class_name DebtAgentNode
extends Node2D

signal player_entered
signal player_exited

const _C_BODY   := Color(0.18, 0.12, 0.10)
const _C_ACCENT := Color(0.82, 0.14, 0.08)
const SHEET_C1_PATH := "res://assets/pixel/sprites/npcs/nguoi_thu_no_c1_sheet_64.png"
const SHEET_C2_PATH := "res://assets/pixel/sprites/npcs/tay_sai_rung_c2_sheet_64.png"
const SHEET_C4_PATH := "res://assets/pixel/sprites/npcs/ba_hac_nguyet_sheet_64.png"
const FRAME_SIZE := 64
const RENDER_SCALE := 2.75
const SHADOW_COLOR := Color(0.06, 0.03, 0.04, 0.42)

var display_name := "Người Thu Nợ"
var interactable_enabled := true
var light_origin := Vector2(220.0, 720.0)   # Tâm nguồn sáng từ cửa ngoài bên trái

var _sprite: AnimatedSprite2D = null
var _cast_shadow: AnimatedSprite2D = null
var _shadow: Polygon2D = null
var _alert_lbl: Label = null
var _area: Area2D = null
var _faces_left_by_default := false
var _facing_dir := "right"
var _has_4dir := false
var _is_walking := false
var _prev_pos := Vector2.ZERO
var _last_footstep_frame := -1
var _footstep_alternate := false


func _ready() -> void:
	if "physics_interpolation_mode" in self:
		physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_INHERIT
	_prev_pos = position
	_build_visual()
	_build_interaction()
	set_interactable(interactable_enabled)
	_update_cast_shadow()


func _process(delta: float) -> void:
	if _is_walking and delta > 0.0001 and _sprite != null and _sprite.sprite_frames != null:
		var inst_speed := (position - _prev_pos).length() / delta
		_sprite.speed_scale = clampf(inst_speed / 220.0, 0.72, 1.35)
		if _shadow != null:
			var total_f := _sprite.sprite_frames.get_frame_count(_sprite.animation)
			var cur_f := _sprite.frame
			var is_lifted := (
				(cur_f == 1 or cur_f == 3)
				if total_f <= 4
				else ((cur_f % 8) <= 3)
			)
			var shadow_s := 0.88 if is_lifted else 1.0
			_shadow.scale = Vector2(shadow_s, shadow_s)
	_prev_pos = position
	_update_cast_shadow()


func _build_visual() -> void:
	var sheet_path := SHEET_C1_PATH
	_faces_left_by_default = false
	if display_name.contains("Hắc Nguyệt"):
		sheet_path = SHEET_C4_PATH
	elif display_name.contains("Rừng") or name.contains("C2"):
		sheet_path = SHEET_C2_PATH

	# 1. Bóng tiếp đất chuẩn BaseCharacter tại (0, 0)
	_shadow = Polygon2D.new()
	_shadow.name = "ContactShadow"
	_shadow.color = SHADOW_COLOR
	_shadow.z_index = -1
	var pts := PackedVector2Array()
	for i in range(14):
		var ang := (float(i) / 14.0) * TAU
		pts.append(Vector2(cos(ang) * 8.0, sin(ang) * 2.6) * RENDER_SCALE)
	_shadow.polygon = pts
	add_child(_shadow)

	# 2. Sprite 32-bit hỗ trợ cả idle lẫn walk + bóng đổ silhouette hắt theo chiều sáng cửa trái
	var tex := load(sheet_path) as Texture2D
	_has_4dir = tex != null and tex.get_height() >= FRAME_SIZE * 8
	_sprite = _build_animated_sprite(sheet_path)
	if _sprite != null:
		_sprite.frame_changed.connect(_on_sprite_frame_changed)
		_cast_shadow = AnimatedSprite2D.new()
		_cast_shadow.name = "DirectionalCastShadow"
		_cast_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_cast_shadow.sprite_frames = _sprite.sprite_frames
		_cast_shadow.offset = Vector2(0.0, -28.0)
		_cast_shadow.z_index = -1
		_cast_shadow.material = BaseCharacter.get_cast_shadow_material()
		_cast_shadow.modulate = Color(1.0, 1.0, 1.0, 0.52)
		_play_directional_anim("idle")
		_cast_shadow.play(_sprite.animation)
		add_child(_cast_shadow)
		add_child(_sprite)
	else:
		var body := ColorRect.new()
		body.position = Vector2(-18, -52)
		body.size = Vector2(36, 52)
		body.color = _C_BODY
		add_child(body)

	_alert_lbl = Label.new()
	_alert_lbl.text = "!"
	_alert_lbl.position = Vector2(28, -148)
	_alert_lbl.size = Vector2(30, 30)
	_alert_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_alert_lbl.add_theme_font_size_override("font_size", 30)
	_alert_lbl.add_theme_color_override("font_color", _C_ACCENT)
	_alert_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.04, 0.92))
	_alert_lbl.add_theme_constant_override("outline_size", 4)
	add_child(_alert_lbl)

	var name_lbl := Label.new()
	name_lbl.text = display_name
	name_lbl.position = Vector2(-92, -168)
	name_lbl.size = Vector2(184, 28)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.54))
	name_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.04, 0.92))
	name_lbl.add_theme_constant_override("outline_size", 4)
	add_child(name_lbl)


func _build_animated_sprite(sheet_path: String) -> AnimatedSprite2D:
	var frames: SpriteFrames = BaseCharacter.get_or_build_frames(sheet_path)
	if frames == null:
		return null
	var sprite := AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = frames
	sprite.offset = Vector2(0.0, -28.0)
	sprite.scale = Vector2(RENDER_SCALE, RENDER_SCALE)
	sprite.play("idle")
	return sprite


func _build_interaction() -> void:
	_area = Area2D.new()
	_area.name = "DebtAgentInteraction"
	_area.collision_layer = 0
	_area.collision_mask = 1
	add_child(_area)

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(104, 112)
	col.shape = rect
	col.position = Vector2(0.0, -40.0)
	_area.add_child(col)

	_area.body_entered.connect(func(_b: Node) -> void:
		if interactable_enabled:
			player_entered.emit()
	)
	_area.body_exited.connect(func(_b: Node) -> void:
		player_exited.emit()
	)


func set_interactable(enabled: bool) -> void:
	interactable_enabled = enabled
	if _area != null:
		_area.monitoring = enabled
	if _alert_lbl != null:
		_alert_lbl.visible = enabled


func face_direction(dir: String) -> void:
	if dir not in ["down", "up", "left", "right"]:
		return
	_facing_dir = dir
	_play_directional_anim("walk" if _is_walking else "idle")


func face_horizontal(dir_x: float) -> void:
	if absf(dir_x) < 0.01:
		return
	face_direction("right" if dir_x > 0.0 else "left")


func _play_directional_anim(prefix: String) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var anim_name := prefix
	if _has_4dir:
		_sprite.flip_h = false
		var candidate := "%s_%s" % [prefix, _facing_dir]
		if _sprite.sprite_frames.has_animation(candidate):
			anim_name = candidate
	else:
		if _faces_left_by_default:
			_sprite.flip_h = (_facing_dir == "right")
		else:
			_sprite.flip_h = (_facing_dir == "left")
	if _sprite.sprite_frames.has_animation(anim_name):
		if _sprite.animation != anim_name or not _sprite.is_playing():
			_sprite.play(anim_name)


func _on_sprite_frame_changed() -> void:
	if not _is_walking or _sprite == null or _sprite.sprite_frames == null:
		return
	var anim := _sprite.animation
	if not anim.begins_with("walk"):
		return
	var cur_frame := _sprite.frame
	var total_frames := _sprite.sprite_frames.get_frame_count(anim)
	var is_step := false
	if total_frames <= 4:
		is_step = (cur_frame == 0 or cur_frame == 2)
	elif total_frames <= 8:
		is_step = (cur_frame == 1 or cur_frame == 5)
	else:
		is_step = (cur_frame == 4 or cur_frame == 12)
	if is_step and cur_frame != _last_footstep_frame:
		_last_footstep_frame = cur_frame
		var key := "footstep_wood_1" if _footstep_alternate else "footstep_wood_2"
		_footstep_alternate = not _footstep_alternate
		var audio := get_node_or_null("/root/AudioManager")
		if audio != null and audio.has_method("play_sfx_key"):
			audio.play_sfx_key(key, 0.35, randf_range(0.90, 1.06))


func walk_to(target_pos: Vector2, speed: float = 240.0) -> void:
	var delta := target_pos - position
	var dist := delta.length()
	if dist < 2.0:
		position = target_pos
		return
	if absf(delta.x) >= absf(delta.y) or not _has_4dir:
		face_direction("right" if delta.x >= 0.0 else "left")
	else:
		face_direction("down" if delta.y >= 0.0 else "up")
	_is_walking = true
	_prev_pos = position
	_last_footstep_frame = -1
	_play_directional_anim("walk")
	var duration := clampf(dist / maxf(40.0, speed), 0.35, 2.2)
	var tw := create_tween()
	tw.tween_property(self, "position", target_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	if is_instance_valid(self):
		_is_walking = false
		if _sprite != null:
			_sprite.speed_scale = 1.0
		if _shadow != null:
			_shadow.scale = Vector2.ONE
		_play_directional_anim("idle")


func _update_cast_shadow() -> void:
	if _cast_shadow == null or _sprite == null:
		return
	# Đồng bộ frame, animation và hướng lật để bóng đổ silhouette khớp từng bước chân
	if _cast_shadow.animation != _sprite.animation:
		_cast_shadow.play(_sprite.animation)
	_cast_shadow.frame = _sprite.frame
	_cast_shadow.flip_h = _sprite.flip_h

	# Tính hướng hắt bóng ngược chiều tia sáng từ cửa ngoài bên trái
	var away := global_position - light_origin
	var dist := away.length()
	var dir := away.normalized() if dist > 1.0 else Vector2(0.95, 0.24)
	# Độ dài & độ đậm bóng giảm mượt (smoothstep) khi bước sâu vào giữa phòng rời khỏi luồng nắng cửa
	var t := clampf(1.0 - (dist - 100.0) / 840.0, 0.0, 1.0)
	var beam_t := t * t * (3.0 - 2.0 * t)
	var len_mult := lerpf(0.62, 0.92, beam_t)
	var thickness := lerpf(0.32, 0.44, beam_t)
	var alpha := lerpf(0.24, 0.58, beam_t)

	# Chiếu silhouette có độ dày 3/4 rõ dáng gà lên mặt sàn, mờ dần về phía đầu bóng
	var x_axis := Vector2(RENDER_SCALE, 0.0)
	var y_axis := Vector2(
		-dir.x * len_mult * RENDER_SCALE,
		-thickness * RENDER_SCALE
	)
	_cast_shadow.transform = Transform2D(x_axis, y_axis, Vector2(0.0, 2.0))
	_cast_shadow.modulate = Color(1.0, 1.0, 1.0, alpha)
