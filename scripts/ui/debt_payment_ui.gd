class_name DebtPaymentUI
extends CanvasLayer

const DEFAULT_CHECKPOINT_ID := "c1_mat_bang"
const PANEL_SIZE := Vector2(640, 360)
const PANEL_PADDING := 44

var _title_lbl: Label
var _amount_lbl: Label
var _gold_lbl: Label
var _message_lbl: Label
var _pay_btn: Button
var _skip_btn: Button
var _checkpoint: DebtCheckpoint
var _checkpoint_id := DEFAULT_CHECKPOINT_ID


func _ready() -> void:
	layer = 18
	visible = false
	_build_ui()
	GameManager.gold_changed.connect(func(_amount: int) -> void:
		_refresh()
	)


func show_payment(checkpoint_id: String = DEFAULT_CHECKPOINT_ID) -> void:
	_checkpoint_id = checkpoint_id
	_checkpoint = _find_checkpoint(_checkpoint_id)
	if _checkpoint == null or _checkpoint.is_paid:
		visible = false
		return

	visible = true
	_pay_btn.disabled = false
	_skip_btn.text = "Bỏ qua"
	_message_lbl.text = ""
	_refresh()


func _build_ui() -> void:
	var viewport_size := get_viewport().get_visible_rect().size

	var backdrop := ColorRect.new()
	backdrop.position = Vector2.ZERO
	backdrop.size = viewport_size
	backdrop.color = Color(0.02, 0.02, 0.03, 0.58)
	add_child(backdrop)

	var panel := ColorRect.new()
	panel.position = (viewport_size - PANEL_SIZE) * 0.5
	panel.size = PANEL_SIZE
	panel.color = Color(0.08, 0.08, 0.10, 0.95)
	add_child(panel)

	_title_lbl = Label.new()
	_title_lbl.text = "Thanh toán khoản nợ"
	_title_lbl.position = Vector2(PANEL_PADDING, 28)
	_title_lbl.size = Vector2(PANEL_SIZE.x - PANEL_PADDING * 2.0, 42)
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 30)
	_title_lbl.add_theme_color_override("font_color", Color(0.95, 0.84, 0.54))
	panel.add_child(_title_lbl)

	_amount_lbl = _make_line(panel, Vector2(PANEL_PADDING, 98))
	_gold_lbl = _make_line(panel, Vector2(PANEL_PADDING, 142))

	_message_lbl = Label.new()
	_message_lbl.position = Vector2(PANEL_PADDING, 188)
	_message_lbl.size = Vector2(PANEL_SIZE.x - PANEL_PADDING * 2.0, 34)
	_message_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_lbl.add_theme_font_size_override("font_size", 22)
	panel.add_child(_message_lbl)

	_pay_btn = Button.new()
	_pay_btn.text = "Trả nợ"
	_pay_btn.position = Vector2(130, 266)
	_pay_btn.size = Vector2(170, 52)
	_pay_btn.add_theme_font_size_override("font_size", 22)
	_pay_btn.pressed.connect(_on_pay_pressed)
	panel.add_child(_pay_btn)

	_skip_btn = Button.new()
	_skip_btn.text = "Bỏ qua"
	_skip_btn.position = Vector2(340, 266)
	_skip_btn.size = Vector2(170, 52)
	_skip_btn.add_theme_font_size_override("font_size", 22)
	_skip_btn.pressed.connect(_on_skip_pressed)
	panel.add_child(_skip_btn)


func _make_line(parent: Node, position: Vector2) -> Label:
	var label := Label.new()
	label.position = position
	label.size = Vector2(PANEL_SIZE.x - PANEL_PADDING * 2.0, 34)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.88, 0.82, 0.70))
	parent.add_child(label)
	return label


func _refresh() -> void:
	if _checkpoint == null:
		return
	_title_lbl.text = "Thanh toán: %s" % _checkpoint.title
	_amount_lbl.text = "Còn thiếu: %dG" % _get_amount_due(_checkpoint)
	_gold_lbl.text = "Vàng hiện tại: %dG" % GameManager.gold


func _get_amount_due(checkpoint: DebtCheckpoint) -> int:
	var amount := checkpoint.amount_gold
	if checkpoint.is_late:
		amount += checkpoint.penalty_gold
	return amount


func _find_checkpoint(id: String) -> DebtCheckpoint:
	for checkpoint in DebtSystem.checkpoints:
		if checkpoint.id == id:
			return checkpoint
	return null


func _on_pay_pressed() -> void:
	if DebtSystem.pay_checkpoint(_checkpoint_id):
		_message_lbl.text = "Đã trả. Xong việc ở đây."
		_message_lbl.add_theme_color_override("font_color", Color(0.60, 0.95, 0.60))
		_pay_btn.disabled = true
		_skip_btn.text = "Đóng"
		await get_tree().create_timer(1.2).timeout
		visible = false
	else:
		_message_lbl.text = "Không đủ vàng."
		_message_lbl.add_theme_color_override("font_color", Color(1.0, 0.32, 0.28))


func _on_skip_pressed() -> void:
	visible = false
