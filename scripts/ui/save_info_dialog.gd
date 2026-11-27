class_name SaveInfoDialog
extends AcceptDialog

signal load_confirmed

var _metadata: Dictionary = {}


func _ready() -> void:
	title = "Thông Tin Lưu"
	ok_button_text = "Tiếp tục"
	add_theme_stylebox_override("panel", HoaTamUI.make_system_slate_style(24.0))
	dialog_text = _build_message()
	confirmed.connect(_on_confirmed)
	add_cancel_button("Hủy")


func set_metadata(metadata: Dictionary) -> void:
	_metadata = metadata.duplicate(true)
	dialog_text = _build_message()


func popup_with_metadata(metadata: Dictionary) -> void:
	set_metadata(metadata)
	popup_centered()


func _build_message() -> String:
	var day := int(_metadata.get("day", 0))
	var saved_at := str(_metadata.get("saved_at", ""))
	if saved_at.is_empty():
		saved_at = "không rõ"
	return "Ngày %d — Lưu lúc %s" % [day, saved_at]


func _on_confirmed() -> void:
	load_confirmed.emit()
