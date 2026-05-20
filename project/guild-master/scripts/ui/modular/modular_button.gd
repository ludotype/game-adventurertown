class_name ModularButton
extends Button

@export_group("Layout Settings")
@export var min_width: float = 180.0
@export var min_height: float = 56.0
@export var corner_radius: int = 4

@export_group("Colors")
@export var normal_bg_color: Color = Color("#3a3a40")
@export var hover_bg_color: Color = Color("#4a4a52")
@export var pressed_bg_color: Color = Color("#2a2a30")
@export var text_color: Color = Color("#e0e0e0")

@export_group("Fonts")
@export_range(10, 32, 1) var font_size: int = 20

func _ready() -> void:
	_apply_dynamic_ui_settings()

func _apply_dynamic_ui_settings() -> void:
	custom_minimum_size = Vector2(min_width, min_height)
	add_theme_font_size_override("font_size", font_size)
	add_theme_color_override("font_color", text_color)

	var normal := StyleBoxFlat.new()
	normal.bg_color = normal_bg_color
	normal.corner_radius_top_left = corner_radius
	normal.corner_radius_top_right = corner_radius
	normal.corner_radius_bottom_left = corner_radius
	normal.corner_radius_bottom_right = corner_radius
	add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_bg_color
	hover.corner_radius_top_left = corner_radius
	hover.corner_radius_top_right = corner_radius
	hover.corner_radius_bottom_left = corner_radius
	hover.corner_radius_bottom_right = corner_radius
	add_theme_stylebox_override("hover", hover)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = pressed_bg_color
	pressed_style.corner_radius_top_left = corner_radius
	pressed_style.corner_radius_top_right = corner_radius
	pressed_style.corner_radius_bottom_left = corner_radius
	pressed_style.corner_radius_bottom_right = corner_radius
	add_theme_stylebox_override("pressed", pressed_style)
