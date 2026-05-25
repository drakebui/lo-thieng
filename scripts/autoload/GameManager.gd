# gdlint: ignore=max-public-methods
# Quản lý game state tổng: phase hiện tại, ngày, gold, reputation
extends Node

signal day_changed(day: int)
signal phase_changed(phase: GamePhase)
signal gold_changed(amount: int)
signal reputation_changed(value: int)
signal travel_stamina_changed(current: int, maximum: int)
signal region_unlocked(region_id: String)

enum GamePhase { MORNING, NOON, AFTERNOON, NIGHT }

const MAX_HAND_SLOTS := 12
const COMBAT_WEAPON_SLOTS := 3
const DEMO_LAST_DAY := 4
const GAME_OVER_ZERO_GOLD_THRESHOLD: int = 3
const REGION_ENTRY_COST: Dictionary = {
	"DongMay":     2,
	"RungTramHon": 2,
	"NuiThanDo":   3,
	"BaiCat":      3,
	"ThanhNgoc":   4,
	"LangTo":      2,
}
# Thứ tự điều hướng trong một vùng (player đi từ trái sang phải qua các scene)
const SUB_SCENE_ORDER: Array[String] = [
	"STORY_1",
	"LOOP_A",
	"LOOP_B",
	"STORY_2",
	"LOOP_C",
	"LANDMARK",
]
const DEFAULT_TUTORIAL_FLAGS: Dictionary = {
	"opening_seen": false,
	"forge_phase1_shown": false,
	"forge_phase2_shown": false,
	"debt_notice_shown": false,
	"shelf_shown": false,
	"bargain_shown": false,
	"inventory_shown": false,
	"explore_shown": false,
	"combat_shown": false,
	"stamina_shown": false,
	"ba_trum_intro_seen": false,
	"ntn_day1_dialogue_seen": false,
	"day_scene_card_seen_1": false,
	"day_scene_card_seen_2": false,
	"day_scene_card_seen_3": false,
	"day_scene_card_seen_4": false,
	"explore_phase_seen": false,
	"day1_loop_seen": false,
	"day0_intro_seen": false,
	"day0_forge_phase_seen": false,
	"day0_forge_done": false,
	"first_forge_complete_seen": false,
	"day0_shop_phase_seen": false,
	"day0_shop_hint_seen": false,
	"day0_bargain_seen": false,
	"first_price_hint_seen": false,
	"day0_customer_done": false,
	"day1_forge_done": false,
	"day2_freeplay_seen": false,
	"co_long_gio_met": false,
	"day3_co_long_gio_seen": false,
	"day4_deadline_seen": false,
}

# ── Core state ────────────────────────────────────────────────────────────────

var current_day:   int = 0
var current_phase: GamePhase = GamePhase.MORNING
var gold:          int = 2000
var reputation:    int = 0
var smithing_mastery: int = 0
var current_tier: int = 1
var artifact_count:   int = 0
var consecutive_zero_gold_days: int = 0

# ── Exploration ───────────────────────────────────────────────────────────────

var travel_stamina:     int = 14
var max_travel_stamina: int = 14
var unlocked_regions:   Array[String] = ["DongMay"]
var hand_inventory:     Array[Dictionary] = []   # tối đa MAX_HAND_SLOTS khi đi vùng
var exploration_state:  Dictionary = {}
# Cấu trúc:
# {
#   "region_id": String,
#   "rng_seed": int,
#   "enemy_spawn_seed": int,              # reroll vị trí quái mà không đổi map
#   "pending_loot": Array[Dictionary],    # item drop chờ nhận
#   "pending_combat_enemy_idx": int       # quái đang trigger combat hiện tại
# }

# ── Region / Combat handoff ───────────────────────────────────────────────────

var current_region_id:    String = ""   # vùng đang khám phá
var current_sub_scene_idx: int = 0
var region_clear_flags: Dictionary = {}   # Vùng nào đã clear tới LANDMARK
var unlocked_warrior_npcs: Array[String] = []   # Kiếm sĩ đặc trưng theo region_id
var current_sub_scene_type: String = "STORY_1"
var pending_combat_enemy: String = ""   # enemy_id để CombatScene load (từ exploration)
var pending_combat_is_counter: bool = false
var post_combat_return:   String = ""   # scene path quay lại sau combat

# ── Forge state (dùng nội bộ giữa MaterialPicker / WeaponBuilder) ─────────────

var selected_material: Dictionary = {}
var selected_blank:    Dictionary = {}
var selected_element:  String = ""
var forge_return_to_material_step: bool = false

# ── Weapons ───────────────────────────────────────────────────────────────────

var forged_weapons:   Array[Dictionary] = []
var equipped_weapons: Array[Dictionary] = [{}, {}, {}]
var save_restored:    bool = false
var day_start_gold:   int = 2000
var pending_day_summary_stats: Dictionary = {}
var tutorial_flags: Dictionary = DEFAULT_TUTORIAL_FLAGS.duplicate()


func _ready() -> void:
	gold_changed.connect(func(amount: int) -> void:
		EventBus.gold_changed.emit(amount)
	)
	reputation_changed.connect(func(value: int) -> void:
		EventBus.reputation_changed.emit(value)
	)
	travel_stamina_changed.connect(func(current: int, maximum: int) -> void:
		EventBus.stamina_changed.emit(current, maximum)
	)
	phase_changed.connect(func(_phase: GamePhase) -> void:
		EventBus.day_phase_changed.emit(current_day, current_phase)
	)
	day_changed.connect(func(_day: int) -> void:
		EventBus.day_phase_changed.emit(current_day, current_phase)
	)
	EventBus.weapon_forged.connect(_on_weapon_forged)
	EventBus.shop_closed.connect(func(stats: Dictionary) -> void:
		pending_day_summary_stats = stats.duplicate()
		if current_phase == GamePhase.AFTERNOON:
			DayCycle.advance_phase()
		else:
			push_warning("shop_closed khi current_phase không phải AFTERNOON")
	)


func init_new_game() -> void:
	current_day = 0
	current_phase = GamePhase.MORNING
	gold = 2000
	reputation = 0
	smithing_mastery = 0
	current_tier = 1
	artifact_count = 0
	consecutive_zero_gold_days = 0
	travel_stamina = max_travel_stamina
	unlocked_regions = ["DongMay"]
	current_sub_scene_idx = 0
	region_clear_flags = {}
	unlocked_warrior_npcs = []
	day_start_gold = gold
	pending_day_summary_stats = {}
	tutorial_flags = _get_default_tutorial_flags()
	clear_hand()
	clear_exploration_state()
	current_region_id = ""
	current_sub_scene_type = SUB_SCENE_ORDER[0]
	pending_combat_enemy = ""
	pending_combat_is_counter = false
	post_combat_return = ""
	selected_material = {}
	selected_blank = {}
	selected_element = ""
	forge_return_to_material_step = false

	var starter_weapon := _make_starter_weapon()
	forged_weapons = [starter_weapon]
	equipped_weapons = [starter_weapon, {}, {}]

	InventorySystem.clear_all()
	InventorySystem.set_weapons([starter_weapon])
	InventorySystem.add_trade_offer({
		"type": "material",
		"item_id": "sat_tho",
		"name": "Sắt Thô",
		"amount": 4,
	})
	for checkpoint in DebtSystem.checkpoints:
		checkpoint.is_paid = false
		checkpoint.is_late = false
		checkpoint.has_notified = false
	DebtSystem.refresh_debt_summary()
	save_restored = true
	gold_changed.emit(gold)
	reputation_changed.emit(reputation)
	travel_stamina_changed.emit(travel_stamina, max_travel_stamina)
	phase_changed.emit(current_phase)
	day_changed.emit(current_day)


func ensure_new_game_starter() -> void:
	if current_day > 1:
		return
	if not forged_weapons.is_empty() or has_any_equipped():
		return
	if not InventorySystem.get_weapons().is_empty():
		return

	var starter_weapon := _make_starter_weapon()
	forged_weapons = [starter_weapon]
	equipped_weapons = [starter_weapon, {}, {}]
	InventorySystem.set_weapons([starter_weapon])


func restore_from_save(data: Dictionary) -> void:
	if data.has("day"):
		current_day = int(data["day"])
	if data.has("current_phase"):
		_restore_current_phase(int(data["current_phase"]))
	if data.has("gold"):
		gold = int(data["gold"])
	if data.has("day_start_gold"):
		day_start_gold = int(data["day_start_gold"])
	else:
		day_start_gold = gold
	if data.has("reputation"):
		reputation = int(data["reputation"])
	if data.has("smithing_mastery"):
		smithing_mastery = int(data["smithing_mastery"])
	current_tier = int(data.get("current_tier", 1))
	if data.has("artifact_count"):
		artifact_count = int(data["artifact_count"])
	consecutive_zero_gold_days = int(data.get("consecutive_zero_gold_days", 0))
	if data.has("max_travel_stamina"):
		max_travel_stamina = maxi(1, int(data["max_travel_stamina"]))
	if data.has("unlocked_regions"):
		var loaded_regions: Array[String] = []
		loaded_regions.assign(data["unlocked_regions"])
		unlocked_regions = loaded_regions
	if data.has("region_clear_flags") and data["region_clear_flags"] is Dictionary:
		region_clear_flags = (data["region_clear_flags"] as Dictionary).duplicate()
	if data.has("unlocked_warrior_npcs"):
		var loaded_warriors: Array[String] = []
		loaded_warriors.assign(data["unlocked_warrior_npcs"])
		unlocked_warrior_npcs = loaded_warriors
	if data.has("debt_checkpoints"):
		for entry: Dictionary in data["debt_checkpoints"]:
			for checkpoint in DebtSystem.checkpoints:
				if checkpoint.id == entry.get("id", ""):
					checkpoint.is_paid = entry.get("is_paid", false)
					checkpoint.is_late = entry.get("is_late", false)
					checkpoint.has_notified = entry.get("has_notified", false)
	if data.has("forged_weapons"):
		var loaded_weapons: Array[Dictionary] = []
		loaded_weapons.assign(data["forged_weapons"])
		forged_weapons = loaded_weapons
	if data.has("equipped_weapons"):
		var loaded_equipped: Array[Dictionary] = []
		var saved_equipped: Array = data["equipped_weapons"]
		for i in COMBAT_WEAPON_SLOTS:
			if i < saved_equipped.size() and saved_equipped[i] is Dictionary:
				loaded_equipped.append(saved_equipped[i])
			else:
				loaded_equipped.append({})
		equipped_weapons = loaded_equipped
	if data.has("travel_stamina"):
		travel_stamina = clampi(int(data["travel_stamina"]), 0, max_travel_stamina)
	if data.has("tutorial_flags") and data["tutorial_flags"] is Dictionary:
		tutorial_flags = _merge_tutorial_flags(data["tutorial_flags"] as Dictionary)
	else:
		tutorial_flags = _get_default_tutorial_flags()
	ensure_new_game_starter()
	DebtSystem.refresh_debt_summary()

	save_restored = true
	gold_changed.emit(gold)
	reputation_changed.emit(reputation)
	travel_stamina_changed.emit(travel_stamina, max_travel_stamina)
	phase_changed.emit(current_phase)
	day_changed.emit(current_day)


func _restore_current_phase(saved_phase: int) -> void:
	match saved_phase:
		GamePhase.MORNING:
			current_phase = GamePhase.MORNING
		GamePhase.NOON:
			current_phase = GamePhase.NOON
		GamePhase.AFTERNOON:
			current_phase = GamePhase.AFTERNOON
		GamePhase.NIGHT:
			current_phase = GamePhase.NIGHT
		_:
			current_phase = GamePhase.MORNING


func _get_default_tutorial_flags() -> Dictionary:
	return DEFAULT_TUTORIAL_FLAGS.duplicate()


func _merge_tutorial_flags(saved_flags: Dictionary) -> Dictionary:
	var merged_flags := _get_default_tutorial_flags()
	for flag: String in saved_flags.keys():
		if flag == "day2_bargain_seen":
			continue
		merged_flags[flag] = bool(saved_flags[flag])
	if bool(saved_flags.get("day2_bargain_seen", false)):
		merged_flags["first_price_hint_seen"] = true
	return merged_flags


# ══════════════════════════════════════════════════════════════════════════════
# GOLD
# ══════════════════════════════════════════════════════════════════════════════

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


# ══════════════════════════════════════════════════════════════════════════════
# REPUTATION
# ══════════════════════════════════════════════════════════════════════════════

func add_reputation(amount: int) -> void:
	reputation = clampi(reputation + amount, 0, 10)
	reputation_changed.emit(reputation)


# ══════════════════════════════════════════════════════════════════════════════
# PHASE & DAY
# ══════════════════════════════════════════════════════════════════════════════

func change_phase(new_phase: GamePhase) -> void:
	current_phase = new_phase
	phase_changed.emit(new_phase)


func _check_zero_gold_streak() -> void:
	if gold <= 0:
		consecutive_zero_gold_days += 1
	else:
		consecutive_zero_gold_days = 0
	if consecutive_zero_gold_days >= GAME_OVER_ZERO_GOLD_THRESHOLD:
		EventBus.game_over_triggered.emit("zero_gold_3_days")


func advance_day() -> void:
	current_day += 1
	day_start_gold = gold
	_restore_travel_stamina()
	change_phase(GamePhase.MORNING)
	day_changed.emit(current_day)


# ══════════════════════════════════════════════════════════════════════════════
# TRAVEL STAMINA
# ══════════════════════════════════════════════════════════════════════════════

func get_entry_cost(region_id: String) -> int:
	var cost: int = REGION_ENTRY_COST.get(region_id, 2)
	return cost


func can_enter_region(region_id: String) -> bool:
	return travel_stamina >= get_entry_cost(region_id)


func consume_entry_stamina(region_id: String) -> bool:
	var cost: int = get_entry_cost(region_id)
	if travel_stamina < cost:
		return false
	travel_stamina = maxi(0, travel_stamina - cost)
	travel_stamina_changed.emit(travel_stamina, max_travel_stamina)
	if travel_stamina == 0:
		EventBus.travel_stamina_depleted.emit()
	return true


func consume_encounter_stamina() -> int:
	var cost := 1 if pending_combat_is_counter else 2
	var spent: int = mini(cost, travel_stamina)
	if spent <= 0:
		return 0
	travel_stamina = maxi(0, travel_stamina - spent)
	travel_stamina_changed.emit(travel_stamina, max_travel_stamina)
	if travel_stamina == 0:
		EventBus.travel_stamina_depleted.emit()
	return spent


func consume_flee_stamina(amount: int = 1) -> int:
	var spent: int = mini(maxi(amount, 0), travel_stamina)
	if spent <= 0:
		return 0
	travel_stamina = maxi(0, travel_stamina - spent)
	travel_stamina_changed.emit(travel_stamina, max_travel_stamina)
	if travel_stamina == 0:
		EventBus.travel_stamina_depleted.emit()
	return spent


func _restore_travel_stamina() -> void:
	travel_stamina = max_travel_stamina
	travel_stamina_changed.emit(travel_stamina, max_travel_stamina)


# ══════════════════════════════════════════════════════════════════════════════
# REGIONS
# ══════════════════════════════════════════════════════════════════════════════

func unlock_region(region_id: String) -> void:
	if region_id not in unlocked_regions:
		unlocked_regions.append(region_id)
		region_unlocked.emit(region_id)


func is_region_unlocked(region_id: String) -> bool:
	return region_id in unlocked_regions


func is_region_cleared(region_id: String) -> bool:
	return region_clear_flags.get(region_id, false)


func mark_region_cleared(region_id: String) -> void:
	if region_clear_flags.get(region_id, false):
		return
	region_clear_flags[region_id] = true
	if not unlocked_warrior_npcs.has(region_id):
		unlocked_warrior_npcs.append(region_id)
	EventBus.region_cleared.emit(region_id)


func clear_exploration_state() -> void:
	exploration_state.clear()


# ══════════════════════════════════════════════════════════════════════════════
# HAND INVENTORY (giới hạn 12 slot khi đi vùng)
# ══════════════════════════════════════════════════════════════════════════════

func add_to_hand(material: Dictionary) -> bool:
	if hand_inventory.size() >= MAX_HAND_SLOTS:
		return false
	hand_inventory.append(material)
	return true


func remove_from_hand(material: Dictionary) -> void:
	hand_inventory.erase(material)


func clear_hand() -> void:
	hand_inventory.clear()


func is_hand_full() -> bool:
	return hand_inventory.size() >= MAX_HAND_SLOTS


# ══════════════════════════════════════════════════════════════════════════════
# WEAPONS
# ══════════════════════════════════════════════════════════════════════════════

func add_weapon(weapon_data: Dictionary) -> void:
	forged_weapons.append(weapon_data)
	EventBus.weapon_forged.emit(weapon_data)


func _on_weapon_forged(weapon_data: Dictionary) -> void:
	if weapon_data not in forged_weapons:
		forged_weapons.append(weapon_data)
	smithing_mastery += 1
	if current_day == 0:
		mark_tutorial_seen("day0_forge_done")
	elif current_day == 1:
		mark_tutorial_seen("day1_forge_done")


func has_tutorial_seen(flag: String) -> bool:
	return bool(tutorial_flags.get(flag, false))


func mark_tutorial(key: String) -> void:
	tutorial_flags[key] = true


func mark_tutorial_seen(flag: String) -> void:
	mark_tutorial(flag)


func equip_to_slot(slot: int, combat_weapon: Dictionary) -> void:
	if slot < 0 or slot >= equipped_weapons.size():
		return
	equipped_weapons[slot] = combat_weapon


func unequip_slot(slot: int) -> void:
	if slot < 0 or slot >= equipped_weapons.size():
		return
	equipped_weapons[slot] = {}


func has_any_equipped() -> bool:
	for w: Dictionary in equipped_weapons:
		if not w.is_empty():
			return true
	return false


func _make_starter_weapon() -> Dictionary:
	return {
		"weapon_name": "Búa Sắt Cũ",
		"blank_id": "bua_chien",
		"blank_name": "Búa Chiến",
		"atk": 12,
		"def_stat": 2,
		"magic": 0,
		"speed": 6,
		"skill1": {},
		"skill2": {},
		"rarity_tier": 1,
		"durability": 35,
		"durability_max": 50,
		"source": "starter",
	}
