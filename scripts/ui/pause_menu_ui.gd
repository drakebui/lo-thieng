class_name PauseMenuUI
extends CanvasLayer

const PATH_MAIN_MENU := "res://scenes/ui/MainMenu.tscn"

var _save_and_exit_button: Button


func _ready() -> void:
	layer = 10
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
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.6)
	backdrop.size = Vector2(1280, 720)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 300)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	center.add_child(panel)

	var menu := VBoxContainer.new()
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	menu.add_theme_constant_override("separation", 14)
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.add_child(menu)

	var title := Label.new()
	title.text = "TẠM DỪNG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	menu.add_child(title)

	var continue_button := _make_button("Tiếp Tục")
	continue_button.pressed.connect(close)
	menu.add_child(continue_button)

	_save_and_exit_button = _make_button("Lưu & Thoát về Menu")
	_save_and_exit_button.pressed.connect(_on_save_and_exit_pressed)
	menu.add_child(_save_and_exit_button)

	var exit_button := _make_button("Về Menu (không lưu)")
	exit_button.pressed.connect(_on_exit_without_save_pressed)
	menu.add_child(exit_button)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 48)
	button.process_mode = Node.PROCESS_MODE_ALWAYS
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
	if not can_save:
		return
	SaveSystem.save_game(GameManager.build_save_state())
	get_tree().paused = false
	SceneManager.go_to(PATH_MAIN_MENU)


func _on_exit_without_save_pressed() -> void:
	get_tree().paused = false
	SceneManager.go_to(PATH_MAIN_MENU)
