class_name ShopManager
extends Node

# Quản lý phiên bán hàng buổi chiều:
# - Hàng đợi khách spawn theo interval ngẫu nhiên
# - Open / close API
# UI lắng nghe signals của node này; cross-system dùng EventBus.

# ══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ══════════════════════════════════════════════════════════════════════════════

signal shop_opened
signal shop_closed(session_stats: Dictionary)
signal customer_arrived(customer: Dictionary)
signal customer_left(customer: Dictionary, reason: String)   # "sale"|"browsed"|"timeout"

# ══════════════════════════════════════════════════════════════════════════════
# CONSTANTS
# ══════════════════════════════════════════════════════════════════════════════

# Recettear model: toàn bộ khách vào 1 lần khi mở cửa
const MIN_CUSTOMERS     := 3
const MAX_CUSTOMERS     := 7
const STAGGER_INTERVAL  := 0.6    # giây giữa mỗi khách bước qua cửa
# Mỗi item trên kệ khớp preferred của template → +MATCH_BONUS vào weight
const MATCH_BONUS       := 1.5
const CUSTOMER_DIR := "res://resources/customers"
const DEMO_CUSTOMER_IDS: Array[String] = [
	"hiep_khach",
	"ve_binh",
	"tho_san",
	"nong_dan",
]

# ══════════════════════════════════════════════════════════════════════════════
# STATE
# ══════════════════════════════════════════════════════════════════════════════

var is_open: bool = false
var customer_templates: Array[NPCData] = []

var _shelf_inventory: Array = []   # set trước open_shop()

var _next_id: int = 0
var _session_start_time: float = 0.0

# Hàng chờ vào cửa — drain với stagger timer
var _spawn_queue:   Array[Dictionary] = []
var _stagger_timer: float = 0.0

# Khách đang trong shop
var _in_shop: Array[Dictionary] = []

# Thống kê phiên hiện tại
var _gold_earned:       int = 0
var _customers_served:  int = 0
var _customers_visited: int = 0


func _ready() -> void:
	_load_customer_templates()
	EventBus.commission_npc_spawn_requested.connect(_on_commission_spawn_requested)
	EventBus.commission_npc_dismiss_requested.connect(_on_commission_dismiss_requested)


# ══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ══════════════════════════════════════════════════════════════════════════════

# Mở cửa hàng — slot_count = số ô kệ đã có vũ khí (đếm từ shop_scene).
func open_shop(slot_count: int = 0) -> void:
	if is_open:
		return
	if customer_templates.is_empty():
		_load_customer_templates()
	if customer_templates.is_empty():
		return
	is_open            = true
	_next_id           = 0
	_session_start_time = Time.get_ticks_msec()
	_in_shop.clear()
	_spawn_queue.clear()
	_gold_earned       = 0
	_customers_served  = 0
	_customers_visited = 0

	if _should_run_tutorial_scripted_customer():
		_spawn_queue.append(_spawn_scripted_customer(_get_scripted_customer_id()))
	else:
		# Tổng NPC = số vũ khí trên kệ + ngẫu nhiên 0/1/2, tối thiểu 1
		var count: int = maxi(1, slot_count + randi_range(0, 2))
		for i in range(count):
			_spawn_queue.append(_instantiate(_pick_weighted_template()))
	_stagger_timer = 0.2  # khách đầu vào ngay sau 0.2s

	shop_opened.emit()
	EventBus.shop_opened.emit()


# Đóng cửa sớm hoặc kết thúc phiên.
func close_shop() -> void:
	if not is_open:
		return
	is_open = false
	_spawn_queue.clear()   # huỷ khách chưa kịp vào

	# Đuổi khách còn trong shop
	for c in _in_shop.duplicate():
		_remove_customer(c, "timeout")

	var stats := _build_stats()
	shop_closed.emit(stats)
	EventBus.shop_closed.emit(stats)


# Gọi khi hoàn thành bán hàng cho 1 khách. Trả về true nếu thành công, false nếu khách không tồn tại.
func complete_sale(instance_id: int, gold: int) -> bool:
	var c := _find_customer(instance_id)
	if c.is_empty():
		return false
	_gold_earned      += gold
	_customers_served += 1
	if gold > 0:
		GameManager.add_gold(gold)
	EventBus.customer_served.emit(c.get("type", ""), gold)
	_remove_customer(c, "sale")
	return true


# Gọi khi khách bỏ đi không mua (hết patience, từ chối giá, tự đi ra).
func customer_walk_out(instance_id: int) -> void:
	var c := _find_customer(instance_id)
	if not c.is_empty():
		_remove_customer(c, "browsed")


# Giver commission đi qua queue shop, không gọi trực tiếp scene customer.
func _on_commission_spawn_requested(npc_id: String) -> void:
	if not is_open:
		return
	if _has_commission_giver(npc_id):
		return
	var tmpl := _find_template(npc_id)
	if tmpl == null:
		push_warning("Commission giver template not found: " + npc_id)
		return
	var customer := _instantiate(tmpl)
	customer["is_commission_giver"] = true
	_spawn_queue.push_front(customer)


func _on_commission_dismiss_requested(instance_id: int) -> void:
	var c := _find_customer(instance_id)
	if not c.is_empty():
		_customers_served += 1
		_remove_customer(c, "commission_fulfilled")


func _has_commission_giver(npc_id: String) -> bool:
	for queued in _spawn_queue:
		if queued.get("is_commission_giver", false) and queued.get("type", "") == npc_id:
			return true
	for active in _in_shop:
		if active.get("is_commission_giver", false) and active.get("type", "") == npc_id:
			return true
	return false


# Trả về danh sách khách đang trong shop (read-only copy).
func get_customers_in_shop() -> Array[Dictionary]:
	return _in_shop.duplicate()


# ══════════════════════════════════════════════════════════════════════════════
# PROCESS — spawn
# ══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not is_open:
		return

	# Drain hàng chờ — stagger từng khách qua cửa
	if not _spawn_queue.is_empty():
		_stagger_timer -= delta
		if _stagger_timer <= 0.0:
			var customer: Dictionary = _spawn_queue.pop_front()
			_in_shop.append(customer)
			_customers_visited += 1
			customer_arrived.emit(customer)
			EventBus.customer_arrived.emit(customer)
			_stagger_timer = STAGGER_INTERVAL


# ══════════════════════════════════════════════════════════════════════════════
# SHELF INVENTORY — dùng để tính trọng số spawn
# ══════════════════════════════════════════════════════════════════════════════

# Gọi trước open_shop() để cấu hình kệ hàng hiện tại.
func set_shelf_inventory(items: Array) -> void:
	_shelf_inventory = items


# ══════════════════════════════════════════════════════════════════════════════
# SPAWN LOGIC
# ══════════════════════════════════════════════════════════════════════════════

# Chọn template với xác suất tỉ lệ thuận với kệ hàng hiện tại.
func _pick_weighted_template() -> NPCData:
	var eligible: Array[NPCData] = []
	var day: int = GameManager.current_day
	for tmpl in customer_templates:
		if _is_demo_day() and not DEMO_CUSTOMER_IDS.has(tmpl.npc_id):
			continue
		if tmpl.min_day <= day:
			eligible.append(tmpl)
	if eligible.is_empty():
		eligible = _get_demo_templates() if _is_demo_day() else customer_templates

	var weights: Array[float] = []
	for tmpl in eligible:
		weights.append(_calc_weight(tmpl))
	return _weighted_random_from(eligible, weights)


# Trọng số = 1.0 + MATCH_BONUS × số item trên kệ khớp preferred của template.
# Mỗi item chỉ tính 1 lần dù khớp nhiều tag.
func _calc_weight(tmpl: NPCData) -> float:
	var preferred: Array[String] = tmpl.preferred_tags
	var weight: float = 1.0
	for item: Dictionary in _shelf_inventory:
		var item_tags := _item_tags(item)
		for tag: String in preferred:
			if tag in item_tags:
				weight += MATCH_BONUS
				break   # item này đã tính, không cộng nhiều lần
	return weight


# Tập hợp tất cả tag nhận dạng của 1 item: blank_id, suffix, phase2_prefix, element.
func _item_tags(item: Dictionary) -> Array:
	var tags: Array = []
	for key in ["blank_id", "suffix", "phase2_prefix", "element"]:
		var v: String = item.get(key, "")
		if not v.is_empty():
			tags.append(v)
	return tags


# Chọn ngẫu nhiên có trọng số từ customer_templates.
func _weighted_random(weights: Array[float]) -> NPCData:
	return _weighted_random_from(customer_templates, weights)


func _weighted_random_from(pool: Array[NPCData], weights: Array[float]) -> NPCData:
	if pool.is_empty():
		return null
	var total: float = 0.0
	for w in weights:
		total += w
	var r: float = randf() * total
	var cumulative: float = 0.0
	for i in pool.size():
		cumulative += weights[i]
		if r <= cumulative:
			return pool[i]
	return pool[-1]


# Tạo instance từ template — thêm instance_id và random budget.
func _instantiate(tmpl: NPCData) -> Dictionary:
	var c := {
		"type": tmpl.npc_id,
		"name": tmpl.npc_name,
		"budget": [tmpl.budget_min, tmpl.budget_max],
		"patience": tmpl.patience,
		"preferred": tmpl.preferred_tags.duplicate(),
		"disliked": tmpl.disliked_tags.duplicate(),
		"walk_speed": tmpl.walk_speed,
		"min_weapon_rarity": tmpl.min_weapon_rarity,
	}
	c["instance_id"] = _next_id
	_next_id += 1
	c["budget_this_visit"] = randi_range(tmpl.budget_min, tmpl.budget_max)
	return c


func _load_customer_templates() -> void:
	customer_templates.clear()
	var dir := DirAccess.open(CUSTOMER_DIR)
	if dir == null:
		return

	var files: PackedStringArray = dir.get_files()
	files.sort()
	for file_name in files:
		if file_name.get_extension() != "tres":
			continue

		var resource_path := "%s/%s" % [CUSTOMER_DIR, file_name]
		var resource := load(resource_path)
		if resource is NPCData:
			var customer := resource as NPCData
			customer_templates.append(customer)


func _is_demo_day() -> bool:
	return GameManager.current_day <= GameManager.DEMO_LAST_DAY


func _get_demo_templates() -> Array[NPCData]:
	var result: Array[NPCData] = []
	for tmpl in customer_templates:
		if DEMO_CUSTOMER_IDS.has(tmpl.npc_id):
			result.append(tmpl)
	return result


func _should_run_tutorial_scripted_customer() -> bool:
	return (
		(
			GameManager.current_day == 0
			and not GameManager.has_tutorial_seen("day0_customer_done")
		)
		or GameManager.current_day == 1
	)


func _get_scripted_customer_id() -> String:
	if GameManager.current_day == 1:
		return "hiep_khach_lang_bat"
	return "nong_dan"


func _spawn_scripted_customer(customer_id: String) -> Dictionary:
	var template := _find_template(_normalize_scripted_customer_id(customer_id))
	if template == null:
		template = _make_default_scripted_customer(customer_id)
	return _instantiate(template)


func _normalize_scripted_customer_id(customer_id: String) -> String:
	if customer_id == "hiep_khach_lang_bat":
		return "hiep_khach"
	return customer_id


func _make_default_scripted_customer(customer_id: String) -> NPCData:
	var customer := NPCData.new()
	customer.npc_id = _normalize_scripted_customer_id(customer_id)
	customer.npc_name = "Hiệp Khách Lang Bạt"
	customer.budget_min = 500
	customer.budget_max = 1500
	customer.patience = 2
	customer.preferred_tags = ["kiem", "bua_chien"]
	customer.disliked_tags = []
	customer.walk_speed = 100.0
	customer.min_day = 1
	customer.min_weapon_rarity = 1
	return customer


func _find_template(npc_id: String) -> NPCData:
	for tmpl in customer_templates:
		if tmpl.npc_id == npc_id:
			return tmpl
	return null


# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _remove_customer(customer: Dictionary, reason: String) -> void:
	_in_shop.erase(customer)
	customer_left.emit(customer, reason)
	_check_session_complete()


func _check_session_complete() -> void:
	# Kết thúc phiên ngay khi hàng đợi và shop đều trống — không cần đợi hết giờ
	if is_open and _spawn_queue.is_empty() and _in_shop.is_empty():
		close_shop()


func _find_customer(instance_id: int) -> Dictionary:
	for c in _in_shop:
		if c.get("instance_id") == instance_id:
			return c
	return {}


func _build_stats() -> Dictionary:
	if _should_run_tutorial_scripted_customer():
		GameManager.mark_tutorial_seen("day0_customer_done")
	var duration := 0.0
	if _session_start_time > 0.0:
		duration = (Time.get_ticks_msec() - _session_start_time) / 1000.0
	return {
		"gold_earned":       _gold_earned,
		"customers_served":  _customers_served,
		"customers_visited": _customers_visited,
		"duration":          duration,
	}
