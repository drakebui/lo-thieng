class_name DebtCheckpoint
extends Resource

@export var id: String
@export var title: String
@export var agent_id: String
@export var amount_gold: int
@export var trigger_day: int
@export var deadline_day: int
@export var penalty_gold: int
@export var late_days_before_harass: int
@export var on_time_reward: Dictionary
@export var agent_name: String = ""
@export var agent_description: String = ""
@export var agent_quote: String
@export var is_paid: bool = false
@export var is_late: bool = false
@export var has_notified: bool = false
