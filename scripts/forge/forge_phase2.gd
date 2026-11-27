# Phase 2: Rèn Búa 2 Hướng "Cương / Nhu" Tất Định — 5 nhát búa con lắc liên tục
# - Búa Nặng — Hướng CƯƠNG (Space / Chuột Trái): thiên Công/Thủ (cuong_hits += 1)
# - Búa Khéo — Hướng NHU (Enter / Chuột Phải): thiên Tốc/Linh (nhu_hits += 1)
# Xóa bỏ hoàn toàn ngẫu nhiên (.pick_random()): 100% ánh xạ tất định từ (score, cuong_hits, nhu_hits)
# Kết quả emit EventBus.phase2_completed(score, prefix_tier)
extends Node

signal beat_started(beat_index: int, perfect_center: float)
signal strike_resolved(result: int, strike_index: int, running_score: int)

enum HitResult { PERFECT, GOOD, MISS }

const STYLE_CUONG := "cuong"
const STYLE_NHU := "nhu"

const TOTAL_STRIKES      := 5
const BASE_BEAT_DURATION := 1.5   # giây mỗi nhát ở rarity 1
const BEAT_SPEEDUP_STEP  := 0.07  # mỗi nhát sau nhanh hơn 7% tạo cao trào nhát 4-5
const PERFECT_HALF_WIDTH := 0.08  # ±8% quanh tâm
const GOOD_HALF_WIDTH    := 0.18  # ±18% quanh tâm
const BREATH_DURATION    := 0.22  # nhịp thở 0.22s khi đổi chiều / sau mỗi nhát đập

# GATE D — Trần tiền tố theo bậc nguyên liệu (T1 max 1, T2 max 3, T3 max 5)
const MATERIAL_PREFIX_CAP: Dictionary = {
	1: 1,
	2: 3,
	3: 5,
}

var score: int = 0
var combo_count: int = 0
var current_strike: int = 0
var cuong_hits: int = 0
var nhu_hits: int = 0
var last_strike_style: String = STYLE_CUONG
var strike_styles: Array[String] = []
var is_active: bool = false
var beat_progress: float = 0.0
var perfect_center: float = 0.55
var window_scale: float = 1.0
var direction: float = 1.0

var _base_beat_duration: float = BASE_BEAT_DURATION
var _beat_duration: float = BASE_BEAT_DURATION
var _material_rarity: int = 1

var _hit_this_beat: bool = false
var _is_breathing: bool = false
var _breath_timer: float = 0.0
var _between_beats: bool = false


func start_phase(
	p_window_scale: float = 1.0,
	p_beat_duration: float = BASE_BEAT_DURATION,
	material_rarity: int = 1
) -> void:
	score = 0
	combo_count = 0
	current_strike = 0
	cuong_hits = 0
	nhu_hits = 0
	last_strike_style = STYLE_CUONG
	strike_styles.clear()
	is_active = true
	_is_breathing = false
	_breath_timer = 0.0
	_between_beats = false
	window_scale = p_window_scale
	_base_beat_duration = p_beat_duration
	_beat_duration = p_beat_duration
	_material_rarity = material_rarity
	direction = -1.0  # _next_beat sẽ lật thành +1.0 để bắt đầu từ trái sang phải
	_next_beat()


func try_hit(style: String = STYLE_CUONG) -> void:
	if not is_active or _hit_this_beat or _between_beats or _is_breathing:
		return
	var normalized_style := STYLE_NHU if style == STYLE_NHU else STYLE_CUONG
	_hit_this_beat = true
	_resolve_hit(beat_progress, normalized_style)


func get_combo_count() -> int:
	return combo_count


func _process(delta: float) -> void:
	if not is_active:
		return

	if _is_breathing:
		_breath_timer -= delta
		if _breath_timer <= 0.0:
			_is_breathing = false
			_between_beats = false
			_next_beat()
		return

	beat_progress += direction * (delta / _beat_duration)
	if direction > 0.0 and beat_progress >= 1.0:
		beat_progress = 1.0
		if not _hit_this_beat:
			_hit_this_beat = true
			_resolve_hit(1.0, "")
	elif direction < 0.0 and beat_progress <= 0.0:
		beat_progress = 0.0
		if not _hit_this_beat:
			_hit_this_beat = true
			_resolve_hit(0.0, "")


func _resolve_hit(progress: float, style: String = STYLE_CUONG) -> void:
	var dist := absf(progress - perfect_center)
	var perfect_w := PERFECT_HALF_WIDTH * window_scale
	var good_w    := GOOD_HALF_WIDTH    * window_scale

	if style == STYLE_CUONG:
		cuong_hits += 1
	elif style == STYLE_NHU:
		nhu_hits += 1
	last_strike_style = style
	strike_styles.append(style)

	var result: HitResult
	if style == "":
		result = HitResult.MISS
		score -= 1
		combo_count = 0
	elif dist <= perfect_w:
		result = HitResult.PERFECT
		score += 1
		combo_count += 1
	elif dist <= good_w:
		result = HitResult.GOOD
		combo_count = 0
	else:
		result = HitResult.MISS
		score -= 1
		combo_count = 0

	strike_resolved.emit(result, current_strike, score)
	current_strike += 1

	if current_strike >= TOTAL_STRIKES:
		is_active = false
		var prefix_tier := _score_to_prefix(score)
		EventBus.phase2_completed.emit(score, prefix_tier)
		return

	# Nhịp thở 0.22s mượt mà sau nhát đập
	_is_breathing = true
	_breath_timer = BREATH_DURATION
	_between_beats = true


func _next_beat() -> void:
	_hit_this_beat = false
	_between_beats = false
	direction = -direction
	if direction > 0.0:
		beat_progress = 0.0
		# Con lắc chạy trái -> phải: tâm hoàn hảo nảy sang nửa phải [0.55, 0.72]
		perfect_center = randf_range(0.55, 0.72)
	else:
		beat_progress = 1.0
		# Con lắc chạy phải -> trái: tâm hoàn hảo nảy sang nửa trái [0.28, 0.45]
		perfect_center = randf_range(0.28, 0.45)

	var speed_factor := maxf(0.65, 1.0 - float(current_strike) * BEAT_SPEEDUP_STEP)
	_beat_duration = _base_beat_duration * speed_factor
	beat_started.emit(current_strike, perfect_center)


func _score_to_prefix(raw_score: int) -> String:
	return resolve_deterministic_prefix(raw_score, _material_rarity, cuong_hits, nhu_hits)


## Bảng Ánh Xạ Tiền Tố Tất Định 100% — xóa sạch ngẫu nhiên, trả về đúng tiền tố theo ý đồ Cương/Nhu
static func resolve_deterministic_prefix(
	raw_score: int,
	material_rarity: int,
	p_cuong_hits: int,
	p_nhu_hits: int
) -> String:
	var cap: int = MATERIAL_PREFIX_CAP.get(clampi(material_rarity, 1, 3), 1)
	var capped_score: int = mini(raw_score, cap)

	if capped_score <= -4:
		return "phan_chu"
	if capped_score in [-3, -2]:
		return "curse_nang"
	if capped_score == -1:
		return "curse_nhe"
	if capped_score == 0:
		return "thuong"
	if capped_score == 1:
		if p_cuong_hits >= 4:
			return "nang_tay"
		if p_nhu_hits >= 4:
			return "than_toc"
		return "tot"
	if capped_score == 2:
		return "kiet_tac" if p_cuong_hits > p_nhu_hits else "can_bang"
	if capped_score == 3:
		return "to_nghe" if p_cuong_hits > p_nhu_hits else "huyen_bi"
	if capped_score == 4:
		return "cung_nhu_da" if p_cuong_hits > p_nhu_hits else "khi_phach"
	return "perfect" if p_cuong_hits > p_nhu_hits else "truong_sinh"


func get_prefix_name(tier: String) -> String:
	return ForgeConverter.PREFIX_NAMES.get(tier, tier)
