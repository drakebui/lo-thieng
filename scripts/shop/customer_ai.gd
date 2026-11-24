# customer_ai.gd
# Điều khiển hành vi khách hàng trong ShopScene 2D.
# Vòng đời: ENTERING → BROWSING → APPROACHING_COUNTER → AT_COUNTER → LEAVING → DONE
# Spawn bởi ShopScene khi nhận signal customer_arrived từ ShopManager.
class_name CustomerAI
extends CharacterBody2D

# ══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ══════════════════════════════════════════════════════════════════════════════

signal reached_counter(instance_id: int)
signal left_shop(instance_id: int, reason: String)   # "served"|"impatient"|"dismissed"

# ══════════════════════════════════════════════════════════════════════════════
# ENUMS
# ══════════════════════════════════════════════════════════════════════════════

enum State { ENTERING, BROWSING, APPROACHING_COUNTER, AT_COUNTER, LEAVING, DONE }

# ══════════════════════════════════════════════════════════════════════════════
# CONSTANTS
# ══════════════════════════════════════════════════════════════════════════════

const ARRIVE_DIST  := 10.0   # px — tính là đã đến nơi
const BROWSE_PAUSE := 1.8    # giây đứng ngắm trước kệ
const COUNTER_WAIT := 120.0  # giây tối đa đợi ở quầy (đủ cho 2-3 negotiations)
const SHOP_SPEED_MULTIPLIER := 1.30  # tăng tốc khách trong cửa hàng

# Màu đặc trưng theo loại khách
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

# ══════════════════════════════════════════════════════════════════════════════
# STATE
# ══════════════════════════════════════════════════════════════════════════════

var instance_id:    int        = -1
var customer_data:  Dictionary = {}

# Layout — ShopScene inject qua setup(); fallback an toàn nếu thiếu
var _shelf_fronts:    Array   = []
var _counter_spots:   Array   = []
var _door_entry:      Vector2 = Vector2.ZERO
var _door_exit:       Vector2 = Vector2.ZERO
var _occupied_shelves: Array  = []   # chỉ số kệ có hàng thực sự

var _state:         State   = State.ENTERING
var _speed:         float   = 100.0
var _target:        Vector2 = Vector2.ZERO
var _browse_queue:  Array   = []   # chỉ số kệ sẽ ghé, pop_front khi đi tiếp
var _pause_timer:   float   = 0.0
var _pausing:       bool    = false
var _wait_timer:    float   = 0.0
var _is_wait_timer_paused: bool = false
var _leaving_reason: String = "impatient"
var _wants_to_buy:  bool    = true


# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

func setup(data: Dictionary) -> void:
	instance_id   = data.get("instance_id", -1)
	customer_data = data
	_speed        = data.get("walk_speed", 100.0) * SHOP_SPEED_MULTIPLIER
	_wants_to_buy = randf() < 0.90

	# Nhận layout động từ ShopScene
	_shelf_fronts    = data.get("shelf_fronts",    [])
	_counter_spots   = data.get("counter_spots",   [])
	_door_entry      = data.get("door_entry",      Vector2.ZERO)
	_door_exit       = data.get("door_exit",       Vector2.ZERO)
	_occupied_shelves = data.get("occupied_shelves", [])

	position = _door_entry
	# Layer 2 = khách, chỉ va chạm tường (layer 4); không chặn player (layer 1) hay nhau (layer 2)
	collision_layer = 2
	collision_mask  = 4
	_build_visuals(data.get("type", ""))
	_pick_browse_plan()
	_begin_enter()


func _build_visuals(ctype: String) -> void:
	var body_color: Color = CUSTOMER_COLORS.get(ctype, Color(0.55, 0.35, 0.35))

	var body := Polygon2D.new()
	body.color = body_color
	body.polygon = PackedVector2Array([
		Vector2(-18, -22), Vector2(18, -22),
		Vector2(18,  26),  Vector2(-18, 26),
	])
	add_child(body)

	var head := Polygon2D.new()
	head.color = Color(0.82, 0.68, 0.52)
	head.polygon = PackedVector2Array([
		Vector2(-13, -44), Vector2(13, -44),
		Vector2(13,  -24), Vector2(-13, -24),
	])
	add_child(head)

	var col   := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(36, 48)
	col.shape  = shape
	add_child(col)


# ══════════════════════════════════════════════════════════════════════════════
# STATE TRANSITIONS
# ══════════════════════════════════════════════════════════════════════════════

func _pick_browse_plan() -> void:
	# Chỉ ghé kệ có hàng thực sự
	var candidates: Array = _occupied_shelves.duplicate()
	if candidates.is_empty():
		_wants_to_buy = false
		return
	candidates.shuffle()
	var count: int = mini(randi_range(1, 2), candidates.size())
	_browse_queue = candidates.slice(0, count)


func _begin_enter() -> void:
	_state = State.ENTERING
	# Đi thẳng đến kệ đầu tiên — tự nhiên hơn là đi vào giữa rồi mới rẽ
	if not _browse_queue.is_empty() and not _shelf_fronts.is_empty():
		_target = _shelf_fronts[_browse_queue[0]]
	elif not _counter_spots.is_empty():
		_target = _counter_spots.pick_random()
	else:
		_target = position   # fallback: đứng yên


func _on_entered() -> void:
	# Đã đến kệ đầu tiên — pause rồi ghé tiếp
	_state = State.BROWSING
	_browse_queue.pop_front()   # kệ đầu tiên: đã ở đây rồi
	_pausing     = true
	_pause_timer = BROWSE_PAUSE


func _next_browse_target() -> void:
	if _browse_queue.is_empty():
		if _wants_to_buy:
			_begin_approach()
		else:
			_begin_leave("browsed")
		return
	var idx: int = _browse_queue.pop_front()
	_target  = _shelf_fronts[idx]
	_pausing = false


func _begin_approach() -> void:
	_state  = State.APPROACHING_COUNTER
	_target = _counter_spots.pick_random() if not _counter_spots.is_empty() else position


func _on_reached_counter() -> void:
	_state      = State.AT_COUNTER
	_wait_timer = COUNTER_WAIT
	velocity    = Vector2.ZERO
	reached_counter.emit(instance_id)


func _begin_leave(reason: String) -> void:
	_leaving_reason = reason
	_state          = State.LEAVING
	_target         = _door_exit


func _on_exited() -> void:
	_state = State.DONE
	left_shop.emit(instance_id, _leaving_reason)
	queue_free()


# ══════════════════════════════════════════════════════════════════════════════
# PROCESS
# ══════════════════════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	match _state:
		State.ENTERING:
			_walk_to_target()
			if _near_target():
				_on_entered()

		State.BROWSING:
			if _pausing:
				_pause_timer -= delta
				if _pause_timer <= 0.0:
					_next_browse_target()
				return
			_walk_to_target()
			if _near_target():
				_pausing     = true
				_pause_timer = BROWSE_PAUSE

		State.APPROACHING_COUNTER:
			_walk_to_target()
			if _near_target():
				_on_reached_counter()

		State.AT_COUNTER:
			velocity = Vector2.ZERO
			move_and_slide()
			if not _is_wait_timer_paused:
				_wait_timer -= delta
				if _wait_timer <= 0.0:
					_begin_leave("impatient")

		State.LEAVING:
			_walk_to_target()
			if _near_target():
				_on_exited()

		State.DONE:
			pass


func _walk_to_target() -> void:
	velocity = (_target - position).normalized() * _speed
	move_and_slide()


func _near_target() -> bool:
	return position.distance_to(_target) < ARRIVE_DIST


# ══════════════════════════════════════════════════════════════════════════════
# PUBLIC API — gọi từ ShopScene
# ══════════════════════════════════════════════════════════════════════════════

# Tạm dừng / tiếp tục đếm ngược khi mở giao diện đàm phán
func set_wait_timer_paused(paused: bool) -> void:
	_is_wait_timer_paused = paused


# Gọi sau khi sale hoàn tất → khách tự đi ra
func dismiss_served() -> void:
	if _state == State.AT_COUNTER or _state == State.BROWSING:
		_begin_leave("served")


# Gọi khi shop đóng cửa, đuổi khách ngay
func force_leave() -> void:
	if _state != State.LEAVING and _state != State.DONE:
		_begin_leave("dismissed")
