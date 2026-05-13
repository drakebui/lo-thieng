class_name StatusEffect
extends Resource

## Các loại status effect trong combat — theo GDD Section 5.3
enum Type {
	BURN,       # Cháy: 4 dmg/lượt × 2 lượt (Suffix Hỏa)
	FREEZE,     # Băng Giá: 50% bỏ lượt × 1 lượt (Suffix Băng)
	POISON,     # Độc: 5% HP tối đa/lượt, stackable (Suffix Độc)
	DEF_UP,     # Phòng Thủ Tăng: +flat DEF N lượt (Prefix Kiên Cố)
	ATK_DOWN,   # Tấn Công Giảm: -flat ATK N lượt (Prefix Khí Phách)
	STATS_UP,   # Toàn Stat Tăng: +% mọi stat N lượt (Prefix Cân Bằng)
	SKIP_TURN,  # Mất Lượt: bỏ lượt kế tiếp (Prefix Nặng Tay)
}

# Hằng số theo GDD Section 5.3
const BURN_DAMAGE: int = 4
const BURN_DURATION: int = 2
const POISON_HP_PERCENT: float = 0.05   # 5% HP tối đa mỗi stack mỗi lượt
const POISON_DEFAULT_DURATION: int = 3
const FREEZE_MISS_CHANCE: float = 0.5   # 50%
const FREEZE_DURATION: int = 1

@export var type: Type
@export var duration: int = 0       # số lượt còn hiệu lực
@export var stacks: int = 1         # chỉ Poison dùng nhiều stack
@export var flat_value: float = 0.0  # giá trị flat (DEF, ATK)
@export var percent_value: float = 0.0  # giá trị % (STATS_UP)


# --- Factory methods ---

static func create_burn() -> StatusEffect:
	var e := StatusEffect.new()
	e.type = Type.BURN
	e.duration = BURN_DURATION
	return e


static func create_freeze() -> StatusEffect:
	var e := StatusEffect.new()
	e.type = Type.FREEZE
	e.duration = FREEZE_DURATION
	return e


static func create_poison() -> StatusEffect:
	var e := StatusEffect.new()
	e.type = Type.POISON
	e.duration = POISON_DEFAULT_DURATION
	e.stacks = 1
	return e


static func create_def_up(amount: int, turns: int) -> StatusEffect:
	var e := StatusEffect.new()
	e.type = Type.DEF_UP
	e.duration = turns
	e.flat_value = amount
	return e


static func create_atk_down(amount: int, turns: int) -> StatusEffect:
	var e := StatusEffect.new()
	e.type = Type.ATK_DOWN
	e.duration = turns
	e.flat_value = amount
	return e


static func create_stats_up(percent: float, turns: int) -> StatusEffect:
	var e := StatusEffect.new()
	e.type = Type.STATS_UP
	e.duration = turns
	e.percent_value = percent
	return e


static func create_skip_turn() -> StatusEffect:
	var e := StatusEffect.new()
	e.type = Type.SKIP_TURN
	e.duration = 1
	return e


# --- Queries ---

func get_display_name() -> String:
	match type:
		Type.BURN: return "Cháy"
		Type.FREEZE: return "Băng Giá"
		Type.POISON: return "Độc"
		Type.DEF_UP: return "Phòng Thủ Tăng"
		Type.ATK_DOWN: return "Tấn Công Giảm"
		Type.STATS_UP: return "Toàn Stat Tăng"
		Type.SKIP_TURN: return "Mất Lượt"
	return ""


func is_debuff() -> bool:
	return type in [Type.BURN, Type.FREEZE, Type.POISON, Type.ATK_DOWN, Type.SKIP_TURN]


func is_expired() -> bool:
	return duration <= 0


# --- Tick logic (gọi vào cuối lượt của target) ---

## Tính damage tick. Trả về lượng HP mất (dương = mất HP).
func calculate_tick_damage(target_max_hp: int) -> int:
	match type:
		Type.BURN:
			return BURN_DAMAGE
		Type.POISON:
			# Mỗi stack thêm 5% HP tối đa — stackable theo GDD
			return int(target_max_hp * POISON_HP_PERCENT * stacks)
	return 0


## Freeze: 50% chance bỏ lượt. Gọi vào đầu lượt của target khi bị Freeze.
func roll_freeze_skip() -> bool:
	if type != Type.FREEZE:
		return false
	return randf() < FREEZE_MISS_CHANCE


## Giảm duration 1 lượt. Trả về true nếu effect vừa hết hạn.
func tick_duration() -> bool:
	duration -= 1
	return duration <= 0


## Stack thêm 1 cho Poison (khi bị cast lại lên target đang có Poison).
func add_stack() -> void:
	if type == Type.POISON:
		stacks += 1


## Stat modifier để CombatManager tính stat thực tế khi có buff/debuff.
## Keys: "def", "atk", "atk_pct", "def_pct", "magic_pct", "speed_pct"
func get_stat_modifiers() -> Dictionary:
	match type:
		Type.DEF_UP:
			return {"def": flat_value}
		Type.ATK_DOWN:
			return {"atk": -flat_value}
		Type.STATS_UP:
			return {
				"atk_pct": percent_value,
				"def_pct": percent_value,
				"magic_pct": percent_value,
				"speed_pct": percent_value,
			}
	return {}
