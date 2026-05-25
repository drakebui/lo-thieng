class_name DebtAgentNode
extends Node2D

signal player_entered
signal player_exited

const _C_BODY   := Color(0.18, 0.12, 0.10)
const _C_ACCENT := Color(0.82, 0.14, 0.08)

var display_name := "Người Thu Nợ"


func _ready() -> void:
	_build_visual()
	_build_interaction()


func _build_visual() -> void:
	var shadow := ColorRect.new()
	shadow.position = Vector2(-22, 38)
	shadow.size = Vector2(44, 10)
	shadow.color = Color(0.0, 0.0, 0.0, 0.32)
	add_child(shadow)

	var body := ColorRect.new()
	body.position = Vector2(-18, -8)
	body.size = Vector2(36, 52)
	body.color = _C_BODY
	add_child(body)

	var sash := ColorRect.new()
	sash.position = Vector2(-18, 2)
	sash.size = Vector2(36, 8)
	sash.color = _C_ACCENT
	add_child(sash)

	var head := ColorRect.new()
	head.position = Vector2(-12, -30)
	head.size = Vector2(24, 24)
	head.color = Color(0.72, 0.54, 0.38)
	add_child(head)

	var alert := Label.new()
	alert.text = "!"
	alert.position = Vector2(18, -42)
	alert.size = Vector2(30, 30)
	alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert.add_theme_font_size_override("font_size", 28)
	alert.add_theme_color_override("font_color", _C_ACCENT)
	add_child(alert)

	var name_lbl := Label.new()
	name_lbl.text = display_name
	name_lbl.position = Vector2(-72, -68)
	name_lbl.size = Vector2(144, 28)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.76, 0.52))
	add_child(name_lbl)


func _build_interaction() -> void:
	var area := Area2D.new()
	area.name = "DebtAgentInteraction"
	area.collision_layer = 0
	area.collision_mask = 1
	add_child(area)

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(104, 112)
	col.shape = rect
	area.add_child(col)

	area.body_entered.connect(func(_b: Node) -> void: player_entered.emit())
	area.body_exited.connect(func(_b: Node) -> void: player_exited.emit())
