# gdlint: disable=max-file-lines
# Forge Session — Lò Rèn 3 Pha "Rèn Có Ý Đồ" (32-bit Hoả Tâm)
# - Phase 1: Nung Phôi theo 2 Hồ Sơ Nhiệt (Phôi Nặng 80–92% vs Phôi Thanh/Phép 65–80%)
# - Phase 2: Đập Búa 2 Hướng "Cương / Nhu" Tất Định (Space/Trái vs Enter/Phải)
# - Phase 3: Nhịp 3A chọn 6 Ấn Linh Lực / Nước Thuần tại Bể Tôi -> Nhịp 3B căn nhịp Tôi Hoàn Hảo
# - Thành Phẩm: 3 hành động tức thì [Trang Bị Ngay] · [Bày Lên Kệ Tiệm] · [Cất Vào Kho]
extends Control

enum Phase { P1, P2, P3_SEAL, P3_ANIM, RESULT }

const _FORGE1_SCRIPT := preload("res://scripts/forge/forge_system.gd")
const _FORGE2_SCRIPT := preload("res://scripts/forge/forge_phase2.gd")
const _FORGE3_SCRIPT := preload("res://scripts/forge/forge_phase3.gd")
const _HEAT_BAR_SCRIPT := preload("res://scripts/forge/heat_bar.gd")
const _BEAT_BAR_SCRIPT := preload("res://scripts/forge/beat_bar.gd")
const _STAGE_SCRIPT := preload("res://scripts/forge/forge_visual_stage.gd")
const _CARD_SCENE    := preload("res://scenes/ui/WeaponCardUI.tscn")
const _PHASE_INDICATOR_SCRIPT := preload("res://scripts/forge/forge_phase_indicator.gd")
const _PHASE_INDICATOR_SCENE := preload("res://scenes/forge/ForgePhaseIndicator.tscn")

const PATH_WEAPON_BUILDER := "res://scenes/forge/WeaponBuilder.tscn"
const PATH_WORKSHOP := "res://scenes/main/WorkshopHub.tscn"
const BACKGROUND_PIXEL_PATH := "res://assets/pixel/backgrounds/forge_p3_quench_bg_640x360.png"
const ELEMENT_SEALS_SHEET_PATH := "res://assets/pixel/ui/forge/element_seals_sheet_64.png"
const COOK_FILL_TEX_PATH := "res://assets/pixel/ui/forge/forge_cook_fill_9s.png"
const ELEMENT_CARD_TEX_PATH := "res://assets/pixel/ui/forge/forge_element_card.png"
const CARD_GLOW_TEX_PATH := "res://assets/pixel/ui/forge/forge_card_glow.png"

const ELEMENT_ORDER: Array[String] = ["hoa", "bang", "set", "tho", "phong", "hu_khong"]

const COLOR_PERFECT := Color(0.98, 0.86, 0.20)
const COLOR_GOOD    := Color(0.92, 0.56, 0.14)
const COLOR_MISS    := Color(0.82, 0.24, 0.18)
const COLOR_CUONG   := Color(0.98, 0.44, 0.14)
const COLOR_NHU     := Color(0.32, 0.84, 0.98)

const PHASE1_TIER_NAMES := {
	"lanh": "Lạnh", "cam": "Cam", "do_ruc": "Đỏ Rực", "chay": "Cháy Thép",
}

# ─── State ────────────────────────────────────────────────────────────────────

var _current_phase := Phase.P1
var _p1_tier:   String = ""
var _p2_prefix: String = ""
var _bar_width: float = 1040.0
var _bar_height: float = 76.0
var _stage_height: float = 480.0
var _heat_tick_timer: float = 0.0
var _p1_transition_pending: bool = false
var _seal_pulse_time: float = 0.0

# ─── Logic nodes ──────────────────────────────────────────────────────────────

var _forge1: Node
var _forge2: Node
var _forge3: Node

# ─── Phase containers & Header ────────────────────────────────────────────────

var _p1_root:      Control
var _p2_root:      Control
var _p3_anim_root: Control
var _result_root:  Control
var _phase_indicator
var _global_back_btn: Button
var _recipe_chip: PanelContainer
var _recipe_main_label: Label
var _recipe_buff_label: Label

# ─── Phase 1 widgets (Nung Thép — 2 Hồ Sơ Nhiệt) ──────────────────────────────

var _p1_stage:          ForgeVisualStage
var _p1_heat_bar:       HeatBar
var _p1_cook_bar:       ProgressBar
var _p1_cook_label:     Label
var _p1_instruct_badge: PanelContainer
var _p1_instruct:       Label
var _p1_result_box:     PanelContainer
var _p1_result_label:   Label
var _p1_mult_label:     Label
var _p1_result_tween:   Tween

var _p1_lbl_lanh:   Label
var _p1_lbl_cam:    Label
var _p1_lbl_do_ruc: Label
var _p1_lbl_chay:   Label

# ─── Phase 2 widgets (Rèn Búa Cương / Nhu) ────────────────────────────────────

var _p2_stage:          ForgeVisualStage
var _p2_beat_bar:       BeatBar
var _p2_strike_badges:  Array[PanelContainer] = []
var _p2_feedback_label: Label
var _p2_feedback_tween: Tween

# ─── Phase 3 widgets (Nhịp 3A Chọn Ấn + Nhịp 3B Tôi Nước) ─────────────────────

var _p3_stage:          ForgeVisualStage
var _p3_instruct_badge: PanelContainer
var _p3_instruct:       Label
var _p3_perfect_banner: PanelContainer
var _p3_seal_overlay:   Control
var _p3_seal_buttons:   Dictionary = {}
var _p3_seal_base_y:    Dictionary = {}
var _p3_seal_base_rot:  Dictionary = {}
var _p3_visible_elements: Array[String] = []
var _p3_seal_hovered:   String = ""
var _p3_pure_water_btn: Button
var _p3_element_key:    String = ""
var _p3_quench_pressed: bool = false
var _p3_is_perfect:     bool = false
var _p3_input_lock:     float = 0.0

# ─── Result (Thanh hành động 1 tầng gọn rõ) ──────────────────────────────────

var _weapon_card:         Control
var _result_action_row:   HBoxContainer
var _result_nav_row:      HBoxContainer
var _result_status_label: Label
var _equip_btn:           Button
var _shelf_btn:           Button
var _save_btn:            Button
var _retry_btn:           Button
var _hub_btn:             Button
var _has_saved:           bool = false
var _forge_result:        Dictionary = {}


# ══════════════════════════════════════════════════════════════════════════════
# READY
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vp := get_viewport_rect().size
	_bar_width = clampf(vp.x * 0.56, 660.0, 1020.0)
	_bar_height = 60.0
	_stage_height = vp.y

	var forge_book := get_node_or_null("ForgeBookUI")
	if forge_book:
		forge_book.queue_free()

	var bg := TextureRect.new()
	if ResourceLoader.exists(BACKGROUND_PIXEL_PATH):
		bg.texture = load(BACKGROUND_PIXEL_PATH) as Texture2D
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.04, 0.02, 0.01, 0.16)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	theme = preload("res://assets/fonts/hoa_tam_pixel_theme.tres")

	_forge1 = _FORGE1_SCRIPT.new()
	add_child(_forge1)
	_forge2 = _FORGE2_SCRIPT.new()
	add_child(_forge2)
	_forge3 = _FORGE3_SCRIPT.new()
	add_child(_forge3)

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

	_global_back_btn = _build_global_back_button()
	add_child(_global_back_btn)
	_recipe_chip = _build_recipe_chip()
	add_child(_recipe_chip)

	_go_to_phase1()


func _exit_tree() -> void:
	AudioManager.stop_sfx_loop()


# ══════════════════════════════════════════════════════════════════════════════
# TOP HEADER: BACK BUTTON + 6-STEP INDICATOR + RECIPE/BUFF CHIP
# ══════════════════════════════════════════════════════════════════════════════

func _setup_button(btn: Button) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _build_global_back_button() -> Button:
	var back_btn := Button.new()
	back_btn.text = "← Bàn Chuẩn Bị (Esc)"
	back_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_btn.offset_left = 18.0
	back_btn.offset_top = 14.0
	back_btn.custom_minimum_size = Vector2(216.0, 38.0)
	_setup_button(back_btn)
	HoaTamUI.apply_flat_tab_button(back_btn, false, 17)
	back_btn.pressed.connect(_go_to_prep_and_refund)
	return back_btn


func _build_recipe_chip() -> PanelContainer:
	var chip := PanelContainer.new()
	chip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	chip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	chip.offset_left = -520.0
	chip.offset_top = 12.0
	chip.offset_right = -20.0
	chip.offset_bottom = 94.0
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", HoaTamUI.make_wood_panel_style(14.0))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	chip.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	_recipe_main_label = Label.new()
	_recipe_main_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_recipe_main_label.add_theme_font_size_override("font_size", 21)
	_recipe_main_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72))
	vbox.add_child(_recipe_main_label)

	_recipe_buff_label = Label.new()
	_recipe_buff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_recipe_buff_label.add_theme_font_size_override("font_size", 18)
	_recipe_buff_label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.62))
	vbox.add_child(_recipe_buff_label)

	return chip


func _refresh_recipe_chip() -> void:
	if _recipe_main_label == null or _recipe_buff_label == null:
		return
	var blank_name := String(GameManager.selected_blank.get("name", "Phôi Vũ Khí"))
	var mat_name := String(GameManager.selected_material.get("name", "Nguyên Liệu"))
	var rarity: int = int(GameManager.selected_material.get("rarity", 1))
	var phase_tag := "Pha 1/3 · Nung"
	match _current_phase:
		Phase.P2:
			phase_tag = "Pha 2/3 · Rèn Búa"
		Phase.P3_SEAL, Phase.P3_ANIM:
			phase_tag = "Pha 3/3 · Tôi Luyện"
	_recipe_main_label.text = "%s  |  %s • %s %s" % [phase_tag, blank_name, mat_name, "★".repeat(rarity)]

	var parts: Array[String] = []
	if _p1_tier != "":
		var t_name: String = PHASE1_TIER_NAMES.get(_p1_tier, _p1_tier)
		var mult: float = _forge1.get_multiplier(_p1_tier)
		var pct: int = int(round(absf(mult - 1.0) * 100.0))
		var sign_s := "+" if mult >= 1.0 else "−"
		parts.append("Lửa: %s (%s%d%%)" % [t_name, sign_s, pct])
	else:
		var range_txt: String = _forge1.get_profile_range_text()
		parts.append(range_txt)
		parts.append(_rarity_label(rarity))

	if _p2_prefix != "":
		var p_name: String = ForgeConverter.PREFIX_NAMES.get(_p2_prefix, _p2_prefix)
		parts.append("Rèn: %s" % p_name)
	elif _current_phase == Phase.P2:
		if _p1_tier == "do_ruc":
			parts.append("+15% Vùng Búa")
		elif _p1_tier == "lanh" or _p1_tier == "chay":
			parts.append("−15% Vùng Búa")

	_recipe_buff_label.text = "  |  ".join(parts)


func _build_indicator() -> void:
	_phase_indicator = get_node_or_null("ForgePhaseIndicator")
	if _phase_indicator != null:
		_phase_indicator.visible = false


func _update_indicator(_active: int) -> void:
	# Ẩn hộp tiến trình lớn giữa-trên để không che đầu búa/lò; trạng thái pha hiển thị gọn trên Thẻ Công Thức
	if _phase_indicator != null:
		_phase_indicator.visible = false


func _move_indicator_to_front() -> void:
	if _phase_indicator:
		move_child(_phase_indicator, get_child_count() - 1)


func _make_bronze_panel_style(bg: Color, border: Color, _radius: int = 8) -> StyleBoxFlat:
	var sb := HoaTamUI.make_inset_surface_style(bg.a, 14.0, border)
	sb.bg_color = bg
	return sb


func _build_key_prompt_badge(prompt_text: String) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxEmpty.new()
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	badge.add_theme_stylebox_override("panel", style)

	var lbl := Label.new()
	lbl.name = "PromptLabel"
	lbl.text = prompt_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.80))
	lbl.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.02, 1.0))
	lbl.add_theme_constant_override("outline_size", 6)
	badge.add_child(lbl)
	return badge


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 1 — NUNG THÉP (2 Hồ Sơ Nhiệt: Phôi Nặng vs Phôi Thanh & Phép)
# ══════════════════════════════════════════════════════════════════════════════

func _build_phase1_ui() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_p1_stage = _STAGE_SCRIPT.new()
	_p1_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_p1_stage.set_mode(_STAGE_SCRIPT.Mode.MODE_HEAT)
	root.add_child(_p1_stage)

	_p1_result_box = _build_phase1_floating_result()
	root.add_child(_p1_result_box)

	var bottom_wrap := CenterContainer.new()
	bottom_wrap.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_wrap.offset_top = -208
	bottom_wrap.offset_bottom = -16
	bottom_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom_wrap)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	bottom_wrap.add_child(vbox)

	vbox.add_child(_build_dual_heat_deck())

	_p1_instruct_badge = _build_key_prompt_badge(
		"[SPACE] Nhấp nhả Bơm Bễ giữ nhiệt trong vùng Cam / Đỏ Rực"
	)
	_p1_instruct = _p1_instruct_badge.get_node("PromptLabel") as Label
	vbox.add_child(_p1_instruct_badge)

	return root


func _build_phase1_floating_result() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.visible = false
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(540, 140)
	panel.offset_left = -270
	panel.offset_right = 270
	panel.offset_top = -70
	panel.offset_bottom = 70
	var style := HoaTamUI.make_wood_panel_style(16.0)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	_p1_result_label = Label.new()
	_p1_result_label.add_theme_font_size_override("font_size", 38)
	_p1_result_label.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	_p1_result_label.add_theme_constant_override("outline_size", 5)
	_p1_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_p1_result_label)

	_p1_mult_label = Label.new()
	_p1_mult_label.add_theme_font_size_override("font_size", 24)
	_p1_mult_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.72))
	_p1_mult_label.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	_p1_mult_label.add_theme_constant_override("outline_size", 4)
	_p1_mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_p1_mult_label)

	return panel


func _build_dual_heat_deck() -> Control:
	var deck := VBoxContainer.new()
	deck.add_theme_constant_override("separation", 10)

	# Thanh Độ Chín Thép 32-bit: ruột thép nóng pixel art + khung đồng bar_frame_9s.png bao ngoài
	var cook_wrap := Control.new()
	cook_wrap.custom_minimum_size = Vector2(_bar_width, 36.0)
	cook_wrap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	deck.add_child(cook_wrap)

	_p1_cook_bar = ProgressBar.new()
	_p1_cook_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_p1_cook_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_p1_cook_bar.offset_left = 18.0
	_p1_cook_bar.offset_right = -18.0
	_p1_cook_bar.offset_top = 8.0
	_p1_cook_bar.offset_bottom = -8.0
	_p1_cook_bar.show_percentage = false
	_p1_cook_bar.min_value = 0.0
	_p1_cook_bar.max_value = 100.0
	_p1_cook_bar.value = 0.0

	var bg_box := StyleBoxFlat.new()
	bg_box.bg_color = HoaTamUI.COL_OUTLINE
	_p1_cook_bar.add_theme_stylebox_override("background", bg_box)

	if ResourceLoader.exists(COOK_FILL_TEX_PATH):
		var fill_tex := StyleBoxTexture.new()
		fill_tex.texture = load(COOK_FILL_TEX_PATH) as Texture2D
		fill_tex.texture_margin_left = 6.0
		fill_tex.texture_margin_right = 6.0
		fill_tex.texture_margin_top = 3.0
		fill_tex.texture_margin_bottom = 3.0
		fill_tex.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		fill_tex.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		_p1_cook_bar.add_theme_stylebox_override("fill", fill_tex)
	else:
		var fallback_fill := StyleBoxFlat.new()
		fallback_fill.bg_color = HoaTamUI.COL_EMBER
		_p1_cook_bar.add_theme_stylebox_override("fill", fallback_fill)
	cook_wrap.add_child(_p1_cook_bar)

	if ResourceLoader.exists(HoaTamUI.TEX_BAR_FRAME):
		var cook_frame := NinePatchRect.new()
		cook_frame.texture = load(HoaTamUI.TEX_BAR_FRAME) as Texture2D
		cook_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cook_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cook_frame.patch_margin_left = 24
		cook_frame.patch_margin_right = 24
		cook_frame.patch_margin_top = 12
		cook_frame.patch_margin_bottom = 12
		cook_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cook_wrap.add_child(cook_frame)

	_p1_cook_label = Label.new()
	_p1_cook_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_p1_cook_label.text = "Độ chín thép: 0%"
	_p1_cook_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_cook_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_p1_cook_label.add_theme_font_size_override("font_size", 18)
	_p1_cook_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.86))
	_p1_cook_label.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	_p1_cook_label.add_theme_constant_override("outline_size", 5)
	cook_wrap.add_child(_p1_cook_label)

	_p1_heat_bar = _HEAT_BAR_SCRIPT.new()
	_p1_heat_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_p1_heat_bar.custom_minimum_size = Vector2(_bar_width, _bar_height)
	deck.add_child(_p1_heat_bar)

	var row_margin := MarginContainer.new()
	row_margin.add_theme_constant_override("margin_left", int(_HEAT_BAR_SCRIPT.FRAME_INSET_X))
	row_margin.add_theme_constant_override("margin_right", int(_HEAT_BAR_SCRIPT.FRAME_INSET_X))
	row_margin.add_theme_constant_override("margin_top", 2)
	deck.add_child(row_margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row_margin.add_child(row)

	_p1_lbl_lanh = _make_heat_zone_label("Lạnh (−30%)", 0.55, Color(0.74, 0.86, 0.98), HORIZONTAL_ALIGNMENT_CENTER)
	row.add_child(_p1_lbl_lanh)

	_p1_lbl_cam = _make_heat_zone_label("Cam (+20%)", 0.25, Color(1.0, 0.78, 0.36), HORIZONTAL_ALIGNMENT_CENTER)
	row.add_child(_p1_lbl_cam)

	_p1_lbl_do_ruc = _make_heat_zone_label("Đỏ Rực ★", 0.12, Color(1.0, 0.66, 0.24), HORIZONTAL_ALIGNMENT_CENTER)
	row.add_child(_p1_lbl_do_ruc)

	_p1_lbl_chay = _make_heat_zone_label("Cháy", 0.08, Color(1.0, 0.48, 0.38), HORIZONTAL_ALIGNMENT_RIGHT)
	row.add_child(_p1_lbl_chay)

	return deck


func _make_heat_zone_label(
	text_val: String,
	ratio: float,
	col: Color,
	align: HorizontalAlignment
) -> Label:
	var lbl := Label.new()
	lbl.text = text_val
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_stretch_ratio = ratio
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.horizontal_alignment = align
	return lbl


func _load_selected_weapon_texture() -> Texture2D:
	var sprite_path := String(GameManager.selected_blank.get("sprite_path", ""))
	if sprite_path.begins_with("res://assets/pixel/") and ResourceLoader.exists(sprite_path):
		return load(sprite_path) as Texture2D
	return null


func _go_to_phase1() -> void:
	AudioManager.stop_sfx_loop()
	if _p1_result_tween != null:
		_p1_result_tween.kill()
		_p1_result_tween = null
	_current_phase = Phase.P1
	_p1_tier = ""
	_p2_prefix = ""
	_p1_transition_pending = false
	_heat_tick_timer = 0.0
	_update_indicator(_PHASE_INDICATOR_SCRIPT.Phase.NUNG_THEP)
	if _phase_indicator != null:
		_phase_indicator.visible = false
	_p1_root.visible      = true
	_p2_root.visible      = false
	_p3_anim_root.visible = false
	_result_root.visible  = false
	if _global_back_btn:
		_global_back_btn.visible = true
	if _recipe_chip:
		_recipe_chip.visible = true

	_p1_result_box.visible = false
	_p1_result_box.modulate = Color.WHITE
	_p1_result_box.scale = Vector2.ONE
	if _p1_cook_bar != null:
		_p1_cook_bar.value = 0.0
	if _p1_cook_label != null:
		_p1_cook_label.text = "Độ chín thép: 0%"
	if _p1_stage != null:
		_p1_stage.set_mode(_STAGE_SCRIPT.Mode.MODE_HEAT)
		_p1_stage.set_blank_id(String(GameManager.selected_blank.get("id", "")))
		_p1_stage.set_weapon_texture(_load_selected_weapon_texture())
	if _p1_instruct != null:
		_p1_instruct.text = "[SPACE] Nhấp nhả Bơm Bễ giữ nhiệt trong vùng Cam / Đỏ Rực"
	_start_phase1_logic()
	_refresh_recipe_chip()


func _start_phase1_logic() -> void:
	var rarity: int = int(GameManager.selected_material.get("rarity", 1))
	var blank_id: String = String(GameManager.selected_blank.get("id", ""))
	var already_consumed := bool(GameManager.selected_material.get("materials_consumed", false))
	if not already_consumed:
		var validation_error := ForgeValidator.validate(
			GameManager.selected_blank,
			GameManager.selected_material,
			InventorySystem.materials
		)
		if validation_error != "":
			if _p1_instruct != null:
				_p1_instruct.text = validation_error
				_p1_instruct.add_theme_color_override("font_color", COLOR_MISS)
			push_warning("[ForgeValidator] " + validation_error)
			return
	_forge1.start_phase(GameManager.reputation, rarity, blank_id)
	_update_heat_zones()


func _update_heat_zones() -> void:
	var low_frac: float  = float(_forge1.sweet_spot_low)  / 100.0
	var peak_frac: float = float(_forge1.sweet_spot_peak) / 100.0
	var burn_frac: float = float(_forge1.burn_point)      / 100.0

	_p1_heat_bar.set_thresholds(low_frac, peak_frac, burn_frac)

	_p1_lbl_lanh.size_flags_stretch_ratio   = maxf(0.10, low_frac)
	_p1_lbl_cam.size_flags_stretch_ratio    = maxf(0.10, peak_frac - low_frac)
	_p1_lbl_do_ruc.size_flags_stretch_ratio = maxf(0.08, burn_frac - peak_frac)
	_p1_lbl_chay.size_flags_stretch_ratio   = maxf(0.06, 1.0 - burn_frac)
	_p1_lbl_do_ruc.text = "Đỏ Rực ★"


func _highlight_active_heat_zone(h: float) -> void:
	var active_idx := 0
	if h > float(_forge1.burn_point):
		active_idx = 3
	elif h >= float(_forge1.sweet_spot_peak):
		active_idx = 2
	elif h >= float(_forge1.sweet_spot_low):
		active_idx = 1

	var labels: Array[Label] = [_p1_lbl_lanh, _p1_lbl_cam, _p1_lbl_do_ruc, _p1_lbl_chay]
	for i in range(labels.size()):
		var lbl := labels[i]
		if lbl == null:
			continue
		if i == active_idx:
			lbl.modulate = Color(1.25, 1.18, 0.95, 1.0)
		else:
			lbl.modulate = Color(0.72, 0.68, 0.64, 0.62)


func _on_phase1_done(tier: String) -> void:
	if _current_phase != Phase.P1:
		return
	AudioManager.stop_sfx_loop()
	var p1_min := String(GameManager.selected_material.get("phase1_min", ""))
	if p1_min == "do_ruc" and tier != "chay":
		tier = "do_ruc"
	elif p1_min == "cam" and tier == "lanh":
		tier = "cam"
	_p1_tier = tier
	_p1_transition_pending = true
	_refresh_recipe_chip()

	match tier:
		"cam", "do_ruc":
			AudioManager.play_sfx_key("skill_fire")
		"chay":
			AudioManager.play_sfx_key("player_hurt")

	var mult:     float = _forge1.get_multiplier(tier)
	var pct:      int   = int(round(absf(mult - 1.0) * 100.0))
	var sign_str: String = "+" if mult >= 1.0 else "−"
	var tier_name: String = PHASE1_TIER_NAMES.get(tier, tier)

	_p1_result_label.text = "%s" % tier_name
	_p1_mult_label.text   = "Chỉ số: ×%.1f (%s%d%%)  •  Chuyển sang Đe Rèn..." % [
		mult, sign_str, pct
	]
	if _p1_instruct != null:
		_p1_instruct.text = "[SPACE] Chuyển ngay sang Rèn Búa  →"

	var tier_color := Color.WHITE
	match tier:
		"lanh":   tier_color = Color(0.6, 0.72, 0.95)
		"cam":    tier_color = Color(0.95, 0.62, 0.18)
		"do_ruc": tier_color = Color(1.0, 0.48, 0.08)
		"chay":   tier_color = Color(0.75, 0.32, 0.18)
	_p1_result_label.add_theme_color_override("font_color", tier_color)

	_p1_result_box.visible = true
	_p1_result_box.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_p1_result_box.scale = Vector2(0.88, 0.88)
	_p1_result_box.pivot_offset = _p1_result_box.custom_minimum_size * 0.5
	if _p1_result_tween != null:
		_p1_result_tween.kill()
	_p1_result_tween = create_tween()
	_p1_result_tween.set_parallel(true)
	_p1_result_tween.tween_property(_p1_result_box, "modulate:a", 1.0, 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_p1_result_tween.tween_property(_p1_result_box, "scale", Vector2.ONE, 0.24) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_p1_result_tween.chain().tween_interval(1.15)
	_p1_result_tween.chain().tween_callback(_go_to_phase2)


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 2 — RÈN BÚA 2 HƯỚNG "CƯƠNG / NHU" TẤT ĐỊNH
# ══════════════════════════════════════════════════════════════════════════════

func _build_phase2_ui() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_p2_stage = _STAGE_SCRIPT.new()
	_p2_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_p2_stage.set_mode(_STAGE_SCRIPT.Mode.MODE_ANVIL)
	root.add_child(_p2_stage)

	_p2_feedback_label = Label.new()
	_p2_feedback_label.text = ""
	_p2_feedback_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_p2_feedback_label.offset_left = -360
	_p2_feedback_label.offset_right = 360
	_p2_feedback_label.offset_top = 112
	_p2_feedback_label.offset_bottom = 182
	_p2_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p2_feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_p2_feedback_label.add_theme_font_size_override("font_size", 46)
	_p2_feedback_label.add_theme_color_override("font_outline_color", Color(0.06, 0.03, 0.01, 0.95))
	_p2_feedback_label.add_theme_constant_override("outline_size", 6)
	root.add_child(_p2_feedback_label)

	var bottom_wrap := CenterContainer.new()
	bottom_wrap.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_wrap.offset_top = -202
	bottom_wrap.offset_bottom = -16
	bottom_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom_wrap)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	bottom_wrap.add_child(vbox)

	var beat_deck := VBoxContainer.new()
	beat_deck.add_theme_constant_override("separation", 10)
	beat_deck.add_child(_build_strike_badges_row())

	_p2_beat_bar = _BEAT_BAR_SCRIPT.new()
	_p2_beat_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_p2_beat_bar.custom_minimum_size = Vector2(_bar_width, _bar_height)
	beat_deck.add_child(_p2_beat_bar)
	vbox.add_child(beat_deck)

	vbox.add_child(
		_build_key_prompt_badge(
			"[Space/Trái] Búa Cương (Công/Thủ)  ·  [Enter/Phải] Búa Nhu (Tốc/Linh)"
		)
	)

	return root


func _build_strike_badges_row() -> HBoxContainer:
	_p2_strike_badges.clear()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	for i in 5:
		var badge := PanelContainer.new()
		badge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		badge.custom_minimum_size = Vector2(72, 54)
		badge.add_theme_stylebox_override("panel", _make_pixel_slot_style(HoaTamUI.SlotState.EMPTY))

		var hb := HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_theme_constant_override("separation", 4)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(hb)

		var icon := TextureRect.new()
		icon.name = "HammerIcon"
		icon.visible = false
		icon.custom_minimum_size = Vector2(26, 26)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(icon)

		var lbl := Label.new()
		lbl.name = "BadgeLabel"
		lbl.text = str(i + 1)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color(0.74, 0.66, 0.54))
		lbl.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
		lbl.add_theme_constant_override("outline_size", 4)
		hb.add_child(lbl)

		row.add_child(badge)
		_p2_strike_badges.append(badge)
	return row


func _make_pixel_slot_style(
	slot_state: HoaTamUI.SlotState,
	tint: Color = Color.WHITE
) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = HoaTamUI.get_slot_texture(slot_state)
	s.texture_margin_left = 18.0
	s.texture_margin_right = 18.0
	s.texture_margin_top = 18.0
	s.texture_margin_bottom = 18.0
	s.content_margin_left = 6.0
	s.content_margin_right = 6.0
	s.content_margin_top = 4.0
	s.content_margin_bottom = 4.0
	s.modulate_color = tint
	return s


func _reset_strike_badges() -> void:
	for i in _p2_strike_badges.size():
		var badge := _p2_strike_badges[i]
		badge.scale = Vector2.ONE
		badge.add_theme_stylebox_override("panel", _make_pixel_slot_style(HoaTamUI.SlotState.EMPTY))
		var icon := badge.find_child("HammerIcon", true, false) as TextureRect
		if icon != null:
			icon.visible = false
			icon.texture = null
		var lbl := badge.find_child("BadgeLabel", true, false) as Label
		if lbl != null:
			lbl.text = str(i + 1)
			lbl.add_theme_color_override("font_color", Color(0.74, 0.66, 0.54))


func _highlight_current_strike_badge(active_idx: int) -> void:
	if active_idx < 0 or active_idx >= _p2_strike_badges.size():
		return
	var badge := _p2_strike_badges[active_idx]
	badge.add_theme_stylebox_override("panel", _make_pixel_slot_style(HoaTamUI.SlotState.SELECTED))
	var lbl := badge.find_child("BadgeLabel", true, false) as Label
	if lbl != null:
		lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72))


func _update_strike_badge(idx: int, result: int, style: String) -> void:
	if idx < 0 or idx >= _p2_strike_badges.size():
		return
	var badge := _p2_strike_badges[idx]
	var icon := badge.find_child("HammerIcon", true, false) as TextureRect
	var lbl := badge.find_child("BadgeLabel", true, false) as Label
	var is_nhu := (style == _FORGE2_SCRIPT.STYLE_NHU)
	var is_cuong := (style == _FORGE2_SCRIPT.STYLE_CUONG)

	if icon != null:
		if is_nhu:
			icon.texture = HoaTamUI.get_combat_icon(HoaTamUI.CombatIcon.HAMMER_NHU)
			icon.visible = true
		elif is_cuong:
			icon.texture = HoaTamUI.get_combat_icon(HoaTamUI.CombatIcon.HAMMER_CUONG)
			icon.visible = true
		else:
			icon.visible = false

	var slot_tint := (
		Color(0.68, 0.94, 1.05, 1.0) if is_nhu
		else (Color(1.12, 0.82, 0.62, 1.0) if is_cuong else Color(0.92, 0.55, 0.52, 1.0))
	)
	var border_col := COLOR_NHU if is_nhu else (COLOR_CUONG if is_cuong else COLOR_MISS)

	match result:
		_forge2.HitResult.PERFECT:
			badge.add_theme_stylebox_override(
				"panel", _make_pixel_slot_style(HoaTamUI.SlotState.SELECTED, slot_tint)
			)
			if lbl != null:
				lbl.text = "★"
				lbl.add_theme_color_override(
					"font_color", COLOR_PERFECT if is_cuong else Color(0.76, 0.98, 1.0)
				)
		_forge2.HitResult.GOOD:
			badge.add_theme_stylebox_override(
				"panel", _make_pixel_slot_style(HoaTamUI.SlotState.FILLED, slot_tint)
			)
			if lbl != null:
				lbl.text = "◆"
				lbl.add_theme_color_override("font_color", border_col.lightened(0.20))
		_:
			badge.add_theme_stylebox_override(
				"panel",
				_make_pixel_slot_style(HoaTamUI.SlotState.LOCKED, Color(1.0, 0.52, 0.48, 1.0))
			)
			if lbl != null:
				lbl.text = "✕"
				lbl.add_theme_color_override("font_color", COLOR_MISS)


func _go_to_phase2() -> void:
	AudioManager.stop_sfx_loop()
	if _p1_result_tween != null:
		_p1_result_tween.kill()
		_p1_result_tween = null
	if _p2_feedback_tween != null:
		_p2_feedback_tween.kill()
		_p2_feedback_tween = null
	_p1_transition_pending = false
	_current_phase = Phase.P2
	_update_indicator(_PHASE_INDICATOR_SCRIPT.Phase.REN_BUA)
	_p1_root.visible      = false
	_p2_root.visible      = true
	_p2_root.modulate     = Color(1, 1, 1, 0)
	create_tween().tween_property(_p2_root, "modulate:a", 1.0, 0.22)
	_p3_anim_root.visible = false
	_result_root.visible  = false
	if _global_back_btn:
		_global_back_btn.visible = true
	if _recipe_chip:
		_recipe_chip.visible = true
	_refresh_recipe_chip()

	if _p2_stage != null:
		_p2_stage.set_mode(_STAGE_SCRIPT.Mode.MODE_ANVIL)
		_p2_stage.set_blank_id(String(GameManager.selected_blank.get("id", "")))
		_p2_stage.set_weapon_texture(_load_selected_weapon_texture())
		_p2_stage.set_beat_state(0.0, 0.55, 0, _forge2.TOTAL_STRIKES)
	_p2_feedback_label.text = ""
	_p2_feedback_label.scale = Vector2.ONE
	_reset_strike_badges()
	_start_phase2_logic()


func _start_phase2_logic() -> void:
	var rarity: int = int(GameManager.selected_material.get("rarity", 1))
	var window_scale: float
	var beat_dur: float
	match rarity:
		1:
			window_scale = 1.00
			beat_dur = 1.50
		2:
			window_scale = 0.70
			beat_dur = 1.15
		3:
			window_scale = 0.45
			beat_dur = 0.85
		_:
			window_scale = 1.00
			beat_dur = 1.50

	var p1_bonus: float = _forge1.get_perfect_bonus_for_phase2(_p1_tier)
	window_scale = maxf(0.20, window_scale + p1_bonus)
	_forge2.start_phase(window_scale, beat_dur, rarity)


func _on_beat_started(beat_index: int, perfect_center: float) -> void:
	if _current_phase != Phase.P2:
		return
	_highlight_current_strike_badge(beat_index)

	var good_w: float = _forge2.GOOD_HALF_WIDTH    * _forge2.window_scale
	var perf_w: float = _forge2.PERFECT_HALF_WIDTH * _forge2.window_scale
	_p2_beat_bar.set_zones(perfect_center, good_w, perf_w)
	_p2_beat_bar.progress = _forge2.beat_progress


func _on_strike_resolved(result: int, idx: int, _running_score: int) -> void:
	if _current_phase != Phase.P2:
		return
	var style: String = String(_forge2.last_strike_style)
	var is_nhu := (style == _FORGE2_SCRIPT.STYLE_NHU)
	var style_name := "NHU" if is_nhu else ("CƯƠNG" if style == _FORGE2_SCRIPT.STYLE_CUONG else "")
	var style_pitch := 1.12 if is_nhu else 0.92

	_update_strike_badge(idx, result, style)

	var combo: int = _forge2.get_combo_count()
	if _p2_stage != null:
		_p2_stage.set_combo_count(combo)
		_p2_stage.trigger_strike(result, style)

	var feedback_pop := 1.18
	var badge_pop := 1.22
	var style_col := COLOR_NHU if is_nhu else COLOR_CUONG
	match result:
		_forge2.HitResult.PERFECT:
			if combo >= 2:
				_p2_feedback_label.text = "★ PERFECT %s! COMBO x%d" % [style_name, combo]
				feedback_pop = 1.36 + minf(0.18, float(combo) * 0.04)
			else:
				_p2_feedback_label.text = "★ PERFECT %s!" % style_name
				feedback_pop = 1.26
			_p2_feedback_label.add_theme_color_override(
				"font_color", Color(0.66, 0.96, 1.0) if is_nhu else COLOR_PERFECT
			)
			_p2_beat_bar.flash_result(style_col)
			AudioManager.play_sfx_key("hammer_perfect", 1.0, style_pitch)
			badge_pop = 1.30
		_forge2.HitResult.GOOD:
			_p2_feedback_label.text = "◆ GOOD · %s" % style_name
			_p2_feedback_label.add_theme_color_override("font_color", style_col.lightened(0.16))
			_p2_beat_bar.flash_result(style_col)
			AudioManager.play_sfx_key("hammer_good", 0.95, style_pitch)
			feedback_pop = 1.16
			badge_pop = 1.22
		_forge2.HitResult.MISS:
			_p2_feedback_label.text = "✕ MISS"
			_p2_feedback_label.add_theme_color_override("font_color", COLOR_MISS)
			_p2_beat_bar.flash_result(COLOR_MISS)
			AudioManager.play_sfx_key("hammer_miss", 0.90, style_pitch)
			feedback_pop = 1.10
			badge_pop = 1.14

	if _p2_feedback_tween != null:
		_p2_feedback_tween.kill()
	_p2_feedback_label.pivot_offset = _p2_feedback_label.size * 0.5
	_p2_feedback_label.scale = Vector2(feedback_pop, feedback_pop)
	_p2_feedback_label.modulate = Color.WHITE
	_p2_feedback_tween = create_tween()
	_p2_feedback_tween.set_parallel(true)
	_p2_feedback_tween.tween_property(_p2_feedback_label, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_p2_feedback_tween.chain().tween_interval(0.38)
	_p2_feedback_tween.chain().tween_property(_p2_feedback_label, "modulate:a", 0.0, 0.20)

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
	_refresh_recipe_chip()
	_go_to_phase3_seal()


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 3 — NHỊP 3A (CHỌN 6 ẤN LINH LỰC) & NHỊP 3B (CĂN NHỊP NHÚNG NƯỚC)
# ══════════════════════════════════════════════════════════════════════════════

func _build_phase3_anim_ui() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_p3_stage = _STAGE_SCRIPT.new()
	_p3_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_p3_stage.set_mode(_STAGE_SCRIPT.Mode.MODE_QUENCH)
	_p3_stage.quench_water_impact.connect(_on_quench_water_impact)
	_p3_stage.quench_sequence_finished.connect(_on_quench_sequence_finished)
	root.add_child(_p3_stage)

	_p3_perfect_banner = PanelContainer.new()
	_p3_perfect_banner.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_p3_perfect_banner.visible = false
	_p3_perfect_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_p3_perfect_banner.custom_minimum_size = Vector2(560, 58)
	_p3_perfect_banner.offset_left = -280
	_p3_perfect_banner.offset_right = 280
	_p3_perfect_banner.offset_top = 18
	_p3_perfect_banner.offset_bottom = 76
	_p3_perfect_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_p3_perfect_banner.add_theme_stylebox_override("panel", HoaTamUI.make_wood_panel_style(12.0))

	var banner_lbl := Label.new()
	banner_lbl.text = "★ TÔI HOÀN HẢO (+10% Giá · +10 Bền)"
	banner_lbl.add_theme_font_size_override("font_size", 26)
	banner_lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.42))
	banner_lbl.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	banner_lbl.add_theme_constant_override("outline_size", 5)
	banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p3_perfect_banner.add_child(banner_lbl)
	root.add_child(_p3_perfect_banner)

	var bottom_wrap := CenterContainer.new()
	bottom_wrap.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_wrap.offset_top = -74
	bottom_wrap.offset_bottom = -20
	bottom_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom_wrap)

	_p3_instruct_badge = _build_key_prompt_badge(
		"[Space / Chuột Trái] Nhúng Tôi khi Vòng Cổ Ngữ hội tụ tâm vàng"
	)
	_p3_instruct = _p3_instruct_badge.get_node("PromptLabel") as Label
	bottom_wrap.add_child(_p3_instruct_badge)

	# Nhịp 3A Overlay: Phủ tối nhẹ alpha=0.46 (lộ rõ thùng gỗ ở giữa) + Thẻ Bài Linh Lực
	_p3_seal_overlay = _build_phase3_seal_overlay()
	root.add_child(_p3_seal_overlay)

	return root


func _build_phase3_seal_overlay() -> Control:
	var overlay := Control.new()
	overlay.name = "Phase3SealOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false

	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.03, 0.02, 0.02, 0.46)
	overlay.add_child(veil)

	var title := Label.new()
	title.text = "KHẮC ẤN LINH LỰC TẠI BỂ TÔI"
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -420
	title.offset_right = 420
	title.offset_top = 62
	title.offset_bottom = 112
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.44))
	title.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	title.add_theme_constant_override("outline_size", 6)
	overlay.add_child(title)

	var sub := Label.new()
	sub.name = "SealSubLabel"
	sub.text = "Bấm phím số hoặc Click chọn Thẻ Linh Lực hợp chất liệu"
	sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sub.offset_left = -520
	sub.offset_right = 520
	sub.offset_top = 116
	sub.offset_bottom = 150
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.92, 0.84, 0.68))
	sub.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	sub.add_theme_constant_override("outline_size", 4)
	overlay.add_child(sub)

	# Khung chứa các Thẻ Bài Linh Lực 32-bit (5x native = 280x380, chỉ hiện các hệ dẫn được)
	var arc_holder := Control.new()
	arc_holder.name = "SealArcHolder"
	arc_holder.set_anchors_preset(Control.PRESET_CENTER)
	arc_holder.offset_left = -880
	arc_holder.offset_right = 880
	arc_holder.offset_top = -270
	arc_holder.offset_bottom = 260
	overlay.add_child(arc_holder)

	var sheet: Texture2D = null
	if ResourceLoader.exists(ELEMENT_SEALS_SHEET_PATH):
		sheet = load(ELEMENT_SEALS_SHEET_PATH) as Texture2D
	var card_tex: Texture2D = null
	if ResourceLoader.exists(ELEMENT_CARD_TEX_PATH):
		card_tex = load(ELEMENT_CARD_TEX_PATH) as Texture2D
	var glow_tex: Texture2D = null
	if ResourceLoader.exists(CARD_GLOW_TEX_PATH):
		glow_tex = load(CARD_GLOW_TEX_PATH) as Texture2D

	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	_p3_seal_buttons.clear()
	_p3_seal_base_y.clear()
	var card_w := 280.0
	var card_h := 380.0

	for idx in range(ELEMENT_ORDER.size()):
		var elem_key: String = ELEMENT_ORDER[idx]
		var elem_data: Dictionary = _FORGE3_SCRIPT.ELEMENTS[elem_key]
		var elem_col: Color = elem_data["color"]
		var elem_name: String = String(elem_data["name"])
		var suffix_name: String = _FORGE3_SCRIPT.SUFFIX_NAMES.get(String(elem_data["suffix"]), "")

		var card_root := Control.new()
		card_root.name = "Card_" + elem_key
		card_root.size = Vector2(card_w, card_h)
		card_root.pivot_offset = Vector2(card_w * 0.5, card_h * 0.5)
		card_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		card_root.visible = false
		arc_holder.add_child(card_root)

		# Lớp hào quang Glowing 32-bit phát sáng quanh mép thẻ (5x native = 320x420)
		var glow := TextureRect.new()
		glow.name = "CardGlow"
		glow.texture = glow_tex
		glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		glow.material = add_mat
		glow.position = Vector2(-20.0, -20.0)
		glow.size = Vector2(card_w + 40.0, card_h + 40.0)
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.stretch_mode = TextureRect.STRETCH_SCALE
		glow.modulate = Color(elem_col.r, elem_col.g, elem_col.b, 0.78)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_root.add_child(glow)

		# Thân lá bài 32-bit cổ điển
		var card_bg := TextureRect.new()
		card_bg.name = "CardFrame"
		card_bg.texture = card_tex
		card_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		card_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_bg.stretch_mode = TextureRect.STRETCH_SCALE
		card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_root.add_child(card_bg)

		# Nút tương tác phủ trọn thẻ bài
		var btn := Button.new()
		btn.name = "CardButton"
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		_setup_button(btn)
		btn.pressed.connect(_on_phase3_seal_chosen.bind(elem_key))
		btn.mouse_entered.connect(_on_phase3_card_hover.bind(elem_key, true))
		btn.mouse_exited.connect(_on_phase3_card_hover.bind(elem_key, false))
		card_root.add_child(btn)

		# Nhãn phím tắt & dấu đơn hàng trên đỉnh thẻ
		var key_lbl := Label.new()
		key_lbl.name = "KeyLabel"
		key_lbl.text = "[%d]" % (idx + 1)
		key_lbl.position = Vector2(20.0, 26.0)
		key_lbl.size = Vector2(card_w - 40.0, 34.0)
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_lbl.add_theme_font_size_override("font_size", 24)
		key_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.62))
		key_lbl.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
		key_lbl.add_theme_constant_override("outline_size", 5)
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_root.add_child(key_lbl)

		# Huân chương nguyên tố 32-bit (2x của 64x64 = 128x128) nằm gọn trong vòng tròn cổ ngữ giữa thẻ
		var icon := TextureRect.new()
		icon.name = "SealIcon"
		icon.position = Vector2((card_w - 128.0) * 0.5, 102.0)
		icon.size = Vector2(128.0, 128.0)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if sheet != null:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(float(idx * 64), 0.0, 64.0, 64.0)
			icon.texture = atlas
		card_root.add_child(icon)

		# Tên nguyên tố & Hậu tố nằm dưới vạch đồng ngang
		var name_lbl := Label.new()
		name_lbl.text = elem_name
		name_lbl.position = Vector2(16.0, 274.0)
		name_lbl.size = Vector2(card_w - 32.0, 42.0)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 34)
		name_lbl.add_theme_color_override("font_color", elem_col.lightened(0.32))
		name_lbl.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
		name_lbl.add_theme_constant_override("outline_size", 6)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_root.add_child(name_lbl)

		var suf_lbl := Label.new()
		suf_lbl.text = suffix_name
		suf_lbl.position = Vector2(16.0, 320.0)
		suf_lbl.size = Vector2(card_w - 32.0, 30.0)
		suf_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		suf_lbl.add_theme_font_size_override("font_size", 20)
		suf_lbl.add_theme_color_override("font_color", Color(0.90, 0.84, 0.72))
		suf_lbl.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
		suf_lbl.add_theme_constant_override("outline_size", 4)
		suf_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_root.add_child(suf_lbl)

		_p3_seal_buttons[elem_key] = card_root
		_p3_seal_base_y[elem_key] = 66.0

	# Nút bên dưới: [0 / Space] Tôi Nước Thuần (nút đồng 9-slice 32-bit, không giữ focus)
	_p3_pure_water_btn = Button.new()
	_p3_pure_water_btn.text = "[0 / Space] Tôi Nước Thuần (Không khắc hệ)"
	_p3_pure_water_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_p3_pure_water_btn.offset_left = -246
	_p3_pure_water_btn.offset_right = 246
	_p3_pure_water_btn.offset_top = -78
	_p3_pure_water_btn.offset_bottom = -24
	_setup_button(_p3_pure_water_btn)
	HoaTamUI.apply_secondary_button(_p3_pure_water_btn, 20)
	_p3_pure_water_btn.pressed.connect(_on_phase3_seal_chosen.bind(""))
	overlay.add_child(_p3_pure_water_btn)

	return overlay


func _on_phase3_card_hover(elem_key: String, entered: bool) -> void:
	if entered:
		_p3_seal_hovered = elem_key
	elif _p3_seal_hovered == elem_key:
		_p3_seal_hovered = ""


func _go_to_phase3_seal() -> void:
	AudioManager.stop_sfx_loop()
	_current_phase = Phase.P3_SEAL
	_seal_pulse_time = 0.0
	_p3_seal_hovered = ""
	_update_indicator(_PHASE_INDICATOR_SCRIPT.Phase.TOI_LUYEN)
	_p1_root.visible      = false
	_p2_root.visible      = false
	_p3_anim_root.visible = true
	_p3_anim_root.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(_p3_anim_root, "modulate:a", 1.0, 0.22)
	_result_root.visible  = false
	if _global_back_btn:
		_global_back_btn.visible = true
	if _recipe_chip:
		_recipe_chip.visible = true
	_refresh_recipe_chip()

	if _p3_perfect_banner != null:
		_p3_perfect_banner.visible = false
	if _p3_instruct_badge != null:
		_p3_instruct_badge.visible = false
	if _p3_stage != null:
		_p3_stage.set_mode(_STAGE_SCRIPT.Mode.MODE_QUENCH)
		_p3_stage.set_blank_id(String(GameManager.selected_blank.get("id", "")))
		_p3_stage.set_weapon_texture(_load_selected_weapon_texture())

	# CHỈ HIỆN những nguyên tố mà nguyên liệu hiện tại có thể dẫn (ẩn hoàn toàn nguyên tố bị khóa)
	var allowed: Array = Array(
		GameManager.selected_material.get("allowed_elements", ["hoa", "phong", "tho"])
	)
	var comm_elem := _get_active_commission_element()
	_p3_visible_elements.clear()
	for elem_key: String in ELEMENT_ORDER:
		var card: Control = _p3_seal_buttons.get(elem_key, null)
		if card == null:
			continue
		if elem_key in allowed:
			_p3_visible_elements.append(elem_key)
			card.visible = true
		else:
			card.visible = false

	# Xếp các thẻ bài hợp lệ theo hình quạt cân đối chính giữa màn hình (280x380, thoáng rộng)
	var count := _p3_visible_elements.size()
	var card_w := 280.0
	var center_x := 880.0
	var base_y := 58.0
	var spacing := 380.0 if count <= 3 else (350.0 if count == 4 else 296.0)
	var total_span := spacing * float(maxi(0, count - 1))

	for i in range(count):
		var elem_key: String = _p3_visible_elements[i]
		var card: Control = _p3_seal_buttons[elem_key]
		var norm := 0.0 if count <= 1 else (float(i) / float(count - 1) * 2.0 - 1.0)
		var px := center_x - total_span * 0.5 + float(i) * spacing - card_w * 0.5
		var arc_drop := norm * norm * (34.0 if count >= 3 else 0.0)
		var py := base_y + arc_drop
		var rot := norm * (0.065 if count >= 3 else 0.0)

		card.position = Vector2(px, py)
		card.rotation = rot
		card.scale = Vector2.ONE
		card.z_index = i
		_p3_seal_base_y[elem_key] = py
		_p3_seal_base_rot[elem_key] = rot

		var key_lbl := card.find_child("KeyLabel", true, false) as Label
		if key_lbl != null:
			var star := " ★ ĐƠN" if (comm_elem != "" and comm_elem == elem_key) else ""
			key_lbl.text = "[%d]%s" % [i + 1, star]

	var sub_lbl := _p3_seal_overlay.find_child("SealSubLabel", true, false) as Label
	if sub_lbl != null:
		if count > 0:
			sub_lbl.text = "Bấm [1..%d] hoặc Click chọn Thẻ Linh Lực hợp chất liệu" % count
		else:
			sub_lbl.text = "Nguyên liệu này chỉ tôi bằng Nước Thuần [0 / Space]"

	if _p3_seal_overlay != null:
		_p3_seal_overlay.visible = true
		_p3_seal_overlay.modulate = Color(1, 1, 1, 0)
		create_tween().tween_property(_p3_seal_overlay, "modulate:a", 1.0, 0.22)


func _get_active_commission_element() -> String:
	var comm_sys := get_node_or_null("/root/CommissionSystem")
	if comm_sys == null or not comm_sys.has_method("get_active"):
		return ""
	for c in comm_sys.get_active():
		if c != null and not String(c.get("req_element")).is_empty():
			return String(c.get("req_element"))
	return ""


func _on_phase3_seal_chosen(element_key: String) -> void:
	if _current_phase != Phase.P3_SEAL:
		return
	if element_key != "":
		var allowed: Array = Array(
			GameManager.selected_material.get("allowed_elements", ["hoa", "phong", "tho"])
		)
		if not (element_key in allowed):
			return
	GameManager.selected_element = element_key
	AudioManager.play_sfx_key("zone_prompt", 0.80, 1.08 if element_key != "" else 0.92)

	if _p3_seal_overlay != null:
		var tw := create_tween()
		tw.tween_property(_p3_seal_overlay, "modulate:a", 0.0, 0.18)
		tw.tween_callback(func() -> void:
			_p3_seal_overlay.visible = false
		)
	_start_phase3_quench(element_key)


func _start_phase3_quench(element_key: String) -> void:
	_forge3.start_phase(element_key)
	_current_phase = Phase.P3_ANIM
	_p3_element_key = element_key
	_p3_quench_pressed = false
	_p3_is_perfect = false
	_p3_input_lock = 0.16
	_p1_root.visible = false
	_p2_root.visible = false
	_p3_anim_root.visible = true
	_result_root.visible = false

	# Ẩn nút quay lại khi đã vào nhịp nhúng nước để tránh bấm nhầm thoát giữa chừng
	if _global_back_btn != null:
		_global_back_btn.visible = false
	if _p3_perfect_banner != null:
		_p3_perfect_banner.visible = false
	if _p3_instruct_badge != null:
		_p3_instruct_badge.visible = true
	if _p3_instruct != null:
		_p3_instruct.text = "[Space / Chuột Trái] Nhúng Tôi khi Vòng Cổ Ngữ hội tụ tâm vàng"
		_p3_instruct.add_theme_color_override("font_color", Color(0.96, 0.88, 0.68))

	var elem: Dictionary = _forge3.get_element_data(element_key)
	var elem_color: Color = elem.get("color", _FORGE3_SCRIPT.PURE_WATER_COLOR)
	var dur: float = _forge3.QUENCH_DURATION
	var weapon_tex := _load_selected_weapon_texture()

	if _p3_stage != null:
		_p3_stage.set_mode(_STAGE_SCRIPT.Mode.MODE_QUENCH)
		_p3_stage.set_blank_id(String(GameManager.selected_blank.get("id", "")))
		_p3_stage.set_weapon_texture(weapon_tex)
		_p3_stage.start_quench_sequence(elem_color, dur)


func _handle_quench_press() -> void:
	if _p3_quench_pressed or _p3_input_lock > 0.0 or _current_phase != Phase.P3_ANIM:
		return
	_p3_quench_pressed = true
	var is_perfect: bool = _forge3.try_quench_press()
	_p3_is_perfect = is_perfect
	if _p3_stage != null:
		_p3_stage.trigger_quench_plunge(is_perfect)
	if is_perfect:
		# Ẩn dòng hướng dẫn dưới khi đã hiện banner Tôi Hoàn Hảo trên đỉnh (tránh lặp thông tin)
		if _p3_instruct_badge != null:
			_p3_instruct_badge.visible = false
	else:
		if _p3_instruct != null:
			_p3_instruct.text = "Tôi Luyện Tiêu Chuẩn — Giữ nguyên độ bền 50/50"
			_p3_instruct.add_theme_color_override("font_color", Color(0.78, 0.74, 0.68))


func _on_quench_water_impact(is_perfect: bool) -> void:
	AudioManager.play_sfx_key("quench_sizzle", 0.92, 1.05 if is_perfect else 0.94)
	if is_perfect:
		AudioManager.play_sfx_key("hammer_perfect", 1.08)
		_show_perfect_quench_banner()


func _show_perfect_quench_banner() -> void:
	if _p3_perfect_banner == null:
		return
	_p3_perfect_banner.visible = true
	_p3_perfect_banner.pivot_offset = _p3_perfect_banner.custom_minimum_size * 0.5
	_p3_perfect_banner.scale = Vector2(0.78, 0.78)
	_p3_perfect_banner.modulate = Color(1.2, 1.12, 0.75, 0.0)
	var btw := create_tween().set_parallel(true)
	btw.tween_property(_p3_perfect_banner, "scale", Vector2.ONE, 0.24) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	btw.tween_property(_p3_perfect_banner, "modulate", Color.WHITE, 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_quench_sequence_finished() -> void:
	if _current_phase != Phase.P3_ANIM:
		return
	_finish_quench(_p3_element_key)


func _finish_quench(_element_key: String) -> void:
	AudioManager.play_sfx_key("weapon_reveal", 0.78)
	var final_perfect := _p3_is_perfect or bool(_forge3.get("perfect_quench"))
	var result: Dictionary = _forge3.complete(_p1_tier, _p2_prefix, final_perfect)
	result["perfect_quench"] = final_perfect
	result["durability_bonus"] = 10 if final_perfect else 0

	var blank: Dictionary = GameManager.selected_blank
	var mat:   Dictionary = GameManager.selected_material
	result["blank_id"]          = blank.get("id",         "")
	result["weapon_type"]       = blank.get("name",       "Vũ Khí")
	result["sprite_path"]       = String(blank.get("sprite_path", ""))
	result["base_atk"]          = int(blank.get("atk", 10)) + int(mat.get("atk_bonus", 0))
	result["base_def"]          = int(blank.get("def", 0)) + int(mat.get("def_bonus", 0))
	result["base_magic"]        = int(blank.get("magic", 3)) + int(mat.get("magic_bonus", 0))
	result["base_speed"]        = int(blank.get("speed", 5)) + int(mat.get("speed_bonus", 0))
	result["innate_skill_id"]   = blank.get("skill",       "")
	result["innate_skill"]      = blank.get("skill_name",  blank.get("skill", ""))
	result["innate_skill_desc"] = blank.get("skill_desc",  "")
	result["material_name"]     = mat.get("name",          "")

	var rarity_price_table := {1: 0.5, 2: 1.0, 3: 1.6}
	var material_rarity: int = int(mat.get("rarity", 1))
	result["material_rarity"] = material_rarity
	result["rarity_tier"] = ForgeConverter.PREFIX_RARITY.get(_p2_prefix, 2)
	var base_mult: float = float(rarity_price_table.get(material_rarity, 1.0)) * float(mat.get("price_mult", 1.0))
	if final_perfect:
		base_mult *= 1.10
	result["price_mult"] = base_mult
	_show_result(result)


# ══════════════════════════════════════════════════════════════════════════════
# RESULT — THẺ THÀNH PHẨM + THANH HÀNH ĐỘNG 1 TẦNG GỌN RÕ (TỐI ĐA 3 NÚT)
# ══════════════════════════════════════════════════════════════════════════════

func _build_result_ui() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Nền tối ấm phủ nhẹ tách biệt Thẻ Thành Phẩm khỏi sân khấu bể nước phía sau
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = HoaTamUI.COL_DIM_BG
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 44)
	margin.add_theme_constant_override("margin_bottom", 34)
	root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	var card_wrap := CenterContainer.new()
	card_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_wrap.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	vbox.add_child(card_wrap)

	_weapon_card = _CARD_SCENE.instantiate()
	var vp := get_viewport_rect().size
	var card_w := 1160.0
	var card_h := 680.0
	var card_fit := minf(1.0, minf((vp.x - 96.0) / card_w, (vp.y - 220.0) / card_h))
	if card_fit < 0.99:
		var card_holder := Control.new()
		card_holder.custom_minimum_size = Vector2(card_w * card_fit, card_h * card_fit)
		_weapon_card.scale = Vector2(card_fit, card_fit)
		card_holder.add_child(_weapon_card)
		card_wrap.add_child(card_holder)
	else:
		card_wrap.add_child(_weapon_card)

	# Thanh hành động 1 tầng duy nhất:
	# - Trước khi cất: 3 nút rõ vai trò (chỉ 1 nút đỏ sáp làm hành động chính)
	# - Sau khi cất: chuyển mượt sang 2 nút đi tiếp (không để 3 nút xám vô dụng)
	var action_slot := VBoxContainer.new()
	action_slot.alignment = BoxContainer.ALIGNMENT_CENTER
	action_slot.add_theme_constant_override("separation", 10)
	vbox.add_child(action_slot)

	_result_action_row = HBoxContainer.new()
	_result_action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_result_action_row.add_theme_constant_override("separation", 16)
	action_slot.add_child(_result_action_row)

	_shelf_btn = Button.new()
	_shelf_btn.custom_minimum_size = Vector2(310, 60)
	_setup_button(_shelf_btn)
	HoaTamUI.apply_primary_button(_shelf_btn, 22)
	_shelf_btn.pressed.connect(_on_save_and_shelf_pressed)
	_result_action_row.add_child(_shelf_btn)

	_equip_btn = Button.new()
	_equip_btn.custom_minimum_size = Vector2(280, 60)
	_setup_button(_equip_btn)
	HoaTamUI.apply_secondary_button(_equip_btn, 22)
	_equip_btn.pressed.connect(_on_equip_now_pressed)
	_result_action_row.add_child(_equip_btn)

	_save_btn = Button.new()
	_save_btn.text = "CẤT KHO · S"
	_save_btn.custom_minimum_size = Vector2(230, 60)
	_setup_button(_save_btn)
	HoaTamUI.apply_secondary_button(_save_btn, 22)
	_save_btn.pressed.connect(_on_save_pressed)
	_result_action_row.add_child(_save_btn)

	_result_nav_row = HBoxContainer.new()
	_result_nav_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_result_nav_row.add_theme_constant_override("separation", 18)
	_result_nav_row.visible = false
	action_slot.add_child(_result_nav_row)

	_retry_btn = Button.new()
	_retry_btn.text = "RÈN MÓN MỚI · R"
	_retry_btn.custom_minimum_size = Vector2(280, 60)
	_setup_button(_retry_btn)
	HoaTamUI.apply_primary_button(_retry_btn, 22)
	_retry_btn.pressed.connect(_on_retry_pressed)
	_result_nav_row.add_child(_retry_btn)

	_hub_btn = Button.new()
	_hub_btn.text = "VỀ PHÒNG XƯỞNG · Esc"
	_hub_btn.custom_minimum_size = Vector2(300, 60)
	_setup_button(_hub_btn)
	HoaTamUI.apply_secondary_button(_hub_btn, 22)
	_hub_btn.pressed.connect(_go_to_hub)
	_result_nav_row.add_child(_hub_btn)

	_result_status_label = Label.new()
	_result_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_status_label.add_theme_font_size_override("font_size", 19)
	_result_status_label.add_theme_color_override("font_color", Color(0.82, 0.76, 0.64))
	_result_status_label.add_theme_color_override("font_outline_color", HoaTamUI.COL_OUTLINE)
	_result_status_label.add_theme_constant_override("outline_size", 3)
	action_slot.add_child(_result_status_label)

	return root


func _find_target_equip_slot() -> Dictionary:
	for i in range(GameManager.equipped_weapons.size()):
		if GameManager.equipped_weapons[i].is_empty():
			return {"slot": i, "is_replace": false}
	return {"slot": 0, "is_replace": true}


func _show_result(result: Dictionary) -> void:
	_forge_result         = result
	_has_saved            = false
	_current_phase        = Phase.RESULT
	_p1_root.visible      = false
	_p2_root.visible      = false
	_p3_anim_root.visible = false
	_result_root.visible  = true
	_result_root.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(_result_root, "modulate:a", 1.0, 0.20)
	if _global_back_btn:
		_global_back_btn.visible = false
	if _recipe_chip:
		_recipe_chip.visible = false
	if _phase_indicator != null:
		_phase_indicator.visible = false

	_result_action_row.visible = true
	_result_nav_row.visible = false

	var shelf_count := InventorySystem.shelf_weapons.size()
	var shelf_max := InventorySystem.MAX_SHELF_SLOTS
	var shelf_has_space := shelf_count < shelf_max

	if _shelf_btn != null:
		_shelf_btn.disabled = not shelf_has_space
		if shelf_has_space:
			HoaTamUI.apply_primary_button(_shelf_btn, 22)
			_shelf_btn.text = "BÀY KỆ (%d/%d) · B" % [shelf_count, shelf_max]
		else:
			HoaTamUI.apply_secondary_button(_shelf_btn, 22)
			_shelf_btn.text = "KỆ TIỆM ĐẦY (%d/%d)" % [shelf_count, shelf_max]

	if _equip_btn != null:
		_equip_btn.disabled = false
		var slot_info := _find_target_equip_slot()
		var slot_num := int(slot_info["slot"]) + 1
		if bool(slot_info["is_replace"]):
			_equip_btn.text = "THAY Ô %d · E" % slot_num
		else:
			_equip_btn.text = "TRANG BỊ Ô %d · E" % slot_num

	if _save_btn != null:
		_save_btn.disabled = false
		_save_btn.text = "CẤT KHO · S"
		if shelf_has_space:
			HoaTamUI.apply_secondary_button(_save_btn, 22)
		else:
			HoaTamUI.apply_primary_button(_save_btn, 22)

	if _result_status_label != null:
		_result_status_label.text = "Chọn nơi đặt thành phẩm  ·  Phím nhanh: R (Rèn mới) · Esc (Về xưởng)"
		_result_status_label.add_theme_color_override("font_color", Color(0.82, 0.76, 0.64))

	_weapon_card.setup(result)


# ══════════════════════════════════════════════════════════════════════════════
# INPUT / PROCESS / SAVE & REFUND
# ══════════════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	# Chuột Trái / Chuột Phải cho Phase 2 (Cương/Nhu) & Chuột Trái cho Phase 3B (Nhúng Tôi)
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if _is_point_on_back_btn(mb.position):
			return
		if _current_phase == Phase.P2 and _forge2.is_active:
			if mb.button_index == MOUSE_BUTTON_LEFT:
				_forge2.try_hit(_FORGE2_SCRIPT.STYLE_CUONG)
				return
			if mb.button_index == MOUSE_BUTTON_RIGHT:
				_forge2.try_hit(_FORGE2_SCRIPT.STYLE_NHU)
				return
		elif _current_phase == Phase.P3_ANIM and mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_quench_press()
			return

	if event is InputEventKey and event.keycode == KEY_SPACE \
			and not event.pressed and not event.echo:
		if _current_phase == Phase.P1 and _forge1.is_active:
			_forge1.is_pumping = false
			AudioManager.stop_sfx_loop()
			get_viewport().set_input_as_handled()
		return

	if not (event is InputEventKey) or event.echo or not event.pressed:
		return

	# Phím số [1..6] & [0 / Space] chọn Thẻ Linh Lực đang hiện ở Nhịp 3A
	if _current_phase == Phase.P3_SEAL:
		var pick_idx := -1
		match event.keycode:
			KEY_1, KEY_KP_1:
				pick_idx = 0
			KEY_2, KEY_KP_2:
				pick_idx = 1
			KEY_3, KEY_KP_3:
				pick_idx = 2
			KEY_4, KEY_KP_4:
				pick_idx = 3
			KEY_5, KEY_KP_5:
				pick_idx = 4
			KEY_6, KEY_KP_6:
				pick_idx = 5
			KEY_0, KEY_KP_0, KEY_SPACE:
				get_viewport().set_input_as_handled()
				_on_phase3_seal_chosen("")
				return
			KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				_go_to_prep_and_refund()
				return
		if pick_idx >= 0 and pick_idx < _p3_visible_elements.size():
			get_viewport().set_input_as_handled()
			_on_phase3_seal_chosen(_p3_visible_elements[pick_idx])
		return

	match event.keycode:
		KEY_SPACE:
			match _current_phase:
				Phase.P1:
					get_viewport().set_input_as_handled()
					if _p1_transition_pending:
						_go_to_phase2()
						return
					if _forge1.is_active:
						if not _forge1.is_pumping:
							AudioManager.play_sfx_key("bellows_puff", 0.72)
						_forge1.is_pumping = true
						AudioManager.play_sfx_loop("furnace_burn", 0.85)
				Phase.P2:
					get_viewport().set_input_as_handled()
					if _forge2.is_active:
						_forge2.try_hit(_FORGE2_SCRIPT.STYLE_CUONG)
				Phase.P3_ANIM:
					get_viewport().set_input_as_handled()
					_handle_quench_press()
		KEY_ENTER, KEY_KP_ENTER:
			match _current_phase:
				Phase.P1:
					get_viewport().set_input_as_handled()
					if _p1_transition_pending:
						_go_to_phase2()
						return
					if _forge1.is_active:
						_forge1.release()
				Phase.P2:
					get_viewport().set_input_as_handled()
					if _forge2.is_active:
						_forge2.try_hit(_FORGE2_SCRIPT.STYLE_NHU)
				Phase.P3_ANIM:
					get_viewport().set_input_as_handled()
					_handle_quench_press()
		KEY_E:
			if _current_phase == Phase.RESULT and not _has_saved:
				get_viewport().set_input_as_handled()
				_on_equip_now_pressed()
		KEY_B:
			if _current_phase == Phase.RESULT and not _has_saved:
				get_viewport().set_input_as_handled()
				_on_save_and_shelf_pressed()
		KEY_S:
			if _current_phase == Phase.RESULT and not _has_saved:
				get_viewport().set_input_as_handled()
				_on_save_pressed()
		KEY_R:
			if _current_phase == Phase.RESULT:
				get_viewport().set_input_as_handled()
				_on_retry_pressed()
		KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			if _current_phase == Phase.RESULT:
				_go_to_hub()
			elif _current_phase != Phase.P3_ANIM:
				_go_to_prep_and_refund()


func _is_point_on_back_btn(pt: Vector2) -> bool:
	if _global_back_btn == null or not _global_back_btn.visible:
		return false
	return _global_back_btn.get_global_rect().has_point(pt)


func _process(delta: float) -> void:
	match _current_phase:
		Phase.P1:
			var h: float = float(_forge1.heat)
			var pct: float = h / 100.0
			_p1_heat_bar.heat_percent = pct
			_p1_heat_bar.tick_animation(delta)
			var cook: float = float(_forge1.cook_progress)
			if _p1_cook_bar != null:
				_p1_cook_bar.value = cook * 100.0
			if _p1_cook_label != null:
				_p1_cook_label.text = "Độ chín thép: %d%%" % int(cook * 100.0)
			if _p1_stage != null:
				_p1_stage.set_heat_state(
					pct,
					float(_forge1.sweet_spot_low) / 100.0,
					float(_forge1.sweet_spot_peak) / 100.0,
					float(_forge1.burn_point) / 100.0,
					bool(_forge1.is_pumping)
				)
			if _forge1.is_active:
				_highlight_active_heat_zone(h)
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
		Phase.P3_SEAL:
			_seal_pulse_time += delta
			for idx in range(_p3_visible_elements.size()):
				var ek: String = _p3_visible_elements[idx]
				var card: Control = _p3_seal_buttons.get(ek, null)
				if card == null or not card.visible:
					continue
				var is_hov := (_p3_seal_hovered == ek)
				var base_y: float = float(_p3_seal_base_y.get(ek, card.position.y))
				var base_rot: float = float(_p3_seal_base_rot.get(ek, 0.0))
				var float_off: float = sin(_seal_pulse_time * 2.8 + float(idx) * 0.9) * 5.0
				var target_y: float = base_y + (float_off - 16.0 if is_hov else float_off)
				var target_scale: Vector2 = Vector2(1.08, 1.08) if is_hov else Vector2.ONE
				var target_rot: float = 0.0 if is_hov else base_rot
				var lerp_t: float = minf(1.0, delta * 12.0)
				card.position.y = lerpf(card.position.y, target_y, lerp_t)
				card.scale = card.scale.lerp(target_scale, lerp_t)
				card.rotation = lerpf(card.rotation, target_rot, lerp_t)
				card.z_index = 20 if is_hov else idx

				var glow := card.get_node_or_null("CardGlow") as TextureRect
				if glow != null:
					var elem_col: Color = _FORGE3_SCRIPT.ELEMENTS[ek]["color"]
					var pulse := 0.5 + sin(_seal_pulse_time * 4.2 + float(idx) * 1.1) * 0.5
					var ga := (0.95 + pulse * 0.25) if is_hov else (0.55 + pulse * 0.30)
					glow.modulate = Color(elem_col.r, elem_col.g, elem_col.b, ga)
		Phase.P3_ANIM:
			if _p3_input_lock > 0.0:
				_p3_input_lock = maxf(0.0, _p3_input_lock - delta)
			if _p3_stage != null and "quench_progress" in _forge3:
				_p3_stage.set_quench_progress(_forge3.quench_progress, _FORGE3_SCRIPT.TARGET_PROGRESS)
				if not _p3_quench_pressed and _forge3.quench_progress >= 0.86:
					_p3_quench_pressed = true
					_p3_is_perfect = false
					_p3_stage.trigger_quench_plunge(false)
					if _p3_instruct != null:
						_p3_instruct.text = "Tự động nhúng tôi — Giữ nguyên độ bền 50/50"
						_p3_instruct.add_theme_color_override("font_color", Color(0.78, 0.74, 0.68))


func _p1_tick_heat_warning(h: float, delta: float) -> void:
	if h < float(_forge1.sweet_spot_peak):
		_heat_tick_timer = 0.0
		return
	_heat_tick_timer += delta
	var interval := 0.14 if h > float(_forge1.burn_point) else 0.24
	if _heat_tick_timer >= interval:
		_heat_tick_timer = 0.0
		var pitch := 1.25 if h > float(_forge1.burn_point) else 0.95
		AudioManager.play_sfx_key("heat_tick", 0.40, pitch)


func _save_forged_weapon_once() -> Dictionary:
	if _forge_result.is_empty() or _has_saved:
		return {}
	_has_saved = true
	if _equip_btn != null:
		_equip_btn.disabled = true
	if _shelf_btn != null:
		_shelf_btn.disabled = true
	if _save_btn != null:
		_save_btn.disabled = true

	var weapon: Dictionary = ForgeConverter.forge_to_combat(_forge_result)
	for key in _forge_result:
		if not weapon.has(key):
			weapon[key] = _forge_result[key]
	InventorySystem.add_weapon(weapon)
	EventBus.weapon_forged.emit(weapon)

	# Chỉ trừ nguyên liệu nếu chưa trừ ở Bàn Chuẩn Bị (chống trừ 2 lần)
	var already_consumed := bool(GameManager.selected_material.get("materials_consumed", false))
	if not already_consumed:
		var qty_to_consume: int = int(GameManager.selected_blank.get("required_quantity", 2))
		var selected_mat_ids: Array = GameManager.selected_material.get("material_ids", [])
		if not selected_mat_ids.is_empty():
			_consume_selected_material_ids(selected_mat_ids)
		else:
			var selected_mat_id: String = String(GameManager.selected_material.get(
				"item_id", GameManager.selected_material.get("id", "")
			))
			_consume_material_units([selected_mat_id], qty_to_consume)
	GameManager.selected_material["materials_consumed"] = false
	return weapon


func _transition_result_to_nav(status_msg: String) -> void:
	if _result_action_row != null:
		_result_action_row.visible = false
	if _result_nav_row != null:
		_result_nav_row.visible = true
	if _result_status_label != null:
		_result_status_label.text = status_msg
		_result_status_label.add_theme_color_override("font_color", Color(0.64, 0.96, 0.76))


func _on_equip_now_pressed() -> void:
	var slot_info := _find_target_equip_slot()
	var target_slot := int(slot_info["slot"])
	var weapon := _save_forged_weapon_once()
	if weapon.is_empty():
		return
	GameManager.equip_to_slot(target_slot, weapon)
	AudioManager.play_sfx_key("weapon_reveal", 0.72, 1.08)
	_transition_result_to_nav("✓ Đã trang bị vào Ô %d" % (target_slot + 1))


func _on_save_pressed() -> void:
	var weapon := _save_forged_weapon_once()
	if weapon.is_empty():
		return
	_transition_result_to_nav("✓ Đã cất vào Kho đồ")


func _on_save_and_shelf_pressed() -> void:
	if InventorySystem.shelf_weapons.size() >= InventorySystem.MAX_SHELF_SLOTS:
		return
	var weapon := _save_forged_weapon_once()
	if weapon.is_empty():
		return
	var moved := InventorySystem.move_to_shelf(weapon)
	var msg := (
		"✓ Đã bày lên Kệ Tiệm (%d/%d)" % [
			InventorySystem.shelf_weapons.size(),
			InventorySystem.MAX_SHELF_SLOTS,
		]
		if moved
		else "Kệ tiệm đã đầy — Đã cất vào Kho đồ"
	)
	_transition_result_to_nav(msg)


func _refund_consumed_materials_if_aborted() -> void:
	if not bool(GameManager.selected_material.get("materials_consumed", false)):
		return
	var mat_id := String(GameManager.selected_material.get("consumed_mat_id", ""))
	var qty := int(GameManager.selected_material.get("consumed_qty", 0))
	GameManager.selected_material["materials_consumed"] = false
	if mat_id == "" or qty <= 0:
		return
	InventorySystem.add_trade_offer({
		"type": "material",
		"item_id": mat_id,
		"name": String(GameManager.selected_material.get("name", mat_id)),
		"amount": qty,
	})


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
		1:
			return "★☆☆ Phổ Thông"
		2:
			return "★★☆ Hiếm"
		3:
			return "★★★ Cực Hiếm"
	return ""


func _on_retry_pressed() -> void:
	AudioManager.stop_sfx_loop()
	if not _has_saved and not _forge_result.is_empty():
		_save_forged_weapon_once()
	get_tree().change_scene_to_file(PATH_WEAPON_BUILDER)


func _go_to_prep_and_refund() -> void:
	AudioManager.stop_sfx_loop()
	_refund_consumed_materials_if_aborted()
	GameManager.forge_return_to_material_step = true
	get_tree().change_scene_to_file(PATH_WEAPON_BUILDER)


func _go_to_hub() -> void:
	AudioManager.stop_sfx_loop()
	if not _has_saved and not _forge_result.is_empty():
		_save_forged_weapon_once()
	SceneManager.go_to(PATH_WORKSHOP)
