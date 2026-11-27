class_name CombatLoadoutUI
extends CanvasLayer

signal loadout_confirmed(region_id: String, weapons: Array)

const PANEL_SIZE := Vector2(780, 620)
const MAX_SELECTED := 3

var _root: Control
var _title_lbl: Label
var _hint_lbl: Label
var _list_box: VBoxContainer
var _confirm_btn: Button
var _region_id: String = ""
var _selected_weapons: Array[Dictionary] = []


func _ready() -> void:
	layer = 17
	visible = false
	_build_ui()


func show_loadout(region_id: String) -> void:
	_region_id = region_id
	_selected_weapons.clear()
	_preselect_equipped_weapons()
	visible = true
	_root.visible = true
	_refresh()


func hide_loadout() -> void:
	visible = false
	if _root != null:
		_root.visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_root.add_child(HoaTamUI.make_dim_backdrop())

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := HoaTamUI.make_panel_container(false, 36.0)
	panel.add_theme_stylebox_override("panel", HoaTamUI.make_leather_chest_style(36.0))
	panel.custom_minimum_size = PANEL_SIZE
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)
	header.add_child(HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(HoaTamUI.HudIcon.ATK), 34))

	_title_lbl = Label.new()
	_title_lbl.text = "CHỌN VŨ KHÍ MANG THEO"
	_title_lbl.add_theme_font_size_override("font_size", 30)
	_title_lbl.add_theme_color_override("font_color", HoaTamUI.COL_GOLD)
	header.add_child(_title_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override("font_size", 20)
	_hint_lbl.add_theme_color_override("font_color", HoaTamUI.COL_PARCHMENT)
	vbox.add_child(_hint_lbl)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_list_box)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_row)

	var close_btn := Button.new()
	close_btn.text = "Hủy"
	close_btn.custom_minimum_size = Vector2(180, 56)
	HoaTamUI.apply_secondary_button(close_btn, 22)
	close_btn.pressed.connect(hide_loadout)
	btn_row.add_child(close_btn)

	_confirm_btn = Button.new()
	_confirm_btn.custom_minimum_size = Vector2(220, 56)
	HoaTamUI.apply_primary_button(_confirm_btn, 22)
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	btn_row.add_child(_confirm_btn)


func _refresh() -> void:
	_clear_list()
	var weapons := InventorySystem.get_weapons()
	_hint_lbl.text = "Chọn tối đa %d vũ khí cho hành trình khám phá." % MAX_SELECTED
	_confirm_btn.text = "Xuất Phát"

	if weapons.is_empty():
		_hint_lbl.text = "Kho chưa có vũ khí. Bạn vẫn có thể lên đường tay không."
		_confirm_btn.text = "Đi Tay Không"
		_list_box.add_child(_make_info_label("Không có vũ khí trong kho."))
		return

	for weapon: Dictionary in weapons:
		_list_box.add_child(_make_weapon_row(weapon))


func _make_weapon_row(weapon: Dictionary) -> Button:
	var is_selected := weapon in _selected_weapons
	var button := Button.new()
	button.text = _weapon_label(weapon, is_selected)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 54)
	if is_selected:
		HoaTamUI.apply_primary_button(button, 20)
	else:
		HoaTamUI.apply_secondary_button(button, 20)
	button.pressed.connect(_toggle_weapon.bind(weapon))
	return button


func _make_info_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", HoaTamUI.COL_PARCHMENT)
	return label


func _weapon_label(weapon: Dictionary, is_selected: bool) -> String:
	var marker := "[ĐÃ CHỌN]" if is_selected else "[   ]"
	var w_name: String = weapon.get("weapon_name", weapon.get("name", "???"))
	var atk: int = int(weapon.get("atk", weapon.get("base_atk", 0)))
	var speed: int = int(weapon.get("speed", 5))
	return "%s  %s  ·  ATK %d  ·  SPD %d" % [marker, w_name, atk, speed]


func _toggle_weapon(weapon: Dictionary) -> void:
	if weapon in _selected_weapons:
		_selected_weapons.erase(weapon)
	elif _selected_weapons.size() < MAX_SELECTED:
		_selected_weapons.append(weapon)
	_refresh()


func _on_confirm_pressed() -> void:
	var loadout: Array[Dictionary] = []
	loadout.assign(_selected_weapons)
	hide_loadout()
	loadout_confirmed.emit(_region_id, loadout)


func _preselect_equipped_weapons() -> void:
	var weapons := InventorySystem.get_weapons()
	for equipped: Dictionary in GameManager.equipped_weapons:
		if equipped.is_empty():
			continue
		if equipped in weapons and equipped not in _selected_weapons:
			_selected_weapons.append(equipped)


func _clear_list() -> void:
	for child in _list_box.get_children():
		child.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			hide_loadout()
			get_viewport().set_input_as_handled()
