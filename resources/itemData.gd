class_name ItemData
extends Resource

enum ItemType { MATERIAL, ELEMENT, BLANK, CONSUMABLE, QUEST, RECIPE }

@export var item_id: String = ""
@export var item_name: String = ""
@export var item_type: ItemType
@export var description: String = ""
@export var rarity: int = 1
@export var base_value: int = 0
@export var icon: Texture2D
@export var effect_data: Dictionary = {}  # Flexible: tuỳ consumable
