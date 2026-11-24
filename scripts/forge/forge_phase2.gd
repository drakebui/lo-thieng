# Phase 2: Rèn Búa — 5 nhát búa, timing-based con lắc liên tục
# Kết quả emit EventBus.phase2_completed(score, prefix_tier)
extends Node

signal beat_started(beat_index: int, perfect_center: float)
signal strike_resolved(result: int, strike_index: int, running_score: int)

enum HitResult { PERFECT, GOOD, MISS }

const TOTAL_STRIKES      := 5
const BASE_BEAT_DURATION := 1.5   # giây mỗi nhát ở rarity 1
const BEAT_SPEEDUP_STEP  := 0.07  # mỗi nhát sau nhanh hơn 7% tạo cao trào nhát 4-5
const PERFECT_HALF_WIDTH := 0.08  # ±8% quanh tâm
const GOOD_HALF_WIDTH    := 0.18  # ±18% quanh tâm
const BREATH_DURATION    := 0.22  # nhịp thở 0.22s khi đổi chiều / sau mỗi nhát đập

var score: int = 0
var combo_count: int = 0
var current_strike: int = 0
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


func try_hit() -> void:
	if not is_active or _hit_this_beat or _between_beats or _is_breathing:
		return
	_hit_this_beat = true
	_resolve_hit(beat_progress)


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
			_resolve_hit(1.0)
	elif direction < 0.0 and beat_progress <= 0.0:
		beat_progress = 0.0
		if not _hit_this_beat:
			_hit_this_beat = true
			_resolve_hit(0.0)


func _resolve_hit(progress: float) -> void:
	var dist := absf(progress - perfect_center)
	var perfect_w := PERFECT_HALF_WIDTH * window_scale
	var good_w    := GOOD_HALF_WIDTH    * window_scale

	var result: HitResult
	if dist <= perfect_w:
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
		EventBus.phase2_completed.emit(score, _score_to_prefix(score))
		return

	# Nhịp thở 0.22s mượt mà sau nhát đập, không dùng create_timer gây khựng đơ
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


func _score_to_prefix(s: int) -> String:
	# GATE D — Prefix Eligibility Cap
	# Material rarity acts as tier (1=T1 Thô, 2=T2 Tinh, 3=T3 Thượng).
	# T1 max prefix score = 1  → "Tot" prefix ceiling
	# T2 max prefix score = 3  → "Kiet Tac"/"Can Bang" ceiling
	# T3 max prefix score = 5  → full "Perfect" unlock
	const MATERIAL_PREFIX_CAP: Dictionary = {
		1: 1,
		2: 3,
		3: 5,
	}
	s = mini(s, MATERIAL_PREFIX_CAP.get(_material_rarity, 5))
	# GDD Section 6.2: score +2/+3/+4/+5 mỗi mức có 2 prefix ngẫu nhiên
	var prefix_tier := "thuong"
	match s:
		-5, -4:
			prefix_tier = "phan_chu"
		-3, -2:
			prefix_tier = "curse_nang"
		-1:
			prefix_tier = "curse_nhe"
		1:
			prefix_tier = (["tot", "nang_tay", "than_toc"] as Array).pick_random()
		2:
			prefix_tier = (["kiet_tac", "can_bang"] as Array).pick_random()
		3:
			prefix_tier = (["to_nghe", "huyen_bi"] as Array).pick_random()
		4:
			prefix_tier = (["cung_nhu_da", "khi_phach"] as Array).pick_random()
		5:
			prefix_tier = (["truong_sinh", "perfect"] as Array).pick_random()
		_:
			pass
	return prefix_tier


func get_prefix_name(tier: String) -> String:
	return {
		"phan_chu":   "Phản Chủ",
		"curse_nang": "Lời Nguyền",
		"curse_nhe":  "Nguyền Nhẹ",
		"thuong":     "Thường",
		"tot":        "Tốt",
		"kiet_tac":   "Kiệt Tác",
		"to_nghe":    "Tổ Nghề",
		"khi_phach":  "Khí Phách",
		"perfect":    "PERFECT",
	}.get(tier, tier)
