# scripts/regions/exploration_scene.gd
# Khám phá vùng đất: map procedural, chạm kẻ địch → combat.
extends Node2D

const TILE  := 64
const COLS  := 50
const ROWS  := 28
const PATH_WORKSHOP := "res://scenes/main/WorkshopHub.tscn"
const PATH_COMBAT   := "res://scenes/combat/CombatScene.tscn"
const SPEED_PATROL := 55.0
const SPEED_CHASE  := 110.0
const ENEMY_SPAWN_RETRIES := 30

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
var _player:       CharacterBody2D
var _near_exit:    bool       = false
var _enemy_nodes:  Array[CharacterBody2D] = []
var _enemy_states: Dictionary = {}
var _pending_meta: Dictionary = {}

# HUD
var _hint_lbl:    Label
var _lbl_stamina: Label
var _lbl_bag:     Label
var _bag_overlay: Control
var _bag_items_box: VBoxContainer


# ══════════════════════════════════════════════════════════════════════════════
# READY
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_region_id = GameManager.current_region_id
	if _region_id.is_empty():
		_region_id = "DongMay"

	var meta: Dictionary = REGION_META.get(_region_id, REGION_META["DongMay"])

	_setup_exploration_state()
	# Trừ thể lực khi vào vùng mới; restore từ combat không trừ lần hai.
	var entry_paid: bool = GameManager.exploration_state.get("entry_paid", false)
	var is_new_session: bool = not GameManager.exploration_state.has("entry_paid") or not entry_paid
	if is_new_session:
		GameManager.consume_entry_stamina(_region_id)
		GameManager.exploration_state["entry_paid"] = true
	_build_map(meta)
	_build_player()
	_pending_meta = meta
	call_deferred("_build_enemies", _pending_meta)
	_build_exit_zone()
	_build_hud(meta)
	_refresh_hud()
	_consume_pending_loot()

	GameManager.travel_stamina_changed.connect(func(_c: int, _m: int) -> void: _refresh_hud())
	EventBus.region_entered.emit(_region_id)


# ══════════════════════════════════════════════════════════════════════════════
# PROCESS — enemy AI
# ══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	for entry in _enemy_states.values():
		if entry.get("defeated", false):
			continue
		_update_enemy(entry, delta)


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
		KEY_ESCAPE:
			if _bag_overlay != null and _bag_overlay.visible:
				_bag_overlay.visible = false
			else:
				_leave_region()


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

	# Vân nền xen kẽ
	var floor_alt := Color(meta["floor"].r * 0.91, meta["floor"].g * 0.91, meta["floor"].b * 0.91)
	for r in range(1, ROWS - 1):
		if r % 2 == 0: continue
		var stripe := ColorRect.new()
		stripe.position = Vector2(TILE, r * TILE)
		stripe.size     = Vector2(TILE * (COLS - 2), TILE)
		stripe.color    = floor_alt
		add_child(stripe)

	_build_wall_col()
	_build_obstacles(meta)


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
	var occupied: Dictionary = {}
	var cx := COLS / 2
	var cy := ROWS / 2

	# Vùng an toàn: giữa map (player spawn), cạnh trái (exit), border
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			occupied[Vector2i(cx + dx, cy + dy)] = true
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
	_add_player_camera()


func _add_player_camera() -> void:
	var camera := Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = TILE * COLS
	camera.limit_bottom = TILE * ROWS
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.make_current()
	_player.add_child(camera)


# ══════════════════════════════════════════════════════════════════════════════
# ENEMIES
# ══════════════════════════════════════════════════════════════════════════════

func _build_enemies(_meta: Dictionary) -> void:
	var enemy_list: Array[EnemyData] = EnemyDatabase.get_enemies_by_region(_region_id)
	if enemy_list.is_empty():
		return

	var enemy_rng := RandomNumberGenerator.new()
	enemy_rng.seed = int(GameManager.exploration_state.get("enemy_spawn_seed", Time.get_ticks_usec()))
	var spawn_count := 6
	var spots: Array = _rand_enemy_positions(spawn_count, enemy_rng)
	for i in spots.size():
		var enemy_data: EnemyData = enemy_list[i % enemy_list.size()]
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
	visual.size = Vector2(40, 40)
	visual.position = Vector2(-20, -20)
	visual.color = enemy_data.color
	enemy.add_child(visual)

	var name_lbl := Label.new()
	name_lbl.text = enemy_data.enemy_name
	name_lbl.position = Vector2(-52, -52)
	name_lbl.size = Vector2(104, 28)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
	enemy.add_child(name_lbl)

	var body_col := CollisionShape2D.new()
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(40, 40)
	body_col.shape = body_shape
	enemy.add_child(body_col)

	var detection_area := Area2D.new()
	detection_area.collision_layer = 0
	detection_area.collision_mask = 1
	detection_area.monitoring = true
	enemy.add_child(detection_area)
	var detection_col := CollisionShape2D.new()
	var detection_shape := CircleShape2D.new()
	detection_shape.radius = 220.0
	detection_col.shape = detection_shape
	detection_area.add_child(detection_col)

	var contact_area := Area2D.new()
	contact_area.collision_layer = 0
	contact_area.collision_mask = 1
	contact_area.monitoring = true
	enemy.add_child(contact_area)
	var contact_col := CollisionShape2D.new()
	var contact_shape := CircleShape2D.new()
	contact_shape.radius = 28.0
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
		"detection_area": detection_area,
		"contact_area": contact_area,
		"defeated": false,
	}

	detection_area.body_entered.connect(func(body: Node2D) -> void:
		if body == _player and not _enemy_states[idx].get("defeated", false):
			_enemy_states[idx]["state"] = "chase"
	)
	detection_area.body_exited.connect(func(body: Node2D) -> void:
		if body == _player and not _enemy_states[idx].get("defeated", false):
			_enemy_states[idx]["state"] = "return"
	)
	contact_area.body_entered.connect(func(body: Node2D) -> void:
		if body == _player and not _enemy_states[idx].get("defeated", false):
			_start_combat(enemy)
	)


func _update_enemy(entry: Dictionary, _delta: float) -> void:
	var node: CharacterBody2D = entry["node"]
	match entry["state"]:
		"patrol":
			var waypoints: Array = entry["waypoints"]
			var wp_idx: int = entry["wp_idx"]
			var target: Vector2 = waypoints[wp_idx]
			var patrol_dir: Vector2 = (target - node.position).normalized()
			node.velocity = patrol_dir * SPEED_PATROL
			node.move_and_slide()
			if node.position.distance_to(target) < 8.0:
				entry["wp_idx"] = (wp_idx + 1) % 2
		"chase":
			var chase_dir: Vector2 = (_player.position - node.position).normalized()
			node.velocity = chase_dir * SPEED_CHASE
			node.move_and_slide()
		"return":
			var origin: Vector2 = entry["origin"]
			var return_dir: Vector2 = (origin - node.position).normalized()
			node.velocity = return_dir * SPEED_PATROL
			node.move_and_slide()
			if node.position.distance_to(origin) < 8.0:
				entry["state"] = "patrol"


func _start_combat(enemy_node: CharacterBody2D) -> void:
	for idx in _enemy_states.keys():
		var entry: Dictionary = _enemy_states[idx]
		if entry["node"] != enemy_node:
			continue
		var enemy_data: EnemyData = entry["enemy_data"]
		GameManager.exploration_state["player_position"] = _player.position
		GameManager.exploration_state["pending_combat_enemy_idx"] = idx
		GameManager.pending_combat_enemy = enemy_data.enemy_id
		GameManager.post_combat_return = "res://scenes/regions/ExplorationScene.tscn"
		EventBus.encounter_triggered.emit({
			"enemy_id": enemy_data.enemy_id,
			"enemy_name": enemy_data.enemy_name,
		})
		SceneManager.go_to(PATH_COMBAT)
		return


# ══════════════════════════════════════════════════════════════════════════════
# EXIT ZONE (trái)
# ══════════════════════════════════════════════════════════════════════════════

func _build_exit_zone() -> void:
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
		_near_exit        = true
		_hint_lbl.text    = "[E]  Rời vùng đất — về Xưởng"
		_hint_lbl.visible = true
	)
	area.body_exited.connect(func(body: Node2D) -> void:
		if body != _player: return
		_near_exit        = false
		_hint_lbl.visible = false
	)


func _leave_region() -> void:
	GameManager.current_region_id = ""
	for item in GameManager.hand_inventory:
		var item_type: int = item.get("item_type", -1)
		if item_type == ItemData.ItemType.MATERIAL or item_type == ItemData.ItemType.BLANK:
			InventorySystem.add_material(item)
		# TODO: Xử lý consumable/loại khác khi có hệ thống dùng item ngoài vùng.
	GameManager.clear_hand()
	GameManager.clear_exploration_state()
	EventBus.region_exited.emit(_region_id)
	SceneManager.go_to(PATH_WORKSHOP)


# ══════════════════════════════════════════════════════════════════════════════
# HUD
# ══════════════════════════════════════════════════════════════════════════════

func _build_hud(meta: Dictionary) -> void:
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)

	var vp := get_viewport_rect().size

	var bar := ColorRect.new()
	bar.position = Vector2.ZERO
	bar.size     = Vector2(vp.x, 48)
	bar.color    = Color(0.05, 0.04, 0.03, 0.92)
	hud.add_child(bar)

	var region_lbl := Label.new()
	region_lbl.text     = meta.get("name", _region_id)
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

	var esc_lbl := Label.new()
	esc_lbl.text = "[ESC]  Quay về Xưởng"
	esc_lbl.position = Vector2(vp.x - 310, 8)
	esc_lbl.size     = Vector2(300, 32)
	esc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	esc_lbl.add_theme_font_size_override("font_size", 20)
	esc_lbl.add_theme_color_override("font_color", Color(0.58, 0.55, 0.48))
	hud.add_child(esc_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.position              = Vector2(0, vp.y - 48)
	_hint_lbl.size                  = Vector2(vp.x, 40)
	_hint_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override("font_size", 26)
	_hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.52))
	_hint_lbl.visible = false
	hud.add_child(_hint_lbl)

	_bag_overlay = _build_bag_overlay()
	hud.add_child(_bag_overlay)


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
		var offset := Vector2(enemy_rng.randi_range(-3, 3) * TILE, enemy_rng.randi_range(-3, 3) * TILE)
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
	if stored_position is Vector2:
		return stored_position
	return fallback


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
