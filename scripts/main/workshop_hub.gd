# gdlint: disable=max-file-lines
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
const PATH_DEBT_NOTICE := "res://scenes/ui/DebtNoticeUI.tscn"
const PATH_DEBT_PAYMENT := "res://scenes/ui/DebtPaymentUI.tscn"
const PATH_INVENTORY := "res://scenes/ui/InventoryUI.tscn"
const PATH_PAUSE_MENU := "res://scenes/ui/PauseMenu.tscn"
const PATH_GAME_OVER := "res://scenes/ui/GameOver.tscn"
const DAY_SCENE_CARD_SCRIPT := "res://scripts/ui/day_scene_card_ui.gd"
const TUTORIAL_OVERLAY_SCRIPT := "res://scripts/ui/tutorial_overlay_ui.gd"
const FORGE_RECIPE_BOOK_SCRIPT := "res://scripts/ui/forge_recipe_book_ui.gd"
const DEBT_C1_ID := "c1_mat_bang"
const DEBT_C2_ID := "c2_dan_duong"
const DEBT_C3_ID := "c3_thue_lon"
const DEBT_C4_ID := "c4_no_goc"

# Zone IDs
const ZONE_FORGE := "forge"
const ZONE_BED   := "bed"
const ZONE_EXIT  := "exit"
const ZONE_SHOP  := "shop"
const ZONE_FORGE_BOOK := "forge_book"
const ZONE_DEBT_AGENT := "debt_agent"
const ZONE_DEBT_AGENT_C2 := "debt_agent_c2"
const ZONE_DEBT_AGENT_C3 := "debt_agent_c3"
const ZONE_DEBT_AGENT_C4 := "debt_agent_c4"

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
var forge_book_center: Vector2
var forge_book_size: Vector2

# ══════════════════════════════════════════════════════════════════════════════
# STATE
# ══════════════════════════════════════════════════════════════════════════════

var tutorial_step: int = 0

var _player:    CharacterBody2D
var _near_zone: String = ""

var _region_select: CanvasLayer   # lazy-load
var _day_summary:   CanvasLayer   # lazy-load
var _debt_notice:   DebtNoticeUI   # lazy-load
var _debt_payment:  DebtPaymentUI  # lazy-load
var _inventory_ui:  InventoryUI    # lazy-load
var _combat_loadout: CombatLoadoutUI # lazy-load
var _pause_menu: Node = null
var _game_over_ui: Node = null
var _day_card_overlay: DaySceneCardUI = null
var _debt_agent_marker: Node2D = null
var _debt_agent_c2: Node2D = null
var _debt_agent_c3: Node2D = null
var _debt_agent_c4: Node2D = null
var _tutorial_overlay: TutorialOverlayUI = null
var _forge_recipe_book_ui: ForgeRecipeBookUI = null
var _sticky_hint_zone: String = ""
var _sticky_hint_text: String = ""
var _last_debt_check_day: int = 0
var _tutorial_locked_zones: Dictionary = {}
var _tutorial_noon_timer: SceneTreeTimer = null
var _tutorial_noon_remaining: int = 60
var _tutorial_advance_btn: Button = null
var _arrow_node: Node2D = null
var _arrow_tween: Tween = null

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
	exit_center   = Vector2(TILE * 1.5,         door_center_y)
	exit_size     = Vector2(float(TILE),         door_half_h * 2.0)
	shop_center   = Vector2(vp.x - TILE * 1.5,  door_center_y)
	shop_size     = Vector2(float(TILE),         door_half_h * 2.0)
	forge_book_center = forge_center + Vector2(TILE * 3.1, TILE * 0.2)
	forge_book_size = Vector2(TILE * 1.4, TILE * 1.0)


func _ready() -> void:
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
	add_child(preload("res://scenes/ui/HUD.tscn").instantiate())
	_connect_signals()
	_ensure_game_over_ui()
	_sync_debt_agent_scene()
	if not GameManager.pending_day_summary_stats.is_empty():
		var stats := GameManager.pending_day_summary_stats.duplicate()
		GameManager.pending_day_summary_stats = {}
		if GameManager.current_day == 0 and not GameManager.has_tutorial_seen("explore_phase_seen"):
			_show_tutorial(GuideBook.get_explore_steps(), "explore_phase_seen")
			_tutorial_overlay.completed.connect(func() -> void: _open_day_summary(stats), CONNECT_ONE_SHOT)
		else:
			_open_day_summary(stats)
	_sync_debt_overlays()
	if not _show_day_start_card_if_needed():
		_sync_tutorial_script()
	_sync_day1_scripted_tutorial()


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
	_build_forge_book_visual()
	_build_bed_visual()
	_build_door_visual(true)    # trái — WorldExit
	_build_door_visual(false)   # phải — ShopDoor


func _build_wall_collision() -> void:
	var sb := StaticBody2D.new()
	sb.collision_layer = 4
	sb.collision_mask  = 0
	add_child(sb)

	var rw     := float(TILE)
	var full_w := float(TILE * cols)
	var full_h := float(TILE * rows)

	# tường trên + dưới (full width)
	_wall_seg(sb, Vector2(0, 0),           Vector2(full_w, rw))
	_wall_seg(sb, Vector2(0, full_h - rw), Vector2(full_w, rw))

	# tường trái — lấp đầy (zone exit phát hiện khi player áp sát từ bên trong)
	_wall_seg(sb, Vector2(0, rw), Vector2(rw, full_h - rw * 2))

	# tường phải — lấp đầy
	_wall_seg(sb, Vector2(full_w - rw, rw), Vector2(rw, full_h - rw * 2))


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


func _build_forge_book_visual() -> void:
	var book := ColorRect.new()
	book.position = forge_book_center - forge_book_size * 0.5
	book.size = forge_book_size
	book.color = Color(0.34, 0.18, 0.07)
	add_child(book)

	_zone_label("Bí Kíp Rèn", forge_book_center + Vector2(-42, -52), C_LABEL_FRG)


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
	_player.set("move_speed", PLAYER_MOVE_SPEED)
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


# ══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ══════════════════════════════════════════════════════════════════════════════

func _connect_signals() -> void:
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.day_changed.connect(_on_day_changed)
	EventBus.shop_closed.connect(_on_shop_closed_for_summary)
	EventBus.guide_book_opened.connect(_open_guide_book)
	EventBus.forge_book_opened.connect(_open_forge_recipe_book)
	EventBus.weapon_forged.connect(_on_tutorial_weapon_forged)


func _on_phase_changed(_phase: GameManager.GamePhase) -> void:
	_sync_debt_agent_scene()
	_sync_debt_payment()
	_sync_day1_scripted_tutorial()


func _on_day_changed(_day: int) -> void:
	if _day != 0:
		_clear_sticky_hint()
	_sync_debt_agent_scene()
	_sync_day1_scripted_tutorial()


# ══════════════════════════════════════════════════════════════════════════════
# ZONE CALLBACKS
# ══════════════════════════════════════════════════════════════════════════════

func _on_zone_entered(body: Node2D, zone_id: String) -> void:
	if body != _player:
		return
	_near_zone        = zone_id
	if _sticky_hint_zone != "" and zone_id != _sticky_hint_zone:
		return
	_request_hint("[E]   " + _hint_text(zone_id))


func _on_zone_exited(body: Node2D, zone_id: String) -> void:
	if body != _player or _near_zone != zone_id:
		return
	_near_zone        = ""
	if _sticky_hint_zone != "":
		_restore_sticky_hint()
		return
	_clear_hint()


func _hint_text(zone_id: String) -> String:
	var hints := {
		ZONE_FORGE: "Vào lò rèn",
		ZONE_BED: "Nghỉ ngơi — kết thúc ngày",
		ZONE_EXIT: "Đi khám phá vùng đất",
		ZONE_SHOP: "Mở cửa tiệm",
		ZONE_FORGE_BOOK: "Mở Bí Kíp Rèn",
		ZONE_DEBT_AGENT: "Nói chuyện với Người Thu Nợ",
		ZONE_DEBT_AGENT_C2: "Nói chuyện với Tay Sai Rừng",
		ZONE_DEBT_AGENT_C3: "Nói chuyện với Thương Nhân Sa Mạc",
		ZONE_DEBT_AGENT_C4: "Nói chuyện với Bà Trùm Hắc Nguyệt",
	}
	return String(hints.get(zone_id, ""))


# ══════════════════════════════════════════════════════════════════════════════
# ZONE ACTIONS
# ══════════════════════════════════════════════════════════════════════════════

func _activate_zone(zone_id: String) -> void:
	if _tutorial_overlay != null and _tutorial_overlay.visible:
		return
	if _is_tutorial_zone_locked(zone_id):
		_request_hint("Chưa tới lúc.")
		return
	if not _tutorial_allows_zone(zone_id):
		return
	if zone_id == _sticky_hint_zone:
		_clear_sticky_hint()
	match zone_id:
		ZONE_FORGE: _go_forge()
		ZONE_BED:   _go_sleep()
		ZONE_EXIT:  _go_explore()
		ZONE_SHOP:  _go_shop()
		ZONE_FORGE_BOOK: EventBus.forge_book_opened.emit()
		ZONE_DEBT_AGENT: _talk_to_debt_agent()
		ZONE_DEBT_AGENT_C2: _talk_to_c2_agent()
		ZONE_DEBT_AGENT_C3: _talk_to_c3_agent()
		ZONE_DEBT_AGENT_C4: _talk_to_c4_agent()


func _go_forge() -> void:
	if _should_show_tutorial_before_forge():
		_show_tutorial(GuideBook.get_day0_forge_steps(), "day0_forge_phase_seen")
		_tutorial_overlay.completed.connect(_go_forge, CONNECT_ONE_SHOT)
		return
	if GameManager.current_phase == GameManager.GamePhase.MORNING:
		_advance_phase_from(GameManager.GamePhase.MORNING)
	SceneManager.go_to(PATH_FORGE)


func _go_shop() -> void:
	if _is_day1_tutorial_active() and tutorial_step < 3:
		_request_hint("Chiều mới mở cửa bán hàng.")
		return
	if _should_show_c1_debt_agent():
		_show_c1_debt_notice()
		return
	if _should_show_tutorial_before_shop():
		_show_tutorial(GuideBook.get_day0_shop_phase_steps(), "day0_shop_phase_seen")
		_tutorial_overlay.completed.connect(_go_shop, CONNECT_ONE_SHOT)
		return
	if GameManager.current_day <= 1 and InventorySystem.get_weapons().is_empty():
		_request_hint("Hãy bày vũ khí lên kệ trước khi mở cửa tiệm!")
		return
	# Đảm bảo mở shop luôn bước vào buổi chiều, kể cả khi bỏ qua rèn.
	if GameManager.current_phase == GameManager.GamePhase.MORNING:
		DayCycle.advance_phase()
	if GameManager.current_phase == GameManager.GamePhase.NOON:
		DayCycle.advance_phase()
	EventBus.shop_opened.emit()
	SceneManager.go_to(PATH_SHOP)


func _talk_to_debt_agent() -> void:
	if not _should_show_c1_debt_agent():
		return
	var c1 := DebtSystem.get_checkpoint(DEBT_C1_ID)
	if c1 == null:
		return
	if GameManager.has_tutorial_seen("ntn_day1_dialogue_seen"):
		_open_debt_notice(c1)
		return
	_ensure_tutorial_overlay()
	_tutorial_overlay.show_steps(GuideBook.get_ntn_day1_dialogue())
	GameManager.mark_tutorial_seen("ntn_day1_dialogue_seen")
	_tutorial_overlay.completed.connect(func() -> void: _open_debt_notice(c1), CONNECT_ONE_SHOT)


func _talk_to_c2_agent() -> void:
	if _is_demo_runtime():
		return
	var c2 := DebtSystem.get_checkpoint(DEBT_C2_ID)
	if c2 == null or c2.is_paid or GameManager.current_day < c2.trigger_day:
		return
	if GameManager.has_tutorial_seen("tay_sai_rung_dialogue_seen"):
		_open_debt_notice(c2)
		return
	_ensure_tutorial_overlay()
	_tutorial_overlay.show_steps(GuideBook.get_tay_sai_rung_dialogue())
	GameManager.mark_tutorial_seen("tay_sai_rung_dialogue_seen")
	_tutorial_overlay.completed.connect(func() -> void: _open_debt_notice(c2), CONNECT_ONE_SHOT)


func _talk_to_c3_agent() -> void:
	if _is_demo_runtime():
		return
	var c3 := DebtSystem.get_checkpoint(DEBT_C3_ID)
	if c3 == null or c3.is_paid or GameManager.current_day < c3.trigger_day:
		return
	if GameManager.has_tutorial_seen("thuong_nhan_dialogue_seen"):
		_open_debt_notice(c3)
		return
	_ensure_tutorial_overlay()
	_tutorial_overlay.show_steps(GuideBook.get_thuong_nhan_dialogue())
	GameManager.mark_tutorial_seen("thuong_nhan_dialogue_seen")
	_tutorial_overlay.completed.connect(func() -> void: _open_debt_notice(c3), CONNECT_ONE_SHOT)


func _talk_to_c4_agent() -> void:
	if _is_demo_runtime():
		return
	var c4 := DebtSystem.get_checkpoint(DEBT_C4_ID)
	if c4 == null or c4.is_paid or GameManager.current_day < c4.trigger_day:
		return
	if GameManager.has_tutorial_seen("ba_trum_c4_dialogue_seen"):
		_open_debt_notice(c4)
		return
	_ensure_tutorial_overlay()
	_tutorial_overlay.show_steps(GuideBook.get_ba_trum_c4_dialogue())
	GameManager.mark_tutorial_seen("ba_trum_c4_dialogue_seen")
	_tutorial_overlay.completed.connect(func() -> void: _open_debt_notice(c4), CONNECT_ONE_SHOT)


func _go_explore() -> void:
	if GameManager.travel_stamina <= 0:
		_request_hint("Hết thể lực — hãy nghỉ ngơi trước!")
		return
	if _should_show_tutorial_before_explore():
		_show_tutorial(GuideBook.get_explore_steps(), "explore_phase_seen")
		_tutorial_overlay.completed.connect(_go_explore, CONNECT_ONE_SHOT)
		return
	_open_region_select()


func _go_sleep() -> void:
	if GameManager.current_phase != GameManager.GamePhase.NIGHT:
		if GameManager.current_day < 2:
			_request_hint("Chưa đến giờ nghỉ — hãy hoàn thành công việc trong ngày!")
			return
		_force_advance_to_night()
	if GameManager.current_day == 0 and not GameManager.has_tutorial_seen("explore_phase_seen"):
		_show_tutorial(GuideBook.get_explore_steps(), "explore_phase_seen")
		_tutorial_overlay.completed.connect(_go_sleep, CONNECT_ONE_SHOT)
		return
	_open_day_summary()


func _force_advance_to_night() -> void:
	# Skip thẳng tới NIGHT mà không trigger side effect của các phase trung gian.
	GameManager.current_phase = GameManager.GamePhase.NIGHT
	GameManager.phase_changed.emit(GameManager.GamePhase.NIGHT)


func _on_shop_closed_for_summary(stats: Dictionary) -> void:
	GameManager.pending_day_summary_stats = {}
	_open_day_summary(stats)
	_sync_debt_payment()


func _advance_phase_from(expected_phase: GameManager.GamePhase) -> void:
	if GameManager.current_phase != expected_phase:
		push_warning("Không advance phase: current_phase không khớp flow mong đợi")
		return
	DayCycle.advance_phase()


# ══════════════════════════════════════════════════════════════════════════════
# OVERLAYS — lazy-load
# ══════════════════════════════════════════════════════════════════════════════

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
	_sync_tutorial_script()


func _sync_tutorial_script() -> void:
	if GameManager.current_day == 0:
		_sync_day0_tutorial()
	elif GameManager.current_day == 2:
		_sync_day2_tutorial()
	elif GameManager.current_day == 3:
		_sync_day3_tutorial()
	elif GameManager.current_day == 4:
		_sync_day4_tutorial()


func _sync_day1_scripted_tutorial() -> void:
	if not _is_day1_tutorial_active():
		_set_tutorial_step(4)
		return
	if GameManager.current_phase == GameManager.GamePhase.AFTERNOON:
		_set_tutorial_step(3)
	elif GameManager.has_tutorial_seen("debt_notice_shown"):
		_set_tutorial_step(2)
	elif GameManager.has_tutorial_seen("day1_forge_done"):
		_set_tutorial_step(1)
	else:
		_set_tutorial_step(0)


func _is_day1_tutorial_active() -> bool:
	return (
		GameManager.current_day == 1
		and GameManager.has_tutorial_seen("opening_seen")
	)


func _set_tutorial_step(step: int) -> void:
	if not _is_day1_tutorial_active() and step < 4:
		step = 4
	if tutorial_step == step and step != 1:
		return
	tutorial_step = step
	EventBus.tutorial_step_changed.emit(tutorial_step)
	_hide_tutorial_advance_button()

	match tutorial_step:
		0:
			_set_tutorial_locks([ZONE_BED, ZONE_EXIT, ZONE_SHOP, ZONE_FORGE_BOOK])
			_request_hint("Đến lò rèn và rèn vũ khí đầu tiên của ngươi.")
			_show_tutorial_arrow(forge_center, "Lò Rèn")
		1:
			_set_tutorial_locks([ZONE_BED, ZONE_EXIT, ZONE_SHOP, ZONE_FORGE_BOOK])
			_request_hint("Người Thu Nợ đang chờ ở cửa tiệm.")
			_show_tutorial_arrow(shop_center + Vector2(-TILE * 1.5, 0.0), "Người Thu Nợ")
			_sync_debt_agent_scene()
			_show_day1_debt_notice()
		2:
			_set_tutorial_locks([ZONE_EXIT, ZONE_SHOP])
			_request_hint("Buổi trưa: Rèn thêm hoặc chờ đến chiều.")
			_hide_tutorial_arrow()
			_show_tutorial_advance_button()
			_start_tutorial_noon_timer()
		3:
			_set_tutorial_locks([ZONE_EXIT, ZONE_BED])
			_request_hint("Đặt vũ khí lên kệ trước khi mở cửa!")
			_show_tutorial_arrow(shop_center, "Mở Tiệm")
		_:
			_set_tutorial_locks([])
			_clear_hint()
			_hide_tutorial_arrow()


func _set_tutorial_locks(zone_ids: Array) -> void:
	_tutorial_locked_zones.clear()
	for zone_id: String in zone_ids:
		_tutorial_locked_zones[zone_id] = true
	_apply_interactable_locks()


func _apply_interactable_locks() -> void:
	for node in get_tree().get_nodes_in_group("interactable"):
		if not node.has_method("set_locked"):
			continue
		var zone_id := String(node.get_meta("zone_id", ""))
		node.set_locked(_tutorial_locked_zones.has(zone_id))


func _is_tutorial_zone_locked(zone_id: String) -> bool:
	return _tutorial_locked_zones.has(zone_id)


func _on_tutorial_weapon_forged(_weapon_data) -> void:
	if _is_day1_tutorial_active() and tutorial_step == 0:
		_set_tutorial_step(1)


func _show_day1_debt_notice() -> void:
	if GameManager.has_tutorial_seen("debt_notice_shown"):
		return
	var c1 := DebtSystem.get_checkpoint(DEBT_C1_ID)
	if c1 == null:
		return
	_open_debt_notice(c1)


func _on_day1_debt_notice_closed() -> void:
	GameManager.mark_tutorial("debt_notice_shown")
	_set_tutorial_step(2)


func _show_tutorial_advance_button() -> void:
	if _tutorial_advance_btn == null:
		_tutorial_advance_btn = Button.new()
		_tutorial_advance_btn.position = Vector2(get_viewport_rect().size.x - 220, 92)
		_tutorial_advance_btn.size = Vector2(220, 48)
		_tutorial_advance_btn.add_theme_font_size_override("font_size", 20)
		_tutorial_advance_btn.pressed.connect(_advance_day1_to_afternoon)
		add_child(_tutorial_advance_btn)
	_update_noon_btn_text()
	_tutorial_advance_btn.visible = true


func _update_noon_btn_text() -> void:
	if _tutorial_advance_btn == null:
		return
	_tutorial_advance_btn.text = "Sang chiều (%ds)" % _tutorial_noon_remaining


func _hide_tutorial_advance_button() -> void:
	if _tutorial_advance_btn != null:
		_tutorial_advance_btn.visible = false


func _zone_center(zone_id: String) -> Vector2:
	match zone_id:
		ZONE_FORGE:      return forge_center
		ZONE_BED:        return bed_center
		ZONE_EXIT:       return exit_center
		ZONE_SHOP:       return shop_center
		ZONE_FORGE_BOOK: return forge_book_center
	return Vector2.ZERO


func _show_tutorial_arrow(world_pos: Vector2, hint_text: String) -> void:
	if _arrow_node == null:
		_arrow_node = Node2D.new()
		_arrow_node.z_index = 50
		var lbl := Label.new()
		lbl.name = "ArrowLabel"
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.15))
		lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		lbl.add_theme_constant_override("shadow_offset_x", 2)
		lbl.add_theme_constant_override("shadow_offset_y", 2)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(240, 0)
		lbl.position = Vector2(-120.0, 0.0)
		_arrow_node.add_child(lbl)
		add_child(_arrow_node)

	(_arrow_node.get_node("ArrowLabel") as Label).text = "▼  " + hint_text
	_arrow_node.position = world_pos + Vector2(0.0, -float(TILE) - 20.0)
	_arrow_node.visible = true

	if _arrow_tween != null:
		_arrow_tween.kill()
	_arrow_tween = create_tween()
	_arrow_tween.set_loops()
	_arrow_tween.tween_property(
		_arrow_node, "position:y",
		world_pos.y - float(TILE) - 6.0, 0.45
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_arrow_tween.tween_property(
		_arrow_node, "position:y",
		world_pos.y - float(TILE) - 26.0, 0.45
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _hide_tutorial_arrow() -> void:
	if _arrow_tween != null:
		_arrow_tween.kill()
		_arrow_tween = null
	if _arrow_node != null:
		_arrow_node.visible = false


func _start_tutorial_noon_timer() -> void:
	if _tutorial_noon_timer != null:
		return
	_tutorial_noon_remaining = 60
	_tick_tutorial_noon_timer()


func _tick_tutorial_noon_timer() -> void:
	_tutorial_noon_timer = get_tree().create_timer(1.0)
	await _tutorial_noon_timer.timeout
	_tutorial_noon_timer = null
	if not (_is_day1_tutorial_active() and tutorial_step == 2):
		return
	_tutorial_noon_remaining -= 1
	_update_noon_btn_text()
	if _tutorial_noon_remaining <= 0:
		_advance_day1_to_afternoon()
	else:
		_tick_tutorial_noon_timer()


func _advance_day1_to_afternoon() -> void:
	if GameManager.current_phase != GameManager.GamePhase.NOON:
		return
	_tutorial_noon_remaining = 0
	_tutorial_noon_timer = null
	DayCycle.advance_phase()


func _sync_day0_tutorial() -> void:
	if GameManager.current_phase == GameManager.GamePhase.MORNING \
			and not GameManager.has_tutorial_seen("ba_trum_intro_seen"):
		_show_tutorial(GuideBook.get_ba_trum_intro_steps(), "ba_trum_intro_seen")
		_tutorial_overlay.completed.connect(_sync_day0_tutorial, CONNECT_ONE_SHOT)
		return
	if GameManager.current_phase == GameManager.GamePhase.MORNING \
			and GameManager.has_tutorial_seen("ba_trum_intro_seen") \
			and not GameManager.has_tutorial_seen("day0_intro_seen"):
		_show_tutorial(GuideBook.get_day0_intro_steps(), "day0_intro_seen")
	elif _is_day0_forge_required():
		_set_sticky_hint(ZONE_FORGE, "→ Quay lại Lò Rèn để hoàn thành vũ khí")
	elif GameManager.current_phase == GameManager.GamePhase.NOON \
			and GameManager.has_tutorial_seen("day0_forge_done") \
			and not GameManager.has_tutorial_seen("first_forge_complete_seen"):
		_show_tutorial(GuideBook.get_first_forge_complete_steps(), "first_forge_complete_seen")
		_tutorial_overlay.completed.connect(_sync_day0_tutorial, CONNECT_ONE_SHOT)
	elif GameManager.current_phase == GameManager.GamePhase.NOON \
			and GameManager.has_tutorial_seen("day0_forge_done") \
			and not GameManager.has_tutorial_seen("day0_shop_hint_seen"):
		_show_tutorial(GuideBook.get_day0_shop_hint_steps(), "day0_shop_hint_seen")

func _sync_day2_tutorial() -> void:
	if GameManager.current_phase != GameManager.GamePhase.MORNING:
		return
	if GameManager.has_tutorial_seen("day2_freeplay_seen"):
		return
	_show_tutorial(GuideBook.get_day2_intro_steps(), "day2_freeplay_seen")


func _sync_day3_tutorial() -> void:
	if GameManager.current_phase != GameManager.GamePhase.MORNING:
		return
	if GameManager.has_tutorial_seen("day3_co_long_gio_seen"):
		return
	var has_met := GameManager.has_tutorial_seen("co_long_gio_met")
	_show_tutorial(GuideBook.get_day3_intro_steps(has_met), "day3_co_long_gio_seen")


func _sync_day4_tutorial() -> void:
	if GameManager.current_phase != GameManager.GamePhase.MORNING:
		return
	if GameManager.has_tutorial_seen("day4_deadline_seen"):
		return
	_show_tutorial(GuideBook.get_day4_intro_steps(), "day4_deadline_seen")


func _show_tutorial(steps: Array[Dictionary], flag: String) -> void:
	_ensure_tutorial_overlay()
	_tutorial_overlay.show_steps(steps)
	if flag == "day0_intro_seen":
		_tutorial_overlay.completed.connect(
			func() -> void: _set_sticky_hint(ZONE_FORGE, "→ Lò Rèn đang chờ bạn"),
			CONNECT_ONE_SHOT
		)
	elif flag == "day0_shop_hint_seen":
		_tutorial_overlay.completed.connect(
			func() -> void: _set_sticky_hint(ZONE_SHOP, "→ Mang vũ khí vào Tiệm để bán"),
			CONNECT_ONE_SHOT
		)
	GameManager.mark_tutorial_seen(flag)


func _ensure_tutorial_overlay() -> void:
	if _tutorial_overlay != null:
		return
	var script: GDScript = load(TUTORIAL_OVERLAY_SCRIPT)
	_tutorial_overlay = script.new() as TutorialOverlayUI
	add_child(_tutorial_overlay)


func _open_guide_book() -> void:
	_ensure_tutorial_overlay()
	_tutorial_overlay.show_sections(GuideBook.get_sections())


func _request_hint(text: String) -> void:
	EventBus.hint_requested.emit(text)


func _clear_hint() -> void:
	EventBus.hint_requested.emit("")


func _set_sticky_hint(zone_id: String, text: String) -> void:
	_sticky_hint_zone = zone_id
	_sticky_hint_text = text
	_request_hint(text)
	var pos := _zone_center(zone_id)
	if pos != Vector2.ZERO:
		_show_tutorial_arrow(pos, text.trim_prefix("→ ").strip_edges())


func _clear_sticky_hint() -> void:
	_sticky_hint_zone = ""
	_sticky_hint_text = ""
	_clear_hint()
	_hide_tutorial_arrow()


func _restore_sticky_hint() -> void:
	_request_hint(_sticky_hint_text)


func _should_show_tutorial_before_forge() -> bool:
	return GameManager.current_day == 0 \
		and not GameManager.has_tutorial_seen("day0_forge_phase_seen")


func _should_show_tutorial_before_shop() -> bool:
	return GameManager.current_day == 0 \
		and not GameManager.has_tutorial_seen("day0_shop_phase_seen")


func _is_day0_forge_required() -> bool:
	return GameManager.current_day == 0 \
		and GameManager.current_phase == GameManager.GamePhase.NOON \
		and not GameManager.has_tutorial_seen("day0_forge_done")


func _should_show_tutorial_before_explore() -> bool:
	return GameManager.current_day >= 1 \
		and not GameManager.has_tutorial_seen("explore_phase_seen")


func _tutorial_allows_zone(zone_id: String) -> bool:
	if GameManager.current_day != 0:
		return true
	var allowed := true
	if GameManager.current_phase == GameManager.GamePhase.MORNING:
		allowed = zone_id in [ZONE_FORGE, ZONE_FORGE_BOOK]
		if not allowed:
			_request_hint("Tutorial ngày 0: hãy vào Lò Rèn trước.")
	elif GameManager.current_phase == GameManager.GamePhase.NOON:
		if not GameManager.has_tutorial_seen("day0_forge_done"):
			allowed = zone_id in [ZONE_FORGE, ZONE_FORGE_BOOK]
			if not allowed:
				_request_hint("Tutorial: quay lại Lò Rèn và lưu vũ khí vào túi trước.")
		elif not GameManager.has_tutorial_seen("day0_customer_done"):
			allowed = zone_id in [ZONE_SHOP, ZONE_FORGE, ZONE_FORGE_BOOK]
			if not allowed:
				_request_hint("Tutorial: hãy mở tiệm và bán vũ khí trước khi làm việc khác.")
	return allowed


func _open_inventory() -> void:
	if GameManager.current_phase == GameManager.GamePhase.NIGHT:
		_request_hint("Không mở kho lúc nghỉ đêm.")
		return
	if _inventory_ui == null:
		var scene := load(PATH_INVENTORY) as PackedScene
		_inventory_ui = scene.instantiate() as InventoryUI
		add_child(_inventory_ui)
	_inventory_ui.show_inventory()


func _sync_debt_overlays() -> void:
	_sync_debt_agent_scene()
	if GameManager.current_phase == GameManager.GamePhase.MORNING:
		if _should_show_c1_debt_agent():
			return
		if _last_debt_check_day != GameManager.current_day:
			_last_debt_check_day = GameManager.current_day
			DebtSystem.check_day(GameManager.current_day)
	_sync_debt_payment()


func _sync_debt_payment() -> void:
	if GameManager.current_phase != GameManager.GamePhase.NIGHT:
		return
	var debt_id := _get_payable_debt_id()
	if debt_id == "":
		return
	_open_debt_payment(debt_id)


func _ensure_debt_notice() -> void:
	if _debt_notice != null:
		return
	var scene := load(PATH_DEBT_NOTICE) as PackedScene
	_debt_notice = scene.instantiate() as DebtNoticeUI
	add_child(_debt_notice)


func _show_c1_debt_notice() -> void:
	_talk_to_debt_agent()


func _open_debt_notice(checkpoint: DebtCheckpoint) -> void:
	checkpoint.has_notified = true
	_ensure_debt_notice()
	_debt_notice.show_checkpoint(checkpoint)
	if _is_day1_tutorial_active() and tutorial_step == 1:
		if not _debt_notice.notice_closed.is_connected(_on_day1_debt_notice_closed):
			_debt_notice.notice_closed.connect(_on_day1_debt_notice_closed, CONNECT_ONE_SHOT)
	if GameManager.has_tutorial_seen("day1_loop_seen"):
		return
	if not _debt_notice.notice_closed.is_connected(_on_ntn_notice_closed):
		_debt_notice.notice_closed.connect(_on_ntn_notice_closed, CONNECT_ONE_SHOT)


func _on_ntn_notice_closed() -> void:
	if not GameManager.has_tutorial_seen("day1_loop_seen"):
		_show_tutorial(GuideBook.get_day1_post_ntn_steps(), "day1_loop_seen")


func _open_debt_payment(checkpoint_id: String = DEBT_C1_ID) -> void:
	if _debt_payment == null:
		var scene := load(PATH_DEBT_PAYMENT) as PackedScene
		_debt_payment = scene.instantiate() as DebtPaymentUI
		add_child(_debt_payment)
	_debt_payment.show_payment(checkpoint_id)


func _sync_debt_agent_scene() -> void:
	_ensure_debt_agent_marker()


func _should_show_c1_debt_agent() -> bool:
	var checkpoint := DebtSystem.get_checkpoint(DEBT_C1_ID)
	if checkpoint == null:
		return false
	return (
		not checkpoint.is_paid
		and GameManager.current_day == checkpoint.trigger_day
		and GameManager.current_phase in [GameManager.GamePhase.MORNING, GameManager.GamePhase.NOON]
	)


func _ensure_debt_agent_marker() -> void:
	var show_c1 := _should_show_c1_debt_agent()
	if show_c1 and _debt_agent_marker == null:
		var agent: DebtAgentNode = DebtAgentNode.new()
		agent.name = "NguoiThuNoC1"
		agent.position = shop_center + Vector2(-TILE * 1.5, 0)
		agent.z_index = 30
		agent.player_entered.connect(_on_debt_agent_entered.bind(ZONE_DEBT_AGENT))
		agent.player_exited.connect(_on_debt_agent_exited.bind(ZONE_DEBT_AGENT))
		add_child(agent)
		_debt_agent_marker = agent
	if not show_c1:
		_clear_debt_agent_marker()
	if _is_demo_runtime():
		_clear_debt_agent_c2()
		_clear_debt_agent_c3()
		_clear_debt_agent_c4()
		return

	var c2 := DebtSystem.get_checkpoint(DEBT_C2_ID)
	if c2 != null:
		if c2.is_paid:
			_clear_debt_agent_c2()
		elif GameManager.current_day >= c2.trigger_day and _debt_agent_c2 == null:
			var c2_agent: DebtAgentNode = DebtAgentNode.new()
			c2_agent.name = "TaySaiRungC2"
			c2_agent.display_name = "Tay Sai Rừng"
			c2_agent.position = Vector2(cols * TILE / 2.0, 8.0 * TILE)
			c2_agent.z_index = 30
			c2_agent.player_entered.connect(_on_debt_agent_c2_entered)
			c2_agent.player_exited.connect(_on_debt_agent_c2_exited)
			add_child(c2_agent)
			_debt_agent_c2 = c2_agent

	var c3 := DebtSystem.get_checkpoint(DEBT_C3_ID)
	if c3 != null:
		if c3.is_paid:
			_clear_debt_agent_c3()
		elif GameManager.current_day >= c3.trigger_day and _debt_agent_c3 == null:
			var c3_agent: DebtAgentNode = DebtAgentNode.new()
			c3_agent.name = "ThuongNhanC3"
			c3_agent.display_name = "Thương Nhân Sa Mạc"
			c3_agent.position = Vector2(cols * TILE / 2.0, 12.0 * TILE)
			c3_agent.z_index = 30
			c3_agent.player_entered.connect(_on_debt_agent_entered.bind(ZONE_DEBT_AGENT_C3))
			c3_agent.player_exited.connect(_on_debt_agent_exited.bind(ZONE_DEBT_AGENT_C3))
			add_child(c3_agent)
			_debt_agent_c3 = c3_agent

	var c4 := DebtSystem.get_checkpoint(DEBT_C4_ID)
	if c4 != null:
		if c4.is_paid:
			_clear_debt_agent_c4()
		elif GameManager.current_day >= c4.trigger_day and _debt_agent_c4 == null:
			var c4_agent: DebtAgentNode = DebtAgentNode.new()
			c4_agent.name = "BaTrumHacNguyetC4"
			c4_agent.display_name = "Bà Trùm Hắc Nguyệt"
			c4_agent.position = Vector2(cols * TILE / 2.0, 16.0 * TILE)
			c4_agent.z_index = 30
			c4_agent.player_entered.connect(_on_debt_agent_entered.bind(ZONE_DEBT_AGENT_C4))
			c4_agent.player_exited.connect(_on_debt_agent_exited.bind(ZONE_DEBT_AGENT_C4))
			add_child(c4_agent)
			_debt_agent_c4 = c4_agent


func _clear_debt_agent_marker() -> void:
	if _debt_agent_marker == null:
		return
	if _near_zone == ZONE_DEBT_AGENT:
		_near_zone = ""
		_clear_hint()
	_debt_agent_marker.queue_free()
	_debt_agent_marker = null


func _clear_debt_agent_c2() -> void:
	if _debt_agent_c2 == null:
		return
	if _near_zone == ZONE_DEBT_AGENT_C2:
		_near_zone = ""
		_clear_hint()
	_debt_agent_c2.queue_free()
	_debt_agent_c2 = null


func _clear_debt_agent_c3() -> void:
	if _debt_agent_c3 == null:
		return
	if _near_zone == ZONE_DEBT_AGENT_C3:
		_near_zone = ""
		_clear_hint()
	_debt_agent_c3.queue_free()
	_debt_agent_c3 = null


func _clear_debt_agent_c4() -> void:
	if _debt_agent_c4 == null:
		return
	if _near_zone == ZONE_DEBT_AGENT_C4:
		_near_zone = ""
		_clear_hint()
	_debt_agent_c4.queue_free()
	_debt_agent_c4 = null


func _on_debt_agent_entered(zone_id: String) -> void:
	_near_zone = zone_id
	_request_hint("[E]   " + _hint_text(zone_id))


func _on_debt_agent_exited(zone_id: String) -> void:
	if _near_zone != zone_id:
		return
	_near_zone = ""
	_clear_hint()


func _on_debt_agent_c2_entered() -> void:
	_on_debt_agent_entered(ZONE_DEBT_AGENT_C2)


func _on_debt_agent_c2_exited() -> void:
	_on_debt_agent_exited(ZONE_DEBT_AGENT_C2)


func _get_payable_debt_id() -> String:
	var day := GameManager.current_day
	for checkpoint in DebtSystem.checkpoints:
		if checkpoint.is_paid:
			continue
		if checkpoint.trigger_day > day:
			continue
		if _is_demo_runtime() and checkpoint.id != DEBT_C1_ID:
			continue
		return checkpoint.id
	return ""


func _is_demo_runtime() -> bool:
	return GameManager.current_day <= GameManager.DEMO_LAST_DAY


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
	_last_debt_check_day = 0
	_sync_debt_overlays()
