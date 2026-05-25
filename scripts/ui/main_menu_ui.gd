extends Control

const PATH_WORKSHOP := "res://scenes/main/WorkshopHub.tscn"
const PATH_OPENING_SEQUENCE := "res://scenes/intro/OpeningSequence.tscn"
const PATH_OPENING_DEBT_SCRIPT := "res://scripts/intro/opening_debt_scene.gd"
const _DIR := "res://assets/UI/" + "Main Menu/"
const _BUTTON_SIZE := Vector2(300, 60)
const _BUTTON_SOURCE_WIDTH := 300
const _BG_MIN_VALUE := 0.86
const _BG_MAX_DELTA := 0.08
const _CROP_MIN_VISIBLE_PIXELS := 3
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
	bg.texture = load(_DIR + "BG.png")
	bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Đặt container từ 14% → 100% chiều cao để nhóm button ra ~57% từ trên
	var center := CenterContainer.new()
	center.anchor_left = 0.0
	center.anchor_right = 1.0
	center.anchor_top = 0.14
	center.anchor_bottom = 1.0
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	center.add_child(vbox)

	var start_btn := _make_tex_btn("Start.png")
	start_btn.custom_minimum_size = Vector2(360, 80)
	start_btn.pressed.connect(_on_new_game_pressed)
	vbox.add_child(start_btn)

	_continue_btn = _make_tex_btn("Cont.png")
	_continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(_continue_btn)

	var setting_btn := _make_tex_btn("Setting.png")
	setting_btn.pressed.connect(_on_setting_pressed)
	vbox.add_child(setting_btn)

	var quit_btn := _make_tex_btn("Quit.png")
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)

	_new_game_dialog = ConfirmationDialog.new()
	_new_game_dialog.title = "Chơi Mới"
	_new_game_dialog.dialog_text = "Xóa save hiện tại và bắt đầu lại?"
	_new_game_dialog.confirmed.connect(_on_new_game_confirmed)
	add_child(_new_game_dialog)


func _make_tex_btn(filename: String) -> Button:
	var btn := Button.new()
	btn.flat = true
	btn.icon = _load_button_icon(filename)
	btn.expand_icon = true
	btn.custom_minimum_size = _BUTTON_SIZE
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return btn


func _load_button_icon(filename: String) -> Texture2D:
	var source := load(_DIR + filename) as Texture2D
	if source == null:
		return null

	var image := source.get_image()
	if image == null or image.is_empty():
		return source

	image.convert(Image.FORMAT_RGBA8)
	_resize_button_source(image)
	_clear_baked_background(image)

	var visible_rect := _get_visible_rect(image)
	if visible_rect.size.x <= 0 or visible_rect.size.y <= 0:
		return ImageTexture.create_from_image(image)

	return ImageTexture.create_from_image(image.get_region(visible_rect))


func _resize_button_source(image: Image) -> void:
	var aspect := float(image.get_height()) / float(image.get_width())
	var target_height := maxi(1, roundi(float(_BUTTON_SOURCE_WIDTH) * aspect))
	image.resize(_BUTTON_SOURCE_WIDTH, target_height, Image.INTERPOLATE_LANCZOS)


func _clear_baked_background(image: Image) -> void:
	var image_size := image.get_size()
	var visited := PackedByteArray()
	visited.resize(image_size.x * image_size.y)

	var queue: Array[int] = []
	for x in range(image_size.x):
		_queue_background_pixel(image, visited, queue, x, 0)
		_queue_background_pixel(image, visited, queue, x, image_size.y - 1)
	for y in range(image_size.y):
		_queue_background_pixel(image, visited, queue, 0, y)
		_queue_background_pixel(image, visited, queue, image_size.x - 1, y)

	var read_index := 0
	while read_index < queue.size():
		var pixel_id := queue[read_index]
		read_index += 1

		var x := pixel_id % image_size.x
		var y := int(pixel_id / image_size.x)
		var color := image.get_pixel(x, y)
		color.a = 0.0
		image.set_pixel(x, y, color)

		_queue_background_pixel(image, visited, queue, x - 1, y)
		_queue_background_pixel(image, visited, queue, x + 1, y)
		_queue_background_pixel(image, visited, queue, x, y - 1)
		_queue_background_pixel(image, visited, queue, x, y + 1)


func _queue_background_pixel(
	image: Image,
	visited: PackedByteArray,
	queue: Array[int],
	x: int,
	y: int
) -> void:
	var image_size := image.get_size()
	if x < 0 or y < 0 or x >= image_size.x or y >= image_size.y:
		return

	var pixel_id := y * image_size.x + x
	if visited[pixel_id] == 1:
		return

	visited[pixel_id] = 1
	if _is_baked_background_color(image.get_pixel(x, y)):
		queue.append(pixel_id)


func _is_baked_background_color(color: Color) -> bool:
	var min_value := minf(color.r, minf(color.g, color.b))
	var max_value := maxf(color.r, maxf(color.g, color.b))
	return min_value >= _BG_MIN_VALUE and max_value - min_value <= _BG_MAX_DELTA


func _get_visible_rect(image: Image) -> Rect2i:
	var image_size := image.get_size()
	var min_x := image_size.x
	var min_y := image_size.y
	var max_x := -1
	var max_y := -1

	for x in range(image_size.x):
		if _count_visible_column_pixels(image, x) >= _CROP_MIN_VISIBLE_PIXELS:
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
	for y in range(image_size.y):
		if _count_visible_row_pixels(image, y) >= _CROP_MIN_VISIBLE_PIXELS:
			min_y = mini(min_y, y)
			max_y = maxi(max_y, y)

	if max_x < min_x or max_y < min_y:
		return Rect2i()

	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _count_visible_column_pixels(image: Image, x: int) -> int:
	var count := 0
	for y in range(image.get_height()):
		if image.get_pixel(x, y).a > 0.01:
			count += 1
	return count


func _count_visible_row_pixels(image: Image, y: int) -> int:
	var count := 0
	for x in range(image.get_width()):
		if image.get_pixel(x, y).a > 0.01:
			count += 1
	return count


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
