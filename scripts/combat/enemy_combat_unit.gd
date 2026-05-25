# enemy_combat_unit.gd
# Mở rộng Combatant với các field đặc thù cho enemy: archetype, drop_gold, color.
# Dùng from_template() để tạo nhanh từ Dictionary template.
class_name EnemyCombatUnit
extends Combatant

# ══════════════════════════════════════════════════════════════════════════════
# ENEMY-SPECIFIC FIELDS
# ══════════════════════════════════════════════════════════════════════════════

# AI archetype quyết định behavior — xem enemy_ai.gd
# Giá trị hợp lệ: "aggressive" | "defensive" | "caster" | "boss"
var archetype: String = "aggressive"

# Vàng nhận được khi player thắng trận
var drop_gold: int = 30

# Màu tint sprite trong combat_scene (dùng ColorRect mock)
var color: Color = Color(0.55, 0.25, 0.12)

# Tỉ lệ ra đòn chí mạng (0.0–1.0). Giảm bởi player.crit_resist.
# aggressive ≈ 0.25, caster ≈ 0.20, defensive ≈ 0.10, boss ≈ 0.30
var crit_rate: float = 0.15

# ══════════════════════════════════════════════════════════════════════════════
# FACTORY
# ══════════════════════════════════════════════════════════════════════════════

# Tạo EnemyCombatUnit từ template Dictionary.
# Template format (xem EnemyData.to_template()):
#   "name"      : String
#   "archetype" : String  — "aggressive" | "defensive" | "caster" | "boss"
#   "hp"        : int
#   "atk"       : int
#   "def_stat"  : int
#   "magic"     : int
#   "speed"     : int
#   "color"     : Color
#   "drop_gold" : int
static func from_template(tmpl: Dictionary) -> EnemyCombatUnit:
	var e            := EnemyCombatUnit.new()
	e.combatant_name  = tmpl.get("name",      "Kẻ Địch")
	var base_hp: int  = tmpl.get("hp",         30)
	e.hp              = base_hp
	e.max_hp          = base_hp
	e.atk             = tmpl.get("atk",         8)
	e.def_stat        = tmpl.get("def_stat",    0)
	e.magic           = tmpl.get("magic",       0)
	e.speed           = tmpl.get("speed",       5)
	e.archetype       = tmpl.get("archetype",  "aggressive")
	e.drop_gold       = tmpl.get("drop_gold",  30)
	e.color           = tmpl.get("color",      Color(0.55, 0.25, 0.12))
	e.crit_rate       = tmpl.get("crit_rate",  0.15)
	return e
