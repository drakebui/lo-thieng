# Thanh chỉ báo 6 bước rèn — phong cách đồng cổ Hỏa Tâm
class_name ForgePhaseIndicator
extends Control

enum Phase {
	CHON_PHOI = 0,
	CHON_NL = 1,
	CHON_LINH_LUC = 2,
	NUNG_THEP = 3,
	REN_BUA = 4,
	TOI_LUYEN = 5,
}

const COLOR_DONE := Color(0.86, 0.64, 0.34, 1.0)
const COLOR_ACTIVE := Color(1.0, 0.96, 0.86, 1.0)
const COLOR_PENDING := Color(0.56, 0.42, 0.28, 0.48)
const COLOR_BRONZE_BORDER := Color(0.76, 0.56, 0.24, 0.95)
const COLOR_GOLD_HIGHLIGHT := Color(1.0, 0.84, 0.34, 1.0)
const COLOR_DONE_BORDER := Color(0.66, 0.44, 0.18, 0.90)
const COLOR_PENDING_BORDER := Color(0.36, 0.24, 0.14, 0.55)
const COLOR_FRAME_BG := Color(0.10, 0.06, 0.03, 0.86)
const COLOR_ACTIVE_BG := Color(0.30, 0.16, 0.04, 0.96)
const COLOR_DONE_BG := Color(0.16, 0.09, 0.04, 0.92)
const STEP_SIZE := 50.0
const STEP_NAMES := [
	"Step1",
	"Step2",
	"Step3",
	"Step4",
	"Step5",
	"Step6",
]
const PHASE_LABELS := [
	"1. Chuẩn Bị Rèn",
	"1. Chuẩn Bị Rèn",
	"1. Chuẩn Bị Rèn",
	"2. Nung Thép",
	"3. Rèn Búa",
	"4. Tôi Luyện",
]
# Chỉ hiển thị 4 bước tinh gọn khớp luồng mới (ẩn Step2 & Step3 đã gộp vào Bàn Chuẩn Bị)
const VISIBLE_STEP_INDICES := [0, 3, 4, 5]
const STEP_PIXEL_ICONS := [
	"res://assets/pixel/sprites/weapons/kiem_don.png",
	"res://assets/pixel/ui/materials/sat_tho.png",
	"res://assets/pixel/ui/forge/element_seals_sheet_64.png",
	"res://assets/pixel/sprites/forge/forge_hearth_144x112.png",
	"res://assets/pixel/sprites/forge/forge_hammer_96x96.png",
	"res://assets/pixel/sprites/forge/forge_quench_tub_144x112.png",
]

var current_phase: int = 0

var _active_tween: Tween
var _done_tweens: Dictionary = {}
var _reported_done := [false, false, false, false, false, false]
var _step_frames: Array[Panel] = []
var _done_badges: Array[Label] = []
var _phase_name_label: Label


func _ready() -> void:
	theme = preload("res://assets/fonts/hoa_tam_pixel_theme.tres")
	_setup_hoa_tam_chrome()
	set_phase(Phase.CHON_PHOI)


func set_phase(new_phase: int) -> void:
	current_phase = clampi(new_phase, Phase.CHON_PHOI, Phase.TOI_LUYEN)
	print("ForgePhaseIndicator: active step %d" % (current_phase + 1))
	_refresh_all_steps()


func advance() -> void:
	if current_phase < Phase.TOI_LUYEN:
		set_phase(current_phase + 1)


func _setup_hoa_tam_chrome() -> void:
	# Tắt texture thanh cuộn cũ trong ScrollBg để dùng khung đồng cổ 32-bit thuần
	var scroll_bg := get_node_or_null("ScrollBg") as TextureRect
	if scroll_bg != null:
		scroll_bg.texture = null

	# Khung viền đồng cổ bao trọn cả 4 biểu tượng và nhãn chữ bên dưới (không cắt chữ)
	if get_node_or_null("BronzeFrame") == null:
		var frame := Panel.new()
		frame.name = "BronzeFrame"
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.offset_left = 78.0
		frame.offset_top = 4.0
		frame.offset_right = -78.0
		frame.offset_bottom = 6.0
		frame.add_theme_stylebox_override("panel", _make_outer_bronze_style())
		add_child(frame)
		move_child(frame, 0)

	# Đẩy nhẹ hàng icon lên trên để nhường khoảng thở sạch cho tên bước phía dưới
	var steps_row := get_node_or_null("StepsRow") as Control
	if steps_row == null:
		steps_row = get_node_or_null("HBoxContainer") as Control
	if steps_row != null:
		steps_row.offset_top -= 10.0
		steps_row.offset_bottom -= 10.0

	# Khung huy hiệu đồng + chỉ hiện 4 bước tinh gọn (0, 3, 4, 5)
	_step_frames.clear()
	_done_badges.clear()
	for i in range(STEP_NAMES.size()):
		var step := _get_step(i)
		if step == null:
			_step_frames.append(null)
			_done_badges.append(null)
			continue
		if not VISIBLE_STEP_INDICES.has(i):
			step.visible = false
			_step_frames.append(null)
			_done_badges.append(null)
			continue
		step.visible = true
		step.position.y -= 8.0
		var badge_frame := step.get_node_or_null("StepFrame") as Panel
		if badge_frame == null:
			badge_frame = Panel.new()
			badge_frame.name = "StepFrame"
			badge_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge_frame.position = Vector2(-4.0, -4.0)
			badge_frame.size = Vector2(STEP_SIZE + 8.0, STEP_SIZE + 8.0)
			step.add_child(badge_frame)
			step.move_child(badge_frame, 0)
		_step_frames.append(badge_frame)

		var icon := step.get_node_or_null("Icon") as TextureRect
		if icon != null and i < STEP_PIXEL_ICONS.size():
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var icon_path: String = STEP_PIXEL_ICONS[i]
			if ResourceLoader.exists(icon_path):
				var tex := load(icon_path) as Texture2D
				if i == 2 and tex != null:
					var atlas := AtlasTexture.new()
					atlas.atlas = tex
					atlas.region = Rect2(0.0, 0.0, 64.0, 64.0)
					icon.texture = atlas
				else:
					icon.texture = tex

		# Ẩn checkmark ảnh cũ, thay bằng dấu tích vàng kim đồng bộ
		var old_check := step.get_node_or_null("Checkmark") as TextureRect
		if old_check != null:
			old_check.texture = null
			old_check.visible = false

		var done_lbl := step.get_node_or_null("DoneBadge") as Label
		if done_lbl == null:
			done_lbl = Label.new()
			done_lbl.name = "DoneBadge"
			done_lbl.text = "✓"
			done_lbl.visible = false
			done_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			done_lbl.position = Vector2(STEP_SIZE - 14.0, -8.0)
			done_lbl.add_theme_font_size_override("font_size", 20)
			done_lbl.add_theme_color_override("font_color", COLOR_GOLD_HIGHLIGHT)
			done_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02, 0.98))
			done_lbl.add_theme_constant_override("outline_size", 5)
			step.add_child(done_lbl)
		_done_badges.append(done_lbl)

	# Nhãn tên bước hiện tại nằm gọn trong lòng khung đồng phía dưới hàng biểu tượng
	_phase_name_label = get_node_or_null("PhaseNameLabel") as Label
	if _phase_name_label == null:
		_phase_name_label = Label.new()
		_phase_name_label.name = "PhaseNameLabel"
		_phase_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_phase_name_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_phase_name_label.offset_top = -24.0
		_phase_name_label.offset_bottom = 2.0
		_phase_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_phase_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_phase_name_label.add_theme_font_size_override("font_size", 17)
		_phase_name_label.add_theme_color_override("font_color", COLOR_GOLD_HIGHLIGHT)
		_phase_name_label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02, 0.95))
		_phase_name_label.add_theme_constant_override("outline_size", 4)
		add_child(_phase_name_label)


func _refresh_all_steps() -> void:
	if _active_tween:
		_active_tween.kill()
		_active_tween = null
	for tween: Tween in _done_tweens.values():
		if tween:
			tween.kill()
	_done_tweens.clear()

	if _phase_name_label != null and current_phase >= 0 and current_phase < PHASE_LABELS.size():
		_phase_name_label.text = PHASE_LABELS[current_phase]

	for i in range(STEP_NAMES.size()):
		var step := _get_step(i)
		if step == null:
			continue
		var icon := step.get_node_or_null("Icon") as TextureRect
		var done_badge: Label = _done_badges[i] if i < _done_badges.size() else null
		var badge_frame: Panel = _step_frames[i] if i < _step_frames.size() else null

		step.pivot_offset = Vector2(STEP_SIZE * 0.5, STEP_SIZE * 0.5)
		if i < current_phase:
			if icon != null:
				icon.modulate = COLOR_DONE
			if done_badge != null:
				done_badge.visible = true
			if badge_frame != null:
				badge_frame.add_theme_stylebox_override(
					"panel", _make_step_style(COLOR_DONE_BG, COLOR_DONE_BORDER, 2, false)
				)
			step.scale = Vector2.ONE
			if not _reported_done[i]:
				_reported_done[i] = true
				print("ForgePhaseIndicator: step %d completed" % (i + 1))
				_animate_done(step)
		elif i == current_phase:
			if icon != null:
				icon.modulate = COLOR_ACTIVE
			if done_badge != null:
				done_badge.visible = false
			if badge_frame != null:
				badge_frame.add_theme_stylebox_override(
					"panel", _make_step_style(COLOR_ACTIVE_BG, COLOR_GOLD_HIGHLIGHT, 3, true)
				)
			step.scale = Vector2.ONE
			_animate_active(step)
		else:
			if icon != null:
				icon.modulate = COLOR_PENDING
			if done_badge != null:
				done_badge.visible = false
			if badge_frame != null:
				badge_frame.add_theme_stylebox_override(
					"panel", _make_step_style(COLOR_FRAME_BG, COLOR_PENDING_BORDER, 1, false)
				)
			step.scale = Vector2.ONE


func _make_outer_bronze_style() -> StyleBoxFlat:
	return HoaTamUI.make_inset_surface_style(0.80, 10.0, COLOR_BRONZE_BORDER)


func _make_step_style(
	bg_col: Color,
	border_col: Color,
	border_w: int,
	_glow: bool
) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg_col
	s.border_color = border_col
	s.set_border_width_all(border_w)
	return s


func _animate_active(step: Control) -> void:
	if not visible or not is_inside_tree():
		return
	_active_tween = create_tween().set_loops()
	_active_tween.tween_property(step, "scale", Vector2(1.12, 1.12), 0.55) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_active_tween.tween_property(step, "scale", Vector2.ONE, 0.55) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _animate_done(step: Control) -> void:
	var tween := create_tween()
	_done_tweens[step.name] = tween
	tween.tween_property(step, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(step, "scale", Vector2.ONE, 0.1)


func _get_step(index: int) -> Control:
	var row := get_node_or_null("ScrollBg/IconRow")
	if row == null or index < 0 or index >= STEP_NAMES.size():
		return null
	return row.get_node_or_null(STEP_NAMES[index]) as Control
