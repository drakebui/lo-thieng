@tool
extends EditorScript

const ForgeConverter := preload("res://scripts/forge/weapon_data.gd")
const ForgeSystem := preload("res://scripts/forge/forge_system.gd")
const ForgePhase2 := preload("res://scripts/forge/forge_phase2.gd")
const ForgePhase3 := preload("res://scripts/forge/forge_phase3.gd")
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
	_check_chapter1_forge_mechanics()
	_check_chapter1_shop_and_echo()
	_check_guide_book_functions()
	_check_day_cycle_constants()
	_check_audit_regressions()
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


func _check_chapter1_forge_mechanics() -> void:
	# 1. Kiểm tra 2 hồ sơ nhiệt Phase 1 (Phôi Nặng vs Phôi Thanh & Phép)
	var heavy: Dictionary = ForgeSystem.get_heat_profile("bua_chien")
	var light: Dictionary = ForgeSystem.get_heat_profile("kiem_don")
	_check("HeatProfile heavy low == 55", is_equal_approx(float(heavy["low"]), 55.0))
	_check("HeatProfile heavy peak == 80", is_equal_approx(float(heavy["peak"]), 80.0))
	_check("HeatProfile heavy burn == 92", is_equal_approx(float(heavy["burn"]), 92.0))
	_check("HeatProfile light low == 48", is_equal_approx(float(light["low"]), 48.0))
	_check("HeatProfile light peak == 65", is_equal_approx(float(light["peak"]), 65.0))
	_check("HeatProfile light burn == 80", is_equal_approx(float(light["burn"]), 80.0))

	# 2. Kiểm tra bảng ánh xạ tiền tố Phase 2 tất định 100% (0 ngẫu nhiên)
	_assert_string(
		"P2 score=-4 -> phan_chu",
		ForgePhase2.resolve_deterministic_prefix(-4, 3, 2, 2),
		"phan_chu"
	)
	_assert_string(
		"P2 score=-2 -> curse_nang",
		ForgePhase2.resolve_deterministic_prefix(-2, 3, 2, 2),
		"curse_nang"
	)
	_assert_string(
		"P2 score=-1 -> curse_nhe",
		ForgePhase2.resolve_deterministic_prefix(-1, 3, 2, 2),
		"curse_nhe"
	)
	_assert_string(
		"P2 score=0 -> thuong",
		ForgePhase2.resolve_deterministic_prefix(0, 3, 3, 2),
		"thuong"
	)
	_assert_string(
		"P2 T1 cap score=5 cuong=4 -> nang_tay",
		ForgePhase2.resolve_deterministic_prefix(5, 1, 4, 1),
		"nang_tay"
	)
	_assert_string(
		"P2 T1 cap score=5 nhu=4 -> than_toc",
		ForgePhase2.resolve_deterministic_prefix(5, 1, 1, 4),
		"than_toc"
	)
	_assert_string(
		"P2 T1 cap score=1 balanced -> tot",
		ForgePhase2.resolve_deterministic_prefix(1, 1, 3, 2),
		"tot"
	)
	_assert_string(
		"P2 T2 score=2 cuong>nhu -> kiet_tac",
		ForgePhase2.resolve_deterministic_prefix(2, 2, 3, 2),
		"kiet_tac"
	)
	_assert_string(
		"P2 T2 score=2 nhu>=cuong -> can_bang",
		ForgePhase2.resolve_deterministic_prefix(2, 2, 2, 3),
		"can_bang"
	)
	_assert_string(
		"P2 T2 cap score=5 cuong>nhu -> to_nghe",
		ForgePhase2.resolve_deterministic_prefix(5, 2, 4, 1),
		"to_nghe"
	)
	_assert_string(
		"P2 T2 cap score=5 nhu>=cuong -> huyen_bi",
		ForgePhase2.resolve_deterministic_prefix(5, 2, 2, 3),
		"huyen_bi"
	)
	_assert_string(
		"P2 T3 score=4 cuong>nhu -> cung_nhu_da",
		ForgePhase2.resolve_deterministic_prefix(4, 3, 3, 2),
		"cung_nhu_da"
	)
	_assert_string(
		"P2 T3 score=4 nhu>=cuong -> khi_phach",
		ForgePhase2.resolve_deterministic_prefix(4, 3, 2, 3),
		"khi_phach"
	)
	_assert_string(
		"P2 T3 score=5 cuong>nhu -> perfect",
		ForgePhase2.resolve_deterministic_prefix(5, 3, 3, 2),
		"perfect"
	)
	_assert_string(
		"P2 T3 score=5 nhu>=cuong -> truong_sinh",
		ForgePhase2.resolve_deterministic_prefix(5, 3, 2, 3),
		"truong_sinh"
	)

	# 3. Kiểm tra Tôi Hoàn Hảo (+10% Giá, +10 Bền = 60/60) & Tôi Nước Thuần
	var pure_fd := {
		"phase1_tier": "do_ruc",
		"phase2_prefix": "to_nghe",
		"element": "",
		"suffix": "",
		"element_name": "",
		"base_atk": 14,
		"base_def": 2,
		"base_magic": 3,
		"base_speed": 6,
		"weapon_type": "Kiếm Đơn",
		"blank_id": "kiem_don",
		"perfect_quench": true,
		"durability_bonus": 10,
		"price_mult": 1.10,
	}
	var pure_w: Dictionary = ForgeConverter.forge_to_combat(pure_fd)
	_assert_int("Perfect quench durability_max == 60", pure_w.get("durability_max", 0), 60)
	_assert_string("Pure water weapon name has no trailing dot", pure_w.get("weapon_name", ""), "Tổ Nghề Kiếm Đơn")
	var p3: Variant = ForgePhase3.new()
	var elem_info: Dictionary = p3.get_element_data("")
	if p3 is Node:
		(p3 as Node).free()
	_assert_string("Pure water fallback element label", elem_info.get("name", ""), "Nước Thuần")


func _check_chapter1_shop_and_echo() -> void:
	# 1. Kiểm tra 4 tầng đọc vị mặc cả (NegotiationUI.get_reaction_tier)
	var neg_script := preload("res://scripts/shop/negotiation_ui.gd")
	_assert_int("Haggle Tier 1 (<= offer*1.05)", neg_script.get_reaction_tier(210, 200, 400), 1)
	_assert_int("Haggle Tier 2 (<= max*0.88)", neg_script.get_reaction_tier(320, 200, 400), 2)
	_assert_int("Haggle Tier 3 (<= max)", neg_script.get_reaction_tier(390, 200, 400), 3)
	_assert_int("Haggle Tier 4 (> max)", neg_script.get_reaction_tier(450, 200, 400), 4)

	# 2. Kiểm tra đủ 6 đơn đặt rèn Chương 1 (commission_001..006.tres)
	var commission_paths := [
		"res://resources/commissions/commission_001.tres",
		"res://resources/commissions/commission_002.tres",
		"res://resources/commissions/commission_003.tres",
		"res://resources/commissions/commission_004.tres",
		"res://resources/commissions/commission_005.tres",
		"res://resources/commissions/commission_006.tres",
	]
	for cpath: String in commission_paths:
		var c := load(cpath)
		_check("Commission " + cpath.get_file(), c != null, "cannot load " + cpath)


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


func _check_audit_regressions() -> void:
	# 1. Mỗi vũ khí rèn mới phải có uid riêng và fallback price_mult = 1.10 khi perfect_quench = true
	var fd1 := {
		"prefix": "Bình Thường", "rarity_tier": 1, "material_rarity": 1,
		"element": "", "quality_mult": 1.0, "base_atk": 10, "base_def": 2,
		"base_magic": 1, "base_speed": 5, "weapon_type": "Kiếm Đơn",
		"blank_id": "kiem_don", "perfect_quench": true, "durability_bonus": 10,
	}
	var fd2 := fd1.duplicate()
	var w1: Dictionary = ForgeConverter.forge_to_combat(fd1)
	var w2: Dictionary = ForgeConverter.forge_to_combat(fd2)
	_check("ForgeConverter assigns non-empty uid", String(w1.get("uid", "")) != "")
	_check("ForgeConverter uid unique per forge", String(w1.get("uid", "")) != String(w2.get("uid", "")))
	_check("ForgeConverter perfect_quench fallback price_mult", float(fd1.get("price_mult", 1.10)) >= 1.10)

	# 2. ForgePhase2 không văng lỗi khi material_rarity ngoài biên 1..3
	var p2: Variant = ForgePhase2.new()
	var low_cap: Dictionary = p2.calculate_prefix(95, 0)
	var high_cap: Dictionary = p2.calculate_prefix(95, 9)
	if p2 is Node:
		(p2 as Node).free()
	_check("ForgePhase2 clamps material_rarity <= 0", int(low_cap.get("rarity_tier", 0)) >= 1)
	_check("ForgePhase2 clamps material_rarity > 3", int(high_cap.get("rarity_tier", 0)) <= 4)

	# 3. tho_san.tres khớp đúng tag phoi_no_ban
	var tho_san := load("res://resources/customers/tho_san.tres")
	if tho_san == null:
		_fail("tho_san.tres", "cannot load")
	else:
		var ptags: Array = tho_san.get("preferred_weapon_tags")
		_check("tho_san prefers phoi_no_ban", ptags.has("phoi_no_ban"))

	# 4. first_artifact_shard.tres trả đúng mảnh cổ khí #1
	var q_shard := load("res://resources/quests/first_artifact_shard.tres")
	if q_shard == null:
		_fail("first_artifact_shard.tres", "cannot load")
	else:
		_assert_int("first_artifact_shard.reward_artifact_id == 1", q_shard.get("reward_artifact_id"), 1)

	# 5. Kiểm tra API chuẩn trên các Autoload scripts vừa bổ sung
	var gm_scr := preload("res://scripts/autoload/GameManager.gd") as Script
	var inv_scr := preload("res://scripts/autoload/InventorySystem.gd") as Script
	var comm_scr := preload("res://scripts/autoload/CommissionSystem.gd") as Script
	var debt_scr := preload("res://scripts/autoload/DebtSystem.gd") as Script
	_check("InventorySystem has _unequip_weapon_ref", _script_has_method(inv_scr, "_unequip_weapon_ref"))
	_check("CommissionSystem has restore_state", _script_has_method(comm_scr, "restore_state"))
	_check("DebtSystem has reset_checkpoints", _script_has_method(debt_scr, "reset_checkpoints"))
	_check("GameManager has ensure_new_game_starter", _script_has_method(gm_scr, "ensure_new_game_starter"))

	# 6. Gộp kiểm thử WeaponSpec.satisfies từ commission_smoke_test cũ
	var c1: CommissionData = load("res://resources/commissions/commission_001.tres")
	if c1 == null:
		_fail("commission_001.tres", "cannot load")
	else:
		var w_match := {"blank_id": "kiem_don", "element": "hoa", "rarity_tier": 1}
		var w_nomatch := {"blank_id": "bua_chien", "element": "bang", "rarity_tier": 1}
		_check("WeaponSpec matches commission_001 (kiem_don/hoa)", WeaponSpec.satisfies(w_match, c1) == true)
		_check("WeaponSpec rejects commission_001 (bua_chien/bang)", WeaponSpec.satisfies(w_nomatch, c1) == false)


func _value_size_text(value: Variant) -> String:
	if value is Array:
		return "Array size %d" % value.size()
	return str(value)
