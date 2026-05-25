extends Node

# Chuyển scene với fade đơn giản: màn đen → đổi scene → hiện ra
# Dùng: SceneManager.go_to("res://scenes/forge/ForgeSession.tscn")

const FADE_DURATION := 0.20

var _overlay: ColorRect
var _busy: bool = false


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)

	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate.a = 0.0
	layer.add_child(_overlay)


# Chuyển tới scene tại path. Bỏ qua nếu đang trong quá trình chuyển.
func go_to(path: String) -> void:
	if _busy:
		return
	if not ResourceLoader.exists(path):
		push_error("Scene không tồn tại: %s" % path)
		return
	_busy = true

	var tw := create_tween()
	tw.tween_property(_overlay, "modulate:a", 1.0, FADE_DURATION)
	tw.tween_callback(func() -> void:
		get_tree().change_scene_to_file(path)
		var tw2 := create_tween()
		tw2.tween_property(_overlay, "modulate:a", 0.0, FADE_DURATION)
		tw2.tween_callback(func() -> void: _busy = false)
	)
