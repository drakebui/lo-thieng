# scripts/combat/skill_executor.gd
# Nhận SkillData resource + attacker/target Combatant, resolve effect, trả về result.
# Không emit signal, không đụng UI — combat_manager dùng result để log và emit.
#
# Result dict:
#   "dmg"       : int     — HP target mất (0 nếu shield block)
#   "heal"      : int     — HP attacker hồi
#   "log"       : String  — dòng log hiển thị trong combat
#   "hit"       : bool    — có gây damage thực sự không (để emit hit_landed)
#   "status"    : String  — "burn" | "freeze" | "poison" | ""
#   "escaped"   : bool    — true nếu ESCAPE effect
#   "bonus_gold": int     — thưởng vàng khi thắng (Tổ Nghề)
#   "bonus_rep" : int     — thưởng reputation khi thắng (Hào Kiệt)
class_name SkillExecutor
extends RefCounted


static func execute(skill: SkillData, attacker: Combatant, target: Combatant) -> Dictionary:
	var r := _empty_result()

	match skill.effect_type:
		SkillData.EffectType.DAMAGE:
			r = _do_damage(skill, attacker, target, r)
		SkillData.EffectType.DAMAGE_MAGIC:
			r = _do_damage_magic(skill, attacker, target, r)
		SkillData.EffectType.DAMAGE_IGNORE_DEF:
			r = _do_damage_ignore_def(skill, attacker, target, r)
		SkillData.EffectType.DAMAGE_MULTI:
			r = _do_damage_multi(skill, attacker, target, r)
		SkillData.EffectType.BUFF_SELF:
			r = _do_buff_self(skill, attacker, r)
		SkillData.EffectType.DEBUFF_ENEMY:
			r = _do_debuff_enemy(skill, target, attacker, r)
		SkillData.EffectType.HEAL:
			r = _do_heal(skill, attacker, r)
		SkillData.EffectType.STATUS_BURN:
			r = _do_status_burn(skill, attacker, target, r)
		SkillData.EffectType.STATUS_FREEZE:
			r = _do_status_freeze(skill, attacker, target, r)
		SkillData.EffectType.STATUS_POISON:
			r = _do_status_poison(skill, attacker, target, r)
		SkillData.EffectType.SHIELD:
			r = _do_shield(skill, attacker, r)
		SkillData.EffectType.CLEANSE:
			r = _do_cleanse(skill, attacker, r)
		SkillData.EffectType.ESCAPE:
			r["escaped"] = true
			r["log"] = "> %s bỏ chạy khỏi trận!" % attacker.combatant_name
		SkillData.EffectType.SPECIAL:
			r = _do_special(skill, attacker, target, r)

	r["bonus_gold"] = skill.bonus_gold_on_win
	r["bonus_rep"]  = skill.bonus_reputation_on_win
	return r


# ══════════════════════════════════════════════════════════════════════════════
# EFFECT HANDLERS
# ══════════════════════════════════════════════════════════════════════════════

# DAMAGE — sát thương ATK × multiplier. Nếu effect_value > 0 → cũng hồi HP.
static func _do_damage(
		skill: SkillData, attacker: Combatant,
		target: Combatant, r: Dictionary) -> Dictionary:
	var raw    := attacker.calc_raw_damage(skill.damage_multiplier)
	var actual := target.take_damage(raw)
	r["dmg"] = actual
	r["hit"] = actual > 0
	r["log"] = "> %s dùng %s: %s" % [attacker.combatant_name, skill.skill_name, _dmg_text(actual)]

	if skill.lose_next_turn:
		attacker.lose_next_turn = true
		r["log"] += " (mất lượt tiếp theo!)"

	# Combo heal (Master's Form: effect_value = 10 flat HP)
	if skill.effect_value > 0.0:
		var healed := attacker.heal(int(skill.effect_value))
		r["heal"] = healed
		r["log"] += " / +%d HP" % healed

	return r


# DAMAGE_MAGIC — sát thương tính theo Magic stat thay vì ATK (Arcane Blade).
static func _do_damage_magic(
		skill: SkillData, attacker: Combatant,
		target: Combatant, r: Dictionary) -> Dictionary:
	var raw    := attacker.calc_magic_damage(skill.damage_multiplier)
	var actual := target.take_damage(raw)
	r["dmg"] = actual
	r["hit"] = actual > 0
	r["log"] = "> %s dùng %s (Magic): %s" % [
		attacker.combatant_name, skill.skill_name, _dmg_text(actual)
	]
	return r


# DAMAGE_IGNORE_DEF — xuyên qua X% DEF (Chain Lightning 50%, Shadow Strike 100%).
static func _do_damage_ignore_def(
		skill: SkillData, attacker: Combatant,
		target: Combatant, r: Dictionary) -> Dictionary:
	var raw    := attacker.calc_raw_damage(skill.damage_multiplier)
	var actual := target.take_damage(raw, skill.ignore_def_percent)
	r["dmg"] = actual
	r["hit"] = actual > 0
	r["log"] = "> %s dùng %s (xuyên %d%% DEF): %s" % [
		attacker.combatant_name, skill.skill_name,
		int(skill.ignore_def_percent * 100), _dmg_text(actual)
	]
	return r


# DAMAGE_MULTI — đánh nhiều lần (Double Strike = 2 lần). Shield chặn lần đầu.
static func _do_damage_multi(
		skill: SkillData, attacker: Combatant,
		target: Combatant, r: Dictionary) -> Dictionary:
	var total  := 0
	var hits: int = max(1, skill.hit_count)
	for _i in hits:
		var raw    := attacker.calc_raw_damage(skill.damage_multiplier)
		var actual := target.take_damage(raw)
		total += actual
		if actual > 0:
			r["hit"] = true
	r["dmg"] = total
	r["log"] = "> %s dùng %s (%d lần): -%d HP tổng" % [
		attacker.combatant_name, skill.skill_name, hits, total
	]
	return r


# BUFF_SELF — tăng stat bản thân.
# Convention: effect_value >= 1.0 → flat DEF bonus (Iron Wall: +5 DEF 2 lượt)
#             effect_value <  1.0 → damage multiplier  (Balanced Stance: +15% dmg)
static func _do_buff_self(skill: SkillData, attacker: Combatant, r: Dictionary) -> Dictionary:
	if skill.effect_value >= 1.0:
		attacker.def_bonus       = int(skill.effect_value)
		attacker.def_bonus_turns = max(1, skill.effect_duration)
		r["log"] = "> %s dùng %s: +%d DEF trong %d lượt!" % [
			attacker.combatant_name, skill.skill_name,
			int(skill.effect_value), skill.effect_duration
		]
	else:
		attacker.dmg_mult       = 1.0 + skill.effect_value
		attacker.dmg_mult_turns = max(1, skill.effect_duration)
		r["log"] = "> %s dùng %s: +%d%% sát thương trong %d lượt!" % [
			attacker.combatant_name, skill.skill_name,
			int(skill.effect_value * 100), skill.effect_duration
		]
	return r


# DEBUFF_ENEMY — giảm ATK kẻ thù (Heroic Shout: -1 ATK 3 lượt).
static func _do_debuff_enemy(
		skill: SkillData, target: Combatant,
		attacker: Combatant, r: Dictionary) -> Dictionary:
	var penalty := int(skill.effect_value)
	target.atk_penalty       = penalty
	target.atk_penalty_turns = max(1, skill.effect_duration)
	target.atk               = max(0, target.atk - penalty)
	r["log"] = "> %s dùng %s: -%d ATK của %s trong %d lượt!" % [
		attacker.combatant_name, skill.skill_name,
		penalty, target.combatant_name, skill.effect_duration
	]
	return r


# HEAL — hồi HP. effect_value >= 1 → flat HP; < 1 → % max HP.
# Heal Pulse cũng tự động cleanse 1 debuff.
static func _do_heal(skill: SkillData, attacker: Combatant, r: Dictionary) -> Dictionary:
	var amount: int
	if skill.effect_value >= 1.0:
		amount = int(skill.effect_value)
	else:
		amount = int(attacker.max_hp * skill.effect_value)
	var healed   := attacker.heal(amount)
	var cleansed := _cleanse_one(attacker)
	r["heal"] = healed
	r["log"] = "> %s dùng %s: +%d HP" % [attacker.combatant_name, skill.skill_name, healed]
	if cleansed:
		r["log"] += " + xóa 1 debuff!"
	return r


# STATUS_BURN — gây damage + Burn X lượt (4 dmg/lượt từ effect_value).
static func _do_status_burn(
		skill: SkillData, attacker: Combatant,
		target: Combatant, r: Dictionary) -> Dictionary:
	var raw    := attacker.calc_raw_damage(skill.damage_multiplier)
	var actual := target.take_damage(raw)
	target.burn_turns = max(1, skill.effect_duration)
	target.burn_dmg   = int(skill.effect_value)
	r["dmg"]    = actual
	r["hit"]    = actual > 0
	r["status"] = "burn"
	r["log"] = "> %s dùng %s: %s + Bỏng %d lượt (%d dmg/lượt)!" % [
		attacker.combatant_name, skill.skill_name,
		_dmg_text(actual), skill.effect_duration, int(skill.effect_value)
	]
	return r


# STATUS_FREEZE — gây damage + Freeze (effect_chance % mất lượt tiếp theo).
static func _do_status_freeze(
		skill: SkillData, attacker: Combatant,
		target: Combatant, r: Dictionary) -> Dictionary:
	var raw    := attacker.calc_raw_damage(skill.damage_multiplier)
	var actual := target.take_damage(raw)
	r["dmg"] = actual
	r["hit"] = actual > 0
	r["log"] = "> %s dùng %s: %s" % [attacker.combatant_name, skill.skill_name, _dmg_text(actual)]
	if randf() <= skill.effect_chance:
		target.freeze_turns = max(1, skill.effect_duration)
		r["status"] = "freeze"
		r["log"] += " + Đóng Băng!"
	return r


# STATUS_POISON — tích tụ Độc (5% max HP/lượt, bền đến khi cleanse).
# Poison Cloud (damage_multiplier = 0) không gây direct damage.
static func _do_status_poison(
		skill: SkillData, attacker: Combatant,
		target: Combatant, r: Dictionary) -> Dictionary:
	if skill.damage_multiplier > 0.0:
		var raw    := attacker.calc_raw_damage(skill.damage_multiplier)
		var actual := target.take_damage(raw)
		r["dmg"] = actual
		r["hit"] = actual > 0
	target.poison_turns = max(1, skill.effect_duration)
	r["status"] = "poison"
	r["log"] = "> %s dùng %s: Độc tích tụ (%.0f%% HP/lượt)!" % [
		attacker.combatant_name, skill.skill_name, skill.effect_value * 100.0
	]
	return r


# SHIELD — Stone Form: chặn 1 đòn hoàn toàn.
static func _do_shield(skill: SkillData, attacker: Combatant, r: Dictionary) -> Dictionary:
	attacker.shield_active = true
	r["log"] = "> %s dùng %s: Miễn nhiễm đòn tiếp theo!" % [attacker.combatant_name, skill.skill_name]
	return r


# CLEANSE — xóa toàn bộ status effect đang tác động lên bản thân.
static func _do_cleanse(skill: SkillData, attacker: Combatant, r: Dictionary) -> Dictionary:
	_cleanse_all(attacker)
	r["log"] = "> %s dùng %s: Xóa toàn bộ debuff!" % [attacker.combatant_name, skill.skill_name]
	return r


# SPECIAL — effect đặc biệt, xử lý theo skill_id.
static func _do_special(
		skill: SkillData, attacker: Combatant,
		_target: Combatant, r: Dictionary) -> Dictionary:
	match skill.skill_id:
		"last_stand":
			# Khi HP < 20%: boost ×1.5 damage lượt này
			if float(attacker.hp) / float(attacker.max_hp) < 0.20:
				attacker.dmg_mult       = skill.effect_value  # 1.5
				attacker.dmg_mult_turns = 1
				r["log"] = "> %s kích hoạt %s: +50%% sát thương lượt này!" % [
					attacker.combatant_name, skill.skill_name
				]
			else:
				r["log"] = "> %s: %s chưa kích hoạt (cần HP < 20%%)." % [
					attacker.combatant_name, skill.skill_name
				]
		"truong_sinh":
			# Eternal — không có combat effect, chỉ bảo vệ durability (forge system)
			r["log"] = "> %s: %s đang bảo vệ vũ khí khỏi mài mòn." % [
				attacker.combatant_name, skill.skill_name
			]
		_:
			r["log"] = "> %s dùng %s." % [attacker.combatant_name, skill.skill_name]
	return r


# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

static func _empty_result() -> Dictionary:
	return {
		"dmg": 0, "heal": 0, "log": "", "hit": false,
		"status": "", "escaped": false, "bonus_gold": 0, "bonus_rep": 0,
	}


static func _dmg_text(actual: int) -> String:
	return "chặn bởi khiên!" if actual == 0 else "-%d HP" % actual


# Xóa status effect đầu tiên tìm thấy (dùng cho Heal Pulse cleanse 1 debuff).
static func _cleanse_one(c: Combatant) -> bool:
	if c.burn_turns > 0:
		c.burn_turns = 0
		return true
	if c.poison_turns > 0:
		c.poison_turns = 0
		return true
	if c.freeze_turns > 0:
		c.freeze_turns = 0
		return true
	if c.atk_penalty_turns > 0:
		c.atk_penalty       = 0
		c.atk_penalty_turns = 0
		return true
	return false


# Xóa toàn bộ status + debuff (dùng cho Cleanse skill).
static func _cleanse_all(c: Combatant) -> void:
	c.burn_turns        = 0
	c.poison_turns      = 0
	c.freeze_turns      = 0
	c.atk_penalty       = 0
	c.atk_penalty_turns = 0
