# Overlay giao vũ khí cho NPC đã đặt commission trong phiên shop.
class_name CommissionDeliveryUI
extends CanvasLayer

const PANEL_SIZE := Vector2(820, 540)
const PADDING := 36
const ROW_HEIGHT := 60

const PHASE2_PREFIX_NAMES := {
	"phan_chu": "Phản Chủ",
	"curse_nang": "Lời Nguyền",
	"curse_nhe": "Nguyền Nhẹ",
	"thuong": "Thường",
	"tot": "Tốt",
	"kiet_tac": "Kiệt Tác",
	"to_nghe": "Tổ Nghề",
	"khi_phach": "Khí Phách",
	"perfect": "PERFECT",
}

var _commission: CommissionData = null
var _customer_instance_id: int = -1
var _is_delivering: bool = false

var _title_lbl: Label
var _flavor_lbl: Label
var _requirements_lbl: Label
var _weapon_list: VBoxContainer
var _status_lbl: Label


func _ready() -> void:
	layer = 19
	visible = false
	_build_ui()
	EventBus.commission_giver_arrived.connect(_on_giver_arrived)


func _on_giver_arrived(c: CommissionData, customer: Dictionary) -> void:
	_commission = c
	_customer_instance_id = int(customer.get("instance_id", -1))
	_is_delivering = false
	_title_lbl.text = "Giao đơn cho %s" % c.giver_npc_id
	_flavor_lbl.text = "\"%s\"" % c.flavor_accept
	_requirements_lbl.text = _requirements_text(c)
	_populate_weapon_list()
	visible = true


func _build_ui() -> void:
	var viewport_size := get_viewport().get_visible_rect().size

	var backdrop := ColorRect.new()
	backdrop.position = Vector2.ZERO
	backdrop.size = viewport_size
	backdrop.color = Color(0.02, 0.01, 0.0, 0.58)
	add_child(backdrop)

	var panel := ColorRect.new()
	panel.position = (viewport_size - PANEL_SIZE) * 0.5
	panel.size = PANEL_SIZE
	panel.color = Color(0.10, 0.07, 0.04, 0.95)
	add_child(panel)

	_title_lbl = Label.new()
	_title_lbl.position = Vector2(PADDING, 22)
	_title_lbl.size = Vector2(PANEL_SIZE.x - PADDING * 2.0, 36)
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 26)
	_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32))
	panel.add_child(_title_lbl)

	_flavor_lbl = _make_label(
		panel,
		Vector2(PADDING, 66),
		66,
		18,
		Color(0.88, 0.78, 0.58)
	)

	_requirements_lbl = _make_label(
		panel,
		Vector2(PADDING, 132),
		48,
		17,
		Color(0.74, 0.92, 0.78)
	)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(PADDING, 188)
	scroll.size = Vector2(PANEL_SIZE.x - PADDING * 2.0, 230)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	_weapon_list = VBoxContainer.new()
	_weapon_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_weapon_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_weapon_list)

	_status_lbl = Label.new()
	_status_lbl.position = Vector2(PADDING, 424)
	_status_lbl.size = Vector2(PANEL_SIZE.x - PADDING * 2.0, 34)
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_size_override("font_size", 18)
	_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.36))
	panel.add_child(_status_lbl)

	var skip_btn := Button.new()
	skip_btn.text = "Bỏ Qua"
	skip_btn.position = Vector2(PANEL_SIZE.x - 220 - PADDING, PANEL_SIZE.y - 70)
	skip_btn.size = Vector2(220, 50)
	skip_btn.add_theme_font_size_override("font_size", 22)
	skip_btn.pressed.connect(_on_skip_pressed)
	panel.add_child(skip_btn)


func _make_label(parent: Node, pos: Vector2, height: int,
		font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = Vector2(PANEL_SIZE.x - PADDING * 2.0, height)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _populate_weapon_list() -> void:
	for child in _weapon_list.get_children():
		_weapon_list.remove_child(child)
		child.queue_free()

	var weapons := InventorySystem.get_weapons()
	var has_match := false
	for weapon: Dictionary in weapons:
		var matches := WeaponSpec.satisfies(weapon, _commission)
		has_match = has_match or matches
		_weapon_list.add_child(_make_weapon_row(weapon, matches))

	if weapons.is_empty() or not has_match:
		_status_lbl.text = "Chưa có món khớp đơn"
	else:
		_status_lbl.text = ""


func _make_weapon_row(weapon: Dictionary, matches: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)

	var name_lbl := Label.new()
	name_lbl.text = _weapon_display_name(weapon)
	name_lbl.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.86, 0.66))
	row.add_child(name_lbl)

	var deliver_btn := Button.new()
	deliver_btn.text = "Giao"
	deliver_btn.custom_minimum_size = Vector2(120, 44)
	deliver_btn.disabled = not matches
	deliver_btn.pressed.connect(_on_deliver_pressed.bind(weapon))
	row.add_child(deliver_btn)

	return row


func _on_deliver_pressed(weapon: Dictionary) -> void:
	if _is_delivering or _commission == null:
		return
	if not WeaponSpec.satisfies(weapon, _commission):
		return

	_is_delivering = true
	CommissionSystem.fulfill(_commission.commission_id, weapon)
	InventorySystem.weapons.erase(weapon)
	_status_lbl.text = "\"%s\"" % _commission.flavor_fulfilled
	await get_tree().create_timer(1.5).timeout
	EventBus.commission_npc_dismiss_requested.emit(_customer_instance_id)
	_close()


func _on_skip_pressed() -> void:
	# Không giao thì NPC tiếp tục đi theo flow shop bình thường.
	_close()


func _close() -> void:
	_commission = null
	_customer_instance_id = -1
	_is_delivering = false
	visible = false


func _weapon_display_name(weapon: Dictionary) -> String:
	var weapon_type := String(weapon.get("weapon_type", "Vũ Khí"))
	var prefix_key := String(weapon.get("phase2_prefix", ""))
	var prefix_name := String(PHASE2_PREFIX_NAMES.get(prefix_key, prefix_key))
	var element_name := String(weapon.get("element_name", ""))
	var parts: Array[String] = [weapon_type]
	if not prefix_name.is_empty():
		parts.append(prefix_name)
	if not element_name.is_empty():
		parts.append(element_name)
	return " ".join(parts)


func _requirements_text(c: CommissionData) -> String:
	var blank := c.req_blank if not c.req_blank.is_empty() else "bất kỳ"
	var element := c.req_element if not c.req_element.is_empty() else "bất kỳ"
	var prefix := c.req_phase2_prefix \
			if not c.req_phase2_prefix.is_empty() else "bất kỳ"
	return "Yêu cầu: phôi %s · nguyên tố %s · phẩm %s · hiếm tối thiểu %d" % [
		blank,
		element,
		prefix,
		c.req_min_rarity,
	]
