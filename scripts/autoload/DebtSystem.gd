extends Node

signal debt_triggered(checkpoint: DebtCheckpoint)
signal debt_deadline_warning(checkpoint: DebtCheckpoint, days_left: int)
signal debt_paid(checkpoint: DebtCheckpoint)
signal debt_penalty_applied(checkpoint: DebtCheckpoint, penalty: int)

const DEBT_DIR := "res://resources/debt"

var checkpoints: Array[DebtCheckpoint] = []
var current_debt: int = 0
var days_until_checkpoint: int = 0


func _ready() -> void:
	_load_checkpoints()
	refresh_debt_summary()


func check_day(day: int) -> void:
	for checkpoint in checkpoints:
		if checkpoint.is_paid:
			continue

		if checkpoint.trigger_day <= day and not checkpoint.has_notified:
			checkpoint.has_notified = true
			debt_triggered.emit(checkpoint)

		if day > checkpoint.deadline_day and not checkpoint.is_late:
			checkpoint.is_late = true
			debt_penalty_applied.emit(checkpoint, checkpoint.penalty_gold)

		var days_left: int = checkpoint.deadline_day - day
		if days_left >= 0 and days_left <= 1:
			debt_deadline_warning.emit(checkpoint, days_left)
	refresh_debt_summary()


func get_checkpoint(id: String) -> DebtCheckpoint:
	for checkpoint: DebtCheckpoint in checkpoints:
		if checkpoint.id == id:
			return checkpoint
	return null


func pay_checkpoint(id: String) -> bool:
	for checkpoint in checkpoints:
		if checkpoint.id != id:
			continue

		if checkpoint.is_paid:
			return false

		var total_amount: int = checkpoint.amount_gold
		if checkpoint.is_late:
			total_amount += checkpoint.penalty_gold

		if GameManager.gold < total_amount:
			return false

		GameManager.gold -= total_amount
		GameManager.gold_changed.emit(GameManager.gold)
		checkpoint.is_paid = true
		debt_paid.emit(checkpoint)
		refresh_debt_summary()
		return true

	return false


func refresh_debt_summary() -> void:
	# Tổng hợp phần nợ đang có hiệu lực để HUD chỉ cần đọc dữ liệu sẵn.
	current_debt = 0
	days_until_checkpoint = 0
	var nearest_days := 999999
	for checkpoint in checkpoints:
		if checkpoint.is_paid:
			continue
		if checkpoint.trigger_day > GameManager.current_day:
			continue
		var amount := checkpoint.amount_gold
		if checkpoint.is_late:
			amount += checkpoint.penalty_gold
		current_debt += amount
		nearest_days = mini(
			nearest_days,
			maxi(0, checkpoint.deadline_day - GameManager.current_day)
		)
	if current_debt > 0 and nearest_days != 999999:
		days_until_checkpoint = nearest_days
	EventBus.debt_updated.emit(current_debt, days_until_checkpoint)


func _load_checkpoints() -> void:
	checkpoints.clear()
	var dir := DirAccess.open(DEBT_DIR)
	if dir == null:
		return

	var files: PackedStringArray = dir.get_files()
	files.sort()
	for file_name in files:
		if file_name.get_extension() != "tres":
			continue

		var resource_path := "%s/%s" % [DEBT_DIR, file_name]
		var resource := load(resource_path)
		if resource is DebtCheckpoint:
			var checkpoint := resource as DebtCheckpoint
			checkpoints.append(checkpoint)
