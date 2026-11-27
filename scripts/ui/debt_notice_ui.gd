class_name DebtNoticeUI
extends CanvasLayer

signal notice_closed

const PANEL_SIZE := Vector2(720, 460)

var _title_lbl: Label
var _agent_name_lbl: Label
var _agent_desc_lbl: Label
var _quote_lbl: Label
var _amount_lbl: Label
var _deadline_lbl: Label


func _ready() -> void:
	layer = 17
	visible = false
	_build_ui()
	if not DebtSystem.debt_triggered.is_connected(_on_debt_triggered):
		DebtSystem.debt_triggered.connect(_on_debt_triggered)


func show_checkpoint(checkpoint: DebtCheckpoint) -> void:
	if checkpoint.agent_name != "":
		_agent_name_lbl.text = checkpoint.agent_name
		_agent_name_lbl.visible = true
	if checkpoint.agent_description != "":
		_agent_desc_lbl.text = checkpoint.agent_description
		_agent_desc_lbl.visible = true
	_quote_lbl.text = "\"%s\"" % checkpoint.agent_quote
	_amount_lbl.text = "Số tiền: %d G" % checkpoint.amount_gold
	_deadline_lbl.text = "Hạn chót: Tối Ngày %d" % checkpoint.deadline_day
	visible = true


func _build_ui() -> void:
	add_child(HoaTamUI.make_dim_backdrop())

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := HoaTamUI.make_panel_container(true, 40.0)
	panel.custom_minimum_size = PANEL_SIZE
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)
	header.add_child(HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(HoaTamUI.HudIcon.DEBT), 38))

	_title_lbl = Label.new()
	_title_lbl.text = "KHẾ ƯỚC BÁO NỢ"
	_title_lbl.add_theme_font_size_override("font_size", 32)
	_title_lbl.add_theme_color_override("font_color", HoaTamUI.COL_CRIMSON_INK)
	header.add_child(_title_lbl)

	_agent_name_lbl = Label.new()
	_agent_name_lbl.add_theme_font_size_override("font_size", 22)
	_agent_name_lbl.add_theme_color_override("font_color", HoaTamUI.COL_INK)
	_agent_name_lbl.visible = false
	vbox.add_child(_agent_name_lbl)

	_agent_desc_lbl = Label.new()
	_agent_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_agent_desc_lbl.add_theme_font_size_override("font_size", 18)
	_agent_desc_lbl.add_theme_color_override("font_color", HoaTamUI.COL_INK_MUTE)
	_agent_desc_lbl.visible = false
	vbox.add_child(_agent_desc_lbl)

	_quote_lbl = Label.new()
	_quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quote_lbl.add_theme_font_size_override("font_size", 22)
	_quote_lbl.add_theme_color_override("font_color", HoaTamUI.COL_INK)
	vbox.add_child(_quote_lbl)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 24)
	vbox.add_child(stats_row)
	stats_row.add_child(HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(HoaTamUI.HudIcon.GOLD), 28))
	_amount_lbl = _make_line(HoaTamUI.COL_CRIMSON_INK)
	stats_row.add_child(_amount_lbl)
	_deadline_lbl = _make_line(HoaTamUI.COL_INK)
	stats_row.add_child(_deadline_lbl)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(footer)

	var close_btn := Button.new()
	close_btn.text = "Đã Hiểu"
	close_btn.custom_minimum_size = Vector2(200, 56)
	HoaTamUI.apply_primary_button(close_btn, 22)
	close_btn.pressed.connect(_on_close_pressed)
	footer.add_child(close_btn)


func _make_line(color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	return label


func _on_debt_triggered(checkpoint: DebtCheckpoint) -> void:
	show_checkpoint(checkpoint)


func _on_close_pressed() -> void:
	visible = false
	notice_closed.emit()
	EventBus.debt_notice_closed.emit()
