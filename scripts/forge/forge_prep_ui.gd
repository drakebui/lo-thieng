# gdlint: disable=max-file-lines
# Mặt Bàn Thợ Rèn 32-Bit Hữu Cơ (640×360 × 3 = 1920×1080) — Camera Cúi Nhìn 2 Vùng
# Vùng 1: Cúi đọc Sổ Cẩm Nang (3 kẹp I/II/III, 1 phôi/trang mở) & Tờ Giấy Đơn Hàng
# Vùng 2: Túi Da & Quặng bày hữu cơ trên Tấm Vải Lanh + Nút Dấu Sáp Đỏ khởi lò
extends Control

signal weapon_confirmed(weapon_id: String)
signal forge_ready(weapon_id: String, materials: Array)

const _FORGE1_SCRIPT := preload("res://scripts/forge/forge_system.gd")
const _PHASE3_SCRIPT := preload("res://scripts/forge/forge_phase3.gd")

# Tỷ lệ bàn rèn gốc 640×360 phóng nguyên 3× lên 1920×1080 (đạt 0% mixel)
const WB_SCALE := 3.0
const PAGE_SSAA := 2.0

enum FocusZone { FOCUS_BOOK, FOCUS_CLOTH }

# Vùng nội dung cần hiển thị trọn vẹn (tọa độ trên bàn gốc 1920×1080) — tự động co vừa mọi độ phân giải cửa sổ
const FOCUS_RECTS: Dictionary = {
	FocusZone.FOCUS_BOOK: Rect2(Vector2(24.0, 88.0), Vector2(1384.0, 824.0)),
	FocusZone.FOCUS_CLOTH: Rect2(Vector2(520.0, 194.0), Vector2(1396.0, 826.0)),
}

# Shader bóng tiếp xúc màu nâu mận ấm RGB(18, 10, 12) đổ xuống mặt bàn gỗ
const SHADOW_SHADER_CODE := """shader_type canvas_item;
uniform float shadow_alpha = 0.45;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(0.0706, 0.0392, 0.0471, step(0.5, tex.a) * shadow_alpha);
}
"""

# Shader uốn cong nội dung 2 trang sách theo vòm giấy tự nhiên + đổ bóng gáy sách
const PAGE_WARP_SHADER_CODE := """shader_type canvas_item;
uniform float page_side = -1.0;
uniform float arch_strength = 0.092;
uniform float spine_shadow = 0.42;
void fragment() {
	float d_spine = (page_side < 0.0) ? (1.0 - UV.x) : UV.x;
	float arch = sin(pow(clamp(d_spine, 0.0, 1.0), 0.62) * 3.14159265);
	float curve = mix(arch, 0.22, smoothstep(0.66, 1.0, d_spine) * (1.0 - arch));
	vec2 warped_uv = vec2(UV.x, UV.y + curve * arch_strength);
	if (warped_uv.y < 0.0 || warped_uv.y > 1.0) {
		COLOR = vec4(0.0);
	} else {
		vec4 col = texture(TEXTURE, warped_uv);
		float shade = mix(1.0 - spine_shadow, 1.0, smoothstep(0.0, 0.28, d_spine));
		COLOR = vec4(col.rgb * shade, col.a);
	}
}
"""

const PATH_BG := "res://assets/pixel/backgrounds/forge_workbench_bg_640x360.png"
const PATH_GRIMOIRE := "res://assets/pixel/ui/forge/forge_grimoire_open.png"
const PATH_CLOTH_MAT := "res://assets/pixel/ui/forge/forge_cloth_mat.png"
const PATH_LEATHER_POUCH := "res://assets/pixel/ui/forge/forge_leather_pouch.png"
const PATH_WAX_SEAL_BTN := "res://assets/pixel/ui/forge/forge_wax_seal_btn.png"
const PATH_COMMISSION_NOTE := "res://assets/pixel/ui/forge/forge_commission_note.png"
const PATH_WEAPONS := "res://assets/pixel/sprites/weapons/"
const PATH_MAT_ICONS := "res://assets/pixel/ui/materials/"
const PATH_FONT_PIXELIFY := "res://assets/fonts/PixelifySans.ttf"
const PATH_FONT_LORA := "res://assets/fonts/Lora-Regular.ttf"
const PATH_FONT_LORA_ITALIC := "res://assets/fonts/Lora-Italic.ttf"
const PATH_FORGE_SESSION := "res://scenes/forge/ForgeSession.tscn"
const PATH_WORKSHOP := "res://scenes/main/WorkshopHub.tscn"

# Bảng màu mực cổ & Hoả Tâm 32-bit
const COL_BRONZE := Color(0.76, 0.56, 0.24, 0.92)
const COL_GOLD := Color(1.0, 0.84, 0.36, 1.0)
const COL_SEL := Color(0.28, 0.15, 0.06, 0.96)
const COL_TEXT := Color(0.96, 0.90, 0.78, 1.0)
const COL_WARN := Color(0.96, 0.44, 0.34, 1.0)
const COL_OUTLINE := Color(0.0706, 0.0471, 0.0627, 0.96)  # #120C10
const COL_INK := Color(0.18, 0.09, 0.04, 1.0)
const COL_INK_MUTED := Color(0.39, 0.25, 0.14, 1.0)
const COL_INK_ACCENT := Color(0.58, 0.14, 0.08, 1.0)
const COL_INK_GOOD := Color(0.16, 0.38, 0.16, 1.0)
const COL_AMBER_GLOW := Color(1.0, 0.76, 0.24, 0.95)

# Ánh xạ mã nguyên liệu cũ sang mã chuẩn ItemDatabase để tương thích kho đồ
const MATERIAL_INVENTORY_ALIASES := {
	"dong_co_kho": ["dong_co_kho", "dong_vun"],
	"bac_manh": ["bac_manh", "bac_vun"],
	"go_co_thu": ["go_co_thu", "go_linh"],
	"pha_le_rung": ["pha_le_rung", "pha_le"],
	"mithril_tho": ["mithril_tho", "mithril"],
	"thep_hoa_son": ["thep_hoa_son", "vas_rong"],
	"cat_thieng": ["cat_thieng", "cat_than"],
	"go_to_nghe": ["go_to_nghe", "go_linh"],
	"tro_lo_to": ["tro_lo_to", "tro_thieng"],
	"manh_thieng": ["manh_thieng", "tinh_the_lo"],
}

const MATERIAL_ICON_FILES := {
	"sat_tho": "sat_tho.png", "dong_co_kho": "dong_co_kho.png",
	"da_thu": "da_thu.png", "bac_manh": "bac_manh.png",
	"go_co_thu": "go_co_thu.png", "pha_le_rung": "pha_le_rung.png",
	"nhua_linh": "nhua_linh.png", "la_hon": "la_hon.png",
	"quang_than": "quang_than.png", "mithril_tho": "mithril_tho.png",
	"da_hoa_son": "da_hoa_son.png", "thep_hoa_son": "thep_hoa_son.png",
	"cat_thieng": "cat_thieng.png", "ho_phach": "ho_phach.png",
	"xuong_ca": "xuong_ca.png", "da_vang": "da_vang.png",
	"thep_trang": "thep_trang.png", "ngoc_tho": "ngoc_tho.png",
	"soi_vang": "soi_vang.png", "da_ngoc": "da_ngoc.png",
	"di_thach": "di_thach.png", "go_to_nghe": "go_to_nghe.png",
	"tro_lo_to": "tro_lo_to.png", "manh_thieng": "manh_thieng.png",
}

const NPC_DISPLAY_NAMES := {
	"nong_dan": "Trâu Nông Dân",
	"ve_binh": "Sói Vệ Binh",
	"tho_san": "Cáo Thợ Săn",
	"hiep_khach": "Mèo Hiệp Khách",
	"thuong_nhan": "Lửng Thương Nhân",
	"thich_khach": "Chồn Thích Khách",
	"dao_si": "Hạc Đạo Sĩ",
	"vo_tang": "Gấu Võ Tăng",
	"thu_ve": "Lợn Rừng Thủ Vệ",
}

# Thứ tự chuẩn 3 kẹp trang:
# Kẹp I (3 phôi cận chiến linh hoạt C1) | Kẹp II (3 phôi hạng nặng & huyền thuật C1) | Kẹp III (6 phôi bí truyền C2+)
const WEAPON_ORDER: Array[String] = [
	"kiem_don", "song_dao", "giao_dai",
	"bua_chien", "khien_dong", "gay_phep",
	"cung_truong", "quyen_cu", "con_nhi_khuc",
	"dao_phat", "liem_song", "phoi_no_ban",
]

const CHAPTER1_BLANKS: Array[String] = [
	"kiem_don", "song_dao", "giao_dai",
	"bua_chien", "khien_dong", "gay_phep",
]

const WEAPON_DATA: Dictionary = {
	"kiem_don": {
		"name": "Kiếm Đơn", "chapter": 1, "atk": 12, "def": 0, "magic": 3, "speed": 6,
		"skill": "tram_chuan", "skill_name": "Trảm Chuẩn",
		"skill_desc": "1.15× ATK sát thương ổn định",
		"lore": "Lưỡi kiếm nhập môn của thợ rèn Lò Thiêng, cân bằng giữa công và thủ.",
		"customers": "Hiệp Khách", "required_tier": 1, "required_quantity": 2,
		"asset": "kiem_don",
	},
	"song_dao": {
		"name": "Song Đao", "chapter": 1, "atk": 10, "def": 0, "magic": 2, "speed": 8,
		"skill": "song_nha", "skill_name": "Song Nha",
		"skill_desc": "Chém 2 nhát liên hoàn (0.65× ATK mỗi nhát)",
		"lore": "Đôi đoản đao rèn song sinh, nhẹ như lá thu nhưng sắc bén khó lường.",
		"customers": "Thích Khách", "required_tier": 2, "required_quantity": 4,
		"asset": "song_dao",
	},
	"giao_dai": {
		"name": "Giáo Dài", "chapter": 1, "atk": 13, "def": 2, "magic": 1, "speed": 5,
		"skill": "truong_thuong", "skill_name": "Trường Thương Tiên Phong",
		"skill_desc": "1.00× ATK + luôn đánh trước địch",
		"lore": "Mũi thương vươn xa giữ khoảng cách, giành tiên cơ trước mãnh thú.",
		"customers": "Thủ Vệ, Hiệp Khách", "required_tier": 1, "required_quantity": 2,
		"asset": "giao_dai",
	},
	"bua_chien": {
		"name": "Búa Chiến", "chapter": 2, "atk": 15, "def": 3, "magic": 0, "speed": 3,
		"skill": "chan_son_chuy", "skill_name": "Chấn Sơn Chùy",
		"skill_desc": "1.10× ATK + phá giáp −2 DEF địch (2 lượt)",
		"lore": "Khối thép nặng trịch nung già lửa, một đòn rung chuyển cả lớp giáp dày.",
		"customers": "Võ Tăng, Thủ Vệ", "required_tier": 2, "required_quantity": 4,
		"asset": "bua_chien",
	},
	"khien_dong": {
		"name": "Khiên Đồng", "chapter": 2, "atk": 6, "def": 8, "magic": 0, "speed": 4,
		"skill": "thuan_kich", "skill_name": "Thuẫn Kích",
		"skill_desc": "0.80× ATK + dựng khiên +3 DEF trong 1 lượt",
		"lore": "Mặt khiên đúc từ đồng tổ nghề, vừa hóa giải đòn nặng vừa phản chấn.",
		"customers": "Thủ Vệ", "required_tier": 1, "required_quantity": 2,
		"asset": "khien_dong",
	},
	"gay_phep": {
		"name": "Gậy Phép", "chapter": 2, "atk": 5, "def": 0, "magic": 12, "speed": 6,
		"skill": "linh_dan", "skill_name": "Linh Đạn",
		"skill_desc": "1.15× Phép + xuyên 50% giáp vật lý địch",
		"lore": "Trượng dẫn linh khí thanh khiết, đánh thẳng vào bản thể kẻ thù.",
		"customers": "Đạo Sĩ", "required_tier": 2, "required_quantity": 4,
		"asset": "gay_phep",
	},
	"cung_truong": {
		"name": "Cung Trường", "chapter": 3, "atk": 11, "def": 0, "magic": 4, "speed": 7,
		"skill": "aim", "skill_name": "Bách Bộ Xuyên Dương",
		"skill_desc": "Bỏ qua 30% DEF địch",
		"lore": "Cánh cung gỗ linh lực uốn dưới lửa Núi Than Đỏ.",
		"customers": "Thợ Săn", "required_tier": 2, "required_quantity": 4,
		"asset": "cung_truong",
	},
	"quyen_cu": {
		"name": "Quyền Cụ", "chapter": 3, "atk": 9, "def": 1, "magic": 2, "speed": 9,
		"skill": "combo", "skill_name": "Liên Hoàn Quyền",
		"skill_desc": "Đánh 3 lần liên tiếp",
		"lore": "Bao tay thép rèn theo thế quyền cổ của võ tăng phương Nam.",
		"customers": "Võ Tăng", "required_tier": 2, "required_quantity": 4,
		"asset": "quyen_cu",
	},
	"con_nhi_khuc": {
		"name": "Côn Nhị Khúc", "chapter": 3, "atk": 10, "def": 1, "magic": 3, "speed": 8,
		"skill": "whirl", "skill_name": "Toàn Phong Côn",
		"skill_desc": "Quét sát thương diện rộng",
		"lore": "Hai đoạn thiết mộc nối xích đồng, xoay tít như gió lốc.",
		"customers": "Võ Tăng, Thích Khách", "required_tier": 2, "required_quantity": 4,
		"asset": "con_nhi_khuc",
	},
	"dao_phat": {
		"name": "Đao Phạt", "chapter": 3, "atk": 16, "def": 2, "magic": 0, "speed": 4,
		"skill": "heavy_cleave", "skill_name": "Trọng Đao Trảm",
		"skill_desc": "+100% sát thương, mất lượt sau",
		"lore": "Đại đao bản rộng chuyên phá trận, đòi hỏi quặng bậc Thượng.",
		"customers": "Thủ Vệ đặc biệt", "required_tier": 3, "required_quantity": 6,
		"asset": "dao_phat",
	},
	"liem_song": {
		"name": "Liềm Song", "chapter": 3, "atk": 11, "def": 0, "magic": 2, "speed": 7,
		"skill": "reap", "skill_name": "Đoạt Hồn Liềm",
		"skill_desc": "Tấn công kèm gây Độc",
		"lore": "Đôi lưỡi liềm cong tẩm sương đêm từ vùng đất cổ.",
		"customers": "Thích Khách", "required_tier": 3, "required_quantity": 6,
		"asset": "liem_song",
	},
	"phoi_no_ban": {
		"name": "Nỏ Bắn", "chapter": 3, "atk": 15, "def": 0, "magic": 0, "speed": 4,
		"skill": "pierce", "skill_name": "Phá Giáp Nỏ",
		"skill_desc": "Xuyên 100% DEF địch",
		"lore": "Cơ quan nỏ liên châu tinh xảo bậc nhất của Tổ Nghề.",
		"customers": "Thợ Săn, Thích Khách", "required_tier": 3, "required_quantity": 6,
		"asset": "phoi_no_ban",
	},
}

# Tọa độ rải hình quạt tự nhiên từ miệng Túi Da (góc trên-phải) lan ra giữa & trái-dưới Tấm Vải Lanh (612×408)
const CLOTH_PILE_SLOTS: Array[Dictionary] = [
	{"pos": Vector2(362.0, 152.0), "rot": -7.5, "scale": 1.04, "tag_rot": 5.0},
	{"pos": Vector2(246.0, 126.0), "rot": 6.2,  "scale": 0.98, "tag_rot": -6.0},
	{"pos": Vector2(126.0, 162.0), "rot": -9.0, "scale": 0.96, "tag_rot": 4.5},
	{"pos": Vector2(288.0, 236.0), "rot": -4.2, "scale": 1.06, "tag_rot": 7.0},
	{"pos": Vector2(168.0, 266.0), "rot": 8.5,  "scale": 0.95, "tag_rot": -5.5},
	{"pos": Vector2(416.0, 248.0), "rot": 5.0,  "scale": 1.00, "tag_rot": -4.0},
	{"pos": Vector2(496.0, 206.0), "rot": -6.8, "scale": 0.94, "tag_rot": 6.0},
	{"pos": Vector2(236.0, 316.0), "rot": 3.4,  "scale": 0.96, "tag_rot": -3.5},
	{"pos": Vector2(354.0, 314.0), "rot": -5.8, "scale": 1.02, "tag_rot": 4.0},
	{"pos": Vector2(472.0, 304.0), "rot": 6.6,  "scale": 0.95, "tag_rot": -6.5},
	{"pos": Vector2(96.0, 224.0),  "rot": -3.5, "scale": 0.92, "tag_rot": 5.5},
	{"pos": Vector2(484.0, 132.0), "rot": 7.0,  "scale": 0.94, "tag_rot": -5.0},
]

var _current_weapon: String = "kiem_don"
var _selected_material_id: String = ""
var _focus_zone: FocusZone = FocusZone.FOCUS_BOOK
var _camera_tween: Tween
var _material_catalog: Dictionary = {}
var _material_order: Array[String] = []
var _active_commission_info: Dictionary = {}

var _font_pixel: Font
var _font_lora: Font
var _font_lora_italic: Font
var _shadow_shader: Shader
var _page_warp_shader: Shader

var _table_world: Control
var _workbench_props: Dictionary = {}
var _bookmark_tabs: Dictionary = {}

# Widgets Cuốn Sổ Cẩm Nang (Vùng 1)
var _page_num_lbl: Label
var _page_comm_lbl: Label
var _weapon_preview: TextureRect
var _sealed_stamp_lbl: Label
var _weapon_title: Label
var _weapon_lore_lbl: Label
var _recipe_qty_lbl: Label
var _stock_check_lbl: Label
var _heat_profile_lbl: Label
var _stats_labels: Dictionary = {}
var _skill_name_lbl: Label
var _skill_lbl: Label
var _book_focus_overlay: Button

# Widgets Tờ Giấy Đơn Hàng (+3.8°)
var _note_title_lbl: Label
var _note_detail_lbl: Label
var _note_click_btn: Button

# Widgets Tấm Vải Lanh (+1.8°) & Túi Da (-18.0°) (Vùng 2)
var _cloth_focus_overlay: Button
var _cloth_items_layer: Control
var _cloth_empty_lbl: Label
var _cloth_info_lbl: Label
var _cloth_mat_nodes: Dictionary = {}
var _pouch_btn: Button

# Widgets Nút Dấu Sáp Đỏ (-0.8°)
var _wax_btn: Button
var _wax_title_lbl: Label
var _wax_hint_lbl: Label
var _wax_hovered: bool = false
var _wax_pulse_tween: Tween

# HUD chuyển vùng gọn
var _hud_zone_book_btn: Button
var _hud_zone_cloth_btn: Button
var _is_starting_forge: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	theme = preload("res://assets/fonts/hoa_tam_pixel_theme.tres")
	_load_fonts()
	_load_material_catalog()
	_build_ui()
	_setup_phase_indicator()

	var init_id := String(GameManager.selected_blank.get("id", "kiem_don"))
	_select_blank(init_id if WEAPON_DATA.has(init_id) else "kiem_don")
	if GameManager.forge_return_to_material_step:
		GameManager.forge_return_to_material_step = false
		_restore_previous_selection()
		_set_focus_zone(FocusZone.FOCUS_CLOTH, true)
	else:
		_set_focus_zone(FocusZone.FOCUS_BOOK, true)
	resized.connect(_on_viewport_resized)
	call_deferred("_on_viewport_resized")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if _focus_zone == FocusZone.FOCUS_BOOK:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_turn_book_page(-1)
				return
			if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_turn_book_page(1)
				return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_ESCAPE:
			_on_back_pressed()
		KEY_TAB:
			var next_zone := (
				FocusZone.FOCUS_CLOTH
				if _focus_zone == FocusZone.FOCUS_BOOK
				else FocusZone.FOCUS_BOOK
			)
			_set_focus_zone(next_zone)
			get_viewport().set_input_as_handled()
		KEY_E:
			_set_focus_zone(FocusZone.FOCUS_CLOTH)
		KEY_Q:
			_set_focus_zone(FocusZone.FOCUS_BOOK)
		KEY_LEFT, KEY_A:
			if _focus_zone == FocusZone.FOCUS_BOOK:
				_turn_book_page(-1)
		KEY_RIGHT, KEY_D:
			if _focus_zone == FocusZone.FOCUS_BOOK:
				_turn_book_page(1)
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			if _focus_zone == FocusZone.FOCUS_CLOTH and _wax_btn != null and not _wax_btn.disabled:
				get_viewport().set_input_as_handled()
				_on_start_forge_pressed()


# --- Nạp Font tiếng Việt (Pixelify Sans & Lora) & Danh Mục 24 Nguyên Liệu ---

func _load_fonts() -> void:
	_font_pixel = _try_load_font(PATH_FONT_PIXELIFY)
	_font_lora = _try_load_font(PATH_FONT_LORA)
	_font_lora_italic = _try_load_font(PATH_FONT_LORA_ITALIC)
	if _font_lora_italic == null:
		_font_lora_italic = _font_lora


func _try_load_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		var res := load(path) as Font
		if res != null:
			return res
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		var ff := FontFile.new()
		if ff.load_dynamic_font(abs_path) == OK:
			return ff
	return null


func _load_material_catalog() -> void:
	_material_catalog.clear()
	_material_order.clear()
	for item: ItemData in ItemDatabase.get_items_by_type(ItemData.ItemType.MATERIAL):
		var eff: Dictionary = item.effect_data
		var icon_file: String = MATERIAL_ICON_FILES.get(item.item_id, "")
		_material_catalog[item.item_id] = {
			"id": item.item_id,
			"name": item.item_name,
			"tier": item.rarity,
			"atk": int(eff.get("atk_bonus", 0)),
			"def": int(eff.get("def_bonus", 0)),
			"magic": int(eff.get("magic_bonus", 0)),
			"speed": int(eff.get("speed_bonus", 0)),
			"price_mult": float(eff.get("price_mult", 1.0)),
			"phase1_min": String(eff.get("phase1_min", "")),
			"allowed_elements": Array(eff.get("allowed_elements", ["hoa", "phong", "tho"])),
			"icon": (PATH_MAT_ICONS + icon_file) if icon_file != "" else "",
		}
		_material_order.append(item.item_id)

	_material_order.sort_custom(func(a: String, b: String) -> bool:
		var ta: int = int(_material_catalog[a]["tier"])
		var tb: int = int(_material_catalog[b]["tier"])
		if ta != tb:
			return ta < tb
		return String(_material_catalog[a]["name"]) < String(_material_catalog[b]["name"])
	)


# --- Dựng Mặt Bàn Thợ Rèn Hữu Cơ 640×360 (×3 = 1920×1080) & Camera 2 Vùng ---

func _build_ui() -> void:
	_shadow_shader = Shader.new()
	_shadow_shader.code = SHADOW_SHADER_CODE
	_page_warp_shader = Shader.new()
	_page_warp_shader.code = PAGE_WARP_SHADER_CODE

	# Khung thế giới bàn rèn 1920×1080 — mọi vật thể & mặt bàn phóng đồng bộ để đạt 0% mixel
	_table_world = Control.new()
	_table_world.name = "WorkbenchWorld"
	_table_world.position = Vector2.ZERO
	_table_world.size = Vector2(640.0 * WB_SCALE, 360.0 * WB_SCALE)
	_table_world.pivot_offset = Vector2.ZERO
	_table_world.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_table_world)

	# 1. Nền mặt bàn gỗ thợ rèn 640×360 phóng 3× chuẩn 1920×1080
	var bg := _make_tex(_try_load_tex(PATH_BG), Vector2.ZERO, TextureRect.STRETCH_SCALE)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_table_world.add_child(bg)

	# 2. Tấm Vải Lanh (204×136) — tâm (468, 196), xoay +1.8°
	var cloth_root := _place_organic_prop(
		"ClothMatProp", PATH_CLOTH_MAT,
		Vector2(204.0, 136.0), Vector2(468.0, 196.0), 1.8, Vector2(2.5, 3.5), 0.36
	)
	_workbench_props["cloth"] = cloth_root
	_populate_cloth_mat(cloth_root)

	# 3. Cuốn Sổ Cẩm Nang (304×176) — tâm (186, 206), xoay -1.6°
	var book_root := _place_organic_prop(
		"GrimoireProp", PATH_GRIMOIRE,
		Vector2(304.0, 176.0), Vector2(186.0, 206.0), -1.6, Vector2(3.5, 5.5), 0.48
	)
	_workbench_props["book"] = book_root
	_populate_grimoire_pages(book_root)

	# 4. Tờ Giấy Đơn Hàng (144×56 — không đinh) — tâm (294, 66), xoay +3.8°
	var note_root := _place_organic_prop(
		"CommissionNoteProp", PATH_COMMISSION_NOTE,
		Vector2(144.0, 56.0), Vector2(294.0, 66.0), 3.8, Vector2(2.0, 3.5), 0.42
	)
	_workbench_props["note"] = note_root
	_populate_commission_note(note_root)

	# 5. Túi Da (100×96) — tâm (514, 114), xoay +28.0° (thuận chiều kim đồng hồ, miệng chĩa vào đống quặng)
	var pouch_root := _place_organic_prop(
		"LeatherPouchProp", PATH_LEATHER_POUCH,
		Vector2(100.0, 96.0), Vector2(514.0, 114.0), 28.0, Vector2(3.5, 5.5), 0.50
	)
	_workbench_props["pouch"] = pouch_root
	_populate_leather_pouch(pouch_root)

	# 6. Nút Dấu Sáp Đỏ (168×54) — tâm (492, 306), xoay -0.8°
	var wax_root := _place_organic_prop(
		"WaxSealProp", PATH_WAX_SEAL_BTN,
		Vector2(168.0, 54.0), Vector2(492.0, 306.0), -0.8, Vector2(3.0, 4.5), 0.48
	)
	_workbench_props["wax"] = wax_root
	_populate_wax_seal_btn(wax_root)

	# HUD nổi cố định (không phóng theo mặt bàn)
	_build_fixed_hud()


func _build_fixed_hud() -> void:
	# Thanh điều hướng góc trên-trái: đặt chung 1 HBoxContainer để tuyệt đối không đè chữ nhau
	var nav_bar := HBoxContainer.new()
	nav_bar.position = Vector2(18.0, 14.0)
	nav_bar.add_theme_constant_override("separation", 10)
	add_child(nav_bar)

	var back_btn := Button.new()
	back_btn.text = "← Xưởng (Esc)"
	back_btn.custom_minimum_size = Vector2(150.0, 36.0)
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	HoaTamUI.apply_flat_tab_button(back_btn, false, 17)
	back_btn.pressed.connect(_on_back_pressed)
	nav_bar.add_child(back_btn)

	_hud_zone_book_btn = Button.new()
	_hud_zone_book_btn.text = "[Q] Sổ Cẩm Nang"
	_hud_zone_book_btn.custom_minimum_size = Vector2(196.0, 36.0)
	_hud_zone_book_btn.focus_mode = Control.FOCUS_NONE
	_hud_zone_book_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	HoaTamUI.apply_flat_tab_button(_hud_zone_book_btn, true, 17)
	_hud_zone_book_btn.pressed.connect(_set_focus_zone.bind(FocusZone.FOCUS_BOOK, false))
	nav_bar.add_child(_hud_zone_book_btn)

	_hud_zone_cloth_btn = Button.new()
	_hud_zone_cloth_btn.text = "[E] Quặng & Khởi Lò"
	_hud_zone_cloth_btn.custom_minimum_size = Vector2(214.0, 36.0)
	_hud_zone_cloth_btn.focus_mode = Control.FOCUS_NONE
	_hud_zone_cloth_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	HoaTamUI.apply_flat_tab_button(_hud_zone_cloth_btn, false, 17)
	_hud_zone_cloth_btn.pressed.connect(_set_focus_zone.bind(FocusZone.FOCUS_CLOTH, false))
	nav_bar.add_child(_hud_zone_cloth_btn)


func _place_organic_prop(
	node_name: String,
	tex_path: String,
	base_size: Vector2,
	base_center: Vector2,
	angle_deg: float,
	shadow_offset: Vector2,
	shadow_alpha: float
) -> Control:
	var tex := _try_load_tex(tex_path)
	var scaled_sz := base_size * WB_SCALE
	var scaled_center := base_center * WB_SCALE
	var sh_off := shadow_offset * WB_SCALE

	# Bóng tiếp xúc màu nâu mận ấm đổ xuống mặt bàn gỗ
	var shadow := _make_tex(tex, Vector2.ZERO, TextureRect.STRETCH_SCALE)
	shadow.name = node_name + "Shadow"
	shadow.size = scaled_sz
	shadow.pivot_offset = scaled_sz * 0.5
	shadow.position = scaled_center - scaled_sz * 0.5 + sh_off
	shadow.rotation_degrees = angle_deg
	var sh_mat := ShaderMaterial.new()
	sh_mat.shader = _shadow_shader
	sh_mat.set_shader_parameter("shadow_alpha", shadow_alpha)
	shadow.material = sh_mat
	_table_world.add_child(shadow)

	# Node gốc vật thể (mọi nội dung con xoay đồng bộ theo góc vật thể)
	var holder := Control.new()
	holder.name = node_name
	holder.size = scaled_sz
	holder.pivot_offset = scaled_sz * 0.5
	holder.position = scaled_center - scaled_sz * 0.5
	holder.rotation_degrees = angle_deg
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	_table_world.add_child(holder)

	var sprite := _make_tex(tex, Vector2.ZERO, TextureRect.STRETCH_SCALE)
	sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(sprite)
	return holder


func _setup_phase_indicator() -> void:
	# Ẩn thanh ForgePhaseIndicator ở Bàn Chuẩn Bị để lộ trọn ánh lửa lò & Tờ Giấy Đơn Hàng
	var ind := get_node_or_null("ForgePhaseIndicator") as Control
	if ind != null:
		ind.visible = false


# --- Camera Cúi Nhìn 2 Vùng (Focus Pan & Zoom 0.25s, tự động co vừa mọi kích thước cửa sổ) ---

func _on_viewport_resized() -> void:
	if _table_world == null:
		return
	_set_focus_zone(_focus_zone, true)


func _set_focus_zone(zone: FocusZone, instant: bool = false) -> void:
	_focus_zone = zone
	var rect: Rect2 = FOCUS_RECTS[zone]
	var view_sz := size
	if view_sz.x < 10.0 or view_sz.y < 10.0:
		view_sz = get_viewport_rect().size
	if view_sz.x < 10.0 or view_sz.y < 10.0:
		view_sz = Vector2(1920.0, 1080.0)

	# Chừa 48px phía trên cho thanh nút điều hướng cố định, tự tính tỷ lệ vừa khít 100% khung hình
	var top_pad := 44.0
	var avail_w := maxf(320.0, view_sz.x - 16.0)
	var avail_h := maxf(240.0, view_sz.y - top_pad - 12.0)
	var target_scale_f := minf(avail_w / rect.size.x, avail_h / rect.size.y)
	var target_scale := Vector2(target_scale_f, target_scale_f)
	var scaled_sz := rect.size * target_scale_f
	var offset_x := (view_sz.x - scaled_sz.x) * 0.5
	var offset_y := top_pad + (avail_h - scaled_sz.y) * 0.5
	var target_pos := Vector2(offset_x, offset_y) - rect.position * target_scale_f
	var world_w := 640.0 * WB_SCALE * target_scale_f
	var world_h := 360.0 * WB_SCALE * target_scale_f
	if world_w >= view_sz.x:
		target_pos.x = clampf(target_pos.x, view_sz.x - world_w, 0.0)
	if world_h >= view_sz.y:
		target_pos.y = clampf(target_pos.y, view_sz.y - world_h, 0.0)

	if _camera_tween != null:
		_camera_tween.kill()
		_camera_tween = null

	if instant or not is_inside_tree():
		_table_world.scale = target_scale
		_table_world.position = target_pos
	else:
		_camera_tween = create_tween().set_parallel(true)
		_camera_tween.tween_property(_table_world, "scale", target_scale, 0.25) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_camera_tween.tween_property(_table_world, "position", target_pos, 0.25) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	_refresh_focus_overlays()


func _refresh_focus_overlays() -> void:
	var in_book := (_focus_zone == FocusZone.FOCUS_BOOK)
	if _cloth_focus_overlay != null:
		_cloth_focus_overlay.visible = in_book
	if _book_focus_overlay != null:
		_book_focus_overlay.visible = not in_book

	if _hud_zone_book_btn != null:
		HoaTamUI.apply_flat_tab_button(_hud_zone_book_btn, in_book, 17)
	if _hud_zone_cloth_btn != null:
		HoaTamUI.apply_flat_tab_button(_hud_zone_cloth_btn, not in_book, 17)


# --- 1.1b: Cuốn Sổ Cẩm Nang Chuẩn Sách Thật (Vùng 1) ---

func _make_warped_page(
	book_root: Control,
	page_name: String,
	rect_pos: Vector2,
	rect_size: Vector2,
	page_side: float,
	pad_left: int,
	pad_right: int
) -> VBoxContainer:
	# Render 2× supersampling để dấu tiếng Việt sắc nét khi uốn cong & xoay
	var hi_size := rect_size * PAGE_SSAA
	var svc := SubViewportContainer.new()
	svc.name = page_name
	svc.position = rect_pos
	svc.size = hi_size
	svc.scale = Vector2(1.0 / PAGE_SSAA, 1.0 / PAGE_SSAA)
	svc.stretch = true
	svc.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	svc.mouse_filter = Control.MOUSE_FILTER_PASS

	var warp_mat := ShaderMaterial.new()
	warp_mat.shader = _page_warp_shader
	warp_mat.set_shader_parameter("page_side", page_side)
	warp_mat.set_shader_parameter("arch_strength", 0.092)
	warp_mat.set_shader_parameter("spine_shadow", 0.42)
	svc.material = warp_mat
	book_root.add_child(svc)

	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.size = Vector2i(int(hi_size.x), int(hi_size.y))
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	vp.handle_input_locally = true
	svc.add_child(vp)

	var page_root := Control.new()
	page_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_root.theme = theme
	vp.add_child(page_root)

	# Chừa lề rộng đều 4 phía để khối chữ lọt hẳn vào giữa lòng trang giấy cổ (không bám sát mép cong)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", int(pad_left * PAGE_SSAA))
	margin.add_theme_constant_override("margin_right", int(pad_right * PAGE_SSAA))
	margin.add_theme_constant_override("margin_top", 148)
	margin.add_theme_constant_override("margin_bottom", 62)
	page_root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	return vbox


func _build_bookmark_tabs(book_root: Control) -> void:
	# 3 thẻ kẹp trang nhô ở mép trái bìa sách: I (Cận chiến) / II (Hạng nặng & Phép) / III (Bí truyền C2)
	_bookmark_tabs.clear()
	var chapter_defs := [
		[1, "I", 104.0, "Kẹp I: Kiếm Đơn · Song Đao · Giáo Dài"],
		[2, "II", 186.0, "Kẹp II: Búa Chiến · Khiên Đồng · Gậy Phép"],
		[3, "III", 268.0, "Kẹp III: 6 Phôi Bí Truyền (Chương 2+)"],
	]
	for cd in chapter_defs:
		var ch_num: int = int(cd[0])
		var tab_btn := Button.new()
		tab_btn.text = String(cd[1])
		tab_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		tab_btn.position = Vector2(-34.0, float(cd[2]))
		tab_btn.size = Vector2(56.0, 56.0)
		tab_btn.tooltip_text = String(cd[3])
		_apply_font(tab_btn, _font_pixel, 21)
		tab_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		tab_btn.pressed.connect(_jump_to_chapter_page.bind(ch_num))
		book_root.add_child(tab_btn)
		book_root.move_child(tab_btn, 0)
		_bookmark_tabs[ch_num] = tab_btn


func _populate_grimoire_pages(book_root: Control) -> void:
	_build_bookmark_tabs(book_root)

	# --- TRANG TRÁI: BẢN VẼ PHÁC THẢO 32-BIT + TÊN + TRUYỀN THUYẾT TỔ NGHỀ ---
	var left_vb := _make_warped_page(
		book_root, "LeftPageWarp", Vector2(78.0, 15.0), Vector2(348.0, 414.0), -1.0, 42, 36
	)

	var left_head := HBoxContainer.new()
	left_vb.add_child(left_head)
	_page_num_lbl = _make_ink_lbl("", 24, COL_INK_MUTED, _font_lora_italic, HORIZONTAL_ALIGNMENT_LEFT)
	_page_num_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_head.add_child(_page_num_lbl)
	_page_comm_lbl = _make_ink_lbl("", 24, COL_INK_ACCENT, _font_pixel, HORIZONTAL_ALIGNMENT_RIGHT)
	left_head.add_child(_page_comm_lbl)

	left_vb.add_child(_make_book_ornament("— ✦ —", 20))

	# Bản vẽ phác thảo 32-bit nằm gọn giữa bụng trang giấy (0 hộp StyleBoxFlat, 0 weapon_pedestal)
	var sketch_box := Control.new()
	sketch_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sketch_box.custom_minimum_size = Vector2(0.0, 206.0)
	left_vb.add_child(sketch_box)

	var sketch_center := CenterContainer.new()
	sketch_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sketch_box.add_child(sketch_center)

	_weapon_preview = _make_tex(null, Vector2(204.0, 204.0))
	_weapon_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_weapon_preview.modulate = Color(0.90, 0.81, 0.68, 0.96)
	sketch_center.add_child(_weapon_preview)

	# Con dấu niêm phong mực đỏ son cho 6 phôi Chương 2+ (chỉ hiện ở Kẹp III)
	_sealed_stamp_lbl = _make_ink_lbl(
		"NIÊM PHONG\nBí truyền Chương 2 — Mở khi đặt chân tới Núi Than Đỏ",
		25,
		COL_INK_ACCENT,
		_font_lora_italic,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	_sealed_stamp_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sealed_stamp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sealed_stamp_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sealed_stamp_lbl.visible = false
	sketch_box.add_child(_sealed_stamp_lbl)

	_weapon_title = _make_ink_lbl("", 44, COL_INK, _font_pixel, HORIZONTAL_ALIGNMENT_CENTER)
	left_vb.add_child(_weapon_title)
	left_vb.add_child(_make_short_ink_rule(180.0, 2.0, 0.36))

	_weapon_lore_lbl = _make_ink_lbl("", 25, COL_INK_MUTED, _font_lora_italic, HORIZONTAL_ALIGNMENT_CENTER)
	_weapon_lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_vb.add_child(_weapon_lore_lbl)

	# --- TRANG PHẢI: BẢN GHI CẨM NANG CỔ (CĂN GIỮA THANH THOÁT, KHÔNG BẢNG BIỂU FORM UI) ---
	var right_vb := _make_warped_page(
		book_root, "RightPageWarp", Vector2(486.0, 15.0), Vector2(348.0, 414.0), 1.0, 36, 42
	)

	right_vb.add_child(_make_ink_lbl("BẢN GHI TỔ NGHỀ", 32, COL_INK, _font_pixel, HORIZONTAL_ALIGNMENT_CENTER))
	right_vb.add_child(_make_short_ink_rule(220.0, 2.0, 0.42))

	# Khối 1: Định lượng & kiểm kê trong túi (viết gọn như lời dặn đầu mục)
	_recipe_qty_lbl = _make_ink_lbl("", 27, COL_INK, _font_pixel, HORIZONTAL_ALIGNMENT_CENTER)
	_recipe_qty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_vb.add_child(_recipe_qty_lbl)

	_stock_check_lbl = _make_ink_lbl("", 24, COL_INK_GOOD, _font_lora_italic, HORIZONTAL_ALIGNMENT_CENTER)
	_stock_check_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_vb.add_child(_stock_check_lbl)

	right_vb.add_child(_make_book_ornament("· · ✦ · ·", 19))

	# Khối 2: Chỉ số khắc rèn xếp thành 2 hàng cân đối giữa trang (không kẻ cột bảng tính)
	var stat_row_1 := HBoxContainer.new()
	stat_row_1.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_row_1.add_theme_constant_override("separation", 28)
	right_vb.add_child(stat_row_1)
	_add_book_stat_pair(stat_row_1, "atk", "Công")
	stat_row_1.add_child(_make_ink_lbl("·", 28, COL_INK_MUTED, _font_lora))
	_add_book_stat_pair(stat_row_1, "def", "Thủ")

	var stat_row_2 := HBoxContainer.new()
	stat_row_2.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_row_2.add_theme_constant_override("separation", 28)
	right_vb.add_child(stat_row_2)
	_add_book_stat_pair(stat_row_2, "magic", "Phép")
	stat_row_2.add_child(_make_ink_lbl("·", 28, COL_INK_MUTED, _font_lora))
	_add_book_stat_pair(stat_row_2, "speed", "Tốc")

	right_vb.add_child(
		_make_ink_lbl(
			"Độ bền 50  ·  Tôi Hoàn Hảo 60", 23, COL_INK_MUTED, _font_lora_italic, HORIZONTAL_ALIGNMENT_CENTER
		)
	)
	right_vb.add_child(_make_book_ornament("· · ✦ · ·", 19))

	# Khối 3: Bí pháp bẩm sinh [0 STA] & Đặc tính lửa nung (trình bày như ghi chú thư pháp giữa trang)
	_skill_name_lbl = _make_ink_lbl("", 28, COL_INK_ACCENT, _font_pixel, HORIZONTAL_ALIGNMENT_CENTER)
	_skill_name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_vb.add_child(_skill_name_lbl)

	_skill_lbl = _make_ink_lbl("", 24, COL_INK, _font_lora, HORIZONTAL_ALIGNMENT_CENTER)
	_skill_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_vb.add_child(_skill_lbl)

	_heat_profile_lbl = _make_ink_lbl("", 23, COL_INK_ACCENT, _font_lora_italic, HORIZONTAL_ALIGNMENT_CENTER)
	_heat_profile_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_vb.add_child(_heat_profile_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_vb.add_child(spacer)

	# Tách riêng 2 nút lật trang neo chuẩn 2 góc dưới trên mặt giấy sáng (đo từ forge_grimoire_open.png)
	var prev_btn := _make_page_turn_btn("‹ Trang trước", HORIZONTAL_ALIGNMENT_LEFT, -1)
	prev_btn.position = Vector2(98.0, 368.0)
	prev_btn.size = Vector2(180.0, 36.0)
	prev_btn.pivot_offset = prev_btn.size * 0.5
	prev_btn.rotation_degrees = -2.2
	book_root.add_child(prev_btn)

	var next_btn := _make_page_turn_btn("Trang sau ›", HORIZONTAL_ALIGNMENT_RIGHT, 1)
	next_btn.position = Vector2(630.0, 368.0)
	next_btn.size = Vector2(180.0, 36.0)
	next_btn.pivot_offset = next_btn.size * 0.5
	next_btn.rotation_degrees = 2.2
	book_root.add_child(next_btn)

	# Lớp click trượt về Vùng 1 khi đang cúi nhìn Vùng 2 (bấm vào mép sách lấp ló bên trái)
	_book_focus_overlay = _make_invisible_btn("Click để cúi đọc Sổ Cẩm Nang (Q / Tab)")
	_book_focus_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_book_focus_overlay.pressed.connect(_set_focus_zone.bind(FocusZone.FOCUS_BOOK, false))
	book_root.add_child(_book_focus_overlay)


func _add_book_stat_pair(row: HBoxContainer, stat_key: String, label_txt: String) -> void:
	var pair := HBoxContainer.new()
	pair.add_theme_constant_override("separation", 8)
	row.add_child(pair)
	pair.add_child(_make_ink_lbl(label_txt, 25, COL_INK_MUTED, _font_lora))
	var val_lbl := _make_ink_lbl("0", 29, COL_INK, _font_pixel)
	pair.add_child(val_lbl)
	_stats_labels[stat_key] = val_lbl


func _make_short_ink_rule(rule_w: float, thickness: float = 2.0, alpha: float = 0.36) -> CenterContainer:
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(rule_w, thickness)
	line.color = Color(0.38, 0.21, 0.10, alpha)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(line)
	return center


func _make_book_ornament(sym: String, fsize: int = 20) -> Label:
	return _make_ink_lbl(
		sym, fsize, Color(0.42, 0.24, 0.12, 0.62), _font_lora, HORIZONTAL_ALIGNMENT_CENTER
	)


# --- 1.1c: Tờ Giấy Đơn Hàng (+3.8°) phía trên đầu Sổ ---

func _populate_commission_note(note_root: Control) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note_root.add_child(margin)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 4)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vb)

	_note_title_lbl = _make_ink_lbl(
		"Chưa có đơn đặt rèn", 20, COL_INK_MUTED, _font_lora_italic, HORIZONTAL_ALIGNMENT_CENTER
	)
	_note_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_note_title_lbl)

	_note_detail_lbl = _make_ink_lbl(
		"", 16, COL_INK, _font_lora, HORIZONTAL_ALIGNMENT_CENTER
	)
	_note_detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_note_detail_lbl)

	_note_click_btn = _make_invisible_btn("Bấm để mở đúng trang phôi khách đặt")
	_note_click_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_note_click_btn.pressed.connect(_on_commission_note_pressed)
	note_root.add_child(_note_click_btn)


# --- 1.1d: Túi Da (-18.0°) & Quặng Bày Hữu Cơ Trên Vải Lanh (Vùng 2) ---

func _populate_cloth_mat(cloth_root: Control) -> void:
	_cloth_items_layer = Control.new()
	_cloth_items_layer.name = "OrganicMaterialsLayer"
	_cloth_items_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cloth_items_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	cloth_root.add_child(_cloth_items_layer)

	_cloth_empty_lbl = _make_outlined_lbl(
		"Túi quặng đang trống — hãy ra Đồng Mây thu thập!",
		19, Color(0.95, 0.88, 0.76, 0.92), _font_lora_italic, HORIZONTAL_ALIGNMENT_CENTER
	)
	_cloth_empty_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cloth_empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cloth_empty_lbl.visible = false
	cloth_root.add_child(_cloth_empty_lbl)

	# Dòng chú thích tinh tế ngay mép đáy tấm vải (0 hộp đen)
	_cloth_info_lbl = _make_outlined_lbl(
		"Chọn 1 loại nguyên liệu trên vải để đưa vào lò",
		17, COL_TEXT, _font_lora, HORIZONTAL_ALIGNMENT_CENTER
	)
	_cloth_info_lbl.position = Vector2(24.0, 356.0)
	_cloth_info_lbl.size = Vector2(564.0, 34.0)
	_cloth_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cloth_root.add_child(_cloth_info_lbl)

	# Khi đang ở Vùng 1, click lên mép Tấm Vải lấp ló bên phải để trượt mượt sang Vùng 2
	_cloth_focus_overlay = _make_invisible_btn("Click để sang Tấm Vải Lanh bốc quặng (E / Tab)")
	_cloth_focus_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cloth_focus_overlay.pressed.connect(_set_focus_zone.bind(FocusZone.FOCUS_CLOTH, false))
	cloth_root.add_child(_cloth_focus_overlay)


func _populate_leather_pouch(pouch_root: Control) -> void:
	_pouch_btn = _make_invisible_btn("Túi da đựng quặng — Bấm để kiểm kê")
	_pouch_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pouch_btn.pressed.connect(_on_pouch_pressed)
	pouch_root.add_child(_pouch_btn)


func _on_pouch_pressed() -> void:
	if _focus_zone != FocusZone.FOCUS_CLOTH:
		_set_focus_zone(FocusZone.FOCUS_CLOTH)
		return
	AudioManager.play_sfx_key("chest_open", 0.72, 1.08)
	var pouch_root: Control = _workbench_props.get("pouch", null)
	if pouch_root != null:
		var tw := create_tween()
		tw.tween_property(pouch_root, "scale", Vector2(1.06, 0.94), 0.08)
		tw.tween_property(pouch_root, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)
	var total_units := 0
	var distinct_kinds := 0
	for mat_id: String in _material_order:
		var cnt := _inventory_count_for(mat_id)
		if cnt > 0:
			total_units += cnt
			distinct_kinds += 1
	if _cloth_info_lbl != null:
		_cloth_info_lbl.text = "Trong túi da có %d loại nguyên liệu (%d phần)." % [distinct_kinds, total_units]


# --- 1.1e: Nút Dấu Sáp Đỏ (-0.8°) Khởi Lò ---

func _populate_wax_seal_btn(wax_root: Control) -> void:
	_wax_hint_lbl = _make_outlined_lbl(
		"", 16, COL_GOLD, _font_lora, HORIZONTAL_ALIGNMENT_CENTER
	)
	_wax_hint_lbl.position = Vector2(14.0, -28.0)
	_wax_hint_lbl.size = Vector2(476.0, 26.0)
	wax_root.add_child(_wax_hint_lbl)

	_wax_title_lbl = _make_outlined_lbl(
		"KHỞI LÒ RÈN", 26, Color(1.0, 0.93, 0.74, 1.0), _font_pixel, HORIZONTAL_ALIGNMENT_CENTER
	)
	_wax_title_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wax_title_lbl.offset_left = 86.0
	_wax_title_lbl.offset_right = -24.0
	_wax_title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wax_root.add_child(_wax_title_lbl)

	_wax_btn = _make_invisible_btn("Đóng dấu sáp đỏ để đưa phôi vào lò nung")
	_wax_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wax_btn.pressed.connect(_on_wax_seal_clicked)
	_wax_btn.mouse_entered.connect(_on_wax_hover_changed.bind(true))
	_wax_btn.mouse_exited.connect(_on_wax_hover_changed.bind(false))
	_wax_btn.button_down.connect(_on_wax_press_feedback.bind(true))
	_wax_btn.button_up.connect(_on_wax_press_feedback.bind(false))
	wax_root.add_child(_wax_btn)


func _on_wax_hover_changed(hovered: bool) -> void:
	_wax_hovered = hovered
	if _wax_btn == null or _wax_btn.disabled:
		return
	var wax_root: Control = _workbench_props.get("wax", null)
	if wax_root == null:
		return
	if _wax_pulse_tween != null and _wax_pulse_tween.is_valid():
		_wax_pulse_tween.kill()
	var tw := create_tween().set_parallel(true)
	if hovered:
		tw.tween_property(wax_root, "scale", Vector2(1.045, 1.045), 0.12) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(wax_root, "modulate", Color(1.22, 1.12, 0.94, 1.0), 0.12)
		if _wax_title_lbl != null:
			_wax_title_lbl.add_theme_color_override("font_outline_color", Color(0.88, 0.44, 0.08, 0.95))
	else:
		tw.tween_property(wax_root, "scale", Vector2.ONE, 0.14) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(wax_root, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.14)
		if _wax_title_lbl != null:
			_wax_title_lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.03, 0.02, 0.96))
		_start_wax_ready_pulse()


func _on_wax_press_feedback(down: bool) -> void:
	if _wax_btn == null or _wax_btn.disabled:
		return
	var wax_root: Control = _workbench_props.get("wax", null)
	if wax_root == null:
		return
	var target := Vector2(0.95, 0.95) if down else (Vector2(1.045, 1.045) if _wax_hovered else Vector2.ONE)
	create_tween().tween_property(wax_root, "scale", target, 0.07) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _start_wax_ready_pulse() -> void:
	if _wax_pulse_tween != null and _wax_pulse_tween.is_valid():
		_wax_pulse_tween.kill()
	if _wax_btn == null or _wax_btn.disabled or _wax_hovered:
		return
	var wax_root: Control = _workbench_props.get("wax", null)
	if wax_root == null:
		return
	_wax_pulse_tween = create_tween().set_loops()
	_wax_pulse_tween.tween_property(wax_root, "modulate", Color(1.14, 1.07, 0.95, 1.0), 0.95) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_wax_pulse_tween.tween_property(wax_root, "modulate", Color(0.98, 0.96, 0.94, 1.0), 0.95) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_wax_seal_clicked() -> void:
	if _focus_zone != FocusZone.FOCUS_CLOTH:
		_set_focus_zone(FocusZone.FOCUS_CLOTH)
		return
	if not _wax_btn.disabled:
		_on_start_forge_pressed()


# --- Logic Chọn Phôi, Lật Trang, Đơn Hàng & Bày Quặng Hữu Cơ ---

func _is_blank_sealed(weapon_id: String) -> bool:
	return not (weapon_id in CHAPTER1_BLANKS) and not GameManager.is_region_unlocked("NuiThanDo")


func _turn_book_page(delta: int) -> void:
	var idx := WEAPON_ORDER.find(_current_weapon)
	if idx < 0:
		idx = 0
	var next_idx := wrapi(idx + delta, 0, WEAPON_ORDER.size())
	AudioManager.play_sfx_key("book_flip", 0.72, randf_range(0.95, 1.06))
	_select_blank(WEAPON_ORDER[next_idx])


func _jump_to_chapter_page(chapter_num: int) -> void:
	if _focus_zone != FocusZone.FOCUS_BOOK:
		_set_focus_zone(FocusZone.FOCUS_BOOK)
	for wid: String in WEAPON_ORDER:
		if int(WEAPON_DATA[wid]["chapter"]) == chapter_num:
			AudioManager.play_sfx_key("book_flip", 0.75, 1.02)
			_select_blank(wid)
			return


func _select_blank(weapon_id: String) -> void:
	if not WEAPON_DATA.has(weapon_id):
		return
	_current_weapon = weapon_id
	if _selected_material_id != "" and not _is_material_eligible(_selected_material_id, weapon_id):
		_selected_material_id = ""
	_refresh_all_live()


func _refresh_all_live() -> void:
	var blank: Dictionary = WEAPON_DATA[_current_weapon]
	var comm_map := _collect_active_commissions()
	var page_idx := WEAPON_ORDER.find(_current_weapon)
	var t_num: int = int(blank["required_tier"])
	var req_qty: int = int(blank["required_quantity"])
	var sealed := _is_blank_sealed(_current_weapon)

	if _page_num_lbl != null:
		_page_num_lbl.text = "Trang %s / XII" % _page_roman(page_idx + 1)
	if _page_comm_lbl != null:
		_page_comm_lbl.text = "★ Đơn khách" if comm_map.has(_current_weapon) else ""
	if _weapon_title != null:
		_weapon_title.text = String(blank["name"])
	if _weapon_lore_lbl != null:
		_weapon_lore_lbl.text = String(blank.get("lore", ""))
	if _weapon_preview != null:
		_weapon_preview.texture = _try_load_tex(_prototype_path(blank))
		_weapon_preview.modulate = (
			Color(0.65, 0.56, 0.46, 0.28) if sealed else Color(0.90, 0.81, 0.68, 0.96)
		)
	if _sealed_stamp_lbl != null:
		_sealed_stamp_lbl.visible = sealed

	if _recipe_qty_lbl != null:
		_recipe_qty_lbl.text = "Cần: %d phần nguyên liệu · Bậc %s+" % [req_qty, _tier_roman(t_num)]

	var qualifying_units := _count_qualifying_materials(t_num)
	if _stock_check_lbl != null:
		if sealed:
			_stock_check_lbl.text = "Bí truyền niêm phong — mở ở Chương 2 (Núi Than Đỏ)"
			_stock_check_lbl.add_theme_color_override("font_color", COL_INK_ACCENT)
		else:
			_stock_check_lbl.text = "Trong túi có: %d phần đủ bậc" % qualifying_units
			_stock_check_lbl.add_theme_color_override(
				"font_color", COL_INK_GOOD if qualifying_units >= req_qty else COL_INK_ACCENT
			)

	var heat_prof: Dictionary = _FORGE1_SCRIPT.get_heat_profile(_current_weapon)
	if _heat_profile_lbl != null:
		_heat_profile_lbl.text = "Nhiệt nung: %s" % String(heat_prof.get("book_note", ""))

	_refresh_bookmark_tabs()
	_refresh_live_stats()
	_refresh_commission_note()
	_rebuild_organic_cloth_materials()
	_refresh_wax_seal_button()


func _refresh_bookmark_tabs() -> void:
	var cur_ch: int = int(WEAPON_DATA[_current_weapon]["chapter"])
	for ch_num in _bookmark_tabs.keys():
		var btn: Button = _bookmark_tabs[ch_num]
		var is_act: bool = int(ch_num) == cur_ch
		btn.position.x = -42.0 if is_act else -34.0
		var txt_col := Color(0.98, 0.91, 0.76, 1.0) if is_act else COL_INK
		btn.add_theme_color_override("font_color", txt_col)
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.80, 1.0))
		var sb_norm := HoaTamUI._make_9slice(
			HoaTamUI.TEX_BTN_WAX_N if is_act else HoaTamUI.TEX_PANEL_PARCHMENT,
			12.0, 12.0, 8.0, 2.0
		)
		sb_norm.content_margin_left = 10.0
		sb_norm.content_margin_right = 14.0 if is_act else 18.0
		var sb_hov := HoaTamUI._make_9slice(HoaTamUI.TEX_BTN_WAX_H, 12.0, 12.0, 8.0, 2.0)
		sb_hov.content_margin_left = 10.0
		sb_hov.content_margin_right = 14.0 if is_act else 18.0
		btn.add_theme_stylebox_override("normal", sb_norm)
		btn.add_theme_stylebox_override("hover", sb_hov)
		btn.add_theme_stylebox_override("pressed", sb_norm)


func _refresh_live_stats() -> void:
	var blank: Dictionary = WEAPON_DATA[_current_weapon]
	var totals := _compute_selected_material_totals()
	for k in ["atk", "def", "magic", "speed"]:
		var bonus: int = int(totals[k])
		var val: int = int(blank[k]) + bonus
		var lbl: Label = _stats_labels[k]
		if bonus > 0:
			lbl.text = "%d(+%d)" % [val, bonus]
			lbl.add_theme_color_override("font_color", COL_INK_GOOD)
		elif bonus < 0:
			lbl.text = "%d(%d)" % [val, bonus]
			lbl.add_theme_color_override("font_color", COL_INK_ACCENT)
		else:
			lbl.text = str(val)
			lbl.add_theme_color_override("font_color", COL_INK)

	if _skill_name_lbl != null:
		_skill_name_lbl.text = "✦ %s [0 STA]" % _skill_name(blank)
	if _skill_lbl != null:
		_skill_lbl.text = String(blank["skill_desc"])


func _collect_active_commissions() -> Dictionary:
	var result: Dictionary = {}
	_active_commission_info = {}
	var comm_sys := get_node_or_null("/root/CommissionSystem")
	if comm_sys == null or not comm_sys.has_method("get_active"):
		return result
	for comm in comm_sys.get_active():
		if comm == null:
			continue
		var req_blank := String(comm.get("req_blank"))
		var req_elem := String(comm.get("req_element"))
		var req_rarity := maxi(1, int(comm.get("req_min_rarity")))
		var reward_gold := int(comm.get("reward_gold"))
		var giver_id := String(comm.get("giver_npc_id"))
		var elem_name := "Tự do"
		if req_elem != "" and _PHASE3_SCRIPT.ELEMENTS.has(req_elem):
			elem_name = String(_PHASE3_SCRIPT.ELEMENTS[req_elem]["name"])
		if _active_commission_info.is_empty():
			_active_commission_info = {
				"req_blank": req_blank,
				"req_element": req_elem,
				"req_min_rarity": req_rarity,
				"elem_name": elem_name,
				"reward_gold": reward_gold,
				"giver_id": giver_id,
				"giver_name": NPC_DISPLAY_NAMES.get(giver_id, giver_id),
			}
		if req_blank != "" and WEAPON_DATA.has(req_blank):
			result[req_blank] = elem_name
	return result


func _refresh_commission_note() -> void:
	if _note_title_lbl == null or _note_detail_lbl == null:
		return
	if _active_commission_info.is_empty():
		_note_title_lbl.text = "Chưa có đơn đặt rèn"
		_note_title_lbl.add_theme_color_override("font_color", COL_INK_MUTED)
		_note_detail_lbl.text = ""
		if _note_click_btn != null:
			_note_click_btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
		return

	var req_b := String(_active_commission_info.get("req_blank", ""))
	var b_name := String(WEAPON_DATA[req_b]["name"]) if WEAPON_DATA.has(req_b) else "Phôi tự chọn"
	var giver_name := String(_active_commission_info.get("giver_name", "Khách"))
	var elem_name := String(_active_commission_info.get("elem_name", "Tự do"))
	var req_r: int = int(_active_commission_info.get("req_min_rarity", 1))
	var reward_g: int = int(_active_commission_info.get("reward_gold", 0))

	_note_title_lbl.text = "★ %s đặt: %s" % [giver_name, b_name]
	_note_title_lbl.add_theme_color_override("font_color", COL_INK_ACCENT)
	_note_detail_lbl.text = "Hệ %s · Bậc %s+ · Thưởng %dG" % [
		elem_name, _tier_roman(req_r), reward_g
	]
	if _note_click_btn != null:
		_note_click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _on_commission_note_pressed() -> void:
	if _active_commission_info.is_empty():
		if _focus_zone != FocusZone.FOCUS_BOOK:
			_set_focus_zone(FocusZone.FOCUS_BOOK)
		return
	var req_blank := String(_active_commission_info.get("req_blank", ""))
	if req_blank != "" and WEAPON_DATA.has(req_blank):
		AudioManager.play_sfx_key("book_flip", 0.78, 1.04)
		_select_blank(req_blank)
	if _focus_zone != FocusZone.FOCUS_BOOK:
		_set_focus_zone(FocusZone.FOCUS_BOOK)


func _rebuild_organic_cloth_materials() -> void:
	if _cloth_items_layer == null:
		return
	for child in _cloth_items_layer.get_children():
		child.queue_free()
	_cloth_mat_nodes.clear()

	# Lọc danh sách nguyên liệu thực tế có số lượng > 0 trong InventorySystem
	var owned_mats: Array[String] = []
	for mat_id: String in _material_order:
		if _inventory_count_for(mat_id) > 0:
			owned_mats.append(mat_id)

	var req_tier: int = int(WEAPON_DATA[_current_weapon]["required_tier"])
	var req_qty: int = int(WEAPON_DATA[_current_weapon]["required_quantity"])
	var sealed := _is_blank_sealed(_current_weapon)

	if owned_mats.is_empty():
		if _cloth_empty_lbl != null:
			_cloth_empty_lbl.visible = true
		_update_cloth_info_default()
		return

	if _cloth_empty_lbl != null:
		_cloth_empty_lbl.visible = false

	# Xếp nguyên liệu đủ chuẩn lên các vị trí gần trung tâm tấm vải trước
	owned_mats.sort_custom(func(a: String, b: String) -> bool:
		var ea := _is_material_eligible(a, _current_weapon)
		var eb := _is_material_eligible(b, _current_weapon)
		if ea != eb:
			return ea
		return int(_material_catalog[a]["tier"]) < int(_material_catalog[b]["tier"])
	)

	var max_display := mini(owned_mats.size(), CLOTH_PILE_SLOTS.size())
	for idx in range(max_display):
		var mat_id: String = owned_mats[idx]
		var mat: Dictionary = _material_catalog[mat_id]
		var owned: int = _inventory_count_for(mat_id)
		var eligible: bool = (not sealed) and _is_material_eligible(mat_id, _current_weapon)
		var is_selected: bool = (mat_id == _selected_material_id)
		var slot_cfg: Dictionary = CLOTH_PILE_SLOTS[idx]
		var center_pos: Vector2 = slot_cfg["pos"]
		var angle_deg: float = float(slot_cfg["rot"])
		var item_scale: float = float(slot_cfg.get("scale", 1.0))
		var tag_rot: float = float(slot_cfg.get("tag_rot", 4.0))

		var pile := Control.new()
		pile.size = Vector2(118.0, 114.0)
		pile.pivot_offset = pile.size * 0.5
		pile.position = center_pos - pile.size * 0.5
		pile.scale = Vector2(item_scale, item_scale)
		pile.mouse_filter = Control.MOUSE_FILTER_PASS
		_cloth_items_layer.add_child(pile)

		var tex := _try_load_tex(String(mat["icon"]))

		# Lớp dưới trên thớ vải: Bóng đè tiếp xúc dẹt (giãn ra khi nhấc lên) + Vòng nét phấn vẽ tay khi chọn
		var underlay := _ClothItemUnderlay.new()
		underlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		underlay.is_selected = is_selected
		underlay.seed_phase = float(idx) * 1.37
		underlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pile.add_child(underlay)

		# Sprite vật phẩm 32-bit hòa ánh sáng ấm của lò rèn (nhấc cao 8px + phóng nhẹ khi chọn)
		var icon := _make_tex(tex, Vector2(82.0, 82.0))
		icon.size = Vector2(82.0, 82.0)
		icon.pivot_offset = icon.size * 0.5
		icon.rotation_degrees = angle_deg
		var lift_y := -8.0 if is_selected else 0.0
		icon.position = Vector2(18.0, 10.0 + lift_y)
		if is_selected:
			icon.scale = Vector2(1.07, 1.07)
			icon.modulate = Color(1.04, 0.96, 0.85, 1.0)
		elif eligible:
			# Nhuộm nhẹ ánh lửa ấm của mặt bàn rèn để vật phẩm ăn cùng không gian ánh sáng với gỗ & vải
			icon.modulate = Color(0.94, 0.86, 0.76, 1.0)
		else:
			icon.modulate = Color(0.62, 0.56, 0.50, 0.56)
		pile.add_child(icon)

		# Mảnh thẻ giấy da nhỏ đóng số mực nâu ghim sát chân vật phẩm (xóa hoàn toàn chữ nổi kiểu UI)
		var qty_tag := _make_parchment_qty_tag(owned, is_selected, eligible, tag_rot)
		qty_tag.position = Vector2(68.0, 74.0)
		pile.add_child(qty_tag)

		# Nút trong suốt bắt click & hover
		var hit_btn := _make_invisible_btn(_build_material_tooltip(mat, owned, req_tier, req_qty, sealed))
		hit_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hit_btn.mouse_default_cursor_shape = (
			Control.CURSOR_POINTING_HAND if eligible else Control.CURSOR_ARROW
		)
		hit_btn.mouse_entered.connect(_on_cloth_material_hovered.bind(mat_id))
		hit_btn.mouse_exited.connect(_update_cloth_info_default)
		hit_btn.pressed.connect(_on_cloth_material_clicked.bind(mat_id))
		pile.add_child(hit_btn)

		_cloth_mat_nodes[mat_id] = pile

	_update_cloth_info_default()


func _make_parchment_qty_tag(
	owned: int,
	is_selected: bool,
	eligible: bool,
	_rot_deg: float
) -> Control:
	var holder := Control.new()
	holder.size = Vector2(54.0, 30.0)
	holder.pivot_offset = holder.size * 0.5
	# Giữ thẳng 0° để chữ số pixel sắc nét tuyệt đối, không bị vỡ răng cưa
	holder.rotation_degrees = 0.0
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not eligible and not is_selected:
		holder.modulate = Color(0.76, 0.70, 0.64, 0.82)

	# Bóng tiếp xúc gọn dưới thẻ
	var sh := ColorRect.new()
	sh.position = Vector2(2.0, 3.0)
	sh.size = holder.size
	sh.color = Color(0.0706, 0.0392, 0.0471, 0.44)
	sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(sh)

	# Mảnh thẻ giấy da kem sáng viền mực nâu đậm (độ tương phản cao, không bị viền gỗ ăn hết chữ)
	var card := Panel.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tag_sb := StyleBoxFlat.new()
	tag_sb.bg_color = Color(0.98, 0.92, 0.78, 1.0) if is_selected else Color(0.93, 0.85, 0.69, 0.98)
	tag_sb.border_color = Color(0.68, 0.18, 0.10, 1.0) if is_selected else Color(0.24, 0.13, 0.08, 1.0)
	tag_sb.set_border_width_all(2)
	tag_sb.set_corner_radius_all(4)
	card.add_theme_stylebox_override("panel", tag_sb)
	holder.add_child(card)

	# Lỗ xỏ dây buộc nhỏ góc trái mảnh thẻ
	var eyelet := ColorRect.new()
	eyelet.position = Vector2(5.0, 13.0)
	eyelet.size = Vector2(4.0, 4.0)
	eyelet.color = Color(0.24, 0.14, 0.08, 0.88)
	eyelet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(eyelet)

	# Số lượng cỡ 20px mực đậm sắc nét trên nền giấy kem sáng
	var num_lbl := _make_ink_lbl(
		"×%d" % owned,
		20,
		Color(0.68, 0.12, 0.08, 1.0) if is_selected else Color(0.16, 0.08, 0.04, 1.0),
		_font_pixel,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	num_lbl.position = Vector2(10.0, 0.0)
	num_lbl.size = Vector2(42.0, 30.0)
	num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	holder.add_child(num_lbl)
	return holder


func _build_material_tooltip(
	mat: Dictionary,
	owned: int,
	req_tier: int,
	req_qty: int,
	sealed: bool
) -> String:
	var t_num: int = int(mat["tier"])
	var base := "%s (Bậc %s · có %d) — %s" % [
		String(mat["name"]), _tier_roman(t_num), owned, _format_mat_bonuses(mat)
	]
	if sealed:
		return base + "\nPhôi đang mở thuộc Chương 2 (niêm phong)."
	if t_num < req_tier:
		return base + "\nChưa đủ bậc (phôi cần Bậc %s+)." % _tier_roman(req_tier)
	if owned < req_qty:
		return base + "\nChưa đủ số lượng (phôi cần %d phần)." % req_qty
	return base + "\nBấm để chọn %d phần đưa vào lò." % req_qty


func _on_cloth_material_hovered(mat_id: String) -> void:
	if _cloth_info_lbl == null or not _material_catalog.has(mat_id):
		return
	var mat: Dictionary = _material_catalog[mat_id]
	var owned := _inventory_count_for(mat_id)
	var req_tier: int = int(WEAPON_DATA[_current_weapon]["required_tier"])
	var req_qty: int = int(WEAPON_DATA[_current_weapon]["required_quantity"])
	var t_num: int = int(mat["tier"])

	if _is_blank_sealed(_current_weapon):
		_cloth_info_lbl.text = "%s (Bậc %s · ×%d) — Phôi đang mở bị niêm phong ở Chương 1" % [
			String(mat["name"]), _tier_roman(t_num), owned
		]
	elif t_num < req_tier:
		_cloth_info_lbl.text = "%s (Bậc %s · ×%d) — Chưa đủ bậc (cần Bậc %s+)" % [
			String(mat["name"]), _tier_roman(t_num), owned, _tier_roman(req_tier)
		]
	elif owned < req_qty:
		_cloth_info_lbl.text = "%s (Bậc %s · ×%d) — Thiếu nguyên liệu (cần %d phần)" % [
			String(mat["name"]), _tier_roman(t_num), owned, req_qty
		]
	else:
		var elems := _format_allowed_elements(mat)
		_cloth_info_lbl.text = "%s (Bậc %s) · %s · Hợp hệ: %s" % [
			String(mat["name"]), _tier_roman(t_num), _format_mat_bonuses(mat), elems
		]


func _update_cloth_info_default() -> void:
	if _cloth_info_lbl == null:
		return
	var req_qty: int = int(WEAPON_DATA[_current_weapon]["required_quantity"])
	if _selected_material_id != "" and _material_catalog.has(_selected_material_id):
		var mat: Dictionary = _material_catalog[_selected_material_id]
		_cloth_info_lbl.text = "✓ Đã chọn: %s ×%d (%s) — Hợp hệ: %s" % [
			String(mat["name"]), req_qty, _format_mat_bonuses(mat), _format_allowed_elements(mat)
		]
	elif _is_blank_sealed(_current_weapon):
		_cloth_info_lbl.text = "Hãy lật về Kẹp I hoặc II để chọn phôi Chương 1"
	else:
		_cloth_info_lbl.text = "Bấm chọn 1 cụm nguyên liệu đủ chuẩn (%d phần) trên tấm vải" % req_qty


func _on_cloth_material_clicked(mat_id: String) -> void:
	if _focus_zone != FocusZone.FOCUS_CLOTH:
		_set_focus_zone(FocusZone.FOCUS_CLOTH)
		return
	if _is_blank_sealed(_current_weapon):
		return
	if not _is_material_eligible(mat_id, _current_weapon):
		AudioManager.play_sfx_key("hammer_miss", 0.55, 1.15)
		_on_cloth_material_hovered(mat_id)
		return
	_selected_material_id = "" if _selected_material_id == mat_id else mat_id
	AudioManager.play_sfx_key("zone_prompt", 0.65, 1.10 if _selected_material_id != "" else 0.90)
	_refresh_live_stats()
	_rebuild_organic_cloth_materials()
	_refresh_wax_seal_button()


func _refresh_wax_seal_button() -> void:
	if _wax_btn == null:
		return
	var wax_root: Control = _workbench_props.get("wax", null)
	var sealed := _is_blank_sealed(_current_weapon)
	var can_forge := false
	var hint_txt := ""
	var hint_col := COL_WARN

	if sealed:
		hint_txt = "Phôi bí truyền Chương 2 — chưa thể rèn"
	elif _selected_material_id == "":
		hint_txt = "Chọn nguyên liệu đủ chuẩn trên tấm vải"
		hint_col = COL_TEXT
	else:
		var err := ForgeValidator.validate(
			_build_selected_blank_dict(),
			_build_selected_material_dict(),
			InventorySystem.materials
		)
		if err != "":
			hint_txt = err
		else:
			can_forge = true
			hint_txt = "Sẵn sàng — Đóng ấn sáp khởi lò!"
			hint_col = COL_GOLD

	_wax_btn.disabled = not can_forge
	_wax_btn.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if can_forge else Control.CURSOR_ARROW
	)
	if wax_root != null:
		if _wax_pulse_tween != null and _wax_pulse_tween.is_valid():
			_wax_pulse_tween.kill()
		if can_forge:
			wax_root.modulate = Color(1.22, 1.12, 0.94, 1.0) if _wax_hovered else Color(1.0, 1.0, 1.0, 1.0)
			if not _wax_hovered:
				_start_wax_ready_pulse()
		else:
			wax_root.scale = Vector2.ONE
			wax_root.modulate = Color(0.70, 0.64, 0.60, 0.86)
	if _wax_hint_lbl != null:
		_wax_hint_lbl.text = hint_txt
		_wax_hint_lbl.add_theme_color_override("font_color", hint_col)


func _on_start_forge_pressed() -> void:
	if _is_starting_forge:
		return
	if _is_blank_sealed(_current_weapon) or _selected_material_id == "":
		return
	var blank_dict := _build_selected_blank_dict()
	var mat_dict := _build_selected_material_dict()
	if ForgeValidator.validate(blank_dict, mat_dict, InventorySystem.materials) != "":
		_refresh_wax_seal_button()
		return

	_is_starting_forge = true
	if _wax_btn != null:
		_wax_btn.disabled = true

	# Phát âm thanh đóng ấn sáp & hiệu ứng lún ấn
	AudioManager.play_sfx_key("hammer_good", 0.82, 0.72)
	var wax_root: Control = _workbench_props.get("wax", null)
	if wax_root != null:
		var tw := create_tween()
		tw.tween_property(wax_root, "scale", Vector2(0.94, 0.94), 0.06)
		tw.tween_property(wax_root, "scale", Vector2.ONE, 0.08)

	# Trừ đúng định lượng nguyên liệu trong kho ngay khi khởi lò (gắn cờ chống trừ 2 lần ở ForgeSession)
	var req_qty: int = int(blank_dict["required_quantity"])
	_consume_material_from_inventory(_selected_material_id, req_qty)
	mat_dict["materials_consumed"] = true
	mat_dict["consumed_mat_id"] = _selected_material_id
	mat_dict["consumed_qty"] = req_qty

	GameManager.selected_blank = blank_dict
	GameManager.selected_material = mat_dict
	GameManager.selected_element = ""  # Để người chơi chọn Ấn Linh Lực tại Bể Tôi ở Phase 3
	weapon_confirmed.emit(_current_weapon)
	forge_ready.emit(_current_weapon, mat_dict["material_ids"].duplicate())
	get_tree().change_scene_to_file(PATH_FORGE_SESSION)


func _on_back_pressed() -> void:
	GameManager.selected_blank = {}
	GameManager.selected_material = {}
	GameManager.selected_element = ""
	GameManager.forge_return_to_material_step = false
	SceneManager.go_to(PATH_WORKSHOP)


func _restore_previous_selection() -> void:
	var prev_id := String(GameManager.selected_material.get("item_id", ""))
	if prev_id != "" and _is_material_eligible(prev_id, _current_weapon):
		_selected_material_id = prev_id
	_refresh_all_live()


# --- Tính Toán Kho, Định Lượng & Dữ Liệu Xuất Sang ForgeSession ---

func _is_material_eligible(mat_id: String, weapon_id: String) -> bool:
	if not _material_catalog.has(mat_id) or not WEAPON_DATA.has(weapon_id):
		return false
	if _is_blank_sealed(weapon_id):
		return false
	var mat: Dictionary = _material_catalog[mat_id]
	var blank: Dictionary = WEAPON_DATA[weapon_id]
	if int(mat["tier"]) < int(blank["required_tier"]):
		return false
	return _inventory_count_for(mat_id) >= int(blank["required_quantity"])


func _count_qualifying_materials(req_tier: int) -> int:
	var total := 0
	for mat_id: String in _material_order:
		if int(_material_catalog[mat_id]["tier"]) >= req_tier:
			total += _inventory_count_for(mat_id)
	return total


func _build_selected_blank_dict() -> Dictionary:
	var d: Dictionary = WEAPON_DATA[_current_weapon]
	return {
		"id": _current_weapon,
		"name": String(d["name"]),
		"atk": int(d["atk"]),
		"def": int(d["def"]),
		"magic": int(d["magic"]),
		"speed": int(d["speed"]),
		"skill": String(d["skill"]),
		"skill_name": _skill_name(d),
		"skill_desc": String(d["skill_desc"]),
		"customers": String(d["customers"]),
		"required_tier": int(d["required_tier"]),
		"required_quantity": int(d["required_quantity"]),
		"sprite_path": _prototype_path(d),
	}


func _build_selected_material_dict() -> Dictionary:
	var req_qty: int = int(WEAPON_DATA[_current_weapon]["required_quantity"])
	var slotted: Array[String] = []
	var aliases: Dictionary = {}
	var totals := _compute_selected_material_totals()
	var mat_name := ""
	var mat_tier := 1
	var allowed_elems: Array = ["hoa", "phong", "tho"]

	if _selected_material_id != "" and _material_catalog.has(_selected_material_id):
		var mat: Dictionary = _material_catalog[_selected_material_id]
		mat_name = String(mat["name"])
		mat_tier = int(mat["tier"])
		allowed_elems = Array(mat["allowed_elements"]).duplicate()
		aliases[_selected_material_id] = _accepted_ids_for(_selected_material_id)
		for _i in range(req_qty):
			slotted.append(_selected_material_id)

	return {
		"id": "mat_" + _selected_material_id,
		"item_id": _selected_material_id,
		"name": mat_name,
		"rarity": maxi(1, mat_tier),
		"atk_bonus": int(totals["atk"]),
		"def_bonus": int(totals["def"]),
		"magic_bonus": int(totals["magic"]),
		"speed_bonus": int(totals["speed"]),
		"price_mult": float(totals["price_mult"]),
		"phase1_min": String(totals["phase1_min"]),
		"material_ids": slotted,
		"material_inventory_aliases": aliases,
		"allowed_elements": allowed_elems,
	}


func _compute_selected_material_totals() -> Dictionary:
	var t := {"atk": 0, "def": 0, "magic": 0, "speed": 0, "price_mult": 1.0, "phase1_min": ""}
	if _selected_material_id == "" or not _material_catalog.has(_selected_material_id):
		return t
	var m: Dictionary = _material_catalog[_selected_material_id]
	var req_qty: int = int(WEAPON_DATA[_current_weapon]["required_quantity"])
	t["atk"] = int(m["atk"]) * req_qty
	t["def"] = int(m["def"]) * req_qty
	t["magic"] = int(m["magic"]) * req_qty
	t["speed"] = int(m["speed"]) * req_qty
	t["price_mult"] = float(m["price_mult"])
	var p1 := String(m["phase1_min"])
	if p1 == "do_ruc" or p1 == "vang_kim":
		t["phase1_min"] = "do_ruc"
	elif p1 == "cam":
		t["phase1_min"] = "cam"
	return t


func _consume_material_from_inventory(mat_id: String, amount: int) -> void:
	var accepted := _accepted_ids_for(mat_id)
	var remaining := maxi(0, amount)
	var i := InventorySystem.materials.size() - 1
	while i >= 0 and remaining > 0:
		var entry: Dictionary = InventorySystem.materials[i]
		if not (String(entry.get("item_id", "")) in accepted):
			i -= 1
			continue
		var qty_key := "quantity" if entry.has("quantity") else ("amount" if entry.has("amount") else "")
		if qty_key == "":
			InventorySystem.materials.remove_at(i)
			remaining -= 1
			i -= 1
			continue
		var qty := maxi(1, int(entry.get(qty_key, 1)))
		var taken := mini(qty, remaining)
		qty -= taken
		remaining -= taken
		if qty <= 0:
			InventorySystem.materials.remove_at(i)
		else:
			entry[qty_key] = qty
			InventorySystem.materials[i] = entry
		i -= 1


func _inventory_count_for(mat_id: String) -> int:
	if not _material_catalog.has(mat_id):
		return 0
	var accepted := _accepted_ids_for(mat_id)
	var total := 0
	for entry in InventorySystem.materials:
		if not (entry is Dictionary):
			continue
		var eid := String(entry.get("item_id", ""))
		if eid in accepted:
			total += int(entry.get("quantity", entry.get("amount", 1)))
	return total


func _accepted_ids_for(mat_id: String) -> Array[String]:
	var out: Array[String] = []
	for item_id in MATERIAL_INVENTORY_ALIASES.get(mat_id, [mat_id]):
		out.append(String(item_id))
	if not (mat_id in out):
		out.append(mat_id)
	return out


# --- Tiện Ích Font, Label & Style ---

func _apply_font(ctrl: Control, font: Font, fsize: int) -> void:
	if font != null:
		ctrl.add_theme_font_override("font", font)
	ctrl.add_theme_font_size_override("font_size", fsize)


func _make_ink_lbl(
	txt: String,
	fsize: int,
	col: Color,
	font: Font = null,
	align: int = HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.horizontal_alignment = align as HorizontalAlignment
	_apply_font(lbl, font, fsize)
	lbl.add_theme_color_override("font_color", col)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _make_outlined_lbl(
	txt: String,
	fsize: int,
	col: Color,
	font: Font = null,
	align: int = HORIZONTAL_ALIGNMENT_CENTER
) -> Label:
	var lbl := _make_ink_lbl(txt, fsize, col, font, align)
	lbl.add_theme_color_override("font_outline_color", COL_OUTLINE)
	lbl.add_theme_constant_override("outline_size", 4)
	return lbl


func _make_ink_divider(thickness: float = 3.0, alpha: float = 0.42) -> ColorRect:
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0.0, thickness)
	line.color = Color(0.38, 0.21, 0.10, alpha)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


func _make_page_turn_btn(txt: String, align: HorizontalAlignment, delta: int) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.flat = true
	btn.alignment = align
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_font(btn, _font_lora, 22)
	btn.add_theme_color_override("font_color", COL_INK_MUTED)
	btn.add_theme_color_override("font_hover_color", Color(0.76, 0.18, 0.08, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.58, 0.12, 0.06, 1.0))
	btn.add_theme_color_override("font_outline_color", Color(1.0, 0.78, 0.28, 0.0))
	btn.add_theme_constant_override("outline_size", 0)
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.mouse_entered.connect(func() -> void:
		btn.pivot_offset = btn.size * 0.5
		btn.add_theme_color_override("font_outline_color", Color(1.0, 0.82, 0.34, 0.82))
		btn.add_theme_constant_override("outline_size", 6)
		create_tween().tween_property(btn, "scale", Vector2(1.06, 1.06), 0.11) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func() -> void:
		btn.add_theme_constant_override("outline_size", 0)
		create_tween().tween_property(btn, "scale", Vector2.ONE, 0.12) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.pressed.connect(_turn_book_page.bind(delta))
	return btn


func _make_invisible_btn(tip: String = "") -> Button:
	var btn := Button.new()
	btn.flat = true
	btn.text = ""
	btn.tooltip_text = tip
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn


func _make_tex(
	tex: Texture2D,
	min_sz: Vector2,
	stretch: int = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.custom_minimum_size = min_sz
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = stretch as TextureRect.StretchMode
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _format_mat_bonuses(mat: Dictionary) -> String:
	var parts: Array[String] = []
	for pair in [["atk", "ATK"], ["def", "DEF"], ["magic", "MAG"], ["speed", "SPD"]]:
		var val: int = int(mat[pair[0]])
		if val != 0:
			parts.append("%s%+d" % [pair[1], val])
	if float(mat["price_mult"]) > 1.0:
		parts.append("Giá+%d%%" % int(round((float(mat["price_mult"]) - 1.0) * 100.0)))
	return " ".join(parts) if not parts.is_empty() else "Ổn định"


func _format_allowed_elements(mat: Dictionary) -> String:
	var names: Array[String] = []
	for ek in mat["allowed_elements"]:
		if _PHASE3_SCRIPT.ELEMENTS.has(ek):
			names.append(String(_PHASE3_SCRIPT.ELEMENTS[ek]["name"]))
	return ", ".join(names)


func _tier_roman(tier: int) -> String:
	match tier:
		1:
			return "I"
		2:
			return "II"
		3:
			return "III"
	return str(tier)


func _page_roman(num: int) -> String:
	var table: Array[String] = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
	if num >= 1 and num < table.size():
		return table[num]
	return str(num)


func _skill_name(data: Dictionary) -> String:
	return String(data.get("skill_name", data.get("skill", "")))


func _prototype_path(data: Dictionary) -> String:
	return PATH_WEAPONS + String(data.get("asset", "")) + ".png"


func _try_load_tex(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var loaded := load(path) as Texture2D
		if loaded != null:
			return loaded
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


# Lớp vẽ bóng tiếp xúc dẹt & vòng nét phấn thợ rèn vẽ tay trực tiếp trên nền vải lanh
class _ClothItemUnderlay extends Control:
	var is_selected: bool = false
	var seed_phase: float = 0.0

	func _draw() -> void:
		var foot := Vector2(size.x * 0.50, size.y * 0.72)

		# 1. Vòng nét phấn thợ rèn vẽ tay quanh chân vật khi đang được chọn
		if is_selected:
			_draw_hand_chalk_ring(
				foot + Vector2(0.0, -14.0), 46.0, 34.0,
				Color(0.95, 0.87, 0.68, 0.82), 2.6, 0.0
			)
			_draw_hand_chalk_ring(
				foot + Vector2(1.5, -13.0), 48.5, 36.0,
				Color(0.96, 0.88, 0.72, 0.36), 1.6, 0.9
			)

		# 2. Bóng đè tiếp xúc 2 lớp hình oval dẹt màu nâu mận ấm RGB(18, 10, 12)
		# Khi nhấc vật lên (is_selected): bóng dịch xa hơn xuống-phải và giãn rộng mềm hơn
		var sh_center := foot + (Vector2(5.0, 6.0) if is_selected else Vector2(2.0, 1.0))
		var rx_outer := 38.0 if is_selected else 34.0
		var ry_outer := 15.0 if is_selected else 13.0
		var a_outer := 0.22 if is_selected else 0.28
		var a_inner := 0.36 if is_selected else 0.48
		_draw_oval(sh_center, rx_outer, ry_outer, Color(0.0706, 0.0392, 0.0471, a_outer))
		_draw_oval(sh_center, rx_outer * 0.72, ry_outer * 0.68, Color(0.0706, 0.0392, 0.0471, a_inner))

	func _draw_oval(center: Vector2, rx: float, ry: float, col: Color) -> void:
		var pts := PackedVector2Array()
		var segs := 20
		for i in range(segs):
			var a := float(i) * TAU / float(segs)
			pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(pts, col)

	func _draw_hand_chalk_ring(
		center: Vector2,
		rx: float,
		ry: float,
		col: Color,
		width: float,
		phase_off: float
	) -> void:
		var pts := PackedVector2Array()
		var segs := 32
		# Quét quá 1 vòng một chút (~1.06 vòng) với độ rung tay nhẹ giống nét phấn vẽ trên vải
		for i in range(segs + 3):
			var frac := float(i) / float(segs)
			var a := -0.45 + frac * TAU * 1.04
			var wobble := sin(a * 3.0 + seed_phase + phase_off) * 2.2 \
				+ cos(a * 5.0 - seed_phase) * 1.1
			var r_end := 1.0 + (frac - 0.5) * 0.05
			pts.append(center + Vector2(cos(a) * (rx * r_end + wobble), sin(a) * (ry * r_end + wobble * 0.7)))
		draw_polyline(pts, col, width, false)
