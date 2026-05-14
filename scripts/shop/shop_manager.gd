class_name ShopManager
extends Node

# Quản lý phiên bán hàng buổi chiều:
# - Timer 10 phút thực
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
signal time_updated(seconds_left: float)

# ══════════════════════════════════════════════════════════════════════════════
# CONSTANTS
# ══════════════════════════════════════════════════════════════════════════════

const SESSION_DURATION  := 600.0  # 10 phút thực
# Recettear model: toàn bộ khách vào 1 lần khi mở cửa
const MIN_CUSTOMERS     := 3
const MAX_CUSTOMERS     := 7
const STAGGER_INTERVAL  := 0.6    # giây giữa mỗi khách bước qua cửa
# Mỗi item trên kệ khớp preferred của template → +MATCH_BONUS vào weight
const MATCH_BONUS       := 1.5

# ══════════════════════════════════════════════════════════════════════════════
# CUSTOMER POOL (MVP — hard-coded, sau migrate sang .tres resource)
# Mỗi entry là template; mỗi lần spawn tạo instance mới với id riêng.
# budget: [min, max] — random khi spawn
# patience: số lần offer tối đa trước khi bỏ đi
# preferred / disliked: blank_id hoặc element tag
# ══════════════════════════════════════════════════════════════════════════════

const CUSTOMER_TEMPLATES: Array = [
	{
		"type": "hiep_khach",
		"name": "Hiệp Khách Lang Bạt",
		"budget": [600, 1400],
		"patience": 2,
		"preferred": ["kiem_don", "song_dao", "khi_phach", "hoa"],
		"disliked": ["curse_nang", "phan_chu"],
		"walk_speed": 100.0,
	},
	{
		"type": "thu_ve",
		"name": "Thủ Vệ Vùng Biên",
		"budget": [500, 1200],
		"patience": 2,
		"preferred": ["bua_chien", "giao_dai", "khien_dong", "tot"],
		"disliked": ["curse_nhe", "curse_nang"],
		"walk_speed": 80.0,
	},
	{
		"type": "vo_tang",
		"name": "Võ Tăng Vân Du",
		"budget": [700, 1500],
		"patience": 2,
		"preferred": ["quyen_cu", "con_nhi_khuc", "bua_chien"],
		"disliked": ["phan_chu"],
		"walk_speed": 110.0,
	},
	{
		"type": "thich_khach",
		"name": "Thích Khách Bóng Tối",
		"budget": [800, 1600],
		"patience": 1,
		"preferred": ["song_dao", "liem_song", "hu_khong", "bang_gia"],
		"disliked": ["khi_phach", "thuong"],
		"walk_speed": 130.0,
	},
	{
		"type": "dao_si",
		"name": "Đạo Sĩ Đám Mây",
		"budget": [900, 2000],
		"patience": 2,
		"preferred": ["gay_phep", "dao_dong", "sam_set"],
		"disliked": ["phan_chu", "curse_nang"],
		"walk_speed": 90.0,
	},
	{
		"type": "thuong_nhan",
		"name": "Thương Nhân Xa Xứ",
		"budget": [300, 900],
		"patience": 3,
		"preferred": ["thuong", "tot"],  # thích hàng phổ thông, dễ bán lại
		"disliked": ["perfect", "khi_phach"],  # không cần hàng quá đắt
		"walk_speed": 85.0,
	},
	{
		"type": "nong_dan",
		"name": "Nông Dân Vùng Thảo Nguyên",
		"budget": [200, 700],
		"patience": 1,
		"preferred": ["dao_phat", "bua_chien", "thuong"],
		"disliked": [],
		"walk_speed": 75.0,
	},
	{
		"type": "ve_binh",
		"name": "Vệ Binh Hoàng Gia",
		"budget": [1200, 2500],
		"patience": 2,
		"preferred": ["giao_dai", "khien_dong", "phu_viet", "kiet_tac"],
		"disliked": ["curse_nang", "phan_chu"],
		"walk_speed": 90.0,
	},
]

# ══════════════════════════════════════════════════════════════════════════════
# STATE
# ══════════════════════════════════════════════════════════════════════════════

var is_open: bool = false

var _shelf_inventory: Array = []   # set trước open_shop()

var _time_left:     float = 0.0
var _next_id:       int   = 0

# Hàng chờ vào cửa — drain với stagger timer
var _spawn_queue:   Array[Dictionary] = []
var _stagger_timer: float = 0.0

# Khách đang trong shop
var _in_shop: Array[Dictionary] = []

# Thống kê phiên hiện tại
var _gold_earned:       int = 0
var _customers_served:  int = 0
var _customers_visited: int = 0


# ══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ══════════════════════════════════════════════════════════════════════════════

# Mở cửa hàng — slot_count = số ô kệ đã có vũ khí (đếm từ shop_scene).
func open_shop(slot_count: int = 0) -> void:
	if is_open:
		return
	is_open            = true
	_time_left         = SESSION_DURATION
	_next_id           = 0
	_in_shop.clear()
	_spawn_queue.clear()
	_gold_earned       = 0
	_customers_served  = 0
	_customers_visited = 0

	# Tổng NPC = số vũ khí trên kệ + ngẫu nhiên 0/1/2, tối thiểu 1
	var count: int = maxi(1, slot_count + randi_range(0, 2))
	for i in count:
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


# Gọi khi hoàn thành bán hàng cho 1 khách.
func complete_sale(instance_id: int, gold: int) -> void:
	var c := _find_customer(instance_id)
	if c.is_empty():
		return
	_gold_earned      += gold
	_customers_served += 1
	if gold > 0:
		GameManager.add_gold(gold)
	EventBus.customer_served.emit(c.get("type", ""), gold)
	_remove_customer(c, "sale")


# Gọi khi khách bỏ đi không mua (hết patience, từ chối giá, tự đi ra).
func customer_walk_out(instance_id: int) -> void:
	var c := _find_customer(instance_id)
	if not c.is_empty():
		_remove_customer(c, "browsed")


# Trả về số giây còn lại trong phiên.
func get_time_left() -> float:
	return _time_left


# Trả về danh sách khách đang trong shop (read-only copy).
func get_customers_in_shop() -> Array[Dictionary]:
	return _in_shop.duplicate()


# ══════════════════════════════════════════════════════════════════════════════
# PROCESS — session timer + spawn
# ══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not is_open:
		return

	_time_left -= delta
	time_updated.emit(_time_left)

	if _time_left <= 0.0:
		close_shop()
		return

	# Drain hàng chờ — stagger từng khách qua cửa
	if not _spawn_queue.is_empty():
		_stagger_timer -= delta
		if _stagger_timer <= 0.0:
			var customer: Dictionary = _spawn_queue.pop_front()
			_in_shop.append(customer)
			_customers_visited += 1
			customer_arrived.emit(customer)
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
func _pick_weighted_template() -> Dictionary:
	var weights: Array[float] = []
	for tmpl in CUSTOMER_TEMPLATES:
		weights.append(_calc_weight(tmpl))
	return _weighted_random(weights)


# Trọng số = 1.0 + MATCH_BONUS × số item trên kệ khớp preferred của template.
# Mỗi item chỉ tính 1 lần dù khớp nhiều tag.
func _calc_weight(tmpl: Dictionary) -> float:
	var preferred: Array = tmpl.get("preferred", [])
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


# Chọn ngẫu nhiên có trọng số từ CUSTOMER_TEMPLATES.
func _weighted_random(weights: Array[float]) -> Dictionary:
	var total: float = 0.0
	for w in weights:
		total += w
	var r: float = randf() * total
	var cumulative: float = 0.0
	for i in CUSTOMER_TEMPLATES.size():
		cumulative += weights[i]
		if r <= cumulative:
			return CUSTOMER_TEMPLATES[i]
	return CUSTOMER_TEMPLATES[-1]


# Tạo instance từ template — thêm instance_id và random budget.
func _instantiate(tmpl: Dictionary) -> Dictionary:
	var c        := tmpl.duplicate()
	c["instance_id"] = _next_id
	_next_id += 1
	var b: Array = tmpl["budget"]
	c["budget_this_visit"] = randi_range(b[0], b[1])
	return c


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
	return {
		"gold_earned":       _gold_earned,
		"customers_served":  _customers_served,
		"customers_visited": _customers_visited,
		"duration":          SESSION_DURATION - _time_left,
	}
