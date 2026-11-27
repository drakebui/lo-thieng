class_name TutorialOverlayUI
extends CanvasLayer

signal completed

const PANEL_SIZE := Vector2(720, 280)
const BOOK_PANEL_SIZE := Vector2(720, 460)
const BOOK_STEP_PANEL_SIZE := Vector2(720, 340)
const DEFAULT_BODY_SIZE := Vector2(640, 120)
const DIALOGUE_BODY_SIZE := Vector2(640, 112)
const DIALOGUE_PANEL_SIZE := Vector2(880, 293)
const DIALOGUE_NAME_PANEL_SIZE := Vector2(320, 78)
const DEFAULT_STEP_SEPARATION := 18
const DIALOGUE_STEP_SEPARATION := 6
const PLAYER_PORTRAIT_PATH := "res://assets/pixel/ui/portraits/portrait_nam_256.png"
const DEFAULT_NPC_PORTRAIT_PATH := "res://assets/pixel/ui/portraits/portrait_ba_hac_nguyet_256.png"
const CO_LONG_GIO_PORTRAIT_PATH := "res://assets/pixel/ui/portraits/portrait_co_long_gio_256.png"
const BA_TRUM_HAC_NGUYET_PORTRAIT_PATH := "res://assets/pixel/ui/portraits/portrait_ba_hac_nguyet_256.png"
const CUC_THAN_PORTRAIT_PATH := "res://assets/pixel/ui/portraits/portrait_cuc_than_256.png"
const NGUOI_THU_NO_PORTRAIT_PATH := "res://assets/pixel/ui/portraits/portrait_nguoi_thu_no_c1_256.png"
const ACTIVE_PORTRAIT_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const INACTIVE_PORTRAIT_MODULATE := Color(0.46, 0.46, 0.46, 0.46)
const PLAYER_SPEAKERS: Array[String] = ["Người Giữ Lò", "Nấm", "Thợ Rèn"]
const CHARACTER_PORTRAITS: Dictionary = {
	"Cô Lộng Gió": CO_LONG_GIO_PORTRAIT_PATH,
	"Bà Trùm Hắc Nguyệt": BA_TRUM_HAC_NGUYET_PORTRAIT_PATH,
	"Người Thu Nợ": NGUOI_THU_NO_PORTRAIT_PATH,
	"Cục Than": CUC_THAN_PORTRAIT_PATH,
}

const C_PANEL_BG := Color(0.06, 0.038, 0.024, 0.96)
const C_PANEL_BORDER := Color(0.76, 0.56, 0.24, 0.94)
const C_TEXT := Color(0.96, 0.90, 0.76)
const C_MUTED := Color(0.76, 0.70, 0.58, 1.0)
const C_DIALOGUE_TITLE := Color(1.0, 0.86, 0.40, 1.0)
const C_DIALOGUE_TEXT := Color(0.96, 0.90, 0.78, 1.0)
const C_DIALOGUE_MUTED := Color(0.78, 0.68, 0.52, 1.0)

var _sections: Array[Dictionary] = []
var _steps: Array[Dictionary] = []
var _step_idx: int = 0
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
var _step_box: VBoxContainer
var _section_box: VBoxContainer
var _section_buttons_box: VBoxContainer
var _step_lbl: Label
var _title_lbl: Label
var _body_lbl: Label
var _next_btn: Button
var _back_btn: Button
var _close_btn: Button
var _is_book_mode := false


func _ready() -> void:
	layer = 40
	visible = false
	_build_ui()
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := event as InputEventKey
	if _step_box.visible:
		if key.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E]:
			get_viewport().set_input_as_handled()
			_on_next_pressed()
	elif _section_box.visible:
		if key.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_close_pressed()


func _on_viewport_size_changed() -> void:
	if _dialogue_bottom != null and _dialogue_bottom.visible:
		_layout_dialogue_elements()


func show_steps(steps: Array[Dictionary]) -> void:
	_is_book_mode = false
	_sections.clear()
	_steps = steps.duplicate()
	_step_idx = 0
	if _steps.is_empty():
		completed.emit()
		return
	_set_panel_size(PANEL_SIZE)
	_show_step_box()
	_refresh_step()
	visible = true


func show_sections(sections: Array[Dictionary]) -> void:
	_is_book_mode = true
	_sections = sections.duplicate()
	_steps.clear()
	_step_idx = 0
	if _sections.is_empty():
		completed.emit()
		return
	_show_section_box()
	visible = true


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.01, 0.0, 0.52)
	root.add_child(bg)

	_center_container = CenterContainer.new()
	_center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_center_container)

	_dialogue_bottom = Control.new()
	_dialogue_bottom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialogue_bottom.visible = false
	root.add_child(_dialogue_bottom)

	_dialogue_row = Control.new()
	_dialogue_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialogue_bottom.add_child(_dialogue_row)

	_player_side = _make_portrait_side(PLAYER_PORTRAIT_PATH, "Người Giữ Lò")
	_player_portrait = _player_side.get_child(0) as TextureRect
	_player_name_lbl = _player_side.get_child(1) as Label
	_dialogue_row.add_child(_player_side)

	_panel = PanelContainer.new()
	_panel.z_index = 5
	_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_center_container.add_child(_panel)
	_set_panel_size(PANEL_SIZE)
	_panel.add_theme_stylebox_override("panel", _make_panel_style())

	_npc_side = _make_portrait_side(DEFAULT_NPC_PORTRAIT_PATH, "NPC")
	_npc_portrait = _npc_side.get_child(0) as TextureRect
	_npc_name_lbl = _npc_side.get_child(1) as Label
	_dialogue_row.add_child(_npc_side)

	_dialogue_name_panel = PanelContainer.new()
	_dialogue_name_panel.z_index = 6
	_dialogue_name_panel.visible = false
	_dialogue_name_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	_dialogue_name_lbl.add_theme_color_override("font_color", C_DIALOGUE_TITLE)
	_dialogue_name_panel.add_child(_dialogue_name_lbl)

	_step_box = VBoxContainer.new()
	_step_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_step_box.add_theme_constant_override("separation", DEFAULT_STEP_SEPARATION)
	_panel.add_child(_step_box)

	_step_lbl = Label.new()
	_step_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_step_lbl.add_theme_font_size_override("font_size", 16)
	_step_box.add_child(_step_lbl)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 30)
	_step_box.add_child(_title_lbl)

	_body_lbl = Label.new()
	_body_lbl.custom_minimum_size = DEFAULT_BODY_SIZE
	_body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_lbl.add_theme_font_size_override("font_size", 22)
	_step_box.add_child(_body_lbl)

	_back_btn = Button.new()
	_back_btn.custom_minimum_size = Vector2(220, 42)
	_back_btn.text = "Mục lục"
	_back_btn.add_theme_font_size_override("font_size", 18)
	_back_btn.pressed.connect(_show_section_box)
	_step_box.add_child(_back_btn)

	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(220, 48)
	_next_btn.add_theme_font_size_override("font_size", 20)
	_next_btn.pressed.connect(_on_next_pressed)
	_step_box.add_child(_next_btn)
	_apply_default_text_colors()

	_build_section_box()


func _build_section_box() -> void:
	_section_box = VBoxContainer.new()
	_section_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_section_box.add_theme_constant_override("separation", 16)
	_panel.add_child(_section_box)

	var title := Label.new()
	title.text = "Guide Book"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	_section_box.add_child(title)

	var hint := Label.new()
	hint.text = "Chọn mục cần xem"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.modulate = Color(0.74, 0.70, 0.62, 1.0)
	_section_box.add_child(hint)

	_section_buttons_box = VBoxContainer.new()
	_section_buttons_box.add_theme_constant_override("separation", 10)
	_section_buttons_box.custom_minimum_size = Vector2(520, 260)
	_section_box.add_child(_section_buttons_box)

	_close_btn = Button.new()
	_close_btn.custom_minimum_size = Vector2(220, 48)
	_close_btn.text = "Đóng"
	_close_btn.add_theme_font_size_override("font_size", 20)
	_close_btn.pressed.connect(_on_close_pressed)
	_section_box.add_child(_close_btn)
	_section_box.visible = false


func _set_panel_size(size: Vector2) -> void:
	_panel.custom_minimum_size = size


func _show_step_box() -> void:
	_step_box.visible = true
	_section_box.visible = false
	_back_btn.visible = _is_book_mode


func _show_section_box() -> void:
	_move_panel_to_center()
	_set_panel_size(BOOK_PANEL_SIZE)
	_step_box.visible = false
	_section_box.visible = true
	_refresh_sections()


func _make_panel_style() -> StyleBoxTexture:
	return HoaTamUI.make_wood_panel_style(30.0)


func _make_dialogue_panel_style() -> StyleBox:
	return HoaTamUI.make_dialogue_panel_style(36.0)


func _make_dialogue_name_style() -> StyleBox:
	return HoaTamUI.make_nameplate_style()


func _make_portrait_side(texture_path: String, display_name: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(108, 198)
	box.alignment = BoxContainer.ALIGNMENT_END
	box.add_theme_constant_override("separation", 8)

	var portrait := TextureRect.new()
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not texture_path.is_empty():
		portrait.texture = load(texture_path) as Texture2D
	portrait.visible = portrait.texture != null
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(portrait)

	var name_lbl := Label.new()
	name_lbl.text = display_name
	name_lbl.visible = false
	name_lbl.custom_minimum_size = Vector2.ZERO
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
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
	# Khóa đúng bội số nguyên 2x cho ảnh chân dung Hi-Bit 256x256 trên 1920x1080 (512x512 -> 0% mixel, không phóng bể)
	var portrait_size := 512.0
	if viewport_size.x < 1600.0 or viewport_size.y < 900.0:
		portrait_size = clampf(minf(viewport_size.x * 0.28, viewport_size.y * 0.54), 256.0, 384.0)
	var side_size := Vector2(portrait_size, portrait_size)
	var bottom_margin := 24.0

	_player_portrait.custom_minimum_size = side_size
	_player_portrait.size = side_size
	_npc_portrait.custom_minimum_size = side_size
	_npc_portrait.size = side_size
	_player_name_lbl.custom_minimum_size = Vector2.ZERO
	_npc_name_lbl.custom_minimum_size = Vector2.ZERO

	_player_side.custom_minimum_size = side_size
	_player_side.size = side_size
	_player_side.position = Vector2(16.0, viewport_size.y - side_size.y - bottom_margin)
	_npc_side.custom_minimum_size = side_size
	_npc_side.size = side_size
	_npc_side.position = Vector2(
		viewport_size.x - portrait_size - 16.0,
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


func _portrait_path_for_speaker(speaker: String, explicit_path: String = "") -> String:
	if not explicit_path.is_empty():
		return explicit_path
	if _is_player_speaker(speaker):
		return PLAYER_PORTRAIT_PATH
	return CHARACTER_PORTRAITS.get(speaker, DEFAULT_NPC_PORTRAIT_PATH)


func _dialogue_partner_speaker(current_speaker: String) -> String:
	if not _is_player_speaker(current_speaker):
		return current_speaker
	for step: Dictionary in _steps:
		if not _is_dialogue_step(step):
			continue
		var speaker: String = step.get("speaker", step.get("title", ""))
		if not speaker.is_empty() and not _is_player_speaker(speaker):
			return speaker
	return ""


func _apply_dialogue_speaker(step: Dictionary) -> void:
	var speaker: String = step.get("speaker", step.get("title", ""))
	var is_player := _is_player_speaker(speaker)
	var partner := _dialogue_partner_speaker(speaker)
	var explicit_portrait: String = step.get("portrait", "")
	var npc_portrait_path := ""
	if not partner.is_empty() or not explicit_portrait.is_empty():
		npc_portrait_path = _portrait_path_for_speaker(partner, explicit_portrait)
	_player_portrait.texture = load(PLAYER_PORTRAIT_PATH) as Texture2D
	if npc_portrait_path.is_empty():
		_npc_portrait.texture = null
	else:
		_npc_portrait.texture = load(npc_portrait_path) as Texture2D
	_player_portrait.visible = _player_portrait.texture != null
	_npc_portrait.visible = _npc_portrait.texture != null
	_npc_side.visible = _npc_portrait.visible
	_player_side.modulate = ACTIVE_PORTRAIT_MODULATE if is_player else INACTIVE_PORTRAIT_MODULATE
	_npc_side.modulate = INACTIVE_PORTRAIT_MODULATE if is_player else ACTIVE_PORTRAIT_MODULATE
	_player_name_lbl.text = "Người Giữ Lò"
	_npc_name_lbl.text = partner
	_dialogue_name_panel.visible = true
	_dialogue_name_lbl.text = "Người Giữ Lò" if is_player else partner
	_dialogue_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_layout_dialogue_elements()


func _apply_default_text_colors() -> void:
	_step_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_step_box.add_theme_constant_override("separation", DEFAULT_STEP_SEPARATION)
	_body_lbl.custom_minimum_size = DEFAULT_BODY_SIZE
	_body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_lbl.visible = true
	_next_btn.custom_minimum_size = Vector2(220, 48)
	_step_lbl.add_theme_color_override("font_color", C_MUTED)
	_title_lbl.add_theme_color_override("font_color", C_TEXT)
	_body_lbl.add_theme_color_override("font_color", C_TEXT)


func _apply_dialogue_text_colors() -> void:
	_step_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_step_box.add_theme_constant_override("separation", DIALOGUE_STEP_SEPARATION)
	_body_lbl.custom_minimum_size = DIALOGUE_BODY_SIZE
	_body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_lbl.visible = false
	_next_btn.custom_minimum_size = Vector2(160, 36)
	_step_lbl.add_theme_color_override("font_color", C_DIALOGUE_MUTED)
	_title_lbl.add_theme_color_override("font_color", C_DIALOGUE_TITLE)
	_body_lbl.add_theme_color_override("font_color", C_DIALOGUE_TEXT)


func _is_dialogue_step(step: Dictionary) -> bool:
	return step.get("type", "") == "dialogue"


func _apply_step_visual(step: Dictionary) -> void:
	if _is_dialogue_step(step):
		_move_panel_to_dialogue_bottom()
		_set_panel_size(DIALOGUE_PANEL_SIZE)
		_panel.add_theme_stylebox_override("panel", _make_dialogue_panel_style())
		_apply_dialogue_text_colors()
		_apply_dialogue_speaker(step)
		return
	_move_panel_to_center()
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	_apply_default_text_colors()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _refresh_sections() -> void:
	for child in _section_buttons_box.get_children():
		_section_buttons_box.remove_child(child)
		child.queue_free()

	for i in _sections.size():
		var section: Dictionary = _sections[i]
		var btn := Button.new()
		btn.text = section.get("title", "Mục %d" % [i + 1])
		btn.custom_minimum_size = Vector2(520, 42)
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_open_section.bind(i))
		_section_buttons_box.add_child(btn)


func _open_section(index: int) -> void:
	if index < 0 or index >= _sections.size():
		return
	var section: Dictionary = _sections[index]
	var steps: Array = section.get("steps", [])
	_steps.clear()
	for step: Dictionary in steps:
		_steps.append(step)
	_step_idx = 0
	if _steps.is_empty():
		return
	_set_panel_size(BOOK_STEP_PANEL_SIZE)
	_show_step_box()
	_refresh_step()


func _refresh_step() -> void:
	var step := _steps[_step_idx]
	_apply_step_visual(step)
	_step_lbl.text = "Bước %d / %d" % [_step_idx + 1, _steps.size()]
	_step_lbl.visible = _steps.size() > 1 and not _is_dialogue_step(step)
	_title_lbl.text = step.get("title", "")
	_body_lbl.text = step.get("body", "")
	if _step_idx >= _steps.size() - 1:
		_next_btn.text = "Mục lục" if _is_book_mode else "Đã hiểu"
	else:
		_next_btn.text = "Tiếp"


func _on_next_pressed() -> void:
	_step_idx += 1
	if _step_idx >= _steps.size():
		if _is_book_mode:
			_show_section_box()
			return
		visible = false
		completed.emit()
		return
	_refresh_step()


func _on_close_pressed() -> void:
	visible = false
	if not _is_book_mode:
		completed.emit()
