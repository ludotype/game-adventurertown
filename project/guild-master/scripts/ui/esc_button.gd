extends Control

@export_group("Layout Settings")
@export var button_size: Vector2 = Vector2(48, 48)

@export_group("Colors")
@export var normal_bg_color: Color = Color("#3a3a40")
@export var hover_bg_color: Color = Color("#4a4a52")
@export var pressed_bg_color: Color = Color("#2a2a30")
@export var icon_color: Color = Color("#e0e0e0")

@export_group("UI References")
@export var button: Button

func _ready() -> void:
	_resolve_references()
	_apply_dynamic_ui_settings()
	if button:
		button.pressed.connect(_on_button_pressed)

func _resolve_references() -> void:
	if button == null:
		button = get_node_or_null("Button")

func _apply_dynamic_ui_settings() -> void:
	if button == null:
		return
	button.custom_minimum_size = button_size
	button.add_theme_color_override("font_color", icon_color)

	var normal := StyleBoxFlat.new()
	normal.bg_color = normal_bg_color
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_bg_color
	hover.corner_radius_top_left = 6
	hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_left = 6
	hover.corner_radius_bottom_right = 6
	button.add_theme_stylebox_override("hover", hover)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = pressed_bg_color
	pressed_style.corner_radius_top_left = 6
	pressed_style.corner_radius_top_right = 6
	pressed_style.corner_radius_bottom_left = 6
	pressed_style.corner_radius_bottom_right = 6
	button.add_theme_stylebox_override("pressed", pressed_style)

func _on_button_pressed() -> void:
	var pause_menu = get_tree().root.get_node_or_null("PauseMenu")
	if pause_menu and pause_menu.has_method("toggle_pause"):
		pause_menu.toggle_pause()
	else:
		push_warning("ESCButton: PauseMenu not found")
