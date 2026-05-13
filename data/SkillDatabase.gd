# scripts/systems/SkillDatabase.gd
# Chứa toàn bộ 25 skills: 12 Prefix + 6 Suffix + 7 Universal
# Dùng: SkillDatabase.get_skill("ben_ngot")
#        SkillDatabase.get_all_prefix_skills()

class_name SkillDatabase
extends Node

# ─── Internal registry ────────────────────────────────────
static var _skills: Dictionary = {}
static var _initialized: bool = false

static func _init_if_needed() -> void:
	if _initialized:
		return
	_build_prefix_skills()
	_build_suffix_skills()
	_build_universal_skills()
	_initialized = true

# ─── Public API ───────────────────────────────────────────

static func get_skill(skill_id: String) -> SkillData:
	_init_if_needed()
	return _skills.get(skill_id, null)

static func get_all_prefix_skills() -> Array[SkillData]:
	_init_if_needed()
	var result: Array[SkillData] = []
	for s in _skills.values():
		if s.skill_source == SkillData.SkillSource.PREFIX:
			result.append(s)
	return result

static func get_all_suffix_skills() -> Array[SkillData]:
	_init_if_needed()
	var result: Array[SkillData] = []
	for s in _skills.values():
		if s.skill_source == SkillData.SkillSource.SUFFIX:
			result.append(s)
	return result

static func get_all_universal_skills() -> Array[SkillData]:
	_init_if_needed()
	var result: Array[SkillData] = []
	for s in _skills.values():
		if s.skill_source == SkillData.SkillSource.UNIVERSAL:
			result.append(s)
	return result

# ─── Helper ───────────────────────────────────────────────

static func _register(s: SkillData) -> void:
	_skills[s.skill_id] = s

static func _make() -> SkillData:
	return SkillData.new()


# ═══════════════════════════════════════════════════════════
# PREFIX SKILLS (12) — gắn với Phase 2 forge result
# ═══════════════════════════════════════════════════════════

static func _build_prefix_skills() -> void:

	# ── 1. Bén Ngọt — Slash ─────────────────────────────
	var s := _make()
	s.skill_id          = "ben_ngot"
	s.skill_name        = "Slash"
	s.skill_source      = SkillData.SkillSource.PREFIX
	s.effect_type       = SkillData.EffectType.DAMAGE
	s.stamina_cost      = 1
	s.damage_multiplier = 1.5   # +50% damage
	s.description       = "Chém nhanh, gây 150% sát thương thường."
	_register(s)

	# ── 2. Kiên Cố — Iron Wall ───────────────────────────
	s = _make()
	s.skill_id          = "kien_co"
	s.skill_name        = "Iron Wall"
	s.skill_source      = SkillData.SkillSource.PREFIX
	s.effect_type       = SkillData.EffectType.BUFF_SELF
	s.stamina_cost      = 1
	s.effect_value      = 5.0   # +5 DEF
	s.effect_duration   = 2
	s.description       = "Tăng 5 DEF trong 2 lượt."
	_register(s)

	# ── 3. Nặng Tay — Crushing Blow ──────────────────────
	s = _make()
	s.skill_id          = "nang_tay"
	s.skill_name        = "Crushing Blow"
	s.skill_source      = SkillData.SkillSource.PREFIX
	s.effect_type       = SkillData.EffectType.DAMAGE
	s.stamina_cost      = 2
	s.damage_multiplier = 2.0   # +100% damage
	s.lose_next_turn    = true
	s.description       = "Gây 200% sát thương, nhưng mất lượt tiếp theo."
	_register(s)

	# ── 4. Thần Tốc — Double Strike ──────────────────────
	s = _make()
	s.skill_id          = "than_toc"
	s.skill_name        = "Double Strike"
	s.skill_source      = SkillData.SkillSource.PREFIX
	s.effect_type       = SkillData.EffectType.DAMAGE_MULTI
	s.stamina_cost      = 2
	s.damage_multiplier = 1.0
	s.hit_count         = 2     # 2 lần đánh
	s.description       = "Đánh 2 lần liên tiếp, mỗi lần gây sát thương thường."
	_register(s)

	# ── 5. Kiệt Tác — Master's Form ──────────────────────
	s = _make()
	s.skill_id          = "kiet_tac"
	s.skill_name        = "Master's Form"
	s.skill_source      = SkillData.SkillSource.PREFIX
	s.effect_type       = SkillData.EffectType.DAMAGE
	s.stamina_cost      = 2
	s.damage_multiplier = 1.3   # +30% damage
	s.effect_value      = 10.0  # +10 HP heal
	s.description       = "Gây 130% sát thương và hồi 10 HP."
	_register(s)

	# ── 6. Cân Bằng — Balanced Stance ────────────────────
	s = _make()
	s.skill_id          = "can_bang"
	s.skill_name        = "Balanced Stance"
	s.skill_source      = SkillData.SkillSource.PREFIX
	s.effect_type       = SkillData.EffectType.BUFF_SELF
	s.stamina_cost      = 1
	s.effect_value      = 0.15  # +15% mọi stat
	s.effect_duration   = 2
	s.description       = "Tăng 15% tất cả chỉ số trong 2 lượt."
	_register(s)

	# ── 7. Tổ Nghề — Ancestral Echo ──────────────────────
	s = _make()
	s.skill_id          = "to_nghe"
	s.skill_name        = "Ancestral Echo"
	s.skill_source      = SkillData.SkillSource.PREFIX
	s.effect_type       = SkillData.EffectType.DAMAGE
	s.stamina_cost      = 1
	s.damage_multiplier = 1.25  # +25% damage
	s.bonus_gold_on_win = 50
	s.description       = "Gây 125% sát thương. Thưởng 50G nếu thắng trận."
	_register(s)

	# ── 8. Huyền Bí — Arcane Blade ───────────────────────
	s = _make()
	s.skill_id          = "huyen_bi"
	s.skill_name        = "Arcane Blade"
	s.skill_source      = SkillData.SkillSource.PREFIX
	s.effect_type       = SkillData.EffectType.DAMAGE_MAGIC
	s.stamina_cost      = 1
	s.damage_multiplier = 1.0   # Damage = Magic stat thay vì ATK
	s.description       = "Sát thương tính theo chỉ số Magic thay vì ATK."
	_register(s)

	# ── 9. Cứng Như Đá — Stone Form ──────────────────────
	s = _make()
	s.skill_id          = "cung_nhu_da"
	s.skill_name        = "Stone Form"
	s.skill_source      = SkillData.SkillSource.PREFIX
	s.effect_type       = SkillData.EffectType.SHIELD
	s.stamina_cost      = 2
	s.effect_value      = 1.0   # Chặn 1 đòn hoàn toàn
	s.description       = "Miễn nhiễm hoàn toàn với đòn tấn công tiếp theo."
	_register(s)

	# ── 10. Khí Phách — Heroic Shout ─────────────────────
	s = _make()
	s.skill_id          = "khi_phach"
	s.skill_name        = "Heroic Shout"
	s.skill_source      = SkillData.SkillSource.PREFIX
	s.effect_type       = SkillData.EffectType.DEBUFF_ENEMY
	s.stamina_cost      = 1
	s.effect_value      = 1.0   # -1 ATK enemy
	s.effect_duration   = 3
	s.description       = "Giảm 1 ATK của kẻ thù trong 3 lượt."
	_register(s)

	# ── 11. Trường Sinh — Eternal ─────────────────────────
	s = _make()
	s.skill_id          = "truong_sinh"
	s.skill_name        = "Eternal"
	s.skill_source      = SkillData.SkillSource.PREFIX
	s.effect_type       = SkillData.EffectType.SPECIAL
	s.stamina_cost      = 0
	s.description       = "Vũ khí không mất Durability trong suốt trận chiến."
	_register(s)

	# ── 12. Hào Kiệt — Hero's Edge ───────────────────────
	s = _make()
	s.skill_id              = "hao_kiet"
	s.skill_name            = "Hero's Edge"
	s.skill_source          = SkillData.SkillSource.PREFIX
	s.effect_type           = SkillData.EffectType.DAMAGE
	s.stamina_cost          = 2
	s.damage_multiplier     = 1.5   # +50% damage
	s.bonus_reputation_on_win = 1
	s.description           = "Gây 150% sát thương. +1 Reputation nếu thắng trận."
	_register(s)


# ═══════════════════════════════════════════════════════════
# SUFFIX SKILLS (6) — từ nguyên tố Linh Lực Phase 3
# ═══════════════════════════════════════════════════════════

static func _build_suffix_skills() -> void:

	# ── 1. Hỏa — Burn ────────────────────────────────────
	var s := _make()
	s.skill_id        = "suffix_hoa"
	s.skill_name      = "Burn"
	s.skill_source    = SkillData.SkillSource.SUFFIX
	s.effect_type     = SkillData.EffectType.STATUS_BURN
	s.stamina_cost    = 2
	s.damage_multiplier = 1.0
	s.effect_value    = 4.0  # 4 damage/turn
	s.effect_duration = 2
	s.description     = "Gây sát thương Lửa + Burn 2 lượt (4 sát thương/lượt)."
	_register(s)

	# ── 2. Băng — Freeze ─────────────────────────────────
	s = _make()
	s.skill_id        = "suffix_bang"
	s.skill_name      = "Freeze"
	s.skill_source    = SkillData.SkillSource.SUFFIX
	s.effect_type     = SkillData.EffectType.STATUS_FREEZE
	s.stamina_cost    = 2
	s.damage_multiplier = 1.0
	s.effect_chance   = 0.5   # 50% chance miss turn
	s.effect_duration = 1
	s.description     = "Gây sát thương Băng + 50% cơ hội kẻ thù mất lượt."
	_register(s)

	# ── 3. Sét — Chain Lightning ──────────────────────────
	s = _make()
	s.skill_id             = "suffix_set"
	s.skill_name           = "Chain Lightning"
	s.skill_source         = SkillData.SkillSource.SUFFIX
	s.effect_type          = SkillData.EffectType.DAMAGE_IGNORE_DEF
	s.stamina_cost         = 2
	s.damage_multiplier    = 1.0
	s.ignore_def_percent   = 0.5   # Bỏ qua 50% DEF
	s.description          = "Gây sát thương Sét, xuyên qua 50% DEF của kẻ thù."
	_register(s)

	# ── 4. Độc — Poison Cloud ─────────────────────────────
	s = _make()
	s.skill_id        = "suffix_doc"
	s.skill_name      = "Poison Cloud"
	s.skill_source    = SkillData.SkillSource.SUFFIX
	s.effect_type     = SkillData.EffectType.STATUS_POISON
	s.stamina_cost    = 1
	s.damage_multiplier = 0.0   # Không gây direct damage
	s.effect_value    = 0.05    # 5% max HP mỗi lượt
	s.effect_duration = 99      # Cho đến khi cleanse
	s.description     = "Tích tụ Độc. Kẻ thù mất 5% HP tối đa mỗi lượt."
	_register(s)

	# ── 5. Thánh — Heal Pulse ─────────────────────────────
	s = _make()
	s.skill_id        = "suffix_thanh"
	s.skill_name      = "Heal Pulse"
	s.skill_source    = SkillData.SkillSource.SUFFIX
	s.effect_type     = SkillData.EffectType.HEAL
	s.stamina_cost    = 2
	s.effect_value    = 0.30    # Hồi 30% max HP
	s.description     = "Hồi 30% HP tối đa và xóa 1 debuff đang tác động."
	_register(s)

	# ── 6. Bóng Tối — Shadow Strike ───────────────────────
	s = _make()
	s.skill_id             = "suffix_bong_toi"
	s.skill_name           = "Shadow Strike"
	s.skill_source         = SkillData.SkillSource.SUFFIX
	s.effect_type          = SkillData.EffectType.DAMAGE_IGNORE_DEF
	s.stamina_cost         = 2
	s.damage_multiplier    = 1.0
	s.ignore_def_percent   = 1.0   # Ignore 100% DEF nếu enemy không có Holy
	s.description          = "Xuyên thấu 100% DEF, trừ khi kẻ thù có thuộc tính Thánh."
	_register(s)


# ═══════════════════════════════════════════════════════════
# UNIVERSAL SKILLS (7) — mở khóa qua progression
# ═══════════════════════════════════════════════════════════

static func _build_universal_skills() -> void:

	# ── 1. Stance Switch ──────────────────────────────────
	var s := _make()
	s.skill_id                = "stance_switch"
	s.skill_name              = "Stance Switch"
	s.skill_source            = SkillData.SkillSource.UNIVERSAL
	s.effect_type             = SkillData.EffectType.SPECIAL
	s.stamina_cost            = 0
	s.unlock_condition        = "day_5"
	s.is_unlocked_by_default  = false
	s.description             = "Đổi 2 vũ khí trong 1 lượt thay vì mất lượt."
	_register(s)

	# ── 2. Forge Sense ────────────────────────────────────
	s = _make()
	s.skill_id                = "forge_sense"
	s.skill_name              = "Forge Sense"
	s.skill_source            = SkillData.SkillSource.UNIVERSAL
	s.effect_type             = SkillData.EffectType.SPECIAL
	s.stamina_cost            = 0
	s.unlock_condition        = "day_8"
	s.is_unlocked_by_default  = false
	s.description             = "Xem tất cả chỉ số ẩn của kẻ thù."
	_register(s)

	# ── 3. Ancestral Bond ─────────────────────────────────
	s = _make()
	s.skill_id                = "ancestral_bond"
	s.skill_name              = "Ancestral Bond"
	s.skill_source            = SkillData.SkillSource.UNIVERSAL
	s.effect_type             = SkillData.EffectType.BUFF_SELF
	s.stamina_cost            = 0
	s.unlock_condition        = "mastery_first"
	s.is_unlocked_by_default  = false
	s.description             = "Vũ khí Mastery giảm 1 Stamina chi phí kỹ năng."
	_register(s)

	# ── 4. Smith's Wisdom ─────────────────────────────────
	s = _make()
	s.skill_id                = "smiths_wisdom"
	s.skill_name              = "Smith's Wisdom"
	s.skill_source            = SkillData.SkillSource.UNIVERSAL
	s.effect_type             = SkillData.EffectType.BUFF_SELF
	s.stamina_cost            = 0
	s.effect_value            = 1.0   # +1 max Stamina
	s.unlock_condition        = "reputation_5"
	s.is_unlocked_by_default  = false
	s.description             = "Tăng vĩnh viễn 1 Stamina tối đa."
	_register(s)

	# ── 5. Endurance ──────────────────────────────────────
	s = _make()
	s.skill_id                = "endurance"
	s.skill_name              = "Endurance"
	s.skill_source            = SkillData.SkillSource.UNIVERSAL
	s.effect_type             = SkillData.EffectType.BUFF_SELF
	s.stamina_cost            = 0
	s.effect_value            = 20.0  # +20 max HP
	s.unlock_condition        = "reputation_7"
	s.is_unlocked_by_default  = false
	s.description             = "Tăng vĩnh viễn 20 HP tối đa."
	_register(s)

	# ── 6. Counter ────────────────────────────────────────
	s = _make()
	s.skill_id                = "counter"
	s.skill_name              = "Counter"
	s.skill_source            = SkillData.SkillSource.UNIVERSAL
	s.effect_type             = SkillData.EffectType.SPECIAL
	s.stamina_cost            = 0
	s.unlock_condition        = "artifact_5"
	s.is_unlocked_by_default  = false
	s.description             = "Tự động phản đòn nếu DEF vượt quá ATK của kẻ thù."
	_register(s)

	# ── 7. Last Stand ─────────────────────────────────────
	s = _make()
	s.skill_id                = "last_stand"
	s.skill_name              = "Last Stand"
	s.skill_source            = SkillData.SkillSource.UNIVERSAL
	s.effect_type             = SkillData.EffectType.SPECIAL
	s.stamina_cost            = 0
	s.effect_value            = 1.5   # × 1.5 damage khi HP < 20%
	s.unlock_condition        = "artifact_10"
	s.is_unlocked_by_default  = false
	s.description             = "Khi HP dưới 20%, tăng 50% sát thương gây ra."
	_register(s)
