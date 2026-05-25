# scripts/systems/NPCDatabase.gd
# FULL-GAME REFERENCE: không dùng trong runtime demo 4 ngày.
# Chứa toàn bộ 20 NPCs: 6 VIP + 2 Antagonist + 12 Recurring
# Dùng: NPCDatabase.get_npc("co_long_gio")
#        NPCDatabase.get_npcs_by_type(NPCData.NPCType.VIP)
#        NPCDatabase.get_npcs_in_region("DongMay")

class_name NPCDatabase
extends Node

static var _npcs: Dictionary = {}
static var _initialized: bool = false

# ─── Public API ───────────────────────────────────────────

static func get_npc(npc_id: String) -> NPCData:
	_init_if_needed()
	return _npcs.get(npc_id, null)

static func get_npcs_by_type(type: NPCData.NPCType) -> Array[NPCData]:
	_init_if_needed()
	var result: Array[NPCData] = []
	for npc in _npcs.values():
		if npc.npc_type == type:
			result.append(npc)
	return result

static func get_npcs_in_region(region_id: String) -> Array[NPCData]:
	_init_if_needed()
	var result: Array[NPCData] = []
	for npc in _npcs.values():
		var regions: Array = npc.schedule.get("regions", [])
		if region_id in regions:
			result.append(npc)
	return result

# ─── Internal ─────────────────────────────────────────────

static func _init_if_needed() -> void:
	if _initialized:
		return
	_build_vip_npcs()
	_build_antagonists()
	_build_recurring_npcs()
	_initialized = true

static func _register(npc: NPCData) -> void:
	_npcs[npc.npc_id] = npc

static func _make_npc(
	id: String,
	name: String,
	type: NPCData.NPCType,
	budget_min: int,
	budget_max: int,
	patience: int,
	preferred: Array,
	disliked: Array,
	regions: Array,
	times: Array
) -> NPCData:
	var npc := NPCData.new()
	npc.npc_id                 = id
	npc.npc_name               = name
	npc.npc_type               = type
	npc.budget_range           = Vector2i(budget_min, budget_max)
	npc.patience               = patience
	npc.preferred_weapon_tags  = preferred
	npc.disliked_weapon_tags   = disliked
	npc.schedule               = {"regions": regions, "times": times}
	npc.affinity               = 0
	return npc


# ═══════════════════════════════════════════════════════════
# VIP NPCs — 6 (mỗi vùng 1, quest giver chính)
# ═══════════════════════════════════════════════════════════

static func _build_vip_npcs() -> void:

	# ── Cô Lộng Gió — Đồng Mây Trắng ────────────────────
	var npc := _make_npc(
		"co_long_gio", "Cô Lộng Gió",
		NPCData.NPCType.VIP,
		2000, 5000, 3,
		["HiepKhach", "prefix_kiet_tac", "prefix_to_nghe"],
		["Curse"],
		["DongMay"],
		["morning", "afternoon"]
	)
	# Extra VIP data
	npc.affinity = 0
	_register(npc)

	# ── Tướng Bóng Rừng — Rừng Trăm Hồn ─────────────────
	npc = _make_npc(
		"tuong_bong_rung", "Tướng Bóng Rừng",
		NPCData.NPCType.VIP,
		3000, 7000, 2,
		["ThuVe", "suffix_bong_toi", "suffix_doc"],
		["suffix_thanh"],
		["RungTramHon"],
		["afternoon", "night"]
	)
	_register(npc)

	# ── Gã Khét Lửa — Núi Than Đỏ ────────────────────────
	npc = _make_npc(
		"ga_khet_lua", "Gã Khét Lửa",
		NPCData.NPCType.VIP,
		2500, 6000, 3,
		["VoTang", "suffix_hoa", "prefix_nang_tay"],
		["suffix_bang"],
		["NuiThanDo"],
		["morning", "afternoon"]
	)
	_register(npc)

	# ── Ông Cát Thần — Bãi Cát Thần Vàng ─────────────────
	npc = _make_npc(
		"ong_cat_than", "Ông Cát Thần",
		NPCData.NPCType.VIP,
		4000, 9000, 2,
		["DaoSi", "suffix_set", "prefix_huyen_bi"],
		["prefix_nang_tay"],
		["BaiCat"],
		["morning", "afternoon"]
	)
	_register(npc)

	# ── Bà Thiên Kim — Thành Ngọc Bích ───────────────────
	npc = _make_npc(
		"ba_thien_kim", "Bà Thiên Kim",
		NPCData.NPCType.VIP,
		8000, 20000, 1,
		["Mastery", "prefix_kiet_tac", "prefix_hao_kiet"],
		["Curse", "prefix_nang_tay"],
		["ThanhNgoc"],
		["afternoon"]
	)
	_register(npc)

	# ── Lão Thôi Cổ — Làng Tổ Nghề ──────────────────────
	npc = _make_npc(
		"lao_thoi_co", "Lão Thôi Cổ",
		NPCData.NPCType.VIP,
		5000, 15000, 3,
		["Mastery", "prefix_truong_sinh", "prefix_to_nghe"],
		[],
		["LangTo"],
		["morning", "afternoon", "night"]
	)
	_register(npc)


# ═══════════════════════════════════════════════════════════
# ANTAGONISTS — 2 (không mua vũ khí, chỉ quest/event)
# ═══════════════════════════════════════════════════════════

static func _build_antagonists() -> void:

	# ── Bà Trùm Hắc Nguyệt ───────────────────────────────
	var npc := _make_npc(
		"ba_trum_hac_nguyet", "Bà Trùm Hắc Nguyệt",
		NPCData.NPCType.ANTAGONIST,
		0, 0, 0,
		[], [],
		["Shop"],            # Chỉ xuất hiện tại shop khi đến Cơn Nợ
		["morning"]
	)
	_register(npc)

	# ── Lão Gà Chọi ──────────────────────────────────────
	npc = _make_npc(
		"lao_ga_choi", "Lão Gà Chọi",
		NPCData.NPCType.ANTAGONIST,
		0, 0, 0,
		[], [],
		["Shop"],            # Xuất hiện random, báo nợ
		["afternoon"]
	)
	_register(npc)


# ═══════════════════════════════════════════════════════════
# RECURRING CUSTOMERS — 12 (có affinity, có quest riêng)
# ═══════════════════════════════════════════════════════════

static func _build_recurring_npcs() -> void:

	# ── #81 Hiệp Khách Lang Bạt ───────────────────────────
	var npc := _make_npc(
		"hiep_khach_lang_bat", "Hiệp Khách Lang Bạt",
		NPCData.NPCType.RECURRING,
		500, 1500, 3,
		["HiepKhach", "suffix_hoa", "suffix_set"],
		["Curse"],
		["DongMay", "RungTramHon"],
		["morning", "afternoon"]
	)
	_register(npc)

	# ── #92 Đại Đạo Sĩ ───────────────────────────────────
	npc = _make_npc(
		"dai_dao_si", "Đại Đạo Sĩ",
		NPCData.NPCType.RECURRING,
		1500, 4000, 2,
		["DaoSi", "prefix_huyen_bi", "suffix_thanh"],
		["prefix_nang_tay", "ThuVe"],
		["NuiThanDo", "RungTramHon"],
		["morning"]
	)
	_register(npc)

	# ── #104 Đại Tướng ────────────────────────────────────
	npc = _make_npc(
		"dai_tuong", "Đại Tướng",
		NPCData.NPCType.RECURRING,
		3000, 8000, 1,
		["ThuVe", "Mastery", "prefix_kien_co"],
		["ThichKhach", "suffix_doc"],
		["ThanhNgoc", "DongMay"],
		["afternoon"]
	)
	_register(npc)

	# ── #108 Đứa Trẻ Mồ Côi ──────────────────────────────
	npc = _make_npc(
		"dua_tre_mo_coi", "Đứa Trẻ Mồ Côi",
		NPCData.NPCType.RECURRING,
		50, 200, 5,
		["HiepKhach", "prefix_than_toc"],
		["Mastery"],          # Không đủ tiền mua Mastery
		["DongMay"],
		["morning", "afternoon"]
	)
	_register(npc)

	# ── #110 Hội Đồng Thợ Rèn ────────────────────────────
	npc = _make_npc(
		"hoi_dong_tho_ren", "Hội Đồng Thợ Rèn",
		NPCData.NPCType.RECURRING,
		5000, 15000, 1,
		["Mastery", "prefix_kiet_tac", "prefix_to_nghe"],
		["Curse"],
		["ThanhNgoc", "LangTo"],
		["afternoon"]
	)
	_register(npc)

	# ── Thợ Săn Rừng Già ──────────────────────────────────
	npc = _make_npc(
		"tho_san_rung_gia", "Thợ Săn Rừng Già",
		NPCData.NPCType.RECURRING,
		400, 1200, 3,
		["ThoSan", "suffix_doc", "suffix_bang"],
		[],
		["RungTramHon", "DongMay"],
		["morning"]
	)
	_register(npc)

	# ── Võ Tăng Du Phương ─────────────────────────────────
	npc = _make_npc(
		"vo_tang_du_phuong", "Võ Tăng Du Phương",
		NPCData.NPCType.RECURRING,
		600, 1800, 4,
		["VoTang", "suffix_thanh", "prefix_can_bang"],
		["suffix_bong_toi"],
		["RungTramHon", "NuiThanDo"],
		["morning", "afternoon"]
	)
	_register(npc)

	# ── Thương Nhân Cát Vàng ──────────────────────────────
	npc = _make_npc(
		"thuong_nhan_cat_vang", "Thương Nhân Cát Vàng",
		NPCData.NPCType.RECURRING,
		2000, 6000, 2,
		["prefix_hao_kiet", "suffix_set"],
		["Curse"],
		["BaiCat", "ThanhNgoc"],
		["afternoon"]
	)
	_register(npc)

	# ── Vệ Binh Hoàng Gia ─────────────────────────────────
	npc = _make_npc(
		"ve_binh_hoang_gia", "Vệ Binh Hoàng Gia",
		NPCData.NPCType.RECURRING,
		4000, 10000, 1,
		["ThuVe", "Mastery", "prefix_kien_co", "prefix_cung_nhu_da"],
		["ThichKhach", "suffix_doc"],
		["ThanhNgoc"],
		["afternoon"]
	)
	_register(npc)

	# ── Thích Khách Bí Ẩn ─────────────────────────────────
	npc = _make_npc(
		"thich_khach_bi_an", "Thích Khách Bí Ẩn",
		NPCData.NPCType.RECURRING,
		1000, 3000, 2,
		["ThichKhach", "suffix_bong_toi", "prefix_than_toc"],
		["ThuVe", "suffix_thanh"],
		["RungTramHon", "BaiCat"],
		["night"]            # Chỉ xuất hiện ban đêm
	)
	_register(npc)

	# ── Bà Bán Thuốc ──────────────────────────────────────
	# Special: bán consumable, không mua vũ khí thường
	npc = _make_npc(
		"ba_ban_thuoc", "Bà Bán Thuốc",
		NPCData.NPCType.RECURRING,
		0, 0, 5,
		[], [],
		["DongMay", "RungTramHon", "NuiThanDo", "BaiCat", "ThanhNgoc", "LangTo"],
		["morning", "afternoon"]
	)
	npc.schedule["role"] = "vendor"   # Không mặc cả — bán consumable giá cố định
	_register(npc)

	# ── Lão Lang Thang ────────────────────────────────────
	# Xuất hiện random bất kỳ vùng, bán nguyên liệu giá cao
	npc = _make_npc(
		"lao_lang_thang", "Lão Lang Thang",
		NPCData.NPCType.RECURRING,
		500, 2000, 4,
		["HiepKhach", "suffix_hoa"],
		[],
		["DongMay", "RungTramHon", "NuiThanDo", "BaiCat"],
		["morning"]
	)
	npc.schedule["spawn_chance"] = 0.2  # 20% chance xuất hiện mỗi ngày
	_register(npc)
