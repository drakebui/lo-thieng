class_name DaySceneCardUI
extends CanvasLayer

signal closed

const CARD_SIZE := Vector2(1020, 320)
const FADE_DURATION := 0.85
const TITLE_COLOR := Color("#F5D87A")
const BODY_COLOR := Color(0.92, 0.88, 0.78, 0.82)

var _continue_btn: Button


func show_day(day: int) -> void:
	layer = 45
	_build_ui(day)


func _build_ui(day: int) -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.88)
	root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := HoaTamUI.make_panel_container(false, 42.0)
	panel.custom_minimum_size = CARD_SIZE
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_bottom", 34)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 22)
	vbox.modulate.a = 0.0
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Ngày %d — Buổi Sáng" % day
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	vbox.add_child(title)

	var body := Label.new()
	body.text = "Thị trấn Tây Hương"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 20)
	body.add_theme_color_override("font_color", BODY_COLOR)
	vbox.add_child(body)

	_continue_btn = Button.new()
	_continue_btn.custom_minimum_size = Vector2(200, 56)
	_continue_btn.text = "Bắt Đầu"
	HoaTamUI.apply_primary_button(_continue_btn, 22)
	_continue_btn.visible = false
	_continue_btn.disabled = true
	_continue_btn.pressed.connect(_close)
	vbox.add_child(_continue_btn)

	var tween := create_tween()
	tween.tween_property(vbox, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_callback(_enable_continue)


func _enable_continue() -> void:
	_continue_btn.visible = true
	_continue_btn.disabled = false


func _close() -> void:
	closed.emit()
	queue_free()
