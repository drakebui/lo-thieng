# scripts/ui/day_summary_ui.gd
# Overlay tổng kết cuối ngày: vàng kiếm được, ngày tiếp theo, lưu game
class_name DaySummaryUI
extends CanvasLayer

const PATH_WORKSHOP := "res://scenes/main/WorkshopHub.tscn"

var _title: Label
var _gold_lbl: Label
var _sold_lbl: Label
var _session_stats: Dictionary = {}

func _ready() -> void:
	layer   = 16
	visible = false
	_build_placeholder()


func _process(_delta: float) -> void:
	if visible:
		_refresh_summary()


func show_summary(stats: Dictionary = {}) -> void:
	_session_stats = stats.duplicate()
	visible = true
	_refresh_summary()


func _build_placeholder() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.02, 0.01, 0.85)
	root.add_child(bg)

	var panel := ColorRect.new()
	panel.size = Vector2(460, 300)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -panel.size * 0.5
	panel.color    = Color(0.14, 0.09, 0.04)
	root.add_child(panel)

	_title = Label.new()
	_title.position            = Vector2(0, 24)
	_title.size                = Vector2(460, 42)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.28))
	panel.add_child(_title)

	_gold_lbl = Label.new()
	_gold_lbl.position = Vector2(48, 96)
	_gold_lbl.size = Vector2(364, 32)
	_gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_lbl.add_theme_font_size_override("font_size", 22)
	_gold_lbl.add_theme_color_override("font_color", Color(0.90, 0.82, 0.65))
	panel.add_child(_gold_lbl)

	_sold_lbl = Label.new()
	_sold_lbl.position = Vector2(48, 138)
	_sold_lbl.size = Vector2(364, 32)
	_sold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sold_lbl.add_theme_font_size_override("font_size", 22)
	_sold_lbl.add_theme_color_override("font_color", Color(0.90, 0.82, 0.65))
	panel.add_child(_sold_lbl)

	var next_btn := Button.new()
	next_btn.text     = "Sang Ngày Mới"
	next_btn.position = Vector2(80, 216)
	next_btn.size     = Vector2(300, 52)
	next_btn.add_theme_font_size_override("font_size", 22)
	next_btn.pressed.connect(_on_next_day)
	panel.add_child(next_btn)

	_refresh_summary()


func _on_next_day() -> void:
	GameManager.advance_day()
	GameManager.clear_hand()
	GameManager.pending_day_summary_stats = {}
	_save_game()
	visible = false
	SceneManager.go_to(PATH_WORKSHOP)


func _save_game() -> void:
	var state := {
		"day": GameManager.current_day,
		"gold": GameManager.gold,
		"reputation": GameManager.reputation,
		"smithing_mastery": GameManager.smithing_mastery,
		"artifact_count": GameManager.artifact_count,
		"travel_stamina": GameManager.travel_stamina,
		"unlocked_regions": GameManager.unlocked_regions,
		"forged_weapons": GameManager.forged_weapons,
		"equipped_weapons": GameManager.equipped_weapons,
		"day_start_gold": GameManager.day_start_gold,
	}
	SaveSystem.save_game(state)


func _refresh_summary() -> void:
	if _title == null:
		return
	_title.text = "Kết Thúc Ngày %d" % GameManager.current_day
	var earned_today := GameManager.gold - GameManager.day_start_gold
	_gold_lbl.text = "Vàng kiếm được: %d G" % earned_today
	var sold_count: int = _session_stats.get("customers_served", 0)
	_sold_lbl.text = "Vũ khí đã bán: %d" % sold_count


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			visible = false
			get_viewport().set_input_as_handled()
