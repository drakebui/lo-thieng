# scripts/ui/region_select_ui.gd
# Overlay chọn vùng đất trước khi xuất phát khám phá.
class_name RegionSelectUI
extends CanvasLayer

signal region_chosen(region_id: String)

const REGIONS: Array = [
	{
		"id": "DongMay", "name": "Đồng Mây Trắng",
		"desc": "Thảo nguyên cỏ xanh — sắt thô, bạc mảnh",
		"color": Color(0.72, 0.68, 0.38),
	},
	{
		"id": "RungTramHon", "name": "Rừng Trăm Hồn",
		"desc": "Rừng linh khí — gỗ cổ thụ, pha lê rừng",
		"color": Color(0.28, 0.72, 0.35),
	},
	{
		"id": "NuiThanDo", "name": "Núi Than Đỏ",
		"desc": "Núi lửa ngủ — quặng than, mithril thô",
		"color": Color(0.88, 0.35, 0.15),
	},
	{
		"id": "BaiCat", "name": "Bãi Cát Thần Vàng",
		"desc": "Sa mạc huyền bí — hổ phách, đá vàng",
		"color": Color(0.95, 0.82, 0.28),
	},
	{
		"id": "ThanhNgoc", "name": "Thành Ngọc Bích",
		"desc": "Thành phố cổ đại — thép trắng, ngọc thô",
		"color": Color(0.35, 0.72, 0.88),
	},
	{
		"id": "LangTo", "name": "Làng Tổ Nghề",
		"desc": "Quê hương tổ tiên — di thạch, mảnh thiêng",
		"color": Color(0.88, 0.72, 0.38),
	},
]


func _ready() -> void:
	layer   = 16
	visible = false
	_build_ui()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.03, 0.02, 0.90)
	root.add_child(bg)

	var title := Label.new()
	title.text = "CHỌN VÙNG KHÁM PHÁ"
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top    = 28
	title.offset_bottom = 110
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.48))
	root.add_child(title)

	var stamina_lbl := Label.new()
	stamina_lbl.text = "Thể lực còn lại: %d / %d" % [
		GameManager.travel_stamina,
		GameManager.max_travel_stamina,
	]
	stamina_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	stamina_lbl.offset_top    = 112
	stamina_lbl.offset_bottom = 148
	stamina_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamina_lbl.add_theme_font_size_override("font_size", 30)
	stamina_lbl.add_theme_color_override("font_color", Color(0.62, 0.88, 0.55))
	root.add_child(stamina_lbl)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	grid.anchor_left   = 0.04
	grid.anchor_right  = 0.96
	grid.anchor_top    = 0.15
	grid.anchor_bottom = 0.88
	root.add_child(grid)

	for region in REGIONS:
		grid.add_child(_build_card(region))

	var close_btn := Button.new()
	close_btn.text = "[ Đóng  (ESC) ]"
	close_btn.anchor_left   = 0.35
	close_btn.anchor_right  = 0.65
	close_btn.anchor_top    = 0.90
	close_btn.anchor_bottom = 0.98
	close_btn.add_theme_font_size_override("font_size", 36)
	close_btn.pressed.connect(func() -> void: visible = false)
	root.add_child(close_btn)


func _build_card(region: Dictionary) -> PanelContainer:
	var rid: String     = region["id"]
	var unlocked: bool  = GameManager.is_region_unlocked(rid)
	var accent: Color   = region["color"]

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.bg_color     = Color(accent.r * 0.14, accent.g * 0.14, accent.b * 0.14)
	style.border_color = accent if unlocked else Color(
		accent.r * 0.35,
		accent.g * 0.35,
		accent.b * 0.35
	)
	style.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	margin.add_child(col)

	var name_lbl := Label.new()
	name_lbl.text = region["name"]
	name_lbl.add_theme_font_size_override("font_size", 32)
	name_lbl.add_theme_color_override("font_color",
		accent if unlocked else Color(accent.r * 0.45, accent.g * 0.45, accent.b * 0.45))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = region["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 20)
	desc_lbl.add_theme_color_override("font_color",
		Color(0.70, 0.66, 0.55) if unlocked else Color(0.40, 0.37, 0.30))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.max_lines_visible = 1
	desc_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(desc_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "[ Đã mở khóa ]" if unlocked else "[ Chưa mở khóa ]"
	status_lbl.add_theme_font_size_override("font_size", 22)
	status_lbl.add_theme_color_override("font_color",
		Color(0.42, 0.88, 0.48) if unlocked else Color(0.55, 0.38, 0.28))
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(status_lbl)

	if unlocked:
		var cost: int = GameManager.get_entry_cost(rid)
		var can_enter: bool = GameManager.can_enter_region(rid)

		var cost_lbl := Label.new()
		cost_lbl.text = "Chi phí vào vùng: -%d thể lực" % cost
		cost_lbl.add_theme_font_size_override("font_size", 20)
		cost_lbl.add_theme_color_override("font_color",
			Color(0.62, 0.88, 0.55) if can_enter else Color(0.82, 0.42, 0.32))
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(cost_lbl)

		var btn := Button.new()
		btn.text = "→  Xuất Phát" if can_enter else "Không đủ thể lực"
		btn.add_theme_font_size_override("font_size", 26)
		btn.disabled = not can_enter
		if can_enter:
			btn.pressed.connect(func() -> void:
				visible = false
				region_chosen.emit(rid)
			)
		col.add_child(btn)

	return panel


func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if not (event is InputEventKey): return
	if (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		visible = false
		get_viewport().set_input_as_handled()
