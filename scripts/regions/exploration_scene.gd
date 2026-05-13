# scripts/regions/exploration_scene.gd
# Khám phá vùng đất: map procedural, thu thập tài nguyên (E), chạm vùng kẻ địch → combat (kiểu Pokémon).
extends Node2D

const TILE  := 64
const COLS  := 30
const ROWS  := 17
const PATH_WORKSHOP := "res://scenes/main/WorkshopHub.tscn"
const PATH_COMBAT   := "res://scenes/combat/CombatScene.tscn"

const REGION_META: Dictionary = {
	"DongMay":    {"name":"Đồng Mây Trắng",    "floor":Color(0.55,0.52,0.35), "wall":Color(0.28,0.18,0.08), "obs":Color(0.42,0.35,0.22), "grass":Color(0.45,0.62,0.28,0.42)},
	"RungTramHon":{"name":"Rừng Trăm Hồn",     "floor":Color(0.18,0.33,0.16), "wall":Color(0.10,0.20,0.08), "obs":Color(0.14,0.28,0.12), "grass":Color(0.18,0.52,0.22,0.42)},
	"NuiThanDo":  {"name":"Núi Than Đỏ",        "floor":Color(0.30,0.20,0.16), "wall":Color(0.16,0.10,0.08), "obs":Color(0.45,0.22,0.14), "grass":Color(0.72,0.28,0.12,0.42)},
	"BaiCat":     {"name":"Bãi Cát Thần Vàng",  "floor":Color(0.75,0.68,0.45), "wall":Color(0.55,0.42,0.22), "obs":Color(0.65,0.52,0.28), "grass":Color(0.88,0.72,0.22,0.42)},
	"ThanhNgoc":  {"name":"Thành Ngọc Bích",    "floor":Color(0.38,0.52,0.60), "wall":Color(0.20,0.30,0.42), "obs":Color(0.28,0.45,0.55), "grass":Color(0.28,0.62,0.80,0.42)},
	"LangTo":     {"name":"Làng Tổ Nghề",        "floor":Color(0.46,0.40,0.33), "wall":Color(0.26,0.20,0.16), "obs":Color(0.38,0.28,0.22), "grass":Color(0.52,0.62,0.28,0.42)},
}

# ── State ──────────────────────────────────────────────────────────────────────
var _region_id:    String
var _player:       CharacterBody2D
var _near_gather:  Dictionary = {}   # {root, item, area, collected}
var _near_exit:    bool       = false
var _in_enc_zone:  bool       = false
var _enc_timer:    float      = 0.0
const ENC_INTERVAL := 2.5
const ENC_CHANCE   := 0.40
var _gather_data:  Array      = []   # Array of Dictionary

# HUD
var _hint_lbl:    Label
var _lbl_stamina: Label
var _lbl_bag:     Label


# ══════════════════════════════════════════════════════════════════════════════
# READY
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_region_id = GameManager.current_region_id
	if _region_id.is_empty():
		_region_id = "DongMay"

	var meta: Dictionary = REGION_META.get(_region_id, REGION_META["DongMay"])

	randomize()
	_build_map(meta)
	_build_player()
	_build_gather_nodes(meta)
	_build_enemy_zones(meta)
	_build_exit_zone()
	_build_hud(meta)
	_refresh_hud()

	GameManager.travel_stamina_changed.connect(func(_c: int, _m: int) -> void: _refresh_hud())
	EventBus.region_entered.emit(_region_id)


# ══════════════════════════════════════════════════════════════════════════════
# PROCESS — encounter tick
# ══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if _in_enc_zone:
		_enc_timer -= delta
		if _enc_timer <= 0.0:
			_enc_timer = ENC_INTERVAL + randf_range(-0.5, 0.8)
			_try_encounter()


# ══════════════════════════════════════════════════════════════════════════════
# INPUT
# ══════════════════════════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey): return
	var key := event as InputEventKey
	if not key.pressed or key.echo: return
	match key.keycode:
		KEY_E:
			if not _near_gather.is_empty():
				_do_gather()
			elif _near_exit:
				_leave_region()
		KEY_ESCAPE:
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
	_player.position = Vector2(TILE * (COLS / 2), TILE * (ROWS / 2))
	add_child(_player)


# ══════════════════════════════════════════════════════════════════════════════
# GATHER NODES
# ══════════════════════════════════════════════════════════════════════════════

func _build_gather_nodes(meta: Dictionary) -> void:
	var items: Array = ItemDatabase.get_items_by_region(_region_id)
	if items.is_empty(): return

	var spots := _rand_floor_positions(6)
	var count := mini(spots.size(), 6)
	for i in count:
		var item: ItemData = items[i % items.size()]
		var pos := Vector2(spots[i].x * TILE + TILE * 0.5, spots[i].y * TILE + TILE * 0.5)
		_spawn_gather(item, pos, meta)


func _spawn_gather(item: ItemData, pos: Vector2, meta: Dictionary) -> void:
	var root := Node2D.new()
	root.position = pos
	add_child(root)

	# Visual — hình vuông sáng
	var sz     := 26.0
	var visual := ColorRect.new()
	visual.size     = Vector2(sz, sz)
	visual.position = Vector2(-sz * 0.5, -sz * 0.5)
	var fc: Color = meta["floor"]
	visual.color  = Color(minf(fc.r * 1.7, 1.0), minf(fc.g * 1.7, 1.0), minf(fc.b * 1.5, 1.0))
	root.add_child(visual)

	var lbl := Label.new()
	lbl.text = item.item_name
	lbl.position = Vector2(-52, -52)
	lbl.size     = Vector2(104, 36)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.65))
	root.add_child(lbl)

	# Proximity Area2D
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 1
	var col  := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = float(TILE) * 0.75
	col.shape   = circ
	area.add_child(col)
	root.add_child(area)

	var entry: Dictionary = {"root": root, "item": item, "area": area, "collected": false}
	_gather_data.append(entry)

	area.body_entered.connect(func(body: Node2D) -> void:
		if body != _player or entry["collected"]: return
		_near_gather = entry
		_hint_lbl.text    = "[E]  Thu thập: %s" % item.item_name
		_hint_lbl.visible = true
	)
	area.body_exited.connect(func(body: Node2D) -> void:
		if body != _player: return
		if _near_gather.get("area") == area:
			_near_gather     = {}
			_hint_lbl.visible = false
	)


func _do_gather() -> void:
	if _near_gather.is_empty(): return
	if _near_gather.get("collected", false): return

	if GameManager.is_hand_full():
		_hint_lbl.text = "Túi đầy! (%d / %d)" % [GameManager.hand_inventory.size(), GameManager.MAX_HAND_SLOTS]
		return

	if not GameManager.consume_travel_stamina(1):
		_hint_lbl.text = "Hết thể lực — không thể thu thập!"
		return

	var item: ItemData = _near_gather["item"]
	var mat: Dictionary = {
		"item_id":   item.item_id,
		"item_name": item.item_name,
		"rarity":    item.rarity,
		"base_value":item.base_value,
		"item_type": item.item_type,
	}
	mat.merge(item.effect_data)
	GameManager.add_to_hand(mat)
	EventBus.gathering_node_collected.emit(mat)

	_near_gather["collected"] = true
	var root: Node2D = _near_gather["root"]
	for child in root.get_children():
		if child is ColorRect or child is Label:
			child.modulate.a = 0.22

	_near_gather      = {}
	_hint_lbl.visible = false
	_refresh_hud()


# ══════════════════════════════════════════════════════════════════════════════
# ENEMY ZONES (Pokémon-style)
# ══════════════════════════════════════════════════════════════════════════════

func _build_enemy_zones(meta: Dictionary) -> void:
	var grass_c: Color = meta["grass"]
	# 3 zone tại vị trí cố định trên grid (tránh giữa và exit)
	var zone_grids: Array = [
		Vector2i(4,  2),
		Vector2i(22, 2),
		Vector2i(12, 11),
	]
	for gp in zone_grids:
		_spawn_enc_zone(gp, grass_c)


func _spawn_enc_zone(grid_pos: Vector2i, color: Color) -> void:
	var zone_w := TILE * 4
	var zone_h := TILE * 3
	var pos    := Vector2(grid_pos.x * TILE, grid_pos.y * TILE)

	var visual := ColorRect.new()
	visual.position = pos
	visual.size     = Vector2(zone_w, zone_h)
	visual.color    = color
	add_child(visual)

	var qlbl := Label.new()
	qlbl.text     = "?"
	qlbl.position = pos + Vector2(zone_w * 0.5 - 12, zone_h * 0.5 - 20)
	qlbl.add_theme_font_size_override("font_size", 38)
	qlbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35))
	add_child(qlbl)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 1
	add_child(area)

	var col  := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size    = Vector2(zone_w, zone_h)
	col.position = pos + Vector2(zone_w, zone_h) * 0.5
	col.shape    = rect
	area.add_child(col)

	area.body_entered.connect(func(body: Node2D) -> void:
		if body != _player: return
		_in_enc_zone = true
		_enc_timer   = ENC_INTERVAL
	)
	area.body_exited.connect(func(body: Node2D) -> void:
		if body != _player: return
		_in_enc_zone = false
	)


func _try_encounter() -> void:
	if not _in_enc_zone: return
	if randf() > ENC_CHANCE: return

	var enemies: Array = EnemyDatabase.get_enemies_by_region(_region_id)
	if enemies.is_empty(): return

	var enemy_data: EnemyData = enemies[randi() % enemies.size()]

	if not GameManager.consume_travel_stamina(1):
		_hint_lbl.text    = "Hết thể lực — không thể chiến đấu!"
		_hint_lbl.visible = true
		_in_enc_zone = false
		return

	GameManager.pending_combat_enemy = enemy_data.enemy_id
	GameManager.post_combat_return   = "res://scenes/regions/ExplorationScene.tscn"
	EventBus.encounter_triggered.emit({"enemy_id": enemy_data.enemy_id, "enemy_name": enemy_data.enemy_name})
	SceneManager.go_to(PATH_COMBAT)


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


func _refresh_hud() -> void:
	_lbl_stamina.text = "Thể lực  %d / %d" % [GameManager.travel_stamina, GameManager.max_travel_stamina]
	_lbl_bag.text     = "Túi  %d / %d"      % [GameManager.hand_inventory.size(), GameManager.MAX_HAND_SLOTS]


# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _rand_floor_positions(count: int) -> Array:
	var result: Array = []
	var cx := COLS / 2
	var cy := ROWS / 2
	var attempts := 0
	while result.size() < count and attempts < 500:
		attempts += 1
		var c := randi_range(3, COLS - 4)
		var r := randi_range(3, ROWS - 4)
		# Tránh spawn player
		if abs(c - cx) < 4 and abs(r - cy) < 4: continue
		# Tránh exit zone
		if c <= 2: continue
		var v := Vector2i(c, r)
		# Tránh quá gần nhau
		var too_close := false
		for prev in result:
			if abs((prev as Vector2i).x - v.x) < 3 and abs((prev as Vector2i).y - v.y) < 3:
				too_close = true; break
		if not too_close:
			result.append(v)
	return result
