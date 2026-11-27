class_name BaseCharacter
extends CharacterBody2D

# ══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ══════════════════════════════════════════════════════════════════════════════

signal movement_started
signal movement_stopped
signal facing_changed(new_facing: String)

# ══════════════════════════════════════════════════════════════════════════════
# CONSTANTS & CONFIG
# ══════════════════════════════════════════════════════════════════════════════

const FRAME_W := 64
const FRAME_H := 64
# Điểm chạm chân chuẩn trong ô frame 64x64: (32, 60)
const FEET_X := 32
const FEET_Y := 60

# Hằng số chuyển động mặc định
const DEFAULT_SPEED := 240.0
const DEFAULT_MOVE_ACCEL := 2400.0
const DEFAULT_MOVE_DECEL := 2800.0
const STOP_SPEED_THRESHOLD := 28.0
const DIAGONAL_BIAS := 0.12

# Màu bóng tiếp đất bán trong suốt chuẩn Lò Thiêng
const SHADOW_COLOR := Color(0.06, 0.03, 0.04, 0.42)

# Cache tĩnh SpriteFrames & Shader bóng đổ dùng chung giữa các instance để chuyển scene 0ms
static var _frames_cache: Dictionary = {}
static var _cast_shadow_material: ShaderMaterial = null

# ══════════════════════════════════════════════════════════════════════════════
# EXPORT / CONFIGURABLE PROPERTIES
# ══════════════════════════════════════════════════════════════════════════════

@export var sprite_sheet_path: String = ""
@export var custom_sprite_frames: SpriteFrames = null
@export var render_scale: float = 1.0:
	set(val):
		render_scale = val
		_apply_render_scale()

@export var move_speed: float = DEFAULT_SPEED
@export var move_accel: float = DEFAULT_MOVE_ACCEL
@export var move_decel: float = DEFAULT_MOVE_DECEL
@export var can_move: bool = true:
	set(val):
		can_move = val
		if not can_move:
			velocity = Vector2.ZERO
			move_direction = Vector2.ZERO
			_update_animation(Vector2.ZERO)
@export var enable_footsteps: bool = false
@export var auto_flip_left: bool = true

# Thông số va chạm chân (CapsuleShape2D nằm ngang tại đáy chân: ~34x18 px)
@export var foot_collision_width: float = 34.0
@export var foot_collision_height: float = 18.0
@export var scale_collision_with_render_scale: bool = false

# ══════════════════════════════════════════════════════════════════════════════
# RUNTIME STATE
# ══════════════════════════════════════════════════════════════════════════════

var facing_dir: String = "down":
	set(val):
		if val not in ["down", "up", "left", "right"]:
			return
		if facing_dir == val:
			return
		facing_dir = val
		if _sprite != null:
			_play_directional_anim("idle" if velocity.length() < STOP_SPEED_THRESHOLD else "walk")

var is_movement_locked: bool = false
var move_direction: Vector2 = Vector2.ZERO

var _sprite: AnimatedSprite2D
var _cast_shadow: AnimatedSprite2D
var _shadow: Polygon2D
var _collision_shape: CollisionShape2D
var _emote_anchor: Marker2D

var _shadow_lights: Array[Dictionary] = []
var _shadow_time: float = 0.0
var _shadow_smooth_vec: Vector2 = Vector2.ZERO
var _shadow_smooth_alpha: float = 0.0
var _shadow_initialized: bool = false
var _was_moving: bool = false
var _last_footstep_frame: int = -1
var _footstep_alternate: bool = false


# ══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Bật nội suy vật lý mượt mà trên màn hình tần số quét cao nếu engine hỗ trợ
	if "physics_interpolation_mode" in self:
		physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_INHERIT

	# 1. Bóng tiếp đất (Polygon2D) cố định tại điểm chạm chân (0, 0)
	_shadow = _build_contact_shadow()
	add_child(_shadow)

	# 2. AnimatedSprite2D căn chỉnh điểm chân (32, 60) tại (0, 0) + bóng đổ silhouette theo nguồn sáng
	_sprite = _build_animated_sprite()
	_cast_shadow = _build_cast_shadow_sprite()
	if _cast_shadow != null:
		add_child(_cast_shadow)
	add_child(_sprite)

	# 3. Va chạm bàn chân (CollisionShape2D)
	_collision_shape = _build_foot_collision()
	add_child(_collision_shape)

	# 4. Neo hội thoại / biểu cảm (EmoteAnchor) tại (0, -56)
	_emote_anchor = Marker2D.new()
	_emote_anchor.name = "EmoteAnchor"
	_emote_anchor.position = Vector2(0.0, -56.0 * render_scale)
	add_child(_emote_anchor)

	# Hook âm thanh bước chân khi đổi frame animation
	if _sprite != null:
		_sprite.frame_changed.connect(_on_sprite_frame_changed)

	_apply_render_scale()
	_play_directional_anim("idle")
	_update_directional_shadow(0.0)


func _physics_process(delta: float) -> void:
	var target_vel := Vector2.ZERO
	if can_move and not is_movement_locked:
		target_vel = move_direction * move_speed

	var rate := move_accel if target_vel != Vector2.ZERO else move_decel
	velocity = velocity.move_toward(target_vel, rate * delta)
	move_and_slide()

	_update_movement_signals()
	_update_animation(move_direction)
	_update_directional_shadow(delta)


static func get_cast_shadow_material() -> ShaderMaterial:
	if _cast_shadow_material != null:
		return _cast_shadow_material
	var shd := Shader.new()
	shd.code = """shader_type canvas_item;

uniform vec3 shadow_color : source_color = vec3(0.03, 0.015, 0.025);
varying float v_height_t;

void vertex() {
	// Ban chan nam quanh VERTEX.y = 0.0, dinh dau/tai quanh VERTEX.y = -52.0
	v_height_t = clamp(-VERTEX.y / 52.0, 0.0, 1.0);
}

void fragment() {
	// Mo dan muot tu ban chan (1.0) ra phia dau bong (0.0) de tranh mep cat cung gia tao
	float fade = 1.0 - smoothstep(0.02, 0.96, v_height_t);
	float grad = pow(clamp(fade, 0.0, 1.0), 1.15);
	COLOR = vec4(shadow_color, COLOR.a * grad);
}
"""
	_cast_shadow_material = ShaderMaterial.new()
	_cast_shadow_material.shader = shd
	return _cast_shadow_material


func set_shadow_lights(lights: Array[Dictionary]) -> void:
	_shadow_lights = lights.duplicate(true)
	_shadow_initialized = false
	_update_directional_shadow(0.0)


func _build_cast_shadow_sprite() -> AnimatedSprite2D:
	if _sprite == null or _sprite.sprite_frames == null:
		return null
	var sh := AnimatedSprite2D.new()
	sh.name = "DirectionalCastShadow"
	sh.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sh.sprite_frames = _sprite.sprite_frames
	sh.offset = Vector2(0.0, float(FRAME_H / 2 - FEET_Y))
	sh.z_index = -1
	sh.material = get_cast_shadow_material()
	sh.visible = false
	return sh


func _update_directional_shadow(delta: float) -> void:
	if _cast_shadow == null or _sprite == null:
		return
	if _shadow_lights.is_empty():
		_shadow_smooth_alpha = 0.0
		_shadow_initialized = false
		_cast_shadow.visible = false
		return

	_shadow_time += delta
	var total_vec := Vector2.ZERO
	var total_weight := 0.0
	var target_alpha := 0.0

	for light: Dictionary in _shadow_lights:
		var lpos: Vector2 = light.get("pos", Vector2.ZERO) as Vector2
		var radius: float = maxf(1.0, float(light.get("radius", 500.0)))
		var strength: float = float(light.get("strength", 1.0))
		if strength <= 0.001:
			continue
		var away := global_position - lpos
		var dist := away.length()
		if dist >= radius:
			continue
		# Suy giảm bậc 3 (smoothstep) về 0 tại biên bán kính để bóng mờ dần tự nhiên, không mất ngang
		var t := clampf(1.0 - dist / radius, 0.0, 1.0)
		var falloff := t * t * (3.0 - 2.0 * t)
		var flicker_amp := float(light.get("flicker", 0.0))
		var flick := 1.0 + (sin(_shadow_time * 9.5) * 0.5 + sin(_shadow_time * 15.2) * 0.5) * flicker_amp
		var w := strength * falloff * flick
		if w <= 0.001:
			continue

		var dir := away.normalized() if dist > 1.0 else Vector2(0.0, 1.0)
		var bias: Vector2 = light.get("bias_dir", Vector2.ZERO) as Vector2
		if bias.length_squared() > 0.001:
			dir = (dir * 0.55 + bias.normalized() * 0.45).normalized()

		var max_len := float(light.get("max_length", 0.88))
		var seg_len := lerpf(max_len * 0.60, max_len, falloff) * flick
		total_vec += dir * seg_len * w
		total_weight += w
		var max_a := float(light.get("max_alpha", 0.50))
		target_alpha = maxf(target_alpha, max_a * falloff)

	var target_vec := total_vec / total_weight if total_weight > 0.002 else _shadow_smooth_vec
	if delta <= 0.0 or not _shadow_initialized:
		_shadow_smooth_vec = target_vec
		_shadow_smooth_alpha = target_alpha
		_shadow_initialized = true
	else:
		# Chuyển mượt hướng và độ mờ theo thời gian, không giật hoặc mất bóng đột ngột
		var blend := 1.0 - exp(-9.0 * delta)
		if total_weight > 0.002:
			_shadow_smooth_vec = _shadow_smooth_vec.lerp(target_vec, blend)
		_shadow_smooth_alpha = lerpf(_shadow_smooth_alpha, target_alpha, blend)

	if _shadow_smooth_alpha < 0.006:
		_cast_shadow.visible = false
		return

	# Chiếu 3/4 liên tục trên trục Y, tránh bước nhảy dấu đột ngột khi băng qua nguồn sáng
	var sx := clampf(_shadow_smooth_vec.x, -0.98, 0.98)
	var sy := clampf(_shadow_smooth_vec.y * 0.72 + 0.20, -0.65, 0.80)

	if _cast_shadow.animation != _sprite.animation and _cast_shadow.sprite_frames.has_animation(_sprite.animation):
		_cast_shadow.play(_sprite.animation)
	_cast_shadow.frame = _sprite.frame
	_cast_shadow.flip_h = _sprite.flip_h
	_cast_shadow.visible = true

	# Chân (0,0) bám chặt chân Nấm; đỉnh đầu (0,-56) đổ dọc theo (sx, sy) và mờ dần ra xa qua shader
	var x_axis := Vector2(render_scale, 0.0)
	var y_axis := Vector2(-sx * render_scale, -sy * render_scale)
	_cast_shadow.transform = Transform2D(x_axis, y_axis, Vector2(0.0, 2.0))
	_cast_shadow.modulate = Color(1.0, 1.0, 1.0, clampf(_shadow_smooth_alpha, 0.0, 0.62))


# ══════════════════════════════════════════════════════════════════════════════
# MOVEMENT & DIRECTION LOGIC
# ══════════════════════════════════════════════════════════════════════════════

func _update_movement_signals() -> void:
	var moving := velocity.length() >= STOP_SPEED_THRESHOLD
	if moving and not _was_moving:
		_was_moving = true
		movement_started.emit()
	elif not moving and _was_moving:
		_was_moving = false
		movement_stopped.emit()


func _resolve_facing_direction(v: Vector2) -> String:
	var ax := absf(v.x)
	var ay := absf(v.y)
	# Hysteresis chống rung giật hướng khi di chuyển chéo
	if absf(ax - ay) <= DIAGONAL_BIAS:
		if (facing_dir == "left" and v.x < 0.0) or (facing_dir == "right" and v.x > 0.0):
			return facing_dir
		if (facing_dir == "up" and v.y < 0.0) or (facing_dir == "down" and v.y > 0.0):
			return facing_dir
	if ax >= ay:
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"


func _update_animation(input_vec: Vector2) -> void:
	if _sprite == null:
		return

	var speed := velocity.length()
	if input_vec == Vector2.ZERO and speed < STOP_SPEED_THRESHOLD:
		_sprite.speed_scale = 1.0
		_play_directional_anim("idle")
		if _shadow != null:
			_shadow.scale = Vector2(render_scale, render_scale)
		return

	if input_vec != Vector2.ZERO:
		var new_facing := _resolve_facing_direction(input_vec)
		if new_facing != facing_dir:
			facing_dir = new_facing
			facing_changed.emit(facing_dir)

	var speed_ratio := clampf(speed / 260.0, 0.80, 1.22)
	_sprite.speed_scale = speed_ratio
	var prefix := "run" if move_speed >= 420.0 else "walk"
	_play_directional_anim(prefix)

	# Hiệu ứng nén bóng nhẹ theo nhịp nhấc chân (frame 4 & 12 là điểm tiếp đất ở sheet 16 cột)
	if _shadow != null and _sprite.sprite_frames != null:
		var total_f := _sprite.sprite_frames.get_frame_count(_sprite.animation)
		var is_lifted := (
			(_sprite.frame == 1 or _sprite.frame == 3)
			if total_f <= 4
			else ((_sprite.frame % 8) <= 3)
		)
		var shadow_s := 0.88 if is_lifted else 1.0
		_shadow.scale = Vector2(shadow_s, shadow_s) * render_scale


func _play_directional_anim(prefix: String) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return

	var anim_name := ""
	if facing_dir == "left" and auto_flip_left:
		_sprite.flip_h = true
		anim_name = prefix + "_right"
		if not _sprite.sprite_frames.has_animation(anim_name):
			if _sprite.sprite_frames.has_animation(prefix + "_left"):
				_sprite.flip_h = false
				anim_name = prefix + "_left"
			elif _sprite.sprite_frames.has_animation(prefix):
				anim_name = prefix
	else:
		_sprite.flip_h = false
		anim_name = prefix + "_" + facing_dir
		if not _sprite.sprite_frames.has_animation(anim_name):
			if _sprite.sprite_frames.has_animation(prefix):
				anim_name = prefix

	_play_animation_internal(anim_name)


func _play_animation_internal(anim_name: String) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	if not _sprite.sprite_frames.has_animation(anim_name):
		return
	if _sprite.animation == anim_name and _sprite.is_playing():
		return

	var prev_frame := _sprite.frame
	var prev_progress := _sprite.frame_progress
	var was_walk := _sprite.animation.begins_with("walk") or _sprite.animation.begins_with("run")
	var is_walk := anim_name.begins_with("walk") or anim_name.begins_with("run")
	_sprite.play(anim_name)

	# Giữ nguyên pha bước chân khi đổi hướng đột ngột (không giật khung hình)
	if was_walk and is_walk:
		if _sprite.has_method("set_frame_and_progress"):
			_sprite.set_frame_and_progress(prev_frame, prev_progress)
		else:
			_sprite.frame = prev_frame


# ══════════════════════════════════════════════════════════════════════════════
# FOOTSTEP AUDIO HOOK
# ══════════════════════════════════════════════════════════════════════════════

func _on_sprite_frame_changed() -> void:
	if not enable_footsteps:
		return
	if velocity.length() < STOP_SPEED_THRESHOLD:
		return
	if _sprite == null:
		return

	var anim := _sprite.animation
	if not (anim.begins_with("walk") or anim.begins_with("run")):
		return

	var cur_frame := _sprite.frame
	var total_frames := 16
	if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(anim):
		total_frames = _sprite.sprite_frames.get_frame_count(anim)

	var is_step := false
	if total_frames <= 4:
		is_step = (cur_frame == 0 or cur_frame == 2)
	elif total_frames <= 8:
		is_step = (cur_frame == 1 or cur_frame == 5)
	else:
		# 16 frame chuẩn: điểm tiếp đất là frame 4 và 12
		is_step = (cur_frame == 4 or cur_frame == 12)

	if is_step and cur_frame != _last_footstep_frame:
		_last_footstep_frame = cur_frame
		_play_footstep_sound()


func _play_footstep_sound() -> void:
	var key := "footstep_wood_1" if _footstep_alternate else "footstep_wood_2"
	_footstep_alternate = not _footstep_alternate
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play_sfx_key"):
		var pitch := randf_range(0.92, 1.08)
		audio.play_sfx_key(key, 0.45, pitch)


# ══════════════════════════════════════════════════════════════════════════════
# BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

func _build_contact_shadow() -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = "ContactShadow"
	poly.color = SHADOW_COLOR
	poly.position = Vector2.ZERO
	poly.z_index = -1
	var pts := PackedVector2Array()
	var segs := 14
	var rx := 7.67
	var ry := 2.5
	for i in range(segs):
		var ang := (float(i) / float(segs)) * TAU
		pts.append(Vector2(cos(ang) * rx, sin(ang) * ry))
	poly.polygon = pts
	poly.scale = Vector2(render_scale, render_scale)
	return poly


func _build_animated_sprite() -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Tâm frame là (32, 32). Điểm chân là (32, 60).
	# Offset (0, -28) căn chỉnh chân (32, 60) trùng chính xác (0, 0) của character.
	sprite.offset = Vector2(0.0, float(FRAME_H / 2 - FEET_Y))
	sprite.position = Vector2.ZERO
	sprite.scale = Vector2(render_scale, render_scale)

	var frames := custom_sprite_frames
	if frames == null and not sprite_sheet_path.is_empty():
		frames = get_or_build_frames(sprite_sheet_path)

	if frames != null:
		sprite.sprite_frames = frames

	return sprite


func _build_foot_collision() -> CollisionShape2D:
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape := CapsuleShape2D.new()
	var s := render_scale if scale_collision_with_render_scale else 1.0
	shape.radius = (foot_collision_height * 0.5) * s
	shape.height = foot_collision_width * s
	col.shape = shape
	col.rotation = deg_to_rad(90.0)
	col.position = Vector2(0.0, -shape.radius)
	return col


func _apply_render_scale() -> void:
	if _sprite != null:
		_sprite.scale = Vector2(render_scale, render_scale)
	if _shadow != null:
		_shadow.scale = Vector2(render_scale, render_scale)
	if _emote_anchor != null:
		_emote_anchor.position = Vector2(0.0, -56.0 * render_scale)
	if _collision_shape != null and _collision_shape.shape is CapsuleShape2D:
		var cap := _collision_shape.shape as CapsuleShape2D
		var s := render_scale if scale_collision_with_render_scale else 1.0
		cap.radius = (foot_collision_height * 0.5) * s
		cap.height = foot_collision_width * s
		_collision_shape.position = Vector2(0.0, -cap.radius)


# ══════════════════════════════════════════════════════════════════════════════
# SPRITE FRAMES FACTORY
# ══════════════════════════════════════════════════════════════════════════════

static func get_or_build_frames(sheet_path: String) -> SpriteFrames:
	if _frames_cache.has(sheet_path):
		return _frames_cache[sheet_path]

	var texture := load(sheet_path) as Texture2D
	if texture == null:
		push_error("BaseCharacter: Không load được sprite sheet: %s" % sheet_path)
		return null

	var frames := SpriteFrames.new()
	var cols := int(texture.get_width() / FRAME_W)
	var rows := int(texture.get_height() / FRAME_H)

	if cols < 1 or rows < 1:
		push_error("BaseCharacter: Kích thước sheet không hợp lệ: %s" % sheet_path)
		return null

	var idle_fps := 6.0 if cols <= 4 else (8.0 if cols <= 8 else 12.0)
	var walk_fps := 10.0 if cols <= 4 else (14.0 if cols <= 8 else 24.0)
	var run_fps := 14.0 if cols <= 4 else (18.0 if cols <= 8 else 28.0)
	var hurt_fps := 12.0 if cols <= 4 else 16.0
	var special_fps := 12.0 if cols <= 4 else 18.0

	# Chuẩn NPC / Customer / Enemy 4 hàng (4x4 256x256 hoặc 16x4 1024x256): Row 0=idle, 1=walk, 2=attack, 3=hurt
	if rows == 4:
		var defs_4row: Array[Dictionary] = [
			{"name": "idle",   "row": 0, "fps": idle_fps,    "loop": true,  "max_f": cols},
			{"name": "walk",   "row": 1, "fps": walk_fps,    "loop": true,  "max_f": cols},
			{"name": "attack", "row": 2, "fps": special_fps, "loop": false, "max_f": mini(cols, 8)},
			{"name": "hurt",   "row": 3, "fps": hurt_fps,    "loop": false, "max_f": mini(cols, 8)},
		]
		for d4: Dictionary in defs_4row:
			var aname: String = d4["name"]
			if frames.has_animation(aname):
				frames.clear(aname)
			else:
				frames.add_animation(aname)
			frames.set_animation_speed(aname, d4["fps"])
			frames.set_animation_loop(aname, d4["loop"])
			for c in range(int(d4["max_f"])):
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(c * FRAME_W, int(d4["row"]) * FRAME_H, FRAME_W, FRAME_H)
				frames.add_frame(aname, atlas)
		for dir_s: String in ["down", "up", "right", "left"]:
			_alias_anim(frames, "idle_" + dir_s, "idle")
			_alias_anim(frames, "walk_" + dir_s, "walk")
			_alias_anim(frames, "run_" + dir_s, "walk")
		_alias_anim(frames, "run", "walk")
		_alias_anim(frames, "special", "attack")
		_frames_cache[sheet_path] = frames
		return frames

	var defs: Array[Dictionary] = [
		{"name": "idle_down",  "row": 0,  "fps": idle_fps,    "loop": true,  "max_f": cols},
		{"name": "idle_up",    "row": 1,  "fps": idle_fps,    "loop": true,  "max_f": cols},
		{"name": "idle_right", "row": 2,  "fps": idle_fps,    "loop": true,  "max_f": cols},
		{"name": "idle_left",  "row": 3,  "fps": idle_fps,    "loop": true,  "max_f": cols},
		{"name": "walk_down",  "row": 4,  "fps": walk_fps,    "loop": true,  "max_f": cols},
		{"name": "walk_up",    "row": 5,  "fps": walk_fps,    "loop": true,  "max_f": cols},
		{"name": "walk_right", "row": 6,  "fps": walk_fps,    "loop": true,  "max_f": cols},
		{"name": "walk_left",  "row": 7,  "fps": walk_fps,    "loop": true,  "max_f": cols},
		{"name": "run_down",   "row": 8,  "fps": run_fps,     "loop": true,  "max_f": cols},
		{"name": "run_up",     "row": 9,  "fps": run_fps,     "loop": true,  "max_f": cols},
		{"name": "run_right",  "row": 10, "fps": run_fps,     "loop": true,  "max_f": cols},
		{"name": "run_left",   "row": 11, "fps": run_fps,     "loop": true,  "max_f": cols},
		{"name": "hurt",       "row": 12, "fps": hurt_fps,    "loop": false, "max_f": mini(cols, 8)},
		{"name": "special",    "row": 13, "fps": special_fps, "loop": false, "max_f": mini(cols, 8)},
	]

	for definition: Dictionary in defs:
		var r: int = definition["row"]
		if r >= rows:
			continue
		var anim_name: String = definition["name"]
		if frames.has_animation(anim_name):
			frames.clear(anim_name)
		else:
			frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, definition["fps"])
		frames.set_animation_loop(anim_name, definition["loop"])
		var count: int = definition["max_f"]
		for c in range(count):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(c * FRAME_W, r * FRAME_H, FRAME_W, FRAME_H)
			frames.add_frame(anim_name, atlas)

	# Fallbacks / Aliases tương thích ngược cho Combat hoặc Script cũ
	_alias_anim(frames, "idle", "idle_right" if rows > 2 else "idle_down")
	_alias_anim(frames, "walk", "walk_right" if rows > 6 else "walk_down")
	_alias_anim(frames, "run",  "run_right" if rows > 10 else "run_down")
	_alias_anim(frames, "attack", "special")

	_frames_cache[sheet_path] = frames
	return frames


static func clear_frames_cache() -> void:
	_frames_cache.clear()


static func _alias_anim(frames: SpriteFrames, alias_name: String, source_name: String) -> void:
	if not frames.has_animation(source_name):
		return
	if frames.has_animation(alias_name):
		frames.clear(alias_name)
	else:
		frames.add_animation(alias_name)
	frames.set_animation_speed(alias_name, frames.get_animation_speed(source_name))
	frames.set_animation_loop(alias_name, frames.get_animation_loop(source_name))
	var frame_count := frames.get_frame_count(source_name)
	for i in range(frame_count):
		frames.add_frame(alias_name, frames.get_frame_texture(source_name, i))


# ══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ══════════════════════════════════════════════════════════════════════════════

func play_anim(name: String) -> void:
	_play_animation_internal(name)


func set_facing(dir: String) -> void:
	if dir not in ["down", "up", "left", "right"]:
		return
	facing_dir = dir


func set_can_move(val: bool) -> void:
	can_move = val


func lock_movement() -> void:
	is_movement_locked = true
	velocity = Vector2.ZERO
	move_direction = Vector2.ZERO
	_update_animation(Vector2.ZERO)


func unlock_movement() -> void:
	is_movement_locked = false


func set_render_scale(val: float) -> void:
	render_scale = val


func get_facing() -> String:
	return facing_dir


func is_moving() -> bool:
	return velocity.length() >= STOP_SPEED_THRESHOLD


func get_emote_position() -> Vector2:
	if _emote_anchor != null:
		return _emote_anchor.global_position
	return global_position + Vector2(0.0, -56.0 * render_scale)


func get_sprite() -> AnimatedSprite2D:
	return _sprite


func get_shadow() -> Polygon2D:
	return _shadow


func get_collision_shape() -> CollisionShape2D:
	return _collision_shape


func get_emote_anchor() -> Marker2D:
	return _emote_anchor
