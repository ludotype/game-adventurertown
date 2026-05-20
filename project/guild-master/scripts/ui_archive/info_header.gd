# class_name InfoHeader
extends Control

signal time_clicked()

@export var bg_color: Color = Color(0x252529ff)
@export var border_color: Color = Color(0x3a3a40ff)
@export var title_font_size: int = 22
@export var metric_font_size: int = 18
@export var time_font_size: int = 20
@export var text_color: Color = Color(0xEAE6DFff)
@export var dim_text_color: Color = Color(0xc0bcb5ff)

@onready var _bg: Panel = $Background
@onready var _left_metrics: HBoxContainer = $MarginContainer/HBoxContainer/LeftMetrics
@onready var _right_info: HBoxContainer = $MarginContainer/HBoxContainer/RightInfo

var _metric_labels: Dictionary = {}
var _place_label: Label
var _time_label: Label

func _ready() -> void:
	_apply_style()
	_setup_labels()

func _setup_labels() -> void:
	if _right_info == null:
		return
	for child in _right_info.get_children():
		child.queue_free()

	_place_label = Label.new()
	_place_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_place_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_label.add_theme_font_size_override("font_size", title_font_size)
	_place_label.add_theme_color_override("font_color", text_color)
	_right_info.add_child(_place_label)

	var sep := Label.new()
	sep.text = " | "
	sep.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sep.add_theme_font_size_override("font_size", time_font_size)
	sep.add_theme_color_override("font_color", dim_text_color)
	_right_info.add_child(sep)

	_time_label = Label.new()
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_time_label.add_theme_font_size_override("font_size", time_font_size)
	_time_label.add_theme_color_override("font_color", text_color)
	_time_label.gui_input.connect(_on_time_gui_input)
	_right_info.add_child(_time_label)

func _apply_style() -> void:
	if _bg is Panel:
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

func set_place_name(place_name: String) -> void:
	if _place_label:
		_place_label.text = place_name

func set_time(text: String) -> void:
	if _time_label:
		_time_label.text = text

func set_metrics(metrics: Dictionary) -> void:
	if _left_metrics == null:
		return
	# Clear all children including separators
	for child in _left_metrics.get_children():
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
		label.add_theme_font_size_override("font_size", metric_font_size)
		label.add_theme_color_override("font_color", text_color)
		_left_metrics.add_child(label)
		_metric_labels[key] = label

		if i < ordered_keys.size() - 1:
			var sep := Label.new()
			sep.text = " | "
			sep.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			sep.add_theme_font_size_override("font_size", metric_font_size)
			sep.add_theme_color_override("font_color", dim_text_color)
			_left_metrics.add_child(sep)

func _metric_display_name(metric_key: String) -> String:
	# metric_key is like "player.funds" — extract last part
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
