class_name ForgePhaseIndicator
extends Control

enum Phase {
	CHON_PHOI = 0,
	CHON_NL = 1,
	CHON_LINH_LUC = 2,
	NUNG_THEP = 3,
	REN_BUA = 4,
	TOI_LUYEN = 5,
}

const COLOR_DONE := Color("#8B4513")
const COLOR_ACTIVE := Color.WHITE
const COLOR_PENDING := Color(0.6, 0.4, 0.2, 0.5)
const STEP_SIZE := 50.0
const STEP_NAMES := [
	"Step1",
	"Step2",
	"Step3",
	"Step4",
	"Step5",
	"Step6",
]

var current_phase: int = 0

var _active_tween: Tween
var _done_tweens: Dictionary = {}
var _reported_done := [false, false, false, false, false, false]


func _ready() -> void:
	set_phase(Phase.CHON_PHOI)


func set_phase(new_phase: int) -> void:
	current_phase = clampi(new_phase, Phase.CHON_PHOI, Phase.TOI_LUYEN)
	print("ForgePhaseIndicator: active step %d" % (current_phase + 1))
	_refresh_all_steps()


func advance() -> void:
	if current_phase < Phase.TOI_LUYEN:
		set_phase(current_phase + 1)


func _refresh_all_steps() -> void:
	if _active_tween:
		_active_tween.kill()
		_active_tween = null
	for tween: Tween in _done_tweens.values():
		if tween:
			tween.kill()
	_done_tweens.clear()

	for i in range(6):
		var step := _get_step(i)
		var icon := step.get_node("Icon") as TextureRect
		var check := step.get_node("Checkmark") as TextureRect

		step.pivot_offset = Vector2(STEP_SIZE * 0.5, STEP_SIZE * 0.5)
		if i < current_phase:
			icon.modulate = COLOR_DONE
			check.visible = true
			step.scale = Vector2.ONE
			if not _reported_done[i]:
				_reported_done[i] = true
				print("ForgePhaseIndicator: step %d completed" % (i + 1))
				_animate_done(step)
		elif i == current_phase:
			icon.modulate = COLOR_ACTIVE
			check.visible = false
			step.scale = Vector2.ONE
			_animate_active(step)
		else:
			icon.modulate = COLOR_PENDING
			check.visible = false
			step.scale = Vector2.ONE


func _animate_active(step: Control) -> void:
	_active_tween = create_tween().set_loops()
	_active_tween.tween_property(step, "scale", Vector2(1.1, 1.1), 0.6) \
		.set_ease(Tween.EASE_IN_OUT)
	_active_tween.tween_property(step, "scale", Vector2.ONE, 0.6) \
		.set_ease(Tween.EASE_IN_OUT)


func _animate_done(step: Control) -> void:
	var tween := create_tween()
	_done_tweens[step.name] = tween
	tween.tween_property(step, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(step, "scale", Vector2.ONE, 0.1)


func _get_step(index: int) -> Control:
	return $ScrollBg/IconRow.get_node(STEP_NAMES[index]) as Control
