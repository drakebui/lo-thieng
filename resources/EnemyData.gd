class_name EnemyData
extends Resource

@export var enemy_id:   String = ""
@export var enemy_name: String = ""
@export var archetype:  String = "aggressive"  # "aggressive" | "defensive" | "caster" | "boss"
@export var tier:       int    = 1
@export var hp:         int    = 30
@export var atk:        int    = 8
@export var def_stat:   int    = 0
@export var magic:      int    = 0
@export var speed:      int    = 5
@export var drop_gold:  int    = 30
@export var color:      Color  = Color(0.55, 0.25, 0.12)
@export var region:     String = ""
@export var crit_rate:  float  = 0.15  # tỉ lệ ra đòn chí mạng (giảm bởi player crit_resist)
@export var loot_items: Array[Dictionary] = [] # Mỗi phần tử: { "item_id": String, "chance": float }

# Chuyển EnemyData sang Dictionary để dùng với EnemyCombatUnit.from_template()
func to_template() -> Dictionary:
	return {
		"name":      enemy_name,
		"archetype": archetype,
		"hp":        hp,
		"atk":       atk,
		"def_stat":  def_stat,
		"magic":     magic,
		"speed":     speed,
		"color":     color,
		"drop_gold": drop_gold,
		"crit_rate": crit_rate,
		"loot_items": loot_items,
	}
