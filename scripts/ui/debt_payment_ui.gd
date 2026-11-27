class_name DebtPaymentUI
extends CanvasLayer

const DEFAULT_CHECKPOINT_ID := "c1_mat_bang"
const PANEL_SIZE := Vector2(680, 410)

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
	_skip_btn.text = "Để Sau"
	_message_lbl.text = ""
	_refresh()


func _build_ui() -> void:
	add_child(HoaTamUI.make_dim_backdrop())

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := HoaTamUI.make_panel_container(true, 40.0)
	panel.custom_minimum_size = PANEL_SIZE
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)
	header.add_child(HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(HoaTamUI.HudIcon.DEBT), 40))

	_title_lbl = Label.new()
	_title_lbl.text = "THANH TOÁN KHOẢN NỢ"
	_title_lbl.add_theme_font_size_override("font_size", 32)
	_title_lbl.add_theme_color_override("font_color", HoaTamUI.COL_CRIMSON_INK)
	header.add_child(_title_lbl)

	var amount_row := HBoxContainer.new()
	amount_row.alignment = BoxContainer.ALIGNMENT_CENTER
	amount_row.add_theme_constant_override("separation", 10)
	vbox.add_child(amount_row)
	amount_row.add_child(HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(HoaTamUI.HudIcon.GOLD), 30))
	_amount_lbl = _make_line()
	amount_row.add_child(_amount_lbl)

	_gold_lbl = _make_line()
	_gold_lbl.add_theme_color_override("font_color", HoaTamUI.COL_INK_MUTE)
	vbox.add_child(_gold_lbl)

	_message_lbl = Label.new()
	_message_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_lbl.add_theme_font_size_override("font_size", 22)
	_message_lbl.add_theme_color_override("font_color", HoaTamUI.COL_CRIMSON_INK)
	vbox.add_child(_message_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 22)
	vbox.add_child(btn_row)

	_pay_btn = Button.new()
	_pay_btn.text = "Trả Đủ Nợ"
	_pay_btn.custom_minimum_size = Vector2(210, 58)
	HoaTamUI.apply_primary_button(_pay_btn, 22)
	_pay_btn.pressed.connect(_on_pay_pressed)
	btn_row.add_child(_pay_btn)

	_skip_btn = Button.new()
	_skip_btn.text = "Để Sau"
	_skip_btn.custom_minimum_size = Vector2(180, 58)
	HoaTamUI.apply_parchment_button(_skip_btn, 22)
	_skip_btn.pressed.connect(_on_skip_pressed)
	btn_row.add_child(_skip_btn)


func _make_line() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", HoaTamUI.COL_INK)
	return label


func _refresh() -> void:
	if _checkpoint == null:
		return
	var total := _checkpoint.amount_gold
	if _checkpoint.is_late:
		total += _checkpoint.penalty_gold
	_title_lbl.text = _checkpoint.title.to_upper()
	_amount_lbl.text = "Số tiền cần nộp: %d G" % total
	_gold_lbl.text = "Vàng hiện có trong xưởng: %d G" % GameManager.gold
	_pay_btn.disabled = _checkpoint.is_paid or GameManager.gold < total


func _on_pay_pressed() -> void:
	if _checkpoint == null:
		return
	if DebtSystem.pay_checkpoint(_checkpoint.id):
		_message_lbl.add_theme_color_override("font_color", Color(0.16, 0.42, 0.24))
		_message_lbl.text = "Đã thanh toán đủ khoản nợ."
		_pay_btn.disabled = true
		_skip_btn.text = "Đóng"
		_refresh()
	else:
		_message_lbl.add_theme_color_override("font_color", HoaTamUI.COL_CRIMSON_INK)
		_message_lbl.text = "Chưa đủ vàng để thanh toán."


func _on_skip_pressed() -> void:
	visible = false


func _find_checkpoint(checkpoint_id: String) -> DebtCheckpoint:
	for checkpoint in DebtSystem.checkpoints:
		if checkpoint.id == checkpoint_id:
			return checkpoint
	return null
