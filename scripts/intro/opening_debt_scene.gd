extends Control

const PATH_WORKSHOP := "res://scenes/main/WorkshopHub.tscn"
const PANEL_SIZE := Vector2(920, 360)
const SCENE_CARD_SIZE := Vector2(1120, 360)
const DIALOGUE_PANEL_SIZE := Vector2(880, 293)
const DIALOGUE_NAME_PANEL_SIZE := Vector2(320, 78)
const DEFAULT_CONTENT_SEPARATION := 22
const DIALOGUE_CONTENT_SEPARATION := 8
const SCENE_CARD_DURATION := 3.0
const FORGE_CARD_DURATION := 2.0
const NARRATION_FADE_DURATION := 0.8
const OPENING_BACKGROUND_PATH := "res://assets/sprites/forge/backgrounds/Forge Scene BG.PNG"
const DIALOGUE_TEXT_TEXTURE_PATH := "res://assets/UI/dialogue/Dialogue Text.png"
const DIALOGUE_NAME_TEXTURE_PATH := "res://assets/UI/dialogue/Dialogue Name.png"
const PLAYER_PORTRAIT_PATH := "res://assets/sprites/characters/nam_full_size_transparent.png"
const NPC_PORTRAIT_PATH := "res://assets/sprites/characters/Bà Hắc Nguyệt 1.png"
const ACTIVE_PORTRAIT_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const INACTIVE_PORTRAIT_MODULATE := Color(0.46, 0.46, 0.46, 0.46)
const PLAYER_SPEAKERS: Array[String] = ["Người Giữ Lò", "Nấm", "Thợ Rèn"]
const OPENING_STEPS: Array[Dictionary] = [
	{
		"mode": "scene_card",
		"title": "Lò Không Khóa",
		"body": "[center]Mưa tro rơi rất nhẹ trước cổng xưởng cũ.[/center]",
		"duration": SCENE_CARD_DURATION,
	},
	{
		"mode": "narration",
		"title": "",
		"body": "[center][i]Người Giữ Lò cầm chiếc chìa khóa cong. "
			+ "Cánh cửa gỗ mở ra trước khi chìa chạm ổ khóa.[/i][/center]",
		"duration": SCENE_CARD_DURATION,
	},
	{
		"mode": "dialogue",
		"title": "Người Giữ Lò",
		"body": "...Ai đó đã vào trước.",
	},
	{
		"mode": "narration",
		"title": "",
		"body": "[center][i]Có đe, có lò, có phôi sắt nằm dở dang. "
			+ "Không có mùi bỏ hoang. Có mùi than cũ, sắt lạnh, "
			+ "và thứ gì đó như lời hứa để lâu quá.[/i][/center]",
	},
	{
		"mode": "dialogue",
		"title": "Bà Trùm Hắc Nguyệt",
		"body": "Cảm động đấy, bé mèo. Nhưng cảm động không trả được lãi.",
	},
	{
		"mode": "dialogue",
		"title": "Bà Trùm Hắc Nguyệt",
		"body": "Ta đợi ngươi từ sáng sớm. Người ta nói Lò Thiêng có chủ mới về. "
			+ "Ta nói: hãy đợi xem tay chủ mới có chai không đã.",
	},
	{
		"mode": "dialogue",
		"title": "Bà Trùm Hắc Nguyệt",
		"body": "Hắc Nguyệt. Chủ nợ duy nhất của cái xưởng ngươi vừa bước vào. "
			+ "Cơn Nợ đầu tiên: 3,000G. Ngày thứ 4, ta lấy đủ.",
	},
	{
		"mode": "dialogue",
		"title": "Bà Trùm Hắc Nguyệt",
		"body": "Ta không phải kẻ ác, bé mèo. Ta là người duy nhất trong xứ này "
			+ "vẫn giữ hợp đồng khi mọi thứ khác đã mục nát.",
	},
	{
		"mode": "dialogue",
		"title": "Bà Trùm Hắc Nguyệt",
		"body": "Và đừng để lò tắt. Lần cuối nó tắt... mất cả đời người "
			+ "mới gọi nó dậy lại được.",
	},
	{
		"mode": "dialogue",
		"title": "Người Giữ Lò",
		"body": "...Ừ. Vậy thì bắt đầu thôi.",
	},
]

var _step: int = 0
var _timer_token: int = 0
var _center_container: CenterContainer
var _dialogue_bottom: Control
var _dialogue_row: Control
var _player_side: VBoxContainer
var _npc_side: VBoxContainer
var _player_portrait: TextureRect
var _npc_portrait: TextureRect
var _player_name_lbl: Label
var _npc_name_lbl: Label
var _dialogue_name_panel: PanelContainer
var _dialogue_name_lbl: Label
var _panel: PanelContainer
var _content_box: VBoxContainer
var _title_lbl: Label
var _body_lbl: RichTextLabel
var _next_btn: Button
var _placeholder_bg: ColorRect
var _fade_tween: Tween


func _ready() -> void:
	_sync_fullscreen_rect()
	_build_ui()
	if GameManager.has_tutorial_seen("opening_seen"):
		_finish_intro()
		return
	_show_current_step()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_fullscreen_rect()
		if _dialogue_bottom != null and _dialogue_bottom.visible:
			_layout_dialogue_elements()


func _sync_fullscreen_rect() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _build_ui() -> void:
	var backdrop := TextureRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = load(OPENING_BACKGROUND_PATH) as Texture2D
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(backdrop)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.38)
	add_child(bg)

	_center_container = CenterContainer.new()
	_center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_center_container)

	_dialogue_bottom = Control.new()
	_dialogue_bottom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialogue_bottom.visible = false
	add_child(_dialogue_bottom)

	_dialogue_row = Control.new()
	_dialogue_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialogue_bottom.add_child(_dialogue_row)

	_player_side = _make_portrait_side(PLAYER_PORTRAIT_PATH, "Người Giữ Lò")
	_player_portrait = _player_side.get_child(0) as TextureRect
	_player_name_lbl = _player_side.get_child(1) as Label
	_dialogue_row.add_child(_player_side)

	_panel = PanelContainer.new()
	_panel.z_index = 5
	_panel.custom_minimum_size = PANEL_SIZE
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	_center_container.add_child(_panel)

	_npc_side = _make_portrait_side(NPC_PORTRAIT_PATH, "NPC")
	_npc_portrait = _npc_side.get_child(0) as TextureRect
	_npc_name_lbl = _npc_side.get_child(1) as Label
	_dialogue_row.add_child(_npc_side)

	_dialogue_name_panel = PanelContainer.new()
	_dialogue_name_panel.z_index = 6
	_dialogue_name_panel.visible = false
	_dialogue_name_panel.custom_minimum_size = DIALOGUE_NAME_PANEL_SIZE
	_dialogue_name_panel.add_theme_stylebox_override(
		"panel",
		_make_dialogue_name_style()
	)
	_dialogue_row.add_child(_dialogue_name_panel)

	_dialogue_name_lbl = Label.new()
	_dialogue_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialogue_name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dialogue_name_lbl.add_theme_font_size_override("font_size", 22)
	_dialogue_name_lbl.add_theme_color_override(
		"font_color",
		Color(0.42, 0.13, 0.04, 1.0)
	)
	_dialogue_name_panel.add_child(_dialogue_name_lbl)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_bottom", 34)
	_panel.add_child(margin)

	_content_box = VBoxContainer.new()
	_content_box.add_theme_constant_override("separation", DEFAULT_CONTENT_SEPARATION)
	margin.add_child(_content_box)

	_placeholder_bg = ColorRect.new()
	_placeholder_bg.custom_minimum_size = Vector2(780, 132)
	_placeholder_bg.color = Color(0.16, 0.16, 0.16, 1.0)
	_placeholder_bg.visible = false
	_content_box.add_child(_placeholder_bg)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 40)
	_title_lbl.add_theme_color_override("font_color", Color.WHITE)
	_content_box.add_child(_title_lbl)

	_body_lbl = RichTextLabel.new()
	_body_lbl.bbcode_enabled = true
	_body_lbl.fit_content = true
	_body_lbl.scroll_active = false
	_body_lbl.custom_minimum_size = Vector2(0, 146)
	_body_lbl.add_theme_font_size_override("font_size", 24)
	_body_lbl.add_theme_color_override("default_color", Color.WHITE)
	_content_box.add_child(_body_lbl)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_END
	_content_box.add_child(button_row)

	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(160, 48)
	_next_btn.pressed.connect(_on_next_pressed)
	button_row.add_child(_next_btn)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.62)
	style.border_color = Color(1.0, 1.0, 1.0, 0.18)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style


func _make_dialogue_style() -> StyleBox:
	var texture := load(DIALOGUE_TEXT_TEXTURE_PATH) as Texture2D
	if texture == null:
		return _make_panel_style()
	var style := StyleBoxTexture.new()
	style.texture = texture
	# 9-slice: bảo tồn phần cuộn trang sức 2 đầu khi panel thay đổi kích thước
	style.texture_margin_left = 97.0
	style.texture_margin_right = 102.0
	style.texture_margin_top = 89.0
	style.texture_margin_bottom = 64.0
	style.content_margin_left = 110.0
	style.content_margin_top = 82.0
	style.content_margin_right = 110.0
	style.content_margin_bottom = 72.0
	return style


func _make_dialogue_name_style() -> StyleBox:
	var texture := load(DIALOGUE_NAME_TEXTURE_PATH) as Texture2D
	if texture == null:
		return _make_panel_style()
	var style := StyleBoxTexture.new()
	style.texture = texture
	# 9-slice tính từ edge thực của scroll (bỏ qua vùng transparent bên ngoài)
	style.texture_margin_left = 297.0
	style.texture_margin_right = 346.0
	style.texture_margin_top = 127.0
	style.texture_margin_bottom = 166.0
	style.content_margin_left = 44.0
	style.content_margin_top = 18.0
	style.content_margin_right = 44.0
	style.content_margin_bottom = 18.0
	return style


func _make_portrait_side(texture_path: String, display_name: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(108, 198)
	box.alignment = BoxContainer.ALIGNMENT_END
	box.add_theme_constant_override("separation", 8)

	var portrait := TextureRect.new()
	portrait.texture = load(texture_path) as Texture2D
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(portrait)

	var name_lbl := Label.new()
	name_lbl.text = display_name
	name_lbl.visible = false
	name_lbl.custom_minimum_size = Vector2.ZERO
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(name_lbl)
	return box


func _move_panel_to_center() -> void:
	if _panel.get_parent() != _center_container:
		_panel.get_parent().remove_child(_panel)
		_center_container.add_child(_panel)
	_dialogue_bottom.visible = false
	_dialogue_name_panel.visible = false


func _move_panel_to_dialogue_bottom() -> void:
	if _panel.get_parent() != _dialogue_row:
		_panel.get_parent().remove_child(_panel)
		_dialogue_row.add_child(_panel)
		_dialogue_row.move_child(_panel, _dialogue_row.get_child_count() - 1)
	_dialogue_bottom.visible = true
	_layout_dialogue_elements()


func _layout_dialogue_elements() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var portrait_height := maxf(420.0, viewport_size.y - 84.0)
	var portrait_width := minf(
		portrait_height,
		maxf(viewport_size.x * 0.40, portrait_height * 0.78)
	)
	var side_size := Vector2(portrait_width, portrait_height)
	var bottom_margin := 10.0

	_player_portrait.custom_minimum_size = Vector2(portrait_width, portrait_height)
	_player_portrait.size = Vector2(portrait_width, portrait_height)
	_npc_portrait.custom_minimum_size = Vector2(portrait_width, portrait_height)
	_npc_portrait.size = Vector2(portrait_width, portrait_height)
	_player_name_lbl.custom_minimum_size = Vector2.ZERO
	_npc_name_lbl.custom_minimum_size = Vector2.ZERO

	_player_side.custom_minimum_size = side_size
	_player_side.size = side_size
	_player_side.position = Vector2(24.0, viewport_size.y - side_size.y - bottom_margin)
	_npc_side.custom_minimum_size = side_size
	_npc_side.size = side_size
	_npc_side.position = Vector2(
		viewport_size.x - portrait_width - 24.0,
		viewport_size.y - side_size.y - bottom_margin
	)

	_panel.size = DIALOGUE_PANEL_SIZE
	_panel.position = Vector2(
		(viewport_size.x - DIALOGUE_PANEL_SIZE.x) * 0.5,
		viewport_size.y - DIALOGUE_PANEL_SIZE.y - 24.0
	)
	if _dialogue_name_panel.visible:
		var name_x := _panel.position.x + 28.0
		_dialogue_name_panel.size = DIALOGUE_NAME_PANEL_SIZE
		_dialogue_name_panel.position = Vector2(
			name_x,
			_panel.position.y - DIALOGUE_NAME_PANEL_SIZE.y + 34.0
		)


func _is_player_speaker(speaker: String) -> bool:
	return PLAYER_SPEAKERS.has(speaker)


func _apply_dialogue_speaker(entry: Dictionary) -> void:
	var speaker: String = entry.get("speaker", entry.get("title", ""))
	var is_player := _is_player_speaker(speaker)
	_player_side.modulate = ACTIVE_PORTRAIT_MODULATE if is_player else INACTIVE_PORTRAIT_MODULATE
	_npc_side.modulate = INACTIVE_PORTRAIT_MODULATE if is_player else ACTIVE_PORTRAIT_MODULATE
	_player_name_lbl.text = "Người Giữ Lò"
	_npc_name_lbl.text = "NPC" if is_player else speaker
	_dialogue_name_panel.visible = true
	_dialogue_name_lbl.text = "Người Giữ Lò" if is_player else speaker
	_dialogue_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_layout_dialogue_elements()


func _show_current_step() -> void:
	if _step >= OPENING_STEPS.size():
		_finish_intro()
		return

	var entry: Dictionary = OPENING_STEPS[_step]
	var mode: String = entry.get("mode", "narration")
	if mode == "scene_card":
		_configure_scene_card()
	elif mode == "dialogue":
		_configure_dialogue_card(entry)
	else:
		_configure_narration_card()

	_title_lbl.text = entry.get("title", "")
	_body_lbl.text = entry.get("body", "")
	_next_btn.text = "Bắt đầu" if _step >= OPENING_STEPS.size() - 1 else "Tiếp"

	var duration: float = entry.get("duration", 0.0)
	if duration > 0.0:
		_start_auto_advance(duration)


func _configure_scene_card() -> void:
	_stop_auto_advance()
	_move_panel_to_center()
	_content_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_content_box.add_theme_constant_override("separation", DEFAULT_CONTENT_SEPARATION)
	_panel.custom_minimum_size = SCENE_CARD_SIZE
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	_placeholder_bg.visible = false
	_title_lbl.visible = true
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 46)
	_title_lbl.add_theme_color_override("font_color", Color.WHITE)
	_body_lbl.add_theme_color_override("default_color", Color.WHITE)
	_body_lbl.modulate.a = 1.0
	_body_lbl.custom_minimum_size = Vector2(0, 146)
	_body_lbl.add_theme_font_size_override("font_size", 24)
	_next_btn.custom_minimum_size = Vector2(160, 48)


func _configure_narration_card() -> void:
	_stop_auto_advance()
	_move_panel_to_center()
	_content_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_content_box.add_theme_constant_override("separation", DEFAULT_CONTENT_SEPARATION)
	_panel.custom_minimum_size = PANEL_SIZE
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	_placeholder_bg.visible = false
	_title_lbl.visible = true
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 34)
	_title_lbl.add_theme_color_override("font_color", Color.WHITE)
	_body_lbl.add_theme_font_size_override("font_size", 22)
	_body_lbl.add_theme_color_override("default_color", Color.WHITE)
	_body_lbl.custom_minimum_size = Vector2(0, 146)
	_body_lbl.modulate.a = 0.0
	_next_btn.custom_minimum_size = Vector2(160, 48)
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_body_lbl, "modulate:a", 1.0, NARRATION_FADE_DURATION)


func _configure_dialogue_card(entry: Dictionary) -> void:
	_stop_auto_advance()
	_move_panel_to_dialogue_bottom()
	_content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_box.add_theme_constant_override("separation", DIALOGUE_CONTENT_SEPARATION)
	_panel.custom_minimum_size = DIALOGUE_PANEL_SIZE
	_panel.add_theme_stylebox_override("panel", _make_dialogue_style())
	_placeholder_bg.visible = false
	_title_lbl.visible = false
	_title_lbl.add_theme_font_size_override("font_size", 30)
	_title_lbl.add_theme_color_override("font_color", Color(0.42, 0.13, 0.04, 1.0))
	_body_lbl.add_theme_font_size_override("font_size", 24)
	_body_lbl.add_theme_color_override("default_color", Color(0.18, 0.08, 0.03, 1.0))
	_body_lbl.custom_minimum_size = Vector2(0, 112)
	_body_lbl.modulate.a = 1.0
	_next_btn.custom_minimum_size = Vector2(120, 36)
	_apply_dialogue_speaker(entry)


func _on_next_pressed() -> void:
	_step += 1
	_show_current_step()


func _start_auto_advance(delay: float) -> void:
	_timer_token += 1
	var token := _timer_token
	await get_tree().create_timer(delay).timeout
	if token != _timer_token:
		return
	_on_next_pressed()


func _stop_auto_advance() -> void:
	_timer_token += 1


func _finish_intro() -> void:
	GameManager.mark_tutorial("opening_seen")
	GameManager.mark_tutorial("ba_trum_intro_seen")
	SceneManager.go_to(PATH_WORKSHOP)
