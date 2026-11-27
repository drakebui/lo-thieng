class_name InventoryUI
extends CanvasLayer

const PANEL_SIZE := Vector2(620, 520)

var _root: Control
var _materials_list: VBoxContainer
var _weapons_list: VBoxContainer


func _ready() -> void:
	layer = 19
	_build_ui()
	hide_inventory()


func show_inventory() -> void:
	refresh()
	visible = true
	_root.visible = true


func hide_inventory() -> void:
	visible = false
	if _root != null:
		_root.visible = false


func refresh() -> void:
	if _root == null:
		return
	_refresh_materials()
	_refresh_weapons()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.02, 0.01, 0.72)
	_root.add_child(bg)

	var panel := ColorRect.new()
	panel.size = PANEL_SIZE
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -PANEL_SIZE * 0.5
	panel.color = Color(0.13, 0.08, 0.04, 0.97)
	_root.add_child(panel)

	var title := Label.new()
	title.text = "Kho Đồ"
	title.position = Vector2(24, 18)
	title.size = Vector2(420, 34)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.36))
	panel.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Đóng"
	close_btn.position = Vector2(500, 18)
	close_btn.size = Vector2(92, 34)
	close_btn.pressed.connect(hide_inventory)
	panel.add_child(close_btn)

	var tabs := TabContainer.new()
	tabs.position = Vector2(24, 68)
	tabs.size = Vector2(572, 424)
	panel.add_child(tabs)

	_materials_list = _make_tab_list(tabs, "Vật Liệu")
	_weapons_list = _make_tab_list(tabs, "Vũ Khí")


func _make_tab_list(tabs: TabContainer, tab_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	return list


func _refresh_materials() -> void:
	_clear_list(_materials_list)

	var materials := InventorySystem.get_materials()
	if materials.is_empty():
		_materials_list.add_child(_make_entry_label("Kho vật liệu trống"))
		return

	for material: Dictionary in materials:
		var material_name: String = material.get(
			"material_name",
			material.get("item_name", material.get("name", "???"))
		)
		var quantity: int = int(material.get("quantity", material.get("amount", 1)))
		_materials_list.add_child(
			_make_entry_label("%s x%d" % [material_name, quantity])
		)


func _refresh_weapons() -> void:
	_clear_list(_weapons_list)

	var weapons := InventorySystem.get_weapons()
	if weapons.is_empty():
		_weapons_list.add_child(_make_entry_label("Không có vũ khí"))
		return

	for weapon: Dictionary in weapons:
		var weapon_name: String = weapon.get("weapon_name", weapon.get("name", "???"))
		var atk: int = int(weapon.get("atk", weapon.get("base_atk", 0)))
		var equipped := _get_equipped_marker(weapon)
		_weapons_list.add_child(
			_make_entry_label("%s%s (ATK %d)" % [weapon_name, equipped, atk])
		)


func _get_equipped_marker(weapon: Dictionary) -> String:
	for i in GameManager.equipped_weapons.size():
		if GameManager.equipped_weapons[i] == weapon:
			return " [Mang theo %d]" % (i + 1)
	return ""


func _make_entry_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.92, 0.84, 0.68))
	return label


func _clear_list(list: VBoxContainer) -> void:
	for child in list.get_children():
		child.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if _root == null or not _root.visible:
		return
	if event is InputEventKey and (event as InputEventKey).pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			hide_inventory()
			get_viewport().set_input_as_handled()
