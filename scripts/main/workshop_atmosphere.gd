class_name WorkshopAtmosphere
extends Node2D

# Hiệu ứng môi trường 32-bit cho WorkshopHub:
# - Ánh lửa lò rèn bập bùng + hạt tàn lửa pixel bay lên
# - Quầng sáng nến (bục Bí Kíp) và đèn lồng (cạnh giường & cửa Tiệm)
# - Đổi tông ánh sáng theo 4 buổi (Sáng / Trưa / Chiều / Đêm)
# - Huy hiệu [E] nổi mượt trên đầu vật thể / NPC khi Nấm lại gần

const MAX_EMBERS := 18

var _vp: Vector2 = Vector2(1920, 1080)
var _phase: int = 0
var _time: float = 0.0
var _embers: Array[Dictionary] = []

var _prompt_root: Node2D = null
var _prompt_panel: PanelContainer = null
var _prompt_key_lbl: Label = null
var _prompt_text_lbl: Label = null
var _prompt_base_pos: Vector2 = Vector2.ZERO
var _prompt_visible: bool = false


func setup(viewport_size: Vector2, initial_phase: int) -> void:
	_vp = viewport_size
	_phase = initial_phase
	z_index = 40
	_init_embers()
	_build_floating_prompt()
	queue_redraw()


func set_phase(new_phase: int) -> void:
	_phase = new_phase
	queue_redraw()


func show_prompt(world_pos: Vector2, label_text: String) -> void:
	if _prompt_root == null:
		return
	_prompt_base_pos = world_pos
	_prompt_text_lbl.text = label_text
	_prompt_visible = true
	_prompt_root.visible = true
	_prompt_root.position = world_pos


func hide_prompt() -> void:
	_prompt_visible = false
	if _prompt_root != null:
		_prompt_root.visible = false


func _process(delta: float) -> void:
	_time += delta
	_update_embers(delta)
	if _prompt_visible and _prompt_root != null:
		var bob := sin(_time * 4.5) * 4.0
		_prompt_root.position = _prompt_base_pos + Vector2(0.0, bob)
	queue_redraw()


func _draw() -> void:
	var night_boost := 1.45 if _phase == GameManager.GamePhase.NIGHT else 1.0
	var flicker_a := 0.85 + sin(_time * 9.5) * 0.10 + sin(_time * 17.3) * 0.05
	var flicker_b := 0.88 + sin(_time * 6.8 + 1.4) * 0.08 + sin(_time * 13.1) * 0.04

	# 1. Phủ tông ánh sáng môi trường theo 4 buổi trong ngày
	_draw_phase_tint()

	# 2. Quầng sáng lửa lò rèn (cửa lò chính & hộc than dưới)
	var forge_mouth := Vector2(_vp.x * 0.305, _vp.y * 0.335)
	_draw_warm_glow(
		forge_mouth,
		_vp.x * 0.095 * flicker_a,
		Color(1.0, 0.48, 0.10, 0.24 * night_boost * flicker_a)
	)
	_draw_warm_glow(
		forge_mouth + Vector2(0.0, _vp.y * 0.115),
		_vp.x * 0.045 * flicker_b,
		Color(1.0, 0.32, 0.06, 0.20 * night_boost * flicker_b)
	)

	# 3. Ánh nến & đèn dầu trên bục Bí Kíp Rèn
	var book_candle := Vector2(_vp.x * 0.598, _vp.y * 0.215)
	_draw_warm_glow(
		book_candle,
		_vp.x * 0.042 * flicker_b,
		Color(1.0, 0.78, 0.32, 0.18 * night_boost * flicker_b)
	)

	# 4. Đèn lồng treo cạnh cửa sổ & đèn lồng cửa sang Tiệm
	var bed_lantern := Vector2(_vp.x * 0.685, _vp.y * 0.205)
	_draw_warm_glow(
		bed_lantern,
		_vp.x * 0.052 * flicker_b,
		Color(1.0, 0.72, 0.28, 0.20 * night_boost * flicker_b)
	)
	var shop_lantern := Vector2(_vp.x * 0.905, _vp.y * 0.640)
	_draw_warm_glow(
		shop_lantern,
		_vp.x * 0.048 * flicker_a,
		Color(1.0, 0.68, 0.24, 0.22 * night_boost * flicker_a)
	)

	# 5. Hạt tàn lửa pixel bay lên quanh lò rèn & đe sắt
	for ember: Dictionary in _embers:
		var pos: Vector2 = ember["pos"]
		var sz: float = ember["size"]
		var alpha: float = clampf(ember["life"] / ember["max_life"], 0.0, 1.0)
		var col: Color = ember["color"]
		col.a = alpha * 0.92
		draw_rect(Rect2(pos, Vector2(sz, sz)), col)


func _draw_phase_tint() -> void:
	var full := Rect2(Vector2.ZERO, _vp)
	match _phase:
		GameManager.GamePhase.MORNING:
			# Nắng sớm dịu hắt chéo từ cửa trái vào sàn gỗ
			var sun_poly := PackedVector2Array([
				Vector2(_vp.x * 0.115, _vp.y * 0.49),
				Vector2(_vp.x * 0.245, _vp.y * 0.60),
				Vector2(_vp.x * 0.315, _vp.y * 0.80),
				Vector2(_vp.x * 0.125, _vp.y * 0.80),
			])
			draw_colored_polygon(sun_poly, Color(1.0, 0.92, 0.65, 0.11))
		GameManager.GamePhase.NOON:
			draw_rect(full, Color(1.0, 0.96, 0.88, 0.03))
		GameManager.GamePhase.AFTERNOON:
			draw_rect(full, Color(0.86, 0.44, 0.12, 0.11))
		GameManager.GamePhase.NIGHT:
			# Dịu ánh sáng ban ngày ở cửa mở trái & cửa sổ cạnh giường khi về đêm
			draw_rect(
				Rect2(Vector2(_vp.x * 0.115, _vp.y * 0.48), Vector2(_vp.x * 0.04, _vp.y * 0.30)),
				Color(0.04, 0.06, 0.16, 0.62)
			)
			draw_rect(
				Rect2(Vector2(_vp.x * 0.71, _vp.y * 0.125), Vector2(_vp.x * 0.085, _vp.y * 0.105)),
				Color(0.04, 0.06, 0.16, 0.68)
			)
			draw_rect(full, Color(0.05, 0.07, 0.18, 0.34))


func _draw_warm_glow(center: Vector2, radius: float, color: Color) -> void:
	var rings := 3
	for i in range(rings, 0, -1):
		var frac := float(i) / float(rings)
		var col := color
		col.a = color.a * (1.15 - frac * 0.72)
		draw_circle(center, radius * frac, col)


func _init_embers() -> void:
	_embers.clear()
	for _i in MAX_EMBERS:
		var e := _spawn_ember(true)
		_embers.append(e)


func _spawn_ember(random_progress: bool) -> Dictionary:
	var origin_x := randf_range(_vp.x * 0.265, _vp.x * 0.355)
	var origin_y := randf_range(_vp.y * 0.34, _vp.y * 0.46)
	var max_life := randf_range(1.4, 2.8)
	var life := randf_range(0.2, max_life) if random_progress else max_life
	var palette: Array[Color] = [
		Color(1.00, 0.88, 0.34),
		Color(1.00, 0.56, 0.14),
		Color(0.95, 0.30, 0.08),
	]
	return {
		"pos": Vector2(origin_x, origin_y),
		"vel": Vector2(randf_range(-16.0, 22.0), randf_range(-42.0, -20.0)),
		"life": life,
		"max_life": max_life,
		"size": 4.0 if randf() < 0.65 else 6.0,
		"color": palette[randi() % palette.size()],
		"phase": randf_range(0.0, TAU),
	}


func _update_embers(delta: float) -> void:
	for i in _embers.size():
		var e: Dictionary = _embers[i]
		e["life"] = float(e["life"]) - delta
		if float(e["life"]) <= 0.0:
			_embers[i] = _spawn_ember(false)
			continue
		var pos: Vector2 = e["pos"]
		var vel: Vector2 = e["vel"]
		var sway := sin(_time * 3.5 + float(e["phase"])) * 18.0
		pos.x += (vel.x + sway) * delta
		pos.y += vel.y * delta
		e["pos"] = pos
		_embers[i] = e


func _build_floating_prompt() -> void:
	_prompt_root = Node2D.new()
	_prompt_root.name = "FloatingZonePrompt"
	_prompt_root.z_index = 60
	_prompt_root.visible = false
	add_child(_prompt_root)

	_prompt_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.055, 0.035, 0.94)
	style.border_color = Color(0.92, 0.72, 0.30, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	_prompt_panel.add_theme_stylebox_override("panel", style)
	_prompt_panel.position = Vector2(-115.0, -48.0)
	_prompt_root.add_child(_prompt_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	_prompt_panel.add_child(hbox)

	var key_box := PanelContainer.new()
	var key_style := StyleBoxFlat.new()
	key_style.bg_color = Color(0.92, 0.72, 0.24, 1.0)
	key_style.set_corner_radius_all(4)
	key_style.content_margin_left = 7
	key_style.content_margin_right = 7
	key_style.content_margin_top = 2
	key_style.content_margin_bottom = 2
	key_box.add_theme_stylebox_override("panel", key_style)
	hbox.add_child(key_box)

	_prompt_key_lbl = Label.new()
	_prompt_key_lbl.text = "E"
	_prompt_key_lbl.add_theme_font_size_override("font_size", 16)
	_prompt_key_lbl.add_theme_color_override("font_color", Color(0.10, 0.05, 0.02))
	key_box.add_child(_prompt_key_lbl)

	_prompt_text_lbl = Label.new()
	_prompt_text_lbl.text = ""
	_prompt_text_lbl.add_theme_font_size_override("font_size", 17)
	_prompt_text_lbl.add_theme_color_override("font_color", Color(0.98, 0.93, 0.80))
	hbox.add_child(_prompt_text_lbl)
