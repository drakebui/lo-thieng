# UI test scene cho Phase 1: Nung Thép
# Giữ SPACE để bơm, nhả để kết thúc
extends Control

const _FORGE_SCRIPT := preload("res://scripts/forge/forge_system.gd")
const _HEAT_BAR_SCRIPT := preload("res://scripts/forge/heat_bar.gd")
const _PHASE_INDICATOR_SCRIPT := preload("res://scripts/forge/forge_phase_indicator.gd")
const BAR_WIDTH  := 1400.0
const BAR_HEIGHT := 140.0
const BACKGROUND_PATH := "res://assets/sprites/forge/backgrounds/Forge Scene BG.PNG"

var _forge: Node
var _heat_bar: HeatBar
var _heat_label: Label
var _zone_label: Label
var _instruct_label: Label
var _result_container: VBoxContainer
var _result_label: Label
var _multiplier_label: Label
var _lbl_eff_lanh: Label
var _lbl_eff_cam: Label
var _lbl_eff_do_ruc: Label
var _lbl_eff_chay: Label
var _tip_label: Label
var _label_pulse: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := TextureRect.new()
	bg.texture = load(BACKGROUND_PATH) as Texture2D
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_forge = _FORGE_SCRIPT.new()
	add_child(_forge)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 48)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "NUNG THÉP — Phase 1"
	title.add_theme_font_size_override("font_size", 104)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_build_heat_bar())

	_heat_label = Label.new()
	_heat_label.text = "Nhiệt độ: 0 / 100"
	_heat_label.add_theme_font_size_override("font_size", 76)
	_heat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_heat_label)

	_zone_label = Label.new()
	_zone_label.text = "Sẵn sàng..."
	_zone_label.add_theme_font_size_override("font_size", 64)
	_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_zone_label)

	_tip_label = Label.new()
	_tip_label.text = "Cam = an toàn (+20%)  •  Đỏ Rực = mạo hiểm (+40%)  •  Cháy Thép = hỏng (−50%)"
	_tip_label.add_theme_font_size_override("font_size", 38)
	_tip_label.add_theme_color_override("font_color", Color(0.72, 0.67, 0.52))
	_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_tip_label)

	_instruct_label = Label.new()
	_instruct_label.text = "Giữ [SPACE] để bơm ống bễ — Nhả để kết thúc"
	_instruct_label.add_theme_font_size_override("font_size", 52)
	_instruct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_instruct_label)

	_result_container = VBoxContainer.new()
	_result_container.visible = false
	_result_container.add_theme_constant_override("separation", 32)
	vbox.add_child(_result_container)

	_result_container.add_child(HSeparator.new())

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 88)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_container.add_child(_result_label)

	_multiplier_label = Label.new()
	_multiplier_label.add_theme_font_size_override("font_size", 60)
	_multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_container.add_child(_multiplier_label)

	var retry := Button.new()
	retry.text = "[ Rèn lại   (R) ]"
	retry.add_theme_font_size_override("font_size", 52)
	retry.pressed.connect(_on_retry_pressed)
	_result_container.add_child(retry)

	EventBus.phase1_completed.connect(_on_phase1_completed)
	_forge.start_phase(0)
	_update_heat_bar_thresholds()
	_set_indicator_phase(_PHASE_INDICATOR_SCRIPT.Phase.NUNG_THEP)


func _set_indicator_phase(phase: int) -> void:
	var indicator := get_node_or_null("ForgePhaseIndicator")
	if indicator == null:
		return
	indicator.set_phase(phase)
	move_child(indicator, get_child_count() - 1)


func _build_heat_bar() -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 8)

	_heat_bar = _HEAT_BAR_SCRIPT.new()
	_heat_bar.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	wrapper.add_child(_heat_bar)

	# Hàng effect: luôn hiển thị multiplier của từng zone
	var eff_row := HBoxContainer.new()

	_lbl_eff_lanh = Label.new()
	_lbl_eff_lanh.text = "−30%"
	_lbl_eff_lanh.add_theme_font_size_override("font_size", 36)
	_lbl_eff_lanh.add_theme_color_override("font_color", Color(0.6, 0.72, 0.95))
	eff_row.add_child(_lbl_eff_lanh)

	_lbl_eff_cam = Label.new()
	_lbl_eff_cam.text = "+20%"
	_lbl_eff_cam.add_theme_font_size_override("font_size", 36)
	_lbl_eff_cam.add_theme_color_override("font_color", Color(0.95, 0.62, 0.18))
	_lbl_eff_cam.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eff_row.add_child(_lbl_eff_cam)

	_lbl_eff_do_ruc = Label.new()
	_lbl_eff_do_ruc.text = "+40% ★"
	_lbl_eff_do_ruc.add_theme_font_size_override("font_size", 36)
	_lbl_eff_do_ruc.add_theme_color_override("font_color", Color(1.0, 0.45, 0.05))
	_lbl_eff_do_ruc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eff_row.add_child(_lbl_eff_do_ruc)

	_lbl_eff_chay = Label.new()
	_lbl_eff_chay.text = "−50%"
	_lbl_eff_chay.add_theme_font_size_override("font_size", 36)
	_lbl_eff_chay.add_theme_color_override("font_color", Color(0.55, 0.25, 0.10))
	_lbl_eff_chay.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	eff_row.add_child(_lbl_eff_chay)

	wrapper.add_child(eff_row)
	return wrapper


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo:
		return
	if event.keycode == KEY_SPACE:
		if event.pressed and _forge.is_active:
			_forge.is_pumping = true
		elif not event.pressed and _forge.is_active:
			_forge.release()
	if event.keycode == KEY_R and event.pressed and not _forge.is_active:
		_on_retry_pressed()


func _process(delta: float) -> void:
	var h: float = _forge.heat
	_heat_bar.heat_percent = h / 100.0
	_heat_bar.tick_animation(delta)
	_heat_label.text = "Nhiệt độ: %d / 100" % int(h)
	if _forge.is_active:
		_label_pulse += delta
		_update_zone_feedback(h)
		_animate_zone_label(h)


func _animate_zone_label(h: float) -> void:
	if h >= _forge.burn_point:
		# Cháy: flash nhanh — thép đã hỏng, panic
		var a: float = 0.45 + sin(_label_pulse * 12.0) * 0.55
		_zone_label.modulate = Color(1.0, 1.0, 1.0, a)
	elif h >= _forge.SWEET_SPOT_PEAK:
		# Đỏ Rực: pulse urgency — nhả ngay!
		var a: float = 0.70 + sin(_label_pulse * 6.0) * 0.30
		_zone_label.modulate = Color(1.0, 1.0, 1.0, a)
	else:
		_zone_label.modulate = Color.WHITE


func _update_zone_feedback(h: float) -> void:
	if h < _forge.SWEET_SPOT_LOW:
		_zone_label.text = "[ Lạnh ]   Tiếp tục bơm..."
		_zone_label.add_theme_color_override("font_color", Color(0.6, 0.72, 0.95))
	elif h < _forge.SWEET_SPOT_PEAK:
		_zone_label.text = "[ Cam ]   Sweet spot — có thể nhả!"
		_zone_label.add_theme_color_override("font_color", Color(0.95, 0.62, 0.18))
	elif h < _forge.burn_point:
		_zone_label.text = "[ Đỏ Rực ]   ĐỈNH NHIỆT — Nhả ngay!"
		_zone_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.05))
	else:
		_zone_label.text = "[ Cháy Thép ]   Thép đã hỏng!"
		_zone_label.add_theme_color_override("font_color", Color(0.55, 0.25, 0.10))


func _on_phase1_completed(tier: String) -> void:
	_result_container.visible = true
	_instruct_label.visible = false

	var mult: float = _forge.get_multiplier(tier)
	var pct := int(abs(mult - 1.0) * 100)
	var sign_str := "+" if mult >= 1.0 else "-"
	var tier_name: String = {
		"lanh":   "Lạnh",
		"cam":    "Cam",
		"do_ruc": "Đỏ Rực",
		"chay":   "Cháy Thép",
	}.get(tier, tier)

	_result_label.text = "Kết quả: %s" % tier_name
	_multiplier_label.text = "Nhân stats: ×%.1f  (%s%d%%)" % [mult, sign_str, pct]

	var tier_color := Color.WHITE
	match tier:
		"lanh":   tier_color = Color(0.6, 0.72, 0.95)
		"cam":    tier_color = Color(0.95, 0.62, 0.18)
		"do_ruc": tier_color = Color(1.0, 0.45, 0.05)
		"chay":   tier_color = Color(0.55, 0.25, 0.10)
	_result_label.add_theme_color_override("font_color", tier_color)


func _on_retry_pressed() -> void:
	_result_container.visible = false
	_instruct_label.visible = true
	_zone_label.text = "Sẵn sàng..."
	_zone_label.add_theme_color_override("font_color", Color.WHITE)
	_zone_label.modulate = Color.WHITE
	_label_pulse = 0.0
	_forge.start_phase(0)
	_update_heat_bar_thresholds()


func _update_heat_bar_thresholds() -> void:
	var low_frac: float  = _forge.SWEET_SPOT_LOW  / 100.0
	var peak_frac: float = _forge.SWEET_SPOT_PEAK / 100.0
	var burn_frac: float = _forge.burn_point      / 100.0

	_heat_bar.set_thresholds(low_frac, peak_frac, burn_frac)

	_lbl_eff_lanh.custom_minimum_size.x   = BAR_WIDTH * low_frac
	_lbl_eff_cam.custom_minimum_size.x    = BAR_WIDTH * (peak_frac - low_frac)
	_lbl_eff_do_ruc.custom_minimum_size.x = BAR_WIDTH * (burn_frac - peak_frac)
	_lbl_eff_chay.custom_minimum_size.x   = BAR_WIDTH * (1.0 - burn_frac)
