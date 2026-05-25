class_name GameOverUI
extends CanvasLayer

const PATH_WORKSHOP := "res://scenes/main/WorkshopHub.tscn"
const PATH_MAIN_MENU := "res://scenes/ui/MainMenu.tscn"
const PANEL_SIZE := Vector2(600, 320)

var _panel: ColorRect


func _ready() -> void:
	layer = 64
	_build_layout()
	_center_panel()
	EventBus.game_over_triggered.connect(_on_game_over)
	hide()
	if GameManager.consecutive_zero_gold_days >= GameManager.GAME_OVER_ZERO_GOLD_THRESHOLD:
		_on_game_over("zero_gold_3_days")


func _build_layout() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.85)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	_panel = ColorRect.new()
	_panel.size = PANEL_SIZE
	_panel.color = Color.WHITE
	add_child(_panel)

	var title := Label.new()
	title.text = "KẾT THÚC"
	title.position = Vector2(0, 36)
	title.size = Vector2(PANEL_SIZE.x, 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.55, 0.04, 0.04))
	_panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Ba ngày liên tiếp lò trống tiền...\nHắc Nguyệt đã sai người đến."
	subtitle.position = Vector2(48, 126)
	subtitle.size = Vector2(PANEL_SIZE.x - 96, 72)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(0.12, 0.10, 0.08))
	_panel.add_child(subtitle)

	var restart_btn := _make_button("Bắt Đầu Lại", Vector2(72, 236))
	restart_btn.pressed.connect(_on_restart_pressed)
	_panel.add_child(restart_btn)

	var menu_btn := _make_button("Về Menu", Vector2(328, 236))
	menu_btn.pressed.connect(_on_menu_pressed)
	_panel.add_child(menu_btn)


func _center_panel() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_panel.position = (viewport_size - PANEL_SIZE) * 0.5


func _make_button(text: String, position: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = Vector2(200, 52)
	button.add_theme_font_size_override("font_size", 22)
	return button


func _on_game_over(_reason: String) -> void:
	show()


func _on_restart_pressed() -> void:
	GameManager.init_new_game()
	SceneManager.go_to(PATH_WORKSHOP)


func _on_menu_pressed() -> void:
	SceneManager.go_to(PATH_MAIN_MENU)
