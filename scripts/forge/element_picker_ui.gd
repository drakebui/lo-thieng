# Màn chọn linh lực trước khi bắt đầu chuỗi rèn chính
extends Control

const _PHASE3_SCRIPT := preload("res://scripts/forge/forge_phase3.gd")
const _PHASE_INDICATOR_SCRIPT := preload("res://scripts/forge/forge_phase_indicator.gd")
const BACKGROUND_PATH := "res://assets/sprites/forge/backgrounds/Forge Scene BG.PNG"
const PATH_WEAPON_BUILDER := "res://scenes/forge/WeaponBuilder.tscn"
const PATH_FORGE_SESSION := "res://scenes/forge/ForgeSession.tscn"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := TextureRect.new()
	bg.texture = load(BACKGROUND_PATH) as Texture2D
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var back_btn := Button.new()
	back_btn.text = "[ Quay lại chọn nguyên liệu  (Esc) ]"
	back_btn.add_theme_font_size_override("font_size", 28)
	back_btn.position = Vector2(32, 28)
	back_btn.size = Vector2(380, 52)
	back_btn.pressed.connect(_go_to_material_picker)
	add_child(back_btn)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 130
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 56)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "CHỌN LINH LỰC"
	title.add_theme_font_size_override("font_size", 92)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.50))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 40)
	vbox.add_child(grid)

	var allowed: Array = GameManager.selected_material.get("allowed_elements", [])
	for key in _PHASE3_SCRIPT.ELEMENTS.keys():
		if allowed.is_empty() or key in allowed:
			var data: Dictionary = _PHASE3_SCRIPT.ELEMENTS[key]
			var btn := Button.new()
			btn.text = data["name"]
			btn.custom_minimum_size = Vector2(360, 120)
			btn.add_theme_font_size_override("font_size", 64)
			btn.add_theme_color_override("font_color", data["color"])
			btn.pressed.connect(_on_element_picked.bind(key))
			grid.add_child(btn)

	var indicator := get_node_or_null("ForgePhaseIndicator")
	if indicator:
		indicator.set_phase(_PHASE_INDICATOR_SCRIPT.Phase.CHON_LINH_LUC)
		move_child(indicator, get_child_count() - 1)


func _on_element_picked(element_key: String) -> void:
	GameManager.selected_element = element_key
	get_tree().change_scene_to_file(PATH_FORGE_SESSION)


func _go_to_material_picker() -> void:
	GameManager.forge_return_to_material_step = true
	get_tree().change_scene_to_file(PATH_WEAPON_BUILDER)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_go_to_material_picker()
