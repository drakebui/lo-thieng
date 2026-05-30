extends Node

const SAVE_PATH = "user://save_data.json"

func save_game(game_state: Dictionary) -> void:
	game_state["saved_at"] = Time.get_datetime_string_from_system()
	game_state["tutorial_flags"] = GameManager.tutorial_flags
	game_state["region_clear_flags"] = GameManager.region_clear_flags
	game_state["unlocked_warrior_npcs"] = GameManager.unlocked_warrior_npcs
	game_state["quest_statuses"] = GameManager.quest_statuses
	game_state["active_quest_id"] = GameManager.active_quest_id
	game_state["unlocked_recipe_ids"] = GameManager.unlocked_recipe_ids
	game_state["materials"] = InventorySystem.get_materials()
	game_state["weapons"] = InventorySystem.get_weapons()
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(game_state))
	file.close()

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	var loaded_data: Dictionary = data if data else {}
	if loaded_data.has("tutorial_flags") and loaded_data["tutorial_flags"] is Dictionary:
		for key in loaded_data["tutorial_flags"]:
			if GameManager.tutorial_flags.has(key):
				GameManager.tutorial_flags[key] = bool(loaded_data["tutorial_flags"][key])
	InventorySystem.set_materials(loaded_data.get("materials", []))
	InventorySystem.set_weapons(
		loaded_data.get("weapons", loaded_data.get("forged_weapons", []))
	)
	return loaded_data

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func get_save_metadata() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	var loaded_data: Dictionary = data if data else {}
	return {
		"day": loaded_data.get("day", 0),
		"saved_at": loaded_data.get("saved_at", ""),
	}

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
