class_name GameOverUI
extends CanvasLayer

const PATH_WORKSHOP := "res://scenes/main/WorkshopHub.tscn"
const PATH_MAIN_MENU := "res://scenes/ui/MainMenu.tscn"
const PANEL_SIZE := Vector2(680, 390)

var _panel: PanelContainer


func _ready() -> void:
	layer = 64
	_build_layout()
	EventBus.game_over_triggered.connect(_on_game_over)
	hide()
	if GameManager.consecutive_zero_gold_days >= GameManager.GAME_OVER_ZERO_GOLD_THRESHOLD:
		_on_game_over("zero_gold_3_days")


func _build_layout() -> void:
	var backdrop := HoaTamUI.make_dim_backdrop()
	backdrop.color = Color(0.04, 0.02, 0.03, 0.86)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Trát tịch thu trên giấy dó cổ 32-bit (xóa hoàn toàn hộp trắng Color.WHITE)
	_panel = HoaTamUI.make_panel_container(true, 40.0)
	_panel.custom_minimum_size = PANEL_SIZE
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	_panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 14)
	vbox.add_child(header)
	header.add_child(HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(HoaTamUI.HudIcon.DEBT), 42))

	var title := Label.new()
	title.text = "TRÁT TỊCH THU LÒ RÈN"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", HoaTamUI.COL_CRIMSON_INK)
	header.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Ba ngày liên tiếp lò trống tiền.\nHắc Nguyệt đã sai người đến niêm phong cửa xưởng."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", HoaTamUI.COL_INK)
	vbox.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_row)

	var restart_btn := Button.new()
	restart_btn.text = "Mở Lò Lại Từ Đầu"
	restart_btn.custom_minimum_size = Vector2(248, 60)
	HoaTamUI.apply_primary_button(restart_btn, 22)
	restart_btn.pressed.connect(_on_restart_pressed)
	btn_row.add_child(restart_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Về Màn Hình Chính"
	menu_btn.custom_minimum_size = Vector2(236, 60)
	HoaTamUI.apply_secondary_button(menu_btn, 22)
	menu_btn.pressed.connect(_on_menu_pressed)
	btn_row.add_child(menu_btn)


func _on_game_over(_reason: String) -> void:
	show()


func _on_restart_pressed() -> void:
	GameManager.init_new_game()
	SceneManager.go_to(PATH_WORKSHOP)


func _on_menu_pressed() -> void:
	SceneManager.go_to(PATH_MAIN_MENU)
