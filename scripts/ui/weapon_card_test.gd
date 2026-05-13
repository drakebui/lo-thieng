# Scene test standalone cho WeaponCardUI
extends Control

const _CARD_SCENE := preload("res://scenes/ui/WeaponCardUI.tscn")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.08, 0.06)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "WEAPON CARD — Preview"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.55, 0.50, 0.40))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 40
	title.offset_bottom = 120
	add_child(title)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := _CARD_SCENE.instantiate()
	center.add_child(card)
