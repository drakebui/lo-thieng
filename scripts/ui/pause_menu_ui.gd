class_name PauseMenuUI
extends CanvasLayer

const PATH_MAIN_MENU := "res://scenes/ui/MainMenu.tscn"

var _save_and_exit_button: Button


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_layout()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


func open() -> void:
	_refresh_actions()
	visible = true
	get_tree().paused = true


func close() -> void:
	get_tree().paused = false
	visible = false


func _build_layout() -> void:
	var backdrop := HoaTamUI.make_dim_backdrop()
	backdrop.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(center)

	var panel := HoaTamUI.make_panel_container(false, 36.0)
	panel.add_theme_stylebox_override("panel", HoaTamUI.make_system_slate_style(36.0))
	panel.custom_minimum_size = Vector2(460, 360)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	center.add_child(panel)

	var menu := VBoxContainer.new()
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	menu.add_theme_constant_override("separation", 18)
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.add_child(menu)

	var title := Label.new()
	title.text = "TẠM DỪNG XƯỞNG LÒ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", HoaTamUI.COL_GOLD)
	menu.add_child(title)

	var continue_button := _make_button("Tiếp Tục Rèn", true)
	continue_button.pressed.connect(close)
	menu.add_child(continue_button)

	_save_and_exit_button = _make_button("Lưu & Về Màn Hình Chính", false)
	_save_and_exit_button.pressed.connect(_on_save_and_exit_pressed)
	menu.add_child(_save_and_exit_button)

	var exit_button := _make_button("Thoát (Không Lưu)", false)
	exit_button.pressed.connect(_on_exit_without_save_pressed)
	menu.add_child(exit_button)


func _make_button(text: String, is_primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(340, 58)
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	if is_primary:
		HoaTamUI.apply_primary_button(button, 22)
	else:
		HoaTamUI.apply_secondary_button(button, 21)
	return button


func _refresh_actions() -> void:
	if GameManager.current_day >= 2:
		_save_and_exit_button.disabled = false
	else:
		_save_and_exit_button.disabled = (
			GameManager.current_phase != GameManager.GamePhase.NIGHT
		)


func _on_save_and_exit_pressed() -> void:
	var can_save := (
		GameManager.current_day >= 2
		or GameManager.current_phase == GameManager.GamePhase.NIGHT
	)
	if can_save:
		SaveSystem.save_game(GameManager.build_save_state())
	close()
	SceneManager.go_to(PATH_MAIN_MENU)


func _on_exit_without_save_pressed() -> void:
	close()
	SceneManager.go_to(PATH_MAIN_MENU)
