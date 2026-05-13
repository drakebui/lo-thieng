# Material Picker — chọn nguyên liệu trước khi rèn
# Lưu vào GameManager.selected_material → chuyển sang WeaponBuilder
extends Control

const REGION_NAMES := {
	"DongMay":     "Đồng Mây Trắng",
	"RungTramHon": "Rừng Trăm Hồn",
	"NuiThanDo":   "Núi Than Đỏ",
	"BaiCat":      "Bãi Cát Thần Vàng",
	"ThanhNgoc":   "Thành Ngọc Bích",
	"LangTo":      "Làng Tổ Nghề",
}
const RARITY_COLORS := [
	Color.WHITE,
	Color(0.60, 0.60, 0.60),   # r1 — xám
	Color(0.38, 0.62, 0.95),   # r2 — xanh
	Color(0.95, 0.82, 0.22),   # r3 — vàng
]

var _materials: Array  = []
var _selected_idx: int = -1
var _hovered_idx:  int = -1
var _item_panels:  Array[PanelContainer] = []

var _detail_panel:   PanelContainer
var _detail_name:    Label
var _detail_stars:   Label
var _detail_region:  Label
var _detail_desc:    Label
var _detail_bonuses: Label
var _detail_effect:  Label
var _next_btn:       Button

# Refs để _do_layout() đặt position/size trực tiếp
var _bg:          ColorRect
var _title_ctrl:  Control
var _grid_scroll: ScrollContainer
var _btn_wrap:    CenterContainer


# ══════════════════════════════════════════════════════════════════════════════
# READY + LAYOUT
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var raw := ItemDatabase.get_items_by_type(ItemData.ItemType.MATERIAL)
	for item in raw:
		_materials.append(item)

	_bg = ColorRect.new()
	_bg.color = Color(0.08, 0.07, 0.05)
	add_child(_bg)

	_title_ctrl = _build_title()
	add_child(_title_ctrl)

	# Grid và detail là con trực tiếp của root Control
	# — không qua HBoxContainer để tránh min-size clamping
	add_child(_build_grid())        # lưu ref vào _grid_scroll bên trong hàm
	add_child(_build_detail_panel()) # lưu ref vào _detail_panel

	_btn_wrap = CenterContainer.new()
	add_child(_btn_wrap)

	_next_btn = Button.new()
	_next_btn.text = "Chọn Phôi  →"
	_next_btn.add_theme_font_size_override("font_size", 62)
	_next_btn.custom_minimum_size = Vector2(720, 100)
	_next_btn.disabled   = true
	_next_btn.focus_mode = Control.FOCUS_NONE
	_next_btn.pressed.connect(_on_next_pressed)
	_apply_btn_style()
	_btn_wrap.add_child(_next_btn)

	_update_detail(-1)
	_do_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_do_layout()


# Đặt vị trí và kích thước tất cả các vùng — hoàn toàn bằng tay
func _do_layout() -> void:
	if not _bg:
		return
	var w := size.x
	var h := size.y
	if w == 0 or h == 0:
		return

	const LM        := 72.0   # lề trái/phải
	const TITLE_T   := 40.0   # top title
	const TITLE_H   := 145.0  # chiều cao title
	const BODY_T    := 195.0  # top body
	const BTN_H     := 102.0  # chiều cao vùng nút
	const BTN_BOT   := 28.0   # khoảng cách đáy màn hình
	const DETAIL_W  := 620.0  # chiều rộng detail panel
	const SEP       := 48.0   # khoảng giữa grid và detail

	_bg.position = Vector2.ZERO
	_bg.size     = Vector2(w, h)

	_title_ctrl.position = Vector2(LM, TITLE_T)
	_title_ctrl.size     = Vector2(w - LM * 2, TITLE_H)

	var body_h    := h - BODY_T - BTN_H - BTN_BOT          # ví dụ: 755px ở 1080
	var scroll_w  := w - LM * 2 - DETAIL_W - SEP           # ví dụ: 1108px ở 1920

	# ScrollContainer kích thước cố định → GridContainer (850px) cuộn bên trong
	_grid_scroll.position = Vector2(LM, BODY_T)
	_grid_scroll.size     = Vector2(scroll_w, body_h)

	# Detail panel — bên phải grid
	_detail_panel.position = Vector2(LM + scroll_w + SEP, BODY_T)
	_detail_panel.size     = Vector2(DETAIL_W, body_h)

	_btn_wrap.position = Vector2(0, h - BTN_H - BTN_BOT)
	_btn_wrap.size     = Vector2(w, BTN_H)


# ══════════════════════════════════════════════════════════════════════════════
# BUILD — TITLE
# ══════════════════════════════════════════════════════════════════════════════

func _build_title() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)

	var lbl := Label.new()
	lbl.text = "CHỌN NGUYÊN LIỆU"
	lbl.add_theme_font_size_override("font_size", 92)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.50))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(lbl)

	var accent := ColorRect.new()
	accent.color = Color(0.60, 0.45, 0.14)
	accent.custom_minimum_size = Vector2(0, 3)
	vb.add_child(accent)

	return vb


# ══════════════════════════════════════════════════════════════════════════════
# BUILD — GRID (4 cột, scroll dọc)
# ══════════════════════════════════════════════════════════════════════════════

func _build_grid() -> ScrollContainer:
	_grid_scroll = ScrollContainer.new()
	_grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	_grid_scroll.add_child(grid)

	for i in _materials.size():
		var panel := _build_grid_item(i)
		grid.add_child(panel)
		_item_panels.append(panel)

	return _grid_scroll


func _build_grid_item(idx: int) -> PanelContainer:
	var item: ItemData = _materials[idx]
	var c: Color = RARITY_COLORS[clamp(item.rarity, 1, 3)]

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size   = Vector2(0, 130)
	panel.mouse_filter          = Control.MOUSE_FILTER_STOP
	_apply_item_style(panel, c, false, false)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left",   18)
	inner.add_theme_constant_override("margin_right",  18)
	inner.add_theme_constant_override("margin_top",    12)
	inner.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(inner)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	inner.add_child(vb)

	var c_bright := Color(minf(c.r * 1.45, 1.0), minf(c.g * 1.45, 1.0), minf(c.b * 1.45, 1.0))

	var name_lbl := Label.new()
	name_lbl.text = item.item_name
	name_lbl.add_theme_font_size_override("font_size", 38)
	name_lbl.add_theme_color_override("font_color", c_bright)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.size_flags_vertical  = Control.SIZE_EXPAND_FILL
	vb.add_child(name_lbl)

	var region_id := item.effect_data.get("region", "") as String
	var region_lbl := Label.new()
	region_lbl.text = REGION_NAMES.get(region_id, region_id)
	region_lbl.add_theme_font_size_override("font_size", 24)
	region_lbl.add_theme_color_override("font_color", Color(0.50, 0.48, 0.40))
	region_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(region_lbl)

	var stars_lbl := Label.new()
	stars_lbl.text = "★".repeat(item.rarity) + "☆".repeat(3 - item.rarity)
	stars_lbl.add_theme_font_size_override("font_size", 26)
	stars_lbl.add_theme_color_override("font_color", c)
	stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(stars_lbl)

	panel.gui_input.connect(_on_item_input.bind(idx))
	panel.mouse_entered.connect(_on_item_mouse_entered.bind(idx))
	panel.mouse_exited.connect(_on_item_mouse_exited.bind(idx))

	return panel


# ══════════════════════════════════════════════════════════════════════════════
# BUILD — DETAIL PANEL
# ══════════════════════════════════════════════════════════════════════════════

func _build_detail_panel() -> Control:
	_detail_panel = PanelContainer.new()
	_apply_detail_style(Color(0.42, 0.38, 0.28))

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left",   40)
	inner.add_theme_constant_override("margin_right",  40)
	inner.add_theme_constant_override("margin_top",    36)
	inner.add_theme_constant_override("margin_bottom", 36)
	_detail_panel.add_child(inner)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	inner.add_child(vb)

	_detail_name = Label.new()
	_detail_name.text = "— Chọn nguyên liệu —"
	_detail_name.add_theme_font_size_override("font_size", 58)
	_detail_name.add_theme_color_override("font_color", Color(0.68, 0.64, 0.52))
	_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_name.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_detail_name)

	_detail_stars = Label.new()
	_detail_stars.add_theme_font_size_override("font_size", 42)
	_detail_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_detail_stars)

	_detail_region = Label.new()
	_detail_region.add_theme_font_size_override("font_size", 34)
	_detail_region.add_theme_color_override("font_color", Color(0.55, 0.52, 0.44))
	_detail_region.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_detail_region)

	vb.add_child(_make_divider())

	_detail_desc = Label.new()
	_detail_desc.add_theme_font_size_override("font_size", 34)
	_detail_desc.add_theme_color_override("font_color", Color(0.68, 0.65, 0.55))
	_detail_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_detail_desc.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_detail_desc)

	vb.add_child(_make_divider())

	_detail_bonuses = Label.new()
	_detail_bonuses.add_theme_font_size_override("font_size", 42)
	_detail_bonuses.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_detail_bonuses.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_detail_bonuses)

	_detail_effect = Label.new()
	_detail_effect.add_theme_font_size_override("font_size", 34)
	_detail_effect.add_theme_color_override("font_color", Color(0.55, 0.95, 0.60))
	_detail_effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_detail_effect.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_detail_effect)

	return _detail_panel


func _make_divider() -> Control:
	var rect := ColorRect.new()
	rect.color = Color(0.35, 0.32, 0.25, 0.55)
	rect.custom_minimum_size = Vector2(0, 2)
	return rect



# ══════════════════════════════════════════════════════════════════════════════
# STYLE HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _apply_item_style(panel: PanelContainer, c: Color, hovered: bool, selected: bool) -> void:
	var s := StyleBoxFlat.new()
	s.set_corner_radius_all(10)
	if selected:
		s.bg_color     = Color(c.r * 0.30, c.g * 0.30, c.b * 0.30)
		s.border_color = c
		s.set_border_width_all(4)
	elif hovered:
		s.bg_color     = Color(c.r * 0.20, c.g * 0.20, c.b * 0.20)
		s.border_color = Color(c.r * 0.68, c.g * 0.68, c.b * 0.68)
		s.set_border_width_all(3)
	else:
		s.bg_color     = Color(c.r * 0.12, c.g * 0.12, c.b * 0.12)
		s.border_color = Color(c.r * 0.35, c.g * 0.35, c.b * 0.35)
		s.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", s)


func _refresh_item(idx: int) -> void:
	if idx < 0 or idx >= _item_panels.size():
		return
	var item: ItemData = _materials[idx]
	var c: Color = RARITY_COLORS[clamp(item.rarity, 1, 3)]
	_apply_item_style(_item_panels[idx], c, _hovered_idx == idx, _selected_idx == idx)


func _apply_detail_style(border_c: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color     = Color(0.11, 0.09, 0.07)
	s.border_color = border_c
	s.set_border_width_all(3)
	s.set_corner_radius_all(12)
	_detail_panel.add_theme_stylebox_override("panel", s)


func _apply_btn_style() -> void:
	var enabled := not _next_btn.disabled
	var s := StyleBoxFlat.new()
	s.set_corner_radius_all(10)
	s.content_margin_left   = 48
	s.content_margin_right  = 48
	s.content_margin_top    = 20
	s.content_margin_bottom = 20
	if enabled:
		s.bg_color     = Color(0.50, 0.34, 0.08)
		s.border_color = Color(0.80, 0.60, 0.18)
		s.set_border_width_all(3)
		_next_btn.add_theme_color_override("font_color", Color(0.98, 0.92, 0.62))
		var hover := s.duplicate() as StyleBoxFlat
		hover.bg_color = Color(0.62, 0.44, 0.12); hover.border_color = Color(0.95, 0.78, 0.28)
		hover.set_border_width_all(4)
		_next_btn.add_theme_stylebox_override("hover", hover)
	else:
		s.bg_color     = Color(0.17, 0.15, 0.13)
		s.border_color = Color(0.30, 0.28, 0.24)
		s.set_border_width_all(2)
		_next_btn.add_theme_color_override("font_color", Color(0.40, 0.38, 0.32))
	_next_btn.add_theme_stylebox_override("normal",   s)
	_next_btn.add_theme_stylebox_override("disabled", s)
	_next_btn.add_theme_stylebox_override("focus",    s)


# ══════════════════════════════════════════════════════════════════════════════
# EVENT HANDLERS
# ══════════════════════════════════════════════════════════════════════════════

func _on_item_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		_on_material_selected(idx)


func _on_item_mouse_entered(idx: int) -> void:
	_hovered_idx = idx
	_refresh_item(idx)


func _on_item_mouse_exited(idx: int) -> void:
	if _hovered_idx == idx:
		_hovered_idx = -1
	_refresh_item(idx)


func _on_material_selected(idx: int) -> void:
	var prev := _selected_idx
	_selected_idx = idx
	if prev >= 0:
		_refresh_item(prev)
	_refresh_item(idx)
	_update_detail(idx)
	if _next_btn.disabled:
		_next_btn.disabled = false
		_apply_btn_style()


func _update_detail(idx: int) -> void:
	if idx < 0:
		_detail_name.text = "— Chọn nguyên liệu —"
		_detail_name.add_theme_color_override("font_color", Color(0.68, 0.64, 0.52))
		_detail_stars.text   = ""
		_detail_region.text  = ""
		_detail_desc.text    = ""
		_detail_bonuses.text = ""
		_detail_effect.text  = ""
		_apply_detail_style(Color(0.42, 0.38, 0.28))
		return

	var item: ItemData = _materials[idx]
	var c: Color = RARITY_COLORS[clamp(item.rarity, 1, 3)]
	var c_bright := Color(minf(c.r * 1.45, 1.0), minf(c.g * 1.45, 1.0), minf(c.b * 1.45, 1.0))

	_apply_detail_style(Color(c.r * 0.55, c.g * 0.55, c.b * 0.55))
	_detail_name.text = item.item_name
	_detail_name.add_theme_color_override("font_color", c_bright)
	_detail_stars.text = "★".repeat(item.rarity) + "☆".repeat(3 - item.rarity)
	_detail_stars.add_theme_color_override("font_color", c)

	var region_id := item.effect_data.get("region", "") as String
	_detail_region.text = "Vùng: " + REGION_NAMES.get(region_id, region_id)
	_detail_desc.text   = item.description

	# Stat bonuses
	var lines: PackedStringArray = []
	var atk_b  := item.effect_data.get("atk_bonus",   0) as int
	var def_b  := item.effect_data.get("def_bonus",   0) as int
	var mag_b  := item.effect_data.get("magic_bonus", 0) as int
	var spd_b  := item.effect_data.get("speed_bonus", 0) as int
	var p_mult := item.effect_data.get("price_mult", 1.0) as float
	if atk_b  != 0: lines.append("ATK    %s%d" % ["+" if atk_b  > 0 else "", atk_b])
	if def_b  != 0: lines.append("DEF    %s%d" % ["+" if def_b  > 0 else "", def_b])
	if mag_b  != 0: lines.append("MAGIC  %s%d" % ["+" if mag_b  > 0 else "", mag_b])
	if spd_b  != 0: lines.append("SPD    %s%d" % ["+" if spd_b  > 0 else "", spd_b])
	if p_mult != 1.0: lines.append("Giá bán  ×%.2f" % p_mult)

	if lines.is_empty():
		_detail_bonuses.text = "(không có bonus stat)"
		_detail_bonuses.add_theme_color_override("font_color", Color(0.45, 0.42, 0.35))
	else:
		_detail_bonuses.text = "\n".join(lines)
		_detail_bonuses.add_theme_color_override("font_color", Color(0.92, 0.88, 0.72))

	# Special phase effect
	var p1_min := item.effect_data.get("phase1_min", "") as String
	match p1_min:
		"vang_kim": _detail_effect.text = "⚡ Phase 1 tự động đạt Vàng Kim"
		"cam":      _detail_effect.text = "🔥 Phase 1 tối thiểu Cam"
		_:          _detail_effect.text = ""


func _on_next_pressed() -> void:
	if _selected_idx < 0:
		return
	var item: ItemData = _materials[_selected_idx]
	GameManager.selected_material = {
		"id":          item.item_id,
		"name":        item.item_name,
		"rarity":      item.rarity,
		"atk_bonus":   item.effect_data.get("atk_bonus",   0),
		"def_bonus":   item.effect_data.get("def_bonus",   0),
		"magic_bonus": item.effect_data.get("magic_bonus", 0),
		"speed_bonus": item.effect_data.get("speed_bonus", 0),
		"price_mult":  item.effect_data.get("price_mult",  1.0),
		"phase1_min":  item.effect_data.get("phase1_min",  ""),
	}
	get_tree().change_scene_to_file("res://scenes/forge/WeaponBuilder.tscn")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo or not event.pressed:
		return
	if event.keycode == KEY_ENTER and _selected_idx >= 0:
		_on_next_pressed()
