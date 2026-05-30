# gdlint: disable=max-file-lines
# scripts/regions/exploration_scene.gd
# Khám phá vùng đất: map procedural, chạm kẻ địch → combat.
extends Node2D

const TILE  := 64
const COLS  := 72
const ROWS  := 40
const PATH_WORKSHOP := "res://scenes/main/WorkshopHub.tscn"
const PATH_COMBAT   := "res://scenes/combat/CombatScene.tscn"
const PATH_EXPLORATION := "res://scenes/regions/ExplorationScene.tscn"
const PATH_PAUSE_MENU := "res://scenes/ui/PauseMenu.tscn"
const PATH_TUTORIAL_OVERLAY_SCRIPT := "res://scripts/ui/tutorial_overlay_ui.gd"
const PATH_TEMP_EXPLORATION_BG := "res://assets/reference/exploration_scale_reference.png"
const FLAG_CO_LONG_GIO_MET := "co_long_gio_met"
const FLAG_CO_LONG_GIO_SECOND := "co_long_gio_second_met"
const FLAG_MOVE_HINT_SEEN := "move_hint_seen"
const SPEED_PATROL := 55.0
const SPEED_CHASE  := 110.0
const ENEMY_SPAWN_RETRIES := 30
const USE_TEMP_EXPLORATION_BG := true

const MINI_W: int = 200
const MINI_H: int = 112

# Config cho từng loại sub-scene
const SUB_SCENE_CONFIG: Dictionary = {
	"STORY_1": {
		"label": "Dân Cư",
		"tint": Color(0.55, 0.68, 0.88, 0.20),
		"enemy_count": 3,
		"tier_filter": [1],
		"respawn": false,
		"is_loop": false,
		"gather_count": 2,
	},
	"LOOP_A": {
		"label": "Hoang Dã",
		"tint": Color(0.45, 0.72, 0.35, 0.18),
		"enemy_count": 5,
		"tier_filter": [1],
		"respawn": true,
		"is_loop": true,
		"gather_count": 3,
	},
	"LOOP_B": {
		"label": "Biên Giới",
		"tint": Color(0.78, 0.68, 0.38, 0.20),
		"enemy_count": 4,
		"tier_filter": [1, 2],
		"respawn": true,
		"is_loop": true,
		"gather_count": 3,
	},
	"STORY_2": {
		"label": "Linh Thiêng",
		"tint": Color(0.62, 0.52, 0.82, 0.28),
		"enemy_count": 0,
		"tier_filter": [],
		"respawn": false,
		"is_loop": false,
		"gather_count": 1,
	},
	"LOOP_C": {
		"label": "Sâu Thẳm",
		"tint": Color(0.50, 0.22, 0.14, 0.30),
		"enemy_count": 6,
		"tier_filter": [2, 3],
		"respawn": true,
		"is_loop": true,
		"gather_count": 3,
	},
	"LANDMARK": {
		"label": "Di Tích",
		"tint": Color(0.82, 0.72, 0.22, 0.32),
		"enemy_count": 1,
		"tier_filter": [3, 4],
		"respawn": false,
		"is_loop": false,
		"gather_count": 0,
	},
}

const REGION_META: Dictionary = {
	"DongMay": {
		"name": "Đồng Mây Trắng", "floor": Color(0.55, 0.52, 0.35),
		"wall": Color(0.28, 0.18, 0.08), "obs": Color(0.42, 0.35, 0.22),
		"grass": Color(0.45, 0.62, 0.28, 0.42),
	},
	"RungTramHon": {
		"name": "Rừng Trăm Hồn", "floor": Color(0.18, 0.33, 0.16),
		"wall": Color(0.10, 0.20, 0.08), "obs": Color(0.14, 0.28, 0.12),
		"grass": Color(0.18, 0.52, 0.22, 0.42),
	},
	"NuiThanDo": {
		"name": "Núi Than Đỏ", "floor": Color(0.30, 0.20, 0.16),
		"wall": Color(0.16, 0.10, 0.08), "obs": Color(0.45, 0.22, 0.14),
		"grass": Color(0.72, 0.28, 0.12, 0.42),
	},
	"BaiCat": {
		"name": "Bãi Cát Thần Vàng", "floor": Color(0.75, 0.68, 0.45),
		"wall": Color(0.55, 0.42, 0.22), "obs": Color(0.65, 0.52, 0.28),
		"grass": Color(0.88, 0.72, 0.22, 0.42),
	},
	"ThanhNgoc": {
		"name": "Thành Ngọc Bích", "floor": Color(0.38, 0.52, 0.60),
		"wall": Color(0.20, 0.30, 0.42), "obs": Color(0.28, 0.45, 0.55),
		"grass": Color(0.28, 0.62, 0.80, 0.42),
	},
	"LangTo": {
		"name": "Làng Tổ Nghề", "floor": Color(0.46, 0.40, 0.33),
		"wall": Color(0.26, 0.20, 0.16), "obs": Color(0.38, 0.28, 0.22),
		"grass": Color(0.52, 0.62, 0.28, 0.42),
	},
}

# ── State ──────────────────────────────────────────────────────────────────────
var _region_id:    String
var _scene_idx: int = 0
var _scene_type: String = "STORY_1"
var _scene_cfg: Dictionary = {}
var _scene_visited_key: String = ""
var _scene_already_visited: bool = false
var _region_was_cleared_on_entry: bool = false
var _player:       CharacterBody2D
var _near_exit:    bool       = false
var _near_exit_right: bool = false
var _near_co_long_gio: bool = false
var _is_leaving_region: bool = false
var _enemy_nodes:  Array[CharacterBody2D] = []
var _enemy_states: Dictionary = {}
var _pending_meta: Dictionary = {}
var _obstacle_rects: Array[Rect2] = []
var _near_gather_idx: int = -1
var _gather_nodes: Array[Node2D] = []

# HUD
var _hint_lbl:    Label
var _quest_lbl:   Label = null
var _move_hint_lbl: Label = null
var _lbl_stamina: Label
var _lbl_bag:     Label
var _bag_overlay: Control
var _bag_items_box: VBoxContainer
var _pause_menu: Node = null
var _tutorial_overlay: TutorialOverlayUI = null

# Mini map
var _mini_map_container:  Control    = null
var _mini_map_player_dot: ColorRect  = null
var _mini_map_enemy_dots: Dictionary = {}  # enemy_idx: int → ColorRect
var _mini_map_npc_icons:  Dictionary = {}  # npc_id: String → Dictionary


# ══════════════════════════════════════════════════════════════════════════════
# READY
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_region_id = GameManager.current_region_id
	if _region_id.is_empty():
		_region_id = "DongMay"
	_scene_idx = clampi(
		GameManager.current_sub_scene_idx,
		0,
		GameManager.SUB_SCENE_ORDER.size() - 1
	)
	_scene_type = GameManager.SUB_SCENE_ORDER[_scene_idx]
	_scene_cfg = SUB_SCENE_CONFIG.get(_scene_type, SUB_SCENE_CONFIG["LOOP_A"])
	_scene_visited_key = "%s_%d" % [_region_id, _scene_idx]
	GameManager.current_sub_scene_idx = _scene_idx
	GameManager.current_sub_scene_type = _scene_type
	_region_was_cleared_on_entry = GameManager.is_region_cleared(_region_id)
	if _scene_type == "LANDMARK" and not _region_was_cleared_on_entry:
		GameManager.mark_region_cleared(_region_id)

	var meta: Dictionary = REGION_META.get(_region_id, REGION_META["DongMay"])

	_setup_exploration_state()
	_scene_already_visited = GameManager.exploration_state.get(
		"visited_" + _scene_visited_key,
		false
	)
	# Trừ thể lực khi vào vùng mới; restore từ combat không trừ lần hai.
	var entry_paid: bool = GameManager.exploration_state.get("entry_paid", false)
	var is_new_region_entry: bool = (_scene_idx == 0) and not entry_paid
	if is_new_region_entry:
		GameManager.consume_entry_stamina(_region_id)
		GameManager.exploration_state["entry_paid"] = true
	_build_map(meta)
	_build_player()
	_pending_meta = meta
	call_deferred("_build_enemies", _pending_meta)
	_build_exit_zone()
	_build_hud(meta)
	_build_special_npcs()
	_build_gather_nodes()
	if not GameManager.has_tutorial_seen(FLAG_MOVE_HINT_SEEN):
		_move_hint_lbl.visible = true
		_move_hint_lbl.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_property(_move_hint_lbl, "modulate:a", 0.0, 1.5).set_delay(4.0)
		tween.finished.connect(func() -> void: _move_hint_lbl.visible = false)
		GameManager.mark_tutorial_seen(FLAG_MOVE_HINT_SEEN)
	else:
		_move_hint_lbl.visible = false
	_refresh_hud()
	_consume_pending_loot()

	GameManager.travel_stamina_changed.connect(func(_c: int, _m: int) -> void: _refresh_hud())
	EventBus.quest_started.connect(func(_quest_id: String) -> void: _refresh_hud())
	EventBus.quest_completed.connect(func(_quest_id: String) -> void: _refresh_hud())
	EventBus.quest_updated.connect(_refresh_hud)
	EventBus.region_entered.emit(_region_id)


# ══════════════════════════════════════════════════════════════════════════════
# PROCESS — enemy AI
# ══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	for entry in _enemy_states.values():
		if entry.get("defeated", false):
			continue
		_update_enemy(entry, delta)
	_update_mini_map()
	_clamp_player_in_bounds()


# ══════════════════════════════════════════════════════════════════════════════
# INPUT
# ══════════════════════════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey): return
	var key := event as InputEventKey
	if not key.pressed or key.echo: return
	match key.keycode:
		KEY_B:
			_toggle_bag_overlay()
		KEY_E:
			if _near_exit:
				_leave_region()
			elif _near_co_long_gio:
				_open_co_long_gio_dialogue()
			elif _near_gather_idx >= 0:
				_collect_gather(_near_gather_idx)
			elif _near_exit_right:
				_advance_sub_scene()
		KEY_ESCAPE:
			if _bag_overlay != null and _bag_overlay.visible:
				_bag_overlay.visible = false
			else:
				_open_pause_menu()


# ══════════════════════════════════════════════════════════════════════════════
# MAP
# ══════════════════════════════════════════════════════════════════════════════

func _build_map(meta: Dictionary) -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size     = Vector2(TILE * COLS, TILE * ROWS)
	bg.color    = meta["wall"]
	add_child(bg)

	var floor_bg := ColorRect.new()
	floor_bg.position = Vector2(TILE, TILE)
	floor_bg.size     = Vector2(TILE * (COLS - 2), TILE * (ROWS - 2))
	floor_bg.color    = meta["floor"]
	add_child(floor_bg)

	if USE_TEMP_EXPLORATION_BG:
		_build_temp_exploration_background()

	# Vân nền xen kẽ
	var floor_alt := Color(meta["floor"].r * 0.91, meta["floor"].g * 0.91, meta["floor"].b * 0.91)
	for r in range(1, ROWS - 1):
		if r % 2 == 0: continue
		var stripe := ColorRect.new()
		stripe.position = Vector2(TILE, r * TILE)
		stripe.size     = Vector2(TILE * (COLS - 2), TILE)
		stripe.color    = floor_alt
		if USE_TEMP_EXPLORATION_BG:
			stripe.color = Color(floor_alt.r, floor_alt.g, floor_alt.b, 0.08)
		add_child(stripe)

	_build_wall_col()
	_build_obstacles(meta)


func _build_temp_exploration_background() -> void:
	var texture := load(PATH_TEMP_EXPLORATION_BG) as Texture2D
	if texture == null:
		push_warning("Không load được background tạm exploration: %s" % PATH_TEMP_EXPLORATION_BG)
		return

	var sprite := Sprite2D.new()
	sprite.name = "TempExplorationBackground"
	sprite.texture = texture
	sprite.centered = true
	sprite.position = Vector2(TILE * COLS, TILE * ROWS) * 0.5

	var map_size := Vector2(TILE * COLS, TILE * ROWS)
	var texture_size := texture.get_size()
	var scale_factor := maxf(map_size.x / texture_size.x, map_size.y / texture_size.y)
	sprite.scale = Vector2.ONE * scale_factor
	add_child(sprite)

	var tint := ColorRect.new()
	tint.color = _scene_cfg.get("tint", Color(0, 0, 0, 0))
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.size = Vector2(TILE * COLS, TILE * ROWS)
	tint.position = Vector2.ZERO
	add_child(tint)


func _build_wall_col() -> void:
	var sb := StaticBody2D.new()
	sb.collision_layer = 4
	sb.collision_mask  = 0
	add_child(sb)

	var fw := float(TILE * COLS)
	var fh := float(TILE * ROWS)
	var rw := float(TILE)

	_wall_seg(sb, Vector2(0, 0),         Vector2(fw, rw))
	_wall_seg(sb, Vector2(0, fh - rw),   Vector2(fw, rw))
	_wall_seg(sb, Vector2(0, rw),        Vector2(rw, fh - rw * 2))
	_wall_seg(sb, Vector2(fw - rw, rw),  Vector2(rw, fh - rw * 2))


func _wall_seg(parent: StaticBody2D, pos: Vector2, sz: Vector2) -> void:
	var col  := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size    = sz
	col.position = pos + sz * 0.5
	col.shape    = rect
	parent.add_child(col)


func _build_obstacles(meta: Dictionary) -> void:
	_obstacle_rects.clear()
	var occupied: Dictionary = {}
	var cx := COLS / 2
	var cy := ROWS / 2

	# Vùng an toàn: giữa map (player spawn), cạnh trái (exit), border
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			occupied[Vector2i(cx + dx, cy + dy)] = true
	if _region_id == "DongMay":
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				occupied[Vector2i(COLS - 6 + dx, 4 + dy)] = true
	for r in ROWS:
		for c in [0, 1, COLS - 2, COLS - 1]:
			occupied[Vector2i(c, r)] = true
	for c in COLS:
		for r in [0, ROWS - 1]:
			occupied[Vector2i(c, r)] = true

	var sb := StaticBody2D.new()
	sb.collision_layer = 4
	sb.collision_mask  = 0
	add_child(sb)

	var obs_c: Color = meta["obs"]
	var placed := 0
	var tries  := 0
	while placed < 20 and tries < 300:
		tries += 1
		var col := randi_range(2, COLS - 3)
		var row := randi_range(2, ROWS - 3)
		var w   := randi_range(1, 2)
		var h   := randi_range(1, 2)

		var ok := true
		for dc in (w + 1):
			for dr in (h + 1):
				if occupied.has(Vector2i(col + dc, row + dr)):
					ok = false; break
			if not ok: break
		if not ok: continue

		for dc in (w + 2):
			for dr in (h + 2):
				occupied[Vector2i(col + dc - 1, row + dr - 1)] = true

		var visual := ColorRect.new()
		visual.position = Vector2(col * TILE, row * TILE)
		visual.size     = Vector2(w * TILE,   h * TILE)
		visual.color    = obs_c
		add_child(visual)
		_obstacle_rects.append(Rect2(visual.position, visual.size))
		_wall_seg(sb, Vector2(col * TILE, row * TILE), Vector2(w * TILE, h * TILE))
		placed += 1


# ══════════════════════════════════════════════════════════════════════════════
# PLAYER
# ══════════════════════════════════════════════════════════════════════════════

func _build_player() -> void:
	var scr: GDScript = load("res://scripts/shop/player_shop.gd")
	_player          = scr.new() as CharacterBody2D
	_player.position = _get_restore_player_position()
	add_child(_player)
	_player.scale = Vector2(5.0, 5.0)
	_add_player_camera()


func _add_player_camera() -> void:
	var camera := Camera2D.new()
	# Giới hạn bản đồ — tính theo world space.
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = TILE * COLS
	camera.limit_bottom = TILE * ROWS
	# Zoom vừa đủ để nhìn rõ player và vùng xung quanh.
	camera.zoom = Vector2(1.5, 1.5)
	# Camera follow player, vị trí (0,0) relative to player.
	camera.position = Vector2.ZERO
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	# Gắn vào player để Godot tự follow parent.
	_player.add_child(camera)
	camera.make_current()


# ══════════════════════════════════════════════════════════════════════════════
# ENEMIES
# ══════════════════════════════════════════════════════════════════════════════

func _build_enemies(_meta: Dictionary) -> void:
	var spawn_count: int = _scene_cfg.get("enemy_count", 0)
	if spawn_count == 0:
		return
	if _scene_type == "LANDMARK" and _region_was_cleared_on_entry:
		return
	if _scene_already_visited and not _scene_cfg.get("respawn", false):
		return
	GameManager.exploration_state["visited_" + _scene_visited_key] = true

	var all_enemies: Array[EnemyData] = EnemyDatabase.get_enemies_by_region(_region_id)
	if all_enemies.is_empty():
		return

	var tier_filter: Array = _scene_cfg.get("tier_filter", [])
	var pool: Array[EnemyData] = []
	for ed in all_enemies:
		if tier_filter.is_empty() or ed.tier in tier_filter:
			pool.append(ed)
	if pool.is_empty() and tier_filter.has(4):
		for ed in all_enemies:
			if ed.tier == 3:
				pool.append(ed)
	# Fallback: nếu không có enemy nào đúng tier, dùng toàn bộ list.
	if pool.is_empty():
		pool = all_enemies

	if _scene_cfg.get("is_loop", false):
		GameManager.exploration_state["enemy_spawn_seed"] = int(Time.get_ticks_usec())

	var enemy_rng := RandomNumberGenerator.new()
	enemy_rng.seed = int(GameManager.exploration_state.get("enemy_spawn_seed", Time.get_ticks_usec()))
	var spots: Array = _rand_enemy_positions(spawn_count, enemy_rng)
	for i in spots.size():
		var enemy_data: EnemyData = pool[i % pool.size()]
		var grid_pos: Vector2i = spots[i]
		var world_pos := Vector2(
			grid_pos.x * TILE + TILE * 0.5,
			grid_pos.y * TILE + TILE * 0.5
		)
		_spawn_enemy(i, enemy_data, world_pos, enemy_rng)


func _spawn_enemy(
		idx: int,
		enemy_data: EnemyData,
		pos: Vector2,
		enemy_rng: RandomNumberGenerator
) -> void:
	var enemy := CharacterBody2D.new()
	enemy.position = pos
	enemy.collision_layer = 2
	enemy.collision_mask = 5
	add_child(enemy)

	var visual := ColorRect.new()
	visual.size = Vector2(200, 200)
	visual.position = Vector2(-100, -100)
	visual.color = enemy_data.color
	enemy.add_child(visual)

	var name_lbl := Label.new()
	name_lbl.text = enemy_data.enemy_name
	name_lbl.position = Vector2(-130, -140)
	name_lbl.size = Vector2(260, 40)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
	enemy.add_child(name_lbl)

	var body_col := CollisionShape2D.new()
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(200, 200)
	body_col.shape = body_shape
	enemy.add_child(body_col)

	var contact_area := Area2D.new()
	contact_area.collision_layer = 0
	contact_area.collision_mask = 1
	contact_area.monitoring = true
	enemy.add_child(contact_area)
	var contact_col := CollisionShape2D.new()
	var contact_shape := CircleShape2D.new()
	contact_shape.radius = 140.0
	contact_col.shape = contact_shape
	contact_area.add_child(contact_col)

	var waypoints: Array[Vector2] = _make_enemy_waypoints(pos, enemy_rng)
	_enemy_nodes.append(enemy)
	_enemy_states[idx] = {
		"state": "patrol",
		"waypoints": waypoints,
		"wp_idx": 0,
		"origin": pos,
		"enemy_data": enemy_data,
		"node": enemy,
		"contact_area": contact_area,
		"alert_timer": 0.0,
		"facing_dir": Vector2.RIGHT,
		"defeated": false,
	}

	contact_area.body_entered.connect(func(body: Node2D) -> void:
		if body == _player and not _enemy_states[idx].get("defeated", false):
			_start_combat(enemy)
	)

	_add_enemy_mini_dot(idx, enemy_data)


func _update_enemy(entry: Dictionary, delta: float) -> void:
	var node: CharacterBody2D = entry["node"]
	match entry["state"]:
		"patrol":
			var waypoints: Array = entry["waypoints"]
			var wp_idx: int = entry["wp_idx"]
			var target: Vector2 = waypoints[wp_idx]
			var patrol_dir: Vector2 = (target - node.position).normalized()
			node.velocity = patrol_dir * SPEED_PATROL
			node.move_and_slide()
			if node.velocity.length() > 0.1:
				entry["facing_dir"] = node.velocity.normalized()
			if _check_vision_cone(entry):
				entry["state"] = "alert"
				entry["alert_timer"] = 0.0
				node.velocity = Vector2.ZERO
				return
			if node.position.distance_to(target) < 8.0:
				entry["wp_idx"] = (wp_idx + 1) % 2
		"alert":
			entry["alert_timer"] = entry.get("alert_timer", 0.0) + delta
			node.velocity = Vector2.ZERO
			if entry["alert_timer"] >= 1.2:
				entry["state"] = "chase"
		"chase":
			var chase_dir: Vector2 = (_player.position - node.position).normalized()
			node.velocity = chase_dir * SPEED_CHASE
			node.move_and_slide()
			if node.position.distance_to(_player.position) > 700.0:
				entry["state"] = "return"
		"return":
			var origin: Vector2 = entry["origin"]
			var return_dir: Vector2 = (origin - node.position).normalized()
			node.velocity = return_dir * SPEED_PATROL
			node.move_and_slide()
			if node.position.distance_to(origin) < 8.0:
				entry["state"] = "patrol"


func _check_vision_cone(entry: Dictionary) -> bool:
	var node: CharacterBody2D = entry["node"]
	var facing: Vector2 = entry.get("facing_dir", Vector2.RIGHT)
	var to_player: Vector2 = _player.position - node.position
	var dist: float = to_player.length()
	if dist > 600.0 or dist <= 0.001:
		return false
	var angle: float = rad_to_deg(facing.angle_to(to_player.normalized()))
	return abs(angle) <= 30.0


func _start_combat(enemy_node: CharacterBody2D) -> void:
	for idx in _enemy_states.keys():
		var entry: Dictionary = _enemy_states[idx]
		if entry["node"] != enemy_node:
			continue
		var enemy_data: EnemyData = entry["enemy_data"]
		var to_player: Vector2 = _player.position - enemy_node.position
		var facing: Vector2 = entry.get("facing_dir", Vector2.RIGHT)
		var angle: float = 0.0
		if to_player.length() > 0.001:
			angle = rad_to_deg(facing.angle_to(to_player.normalized()))
		var is_counter: bool = abs(angle) > 120.0
		GameManager.exploration_state["player_position"] = _player.position
		GameManager.exploration_state["pending_combat_enemy_idx"] = idx
		GameManager.pending_combat_enemy = enemy_data.enemy_id
		GameManager.pending_combat_is_counter = is_counter
		GameManager.consume_encounter_stamina()
		GameManager.post_combat_return = "res://scenes/regions/ExplorationScene.tscn"
		EventBus.encounter_triggered.emit({
			"enemy_id": enemy_data.enemy_id,
			"enemy_name": enemy_data.enemy_name,
		})
		SceneManager.go_to(PATH_COMBAT)
		return


# ══════════════════════════════════════════════════════════════════════════════
# EXIT ZONE
# ══════════════════════════════════════════════════════════════════════════════

func _build_exit_zone() -> void:
	_build_exit_left()
	if _scene_idx < GameManager.SUB_SCENE_ORDER.size() - 1:
		_build_exit_right()


func _build_exit_left() -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 1
	add_child(area)

	var col  := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	var h    := TILE * (ROWS - 2)
	rect.size    = Vector2(TILE * 1.2, h)
	col.position = Vector2(TILE * 0.6, TILE + h * 0.5)
	col.shape    = rect
	area.add_child(col)

	area.body_entered.connect(func(body: Node2D) -> void:
		if body != _player: return
		_near_exit = true
		if _scene_idx == 0:
			_hint_lbl.text = "[E]  Rời vùng đất — về Xưởng"
		else:
			var prev_type: String = GameManager.SUB_SCENE_ORDER[_scene_idx - 1]
			var prev_label: String = SUB_SCENE_CONFIG.get(prev_type, {}).get("label", "")
			_hint_lbl.text = "[E]  Quay lại — %s" % prev_label
		_hint_lbl.visible = true
	)
	area.body_exited.connect(func(body: Node2D) -> void:
		if body != _player: return
		_near_exit = false
		_hint_lbl.visible = false
	)


func _build_exit_right() -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	add_child(area)

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	var h := float(TILE * (ROWS - 2))
	rect.size = Vector2(TILE * 1.2, h)
	col.position = Vector2(TILE * COLS - TILE * 0.6, TILE + h * 0.5)
	col.shape = rect
	area.add_child(col)

	var next_type: String = GameManager.SUB_SCENE_ORDER[_scene_idx + 1]
	var next_label: String = SUB_SCENE_CONFIG.get(next_type, {}).get("label", "Tiếp")

	area.body_entered.connect(func(body: Node2D) -> void:
		if body != _player: return
		_near_exit_right = true
		_hint_lbl.text = "[E]  Tiến vào — %s" % next_label
		_hint_lbl.visible = true
	)
	area.body_exited.connect(func(body: Node2D) -> void:
		if body != _player: return
		_near_exit_right = false
		_hint_lbl.visible = false
	)


func _leave_region() -> void:
	if _is_leaving_region:
		return
	_is_leaving_region = true
	if _scene_idx == 0:
		# Về workshop.
		GameManager.current_sub_scene_idx = 0
		GameManager.current_sub_scene_type = GameManager.SUB_SCENE_ORDER[0]
		GameManager.current_region_id = ""
		for item in GameManager.hand_inventory:
			var item_type: int = item.get("item_type", -1)
			if item_type == ItemData.ItemType.MATERIAL or item_type == ItemData.ItemType.BLANK:
				InventorySystem.add_material(item)
			# TODO: Xử lý consumable/loại khác khi có hệ thống dùng item ngoài vùng.
		GameManager.clear_hand()
		GameManager.clear_exploration_state()
		EventBus.region_exited.emit(_region_id)
		if GameManager.is_region_cleared(_region_id):
			GameManager.unlock_next_region_after(_region_id)
		SceneManager.go_to(PATH_WORKSHOP)
	else:
		# Về sub-scene trước.
		GameManager.current_sub_scene_idx = _scene_idx - 1
		GameManager.current_sub_scene_type = GameManager.SUB_SCENE_ORDER[_scene_idx - 1]
		GameManager.exploration_state["entry_paid"] = true
		SceneManager.go_to(PATH_EXPLORATION)


func _advance_sub_scene() -> void:
	if _is_leaving_region:
		return
	if _scene_idx >= GameManager.SUB_SCENE_ORDER.size() - 1:
		return
	_is_leaving_region = true
	GameManager.current_sub_scene_idx = _scene_idx + 1
	GameManager.current_sub_scene_type = GameManager.SUB_SCENE_ORDER[_scene_idx + 1]
	GameManager.exploration_state["entry_paid"] = true
	SceneManager.go_to(PATH_EXPLORATION)


# ══════════════════════════════════════════════════════════════════════════════
# SPECIAL NPCS
# ══════════════════════════════════════════════════════════════════════════════

func _build_special_npcs() -> void:
	if _scene_already_visited:
		return
	if not _should_spawn_co_long_gio():
		return

	var npc := CharacterBody2D.new()
	npc.name = "CoLongGio"
	npc.position = Vector2((COLS - 6) * TILE, 4 * TILE)
	npc.collision_layer = 2
	npc.collision_mask = 0
	add_child(npc)

	var visual := ColorRect.new()
	visual.size = Vector2(38, 54)
	visual.position = Vector2(-19, -27)
	visual.color = Color(0.62, 0.82, 0.92)
	npc.add_child(visual)

	var sash := ColorRect.new()
	sash.size = Vector2(30, 8)
	sash.position = Vector2(-15, -4)
	sash.color = Color(0.94, 0.82, 0.42)
	npc.add_child(sash)

	var name_lbl := Label.new()
	name_lbl.text = "Cô Lộng Gió"
	name_lbl.position = Vector2(-78, -64)
	name_lbl.size = Vector2(156, 28)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(0.80, 0.94, 1.0))
	npc.add_child(name_lbl)

	var body_col := CollisionShape2D.new()
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(38, 54)
	body_col.shape = body_shape
	npc.add_child(body_col)

	var talk_area := Area2D.new()
	talk_area.collision_layer = 0
	talk_area.collision_mask = 1
	talk_area.monitoring = true
	npc.add_child(talk_area)

	var talk_col := CollisionShape2D.new()
	var talk_shape := CircleShape2D.new()
	talk_shape.radius = 96.0
	talk_col.shape = talk_shape
	talk_area.add_child(talk_col)

	talk_area.body_entered.connect(func(body: Node2D) -> void:
		if body != _player:
			return
		_near_co_long_gio = true
		_hint_lbl.text = "[E]  Trò chuyện với Cô Lộng Gió"
		_hint_lbl.visible = true
	)
	talk_area.body_exited.connect(func(body: Node2D) -> void:
		if body != _player:
			return
		_near_co_long_gio = false
		_hint_lbl.visible = false
	)
	_add_npc_mini_icon(
		"co_long_gio",
		npc.position,
		Color(0.72, 0.92, 1.0)
	)


func _should_spawn_co_long_gio() -> bool:
	if _scene_type != "STORY_1":
		return false
	if _region_id != "DongMay":
		return false
	if GameManager.current_day < 3:
		return false
	return GameManager.current_phase != GameManager.GamePhase.NIGHT


func _open_co_long_gio_dialogue() -> void:
	if _tutorial_overlay != null and _tutorial_overlay.visible:
		return
	# Đã xem lần 2 rồi thì không show lại — nàng sẽ im lặng khi đứng gần.
	if GameManager.has_tutorial_seen(FLAG_CO_LONG_GIO_SECOND):
		return
	_ensure_tutorial_overlay()
	_tutorial_overlay.show_steps(_get_co_long_gio_dialogue())
	# Mark đúng lần hiện tại — không mark lần 2 trước khi lần 1 xong.
	if GameManager.has_tutorial_seen(FLAG_CO_LONG_GIO_MET):
		GameManager.mark_tutorial_seen(FLAG_CO_LONG_GIO_SECOND)
		GameManager.trigger_quest_event(FLAG_CO_LONG_GIO_SECOND)
	else:
		GameManager.mark_tutorial_seen(FLAG_CO_LONG_GIO_MET)


func _ensure_tutorial_overlay() -> void:
	if _tutorial_overlay != null:
		return
	var script: GDScript = load(PATH_TUTORIAL_OVERLAY_SCRIPT)
	_tutorial_overlay = script.new() as TutorialOverlayUI
	add_child(_tutorial_overlay)


func _get_co_long_gio_dialogue() -> Array[Dictionary]:
	if GameManager.has_tutorial_seen(FLAG_CO_LONG_GIO_MET):
		return GuideBook.get_co_long_gio_second_dialogue()
	return GuideBook.get_co_long_gio_first_dialogue()


# ══════════════════════════════════════════════════════════════════════════════
# HUD
# ══════════════════════════════════════════════════════════════════════════════

func _build_hud(meta: Dictionary) -> void:
	var vp := get_viewport_rect().size
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)

	var hud := Control.new()
	hud.position = Vector2.ZERO
	hud.size = vp
	hud_layer.add_child(hud)

	var bar := ColorRect.new()
	bar.position = Vector2.ZERO
	bar.size     = Vector2(vp.x, 48)
	bar.color    = Color(0.05, 0.04, 0.03, 0.92)
	hud.add_child(bar)

	var region_lbl := Label.new()
	region_lbl.text     = "%s  ›  %s" % [
		meta.get("name", _region_id),
		_scene_cfg.get("label", ""),
	]
	region_lbl.position = Vector2(16, 8)
	region_lbl.add_theme_font_size_override("font_size", 24)
	region_lbl.add_theme_color_override("font_color", Color(0.95, 0.84, 0.55))
	hud.add_child(region_lbl)

	_lbl_stamina = Label.new()
	_lbl_stamina.position = Vector2(380, 8)
	_lbl_stamina.size     = Vector2(280, 32)
	_lbl_stamina.add_theme_font_size_override("font_size", 22)
	_lbl_stamina.add_theme_color_override("font_color", Color(0.65, 0.92, 0.58))
	hud.add_child(_lbl_stamina)

	_lbl_bag = Label.new()
	_lbl_bag.position = Vector2(680, 8)
	_lbl_bag.size     = Vector2(280, 32)
	_lbl_bag.add_theme_font_size_override("font_size", 22)
	_lbl_bag.add_theme_color_override("font_color", Color(0.85, 0.78, 0.58))
	hud.add_child(_lbl_bag)

	var bag_btn := Button.new()
	bag_btn.text = "Túi (B)"
	bag_btn.position = Vector2(980, 6)
	bag_btn.size = Vector2(120, 36)
	bag_btn.add_theme_font_size_override("font_size", 20)
	bag_btn.pressed.connect(_toggle_bag_overlay)
	hud.add_child(bag_btn)

	_quest_lbl = Label.new()
	_quest_lbl.position = Vector2(1120, 8)
	_quest_lbl.size = Vector2(vp.x - 1300, 32)
	_quest_lbl.add_theme_font_size_override("font_size", 18)
	_quest_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.36))
	_quest_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hud.add_child(_quest_lbl)

	var return_btn := Button.new()
	return_btn.text = "← Về Xưởng"
	return_btn.position = Vector2(vp.x - 166, 6)
	return_btn.size = Vector2(154, 36)
	return_btn.add_theme_font_size_override("font_size", 18)
	return_btn.pressed.connect(_leave_region)
	hud.add_child(return_btn)

	_hint_lbl = Label.new()
	_hint_lbl.position              = Vector2(0, vp.y - 48)
	_hint_lbl.size                  = Vector2(vp.x, 40)
	_hint_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override("font_size", 26)
	_hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.52))
	_hint_lbl.visible = false
	hud.add_child(_hint_lbl)

	_build_move_hint(hud)

	_bag_overlay = _build_bag_overlay()
	hud.add_child(_bag_overlay)

	_build_mini_map(hud, meta)


func _build_move_hint(hud: Control) -> void:
	_move_hint_lbl = Label.new()
	_move_hint_lbl.text = "WASD / ↑↓←→  Di chuyển   ·   E  Tương tác   ·   ESC  Quay về xưởng"
	_move_hint_lbl.position = Vector2(16, 16)
	_move_hint_lbl.add_theme_font_size_override("font_size", 20)
	_move_hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.52, 1.0))
	_move_hint_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_move_hint_lbl.add_theme_constant_override("shadow_offset_x", 1)
	_move_hint_lbl.add_theme_constant_override("shadow_offset_y", 1)
	_move_hint_lbl.visible = false
	hud.add_child(_move_hint_lbl)


func _refresh_hud() -> void:
	var cost: int = GameManager.get_entry_cost(_region_id)
	_lbl_stamina.text = "Thể lực  %d / %d  (vào vùng: -%d)" % [
		GameManager.travel_stamina,
		GameManager.max_travel_stamina,
		cost,
	]
	_lbl_bag.text = "Túi  %d / %d" % [
		GameManager.hand_inventory.size(),
		GameManager.MAX_HAND_SLOTS,
	]
	if _quest_lbl != null:
		var quest_text := GameManager.get_quest_hud_text()
		_quest_lbl.text = quest_text
		_quest_lbl.visible = not quest_text.is_empty()
	if _bag_overlay != null and _bag_overlay.visible:
		_refresh_bag_overlay()


func _build_bag_overlay() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.position = Vector2(360, 110)
	panel.size = Vector2(560, 520)
	overlay.add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.075, 0.055, 0.96)
	style.border_color = Color(0.72, 0.56, 0.22)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var title := Label.new()
	title.text = "TÚI KHÁM PHÁ"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.50))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	_bag_items_box = VBoxContainer.new()
	_bag_items_box.add_theme_constant_override("separation", 8)
	_bag_items_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_bag_items_box)

	var close_btn := Button.new()
	close_btn.text = "[ Đóng ]"
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.pressed.connect(func() -> void:
		_bag_overlay.visible = false
	)
	root.add_child(close_btn)

	return overlay


func _toggle_bag_overlay() -> void:
	if _bag_overlay == null:
		return
	_bag_overlay.visible = not _bag_overlay.visible
	if _bag_overlay.visible:
		_refresh_bag_overlay()


func _refresh_bag_overlay() -> void:
	for child in _bag_items_box.get_children():
		child.queue_free()

	var summary: Dictionary = {}
	for item in GameManager.hand_inventory:
		var item_id: String = item.get("item_id", "")
		if item_id.is_empty():
			continue
		if not summary.has(item_id):
			summary[item_id] = {
				"name": item.get("item_name", item_id),
				"count": 0,
				"rarity": item.get("rarity", 1),
			}
		var entry: Dictionary = summary[item_id]
		entry["count"] = int(entry.get("count", 0)) + 1
		summary[item_id] = entry

	if summary.is_empty():
		_bag_items_box.add_child(_make_bag_line("Chưa có vật phẩm nào.", Color(0.62, 0.58, 0.50)))
		return

	for item_id in summary.keys():
		var entry: Dictionary = summary[item_id]
		var rarity: int = entry.get("rarity", 1)
		var color := Color(0.82, 0.78, 0.66)
		if rarity == 2:
			color = Color(0.42, 0.66, 0.95)
		elif rarity >= 3:
			color = Color(0.95, 0.82, 0.22)
		var line := "%s  x%d" % [entry.get("name", item_id), entry.get("count", 1)]
		_bag_items_box.add_child(_make_bag_line(line, color))


func _make_bag_line(text: String, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return lbl


# ══════════════════════════════════════════════════════════════════════════════
# MINI MAP
# ══════════════════════════════════════════════════════════════════════════════

func _build_mini_map(hud: Control, meta: Dictionary) -> void:
	var vp := get_viewport_rect().size
	var mx := vp.x - MINI_W - 12.0
	var my := 56.0

	# Nền tối + viền
	var bg := ColorRect.new()
	bg.position = Vector2(mx - 2, my - 2)
	bg.size = Vector2(MINI_W + 4, MINI_H + 22)
	bg.color = Color(0.04, 0.03, 0.02, 0.90)
	hud.add_child(bg)

	# Nhãn "BẢN ĐỒ"
	var map_lbl := Label.new()
	map_lbl.text = "BẢN ĐỒ"
	map_lbl.position = Vector2(mx, my)
	map_lbl.size = Vector2(MINI_W, 16)
	map_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_lbl.add_theme_font_size_override("font_size", 13)
	map_lbl.add_theme_color_override("font_color", Color(0.60, 0.54, 0.40))
	hud.add_child(map_lbl)
	my += 18.0

	_build_mini_map_terrain(hud, meta, Vector2(mx, my))

	# Container clip để dot không tràn ra ngoài
	_mini_map_container = Control.new()
	_mini_map_container.position = Vector2(mx, my)
	_mini_map_container.size = Vector2(MINI_W, MINI_H)
	_mini_map_container.clip_contents = true
	hud.add_child(_mini_map_container)

	# Dot người chơi (vàng, 6×6)
	_mini_map_player_dot = ColorRect.new()
	_mini_map_player_dot.size = Vector2(6, 6)
	_mini_map_player_dot.color = Color(1.0, 0.94, 0.22)
	_mini_map_container.add_child(_mini_map_player_dot)


func _build_mini_map_terrain(hud: Control, meta: Dictionary, origin: Vector2) -> void:
	var sx := float(MINI_W) / float(TILE * COLS)
	var sy := float(MINI_H) / float(TILE * ROWS)
	var fc: Color = meta["floor"]
	var wc: Color = meta["wall"]
	var oc: Color = meta["obs"]

	var wall_rect := ColorRect.new()
	wall_rect.position = origin
	wall_rect.size = Vector2(MINI_W, MINI_H)
	wall_rect.color = Color(wc.r * 0.70, wc.g * 0.70, wc.b * 0.70, 1.0)
	hud.add_child(wall_rect)

	var floor_rect := ColorRect.new()
	floor_rect.position = origin + Vector2(TILE * sx, TILE * sy)
	floor_rect.size = Vector2(TILE * (COLS - 2) * sx, TILE * (ROWS - 2) * sy)
	floor_rect.color = Color(fc.r * 0.55, fc.g * 0.55, fc.b * 0.55, 1.0)
	hud.add_child(floor_rect)

	var floor_alt := Color(fc.r * 0.48, fc.g * 0.48, fc.b * 0.48, 1.0)
	for row in range(1, ROWS - 1):
		if row % 2 == 0:
			continue
		var stripe := ColorRect.new()
		stripe.position = origin + Vector2(TILE * sx, row * TILE * sy)
		stripe.size = Vector2(TILE * (COLS - 2) * sx, TILE * sy)
		stripe.color = floor_alt
		hud.add_child(stripe)

	for obstacle_rect in _obstacle_rects:
		var mini_rect := ColorRect.new()
		mini_rect.position = origin + Vector2(
			obstacle_rect.position.x * sx,
			obstacle_rect.position.y * sy
		)
		mini_rect.size = Vector2(obstacle_rect.size.x * sx, obstacle_rect.size.y * sy)
		mini_rect.color = Color(oc.r * 0.85, oc.g * 0.85, oc.b * 0.85, 1.0)
		hud.add_child(mini_rect)

	var exit_strip := ColorRect.new()
	exit_strip.position = origin
	exit_strip.size = Vector2(float(MINI_W) / float(COLS), MINI_H)
	exit_strip.color = Color(0.18, 0.72, 0.32, 0.80)
	hud.add_child(exit_strip)


func _add_enemy_mini_dot(idx: int, enemy_data: EnemyData) -> void:
	if _mini_map_container == null:
		return
	var dot := ColorRect.new()
	dot.size = Vector2(4, 4)
	dot.color = enemy_data.color
	_mini_map_container.add_child(dot)
	_mini_map_enemy_dots[idx] = dot


func _add_npc_mini_icon(npc_id: String, world_pos: Vector2, color: Color) -> void:
	if _mini_map_container == null:
		return
	var icon := Label.new()
	icon.text = "✦"
	icon.size = Vector2(14, 14)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 13)
	icon.add_theme_color_override("font_color", color)
	_mini_map_container.add_child(icon)
	_mini_map_npc_icons[npc_id] = {
		"node": icon,
		"world_pos": world_pos,
	}


func _update_mini_map() -> void:
	if _mini_map_container == null or _player == null:
		return

	var sx := float(MINI_W) / float(TILE * COLS)
	var sy := float(MINI_H) / float(TILE * ROWS)

	if _mini_map_player_dot != null:
		var pp := _player.position
		_mini_map_player_dot.position = Vector2(pp.x * sx - 3.0, pp.y * sy - 3.0)

	for idx in _mini_map_enemy_dots.keys():
		var dot: ColorRect = _mini_map_enemy_dots[idx]
		if not _enemy_states.has(idx):
			continue
		var entry: Dictionary = _enemy_states[idx]
		if entry.get("defeated", false):
			dot.visible = false
			continue
		var ep: Vector2 = (entry["node"] as CharacterBody2D).position
		dot.position = Vector2(ep.x * sx - 2.0, ep.y * sy - 2.0)
		# Đỏ khi đang đuổi / cảnh giác
		match entry.get("state", "patrol"):
			"chase", "alert":
				dot.color = Color(0.95, 0.18, 0.18)
			_:
				dot.color = (entry["enemy_data"] as EnemyData).color

	for npc_id in _mini_map_npc_icons.keys():
		var npc_entry: Dictionary = _mini_map_npc_icons[npc_id]
		var icon: Label = npc_entry["node"]
		var np: Vector2 = npc_entry["world_pos"]
		icon.position = Vector2(np.x * sx - 7.0, np.y * sy - 7.0)


# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _setup_exploration_state() -> void:
	var state: Dictionary = GameManager.exploration_state
	var can_restore: bool = state.has("rng_seed") and state.get("region_id", "") == _region_id
	if not can_restore:
		var new_seed := int(Time.get_ticks_usec())
		state = {
			"region_id": _region_id,
			"rng_seed": new_seed,
			"enemy_spawn_seed": new_seed + 17,
			"pending_loot": [],
			"pending_combat_enemy_idx": -1,
			"entry_paid": false,
			"player_position": Vector2(TILE * (COLS / 2), TILE * (ROWS / 2)),
		}
		GameManager.exploration_state = state
	else:
		_ensure_exploration_state_keys()

	seed(int(GameManager.exploration_state["rng_seed"]))


func _ensure_exploration_state_keys() -> void:
	var state: Dictionary = GameManager.exploration_state
	if not state.has("enemy_spawn_seed"):
		state["enemy_spawn_seed"] = int(Time.get_ticks_usec())
	if not state.has("pending_loot"):
		state["pending_loot"] = []
	if not state.has("pending_combat_enemy_idx"):
		state["pending_combat_enemy_idx"] = -1
	if not state.has("entry_paid"):
		state["entry_paid"] = false
	if not state.has("player_position"):
		state["player_position"] = Vector2(TILE * (COLS / 2), TILE * (ROWS / 2))
	GameManager.exploration_state = state


func _make_enemy_waypoints(origin: Vector2, enemy_rng: RandomNumberGenerator) -> Array[Vector2]:
	var waypoints: Array[Vector2] = []
	for _i in 2:
		var offset := Vector2(enemy_rng.randi_range(-8, 8) * TILE, enemy_rng.randi_range(-8, 8) * TILE)
		var point := origin + offset
		point.x = clampf(point.x, TILE * 1.5, TILE * (COLS - 1.5))
		point.y = clampf(point.y, TILE * 1.5, TILE * (ROWS - 1.5))
		waypoints.append(point)
	return waypoints


func _rand_enemy_positions(count: int, enemy_rng: RandomNumberGenerator) -> Array:
	var result: Array = []
	for _idx in count:
		var placed := false
		for _attempt in ENEMY_SPAWN_RETRIES:
			var grid := Vector2i(
				enemy_rng.randi_range(3, COLS - 4),
				enemy_rng.randi_range(3, ROWS - 4)
			)
			if _is_valid_enemy_spawn_grid(grid, result):
				result.append(grid)
				placed = true
				break
		if not placed:
			push_warning(
				"Không tìm được vị trí enemy zone; dùng fallback gần trung tâm map."
			)
			result.append(_fallback_enemy_spawn_grid(result))
	return result


func _is_valid_enemy_spawn_grid(grid: Vector2i, existing: Array) -> bool:
	if _is_protected_enemy_spawn_grid(grid):
		return false
	if _is_obstacle_grid(grid):
		return false
	for prev in existing:
		var prev_grid := prev as Vector2i
		if abs(prev_grid.x - grid.x) < 8 and abs(prev_grid.y - grid.y) < 8:
			return false
	return true


func _is_protected_enemy_spawn_grid(grid: Vector2i) -> bool:
	var cx: int = COLS / 2
	var cy: int = ROWS / 2
	if grid.x <= 3:
		return true
	if grid.x < 3 or grid.x > COLS - 4 or grid.y < 3 or grid.y > ROWS - 4:
		return true
	return abs(grid.x - cx) < 5 and abs(grid.y - cy) < 5


func _is_obstacle_grid(grid: Vector2i) -> bool:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE * 0.75, TILE * 0.75)

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(
		0.0,
		Vector2(grid.x * TILE + TILE * 0.5, grid.y * TILE + TILE * 0.5)
	)
	query.collision_mask = 4
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var hits := get_world_2d().direct_space_state.intersect_shape(query, 1)
	return not hits.is_empty()


func _fallback_enemy_spawn_grid(existing: Array) -> Vector2i:
	var center := Vector2i(COLS / 2, ROWS / 2)
	var offsets := [
		Vector2i(6, 0),
		Vector2i(-6, 0),
		Vector2i(0, 6),
		Vector2i(0, -6),
		Vector2i(8, 4),
		Vector2i(-8, 4),
		Vector2i(8, -4),
		Vector2i(-8, -4),
		Vector2i(10, 0),
		Vector2i(0, 10),
	]
	for offset in offsets:
		var candidate: Vector2i = center + offset
		if _is_valid_enemy_spawn_grid(candidate, existing):
			return candidate
	for offset in offsets:
		var loose_candidate: Vector2i = center + offset
		if not _is_protected_enemy_spawn_grid(loose_candidate) and not _is_obstacle_grid(loose_candidate):
			return loose_candidate
	return Vector2i(COLS / 2 + 6, ROWS / 2)


func _get_restore_player_position() -> Vector2:
	var fallback: Vector2 = Vector2(TILE * (COLS / 2), TILE * (ROWS / 2))
	var stored_position: Variant = GameManager.exploration_state.get("player_position", fallback)
	var pos: Vector2 = stored_position if stored_position is Vector2 else fallback
	return pos.clamp(
		Vector2(TILE * 1.5, TILE * 1.5),
		Vector2(TILE * (COLS - 1.5), TILE * (ROWS - 1.5))
	)


func _clamp_player_in_bounds() -> void:
	if _player == null:
		return
	_player.position = _player.position.clamp(
		Vector2(TILE * 1.5, TILE * 1.5),
		Vector2(TILE * (COLS - 1.5), TILE * (ROWS - 1.5))
	)


func _consume_pending_loot() -> void:
	var pending_loot: Array = GameManager.exploration_state.get("pending_loot", [])
	if pending_loot.is_empty():
		return

	var received_names: Array[String] = []
	var remaining_loot: Array[Dictionary] = []
	for loot in pending_loot:
		var item_id: String = loot.get("item_id", "")
		var item: ItemData = ItemDatabase.get_item(item_id)
		if item == null:
			continue
		var hand_item := _item_to_hand_entry(item)
		if GameManager.add_to_hand(hand_item):
			received_names.append(item.item_name)
		else:
			remaining_loot.append(loot)

	GameManager.exploration_state["pending_loot"] = remaining_loot
	_refresh_hud()
	if not received_names.is_empty():
		_hint_lbl.text = "[Nhận: %s]" % ", ".join(received_names)
		_hint_lbl.visible = true
	elif not remaining_loot.is_empty():
		_hint_lbl.text = "Túi đầy — chiến lợi phẩm đang chờ nhận!"
		_hint_lbl.visible = true


func _item_to_hand_entry(item: ItemData) -> Dictionary:
	var hand_item: Dictionary = {
		"item_id": item.item_id,
		"item_name": item.item_name,
		"rarity": item.rarity,
		"base_value": item.base_value,
		"item_type": item.item_type,
	}
	hand_item.merge(item.effect_data)
	return hand_item


func _build_gather_nodes() -> void:
	var count: int = _scene_cfg.get("gather_count", 0)
	if count == 0:
		return
	var gather_key := "gather_seed_" + _scene_visited_key
	if not GameManager.exploration_state.has(gather_key):
		GameManager.exploration_state[gather_key] = int(Time.get_ticks_usec())
	var rng := RandomNumberGenerator.new()
	rng.seed = int(GameManager.exploration_state[gather_key])
	var collected_key := "gather_collected_" + _scene_visited_key
	var collected: Array = GameManager.exploration_state.get(collected_key, [])
	var pool: Array[ItemData] = []
	for item in ItemDatabase.get_items_by_type(ItemData.ItemType.MATERIAL):
		if item.effect_data.get("region", "") == _region_id:
			pool.append(item)
	if pool.is_empty():
		pool = ItemDatabase.get_items_by_type(ItemData.ItemType.MATERIAL)
	var occupied: Dictionary = {}
	for i in _gather_nodes.size():
		pass
	for i in count:
		var tries := 0
		var gx := 0
		var gy := 0
		var ok := false
		while tries < 60 and not ok:
			tries += 1
			gx = rng.randi_range(4, COLS - 5)
			gy = rng.randi_range(4, ROWS - 5)
			var gv := Vector2i(gx, gy)
			if occupied.has(gv):
				continue
			var cx := COLS / 2
			var cy := ROWS / 2
			if abs(gx - cx) < 4 and abs(gy - cy) < 4:
				continue
			var rect := Rect2(Vector2(gx * TILE, gy * TILE), Vector2(TILE, TILE))
			var blocked := false
			for obs in _obstacle_rects:
				if obs.intersects(rect):
					blocked = true
					break
			if blocked:
				continue
			ok = true
			occupied[gv] = true
		if not ok:
			continue
		var is_collected: bool = i < collected.size() and bool(collected[i])
		var item: ItemData = pool[rng.randi() % pool.size()]
		var world_pos := Vector2(gx * TILE + TILE * 0.5, gy * TILE + TILE * 0.5)
		var node := _spawn_gather_node(i, item, world_pos, is_collected)
		_gather_nodes.append(node)


func _spawn_gather_node(
		idx: int, item: ItemData, pos: Vector2, is_collected: bool
) -> Node2D:
	var area := Area2D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.set_meta("gather_idx", idx)
	area.set_meta("item_id", item.item_id)
	area.set_meta("collected", is_collected)
	add_child(area)

	var visual := ColorRect.new()
	visual.size = Vector2(56, 56)
	visual.position = Vector2(-28, -28)
	visual.color = (
		Color(0.25, 0.25, 0.20, 0.5) if is_collected
		else Color(0.35, 0.58, 0.20, 0.85)
	)
	area.add_child(visual)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 80.0
	col.shape = shape
	area.add_child(col)

	area.body_entered.connect(func(body: Node2D) -> void:
		if body != _player or area.get_meta("collected", false):
			return
		_near_gather_idx = area.get_meta("gather_idx", -1)
		_hint_lbl.text = "[E]  Nhặt nguyên liệu (%s)" % item.item_name
		_hint_lbl.visible = true
	)
	area.body_exited.connect(func(body: Node2D) -> void:
		if body != _player:
			return
		if _near_gather_idx == area.get_meta("gather_idx", -1):
			_near_gather_idx = -1
			_hint_lbl.visible = false
	)
	return area


func _collect_gather(idx: int) -> void:
	if idx < 0 or idx >= _gather_nodes.size():
		return
	var node := _gather_nodes[idx]
	if node.get_meta("collected", false):
		return
	node.set_meta("collected", true)
	var visual := node.get_child(0) as ColorRect
	if visual != null:
		visual.color = Color(0.25, 0.25, 0.20, 0.5)
	var collected_key := "gather_collected_" + _scene_visited_key
	var collected: Array = GameManager.exploration_state.get(collected_key, [])
	while collected.size() <= idx:
		collected.append(false)
	collected[idx] = true
	GameManager.exploration_state[collected_key] = collected
	_near_gather_idx = -1
	_hint_lbl.visible = false
	var item_id: String = node.get_meta("item_id", "")
	var item: ItemData = ItemDatabase.get_item(item_id)
	if item == null:
		return
	var hand_item := _item_to_hand_entry(item)
	if GameManager.add_to_hand(hand_item):
		_hint_lbl.text = "[Nhặt: %s]" % item.item_name
		_hint_lbl.visible = true
		_refresh_hud()
	else:
		_hint_lbl.text = "Túi đầy!"
		_hint_lbl.visible = true


func _open_pause_menu() -> void:
	if _pause_menu == null:
		var scene := load(PATH_PAUSE_MENU)
		if scene == null:
			return
		_pause_menu = scene.instantiate()
		add_child(_pause_menu)
	_pause_menu.open()
