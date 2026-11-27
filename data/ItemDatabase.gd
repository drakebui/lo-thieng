# scripts/systems/ItemDatabase.gd
# Chứa toàn bộ ~66 items: 24 NL + 18 Linh Lực + 12 Phôi + 12 Consumable
# Dùng: ItemDatabase.get_item("sat_tho")
#        ItemDatabase.get_items_by_region("DongMay")
#        ItemDatabase.get_items_by_type(ItemData.ItemType.MATERIAL)

class_name ItemDatabase
extends Node

static var _items: Dictionary = {}
static var _initialized: bool = false

# ─── Public API ───────────────────────────────────────────

static func get_item(item_id: String) -> ItemData:
	_init_if_needed()
	return _items.get(item_id, null)

static func get_items_by_type(type: ItemData.ItemType) -> Array[ItemData]:
	_init_if_needed()
	var result: Array[ItemData] = []
	for item in _items.values():
		if item.item_type == type:
			result.append(item)
	return result

static func get_items_by_region(region_id: String) -> Array[ItemData]:
	_init_if_needed()
	var result: Array[ItemData] = []
	for item in _items.values():
		if item.effect_data.get("region", "") == region_id:
			result.append(item)
	return result

static func get_blanks_for_customer_type(customer_type: String) -> Array[ItemData]:
	_init_if_needed()
	var result: Array[ItemData] = []
	for item in _items.values():
		if item.item_type == ItemData.ItemType.BLANK:
			var preferred: Array = item.effect_data.get("preferred_customers", [])
			if customer_type in preferred:
				result.append(item)
	return result

# ─── Internal ─────────────────────────────────────────────

static func _init_if_needed() -> void:
	if _initialized:
		return
	_build_materials()
	_build_elements()
	_build_blanks()
	_build_consumables()
	_initialized = true

static func _register(item: ItemData) -> void:
	_items[item.item_id] = item

static func _mat(
	id: String, name: String, region: String, rarity: int, value: int,
	desc: String, bonuses: Dictionary = {}
) -> void:
	var item := ItemData.new()
	item.item_id    = id
	item.item_name  = name
	item.item_type  = ItemData.ItemType.MATERIAL
	item.rarity     = rarity
	item.base_value = value
	item.description = desc
	item.effect_data = {"region": region}
	item.effect_data.merge(bonuses)
	_register(item)

static func _elem(
	id: String, name: String, element: String, rarity: int, value: int, desc: String
) -> void:
	var item := ItemData.new()
	item.item_id    = id
	item.item_name  = name
	item.item_type  = ItemData.ItemType.ELEMENT
	item.rarity     = rarity
	item.base_value = value
	item.description = desc
	item.effect_data = {"element": element, "suffix_bonus": rarity * 10}
	_register(item)

static func _blank(
	id: String, name: String, base_atk: int, base_def: int, base_magic: int,
	customers: Array, value: int, desc: String, skill: String = ""
) -> void:
	var item := ItemData.new()
	item.item_id    = id
	item.item_name  = name
	item.item_type  = ItemData.ItemType.BLANK
	item.rarity     = 1
	item.base_value = value
	item.description = desc
	item.effect_data = {
		"base_atk":            base_atk,
		"base_def":            base_def,
		"base_magic":          base_magic,
		"preferred_customers": customers,
	}
	if not skill.is_empty():
		item.effect_data["skill"] = skill
	_register(item)

static func _cons(
	id: String, name: String, effect_type: String, value: float, price: int, desc: String
) -> void:
	var item := ItemData.new()
	item.item_id    = id
	item.item_name  = name
	item.item_type  = ItemData.ItemType.CONSUMABLE
	item.rarity     = 1
	item.base_value = price
	item.description = desc
	item.effect_data = {"effect_type": effect_type, "value": value}
	_register(item)


# ═══════════════════════════════════════════════════════════
# NGUYÊN LIỆU THÔ — 24 items (4 per region)
# rarity: 1=phổ thông, 2=hiếm, 3=cực hiếm
# ═══════════════════════════════════════════════════════════

static func _build_materials() -> void:

	# ── Đồng Mây Trắng ────────────────────────────────────
	_mat("sat_tho",      "Sắt Thô",          "DongMay", 1,  80,
		"Quặng sắt phổ thông từ thảo nguyên. Nguyên liệu cơ bản nhất.",
		{atk_bonus=1, allowed_elements=["hoa", "phong", "tho"]})
	_mat("da_thu",       "Da Thú",           "DongMay", 1,  60,
		"Da từ thú rừng đồng cỏ. Tăng độ bền vũ khí.",
		{def_bonus=1, allowed_elements=["hoa", "phong", "tho"]})
	_mat("bac_manh",     "Bạc Mảnh",         "DongMay", 2, 150,
		"Mảnh bạc tinh khiết. Tăng Magic khi rèn.",
		{magic_bonus=3, allowed_elements=["hoa", "phong", "tho", "bang", "set"]})
	_mat("dong_co_kho",  "Đồng Cỏ Khô",      "DongMay", 1,  40,
		"Cỏ khô đặc biệt vùng đồng. Dùng làm chất kết dính.",
		{def_bonus=1, allowed_elements=["hoa", "phong", "tho"]})

	# ── Rừng Trăm Hồn ─────────────────────────────────────
	_mat("go_co_thu",    "Gỗ Cổ Thụ",        "RungTramHon", 2, 200,
		"Gỗ từ cây trăm tuổi. Tăng ATK và Magic cho vũ khí nhẹ.",
		{atk_bonus=2, magic_bonus=2, allowed_elements=["hoa", "phong", "tho", "bang", "set"]})
	_mat("pha_le_rung",  "Pha Lê Rừng",      "RungTramHon", 2, 180,
		"Tinh thể hình thành tự nhiên trong rừng linh khí. Tăng Magic.",
		{magic_bonus=4, allowed_elements=["hoa", "phong", "tho", "bang", "set"]})
	_mat("nhua_linh",    "Nhựa Linh",        "RungTramHon", 1,  90,
		"Nhựa cây có linh khí. Giúp Linh Lực thấm sâu hơn khi Tôi Luyện.",
		{magic_bonus=1, allowed_elements=["hoa", "phong", "tho"]})
	_mat("la_hon",       "Lá Hồn",           "RungTramHon", 3, 400,
		"Lá cây thiêng rất hiếm. Tăng hiệu quả Suffix lên đáng kể.",
		{
			magic_bonus=3, price_mult=1.1,
			allowed_elements=["hoa", "phong", "tho", "bang", "set", "hu_khong"],
		})

	# ── Núi Than Đỏ ───────────────────────────────────────
	_mat("quang_than",   "Quặng Than",       "NuiThanDo", 1, 120,
		"Quặng than núi lửa. Tăng ATK nhưng giảm nhẹ Speed.",
		{atk_bonus=3, speed_bonus=-1, allowed_elements=["hoa", "phong", "tho"]})
	_mat("mithril_tho",  "Mithril Thô",      "NuiThanDo", 3, 500,
		"Kim loại huyền thoại hiếm nhất. Tăng mạnh ATK và Magic.",
		{atk_bonus=6, magic_bonus=4, allowed_elements=["hoa", "phong", "tho", "bang", "set", "hu_khong"]})
	_mat("da_hoa_son",   "Đá Hỏa Sơn",      "NuiThanDo", 2, 220,
		"Đá từ núi lửa ngủ. Tự động đẩy Phase 1 lên tier Cam.",
		{atk_bonus=1, phase1_min="cam", allowed_elements=["hoa", "phong", "tho", "bang", "set"]})
	_mat("thep_hoa_son", "Thép Hỏa Sơn",    "NuiThanDo", 2, 280,
		"Thép đã qua nung núi lửa. Tự động bypass Phase 1 lên Vàng Kim.",
		{atk_bonus=2, phase1_min="vang_kim", allowed_elements=["hoa", "phong", "tho", "bang", "set"]})

	# ── Bãi Cát Thần Vàng ─────────────────────────────────
	_mat("cat_thieng",   "Cát Thiêng",       "BaiCat", 1,  70,
		"Cát sa mạc có khí thiêng. Tăng nhẹ độ bền vũ khí.",
		{def_bonus=1, allowed_elements=["hoa", "phong", "tho"]})
	_mat("ho_phach",     "Hổ Phách Cổ",     "BaiCat", 2, 250,
		"Hổ phách hàng nghìn năm tuổi. Tăng Speed và Magic.",
		{magic_bonus=2, speed_bonus=3, allowed_elements=["hoa", "phong", "tho", "bang", "set"]})
	_mat("xuong_ca",     "Xương Cá Sa Mạc", "BaiCat", 1,  85,
		"Xương cá hóa thạch. Làm vũ khí nhẹ hơn, tăng Speed.",
		{speed_bonus=2, allowed_elements=["hoa", "phong", "tho"]})
	_mat("da_vang",      "Đá Vàng",          "BaiCat", 3, 450,
		"Đá mang màu vàng rực. Tăng giá bán vũ khí thêm 20%.",
		{price_mult=1.2, allowed_elements=["hoa", "phong", "tho", "bang", "set", "hu_khong"]})

	# ── Thành Ngọc Bích ───────────────────────────────────
	_mat("thep_trang",   "Thép Trắng",       "ThanhNgoc", 2, 300,
		"Thép tinh luyện bậc cao từ thành phố. Tăng ATK và DEF đồng đều.",
		{atk_bonus=3, def_bonus=3, allowed_elements=["hoa", "phong", "tho", "bang", "set"]})
	_mat("ngoc_tho",     "Ngọc Thô",         "ThanhNgoc", 3, 550,
		"Ngọc chưa mài giũa. Dùng trong vũ khí cao cấp cho giới quý tộc.",
		{atk_bonus=2, magic_bonus=3, allowed_elements=["hoa", "phong", "tho", "bang", "set", "hu_khong"]})
	_mat("soi_vang",     "Sợi Vàng",         "ThanhNgoc", 2, 200,
		"Sợi vàng thủ công. Tăng giá trị thẩm mỹ, nâng giá bán.",
		{magic_bonus=1, price_mult=1.15, allowed_elements=["hoa", "phong", "tho", "bang", "set"]})
	_mat("da_ngoc",      "Đá Ngọc",          "ThanhNgoc", 1, 130,
		"Đá thường nhưng có ánh ngọc. Tăng nhẹ DEF.",
		{def_bonus=2, allowed_elements=["hoa", "phong", "tho"]})

	# ── Làng Tổ Nghề ──────────────────────────────────────
	_mat("di_thach",     "Di Thạch",         "LangTo", 3, 600,
		"Đá thiêng từ thời Tổ Nghề. Dùng trong công thức vũ khí Mastery đặc biệt.",
		{
			atk_bonus=3, def_bonus=3, magic_bonus=3, speed_bonus=1,
			allowed_elements=["hoa", "phong", "tho", "bang", "set", "hu_khong"],
		})
	_mat("manh_thieng",  "Mảnh Thiêng",      "LangTo", 3, 700,
		"Mảnh vỡ từ Lò Thiêng nguyên thủy. Tăng mạnh mọi chỉ số khi rèn.",
		{
			atk_bonus=5, def_bonus=3, magic_bonus=5, speed_bonus=2,
			allowed_elements=["hoa", "phong", "tho", "bang", "set", "hu_khong"],
		})
	_mat("tro_lo_to",    "Tro Lò Tổ",        "LangTo", 2, 350,
		"Tro từ lò rèn cổ. Dùng trong Phase 1 để ổn định nhiệt độ.",
		{def_bonus=2, allowed_elements=["hoa", "phong", "tho", "bang", "set"]})
	_mat("go_to_nghe",   "Gỗ Tổ Nghề",       "LangTo", 2, 320,
		"Gỗ thiêng từ làng cổ. Tăng hiệu quả Phase 2 nhẹ.",
		{atk_bonus=1, magic_bonus=1, allowed_elements=["hoa", "phong", "tho", "bang", "set"]})


# ═══════════════════════════════════════════════════════════
# LINH LỰC — 18 items (3 rarity × 6 nguyên tố)
# effect_data: element + suffix_bonus (rarity × 10)
# ═══════════════════════════════════════════════════════════

static func _build_elements() -> void:

	# ── Hỏa ───────────────────────────────────────────────
	_elem("linh_luc_hoa_1",   "Linh Lực Hỏa Sơ",      "hoa", 1, 100,
		"Linh lực lửa cơ bản. Gắn kỹ năng Burn vào vũ khí.")
	_elem("linh_luc_hoa_2",   "Linh Lực Hỏa Trung",   "hoa", 2, 250,
		"Linh lực lửa cấp trung. Burn gây thêm 2 sát thương/lượt.")
	_elem("linh_luc_hoa_3",   "Linh Lực Hỏa Thần",    "hoa", 3, 600,
		"Linh lực lửa tối thượng. Burn lan sang lượt kế tiếp.")

	# ── Băng ───────────────────────────────────────────────
	_elem("linh_luc_bang_1",  "Linh Lực Băng Sơ",     "bang", 1, 100,
		"Linh lực băng cơ bản. Gắn kỹ năng Freeze vào vũ khí.")
	_elem("linh_luc_bang_2",  "Linh Lực Băng Trung",  "bang", 2, 250,
		"Linh lực băng cấp trung. Xác suất Freeze tăng lên 70%.")
	_elem("linh_luc_bang_3",  "Linh Lực Băng Nguyên", "bang", 3, 600,
		"Linh lực băng nguyên thủy. Freeze kéo dài 2 lượt.")

	# ── Sét ────────────────────────────────────────────────
	_elem("linh_luc_set_1",   "Linh Lực Sét Sơ",      "set", 1, 100,
		"Linh lực sét cơ bản. Gắn Chain Lightning, xuyên 50% DEF.")
	_elem("linh_luc_set_2",   "Linh Lực Sét Trung",   "set", 2, 250,
		"Linh lực sét cấp trung. Xuyên thêm 15% DEF so với cơ bản.")
	_elem("linh_luc_set_3",   "Linh Lực Thiên Sét",   "set", 3, 600,
		"Linh lực sét hủy diệt. Xuyên 80% DEF, có 20% stunned 1 lượt.")

	# ── Thổ (Độc/Địa) ──────────────────────────────────────
	_elem("linh_luc_doc_1",   "Linh Lực Thổ Sơ",      "tho", 1, 80,
		"Linh lực thổ cơ bản. Gắn Độc Vân, 5% HP/lượt.")
	_elem("linh_luc_doc_2",   "Linh Lực Thổ Trung",   "tho", 2, 200,
		"Linh lực thổ cấp trung. Stack độc nhanh gấp đôi.")
	_elem("linh_luc_hac_doc", "Linh Lực Hắc Thổ",     "tho", 3, 500,
		"Thổ độc tối thượng. 8% HP/lượt, xuyên giáp.")

	# ── Phong ──────────────────────────────────────────────
	_elem("linh_luc_thanh_1", "Linh Lực Phong Sơ",    "phong", 1, 120,
		"Linh lực phong cơ bản. Gắn Cuồng Phong tăng tốc.")
	_elem("linh_luc_thanh_2", "Linh Lực Phong Trung", "phong", 2, 300,
		"Linh lực phong cấp trung. Tăng mạnh sát thương gió.")
	_elem("linh_luc_thanh_3", "Linh Lực Phong Khiết", "phong", 3, 700,
		"Linh lực phong thuần khiết. Bão tố liên hoàn.")

	# ── Hư Không ───────────────────────────────────────────
	_elem("linh_luc_bong_1",  "Linh Lực Hư Không Sơ",     "hu_khong", 1, 100,
		"Linh lực hư không cơ bản. Gắn Shadow Strike, xuyên DEF.")
	_elem("linh_luc_bong_2",  "Linh Lực Hư Không Trung",  "hu_khong", 2, 250,
		"Linh lực hư không cấp trung. Thêm 20% damage xuyên bóng.")
	_elem("linh_luc_bong_3",  "Linh Lực Vong Hồn",        "hu_khong", 3, 650,
		"Linh lực hư không tối thượng. Xuyên 100% DEF.")


# ═══════════════════════════════════════════════════════════
# PHÔI VŨ KHÍ — 12 items
# effect_data: base stats + preferred_customers
# ═══════════════════════════════════════════════════════════

static func _build_blanks() -> void:

	# id, name, base_atk, base_def, base_magic, preferred_customers[], base_price, desc
	_blank(
		"phoi_kiem_don", "Kiếm Đơn", 8, 0, 0, ["hiep_khach"], 200,
		"Kiếm một tay cân bằng. Phù hợp Hiệp Khách. Skill cơ bản: Slash.")
	_blank(
		"phoi_song_dao", "Song Đao", 7, 0, 1, ["thich_khach"], 220,
		"Đôi dao nhẹ. Phù hợp Thích Khách. Skill cơ bản: Twin Strike.")
	_blank(
		"phoi_giao_dai", "Giáo Dài", 6, 2, 0, ["thu_ve", "hiep_khach"], 240,
		"Giáo dài lợi thế tầm xa. Skill cơ bản: Reach.")
	_blank(
		"phoi_bua_chien", "Búa Chiến", 10, 3, 0, ["vo_tang", "thu_ve"], 280,
		"Búa chiến nặng nề, ATK cao nhất. Skill cơ bản: Crush.")
	_blank(
		"phoi_cung_truong", "Cung Trường", 6, 0, 2, ["tho_san"], 260,
		"Cung dài, tầm xa. Phù hợp Thợ Săn. Skill cơ bản: Aim.")
	_blank(
		"phoi_khien_dong", "Khiên Đồng", 2, 8, 0, ["thu_ve"], 220,
		"Khiên phòng thủ cao nhất. Phù hợp Thủ Vệ. Skill cơ bản: Block.")
	_blank(
		"phoi_quyen_cu", "Quyền Cụ", 7, 0, 0, ["vo_tang"], 190,
		"Vũ khí tay trần tăng cường. Skill cơ bản: Combo (3 hit nhỏ).")
	_blank(
		"phoi_con_nhi_khuc", "Côn Nhị Khúc", 6, 1, 0, ["vo_tang", "thich_khach"], 210,
		"Côn nhị khúc linh hoạt. Skill cơ bản: Whirl.")
	_blank(
		"phoi_dao_phat", "Đao Phạt", 9, 2, 0, ["thu_ve"], 300,
		"Đao phạt chuyên cho Thủ Vệ đặc biệt. Skill cơ bản: Heavy Cleave.")
	_blank(
		"phoi_gay_phep", "Gậy Phép", 2, 0, 10, ["dao_si"], 350,
		"Gậy pháp thuật, Magic cao nhất. Phù hợp Đạo Sĩ. Skill cơ bản: Cast.")
	_blank(
		"phoi_liem_song", "Liềm Song", 8, 0, 2, ["thich_khach"], 270,
		"Đôi liềm kỳ bí. Phù hợp Thích Khách. Skill cơ bản: Reap.")
	_blank(
		"phoi_no_ban", "Nỏ Bắn", 10, 0, 0, ["tho_san", "thich_khach"], 310,
		"Nỏ cơ khí xuyên giáp. Phù hợp Thợ Săn và Thích Khách. Skill cơ bản: Pierce.",
		"pierce")


# ═══════════════════════════════════════════════════════════
# CONSUMABLE — 12 items
# effect_data: effect_type + value
# effect_type: "heal_flat", "heal_pct", "stamina", "cleanse",
#              "escape", "revive", "forge_bonus", "buff_def", "buff_atk",
#              "repair", "poison_coat", "resist"
# ═══════════════════════════════════════════════════════════

static func _build_consumables() -> void:

	# Từ GDD gốc
	_cons("banh_mat",       "Bánh Mật",         "heal_flat",    20.0,   100,
		"Hồi 20 HP. Mua từ Bà Bán Thuốc ở mỗi vùng.")
	_cons("binh_suong",     "Bình Sương",        "stamina",       1.0,   150,
		"Hồi 1 Stamina ngay lập tức.")
	_cons("tra_thao_moc",   "Trà Thảo Mộc",     "cleanse",       1.0,   200,
		"Xóa 1 debuff đang tác động.")
	_cons("khoi_tron",      "Khói Trốn",         "escape",        1.0,   300,
		"Thoát khỏi combat thường ngay lập tức.")
	_cons("da_hoi_sinh",    "Đá Hồi Sinh",       "revive",        0.5,  1500,
		"Hồi sinh 1 lần với 50% HP khi bị đánh ngã trong trận.")
	_cons("tro_lo_mini",    "Tro Lò Thiêng",     "forge_bonus",   1.0,   500,
		"Dùng trong Phase 2 rèn: +1 điểm Perfect timing cho nhát búa tiếp theo.")

	# Mở rộng thêm 6
	_cons("chao_hoi_suc",   "Cháo Hồi Sức",     "heal_flat",    40.0,   250,
		"Hồi 40 HP. Hiệu quả hơn Bánh Mật nhưng đắt hơn.")
	_cons("dau_boi_vu_khi", "Dầu Bôi Vũ Khí",   "repair",       20.0,   300,
		"Sửa 20 Durability cho 1 vũ khí ngay trong combat.")
	_cons("bua_ho_menh",    "Bùa Hộ Mệnh",       "buff_def",      5.0,   350,
		"Tăng 5 DEF trong 3 lượt combat.")
	_cons("binh_lua",       "Bình Lửa",           "buff_atk",      8.0,   400,
		"Ném bình lửa: gây 8 sát thương Hỏa trực tiếp, không tính DEF.")
	_cons("thao_duoc_rung", "Thảo Dược Rừng",    "heal_pct",      0.25,  320,
		"Hồi 25% HP tối đa. Rẻ hơn Đá Hồi Sinh nhưng cần dùng trước khi chết.")
	_cons("vien_giai_doc",  "Viên Giải Độc",     "cleanse",       2.0,   250,
		"Xóa toàn bộ stack Poison đang tích lũy.")
