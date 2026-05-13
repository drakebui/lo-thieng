# scripts/autoload/InventorySystem.gd
extends Node

var weapons: Array[Dictionary] = []
var shelf_weapons: Array[Dictionary] = []  # Max 3 slot — dùng cho tiệm

const MAX_SHELF_SLOTS := 3

signal weapon_added(weapon: Dictionary)
signal shelf_updated()

func add_weapon(weapon: Dictionary) -> void:
	weapons.append(weapon)
	weapon_added.emit(weapon)

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
