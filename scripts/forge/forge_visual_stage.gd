# gdlint: disable=max-file-lines
class_name ForgeVisualStage
extends Control

# Sân khấu rèn 32-bit Hoả Tâm cho cả 3 giai đoạn:
# - MODE_HEAT: Bếp than đá + ống bễ 4 khung + phôi/vũ khí đổi màu nhiệt + khói & lửa
# - MODE_ANVIL: Đe sắt ấn hoa sen + búa rèn xoay trục + hitstop, shockwave, tia lửa nảy
# - MODE_QUENCH: Bể tôi luyện 2 lớp (chìm vũ khí thật sự) + cột hơi nước & ấn nguyên tố

enum Mode { MODE_HEAT, MODE_ANVIL, MODE_QUENCH }
enum _HammerState { IDLE, SWING_DOWN, HITSTOP, REBOUND }

const _TEX_HEARTH: Texture2D = preload(
	"res://assets/pixel/sprites/forge/forge_hearth_144x112.png"
)
const _TEX_BELLOWS: Texture2D = preload(
	"res://assets/pixel/sprites/forge/forge_bellows_sheet_96.png"
)
const _TEX_ANVIL: Texture2D = preload(
	"res://assets/pixel/sprites/forge/forge_anvil_128x112.png"
)
const _TEX_HAMMER: Texture2D = preload(
	"res://assets/pixel/sprites/forge/forge_hammer_96x96.png"
)
const _TEX_QUENCH_BACK: Texture2D = preload(
	"res://assets/pixel/sprites/forge/forge_quench_tub_144x112.png"
)
const _TEX_QUENCH_FRONT: Texture2D = preload(
	"res://assets/pixel/sprites/forge/forge_quench_tub_front_144x112.png"
)

const _BELLOWS_FRAME_SIZE := 96.0
const _BELLOWS_FPS := 10.0
const _HAMMER_PIVOT_PX := Vector2(78.0, 82.0)
const _HAMMER_REST_ANGLE := 0.16
const _HAMMER_MAX_WINDUP := 0.78
const _HAMMER_IMPACT_ANGLE := -0.62
const _HAMMER_MISS_ANGLE := -0.46
const _HITSTOP_PERFECT := 0.045

var mode: Mode = Mode.MODE_HEAT
var heat_percent: float = 0.0
var sweet_min: float = 0.60
var peak_frac: float = 0.80
var burn_frac: float = 0.92
var is_pumping: bool = false

var _weapon_tex: Texture2D = null
var _time: float = 0.0
var _flash_alpha: float = 0.0
var _flash_color: Color = Color(1.0, 0.92, 0.45)
var _shake_amp: float = 0.0
var _particles: Array[Dictionary] = []
var _shockwaves: Array[Dictionary] = []
var _ember_timer: float = 0.0
var _smoke_timer: float = 0.0

# Trạng thái ống bễ Phase 1
var _bellows_frame: int = 0
var _bellows_timer: float = 0.0

# Trạng thái rèn búa Phase 2
var _beat_progress: float = 0.0
var _beat_perfect_center: float = 0.55
var _strike_idx: int = 0
var _total_strikes: int = 5
var _combo_count: int = 0
var _hammer_state: _HammerState = _HammerState.IDLE
var _hammer_angle: float = _HAMMER_REST_ANGLE
var _hammer_start_angle: float = _HAMMER_REST_ANGLE
var _hammer_target_angle: float = _HAMMER_IMPACT_ANGLE
var _hammer_timer: float = 0.0
var _hitstop_timer: float = 0.0
var _impact_punch: float = 0.0
var _impact_punch_vel: float = 0.0
var _arc_alpha: float = 0.0
var _arc_color: Color = Color(1.0, 0.92, 0.55)
var _pending_hit_result: int = 0
var _anvil_floor_y: float = 120.0

# Trạng thái tôi luyện Phase 3
var _quench_active: bool = false
var _quench_elapsed: float = 0.0
var _quench_duration: float = 2.0
var _quench_color: Color = Color(0.28, 0.72, 1.0)
var _quench_splashed: bool = false
var _quench_steam_timer: float = 0.0
var quench_progress: float = 0.0
var quench_target_progress: float = 0.70
var is_perfect_quench: bool = false
var _perfect_star_alpha: float = 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_particles.clear()
	_shockwaves.clear()
	_flash_alpha = 0.0
	_shake_amp = 0.0
	_impact_punch = 0.0
	_impact_punch_vel = 0.0
	_arc_alpha = 0.0
	_hammer_state = _HammerState.IDLE
	_hammer_angle = _HAMMER_REST_ANGLE
	_hitstop_timer = 0.0
	_bellows_frame = 0
	_bellows_timer = 0.0
	_combo_count = 0
	_perfect_star_alpha = 0.0
	if new_mode != Mode.MODE_QUENCH:
		_quench_active = false
		quench_progress = 0.0
		is_perfect_quench = false
	queue_redraw()


func set_weapon_texture(tex: Texture2D) -> void:
	_weapon_tex = tex
	queue_redraw()


func set_heat_state(
	pct: float,
	p_sweet: float,
	p_peak: float,
	p_burn: float,
	pumping: bool
) -> void:
	heat_percent = clampf(pct, 0.0, 1.0)
	sweet_min = p_sweet
	peak_frac = p_peak
	burn_frac = p_burn
	is_pumping = pumping


func set_beat_state(
	progress: float,
	perfect_center: float,
	strike_idx: int,
	total_strikes: int
) -> void:
	_beat_progress = clampf(progress, 0.0, 1.0)
	_beat_perfect_center = clampf(perfect_center, 0.1, 0.9)
	_strike_idx = maxi(0, strike_idx)
	_total_strikes = maxi(1, total_strikes)


func set_combo_count(count: int) -> void:
	_combo_count = maxi(0, count)
	queue_redraw()


func trigger_strike(hit_result: int) -> void:
	# 0 = PERFECT, 1 = GOOD, 2 = MISS
	_pending_hit_result = hit_result
	_hammer_start_angle = _hammer_angle
	_hammer_target_angle = _HAMMER_MISS_ANGLE if hit_result == 2 else _HAMMER_IMPACT_ANGLE
	_hammer_state = _HammerState.SWING_DOWN
	_hammer_timer = 0.0
	_arc_alpha = 0.95 if hit_result == 0 else (0.68 if hit_result == 1 else 0.35)
	if _combo_count >= 2:
		_arc_color = Color(1.0, 0.92, 0.35)
	elif hit_result == 0:
		_arc_color = Color(1.0, 0.95, 0.52)
	elif hit_result == 1:
		_arc_color = Color(1.0, 0.64, 0.20)
	else:
		_arc_color = Color(0.65, 0.58, 0.56)
	queue_redraw()


func set_quench_progress(p: float, target_p: float = 0.70) -> void:
	quench_progress = clampf(p, 0.0, 1.0)
	quench_target_progress = clampf(target_p, 0.1, 0.9)
	queue_redraw()


func trigger_perfect_quench() -> void:
	is_perfect_quench = true
	_perfect_star_alpha = 1.0
	_shake_amp = 11.0
	_flash_color = Color(1.0, 0.96, 0.60)
	_flash_alpha = 1.0
	var water := _get_quench_water_center()
	# Sóng xung kích hào quang sao vàng kim + ánh sáng nguyên tố
	_shockwaves.append({
		"pos": water, "r": 16.0, "max_r": 200.0, "life": 0.65, "max_life": 0.65,
		"color": Color(1.0, 0.90, 0.35), "width": 4.5, "flat": 0.42,
	})
	_shockwaves.append({
		"pos": water, "r": 10.0, "max_r": 170.0, "life": 0.50, "max_life": 0.50,
		"color": _quench_color.lightened(0.55), "width": 3.5, "flat": 0.42,
	})
	# 36 tia sáng nguyên tố & vàng kim nổ bung từ tâm mặt nước
	for _i in range(36):
		var ang := randf_range(0.0, TAU)
		var spd := randf_range(160.0, 420.0)
		var is_gold := (_i % 2 == 0)
		var col := Color(1.0, 0.88, 0.25) if is_gold else _quench_color.lightened(randf_range(0.3, 0.7))
		_particles.append({
			"kind": "spark",
			"pos": water + Vector2(cos(ang), sin(ang) * 0.42) * randf_range(6.0, 24.0),
			"vel": Vector2(cos(ang) * spd, sin(ang) * spd * 0.65),
			"gravity": 120.0,
			"life": randf_range(0.45, 0.85),
			"max_life": 0.85,
			"size": randf_range(5.0, 8.0),
			"color": col,
			"core": Color(1.0, 1.0, 0.95),
			"bounce": false,
		})
	queue_redraw()


func start_quench_sequence(elem_color: Color, duration: float) -> void:
	mode = Mode.MODE_QUENCH
	_particles.clear()
	_shockwaves.clear()
	_quench_active = true
	_quench_elapsed = 0.0
	_quench_duration = maxf(0.4, duration)
	_quench_color = elem_color
	_quench_splashed = false
	_quench_steam_timer = 0.0
	quench_progress = 0.0
	is_perfect_quench = false
	_perfect_star_alpha = 0.0
	_flash_alpha = 0.0
	_shake_amp = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_flash_alpha = maxf(0.0, _flash_alpha - delta * 2.5)
	_shake_amp = maxf(0.0, _shake_amp - delta * 36.0)
	_arc_alpha = maxf(0.0, _arc_alpha - delta * 4.5)

	match mode:
		Mode.MODE_HEAT:
			_process_heat(delta)
		Mode.MODE_ANVIL:
			_process_anvil(delta)
		Mode.MODE_QUENCH:
			_process_quench(delta)

	_update_particles(delta)
	_update_shockwaves(delta)
	queue_redraw()


func _process_heat(delta: float) -> void:
	# Hoạt ảnh ống bễ 4 khung khi đang bơm gió
	if is_pumping:
		_bellows_timer += delta
		var frame_dur := 1.0 / _BELLOWS_FPS
		if _bellows_timer >= frame_dur:
			_bellows_timer -= frame_dur
			_bellows_frame = (_bellows_frame + 1) % 4
			if _bellows_frame == 2:
				_spawn_bellows_puff()
	else:
		_bellows_timer = 0.0
		_bellows_frame = 0

	# Tàn lửa bốc lên từ bếp than
	if heat_percent > 0.16 or is_pumping:
		_ember_timer += delta
		var interval := 0.032 if is_pumping else 0.095
		if _ember_timer >= interval:
			_ember_timer = 0.0
			_spawn_heat_ember()

	# Khói đen cuộn lên khi quá nhiệt
	if heat_percent >= burn_frac:
		_smoke_timer += delta
		if _smoke_timer >= 0.055:
			_smoke_timer = 0.0
			_spawn_burn_smoke()
	else:
		_smoke_timer = 0.0


func _process_anvil(delta: float) -> void:
	# Rung dọc tắt dần khi búa nện xuống đe
	if absf(_impact_punch) > 0.05 or absf(_impact_punch_vel) > 0.05:
		var spring_force := -260.0 * _impact_punch - 18.0 * _impact_punch_vel
		_impact_punch_vel += spring_force * delta
		_impact_punch += _impact_punch_vel * delta
	else:
		_impact_punch = 0.0
		_impact_punch_vel = 0.0

	match _hammer_state:
		_HammerState.IDLE:
			var windup_t := clampf(_beat_progress / maxf(0.12, _beat_perfect_center), 0.0, 1.0)
			var eased := 1.0 - pow(1.0 - windup_t, 2.0)
			var target := lerpf(_HAMMER_REST_ANGLE, _HAMMER_MAX_WINDUP, eased)
			if _beat_progress > _beat_perfect_center:
				target += sin(_time * 28.0) * 0.025
			_hammer_angle = lerpf(_hammer_angle, target, minf(1.0, delta * 14.0))
		_HammerState.SWING_DOWN:
			_hammer_timer += delta
			var dur := 0.055
			var t := clampf(_hammer_timer / dur, 0.0, 1.0)
			var ease_in := t * t * t
			_hammer_angle = lerpf(_hammer_start_angle, _hammer_target_angle, ease_in)
			if t >= 1.0:
				_on_hammer_impact(_pending_hit_result)
				if _pending_hit_result == 0:
					_hammer_state = _HammerState.HITSTOP
					_hitstop_timer = _HITSTOP_PERFECT
				else:
					_hammer_state = _HammerState.REBOUND
					_hammer_timer = 0.0
		_HammerState.HITSTOP:
			_hitstop_timer -= delta
			if _hitstop_timer <= 0.0:
				_hammer_state = _HammerState.REBOUND
				_hammer_timer = 0.0
		_HammerState.REBOUND:
			_hammer_timer += delta
			var dur := 0.24
			var t := clampf(_hammer_timer / dur, 0.0, 1.0)
			var ease_out := 1.0 - pow(1.0 - t, 3.0)
			_hammer_angle = lerpf(_hammer_target_angle, _HAMMER_REST_ANGLE, ease_out)
			if t >= 1.0:
				_hammer_state = _HammerState.IDLE


func _on_hammer_impact(hit_result: int) -> void:
	var impact := _get_anvil_impact_point(_strike_idx)
	var count := 12
	var tail_col := Color(1.0, 0.56, 0.14)
	if hit_result == 0:
		count = 28
		tail_col = Color(1.0, 0.78, 0.18)
		_flash_color = Color(1.0, 0.96, 0.56)
		_flash_alpha = 0.92
		_shake_amp = 9.5
		_impact_punch = 8.5
		_impact_punch_vel = 42.0
		_shockwaves.append({
			"pos": impact, "r": 12.0, "max_r": 136.0, "life": 0.34, "max_life": 0.34,
			"color": Color(1.0, 0.94, 0.45), "width": 3.5, "flat": 0.48,
		})
		_shockwaves.append({
			"pos": impact, "r": 6.0, "max_r": 88.0, "life": 0.24, "max_life": 0.24,
			"color": Color(1.0, 1.0, 0.88), "width": 2.5, "flat": 0.48,
		})
	elif hit_result == 1:
		count = 16
		tail_col = Color(0.98, 0.52, 0.12)
		_flash_color = Color(1.0, 0.72, 0.26)
		_flash_alpha = 0.52
		_shake_amp = 4.8
		_impact_punch = 5.0
		_impact_punch_vel = 24.0
		_shockwaves.append({
			"pos": impact, "r": 10.0, "max_r": 86.0, "life": 0.26, "max_life": 0.26,
			"color": Color(1.0, 0.66, 0.22), "width": 2.5, "flat": 0.48,
		})
	else:
		count = 10
		tail_col = Color(0.50, 0.44, 0.42)
		_flash_color = Color(0.80, 0.22, 0.18)
		_flash_alpha = 0.36
		_shake_amp = 3.2
		_impact_punch = 2.5
		_impact_punch_vel = 10.0

	# Búa Vàng khi combo >= 2: tia lửa vàng dày gấp đôi + sóng xung kích hào quang vàng rực
	var is_gold_combo := (_combo_count >= 2 and hit_result != 2)
	if is_gold_combo:
		count *= 2
		tail_col = Color(1.0, 0.88, 0.20)
		_flash_color = Color(1.0, 0.96, 0.48)
		_flash_alpha = minf(1.0, _flash_alpha + 0.18)
		_shockwaves.append({
			"pos": impact, "r": 8.0, "max_r": 160.0, "life": 0.40, "max_life": 0.40,
			"color": Color(1.0, 0.88, 0.18), "width": 4.0, "flat": 0.48,
		})

	for _i in range(count):
		var ang := randf_range(-PI * 0.95, -PI * 0.05)
		var spd := randf_range(140.0, 380.0) if hit_result != 2 else randf_range(50.0, 140.0)
		_particles.append({
			"kind": "spark" if hit_result != 2 else "smoke",
			"pos": impact + Vector2(randf_range(-28.0, 28.0), randf_range(-4.0, 4.0)),
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"gravity": 580.0 if hit_result != 2 else -35.0,
			"life": randf_range(0.30, 0.64),
			"max_life": 0.64,
			"size": (6.0 if is_gold_combo else 5.0) if hit_result == 0 else 4.0,
			"color": tail_col,
			"core": Color(1.0, 1.0, 0.92) if is_gold_combo else Color(1.0, 0.98, 0.85),
			"bounce": hit_result != 2,
		})


func _process_quench(delta: float) -> void:
	if not _quench_active:
		return
	_quench_elapsed = minf(_quench_elapsed + delta, _quench_duration)
	var t := _quench_elapsed / _quench_duration

	# Nếu quench_progress chưa gán từ ngoài thì đồng bộ theo thời gian
	if quench_progress <= 0.001 and t > 0.0:
		quench_progress = t

	if _perfect_star_alpha > 0.0:
		_perfect_star_alpha = maxf(0.0, _perfect_star_alpha - delta * 1.6)

	# Khoảnh khắc vũ khí chạm mặt nước linh lực (~28%)
	if t >= 0.28 and not _quench_splashed:
		_quench_splashed = true
		_trigger_quench_splash()

	# Luồng hơi nước & đốm linh lực tiếp tục bốc lên trong khi ngâm
	if t >= 0.28 and t <= 0.78:
		_quench_steam_timer += delta
		if _quench_steam_timer >= 0.045:
			_quench_steam_timer = 0.0
			_spawn_quench_steam_puff()


func _trigger_quench_splash() -> void:
	var water := _get_quench_water_center()
	_shake_amp = 6.5
	_flash_color = _quench_color.lightened(0.45)
	_flash_alpha = 0.65

	# Vòng sóng nước & ấn nguyên tố mở rộng
	_shockwaves.append({
		"pos": water, "r": 14.0, "max_r": 110.0, "life": 0.55, "max_life": 0.55,
		"color": _quench_color.lightened(0.4), "width": 3.0, "flat": 0.42,
	})
	_shockwaves.append({
		"pos": water, "r": 8.0, "max_r": 150.0, "life": 0.75, "max_life": 0.75,
		"color": Color(1.0, 1.0, 1.0, 0.85), "width": 2.0, "flat": 0.42,
	})

	# Giọt linh lực bắn tung tóe
	for _i in range(22):
		var ang := randf_range(-PI * 0.88, -PI * 0.12)
		var spd := randf_range(110.0, 270.0)
		_particles.append({
			"kind": "droplet",
			"pos": water + Vector2(randf_range(-34.0, 34.0), randf_range(-4.0, 4.0)),
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"gravity": 460.0,
			"life": randf_range(0.36, 0.70),
			"max_life": 0.70,
			"size": randf_range(4.0, 7.0),
			"color": _quench_color.lightened(randf_range(0.15, 0.55)),
			"core": Color(1.0, 1.0, 1.0),
			"bounce": false,
		})

	# Cột hơi nước pixel 32-bit bùng lên
	for _j in range(18):
		_spawn_quench_steam_puff()


func _spawn_quench_steam_puff() -> void:
	var water := _get_quench_water_center()
	var col := Color(0.94, 0.96, 1.0).lerp(_quench_color.lightened(0.5), 0.28)
	_particles.append({
		"kind": "steam",
		"pos": water + Vector2(randf_range(-40.0, 40.0), randf_range(-8.0, 6.0)),
		"vel": Vector2(randf_range(-28.0, 28.0), randf_range(-135.0, -72.0)),
		"gravity": -18.0,
		"life": randf_range(0.55, 0.95),
		"max_life": 0.95,
		"size": randf_range(10.0, 18.0),
		"color": col,
		"core": Color.WHITE,
		"bounce": false,
	})


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var shake := Vector2.ZERO
	if _shake_amp > 0.2:
		shake = Vector2(
			randf_range(-_shake_amp, _shake_amp),
			randf_range(-_shake_amp, _shake_amp)
		)
	elif mode == Mode.MODE_HEAT and heat_percent >= burn_frac:
		shake = Vector2(randf_range(-2.6, 2.6), randf_range(-1.8, 1.8))

	match mode:
		Mode.MODE_HEAT:
			_draw_heat_stage(shake)
		Mode.MODE_ANVIL:
			_draw_anvil_stage(shake)
		Mode.MODE_QUENCH:
			_draw_quench_stage(shake)

	_draw_shockwaves(shake)
	_draw_particles(shake)


# ══════════════════════════════════════════════════════════════════════════════
# MODE_HEAT — PHASE 1: BẾP THAN + ỐNG BỄ 4 KHUNG + PHÔI ĐỔI MÀU NHIỆT
# ══════════════════════════════════════════════════════════════════════════════

func _draw_heat_stage(shake: Vector2) -> void:
	var hearth_rect := _get_hearth_rect(shake)
	var s := hearth_rect.size.x / 144.0
	var coal_center := Vector2(
		hearth_rect.position.x + hearth_rect.size.x * 0.50,
		hearth_rect.position.y + hearth_rect.size.y * 0.36
	)

	# Quầng sáng ấm dưới chân lò than
	var pulse := 0.90 + sin(_time * 9.0) * 0.10
	var glow_a := clampf(0.14 + heat_percent * 0.34, 0.12, 0.48) * pulse
	_draw_ellipse_fill(
		Vector2(coal_center.x, hearth_rect.end.y - 6.0 * s),
		hearth_rect.size.x * 0.62,
		14.0 * s,
		Color(1.0, 0.42, 0.08, glow_a)
	)

	# Vẽ bếp than đá 32-bit
	draw_texture_rect(_TEX_HEARTH, hearth_rect, false)

	# Ngọn lửa lò đa tầng bùng cao theo nhiệt độ + lực bơm bễ
	_draw_hearth_flames(coal_center, s)

	# Vẽ ống bễ 4 khung bên trái chĩa vòi vào lò than
	var bellows_size := _BELLOWS_FRAME_SIZE * clampf(s * 0.92, 0.95, 1.75)
	var bellows_pos := Vector2(
		hearth_rect.position.x - bellows_size * 0.86,
		coal_center.y - bellows_size * 0.54
	)
	var src_rect := Rect2(
		Vector2(_bellows_frame * _BELLOWS_FRAME_SIZE, 0.0),
		Vector2(_BELLOWS_FRAME_SIZE, _BELLOWS_FRAME_SIZE)
	)
	draw_texture_rect_region(
		_TEX_BELLOWS,
		Rect2(bellows_pos, Vector2(bellows_size, bellows_size)),
		src_rect
	)

	# Càng kìm sắt kẹp phôi từ bên phải vào giữa bếp than
	var bob := sin(_time * 14.0) * (2.5 if is_pumping else 0.8)
	var billet_center := coal_center + Vector2(0.0, -10.0 * s + bob)
	_draw_tongs(billet_center, hearth_rect.end.x + 68.0 * s, s)

	# Quầng rung nhiệt khi vào vùng Cam / Đỏ Rực
	var billet_col := _billet_color(heat_percent)
	if heat_percent >= sweet_min and heat_percent < burn_frac:
		var peak_boost := 1.45 if heat_percent >= peak_frac else 1.0
		var aura_r := (36.0 + (heat_percent - sweet_min) * 72.0) * s * 0.65 * peak_boost
		draw_circle(
			billet_center,
			aura_r,
			Color(billet_col.r, billet_col.g, billet_col.b, 0.16 * pulse * peak_boost)
		)
		if heat_percent >= peak_frac:
			_draw_heat_shimmer(billet_center, s)

	# Phôi vũ khí thật (hoặc phôi thép 32-bit fallback) nằm trên than hồng
	_draw_heated_weapon_or_billet(billet_center, billet_col, s)


func _draw_hearth_flames(coal_center: Vector2, s: float) -> void:
	var intensity := clampf(heat_percent * 1.15 + (0.28 if is_pumping else 0.0), 0.15, 1.35)
	var cols: Array[Color] = [
		Color(0.95, 0.24, 0.04, 0.72),
		Color(1.00, 0.58, 0.10, 0.82),
		Color(1.00, 0.94, 0.56, 0.88),
	]
	for layer in range(3):
		var tongue_count := 7 - layer * 2
		var spread := (36.0 - layer * 9.0) * s
		var base_h := (18.0 + intensity * 30.0 - layer * 6.0) * s
		if heat_percent >= burn_frac and layer == 2:
			continue
		for i in range(tongue_count):
			var frac := 0.0 if tongue_count == 1 else (float(i) / float(tongue_count - 1) - 0.5)
			var phase := _time * (11.0 + layer * 3.5) + i * 1.7
			var flick := 0.78 + sin(phase) * 0.22
			var tx := coal_center.x + frac * spread * 2.0 + sin(phase * 0.7) * 3.0 * s
			var th := base_h * flick * (1.0 - absf(frac) * 0.55)
			var tw := (11.0 - layer * 2.5) * s
			var col: Color = cols[layer]
			if heat_percent >= burn_frac:
				col = col.darkened(0.45)
			draw_rect(
				Rect2(Vector2(tx - tw * 0.5, coal_center.y - th), Vector2(tw, th)),
				col
			)


func _draw_heat_shimmer(center: Vector2, s: float) -> void:
	for i in range(4):
		var wave_y := center.y - (14.0 + i * 10.0) * s
		var wave_x := center.x + sin(_time * 12.0 + i * 1.6) * 14.0 * s
		var w := (34.0 - i * 5.0) * s
		draw_rect(
			Rect2(Vector2(wave_x - w * 0.5, wave_y), Vector2(w, 2.5 * s)),
			Color(1.0, 0.96, 0.72, 0.22 - i * 0.04)
		)


func _draw_tongs(grip_pos: Vector2, handle_end_x: float, s: float) -> void:
	var pivot := grip_pos + Vector2(40.0 * s, 4.0 * s)
	var upper_tip := grip_pos + Vector2(18.0 * s, -6.0 * s)
	var lower_tip := grip_pos + Vector2(18.0 * s, 8.0 * s)
	var upper_end := Vector2(handle_end_x, pivot.y - 10.0 * s)
	var lower_end := Vector2(handle_end_x, pivot.y + 12.0 * s)

	var iron_dark := Color(0.12, 0.10, 0.12)
	var iron_mid := Color(0.28, 0.26, 0.30)
	var iron_hi := Color(0.48, 0.45, 0.52)

	draw_line(upper_tip, upper_end, iron_dark, 6.0 * s)
	draw_line(lower_tip, lower_end, iron_dark, 6.0 * s)
	draw_line(upper_tip, upper_end, iron_mid, 3.6 * s)
	draw_line(lower_tip, lower_end, iron_mid, 3.6 * s)
	draw_line(upper_tip + Vector2(0, -1), upper_end + Vector2(0, -1), iron_hi, 1.4 * s)
	draw_circle(pivot, 4.5 * s, iron_dark)
	draw_circle(pivot, 2.6 * s, iron_hi)


func _draw_heated_weapon_or_billet(center: Vector2, billet_col: Color, s: float) -> void:
	if _weapon_tex != null:
		var w_sz := clampf(68.0 * s, 72.0, 128.0)
		var tint := _weapon_heat_tint(heat_percent)
		draw_set_transform(center, -0.58, Vector2.ONE)
		# Viền phát sáng nhẹ quanh vũ khí khi nóng đỏ
		if heat_percent >= sweet_min and heat_percent < burn_frac:
			var glow := Color(billet_col.r, billet_col.g, billet_col.b, 0.35)
			draw_texture_rect(
				_weapon_tex,
				Rect2(Vector2(-w_sz * 0.54, -w_sz * 0.54), Vector2(w_sz * 1.08, w_sz * 1.08)),
				false,
				glow
			)
		draw_texture_rect(
			_weapon_tex,
			Rect2(Vector2(-w_sz * 0.5, -w_sz * 0.5), Vector2(w_sz, w_sz)),
			false,
			tint
		)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return

	# Fallback phôi thép 32-bit sắc nét
	_draw_pixel_billet(center, 86.0 * s, 16.0 * s, billet_col, 0.0)


# ══════════════════════════════════════════════════════════════════════════════
# MODE_ANVIL — PHASE 2: ĐE SẮT + PHÔI ĐỊNH HÌNH + BÚA RÈN XOAY TRỤC
# ══════════════════════════════════════════════════════════════════════════════

func _draw_anvil_stage(shake: Vector2) -> void:
	var punch_vec := Vector2(0.0, _impact_punch)
	var anvil_rect := _get_anvil_rect(shake + punch_vec)
	var s := anvil_rect.size.x / 128.0
	var anvil_center_top := Vector2(
		anvil_rect.position.x + anvil_rect.size.x * 0.54,
		anvil_rect.position.y + anvil_rect.size.y * 0.14
	)
	var impact := _get_strike_hotspot(anvil_rect, _strike_idx, s)
	_anvil_floor_y = impact.y + 4.0

	# Bóng đổ nền dưới gốc sồi đe sắt
	_draw_ellipse_fill(
		Vector2(anvil_rect.position.x + anvil_rect.size.x * 0.50, anvil_rect.end.y - 4.0 * s),
		anvil_rect.size.x * 0.48,
		11.0 * s,
		Color(0.03, 0.02, 0.02, 0.58)
	)

	# Vẽ đe sắt ấn hoa sen
	draw_texture_rect(_TEX_ANVIL, anvil_rect, false)

	# Phôi vũ khí nằm trên mặt phẳng đe, định hình & sáng dần theo strike_idx
	var shape_prog := clampf(float(_strike_idx) / float(maxi(1, _total_strikes)), 0.0, 1.0)
	var hot_col := Color(0.98, 0.56, 0.14).lerp(Color(1.0, 0.84, 0.44), shape_prog * 0.45)
	if _flash_alpha > 0.01:
		hot_col = hot_col.lerp(_flash_color, _flash_alpha)

	if _weapon_tex != null:
		var w_sz := clampf((60.0 + shape_prog * 14.0) * s, 68.0, 128.0)
		var tint := Color(1.0, 0.62, 0.22).lerp(Color(1.0, 0.92, 0.76), shape_prog * 0.65)
		if _flash_alpha > 0.01:
			tint = tint.lerp(_flash_color.lightened(0.35), _flash_alpha)
		draw_set_transform(anvil_center_top + Vector2(-4.0 * s, -10.0 * s), -0.78, Vector2.ONE)
		draw_texture_rect(
			_weapon_tex,
			Rect2(Vector2(-w_sz * 0.5, -w_sz * 0.5), Vector2(w_sz, w_sz)),
			false,
			tint
		)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var bw := (72.0 + shape_prog * 22.0) * s
		var bh := (15.0 - shape_prog * 3.0) * s
		_draw_pixel_billet(anvil_center_top + Vector2(-4.0 * s, -bh * 0.45), bw, bh, hot_col, shape_prog)

	# Vết búa các nhát trước đó
	_draw_past_strikes(anvil_rect, s)

	# Điểm Nóng (hotspot) của nhát hiện tại
	_draw_strike_hotspot(impact, s)

	# Quầng lóe khi búa chạm đe
	if _flash_alpha > 0.02:
		draw_circle(
			impact,
			(46.0 + (1.0 - _flash_alpha) * 28.0) * s * 0.85,
			Color(_flash_color.r, _flash_color.g, _flash_color.b, _flash_alpha * 0.42)
		)

	# Vệt cung chuyển động (motion arc) khi giáng búa
	var h_scale := clampf(s * 0.96, 0.95, 1.85)
	var pivot := impact + Vector2(72.0 * h_scale, 8.0 * h_scale)
	if _arc_alpha > 0.02:
		var arc_col := Color(1.0, 0.92, 0.35) if _combo_count >= 2 else _arc_color
		_draw_hammer_motion_arc(pivot, 72.0 * h_scale, arc_col)

	# Vẽ búa rèn xoay quanh trục cán phía trên-phải
	draw_set_transform(pivot, _hammer_angle, Vector2(h_scale, h_scale))
	if _combo_count >= 2:
		_draw_golden_hammer_aura()
	draw_texture_rect(
		_TEX_HAMMER,
		Rect2(-_HAMMER_PIVOT_PX, Vector2(96.0, 96.0)),
		false
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_golden_hammer_aura() -> void:
	var head_pos := Vector2(-60.0, -64.0)
	var pulse := 0.85 + sin(_time * 12.0) * 0.15
	draw_circle(head_pos, 26.0 * pulse, Color(1.0, 0.82, 0.15, 0.24 * pulse))
	draw_circle(head_pos, 16.0 * pulse, Color(1.0, 0.92, 0.35, 0.40 * pulse))
	draw_circle(head_pos, 7.0 * pulse, Color(1.0, 0.98, 0.70, 0.65))

	var ray_len := 22.0 * pulse
	var ray_col := Color(1.0, 0.95, 0.55, 0.75 * pulse)
	draw_line(head_pos + Vector2(-ray_len, 0), head_pos + Vector2(ray_len, 0), ray_col, 2.0)
	draw_line(head_pos + Vector2(0, -ray_len), head_pos + Vector2(0, ray_len), ray_col, 2.0)


func _draw_strike_hotspot(pos: Vector2, s: float) -> void:
	var pulse := 0.85 + sin(_time * 10.0) * 0.15
	var r := 9.0 * s * pulse
	draw_circle(pos, r * 1.8, Color(1.0, 0.75, 0.18, 0.24 * pulse))
	draw_arc(pos, r, 0.0, TAU, 18, Color(1.0, 0.92, 0.40, 0.85 * pulse), 2.0)
	draw_circle(pos, 3.0 * s, Color(1.0, 0.98, 0.80, 0.95))
	var d := (r + 3.0 * s)
	var tick_col := Color(1.0, 0.88, 0.30, 0.75 * pulse)
	draw_line(pos + Vector2(-d, 0), pos + Vector2(-d + 3.0 * s, 0), tick_col, 1.5)
	draw_line(pos + Vector2(d, 0), pos + Vector2(d - 3.0 * s, 0), tick_col, 1.5)
	draw_line(pos + Vector2(0, -d), pos + Vector2(0, -d + 3.0 * s), tick_col, 1.5)
	draw_line(pos + Vector2(0, d), pos + Vector2(0, d - 3.0 * s), tick_col, 1.5)


func _draw_past_strikes(anvil_rect: Rect2, s: float) -> void:
	for i in range(_strike_idx):
		var p := _get_strike_hotspot(anvil_rect, i, s)
		draw_circle(p, 4.0 * s, Color(0.12, 0.08, 0.06, 0.65))
		draw_circle(p, 2.4 * s, Color(0.95, 0.48, 0.14, 0.55))


func _draw_hammer_motion_arc(pivot: Vector2, radius: float, custom_col: Color = Color.TRANSPARENT) -> void:
	var use_col := _arc_color if custom_col.a <= 0.001 else custom_col
	# Cung quét từ góc giơ cao xuống điểm đập trên mặt đe
	var start_rad := -2.35 + _HAMMER_MAX_WINDUP * 0.72
	var end_rad := -2.35 + _HAMMER_IMPACT_ANGLE
	var steps := 10
	for k in range(3):
		var r_off := radius * (0.86 + k * 0.08)
		var width := (10.0 - k * 2.6)
		if _combo_count >= 2:
			width += 2.0
		var alpha := _arc_alpha * (0.42 - k * 0.11)
		var pts := PackedVector2Array()
		for i in range(steps + 1):
			var frac := float(i) / float(steps)
			var ang := lerpf(start_rad, end_rad, frac)
			pts.append(pivot + Vector2(cos(ang), sin(ang)) * r_off)
		draw_polyline(
			pts,
			Color(use_col.r, use_col.g, use_col.b, alpha),
			width
		)


# ══════════════════════════════════════════════════════════════════════════════
# MODE_QUENCH — PHASE 3: BỂ TÔI 2 LỚP + VŨ KHÍ CHÌM THẬT + ẤN NGUYÊN TỐ
# ══════════════════════════════════════════════════════════════════════════════

func _draw_quench_stage(shake: Vector2) -> void:
	var tub_rect := _get_quench_tub_rect(shake)
	var s := tub_rect.size.x / 144.0
	var water_center := Vector2(
		tub_rect.position.x + tub_rect.size.x * 0.50,
		tub_rect.position.y + tub_rect.size.y * 0.36
	)
	var t := 0.0
	if _quench_active:
		t = clampf(_quench_elapsed / _quench_duration, 0.0, 1.0)

	# Lớp 1: Hào quang nguyên tố phía sau bể
	if t > 0.25:
		var aura_str := sin(clampf((t - 0.25) / 0.75, 0.0, 1.0) * PI)
		draw_circle(
			water_center + Vector2(0.0, -24.0 * s),
			(64.0 + aura_str * 42.0) * s,
			Color(_quench_color.r, _quench_color.g, _quench_color.b, 0.22 * aura_str)
		)

	# Lớp 2: Thân sau bể tôi gỗ đai sắt
	draw_texture_rect(_TEX_QUENCH_BACK, tub_rect, false)

	# Lớp 3: Mặt nước linh lực đổi màu động + gợn sóng
	var rx := tub_rect.size.x * 0.34
	var ry := tub_rect.size.y * 0.16
	var water_col := Color(_quench_color.r, _quench_color.g, _quench_color.b, 0.58)
	_draw_ellipse_fill(water_center, rx, ry, water_col)
	var wave_r := fmod(_time * 0.85, 1.0)
	_draw_ellipse_outline(
		water_center,
		rx * (0.35 + wave_r * 0.58),
		ry * (0.35 + wave_r * 0.58),
		Color(1.0, 1.0, 1.0, (1.0 - wave_r) * 0.45),
		2.0
	)

	# Vòng Cổ Ngữ Nguyên Tố thu nhỏ dần vào vòng tròn tâm trên mặt bể
	_draw_converging_runes(water_center, s)

	# Lớp 4: Vũ khí hạ thẳng xuống trong lòng bể (0..28%), ngâm (28..70%), nâng vọt lên (70..95%)
	var weapon_y := _compute_quench_weapon_y(t, water_center.y, s)
	var weapon_tint := _compute_quench_weapon_tint(t)
	var weapon_pos := Vector2(water_center.x, weapon_y)
	_draw_quench_weapon(weapon_pos, weapon_tint, t, s)

	# Lớp 5: Mép trước thành bể đè LÊN TRÊN vũ khí để vũ khí chìm thật sự vào trong thùng
	draw_texture_rect(_TEX_QUENCH_FRONT, tub_rect, false)

	# Lớp 6: Vòng ấn nguyên tố xoay mở rộng khi chạm nước
	if t >= 0.28:
		var seal_t := clampf((t - 0.28) / 0.65, 0.0, 1.0)
		_draw_elemental_seal(water_center, seal_t, s)

	# Lớp 7: Hào quang sao vàng kim + nổ tia sáng khi TÔI HOÀN HẢO
	if _perfect_star_alpha > 0.01:
		_draw_perfect_quench_star(water_center, s)


func _draw_converging_runes(water_center: Vector2, s: float) -> void:
	var target_r := 28.0 * s
	var start_r := 120.0 * s
	var prog := quench_progress
	var target_p := quench_target_progress
	var shrink_frac := clampf(prog / maxf(0.01, target_p), 0.0, 1.0)
	var cur_r := lerpf(start_r, target_r, shrink_frac)
	if prog > target_p:
		cur_r = maxf(6.0 * s, target_r * (1.0 - (prog - target_p) / maxf(0.01, 1.0 - target_p)))

	var is_in_zone := absf(prog - target_p) <= 0.08
	var ring_col := Color(1.0, 0.92, 0.35) if is_in_zone else _quench_color.lightened(0.35)
	var alpha := clampf(1.0 - pow(absf(prog - target_p) * 1.5, 2.0), 0.35, 1.0)
	ring_col.a = alpha

	# Vòng tròn tâm mục tiêu trên mặt bể
	var target_col := Color(1.0, 0.88, 0.30, 0.65 + sin(_time * 8.0) * 0.25)
	if is_in_zone:
		target_col = Color(1.0, 0.98, 0.60, 0.95)
	_draw_ellipse_outline(water_center, target_r, target_r * 0.42, target_col, 2.4 if is_in_zone else 1.6)
	_draw_ellipse_outline(water_center, target_r * 0.68, target_r * 0.68 * 0.42, target_col * 0.7, 1.2)

	# Vòng cổ ngữ đang thu nhỏ
	_draw_ellipse_outline(water_center, cur_r, cur_r * 0.42, ring_col, 2.5 if is_in_zone else 1.8)

	# 6 Cổ Ngữ Nguyên Tố phân bố đều quanh vòng
	var num_runes := 6
	var rot := _time * 1.6
	for i in range(num_runes):
		var a := rot + float(i) * TAU / float(num_runes)
		var rune_pos := water_center + Vector2(cos(a) * cur_r, sin(a) * cur_r * 0.42)
		_draw_ancient_glyph(rune_pos, i, ring_col, s, is_in_zone)


func _draw_ancient_glyph(pos: Vector2, _idx: int, col: Color, s: float, is_in_zone: bool) -> void:
	var sz := (6.0 if is_in_zone else 4.5) * s
	draw_circle(pos, sz * 0.55, col)
	var pts := PackedVector2Array([
		pos + Vector2(0, -sz),
		pos + Vector2(sz * 0.8, 0),
		pos + Vector2(0, sz),
		pos + Vector2(-sz * 0.8, 0),
	])
	draw_colored_polygon(pts, Color(col.r, col.g, col.b, col.a * 0.35))
	draw_polyline(PackedVector2Array([
		pos + Vector2(0, -sz),
		pos + Vector2(sz * 0.8, 0),
		pos + Vector2(0, sz),
		pos + Vector2(-sz * 0.8, 0),
		pos + Vector2(0, -sz),
	]), col, 1.4)


func _draw_perfect_quench_star(center: Vector2, s: float) -> void:
	var a := _perfect_star_alpha
	var star_col := Color(1.0, 0.94, 0.55, a)
	var ray_h := 160.0 * s * a
	var ray_v := ray_h * 0.42
	# 4 tia chính hình chữ thập
	draw_line(center + Vector2(-ray_h, 0), center + Vector2(ray_h, 0), star_col, 3.5 * a)
	draw_line(center + Vector2(0, -ray_v * 2.2), center + Vector2(0, ray_v * 2.2), star_col, 3.5 * a)
	# 4 tia chéo
	var diag := ray_h * 0.65
	draw_line(center + Vector2(-diag, -diag * 0.42), center + Vector2(diag, diag * 0.42), star_col, 2.0 * a)
	draw_line(center + Vector2(diag, -diag * 0.42), center + Vector2(-diag, diag * 0.42), star_col, 2.0 * a)
	# Tâm sao sáng rực
	draw_circle(center, 22.0 * s * a, Color(1.0, 1.0, 0.92, a * 0.9))
	draw_circle(center, 42.0 * s * a, Color(1.0, 0.88, 0.25, a * 0.45))
	var weapon_tint := _compute_quench_weapon_tint(t)
	var weapon_pos := Vector2(water_center.x, weapon_y)
	_draw_quench_weapon(weapon_pos, weapon_tint, t, s)

	# Lớp 5: Mép trước thành bể đè LÊN TRÊN vũ khí để vũ khí chìm thật sự vào trong thùng
	draw_texture_rect(_TEX_QUENCH_FRONT, tub_rect, false)

	# Lớp 6: Vòng ấn nguyên tố xoay mở rộng khi chạm nước
	if t >= 0.28:
		var seal_t := clampf((t - 0.28) / 0.65, 0.0, 1.0)
		_draw_elemental_seal(water_center, seal_t, s)


func _compute_quench_weapon_y(t: float, water_y: float, s: float) -> float:
	var start_y := water_y - 78.0 * s
	var submerged_y := water_y + 18.0 * s
	var rise_y := water_y - 68.0 * s
	if t < 0.28:
		var p := clampf(t / 0.28, 0.0, 1.0)
		return lerpf(start_y, submerged_y, p * p)
	if t < 0.70:
		var shiver := sin(_time * 26.0) * 1.8 * s
		return submerged_y + shiver
	if t < 0.95:
		var p := clampf((t - 0.70) / 0.25, 0.0, 1.0)
		# Ease-out back để vũ khí vọt lên đầy khí thế
		var c1 := 1.70158
		var c3 := c1 + 1.0
		var back := 1.0 + c3 * pow(p - 1.0, 3.0) + c1 * pow(p - 1.0, 2.0)
		return lerpf(submerged_y, rise_y, back)
	return rise_y + sin(_time * 5.0) * 2.5 * s


func _compute_quench_weapon_tint(t: float) -> Color:
	var hot := Color(1.0, 0.44, 0.12)
	var elem_glow := _quench_color.lightened(0.38)
	if t < 0.28:
		return hot
	if t < 0.56:
		return hot.lerp(elem_glow, (t - 0.28) / 0.28)
	if t < 0.85:
		return elem_glow.lerp(Color.WHITE, (t - 0.56) / 0.29)
	return Color.WHITE


func _draw_quench_weapon(pos: Vector2, tint: Color, t: float, s: float) -> void:
	# Viền hào quang nguyên tố sau khi tôi xong
	if t >= 0.62:
		var rim_a := clampf((t - 0.62) / 0.25, 0.0, 1.0) * (0.40 + sin(_time * 8.0) * 0.12)
		draw_circle(pos, 46.0 * s, Color(_quench_color.r, _quench_color.g, _quench_color.b, rim_a))

	if _weapon_tex != null:
		var w_sz := clampf(86.0 * s, 96.0, 176.0)
		if t >= 0.62:
			var rim_col := Color(_quench_color.r, _quench_color.g, _quench_color.b, 0.55)
			draw_texture_rect(
				_weapon_tex,
				Rect2(pos - Vector2(w_sz * 0.54, w_sz * 0.54), Vector2(w_sz * 1.08, w_sz * 1.08)),
				false,
				rim_col
			)
		draw_texture_rect(
			_weapon_tex,
			Rect2(pos - Vector2(w_sz * 0.5, w_sz * 0.5), Vector2(w_sz, w_sz)),
			false,
			tint
		)
		return

	# Fallback lưỡi kiếm 32-bit dựng đứng
	var bw := 18.0 * s
	var bh := 78.0 * s
	var base := Color(0.84, 0.88, 0.94) * tint
	draw_rect(
		Rect2(pos - Vector2(bw * 0.5 + 3.0, bh * 0.5 + 3.0), Vector2(bw + 6.0, bh + 6.0)),
		Color(0.08, 0.05, 0.06)
	)
	draw_rect(Rect2(pos - Vector2(bw * 0.5, bh * 0.5), Vector2(bw, bh)), base)
	draw_rect(
		Rect2(pos - Vector2(bw * 0.25, bh * 0.45), Vector2(bw * 0.4, bh * 0.85)),
		base.lightened(0.35)
	)
	# Chuôi kiếm
	draw_rect(
		Rect2(pos + Vector2(-bw * 0.95, bh * 0.30), Vector2(bw * 1.9, 7.0 * s)),
		Color(0.76, 0.58, 0.22)
	)


func _draw_elemental_seal(center: Vector2, seal_t: float, s: float) -> void:
	var alpha := sin(seal_t * PI) * 0.78
	if alpha <= 0.02:
		return
	var r := (26.0 + seal_t * 58.0) * s
	var col := Color(_quench_color.r, _quench_color.g, _quench_color.b, alpha)
	var hi := Color(1.0, 1.0, 1.0, alpha * 0.75)

	_draw_ellipse_outline(center, r, r * 0.42, col, 2.5)
	_draw_ellipse_outline(center, r * 0.72, r * 0.30, hi, 1.5)

	# 8 tia ấn xoay quanh tâm bể
	var rot := _time * 2.2
	for i in range(8):
		var a := rot + float(i) * TAU / 8.0
		var p0 := center + Vector2(cos(a) * r * 0.65, sin(a) * r * 0.65 * 0.42)
		var p1 := center + Vector2(cos(a) * r * 1.05, sin(a) * r * 1.05 * 0.42)
		draw_line(p0, p1, hi, 2.0)


# ══════════════════════════════════════════════════════════════════════════════
# HELPERS — TỌA ĐỘ, HẠT & HÌNH HỌC
# ══════════════════════════════════════════════════════════════════════════════

func _get_hearth_rect(shake: Vector2) -> Rect2:
	var s := clampf(size.y / 118.0, 1.15, 2.0)
	var w := 144.0 * s
	var h := 112.0 * s
	var x := size.x * 0.52 - w * 0.5 + shake.x
	var y := size.y * 0.96 - h + shake.y
	return Rect2(Vector2(x, y), Vector2(w, h))


func _get_anvil_rect(offset: Vector2) -> Rect2:
	var s := clampf(size.y / 122.0, 1.12, 1.95)
	var w := 128.0 * s
	var h := 112.0 * s
	var x := size.x * 0.47 - w * 0.5 + offset.x
	var y := size.y * 0.97 - h + offset.y
	return Rect2(Vector2(x, y), Vector2(w, h))


func _get_strike_hotspot(anvil_rect: Rect2, strike_idx: int, s: float) -> Vector2:
	var total := maxi(1, _total_strikes)
	var frac := float(clampi(strike_idx, 0, total - 1)) / float(maxi(1, total - 1))
	# 5 điểm nóng phân bố đều dọc theo lưỡi vũ khí trên mặt đe
	var x_start := anvil_rect.position.x + anvil_rect.size.x * 0.40
	var x_end := anvil_rect.position.x + anvil_rect.size.x * 0.66
	var x := lerpf(x_start, x_end, frac)
	var y := anvil_rect.position.y + anvil_rect.size.y * 0.14
	return Vector2(x, y)


func _get_anvil_impact_point(strike_idx: int = -1) -> Vector2:
	var r := _get_anvil_rect(Vector2.ZERO)
	var s := r.size.x / 128.0
	var idx := _strike_idx if strike_idx < 0 else strike_idx
	return _get_strike_hotspot(r, idx, s)


func _get_quench_tub_rect(shake: Vector2) -> Rect2:
	var s := clampf(size.y / 154.0, 1.25, 2.05)
	var w := 144.0 * s
	var h := 112.0 * s
	var x := size.x * 0.50 - w * 0.5 + shake.x
	var y := size.y * 0.97 - h + shake.y
	return Rect2(Vector2(x, y), Vector2(w, h))


func _get_quench_water_center() -> Vector2:
	var r := _get_quench_tub_rect(Vector2.ZERO)
	return Vector2(r.position.x + r.size.x * 0.50, r.position.y + r.size.y * 0.36)


func _draw_pixel_billet(
	center: Vector2,
	bw: float,
	bh: float,
	col: Color,
	shape_prog: float
) -> void:
	var bpos := Vector2(center.x - bw * 0.5, center.y - bh * 0.5)
	draw_rect(
		Rect2(bpos - Vector2(3.0, 3.0), Vector2(bw + 6.0, bh + 6.0)),
		Color(0.08, 0.05, 0.06)
	)
	draw_rect(Rect2(bpos, Vector2(bw, bh)), col)
	# Vệt sáng cạnh trên
	draw_rect(
		Rect2(bpos + Vector2(5.0, 3.0), Vector2(bw - 10.0, maxf(3.0, bh * 0.28))),
		col.lightened(0.36)
	)
	# Rãnh sống lưỡi hiện rõ dần khi rèn búa
	if shape_prog > 0.15:
		draw_rect(
			Rect2(bpos + Vector2(10.0, bh * 0.52), Vector2(bw - 20.0, maxf(2.0, bh * 0.14))),
			col.darkened(0.28)
		)


func _billet_color(pct: float) -> Color:
	if pct >= burn_frac:
		return Color(0.24, 0.16, 0.14)
	if pct >= peak_frac:
		var t := clampf((pct - peak_frac) / maxf(0.01, burn_frac - peak_frac), 0.0, 1.0)
		return Color(1.0, 0.46, 0.08).lerp(Color(1.0, 0.94, 0.62), t)
	if pct >= sweet_min:
		var t := clampf((pct - sweet_min) / maxf(0.01, peak_frac - sweet_min), 0.0, 1.0)
		return Color(0.86, 0.34, 0.08).lerp(Color(1.0, 0.54, 0.12), t)
	var t := clampf(pct / maxf(0.01, sweet_min), 0.0, 1.0)
	return Color(0.46, 0.50, 0.58).lerp(Color(0.86, 0.34, 0.08), t)


func _weapon_heat_tint(pct: float) -> Color:
	if pct >= burn_frac:
		return Color(0.30, 0.22, 0.20)
	if pct >= peak_frac:
		var t := clampf((pct - peak_frac) / maxf(0.01, burn_frac - peak_frac), 0.0, 1.0)
		return Color(1.0, 0.66, 0.28).lerp(Color(1.0, 0.98, 0.78), t)
	if pct >= sweet_min:
		var t := clampf((pct - sweet_min) / maxf(0.01, peak_frac - sweet_min), 0.0, 1.0)
		return Color(0.95, 0.54, 0.22).lerp(Color(1.0, 0.66, 0.28), t)
	var t := clampf(pct / maxf(0.01, sweet_min), 0.0, 1.0)
	return Color(0.72, 0.76, 0.84).lerp(Color(0.95, 0.54, 0.22), t)


func _spawn_bellows_puff() -> void:
	var hearth := _get_hearth_rect(Vector2.ZERO)
	var nozzle := Vector2(hearth.position.x + 8.0, hearth.position.y + hearth.size.y * 0.38)
	for _i in range(6):
		_particles.append({
			"kind": "wind",
			"pos": nozzle + Vector2(randf_range(-4.0, 8.0), randf_range(-6.0, 6.0)),
			"vel": Vector2(randf_range(160.0, 260.0), randf_range(-38.0, 18.0)),
			"gravity": -16.0,
			"life": randf_range(0.18, 0.32),
			"max_life": 0.32,
			"size": randf_range(4.0, 6.0),
			"color": Color(1.0, 0.90, 0.68, 0.75),
			"core": Color.WHITE,
			"bounce": false,
		})


func _spawn_heat_ember() -> void:
	var hearth := _get_hearth_rect(Vector2.ZERO)
	var coal := Vector2(
		hearth.position.x + hearth.size.x * 0.50,
		hearth.position.y + hearth.size.y * 0.34
	)
	var is_burnt := heat_percent >= burn_frac
	var col := Color(0.42, 0.38, 0.36) if is_burnt else Color(1.0, randf_range(0.45, 0.92), 0.14)
	_particles.append({
		"kind": "ember",
		"pos": coal + Vector2(randf_range(-42.0, 42.0), randf_range(-6.0, 10.0)),
		"vel": Vector2(
			randf_range(-20.0, 42.0) if is_pumping else randf_range(-22.0, 22.0),
			randf_range(-135.0, -68.0) if is_pumping else randf_range(-92.0, -48.0)
		),
		"gravity": -14.0,
		"life": randf_range(0.42, 0.82),
		"max_life": 0.82,
		"size": 5.0 if is_burnt else 4.0,
		"color": col,
		"core": Color(1.0, 0.98, 0.78),
		"bounce": false,
	})


func _spawn_burn_smoke() -> void:
	var hearth := _get_hearth_rect(Vector2.ZERO)
	var coal := Vector2(
		hearth.position.x + hearth.size.x * 0.50,
		hearth.position.y + hearth.size.y * 0.30
	)
	_particles.append({
		"kind": "smoke",
		"pos": coal + Vector2(randf_range(-34.0, 34.0), randf_range(-8.0, 4.0)),
		"vel": Vector2(randf_range(-24.0, 24.0), randf_range(-95.0, -52.0)),
		"gravity": -10.0,
		"life": randf_range(0.55, 0.95),
		"max_life": 0.95,
		"size": randf_range(10.0, 16.0),
		"color": Color(0.18, 0.15, 0.15, 0.82),
		"core": Color(0.28, 0.24, 0.24),
		"bounce": false,
	})


func _update_particles(delta: float) -> void:
	var i := _particles.size() - 1
	while i >= 0:
		var p: Dictionary = _particles[i]
		p["life"] = float(p["life"]) - delta
		if float(p["life"]) <= 0.0:
			_particles.remove_at(i)
		else:
			var vel: Vector2 = p["vel"]
			vel.y += float(p["gravity"]) * delta
			var pos: Vector2 = (p["pos"] as Vector2) + vel * delta
			if bool(p.get("bounce", false)) and pos.y >= _anvil_floor_y and vel.y > 0.0:
				pos.y = _anvil_floor_y
				vel.y *= -0.46
				vel.x *= 0.78
			p["vel"] = vel
			p["pos"] = pos
			_particles[i] = p
		i -= 1


func _update_shockwaves(delta: float) -> void:
	var i := _shockwaves.size() - 1
	while i >= 0:
		var sw: Dictionary = _shockwaves[i]
		sw["life"] = float(sw["life"]) - delta
		if float(sw["life"]) <= 0.0:
			_shockwaves.remove_at(i)
		else:
			var prog := 1.0 - float(sw["life"]) / float(sw["max_life"])
			sw["r"] = lerpf(10.0, float(sw["max_r"]), 1.0 - pow(1.0 - prog, 2.0))
			_shockwaves[i] = sw
		i -= 1


func _draw_shockwaves(shake: Vector2) -> void:
	for sw: Dictionary in _shockwaves:
		var alpha := clampf(float(sw["life"]) / float(sw["max_life"]), 0.0, 1.0)
		var col: Color = sw["color"]
		col.a *= alpha
		var r: float = sw["r"]
		var flat: float = sw.get("flat", 0.5)
		_draw_ellipse_outline(
			(sw["pos"] as Vector2) + shake,
			r,
			r * flat,
			col,
			float(sw["width"]) * alpha
		)


func _draw_particles(shake: Vector2) -> void:
	for p: Dictionary in _particles:
		var ratio := clampf(float(p["life"]) / float(p["max_life"]), 0.0, 1.0)
		var pos: Vector2 = (p["pos"] as Vector2) + shake
		var vel: Vector2 = p["vel"]
		var sz: float = p["size"]
		var col: Color = p["color"]
		var kind: String = p.get("kind", "ember")

		if kind == "spark":
			# Tia lửa 2 lớp: đuôi cam kéo dài + lõi trắng sáng
			var tail := pos - vel.normalized() * clampf(vel.length() * 0.045, 5.0, 18.0)
			draw_line(tail, pos, Color(col.r, col.g, col.b, ratio), maxf(2.0, sz * 0.65))
			var core: Color = p.get("core", Color.WHITE)
			core.a = ratio
			draw_rect(Rect2(pos - Vector2(sz * 0.4, sz * 0.4), Vector2(sz * 0.8, sz * 0.8)), core)
		elif kind == "steam" or kind == "smoke":
			var cur_sz := sz * (1.45 - ratio * 0.45)
			col.a *= ratio * 0.78
			draw_rect(
				Rect2(pos - Vector2(cur_sz * 0.5, cur_sz * 0.5), Vector2(cur_sz, cur_sz)),
				col
			)
		elif kind == "wind":
			col.a *= ratio
			draw_rect(Rect2(pos, Vector2(sz * 2.4, sz * 0.55)), col)
		else:
			col.a *= ratio
			draw_rect(Rect2(pos - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)), col)


func _draw_ellipse_fill(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var segs := 20
	for i in range(segs):
		var a := float(i) * TAU / float(segs)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)


func _draw_ellipse_outline(
	center: Vector2,
	rx: float,
	ry: float,
	col: Color,
	width: float
) -> void:
	var pts := PackedVector2Array()
	var segs := 24
	for i in range(segs + 1):
		var a := float(i) * TAU / float(segs)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, col, maxf(1.0, width))
