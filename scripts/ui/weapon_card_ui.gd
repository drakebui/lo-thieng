# gdlint: disable=max-file-lines
# Reusable weapon card UI — hiển thị kết quả vũ khí sau khi rèn (bố cục 2 cột 32-bit Hoả Tâm)
# setup(weapon_data) để cập nhật nội dung:
#   phase1_tier, phase2_prefix, element, suffix, element_name, element_color
#   weapon_type, base_atk, base_def, base_magic, base_speed, sprite_path
#   innate_skill, innate_skill_desc, perfect_quench, price_mult, durability_bonus
extends Control

signal shelf_saved(result: Dictionary)
signal warehouse_saved(result: Dictionary)

const _FORGE_CONVERTER := preload("res://scripts/forge/weapon_data.gd")

const CARD_WIDTH := 1160.0
const CARD_HEIGHT := 680.0

const _PEDESTAL_TEX_PATH := "res://assets/pixel/ui/forge/weapon_pedestal_160x160.png"
const _ELEMENT_SEALS_PATH := "res://assets/pixel/ui/forge/element_seals_sheet_64.png"
const _QUALITY_CREST_PATH := "res://assets/pixel/ui/forge/quality_crest_sheet_48.png"

const PHASE1_TIER_NAMES := {
	"lanh": "Lạnh (−30%)",
	"cam": "Cam (+20%)",
	"do_ruc": "Đỏ Rực (+40%)",
	"vang_kim": "Vàng Kim (+40%)",
	"chay": "Cháy Thép (−50%)",
}
const PHASE1_TIER_COLORS := {
	"lanh": Color(0.68, 0.84, 1.0),
	"cam": Color(1.0, 0.76, 0.36),
	"do_ruc": Color(1.0, 0.62, 0.24),
	"vang_kim": Color(1.0, 0.88, 0.40),
	"chay": Color(0.96, 0.46, 0.38),
}
const ELEMENT_SEAL_INDEX := {
	"hoa": 0,
	"bang": 1,
	"set": 2,
	"tho": 3,
	"phong": 4,
	"hu_khong": 5,
}
const SUFFIX_TO_ELEMENT := {
	"thieu_dot": "hoa",
	"bang_gia": "bang",
	"sam_set": "set",
	"dao_dong": "tho",
	"cuong_phong": "phong",
	"hu_khong": "hu_khong",
}
const QUALITY_CREST_INDEX := {
	"phan_chu": 0,
	"curse_nang": 0,
	"curse_nhe": 0,
	"thuong": 1,
	"tot": 2,
	"nang_tay": 2,
	"than_toc": 2,
	"kiet_tac": 3,
	"can_bang": 3,
	"to_nghe": 3,
	"huyen_bi": 3,
	"cung_nhu_da": 3,
	"khi_phach": 3,
	"truong_sinh": 4,
	"perfect": 4,
}
const RARITY_TITLE_COLORS := {
	1: Color(0.96, 0.50, 0.42),   # Bị nguyền (đỏ san hô sáng, tương phản cao)
	2: Color(0.95, 0.90, 0.78),   # Phổ thông / Tốt (ngà sáng)
	3: Color(1.00, 0.83, 0.40),   # Kiệt Tác / Tổ Nghề (vàng hổ phách)
	4: Color(0.66, 0.92, 1.00),   # Cứng Như Đá / Khí Phách (lam sáng)
	5: Color(1.00, 0.95, 0.62),   # Hào Kiệt / Trường Sinh (vàng kem rực)
}
const PREFIX_SKILL_DESCS := {
	"thuong": "Chém bén gây 1.5× Công",
	"tot": "Dựng tường sắt +5 Thủ trong 2 lượt",
	"nang_tay": "Đòn đập 2.0× Công, mất lượt sau",
	"than_toc": "Chém liên hoàn 2 nhát (1.0× mỗi nhát)",
	"kiet_tac": "Gây 1.3× Công và hồi +10 Máu",
	"can_bang": "Tăng +15% mọi chỉ số trong 2 lượt",
	"to_nghe": "Gây 1.25× Công, thưởng +50G khi thắng",
	"huyen_bi": "Đòn chém tính theo chỉ số Phép",
	"cung_nhu_da": "Hóa đá miễn hoàn toàn 1 đòn đánh",
	"khi_phach": "Hét uy áp giảm −1 Công địch 3 lượt",
	"truong_sinh": "Nội tại: không hao Độ bền trong trận",
	"perfect": "Gây 1.5× Công, +1 Tiếng tăm khi thắng",
	"curse_nhe": "Chém yếu hơn chuẩn (1.2× Công)",
}
const SUFFIX_SKILL_DESCS := {
	"thieu_dot": "1.0× Công + Cháy 2 lượt (4/lượt)",
	"bang_gia": "0.8× Công + 50% đóng băng 1 lượt",
	"sam_set": "1.0× Công, xuyên 50% Thủ địch",
	"dao_dong": "0.6× Công + trúng Độc 3 lượt",
	"cuong_phong": "1.0× Công + xúc xắc 1–6 sát thương",
	"hu_khong": "1.0× Công, xuyên 100% Thủ địch",
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
	"quan_binh": "Quan Binh",
	"ba_hac_nguyet": "Bà Trùm Hắc Nguyệt",
	"co_long_gio": "Cô Lộng Gió",
	"nguoi_thu_no": "Người Thu Nợ",
}

const _DEFAULT_ATK := 12
const _DEFAULT_DEF := 0
const _DEFAULT_MAGIC := 3

# Dữ liệu vũ khí hiện tại & cờ trạng thái
var _current_data: Dictionary = {}
var _matched_customer_name: String = ""
var _is_perfect_quench: bool = false
var _is_built: bool = false
var _glow_active: bool = false
var _pulse_time: float = 0.0

# Texture sheets dùng chung
var _element_seals_tex: Texture2D = null
var _quality_crest_tex: Texture2D = null

# Nodes cần cập nhật từ setup()
var _card_panel: PanelContainer
var _pedestal_rect: TextureRect
var _weapon_sprite_rect: TextureRect
var _quality_crest_rect: TextureRect
var _quality_badge_label: Label
var _element_seal_rect: TextureRect
var _element_badge_label: Label
var _p1_summary_val: Label
var _p2_summary_val: Label
var _p3_summary_val: Label
var _name_label: Label
var _subtitle_label: Label
var _banners_row: HBoxContainer
var _perfect_badge_panel: PanelContainer
var _commission_banner_panel: PanelContainer
var _commission_banner_label: Label
var _atk_val: Label
var _def_val: Label
var _magic_val: Label
var _spd_val: Label
var _innate_skill_label: Label
var _prefix_skill_label: Label
var _suffix_skill_label: Label
var _durability_label: Label
var _price_label: Label


func _ready() -> void:
	theme = preload("res://assets/fonts/hoa_tam_pixel_theme.tres")
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	_build()

	if get_parent() == get_tree().root or get_parent() is SubViewport:
		setup({
			"phase1_tier": "do_ruc",
			"phase2_prefix": "kiet_tac",
			"element": "hoa",
			"suffix": "thieu_dot",
			"element_name": "Hỏa",
			"element_color": Color(1.0, 0.32, 0.05),
			"weapon_type": "Kiếm Đơn",
			"material_name": "Sắt Thô",
			"base_atk": 12,
			"base_def": 0,
			"base_magic": 3,
			"base_speed": 6,
			"innate_skill": "Trảm Chuẩn",
			"innate_skill_desc": "1.15× ATK sát thương ổn định",
			"perfect_quench": true,
		})


func _process(delta: float) -> void:
	if not _glow_active:
		return
	_pulse_time += delta
	var wave: float = 0.5 + 0.5 * sin(_pulse_time * 3.0)
	if _pedestal_rect != null:
		var boost: float = lerpf(1.0, 1.12, wave)
		_pedestal_rect.self_modulate = Color(boost, lerpf(0.98, 1.06, wave), lerpf(0.94, 0.88, wave), 1.0)
	if _weapon_sprite_rect != null:
		_weapon_sprite_rect.position.y = sin(_pulse_time * 2.4) * 3.0


func _build() -> void:
	if _is_built:
		return
	_is_built = true

	if ResourceLoader.exists(_ELEMENT_SEALS_PATH):
		_element_seals_tex = load(_ELEMENT_SEALS_PATH) as Texture2D
	if ResourceLoader.exists(_QUALITY_CREST_PATH):
		_quality_crest_tex = load(_QUALITY_CREST_PATH) as Texture2D

	# Khung thép rèn đinh tán đồng 32-bit nguyên vẹn 4 góc (không vẽ dải đè góc đồng)
	_card_panel = PanelContainer.new()
	_card_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_card_panel.add_theme_stylebox_override("panel", HoaTamUI.make_forged_steel_style(24.0))
	add_child(_card_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 26)
	add_child(margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(columns)

	_build_left_column(columns)
	_build_right_column(columns)


func _build_left_column(parent: HBoxContainer) -> void:
	var left_col := VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(360.0, 0.0)
	left_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_col.alignment = BoxContainer.ALIGNMENT_CENTER
	left_col.add_theme_constant_override("separation", 14)
	parent.add_child(left_col)

	# 1. Bệ trưng bày 32-bit + Ảnh vũ khí lớn sắc nét (Hero Element)
	var stage_center := CenterContainer.new()
	stage_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.add_child(stage_center)

	var stage_box := Control.new()
	stage_box.custom_minimum_size = Vector2(288.0, 288.0)
	stage_center.add_child(stage_box)

	_pedestal_rect = TextureRect.new()
	_pedestal_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pedestal_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_pedestal_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pedestal_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(_PEDESTAL_TEX_PATH):
		_pedestal_rect.texture = load(_PEDESTAL_TEX_PATH) as Texture2D
	stage_box.add_child(_pedestal_rect)

	var weapon_holder := Control.new()
	weapon_holder.position = Vector2(40.0, 40.0)
	weapon_holder.size = Vector2(208.0, 208.0)
	stage_box.add_child(weapon_holder)

	_weapon_sprite_rect = TextureRect.new()
	_weapon_sprite_rect.position = Vector2.ZERO
	_weapon_sprite_rect.size = Vector2(208.0, 208.0)
	_weapon_sprite_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_weapon_sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_weapon_sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	weapon_holder.add_child(_weapon_sprite_rect)

	# 2. Hàng 2 Huy hiệu có tên rõ (Phẩm chất & Nguyên tố)
	var badge_row := HBoxContainer.new()
	badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_row.add_theme_constant_override("separation", 10)
	left_col.add_child(badge_row)

	var q_pill := _make_badge_pill()
	badge_row.add_child(q_pill)
	_quality_crest_rect = q_pill.get_node("HBox/Icon") as TextureRect
	_quality_badge_label = q_pill.get_node("HBox/Label") as Label

	var e_pill := _make_badge_pill()
	badge_row.add_child(e_pill)
	_element_seal_rect = e_pill.get_node("HBox/Icon") as TextureRect
	_element_badge_label = e_pill.get_node("HBox/Label") as Label

	# 3. Bảng tổng kết 3 pha tay nghề (giải thích ngay kết quả rèn)
	var summary_panel := PanelContainer.new()
	summary_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_panel.add_theme_stylebox_override(
		"panel", HoaTamUI.make_inset_surface_style(0.68, 12.0, Color(0.46, 0.35, 0.22, 0.72))
	)
	left_col.add_child(summary_panel)

	var sum_vb := VBoxContainer.new()
	sum_vb.add_theme_constant_override("separation", 6)
	summary_panel.add_child(sum_vb)

	_p1_summary_val = _add_summary_row(sum_vb, "Nung lửa:")
	_p2_summary_val = _add_summary_row(sum_vb, "Đập búa:")
	_p3_summary_val = _add_summary_row(sum_vb, "Tôi luyện:")


func _make_badge_pill() -> PanelContainer:
	var pill := PanelContainer.new()
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill.add_theme_stylebox_override(
		"panel", HoaTamUI.make_inset_surface_style(0.62, 8.0, Color(0.48, 0.36, 0.22, 0.75))
	)

	var hb := HBoxContainer.new()
	hb.name = "HBox"
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 8)
	pill.add_child(hb)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(36.0, 36.0)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(icon)

	var lbl := Label.new()
	lbl.name = "Label"
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", HoaTamUI.COL_PARCHMENT)
	lbl.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	lbl.add_theme_constant_override("outline_size", 3)
	hb.add_child(lbl)

	return pill


func _add_summary_row(parent: VBoxContainer, caption: String) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var k_lbl := Label.new()
	k_lbl.text = caption
	k_lbl.add_theme_font_size_override("font_size", 18)
	k_lbl.add_theme_color_override("font_color", Color(0.72, 0.66, 0.56))
	row.add_child(k_lbl)

	var v_lbl := Label.new()
	v_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.add_theme_font_size_override("font_size", 18)
	v_lbl.add_theme_color_override("font_color", HoaTamUI.COL_PARCHMENT)
	v_lbl.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	v_lbl.add_theme_constant_override("outline_size", 3)
	row.add_child(v_lbl)
	return v_lbl


func _build_right_column(parent: HBoxContainer) -> void:
	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 12)
	parent.add_child(right_col)

	# 1. Tiêu đề tên vũ khí (độ tương phản cao) + dòng phụ chất liệu
	var header_vb := VBoxContainer.new()
	header_vb.add_theme_constant_override("separation", 4)
	right_col.add_child(header_vb)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 40)
	_name_label.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	_name_label.add_theme_constant_override("outline_size", 5)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_vb.add_child(_name_label)

	_subtitle_label = Label.new()
	_subtitle_label.add_theme_font_size_override("font_size", 20)
	_subtitle_label.add_theme_color_override("font_color", Color(0.80, 0.74, 0.62))
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_vb.add_child(_subtitle_label)

	# 2. Dải huy hiệu nổi bật (Tôi Hoàn Hảo / Khớp Đơn Hàng — chỉ hiện khi có)
	_banners_row = HBoxContainer.new()
	_banners_row.add_theme_constant_override("separation", 10)
	_banners_row.visible = false
	right_col.add_child(_banners_row)

	_perfect_badge_panel = _make_highlight_banner(
		"★ TÔI HOÀN HẢO (+10% Giá · +10 Bền)",
		Color(0.24, 0.17, 0.05, 0.94),
		HoaTamUI.COL_GOLD,
		Color(1.0, 0.94, 0.56),
		19
	)
	_perfect_badge_panel.visible = false
	_banners_row.add_child(_perfect_badge_panel)

	_commission_banner_panel = PanelContainer.new()
	var comm_style := HoaTamUI.make_inset_surface_style(0.92, 8.0, HoaTamUI.COL_JADE)
	comm_style.bg_color = Color(0.08, 0.22, 0.18, 0.94)
	_commission_banner_panel.add_theme_stylebox_override("panel", comm_style)
	_commission_banner_panel.visible = false
	_banners_row.add_child(_commission_banner_panel)

	_commission_banner_label = Label.new()
	_commission_banner_label.add_theme_font_size_override("font_size", 19)
	_commission_banner_label.add_theme_color_override("font_color", Color(0.62, 0.98, 0.82))
	_commission_banner_panel.add_child(_commission_banner_label)

	# 3. 4 Ô chỉ số có Icon 32-bit rõ ràng (CÔNG / THỦ / PHÉP / TỐC)
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 10)
	right_col.add_child(stats_row)

	_atk_val = _add_stat_block(stats_row, "CÔNG", HoaTamUI.HudIcon.ATK, Color(0.98, 0.52, 0.40))
	_def_val = _add_stat_block(stats_row, "THỦ", HoaTamUI.HudIcon.DEF, Color(0.48, 0.80, 0.98))
	_magic_val = _add_stat_block(stats_row, "PHÉP", HoaTamUI.HudIcon.MAG, Color(0.84, 0.62, 0.98))
	_spd_val = _add_stat_block(stats_row, "TỐC", HoaTamUI.HudIcon.SPD, Color(0.54, 0.94, 0.66))

	# 4. Khối 3 Kỹ năng thực chiến (Bẩm sinh + Chiêu Rèn + Chiêu Linh Lực)
	var skills_panel := PanelContainer.new()
	skills_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	skills_panel.add_theme_stylebox_override(
		"panel", HoaTamUI.make_inset_surface_style(0.66, 14.0, Color(0.45, 0.34, 0.22, 0.72))
	)
	right_col.add_child(skills_panel)

	var skills_vb := VBoxContainer.new()
	skills_vb.add_theme_constant_override("separation", 12)
	skills_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	skills_panel.add_child(skills_vb)

	var skills_heading := Label.new()
	skills_heading.text = "KỸ NĂNG THỰC CHIẾN"
	skills_heading.add_theme_font_size_override("font_size", 16)
	skills_heading.add_theme_color_override("font_color", HoaTamUI.COL_BRASS)
	skills_vb.add_child(skills_heading)

	_innate_skill_label = _make_skill_line(skills_vb, Color(0.94, 0.90, 0.80))
	skills_vb.add_child(_make_divider(Color(0.36, 0.30, 0.24, 0.55)))
	_prefix_skill_label = _make_skill_line(skills_vb, Color(1.0, 0.86, 0.48))
	skills_vb.add_child(_make_divider(Color(0.36, 0.30, 0.24, 0.55)))
	_suffix_skill_label = _make_skill_line(skills_vb, Color(0.76, 0.88, 0.98))

	# 5. Chân thẻ: Độ bền (trái) & Định giá Xưởng kèm đồng vàng (phải)
	var footer_panel := PanelContainer.new()
	footer_panel.add_theme_stylebox_override(
		"panel", HoaTamUI.make_inset_surface_style(0.72, 12.0, Color(0.58, 0.44, 0.24, 0.78))
	)
	right_col.add_child(footer_panel)

	var footer_hb := HBoxContainer.new()
	footer_hb.add_theme_constant_override("separation", 12)
	footer_panel.add_child(footer_hb)

	_durability_label = Label.new()
	_durability_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_durability_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_durability_label.add_theme_font_size_override("font_size", 22)
	_durability_label.add_theme_color_override("font_color", Color(0.84, 0.80, 0.70))
	footer_hb.add_child(_durability_label)

	var price_hb := HBoxContainer.new()
	price_hb.alignment = BoxContainer.ALIGNMENT_END
	price_hb.add_theme_constant_override("separation", 8)
	footer_hb.add_child(price_hb)

	var gold_icon := HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(HoaTamUI.HudIcon.GOLD), 28)
	gold_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	price_hb.add_child(gold_icon)

	_price_label = Label.new()
	_price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_price_label.add_theme_font_size_override("font_size", 30)
	_price_label.add_theme_color_override("font_color", Color(1.0, 0.87, 0.34))
	_price_label.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	_price_label.add_theme_constant_override("outline_size", 4)
	price_hb.add_child(_price_label)


func _make_skill_line(parent: VBoxContainer, col: Color) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(lbl)
	return lbl


func _make_highlight_banner(
	text_val: String,
	bg_col: Color,
	border_col: Color,
	font_col: Color,
	font_sz: int
) -> PanelContainer:
	var panel := PanelContainer.new()
	var s := HoaTamUI.make_inset_surface_style(bg_col.a, 8.0, border_col)
	s.bg_color = bg_col
	panel.add_theme_stylebox_override("panel", s)

	var lbl := Label.new()
	lbl.text = text_val
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.add_theme_color_override("font_color", font_col)
	panel.add_child(lbl)
	return panel


func _make_divider(color: Color) -> Control:
	var rect := ColorRect.new()
	rect.color = color
	rect.custom_minimum_size = Vector2(0.0, 2.0)
	return rect


func _add_stat_block(
	parent: HBoxContainer,
	stat_name: String,
	icon_id: HoaTamUI.HudIcon,
	color: Color
) -> Label:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s := HoaTamUI.make_inset_surface_style(
		0.66, 10.0, Color(color.r * 0.58, color.g * 0.58, color.b * 0.58, 0.62)
	)
	card.add_theme_stylebox_override("panel", s)
	parent.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	card.add_child(vb)

	var top_hb := HBoxContainer.new()
	top_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hb.add_theme_constant_override("separation", 6)
	vb.add_child(top_hb)

	var icon := HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(icon_id), 22)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_hb.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = stat_name
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", Color(0.80, 0.74, 0.64))
	top_hb.add_child(name_lbl)

	var val := Label.new()
	val.text = "—"
	val.add_theme_font_size_override("font_size", 36)
	val.add_theme_color_override("font_color", color)
	val.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	val.add_theme_constant_override("outline_size", 4)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(val)

	return val


func _make_atlas_icon(sheet: Texture2D, idx: int, cell_size: int) -> AtlasTexture:
	if sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(float(idx * cell_size), 0.0, float(cell_size), float(cell_size))
	return atlas


func _resolve_weapon_sprite_path(data: Dictionary) -> String:
	var sp: String = String(data.get("sprite_path", ""))
	if sp.is_empty() and GameManager != null and not GameManager.selected_blank.is_empty():
		sp = String(GameManager.selected_blank.get("sprite_path", ""))
	if sp.is_empty() and ResourceLoader.exists("res://assets/pixel/sprites/weapons/kiem_don.png"):
		sp = "res://assets/pixel/sprites/weapons/kiem_don.png"
	return sp


# ══════════════════════════════════════════════════════════════════════════════
# SETUP — cập nhật nội dung từ kết quả rèn
# ══════════════════════════════════════════════════════════════════════════════

func setup(data: Dictionary) -> void:
	if not _is_built:
		_build()

	_current_data = data
	var tier_key: String = data.get("phase1_tier", "cam")
	var prefix_key: String = data.get("phase2_prefix", "thuong")
	var suffix_key: String = data.get("suffix", "")
	var elem_key: String = String(data.get("element", "")).to_lower()
	if elem_key.is_empty() and not suffix_key.is_empty():
		elem_key = SUFFIX_TO_ELEMENT.get(suffix_key, "")
	var elem_color: Color = data.get("element_color", Color(0.54, 0.78, 0.90))
	var elem_bright := elem_color.lightened(0.45)
	var elem_name: String = String(data.get("element_name", ""))
	var weapon_type: String = data.get("weapon_type", "Vũ Khí")
	var innate_skill: String = data.get("innate_skill", "")
	var innate_desc: String = data.get("innate_skill_desc", "")
	var base_atk: int = data.get("base_atk", _DEFAULT_ATK)
	var base_def: int = data.get("base_def", _DEFAULT_DEF)
	var base_magic: int = data.get("base_magic", _DEFAULT_MAGIC)
	var base_speed: int = data.get("base_speed", 5)

	var prefix_name: String = _FORGE_CONVERTER.PREFIX_NAMES.get(prefix_key, prefix_key)
	var tier_name: String = PHASE1_TIER_NAMES.get(tier_key, tier_key)
	var material_name: String = String(data.get("material_name", ""))

	_is_perfect_quench = bool(data.get("perfect_quench", false))
	var price_mult: float = float(data.get("price_mult", 1.10 if _is_perfect_quench else 1.0))
	var dur_bonus: int = int(data.get("durability_bonus", 10 if _is_perfect_quench else 0))
	var base_dur: int = int(data.get("durability", 50))
	var max_dur: int = base_dur + dur_bonus

	# 1 nguồn tính chỉ số & giá bán duy nhất từ ForgeConverter (scripts/forge/weapon_data.gd)
	var mult: float = _FORGE_CONVERTER.P1_MULTIPLIERS.get(tier_key, 1.0)
	var bonus: int = _FORGE_CONVERTER.PHASE2_BONUS.get(prefix_key, 0)
	var atk: int = maxi(1, int(base_atk * mult) + bonus)
	var def_v: int = maxi(0, int(base_def * mult))
	var magic: int = maxi(0, int(base_magic * mult) + bonus)
	var spd: int = base_speed

	var rar_tier: int = _FORGE_CONVERTER.PREFIX_RARITY.get(prefix_key, 2)
	var sell_val := _FORGE_CONVERTER.weapon_sell_value(atk, magic, spd, rar_tier, price_mult)
	var price_min := int(sell_val * 0.85)
	var price_max := int(sell_val * 1.15)
	var title_col: Color = RARITY_TITLE_COLORS.get(rar_tier, HoaTamUI.COL_PARCHMENT)

	# Kiểm tra khớp đơn hàng với CommissionSystem
	_matched_customer_name = ""
	if CommissionSystem != null:
		var check_data := data.duplicate()
		check_data["rarity_tier"] = rar_tier
		if String(check_data.get("blank_id", "")).is_empty() and GameManager != null:
			if not GameManager.selected_blank.is_empty():
				check_data["blank_id"] = GameManager.selected_blank.get(
					"blank_id", GameManager.selected_blank.get("id", "")
				)
		for c in CommissionSystem.get_active():
			if WeaponSpec.satisfies(check_data, c):
				_matched_customer_name = NPC_DISPLAY_NAMES.get(c.giver_npc_id, c.giver_npc_id)
				break

	# Cột trái: Ảnh vũ khí + 2 Huy hiệu có chữ + Tổng kết 3 pha
	var sprite_path := _resolve_weapon_sprite_path(data)
	if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
		_weapon_sprite_rect.texture = load(sprite_path) as Texture2D
	else:
		_weapon_sprite_rect.texture = null
	_weapon_sprite_rect.position.y = 0.0

	var crest_idx: int = QUALITY_CREST_INDEX.get(prefix_key, 1)
	_quality_crest_rect.texture = _make_atlas_icon(_quality_crest_tex, crest_idx, 48)
	_quality_badge_label.text = prefix_name
	_quality_badge_label.add_theme_color_override("font_color", title_col)

	if ELEMENT_SEAL_INDEX.has(elem_key):
		var seal_idx: int = ELEMENT_SEAL_INDEX[elem_key]
		_element_seal_rect.visible = true
		_element_seal_rect.texture = _make_atlas_icon(_element_seals_tex, seal_idx, 64)
		_element_badge_label.text = elem_name
		_element_badge_label.add_theme_color_override("font_color", elem_bright)
	else:
		_element_seal_rect.visible = false
		_element_seal_rect.texture = null
		_element_badge_label.text = "Nước Thuần"
		_element_badge_label.add_theme_color_override("font_color", Color(0.68, 0.86, 0.94))

	_p1_summary_val.text = tier_name
	_p1_summary_val.add_theme_color_override(
		"font_color", PHASE1_TIER_COLORS.get(tier_key, HoaTamUI.COL_PARCHMENT)
	)
	var bonus_str := (" (+%d)" % bonus) if bonus > 0 else ((" (%d)" % bonus) if bonus < 0 else "")
	_p2_summary_val.text = "%s%s" % [prefix_name, bonus_str]
	_p2_summary_val.add_theme_color_override("font_color", title_col)
	if _is_perfect_quench:
		_p3_summary_val.text = "★ Hoàn Hảo"
		_p3_summary_val.add_theme_color_override("font_color", Color(1.0, 0.92, 0.44))
	else:
		_p3_summary_val.text = "Tiêu chuẩn"
		_p3_summary_val.add_theme_color_override("font_color", Color(0.76, 0.72, 0.64))

	# Nhịp sáng tinh tế khi phẩm chất cao (>= Kiệt Tác) hoặc Tôi Hoàn Hảo
	_glow_active = (crest_idx >= 3) or _is_perfect_quench
	_pulse_time = 0.0
	if not _glow_active and _pedestal_rect != null:
		_pedestal_rect.self_modulate = Color.WHITE

	# Cột phải: Tiêu đề + Banner + Chỉ số + 3 Kỹ năng thực chiến + Chân thẻ
	_name_label.text = _FORGE_CONVERTER._build_name(data)
	_name_label.add_theme_color_override("font_color", title_col)

	var sub_parts: Array[String] = [weapon_type]
	if not material_name.is_empty():
		sub_parts.append("Chất liệu: %s" % material_name)
	_subtitle_label.text = "  ·  ".join(sub_parts)

	_perfect_badge_panel.visible = _is_perfect_quench
	if not _matched_customer_name.is_empty():
		_commission_banner_label.text = "✓ KHỚP ĐƠN: %s" % _matched_customer_name
		_commission_banner_panel.visible = true
	else:
		_commission_banner_panel.visible = false
	_banners_row.visible = _perfect_badge_panel.visible or _commission_banner_panel.visible

	_atk_val.text = str(atk)
	_def_val.text = str(def_v)
	_magic_val.text = str(magic)
	_spd_val.text = str(spd)

	# 1. Chiêu Bẩm Sinh [0 STA]
	if innate_skill.is_empty():
		_innate_skill_label.text = "Bẩm sinh [0 STA]:  —"
	else:
		_innate_skill_label.text = "Bẩm sinh [0 STA]:  %s — %s" % [innate_skill, innate_desc]

	# 2. Chiêu Rèn (Tiền Tố Phase 2)
	var skill1: Dictionary = _FORGE_CONVERTER._prefix_to_skill(prefix_key)
	if skill1.is_empty():
		_prefix_skill_label.text = "Chiêu rèn:  Không có (Bị nguyền do đập lệch nhịp)"
		_prefix_skill_label.add_theme_color_override("font_color", Color(0.94, 0.50, 0.44))
	else:
		var s1_name: String = String(skill1.get("name", ""))
		var s1_sta: int = int(skill1.get("stamina_cost", 1))
		var s1_desc: String = PREFIX_SKILL_DESCS.get(prefix_key, "")
		_prefix_skill_label.text = "Chiêu rèn [%d STA]:  %s — %s" % [s1_sta, s1_name, s1_desc]
		_prefix_skill_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.50))

	# 3. Chiêu Linh Lực (Hệ Phase 3)
	var skill2: Dictionary = _FORGE_CONVERTER._suffix_to_skill(suffix_key)
	if skill2.is_empty() or elem_name.is_empty():
		_suffix_skill_label.text = "Linh lực:  Tôi Nước Thuần — Chưa khắc chiêu nguyên tố"
		_suffix_skill_label.add_theme_color_override("font_color", Color(0.70, 0.78, 0.84))
	else:
		var s2_name: String = String(skill2.get("name", ""))
		var s2_sta: int = int(skill2.get("stamina_cost", 2))
		var s2_desc: String = SUFFIX_SKILL_DESCS.get(suffix_key, "")
		_suffix_skill_label.text = "Linh lực [%d STA]:  %s (%s) — %s" % [
			s2_sta, s2_name, elem_name, s2_desc
		]
		_suffix_skill_label.add_theme_color_override("font_color", elem_bright)

	# Chân thẻ: Độ bền & Định giá
	if _is_perfect_quench and dur_bonus > 0:
		_durability_label.text = "Độ bền: %d / %d  (★ +%d)" % [max_dur, max_dur, dur_bonus]
	else:
		_durability_label.text = "Độ bền: %d / %d" % [max_dur, max_dur]

	var price_txt := "%s – %s G" % [_fmt_price(price_min), _fmt_price(price_max)]
	_price_label.text = (price_txt + " (+10%)") if _is_perfect_quench else price_txt


func _fmt_price(n: int) -> String:
	var s := str(n)
	var result := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			result += "."
		result += s[i]
	return result


# ══════════════════════════════════════════════════════════════════════════════
# LOGIC XỬ LÝ VŨ KHÍ & KỆ HÀNG
# ══════════════════════════════════════════════════════════════════════════════

## Xây dựng Dictionary vũ khí hoàn chỉnh (kèm bonus perfect_quench nếu có)
func build_combat_weapon() -> Dictionary:
	var weapon: Dictionary = _FORGE_CONVERTER.forge_to_combat(_current_data)
	for key in _current_data:
		if not weapon.has(key):
			weapon[key] = _current_data[key]
	var is_perfect: bool = bool(_current_data.get("perfect_quench", false))
	if is_perfect:
		weapon["perfect_quench"] = true
		var dur_b: int = int(_current_data.get("durability_bonus", 10))
		if dur_b <= 0:
			dur_b = 10
		weapon["durability_bonus"] = dur_b
		var max_d: int = 50 + dur_b
		weapon["durability"] = max_d
		weapon["durability_max"] = max_d
		var p_mult: float = float(_current_data.get("price_mult", 1.0))
		if not _current_data.has("price_mult"):
			p_mult *= 1.10
		weapon["price_mult"] = p_mult
		var atk_val: int = int(weapon.get("atk", 1))
		var mag_val: int = int(weapon.get("magic", 0))
		var spd_val: int = int(weapon.get("speed", 5))
		var rar_val: int = int(weapon.get("rarity_tier", 2))
		weapon["sell_value"] = _FORGE_CONVERTER.weapon_sell_value(
			atk_val, mag_val, spd_val, rar_val, p_mult
		)
	return weapon


## Lưu vũ khí và bày ngay lên kệ bán tiệm (tối đa MAX_SHELF_SLOTS)
## Trả về: { "success": bool, "weapon": Dictionary, "message": String }
func save_and_shelf(custom_weapon: Dictionary = {}) -> Dictionary:
	var weapon: Dictionary = custom_weapon if not custom_weapon.is_empty() else build_combat_weapon()
	InventorySystem.add_weapon(weapon)
	EventBus.weapon_forged.emit(weapon)

	var moved: bool = InventorySystem.move_to_shelf(weapon)
	var max_slots := InventorySystem.MAX_SHELF_SLOTS
	var msg: String = ""
	if moved:
		msg = "Đã lưu và bày lên kệ bán tiệm (Slot %d/%d)" % [
			InventorySystem.get_shelf_weapons().size(),
			max_slots,
		]
	else:
		msg = "Kệ tiệm đã đầy (%d/%d) — Đã lưu vào kho" % [max_slots, max_slots]

	var res := {
		"success": moved,
		"weapon": weapon,
		"message": msg,
	}
	shelf_saved.emit(res)
	return res


## Lưu vũ khí vào kho thông thường
func save_to_warehouse(custom_weapon: Dictionary = {}) -> Dictionary:
	var weapon: Dictionary = custom_weapon if not custom_weapon.is_empty() else build_combat_weapon()
	InventorySystem.add_weapon(weapon)
	EventBus.weapon_forged.emit(weapon)

	var res := {
		"success": true,
		"weapon": weapon,
		"message": "Đã lưu vào kho thành công",
	}
	warehouse_saved.emit(res)
	return res


## Lấy tên khách hàng của đơn hàng khớp (nếu có)
func get_matched_customer_name() -> String:
	return _matched_customer_name


## Kiểm tra vũ khí hiện tại có tôi hoàn hảo không
func is_perfect_quench() -> bool:
	return _is_perfect_quench
