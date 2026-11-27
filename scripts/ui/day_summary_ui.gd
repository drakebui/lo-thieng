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
	layer = 16
	visible = false
	_build_ui()
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


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	root.add_child(HoaTamUI.make_dim_backdrop())

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := HoaTamUI.make_panel_container(true, 40.0)
	panel.custom_minimum_size = Vector2(600, 470)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)
	header.add_child(HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(HoaTamUI.HudIcon.NIGHT), 34))

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 32)
	_title.add_theme_color_override("font_color", HoaTamUI.COL_INK)
	header.add_child(_title)

	var gold_row := HBoxContainer.new()
	gold_row.alignment = BoxContainer.ALIGNMENT_CENTER
	gold_row.add_theme_constant_override("separation", 10)
	vbox.add_child(gold_row)
	gold_row.add_child(HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(HoaTamUI.HudIcon.GOLD), 28))
	_gold_lbl = _make_label(HoaTamUI.COL_INK)
	gold_row.add_child(_gold_lbl)

	var sold_row := HBoxContainer.new()
	sold_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sold_row.add_theme_constant_override("separation", 10)
	vbox.add_child(sold_row)
	sold_row.add_child(HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(HoaTamUI.HudIcon.ATK), 26))
	_sold_lbl = _make_label(HoaTamUI.COL_INK)
	sold_row.add_child(_sold_lbl)

	_debt_lbl = _make_label(HoaTamUI.COL_CRIMSON_INK)
	vbox.add_child(_debt_lbl)

	_debt_label = _make_label(HoaTamUI.COL_INK_MUTE)
	_debt_label.name = "DebtTrackerLabel"
	_debt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_debt_label)

	_hint_label = _make_label(HoaTamUI.COL_CRIMSON_INK)
	_hint_label.name = "HintLabel"
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.add_theme_font_size_override("font_size", 19)
	vbox.add_child(_hint_label)

	var btn_wrap := HBoxContainer.new()
	btn_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_wrap)

	var next_btn := Button.new()
	next_btn.text = "Sang Ngày Mới"
	next_btn.custom_minimum_size = Vector2(280, 58)
	HoaTamUI.apply_primary_button(next_btn, 22)
	next_btn.pressed.connect(_on_next_day)
	btn_wrap.add_child(next_btn)

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
	_title.text = "SỔ CUỐI NGÀY %d" % GameManager.current_day
	var earned_today := GameManager.gold - GameManager.day_start_gold
	_gold_lbl.text = "Vàng kiếm được: %d G" % earned_today
	var sold_count: int = _session_stats.get("customers_served", 0)
	_sold_lbl.text = "Vũ khí đã bán: %d" % sold_count
	var cp := _find_active_checkpoint()
	if cp != null:
		if cp.is_paid:
			_debt_lbl.add_theme_color_override("font_color", Color(0.16, 0.42, 0.24))
			_debt_lbl.text = "Đã thanh toán mốc %s" % cp.title
			_debt_label.visible = false
			_hint_label.visible = false
		else:
			_debt_lbl.add_theme_color_override("font_color", HoaTamUI.COL_CRIMSON_INK)
			var owed := cp.amount_gold
			if cp.is_late:
				owed += cp.penalty_gold
			var days_left: int = maxi(0, cp.deadline_day - GameManager.current_day)
			_debt_lbl.text = "Nợ (%s): %d G · Còn %d ngày" % [cp.title, owed, days_left]
			var still_need: int = maxi(0, owed - GameManager.gold)
			_debt_label.text = (
				"%s: %d G | Hiện có: %d G\n" % [cp.title, owed, GameManager.gold]
				+ ("Đã đủ tiền trả nợ." if still_need == 0 else "Còn thiếu: %d G" % still_need)
			)
			_debt_label.visible = true
			_hint_label.visible = still_need > 2000
			if _hint_label.visible:
				_hint_label.text = "Ngày mai hãy ra ngoài kiếm nguyên liệu và rèn thêm."
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
			DebtSystem.refresh_debt_summary()
		_open_resolution_modal("Quá hạn C1", _day4_penalty_text(c1))


func _day4_penalty_text(c1: DebtCheckpoint) -> String:
	var owed := c1.amount_gold + c1.penalty_gold
	return "Người Thu Nợ ghi thêm tiền phạt.\n" \
		+ "Phạt: +%d G · Tổng nợ: %d G\n" % [c1.penalty_gold, owed] \
		+ "Mở bảng trả nợ vào ban đêm để xử lý trước khi rời lò."


func _open_resolution_modal(title: String, body: String) -> void:
	if _resolution_modal != null:
		return

	var modal := Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	_resolution_modal = modal

	modal.add_child(HoaTamUI.make_dim_backdrop())

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)

	var panel := HoaTamUI.make_panel_container(false, 36.0)
	panel.custom_minimum_size = Vector2(640, 320)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", HoaTamUI.COL_GOLD)
	vbox.add_child(title_lbl)

	var body_lbl := Label.new()
	body_lbl.text = body
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.add_theme_font_size_override("font_size", 22)
	body_lbl.add_theme_color_override("font_color", HoaTamUI.COL_PARCHMENT)
	vbox.add_child(body_lbl)

	var btn_wrap := HBoxContainer.new()
	btn_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_wrap)

	var ok_btn := Button.new()
	ok_btn.text = "Tiếp Tục"
	ok_btn.custom_minimum_size = Vector2(210, 56)
	HoaTamUI.apply_primary_button(ok_btn, 22)
	ok_btn.pressed.connect(_on_resolution_continue)
	btn_wrap.add_child(ok_btn)


func _on_resolution_continue() -> void:
	if _resolution_modal != null:
		_resolution_modal.queue_free()
		_resolution_modal = null
	_resolution_seen = true
	_continue_next_day()


func _make_label(color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	return label


func _find_active_checkpoint() -> DebtCheckpoint:
	for checkpoint in DebtSystem.checkpoints:
		if checkpoint.trigger_day <= GameManager.current_day \
				and checkpoint.has_notified \
				and not checkpoint.is_paid:
			return checkpoint
	return _find_c1_checkpoint()


func _find_c1_checkpoint() -> DebtCheckpoint:
	for checkpoint in DebtSystem.checkpoints:
		if checkpoint.id == C1_CHECKPOINT_ID:
			return checkpoint
	return null
