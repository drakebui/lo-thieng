# Màn hình kho vũ khí — xem danh sách vũ khí đã rèn.
extends Control

const RARITY_COLORS: Array = [
	Color(0.62, 0.60, 0.58),  # 1 Phổ Thông
	Color(0.88, 0.86, 0.80),  # 2 Thường
	Color(0.38, 0.72, 0.95),  # 3 Hiếm
	Color(0.72, 0.40, 0.95),  # 4 Cực Hiếm
	Color(0.95, 0.80, 0.18),  # 5 Huyền Thoại
]
const RARITY_NAMES: Array = [
	"Phổ Thông", "Thường", "Hiếm", "Cực Hiếm", "Huyền Thoại",
]

var _scroll: ScrollContainer


# ══════════════════════════════════════════════════════════════════════════════
# READY
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.07, 0.06)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_add_anchored(_build_header(), 0.0, 0.00, 1.0, 0.10)
	_add_anchored(_build_weapon_list(), 0.0, 0.10, 1.0, 0.90)
	_add_anchored(_build_footer(), 0.0, 0.90, 1.0, 1.00)

	_refresh_weapon_list()

	InventorySystem.weapon_added.connect(func(_w: Dictionary) -> void: _refresh_weapon_list())


func _add_anchored(node: Control, al: float, at: float, ar: float, ab: float) -> void:
	node.anchor_left   = al;  node.anchor_top    = at
	node.anchor_right  = ar;  node.anchor_bottom = ab
	node.offset_left   = 48;  node.offset_top    = 0
	node.offset_right  = -48; node.offset_bottom = 0
	add_child(node)


# ══════════════════════════════════════════════════════════════════════════════
# HEADER
# ══════════════════════════════════════════════════════════════════════════════

func _build_header() -> Control:
	var lbl := Label.new()
	lbl.text = "KHO VŨ KHÍ"
	lbl.add_theme_font_size_override("font_size", 88)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl


# ══════════════════════════════════════════════════════════════════════════════
# WEAPON LIST
# ══════════════════════════════════════════════════════════════════════════════

func _build_weapon_list() -> Control:
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	_scroll.add_child(vbox)

	return _scroll


func _refresh_weapon_list() -> void:
	var vbox := _scroll.get_child(0) as VBoxContainer
	for child in vbox.get_children():
		child.queue_free()

	vbox.add_child(_build_equipped_summary())

	var all_weapons := InventorySystem.get_weapons()
	if all_weapons.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Chưa có vũ khí nào.\nHãy rèn trước!"
		empty_lbl.add_theme_font_size_override("font_size", 52)
		empty_lbl.add_theme_color_override("font_color", Color(0.45, 0.42, 0.36))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(empty_lbl)
		return

	for fd: Dictionary in all_weapons:
		var combat_w: Dictionary = ForgeConverter.forge_to_combat(fd)
		var panel := _build_weapon_card(fd, combat_w)
		vbox.add_child(panel)


func _build_weapon_card(fd: Dictionary, cw: Dictionary) -> PanelContainer:
	var rarity: int    = cw.get("rarity_tier", 2)
	var r_color: Color = RARITY_COLORS[clampi(rarity - 1, 0, 4)]

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_card_style(panel, r_color)

	var inner := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		inner.add_theme_constant_override(side, 20)
	panel.add_child(inner)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	inner.add_child(col)

	# Tên vũ khí và nút trang bị
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 16)
	col.add_child(header_row)

	var name_lbl := Label.new()
	name_lbl.text = cw.get("weapon_name", "???")
	name_lbl.add_theme_font_size_override("font_size", 52)
	name_lbl.add_theme_color_override("font_color", r_color)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(name_lbl)

	var equip_btn := Button.new()
	equip_btn.text = _get_equip_button_text(cw)
	equip_btn.disabled = _get_equipped_slot(cw) != -1
	equip_btn.add_theme_font_size_override("font_size", 34)
	equip_btn.custom_minimum_size = Vector2(220, 64)
	equip_btn.pressed.connect(_on_equip_pressed.bind(cw))
	header_row.add_child(equip_btn)

	# Rarity
	var rarity_lbl := Label.new()
	rarity_lbl.text = RARITY_NAMES[clampi(rarity - 1, 0, 4)]
	rarity_lbl.add_theme_font_size_override("font_size", 34)
	rarity_lbl.add_theme_color_override("font_color", Color(r_color.r, r_color.g, r_color.b, 0.75))
	col.add_child(rarity_lbl)

	# Stats
	var stats_parts: Array[String] = []
	stats_parts.append("ATK %d" % cw.get("atk", 0))
	if cw.get("def_stat", 0) > 0:
		stats_parts.append("DEF %d" % cw.get("def_stat", 0))
	if cw.get("magic", 0) > 0:
		stats_parts.append("MAG %d" % cw.get("magic", 0))
	stats_parts.append("SPD %d" % cw.get("speed", 5))
	var stats_lbl := Label.new()
	stats_lbl.text = "  ·  ".join(stats_parts)
	stats_lbl.add_theme_font_size_override("font_size", 38)
	stats_lbl.add_theme_color_override("font_color", Color(0.72, 0.70, 0.62))
	col.add_child(stats_lbl)

	# Skills
	var s1: Dictionary = cw.get("skill1", {})
	var s2: Dictionary = cw.get("skill2", {})
	var s1_text := "—"
	if not s1.is_empty():
		s1_text = "%s [%dSTA]" % [s1.get("name", "—"), s1.get("stamina_cost", 0)]
	var s2_text := "—"
	if not s2.is_empty():
		s2_text = "%s [%dSTA]" % [s2.get("name", "—"), s2.get("stamina_cost", 0)]
	var skill_lbl := Label.new()
	skill_lbl.text = "Skill 1: %s   |   Skill 2: %s" % [s1_text, s2_text]
	skill_lbl.add_theme_font_size_override("font_size", 36)
	skill_lbl.add_theme_color_override("font_color", Color(0.58, 0.72, 0.88))
	skill_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(skill_lbl)

	# Vật liệu + giá ước tính
	var mat_name: String  = fd.get("material_name", "")
	var price_mult: float = fd.get("price_mult", 1.0)
	var base_atk: int     = fd.get("base_atk", 10)
	var est_price: int    = int(base_atk * 15.0 * price_mult)
	var meta_lbl := Label.new()
	var meta_parts: Array[String] = []
	if mat_name != "":
		meta_parts.append("Vật liệu: %s" % mat_name)
	meta_parts.append("Giá ước tính: ~%dG" % est_price)
	meta_lbl.text = "  ·  ".join(meta_parts)
	meta_lbl.add_theme_font_size_override("font_size", 34)
	meta_lbl.add_theme_color_override("font_color", Color(0.55, 0.52, 0.42))
	col.add_child(meta_lbl)

	return panel


func _build_equipped_summary() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_card_style(panel, Color(0.95, 0.82, 0.5))

	var inner := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		inner.add_theme_constant_override(side, 18)
	panel.add_child(inner)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	inner.add_child(col)

	var title := Label.new()
	title.text = "ĐANG TRANG BỊ"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	col.add_child(title)

	for i in GameManager.equipped_weapons.size():
		var weapon: Dictionary = GameManager.equipped_weapons[i]
		var slot_lbl := Label.new()
		slot_lbl.text = "Ô %d: %s" % [i + 1, _get_equipped_name(weapon)]
		slot_lbl.add_theme_font_size_override("font_size", 32)
		slot_lbl.add_theme_color_override("font_color", Color(0.72, 0.70, 0.62))
		col.add_child(slot_lbl)

	return panel


func _on_equip_pressed(weapon: Dictionary) -> void:
	if _get_equipped_slot(weapon) != -1:
		return
	GameManager.equip_to_slot(_get_next_equip_slot(), weapon)
	_refresh_weapon_list()


func _get_next_equip_slot() -> int:
	for i in GameManager.equipped_weapons.size():
		if GameManager.equipped_weapons[i].is_empty():
			return i
	return 0


func _get_equip_button_text(weapon: Dictionary) -> String:
	var slot := _get_equipped_slot(weapon)
	if slot != -1:
		return "Ô %d" % (slot + 1)
	return "Trang Bị"


func _get_equipped_slot(weapon: Dictionary) -> int:
	for i in GameManager.equipped_weapons.size():
		if GameManager.equipped_weapons[i] == weapon:
			return i
	return -1


func _get_equipped_name(weapon: Dictionary) -> String:
	if weapon.is_empty():
		return "( Trống )"
	return weapon.get("weapon_name", "???")


# ══════════════════════════════════════════════════════════════════════════════
# FOOTER
# ══════════════════════════════════════════════════════════════════════════════

func _build_footer() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)

	var forge_btn := Button.new()
	forge_btn.text = "[ Tiếp tục Rèn ]"
	forge_btn.add_theme_font_size_override("font_size", 48)
	forge_btn.custom_minimum_size = Vector2(400, 80)
	forge_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/forge/MaterialPicker.tscn"))
	row.add_child(forge_btn)

	var hub_btn := Button.new()
	hub_btn.text = "[ Quay về Xưởng ]"
	hub_btn.add_theme_font_size_override("font_size", 48)
	hub_btn.custom_minimum_size = Vector2(440, 80)
	hub_btn.pressed.connect(func() -> void:
		SceneManager.go_to("res://scenes/main/WorkshopHub.tscn"))
	row.add_child(hub_btn)

	return row


# ══════════════════════════════════════════════════════════════════════════════
# INPUT
# ══════════════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo or not event.pressed:
		return
	if event.keycode == KEY_ESCAPE:
		SceneManager.go_to("res://scenes/main/WorkshopHub.tscn")


# ══════════════════════════════════════════════════════════════════════════════
# STYLE
# ══════════════════════════════════════════════════════════════════════════════

func _apply_card_style(panel: PanelContainer, accent: Color) -> void:
	var s := StyleBoxFlat.new()
	s.set_corner_radius_all(8)
	s.bg_color     = Color(0.12, 0.11, 0.10)
	s.border_color = Color(accent.r * 0.5, accent.g * 0.5, accent.b * 0.5)
	s.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", s)
