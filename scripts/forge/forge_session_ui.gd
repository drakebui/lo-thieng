# gdlint: disable=max-file-lines
# Forge Session — kết hợp 3 phase rèn thành một luồng hoàn chỉnh
# Nung → Rèn Búa → Tôi Luyện bằng linh lực đã chọn → Weapon Card
extends Control

enum Phase { P1, P2, P3_ANIM, RESULT }

const _FORGE1_SCRIPT := preload("res://scripts/forge/forge_system.gd")
const _FORGE2_SCRIPT := preload("res://scripts/forge/forge_phase2.gd")
const _FORGE3_SCRIPT := preload("res://scripts/forge/forge_phase3.gd")
const _HEAT_BAR_SCRIPT := preload("res://scripts/forge/heat_bar.gd")
const _BEAT_BAR_SCRIPT := preload("res://scripts/forge/beat_bar.gd")
const _STAGE_SCRIPT := preload("res://scripts/forge/forge_visual_stage.gd")
const _CARD_SCENE    := preload("res://scenes/ui/WeaponCardUI.tscn")
const _PHASE_INDICATOR_SCRIPT := preload("res://scripts/forge/forge_phase_indicator.gd")
const _PHASE_INDICATOR_SCENE := preload("res://scenes/forge/ForgePhaseIndicator.tscn")

const PATH_ELEMENT_PICKER := "res://scenes/forge/ElementPicker.tscn"
const PATH_WEAPON_BUILDER := "res://scenes/forge/WeaponBuilder.tscn"
const PATH_WORKSHOP := "res://scenes/main/WorkshopHub.tscn"
const BACKGROUND_PIXEL_PATH := "res://assets/pixel/backgrounds/forge_hearth_bg_640x360.png"
const BACKGROUND_FALLBACK_PATH := "res://assets/sprites/forge/backgrounds/Forge Scene BG.PNG"

const COLOR_PERFECT := Color(0.98, 0.86, 0.20)
const COLOR_GOOD    := Color(0.92, 0.56, 0.14)
const COLOR_MISS    := Color(0.82, 0.24, 0.18)

const PHASE2_PREFIX_NAMES := {
	"phan_chu":   "Phản Chủ",  "curse_nang": "Lời Nguyền",
	"curse_nhe":  "Nguyền Nhẹ","thuong":     "Thường",
	"tot":        "Tốt",       "kiet_tac":   "Kiệt Tác",
	"to_nghe":    "Tổ Nghề",   "khi_phach":  "Khí Phách",
	"perfect":    "PERFECT",
}

const PHASE1_TIER_NAMES := {
	"lanh": "Lạnh", "cam": "Cam", "do_ruc": "Đỏ Rực", "chay": "Cháy Thép",
}

# ─── State ────────────────────────────────────────────────────────────────────

var _current_phase := Phase.P1
var _p1_tier:   String = ""
var _p2_prefix: String = ""
var _bar_width: float = 1120.0
var _bar_height: float = 104.0
var _stage_height: float = 240.0
var _heat_tick_timer: float = 0.0

# ─── Logic nodes ──────────────────────────────────────────────────────────────

var _forge1: Node
var _forge2: Node
var _forge3: Node

# ─── Phase containers ─────────────────────────────────────────────────────────

var _p1_root:      Control
var _p2_root:      Control
var _p3_anim_root: Control
var _result_root:  Control

# ─── Phase indicator ──────────────────────────────────────────────────────────

var _phase_indicator

# ─── Phase 1 widgets ──────────────────────────────────────────────────────────

var _p1_active_box:     VBoxContainer  # ẩn khi phase 1 xong
var _p1_stage:          ForgeVisualStage
var _p1_heat_bar:       HeatBar
var _p1_cook_bar:       ProgressBar
var _p1_cook_label:     Label
var _p1_heat_label:     Label
var _p1_zone_label:     Label
var _p1_instruct:       Label
var _p1_result_box:     VBoxContainer
var _p1_result_label:   Label
var _p1_mult_label:     Label
var _p1_result_tween:   Tween

# Labels của heat bar — resize theo rarity
var _p1_lbl_lanh:   Label
var _p1_lbl_cam:    Label
var _p1_lbl_do_ruc: Label
var _p1_lbl_chay:   Label
var _p1_lbl_eff_lanh:   Label
var _p1_lbl_eff_cam:    Label
var _p1_lbl_eff_do_ruc: Label
var _p1_lbl_eff_chay:   Label
var _p1_tip_label:  Label
var _p1_label_pulse: float = 0.0

# ─── Phase 2 widgets ──────────────────────────────────────────────────────────

var _p2_stage:          ForgeVisualStage
var _p2_beat_bar:       BeatBar
var _p2_strike_badges:  Array[PanelContainer] = []
var _p2_strike_label:   Label
var _p2_score_label:    Label
var _p2_feedback_label: Label
var _p2_feedback_tween: Tween

# ─── Phase 3 widgets ──────────────────────────────────────────────────────────

var _p3_anim_bg:        ColorRect
var _p3_flash_rect:     ColorRect
var _p3_stage:          ForgeVisualStage
var _p3_anim_label:     Label
var _p3_instruct:       Label
var _p3_perfect_banner: PanelContainer
var _p3_tween:          Tween
var _p3_quench_pressed: bool = false
var _p3_is_perfect:     bool = false

# ─── Result ───────────────────────────────────────────────────────────────────

var _weapon_card:  Control
var _save_btn:     Button
var _forge_result: Dictionary = {}
var _global_back_btn: Button
var _phase1_tooltip: PanelContainer
var _phase2_tooltip: PanelContainer


# ══════════════════════════════════════════════════════════════════════════════
# READY
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vp := get_viewport_rect().size
	_bar_width = clampf(vp.x * 0.68, 860.0, 1280.0)
	_bar_height = clampf(vp.y * 0.10, 84.0, 114.0)
	_stage_height = clampf(vp.y * 0.225, 230.0, 250.0)

	var forge_book := get_node_or_null("ForgeBookUI")
	if forge_book:
		forge_book.queue_free()

	var bg := TextureRect.new()
	var bg_tex: Texture2D = null
	if ResourceLoader.exists(BACKGROUND_PIXEL_PATH):
		bg_tex = load(BACKGROUND_PIXEL_PATH) as Texture2D
	if bg_tex == null and ResourceLoader.exists(BACKGROUND_FALLBACK_PATH):
		bg_tex = load(BACKGROUND_FALLBACK_PATH) as Texture2D
	bg.texture = bg_tex
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Lớp phủ tối nhẹ để nền lò 32-bit nổi bật ấm áp mà thanh rèn vẫn rõ chữ
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.04, 0.02, 0.01, 0.18)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	_forge1 = _FORGE1_SCRIPT.new(); add_child(_forge1)
	_forge2 = _FORGE2_SCRIPT.new(); add_child(_forge2)
	_forge3 = _FORGE3_SCRIPT.new(); add_child(_forge3)

	_forge2.beat_started.connect(_on_beat_started)
	_forge2.strike_resolved.connect(_on_strike_resolved)

	EventBus.phase1_completed.connect(_on_phase1_done)
	EventBus.phase2_completed.connect(_on_phase2_done)

	_build_indicator()
	_p1_root      = _build_phase1_ui()
	_p2_root      = _build_phase2_ui()
	_p3_anim_root = _build_phase3_anim_ui()
	_result_root  = _build_result_ui()

	add_child(_p1_root)
	add_child(_p2_root)
	add_child(_p3_anim_root)
	add_child(_result_root)
	_phase1_tooltip = _build_phase_tooltip(
		"Phase1Tooltip",
		"PHASE 1 — NUNG THÉP",
		"Nhấp nhả [Space] theo nhịp giữ nhiệt trong vùng Cam (+20%) hoặc Đỏ Rực (+40%) cho đến khi Chín Thép (100%). Tránh để quá nhiệt Cháy Thép!",
		_on_phase1_tooltip_confirmed
	)
	_phase2_tooltip = _build_phase_tooltip(
		"Phase2Tooltip",
		"PHASE 2 — RÈN BÚA",
		"Nhấn [Space] khi kim chạm vùng PERFECT (vàng kim). "
			+ "Combo liên tiếp kích hoạt BÚA VÀNG tăng hào quang và tia lửa!",
		_on_phase2_tooltip_confirmed
	)
	add_child(_phase1_tooltip)
	add_child(_phase2_tooltip)
	_global_back_btn = _build_global_back_button()
	add_child(_global_back_btn)

	_go_to_phase1()


func _exit_tree() -> void:
	AudioManager.stop_sfx_loop()


# ══════════════════════════════════════════════════════════════════════════════
# PHASE INDICATOR
# ══════════════════════════════════════════════════════════════════════════════

func _build_global_back_button() -> Button:
	var back_btn := Button.new()
	back_btn.text = "[ Quay lại chọn linh lực  (Esc) ]"
	back_btn.add_theme_font_size_override("font_size", 28)
	back_btn.position = Vector2(32, 28)
	back_btn.size = Vector2(380, 52)
	back_btn.pressed.connect(_go_to_element_picker)
	return back_btn


func _build_indicator() -> void:
	_phase_indicator = get_node_or_null("ForgePhaseIndicator")
	if _phase_indicator == null:
		_phase_indicator = _PHASE_INDICATOR_SCENE.instantiate()
		add_child(_phase_indicator)
	_phase_indicator.set_phase(_PHASE_INDICATOR_SCRIPT.Phase.CHON_PHOI)
	_move_indicator_to_front()


func _update_indicator(active: int) -> void:
	if _phase_indicator == null:
		return
	_phase_indicator.set_phase(active)
	_move_indicator_to_front()


func _move_indicator_to_front() -> void:
	if _phase_indicator:
		move_child(_phase_indicator, get_child_count() - 1)


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 1 — NUNG THÉP
# ══════════════════════════════════════════════════════════════════════════════

func _build_phase1_ui() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 86

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "NUNG THÉP — Phase 1"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var info_row := HBoxContainer.new()
	info_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(info_row)

	var blank_label := Label.new()
	blank_label.text = GameManager.selected_blank.get("name", "Phôi")
	blank_label.add_theme_font_size_override("font_size", 32)
	blank_label.add_theme_color_override("font_color", Color(0.90, 0.78, 0.45))
	blank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_row.add_child(blank_label)

	var plus_label := Label.new()
	plus_label.text = "  +  "
	plus_label.add_theme_font_size_override("font_size", 32)
	plus_label.add_theme_color_override("font_color", Color(0.90, 0.78, 0.45))
	plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_row.add_child(plus_label)

	var rarity: int = GameManager.selected_material.get("rarity", 1)
	var material_label := Label.new()
	material_label.text = "%s  %s" % [
		GameManager.selected_material.get("name", "Nguyên liệu"),
		"★".repeat(rarity),
	]
	material_label.add_theme_font_size_override("font_size", 32)
	material_label.add_theme_color_override("font_color", Color(0.90, 0.78, 0.45))
	material_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_row.add_child(material_label)

	# Gom toàn bộ UI active — ẩn khi phase xong để nhường chỗ cho result
	_p1_active_box = VBoxContainer.new()
	_p1_active_box.add_theme_constant_override("separation", 12)
	vbox.add_child(_p1_active_box)

	_p1_stage = _STAGE_SCRIPT.new()
	_p1_stage.custom_minimum_size = Vector2(_bar_width, _stage_height)
	_p1_stage.set_mode(_STAGE_SCRIPT.Mode.MODE_HEAT)
	_p1_active_box.add_child(_p1_stage)

	_p1_active_box.add_child(_build_heat_bar())
	_p1_active_box.add_child(_build_cook_progress_bar())

	_p1_heat_label = Label.new()
	_p1_heat_label.text = "Nhiệt độ: 0 / 100"
	_p1_heat_label.add_theme_font_size_override("font_size", 46)
	_p1_heat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_active_box.add_child(_p1_heat_label)

	_p1_zone_label = Label.new()
	_p1_zone_label.text = "Sẵn sàng..."
	_p1_zone_label.add_theme_font_size_override("font_size", 40)
	_p1_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_active_box.add_child(_p1_zone_label)

	_p1_tip_label = Label.new()
	_p1_tip_label.text = (
		"Cam = an toàn (+20%)  •  Đỏ Rực = mạo hiểm (+40%)  •  "
		+ "Cháy Thép = hỏng (−50%)"
	)
	_p1_tip_label.add_theme_font_size_override("font_size", 26)
	_p1_tip_label.add_theme_color_override("font_color", Color(0.76, 0.70, 0.56))
	_p1_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_active_box.add_child(_p1_tip_label)

	_p1_instruct = Label.new()
	_p1_instruct.text = "Nhấp nhả [SPACE] theo nhịp giữ nhiệt trong vùng Cam / Đỏ Rực (chín 100%)"
	_p1_instruct.add_theme_font_size_override("font_size", 32)
	_p1_instruct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_active_box.add_child(_p1_instruct)

	_p1_result_box = VBoxContainer.new()
	_p1_result_box.visible = false
	_p1_result_box.add_theme_constant_override("separation", 28)
	vbox.add_child(_p1_result_box)
	_p1_result_box.add_child(HSeparator.new())

	_p1_result_label = Label.new()
	_p1_result_label.add_theme_font_size_override("font_size", 64)
	_p1_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_result_box.add_child(_p1_result_label)

	_p1_mult_label = Label.new()
	_p1_mult_label.add_theme_font_size_override("font_size", 44)
	_p1_mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_result_box.add_child(_p1_mult_label)

	var next := Button.new()
	next.text = "[ Tiếp tục Rèn Búa  → ]"
	next.add_theme_font_size_override("font_size", 38)
	next.pressed.connect(_go_to_phase2)
	_p1_result_box.add_child(next)

	return root


func _build_cook_progress_bar() -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_p1_cook_label = Label.new()
	_p1_cook_label.text = "Tiến độ chín thép: 0%"
	_p1_cook_label.add_theme_font_size_override("font_size", 28)
	_p1_cook_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
	row.add_child(_p1_cook_label)
	wrapper.add_child(row)

	_p1_cook_bar = ProgressBar.new()
	_p1_cook_bar.custom_minimum_size = Vector2(_bar_width, 22.0)
	_p1_cook_bar.show_percentage = false
	_p1_cook_bar.min_value = 0.0
	_p1_cook_bar.max_value = 100.0
	_p1_cook_bar.value = 0.0

	var bg_box := StyleBoxFlat.new()
	bg_box.bg_color = Color(0.08, 0.05, 0.04, 0.95)
	bg_box.border_color = Color(0.38, 0.26, 0.14)
	bg_box.set_border_width_all(2)
	bg_box.set_corner_radius_all(5)
	_p1_cook_bar.add_theme_stylebox_override("background", bg_box)

	var fill_box := StyleBoxFlat.new()
	fill_box.bg_color = Color(0.96, 0.62, 0.14)
	fill_box.border_color = Color(1.0, 0.88, 0.35)
	fill_box.set_border_width_all(1)
	fill_box.set_corner_radius_all(5)
	_p1_cook_bar.add_theme_stylebox_override("fill", fill_box)

	wrapper.add_child(_p1_cook_bar)
	return wrapper


func _build_heat_bar() -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)

	_p1_heat_bar = _HEAT_BAR_SCRIPT.new()
	_p1_heat_bar.custom_minimum_size = Vector2(_bar_width, _bar_height)
	wrapper.add_child(_p1_heat_bar)

	var row := HBoxContainer.new()

	_p1_lbl_lanh = Label.new()
	_p1_lbl_lanh.text = "Lạnh  (<60)"
	_p1_lbl_lanh.add_theme_font_size_override("font_size", 28)
	_p1_lbl_lanh.add_theme_color_override("font_color", Color(0.6, 0.72, 0.95))
	_p1_lbl_lanh.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_p1_lbl_lanh.custom_minimum_size.x = _bar_width * 0.6
	row.add_child(_p1_lbl_lanh)

	_p1_lbl_cam = Label.new()
	_p1_lbl_cam.text = "Cam"
	_p1_lbl_cam.add_theme_font_size_override("font_size", 28)
	_p1_lbl_cam.add_theme_color_override("font_color", Color(0.95, 0.62, 0.18))
	_p1_lbl_cam.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_lbl_cam.custom_minimum_size.x = _bar_width * 0.2
	row.add_child(_p1_lbl_cam)

	_p1_lbl_do_ruc = Label.new()
	_p1_lbl_do_ruc.text = "Đỏ Rực"
	_p1_lbl_do_ruc.add_theme_font_size_override("font_size", 26)
	_p1_lbl_do_ruc.add_theme_color_override("font_color", Color(1.0, 0.45, 0.05))
	_p1_lbl_do_ruc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_lbl_do_ruc.custom_minimum_size.x = _bar_width * 0.12
	row.add_child(_p1_lbl_do_ruc)

	_p1_lbl_chay = Label.new()
	_p1_lbl_chay.text = "Cháy"
	_p1_lbl_chay.add_theme_font_size_override("font_size", 26)
	_p1_lbl_chay.add_theme_color_override("font_color", Color(0.75, 0.32, 0.16))
	_p1_lbl_chay.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_p1_lbl_chay.custom_minimum_size.x = _bar_width * 0.08
	row.add_child(_p1_lbl_chay)

	wrapper.add_child(row)

	# Hàng effect: luôn hiển thị multiplier của từng zone
	var eff_row := HBoxContainer.new()

	_p1_lbl_eff_lanh = Label.new()
	_p1_lbl_eff_lanh.text = "−30%"
	_p1_lbl_eff_lanh.add_theme_font_size_override("font_size", 24)
	_p1_lbl_eff_lanh.add_theme_color_override("font_color", Color(0.6, 0.72, 0.95))
	eff_row.add_child(_p1_lbl_eff_lanh)

	_p1_lbl_eff_cam = Label.new()
	_p1_lbl_eff_cam.text = "+20%"
	_p1_lbl_eff_cam.add_theme_font_size_override("font_size", 24)
	_p1_lbl_eff_cam.add_theme_color_override("font_color", Color(0.95, 0.62, 0.18))
	_p1_lbl_eff_cam.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eff_row.add_child(_p1_lbl_eff_cam)

	_p1_lbl_eff_do_ruc = Label.new()
	_p1_lbl_eff_do_ruc.text = "+40% ★"
	_p1_lbl_eff_do_ruc.add_theme_font_size_override("font_size", 24)
	_p1_lbl_eff_do_ruc.add_theme_color_override("font_color", Color(1.0, 0.45, 0.05))
	_p1_lbl_eff_do_ruc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eff_row.add_child(_p1_lbl_eff_do_ruc)

	_p1_lbl_eff_chay = Label.new()
	_p1_lbl_eff_chay.text = "−50%"
	_p1_lbl_eff_chay.add_theme_font_size_override("font_size", 24)
	_p1_lbl_eff_chay.add_theme_color_override("font_color", Color(0.75, 0.32, 0.16))
	_p1_lbl_eff_chay.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	eff_row.add_child(_p1_lbl_eff_chay)

	wrapper.add_child(eff_row)
	return wrapper


func _load_selected_weapon_texture() -> Texture2D:
	var sprite_path := String(GameManager.selected_blank.get("sprite_path", ""))
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		return load(sprite_path) as Texture2D
	return null


func _go_to_phase1() -> void:
	AudioManager.stop_sfx_loop()
	if _p1_result_tween != null:
		_p1_result_tween.kill()
		_p1_result_tween = null
	_current_phase = Phase.P1
	_heat_tick_timer = 0.0
	_update_indicator(_PHASE_INDICATOR_SCRIPT.Phase.NUNG_THEP)
	_p1_root.visible      = true
	_p2_root.visible      = false
	_p3_anim_root.visible = false
	_result_root.visible  = false
	if _global_back_btn:
		_global_back_btn.visible = true
	_p1_active_box.visible = true
	_p1_result_box.visible = false
	_p1_result_box.modulate = Color.WHITE
	_p1_result_box.scale = Vector2.ONE
	if _p1_cook_bar != null:
		_p1_cook_bar.value = 0.0
	if _p1_cook_label != null:
		_p1_cook_label.text = "Tiến độ chín thép: 0%"
	if _p1_stage != null:
		_p1_stage.set_mode(_STAGE_SCRIPT.Mode.MODE_HEAT)
		_p1_stage.set_weapon_texture(_load_selected_weapon_texture())
	_p1_zone_label.text    = "Sẵn sàng..."
	_p1_zone_label.add_theme_color_override("font_color", Color.WHITE)
	var rarity: int = GameManager.selected_material.get("rarity", 1)
	_p1_instruct.text = "Nhấp nhả [SPACE] giữ nhiệt trong vùng Cam / Đỏ Rực     %s" \
		% _rarity_label(rarity)
	if not GameManager.has_tutorial_seen("forge_phase1_shown"):
		_phase1_tooltip.visible = true
		return
	_start_phase1_logic()


func _start_phase1_logic() -> void:
	var rarity: int = GameManager.selected_material.get("rarity", 1)
	var validation_error := ForgeValidator.validate(
		GameManager.selected_blank,
		GameManager.selected_material,
		InventorySystem.materials
	)
	if validation_error != "":
		_p1_zone_label.text = validation_error
		_p1_zone_label.add_theme_color_override("font_color", COLOR_MISS)
		push_warning("[ForgeValidator] " + validation_error)
		return
	_forge1.start_phase(0, rarity)
	_update_heat_zones()


func _update_heat_zones() -> void:
	var low_frac: float  = _forge1.SWEET_SPOT_LOW  / 100.0
	var peak_frac: float = _forge1.SWEET_SPOT_PEAK / 100.0
	var burn_frac: float = _forge1.burn_point      / 100.0

	_p1_heat_bar.set_thresholds(low_frac, peak_frac, burn_frac)

	_p1_lbl_lanh.custom_minimum_size.x   = _bar_width * low_frac
	_p1_lbl_cam.custom_minimum_size.x    = _bar_width * (peak_frac - low_frac)
	_p1_lbl_do_ruc.custom_minimum_size.x = _bar_width * (burn_frac - peak_frac)
	_p1_lbl_chay.custom_minimum_size.x   = _bar_width * (1.0 - burn_frac)
	_p1_lbl_do_ruc.text = "Đỏ Rực (%d%%)" % int((burn_frac - peak_frac) * 100.0)
	_p1_lbl_chay.text   = "Cháy (%d%%)" % int((1.0 - burn_frac) * 100.0)

	_p1_lbl_eff_lanh.custom_minimum_size.x   = _bar_width * low_frac
	_p1_lbl_eff_cam.custom_minimum_size.x    = _bar_width * (peak_frac - low_frac)
	_p1_lbl_eff_do_ruc.custom_minimum_size.x = _bar_width * (burn_frac - peak_frac)
	_p1_lbl_eff_chay.custom_minimum_size.x   = _bar_width * (1.0 - burn_frac)


func _on_phase1_done(tier: String) -> void:
	if _current_phase != Phase.P1:
		return
	AudioManager.stop_sfx_loop()
	# Nguyên liệu có thể override tier tối thiểu
	var p1_min := GameManager.selected_material.get("phase1_min", "") as String
	if p1_min == "do_ruc":
		tier = "do_ruc"
	elif p1_min == "cam" and tier == "lanh":
		tier = "cam"
	_p1_tier = tier
	match tier:
		"cam", "do_ruc":
			AudioManager.play_sfx_key("skill_fire")
		"chay":
			AudioManager.play_sfx_key("player_hurt")
	_p1_active_box.visible = false
	_p1_result_box.visible = true

	var mult:     float = _forge1.get_multiplier(tier)
	var pct:      int   = int(abs(mult - 1.0) * 100)
	var sign_str: String = "+" if mult >= 1.0 else "-"
	var tier_name: String = PHASE1_TIER_NAMES.get(tier, tier)

	_p1_result_label.text = "Kết quả: %s" % tier_name
	_p1_mult_label.text   = "Nhân stats: ×%.1f  (%s%d%%)" % [mult, sign_str, pct]

	var tier_color := Color.WHITE
	match tier:
		"lanh":   tier_color = Color(0.6, 0.72, 0.95)
		"cam":    tier_color = Color(0.95, 0.62, 0.18)
		"do_ruc": tier_color = Color(1.0, 0.45, 0.05)
		"chay":   tier_color = Color(0.55, 0.25, 0.10)
	_p1_result_label.add_theme_color_override("font_color", tier_color)

	# Hiệu ứng xuất hiện mượt (fade + scale nhẹ) cho bảng kết quả Phase 1
	_p1_result_box.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_p1_result_box.scale = Vector2(0.92, 0.92)
	_p1_result_box.pivot_offset = _p1_result_box.size * 0.5
	if _p1_result_tween != null:
		_p1_result_tween.kill()
	_p1_result_tween = create_tween().set_parallel(true)
	_p1_result_tween.tween_property(_p1_result_box, "modulate:a", 1.0, 0.28) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_p1_result_tween.tween_property(_p1_result_box, "scale", Vector2.ONE, 0.30) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 2 — RÈN BÚA
# ══════════════════════════════════════════════════════════════════════════════

func _build_phase2_ui() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 86

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "RÈN BÚA — Phase 2"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var info_row := HBoxContainer.new()
	info_row.alignment = BoxContainer.ALIGNMENT_CENTER
	info_row.add_theme_constant_override("separation", 64)
	vbox.add_child(info_row)

	_p2_strike_label = Label.new()
	_p2_strike_label.text = "Nhát  1 / 5"
	_p2_strike_label.add_theme_font_size_override("font_size", 40)
	info_row.add_child(_p2_strike_label)

	_p2_score_label = Label.new()
	_p2_score_label.text = "Điểm:  0"
	_p2_score_label.add_theme_font_size_override("font_size", 40)
	info_row.add_child(_p2_score_label)

	var diff_lbl := Label.new()
	diff_lbl.name = "DiffLabel"
	diff_lbl.add_theme_font_size_override("font_size", 32)
	diff_lbl.add_theme_color_override("font_color", Color(0.84, 0.68, 0.42))
	info_row.add_child(diff_lbl)

	# Hàng 5 huy hiệu tiến độ nhát búa (chờ / ★ PERFECT / ◆ GOOD / ✕ MISS)
	vbox.add_child(_build_strike_badges_row())

	_p2_stage = _STAGE_SCRIPT.new()
	_p2_stage.custom_minimum_size = Vector2(_bar_width, _stage_height)
	_p2_stage.set_mode(_STAGE_SCRIPT.Mode.MODE_ANVIL)
	vbox.add_child(_p2_stage)

	vbox.add_child(_build_beat_bar())

	_p2_feedback_label = Label.new()
	_p2_feedback_label.text = ""
	_p2_feedback_label.add_theme_font_size_override("font_size", 56)
	_p2_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p2_feedback_label.custom_minimum_size.y = 64
	vbox.add_child(_p2_feedback_label)

	var instruct := Label.new()
	instruct.text = "Nhấn [SPACE] hoặc [ENTER] khi kim chạm vùng vàng kim"
	instruct.add_theme_font_size_override("font_size", 32)
	instruct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instruct)

	return root


func _build_strike_badges_row() -> HBoxContainer:
	_p2_strike_badges.clear()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	for i in 5:
		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(72, 50)
		badge.add_theme_stylebox_override(
			"panel", _make_badge_style(Color(0.12, 0.08, 0.05, 0.9), Color(0.42, 0.30, 0.16))
		)
		var lbl := Label.new()
		lbl.name = "BadgeLabel"
		lbl.text = str(i + 1)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 26)
		lbl.add_theme_color_override("font_color", Color(0.70, 0.62, 0.50))
		badge.add_child(lbl)
		row.add_child(badge)
		_p2_strike_badges.append(badge)
	return row


func _make_badge_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	return s


func _reset_strike_badges() -> void:
	for i in _p2_strike_badges.size():
		var badge := _p2_strike_badges[i]
		badge.scale = Vector2.ONE
		badge.add_theme_stylebox_override(
			"panel", _make_badge_style(Color(0.12, 0.08, 0.05, 0.9), Color(0.42, 0.30, 0.16))
		)
		var lbl := badge.get_node("BadgeLabel") as Label
		lbl.text = str(i + 1)
		lbl.add_theme_color_override("font_color", Color(0.70, 0.62, 0.50))


func _update_strike_badge(idx: int, result: int) -> void:
	if idx < 0 or idx >= _p2_strike_badges.size():
		return
	var badge := _p2_strike_badges[idx]
	var lbl := badge.get_node("BadgeLabel") as Label
	match result:
		_forge2.HitResult.PERFECT:
			badge.add_theme_stylebox_override(
				"panel", _make_badge_style(Color(0.32, 0.25, 0.04, 0.96), COLOR_PERFECT)
			)
			lbl.text = "★"
			lbl.add_theme_color_override("font_color", COLOR_PERFECT)
		_forge2.HitResult.GOOD:
			badge.add_theme_stylebox_override(
				"panel", _make_badge_style(Color(0.28, 0.14, 0.04, 0.96), COLOR_GOOD)
			)
			lbl.text = "◆"
			lbl.add_theme_color_override("font_color", COLOR_GOOD)
		_:
			badge.add_theme_stylebox_override(
				"panel", _make_badge_style(Color(0.26, 0.07, 0.06, 0.96), COLOR_MISS)
			)
			lbl.text = "✕"
			lbl.add_theme_color_override("font_color", COLOR_MISS)


func _build_beat_bar() -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)

	_p2_beat_bar = _BEAT_BAR_SCRIPT.new()
	_p2_beat_bar.custom_minimum_size = Vector2(_bar_width, _bar_height)
	wrapper.add_child(_p2_beat_bar)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var lbl := Label.new()
	lbl.text = "◆ GOOD (cam)   •   ★ PERFECT (vàng kim)"
	lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.34))
	lbl.add_theme_font_size_override("font_size", 24)
	row.add_child(lbl)
	wrapper.add_child(row)
	return wrapper


func _go_to_phase2() -> void:
	AudioManager.stop_sfx_loop()
	if _p2_feedback_tween != null:
		_p2_feedback_tween.kill()
		_p2_feedback_tween = null
	_current_phase = Phase.P2
	_update_indicator(_PHASE_INDICATOR_SCRIPT.Phase.REN_BUA)
	_p1_root.visible      = false
	_p2_root.visible      = true
	_p3_anim_root.visible = false
	_result_root.visible  = false
	if _global_back_btn:
		_global_back_btn.visible = true
	if _p2_stage != null:
		_p2_stage.set_mode(_STAGE_SCRIPT.Mode.MODE_ANVIL)
		_p2_stage.set_weapon_texture(_load_selected_weapon_texture())
		_p2_stage.set_beat_state(0.0, 0.55, 0, _forge2.TOTAL_STRIKES)
	_p2_score_label.text    = "Điểm:  0"
	_p2_strike_label.text   = "Nhát  1 / 5"
	_p2_feedback_label.text = ""
	_p2_feedback_label.scale = Vector2.ONE
	_reset_strike_badges()
	if not GameManager.has_tutorial_seen("forge_phase2_shown"):
		_phase2_tooltip.visible = true
		return
	_start_phase2_logic()


func _start_phase2_logic() -> void:
	var rarity: int = GameManager.selected_material.get("rarity", 1)
	var window_scale: float
	var beat_dur: float
	match rarity:
		1: window_scale = 1.00; beat_dur = 1.50   # Phổ thông — tiêu chuẩn
		2: window_scale = 0.70; beat_dur = 1.15   # Hiếm — hitbox nhỏ hơn, nhanh hơn
		3: window_scale = 0.45; beat_dur = 0.85   # Cực hiếm — rất nhỏ, rất nhanh
		_: window_scale = 1.00; beat_dur = 1.50

	# Truyền bonus của Phase 1 vào window_scale của Phase 2
	var p1_bonus: float = 0.0
	if _forge1.has_method("get_perfect_bonus_for_phase2"):
		p1_bonus = _forge1.get_perfect_bonus_for_phase2(_p1_tier)
	elif _p1_tier == "do_ruc":
		p1_bonus = 0.15
	elif _p1_tier == "lanh" or _p1_tier == "chay":
		p1_bonus = -0.15
	window_scale = maxf(0.20, window_scale + p1_bonus)

	var diff_lbl := _p2_root.find_child("DiffLabel") as Label
	if diff_lbl:
		var max_stars := {1: "★★☆☆☆", 2: "★★★☆☆", 3: "★★★★★"}
		var bonus_str := ""
		if p1_bonus > 0.0:
			bonus_str = " | ★ Thép Đỏ Rực (+15% Vùng Đánh)"
		elif p1_bonus < 0.0:
			bonus_str = " | ⚠ Thép Phạt (−15% Vùng Đánh)"
		diff_lbl.text = "%s  |  Tối đa Prefix: %s%s" % [
			_rarity_label(rarity),
			max_stars.get(rarity, "★★★★★"),
			bonus_str,
		]
	_forge2.start_phase(window_scale, beat_dur, rarity)


func _build_phase_tooltip(
	node_name: String,
	title_text: String,
	body_text: String,
	confirmed_callback: Callable
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.visible = false
	panel.custom_minimum_size = Vector2(430, 190)
	panel.position = Vector2(get_viewport_rect().size.x - 480, 130)
	panel.add_theme_stylebox_override("panel", _make_tooltip_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.28))
	vbox.add_child(title)

	var body := Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72))
	vbox.add_child(body)

	var button := Button.new()
	button.text = "Đã hiểu"
	button.custom_minimum_size = Vector2(120, 40)
	button.pressed.connect(confirmed_callback)
	vbox.add_child(button)
	return panel


func _make_tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.035, 0.018, 0.96)
	style.border_color = Color(0.72, 0.54, 0.24)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style


func _on_phase1_tooltip_confirmed() -> void:
	_phase1_tooltip.visible = false
	GameManager.mark_tutorial("forge_phase1_shown")
	_start_phase1_logic()


func _on_phase2_tooltip_confirmed() -> void:
	_phase2_tooltip.visible = false
	GameManager.mark_tutorial("forge_phase2_shown")
	_start_phase2_logic()


func _has_active_phase_tooltip() -> bool:
	return (
		(_phase1_tooltip != null and _phase1_tooltip.visible)
		or (_phase2_tooltip != null and _phase2_tooltip.visible)
	)


func _on_beat_started(beat_index: int, perfect_center: float) -> void:
	if _current_phase != Phase.P2:
		return
	_p2_strike_label.text   = "Nhát  %d / 5" % (beat_index + 1)
	_p2_feedback_label.text = ""

	var good_w: float = _forge2.GOOD_HALF_WIDTH    * _forge2.window_scale
	var perf_w: float = _forge2.PERFECT_HALF_WIDTH * _forge2.window_scale
	_p2_beat_bar.set_zones(perfect_center, good_w, perf_w)
	_p2_beat_bar.progress = 0.0


func _on_strike_resolved(result: int, idx: int, running_score: int) -> void:
	if _current_phase != Phase.P2:
		return
	_p2_score_label.text = "Điểm:  %d" % running_score
	_update_strike_badge(idx, result)

	var combo: int = 0
	if _forge2.has_method("get_combo_count"):
		combo = _forge2.get_combo_count()
	elif "combo_count" in _forge2:
		combo = int(_forge2.combo_count)

	if _p2_stage != null:
		if _p2_stage.has_method("set_combo_count"):
			_p2_stage.set_combo_count(combo)
		_p2_stage.trigger_strike(result)

	var feedback_pop := 1.16
	var badge_pop := 1.20
	match result:
		_forge2.HitResult.PERFECT:
			if combo >= 2:
				_p2_feedback_label.text = "★ PERFECT! COMBO x%d" % combo
				_p2_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.20))
				feedback_pop = 1.38 + minf(0.18, float(combo) * 0.04)
			else:
				_p2_feedback_label.text = "★  PERFECT!"
				_p2_feedback_label.add_theme_color_override("font_color", COLOR_PERFECT)
				feedback_pop = 1.28
			_p2_beat_bar.flash_result(COLOR_PERFECT)
			AudioManager.play_sfx_key("hammer_perfect")
			badge_pop = 1.30
		_forge2.HitResult.GOOD:
			_p2_feedback_label.text = "◆  GOOD"
			_p2_feedback_label.add_theme_color_override("font_color", COLOR_GOOD)
			_p2_beat_bar.flash_result(COLOR_GOOD)
			AudioManager.play_sfx_key("hammer_good")
			feedback_pop = 1.18
			badge_pop = 1.22
		_forge2.HitResult.MISS:
			_p2_feedback_label.text = "✕  MISS..."
			_p2_feedback_label.add_theme_color_override("font_color", COLOR_MISS)
			_p2_beat_bar.flash_result(COLOR_MISS)
			AudioManager.play_sfx_key("hammer_miss")
			feedback_pop = 1.10
			badge_pop = 1.14

	# Hiệu ứng nảy phóng nhẹ cho nhãn phản hồi và huy hiệu nhát búa vừa đánh
	if _p2_feedback_tween != null:
		_p2_feedback_tween.kill()
	_p2_feedback_label.pivot_offset = _p2_feedback_label.size * 0.5
	_p2_feedback_label.scale = Vector2(feedback_pop, feedback_pop)
	_p2_feedback_tween = create_tween().set_parallel(true)
	_p2_feedback_tween.tween_property(_p2_feedback_label, "scale", Vector2.ONE, 0.24) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if combo >= 2 and result == _forge2.HitResult.PERFECT:
		_p2_feedback_label.modulate = Color(1.35, 1.25, 0.7)
		_p2_feedback_tween.tween_property(_p2_feedback_label, "modulate", Color.WHITE, 0.26) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if idx >= 0 and idx < _p2_strike_badges.size():
		var badge := _p2_strike_badges[idx]
		badge.pivot_offset = badge.size * 0.5
		badge.scale = Vector2(badge_pop, badge_pop)
		var badge_tw := create_tween()
		badge_tw.tween_property(badge, "scale", Vector2.ONE, 0.22) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_phase2_done(_score: int, prefix_tier: String) -> void:
	if _current_phase != Phase.P2:
		return
	_p2_prefix = prefix_tier
	_go_to_phase3_anim()


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 3 — TÔI LUYỆN
# ══════════════════════════════════════════════════════════════════════════════

func _build_phase3_anim_ui() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_p3_anim_bg = ColorRect.new()
	_p3_anim_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_p3_anim_bg.color = Color(0, 0, 0, 0)
	_p3_anim_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_p3_anim_bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)

	# Sân khấu tôi luyện 32-bit (bể tôi 2 lớp + vũ khí thật chìm vào bể + hơi nước linh lực)
	var stage_wrap := CenterContainer.new()
	vbox.add_child(stage_wrap)

	_p3_stage = _STAGE_SCRIPT.new()
	_p3_stage.custom_minimum_size = Vector2(560.0, 380.0)
	_p3_stage.set_mode(_STAGE_SCRIPT.Mode.MODE_QUENCH)
	stage_wrap.add_child(_p3_stage)

	_p3_anim_label = Label.new()
	_p3_anim_label.add_theme_font_size_override("font_size", 54)
	_p3_anim_label.add_theme_color_override("font_color", Color.WHITE)
	_p3_anim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_p3_anim_label)

	_p3_instruct = Label.new()
	_p3_instruct.text = "Nhấn [SPACE] khi Vòng Cổ Ngữ thu nhỏ vào tâm để TÔI HOÀN HẢO!"
	_p3_instruct.add_theme_font_size_override("font_size", 30)
	_p3_instruct.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	_p3_instruct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_p3_instruct)

	_p3_perfect_banner = PanelContainer.new()
	_p3_perfect_banner.visible = false
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color(0.14, 0.09, 0.02, 0.96)
	banner_style.border_color = Color(1.0, 0.84, 0.25)
	banner_style.set_border_width_all(2)
	banner_style.set_corner_radius_all(8)
	banner_style.content_margin_left = 28
	banner_style.content_margin_right = 28
	banner_style.content_margin_top = 10
	banner_style.content_margin_bottom = 10
	_p3_perfect_banner.add_theme_stylebox_override("panel", banner_style)

	var banner_lbl := Label.new()
	banner_lbl.text = "★ TÔI HOÀN HẢO! (+10% Giá, +15% Bền)"
	banner_lbl.add_theme_font_size_override("font_size", 40)
	banner_lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.38))
	banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p3_perfect_banner.add_child(banner_lbl)
	vbox.add_child(_p3_perfect_banner)

	# Lớp lóe trắng đặt trên cùng để phủ sáng toàn màn hình cuối pha tôi
	_p3_flash_rect = ColorRect.new()
	_p3_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_p3_flash_rect.color = Color(1, 1, 1, 0)
	_p3_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_p3_flash_rect)

	return root


func _go_to_phase3_anim() -> void:
	AudioManager.stop_sfx_loop()
	var element_key := GameManager.selected_element
	if element_key == "":
		element_key = "hoa"
		GameManager.selected_element = element_key
	_forge3.start_phase(element_key)
	_current_phase        = Phase.P3_ANIM
	_update_indicator(_PHASE_INDICATOR_SCRIPT.Phase.TOI_LUYEN)
	_p1_root.visible      = false
	_p2_root.visible      = false
	_p3_anim_root.visible = true
	_result_root.visible  = false
	if _global_back_btn:
		_global_back_btn.visible = true

	_p3_quench_pressed = false
	_p3_is_perfect = false
	if _p3_perfect_banner != null:
		_p3_perfect_banner.visible = false
	if _p3_instruct != null:
		_p3_instruct.text = "Nhấn [SPACE] khi Vòng Cổ Ngữ thu nhỏ vào tâm để TÔI HOÀN HẢO!"
		_p3_instruct.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))

	var elem: Dictionary = _forge3.get_element_data(element_key)
	var elem_color: Color = elem.get("color", Color.WHITE)
	var elem_name: String = String(elem.get("name", ""))
	var dur: float = _forge3.QUENCH_DURATION
	var weapon_tex := _load_selected_weapon_texture()

	if _p3_stage != null:
		_p3_stage.set_mode(_STAGE_SCRIPT.Mode.MODE_QUENCH)
		_p3_stage.set_weapon_texture(weapon_tex)
		_p3_stage.start_quench_sequence(elem_color, dur)

	_p3_anim_bg.color    = Color(elem_color.r, elem_color.g, elem_color.b, 0.0)
	_p3_flash_rect.color = Color(1, 1, 1, 0.0)
	_p3_anim_label.text  = "Nhúng tôi luyện %s..." % elem_name

	if _p3_tween:
		_p3_tween.kill()
	_p3_tween = create_tween()
	# 0.28 * dur: chạm mặt nước — xì hơi nước & đổi chữ thẩm thấu linh lực
	_p3_tween.tween_interval(dur * 0.28)
	_p3_tween.tween_callback(func() -> void:
		AudioManager.play_sfx_key("quench_sizzle", 0.85)
		_p3_anim_label.text = "Linh lực %s đang thẩm thấu!" % elem_name
	)
	# 0.28 -> 0.55 * dur: nền sáng nhẹ màu nguyên tố (alpha 0.28)
	_p3_tween.tween_property(
		_p3_anim_bg, "color",
		Color(elem_color.r, elem_color.g, elem_color.b, 0.28),
		dur * 0.27
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 0.55 -> 0.88 * dur: chờ vũ khí nguội sáng và nâng lên khỏi bể
	_p3_tween.tween_interval(dur * 0.33)
	# 0.88 -> 1.00 * dur: lóe trắng (0.85) -> hoàn tất tôi luyện
	_p3_tween.tween_property(
		_p3_flash_rect, "color",
		Color(1.0, 1.0, 1.0, 0.85),
		dur * 0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_p3_tween.tween_callback(_finish_quench.bind(element_key))


func _handle_quench_press() -> void:
	if _p3_quench_pressed or _current_phase != Phase.P3_ANIM:
		return
	_p3_quench_pressed = true
	var is_perfect := false
	if _forge3.has_method("try_quench_press"):
		is_perfect = _forge3.try_quench_press()
	elif _forge3.has_method("is_in_quench_window"):
		is_perfect = _forge3.is_in_quench_window()
	else:
		is_perfect = absf(_forge3.quench_progress - 0.70) <= 0.08

	_p3_is_perfect = is_perfect
	if is_perfect:
		_on_perfect_quench_achieved()
	else:
		AudioManager.play_sfx_key("hammer_good", 0.85)
		if _p3_instruct != null:
			_p3_instruct.text = "Tôi Luyện Thường (nhấn lệch tâm hội tụ)"
			_p3_instruct.add_theme_color_override("font_color", Color(0.72, 0.70, 0.68))


func _on_perfect_quench_achieved() -> void:
	if _p3_stage != null and _p3_stage.has_method("trigger_perfect_quench"):
		_p3_stage.trigger_perfect_quench()
	AudioManager.play_sfx_key("hammer_perfect", 1.15)
	AudioManager.play_sfx_key("skill_fire", 1.20)
	if _p3_perfect_banner != null:
		_p3_perfect_banner.visible = true
		_p3_perfect_banner.pivot_offset = _p3_perfect_banner.size * 0.5
		_p3_perfect_banner.scale = Vector2(0.65, 0.65)
		_p3_perfect_banner.modulate = Color(1.3, 1.2, 0.7, 0.0)
		var btw := create_tween().set_parallel(true)
		btw.tween_property(_p3_perfect_banner, "scale", Vector2.ONE, 0.32) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		btw.tween_property(_p3_perfect_banner, "modulate", Color.WHITE, 0.30) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _p3_instruct != null:
		_p3_instruct.text = "★ TÔI THÀNH CÔNG RỰC RỠ!"
		_p3_instruct.add_theme_color_override("font_color", Color(1.0, 0.95, 0.40))


func _finish_quench(_element_key: String) -> void:
	AudioManager.play_sfx_key("weapon_reveal", 0.78)
	create_tween().tween_property(_p3_flash_rect, "color", Color(1, 1, 1, 0), 0.4)
	var final_perfect := _p3_is_perfect or bool(_forge3.get("perfect_quench", false))
	var result: Dictionary = _forge3.complete(_p1_tier, _p2_prefix, final_perfect)
	result["perfect_quench"] = final_perfect
	if final_perfect:
		result["durability_bonus"] = maxi(int(result.get("durability_bonus", 0)), 15)
	# Gắn thông tin phôi vào kết quả để WeaponCard hiển thị đúng stats
	var blank: Dictionary = GameManager.selected_blank
	var mat:   Dictionary = GameManager.selected_material
	result["blank_id"]          = blank.get("id",         "")
	result["weapon_type"]       = blank.get("name",       "Vũ Khí")
	result["base_atk"]          = blank.get("atk",        10) + mat.get("atk_bonus",   0)
	result["base_def"]          = blank.get("def",         0) + mat.get("def_bonus",    0)
	result["base_magic"]        = blank.get("magic",       3) + mat.get("magic_bonus",  0)
	result["base_speed"]        = blank.get("speed",       5) + mat.get("speed_bonus",  0)
	result["innate_skill_id"]   = blank.get("skill",       "")
	result["innate_skill"]      = blank.get("skill_name",  blank.get("skill", ""))
	result["innate_skill_desc"] = blank.get("skill_desc",  "")
	result["material_name"]     = mat.get("name",          "")
	var rarity_price_table := {1: 0.5, 2: 1.0, 3: 1.6}
	var material_rarity: int = GameManager.selected_material.get("rarity", 1)
	result["rarity_tier"] = material_rarity
	var base_mult: float = rarity_price_table.get(material_rarity, 1.0) * mat.get("price_mult", 1.0)
	if final_perfect:
		base_mult *= 1.10
	result["price_mult"] = base_mult
	_show_result(result)


# ══════════════════════════════════════════════════════════════════════════════
# RESULT — WEAPON CARD
# ══════════════════════════════════════════════════════════════════════════════

func _build_result_ui() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 100

	# VBox fill toàn màn hình — spacer hút phần dư giữa card và buttons
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	root.add_child(vbox)

	var title := Label.new()
	title.text = "VŨ KHÍ HOÀN THÀNH"
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size.y = 92
	vbox.add_child(title)

	# Card căn giữa ngang, giữ đúng kích thước minimum (không expand)
	var card_wrap := CenterContainer.new()
	card_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_wrap.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	vbox.add_child(card_wrap)

	_weapon_card = _CARD_SCENE.instantiate()
	card_wrap.add_child(_weapon_card)

	# Spacer đẩy buttons xuống đáy
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 40)
	btn_row.custom_minimum_size.y = 92
	vbox.add_child(btn_row)

	_save_btn = Button.new()
	_save_btn.text = "⚔  LƯU VÀO KHO  (S)"
	_save_btn.add_theme_font_size_override("font_size", 52)
	_save_btn.custom_minimum_size = Vector2(640, 88)
	_save_btn.pressed.connect(_on_save_pressed)
	btn_row.add_child(_save_btn)

	var retry := Button.new()
	retry.text = "[ Rèn mới  (R) ]"
	retry.add_theme_font_size_override("font_size", 52)
	retry.custom_minimum_size = Vector2(440, 88)
	retry.pressed.connect(_on_retry_pressed)
	btn_row.add_child(retry)

	var hub_btn := Button.new()
	hub_btn.text = "[ Quay về Xưởng  (Esc) ]"
	hub_btn.add_theme_font_size_override("font_size", 52)
	hub_btn.custom_minimum_size = Vector2(520, 88)
	hub_btn.pressed.connect(_go_to_hub)
	btn_row.add_child(hub_btn)

	return root


func _show_result(result: Dictionary) -> void:
	_forge_result         = result
	_current_phase        = Phase.RESULT
	_p3_anim_root.visible = false
	_result_root.visible  = true
	if _global_back_btn:
		_global_back_btn.visible = false
	_save_btn.disabled    = false
	_weapon_card.setup(result)


# ══════════════════════════════════════════════════════════════════════════════
# INPUT / PROCESS / RETRY
# ══════════════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo or not event.pressed:
		return
	if _has_active_phase_tooltip():
		return

	match event.keycode:
		KEY_SPACE:
			match _current_phase:
				Phase.P1:
					if _forge1.is_active:
						if not _forge1.is_pumping:
							AudioManager.play_sfx_key("bellows_puff", 0.72)
						_forge1.is_pumping = true
						AudioManager.play_sfx_loop("furnace_burn", 0.85)
				Phase.P2:
					if _forge2.is_active:
						_forge2.try_hit()
				Phase.P3_ANIM:
					_handle_quench_press()
		KEY_ENTER:
			match _current_phase:
				Phase.P1:
					if _forge1.is_active:
						_forge1.release()
				Phase.P2:
					if _forge2.is_active:
						_forge2.try_hit()
				Phase.P3_ANIM:
					_handle_quench_press()
		KEY_S:
			if _current_phase == Phase.RESULT:
				_on_save_pressed()
		KEY_R:
			if _current_phase == Phase.RESULT:
				_on_retry_pressed()
		KEY_ESCAPE:
			if _current_phase == Phase.RESULT:
				_go_to_hub()
			else:
				_go_to_element_picker()


func _unhandled_key_input(event: InputEvent) -> void:
	# Nhả SPACE dừng bơm ống bễ (giữ nhịp bơm duy trì nhiệt)
	if event is InputEventKey and event.keycode == KEY_SPACE \
			and not event.pressed and not event.echo:
		if _current_phase == Phase.P1 and _forge1.is_active:
			_forge1.is_pumping = false
			AudioManager.stop_sfx_loop()


func _process(delta: float) -> void:
	match _current_phase:
		Phase.P1:
			var h: float = _forge1.heat
			var pct: float = h / 100.0
			_p1_heat_bar.heat_percent = pct
			_p1_heat_bar.tick_animation(delta)
			var cook: float = float(_forge1.get("cook_progress")) if _forge1.get("cook_progress") != null else 0.0
			if _p1_cook_bar != null:
				_p1_cook_bar.value = cook * 100.0
			if _p1_cook_label != null:
				_p1_cook_label.text = "Tiến độ chín thép: %d%%" % int(cook * 100.0)
			if _p1_stage != null:
				_p1_stage.set_heat_state(
					pct,
					_forge1.SWEET_SPOT_LOW / 100.0,
					_forge1.SWEET_SPOT_PEAK / 100.0,
					_forge1.burn_point / 100.0,
					_forge1.is_pumping
				)
			_p1_heat_label.text = "Nhiệt độ: %d / 100" % int(h)
			if _forge1.is_active:
				_p1_label_pulse += delta
				_p1_update_zone(h)
				_p1_animate_zone_label(h)
				_p1_tick_heat_warning(h, delta)
		Phase.P2:
			if _forge2.is_active:
				if _p2_beat_bar != null:
					_p2_beat_bar.progress = _forge2.beat_progress
				if _p2_stage != null:
					_p2_stage.set_beat_state(
						_forge2.beat_progress,
						_forge2.perfect_center,
						_forge2.current_strike,
						_forge2.TOTAL_STRIKES
					)
		Phase.P3_ANIM:
			if _p3_stage != null and "quench_progress" in _forge3:
				_p3_stage.set_quench_progress(_forge3.quench_progress, 0.70)


func _p1_tick_heat_warning(h: float, delta: float) -> void:
	if h < _forge1.SWEET_SPOT_PEAK:
		_heat_tick_timer = 0.0
		return
	_heat_tick_timer += delta
	var interval := 0.14 if h >= _forge1.burn_point else 0.24
	if _heat_tick_timer >= interval:
		_heat_tick_timer = 0.0
		var pitch := 1.25 if h >= _forge1.burn_point else 0.95
		AudioManager.play_sfx_key("heat_tick", 0.40, pitch)


func _p1_animate_zone_label(h: float) -> void:
	if h >= _forge1.burn_point:
		var a: float = 0.45 + sin(_p1_label_pulse * 12.0) * 0.55
		_p1_zone_label.modulate = Color(1.0, 1.0, 1.0, a)
	elif h >= _forge1.SWEET_SPOT_PEAK:
		var a: float = 0.70 + sin(_p1_label_pulse * 6.0) * 0.30
		_p1_zone_label.modulate = Color(1.0, 1.0, 1.0, a)
	else:
		_p1_zone_label.modulate = Color.WHITE


func _p1_update_zone(h: float) -> void:
	if h < _forge1.SWEET_SPOT_LOW:
		_p1_zone_label.text = "[ Lạnh ]   Tiếp tục bơm..."
		_p1_zone_label.add_theme_color_override("font_color", Color(0.6, 0.72, 0.95))
	elif h < _forge1.SWEET_SPOT_PEAK:
		_p1_zone_label.text = "[ Cam ]   Sweet spot — có thể nhả!"
		_p1_zone_label.add_theme_color_override("font_color", Color(0.95, 0.62, 0.18))
	elif h < _forge1.burn_point:
		_p1_zone_label.text = "[ Đỏ Rực ]   ĐỈNH NHIỆT — Nhả ngay!"
		_p1_zone_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.05))
	else:
		_p1_zone_label.text = "[ Cháy Thép ]   Thép đã hỏng!"
		_p1_zone_label.add_theme_color_override("font_color", Color(0.55, 0.25, 0.10))


func _on_save_pressed() -> void:
	if _forge_result.is_empty():
		return
	_save_btn.disabled = true
	_save_btn.text = "✓  ĐÃ LƯU"
	# Chuyển sang combat-ready format, merge thêm các field raw còn thiếu
	var weapon: Dictionary = ForgeConverter.forge_to_combat(_forge_result)
	for key in _forge_result:
		if not weapon.has(key):
			weapon[key] = _forge_result[key]
	InventorySystem.add_weapon(weapon)
	EventBus.weapon_forged.emit(weapon)
	var qty_to_consume: int = GameManager.selected_blank.get("required_quantity", 2)
	var selected_mat_ids: Array = GameManager.selected_material.get("material_ids", [])
	if not selected_mat_ids.is_empty():
		_consume_selected_material_ids(selected_mat_ids)
		return
	var selected_mat_id: String = GameManager.selected_material.get(
		"item_id", GameManager.selected_material.get("id", "")
	)
	_consume_material_units([selected_mat_id], qty_to_consume)


func _consume_selected_material_ids(selected_mat_ids: Array) -> void:
	var alias_map: Dictionary = GameManager.selected_material.get("material_inventory_aliases", {})
	for selected_id in selected_mat_ids:
		var accepted_ids: Array = alias_map.get(selected_id, [selected_id])
		_consume_material_units(accepted_ids, 1)


func _consume_material_units(accepted_ids: Array, amount: int) -> void:
	var remaining := maxi(0, amount)
	var i := InventorySystem.materials.size() - 1
	while i >= 0 and remaining > 0:
		var entry: Dictionary = InventorySystem.materials[i]
		if not accepted_ids.has(entry.get("item_id", "")):
			i -= 1
			continue

		var quantity_key := _get_material_quantity_key(entry)
		if quantity_key == "":
			InventorySystem.materials.remove_at(i)
			remaining -= 1
			i -= 1
			continue

		var quantity := maxi(1, int(entry.get(quantity_key, 1)))
		var consumed := mini(quantity, remaining)
		quantity -= consumed
		remaining -= consumed
		if quantity <= 0:
			InventorySystem.materials.remove_at(i)
		else:
			entry[quantity_key] = quantity
			InventorySystem.materials[i] = entry
		i -= 1


func _get_material_quantity_key(entry: Dictionary) -> String:
	if entry.has("quantity"):
		return "quantity"
	if entry.has("amount"):
		return "amount"
	return ""


func _rarity_label(rarity: int) -> String:
	match rarity:
		1: return "[★☆☆ Phổ Thông]"
		2: return "[★★☆ Hiếm]"
		3: return "[★★★ Cực Hiếm]"
	return ""


func _on_retry_pressed() -> void:
	AudioManager.stop_sfx_loop()
	if _p3_tween:
		_p3_tween.kill()
	get_tree().change_scene_to_file(PATH_WEAPON_BUILDER)


func _go_to_element_picker() -> void:
	AudioManager.stop_sfx_loop()
	if _p3_tween:
		_p3_tween.kill()
	get_tree().change_scene_to_file(PATH_ELEMENT_PICKER)


func _go_to_hub() -> void:
	AudioManager.stop_sfx_loop()
	if _p3_tween:
		_p3_tween.kill()
	SceneManager.go_to(PATH_WORKSHOP)
