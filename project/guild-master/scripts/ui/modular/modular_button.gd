class_name ModularButton
extends Button

@export var placeholder_color: Color = Color(0.35, 0.35, 0.4, 0.9)
@export var font_size: int = 20
@export var min_width: float = 180.0
@export var min_height: float = 56.0
@export var corner_radius: int = 4

func _ready() -> void:
	_apply_style()

func _apply_style() -> void:
	custom_minimum_size = Vector2(min_width, min_height)
	add_theme_font_size_override("font_size", font_size)

	var normal := StyleBoxFlat.new()
	normal.bg_color = placeholder_color
	normal.corner_radius_top_left = corner_radius
	normal.corner_radius_top_right = corner_radius
	normal.corner_radius_bottom_left = corner_radius
	normal.corner_radius_bottom_right = corner_radius
	add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = placeholder_color.lightened(0.1)
	hover.corner_radius_top_left = corner_radius
	hover.corner_radius_top_right = corner_radius
	hover.corner_radius_bottom_left = corner_radius
	hover.corner_radius_bottom_right = corner_radius
	add_theme_stylebox_override("hover", hover)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = placeholder_color.darkened(0.1)
	pressed_style.corner_radius_top_left = corner_radius
	pressed_style.corner_radius_top_right = corner_radius
	pressed_style.corner_radius_bottom_left = corner_radius
	pressed_style.corner_radius_bottom_right = corner_radius
	add_theme_stylebox_override("pressed", pressed_style)
