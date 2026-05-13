# UI test scene cho Phase 3: Tôi Luyện
# Auto phase — chọn nguyên tố → animation nhúng vũ khí → hiện card kết quả
extends Control

const _PHASE3_SCRIPT := preload("res://scripts/forge/forge_phase3.gd")

# Giả lập đầu vào từ phase 1+2 (trong game thật sẽ nhận từ EventBus)
const MOCK_PHASE1_TIER   := "cam"
const MOCK_PHASE2_PREFIX := "kiet_tac"

const PHASE2_PREFIX_NAMES := {
	"phan_chu":   "Phản Chủ",
	"curse_nang": "Lời Nguyền",
	"curse_nhe":  "Nguyền Nhẹ",
	"thuong":     "Thường",
	"tot":        "Tốt",
	"kiet_tac":   "Kiệt Tác",
	"to_nghe":    "Tổ Nghề",
	"khi_phach":  "Khí Phách",
	"perfect":    "PERFECT",
}

const PHASE1_TIER_NAMES := {
	"lanh":     "Lạnh",
	"cam":      "Cam",
	"vang_kim": "Vàng Kim",
}

var _phase3: Node

# Màn hình chọn nguyên tố
var _pick_screen:   Control
var _element_btns:  Array[Button]

# Màn hình animation
var _anim_screen:   Control
var _anim_bg:       ColorRect
var _weapon_rect:   ColorRect
var _anim_label:    Label
var _flash_rect:    ColorRect

# Màn hình kết quả
var _result_screen:  Control
var _card_bg:        ColorRect
var _card_labels:    Array[Label]

var _chosen_element: String = ""
var _tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.08, 0.06)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_phase3 = _PHASE3_SCRIPT.new()
	add_child(_phase3)

	_build_pick_screen()
	_build_anim_screen()
	_build_result_screen()

	_show_pick_screen()


# ─── MÀN HÌNH CHỌN NGUYÊN TỐ ────────────────────────────────────────────────

func _build_pick_screen() -> void:
	_pick_screen = Control.new()
	_pick_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_pick_screen)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pick_screen.add_child(center)

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

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 40)
	vbox.add_child(grid)

	for key in _phase3.ELEMENTS.keys():
		var data: Dictionary = _phase3.ELEMENTS[key]
		var btn := Button.new()
		btn.text = data["name"]
		btn.custom_minimum_size = Vector2(360, 120)
		btn.add_theme_font_size_override("font_size", 64)
		btn.add_theme_color_override("font_color", data["color"])
		btn.pressed.connect(_on_element_picked.bind(key))
		grid.add_child(btn)
		_element_btns.append(btn)


# ─── MÀN HÌNH ANIMATION ──────────────────────────────────────────────────────

func _build_anim_screen() -> void:
	_anim_screen = Control.new()
	_anim_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_anim_screen.visible = false
	add_child(_anim_screen)

	# Nền màu nguyên tố (sẽ tween alpha)
	_anim_bg = ColorRect.new()
	_anim_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_anim_bg.color = Color(0, 0, 0, 0)
	_anim_screen.add_child(_anim_bg)

	# Flash overlay khi hoàn thành
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1, 1, 1, 0)
	_anim_screen.add_child(_flash_rect)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_anim_screen.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 80)
	center.add_child(vbox)

	# Hình chữ nhật giả lập vũ khí
	var weapon_wrap := CenterContainer.new()
	vbox.add_child(weapon_wrap)

	_weapon_rect = ColorRect.new()
	_weapon_rect.custom_minimum_size = Vector2(60, 280)
	_weapon_rect.color = Color(0.72, 0.72, 0.72)
	weapon_wrap.add_child(_weapon_rect)

	_anim_label = Label.new()
	_anim_label.text = "Đang tôi luyện..."
	_anim_label.add_theme_font_size_override("font_size", 76)
	_anim_label.add_theme_color_override("font_color", Color.WHITE)
	_anim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_anim_label)


# ─── MÀN HÌNH KẾT QUẢ ────────────────────────────────────────────────────────

func _build_result_screen() -> void:
	_result_screen = Control.new()
	_result_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_screen.visible = false
	add_child(_result_screen)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_screen.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 48)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "VŨ KHÍ HOÀN THÀNH"
	title.add_theme_font_size_override("font_size", 104)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Card vũ khí
	var card_wrap := CenterContainer.new()
	vbox.add_child(card_wrap)

	_card_bg = ColorRect.new()
	_card_bg.custom_minimum_size = Vector2(1000, 520)
	_card_bg.color = Color(0.14, 0.12, 0.10)
	card_wrap.add_child(_card_bg)

	var card_vbox := VBoxContainer.new()
	card_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_vbox.add_theme_constant_override("separation", 20)
	# Padding trong card
	card_vbox.position = Vector2(40, 32)
	card_vbox.size = Vector2(920, 456)
	_card_bg.add_child(card_vbox)

	# Tạo sẵn 6 label trong card — sẽ điền nội dung ở _show_result_card()
	for i in range(6):
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 52 if i == 0 else 44)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_vbox.add_child(lbl)
		_card_labels.append(lbl)

	# Nút thử lại
	var retry := Button.new()
	retry.text = "[ Rèn lại   (R) ]"
	retry.add_theme_font_size_override("font_size", 52)
	retry.pressed.connect(_on_retry_pressed)
	vbox.add_child(retry)


# ─── LOGIC CHUYỂN MÀN ────────────────────────────────────────────────────────

func _show_pick_screen() -> void:
	_pick_screen.visible   = true
	_anim_screen.visible   = false
	_result_screen.visible = false


func _on_element_picked(element_key: String) -> void:
	_chosen_element = element_key
	_phase3.start_phase(element_key)
	_pick_screen.visible = false
	_start_quench_animation(element_key)


func _start_quench_animation(element_key: String) -> void:
	_anim_screen.visible = true
	var elem: Dictionary = _phase3.get_element_data(element_key)
	var elem_color: Color = elem.get("color", Color.WHITE)
	var elem_name: String = elem.get("name", "")

	_anim_label.text = "Tôi luyện %s..." % elem_name
	_anim_bg.color   = Color(elem_color.r, elem_color.g, elem_color.b, 0)

	if _tween:
		_tween.kill()
	_tween = create_tween().set_loops(0)
	var dur: float = _phase3.QUENCH_DURATION

	# Giai đoạn 1: Nền sáng dần theo màu nguyên tố
	_tween.tween_property(_anim_bg, "color",
		Color(elem_color.r, elem_color.g, elem_color.b, 0.45),
		dur * 0.4)

	# Giai đoạn 2: Vũ khí đổi màu sang nguyên tố
	_tween.tween_property(_weapon_rect, "color", elem_color, dur * 0.25)

	# Giai đoạn 3: Pulse mạnh
	_tween.tween_property(_anim_bg, "color",
		Color(elem_color.r, elem_color.g, elem_color.b, 0.75),
		dur * 0.2)

	# Giai đoạn 4: Flash trắng → hoàn thành
	_tween.tween_property(_flash_rect, "color", Color(1, 1, 1, 0.85), dur * 0.08)
	_tween.tween_callback(_finish_quench)
	_tween.set_loops(1)


func _finish_quench() -> void:
	# Fade out flash
	var fade := create_tween()
	fade.tween_property(_flash_rect, "color", Color(1, 1, 1, 0), 0.4)

	var result: Dictionary = _phase3.complete(MOCK_PHASE1_TIER, MOCK_PHASE2_PREFIX)
	_show_result_card(result)


func _show_result_card(result: Dictionary) -> void:
	var elem_color: Color  = result.get("element_color", Color.WHITE)
	var elem_name: String  = result.get("element_name", "")
	var suffix_key: String = result.get("suffix", "")
	var suffix_name: String = _phase3.get_suffix_name(suffix_key)
	var prefix_key: String  = result.get("phase2_prefix", "thuong")
	var prefix_name: String = PHASE2_PREFIX_NAMES.get(prefix_key, prefix_key)
	var tier_key: String    = result.get("phase1_tier", "cam")
	var tier_name: String   = PHASE1_TIER_NAMES.get(tier_key, tier_key)

	# Tô viền card theo màu nguyên tố
	_card_bg.color = Color(
		elem_color.r * 0.18 + 0.08,
		elem_color.g * 0.18 + 0.06,
		elem_color.b * 0.18 + 0.05
	)

	# Điền nội dung card
	_card_labels[0].text = "⚔  %s · %s" % [prefix_name, suffix_name]
	_card_labels[0].add_theme_color_override("font_color", elem_color)

	_card_labels[1].text = "Nung:  %s     Rèn:  %s     Nguyên tố:  %s" % [
		tier_name, prefix_name, elem_name]
	_card_labels[1].add_theme_color_override("font_color", Color(0.78, 0.72, 0.62))

	_card_labels[2].text = "Skill 1 (Prefix — %s):  [Sẽ xác định sau]" % prefix_name
	_card_labels[2].add_theme_color_override("font_color", Color(0.85, 0.82, 0.72))

	_card_labels[3].text = "Skill 2 (Suffix — %s):  [Sẽ xác định sau]" % suffix_name
	_card_labels[3].add_theme_color_override("font_color", elem_color)

	_card_labels[4].text = "Độ bền:  50 / 50"
	_card_labels[4].add_theme_color_override("font_color", Color(0.78, 0.72, 0.62))

	_card_labels[5].text = "Giá ước tính:  ???G"
	_card_labels[5].add_theme_color_override("font_color", Color(0.78, 0.72, 0.62))

	_anim_screen.visible   = false
	_result_screen.visible = true


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo or not event.pressed:
		return
	if event.keycode == KEY_R and _result_screen.visible:
		_on_retry_pressed()


func _on_retry_pressed() -> void:
	if _tween:
		_tween.kill()
	_weapon_rect.color = Color(0.72, 0.72, 0.72)
	_anim_bg.color     = Color(0, 0, 0, 0)
	_flash_rect.color  = Color(1, 1, 1, 0)
	_show_pick_screen()
