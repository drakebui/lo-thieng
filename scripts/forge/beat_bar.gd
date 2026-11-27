class_name BeatBar
extends Control

# Thanh nhịp Rèn Búa Phase 2 chuẩn 32-bit Hoả Tâm Pixel Art (0% mixel, 0% vector gradient):
# - Khung 9-slice thép rèn tai đồng đinh tán (forge_heat_frame_9s.png)
# - Lòng thanh vẽ trên lưới pixel cứng 3x3: nền thép tối, vùng GOOD đồng cam,
#   vùng PERFECT vàng rực có sóng sáng pixel nhảy bước 10 FPS & chốt tâm đồng
# - Con trỏ đập búa thép sáng & đồng vàng nạm ngọc lam (forge_beat_cursor.png)

const _TEX_FRAME_PATH := "res://assets/pixel/ui/forge/forge_heat_frame_9s.png"
const _TEX_CURSOR_PATH := "res://assets/pixel/ui/forge/forge_beat_cursor.png"
const _TEX_DIVIDER_PATH := "res://assets/pixel/ui/forge/forge_heat_divider.png"

const PX := 3.0
const FRAME_INSET_X := 30.0
const FRAME_INSET_Y := 12.0

const COL_OUTLINE    := Color(0.071, 0.047, 0.063, 1.0)  # #120C10
const COL_BG_DARK    := Color(0.095, 0.068, 0.088, 1.0)
const COL_BG_MID     := Color(0.135, 0.102, 0.128, 1.0)
const COL_TICK       := Color(0.280, 0.225, 0.255, 1.0)

const COL_GOOD_DARK  := Color(0.420, 0.175, 0.085, 1.0)
const COL_GOOD_MID   := Color(0.710, 0.320, 0.110, 1.0)
const COL_GOOD_HI    := Color(0.880, 0.480, 0.155, 1.0)

const COL_PERF_DARK  := Color(0.880, 0.450, 0.110, 1.0)
const COL_PERF_MID   := Color(0.980, 0.720, 0.200, 1.0)
const COL_PERF_HI    := Color(1.000, 0.900, 0.450, 1.0)
const COL_PERF_CORE  := Color(1.000, 0.965, 0.840, 1.0)

var progress: float = 0.0:
	set(v):
		progress = clampf(v, 0.0, 1.0)
		queue_redraw()

var perfect_center: float = 0.55
var perfect_half: float = 0.08
var good_half: float = 0.18

var _flash_alpha: float = 0.0
var _flash_color: Color = COL_PERF_HI
var _anim_time: float = 0.0
var _frame_style: StyleBoxTexture
var _cursor_tex: Texture2D
var _divider_tex: Texture2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_pixel_assets()


func _load_pixel_assets() -> void:
	if _frame_style == null and ResourceLoader.exists(_TEX_FRAME_PATH):
		var frame_tex := load(_TEX_FRAME_PATH) as Texture2D
		if frame_tex != null:
			_frame_style = StyleBoxTexture.new()
			_frame_style.texture = frame_tex
			_frame_style.texture_margin_left = 36.0
			_frame_style.texture_margin_right = 36.0
			_frame_style.texture_margin_top = 15.0
			_frame_style.texture_margin_bottom = 15.0
			_frame_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
			_frame_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	if _cursor_tex == null and ResourceLoader.exists(_TEX_CURSOR_PATH):
		_cursor_tex = load(_TEX_CURSOR_PATH) as Texture2D
	if _divider_tex == null and ResourceLoader.exists(_TEX_DIVIDER_PATH):
		_divider_tex = load(_TEX_DIVIDER_PATH) as Texture2D


func set_zones(center: float, p_good_half: float, p_perfect_half: float) -> void:
	perfect_center = clampf(center, 0.1, 0.9)
	good_half = p_good_half
	perfect_half = p_perfect_half
	queue_redraw()


func flash_result(color: Color) -> void:
	_flash_color = color
	_flash_alpha = 0.65
	queue_redraw()


func _process(delta: float) -> void:
	_anim_time += delta
	if _flash_alpha > 0.0:
		_flash_alpha = maxf(0.0, _flash_alpha - delta * 2.6)
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	if _frame_style == null:
		_load_pixel_assets()

	var inner := Rect2(
		Vector2(FRAME_INSET_X, FRAME_INSET_Y),
		Vector2(maxf(PX * 4.0, w - FRAME_INSET_X * 2.0), maxf(PX * 4.0, h - FRAME_INSET_Y * 2.0))
	)

	var anim_step: int = int(floor(_anim_time * 10.0))

	# 1. Nền thép tối & 2 vùng GOOD / PERFECT trên lưới pixel cứng 3x3
	_draw_pixel_track(inner, anim_step)

	# 2. Chốt tâm đích đồng rèn tại perfect_center
	_draw_center_marker(inner)

	# 3. Đuôi vệt sáng pixel rời rạc sau con trỏ chạy
	var ix: float = inner.position.x + snappedf(inner.size.x * progress, PX)
	_draw_pixel_trail(inner, ix)

	# 4. Chớp phản hồi khi đập búa (giới hạn trong lòng thanh, không đè khung)
	if _flash_alpha > 0.02:
		draw_rect(
			inner,
			Color(_flash_color.r, _flash_color.g, _flash_color.b, _flash_alpha * 0.55)
		)

	# 5. Khung 9-slice thép rèn & tai đồng đinh tán 32-bit
	_draw_pixel_frame(w, h)

	# 6. Con trỏ đập búa 32-bit
	_draw_pixel_cursor(inner, ix, h)


func _draw_pixel_track(inner: Rect2, anim_step: int) -> void:
	var cols: int = maxi(1, int(floor(inner.size.x / PX)))
	var rows: int = maxi(1, int(floor(inner.size.y / PX)))

	var gs_col: int = int(round(clampf(perfect_center - good_half, 0.0, 1.0) * float(cols)))
	var ge_col: int = int(round(clampf(perfect_center + good_half, 0.0, 1.0) * float(cols)))
	var ps_col: int = int(round(clampf(perfect_center - perfect_half, 0.0, 1.0) * float(cols)))
	var pe_col: int = int(round(clampf(perfect_center + perfect_half, 0.0, 1.0) * float(cols)))
	var pc_col: int = int(round(perfect_center * float(cols)))
	var perf_half_cols: int = maxi(1, (pe_col - ps_col) / 2)
	var wave_dist: int = anim_step % maxi(2, perf_half_cols + 1)

	for gx in range(cols):
		var px_x: float = inner.position.x + float(gx) * PX
		var cell_w: float = minf(PX, inner.end.x - px_x)
		if cell_w <= 0.0:
			continue
		var in_perf := (gx >= ps_col and gx < pe_col)
		var in_good := (gx >= gs_col and gx < ge_col)
		var is_tick := (gx > 0 and (gx % maxi(8, cols / 10)) == 0)

		for gy in range(rows):
			var px_y: float = inner.position.y + float(gy) * PX
			var cell_h: float = minf(PX, inner.end.y - px_y)
			if cell_h <= 0.0:
				continue

			var col: Color
			if in_perf:
				col = _sample_perfect_pixel(gx, gy, rows, pc_col, wave_dist, anim_step)
			elif in_good:
				col = _sample_good_pixel(gx, gy, rows, gs_col, ge_col)
			else:
				col = _sample_bg_pixel(gx, gy, rows, is_tick)
			draw_rect(Rect2(Vector2(px_x, px_y), Vector2(cell_w, cell_h)), col)


func _sample_bg_pixel(gx: int, gy: int, rows: int, is_tick: bool) -> Color:
	if is_tick and gy >= 1 and gy <= rows - 2:
		return COL_TICK
	if gy == 0 or gy >= rows - 1:
		return COL_OUTLINE
	return COL_BG_MID if ((gx + gy) % 3) == 0 else COL_BG_DARK


func _sample_good_pixel(gx: int, gy: int, rows: int, gs_col: int, ge_col: int) -> Color:
	if gx == gs_col or gx == ge_col - 1:
		return COL_OUTLINE
	if gy == 0:
		return COL_GOOD_HI
	if gy >= rows - 1:
		return COL_GOOD_DARK
	var checker := ((gx + gy) % 2) == 0
	if gy == 1:
		return COL_GOOD_HI if checker else COL_GOOD_MID
	if gy == rows - 2:
		return COL_GOOD_DARK if checker else COL_GOOD_MID
	return COL_GOOD_MID


func _sample_perfect_pixel(
	gx: int,
	gy: int,
	rows: int,
	pc_col: int,
	wave_dist: int,
	anim_step: int
) -> Color:
	var dist_center := absi(gx - pc_col)
	if gy == 0:
		return COL_PERF_CORE if ((gx + anim_step) % 3 == 0) else COL_PERF_HI
	if gy >= rows - 1:
		return COL_PERF_DARK
	if dist_center == wave_dist or dist_center == 0:
		return COL_PERF_CORE
	if gy == 1 or ((gx + gy + anim_step) % 5) == 0:
		return COL_PERF_HI
	if gy == rows - 2:
		return COL_PERF_DARK if ((gx + gy) % 2 == 0) else COL_PERF_MID
	return COL_PERF_MID


func _draw_center_marker(inner: Rect2) -> void:
	var cx: float = inner.position.x + snappedf(inner.size.x * perfect_center, PX)
	if _divider_tex != null:
		var dw: float = float(_divider_tex.get_width())
		var dh: float = inner.size.y + 6.0
		var rect := Rect2(Vector2(cx - dw * 0.5, inner.position.y - 3.0), Vector2(dw, dh))
		draw_texture_rect(_divider_tex, rect, false, Color(1.0, 0.96, 0.72, 1.0))
	else:
		draw_rect(Rect2(Vector2(cx - PX * 0.5, inner.position.y), Vector2(PX, inner.size.y)), COL_PERF_CORE)


func _draw_pixel_trail(inner: Rect2, ix: float) -> void:
	var steps := 4
	for i in range(steps):
		var col_x: float = ix - float(steps - i) * PX * 2.0
		if col_x < inner.position.x:
			continue
		var alpha := 0.10 + float(i) * 0.09
		draw_rect(
			Rect2(Vector2(col_x, inner.position.y + PX), Vector2(PX * 2.0, inner.size.y - PX * 2.0)),
			Color(1.0, 0.95, 0.75, alpha)
		)


func _draw_pixel_frame(w: float, h: float) -> void:
	var frame_rect := Rect2(Vector2.ZERO, Vector2(w, h))
	if _frame_style != null:
		if _flash_alpha > 0.05:
			_frame_style.modulate_color = Color.WHITE.lerp(_flash_color.lightened(0.25), _flash_alpha)
		else:
			_frame_style.modulate_color = Color.WHITE
		draw_style_box(_frame_style, frame_rect)
	else:
		draw_rect(frame_rect, COL_OUTLINE, false, PX)


func _draw_pixel_cursor(inner: Rect2, ix: float, h: float) -> void:
	var cx: float = clampf(ix, inner.position.x, inner.end.x)
	if _cursor_tex != null:
		var cw: float = float(_cursor_tex.get_width())
		var ch: float = h + 24.0
		var crect := Rect2(Vector2(cx - cw * 0.5, -12.0), Vector2(cw, ch))
		draw_texture_rect(_cursor_tex, crect, false)
	else:
		draw_rect(Rect2(Vector2(cx - PX, -6.0), Vector2(PX * 2.0, h + 12.0)), COL_OUTLINE)
		draw_rect(Rect2(Vector2(cx - PX * 0.5, -3.0), Vector2(PX, h + 6.0)), COL_PERF_CORE)
