extends Node

# Hệ thống rèn Phase 1: Nung Thép
# Kết quả emit qua EventBus.phase1_completed(result_tier)

const HEAT_MIN       := 0.0
const HEAT_MAX       := 100.0
const SWEET_SPOT_LOW := 60.0   # Cam bắt đầu — cố định cho mọi rarity

# Vàng Kim bắt đầu — thay đổi theo rarity để thu nhỏ vùng vàng:
#   rarity 1 → 72  (Gold = 28%)
#   rarity 2 → 80  (Gold = 20%)
#   rarity 3 → 91  (Gold =  9%)
var sweet_spot_high: float = 80.0

# Đơn vị/giây
const BASE_HEAT_RATE := 15.0
const HEAT_DECAY_RATE := 5.0

# Multiplier kết quả theo tier
const TIER_MULTIPLIERS := {
	"lanh":    0.7,  # <60  → -30%
	"cam":     1.2,  # 60-80 → +20%
	"vang_kim": 1.4, # >80  → +40%
}

var heat: float = 0.0
var is_pumping: bool = false
var is_active: bool = false

# Tăng khi reputation cao — thanh nhiệt chạy nhanh hơn
var _heat_rate_multiplier: float = 1.0


func start_phase(reputation_level: int = 0, rarity: int = 1) -> void:
	heat = 0.0
	is_pumping = false
	is_active = true
	# Vùng vàng kim co lại theo rarity: 1★=28%, 2★=20%, 3★=9%
	match rarity:
		1: sweet_spot_high = 72.0
		2: sweet_spot_high = 80.0
		3: sweet_spot_high = 91.0
		_: sweet_spot_high = 80.0
	# Rarity 1=×1.0 | 2=×1.6 | 3=×2.2 — thanh chạy nhanh hơn → vàng kim khó bắt hơn
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
	elif h <= sweet_spot_high:
		return "cam"
	else:
		return "vang_kim"
