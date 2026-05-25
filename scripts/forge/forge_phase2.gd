# Phase 2: Rèn Búa — 5 nhát búa, timing-based
# Kết quả emit EventBus.phase2_completed(score, prefix_tier)
extends Node

signal beat_started(beat_index: int, perfect_center: float)
signal strike_resolved(result: int, strike_index: int, running_score: int)

enum HitResult { PERFECT, GOOD, MISS }

const TOTAL_STRIKES      := 5
const BASE_BEAT_DURATION := 1.5   # giây mỗi nhát ở rarity 1
const PERFECT_HALF_WIDTH := 0.08  # ±8% quanh tâm
const GOOD_HALF_WIDTH    := 0.18  # ±18% quanh tâm
# Difficulty: Story=1.5, Normal=1.0, Hardcore=0.7 — nhân vào half-width

var score: int = 0
var current_strike: int = 0
var is_active: bool = false
var beat_progress: float = 0.0
var perfect_center: float = 0.55
var window_scale: float = 1.0
var _beat_duration: float = BASE_BEAT_DURATION
var _material_rarity: int = 1

var _hit_this_beat: bool = false
var _between_beats: bool = false


func start_phase(
	p_window_scale: float = 1.0,
	p_beat_duration: float = BASE_BEAT_DURATION,
	material_rarity: int = 1
) -> void:
	score = 0
	current_strike = 0
	is_active = true
	_between_beats = false
	window_scale = p_window_scale
	_beat_duration = p_beat_duration
	_material_rarity = material_rarity
	_next_beat()


func try_hit() -> void:
	if not is_active or _hit_this_beat or _between_beats:
		return
	_hit_this_beat = true
	_resolve_hit(beat_progress)


func _process(delta: float) -> void:
	if not is_active or _between_beats:
		return
	beat_progress = minf(beat_progress + delta / _beat_duration, 1.0)
	if beat_progress >= 1.0 and not _hit_this_beat:
		_hit_this_beat = true
		_resolve_hit(1.0)


func _resolve_hit(progress: float) -> void:
	var dist := absf(progress - perfect_center)
	var perfect_w := PERFECT_HALF_WIDTH * window_scale
	var good_w    := GOOD_HALF_WIDTH    * window_scale

	var result: HitResult
	if dist <= perfect_w:
		result = HitResult.PERFECT
		score += 1
	elif dist <= good_w:
		result = HitResult.GOOD
	else:
		result = HitResult.MISS
		score -= 1

	strike_resolved.emit(result, current_strike, score)
	current_strike += 1

	if current_strike >= TOTAL_STRIKES:
		is_active = false
		EventBus.phase2_completed.emit(score, _score_to_prefix(score))
		return

	_between_beats = true
	await get_tree().create_timer(0.5).timeout
	_between_beats = false
	_next_beat()


func _next_beat() -> void:
	beat_progress = 0.0
	_hit_this_beat = false
	perfect_center = randf_range(0.38, 0.72)
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
