@tool
extends EditorScript

const ForgeConverter := preload("res://scripts/forge/weapon_data.gd")
const GuideBook := preload("res://scripts/ui/guide_book.gd")
const GameManagerScript := preload("res://scripts/autoload/GameManager.gd")

const VALID_EFFECTS := [
	"DAMAGE",
	"DAMAGE_STATUS",
	"BUFF_DEF",
	"BUFF_ALL_STATS",
	"DAMAGE_HEAL",
	"DAMAGE_TWICE",
	"DAMAGE_SKIP_TURN",
	"SHIELD_ONE_HIT",
	"DEBUFF_ATK",
	"PASSIVE_NO_DURABILITY",
	"DAMAGE_IGNORE_DEF",
]

var _passed := 0
var _failed := 0


func _run() -> void:
	print("=== LÒ THIÊNG SMOKE TEST ===")
	_check_files()
	_check_debt_checkpoints()
	_check_skill_effects()
	_check_forge_converter()
	_check_guide_book_functions()
	_check_day_cycle_constants()
	print("=== %d/%d checks passed ===" % [_passed, _passed + _failed])


func _pass(name: String) -> void:
	_passed += 1
	print("[PASS] " + name)


func _fail(name: String, reason: String) -> void:
	_failed += 1
	print("[FAIL] " + name + " — " + reason)


func _check(name: String, condition: bool, reason: String = "") -> void:
	if condition:
		_pass(name)
	else:
		_fail(name, reason if reason != "" else "condition false")


func _check_files() -> void:
	var paths := [
		"res://scenes/main/WorkshopHub.tscn",
		"res://scenes/forge/WeaponBuilder.tscn",
		"res://scenes/forge/ElementPicker.tscn",
		"res://scenes/forge/ForgeSession.tscn",
		"res://resources/DebtCheckpoint.gd",
		"res://resources/debt/c1_mat_bang.tres",
		"res://resources/debt/c2_dan_duong.tres",
		"res://resources/debt/c3_thue_lon.tres",
		"res://resources/debt/c4_no_goc.tres",
		"res://scripts/tools/static_check.py",
		"res://scripts/ui/guide_book.gd",
		"res://scripts/forge/weapon_data.gd",
	]
	for path: String in paths:
		_check("File: " + path.get_file(), _file_exists(path), "file not found")


func _check_debt_checkpoints() -> void:
	var c1 := load("res://resources/debt/c1_mat_bang.tres")
	if c1 == null:
		_fail("C1 checkpoint", "cannot load")
	else:
		_assert_int("C1.amount_gold == 3000", c1.get("amount_gold"), 3000)
		_assert_int("C1.trigger_day == 1", c1.get("trigger_day"), 1)
		_assert_int("C1.deadline_day == 4", c1.get("deadline_day"), 4)
		_assert_int("C1.penalty_gold == 300", c1.get("penalty_gold"), 300)
		_assert_string("C1.agent_id == nguoi_thu_no", c1.get("agent_id"), "nguoi_thu_no")

	var c4 := load("res://resources/debt/c4_no_goc.tres")
	if c4 == null:
		_fail("C4 checkpoint", "cannot load")
	else:
		_assert_int("C4.amount_gold == 65000", c4.get("amount_gold"), 65000)
		_assert_int("C4.trigger_day == 29", c4.get("trigger_day"), 29)
		_assert_int("C4.deadline_day == 52", c4.get("deadline_day"), 52)
		_assert_int("C4.penalty_gold == 6500", c4.get("penalty_gold"), 6500)
		_assert_string("C4.agent_id == ba_trum_hac_nguyet", c4.get("agent_id"), "ba_trum_hac_nguyet")


func _check_skill_effects() -> void:
	var dir := DirAccess.open("res://resources/skills/")
	if dir == null:
		_fail("Skill directory", "cannot open res://resources/skills/")
		return

	var files: PackedStringArray = dir.get_files()
	files.sort()
	for file_name: String in files:
		if file_name.get_extension() != "tres":
			continue
		var path := "res://resources/skills/" + file_name
		var skill := load(path)
		if skill == null or not skill is Resource:
			_fail("skill " + file_name, "cannot load skill " + file_name)
			continue
		var effect := str(skill.get("effect"))
		if effect not in VALID_EFFECTS:
			_fail("skill " + file_name + " effect", effect + " not in VALID_EFFECTS")
		else:
			_pass("skill " + file_name + " effect OK")


func _check_forge_converter() -> void:
	var fd := {
		"phase1_tier": "cam",
		"phase2_prefix": "thuong",
		"suffix": "thieu_dot",
		"element_name": "Hỏa",
		"base_atk": 10,
		"base_def": 2,
		"base_magic": 0,
		"base_speed": 5,
		"weapon_type": "Kiếm Đơn",
		"blank_id": "kiem_don",
		"price_mult": 1.0,
	}
	var result: Dictionary = ForgeConverter.forge_to_combat(fd)
	var required_keys := [
		"weapon_name",
		"atk",
		"def_stat",
		"magic",
		"speed",
		"skill1",
		"skill2",
		"rarity_tier",
		"sell_value",
		"combat_power",
		"durability",
		"durability_max",
		"phase1_tier",
		"phase2_prefix",
	]
	for key: String in required_keys:
		_check("ForgeConverter has key " + key, result.has(key), "missing key " + key)
	_check("ForgeConverter atk >= 1", result.get("atk", 0) >= 1, "atk phải >= 1")
	_check("ForgeConverter sell_value > 0", result.get("sell_value", 0) > 0, "sell_value phải > 0")
	_check(
		"ForgeConverter rarity_tier >= 1",
		result.get("rarity_tier", 0) >= 1,
		"rarity_tier phải >= 1"
	)
	_check(
		"ForgeConverter weapon_name non-empty",
		str(result.get("weapon_name", "")).length() > 0,
		"weapon_name không được rỗng"
	)
	_check(
		"ForgeConverter skill1 Dictionary",
		result.get("skill1", null) is Dictionary,
		"skill1 phải là Dictionary"
	)


func _check_guide_book_functions() -> void:
	_guide_method("get_ba_trum_intro_steps", 3)
	_guide_method("get_co_long_gio_first_dialogue", 6)
	_guide_method("get_co_long_gio_second_dialogue", 5)
	_guide_method("get_ba_trum_c4_dialogue", 5)
	_guide_method("get_ntn_day1_dialogue", 4)


func _check_day_cycle_constants() -> void:
	var constants: Dictionary = (GameManagerScript as Script).get_script_constant_map()
	if not constants.has("DEMO_LAST_DAY"):
		_fail("GameManager.DEMO_LAST_DAY", "constant DEMO_LAST_DAY not found")
	else:
		_assert_int("GameManager.DEMO_LAST_DAY == 4", constants["DEMO_LAST_DAY"], 4)

	if not constants.has("GAME_OVER_ZERO_GOLD_THRESHOLD"):
		_fail(
			"GameManager.GAME_OVER_ZERO_GOLD_THRESHOLD",
			"constant GAME_OVER_ZERO_GOLD_THRESHOLD not found"
		)
	else:
		_assert_int(
			"GameManager.GAME_OVER_ZERO_GOLD_THRESHOLD == 3",
			constants["GAME_OVER_ZERO_GOLD_THRESHOLD"],
			3
		)


func _guide_method(method_name: String, min_size: int) -> void:
	if not _script_has_method(GuideBook, method_name):
		_fail(method_name, "function not found")
		return
	var result: Variant = Callable(GuideBook, method_name).call()
	var is_valid: bool = result is Array and (result as Array).size() >= min_size
	_check(
		method_name,
		is_valid,
		"expected Array size >= %d got %s" % [min_size, _value_size_text(result)]
	)


func _script_has_method(script: Script, method_name: String) -> bool:
	for method: Dictionary in script.get_script_method_list():
		if method.get("name", "") == method_name:
			return true
	return false


func _file_exists(path: String) -> bool:
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)


func _assert_int(name: String, actual: Variant, expected: int) -> void:
	_check(name, actual == expected, "expected %d got %s" % [expected, str(actual)])


func _assert_string(name: String, actual: Variant, expected: String) -> void:
	_check(name, actual == expected, "expected %s got %s" % [expected, str(actual)])


func _value_size_text(value: Variant) -> String:
	if value is Array:
		return "Array size %d" % value.size()
	return str(value)
