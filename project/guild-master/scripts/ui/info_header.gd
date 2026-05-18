class_name InfoHeader
extends Control

signal time_clicked()

@export var bg_color: Color = Color(0.1, 0.1, 0.12, 0.8)
@export var title_font_size: int = 40
@export var time_font_size: int = 24
@export var text_color: Color = Color(1, 1, 1, 1)

@onready var _bg: ColorRect = $Background
@onready var _title: Label = $MarginContainer/VBoxContainer/PlaceNameLabel
@onready var _time: Label = $MarginContainer/VBoxContainer/TimeLabel

func _ready() -> void:
	_apply_style()
	if _time:
		_time.gui_input.connect(_on_time_gui_input)

func _apply_style() -> void:
	if _bg:
		_bg.color = bg_color
	if _title:
		_title.add_theme_font_size_override("font_size", title_font_size)
		_title.add_theme_color_override("font_color", text_color)
	if _time:
		_time.add_theme_font_size_override("font_size", time_font_size)
		_time.add_theme_color_override("font_color", text_color)

func set_place_name(place_name: String) -> void:
	if _title:
		_title.text = place_name

func set_time(text: String) -> void:
	if _time:
		_time.text = text

func _on_time_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		time_clicked.emit()
