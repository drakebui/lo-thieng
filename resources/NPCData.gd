class_name NPCData
extends Resource

enum NPCType { VIP, ANTAGONIST, RECURRING, REGULAR }

@export var npc_id: String = ""
@export var npc_name: String = ""
@export var npc_type: NPCType
@export var portrait: Texture2D
@export var budget_range: Vector2i = Vector2i(500, 1500)
@export var patience: int = 2
@export var preferred_weapon_tags: Array[String] = []
@export var disliked_weapon_tags: Array[String] = []
@export var affinity: int = 0
@export var schedule: Dictionary = {}  # {"region": "DongMay", "time": ["morning","afternoon"]}
