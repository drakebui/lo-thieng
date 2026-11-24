class_name PlayerShop
extends "res://scripts/characters/base_character.gd"

# ══════════════════════════════════════════════════════════════════════════════
# CONSTANTS & CONFIG (PIXEL ART PLAYER NẤM)
# ══════════════════════════════════════════════════════════════════════════════

# [PIXEL ART CONFIG] Chuẩn 32-bit 4 hướng, 16 frame/chu kỳ @ 24 FPS
# Scale nguyên 3.0x trong phòng/tiệm (192px), chân gắn chặt đáy va chạm (0, 0)
const SPRITE_SHEET_PATH := "res://assets/pixel/sprites/player/nam_4dir_sheet_64.png"
const PLAYER_SPEED := 360.0
const SPRITE_RENDER_SCALE := 3.0

const IDLE_FPS := 12.0
const WALK_FPS := 24.0
const RUN_FPS := 28.0
const HURT_FPS := 16.0
const SPECIAL_FPS := 18.0

# ══════════════════════════════════════════════════════════════════════════════
# PLAYER STATS
# ══════════════════════════════════════════════════════════════════════════════

var stamina: float = 100.0
var max_stamina: float = 100.0
var is_running: bool = false


# ══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════════

func _init() -> void:
	sprite_sheet_path = SPRITE_SHEET_PATH
	render_scale = SPRITE_RENDER_SCALE
	move_speed = PLAYER_SPEED
	# Layer 1 = player; mask 4 = tường/nội thất, mask 8 = rào chỉ-player (khe cửa tiệm)
	collision_layer = 1
	collision_mask = 12


func _ready() -> void:
	super._ready()


func _physics_process(delta: float) -> void:
	if can_move and not is_movement_locked:
		move_direction = _read_move_input()
	else:
		move_direction = Vector2.ZERO

	super._physics_process(delta)


# ══════════════════════════════════════════════════════════════════════════════
# PLAYER INPUT
# ══════════════════════════════════════════════════════════════════════════════

func _read_move_input() -> Vector2:
	var x := 0.0
	var y := 0.0
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		x -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		x += 1.0
	if Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		y -= 1.0
	if Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		y += 1.0
	var v := Vector2(x, y)
	return v.normalized() if v.length_squared() > 0.0 else Vector2.ZERO


# ══════════════════════════════════════════════════════════════════════════════
# COMPATIBILITY HELPERS
# ══════════════════════════════════════════════════════════════════════════════

static func _get_or_build_sprite_frames() -> SpriteFrames:
	return get_or_build_frames(SPRITE_SHEET_PATH)
