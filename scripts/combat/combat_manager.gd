# combat_manager.gd
# Điều phối toàn bộ logic combat với state machine:
# IDLE → PLAYER_TURN → ENEMY_TURN → RESOLVE → (loop) → ENDED
#
# Không chứa UI. Emit signals để combat_scene.gd cập nhật hiển thị.
# API công khai: start_combat() và submit_player_action()
extends Node
class_name CombatManager

# ══════════════════════════════════════════════════════════════════════════════
# STATE MACHINE
# ══════════════════════════════════════════════════════════════════════════════

enum CombatState { IDLE, PLAYER_TURN, ENEMY_TURN, RESOLVE, ENDED }

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

# Khoảng dừng giữa action player và action enemy (giây)
const ACTION_DELAY := 0.65

# ══════════════════════════════════════════════════════════════════════════════
# SKILL DATABASE (MVP — chuyển sang SkillExecutor + .tres ở phase sau)
# ══════════════════════════════════════════════════════════════════════════════

const SKILLS: Dictionary = {
	"basic_attack": {
		"name": "Tấn Công Thường", "stamina_cost": 0,
		"effect": "DAMAGE", "damage_mult": 1.0, "dice": 4,
	},
	"master_form": {
		"name": "Master's Form", "stamina_cost": 2,
		"effect": "DAMAGE_HEAL", "damage_mult": 1.3, "dice": 0, "heal_flat": 10,
	},
	"slash": {
		"name": "Slash", "stamina_cost": 1,
		"effect": "DAMAGE", "damage_mult": 1.5, "dice": 0,
	},
	"burn_skill": {
		"name": "Burn", "stamina_cost": 2,
		"effect": "DAMAGE_STATUS", "damage_mult": 1.0, "dice": 0,
		"status": "burn", "status_turns": 2, "status_dmg": 4,
	},
	"freeze_skill": {
		"name": "Băng Giá", "stamina_cost": 2,
		"effect": "DAMAGE_STATUS", "damage_mult": 0.8, "dice": 0,
		"status": "freeze", "status_turns": 1, "effect_chance": 0.5,
	},
	"chain_lightning": {
		"name": "Sấm Sét", "stamina_cost": 2,
		"effect": "DAMAGE", "damage_mult": 1.0, "dice": 0, "ignore_def": 0.5,
	},
	"iron_wall": {
		"name": "Iron Wall", "stamina_cost": 1,
		"effect": "BUFF_DEF", "def_bonus": 5, "def_bonus_turns": 2,
	},
	"heroic_shout": {
		"name": "Heroic Shout", "stamina_cost": 1,
		"effect": "DEBUFF_ATK", "atk_penalty": 2, "atk_penalty_turns": 3,
	},
	"enemy_bite": {
		"name": "Cắn Mạnh", "stamina_cost": 0,
		"effect": "DAMAGE", "damage_mult": 1.3, "dice": 0,
	},
	"enemy_magic": {
		"name": "Ma Lực", "stamina_cost": 0,
		"effect": "DAMAGE", "damage_mult": 0.0, "dice": 0, "use_magic": true, "magic_mult": 1.5,
	},
}

# ══════════════════════════════════════════════════════════════════════════════
# ENEMY TEMPLATES (MVP — chuyển sang EnemyData.tres ở phase sau)
# ══════════════════════════════════════════════════════════════════════════════

const ENEMY_TEMPLATES: Dictionary = {
	# Đồng Mây Trắng — vùng đầu tiên, kẻ địch mức cơ bản
	# Mục tiêu: 3-4 lượt với player ATK=16 DEF=2 (Kiếm Đơn slot 0)
	# Sói: T1 Slash(21) T2 Burn(13+tick) T3 Slash(21+tick) → enemy HP=0 giữa T3-T4
	"soi": {
		"name": "Sói Hoang", "archetype": "aggressive",
		"hp": 72, "atk": 13, "def_stat": 3, "magic": 0, "speed": 6,
		"color": Color(0.55, 0.25, 0.12), "drop_gold": 45,
		"crit_rate": 0.25,  # hung hăng → crit cao nhất
	},
	# Người Đá: DEF cao, thủ mỗi lượt 3 → kéo dài 4-5 lượt
	"nguoi_da": {
		"name": "Người Đá", "archetype": "defensive",
		"hp": 75, "atk": 11, "def_stat": 6, "magic": 0, "speed": 4,
		"color": Color(0.42, 0.42, 0.45), "drop_gold": 60,
		"crit_rate": 0.10,  # phòng thủ → ít crit
	},
	# Ma Rừng: caster xen kẽ basic/magic → 3-4 lượt, player phải chịu magic burst
	"ma_rung": {
		"name": "Ma Rừng", "archetype": "caster",
		"hp": 60, "atk": 5, "def_stat": 2, "magic": 10, "speed": 8,
		"color": Color(0.22, 0.45, 0.35), "drop_gold": 75,
		"crit_rate": 0.20,  # phép thuật tập trung → crit trung bình
	},
}

# ══════════════════════════════════════════════════════════════════════════════
# STATE
# ══════════════════════════════════════════════════════════════════════════════

var _state:          CombatState = CombatState.IDLE
var _round_num:      int         = 0
var _enemy_intent:   Dictionary  = {}
var _pending_action: Dictionary  = {}

var player: Combatant      = null
var enemy:  EnemyCombatUnit = null


# ══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ══════════════════════════════════════════════════════════════════════════════

func start_combat(p: Combatant, e: EnemyCombatUnit) -> void:
	player     = p
	enemy      = e
	_round_num = 0
	_go_to(CombatState.PLAYER_TURN)


# Gọi từ UI khi player bấm nút hành động
func submit_player_action(action: Dictionary) -> void:
	if _state != CombatState.PLAYER_TURN:
		return
	_pending_action = action
	_go_to(CombatState.ENEMY_TURN)


func get_state() -> CombatState:
	return _state


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
	state_changed.emit(CombatState.ENEMY_TURN)

	_log("─── Lượt %d ───" % _round_num)

	# Bỏ chạy — kết thúc ngay, không cần delay
	if _pending_action.get("type") == "run":
		_log("> Bạn bỏ chạy khỏi trận!")
		_finish("run", {})
		return

	var player_faster:    bool = player.speed >= enemy.speed
	var enemy_defending: bool = _enemy_intent.get("type", "") == "defend"

	# Khi enemy đang phòng thủ, luôn cho enemy hành động trước (bất kể speed)
	# để DEF bonus có hiệu lực ngay khi player tấn công trong cùng lượt.
	if player_faster and not enemy_defending:
		# Player đánh trước
		_do_player_action(_pending_action)
		if _check_end(): return
		await get_tree().create_timer(ACTION_DELAY).timeout
		if _state != CombatState.ENEMY_TURN: return
		_do_enemy_action()
	else:
		# Enemy hành động trước (do chậm hơn player, hoặc đang phòng thủ)
		_do_enemy_action()
		if _check_end(): return
		await get_tree().create_timer(ACTION_DELAY).timeout
		if _state != CombatState.ENEMY_TURN: return
		_do_player_action(_pending_action)

	if _check_end(): return

	# Delay nhỏ trước khi chuyển sang RESOLVE để player đọc log
	await get_tree().create_timer(ACTION_DELAY * 0.6).timeout
	if _state != CombatState.ENEMY_TURN: return

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
		_log("> Bạn mất lượt này (hậu quả đòn trước)!")
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

	var skill: Dictionary = action.get("skill", {})
	var cost:  int        = skill.get("stamina_cost", 0)
	player.stamina        = max(0, player.stamina - cost)

	_execute_skill(skill, player, enemy)

	# Trừ Durability khi dùng skill có chi phí (basic attack = 0 STA không tính)
	if cost > 0:
		var pu := player as PlayerCombatUnit
		if pu and pu.spend_durability():
			_log("> ⚠ Vũ khí bị hỏng! Sức mạnh giảm 50%.")

	combatant_updated.emit(true)
	combatant_updated.emit(false)


func _do_enemy_action() -> void:
	if enemy.lose_next_turn:
		enemy.lose_next_turn = false
		_log("> %s mất lượt!" % enemy.combatant_name)
		combatant_updated.emit(false)
		return

	if enemy.freeze_turns > 0 and randf() < 0.5:
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
			elif is_crit:
				_log("> %s ĐÒN CHÍ MẠNG! -%d HP" % [enemy.combatant_name, actual])
				hit_landed.emit(true, actual, true)
			else:
				_log("> %s tấn công: -%d HP" % [enemy.combatant_name, actual])
				hit_landed.emit(true, actual, false)

		"defend":
			enemy.def_bonus       = 4
			enemy.def_bonus_turns = 1  # hết sau RESOLVE cùng lượt; enemy luôn defend trước player tấn công
			_log("> %s phòng thủ! (+4 DEF lượt này)" % enemy.combatant_name)

		"skill":
			var skill_id: String = _enemy_intent.get("skill_id", "enemy_magic")
			if SKILLS.has(skill_id):
				_execute_skill(SKILLS[skill_id], enemy, player)
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
			_finish("win", { "gold": enemy.drop_gold })
			return

	combatant_updated.emit(false)
	combatant_updated.emit(true)


# ══════════════════════════════════════════════════════════════════════════════
# SKILL EXECUTION (MVP — chuyển sang skill_executor.gd ở phase sau)
# ══════════════════════════════════════════════════════════════════════════════

func _execute_skill(skill: Dictionary, attacker: Combatant, target: Combatant) -> void:
	var effect:     String = skill.get("effect",       "DAMAGE")
	var mult:       float  = skill.get("damage_mult",  1.0)
	var dice:       int    = skill.get("dice",         0)
	var ignore_def: float  = skill.get("ignore_def",   0.0)
	var name:       String = skill.get("name",         "???")

	var target_is_player := (target == player)

	match effect:
		"DAMAGE":
			var raw: int
			if skill.get("use_magic", false):
				raw = attacker.calc_magic_damage(skill.get("magic_mult", 1.0))
			else:
				raw = attacker.calc_raw_damage(mult, dice)
			var actual := target.take_damage(raw, ignore_def)
			_log("> %s dùng %s: %s" % [attacker.combatant_name, name,
				"chặn bởi khiên!" if actual == 0 else "-%d HP" % actual])
			if actual > 0:
				hit_landed.emit(target_is_player, actual, false)

		"DAMAGE_HEAL":
			var raw    := attacker.calc_raw_damage(mult, dice)
			var actual := target.take_damage(raw)
			var healed := attacker.heal(skill.get("heal_flat", 0))
			_log("> %s dùng %s: -%d HP địch, +%d HP bản thân" % [
				attacker.combatant_name, name, actual, healed])
			if actual > 0:
				hit_landed.emit(target_is_player, actual, false)

		"DAMAGE_STATUS":
			var raw    := attacker.calc_raw_damage(mult, dice)
			var actual := target.take_damage(raw)
			var status: String = skill.get("status", "")
			var applied: bool  = randf() <= skill.get("effect_chance", 1.0)

			var msg := "> %s dùng %s: -%d HP" % [attacker.combatant_name, name, actual]
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

		"BUFF_DEF":
			attacker.def_bonus       = skill.get("def_bonus",       0)
			attacker.def_bonus_turns = skill.get("def_bonus_turns", 1)
			_log("> %s dùng %s: +%d DEF trong %d lượt!" % [
				attacker.combatant_name, name,
				attacker.def_bonus, attacker.def_bonus_turns])

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
			var actual := target.take_damage(raw, ignore_def)
			attacker.lose_next_turn = true
			_log("> %s dùng %s: -%d HP (sẽ mất lượt sau!)" % [
				attacker.combatant_name, name, actual])
			if actual > 0:
				hit_landed.emit(target_is_player, actual, false)

		"DAMAGE_TWICE":
			# Thần Tốc — Double Strike: đánh 2 lần liên tiếp
			var total := 0
			for _i in 2:
				var raw    := attacker.calc_raw_damage(mult, dice)
				var actual := target.take_damage(raw, ignore_def)
				total += actual
			_log("> %s dùng %s: 2 đòn, -%d HP tổng!" % [
				attacker.combatant_name, name, total])
			if total > 0:
				hit_landed.emit(target_is_player, total, false)

		"BUFF_ALL_STATS":
			# Cân Bằng — Balanced Stance: dmg_mult phủ ATK+Magic, def_bonus phủ DEF
			var turns: int   = skill.get("stat_bonus_turns", 2)
			var pct:   float = skill.get("stat_bonus_pct",   0.15)
			attacker.dmg_mult        = 1.0 + pct
			attacker.dmg_mult_turns  = turns
			attacker.def_bonus       = int(attacker.def_stat * pct)
			attacker.def_bonus_turns = turns
			_log("> %s dùng %s: +%.0f%% mọi stat trong %d lượt!" % [
				attacker.combatant_name, name, pct * 100.0, turns])

		"SHIELD_ONE_HIT":
			# Cứng Như Đá — Stone Form: chặn hoàn toàn 1 đòn kế tiếp
			attacker.shield_active = true
			_log("> %s dùng %s: sẵn sàng chặn 1 đòn!" % [
				attacker.combatant_name, name])

		"PASSIVE_NO_DURABILITY":
			# Trường Sinh — Eternal: hiệu ứng bị động, không cần kích hoạt thủ công
			# (Durability system chưa implement — skill này chỉ log thông báo)
			_log("> %s: Eternal đang hoạt động — không mất Durability trong trận." % \
				attacker.combatant_name)


# ══════════════════════════════════════════════════════════════════════════════
# WIN / LOSE DETECTION
# ══════════════════════════════════════════════════════════════════════════════

func _check_end() -> bool:
	if not enemy.is_alive():
		_finish("win", { "gold": enemy.drop_gold })
		return true
	if not player.is_alive():
		_finish("lose", {})
		return true
	return false


func _finish(result: String, data: Dictionary) -> void:
	_state = CombatState.ENDED
	state_changed.emit(CombatState.ENDED)
	EventBus.combat_ended.emit(result)
	combat_ended.emit(result, data)


# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _log(msg: String) -> void:
	action_logged.emit(msg)
