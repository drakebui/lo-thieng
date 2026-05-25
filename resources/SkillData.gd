class_name SkillData
extends Resource

enum SkillSource { PREFIX, SUFFIX, UNIVERSAL }

enum EffectType {
	DAMAGE,           # Gây damage thường
	DAMAGE_MAGIC,     # Damage = Magic stat (Arcane Blade)
	DAMAGE_IGNORE_DEF,# Ignore % DEF (Chain Lightning)
	DAMAGE_MULTI,     # Đánh nhiều lần (Double Strike)
	BUFF_SELF,        # Buff stat bản thân
	BUFF_TEAM,        # Không dùng v1.0
	DEBUFF_ENEMY,     # Giảm stat enemy
	HEAL,             # Hồi HP
	STATUS_BURN,      # Gây Burn (damage/turn)
	STATUS_FREEZE,    # Gây Freeze (miss chance)
	STATUS_POISON,    # Gây Poison (% HP/turn)
	SHIELD,           # Chặn 1 đòn
	CLEANSE,          # Xóa debuff
	ESCAPE,           # Thoát combat
	SPECIAL,          # Effect đặc biệt (Tổ Nghề, Hào Kiệt)
}

@export var skill_id: String = ""
@export var skill_name: String = ""
@export var skill_source: SkillSource = SkillSource.PREFIX
@export var effect_type: EffectType = EffectType.DAMAGE
@export var effect: String = "DAMAGE"

# Cost & Power
@export var stamina_cost: int = 1
@export var damage_multiplier: float = 1.0   # 1.5 = +50% damage
@export var damage_mult: float = 1.0
@export var dice: int = 0
@export var effect_value: float = 0.0        # Heal amount, debuff value, status damage...
@export var effect_duration: int = 0         # Số lượt buff/debuff/status tồn tại
@export var effect_chance: float = 1.0       # 0.0-1.0 (Freeze = 0.5 = 50% chance)
@export var heal_flat: int = 0

# Special flags
@export var ignore_def_percent: float = 0.0  # 0.5 = ignore 50% DEF
@export var ignore_def: float = 0.0
@export var hit_count: int = 1               # Double Strike = 2
@export var lose_next_turn: bool = false     # Crushing Blow
@export var use_magic: bool = false
@export var magic_mult: float = 1.0
@export var status: String = ""
@export var status_turns: int = 0
@export var status_dmg: int = 0
@export var def_bonus: int = 0
@export var def_bonus_turns: int = 0
@export var atk_penalty: int = 0
@export var atk_penalty_turns: int = 0
@export var stat_bonus_pct: float = 0.0
@export var stat_bonus_turns: int = 0

# Bonus effects (Tổ Nghề, Hào Kiệt)
@export var bonus_gold_on_win: int = 0       # Tổ Nghề: +50G khi thắng
@export var bonus_reputation_on_win: int = 0 # Hào Kiệt: +1 Reputation

# Unlock
@export var unlock_condition: String = ""    # "day_5", "reputation_5", "mastery_first", etc.
@export var is_unlocked_by_default: bool = true

# Display
@export var description: String = ""
@export var icon: Texture2D
