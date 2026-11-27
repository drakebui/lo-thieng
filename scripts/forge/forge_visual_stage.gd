# gdlint: disable=max-file-lines
class_name ForgeVisualStage
extends Control

# Sân khấu rèn 32-bit Hoả Tâm toàn màn hình (Option B — 3 cảnh cận POV Straight-on 3/4):
# - MODE_HEAT:   Nền lò than liền khối + bễ co bóp cục bộ + mạch hoa sen hắt sáng + phôi đổi màu nhiệt
# - MODE_ANVIL:  Nền mặt đe liền khối + phôi biến hình 5 bước + ấn hoa sen chớp sáng + búa hitstop
# - MODE_QUENCH: Nền bể tôi thùng gỗ + nước nhuộm linh lực + vũ khí chìm cắt mặt nước + quét sáng

signal quench_water_impact(is_perfect: bool)
signal quench_sequence_finished

enum Mode { MODE_HEAT, MODE_ANVIL, MODE_QUENCH }
enum _HammerState { IDLE, SWING_DOWN, HITSTOP, REBOUND }
enum _QuenchState { IDLE, AIMING, PLUNGING, HITSTOP, SOAKING, LIFTING, HOLD }

const _QUENCH_WEAPON_SHADER_CODE := """shader_type canvas_item;
uniform float water_line_y = 360.0;
uniform float submerge_depth = 90.0;
uniform float hot_amount = 1.0;
uniform float cool_front_y = 600.0;
uniform vec4 elem_color : source_color = vec4(0.35, 0.78, 1.0, 1.0);
uniform float elem_infuse = 0.0;
uniform float gleam_progress = -1.0;
uniform vec4 gleam_color : source_color = vec4(1.0, 0.96, 0.72, 1.0);

varying vec2 v_canvas_pos;

void vertex() {
	v_canvas_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.1) {
		discard;
	}
	vec3 col = tex.rgb;
	float lum = dot(col, vec3(0.299, 0.587, 0.114));

	// 1. Nhiệt nung đỏ cam rút dần từ mũi nhúng lên chuôi theo cool_front_y
	float local_hot = hot_amount * smoothstep(cool_front_y + 18.0, cool_front_y - 24.0, v_canvas_pos.y);
	vec3 ember = mix(vec3(0.66, 0.15, 0.06), vec3(1.0, 0.46, 0.10), clamp(lum * 1.35, 0.0, 1.0));
	ember = mix(ember, vec3(1.0, 0.90, 0.50), smoothstep(0.56, 0.92, lum));
	col = mix(col, ember, local_hot * 0.88);

	// 2. Ánh linh lực phủ nhẹ dọc mép thép sau khi tôi
	if (elem_infuse > 0.01) {
		float rim = smoothstep(0.42, 0.95, lum);
		col = mix(col, mix(col, elem_color.rgb * 1.25, 0.44), elem_infuse * (0.24 + rim * 0.42));
	}

	// 3. Vệt sáng tôi thép quét chéo bám chặt pixel vũ khí (không tràn ra không khí)
	if (gleam_progress >= 0.0 && gleam_progress <= 1.0) {
		float diag = (UV.x + UV.y) * 0.5;
		float band = 1.0 - smoothstep(0.0, 0.11, abs(diag - gleam_progress));
		float stepped = floor(band * 3.0 + 0.5) / 3.0;
		col = mix(col, gleam_color.rgb, stepped * 0.88);
	}

	// 4. Khúc xạ thật dưới mặt nước + viền bọt trắng ngay tại đường tiếp xúc mặt nước
	float under = v_canvas_pos.y - water_line_y;
	float out_alpha = tex.a;
	if (under > 0.0) {
		if (under < 4.5) {
			col = mix(col, vec3(0.95, 0.98, 1.0), 0.74);
		} else {
			float depth_t = clamp((under - 4.5) / max(12.0, submerge_depth), 0.0, 1.0);
			vec3 water_col = mix(vec3(0.09, 0.15, 0.23), elem_color.rgb * 0.62, 0.52);
			col = mix(col, water_col, 0.60 + depth_t * 0.32);
			out_alpha *= (1.0 - depth_t * 0.86) * 0.48;
		}
	}

	COLOR = vec4(col, out_alpha);
}
"""

const _TEX_BG_P1: Texture2D = preload(
	"res://assets/pixel/backgrounds/forge_p1_hearth_bg_640x360.png"
)
const _TEX_BG_P2: Texture2D = preload(
	"res://assets/pixel/backgrounds/forge_p2_anvil_bg_640x360.png"
)
const _TEX_BG_P3: Texture2D = preload(
	"res://assets/pixel/backgrounds/forge_p3_quench_bg_640x360.png"
)
const _TEX_HAMMER: Texture2D = preload(
	"res://assets/pixel/sprites/forge/forge_hammer_96x96.png"
)
const _TEX_TONGS: Texture2D = preload(
	"res://assets/pixel/sprites/forge/forge_tongs_96x48.png"
)
const _TEX_BILLET_BLADE: Texture2D = preload(
	"res://assets/pixel/sprites/forge/raw_billet_blade_64.png"
)
const _TEX_BILLET_HEAVY: Texture2D = preload(
	"res://assets/pixel/sprites/forge/raw_billet_heavy_64.png"
)
const _TEX_BILLET_STAFF: Texture2D = preload(
	"res://assets/pixel/sprites/forge/raw_billet_staff_64.png"
)

const _BG_W := 640.0
const _BG_H := 360.0
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
var _blank_id: String = ""
var _time: float = 0.0
var _flash_alpha: float = 0.0
var _flash_color: Color = Color(1.0, 0.92, 0.45)
var _shake_amp: float = 0.0
var _particles: Array[Dictionary] = []
var _shockwaves: Array[Dictionary] = []
var _ember_timer: float = 0.0
var _smoke_timer: float = 0.0

# Trạng thái Phase 1 (Bễ co bóp cục bộ)
var _bellows_phase: float = 0.0
var _bellows_puff_timer: float = 0.0

# Trạng thái Phase 2 (Rèn búa + biến hình 5 bước + hoa sen đe)
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
var _pending_hit_style: String = "cuong"
var _anvil_floor_y: float = 360.0
var _anvil_rune_glow: float = 0.0
var _anvil_rune_col: Color = Color(1.0, 0.72, 0.22)

# Trạng thái Phase 3 (Tôi nước theo thao tác bấm + shader cắt mặt nước 32-bit)
var _quench_state: _QuenchState = _QuenchState.IDLE
var _quench_active: bool = false
var _quench_state_time: float = 0.0
var _quench_duration: float = 2.4
var _quench_color: Color = Color(0.28, 0.72, 1.0)
var _quench_splashed: bool = false
var _quench_steam_timer: float = 0.0
var _quench_drip_timer: float = 0.0
var _quench_ember_timer: float = 0.0
var _quench_plunge_start_y_off: float = -48.0
var _quench_cur_y_off: float = -48.0
var _quench_hot_amount: float = 1.0
var _quench_cool_frac: float = 0.0
var _quench_elem_infuse: float = 0.0
var _quench_gleam_prog: float = -1.0
var _quench_shake_trauma: float = 0.0
var quench_progress: float = 0.0
var quench_target_progress: float = 0.70
var is_perfect_quench: bool = false
var _water_tint_strength: float = 0.0
var _quench_weapon_sprite: Sprite2D = null
var _quench_weapon_mat: ShaderMaterial = null
var _quench_fg_layer: Control = null


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_setup_quench_layers()


func _setup_quench_layers() -> void:
	var shader := Shader.new()
	shader.code = _QUENCH_WEAPON_SHADER_CODE
	_quench_weapon_mat = ShaderMaterial.new()
	_quench_weapon_mat.shader = shader

	_quench_weapon_sprite = Sprite2D.new()
	_quench_weapon_sprite.name = "QuenchWeaponSprite"
	_quench_weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_quench_weapon_sprite.material = _quench_weapon_mat
	_quench_weapon_sprite.visible = false
	add_child(_quench_weapon_sprite)

	_quench_fg_layer = Control.new()
	_quench_fg_layer.name = "QuenchForegroundLayer"
	_quench_fg_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_quench_fg_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quench_fg_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_quench_fg_layer.draw.connect(_draw_quench_foreground)
	add_child(_quench_fg_layer)


func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_particles.clear()
	_shockwaves.clear()
	_flash_alpha = 0.0
	_shake_amp = 0.0
	_quench_shake_trauma = 0.0
	_impact_punch = 0.0
	_impact_punch_vel = 0.0
	_arc_alpha = 0.0
	_hammer_state = _HammerState.IDLE
	_hammer_angle = _HAMMER_REST_ANGLE
	_hitstop_timer = 0.0
	_bellows_phase = 0.0
	_bellows_puff_timer = 0.0
	_combo_count = 0
	_anvil_rune_glow = 0.0
	if new_mode != Mode.MODE_QUENCH:
		_quench_state = _QuenchState.IDLE
		_quench_active = false
		quench_progress = 0.0
		is_perfect_quench = false
		_water_tint_strength = 0.0
		if _quench_weapon_sprite != null:
			_quench_weapon_sprite.visible = false
	else:
		_quench_state = _QuenchState.IDLE
		_quench_active = false
		_quench_cur_y_off = -64.0
		_quench_plunge_start_y_off = -64.0
		_quench_hot_amount = 1.0
		_quench_cool_frac = 0.0
		_quench_elem_infuse = 0.0
		_quench_gleam_prog = -1.0
		_water_tint_strength = 0.0
		quench_progress = 0.0
		is_perfect_quench = false
	queue_redraw()
	if _quench_fg_layer != null:
		_quench_fg_layer.queue_redraw()


func set_weapon_texture(tex: Texture2D) -> void:
	# LUẬT DỰ ÁN: Chỉ chấp nhận sprite từ bộ 32-bit mới (res://assets/pixel/)
	if tex != null and tex.resource_path.begins_with("res://assets/pixel/"):
		_weapon_tex = tex
	else:
		_weapon_tex = null
	queue_redraw()


func set_blank_id(blank_id: String) -> void:
	_blank_id = blank_id
	queue_redraw()


func _get_raw_billet_texture() -> Texture2D:
	match _blank_id:
		"bua_chien", "khien_dong":
			return _TEX_BILLET_HEAVY
		"gay_phep":
			return _TEX_BILLET_STAFF
		_:
			return _TEX_BILLET_BLADE


func _get_anvil_weapon_rotation() -> float:
	# Các sprite vũ khí gốc nghiêng -45° lên góc trên-phải -> xoay +45° (+PI/4) để nằm ngang trên mặt đe
	match _blank_id:
		"khien_dong", "song_dao":
			return 0.0
		_:
			return PI * 0.25


func _get_quench_weapon_rotation() -> float:
	# Xoay mũi/đầu nặng vũ khí chĩa thẳng xuống bể nước để nhúng tự nhiên, chuôi ở trên cho kìm kẹp
	match _blank_id:
		"khien_dong":
			return 0.0
		"song_dao":
			return PI
		_:
			return PI * 0.75


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


func trigger_strike(hit_result: int, strike_style: String = "cuong") -> void:
	# 0 = PERFECT, 1 = GOOD, 2 = MISS; strike_style = "cuong" (Đỏ Cam) | "nhu" (Lam Ngọc)
	_pending_hit_result = hit_result
	_pending_hit_style = strike_style
	_hammer_start_angle = _hammer_angle
	_hammer_target_angle = _HAMMER_MISS_ANGLE if hit_result == 2 else _HAMMER_IMPACT_ANGLE
	_hammer_state = _HammerState.SWING_DOWN
	_hammer_timer = 0.0
	_arc_alpha = 0.95 if hit_result == 0 else (0.68 if hit_result == 1 else 0.35)
	if hit_result == 2:
		_arc_color = Color(0.65, 0.58, 0.56)
	elif strike_style == "nhu":
		_arc_color = Color(0.42, 0.90, 1.0) if hit_result == 0 else Color(0.32, 0.78, 0.94)
	elif _combo_count >= 2:
		_arc_color = Color(1.0, 0.82, 0.28)
	elif hit_result == 0:
		_arc_color = Color(1.0, 0.62, 0.16)
	else:
		_arc_color = Color(0.96, 0.44, 0.12)
	queue_redraw()


func set_quench_progress(p: float, target_p: float = 0.70) -> void:
	quench_progress = clampf(p, 0.0, 1.0)
	quench_target_progress = clampf(target_p, 0.1, 0.9)
	queue_redraw()
	if _quench_fg_layer != null:
		_quench_fg_layer.queue_redraw()


func trigger_perfect_quench() -> void:
	trigger_quench_plunge(true)


func trigger_quench_plunge(perfect: bool) -> void:
	if not _quench_active or _quench_state != _QuenchState.AIMING:
		return
	is_perfect_quench = perfect
	_quench_state = _QuenchState.PLUNGING
	_quench_state_time = 0.0
	_quench_splashed = false
	_quench_plunge_start_y_off = _quench_cur_y_off
	queue_redraw()
	if _quench_fg_layer != null:
		_quench_fg_layer.queue_redraw()


func start_quench_sequence(elem_color: Color, duration: float) -> void:
	mode = Mode.MODE_QUENCH
	_particles.clear()
	_shockwaves.clear()
	_quench_active = true
	_quench_state = _QuenchState.AIMING
	_quench_state_time = 0.0
	_quench_duration = maxf(0.4, duration)
	_quench_color = elem_color
	_quench_splashed = false
	_quench_steam_timer = 0.0
	_quench_drip_timer = 0.0
	_quench_ember_timer = 0.0
	_quench_cur_y_off = -64.0
	_quench_plunge_start_y_off = -64.0
	_quench_hot_amount = 1.0
	_quench_cool_frac = 0.0
	_quench_elem_infuse = 0.0
	_quench_gleam_prog = -1.0
	_quench_shake_trauma = 0.0
	quench_progress = 0.0
	is_perfect_quench = false
	_water_tint_strength = 1.0
	_flash_alpha = 0.0
	_shake_amp = 0.0
	queue_redraw()
	if _quench_fg_layer != null:
		_quench_fg_layer.queue_redraw()


func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	_time += dt
	_flash_alpha = maxf(0.0, _flash_alpha - dt * 3.0)
	_shake_amp = maxf(0.0, _shake_amp - dt * 34.0)
	_quench_shake_trauma = maxf(0.0, _quench_shake_trauma - dt * 3.4)
	_arc_alpha = maxf(0.0, _arc_alpha - dt * 4.5)
	_anvil_rune_glow = maxf(0.0, _anvil_rune_glow - dt * 1.9)

	match mode:
		Mode.MODE_HEAT:
			_process_heat(dt)
		Mode.MODE_ANVIL:
			_process_anvil(dt)
		Mode.MODE_QUENCH:
			_process_quench(dt)

	_update_particles(dt)
	_update_shockwaves(dt)
	queue_redraw()
	if _quench_fg_layer != null:
		_quench_fg_layer.queue_redraw()


func _process_heat(delta: float) -> void:
	if is_pumping:
		_bellows_phase += delta * 12.5
		_bellows_puff_timer += delta
		if _bellows_puff_timer >= 0.16:
			_bellows_puff_timer = 0.0
			_spawn_bellows_puff()
	else:
		_bellows_phase = lerpf(_bellows_phase, 0.0, minf(1.0, delta * 10.0))
		_bellows_puff_timer = 0.0

	if heat_percent > 0.14 or is_pumping:
		_ember_timer += delta
		var interval := 0.030 if is_pumping else 0.090
		if _ember_timer >= interval:
			_ember_timer = 0.0
			_spawn_heat_ember()

	if heat_percent >= burn_frac:
		_smoke_timer += delta
		if _smoke_timer >= 0.055:
			_smoke_timer = 0.0
			_spawn_burn_smoke()
	else:
		_smoke_timer = 0.0


func _process_anvil(delta: float) -> void:
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
	var is_nhu := (_pending_hit_style == "nhu")
	var count := 12
	var tail_col := Color(0.36, 0.86, 1.0) if is_nhu else Color(1.0, 0.46, 0.12)
	var core_col := Color(1.0, 0.96, 0.66) if is_nhu else Color(1.0, 0.98, 0.85)
	if hit_result == 0:
		count = 24 if is_nhu else 32
		tail_col = Color(0.34, 0.88, 1.0) if is_nhu else Color(1.0, 0.54, 0.12)
		_flash_color = Color(0.68, 0.96, 1.0) if is_nhu else Color(1.0, 0.78, 0.32)
		_flash_alpha = 0.88 if is_nhu else 0.95
		_shake_amp = 3.0 if is_nhu else 6.0
		_impact_punch = 4.5 if is_nhu else 8.5
		_impact_punch_vel = 26.0 if is_nhu else 42.0
		_anvil_rune_glow = 1.0
		_anvil_rune_col = Color(0.45, 0.94, 1.0) if is_nhu else Color(1.0, 0.72, 0.20)
		_shockwaves.append({
			"pos": impact, "r": 12.0, "max_r": 136.0 if is_nhu else 156.0,
			"life": 0.36, "max_life": 0.36,
			"color": _anvil_rune_col, "width": 3.2 if is_nhu else 4.0, "flat": 0.46,
		})
		_shockwaves.append({
			"pos": impact, "r": 6.0, "max_r": 90.0, "life": 0.24, "max_life": 0.24,
			"color": Color(1.0, 0.98, 0.78), "width": 2.2, "flat": 0.46,
		})
	elif hit_result == 1:
		count = 14 if is_nhu else 20
		tail_col = Color(0.30, 0.80, 0.96) if is_nhu else Color(0.98, 0.44, 0.10)
		_flash_color = Color(0.62, 0.90, 1.0) if is_nhu else Color(1.0, 0.64, 0.20)
		_flash_alpha = 0.48 if is_nhu else 0.58
		_shake_amp = 2.2 if is_nhu else 4.2
		_impact_punch = 3.2 if is_nhu else 5.5
		_impact_punch_vel = 16.0 if is_nhu else 26.0
		_anvil_rune_glow = 0.55
		_anvil_rune_col = tail_col
		_shockwaves.append({
			"pos": impact, "r": 10.0, "max_r": 84.0 if is_nhu else 96.0,
			"life": 0.26, "max_life": 0.26,
			"color": tail_col, "width": 2.4 if is_nhu else 3.0, "flat": 0.46,
		})
	else:
		count = 10
		tail_col = Color(0.50, 0.44, 0.42)
		_flash_color = Color(0.80, 0.22, 0.18)
		_flash_alpha = 0.36
		_shake_amp = 2.0 if is_nhu else 3.8
		_impact_punch = 2.0
		_impact_punch_vel = 10.0

	var is_gold_combo := (_combo_count >= 2 and hit_result != 2)
	if is_gold_combo:
		count = int(count * 1.55)
		_flash_alpha = minf(1.0, _flash_alpha + 0.16)
		_anvil_rune_glow = 1.0
		_shockwaves.append({
			"pos": impact, "r": 8.0, "max_r": 168.0, "life": 0.40, "max_life": 0.40,
			"color": Color(0.54, 0.95, 1.0) if is_nhu else Color(1.0, 0.78, 0.20),
			"width": 3.6, "flat": 0.46,
		})

	for i in range(count):
		var ang := randf_range(-PI * 0.85, -PI * 0.15) if is_nhu else randf_range(-PI * 0.95, -PI * 0.05)
		var spd := randf_range(130.0, 340.0) if is_nhu else randf_range(175.0, 440.0)
		if hit_result == 2:
			spd = randf_range(50.0, 140.0)
		var spark_col := tail_col
		if is_nhu and hit_result != 2 and (i % 3 == 0):
			spark_col = Color(1.0, 0.92, 0.48)
		_particles.append({
			"kind": "spark" if hit_result != 2 else "smoke",
			"pos": impact + Vector2(randf_range(-20.0, 20.0), randf_range(-4.0, 4.0)),
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"gravity": 520.0 if (hit_result != 2 and is_nhu) else (640.0 if hit_result != 2 else -35.0),
			"life": randf_range(0.30, 0.66),
			"max_life": 0.66,
			"size": (4.4 if is_nhu else 6.0) if hit_result == 0 else (3.6 if is_nhu else 4.8),
			"color": spark_col,
			"core": core_col,
			"bounce": hit_result != 2,
		})


func _process_quench(delta: float) -> void:
	if not _quench_active:
		return
	_quench_state_time += delta

	match _quench_state:
		_QuenchState.AIMING:
			# Vũ khí nóng đỏ lơ lửng trọn vẹn phía trên mặt nước, hạ chậm tạo độ căng chờ bấm
			var tension_t := clampf(quench_progress / maxf(0.01, quench_target_progress), 0.0, 1.0)
			_quench_cur_y_off = lerpf(-66.0, -54.0, tension_t) + sin(_time * 6.5) * 1.0
			_quench_hot_amount = 1.0
			_quench_cool_frac = 0.0
			_quench_elem_infuse = 0.0
			_quench_gleam_prog = -1.0
			_quench_ember_timer += delta
			if _quench_ember_timer >= 0.16:
				_quench_ember_timer = 0.0
				_spawn_quench_hot_ember()
		_QuenchState.PLUNGING:
			# Lao thẳng dứt khoát từ trên mặt nước xuống ngập trong thùng gỗ (0.13s, ease-in cubic)
			var dur := 0.13
			var p := clampf(_quench_state_time / dur, 0.0, 1.0)
			var ease_in := p * p * p
			_quench_cur_y_off = lerpf(_quench_plunge_start_y_off, 14.0, ease_in)
			if p >= 0.45 and not _quench_splashed:
				_quench_splashed = true
				_trigger_quench_splash(is_perfect_quench)
				quench_water_impact.emit(is_perfect_quench)
			if p >= 1.0:
				_quench_state_time = 0.0
				if is_perfect_quench:
					_quench_state = _QuenchState.HITSTOP
				else:
					_quench_state = _QuenchState.SOAKING
		_QuenchState.HITSTOP:
			# Hitstop ngắn 40ms khi Tôi Hoàn Hảo tạo cảm giác lực đanh thép
			if _quench_state_time >= 0.04:
				_quench_state = _QuenchState.SOAKING
				_quench_state_time = 0.0
		_QuenchState.SOAKING:
			# Ngâm trong nước 0.48s: nhiệt rút dần từ mũi lên chuôi, cột hơi nước pixel bốc lên
			var dur := 0.48
			var p := clampf(_quench_state_time / dur, 0.0, 1.0)
			var tremble := (1.0 - p) * 1.2 * sin(_time * 32.0)
			_quench_cur_y_off = 14.0 + tremble
			_quench_cool_frac = ease(p, 0.65)
			_quench_hot_amount = clampf(1.0 - p * 0.85, 0.0, 1.0)
			_quench_elem_infuse = clampf(p * 1.15, 0.0, 1.0)
			_quench_steam_timer += delta
			var steam_iv := 0.022 if is_perfect_quench else 0.032
			if _quench_steam_timer >= steam_iv:
				_quench_steam_timer = 0.0
				_spawn_quench_steam_puff()
				if is_perfect_quench:
					_spawn_quench_steam_puff()
			if p >= 1.0:
				_quench_state = _QuenchState.LIFTING
				_quench_state_time = 0.0
		_QuenchState.LIFTING:
			# Nhấc mượt thanh vũ khí đã tôi lên khỏi mặt nước + nhỏ giọt nước + vệt sáng quét thân
			var dur := 0.44
			var p := clampf(_quench_state_time / dur, 0.0, 1.0)
			var ease_out := 1.0 - pow(1.0 - p, 3.0)
			_quench_cur_y_off = lerpf(14.0, -48.0, ease_out)
			_quench_hot_amount = 0.0
			_quench_cool_frac = 1.0
			_quench_elem_infuse = lerpf(1.0, 0.35 if is_perfect_quench else 0.18, p)
			if p >= 0.25 and p <= 0.88:
				_quench_gleam_prog = clampf((p - 0.25) / 0.63, 0.0, 1.0)
			else:
				_quench_gleam_prog = -1.0
			if p < 0.78:
				_quench_drip_timer += delta
				if _quench_drip_timer >= 0.075:
					_quench_drip_timer = 0.0
					_spawn_quench_drip()
			if p >= 1.0:
				_quench_state = _QuenchState.HOLD
				_quench_state_time = 0.0
				if is_perfect_quench:
					_spawn_perfect_glint_burst()
		_QuenchState.HOLD:
			var dur := 0.26
			var p := clampf(_quench_state_time / dur, 0.0, 1.0)
			_quench_cur_y_off = -48.0 + sin(_time * 4.5) * 1.2
			_quench_gleam_prog = -1.0
			if p >= 1.0:
				_quench_state = _QuenchState.IDLE
				_quench_active = false
				quench_sequence_finished.emit()


func _trigger_quench_splash(perfect: bool) -> void:
	var water := _get_quench_water_entry()
	_quench_shake_trauma = 0.92 if perfect else 0.56
	_flash_color = Color(1.0, 0.94, 0.55) if perfect else _quench_color.lightened(0.45)
	_flash_alpha = 0.42 if perfect else 0.22

	_shockwaves.append({
		"pos": water, "r": 12.0, "max_r": 118.0 if perfect else 92.0,
		"life": 0.52, "max_life": 0.52,
		"color": Color(1.0, 0.90, 0.38) if perfect else _quench_color.lightened(0.38),
		"width": 3.0, "flat": 0.40, "pixel": true,
	})
	_shockwaves.append({
		"pos": water, "r": 6.0, "max_r": 146.0 if perfect else 112.0,
		"life": 0.68, "max_life": 0.68,
		"color": Color(0.95, 0.97, 1.0, 0.85),
		"width": 2.0, "flat": 0.40, "pixel": true,
	})

	var drop_count := 26 if perfect else 16
	for _i in range(drop_count):
		var ang := randf_range(-PI * 0.86, -PI * 0.14)
		var spd := randf_range(135.0, 310.0) if perfect else randf_range(105.0, 235.0)
		_particles.append({
			"kind": "droplet",
			"pos": water + Vector2(randf_range(-28.0, 28.0), randf_range(-4.0, 4.0)),
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"gravity": 520.0,
			"life": randf_range(0.34, 0.66),
			"max_life": 0.66,
			"size": 6.0 if randf() > 0.45 else 3.0,
			"color": _quench_color.lightened(randf_range(0.22, 0.60)),
			"core": Color(0.96, 0.98, 1.0),
			"bounce": false,
		})

	if perfect:
		for i in range(18):
			var ang := randf_range(-PI * 0.92, -PI * 0.08)
			var spd := randf_range(150.0, 340.0)
			var is_gold := (i % 2 == 0)
			_particles.append({
				"kind": "glint",
				"pos": water + Vector2(randf_range(-24.0, 24.0), randf_range(-8.0, 4.0)),
				"vel": Vector2(cos(ang), sin(ang)) * spd,
				"gravity": 180.0,
				"life": randf_range(0.42, 0.76),
				"max_life": 0.76,
				"size": 6.0,
				"color": Color(1.0, 0.88, 0.32) if is_gold else _quench_color.lightened(0.55),
				"core": Color(1.0, 0.98, 0.88),
				"bounce": false,
			})

	var puff_count := 16 if perfect else 11
	for _j in range(puff_count):
		_spawn_quench_steam_puff()


func _spawn_quench_hot_ember() -> void:
	var bg := _get_bg_rect(Vector2.ZERO)
	var s := bg.size.x / _BG_W
	var entry := _get_quench_water_entry()
	var w_pos := Vector2(entry.x, entry.y + _quench_cur_y_off * s)
	_particles.append({
		"kind": "ember",
		"pos": w_pos + Vector2(randf_range(-12.0, 12.0) * s, randf_range(-10.0, 18.0) * s),
		"vel": Vector2(randf_range(-18.0, 18.0), randf_range(-42.0, -14.0)),
		"gravity": -10.0,
		"life": randf_range(0.35, 0.65),
		"max_life": 0.65,
		"size": 3.0,
		"color": Color(1.0, randf_range(0.46, 0.84), 0.16),
		"core": Color(1.0, 0.96, 0.75),
		"bounce": false,
	})


func _spawn_quench_drip() -> void:
	var bg := _get_bg_rect(Vector2.ZERO)
	var s := bg.size.x / _BG_W
	var entry := _get_quench_water_entry()
	var tip_pos := Vector2(entry.x + randf_range(-10.0, 10.0) * s, entry.y + (_quench_cur_y_off + 24.0) * s)
	_particles.append({
		"kind": "droplet",
		"pos": tip_pos,
		"vel": Vector2(randf_range(-14.0, 14.0), randf_range(40.0, 95.0)),
		"gravity": 560.0,
		"life": 0.36,
		"max_life": 0.36,
		"size": 3.0,
		"color": _quench_color.lightened(0.48),
		"core": Color(0.96, 0.99, 1.0),
		"bounce": false,
	})


func _spawn_perfect_glint_burst() -> void:
	var bg := _get_bg_rect(Vector2.ZERO)
	var s := bg.size.x / _BG_W
	var entry := _get_quench_water_entry()
	var w_pos := Vector2(entry.x, entry.y + _quench_cur_y_off * s)
	for i in range(8):
		var a := float(i) * TAU / 8.0 + randf_range(-0.18, 0.18)
		var dist := randf_range(16.0, 34.0) * s
		_particles.append({
			"kind": "glint",
			"pos": w_pos + Vector2(cos(a), sin(a)) * dist,
			"vel": Vector2(cos(a), sin(a)) * randf_range(16.0, 42.0),
			"gravity": -16.0,
			"life": randf_range(0.28, 0.48),
			"max_life": 0.48,
			"size": 6.0,
			"color": Color(1.0, 0.90, 0.36) if (i % 2 == 0) else _quench_color.lightened(0.55),
			"core": Color(1.0, 0.99, 0.90),
			"bounce": false,
		})


func _spawn_quench_steam_puff() -> void:
	var water := _get_quench_water_entry()
	var tint := Color(0.93, 0.95, 0.98).lerp(_quench_color.lightened(0.58), 0.24)
	_particles.append({
		"kind": "pixel_steam",
		"pos": water + Vector2(randf_range(-34.0, 34.0), randf_range(-8.0, 4.0)),
		"vel": Vector2(randf_range(-28.0, 28.0), randf_range(-165.0, -82.0)),
		"gravity": -22.0,
		"life": randf_range(0.52, 0.92),
		"max_life": 0.92,
		"size": randf_range(12.0, 21.0),
		"color": tint,
		"core": Color(0.98, 0.98, 1.0),
		"bounce": false,
	})


func _get_current_shake() -> Vector2:
	if mode == Mode.MODE_QUENCH:
		var amp := _quench_shake_trauma * _quench_shake_trauma * 6.5
		if amp > 0.25:
			return Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
		return Vector2.ZERO
	if _shake_amp > 0.2:
		return Vector2(randf_range(-_shake_amp, _shake_amp), randf_range(-_shake_amp, _shake_amp))
	if mode == Mode.MODE_HEAT and heat_percent >= burn_frac:
		return Vector2(randf_range(-2.4, 2.4), randf_range(-1.6, 1.6))
	return Vector2.ZERO


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var shake := _get_current_shake()

	match mode:
		Mode.MODE_HEAT:
			if _quench_weapon_sprite != null:
				_quench_weapon_sprite.visible = false
			_draw_heat_stage(shake)
			_draw_shockwaves(shake)
			_draw_particles(shake)
		Mode.MODE_ANVIL:
			if _quench_weapon_sprite != null:
				_quench_weapon_sprite.visible = false
			_draw_anvil_stage(shake)
			_draw_shockwaves(shake)
			_draw_particles(shake)
		Mode.MODE_QUENCH:
			_draw_quench_stage(shake)


# ══════════════════════════════════════════════════════════════════════════════
# MODE_HEAT — PHASE 1: NỀN LÒ THAN LIỀN KHỐI + BỄ CO BÓP + HOA SEN HẮT SÁNG
# ══════════════════════════════════════════════════════════════════════════════

func _draw_heat_stage(shake: Vector2) -> void:
	var bg := _get_bg_rect(shake)
	var s := bg.size.x / _BG_W
	draw_texture_rect(_TEX_BG_P1, bg, false)

	var coal_center := _bg_pt(bg, 0.50, 0.515)

	# 1. Quầng sáng mềm nhiều lớp trong hố than (không vẽ cột lửa hình chữ nhật hay bóp méo nền)
	var pulse := 0.90 + sin(_time * 8.5) * 0.10
	var glow_str := clampf(heat_percent * 0.95 + (0.28 if is_pumping else 0.0), 0.08, 1.20)
	_draw_soft_glow(coal_center, 88.0 * s, 40.0 * s, Color(1.0, 0.36, 0.06), 0.24 * glow_str * pulse)
	if heat_percent >= sweet_min * 0.8:
		_draw_soft_glow(coal_center, 52.0 * s, 24.0 * s, Color(1.0, 0.72, 0.18), 0.22 * glow_str * pulse)
	if heat_percent >= peak_frac and heat_percent < burn_frac:
		_draw_soft_glow(coal_center, 34.0 * s, 16.0 * s, Color(1.0, 0.94, 0.62), 0.20 * pulse)

	# 2. Ánh phản xạ nhẹ khi bơm bễ ở mũi ống đồng (giữ nguyên toàn vẹn nền bễ 32-bit)
	if is_pumping:
		var nozzle := _bg_pt(bg, 0.355, 0.495)
		_draw_soft_glow(nozzle, 18.0 * s, 10.0 * s, Color(1.0, 0.78, 0.36), 0.26 * pulse)

	# 3. Duy nhất 1 thanh phôi sạch nằm gọn trong lòng than hồng (không chồng 2 ảnh, không kìm lệch tông)
	var bob := sin(_time * 10.0) * (1.2 if is_pumping else 0.4)
	var billet_center := coal_center + Vector2(0.0, -2.0 * s + bob)
	var billet_col := _billet_color(heat_percent)
	_draw_heated_weapon_or_billet(billet_center, billet_col, s)


func _draw_soft_glow(center: Vector2, rx: float, ry: float, col: Color, max_alpha: float) -> void:
	# Vẽ 4 lớp elip mờ chồng nhau tạo ánh sáng lan mềm tự nhiên, không bao giờ có viền cứng
	for i in range(4):
		var frac := 1.0 - float(i) * 0.22
		var a := max_alpha * (0.24 + float(i) * 0.18)
		_draw_ellipse_fill(center, rx * frac, ry * frac, Color(col.r, col.g, col.b, a))


func _draw_tongs(grip_pos: Vector2, wrist_tilt: float, s: float) -> void:
	if _TEX_TONGS != null:
		var tongs_scale := clampf(s * 0.90, 1.50, 2.75)
		draw_set_transform(grip_pos, wrist_tilt, Vector2(-tongs_scale, tongs_scale))
		draw_texture_rect(_TEX_TONGS, Rect2(Vector2(-85.0, -24.0), Vector2(96.0, 48.0)), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_heated_weapon_or_billet(center: Vector2, billet_col: Color, s: float) -> void:
	# Bóng tiếp xúc gọn dưới đáy phôi hòa vào lớp than
	_draw_ellipse_fill(center + Vector2(0.0, 9.0 * s), 34.0 * s, 7.0 * s, Color(0.05, 0.02, 0.02, 0.58))
	var tex := _get_raw_billet_texture()
	var w_sz := 68.0 * s
	var tint := _billet_heat_tint(heat_percent)
	if heat_percent >= sweet_min and heat_percent < burn_frac:
		var glow_col := Color(billet_col.r, billet_col.g, billet_col.b, 0.34)
		draw_texture_rect(
			tex,
			Rect2(center - Vector2(w_sz * 0.54, w_sz * 0.54), Vector2(w_sz * 1.08, w_sz * 1.08)),
			false,
			glow_col
		)
	draw_texture_rect(tex, Rect2(center - Vector2(w_sz * 0.5, w_sz * 0.5), Vector2(w_sz, w_sz)), false, tint)


# ══════════════════════════════════════════════════════════════════════════════
# MODE_ANVIL — PHASE 2: NỀN ĐE LIỀN KHỐI + PHÔI BIẾN HÌNH 5 BƯỚC + HOA SEN SÁNG
# ══════════════════════════════════════════════════════════════════════════════

func _draw_anvil_stage(shake: Vector2) -> void:
	var bg := _get_bg_rect(shake + Vector2(0.0, _impact_punch * 0.38))
	var s := bg.size.x / _BG_W
	draw_texture_rect(_TEX_BG_P2, bg, false)

	var anvil_top := _bg_pt(bg, 0.515, 0.296)
	var lotus_top := _bg_pt(bg, 0.505, 0.296)
	var lotus_body := _bg_pt(bg, 0.505, 0.445)
	var impact := _get_strike_hotspot_on_bg(bg, _strike_idx)
	_anvil_floor_y = _bg_pt(bg, 0.50, 0.342).y

	# 1. Gu 3 — Ấn Hoa Sen khắc trên mặt đe & thân đe bùng sáng theo hướng Cương / Nhu
	if _anvil_rune_glow > 0.02:
		var ga := _anvil_rune_glow
		var gc := Color(_anvil_rune_col.r, _anvil_rune_col.g, _anvil_rune_col.b, 0.42 * ga)
		var ghi := Color(1.0, 0.98, 0.85, 0.72 * ga)
		_draw_ellipse_fill(lotus_top, 30.0 * s * (1.15 - ga * 0.15), 11.0 * s, gc)
		_draw_ellipse_outline(lotus_top, 24.0 * s, 9.0 * s, ghi, 2.0 * ga)
		_draw_ellipse_fill(lotus_body, 22.0 * s, 14.0 * s, Color(gc.r, gc.g, gc.b, gc.a * 0.75))

	# 2. Bóng tiếp xúc của phôi trên mặt đe sắt
	var shape_prog := clampf(float(_strike_idx) / float(maxi(1, _total_strikes)), 0.0, 1.0)
	_draw_ellipse_fill(
		anvil_top + Vector2(0.0, 6.0 * s),
		(46.0 + shape_prog * 14.0) * s,
		7.0 * s,
		Color(0.04, 0.02, 0.03, 0.55)
	)

	# 3. Gu 2 — Phôi biến hình 5 bước từ thỏi sắt thô -> dáng vũ khí thật
	_draw_morphing_billet(anvil_top + Vector2(0.0, -2.0 * s), shape_prog, s)

	# 4. Vết búa các nhát đã đập + điểm nóng nhát hiện tại
	_draw_past_strikes_on_bg(bg, s)
	_draw_strike_hotspot(impact, s * 0.72)

	# 5. Quầng lóe va chạm
	if _flash_alpha > 0.02:
		draw_circle(
			impact,
			(34.0 + (1.0 - _flash_alpha) * 22.0) * s,
			Color(_flash_color.r, _flash_color.g, _flash_color.b, _flash_alpha * 0.42)
		)

	# 6. Gu 1 — Vệt vung búa (motion arc) + Cây búa xoay trục + bóng đổ trên mặt đe
	var h_scale := s * 0.92
	var pivot := impact + Vector2(68.0 * h_scale, 8.0 * h_scale)
	if _arc_alpha > 0.02:
		var arc_col := Color(1.0, 0.92, 0.35) if _combo_count >= 2 else _arc_color
		_draw_hammer_motion_arc(pivot, 68.0 * h_scale, arc_col)

	draw_set_transform(pivot, _hammer_angle, Vector2(h_scale, h_scale))
	if _combo_count >= 2:
		_draw_golden_hammer_aura()
	draw_texture_rect(_TEX_HAMMER, Rect2(-_HAMMER_PIVOT_PX, Vector2(96.0, 96.0)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_morphing_billet(center: Vector2, shape_prog: float, s: float) -> void:
	var hot_tint := Color(1.0, 0.62, 0.24).lerp(Color(1.0, 0.90, 0.68), shape_prog * 0.55)
	if _flash_alpha > 0.01:
		hot_tint = hot_tint.lerp(_flash_color.lightened(0.30), _flash_alpha * 0.75)

	# Nhát 0 -> 3: Sprite phôi thô 32-bit thật dẹt & kéo dài dần trên mặt đe
	var billet_alpha := clampf(1.0 - maxf(0.0, (shape_prog - 0.50) / 0.40), 0.0, 1.0)
	if billet_alpha > 0.02 or _weapon_tex == null:
		var tex := _get_raw_billet_texture()
		var bw := (64.0 + shape_prog * 18.0) * s
		var bh := (64.0 - shape_prog * 12.0) * s
		var b_tint := Color(hot_tint.r, hot_tint.g, hot_tint.b, billet_alpha if _weapon_tex != null else 1.0)
		draw_texture_rect(tex, Rect2(center - Vector2(bw * 0.5, bh * 0.5), Vector2(bw, bh)), false, b_tint)

	# Nhát 2 -> 5: Hình dáng vũ khí thành phẩm 32-bit thật hiện rõ dần theo từng nhát đập
	if _weapon_tex != null and shape_prog > 0.25:
		var weap_alpha := clampf((shape_prog - 0.25) / 0.60, 0.0, 1.0)
		var w_sz := (46.0 + shape_prog * 18.0) * s
		var tint := Color(1.0, 0.66, 0.28).lerp(Color(1.0, 0.96, 0.86), shape_prog * 0.75)
		if _flash_alpha > 0.01:
			tint = tint.lerp(_flash_color.lightened(0.35), _flash_alpha)
		tint.a = weap_alpha
		var rot := _get_anvil_weapon_rotation()
		var w_scale := Vector2(1.0, 0.70) if _blank_id == "khien_dong" else Vector2.ONE
		draw_set_transform(center + Vector2(0.0, -2.0 * s), rot, w_scale)
		if shape_prog >= 0.75:
			var glow := Color(1.0, 0.78, 0.28, 0.28 * weap_alpha)
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


func _draw_golden_hammer_aura() -> void:
	var head_pos := Vector2(-60.0, -64.0)
	var pulse := 0.85 + sin(_time * 12.0) * 0.15
	draw_circle(head_pos, 26.0 * pulse, Color(1.0, 0.82, 0.15, 0.24 * pulse))
	draw_circle(head_pos, 16.0 * pulse, Color(1.0, 0.92, 0.35, 0.40 * pulse))
	draw_circle(head_pos, 7.0 * pulse, Color(1.0, 0.98, 0.70, 0.65))


func _draw_strike_hotspot(pos: Vector2, s: float) -> void:
	var pulse := 0.85 + sin(_time * 10.0) * 0.15
	var r := 8.5 * s * pulse
	draw_circle(pos, r * 1.8, Color(1.0, 0.75, 0.18, 0.24 * pulse))
	draw_arc(pos, r, 0.0, TAU, 18, Color(1.0, 0.92, 0.40, 0.85 * pulse), 2.0)
	draw_circle(pos, 2.8 * s, Color(1.0, 0.98, 0.80, 0.95))


func _draw_past_strikes_on_bg(bg: Rect2, s: float) -> void:
	for i in range(_strike_idx):
		var p := _get_strike_hotspot_on_bg(bg, i)
		draw_circle(p, 3.0 * s, Color(0.12, 0.08, 0.06, 0.65))
		draw_circle(p, 1.8 * s, Color(0.95, 0.52, 0.16, 0.65))


func _draw_hammer_motion_arc(pivot: Vector2, radius: float, custom_col: Color = Color.TRANSPARENT) -> void:
	var use_col := _arc_color if custom_col.a <= 0.001 else custom_col
	var start_rad := -2.35 + _HAMMER_MAX_WINDUP * 0.72
	var end_rad := -2.35 + _HAMMER_IMPACT_ANGLE
	var steps := 10
	for k in range(3):
		var r_off := radius * (0.86 + k * 0.08)
		var width := (10.0 - k * 2.6) + (2.0 if _combo_count >= 2 else 0.0)
		var alpha := _arc_alpha * (0.42 - k * 0.11)
		var pts := PackedVector2Array()
		for i in range(steps + 1):
			var frac := float(i) / float(steps)
			var ang := lerpf(start_rad, end_rad, frac)
			pts.append(pivot + Vector2(cos(ang), sin(ang)) * r_off)
		draw_polyline(pts, Color(use_col.r, use_col.g, use_col.b, alpha), width)


# ══════════════════════════════════════════════════════════════════════════════
# MODE_QUENCH — PHASE 3: BỂ TÔI 32-BIT, SHADER KHÚC XẠ MẶT NƯỚC & PIXEL JUICE
# ══════════════════════════════════════════════════════════════════════════════

func _draw_quench_stage(shake: Vector2) -> void:
	var bg := _get_bg_rect(shake)
	var s := bg.size.x / _BG_W
	var px := maxf(2.0, roundf(s))
	draw_texture_rect(_TEX_BG_P3, bg, false)

	var water_center := _bg_pt(bg, 0.5008, 0.3167)
	var water_entry := _bg_pt(bg, 0.5008, 0.328)
	var water_rx := 84.0 * s
	var water_ry := 32.0 * s

	# 1. Nhuộm màu mặt nước linh lực mềm nằm lọt lòng thùng gỗ (không tràn viền gỗ)
	if _water_tint_strength > 0.01:
		var is_submerged := (
			_quench_state == _QuenchState.PLUNGING
			or _quench_state == _QuenchState.HITSTOP
			or _quench_state == _QuenchState.SOAKING
		)
		var tint_a := (0.34 if is_submerged else 0.24) * _water_tint_strength
		_draw_ellipse_fill(
			water_center,
			water_rx,
			water_ry,
			Color(_quench_color.r, _quench_color.g, _quench_color.b, tint_a)
		)
		# Phản chiếu ánh nóng đỏ của phôi lên mặt nước khi đang căn nhịp nhúng
		if _quench_state == _QuenchState.AIMING and _quench_hot_amount > 0.2:
			_draw_pixel_water_reflection(water_entry, s, px)

	# 2. Gợn sóng lăn tăn dạng pixel snap (0% đường vector mảnh)
	var wave_r := fmod(_time * 0.55, 1.0)
	_draw_pixel_ellipse_ring(
		self,
		water_center,
		water_rx * (0.28 + wave_r * 0.62),
		water_ry * (0.28 + wave_r * 0.62),
		Color(0.95, 0.98, 1.0, (1.0 - wave_r) * 0.30),
		px,
		2
	)

	# 3. Vòng Cổ Ngữ hội tụ 32-bit trên mặt nước (chỉ hiện khi đang AIMING)
	if _quench_active and _quench_state == _QuenchState.AIMING:
		_draw_converging_runes(water_entry, s, px)

	# 4. Kìm sắt kẹp chắc chuôi vũ khí (đi liền mạch suốt toàn bộ quá trình nhúng)
	var weapon_pos := Vector2(water_entry.x, water_entry.y + _quench_cur_y_off * s)
	var w_sz := 72.0 * s
	var grip_y_off := -w_sz * (0.42 if _blank_id == "khien_dong" else 0.34)
	var grip_pos := weapon_pos + Vector2(2.0 * s, grip_y_off)
	var wrist_tilt := -0.14
	match _quench_state:
		_QuenchState.PLUNGING, _QuenchState.HITSTOP, _QuenchState.SOAKING:
			wrist_tilt = -0.25
		_QuenchState.LIFTING, _QuenchState.HOLD:
			wrist_tilt = -0.09
	_draw_tongs(grip_pos, wrist_tilt, s * 0.72)

	# 5. Cập nhật Sprite2D vũ khí có Shader cắt khúc xạ mặt nước + nguội nhiệt + vệt sáng
	_sync_quench_weapon_sprite(weapon_pos, water_entry.y, w_sz, s)


func _sync_quench_weapon_sprite(
	weapon_pos: Vector2,
	water_line_local_y: float,
	w_sz: float,
	s: float
) -> void:
	if _quench_weapon_sprite == null or _quench_weapon_mat == null:
		return
	var tex := _weapon_tex if _weapon_tex != null else _get_raw_billet_texture()
	if tex == null:
		_quench_weapon_sprite.visible = false
		return

	_quench_weapon_sprite.visible = true
	_quench_weapon_sprite.texture = tex
	var tex_w := maxf(1.0, float(tex.get_width()))
	var sprite_scale := w_sz / tex_w
	_quench_weapon_sprite.position = weapon_pos
	_quench_weapon_sprite.rotation = _get_quench_weapon_rotation()
	_quench_weapon_sprite.scale = Vector2(sprite_scale, sprite_scale)

	var canvas_xform := get_global_transform_with_canvas()
	var water_canvas_y := (canvas_xform * Vector2(weapon_pos.x, water_line_local_y)).y
	var top_canvas_y := (canvas_xform * Vector2(weapon_pos.x, weapon_pos.y - w_sz * 0.55)).y
	var bot_canvas_y := (canvas_xform * Vector2(weapon_pos.x, weapon_pos.y + w_sz * 0.55)).y
	var cool_front_y := lerpf(bot_canvas_y + 12.0, top_canvas_y - 12.0, _quench_cool_frac)

	_quench_weapon_mat.set_shader_parameter("water_line_y", water_canvas_y)
	_quench_weapon_mat.set_shader_parameter("submerge_depth", 32.0 * s)
	_quench_weapon_mat.set_shader_parameter("hot_amount", _quench_hot_amount)
	_quench_weapon_mat.set_shader_parameter("cool_front_y", cool_front_y)
	_quench_weapon_mat.set_shader_parameter("elem_color", _quench_color)
	_quench_weapon_mat.set_shader_parameter("elem_infuse", _quench_elem_infuse)
	_quench_weapon_mat.set_shader_parameter("gleam_progress", _quench_gleam_prog)
	var gleam_col := (
		Color(1.0, 0.96, 0.62, 1.0)
		if is_perfect_quench
		else _quench_color.lightened(0.62)
	)
	_quench_weapon_mat.set_shader_parameter("gleam_color", gleam_col)


func _draw_quench_foreground() -> void:
	if mode != Mode.MODE_QUENCH or _quench_fg_layer == null or size.x <= 0.0:
		return
	var shake := _get_current_shake()
	var bg := _get_bg_rect(shake)
	var s := bg.size.x / _BG_W
	var px := maxf(2.0, roundf(s))
	var water_entry := _bg_pt(bg, 0.5008, 0.328)

	# 1. Bọt sủi pixel chạy quanh chỗ lưỡi vũ khí đâm xuống mặt nước (thay cho elip phẳng cũ)
	if (
		_quench_state == _QuenchState.PLUNGING
		or _quench_state == _QuenchState.HITSTOP
		or _quench_state == _QuenchState.SOAKING
	):
		_draw_pixel_waterline_foam(_quench_fg_layer, water_entry, s, px)

	# 2. Vòng sóng pixel & hạt hơi nước / giọt nước / tia sáng trước thân vũ khí
	_draw_shockwaves_on(_quench_fg_layer, shake, px)
	_draw_particles_on(_quench_fg_layer, shake, px)

	# 3. Nháy sáng cục bộ mềm quanh mặt nước lúc chạm nước (không lóe mù cả màn hình)
	if _flash_alpha > 0.02:
		var glow_col := Color(_flash_color.r, _flash_color.g, _flash_color.b, _flash_alpha * 0.28)
		_draw_pixel_ellipse_ring(
			_quench_fg_layer,
			water_entry,
			(42.0 + (1.0 - _flash_alpha) * 34.0) * s,
			(17.0 + (1.0 - _flash_alpha) * 14.0) * s,
			glow_col,
			px * 2.0,
			1
		)


func _draw_pixel_water_reflection(water_entry: Vector2, s: float, px: float) -> void:
	var step_t := int(floor(_time * 8.0))
	for row in range(4):
		var ry := water_entry.y + float(row - 1) * px * 2.0
		var half_w := (24.0 - float(row) * 4.5) * s
		var drift := float(((step_t + row * 3) % 5) - 2) * px
		var x0 := snappedf(water_entry.x - half_w * 0.5 + drift, px)
		var w := snappedf(half_w, px)
		var alpha := (0.28 - float(row) * 0.05) * _quench_hot_amount
		draw_rect(
			Rect2(Vector2(x0, snappedf(ry, px)), Vector2(w, px)),
			Color(1.0, 0.54, 0.14, alpha)
		)


func _draw_pixel_waterline_foam(canvas: CanvasItem, entry: Vector2, s: float, px: float) -> void:
	var step_t := int(floor(_time * 12.0))
	var base_rx := 22.0 * s
	var foam_light := Color(0.96, 0.98, 1.0, 0.90)
	var foam_tint := _quench_color.lightened(0.55)
	foam_tint.a = 0.78
	for i in range(14):
		var a := float(i) * TAU / 14.0 + float(step_t % 4) * 0.12
		var wobble := 0.84 + float((i * 7 + step_t) % 4) * 0.09
		var fx := snappedf(entry.x + cos(a) * base_rx * wobble, px)
		var fy := snappedf(entry.y + sin(a) * base_rx * 0.30 * wobble, px)
		var col := foam_light if ((i + step_t) % 2 == 0) else foam_tint
		var blk := px * (2.0 if ((i + step_t) % 3 == 0) else 1.0)
		canvas.draw_rect(Rect2(Vector2(fx - blk * 0.5, fy - px * 0.5), Vector2(blk, px)), col)


func _draw_converging_runes(water_entry: Vector2, s: float, px: float) -> void:
	var target_r := 30.0 * s
	var start_r := 76.0 * s
	var prog := quench_progress
	var target_p := quench_target_progress
	var shrink_frac := clampf(prog / maxf(0.01, target_p), 0.0, 1.0)
	var cur_r := lerpf(start_r, target_r, shrink_frac)
	if prog > target_p:
		cur_r = maxf(8.0 * s, target_r * (1.0 - (prog - target_p) / maxf(0.01, 1.0 - target_p)))

	var is_in_zone := absf(prog - target_p) <= 0.08
	var aspect := 0.40

	# 1. Vòng đích vàng kim ổn định trên mặt nước (pixel 3px sắc nét, không mixel)
	var target_col := (
		Color(1.0, 0.96, 0.66, 0.98)
		if is_in_zone
		else Color(0.957, 0.784, 0.349, 0.72 + sin(_time * 7.0) * 0.14)
	)
	_draw_pixel_ellipse_ring(
		self, water_entry, target_r, target_r * aspect, target_col, px, 1
	)
	if is_in_zone:
		_draw_pixel_ellipse_ring(
			self, water_entry, target_r + px, (target_r + px) * aspect,
			Color(1.0, 0.90, 0.36, 0.48), px, 2
		)

	# 4 mốc kim cương pixel ở 4 cực của vòng đích để mắt khóa tâm tức thì
	var pip_col := Color(1.0, 0.98, 0.80, 0.95) if is_in_zone else Color(0.96, 0.80, 0.38, 0.88)
	var pips := [
		Vector2(target_r, 0.0),
		Vector2(-target_r, 0.0),
		Vector2(0.0, target_r * aspect),
		Vector2(0.0, -target_r * aspect),
	]
	for off: Vector2 in pips:
		var pp := Vector2(snappedf(water_entry.x + off.x, px), snappedf(water_entry.y + off.y, px))
		draw_rect(Rect2(pp - Vector2(px, px), Vector2(px * 2.0, px * 2.0)), pip_col)

	# 2. Vòng Cổ Ngữ thu nhỏ (pixel-stepped trong màu nguyên tố, hóa vàng khi vào cửa sổ)
	var ring_col := Color(1.0, 0.94, 0.44, 0.96) if is_in_zone else _quench_color.lightened(0.36)
	ring_col.a = clampf(1.0 - pow(absf(prog - target_p) * 1.4, 2.0), 0.46, 0.96)
	_draw_pixel_ellipse_ring(
		self, water_entry, cur_r, cur_r * aspect, ring_col, px, 1
	)

	# 6 hạt cổ ngữ xoay đều trên vòng đang thu nhỏ (pixel block 2×2 thay vì đa giác vector)
	var rot := _time * 1.8
	for i in range(6):
		var a := rot + float(i) * TAU / 6.0
		var gx := snappedf(water_entry.x + cos(a) * cur_r, px)
		var gy := snappedf(water_entry.y + sin(a) * cur_r * aspect, px)
		var g_sz := px * (2.0 if is_in_zone else 1.5)
		draw_rect(Rect2(Vector2(gx - g_sz * 0.5, gy - g_sz * 0.5), Vector2(g_sz, g_sz)), ring_col)
		draw_rect(
			Rect2(Vector2(gx - px * 0.5, gy - px * 0.5), Vector2(px, px)),
			Color(1.0, 0.98, 0.88, ring_col.a)
		)


func _draw_pixel_ellipse_ring(
	canvas: CanvasItem,
	center: Vector2,
	rx: float,
	ry: float,
	col: Color,
	px: float,
	dash_stride: int = 1
) -> void:
	if rx < px or ry < px or col.a <= 0.01:
		return
	var perimeter := TAU * sqrt(maxf(1.0, (rx * rx + ry * ry) * 0.5))
	var steps := clampi(int(perimeter / maxf(px, 2.0)), 16, 128)
	var prev_key := Vector2i(-99999, -99999)
	for i in range(steps):
		if dash_stride > 1 and (i % dash_stride) != 0:
			continue
		var a := float(i) * TAU / float(steps)
		var sx := snappedf(center.x + cos(a) * rx, px)
		var sy := snappedf(center.y + sin(a) * ry, px)
		var key := Vector2i(int(roundf(sx / px)), int(roundf(sy / px)))
		if key == prev_key:
			continue
		prev_key = key
		canvas.draw_rect(Rect2(Vector2(sx, sy), Vector2(px, px)), col)


# ══════════════════════════════════════════════════════════════════════════════
# HELPERS — TỌA ĐỘ NỀN 16:9, HẠT & HÌNH HỌC
# ══════════════════════════════════════════════════════════════════════════════

func _get_bg_rect(offset: Vector2) -> Rect2:
	# Phủ kín khung nhìn theo đúng tỷ lệ 16:9, dư nhẹ 16px mỗi cạnh để shake không hở viền đen
	var pad := 16.0
	var target_w := size.x + pad * 2.0
	var target_h := size.y + pad * 2.0
	var scale_f := maxf(target_w / _BG_W, target_h / _BG_H)
	var rw := _BG_W * scale_f
	var rh := _BG_H * scale_f
	var rx := (size.x - rw) * 0.5 + offset.x
	var ry := (size.y - rh) * 0.5 + offset.y
	return Rect2(Vector2(rx, ry), Vector2(rw, rh))


func _bg_pt(bg: Rect2, nx: float, ny: float) -> Vector2:
	return Vector2(bg.position.x + bg.size.x * nx, bg.position.y + bg.size.y * ny)


func _get_strike_hotspot_on_bg(bg: Rect2, strike_idx: int) -> Vector2:
	var total := maxi(1, _total_strikes)
	var frac := float(clampi(strike_idx, 0, total - 1)) / float(maxi(1, total - 1))
	var nx := lerpf(0.435, 0.605, frac)
	return _bg_pt(bg, nx, 0.295)


func _get_anvil_impact_point(strike_idx: int = -1) -> Vector2:
	var bg := _get_bg_rect(Vector2.ZERO)
	var idx := _strike_idx if strike_idx < 0 else strike_idx
	return _get_strike_hotspot_on_bg(bg, idx)


func _get_quench_water_center() -> Vector2:
	return _bg_pt(_get_bg_rect(Vector2.ZERO), 0.5008, 0.3167)


func _get_quench_water_entry() -> Vector2:
	return _bg_pt(_get_bg_rect(Vector2.ZERO), 0.5008, 0.328)


func _billet_heat_tint(pct: float) -> Color:
	if pct >= burn_frac:
		return Color(0.36, 0.26, 0.24)
	if pct >= peak_frac:
		var t := clampf((pct - peak_frac) / maxf(0.01, burn_frac - peak_frac), 0.0, 1.0)
		return Color(1.0, 0.62, 0.24).lerp(Color(1.0, 0.96, 0.74), t)
	if pct >= sweet_min:
		var t := clampf((pct - sweet_min) / maxf(0.01, peak_frac - sweet_min), 0.0, 1.0)
		return Color(1.0, 0.58, 0.30).lerp(Color(1.0, 0.66, 0.26), t)
	var t := clampf(pct / maxf(0.01, sweet_min), 0.0, 1.0)
	return Color(0.92, 0.94, 0.98).lerp(Color(1.0, 0.64, 0.36), t)


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


func _spawn_bellows_puff() -> void:
	var bg := _get_bg_rect(Vector2.ZERO)
	var nozzle := _bg_pt(bg, 0.345, 0.495)
	for _i in range(7):
		_particles.append({
			"kind": "wind",
			"pos": nozzle + Vector2(randf_range(-4.0, 10.0), randf_range(-8.0, 8.0)),
			"vel": Vector2(randf_range(220.0, 360.0), randf_range(-34.0, 22.0)),
			"gravity": -12.0,
			"life": randf_range(0.18, 0.32),
			"max_life": 0.32,
			"size": randf_range(4.5, 7.0),
			"color": Color(1.0, 0.90, 0.68, 0.78),
			"core": Color.WHITE,
			"bounce": false,
		})


func _spawn_heat_ember() -> void:
	var bg := _get_bg_rect(Vector2.ZERO)
	var coal := _bg_pt(bg, 0.50, 0.50)
	var is_burnt := heat_percent >= burn_frac
	var col := Color(0.42, 0.38, 0.36) if is_burnt else Color(1.0, randf_range(0.45, 0.92), 0.14)
	_particles.append({
		"kind": "ember",
		"pos": coal + Vector2(randf_range(-68.0, 68.0), randf_range(-16.0, 16.0)),
		"vel": Vector2(
			randf_range(-18.0, 52.0) if is_pumping else randf_range(-24.0, 24.0),
			randf_range(-155.0, -76.0) if is_pumping else randf_range(-98.0, -52.0)
		),
		"gravity": -14.0,
		"life": randf_range(0.42, 0.85),
		"max_life": 0.85,
		"size": 5.5 if is_burnt else 4.5,
		"color": col,
		"core": Color(1.0, 0.98, 0.78),
		"bounce": false,
	})


func _spawn_burn_smoke() -> void:
	var bg := _get_bg_rect(Vector2.ZERO)
	var coal := _bg_pt(bg, 0.50, 0.46)
	_particles.append({
		"kind": "smoke",
		"pos": coal + Vector2(randf_range(-54.0, 54.0), randf_range(-12.0, 8.0)),
		"vel": Vector2(randf_range(-28.0, 28.0), randf_range(-110.0, -60.0)),
		"gravity": -10.0,
		"life": randf_range(0.55, 0.95),
		"max_life": 0.95,
		"size": randf_range(12.0, 18.0),
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
	_draw_shockwaves_on(self, shake, 3.0)


func _draw_shockwaves_on(canvas: CanvasItem, shake: Vector2, px: float) -> void:
	for sw: Dictionary in _shockwaves:
		var alpha := clampf(float(sw["life"]) / float(sw["max_life"]), 0.0, 1.0)
		var col: Color = sw["color"]
		col.a *= alpha
		var r: float = sw["r"]
		var flat: float = sw.get("flat", 0.5)
		var center := (sw["pos"] as Vector2) + shake
		if bool(sw.get("pixel", false)):
			_draw_pixel_ellipse_ring(canvas, center, r, r * flat, col, px, 1)
		else:
			_draw_ellipse_outline(center, r, r * flat, col, float(sw["width"]) * alpha)


func _draw_particles(shake: Vector2) -> void:
	_draw_particles_on(self, shake, 3.0)


func _draw_particles_on(canvas: CanvasItem, shake: Vector2, px: float) -> void:
	for p: Dictionary in _particles:
		var ratio := clampf(float(p["life"]) / float(p["max_life"]), 0.0, 1.0)
		var pos: Vector2 = (p["pos"] as Vector2) + shake
		var vel: Vector2 = p["vel"]
		var sz: float = p["size"]
		var col: Color = p["color"]
		var kind: String = p.get("kind", "ember")

		if kind == "spark":
			var tail := pos - vel.normalized() * clampf(vel.length() * 0.045, 5.0, 18.0)
			canvas.draw_line(tail, pos, Color(col.r, col.g, col.b, ratio), maxf(2.0, sz * 0.65))
			var core: Color = p.get("core", Color.WHITE)
			core.a = ratio
			canvas.draw_rect(Rect2(pos - Vector2(sz * 0.4, sz * 0.4), Vector2(sz * 0.8, sz * 0.8)), core)
		elif kind == "pixel_steam":
			# Cụm mây hơi nước pixel art 32-bit 2 lớp (bước lưới px, không hình chữ nhật thô)
			var expand := 1.0 + (1.0 - ratio) * 0.85
			var s_x := snappedf(pos.x, px)
			var s_y := snappedf(pos.y, px)
			var bw := snappedf(sz * expand, px)
			var bh := snappedf(sz * expand * 0.72, px)
			var outer_col := Color(col.r, col.g, col.b, ratio * 0.48)
			var inner_col := Color(0.98, 0.99, 1.0, ratio * 0.68)
			canvas.draw_rect(Rect2(Vector2(s_x - bw * 0.5, s_y - bh * 0.5), Vector2(bw, bh)), outer_col)
			canvas.draw_rect(
				Rect2(Vector2(s_x - bw * 0.3, s_y - bh * 0.8), Vector2(bw * 0.6, bh * 0.55)),
				inner_col
			)
		elif kind == "glint":
			# Sao lấp lánh 4 cánh vẽ bằng khối pixel px×px (0% vector line)
			var gx := snappedf(pos.x, px)
			var gy := snappedf(pos.y, px)
			var arm := px * (2.0 if ratio > 0.45 else 1.0)
			var gc := Color(col.r, col.g, col.b, ratio)
			var core_c := Color(1.0, 0.99, 0.90, ratio)
			canvas.draw_rect(Rect2(Vector2(gx - arm, gy), Vector2(arm * 2.0 + px, px)), gc)
			canvas.draw_rect(Rect2(Vector2(gx, gy - arm), Vector2(px, arm * 2.0 + px)), gc)
			canvas.draw_rect(Rect2(Vector2(gx, gy), Vector2(px, px)), core_c)
		elif kind == "droplet":
			var dx := snappedf(pos.x, px)
			var dy := snappedf(pos.y, px)
			var ds := maxf(px, snappedf(sz, px))
			col.a *= ratio
			canvas.draw_rect(Rect2(Vector2(dx, dy), Vector2(ds, ds)), col)
			canvas.draw_rect(
				Rect2(Vector2(dx, dy), Vector2(px, px)),
				Color(0.96, 0.99, 1.0, ratio * 0.85)
			)
		elif kind == "steam" or kind == "smoke":
			var cur_sz := sz * (1.45 - ratio * 0.45)
			col.a *= ratio * 0.78
			canvas.draw_rect(Rect2(pos - Vector2(cur_sz * 0.5, cur_sz * 0.5), Vector2(cur_sz, cur_sz)), col)
		elif kind == "wind":
			var wind_tail := pos - vel.normalized() * clampf(vel.length() * 0.055, 8.0, 26.0)
			canvas.draw_line(wind_tail, pos, Color(col.r, col.g, col.b, ratio * 0.55), maxf(1.5, sz * 0.35))
		else:
			col.a *= ratio
			var ex := snappedf(pos.x, px)
			var ey := snappedf(pos.y, px)
			canvas.draw_rect(Rect2(Vector2(ex, ey), Vector2(maxf(px, sz), maxf(px, sz))), col)


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
