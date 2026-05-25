class_name ForgeRecipeBookUI
extends CanvasLayer

const PANEL_SIZE := Vector2(920, 580)
const DEFAULT_RECIPES: Array[Dictionary] = [
	{
		"name": "Kiếm Đơn",
		"blank": "Phôi Kiếm Đơn (#51)",
		"materials": [{"item": "Quặng Sắt", "qty": 2}],
		"linh_luc": "Tùy chọn",
		"description": "Vũ khí cơ bản, dễ rèn, phù hợp cho cả chiến binh lẫn thương nhân mới vào nghề.",
		"forge_tips": "Phase Nung: giữ vùng Cam để có multiplier ×1.2.\n"
			+ "Phase Búa: nhắm prefix 'Kiệt Tác' trở lên.\n"
			+ "Phase Tôi: không bắt buộc chọn linh lực.",
	},
	{
		"name": "Giáo Dài",
		"blank": "Phôi Giáo Dài (#53)",
		"materials": [
			{"item": "Quặng Sắt", "qty": 2},
			{"item": "Gỗ Cứng", "qty": 1},
		],
		"linh_luc": "Tùy chọn",
		"description": "Vũ khí tầm xa, lợi thế khi đánh trước. Cần tay nghề ổn định.",
		"forge_tips": "Phase Búa: giáo dài nhạy với nhịp gõ — đừng vội.\n"
			+ "Phase Tôi: chọn linh lực để tăng tầm kiểm soát.",
	},
	{
		"name": "Gậy Phép",
		"blank": "Phôi Gậy Phép (#60)",
		"materials": [
			{"item": "Pha Lê", "qty": 2},
			{"item": "Gỗ Cứng", "qty": 1},
		],
		"linh_luc": "Hỏa / Sét / Băng",
		"description": "Kênh magic damage, yêu cầu Linh Lực để khai phóng toàn bộ tiềm năng.",
		"forge_tips": "Phase Tôi: BẮT BUỘC chọn Linh Lực (Hỏa/Sét/Băng) để unlock skill bẩm sinh.",
	},
]

var _root: Control
var _tabs: TabContainer
var _slot_list: VBoxContainer
var _detail_name: Label
var _detail_blank: Label
var _detail_materials: VBoxContainer
var _detail_linh_luc: Label
var _detail_description: Label
var _detail_tips: Label
var _selected_slot: Button = null
var _recipes: Array[Dictionary] = []


func _ready() -> void:
	layer = 18
	_build_ui()
	hide_book()


func show_book() -> void:
	_recipes = DEFAULT_RECIPES.duplicate(true)
	_refresh_slots()
	if _slot_list.get_child_count() > 0:
		_select_slot(_slot_list.get_child(0) as Button, _recipes[0])
	visible = true


func hide_book() -> void:
	visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.01, 0.0, 0.72)
	_root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := ColorRect.new()
	panel.custom_minimum_size = PANEL_SIZE
	panel.color = Color(0.13, 0.08, 0.04, 0.98)
	center.add_child(panel)

	var title := Label.new()
	title.text = "Bí Kíp Rèn"
	title.position = Vector2(24, 18)
	title.size = Vector2(720, 36)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.36))
	panel.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Đóng"
	close_btn.position = Vector2(PANEL_SIZE.x - 116, 18)
	close_btn.size = Vector2(92, 34)
	close_btn.pressed.connect(_on_close_pressed)
	panel.add_child(close_btn)

	_tabs = TabContainer.new()
	_tabs.position = Vector2(24, 72)
	_tabs.size = Vector2(PANEL_SIZE.x - 48, PANEL_SIZE.y - 96)
	panel.add_child(_tabs)

	_build_mechanics_tab()
	_build_recipe_tab()


func _build_mechanics_tab() -> void:
	var box := VBoxContainer.new()
	box.name = "Cơ Chế"
	box.add_theme_constant_override("separation", 14)
	_tabs.add_child(box)

	var body := Label.new()
	body.text = "Cơ chế rèn nâng cao:\n\n" \
		+ "- Phase Nung: giữ nhiệt ổn định để tăng chất lượng nền.\n" \
		+ "- Phase Rèn Búa: canh nhịp tốt để quyết định prefix.\n" \
		+ "- Phase Tôi Luyện: chọn Linh Lực để chốt hiệu ứng cuối.\n\n" \
		+ "Nội dung chi tiết sẽ được thay bằng dữ liệu GDD sau."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 20)
	body.add_theme_color_override("font_color", Color(0.94, 0.84, 0.68))
	box.add_child(body)


func _build_recipe_tab() -> void:
	var hbox := HBoxContainer.new()
	hbox.name = "Công Thức"
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 0)
	_tabs.add_child(hbox)

	# Panel trái — danh sách slot vũ khí
	var left_bg := ColorRect.new()
	left_bg.custom_minimum_size = Vector2(220, 0)
	left_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_bg.color = Color(0.08, 0.05, 0.02, 1.0)
	hbox.add_child(left_bg)

	var left_margin := MarginContainer.new()
	left_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_margin.add_theme_constant_override("margin_top", 8)
	left_margin.add_theme_constant_override("margin_left", 8)
	left_margin.add_theme_constant_override("margin_right", 8)
	left_margin.add_theme_constant_override("margin_bottom", 8)
	left_bg.add_child(left_margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_margin.add_child(scroll)

	_slot_list = VBoxContainer.new()
	_slot_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slot_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_slot_list)

	var divider := VSeparator.new()
	divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(divider)

	# Panel phải — chi tiết vũ khí được chọn
	var right_margin := MarginContainer.new()
	right_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_margin.add_theme_constant_override("margin_top", 16)
	right_margin.add_theme_constant_override("margin_left", 20)
	right_margin.add_theme_constant_override("margin_right", 16)
	right_margin.add_theme_constant_override("margin_bottom", 16)
	hbox.add_child(right_margin)

	var detail_box := VBoxContainer.new()
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_theme_constant_override("separation", 10)
	right_margin.add_child(detail_box)

	_detail_name = _make_label("", 26, true)
	detail_box.add_child(_detail_name)

	_detail_blank = _make_label("", 18)
	detail_box.add_child(_detail_blank)

	detail_box.add_child(_make_hsep())
	detail_box.add_child(_make_label("Nguyên liệu:", 18, true))

	_detail_materials = VBoxContainer.new()
	_detail_materials.add_theme_constant_override("separation", 4)
	detail_box.add_child(_detail_materials)

	detail_box.add_child(_make_hsep())

	_detail_linh_luc = _make_label("", 18)
	detail_box.add_child(_detail_linh_luc)

	_detail_description = _make_label("", 17)
	_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_box.add_child(_detail_description)

	detail_box.add_child(_make_label("Ghi chú rèn:", 18, true))

	_detail_tips = _make_label("", 17)
	_detail_tips.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_box.add_child(_detail_tips)


func _refresh_slots() -> void:
	for child in _slot_list.get_children():
		child.queue_free()
	_selected_slot = null
	for i in _recipes.size():
		var recipe := _recipes[i]
		var btn := Button.new()
		btn.text = recipe.get("name", "???")
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_color_override("font_color", Color(0.92, 0.84, 0.68))
		btn.pressed.connect(_select_slot.bind(btn, recipe))
		_slot_list.add_child(btn)


func _select_slot(btn: Button, recipe: Dictionary) -> void:
	if _selected_slot != null:
		_selected_slot.add_theme_color_override("font_color", Color(0.92, 0.84, 0.68))
	_selected_slot = btn
	btn.add_theme_color_override("font_color", Color(1.0, 0.84, 0.36))
	_update_detail(recipe)


func _update_detail(recipe: Dictionary) -> void:
	_detail_name.text = recipe.get("name", "")
	_detail_blank.text = "Phôi: %s" % recipe.get("blank", "???")
	_detail_linh_luc.text = "⚡ Linh Lực: %s" % recipe.get("linh_luc", "Tùy chọn")
	_detail_description.text = recipe.get("description", "")
	_detail_tips.text = recipe.get("forge_tips", "")

	for child in _detail_materials.get_children():
		child.queue_free()
	for material: Dictionary in (recipe.get("materials", []) as Array):
		_detail_materials.add_child(_make_label(_format_material_status(material), 17))


func _format_material_status(material: Dictionary) -> String:
	var item_name: String = material.get("item", "???")
	var required := int(material.get("qty", 0))
	var current := InventorySystem.get_item_count(item_name)
	if current >= required:
		return "  ✓  %s  x%d   (có %d)" % [item_name, required, current]
	return "  ✗  %s  x%d   (thiếu %d)" % [item_name, required, required - current]


func _make_label(text: String, font_size: int, is_heading: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	var color := Color(1.0, 0.84, 0.36) if is_heading else Color(0.92, 0.84, 0.68)
	label.add_theme_color_override("font_color", color)
	return label


func _make_hsep() -> HSeparator:
	var sep := HSeparator.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sep


func _on_close_pressed() -> void:
	hide_book()
	EventBus.forge_book_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()
