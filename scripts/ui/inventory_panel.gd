# scripts/ui/inventory_panel.gd
# Overlay panel dùng chung cho 2 pha:
#   SHOP  — chọn vũ khí đặt lên kệ (2 hàng × 3 kệ)
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

const PW := 820; const PH := 600
const C_FRAME := Color(0.72, 0.54, 0.24)
const C_PANEL := Color(0.13, 0.08, 0.05)
const C_HDR   := Color(0.20, 0.13, 0.07)
const C_SEP   := Color(0.42, 0.28, 0.12, 0.6)
const C_TEXT  := Color(0.96, 0.88, 0.72)
const C_MUTE  := Color(0.64, 0.52, 0.36)
const C_GOLD  := Color(1.00, 0.84, 0.26)
const C_SLOT_EMPTY := Color(0.22, 0.14, 0.07)
const C_SLOT_FILLED := Color(0.16, 0.28, 0.14)

# Màu rarity
const RARITY_COLORS: Array[Color] = [
	Color(0.55, 0.55, 0.55),   # 0 — thường
	Color(0.28, 0.64, 0.28),   # 1 — tốt
	Color(0.22, 0.48, 0.82),   # 2 — hiếm
	Color(0.64, 0.22, 0.82),   # 3 — sử thi
	Color(0.90, 0.72, 0.18),   # 4 — kiệt tác
]

# ══════════════════════════════════════════════════════════════════════════════
# STATE
# ══════════════════════════════════════════════════════════════════════════════

var _mode:       Mode = Mode.SHOP
var _weapons:    Array = []           # toàn bộ kho
var _shelf_slots: Array = []          # ref tới _shelf_slots của shop_scene (SHOP mode)
var _shelf_idx:  int = -1             # kệ đang chọn (SHOP mode)
var _shelf_groups: Array = []         # cấu hình nhóm slot từ ShopScene

# Nodes
var _root:         Control
var _lbl_title:    Label
var _content_root: Control            # vùng nội dung thay đổi theo mode

# Dynamic children (xóa/tạo lại mỗi lần open)
var _dynamic_nodes: Array = []

# ══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	layer   = 18
	visible = false
	_build_skeleton()


# ══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ══════════════════════════════════════════════════════════════════════════════

func open_shop(
	weapons: Array,
	shelf_idx: int,
	shelf_slots: Array,
	shelf_groups: Array = []
) -> void:
	_mode       = Mode.SHOP
	_weapons    = weapons
	_shelf_idx  = shelf_idx
	_shelf_slots = shelf_slots
	_shelf_groups = shelf_groups
	_lbl_title.text = "%s  —  Bày Hàng" % _get_shelf_name(shelf_idx)
	_rebuild_content()
	visible = true


func open_forge(weapons: Array) -> void:
	_mode    = Mode.FORGE
	_weapons = weapons
	_lbl_title.text = "Kho Vũ Khí  —  Chọn để Rèn Tiếp"
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
# BUILD — skeleton cố định
# ══════════════════════════════════════════════════════════════════════════════

func _build_skeleton() -> void:
	var vp_size := Vector2(1024, 768)
	var bx := int((vp_size.x - PW) * 0.5)
	var by := int((vp_size.y - PH) * 0.5)

	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	# Overlay
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 0.60)
	_root.add_child(ov)

	# Border + panel
	var border := ColorRect.new()
	border.position = Vector2(bx - 2, by - 2)
	border.size     = Vector2(PW + 4, PH + 4)
	border.color    = C_FRAME
	_root.add_child(border)

	var panel := ColorRect.new()
	panel.position = Vector2(bx, by)
	panel.size     = Vector2(PW, PH)
	panel.color    = C_PANEL
	_root.add_child(panel)

	# Header
	var hdr := ColorRect.new()
	hdr.position = Vector2(bx, by)
	hdr.size     = Vector2(PW, 48)
	hdr.color    = C_HDR
	_root.add_child(hdr)

	_lbl_title = Label.new()
	_lbl_title.position = Vector2(bx, by + 8)
	_lbl_title.size     = Vector2(PW - 48, 32)
	_lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_title.add_theme_font_size_override("font_size", 23)
	_lbl_title.add_theme_color_override("font_color", C_TEXT)
	_root.add_child(_lbl_title)

	# Nút đóng [X]
	var close_btn := Button.new()
	close_btn.position = Vector2(bx + PW - 42, by + 6)
	close_btn.size     = Vector2(36, 36)
	close_btn.text     = "✕"
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(close)
	_root.add_child(close_btn)

	# Separator header
	var sep := ColorRect.new()
	sep.position = Vector2(bx + 8, by + 48)
	sep.size     = Vector2(PW - 16, 1)
	sep.color    = C_SEP
	_root.add_child(sep)

	# Vùng nội dung — bên dưới header
	_content_root = Control.new()
	_content_root.position = Vector2(bx, by + 52)
	_content_root.size     = Vector2(PW, PH - 52)
	_content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_content_root)


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
	var slot_indices := _get_current_group_slot_indices()
	_add_section_label("Ô trưng bày", 4)
	var next_y := 28
	for slot_idx: int in slot_indices:
		_build_slot_row(slot_idx, next_y)
		next_y += 52

	# Separator
	var sep := ColorRect.new()
	sep.position = Vector2(8, next_y)
	sep.size     = Vector2(PW - 16, 1)
	sep.color    = C_SEP
	_content_root.add_child(sep)
	_dynamic_nodes.append(sep)

	# Phần 2: danh sách vũ khí
	var inv_lbl := Label.new()
	inv_lbl.text     = "Kho vũ khí"
	inv_lbl.position = Vector2(12, next_y + 4)
	inv_lbl.size     = Vector2(200, 22)
	inv_lbl.add_theme_font_size_override("font_size", 18)
	inv_lbl.add_theme_color_override("font_color", C_MUTE)
	_content_root.add_child(inv_lbl)
	_dynamic_nodes.append(inv_lbl)

	var list_y := next_y + 30
	for w: Dictionary in _weapons:
		_build_shop_weapon_card(w, list_y)
		list_y += 84


func _add_section_label(text: String, y: int) -> void:
	var lbl := Label.new()
	lbl.text     = text
	lbl.position = Vector2(12, y)
	lbl.size     = Vector2(200, 20)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", C_MUTE)
	_content_root.add_child(lbl)
	_dynamic_nodes.append(lbl)


func _build_slot_row(slot_idx: int, y: int) -> void:
	var slot: Dictionary = _shelf_slots[slot_idx] if slot_idx < _shelf_slots.size() else {}
	var weapon: Dictionary = slot.get("weapon", {})
	var has_wpn := not weapon.is_empty()

	# Ô kệ
	var slot_bg := ColorRect.new()
	slot_bg.position = Vector2(8, y)
	slot_bg.size     = Vector2(PW - 16, 44)
	slot_bg.color    = C_SLOT_FILLED if has_wpn else C_SLOT_EMPTY
	_content_root.add_child(slot_bg)
	_dynamic_nodes.append(slot_bg)

	# Accent rarity
	if has_wpn:
		var tier: int = weapon.get("rarity_tier", 0)
		var acc := ColorRect.new()
		acc.position = Vector2(8, y)
		acc.size     = Vector2(4, 44)
		acc.color    = RARITY_COLORS[mini(tier, RARITY_COLORS.size() - 1)]
		_content_root.add_child(acc)
		_dynamic_nodes.append(acc)

	# Tên vũ khí hoặc "(Trống)"
	var wpn_name: String = weapon.get("weapon_name", "( Trống )") if has_wpn else "( Trống )"
	var name_lbl := Label.new()
	name_lbl.text     = "%s · %s" % [_get_slot_name(slot_idx), wpn_name]
	name_lbl.position = Vector2(18, y + 4)
	name_lbl.size     = Vector2(PW - 220, 20)
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", C_TEXT if has_wpn else C_MUTE)
	_content_root.add_child(name_lbl)
	_dynamic_nodes.append(name_lbl)

	if has_wpn:
		var stats_lbl := Label.new()
		stats_lbl.text = "ATK %d  DEF %d  MAG %d  SPD %d" % [
			weapon.get("atk", 0), weapon.get("def_stat", 0),
			weapon.get("magic", 0), weapon.get("speed", 0)
		]
		stats_lbl.position = Vector2(18, y + 24)
		stats_lbl.size     = Vector2(PW - 220, 16)
		stats_lbl.add_theme_font_size_override("font_size", 14)
		stats_lbl.add_theme_color_override("font_color", C_MUTE)
		_content_root.add_child(stats_lbl)
		_dynamic_nodes.append(stats_lbl)

	# Nút Bỏ trống
	if has_wpn:
		var clr_btn := Button.new()
		clr_btn.text     = "Bỏ trống"
		clr_btn.position = Vector2(PW - 202, y + 7)
		clr_btn.size     = Vector2(96, 30)
		clr_btn.add_theme_font_size_override("font_size", 16)
		clr_btn.pressed.connect(_on_clear_slot.bind(slot_idx))
		_content_root.add_child(clr_btn)
		_dynamic_nodes.append(clr_btn)


func _build_shop_weapon_card(w: Dictionary, y: int) -> void:
	var tier: int = w.get("rarity_tier", 0)
	var rarity_col := RARITY_COLORS[mini(tier, RARITY_COLORS.size() - 1)]

	# Card nền
	var bg := ColorRect.new()
	bg.position = Vector2(8, y)
	bg.size     = Vector2(PW - 16, 78)
	bg.color    = Color(0.10, 0.07, 0.04)
	_content_root.add_child(bg)
	_dynamic_nodes.append(bg)

	# Accent rarity
	var acc := ColorRect.new()
	acc.position = Vector2(8, y)
	acc.size     = Vector2(5, 78)
	acc.color    = rarity_col
	_content_root.add_child(acc)
	_dynamic_nodes.append(acc)

	# Tên
	var name_lbl := Label.new()
	name_lbl.text     = w.get("weapon_name", "?")
	name_lbl.position = Vector2(20, y + 6)
	name_lbl.size     = Vector2(PW - 250, 24)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	_content_root.add_child(name_lbl)
	_dynamic_nodes.append(name_lbl)

	# Stats
	var stat_lbl := Label.new()
	stat_lbl.text = "ATK %d  ·  DEF %d  ·  MAG %d  ·  SPD %d" % [
		w.get("atk", 0), w.get("def_stat", 0), w.get("magic", 0), w.get("speed", 0)
	]
	stat_lbl.position = Vector2(20, y + 32)
	stat_lbl.size     = Vector2(PW - 250, 20)
	stat_lbl.add_theme_font_size_override("font_size", 16)
	stat_lbl.add_theme_color_override("font_color", C_MUTE)
	_content_root.add_child(stat_lbl)
	_dynamic_nodes.append(stat_lbl)

	# Vị trí trên kệ
	var location := _get_weapon_location_text(w)
	var loc_lbl := Label.new()
	loc_lbl.text     = location
	loc_lbl.position = Vector2(20, y + 52)
	loc_lbl.size     = Vector2(PW - 250, 18)
	loc_lbl.add_theme_font_size_override("font_size", 14)
	loc_lbl.add_theme_color_override("font_color", C_GOLD if location != "Trong kho" else C_MUTE)
	_content_root.add_child(loc_lbl)
	_dynamic_nodes.append(loc_lbl)

	# Nút đặt vũ khí vào từng ô của nhóm hiện tại
	var slot_indices := _get_current_group_slot_indices()
	var on_other  := _is_on_other_shelf(w)
	for i: int in slot_indices.size():
		var slot_idx: int = slot_indices[i]
		var on_slot := _slot_has_weapon(slot_idx, w)
		var btn := Button.new()
		btn.text = _get_slot_name(slot_idx)
		if on_slot:
			btn.text = "✓ %s" % _get_slot_name(slot_idx)
		btn.position = Vector2(PW - 222 + (i % 2) * 108, y + 6 + floori(i / 2.0) * 34)
		btn.size = Vector2(104, 30)
		btn.add_theme_font_size_override("font_size", 15)
		btn.disabled = on_slot or on_other
		if not on_slot and not on_other:
			btn.pressed.connect(_on_place_weapon.bind(slot_idx, w))
		_content_root.add_child(btn)
		_dynamic_nodes.append(btn)


# ── FORGE mode ────────────────────────────────────────────────────────────────

func _build_forge_content() -> void:
	var inv_lbl := Label.new()
	inv_lbl.text     = "Chọn vũ khí để tiếp tục rèn:"
	inv_lbl.position = Vector2(12, 8)
	inv_lbl.size     = Vector2(400, 24)
	inv_lbl.add_theme_font_size_override("font_size", 18)
	inv_lbl.add_theme_color_override("font_color", C_MUTE)
	_content_root.add_child(inv_lbl)
	_dynamic_nodes.append(inv_lbl)

	var list_y := 38
	for w: Dictionary in _weapons:
		_build_forge_weapon_card(w, list_y)
		list_y += 84


func _build_forge_weapon_card(w: Dictionary, y: int) -> void:
	var tier: int = w.get("rarity_tier", 0)
	var rarity_col := RARITY_COLORS[mini(tier, RARITY_COLORS.size() - 1)]

	var bg := ColorRect.new()
	bg.position = Vector2(8, y)
	bg.size     = Vector2(PW - 16, 78)
	bg.color    = Color(0.10, 0.07, 0.04)
	_content_root.add_child(bg)
	_dynamic_nodes.append(bg)

	var acc := ColorRect.new()
	acc.position = Vector2(8, y)
	acc.size     = Vector2(5, 78)
	acc.color    = rarity_col
	_content_root.add_child(acc)
	_dynamic_nodes.append(acc)

	var name_lbl := Label.new()
	name_lbl.text     = w.get("weapon_name", "?")
	name_lbl.position = Vector2(20, y + 6)
	name_lbl.size     = Vector2(PW - 170, 24)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	_content_root.add_child(name_lbl)
	_dynamic_nodes.append(name_lbl)

	var stat_lbl := Label.new()
	stat_lbl.text = "ATK %d  ·  DEF %d  ·  MAG %d  ·  SPD %d" % [
		w.get("atk", 0), w.get("def_stat", 0), w.get("magic", 0), w.get("speed", 0)
	]
	stat_lbl.position = Vector2(20, y + 32)
	stat_lbl.size     = Vector2(PW - 170, 20)
	stat_lbl.add_theme_font_size_override("font_size", 16)
	stat_lbl.add_theme_color_override("font_color", C_MUTE)
	_content_root.add_child(stat_lbl)
	_dynamic_nodes.append(stat_lbl)

	var tier_lbl := Label.new()
	tier_lbl.text = _rarity_name(tier)
	tier_lbl.position = Vector2(20, y + 54)
	tier_lbl.size     = Vector2(PW - 170, 18)
	tier_lbl.add_theme_font_size_override("font_size", 14)
	tier_lbl.add_theme_color_override("font_color", rarity_col)
	_content_root.add_child(tier_lbl)
	_dynamic_nodes.append(tier_lbl)

	var forge_btn := Button.new()
	forge_btn.text     = "Rèn Tiếp"
	forge_btn.position = Vector2(PW - 150, y + 22)
	forge_btn.size     = Vector2(134, 34)
	forge_btn.add_theme_font_size_override("font_size", 18)
	forge_btn.pressed.connect(_on_choose_for_forge.bind(w))
	_content_root.add_child(forge_btn)
	_dynamic_nodes.append(forge_btn)


# ══════════════════════════════════════════════════════════════════════════════
# CALLBACKS
# ══════════════════════════════════════════════════════════════════════════════

func _on_place_weapon(slot_idx: int, weapon: Dictionary) -> void:
	slot_weapon_changed.emit(slot_idx, weapon)
	_rebuild_content()   # refresh để cập nhật trạng thái nút


func _on_clear_slot(slot_idx: int) -> void:
	slot_weapon_changed.emit(slot_idx, {})
	_rebuild_content()


func _on_choose_for_forge(weapon: Dictionary) -> void:
	weapon_chosen_for_forge.emit(weapon)
	close()


# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _slot_has_weapon(slot_idx: int, w: Dictionary) -> bool:
	if slot_idx < 0 or slot_idx >= _shelf_slots.size():
		return false
	return _shelf_slots[slot_idx].get("weapon", {}) == w


func _is_on_other_shelf(w: Dictionary) -> bool:
	# Vũ khí đang ở kệ khác (không phải _shelf_idx hiện tại)
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
	return floori(slot_idx / 2.0)


func _get_shelf_name(shelf_idx: int) -> String:
	if shelf_idx >= 0 and shelf_idx < _shelf_groups.size():
		return _shelf_groups[shelf_idx].get("name", "Kệ")
	return "Kệ %d" % (shelf_idx + 1)


func _get_slot_name(slot_idx: int) -> String:
	var group_idx := _get_group_idx_for_slot(slot_idx)
	if group_idx >= 0 and group_idx < _shelf_groups.size():
		var group: Dictionary = _shelf_groups[group_idx]
		var configured_name: String = group.get("slot_name", "")
		if not configured_name.is_empty():
			return configured_name
		var slots: Array = group.get("slots", [])
		var local_idx := slots.find(slot_idx)
		if local_idx >= 0:
			return "Ô %d" % (local_idx + 1)
	return "Ô %d" % (slot_idx + 1)


func _rarity_name(tier: int) -> String:
	match tier:
		0: return "Thường"
		1: return "Tốt"
		2: return "Hiếm"
		3: return "Sử Thi"
		4: return "Kiệt Tác"
		_: return ""
