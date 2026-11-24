# scripts/ui/day_summary_ui.gd
# Overlay tổng kết cuối ngày: vàng kiếm được, ngày tiếp theo, lưu game
class_name DaySummaryUI
extends CanvasLayer

const PATH_WORKSHOP := "res://scenes/main/WorkshopHub.tscn"
const C1_CHECKPOINT_ID := "c1_mat_bang"
const DAY4_RESOLUTION_DAY := 4

var _title: Label
var _gold_lbl: Label
var _sold_lbl: Label
var _debt_lbl: Label
var _debt_label: Label
var _hint_label: Label
var _resolution_modal: Control
var _resolution_seen: bool = false
var _session_stats: Dictionary = {}

func _ready() -> void:
	layer   = 16
	visible = false
	_build_placeholder()
	GameManager.gold_changed.connect(func(_amount: int) -> void:
		if visible:
			_refresh_summary()
	)
	DebtSystem.debt_paid.connect(func(_checkpoint: DebtCheckpoint) -> void:
		if visible:
			_refresh_summary()
	)


func show_summary(stats: Dictionary = {}) -> void:
	_session_stats = stats.duplicate()
	_resolution_seen = false
	visible = true
	_refresh_summary()


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
	panel.size = Vector2(520, 430)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -panel.size * 0.5
	panel.color    = Color(0.14, 0.09, 0.04)
	root.add_child(panel)

	_title = Label.new()
	_title.position            = Vector2(0, 24)
	_title.size                = Vector2(520, 42)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.28))
	panel.add_child(_title)

	_gold_lbl = Label.new()
	_gold_lbl.position = Vector2(48, 96)
	_gold_lbl.size = Vector2(424, 32)
	_gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_lbl.add_theme_font_size_override("font_size", 22)
	_gold_lbl.add_theme_color_override("font_color", Color(0.90, 0.82, 0.65))
	panel.add_child(_gold_lbl)

	_sold_lbl = Label.new()
	_sold_lbl.position = Vector2(48, 138)
	_sold_lbl.size = Vector2(424, 32)
	_sold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sold_lbl.add_theme_font_size_override("font_size", 22)
	_sold_lbl.add_theme_color_override("font_color", Color(0.90, 0.82, 0.65))
	panel.add_child(_sold_lbl)

	_debt_lbl = _make_label(panel, Vector2(48, 178), Vector2(424, 32))
	_debt_label = _make_label(panel, Vector2(48, 212), Vector2(424, 86))
	_debt_label.name = "DebtTrackerLabel"
	_debt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label = _make_label(panel, Vector2(48, 304), Vector2(424, 42))
	_hint_label.name = "HintLabel"
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.34))

	var next_btn := Button.new()
	next_btn.text     = "Sang Ngày Mới"
	next_btn.position = Vector2(110, 358)
	next_btn.size     = Vector2(300, 52)
	next_btn.add_theme_font_size_override("font_size", 22)
	next_btn.pressed.connect(_on_next_day)
	panel.add_child(next_btn)

	_refresh_summary()


func _on_next_day() -> void:
	if _should_show_day4_resolution():
		_show_day4_resolution(_find_c1_checkpoint())
		return
	_continue_next_day()


func _continue_next_day() -> void:
	var game_over_triggered := false
	if GameManager.current_phase == GameManager.GamePhase.NIGHT:
		DayCycle.advance_phase()
		game_over_triggered = (
			GameManager.consecutive_zero_gold_days
			>= GameManager.GAME_OVER_ZERO_GOLD_THRESHOLD
		)
	else:
		push_warning("Không sang ngày mới: current_phase không phải NIGHT")
	GameManager.clear_hand()
	GameManager.pending_day_summary_stats = {}
	_save_game()
	visible = false
	if game_over_triggered:
		return
	SceneManager.go_to(PATH_WORKSHOP)


func _save_game() -> void:
	SaveSystem.save_game(GameManager.build_save_state())


func _refresh_summary() -> void:
	if _title == null:
		return
	_title.text = "Kết Thúc Ngày %d" % GameManager.current_day
	var earned_today := GameManager.gold - GameManager.day_start_gold
	_gold_lbl.text = "Vàng kiếm được: %d G" % earned_today
	var sold_count: int = _session_stats.get("customers_served", 0)
	_sold_lbl.text = "Vũ khí đã bán: %d" % sold_count
	var c1 := _find_c1_checkpoint()
	if c1 != null:
		if c1.is_paid:
			_debt_lbl.text = "✓ C1 — Đã trả"
			_debt_label.visible = false
			_hint_label.visible = false
		else:
			var owed := c1.amount_gold
			if c1.is_late:
				owed += c1.penalty_gold
			var days_left: int = c1.deadline_day - GameManager.current_day
			_debt_lbl.text = "Nợ C1: %d G · Còn %d ngày" % [owed, days_left]
			var still_need: int = maxi(0, owed - GameManager.gold)
			_debt_label.text = (
				"Checkpoint C1: %dG\n" % owed
				+ "Còn %d ngày | Hiện có: %dG\n" % [days_left, GameManager.gold]
				+ ("Đủ tiền!" if still_need == 0 else "Còn thiếu: %dG" % still_need)
			)
			_debt_label.visible = true
			_hint_label.visible = still_need > 2000
			if _hint_label.visible:
				_hint_label.text = "Ngày mai hãy ra ngoài kiếm nguyên liệu và rèn thêm!"
	else:
		_debt_lbl.text = ""
		_debt_label.visible = false
		_hint_label.visible = false


func _should_show_day4_resolution() -> bool:
	return GameManager.current_day == DAY4_RESOLUTION_DAY \
		and not _resolution_seen \
		and _find_c1_checkpoint() != null


func _show_day4_resolution(c1: DebtCheckpoint) -> void:
	if c1.is_paid:
		_open_resolution_modal(
			"Người Thu Nợ",
			"Người Thu Nợ gật đầu.\n\"Tốt lắm. Tuần tới... sẽ có người khác đến.\""
		)
	else:
		if not c1.is_late:
			c1.is_late = true
		_open_resolution_modal("Quá hạn C1", _day4_penalty_text(c1))


func _day4_penalty_text(c1: DebtCheckpoint) -> String:
	var owed := c1.amount_gold + c1.penalty_gold
	return "Người Thu Nợ ghi thêm tiền phạt.\n" \
		+ "Phạt: +%d G · Tổng nợ: %d G\n" % [c1.penalty_gold, owed] \
		+ "Hint: mở bảng trả nợ vào ban đêm để xử lý trước khi rời lò."


func _open_resolution_modal(title: String, body: String) -> void:
	if _resolution_modal != null:
		return

	var modal := Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	_resolution_modal = modal

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.01, 0.01, 0.72)
	modal.add_child(bg)

	var panel := ColorRect.new()
	panel.size = Vector2(620, 300)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -panel.size * 0.5
	panel.color = Color(0.10, 0.07, 0.04, 0.98)
	modal.add_child(panel)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.position = Vector2(36, 28)
	title_lbl.size = Vector2(548, 42)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.28))
	panel.add_child(title_lbl)

	var body_lbl := Label.new()
	body_lbl.text = body
	body_lbl.position = Vector2(44, 92)
	body_lbl.size = Vector2(532, 104)
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.add_theme_font_size_override("font_size", 22)
	body_lbl.add_theme_color_override("font_color", Color(0.90, 0.82, 0.65))
	panel.add_child(body_lbl)

	var ok_btn := Button.new()
	ok_btn.text = "Tiếp tục"
	ok_btn.position = Vector2(210, 224)
	ok_btn.size = Vector2(200, 50)
	ok_btn.add_theme_font_size_override("font_size", 22)
	ok_btn.pressed.connect(_on_resolution_continue)
	panel.add_child(ok_btn)


func _on_resolution_continue() -> void:
	if _resolution_modal != null:
		_resolution_modal.queue_free()
		_resolution_modal = null
	_resolution_seen = true
	_continue_next_day()


func _make_label(
	parent: Node,
	label_position: Vector2,
	label_size: Vector2 = Vector2(364, 32)
) -> Label:
	var label := Label.new()
	label.position = label_position
	label.size = label_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.90, 0.82, 0.65))
	parent.add_child(label)
	return label


func _find_c1_checkpoint() -> DebtCheckpoint:
	for checkpoint in DebtSystem.checkpoints:
		if checkpoint.id == C1_CHECKPOINT_ID:
			return checkpoint
	return null
