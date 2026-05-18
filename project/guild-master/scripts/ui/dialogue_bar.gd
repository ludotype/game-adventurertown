class_name DialogueBar
extends Control

@export var bg_color: Color = Color("#1a1a1e")
@export var border_color: Color = Color("#3a3a40")
@export var font_size: int = 20
@export var text_color: Color = Color("#EAE6DF")

@onready var _bg: Panel = $Background
@onready var _text: RichTextLabel = $MarginContainer/RichTextLabel

func _ready() -> void:
	_apply_style()
	clear()

func _apply_style() -> void:
	if _bg:
		var border := StyleBoxFlat.new()
		border.bg_color = bg_color
		border.border_width_left = 2
		border.border_width_top = 2
		border.border_width_right = 2
		border.border_width_bottom = 2
		border.border_color = border_color
		border.corner_radius_top_left = 4
		border.corner_radius_top_right = 4
		border.corner_radius_bottom_left = 4
		border.corner_radius_bottom_right = 4
		_bg.add_theme_stylebox_override("panel", border)
	if _text:
		_text.add_theme_font_size_override("normal_font_size", font_size)
		_text.add_theme_color_override("default_color", text_color)

func show_dialogue(speaker: String, text: String) -> void:
	if _text == null:
		return
	_text.clear()
	_text.append_text("[b]%s[/b]: \"%s\"" % [speaker, text])
	visible = true

func clear() -> void:
	if _text:
		_text.clear()
	visible = false
