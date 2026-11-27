# Đại diện một chiến binh trong combat — player hoặc enemy
class_name Combatant
extends RefCounted

var combatant_name: String = ""
var is_player:      bool   = false

# Live stats
var hp:          int = 50
var max_hp:      int = 50
var stamina:     int = 5
var max_stamina: int = 5
var atk:         int = 10
var def_stat:    int = 0
var magic:       int = 0
var speed:       int = 5

# Status effects (lượt còn lại)
var burn_turns:   int = 0
var burn_dmg:     int = 4
var freeze_turns: int = 0
var poison_turns: int = 0

# Buffs / debuffs có duration
var def_bonus:         int = 0
var def_bonus_turns:   int = 0
var atk_penalty:       int = 0
var atk_penalty_turns: int = 0
var dmg_mult:          float = 1.0
var dmg_mult_turns:    int   = 0

# Special flags
var shield_active:  bool  = false  # Chặn 1 đòn (Stone Form)
var lose_next_turn: bool  = false  # Mất lượt sau (Crushing Blow)

# Kháng chí mạng — trang bị sau này có thể tăng lên để giảm tỉ lệ nhận crit
var crit_resist: float = 0.0

# Skills của player (set từ vũ khí đang trang bị)
var skill1: Dictionary = {}
var skill2: Dictionary = {}


func take_damage(raw: int, ignore_def_pct: float = 0.0) -> int:
	if shield_active:
		shield_active = false
		return 0
	var eff_def: int     = max(0, def_stat + def_bonus)
	var eff_ignore: float = clampf(ignore_def_pct, 0.0, 1.0)
	var reduced_def: int = int(eff_def * (1.0 - eff_ignore))
	var actual: int      = max(1, raw - reduced_def)
	hp = max(0, hp - actual)
	return actual


func heal(amount: int) -> int:
	var before := hp
	hp = min(max_hp, hp + amount)
	return hp - before


func is_alive() -> bool:
	return hp > 0


func calc_raw_damage(mult: float, dice: int = 0) -> int:
	var eff_atk: int = max(0, atk - atk_penalty)  # atk_penalty trừ tại đây, không modify atk trực tiếp
	var base    := int(eff_atk * dmg_mult * mult)
	if dice > 0:
		base += randi_range(1, dice)
	return base


func calc_magic_damage(mult: float) -> int:
	return int(magic * dmg_mult * mult)


# Tick status effects cuối lượt — trả về mảng log messages
func tick_status() -> Array:
	var msgs: Array = []

	if burn_turns > 0:
		hp = max(0, hp - burn_dmg)
		msgs.append("%s bị Bỏng: -%d HP" % [combatant_name, burn_dmg])
		burn_turns -= 1
		if burn_turns == 0:
			msgs.append("Bỏng trên %s đã tắt." % combatant_name)
		if hp <= 0:
			return msgs

	if poison_turns > 0:
		var dmg: int = max(1, int(max_hp * 0.05))
		hp = max(0, hp - dmg)
		msgs.append("%s bị Độc: -%d HP" % [combatant_name, dmg])
		poison_turns -= 1

	return msgs


# Tick buff/debuff durations
func tick_buffs() -> void:
	if def_bonus_turns > 0:
		def_bonus_turns -= 1
		if def_bonus_turns == 0:
			def_bonus = 0

	if atk_penalty_turns > 0:
		atk_penalty_turns -= 1
		if atk_penalty_turns == 0:
			atk_penalty = 0

	if dmg_mult_turns > 0:
		dmg_mult_turns -= 1
		if dmg_mult_turns == 0:
			dmg_mult = 1.0


func status_summary() -> String:
	var parts: Array = []
	if burn_turns > 0:   parts.append("[Bỏng %d]" % burn_turns)
	if freeze_turns > 0: parts.append("[Băng %d]" % freeze_turns)
	if poison_turns > 0: parts.append("[Độc %d]" % poison_turns)
	if shield_active:    parts.append("[Khiên]")
	if def_bonus > 0:    parts.append("+%dDEF(%d)" % [def_bonus, def_bonus_turns])
	if atk_penalty > 0:  parts.append("-%dATK_địch(%d)" % [atk_penalty, atk_penalty_turns])
	return "  ".join(parts)
