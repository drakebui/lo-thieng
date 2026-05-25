# gdlint: disable=max-file-lines
class_name NegotiationUI
extends CanvasLayer

signal deal_accepted(weapon: Dictionary, gold: int)
signal trade_accepted(weapon: Dictionary, trade_offer: Dictionary)
signal deal_declined()
enum Phase { SELECT, PRICE }
enum Mood { NEUTRAL, HAPPY, THINKING, ANNOYED, ANGRY }

const PPW := 128; const PPH := 190    # kích thước khung chân dung trong dialog
const PANEL_W := 940
const PANEL_H := 620
const PRICE_TRACK_W := 500
const PRICE_ZONE_H := 10
const PRICE_VISIBLE_PAD_MIN := 80.0
const PRICE_VISIBLE_PAD_RATIO := 0.45
const PROPOSALS_MAX := 3              # tối đa số lần player đề xuất giá

const C_OVR   := Color(0.05, 0.03, 0.01, 0.80)
const C_FRAME := Color(0.72, 0.54, 0.24)
const C_PANEL := Color(0.13, 0.08, 0.05)
const C_HDR   := Color(0.20, 0.13, 0.07)
const C_SPCH  := Color(0.10, 0.07, 0.04)
const C_SEP   := Color(0.42, 0.28, 0.12)
const C_IBKG  := Color(0.08, 0.05, 0.02)
const C_TRAD  := Color(0.06, 0.13, 0.08)
const C_TEXT  := Color(0.96, 0.88, 0.72)
const C_MUTE  := Color(0.64, 0.52, 0.36)
const C_GOLD  := Color(1.00, 0.84, 0.26)
const C_TGRN  := Color(0.54, 0.90, 0.54)
const C_BTN   := Color(0.28, 0.18, 0.09)
const C_BTNH  := Color(0.44, 0.30, 0.15)
const C_ACC   := Color(0.16, 0.40, 0.18)
const C_ACCH  := Color(0.24, 0.54, 0.28)
const C_REJ   := Color(0.42, 0.12, 0.12)
const C_REJH  := Color(0.58, 0.18, 0.18)
const C_ZONE_SAFE := Color(0.46, 0.47, 0.42)
const C_ZONE_DEAL := Color(0.30, 0.66, 0.28)
const C_THRT  := Color(0.48, 0.22, 0.06)   # nút đe dọa
const C_THRTH := Color(0.66, 0.32, 0.10)
const C_SKIN  := Color(0.82, 0.66, 0.50)
const C_SHOP  := Color(0.28, 0.42, 0.62)
const C_APRON := Color(0.56, 0.34, 0.14)

const CUST_COLORS: Dictionary = {
	"hiep_khach":  Color(0.20, 0.45, 0.72),
	"thu_ve":      Color(0.48, 0.50, 0.56),
	"tho_san":     Color(0.30, 0.48, 0.24),
	"vo_tang":     Color(0.72, 0.62, 0.22),
	"thich_khach": Color(0.48, 0.22, 0.58),
	"dao_si":      Color(0.22, 0.60, 0.58),
	"thuong_nhan": Color(0.68, 0.48, 0.18),
	"nong_dan":    Color(0.40, 0.55, 0.28),
	"ve_binh":     Color(0.28, 0.34, 0.60),
}

const DIALOGUES: Dictionary = {
	"hiep_khach":  "Tôi cần một thanh kiếm tốt cho hành trình dài...",
	"thu_ve":      "Cần thứ gì đủ nặng để giữ tuyến đầu.",
	"tho_san":     "Tôi cần thứ nhẹ, chắc, không vướng tay khi băng đồng.",
	"vo_tang":     "Không cần hoa mỹ — dùng được là đủ.",
	"thich_khach": "...Thứ gì đó nhanh. Đừng hỏi để làm gì.",
	"dao_si":      "Huyền lực quan trọng hơn vật lý.",
	"thuong_nhan": "Tôi mua để bán lại — giá phải hợp lý.",
	"nong_dan":    "Dao làm vườn thôi. Không cần gì đặc biệt. Bao nhiêu?",
	"ve_binh":     "Tiêu chuẩn hoàng gia. Chất lượng trên hết.",
}

const NPC_OFFER_LINES: Dictionary = {
	"hiep_khach":  "Tôi trả %dG thôi — đủ xài trên đường rồi.",
	"thu_ve":      "%dG. Không hơn, quân đội không có ngân sách dư.",
	"tho_san":     "%dG. Đi săn còn phải giữ tiền mua dây cung.",
	"vo_tang":     "Mức giá hợp lý với tôi là %dG.",
	"thich_khach": "%dG. Đừng hỏi thêm.",
	"dao_si":      "Huyền lực đáng %dG, không hơn.",
	"thuong_nhan": "Giá thị trường tôi biết. %dG là hợp lý.",
	"nong_dan":    "Tôi chắt chiu được %dG, mong thông cảm.",
	"ve_binh":     "Ngân khố hoàng gia phê duyệt %dG cho vật phẩm này.",
}

const HAGGLE_COUNTER_LINES: Dictionary = {
	"hiep_khach":  "Đắt vậy sao! Tôi chỉ có thể trả tối đa %dG thôi.",
	"thu_ve":      "Vượt ngân sách. Tối đa của tôi là %dG.",
	"tho_san":     "%dG là mức tôi gánh được. Cao hơn thì khó.",
	"vo_tang":     "Không hợp lý. Tôi chỉ trả %dG, không hơn.",
	"thich_khach": "...%dG. Cuối cùng đấy.",
	"dao_si":      "Giá quá cao. Tôi chỉ có thể trả %dG.",
	"thuong_nhan": "Thôi được, %dG là cao nhất — tôi cần lời nữa chứ.",
	"nong_dan":    "Trời ơi... %dG là hết sức rồi bác ơi.",
	"ve_binh":     "Ngân khố chỉ duyệt %dG. Không thể cao hơn.",
}

const HAGGLE_TOO_HIGH_LINES: Dictionary = {
	"hiep_khach":  "Quá đắt! Thôi tôi đi chỗ khác.",
	"thu_ve":      "Không nằm trong ngân sách. Rút lui.",
	"tho_san":     "Giá đó mua dây bẫy cả mùa còn hơn. Tôi đi.",
	"vo_tang":     "Không hợp lý. Tôi đi.",
	"thich_khach": "Không. Tạm biệt.",
	"dao_si":      "Quá đắt, không xứng huyền lực. Tôi đi.",
	"thuong_nhan": "Không lời được. Tôi qua chỗ khác.",
	"nong_dan":    "Thôi... đắt quá. Để lần khác vậy.",
	"ve_binh":     "Không đạt tiêu chuẩn ngân sách hoàng gia.",
}

const ACCEPT_LINES: Dictionary = {
	"hiep_khach":  "Được rồi! Hàng tốt, giá hợp lý. Cảm ơn!",
	"thu_ve":      "Hợp lý. Giao dịch thành công.",
	"tho_san":     "Được. Nhẹ tay đấy. Tôi lấy.",
	"vo_tang":     "Tốt. Tôi sẽ dùng nó xứng đáng.",
	"thich_khach": "...Ổn. Đây tiền.",
	"dao_si":      "Tuyệt! Huyền lực trong đây rất mạnh.",
	"thuong_nhan": "Giá phải chăng, tôi lấy.",
	"nong_dan":    "Ôi. Tay cầm... ấm lạ. Như vừa ra lò vậy. Lần sau mình lại. Cảm ơn nha.",
	"ve_binh":     "Giao dịch hoàn tất. Hoàng gia hài lòng.",
}

const DECLINE_LINES: Dictionary = {
	"hiep_khach":  "Thôi vậy... Có lẽ lần sau.",
	"thu_ve":      "Không đủ tiêu chuẩn. Tôi đi chỗ khác.",
	"tho_san":     "Không hợp chuyến săn này. Để lần khác.",
	"vo_tang":     "Không hợp ý. Cảm ơn vẫn vậy.",
	"thich_khach": "Không. Tạm biệt.",
	"dao_si":      "Tiếc. Lần sau nhé.",
	"thuong_nhan": "Giá quá cao, không lời được.",
	"nong_dan":    "Thôi... đắt quá. Để lần khác vậy.",
	"ve_binh":     "Không đạt chuẩn. Rút lui.",
}

const HAGGLE_FRUSTRATED_LINES: Dictionary = {
	"hiep_khach":  "Giá cao quá! Nhưng... tôi vẫn muốn thứ này. Xem lại đi.",
	"thu_ve":      "Vượt ngân sách rồi. Cố hạ xuống không?",
	"tho_san":     "Hàng ổn, nhưng giá này làm tôi hụt tiền đi đường.",
	"vo_tang":     "Không hợp lý. Tôi còn chờ thêm một chút.",
	"thich_khach": "...Đắt quá. Lần cuối đấy.",
	"dao_si":      "Huyền lực không đáng giá thế. Thử lại đi.",
	"thuong_nhan": "Tôi không lời được. Bớt xuống không?",
	"nong_dan":    "Tôi chỉ cần đồ dùng được thôi... bác bớt thêm được không?",
	"ve_binh":     "Vượt ngân sách hoàng gia. Hạ xuống đi.",
}

const WALKIN_LINES: Dictionary = {
	"hiep_khach":  "Ồ, tiệm rèn mới à. Xem thử có gì không...",
	"thu_ve":      "(nhìn quanh) Vũ khí ở đây trông... được đây.",
	"tho_san":     "Có món nào nhẹ để mang qua đồng không?",
	"vo_tang":     "Nam mô... Ta cần đồ tốt cho tu hành.",
	"thich_khach": "...",
	"dao_si":      "Huyền khí ở đây khá thuần. Đáng xem.",
	"thuong_nhan": "(nhẩm tính) Tiệm mới, chắc giá chưa ổn định...",
	"nong_dan":    "Ơ... mở cửa rồi hả? Tưởng chỗ này bỏ mãi.",
	"ve_binh":     "Kiểm tra hàng hóa theo lệnh hoàng gia.",
}

const BROWSE_LINES: Dictionary = {
	"hiep_khach":  "Hmm... loại này nhẹ tay quá. Cần thứ gì đó chắc hơn...",
	"thu_ve":      "Trọng lượng ổn. Cân bằng ra sao nhỉ?",
	"tho_san":     "Cán này không vướng áo. Lưỡi cũng không quá nặng.",
	"vo_tang":     "Thô nhưng có hồn. Ta thích thế này.",
	"thich_khach": "...(nghiêng đầu xem lưỡi kiếm)",
	"dao_si":      "Nguyên tố hỏa trong này còn mạnh. Tốt.",
	"thuong_nhan": "Chất lượng này bán lại được khoảng... hmm.",
	"nong_dan":    "Tay cầm này... ấm lạ. Như vừa ra lò vậy.",
	"ve_binh":     "Kiểm tra: lưỡi sắc, cán chắc. Đạt tiêu chuẩn cơ bản.",
}

const THINKING_LINES: Dictionary = {
	"hiep_khach":  "Để ta tính... hành trình còn dài, cần giữ tiền dự phòng...",
	"thu_ve":      "Ngân sách hạn chế... nhưng thiếu vũ khí cũng không được...",
	"tho_san":     "Một chuyến săn lời không nhiều... phải tính kỹ.",
	"vo_tang":     "Từ bi hỷ xả... nhưng tiền cũng phải tính...",
	"thich_khach": "...",
	"dao_si":      "Huyền lực của nó và mức giá... cần cân nhắc.",
	"thuong_nhan": "Giá mua, giá bán, lợi nhuận... hmm.",
	"nong_dan":    "Tôi còn phải chừa tiền sửa cái cuốc gãy nữa...",
	"ve_binh":     "Tham chiếu bảng giá hoàng gia... xử lý...",
}

const THREAT_APPEAR_RATE: Dictionary = {
	"nong_dan":    0.70,
	"thuong_nhan": 0.55,
	"hiep_khach":  0.30,
	"tho_san":     0.25,
	"vo_tang":     0.20,
	"dao_si":      0.15,
	"thu_ve":      0.05,
	"thich_khach": 0.0,   # sát thủ — quá nguy hiểm
	"ve_binh":     0.0,   # vệ binh hoàng gia — liên lụy pháp lý
}

const THREAT_SUCCESS_RATE: Dictionary = {
	"nong_dan":    0.85,
	"thuong_nhan": 0.68,
	"hiep_khach":  0.38,
	"tho_san":     0.32,
	"vo_tang":     0.28,
	"dao_si":      0.22,
	"thu_ve":      0.08,
	"thich_khach": 0.0,
	"ve_binh":     0.0,
}

const THREAT_SUCCESS_LINES: Dictionary = {
	"hiep_khach":  "...(nghiến răng) Lần này thôi. Đừng tưởng ta sợ mi.",
	"thu_ve":      "...(căng thẳng) Lần này bỏ qua. Nhưng đừng thử lại.",
	"tho_san":     "...Được. Nhưng tôi nhớ mặt người ép giá rất lâu.",
	"vo_tang":     "Ta không muốn gây thêm nghiệp... thôi được.",
	"thich_khach": "...",
	"dao_si":      "...(thở dài) Duyên phận vậy rồi.",
	"thuong_nhan": "(lắp bắp) Th... thôi được, đừng làm to chuyện...",
	"nong_dan":    "...(run rẩy) Vâng vâng... bác muốn bao nhiêu cũng được...",
	"ve_binh":     "...",
}

const THREAT_FAIL_LINES: Dictionary = {
	"hiep_khach":  "(rút kiếm) Mi muốn thử sức với ta?! Tôi đi!",
	"thu_ve":      "(đặt tay lên đao) Tên thợ rèn. Mi vừa phạm sai lầm.",
	"tho_san":     "(lùi lại) Tôi săn thú, không chịu bị dọa trong tiệm.",
	"vo_tang":     "(tấn công tư thế) Ngươi dám?! Ta không mua nữa.",
	"thich_khach": "...",
	"dao_si":      "(mắt lóe sáng) Trò con nít. Tôi đi.",
	"thuong_nhan": "Anh nghĩ tôi sợ sao?! Tôi có người bảo kê! Tôi đi!",
	"nong_dan":    "Không! Tôi báo quan ngay bây giờ!",
	"ve_binh":     "...",
}

# ══════════════════════════════════════════════════════════════════════════════
# TRADE SYSTEM
# ══════════════════════════════════════════════════════════════════════════════

const TRADE_RATES: Dictionary = {
	"hiep_khach": 0.10, "thu_ve":      0.10, "tho_san":    0.12, "vo_tang":    0.15,
	"thich_khach": 0.20, "dao_si":     0.25, "thuong_nhan": 0.35,
	"nong_dan":   0.05, "ve_binh":     0.10,
}

const TRADE_OFFER_POOL: Array = [
	{"type": "material", "item_id": "sat_tho", "name": "Quặng Sắt", "amount": 15},
	{"type": "material", "item_id": "quang_than", "name": "Than Hầm Mỏ", "amount": 10},
	{"type": "material", "item_id": "da_thu", "name": "Da Thú Rừng", "amount": 8},
	{"type": "material", "item_id": "da_hoa_son", "name": "Đá Lửa Núi Lửa", "amount": 6},
	{
		"type": "material",
		"item_id": "linh_luc_bang_2",
		"name": "Tinh Thể Băng",
		"amount": 5,
	},
	{"type": "item",     "name": "Kiếm Cổ Đại",          "rarity": 4},
	{"type": "item",     "name": "Đoản Đao Huyền Thoại", "rarity": 5},
	{"type": "item",     "name": "Búa Thần Cổ",          "rarity": 5},
]

const TRADE_INTRO_LINES: Dictionary = {
	"hiep_khach":  "À... thật ra tôi có thứ này muốn đổi. Chịu không?",
	"thu_ve":      "Quân đội cấp cho tôi vật này. Đổi hàng được không?",
	"tho_san":     "Tôi có ít vật liệu săn được. Đổi thay tiền được chứ?",
	"vo_tang":     "Tôi nhặt được thứ này. Đổi lấy vũ khí nhé?",
	"thich_khach": "...Tôi có thứ đáng giá hơn tiền. Muốn đổi không?",
	"dao_si":      "Tôi có nguyên liệu huyền bí. Trao đổi nhé?",
	"thuong_nhan": "Thay vì tiền — tôi có hàng đổi. Lợi hơn cho cả hai.",
	"nong_dan":    "Tiền không đủ... tôi có mấy thứ này có đổi được không?",
	"ve_binh":     "Kho cũ hoàng gia có vật phẩm muốn trao đổi.",
}

var _phase:          Phase      = Phase.SELECT
var _customer:       Dictionary = {}
var _weapons:        Array      = []
var _chosen_weapon:  Dictionary = {}
var _offer_gold:     int        = 0
var _trade_offer:    Dictionary = {}
var _resolving:      bool       = false
var _patience:       int        = 0   # kiên nhẫn hiện tại của NPC
var _proposals_used: int        = 0   # số lần player đã đề xuất giá

var _npc_max_price:  int        = 0   # giá tối đa NPC sẵn sàng trả (budget ∩ val×class_factor)
var _price_cap_hard: int        = 0   # trần cứng player được nhập (val × 1.6)
var _hint_min:       int        = 0   # cận dưới gợi ý hiển thị
var _hint_max:       int        = 0   # cận trên gợi ý hiển thị
var _threat_available: bool     = false  # nút đe dọa có xuất hiện lượt này không
var _threat_used:      bool     = false  # đã dùng chưa (1 lần/giao dịch)

var _root:           Control

var _bx:             int = 0   # outer border left x
var _by:             int = 0   # outer border top y

var _rport_body:     ColorRect
var _rport_name:     Label
var _mood_overlay:   ColorRect
var _patience_bar:   ColorRect

var _lbl_hdr:        Label
var _lbl_npc_speech: Label

var _weapon_box:     VBoxContainer
var _btn_no_sale:    Button

var _p2_root:            Control
var _lbl_wpn_name:       Label
var _lbl_wpn_stats:      Label
var _lbl_negotiate_info: Label   # "Lượt còn: X/3 · Kiên nhẫn: ●●○"
var _lbl_npc_offer:      Label
var _price_slider:       HSlider
var _lbl_price_display:  Label
var _zone_low_rect:      ColorRect
var _zone_good_rect:     ColorRect
var _zone_high_rect:     ColorRect
var _lbl_hint:       Label    # gợi ý khoảng giá hợp lý
var _trade_section:  Control
var _lbl_trade_desc: Label
var _btn_sell_npc:   Button
var _btn_propose:    Button
var _btn_threaten:   Button
var _btn_trade:      Button
var _btn_decline_p2: Button
var _bargain_tooltip: PanelContainer

func _ready() -> void:
	layer   = 20
	visible = false
	_build_ui()
	_bargain_tooltip = _build_bargain_tooltip()
	add_child(_bargain_tooltip)


func present(customer: Dictionary, weapon: Dictionary) -> void:
	var show_bargain_tip := not GameManager.has_tutorial_seen("bargain_shown")
	_customer    = customer
	_resolving   = false
	_trade_offer = {}

	var ctype: String = customer.get("type", "")
	_rport_body.color = CUST_COLORS.get(ctype, Color(0.5, 0.3, 0.3))
	_rport_name.text  = customer.get("name", "Khách")

	# Phase 1 bị bỏ qua — NPC tự chọn vũ khí từ kệ
	_weapon_box.visible     = false
	_btn_no_sale.visible    = false
	_p2_root.visible        = false
	_btn_sell_npc.visible   = false
	_btn_propose.visible    = false
	_btn_trade.visible      = false
	_btn_decline_p2.visible = false
	visible = true
	_on_weapon_selected(weapon)
	if show_bargain_tip:
		_show_bargain_tooltip()


func close_ui() -> void:
	visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	# ── Overlay phủ màn hình để panel trung tâm đọc rõ hơn ────────────────────
	var vp  := get_viewport().get_visible_rect()
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = C_OVR
	_root.add_child(ov)

	# Tính gốc panel căn giữa viewport.
	_bx = int((vp.size.x - PANEL_W) * 0.5)   # outer border left
	_by = int((vp.size.y - PANEL_H) * 0.5)   # outer border top
	var px  := _bx + 2   # inner panel left
	var py  := _by + 2   # inner panel top

	# ── Viền vàng panel ───────────────────────────────────────────────────────
	_r(Vector2(_bx,       _by),       Vector2(PANEL_W,   2), C_FRAME)
	_r(Vector2(_bx,       _by + PANEL_H - 2), Vector2(PANEL_W,   2), C_FRAME)
	_r(Vector2(_bx,       _by),       Vector2(  2, PANEL_H), C_FRAME)
	_r(Vector2(_bx + PANEL_W - 2, _by),       Vector2(  2, PANEL_H), C_FRAME)

	# ── Nền panel ────────────────────────────────────────────────────────────
	_r(Vector2(px, py), Vector2(PANEL_W - 4, PANEL_H - 4), C_PANEL)

	# ── Header ───────────────────────────────────────────────────────────────
	_r(Vector2(px, py),       Vector2(PANEL_W - 4,  54), C_HDR)
	_r(Vector2(_bx, py + 54), Vector2(PANEL_W,   1), C_SEP)
	_lbl_hdr = _lbl("", px + 12, py + 11, PANEL_W - 28, 32, 22)
	_lbl_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# ── Dialogue bubble giữa hai chân dung ───────────────────────────────────
	_dialogue_box(Vector2(px + 178, py + 76), Vector2(PANEL_W - 360, 148))
	_lbl_npc_speech = _lbl("", px + 194, py + 90, PANEL_W - 392, 120, 20)
	_lbl_npc_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_npc_speech.add_theme_color_override("font_color", Color(0.18, 0.08, 0.03, 1.0))

	# ── Phase 1: danh sách vũ khí ────────────────────────────────────────────
	var p1_title := _lbl("Chọn vật phẩm muốn đề xuất:", px + 34, py + 300, 860, 24, 16)
	p1_title.add_theme_color_override("font_color", C_MUTE)

	_weapon_box = VBoxContainer.new()
	_weapon_box.position = Vector2(px + 34, py + 334)
	_weapon_box.size     = Vector2(PANEL_W - 72, 220)
	_weapon_box.add_theme_constant_override("separation", 8)
	_root.add_child(_weapon_box)

	# ── Phase 2: khu vực đàm phán ────────────────────────────────────────────
	_p2_root = Control.new()
	_p2_root.position = Vector2(px + 34, py + 300)
	_p2_root.size     = Vector2(PANEL_W - 72, 230)
	_p2_root.visible  = false
	_root.add_child(_p2_root)
	_build_phase2_layout()

	# ── Separator trước nút ───────────────────────────────────────────────────
	_r(Vector2(_bx, py + PANEL_H - 62), Vector2(PANEL_W, 1), C_SEP)

	# ── Nút Phase 1 ──────────────────────────────────────────────────────────
	_btn_no_sale = _btn("Không bán lần này", C_REJ, C_REJH, 15)
	_btn_no_sale.position = Vector2(_bx + PANEL_W - 256, py + PANEL_H - 52)
	_btn_no_sale.size     = Vector2(240, 44)
	_btn_no_sale.pressed.connect(_on_decline)
	_root.add_child(_btn_no_sale)

	# ── Nút Phase 2 (ẩn ban đầu) ─────────────────────────────────────────────
	_btn_sell_npc   = _btn("Bán giá NPC", C_ACC,  C_ACCH, 14)
	_btn_propose    = _btn("Đề xuất giá", C_BTN,  C_BTNH, 14)
	_btn_threaten   = _btn("⚠ Đe dọa",   C_THRT, C_THRTH, 14)
	_btn_trade      = _btn("Đổi hàng",   C_ACC,  C_ACCH, 14)
	_btn_decline_p2 = _btn("Từ chối",    C_REJ,  C_REJH, 14)
	for b: Button in [_btn_sell_npc, _btn_propose, _btn_threaten, _btn_trade, _btn_decline_p2]:
		b.visible = false
		_root.add_child(b)
	_btn_sell_npc.pressed.connect(_on_sell_npc_price)
	_btn_propose.pressed.connect(_on_propose)
	_btn_threaten.pressed.connect(_on_threaten)
	_btn_trade.pressed.connect(_on_trade_accept)
	_btn_decline_p2.pressed.connect(_on_decline)

	# ── Chân dung (thêm cuối — đè lên viền panel) ────────────────────────────
	_build_player_portrait()
	_build_npc_portrait()


func _build_bargain_tooltip() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "BargainTooltip"
	panel.visible = false
	panel.custom_minimum_size = Vector2(456, 238)
	panel.size = Vector2(456, 238)
	panel.position = Vector2(_bx + 242, _by + 246)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_tooltip_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "MẶC CẢ"
	title.custom_minimum_size = Vector2(396, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", C_GOLD)
	vbox.add_child(title)

	var body := Label.new()
	body.text = "Kéo slider để đặt giá trong vùng gợi ý. Giá quá cao sẽ làm khách mất "
	body.text += "kiên nhẫn và có thể bỏ đi."
	body.custom_minimum_size = Vector2(396, 92)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 17)
	body.add_theme_color_override("font_color", C_TEXT)
	vbox.add_child(body)

	var ok_btn := Button.new()
	ok_btn.text = "Đã hiểu"
	ok_btn.custom_minimum_size = Vector2(120, 40)
	ok_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok_btn.pressed.connect(_on_bargain_tooltip_confirmed)
	vbox.add_child(ok_btn)
	return panel


func _make_tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.035, 0.018, 0.96)
	style.border_color = C_FRAME
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style


func _show_bargain_tooltip() -> void:
	_set_action_buttons_disabled(true)
	_bargain_tooltip.visible = true


func _on_bargain_tooltip_confirmed() -> void:
	_bargain_tooltip.visible = false
	_set_action_buttons_disabled(false)
	GameManager.mark_tutorial("bargain_shown")


func _set_action_buttons_disabled(disabled: bool) -> void:
	for b: Button in [_btn_sell_npc, _btn_propose, _btn_threaten, _btn_trade, _btn_decline_p2]:
		b.disabled = disabled


func _build_phase2_layout() -> void:
	# Tên vũ khí
	_lbl_wpn_name = Label.new()
	_lbl_wpn_name.position = Vector2(0, 0)
	_lbl_wpn_name.size     = Vector2(520, 32)
	_lbl_wpn_name.clip_text = true
	_lbl_wpn_name.add_theme_font_size_override("font_size", 21)
	_lbl_wpn_name.add_theme_color_override("font_color", C_TEXT)
	_p2_root.add_child(_lbl_wpn_name)

	# Chỉ số vũ khí (thu hẹp để nhường chỗ cho info label bên phải)
	_lbl_wpn_stats = Label.new()
	_lbl_wpn_stats.position = Vector2(0, 38)
	_lbl_wpn_stats.size     = Vector2(500, 24)
	_lbl_wpn_stats.clip_text = true
	_lbl_wpn_stats.add_theme_font_size_override("font_size", 15)
	_lbl_wpn_stats.add_theme_color_override("font_color", C_MUTE)
	_p2_root.add_child(_lbl_wpn_stats)

	# Lượt đề xuất + kiên nhẫn NPC (cùng hàng với stats, căn phải)
	_lbl_negotiate_info = Label.new()
	_lbl_negotiate_info.position           = Vector2(510, 38)
	_lbl_negotiate_info.size               = Vector2(358, 24)
	_lbl_negotiate_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_negotiate_info.add_theme_font_size_override("font_size", 15)
	_lbl_negotiate_info.add_theme_color_override("font_color", C_MUTE)
	_p2_root.add_child(_lbl_negotiate_info)

	_r_in(_p2_root, Vector2(0, 72), Vector2(868, 1), C_SEP)

	# Giá NPC đề nghị
	var lbl_ofr: Label = Label.new()
	lbl_ofr.text     = "NPC:"
	lbl_ofr.position = Vector2(0, 94)
	lbl_ofr.size     = Vector2(58, 26)
	lbl_ofr.add_theme_font_size_override("font_size", 16)
	lbl_ofr.add_theme_color_override("font_color", C_MUTE)
	_p2_root.add_child(lbl_ofr)

	_lbl_npc_offer = Label.new()
	_lbl_npc_offer.position = Vector2(70, 84)
	_lbl_npc_offer.size     = Vector2(154, 52)
	_lbl_npc_offer.add_theme_font_size_override("font_size", 40)
	_lbl_npc_offer.add_theme_color_override("font_color", C_GOLD)
	_p2_root.add_child(_lbl_npc_offer)

	# Slider giá player
	var lbl_inp: Label = Label.new()
	lbl_inp.text     = "Giá của bạn:"
	lbl_inp.position = Vector2(246, 146)
	lbl_inp.size     = Vector2(126, 26)
	lbl_inp.add_theme_font_size_override("font_size", 16)
	lbl_inp.add_theme_color_override("font_color", C_MUTE)
	_p2_root.add_child(lbl_inp)

	# Gợi ý khoảng giá — cập nhật mỗi lần weapon được chọn và sau mỗi counter
	_lbl_hint = Label.new()
	_lbl_hint.position = Vector2(380, 142)
	_lbl_hint.size     = Vector2(366, 44)
	_lbl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_hint.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_lbl_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_hint.add_theme_font_size_override("font_size", 14)
	_lbl_hint.add_theme_color_override("font_color", Color(0.54, 0.78, 0.54))
	_p2_root.add_child(_lbl_hint)

	_zone_low_rect = ColorRect.new()
	_zone_low_rect.position = Vector2(246, 132)
	_zone_low_rect.size     = Vector2(0, PRICE_ZONE_H)
	_zone_low_rect.color    = C_ZONE_SAFE
	_p2_root.add_child(_zone_low_rect)

	_zone_good_rect = ColorRect.new()
	_zone_good_rect.position = Vector2(246, 132)
	_zone_good_rect.size     = Vector2(0, PRICE_ZONE_H)
	_zone_good_rect.color    = C_ZONE_DEAL
	_p2_root.add_child(_zone_good_rect)

	_zone_high_rect = ColorRect.new()
	_zone_high_rect.position = Vector2(246, 132)
	_zone_high_rect.size     = Vector2(0, PRICE_ZONE_H)
	_zone_high_rect.color    = C_REJ
	_p2_root.add_child(_zone_high_rect)

	_price_slider = HSlider.new()
	_price_slider.position = Vector2(246, 100)
	_price_slider.size     = Vector2(PRICE_TRACK_W, 34)
	_price_slider.step     = 1.0
	_price_slider.value_changed.connect(_on_price_slider_changed)
	_p2_root.add_child(_price_slider)

	_lbl_price_display = Label.new()
	_lbl_price_display.position = Vector2(760, 88)
	_lbl_price_display.size     = Vector2(108, 54)
	_lbl_price_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_price_display.add_theme_font_size_override("font_size", 38)
	_lbl_price_display.add_theme_color_override("font_color", C_GOLD)
	_p2_root.add_child(_lbl_price_display)

	# Khu vực đổi hàng (ẩn khi không có trade)
	_trade_section = Control.new()
	_trade_section.position = Vector2(0, 186)
	_trade_section.size     = Vector2(868, 34)
	_trade_section.visible  = false
	_p2_root.add_child(_trade_section)

	_r_in(_trade_section, Vector2(0, 0), Vector2(868, 34), C_TRAD)

	var trd_ttl := Label.new()
	trd_ttl.text     = "Đề xuất đổi hàng:"
	trd_ttl.position = Vector2(12, 6)
	trd_ttl.size     = Vector2(154, 22)
	trd_ttl.add_theme_font_size_override("font_size", 15)
	trd_ttl.add_theme_color_override("font_color", C_TGRN)
	_trade_section.add_child(trd_ttl)

	_lbl_trade_desc = Label.new()
	_lbl_trade_desc.position = Vector2(176, 5)
	_lbl_trade_desc.size     = Vector2(680, 24)
	_lbl_trade_desc.add_theme_font_size_override("font_size", 16)
	_lbl_trade_desc.add_theme_color_override("font_color", C_TEXT)
	_trade_section.add_child(_lbl_trade_desc)


func _build_player_portrait() -> void:
	var lx := _bx + 34; var ly := _by + 78
	_r(Vector2(lx - 2, ly - 2), Vector2(PPW + 4, PPH + 4), C_FRAME)
	_r(Vector2(lx,     ly),     Vector2(PPW, PPH),          Color(0.08, 0.05, 0.03))
	var avatar_tex: Texture2D = load("res://assets/sprites/characters/nam_portrait.png")
	if avatar_tex:
		var portrait := TextureRect.new()
		portrait.texture    = avatar_tex
		portrait.position   = Vector2(lx, ly)
		portrait.size       = Vector2(PPW, PPH)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		_root.add_child(portrait)
	var lbl := _lbl("Nấm", lx, ly + PPH + 10, PPW, 26, 15)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", C_MUTE)


func _build_npc_portrait() -> void:
	# Chân dung NPC nằm gọn trong panel trung tâm.
	var rx := _bx + PANEL_W - PPW - 34; var ry := _by + 78
	_r(Vector2(rx - 2, ry - 2), Vector2(PPW + 4, PPH + 4), C_FRAME)
	_r(Vector2(rx,     ry),     Vector2(PPW, PPH),          Color(0.16, 0.11, 0.06))
	_rport_body = ColorRect.new()
	_rport_body.position = Vector2(rx + 20, ry + 78)
	_rport_body.size     = Vector2(88, 96)
	_rport_body.color    = Color(0.5, 0.3, 0.3)
	_root.add_child(_rport_body)
	_r(Vector2(rx + 32, ry + 24), Vector2(64, 50), C_SKIN)
	_mood_overlay = ColorRect.new()
	_mood_overlay.position = Vector2(rx, ry)
	_mood_overlay.size     = Vector2(PPW, PPH)
	_mood_overlay.color    = Color(0, 0, 0, 0)
	_root.add_child(_mood_overlay)
	_patience_bar = ColorRect.new()
	_patience_bar.position = Vector2(rx + (PPW - 160) * 0.5, ry + PPH + 10)
	_patience_bar.size     = Vector2(160, 8)
	_patience_bar.color    = C_TGRN
	_root.add_child(_patience_bar)
	_rport_name = _lbl("Khách", rx, ry + PPH + 26, PPW, 26, 15)
	_rport_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rport_name.add_theme_color_override("font_color", C_MUTE)


# ══════════════════════════════════════════════════════════════════════════════
# POPULATE — Phase 1
# ══════════════════════════════════════════════════════════════════════════════

func _refresh_weapons(weapons: Array) -> void:
	for child in _weapon_box.get_children():
		child.queue_free()
	for w: Dictionary in weapons:
		var btn := _btn(_weapon_label(w), C_BTN, C_BTNH, 15)
		btn.custom_minimum_size   = Vector2(PANEL_W - 72, 82)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment             = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_weapon_selected.bind(w))
		_weapon_box.add_child(btn)


func _weapon_label(w: Dictionary) -> String:
	return "%s\n    ATK %d  ·  MAG %d  ·  SPD %d  ·  DUR %d/%d  ·  Giá trị ~%dG" % [
		w.get("weapon_name", "???"),
		w.get("atk", 0), w.get("magic", 0), w.get("speed", 0),
		w.get("durability", 50), w.get("durability_max", 50),
		_weapon_value(w),
	]


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 2 — ĐÀM PHÁN GIÁ
# ══════════════════════════════════════════════════════════════════════════════

func _on_weapon_selected(weapon: Dictionary) -> void:
	if _resolving:
		return
	_resolving = true
	_chosen_weapon = weapon
	_offer_gold    = _calculate_offer(_customer, weapon)
	_trade_offer   = _roll_trade_offer(_customer)
	_phase         = Phase.PRICE
	_set_mood(Mood.NEUTRAL)

	# Cập nhật header
	_lbl_hdr.text = weapon.get("weapon_name", "???")
	_lbl_hdr.add_theme_color_override("font_color", C_TEXT)

	# Cập nhật dialogue → lời chào giá NPC
	var ctype: String = _customer.get("type", "")
	var offer_line: String = NPC_OFFER_LINES.get(ctype, "Tôi trả %dG.")
	var speech_text: String = offer_line % _offer_gold

	# Cập nhật phase 2 fields
	_lbl_wpn_name.text  = weapon.get("weapon_name", "???")
	_lbl_wpn_stats.text = "ATK %d  ·  MAG %d  ·  SPD %d  ·  DUR %d/%d  ·  Giá trị ước tính ~%dG" % [
		weapon.get("atk", 0), weapon.get("magic", 0), weapon.get("speed", 0),
		weapon.get("durability", 50), weapon.get("durability_max", 50),
		_weapon_value(weapon),
	]
	_lbl_npc_offer.text      = "%dG" % _offer_gold

	# Tính giới hạn giá và gợi ý cho vòng đàm phán này
	var val_w:    int   = _weapon_value(weapon)
	var budget_w: int   = _customer.get("budget_this_visit", 500)
	_npc_max_price  = mini(budget_w, int(val_w * _get_class_max_factor(_customer.get("type", ""))))
	_price_cap_hard = int(val_w * 1.6)
	_hint_min       = _offer_gold + 10
	_hint_max       = int(_npc_max_price * randf_range(0.82, 0.93))
	_lbl_hint.text  = "Gợi ý: ~%dG – %dG" % [_hint_min, _hint_max]
	var show_bargain_tip := not GameManager.has_tutorial_seen("first_price_hint_seen")
	if show_bargain_tip:
		_lbl_hint.text = "Tutorial: kéo giá trong khoảng gợi ý; quá cao làm khách mất kiên nhẫn."
		GameManager.mark_tutorial_seen("first_price_hint_seen")
	_refresh_slider_range()
	# Trade offer
	if not _trade_offer.is_empty():
		_lbl_trade_desc.text   = _trade_desc(_trade_offer)
		_trade_section.visible = true
		speech_text = TRADE_INTRO_LINES.get(ctype, "Tôi có thứ muốn đổi.")
	else:
		_trade_section.visible = false

	# Ẩn Phase 1, hiện Phase 2
	_weapon_box.visible  = false
	_btn_no_sale.visible = false
	_p2_root.visible     = true
	# Khởi tạo patience, proposals và đe dọa cho vòng đàm phán này
	_patience         = _customer.get("patience", 2)
	_proposals_used   = 0
	_threat_used      = false
	_threat_available = randf() < THREAT_APPEAR_RATE.get(_customer.get("type", ""), 0.0)
	_layout_p2_buttons(not _trade_offer.is_empty(), true, _threat_available)
	_update_negotiate_info()
	await _type_text(_lbl_npc_speech, speech_text)
	if visible:
		_resolving = false


func _layout_p2_buttons(
		has_trade: bool,
		show_propose: bool = true,
		show_threat: bool = false) -> void:
	var bx := _bx + 3
	var y  := _by + PANEL_H - 52
	var h  := 44

	# Ẩn tất cả trước
	for b: Button in [_btn_sell_npc, _btn_propose, _btn_threaten, _btn_trade, _btn_decline_p2]:
		b.visible = false

	# Xây danh sách nút cần hiện theo thứ tự
	var btns: Array = [_btn_sell_npc]
	if show_propose: btns.append(_btn_propose)
	if show_threat:  btns.append(_btn_threaten)
	if has_trade:    btns.append(_btn_trade)
	btns.append(_btn_decline_p2)

	# Chia đều chiều rộng, pixel dư dồn vào nút cuối
	const GAP  := 9
	var area := PANEL_W - 6
	var n      := btns.size()
	var btn_w  := int((area - GAP * (n - 1)) / n)
	var remain := area - GAP * (n - 1) - btn_w * n

	var x := bx
	for i: int in n:
		var b: Button = btns[i]
		b.position = Vector2(x, y)
		b.size     = Vector2(btn_w + (remain if i == n - 1 else 0), h)
		b.visible  = true
		x += btn_w + GAP

	_btn_sell_npc.text = "Bán giá NPC  ·  %dG" % _offer_gold


func _type_text(label: Label, text: String, speed: float = 0.032) -> void:
	label.text = ""
	for i: int in text.length():
		label.text = text.left(i + 1)
		await get_tree().create_timer(speed).timeout


func _set_mood(mood: Mood) -> void:
	if _mood_overlay == null:
		return
	match mood:
		Mood.NEUTRAL:
			_mood_overlay.color = Color(0, 0, 0, 0)
		Mood.HAPPY:
			_mood_overlay.color = Color(0.2, 0.8, 0.2, 0.30)
		Mood.THINKING:
			_mood_overlay.color = Color(0.6, 0.6, 0.0, 0.25)
		Mood.ANNOYED:
			_mood_overlay.color = Color(0.8, 0.4, 0.0, 0.30)
		Mood.ANGRY:
			_mood_overlay.color = Color(0.8, 0.1, 0.1, 0.40)


func _refresh_slider_range() -> void:
	var min_price := float(_offer_gold)
	var deal_end := float(maxi(_offer_gold, _npc_max_price))
	var max_price := _get_visible_slider_max(min_price, deal_end)
	_price_slider.min_value = min_price
	_price_slider.max_value = max_price
	_price_slider.value = clampf(float(maxi(_offer_gold, _hint_min)), min_price, max_price)
	_on_price_slider_changed(_price_slider.value)

	var instant_accept_end := clampf(float(int(_offer_gold * 1.05)), min_price, deal_end)
	var good_end := clampf(deal_end, min_price, max_price)
	_set_zone_rect(_zone_low_rect, min_price, instant_accept_end)
	if good_end > instant_accept_end:
		_set_zone_rect(_zone_good_rect, instant_accept_end, good_end)
	else:
		_set_zone_rect(_zone_good_rect, min_price, good_end)
	_set_zone_rect(_zone_high_rect, good_end, max_price)


func _get_visible_slider_max(min_price: float, deal_end: float) -> float:
	var hard_max := float(maxi(_offer_gold + 1, _price_cap_hard))
	var deal_span := maxf(1.0, deal_end - min_price)
	var pad := maxf(PRICE_VISIBLE_PAD_MIN, deal_span * PRICE_VISIBLE_PAD_RATIO)
	return clampf(deal_end + pad, min_price + 1.0, hard_max)


func _set_zone_rect(rect: ColorRect, start_price: float, end_price: float) -> void:
	var min_price := float(_price_slider.min_value)
	var max_price := float(_price_slider.max_value)
	var price_range := maxf(1.0, max_price - min_price)
	var start_ratio := clampf((start_price - min_price) / price_range, 0.0, 1.0)
	var end_ratio := clampf((end_price - min_price) / price_range, 0.0, 1.0)
	rect.position.x = _price_slider.position.x + PRICE_TRACK_W * start_ratio
	rect.size.x = PRICE_TRACK_W * maxf(0.0, end_ratio - start_ratio)


func _on_price_slider_changed(value: float) -> void:
	_lbl_price_display.text = "%dG" % int(value)


func _get_proposed_price() -> int:
	return int(_price_slider.value)


# ── Xử lý kết quả ─────────────────────────────────────────────────────────────

func _on_sell_npc_price() -> void:
	if _resolving: return
	_resolving = true
	var ctype: String = _customer.get("type", "")
	_set_mood(Mood.HAPPY)
	await _type_text(_lbl_npc_speech, ACCEPT_LINES.get(ctype, "Cảm ơn!"))
	await get_tree().create_timer(1.1).timeout
	close_ui()
	deal_accepted.emit(_chosen_weapon, _offer_gold)


func _on_propose() -> void:
	if _resolving: return
	_resolving = true

	if _proposals_used >= PROPOSALS_MAX:
		_patience  = 0
		_update_negotiate_info()
		var ctype_imm: String = _customer.get("type", "")
		_set_mood(Mood.ANGRY)
		await _type_text(_lbl_npc_speech, HAGGLE_TOO_HIGH_LINES.get(ctype_imm, "Quá đắt! Tôi đi."))
		await get_tree().create_timer(1.2).timeout
		close_ui()
		deal_declined.emit()
		return

	var proposed: int = _get_proposed_price()
	var ctype:    String = _customer.get("type", "")
	var thinking_line: String = THINKING_LINES.get(ctype, "")
	if not thinking_line.is_empty():
		_set_mood(Mood.THINKING)
		await _type_text(_lbl_npc_speech, thinking_line)
		await get_tree().create_timer(1.2).timeout
		if not visible:
			return

	_proposals_used += 1
	_update_negotiate_info()

	# Trần cứng — giá vô lý, trừ patience ngay và không mặc cả thêm
	if proposed > _price_cap_hard:
		_patience -= 1
		_update_negotiate_info()
		_set_mood(Mood.ANGRY)
		if _patience <= 0:
			await _type_text(_lbl_npc_speech, HAGGLE_TOO_HIGH_LINES.get(ctype, "Quá đắt! Tôi đi."))
			await get_tree().create_timer(1.2).timeout
			close_ui()
			deal_declined.emit()
		else:
			await _type_text(_lbl_npc_speech, "Giá đó... không ai trả nổi đâu. Nghiêm túc lại đi.")
			_check_proposal_limit()
			_resolving = false
		return

	if proposed <= _offer_gold:
		# Player tự bán dưới giá NPC → chấp nhận ngay
		_set_mood(Mood.HAPPY)
		await _type_text(_lbl_npc_speech, ACCEPT_LINES.get(ctype, "Cảm ơn!"))
		await get_tree().create_timer(1.1).timeout
		close_ui()
		deal_accepted.emit(_chosen_weapon, proposed)

	elif proposed <= int(_offer_gold * 1.05):
		# Sát với giá NPC (≤5%) → chấp nhận, không mặc cả thêm
		_set_mood(Mood.HAPPY)
		await _type_text(_lbl_npc_speech, "Hm... %dG thôi, được rồi." % proposed)
		await get_tree().create_timer(1.1).timeout
		close_ui()
		deal_accepted.emit(_chosen_weapon, proposed)

	elif proposed <= _npc_max_price:
		# Trong tầm với → NPC trả giá lại (không chấp nhận thẳng)
		var step:    float = randf_range(0.38, 0.55)
		var counter: int   = _offer_gold + int((proposed - _offer_gold) * step)
		counter     = maxi(counter, _offer_gold + 1)
		_offer_gold = counter
		_lbl_npc_offer.text = "%dG" % counter
		_btn_sell_npc.text  = "Bán giá NPC  ·  %dG" % counter
		# Cập nhật gợi ý sau khi NPC đã nâng giá
		_hint_min      = counter + 1
		_lbl_hint.text = "Gợi ý: ~%dG – %dG" % [_hint_min, _hint_max]
		_refresh_slider_range()
		var counter_line: String = HAGGLE_COUNTER_LINES.get(ctype, "Tôi chỉ trả %dG.")
		_set_mood(Mood.ANNOYED)
		await _type_text(_lbl_npc_speech, counter_line % counter)
		_check_proposal_limit()
		_resolving = false

	else:
		# Vượt quá khả năng → patience giảm, NPC bực bội
		_patience -= 1
		_update_negotiate_info()
		if _patience <= 1:
			_set_mood(Mood.ANGRY)
		else:
			_set_mood(Mood.ANNOYED)
		if _patience <= 0:
			await _type_text(_lbl_npc_speech, HAGGLE_TOO_HIGH_LINES.get(ctype, "Quá đắt! Tôi đi."))
			await get_tree().create_timer(1.2).timeout
			close_ui()
			deal_declined.emit()
		else:
			await _type_text(_lbl_npc_speech, HAGGLE_FRUSTRATED_LINES.get(ctype, "Giá quá cao!"))
			_check_proposal_limit()
			_resolving = false


func _on_trade_accept() -> void:
	if _resolving: return
	_resolving = true
	_set_mood(Mood.HAPPY)
	await _type_text(_lbl_npc_speech, "Tuyệt! Trao đổi thành công.")
	await get_tree().create_timer(1.1).timeout
	close_ui()
	trade_accepted.emit(_chosen_weapon, _trade_offer)


func _on_threaten() -> void:
	if _resolving or _threat_used: return
	_resolving         = true
	_threat_used      = true
	_threat_available = false

	var ctype:    String = _customer.get("type", "")
	var success:  bool   = randf() < THREAT_SUCCESS_RATE.get(ctype, 0.0)
	var rep_loss: int

	if success:
		rep_loss     = randi_range(8, 13)
		_patience   += randi_range(1, 2)
		_npc_max_price = int(_npc_max_price * randf_range(1.15, 1.30))
		_hint_max   = int(_npc_max_price * randf_range(0.82, 0.93))
		_lbl_hint.text = "Gợi ý: ~%dG – %dG" % [_hint_min, _hint_max]
		_refresh_slider_range()
		_set_mood(Mood.ANNOYED)
		await _type_text(_lbl_npc_speech, THREAT_SUCCESS_LINES.get(ctype, "...(run rẩy) Vâng..."))
		_update_negotiate_info()
	else:
		rep_loss   = randi_range(16, 24)
		_patience -= 1
		_update_negotiate_info()
		var fail_line: String = THREAT_FAIL_LINES.get(ctype, "Không! Tôi đi!")
		if _patience <= 0:
			_resolving = true
			_set_mood(Mood.ANGRY)
			await _type_text(_lbl_npc_speech, fail_line)
			_show_rep_loss(rep_loss)
			await get_tree().create_timer(1.4).timeout
			close_ui()
			deal_declined.emit()
			return
		if _patience <= 1:
			_set_mood(Mood.ANGRY)
		else:
			_set_mood(Mood.ANNOYED)
		await _type_text(_lbl_npc_speech, fail_line)

	# Trừ uy tín (luôn xảy ra dù thành công hay thất bại)
	_show_rep_loss(rep_loss)
	GameManager.add_reputation(-rep_loss)

	_layout_p2_buttons(not _trade_offer.is_empty(), _proposals_used < PROPOSALS_MAX, false)
	_resolving = false


func _show_rep_loss(amount: int) -> void:
	_lbl_negotiate_info.text = "Uy tín  −%d  |  " % amount + _lbl_negotiate_info.text
	_lbl_negotiate_info.add_theme_color_override("font_color", Color(0.90, 0.32, 0.22))


func _on_decline() -> void:
	if _resolving: return
	_resolving = true
	var ctype: String = _customer.get("type", "")
	if _phase == Phase.PRICE:
		await _type_text(_lbl_npc_speech, DECLINE_LINES.get(ctype, "Không sao."))
	else:
		await _type_text(_lbl_npc_speech, DECLINE_LINES.get(ctype, "Không sao."))
	await get_tree().create_timer(0.9).timeout
	close_ui()
	deal_declined.emit()


# ══════════════════════════════════════════════════════════════════════════════
# TRADE ROLL
# ══════════════════════════════════════════════════════════════════════════════

func _roll_trade_offer(customer: Dictionary) -> Dictionary:
	var ctype: String = customer.get("type", "")
	var rate:  float  = TRADE_RATES.get(ctype, 0.10)
	if randf() > rate:
		return {}
	return TRADE_OFFER_POOL[randi() % TRADE_OFFER_POOL.size()].duplicate()


func _trade_desc(offer: Dictionary) -> String:
	if offer.get("type", "") == "material":
		return "%d×  %s" % [offer.get("amount", 1), offer.get("name", "???")]
	var rarity: int = offer.get("rarity", 4)
	var stars   := "★".repeat(rarity) + "☆".repeat(5 - rarity)
	return "%s  [Hỏng - Độ bền 0/50]  %s" % [offer.get("name", "???"), stars]


# ══════════════════════════════════════════════════════════════════════════════
# PRICING
# ══════════════════════════════════════════════════════════════════════════════

func _calculate_offer(customer: Dictionary, weapon: Dictionary) -> int:
	var val:    int   = _weapon_value(weapon)
	var budget: int   = customer.get("budget_this_visit", 500)
	var factor: float = randf_range(0.60, 0.80)
	if weapon.get("rarity_tier", 1) < customer.get("min_weapon_rarity", 1):
		factor *= 0.55
	return mini(int(val * factor), budget)


func _weapon_value(w: Dictionary) -> int:
	if w.has("sell_value"):
		return w["sell_value"]
	# Fallback cho vũ khí cũ chưa có sell_value (save data trước Ticket B)
	return (w.get("atk", 0) + w.get("magic", 0)) * 28 \
		+ w.get("rarity_tier", 1) * 140 \
		+ w.get("speed", 5) * 6


# Hệ số × giá trị vũ khí → giá tối đa NPC class đó sẵn sàng trả.
# Class giàu (ve_binh, dao_si) trả cao hơn giá trị; class nghèo (nong_dan) trả thấp hơn.
func _get_class_max_factor(ctype: String) -> float:
	var factor: float
	match ctype:
		"ve_binh":
			factor = randf_range(1.35, 1.50)   # ngân khố hoàng gia
		"dao_si":
			factor = randf_range(1.25, 1.40)   # giàu, cần hàng hiếm
		"thich_khach":
			factor = randf_range(1.20, 1.35)   # tiền nhiều, ít kiên nhẫn
		"vo_tang":
			factor = randf_range(1.15, 1.30)
		"hiep_khach":
			factor = randf_range(1.10, 1.25)
		"thu_ve":
			factor = randf_range(1.05, 1.20)
		"tho_san":
			factor = randf_range(1.00, 1.15)
		"thuong_nhan":
			factor = randf_range(0.95, 1.10)   # cần lời, không trả cao
		"nong_dan":
			factor = randf_range(0.80, 0.95)   # tiền ít, trả dưới giá trị
		_:
			factor = randf_range(1.00, 1.15)
	return factor


# ══════════════════════════════════════════════════════════════════════════════
# NEGOTIATE INFO
# ══════════════════════════════════════════════════════════════════════════════

func _update_negotiate_info() -> void:
	var max_p    : int = _customer.get("patience", 2)
	var dots_on  : String = "●".repeat(_patience)
	var dots_off : String = "○".repeat(maxi(0, max_p - _patience))
	var left     : int = PROPOSALS_MAX - _proposals_used
	_lbl_negotiate_info.text = "Lượt còn: %d/%d  ·  Kiên nhẫn: %s%s" % [
		left, PROPOSALS_MAX, dots_on, dots_off,
	]
	if _patience <= 1:
		_lbl_negotiate_info.add_theme_color_override("font_color", Color(0.90, 0.32, 0.22))
		_set_mood(Mood.ANGRY)
	elif left <= 1:
		_lbl_negotiate_info.add_theme_color_override("font_color", Color(0.90, 0.72, 0.22))
	else:
		_lbl_negotiate_info.add_theme_color_override("font_color", C_MUTE)
	if _patience_bar != null:
		var ratio := float(_patience) / float(maxi(1, _customer.get("patience", 2)))
		_patience_bar.size.x = 160.0 * ratio
		_patience_bar.color = Color(1.0 - ratio, ratio * 0.8, 0.1)


func _check_proposal_limit() -> void:
	if _proposals_used >= PROPOSALS_MAX:
		_layout_p2_buttons(not _trade_offer.is_empty(), false, _threat_available and not _threat_used)


# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _r(pos: Vector2, sz: Vector2, color: Color) -> void:
	var c := ColorRect.new()
	c.color = color; c.position = pos; c.size = sz
	_root.add_child(c)


func _r_in(parent: Control, pos: Vector2, sz: Vector2, color: Color) -> void:
	var c := ColorRect.new()
	c.color = color; c.position = pos; c.size = sz
	parent.add_child(c)


func _dialogue_box(pos: Vector2, sz: Vector2) -> void:
	_r(pos, sz, C_SPCH)
	_r(Vector2(pos.x, pos.y), Vector2(sz.x, 1), C_SEP)
	_r(Vector2(pos.x, pos.y + sz.y - 1), Vector2(sz.x, 1), C_SEP)
	_r(Vector2(pos.x, pos.y), Vector2(1, sz.y), C_SEP)
	_r(Vector2(pos.x + sz.x - 1, pos.y), Vector2(1, sz.y), C_SEP)


func _lbl(text: String, x: int, y: int, w: int, h: int, font_size: int) -> Label:
	var l := Label.new()
	l.text = text; l.position = Vector2(x, y); l.size = Vector2(w, h)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", C_TEXT)
	_root.add_child(l)
	return l


func _btn(label: String, c_norm: Color, c_hover: Color, font_size: int = 15) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_color_override("font_color",       C_TEXT)
	btn.add_theme_color_override("font_hover_color", C_TEXT)
	btn.add_theme_font_size_override("font_size", font_size)
	for state: String in ["normal", "focus"]:
		var s := StyleBoxFlat.new()
		s.bg_color = c_norm; s.set_corner_radius_all(5)
		s.content_margin_left = 10.0; s.content_margin_right  = 10.0
		s.content_margin_top  = 5.0;  s.content_margin_bottom = 5.0
		btn.add_theme_stylebox_override(state, s)
	for state: String in ["hover", "pressed"]:
		var s := StyleBoxFlat.new()
		s.bg_color = c_hover; s.set_corner_radius_all(5)
		s.content_margin_left = 10.0; s.content_margin_right  = 10.0
		s.content_margin_top  = 5.0;  s.content_margin_bottom = 5.0
		btn.add_theme_stylebox_override(state, s)
	return btn
