# Weapon Builder — Chọn phôi vũ khí trước khi bắt đầu rèn
# Lưu lựa chọn vào GameManager.selected_blank → chuyển sang ForgeSession
extends Control

const BLANKS: Array = [
	{
		"id": "kiem_don",   "name": "Kiếm Đơn",    "skill": "Slash",        "skill_desc": "Chém cơ bản +50% dmg",
		"atk": 12, "def": 0,  "magic": 3,  "speed": 6, "customers": "Hiệp Khách",
		"color": Color(0.55, 0.62, 0.82),
	},
	{
		"id": "song_dao",   "name": "Song Đao",     "skill": "Twin Strike",  "skill_desc": "Đánh 2 lần liên tiếp",
		"atk": 10, "def": 0,  "magic": 2,  "speed": 8, "customers": "Thích Khách",
		"color": Color(0.72, 0.45, 0.62),
	},
	{
		"id": "giao_dai",   "name": "Giáo Dài",     "skill": "Reach",        "skill_desc": "Tấn công trước khi địch đánh",
		"atk": 13, "def": 2,  "magic": 1,  "speed": 5, "customers": "Thủ Vệ, Hiệp Khách",
		"color": Color(0.48, 0.72, 0.55),
	},
	{
		"id": "bua_chien",  "name": "Búa Chiến",    "skill": "Crush",        "skill_desc": "Phá giáp -3 DEF địch",
		"atk": 15, "def": 3,  "magic": 0,  "speed": 3, "customers": "Võ Tăng, Thủ Vệ",
		"color": Color(0.72, 0.55, 0.32),
	},
	{
		"id": "cung_truong","name": "Cung Trường",  "skill": "Aim",          "skill_desc": "Bỏ qua DEF địch 30%",
		"atk": 11, "def": 0,  "magic": 4,  "speed": 7, "customers": "Thợ Săn",
		"color": Color(0.52, 0.72, 0.42),
	},
	{
		"id": "khien_dong", "name": "Khiên Đồng",   "skill": "Block",        "skill_desc": "Chặn đòn tiếp theo",
		"atk": 6,  "def": 8,  "magic": 0,  "speed": 4, "customers": "Thủ Vệ",
		"color": Color(0.55, 0.58, 0.72),
	},
	{
		"id": "quyen_cu",   "name": "Quyền Cụ",     "skill": "Combo",        "skill_desc": "Đánh 3 lần, mỗi lần 60% dmg",
		"atk": 9,  "def": 1,  "magic": 2,  "speed": 9, "customers": "Võ Tăng",
		"color": Color(0.72, 0.42, 0.42),
	},
	{
		"id": "con_nhi",    "name": "Côn Nhị Khúc", "skill": "Whirl",        "skill_desc": "AoE — cả đội địch nhận dmg",
		"atk": 10, "def": 1,  "magic": 3,  "speed": 8, "customers": "Võ Tăng, Thích Khách",
		"color": Color(0.65, 0.52, 0.72),
	},
	{
		"id": "dao_phat",   "name": "Đao Phạt",     "skill": "Heavy Cleave", "skill_desc": "+100% dmg, mất lượt sau",
		"atk": 16, "def": 2,  "magic": 0,  "speed": 4, "customers": "Thủ Vệ đặc biệt",
		"color": Color(0.72, 0.35, 0.28),
	},
	{
		"id": "gay_phep",   "name": "Gậy Phép",     "skill": "Cast",         "skill_desc": "Dmg = Magic ×2",
		"atk": 5,  "def": 0,  "magic": 12, "speed": 6, "customers": "Đạo Sĩ",
		"color": Color(0.42, 0.52, 0.82),
	},
	{
		"id": "liem_song",  "name": "Liềm Song",    "skill": "Reap",         "skill_desc": "Tấn công + gây Độc",
		"atk": 11, "def": 0,  "magic": 2,  "speed": 7, "customers": "Thích Khách",
		"color": Color(0.35, 0.65, 0.48),
	},
	{
		"id": "phu_viet",   "name": "Phủ Việt",     "skill": "Sunder",       "skill_desc": "Phá giáp vĩnh viễn -2 DEF",
		"atk": 14, "def": 4,  "magic": 0,  "speed": 4, "customers": "Thủ Vệ, Võ Tăng",
		"color": Color(0.65, 0.58, 0.35),
	},
]

var _selected_idx: int = -1
var _hovered_idx:  int = -1
var _item_panels:  Array[PanelContainer] = []

var _detail_name:     Label
var _detail_skill:    Label
var _detail_desc:     Label
var _detail_atk:      Label
var _detail_def:      Label
var _detail_magic:    Label
var _detail_speed:    Label
var _detail_customer: Label
var _detail_panel:    PanelContainer
var _forge_btn:       Button


# ══════════════════════════════════════════════════════════════════════════════
# READY
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.07, 0.05)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left",   72)
	root_margin.add_theme_constant_override("margin_right",  72)
	root_margin.add_theme_constant_override("margin_top",    52)
	root_margin.add_theme_constant_override("margin_bottom", 52)
	add_child(root_margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	root_margin.add_child(vbox)

	vbox.add_child(_build_title())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 48)
	vbox.add_child(body)

	body.add_child(_build_grid())
	body.add_child(_build_detail_panel())

	vbox.add_child(_build_forge_row())

	_update_detail(-1)


# ══════════════════════════════════════════════════════════════════════════════
# TITLE
# ══════════════════════════════════════════════════════════════════════════════

func _build_title() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)

	var lbl := Label.new()
	lbl.text = "CHỌN PHÔI VŨ KHÍ"
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
# GRID
# ══════════════════════════════════════════════════════════════════════════════

func _build_grid() -> Control:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)

	for i in BLANKS.size():
		var item := _build_grid_item(i)
		grid.add_child(item)
		_item_panels.append(item)

	return grid


func _build_grid_item(idx: int) -> PanelContainer:
	var blank: Dictionary = BLANKS[idx]
	var c: Color = blank["color"]

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size   = Vector2(0, 150)
	panel.mouse_filter          = Control.MOUSE_FILTER_STOP
	_apply_item_style(panel, c, false, false)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left",   22)
	inner.add_theme_constant_override("margin_right",  22)
	inner.add_theme_constant_override("margin_top",    18)
	inner.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(inner)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	inner.add_child(vb)

	var c_bright := Color(minf(c.r * 1.45, 1.0), minf(c.g * 1.45, 1.0), minf(c.b * 1.45, 1.0))

	var name_lbl := Label.new()
	name_lbl.text = blank["name"]
	name_lbl.add_theme_font_size_override("font_size", 50)
	name_lbl.add_theme_color_override("font_color", c_bright)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	name_lbl.size_flags_vertical  = Control.SIZE_EXPAND_FILL
	name_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(name_lbl)

	var skill_lbl := Label.new()
	skill_lbl.text = blank["skill"]
	skill_lbl.add_theme_font_size_override("font_size", 34)
	skill_lbl.add_theme_color_override("font_color", Color(0.65, 0.62, 0.52))
	skill_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_lbl.clip_contents        = true
	vb.add_child(skill_lbl)

	panel.gui_input.connect(_on_item_input.bind(idx))
	panel.mouse_entered.connect(_on_item_mouse_entered.bind(idx))
	panel.mouse_exited.connect(_on_item_mouse_exited.bind(idx))

	return panel


# ══════════════════════════════════════════════════════════════════════════════
# DETAIL PANEL
# ══════════════════════════════════════════════════════════════════════════════

func _build_detail_panel() -> Control:
	_detail_panel = PanelContainer.new()
	_detail_panel.custom_minimum_size   = Vector2(640, 0)
	_detail_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	_detail_panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_apply_detail_panel_style(Color(0.42, 0.38, 0.28))

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left",   40)
	inner.add_theme_constant_override("margin_right",  40)
	inner.add_theme_constant_override("margin_top",    36)
	inner.add_theme_constant_override("margin_bottom", 36)
	_detail_panel.add_child(inner)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 22)
	inner.add_child(vb)

	# Tên phôi
	_detail_name = Label.new()
	_detail_name.text = "— Chọn phôi —"
	_detail_name.add_theme_font_size_override("font_size", 68)
	_detail_name.add_theme_color_override("font_color", Color(0.68, 0.64, 0.52))
	_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_name.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_detail_name)

	# Tên skill
	_detail_skill = Label.new()
	_detail_skill.add_theme_font_size_override("font_size", 52)
	_detail_skill.add_theme_color_override("font_color", Color(0.95, 0.82, 0.50))
	_detail_skill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_detail_skill)

	# Mô tả skill
	_detail_desc = Label.new()
	_detail_desc.add_theme_font_size_override("font_size", 40)
	_detail_desc.add_theme_color_override("font_color", Color(0.68, 0.65, 0.55))
	_detail_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_desc.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_detail_desc)

	vb.add_child(_make_divider())

	# Stats — 4 khối ATK / DEF / MAGIC / SPD
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 0)
	vb.add_child(stats_row)

	_detail_atk   = _add_stat_block(stats_row, "ATK",   Color(0.95, 0.45, 0.35))
	_detail_def   = _add_stat_block(stats_row, "DEF",   Color(0.45, 0.75, 0.95))
	_detail_magic = _add_stat_block(stats_row, "MAGIC", Color(0.78, 0.55, 0.95))
	_detail_speed = _add_stat_block(stats_row, "SPD",   Color(0.55, 0.92, 0.62))

	vb.add_child(_make_divider())

	# Khách hàng
	var cust_header := Label.new()
	cust_header.text = "Khách hàng phù hợp"
	cust_header.add_theme_font_size_override("font_size", 34)
	cust_header.add_theme_color_override("font_color", Color(0.48, 0.46, 0.38))
	cust_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(cust_header)

	_detail_customer = Label.new()
	_detail_customer.add_theme_font_size_override("font_size", 44)
	_detail_customer.add_theme_color_override("font_color", Color(0.52, 0.88, 0.55))
	_detail_customer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_customer.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_detail_customer)

	return _detail_panel


func _make_divider() -> Control:
	var rect := ColorRect.new()
	rect.color = Color(0.35, 0.32, 0.25, 0.55)
	rect.custom_minimum_size = Vector2(0, 2)
	return rect


func _add_stat_block(parent: HBoxContainer, label_text: String, color: Color) -> Label:
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	parent.add_child(vb)

	var val_lbl := Label.new()
	val_lbl.text = "—"
	val_lbl.add_theme_font_size_override("font_size", 68)
	val_lbl.add_theme_color_override("font_color", color)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(val_lbl)

	var name_lbl := Label.new()
	name_lbl.text = label_text
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_color", Color(0.48, 0.46, 0.38))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(name_lbl)

	return val_lbl


# ══════════════════════════════════════════════════════════════════════════════
# FORGE BUTTON ROW
# ══════════════════════════════════════════════════════════════════════════════

func _build_forge_row() -> Control:
	@warning_ignore("shadowed_global_identifier")
	var wrap := CenterContainer.new()
	wrap.custom_minimum_size.y = 112

	_forge_btn = Button.new()
	_forge_btn.text = "⚒   BẮT ĐẦU RÈN"
	_forge_btn.add_theme_font_size_override("font_size", 62)
	_forge_btn.custom_minimum_size = Vector2(720, 100)
	_forge_btn.disabled   = true
	_forge_btn.focus_mode = Control.FOCUS_NONE
	_forge_btn.pressed.connect(_on_forge_pressed)
	_apply_forge_btn_style()
	wrap.add_child(_forge_btn)

	return wrap


# ══════════════════════════════════════════════════════════════════════════════
# STYLE HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _apply_item_style(panel: PanelContainer, c: Color, hovered: bool, selected: bool) -> void:
	var s := StyleBoxFlat.new()
	s.set_corner_radius_all(10)

	if selected:
		s.bg_color = Color(c.r * 0.30, c.g * 0.30, c.b * 0.30)
		s.border_color = c
		s.set_border_width_all(4)
	elif hovered:
		s.bg_color = Color(c.r * 0.20, c.g * 0.20, c.b * 0.20)
		s.border_color = Color(c.r * 0.68, c.g * 0.68, c.b * 0.68)
		s.set_border_width_all(3)
	else:
		s.bg_color = Color(c.r * 0.12, c.g * 0.12, c.b * 0.12)
		s.border_color = Color(c.r * 0.35, c.g * 0.35, c.b * 0.35)
		s.set_border_width_all(2)

	panel.add_theme_stylebox_override("panel", s)


func _refresh_item(idx: int) -> void:
	if idx < 0 or idx >= _item_panels.size():
		return
	_apply_item_style(
		_item_panels[idx],
		BLANKS[idx]["color"],
		_hovered_idx == idx,
		_selected_idx == idx
	)


func _apply_detail_panel_style(border_c: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.11, 0.09, 0.07)
	s.border_color = border_c
	s.set_border_width_all(3)
	s.set_corner_radius_all(12)
	_detail_panel.add_theme_stylebox_override("panel", s)


func _apply_forge_btn_style() -> void:
	var enabled := not _forge_btn.disabled

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
		_forge_btn.add_theme_color_override("font_color", Color(0.98, 0.92, 0.62))

		var hover := s.duplicate() as StyleBoxFlat
		hover.bg_color     = Color(0.62, 0.44, 0.12)
		hover.border_color = Color(0.95, 0.78, 0.28)
		hover.set_border_width_all(4)
		_forge_btn.add_theme_stylebox_override("hover", hover)

		var pressed := s.duplicate() as StyleBoxFlat
		pressed.bg_color = Color(0.38, 0.26, 0.06)
		_forge_btn.add_theme_stylebox_override("pressed", pressed)
	else:
		s.bg_color     = Color(0.17, 0.15, 0.13)
		s.border_color = Color(0.30, 0.28, 0.24)
		s.set_border_width_all(2)
		_forge_btn.add_theme_color_override("font_color", Color(0.40, 0.38, 0.32))

	_forge_btn.add_theme_stylebox_override("normal",   s)
	_forge_btn.add_theme_stylebox_override("disabled", s)
	_forge_btn.add_theme_stylebox_override("focus",    s)


# ══════════════════════════════════════════════════════════════════════════════
# EVENT HANDLERS
# ══════════════════════════════════════════════════════════════════════════════

func _on_item_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		_on_blank_selected(idx)


func _on_item_mouse_entered(idx: int) -> void:
	_hovered_idx = idx
	_refresh_item(idx)


func _on_item_mouse_exited(idx: int) -> void:
	if _hovered_idx == idx:
		_hovered_idx = -1
	_refresh_item(idx)


func _on_blank_selected(idx: int) -> void:
	var prev := _selected_idx
	_selected_idx = idx
	if prev >= 0:
		_refresh_item(prev)
	_refresh_item(idx)
	_update_detail(idx)
	if _forge_btn.disabled:
		_forge_btn.disabled = false
		_apply_forge_btn_style()


func _update_detail(idx: int) -> void:
	if idx < 0:
		_detail_name.text = "— Chọn phôi —"
		_detail_name.add_theme_color_override("font_color", Color(0.68, 0.64, 0.52))
		_detail_skill.text    = ""
		_detail_desc.text     = ""
		_detail_atk.text      = "—"
		_detail_def.text      = "—"
		_detail_magic.text    = "—"
		_detail_speed.text    = "—"
		_detail_customer.text = ""
		_apply_detail_panel_style(Color(0.42, 0.38, 0.28))
		return

	var b: Dictionary = BLANKS[idx]
	var c: Color      = b["color"]
	var c_bright      := Color(minf(c.r * 1.45, 1.0), minf(c.g * 1.45, 1.0), minf(c.b * 1.45, 1.0))

	_apply_detail_panel_style(Color(c.r * 0.55, c.g * 0.55, c.b * 0.55))

	_detail_name.text = b["name"]
	_detail_name.add_theme_color_override("font_color", c_bright)
	_detail_skill.text    = b["skill"]
	_detail_desc.text     = b["skill_desc"]
	_detail_atk.text      = str(b["atk"])
	_detail_def.text      = str(b["def"])
	_detail_magic.text    = str(b["magic"])
	_detail_speed.text    = str(b["speed"])
	_detail_customer.text = b["customers"]


func _on_forge_pressed() -> void:
	if _selected_idx < 0:
		return
	GameManager.selected_blank = BLANKS[_selected_idx]
	get_tree().change_scene_to_file("res://scenes/forge/ForgeSession.tscn")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo or not event.pressed:
		return
	if event.keycode == KEY_ENTER and _selected_idx >= 0:
		_on_forge_pressed()
