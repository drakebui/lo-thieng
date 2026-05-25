# scripts/systems/CustomerTagSystem.gd
# Định nghĩa toàn bộ tag hợp lệ + logic matching khách với vũ khí
# Đặt tại: res://scripts/systems/CustomerTagSystem.gd
# Dùng: CustomerTagSystem.score_weapon_for_npc(weapon, npc)
#        CustomerTagSystem.get_tag_description(tag)

class_name CustomerTagSystem
extends Node

# ═══════════════════════════════════════════════════════════════
# PHẦN 1 — ĐỊNH NGHĨA TẤT CẢ TAGS HỢP LỆ
# ═══════════════════════════════════════════════════════════════
#
# Tag chia làm 4 nhóm:
#   A. CUSTOMER_TYPE  — loại khách hàng (map với blank phôi)
#   B. PREFIX_TAG     — prefix vũ khí khách thích/ghét
#   C. SUFFIX_TAG     — suffix/element khách thích/ghét
#   D. QUALITY_TAG    — chất lượng tổng thể của vũ khí
#
# Mỗi tag trong preferred_weapon_tags → +điểm
# Mỗi tag trong disliked_weapon_tags  → -điểm hoặc từ chối mua

# ── A. CUSTOMER TYPE TAGS ───────────────────────────────────
# Map trực tiếp với preferred_customers[] trong Phôi (ItemDatabase)

const CUSTOMER_TYPE_TAGS := {
	"HiepKhach": {
		"label":       "Hiệp Khách",
		"desc":        "Thích vũ khí linh hoạt, tốc độ cao. Phôi phù hợp: Kiếm Đơn, Giáo Dài.",
		"blank_ids":   ["phoi_kiem_don", "phoi_giao_dai"],
		"score_bonus": 30,       # Điểm thưởng nếu phôi đúng loại
	},
	"ThichKhach": {
		"label":       "Thích Khách",
		"desc":        "Thích vũ khí nhẹ, song đao, sát thương nhanh. "
			+ "Phôi: Song Đao, Liềm Song, Côn, Nỏ.",
		"blank_ids":   ["phoi_song_dao", "phoi_liem_song", "phoi_con_hai_khuc", "phoi_no_ban"],
		"score_bonus": 30,
	},
	"ThuVe": {
		"label":       "Thủ Vệ",
		"desc":        "Thích vũ khí phòng thủ cao, DEF là ưu tiên. Phôi: Khiên, Giáo, Búa, Đao Phạt.",
		"blank_ids":   [
			"phoi_khien_dong", "phoi_giao_dai",
			"phoi_bua_chien", "phoi_dao_phat"
		],
		"score_bonus": 30,
	},
	"VoTang": {
		"label":       "Võ Tăng",
		"desc":        "Thích vũ khí gần, đòn combo. Phôi: Quyền Cụ, Côn Nhị Khúc, Búa.",
		"blank_ids":   ["phoi_quyen_cu", "phoi_con_hai_khuc", "phoi_bua_chien"],
		"score_bonus": 30,
	},
	"DaoSi": {
		"label":       "Đạo Sĩ",
		"desc":        "Thích vũ khí phép, Magic cao. Phôi: Gậy Phép. Ưu tiên suffix phép.",
		"blank_ids":   ["phoi_gay_phep"],
		"score_bonus": 30,
	},
	"ThoSan": {
		"label":       "Thợ Săn",
		"desc":        "Thích vũ khí tầm xa. Phôi: Cung Trường, Nỏ Bắn.",
		"blank_ids":   ["phoi_cung_truong", "phoi_no_ban"],
		"score_bonus": 30,
	},
}

# ── B. PREFIX TAGS ──────────────────────────────────────────
# Khớp với skill_id trong SkillDatabase

const PREFIX_TAGS := {
	"prefix_ben_ngot": {
		"label":       "Bén Ngọt",
		"skill_id":    "ben_ngot",
		"desc":        "Slash +50% damage. Hiệp Khách, Thích Khách ưa.",
		"score_bonus": 20,
	},
	"prefix_kien_co": {
		"label":       "Kiên Cố",
		"skill_id":    "kien_co",
		"desc":        "Iron Wall +5 DEF/2 lượt. Thủ Vệ ưa.",
		"score_bonus": 20,
	},
	"prefix_nang_tay": {
		"label":       "Nặng Tay",
		"skill_id":    "nang_tay",
		"desc":        "Crushing Blow +100% damage, mất lượt sau. Võ Tăng ưa, Đạo Sĩ ghét.",
		"score_bonus": 20,
	},
	"prefix_than_toc": {
		"label":       "Thần Tốc",
		"skill_id":    "than_toc",
		"desc":        "Double Strike đánh 2 lần. Thích Khách, Hiệp Khách ưa.",
		"score_bonus": 20,
	},
	"prefix_kiet_tac": {
		"label":       "Kiệt Tác",
		"skill_id":    "kiet_tac",
		"desc":        "Master's Form +30% dmg +10 HP. VIP ưa, giá bán cao.",
		"score_bonus": 25,
	},
	"prefix_can_bang": {
		"label":       "Cân Bằng",
		"skill_id":    "can_bang",
		"desc":        "Balanced Stance +15% mọi stat. Võ Tăng ưa.",
		"score_bonus": 20,
	},
	"prefix_to_nghe": {
		"label":       "Tổ Nghề",
		"skill_id":    "to_nghe",
		"desc":        "Ancestral Echo +25% dmg +50G khi thắng. VIP, collector ưa.",
		"score_bonus": 25,
	},
	"prefix_huyen_bi": {
		"label":       "Huyền Bí",
		"skill_id":    "huyen_bi",
		"desc":        "Arcane Blade damage = Magic. Đạo Sĩ ưa.",
		"score_bonus": 20,
	},
	"prefix_cung_nhu_da": {
		"label":       "Cứng Như Đá",
		"skill_id":    "cung_nhu_da",
		"desc":        "Stone Form miễn 1 đòn. Thủ Vệ ưa.",
		"score_bonus": 20,
	},
	"prefix_khi_phach": {
		"label":       "Khí Phách",
		"skill_id":    "khi_phach",
		"desc":        "Heroic Shout -1 ATK enemy/3 lượt. Hiệp Khách ưa.",
		"score_bonus": 20,
	},
	"prefix_truong_sinh": {
		"label":       "Trường Sinh",
		"skill_id":    "truong_sinh",
		"desc":        "Eternal không mất Durability. Mọi loại khách đều ưa.",
		"score_bonus": 30,
	},
	"prefix_hao_kiet": {
		"label":       "Hào Kiệt",
		"skill_id":    "hao_kiet",
		"desc":        "Hero's Edge +50% dmg +1 Reputation. VIP, chiến binh ưa.",
		"score_bonus": 25,
	},
}

# ── C. SUFFIX / ELEMENT TAGS ────────────────────────────────
# Khớp với element_type trong Linh Lực

const SUFFIX_TAGS := {
	"suffix_hoa": {
		"label":       "Lửa (Hỏa)",
		"skill_id":    "suffix_hoa",
		"desc":        "Burn 4 dmg/lượt. Võ Tăng, Thích Khách ưa. Thủ Thánh ghét.",
		"score_bonus": 15,
	},
	"suffix_bang": {
		"label":       "Băng",
		"skill_id":    "suffix_bang",
		"desc":        "Freeze 50% miss chance. Thợ Săn, Đạo Sĩ ưa.",
		"score_bonus": 15,
	},
	"suffix_set": {
		"label":       "Sét",
		"skill_id":    "suffix_set",
		"desc":        "Chain Lightning xuyên 50% DEF. Đạo Sĩ, Thích Khách ưa.",
		"score_bonus": 15,
	},
	"suffix_doc": {
		"label":       "Độc",
		"skill_id":    "suffix_doc",
		"desc":        "Poison 5% HP/lượt. Thích Khách ưa. Thủ Vệ, Võ Tăng ghét.",
		"score_bonus": 15,
	},
	"suffix_thanh": {
		"label":       "Thánh",
		"skill_id":    "suffix_thanh",
		"desc":        "Heal Pulse hồi 30% HP. Võ Tăng, Thủ Vệ ưa. Bóng Tối không hợp.",
		"score_bonus": 15,
	},
	"suffix_bong_toi": {
		"label":       "Bóng Tối",
		"skill_id":    "suffix_bong_toi",
		"desc":        "Shadow Strike xuyên 100% DEF. Thích Khách ưa. Thủ Thánh ghét.",
		"score_bonus": 15,
	},
}

# ── D. QUALITY TAGS ─────────────────────────────────────────
# Dựa trên kết quả rèn, không phải loại vũ khí

const QUALITY_TAGS := {
	"Mastery": {
		"label":       "Mastery",
		"desc":        "Vũ khí đã qua boss test, stats x1.5. VIP bắt buộc phải có.",
		"score_bonus": 50,
		"required_by": ["ba_thien_kim", "hoi_dong_tho_ren", "ve_binh_hoang_gia"],
	},
	"Curse": {
		"label":       "Curse (Lời Nguyền)",
		"desc":        "Vũ khí bị nguyền từ Phase 2 thất bại. Hầu hết khách ghét.",
		"score_penalty": -40,   # Điểm trừ khi vũ khí bị Curse
	},
	"HighATK": {
		"label":       "ATK Cao (≥15)",
		"desc":        "ATK từ 15 trở lên. Chiến binh ưa.",
		"score_bonus": 15,
		"threshold":   15,
	},
	"HighDEF": {
		"label":       "DEF Cao (≥10)",
		"desc":        "DEF từ 10 trở lên. Thủ Vệ ưa.",
		"score_bonus": 15,
		"threshold":   10,
	},
	"HighMagic": {
		"label":       "Magic Cao (≥10)",
		"desc":        "Magic từ 10 trở lên. Đạo Sĩ ưa.",
		"score_bonus": 15,
		"threshold":   10,
	},
	"LowDurability": {
		"label":       "Durability Thấp (<20)",
		"desc":        "Độ bền dưới 20. Mọi khách đều giảm hứng thú.",
		"score_penalty": -25,
		"threshold":   20,
	},
	"PerfectForge": {
		"label":       "Rèn Hoàn Hảo (Phase 1 Vàng Kim)",
		"desc":        "Phase 1 đạt Vàng Kim (+40%). VIP trả giá cao hơn.",
		"score_bonus": 20,
	},
}

# ── ALL VALID TAGS (tập hợp để validate) ───────────────────
static func get_all_valid_tags() -> Array[String]:
	var tags: Array[String] = []
	tags.append_array(CUSTOMER_TYPE_TAGS.keys())
	tags.append_array(PREFIX_TAGS.keys())
	tags.append_array(SUFFIX_TAGS.keys())
	tags.append_array(QUALITY_TAGS.keys())
	return tags


# ═══════════════════════════════════════════════════════════════
# PHẦN 2 — MATCHING LOGIC
# Tính điểm "độ phù hợp" của 1 vũ khí với 1 NPC
# ═══════════════════════════════════════════════════════════════

## Kết quả matching trả về Dictionary để shop_manager dễ dùng
## {
##   "score":       int,     # Điểm tổng (âm = khách ghét, dương = khách thích)
##   "will_buy":    bool,    # Khách có xem xét mua không
##   "hard_reject": bool,    # Từ chối ngay (Curse hoặc disliked quá nặng)
##   "price_mult":  float,   # Hệ số giá khách chấp nhận (0.8 - 1.4)
##   "reasons":     Array,   # Danh sách lý do (debug + dialogue hint)
## }

static func score_weapon_for_npc(weapon: WeaponData, npc: NPCData) -> Dictionary:
	var score: int = 0
	var reasons: Array[String] = []
	var hard_reject: bool = false

	# ── 1. Check CUSTOMER TYPE (blank phôi) ──────────────────
	for tag in npc.preferred_weapon_tags:
		if tag in CUSTOMER_TYPE_TAGS:
			var cfg: Dictionary = CUSTOMER_TYPE_TAGS[tag]
			if weapon.blank_type in cfg["blank_ids"]:
				score += cfg["score_bonus"]
				reasons.append("Phôi %s phù hợp (+%d)" % [weapon.blank_type, cfg["score_bonus"]])

	# ── 2. Check PREFIX TAG ───────────────────────────────────
	for tag in npc.preferred_weapon_tags:
		if tag in PREFIX_TAGS:
			if weapon.prefix == PREFIX_TAGS[tag]["skill_id"] or weapon.prefix == tag:
				var bonus: int = PREFIX_TAGS[tag]["score_bonus"]
				score += bonus
				reasons.append("Prefix '%s' ưa thích (+%d)" % [PREFIX_TAGS[tag]["label"], bonus])

	for tag in npc.disliked_weapon_tags:
		if tag in PREFIX_TAGS:
			if weapon.prefix == PREFIX_TAGS[tag]["skill_id"] or weapon.prefix == tag:
				score -= PREFIX_TAGS[tag]["score_bonus"] * 2
				reasons.append("Prefix '%s' không thích (-%d)" % [
				PREFIX_TAGS[tag]["label"], PREFIX_TAGS[tag]["score_bonus"] * 2
			])

	# ── 3. Check SUFFIX / ELEMENT TAG ────────────────────────
	for tag in npc.preferred_weapon_tags:
		if tag in SUFFIX_TAGS:
			if weapon.suffix_element == tag or weapon.suffix_element == SUFFIX_TAGS[tag]["skill_id"]:
				var bonus: int = SUFFIX_TAGS[tag]["score_bonus"]
				score += bonus
				reasons.append("Element '%s' ưa thích (+%d)" % [SUFFIX_TAGS[tag]["label"], bonus])

	for tag in npc.disliked_weapon_tags:
		if tag in SUFFIX_TAGS:
			if weapon.suffix_element == tag or weapon.suffix_element == SUFFIX_TAGS[tag]["skill_id"]:
				var penalty: int = SUFFIX_TAGS[tag]["score_bonus"] * 2
				score -= penalty
				reasons.append("Element '%s' không thích (-%d)" % [SUFFIX_TAGS[tag]["label"], penalty])

	# ── 4. Check QUALITY TAGS ─────────────────────────────────

	# Mastery
	if "Mastery" in npc.preferred_weapon_tags:
		if weapon.is_mastery:
			score += QUALITY_TAGS["Mastery"]["score_bonus"]
			reasons.append("Vũ khí Mastery ưa thích (+%d)" % QUALITY_TAGS["Mastery"]["score_bonus"])
		else:
			# VIP required_by: nếu NPC bắt buộc cần Mastery mà không có → hard reject
			var required_npcs: Array = QUALITY_TAGS["Mastery"].get("required_by", [])
			if npc.npc_id in required_npcs:
				hard_reject = true
				reasons.append("NPC này chỉ mua Mastery — từ chối ngay!")

	# Curse
	if weapon.is_cursed:
		if "Curse" in npc.disliked_weapon_tags or true:  # Mọi khách đều ghét Curse mặc định
			var penalty: int = absf(QUALITY_TAGS["Curse"]["score_penalty"]) as int
			score -= penalty
			reasons.append("Vũ khí bị nguyền! (-%d)" % penalty)
			if score < -20:
				hard_reject = true
				reasons.append("Điểm quá thấp do Curse → khách bỏ đi!")

	# ATK cao
	if weapon.atk >= QUALITY_TAGS["HighATK"]["threshold"]:
		if _npc_wants_high_atk(npc):
			score += QUALITY_TAGS["HighATK"]["score_bonus"]
			reasons.append("ATK cao (%d) (+%d)" % [weapon.atk, QUALITY_TAGS["HighATK"]["score_bonus"]])

	# DEF cao
	if weapon.def_stat >= QUALITY_TAGS["HighDEF"]["threshold"]:
		if "ThuVe" in npc.preferred_weapon_tags:
			score += QUALITY_TAGS["HighDEF"]["score_bonus"]
			reasons.append("DEF cao (%d) (+%d)" % [weapon.def_stat, QUALITY_TAGS["HighDEF"]["score_bonus"]])

	# Magic cao
	if weapon.magic >= QUALITY_TAGS["HighMagic"]["threshold"]:
		if "DaoSi" in npc.preferred_weapon_tags:
			score += QUALITY_TAGS["HighMagic"]["score_bonus"]
			reasons.append("Magic cao (%d) (+%d)" % [weapon.magic, QUALITY_TAGS["HighMagic"]["score_bonus"]])

	# Durability thấp
	if weapon.durability < QUALITY_TAGS["LowDurability"]["threshold"]:
		var penalty: int = absf(QUALITY_TAGS["LowDurability"]["score_penalty"]) as int
		score -= penalty
		reasons.append("Durability thấp (%d/%d) (-%d)" % [
			weapon.durability, weapon.max_durability, penalty
		])

	# Perfect Forge (Phase 1 Vàng Kim — lưu trong WeaponData.effect_data hoặc flag)
	# Giả sử WeaponData có field forge_tier: String
	# if weapon.forge_tier == "overheat":  # Vàng Kim = overheat tier theo forge_system
	#     score += QUALITY_TAGS["PerfectForge"]["score_bonus"]
	#     reasons.append("Rèn hoàn hảo (+%d)" % QUALITY_TAGS["PerfectForge"]["score_bonus"])

	# ── 5. Affinity bonus ─────────────────────────────────────
	# Khách quen thân → dễ tính hơn
	var affinity_bonus: int = npc.affinity / 20  # Affinity 100 → +5 điểm
	if affinity_bonus > 0:
		score += affinity_bonus
		reasons.append("Khách quen (+%d từ affinity %d)" % [affinity_bonus, npc.affinity])

	# ── 6. Tính kết quả ───────────────────────────────────────
	var will_buy: bool = score >= 0 and not hard_reject
	var price_mult: float = _score_to_price_mult(score)

	return {
		"score":       score,
		"will_buy":    will_buy,
		"hard_reject": hard_reject,
		"price_mult":  price_mult,
		"reasons":     reasons,
	}


## Tính price_mult từ score
## score < 0  → khách trả giá thấp hơn thị trường
## score 0-30 → quanh giá thị trường
## score > 60 → khách sẵn sàng trả cao
static func _score_to_price_mult(score: int) -> float:
	if score < -30:
		return 0.6
	if score < 0:
		return 0.8
	if score < 20:
		return 1.0
	if score < 40:
		return 1.1
	if score < 60:
		return 1.25
	return 1.4   # Hào Kiệt Mastery cho VIP → x1.4 giá


static func _npc_wants_high_atk(npc: NPCData) -> bool:
	var atk_lovers := ["HiepKhach", "ThichKhach", "VoTang"]
	for t in atk_lovers:
		if t in npc.preferred_weapon_tags:
			return true
	return false


## Debug helper — in ra lý do matching trong console
static func debug_match(weapon: WeaponData, npc: NPCData) -> void:
	var result := score_weapon_for_npc(weapon, npc)
	print("=== MATCHING: %s ↔ %s ===" % [weapon.weapon_name, npc.npc_name])
	print("Score: %d | Will Buy: %s | Price Mult: %.2f" % [
		result["score"], str(result["will_buy"]), result["price_mult"]
	])
	for r in result["reasons"]:
		print("  • %s" % r)
	print("")


# ═══════════════════════════════════════════════════════════════
# PHẦN 3 — HELPER CHO SHOP MANAGER
# ═══════════════════════════════════════════════════════════════

## Lấy tất cả vũ khí trên kệ, sort theo độ phù hợp với NPC
## Dùng khi Customer AI "ngắm" kệ và chọn vũ khí để hỏi mua
static func get_best_weapon_for_npc(
	npc:         NPCData,
	weapons_on_shelf: Array  # Array[WeaponData]
) -> WeaponData:
	var best_weapon: WeaponData = null
	var best_score:  int        = -999

	for weapon in weapons_on_shelf:
		var result := score_weapon_for_npc(weapon, npc)
		if result["will_buy"] and result["score"] > best_score:
			best_score  = result["score"]
			best_weapon = weapon

	return best_weapon  # null nếu không có vũ khí nào phù hợp


## Tính acceptable_price range cho bargaining mini-game
## Trả về Vector2i(min_price, max_price) khách chịu trả
static func get_acceptable_price_range(
	weapon: WeaponData,
	npc:    NPCData
) -> Vector2i:
	var result    := score_weapon_for_npc(weapon, npc)
	var mult:  float = result["price_mult"]
	var budget_max:  int = npc.budget_range.y

	var ideal_price: int = roundi(weapon.base_price * mult)
	var max_price:   int = mini(ideal_price + roundi(ideal_price * 0.15), budget_max)
	var min_price:   int = roundi(ideal_price * 0.85)

	return Vector2i(min_price, max_price)


## Validate tags trong NPCData — gọi khi load để catch typo
static func validate_npc_tags(npc: NPCData) -> Array[String]:
	var errors: Array[String] = []
	var valid := get_all_valid_tags()

	for tag in npc.preferred_weapon_tags:
		if tag not in valid:
			errors.append("NPC '%s': preferred tag '%s' không tồn tại!" % [npc.npc_id, tag])

	for tag in npc.disliked_weapon_tags:
		if tag not in valid:
			errors.append("NPC '%s': disliked tag '%s' không tồn tại!" % [npc.npc_id, tag])

	return errors
