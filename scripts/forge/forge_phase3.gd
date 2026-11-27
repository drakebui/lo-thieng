# Phase 3: Tôi Luyện — Khắc Ấn Linh Lực (hoặc Tôi Nước Thuần) & căn nhịp Cổ Ngữ hội tụ
# Kết quả emit EventBus.phase3_completed(weapon_result: Dictionary)
extends Node

const PURE_WATER_COLOR := Color(0.45, 0.74, 0.88)

const ELEMENTS: Dictionary = {
	"hoa": {
		"name":   "Hỏa",
		"suffix": "thieu_dot",
		"color":  Color(1.0, 0.32, 0.05),
	},
	"bang": {
		"name":   "Băng",
		"suffix": "bang_gia",
		"color":  Color(0.38, 0.78, 1.0),
	},
	"set": {
		"name":   "Sét",
		"suffix": "sam_set",
		"color":  Color(0.92, 0.92, 0.22),
	},
	"tho": {
		"name":   "Thổ",
		"suffix": "dao_dong",
		"color":  Color(0.62, 0.42, 0.12),
	},
	"phong": {
		"name":   "Phong",
		"suffix": "cuong_phong",
		"color":  Color(0.28, 0.92, 0.52),
	},
	"hu_khong": {
		"name":   "Hư Không",
		"suffix": "hu_khong",
		"color":  Color(0.52, 0.18, 0.88),
	},
}

const SUFFIX_NAMES: Dictionary = {
	"thieu_dot":   "Thiêu Đốt",
	"bang_gia":    "Băng Giá",
	"sam_set":     "Sấm Sét",
	"dao_dong":    "Dao Động",
	"cuong_phong": "Cuồng Phong",
	"hu_khong":    "Hư Không",
}

# Thời gian tôi luyện 2.4s (0..1.0 trong 2.4s)
const QUENCH_DURATION := 2.4

# Vùng tâm hội tụ cổ ngữ: 0.70 ± 0.08 (0.62 .. 0.78)
const TARGET_PROGRESS  := 0.70
const TARGET_TOLERANCE := 0.08

var element_key: String = ""
var is_active: bool = false
var quench_progress: float = 0.0
var is_quenching: bool = false
var perfect_quench: bool = false
var _quench_pressed: bool = false


func start_phase(element: String) -> void:
	element_key = element if ELEMENTS.has(element) else ""
	is_active = true
	is_quenching = true
	quench_progress = 0.0
	perfect_quench = false
	_quench_pressed = false


func _process(delta: float) -> void:
	if not is_active or not is_quenching:
		return
	quench_progress = minf(quench_progress + delta / QUENCH_DURATION, 1.0)
	if quench_progress >= 1.0:
		is_quenching = false


# Người chơi nhấn Space / Chuột Trái căn nhịp hội tụ
func try_quench_press() -> bool:
	if not is_active or not is_quenching or _quench_pressed:
		return false
	_quench_pressed = true
	var dist := absf(quench_progress - TARGET_PROGRESS)
	if dist <= TARGET_TOLERANCE:
		perfect_quench = true
		return true
	return false


# Kiểm tra xem hiện tại có đang trong cửa sổ hội tụ không
func is_in_quench_window() -> bool:
	return absf(quench_progress - TARGET_PROGRESS) <= TARGET_TOLERANCE


# Gọi sau khi kết thúc tôi luyện — tính kết quả và emit signal
func complete(phase1_tier: String, phase2_prefix: String, is_perfect_quench: bool = false) -> Dictionary:
	is_active = false
	is_quenching = false
	var final_perfect := is_perfect_quench or perfect_quench
	var elem: Dictionary = ELEMENTS.get(element_key, {})
	var result := {
		"phase1_tier":      phase1_tier,
		"phase2_prefix":    phase2_prefix,
		"element":          element_key,
		"suffix":           String(elem.get("suffix", "")),
		"element_name":     String(elem.get("name", "")),
		"element_color":    elem.get("color", PURE_WATER_COLOR),
		"perfect_quench":   final_perfect,
		"price_mult":       1.10 if final_perfect else 1.0,
		"durability_bonus": 10 if final_perfect else 0,
	}
	EventBus.phase3_completed.emit(result)
	return result


func get_element_data(element: String) -> Dictionary:
	if ELEMENTS.has(element):
		return ELEMENTS[element]
	return {
		"name": "Nước Thuần",
		"suffix": "",
		"color": PURE_WATER_COLOR,
	}


func get_suffix_name(suffix: String) -> String:
	return SUFFIX_NAMES.get(suffix, suffix)
