# scripts/ui/inventory_panel.gd
# Overlay panel dùng chung cho 2 pha:
#   SHOP  — bày vũ khí lên Bàn Trưng Bày 2x2 (4 ô chuẩn 32-bit)
#   FORGE — chọn vũ khí để rèn tiếp
class_name InventoryPanel
extends CanvasLayer

# ══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ══════════════════════════════════════════════════════════════════════════════

signal slot_weapon_changed(slot_idx: int, weapon: Dictionary)
signal weapon_chosen_for_forge(weapon: Dictionary)

# ══════════════════════════════════════════════════════════════════════════════
# CONSTANTS
# ══════════════════════════════════════════════════════════════════════════════

enum Mode { SHOP, FORGE }

const PW := 860
const PH := 620
const C_SEP := Color(0.56, 0.40, 0.20, 0.65)
const C_TEXT := Color(0.96, 0.88, 0.72)
const C_MUTE := Color(0.70, 0.58, 0.42)
const C_GOLD := Color(0.96, 0.78, 0.35)
const C_SLOT_EMPTY := Color(0.16, 0.10, 0.08, 0.86)
const C_SLOT_FILLED := Color(0.14, 0.24, 0.14, 0.90)
const WEAPON_SPRITE_DIR := "res://assets/pixel/sprites/weapons/"

const RARITY_COLORS: Array[Color] = [
	Color(0.62, 0.62, 0.62),   # 0 — thường
	Color(0.32, 0.72, 0.36),   # 1 — tốt
	Color(0.28, 0.58, 0.90),   # 2 — hiếm
	Color(0.72, 0.32, 0.88),   # 3 — sử thi
	Color(0.96, 0.78, 0.24),   # 4 — kiệt tác
]

# ══════════════════════════════════════════════════════════════════════════════
# STATE
# ══════════════════════════════════════════════════════════════════════════════

var _mode: Mode = Mode.SHOP
var _weapons: Array = []
var _shelf_slots: Array = []
var _shelf_idx: int = -1
var _shelf_groups: Array = []

# Nodes
var _root: Control
var _panel_holder: Control
var _lbl_title: Label
var _content_root: Control
var _dynamic_nodes: Array = []


# ══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	layer = 18
	visible = false
	_build_skeleton()
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_recenter_panel):
		vp.size_changed.connect(_recenter_panel)


# ══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ══════════════════════════════════════════════════════════════════════════════

func open_shop(
	weapons: Array,
	shelf_idx: int,
	shelf_slots: Array,
	shelf_groups: Array = []
) -> void:
	_mode = Mode.SHOP
	_weapons = weapons
	_shelf_idx = shelf_idx
	_shelf_slots = shelf_slots
	_shelf_groups = shelf_groups
	_lbl_title.text = "%s  —  Bày Hàng" % _get_shelf_name(shelf_idx)
	_recenter_panel()
	_rebuild_content()
	visible = true


func open_forge(weapons: Array) -> void:
	_mode = Mode.FORGE
	_weapons = weapons
	_lbl_title.text = "Kho Vũ Khí  —  Chọn để Rèn Tiếp"
	_recenter_panel()
	_rebuild_content()
	visible = true


func close() -> void:
	visible = false
	_clear_dynamic()


func refresh() -> void:
	if visible:
		_rebuild_content()


# ══════════════════════════════════════════════════════════════════════════════
# INPUT
# ══════════════════════════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


# ══════════════════════════════════════════════════════════════════════════════
# BUILD — skeleton cố định, tự căn giữa theo mọi kích thước cửa sổ
# ══════════════════════════════════════════════════════════════════════════════

func _build_skeleton() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_root.add_child(HoaTamUI.make_dim_backdrop())

	_panel_holder = Control.new()
	_panel_holder.size = Vector2(PW, PH)
	_panel_holder.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_panel_holder)

	var panel := HoaTamUI.make_panel_container(false, 0.0)
	panel.add_theme_stylebox_override("panel", HoaTamUI.make_leather_chest_style(0.0))
	panel.position = Vector2.ZERO
	panel.size = Vector2(PW, PH)
	_panel_holder.add_child(panel)

	var font_px := load(HoaTamUI.FONT_PIXEL) as Font

	_lbl_title = Label.new()
	_lbl_title.position = Vector2(20, 14)
	_lbl_title.size = Vector2(PW - 76, 34)
	_lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font_px != null:
		_lbl_title.add_theme_font_override("font", font_px)
	_lbl_title.add_theme_font_size_override("font_size", 22)
	_lbl_title.add_theme_color_override("font_color", HoaTamUI.COL_GOLD)
	_panel_holder.add_child(_lbl_title)

	var close_btn := Button.new()
	close_btn.position = Vector2(PW - 54, 12)
	close_btn.size = Vector2(38, 36)
	close_btn.text = "X"
	HoaTamUI.apply_secondary_button(close_btn, 18)
	close_btn.pressed.connect(close)
	_panel_holder.add_child(close_btn)

	var sep := ColorRect.new()
	sep.position = Vector2(20, 54)
	sep.size = Vector2(PW - 40, 2)
	sep.color = C_SEP
	_panel_holder.add_child(sep)

	_content_root = Control.new()
	_content_root.position = Vector2(20, 62)
	_content_root.size = Vector2(PW - 40, PH - 82)
	_content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_holder.add_child(_content_root)

	_recenter_panel()


func _recenter_panel() -> void:
	if _panel_holder == null:
		return
	var vp_size := get_viewport().get_visible_rect().size
	_panel_holder.position = Vector2(
		roundf((vp_size.x - float(PW)) * 0.5),
		roundf((vp_size.y - float(PH)) * 0.5)
	)


# ══════════════════════════════════════════════════════════════════════════════
# BUILD — nội dung động
# ══════════════════════════════════════════════════════════════════════════════

func _rebuild_content() -> void:
	_clear_dynamic()
	if _mode == Mode.SHOP:
		_build_shop_content()
	else:
		_build_forge_content()


func _clear_dynamic() -> void:
	for n in _dynamic_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_dynamic_nodes.clear()


# ── SHOP mode ─────────────────────────────────────────────────────────────────

func _build_shop_content() -> void:
	var cw: float = _content_root.size.x
	var ch: float = _content_root.size.y
	var slot_indices := _get_current_group_slot_indices()

	_add_section_label("4 Ô Bàn Giữa (bố cục 2×2 khớp mặt bàn)", 0)

	# Hiển thị các ô trưng bày dạng lưới 2 cột (khớp trực tiếp 2x2 trên bàn tiệm)
	var cols: int = 2 if slot_indices.size() >= 2 else 1
	var gap_x: float = 12.0
	var gap_y: float = 8.0
	var cell_w: float = floorf((cw - gap_x * float(cols - 1)) / float(cols))
	var cell_h: float = 56.0
	var start_y: float = 26.0

	for i: int in slot_indices.size():
		var col_i: int = i % cols
		var row_i: int = floori(float(i) / float(cols))
		var rx: float = float(col_i) * (cell_w + gap_x)
		var ry: float = start_y + float(row_i) * (cell_h + gap_y)
		_build_slot_cell(slot_indices[i], Rect2(rx, ry, cell_w, cell_h))

	var rows_used: int = ceili(float(maxi(1, slot_indices.size())) / float(cols))
	var next_y: float = start_y + float(rows_used) * (cell_h + gap_y) + 4.0

	var sep := ColorRect.new()
	sep.position = Vector2(0, next_y)
	sep.size = Vector2(cw, 2)
	sep.color = C_SEP
	_content_root.add_child(sep)
	_dynamic_nodes.append(sep)

	var inv_lbl := Label.new()
	inv_lbl.text = "Kho vũ khí (%d món)" % _weapons.size()
	inv_lbl.position = Vector2(2, next_y + 8)
	inv_lbl.size = Vector2(360, 24)
	inv_lbl.add_theme_font_size_override("font_size", 17)
	inv_lbl.add_theme_color_override("font_color", C_MUTE)
	_content_root.add_child(inv_lbl)
	_dynamic_nodes.append(inv_lbl)

	var scroll_y: float = next_y + 36.0
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, scroll_y)
	scroll.size = Vector2(cw, maxf(120.0, ch - scroll_y))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_root.add_child(scroll)
	_dynamic_nodes.append(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	if _weapons.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Kho đang trống — hãy quay về Xưởng Rèn để tạo vũ khí mới."
		empty_lbl.custom_minimum_size = Vector2(cw - 20.0, 60.0)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 17)
		empty_lbl.add_theme_color_override("font_color", C_MUTE)
		vbox.add_child(empty_lbl)
		return

	for w: Dictionary in _weapons:
		vbox.add_child(_build_shop_weapon_card(w, cw - 16.0))


func _add_section_label(text: String, y: int) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(2, y)
	lbl.size = Vector2(_content_root.size.x, 22)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", C_MUTE)
	_content_root.add_child(lbl)
	_dynamic_nodes.append(lbl)


func _build_slot_cell(slot_idx: int, rect: Rect2) -> void:
	var slot: Dictionary = _shelf_slots[slot_idx] if slot_idx < _shelf_slots.size() else {}
	var weapon: Dictionary = slot.get("weapon", {})
	var has_wpn := not weapon.is_empty()

	var holder := Panel.new()
	holder.position = rect.position
	holder.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = C_SLOT_FILLED if has_wpn else C_SLOT_EMPTY
	style.border_color = HoaTamUI.COL_GOLD if has_wpn else Color(0.45, 0.32, 0.19, 0.72)
	style.set_border_width_all(2)
	holder.add_theme_stylebox_override("panel", style)
	_content_root.add_child(holder)
	_dynamic_nodes.append(holder)

	if has_wpn:
		var tier: int = int(weapon.get("rarity_tier", 1))
		var acc := ColorRect.new()
		acc.position = Vector2(2, 2)
		acc.size = Vector2(4, rect.size.y - 4)
		acc.color = RARITY_COLORS[clampi(tier - 1, 0, RARITY_COLORS.size() - 1)]
		holder.add_child(acc)

		var icon := _make_weapon_icon_rect(weapon, Vector2(40, 40))
		icon.position = Vector2(10, 8)
		holder.add_child(icon)

	var text_x: float = 56.0 if has_wpn else 12.0
	var text_w: float = rect.size.x - text_x - (90.0 if has_wpn else 12.0)

	var wpn_name: String = String(weapon.get("weapon_name", "( Trống )")) if has_wpn else "( Trống )"
	var name_lbl := Label.new()
	name_lbl.text = "%s · %s" % [_get_slot_name(slot_idx), wpn_name]
	name_lbl.position = Vector2(text_x, 6)
	name_lbl.size = Vector2(text_w, 22)
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", C_TEXT if has_wpn else C_MUTE)
	holder.add_child(name_lbl)

	if has_wpn:
		var stats_lbl := Label.new()
		stats_lbl.text = "ATK %d · MAG %d · SPD %d" % [
			int(weapon.get("atk", 0)),
			int(weapon.get("magic", 0)),
			int(weapon.get("speed", 0)),
		]
		stats_lbl.position = Vector2(text_x, 30)
		stats_lbl.size = Vector2(text_w, 18)
		stats_lbl.clip_text = true
		stats_lbl.add_theme_font_size_override("font_size", 13)
		stats_lbl.add_theme_color_override("font_color", C_MUTE)
		holder.add_child(stats_lbl)

		var clr_btn := Button.new()
		clr_btn.text = "Cất đi"
		clr_btn.position = Vector2(rect.size.x - 84, 11)
		clr_btn.size = Vector2(76, 34)
		HoaTamUI.apply_secondary_button(clr_btn, 14)
		clr_btn.pressed.connect(_on_clear_slot.bind(slot_idx))
		holder.add_child(clr_btn)
	else:
		var hint_lbl := Label.new()
		hint_lbl.text = "Chọn nút %s ở kho dưới" % _get_slot_name(slot_idx)
		hint_lbl.position = Vector2(text_x, 30)
		hint_lbl.size = Vector2(text_w, 18)
		hint_lbl.add_theme_font_size_override("font_size", 13)
		hint_lbl.add_theme_color_override("font_color", Color(0.54, 0.44, 0.32))
		holder.add_child(hint_lbl)


func _build_shop_weapon_card(w: Dictionary, card_w: float) -> Control:
	var tier: int = int(w.get("rarity_tier", 1))
	var rarity_col := RARITY_COLORS[clampi(tier - 1, 0, RARITY_COLORS.size() - 1)]

	var card := Panel.new()
	card.custom_minimum_size = Vector2(card_w, 84.0)
	var style := HoaTamUI.make_inset_surface_style(0.76, 0.0, Color(0.45, 0.32, 0.19, 0.7))
	card.add_theme_stylebox_override("panel", style)

	var acc := ColorRect.new()
	acc.position = Vector2(1, 1)
	acc.size = Vector2(5, 82)
	acc.color = rarity_col
	card.add_child(acc)

	var icon_box := ColorRect.new()
	icon_box.position = Vector2(14, 12)
	icon_box.size = Vector2(60, 60)
	icon_box.color = Color(0.14, 0.09, 0.07, 0.92)
	card.add_child(icon_box)

	var icon := _make_weapon_icon_rect(w, Vector2(52, 52))
	icon.position = Vector2(18, 16)
	card.add_child(icon)

	var slot_indices := _get_current_group_slot_indices()
	var btn_cols: int = mini(2, maxi(1, slot_indices.size()))
	var btn_area_w: float = float(btn_cols) * 108.0 + 16.0
	var info_w: float = maxf(200.0, card_w - 90.0 - btn_area_w)

	var name_lbl := Label.new()
	name_lbl.text = String(w.get("weapon_name", "?"))
	name_lbl.position = Vector2(86, 8)
	name_lbl.size = Vector2(info_w, 24)
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", 19)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	card.add_child(name_lbl)

	var stat_lbl := Label.new()
	stat_lbl.text = "ATK %d  ·  DEF %d  ·  MAG %d  ·  SPD %d" % [
		int(w.get("atk", 0)),
		int(w.get("def_stat", 0)),
		int(w.get("magic", 0)),
		int(w.get("speed", 0)),
	]
	stat_lbl.position = Vector2(86, 35)
	stat_lbl.size = Vector2(info_w, 20)
	stat_lbl.clip_text = true
	stat_lbl.add_theme_font_size_override("font_size", 15)
	stat_lbl.add_theme_color_override("font_color", C_MUTE)
	card.add_child(stat_lbl)

	var location := _get_weapon_location_text(w)
	var loc_lbl := Label.new()
	loc_lbl.text = location
	loc_lbl.position = Vector2(86, 58)
	loc_lbl.size = Vector2(info_w, 18)
	loc_lbl.add_theme_font_size_override("font_size", 14)
	loc_lbl.add_theme_color_override("font_color", C_GOLD if location != "Trong kho" else C_MUTE)
	card.add_child(loc_lbl)

	var placed_slot := _get_placed_slot(w)
	for i: int in slot_indices.size():
		var slot_idx: int = slot_indices[i]
		var on_slot := (placed_slot == slot_idx)
		var is_placed_elsewhere := (placed_slot != -1 and not on_slot)
		var btn := Button.new()
		btn.text = ("✓ %s" % _get_slot_name(slot_idx)) if on_slot else _get_slot_name(slot_idx)
		var col_i: int = i % 2
		var row_i: int = floori(float(i) / 2.0)
		var bx: float = card_w - btn_area_w + 6.0 + float(col_i) * 108.0
		var by: float = (24.0 if slot_indices.size() <= 2 else 8.0) + float(row_i) * 36.0
		btn.position = Vector2(bx, by)
		btn.size = Vector2(102, 32)
		if on_slot:
			HoaTamUI.apply_primary_button(btn, 14)
		else:
			HoaTamUI.apply_secondary_button(btn, 14)
		btn.disabled = on_slot or is_placed_elsewhere
		if not btn.disabled:
			btn.pressed.connect(_on_place_weapon.bind(slot_idx, w))
		card.add_child(btn)

	return card


# ── FORGE mode ────────────────────────────────────────────────────────────────

func _build_forge_content() -> void:
	var cw: float = _content_root.size.x
	var ch: float = _content_root.size.y

	var inv_lbl := Label.new()
	inv_lbl.text = "Chọn vũ khí để tiếp tục rèn:"
	inv_lbl.position = Vector2(2, 4)
	inv_lbl.size = Vector2(400, 24)
	inv_lbl.add_theme_font_size_override("font_size", 18)
	inv_lbl.add_theme_color_override("font_color", C_MUTE)
	_content_root.add_child(inv_lbl)
	_dynamic_nodes.append(inv_lbl)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 34)
	scroll.size = Vector2(cw, ch - 34)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_root.add_child(scroll)
	_dynamic_nodes.append(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	for w: Dictionary in _weapons:
		vbox.add_child(_build_forge_weapon_card(w, cw - 16.0))


func _build_forge_weapon_card(w: Dictionary, card_w: float) -> Control:
	var tier: int = int(w.get("rarity_tier", 1))
	var rarity_col := RARITY_COLORS[clampi(tier - 1, 0, RARITY_COLORS.size() - 1)]

	var card := Panel.new()
	card.custom_minimum_size = Vector2(card_w, 84.0)
	card.add_theme_stylebox_override(
		"panel",
		HoaTamUI.make_inset_surface_style(0.76, 0.0, Color(0.45, 0.32, 0.19, 0.7))
	)

	var acc := ColorRect.new()
	acc.position = Vector2(1, 1)
	acc.size = Vector2(5, 82)
	acc.color = rarity_col
	card.add_child(acc)

	var icon := _make_weapon_icon_rect(w, Vector2(52, 52))
	icon.position = Vector2(18, 16)
	card.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = String(w.get("weapon_name", "?"))
	name_lbl.position = Vector2(86, 8)
	name_lbl.size = Vector2(card_w - 246.0, 24)
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", 19)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	card.add_child(name_lbl)

	var stat_lbl := Label.new()
	stat_lbl.text = "ATK %d  ·  DEF %d  ·  MAG %d  ·  SPD %d" % [
		int(w.get("atk", 0)),
		int(w.get("def_stat", 0)),
		int(w.get("magic", 0)),
		int(w.get("speed", 0)),
	]
	stat_lbl.position = Vector2(86, 35)
	stat_lbl.size = Vector2(card_w - 246.0, 20)
	stat_lbl.add_theme_font_size_override("font_size", 15)
	stat_lbl.add_theme_color_override("font_color", C_MUTE)
	card.add_child(stat_lbl)

	var tier_lbl := Label.new()
	tier_lbl.text = _rarity_name(tier)
	tier_lbl.position = Vector2(86, 58)
	tier_lbl.size = Vector2(card_w - 246.0, 18)
	tier_lbl.add_theme_font_size_override("font_size", 14)
	tier_lbl.add_theme_color_override("font_color", rarity_col)
	card.add_child(tier_lbl)

	var forge_btn := Button.new()
	forge_btn.text = "Rèn Tiếp"
	forge_btn.position = Vector2(card_w - 146.0, 23)
	forge_btn.size = Vector2(134, 38)
	HoaTamUI.apply_primary_button(forge_btn, 16)
	forge_btn.pressed.connect(_on_choose_for_forge.bind(w))
	card.add_child(forge_btn)

	return card


# ══════════════════════════════════════════════════════════════════════════════
# CALLBACKS
# ══════════════════════════════════════════════════════════════════════════════

func _on_place_weapon(slot_idx: int, weapon: Dictionary) -> void:
	var old_slot := _get_placed_slot(weapon)
	if old_slot != -1 and old_slot != slot_idx:
		slot_weapon_changed.emit(old_slot, {})
	slot_weapon_changed.emit(slot_idx, weapon)
	_rebuild_content()


func _on_clear_slot(slot_idx: int) -> void:
	slot_weapon_changed.emit(slot_idx, {})
	_rebuild_content()


func _on_choose_for_forge(weapon: Dictionary) -> void:
	weapon_chosen_for_forge.emit(weapon)
	close()


# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _make_weapon_icon_rect(w: Dictionary, icon_size: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.size = icon_size
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex := _resolve_weapon_texture(w)
	if tex != null:
		tr.texture = tex
	return tr


func _resolve_weapon_texture(w: Dictionary) -> Texture2D:
	var sprite_path := String(w.get("sprite_path", ""))
	if sprite_path.begins_with("res://assets/pixel/") and ResourceLoader.exists(sprite_path):
		return load(sprite_path) as Texture2D
	var blank_id := String(w.get("blank_id", ""))
	if not blank_id.is_empty():
		var by_blank := "%s%s.png" % [WEAPON_SPRITE_DIR, blank_id]
		if ResourceLoader.exists(by_blank):
			return load(by_blank) as Texture2D
	var fallback := "%skiem_don.png" % WEAPON_SPRITE_DIR
	return load(fallback) as Texture2D if ResourceLoader.exists(fallback) else null


func _get_placed_slot(w: Dictionary) -> int:
	if w.is_empty():
		return -1
	for i: int in _shelf_slots.size():
		if _shelf_slots[i].get("weapon", {}) == w:
			return i
	return -1


func _slot_has_weapon(slot_idx: int, w: Dictionary) -> bool:
	if slot_idx < 0 or slot_idx >= _shelf_slots.size():
		return false
	return _shelf_slots[slot_idx].get("weapon", {}) == w


func _is_on_other_shelf(w: Dictionary) -> bool:
	for i: int in _shelf_slots.size():
		if _shelf_slots[i].get("weapon", {}) == w:
			var this_shelf := _get_group_idx_for_slot(i)
			if this_shelf != _shelf_idx:
				return true
	return false


func _get_weapon_location_text(w: Dictionary) -> String:
	for i: int in _shelf_slots.size():
		if _shelf_slots[i].get("weapon", {}) == w:
			return "%s · %s" % [
				_get_shelf_name(_get_group_idx_for_slot(i)),
				_get_slot_name(i),
			]
	return "Trong kho"


func _get_current_group_slot_indices() -> Array:
	if _shelf_idx >= 0 and _shelf_idx < _shelf_groups.size():
		return _shelf_groups[_shelf_idx].get("slots", [])
	return [_shelf_idx * 2, _shelf_idx * 2 + 1]


func _get_group_idx_for_slot(slot_idx: int) -> int:
	for group_idx: int in _shelf_groups.size():
		var slots: Array = _shelf_groups[group_idx].get("slots", [])
		if slot_idx in slots:
			return group_idx
	return floori(float(slot_idx) / 2.0)


func _get_shelf_name(shelf_idx: int) -> String:
	if shelf_idx >= 0 and shelf_idx < _shelf_groups.size():
		return String(_shelf_groups[shelf_idx].get("name", "Kệ"))
	return "Kệ %d" % (shelf_idx + 1)


func _get_slot_name(slot_idx: int) -> String:
	var group_idx := _get_group_idx_for_slot(slot_idx)
	if group_idx >= 0 and group_idx < _shelf_groups.size():
		var group: Dictionary = _shelf_groups[group_idx]
		var slot_names: Array = group.get("slot_names", [])
		var slots: Array = group.get("slots", [])
		var local_idx := slots.find(slot_idx)
		if local_idx >= 0 and local_idx < slot_names.size():
			return String(slot_names[local_idx])
		var configured_name: String = String(group.get("slot_name", ""))
		if not configured_name.is_empty():
			return configured_name
		if local_idx >= 0:
			return "Ô %d" % (local_idx + 1)
	return "Ô %d" % (slot_idx + 1)


func _rarity_name(tier: int) -> String:
	match tier:
		1: return "Thường"
		2: return "Tốt"
		3: return "Hiếm"
		4: return "Sử Thi"
		5: return "Kiệt Tác"
		_: return ""
