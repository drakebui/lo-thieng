class_name HeatBar
extends Control

# Thanh nhiệt Phase 1 vẽ bằng _draw(): khung kim loại rèn 2 lớp,
# 4 chốt đinh tán đồng, sóng nhiệt vùng đỉnh và kim chỉ 2 đầu nhọn.

const COLOR_BG           := Color(0.024, 0.016, 0.008)
const COLOR_BORDER_IDLE  := Color(0.46, 0.31, 0.14, 0.95)
const COLOR_FRAME_OUTER  := Color(0.14, 0.09, 0.06, 0.98)
const COLOR_RIVET_DARK   := Color(0.18, 0.10, 0.05)
const COLOR_RIVET_FILL   := Color(0.76, 0.52, 0.22)
const COLOR_RIVET_HI     := Color(1.00, 0.86, 0.56)
const COLOR_COLD_START   := Color(0.10, 0.20, 0.45)
const COLOR_COLD_END     := Color(0.18, 0.48, 0.72)
const COLOR_CAM_START    := Color(0.35, 0.12, 0.00)
const COLOR_CAM_END      := Color(0.85, 0.45, 0.08)
const COLOR_DORUC_START  := Color(0.72, 0.18, 0.00)
const COLOR_DORUC_END    := Color(1.00, 0.78, 0.05)
const COLOR_CHAY_START   := Color(0.22, 0.09, 0.02)
const COLOR_CHAY_END     := Color(0.08, 0.03, 0.01)
const COLOR_TICK         := Color(1.0, 1.0, 1.0, 0.12)
const COLOR_CAM_MARK     := Color(0.95, 0.86, 0.20, 0.78)
const COLOR_PEAK_MARK    := Color(1.00, 0.48, 0.06, 0.88)
const COLOR_BURN_MARK    := Color(0.85, 0.12, 0.06, 0.82)
const COLOR_SHEEN        := Color(1.0, 1.0, 1.0, 0.10)
const COLOR_DANGER_FLASH := Color(1.0, 0.12, 0.08, 0.22)
const COLOR_INDICATOR    := Color(1.0, 0.98, 0.90, 0.98)
const COLOR_NEEDLE_EDGE  := Color(0.10, 0.05, 0.02, 0.96)

@export var heat_percent: float = 0.0:
	set(value):
		heat_percent = clampf(value, 0.0, 1.0)
		queue_redraw()

var sweet_min: float = 0.60   # Cam bắt đầu
var peak_frac: float = 0.80   # Đỏ Rực bắt đầu
var burn_frac: float = 0.92   # Cháy bắt đầu

var _danger_flash: float = 0.0
var _anim_time: float = 0.0


func set_thresholds(new_sweet_min: float, new_peak_frac: float, new_burn_frac: float) -> void:
	sweet_min = clampf(new_sweet_min, 0.0, 1.0)
	peak_frac = clampf(new_peak_frac, sweet_min, 1.0)
	burn_frac = clampf(new_burn_frac, peak_frac, 1.0)
	queue_redraw()


func tick_animation(delta: float) -> void:
	_anim_time += delta
	if is_overheated():
		_danger_flash = sin(Time.get_ticks_msec() * 0.015) * 0.5 + 0.5
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
	_draw_forged_frame(width, height)
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
	for i in range(steps):
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
		var tick_w: float = 1.0
		if is_equal_approx(pct, sweet_min):
			tick_color = COLOR_CAM_MARK
			tick_w = 2.0
		elif is_equal_approx(pct, peak_frac):
			tick_color = COLOR_PEAK_MARK
			tick_w = 2.0
		elif is_equal_approx(pct, burn_frac):
			tick_color = COLOR_BURN_MARK
			tick_w = 2.0
		draw_line(Vector2(x, 0.0), Vector2(x, height), tick_color, tick_w)

	# Vùng Cam — sáng dịu
	draw_rect(
		Rect2(Vector2(width * sweet_min, 0.0), Vector2(width * (peak_frac - sweet_min), height)),
		Color(COLOR_CAM_MARK.r, COLOR_CAM_MARK.g, COLOR_CAM_MARK.b, 0.08)
	)

	# Vùng Đỏ Rực — hiệu ứng sóng nhiệt nhấp nháy & vệt quét sáng
	var peak_x: float = width * peak_frac
	var peak_w: float = width * (burn_frac - peak_frac)
	if peak_w > 1.0:
		var pulse: float = 0.5 + sin(_anim_time * 6.5) * 0.5
		draw_rect(
			Rect2(Vector2(peak_x, 0.0), Vector2(peak_w, height)),
			Color(1.0, 0.78, 0.22, 0.12 + pulse * 0.14)
		)
		var wave_frac: float = fmod(_anim_time * 1.15, 1.0)
		var band_w: float = maxf(6.0, peak_w * 0.24)
		var band_x: float = peak_x + wave_frac * maxf(0.0, peak_w - band_w)
		draw_rect(
			Rect2(Vector2(band_x, 2.0), Vector2(band_w, height - 4.0)),
			Color(1.0, 0.96, 0.65, 0.24)
		)


func _draw_fill_overlay(width: float, height: float) -> void:
	if heat_percent <= 0.001:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.48))
		return

	var fill_width: float = width * heat_percent
	if fill_width < width:
		draw_rect(
			Rect2(Vector2(fill_width, 0.0), Vector2(width - fill_width, height)),
			Color(0.0, 0.0, 0.0, 0.54)
		)
	draw_rect(Rect2(Vector2.ZERO, Vector2(fill_width, height * 0.32)), COLOR_SHEEN)


func _draw_forged_frame(width: float, height: float) -> void:
	var outer_rect := Rect2(Vector2.ZERO, Vector2(width, height))
	var inner_rect := Rect2(Vector2(3.0, 3.0), Vector2(width - 6.0, height - 6.0))
	draw_rect(outer_rect, COLOR_FRAME_OUTER, false, 4.0)
	draw_rect(inner_rect, _get_border_color(), false, 2.0)

	# 4 chốt đinh tán đồng ở 4 góc khung
	var inset := 8.0
	var corners: Array[Vector2] = [
		Vector2(inset, inset),
		Vector2(width - inset, inset),
		Vector2(inset, height - inset),
		Vector2(width - inset, height - inset),
	]
	for pos: Vector2 in corners:
		draw_circle(pos, 4.2, COLOR_RIVET_DARK)
		draw_circle(pos, 3.0, COLOR_RIVET_FILL)
		draw_rect(Rect2(pos - Vector2(1.5, 1.5), Vector2(1.8, 1.8)), COLOR_RIVET_HI)


func _draw_heat_indicator(width: float, height: float) -> void:
	var x: float = clampf(width * heat_percent, 0.0, width)
	# Thân kim sắc nét có viền tối tương phản
	draw_rect(Rect2(Vector2(x - 3.5, -2.0), Vector2(7.0, height + 4.0)), COLOR_NEEDLE_EDGE)
	draw_rect(Rect2(Vector2(x - 2.0, -1.0), Vector2(4.0, height + 2.0)), COLOR_INDICATOR)

	# Mũi nhọn tam giác trên-dưới
	var top_outer := PackedVector2Array([
		Vector2(x - 8.5, -8.0),
		Vector2(x + 8.5, -8.0),
		Vector2(x, 4.0),
	])
	var top_inner := PackedVector2Array([
		Vector2(x - 5.5, -6.5),
		Vector2(x + 5.5, -6.5),
		Vector2(x, 1.5),
	])
	var bot_outer := PackedVector2Array([
		Vector2(x - 8.5, height + 8.0),
		Vector2(x + 8.5, height + 8.0),
		Vector2(x, height - 4.0),
	])
	var bot_inner := PackedVector2Array([
		Vector2(x - 5.5, height + 6.5),
		Vector2(x + 5.5, height + 6.5),
		Vector2(x, height - 1.5),
	])
	draw_colored_polygon(top_outer, COLOR_NEEDLE_EDGE)
	draw_colored_polygon(top_inner, COLOR_INDICATOR)
	draw_colored_polygon(bot_outer, COLOR_NEEDLE_EDGE)
	draw_colored_polygon(bot_inner, COLOR_INDICATOR)


func _get_border_color() -> Color:
	if is_overheated():
		return Color(0.95, 0.18, 0.12, 0.96)
	if is_at_peak():
		return Color(1.00, 0.56, 0.08, 0.96)
	if is_in_sweet_spot():
		return Color(0.92, 0.72, 0.20, 0.94)
	if heat_percent >= 0.30:
		return Color(0.78, 0.44, 0.12, 0.88)
	return COLOR_BORDER_IDLE
