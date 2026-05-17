class_name MovePanel
extends Control

signal move_pressed(place_id: String)

@export var bg_color: Color = Color(0.12, 0.12, 0.15, 0.9)
@export var title_font_size: int = 20
@export var button_font_size: int = 20
@export var button_min_width: float = 180.0
@export var button_min_height: float = 64.0
@export var separation: int = 12
@export var text_color: Color = Color(1, 1, 1, 1)

@onready var _bg: ColorRect = $Background
@onready var _title: Label = $MarginContainer/VBoxContainer/Title
@onready var _list: HBoxContainer = $MarginContainer/VBoxContainer/MoveList

func _ready() -> void:
	_apply_style()

func _apply_style() -> void:
	if _bg:
		_bg.color = bg_color
	if _title:
		_title.add_theme_font_size_override("font_size", title_font_size)
		_title.add_theme_color_override("font_color", text_color)
	if _list:
		_list.add_theme_constant_override("separation", separation)

func set_title(text: String) -> void:
	if _title:
		_title.text = text

func clear() -> void:
	for child in _list.get_children():
		child.queue_free()

func add_destination(display_name: String, place_id: String) -> void:
	var btn := ModularButton.new()
	btn.text = display_name
	btn.font_size = button_font_size
	btn.min_width = button_min_width
	btn.min_height = button_min_height
	btn.pressed.connect(func(): move_pressed.emit(place_id))
	_list.add_child(btn)
