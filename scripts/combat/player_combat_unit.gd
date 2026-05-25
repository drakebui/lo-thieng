# player_combat_unit.gd
# Mở rộng Combatant với 3 weapon slots và logic equip/switch.
# Vũ khí quyết định ATK/Magic/Speed/Skill 1/Skill 2.
# HP và Stamina là stat riêng của player, không thay đổi khi đổi vũ khí.
# Đổi vũ khí tốn 1 lượt (switch_weapon trả về COST_TURN để combat_manager xử lý).
class_name PlayerCombatUnit
extends Combatant

# ══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ══════════════════════════════════════════════════════════════════════════════

signal weapon_equipped(slot_idx: int, weapon: Dictionary)
signal weapon_unequipped(slot_idx: int)
signal weapon_switched(from_slot: int, to_slot: int)

# ══════════════════════════════════════════════════════════════════════════════
# SWITCH RESULT — trả về từ switch_weapon()
# ══════════════════════════════════════════════════════════════════════════════

enum SwitchResult {
	OK,         # đổi thành công, tốn 1 lượt
	SAME_SLOT,  # đã ở slot đó rồi, không làm gì
	EMPTY_SLOT, # slot trống, không thể đổi
}

# ══════════════════════════════════════════════════════════════════════════════
# BASE STATS — stat của player, không bị vũ khí thay đổi
# ══════════════════════════════════════════════════════════════════════════════

const BASE_HP:             int = 50
const BASE_STAMINA:        int = 5
const BASE_DEF:            int = 2   # giáp cơ bản, vũ khí cộng thêm nếu có
const STAMINA_REGEN:       int = 1   # hồi mỗi lượt PLAYER_TURN

# ══════════════════════════════════════════════════════════════════════════════
# WEAPON SLOTS
# ══════════════════════════════════════════════════════════════════════════════

# 3 slot vũ khí; Dictionary rỗng = ô trống
# Cấu trúc weapon Dictionary:
#   "weapon_name"  : String  — tên hiển thị đầy đủ
#   "blank_id"     : String  — id phôi ("kiem_don", "bua_chien"...)
#   "blank_name"   : String  — tên phôi hiển thị
#   "atk"          : int
#   "def_stat"     : int     — def bonus từ vũ khí (cộng với BASE_DEF)
#   "magic"        : int
#   "speed"        : int
#   "skill1"       : Dictionary  — prefix skill (có "name", "stamina_cost", "effect"...)
#   "skill2"       : Dictionary  — suffix/element skill
#   "innate_skill" : String  — tên skill bẩm sinh từ loại phôi (info only)
#   "rarity_tier"  : int     — 1-5
var weapon_slots: Array[Dictionary] = [{}, {}, {}]

# Index slot đang active (0, 1, 2)
var active_slot: int = 0

# ══════════════════════════════════════════════════════════════════════════════
# INIT
# ══════════════════════════════════════════════════════════════════════════════

func setup_player(player_name: String = "Thợ Rèn") -> void:
	combatant_name = player_name
	is_player      = true
	hp             = BASE_HP
	max_hp         = BASE_HP
	stamina        = BASE_STAMINA
	max_stamina    = BASE_STAMINA
	_clear_weapon_stats()


# ══════════════════════════════════════════════════════════════════════════════
# EQUIP / UNEQUIP
# ══════════════════════════════════════════════════════════════════════════════

# Trang bị vũ khí vào slot. Nếu slot đó đang active → cập nhật stats ngay.
func equip_weapon(slot_idx: int, weapon: Dictionary) -> void:
	assert(slot_idx >= 0 and slot_idx < 3, "slot_idx phải là 0, 1 hoặc 2")
	weapon_slots[slot_idx] = weapon
	if slot_idx == active_slot:
		_apply_weapon_stats()
	weapon_equipped.emit(slot_idx, weapon)


# Tháo vũ khí khỏi slot. Nếu slot đó đang active → về stat trần.
func unequip_weapon(slot_idx: int) -> void:
	assert(slot_idx >= 0 and slot_idx < 3)
	weapon_slots[slot_idx] = {}
	if slot_idx == active_slot:
		_clear_weapon_stats()
	weapon_unequipped.emit(slot_idx)


# ══════════════════════════════════════════════════════════════════════════════
# SWITCH
# ══════════════════════════════════════════════════════════════════════════════

# Chuyển sang slot khác. Trả về SwitchResult để combat_manager xử lý "tốn lượt".
func switch_weapon(to_slot: int) -> SwitchResult:
	if to_slot == active_slot:
		return SwitchResult.SAME_SLOT
	if weapon_slots[to_slot].is_empty():
		return SwitchResult.EMPTY_SLOT

	var from_slot := active_slot
	active_slot   = to_slot
	_apply_weapon_stats()
	weapon_switched.emit(from_slot, to_slot)
	return SwitchResult.OK


# Vòng lặp qua slot tiếp theo có vũ khí (tiện dụng cho UI "Next Weapon")
func switch_to_next_slot() -> SwitchResult:
	for offset in [1, 2]:
		var candidate: int = (active_slot + offset) % 3
		if not weapon_slots[candidate].is_empty():
			return switch_weapon(candidate)
	return SwitchResult.EMPTY_SLOT


# ══════════════════════════════════════════════════════════════════════════════
# QUERIES
# ══════════════════════════════════════════════════════════════════════════════

func get_active_weapon() -> Dictionary:
	return weapon_slots[active_slot]

func get_slot_weapon(slot_idx: int) -> Dictionary:
	return weapon_slots[slot_idx]

func is_slot_empty(slot_idx: int) -> bool:
	return weapon_slots[slot_idx].is_empty()

func count_equipped() -> int:
	var n := 0
	for w in weapon_slots:
		if not w.is_empty():
			n += 1
	return n

# Trả về String mô tả ngắn của slot (dùng trong UI)
func slot_label(slot_idx: int) -> String:
	var w: Dictionary = weapon_slots[slot_idx]
	if w.is_empty():
		return "[ Trống ]"
	var marker := " ◀" if slot_idx == active_slot else ""
	return "%s%s" % [w.get("weapon_name", "???"), marker]

# ══════════════════════════════════════════════════════════════════════════════
# STAMINA
# ══════════════════════════════════════════════════════════════════════════════

# Gọi mỗi đầu PLAYER_TURN
func regen_stamina() -> int:
	var before := stamina
	stamina = min(max_stamina, stamina + STAMINA_REGEN)
	return stamina - before  # lượng thực tế hồi được

func can_use_skill(skill: Dictionary) -> bool:
	return stamina >= skill.get("stamina_cost", 0) and not skill.is_empty()

func spend_stamina(amount: int) -> void:
	stamina = max(0, stamina - amount)

# ══════════════════════════════════════════════════════════════════════════════
# INTERNAL — sync stats từ vũ khí active
# ══════════════════════════════════════════════════════════════════════════════

func _apply_weapon_stats() -> void:
	var w: Dictionary = weapon_slots[active_slot]
	if w.is_empty():
		_clear_weapon_stats()
		return

	# Vũ khí hỏng (durability = 0) → toàn bộ stat ×0.5
	var mult: float = 0.5 if w.get("durability", 1) <= 0 else 1.0
	atk      = maxi(1, int(w.get("atk",      8) * mult))
	def_stat = BASE_DEF + maxi(0, int(w.get("def_stat", 0) * mult))
	magic    = maxi(0, int(w.get("magic",    0) * mult))
	speed    = w.get("speed",    5)
	skill1   = w.get("skill1",   {})
	skill2   = w.get("skill2",   {})

# Trừ 1 Durability khi dùng skill. Trả về true nếu vũ khí vừa hỏng.
# Vũ khí Trường Sinh (PASSIVE_NO_DURABILITY) được miễn.
func spend_durability() -> bool:
	var w := weapon_slots[active_slot]
	if w.is_empty():
		return false
	if w.get("skill1", {}).get("effect", "") == "PASSIVE_NO_DURABILITY":
		return false
	var dur: int = w.get("durability", 50)
	if dur <= 0:
		return false
	dur -= 1
	w["durability"] = dur
	weapon_slots[active_slot] = w
	if dur == 0:
		_apply_weapon_stats()  # re-apply với mult=0.5
		return true
	return false


func _clear_weapon_stats() -> void:
	atk      = 0
	def_stat = BASE_DEF
	magic    = 0
	speed    = 5
	skill1   = {}
	skill2   = {}

# ══════════════════════════════════════════════════════════════════════════════
# STATIC FACTORY — tạo mock weapon để test (không cần qua forge)
# ══════════════════════════════════════════════════════════════════════════════

static func make_mock_weapon(
		weapon_name:  String,
		blank_id:     String,
		atk:          int,
		def_bonus:    int,
		magic:        int,
		speed:        int,
		skill1:       Dictionary,
		skill2:       Dictionary,
		rarity:       int = 2
) -> Dictionary:
	return {
		"weapon_name":   weapon_name,
		"blank_id":      blank_id,
		"blank_name":    blank_id.replace("_", " ").capitalize(),
		"atk":           atk,
		"def_stat":      def_bonus,
		"magic":         magic,
		"speed":         speed,
		"skill1":        skill1,
		"skill2":        skill2,
		"rarity_tier":   rarity,
		"durability":     50,
		"durability_max": 50,
	}

# Tạo player với vũ khí mock sẵn để test combat nhanh
static func make_for_test() -> PlayerCombatUnit:
	var p := PlayerCombatUnit.new()
	p.setup_player("Thợ Rèn")

	var slash_skill := {
		"name": "Slash", "stamina_cost": 1,
		"effect": "DAMAGE", "damage_mult": 1.5, "dice": 0,
	}
	var burn_skill := {
		"name": "Burn", "stamina_cost": 2,
		"effect": "DAMAGE_STATUS", "damage_mult": 1.0, "dice": 0,
		"status": "burn", "status_turns": 2, "status_dmg": 4,
	}
	var master_form := {
		"name": "Master's Form", "stamina_cost": 2,
		"effect": "DAMAGE_HEAL", "damage_mult": 1.3, "dice": 0, "heal_flat": 10,
	}
	var iron_wall := {
		"name": "Iron Wall", "stamina_cost": 1,
		"effect": "BUFF_DEF", "def_bonus": 5, "def_bonus_turns": 2,
	}
	var freeze_skill := {
		"name": "Băng Giá", "stamina_cost": 2,
		"effect": "DAMAGE_STATUS", "damage_mult": 0.8, "dice": 0,
		"status": "freeze", "status_turns": 1, "effect_chance": 0.5,
	}

	# Slot 0: Kiệt Tác Kiếm Đơn · Hỏa (Slash + Burn)
	p.equip_weapon(0, make_mock_weapon(
		"Kiệt Tác Kiếm Đơn · Thiêu Đốt",
		"kiem_don", 16, 0, 4, 8,
		slash_skill, burn_skill, 3
	))
	# Slot 1: Tốt Búa Chiến · Sét (Master's Form + Iron Wall)
	p.equip_weapon(1, make_mock_weapon(
		"Tốt Búa Chiến · Sấm Sét",
		"bua_chien", 18, 3, 0, 4,
		master_form, iron_wall, 2
	))
	# Slot 2: Thường Gậy Phép · Băng (Freeze + empty fallback)
	p.equip_weapon(2, make_mock_weapon(
		"Thường Gậy Phép · Băng Giá",
		"gay_phep", 5, 0, 12, 5,
		freeze_skill, burn_skill, 1
	))

	return p
