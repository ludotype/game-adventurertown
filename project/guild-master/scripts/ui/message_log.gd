class_name MessageLog
extends Control

@export_group("UI References")
@export var text_label: RichTextLabel

@export_group("Font Overrides")
@export var message_font: Font
@export var message_font_size: int = 22
@export var outline_size: int = 2
@export var outline_color: Color = Color.BLACK

func _ready() -> void:
	_resolve_references()
	_apply_font_overrides()

func _apply_font_overrides() -> void:
	if text_label == null:
		return
	if message_font:
		text_label.add_theme_font_override("normal_font", message_font)
	if message_font_size > 0:
		text_label.add_theme_font_size_override("normal_font_size", message_font_size)
	if outline_size > 0:
		text_label.add_theme_constant_override("outline_size", outline_size)
		text_label.add_theme_color_override("font_outline_color", outline_color)

func _resolve_references() -> void:
	if text_label == null:
		text_label = get_node_or_null("MarginContainer/RichTextLabel")

func set_message(text: String) -> void:
	if text_label == null:
		return
	text_label.clear()
	text_label.append_text(text)

func append_message(text: String) -> void:
	if text_label == null:
		return
	if text_label.get_parsed_text().is_empty():
		text_label.append_text(text)
	else:
		text_label.append_text("\n" + text)
	text_label.scroll_to_line(text_label.get_line_count() - 1)

func clear() -> void:
	if text_label:
		text_label.clear()
