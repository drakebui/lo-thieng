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
const REGION_ENTRY_COST: Dictionary = {
	"DongMay":     2,
	"RungTramHon": 2,
	"NuiThanDo":   3,
	"BaiCat":      3,
	"ThanhNgoc":   4,
	"LangTo":      2,
}

# ── Core state ────────────────────────────────────────────────────────────────

var current_day:   int = 1
var current_phase: GamePhase = GamePhase.MORNING
var gold:          int = 2000
var reputation:    int = 0
var smithing_mastery: int = 0
var artifact_count:   int = 0

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
var pending_combat_enemy: String = ""   # enemy_id để CombatScene load (từ exploration)
var post_combat_return:   String = ""   # scene path quay lại sau combat

# ── Forge state (dùng nội bộ giữa MaterialPicker / WeaponBuilder) ─────────────

var selected_material: Dictionary = {}
var selected_blank:    Dictionary = {}

# ── Weapons ───────────────────────────────────────────────────────────────────

var forged_weapons:   Array[Dictionary] = []
var equipped_weapons: Array[Dictionary] = [{}, {}]
var save_restored:    bool = false
var day_start_gold:   int = 2000
var pending_day_summary_stats: Dictionary = {}


func _ready() -> void:
	EventBus.weapon_forged.connect(_on_weapon_forged)
	EventBus.shop_closed.connect(func(stats: Dictionary) -> void:
		pending_day_summary_stats = stats.duplicate()
		change_phase(GamePhase.NIGHT)
	)


func restore_from_save(data: Dictionary) -> void:
	if data.has("day"):
		current_day = int(data["day"])
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
	if data.has("artifact_count"):
		artifact_count = int(data["artifact_count"])
	if data.has("unlocked_regions"):
		var loaded_regions: Array[String] = []
		loaded_regions.assign(data["unlocked_regions"])
		unlocked_regions = loaded_regions
	if data.has("forged_weapons"):
		var loaded_weapons: Array[Dictionary] = []
		loaded_weapons.assign(data["forged_weapons"])
		forged_weapons = loaded_weapons
	if data.has("equipped_weapons"):
		var loaded_equipped: Array[Dictionary] = []
		var saved_equipped: Array = data["equipped_weapons"]
		for i in 2:
			if i < saved_equipped.size() and saved_equipped[i] is Dictionary:
				loaded_equipped.append(saved_equipped[i])
			else:
				loaded_equipped.append({})
		equipped_weapons = loaded_equipped
	if data.has("travel_stamina"):
		travel_stamina = clampi(int(data["travel_stamina"]), 0, max_travel_stamina)

	save_restored = true
	gold_changed.emit(gold)
	reputation_changed.emit(reputation)
	travel_stamina_changed.emit(travel_stamina, max_travel_stamina)
	day_changed.emit(current_day)


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
