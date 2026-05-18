class_name DialogueBar
extends Control

@export var bg_color: Color = Color(0x252529ff)
@export var border_color: Color = Color(0x3a3a40ff)
@export var font_size: int = 20
@export var text_color: Color = Color(0xEAE6DFff)

@onready var _bg: Panel = $Background
@onready var _text: RichTextLabel = $MarginContainer/RichTextLabel

func _ready() -> void:
	_apply_style()
	if _text:
		_text.scroll_following = true
	clear()
	visible = true

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

func append_log(text: String, speaker: String = "") -> void:
	if _text == null:
		return
	if text.is_empty():
		return
	var needs_newline := not _text.get_parsed_text().is_empty()
	if not speaker.is_empty():
		if needs_newline:
			_text.append_text("\n[b]%s[/b]: %s" % [speaker, text])
		else:
			_text.append_text("[b]%s[/b]: %s" % [speaker, text])
	else:
		if needs_newline:
			_text.append_text("\n%s" % text)
		else:
			_text.append_text("%s" % text)
	visible = true

func clear() -> void:
	if _text:
		_text.clear()
		_text.append_text("[i]...[/i]")
