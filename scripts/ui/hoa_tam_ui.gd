# scripts/ui/hoa_tam_ui.gd
# Thư viện thành phần UI 32-bit Hoả Tâm dùng chung toàn game (0% mixel, 0% emoji).
class_name HoaTamUI
extends RefCounted

# ── Bảng màu chuẩn Hoả Tâm (không dùng RGB gốc #FF0000 / #FFFFFF) ────────────
const COL_OUTLINE := Color(0.071, 0.047, 0.063, 1.0)     # #120C10
const COL_WOOD_DARK := Color(0.106, 0.071, 0.078, 1.0)   # #1B1214
const COL_PARCHMENT := Color(0.918, 0.843, 0.718, 1.0)   # #EAD7B7
const COL_INK := Color(0.165, 0.106, 0.094, 1.0)         # #2A1B18 (chữ mực trên giấy dó)
const COL_INK_MUTE := Color(0.365, 0.267, 0.204, 1.0)    # #5D4434
const COL_GOLD := Color(0.957, 0.784, 0.349, 1.0)        # #F4C859
const COL_BRASS := Color(0.784, 0.608, 0.329, 1.0)       # #C89B54
const COL_EMBER := Color(0.910, 0.478, 0.141, 1.0)       # #E87A24
const COL_CRIMSON := Color(0.788, 0.290, 0.220, 1.0)     # #C94A38 (cảnh báo nợ / nguyền)
const COL_CRIMSON_INK := Color(0.565, 0.145, 0.133, 1.0) # #902522 (chữ đỏ trên giấy dó)
const COL_JADE := Color(0.337, 0.792, 0.651, 1.0)        # #56CAA6
const COL_DIM_BG := Color(0.055, 0.035, 0.043, 0.78)     # Nền tối ấm sau modal

# ── Đường dẫn UI Kit 32-bit ──────────────────────────────────────────────────
const TEX_PANEL_WOOD := "res://assets/pixel/ui/kit/panel_wood_brass_9s.png"
const TEX_PANEL_PARCHMENT := "res://assets/pixel/ui/kit/panel_parchment_9s.png"
const TEX_PANEL_DIALOGUE := "res://assets/pixel/ui/kit/panel_dialogue_scroll_9s.png"
const TEX_PANEL_NAMEPLATE := "res://assets/pixel/ui/kit/panel_nameplate_9s.png"
const TEX_PANEL_LEATHER := "res://assets/pixel/ui/kit/panel_leather_chest_9s.png"
const TEX_PANEL_STEEL := "res://assets/pixel/ui/kit/panel_forged_steel_9s.png"
const TEX_PANEL_SYSTEM := "res://assets/pixel/ui/kit/panel_system_slate_9s.png"
const TEX_BTN_BRASS_N := "res://assets/pixel/ui/kit/btn_brass_normal_9s.png"
const TEX_BTN_BRASS_H := "res://assets/pixel/ui/kit/btn_brass_hover_9s.png"
const TEX_BTN_BRASS_P := "res://assets/pixel/ui/kit/btn_brass_pressed_9s.png"
const TEX_BTN_WAX_N := "res://assets/pixel/ui/kit/btn_wax_primary_normal_9s.png"
const TEX_BTN_WAX_H := "res://assets/pixel/ui/kit/btn_wax_primary_hover_9s.png"
const TEX_BTN_WAX_P := "res://assets/pixel/ui/kit/btn_wax_primary_pressed_9s.png"
const TEX_BTN_PARCHMENT_N := "res://assets/pixel/ui/kit/btn_parchment_normal_9s.png"
const TEX_BTN_PARCHMENT_H := "res://assets/pixel/ui/kit/btn_parchment_hover_9s.png"
const TEX_BTN_PARCHMENT_P := "res://assets/pixel/ui/kit/btn_parchment_pressed_9s.png"
const TEX_SLOT_SHEET := "res://assets/pixel/ui/kit/slot_frame_sheet_32.png"
const TEX_HUD_ICONS := "res://assets/pixel/ui/kit/hud_icons_sheet_16.png"
const TEX_COMBAT_ICONS := "res://assets/pixel/ui/kit/combat_action_icons_16.png"
const TEX_BAR_FRAME := "res://assets/pixel/ui/kit/bar_frame_9s.png"
const TEX_STAMINA_PIPS := "res://assets/pixel/ui/kit/stamina_pip_sheet_12.png"

const FONT_PIXEL := "res://assets/fonts/PixelifySans.ttf"
const FONT_SERIF := "res://assets/fonts/Lora-Regular.ttf"

# ── Chỉ số Icon trong hud_icons_sheet_16.png (12 ô 60×60) ────────────────────
enum HudIcon {
	GOLD = 0,
	REPUTATION = 1,
	STAMINA = 2,
	DEBT = 3,
	MORNING = 4,
	NOON = 5,
	AFTERNOON = 6,
	NIGHT = 7,
	ATK = 8,
	DEF = 9,
	MAG = 10,
	SPD = 11,
}

# ── Chỉ số Icon trong combat_action_icons_16.png (8 ô 72×72) ─────────────────
enum CombatIcon {
	BASIC_SLASH = 0,
	SKILL_1 = 1,
	SKILL_2 = 2,
	RUN = 3,
	SWAP_WEAPON = 4,
	HAMMER_CUONG = 5,
	HAMMER_NHU = 6,
	BAG = 7,
}

# ── Trạng thái ô chứa & hạt thể lực ──────────────────────────────────────────
enum SlotState { EMPTY = 0, FILLED = 1, SELECTED = 2, LOCKED = 3 }
enum PipState { FULL = 0, LOW = 1, EMPTY = 2 }


static func make_wood_panel_style(pad: float = 24.0) -> StyleBoxTexture:
	return _make_9slice(TEX_PANEL_WOOD, 36.0, 36.0, pad, pad)


static func make_parchment_panel_style(pad: float = 28.0) -> StyleBoxTexture:
	return _make_9slice(TEX_PANEL_PARCHMENT, 36.0, 36.0, pad, pad)


static func make_dialogue_panel_style(pad: float = 24.0) -> StyleBoxTexture:
	return _make_9slice(TEX_PANEL_DIALOGUE, 36.0, 36.0, pad, pad)


static func make_nameplate_style() -> StyleBoxTexture:
	var sb := _make_9slice(TEX_PANEL_NAMEPLATE, 56.0, 18.0, 28.0, 6.0)
	# Phần đuôi băng rôn gập 3D chiếm ~30% dưới ảnh -> tăng lề đáy để tên nhân vật nằm chính giữa dải đỏ mận
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 22.0
	return sb


static func make_leather_chest_style(pad: float = 24.0) -> StyleBoxTexture:
	return _make_9slice(TEX_PANEL_LEATHER, 36.0, 36.0, pad, pad)


static func make_forged_steel_style(pad: float = 24.0) -> StyleBoxTexture:
	return _make_9slice(TEX_PANEL_STEEL, 36.0, 36.0, pad, pad)


static func make_system_slate_style(pad: float = 28.0) -> StyleBoxTexture:
	return _make_9slice(TEX_PANEL_SYSTEM, 36.0, 36.0, pad, pad)


static func make_bar_frame_style() -> StyleBoxTexture:
	return _make_9slice(TEX_BAR_FRAME, 24.0, 12.0, 6.0, 4.0)


# Bề mặt chìm nhẹ bên trong Modal / Sân khấu (KHÔNG dùng khung 9-slice dày tránh lồng khung)
static func make_inset_surface_style(
	bg_alpha: float = 0.62,
	pad: float = 10.0,
	border_col: Color = Color(0.45, 0.32, 0.19, 0.65)
) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(COL_WOOD_DARK.r, COL_WOOD_DARK.g, COL_WOOD_DARK.b, bg_alpha)
	s.border_color = border_col
	s.set_border_width_all(1)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad
	s.content_margin_bottom = pad
	return s


# Dải HUD mảnh trên/dưới mép màn hình (chỉ có 1 đường chỉ đồng phân tách, không đóng hộp 4 cạnh)
static func make_hud_strip_style(
	pad_h: float = 16.0,
	pad_v: float = 8.0,
	top_line: bool = false
) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.075, 0.048, 0.052, 0.82)
	s.border_color = Color(0.68, 0.50, 0.24, 0.72)
	if top_line:
		s.border_width_top = 2
	else:
		s.border_width_bottom = 2
	s.content_margin_left = pad_h
	s.content_margin_right = pad_h
	s.content_margin_top = pad_v
	s.content_margin_bottom = pad_v
	return s


# Nút tab / điều hướng nhẹ cho HUD & góc màn hình (không tranh chấp điểm nhấn chính)
static func apply_flat_tab_button(
	btn: Button,
	is_active: bool = false,
	font_size: int = 18
) -> void:
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var s_norm := StyleBoxFlat.new()
	s_norm.bg_color = Color(0.24, 0.13, 0.09, 0.88) if is_active else Color(0.08, 0.05, 0.05, 0.72)
	s_norm.border_color = COL_GOLD if is_active else Color(0.42, 0.30, 0.18, 0.55)
	s_norm.border_width_bottom = 2 if is_active else 1
	s_norm.content_margin_left = 12.0
	s_norm.content_margin_right = 12.0
	s_norm.content_margin_top = 6.0
	s_norm.content_margin_bottom = 6.0

	var s_hov := s_norm.duplicate() as StyleBoxFlat
	s_hov.bg_color = Color(0.32, 0.17, 0.11, 0.94)
	s_hov.border_color = COL_GOLD
	s_hov.border_width_bottom = 2

	btn.add_theme_stylebox_override("normal", s_norm)
	btn.add_theme_stylebox_override("hover", s_hov)
	btn.add_theme_stylebox_override("pressed", s_hov)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", COL_GOLD if is_active else COL_PARCHMENT)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.78))


static func make_panel_container(use_parchment: bool = false, pad: float = 24.0) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sb := make_parchment_panel_style(pad) if use_parchment else make_wood_panel_style(pad)
	panel.add_theme_stylebox_override("panel", sb)
	return panel


static func apply_primary_button(btn: Button, font_size: int = 24) -> void:
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.add_theme_stylebox_override("normal", _make_9slice(TEX_BTN_WAX_N, 27.0, 18.0, 20.0, 10.0))
	btn.add_theme_stylebox_override("hover", _make_9slice(TEX_BTN_WAX_H, 27.0, 18.0, 20.0, 10.0))
	btn.add_theme_stylebox_override("focus", _make_9slice(TEX_BTN_WAX_H, 27.0, 18.0, 20.0, 10.0))
	btn.add_theme_stylebox_override("pressed", _make_9slice(TEX_BTN_WAX_P, 27.0, 18.0, 20.0, 12.0))
	var dis := _make_9slice(TEX_BTN_WAX_P, 27.0, 18.0, 20.0, 10.0)
	dis.modulate_color = Color(0.62, 0.58, 0.56, 0.85)
	btn.add_theme_stylebox_override("disabled", dis)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(0.992, 0.945, 0.840, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.980, 0.880, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.86, 0.78, 0.66, 1.0))


static func apply_secondary_button(btn: Button, font_size: int = 22) -> void:
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.add_theme_stylebox_override("normal", _make_9slice(TEX_BTN_BRASS_N, 27.0, 18.0, 20.0, 10.0))
	btn.add_theme_stylebox_override("hover", _make_9slice(TEX_BTN_BRASS_H, 27.0, 18.0, 20.0, 10.0))
	btn.add_theme_stylebox_override("focus", _make_9slice(TEX_BTN_BRASS_H, 27.0, 18.0, 20.0, 10.0))
	btn.add_theme_stylebox_override("pressed", _make_9slice(TEX_BTN_BRASS_P, 27.0, 18.0, 20.0, 12.0))
	var dis := _make_9slice(TEX_BTN_BRASS_P, 27.0, 18.0, 20.0, 10.0)
	dis.modulate_color = Color(0.62, 0.58, 0.56, 0.85)
	btn.add_theme_stylebox_override("disabled", dis)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", COL_PARCHMENT)
	btn.add_theme_color_override("font_hover_color", Color(0.992, 0.918, 0.678, 1.0))


static func apply_parchment_button(btn: Button, font_size: int = 20) -> void:
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.add_theme_stylebox_override("normal", _make_9slice(TEX_BTN_PARCHMENT_N, 52.0, 18.0, 28.0, 10.0))
	btn.add_theme_stylebox_override("hover", _make_9slice(TEX_BTN_PARCHMENT_H, 52.0, 18.0, 28.0, 10.0))
	btn.add_theme_stylebox_override("focus", _make_9slice(TEX_BTN_PARCHMENT_H, 52.0, 18.0, 28.0, 10.0))
	btn.add_theme_stylebox_override("pressed", _make_9slice(TEX_BTN_PARCHMENT_P, 52.0, 18.0, 28.0, 12.0))
	var dis := _make_9slice(TEX_BTN_PARCHMENT_P, 52.0, 18.0, 28.0, 10.0)
	dis.modulate_color = Color(0.62, 0.58, 0.56, 0.85)
	btn.add_theme_stylebox_override("disabled", dis)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", COL_INK)
	btn.add_theme_color_override("font_hover_color", Color(0.28, 0.14, 0.08, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.12, 0.08, 0.06, 1.0))


static func get_hud_icon(icon: HudIcon) -> AtlasTexture:
	return _slice_strip(TEX_HUD_ICONS, int(icon), 60, 60)


static func get_combat_icon(icon: CombatIcon) -> AtlasTexture:
	return _slice_strip(TEX_COMBAT_ICONS, int(icon), 72, 72)


static func get_slot_texture(state: SlotState) -> AtlasTexture:
	return _slice_strip(TEX_SLOT_SHEET, int(state), 96, 96)


static func get_pip_texture(state: PipState) -> AtlasTexture:
	return _slice_strip(TEX_STAMINA_PIPS, int(state), 48, 48)


static func make_icon_rect(tex: Texture2D, size_px: int = 30) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = tex
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(size_px, size_px)
	return rect


static func make_dim_backdrop() -> ColorRect:
	var bg := ColorRect.new()
	bg.color = COL_DIM_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	return bg


static func _make_9slice(
	path: String,
	margin_h: float,
	margin_v: float,
	pad_h: float,
	pad_v: float
) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(path) as Texture2D
	sb.texture_margin_left = margin_h
	sb.texture_margin_right = margin_h
	sb.texture_margin_top = margin_v
	sb.texture_margin_bottom = margin_v
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb


static func _slice_strip(path: String, index: int, cell_w: int, cell_h: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path) as Texture2D
	atlas.region = Rect2(index * cell_w, 0, cell_w, cell_h)
	return atlas
