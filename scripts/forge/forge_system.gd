extends Node

# Hệ thống rèn Phase 1: Nung Thép theo Đặc Tính Vật Lý (2 Hồ Sơ Nhiệt)
# - Phôi Nặng (bua_chien, giao_dai, khien_dong): lửa Đỏ Rực 80–92%, giữ nhiệt bền, cháy chậm 4.5s
# - Phôi Thanh & Phép (kiem_don, song_dao, gay_phep): lửa Đỏ Rực 65–80%, bơm nhạy hơn, dễ cháy 3.0s
# Kết quả emit qua EventBus.phase1_completed(result_tier)

const HEAT_MIN        := 0.0
const HEAT_MAX        := 100.0
const SWEET_SPOT_LOW  := 55.0   # Mặc định tương thích ngược (Phôi Nặng)
const SWEET_SPOT_PEAK := 80.0   # Mặc định tương thích ngược (Phôi Nặng)
const BASE_HEAT_RATE  := 90.0   # Tốc độ gia nhiệt cơ bản khi bơm
const HEAT_DECAY_RATE := 16.0   # Tốc độ giảm nhiệt cơ bản khi nhả bơm

const HEAVY_BLANKS: Array[String] = [
	"bua_chien",
	"giao_dai",
	"khien_dong",
	"dao_phat",
]

const HEAT_PROFILES: Dictionary = {
	"heavy": {
		"key": "heavy",
		"label": "Phôi Nặng",
		"low": 55.0,
		"peak": 80.0,
		"burn": 92.0,
		"burn_limit": 4.5,
		"decay_mult": 0.85,
		"bellows_mult": 1.00,
		"range_text": "Lửa chuẩn: 80–92%",
		"book_note": "Phôi Nặng — cần lửa Đỏ Rực 80–92%",
	},
	"light": {
		"key": "light",
		"label": "Phôi Thanh & Phép",
		"low": 48.0,
		"peak": 65.0,
		"burn": 80.0,
		"burn_limit": 3.0,
		"decay_mult": 1.00,
		"bellows_mult": 1.12,
		"range_text": "Lửa chuẩn: 65–80%",
		"book_note": "Phôi Thanh/Phép — lửa Chuẩn 65–80%",
	},
}

const TIER_MULTIPLIERS := {
	"lanh":   0.7,   # dưới ngưỡng Cam        → −30% (thép lạnh, cứng, khó rèn)
	"cam":    1.2,   # Cam đến Đỏ Rực         → +20% (nhiệt vừa đủ)
	"do_ruc": 1.4,   # Đỏ Rực đến Cháy        → +40% (đỉnh nhiệt, thép mềm nhất)
	"chay":   0.5,   # quá ngưỡng cháy        → −50% (thép cháy, hạt tinh thể vỡ)
}

var sweet_spot_low: float = 55.0
var sweet_spot_peak: float = 80.0
var burn_point: float = 92.0
var burn_limit: float = 4.5
var decay_mult: float = 0.85
var bellows_mult: float = 1.00
var profile_key: String = "heavy"
var profile_range_text: String = "Lửa chuẩn: 80–92%"

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

# Tăng khi reputation cao hoặc nguyên liệu bậc cao — thanh nhiệt chạy nhanh hơn
var _heat_rate_multiplier: float = 1.0
var _is_burnt: bool = false


static func get_heat_profile(blank_id: String) -> Dictionary:
	if blank_id in HEAVY_BLANKS:
		return HEAT_PROFILES["heavy"]
	return HEAT_PROFILES["light"]


func start_phase(
	reputation_level: int = 0,
	rarity: int = 1,
	blank_id: String = ""
) -> void:
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

	var profile: Dictionary = get_heat_profile(blank_id)
	profile_key = String(profile["key"])
	sweet_spot_low = float(profile["low"])
	sweet_spot_peak = float(profile["peak"])
	burn_point = float(profile["burn"])
	burn_limit = float(profile["burn_limit"])
	decay_mult = float(profile["decay_mult"])
	bellows_mult = float(profile["bellows_mult"])
	profile_range_text = String(profile["range_text"])

	# Rarity 1=×1.0 | 2=×1.35 | 3=×1.7 — bậc cao nóng nhanh hơn nhưng vẫn giữ đúng khoảng % vật lý
	var rarity_mult: float = 1.0 + float(maxi(0, rarity - 1)) * 0.35
	_heat_rate_multiplier = (1.0 + float(reputation_level) * 0.1) * rarity_mult


func get_profile_range_text() -> String:
	return profile_range_text


# Gọi release() khi người chơi kết thúc sớm hoặc tự động khi chín/cháy
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

	# Quán tính nhiệt: Phôi Thanh nhạy bễ hơn (bellows_mult=1.12), Phôi Nặng giữ nhiệt bền (decay_mult=0.85)
	if is_pumping:
		var target_speed := BASE_HEAT_RATE * _heat_rate_multiplier * bellows_mult
		heat_velocity = move_toward(heat_velocity, target_speed, 220.0 * delta)
	else:
		var target_decay := -HEAT_DECAY_RATE * decay_mult
		heat_velocity = move_toward(heat_velocity, target_decay, 160.0 * delta)

	heat = clampf(heat + heat_velocity * delta, HEAT_MIN, HEAT_MAX)

	# Quá nhiệt: tích lũy burn_timer tới ngưỡng burn_limit riêng theo hồ sơ phôi
	if heat >= burn_point:
		burn_timer += delta
		if burn_timer >= burn_limit:
			_is_burnt = true
			release()
			return
	else:
		burn_timer = maxf(0.0, burn_timer - delta * 0.8)

	if heat >= sweet_spot_peak and heat < burn_point:
		# Vùng Đỏ Rực: tiến độ chín nhanh (~2.8s)
		cook_progress = minf(1.0, cook_progress + delta / 2.8)
		do_ruc_time += delta
		total_cook_time += delta
	elif heat >= sweet_spot_low and heat < sweet_spot_peak:
		# Vùng Cam: tiến độ chín vừa (~3.8s)
		cook_progress = minf(1.0, cook_progress + delta / 3.8)
		total_cook_time += delta

	# Tự động kết thúc khi chín hoàn toàn
	if cook_progress >= 1.0:
		cook_progress = 1.0
		release()


func _get_tier(h: float) -> String:
	if _is_burnt or burn_timer >= burn_limit or h >= burn_point:
		return "chay"
	var ratio := (do_ruc_time / total_cook_time) if total_cook_time > 0.0 else 0.0
	if cook_progress >= 1.0 and ratio >= 0.40:
		return "do_ruc"
	if cook_progress >= 1.0 or (cook_progress >= 0.6 and h >= sweet_spot_low):
		return "cam"
	return "lanh"
