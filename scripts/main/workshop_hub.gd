extends Node2D

const TILE := 64
const PLAYER_MOVE_SPEED := 240.0

const C_WALL      := Color(0.20, 0.12, 0.06)
const C_FLOOR     := Color(0.55, 0.40, 0.25)
const C_FLOOR_ALT := Color(0.48, 0.34, 0.20)
const C_FORGE_BG  := Color(0.22, 0.10, 0.04)
const C_FORGE_FRE := Color(0.92, 0.44, 0.08)
const C_BED_BG    := Color(0.18, 0.30, 0.48)
const C_DOOR      := Color(0.55, 0.42, 0.22)
const C_LABEL_FRG := Color(1.00, 0.80, 0.35)
const C_LABEL_BED := Color(0.72, 0.88, 1.00)
const DAY_CARD_FLAG_PREFIX := "day_scene_card_seen_"

# Scene path
const PATH_FORGE := "res://scenes/forge/WeaponBuilder.tscn"
const PATH_SHOP  := "res://scenes/shop/ShopScene.tscn"
const PATH_INVENTORY := "res://scenes/ui/InventoryUI.tscn"
const PATH_PAUSE_MENU := "res://scenes/ui/PauseMenu.tscn"
const PATH_GAME_OVER := "res://scenes/ui/GameOver.tscn"
const WORKSHOP_BG_PATH := "res://assets/pixel/backgrounds/workshop_hub_bg_640x360.png"
const CO_LONG_GIO_SHEET_PATH := "res://assets/pixel/sprites/npcs/co_long_gio_sheet_64.png"
const NPC_FRAME_SIZE := 64
const NPC_RENDER_SCALE := 2.75
const DAY_SCENE_CARD_SCRIPT := "res://scripts/ui/day_scene_card_ui.gd"
const WORKSHOP_TUTORIAL_CONTROLLER_SCRIPT := "res://scripts/main/workshop_tutorial_controller.gd"
const WORKSHOP_DEBT_CONTROLLER_SCRIPT := "res://scripts/main/workshop_debt_controller.gd"
const WORKSHOP_ATMOSPHERE_SCRIPT := "res://scripts/main/workshop_atmosphere.gd"
const FORGE_RECIPE_BOOK_SCRIPT := "res://scripts/ui/forge_recipe_book_ui.gd"

# Zone IDs
const ZONE_FORGE := "forge"
const ZONE_BED   := "bed"
const ZONE_EXIT  := "exit"
const ZONE_SHOP  := "shop"
const ZONE_FORGE_BOOK := "forge_book"
const ZONE_INVENTORY := "inventory"
const ZONE_DEBT_AGENT := "debt_agent"
const ZONE_DEBT_AGENT_C2 := "debt_agent_c2"
const ZONE_DEBT_AGENT_C3 := "debt_agent_c3"
const ZONE_DEBT_AGENT_C4 := "debt_agent_c4"
const ZONE_VISITOR_CLG := "visitor_co_long_gio"

# Vị trí các zone — tính động theo viewport trong _init_layout()
var cols: int
var rows: int
var _room_left: float
var _room_right: float
var _room_top: float
var _room_bottom: float
var forge_center: Vector2
var forge_size:   Vector2
var bed_center:   Vector2
var bed_size:     Vector2
var door_center_y: float
var door_half_h:   float
var exit_center:  Vector2
var exit_size:    Vector2
var shop_center:  Vector2
var shop_size:    Vector2
var forge_book_center: Vector2
var forge_book_size: Vector2
var inventory_center: Vector2
var inventory_size: Vector2

var _player:    CharacterBody2D
var _near_zone: String = ""
var _overlapping_zones: Array[String] = []

var _region_select: CanvasLayer   # lazy-load
var _day_summary:   CanvasLayer   # lazy-load
var _inventory_ui:  InventoryUI    # lazy-load
var _combat_loadout: CombatLoadoutUI # lazy-load
var _pause_menu: Node = null
var _game_over_ui: Node = null
var _day_card_overlay: DaySceneCardUI = null
var _tutorial_ctrl: WorkshopTutorialController = null
var _debt_ctrl: WorkshopDebtController = null
var _atmosphere: WorkshopAtmosphere = null
var _debt_agents: Dictionary = {}
var _forge_recipe_book_ui: ForgeRecipeBookUI = null
var _visitor_clg: Node2D = null

func _init_layout() -> void:
	var vp := get_viewport_rect().size
	cols          = ceili(vp.x / float(TILE))        # 30 @ 1920
	rows          = ceili(vp.y / float(TILE))        # 17 @ 1080
	# Giới hạn sàn đi lại chuẩn góc nhìn 3/4 của workshop_hub_bg_640x360.png
	_room_left    = vp.x * 0.11
	_room_right   = vp.x * 0.895
	_room_top     = vp.y * 0.42
	_room_bottom  = vp.y * 0.875
	# 6 vùng tương tác bám sát vùng sàn đi tới từng đồ vật
	forge_center      = Vector2(vp.x * 0.345, vp.y * 0.565)
	forge_size        = Vector2(vp.x * 0.21,  vp.y * 0.17)
	forge_book_center = Vector2(vp.x * 0.58,  vp.y * 0.465)
	forge_book_size   = Vector2(vp.x * 0.12,  vp.y * 0.10)
	bed_center        = Vector2(vp.x * 0.72,  vp.y * 0.505)
	bed_size          = Vector2(vp.x * 0.14,  vp.y * 0.11)
	inventory_center  = Vector2(vp.x * 0.775, vp.y * 0.62)
	inventory_size    = Vector2(vp.x * 0.12,  vp.y * 0.10)
	door_center_y     = vp.y * 0.73
	door_half_h       = vp.y * 0.085
	exit_center       = Vector2(vp.x * 0.165, vp.y * 0.73)
	exit_size         = Vector2(vp.x * 0.10,  vp.y * 0.17)
	shop_center       = Vector2(vp.x * 0.855, vp.y * 0.745)
	shop_size         = Vector2(vp.x * 0.10,  vp.y * 0.16)


func _ready() -> void:
	y_sort_enabled = true
	if not GameManager.save_restored:
		if SaveSystem.has_save():
			var data := SaveSystem.load_game()
			GameManager.restore_from_save(data)
		else:
			GameManager.init_new_game()
			GameManager.save_restored = true
	_init_layout()
	_build_room()
	_build_player()
	_build_zones()
	_build_atmosphere()
	_ensure_debt_controller()
	_ensure_tutorial_controller()
	add_child(preload("res://scenes/ui/HUD.tscn").instantiate())
	_connect_signals()
	_ensure_game_over_ui()
	_sync_debt_agent_scene()
	if not GameManager.pending_day_summary_stats.is_empty():
		var stats := GameManager.pending_day_summary_stats.duplicate()
		GameManager.pending_day_summary_stats = {}
		if GameManager.current_day == 0 and not GameManager.has_tutorial_seen("explore_phase_seen"):
			_tutorial_ctrl.show_tutorial_then(
				GuideBook.get_explore_steps(),
				"explore_phase_seen",
				func() -> void: _open_day_summary(stats)
			)
		else:
			_open_day_summary(stats)
	_sync_debt_overlays()
	if not _show_day_start_card_if_needed():
		_tutorial_ctrl.sync_script()
	_tutorial_ctrl.sync_day1_scripted()
	_build_hub_visitors()
	AudioManager.play_sfx_loop("furnace_burn", 0.14)


func _exit_tree() -> void:
	AudioManager.stop_sfx_loop()


func _process(_delta: float) -> void:
	if _player == null:
		return
	var blocked := _has_blocking_overlay()
	_player.set("can_move", not blocked)
	# Điều chỉnh âm thanh lửa lò âm ỉ theo khoảng cách tới lò rèn
	var dist := _player.position.distance_to(forge_center)
	var prox := clampf(1.0 - dist / 950.0, 0.0, 1.0)
	var target_vol := 0.06 if blocked else lerpf(0.08, 0.34, prox)
	AudioManager.set_sfx_loop_volume(target_vol)


func _unhandled_input(event: InputEvent) -> void:
	if _day_card_overlay != null:
		return
	if _forge_recipe_book_ui != null and _forge_recipe_book_ui.visible:
		return
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		_open_pause_menu()
		get_viewport().set_input_as_handled()
		return
	if key.pressed and not key.echo and key.keycode == KEY_I:
		_open_inventory()
		get_viewport().set_input_as_handled()
		return
	if _is_debug_reset_key(key):
		_debug_reset_game()
		get_viewport().set_input_as_handled()
		return
	if key.pressed and key.keycode == KEY_E and _near_zone != "":
		_activate_zone(_near_zone)
		get_viewport().set_input_as_handled()


func _is_debug_reset_key(key: InputEventKey) -> bool:
	return (
		OS.has_feature("editor")
		and key.pressed
		and not key.echo
		and (key.ctrl_pressed or key.meta_pressed)
		and key.keycode == KEY_R
	)


func _build_room() -> void:
	var vp := get_viewport_rect().size
	var bg_tex := load(WORKSHOP_BG_PATH) as Texture2D
	if bg_tex != null:
		var bg_rect := TextureRect.new()
		bg_rect.texture = bg_tex
		bg_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
		bg_rect.position = Vector2.ZERO
		bg_rect.size = vp
		bg_rect.z_index = -10
		add_child(bg_rect)
	else:
		# Fallback an toàn nếu thiếu ảnh nền 32-bit
		var bg := ColorRect.new()
		bg.position = Vector2.ZERO
		bg.size     = Vector2(TILE * cols, TILE * rows)
		bg.color    = C_WALL
		bg.z_index  = -10
		add_child(bg)

		var floor_bg := ColorRect.new()
		floor_bg.position = Vector2(_room_left, _room_top)
		floor_bg.size     = Vector2(_room_right - _room_left, _room_bottom - _room_top)
		floor_bg.color    = C_FLOOR
		floor_bg.z_index  = -9
		add_child(floor_bg)

	_build_wall_collision()


func _build_atmosphere() -> void:
	var script: GDScript = load(WORKSHOP_ATMOSPHERE_SCRIPT)
	_atmosphere = script.new() as WorkshopAtmosphere
	add_child(_atmosphere)
	_atmosphere.setup(get_viewport_rect().size, GameManager.current_phase)


func _build_wall_collision() -> void:
	var sb := StaticBody2D.new()
	sb.collision_layer = 4
	sb.collision_mask  = 0
	add_child(sb)

	var vp := get_viewport_rect().size
	# 1. Tường trên & tường dưới phòng
	_wall_seg(sb, Vector2(0.0, 0.0), Vector2(vp.x, vp.y * 0.42))
	_wall_seg(sb, Vector2(0.0, vp.y * 0.875), Vector2(vp.x, vp.y * 0.125))
	# 2. Tường vát chéo trái & phải theo đúng góc nhìn 3/4 cutaway
	_wall_poly(sb, PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(vp.x * 0.21, 0.0),
		Vector2(vp.x * 0.205, vp.y * 0.42),
		Vector2(vp.x * 0.11, vp.y * 0.875),
		Vector2(0.0, vp.y * 0.875),
	]))
	_wall_poly(sb, PackedVector2Array([
		Vector2(vp.x * 0.79, 0.0),
		Vector2(vp.x, 0.0),
		Vector2(vp.x, vp.y * 0.875),
		Vector2(vp.x * 0.895, vp.y * 0.875),
		Vector2(vp.x * 0.805, vp.y * 0.42),
	]))
	# 3. Va chạm từng cụm đồ vật (không đi xuyên qua cửa mở, lò rèn, đe, bục sách, giường, rương)
	_wall_norm_rect(sb, vp, 0.145, 0.42, 0.235, 0.655)  # Cánh cửa mở + thùng gỗ trái
	_wall_norm_rect(sb, vp, 0.23,  0.42, 0.505, 0.495)  # Chân lò đá + 2 thùng nước tôi
	_wall_norm_rect(sb, vp, 0.345, 0.47, 0.438, 0.585)  # Gốc cây & đe sắt
	_wall_norm_rect(sb, vp, 0.53,  0.42, 0.632, 0.45)   # Chân bục Bí Kíp Rèn + cuộn giấy
	_wall_norm_rect(sb, vp, 0.70,  0.42, 0.845, 0.565)  # Giường ngủ
	_wall_norm_rect(sb, vp, 0.732, 0.55, 0.825, 0.61)   # Rương gỗ cuối giường


func _wall_norm_rect(
	parent: StaticBody2D, vp: Vector2, x0: float, y0: float, x1: float, y1: float
) -> void:
	_wall_seg(parent, Vector2(vp.x * x0, vp.y * y0), Vector2(vp.x * (x1 - x0), vp.y * (y1 - y0)))


func _wall_poly(parent: StaticBody2D, pts: PackedVector2Array) -> void:
	var poly := CollisionPolygon2D.new()
	poly.polygon = pts
	parent.add_child(poly)


func _wall_seg(parent: StaticBody2D, pos: Vector2, sz: Vector2) -> void:
	if sz.x <= 0.0 or sz.y <= 0.0:
		return
	var col  := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size    = sz
	col.position = pos + sz * 0.5
	col.shape    = rect
	parent.add_child(col)


func _build_player() -> void:
	var vp := get_viewport_rect().size
	var scr: GDScript = load("res://scripts/shop/player_shop.gd")
	_player          = scr.new() as CharacterBody2D
	_player.set("move_speed", PLAYER_MOVE_SPEED)
	_player.set("enable_footsteps", true)
	_player.position = Vector2(vp.x * 0.50, vp.y * 0.71)
	add_child(_player)


func _build_zones() -> void:
	_make_zone(ZONE_FORGE, forge_center, forge_size)
	_make_zone(ZONE_BED,   bed_center,   bed_size)
	_make_zone(ZONE_INVENTORY, inventory_center, inventory_size)
	_make_zone(ZONE_EXIT,  exit_center,  exit_size)
	_make_zone(ZONE_SHOP,  shop_center,  shop_size)
	_make_zone(ZONE_FORGE_BOOK, forge_book_center, forge_book_size)


func _make_zone(id: String, center: Vector2, sz: Vector2) -> void:
	var area := Area2D.new()
	area.name            = "Zone_" + id
	area.collision_layer = 0
	area.collision_mask  = 1   # detect player (layer 1)
	add_child(area)

	var col  := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size    = sz
	col.position = center
	col.shape    = rect
	area.add_child(col)

	area.body_entered.connect(_on_zone_entered.bind(id))
	area.body_exited.connect(_on_zone_exited.bind(id))


func _connect_signals() -> void:
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.day_changed.connect(_on_day_changed)
	EventBus.shop_closed.connect(_on_shop_closed_for_summary)
	EventBus.guide_book_opened.connect(_open_guide_book)
	EventBus.forge_book_opened.connect(_open_forge_recipe_book)


func _on_phase_changed(phase: GameManager.GamePhase) -> void:
	if _atmosphere != null:
		_atmosphere.set_phase(phase)
	_sync_debt_agent_scene()
	_sync_debt_payment()
	_tutorial_ctrl.sync_day1_scripted()


func _on_day_changed(_day: int) -> void:
	_tutorial_ctrl.handle_day_changed(_day)
	_sync_debt_agent_scene()
	_tutorial_ctrl.sync_day1_scripted()


func _on_zone_entered(body: Node2D, zone_id: String) -> void:
	if body != _player:
		return
	if not _overlapping_zones.has(zone_id):
		_overlapping_zones.append(zone_id)
	_refresh_near_zone()


func _on_zone_exited(body: Node2D, zone_id: String) -> void:
	if body != _player:
		return
	_overlapping_zones.erase(zone_id)
	_refresh_near_zone()


func _refresh_near_zone() -> void:
	var best_zone := ""
	var best_prio := -1
	var best_dist := INF
	for zone_id: String in _overlapping_zones:
		var prio := _zone_priority(zone_id)
		var dist := _player.position.distance_to(_zone_anchor_pos(zone_id))
		if prio > best_prio or (prio == best_prio and dist < best_dist):
			best_prio = prio
			best_dist = dist
			best_zone = zone_id
	if best_zone == _near_zone:
		return
	_near_zone = best_zone
	if _near_zone == "":
		_tutorial_ctrl.on_zone_exited()
		if _atmosphere != null:
			_atmosphere.hide_prompt()
	else:
		_tutorial_ctrl.on_zone_entered(_near_zone, _hint_text(_near_zone))
		AudioManager.play_sfx_key("zone_prompt", 0.32)
		if _atmosphere != null:
			_atmosphere.show_prompt(_zone_prompt_pos(_near_zone), _zone_short_title(_near_zone))


func _zone_priority(zone_id: String) -> int:
	if zone_id in [
		ZONE_VISITOR_CLG, ZONE_DEBT_AGENT, ZONE_DEBT_AGENT_C2,
		ZONE_DEBT_AGENT_C3, ZONE_DEBT_AGENT_C4,
	]:
		return 3
	if zone_id in [ZONE_FORGE, ZONE_FORGE_BOOK, ZONE_INVENTORY, ZONE_BED]:
		return 2
	return 1


func _zone_anchor_pos(zone_id: String) -> Vector2:
	match zone_id:
		ZONE_FORGE: return forge_center
		ZONE_BED: return bed_center
		ZONE_INVENTORY: return inventory_center
		ZONE_EXIT: return exit_center
		ZONE_SHOP: return shop_center
		ZONE_FORGE_BOOK: return forge_book_center
		ZONE_VISITOR_CLG:
			return _visitor_clg.position if _visitor_clg != null else Vector2.ZERO
		_:
			if _debt_agents.has(zone_id) and _debt_agents[zone_id] != null:
				return (_debt_agents[zone_id] as Node2D).position
	return Vector2.ZERO


func _zone_prompt_pos(zone_id: String) -> Vector2:
	var vp := get_viewport_rect().size
	match zone_id:
		ZONE_FORGE: return Vector2(vp.x * 0.34, vp.y * 0.42)
		ZONE_FORGE_BOOK: return Vector2(vp.x * 0.58, vp.y * 0.25)
		ZONE_BED: return Vector2(vp.x * 0.76, vp.y * 0.34)
		ZONE_INVENTORY: return Vector2(vp.x * 0.78, vp.y * 0.51)
		ZONE_EXIT: return Vector2(vp.x * 0.165, vp.y * 0.56)
		ZONE_SHOP: return Vector2(vp.x * 0.855, vp.y * 0.57)
		ZONE_VISITOR_CLG:
			if _visitor_clg != null:
				return _visitor_clg.position + Vector2(0.0, -96.0)
		_:
			if _debt_agents.has(zone_id) and _debt_agents[zone_id] != null:
				return (_debt_agents[zone_id] as Node2D).position + Vector2(0.0, -104.0)
	return _zone_anchor_pos(zone_id) + Vector2(0.0, -64.0)


func _zone_short_title(zone_id: String) -> String:
	var titles := {
		ZONE_FORGE: "Lò Rèn",
		ZONE_BED: "Nghỉ Ngơi",
		ZONE_INVENTORY: "Rương Kho Đồ",
		ZONE_EXIT: "Khám Phá",
		ZONE_SHOP: "Mở Tiệm",
		ZONE_FORGE_BOOK: "Bí Kíp Rèn",
		ZONE_DEBT_AGENT: "Người Thu Nợ",
		ZONE_DEBT_AGENT_C2: "Tay Sai Rừng",
		ZONE_DEBT_AGENT_C3: "Thương Nhân",
		ZONE_DEBT_AGENT_C4: "Bà Trùm Hắc Nguyệt",
		ZONE_VISITOR_CLG: "Cô Lộng Gió",
	}
	return String(titles.get(zone_id, _hint_text(zone_id)))


func _hint_text(zone_id: String) -> String:
	var hints := {
		ZONE_FORGE: "Vào lò rèn",
		ZONE_BED: "Nghỉ ngơi — kết thúc ngày",
		ZONE_INVENTORY: "Mở Rương Kho Đồ",
		ZONE_EXIT: "Đi khám phá vùng đất",
		ZONE_SHOP: "Mở cửa tiệm",
		ZONE_FORGE_BOOK: "Mở Bí Kíp Rèn",
		ZONE_DEBT_AGENT: "Nói chuyện với Người Thu Nợ",
		ZONE_DEBT_AGENT_C2: "Nói chuyện với Tay Sai Rừng",
		ZONE_DEBT_AGENT_C3: "Nói chuyện với Thương Nhân Sa Mạc",
		ZONE_DEBT_AGENT_C4: "Nói chuyện với Bà Trùm Hắc Nguyệt",
		ZONE_VISITOR_CLG: "Trò chuyện với Cô Lộng Gió",
	}
	return String(hints.get(zone_id, ""))


func _activate_zone(zone_id: String) -> void:
	if not _tutorial_ctrl.can_activate_zone(zone_id):
		return
	match zone_id:
		ZONE_FORGE: _go_forge()
		ZONE_BED:   _go_sleep()
		ZONE_INVENTORY: _open_inventory()
		ZONE_EXIT:  _go_explore()
		ZONE_SHOP:  _go_shop()
		ZONE_FORGE_BOOK: EventBus.forge_book_opened.emit()
		ZONE_DEBT_AGENT: _debt_ctrl.talk_to_debt_agent()
		ZONE_DEBT_AGENT_C2: _debt_ctrl.talk_to_c2_agent()
		ZONE_DEBT_AGENT_C3: _debt_ctrl.talk_to_c3_agent()
		ZONE_DEBT_AGENT_C4: _debt_ctrl.talk_to_c4_agent()
		ZONE_VISITOR_CLG: _talk_to_hub_visitor_clg()


func _build_hub_visitors() -> void:
	if GameManager.current_day < 3:
		return
	var met: bool = GameManager.has_tutorial_seen("co_long_gio_met")
	var hub_met: bool = GameManager.has_tutorial_seen("co_long_gio_hub_met")
	if met and hub_met:
		return
	if _visitor_clg != null:
		return
	var vp := get_viewport_rect().size
	var npc := Node2D.new()
	npc.name = "CoLongGioHub"
	npc.position = Vector2(vp.x * 0.285, vp.y * 0.68)
	add_child(npc)
	_visitor_clg = npc

	var clg_sprite := _build_npc_animated_sprite(CO_LONG_GIO_SHEET_PATH)
	if clg_sprite != null:
		npc.add_child(clg_sprite)
	else:
		var visual := ColorRect.new()
		visual.size = Vector2(38, 54)
		visual.position = Vector2(-19, -27)
		visual.color = Color(0.62, 0.82, 0.92)
		npc.add_child(visual)

	var name_lbl := Label.new()
	name_lbl.text = "Cô Lộng Gió"
	name_lbl.position = Vector2(-78, -90)
	name_lbl.size = Vector2(156, 28)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(0.80, 0.94, 1.0))
	name_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.04, 0.92))
	name_lbl.add_theme_constant_override("outline_size", 4)
	npc.add_child(name_lbl)

	var body_col := CollisionShape2D.new()
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(38, 54)
	body_col.shape = body_shape

	var static_body := StaticBody2D.new()
	static_body.collision_layer = 2
	static_body.collision_mask = 0
	static_body.add_child(body_col)
	npc.add_child(static_body)

	var talk_area := Area2D.new()
	talk_area.collision_layer = 0
	talk_area.collision_mask = 1
	talk_area.monitoring = true
	npc.add_child(talk_area)

	var talk_col := CollisionShape2D.new()
	var talk_shape := CircleShape2D.new()
	talk_shape.radius = float(TILE) * 1.5
	talk_col.shape = talk_shape
	talk_area.add_child(talk_col)

	talk_area.body_entered.connect(_on_zone_entered.bind(ZONE_VISITOR_CLG))
	talk_area.body_exited.connect(_on_zone_exited.bind(ZONE_VISITOR_CLG))


func _build_npc_animated_sprite(sheet_path: String) -> AnimatedSprite2D:
	var texture := load(sheet_path) as Texture2D
	if texture == null:
		return null
	var sprite := AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 6.0)
	frames.set_animation_loop("idle", true)
	for col in 4:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(col * NPC_FRAME_SIZE, 0, NPC_FRAME_SIZE, NPC_FRAME_SIZE)
		frames.add_frame("idle", atlas)
	sprite.sprite_frames = frames
	sprite.offset = Vector2(0.0, -16.0)
	sprite.scale = Vector2(NPC_RENDER_SCALE, NPC_RENDER_SCALE)
	sprite.play("idle")
	return sprite


func _talk_to_hub_visitor_clg() -> void:
	if _visitor_clg == null:
		return
	var met: bool = GameManager.has_tutorial_seen("co_long_gio_met")
	if not met:
		_tutorial_ctrl.show_tutorial_then(
			GuideBook.get_co_long_gio_first_dialogue(),
			"co_long_gio_hub_met",
			func() -> void:
				GameManager.mark_tutorial_seen("co_long_gio_met")
				_visitor_clg.queue_free()
				_visitor_clg = null
				_overlapping_zones.erase(ZONE_VISITOR_CLG)
				_refresh_near_zone()
		)
	else:
		_tutorial_ctrl.show_tutorial_then(
			GuideBook.get_co_long_gio_second_dialogue(),
			"co_long_gio_hub_met",
			func() -> void:
				_visitor_clg.queue_free()
				_visitor_clg = null
				_overlapping_zones.erase(ZONE_VISITOR_CLG)
				_refresh_near_zone()
		)


func _go_forge() -> void:
	if _tutorial_ctrl.should_show_before_forge():
		_tutorial_ctrl.show_tutorial_then(
			GuideBook.get_day0_forge_steps(),
			"day0_forge_phase_seen",
			_go_forge
		)
		return
	if GameManager.current_phase == GameManager.GamePhase.MORNING:
		_advance_phase_from(GameManager.GamePhase.MORNING)
	SceneManager.go_to(PATH_FORGE)


func _go_shop() -> void:
	if _tutorial_ctrl.is_day1_active() and _tutorial_ctrl.tutorial_step < 3:
		_tutorial_ctrl.request_hint("Chiều mới mở cửa bán hàng.")
		return
	if _debt_ctrl.should_show_c1_debt_agent():
		_debt_ctrl.show_c1_debt_notice()
		return
	if _tutorial_ctrl.should_show_before_shop():
		_tutorial_ctrl.show_tutorial_then(
			GuideBook.get_day0_shop_phase_steps(),
			"day0_shop_phase_seen",
			_go_shop
		)
		return
	if GameManager.current_day <= 1 and InventorySystem.get_weapons().is_empty():
		_tutorial_ctrl.request_hint("Hãy bày vũ khí lên kệ trước khi mở cửa tiệm!")
		return
	# Đảm bảo mở shop luôn bước vào buổi chiều, kể cả khi bỏ qua rèn.
	if GameManager.current_phase == GameManager.GamePhase.MORNING:
		DayCycle.advance_phase()
	if GameManager.current_phase == GameManager.GamePhase.NOON:
		DayCycle.advance_phase()
	AudioManager.play_sfx_key("door_wood", 0.75)
	SceneManager.go_to(PATH_SHOP)


func _go_explore() -> void:
	if GameManager.travel_stamina <= 0:
		_tutorial_ctrl.request_hint("Hết thể lực — hãy nghỉ ngơi trước!")
		return
	if _tutorial_ctrl.should_show_before_explore():
		_tutorial_ctrl.show_tutorial_then(
			GuideBook.get_explore_steps(),
			"explore_phase_seen",
			_go_explore
		)
		return
	AudioManager.play_sfx_key("door_wood", 0.70)
	_open_region_select()


func _go_sleep() -> void:
	if GameManager.current_phase != GameManager.GamePhase.NIGHT:
		if GameManager.current_day < 2:
			_tutorial_ctrl.request_hint("Chưa đến giờ nghỉ — hãy hoàn thành công việc trong ngày!")
			return
		_force_advance_to_night()
	if GameManager.current_day == 0 and not GameManager.has_tutorial_seen("explore_phase_seen"):
		_tutorial_ctrl.show_tutorial_then(
			GuideBook.get_explore_steps(),
			"explore_phase_seen",
			_go_sleep
		)
		return
	_open_day_summary()


func _force_advance_to_night() -> void:
	DayCycle.force_to_night()


func _on_shop_closed_for_summary(stats: Dictionary) -> void:
	GameManager.pending_day_summary_stats = {}
	_open_day_summary(stats)
	_sync_debt_payment()


func _advance_phase_from(expected_phase: GameManager.GamePhase) -> void:
	if GameManager.current_phase != expected_phase:
		push_warning("Không advance phase: current_phase không khớp flow mong đợi")
		return
	DayCycle.advance_phase()


func _open_region_select() -> void:
	if _region_select == null:
		var scr: GDScript = load("res://scripts/ui/region_select_ui.gd")
		_region_select = scr.new() as CanvasLayer
		(_region_select as RegionSelectUI).region_chosen.connect(_on_region_chosen)
		add_child(_region_select)
	_region_select.visible = true


func _on_region_chosen(region_id: String) -> void:
	_open_combat_loadout(region_id)


func _open_combat_loadout(region_id: String) -> void:
	if _combat_loadout == null:
		var scr: GDScript = load("res://scripts/ui/combat_loadout_ui.gd")
		_combat_loadout = scr.new() as CombatLoadoutUI
		_combat_loadout.loadout_confirmed.connect(_on_loadout_confirmed)
		add_child(_combat_loadout)
	_combat_loadout.show_loadout(region_id)


func _on_loadout_confirmed(region_id: String, weapons: Array) -> void:
	_set_combat_loadout(weapons)
	GameManager.current_region_id = region_id
	SceneManager.go_to("res://scenes/regions/ExplorationScene.tscn")


func _set_combat_loadout(weapons: Array) -> void:
	GameManager.equipped_weapons.clear()
	for i in GameManager.COMBAT_WEAPON_SLOTS:
		if i < weapons.size() and weapons[i] is Dictionary:
			GameManager.equipped_weapons.append(weapons[i])
		else:
			GameManager.equipped_weapons.append({})


func _ensure_tutorial_controller() -> void:
	if _tutorial_ctrl != null:
		return
	_ensure_debt_controller()
	var script: GDScript = load(WORKSHOP_TUTORIAL_CONTROLLER_SCRIPT)
	_tutorial_ctrl = script.new() as WorkshopTutorialController
	_tutorial_ctrl.hub = self
	_tutorial_ctrl.layout = _get_tutorial_layout()
	_tutorial_ctrl.advance_phase_requested.connect(_on_tutorial_advance_phase_requested)
	_tutorial_ctrl.debt_agent_sync_requested.connect(_sync_debt_agent_scene)
	_tutorial_ctrl.debt_notice_requested.connect(_debt_ctrl.open_debt_notice)
	add_child(_tutorial_ctrl)


func _ensure_debt_controller() -> void:
	if _debt_ctrl != null:
		return
	var script: GDScript = load(WORKSHOP_DEBT_CONTROLLER_SCRIPT)
	_debt_ctrl = script.new() as WorkshopDebtController
	_debt_ctrl.setup(self)
	_debt_ctrl.setup_layout(TILE, cols, shop_center)
	_debt_ctrl.debt_agent_spawn_requested.connect(_on_debt_agent_spawn_requested)
	_debt_ctrl.debt_agent_cleared.connect(_on_debt_agent_cleared)
	add_child(_debt_ctrl)


func _get_tutorial_layout() -> Dictionary:
	return {
		"TILE": TILE,
		"forge_center": forge_center,
		"bed_center": bed_center,
		"exit_center": exit_center,
		"shop_center": shop_center,
		"forge_book_center": forge_book_center,
	}


func _on_tutorial_advance_phase_requested() -> void:
	DayCycle.advance_phase()


func _open_day_summary(stats: Dictionary = {}) -> void:
	if _day_summary == null:
		var scr: GDScript = load("res://scripts/ui/day_summary_ui.gd")
		_day_summary = scr.new() as CanvasLayer
		add_child(_day_summary)
	(_day_summary as DaySummaryUI).show_summary(stats)


func _open_forge_recipe_book() -> void:
	if _forge_recipe_book_ui == null:
		var scr: GDScript = load(FORGE_RECIPE_BOOK_SCRIPT)
		_forge_recipe_book_ui = scr.new() as ForgeRecipeBookUI
		add_child(_forge_recipe_book_ui)
	AudioManager.play_sfx_key("book_flip", 0.72)
	_forge_recipe_book_ui.show_book()


func _ensure_game_over_ui() -> void:
	if _game_over_ui == null:
		_game_over_ui = load(PATH_GAME_OVER).instantiate()
		add_child(_game_over_ui)


func _show_day_start_card_if_needed() -> bool:
	if GameManager.current_day <= 0:
		return false
	if GameManager.current_phase != GameManager.GamePhase.MORNING:
		return false

	var flag := DAY_CARD_FLAG_PREFIX + str(GameManager.current_day)
	if GameManager.has_tutorial_seen(flag):
		return false

	GameManager.mark_tutorial_seen(flag)
	_show_day_start_card()
	return true


func _show_day_start_card() -> void:
	var script: GDScript = load(DAY_SCENE_CARD_SCRIPT)
	_day_card_overlay = script.new() as DaySceneCardUI
	_day_card_overlay.closed.connect(_on_day_start_card_closed, CONNECT_ONE_SHOT)
	add_child(_day_card_overlay)
	_day_card_overlay.show_day(GameManager.current_day)


func _on_day_start_card_closed() -> void:
	if _day_card_overlay == null:
		return
	_day_card_overlay = null
	_sync_debt_overlays()
	_tutorial_ctrl.sync_script()


func _open_guide_book() -> void:
	_tutorial_ctrl.open_guide_book()


func _open_inventory() -> void:
	if GameManager.current_phase == GameManager.GamePhase.NIGHT:
		_tutorial_ctrl.request_hint("Không mở kho lúc nghỉ đêm.")
		return
	if _inventory_ui == null:
		var scene := load(PATH_INVENTORY) as PackedScene
		_inventory_ui = scene.instantiate() as InventoryUI
		add_child(_inventory_ui)
	AudioManager.play_sfx_key("chest_open", 0.72)
	_inventory_ui.show_inventory()


func _has_blocking_overlay() -> bool:
	if _day_card_overlay != null:
		return true
	if _forge_recipe_book_ui != null and _forge_recipe_book_ui.visible:
		return true
	if _inventory_ui != null and _inventory_ui.visible:
		return true
	if _region_select != null and _region_select.visible:
		return true
	if _combat_loadout != null and _combat_loadout.visible:
		return true
	if _day_summary != null and _day_summary.visible:
		return true
	if _pause_menu != null and _pause_menu.visible:
		return true
	if _tutorial_ctrl != null and _tutorial_ctrl.is_overlay_active():
		return true
	if _debt_ctrl != null and _debt_ctrl.has_visible_overlay():
		return true
	return false


func _sync_debt_overlays() -> void:
	_debt_ctrl.sync_overlays()


func _sync_debt_payment() -> void:
	_debt_ctrl.sync_payment()


func _sync_debt_agent_scene() -> void:
	_debt_ctrl.sync_agent_scene()


func _on_debt_agent_spawn_requested(
		zone_id: String,
		node_name: String,
		display_name: String,
		pos: Vector2
) -> void:
	if _debt_agents.has(zone_id):
		return
	var agent: DebtAgentNode = DebtAgentNode.new()
	agent.name = node_name
	agent.display_name = display_name
	agent.position = pos
	agent.player_entered.connect(_on_debt_agent_entered.bind(zone_id))
	agent.player_exited.connect(_on_debt_agent_exited.bind(zone_id))
	add_child(agent)
	_debt_agents[zone_id] = agent


func _on_debt_agent_cleared(zone_id: String) -> void:
	if not _debt_agents.has(zone_id):
		return
	_overlapping_zones.erase(zone_id)
	var agent := _debt_agents[zone_id] as Node2D
	if agent != null:
		agent.queue_free()
	_debt_agents.erase(zone_id)
	_refresh_near_zone()


func _on_debt_agent_entered(zone_id: String) -> void:
	if not _overlapping_zones.has(zone_id):
		_overlapping_zones.append(zone_id)
	_refresh_near_zone()


func _on_debt_agent_exited(zone_id: String) -> void:
	_overlapping_zones.erase(zone_id)
	_refresh_near_zone()


func _open_pause_menu() -> void:
	if _pause_menu == null:
		var scene := load(PATH_PAUSE_MENU) as PackedScene
		_pause_menu = scene.instantiate()
		add_child(_pause_menu)
	(_pause_menu as PauseMenuUI).open()


func _debug_reset_game() -> void:
	# Reset nhanh để test debt flow trong editor/dev build.
	SaveSystem.delete_save()
	GameManager.init_new_game()
	_debt_ctrl.reset_day_check()
	_sync_debt_overlays()
