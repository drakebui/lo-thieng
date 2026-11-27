class_name HeatBar
extends Control

# Thanh nhiệt Phase 1 chuẩn 32-bit Hoả Tâm Pixel Art (0% mixel, 0% vector gradient):
# - Khung 9-slice thép rèn ốp tai đồng có đinh tán (forge_heat_frame_9s.png)
# - 4 vùng nhiệt dithered trên lưới pixel cứng 3x3 (Lạnh / Cam / Đỏ Rực / Cháy)
# - Chốt chia ngưỡng đồng rèn (forge_heat_divider.png)
# - Kim chỉ nhiệt 2 đầu mũi tên đồng nạm ngọc (forge_heat_needle.png)

const _TEX_FRAME_PATH := "res://assets/pixel/ui/forge/forge_heat_frame_9s.png"
const _TEX_NEEDLE_PATH := "res://assets/pixel/ui/forge/forge_heat_needle.png"
const _TEX_DIVIDER_PATH := "res://assets/pixel/ui/forge/forge_heat_divider.png"

const PX := 3.0  # 1 native pixel art = 3x3 screen pixel (khớp 640x360 -> 1920x1080)
const FRAME_INSET_X := 30.0  # 10 native px * 3 (tai đồng 2 bên)
const FRAME_INSET_Y := 12.0  # 4 native px * 3 (thanh thép trên/dưới)

# Bảng màu Hoả Tâm 32-bit cho 4 vùng nhiệt (không dùng smooth lerp vector)
const COL_OUTLINE := Color(0.071, 0.047, 0.063, 1.0)    # #120C10
const COL_UNFILLED := Color(0.065, 0.042, 0.048, 0.72)  # Lớp tối phủ phần nhiệt chưa đạt

# Vùng Lạnh (thép nguội)
const COL_COLD_DARK := Color(0.110, 0.165, 0.255)
const COL_COLD_MID  := Color(0.176, 0.275, 0.392)
const COL_COLD_HI   := Color(0.275, 0.420, 0.560)

# Vùng Cam (than hồng)
const COL_CAM_DARK := Color(0.455, 0.165, 0.090)
const COL_CAM_MID  := Color(0.760, 0.310, 0.110)
const COL_CAM_HI   := Color(0.910, 0.478, 0.141)

# Vùng Đỏ Rực ★ (lõi lửa vàng sáng)
const COL_PEAK_DARK := Color(0.860, 0.380, 0.100)
const COL_PEAK_MID  := Color(0.980, 0.675, 0.195)
const COL_PEAK_HI   := Color(1.000, 0.890, 0.440)
const COL_PEAK_CORE := Color(1.000, 0.960, 0.820)

# Vùng Cháy (than đen nứt đỏ báo động)
const COL_BURN_DARK := Color(0.130, 0.075, 0.090)
const COL_BURN_MID  := Color(0.380, 0.100, 0.110)
const COL_BURN_HI   := Color(0.820, 0.220, 0.160)

@export var heat_percent: float = 0.0:
	set(value):
		heat_percent = clampf(value, 0.0, 1.0)
		queue_redraw()

var sweet_min: float = 0.60   # Cam bắt đầu
var peak_frac: float = 0.80   # Đỏ Rực bắt đầu
var burn_frac: float = 0.92   # Cháy bắt đầu

var _anim_time: float = 0.0
var _frame_style: StyleBoxTexture
var _needle_tex: Texture2D
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
	if _needle_tex == null and ResourceLoader.exists(_TEX_NEEDLE_PATH):
		_needle_tex = load(_TEX_NEEDLE_PATH) as Texture2D
	if _divider_tex == null and ResourceLoader.exists(_TEX_DIVIDER_PATH):
		_divider_tex = load(_TEX_DIVIDER_PATH) as Texture2D


func set_thresholds(new_sweet_min: float, new_peak_frac: float, new_burn_frac: float) -> void:
	sweet_min = clampf(new_sweet_min, 0.0, 1.0)
	peak_frac = clampf(new_peak_frac, sweet_min, 1.0)
	burn_frac = clampf(new_burn_frac, peak_frac, 1.0)
	queue_redraw()


func tick_animation(delta: float) -> void:
	_anim_time += delta
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
	if _frame_style == null:
		_load_pixel_assets()

	var inner := Rect2(
		Vector2(FRAME_INSET_X, FRAME_INSET_Y),
		Vector2(maxf(PX * 4.0, width - FRAME_INSET_X * 2.0), maxf(PX * 4.0, height - FRAME_INSET_Y * 2.0))
	)

	# 1. Nền lòng ống tối màu mận đen
	draw_rect(inner, COL_OUTLINE)

	# 2. Vẽ 4 vùng nhiệt theo lưới pixel cứng 3x3 (dithered pixel art)
	var anim_step: int = int(floor(_anim_time * 8.0))
	_draw_pixel_zones(inner, anim_step)

	# 3. Phủ tối phần nhiệt chưa nung tới + vạch sáng đầu mức nhiệt (snap lưới 3px)
	_draw_heat_progress_mask(inner)

	# 4. Chốt chia ngưỡng đồng rèn 32-bit tại 3 mốc Cam / Đỏ Rực / Cháy
	_draw_threshold_dividers(inner)

	# 5. Khung 9-slice thép rèn & tai đồng đinh tán 32-bit
	_draw_pixel_frame(width, height, anim_step)

	# 6. Kim chỉ nhiệt đồng thau nạm ngọc 32-bit
	_draw_pixel_needle(inner, height)


func _draw_pixel_zones(inner: Rect2, anim_step: int) -> void:
	var cols: int = maxi(1, int(floor(inner.size.x / PX)))
	var rows: int = maxi(1, int(floor(inner.size.y / PX)))

	var cam_col: int = int(round(sweet_min * float(cols)))
	var peak_col: int = int(round(peak_frac * float(cols)))
	var burn_col: int = int(round(burn_frac * float(cols)))

	for gx in range(cols):
		var px_x: float = inner.position.x + float(gx) * PX
		var cell_w: float = minf(PX, inner.end.x - px_x)
		if cell_w <= 0.0:
			continue
		for gy in range(rows):
			var px_y: float = inner.position.y + float(gy) * PX
			var cell_h: float = minf(PX, inner.end.y - px_y)
			if cell_h <= 0.0:
				continue
			var col: Color = _sample_zone_pixel(
				gx, gy, rows, cam_col, peak_col, burn_col, anim_step
			)
			draw_rect(Rect2(Vector2(px_x, px_y), Vector2(cell_w, cell_h)), col)


func _sample_zone_pixel(
	gx: int,
	gy: int,
	rows: int,
	cam_col: int,
	peak_col: int,
	burn_col: int,
	anim_step: int
) -> Color:
	var is_top := (gy == 0)
	var is_sub_top := (gy == 1)
	var is_bot := (gy >= rows - 1)
	var is_sub_bot := (gy == rows - 2)
	var checker := ((gx + gy) % 2) == 0

	# Vùng 1: Lạnh (xanh thép nguội + dither chuyển sáng về phía Cam)
	if gx < cam_col:
		if is_bot:
			return COL_COLD_DARK
		if is_top:
			return COL_COLD_HI if (gx % 3 != 0) else COL_COLD_MID
		var near_cam := (cam_col - gx) <= 5
		if near_cam and checker:
			return COL_COLD_HI
		if is_sub_bot:
			return COL_COLD_DARK if checker else COL_COLD_MID
		return COL_COLD_MID

	# Vùng 2: Cam (than hồng rực ấm)
	if gx < peak_col:
		if is_bot:
			return COL_CAM_DARK
		if is_top:
			return COL_CAM_HI if ((gx + anim_step) % 4 != 0) else COL_PEAK_MID
		if is_sub_top:
			return COL_CAM_HI if checker else COL_CAM_MID
		if is_sub_bot:
			return COL_CAM_DARK if checker else COL_CAM_MID
		return COL_CAM_HI if (((gx + gy + anim_step / 2) % 5) == 0) else COL_CAM_MID

	# Vùng 3: Đỏ Rực ★ (lõi lửa vàng kem + hạt lửa pixel nhảy bước 8 FPS)
	if gx < burn_col:
		var spark_hash := (gx * 7 + gy * 13 + anim_step * 3) % 11
		if is_bot:
			return COL_PEAK_DARK
		if is_top:
			return COL_PEAK_CORE if ((gx - anim_step) % 4 == 0) else COL_PEAK_HI
		if spark_hash == 0:
			return COL_PEAK_CORE
		if is_sub_top or spark_hash <= 3:
			return COL_PEAK_HI
		if is_sub_bot:
			return COL_PEAK_DARK if checker else COL_PEAK_MID
		return COL_PEAK_MID

	# Vùng 4: Cháy (than đen sọc cảnh báo đỏ pixel art)
	var stripe := ((gx - gy + anim_step) % 4) == 0
	if is_bot:
		return COL_BURN_DARK
	if stripe:
		return COL_BURN_HI if not is_sub_bot else COL_BURN_MID
	return COL_BURN_MID if (is_top or checker) else COL_BURN_DARK


func _draw_heat_progress_mask(inner: Rect2) -> void:
	var fill_w: float = snappedf(inner.size.x * heat_percent, PX)
	var fill_x: float = inner.position.x + clampf(fill_w, 0.0, inner.size.x)

	# Lớp che tối cho phần nhiệt chưa nung tới (rõ mức nhiệt đã đạt)
	if fill_x < inner.end.x:
		draw_rect(
			Rect2(Vector2(fill_x, inner.position.y), Vector2(inner.end.x - fill_x, inner.size.y)),
			COL_UNFILLED
		)

	# Vệt sáng pixel 3px ở ngay đầu cột nhiệt khi đang có lửa
	if fill_w >= PX and fill_x < inner.end.x:
		draw_rect(
			Rect2(Vector2(fill_x - PX, inner.position.y), Vector2(PX, inner.size.y)),
			Color(1.0, 0.96, 0.78, 0.65)
		)


func _draw_threshold_dividers(inner: Rect2) -> void:
	var marks: Array[Dictionary] = [
		{"pct": sweet_min, "tint": Color(1.00, 0.88, 0.45, 1.0)},
		{"pct": peak_frac, "tint": Color(1.00, 0.68, 0.24, 1.0)},
		{"pct": burn_frac, "tint": Color(1.00, 0.36, 0.28, 1.0)},
	]
	for mark: Dictionary in marks:
		var pct: float = float(mark["pct"])
		var mx: float = inner.position.x + snappedf(inner.size.x * pct, PX)
		if _divider_tex != null:
			var dw: float = float(_divider_tex.get_width())
			var dh: float = inner.size.y + 6.0
			var rect := Rect2(
				Vector2(mx - dw * 0.5, inner.position.y - 3.0),
				Vector2(dw, dh)
			)
			draw_texture_rect(_divider_tex, rect, false, mark["tint"])
		else:
			draw_rect(
				Rect2(Vector2(mx - PX * 0.5, inner.position.y), Vector2(PX, inner.size.y)),
				mark["tint"]
			)


func _draw_pixel_frame(width: float, height: float, anim_step: int) -> void:
	var frame_rect := Rect2(Vector2.ZERO, Vector2(width, height))
	if _frame_style != null:
		if is_overheated() and (anim_step % 2) == 0:
			_frame_style.modulate_color = Color(1.20, 0.58, 0.50, 1.0)
		elif is_at_peak():
			_frame_style.modulate_color = Color(1.10, 1.02, 0.86, 1.0)
		else:
			_frame_style.modulate_color = Color.WHITE
		draw_style_box(_frame_style, frame_rect)
	else:
		draw_rect(frame_rect, COL_OUTLINE, false, PX)


func _draw_pixel_needle(inner: Rect2, height: float) -> void:
	var nx: float = inner.position.x + snappedf(inner.size.x * heat_percent, PX)
	nx = clampf(nx, inner.position.x, inner.end.x)
	if _needle_tex != null:
		var nw: float = float(_needle_tex.get_width())
		var nh: float = height + 24.0
		var nrect := Rect2(Vector2(nx - nw * 0.5, -12.0), Vector2(nw, nh))
		draw_texture_rect(_needle_tex, nrect, false)
	else:
		draw_rect(Rect2(Vector2(nx - PX, -6.0), Vector2(PX * 2.0, height + 12.0)), COL_OUTLINE)
		draw_rect(Rect2(Vector2(nx - PX * 0.5, -3.0), Vector2(PX, height + 6.0)), COL_PEAK_CORE)
