class_name ForgeConverter

# Chuyển đổi dữ liệu rèn (forge output) sang Dictionary dùng được trong combat.
# Không có state — tất cả hàm đều static.

const P1_MULTIPLIERS: Dictionary = {
	"lanh":   0.7,   # −30%
	"cam":    1.2,   # +20%
	"do_ruc": 1.4,   # +40%
	"chay":   0.5,   # −50%
}

const PREFIX_NAMES: Dictionary = {
	"phan_chu":    "Phản Chủ",
	"curse_nang":  "Lời Nguyền",
	"curse_nhe":   "Nguyền Nhẹ",
	"thuong":      "Bén Ngọt",
	"tot":         "Kiên Cố",
	"nang_tay":    "Nặng Tay",
	"than_toc":    "Thần Tốc",
	"kiet_tac":    "Kiệt Tác",
	"can_bang":    "Cân Bằng",
	"to_nghe":     "Tổ Nghề",
	"huyen_bi":    "Huyền Bí",
	"cung_nhu_da": "Cứng Như Đá",
	"khi_phach":   "Khí Phách",
	"truong_sinh": "Trường Sinh",
	"perfect":     "Hào Kiệt",
}

const PREFIX_RARITY: Dictionary = {
	"phan_chu":    1,
	"curse_nang":  1,
	"curse_nhe":   1,
	"thuong":      2,
	"tot":         2,
	"nang_tay":    2,
	"than_toc":    2,
	"kiet_tac":    3,
	"can_bang":    3,
	"to_nghe":     3,
	"huyen_bi":    3,
	"cung_nhu_da": 4,
	"khi_phach":   4,
	"truong_sinh": 5,
	"perfect":     5,
}


## Nguồn sự thật duy nhất cho giá bán vũ khí.
## Dùng chung bởi weapon_card_ui (hiển thị) và negotiation_ui (shop).
static func weapon_sell_value(
	atk: int,
	magic: int,
	speed: int,
	rarity_tier: int,
	price_mult: float = 1.0
) -> int:
	return int((atk * 40 + magic * 30 + rarity_tier * 120 + speed * 10 + 200) * price_mult)


## Chỉ số sức mạnh tổng hợp để hiển thị và so sánh — không dùng trong combat logic.
static func weapon_combat_power(atk: int, def_stat: int, magic: int, speed: int) -> int:
	return atk * 3 + magic * 2 + def_stat + speed


## Nhận forge_data từ GameManager.forged_weapons, trả về combat-ready weapon Dict.
## forge_data cần có: phase1_tier, phase2_prefix, suffix, element_name,
##   base_atk, base_def, base_magic, base_speed, weapon_type, blank_id
static func forge_to_combat(fd: Dictionary) -> Dictionary:
	var p1_tier:   String = fd.get("phase1_tier",   "cam")
	var p2_prefix: String = fd.get("phase2_prefix", "thuong")
	var suffix:    String = fd.get("suffix",        "")
	var blank_id:  String = fd.get("blank_id",      "")

	var p1_mult: float = P1_MULTIPLIERS.get(p1_tier, 1.0)

	# Phase 1 nhân ATK, DEF, Magic — Speed là tốc độ chiến đấu, không phụ thuộc nhiệt
	# TODO: PHASE2_BONUS is applied in weapon_card_ui preview but NOT here.
	# Combat stats and preview stats currently diverge. Fix in next pass.
	var atk:        int   = maxi(1, int(fd.get("base_atk",   10) * p1_mult))
	var def_s:      int   = maxi(0, int(fd.get("base_def",    0) * p1_mult))
	var magic:      int   = maxi(0, int(fd.get("base_magic",  0) * p1_mult))
	var speed:      int   = fd.get("base_speed", 5)
	var price_mult: float = fd.get("price_mult", 1.0)
	var rar_tier:   int   = PREFIX_RARITY.get(p2_prefix, 2)

	return {
		"weapon_name":    _build_name(fd),
		"blank_id":       blank_id,
		"blank_name":     fd.get("weapon_type", "Vũ Khí"),
		"atk":            atk,
		"def_stat":       def_s,
		"magic":          magic,
		"speed":          speed,
		"skill1":         _prefix_to_skill(p2_prefix),
		"skill2":         _suffix_to_skill(suffix),
		"rarity_tier":    rar_tier,
		"phase1_tier":    p1_tier,
		"phase2_prefix":  p2_prefix,
		"element":        fd.get("element",      ""),
		"element_name":   fd.get("element_name", ""),
		"durability":      50,
		"durability_max":  50,
		"sell_value":      weapon_sell_value(atk, magic, speed, rar_tier, price_mult),
		"combat_power":    weapon_combat_power(atk, def_s, magic, speed),
	}


static func _build_name(fd: Dictionary) -> String:
	var prefix_name: String = PREFIX_NAMES.get(fd.get("phase2_prefix", "thuong"), "Thường")
	var blank_name:  String = fd.get("weapon_type",  "Vũ Khí")
	var elem_name:   String = fd.get("element_name", "")
	if elem_name.is_empty():
		return "%s %s" % [prefix_name, blank_name]
	return "%s %s · %s" % [prefix_name, blank_name, elem_name]


# ── Prefix → Skill 1 ─────────────────────────────────────────────────────────
# Mapping theo GDD Section 5.3 "Skills từ Prefix" — 12 prefix + curse
static func _prefix_to_skill(prefix: String) -> Dictionary:
	match prefix:
		"thuong":      # Bén Ngọt — Slash +50% dmg
			return {
				"name": "Slash", "stamina_cost": 1,
				"effect": "DAMAGE", "damage_mult": 1.5, "dice": 0,
			}
		"tot":         # Kiên Cố — Iron Wall +5 DEF 2 lượt
			return {
				"name": "Iron Wall", "stamina_cost": 1,
				"effect": "BUFF_DEF", "def_bonus": 5, "def_bonus_turns": 2,
			}
		"nang_tay":    # Nặng Tay — Crushing Blow +100% dmg, mất lượt sau
			return {
				"name": "Crushing Blow", "stamina_cost": 2,
				"effect": "DAMAGE_SKIP_TURN", "damage_mult": 2.0, "dice": 0,
				"skip_self_next_turn": true,
			}
		"than_toc":    # Thần Tốc — Double Strike đánh 2 lần
			return {
				"name": "Double Strike", "stamina_cost": 2,
				"effect": "DAMAGE_TWICE", "damage_mult": 1.0, "dice": 0,
			}
		"kiet_tac":    # Kiệt Tác — Master's Form +30% dmg +10 HP
			return {
				"name": "Master's Form", "stamina_cost": 2,
				"effect": "DAMAGE_HEAL", "damage_mult": 1.3, "dice": 0, "heal_flat": 10,
			}
		"can_bang":    # Cân Bằng — Balanced Stance +15% mọi stat 2 lượt
			return {
				"name": "Balanced Stance", "stamina_cost": 1,
				"effect": "BUFF_ALL_STATS", "stat_bonus_pct": 0.15, "stat_bonus_turns": 2,
			}
		"to_nghe":     # Tổ Nghề — Ancestral Echo +25% dmg, thưởng 50G nếu thắng
			return {
				"name": "Ancestral Echo", "stamina_cost": 1,
				"effect": "DAMAGE", "damage_mult": 1.25, "dice": 0,
				"gold_bonus_on_win": 50,
			}
		"huyen_bi":    # Huyền Bí — Arcane Blade damage = Magic thay ATK
			return {
				"name": "Arcane Blade", "stamina_cost": 1,
				"effect": "DAMAGE", "damage_mult": 1.0, "dice": 0,
				"use_magic": true,
			}
		"cung_nhu_da": # Cứng Như Đá — Stone Form miễn 1 đòn
			return {
				"name": "Stone Form", "stamina_cost": 2,
				"effect": "SHIELD_ONE_HIT",
			}
		"khi_phach":   # Khí Phách — Heroic Shout -1 ATK địch 3 lượt
			return {
				"name": "Heroic Shout", "stamina_cost": 1,
				"effect": "DEBUFF_ATK", "atk_penalty": 1, "atk_penalty_turns": 3,
			}
		"truong_sinh": # Trường Sinh — Eternal không mất Durability trong trận
			return {
				"name": "Eternal", "stamina_cost": 0,
				"effect": "PASSIVE_NO_DURABILITY",
			}
		"perfect":     # Hào Kiệt — Hero's Edge +50% dmg, +1 Reputation nếu thắng
			return {
				"name": "Hero's Edge", "stamina_cost": 2,
				"effect": "DAMAGE", "damage_mult": 1.5, "dice": 0,
				"rep_bonus_on_win": 1,
			}
		"curse_nhe":   # Nguyền Nhẹ — Slash yếu hơn
			return {
				"name": "Slash", "stamina_cost": 1,
				"effect": "DAMAGE", "damage_mult": 1.2, "dice": 0,
			}
		_:             # Phản Chủ, Lời Nguyền — không có skill
			return {}


# ── Suffix → Skill 2 ─────────────────────────────────────────────────────────
# Mapping theo GDD Section 5.3 "Skills từ Suffix Linh Lực"
static func _suffix_to_skill(suffix: String) -> Dictionary:
	match suffix:
		"thieu_dot":   # Hỏa — Burn
			return {
				"name": "Burn", "stamina_cost": 2,
				"effect": "DAMAGE_STATUS", "damage_mult": 1.0, "dice": 0,
				"status": "burn", "status_turns": 2, "status_dmg": 4,
			}
		"bang_gia":    # Băng — Freeze
			return {
				"name": "Băng Giá", "stamina_cost": 2,
				"effect": "DAMAGE_STATUS", "damage_mult": 0.8, "dice": 0,
				"status": "freeze", "status_turns": 1, "effect_chance": 0.5,
			}
		"sam_set":     # Sét — Chain Lightning bỏ qua 50% DEF
			return {
				"name": "Sấm Sét", "stamina_cost": 2,
				"effect": "DAMAGE", "damage_mult": 1.0, "dice": 0, "ignore_def": 0.5,
			}
		"dao_dong":    # Thổ — Poison Cloud (Độc)
			return {
				"name": "Độc Vân", "stamina_cost": 1,
				"effect": "DAMAGE_STATUS", "damage_mult": 0.6, "dice": 0,
				"status": "poison", "status_turns": 3, "effect_chance": 1.0,
			}
		"cuong_phong": # Phong — Cuồng Phong dmg + dice
			return {
				"name": "Cuồng Phong", "stamina_cost": 1,
				"effect": "DAMAGE", "damage_mult": 1.0, "dice": 6,
			}
		"hu_khong":    # Hư Không — Shadow Strike bỏ qua 100% DEF
			return {
				"name": "Shadow Strike", "stamina_cost": 2,
				"effect": "DAMAGE", "damage_mult": 1.0, "dice": 0, "ignore_def": 1.0,
			}
		_:
			return {}
