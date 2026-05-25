# gdlint: disable=max-file-lines
# Forge Session — kết hợp 3 phase rèn thành một luồng hoàn chỉnh
# Nung → Rèn Búa → Tôi Luyện bằng linh lực đã chọn → Weapon Card
extends Control

enum Phase { P1, P2, P3_PICK, P3_ANIM, RESULT }

const _FORGE1_SCRIPT := preload("res://scripts/forge/forge_system.gd")
const _FORGE2_SCRIPT := preload("res://scripts/forge/forge_phase2.gd")
const _FORGE3_SCRIPT := preload("res://scripts/forge/forge_phase3.gd")
const _HEAT_BAR_SCRIPT := preload("res://scripts/forge/heat_bar.gd")
const _CARD_SCENE    := preload("res://scenes/ui/WeaponCardUI.tscn")
const _PHASE_INDICATOR_SCRIPT := preload("res://scripts/forge/forge_phase_indicator.gd")
const _PHASE_INDICATOR_SCENE := preload("res://scenes/forge/ForgePhaseIndicator.tscn")

const PATH_MATERIAL_PICKER := "res://scenes/forge/MaterialPicker.tscn"
const PATH_ELEMENT_PICKER := "res://scenes/forge/ElementPicker.tscn"
const PATH_WEAPON_BUILDER := "res://scenes/forge/WeaponBuilder.tscn"
const PATH_WORKSHOP := "res://scenes/main/WorkshopHub.tscn"
const BACKGROUND_PATH := "res://assets/sprites/forge/backgrounds/Forge Scene BG.PNG"

const BAR_WIDTH  := 1400.0
const BAR_HEIGHT := 140.0

const COLOR_PERFECT := Color(0.95, 0.86, 0.2)
const COLOR_GOOD    := Color(0.85, 0.55, 0.1)
const COLOR_MISS    := Color(0.75, 0.22, 0.18)

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

# ─── Logic nodes ──────────────────────────────────────────────────────────────

var _forge1: Node
var _forge2: Node
var _forge3: Node

# ─── Phase containers ─────────────────────────────────────────────────────────

var _p1_root:      Control
var _p2_root:      Control
var _p3_pick_root: Control
var _p3_anim_root: Control
var _result_root:  Control

# ─── Phase indicator ──────────────────────────────────────────────────────────

var _phase_indicator

# ─── Phase 1 widgets ──────────────────────────────────────────────────────────

var _p1_active_box:     VBoxContainer  # ẩn khi phase 1 xong
var _p1_heat_bar:       HeatBar
var _p1_heat_label:     Label
var _p1_zone_label:     Label
var _p1_instruct:       Label
var _p1_result_box:     VBoxContainer
var _p1_result_label:   Label
var _p1_mult_label:     Label

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

var _p2_good_zone:      ColorRect
var _p2_perfect_zone:   ColorRect
var _p2_beat_indicator: ColorRect
var _p2_strike_label:   Label
var _p2_score_label:    Label
var _p2_feedback_label: Label

# ─── Phase 3 widgets ──────────────────────────────────────────────────────────

var _p3_anim_bg:     ColorRect
var _p3_flash_rect:  ColorRect
var _p3_weapon_rect: ColorRect
var _p3_anim_label:  Label
var _p3_tween:       Tween
var _p3_element_grid: GridContainer

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
	var forge_book := get_node_or_null("ForgeBookUI")
	if forge_book:
		forge_book.queue_free()

	var bg := TextureRect.new()
	bg.texture = load(BACKGROUND_PATH) as Texture2D
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

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
	_p3_pick_root = _build_phase3_pick_ui()
	_p3_anim_root = _build_phase3_anim_ui()
	_result_root  = _build_result_ui()

	add_child(_p1_root)
	add_child(_p2_root)
	add_child(_p3_pick_root)
	add_child(_p3_anim_root)
	add_child(_result_root)
	_phase1_tooltip = _build_phase_tooltip(
		"Phase1Tooltip",
		"PHASE 1 — NUNG",
		"Giữ [Space] để bơm bễ. Nhả khi nhiệt độ vào vùng Cam trên thanh.",
		_on_phase1_tooltip_confirmed
	)
	_phase2_tooltip = _build_phase_tooltip(
		"Phase2Tooltip",
		"PHASE 2 — RÈN",
		"Nhấn [Space] khi thanh đến vùng PERFECT (xanh). "
			+ "5 nhát búa quyết định chất lượng!",
		_on_phase2_tooltip_confirmed
	)
	add_child(_phase1_tooltip)
	add_child(_phase2_tooltip)
	_global_back_btn = _build_global_back_button()
	add_child(_global_back_btn)

	_go_to_phase1()


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
	root.offset_top = 100

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 48)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "NUNG THÉP — Phase 1"
	title.add_theme_font_size_override("font_size", 104)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Gom toàn bộ UI active — ẩn khi phase xong để nhường chỗ cho result
	_p1_active_box = VBoxContainer.new()
	_p1_active_box.add_theme_constant_override("separation", 40)
	vbox.add_child(_p1_active_box)

	_p1_active_box.add_child(_build_heat_bar())

	_p1_heat_label = Label.new()
	_p1_heat_label.text = "Nhiệt độ: 0 / 100"
	_p1_heat_label.add_theme_font_size_override("font_size", 76)
	_p1_heat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_active_box.add_child(_p1_heat_label)

	_p1_zone_label = Label.new()
	_p1_zone_label.text = "Sẵn sàng..."
	_p1_zone_label.add_theme_font_size_override("font_size", 64)
	_p1_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_active_box.add_child(_p1_zone_label)

	_p1_tip_label = Label.new()
	_p1_tip_label.text = (
		"Cam = an toàn (+20%)  •  Đỏ Rực = mạo hiểm (+40%)  •  "
		+ "Cháy Thép = hỏng (−50%)"
	)
	_p1_tip_label.add_theme_font_size_override("font_size", 38)
	_p1_tip_label.add_theme_color_override("font_color", Color(0.72, 0.67, 0.52))
	_p1_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_active_box.add_child(_p1_tip_label)

	_p1_instruct = Label.new()
	_p1_instruct.text = "Giữ [SPACE] để bơm ống bễ — Nhả để kết thúc"
	_p1_instruct.add_theme_font_size_override("font_size", 52)
	_p1_instruct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_active_box.add_child(_p1_instruct)

	_p1_result_box = VBoxContainer.new()
	_p1_result_box.visible = false
	_p1_result_box.add_theme_constant_override("separation", 40)
	vbox.add_child(_p1_result_box)
	_p1_result_box.add_child(HSeparator.new())

	_p1_result_label = Label.new()
	_p1_result_label.add_theme_font_size_override("font_size", 88)
	_p1_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_result_box.add_child(_p1_result_label)

	_p1_mult_label = Label.new()
	_p1_mult_label.add_theme_font_size_override("font_size", 60)
	_p1_mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_result_box.add_child(_p1_mult_label)

	var next := Button.new()
	next.text = "[ Tiếp tục Rèn Búa  → ]"
	next.add_theme_font_size_override("font_size", 52)
	next.pressed.connect(_go_to_phase2)
	_p1_result_box.add_child(next)

	return root


func _build_heat_bar() -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 8)

	_p1_heat_bar = _HEAT_BAR_SCRIPT.new()
	_p1_heat_bar.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	wrapper.add_child(_p1_heat_bar)

	var row := HBoxContainer.new()

	_p1_lbl_lanh = Label.new()
	_p1_lbl_lanh.text = "Lạnh  (<60)"
	_p1_lbl_lanh.add_theme_font_size_override("font_size", 40)
	_p1_lbl_lanh.add_theme_color_override("font_color", Color(0.6, 0.72, 0.95))
	_p1_lbl_lanh.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_p1_lbl_lanh.custom_minimum_size.x = BAR_WIDTH * 0.6
	row.add_child(_p1_lbl_lanh)

	_p1_lbl_cam = Label.new()
	_p1_lbl_cam.text = "Cam"
	_p1_lbl_cam.add_theme_font_size_override("font_size", 40)
	_p1_lbl_cam.add_theme_color_override("font_color", Color(0.95, 0.62, 0.18))
	_p1_lbl_cam.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_lbl_cam.custom_minimum_size.x = BAR_WIDTH * 0.2
	row.add_child(_p1_lbl_cam)

	_p1_lbl_do_ruc = Label.new()
	_p1_lbl_do_ruc.text = "Đỏ Rực"
	_p1_lbl_do_ruc.add_theme_font_size_override("font_size", 40)
	_p1_lbl_do_ruc.add_theme_color_override("font_color", Color(1.0, 0.45, 0.05))
	_p1_lbl_do_ruc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_lbl_do_ruc.custom_minimum_size.x = BAR_WIDTH * 0.12
	row.add_child(_p1_lbl_do_ruc)

	_p1_lbl_chay = Label.new()
	_p1_lbl_chay.text = "Cháy Thép"
	_p1_lbl_chay.add_theme_font_size_override("font_size", 40)
	_p1_lbl_chay.add_theme_color_override("font_color", Color(0.55, 0.25, 0.10))
	_p1_lbl_chay.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_p1_lbl_chay.custom_minimum_size.x = BAR_WIDTH * 0.08
	row.add_child(_p1_lbl_chay)

	wrapper.add_child(row)

	# Hàng effect: luôn hiển thị multiplier của từng zone
	var eff_row := HBoxContainer.new()

	_p1_lbl_eff_lanh = Label.new()
	_p1_lbl_eff_lanh.text = "−30%"
	_p1_lbl_eff_lanh.add_theme_font_size_override("font_size", 36)
	_p1_lbl_eff_lanh.add_theme_color_override("font_color", Color(0.6, 0.72, 0.95))
	eff_row.add_child(_p1_lbl_eff_lanh)

	_p1_lbl_eff_cam = Label.new()
	_p1_lbl_eff_cam.text = "+20%"
	_p1_lbl_eff_cam.add_theme_font_size_override("font_size", 36)
	_p1_lbl_eff_cam.add_theme_color_override("font_color", Color(0.95, 0.62, 0.18))
	_p1_lbl_eff_cam.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eff_row.add_child(_p1_lbl_eff_cam)

	_p1_lbl_eff_do_ruc = Label.new()
	_p1_lbl_eff_do_ruc.text = "+40% ★"
	_p1_lbl_eff_do_ruc.add_theme_font_size_override("font_size", 36)
	_p1_lbl_eff_do_ruc.add_theme_color_override("font_color", Color(1.0, 0.45, 0.05))
	_p1_lbl_eff_do_ruc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eff_row.add_child(_p1_lbl_eff_do_ruc)

	_p1_lbl_eff_chay = Label.new()
	_p1_lbl_eff_chay.text = "−50%"
	_p1_lbl_eff_chay.add_theme_font_size_override("font_size", 36)
	_p1_lbl_eff_chay.add_theme_color_override("font_color", Color(0.55, 0.25, 0.10))
	_p1_lbl_eff_chay.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	eff_row.add_child(_p1_lbl_eff_chay)

	wrapper.add_child(eff_row)
	return wrapper


func _go_to_phase1() -> void:
	_current_phase = Phase.P1
	_update_indicator(_PHASE_INDICATOR_SCRIPT.Phase.NUNG_THEP)
	_p1_root.visible      = true
	_p2_root.visible      = false
	_p3_pick_root.visible = false
	_p3_anim_root.visible = false
	_result_root.visible  = false
	if _global_back_btn:
		_global_back_btn.visible = true
	_p1_active_box.visible = true
	_p1_result_box.visible = false
	_p1_zone_label.text    = "Sẵn sàng..."
	_p1_zone_label.add_theme_color_override("font_color", Color.WHITE)
	var rarity: int = GameManager.selected_material.get("rarity", 1)
	_p1_instruct.text = "Giữ [SPACE] để bơm ống bễ — Nhả để kết thúc     %s" \
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

	_p1_lbl_lanh.custom_minimum_size.x   = BAR_WIDTH * low_frac
	_p1_lbl_cam.custom_minimum_size.x    = BAR_WIDTH * (peak_frac - low_frac)
	_p1_lbl_do_ruc.custom_minimum_size.x = BAR_WIDTH * (burn_frac - peak_frac)
	_p1_lbl_chay.custom_minimum_size.x   = BAR_WIDTH * (1.0 - burn_frac)
	_p1_lbl_do_ruc.text = "Đỏ Rực  (%d%%)" % int((burn_frac - peak_frac) * 100.0)
	_p1_lbl_chay.text   = "Cháy Thép  (%d%%)" % int((1.0 - burn_frac) * 100.0)

	_p1_lbl_eff_lanh.custom_minimum_size.x   = BAR_WIDTH * low_frac
	_p1_lbl_eff_cam.custom_minimum_size.x    = BAR_WIDTH * (peak_frac - low_frac)
	_p1_lbl_eff_do_ruc.custom_minimum_size.x = BAR_WIDTH * (burn_frac - peak_frac)
	_p1_lbl_eff_chay.custom_minimum_size.x   = BAR_WIDTH * (1.0 - burn_frac)


func _on_phase1_done(tier: String) -> void:
	if _current_phase != Phase.P1:
		return
	# Nguyên liệu có thể override tier tối thiểu
	var p1_min := GameManager.selected_material.get("phase1_min", "") as String
	if p1_min == "do_ruc":
		tier = "do_ruc"
	elif p1_min == "cam" and tier == "lanh":
		tier = "cam"
	_p1_tier = tier
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


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 2 — RÈN BÚA
# ══════════════════════════════════════════════════════════════════════════════

func _build_phase2_ui() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 100

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 48)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "RÈN BÚA — Phase 2"
	title.add_theme_font_size_override("font_size", 104)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var info_row := HBoxContainer.new()
	info_row.alignment = BoxContainer.ALIGNMENT_CENTER
	info_row.add_theme_constant_override("separation", 120)
	vbox.add_child(info_row)

	_p2_strike_label = Label.new()
	_p2_strike_label.text = "Nhát  1 / 5"
	_p2_strike_label.add_theme_font_size_override("font_size", 68)
	info_row.add_child(_p2_strike_label)

	_p2_score_label = Label.new()
	_p2_score_label.text = "Điểm:  0"
	_p2_score_label.add_theme_font_size_override("font_size", 68)
	info_row.add_child(_p2_score_label)

	# Label độ khó — cập nhật trong _go_to_phase2() qua text của instruct
	var diff_lbl := Label.new()
	diff_lbl.name = "DiffLabel"
	diff_lbl.add_theme_font_size_override("font_size", 52)
	diff_lbl.add_theme_color_override("font_color", Color(0.75, 0.60, 0.35))
	info_row.add_child(diff_lbl)

	vbox.add_child(_build_beat_bar())

	_p2_feedback_label = Label.new()
	_p2_feedback_label.text = ""
	_p2_feedback_label.add_theme_font_size_override("font_size", 92)
	_p2_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_p2_feedback_label)

	var instruct := Label.new()
	instruct.text = "Nhấn [SPACE] khi thanh chạm vùng vàng"
	instruct.add_theme_font_size_override("font_size", 52)
	instruct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instruct)

	return root


func _build_beat_bar() -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 8)

	var bar := Control.new()
	bar.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	wrapper.add_child(bar)

	var bg_bar := ColorRect.new()
	bg_bar.color = Color(0.2, 0.18, 0.16)
	bg_bar.size  = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bar.add_child(bg_bar)

	_p2_good_zone = ColorRect.new()
	_p2_good_zone.color = Color(0.65, 0.35, 0.05, 0.7)
	bar.add_child(_p2_good_zone)

	_p2_perfect_zone = ColorRect.new()
	_p2_perfect_zone.color = Color(0.85, 0.72, 0.08, 0.9)
	bar.add_child(_p2_perfect_zone)

	_p2_beat_indicator = ColorRect.new()
	_p2_beat_indicator.color = Color.WHITE
	_p2_beat_indicator.size  = Vector2(10, BAR_HEIGHT)
	bar.add_child(_p2_beat_indicator)

	var row := HBoxContainer.new()
	var sp1 := Control.new(); sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp1)
	var lbl := Label.new()
	lbl.text = "GOOD"
	lbl.add_theme_color_override("font_color", Color(0.9, 0.62, 0.18))
	lbl.add_theme_font_size_override("font_size", 40)
	row.add_child(lbl)
	var sp2 := Control.new(); sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp2)
	wrapper.add_child(row)
	return wrapper


func _go_to_phase2() -> void:
	_current_phase = Phase.P2
	_update_indicator(_PHASE_INDICATOR_SCRIPT.Phase.REN_BUA)
	_p1_root.visible      = false
	_p2_root.visible      = true
	_p3_pick_root.visible = false
	_p3_anim_root.visible = false
	_result_root.visible  = false
	if _global_back_btn:
		_global_back_btn.visible = true
	_p2_score_label.text    = "Điểm:  0"
	_p2_strike_label.text   = "Nhát  1 / 5"
	_p2_feedback_label.text = ""
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
	var diff_lbl := _p2_root.find_child("DiffLabel") as Label
	if diff_lbl:
		var max_stars := {1: "★★☆☆☆", 2: "★★★☆☆", 3: "★★★★★"}
		diff_lbl.text = "%s  |  Tối đa Prefix: %s" % [
			_rarity_label(rarity),
			max_stars.get(rarity, "★★★★★"),
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

	var gs := clampf((perfect_center - good_w) * BAR_WIDTH, 0, BAR_WIDTH)
	var ge := clampf((perfect_center + good_w) * BAR_WIDTH, 0, BAR_WIDTH)
	_p2_good_zone.position = Vector2(gs, 0); _p2_good_zone.size = Vector2(ge - gs, BAR_HEIGHT)

	var ps := clampf((perfect_center - perf_w) * BAR_WIDTH, 0, BAR_WIDTH)
	var pe := clampf((perfect_center + perf_w) * BAR_WIDTH, 0, BAR_WIDTH)
	_p2_perfect_zone.position = Vector2(ps, 0); _p2_perfect_zone.size = Vector2(pe - ps, BAR_HEIGHT)


func _on_strike_resolved(result: int, _idx: int, running_score: int) -> void:
	if _current_phase != Phase.P2:
		return
	_p2_score_label.text = "Điểm:  %d" % running_score
	match result:
		_forge2.HitResult.PERFECT:
			_p2_feedback_label.text = "PERFECT!"
			_p2_feedback_label.add_theme_color_override("font_color", COLOR_PERFECT)
			AudioManager.play_sfx_key("hammer_perfect")
		_forge2.HitResult.GOOD:
			_p2_feedback_label.text = "GOOD"
			_p2_feedback_label.add_theme_color_override("font_color", COLOR_GOOD)
			AudioManager.play_sfx_key("hammer_good")
		_forge2.HitResult.MISS:
			_p2_feedback_label.text = "MISS..."
			_p2_feedback_label.add_theme_color_override("font_color", COLOR_MISS)
			AudioManager.play_sfx_key("hammer_miss")


func _on_phase2_done(_score: int, prefix_tier: String) -> void:
	if _current_phase != Phase.P2:
		return
	_p2_prefix = prefix_tier
	_go_to_phase3_anim()


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 3 — TÔI LUYỆN
# ══════════════════════════════════════════════════════════════════════════════

func _build_phase3_pick_ui() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 100

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 56)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "TÔI LUYỆN — Phase 3"
	title.add_theme_font_size_override("font_size", 104)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Chọn Linh Lực để tôi luyện vũ khí"
	sub.add_theme_font_size_override("font_size", 56)
	sub.add_theme_color_override("font_color", Color(0.78, 0.72, 0.62))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	_p3_element_grid = GridContainer.new()
	_p3_element_grid.columns = 3
	_p3_element_grid.add_theme_constant_override("h_separation", 40)
	_p3_element_grid.add_theme_constant_override("v_separation", 40)
	vbox.add_child(_p3_element_grid)

	return root


func _build_phase3_anim_ui() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_p3_anim_bg = ColorRect.new()
	_p3_anim_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_p3_anim_bg.color = Color(0, 0, 0, 0)
	root.add_child(_p3_anim_bg)

	_p3_flash_rect = ColorRect.new()
	_p3_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_p3_flash_rect.color = Color(1, 1, 1, 0)
	root.add_child(_p3_flash_rect)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 80)
	center.add_child(vbox)

	var weapon_wrap := CenterContainer.new()
	vbox.add_child(weapon_wrap)

	_p3_weapon_rect = ColorRect.new()
	_p3_weapon_rect.custom_minimum_size = Vector2(60, 280)
	_p3_weapon_rect.color = Color(0.72, 0.72, 0.72)
	weapon_wrap.add_child(_p3_weapon_rect)

	_p3_anim_label = Label.new()
	_p3_anim_label.add_theme_font_size_override("font_size", 76)
	_p3_anim_label.add_theme_color_override("font_color", Color.WHITE)
	_p3_anim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_p3_anim_label)

	return root


func _go_to_phase3_pick() -> void:
	_go_to_phase3_anim()


func _refresh_phase3_elements() -> void:
	for child in _p3_element_grid.get_children():
		child.queue_free()
	var allowed: Array = GameManager.selected_material.get("allowed_elements", [])
	for key in _forge3.ELEMENTS.keys():
		if allowed.is_empty() or key in allowed:
			var data: Dictionary = _forge3.ELEMENTS[key]
			var btn := Button.new()
			btn.text = data["name"]
			btn.custom_minimum_size = Vector2(360, 120)
			btn.add_theme_font_size_override("font_size", 64)
			btn.add_theme_color_override("font_color", data["color"])
			btn.pressed.connect(_on_element_picked.bind(key))
			_p3_element_grid.add_child(btn)


func _on_element_picked(element_key: String) -> void:
	GameManager.selected_element = element_key
	_go_to_phase3_anim()


func _go_to_phase3_anim() -> void:
	var element_key := GameManager.selected_element
	if element_key == "":
		element_key = "hoa"
		GameManager.selected_element = element_key
	_forge3.start_phase(element_key)
	_current_phase        = Phase.P3_ANIM
	_update_indicator(_PHASE_INDICATOR_SCRIPT.Phase.TOI_LUYEN)
	_p1_root.visible      = false
	_p2_root.visible      = false
	_p3_pick_root.visible = false
	_p3_anim_root.visible = true
	_result_root.visible  = false
	if _global_back_btn:
		_global_back_btn.visible = true

	var elem: Dictionary = _forge3.get_element_data(element_key)
	var elem_color: Color = elem.get("color", Color.WHITE)

	_p3_weapon_rect.color = Color(0.72, 0.72, 0.72)
	_p3_anim_bg.color     = Color(elem_color.r, elem_color.g, elem_color.b, 0)
	_p3_flash_rect.color  = Color(1, 1, 1, 0)
	_p3_anim_label.text   = "Tôi luyện %s..." % elem.get("name", "")

	if _p3_tween:
		_p3_tween.kill()
	var dur: float = _forge3.QUENCH_DURATION
	_p3_tween = create_tween()
	_p3_tween.tween_property(_p3_anim_bg, "color",
		Color(elem_color.r, elem_color.g, elem_color.b, 0.45), dur * 0.4)
	_p3_tween.tween_property(_p3_weapon_rect, "color", elem_color, dur * 0.25)
	_p3_tween.tween_property(_p3_anim_bg, "color",
		Color(elem_color.r, elem_color.g, elem_color.b, 0.75), dur * 0.2)
	_p3_tween.tween_property(_p3_flash_rect, "color", Color(1, 1, 1, 0.85), dur * 0.08)
	_p3_tween.tween_callback(_finish_quench.bind(element_key))


func _finish_quench(_element_key: String) -> void:
	create_tween().tween_property(_p3_flash_rect, "color", Color(1, 1, 1, 0), 0.4)
	var result: Dictionary = _forge3.complete(_p1_tier, _p2_prefix)
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
	result["price_mult"] = rarity_price_table.get(material_rarity, 1.0) \
		* mat.get("price_mult", 1.0)
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
						_forge1.is_pumping = true
						AudioManager.play_sfx_loop("furnace_burn")
				Phase.P2:
					if _forge2.is_active:
						_forge2.try_hit()
		KEY_ENTER:
			if _current_phase == Phase.P2 and _forge2.is_active:
				_forge2.try_hit()
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
	# Nhả SPACE kết thúc phase 1
	if event is InputEventKey and event.keycode == KEY_SPACE \
			and not event.pressed and not event.echo:
		if _current_phase == Phase.P1 and _forge1.is_active:
			_forge1.is_pumping = false
			_forge1.release()
			AudioManager.stop_sfx_loop()


func _process(_delta: float) -> void:
	match _current_phase:
		Phase.P1:
			var h: float = _forge1.heat
			_p1_heat_bar.heat_percent = h / 100.0
			_p1_heat_bar.tick_animation(_delta)
			_p1_heat_label.text = "Nhiệt độ: %d / 100" % int(h)
			if _forge1.is_active:
				_p1_label_pulse += _delta
				_p1_update_zone(h)
				_p1_animate_zone_label(h)
		Phase.P2:
			if _forge2.is_active:
				_p2_beat_indicator.position.x = clampf(
					_forge2.beat_progress * BAR_WIDTH - 5.0, 0, BAR_WIDTH - 10)


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
	if _p3_tween:
		_p3_tween.kill()
	get_tree().change_scene_to_file(PATH_WEAPON_BUILDER)


func _go_to_element_picker() -> void:
	if _p3_tween:
		_p3_tween.kill()
	get_tree().change_scene_to_file(PATH_ELEMENT_PICKER)


func _go_to_hub() -> void:
	if _p3_tween:
		_p3_tween.kill()
	SceneManager.go_to(PATH_WORKSHOP)
