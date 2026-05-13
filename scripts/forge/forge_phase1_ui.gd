# UI test scene cho Phase 1: Nung Thép
# Giữ SPACE để bơm, nhả để kết thúc
extends Control

const _FORGE_SCRIPT := preload("res://scripts/forge/forge_system.gd")
const BAR_WIDTH  := 1400.0
const BAR_HEIGHT := 140.0

var _forge: Node
var _heat_indicator: ColorRect
var _heat_label: Label
var _zone_label: Label
var _instruct_label: Label
var _result_container: VBoxContainer
var _result_label: Label
var _multiplier_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.09, 0.07)
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


func _build_heat_bar() -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 8)

	var bar := Control.new()
	bar.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	wrapper.add_child(bar)

	# Zone Lạnh: 0–60
	var z_lanh := ColorRect.new()
	z_lanh.color = Color(0.22, 0.28, 0.45)
	z_lanh.position = Vector2.ZERO
	z_lanh.size = Vector2(BAR_WIDTH * 0.6, BAR_HEIGHT)
	bar.add_child(z_lanh)

	# Zone Cam: 60–80
	var z_cam := ColorRect.new()
	z_cam.color = Color(0.85, 0.45, 0.08)
	z_cam.position = Vector2(BAR_WIDTH * 0.6, 0.0)
	z_cam.size = Vector2(BAR_WIDTH * 0.2, BAR_HEIGHT)
	bar.add_child(z_cam)

	# Zone Vàng Kim: 80–100
	var z_gold := ColorRect.new()
	z_gold.color = Color(0.92, 0.76, 0.1)
	z_gold.position = Vector2(BAR_WIDTH * 0.8, 0.0)
	z_gold.size = Vector2(BAR_WIDTH * 0.2, BAR_HEIGHT)
	bar.add_child(z_gold)

	_heat_indicator = ColorRect.new()
	_heat_indicator.color = Color.WHITE
	_heat_indicator.size = Vector2(8.0, BAR_HEIGHT)
	_heat_indicator.position = Vector2.ZERO
	bar.add_child(_heat_indicator)

	# Nhãn tên zone
	var row := HBoxContainer.new()

	var l_lanh := Label.new()
	l_lanh.text = "Lạnh  (<60)"
	l_lanh.add_theme_font_size_override("font_size", 40)
	l_lanh.add_theme_color_override("font_color", Color(0.6, 0.72, 0.95))
	l_lanh.custom_minimum_size.x = BAR_WIDTH * 0.6
	row.add_child(l_lanh)

	var l_cam := Label.new()
	l_cam.text = "Cam"
	l_cam.add_theme_font_size_override("font_size", 40)
	l_cam.add_theme_color_override("font_color", Color(0.95, 0.62, 0.18))
	l_cam.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_cam.custom_minimum_size.x = BAR_WIDTH * 0.2
	row.add_child(l_cam)

	var l_gold := Label.new()
	l_gold.text = "Vàng Kim"
	l_gold.add_theme_font_size_override("font_size", 40)
	l_gold.add_theme_color_override("font_color", Color(0.95, 0.86, 0.2))
	l_gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l_gold.custom_minimum_size.x = BAR_WIDTH * 0.2
	row.add_child(l_gold)

	wrapper.add_child(row)
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


func _process(_delta: float) -> void:
	var h: float = _forge.heat
	_heat_indicator.position.x = clampf(h / 100.0 * BAR_WIDTH - 4.0, 0.0, BAR_WIDTH - 8.0)
	_heat_label.text = "Nhiệt độ: %d / 100" % int(h)
	if _forge.is_active:
		_update_zone_feedback(h)


func _update_zone_feedback(h: float) -> void:
	if h < 60.0:
		_zone_label.text = "[ Lạnh ]   Tiếp tục bơm..."
		_zone_label.add_theme_color_override("font_color", Color(0.6, 0.72, 0.95))
	elif h <= 80.0:
		_zone_label.text = "[ Cam ]   Sweet spot — Nhả ngay!"
		_zone_label.add_theme_color_override("font_color", Color(0.95, 0.62, 0.18))
	else:
		_zone_label.text = "[ Vàng Kim ]   Quá nóng!"
		_zone_label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.2))


func _on_phase1_completed(tier: String) -> void:
	_result_container.visible = true
	_instruct_label.visible = false

	var mult: float = _forge.get_multiplier(tier)
	var pct := int(abs(mult - 1.0) * 100)
	var sign_str := "+" if mult >= 1.0 else "-"
	var tier_name: String = {"lanh": "Lạnh", "cam": "Cam", "vang_kim": "Vàng Kim"}.get(tier, tier)

	_result_label.text = "Kết quả: %s" % tier_name
	_multiplier_label.text = "Nhân stats: ×%.1f  (%s%d%%)" % [mult, sign_str, pct]

	var tier_color := Color.WHITE
	match tier:
		"lanh":     tier_color = Color(0.6, 0.72, 0.95)
		"cam":      tier_color = Color(0.95, 0.62, 0.18)
		"vang_kim": tier_color = Color(0.95, 0.86, 0.2)
	_result_label.add_theme_color_override("font_color", tier_color)


func _on_retry_pressed() -> void:
	_result_container.visible = false
	_instruct_label.visible = true
	_zone_label.text = "Sẵn sàng..."
	_zone_label.add_theme_color_override("font_color", Color.WHITE)
	_forge.start_phase(0)
