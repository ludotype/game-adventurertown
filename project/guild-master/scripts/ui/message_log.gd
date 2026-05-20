class_name MessageLog
extends Control

@export_group("UI References")
@export var text_label: RichTextLabel

func _ready() -> void:
	_resolve_references()

func _resolve_references() -> void:
	if text_label == null:
		text_label = get_node_or_null("MarginContainer/RichTextLabel")

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
