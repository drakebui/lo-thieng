extends Node

signal player_entered(player: Node)
signal player_exited(player: Node)
signal interacted(interactor: Node)

const INTERACT_RADIUS := 48.0

@export var priority: int = 0
@export var is_locked: bool = false

var _area: Area2D
var _icon_label: Label
var _player_in_range: Node = null


func _ready() -> void:
	_build_area()
	_build_icon()


func try_interact(player: Node) -> bool:
	if is_locked:
		return false
	interacted.emit(player)
	return true


func set_locked(value: bool) -> void:
	is_locked = value
	_refresh_icon()


func _build_area() -> void:
	_area = Area2D.new()
	_area.name = "InteractArea"
	_area.monitoring = true
	_area.collision_layer = 0
	_area.collision_mask = 1
	add_child(_area)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = INTERACT_RADIUS
	shape.shape = circle
	_area.add_child(shape)

	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)


func _build_icon() -> void:
	_icon_label = Label.new()
	_icon_label.name = "E"
	_icon_label.text = "E"
	_icon_label.visible = false
	_icon_label.position = Vector2(-8, -64)
	_icon_label.add_theme_font_size_override("font_size", 24)
	_icon_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35))
	add_child(_icon_label)


func _on_body_entered(body: Node2D) -> void:
	if not _is_player_body(body):
		return
	_player_in_range = body
	if is_locked:
		_refresh_icon()
		return
	player_entered.emit(body)
	_refresh_icon()


func _on_body_exited(body: Node2D) -> void:
	if body != _player_in_range:
		return
	_player_in_range = null
	player_exited.emit(body)
	_refresh_icon()


func _refresh_icon() -> void:
	if _icon_label == null:
		return
	_icon_label.visible = _player_in_range != null and not is_locked


func _is_player_body(body: Node) -> bool:
	return body is CharacterBody2D
