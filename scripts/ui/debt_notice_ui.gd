class_name DebtNoticeUI
extends CanvasLayer

signal notice_closed

const PANEL_SIZE := Vector2(680, 420)
const PANEL_PADDING := 42

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
	_amount_lbl.text = "Số tiền: %dG" % checkpoint.amount_gold
	_deadline_lbl.text = "Hạn: Ngày %d" % checkpoint.deadline_day
	visible = true


func _build_ui() -> void:
	var viewport_size := get_viewport().get_visible_rect().size

	var backdrop := ColorRect.new()
	backdrop.position = Vector2.ZERO
	backdrop.size = viewport_size
	backdrop.color = Color(0.02, 0.01, 0.0, 0.58)
	add_child(backdrop)

	var panel := ColorRect.new()
	panel.position = (viewport_size - PANEL_SIZE) * 0.5
	panel.size = PANEL_SIZE
	panel.color = Color(0.10, 0.07, 0.04, 0.94)
	add_child(panel)

	_title_lbl = Label.new()
	_title_lbl.text = "Thông Báo Khoản Nợ"
	_title_lbl.position = Vector2(PANEL_PADDING, 24)
	_title_lbl.size = Vector2(PANEL_SIZE.x - PANEL_PADDING * 2.0, 38)
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 28)
	_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32))
	panel.add_child(_title_lbl)

	_agent_name_lbl = Label.new()
	_agent_name_lbl.position = Vector2(PANEL_PADDING, 72)
	_agent_name_lbl.size = Vector2(PANEL_SIZE.x - PANEL_PADDING * 2.0, 28)
	_agent_name_lbl.add_theme_font_size_override("font_size", 20)
	_agent_name_lbl.add_theme_color_override("font_color", Color(0.72, 0.54, 0.38))
	_agent_name_lbl.visible = false
	panel.add_child(_agent_name_lbl)

	_agent_desc_lbl = Label.new()
	_agent_desc_lbl.position = Vector2(PANEL_PADDING, 100)
	_agent_desc_lbl.size = Vector2(PANEL_SIZE.x - PANEL_PADDING * 2.0, 44)
	_agent_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_agent_desc_lbl.add_theme_font_size_override("font_size", 18)
	_agent_desc_lbl.add_theme_color_override("font_color", Color(0.80, 0.70, 0.55))
	_agent_desc_lbl.visible = false
	panel.add_child(_agent_desc_lbl)

	_quote_lbl = Label.new()
	_quote_lbl.position = Vector2(PANEL_PADDING, 156)
	_quote_lbl.size = Vector2(PANEL_SIZE.x - PANEL_PADDING * 2.0, 90)
	_quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_quote_lbl.add_theme_font_size_override("font_size", 22)
	_quote_lbl.add_theme_color_override("font_color", Color(0.96, 0.86, 0.66))
	panel.add_child(_quote_lbl)

	_amount_lbl = _make_line(panel, Vector2(PANEL_PADDING, 260))
	_deadline_lbl = _make_line(panel, Vector2(PANEL_PADDING, 296))

	var close_btn := Button.new()
	close_btn.text = "Đã hiểu"
	close_btn.position = Vector2(PANEL_SIZE.x - 220, 352)
	close_btn.size = Vector2(178, 46)
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.pressed.connect(_on_close_pressed)
	panel.add_child(close_btn)


func _make_line(parent: Node, position: Vector2) -> Label:
	var label := Label.new()
	label.position = position
	label.size = Vector2(PANEL_SIZE.x - PANEL_PADDING * 2.0, 32)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.90, 0.78, 0.55))
	parent.add_child(label)
	return label


func _on_debt_triggered(checkpoint: DebtCheckpoint) -> void:
	show_checkpoint(checkpoint)


func _on_close_pressed() -> void:
	visible = false
	notice_closed.emit()
	EventBus.debt_notice_closed.emit()
