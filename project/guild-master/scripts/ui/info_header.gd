class_name InfoHeader
extends Control

signal time_clicked()

@export_group("Layout Settings")
@export var padding_size: int = 12
@export var container_separation: int = 8

@export_group("Colors")
@export var text_color: Color = Color("#e0e0e0")
@export var dim_text_color: Color = Color("#a0a0a8")
@export var accent_color: Color = Color("#a0a0a8")

@export_group("Fonts")
@export_range(10, 48, 1) var title_font_size: int = 22
@export_range(10, 48, 1) var metric_font_size: int = 18
@export_range(10, 48, 1) var time_font_size: int = 20

@export_group("UI References")
@export var margin_container: MarginContainer
@export var left_metrics: HBoxContainer
@export var right_info: HBoxContainer

var _metric_labels: Dictionary = {}
var _place_label: Label
var _time_label: Label

func _ready() -> void:
	_resolve_references()
	_apply_dynamic_ui_settings()
	_setup_labels()

func _resolve_references() -> void:
	if margin_container == null:
		margin_container = get_node_or_null("MarginContainer")
	if left_metrics == null:
		left_metrics = get_node_or_null("MarginContainer/HBoxContainer/LeftMetrics")
	if right_info == null:
		right_info = get_node_or_null("MarginContainer/HBoxContainer/RightInfo")

func _apply_dynamic_ui_settings() -> void:
	if margin_container:
		margin_container.add_theme_constant_override("margin_left", padding_size)
		margin_container.add_theme_constant_override("margin_right", padding_size)
		margin_container.add_theme_constant_override("margin_top", padding_size >> 1)
		margin_container.add_theme_constant_override("margin_bottom", padding_size >> 1)
	if left_metrics:
		left_metrics.add_theme_constant_override("separation", container_separation)
	if right_info:
		right_info.add_theme_constant_override("separation", container_separation)

func _setup_labels() -> void:
	if right_info == null:
		return
	for child in right_info.get_children():
		child.queue_free()

	_place_label = Label.new()
	_place_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_place_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	right_info.add_child(_place_label)

	var sep := Label.new()
	sep.text = " | "
	sep.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	right_info.add_child(sep)

	_time_label = Label.new()
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_time_label.gui_input.connect(_on_time_gui_input)
	right_info.add_child(_time_label)

	_update_label_themes()

func _update_label_themes() -> void:
	if _place_label:
		_place_label.add_theme_font_size_override("font_size", title_font_size)
		_place_label.add_theme_color_override("font_color", text_color)
	for child in right_info.get_children():
		if child is Label and child != _place_label and child != _time_label:
			child.add_theme_font_size_override("font_size", time_font_size)
			child.add_theme_color_override("font_color", dim_text_color)
	if _time_label:
		_time_label.add_theme_font_size_override("font_size", time_font_size)
		_time_label.add_theme_color_override("font_color", text_color)

func set_place_name(place_name: String) -> void:
	if _place_label:
		_place_label.text = place_name

func set_time(text: String) -> void:
	if _time_label:
		_time_label.text = text

func set_metrics(metrics: Dictionary) -> void:
	if left_metrics == null:
		return
	for child in left_metrics.get_children():
		child.queue_free()
	_metric_labels.clear()

	var ordered_keys := metrics.keys()
	for i in range(ordered_keys.size()):
		var key = ordered_keys[i]
		var val = metrics[key]
		var display_name := _metric_display_name(key)
		var label := Label.new()
		label.text = "%s: %s" % [display_name, str(val)]
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		left_metrics.add_child(label)
		_metric_labels[key] = label

		if i < ordered_keys.size() - 1:
			var sep := Label.new()
			sep.text = " | "
			sep.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			left_metrics.add_child(sep)

	_update_metric_themes()

func _update_metric_themes() -> void:
	for child in left_metrics.get_children():
		if child is Label:
			child.add_theme_font_size_override("font_size", metric_font_size)
			if child.text == " | ":
				child.add_theme_color_override("font_color", dim_text_color)
			else:
				child.add_theme_color_override("font_color", text_color)

func _metric_display_name(metric_key: String) -> String:
	var parts := metric_key.split(".")
	var raw := parts[-1] if parts.size() > 0 else metric_key
	match raw:
		"funds", "gold", "money":
			return "Funds"
		"hp", "health":
			return "HP"
		"sanity", "san", "mental":
			return "SAN"
		"strength", "str":
			return "STR"
		"intelligence", "int":
			return "INT"
		"dexterity", "dex":
			return "DEX"
		"will", "willpower":
			return "WILL"
		_:
			return raw.capitalize()

func _on_time_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		time_clicked.emit()
