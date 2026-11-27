# gdlint: disable=max-file-lines
extends Node2D

# ShopScene 32-bit Hoả Tâm — map 1:1 theo shop_bg_640x360.png (2 cửa, 4 ô bàn giữa 2×2)
# - Cửa Trái (Door 1): lối từ Xưởng Rèn sang Tiệm ([E] Quay về Xưởng Rèn)
# - Cửa Phải (Door 2): cửa chính hướng ra phố cho khách hàng vào/ra

const PLAYER_MOVE_SPEED := 300.0
const PLAYER_RENDER_SCALE := 3.0
const CUSTOMER_RENDER_SCALE := 2.75

const SHOP_BG_PATH := "res://assets/pixel/backgrounds/shop_bg_640x360.png"
const SHOP_FG_COUNTER_BANNER_PATH := "res://assets/pixel/backgrounds/shop_fg_counter_banner.png"
const SHOP_FG_RIGHT_DOOR_PATH := "res://assets/pixel/backgrounds/shop_fg_right_door.png"
const SHOP_BG_SIZE := Vector2(640.0, 360.0)
const CAMERA_ZOOM := Vector2.ONE
const WEAPON_SPRITE_DIR := "res://assets/pixel/sprites/weapons/"

const WALL_LAYER := 4
const PLAYER_HARD_ZONE_LAYER := 8

const EMPTY_SLOT_BUBBLE_PATH := "res://assets/pixel/ui/shop/empty_slot_bubble_32.png"
const PORTRAIT_NAM_PATH := "res://assets/pixel/ui/portraits/portrait_nam_256.png"
const BUBBLE_BOB_SPEED := 3.2
const SLOT_PIXEL_SNAP := true

# Tọa độ 4 ô đệm nhung đỏ trên Bàn Giữa 2×2 (đo trực tiếp theo ảnh 640×360)
const SLOT_LAYOUTS: Array[Dictionary] = [
	{"center": Vector2(301.5, 169.0), "size": Vector2(30.0, 16.0)},  # Ô 1 — Trên-Trái
	{"center": Vector2(338.0, 169.0), "size": Vector2(30.0, 16.0)},  # Ô 2 — Trên-Phải
	{"center": Vector2(300.5, 191.5), "size": Vector2(32.0, 17.0)},  # Ô 3 — Dưới-Trái
	{"center": Vector2(339.5, 191.5), "size": Vector2(32.0, 17.0)},  # Ô 4 — Dưới-Phải
]

# Nhóm tương tác bàn trưng bày (tạm thời mở 4 ô bàn giữa, tương lai mở rộng tới 12 ô)
const SHELF_GROUPS: Array[Dictionary] = [
	{
		"name": "Bàn Trưng Bày (4 Ô)",
		"interact": Vector2(320.0, 232.0),
		"interact_points": [
			Vector2(320.0, 232.0),
			Vector2(320.0, 148.0),
			Vector2(266.0, 186.0),
			Vector2(374.0, 186.0),
		],
		"hint": Vector2(320.0, 132.0),
		"slot_names": ["Ô 1", "Ô 2", "Ô 3", "Ô 4"],
		"slots": [0, 1, 2, 3],
	},
]

# Tọa độ 2 cửa chuẩn theo kiến trúc phòng 640×360
const WORKSHOP_DOOR_POS := Vector2(156.0, 212.0)
const WORKSHOP_DOOR_HINT := Vector2(168.0, 162.0)
const PLAYER_SPAWN_POS := Vector2(182.0, 224.0)
const STREET_DOOR_ENTRY := Vector2(510.0, 278.0)
const STREET_DOOR_EXIT := Vector2(524.0, 282.0)

# Vị trí đứng nhặt hàng sát từng ô trên Bàn Giữa 2×2 (hệ 640×360)
const SLOT_PICKUP_SPOTS: Array[Vector2] = [
	Vector2(298.0, 148.0),  # Ô 1 — Trên-Trái
	Vector2(342.0, 148.0),  # Ô 2 — Trên-Phải
	Vector2(298.0, 234.0),  # Ô 3 — Dưới-Trái
	Vector2(342.0, 234.0),  # Ô 4 — Dưới-Phải
]

# Điểm tham quan quanh cửa hàng trước khi tiến tới lấy đồ
const CUSTOMER_BROWSE_SPOTS: Array[Vector2] = [
	Vector2(382.0, 186.0),
	Vector2(342.0, 236.0),
	Vector2(262.0, 186.0),
	Vector2(380.0, 150.0),
]

# Hàng xếp hàng có thứ tự tại quầy thu ngân (tối đa 4 chỗ, khách rời đi sẽ tự đôn hàng lên)
const COUNTER_QUEUE_SPOTS: Array[Vector2] = [
	Vector2(320.0, 274.0),
	Vector2(356.0, 278.0),
	Vector2(392.0, 282.0),
	Vector2(428.0, 286.0),
]

# Vùng đứng sát sau quầy thu ngân để Nấm tính tiền cho khách đang chờ (x=120..238, y=240..272)
const COUNTER_CASHIER_RECT_640 := Rect2(120.0, 240.0, 118.0, 32.0)

# Khung vật cản Bàn Giữa để tính waypoint vòng góc bàn (tránh khách đi xuyên bàn)
const CENTER_TABLE_AVOID_RECT := Rect2(272.0, 152.0, 96.0, 76.0)
const TABLE_CORNER_TL := Vector2(260.0, 148.0)
const TABLE_CORNER_TR := Vector2(380.0, 148.0)
const TABLE_CORNER_BL := Vector2(260.0, 234.0)
const TABLE_CORNER_BR := Vector2(380.0, 234.0)

const INTERACT_RANGE_640 := 46.0
const DOOR_INTERACT_RANGE_640 := 42.0

const TUTORIAL_OVERLAY_SCRIPT := "res://scripts/ui/tutorial_overlay_ui.gd"
const PATH_COMMISSION_DELIVERY_UI := "res://scenes/ui/CommissionDeliveryUI.tscn"
const PATH_PAUSE_MENU := "res://scenes/ui/PauseMenu.tscn"
const FONT_PIXEL_PATH := "res://assets/fonts/PixelifySans.ttf"
const FONT_BOOK_PATH := "res://assets/fonts/Lora-Regular.ttf"
const STARTER_WEAPON_NAME := "Búa Sắt Cũ"
const ECHO_GIFT_POOL: Array[String] = [
	"da_ngoc",
	"pha_le_rung",
	"la_hon",
	"nhua_linh",
	"go_co_thu",
]

var _shop_origin := Vector2.ZERO
var _shop_scale := 3.0
var _bubble_bob_time := 0.0
var _camera: Camera2D
var _actors_root: Node2D

var _player: CharacterBody2D
var _shop_mgr: ShopManager
var _neg_ui: NegotiationUI
var _tutorial_overlay: TutorialOverlayUI
var _commission_delivery_ui: CommissionDeliveryUI = null

var _customers: Dictionary = {}      # instance_id → CustomerAI
var _neg_queue: Array = []           # instance_id đang chờ ở quầy
var _active_neg_id: int = -1
var _active_neg_weapon: Dictionary = {}
var _reserved_weapons: Array = []

var _shelf_slots: Array = []         # {weapon, icon, bubble, bubble_base_y, state, holder_id}
var _inventory_panel: InventoryPanel
var _near_shelf_idx: int = -1
var _near_workshop_door: bool = false
var _near_cashier_counter: bool = false

var _shop_session_done: bool = false

var _shop_hud_layer: CanvasLayer
var _btn_open_shop: Button
var _btn_back_hub: Button
var _lbl_shelf_info: Label
var _lbl_shop_wallet: Label
var _dialogue_box: PanelContainer = null
var _lbl_dlg_speaker: Label = null
var _lbl_dlg_body: Label = null
var _dlg_key_badge: PanelContainer = null
var _dlg_toast_timer: float = 0.0
var _dlg_toast_speaker: String = ""
var _dlg_toast_text: String = ""
var _pause_menu: Node = null


# ══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════════

func _init_layout() -> void:
	var vp := get_viewport_rect().size
	_shop_scale = minf(vp.x / SHOP_BG_SIZE.x, vp.y / SHOP_BG_SIZE.y)
	_shop_origin = (vp - SHOP_BG_SIZE * _shop_scale) * 0.5


func _ready() -> void:
	_init_layout()
	_build_visuals()
	_build_collision_walls()
	_build_door_player_barrier()
	_build_furniture()
	_build_actors_layer()
	_spawn_player()
	_setup_camera()
	_build_shelf_system()
	_preload_saved_shelf_weapons()
	_build_shop_hud()
	_setup_shop_manager()
	_setup_ui()
	_refresh_empty_slot_bubbles()
	_update_shelf_info_label()


func _process(delta: float) -> void:
	if _dlg_toast_timer > 0.0:
		_dlg_toast_timer = maxf(0.0, _dlg_toast_timer - delta)
	_update_proximity_prompts()
	_update_empty_slot_bubbles(delta)
	_update_dialogue_box()
	_update_wallet_label()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _is_any_modal_open():
		return
	if _pause_menu != null and (_pause_menu as PauseMenuUI).visible:
		return
	_open_pause_menu()
	get_viewport().set_input_as_handled()


func _is_any_modal_open() -> bool:
	if _inventory_panel != null and _inventory_panel.visible:
		return true
	if _neg_ui != null and _neg_ui.visible:
		return true
	if _tutorial_overlay != null and _tutorial_overlay.visible:
		return true
	if _commission_delivery_ui != null and _commission_delivery_ui.visible:
		return true
	var echo_modal := get_node_or_null("WeaponEchoModal")
	if echo_modal != null and not echo_modal.is_queued_for_deletion():
		return true
	return false


func _open_pause_menu() -> void:
	if _pause_menu == null:
		var scene := load(PATH_PAUSE_MENU) as PackedScene
		_pause_menu = scene.instantiate()
		add_child(_pause_menu)
	(_pause_menu as PauseMenuUI).open()


# ══════════════════════════════════════════════════════════════════════════════
# PROXIMITY & UNIFIED DIALOGUE BOX (Bàn Trưng Bày + Cửa Trái về Xưởng Rèn)
# ══════════════════════════════════════════════════════════════════════════════

func _update_proximity_prompts() -> void:
	if _shop_session_done or _is_any_modal_open() or _player == null:
		_near_shelf_idx = -1
		_near_workshop_door = false
		_near_cashier_counter = false
		return

	var shop_is_open := _shop_mgr != null and _shop_mgr.is_open
	if shop_is_open:
		_near_shelf_idx = -1
		_near_workshop_door = false
		var p640 := _world_to_image(_player.position)
		_near_cashier_counter = COUNTER_CASHIER_RECT_640.has_point(p640)
		return

	_near_cashier_counter = false

	# 1. Kiểm tra gần Bàn Trưng Bày (4 phía quanh bàn giữa 2×2)
	var interact_dist_world := INTERACT_RANGE_640 * _shop_scale
	var closest_shelf := -1
	var closest_dist := interact_dist_world
	for i: int in SHELF_GROUPS.size():
		var pts: Array = SHELF_GROUPS[i].get("interact_points", [SHELF_GROUPS[i].get("interact", Vector2.ZERO)])
		for p in pts:
			var d := _player.position.distance_to(_image_to_world(p as Vector2))
			if d < closest_dist:
				closest_dist = d
				closest_shelf = i

	# 2. Kiểm tra gần Cửa Trái (về Xưởng Rèn)
	var door_dist := _player.position.distance_to(_image_to_world(WORKSHOP_DOOR_POS))
	var near_door := closest_shelf == -1 and door_dist < DOOR_INTERACT_RANGE_640 * _shop_scale

	_near_shelf_idx = closest_shelf
	_near_workshop_door = near_door


# ══════════════════════════════════════════════════════════════════════════════
# VISUALS & COORDINATE MAPPING (640×360 → World)
# ══════════════════════════════════════════════════════════════════════════════

func _build_visuals() -> void:
	# Nền tối đồng màu viền phòng #120C10 cho màn hình siêu rộng
	var vp := get_viewport_rect().size
	var void_bg := Polygon2D.new()
	void_bg.color = HoaTamUI.COL_OUTLINE
	void_bg.z_index = -110
	void_bg.polygon = PackedVector2Array([
		Vector2(-400, -400),
		Vector2(vp.x + 400, -400),
		Vector2(vp.x + 400, vp.y + 400),
		Vector2(-400, vp.y + 400),
	])
	add_child(void_bg)

	var bg := Sprite2D.new()
	bg.name = "ShopBackground"
	var tex := load(SHOP_BG_PATH) as Texture2D
	bg.texture = tex
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.centered = false
	bg.position = _shop_origin
	if tex != null and tex.get_width() > 0 and tex.get_height() > 0:
		bg.scale = Vector2(
			(SHOP_BG_SIZE.x / float(tex.get_width())) * _shop_scale,
			(SHOP_BG_SIZE.y / float(tex.get_height())) * _shop_scale
		)
	else:
		bg.scale = Vector2(_shop_scale, _shop_scale)
	bg.z_index = -100
	add_child(bg)


func _build_actors_layer() -> void:
	_actors_root = Node2D.new()
	_actors_root.name = "Actors"
	_actors_root.y_sort_enabled = true
	_actors_root.z_index = 0
	add_child(_actors_root)
	_build_foreground_occluders()


func _build_foreground_occluders() -> void:
	# 1. Quầy thu ngân + Đèn bàn + Trụ gỗ & Lá cờ xanh (Y-Sort theo chân trụ y=314)
	# Khi Nấm hoặc khách đi phía sau lá cờ hoặc sau quầy, tiền cảnh tự che thân nhân vật đúng vật lý
	_add_y_sorted_occluder(
		"FgCounterAndBanner",
		SHOP_FG_COUNTER_BANNER_PATH,
		Vector2(108.0, 224.0),
		Vector2(266.0, 314.0)
	)
	# 2. Cánh cửa gỗ bên phải đang mở vào trong (Y-Sort theo mép chân cửa y=254)
	_add_y_sorted_occluder(
		"FgRightOpenDoor",
		SHOP_FG_RIGHT_DOOR_PATH,
		Vector2(464.0, 178.0),
		Vector2(485.0, 254.0)
	)


func _add_y_sorted_occluder(
	node_name: String,
	tex_path: String,
	crop_origin: Vector2,
	sort_anchor: Vector2
) -> void:
	if not ResourceLoader.exists(tex_path):
		return
	var tex := load(tex_path) as Texture2D
	if tex == null:
		return
	var spr := Sprite2D.new()
	spr.name = node_name
	spr.texture = tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.centered = false
	spr.position = _image_to_world(sort_anchor)
	spr.offset = crop_origin - sort_anchor
	spr.scale = Vector2(_shop_scale, _shop_scale)
	_actors_root.add_child(spr)


func _image_to_world(point: Vector2) -> Vector2:
	return _shop_origin + point * _shop_scale


func _snap_visual_point(point: Vector2) -> Vector2:
	if not SLOT_PIXEL_SNAP:
		return point
	return Vector2(roundf(point.x), roundf(point.y))


func _snap_visual_scalar(value: float) -> float:
	if not SLOT_PIXEL_SNAP:
		return value
	return roundf(value)


func _get_shop_world_rect() -> Rect2:
	return Rect2(_shop_origin, SHOP_BG_SIZE * _shop_scale)


func _image_points_to_world(points: Array[Vector2]) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in points:
		result.append(_image_to_world(point))
	return result


# ══════════════════════════════════════════════════════════════════════════════
# COLLISION WALLS & FURNITURE (đo khớp 1:1 theo shop_bg_640x360.png)
# ══════════════════════════════════════════════════════════════════════════════

func _build_collision_walls() -> void:
	# Tường bao ngoài (layer 4 + 8: chặn cả player lẫn khách)
	# Tường trên (chân dãy kệ trên & tường đá)
	_collider_poly([
		Vector2(80.0, 0.0),
		Vector2(560.0, 0.0),
		Vector2(560.0, 142.0),
		Vector2(474.0, 142.0),
		Vector2(474.0, 138.0),
		Vector2(156.0, 138.0),
		Vector2(80.0, 138.0),
	], WALL_LAYER | PLAYER_HARD_ZONE_LAYER)

	# Tường trái (chừa hốc Cửa Trái về Xưởng Rèn tại y=184..238 để player áp sát)
	_collider_poly([
		Vector2(0.0, 0.0),
		Vector2(174.0, 0.0),
		Vector2(174.0, 138.0),
		Vector2(146.0, 192.0),
		Vector2(126.0, 260.0),
		Vector2(108.0, 324.0),
		Vector2(0.0, 360.0),
	], WALL_LAYER | PLAYER_HARD_ZONE_LAYER)

	# Tường phải phía trên Cửa Phải (mở cửa ra phố ở y=254..304)
	_collider_poly([
		Vector2(472.0, 0.0),
		Vector2(640.0, 0.0),
		Vector2(640.0, 252.0),
		Vector2(502.0, 252.0),
		Vector2(472.0, 142.0),
	], WALL_LAYER | PLAYER_HARD_ZONE_LAYER)

	# Tường phải phía dưới Cửa Phải
	_collider_poly([
		Vector2(516.0, 306.0),
		Vector2(640.0, 306.0),
		Vector2(640.0, 360.0),
		Vector2(516.0, 360.0),
	], WALL_LAYER | PLAYER_HARD_ZONE_LAYER)

	# Tường dưới (đáy phòng)
	_collider_poly([
		Vector2(0.0, 314.0),
		Vector2(640.0, 314.0),
		Vector2(640.0, 360.0),
		Vector2(0.0, 360.0),
	], WALL_LAYER | PLAYER_HARD_ZONE_LAYER)


func _build_door_player_barrier() -> void:
	# Rào chỉ chặn Player ở khe Cửa Phải ra phố (layer 8); khách hàng (mask 4) đi qua tự nhiên
	_collider_poly([
		Vector2(496.0, 248.0),
		Vector2(534.0, 248.0),
		Vector2(534.0, 314.0),
		Vector2(496.0, 314.0),
	], PLAYER_HARD_ZONE_LAYER)


func _build_furniture() -> void:
	# Nội thất bên trong dùng layer 8 (chặn Player sát mép gỗ, tránh kẹt đường thẳng của CustomerAI)
	# 1. Cánh kệ dọc chữ L bên trái
	_collider_poly([
		Vector2(150.0, 134.0),
		Vector2(204.0, 134.0),
		Vector2(190.0, 194.0),
		Vector2(144.0, 194.0),
	], PLAYER_HARD_ZONE_LAYER)

	# 2. Thùng gỗ, hòm, bao tải góc trên-phải
	_collider_poly([
		Vector2(356.0, 132.0),
		Vector2(476.0, 132.0),
		Vector2(476.0, 152.0),
		Vector2(432.0, 152.0),
		Vector2(400.0, 144.0),
		Vector2(356.0, 144.0),
	], PLAYER_HARD_ZONE_LAYER)

	# 3. Bàn nghiêng sát tường phải + chỉ chặn mép chân cửa gỗ đang mở (chừa lối đi sau cánh cửa)
	_collider_poly([
		Vector2(438.0, 152.0),
		Vector2(486.0, 140.0),
		Vector2(490.0, 198.0),
		Vector2(462.0, 214.0),
		Vector2(438.0, 178.0),
	], PLAYER_HARD_ZONE_LAYER)
	_collider_poly([
		Vector2(466.0, 246.0),
		Vector2(504.0, 246.0),
		Vector2(504.0, 256.0),
		Vector2(466.0, 256.0),
	], PLAYER_HARD_ZONE_LAYER)

	# 4. Bàn Trưng Bày Giữa 2×2 (4 ô đệm nhung đỏ)
	_collider_poly([
		Vector2(280.0, 160.0),
		Vector2(360.0, 160.0),
		Vector2(360.0, 220.0),
		Vector2(280.0, 220.0),
	], PLAYER_HARD_ZONE_LAYER)

	# 5. Quầy thu ngân chữ L + chỉ chặn đúng thân quầy & chân trụ gỗ (x=108..274)
	# Vùng treo lá cờ vải xanh (x=274..305, y=236..302) để trống để nhân vật đi lướt phía sau cờ
	_collider_poly([
		Vector2(108.0, 266.0),
		Vector2(234.0, 266.0),
		Vector2(234.0, 242.0),
		Vector2(274.0, 242.0),
		Vector2(274.0, 304.0),
		Vector2(286.0, 304.0),
		Vector2(286.0, 316.0),
		Vector2(108.0, 316.0),
	], PLAYER_HARD_ZONE_LAYER)


func _collider_poly(image_points: Array[Vector2], layer_bits: int) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = layer_bits
	body.collision_mask = 0
	var col := CollisionPolygon2D.new()
	col.polygon = _image_points_to_world(image_points)
	body.add_child(col)
	add_child(body)


# ══════════════════════════════════════════════════════════════════════════════
# PLAYER & CAMERA (Full-room 1:1 view, không zoom cắt góc)
# ══════════════════════════════════════════════════════════════════════════════

func _spawn_player() -> void:
	_player = load("res://scripts/shop/player_shop.gd").new()
	_player.render_scale = PLAYER_RENDER_SCALE
	_player.move_speed = PLAYER_MOVE_SPEED
	_player.position = _image_to_world(PLAYER_SPAWN_POS)
	_actors_root.add_child(_player)
	_player.facing_dir = "right"
	_setup_shop_player_shadow_lights()


func _setup_shop_player_shadow_lights() -> void:
	if _player == null or not _player.has_method("set_shadow_lights"):
		return
	# Tọa độ nguồn sáng đo trực tiếp từ ảnh nền shop_bg_640x360.png:
	# - Cửa chính phải: tâm ánh nắng (507.8, 241.6), vệt nắng hắt sang trái-xuống
	# - Đèn treo cửa trái: tâm đèn (124.9, 219.1), hắt sang phải-xuống
	# - Đèn bàn quầy thu ngân: tâm đèn (250.4, 242.1)
	var lights: Array[Dictionary] = [
		{
			"pos": _image_to_world(Vector2(507.8, 241.6)),
			"radius": 285.0 * _shop_scale,
			"strength": 1.20,
			"max_alpha": 0.58,
			"max_length": 0.96,
			"flicker": 0.0,
			"bias_dir": Vector2(-0.86, 0.36),
		},
		{
			"pos": _image_to_world(Vector2(124.9, 219.1)),
			"radius": 225.0 * _shop_scale,
			"strength": 0.84,
			"max_alpha": 0.46,
			"max_length": 0.86,
			"flicker": 0.03,
			"bias_dir": Vector2(0.86, 0.34),
		},
		{
			"pos": _image_to_world(Vector2(250.4, 242.1)),
			"radius": 175.0 * _shop_scale,
			"strength": 0.62,
			"max_alpha": 0.38,
			"max_length": 0.76,
			"flicker": 0.03,
			"bias_dir": Vector2.ZERO,
		},
	]
	_player.call("set_shadow_lights", lights)


func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = false
	cam.zoom = CAMERA_ZOOM
	var shop_rect := _get_shop_world_rect()
	cam.position = shop_rect.get_center()
	cam.limit_left = int(shop_rect.position.x)
	cam.limit_top = int(shop_rect.position.y)
	cam.limit_right = int(shop_rect.end.x)
	cam.limit_bottom = int(shop_rect.end.y)
	add_child(cam)
	_camera = cam
	cam.make_current()


# ══════════════════════════════════════════════════════════════════════════════
# SHOP MANAGER & ECHO MODALS
# ══════════════════════════════════════════════════════════════════════════════

func _setup_shop_manager() -> void:
	_shop_mgr = ShopManager.new()
	add_child(_shop_mgr)
	_shop_mgr.customer_arrived.connect(_on_customer_arrived)
	_shop_mgr.customer_left.connect(_on_customer_left_by_manager)
	_shop_mgr.shop_opened.connect(_on_shop_opened)
	_shop_mgr.shop_closed.connect(_on_shop_closed)
	_shop_mgr.echo_event_triggered.connect(_on_weapon_echo_triggered)
	if not EventBus.commission_fulfilled.is_connected(_on_commission_fulfilled_in_shop):
		EventBus.commission_fulfilled.connect(_on_commission_fulfilled_in_shop)

	_neg_ui = NegotiationUI.new()
	add_child(_neg_ui)
	_neg_ui.deal_accepted.connect(_on_deal_accepted)
	_neg_ui.trade_accepted.connect(_on_trade_accepted)
	_neg_ui.deal_declined.connect(_on_deal_declined)


func _on_weapon_echo_triggered(record: Dictionary) -> void:
	show_weapon_echo_modal(record)


func show_weapon_echo_modal(record: Dictionary) -> CanvasLayer:
	var is_cursed := bool(record.get("is_cursed", false))
	var is_glory := not is_cursed and (
		int(record.get("rarity_tier", 1)) >= 3
		or bool(record.get("perfect_quench", false))
		or bool(record.get("matched_pref", false))
	)
	var npc_id := String(record.get("npc_id", ""))
	var npc_name := String(record.get("npc_name", "Khách quen"))
	var wpn_name := String(record.get("weapon_name", "vũ khí"))
	var sold_price := int(record.get("sold_price", 200))

	var existing_echo := get_node_or_null("WeaponEchoModal")
	if existing_echo != null and not existing_echo.is_queued_for_deletion():
		existing_echo.name = "WeaponEchoModalClosing"
		existing_echo.queue_free()

	var layer := CanvasLayer.new()
	layer.name = "WeaponEchoModal"
	layer.layer = 28
	add_child(layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)

	root.add_child(HoaTamUI.make_dim_backdrop())

	var vp := get_viewport().get_visible_rect().size
	const MW := 700.0
	const MH := 416.0
	var bx := roundf((vp.x - MW) * 0.5)
	var by := roundf((vp.y - MH) * 0.5)

	var panel := Panel.new()
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.position = Vector2(bx, by)
	panel.size = Vector2(MW, MH)
	panel.add_theme_stylebox_override(
		"panel",
		HoaTamUI.make_parchment_panel_style(0.0) if not is_cursed else HoaTamUI.make_wood_panel_style(0.0)
	)
	root.add_child(panel)

	var font_pixel := load(FONT_PIXEL_PATH) as Font
	var font_book := load(FONT_BOOK_PATH) as Font

	var lbl_title := Label.new()
	lbl_title.position = Vector2(bx + 16.0, by + 16.0)
	lbl_title.size = Vector2(MW - 32.0, 32.0)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_pixel != null:
		lbl_title.add_theme_font_override("font", font_pixel)
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.add_theme_color_override(
		"font_color", Color(0.98, 0.72, 0.62) if is_cursed else HoaTamUI.COL_CRIMSON_INK
	)
	if is_cursed:
		lbl_title.text = "TIẾNG VỌNG LỜI NGUYỀN  ·  %s" % npc_name
	elif is_glory:
		lbl_title.text = "TIẾNG VỌNG VINH QUANG  ·  %s" % npc_name
	else:
		lbl_title.text = "TIẾNG VỌNG VŨ KHÍ  ·  %s" % npc_name
	root.add_child(lbl_title)

	var lbl_story := Label.new()
	lbl_story.position = Vector2(bx + 36.0, by + 72.0)
	lbl_story.size = Vector2(MW - 72.0, 184.0)
	lbl_story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font_book != null:
		lbl_story.add_theme_font_override("font", font_book)
	lbl_story.add_theme_font_size_override("font_size", 17)
	lbl_story.add_theme_color_override(
		"font_color", Color(0.96, 0.88, 0.72) if is_cursed else HoaTamUI.COL_INK
	)
	root.add_child(lbl_story)

	var sep := ColorRect.new()
	sep.position = Vector2(bx + 36.0, by + 266.0)
	sep.size = Vector2(MW - 72.0, 1.0)
	sep.color = Color(0.42, 0.28, 0.12)
	root.add_child(sep)

	var lbl_effect := Label.new()
	lbl_effect.position = Vector2(bx + 36.0, by + 278.0)
	lbl_effect.size = Vector2(MW - 72.0, 52.0)
	lbl_effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_effect.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font_pixel != null:
		lbl_effect.add_theme_font_override("font", font_pixel)
	lbl_effect.add_theme_font_size_override("font_size", 15)
	root.add_child(lbl_effect)

	if is_cursed:
		var refund_amt := mini(GameManager.gold, int(sold_price * 0.5))
		lbl_story.text = (
			"%s bước vào tiệm với cánh tay băng bó, đặt \"%s\" lên mặt quầy gỗ:\n\n"
			+ "\"Món đồ này mang ám khí. Đang giao chiến thì lưỡi phản chủ làm tôi bị thương nặng. "
			+ "Chủ tiệm định giải quyết thế nào?\""
		) % [npc_name, wpn_name]
		lbl_effect.text = "Hoàn tiền để giữ Danh tiếng, hoặc từ chối (mất uy tín và đuổi 1 khách chờ)."
		lbl_effect.add_theme_color_override("font_color", Color(0.95, 0.62, 0.42))

		var btn_refund := _make_echo_button("Hoàn 50%% vàng (-%dG)" % refund_amt, false, font_pixel)
		btn_refund.position = Vector2(bx + 44.0, by + MH - 68.0)
		btn_refund.size = Vector2(288.0, 48.0)
		btn_refund.pressed.connect(func() -> void:
			_apply_cursed_echo_refund(npc_id, sold_price)
			layer.queue_free()
		)
		root.add_child(btn_refund)

		var btn_refuse := _make_echo_button("Từ chối (-2 Danh tiếng)", true, font_pixel)
		btn_refuse.position = Vector2(bx + MW - 332.0, by + MH - 68.0)
		btn_refuse.size = Vector2(288.0, 48.0)
		btn_refuse.pressed.connect(func() -> void:
			_apply_cursed_echo_refuse(npc_id)
			layer.queue_free()
		)
		root.add_child(btn_refuse)
	elif is_glory:
		var gift_names := _grant_glory_echo_rewards(npc_id)
		lbl_story.text = (
			"%s rạng rỡ bước vào, đặt \"%s\" còn vương vết trận mạc lên quầy:\n\n"
			+ "\"Nhờ cây %s của Lò Thiêng mà tôi thoát hiểm trong gang tấc. "
			+ "Tôi nhặt được ít nguyên liệu quý dọc đường, xin biếu lại người rèn.\""
		) % [npc_name, wpn_name, wpn_name]
		lbl_effect.text = "Nhận quà: %s  ·  +1 Danh tiếng  ·  +10 Thân thiết" % ", ".join(gift_names)
		lbl_effect.add_theme_color_override("font_color", Color(0.18, 0.46, 0.24))

		var btn_ok := _make_echo_button("Nhận quà & Cảm ơn", true, font_pixel)
		btn_ok.position = Vector2(bx + (MW - 252.0) * 0.5, by + MH - 68.0)
		btn_ok.size = Vector2(252.0, 48.0)
		btn_ok.pressed.connect(func() -> void:
			layer.queue_free()
		)
		root.add_child(btn_ok)
	else:
		GameManager.add_npc_affinity(npc_id, 3)
		lbl_story.text = (
			"%s ghé qua chào Nấm:\n\n"
			+ "\"Món %s hôm trước dùng rất bền tay. Lần tới tôi lại ghé ủng hộ tiệm.\""
		) % [npc_name, wpn_name]
		lbl_effect.text = "+3 Thân thiết với %s" % npc_name
		lbl_effect.add_theme_color_override("font_color", HoaTamUI.COL_INK_MUTE)

		var btn_close := _make_echo_button("Cảm ơn", false, font_pixel)
		btn_close.position = Vector2(bx + (MW - 200.0) * 0.5, by + MH - 68.0)
		btn_close.size = Vector2(200.0, 48.0)
		btn_close.pressed.connect(func() -> void:
			layer.queue_free()
		)
		root.add_child(btn_close)

	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.16)
	return layer


func _make_echo_button(text: String, primary: bool, font_pixel: Font) -> Button:
	var btn := Button.new()
	btn.text = text
	if primary:
		HoaTamUI.apply_primary_button(btn, 16)
	else:
		HoaTamUI.apply_secondary_button(btn, 16)
	if font_pixel != null:
		btn.add_theme_font_override("font", font_pixel)
	return btn


func _grant_glory_echo_rewards(npc_id: String) -> Array[String]:
	var gift_count := randi_range(1, 2)
	var names: Array[String] = []
	for _i in gift_count:
		var item_id: String = ECHO_GIFT_POOL[randi() % ECHO_GIFT_POOL.size()]
		var item: ItemData = ItemDatabase.get_item(item_id)
		if item != null:
			var mat := {
				"item_id": item.item_id,
				"item_name": item.item_name,
				"rarity": item.rarity,
				"base_value": item.base_value,
				"item_type": item.item_type,
			}
			mat.merge(item.effect_data)
			InventorySystem.add_material(mat)
			names.append(item.item_name)
	GameManager.add_reputation(1)
	GameManager.add_npc_affinity(npc_id, 10)
	return names


func _apply_cursed_echo_refund(npc_id: String, sold_price: int) -> void:
	var refund := mini(GameManager.gold, int(sold_price * 0.5))
	if refund > 0:
		GameManager.add_gold(-refund)
	GameManager.add_npc_affinity(npc_id, -3)


func _apply_cursed_echo_refuse(npc_id: String) -> void:
	GameManager.add_reputation(-2)
	GameManager.add_npc_affinity(npc_id, -15)
	if _shop_mgr != null:
		_shop_mgr.dismiss_one_queued_customer()


func _setup_ui() -> void:
	if _commission_delivery_ui != null:
		return
	var deliv_scene := load(PATH_COMMISSION_DELIVERY_UI) as PackedScene
	if deliv_scene != null:
		_commission_delivery_ui = deliv_scene.instantiate() as CommissionDeliveryUI
		add_child(_commission_delivery_ui)


# ══════════════════════════════════════════════════════════════════════════════
# CUSTOMER LIFECYCLE — MOONLIGHTER FLOW (Tham quan → Lấy đúng ô → Xếp hàng quầy → Nấm tính tiền)
# ══════════════════════════════════════════════════════════════════════════════

func _on_customer_arrived(data: Dictionary) -> void:
	var cid: int = int(data.get("instance_id", -1))
	var chosen_slot: int = _claim_available_slot_for_customer(data, cid)
	var layout := _build_customer_route_plan(chosen_slot)
	data.merge(layout, true)

	var ai := CustomerAI.new()
	_actors_root.add_child(ai)
	ai.setup(data)
	ai.item_picked_up.connect(_on_customer_picked_up_item)
	ai.reached_counter.connect(_on_customer_reached_counter)
	ai.item_returned.connect(_on_customer_returned_item)
	ai.left_shop.connect(_on_customer_left_shop)
	_customers[cid] = ai

	var ctype := _customer_dialogue_type(data)
	_show_customer_bubble(ai, String(NegotiationUI.WALKIN_LINES.get(ctype, "")), 2.6)
	_maybe_show_browse_bubble(ai, data)


func _customer_dialogue_type(data: Dictionary) -> String:
	return String(data.get("template_id", data.get("type", "")))


func _show_customer_bubble(parent: Node2D, line: String, duration: float) -> void:
	if line.is_empty() or not is_instance_valid(parent):
		return
	var emote_pos := Vector2(0.0, -56.0 * CUSTOMER_RENDER_SCALE)
	if parent.has_method("get_emote_local_pos"):
		emote_pos = parent.call("get_emote_local_pos")

	var old_bubble := parent.get_node_or_null("SpeechBubble")
	if old_bubble != null:
		old_bubble.queue_free()

	var holder := Node2D.new()
	holder.name = "SpeechBubble"
	holder.z_index = 90
	holder.position = emote_pos + Vector2(0.0, -14.0)
	parent.add_child(holder)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.095, 0.062, 0.068, 0.92)
	sb.border_color = HoaTamUI.COL_BRASS
	sb.set_border_width_all(2)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(220.0, 0.0)
	panel.position = Vector2(-110.0, -52.0)

	var lbl := Label.new()
	lbl.text = line
	lbl.custom_minimum_size = Vector2(200.0, 0.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font_book := load(FONT_BOOK_PATH) as Font
	if font_book != null:
		lbl.add_theme_font_override("font", font_book)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", HoaTamUI.COL_PARCHMENT)
	lbl.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	lbl.add_theme_constant_override("outline_size", 3)
	panel.add_child(lbl)
	holder.add_child(panel)

	await get_tree().create_timer(duration).timeout
	if is_instance_valid(holder):
		holder.queue_free()


func _maybe_show_browse_bubble(ai: CustomerAI, data: Dictionary) -> void:
	if randf() >= 0.5:
		return
	await get_tree().create_timer(randf_range(1.6, 2.6)).timeout
	if not is_instance_valid(ai):
		return
	var ctype := _customer_dialogue_type(data)
	_show_customer_bubble(ai, String(NegotiationUI.BROWSE_LINES.get(ctype, "")), 2.8)


func _on_customer_picked_up_item(instance_id: int, slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= _shelf_slots.size():
		return
	var slot: Dictionary = _shelf_slots[slot_idx]
	if int(slot.get("holder_id", -1)) != instance_id:
		return
	slot["state"] = "carried"
	# Ẩn/xoá sprite khỏi bàn ngay lúc khách nhấc hàng lên tay (dữ liệu vẫn giữ an toàn chưa bán)
	if slot.get("icon") != null:
		(slot["icon"] as Node).queue_free()
		slot["icon"] = null
	_update_shelf_info_label()


func _on_customer_reached_counter(instance_id: int) -> void:
	if not _neg_queue.has(instance_id):
		_neg_queue.append(instance_id)
	_refresh_counter_queue_positions()
	# Không tự bật NegotiationUI — chờ Nấm bước lại sau quầy thu ngân bấm [E]!


func _on_customer_returned_item(instance_id: int, slot_idx: int, weapon: Dictionary) -> void:
	if slot_idx < 0 or slot_idx >= _shelf_slots.size():
		return
	var slot: Dictionary = _shelf_slots[slot_idx]
	var restore_weapon: Dictionary = weapon if not weapon.is_empty() else (slot.get("weapon", {}) as Dictionary)
	if restore_weapon.is_empty():
		return
	# Đặt vũ khí trở lại đúng ô kệ cũ
	if int(slot.get("holder_id", -1)) == instance_id or String(slot.get("state", "")) in ["carried", "returning", "reserved", "empty"]:
		_apply_slot_weapon(slot_idx, restore_weapon)
		slot["state"] = "on_display"
		slot["holder_id"] = -1
		InventorySystem.set_shelf_weapons(_get_display_inventory())
		_update_shelf_info_label()


func _on_customer_left_shop(instance_id: int, reason: String) -> void:
	# Lưới an toàn chống mất đồ: nếu khách rời đi mà vẫn còn giữ ô kệ nào thì trả ngay về kệ cũ
	for i: int in _shelf_slots.size():
		var slot: Dictionary = _shelf_slots[i]
		if int(slot.get("holder_id", -1)) == instance_id:
			var w: Dictionary = slot.get("weapon", {})
			if not w.is_empty():
				_apply_slot_weapon(i, w)
			slot["state"] = "on_display" if not w.is_empty() else "empty"
			slot["holder_id"] = -1

	_customers.erase(instance_id)
	_neg_queue = _neg_queue.filter(func(id: int) -> bool: return id != instance_id)
	_refresh_counter_queue_positions()

	if instance_id == _active_neg_id:
		_active_neg_id = -1
		_reserved_weapons.erase(_active_neg_weapon)
		_active_neg_weapon = {}
		_set_all_customer_wait_paused(false)
		_neg_ui.close_ui()

	if reason in ["declined", "impatient", "browsed"]:
		_shop_mgr.customer_walk_out(instance_id)


func _on_customer_left_by_manager(customer: Dictionary, _reason: String) -> void:
	var id: int = int(customer.get("instance_id", -1))
	if _customers.has(id):
		(_customers[id] as CustomerAI).force_leave()


func _on_shop_opened() -> void:
	if _inventory_panel != null and _inventory_panel.visible:
		_inventory_panel.close()
	_btn_open_shop.text = "Đang Mở Cửa Tiệm..."
	_btn_open_shop.disabled = true
	if _btn_back_hub != null:
		_btn_back_hub.visible = false
	_update_shelf_info_label()


func _on_shop_closed(stats: Dictionary) -> void:
	_neg_queue.clear()
	_active_neg_id = -1
	_active_neg_weapon = {}
	_reserved_weapons.clear()
	_shop_session_done = true
	_neg_ui.close_ui()
	for ai in _customers.values():
		(ai as CustomerAI).force_leave()
	# Đảm bảo đồng bộ lại kệ sau khi mọi khách trả hàng chưa bán
	InventorySystem.set_shelf_weapons(_get_display_inventory())
	_btn_open_shop.text = "Đã bán hàng hôm nay"
	_btn_open_shop.disabled = true
	if _btn_back_hub != null:
		_btn_back_hub.visible = true
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

	root.add_child(HoaTamUI.make_dim_backdrop())

	var vp := get_viewport().get_visible_rect().size
	const W := 480.0
	const H := 340.0
	var bx := roundf((vp.x - W) * 0.5)
	var by := roundf((vp.y - H) * 0.5)

	var panel := Panel.new()
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.position = Vector2(bx, by)
	panel.size = Vector2(W, H)
	panel.add_theme_stylebox_override("panel", HoaTamUI.make_parchment_panel_style(0.0))
	root.add_child(panel)

	var font_px := load(FONT_PIXEL_PATH) as Font
	var font_book := load(FONT_BOOK_PATH) as Font

	var lbl_title := Label.new()
	lbl_title.text = "PHIÊN BÁN HÀNG KẾT THÚC"
	lbl_title.position = Vector2(bx + 24.0, by + 22.0)
	lbl_title.size = Vector2(W - 48.0, 34.0)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_px != null:
		lbl_title.add_theme_font_override("font", font_px)
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.add_theme_color_override("font_color", HoaTamUI.COL_CRIMSON_INK)
	root.add_child(lbl_title)

	var sep := ColorRect.new()
	sep.position = Vector2(bx + 36.0, by + 62.0)
	sep.size = Vector2(W - 72.0, 2.0)
	sep.color = Color(0.54, 0.38, 0.22, 0.6)
	root.add_child(sep)

	var gold: int = int(stats.get("gold_earned", 0))
	var served: int = int(stats.get("customers_served", 0))
	var visited: int = int(stats.get("customers_visited", 0))

	var rows: Array = [
		["Khách ghé cửa hàng:", "%d lượt" % visited, HoaTamUI.COL_INK],
		["Giao dịch thành công:", "%d món" % served, Color(0.18, 0.44, 0.22)],
		["Chưa chốt giao dịch:", "%d lượt" % maxi(0, visited - served), HoaTamUI.COL_INK_MUTE],
		["Tổng vàng thu được:", "+%d G" % gold, HoaTamUI.COL_CRIMSON_INK],
	]

	for i: int in rows.size():
		var row: Array = rows[i]
		var ry: float = by + 84.0 + float(i) * 38.0
		var lbl_k := Label.new()
		lbl_k.text = String(row[0])
		lbl_k.position = Vector2(bx + 42.0, ry)
		lbl_k.size = Vector2(240.0, 28.0)
		if font_book != null:
			lbl_k.add_theme_font_override("font", font_book)
		lbl_k.add_theme_font_size_override("font_size", 18)
		lbl_k.add_theme_color_override("font_color", HoaTamUI.COL_INK)
		root.add_child(lbl_k)

		var lbl_v := Label.new()
		lbl_v.text = String(row[1])
		lbl_v.position = Vector2(bx + W - 212.0, ry)
		lbl_v.size = Vector2(170.0, 28.0)
		lbl_v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if font_px != null:
			lbl_v.add_theme_font_override("font", font_px)
		lbl_v.add_theme_font_size_override("font_size", 20 if i == rows.size() - 1 else 18)
		lbl_v.add_theme_color_override("font_color", row[2] as Color)
		root.add_child(lbl_v)

	var close_btn := Button.new()
	close_btn.position = Vector2(bx + (W - 220.0) * 0.5, by + H - 68.0)
	close_btn.size = Vector2(220.0, 46.0)
	close_btn.text = "Quay về Xưởng Rèn"
	HoaTamUI.apply_primary_button(close_btn, 18)
	close_btn.pressed.connect(_go_to_hub)
	root.add_child(close_btn)


# ══════════════════════════════════════════════════════════════════════════════
# CASHIER QUEUE & NEGOTIATION (Chỉ mở khi Nấm đến sau quầy thu ngân bấm [E])
# ══════════════════════════════════════════════════════════════════════════════

func _set_all_customer_wait_paused(paused: bool) -> void:
	for ai in _customers.values():
		if is_instance_valid(ai):
			(ai as CustomerAI).set_wait_timer_paused(paused)


func _refresh_counter_queue_positions() -> void:
	for idx: int in _neg_queue.size():
		var cid: int = int(_neg_queue[idx])
		if not _customers.has(cid):
			continue
		var ai: CustomerAI = _customers[cid] as CustomerAI
		var spot_idx := mini(idx, COUNTER_QUEUE_SPOTS.size() - 1)
		var spot_640: Vector2 = COUNTER_QUEUE_SPOTS[spot_idx]
		var cur_640 := _world_to_image(ai.position)
		var move_route := _route_around_center_table_world(cur_640, spot_640)
		ai.set_queue_spot(move_route, idx == 0)

		# Cập nhật sẵn đường trả đồ về đúng ô kệ cũ phòng trường hợp hết kiên nhẫn
		if ai.target_slot_idx >= 0 and ai.target_slot_idx < SLOT_PICKUP_SPOTS.size():
			var slot_spot := SLOT_PICKUP_SPOTS[ai.target_slot_idx]
			var ret_route := _route_around_center_table_world(spot_640, slot_spot)
			var exit_route := _route_around_center_table_world(slot_spot, STREET_DOOR_EXIT)
			ai.set_return_and_exit_routes(ret_route, exit_route)
	_update_shelf_info_label()


func _get_front_waiting_customer() -> CustomerAI:
	while not _neg_queue.is_empty():
		var cid: int = int(_neg_queue[0])
		if _customers.has(cid) and is_instance_valid(_customers[cid]):
			return _customers[cid] as CustomerAI
		_neg_queue.pop_front()
	return null


func _start_negotiation_for_front_customer() -> void:
	if _active_neg_id != -1:
		return
	var ai := _get_front_waiting_customer()
	if ai == null:
		return
	var cid: int = ai.instance_id
	var found: Array = _shop_mgr.get_customers_in_shop().filter(
		func(c: Dictionary) -> bool: return int(c.get("instance_id", -1)) == cid
	)
	if found.is_empty():
		_neg_queue.erase(cid)
		_refresh_counter_queue_positions()
		return
	var weapon: Dictionary = ai.carried_weapon
	if weapon.is_empty() and ai.target_slot_idx >= 0 and ai.target_slot_idx < _shelf_slots.size():
		weapon = _shelf_slots[ai.target_slot_idx].get("weapon", {})
	if weapon.is_empty():
		_neg_queue.erase(cid)
		_refresh_counter_queue_positions()
		ai.dismiss_served(_route_around_center_table_world(_world_to_image(ai.position), STREET_DOOR_EXIT))
		return

	_active_neg_id = cid
	_active_neg_weapon = weapon
	if not _reserved_weapons.has(weapon):
		_reserved_weapons.append(weapon)
	# Tạm dừng đồng hồ kiên nhẫn của TẤT CẢ khách trong hàng chờ khi Nấm đang thương lượng
	_set_all_customer_wait_paused(true)
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
			"title": "Thương Lượng — Giá khách đề nghị",
			"body": "Khách sẽ đưa giá đầu tiên. Nếu muốn an toàn, "
				+ "chọn 'Bán giá NPC' để chốt ngay.",
		},
		{
			"title": "Thương Lượng — Đề xuất giá",
			"body": "Bạn có 3 lượt đề xuất giá mới. Nhập giá trong vùng gợi ý "
				+ "để khách có thể trả giá lại.",
		},
		{
			"title": "Thương Lượng — Kiên nhẫn",
			"body": "Giá quá cao làm khách mất kiên nhẫn. Hết kiên nhẫn hoặc hết lượt "
				+ "thì khách bỏ đi.",
		},
		{
			"title": "Thương Lượng — Lựa chọn phụ",
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
	_neg_queue.erase(id)
	_set_all_customer_wait_paused(false)

	if _is_protected_starter_weapon(weapon):
		_show_protected_starter_warning()
		if _customers.has(id):
			(_customers[id] as CustomerAI).dismiss_declined()
		_refresh_counter_queue_positions()
		return

	var success := _shop_mgr.complete_sale(id, gold)
	if success:
		_remove_weapon_from_shelf(weapon)
	if _customers.has(id):
		var ai := _customers[id] as CustomerAI
		var exit_route := _route_around_center_table_world(_world_to_image(ai.position), STREET_DOOR_EXIT)
		ai.dismiss_served(exit_route)
	_refresh_counter_queue_positions()


func _on_trade_accepted(weapon: Dictionary, trade_offer: Dictionary) -> void:
	var id := _active_neg_id
	_active_neg_id = -1
	_reserved_weapons.erase(_active_neg_weapon)
	_active_neg_weapon = {}
	_neg_queue.erase(id)
	_set_all_customer_wait_paused(false)

	if _is_protected_starter_weapon(weapon):
		_show_protected_starter_warning()
		if _customers.has(id):
			(_customers[id] as CustomerAI).dismiss_declined()
		_refresh_counter_queue_positions()
		return

	var success := _shop_mgr.complete_sale(id, 0)
	if success:
		_remove_weapon_from_shelf(weapon)
		InventorySystem.add_trade_offer(trade_offer)
	if _customers.has(id):
		var ai := _customers[id] as CustomerAI
		var exit_route := _route_around_center_table_world(_world_to_image(ai.position), STREET_DOOR_EXIT)
		ai.dismiss_served(exit_route)
	_refresh_counter_queue_positions()


func _on_deal_declined() -> void:
	var id := _active_neg_id
	_active_neg_id = -1
	_reserved_weapons.erase(_active_neg_weapon)
	_active_neg_weapon = {}
	_neg_queue.erase(id)
	_set_all_customer_wait_paused(false)

	if _customers.has(id):
		var ai := _customers[id] as CustomerAI
		var slot_idx := ai.target_slot_idx
		if slot_idx >= 0 and slot_idx < _shelf_slots.size():
			_shelf_slots[slot_idx]["state"] = "returning"
			var cur_640 := _world_to_image(ai.position)
			var slot_spot := SLOT_PICKUP_SPOTS[slot_idx]
			var ret_route := _route_around_center_table_world(cur_640, slot_spot)
			var exit_route := _route_around_center_table_world(slot_spot, STREET_DOOR_EXIT)
			ai.return_item_and_leave(ret_route, exit_route, "declined")
		else:
			var exit_route := _route_around_center_table_world(_world_to_image(ai.position), STREET_DOOR_EXIT)
			ai.return_item_and_leave([], exit_route, "declined")
	else:
		_shop_mgr.customer_walk_out(id)
	_refresh_counter_queue_positions()


# ══════════════════════════════════════════════════════════════════════════════
# CUSTOMER SLOT CLAIMING & WAYPOINT ROUTING (Vòng góc Bàn Giữa — 0% xuyên bàn)
# ══════════════════════════════════════════════════════════════════════════════

func _world_to_image(world_pt: Vector2) -> Vector2:
	if _shop_scale <= 0.0:
		return Vector2.ZERO
	return (world_pt - _shop_origin) / _shop_scale


func _claim_available_slot_for_customer(customer: Dictionary, customer_id: int) -> int:
	var preferred: Array = customer.get("preferred", [])
	var disliked: Array = customer.get("disliked", [])
	var best_score: int = -999
	var candidates: Array[int] = []

	for i: int in _shelf_slots.size():
		var slot: Dictionary = _shelf_slots[i]
		if String(slot.get("state", "empty")) != "on_display":
			continue
		var w: Dictionary = slot.get("weapon", {})
		if w.is_empty() or _is_protected_starter_weapon(w):
			continue
		var tags := _weapon_tags(w)
		var score: int = 0
		for tag: String in preferred:
			if tag in tags:
				score += 2
		for tag: String in disliked:
			if tag in tags:
				score -= 3
		if score > best_score:
			best_score = score
			candidates = [i]
		elif score == best_score:
			candidates.append(i)

	if candidates.is_empty():
		return -1
	var chosen: int = candidates[randi() % candidates.size()]
	_shelf_slots[chosen]["state"] = "reserved"
	_shelf_slots[chosen]["holder_id"] = customer_id
	return chosen


func _build_customer_route_plan(chosen_slot: int) -> Dictionary:
	# 1. Điểm ghé ngắm cửa hàng trước khi tới lấy đồ
	var browse_spot: Vector2 = CUSTOMER_BROWSE_SPOTS[randi() % CUSTOMER_BROWSE_SPOTS.size()]
	var browse_waypoints := _route_around_center_table_world(STREET_DOOR_ENTRY, browse_spot)

	if chosen_slot < 0 or chosen_slot >= SLOT_PICKUP_SPOTS.size():
		return {
			"door_entry": _image_to_world(STREET_DOOR_ENTRY),
			"door_exit": _image_to_world(STREET_DOOR_EXIT),
			"render_scale": CUSTOMER_RENDER_SCALE,
			"target_slot_idx": -1,
			"target_weapon": {},
			"browse_waypoints": browse_waypoints,
			"pickup_waypoints": [],
			"counter_waypoints": [],
			"exit_waypoints": _route_around_center_table_world(browse_spot, STREET_DOOR_EXIT),
		}

	var pickup_spot: Vector2 = SLOT_PICKUP_SPOTS[chosen_slot]
	var queue_idx: int = mini(_neg_queue.size(), COUNTER_QUEUE_SPOTS.size() - 1)
	var counter_spot: Vector2 = COUNTER_QUEUE_SPOTS[queue_idx]
	var target_weapon: Dictionary = _shelf_slots[chosen_slot].get("weapon", {})

	return {
		"door_entry": _image_to_world(STREET_DOOR_ENTRY),
		"door_exit": _image_to_world(STREET_DOOR_EXIT),
		"render_scale": CUSTOMER_RENDER_SCALE,
		"target_slot_idx": chosen_slot,
		"target_weapon": target_weapon,
		"browse_waypoints": browse_waypoints,
		"pickup_waypoints": _route_around_center_table_world(browse_spot, pickup_spot),
		"counter_waypoints": _route_around_center_table_world(pickup_spot, counter_spot),
		"exit_waypoints": _route_around_center_table_world(counter_spot, STREET_DOOR_EXIT),
	}


func _route_around_center_table_world(from_640: Vector2, to_640: Vector2) -> Array[Vector2]:
	var pts_640 := _route_around_center_table_640(from_640, to_640)
	var out: Array[Vector2] = []
	for pt: Vector2 in pts_640:
		out.append(_image_to_world(pt))
	return out


func _route_around_center_table_640(from_pt: Vector2, to_pt: Vector2) -> Array[Vector2]:
	if not _segment_hits_rect(from_pt, to_pt, CENTER_TABLE_AVOID_RECT):
		return [to_pt]

	# So sánh 2 nhánh vòng qua cạnh trái (TL/BL) và cạnh phải (TR/BR) của Bàn Giữa
	var left_path: Array[Vector2] = []
	var right_path: Array[Vector2] = []
	if from_pt.y <= CENTER_TABLE_AVOID_RECT.get_center().y:
		left_path = [TABLE_CORNER_TL, TABLE_CORNER_BL, to_pt]
		right_path = [TABLE_CORNER_TR, TABLE_CORNER_BR, to_pt]
	else:
		left_path = [TABLE_CORNER_BL, TABLE_CORNER_TL, to_pt]
		right_path = [TABLE_CORNER_BR, TABLE_CORNER_TR, to_pt]

	# Lược bỏ góc dư nếu đi tới điểm cùng phía ngang
	left_path = _simplify_corner_path(from_pt, left_path)
	right_path = _simplify_corner_path(from_pt, right_path)
	return left_path if _path_len(from_pt, left_path) <= _path_len(from_pt, right_path) else right_path


func _simplify_corner_path(start: Vector2, path: Array[Vector2]) -> Array[Vector2]:
	if path.size() == 3:
		if not _segment_hits_rect(start, path[1], CENTER_TABLE_AVOID_RECT):
			return [path[1], path[2]]
		if not _segment_hits_rect(path[0], path[2], CENTER_TABLE_AVOID_RECT):
			return [path[0], path[2]]
	return path


func _path_len(start: Vector2, pts: Array[Vector2]) -> float:
	var total := 0.0
	var prev := start
	for pt: Vector2 in pts:
		total += prev.distance_to(pt)
		prev = pt
	return total


func _segment_hits_rect(a: Vector2, b: Vector2, r: Rect2) -> bool:
	if r.has_point(a) or r.has_point(b) or r.has_point((a + b) * 0.5):
		return true
	var p1 := r.position
	var p2 := Vector2(r.end.x, r.position.y)
	var p3 := r.end
	var p4 := Vector2(r.position.x, r.end.y)
	return Geometry2D.segment_intersects_segment(a, b, p1, p2) != null \
		or Geometry2D.segment_intersects_segment(a, b, p2, p3) != null \
		or Geometry2D.segment_intersects_segment(a, b, p3, p4) != null \
		or Geometry2D.segment_intersects_segment(a, b, p4, p1) != null


# ══════════════════════════════════════════════════════════════════════════════
# SHELF SYSTEM (4 Ô Bàn Giữa 2×2 · Bóng thoại dấu ! cho ô trống · Vũ khí 32-bit)
# ══════════════════════════════════════════════════════════════════════════════

func _build_shelf_system() -> void:
	for _i: int in SLOT_LAYOUTS.size():
		_shelf_slots.append({
			"weapon": {},
			"icon": null,
			"bubble": null,
			"bubble_base_y": 0.0,
			"state": "empty",
			"holder_id": -1,
		})
	_build_empty_slot_bubbles()
	_build_inventory_panel()


func _preload_saved_shelf_weapons() -> void:
	var saved_shelf: Array = InventorySystem.get_shelf_weapons().duplicate()
	var limit: int = mini(saved_shelf.size(), _shelf_slots.size())
	for i: int in limit:
		var w: Dictionary = saved_shelf[i]
		if not w.is_empty():
			_apply_slot_weapon(i, w)


func _build_empty_slot_bubbles() -> void:
	var tex := load(EMPTY_SLOT_BUBBLE_PATH) as Texture2D
	for i: int in SLOT_LAYOUTS.size():
		var layout: Dictionary = SLOT_LAYOUTS[i]
		var pad_world := _snap_visual_point(_image_to_world(layout.get("center", Vector2.ZERO) as Vector2))
		var bubble := Sprite2D.new()
		bubble.name = "EmptySlotBubble_%d" % i
		bubble.texture = tex
		bubble.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Ảnh gốc 16x16 nhân 2 -> 32x32; scale 1.5x cho đúng pixel 3x3 khớp 1:1 với nền phòng
		var sc := _shop_scale * 0.5
		bubble.scale = Vector2(sc, sc)
		var base_y := pad_world.y - 6.0 * _shop_scale
		bubble.position = Vector2(pad_world.x, base_y)
		bubble.z_index = 25
		add_child(bubble)
		_shelf_slots[i]["bubble"] = bubble
		_shelf_slots[i]["bubble_base_y"] = base_y


func _refresh_empty_slot_bubbles() -> void:
	var can_show := not _shop_session_done and (_shop_mgr == null or not _shop_mgr.is_open)
	for i: int in _shelf_slots.size():
		var slot: Dictionary = _shelf_slots[i]
		var bubble: Sprite2D = slot.get("bubble", null)
		if bubble == null:
			continue
		var is_empty := (slot.get("weapon", {}) as Dictionary).is_empty()
		bubble.visible = can_show and is_empty


func _update_empty_slot_bubbles(delta: float) -> void:
	if _shelf_slots.is_empty():
		return
	var can_show := not _shop_session_done and (_shop_mgr == null or not _shop_mgr.is_open)
	_bubble_bob_time += delta * BUBBLE_BOB_SPEED
	for i: int in _shelf_slots.size():
		var slot: Dictionary = _shelf_slots[i]
		var bubble: Sprite2D = slot.get("bubble", null)
		if bubble == null:
			continue
		var is_empty := (slot.get("weapon", {}) as Dictionary).is_empty()
		var should_show := can_show and is_empty
		bubble.visible = should_show
		if should_show:
			var base_y: float = float(slot.get("bubble_base_y", bubble.position.y))
			var bob := sin(_bubble_bob_time + float(i) * 0.9) * 3.5
			bubble.position.y = roundf(base_y + bob)


func _build_inventory_panel() -> void:
	_inventory_panel = InventoryPanel.new()
	add_child(_inventory_panel)
	_inventory_panel.slot_weapon_changed.connect(_on_slot_weapon_changed)


func _get_shelf_name(shelf_idx: int) -> String:
	if shelf_idx < 0 or shelf_idx >= SHELF_GROUPS.size():
		return "Bàn Trưng Bày"
	return String(SHELF_GROUPS[shelf_idx].get("name", "Bàn Trưng Bày"))


# [E] tương tác Quầy Thu Ngân (khi mở tiệm), Bàn Trưng Bày hoặc Cửa Trái (khi đóng tiệm)
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and (event as InputEventKey).pressed):
		return
	var key: int = (event as InputEventKey).keycode
	if key != KEY_E:
		return
	if _shop_session_done or _is_any_modal_open():
		return

	# Khi tiệm đang mở: Nấm đứng sau quầy thu ngân bấm [E] để tính tiền cho khách đầu hàng
	if _shop_mgr != null and _shop_mgr.is_open:
		if _near_cashier_counter and _active_neg_id == -1 and _get_front_waiting_customer() != null:
			get_viewport().set_input_as_handled()
			_start_negotiation_for_front_customer()
		return

	if _near_workshop_door:
		get_viewport().set_input_as_handled()
		_go_to_hub()
		return

	if _near_shelf_idx < 0:
		return
	var inv := _get_inventory()
	if inv.is_empty():
		_show_dialogue_toast(
			"NẤM",
			"Trong kho chưa có vũ khí nào — hãy quay về Xưởng Rèn để rèn thêm nhé!",
			3.2
		)
		get_viewport().set_input_as_handled()
		return
	_inventory_panel.open_shop(inv, _near_shelf_idx, _shelf_slots, SHELF_GROUPS)
	get_viewport().set_input_as_handled()


func _on_slot_weapon_changed(slot_idx: int, weapon: Dictionary) -> void:
	if _is_protected_starter_weapon(weapon):
		_show_protected_starter_warning()
		return
	var prev_weapon: Dictionary = _shelf_slots[slot_idx].get("weapon", {})
	_apply_slot_weapon(slot_idx, weapon)
	_sync_inventory_shelf(prev_weapon, weapon)
	_update_shelf_info_label()


func _sync_inventory_shelf(removed_weapon: Dictionary, added_weapon: Dictionary) -> void:
	var on_shelf := _get_display_inventory()
	if not removed_weapon.is_empty() and not on_shelf.has(removed_weapon):
		if not InventorySystem.weapons.has(removed_weapon):
			InventorySystem.weapons.append(removed_weapon)
	if not added_weapon.is_empty() and on_shelf.has(added_weapon):
		InventorySystem.weapons.erase(added_weapon)
		for slot_idx in GameManager.equipped_weapons.size():
			if GameManager.equipped_weapons[slot_idx] == added_weapon:
				GameManager.equipped_weapons[slot_idx] = {}
	InventorySystem.set_shelf_weapons(on_shelf)


func _apply_slot_weapon(slot_idx: int, weapon: Dictionary) -> void:
	if slot_idx < 0 or slot_idx >= _shelf_slots.size():
		return
	if not weapon.is_empty():
		for i: int in _shelf_slots.size():
			if i != slot_idx and _shelf_slots[i].get("weapon", {}) == weapon:
				_shelf_slots[i]["weapon"] = {}
				_shelf_slots[i]["state"] = "empty"
				_shelf_slots[i]["holder_id"] = -1
				if _shelf_slots[i].get("icon") != null:
					(_shelf_slots[i]["icon"] as Node).queue_free()
					_shelf_slots[i]["icon"] = null

	var s: Dictionary = _shelf_slots[slot_idx]
	if s.get("icon") != null:
		(s["icon"] as Node).queue_free()
		s["icon"] = null

	s["weapon"] = weapon
	s["state"] = "on_display" if not weapon.is_empty() else "empty"
	s["holder_id"] = -1

	if not weapon.is_empty():
		var layout: Dictionary = SLOT_LAYOUTS[slot_idx]
		var pad_world := _snap_visual_point(_image_to_world(layout.get("center", Vector2.ZERO) as Vector2))
		var holder := _create_weapon_display_node(weapon, pad_world)
		_actors_root.add_child(holder)
		s["icon"] = holder

	_refresh_empty_slot_bubbles()


func _create_weapon_display_node(weapon: Dictionary, pad_world: Vector2) -> Node2D:
	var holder := Node2D.new()
	holder.position = pad_world

	# 1. Bóng đổ mềm trên tấm đệm nhung đỏ
	var shadow := Polygon2D.new()
	shadow.color = Color(0.06, 0.02, 0.03, 0.52)
	shadow.z_index = -1
	var pts := PackedVector2Array()
	for i in range(12):
		var ang := (float(i) / 12.0) * TAU
		pts.append(Vector2(cos(ang) * 10.0, sin(ang) * 4.5 + 2.5) * _shop_scale)
	shadow.polygon = pts
	holder.add_child(shadow)

	# 2. Sprite 32-bit vũ khí thật (res://assets/pixel/sprites/weapons/*.png)
	var tex := _resolve_weapon_texture(weapon)
	if tex != null:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var max_dim := maxf(1.0, maxf(float(tex.get_width()), float(tex.get_height())))
		var target_px := 24.0 * _shop_scale
		var sc := target_px / max_dim
		spr.scale = Vector2(sc, sc)
		spr.position = Vector2(0.0, -2.0 * _shop_scale)
		holder.add_child(spr)

	return holder


func _resolve_weapon_texture(weapon: Dictionary) -> Texture2D:
	var sprite_path := String(weapon.get("sprite_path", ""))
	if sprite_path.begins_with("res://assets/pixel/") and ResourceLoader.exists(sprite_path):
		return load(sprite_path) as Texture2D
	var blank_id := String(weapon.get("blank_id", ""))
	if not blank_id.is_empty():
		var path := "%s%s.png" % [WEAPON_SPRITE_DIR, blank_id]
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	var fallback := "%skiem_don.png" % WEAPON_SPRITE_DIR
	return load(fallback) as Texture2D if ResourceLoader.exists(fallback) else null


func _get_inventory() -> Array:
	var combined: Array = []
	for s: Dictionary in _shelf_slots:
		var sw: Dictionary = s.get("weapon", {})
		if not sw.is_empty() and not combined.has(sw):
			combined.append(sw)
	for w: Dictionary in InventorySystem.get_weapons():
		if not w.is_empty() and not combined.has(w):
			combined.append(w)
	return combined


func _get_display_inventory() -> Array:
	var result: Array = []
	for s: Dictionary in _shelf_slots:
		var w: Dictionary = s.get("weapon", {})
		if not w.is_empty() and not result.has(w):
			result.append(w)
	return result


# ══════════════════════════════════════════════════════════════════════════════
# SHOP HUD & BOX THOẠI 32-BIT (100% HoaTamUI)
# ══════════════════════════════════════════════════════════════════════════════

func _build_shop_hud() -> void:
	_shop_hud_layer = CanvasLayer.new()
	_shop_hud_layer.layer = 6
	add_child(_shop_hud_layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_hud_layer.add_child(root)

	var font_px := load(FONT_PIXEL_PATH) as Font

	# Top-left: Tên tiệm + Vàng / Danh tiếng
	var left_chip := PanelContainer.new()
	left_chip.anchor_left = 0.0
	left_chip.anchor_top = 0.0
	left_chip.offset_left = 18.0
	left_chip.offset_top = 14.0
	left_chip.add_theme_stylebox_override("panel", HoaTamUI.make_hud_strip_style(16.0, 8.0, false))
	root.add_child(left_chip)

	var left_vb := VBoxContainer.new()
	left_vb.add_theme_constant_override("separation", 2)
	left_chip.add_child(left_vb)

	var lbl_room := Label.new()
	lbl_room.text = "TIỆM RÈN LÒ THIÊNG"
	if font_px != null:
		lbl_room.add_theme_font_override("font", font_px)
	lbl_room.add_theme_font_size_override("font_size", 18)
	lbl_room.add_theme_color_override("font_color", HoaTamUI.COL_GOLD)
	left_vb.add_child(lbl_room)

	_lbl_shop_wallet = Label.new()
	if font_px != null:
		_lbl_shop_wallet.add_theme_font_override("font", font_px)
	_lbl_shop_wallet.add_theme_font_size_override("font_size", 15)
	_lbl_shop_wallet.add_theme_color_override("font_color", HoaTamUI.COL_PARCHMENT)
	left_vb.add_child(_lbl_shop_wallet)
	_update_wallet_label()

	# Top-right: Trạng thái mở cửa & số ô đã bày
	var right_chip := PanelContainer.new()
	right_chip.anchor_left = 1.0
	right_chip.anchor_right = 1.0
	right_chip.anchor_top = 0.0
	right_chip.offset_left = -280.0
	right_chip.offset_right = -18.0
	right_chip.offset_top = 14.0
	right_chip.add_theme_stylebox_override("panel", HoaTamUI.make_hud_strip_style(16.0, 8.0, false))
	root.add_child(right_chip)

	_lbl_shelf_info = Label.new()
	_lbl_shelf_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if font_px != null:
		_lbl_shelf_info.add_theme_font_override("font", font_px)
	_lbl_shelf_info.add_theme_font_size_override("font_size", 16)
	_lbl_shelf_info.add_theme_color_override("font_color", HoaTamUI.COL_GOLD)
	right_chip.add_child(_lbl_shelf_info)

	# 1 Box Thoại duy nhất phía dưới trung tâm (giấy dó 32-bit + chân dung Nấm + phím [E])
	_build_dialogue_box(root)

	# Bottom-center: Nút "MỞ CỬA TIỆM" chuẩn 32-bit
	_btn_open_shop = Button.new()
	_btn_open_shop.anchor_left = 0.5
	_btn_open_shop.anchor_right = 0.5
	_btn_open_shop.anchor_top = 1.0
	_btn_open_shop.anchor_bottom = 1.0
	_btn_open_shop.offset_left = -124.0
	_btn_open_shop.offset_right = 124.0
	_btn_open_shop.offset_top = -68.0
	_btn_open_shop.offset_bottom = -16.0
	_btn_open_shop.text = "MỞ CỬA TIỆM"
	HoaTamUI.apply_primary_button(_btn_open_shop, 20)
	_btn_open_shop.pressed.connect(_on_open_shop_pressed)
	root.add_child(_btn_open_shop)

	# Bottom-left: Nút "← Về Xưởng" (ẩn khi đang mở tiệm)
	_btn_back_hub = Button.new()
	_btn_back_hub.anchor_left = 0.0
	_btn_back_hub.anchor_top = 1.0
	_btn_back_hub.anchor_bottom = 1.0
	_btn_back_hub.offset_left = 18.0
	_btn_back_hub.offset_right = 204.0
	_btn_back_hub.offset_top = -66.0
	_btn_back_hub.offset_bottom = -18.0
	_btn_back_hub.text = "← Về Xưởng"
	HoaTamUI.apply_secondary_button(_btn_back_hub, 18)
	_btn_back_hub.pressed.connect(_go_to_hub)
	root.add_child(_btn_back_hub)


func _build_dialogue_box(parent: Control) -> void:
	var font_px := load(FONT_PIXEL_PATH) as Font
	var font_book := load(FONT_BOOK_PATH) as Font

	_dialogue_box = PanelContainer.new()
	_dialogue_box.name = "ShopDialogueBox"
	_dialogue_box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dialogue_box.anchor_left = 0.5
	_dialogue_box.anchor_right = 0.5
	_dialogue_box.anchor_top = 1.0
	_dialogue_box.anchor_bottom = 1.0
	_dialogue_box.offset_left = -380.0
	_dialogue_box.offset_right = 380.0
	_dialogue_box.offset_top = -170.0
	_dialogue_box.offset_bottom = -80.0
	_dialogue_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_box.add_theme_stylebox_override("panel", HoaTamUI.make_dialogue_panel_style(12.0))
	_dialogue_box.visible = false
	parent.add_child(_dialogue_box)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_dialogue_box.add_child(hbox)

	# Chân dung Nấm nhỏ gọn bên trái box thoại
	var portrait_frame := PanelContainer.new()
	var pf_style := StyleBoxFlat.new()
	pf_style.bg_color = HoaTamUI.COL_WOOD_DARK
	pf_style.border_color = HoaTamUI.COL_BRASS
	pf_style.set_border_width_all(2)
	pf_style.set_content_margin_all(2.0)
	portrait_frame.add_theme_stylebox_override("panel", pf_style)
	portrait_frame.custom_minimum_size = Vector2(58.0, 58.0)
	portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(portrait_frame)

	var portrait := TextureRect.new()
	portrait.texture = load(PORTRAIT_NAM_PATH) as Texture2D
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(52.0, 52.0)
	portrait_frame.add_child(portrait)

	# Vùng nội dung thoại ở giữa
	var text_vb := VBoxContainer.new()
	text_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_vb.add_theme_constant_override("separation", 3)
	hbox.add_child(text_vb)

	_lbl_dlg_speaker = Label.new()
	if font_px != null:
		_lbl_dlg_speaker.add_theme_font_override("font", font_px)
	_lbl_dlg_speaker.add_theme_font_size_override("font_size", 15)
	_lbl_dlg_speaker.add_theme_color_override("font_color", HoaTamUI.COL_GOLD)
	_lbl_dlg_speaker.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	_lbl_dlg_speaker.add_theme_constant_override("outline_size", 3)
	text_vb.add_child(_lbl_dlg_speaker)

	_lbl_dlg_body = Label.new()
	_lbl_dlg_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font_book != null:
		_lbl_dlg_body.add_theme_font_override("font", font_book)
	_lbl_dlg_body.add_theme_font_size_override("font_size", 17)
	_lbl_dlg_body.add_theme_color_override("font_color", HoaTamUI.COL_PARCHMENT)
	_lbl_dlg_body.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	_lbl_dlg_body.add_theme_constant_override("outline_size", 2)
	text_vb.add_child(_lbl_dlg_body)

	# Nhãn phím [E] bên phải khi có thể tương tác
	_dlg_key_badge = PanelContainer.new()
	var key_sb := StyleBoxFlat.new()
	key_sb.bg_color = HoaTamUI.COL_WOOD_DARK
	key_sb.border_color = HoaTamUI.COL_GOLD
	key_sb.set_border_width_all(2)
	key_sb.content_margin_left = 12.0
	key_sb.content_margin_right = 12.0
	key_sb.content_margin_top = 6.0
	key_sb.content_margin_bottom = 6.0
	_dlg_key_badge.add_theme_stylebox_override("panel", key_sb)
	_dlg_key_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(_dlg_key_badge)

	var key_lbl := Label.new()
	key_lbl.text = "[E]"
	if font_px != null:
		key_lbl.add_theme_font_override("font", font_px)
	key_lbl.add_theme_font_size_override("font_size", 18)
	key_lbl.add_theme_color_override("font_color", HoaTamUI.COL_GOLD)
	_dlg_key_badge.add_child(key_lbl)


func _show_dialogue_toast(speaker: String, text: String, duration: float = 3.0) -> void:
	_dlg_toast_speaker = speaker
	_dlg_toast_text = text
	_dlg_toast_timer = duration
	_update_dialogue_box()


func _update_dialogue_box() -> void:
	if _dialogue_box == null:
		return
	if _is_any_modal_open() or _shop_session_done:
		_dialogue_box.visible = false
		return

	if _dlg_toast_timer > 0.0 and not _dlg_toast_text.is_empty():
		_dialogue_box.visible = true
		_lbl_dlg_speaker.text = _dlg_toast_speaker
		_lbl_dlg_body.text = _dlg_toast_text
		_dlg_key_badge.visible = false
		return

	if _shop_mgr != null and _shop_mgr.is_open:
		var front_ai := _get_front_waiting_customer()
		if front_ai != null and _active_neg_id == -1:
			var cname := String(front_ai.customer_data.get("name", "Khách hàng"))
			var wname := String(front_ai.carried_weapon.get("weapon_name", "vũ khí"))
			_dialogue_box.visible = true
			if _near_cashier_counter:
				_lbl_dlg_speaker.text = "NẤM  ·  QUẦY THU NGÂN (%d khách đang chờ)" % _neg_queue.size()
				_lbl_dlg_body.text = "%s muốn mua %s. Nhấn [E] để thương lượng tính tiền!" % [cname, wname]
				_dlg_key_badge.visible = true
			else:
				_lbl_dlg_speaker.text = "NẤM  ·  KHÁCH ĐANG CHỜ TẠI QUẦY"
				_lbl_dlg_body.text = "%s đang cầm %s chờ ở quầy — hãy bước lại sau quầy để tính tiền!" % [cname, wname]
				_dlg_key_badge.visible = false
			return
		_dialogue_box.visible = false
		return

	if _near_shelf_idx >= 0:
		var filled := _get_filled_slot_count()
		var empty_count := _shelf_slots.size() - filled
		_dialogue_box.visible = true
		_lbl_dlg_speaker.text = "NẤM  ·  BÀN TRƯNG BÀY (%d/%d)" % [filled, _shelf_slots.size()]
		if empty_count > 0:
			_lbl_dlg_body.text = "Bàn giữa còn %d ô trống (có dấu !). Nhấn [E] để bày vũ khí lên bán." % empty_count
		else:
			_lbl_dlg_body.text = "Bàn giữa đã bày đủ 4/4 vũ khí. Nhấn [E] để đổi món hoặc bấm Mở Cửa Tiệm."
		_dlg_key_badge.visible = true
		return

	if _near_workshop_door:
		_dialogue_box.visible = true
		_lbl_dlg_speaker.text = "NẤM  ·  CỬA XƯỞNG RÈN"
		_lbl_dlg_body.text = "Lối thông thẳng về Xưởng Rèn. Nhấn [E] để quay lại lò rèn."
		_dlg_key_badge.visible = true
		return

	_dialogue_box.visible = false


func _get_filled_slot_count() -> int:
	var filled := 0
	for s: Dictionary in _shelf_slots:
		if not (s.get("weapon", {}) as Dictionary).is_empty():
			filled += 1
	return filled


func _update_wallet_label() -> void:
	if _lbl_shop_wallet == null:
		return
	_lbl_shop_wallet.text = "Vàng: %dG   ·   Danh tiếng: %d   ·   Ngày %d" % [
		GameManager.gold,
		GameManager.reputation,
		GameManager.current_day,
	]


func _on_open_shop_pressed() -> void:
	_open_shop_if_ready()


func _open_shop_if_ready() -> void:
	if _shop_session_done or _shop_mgr.is_open:
		return
	var display := _get_display_inventory()
	if display.is_empty():
		_show_dialogue_toast(
			"NẤM",
			"Cần bày ít nhất 1 vũ khí lên Bàn Trưng Bày trước khi mở cửa tiệm!",
			3.2
		)
		return
	if not _has_sellable_display_weapon(display):
		_show_protected_starter_warning()
		return
	var filled_slots := _get_filled_slot_count()
	_shop_mgr.set_shelf_inventory(display)
	_shop_mgr.open_shop(filled_slots)


func _update_shelf_info_label() -> void:
	if _lbl_shelf_info == null:
		return
	var filled := _get_filled_slot_count()

	if _shop_mgr != null and _shop_mgr.is_open:
		var on_table := 0
		for s: Dictionary in _shelf_slots:
			if String(s.get("state", "")) in ["on_display", "reserved"]:
				on_table += 1
		_lbl_shelf_info.add_theme_color_override("font_color", HoaTamUI.COL_JADE)
		_lbl_shelf_info.text = "Cửa tiệm: ĐANG MỞ\nTrên bàn: %d/%d · Chờ quầy: %d" % [
			on_table,
			_shelf_slots.size(),
			_neg_queue.size(),
		]
	elif _shop_session_done:
		_lbl_shelf_info.add_theme_color_override("font_color", HoaTamUI.COL_BRASS)
		_lbl_shelf_info.text = "Cửa tiệm: ĐÃ CHỐT PHIÊN\nCòn lại: %d/%d vũ khí" % [filled, _shelf_slots.size()]
	else:
		_lbl_shelf_info.add_theme_color_override("font_color", HoaTamUI.COL_GOLD)
		var ready_hint := " (Sẵn sàng!)" if filled > 0 else " (còn 4 ô !)"
		_lbl_shelf_info.text = "Cửa tiệm: ĐÓNG CỬA\nBàn giữa: %d/%d%s" % [filled, _shelf_slots.size(), ready_hint]


# ══════════════════════════════════════════════════════════════════════════════
# NPC WEAPON SELECTION & SALE SYNC
# ══════════════════════════════════════════════════════════════════════════════

func _npc_pick_weapon(customer: Dictionary) -> Dictionary:
	var display := _get_display_inventory().filter(
		func(w: Dictionary) -> bool:
			return not _reserved_weapons.has(w) and not _is_protected_starter_weapon(w)
	)
	if display.is_empty():
		return {}
	var preferred: Array = customer.get("preferred", [])
	var disliked: Array = customer.get("disliked", [])
	var best_score: int = -99
	var candidates: Array = []
	for w: Dictionary in display:
		var tags := _weapon_tags(w)
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
		var v: String = String(w.get(key, ""))
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
	InventorySystem.set_shelf_weapons(_get_display_inventory())
	_update_shelf_info_label()
	_shop_mgr.set_shelf_inventory(_get_display_inventory())


func _on_commission_fulfilled_in_shop(
		_commission_id: String,
		weapon: Dictionary,
		_reward: Dictionary
) -> void:
	_reserved_weapons.erase(weapon)
	for i: int in _shelf_slots.size():
		if _shelf_slots[i].get("weapon", {}) == weapon:
			_apply_slot_weapon(i, {})
	InventorySystem.set_shelf_weapons(_get_display_inventory())
	_update_shelf_info_label()
	if _shop_mgr != null:
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
	_show_dialogue_toast(
		"NẤM",
		"Không nên bán Búa Sắt Cũ — hãy giữ lại để đi khám phá nhé!",
		3.2
	)


func _go_to_hub() -> void:
	SceneManager.go_to("res://scenes/main/WorkshopHub.tscn")
