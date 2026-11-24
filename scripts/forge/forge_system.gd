extends Node

# Hệ thống rèn Phase 1: Nung Thép
# Cơ chế Nung Nhịp Bơm Giữ Nhiệt rút gọn ~3.5 giây
# Kết quả emit qua EventBus.phase1_completed(result_tier)

const HEAT_MIN        := 0.0
const HEAT_MAX        := 100.0
const SWEET_SPOT_LOW  := 60.0   # Cam bắt đầu — cố định
const SWEET_SPOT_PEAK := 80.0   # Đỏ Rực bắt đầu — cố định
const BASE_HEAT_RATE  := 90.0   # Tốc độ gia nhiệt cơ bản khi bơm
const HEAT_DECAY_RATE := 16.0   # Tốc độ giảm nhiệt 16.0/s khi nhả bơm
const TIER_MULTIPLIERS := {
	"lanh":   0.7,   # < 60           → −30% (thép lạnh, cứng, khó rèn)
	"cam":    1.2,   # 60 đến peak    → +20% (nhiệt vừa đủ)
	"do_ruc": 1.4,   # peak đến burn  → +40% (đỉnh nhiệt, thép mềm nhất)
	"chay":   0.5,   # ≥ burn_point   → −50% (thép cháy, hạt tinh thể vỡ)
}

# Vùng Cháy bắt đầu — hẹp dần theo rarity, vùng Đỏ Rực càng khó bắt:
#   rarity 1 → 92  (Đỏ Rực = 12%)
#   rarity 2 → 88  (Đỏ Rực =  8%)
#   rarity 3 → 84  (Đỏ Rực =  4%)
var burn_point: float = 92.0
var heat: float = 0.0
var is_pumping: bool = false
var is_active: bool = false

# Quán tính nhiệt
var heat_velocity: float = 0.0

# Tiến độ chín thép & thời gian các vùng nhiệt (~3.5s)
var cook_progress: float = 0.0
var do_ruc_time: float = 0.0
var total_cook_time: float = 0.0
var burn_timer: float = 0.0
var last_tier: String = ""

# Tăng khi reputation cao — thanh nhiệt chạy nhanh hơn
var _heat_rate_multiplier: float = 1.0
var _is_burnt: bool = false


func start_phase(reputation_level: int = 0, rarity: int = 1) -> void:
	heat = 0.0
	heat_velocity = 0.0
	cook_progress = 0.0
	do_ruc_time = 0.0
	total_cook_time = 0.0
	burn_timer = 0.0
	last_tier = ""
	_is_burnt = false
	is_pumping = false
	is_active = true
	match rarity:
		1: burn_point = 92.0
		2: burn_point = 88.0
		3: burn_point = 84.0
		_: burn_point = 92.0
	# Rarity 1=×1.0 | 2=×1.6 | 3=×2.2 — thanh chạy nhanh hơn → đỉnh nhiệt khó bắt hơn
	var rarity_mult: float = 1.0 + (rarity - 1) * 0.6
	_heat_rate_multiplier = (1.0 + reputation_level * 0.1) * rarity_mult


# Gọi release() khi người chơi nhả phím hoặc tự động khi chín/cháy
func release() -> String:
	if not is_active:
		return last_tier
	is_active = false
	is_pumping = false
	var tier := _get_tier(heat)
	last_tier = tier
	EventBus.phase1_completed.emit(tier)
	return tier


func get_multiplier(tier: String) -> float:
	return TIER_MULTIPLIERS.get(tier, 1.0)


# Thưởng / phạt tỉ lệ cửa sổ nhát đập cho Phase 2 (+0.15 khi do_ruc, 0.0 khi cam, -0.15 khi lanh/chay)
func get_perfect_bonus_for_phase2(tier: String = "") -> float:
	var check_tier := tier if not tier.is_empty() else last_tier
	match check_tier:
		"do_ruc":
			return 0.15
		"cam":
			return 0.0
		"lanh", "chay":
			return -0.15
		_:
			return 0.0


func _process(delta: float) -> void:
	if not is_active:
		return

	# Quán tính nhiệt: khi bơm tăng tốc nhịp nhàng, khi nhả hãm lùi về -HEAT_DECAY_RATE
	if is_pumping:
		var target_speed := BASE_HEAT_RATE * _heat_rate_multiplier
		heat_velocity = move_toward(heat_velocity, target_speed, 220.0 * delta)
	else:
		heat_velocity = move_toward(heat_velocity, -HEAT_DECAY_RATE, 160.0 * delta)

	heat = clampf(heat + heat_velocity * delta, HEAT_MIN, HEAT_MAX)

	# Tích lũy tiến độ chín thép theo vùng nhiệt
	if heat >= burn_point:
		burn_timer += delta
		if burn_timer >= 1.2:
			_is_burnt = true
			release()
			return
	else:
		burn_timer = maxf(0.0, burn_timer - delta * 0.8)

	if heat >= SWEET_SPOT_PEAK and heat < burn_point:
		# Đỏ Rực [80, burn_point): tiến độ chín nhanh (~2.8s)
		cook_progress = minf(1.0, cook_progress + delta / 2.8)
		do_ruc_time += delta
		total_cook_time += delta
	elif heat >= SWEET_SPOT_LOW and heat < SWEET_SPOT_PEAK:
		# Cam [60, 80): tiến độ chín vừa (~3.8s)
		cook_progress = minf(1.0, cook_progress + delta / 3.8)
		total_cook_time += delta

	# Tự động kết thúc khi chín hoàn toàn
	if cook_progress >= 1.0:
		cook_progress = 1.0
		release()


func _get_tier(h: float) -> String:
	if _is_burnt or burn_timer >= 1.2 or h >= burn_point:
		return "chay"
	var ratio := (do_ruc_time / total_cook_time) if total_cook_time > 0.0 else 0.0
	if cook_progress >= 1.0 and ratio >= 0.40:
		return "do_ruc"
	if cook_progress >= 1.0 or h >= SWEET_SPOT_LOW:
		return "cam"
	return "lanh"
