extends CharacterBody2D

const DEFAULT_SPEED := 360.0
const SPRITE_SHEET_PATH := "res://assets/sprites/players/sprite sheet_Nấm.png"
const FRAME_W := 768
const FRAME_H := 448
const SPRITE_RENDER_SCALE := 0.5

var move_speed := DEFAULT_SPEED
var _sprite: AnimatedSprite2D


func _ready() -> void:
	_sprite = _build_sprite()
	add_child(_sprite)

	# Collision khớp với thân
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(44, 56)
	col.shape = shape
	add_child(col)

	# Layer 1 = player; mask 4 = tường/nội thất, mask 8 = rào chỉ-player (khe cửa tiệm)
	collision_layer = 1
	collision_mask  = 12


func _physics_process(_delta: float) -> void:
	var x := 0.0
	var y := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  y += 1.0
	velocity = Vector2(x, y).normalized() * move_speed
	move_and_slide()
	_update_animation()


func _build_sprite() -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	var texture := load(SPRITE_SHEET_PATH) as Texture2D
	if texture == null:
		push_error("Không load được sprite sheet player: %s" % SPRITE_SHEET_PATH)
		return sprite

	var defs: Array[Dictionary] = [
		{"name": "idle", "row": 0, "count": 4, "fps": 6.0, "loop": true},
		{"name": "walk", "row": 1, "count": 4, "fps": 8.0, "loop": true},
		{"name": "run", "row": 5, "count": 4, "fps": 12.0, "loop": true},
		{"name": "hurt", "row": 6, "count": 4, "fps": 10.0, "loop": false},
		{"name": "special", "row": 7, "count": 1, "fps": 1.0, "loop": false},
	]

	for definition: Dictionary in defs:
		var anim_name: String = definition["name"]
		var row: int = definition["row"]
		var frame_count: int = definition["count"]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, definition["fps"])
		frames.set_animation_loop(anim_name, definition["loop"])
		for col in frame_count:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(col * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)
			frames.add_frame(anim_name, atlas)

	sprite.sprite_frames = frames
	sprite.scale = Vector2(SPRITE_RENDER_SCALE, SPRITE_RENDER_SCALE)
	sprite.play("idle")
	return sprite


func _update_animation() -> void:
	if _sprite == null:
		return
	if velocity == Vector2.ZERO:
		_play_animation("idle")
		return
	_play_animation("walk")
	if velocity.x < 0.0:
		_sprite.flip_h = true
	elif velocity.x > 0.0:
		_sprite.flip_h = false


func _play_animation(anim_name: String) -> void:
	if _sprite.animation == anim_name and _sprite.is_playing():
		return
	_sprite.play(anim_name)
