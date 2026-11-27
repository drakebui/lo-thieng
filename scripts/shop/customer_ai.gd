# customer_ai.gd
# Điều khiển hành vi khách hàng kiểu Moonlighter trong ShopScene 2D:
# ENTERING_BROWSE → GOING_TO_PICKUP → PICKING_UP → GOING_TO_COUNTER → IN_QUEUE
#   ↳ Mua thành công: LEAVING ("served")
#   ↳ Bị từ chối / hết kiên nhẫn: RETURNING_ITEM (chạy nhanh trả hàng về kệ cũ) → LEAVING (tăng tốc ra cửa)
class_name CustomerAI
extends CharacterBody2D

# ══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ══════════════════════════════════════════════════════════════════════════════

signal item_picked_up(instance_id: int, slot_idx: int)
signal reached_counter(instance_id: int)
signal item_returned(instance_id: int, slot_idx: int, weapon: Dictionary)
signal left_shop(instance_id: int, reason: String)   # "served"|"declined"|"impatient"|"browsed"|"dismissed"

# ══════════════════════════════════════════════════════════════════════════════
# ENUMS & CONSTANTS
# ══════════════════════════════════════════════════════════════════════════════

enum State {
	ENTERING_BROWSE,
	GOING_TO_PICKUP,
	PICKING_UP,
	GOING_TO_COUNTER,
	IN_QUEUE,
	RETURNING_ITEM,
	LEAVING,
	DONE,
}

const ARRIVE_DIST := 10.0
const BROWSE_PAUSE := 1.2
const PICKUP_PAUSE := 0.55
const RETURN_PAUSE := 0.25
const COUNTER_WAIT := 120.0

const SHOP_SPEED_MULTIPLIER := 1.30
const RETURN_SPEED_MULTIPLIER := 1.65   # mang nhanh vũ khí về kệ cũ
const SPRINT_EXIT_MULTIPLIER := 2.05    # tăng tốc chạy ra ngoài sau khi trả hàng

const CUSTOMER_COLORS: Dictionary = {
	"hiep_khach":  Color(0.20, 0.45, 0.72),
	"thu_ve":      Color(0.48, 0.50, 0.56),
	"tho_san":     Color(0.30, 0.48, 0.24),
	"vo_tang":     Color(0.72, 0.62, 0.22),
	"thich_khach": Color(0.48, 0.22, 0.58),
	"dao_si":      Color(0.22, 0.60, 0.58),
	"thuong_nhan": Color(0.68, 0.48, 0.18),
	"nong_dan":    Color(0.40, 0.55, 0.28),
	"ve_binh":     Color(0.28, 0.34, 0.60),
}

const CUSTOMER_SHEET_PATHS: Dictionary = {
	"nong_dan":    "res://assets/pixel/sprites/customers/nong_dan_sheet_64.png",
	"ve_binh":     "res://assets/pixel/sprites/customers/ve_binh_sheet_64.png",
	"tho_san":     "res://assets/pixel/sprites/customers/tho_san_sheet_64.png",
	"hiep_khach":  "res://assets/pixel/sprites/customers/hiep_khach_sheet_64.png",
	"thuong_nhan": "res://assets/pixel/sprites/customers/thuong_nhan_sheet_64.png",
	"thich_khach": "res://assets/pixel/sprites/customers/thich_khach_sheet_64.png",
	"dao_si":      "res://assets/pixel/sprites/customers/dao_si_sheet_64.png",
	"vo_tang":     "res://assets/pixel/sprites/customers/vo_tang_sheet_64.png",
	"thu_ve":      "res://assets/pixel/sprites/customers/thu_ve_sheet_64.png",
}

const WEAPON_SPRITE_DIR := "res://assets/pixel/sprites/weapons/"
const PAY_READY_BUBBLE_PATH := "res://assets/pixel/ui/shop/empty_slot_bubble_32.png"
const CUSTOMER_RENDER_SCALE := 2.75
const SHADOW_COLOR := Color(0.06, 0.03, 0.04, 0.42)

# ══════════════════════════════════════════════════════════════════════════════
# STATE
# ══════════════════════════════════════════════════════════════════════════════

var instance_id: int = -1
var customer_data: Dictionary = {}
var target_slot_idx: int = -1
var carried_weapon: Dictionary = {}
var is_carrying_item: bool = false

var _door_entry: Vector2 = Vector2.ZERO
var _door_exit: Vector2 = Vector2.ZERO
var _browse_waypoints: Array[Vector2] = []
var _pickup_waypoints: Array[Vector2] = []
var _counter_waypoints: Array[Vector2] = []
var _return_waypoints: Array[Vector2] = []
var _exit_waypoints: Array[Vector2] = []

var _active_waypoints: Array[Vector2] = []
var _state: State = State.ENTERING_BROWSE
var _base_speed: float = 130.0
var _speed_mult: float = 1.0
var _pause_timer: float = 0.0
var _wait_timer: float = COUNTER_WAIT
var _is_wait_timer_paused: bool = false
var _leaving_reason: String = "impatient"
var _is_front_of_queue: bool = false
var _pay_bob_time: float = 0.0

var _sprite: AnimatedSprite2D = null
var _emote_anchor: Marker2D = null
var _carried_sprite: Sprite2D = null
var _pay_indicator: Sprite2D = null
var _render_scale: float = CUSTOMER_RENDER_SCALE


# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

func setup(data: Dictionary) -> void:
	instance_id = int(data.get("instance_id", -1))
	customer_data = data
	_base_speed = float(data.get("walk_speed", 100.0)) * SHOP_SPEED_MULTIPLIER
	_render_scale = float(data.get("render_scale", CUSTOMER_RENDER_SCALE))

	_door_entry = data.get("door_entry", Vector2.ZERO) as Vector2
	_door_exit = data.get("door_exit", Vector2.ZERO) as Vector2
	target_slot_idx = int(data.get("target_slot_idx", -1))
	carried_weapon = (data.get("target_weapon", {}) as Dictionary).duplicate()
	is_carrying_item = false

	_browse_waypoints = _to_vec2_array(data.get("browse_waypoints", []))
	_pickup_waypoints = _to_vec2_array(data.get("pickup_waypoints", []))
	_counter_waypoints = _to_vec2_array(data.get("counter_waypoints", []))
	_exit_waypoints = _to_vec2_array(data.get("exit_waypoints", [_door_exit]))

	position = _door_entry
	# Layer 2 = khách, chỉ va tường ngoài (layer 4); di chuyển vòng bàn bằng waypoint
	collision_layer = 2
	collision_mask = 4
	_build_visuals(String(data.get("type", "")))
	_start_initial_route()


func _to_vec2_array(raw: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for item in raw:
		if item is Vector2:
			out.append(item as Vector2)
	return out


func _build_visuals(ctype: String) -> void:
	# 1. Bóng tiếp đất chuẩn BaseCharacter tại (0, 0)
	var shadow := Polygon2D.new()
	shadow.name = "ContactShadow"
	shadow.color = SHADOW_COLOR
	shadow.z_index = -1
	var pts := PackedVector2Array()
	for i in range(14):
		var ang := (float(i) / 14.0) * TAU
		pts.append(Vector2(cos(ang) * 8.0, sin(ang) * 2.6) * _render_scale)
	shadow.polygon = pts
	add_child(shadow)

	# 2. AnimatedSprite2D 32-bit Hoả Tâm
	var sheet_path: String = String(
		CUSTOMER_SHEET_PATHS.get(ctype, CUSTOMER_SHEET_PATHS["nong_dan"])
	)
	var frames: SpriteFrames = BaseCharacter.get_or_build_frames(sheet_path)
	if frames != null:
		_sprite = AnimatedSprite2D.new()
		_sprite.name = "AnimatedSprite2D"
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_sprite.sprite_frames = frames
		_sprite.offset = Vector2(0.0, -28.0)
		_sprite.scale = Vector2(_render_scale, _render_scale)
		_sprite.play("idle")
		add_child(_sprite)
	else:
		var body_color: Color = CUSTOMER_COLORS.get(ctype, Color(0.55, 0.35, 0.35))
		var body := Polygon2D.new()
		body.color = body_color
		body.polygon = PackedVector2Array([
			Vector2(-18, -48), Vector2(18, -48),
			Vector2(18, 0),    Vector2(-18, 0),
		])
		add_child(body)

	# 3. Va chạm bàn chân chuẩn CapsuleShape2D (34x18) tại y = 0
	var col := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 9.0
	shape.height = 34.0
	col.shape = shape
	col.rotation = deg_to_rad(90.0)
	col.position = Vector2(0.0, -9.0)
	add_child(col)

	# 4. Điểm neo bong bóng thoại / cảm xúc chuẩn (0, -56 * scale)
	_emote_anchor = Marker2D.new()
	_emote_anchor.name = "EmoteAnchor"
	_emote_anchor.position = Vector2(0.0, -56.0 * _render_scale)
	add_child(_emote_anchor)

	# 5. Icon vũ khí đang ôm trên tay (ẩn đến khi nhấc hàng khỏi bàn)
	_carried_sprite = Sprite2D.new()
	_carried_sprite.name = "CarriedWeaponSprite"
	_carried_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_carried_sprite.position = Vector2(-10.0 * _render_scale, -20.0 * _render_scale)
	_carried_sprite.z_index = 4
	_carried_sprite.visible = false
	add_child(_carried_sprite)

	# 6. Bóng thoại dấu ! khi đang đứng đầu hàng chờ Nấm ra quầy tính tiền
	_pay_indicator = Sprite2D.new()
	_pay_indicator.name = "PayReadyIndicator"
	_pay_indicator.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(PAY_READY_BUBBLE_PATH):
		_pay_indicator.texture = load(PAY_READY_BUBBLE_PATH) as Texture2D
	_pay_indicator.scale = Vector2(1.5, 1.5)
	_pay_indicator.position = _emote_anchor.position + Vector2(0.0, -14.0)
	_pay_indicator.z_index = 35
	_pay_indicator.visible = false
	add_child(_pay_indicator)


func get_emote_local_pos() -> Vector2:
	if _emote_anchor != null:
		return _emote_anchor.position
	return Vector2(0.0, -56.0 * _render_scale)


# ══════════════════════════════════════════════════════════════════════════════
# STATE TRANSITIONS (Moonlighter Flow)
# ══════════════════════════════════════════════════════════════════════════════

func _start_initial_route() -> void:
	_speed_mult = 1.0
	if not _browse_waypoints.is_empty():
		_state = State.ENTERING_BROWSE
		_active_waypoints = _browse_waypoints.duplicate()
		_pause_timer = 0.0
	elif target_slot_idx >= 0 and not carried_weapon.is_empty():
		_begin_going_to_pickup()
	else:
		_begin_leave("browsed", 1.15)


func _begin_going_to_pickup() -> void:
	_state = State.GOING_TO_PICKUP
	_speed_mult = 1.0
	_active_waypoints = _pickup_waypoints.duplicate()
	if _active_waypoints.is_empty():
		_on_arrived_at_pickup()


func _on_arrived_at_pickup() -> void:
	_state = State.PICKING_UP
	_pause_timer = PICKUP_PAUSE
	velocity = Vector2.ZERO
	_update_sprite_anim(Vector2.ZERO)


func _complete_pickup_and_head_to_counter() -> void:
	is_carrying_item = true
	_show_carried_weapon_visual(carried_weapon)
	item_picked_up.emit(instance_id, target_slot_idx)

	_state = State.GOING_TO_COUNTER
	_speed_mult = 1.0
	_active_waypoints = _counter_waypoints.duplicate()
	if _active_waypoints.is_empty():
		_on_reached_counter()


func _on_reached_counter() -> void:
	_state = State.IN_QUEUE
	_wait_timer = COUNTER_WAIT
	velocity = Vector2.ZERO
	_update_sprite_anim(Vector2.ZERO)
	# Quay mặt sang trái nhìn về phía quầy thu ngân & Nấm
	if _sprite != null:
		_sprite.flip_h = true
	reached_counter.emit(instance_id)


func _begin_leave(reason: String, mult: float = 1.35) -> void:
	_leaving_reason = reason
	_state = State.LEAVING
	_speed_mult = mult
	_is_front_of_queue = false
	if _pay_indicator != null:
		_pay_indicator.visible = false
	_active_waypoints = _exit_waypoints.duplicate()
	if _active_waypoints.is_empty():
		_active_waypoints = [_door_exit]


func _on_exited() -> void:
	_state = State.DONE
	left_shop.emit(instance_id, _leaving_reason)
	queue_free()


# ══════════════════════════════════════════════════════════════════════════════
# PROCESS
# ══════════════════════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	match _state:
		State.ENTERING_BROWSE:
			if _pause_timer > 0.0:
				_update_sprite_anim(Vector2.ZERO)
				_pause_timer -= delta
				if _pause_timer <= 0.0:
					if target_slot_idx >= 0 and not carried_weapon.is_empty():
						_begin_going_to_pickup()
					else:
						_begin_leave("browsed", 1.2)
				return
			if _follow_waypoints():
				_pause_timer = BROWSE_PAUSE
				velocity = Vector2.ZERO
				_update_sprite_anim(Vector2.ZERO)

		State.GOING_TO_PICKUP:
			if _follow_waypoints():
				_on_arrived_at_pickup()

		State.PICKING_UP:
			_update_sprite_anim(Vector2.ZERO)
			_pause_timer -= delta
			if _pause_timer <= 0.0:
				_complete_pickup_and_head_to_counter()

		State.GOING_TO_COUNTER:
			if _follow_waypoints():
				_on_reached_counter()

		State.IN_QUEUE:
			if not _active_waypoints.is_empty():
				if _follow_waypoints():
					velocity = Vector2.ZERO
					_update_sprite_anim(Vector2.ZERO)
					if _sprite != null:
						_sprite.flip_h = true
			else:
				velocity = Vector2.ZERO
				move_and_slide()
				_update_sprite_anim(Vector2.ZERO)
				if _sprite != null:
					_sprite.flip_h = true

			_tick_pay_indicator(delta)
			if not _is_wait_timer_paused:
				_wait_timer -= delta
				if _wait_timer <= 0.0:
					# Hết kiên nhẫn: tự mang nhanh đồ về kệ cũ rồi chạy ra cửa (fallback về cửa nếu thiếu waypoint)
					if is_carrying_item and not _return_waypoints.is_empty():
						_start_return_item("impatient")
					else:
						if is_carrying_item and target_slot_idx >= 0 and not carried_weapon.is_empty():
							var w := carried_weapon
							is_carrying_item = false
							_hide_carried_weapon_visual()
							item_returned.emit(instance_id, target_slot_idx, w)
							carried_weapon = {}
						_begin_leave("impatient", SPRINT_EXIT_MULTIPLIER)

		State.RETURNING_ITEM:
			if _pause_timer > 0.0:
				_update_sprite_anim(Vector2.ZERO)
				_pause_timer -= delta
				if _pause_timer <= 0.0:
					_begin_leave(_leaving_reason, SPRINT_EXIT_MULTIPLIER)
				return
			if _follow_waypoints():
				_complete_item_return()

		State.LEAVING:
			if _follow_waypoints():
				_on_exited()

		State.DONE:
			pass


func _follow_waypoints() -> bool:
	if _active_waypoints.is_empty():
		return true
	var next_pt: Vector2 = _active_waypoints[0]
	var to_target: Vector2 = next_pt - position
	if to_target.length() <= ARRIVE_DIST:
		position = next_pt
		_active_waypoints.pop_front()
		if _active_waypoints.is_empty():
			velocity = Vector2.ZERO
			return true
		next_pt = _active_waypoints[0]
		to_target = next_pt - position
	velocity = to_target.normalized() * (_base_speed * _speed_mult)
	move_and_slide()
	_update_sprite_anim(velocity)
	return false


func _update_sprite_anim(vel: Vector2) -> void:
	if _sprite == null:
		return
	if vel.length() > 8.0:
		if absf(vel.x) > 4.0:
			_sprite.flip_h = vel.x < 0.0
			if _carried_sprite != null:
				var side := -1.0 if _sprite.flip_h else 1.0
				_carried_sprite.position.x = side * 10.0 * _render_scale
		if _sprite.animation != "walk" and _sprite.sprite_frames.has_animation("walk"):
			_sprite.play("walk")
	else:
		if _sprite.animation != "idle" and _sprite.sprite_frames.has_animation("idle"):
			_sprite.play("idle")


func _tick_pay_indicator(delta: float) -> void:
	if _pay_indicator == null:
		return
	var should_show := _is_front_of_queue and _state == State.IN_QUEUE and _active_waypoints.is_empty() and not _is_wait_timer_paused
	_pay_indicator.visible = should_show
	if should_show:
		_pay_bob_time += delta * 3.8
		var base_y := _emote_anchor.position.y - 14.0
		_pay_indicator.position.y = roundf(base_y + sin(_pay_bob_time) * 4.0)


func _show_carried_weapon_visual(weapon: Dictionary) -> void:
	if _carried_sprite == null:
		return
	var tex := _resolve_weapon_texture(weapon)
	if tex == null:
		_carried_sprite.visible = false
		return
	_carried_sprite.texture = tex
	var max_dim := maxf(1.0, maxf(float(tex.get_width()), float(tex.get_height())))
	var sc := (20.0 * _render_scale) / max_dim
	_carried_sprite.scale = Vector2(sc, sc)
	_carried_sprite.visible = true


func _hide_carried_weapon_visual() -> void:
	if _carried_sprite != null:
		_carried_sprite.visible = false


func _resolve_weapon_texture(weapon: Dictionary) -> Texture2D:
	var sprite_path := String(weapon.get("sprite_path", ""))
	if sprite_path.begins_with("res://assets/pixel/") and ResourceLoader.exists(sprite_path):
		return load(sprite_path) as Texture2D
	var blank_id := String(weapon.get("blank_id", ""))
	if not blank_id.is_empty():
		var path := "%s%s.png" % [WEAPON_SPRITE_DIR, blank_id]
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	var fallback := "%skiem_don.png" % WEAPON_SPRITE_DIR
	return load(fallback) as Texture2D if ResourceLoader.exists(fallback) else null


func _start_return_item(reason: String) -> void:
	_leaving_reason = reason
	_state = State.RETURNING_ITEM
	_speed_mult = RETURN_SPEED_MULTIPLIER
	_is_front_of_queue = false
	if _pay_indicator != null:
		_pay_indicator.visible = false
	_pause_timer = 0.0
	_active_waypoints = _return_waypoints.duplicate()
	if _active_waypoints.is_empty():
		_complete_item_return()


func _complete_item_return() -> void:
	var w := carried_weapon
	is_carrying_item = false
	_hide_carried_weapon_visual()
	item_returned.emit(instance_id, target_slot_idx, w)
	carried_weapon = {}
	_pause_timer = RETURN_PAUSE
	velocity = Vector2.ZERO
	_update_sprite_anim(Vector2.ZERO)


# ══════════════════════════════════════════════════════════════════════════════
# PUBLIC API — gọi từ ShopScene
# ══════════════════════════════════════════════════════════════════════════════

func set_wait_timer_paused(paused: bool) -> void:
	_is_wait_timer_paused = paused


func set_queue_spot(waypoints: Array[Vector2], is_front: bool) -> void:
	_is_front_of_queue = is_front
	if _state == State.IN_QUEUE or _state == State.GOING_TO_COUNTER:
		_active_waypoints = waypoints.duplicate()


func set_return_and_exit_routes(
	return_waypoints: Array[Vector2],
	exit_waypoints: Array[Vector2]
) -> void:
	_return_waypoints = return_waypoints.duplicate()
	_exit_waypoints = exit_waypoints.duplicate()


# Gọi sau khi mua thành công -> khách giữ vũ khí, vui vẻ đi ra cửa
func dismiss_served(exit_waypoints: Array[Vector2] = []) -> void:
	if not exit_waypoints.is_empty():
		_exit_waypoints = exit_waypoints.duplicate()
	is_carrying_item = false
	carried_weapon = {}
	_begin_leave("served", 1.35)


# Gọi khi bị từ chối -> khách mang nhanh hàng trả về đúng ô kệ cũ, rồi chạy nhanh ra cửa
func return_item_and_leave(
	return_waypoints: Array[Vector2],
	exit_waypoints: Array[Vector2],
	reason: String = "declined"
) -> void:
	_return_waypoints = return_waypoints.duplicate()
	_exit_waypoints = exit_waypoints.duplicate()
	if is_carrying_item and target_slot_idx >= 0 and not carried_weapon.is_empty():
		_start_return_item(reason)
	else:
		_begin_leave(reason, SPRINT_EXIT_MULTIPLIER)


# Gọi khi đóng cửa tiệm đột ngột -> đảm bảo hoàn trả đồ ngay trước khi đi ra
func force_leave() -> void:
	if is_carrying_item and target_slot_idx >= 0 and not carried_weapon.is_empty():
		var w := carried_weapon
		is_carrying_item = false
		_hide_carried_weapon_visual()
		item_returned.emit(instance_id, target_slot_idx, w)
		carried_weapon = {}
	if _state != State.LEAVING and _state != State.DONE:
		_begin_leave("dismissed", SPRINT_EXIT_MULTIPLIER)
