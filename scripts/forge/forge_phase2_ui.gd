# UI test scene cho Phase 2: Rèn Búa
# Nhấn SPACE đúng lúc — 5 nhát, căn timing vào vùng vàng
extends Control

const _PHASE2_SCRIPT := preload("res://scripts/forge/forge_phase2.gd")
const _PHASE_INDICATOR_SCRIPT := preload("res://scripts/forge/forge_phase_indicator.gd")
const BAR_WIDTH     := 1400.0
const BAR_HEIGHT    := 140.0
const COLOR_PERFECT := Color(0.95, 0.86, 0.2)
const COLOR_GOOD    := Color(0.85, 0.55, 0.1)
const COLOR_MISS    := Color(0.75, 0.22, 0.18)
const BACKGROUND_PATH := "res://assets/sprites/forge/backgrounds/Forge Scene BG.PNG"

var _phase2: Node

# Widgets thanh nhịp
var _good_zone:      ColorRect
var _perfect_zone:   ColorRect
var _beat_indicator: ColorRect

# Labels thông tin
var _strike_label:   Label
var _score_label:    Label
var _feedback_label: Label
var _instruct_label: Label

# Kết quả cuối
var _result_container: VBoxContainer
var _result_label:     Label
var _prefix_label:     Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := TextureRect.new()
	bg.texture = load(BACKGROUND_PATH) as Texture2D
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_phase2 = _PHASE2_SCRIPT.new()
	add_child(_phase2)
	_phase2.beat_started.connect(_on_beat_started)
	_phase2.strike_resolved.connect(_on_strike_resolved)
	EventBus.phase2_completed.connect(_on_phase2_completed)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 48)
	center.add_child(vbox)

	# Tiêu đề
	var title := Label.new()
	title.text = "RÈN BÚA — Phase 2"
	title.add_theme_font_size_override("font_size", 104)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Nhát búa / điểm
	var info_row := HBoxContainer.new()
	info_row.alignment = BoxContainer.ALIGNMENT_CENTER
	info_row.add_theme_constant_override("separation", 120)
	vbox.add_child(info_row)

	_strike_label = Label.new()
	_strike_label.text = "Nhát  1 / 5"
	_strike_label.add_theme_font_size_override("font_size", 68)
	info_row.add_child(_strike_label)

	_score_label = Label.new()
	_score_label.text = "Điểm:  0"
	_score_label.add_theme_font_size_override("font_size", 68)
	info_row.add_child(_score_label)

	# Thanh nhịp
	vbox.add_child(_build_beat_bar())

	# Feedback nhát vừa đánh
	_feedback_label = Label.new()
	_feedback_label.text = ""
	_feedback_label.add_theme_font_size_override("font_size", 92)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_feedback_label)

	# Hướng dẫn
	_instruct_label = Label.new()
	_instruct_label.text = "Nhấn [SPACE] khi thanh chạm vùng vàng"
	_instruct_label.add_theme_font_size_override("font_size", 52)
	_instruct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_instruct_label)

	# Kết quả cuối
	_result_container = VBoxContainer.new()
	_result_container.visible = false
	_result_container.add_theme_constant_override("separation", 32)
	vbox.add_child(_result_container)

	_result_container.add_child(HSeparator.new())

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 96)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_container.add_child(_result_label)

	_prefix_label = Label.new()
	_prefix_label.add_theme_font_size_override("font_size", 64)
	_prefix_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_container.add_child(_prefix_label)

	var retry := Button.new()
	retry.text = "[ Rèn lại   (R) ]"
	retry.add_theme_font_size_override("font_size", 52)
	retry.pressed.connect(_on_retry_pressed)
	_result_container.add_child(retry)

	_phase2.start_phase(1.0)
	_set_indicator_phase(_PHASE_INDICATOR_SCRIPT.Phase.REN_BUA)


func _set_indicator_phase(phase: int) -> void:
	var indicator := get_node_or_null("ForgePhaseIndicator")
	if indicator == null:
		return
	indicator.set_phase(phase)
	move_child(indicator, get_child_count() - 1)


func _build_beat_bar() -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 8)

	# Thanh nền
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	wrapper.add_child(bar)

	# Nền xám
	var bg_bar := ColorRect.new()
	bg_bar.color = Color(0.2, 0.18, 0.16)
	bg_bar.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bar.add_child(bg_bar)

	# Vùng GOOD (cam, rộng hơn, nằm dưới perfect)
	_good_zone = ColorRect.new()
	_good_zone.color = Color(0.65, 0.35, 0.05, 0.7)
	bar.add_child(_good_zone)

	# Vùng PERFECT (vàng, nằm trên)
	_perfect_zone = ColorRect.new()
	_perfect_zone.color = Color(0.85, 0.72, 0.08, 0.9)
	bar.add_child(_perfect_zone)

	# Indicator (thanh trắng di chuyển)
	_beat_indicator = ColorRect.new()
	_beat_indicator.color = Color.WHITE
	_beat_indicator.size = Vector2(10.0, BAR_HEIGHT)
	bar.add_child(_beat_indicator)

	# Nhãn zone
	var labels_row := HBoxContainer.new()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels_row.add_child(spacer)

	var l_good := Label.new()
	l_good.text = "GOOD"
	l_good.add_theme_color_override("font_color", Color(0.9, 0.62, 0.18))
	l_good.add_theme_font_size_override("font_size", 40)
	labels_row.add_child(l_good)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels_row.add_child(spacer2)

	wrapper.add_child(labels_row)
	return wrapper


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo or not event.pressed:
		return
	if event.keycode == KEY_SPACE and _phase2.is_active:
		_phase2.try_hit()
	if event.keycode == KEY_R and not _phase2.is_active:
		_on_retry_pressed()


func _process(_delta: float) -> void:
	if not _phase2.is_active:
		return
	var prog: float = _phase2.beat_progress
	_beat_indicator.position.x = clampf(prog * BAR_WIDTH - 5.0, 0.0, BAR_WIDTH - 10.0)


func _on_beat_started(beat_index: int, perfect_center: float) -> void:
	_strike_label.text = "Nhát  %d / 5" % (beat_index + 1)
	_feedback_label.text = ""

	var good_w: float = _phase2.GOOD_HALF_WIDTH    * _phase2.window_scale
	var perf_w: float = _phase2.PERFECT_HALF_WIDTH * _phase2.window_scale

	var good_start := clampf((perfect_center - good_w) * BAR_WIDTH, 0.0, BAR_WIDTH)
	var good_end   := clampf((perfect_center + good_w) * BAR_WIDTH, 0.0, BAR_WIDTH)
	_good_zone.position = Vector2(good_start, 0.0)
	_good_zone.size     = Vector2(good_end - good_start, BAR_HEIGHT)

	var perf_start := clampf((perfect_center - perf_w) * BAR_WIDTH, 0.0, BAR_WIDTH)
	var perf_end   := clampf((perfect_center + perf_w) * BAR_WIDTH, 0.0, BAR_WIDTH)
	_perfect_zone.position = Vector2(perf_start, 0.0)
	_perfect_zone.size     = Vector2(perf_end - perf_start, BAR_HEIGHT)


func _on_strike_resolved(result: int, _strike_index: int, running_score: int) -> void:
	_score_label.text = "Điểm:  %d" % running_score

	match result:
		_phase2.HitResult.PERFECT:
			_feedback_label.text = "PERFECT!"
			_feedback_label.add_theme_color_override("font_color", COLOR_PERFECT)
		_phase2.HitResult.GOOD:
			_feedback_label.text = "GOOD"
			_feedback_label.add_theme_color_override("font_color", COLOR_GOOD)
		_phase2.HitResult.MISS:
			_feedback_label.text = "MISS..."
			_feedback_label.add_theme_color_override("font_color", COLOR_MISS)


func _on_phase2_completed(final_score: int, prefix_tier: String) -> void:
	_result_container.visible = true
	_instruct_label.visible   = false
	_feedback_label.text      = ""

	var prefix_name: String = _phase2.get_prefix_name(prefix_tier)
	_result_label.text  = "Vũ khí: %s" % prefix_name
	_prefix_label.text  = "Điểm cuối: %d / 5" % final_score

	var result_color := Color.WHITE
	if final_score >= 4:
		result_color = COLOR_PERFECT
	elif final_score >= 2:
		result_color = COLOR_GOOD
	elif final_score < 0:
		result_color = COLOR_MISS
	_result_label.add_theme_color_override("font_color", result_color)


func _on_retry_pressed() -> void:
	_result_container.visible = false
	_instruct_label.visible   = true
	_feedback_label.text      = ""
	_score_label.text         = "Điểm:  0"
	_phase2.start_phase(1.0)
