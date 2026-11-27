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
const FIRST_ARTIFACT_QUEST_ID := "first_artifact_shard"
const FIRST_ARTIFACT_QUEST_PATH := "res://resources/quests/first_artifact_shard.tres"
const REGION_ENTRY_COST: Dictionary = {
	"DongMay":     2,
	"RungTramHon": 2,
	"NuiThanDo":   3,
	"BaiCat":      3,
	"ThanhNgoc":   4,
	"LangTo":      2,
}
const REGION_UNLOCK_CHAIN: Dictionary = {
	"DongMay": "RungTramHon",
	"RungTramHon": "NuiThanDo",
	"NuiThanDo": "BaiCat",
	"BaiCat": "ThanhNgoc",
	"ThanhNgoc": "LangTo",
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
var collected_artifact_ids: Array[int] = []
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
var quest_statuses: Dictionary = {}
var active_quest_id: String = ""
var unlocked_recipe_ids: Array[String] = []
var npc_affinities: Dictionary = {}              # npc_id -> int (Thân thiết khách hàng)
var sold_weapons_history: Array[Dictionary] = [] # Tối đa 6 món bán gần nhất cho Weapon Echo
const MAX_SOLD_HISTORY := 6
const CURSED_PREFIXES: Array[String] = ["curse_nhe", "curse_nang", "phan_chu"]


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
	collected_artifact_ids = []
	consecutive_zero_gold_days = 0
	travel_stamina = max_travel_stamina
	unlocked_regions = ["DongMay"]
	current_sub_scene_idx = 0
	region_clear_flags = {}
	unlocked_warrior_npcs = []
	day_start_gold = gold
	pending_day_summary_stats = {}
	tutorial_flags = _get_default_tutorial_flags()
	quest_statuses = {}
	active_quest_id = ""
	unlocked_recipe_ids = []
	npc_affinities = {}
	sold_weapons_history = []
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
	DebtSystem.reset_checkpoints()
	CommissionSystem.reset_state()
	DebtSystem.refresh_debt_summary()
	save_restored = true
	gold_changed.emit(gold)
	reputation_changed.emit(reputation)
	travel_stamina_changed.emit(travel_stamina, max_travel_stamina)
	day_changed.emit(current_day)
	phase_changed.emit(current_phase)


func ensure_new_game_starter() -> void:
	if current_day > 1:
		return
	if not forged_weapons.is_empty() or has_any_equipped():
		return
	if not InventorySystem.get_weapons().is_empty():
		return
	if not InventorySystem.get_shelf_weapons().is_empty():
		return

	var starter_weapon := _make_starter_weapon()
	forged_weapons = [starter_weapon]
	equipped_weapons = [starter_weapon, {}, {}]
	InventorySystem.set_weapons([starter_weapon])


func restore_from_save(data: Dictionary) -> void:
	# Reset toàn bộ runtime state trước khi nạp save để không dính dữ liệu phiên cũ
	DebtSystem.reset_checkpoints()
	forged_weapons = []
	equipped_weapons = [{}, {}, {}]
	unlocked_regions = ["DongMay"]
	region_clear_flags = {}
	unlocked_warrior_npcs = []
	collected_artifact_ids = []
	clear_hand()
	clear_exploration_state()
	pending_day_summary_stats = {}
	current_region_id = ""
	current_sub_scene_idx = 0
	current_sub_scene_type = SUB_SCENE_ORDER[0]
	pending_combat_enemy = ""
	pending_combat_is_counter = false
	post_combat_return = ""

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
	if data.has("collected_artifact_ids") and data["collected_artifact_ids"] is Array:
		for aid in data["collected_artifact_ids"]:
			var aid_int := int(aid)
			if aid_int not in collected_artifact_ids:
				collected_artifact_ids.append(aid_int)
	consecutive_zero_gold_days = int(data.get("consecutive_zero_gold_days", 0))
	if data.has("max_travel_stamina"):
		max_travel_stamina = maxi(1, int(data["max_travel_stamina"]))
	if data.has("unlocked_regions") and data["unlocked_regions"] is Array:
		var loaded_regions: Array[String] = []
		for r in data["unlocked_regions"]:
			loaded_regions.append(String(r))
		if not loaded_regions.is_empty():
			unlocked_regions = loaded_regions
	if data.has("region_clear_flags") and data["region_clear_flags"] is Dictionary:
		region_clear_flags = (data["region_clear_flags"] as Dictionary).duplicate()
	if data.has("unlocked_warrior_npcs") and data["unlocked_warrior_npcs"] is Array:
		var loaded_warriors: Array[String] = []
		for w_npc in data["unlocked_warrior_npcs"]:
			loaded_warriors.append(String(w_npc))
		unlocked_warrior_npcs = loaded_warriors
	if data.has("debt_checkpoints") and data["debt_checkpoints"] is Array:
		for entry in data["debt_checkpoints"]:
			if not (entry is Dictionary):
				continue
			for checkpoint in DebtSystem.checkpoints:
				if checkpoint.id == String(entry.get("id", "")):
					checkpoint.is_paid = bool(entry.get("is_paid", false))
					checkpoint.is_late = bool(entry.get("is_late", false))
					checkpoint.has_notified = bool(entry.get("has_notified", false))
	if data.has("hand_inventory") and data["hand_inventory"] is Array:
		for h_item in data["hand_inventory"]:
			if h_item is Dictionary:
				add_to_hand((h_item as Dictionary).duplicate(true))
	# Đồng bộ forged_weapons về cùng instance Dictionary với InventorySystem để tránh lệch reference
	for inv_w in InventorySystem.get_weapons():
		forged_weapons.append(inv_w)
	for shelf_w in InventorySystem.get_shelf_weapons():
		if shelf_w not in forged_weapons:
			forged_weapons.append(shelf_w)
	if forged_weapons.is_empty() and data.has("forged_weapons") and data["forged_weapons"] is Array:
		for fw in data["forged_weapons"]:
			if fw is Dictionary:
				forged_weapons.append(fw)
	if data.has("equipped_weapons") and data["equipped_weapons"] is Array:
		var loaded_equipped: Array[Dictionary] = []
		var saved_equipped: Array = data["equipped_weapons"]
		for i in COMBAT_WEAPON_SLOTS:
			if i < saved_equipped.size() and saved_equipped[i] is Dictionary:
				loaded_equipped.append(saved_equipped[i])
			else:
				loaded_equipped.append({})
		equipped_weapons = loaded_equipped
	_rebind_equipped_weapons_to_inventory()
	if data.has("travel_stamina"):
		travel_stamina = clampi(int(data["travel_stamina"]), 0, max_travel_stamina)
	if data.has("tutorial_flags") and data["tutorial_flags"] is Dictionary:
		tutorial_flags = _merge_tutorial_flags(data["tutorial_flags"] as Dictionary)
	else:
		tutorial_flags = _get_default_tutorial_flags()
	if data.has("quest_statuses") and data["quest_statuses"] is Dictionary:
		quest_statuses = (data["quest_statuses"] as Dictionary).duplicate()
	else:
		quest_statuses = {}
	active_quest_id = String(data.get("active_quest_id", ""))
	if data.has("unlocked_recipe_ids") and data["unlocked_recipe_ids"] is Array:
		var loaded_recipes: Array[String] = []
		for rid in data["unlocked_recipe_ids"]:
			loaded_recipes.append(String(rid))
		unlocked_recipe_ids = loaded_recipes
	else:
		unlocked_recipe_ids = []
	if data.has("npc_affinities") and data["npc_affinities"] is Dictionary:
		npc_affinities = {}
		for k in (data["npc_affinities"] as Dictionary).keys():
			npc_affinities[String(k)] = int(data["npc_affinities"][k])
	else:
		npc_affinities = {}
	if data.has("sold_weapons_history") and data["sold_weapons_history"] is Array:
		var loaded_history: Array[Dictionary] = []
		for entry in data["sold_weapons_history"]:
			if entry is Dictionary:
				loaded_history.append((entry as Dictionary).duplicate(true))
		sold_weapons_history = loaded_history.slice(maxi(0, loaded_history.size() - MAX_SOLD_HISTORY))
	else:
		sold_weapons_history = []
	ensure_new_game_starter()
	DebtSystem.refresh_debt_summary()

	save_restored = true
	gold_changed.emit(gold)
	reputation_changed.emit(reputation)
	travel_stamina_changed.emit(travel_stamina, max_travel_stamina)
	day_changed.emit(current_day)
	phase_changed.emit(current_phase)


func build_save_state() -> Dictionary:
	var debt_states: Array[Dictionary] = []
	for checkpoint in DebtSystem.checkpoints:
		debt_states.append({
			"id": checkpoint.id,
			"is_paid": checkpoint.is_paid,
			"is_late": checkpoint.is_late,
			"has_notified": checkpoint.has_notified,
		})
	return {
		"day": current_day,
		"current_phase": current_phase,
		"gold": gold,
		"reputation": reputation,
		"smithing_mastery": smithing_mastery,
		"current_tier": current_tier,
		"artifact_count": artifact_count,
		"collected_artifact_ids": collected_artifact_ids.duplicate(),
		"travel_stamina": travel_stamina,
		"max_travel_stamina": max_travel_stamina,
		"unlocked_regions": unlocked_regions,
		"forged_weapons": forged_weapons,
		"equipped_weapons": equipped_weapons,
		"day_start_gold": day_start_gold,
		"consecutive_zero_gold_days": consecutive_zero_gold_days,
		"debt_checkpoints": debt_states,
		"npc_affinities": npc_affinities.duplicate(),
		"sold_weapons_history": sold_weapons_history.duplicate(true),
	}


# ══════════════════════════════════════════════════════════════════════════════
# NPC AFFINITY & WEAPON ECHO (CHẶNG 2)
# ══════════════════════════════════════════════════════════════════════════════

func get_npc_affinity(npc_id: String) -> int:
	if npc_id.is_empty():
		return 0
	return int(npc_affinities.get(npc_id, 0))


func add_npc_affinity(npc_id: String, delta: int) -> int:
	if npc_id.is_empty() or delta == 0:
		return get_npc_affinity(npc_id)
	var updated := clampi(get_npc_affinity(npc_id) + delta, -20, 100)
	npc_affinities[npc_id] = updated
	EventBus.npc_affinity_changed.emit(npc_id, updated)
	return updated


# 0 = Khách mới, 1 = Khách Quen (>= 15), 2 = Tri Kỷ Nhà Nghề (>= 35)
func get_npc_affinity_tier(npc_id: String) -> int:
	var aff := get_npc_affinity(npc_id)
	if aff >= 35:
		return 2
	if aff >= 15:
		return 1
	return 0


func record_sold_weapon(
		customer: Dictionary,
		weapon: Dictionary,
		sold_price: int,
		matched_pref: bool
) -> Dictionary:
	var prefix := String(weapon.get("phase2_prefix", ""))
	var is_cursed := prefix in CURSED_PREFIXES
	var record := {
		"npc_id": String(customer.get("type", customer.get("id", ""))),
		"npc_name": String(customer.get("name", "Khách")),
		"weapon_name": String(weapon.get("weapon_name", "Vũ Khí")),
		"blank_id": String(weapon.get("blank_id", "")),
		"phase2_prefix": prefix,
		"rarity_tier": int(weapon.get("rarity_tier", 1)),
		"perfect_quench": bool(weapon.get("perfect_quench", false)),
		"is_cursed": is_cursed,
		"matched_pref": matched_pref,
		"sold_price": sold_price,
		"sold_day": current_day,
		"echo_resolved": false,
	}
	sold_weapons_history.append(record)
	while sold_weapons_history.size() > MAX_SOLD_HISTORY:
		sold_weapons_history.pop_front()
	return record


func get_pending_echo_candidates() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for rec: Dictionary in sold_weapons_history:
		if bool(rec.get("echo_resolved", false)):
			continue
		if current_day >= int(rec.get("sold_day", 0)) + 2:
			candidates.append(rec)
	return candidates


func mark_echo_resolved(record: Dictionary) -> void:
	record["echo_resolved"] = true
	for rec: Dictionary in sold_weapons_history:
		if rec == record or (
			rec.get("npc_id", "") == record.get("npc_id", "")
			and rec.get("weapon_name", "") == record.get("weapon_name", "")
			and int(rec.get("sold_day", -1)) == int(record.get("sold_day", -2))
		):
			rec["echo_resolved"] = true
			break


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


func advance_day() -> void:
	DayCycle.advance_phase()


func _check_zero_gold_streak() -> void:
	if gold <= 0:
		consecutive_zero_gold_days += 1
	else:
		consecutive_zero_gold_days = 0
	if consecutive_zero_gold_days >= GAME_OVER_ZERO_GOLD_THRESHOLD:
		EventBus.game_over_triggered.emit("zero_gold_3_days")


# ══════════════════════════════════════════════════════════════════════════════
# TRAVEL STAMINA
# ══════════════════════════════════════════════════════════════════════════════

func get_entry_cost(region_id: String) -> int:
	var cost: int = REGION_ENTRY_COST.get(region_id, 2)
	return cost


func can_enter_region(region_id: String) -> bool:
	return travel_stamina >= get_entry_cost(region_id)


func consume_travel_stamina(amount: int = 1) -> bool:
	var cost: int = maxi(1, amount)
	if travel_stamina < cost:
		return false
	travel_stamina = maxi(0, travel_stamina - cost)
	travel_stamina_changed.emit(travel_stamina, max_travel_stamina)
	if travel_stamina == 0:
		EventBus.travel_stamina_depleted.emit()
	return true


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


func unlock_next_region_after(region_id: String) -> void:
	var next: String = REGION_UNLOCK_CHAIN.get(region_id, "")
	if not next.is_empty():
		unlock_region(next)


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
	_update_clear_region_quest(region_id)
	EventBus.region_cleared.emit(region_id)


func clear_exploration_state() -> void:
	exploration_state.clear()


# ══════════════════════════════════════════════════════════════════════════════
# QUESTS
# ══════════════════════════════════════════════════════════════════════════════

func trigger_quest_event(event_id: String) -> void:
	var quest := _load_first_artifact_quest()
	if quest == null:
		return
	if quest.trigger_type != "event" or quest.trigger_value != event_id:
		return
	_start_quest(quest)


func get_quest_hud_text() -> String:
	if not active_quest_id.is_empty():
		var active_quest := _load_first_artifact_quest()
		if active_quest == null:
			return ""
		return "[Quest: %s] %s" % [
			active_quest.quest_name,
			active_quest.journal_summary,
		]
	if _is_quest_completed(FIRST_ARTIFACT_QUEST_ID):
		var completed_quest := _load_first_artifact_quest()
		if completed_quest == null:
			return ""
		return "[Quest: %s] Hoàn thành — mở Bí Kíp Rèn đặc biệt" % (
			completed_quest.quest_name
		)
	return ""


func has_unlocked_recipe(recipe_id: String) -> bool:
	return recipe_id in unlocked_recipe_ids


func _start_quest(quest: QuestData) -> void:
	if _is_quest_completed(quest.quest_id):
		return
	if quest_statuses.get(quest.quest_id, QuestData.QuestStatus.LOCKED) \
			== QuestData.QuestStatus.ACTIVE:
		return
	quest_statuses[quest.quest_id] = QuestData.QuestStatus.ACTIVE
	active_quest_id = quest.quest_id
	EventBus.quest_started.emit(quest.quest_id)
	EventBus.quest_updated.emit()
	if _are_quest_objectives_complete(quest):
		_complete_quest(quest)


func _update_clear_region_quest(_region_id: String) -> void:
	if active_quest_id != FIRST_ARTIFACT_QUEST_ID:
		return
	var quest := _load_first_artifact_quest()
	if quest == null:
		return
	if _are_quest_objectives_complete(quest):
		_complete_quest(quest)


func _complete_quest(quest: QuestData) -> void:
	if _is_quest_completed(quest.quest_id):
		return
	quest_statuses[quest.quest_id] = QuestData.QuestStatus.COMPLETED
	if active_quest_id == quest.quest_id:
		active_quest_id = ""
	_grant_quest_reward(quest)
	EventBus.quest_completed.emit(quest.quest_id)
	EventBus.quest_updated.emit()


func collect_artifact(artifact_id: int) -> void:
	if artifact_id < 0 or artifact_id in collected_artifact_ids:
		return
	collected_artifact_ids.append(artifact_id)
	artifact_count += 1
	EventBus.artifact_collected.emit(artifact_id)


func _grant_quest_reward(quest: QuestData) -> void:
	if quest.reward_gold > 0:
		add_gold(quest.reward_gold)
	if quest.reward_reputation > 0:
		add_reputation(quest.reward_reputation)
	if quest.reward_artifact_id >= 0:
		collect_artifact(quest.reward_artifact_id)
	for item_id: String in quest.reward_item_ids:
		if item_id.is_empty():
			continue
		var item: ItemData = ItemDatabase.get_item(item_id)
		if item != null:
			var mat := {
				"item_id": item.item_id,
				"item_name": item.item_name,
				"rarity": item.rarity,
				"base_value": item.base_value,
				"item_type": item.item_type,
			}
			mat.merge(item.effect_data)
			InventorySystem.add_material(mat)
	if not quest.reward_recipe_id.is_empty() and quest.reward_recipe_id not in unlocked_recipe_ids:
		unlocked_recipe_ids.append(quest.reward_recipe_id)


func _are_quest_objectives_complete(quest: QuestData) -> bool:
	for objective: Dictionary in quest.objectives:
		match String(objective.get("type", "")):
			"clear_region":
				if not is_region_cleared(String(objective.get("value", ""))):
					return false
			_:
				return false
	return true


func _is_quest_completed(quest_id: String) -> bool:
	return quest_statuses.get(quest_id, QuestData.QuestStatus.LOCKED) \
		== QuestData.QuestStatus.COMPLETED


func _load_first_artifact_quest() -> QuestData:
	var quest := load(FIRST_ARTIFACT_QUEST_PATH) as QuestData
	if quest == null:
		push_warning("Không load được quest: " + FIRST_ARTIFACT_QUEST_PATH)
	return quest


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


func remove_weapon(weapon: Dictionary) -> void:
	forged_weapons.erase(weapon)
	var uid := String(weapon.get("uid", ""))
	if uid.is_empty():
		return
	for i in range(forged_weapons.size() - 1, -1, -1):
		if String(forged_weapons[i].get("uid", "")) == uid:
			forged_weapons.remove_at(i)
			break


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
		"uid": "starter_hammer",
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


func _rebind_equipped_weapons_to_inventory() -> void:
	var inv_weapons := InventorySystem.get_weapons()
	var used_indices: Array[int] = []
	for slot_idx in equipped_weapons.size():
		var eq: Dictionary = equipped_weapons[slot_idx]
		if eq.is_empty():
			continue
		var matched_inv := false
		for inv_idx in inv_weapons.size():
			if inv_idx in used_indices:
				continue
			if _same_weapon_signature(eq, inv_weapons[inv_idx]):
				equipped_weapons[slot_idx] = inv_weapons[inv_idx]
				used_indices.append(inv_idx)
				matched_inv = true
				break
		if not matched_inv:
			equipped_weapons[slot_idx] = {}


func _same_weapon_signature(a: Dictionary, b: Dictionary) -> bool:
	var uid_a := String(a.get("uid", ""))
	var uid_b := String(b.get("uid", ""))
	if not uid_a.is_empty() and not uid_b.is_empty():
		return uid_a == uid_b
	return (
		a.get("weapon_name", "") == b.get("weapon_name", "")
		and a.get("blank_id", "") == b.get("blank_id", "")
		and int(a.get("atk", 0)) == int(b.get("atk", 0))
		and int(a.get("rarity_tier", 0)) == int(b.get("rarity_tier", 0))
		and int(a.get("durability", 50)) == int(b.get("durability", 50))
		and String(a.get("element", "")) == String(b.get("element", ""))
		and String(a.get("phase2_prefix", "")) == String(b.get("phase2_prefix", ""))
	)


func _enter_tree() -> void:
	call_deferred("_fit_initial_window")


func _fit_initial_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var win := get_window()
	if win == null or win.is_embedded():
		return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
	var screen_idx := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen_idx)
	if usable.size.x <= 0 or usable.size.y <= 0:
		return
	var max_w := int(usable.size.x * 0.90)
	var max_h := int(usable.size.y * 0.88)
	var target_w := mini(1280, max_w)
	var target_h := int(round(float(target_w) * 9.0 / 16.0))
	if target_h > max_h:
		target_h = max_h
		target_w = int(round(float(target_h) * 16.0 / 9.0))
	var final_size := Vector2i(maxi(640, target_w), maxi(360, target_h))
	win.size = final_size
	win.position = usable.position + (usable.size - final_size) / 2


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key_ev := event as InputEventKey
	var is_f11 := key_ev.keycode == KEY_F11
	var is_alt_enter := (
		(key_ev.keycode == KEY_ENTER or key_ev.keycode == KEY_KP_ENTER)
		and key_ev.alt_pressed
	)
	if is_f11 or is_alt_enter:
		toggle_fullscreen()
		get_viewport().set_input_as_handled()


func toggle_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		call_deferred("_fit_initial_window")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
