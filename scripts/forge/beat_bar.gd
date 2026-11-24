class_name BeatBar
extends Control

# Thanh nhịp Rèn Búa Phase 2 vẽ bằng _draw(): khung kim loại rèn 2 lớp,
# 4 chốt đinh tán đồng, sóng nhịp sáng vùng PERFECT và kim chỉ 2 đầu nhọn.

const COLOR_BG             := Color(0.05, 0.035, 0.025, 0.96)
const COLOR_FRAME_OUTER    := Color(0.14, 0.09, 0.06, 0.98)
const COLOR_BORDER         := Color(0.68, 0.48, 0.20, 0.95)
const COLOR_RIVET_DARK     := Color(0.18, 0.10, 0.05)
const COLOR_RIVET_FILL     := Color(0.76, 0.52, 0.22)
const COLOR_RIVET_HI       := Color(1.00, 0.86, 0.56)
const COLOR_GOOD           := Color(0.76, 0.42, 0.08, 0.80)
const COLOR_GOOD_BORDER    := Color(0.95, 0.62, 0.18, 0.92)
const COLOR_PERFECT        := Color(0.98, 0.84, 0.18, 0.96)
const COLOR_PERFECT_CENTER := Color(1.0, 0.98, 0.76, 0.98)
const COLOR_TICK           := Color(1.0, 1.0, 1.0, 0.10)
const COLOR_INDICATOR      := Color(1.0, 0.98, 0.92, 0.98)
const COLOR_NEEDLE_EDGE    := Color(0.10, 0.05, 0.02, 0.96)

var progress: float = 0.0:
	set(v):
		progress = clampf(v, 0.0, 1.0)
		queue_redraw()

var perfect_center: float = 0.55
var perfect_half: float = 0.08
var good_half: float = 0.18

var _flash_alpha: float = 0.0
var _flash_color: Color = COLOR_PERFECT
var _anim_time: float = 0.0


func set_zones(center: float, p_good_half: float, p_perfect_half: float) -> void:
	perfect_center = clampf(center, 0.1, 0.9)
	good_half = p_good_half
	perfect_half = p_perfect_half
	queue_redraw()


func flash_result(color: Color) -> void:
	_flash_color = color
	_flash_alpha = 0.55
	queue_redraw()


func _process(delta: float) -> void:
	_anim_time += delta
	if _flash_alpha > 0.0:
		_flash_alpha = maxf(0.0, _flash_alpha - delta * 2.4)
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return

	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, COLOR_BG)

	# Vạch thước chia nền
	for pct: float in [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]:
		draw_line(Vector2(w * pct, 3.0), Vector2(w * pct, h - 3.0), COLOR_TICK, 1.0)

	# Vùng GOOD (cam đồng)
	var gs := clampf(perfect_center - good_half, 0.0, 1.0) * w
	var ge := clampf(perfect_center + good_half, 0.0, 1.0) * w
	var good_rect := Rect2(Vector2(gs, 5.0), Vector2(ge - gs, h - 10.0))
	draw_rect(good_rect, COLOR_GOOD)
	draw_rect(good_rect, COLOR_GOOD_BORDER, false, 2.0)

	# Vùng PERFECT (vàng kim rực + sóng nhịp sáng + vạch tâm)
	var ps := clampf(perfect_center - perfect_half, 0.0, 1.0) * w
	var pe := clampf(perfect_center + perfect_half, 0.0, 1.0) * w
	var perf_w := pe - ps
	var perf_rect := Rect2(Vector2(ps, 3.0), Vector2(perf_w, h - 6.0))
	draw_rect(perf_rect, COLOR_PERFECT)

	# Sóng nhịp sáng lan tỏa từ tâm PERFECT
	var pulse := 0.5 + sin(_anim_time * 7.5) * 0.5
	var wave_frac := fmod(_anim_time * 1.4, 1.0)
	var wave_half := perf_w * 0.5 * wave_frac
	var cx := perfect_center * w
	draw_rect(
		Rect2(Vector2(ps, 3.0), Vector2(perf_w, (h - 6.0) * 0.34)),
		Color(1.0, 1.0, 1.0, 0.20 + pulse * 0.14)
	)
	draw_rect(
		Rect2(Vector2(cx - wave_half, 4.0), Vector2(wave_half * 2.0, h - 8.0)),
		Color(1.0, 0.98, 0.78, (1.0 - wave_frac) * 0.28)
	)
	draw_line(Vector2(cx, 2.0), Vector2(cx, h - 2.0), COLOR_PERFECT_CENTER, 2.0)

	# Vệt sáng đuôi sau kim chạy
	var ix := progress * w
	var trail_w := minf(42.0, ix)
	if trail_w > 1.0:
		for step in range(3):
			var seg_w := trail_w / 3.0
			var sx := ix - trail_w + seg_w * step
			var seg_a := 0.08 + step * 0.09
			draw_rect(
				Rect2(Vector2(sx, 7.0), Vector2(seg_w + 1.0, h - 14.0)),
				Color(1.0, 0.94, 0.72, seg_a)
			)

	if _flash_alpha > 0.01:
		draw_rect(
			bounds,
			Color(_flash_color.r, _flash_color.g, _flash_color.b, _flash_alpha)
		)

	_draw_forged_frame(w, h)
	_draw_beat_indicator(ix, h)


func _draw_forged_frame(w: float, h: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), COLOR_FRAME_OUTER, false, 4.0)
	draw_rect(Rect2(Vector2(3.0, 3.0), Vector2(w - 6.0, h - 6.0)), COLOR_BORDER, false, 2.0)

	# 4 chốt đinh tán đồng ở 4 góc khung
	var inset := 8.0
	var corners: Array[Vector2] = [
		Vector2(inset, inset),
		Vector2(w - inset, inset),
		Vector2(inset, h - inset),
		Vector2(w - inset, h - inset),
	]
	for pos: Vector2 in corners:
		draw_circle(pos, 4.2, COLOR_RIVET_DARK)
		draw_circle(pos, 3.0, COLOR_RIVET_FILL)
		draw_rect(Rect2(pos - Vector2(1.5, 1.5), Vector2(1.8, 1.8)), COLOR_RIVET_HI)


func _draw_beat_indicator(ix: float, h: float) -> void:
	# Thân kim sắc nét
	draw_rect(Rect2(Vector2(ix - 3.5, -2.0), Vector2(7.0, h + 4.0)), COLOR_NEEDLE_EDGE)
	draw_rect(Rect2(Vector2(ix - 2.0, -1.0), Vector2(4.0, h + 2.0)), COLOR_INDICATOR)

	# Mũi nhọn tam giác trên-dưới
	var top_outer := PackedVector2Array([
		Vector2(ix - 8.5, -8.0),
		Vector2(ix + 8.5, -8.0),
		Vector2(ix, 4.0),
	])
	var top_inner := PackedVector2Array([
		Vector2(ix - 5.5, -6.5),
		Vector2(ix + 5.5, -6.5),
		Vector2(ix, 1.5),
	])
	var bot_outer := PackedVector2Array([
		Vector2(ix - 8.5, h + 8.0),
		Vector2(ix + 8.5, h + 8.0),
		Vector2(ix, h - 4.0),
	])
	var bot_inner := PackedVector2Array([
		Vector2(ix - 5.5, h + 6.5),
		Vector2(ix + 5.5, h + 6.5),
		Vector2(ix, h - 1.5),
	])
	draw_colored_polygon(top_outer, COLOR_NEEDLE_EDGE)
	draw_colored_polygon(top_inner, COLOR_INDICATOR)
	draw_colored_polygon(bot_outer, COLOR_NEEDLE_EDGE)
	draw_colored_polygon(bot_inner, COLOR_INDICATOR)
