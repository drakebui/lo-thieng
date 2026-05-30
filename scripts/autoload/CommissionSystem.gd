extends Node

const COMMISSION_PATHS: Array[String] = [
	"res://resources/commissions/commission_001.tres",
	"res://resources/commissions/commission_002.tres",
]

var _offers: Array[CommissionData] = []
var _active: Array[CommissionData] = []
var _last_offer_day: int = -1


func _ready() -> void:
	EventBus.weapon_forged.connect(_on_weapon_forged)
	EventBus.day_phase_changed.connect(_on_day_phase_changed)
	EventBus.customer_arrived.connect(_on_customer_arrived)
	EventBus.shop_opened.connect(_on_shop_opened)


func roll_daily_offers(day: int) -> void:
	_offers.clear()
	_last_offer_day = day
	for path in COMMISSION_PATHS:
		var c: CommissionData = load(path)
		if c and not _has_active(c.commission_id):
			_offers.append(c)
	for c in _offers:
		EventBus.commission_offered.emit(c)


func accept(commission_id: String) -> bool:
	if _has_active(commission_id):
		return true
	for i in _offers.size():
		if _offers[i].commission_id == commission_id:
			_active.append(_offers[i])
			_offers.remove_at(i)
			EventBus.commission_accepted.emit(commission_id)
			return true
	return false


func reset_state() -> void:
	_offers.clear()
	_active.clear()
	_last_offer_day = -1


# Restore commission đã accept từ save, KHÔNG fire signals — tránh UI popup khi load.
func restore_active_ids(ids: Array) -> void:
	_active.clear()
	for path in COMMISSION_PATHS:
		var c: CommissionData = load(path)
		if c == null:
			continue
		if String(c.commission_id) in ids:
			_active.append(c)


func get_active() -> Array[CommissionData]:
	return _active


func fulfill(commission_id: String, w: Dictionary) -> void:
	for i in _active.size():
		var c: CommissionData = _active[i]
		if c.commission_id == commission_id:
			var reward := {
				"gold": c.reward_gold,
				"reputation": c.reward_reputation,
				"affinity": c.reward_affinity,
			}
			_active.remove_at(i)
			EventBus.commission_fulfilled.emit(commission_id, w, reward)
			if c.reward_gold > 0:
				GameManager.add_gold(c.reward_gold)
			if c.reward_reputation > 0:
				GameManager.add_reputation(c.reward_reputation)
			# Affinity system chưa có autoload riêng — phát signal cho UI/NPC lắng nghe.
			if c.reward_affinity != 0 and not c.giver_npc_id.is_empty():
				EventBus.npc_affinity_changed.emit(
					c.giver_npc_id, c.reward_affinity
				)
			return


func _on_weapon_forged(w) -> void:
	var weapon: Dictionary = w if w is Dictionary else {}
	for c in _active:
		if WeaponSpec.satisfies(weapon, c):
			EventBus.hint_requested.emit(
				"✓ Vũ khí này khớp đơn hàng của " + c.giver_npc_id
			)


func _on_day_phase_changed(day: int, phase: int) -> void:
	# Roll đơn khi bước vào buổi sáng, tránh emit trùng do restore/init.
	if phase == GameManager.GamePhase.MORNING and day != _last_offer_day:
		roll_daily_offers(day)


func _on_shop_opened() -> void:
	for c in _active:
		if not c.giver_npc_id.is_empty():
			EventBus.commission_npc_spawn_requested.emit(c.giver_npc_id)


func _on_customer_arrived(customer: Dictionary) -> void:
	# ShopManager dùng type làm npc_id runtime; id là fallback cho dữ liệu sau này.
	var npc_id := String(customer.get("id", customer.get("type", "")))
	for c in _active:
		if c.giver_npc_id == npc_id:
			EventBus.commission_giver_arrived.emit(c, customer)
			EventBus.hint_requested.emit("Khách " + npc_id + " đến nhận đơn hàng!")
			return


func _has_active(commission_id: String) -> bool:
	for c in _active:
		if c.commission_id == commission_id:
			return true
	return false
