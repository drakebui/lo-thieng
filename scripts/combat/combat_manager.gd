# combat_manager.gd
# Điều phối toàn bộ logic combat với state machine:
# IDLE → PLAYER_TURN → ENEMY_TURN → RESOLVE → (loop) → ENDED
#
# Không chứa UI. Emit signals để combat_scene.gd cập nhật hiển thị.
# API công khai: start_combat() và submit_player_action()
class_name CombatManager
extends Node

# ══════════════════════════════════════════════════════════════════════════════
# SIGNALS — combat_scene.gd lắng nghe để cập nhật UI
# ══════════════════════════════════════════════════════════════════════════════

signal state_changed(new_state: CombatState)
signal round_started(round_num: int)
signal enemy_telegraphed(intent: Dictionary)
signal action_logged(message: String)
signal combatant_updated(is_player: bool)
signal hit_landed(target_is_player: bool, damage: int, is_crit: bool)
signal combat_ended(result: String, reward_data: Dictionary)

# ══════════════════════════════════════════════════════════════════════════════
# STATE MACHINE
# ══════════════════════════════════════════════════════════════════════════════

enum CombatState { IDLE, PLAYER_TURN, ENEMY_TURN, RESOLVE, ENDED }

# Khoảng dừng giữa action player và action enemy (giây)
const ACTION_DELAY := 0.65
const SKILL_DIR := "res://resources/skills"

# ══════════════════════════════════════════════════════════════════════════════
# STATE
# ══════════════════════════════════════════════════════════════════════════════

var player: Combatant      = null
var enemy:  EnemyCombatUnit = null
var skill_db: Dictionary = {}

var _state:          CombatState = CombatState.IDLE
var _round_num:      int         = 0
var _enemy_intent:   Dictionary  = {}
var _pending_action: Dictionary  = {}
var _is_counter_encounter: bool = false
var _counter_bonus_applied: bool = false
var _combat_session_id: int = 0


# ══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_load_skill_db()


func start_combat(p: Combatant, e: EnemyCombatUnit) -> void:
	_combat_session_id += 1
	player     = p
	enemy      = e
	_round_num = 0
	_is_counter_encounter = GameManager.pending_combat_is_counter
	GameManager.pending_combat_is_counter = false
	_counter_bonus_applied = false
	_go_to(CombatState.PLAYER_TURN)


# Gọi từ UI khi player bấm nút hành động
func submit_player_action(action: Dictionary) -> void:
	if _state != CombatState.PLAYER_TURN:
		return
	_pending_action = action
	_go_to(CombatState.ENEMY_TURN)


func get_state() -> CombatState:
	return _state


func get_skill(skill_id: String) -> SkillData:
	if skill_db.is_empty():
		_load_skill_db()
	return skill_db.get(skill_id, null)


# ══════════════════════════════════════════════════════════════════════════════
# STATE MACHINE — TRANSITIONS
# ══════════════════════════════════════════════════════════════════════════════

func _go_to(new_state: CombatState) -> void:
	_state = new_state
	match new_state:
		CombatState.PLAYER_TURN: _enter_player_turn()
		CombatState.ENEMY_TURN:  _enter_enemy_turn()
		CombatState.RESOLVE:     _enter_resolve()
		CombatState.ENDED:       pass


# ─── PLAYER_TURN ──────────────────────────────────────────────────────────────
# Enemy quyết định intent (telegraph), sau đó chờ player chọn hành động

func _enter_player_turn() -> void:
	_round_num += 1
	if _round_num == 1 and _is_counter_encounter:
		_counter_bonus_applied = false
		_log("> Phủ Đầu! Đòn đầu tiên tăng 30% sát thương.")

	# Hồi stamina cho player mỗi đầu lượt
	if player is PlayerCombatUnit:
		(player as PlayerCombatUnit).regen_stamina()

	var e_hp_pct: float = clampf(float(enemy.hp)  / float(enemy.max_hp),  0.0, 1.0)
	var p_hp_pct: float = clampf(float(player.hp) / float(player.max_hp), 0.0, 1.0)
	_enemy_intent = EnemyAI.decide(enemy, _round_num, e_hp_pct, p_hp_pct)

	round_started.emit(_round_num)
	enemy_telegraphed.emit(_enemy_intent)
	state_changed.emit(CombatState.PLAYER_TURN)


# ─── ENEMY_TURN ───────────────────────────────────────────────────────────────
# Resolve cả 2 hành động tuần tự với delay, tốc độ quyết định thứ tự

func _enter_enemy_turn() -> void:
	var session_id := _combat_session_id
	state_changed.emit(CombatState.ENEMY_TURN)

	_log("─── Lượt %d ───" % _round_num)

	# Bỏ chạy — kết thúc ngay, không cần delay
	if _pending_action.get("type") == "run":
		_log("> Bạn bỏ chạy khỏi trận!")
		_finish("run", {})
		return

	var player_faster:    bool = player.speed >= enemy.speed
	var enemy_defending: bool = _enemy_intent.get("type", "") == "defend"
	var can_continue := true

	# Khi enemy đang phòng thủ, luôn cho enemy hành động trước (bất kể speed)
	# để DEF bonus có hiệu lực ngay khi player tấn công trong cùng lượt.
	if player_faster and not enemy_defending:
		# Player đánh trước
		_do_player_action(_pending_action)
		can_continue = not _check_end()
		if can_continue:
			await get_tree().create_timer(ACTION_DELAY).timeout
			if not is_inside_tree() or session_id != _combat_session_id:
				return
			can_continue = _state == CombatState.ENEMY_TURN
		if can_continue:
			_do_enemy_action()
	else:
		# Enemy hành động trước (do chậm hơn player, hoặc đang phòng thủ)
		_do_enemy_action()
		can_continue = not _check_end()
		if can_continue:
			await get_tree().create_timer(ACTION_DELAY).timeout
			if not is_inside_tree() or session_id != _combat_session_id:
				return
			can_continue = _state == CombatState.ENEMY_TURN
		if can_continue:
			_do_player_action(_pending_action)

	if can_continue:
		can_continue = not _check_end()

	# Delay nhỏ trước khi chuyển sang RESOLVE để player đọc log
	if can_continue:
		await get_tree().create_timer(ACTION_DELAY * 0.6).timeout
		if not is_inside_tree() or session_id != _combat_session_id:
			return
		can_continue = _state == CombatState.ENEMY_TURN

	if can_continue:
		_go_to(CombatState.RESOLVE)


# ─── RESOLVE ─────────────────────────────────────────────────────────────────
# Tick status effects + buff durations → kiểm tra kết thúc → lượt tiếp

func _enter_resolve() -> void:
	state_changed.emit(CombatState.RESOLVE)

	for msg in player.tick_status():
		_log("> " + msg)
	for msg in enemy.tick_status():
		_log("> " + msg)
	player.tick_buffs()
	enemy.tick_buffs()

	combatant_updated.emit(true)
	combatant_updated.emit(false)

	if _check_end(): return

	_go_to(CombatState.PLAYER_TURN)


# ══════════════════════════════════════════════════════════════════════════════
# ACTION EXECUTION
# ══════════════════════════════════════════════════════════════════════════════

func _do_player_action(action: Dictionary) -> void:
	if player.lose_next_turn:
		player.lose_next_turn = false
		if player.freeze_turns > 0:
			player.freeze_turns = maxi(0, player.freeze_turns - 1)
		_log("> Bạn mất lượt này (hậu quả đòn trước)!")
		combatant_updated.emit(true)
		return

	if player.freeze_turns > 0:
		player.freeze_turns = maxi(0, player.freeze_turns - 1)
		_log("> Bạn bị Đóng Băng — không thể hành động!")
		combatant_updated.emit(true)
		return

	if action.get("type") == "switch":
		var pu := player as PlayerCombatUnit
		if pu:
			var result := pu.switch_to_next_slot()
			if result == PlayerCombatUnit.SwitchResult.OK:
				_log("> Đổi sang: %s!" % pu.get_active_weapon().get("weapon_name", "???"))
			else:
				_log("> Không có vũ khí khác để đổi.")
		combatant_updated.emit(true)
		return

	var skill: Variant = action.get("skill", {})
	var cost:  int     = _get_skill_cost(skill)
	player.stamina        = max(0, player.stamina - cost)

	_execute_skill(skill, player, enemy)

	# Trừ Durability khi dùng skill có chi phí (basic attack = 0 STA không tính)
	if cost > 0:
		var pu := player as PlayerCombatUnit
		if pu and pu.spend_durability():
			_log("> [Cảnh báo] Vũ khí bị hỏng! Sức mạnh giảm 50%.")

	combatant_updated.emit(true)
	combatant_updated.emit(false)


func _do_enemy_action() -> void:
	if enemy.lose_next_turn:
		enemy.lose_next_turn = false
		if enemy.freeze_turns > 0:
			enemy.freeze_turns = maxi(0, enemy.freeze_turns - 1)
		_log("> %s mất lượt!" % enemy.combatant_name)
		combatant_updated.emit(false)
		return

	if enemy.freeze_turns > 0:
		enemy.freeze_turns = maxi(0, enemy.freeze_turns - 1)
		_log("> %s bị Đóng Băng — không thể hành động!" % enemy.combatant_name)
		combatant_updated.emit(false)
		combatant_updated.emit(true)
		return

	match _enemy_intent.get("type", "attack"):
		"attack":
			var eff_crit: float = maxf(0.0, enemy.crit_rate - player.crit_resist)
			var is_crit:  bool  = randf() < eff_crit
			var raw := enemy.calc_raw_damage(1.0, 0)
			if is_crit:
				raw = int(raw * 1.5)
			var actual := player.take_damage(raw)
			if actual == 0:
				_log("> %s tấn công — bị chặn bởi khiên!" % enemy.combatant_name)
				AudioManager.play_sfx_key("shield_block")
			elif is_crit:
				_log("> %s ĐÒN CHÍ MẠNG! -%d HP" % [enemy.combatant_name, actual])
				hit_landed.emit(true, actual, true)
				AudioManager.play_sfx_key("player_hurt")
			else:
				_log("> %s tấn công: -%d HP" % [enemy.combatant_name, actual])
				hit_landed.emit(true, actual, false)
				AudioManager.play_sfx_key("player_hurt")

		"defend":
			enemy.def_bonus       = 4
			enemy.def_bonus_turns = 1  # hết sau RESOLVE cùng lượt; enemy luôn defend trước player tấn công
			_log("> %s phòng thủ! (+4 DEF lượt này)" % enemy.combatant_name)

		"skill":
			var skill_id: String = _enemy_intent.get("skill_id", "enemy_magic")
			if skill_db.has(skill_id):
				_execute_skill(skill_db[skill_id], enemy, player)
			else:
				var eff_crit: float = maxf(0.0, enemy.crit_rate - player.crit_resist)
				var is_crit:  bool  = randf() < eff_crit
				var dmg := enemy.calc_raw_damage(1.2)
				if is_crit:
					dmg = int(dmg * 1.5)
				var actual := player.take_damage(dmg)
				if is_crit:
					_log("> %s ĐÒN CHÍ MẠNG (phép)! -%d HP" % [enemy.combatant_name, actual])
					hit_landed.emit(true, actual, true)
				else:
					_log("> %s dùng phép thuật: -%d HP" % [enemy.combatant_name, actual])
					hit_landed.emit(true, actual, false)

		"run":
			_log("> %s bỏ chạy khỏi trận!" % enemy.combatant_name)
			_finish("enemy_run", {})
			return

	combatant_updated.emit(false)
	combatant_updated.emit(true)


# ══════════════════════════════════════════════════════════════════════════════
# SKILL EXECUTION (MVP — chuyển sang skill_executor.gd ở phase sau)
# ══════════════════════════════════════════════════════════════════════════════

func _execute_skill(skill_data: Variant, attacker: Combatant, target: Combatant) -> void:
	var skill: Dictionary = _skill_to_runtime_dict(skill_data)
	if skill.is_empty():
		return
	var effect:     String = skill.get("effect",       "DAMAGE")
	var mult:       float  = skill.get("damage_mult",  1.0)
	var dice:       int    = skill.get("dice",         0)
	var ignore_def: float  = skill.get("ignore_def",   0.0)
	var name:       String = skill.get("name",         "???")

	var target_is_player := (target == player)

	match effect:
		"DAMAGE":
			var raw: int
			var eff_ignore: float = ignore_def
			if skill.get("use_magic", false):
				raw = attacker.calc_magic_damage(skill.get("magic_mult", 1.0))
				eff_ignore = maxf(ignore_def, 0.5)
			else:
				raw = attacker.calc_raw_damage(mult, dice)
			raw = _apply_counter_bonus(raw, attacker, target, effect)
			var actual := target.take_damage(raw, eff_ignore)
			_log("> %s dùng %s: %s" % [attacker.combatant_name, name,
				"chặn bởi khiên!" if actual == 0 else "-%d HP" % actual])
			if actual > 0:
				hit_landed.emit(target_is_player, actual, false)
				AudioManager.play_sfx_key("player_hurt" if target_is_player else "sword_hit")
			elif actual == 0:
				AudioManager.play_sfx_key("shield_block")

		"DAMAGE_IGNORE_DEF":
			# Xuyên DEF — ignore_def 1.0 = bỏ qua toàn bộ DEF địch.
			var raw := attacker.calc_raw_damage(mult, dice)
			raw = _apply_counter_bonus(raw, attacker, target, effect)
			var actual := target.take_damage(raw, skill.get("ignore_def", 1.0))
			_log("> %s dùng %s (xuyên DEF): %s" % [
				attacker.combatant_name, name,
				"chặn bởi khiên!" if actual == 0 else "-%d HP" % actual,
			])
			if actual > 0:
				hit_landed.emit(target_is_player, actual, false)
				AudioManager.play_sfx_key("player_hurt" if target_is_player else "sword_hit")
			elif actual == 0:
				AudioManager.play_sfx_key("shield_block")

		"DAMAGE_HEAL":
			var raw    := attacker.calc_raw_damage(mult, dice)
			raw = _apply_counter_bonus(raw, attacker, target, effect)
			var actual := target.take_damage(raw)
			var healed := attacker.heal(skill.get("heal_flat", 0))
			_log("> %s dùng %s: %s, +%d HP bản thân" % [
				attacker.combatant_name, name,
				"chặn bởi khiên!" if actual == 0 else "-%d HP địch" % actual, healed])
			if actual > 0:
				hit_landed.emit(target_is_player, actual, false)
				AudioManager.play_sfx_key("player_hurt" if target_is_player else "sword_hit")
			elif actual == 0:
				AudioManager.play_sfx_key("shield_block")

		"DAMAGE_STATUS":
			var raw    := attacker.calc_raw_damage(mult, dice)
			raw = _apply_counter_bonus(raw, attacker, target, effect)
			var actual := target.take_damage(raw)
			var status: String = skill.get("status", "")
			var applied: bool  = actual > 0 and randf() <= skill.get("effect_chance", 1.0)

			var msg := "> %s dùng %s: %s" % [
				attacker.combatant_name, name,
				"chặn bởi khiên!" if actual == 0 else "-%d HP" % actual,
			]
			if applied and status != "":
				match status:
					"burn":
						target.burn_turns = skill.get("status_turns", 2)
						target.burn_dmg   = skill.get("status_dmg",   4)
						msg += " + Bỏng %d lượt!" % target.burn_turns
					"freeze":
						target.freeze_turns = skill.get("status_turns", 1)
						msg += " + Đóng Băng!"
					"poison":
						target.poison_turns = skill.get("status_turns", 3)
						msg += " + Độc!"
			_log(msg)
			if actual > 0:
				hit_landed.emit(target_is_player, actual, false)
				var hit_sfx := "skill_fire" if status == "burn" \
						else "skill_ice" if status == "freeze" \
						else ("player_hurt" if target_is_player else "sword_hit")
				AudioManager.play_sfx_key(hit_sfx)
			elif actual == 0:
				AudioManager.play_sfx_key("shield_block")

		"BUFF_DEF":
			attacker.def_bonus       = skill.get("def_bonus",       0)
			attacker.def_bonus_turns = skill.get("def_bonus_turns", 1)
			_log("> %s dùng %s: +%d DEF trong %d lượt!" % [
				attacker.combatant_name, name,
				attacker.def_bonus, attacker.def_bonus_turns])
			AudioManager.play_sfx_key("shield_block")

		"DEBUFF_ATK":
			target.atk_penalty       = skill.get("atk_penalty",       0)
			target.atk_penalty_turns = skill.get("atk_penalty_turns", 1)
			# Không modify target.atk trực tiếp — penalty áp dụng trong calc_raw_damage
			_log("> %s dùng %s: -%d ATK địch trong %d lượt!" % [
				attacker.combatant_name, name,
				target.atk_penalty, target.atk_penalty_turns])

		"DAMAGE_SKIP_TURN":
			# Nặng Tay — Crushing Blow: ×2 dmg, mất lượt tiếp theo
			var raw    := attacker.calc_raw_damage(mult, dice)
			raw = _apply_counter_bonus(raw, attacker, target, effect)
			var actual := target.take_damage(raw, ignore_def)
			attacker.lose_next_turn = true
			_log("> %s dùng %s: -%d HP (sẽ mất lượt sau!)" % [
				attacker.combatant_name, name, actual])
			if actual > 0:
				hit_landed.emit(target_is_player, actual, false)
				AudioManager.play_sfx_key("player_hurt" if target_is_player else "blunt_swing")

		"DAMAGE_TWICE":
			# Thần Tốc — Double Strike: đánh 2 lần liên tiếp
			var total := 0
			for _i in 2:
				var raw    := attacker.calc_raw_damage(mult, dice)
				raw = _apply_counter_bonus(raw, attacker, target, effect)
				var actual := target.take_damage(raw, ignore_def)
				total += actual
				if not target.is_alive():
					break
			_log("> %s dùng %s: 2 đòn, -%d HP tổng!" % [
				attacker.combatant_name, name, total])
			if total > 0:
				hit_landed.emit(target_is_player, total, false)
				AudioManager.play_sfx_key("player_hurt" if target_is_player else "sword_hit")

		"BUFF_ALL_STATS":
			# Cân Bằng — Balanced Stance: dmg_mult phủ ATK+Magic, def_bonus phủ DEF
			var turns: int   = skill.get("stat_bonus_turns", 2)
			var pct:   float = skill.get("stat_bonus_pct",   0.15)
			attacker.dmg_mult        = 1.0 + pct
			attacker.dmg_mult_turns  = turns
			attacker.def_bonus       = maxi(1, int(round(attacker.def_stat * pct)))
			attacker.def_bonus_turns = turns
			_log("> %s dùng %s: +%.0f%% mọi stat trong %d lượt!" % [
				attacker.combatant_name, name, pct * 100.0, turns])

		"SHIELD_ONE_HIT":
			# Cứng Như Đá — Stone Form: chặn hoàn toàn 1 đòn kế tiếp
			attacker.shield_active = true
			_log("> %s dùng %s: sẵn sàng chặn 1 đòn!" % [
				attacker.combatant_name, name])
			AudioManager.play_sfx_key("shield_block")

		"PASSIVE_NO_DURABILITY":
			# Trường Sinh — Eternal: hiệu ứng bị động, không cần kích hoạt thủ công
			# (Durability system chưa implement — skill này chỉ log thông báo)
			_log("> %s: Eternal đang hoạt động — không mất Durability trong trận." % \
				attacker.combatant_name)


func _apply_counter_bonus(
		raw_damage: int,
		attacker: Combatant,
		target: Combatant,
		effect: String
) -> int:
	if _counter_bonus_applied:
		return raw_damage
	if _round_num != 1 or not _is_counter_encounter:
		return raw_damage
	if attacker != player or target != enemy:
		return raw_damage
	if effect not in [
		"DAMAGE",
		"DAMAGE_IGNORE_DEF",
		"DAMAGE_HEAL",
		"DAMAGE_STATUS",
		"DAMAGE_SKIP_TURN",
		"DAMAGE_TWICE",
	]:
		return raw_damage
	_counter_bonus_applied = true
	return int(round(raw_damage * 1.3))


# ══════════════════════════════════════════════════════════════════════════════
# WIN / LOSE DETECTION
# ══════════════════════════════════════════════════════════════════════════════

func _check_end() -> bool:
	if _state == CombatState.ENDED:
		return true
	if not player.is_alive():
		_finish("lose", {})
		return true
	if not enemy.is_alive():
		AudioManager.play_sfx_key("enemy_death")
		_finish("win", _build_win_reward())
		return true
	return false


func _build_win_reward() -> Dictionary:
	var total_gold: int = enemy.drop_gold
	if player is PlayerCombatUnit:
		var active_weapon: Dictionary = (player as PlayerCombatUnit).get_active_weapon()
		var s1: Dictionary = active_weapon.get("skill1", {})
		var bonus_gold: int = int(s1.get("gold_bonus_on_win", 0))
		if bonus_gold > 0:
			total_gold += bonus_gold
		var bonus_rep: int = int(s1.get("rep_bonus_on_win", 0))
		if bonus_rep > 0:
			GameManager.add_reputation(bonus_rep)
	return { "gold": total_gold }


func _finish(result: String, data: Dictionary) -> void:
	_state = CombatState.ENDED
	state_changed.emit(CombatState.ENDED)
	match result:
		"win":  AudioManager.play_sfx_key("combat_victory")
		"lose": AudioManager.play_sfx_key("player_death")
	EventBus.combat_ended.emit(result)
	combat_ended.emit(result, data)


# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _log(msg: String) -> void:
	action_logged.emit(msg)


func _load_skill_db() -> void:
	skill_db.clear()
	var dir := DirAccess.open(SKILL_DIR)
	if dir == null:
		return

	var files: PackedStringArray = dir.get_files()
	files.sort()
	for file_name in files:
		if file_name.get_extension() != "tres":
			continue

		var resource_path := "%s/%s" % [SKILL_DIR, file_name]
		var resource := load(resource_path)
		if resource is SkillData:
			var skill := resource as SkillData
			skill_db[skill.skill_id] = skill


func _get_skill_cost(skill_data: Variant) -> int:
	if skill_data is SkillData:
		return (skill_data as SkillData).stamina_cost
	if skill_data is Dictionary:
		var skill: Dictionary = skill_data
		return skill.get("stamina_cost", 0)
	return 0


func _skill_to_runtime_dict(skill_data: Variant) -> Dictionary:
	if skill_data is Dictionary:
		return skill_data
	if not skill_data is SkillData:
		return {}

	var skill := skill_data as SkillData
	return {
		"name": skill.skill_name,
		"stamina_cost": skill.stamina_cost,
		"effect": skill.effect,
		"damage_mult": skill.damage_mult,
		"dice": skill.dice,
		"status": skill.status,
		"status_turns": skill.status_turns,
		"status_dmg": skill.status_dmg,
		"effect_chance": skill.effect_chance,
		"ignore_def": skill.ignore_def,
		"heal_flat": skill.heal_flat,
		"use_magic": skill.use_magic,
		"magic_mult": skill.magic_mult,
		"def_bonus": skill.def_bonus,
		"def_bonus_turns": skill.def_bonus_turns,
		"atk_penalty": skill.atk_penalty,
		"atk_penalty_turns": skill.atk_penalty_turns,
		"stat_bonus_pct": skill.stat_bonus_pct,
		"stat_bonus_turns": skill.stat_bonus_turns,
	}
