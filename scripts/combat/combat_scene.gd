# Combat Scene — UI-only, mọi logic được delegate sang CombatManager
# Luồng: _setup_mock_combat() → manager.start_combat() → lắng nghe signals
extends Control

const HP_BAR_W := 500.0
const HP_BAR_H := 48.0
const _ENEMY_CYCLE: Array[String] = ["soi", "nguoi_da", "ma_rung"]

# ══════════════════════════════════════════════════════════════════════════════
# NODES
# ══════════════════════════════════════════════════════════════════════════════

var _manager: CombatManager

# Player panel
var _p_name_lbl:   Label
var _p_hp_fill:    ColorRect
var _p_hp_lbl:     Label
var _p_sta_pips:   Array[ColorRect] = []
var _p_status_lbl: Label
var _p_stat_lbl:   Label
var _p_sprite:     ColorRect
var _p_color:      Color = Color(0.28, 0.42, 0.62)  # màu gốc sprite player

# Enemy panel
var _e_name_lbl:   Label
var _e_hp_fill:    ColorRect
var _e_hp_lbl:     Label
var _e_status_lbl: Label
var _e_intent_lbl: Label
var _e_stat_lbl:   Label
var _e_sprite:     ColorRect
var _e_color:      Color = Color(0.55, 0.25, 0.12)  # màu gốc sprite enemy

# HP bar tweens — để không bị conflict khi có nhiều update liên tiếp
var _p_hp_tween: Tween = null
var _e_hp_tween: Tween = null

# Action buttons [BasicAtk, Skill1, Skill2, Run]
var _action_btns: Array[Button] = []

# Log + Result
var _log_lines:      Array[String] = []
var _log_label:      Label
var _result_overlay: Control
var _result_title:   Label
var _result_body:    Label
var _retry_btn:      Button
var _return_btn:     Button   # nút quay lại exploration (hiển thị khi từ vùng đất)

var _enemy_cycle_idx: int = 0
var _active_enemy_key: String = ""


# ══════════════════════════════════════════════════════════════════════════════
# READY
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.07, 0.06)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── Anchor-based layout (thay VBoxContainer) ──────────────────────────────
	# VBoxContainer phân bổ theo minimum-size → khi battle_area min (651px) +
	# log (290) + action (200) = 1141px > 1080px màn hình, toàn bộ layout tràn.
	# Anchor layout chia tỉ lệ cố định, nội dung clip nếu quá nhỏ — không tràn.
	#
	#  0%  ┌────────────────┐
	#      │  battle area   │  60% màn hình
	# 60%  ├────────────────┤
	#      │    log area    │  22%
	# 82%  ├────────────────┤
	#      │  action menu   │  18%
	#100%  └────────────────┘
	_add_anchored(_build_battle_area(), 0.0, 0.0, 1.0, 0.60)
	_add_anchored(_build_log_area(),    0.0, 0.60, 1.0, 0.82)
	_add_anchored(_build_action_menu(), 0.0, 0.82, 1.0, 1.0)

	_result_overlay = _build_result_overlay()
	add_child(_result_overlay)
	_result_overlay.visible = false

	# Khởi tạo và thêm CombatManager vào cây
	_manager = CombatManager.new()
	add_child(_manager)
	_manager.state_changed.connect(_on_state_changed)
	_manager.round_started.connect(_on_round_started)
	_manager.enemy_telegraphed.connect(_on_enemy_telegraphed)
	_manager.action_logged.connect(_append_log)
	_manager.combatant_updated.connect(_on_combatant_updated)
	_manager.hit_landed.connect(_on_hit_landed)
	_manager.combat_ended.connect(_on_combat_ended)

	var initial_enemy := "soi"
	if not GameManager.pending_combat_enemy.is_empty():
		initial_enemy                     = GameManager.pending_combat_enemy
		GameManager.pending_combat_enemy  = ""
	_setup_mock_combat(initial_enemy)


# Helper: add child với anchor tỉ lệ (không dùng VBoxContainer).
func _add_anchored(node: Control, al: float, at: float, ar: float, ab: float) -> void:
	node.anchor_left   = al;  node.anchor_top    = at
	node.anchor_right  = ar;  node.anchor_bottom = ab
	node.offset_left   = 0;   node.offset_top    = 0
	node.offset_right  = 0;   node.offset_bottom = 0
	add_child(node)


# ══════════════════════════════════════════════════════════════════════════════
# BUILD UI
# ══════════════════════════════════════════════════════════════════════════════

func _build_battle_area() -> Control:
	var area := HBoxContainer.new()
	area.add_theme_constant_override("separation", 0)
	area.add_child(_build_player_panel())

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 16)
	var title := Label.new()
	title.text = "⚔  COMBAT"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(title)
	area.add_child(mid)

	area.add_child(_build_enemy_panel())
	return area


func _build_player_panel() -> Control:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size.x = 640
	panel.add_theme_constant_override("separation", 14)

	var sp_wrap := CenterContainer.new()
	_p_sprite = ColorRect.new()
	_p_sprite.custom_minimum_size = Vector2(110, 180)
	_p_sprite.color = Color(0.28, 0.42, 0.62)
	sp_wrap.add_child(_p_sprite)
	panel.add_child(sp_wrap)

	_p_name_lbl = Label.new()
	_p_name_lbl.text = "Thợ Rèn"
	_p_name_lbl.add_theme_font_size_override("font_size", 56)
	_p_name_lbl.add_theme_color_override("font_color", Color(0.88, 0.82, 0.68))
	_p_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_p_name_lbl)

	panel.add_child(_build_hp_bar(true))
	panel.add_child(_build_stamina_bar())

	_p_status_lbl = Label.new()
	_p_status_lbl.add_theme_font_size_override("font_size", 36)
	_p_status_lbl.add_theme_color_override("font_color", Color(0.85, 0.72, 0.42))
	_p_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p_status_lbl.text = ""
	panel.add_child(_p_status_lbl)

	_p_stat_lbl = Label.new()
	_p_stat_lbl.add_theme_font_size_override("font_size", 36)
	_p_stat_lbl.add_theme_color_override("font_color", Color(0.62, 0.78, 0.92))
	_p_stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p_stat_lbl.text = ""
	panel.add_child(_p_stat_lbl)

	return panel


func _build_enemy_panel() -> Control:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size.x = 640
	panel.add_theme_constant_override("separation", 14)

	var sp_wrap := CenterContainer.new()
	_e_sprite = ColorRect.new()
	_e_sprite.custom_minimum_size = Vector2(130, 180)
	_e_sprite.color = Color(0.55, 0.25, 0.12)
	sp_wrap.add_child(_e_sprite)
	panel.add_child(sp_wrap)

	_e_name_lbl = Label.new()
	_e_name_lbl.text = "???"
	_e_name_lbl.add_theme_font_size_override("font_size", 56)
	_e_name_lbl.add_theme_color_override("font_color", Color(0.88, 0.48, 0.32))
	_e_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_e_name_lbl)

	panel.add_child(_build_hp_bar(false))

	_e_intent_lbl = Label.new()
	_e_intent_lbl.add_theme_font_size_override("font_size", 44)
	_e_intent_lbl.add_theme_color_override("font_color", Color(0.95, 0.72, 0.28))
	_e_intent_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_e_intent_lbl.text = ""
	panel.add_child(_e_intent_lbl)

	_e_status_lbl = Label.new()
	_e_status_lbl.add_theme_font_size_override("font_size", 36)
	_e_status_lbl.add_theme_color_override("font_color", Color(0.85, 0.72, 0.42))
	_e_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_e_status_lbl.text = ""
	panel.add_child(_e_status_lbl)

	_e_stat_lbl = Label.new()
	_e_stat_lbl.add_theme_font_size_override("font_size", 36)
	_e_stat_lbl.add_theme_color_override("font_color", Color(0.92, 0.68, 0.62))
	_e_stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_e_stat_lbl.text = ""
	panel.add_child(_e_stat_lbl)

	return panel


func _build_hp_bar(is_player: bool) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)

	var bar := Control.new()
	bar.custom_minimum_size = Vector2(HP_BAR_W, HP_BAR_H)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.22, 0.18, 0.16)
	bar_bg.size  = Vector2(HP_BAR_W, HP_BAR_H)
	bar.add_child(bar_bg)

	var fill := ColorRect.new()
	fill.color = Color(0.22, 0.72, 0.32) if is_player else Color(0.82, 0.28, 0.18)
	fill.size  = Vector2(HP_BAR_W, HP_BAR_H)
	bar.add_child(fill)

	if is_player: _p_hp_fill = fill
	else:         _e_hp_fill = fill

	wrapper.add_child(bar)

	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 44)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_player: _p_hp_lbl = lbl
	else:         _e_hp_lbl = lbl
	wrapper.add_child(lbl)

	return wrapper


func _build_stamina_bar() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)

	var lbl := Label.new()
	lbl.text = "STA"
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", Color(0.72, 0.68, 0.58))
	row.add_child(lbl)

	for i in 5:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(36, 36)
		pip.color = Color(0.28, 0.58, 0.88)
		row.add_child(pip)
		_p_sta_pips.append(pip)

	return row


func _build_log_area() -> Control:
	# plain Control — anchor layout kiểm soát size từ ngoài.
	# clip_contents đảm bảo label không leak ra ngoài vùng log khi text nhiều.
	var outer := Control.new()
	outer.clip_contents = true

	var bg := ColorRect.new()
	bg.color = Color(0.11, 0.09, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_child(bg)

	_log_label = Label.new()
	_log_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_log_label.offset_left   = 16
	_log_label.offset_top    = 12
	_log_label.offset_right  = -16
	_log_label.offset_bottom = -12
	_log_label.add_theme_font_size_override("font_size", 38)
	_log_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.68))
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_log_label)

	return outer


func _build_action_menu() -> Control:
	# plain Control — anchor layout kiểm soát size từ ngoài.
	# HBoxContainer bên trong fill FULL_RECT, button text không làm outer phình ra.
	var outer := Control.new()
	outer.clip_contents = true

	var container := HBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 12)

	var labels := ["Tấn Công\nThường", "Skill 1\n—", "Skill 2\n—", "Bỏ Chạy", "Đổi Vũ Khí\n(W)"]
	for i in 5:
		var btn := Button.new()
		btn.text = labels[i]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 48)
		btn.pressed.connect(_on_action_btn_pressed.bind(i))
		container.add_child(btn)
		_action_btns.append(btn)

	outer.add_child(container)
	return outer


func _build_result_overlay() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	center.add_child(vbox)

	_result_title = Label.new()
	_result_title.add_theme_font_size_override("font_size", 120)
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_title)

	_result_body = Label.new()
	_result_body.add_theme_font_size_override("font_size", 56)
	_result_body.add_theme_color_override("font_color", Color(0.82, 0.78, 0.68))
	_result_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_body)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 32)

	_retry_btn = Button.new()
	_retry_btn.text = "[ Đánh lại  (R) ]"
	_retry_btn.add_theme_font_size_override("font_size", 52)
	_retry_btn.pressed.connect(_on_retry)
	btn_row.add_child(_retry_btn)

	_return_btn = Button.new()
	_return_btn.text = "[ Quay lại Khám Phá ]"
	_return_btn.add_theme_font_size_override("font_size", 52)
	_return_btn.visible = false
	_return_btn.pressed.connect(_on_return_to_exploration)
	btn_row.add_child(_return_btn)

	var btn_wrap := CenterContainer.new()
	btn_wrap.add_child(btn_row)
	vbox.add_child(btn_wrap)

	return overlay


# ══════════════════════════════════════════════════════════════════════════════
# COMBAT SETUP
# ══════════════════════════════════════════════════════════════════════════════

func _setup_mock_combat(enemy_key: String) -> void:
	_active_enemy_key = enemy_key
	var p: PlayerCombatUnit
	if GameManager.has_any_equipped():
		p = PlayerCombatUnit.new()
		p.setup_player("Thợ Rèn")
		for i in GameManager.equipped_weapons.size():
			var w: Dictionary = GameManager.equipped_weapons[i]
			if not w.is_empty():
				p.equip_weapon(i, w)
	else:
		p = PlayerCombatUnit.make_for_test()

	# Ưu tiên ENEMY_TEMPLATES; nếu không có thì tra EnemyDatabase (vùng đất)
	var tmpl: Dictionary
	if CombatManager.ENEMY_TEMPLATES.has(enemy_key):
		tmpl = CombatManager.ENEMY_TEMPLATES[enemy_key]
	else:
		var ed: EnemyData = EnemyDatabase.get_enemy(enemy_key)
		if ed != null:
			tmpl = ed.to_template()
		else:
			tmpl = CombatManager.ENEMY_TEMPLATES["soi"]  # fallback

	var e := EnemyCombatUnit.from_template(tmpl)
	_e_color        = e.color
	_e_sprite.color = e.color

	_p_name_lbl.text = p.combatant_name
	_e_name_lbl.text = e.combatant_name

	_log_lines.clear()
	_result_overlay.visible = false
	_append_log("> Trận chiến bắt đầu! [%s]" % e.archetype.to_upper())
	_append_log("> %s xuất hiện!" % e.combatant_name)

	_manager.start_combat(p, e)


# ══════════════════════════════════════════════════════════════════════════════
# SIGNAL HANDLERS — manager → UI
# ══════════════════════════════════════════════════════════════════════════════

func _on_state_changed(new_state: CombatManager.CombatState) -> void:
	match new_state:
		CombatManager.CombatState.PLAYER_TURN:
			_set_buttons_disabled(false)
			_update_action_buttons()
		CombatManager.CombatState.ENEMY_TURN:
			_set_buttons_disabled(true)
			_e_intent_lbl.text = ""
		CombatManager.CombatState.RESOLVE, CombatManager.CombatState.ENDED:
			pass


func _on_round_started(_round_num: int) -> void:
	_refresh_all_ui()


func _on_enemy_telegraphed(intent: Dictionary) -> void:
	_e_intent_lbl.text = "⚠ %s đang %s" % [
		_manager.enemy.combatant_name, intent.get("label", "...")]


# Cập nhật một combatant với HP bar animation
func _on_combatant_updated(is_player: bool) -> void:
	if is_player:
		var p := _manager.player
		_tween_hp_bar(true, p.hp, p.max_hp)
		_p_hp_lbl.text    = "HP  %d / %d" % [p.hp, p.max_hp]
		for i in _p_sta_pips.size():
			_p_sta_pips[i].color = Color(0.28, 0.58, 0.88) if i < p.stamina \
								else Color(0.22, 0.22, 0.28)
		_p_status_lbl.text = p.status_summary()
		_p_stat_lbl.text   = _stat_line(p)
		# Refresh skill buttons ngay khi vũ khí thay đổi (switch weapon)
		if _manager.get_state() == CombatManager.CombatState.PLAYER_TURN:
			_update_action_buttons()
	else:
		var e := _manager.enemy
		_tween_hp_bar(false, e.hp, e.max_hp)
		_e_hp_lbl.text     = "HP  %d / %d" % [e.hp, e.max_hp]
		_e_name_lbl.text   = e.combatant_name
		_e_status_lbl.text = e.status_summary()
		_e_stat_lbl.text   = _stat_line(e)


# Flash sprite đỏ + số -HP nổi lên khi bị đánh
func _on_hit_landed(target_is_player: bool, damage: int, is_crit: bool) -> void:
	var sprite  := _p_sprite if target_is_player else _e_sprite
	var restore := _p_color  if target_is_player else _e_color
	var flash   := Color(1.0, 0.75, 0.05) if is_crit else Color(1.0, 0.22, 0.18)
	var tw := create_tween()
	tw.tween_property(sprite, "color", flash, 0.06)
	tw.tween_property(sprite, "color", flash, 0.10)
	tw.tween_property(sprite, "color", restore, 0.28)
	_spawn_damage_number(target_is_player, damage, is_crit)


func _on_combat_ended(result: String, data: Dictionary) -> void:
	_refresh_all_ui()
	match result:
		"win":
			var gold: int = data.get("gold", 30)
			var dropped_loot: Array[Dictionary] = _roll_enemy_loot(_active_enemy_key)
			_store_exploration_win(dropped_loot)
			_result_title.text = "CHIẾN THẮNG"
			_result_title.add_theme_color_override("font_color", Color(0.95, 0.86, 0.2))
			_result_body.text = _loot_result_body(gold, dropped_loot)
			_retry_btn.visible = false
		"lose":
			_prepare_exploration_return()
			_result_title.text = "THẤT BẠI"
			_result_title.add_theme_color_override("font_color", Color(0.82, 0.22, 0.18))
			_result_body.text  = "Mất 30% vàng mang theo\nNhấn R để thử lại"
			_retry_btn.visible = true
		"run":
			var stamina_spent: int = GameManager.consume_flee_stamina(1)
			_prepare_exploration_return()
			_result_title.text = "BỎ CHẠY"
			_result_title.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))
			var stamina_line: String = ""
			if stamina_spent > 0:
				stamina_line = "\nTốn %d thể lực" % stamina_spent
			_result_body.text  = "Bạn đã rời khỏi trận.%s\nNhấn R để đánh lại" % stamina_line
			_retry_btn.visible = true
	# Hiện nút quay lại nếu đến từ exploration
	if not GameManager.post_combat_return.is_empty():
		_return_btn.visible = true

	_result_overlay.visible = true


func _roll_enemy_loot(enemy_key: String) -> Array[Dictionary]:
	var enemy_data: EnemyData = EnemyDatabase.get_enemy(enemy_key)
	if enemy_data == null:
		return []

	var dropped_loot: Array[Dictionary] = []
	for entry in enemy_data.loot_items:
		var item_id: String = entry.get("item_id", "")
		var chance: float = entry.get("chance", 0.0)
		if item_id.is_empty():
			continue
		if randf() < chance:
			dropped_loot.append({"item_id": item_id})
	return dropped_loot


func _store_exploration_win(dropped_loot: Array[Dictionary]) -> void:
	if GameManager.post_combat_return.is_empty():
		return
	var state: Dictionary = GameManager.exploration_state
	if state.is_empty():
		return

	var pending_loot: Array = state.get("pending_loot", [])
	for loot in dropped_loot:
		if not _add_loot_to_hand(loot):
			pending_loot.append(loot)
	state["pending_loot"] = pending_loot
	state["pending_combat_enemy_idx"] = -1
	state["enemy_spawn_seed"] = int(Time.get_ticks_usec())
	GameManager.exploration_state = state


func _prepare_exploration_return() -> void:
	if GameManager.post_combat_return.is_empty():
		return
	var state: Dictionary = GameManager.exploration_state
	if state.is_empty():
		return
	state["pending_combat_enemy_idx"] = -1
	state["enemy_spawn_seed"] = int(Time.get_ticks_usec())
	GameManager.exploration_state = state


func _add_loot_to_hand(loot: Dictionary) -> bool:
	var item_id: String = loot.get("item_id", "")
	var item: ItemData = ItemDatabase.get_item(item_id)
	if item == null:
		return true
	var hand_item: Dictionary = {
		"item_id": item.item_id,
		"item_name": item.item_name,
		"rarity": item.rarity,
		"base_value": item.base_value,
		"item_type": item.item_type,
	}
	hand_item.merge(item.effect_data)
	return GameManager.add_to_hand(hand_item)


func _loot_result_body(gold: int, dropped_loot: Array[Dictionary]) -> String:
	var item_names: Array[String] = []
	for loot in dropped_loot:
		var item_id: String = loot.get("item_id", "")
		var item: ItemData = ItemDatabase.get_item(item_id)
		if item != null:
			item_names.append(item.item_name)

	var items_text: String = "Không có"
	if not item_names.is_empty():
		items_text = ", ".join(item_names)
	return "Chiến lợi phẩm nhận được:\nVàng: %d G\nVật phẩm: %s" % [gold, items_text]


# ══════════════════════════════════════════════════════════════════════════════
# PLAYER INPUT
# ══════════════════════════════════════════════════════════════════════════════

func _on_action_btn_pressed(idx: int) -> void:
	if _manager.get_state() != CombatManager.CombatState.PLAYER_TURN:
		return
	# Keyboard shortcuts phải tôn trọng trạng thái disabled giống click chuột
	if idx < _action_btns.size() and _action_btns[idx].disabled:
		return

	var p: Combatant = _manager.player
	var action: Dictionary

	match idx:
		0: action = { "type": "skill", "skill": CombatManager.SKILLS["basic_attack"] }
		1: action = { "type": "skill", "skill": p.skill1 }
		2: action = { "type": "skill", "skill": p.skill2 }
		3: action = { "type": "run" }
		4: action = { "type": "switch" }

	_manager.submit_player_action(action)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo or not event.pressed:
		return
	match event.keycode:
		KEY_1: _on_action_btn_pressed(0)
		KEY_2: _on_action_btn_pressed(1)
		KEY_3: _on_action_btn_pressed(2)
		KEY_4: _on_action_btn_pressed(3)
		KEY_W: _on_action_btn_pressed(4)
		KEY_R:
			if _retry_btn.visible:
				_on_retry()


func _on_retry() -> void:
	if _result_overlay.visible and not _retry_btn.visible:
		return
	_return_btn.visible = false
	_enemy_cycle_idx = (_enemy_cycle_idx + 1) % _ENEMY_CYCLE.size()
	_setup_mock_combat(_ENEMY_CYCLE[_enemy_cycle_idx])


func _on_return_to_exploration() -> void:
	var path := GameManager.post_combat_return
	GameManager.post_combat_return = ""
	SceneManager.go_to(path)


# ══════════════════════════════════════════════════════════════════════════════
# UI REFRESH
# ══════════════════════════════════════════════════════════════════════════════

func _refresh_all_ui() -> void:
	var p: Combatant = _manager.player
	var e: Combatant = _manager.enemy

	# Kill tweens đang chạy → set ngay lập tức (dùng khi reset/round mới)
	if _p_hp_tween and _p_hp_tween.is_valid(): _p_hp_tween.kill()
	if _e_hp_tween and _e_hp_tween.is_valid(): _e_hp_tween.kill()

	_p_hp_fill.size.x = HP_BAR_W * clampf(float(p.hp) / float(p.max_hp), 0.0, 1.0)
	_p_hp_lbl.text    = "HP  %d / %d" % [p.hp, p.max_hp]
	for i in _p_sta_pips.size():
		_p_sta_pips[i].color = Color(0.28, 0.58, 0.88) if i < p.stamina \
							else Color(0.22, 0.22, 0.28)
	_p_status_lbl.text = p.status_summary()
	_p_stat_lbl.text   = _stat_line(p)

	_e_hp_fill.size.x  = HP_BAR_W * clampf(float(e.hp) / float(e.max_hp), 0.0, 1.0)
	_e_hp_lbl.text     = "HP  %d / %d" % [e.hp, e.max_hp]
	_e_name_lbl.text   = e.combatant_name
	_e_status_lbl.text = e.status_summary()
	_e_stat_lbl.text   = _stat_line(e)


# Animate HP bar mượt từ giá trị hiện tại xuống giá trị mới
func _tween_hp_bar(is_player: bool, new_hp: int, max_hp: int) -> void:
	var fill   := _p_hp_fill if is_player else _e_hp_fill
	var target := HP_BAR_W * clampf(float(new_hp) / float(max_hp), 0.0, 1.0)

	var old_tw := _p_hp_tween if is_player else _e_hp_tween
	if old_tw and old_tw.is_valid():
		old_tw.kill()

	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(fill, "size:x", target, 0.4)

	if is_player: _p_hp_tween = tw
	else:         _e_hp_tween = tw


func _update_action_buttons() -> void:
	var p: Combatant = _manager.player
	_action_btns[0].text = "Tấn Công\nThường  [0 STA]"

	var s1: Dictionary = p.skill1
	var s1c: int       = s1.get("stamina_cost", 0)
	_action_btns[1].text     = "%s\n[%d STA]" % [s1.get("name", "—"), s1c]
	_action_btns[1].disabled = p.stamina < s1c or s1.is_empty()

	var s2: Dictionary = p.skill2
	var s2c: int       = s2.get("stamina_cost", 0)
	_action_btns[2].text     = "%s\n[%d STA]" % [s2.get("name", "—"), s2c]
	_action_btns[2].disabled = p.stamina < s2c or s2.is_empty()

	_action_btns[3].text = "Bỏ Chạy"

	# Button đổi vũ khí — tìm slot tiếp theo có vũ khí
	var pu := p as PlayerCombatUnit
	if pu:
		var next_slot := -1
		for offset in [1, 2]:
			var candidate: int = (pu.active_slot + offset) % 3
			if not pu.is_slot_empty(candidate):
				next_slot = candidate
				break
		if next_slot == -1:
			_action_btns[4].disabled = true
			_action_btns[4].text     = "Đổi Vũ Khí\n(không có)"
		else:
			_action_btns[4].disabled = false
			var next_name: String = pu.get_slot_weapon(next_slot).get("weapon_name", "???")
			_action_btns[4].text  = "→ %s\n[Tốn lượt]" % next_name
	else:
		_action_btns[4].disabled = true
		_action_btns[4].text     = "Đổi Vũ Khí\n—"


func _set_buttons_disabled(disabled: bool) -> void:
	for btn in _action_btns:
		btn.disabled = disabled


func _append_log(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > 5:
		_log_lines = _log_lines.slice(_log_lines.size() - 5)
	_log_label.text = "\n".join(_log_lines)


# ══════════════════════════════════════════════════════════════════════════════
# FLOATING DAMAGE NUMBER
# ══════════════════════════════════════════════════════════════════════════════

func _spawn_damage_number(target_is_player: bool, damage: int, is_crit: bool = false) -> void:
	var sprite := _p_sprite if target_is_player else _e_sprite

	var lbl := Label.new()
	lbl.text = ("!%d!" % damage) if is_crit else ("-%d" % damage)
	var font_size := 88 if is_crit else 72
	lbl.add_theme_font_size_override("font_size", font_size)
	var color := Color(1.0, 0.82, 0.05) if is_crit else Color(1.0, 0.25, 0.15)
	lbl.add_theme_color_override("font_color", color)
	add_child(lbl)

	var center := sprite.global_position + sprite.size * 0.5
	lbl.position = center + Vector2(-30.0, -sprite.size.y * 0.25)

	var rise := 160.0 if is_crit else 120.0
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - rise, 0.85)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.85)
	tw.tween_callback(lbl.queue_free)


# ══════════════════════════════════════════════════════════════════════════════
# STAT HELPERS
# ══════════════════════════════════════════════════════════════════════════════

# Trả về dòng stats hiển thị (bao gồm cả def_bonus đang active)
func _stat_line(c: Combatant) -> String:
	var eff_atk: int = max(0, c.atk - c.atk_penalty)
	var eff_def := c.def_stat + c.def_bonus
	var parts: Array[String] = [
		"ATK %d" % eff_atk,
		"DEF %d" % eff_def,
		"SPD %d" % c.speed,
	]
	if c.magic > 0:
		parts.append("MAG %d" % c.magic)
	# Hiển thị Durability vũ khí đang cầm (chỉ player)
	var pu := c as PlayerCombatUnit
	if pu:
		var w := pu.get_active_weapon()
		if not w.is_empty():
			var dur:     int = w.get("durability",     50)
			var dur_max: int = w.get("durability_max", 50)
			var tag := "DUR %d/%d" % [dur, dur_max]
			if dur == 0:
				tag += " [HỎNG]"
			parts.append(tag)
	return "  |  ".join(parts)
