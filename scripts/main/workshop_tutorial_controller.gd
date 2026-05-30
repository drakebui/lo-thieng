class_name WorkshopTutorialController
extends Node

signal advance_phase_requested
signal debt_agent_sync_requested
signal debt_notice_requested(checkpoint: DebtCheckpoint)
signal zone_locked(zone_id: String)
signal zone_unlocked(zone_id: String)
signal hint_changed(text: String)

const TUTORIAL_OVERLAY_SCRIPT := "res://scripts/ui/tutorial_overlay_ui.gd"

const ZONE_FORGE := "forge"
const ZONE_BED := "bed"
const ZONE_EXIT := "exit"
const ZONE_SHOP := "shop"
const ZONE_FORGE_BOOK := "forge_book"

var hub: Node = null
var layout: Dictionary = {}
var tutorial_step: int = 0

var _tutorial_overlay: TutorialOverlayUI = null
var _tutorial_locked_zones: Dictionary = {}
var _tutorial_noon_timer: SceneTreeTimer = null
var _tutorial_noon_remaining: int = 60
var _tutorial_advance_btn: Button = null
var _arrow_node: Node2D = null
var _arrow_tween: Tween = null
var _sticky_hint_zone: String = ""
var _sticky_hint_text: String = ""


func _ready() -> void:
	if not EventBus.weapon_forged.is_connected(_on_tutorial_weapon_forged):
		EventBus.weapon_forged.connect(_on_tutorial_weapon_forged)


func sync_script() -> void:
	if GameManager.current_day == 0:
		_sync_day0_tutorial()
	elif GameManager.current_day == 2:
		_sync_day2_tutorial()
	elif GameManager.current_day == 3:
		_sync_day3_tutorial()
	elif GameManager.current_day == 4:
		_sync_day4_tutorial()


func sync_day1_scripted() -> void:
	if not is_day1_active():
		_set_tutorial_step(4)
		return
	if GameManager.current_phase == GameManager.GamePhase.AFTERNOON:
		_set_tutorial_step(3)
	elif GameManager.has_tutorial_seen("debt_notice_shown"):
		_set_tutorial_step(2)
	elif GameManager.has_tutorial_seen("day1_forge_done"):
		_set_tutorial_step(1)
	else:
		_set_tutorial_step(0)


func handle_day_changed(day: int) -> void:
	if day != 0:
		_clear_sticky_hint()


func is_day1_active() -> bool:
	return (
		GameManager.current_day == 1
		and GameManager.has_tutorial_seen("opening_seen")
	)


func _is_overlay_visible() -> bool:
	return _tutorial_overlay != null and _tutorial_overlay.visible


func _is_zone_locked(zone_id: String) -> bool:
	return _tutorial_locked_zones.has(zone_id)


func can_activate_zone(zone_id: String) -> bool:
	if _is_overlay_visible():
		return false
	if _is_zone_locked(zone_id):
		request_hint("Chưa tới lúc.")
		return false
	if not _tutorial_allows_zone(zone_id):
		return false
	if zone_id == _sticky_hint_zone:
		_clear_sticky_hint()
	return true


func on_zone_entered(zone_id: String, hint_text: String) -> void:
	if _sticky_hint_zone != "" and zone_id != _sticky_hint_zone:
		return
	request_hint("[E]   " + hint_text)


func on_zone_exited() -> void:
	if _sticky_hint_zone != "":
		_restore_sticky_hint()
		return
	clear_hint()


func request_hint(text: String) -> void:
	hint_changed.emit(text)
	EventBus.hint_requested.emit(text)


func clear_hint() -> void:
	request_hint("")


func should_show_before_forge() -> bool:
	return GameManager.current_day == 0 \
		and not GameManager.has_tutorial_seen("day0_forge_phase_seen")


func should_show_before_shop() -> bool:
	return GameManager.current_day == 0 \
		and not GameManager.has_tutorial_seen("day0_shop_phase_seen")


func should_show_before_explore() -> bool:
	return GameManager.current_day >= 1 \
		and not GameManager.has_tutorial_seen("explore_phase_seen")


func show_tutorial_then(steps: Array[Dictionary], flag: String, callback: Callable) -> void:
	_show_tutorial(steps, flag)
	_tutorial_overlay.completed.connect(callback, CONNECT_ONE_SHOT)


func open_guide_book() -> void:
	_ensure_tutorial_overlay()
	_tutorial_overlay.show_sections(GuideBook.get_sections())


func should_handle_day1_debt_notice() -> bool:
	return is_day1_active() and not GameManager.has_tutorial_seen("debt_notice_shown")


func on_day1_debt_notice_closed() -> void:
	GameManager.mark_tutorial("debt_notice_shown")
	# Tiến thẳng đến chiều để player vào shop được ngay
	if GameManager.current_phase == GameManager.GamePhase.MORNING:
		advance_phase_requested.emit()
	if GameManager.current_phase == GameManager.GamePhase.NOON:
		advance_phase_requested.emit()
	_set_tutorial_step(3)


func show_day1_post_ntn_if_needed() -> void:
	if not GameManager.has_tutorial_seen("day1_loop_seen"):
		_show_tutorial(GuideBook.get_day1_post_ntn_steps(), "day1_loop_seen")


func _set_tutorial_step(step: int) -> void:
	if not is_day1_active() and step < 4:
		step = 4
	if tutorial_step == step and step != 1:
		return
	tutorial_step = step
	EventBus.tutorial_step_changed.emit(tutorial_step)
	_hide_tutorial_advance_button()

	match tutorial_step:
		0:
			_set_tutorial_locks([ZONE_BED, ZONE_EXIT, ZONE_SHOP, ZONE_FORGE_BOOK])
			request_hint("Đến lò rèn và rèn vũ khí đầu tiên của ngươi.")
			_show_tutorial_arrow(_zone_center(ZONE_FORGE), "Lò Rèn")
		1:
			_set_tutorial_locks([ZONE_BED, ZONE_EXIT, ZONE_SHOP, ZONE_FORGE_BOOK])
			request_hint("Người Thu Nợ đang chờ ở cửa tiệm.")
			_show_tutorial_arrow(
				_zone_center(ZONE_SHOP) + Vector2(-float(_tile()) * 1.5, 0.0),
				"Người Thu Nợ"
			)
			debt_agent_sync_requested.emit()
			_show_day1_debt_notice()
		2:
			_set_tutorial_locks([ZONE_EXIT, ZONE_SHOP])
			request_hint("Buổi trưa: Rèn thêm hoặc chờ đến chiều.")
			_hide_tutorial_arrow()
			_show_tutorial_advance_button()
			_start_tutorial_noon_timer()
		3:
			_set_tutorial_locks([ZONE_EXIT, ZONE_BED])
			request_hint("Đặt vũ khí lên kệ trước khi mở cửa!")
			_show_tutorial_arrow(_zone_center(ZONE_SHOP), "Mở Tiệm")
		_:
			_set_tutorial_locks([])
			clear_hint()
			_hide_tutorial_arrow()


func _set_tutorial_locks(zone_ids: Array) -> void:
	var previous := _tutorial_locked_zones.duplicate()
	_tutorial_locked_zones.clear()
	for zone_id: String in zone_ids:
		_tutorial_locked_zones[zone_id] = true
		if not previous.has(zone_id):
			zone_locked.emit(zone_id)
	for zone_id: String in previous.keys():
		if not _tutorial_locked_zones.has(zone_id):
			zone_unlocked.emit(zone_id)
	_apply_interactable_locks()


func _apply_interactable_locks() -> void:
	for node in get_tree().get_nodes_in_group("interactable"):
		if not node.has_method("set_locked"):
			continue
		var zone_id := String(node.get_meta("zone_id", ""))
		node.set_locked(_tutorial_locked_zones.has(zone_id))


func _on_tutorial_weapon_forged(_weapon_data) -> void:
	if is_day1_active() and tutorial_step == 0:
		_set_tutorial_step(1)


func _show_day1_debt_notice() -> void:
	if GameManager.has_tutorial_seen("debt_notice_shown"):
		return
	var c1 := DebtSystem.get_checkpoint("c1_mat_bang")
	if c1 == null:
		return
	debt_notice_requested.emit(c1)


func _show_tutorial_advance_button() -> void:
	if _tutorial_advance_btn == null:
		_tutorial_advance_btn = Button.new()
		_tutorial_advance_btn.position = Vector2(get_viewport().get_visible_rect().size.x - 220, 92)
		_tutorial_advance_btn.size = Vector2(220, 48)
		_tutorial_advance_btn.add_theme_font_size_override("font_size", 20)
		_tutorial_advance_btn.pressed.connect(_advance_day1_to_afternoon)
		add_child(_tutorial_advance_btn)
	_update_noon_btn_text()
	_tutorial_advance_btn.visible = true


func _update_noon_btn_text() -> void:
	if _tutorial_advance_btn == null:
		return
	_tutorial_advance_btn.text = "Sang chiều (%ds)" % _tutorial_noon_remaining


func _hide_tutorial_advance_button() -> void:
	if _tutorial_advance_btn != null:
		_tutorial_advance_btn.visible = false


func _zone_center(zone_id: String) -> Vector2:
	match zone_id:
		ZONE_FORGE:
			return layout.get("forge_center", Vector2.ZERO)
		ZONE_BED:
			return layout.get("bed_center", Vector2.ZERO)
		ZONE_EXIT:
			return layout.get("exit_center", Vector2.ZERO)
		ZONE_SHOP:
			return layout.get("shop_center", Vector2.ZERO)
		ZONE_FORGE_BOOK:
			return layout.get("forge_book_center", Vector2.ZERO)
	return Vector2.ZERO


func _tile() -> int:
	return int(layout.get("TILE", 64))


func _show_tutorial_arrow(world_pos: Vector2, hint_text: String) -> void:
	if _arrow_node == null:
		_arrow_node = Node2D.new()
		_arrow_node.z_index = 50
		var lbl := Label.new()
		lbl.name = "ArrowLabel"
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.15))
		lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		lbl.add_theme_constant_override("shadow_offset_x", 2)
		lbl.add_theme_constant_override("shadow_offset_y", 2)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(240, 0)
		lbl.position = Vector2(-120.0, 0.0)
		_arrow_node.add_child(lbl)
		add_child(_arrow_node)

	(_arrow_node.get_node("ArrowLabel") as Label).text = "▼  " + hint_text
	_arrow_node.position = world_pos + Vector2(0.0, -float(_tile()) - 20.0)
	_arrow_node.visible = true

	if _arrow_tween != null:
		_arrow_tween.kill()
	_arrow_tween = create_tween()
	_arrow_tween.set_loops()
	_arrow_tween.tween_property(
		_arrow_node, "position:y",
		world_pos.y - float(_tile()) - 6.0, 0.45
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_arrow_tween.tween_property(
		_arrow_node, "position:y",
		world_pos.y - float(_tile()) - 26.0, 0.45
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _hide_tutorial_arrow() -> void:
	if _arrow_tween != null:
		_arrow_tween.kill()
		_arrow_tween = null
	if _arrow_node != null:
		_arrow_node.visible = false


func _start_tutorial_noon_timer() -> void:
	if _tutorial_noon_timer != null:
		return
	_tutorial_noon_remaining = 60
	_tick_tutorial_noon_timer()


func _tick_tutorial_noon_timer() -> void:
	_tutorial_noon_timer = get_tree().create_timer(1.0)
	await _tutorial_noon_timer.timeout
	_tutorial_noon_timer = null
	if not (is_day1_active() and tutorial_step == 2):
		return
	_tutorial_noon_remaining -= 1
	_update_noon_btn_text()
	if _tutorial_noon_remaining <= 0:
		_advance_day1_to_afternoon()
	else:
		_tick_tutorial_noon_timer()


func _advance_day1_to_afternoon() -> void:
	if GameManager.current_phase != GameManager.GamePhase.NOON:
		return
	_tutorial_noon_remaining = 0
	_tutorial_noon_timer = null
	advance_phase_requested.emit()


func _sync_day0_tutorial() -> void:
	if GameManager.current_phase == GameManager.GamePhase.MORNING \
			and not GameManager.has_tutorial_seen("ba_trum_intro_seen"):
		_show_tutorial(GuideBook.get_ba_trum_intro_steps(), "ba_trum_intro_seen")
		_tutorial_overlay.completed.connect(_sync_day0_tutorial, CONNECT_ONE_SHOT)
		return
	if GameManager.current_phase == GameManager.GamePhase.MORNING \
			and GameManager.has_tutorial_seen("ba_trum_intro_seen") \
			and not GameManager.has_tutorial_seen("day0_intro_seen"):
		_show_tutorial(GuideBook.get_day0_intro_steps(), "day0_intro_seen")
	elif _is_day0_forge_required():
		_set_sticky_hint(ZONE_FORGE, "→ Quay lại Lò Rèn để hoàn thành vũ khí")
	elif GameManager.current_phase == GameManager.GamePhase.NOON \
			and GameManager.has_tutorial_seen("day0_forge_done") \
			and not GameManager.has_tutorial_seen("first_forge_complete_seen"):
		_show_tutorial(GuideBook.get_first_forge_complete_steps(), "first_forge_complete_seen")
		_tutorial_overlay.completed.connect(_sync_day0_tutorial, CONNECT_ONE_SHOT)
	elif GameManager.current_phase == GameManager.GamePhase.NOON \
			and GameManager.has_tutorial_seen("day0_forge_done") \
			and not GameManager.has_tutorial_seen("day0_shop_hint_seen"):
		_show_tutorial(GuideBook.get_day0_shop_hint_steps(), "day0_shop_hint_seen")


func _sync_day2_tutorial() -> void:
	if GameManager.current_phase != GameManager.GamePhase.MORNING:
		return
	if GameManager.has_tutorial_seen("day2_freeplay_seen"):
		return
	_show_tutorial(GuideBook.get_day2_intro_steps(), "day2_freeplay_seen")


func _sync_day3_tutorial() -> void:
	if GameManager.current_phase != GameManager.GamePhase.MORNING:
		return
	if GameManager.has_tutorial_seen("day3_co_long_gio_seen"):
		return
	var has_met := GameManager.has_tutorial_seen("co_long_gio_met")
	_show_tutorial(GuideBook.get_day3_intro_steps(has_met), "day3_co_long_gio_seen")


func _sync_day4_tutorial() -> void:
	if GameManager.current_phase != GameManager.GamePhase.MORNING:
		return
	if GameManager.has_tutorial_seen("day4_deadline_seen"):
		return
	_show_tutorial(GuideBook.get_day4_intro_steps(), "day4_deadline_seen")


func _show_tutorial(steps: Array[Dictionary], flag: String) -> void:
	_ensure_tutorial_overlay()
	_tutorial_overlay.show_steps(steps)
	if flag == "day0_intro_seen":
		_tutorial_overlay.completed.connect(
			func() -> void: _set_sticky_hint(ZONE_FORGE, "→ Lò Rèn đang chờ bạn"),
			CONNECT_ONE_SHOT
		)
	elif flag == "day0_shop_hint_seen":
		_tutorial_overlay.completed.connect(
			func() -> void: _set_sticky_hint(ZONE_SHOP, "→ Mang vũ khí vào Tiệm để bán"),
			CONNECT_ONE_SHOT
		)
	GameManager.mark_tutorial_seen(flag)


func _ensure_tutorial_overlay() -> void:
	if _tutorial_overlay != null:
		return
	var script: GDScript = load(TUTORIAL_OVERLAY_SCRIPT)
	_tutorial_overlay = script.new() as TutorialOverlayUI
	add_child(_tutorial_overlay)


func _set_sticky_hint(zone_id: String, text: String) -> void:
	_sticky_hint_zone = zone_id
	_sticky_hint_text = text
	request_hint(text)
	var pos := _zone_center(zone_id)
	if pos != Vector2.ZERO:
		_show_tutorial_arrow(pos, text.trim_prefix("→ ").strip_edges())


func _clear_sticky_hint() -> void:
	_sticky_hint_zone = ""
	_sticky_hint_text = ""
	clear_hint()
	_hide_tutorial_arrow()


func _restore_sticky_hint() -> void:
	request_hint(_sticky_hint_text)


func _is_day0_forge_required() -> bool:
	return GameManager.current_day == 0 \
		and GameManager.current_phase == GameManager.GamePhase.NOON \
		and not GameManager.has_tutorial_seen("day0_forge_done")


func _tutorial_allows_zone(zone_id: String) -> bool:
	if GameManager.current_day != 0:
		return true
	var allowed := true
	if GameManager.current_phase == GameManager.GamePhase.MORNING:
		allowed = zone_id in [ZONE_FORGE, ZONE_FORGE_BOOK]
		if not allowed:
			request_hint("Tutorial ngày 0: hãy vào Lò Rèn trước.")
	elif GameManager.current_phase == GameManager.GamePhase.NOON:
		if not GameManager.has_tutorial_seen("day0_forge_done"):
			allowed = zone_id in [ZONE_FORGE, ZONE_FORGE_BOOK]
			if not allowed:
				request_hint("Tutorial: quay lại Lò Rèn và lưu vũ khí vào túi trước.")
		elif not GameManager.has_tutorial_seen("day0_customer_done"):
			allowed = zone_id in [ZONE_SHOP, ZONE_FORGE, ZONE_FORGE_BOOK]
			if not allowed:
				request_hint("Tutorial: hãy mở tiệm và bán vũ khí trước khi làm việc khác.")
	return allowed
