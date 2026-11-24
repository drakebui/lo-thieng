class_name DebtAgentNode
extends Node2D

signal player_entered
signal player_exited

const _C_BODY   := Color(0.18, 0.12, 0.10)
const _C_ACCENT := Color(0.82, 0.14, 0.08)
const SHEET_C1_PATH := "res://assets/pixel/sprites/npcs/nguoi_thu_no_c1_sheet_64.png"
const SHEET_C4_PATH := "res://assets/pixel/sprites/npcs/ba_hac_nguyet_sheet_64.png"
const FRAME_SIZE := 64
const RENDER_SCALE := 2.75

var display_name := "Người Thu Nợ"


func _ready() -> void:
	_build_visual()
	_build_interaction()


func _build_visual() -> void:
	var sheet_path := SHEET_C4_PATH if display_name.contains("Hắc Nguyệt") else SHEET_C1_PATH
	var sprite := _build_animated_sprite(sheet_path)
	if sprite != null:
		add_child(sprite)
	else:
		# Fallback an toàn nếu thiếu ảnh 32-bit
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
	alert.position = Vector2(30, -76)
	alert.size = Vector2(30, 30)
	alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert.add_theme_font_size_override("font_size", 30)
	alert.add_theme_color_override("font_color", _C_ACCENT)
	alert.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.04, 0.92))
	alert.add_theme_constant_override("outline_size", 4)
	add_child(alert)

	var name_lbl := Label.new()
	name_lbl.text = display_name
	name_lbl.position = Vector2(-84, -96)
	name_lbl.size = Vector2(168, 28)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.54))
	name_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.04, 0.92))
	name_lbl.add_theme_constant_override("outline_size", 4)
	add_child(name_lbl)


func _build_animated_sprite(sheet_path: String) -> AnimatedSprite2D:
	var texture := load(sheet_path) as Texture2D
	if texture == null:
		return null
	var sprite := AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 6.0)
	frames.set_animation_loop("idle", true)
	for col in 4:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(col * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
		frames.add_frame("idle", atlas)
	sprite.sprite_frames = frames
	sprite.offset = Vector2(0.0, -16.0)
	sprite.scale = Vector2(RENDER_SCALE, RENDER_SCALE)
	sprite.play("idle")
	return sprite


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
