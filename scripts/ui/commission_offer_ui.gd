# Panel hiện khi có commission mới — player chọn Nhận Đơn / Bỏ Qua.
# Pattern tái dùng từ DebtNoticeUI: CanvasLayer + build UI bằng code.
class_name CommissionOfferUI
extends CanvasLayer

const PANEL_SIZE := Vector2(720, 460)
const PADDING := 40

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
	_title_lbl.text = "Đơn Đặt Hàng — %s" % c.giver_npc_id
	_reason_lbl.text = c.reason_text
	_hint_lbl.text = c.hint_region
	_reward_lbl.text = "Thưởng: %dG · Tiếng tăm +%d · Cảm tình +%d" % [
		c.reward_gold, c.reward_reputation, c.reward_affinity,
	]
	_flavor_lbl.text = "\"%s\"" % c.flavor_accept
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
	_title_lbl.position = Vector2(PADDING, 24)
	_title_lbl.size = Vector2(PANEL_SIZE.x - PADDING * 2.0, 38)
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 26)
	_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32))
	panel.add_child(_title_lbl)

	_reason_lbl = _make_block(panel, Vector2(PADDING, 80), 120, 20,
		Color(0.96, 0.86, 0.66))
	_hint_lbl = _make_block(panel, Vector2(PADDING, 210), 80, 18,
		Color(0.78, 0.72, 0.55))
	_reward_lbl = _make_block(panel, Vector2(PADDING, 300), 30, 20,
		Color(1.0, 0.88, 0.38))
	_flavor_lbl = _make_block(panel, Vector2(PADDING, 336), 60, 18,
		Color(0.72, 0.66, 0.50))

	var accept_btn := Button.new()
	accept_btn.text = "Nhận Đơn"
	accept_btn.position = Vector2(PADDING, PANEL_SIZE.y - 70)
	accept_btn.size = Vector2(220, 50)
	accept_btn.add_theme_font_size_override("font_size", 22)
	accept_btn.pressed.connect(_on_accept_pressed)
	panel.add_child(accept_btn)

	var skip_btn := Button.new()
	skip_btn.text = "Bỏ Qua"
	skip_btn.position = Vector2(PANEL_SIZE.x - 220 - PADDING, PANEL_SIZE.y - 70)
	skip_btn.size = Vector2(220, 50)
	skip_btn.add_theme_font_size_override("font_size", 22)
	skip_btn.pressed.connect(_on_skip_pressed)
	panel.add_child(skip_btn)


func _make_block(parent: Node, pos: Vector2, height: int,
		font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = Vector2(PANEL_SIZE.x - PADDING * 2.0, height)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _on_commission_offered(c: CommissionData) -> void:
	if c == null:
		return
	# Hàng đợi để player không bị mất đơn khi 2 offer fire liên tiếp.
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
