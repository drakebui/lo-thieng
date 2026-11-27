class_name WorkshopDebtController
extends Node

signal debt_agent_c1_spawn_requested(pos: Vector2)
signal debt_agent_spawn_requested(
	zone_id: String,
	node_name: String,
	display_name: String,
	pos: Vector2
)
signal debt_agent_cleared(zone_id: String)

const PATH_DEBT_NOTICE := "res://scenes/ui/DebtNoticeUI.tscn"
const PATH_DEBT_PAYMENT := "res://scenes/ui/DebtPaymentUI.tscn"

const DEBT_C1_ID := "c1_mat_bang"
const DEBT_C2_ID := "c2_dan_duong"
const DEBT_C3_ID := "c3_thue_lon"
const DEBT_C4_ID := "c4_no_goc"

const ZONE_DEBT_AGENT := "debt_agent"
const ZONE_DEBT_AGENT_C2 := "debt_agent_c2"
const ZONE_DEBT_AGENT_C3 := "debt_agent_c3"
const ZONE_DEBT_AGENT_C4 := "debt_agent_c4"

var _hub: Node = null
var _tile: int = 64
var _cols: int = 0
var _shop_center: Vector2 = Vector2.ZERO
var _last_debt_check_day: int = 0
var _active_debt_agents: Dictionary = {}
var _debt_notice: DebtNoticeUI = null
var _debt_payment: DebtPaymentUI = null
var is_day1_visit_running: bool = false


func setup(hub: Node) -> void:
	_hub = hub


func setup_layout(tile: int, cols: int, shop_center: Vector2) -> void:
	_tile = tile
	_cols = cols
	_shop_center = shop_center


func sync_overlays() -> void:
	sync_agent_scene()
	if GameManager.current_phase == GameManager.GamePhase.MORNING:
		if should_run_day1_debt_visit():
			DebtSystem.refresh_debt_summary()
			return
		if _last_debt_check_day != GameManager.current_day:
			_last_debt_check_day = GameManager.current_day
			_ensure_debt_notice()
			DebtSystem.check_day(GameManager.current_day)
	sync_payment()


func sync_payment() -> void:
	if GameManager.current_phase != GameManager.GamePhase.NIGHT:
		return
	var debt_id := _get_payable_debt_id()
	if debt_id == "":
		return
	_open_debt_payment(debt_id)


func sync_agent_scene() -> void:
	_ensure_debt_agent_marker()


func should_run_day1_debt_visit() -> bool:
	var checkpoint := DebtSystem.get_checkpoint(DEBT_C1_ID)
	if checkpoint == null or checkpoint.is_paid:
		return false
	if GameManager.has_tutorial_seen("debt_notice_shown"):
		return false
	return GameManager.current_day == checkpoint.trigger_day


func should_show_c1_debt_agent() -> bool:
	# C1 Ngày 1 nay dùng cutscene đi vào từ cửa trái rồi rời đi — không đặt tượng tĩnh chặn cửa tiệm
	return false


func run_day1_debt_visit(door_left_pos: Vector2, player_node: Node2D) -> void:
	if is_day1_visit_running or not should_run_day1_debt_visit():
		return
	var c1 := DebtSystem.get_checkpoint(DEBT_C1_ID)
	if c1 == null:
		return

	is_day1_visit_running = true
	var agent := DebtAgentNode.new()
	agent.name = "NguoiThuNoC1"
	agent.display_name = "Người Thu Nợ"
	agent.interactable_enabled = false
	agent.light_origin = Vector2(door_left_pos.x - 70.0, door_left_pos.y - 70.0)
	agent.position = door_left_pos
	_add_to_hub(agent)
	agent.face_horizontal(1.0)
	AudioManager.play_sfx_key("door_wood", 0.72)

	# 1. Người Thu Nợ bước từ cửa bên trái đi tới trước mặt Nấm
	var target_pos := Vector2(door_left_pos.x + 280.0, door_left_pos.y)
	if player_node != null:
		target_pos = Vector2(
			maxf(door_left_pos.x + 160.0, player_node.position.x - 140.0),
			player_node.position.y + 4.0
		)
	await agent.walk_to(target_pos, 230.0)
	if not is_instance_valid(self) or not is_instance_valid(agent):
		is_day1_visit_running = false
		return

	if player_node != null and "facing_dir" in player_node:
		player_node.set("facing_dir", "left")
	agent.face_horizontal(1.0)

	# 2. Hiện thoại Người Thu Nợ rồi mở Khế Ước Báo Nợ
	var tutorial_ctrl := _tutorial_ctrl()
	if tutorial_ctrl != null and not GameManager.has_tutorial_seen("ntn_day1_dialogue_seen"):
		tutorial_ctrl.show_tutorial_then(
			GuideBook.get_ntn_day1_dialogue(),
			"ntn_day1_dialogue_seen",
			func() -> void: _show_c1_notice_and_leave(c1, agent, door_left_pos)
		)
	else:
		_show_c1_notice_and_leave(c1, agent, door_left_pos)


func _show_c1_notice_and_leave(
	c1: DebtCheckpoint,
	agent: DebtAgentNode,
	door_left_pos: Vector2
) -> void:
	_ensure_debt_notice()
	_debt_notice.show_checkpoint(c1)
	_debt_notice.notice_closed.connect(
		func() -> void: _finish_day1_debt_visit(c1, agent, door_left_pos),
		CONNECT_ONE_SHOT
	)


func _finish_day1_debt_visit(
	c1: DebtCheckpoint,
	agent: DebtAgentNode,
	door_left_pos: Vector2
) -> void:
	# 3. Ghi sổ nợ lên HUD đúng lúc nhận tin xong
	GameManager.mark_tutorial("debt_notice_shown")
	DebtSystem.mark_checkpoint_notified(c1.id)

	# 4. Người Thu Nợ quay lưng bước ra lại cửa bên trái rồi biến mất
	if is_instance_valid(agent):
		await agent.walk_to(door_left_pos, 260.0)
		AudioManager.play_sfx_key("door_wood", 0.68)
		if is_instance_valid(agent):
			agent.queue_free()

	is_day1_visit_running = false
	var tutorial_ctrl := _tutorial_ctrl()
	if tutorial_ctrl != null:
		tutorial_ctrl.on_day1_debt_notice_closed()
		tutorial_ctrl.request_hint("Đã nhận khế ước nợ 3,000G (hạn tối Ngày 4) — bạn có thể tự do rèn, khám phá hoặc mở tiệm!")


func show_c1_debt_notice() -> void:
	talk_to_debt_agent()


func talk_to_debt_agent() -> void:
	if not should_show_c1_debt_agent():
		return
	var c1 := DebtSystem.get_checkpoint(DEBT_C1_ID)
	if c1 == null:
		return
	if GameManager.has_tutorial_seen("ntn_day1_dialogue_seen"):
		open_debt_notice(c1)
		return
	var tutorial_ctrl := _tutorial_ctrl()
	if tutorial_ctrl == null:
		open_debt_notice(c1)
		return
	tutorial_ctrl.show_tutorial_then(
		GuideBook.get_ntn_day1_dialogue(),
		"ntn_day1_dialogue_seen",
		func() -> void: open_debt_notice(c1)
	)


func talk_to_c2_agent() -> void:
	if _is_demo_runtime():
		return
	var c2 := DebtSystem.get_checkpoint(DEBT_C2_ID)
	if c2 == null or c2.is_paid or GameManager.current_day < c2.trigger_day:
		return
	if GameManager.has_tutorial_seen("tay_sai_rung_dialogue_seen"):
		open_debt_notice(c2)
		return
	var tutorial_ctrl := _tutorial_ctrl()
	if tutorial_ctrl == null:
		open_debt_notice(c2)
		return
	tutorial_ctrl.show_tutorial_then(
		GuideBook.get_tay_sai_rung_dialogue(),
		"tay_sai_rung_dialogue_seen",
		func() -> void: open_debt_notice(c2)
	)


func talk_to_c3_agent() -> void:
	if _is_demo_runtime():
		return
	var c3 := DebtSystem.get_checkpoint(DEBT_C3_ID)
	if c3 == null or c3.is_paid or GameManager.current_day < c3.trigger_day:
		return
	if GameManager.has_tutorial_seen("thuong_nhan_dialogue_seen"):
		open_debt_notice(c3)
		return
	var tutorial_ctrl := _tutorial_ctrl()
	if tutorial_ctrl == null:
		open_debt_notice(c3)
		return
	tutorial_ctrl.show_tutorial_then(
		GuideBook.get_thuong_nhan_dialogue(),
		"thuong_nhan_dialogue_seen",
		func() -> void: open_debt_notice(c3)
	)


func talk_to_c4_agent() -> void:
	if _is_demo_runtime():
		return
	var c4 := DebtSystem.get_checkpoint(DEBT_C4_ID)
	if c4 == null or c4.is_paid or GameManager.current_day < c4.trigger_day:
		return
	if GameManager.has_tutorial_seen("ba_trum_c4_dialogue_seen"):
		open_debt_notice(c4)
		return
	var tutorial_ctrl := _tutorial_ctrl()
	if tutorial_ctrl == null:
		open_debt_notice(c4)
		return
	tutorial_ctrl.show_tutorial_then(
		GuideBook.get_ba_trum_c4_dialogue(),
		"ba_trum_c4_dialogue_seen",
		func() -> void: open_debt_notice(c4)
	)


func open_debt_notice(checkpoint: DebtCheckpoint) -> void:
	checkpoint.has_notified = true
	_ensure_debt_notice()
	_debt_notice.show_checkpoint(checkpoint)
	var tutorial_ctrl := _tutorial_ctrl()
	if tutorial_ctrl != null and tutorial_ctrl.should_handle_day1_debt_notice():
		var callback := Callable(tutorial_ctrl, "on_day1_debt_notice_closed")
		if not _debt_notice.notice_closed.is_connected(callback):
			_debt_notice.notice_closed.connect(callback, CONNECT_ONE_SHOT)


func has_visible_overlay() -> bool:
	if is_day1_visit_running:
		return true
	if _debt_notice != null and _debt_notice.visible:
		return true
	if _debt_payment != null and _debt_payment.visible:
		return true
	return false


func reset_day_check() -> void:
	_last_debt_check_day = 0


func _ensure_debt_notice() -> void:
	if _debt_notice != null:
		return
	var scene := load(PATH_DEBT_NOTICE) as PackedScene
	_debt_notice = scene.instantiate() as DebtNoticeUI
	_add_to_hub(_debt_notice)


func _open_debt_payment(checkpoint_id: String = DEBT_C1_ID) -> void:
	if _debt_payment == null:
		var scene := load(PATH_DEBT_PAYMENT) as PackedScene
		_debt_payment = scene.instantiate() as DebtPaymentUI
		_add_to_hub(_debt_payment)
	_debt_payment.show_payment(checkpoint_id)


func _on_ntn_notice_closed() -> void:
	var tutorial_ctrl := _tutorial_ctrl()
	if tutorial_ctrl != null:
		tutorial_ctrl.show_day1_post_ntn_if_needed()


func _ensure_debt_agent_marker() -> void:
	var show_c1 := should_show_c1_debt_agent()
	if show_c1:
		_request_debt_agent(
			ZONE_DEBT_AGENT,
			"NguoiThuNoC1",
			"Người Thu Nợ",
			_shop_center + Vector2(-_tile * 1.5, 0)
		)
	else:
		_clear_debt_agent(ZONE_DEBT_AGENT)

	if _is_demo_runtime():
		_clear_debt_agent(ZONE_DEBT_AGENT_C2)
		_clear_debt_agent(ZONE_DEBT_AGENT_C3)
		_clear_debt_agent(ZONE_DEBT_AGENT_C4)
		return

	_sync_late_debt_agent(
		DEBT_C2_ID, ZONE_DEBT_AGENT_C2, "TaySaiRungC2", "Tay Sai Rừng", 8.0
	)
	_sync_late_debt_agent(
		DEBT_C3_ID, ZONE_DEBT_AGENT_C3, "ThuongNhanC3", "Thương Nhân Sa Mạc", 12.0
	)
	_sync_late_debt_agent(
		DEBT_C4_ID, ZONE_DEBT_AGENT_C4, "BaTrumHacNguyetC4", "Bà Trùm Hắc Nguyệt", 12.5
	)


func _sync_late_debt_agent(
		checkpoint_id: String,
		zone_id: String,
		node_name: String,
		display_name: String,
		row: float
) -> void:
	var checkpoint := DebtSystem.get_checkpoint(checkpoint_id)
	if checkpoint == null:
		return
	if checkpoint.is_paid:
		_clear_debt_agent(zone_id)
	elif GameManager.current_day >= checkpoint.trigger_day:
		_request_debt_agent(
			zone_id,
			node_name,
			display_name,
			Vector2(_cols * _tile / 2.0, row * _tile)
		)


func _request_debt_agent(
		zone_id: String,
		node_name: String,
		display_name: String,
		pos: Vector2
) -> void:
	if _active_debt_agents.has(zone_id):
		return
	_active_debt_agents[zone_id] = true
	if zone_id == ZONE_DEBT_AGENT:
		debt_agent_c1_spawn_requested.emit(pos)
	debt_agent_spawn_requested.emit(zone_id, node_name, display_name, pos)


func _clear_debt_agent(zone_id: String) -> void:
	if not _active_debt_agents.has(zone_id):
		return
	_active_debt_agents.erase(zone_id)
	debt_agent_cleared.emit(zone_id)


func _get_payable_debt_id() -> String:
	var day := GameManager.current_day
	for checkpoint in DebtSystem.checkpoints:
		if checkpoint.is_paid:
			continue
		if checkpoint.trigger_day > day:
			continue
		if _is_demo_runtime() and checkpoint.id != DEBT_C1_ID:
			continue
		return checkpoint.id
	return ""


func _is_demo_runtime() -> bool:
	return GameManager.current_day <= GameManager.DEMO_LAST_DAY


func _tutorial_ctrl() -> WorkshopTutorialController:
	if _hub == null:
		return null
	return _hub.get("_tutorial_ctrl") as WorkshopTutorialController


func _add_to_hub(node: Node) -> void:
	if _hub != null:
		_hub.add_child(node)
	else:
		add_child(node)
