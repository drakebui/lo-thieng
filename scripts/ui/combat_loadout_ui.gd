class_name CombatLoadoutUI
extends CanvasLayer

signal loadout_confirmed(region_id: String, weapons: Array)

const PANEL_SIZE := Vector2(760, 620)
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

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.02, 0.01, 0.84)
	_root.add_child(bg)

	var panel := ColorRect.new()
	panel.size = PANEL_SIZE
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -PANEL_SIZE * 0.5
	panel.color = Color(0.12, 0.08, 0.04, 0.97)
	_root.add_child(panel)

	_title_lbl = Label.new()
	_title_lbl.text = "Chọn Vũ Khí Mang Theo"
	_title_lbl.position = Vector2(32, 24)
	_title_lbl.size = Vector2(PANEL_SIZE.x - 64, 42)
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 30)
	_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.36))
	panel.add_child(_title_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.position = Vector2(32, 74)
	_hint_lbl.size = Vector2(PANEL_SIZE.x - 64, 34)
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override("font_size", 20)
	_hint_lbl.add_theme_color_override("font_color", Color(0.86, 0.78, 0.62))
	panel.add_child(_hint_lbl)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(34, 124)
	scroll.size = Vector2(PANEL_SIZE.x - 68, 370)
	panel.add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_list_box)

	var close_btn := Button.new()
	close_btn.text = "Hủy"
	close_btn.position = Vector2(196, 530)
	close_btn.size = Vector2(150, 48)
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.pressed.connect(hide_loadout)
	panel.add_child(close_btn)

	_confirm_btn = Button.new()
	_confirm_btn.position = Vector2(410, 530)
	_confirm_btn.size = Vector2(180, 48)
	_confirm_btn.add_theme_font_size_override("font_size", 22)
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	panel.add_child(_confirm_btn)


func _refresh() -> void:
	_clear_list()
	var weapons := InventorySystem.get_weapons()
	_hint_lbl.text = "Chọn tối đa %d vũ khí cho combat." % MAX_SELECTED
	_confirm_btn.text = "Xuất phát"

	if weapons.is_empty():
		_hint_lbl.text = "Kho không có vũ khí. Bạn vẫn có thể đi tay không."
		_confirm_btn.text = "Đi tay không"
		_list_box.add_child(_make_info_label("Không có vũ khí trong kho."))
		return

	for weapon: Dictionary in weapons:
		_list_box.add_child(_make_weapon_row(weapon))


func _make_weapon_row(weapon: Dictionary) -> Button:
	var button := Button.new()
	button.text = _weapon_label(weapon)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(_toggle_weapon.bind(weapon))
	return button


func _make_info_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.90, 0.82, 0.66))
	return label


func _weapon_label(weapon: Dictionary) -> String:
	var marker := "[ ]"
	if weapon in _selected_weapons:
		marker = "[x]"
	var name: String = weapon.get("weapon_name", weapon.get("name", "???"))
	var atk: int = int(weapon.get("atk", weapon.get("base_atk", 0)))
	var speed: int = int(weapon.get("speed", 5))
	return "%s %s  ATK %d  SPD %d" % [marker, name, atk, speed]


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
