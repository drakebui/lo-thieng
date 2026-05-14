# data/EnemyDatabase.gd
# Chứa toàn bộ enemies theo từng vùng.
# Dùng: EnemyDatabase.get_enemy("soi")
#        EnemyDatabase.get_enemies_by_region("DongMay")

class_name EnemyDatabase
extends Node

static var _enemies:     Dictionary = {}
static var _initialized: bool       = false

# ─── Public API ───────────────────────────────────────────

static func get_enemy(enemy_id: String) -> EnemyData:
	_init_if_needed()
	return _enemies.get(enemy_id, null)

static func get_enemies_by_region(region_id: String) -> Array[EnemyData]:
	_init_if_needed()
	var result: Array[EnemyData] = []
	for enemy in _enemies.values():
		if enemy.region == region_id:
			result.append(enemy)
	return result

static func get_all() -> Array[EnemyData]:
	_init_if_needed()
	var result: Array[EnemyData] = []
	for enemy in _enemies.values():
		result.append(enemy)
	return result

# ─── Internal ─────────────────────────────────────────────

static func _init_if_needed() -> void:
	if _initialized:
		return
	_build_enemies()
	_initialized = true

static func _register(enemy: EnemyData) -> void:
	_enemies[enemy.enemy_id] = enemy

static func _e(
		id: String, name: String, region: String,
		archetype: String, hp: int, atk: int, def: int,
		magic: int, speed: int, gold: int, color: Color
) -> void:
	var e          := EnemyData.new()
	e.enemy_id     = id
	e.enemy_name   = name
	e.region       = region
	e.archetype    = archetype
	e.hp           = hp
	e.atk          = atk
	e.def_stat     = def
	e.magic        = magic
	e.speed        = speed
	e.drop_gold    = gold
	e.color        = color
	e.loot_items   = _loot_for_region(region)
	# Crit rate mặc định theo archetype; có thể override riêng nếu cần
	match archetype:
		"aggressive": e.crit_rate = 0.25
		"caster":     e.crit_rate = 0.20
		"defensive":  e.crit_rate = 0.10
		"boss":       e.crit_rate = 0.30
		_:            e.crit_rate = 0.15
	_register(e)


static func _loot_for_region(region: String) -> Array[Dictionary]:
	var loot: Array[Dictionary] = []
	match region:
		"DongMay":
			loot.append({"item_id": "sat_tho", "chance": 0.65})
			loot.append({"item_id": "da_thu", "chance": 0.50})
			loot.append({"item_id": "dong_co_kho", "chance": 0.35})
			loot.append({"item_id": "bac_manh", "chance": 0.20})
		"RungTramHon":
			loot.append({"item_id": "nhua_linh", "chance": 0.65})
			loot.append({"item_id": "go_co_thu", "chance": 0.45})
			loot.append({"item_id": "pha_le_rung", "chance": 0.35})
			loot.append({"item_id": "la_hon", "chance": 0.15})
		"NuiThanDo":
			loot.append({"item_id": "quang_than", "chance": 0.65})
			loot.append({"item_id": "da_hoa_son", "chance": 0.40})
			loot.append({"item_id": "thep_hoa_son", "chance": 0.30})
			loot.append({"item_id": "mithril_tho", "chance": 0.12})
		"BaiCat":
			loot.append({"item_id": "cat_thieng", "chance": 0.65})
			loot.append({"item_id": "xuong_ca", "chance": 0.45})
			loot.append({"item_id": "ho_phach", "chance": 0.30})
			loot.append({"item_id": "da_vang", "chance": 0.12})
		"ThanhNgoc":
			loot.append({"item_id": "da_ngoc", "chance": 0.65})
			loot.append({"item_id": "thep_trang", "chance": 0.40})
			loot.append({"item_id": "soi_vang", "chance": 0.30})
			loot.append({"item_id": "ngoc_tho", "chance": 0.12})
		"LangTo":
			loot.append({"item_id": "tro_lo_to", "chance": 0.55})
			loot.append({"item_id": "go_to_nghe", "chance": 0.40})
			loot.append({"item_id": "di_thach", "chance": 0.18})
			loot.append({"item_id": "manh_thieng", "chance": 0.10})
	return loot


# ═══════════════════════════════════════════════════════════
# ENEMIES — theo vùng
# ═══════════════════════════════════════════════════════════

static func _build_enemies() -> void:

	# ── Đồng Mây Trắng ────────────────────────────────────
	_e("soi",       "Sói Hoang",    "DongMay",    "aggressive", 72, 13, 3,  0, 6, 45,  Color(0.55, 0.25, 0.12))
	_e("nguoi_da",  "Người Đá",     "DongMay",    "defensive",  75, 11, 6,  0, 4, 60,  Color(0.42, 0.42, 0.45))
	_e("ma_rung",   "Ma Rừng",      "DongMay",    "caster",     60,  5, 2, 10, 8, 75,  Color(0.22, 0.45, 0.35))

	# ── Rừng Trăm Hồn ─────────────────────────────────────
	_e("hon_co_thu",   "Hồn Cổ Thụ",   "RungTramHon", "defensive",  48,  8, 4,  5, 5, 80,  Color(0.18, 0.38, 0.22))
	_e("ma_linh_hoa",  "Ma Linh Hỏa",  "RungTramHon", "caster",     32,  6, 0, 14, 9, 90,  Color(0.72, 0.32, 0.12))
	_e("thu_an",       "Thú Ăn Thịt",  "RungTramHon", "aggressive", 42, 12, 2,  0, 7, 70,  Color(0.38, 0.22, 0.15))

	# ── Núi Than Đỏ ───────────────────────────────────────
	_e("golem_than",   "Golem Than",    "NuiThanDo",   "defensive",  70, 10, 8,  0, 3, 110, Color(0.28, 0.28, 0.28))
	_e("linh_hoa",     "Linh Hỏa",     "NuiThanDo",   "caster",     35,  7, 1, 16, 8, 120, Color(0.88, 0.38, 0.12))
	_e("tho_mo_do",    "Thổ Mỏ Đỏ",   "NuiThanDo",   "aggressive", 50, 13, 3,  0, 6, 100, Color(0.62, 0.28, 0.18))

	# ── Bãi Cát Thần Vàng ─────────────────────────────────
	_e("ran_cat",      "Rắn Cát",      "BaiCat",      "aggressive", 40, 10, 1,  0, 9, 85,  Color(0.75, 0.65, 0.28))
	_e("xac_uop",      "Xác Ướp",      "BaiCat",      "defensive",  60,  8, 6,  4, 4, 95,  Color(0.55, 0.48, 0.32))
	_e("quy_cat",      "Quỷ Cát",      "BaiCat",      "caster",     30,  5, 0, 18, 10, 130, Color(0.82, 0.72, 0.18))

	# ── Thành Ngọc Bích ───────────────────────────────────
	_e("linh_binh",    "Linh Binh",    "ThanhNgoc",   "defensive",  65, 12, 7,  0, 5, 140, Color(0.25, 0.55, 0.65))
	_e("ma_gia",       "Ma Giáo",      "ThanhNgoc",   "caster",     38,  8, 2, 20, 9, 160, Color(0.42, 0.25, 0.72))
	_e("than_linh",    "Thần Linh",    "ThanhNgoc",   "boss",       90, 15, 6, 12, 6, 250, Color(0.85, 0.82, 0.35))

	# ── Làng Tổ Nghề ──────────────────────────────────────
	_e("hon_to_nghe",  "Hồn Tổ Nghề",  "LangTo",     "boss",      120, 18, 8, 15, 7, 400, Color(0.92, 0.78, 0.25))
	_e("quy_lo_thieng","Quỷ Lò Thiêng","LangTo",     "caster",     55,  9, 3, 24, 10, 300, Color(0.62, 0.12, 0.12))
	_e("chien_binh_co","Chiến Binh Cổ","LangTo",     "aggressive", 75, 20, 5,  0, 8, 280, Color(0.48, 0.42, 0.35))
