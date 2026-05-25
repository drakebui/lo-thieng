# Reusable weapon card UI — hiển thị kết quả vũ khí sau khi rèn
# setup(weapon_data) để cập nhật nội dung:
#   phase1_tier, phase2_prefix, element, suffix, element_name, element_color
#   weapon_type, base_atk, base_def, base_magic, base_speed
#   innate_skill, innate_skill_desc
extends Control

const _FORGE_CONVERTER := preload("res://scripts/forge/weapon_data.gd")

const CARD_WIDTH  := 1200.0
const CARD_HEIGHT := 720.0

const PHASE1_TIER_NAMES := {
	"lanh":     "Lạnh",
	"cam":      "Cam",
	"vang_kim": "Vàng Kim",
}
const PHASE1_MULTIPLIERS := {
	"lanh":     0.7,
	"cam":      1.2,
	"vang_kim": 1.4,
}
const PHASE2_PREFIX_NAMES := {
	"phan_chu":   "Phản Chủ",  "curse_nang": "Lời Nguyền",
	"curse_nhe":  "Nguyền Nhẹ","thuong":     "Thường",
	"tot":        "Tốt",       "kiet_tac":   "Kiệt Tác",
	"to_nghe":    "Tổ Nghề",   "khi_phach":  "Khí Phách",
	"perfect":    "PERFECT",
}
const PHASE2_BONUS := {
	"phan_chu":   -5, "curse_nang": -3, "curse_nhe":  -1,
	"thuong":      0, "tot":         1, "kiet_tac":    2,
	"to_nghe":     3, "khi_phach":   4, "perfect":     5,
}
const SUFFIX_NAMES := {
	"thieu_dot":   "Thiêu Đốt", "bang_gia":    "Băng Giá",
	"sam_set":     "Sấm Sét",   "dao_dong":    "Dao Động",
	"cuong_phong": "Cuồng Phong","hu_khong":   "Hư Không",
}

const _DEFAULT_ATK   := 12
const _DEFAULT_DEF   :=  0
const _DEFAULT_MAGIC :=  3

# Nodes cần cập nhật từ setup()
var _card_panel:        PanelContainer
var _accent_strip:      ColorRect
var _name_label:        Label
var _meta_label:        Label
var _atk_val:           Label
var _def_val:           Label
var _magic_val:         Label
var _spd_val:           Label
var _skill1_label:      Label
var _skill2_label:      Label
var _durability_label:  Label
var _price_label:       Label


func _ready() -> void:
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	_build()

	if get_parent() == get_tree().root or get_parent() is SubViewport:
		setup({
			"phase1_tier":      "cam",       "phase2_prefix":    "kiet_tac",
			"element":          "hoa",        "suffix":           "thieu_dot",
			"element_name":     "Hỏa",        "element_color":    Color(1.0, 0.32, 0.05),
			"weapon_type":      "Kiếm Đơn",  "base_atk":         12,
			"base_def":          0,           "base_magic":        3,
			"base_speed":        6,           "innate_skill":      "Slash",
			"innate_skill_desc": "Chém cơ bản +50% dmg",
		})


func _build() -> void:
	# Outer panel với border tối
	_card_panel = PanelContainer.new()
	_card_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_card_style(Color(0.42, 0.38, 0.28))
	add_child(_card_panel)

	# Accent strip nằm trên cùng (đổi màu theo nguyên tố)
	_accent_strip = ColorRect.new()
	_accent_strip.color       = Color(0.42, 0.38, 0.28)
	_accent_strip.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_accent_strip.offset_bottom = 10
	_accent_strip.z_index       = 1
	add_child(_accent_strip)

	# Nội dung bên trong qua MarginContainer
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   52)
	margin.add_theme_constant_override("margin_right",  52)
	margin.add_theme_constant_override("margin_top",    32)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Tên vũ khí
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 60)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name_label.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_name_label)

	# Meta: 3 phase
	_meta_label = Label.new()
	_meta_label.add_theme_font_size_override("font_size", 40)
	_meta_label.add_theme_color_override("font_color", Color(0.65, 0.62, 0.52))
	_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_meta_label)

	vbox.add_child(_make_divider(Color(0.38, 0.35, 0.28, 0.7)))

	# Stats row — 4 khối có màu riêng
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 0)
	vbox.add_child(stats_row)

	_atk_val   = _add_stat_block(stats_row, "ATK",   Color(0.95, 0.45, 0.35))
	_def_val   = _add_stat_block(stats_row, "DEF",   Color(0.42, 0.72, 0.95))
	_magic_val = _add_stat_block(stats_row, "MAGIC", Color(0.78, 0.52, 0.95))
	_spd_val   = _add_stat_block(stats_row, "SPD",   Color(0.52, 0.92, 0.62))

	vbox.add_child(_make_divider(Color(0.38, 0.35, 0.28, 0.7)))

	# Skills
	_skill1_label = Label.new()
	_skill1_label.add_theme_font_size_override("font_size", 44)
	_skill1_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.72))
	_skill1_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_skill1_label)

	_skill2_label = Label.new()
	_skill2_label.add_theme_font_size_override("font_size", 44)
	_skill2_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_skill2_label)

	vbox.add_child(_make_divider(Color(0.38, 0.35, 0.28, 0.7)))

	# Độ bền + Giá
	_durability_label = Label.new()
	_durability_label.add_theme_font_size_override("font_size", 42)
	_durability_label.add_theme_color_override("font_color", Color(0.68, 0.65, 0.55))
	vbox.add_child(_durability_label)

	_price_label = Label.new()
	_price_label.add_theme_font_size_override("font_size", 48)
	_price_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.28))
	vbox.add_child(_price_label)


func _make_divider(color: Color) -> Control:
	var rect := ColorRect.new()
	rect.color = color
	rect.custom_minimum_size = Vector2(0, 2)
	return rect


func _add_stat_block(parent: HBoxContainer, stat_name: String, color: Color) -> Label:
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	parent.add_child(vb)

	var val := Label.new()
	val.text = "—"
	val.add_theme_font_size_override("font_size", 72)
	val.add_theme_color_override("font_color", color)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(val)

	var name_lbl := Label.new()
	name_lbl.text = stat_name
	name_lbl.add_theme_font_size_override("font_size", 30)
	name_lbl.add_theme_color_override("font_color", Color(0.48, 0.46, 0.38))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(name_lbl)

	return val


func _apply_card_style(border_color: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color     = Color(0.12, 0.10, 0.08)
	s.border_color = border_color
	s.set_border_width_all(3)
	s.set_corner_radius_all(12)
	_card_panel.add_theme_stylebox_override("panel", s)


# ══════════════════════════════════════════════════════════════════════════════
# SETUP — cập nhật nội dung từ kết quả rèn
# ══════════════════════════════════════════════════════════════════════════════

func setup(data: Dictionary) -> void:
	var tier_key:    String = data.get("phase1_tier",       "cam")
	var prefix_key:  String = data.get("phase2_prefix",     "thuong")
	var suffix_key:  String = data.get("suffix",            "")
	var elem_color:  Color  = data.get("element_color",     Color(0.6, 0.6, 0.6))
	var elem_name:   String = data.get("element_name",      "")
	var weapon_type: String = data.get("weapon_type",       "Vũ Khí")
	var innate_skill: String = data.get("innate_skill",     "")
	var innate_desc:  String = data.get("innate_skill_desc","")
	var base_atk:    int    = data.get("base_atk",          _DEFAULT_ATK)
	var base_def:    int    = data.get("base_def",          _DEFAULT_DEF)
	var base_magic:  int    = data.get("base_magic",        _DEFAULT_MAGIC)
	var base_speed:  int    = data.get("base_speed",        5)

	var prefix_name:   String = PHASE2_PREFIX_NAMES.get(prefix_key, prefix_key)
	var suffix_name:   String = SUFFIX_NAMES.get(suffix_key, suffix_key)
	var tier_name:     String = PHASE1_TIER_NAMES.get(tier_key, tier_key)
	var material_name: String = data.get("material_name", "")
	var price_mult:    float  = data.get("price_mult",    1.0)

	var mult:  float = PHASE1_MULTIPLIERS.get(tier_key, 1.0)
	var bonus: int   = PHASE2_BONUS.get(prefix_key, 0)
	var atk:   int   = maxi(0, int(base_atk   * mult) + bonus)
	var def_v: int   = maxi(0, int(base_def   * mult))
	var magic: int   = maxi(0, int(base_magic * mult) + bonus)
	var spd:   int   = base_speed

	var rar_tier: int = _FORGE_CONVERTER.PREFIX_RARITY.get(prefix_key, 2)
	var sell_val   := _FORGE_CONVERTER.weapon_sell_value(atk, magic, spd, rar_tier, price_mult)
	var price_min  := int(sell_val * 0.85)
	var price_max  := int(sell_val * 1.15)

	# Cập nhật border và accent theo nguyên tố
	_apply_card_style(Color(elem_color.r * 0.65, elem_color.g * 0.65, elem_color.b * 0.65))
	_accent_strip.color = elem_color

	_name_label.text = "⚔  %s  %s · %s" % [weapon_type, prefix_name, suffix_name]
	_name_label.add_theme_color_override("font_color", elem_color)

	var mat_part := ("NL: %s   •   " % material_name) if not material_name.is_empty() else ""
	_meta_label.text = "%sNung: %s   •   Rèn: %s   •   Nguyên tố: %s" % [
		mat_part, tier_name, prefix_name, elem_name]

	_atk_val.text   = str(atk)
	_def_val.text   = str(def_v)
	_magic_val.text = str(magic)
	_spd_val.text   = str(spd)

	if innate_skill.is_empty():
		_skill1_label.text = "Innate Skill:  —"
	else:
		_skill1_label.text = "Innate:  %s  —  %s" % [innate_skill, innate_desc]

	_skill2_label.text = "Nguyên Tố:  %s  (%s)" % [elem_name, suffix_name]
	_skill2_label.add_theme_color_override("font_color", elem_color)

	_durability_label.text = "Độ bền:  50 / 50"
	_price_label.text = "Giá ước tính:  %s – %s  G" % [_fmt_price(price_min), _fmt_price(price_max)]


func _fmt_price(n: int) -> String:
	var s := str(n)
	var result := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			result += "."
		result += s[i]
	return result
