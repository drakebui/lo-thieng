extends Control

const PATH_WORKSHOP := "res://scenes/main/WorkshopHub.tscn"
const PATH_OPENING_SEQUENCE := "res://scenes/intro/OpeningSequence.tscn"
const PATH_OPENING_DEBT_SCRIPT := "res://scripts/intro/opening_debt_scene.gd"
const MAIN_MENU_BG_PATH := "res://assets/pixel/backgrounds/main_menu_bg_640x360.png"
const _BUTTON_SIZE := Vector2(340, 62)
const _SAVE_INFO_DIALOG_SCRIPT := "res://scripts/ui/save_info_dialog.gd"

var _continue_btn: Button
var _new_game_dialog: ConfirmationDialog
var _save_info_dialog: SaveInfoDialog


func _ready() -> void:
	get_tree().paused = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_layout()
	_refresh_buttons()


func _build_layout() -> void:
	var bg := TextureRect.new()
	if ResourceLoader.exists(MAIN_MENU_BG_PATH):
		bg.texture = load(MAIN_MENU_BG_PATH) as Texture2D
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.05, 0.025, 0.02, 0.22)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	# Tiêu đề game tông Hoả Tâm 32-bit
	var title_box := VBoxContainer.new()
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.add_theme_constant_override("separation", 4)
	vbox.add_child(title_box)

	var title := Label.new()
	title.text = "LÒ THIÊNG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 78)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.36))
	title.add_theme_color_override("font_outline_color", Color(0.10, 0.04, 0.02, 0.98))
	title.add_theme_constant_override("outline_size", 10)
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "— TIẾNG GỌI TỔ NGHỀ —"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.96, 0.84, 0.62))
	subtitle.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02, 0.95))
	subtitle.add_theme_constant_override("outline_size", 6)
	title_box.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 26)
	vbox.add_child(spacer)

	var start_btn := _make_menu_btn("BẮT ĐẦU MỚI", true)
	start_btn.pressed.connect(_on_new_game_pressed)
	vbox.add_child(start_btn)

	_continue_btn = _make_menu_btn("TIẾP TỤC HÀNH TRÌNH", false)
	_continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(_continue_btn)

	var setting_btn := _make_menu_btn("CÀI ĐẶT", false)
	setting_btn.pressed.connect(_on_setting_pressed)
	vbox.add_child(setting_btn)

	var quit_btn := _make_menu_btn("THOÁT GAME", false)
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)

	_new_game_dialog = ConfirmationDialog.new()
	_new_game_dialog.title = "Chơi Mới"
	_new_game_dialog.dialog_text = "Xóa save hiện tại và bắt đầu lại?"
	_new_game_dialog.confirmed.connect(_on_new_game_confirmed)
	add_child(_new_game_dialog)


func _make_menu_btn(label_text: String, is_primary: bool) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = _BUTTON_SIZE
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if is_primary:
		HoaTamUI.apply_primary_button(btn, 26)
	else:
		HoaTamUI.apply_secondary_button(btn, 22)
	return btn


func _refresh_buttons() -> void:
	_continue_btn.visible = SaveSystem.has_save()


func _on_continue_pressed() -> void:
	var metadata := SaveSystem.get_save_metadata()
	_show_save_info_dialog(metadata)


func _show_save_info_dialog(metadata: Dictionary) -> void:
	if _save_info_dialog == null:
		var script := load(_SAVE_INFO_DIALOG_SCRIPT) as GDScript
		if script == null:
			push_warning("Không load được dialog thông tin save")
			return
		_save_info_dialog = script.new() as SaveInfoDialog
		_save_info_dialog.load_confirmed.connect(_load_saved_game)
		add_child(_save_info_dialog)
	_save_info_dialog.popup_with_metadata(metadata)


func _load_saved_game() -> void:
	var data := SaveSystem.load_game()
	if data.is_empty():
		_start_new_game()
		return
	GameManager.restore_from_save(data)
	_go_to_opening_or_workshop()


func _on_new_game_pressed() -> void:
	if SaveSystem.has_save():
		_new_game_dialog.popup_centered()
		return
	_start_new_game()


func _on_new_game_confirmed() -> void:
	SaveSystem.delete_save()
	_start_new_game()


func _start_new_game() -> void:
	GameManager.init_new_game()
	_go_to_opening_or_workshop()


func _go_to_opening_or_workshop() -> void:
	if _should_show_ba_trum_intro():
		_open_ba_trum_intro()
		return
	SceneManager.go_to(PATH_WORKSHOP)


func _should_show_ba_trum_intro() -> bool:
	return GameManager.current_day == 0 \
		and GameManager.current_phase == GameManager.GamePhase.MORNING \
		and not GameManager.has_tutorial_seen("ba_trum_intro_seen")


func _open_ba_trum_intro() -> void:
	if ResourceLoader.exists(PATH_OPENING_SEQUENCE):
		SceneManager.go_to(PATH_OPENING_SEQUENCE)
		return

	var script := load(PATH_OPENING_DEBT_SCRIPT) as GDScript
	if script == null:
		push_warning("Không load được intro Bà Trùm, chuyển thẳng vào xưởng")
		SceneManager.go_to(PATH_WORKSHOP)
		return
	var intro := script.new() as Node
	var tree := get_tree()
	var current_scene := tree.current_scene
	tree.root.add_child(intro)
	tree.current_scene = intro
	if current_scene != null:
		current_scene.queue_free()


func _on_setting_pressed() -> void:
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()
