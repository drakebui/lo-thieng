# scripts/ui/day_summary_ui.gd
# Overlay tổng kết cuối ngày: vàng kiếm được, ngày tiếp theo, lưu game
# Stub — implement đầy đủ ở bước Phase 4
class_name DaySummaryUI
extends CanvasLayer

func _ready() -> void:
	layer   = 16
	visible = false
	_build_placeholder()


func _build_placeholder() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.02, 0.01, 0.85)
	root.add_child(bg)

	var panel := ColorRect.new()
	panel.position = Vector2(312, 200)
	panel.size     = Vector2(400, 280)
	panel.color    = Color(0.14, 0.09, 0.04)
	root.add_child(panel)

	var title := Label.new()
	title.text                = "Kết Thúc Ngày"
	title.position            = Vector2(312, 220)
	title.size                = Vector2(400, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.28))
	root.add_child(title)

	var day_lbl := Label.new()
	day_lbl.text                = "Ngày %d kết thúc." % GameManager.current_day
	day_lbl.position            = Vector2(312, 276)
	day_lbl.size                = Vector2(400, 28)
	day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_lbl.add_theme_font_size_override("font_size", 20)
	day_lbl.add_theme_color_override("font_color", Color(0.90, 0.82, 0.65))
	root.add_child(day_lbl)

	var next_btn := Button.new()
	next_btn.text     = "Sang Ngày Mới"
	next_btn.position = Vector2(362, 400)
	next_btn.size     = Vector2(300, 52)
	next_btn.add_theme_font_size_override("font_size", 22)
	next_btn.pressed.connect(_on_next_day)
	root.add_child(next_btn)


func _on_next_day() -> void:
	GameManager.advance_day()
	GameManager.clear_hand()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			visible = false
			get_viewport().set_input_as_handled()
