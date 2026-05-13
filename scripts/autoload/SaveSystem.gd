extends Node

const SAVE_PATH = "user://save_data.json"

func save_game(game_state: Dictionary) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(game_state))
	file.close()

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data if data else {}

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
