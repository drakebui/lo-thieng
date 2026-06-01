class_name HeatBar
extends Control

# Thanh nhiệt Phase 1, vẽ toàn bộ bằng _draw để dễ đổi mốc theo rarity.

const COLOR_BG          := Color(0.024, 0.016, 0.008)
const COLOR_BORDER_IDLE := Color(0.23, 0.14, 0.05)
const COLOR_COLD_START  := Color(0.10, 0.20, 0.45)
const COLOR_COLD_END    := Color(0.18, 0.48, 0.72)
const COLOR_CAM_START   := Color(0.35, 0.12, 0.00)
const COLOR_CAM_END     := Color(0.85, 0.45, 0.08)
const COLOR_DORUC_START := Color(0.72, 0.18, 0.00)
const COLOR_DORUC_END   := Color(1.00, 0.78, 0.05)
const COLOR_CHAY_START  := Color(0.22, 0.09, 0.02)
const COLOR_CHAY_END    := Color(0.08, 0.03, 0.01)
const COLOR_TICK        := Color(1.0, 1.0, 1.0, 0.10)
const COLOR_CAM_MARK    := Color(0.95, 0.86, 0.20, 0.72)
const COLOR_PEAK_MARK   := Color(1.00, 0.45, 0.05, 0.80)
const COLOR_BURN_MARK   := Color(0.80, 0.10, 0.05, 0.72)
const COLOR_SHEEN       := Color(1.0, 1.0, 1.0, 0.08)
const COLOR_DANGER_FLASH := Color(1.0, 0.12, 0.08, 0.18)
const COLOR_INDICATOR   := Color(1.0, 1.0, 1.0, 0.95)

@export var heat_percent: float = 0.0:
	set(value):
		heat_percent = clampf(value, 0.0, 1.0)
		queue_redraw()

var sweet_min: float = 0.60   # Cam bắt đầu
var peak_frac: float = 0.80   # Đỏ Rực bắt đầu
var burn_frac: float = 0.92   # Cháy bắt đầu

var _danger_flash: float = 0.0
var _fail_flash_time: float = 0.0


func set_thresholds(new_sweet_min: float, new_peak_frac: float, new_burn_frac: float) -> void:
	sweet_min = clampf(new_sweet_min, 0.0, 1.0)
	peak_frac = clampf(new_peak_frac, sweet_min, 1.0)
	burn_frac = clampf(new_burn_frac, peak_frac, 1.0)
	queue_redraw()


func tick_animation(delta: float) -> void:
	if is_overheated():
		_danger_flash = sin(Time.get_ticks_msec() * 0.015) * 0.5 + 0.5
		queue_redraw()
	if _fail_flash_time > 0.0:
		_fail_flash_time -= delta
		if _fail_flash_time < 0.0:
			_fail_flash_time = 0.0
		queue_redraw()


func start_fail_flash() -> void:
	_fail_flash_time = 0.5
	queue_redraw()


func get_zone_name() -> String:
	if heat_percent < sweet_min:
		return "LẠNH"
	if heat_percent < peak_frac:
		return "CAM"
	if heat_percent < burn_frac:
		return "ĐỎ RỰC"
	return "CHÁY THÉP"


func is_in_sweet_spot() -> bool:
	return heat_percent >= sweet_min and heat_percent < burn_frac


func is_at_peak() -> bool:
	return heat_percent >= peak_frac and heat_percent < burn_frac


func is_overheated() -> bool:
	return heat_percent >= burn_frac


func _draw() -> void:
	var width: float = size.x
	var height: float = size.y
	if width <= 0.0 or height <= 0.0:
		return

	var bounds: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(bounds, COLOR_BG)

	_draw_zone(0.0,       sweet_min, COLOR_COLD_START,  COLOR_COLD_END)
	_draw_zone(sweet_min, peak_frac, COLOR_CAM_START,   COLOR_CAM_END)
	_draw_zone(peak_frac, burn_frac, COLOR_DORUC_START, COLOR_DORUC_END)
	_draw_zone(burn_frac, 1.0,       COLOR_CHAY_START,  COLOR_CHAY_END)

	_draw_sweet_marks(width, height)
	_draw_fill_overlay(width, height)
	_draw_heat_indicator(width, height)

	if is_overheated():
		draw_rect(
			bounds,
			Color(
				COLOR_DANGER_FLASH.r,
				COLOR_DANGER_FLASH.g,
				COLOR_DANGER_FLASH.b,
				COLOR_DANGER_FLASH.a * _danger_flash
			)
		)

	if _fail_flash_time > 0.0:
		var fft: float = clampf(_fail_flash_time / 0.5, 0.0, 1.0)
		draw_rect(bounds, Color(1.0, 0.05, 0.05, 0.6 * fft))

	draw_rect(bounds, _get_border_color(), false, 1.5)


func _draw_zone(
	start_pct: float,
	end_pct: float,
	start_color: Color,
	end_color: Color
) -> void:
	if end_pct <= start_pct:
		return

	var width: float = size.x
	var height: float = size.y
	var steps: int = max(1, int((end_pct - start_pct) * 32.0))
	var zone_width: float = width * (end_pct - start_pct)
	for i in steps:
		var t0: float = float(i) / float(steps)
		var t1: float = float(i + 1) / float(steps)
		var x0: float = width * start_pct + zone_width * t0
		var x1: float = width * start_pct + zone_width * t1
		var col: Color = start_color.lerp(end_color, t0)
		draw_rect(Rect2(Vector2(x0, 0.0), Vector2(x1 - x0 + 1.0, height)), col)


func _draw_sweet_marks(width: float, height: float) -> void:
	var tick_positions: Array[float] = [0.25, 0.50, sweet_min, peak_frac, burn_frac]
	for pct: float in tick_positions:
		var x: float = width * pct
		var tick_color: Color = COLOR_TICK
		if is_equal_approx(pct, sweet_min):
			tick_color = COLOR_CAM_MARK
		elif is_equal_approx(pct, peak_frac):
			tick_color = COLOR_PEAK_MARK
		elif is_equal_approx(pct, burn_frac):
			tick_color = COLOR_BURN_MARK
		draw_line(Vector2(x, 0.0), Vector2(x, height), tick_color, 1.0)

	# Cam zone — glow nhẹ
	draw_rect(
		Rect2(Vector2(width * sweet_min, 0.0), Vector2(width * (peak_frac - sweet_min), height)),
		Color(COLOR_CAM_MARK.r, COLOR_CAM_MARK.g, COLOR_CAM_MARK.b, 0.06)
	)
	# Đỏ Rực zone — glow mạnh hơn để người chơi thấy đây là peak
	draw_rect(
		Rect2(Vector2(width * peak_frac, 0.0), Vector2(width * (burn_frac - peak_frac), height)),
		Color(COLOR_PEAK_MARK.r, COLOR_PEAK_MARK.g, COLOR_PEAK_MARK.b, 0.10)
	)


func _draw_fill_overlay(width: float, height: float) -> void:
	if heat_percent <= 0.001:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.48))
		return

	var fill_width: float = width * heat_percent
	if fill_width < width:
		draw_rect(
			Rect2(Vector2(fill_width, 0.0), Vector2(width - fill_width, height)),
			Color(0.0, 0.0, 0.0, 0.25)
		)
	draw_rect(Rect2(Vector2.ZERO, Vector2(fill_width, height * 0.35)), COLOR_SHEEN)


func _draw_heat_indicator(width: float, height: float) -> void:
	var x: float = clampf(width * heat_percent, 0.0, width)
	draw_line(Vector2(x, -2.0), Vector2(x, height + 2.0), COLOR_INDICATOR, 4.0)


func _get_border_color() -> Color:
	if is_overheated():
		return Color(0.95, 0.15, 0.10, 0.90)
	if is_at_peak():
		return Color(1.00, 0.50, 0.05, 0.90)
	if is_in_sweet_spot():
		return Color(0.85, 0.68, 0.16, 0.85)
	if heat_percent >= 0.30:
		return Color(0.75, 0.38, 0.05, 0.70)
	return COLOR_BORDER_IDLE
