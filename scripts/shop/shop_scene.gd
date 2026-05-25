# gdlint: disable=max-file-lines
extends Node2D

# Layout: động theo viewport (chuẩn 1920×1080 → 30×17 tile, tile 64px)
# Tường dày 1 tile, sàn chơi (_cols-2)×(_rows-2) tile bên trong

const TILE := 64
const PLAYER_MOVE_SPEED := 240.0
const SHOP_BG_PATH := "res://assets/UI/shop/Shop.PNG"
const SHOP_COUNTER_FG_PATH := "res://assets/UI/shop/ShopCounterForeground.png"
const SHOP_BG_SIZE := Vector2(1448.0, 1086.0)
const CAMERA_ZOOM := Vector2(1.5, 1.5)
const PLAYER_HARD_ZONE_LAYER := 8
const SHOP_COUNTER_FG_Z_INDEX := 20
const SHOP_COUNTER_FG_OFFSET := Vector2(134.0, 470.0)
const SHOP_COUNTER_FG_SCALE := 0.49
const COUNTER_HARD_TOP_Y := 650.0
const COUNTER_STAND_Y := 650.0
const SLOT_OUTLINE_COLOR := Color(1.0, 1.0, 1.0, 0.32)
const SLOT_OUTLINE_FILLED_COLOR := Color(1.0, 0.92, 0.70, 0.42)
const SLOT_EMPTY_RGB_ALPHA := 0.58
const SLOT_EMPTY_RGB_SPEED := 9.75
const SLOT_PIXEL_SNAP := true
const SLOT_LAYOUTS: Array[Dictionary] = [
	{"center": Vector2(666.0, 462.0), "size": Vector2(72.0, 44.0)},
	{"center": Vector2(752.0, 462.0), "size": Vector2(72.0, 44.0)},
	{"center": Vector2(666.0, 520.0), "size": Vector2(72.0, 44.0)},
	{"center": Vector2(752.0, 520.0), "size": Vector2(72.0, 44.0)},
	{"center": Vector2(1035.0, 398.0), "size": Vector2(78.0, 60.0)},
	{"center": Vector2(342.0, 552.0), "size": Vector2(74.0, 70.0), "skew": Vector2(10.0, -14.0)},
]
const SHELF_GROUPS: Array[Dictionary] = [
	{
		"name": "Bàn giữa Ô 1",
		"interact": Vector2(650.0, 602.0),
		"hint": Vector2(650.0, 570.0),
		"slot_name": "Ô 1",
		"slots": [0],
	},
	{
		"name": "Bàn giữa Ô 2",
		"interact": Vector2(778.0, 602.0),
		"hint": Vector2(778.0, 570.0),
		"slot_name": "Ô 2",
		"slots": [1],
	},
	{
		"name": "Bàn giữa Ô 3",
		"interact": Vector2(650.0, 622.0),
		"hint": Vector2(650.0, 632.0),
		"slot_name": "Ô 3",
		"slots": [2],
	},
	{
		"name": "Bàn giữa Ô 4",
		"interact": Vector2(778.0, 622.0),
		"hint": Vector2(778.0, 632.0),
		"slot_name": "Ô 4",
		"slots": [3],
	},
	{
		"name": "Kệ phải",
		"interact": Vector2(914.0, 526.0),
		"hint": Vector2(906.0, 490.0),
		"slot_name": "Ô 1",
		"slots": [4],
	},
	{
		"name": "Kệ trái",
		"interact": Vector2(398.0, 598.0),
		"hint": Vector2(374.0, 570.0),
		"slot_name": "Ô 1",
		"slots": [5],
	},
]

const COLOR_WALL           := Color(0.24, 0.16, 0.09)   # tường gỗ thẫm
const COLOR_WAINSCOT       := Color(0.34, 0.22, 0.11)   # ốp gỗ chân tường
const COLOR_FLOOR          := Color(0.74, 0.58, 0.38)   # sàn gỗ ấm
const COLOR_FLOOR_PLANK    := Color(0.65, 0.50, 0.30)   # vân sàn
const COLOR_RUG            := Color(0.46, 0.16, 0.20)   # thảm đỏ đậm
const COLOR_RUG_INNER      := Color(0.54, 0.22, 0.26)   # lõi thảm
const COLOR_RUG_BORDER     := Color(0.72, 0.52, 0.24)   # viền thảm vàng
const COLOR_WIN_FRAME      := Color(0.44, 0.28, 0.11)   # khung cửa sổ
const COLOR_WIN_GLASS      := Color(0.70, 0.84, 0.92)   # kính xanh nhạt
const COLOR_WIN_CROSS      := Color(0.38, 0.24, 0.09)   # thanh chia kính
const COLOR_SHELF_BACK     := Color(0.26, 0.15, 0.07)   # lưng kệ tối
const COLOR_SHELF          := Color(0.40, 0.26, 0.12)   # thân kệ
const COLOR_SHELF_SURFACE  := Color(0.56, 0.40, 0.20)   # mặt kệ
const COLOR_COUNTER        := Color(0.32, 0.19, 0.08)   # đế quầy
const COLOR_COUNTER_FACE   := Color(0.45, 0.29, 0.12)   # mặt trước quầy
const COLOR_COUNTER_TOP    := Color(0.60, 0.46, 0.22)   # mặt trên quầy
const COLOR_COUNTER_TRIM   := Color(0.72, 0.56, 0.28)   # viền quầy
const COLOR_DOOR           := Color(0.58, 0.46, 0.28)   # cánh cửa
const COLOR_DOOR_FRAME     := Color(0.38, 0.24, 0.10)   # khung cửa
const COLOR_PLANT_POT      := Color(0.64, 0.38, 0.18)   # chậu gốm
const COLOR_PLANT_LEAF     := Color(0.24, 0.54, 0.22)   # lá
const COLOR_PLANT_LEAF_D   := Color(0.17, 0.38, 0.15)   # lá tối
const INTERACT_RANGE: float = 130.0   # px — khoảng cách tối đa để tương tác kệ
const TUTORIAL_OVERLAY_SCRIPT := "res://scripts/ui/tutorial_overlay_ui.gd"
const PATH_PAUSE_MENU := "res://scenes/ui/PauseMenu.tscn"
const STARTER_WEAPON_NAME := "Búa Sắt Cũ"

var _cols: int
var _rows: int
var _shelf_sx: Array[int]  # x gốc các khu bày hàng — tính trong _init_layout()
var _shelf_interact_pos: Array[Vector2]  # vị trí trước mặt mỗi kệ
var _shop_origin := Vector2.ZERO
var _shop_scale := 1.0
var _slot_rgb_time := 0.0
var _camera: Camera2D

var _player: CharacterBody2D
var _shop_mgr: ShopManager
var _neg_ui: NegotiationUI
var _tutorial_overlay: TutorialOverlayUI

var _customers: Dictionary = {}  # instance_id → CustomerAI node
var _neg_queue: Array = []  # instance_id của các khách đang chờ ở quầy
var _active_neg_id: int = -1
var _active_neg_weapon: Dictionary = {}
var _reserved_weapons: Array = []  # vũ khí bị khóa — NPC khác không lấy được

var _shelf_slots: Array = []  # {weapon, icon: Polygon2D|null, outline: Line2D|null}
var _inventory_panel: InventoryPanel
var _near_shelf_idx: int = -1
var _shelf_hint_popups: Array = []  # Node2D popup cho mỗi kệ
var _empty_inventory_hint: Node2D

var _shop_session_done: bool = false

var _shop_hud_layer: CanvasLayer
var _btn_open_shop: Button
var _lbl_shelf_info: Label
var _pause_menu: Node = null


func _init_layout() -> void:
	var vp := get_viewport_rect().size
	_shop_scale = minf(vp.x / SHOP_BG_SIZE.x, vp.y / SHOP_BG_SIZE.y)
	_shop_origin = (vp - SHOP_BG_SIZE * _shop_scale) * 0.5

	_cols = ceili(vp.x / float(TILE))   # 30 @ 1920
	_rows = ceili(vp.y / float(TILE))   # 17 @ 1080

	# Vị trí kệ bám theo asset Shop.PNG.
	_shelf_sx = [
		int(_image_to_world(Vector2(650.0, 0.0)).x),
		int(_image_to_world(Vector2(778.0, 0.0)).x),
		int(_image_to_world(Vector2(650.0, 0.0)).x),
		int(_image_to_world(Vector2(778.0, 0.0)).x),
		int(_image_to_world(Vector2(958.0, 0.0)).x),
		int(_image_to_world(Vector2(382.0, 0.0)).x),
	]
	_shelf_interact_pos.clear()
	for group: Dictionary in SHELF_GROUPS:
		_shelf_interact_pos.append(_image_to_world(group.get("interact", Vector2.ZERO)))


func _ready() -> void:
	_init_layout()
	_build_visuals()
	_build_collision_walls()
	_build_door_player_barrier()
	_build_furniture()
	_spawn_player()
	_setup_camera()
	_build_shelf_system()
	_build_shop_hud()
	_setup_shop_manager()


func _process(delta: float) -> void:
	_update_shelf_proximity()
	_update_empty_slot_highlights(delta)
	_snap_camera_to_pixel_grid()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _pause_menu != null and (_pause_menu as PauseMenuUI).visible:
		return
	_open_pause_menu()
	get_viewport().set_input_as_handled()


func _open_pause_menu() -> void:
	if _pause_menu == null:
		var scene := load(PATH_PAUSE_MENU) as PackedScene
		_pause_menu = scene.instantiate()
		add_child(_pause_menu)
	(_pause_menu as PauseMenuUI).open()


func _update_shelf_proximity() -> void:
	# Không hiện hint khi shop đã mở, panel đang mở, hoặc phiên hết
	if _shop_session_done \
			or (_shop_mgr != null and _shop_mgr.is_open) \
			or (_inventory_panel != null and _inventory_panel.visible) \
			or (_neg_ui != null and _neg_ui.visible) \
			or _player == null:
		_hide_empty_inventory_hint()
		if _near_shelf_idx != -1:
			_near_shelf_idx = -1
			for popup in _shelf_hint_popups:
				(popup as Node2D).visible = false
		return

	var closest: int        = -1
	var closest_dist: float = INTERACT_RANGE
	for i: int in _shelf_interact_pos.size():
		var d: float = _player.position.distance_to(_shelf_interact_pos[i])
		if d < closest_dist:
			closest_dist = d
			closest = i

	if closest != _near_shelf_idx:
		_hide_empty_inventory_hint()
		if _near_shelf_idx >= 0:
			(_shelf_hint_popups[_near_shelf_idx] as Node2D).visible = false
		_near_shelf_idx = closest
		if closest >= 0:
			var popup: Node2D = _shelf_hint_popups[closest]
			popup.modulate.a  = 0.0
			popup.visible     = true
			create_tween().tween_property(popup, "modulate:a", 1.0, 0.18)


# ── Visuals ───────────────────────────────────────────────────────────────────

func _build_visuals() -> void:
	var bg := Sprite2D.new()
	bg.texture = load(SHOP_BG_PATH) as Texture2D
	bg.centered = false
	bg.position = _shop_origin
	bg.scale = Vector2(_shop_scale, _shop_scale)
	bg.z_index = -100
	add_child(bg)

	var counter_fg := Sprite2D.new()
	counter_fg.texture = load(SHOP_COUNTER_FG_PATH) as Texture2D
	counter_fg.centered = false
	counter_fg.position = _image_to_world(SHOP_COUNTER_FG_OFFSET)
	counter_fg.scale = Vector2(_shop_scale, _shop_scale) * SHOP_COUNTER_FG_SCALE
	counter_fg.z_index = SHOP_COUNTER_FG_Z_INDEX
	add_child(counter_fg)


func _image_to_world(point: Vector2) -> Vector2:
	return _shop_origin + point * _shop_scale


func _snap_visual_point(point: Vector2) -> Vector2:
	if not SLOT_PIXEL_SNAP:
		return point
	var step := Vector2(1.0 / CAMERA_ZOOM.x, 1.0 / CAMERA_ZOOM.y)
	return Vector2(
		roundf(point.x / step.x) * step.x,
		roundf(point.y / step.y) * step.y
	)


func _snap_visual_scalar(value: float) -> float:
	if not SLOT_PIXEL_SNAP:
		return value
	var step := 1.0 / CAMERA_ZOOM.x
	return roundf(value / step) * step


func _image_rect_to_world(rect: Rect2) -> Rect2:
	return Rect2(_image_to_world(rect.position), rect.size * _shop_scale)


func _get_shop_world_rect() -> Rect2:
	return Rect2(_shop_origin, SHOP_BG_SIZE * _shop_scale)


func _image_points_to_world(points: Array[Vector2]) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in points:
		result.append(_image_to_world(point))
	return result


# ── Collision ─────────────────────────────────────────────────────────────────

func _build_collision_walls() -> void:
	# Biên shop bám theo nền isometric trong Shop.PNG.
	_hard_zone_poly([
		Vector2(-800.0, -800.0),
		Vector2(0.0, -800.0),
		Vector2(0.0, 1886.0),
		Vector2(-800.0, 1886.0),
	])
	_hard_zone_poly([
		Vector2(1448.0, -800.0),
		Vector2(2248.0, -800.0),
		Vector2(2248.0, 1886.0),
		Vector2(1448.0, 1886.0),
	])
	_hard_zone_poly([
		Vector2(-800.0, -800.0),
		Vector2(2248.0, -800.0),
		Vector2(2248.0, 0.0),
		Vector2(-800.0, 0.0),
	])
	_hard_zone_poly([
		Vector2(-800.0, 1086.0),
		Vector2(2248.0, 1086.0),
		Vector2(2248.0, 1886.0),
		Vector2(-800.0, 1886.0),
	])
	_hard_zone_poly([
		Vector2(0.0, 0.0),
		Vector2(320.0, 28.0),
		Vector2(390.0, 196.0),
		Vector2(170.0, 790.0),
		Vector2(0.0, 1086.0),
	])
	_hard_zone_poly([
		Vector2(320.0, 28.0),
		Vector2(1050.0, 28.0),
		Vector2(1080.0, 196.0),
		Vector2(390.0, 196.0),
	])
	_hard_zone_poly([
		Vector2(1050.0, 28.0),
		Vector2(1448.0, 0.0),
		Vector2(1448.0, 1086.0),
		Vector2(1232.0, 930.0),
		Vector2(1260.0, 802.0),
		Vector2(1180.0, 820.0),
		Vector2(1080.0, 196.0),
	])
	_hard_zone_poly([
		Vector2(0.0, 930.0),
		Vector2(1232.0, 930.0),
		Vector2(1448.0, 1086.0),
		Vector2(0.0, 1086.0),
	])


func _build_door_player_barrier() -> void:
	# Vùng cửa chặn player, NPC vẫn walk in/out vì customer không query layer này.
	_hard_zone_poly([
		Vector2(1082.0, 514.0),
		Vector2(1120.0, 432.0),
		Vector2(1145.0, 470.0),
		Vector2(1134.0, 636.0),
		Vector2(1086.0, 824.0),
		Vector2(1054.0, 782.0),
		Vector2(1074.0, 620.0),
	])


func _build_furniture() -> void:
	# Hard zone theo line đỏ trong reference shop.
	# Mỗi vật thể dùng polygon riêng để mép chặn không kéo lấn xuống đường đi.
	_hard_zone_poly([
		Vector2(392.0, 196.0),
		Vector2(760.0, 196.0),
		Vector2(760.0, 270.0),
		Vector2(470.0, 270.0),
		Vector2(470.0, 236.0),
		Vector2(392.0, 236.0),
	])
	_hard_zone_poly([
		Vector2(330.0, 232.0),
		Vector2(454.0, 300.0),
		Vector2(404.0, 604.0),
		Vector2(292.0, 604.0),
		Vector2(286.0, 540.0),
		Vector2(322.0, 338.0),
	])
	_hard_zone_poly([
		Vector2(782.0, 224.0),
		Vector2(824.0, 168.0),
		Vector2(860.0, 126.0),
		Vector2(866.0, 36.0),
		Vector2(934.0, 20.0),
		Vector2(956.0, 46.0),
		Vector2(960.0, 130.0),
		Vector2(1018.0, 238.0),
		Vector2(982.0, 252.0),
		Vector2(928.0, 264.0),
		Vector2(850.0, 262.0),
		Vector2(802.0, 246.0),
	])
	_hard_zone_poly([
		Vector2(976.0, 352.0),
		Vector2(1072.0, 322.0),
		Vector2(1116.0, 352.0),
		Vector2(1114.0, 460.0),
		Vector2(1040.0, 474.0),
		Vector2(974.0, 448.0),
	])
	_hard_zone_poly([
		Vector2(620.0, 404.0),
		Vector2(812.0, 404.0),
		Vector2(816.0, 552.0),
		Vector2(620.0, 552.0),
		Vector2(612.0, 510.0),
		Vector2(614.0, 430.0),
	])
	# Quầy tính tiền — giữ player trước mép quầy để foreground chỉ che thân dưới.
	_hard_zone_poly([
		Vector2(160.0, COUNTER_HARD_TOP_Y),
		Vector2(730.0, COUNTER_HARD_TOP_Y),
		Vector2(774.0, 700.0),
		Vector2(732.0, 720.0),
		Vector2(402.0, 774.0),
		Vector2(394.0, 850.0),
		Vector2(278.0, 836.0),
		Vector2(264.0, 720.0),
		Vector2(158.0, 718.0),
	])
	_hard_zone_poly([
		Vector2(168.0, 770.0),
		Vector2(276.0, 836.0),
		Vector2(820.0, 850.0),
		Vector2(836.0, 808.0),
		Vector2(918.0, 810.0),
		Vector2(940.0, 850.0),
		Vector2(1130.0, 844.0),
		Vector2(1160.0, 780.0),
		Vector2(1260.0, 802.0),
		Vector2(1232.0, 930.0),
		Vector2(170.0, 930.0),
	])


# ── Player & Camera ───────────────────────────────────────────────────────────

func _spawn_player() -> void:
	_player = load("res://scripts/shop/player_shop.gd").new()
	_player.set("move_speed", PLAYER_MOVE_SPEED)
	_player.position = _image_to_world(Vector2(830.0, 650.0))
	add_child(_player)


func _setup_camera() -> void:
	var cam := Camera2D.new()
	# Tránh camera dừng ở sub-pixel làm Line2D slot bị nhấp nháy lệch.
	cam.position_smoothing_enabled = false
	cam.zoom = CAMERA_ZOOM
	var shop_rect := _get_shop_world_rect()
	cam.limit_left   = int(shop_rect.position.x)
	cam.limit_top    = int(shop_rect.position.y)
	cam.limit_right  = int(shop_rect.end.x)
	cam.limit_bottom = int(shop_rect.end.y)
	_player.add_child(cam)
	_camera = cam
	_snap_camera_to_pixel_grid()
	cam.make_current()


func _snap_camera_to_pixel_grid() -> void:
	if _camera == null or _player == null:
		return
	_camera.global_position = _snap_visual_point(_player.global_position)


# ── Shop Manager ─────────────────────────────────────────────────────────────

func _setup_shop_manager() -> void:
	_shop_mgr = ShopManager.new()
	add_child(_shop_mgr)
	_shop_mgr.customer_arrived.connect(_on_customer_arrived)
	_shop_mgr.customer_left.connect(_on_customer_left_by_manager)
	_shop_mgr.shop_opened.connect(_on_shop_opened)
	_shop_mgr.shop_closed.connect(_on_shop_closed)

	_neg_ui = NegotiationUI.new()
	add_child(_neg_ui)
	_neg_ui.deal_accepted.connect(_on_deal_accepted)
	_neg_ui.trade_accepted.connect(_on_trade_accepted)
	_neg_ui.deal_declined.connect(_on_deal_declined)
	# Shop bắt đầu đóng — player phải bày hàng rồi mới mở


# ── Customer lifecycle ────────────────────────────────────────────────────────

func _on_customer_arrived(data: Dictionary) -> void:
	data.merge(_build_customer_layout(), true)
	var ai := CustomerAI.new()
	add_child(ai)
	ai.setup(data)
	ai.reached_counter.connect(_on_customer_reached_counter)
	ai.left_shop.connect(_on_customer_left_shop)
	_customers[data["instance_id"]] = ai
	var ctype := _customer_dialogue_type(data)
	_show_customer_bubble(ai, NegotiationUI.WALKIN_LINES.get(ctype, ""), 2.5)
	_maybe_show_browse_bubble(ai, data)


func _customer_dialogue_type(data: Dictionary) -> String:
	return data.get("template_id", data.get("type", ""))


func _show_customer_bubble(parent: Node2D, line: String, duration: float) -> void:
	if line.is_empty() or not is_instance_valid(parent):
		return
	var lbl := Label.new()
	lbl.text = line
	lbl.position = Vector2(-120, -92)
	lbl.size = Vector2(240, 58)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.z_index = 80
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.93, 0.76))
	parent.add_child(lbl)
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(lbl):
		lbl.queue_free()


func _maybe_show_browse_bubble(ai: CustomerAI, data: Dictionary) -> void:
	if randf() >= 0.5:
		return
	await get_tree().create_timer(randf_range(1.5, 2.5)).timeout
	if not is_instance_valid(ai):
		return
	var ctype := _customer_dialogue_type(data)
	_show_customer_bubble(ai, NegotiationUI.BROWSE_LINES.get(ctype, ""), 3.0)


func _on_customer_reached_counter(instance_id: int) -> void:
	_neg_queue.append(instance_id)
	_try_next_negotiation()


func _on_customer_left_shop(instance_id: int, reason: String) -> void:
	_customers.erase(instance_id)
	_neg_queue = _neg_queue.filter(func(id: int) -> bool: return id != instance_id)
	# "served"/"dismissed" đã được xử lý qua _on_deal_accepted / _on_deal_declined
	# Chỉ cần báo ShopManager khi khách tự rời (impatient) mà chưa được xử lý
	if reason == "impatient" or reason == "browsed":
		_shop_mgr.customer_walk_out(instance_id)


func _on_customer_left_by_manager(customer: Dictionary, _reason: String) -> void:
	var id: int = customer.get("instance_id", -1)
	if _customers.has(id):
		(_customers[id] as CustomerAI).force_leave()


func _on_shop_opened() -> void:
	_btn_open_shop.text     = "Đang Mở Cửa..."
	_btn_open_shop.disabled = true
	_update_shelf_info_label()


func _on_shop_closed(stats: Dictionary) -> void:
	_neg_queue.clear()
	_active_neg_id     = -1
	_active_neg_weapon = {}
	_reserved_weapons.clear()
	_shop_session_done = true
	_neg_ui.close_ui()
	for ai in _customers.values():
		(ai as CustomerAI).force_leave()
	_btn_open_shop.text     = "Đã bán hàng hôm nay"
	_btn_open_shop.disabled = true
	_update_shelf_info_label()
	_show_session_result(stats)


func _show_session_result(stats: Dictionary) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)

	# Overlay
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 0.72)
	root.add_child(ov)

	var vp  := get_viewport().get_visible_rect()
	const W := 400; const H := 290
	var bx  := int((vp.size.x - W) * 0.5)
	var by  := int((vp.size.y - H) * 0.5)

	# Viền + nền panel
	var border := ColorRect.new()
	border.position = Vector2(bx - 2, by - 2)
	border.size     = Vector2(W + 4, H + 4)
	border.color    = Color(0.72, 0.54, 0.24)
	root.add_child(border)

	var panel := ColorRect.new()
	panel.position = Vector2(bx, by)
	panel.size     = Vector2(W, H)
	panel.color    = Color(0.13, 0.08, 0.05)
	root.add_child(panel)

	# Tiêu đề
	var hdr := ColorRect.new()
	hdr.position = Vector2(bx, by)
	hdr.size     = Vector2(W, 48)
	hdr.color    = Color(0.20, 0.13, 0.07)
	root.add_child(hdr)

	var lbl_title := Label.new()
	lbl_title.text     = "Phiên Bán Hàng Kết Thúc"
	lbl_title.position = Vector2(bx, by + 10)
	lbl_title.size     = Vector2(W, 30)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 27)
	lbl_title.add_theme_color_override("font_color", Color(0.96, 0.88, 0.72))
	root.add_child(lbl_title)

	# Thống kê
	var gold:    int = stats.get("gold_earned",       0)
	var served:  int = stats.get("customers_served",  0)
	var visited: int = stats.get("customers_visited", 0)

	var lines: Array[String] = [
		"Khách vào cửa hàng:   %d" % visited,
		"Giao dịch thành công: %d" % served,
		"Không mua:            %d" % (visited - served),
		"",
		"Vàng thu được:        %dG" % gold,
	]

	for i: int in lines.size():
		var lbl := Label.new()
		lbl.text     = lines[i]
		lbl.position = Vector2(bx + 32, by + 62 + i * 32)
		lbl.size     = Vector2(W - 64, 28)
		lbl.add_theme_font_size_override("font_size", 23)
		var col: Color = Color(1.00, 0.84, 0.26) if i == lines.size() - 1 else Color(0.85, 0.75, 0.58)
		lbl.add_theme_color_override("font_color", col)
		root.add_child(lbl)

	# Nút về xưởng
	var close_btn := Button.new()
	close_btn.position = Vector2(bx + W / 2 - 90, by + H - 52)
	close_btn.size     = Vector2(180, 38)
	close_btn.text     = "Quay về Xưởng"
	close_btn.add_theme_font_size_override("font_size", 21)
	close_btn.pressed.connect(_go_to_hub)
	root.add_child(close_btn)


# ── Negotiation queue ─────────────────────────────────────────────────────────

func _try_next_negotiation() -> void:
	if _active_neg_id != -1 or _neg_queue.is_empty():
		return
	_active_neg_id = _neg_queue.pop_front()
	var found: Array = _shop_mgr.get_customers_in_shop().filter(
		func(c: Dictionary) -> bool: return c.get("instance_id") == _active_neg_id
	)
	if found.is_empty():
		# Khách đã rời đi trước khi đến lượt — chuyển sang người tiếp theo
		_active_neg_id = -1
		_try_next_negotiation()
		return
	var weapon := _npc_pick_weapon(found[0])
	if weapon.is_empty():
		# Kệ trống — khách bỏ đi
		_shop_mgr.customer_walk_out(_active_neg_id)
		if _customers.has(_active_neg_id):
			(_customers[_active_neg_id] as CustomerAI).dismiss_served()
		_active_neg_id = -1
		_try_next_negotiation()
		return
	_active_neg_weapon = weapon
	_reserved_weapons.append(weapon)   # khóa — NPC khác không lấy được
	if _should_show_bargain_tutorial():
		_show_bargain_tutorial(found[0], weapon)
		return
	_neg_ui.present(found[0], weapon)


func _should_show_bargain_tutorial() -> bool:
	return GameManager.current_day == 0 \
		and not GameManager.has_tutorial_seen("day0_bargain_seen")


func _show_bargain_tutorial(customer: Dictionary, weapon: Dictionary) -> void:
	_ensure_tutorial_overlay()
	var on_completed := func() -> void:
		GameManager.mark_tutorial_seen("day0_bargain_seen")
		_neg_ui.present(customer, weapon)
	_tutorial_overlay.completed.connect(on_completed, CONNECT_ONE_SHOT)
	_tutorial_overlay.show_steps([
		{
			"title": "Bargain — Giá khách đề nghị",
			"body": "Khách sẽ đưa giá đầu tiên. Nếu muốn an toàn, "
				+ "chọn 'Bán giá NPC' để chốt ngay.",
		},
		{
			"title": "Bargain — Đề xuất giá",
			"body": "Bạn có 3 lượt đề xuất giá mới. Nhập giá trong vùng gợi ý "
				+ "để khách có thể trả giá lại.",
		},
		{
			"title": "Bargain — Kiên nhẫn",
			"body": "Giá quá cao làm khách mất kiên nhẫn. Hết kiên nhẫn hoặc hết lượt "
				+ "thì khách bỏ đi.",
		},
		{
			"title": "Bargain — Lựa chọn phụ",
			"body": "Một số khách có thể đổi hàng. Nút đe dọa có rủi ro mất uy tín, "
				+ "chỉ dùng khi thật cần.",
		},
	])


func _ensure_tutorial_overlay() -> void:
	if _tutorial_overlay != null:
		return
	var script: GDScript = load(TUTORIAL_OVERLAY_SCRIPT)
	_tutorial_overlay = script.new() as TutorialOverlayUI
	add_child(_tutorial_overlay)


func _on_deal_accepted(weapon: Dictionary, gold: int) -> void:
	var id := _active_neg_id
	_active_neg_id = -1
	_reserved_weapons.erase(_active_neg_weapon)
	_active_neg_weapon = {}
	_remove_weapon_from_shelf(weapon)
	_shop_mgr.complete_sale(id, gold)
	if _customers.has(id):
		(_customers[id] as CustomerAI).dismiss_served()
	_try_next_negotiation()


func _on_trade_accepted(weapon: Dictionary, trade_offer: Dictionary) -> void:
	var id := _active_neg_id
	_active_neg_id = -1
	_reserved_weapons.erase(_active_neg_weapon)
	_active_neg_weapon = {}
	_remove_weapon_from_shelf(weapon)
	InventorySystem.add_trade_offer(trade_offer)
	_shop_mgr.complete_sale(id, 0)
	if _customers.has(id):
		(_customers[id] as CustomerAI).dismiss_served()
	_try_next_negotiation()


func _on_deal_declined() -> void:
	var id := _active_neg_id
	_active_neg_id = -1
	_reserved_weapons.erase(_active_neg_weapon)   # trả hàng về kệ
	_active_neg_weapon = {}
	_shop_mgr.customer_walk_out(id)
	if _customers.has(id):
		(_customers[id] as CustomerAI).dismiss_served()
	_try_next_negotiation()


# ── Customer layout ───────────────────────────────────────────────────────────

# Tính tọa độ thực tế theo viewport để CustomerAI di chuyển đúng vị trí
func _build_customer_layout() -> Dictionary:
	var shelf_fronts: Array = []
	var occupied: Array    = []
	for i: int in SHELF_GROUPS.size():
		shelf_fronts.append(_image_to_world(SHELF_GROUPS[i].get("interact", Vector2.ZERO)))
		var has_item := false
		for slot_idx: int in _get_group_slot_indices(i):
			if not (_shelf_slots[slot_idx].get("weapon", {}) as Dictionary).is_empty():
				has_item = true
				break
		if has_item:
			occupied.append(i)

	var counter_spots: Array = [
		_image_to_world(Vector2(448.0, COUNTER_STAND_Y)),
		_image_to_world(Vector2(548.0, COUNTER_STAND_Y)),
		_image_to_world(Vector2(648.0, COUNTER_STAND_Y)),
	]

	# NPC walk in/out từ cửa bên phải trong asset Shop.PNG.
	var door_entry := _image_to_world(Vector2(1168.0, 662.0))
	var door_exit  := _image_to_world(Vector2(1238.0, 704.0))

	return {
		"shelf_fronts":     shelf_fronts,
		"occupied_shelves": occupied,
		"counter_spots":    counter_spots,
		"door_entry":       door_entry,
		"door_exit":        door_exit,
	}


# ── Helpers ───────────────────────────────────────────────────────────────────

func _poly(rect: Rect2, color: Color) -> void:
	var p := Polygon2D.new()
	p.color = color
	p.polygon = PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])
	add_child(p)


func _draw_plant(x: float, y: float) -> void:
	# Lá (3 mảng đơn giản)
	_poly(Rect2(x + 4,  y,      22, 18), COLOR_PLANT_LEAF)
	_poly(Rect2(x - 4,  y + 10, 18, 14), COLOR_PLANT_LEAF_D)
	_poly(Rect2(x + 18, y + 8,  18, 14), COLOR_PLANT_LEAF_D)
	# Chậu gốm
	_poly(Rect2(x + 2,  y + 22, 26, 18), COLOR_PLANT_POT)
	_poly(Rect2(x,      y + 20, 30,  5), Color(0.70, 0.46, 0.22))
	_poly(Rect2(x + 6,  y + 22, 18,  5), Color(0.22, 0.14, 0.08))


func _wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position       = rect.get_center()
	body.collision_layer = 4   # layer 4 = tường/nội thất
	body.collision_mask  = 0   # tường không query ai
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	col.shape = shape
	body.add_child(col)
	add_child(body)


func _hard_zone_poly(image_points: Array[Vector2]) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = PLAYER_HARD_ZONE_LAYER
	body.collision_mask = 0
	var col := CollisionPolygon2D.new()
	col.polygon = _image_points_to_world(image_points)
	body.add_child(col)
	add_child(body)


func _get_shelf_hint_pos(shelf_idx: int) -> Vector2:
	if shelf_idx < 0 or shelf_idx >= SHELF_GROUPS.size():
		return Vector2.ZERO
	return _image_to_world(SHELF_GROUPS[shelf_idx].get("hint", Vector2.ZERO))


func _get_shelf_name(shelf_idx: int) -> String:
	if shelf_idx < 0 or shelf_idx >= SHELF_GROUPS.size():
		return "Kệ"
	return SHELF_GROUPS[shelf_idx].get("name", "Kệ")


func _get_group_slot_indices(group_idx: int) -> Array:
	if group_idx < 0 or group_idx >= SHELF_GROUPS.size():
		return []
	return SHELF_GROUPS[group_idx].get("slots", [])


# ── Shelf System ──────────────────────────────────────────────────────────────
# Logic: player di chuyển đến gần kệ → hint xuất hiện → bấm [I] → picker mở.
# Picker 2 level: (1) tổng quan kệ, (2) danh sách vũ khí chọn cho từng slot.
# Vũ khí icon là Polygon2D world-space, tự theo camera.

func _build_shelf_system() -> void:
	for _i: int in SLOT_LAYOUTS.size():
		_shelf_slots.append({"weapon": {}, "icon": null, "outline": null})
	_build_slot_outlines()
	_build_shelf_hints()
	_build_empty_inventory_hint()
	_build_inventory_panel()


func _build_slot_outlines() -> void:
	for i: int in SLOT_LAYOUTS.size():
		var outline := _make_slot_outline(i)
		add_child(outline)
		_shelf_slots[i]["outline"] = outline


func _make_slot_outline(slot_idx: int) -> Line2D:
	var layout: Dictionary = SLOT_LAYOUTS[slot_idx]
	var outline := Line2D.new()
	outline.position = _snap_visual_point(_image_to_world(layout.get("center", Vector2.ZERO)))
	outline.points = _get_slot_local_points(layout, 1.0, true)
	outline.default_color = SLOT_OUTLINE_COLOR
	outline.width = maxf(1.0, _snap_visual_scalar(2.0 * _shop_scale))
	outline.z_index = -8
	outline.antialiased = false
	return outline


func _get_slot_local_points(
	layout: Dictionary,
	scale_mult: float,
	closed: bool
) -> PackedVector2Array:
	var size: Vector2 = layout.get("size", Vector2(72.0, 48.0)) * _shop_scale * scale_mult
	var skew: Vector2 = layout.get("skew", Vector2.ZERO) * _shop_scale * scale_mult
	var half := size * 0.5
	var points := PackedVector2Array([
		_snap_visual_point(Vector2(-half.x + skew.x, -half.y + skew.y)),
		_snap_visual_point(Vector2(half.x + skew.x, -half.y + skew.y)),
		_snap_visual_point(Vector2(half.x - skew.x, half.y - skew.y)),
		_snap_visual_point(Vector2(-half.x - skew.x, half.y - skew.y)),
	])
	if closed:
		points.append(points[0])
	return points


func _build_shelf_hints() -> void:
	for i: int in SHELF_GROUPS.size():
		var hint_pos := _get_shelf_hint_pos(i)
		var cx: float = hint_pos.x
		var py: float = hint_pos.y

		var hint_node := Node2D.new()
		hint_node.visible = false
		hint_node.z_index = 5
		add_child(hint_node)

		# Nền tối
		var bg := Polygon2D.new()
		bg.polygon = PackedVector2Array([
			Vector2(cx - 88, py - 2), Vector2(cx + 88, py - 2),
			Vector2(cx + 88, py + 22), Vector2(cx - 88, py + 22),
		])
		bg.color = Color(0.05, 0.03, 0.01, 0.82)
		hint_node.add_child(bg)

		# Viền vàng mỏng trên cùng
		var border := Polygon2D.new()
		border.polygon = PackedVector2Array([
			Vector2(cx - 88, py - 2), Vector2(cx + 88, py - 2),
			Vector2(cx + 88, py + 1), Vector2(cx - 88, py + 1),
		])
		border.color = Color(0.72, 0.56, 0.28, 0.9)
		hint_node.add_child(border)

		# Chữ hướng dẫn
		var lbl := Label.new()
		lbl.text     = "Nhấn [E] — %s" % _get_shelf_name(i)
		lbl.position = Vector2(cx - 87, py + 1)
		lbl.size     = Vector2(174, 20)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", Color(0.96, 0.88, 0.56))
		hint_node.add_child(lbl)

		_shelf_hint_popups.append(hint_node)


func _build_empty_inventory_hint() -> void:
	_empty_inventory_hint = Node2D.new()
	_empty_inventory_hint.visible = false
	_empty_inventory_hint.z_index = 6
	add_child(_empty_inventory_hint)

	var bg := Polygon2D.new()
	bg.name = "Background"
	bg.polygon = PackedVector2Array([
		Vector2(-142, -4), Vector2(142, -4),
		Vector2(142, 30),  Vector2(-142, 30),
	])
	bg.color = Color(0.05, 0.03, 0.01, 0.88)
	_empty_inventory_hint.add_child(bg)

	var border := Polygon2D.new()
	border.name = "Border"
	border.polygon = PackedVector2Array([
		Vector2(-142, -4), Vector2(142, -4),
		Vector2(142, 0),   Vector2(-142, 0),
	])
	border.color = Color(0.90, 0.35, 0.25, 0.95)
	_empty_inventory_hint.add_child(border)

	var lbl := Label.new()
	lbl.text = "Chưa có vũ khí — hãy rèn trước!"
	lbl.position = Vector2(-140, 1)
	lbl.size = Vector2(280, 26)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.98, 0.78, 0.62))
	_empty_inventory_hint.add_child(lbl)


func _show_empty_inventory_hint(shelf_idx: int) -> void:
	if _empty_inventory_hint == null:
		return
	_empty_inventory_hint.position = _get_shelf_hint_pos(shelf_idx) + Vector2(0.0, 30.0)
	_empty_inventory_hint.modulate.a = 0.0
	_empty_inventory_hint.visible = true
	create_tween().tween_property(_empty_inventory_hint, "modulate:a", 1.0, 0.18)


func _hide_empty_inventory_hint() -> void:
	if _empty_inventory_hint == null:
		return
	_empty_inventory_hint.visible = false


func _build_inventory_panel() -> void:
	_inventory_panel = InventoryPanel.new()
	add_child(_inventory_panel)
	_inventory_panel.slot_weapon_changed.connect(_on_slot_weapon_changed)


# E — tương tác kệ gần nhất → mở InventoryPanel (Moonlighter convention)
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and (event as InputEventKey).pressed):
		return
	var key: int = (event as InputEventKey).keycode
	if key != KEY_E:
		return
	if _near_shelf_idx < 0:
		return
	if _shop_session_done or (_shop_mgr != null and _shop_mgr.is_open):
		return
	var inventory_open := _inventory_panel != null and _inventory_panel.visible
	var negotiation_open := _neg_ui != null and _neg_ui.visible
	if inventory_open or negotiation_open:
		return
	var inv := _get_inventory()
	if inv.is_empty():
		_show_empty_inventory_hint(_near_shelf_idx)
		get_viewport().set_input_as_handled()
		return
	_empty_inventory_hint.visible = false
	_inventory_panel.open_shop(inv, _near_shelf_idx, _shelf_slots, SHELF_GROUPS)
	get_viewport().set_input_as_handled()


# Callback từ InventoryPanel khi player chọn đặt/xóa vũ khí trên kệ
func _on_slot_weapon_changed(slot_idx: int, weapon: Dictionary) -> void:
	if _is_protected_starter_weapon(weapon):
		_show_protected_starter_warning()
		return
	_apply_slot_weapon(slot_idx, weapon)
	_update_shelf_info_label()
	_check_all_slots_filled()


func _apply_slot_weapon(slot_idx: int, weapon: Dictionary) -> void:
	var s: Dictionary = _shelf_slots[slot_idx]

	# Xoá icon cũ trong world-space
	if s.get("icon") != null:
		(s["icon"] as Polygon2D).queue_free()
		s["icon"] = null

	s["weapon"] = weapon
	_update_slot_outline(slot_idx, not weapon.is_empty())

	# Tạo icon mới nếu có vũ khí
	if not weapon.is_empty():
		var layout: Dictionary = SLOT_LAYOUTS[slot_idx]
		var icon_pos := _snap_visual_point(_image_to_world(layout.get("center", Vector2.ZERO)))

		var icon := Polygon2D.new()
		icon.polygon = _get_slot_local_points(layout, 0.54, false)
		icon.position = icon_pos
		icon.color    = _slot_color(weapon)
		icon.z_index = -7
		add_child(icon)
		s["icon"] = icon


func _update_slot_outline(slot_idx: int, has_weapon: bool) -> void:
	var outline: Line2D = _shelf_slots[slot_idx].get("outline", null)
	if outline == null:
		return
	outline.visible = not has_weapon
	if not has_weapon:
		outline.default_color = SLOT_OUTLINE_COLOR


func _update_empty_slot_highlights(delta: float) -> void:
	if _shelf_slots.is_empty():
		return
	_slot_rgb_time += delta * SLOT_EMPTY_RGB_SPEED
	for i: int in _shelf_slots.size():
		var slot: Dictionary = _shelf_slots[i]
		if not (slot.get("weapon", {}) as Dictionary).is_empty():
			continue
		var outline: Line2D = slot.get("outline", null)
		if outline == null:
			continue
		outline.default_color = _get_empty_slot_rgb_color(i)


func _get_empty_slot_rgb_color(slot_idx: int) -> Color:
	var t := _slot_rgb_time + float(slot_idx) * 0.65
	var red := 0.55 + sin(t) * 0.35
	var green := 0.55 + sin(t + TAU / 3.0) * 0.35
	var blue := 0.55 + sin(t + TAU * 2.0 / 3.0) * 0.35
	return Color(red, green, blue, SLOT_EMPTY_RGB_ALPHA)


func _get_inventory() -> Array:
	return InventorySystem.get_weapons()


func _get_display_inventory() -> Array:
	var result: Array = []
	for s: Dictionary in _shelf_slots:
		var w: Dictionary = s.get("weapon", {})
		if not w.is_empty() and not result.has(w):
			result.append(w)
	return result


func _slot_color(w: Dictionary) -> Color:
	match w.get("blank_id", ""):
		"kiem_don":  return Color(0.78, 0.28, 0.22)
		"bua_chien": return Color(0.82, 0.68, 0.20)
		"gay_phep":  return Color(0.30, 0.52, 0.82)
		_:           return Color(0.55, 0.42, 0.28)


# ── Shop HUD ──────────────────────────────────────────────────────────────────

func _build_shop_hud() -> void:
	_shop_hud_layer = CanvasLayer.new()
	_shop_hud_layer.layer = 6
	add_child(_shop_hud_layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_hud_layer.add_child(root)

	var vp := get_viewport().get_visible_rect()

	# Nhãn trạng thái kệ — top-right
	_lbl_shelf_info = Label.new()
	_lbl_shelf_info.position = Vector2(vp.size.x - 230, 10)
	_lbl_shelf_info.size     = Vector2(220, 48)
	_lbl_shelf_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_shelf_info.add_theme_font_size_override("font_size", 18)
	_lbl_shelf_info.add_theme_color_override("font_color", Color(0.85, 0.72, 0.44))
	root.add_child(_lbl_shelf_info)

	# Nút "Mở Cửa Hàng" — bottom-center
	_btn_open_shop = Button.new()
	_btn_open_shop.position = Vector2(vp.size.x / 2 - 80, vp.size.y - 64)
	_btn_open_shop.size     = Vector2(160, 46)
	_btn_open_shop.text     = "Mở Cửa Hàng"
	_btn_open_shop.add_theme_font_size_override("font_size", 21)
	_btn_open_shop.pressed.connect(_on_open_shop_pressed)
	root.add_child(_btn_open_shop)

	# Nút "Quay về Xưởng" — bottom-left, ẩn khi đang mở cửa
	var btn_back := Button.new()
	btn_back.position = Vector2(12, vp.size.y - 64)
	btn_back.size     = Vector2(150, 46)
	btn_back.text     = "← Quay về"
	btn_back.add_theme_font_size_override("font_size", 19)
	btn_back.pressed.connect(_go_to_hub)
	root.add_child(btn_back)

	_update_shelf_info_label()


func _on_open_shop_pressed() -> void:
	_open_shop_if_ready()


func _open_shop_if_ready() -> void:
	if _shop_session_done or _shop_mgr.is_open:
		return
	var display := _get_display_inventory()
	if display.is_empty():
		# Cần ít nhất 1 vũ khí trên kệ
		_lbl_shelf_info.text = "Cần bày ít nhất\n1 vũ khí trên kệ!"
		_lbl_shelf_info.add_theme_color_override("font_color", Color(0.90, 0.35, 0.25))
		return
	if not _has_sellable_display_weapon(display):
		_show_protected_starter_warning()
		return
	# Đếm tổng số ô có vũ khí (kể cả trùng lặp) để tính số NPC
	var filled_slots := 0
	for s: Dictionary in _shelf_slots:
		if not s.get("weapon", {}).is_empty():
			filled_slots += 1
	_shop_mgr.set_shelf_inventory(display)
	_shop_mgr.open_shop(filled_slots)


func _check_all_slots_filled() -> void:
	if _shop_session_done or _shop_mgr.is_open:
		return
	var filled := 0
	for s: Dictionary in _shelf_slots:
		if not s.get("weapon", {}).is_empty():
			filled += 1
	if filled == _shelf_slots.size():
		_open_shop_if_ready()


func _update_shelf_info_label() -> void:
	if _lbl_shelf_info == null:
		return
	var filled := 0
	for s: Dictionary in _shelf_slots:
		if not s.get("weapon", {}).is_empty():
			filled += 1

	if _shop_mgr != null and _shop_mgr.is_open:
		_lbl_shelf_info.add_theme_color_override("font_color", Color(0.35, 0.82, 0.45))
		_lbl_shelf_info.text = "Cửa hàng: Đang mở\nKệ: %d/%d vũ khí" % [filled, _shelf_slots.size()]
	else:
		_lbl_shelf_info.add_theme_color_override("font_color", Color(0.85, 0.72, 0.44))
		_lbl_shelf_info.text = "Cửa hàng: Đóng cửa\nKệ: %d/%d vũ khí" % [filled, _shelf_slots.size()]


# ── NPC weapon selection ──────────────────────────────────────────────────────

func _npc_pick_weapon(customer: Dictionary) -> Dictionary:
	# Loại trừ vũ khí đang bị NPC khác giữ ở quầy
	var display := _get_display_inventory().filter(
		func(w: Dictionary) -> bool:
			return not _reserved_weapons.has(w) and not _is_protected_starter_weapon(w)
	)
	if display.is_empty():
		return {}
	var preferred: Array = customer.get("preferred", [])
	var disliked:  Array = customer.get("disliked",  [])
	var best_score: int  = -99
	var candidates: Array = []
	for w: Dictionary in display:
		var tags   := _weapon_tags(w)
		var score: int = 0
		for tag: String in preferred:
			if tag in tags:
				score += 2
		for tag: String in disliked:
			if tag in tags:
				score -= 3
		if score > best_score:
			best_score = score
			candidates = [w]
		elif score == best_score:
			candidates.append(w)
	return candidates[randi() % candidates.size()]


func _weapon_tags(w: Dictionary) -> Array:
	var tags: Array = []
	for key: String in ["blank_id", "suffix", "phase2_prefix", "element"]:
		var v: String = w.get(key, "")
		if not v.is_empty():
			tags.append(v)
	return tags


func _remove_weapon_from_shelf(weapon: Dictionary) -> void:
	if _is_protected_starter_weapon(weapon):
		_show_protected_starter_warning()
		return
	InventorySystem.sell_weapon(weapon)
	for slot_idx in GameManager.equipped_weapons.size():
		if GameManager.equipped_weapons[slot_idx] == weapon:
			GameManager.equipped_weapons[slot_idx] = {}
	for i: int in _shelf_slots.size():
		if _shelf_slots[i].get("weapon", {}) == weapon:
			_apply_slot_weapon(i, {})
	_update_shelf_info_label()
	_shop_mgr.set_shelf_inventory(_get_display_inventory())


func _has_sellable_display_weapon(display: Array) -> bool:
	for weapon: Dictionary in display:
		if not _is_protected_starter_weapon(weapon):
			return true
	return false


func _is_protected_starter_weapon(weapon: Dictionary) -> bool:
	if weapon.is_empty() or GameManager.current_day > 1:
		return false
	return weapon.get("source", "") == "starter" \
		or weapon.get("weapon_name", "") == STARTER_WEAPON_NAME


func _show_protected_starter_warning() -> void:
	_lbl_shelf_info.text = "Không bán Búa Sắt Cũ\nhãy giữ để đi khám phá!"
	_lbl_shelf_info.add_theme_color_override("font_color", Color(0.90, 0.35, 0.25))


func _go_to_hub() -> void:
	SceneManager.go_to("res://scenes/main/WorkshopHub.tscn")
