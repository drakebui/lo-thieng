extends CanvasLayer

# Chỉ cập nhật UI, không có game logic.
var _lbl_quest: Label = null

@onready var _lbl_day := get_node(
	"VBoxContainer/TopBar/HBoxContainer/DaySlot/_lbl_day"
) as Label
@onready var _lbl_phase := get_node(
	"VBoxContainer/TopBar/HBoxContainer/PhaseSlot/_lbl_phase"
) as Label
@onready var _lbl_gold := get_node(
	"VBoxContainer/TopBar/HBoxContainer/GoldSlot/_lbl_gold"
) as Label
@onready var _lbl_rep := get_node(
	"VBoxContainer/TopBar/HBoxContainer/RepSlot/_lbl_rep"
) as Label
@onready var _lbl_stamina := get_node(
	"VBoxContainer/TopBar/HBoxContainer/StaminaSlot/_lbl_stamina"
) as Label
@onready var _lbl_debt := get_node(
	"VBoxContainer/TopBar/HBoxContainer/DebtSlot/_lbl_debt"
) as Label
@onready var _btn_guide_book := get_node(
	"VBoxContainer/TopBar/HBoxContainer/_btn_guide_book"
) as Button
@onready var _lbl_hint := get_node("VBoxContainer/HintBar/_lbl_hint") as Label


func _ready() -> void:
	_build_quest_label()
	_btn_guide_book.pressed.connect(_on_guide_book_pressed)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.reputation_changed.connect(_on_reputation_changed)
	EventBus.stamina_changed.connect(_on_stamina_changed)
	EventBus.day_phase_changed.connect(_on_day_phase_changed)
	EventBus.debt_updated.connect(_on_debt_updated)
	EventBus.hint_requested.connect(_on_hint_requested)
	EventBus.quest_started.connect(_on_quest_changed)
	EventBus.quest_completed.connect(_on_quest_changed)
	EventBus.quest_updated.connect(_refresh_quest)
	_refresh_all()


func _build_quest_label() -> void:
	var root := get_node("VBoxContainer") as VBoxContainer
	_lbl_quest = Label.new()
	_lbl_quest.name = "_lbl_quest"
	_lbl_quest.custom_minimum_size = Vector2(0, 28)
	_lbl_quest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_quest.add_theme_font_size_override("font_size", 18)
	_lbl_quest.add_theme_color_override("font_color", Color(1.0, 0.84, 0.36))
	root.add_child(_lbl_quest)
	root.move_child(_lbl_quest, 1)


func _refresh_all() -> void:
	var gm := GameManager
	_lbl_day.text = "Ngày %d" % gm.current_day
	_lbl_phase.text = _phase_name(gm.current_phase)
	_lbl_gold.text = "%d G" % gm.gold
	_lbl_rep.text = "Tiếng tăm: %d" % gm.reputation
	_lbl_stamina.text = "%d/%d" % [
		gm.travel_stamina,
		gm.max_travel_stamina,
	]
	_update_debt()
	_refresh_quest()


func _on_gold_changed(value: int) -> void:
	_lbl_gold.text = "%d G" % value


func _on_reputation_changed(value: int) -> void:
	_lbl_rep.text = "Tiếng tăm: %d" % value


func _on_stamina_changed(current: int, maximum: int) -> void:
	_lbl_stamina.text = "%d/%d" % [current, maximum]


func _on_day_phase_changed(day: int, phase: int) -> void:
	_lbl_day.text = "Ngày %d" % day
	_lbl_phase.text = _phase_name(phase)


func _on_debt_updated(amount: int, days_left: int) -> void:
	if amount > 0:
		_lbl_debt.text = "Nợ: %dG (còn %d ngày)" % [amount, days_left]
		_lbl_debt.modulate = Color.RED
	else:
		_lbl_debt.text = ""
		_lbl_debt.modulate = Color.WHITE


func _on_hint_requested(text: String) -> void:
	_lbl_hint.text = text


func _on_quest_changed(_quest_id: String) -> void:
	_refresh_quest()


func _on_guide_book_pressed() -> void:
	EventBus.guide_book_opened.emit()


func _phase_name(phase: int) -> String:
	match phase:
		GameManager.GamePhase.MORNING:
			return "Sáng"
		GameManager.GamePhase.NOON:
			return "Trưa"
		GameManager.GamePhase.AFTERNOON:
			return "Chiều"
		GameManager.GamePhase.NIGHT:
			return "Đêm"
	return ""


func _update_debt() -> void:
	var ds := DebtSystem
	if ds and ds.current_debt > 0:
		_lbl_debt.text = "Nợ: %dG (còn %d ngày)" % [
			ds.current_debt,
			ds.days_until_checkpoint,
		]
		_lbl_debt.modulate = Color.RED
	else:
		_lbl_debt.text = ""
		_lbl_debt.modulate = Color.WHITE


func _refresh_quest() -> void:
	if _lbl_quest == null:
		return
	var quest_text := GameManager.get_quest_hud_text()
	_lbl_quest.text = quest_text
	_lbl_quest.visible = not quest_text.is_empty()
