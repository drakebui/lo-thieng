extends Node

const SAVE_PATH = "user://save_data.json"

func save_game(game_state: Dictionary) -> void:
	game_state["saved_at"] = Time.get_datetime_string_from_system()
	game_state["save_schema_version"] = 1
	game_state["tutorial_flags"] = GameManager.tutorial_flags
	game_state["region_clear_flags"] = GameManager.region_clear_flags
	game_state["unlocked_warrior_npcs"] = GameManager.unlocked_warrior_npcs
	game_state["quest_statuses"] = GameManager.quest_statuses
	game_state["active_quest_id"] = GameManager.active_quest_id
	game_state["unlocked_recipe_ids"] = GameManager.unlocked_recipe_ids
	game_state["npc_affinities"] = GameManager.npc_affinities
	game_state["sold_weapons_history"] = GameManager.sold_weapons_history
	game_state["materials"] = InventorySystem.get_materials()
	game_state["weapons"] = InventorySystem.get_weapons()
	game_state["shelf_weapons"] = InventorySystem.get_shelf_weapons()
	game_state["hand_inventory"] = GameManager.hand_inventory.duplicate(true)
	var active_commissions: Array[String] = []
	for c in CommissionSystem.get_active():
		active_commissions.append(c.commission_id)
	game_state["commissions_active"] = active_commissions
	game_state["commissions_completed"] = CommissionSystem.get_completed_ids()
	game_state["commissions_last_offer_day"] = CommissionSystem.get_last_offer_day()
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Không thể mở file save: " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(game_state))
	file.close()

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Không thể mở file save: " + SAVE_PATH)
		return {}
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if not (data is Dictionary):
		push_error("File save bị hỏng hoặc sai định dạng JSON: " + SAVE_PATH)
		return {}
	var loaded_data: Dictionary = data
	if loaded_data.has("tutorial_flags") and loaded_data["tutorial_flags"] is Dictionary:
		for key in loaded_data["tutorial_flags"]:
			if GameManager.tutorial_flags.has(key):
				GameManager.tutorial_flags[key] = bool(loaded_data["tutorial_flags"][key])
	var raw_mats = loaded_data.get("materials", [])
	InventorySystem.set_materials(raw_mats if raw_mats is Array else [])
	var raw_weapons = loaded_data.get("weapons", loaded_data.get("forged_weapons", []))
	InventorySystem.set_weapons(raw_weapons if raw_weapons is Array else [])
	var raw_shelf = loaded_data.get("shelf_weapons", [])
	InventorySystem.set_shelf_weapons(raw_shelf if raw_shelf is Array else [])
	var raw_active = loaded_data.get("commissions_active", [])
	var raw_completed = loaded_data.get("commissions_completed", [])
	var last_offer_day := int(
		loaded_data.get("commissions_last_offer_day", loaded_data.get("day", -1))
	)
	CommissionSystem.restore_state(
		raw_active if raw_active is Array else [],
		raw_completed if raw_completed is Array else [],
		last_offer_day
	)
	return loaded_data

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func get_save_metadata() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Không thể mở file save: " + SAVE_PATH)
		return {}
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	var loaded_data: Dictionary = data if data is Dictionary else {}
	return {
		"day": loaded_data.get("day", 0),
		"saved_at": loaded_data.get("saved_at", ""),
	}

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
