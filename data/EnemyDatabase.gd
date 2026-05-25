# data/EnemyDatabase.gd
# Load enemy resources theo từng vùng.
# Dùng: EnemyDatabase.get_enemy("soi_dong_co_t1")
#        EnemyDatabase.get_enemies_by_region("DongMay")

class_name EnemyDatabase
extends Node

const ENEMY_DIR := "res://resources/enemies"

static var _enemies: Dictionary = {}
static var _initialized: bool = false

# ─── Public API ───────────────────────────────────────────

static func get_enemy(enemy_id: String) -> EnemyData:
	_init_if_needed()
	return _enemies.get(enemy_id, null)


static func get_enemies_by_region(region_id: String) -> Array[EnemyData]:
	_init_if_needed()
	var result: Array[EnemyData] = []
	for enemy in _enemies.values():
		if enemy.region == region_id:
			result.append(enemy)
	return result


static func get_all() -> Array[EnemyData]:
	_init_if_needed()
	var result: Array[EnemyData] = []
	for enemy in _enemies.values():
		result.append(enemy)
	return result

# ─── Internal ─────────────────────────────────────────────

static func _init_if_needed() -> void:
	if _initialized:
		return
	_load_enemies()
	_initialized = true


static func _register(enemy: EnemyData) -> void:
	_enemies[enemy.enemy_id] = enemy


static func _load_enemies() -> void:
	_enemies.clear()
	var dir := DirAccess.open(ENEMY_DIR)
	if dir == null:
		return

	var files: PackedStringArray = dir.get_files()
	files.sort()
	for file_name in files:
		if file_name.get_extension() != "tres":
			continue

		var resource_path := "%s/%s" % [ENEMY_DIR, file_name]
		var resource := load(resource_path)
		if resource is EnemyData:
			var enemy := resource as EnemyData
			_register(enemy)
