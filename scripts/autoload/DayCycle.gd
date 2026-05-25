extends Node

signal phase_advanced(
	old_phase: GameManager.GamePhase,
	new_phase: GameManager.GamePhase,
	day: int
)


func advance_phase() -> void:
	var old_phase: GameManager.GamePhase = GameManager.current_phase
	var new_phase: GameManager.GamePhase = _get_next_phase(old_phase)

	if old_phase == GameManager.GamePhase.NIGHT:
		GameManager.current_day += 1
		GameManager.day_start_gold = GameManager.gold
		GameManager.travel_stamina = GameManager.max_travel_stamina
		GameManager.travel_stamina_changed.emit(
			GameManager.travel_stamina,
			GameManager.max_travel_stamina
		)
		GameManager.day_changed.emit(GameManager.current_day)

	GameManager.current_phase = new_phase
	GameManager.phase_changed.emit(new_phase)
	phase_advanced.emit(old_phase, new_phase, GameManager.current_day)
	if new_phase == GameManager.GamePhase.MORNING:
		GameManager._check_zero_gold_streak()
		DebtSystem.check_day(GameManager.current_day)


func get_phase_name() -> String:
	match GameManager.current_phase:
		GameManager.GamePhase.MORNING:
			return "Sáng"
		GameManager.GamePhase.NOON:
			return "Trưa"
		GameManager.GamePhase.AFTERNOON:
			return "Chiều"
		GameManager.GamePhase.NIGHT:
			return "Đêm"
	return "Sáng"


func _get_next_phase(phase: GameManager.GamePhase) -> GameManager.GamePhase:
	match phase:
		GameManager.GamePhase.MORNING:
			return GameManager.GamePhase.NOON
		GameManager.GamePhase.NOON:
			return GameManager.GamePhase.AFTERNOON
		GameManager.GamePhase.AFTERNOON:
			return GameManager.GamePhase.NIGHT
	return GameManager.GamePhase.MORNING
