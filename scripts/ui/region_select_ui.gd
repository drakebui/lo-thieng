# scripts/ui/region_select_ui.gd
# Overlay bản đồ chọn vùng đất trước khi xuất phát khám phá (32-bit Hoả Tâm).
class_name RegionSelectUI
extends CanvasLayer

signal region_chosen(region_id: String)

const REGIONS: Array = [
	{
		"id": "DongMay", "name": "Đồng Mây Trắng",
		"desc": "Thảo nguyên cỏ xanh — sắt thô, bạc mảnh",
	},
	{
		"id": "RungTramHon", "name": "Rừng Trăm Hồn",
		"desc": "Rừng linh khí — gỗ cổ thụ, pha lê rừng",
	},
	{
		"id": "NuiThanDo", "name": "Núi Than Đỏ",
		"desc": "Núi lửa ngủ — quặng than, mithril thô",
	},
	{
		"id": "BaiCat", "name": "Bãi Cát Thần Vàng",
		"desc": "Sa mạc huyền bí — hổ phách, đá vàng",
	},
	{
		"id": "ThanhNgoc", "name": "Thành Ngọc Bích",
		"desc": "Thành phố cổ đại — thép trắng, ngọc thô",
	},
	{
		"id": "LangTo", "name": "Làng Tổ Nghề",
		"desc": "Quê hương tổ tiên — di thạch, mảnh thiêng",
	},
]


var _root: Control = null


func _ready() -> void:
	layer = 16
	visible = false
	_build_ui()


func refresh() -> void:
	if _root != null:
		_root.queue_free()
		_root = null
	_build_ui()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_root.add_child(HoaTamUI.make_dim_backdrop())

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	# Không bọc thêm khung gỗ khổng lồ bên ngoài cả 6 thẻ (tránh lồng khung trong khung)
	var container := Control.new()
	container.custom_minimum_size = Vector2(1460, 840)
	center.add_child(container)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 18)
	container.add_child(vbox)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 14)
	vbox.add_child(header)
	header.add_child(HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(HoaTamUI.HudIcon.STAMINA), 38))

	var title := Label.new()
	title.text = "BẢN ĐỒ HÀNH TRÌNH"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", HoaTamUI.COL_GOLD)
	header.add_child(title)

	var stamina_lbl := Label.new()
	stamina_lbl.text = "Thể lực hành trình: %d / %d" % [
		GameManager.travel_stamina,
		GameManager.max_travel_stamina,
	]
	stamina_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamina_lbl.add_theme_font_size_override("font_size", 22)
	stamina_lbl.add_theme_color_override("font_color", HoaTamUI.COL_JADE)
	vbox.add_child(stamina_lbl)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	vbox.add_child(grid)

	for region in REGIONS:
		grid.add_child(_build_card(region))

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(footer)

	var close_btn := Button.new()
	close_btn.text = "Đóng Bản Đồ (ESC)"
	close_btn.custom_minimum_size = Vector2(280, 56)
	HoaTamUI.apply_secondary_button(close_btn, 22)
	close_btn.pressed.connect(func() -> void: visible = false)
	footer.add_child(close_btn)


func _build_card(region: Dictionary) -> PanelContainer:
	var rid: String = region["id"]
	var unlocked: bool = GameManager.is_region_unlocked(rid)

	# Chỉ vùng đã mở dùng thẻ Giấy Dó 9-slice; vùng khóa dùng bề mặt chìm tối (tạo tương phản rõ)
	var panel: PanelContainer
	if unlocked:
		panel = HoaTamUI.make_panel_container(true, 24.0)
	else:
		panel = PanelContainer.new()
		panel.add_theme_stylebox_override("panel", HoaTamUI.make_inset_surface_style(0.72, 24.0))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var name_lbl := Label.new()
	name_lbl.text = region["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override(
		"font_color",
		HoaTamUI.COL_INK if unlocked else HoaTamUI.COL_BRASS
	)
	col.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = region["desc"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 18)
	desc_lbl.add_theme_color_override(
		"font_color",
		HoaTamUI.COL_INK_MUTE if unlocked else Color(0.62, 0.56, 0.48)
	)
	col.add_child(desc_lbl)

	if unlocked:
		var cost: int = GameManager.get_entry_cost(rid)
		var can_enter: bool = GameManager.can_enter_region(rid)

		var cost_row := HBoxContainer.new()
		cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
		cost_row.add_theme_constant_override("separation", 8)
		col.add_child(cost_row)
		cost_row.add_child(HoaTamUI.make_icon_rect(HoaTamUI.get_hud_icon(HoaTamUI.HudIcon.STAMINA), 22))

		var cost_lbl := Label.new()
		cost_lbl.text = "Tiêu hao: -%d thể lực" % cost
		cost_lbl.add_theme_font_size_override("font_size", 18)
		cost_lbl.add_theme_color_override(
			"font_color",
			HoaTamUI.COL_INK if can_enter else HoaTamUI.COL_CRIMSON_INK
		)
		cost_row.add_child(cost_lbl)

		var btn := Button.new()
		btn.text = "Xuất Phát" if can_enter else "Thiếu Thể Lực"
		btn.custom_minimum_size = Vector2(210, 52)
		btn.disabled = not can_enter
		if can_enter:
			HoaTamUI.apply_primary_button(btn, 21)
			btn.pressed.connect(func() -> void:
				visible = false
				region_chosen.emit(rid)
			)
		else:
			HoaTamUI.apply_secondary_button(btn, 20)
		var btn_wrap := HBoxContainer.new()
		btn_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_wrap.add_child(btn)
		col.add_child(btn_wrap)
	else:
		var lock_lbl := Label.new()
		lock_lbl.text = "Chưa Mở Đường"
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 19)
		lock_lbl.add_theme_color_override("font_color", Color(0.56, 0.46, 0.38))
		col.add_child(lock_lbl)

	return panel


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return
	if (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		visible = false
		get_viewport().set_input_as_handled()
