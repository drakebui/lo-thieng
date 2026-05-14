extends Node2D

# Layout: động theo viewport (chuẩn 1920×1080 → 30×17 tile, tile 64px)
# Tường dày 1 tile, sàn chơi (_cols-2)×(_rows-2) tile bên trong

const TILE := 64

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

var _cols: int
var _rows: int
var _shelf_sx: Array[int]  # x gốc của 3 kệ — tính trong _init_layout()
var _shelf_interact_pos: Array[Vector2]  # vị trí trước mặt mỗi kệ

var _player: CharacterBody2D
var _shop_mgr: ShopManager
var _neg_ui: NegotiationUI

var _customers: Dictionary = {}  # instance_id → CustomerAI node
var _neg_queue: Array = []  # instance_id của các khách đang chờ ở quầy
var _active_neg_id: int = -1
var _active_neg_weapon: Dictionary = {}
var _reserved_weapons: Array = []  # vũ khí bị khóa — NPC khác không lấy được

var _shelf_slots: Array = []  # {weapon, icon: Polygon2D|null}
var _inventory_panel: InventoryPanel
var _near_shelf_idx: int = -1
var _shelf_hint_popups: Array = []  # Node2D popup cho mỗi kệ
var _empty_inventory_hint: Node2D

var _shop_session_done: bool = false

var _shop_hud_layer: CanvasLayer
var _btn_open_shop: Button
var _lbl_shelf_info: Label


func _init_layout() -> void:
	var vp := get_viewport_rect().size
	_cols = ceili(vp.x / float(TILE))   # 30 @ 1920
	_rows = ceili(vp.y / float(TILE))   # 17 @ 1080
	# Kệ hàng: 3 cột, chia đều trong vùng sàn (TILE..TILE*(_cols-1))
	# Khoảng cách giữa các kệ: TILE*4 → sx[i] = TILE*(2 + i*4) + TILE = TILE*(3 + i*4)
	# Với _cols=30: sx[0]=TILE*3=192, sx[1]=TILE*7=448, sx[2]=TILE*11=704.
	# Scale lên 1920: sx[i] = round(TILE * (3 + i*4) * _cols / 16.0)
	_shelf_sx = [
		int(round(TILE * 3 * _cols / 16.0)),
		int(round(TILE * 7 * _cols / 16.0)),
		int(round(TILE * 11 * _cols / 16.0)),
	]
	# Kệ nằm ở y=TILE, cao 2 tile → phía dưới kệ là y=TILE*3
	_shelf_interact_pos = [
		Vector2(_shelf_sx[0] + TILE, float(TILE * 3)),
		Vector2(_shelf_sx[1] + TILE, float(TILE * 3)),
		Vector2(_shelf_sx[2] + TILE, float(TILE * 3)),
	]


func _ready() -> void:
	_init_layout()
	_build_visuals()
	_build_collision_walls()
	_build_furniture()
	_spawn_player()
	_setup_camera()
	_build_shelf_system()
	_build_shop_hud()
	_setup_shop_manager()


func _process(_delta: float) -> void:
	_update_shelf_proximity()


func _update_shelf_proximity() -> void:
	# Không hiện hint khi shop đã mở, panel đang mở, hoặc phiên hết
	if _shop_session_done \
			or (_shop_mgr != null and _shop_mgr.is_open) \
			or (_inventory_panel != null and _inventory_panel.visible) \
			or (_neg_ui != null and _neg_ui.visible) \
			or _player == null:
		if _near_shelf_idx != -1:
			_near_shelf_idx = -1
			for popup in _shelf_hint_popups:
				(popup as Node2D).visible = false
		return

	var closest: int        = -1
	var closest_dist: float = INTERACT_RANGE
	for i: int in 3:
		var d: float = _player.position.distance_to(_shelf_interact_pos[i])
		if d < closest_dist:
			closest_dist = d
			closest = i

	if closest != _near_shelf_idx:
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
	var inner_w := TILE * (_cols - 2)
	var inner_h := TILE * (_rows - 2)

	# ── Tường gỗ ─────────────────────────────────────────────────────────────
	_poly(Rect2(0, 0, TILE * _cols, TILE * _rows), COLOR_WALL)

	# ── Sàn gỗ ───────────────────────────────────────────────────────────────
	_poly(Rect2(TILE, TILE, inner_w, inner_h), COLOR_FLOOR)
	var plank_count := inner_h / 40 + 1
	for i: int in plank_count:
		_poly(Rect2(TILE + 4, TILE + 36 + i * 40, inner_w - 8, 2), COLOR_FLOOR_PLANK)

	# ── Thảm trang trí trung tâm ─────────────────────────────────────────────
	var rx := TILE * (_cols / 4)
	var ry := TILE * (_rows / 4 + 1)
	var rw := TILE * (_cols / 2)
	var rh := TILE * (_rows / 4)
	_poly(Rect2(rx,     ry,     rw,      rh),      COLOR_RUG)
	_poly(Rect2(rx + 8, ry + 8, rw - 16, rh - 16), COLOR_RUG_INNER)
	_poly(Rect2(rx,           ry,           rw, 10), COLOR_RUG_BORDER)
	_poly(Rect2(rx,           ry + rh - 10, rw, 10), COLOR_RUG_BORDER)
	_poly(Rect2(rx,           ry, 10, rh),           COLOR_RUG_BORDER)
	_poly(Rect2(rx + rw - 10, ry, 10, rh),           COLOR_RUG_BORDER)
	_poly(Rect2(rx,           ry,           20, 20), COLOR_RUG_BORDER)
	_poly(Rect2(rx + rw - 20, ry,           20, 20), COLOR_RUG_BORDER)
	_poly(Rect2(rx,           ry + rh - 20, 20, 20), COLOR_RUG_BORDER)
	_poly(Rect2(rx + rw - 20, ry + rh - 20, 20, 20), COLOR_RUG_BORDER)

	# ── Cửa sổ trong tường hậu — chia đều 3 vị trí ──────────────────────────
	for wci: int in [_cols / 4, _cols / 2, _cols * 3 / 4]:
		var wc := TILE * wci
		_poly(Rect2(wc - 38, 6,  76, 50), COLOR_WIN_FRAME)
		_poly(Rect2(wc - 32, 10, 64, 38), COLOR_WIN_GLASS)
		_poly(Rect2(wc - 32, 27, 64,  4), COLOR_WIN_CROSS)
		_poly(Rect2(wc - 1,  10,  4, 38), COLOR_WIN_CROSS)

	# Ốp gỗ chân tường hậu
	_poly(Rect2(TILE, TILE - 12, inner_w, 12), COLOR_WAINSCOT)

	# ── 3 kệ hàng (dùng _shelf_sx đã tính sẵn) ───────────────────────────────
	for i: int in 3:
		var sx: int = _shelf_sx[i]
		var sy: int = TILE
		_poly(Rect2(sx - 6, sy, TILE * 2 + 12, TILE * 2), COLOR_SHELF_BACK)
		_poly(Rect2(sx, sy, TILE * 2, TILE * 2), COLOR_SHELF)
		_poly(Rect2(sx - 4, sy, TILE * 2 + 8, 14), COLOR_SHELF_SURFACE)
		_poly(Rect2(sx,     sy + TILE - 5, TILE * 2,     10), COLOR_SHELF_BACK)
		_poly(Rect2(sx - 4, sy + TILE - 5, TILE * 2 + 8, 14), COLOR_SHELF_SURFACE)
		_poly(Rect2(sx - 4, sy + TILE * 2 - 10, TILE * 2 + 8, 10), COLOR_SHELF_SURFACE)

	# ── Quầy bán hàng ─────────────────────────────────────────────────────────
	var cx: int = TILE * (_cols * 5 / 16)
	var cy: int = TILE * (_rows - 3)
	var cw: int = TILE * (_cols * 6 / 16)
	var ch: int = TILE * 2
	_poly(Rect2(cx - 8, cy + 20, cw + 16, ch - 20), COLOR_COUNTER)
	_poly(Rect2(cx, cy + 22, cw, ch - 26), COLOR_COUNTER_FACE)
	_poly(Rect2(cx - 8, cy, cw + 16, 24), COLOR_COUNTER_TOP)
	_poly(Rect2(cx - 8, cy + 20, cw + 16, 4), COLOR_COUNTER_TRIM)
	_poly(Rect2(cx + 60, cy + 2, cw - 120, 16), Color(0.22, 0.30, 0.38))
	_poly(Rect2(cx + 62, cy + 3, cw - 124, 12), Color(0.36, 0.50, 0.64))
	_poly(Rect2(cx + 16,      cy + 3, 36, 14), Color(0.82, 0.68, 0.20))
	_poly(Rect2(cx + cw - 52, cy + 3, 36, 14), Color(0.78, 0.28, 0.22))

	# ── Cửa ra vào (tường phải) ───────────────────────────────────────────────
	var door_x := TILE * (_cols - 1)
	var door_y := TILE * 5
	_poly(Rect2(door_x - 8, door_y, 8 + TILE, TILE * 2), COLOR_DOOR_FRAME)
	_poly(Rect2(door_x, door_y, TILE, TILE * 2), COLOR_DOOR)
	_poly(Rect2(door_x + 14, door_y + 18, 36, 44), COLOR_WIN_GLASS)
	_poly(Rect2(door_x + 12, door_y + 16, 40,  4), COLOR_WIN_FRAME)
	_poly(Rect2(door_x + 12, door_y + 58, 40,  4), COLOR_WIN_FRAME)
	_poly(Rect2(door_x + 12, door_y + 16,  4, 46), COLOR_WIN_FRAME)
	_poly(Rect2(door_x + 48, door_y + 16,  4, 46), COLOR_WIN_FRAME)
	_poly(Rect2(door_x + 8,  door_y + 68,  6, 16), Color(0.80, 0.68, 0.22))

	# ── Chậu cây trang trí ───────────────────────────────────────────────────
	_draw_plant(float(TILE + 16), float(TILE * (_rows - 2) + 6))
	_draw_plant(float(TILE * (_cols - 2)) + 12.0, float(TILE * (_rows - 2) + 6))

	# ── Chân tường (baseboard) ────────────────────────────────────────────────
	_poly(Rect2(TILE, TILE * (_rows - 1) - 8, inner_w, 8), COLOR_WAINSCOT)
	_poly(Rect2(TILE,                    TILE,                  8, inner_h),     COLOR_WAINSCOT)
	_poly(Rect2(TILE * (_cols - 1) - 8, TILE, 8, TILE * 4), COLOR_WAINSCOT)
	_poly(Rect2(TILE * (_cols - 1) - 8, TILE * 7, 8, TILE * 4), COLOR_WAINSCOT)


# ── Collision ─────────────────────────────────────────────────────────────────

func _build_collision_walls() -> void:
	_wall(Rect2(0, 0, TILE * _cols, TILE))                             # trên
	_wall(Rect2(0, TILE * (_rows - 1), TILE * _cols, TILE))            # dưới
	_wall(Rect2(0, 0, TILE, TILE * _rows))                             # trái
	# Tường phải — 2 đoạn, chừa cửa (tile row 5-7, cao 2 tile)
	_wall(Rect2(TILE * (_cols - 1), 0, TILE, TILE * 5))
	_wall(Rect2(TILE * (_cols - 1), TILE * 7, TILE, TILE * (_rows - 7)))


func _build_furniture() -> void:
	# Collision cho 3 kệ hàng — dùng _shelf_sx đã tính sẵn
	for i: int in 3:
		_wall(Rect2(_shelf_sx[i], TILE, TILE * 2, TILE * 2))
	# Collision quầy bán hàng — khớp với vị trí trong _build_visuals
	var cx := TILE * (_cols * 5 / 16)
	var cy := TILE * (_rows - 3)
	var cw := TILE * (_cols * 6 / 16)
	_wall(Rect2(cx, cy, cw, TILE * 2))


# ── Player & Camera ───────────────────────────────────────────────────────────

func _spawn_player() -> void:
	_player = load("res://scripts/shop/player_shop.gd").new()
	_player.position = Vector2(TILE * (_cols / 2), TILE * (_rows / 2))
	add_child(_player)


func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed   = 6.0
	cam.limit_left   = 0
	cam.limit_top    = 0
	cam.limit_right  = TILE * _cols
	cam.limit_bottom = TILE * _rows
	_player.add_child(cam)


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
	var ai := CustomerAI.new()
	add_child(ai)
	ai.setup(data)
	ai.reached_counter.connect(_on_customer_reached_counter)
	ai.left_shop.connect(_on_customer_left_shop)
	_customers[data["instance_id"]] = ai


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
	_neg_ui.present(found[0], weapon)


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


# ── Shelf System ──────────────────────────────────────────────────────────────
# Logic: player di chuyển đến gần kệ → hint xuất hiện → bấm [I] → picker mở.
# Picker 2 level: (1) tổng quan kệ, (2) danh sách vũ khí chọn cho từng slot.
# Vũ khí icon là Polygon2D world-space, tự theo camera.

func _build_shelf_system() -> void:
	for _i: int in 6:
		_shelf_slots.append({"weapon": {}, "icon": null})
	_build_shelf_hints()
	_build_empty_inventory_hint()
	_build_inventory_panel()


func _build_shelf_hints() -> void:
	for i: int in 3:
		var cx: float = _shelf_sx[i] + 64.0
		var py: float = TILE - 30.0   # nổi ngay trên đỉnh kệ (trong vùng tường)

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
		lbl.text     = "Nhấn [E] để bày hàng — Kệ %d" % (i + 1)
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
	var cx: float = _shelf_sx[shelf_idx] + 64.0
	_empty_inventory_hint.position = Vector2(cx, TILE + 76.0)
	_empty_inventory_hint.modulate.a = 0.0
	_empty_inventory_hint.visible = true
	create_tween().tween_property(_empty_inventory_hint, "modulate:a", 1.0, 0.18)


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
	_inventory_panel.open_shop(inv, _near_shelf_idx, _shelf_slots)
	get_viewport().set_input_as_handled()


# Callback từ InventoryPanel khi player chọn đặt/xóa vũ khí trên kệ
func _on_slot_weapon_changed(slot_idx: int, weapon: Dictionary) -> void:
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

	# Tạo icon mới nếu có vũ khí
	if not weapon.is_empty():
		var sh: int  = slot_idx / 2
		var row: int = slot_idx % 2
		# Tâm của mỗi hàng kệ trong world-space
		# Hàng trên: y≈93 (giữa vùng 64-123), Hàng dưới: y≈162 (giữa vùng 133-192)
		var icon_pos := Vector2(_shelf_sx[sh] + 64, 93 + row * 69)

		var icon := Polygon2D.new()
		icon.polygon = PackedVector2Array([
			Vector2(-26, -14), Vector2(26, -14),
			Vector2(26,  14),  Vector2(-26, 14),
		])
		icon.position = icon_pos
		icon.color    = _slot_color(weapon)
		add_child(icon)
		s["icon"] = icon


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
		func(w: Dictionary) -> bool: return not _reserved_weapons.has(w)
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
	for i: int in _shelf_slots.size():
		if _shelf_slots[i].get("weapon", {}) == weapon:
			_apply_slot_weapon(i, {})
			_update_shelf_info_label()
			_shop_mgr.set_shelf_inventory(_get_display_inventory())
			return


func _go_to_hub() -> void:
	SceneManager.go_to("res://scenes/main/WorkshopHub.tscn")
