# class_name MovePanel
extends Control

signal move_pressed(place_id: String)

@export var bg_color: Color = Color(0.12, 0.12, 0.15, 0.9)
@export var title_font_size: int = 20
@export var button_font_size: int = 20
@export var button_min_width: float = 180.0
@export var button_min_height: float = 64.0
@export var max_button_width: float = 300.0
@export var separation: int = 12
@export var text_color: Color = Color(1, 1, 1, 1)

@onready var _bg: ColorRect = $Background
@onready var _title: Label = $MarginContainer/VBoxContainer/Title
@onready var _list: HBoxContainer = $MarginContainer/VBoxContainer/MoveList

func _ready() -> void:
	_apply_style()
	if _list:
		_list.resized.connect(_on_list_resized)

func _apply_style() -> void:
	if _bg:
		_bg.color = bg_color
	if _title:
		_title.add_theme_font_size_override("font_size", title_font_size)
		_title.add_theme_color_override("font_color", text_color)
	if _list:
		_list.add_theme_constant_override("separation", separation)
		_list.alignment = BoxContainer.ALIGNMENT_CENTER

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
	_refresh_button_sizes.call_deferred()

func _on_list_resized() -> void:
	_refresh_button_sizes()

func _refresh_button_sizes() -> void:
	if _list == null or _list.size.x <= 0:
		return
	var count := _list.get_child_count()
	if count == 0:
		return
	for child in _list.get_children():
		var btn := child as Button
		if btn == null:
			continue
		if count == 1:
			btn.size_flags_horizontal = 0
			var target_width := minf(max_button_width, _list.size.x - separation)
			btn.custom_minimum_size.x = maxf(button_min_width, target_width)
		else:
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size.x = button_min_width
