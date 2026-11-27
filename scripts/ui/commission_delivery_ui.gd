# Overlay giao vũ khí cho NPC đã đặt commission trong phiên shop.
class_name CommissionDeliveryUI
extends CanvasLayer

const ForgeConverter := preload("res://scripts/forge/weapon_data.gd")
const FONT_BOOK_PATH := "res://assets/fonts/Lora-Regular.ttf"
const FONT_BOOK_ITALIC_PATH := "res://assets/fonts/Lora-Italic.ttf"

const PANEL_SIZE := Vector2(840, 560)
const ROW_HEIGHT := 58

var _commission: CommissionData = null
var _customer_instance_id: int = -1
var _is_delivering: bool = false

var _font_book: Font = null
var _font_italic: Font = null
var _title_lbl: Label
var _flavor_lbl: Label
var _requirements_lbl: Label
var _weapon_list: VBoxContainer
var _status_lbl: Label


func _ready() -> void:
	layer = 19
	visible = false
	_font_book = load(FONT_BOOK_PATH) as Font
	_font_italic = load(FONT_BOOK_ITALIC_PATH) as Font
	_build_ui()
	EventBus.commission_giver_arrived.connect(_on_giver_arrived)


func _on_giver_arrived(c: CommissionData, customer: Dictionary) -> void:
	_commission = c
	_customer_instance_id = int(customer.get("instance_id", -1))
	_is_delivering = false
	var npc_display := String(customer.get("name", c.giver_npc_id))
	_title_lbl.text = "GIAO ĐƠN CHO %s" % npc_display.to_upper()
	_flavor_lbl.text = "\"%s\"" % c.flavor_accept
	_requirements_lbl.text = _requirements_text(c)
	_populate_weapon_list()
	visible = true


func _build_ui() -> void:
	add_child(HoaTamUI.make_dim_backdrop())

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := HoaTamUI.make_panel_container(false, 36.0)
	panel.custom_minimum_size = PANEL_SIZE
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)
	header.add_child(HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(HoaTamUI.HudIcon.DEBT), 34))

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 28)
	_title_lbl.add_theme_color_override("font_color", HoaTamUI.COL_GOLD)
	header.add_child(_title_lbl)

	_flavor_lbl = _make_label(18, HoaTamUI.COL_PARCHMENT, _font_italic)
	_flavor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_flavor_lbl)

	_requirements_lbl = _make_label(17, HoaTamUI.COL_JADE, _font_book)
	_requirements_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_requirements_lbl)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 236)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_weapon_list = VBoxContainer.new()
	_weapon_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_weapon_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_weapon_list)

	_status_lbl = _make_label(18, HoaTamUI.COL_GOLD, _font_book)
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_status_lbl)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(footer)

	var skip_btn := Button.new()
	skip_btn.text = "Để Lần Sau"
	skip_btn.custom_minimum_size = Vector2(200, 54)
	HoaTamUI.apply_secondary_button(skip_btn, 20)
	skip_btn.pressed.connect(_on_skip_pressed)
	footer.add_child(skip_btn)


func _make_label(font_size: int, color: Color, custom_font: Font = null) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if custom_font != null:
		label.add_theme_font_override("font", custom_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _populate_weapon_list() -> void:
	for child in _weapon_list.get_children():
		_weapon_list.remove_child(child)
		child.queue_free()

	var all_weapons: Array[Dictionary] = []
	var shelf_weapons := InventorySystem.get_shelf_weapons()
	for w: Dictionary in InventorySystem.get_weapons():
		if not all_weapons.has(w):
			all_weapons.append(w)
	for w: Dictionary in shelf_weapons:
		if not all_weapons.has(w):
			all_weapons.append(w)

	var has_match := false
	for weapon: Dictionary in all_weapons:
		var matches := WeaponSpec.satisfies(weapon, _commission)
		has_match = has_match or matches
		var on_shelf := shelf_weapons.has(weapon)
		_weapon_list.add_child(_make_weapon_row(weapon, matches, on_shelf))

	if all_weapons.is_empty() or not has_match:
		_status_lbl.text = "Chưa có vũ khí khớp yêu cầu đơn đặt rèn."
	else:
		_status_lbl.text = ""


func _make_weapon_row(weapon: Dictionary, matches: bool, on_shelf: bool = false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)

	var name_lbl := Label.new()
	var suffix_tag := "  [Trên kệ]" if on_shelf else ""
	name_lbl.text = _weapon_display_name(weapon) + suffix_tag
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _font_book != null:
		name_lbl.add_theme_font_override("font", _font_book)
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override(
		"font_color",
		HoaTamUI.COL_PARCHMENT if matches else Color(0.58, 0.50, 0.42)
	)
	row.add_child(name_lbl)

	var deliver_btn := Button.new()
	deliver_btn.text = "Giao Đơn"
	deliver_btn.custom_minimum_size = Vector2(150, 50)
	deliver_btn.disabled = not matches
	if matches:
		HoaTamUI.apply_primary_button(deliver_btn, 18)
	else:
		HoaTamUI.apply_secondary_button(deliver_btn, 18)
	deliver_btn.pressed.connect(_on_deliver_pressed.bind(weapon))
	row.add_child(deliver_btn)

	return row


func _on_deliver_pressed(weapon: Dictionary) -> void:
	if _is_delivering or _commission == null:
		return
	if not WeaponSpec.satisfies(weapon, _commission):
		return

	_is_delivering = true
	InventorySystem.sell_weapon(weapon)
	CommissionSystem.fulfill(_commission.commission_id, weapon)
	_status_lbl.text = "\"%s\"" % _commission.flavor_fulfilled
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return
	EventBus.commission_npc_dismiss_requested.emit(_customer_instance_id)
	_close()


func _on_skip_pressed() -> void:
	if _is_delivering:
		return
	_close()


func _close() -> void:
	_commission = null
	_customer_instance_id = -1
	_is_delivering = false
	visible = false


func _weapon_display_name(weapon: Dictionary) -> String:
	var existing_name := String(weapon.get("weapon_name", ""))
	if not existing_name.is_empty():
		return existing_name
	var weapon_type := String(weapon.get("weapon_type", "Vũ Khí"))
	var prefix_key := String(weapon.get("phase2_prefix", ""))
	var prefix_name := String(ForgeConverter.PREFIX_NAMES.get(prefix_key, prefix_key))
	var element_name := String(weapon.get("element_name", ""))
	var parts: Array[String] = [weapon_type]
	if not prefix_name.is_empty():
		parts.append(prefix_name)
	if not element_name.is_empty():
		parts.append(element_name)
	return " ".join(parts)


func _requirements_text(c: CommissionData) -> String:
	var blank := c.req_blank if not c.req_blank.is_empty() else "bất kỳ"
	var element := c.req_element if not c.req_element.is_empty() else "bất kỳ"
	var prefix := c.req_phase2_prefix \
		if not c.req_phase2_prefix.is_empty() else "bất kỳ"
	return "Yêu cầu: phôi %s · linh lực %s · phẩm %s · hiếm ≥ %d" % [
		blank,
		element,
		prefix,
		c.req_min_rarity,
	]
