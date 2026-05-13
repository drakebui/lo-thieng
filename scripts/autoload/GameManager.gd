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

# ── Core state ────────────────────────────────────────────────────────────────

var current_day:   int = 1
var current_phase: GamePhase = GamePhase.MORNING
var gold:          int = 2000
var reputation:    int = 0
var smithing_mastery: int = 0
var artifact_count:   int = 0

# ── Exploration ───────────────────────────────────────────────────────────────

var travel_stamina:     int = 10
var max_travel_stamina: int = 10
var unlocked_regions:   Array[String] = ["DongMay"]
var hand_inventory:     Array[Dictionary] = []   # tối đa MAX_HAND_SLOTS khi đi vùng

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
	current_phase = GamePhase.MORNING
	_restore_travel_stamina()
	day_changed.emit(current_day)


# ══════════════════════════════════════════════════════════════════════════════
# TRAVEL STAMINA
# ══════════════════════════════════════════════════════════════════════════════

# Trả về false nếu hết stamina (caller nên ép player về xưởng)
func consume_travel_stamina(amount: int = 1) -> bool:
	if travel_stamina <= 0:
		return false
	travel_stamina = maxi(0, travel_stamina - amount)
	travel_stamina_changed.emit(travel_stamina, max_travel_stamina)
	return true


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
