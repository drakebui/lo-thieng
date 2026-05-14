# scripts/autoload/InventorySystem.gd
extends Node

signal weapon_added(weapon: Dictionary)
signal material_added(mat: Dictionary)
signal shelf_updated()

const MAX_SHELF_SLOTS := 3

var weapons: Array[Dictionary] = []
var shelf_weapons: Array[Dictionary] = []  # Max 3 slot — dùng cho tiệm
# TODO: Persist materials qua SaveSystem khi có yêu cầu save/load kho vật liệu.
var materials: Array[Dictionary] = []

func add_weapon(weapon: Dictionary) -> void:
	weapons.append(weapon)
	weapon_added.emit(weapon)

func add_material(mat: Dictionary) -> void:
	materials.append(mat)
	material_added.emit(mat)

func add_trade_offer(trade_offer: Dictionary) -> void:
	match trade_offer.get("type", ""):
		"material":
			var amount: int = maxi(1, int(trade_offer.get("amount", 1)))
			for _i in amount:
				add_material(_trade_offer_to_material(trade_offer))
		"item":
			add_weapon(_trade_offer_to_weapon(trade_offer))

func set_materials(new_materials: Array) -> void:
	materials.clear()
	for mat in new_materials:
		if mat is Dictionary:
			var material_dict: Dictionary = mat
			materials.append(material_dict)

func remove_material(mat: Dictionary) -> void:
	materials.erase(mat)

func get_materials() -> Array[Dictionary]:
	return materials

func has_material(item_id: String) -> bool:
	for mat in materials:
		if mat.get("item_id", "") == item_id:
			return true
	return false

func get_weapons() -> Array[Dictionary]:
	return weapons

func move_to_shelf(weapon: Dictionary) -> bool:
	if shelf_weapons.size() >= MAX_SHELF_SLOTS:
		return false
	if weapon not in weapons:
		return false
	weapons.erase(weapon)
	shelf_weapons.append(weapon)
	shelf_updated.emit()
	return true

func remove_from_shelf(weapon: Dictionary) -> void:
	shelf_weapons.erase(weapon)
	weapons.append(weapon)
	shelf_updated.emit()

func sell_weapon(weapon: Dictionary) -> void:
	shelf_weapons.erase(weapon)
	shelf_updated.emit()

func get_shelf_weapons() -> Array[Dictionary]:
	return shelf_weapons

func _trade_offer_to_material(trade_offer: Dictionary) -> Dictionary:
	var item_id: String = trade_offer.get("item_id", "")
	var item: ItemData = ItemDatabase.get_item(item_id) if not item_id.is_empty() else null
	if item == null:
		return {
			"item_id": item_id,
			"item_name": trade_offer.get("name", "???"),
			"item_type": ItemData.ItemType.MATERIAL,
		}

	var material: Dictionary = {
		"item_id": item.item_id,
		"item_name": item.item_name,
		"rarity": item.rarity,
		"base_value": item.base_value,
		"item_type": item.item_type,
	}
	material.merge(item.effect_data)
	return material

func _trade_offer_to_weapon(trade_offer: Dictionary) -> Dictionary:
	var rarity: int = clampi(int(trade_offer.get("rarity", 1)), 1, 5)
	return {
		"weapon_name": trade_offer.get("name", "???"),
		"blank_id": "trade_item",
		"blank_name": trade_offer.get("name", "???"),
		"atk": 0,
		"def_stat": 0,
		"magic": 0,
		"speed": 5,
		"skill1": {},
		"skill2": {},
		"rarity_tier": rarity,
		"durability": 0,
		"durability_max": 50,
		"source": "trade",
	}
