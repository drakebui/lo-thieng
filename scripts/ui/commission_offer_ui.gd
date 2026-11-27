# Panel hiện khi có commission mới — player chọn Nhận Đơn / Bỏ Qua.
class_name CommissionOfferUI
extends CanvasLayer

const PANEL_SIZE := Vector2(740, 480)

var _commission: CommissionData = null
var _queue: Array[CommissionData] = []

var _title_lbl: Label
var _reason_lbl: Label
var _hint_lbl: Label
var _reward_lbl: Label
var _flavor_lbl: Label


func _ready() -> void:
	layer = 18
	visible = false
	_build_ui()
	EventBus.commission_offered.connect(_on_commission_offered)


func show_commission(c: CommissionData) -> void:
	if c == null:
		return
	_commission = c
	_title_lbl.text = "ĐƠN ĐẶT RÈN — %s" % c.giver_npc_id.to_upper()
	_reason_lbl.text = c.reason_text
	_hint_lbl.text = "Gợi ý: %s" % c.hint_region
	_reward_lbl.text = "Thưởng: %d G · Tiếng tăm +%d · Thân thiết +%d" % [
		c.reward_gold, c.reward_reputation, c.reward_affinity,
	]
	_flavor_lbl.text = "\"%s\"" % c.flavor_accept
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
	header.add_child(HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(HoaTamUI.HudIcon.DEBT), 34))

	_title_lbl = Label.new()
	_title_lbl.add_theme_font_size_override("font_size", 28)
	_title_lbl.add_theme_color_override("font_color", HoaTamUI.COL_CRIMSON_INK)
	header.add_child(_title_lbl)

	_reason_lbl = _make_block(21, HoaTamUI.COL_INK)
	vbox.add_child(_reason_lbl)

	_hint_lbl = _make_block(18, HoaTamUI.COL_INK_MUTE)
	vbox.add_child(_hint_lbl)

	var reward_row := HBoxContainer.new()
	reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_row.add_theme_constant_override("separation", 10)
	vbox.add_child(reward_row)
	reward_row.add_child(HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(HoaTamUI.HudIcon.GOLD), 26))
	_reward_lbl = _make_block(20, HoaTamUI.COL_CRIMSON_INK)
	reward_row.add_child(_reward_lbl)

	_flavor_lbl = _make_block(18, HoaTamUI.COL_INK_MUTE)
	_flavor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_flavor_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_row)

	var accept_btn := Button.new()
	accept_btn.text = "Nhận Đơn"
	accept_btn.custom_minimum_size = Vector2(220, 56)
	HoaTamUI.apply_primary_button(accept_btn, 22)
	accept_btn.pressed.connect(_on_accept_pressed)
	btn_row.add_child(accept_btn)

	var skip_btn := Button.new()
	skip_btn.text = "Bỏ Qua"
	skip_btn.custom_minimum_size = Vector2(200, 56)
	HoaTamUI.apply_parchment_button(skip_btn, 22)
	skip_btn.pressed.connect(_on_skip_pressed)
	btn_row.add_child(skip_btn)


func _make_block(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _on_commission_offered(c: CommissionData) -> void:
	if c == null:
		return
	if visible:
		_queue.append(c)
		return
	show_commission(c)


func _on_accept_pressed() -> void:
	if _commission != null:
		CommissionSystem.accept(_commission.commission_id)
	_commission = null
	_advance_queue()


func _on_skip_pressed() -> void:
	_commission = null
	_advance_queue()


func _advance_queue() -> void:
	if _queue.is_empty():
		visible = false
		return
	var next: CommissionData = _queue.pop_front()
	show_commission(next)
