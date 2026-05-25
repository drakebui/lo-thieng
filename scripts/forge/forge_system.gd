extends Node

# Hệ thống rèn Phase 1: Nung Thép
# Kết quả emit qua EventBus.phase1_completed(result_tier)

const HEAT_MIN        := 0.0
const HEAT_MAX        := 100.0
const SWEET_SPOT_LOW  := 60.0   # Cam bắt đầu — cố định
const SWEET_SPOT_PEAK := 80.0   # Đỏ Rực bắt đầu — cố định
const BASE_HEAT_RATE  := 15.0
const HEAT_DECAY_RATE := 5.0
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

# Tăng khi reputation cao — thanh nhiệt chạy nhanh hơn
var _heat_rate_multiplier: float = 1.0


func start_phase(reputation_level: int = 0, rarity: int = 1) -> void:
	heat = 0.0
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


# Gọi release() khi người chơi nhả phím — kết thúc phase và emit signal
func release() -> String:
	if not is_active:
		return ""
	is_active = false
	is_pumping = false
	var tier := _get_tier(heat)
	EventBus.phase1_completed.emit(tier)
	return tier


func get_multiplier(tier: String) -> float:
	return TIER_MULTIPLIERS.get(tier, 1.0)


func _process(delta: float) -> void:
	if not is_active:
		return
	if is_pumping:
		heat = clampf(heat + BASE_HEAT_RATE * _heat_rate_multiplier * delta, HEAT_MIN, HEAT_MAX)
	else:
		heat = clampf(heat - HEAT_DECAY_RATE * delta, HEAT_MIN, HEAT_MAX)


func _get_tier(h: float) -> String:
	if h < SWEET_SPOT_LOW:
		return "lanh"
	if h < SWEET_SPOT_PEAK:
		return "cam"
	if h < burn_point:
		return "do_ruc"
	return "chay"
