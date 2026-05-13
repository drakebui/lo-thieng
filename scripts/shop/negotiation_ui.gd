# negotiation_ui.gd
# Recettear-style trading — bán trong suốt, thấy shop phía sau
# Chân dung chủ tiệm BÊN TRÁI · Panel trung tâm · Chân dung NPC BÊN PHẢI
class_name NegotiationUI
extends CanvasLayer

# ══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ══════════════════════════════════════════════════════════════════════════════

signal deal_accepted(weapon: Dictionary, gold: int)
signal trade_accepted(weapon: Dictionary, trade_offer: Dictionary)
signal deal_declined()

# ══════════════════════════════════════════════════════════════════════════════
# LAYOUT — toạ độ tuyệt đối trong không gian root 1024×768
# ══════════════════════════════════════════════════════════════════════════════

# Panel outer = 744×526 (inner 740×522 + 2px border mỗi cạnh)
# Vị trí tính động trong _build_ui() dựa trên viewport thực (_bx, _by)
const PPW := 116; const PPH := 196   # kích thước khung chân dung
const PROPOSALS_MAX := 3              # tối đa số lần player đề xuất giá

# ══════════════════════════════════════════════════════════════════════════════
# PALETTE
# ══════════════════════════════════════════════════════════════════════════════

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
const C_THRT  := Color(0.48, 0.22, 0.06)   # nút đe dọa
const C_THRTH := Color(0.66, 0.32, 0.10)
const C_SKIN  := Color(0.82, 0.66, 0.50)
const C_SHOP  := Color(0.28, 0.42, 0.62)
const C_APRON := Color(0.56, 0.34, 0.14)

# ══════════════════════════════════════════════════════════════════════════════
# AVATAR COLORS
# ══════════════════════════════════════════════════════════════════════════════

const CUST_COLORS: Dictionary = {
	"hiep_khach":  Color(0.20, 0.45, 0.72),
	"thu_ve":      Color(0.48, 0.50, 0.56),
	"vo_tang":     Color(0.72, 0.62, 0.22),
	"thich_khach": Color(0.48, 0.22, 0.58),
	"dao_si":      Color(0.22, 0.60, 0.58),
	"thuong_nhan": Color(0.68, 0.48, 0.18),
	"nong_dan":    Color(0.40, 0.55, 0.28),
	"ve_binh":     Color(0.28, 0.34, 0.60),
}

# ══════════════════════════════════════════════════════════════════════════════
# DIALOGUE TABLES
# ══════════════════════════════════════════════════════════════════════════════

const DIALOGUES: Dictionary = {
	"hiep_khach":  "Tôi cần một thanh kiếm tốt cho hành trình dài...",
	"thu_ve":      "Cần thứ gì đủ nặng để giữ tuyến đầu.",
	"vo_tang":     "Không cần hoa mỹ — dùng được là đủ.",
	"thich_khach": "...Thứ gì đó nhanh. Đừng hỏi để làm gì.",
	"dao_si":      "Huyền lực quan trọng hơn vật lý.",
	"thuong_nhan": "Tôi mua để bán lại — giá phải hợp lý.",
	"nong_dan":    "Cái gì bền không? Tiền không nhiều.",
	"ve_binh":     "Tiêu chuẩn hoàng gia. Chất lượng trên hết.",
}

const NPC_OFFER_LINES: Dictionary = {
	"hiep_khach":  "Tôi trả %dG thôi — đủ xài trên đường rồi.",
	"thu_ve":      "%dG. Không hơn, quân đội không có ngân sách dư.",
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
	"vo_tang":     "Không hợp lý. Tôi đi.",
	"thich_khach": "Không. Tạm biệt.",
	"dao_si":      "Quá đắt, không xứng huyền lực. Tôi đi.",
	"thuong_nhan": "Không lời được. Tôi qua chỗ khác.",
	"nong_dan":    "Tôi không đủ tiền... xin lỗi bác.",
	"ve_binh":     "Không đạt tiêu chuẩn ngân sách hoàng gia.",
}

const ACCEPT_LINES: Dictionary = {
	"hiep_khach":  "Được rồi! Hàng tốt, giá hợp lý. Cảm ơn!",
	"thu_ve":      "Hợp lý. Giao dịch thành công.",
	"vo_tang":     "Tốt. Tôi sẽ dùng nó xứng đáng.",
	"thich_khach": "...Ổn. Đây tiền.",
	"dao_si":      "Tuyệt! Huyền lực trong đây rất mạnh.",
	"thuong_nhan": "Giá phải chăng, tôi lấy.",
	"nong_dan":    "Cảm ơn bác thợ! Vợ tôi sẽ vui lắm.",
	"ve_binh":     "Giao dịch hoàn tất. Hoàng gia hài lòng.",
}

const DECLINE_LINES: Dictionary = {
	"hiep_khach":  "Thôi vậy... Có lẽ lần sau.",
	"thu_ve":      "Không đủ tiêu chuẩn. Tôi đi chỗ khác.",
	"vo_tang":     "Không hợp ý. Cảm ơn vẫn vậy.",
	"thich_khach": "Không. Tạm biệt.",
	"dao_si":      "Tiếc. Lần sau nhé.",
	"thuong_nhan": "Giá quá cao, không lời được.",
	"nong_dan":    "Quá đắt với tôi. Xin lỗi bác.",
	"ve_binh":     "Không đạt chuẩn. Rút lui.",
}

# Bực bội nhưng chưa bỏ đi — patience còn > 0 sau khi bị giá quá cao
const HAGGLE_FRUSTRATED_LINES: Dictionary = {
	"hiep_khach":  "Giá cao quá! Nhưng... tôi vẫn muốn thứ này. Xem lại đi.",
	"thu_ve":      "Vượt ngân sách rồi. Cố hạ xuống không?",
	"vo_tang":     "Không hợp lý. Tôi còn chờ thêm một chút.",
	"thich_khach": "...Đắt quá. Lần cuối đấy.",
	"dao_si":      "Huyền lực không đáng giá thế. Thử lại đi.",
	"thuong_nhan": "Tôi không lời được. Bớt xuống không?",
	"nong_dan":    "Trời ơi... bác cố thêm được không?",
	"ve_binh":     "Vượt ngân sách hoàng gia. Hạ xuống đi.",
}

# ══════════════════════════════════════════════════════════════════════════════
# THREATEN SYSTEM
# ══════════════════════════════════════════════════════════════════════════════

# Xác suất nút đe dọa xuất hiện theo class (0 = không bao giờ)
const THREAT_APPEAR_RATE: Dictionary = {
	"nong_dan":    0.70,
	"thuong_nhan": 0.55,
	"hiep_khach":  0.30,
	"vo_tang":     0.20,
	"dao_si":      0.15,
	"thu_ve":      0.05,
	"thich_khach": 0.0,   # sát thủ — quá nguy hiểm
	"ve_binh":     0.0,   # vệ binh hoàng gia — liên lụy pháp lý
}

# Xác suất đe dọa thành công theo class
const THREAT_SUCCESS_RATE: Dictionary = {
	"nong_dan":    0.85,
	"thuong_nhan": 0.68,
	"hiep_khach":  0.38,
	"vo_tang":     0.28,
	"dao_si":      0.22,
	"thu_ve":      0.08,
	"thich_khach": 0.0,
	"ve_binh":     0.0,
}

const THREAT_SUCCESS_LINES: Dictionary = {
	"hiep_khach":  "...(nghiến răng) Lần này thôi. Đừng tưởng ta sợ mi.",
	"thu_ve":      "...(căng thẳng) Lần này bỏ qua. Nhưng đừng thử lại.",
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
	"hiep_khach": 0.10, "thu_ve":      0.10, "vo_tang":    0.15,
	"thich_khach": 0.20, "dao_si":     0.25, "thuong_nhan": 0.35,
	"nong_dan":   0.05, "ve_binh":     0.10,
}

const TRADE_OFFER_POOL: Array = [
	{"type": "material", "name": "Quặng Sắt",            "amount": 15},
	{"type": "material", "name": "Than Hầm Mỏ",          "amount": 10},
	{"type": "material", "name": "Da Thú Rừng",          "amount": 8},
	{"type": "material", "name": "Đá Lửa Núi Lửa",      "amount": 6},
	{"type": "material", "name": "Tinh Thể Băng",        "amount": 5},
	{"type": "item",     "name": "Kiếm Cổ Đại",          "rarity": 4},
	{"type": "item",     "name": "Đoản Đao Huyền Thoại", "rarity": 5},
	{"type": "item",     "name": "Búa Thần Cổ",          "rarity": 5},
]

const TRADE_INTRO_LINES: Dictionary = {
	"hiep_khach":  "À... thật ra tôi có thứ này muốn đổi. Chịu không?",
	"thu_ve":      "Quân đội cấp cho tôi vật này. Đổi hàng được không?",
	"vo_tang":     "Tôi nhặt được thứ này. Đổi lấy vũ khí nhé?",
	"thich_khach": "...Tôi có thứ đáng giá hơn tiền. Muốn đổi không?",
	"dao_si":      "Tôi có nguyên liệu huyền bí. Trao đổi nhé?",
	"thuong_nhan": "Thay vì tiền — tôi có hàng đổi. Lợi hơn cho cả hai.",
	"nong_dan":    "Tiền không đủ... tôi có mấy thứ này có đổi được không?",
	"ve_binh":     "Kho cũ hoàng gia có vật phẩm muốn trao đổi.",
}

# ══════════════════════════════════════════════════════════════════════════════
# STATE
# ══════════════════════════════════════════════════════════════════════════════

enum Phase { SELECT, PRICE }

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

# ══════════════════════════════════════════════════════════════════════════════
# NODE REFS
# ══════════════════════════════════════════════════════════════════════════════

var _root:           Control

# Gốc panel — tính động từ viewport, dùng trong layout và buttons
var _bx:             int = 0   # outer border left x
var _by:             int = 0   # outer border top y

# Chân dung
var _rport_body:     ColorRect
var _rport_name:     Label

# Header + dialogue (luôn hiển thị)
var _lbl_hdr:        Label
var _lbl_npc_speech: Label

# Phase 1
var _weapon_box:     VBoxContainer
var _btn_no_sale:    Button

# Phase 2
var _p2_root:            Control
var _lbl_wpn_name:       Label
var _lbl_wpn_stats:      Label
var _lbl_negotiate_info: Label   # "Lượt còn: X/3 · Kiên nhẫn: ●●○"
var _lbl_npc_offer:      Label
var _price_input:    LineEdit
var _lbl_hint:       Label    # gợi ý khoảng giá hợp lý
var _trade_section:  Control
var _lbl_trade_desc: Label
var _btn_sell_npc:   Button
var _btn_propose:    Button
var _btn_threaten:   Button
var _btn_trade:      Button
var _btn_decline_p2: Button

# ══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	layer   = 20
	visible = false
	_build_ui()


# ══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ══════════════════════════════════════════════════════════════════════════════

func present(customer: Dictionary, weapon: Dictionary) -> void:
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


func close_ui() -> void:
	visible = false


# ══════════════════════════════════════════════════════════════════════════════
# BUILD UI
# ══════════════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	# ── Overlay fill viewport thực ────────────────────────────────────────────
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = C_OVR
	_root.add_child(ov)

	# Tính gốc panel căn giữa theo viewport thực
	var vp  := get_viewport().get_visible_rect()
	_bx = int((vp.size.x - 744.0) * 0.5)   # outer border left
	_by = int((vp.size.y - 526.0) * 0.5)   # outer border top
	var px  := _bx + 2   # inner panel left
	var py  := _by + 2   # inner panel top

	# ── Viền vàng panel ───────────────────────────────────────────────────────
	_r(Vector2(_bx,       _by),       Vector2(744,   2), C_FRAME)
	_r(Vector2(_bx,       _by + 524), Vector2(744,   2), C_FRAME)
	_r(Vector2(_bx,       _by),       Vector2(  2, 526), C_FRAME)
	_r(Vector2(_bx + 742, _by),       Vector2(  2, 526), C_FRAME)

	# ── Nền panel ────────────────────────────────────────────────────────────
	_r(Vector2(px, py), Vector2(740, 522), C_PANEL)

	# ── Header (py .. py+50) ──────────────────────────────────────────────────
	_r(Vector2(px, py),       Vector2(740,  50), C_HDR)
	_r(Vector2(_bx, py + 50), Vector2(744,   1), C_SEP)
	_lbl_hdr = _lbl("", px + 8, py + 8, 724, 36, 18)
	_lbl_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# ── Dialogue bubble (py+51 .. py+140) ────────────────────────────────────
	_r(Vector2(px, py + 51),        Vector2(740, 88), C_SPCH)
	_r(Vector2(_bx, py + 139),      Vector2(744,  1), C_SEP)
	_lbl_npc_speech = _lbl("", px + 14, py + 57, 712, 76, 16)
	_lbl_npc_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_npc_speech.add_theme_color_override("font_color", C_TEXT)

	# ── Phase 1: danh sách vũ khí (py+140 .. py+460) ─────────────────────────
	var p1_title := _lbl("Chọn vật phẩm muốn đề xuất:", px + 8, py + 146, 724, 24, 14)
	p1_title.add_theme_color_override("font_color", C_MUTE)

	_weapon_box = VBoxContainer.new()
	_weapon_box.position = Vector2(px, py + 174)
	_weapon_box.size     = Vector2(740, 284)
	_weapon_box.add_theme_constant_override("separation", 12)
	_root.add_child(_weapon_box)

	# ── Phase 2: khu vực đàm phán (py+140 .. py+460) ─────────────────────────
	_p2_root = Control.new()
	_p2_root.position = Vector2(px, py + 140)
	_p2_root.size     = Vector2(740, 320)
	_p2_root.visible  = false
	_root.add_child(_p2_root)
	_build_phase2_layout()

	# ── Separator trước nút ───────────────────────────────────────────────────
	_r(Vector2(_bx, py + 460), Vector2(744, 1), C_SEP)

	# ── Nút Phase 1 ──────────────────────────────────────────────────────────
	_btn_no_sale = _btn("Không bán lần này", C_REJ, C_REJH, 15)
	_btn_no_sale.position = Vector2(_bx + 742 - 220, py + 464)
	_btn_no_sale.size     = Vector2(210, 52)
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


func _build_phase2_layout() -> void:
	# Tên vũ khí
	_lbl_wpn_name = Label.new()
	_lbl_wpn_name.position = Vector2(8, 4)
	_lbl_wpn_name.size     = Vector2(724, 30)
	_lbl_wpn_name.add_theme_font_size_override("font_size", 17)
	_lbl_wpn_name.add_theme_color_override("font_color", C_TEXT)
	_p2_root.add_child(_lbl_wpn_name)

	# Chỉ số vũ khí (thu hẹp để nhường chỗ cho info label bên phải)
	_lbl_wpn_stats = Label.new()
	_lbl_wpn_stats.position = Vector2(8, 36)
	_lbl_wpn_stats.size     = Vector2(360, 20)
	_lbl_wpn_stats.add_theme_font_size_override("font_size", 12)
	_lbl_wpn_stats.add_theme_color_override("font_color", C_MUTE)
	_p2_root.add_child(_lbl_wpn_stats)

	# Lượt đề xuất + kiên nhẫn NPC (cùng hàng với stats, căn phải)
	_lbl_negotiate_info = Label.new()
	_lbl_negotiate_info.position           = Vector2(370, 36)
	_lbl_negotiate_info.size               = Vector2(362, 20)
	_lbl_negotiate_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_negotiate_info.add_theme_font_size_override("font_size", 12)
	_lbl_negotiate_info.add_theme_color_override("font_color", C_MUTE)
	_p2_root.add_child(_lbl_negotiate_info)

	_r_in(_p2_root, Vector2(0, 60), Vector2(740, 1), C_SEP)

	# Giá NPC đề nghị
	var lbl_ofr: Label = Label.new()
	lbl_ofr.text     = "NPC đề nghị:"
	lbl_ofr.position = Vector2(8, 64)
	lbl_ofr.size     = Vector2(724, 20)
	lbl_ofr.add_theme_font_size_override("font_size", 13)
	lbl_ofr.add_theme_color_override("font_color", C_MUTE)
	_p2_root.add_child(lbl_ofr)

	_lbl_npc_offer = Label.new()
	_lbl_npc_offer.position = Vector2(8, 84)
	_lbl_npc_offer.size     = Vector2(380, 64)
	_lbl_npc_offer.add_theme_font_size_override("font_size", 52)
	_lbl_npc_offer.add_theme_color_override("font_color", C_GOLD)
	_p2_root.add_child(_lbl_npc_offer)

	_r_in(_p2_root, Vector2(0, 152), Vector2(740, 1), C_SEP)

	# Ô nhập giá player
	var lbl_inp: Label = Label.new()
	lbl_inp.text     = "Nhập giá của bạn:"
	lbl_inp.position = Vector2(8, 156)
	lbl_inp.size     = Vector2(280, 20)
	lbl_inp.add_theme_font_size_override("font_size", 13)
	lbl_inp.add_theme_color_override("font_color", C_MUTE)
	_p2_root.add_child(lbl_inp)

	# Gợi ý khoảng giá — cập nhật mỗi lần weapon được chọn và sau mỗi counter
	_lbl_hint = Label.new()
	_lbl_hint.position = Vector2(292, 156)
	_lbl_hint.size     = Vector2(440, 20)
	_lbl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_hint.add_theme_font_size_override("font_size", 13)
	_lbl_hint.add_theme_color_override("font_color", Color(0.54, 0.78, 0.54))
	_p2_root.add_child(_lbl_hint)

	_price_input = LineEdit.new()
	_price_input.position         = Vector2(8, 178)
	_price_input.size             = Vector2(670, 50)
	_price_input.placeholder_text = "0"
	_price_input.max_length       = 7
	_price_input.add_theme_font_size_override("font_size", 24)
	_price_input.add_theme_color_override("font_color", C_TEXT)
	_price_input.add_theme_color_override("caret_color", C_GOLD)
	var le_s := StyleBoxFlat.new()
	le_s.bg_color            = C_IBKG
	le_s.border_width_bottom = 2
	le_s.border_color        = C_SEP
	le_s.set_corner_radius_all(4)
	le_s.content_margin_left = 12.0
	_price_input.add_theme_stylebox_override("normal", le_s)
	_price_input.add_theme_stylebox_override("focus",  le_s)
	_p2_root.add_child(_price_input)

	var g_lbl := Label.new()
	g_lbl.text     = "G"
	g_lbl.position = Vector2(682, 178)
	g_lbl.size     = Vector2(50, 50)
	g_lbl.add_theme_font_size_override("font_size", 24)
	g_lbl.add_theme_color_override("font_color", C_GOLD)
	_p2_root.add_child(g_lbl)

	_r_in(_p2_root, Vector2(0, 232), Vector2(740, 1), C_SEP)

	# Khu vực đổi hàng (ẩn khi không có trade)
	_trade_section = Control.new()
	_trade_section.position = Vector2(0, 236)
	_trade_section.size     = Vector2(740, 56)
	_trade_section.visible  = false
	_p2_root.add_child(_trade_section)

	_r_in(_trade_section, Vector2(0, 0), Vector2(740, 56), C_TRAD)

	var trd_ttl := Label.new()
	trd_ttl.text     = "Đề xuất đổi hàng:"
	trd_ttl.position = Vector2(14, 6)
	trd_ttl.size     = Vector2(712, 20)
	trd_ttl.add_theme_font_size_override("font_size", 13)
	trd_ttl.add_theme_color_override("font_color", C_TGRN)
	_trade_section.add_child(trd_ttl)

	_lbl_trade_desc = Label.new()
	_lbl_trade_desc.position = Vector2(14, 28)
	_lbl_trade_desc.size     = Vector2(712, 24)
	_lbl_trade_desc.add_theme_font_size_override("font_size", 17)
	_lbl_trade_desc.add_theme_color_override("font_color", C_TEXT)
	_trade_section.add_child(_lbl_trade_desc)


func _build_player_portrait() -> void:
	# Tọa độ tính từ _bx/_by: chân dung trái cách panel 112px
	var lx := _bx - 112; var ly := _by + 48
	_r(Vector2(lx - 2, ly - 2), Vector2(PPW + 4, PPH + 4), C_FRAME)
	_r(Vector2(lx,     ly),     Vector2(PPW, PPH),          Color(0.16, 0.11, 0.06))
	_r(Vector2(lx + 18, ly + 60), Vector2(80, 100), C_SHOP)
	_r(Vector2(lx + 30, ly + 80), Vector2(56,  80), C_APRON)
	_r(Vector2(lx + 28, ly + 18), Vector2(60,  42), C_SKIN)
	var lbl := _lbl("Chủ Tiệm", lx, ly + PPH + 6, PPW, 22, 13)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", C_MUTE)


func _build_npc_portrait() -> void:
	# Chân dung phải: bắt đầu ngay sau cạnh phải panel
	var rx := _bx + 740; var ry := _by + 48
	_r(Vector2(rx - 2, ry - 2), Vector2(PPW + 4, PPH + 4), C_FRAME)
	_r(Vector2(rx,     ry),     Vector2(PPW, PPH),          Color(0.16, 0.11, 0.06))
	_rport_body = ColorRect.new()
	_rport_body.position = Vector2(rx + 18, ry + 60)
	_rport_body.size     = Vector2(80, 100)
	_rport_body.color    = Color(0.5, 0.3, 0.3)
	_root.add_child(_rport_body)
	_r(Vector2(rx + 28, ry + 18), Vector2(60, 42), C_SKIN)
	_rport_name = _lbl("Khách", rx, ry + PPH + 6, PPW, 22, 13)
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
		btn.custom_minimum_size   = Vector2(740, 88)
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
	_chosen_weapon = weapon
	_offer_gold    = _calculate_offer(_customer, weapon)
	_trade_offer   = _roll_trade_offer(_customer)
	_phase         = Phase.PRICE

	# Cập nhật header
	_lbl_hdr.text = weapon.get("weapon_name", "???")
	_lbl_hdr.add_theme_color_override("font_color", C_TEXT)

	# Cập nhật dialogue → lời chào giá NPC
	var ctype: String = _customer.get("type", "")
	var offer_line: String = NPC_OFFER_LINES.get(ctype, "Tôi trả %dG.")
	_lbl_npc_speech.text = offer_line % _offer_gold

	# Cập nhật phase 2 fields
	_lbl_wpn_name.text  = weapon.get("weapon_name", "???")
	_lbl_wpn_stats.text = "ATK %d  ·  MAG %d  ·  SPD %d  ·  DUR %d/%d  ·  Giá trị ước tính ~%dG" % [
		weapon.get("atk", 0), weapon.get("magic", 0), weapon.get("speed", 0),
		weapon.get("durability", 50), weapon.get("durability_max", 50),
		_weapon_value(weapon),
	]
	_lbl_npc_offer.text      = "%dG" % _offer_gold
	_price_input.text        = ""
	_price_input.placeholder_text = str(_weapon_value(weapon))

	# Tính giới hạn giá và gợi ý cho vòng đàm phán này
	var val_w:    int   = _weapon_value(weapon)
	var budget_w: int   = _customer.get("budget_this_visit", 500)
	_npc_max_price  = mini(budget_w, int(val_w * _get_class_max_factor(_customer.get("type", ""))))
	_price_cap_hard = int(val_w * 1.6)
	_hint_min       = _offer_gold + 10
	_hint_max       = int(_npc_max_price * randf_range(0.82, 0.93))
	_lbl_hint.text  = "Gợi ý: ~%dG – %dG" % [_hint_min, _hint_max]

	# Trade offer
	if not _trade_offer.is_empty():
		_lbl_trade_desc.text   = _trade_desc(_trade_offer)
		_trade_section.visible = true
		_lbl_npc_speech.text   = TRADE_INTRO_LINES.get(ctype, "Tôi có thứ muốn đổi.")
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


func _layout_p2_buttons(has_trade: bool, show_propose: bool = true, show_threat: bool = false) -> void:
	var bx := _bx + 2
	var y  := _by + 2 + 464
	var h  := 52

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
	const AREA := 738
	var n      := btns.size()
	var btn_w  := int((AREA - GAP * (n - 1)) / n)
	var remain := AREA - GAP * (n - 1) - btn_w * n

	var x := bx
	for i: int in n:
		var b: Button = btns[i]
		b.position = Vector2(x, y)
		b.size     = Vector2(btn_w + (remain if i == n - 1 else 0), h)
		b.visible  = true
		x += btn_w + GAP

	_btn_sell_npc.text = "Bán giá NPC  ·  %dG" % _offer_gold


# ── Xử lý kết quả ─────────────────────────────────────────────────────────────

func _on_sell_npc_price() -> void:
	if _resolving: return
	_resolving = true
	var ctype: String = _customer.get("type", "")
	_lbl_npc_speech.text = ACCEPT_LINES.get(ctype, "Cảm ơn!")
	await get_tree().create_timer(1.1).timeout
	close_ui()
	deal_accepted.emit(_chosen_weapon, _offer_gold)


func _on_propose() -> void:
	if _resolving: return

	if _proposals_used >= PROPOSALS_MAX:
		_resolving = true
		_patience  = 0
		_update_negotiate_info()
		var ctype_imm: String = _customer.get("type", "")
		_lbl_npc_speech.text = HAGGLE_TOO_HIGH_LINES.get(ctype_imm, "Quá đắt! Tôi đi.")
		await get_tree().create_timer(1.2).timeout
		close_ui()
		deal_declined.emit()
		return

	var input: String = _price_input.text.strip_edges()
	if input.is_empty() or not input.is_valid_int():
		_lbl_npc_speech.text = "Bạn muốn bán giá bao nhiêu? Nhập số vào ô bên dưới."
		return

	var proposed: int   = int(input)
	var ctype:    String = _customer.get("type", "")

	_proposals_used += 1
	_update_negotiate_info()

	# Trần cứng — giá vô lý, trừ patience ngay và không mặc cả thêm
	if proposed > _price_cap_hard:
		_patience -= 1
		_update_negotiate_info()
		if _patience <= 0:
			_resolving = true
			_lbl_npc_speech.text = HAGGLE_TOO_HIGH_LINES.get(ctype, "Quá đắt! Tôi đi.")
			await get_tree().create_timer(1.2).timeout
			close_ui()
			deal_declined.emit()
		else:
			_lbl_npc_speech.text = "Giá đó... không ai trả nổi đâu. Nghiêm túc lại đi."
			_check_proposal_limit()
		return

	if proposed <= _offer_gold:
		# Player tự bán dưới giá NPC → chấp nhận ngay
		_resolving = true
		_lbl_npc_speech.text = ACCEPT_LINES.get(ctype, "Cảm ơn!")
		await get_tree().create_timer(1.1).timeout
		close_ui()
		deal_accepted.emit(_chosen_weapon, proposed)

	elif proposed <= int(_offer_gold * 1.05):
		# Sát với giá NPC (≤5%) → chấp nhận, không mặc cả thêm
		_resolving = true
		_lbl_npc_speech.text = "Hm... %dG thôi, được rồi." % proposed
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
		var counter_line: String = HAGGLE_COUNTER_LINES.get(ctype, "Tôi chỉ trả %dG.")
		_lbl_npc_speech.text = counter_line % counter
		_check_proposal_limit()

	else:
		# Vượt quá khả năng → patience giảm, NPC bực bội
		_patience -= 1
		_update_negotiate_info()
		if _patience <= 0:
			_resolving = true
			_lbl_npc_speech.text = HAGGLE_TOO_HIGH_LINES.get(ctype, "Quá đắt! Tôi đi.")
			await get_tree().create_timer(1.2).timeout
			close_ui()
			deal_declined.emit()
		else:
			_lbl_npc_speech.text = HAGGLE_FRUSTRATED_LINES.get(ctype, "Giá quá cao!")
			_check_proposal_limit()


func _on_trade_accept() -> void:
	if _resolving: return
	_resolving = true
	var ctype: String = _customer.get("type", "")
	_lbl_npc_speech.text = "Tuyệt! Trao đổi thành công."
	await get_tree().create_timer(1.1).timeout
	close_ui()
	trade_accepted.emit(_chosen_weapon, _trade_offer)


func _on_threaten() -> void:
	if _resolving or _threat_used: return
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
		_lbl_npc_speech.text = THREAT_SUCCESS_LINES.get(ctype, "...(run rẩy) Vâng...")
		_update_negotiate_info()
	else:
		rep_loss   = randi_range(16, 24)
		_patience -= 1
		_update_negotiate_info()
		var fail_line: String = THREAT_FAIL_LINES.get(ctype, "Không! Tôi đi!")
		if _patience <= 0:
			_resolving = true
			_lbl_npc_speech.text = fail_line
			_show_rep_loss(rep_loss)
			await get_tree().create_timer(1.4).timeout
			close_ui()
			deal_declined.emit()
			return
		else:
			_lbl_npc_speech.text = fail_line

	# Trừ uy tín (luôn xảy ra dù thành công hay thất bại)
	_show_rep_loss(rep_loss)
	if EventBus.has_signal("reputation_changed"):
		EventBus.reputation_changed.emit(-rep_loss)

	if not _resolving:
		_layout_p2_buttons(not _trade_offer.is_empty(), _proposals_used < PROPOSALS_MAX, false)


func _show_rep_loss(amount: int) -> void:
	_lbl_negotiate_info.text = "Uy tín  −%d  |  " % amount + _lbl_negotiate_info.text
	_lbl_negotiate_info.add_theme_color_override("font_color", Color(0.90, 0.32, 0.22))


func _on_decline() -> void:
	if _resolving: return
	_resolving = true
	var ctype: String = _customer.get("type", "")
	if _phase == Phase.PRICE:
		_lbl_npc_speech.text = DECLINE_LINES.get(ctype, "Không sao.")
	else:
		_lbl_npc_speech.text = DECLINE_LINES.get(ctype, "Không sao.")
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
	return mini(int(val * factor), budget)


func _weapon_value(w: Dictionary) -> int:
	return (w.get("atk", 0) + w.get("magic", 0)) * 28 \
		+ w.get("rarity_tier", 1) * 140 \
		+ w.get("speed", 5) * 6


# Hệ số × giá trị vũ khí → giá tối đa NPC class đó sẵn sàng trả.
# Class giàu (ve_binh, dao_si) trả cao hơn giá trị; class nghèo (nong_dan) trả thấp hơn.
func _get_class_max_factor(ctype: String) -> float:
	match ctype:
		"ve_binh":     return randf_range(1.35, 1.50)   # ngân khố hoàng gia
		"dao_si":      return randf_range(1.25, 1.40)   # giàu, cần hàng hiếm
		"thich_khach": return randf_range(1.20, 1.35)   # tiền nhiều, ít kiên nhẫn
		"vo_tang":     return randf_range(1.15, 1.30)
		"hiep_khach":  return randf_range(1.10, 1.25)
		"thu_ve":      return randf_range(1.05, 1.20)
		"thuong_nhan": return randf_range(0.95, 1.10)   # cần lời, không trả cao
		"nong_dan":    return randf_range(0.80, 0.95)   # tiền ít, trả dưới giá trị
		_:             return randf_range(1.00, 1.15)


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
	elif left <= 1:
		_lbl_negotiate_info.add_theme_color_override("font_color", Color(0.90, 0.72, 0.22))
	else:
		_lbl_negotiate_info.add_theme_color_override("font_color", C_MUTE)


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
