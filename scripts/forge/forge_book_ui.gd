# gdlint: disable=max-file-lines
# Giao diện chọn vũ khí dạng sách — hiển thị trước khi bắt đầu rèn
extends Control

signal weapon_confirmed(weapon_id: String)
signal forge_ready(weapon_id: String, materials: Array)

const PATH_BOOK := "res://assets/UI/book/"
const PATH_WEAPONS := "res://assets/weapons/"
const PATH_BAG := "res://assets/UI/bag/"
const BACKGROUND_PATH := "res://assets/sprites/forge/backgrounds/Forge Scene BG.PNG"
const PATH_ELEMENT_PICKER := "res://scenes/forge/ElementPicker.tscn"
const PATH_WORKSHOP := "res://scenes/main/WorkshopHub.tscn"
const _PHASE_INDICATOR_SCRIPT := preload("res://scripts/forge/forge_phase_indicator.gd")
const BOOK_W := 1180.0
const BOOK_H := 786.0
const BOOK_SCREEN_WIDTH_RATIO := 0.63
const BOOK_SCREEN_HEIGHT_RATIO := 0.60
const BOOK_VERTICAL_OFFSET := 18.0
const PAGE_FLIP_DURATION := 0.92
const PAGE_CONTENT_SWAP_TIME := 0.42
const PAGE_FLIP_LAYER_COUNT := 6
const BOOK_CLOSE_DURATION := 0.42
const MATERIAL_WRAPPER_SIZE := 220.0
const MATERIAL_ICON_SIZE := 172.0
const MATERIAL_ICON_INSET := 24.0
const BAG_POSITION_RATIO := Vector2(0.50, 0.36)
const BAG_VISIBLE_HEIGHT_RATIO := 0.68
const BAG_VISIBLE_HEIGHT_MIN := 396.0
const BAG_VISIBLE_HEIGHT_MAX := 540.0
const BAG_FRAME_COUNT := 8
const BAG_SOURCE_VISIBLE_HEIGHT := 256.0
const BAG_TEXTURE_CENTER_OFFSET := Vector2(4.0, 0.0)
const BAG_OPEN_FPS := 16.0
const BAG_SCATTER_START_FRAME := 8.0
const BAG_LAYER_Z := 0
const MATERIAL_LAYER_Z := 30
const MATERIAL_ICON_Z_BASE := 8
const MATERIAL_MIN_TARGET_DISTANCE := 236.0
const MATERIAL_MIN_BAG_DISTANCE := 300.0
const MATERIAL_MAX_BAG_DISTANCE := 520.0
const MATERIAL_SCATTER_MIN_DISTANCE := 300.0
const MATERIAL_SCATTER_MAX_DISTANCE := 500.0
const MATERIAL_RING_JITTER_ANGLE := 0.14
const MATERIAL_RING_JITTER_RADIUS := 26.0
const MATERIAL_OVERLAP_PADDING := 16.0
const MATERIAL_AVAILABLE_MODULATE := Color(1.18, 1.12, 1.0, 1.0)
const MATERIAL_UNAVAILABLE_MODULATE := Color(0.82, 0.82, 0.82, 0.35)
const MATERIAL_HOVER_MODULATE := Color(1.32, 1.15, 0.86, 1.0)
const NL_TOP_BAR_HEIGHT := 196.0
const NL_BOTTOM_BAR_HEIGHT := 224.0
const NL_SAFE_PADDING := 18.0
const NL_SLOT_SIZE := 78.0
const NL_SLOT_WRAP_SIZE := Vector2(112.0, 118.0)
const NL_SLOT_ROW_GAP := 14
const NL_SLOT_EMPTY_COLOR  := Color(0.92, 0.62, 0.38, 0.68)
const NL_SLOT_FILLED_COLOR := Color("#E8612A")
const NL_SLOT_IMG_EMPTY    := "res://assets/UI/forge/nguyen_lieu/slot1.png"
const NL_SLOT_IMG_FILLED   := "res://assets/UI/forge/nguyen_lieu/slot2.png"
const MATERIAL_INVENTORY_ALIASES := {
	"bac_vun": ["bac_manh"],
	"go_linh": ["go_co_thu", "go_to_nghe"],
	"pha_le": ["pha_le_rung"],
	"mithril": ["mithril_tho"],
	"cat_than": ["cat_thieng"],
	"tro_thieng": ["tro_lo_to"],
}
const PAGE_RIGHT_DESIGN_SIZE := Vector2(
	BOOK_W * (0.91 - 0.555),
	BOOK_H * (0.87 - 0.135)
)

var weapon_data := {
	"kiem_don": {
		"name": "Kiếm Đơn", "atk": 12, "def": 0, "magic": 3, "speed": 6,
		"skill": "Slash", "skill_desc": "Chém cơ bản +50% dmg",
		"customers": "Hiệp Khách", "required_tier": 1, "required_quantity": 2,
		"asset": "Dao ngan",
	},
	"song_dao": {
		"name": "Song Đao", "atk": 10, "def": 0, "magic": 2, "speed": 8,
		"skill": "Twin Strike", "skill_desc": "Đánh 2 lần liên tiếp",
		"customers": "Thích Khách", "required_tier": 2, "required_quantity": 4,
		"asset": "Song dao",
	},
	"giao_dai": {
		"name": "Giáo Dài", "atk": 13, "def": 2, "magic": 1, "speed": 5,
		"skill": "Reach", "skill_desc": "Tấn công trước khi địch đánh",
		"customers": "Thủ Vệ, Hiệp Khách", "required_tier": 1, "required_quantity": 2,
		"asset": "Thuong",
	},
	"bua_chien": {
		"name": "Búa Chiến", "atk": 15, "def": 3, "magic": 0, "speed": 3,
		"skill": "Crush", "skill_desc": "Phá giáp -3 DEF địch",
		"customers": "Võ Tăng, Thủ Vệ", "required_tier": 2, "required_quantity": 4,
		"asset": "Bua",
	},
	"cung_truong": {
		"name": "Cung Trường", "atk": 11, "def": 0, "magic": 4, "speed": 7,
		"skill": "Aim", "skill_desc": "Bỏ qua DEF địch 30%",
		"customers": "Thợ Săn", "required_tier": 2, "required_quantity": 4,
		"asset": "Cung",
	},
	"khien_dong": {
		"name": "Khiên Đồng", "atk": 6, "def": 8, "magic": 0, "speed": 4,
		"skill": "Block", "skill_desc": "Chặn đòn tiếp theo",
		"customers": "Thủ Vệ", "required_tier": 1, "required_quantity": 2,
		"asset": "Khien",
	},
	"quyen_cu": {
		"name": "Quyền Cụ", "atk": 9, "def": 1, "magic": 2, "speed": 9,
		"skill": "Combo", "skill_desc": "Đánh 3 lần, mỗi lần 60% dmg",
		"customers": "Võ Tăng", "required_tier": 2, "required_quantity": 4,
		"asset": "Tay gau",
	},
	"con_nhi_khuc": {
		"name": "Côn Nhị Khúc", "atk": 10, "def": 1, "magic": 3, "speed": 8,
		"skill": "Whirl", "skill_desc": "AoE - cả đội địch nhận dmg",
		"customers": "Võ Tăng, Thích Khách", "required_tier": 2, "required_quantity": 4,
		"asset": "Con nhi khuc",
	},
	"dao_phat": {
		"name": "Đao Phạt", "atk": 16, "def": 2, "magic": 0, "speed": 4,
		"skill": "Heavy Cleave", "skill_desc": "+100% dmg, mất lượt sau",
		"customers": "Thủ Vệ đặc biệt", "required_tier": 3, "required_quantity": 6,
		"asset": "Dao phay",
	},
	"gay_phep": {
		"name": "Gậy Phép", "atk": 5, "def": 0, "magic": 12, "speed": 6,
		"skill": "Cast", "skill_desc": "Dmg = Magic x2",
		"customers": "Đạo Sĩ", "required_tier": 2, "required_quantity": 4,
		"asset": "Truong lua",
	},
	"liem_song": {
		"name": "Liềm Song", "atk": 11, "def": 0, "magic": 2, "speed": 7,
		"skill": "Reap", "skill_desc": "Tấn công + gây Độc",
		"customers": "Thích Khách", "required_tier": 3, "required_quantity": 6,
		"asset": "Song nguyet dao",
	},
	"phoi_no_ban": {
		"name": "Nỏ Bắn", "atk": 15, "def": 0, "magic": 0, "speed": 4,
		"skill": "pierce", "skill_name": "Pierce",
		"skill_desc": "Xuyên giáp - bỏ qua 100% DEF địch",
		"customers": "Thợ Săn, Thích Khách", "required_tier": 3, "required_quantity": 6,
		"asset": "No",
	},
}

var material_data := {
	"sat_tho": {
		"name": "Sắt Thô",
		"icon": "res://assets/UI/forge/nguyen_lieu/1. Sắt Thô.png",
		"tier": 1,
		"atk": 4,
		"speed": 0,
		"def": 1,
		"magic": 0,
		"allowed_elements": ["hoa", "phong", "tho"],
	},
	"dong_vun": {
		"name": "Đồng Vụn",
		"icon": "res://assets/UI/forge/nguyen_lieu/2. Đồng Vụn.png",
		"tier": 1,
		"atk": 3,
		"speed": 0,
		"def": 2,
		"magic": 0,
		"allowed_elements": ["hoa", "phong", "tho"],
	},
	"da_thu": {
		"name": "Da Thú",
		"icon": "res://assets/UI/forge/nguyen_lieu/3. Da Thú.png",
		"tier": 1,
		"atk": 0,
		"speed": 3,
		"def": 1,
		"magic": 0,
		"allowed_elements": ["hoa", "phong", "tho"],
	},
	"bac_vun": {
		"name": "Bạc Vụn",
		"icon": "res://assets/UI/forge/nguyen_lieu/4. Bạc Vụn.png",
		"tier": 1,
		"atk": 1,
		"speed": 0,
		"def": 0,
		"magic": 3,
		"allowed_elements": ["hoa", "phong", "tho", "bang", "set"],
	},
	"go_linh": {
		"name": "Gỗ Linh",
		"icon": "res://assets/UI/forge/nguyen_lieu/5. Gỗ Linh.png",
		"tier": 2,
		"atk": 0,
		"speed": 4,
		"def": 0,
		"magic": 2,
		"allowed_elements": ["hoa", "phong", "tho", "bang", "set"],
	},
	"pha_le": {
		"name": "Pha Lê",
		"icon": "res://assets/UI/forge/nguyen_lieu/6. Pha Lê Xanh.png",
		"tier": 2,
		"atk": 0,
		"speed": 0,
		"def": 0,
		"magic": 5,
		"allowed_elements": ["hoa", "phong", "tho", "bang", "set"],
	},
	"quang_than": {
		"name": "Quặng Than",
		"icon": "res://assets/UI/forge/nguyen_lieu/9. Quặng Than.png",
		"tier": 2,
		"atk": 2,
		"speed": 0,
		"def": 4,
		"magic": 0,
		"allowed_elements": ["hoa", "phong", "tho"],
	},
	"mithril": {
		"name": "Mithril",
		"icon": "res://assets/UI/forge/nguyen_lieu/10. Mithril.png",
		"tier": 3,
		"atk": 6,
		"speed": 0,
		"def": 3,
		"magic": 0,
		"allowed_elements": ["hoa", "phong", "tho", "bang", "set", "hu_khong"],
	},
	"vas_rong": {
		"name": "Vảy Rồng",
		"icon": "res://assets/UI/forge/nguyen_lieu/12. Vảy Rồng.png",
		"tier": 3,
		"atk": 8,
		"speed": 0,
		"def": 2,
		"magic": 0,
		"allowed_elements": ["hoa", "phong", "tho", "bang", "set", "hu_khong"],
	},
	"cat_than": {
		"name": "Cát Thần",
		"icon": "res://assets/UI/forge/nguyen_lieu/13. Cát Thần.png",
		"tier": 2,
		"atk": 1,
		"speed": 2,
		"def": 0,
		"magic": 2,
		"allowed_elements": ["hoa", "phong", "tho"],
	},
	"tro_thieng": {
		"name": "Tro Thiêng",
		"icon": "res://assets/UI/forge/nguyen_lieu/23. Tro Thiêng.png",
		"tier": 1,
		"atk": 0,
		"speed": 0,
		"def": 5,
		"magic": 1,
		"allowed_elements": ["hoa", "phong", "tho", "bang", "set"],
	},
	"tinh_the_lo": {
		"name": "Tinh Thể Lò",
		"icon": "res://assets/UI/forge/nguyen_lieu/24. Tinh Thể Lò.png",
		"tier": 3,
		"atk": 3,
		"speed": 3,
		"def": 3,
		"magic": 3,
		"allowed_elements": ["hoa", "phong", "tho", "bang", "set", "hu_khong"],
	},
}

var current_weapon := ""
var selected_materials: Array = []
var logo_textures: Dictionary = {}
var weapon_textures: Dictionary = {}

var _book_shadow:   ColorRect
var _book_cover:    TextureRect
var _bia_sach:      TextureRect
var _trang_sach:    TextureRect
var _book_content:  Control
var _page_layers:   Array[TextureRect] = []
var _page_edges:    Array[ColorRect] = []
var _curl_shadow:   ColorRect
var _curl_highlight: ColorRect
var _spine_shadow:  ColorRect
var _weapon_sketch: TextureRect
var _weapon_name:   Label
var _lbl_atk:       Label
var _lbl_spd:       Label
var _lbl_dur:       Label
var _skill_name:    Label
var _confirm_btn:   Button
var _state_phoi: Control
var _state_nl: Control
var _back_btn: Button
var _btn_chon_phoi: Button
var _btn_confirm_nl: Button
var _tui_anim: AnimatedSprite2D
var _tui_placeholder: ColorRect
var _nl_top_bar: Control
var _phoi_badge: PanelContainer
var _bag_area: Control
var _nl_scatter_zone: Control
var _nl_bottom_bar: Control
var _slot_row: HBoxContainer
var _slot_counter: Label
var _material_slots: Array[Control] = []
var _slot_material_ids: Array = []
var _btn_confirm_pulse_tween: Tween
var _stat_preview_atk: Label
var _stat_preview_spd: Label
var _stat_preview_def: Label
var _phoi_mini_icon: TextureRect
var _phoi_mini_name: Label
var _anim_player:   AnimationPlayer
var _weapon_list:   GridContainer
var _weapon_buttons: Dictionary = {}
var _flip_token := 0
var _is_nl_transitioning := false
var _material_ids_to_restore: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_state_phoi.visible = true
	_state_nl.visible = false
	_btn_confirm_nl.disabled = true
	# Flow mới chọn nguyên liệu ngay trong sách nên ẩn nút cũ.
	_confirm_btn.visible = false
	_setup_animation()
	_build_weapon_buttons()
	var initial_weapon := GameManager.selected_blank.get("id", "kiem_don") as String
	if not weapon_data.has(initial_weapon):
		initial_weapon = "kiem_don"
	select_weapon(initial_weapon)
	var resize_callable := Callable(self, "_fit_book")
	if not resized.is_connected(resize_callable):
		resized.connect(resize_callable)
	_fit_book()
	_setup_phase_indicator()
	_update_back_button()
	if GameManager.forge_return_to_material_step:
		GameManager.forge_return_to_material_step = false
		_material_ids_to_restore = GameManager.selected_material.get("material_ids", []).duplicate()
		call_deferred("_resume_material_step")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_back_pressed()


# ═══════════════════════════════════════════════════════════════
# BUILD UI
# ═══════════════════════════════════════════════════════════════

func _build_ui() -> void:
	# Nền lò rèn giữ full-screen, sách chỉ nằm ở trung tâm.
	var bg := TextureRect.new()
	bg.name = "ForgeBackground"
	bg.texture = _try_load(BACKGROUND_PATH)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_back_btn = Button.new()
	_back_btn.name = "BackBtn"
	_back_btn.text = "[ Quay lại bước trước  (Esc) ]"
	_back_btn.position = Vector2(32, 28)
	_back_btn.size = Vector2(320, 44)
	_back_btn.add_theme_font_size_override("font_size", 18)
	_back_btn.pressed.connect(_on_back_pressed)
	add_child(_back_btn)

	_book_shadow = ColorRect.new()
	_book_shadow.name = "BookShadow"
	_book_shadow.color = Color(0, 0, 0, 1.0)
	_book_shadow.modulate.a = 0.4
	_book_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor_book(_book_shadow, 10, 14)
	add_child(_book_shadow)

	var cover_texture := _try_load(_find_book_cover_path())
	var page_texture := _try_load(_find_png(PATH_BOOK, "Trang"))

	_book_cover = TextureRect.new()
	_book_cover.name = "BookCover"
	_book_cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_book_cover.stretch_mode = TextureRect.STRETCH_SCALE
	_book_cover.texture = cover_texture
	_book_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor_book(_book_cover, 0, 0)
	add_child(_book_cover)

	# TrangSach giữ nguyên phía sau để khi BiaSach lật không bị trống nền.
	_trang_sach = TextureRect.new()
	_trang_sach.name = "TrangSach"
	_trang_sach.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_trang_sach.stretch_mode = TextureRect.STRETCH_SCALE
	_trang_sach.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trang_sach.texture = page_texture
	_anchor_book(_trang_sach, 0, 0)
	if not _trang_sach.texture:
		# Placeholder màu giấy
		var cr := ColorRect.new()
		cr.color = Color(0.93, 0.89, 0.78)
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_anchor_book(cr, 0, 0)
		add_child(cr)
	add_child(_trang_sach)

	# BiaSach là lớp lật trang, chứa nội dung đang chọn.
	_bia_sach = TextureRect.new()
	_bia_sach.name = "BiaSach"
	_bia_sach.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bia_sach.stretch_mode = TextureRect.STRETCH_SCALE
	_bia_sach.texture = page_texture
	_anchor_book(_bia_sach, 0, 0)
	_bia_sach.pivot_offset = Vector2(BOOK_W / 2.0, BOOK_H / 2.0)
	_bia_sach.clip_contents = true
	_bia_sach.modulate.a = 1.0
	if not _bia_sach.texture:
		var cr := ColorRect.new()
		cr.color = Color(0.87, 0.80, 0.66)
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_anchor_book(cr, 0, 0)
		add_child(cr)
	add_child(_bia_sach)

	_build_page_flip_fx(page_texture)

	_book_content = Control.new()
	_book_content.name = "BookContent"
	_book_content.position = Vector2.ZERO
	_book_content.size = Vector2(BOOK_W, BOOK_H)
	_book_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bia_sach.add_child(_book_content)

	var page_left := Control.new()
	page_left.name = "PageLeft"
	page_left.anchor_left = 0.09
	page_left.anchor_right = 0.445
	page_left.anchor_top = 0.135
	page_left.anchor_bottom = 0.87
	page_left.offset_left = 0
	page_left.offset_right = 0
	page_left.offset_top = 0
	page_left.offset_bottom = 0
	_book_content.add_child(page_left)

	var logo_center := CenterContainer.new()
	logo_center.name = "WeaponLogoCenter"
	logo_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_left.add_child(logo_center)

	var weapon_list := GridContainer.new()
	weapon_list.name = "WeaponList"
	weapon_list.columns = 3
	weapon_list.add_theme_constant_override("h_separation", 24)
	weapon_list.add_theme_constant_override("v_separation", 18)
	logo_center.add_child(weapon_list)
	_weapon_list = weapon_list

	var page_right := Control.new()
	page_right.name = "PageRight"
	page_right.anchor_left = 0.555
	page_right.anchor_right = 0.91
	page_right.anchor_top = 0.135
	page_right.anchor_bottom = 0.87
	page_right.offset_left = 0
	page_right.offset_right = 0
	page_right.offset_top = 0
	page_right.offset_bottom = 0
	_book_content.add_child(page_right)

	_state_phoi = Control.new()
	_state_phoi.name = "StatePhoi"
	_state_phoi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_right.add_child(_state_phoi)

	var mr := MarginContainer.new()
	mr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mr.add_theme_constant_override("margin_left", 18)
	mr.add_theme_constant_override("margin_right", 18)
	mr.add_theme_constant_override("margin_top", 16)
	mr.add_theme_constant_override("margin_bottom", 16)
	_state_phoi.add_child(mr)

	var right_vbox := VBoxContainer.new()
	right_vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	right_vbox.add_theme_constant_override("separation", 16)
	mr.add_child(right_vbox)

	_weapon_sketch = TextureRect.new()
	_weapon_sketch.name = "WeaponSketch"
	_weapon_sketch.custom_minimum_size = Vector2(190, 235)
	_weapon_sketch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_weapon_sketch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_weapon_sketch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_vbox.add_child(_weapon_sketch)

	_weapon_name = Label.new()
	_weapon_name.name = "WeaponName"
	_weapon_name.add_theme_font_size_override("font_size", 34)
	_weapon_name.add_theme_color_override("font_color", Color(0.10, 0.05, 0.01))
	_weapon_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_vbox.add_child(_weapon_name)

	var stats_panel := VBoxContainer.new()
	stats_panel.name = "StatsPanel"
	stats_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_panel.add_theme_constant_override("separation", 8)
	right_vbox.add_child(stats_panel)

	_lbl_atk = Label.new()
	_lbl_atk.name = "LabelATK"
	_lbl_atk.add_theme_font_size_override("font_size", 22)
	_lbl_atk.add_theme_color_override("font_color", Color(0.10, 0.05, 0.01))
	_lbl_atk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_panel.add_child(_lbl_atk)

	_lbl_spd = Label.new()
	_lbl_spd.name = "LabelSPD"
	_lbl_spd.add_theme_font_size_override("font_size", 22)
	_lbl_spd.add_theme_color_override("font_color", Color(0.10, 0.05, 0.01))
	_lbl_spd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_panel.add_child(_lbl_spd)

	_lbl_dur = Label.new()
	_lbl_dur.name = "LabelDUR"
	_lbl_dur.add_theme_font_size_override("font_size", 20)
	_lbl_dur.add_theme_color_override("font_color", Color(0.10, 0.05, 0.01))
	_lbl_dur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_panel.add_child(_lbl_dur)

	var skill_box := PanelContainer.new()
	skill_box.name = "SkillBox"
	skill_box.add_theme_stylebox_override("panel", _skill_box_style())
	right_vbox.add_child(skill_box)

	_skill_name = Label.new()
	_skill_name.name = "SkillName"
	_skill_name.add_theme_font_size_override("font_size", 19)
	_skill_name.add_theme_color_override("font_color", Color(0.08, 0.04, 0.01))
	_skill_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skill_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_box.add_child(_skill_name)

	var button_spacer := Control.new()
	button_spacer.name = "PhoiButtonSpacer"
	button_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(button_spacer)

	_btn_chon_phoi = Button.new()
	_btn_chon_phoi.name = "BtnChonPhoi"
	_btn_chon_phoi.text = "Chọn phôi này →"
	_btn_chon_phoi.add_theme_font_size_override("font_size", 22)
	_btn_chon_phoi.add_theme_color_override("font_color", Color(0.16, 0.07, 0.02))
	_btn_chon_phoi.add_theme_stylebox_override("normal", _confirm_button_style(false))
	_btn_chon_phoi.add_theme_stylebox_override("hover", _confirm_button_style(true))
	_btn_chon_phoi.add_theme_stylebox_override("pressed", _confirm_button_style(true))
	_btn_chon_phoi.custom_minimum_size = Vector2(300, 56)
	add_child(_btn_chon_phoi)

	_build_state_nl()
	_btn_chon_phoi.pressed.connect(transition_to_nl_state)
	_btn_confirm_nl.pressed.connect(_on_confirm_nl_pressed)

	_confirm_btn = _build_confirm_button()
	add_child(_confirm_btn)


func _build_page_flip_fx(page_texture: Texture2D) -> void:
	# Các lớp giấy mỏng lật lệch nhịp để sách có cảm giác dày.
	_spine_shadow = _build_flip_color_rect("SpineShadow", Color(0.12, 0.05, 0.01, 1.0))
	_spine_shadow.modulate.a = 0.24
	add_child(_spine_shadow)

	for index in range(PAGE_FLIP_LAYER_COUNT):
		var layer := TextureRect.new()
		layer.name = "FlipPage%d" % index
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.stretch_mode = TextureRect.STRETCH_SCALE
		layer.texture = page_texture
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.modulate = Color(1.0, 0.97, 0.88, 0.0)
		_anchor_book(layer, 0, 0)
		add_child(layer)
		_page_layers.append(layer)

		var edge := _build_flip_color_rect(
			"FlipPageEdge%d" % index,
			Color(0.48, 0.30, 0.12, 1.0)
		)
		edge.modulate.a = 0.0
		add_child(edge)
		_page_edges.append(edge)

	_curl_shadow = _build_flip_color_rect("PageCurlShadow", Color(0, 0, 0, 1.0))
	_curl_shadow.modulate.a = 0.0
	add_child(_curl_shadow)

	_curl_highlight = _build_flip_color_rect("PageCurlHighlight", Color(1.0, 0.92, 0.68, 1.0))
	_curl_highlight.modulate.a = 0.0
	add_child(_curl_highlight)


func _build_flip_color_rect(node_name: String, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor_book(rect, 0, 0)
	return rect


func _build_confirm_button() -> Button:
	var button := Button.new()
	button.name = "ConfirmBtn"
	button.text = "Bắt đầu rèn →"
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color(0.16, 0.07, 0.02))
	button.add_theme_stylebox_override("normal", _confirm_button_style(false))
	button.add_theme_stylebox_override("hover", _confirm_button_style(true))
	button.add_theme_stylebox_override("pressed", _confirm_button_style(true))
	button.custom_minimum_size = Vector2(360, 64)
	button.pressed.connect(_on_confirm_pressed)
	return button


func _build_state_nl() -> void:
	_state_nl = Control.new()
	_state_nl.name = "StateNL"
	_state_nl.mouse_filter = Control.MOUSE_FILTER_STOP
	_state_nl.clip_contents = false
	_state_nl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_state_nl)

	_nl_top_bar = Control.new()
	_nl_top_bar.name = "TopBar"
	_nl_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_state_nl.add_child(_nl_top_bar)

	_phoi_badge = PanelContainer.new()
	_phoi_badge.name = "PhoiBadge"
	_phoi_badge.custom_minimum_size = Vector2(286.0, 52.0)
	_phoi_badge.clip_contents = true
	_phoi_badge.add_theme_stylebox_override("panel", _phoi_badge_style())
	_nl_top_bar.add_child(_phoi_badge)

	var badge_margin := MarginContainer.new()
	badge_margin.name = "PhoiBadgePadding"
	badge_margin.custom_minimum_size = Vector2(286.0, 52.0)
	badge_margin.add_theme_constant_override("margin_left", 12)
	badge_margin.add_theme_constant_override("margin_right", 12)
	badge_margin.add_theme_constant_override("margin_top", 8)
	badge_margin.add_theme_constant_override("margin_bottom", 8)
	_phoi_badge.add_child(badge_margin)

	var badge_row := HBoxContainer.new()
	badge_row.name = "PhoiBadgeRow"
	badge_row.custom_minimum_size = Vector2(262.0, 36.0)
	badge_row.add_theme_constant_override("separation", 8)
	badge_margin.add_child(badge_row)

	_phoi_mini_icon = TextureRect.new()
	_phoi_mini_icon.name = "PhoiIcon"
	_phoi_mini_icon.custom_minimum_size = Vector2(32, 32)
	_phoi_mini_icon.size = Vector2(32, 32)
	_phoi_mini_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_phoi_mini_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge_row.add_child(_phoi_mini_icon)

	_phoi_mini_name = Label.new()
	_phoi_mini_name.name = "PhoiLabel"
	_phoi_mini_name.custom_minimum_size = Vector2(214.0, 32.0)
	_phoi_mini_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_phoi_mini_name.add_theme_font_size_override("font_size", 18)
	_phoi_mini_name.add_theme_color_override("font_color", Color(0.10, 0.05, 0.01))
	_phoi_mini_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	_phoi_mini_name.clip_text = true
	_phoi_mini_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_row.add_child(_phoi_mini_name)

	_bag_area = Control.new()
	_bag_area.name = "BagArea"
	_bag_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_state_nl.add_child(_bag_area)

	_tui_anim = AnimatedSprite2D.new()
	_tui_anim.name = "TuiAnim"
	_tui_anim.offset = BAG_TEXTURE_CENTER_OFFSET
	_tui_anim.z_index = BAG_LAYER_Z
	_tui_anim.visible = false
	_bag_area.add_child(_tui_anim)

	var bag_frames: SpriteFrames = _build_bag_sprite_frames()
	if bag_frames != null:
		_tui_anim.sprite_frames = bag_frames
		_tui_anim.animation = "idle"
	else:
		_tui_placeholder = ColorRect.new()
		_tui_placeholder.name = "TuiPlaceholder"
		_tui_placeholder.color = Color(0.38, 0.20, 0.08, 1.0)
		_tui_placeholder.size = Vector2(112, 86)
		_tui_placeholder.visible = false
		_bag_area.add_child(_tui_placeholder)

	_nl_scatter_zone = Control.new()
	_nl_scatter_zone.name = "ScatterZone"
	_nl_scatter_zone.z_index = MATERIAL_LAYER_Z
	_nl_scatter_zone.mouse_filter = Control.MOUSE_FILTER_PASS
	_bag_area.add_child(_nl_scatter_zone)

	var stat_preview := Control.new()
	stat_preview.name = "StatPreview"
	stat_preview.visible = false
	stat_preview.anchor_left = 0.60
	stat_preview.anchor_right = 0.92
	stat_preview.anchor_top = 0.64
	stat_preview.anchor_bottom = 0.84
	stat_preview.offset_left = 0
	stat_preview.offset_right = 0
	stat_preview.offset_top = 0
	stat_preview.offset_bottom = 0
	_state_nl.add_child(stat_preview)

	_stat_preview_atk = _build_preview_label("PreviewATK", Vector2(0, 0))
	stat_preview.add_child(_stat_preview_atk)
	_stat_preview_spd = _build_preview_label("PreviewSPD", Vector2(0, 30))
	stat_preview.add_child(_stat_preview_spd)
	_stat_preview_def = _build_preview_label("PreviewDEF", Vector2(0, 60))
	stat_preview.add_child(_stat_preview_def)

	_nl_bottom_bar = Control.new()
	_nl_bottom_bar.name = "BottomBar"
	_nl_bottom_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	_state_nl.add_child(_nl_bottom_bar)

	_slot_row = HBoxContainer.new()
	_slot_row.name = "SlotRow"
	_slot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_slot_row.add_theme_constant_override("separation", NL_SLOT_ROW_GAP)
	_nl_bottom_bar.add_child(_slot_row)

	_slot_counter = Label.new()
	_slot_counter.name = "SlotCounter"
	_slot_counter.text = "Đã chọn: 0 / 2"
	_slot_counter.add_theme_font_size_override("font_size", 22)
	_slot_counter.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72, 1.0))
	_slot_counter.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
	_slot_counter.add_theme_constant_override("shadow_offset_x", 1)
	_slot_counter.add_theme_constant_override("shadow_offset_y", 2)
	_slot_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nl_bottom_bar.add_child(_slot_counter)

	_btn_confirm_nl = Button.new()
	_btn_confirm_nl.name = "BtnConfirmNL"
	_btn_confirm_nl.text = "Xác nhận →"
	_btn_confirm_nl.add_theme_font_size_override("font_size", 22)
	_btn_confirm_nl.add_theme_color_override("font_color", Color(0.16, 0.07, 0.02))
	_btn_confirm_nl.add_theme_stylebox_override("normal", _confirm_button_style(false))
	_btn_confirm_nl.add_theme_stylebox_override("hover", _confirm_button_style(true))
	_btn_confirm_nl.add_theme_stylebox_override("pressed", _confirm_button_style(true))
	_btn_confirm_nl.add_theme_stylebox_override("disabled", _confirm_button_style(false))
	_btn_confirm_nl.custom_minimum_size = Vector2(210, 54)
	_nl_bottom_bar.add_child(_btn_confirm_nl)
	_rebuild_material_slots(2)


func _build_preview_label(node_name: String, label_position: Vector2) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = label_position
	label.size = Vector2(260, 28)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.10, 0.05, 0.01))
	return label


func _build_bag_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("open")
	frames.set_animation_loop("open", false)
	frames.set_animation_speed("open", BAG_OPEN_FPS)
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 1.0)

	var last_texture: Texture2D = null
	for frame_index in range(1, BAG_FRAME_COUNT + 1):
		var path := "%sbag_f%d.png" % [PATH_BAG, frame_index]
		if not ResourceLoader.exists(path):
			push_warning("ForgeBookUI: missing bag frame %s" % path)
			return null
		var texture := load(path) as Texture2D
		if texture == null:
			push_warning("ForgeBookUI: cannot load bag frame %s" % path)
			return null
		frames.add_frame("open", texture)
		last_texture = texture

	frames.add_frame("idle", last_texture)
	print("ForgeBookUI: bag animation frames loaded: %d" % BAG_FRAME_COUNT)
	return frames


func _setup_phase_indicator() -> void:
	var indicator := get_node_or_null("ForgePhaseIndicator")
	if indicator == null:
		return
	indicator.set_phase(_PHASE_INDICATOR_SCRIPT.Phase.CHON_PHOI)
	move_child(indicator, get_child_count() - 1)


func _anchor_book(node: Control, dx: float, dy: float) -> void:
	node.anchor_left   = 0.5
	node.anchor_right  = 0.5
	node.anchor_top    = 0.5
	node.anchor_bottom = 0.5
	node.offset_left   = -BOOK_W / 2.0 + dx
	node.offset_right  =  BOOK_W / 2.0 + dx
	node.offset_top    = -BOOK_H / 2.0 + dy
	node.offset_bottom =  BOOK_H / 2.0 + dy


func _fit_book() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var book_aspect := BOOK_W / BOOK_H
	var book_w := minf(
		viewport_size.x * BOOK_SCREEN_WIDTH_RATIO,
		viewport_size.y * BOOK_SCREEN_HEIGHT_RATIO * book_aspect
	)
	var book_h := book_w / book_aspect
	var cover_w := book_w * 1.14
	var cover_h := book_h * 1.66
	_set_center_rect(_book_cover, cover_w, cover_h, 0.0, 25.0 + BOOK_VERTICAL_OFFSET)
	_set_center_rect(_trang_sach, book_w, book_h, 0.0, BOOK_VERTICAL_OFFSET)
	_set_center_rect(_bia_sach, book_w, book_h, 0.0, BOOK_VERTICAL_OFFSET)
	_set_center_rect(_book_shadow, book_w, book_h, 10.0, 14.0 + BOOK_VERTICAL_OFFSET)
	_bia_sach.pivot_offset = Vector2(book_w * 0.5, book_h * 0.5)
	_fit_page_flip_fx(book_w, book_h)
	_fit_book_content(book_w, book_h)
	_fit_material_overlay(book_w, book_h)
	_fit_confirm_button(viewport_size)


func _fit_page_flip_fx(book_w: float, book_h: float) -> void:
	for index in range(_page_layers.size()):
		var layer := _page_layers[index]
		_set_center_rect(
			layer,
			book_w,
			book_h,
			0.0,
			BOOK_VERTICAL_OFFSET + float(index) * 0.7
		)
		layer.pivot_offset = Vector2(book_w * 0.5, book_h * 0.5)

	for index in range(_page_edges.size()):
		var edge := _page_edges[index]
		var edge_w := maxf(2.0, book_w * 0.004)
		_set_center_rect(
			edge,
			edge_w,
			book_h * (0.86 - float(index) * 0.025),
			book_w * 0.5 - edge_w * 0.5 - float(index) * 1.25,
			BOOK_VERTICAL_OFFSET + float(index) * 0.7
		)
		edge.pivot_offset = Vector2(edge_w * 0.5, book_h * 0.43)

	var spine_w := maxf(14.0, book_w * 0.018)
	_set_center_rect(
		_spine_shadow,
		spine_w,
		book_h * 0.90,
		-book_w * 0.012,
		BOOK_VERTICAL_OFFSET
	)

	var curl_w := maxf(14.0, book_w * 0.018)
	_set_center_rect(
		_curl_shadow,
		curl_w,
		book_h * 0.88,
		book_w * 0.36,
		BOOK_VERTICAL_OFFSET + 6.0
	)
	_set_center_rect(
		_curl_highlight,
		curl_w * 0.58,
		book_h * 0.84,
		book_w * 0.42,
		BOOK_VERTICAL_OFFSET - 2.0
	)


func _fit_book_content(book_w: float, book_h: float) -> void:
	if _book_content == null:
		return
	_book_content.position = Vector2.ZERO
	_book_content.size = Vector2(BOOK_W, BOOK_H)
	_book_content.scale = Vector2(book_w / BOOK_W, book_h / BOOK_H)


func _fit_material_overlay(_book_w: float, book_h: float) -> void:
	if _state_nl == null:
		return
	var viewport_size := get_viewport_rect().size
	_state_nl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var overlay_size := viewport_size
	if _nl_top_bar != null:
		_nl_top_bar.position = Vector2.ZERO
		_nl_top_bar.size = Vector2(overlay_size.x, NL_TOP_BAR_HEIGHT)
	if _phoi_badge != null:
		_phoi_badge.position = Vector2(32.0, 168.0)
		_phoi_badge.size = Vector2(286.0, 52.0)
	if _bag_area != null:
		_bag_area.position = Vector2.ZERO
		_bag_area.size = overlay_size
	if _nl_bottom_bar != null:
		_nl_bottom_bar.position = Vector2(0.0, overlay_size.y - NL_BOTTOM_BAR_HEIGHT)
		_nl_bottom_bar.size = Vector2(overlay_size.x, NL_BOTTOM_BAR_HEIGHT)
		_layout_bottom_bar(overlay_size)

	var safe_top := NL_TOP_BAR_HEIGHT + NL_SAFE_PADDING
	var safe_bottom := overlay_size.y - NL_BOTTOM_BAR_HEIGHT - NL_SAFE_PADDING
	var safe_height := maxf(1.0, safe_bottom - safe_top)
	var bag_visible_height := clampf(
		book_h * BAG_VISIBLE_HEIGHT_RATIO,
		BAG_VISIBLE_HEIGHT_MIN,
		BAG_VISIBLE_HEIGHT_MAX
	)
	bag_visible_height = minf(bag_visible_height, maxf(220.0, safe_height * 0.82))
	var bag_half_height := bag_visible_height * 0.5
	_tui_anim.position = Vector2(
		overlay_size.x * BAG_POSITION_RATIO.x,
		clampf(
			safe_top + safe_height * BAG_POSITION_RATIO.y,
			safe_top + bag_half_height,
			safe_bottom - bag_half_height
		)
	)
	_tui_anim.scale = Vector2.ONE * (bag_visible_height / BAG_SOURCE_VISIBLE_HEIGHT)
	_tui_anim.z_index = BAG_LAYER_Z
	if _tui_placeholder != null:
		_tui_placeholder.position = _tui_anim.position - _tui_placeholder.size * 0.5
		_tui_placeholder.z_index = BAG_LAYER_Z
	if _nl_scatter_zone != null:
		var zone_size := Vector2(overlay_size.x * 0.88, safe_height)
		zone_size.x = clampf(zone_size.x, 760.0, overlay_size.x - 48.0)
		zone_size.y = clampf(zone_size.y, minf(300.0, safe_height), safe_height)
		var zone_top := safe_top + (safe_height - zone_size.y) * 0.5
		_nl_scatter_zone.position = Vector2((overlay_size.x - zone_size.x) * 0.5, zone_top)
		_nl_scatter_zone.size = zone_size
	print("ForgeBookUI: PART 2 size and position completed")


func _fit_confirm_button(viewport_size: Vector2) -> void:
	_fit_bottom_step_button(_btn_chon_phoi, viewport_size, Vector2(300.0, 56.0))
	if _confirm_btn == null:
		return
	var button_size := Vector2(360.0, 64.0)
	_confirm_btn.size = button_size
	_confirm_btn.position = Vector2(
		(viewport_size.x - button_size.x) * 0.5,
		viewport_size.y - button_size.y - 26.0
	)


func _fit_bottom_step_button(
	button: Button,
	viewport_size: Vector2,
	button_size: Vector2
) -> void:
	if button == null:
		return
	button.anchor_left = 0.0
	button.anchor_right = 0.0
	button.anchor_top = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = 0.0
	button.offset_right = 0.0
	button.offset_top = 0.0
	button.offset_bottom = 0.0
	button.size = button_size
	button.position = Vector2(
		(viewport_size.x - button_size.x) * 0.5,
		viewport_size.y - button_size.y - 26.0
	)


func _set_center_rect(node: Control, width: float, height: float, dx: float, dy: float) -> void:
	if node == null:
		return
	node.offset_left = -width * 0.5 + dx
	node.offset_right = width * 0.5 + dx
	node.offset_top = -height * 0.5 + dy
	node.offset_bottom = height * 0.5 + dy


# ═══════════════════════════════════════════════════════════════
# ANIMATION
# ═══════════════════════════════════════════════════════════════

func _setup_animation() -> void:
	_anim_player = AnimationPlayer.new()
	_anim_player.name = "AnimationPlayer"
	add_child(_anim_player)

	var lib  := AnimationLibrary.new()
	var anim := Animation.new()
	anim.length = PAGE_FLIP_DURATION

	# Lật trang chính chậm hơn, có khựng nhẹ khi giấy chạm mặt sách.
	var scale_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(scale_track, NodePath("BiaSach:scale:x"))
	anim.track_set_interpolation_type(scale_track, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(scale_track, 0.0, 1.0)
	anim.track_insert_key(scale_track, 0.24, 0.18)
	anim.track_insert_key(scale_track, PAGE_CONTENT_SWAP_TIME, 0.035)
	anim.track_insert_key(scale_track, 0.68, 1.035)
	anim.track_insert_key(scale_track, PAGE_FLIP_DURATION, 1.0)

	var rotation_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rotation_track, NodePath("BiaSach:rotation_degrees"))
	anim.track_set_interpolation_type(rotation_track, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(rotation_track, 0.0, 0.0)
	anim.track_insert_key(rotation_track, 0.30, -3.0)
	anim.track_insert_key(rotation_track, 0.64, 2.0)
	anim.track_insert_key(rotation_track, PAGE_FLIP_DURATION, 0.0)

	var alpha_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(alpha_track, NodePath("BiaSach:modulate:a"))
	anim.track_set_interpolation_type(alpha_track, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(alpha_track, 0.0, 1.0)
	anim.track_insert_key(alpha_track, 0.24, 0.74)
	anim.track_insert_key(alpha_track, PAGE_CONTENT_SWAP_TIME, 0.58)
	anim.track_insert_key(alpha_track, 0.68, 0.92)
	anim.track_insert_key(alpha_track, PAGE_FLIP_DURATION, 1.0)

	var shadow_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(shadow_track, NodePath("BookShadow:modulate:a"))
	anim.track_set_interpolation_type(shadow_track, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(shadow_track, 0.0, 0.4)
	anim.track_insert_key(shadow_track, 0.38, 0.62)
	anim.track_insert_key(shadow_track, 0.68, 0.30)
	anim.track_insert_key(shadow_track, PAGE_FLIP_DURATION, 0.4)

	_add_flip_overlay_animation(anim)
	_add_flip_layer_animations(anim)

	lib.add_animation("page_flip", anim)
	_anim_player.add_animation_library("", lib)
	_anim_player.animation_finished.connect(_on_flip_finished)


func _add_flip_overlay_animation(anim: Animation) -> void:
	_add_value_track(
		anim,
		NodePath("PageCurlShadow:modulate:a"),
		[0.0, 0.18, 0.46, 0.72, PAGE_FLIP_DURATION],
		[0.0, 0.08, 0.18, 0.06, 0.0]
	)
	_add_value_track(
		anim,
		NodePath("PageCurlShadow:scale:x"),
		[0.0, 0.42, PAGE_FLIP_DURATION],
		[0.7, 1.45, 0.7]
	)
	_add_value_track(
		anim,
		NodePath("PageCurlHighlight:modulate:a"),
		[0.0, 0.22, 0.48, 0.70, PAGE_FLIP_DURATION],
		[0.0, 0.05, 0.12, 0.04, 0.0]
	)
	_add_value_track(
		anim,
		NodePath("SpineShadow:modulate:a"),
		[0.0, 0.32, 0.62, PAGE_FLIP_DURATION],
		[0.24, 0.40, 0.30, 0.24]
	)


func _add_flip_layer_animations(anim: Animation) -> void:
	for index in range(_page_layers.size()):
		var layer_name := "FlipPage%d" % index
		var edge_name := "FlipPageEdge%d" % index
		var delay := float(index) * 0.035
		var close_t := minf(0.31 + delay, 0.48)
		var open_t := minf(0.57 + delay, 0.78)
		var settle_t := minf(0.78 + delay * 0.45, 0.87)
		var alpha_peak := 0.42 - float(index) * 0.035
		var tint := 0.93 - float(index) * 0.015

		_add_value_track(
			anim,
			NodePath("%s:scale:x" % layer_name),
			[0.0, close_t, open_t, settle_t, PAGE_FLIP_DURATION],
			[1.0, 0.055, 1.03, 0.985, 1.0]
		)
		_add_value_track(
			anim,
			NodePath("%s:rotation_degrees" % layer_name),
			[0.0, close_t, open_t, PAGE_FLIP_DURATION],
			[0.0, -4.0 + float(index) * 0.35, 1.6, 0.0]
		)
		_add_value_track(
			anim,
			NodePath("%s:modulate:a" % layer_name),
			[0.0, 0.09 + delay, close_t, open_t, PAGE_FLIP_DURATION],
			[0.0, alpha_peak, alpha_peak * 0.82, alpha_peak * 0.5, 0.0]
		)
		_add_value_track(
			anim,
			NodePath("%s:modulate:g" % layer_name),
			[0.0, close_t, open_t, PAGE_FLIP_DURATION],
			[0.97, tint, 0.98, 0.97]
		)
		_add_value_track(
			anim,
			NodePath("%s:modulate:a" % edge_name),
			[0.0, 0.12 + delay, close_t, open_t, PAGE_FLIP_DURATION],
			[0.0, 0.24, 0.58, 0.20, 0.0]
		)
		_add_value_track(
			anim,
			NodePath("%s:rotation_degrees" % edge_name),
			[0.0, close_t, open_t, PAGE_FLIP_DURATION],
			[0.0, -5.0 + float(index) * 0.4, 1.8, 0.0]
		)


func _add_value_track(
	anim: Animation,
	path: NodePath,
	times: Array,
	values: Array
) -> void:
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, path)
	anim.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
	for index in range(times.size()):
		anim.track_insert_key(track, times[index], values[index])


# ═══════════════════════════════════════════════════════════════
# WEAPON LIST
# ═══════════════════════════════════════════════════════════════

func _build_weapon_buttons() -> void:
	if not _weapon_list:
		push_warning("ForgeBookUI: WeaponList node not found")
		return
	for id: String in weapon_data.keys():
		var data := weapon_data[id] as Dictionary
		var asset_name := data["asset"] as String
		var btn := Button.new()
		btn.name = id
		btn.text = ""
		btn.icon = logo_textures.get(id) as Texture2D
		btn.expand_icon = true
		btn.tooltip_text = data["name"]
		btn.custom_minimum_size = Vector2(92, 122)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_stylebox_override("normal", _logo_button_style(false))
		btn.add_theme_stylebox_override("hover", _logo_button_style(true))
		btn.add_theme_stylebox_override("pressed", _logo_button_style(true))
		if data.get("required_tier", 1) > GameManager.current_tier:
			btn.tooltip_text += " (Tier %d)" % data["required_tier"]
			btn.disabled = true
			btn.modulate = Color(1, 1, 1, 0.35)
		btn.pressed.connect(select_weapon.bind(id))
		_weapon_list.add_child(btn)
		_weapon_buttons[id] = btn
		logo_textures[id] = _try_load(_weapon_asset_path("Logo", asset_name + " Logo.png"))
		weapon_textures[id] = _try_load(_weapon_asset_path("prototype", asset_name + ".png"))
		if logo_textures[id] == null:
			logo_textures[id] = weapon_textures[id]
		btn.icon = logo_textures[id]


# ═══════════════════════════════════════════════════════════════
# PUBLIC
# ═══════════════════════════════════════════════════════════════

func select_weapon(weapon_id: String) -> void:
	if weapon_id == current_weapon or not weapon_data.has(weapon_id):
		return
	var data := weapon_data[weapon_id] as Dictionary
	if data.get("required_tier", 1) > GameManager.current_tier:
		return
	_flip_token += 1
	var flip_token := _flip_token
	current_weapon = weapon_id
	_update_list_highlight(weapon_id)
	print("page_flip start: %s" % weapon_id)
	_anim_player.play("page_flip")
	await get_tree().create_timer(PAGE_CONTENT_SWAP_TIME).timeout
	if flip_token != _flip_token or weapon_id != current_weapon:
		return
	_update_weapon_content(weapon_id)


# ═══════════════════════════════════════════════════════════════
# MATERIAL FLOW
# ═══════════════════════════════════════════════════════════════

func transition_to_nl_state() -> void:
	if current_weapon == "" or not weapon_data.has(current_weapon):
		return
	if _is_nl_transitioning or _state_nl.visible:
		return
	print("ForgeBookUI: transition to material state")
	_is_nl_transitioning = true
	_btn_chon_phoi.disabled = true
	_btn_chon_phoi.visible = false
	_set_book_indicator_phase(_PHASE_INDICATOR_SCRIPT.Phase.CHON_NL)

	var phoi := weapon_data[current_weapon] as Dictionary
	_phoi_mini_name.text = "Đang rèn: %s" % (phoi["name"] as String)
	_phoi_mini_icon.texture = weapon_textures.get(current_weapon) as Texture2D
	_rebuild_material_slots(phoi.get("required_quantity", 2) as int)
	_reset_material_slots()
	_update_stat_preview()

	await _close_and_hide_book()

	var tween := create_tween()
	_state_nl.visible = true
	_state_nl.modulate.a = 0.0
	tween.tween_property(_state_nl, "modulate:a", 1.0, 0.18).set_ease(Tween.EASE_OUT)
	await tween.finished

	await get_tree().process_frame
	await play_bag_open()
	_is_nl_transitioning = false
	_update_back_button()


func _close_and_hide_book() -> void:
	print("ForgeBookUI: close book")
	if _anim_player != null and _anim_player.is_playing():
		_anim_player.stop()
	_btn_chon_phoi.disabled = true
	_state_phoi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var close_tween := create_tween().set_parallel(true)
	for node: Control in _get_book_visual_nodes():
		if node == null:
			continue
		node.pivot_offset = node.size * 0.5
		close_tween.tween_property(
			node,
			"scale",
			Vector2(0.08, 0.92),
			BOOK_CLOSE_DURATION
		).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		close_tween.tween_property(
			node,
			"modulate:a",
			0.0,
			BOOK_CLOSE_DURATION
		).set_ease(Tween.EASE_IN)
	await close_tween.finished
	for node: Control in _get_book_visual_nodes():
		if node != null:
			node.visible = false


func _restore_book_visuals() -> void:
	for node: Control in _get_book_visual_nodes():
		if node == null:
			continue
		node.visible = true
		node.scale = Vector2.ONE
		node.modulate.a = 0.4 if node == _book_shadow else 1.0
	for layer: TextureRect in _page_layers:
		layer.modulate.a = 0.0
	for edge: ColorRect in _page_edges:
		edge.modulate.a = 0.0
	if _curl_shadow != null:
		_curl_shadow.modulate.a = 0.0
	if _curl_highlight != null:
		_curl_highlight.modulate.a = 0.0
	if _spine_shadow != null:
		_spine_shadow.modulate.a = 0.24


func _resume_material_step() -> void:
	await transition_to_nl_state()
	selected_materials = _material_ids_to_restore.duplicate()
	_material_ids_to_restore.clear()
	_update_nl_visual()
	_update_stat_preview()


func _return_to_weapon_step() -> void:
	_is_nl_transitioning = false
	_state_nl.visible = false
	_state_nl.modulate.a = 0.0
	selected_materials.clear()
	_reset_material_slots()
	GameManager.selected_material = {}
	GameManager.selected_element = ""
	for child in _nl_scatter_zone.get_children():
		child.queue_free()
	_tui_anim.visible = false
	if _tui_placeholder != null:
		_tui_placeholder.visible = false
	_restore_book_visuals()
	_btn_chon_phoi.disabled = false
	_btn_chon_phoi.visible = true
	_state_phoi.mouse_filter = Control.MOUSE_FILTER_PASS
	_set_book_indicator_phase(_PHASE_INDICATOR_SCRIPT.Phase.CHON_PHOI)
	_update_back_button()


func _update_back_button() -> void:
	if _back_btn == null:
		return
	_back_btn.visible = true
	_back_btn.disabled = _is_nl_transitioning
	if _state_nl != null and _state_nl.visible:
		_back_btn.text = "[ Quay lại chọn phôi  (Esc) ]"
	else:
		_back_btn.text = "[ Thoát khỏi lò rèn  (Esc) ]"


func _get_book_visual_nodes() -> Array[Control]:
	var nodes: Array[Control] = [
		_book_shadow,
		_book_cover,
		_trang_sach,
		_bia_sach,
		_spine_shadow,
		_curl_shadow,
		_curl_highlight,
	]
	for layer: TextureRect in _page_layers:
		nodes.append(layer)
	for edge: ColorRect in _page_edges:
		nodes.append(edge)
	return nodes


func play_bag_open() -> void:
	print("ForgeBookUI: play bag open")
	_tui_anim.visible = _tui_anim.sprite_frames != null
	if _tui_placeholder != null:
		_tui_placeholder.visible = _tui_anim.sprite_frames == null

	if _tui_anim.sprite_frames == null:
		await get_tree().create_timer(0.25).timeout
		scatter_materials()
		return

	_tui_anim.play("open")
	await get_tree().create_timer(_get_bag_scatter_delay()).timeout
	scatter_materials()
	await _tui_anim.animation_finished
	_tui_anim.play("idle")


func _get_bag_scatter_delay() -> float:
	return maxf(0.0, (BAG_SCATTER_START_FRAME - 1.0) / BAG_OPEN_FPS)


func scatter_materials() -> void:
	print("ForgeBookUI: scatter materials")
	var zone_size := _nl_scatter_zone.size
	if zone_size.x <= 0.0 or zone_size.y <= 0.0:
		zone_size = _state_nl.size * Vector2(0.70, 0.55)

	for child in _nl_scatter_zone.get_children():
		child.queue_free()
	selected_materials.clear()
	_reset_material_slots()

	var bag_pos: Vector2 = (
		_nl_scatter_zone.get_global_transform().affine_inverse()
		* _tui_anim.global_position
	)
	var spawn_list := _get_scatter_material_ids(zone_size)
	var target_positions := _build_material_target_positions(spawn_list.size(), zone_size, bag_pos)

	for index in range(spawn_list.size()):
		var mat_id := spawn_list[index] as String
		var mat := material_data[mat_id] as Dictionary
		var is_selectable := _is_material_selectable(mat_id)
		var icon := _build_material_icon(mat_id, mat, is_selectable)
		var is_locked := not is_selectable
		icon.pivot_offset = Vector2(
			MATERIAL_WRAPPER_SIZE * 0.5,
			MATERIAL_WRAPPER_SIZE * 0.5
		)
		icon.position = bag_pos - icon.pivot_offset
		icon.modulate.a = 0.0
		icon.z_index = MATERIAL_ICON_Z_BASE + index
		icon.set_meta("locked", is_locked)
		_nl_scatter_zone.add_child(icon)

		var target_pos := target_positions[index] as Vector2
		icon.set_meta("scatter_position", target_pos)
		var delay := float(index) * 0.05
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(
			icon,
			"modulate",
			MATERIAL_AVAILABLE_MODULATE if is_selectable else MATERIAL_UNAVAILABLE_MODULATE,
			0.14
		)
		tween.parallel().tween_property(
			icon,
			"position",
			target_pos + _get_material_launch_offset(index),
			0.28
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(
			icon,
			"position",
			target_pos,
			0.18
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_callback(_start_material_float.bind(icon, target_pos, not is_selectable))

		if is_selectable:
			icon.gui_input.connect(
				func(event: InputEvent): _on_mat_clicked(event, mat_id)
			)
			icon.mouse_entered.connect(_on_material_hovered.bind(icon, true))
			icon.mouse_exited.connect(_on_material_hovered.bind(icon, false))

	_update_stat_preview()
	print("ForgeBookUI: PART 3 NL scatter logic completed")


func _get_scatter_material_ids(zone_size: Vector2) -> Array:
	var ids: Array = []
	for mat_id in material_data.keys():
		if _inventory_count_for_material(mat_id as String) > 0:
			ids.append(mat_id)
	if ids.is_empty():
		ids = material_data.keys()
	var max_visible := _max_visible_material_count(zone_size)
	return ids.slice(0, mini(max_visible, ids.size()))


func _max_visible_material_count(zone_size: Vector2) -> int:
	var cell_size := MATERIAL_WRAPPER_SIZE + MATERIAL_OVERLAP_PADDING
	var columns := maxi(1, int(zone_size.x / cell_size))
	var rows := maxi(1, int(zone_size.y / cell_size))
	return maxi(4, mini(8, columns * rows))


func _build_material_target_positions(
	total: int,
	zone_size: Vector2,
	bag_pos: Vector2
) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if total <= 0:
		return positions
	var icon_half := Vector2(MATERIAL_WRAPPER_SIZE * 0.5, MATERIAL_WRAPPER_SIZE * 0.5)
	if _can_place_on_single_arc(total, zone_size):
		for center: Vector2 in _build_single_arc_centers(total, zone_size, bag_pos):
			positions.append(center - icon_half)
		return positions
	var occupied_centers: Array[Vector2] = []
	var candidates := _build_grid_ring_candidates(total, zone_size, bag_pos)
	var angle_seed := randf_range(-0.20, 0.20)

	for index in range(total):
		var target_angle := (float(index) / maxf(1.0, float(total))) * TAU + angle_seed
		var center := _pick_material_candidate(candidates, occupied_centers, target_angle)
		occupied_centers.append(center)
		positions.append(center - icon_half)
	return positions


func _build_grid_ring_candidates(
	total: int,
	zone_size: Vector2,
	bag_pos: Vector2
) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var cell_size := MATERIAL_WRAPPER_SIZE + MATERIAL_OVERLAP_PADDING
	var max_columns := maxi(1, int(zone_size.x / cell_size))
	var max_rows := maxi(1, int(zone_size.y / cell_size))
	var columns := mini(total, max_columns)
	var rows := mini(max_rows, maxi(1, int(ceil(float(total) / float(columns)))))
	var icon_half := Vector2(MATERIAL_WRAPPER_SIZE * 0.5, MATERIAL_WRAPPER_SIZE * 0.5)
	var spacing_x := 0.0
	var spacing_y := 0.0
	if columns > 1:
		spacing_x = (zone_size.x - MATERIAL_WRAPPER_SIZE) / float(columns - 1)
	if rows > 1:
		spacing_y = (zone_size.y - MATERIAL_WRAPPER_SIZE) / float(rows - 1)
	var max_x_jitter := minf(16.0, maxf(0.0, (spacing_x - MATERIAL_WRAPPER_SIZE) * 0.33))
	var max_y_jitter := minf(16.0, maxf(0.0, (spacing_y - MATERIAL_WRAPPER_SIZE) * 0.33))

	for row in range(rows):
		for column in range(columns):
			var x := icon_half.x
			if columns > 1:
				x += spacing_x * float(column)
			else:
				x = zone_size.x * 0.5
			var y := icon_half.y
			if rows > 1:
				y += spacing_y * float(row)
			else:
				y = bag_pos.y
			x += randf_range(-max_x_jitter, max_x_jitter)
			y += randf_range(-max_y_jitter, max_y_jitter)
			var center := _clamp_material_center(Vector2(x, y), zone_size)
			var delta := center - bag_pos
			candidates.append({
				"center": center,
				"angle": atan2(delta.y, delta.x),
				"ring": 0,
			})
	return candidates


func _can_place_on_single_arc(total: int, zone_size: Vector2) -> bool:
	if total <= 1:
		return true
	var available_width := zone_size.x - MATERIAL_WRAPPER_SIZE
	var spacing := available_width / float(total - 1)
	return spacing >= MATERIAL_WRAPPER_SIZE + MATERIAL_OVERLAP_PADDING


func _build_single_arc_centers(
	total: int,
	zone_size: Vector2,
	bag_pos: Vector2
) -> Array[Vector2]:
	var centers: Array[Vector2] = []
	var icon_half := Vector2(MATERIAL_WRAPPER_SIZE * 0.5, MATERIAL_WRAPPER_SIZE * 0.5)
	if total <= 1:
		centers.append(_clamp_material_center(bag_pos, zone_size))
		return centers
	var available_width := zone_size.x - MATERIAL_WRAPPER_SIZE
	var spacing := available_width / float(total - 1)
	var max_x_jitter := minf(22.0, maxf(0.0, (spacing - MATERIAL_WRAPPER_SIZE) * 0.33))
	var y_radius := maxf(0.0, zone_size.y * 0.5 - icon_half.y)
	y_radius = minf(80.0, y_radius)
	for index in range(total):
		var ratio := float(index) / float(total - 1)
		var angle := PI - ratio * PI
		var x := icon_half.x + spacing * float(index)
		x += randf_range(-max_x_jitter, max_x_jitter)
		var y := bag_pos.y - sin(angle) * y_radius
		y += randf_range(-6.0, 6.0)
		centers.append(_clamp_material_center(Vector2(x, y), zone_size))
	return centers


func _build_ring_candidates(
	total: int,
	zone_size: Vector2,
	bag_pos: Vector2
) -> Array[Dictionary]:
	var icon_half := Vector2(MATERIAL_WRAPPER_SIZE * 0.5, MATERIAL_WRAPPER_SIZE * 0.5)
	var max_radius_x := maxf(1.0, zone_size.x * 0.5 - icon_half.x)
	var max_radius_y := maxf(1.0, zone_size.y * 0.5 - icon_half.y)
	var base_radius_x := minf(MATERIAL_SCATTER_MAX_DISTANCE, max_radius_x)
	var base_radius_y := minf(MATERIAL_SCATTER_MAX_DISTANCE * 0.72, max_radius_y)
	var ring_count := 1
	if total > 6 and zone_size.y >= MATERIAL_WRAPPER_SIZE * 2.1:
		ring_count = 2
	if total > 10 and zone_size.y >= MATERIAL_WRAPPER_SIZE * 3.0:
		ring_count = 3
	var points_per_ring := maxi(total * 6, 32)
	var candidates: Array[Dictionary] = []

	for ring_index in range(ring_count):
		var ring_scale := 1.0 - float(ring_index) * 0.24
		var radius_x := maxf(1.0, base_radius_x * ring_scale)
		var radius_y := maxf(1.0, base_radius_y * ring_scale)
		var angle_offset := randf_range(-MATERIAL_RING_JITTER_ANGLE, MATERIAL_RING_JITTER_ANGLE)
		for point_index in range(points_per_ring):
			var angle := (float(point_index) / float(points_per_ring)) * TAU + angle_offset
			var jittered_angle := angle + randf_range(
				-MATERIAL_RING_JITTER_ANGLE,
				MATERIAL_RING_JITTER_ANGLE
			)
			var radial_jitter := randf_range(-MATERIAL_RING_JITTER_RADIUS, MATERIAL_RING_JITTER_RADIUS)
			var center := bag_pos + Vector2(
				cos(jittered_angle) * (radius_x + radial_jitter),
				sin(jittered_angle) * (radius_y + radial_jitter * 0.55)
			)
			center = _push_center_from(center, bag_pos, MATERIAL_MIN_BAG_DISTANCE)
			center = _pull_center_to_radius(center, bag_pos, MATERIAL_MAX_BAG_DISTANCE)
			center = _clamp_material_center(center, zone_size)
			candidates.append({
				"center": center,
				"angle": angle,
				"ring": ring_index,
			})
	return candidates


func _pick_material_candidate(
	candidates: Array[Dictionary],
	occupied_centers: Array[Vector2],
	target_angle: float
) -> Vector2:
	var best_center := Vector2.ZERO
	var best_score := INF
	var fallback_center := Vector2.ZERO
	var fallback_score := -INF
	for candidate: Dictionary in candidates:
		var center := candidate["center"] as Vector2
		var min_gap := _min_material_gap(center, occupied_centers)
		var angle := float(candidate["angle"])
		var ring := int(candidate["ring"])
		var angle_score := absf(wrapf(angle - target_angle, -PI, PI))
		var score := angle_score + float(ring) * 0.32 - min_gap * 0.001
		if min_gap > fallback_score:
			fallback_score = min_gap
			fallback_center = center
		if _material_rect_overlaps(center, occupied_centers):
			continue
		if score < best_score:
			best_score = score
			best_center = center
	if best_score < INF:
		return best_center
	return fallback_center


func _material_rect_overlaps(center: Vector2, occupied_centers: Array[Vector2]) -> bool:
	for other_center: Vector2 in occupied_centers:
		if absf(center.x - other_center.x) < MATERIAL_WRAPPER_SIZE \
				and absf(center.y - other_center.y) < MATERIAL_WRAPPER_SIZE:
			return true
	return false


func _min_material_gap(center: Vector2, occupied_centers: Array[Vector2]) -> float:
	if occupied_centers.is_empty():
		return INF
	var min_gap := INF
	for other_center: Vector2 in occupied_centers:
		min_gap = minf(min_gap, center.distance_to(other_center))
	return min_gap


func _push_center_from(center: Vector2, other_center: Vector2, min_distance: float) -> Vector2:
	var delta := center - other_center
	var distance := delta.length()
	if distance >= min_distance:
		return center
	if distance <= 0.01:
		delta = Vector2.RIGHT
		distance = 1.0
	return center + delta.normalized() * (min_distance - distance)


func _clamp_material_center(center: Vector2, zone_size: Vector2) -> Vector2:
	var half_size := MATERIAL_WRAPPER_SIZE * 0.5
	return Vector2(
		clampf(center.x, half_size, maxf(half_size, zone_size.x - half_size)),
		clampf(center.y, half_size, maxf(half_size, zone_size.y - half_size))
	)


func _pull_center_to_radius(center: Vector2, origin: Vector2, max_distance: float) -> Vector2:
	var delta := center - origin
	var distance := delta.length()
	if distance <= max_distance:
		return center
	if distance <= 0.01:
		return origin + Vector2.RIGHT * max_distance
	return origin + delta.normalized() * max_distance


func _get_material_launch_offset(index: int) -> Vector2:
	var direction := -1.0 if index % 2 == 0 else 1.0
	return Vector2(direction * randf_range(12.0, 28.0), randf_range(-8.0, 8.0))


func _on_material_hovered(icon: Control, is_hovered: bool) -> void:
	if icon == null or not is_instance_valid(icon):
		return
	var mat_id := String(icon.name)
	if bool(icon.get_meta("locked", false)):
		return
	if _remaining_inventory_count_for_material(mat_id) <= 0:
		return
	var tween := create_tween()
	tween.tween_property(
		icon,
		"scale",
		Vector2(1.1, 1.1) if is_hovered else Vector2.ONE,
		0.10
	)
	tween.parallel().tween_property(
		icon,
		"modulate",
		MATERIAL_HOVER_MODULATE if is_hovered else MATERIAL_AVAILABLE_MODULATE,
		0.10
	)


func _on_mat_clicked(event: InputEvent, mat_id: String) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if _remaining_inventory_count_for_material(mat_id) <= 0:
		return

	var required := weapon_data[current_weapon].get("required_quantity", 2) as int
	if selected_materials.size() >= required:
		return
	var slot_index := _next_empty_slot_index()
	if slot_index < 0:
		return
	var scatter_icon := _get_scatter_icon(mat_id)
	if scatter_icon == null:
		return

	selected_materials.append(mat_id)
	_slot_material_ids[slot_index] = mat_id
	_animate_material_to_slot(scatter_icon, slot_index, mat_id)

	_update_stat_preview()
	_print_slot_state()


func _remove_selected_material(mat_id: String) -> void:
	var index := selected_materials.find(mat_id)
	if index >= 0:
		selected_materials.remove_at(index)


func _selected_count_for_material(mat_id: String) -> int:
	var total := 0
	for selected_id: String in selected_materials:
		if selected_id == mat_id:
			total += 1
	return total


func _remaining_inventory_count_for_material(mat_id: String) -> int:
	return maxi(0, _inventory_count_for_material(mat_id) - _selected_count_for_material(mat_id))


func _update_nl_visual() -> void:
	_clear_slot_visuals()
	var required := weapon_data[current_weapon].get("required_quantity", 2) as int
	_rebuild_material_slots(required)
	for index in range(mini(selected_materials.size(), _slot_material_ids.size())):
		_slot_material_ids[index] = selected_materials[index]
		_set_slot_filled(index, selected_materials[index])

	for child in _nl_scatter_zone.get_children():
		var mat_id := String(child.name)
		var remaining := _remaining_inventory_count_for_material(mat_id)
		_refresh_material_count_badge(child as Control, remaining, remaining > 0)
		if remaining <= 0:
			child.visible = false
		elif _is_material_selectable(mat_id):
			child.visible = true
			child.modulate = MATERIAL_AVAILABLE_MODULATE
			child.scale = Vector2.ONE
		else:
			child.visible = true
			child.modulate = MATERIAL_UNAVAILABLE_MODULATE
			child.scale = Vector2.ONE
	_update_slot_counter()
	_sync_confirm_button_state()


func _layout_bottom_bar(viewport_size: Vector2) -> void:
	if _nl_bottom_bar == null:
		return
	var slot_count := maxi(1, _material_slots.size())
	var row_width := float(slot_count) * NL_SLOT_WRAP_SIZE.x
	row_width += float(slot_count - 1) * float(NL_SLOT_ROW_GAP)
	row_width = minf(row_width, viewport_size.x - 64.0)
	if _slot_row != null:
		_slot_row.position = Vector2((viewport_size.x - row_width) * 0.5, 8.0)
		_slot_row.size = Vector2(row_width, NL_SLOT_WRAP_SIZE.y)
	if _slot_counter != null:
		_slot_counter.position = Vector2(0.0, 130.0)
		_slot_counter.size = Vector2(viewport_size.x, 28.0)
	if _btn_confirm_nl != null:
		var button_size := Vector2(252.0, 54.0)
		_btn_confirm_nl.size = button_size
		_btn_confirm_nl.position = Vector2((viewport_size.x - button_size.x) * 0.5, 164.0)


func _rebuild_material_slots(required: int) -> void:
	if _slot_row == null:
		return
	required = maxi(required, 1)
	if _material_slots.size() == required:
		return
	for child in _slot_row.get_children():
		child.queue_free()
	_material_slots.clear()
	_slot_material_ids.clear()
	for index in range(required):
		var slot := _build_material_slot(index)
		_slot_row.add_child(slot)
		_material_slots.append(slot)
		_slot_material_ids.append("")
	var viewport_size := get_viewport_rect().size
	if viewport_size.x > 0.0:
		_layout_bottom_bar(viewport_size)


func _build_material_slot(index: int) -> Control:
	var slot := Control.new()
	slot.name = "Slot%d" % (index + 1)
	slot.custom_minimum_size = NL_SLOT_WRAP_SIZE
	slot.size = NL_SLOT_WRAP_SIZE
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.gui_input.connect(_on_slot_input.bind(index))

	var frame_pos := Vector2((NL_SLOT_WRAP_SIZE.x - NL_SLOT_SIZE) * 0.5, 0.0)

	var slot_bg := TextureRect.new()
	slot_bg.name                = "SlotBg"
	slot_bg.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
	slot_bg.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot_bg.custom_minimum_size = Vector2.ZERO
	slot_bg.texture             = load(NL_SLOT_IMG_EMPTY) as Texture2D
	slot_bg.position            = frame_pos
	slot_bg.size                = Vector2(NL_SLOT_SIZE, NL_SLOT_SIZE)
	slot_bg.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	slot.add_child(slot_bg)

	var frame := PanelContainer.new()
	frame.name = "SlotFrame"
	frame.position = frame_pos
	frame.size = Vector2(NL_SLOT_SIZE, NL_SLOT_SIZE)
	frame.modulate = Color(1, 1, 1, 1)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color.TRANSPARENT
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(frame)

	var fallback := ColorRect.new()
	fallback.name = "SlotFallback%d" % (index + 1)
	fallback.position = frame.position + Vector2(10.0, 10.0)
	fallback.size = Vector2(NL_SLOT_SIZE - 20.0, NL_SLOT_SIZE - 20.0)
	fallback.color = Color(0.77, 0.53, 0.35, 0.26)
	fallback.visible = false
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(fallback)

	var icon := TextureRect.new()
	icon.name = "SlotIcon%d" % (index + 1)
	icon.position = frame.position
	icon.size = Vector2(NL_SLOT_SIZE, NL_SLOT_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.visible = false
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)

	var label := Label.new()
	label.name = "SlotLabel%d" % (index + 1)
	label.position = Vector2(0.0, 84.0)
	label.size = Vector2(NL_SLOT_WRAP_SIZE.x, 32.0)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.96, 0.84, 0.60, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	slot.add_child(label)
	return slot


func _add_dashed_border(slot: Control, frame_pos: Vector2, frame_size: Vector2) -> void:
	var dash_len := 8.0
	var gap := 6.0
	var thickness := 2.0
	var top_count := int(frame_size.x / (dash_len + gap))
	var side_count := int(frame_size.y / (dash_len + gap))
	for index in range(top_count):
		var x := frame_pos.x + float(index) * (dash_len + gap)
		_add_dash(slot, Vector2(x, frame_pos.y), Vector2(dash_len, thickness))
		_add_dash(
			slot,
			Vector2(x, frame_pos.y + frame_size.y - thickness),
			Vector2(dash_len, thickness)
		)
	for index in range(side_count):
		var y := frame_pos.y + float(index) * (dash_len + gap)
		_add_dash(slot, Vector2(frame_pos.x, y), Vector2(thickness, dash_len))
		_add_dash(
			slot,
			Vector2(frame_pos.x + frame_size.x - thickness, y),
			Vector2(thickness, dash_len)
		)


func _add_dash(slot: Control, dash_pos: Vector2, dash_size: Vector2) -> void:
	var dash := ColorRect.new()
	dash.name = "Dash"
	dash.position = dash_pos
	dash.size = dash_size
	dash.color = NL_SLOT_EMPTY_COLOR
	dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(dash)


func _clear_slot_visuals() -> void:
	for index in range(_slot_material_ids.size()):
		_slot_material_ids[index] = ""
		_set_slot_empty(index)


func _reset_material_slots() -> void:
	_clear_slot_visuals()
	_update_slot_counter()
	_sync_confirm_button_state()


func _set_slot_empty(index: int) -> void:
	if index < 0 or index >= _material_slots.size():
		return
	var slot := _material_slots[index]
	var slot_bg := slot.get_node_or_null("SlotBg") as TextureRect
	if slot_bg != null:
		slot_bg.texture = load(NL_SLOT_IMG_EMPTY) as Texture2D
	var icon := slot.get_node_or_null("SlotIcon%d" % (index + 1)) as TextureRect
	if icon != null:
		icon.texture = null
		icon.visible = false
	var fallback := slot.get_node_or_null("SlotFallback%d" % (index + 1)) as ColorRect
	if fallback != null:
		fallback.visible = false
	var label := slot.get_node_or_null("SlotLabel%d" % (index + 1)) as Label
	if label != null:
		label.text = ""


func _set_slot_filled(index: int, mat_id: String) -> void:
	if index < 0 or index >= _material_slots.size():
		return
	if not material_data.has(mat_id):
		return
	var slot := _material_slots[index]
	var mat := material_data[mat_id] as Dictionary
	var slot_bg := slot.get_node_or_null("SlotBg") as TextureRect
	if slot_bg != null:
		slot_bg.texture = load(NL_SLOT_IMG_FILLED) as Texture2D
	var texture := _try_load(mat.get("icon", "") as String)
	var icon := slot.get_node_or_null("SlotIcon%d" % (index + 1)) as TextureRect
	if icon != null:
		icon.texture = texture
		icon.visible = texture != null
	var fallback := slot.get_node_or_null("SlotFallback%d" % (index + 1)) as ColorRect
	if fallback != null:
		fallback.visible = texture == null
	var label := slot.get_node_or_null("SlotLabel%d" % (index + 1)) as Label
	if label != null:
		label.text = mat["name"] as String


func _set_slot_dash_visible(slot: Control, is_visible: bool) -> void:
	for child in slot.get_children():
		if child.name == "Dash":
			child.visible = is_visible


func _next_empty_slot_index() -> int:
	for index in range(_slot_material_ids.size()):
		if String(_slot_material_ids[index]) == "":
			return index
	return -1


func _get_scatter_icon(mat_id: String) -> Control:
	if _nl_scatter_zone == null:
		return null
	return _nl_scatter_zone.get_node_or_null(mat_id) as Control


func _on_slot_input(event: InputEvent, slot_index: int) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if slot_index < 0 or slot_index >= _slot_material_ids.size():
		return
	var mat_id := String(_slot_material_ids[slot_index])
	if mat_id == "":
		return
	var scatter_icon := _get_scatter_icon(mat_id)
	_remove_selected_material(mat_id)
	_slot_material_ids[slot_index] = ""
	_animate_material_back_to_scatter(scatter_icon, slot_index, mat_id)
	_set_slot_empty(slot_index)
	_update_stat_preview()
	_print_slot_state()


func _animate_material_to_slot(scatter_icon: Control, slot_index: int, mat_id: String) -> void:
	var slot_icon := (
		_material_slots[slot_index].get_node_or_null("SlotIcon%d" % (slot_index + 1))
		as TextureRect
	)
	var clone := _build_material_fly_clone(mat_id)
	var should_hide_source := _remaining_inventory_count_for_material(mat_id) <= 0
	if slot_icon == null or clone == null:
		_set_slot_filled(slot_index, mat_id)
		_refresh_material_count_badge(
			scatter_icon,
			_remaining_inventory_count_for_material(mat_id),
			not should_hide_source
		)
		scatter_icon.visible = not should_hide_source
		return
	var from_pos := _state_nl.get_global_transform().affine_inverse() * scatter_icon.global_position
	var to_pos := _state_nl.get_global_transform().affine_inverse() * slot_icon.global_position
	clone.position = from_pos
	clone.z_index = MATERIAL_LAYER_Z + 50
	_state_nl.add_child(clone)
	_refresh_material_count_badge(
		scatter_icon,
		_remaining_inventory_count_for_material(mat_id),
		not should_hide_source
	)
	scatter_icon.visible = not should_hide_source
	var tween := create_tween()
	tween.tween_property(clone, "position", to_pos, 0.25).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(clone, "scale", Vector2(0.86, 0.86), 0.25)
	tween.tween_callback(
		func() -> void:
			if is_instance_valid(clone):
				clone.queue_free()
			_set_slot_filled(slot_index, mat_id)
			_pulse_slot(slot_index)
			_update_slot_counter()
			_sync_confirm_button_state()
	)


func _animate_material_back_to_scatter(
	scatter_icon: Control,
	slot_index: int,
	mat_id: String
) -> void:
	var slot_icon := (
		_material_slots[slot_index].get_node_or_null("SlotIcon%d" % (slot_index + 1))
		as TextureRect
	)
	var clone := _build_material_fly_clone(mat_id)
	if scatter_icon == null or slot_icon == null or clone == null:
		if scatter_icon != null:
			scatter_icon.visible = true
		return
	var from_pos := _state_nl.get_global_transform().affine_inverse() * slot_icon.global_position
	var to_pos := _state_nl.get_global_transform().affine_inverse() * scatter_icon.global_position
	clone.position = from_pos
	clone.scale = Vector2(0.86, 0.86)
	clone.z_index = MATERIAL_LAYER_Z + 50
	_state_nl.add_child(clone)
	var tween := create_tween()
	tween.tween_property(clone, "position", to_pos, 0.20).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(clone, "scale", Vector2.ONE, 0.20)
	tween.tween_callback(
		func() -> void:
			if is_instance_valid(clone):
				clone.queue_free()
			if is_instance_valid(scatter_icon):
				if scatter_icon.has_meta("scatter_position"):
					scatter_icon.position = scatter_icon.get_meta("scatter_position") as Vector2
				scatter_icon.visible = true
				scatter_icon.scale = Vector2.ONE
				scatter_icon.modulate = MATERIAL_AVAILABLE_MODULATE
				_refresh_material_count_badge(
					scatter_icon,
					_remaining_inventory_count_for_material(mat_id),
					true
				)
	)


func _build_material_fly_clone(mat_id: String) -> Control:
	if not material_data.has(mat_id):
		return null
	var mat := material_data[mat_id] as Dictionary
	var texture := _try_load(mat.get("icon", "") as String)
	if texture != null:
		var icon := TextureRect.new()
		icon.name = "MaterialFlyClone"
		icon.texture = texture
		icon.size = Vector2(NL_SLOT_SIZE, NL_SLOT_SIZE)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return icon
	var fallback := PanelContainer.new()
	fallback.name = "MaterialFlyClone"
	fallback.size = Vector2(NL_SLOT_SIZE, NL_SLOT_SIZE)
	fallback.add_theme_stylebox_override(
		"panel",
		_slot_style(true, _material_placeholder_color(mat["tier"] as int))
	)
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return fallback


func _pulse_slot(index: int) -> void:
	if index < 0 or index >= _material_slots.size():
		return
	var slot := _material_slots[index]
	slot.pivot_offset = slot.size * 0.5
	var tween := create_tween()
	tween.tween_property(slot, "scale", Vector2(1.15, 1.15), 0.10)
	tween.tween_property(slot, "scale", Vector2.ONE, 0.10)


func _update_slot_counter() -> void:
	if _slot_counter == null:
		return
	_slot_counter.text = "Đã chọn: %d / %d" % [
		selected_materials.size(),
		maxi(1, _slot_material_ids.size()),
	]


func _sync_confirm_button_state() -> void:
	if _btn_confirm_nl == null:
		return
	var required := maxi(1, _slot_material_ids.size())
	var is_complete := selected_materials.size() >= required
	_btn_confirm_nl.disabled = not is_complete
	if is_complete:
		_start_confirm_pulse()
	else:
		_stop_confirm_pulse()


func _start_confirm_pulse() -> void:
	if _btn_confirm_pulse_tween != null:
		return
	_btn_confirm_nl.pivot_offset = _btn_confirm_nl.size * 0.5
	_btn_confirm_pulse_tween = create_tween().set_loops()
	_btn_confirm_pulse_tween.tween_property(
		_btn_confirm_nl,
		"scale",
		Vector2(1.03, 1.03),
		0.75
	)
	_btn_confirm_pulse_tween.tween_property(
		_btn_confirm_nl,
		"scale",
		Vector2.ONE,
		0.75
	)


func _stop_confirm_pulse() -> void:
	if _btn_confirm_pulse_tween != null:
		_btn_confirm_pulse_tween.kill()
		_btn_confirm_pulse_tween = null
	if _btn_confirm_nl != null:
		_btn_confirm_nl.scale = Vector2.ONE


func _print_slot_state() -> void:
	print("ForgeBookUI: slot state ", _slot_material_ids)
	print("ForgeBookUI: PART 4 slot system completed")


func _update_stat_preview() -> void:
	if current_weapon == "" or not weapon_data.has(current_weapon):
		return
	var base := weapon_data[current_weapon] as Dictionary
	var total_atk := base["atk"] as int
	var total_speed := base["speed"] as int
	var total_def := base["def"] as int

	for mat_id: String in selected_materials:
		var mat := material_data[mat_id] as Dictionary
		total_atk += (mat["atk"] as int)
		total_speed += (mat["speed"] as int)
		total_def += (mat["def"] as int)

	_stat_preview_atk.text = "Công: " + str(total_atk)
	_stat_preview_spd.text = "Tốc: " + str(total_speed)
	_stat_preview_def.text = "Thủ: " + str(total_def)
	_update_slot_counter()
	_sync_confirm_button_state()


func _on_confirm_nl_pressed() -> void:
	print("ForgeBookUI: confirm materials")
	var total_atk := 0
	var total_def := 0
	var total_magic := 0
	var total_speed := 0
	var max_tier := 1
	var mat_names: Array = []
	var material_inventory_aliases := {}
	var union_elements: Array = []

	for mat_id: String in selected_materials:
		var mat := material_data[mat_id] as Dictionary
		total_atk += (mat["atk"] as int)
		total_def += (mat["def"] as int)
		total_magic += (mat["magic"] as int)
		total_speed += (mat["speed"] as int)
		max_tier = maxi(max_tier, mat["tier"] as int)
		mat_names.append(mat["name"])
		var mat_allowed: Array = mat.get("allowed_elements", [])
		for elem: String in mat_allowed:
			if elem not in union_elements:
				union_elements.append(elem)
		if not material_inventory_aliases.has(mat_id):
			material_inventory_aliases[mat_id] = _inventory_ids_for_material(mat_id)

	GameManager.selected_blank = _build_selected_blank(current_weapon)
	GameManager.selected_material = {
		"id": "combined_" + "_".join(selected_materials),
		"item_id": selected_materials[0] if not selected_materials.is_empty() else "",
		"material_ids": selected_materials.duplicate(),
		"material_inventory_aliases": material_inventory_aliases,
		"name": ", ".join(mat_names),
		"rarity": max_tier,
		"atk_bonus": total_atk,
		"def_bonus": total_def,
		"magic_bonus": total_magic,
		"speed_bonus": total_speed,
		"price_mult": 1.0,
		"phase1_min": "",
		"allowed_elements": union_elements,
	}
	GameManager.selected_element = ""

	forge_ready.emit(current_weapon, selected_materials.duplicate())
	print("Forge ready: ", current_weapon, selected_materials)
	get_tree().change_scene_to_file(PATH_ELEMENT_PICKER)


func _start_material_float(icon: Control, target_pos: Vector2, is_locked: bool) -> void:
	if not is_instance_valid(icon):
		return
	var float_offset := randf_range(4.0, 10.0)
	var float_time := randf_range(0.85, 1.25)
	var float_tween := create_tween().set_loops()
	float_tween.tween_property(
		icon,
		"position:y",
		target_pos.y - float_offset,
		float_time
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	float_tween.tween_property(
		icon,
		"position:y",
		target_pos.y + float_offset,
		float_time
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	var outline := icon.get_node_or_null("OutlineLayer") as Control
	if outline == null or is_locked:
		return
	var outline_tween := create_tween().set_loops()
	outline_tween.tween_property(outline, "modulate:a", 0.9, 0.55)
	outline_tween.tween_property(outline, "modulate:a", 0.25, 0.55)


func _build_material_icon(mat_id: String, mat: Dictionary, is_selectable: bool) -> Control:
	var icon_path := mat["icon"] as String
	var wrapper := Control.new()
	wrapper.name = mat_id
	wrapper.custom_minimum_size = Vector2(MATERIAL_WRAPPER_SIZE, MATERIAL_WRAPPER_SIZE)
	wrapper.size = Vector2(MATERIAL_WRAPPER_SIZE, MATERIAL_WRAPPER_SIZE)
	wrapper.mouse_filter = (
		Control.MOUSE_FILTER_STOP if is_selectable else Control.MOUSE_FILTER_IGNORE
	)
	wrapper.tooltip_text = mat["name"]

	var icon: Control
	var texture := load(icon_path) as Texture2D if ResourceLoader.exists(icon_path) else null
	var outline_color := _material_placeholder_color(mat["tier"] as int)
	if texture != null and is_selectable:
		_add_material_outline(wrapper, texture, outline_color)

	if ResourceLoader.exists(icon_path):
		var texture_icon := TextureRect.new()
		texture_icon.texture = texture
		texture_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		texture_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon = texture_icon
	else:
		icon = _build_material_placeholder(outline_color, not is_selectable)

	icon.name = "Icon"
	icon.position = Vector2(MATERIAL_ICON_INSET, MATERIAL_ICON_INSET)
	icon.custom_minimum_size = Vector2(MATERIAL_ICON_SIZE, MATERIAL_ICON_SIZE)
	icon.size = Vector2(MATERIAL_ICON_SIZE, MATERIAL_ICON_SIZE)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(icon)
	_add_material_count_badge(wrapper, _inventory_count_for_material(mat_id), is_selectable)
	if not is_selectable:
		wrapper.modulate = MATERIAL_UNAVAILABLE_MODULATE
	return wrapper


func _add_material_count_badge(
	wrapper: Control,
	count: int,
	is_selectable: bool
) -> void:
	_refresh_material_count_badge(wrapper, count, is_selectable)


func _refresh_material_count_badge(
	wrapper: Control,
	count: int,
	is_selectable: bool
) -> void:
	if wrapper == null or not is_instance_valid(wrapper):
		return
	var badge := wrapper.get_node_or_null("CountBadge") as Label
	if count <= 1:
		if badge != null:
			badge.visible = false
		return
	if badge == null:
		badge = Label.new()
		wrapper.add_child(badge)
	badge.name = "CountBadge"
	badge.text = "x%d" % count
	badge.position = Vector2(MATERIAL_WRAPPER_SIZE - 72.0, MATERIAL_WRAPPER_SIZE - 58.0)
	badge.size = Vector2(64.0, 42.0)
	badge.visible = true
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 30)
	badge.add_theme_color_override(
		"font_color",
		Color(1.0, 0.94, 0.70, 1.0) if is_selectable else Color(0.72, 0.72, 0.72, 0.75)
	)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _add_material_outline(wrapper: Control, texture: Texture2D, color: Color) -> void:
	var outline_layer := Control.new()
	outline_layer.name = "OutlineLayer"
	outline_layer.size = wrapper.size
	outline_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outline_layer.modulate.a = 0.45
	wrapper.add_child(outline_layer)

	var offsets := [
		Vector2(-6, 0),
		Vector2(6, 0),
		Vector2(0, -6),
		Vector2(0, 6),
		Vector2(-4, -4),
		Vector2(4, -4),
		Vector2(-4, 4),
		Vector2(4, 4),
	]
	for offset: Vector2 in offsets:
		var outline_icon := TextureRect.new()
		outline_icon.texture = texture
		outline_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		outline_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		outline_icon.position = Vector2(MATERIAL_ICON_INSET, MATERIAL_ICON_INSET) + offset
		outline_icon.size = Vector2(MATERIAL_ICON_SIZE, MATERIAL_ICON_SIZE)
		outline_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		outline_icon.modulate = color
		outline_layer.add_child(outline_icon)


func _build_material_placeholder(color: Color, is_locked: bool) -> PanelContainer:
	var placeholder := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = color
	style.set_border_width_all(6 if not is_locked else 2)
	style.set_corner_radius_all(8)
	placeholder.add_theme_stylebox_override("panel", style)
	return placeholder


func _is_material_locked(mat_id: String) -> bool:
	if not material_data.has(mat_id):
		return false
	var mat := material_data[mat_id] as Dictionary
	var phoi_tier := weapon_data[current_weapon].get("required_tier", 1) as int
	return (mat["tier"] as int) < phoi_tier


func _is_material_selectable(mat_id: String) -> bool:
	if _is_material_locked(mat_id):
		return false
	return _inventory_count_for_material(mat_id) > 0


func _inventory_count_for_material(mat_id: String) -> int:
	if not material_data.has(mat_id):
		return 0
	var mat := material_data[mat_id] as Dictionary
	var accepted_ids := _inventory_ids_for_material(mat_id)
	var material_name := mat.get("name", "") as String
	var total := 0

	for entry: Dictionary in InventorySystem.get_materials():
		var entry_id := entry.get("item_id", "") as String
		var entry_name: String = entry.get(
			"material_name",
			entry.get("item_name", entry.get("name", ""))
		)
		if not accepted_ids.has(entry_id) and entry_name != material_name:
			continue
		total += int(entry.get("quantity", entry.get("amount", 1)))
	return total


func _inventory_ids_for_material(mat_id: String) -> Array[String]:
	var ids: Array[String] = [mat_id]
	var aliases: Array = MATERIAL_INVENTORY_ALIASES.get(mat_id, [])
	for alias in aliases:
		ids.append(alias as String)
	return ids


func _material_placeholder_color(tier: int) -> Color:
	match tier:
		1:
			return Color(0.80, 0.46, 0.18, 1.0)
		2:
			return Color(0.24, 0.76, 0.60, 1.0)
		3:
			return Color(0.74, 0.52, 1.0, 1.0)
		_:
			return Color(0.40, 0.34, 0.28, 1.0)


func _phoi_badge_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.89, 0.78, 0.90)
	style.border_color = Color("#C4885A")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style


func _slot_style(is_filled: bool, override_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = (
		Color(0.08, 0.04, 0.02, 0.48) if is_filled
		else Color(0.05, 0.03, 0.02, 0.34)
	)
	style.border_color = (
		override_color if override_color != Color.TRANSPARENT
		else NL_SLOT_FILLED_COLOR if is_filled
		else NL_SLOT_EMPTY_COLOR
	)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style


func _set_book_indicator_phase(phase: int) -> void:
	var indicator := get_node_or_null("ForgePhaseIndicator")
	if indicator == null:
		return
	indicator.set_phase(phase)
	move_child(indicator, get_child_count() - 1)


# ═══════════════════════════════════════════════════════════════
# CALLBACKS
# ═══════════════════════════════════════════════════════════════

func _update_weapon_content(weapon_id: String) -> void:
	var data := weapon_data[weapon_id] as Dictionary
	_weapon_sketch.texture = weapon_textures.get(weapon_id) as Texture2D
	_weapon_name.text = data["name"]
	_lbl_atk.text = "Công %s    Thủ %s" % [data["atk"], data["def"]]
	_lbl_spd.text = "Ma thuật %s    Tốc độ %s" % [data["magic"], data["speed"]]
	_lbl_dur.text = "Nguyên liệu cần: %s" % data["required_quantity"]
	_skill_name.text = "%s\n%s" % [_skill_display_name(data), data["skill_desc"]]


func _on_flip_finished(anim_name: StringName) -> void:
	if anim_name == "page_flip":
		print("page_flip end: %s" % current_weapon)


func _on_confirm_pressed() -> void:
	if current_weapon == "" or not weapon_data.has(current_weapon):
		return
	GameManager.selected_blank = _build_selected_blank(current_weapon)
	weapon_confirmed.emit(current_weapon)
	transition_to_nl_state()


func _on_back_pressed() -> void:
	if _is_nl_transitioning:
		return
	if _state_nl != null and _state_nl.visible:
		_return_to_weapon_step()
		return
	_go_to_workshop()


func _go_to_workshop() -> void:
	GameManager.selected_blank = {}
	GameManager.selected_material = {}
	GameManager.selected_element = ""
	GameManager.forge_return_to_material_step = false
	SceneManager.go_to(PATH_WORKSHOP)


# ═══════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════

func _try_load(path: String) -> Texture2D:
	if path == "":
		return null
	var texture := load(path) as Texture2D
	if texture:
		return texture
	return null


func _update_list_highlight(weapon_id: String) -> void:
	for btn: Button in _weapon_buttons.values():
		if btn.name == weapon_id:
			btn.add_theme_stylebox_override("normal", _logo_selected_style())
		else:
			btn.add_theme_stylebox_override("normal", _logo_button_style(false))


func _highlighted_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#C97B2033")
	style.border_color = Color("#C97B20")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _logo_button_style(is_hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.78, 0.61, 0.36, 0.10 if not is_hovered else 0.22)
	style.border_color = Color(0.45, 0.24, 0.10, 0.18 if not is_hovered else 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _logo_selected_style() -> StyleBoxFlat:
	var style := _logo_button_style(true)
	style.bg_color = Color("#C97B2033")
	style.border_color = Color("#E8612A")
	style.set_border_width_all(2)
	return style


func _skill_box_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.80, 0.58, 0.28, 0.18)
	style.border_color = Color(0.45, 0.25, 0.09, 0.30)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _confirm_button_style(is_hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.78, 0.48, 0.18, 0.70 if not is_hovered else 0.86)
	style.border_color = Color(0.38, 0.18, 0.04, 0.70)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _find_png(folder_path: String, prefix: String) -> String:
	for file_name in DirAccess.get_files_at(folder_path):
		if file_name.begins_with(prefix) and file_name.get_extension().to_lower() == "png":
			return folder_path + file_name
	return ""


func _find_book_cover_path() -> String:
	for file_name in DirAccess.get_files_at(PATH_BOOK):
		if file_name.get_extension().to_lower() != "png":
			continue
		if not file_name.begins_with("Trang"):
			return PATH_BOOK + file_name
	return ""


func _weapon_asset_path(kind: String, file_name: String) -> String:
	var dir_path := PATH_WEAPONS + "Logo/"
	if kind == "prototype":
		dir_path = _prototype_dir_path()
	return dir_path + file_name


func _prototype_dir_path() -> String:
	for dir_name in DirAccess.get_directories_at(PATH_WEAPONS):
		if dir_name != "Logo" and dir_name != "icons":
			return PATH_WEAPONS + dir_name + "/"
	return PATH_WEAPONS


func _build_selected_blank(weapon_id: String) -> Dictionary:
	var data := weapon_data[weapon_id] as Dictionary
	return {
		"id": weapon_id,
		"name": data["name"],
		"atk": data["atk"],
		"def": data["def"],
		"magic": data["magic"],
		"speed": data["speed"],
		"skill": data["skill"],
		"skill_name": _skill_display_name(data),
		"skill_desc": data["skill_desc"],
		"customers": data["customers"],
		"required_tier": data["required_tier"],
		"required_quantity": data["required_quantity"],
		"sprite_path": _weapon_asset_path("prototype", String(data.get("asset", "")) + ".png"),
	}


func _skill_display_name(data: Dictionary) -> String:
	return data.get("skill_name", data.get("skill", "")) as String
