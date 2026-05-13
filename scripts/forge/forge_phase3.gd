# Phase 3: Tôi Luyện — Auto phase, không có mini-game
# Player chọn nguyên tố (Linh Lực) → vũ khí được nhúng → suffix xác định
# Kết quả emit EventBus.phase3_completed(weapon_result: Dictionary)
extends Node

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

# Thời gian animation tôi luyện (giây) — UI dùng để chạy tween
const QUENCH_DURATION := 3.5

var element_key: String = ""
var is_active:   bool   = false


func start_phase(element: String) -> void:
	element_key = element
	is_active   = true


# Gọi sau khi animation UI kết thúc — tính kết quả và emit signal
func complete(phase1_tier: String, phase2_prefix: String) -> Dictionary:
	is_active = false
	var elem: Dictionary = ELEMENTS.get(element_key, {})
	var result := {
		"phase1_tier":    phase1_tier,
		"phase2_prefix":  phase2_prefix,
		"element":        element_key,
		"suffix":         elem.get("suffix", ""),
		"element_name":   elem.get("name", ""),
		"element_color":  elem.get("color", Color.WHITE),
	}
	EventBus.phase3_completed.emit(result)
	return result


func get_element_data(element: String) -> Dictionary:
	return ELEMENTS.get(element, {})


func get_suffix_name(suffix: String) -> String:
	return SUFFIX_NAMES.get(suffix, suffix)
