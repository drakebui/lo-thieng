# scripts/main/workshop_hub.gd
# Màn trung tâm điều phối vòng lặp ngày:
#   MORNING  → WorldExit  → khám phá vùng đất
#   NOON     → ForgeZone  → lò rèn
#   AFTERNOON→ ShopDoor   → mở tiệm
#   NIGHT    → BedZone    → kết thúc ngày
extends Node2D

# ══════════════════════════════════════════════════════════════════════════════
# CONSTANTS
# ══════════════════════════════════════════════════════════════════════════════

const TILE := 64

const C_WALL      := Color(0.20, 0.12, 0.06)
const C_FLOOR     := Color(0.55, 0.40, 0.25)
const C_FLOOR_ALT := Color(0.48, 0.34, 0.20)
const C_FORGE_BG  := Color(0.22, 0.10, 0.04)
const C_FORGE_FRE := Color(0.92, 0.44, 0.08)
const C_BED_BG    := Color(0.18, 0.30, 0.48)
const C_DOOR      := Color(0.55, 0.42, 0.22)
const C_LABEL_FRG := Color(1.00, 0.80, 0.35)
const C_LABEL_BED := Color(0.72, 0.88, 1.00)
const C_HINT      := Color(1.00, 0.92, 0.52)
const C_HUD_BAR   := Color(0.07, 0.04, 0.02, 0.90)
const C_HUD_TEXT  := Color(0.94, 0.84, 0.65)

# Scene path
const PATH_FORGE := "res://scenes/forge/MaterialPicker.tscn"
const PATH_SHOP  := "res://scenes/shop/ShopScene.tscn"

# Zone IDs
const ZONE_FORGE := "forge"
const ZONE_BED   := "bed"
const ZONE_EXIT  := "exit"
const ZONE_SHOP  := "shop"

# Vị trí các zone — tính động theo viewport trong _init_layout()
var cols: int
var rows: int
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

# ══════════════════════════════════════════════════════════════════════════════
# STATE
# ══════════════════════════════════════════════════════════════════════════════

var _player:    CharacterBody2D
var _near_zone: String = ""

var _lbl_day:     Label
var _lbl_phase:   Label
var _lbl_stamina: Label
var _lbl_gold:    Label
var _hint_lbl:    Label

var _region_select: CanvasLayer   # lazy-load
var _day_summary:   CanvasLayer   # lazy-load

# ══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════════

func _init_layout() -> void:
	var vp := get_viewport_rect().size
	cols          = ceili(vp.x / float(TILE))        # 30 @ 1920
	rows          = ceili(vp.y / float(TILE))        # 17 @ 1080
	forge_center  = Vector2(TILE * 3,           TILE * 3)
	forge_size    = Vector2(TILE * 5,           TILE * 4)
	bed_center    = Vector2(vp.x - TILE * 3,   TILE * 3)
	bed_size      = Vector2(TILE * 4,           TILE * 4)
	door_center_y = vp.y * 0.5
	door_half_h   = float(TILE * 2)
	exit_center   = Vector2(TILE * 0.5,         door_center_y)
	exit_size     = Vector2(float(TILE),         door_half_h * 2.0)
	shop_center   = Vector2(vp.x - TILE * 0.5,  door_center_y)
	shop_size     = Vector2(float(TILE),         door_half_h * 2.0)


func _ready() -> void:
	if not GameManager.save_restored:
		if SaveSystem.has_save():
			var data := SaveSystem.load_game()
			GameManager.restore_from_save(data)
		else:
			GameManager.save_restored = true
	_init_layout()
	_build_room()
	_build_player()
	_build_zones()
	_build_hud()
	_connect_signals()
	_refresh_hud()
	if not GameManager.pending_day_summary_stats.is_empty():
		var stats := GameManager.pending_day_summary_stats.duplicate()
		GameManager.pending_day_summary_stats = {}
		_open_day_summary(stats)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if key.pressed and key.keycode == KEY_E and _near_zone != "":
		_activate_zone(_near_zone)
		get_viewport().set_input_as_handled()


# ══════════════════════════════════════════════════════════════════════════════
# BUILD — room
# ══════════════════════════════════════════════════════════════════════════════

func _build_room() -> void:
	# Nền tường
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size     = Vector2(TILE * cols, TILE * rows)
	bg.color    = C_WALL
	add_child(bg)

	# Sàn gỗ
	var floor_bg := ColorRect.new()
	floor_bg.position = Vector2(TILE, TILE)
	floor_bg.size     = Vector2(TILE * (cols - 2), TILE * (rows - 2))
	floor_bg.color    = C_FLOOR
	add_child(floor_bg)

	# Vân sàn xen kẽ
	for r: int in range(rows - 2):
		if r % 2 == 0:
			continue
		var plank := ColorRect.new()
		plank.position = Vector2(TILE, TILE + r * TILE)
		plank.size     = Vector2(TILE * (cols - 2), TILE)
		plank.color    = C_FLOOR_ALT
		add_child(plank)

	_build_wall_collision()
	_build_forge_visual()
	_build_bed_visual()
	_build_door_visual(true)    # trái — WorldExit
	_build_door_visual(false)   # phải — ShopDoor


func _build_wall_collision() -> void:
	var sb := StaticBody2D.new()
	sb.collision_layer = 4
	sb.collision_mask  = 0
	add_child(sb)

	var rw       := float(TILE)
	var full_w   := float(TILE * cols)
	var full_h   := float(TILE * rows)
	var door_top := door_center_y - door_half_h
	var door_bot := door_center_y + door_half_h

	# tường trên + dưới (full width)
	_wall_seg(sb, Vector2(0, 0),              Vector2(full_w, rw))
	_wall_seg(sb, Vector2(0, full_h - rw),    Vector2(full_w, rw))

	# tường trái — 2 đoạn kẹp cửa thoát
	_wall_seg(sb, Vector2(0, rw),             Vector2(rw, door_top - rw))
	_wall_seg(sb, Vector2(0, door_bot),       Vector2(rw, full_h - rw - door_bot))

	# tường phải — 2 đoạn kẹp cửa tiệm
	_wall_seg(sb, Vector2(full_w - rw, rw),   Vector2(rw, door_top - rw))
	_wall_seg(sb, Vector2(full_w - rw, door_bot), Vector2(rw, full_h - rw - door_bot))


func _wall_seg(parent: StaticBody2D, pos: Vector2, sz: Vector2) -> void:
	if sz.x <= 0.0 or sz.y <= 0.0:
		return
	var col  := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size    = sz
	col.position = pos + sz * 0.5
	col.shape    = rect
	parent.add_child(col)


func _build_forge_visual() -> void:
	var bg := ColorRect.new()
	bg.position = forge_center - forge_size * 0.5
	bg.size     = forge_size
	bg.color    = C_FORGE_BG
	add_child(bg)

	var fire := ColorRect.new()
	fire.position = forge_center + Vector2(-28, 16)
	fire.size     = Vector2(56, 56)
	fire.color    = C_FORGE_FRE
	add_child(fire)

	_zone_label("Lò Rèn", forge_center + Vector2(-30, -80), C_LABEL_FRG)


func _build_bed_visual() -> void:
	var bg := ColorRect.new()
	bg.position = bed_center - bed_size * 0.5
	bg.size     = bed_size
	bg.color    = C_BED_BG
	add_child(bg)

	_zone_label("Nghỉ Ngơi", bed_center + Vector2(-42, -80), C_LABEL_BED)


func _build_door_visual(is_left: bool) -> void:
	var x := 0.0 if is_left else float(TILE * (cols - 1))
	var dr := ColorRect.new()
	dr.position = Vector2(x, door_center_y - door_half_h)
	dr.size     = Vector2(TILE, door_half_h * 2)
	dr.color    = C_DOOR
	add_child(dr)

	var caption := "Khám Phá" if is_left else "Tiệm"
	var lbl := Label.new()
	lbl.text                = caption
	lbl.position            = Vector2(x + 4, door_center_y - 12)
	lbl.size                = Vector2(TILE - 8, 24)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.70))
	add_child(lbl)


func _zone_label(text: String, pos: Vector2, col: Color) -> void:
	var lbl := Label.new()
	lbl.text     = text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", col)
	add_child(lbl)


# ══════════════════════════════════════════════════════════════════════════════
# BUILD — player
# ══════════════════════════════════════════════════════════════════════════════

func _build_player() -> void:
	var scr: GDScript = load("res://scripts/shop/player_shop.gd")
	_player          = scr.new() as CharacterBody2D
	_player.position = Vector2(TILE * cols * 0.5, TILE * rows * 0.5)
	add_child(_player)


# ══════════════════════════════════════════════════════════════════════════════
# BUILD — interactive zones (Area2D)
# ══════════════════════════════════════════════════════════════════════════════

func _build_zones() -> void:
	_make_zone(ZONE_FORGE, forge_center, forge_size)
	_make_zone(ZONE_BED,   bed_center,   bed_size)
	_make_zone(ZONE_EXIT,  exit_center,  exit_size)
	_make_zone(ZONE_SHOP,  shop_center,  shop_size)


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


# ══════════════════════════════════════════════════════════════════════════════
# BUILD — HUD
# ══════════════════════════════════════════════════════════════════════════════

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)

	var vp := get_viewport_rect().size

	# Top bar
	var bar := ColorRect.new()
	bar.position = Vector2.ZERO
	bar.size     = Vector2(vp.x, 44)
	bar.color    = C_HUD_BAR
	hud.add_child(bar)

	_lbl_day     = _hud_label(hud, Vector2(12,  10))
	_lbl_phase   = _hud_label(hud, Vector2(220, 10))
	_lbl_stamina = _hud_label(hud, Vector2(450, 10))
	_lbl_gold    = _hud_label(hud, Vector2(680, 10))

	# Hint phía dưới màn hình
	_hint_lbl = Label.new()
	_hint_lbl.position              = Vector2(0, vp.y - 44)
	_hint_lbl.size                  = Vector2(vp.x, 36)
	_hint_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override("font_size", 20)
	_hint_lbl.add_theme_color_override("font_color", C_HINT)
	_hint_lbl.visible = false
	hud.add_child(_hint_lbl)


func _hud_label(parent: Node, pos: Vector2) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size     = Vector2(220, 24)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", C_HUD_TEXT)
	parent.add_child(lbl)
	return lbl


func _refresh_hud() -> void:
	_lbl_day.text     = "Ngày %d" % GameManager.current_day
	_lbl_phase.text   = _phase_name(GameManager.current_phase)
	_lbl_stamina.text = "Thể lực  %d / %d" % [
		GameManager.travel_stamina,
		GameManager.max_travel_stamina,
	]
	_lbl_gold.text    = "Vàng  %d G" % GameManager.gold


func _phase_name(p: GameManager.GamePhase) -> String:
	match p:
		GameManager.GamePhase.MORNING:   return "Buổi Sáng"
		GameManager.GamePhase.NOON:      return "Buổi Trưa"
		GameManager.GamePhase.AFTERNOON: return "Buổi Chiều"
		GameManager.GamePhase.NIGHT:     return "Buổi Đêm"
		_:                               return ""


# ══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ══════════════════════════════════════════════════════════════════════════════

func _connect_signals() -> void:
	GameManager.gold_changed.connect(func(_a: int) -> void: _refresh_hud())
	GameManager.travel_stamina_changed.connect(func(_c: int, _m: int) -> void: _refresh_hud())
	GameManager.phase_changed.connect(func(_p: GameManager.GamePhase) -> void: _refresh_hud())
	GameManager.day_changed.connect(func(_d: int) -> void: _refresh_hud())
	EventBus.shop_closed.connect(_on_shop_closed_for_summary)


# ══════════════════════════════════════════════════════════════════════════════
# ZONE CALLBACKS
# ══════════════════════════════════════════════════════════════════════════════

func _on_zone_entered(body: Node2D, zone_id: String) -> void:
	if body != _player:
		return
	_near_zone        = zone_id
	_hint_lbl.text    = "[E]   " + _hint_text(zone_id)
	_hint_lbl.visible = true


func _on_zone_exited(body: Node2D, zone_id: String) -> void:
	if body != _player or _near_zone != zone_id:
		return
	_near_zone        = ""
	_hint_lbl.visible = false


func _hint_text(zone_id: String) -> String:
	match zone_id:
		ZONE_FORGE: return "Vào lò rèn"
		ZONE_BED:   return "Nghỉ ngơi — kết thúc ngày"
		ZONE_EXIT:  return "Đi khám phá vùng đất"
		ZONE_SHOP:  return "Mở cửa tiệm"
		_:          return ""


# ══════════════════════════════════════════════════════════════════════════════
# ZONE ACTIONS
# ══════════════════════════════════════════════════════════════════════════════

func _activate_zone(zone_id: String) -> void:
	match zone_id:
		ZONE_FORGE: _go_forge()
		ZONE_BED:   _go_sleep()
		ZONE_EXIT:  _go_explore()
		ZONE_SHOP:  _go_shop()


func _go_forge() -> void:
	GameManager.change_phase(GameManager.GamePhase.NOON)
	SceneManager.go_to(PATH_FORGE)


func _go_shop() -> void:
	GameManager.change_phase(GameManager.GamePhase.AFTERNOON)
	EventBus.shop_opened.emit()
	SceneManager.go_to(PATH_SHOP)


func _go_explore() -> void:
	if GameManager.travel_stamina <= 0:
		_hint_lbl.text = "Hết thể lực — hãy nghỉ ngơi trước!"
		return
	GameManager.change_phase(GameManager.GamePhase.MORNING)
	_open_region_select()


func _go_sleep() -> void:
	_open_day_summary()


func _on_shop_closed_for_summary(stats: Dictionary) -> void:
	GameManager.pending_day_summary_stats = {}
	_open_day_summary(stats)


# ══════════════════════════════════════════════════════════════════════════════
# OVERLAYS — lazy-load, implement đầy đủ ở bước sau
# ══════════════════════════════════════════════════════════════════════════════

func _open_region_select() -> void:
	if _region_select == null:
		var scr: GDScript = load("res://scripts/ui/region_select_ui.gd")
		_region_select = scr.new() as CanvasLayer
		(_region_select as RegionSelectUI).region_chosen.connect(_on_region_chosen)
		add_child(_region_select)
	_region_select.visible = true


func _on_region_chosen(region_id: String) -> void:
	GameManager.current_region_id = region_id
	SceneManager.go_to("res://scenes/regions/ExplorationScene.tscn")


func _open_day_summary(stats: Dictionary = {}) -> void:
	if _day_summary == null:
		var scr: GDScript = load("res://scripts/ui/day_summary_ui.gd")
		_day_summary = scr.new() as CanvasLayer
		add_child(_day_summary)
	(_day_summary as DaySummaryUI).show_summary(stats)
