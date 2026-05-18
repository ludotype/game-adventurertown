extends Control

## ESCButton
## 좌상단에 배치되는 설정/일시정지 버튼. 클릭 시 PauseMenu를 토글합니다.

@export var button_size: Vector2 = Vector2(48, 48)
@export var placeholder_color: Color = Color(0.2, 0.2, 0.25, 0.8)
@export var icon_color: Color = Color(1, 1, 1, 0.9)

@onready var _button: Button = $Button

func _ready() -> void:
	_apply_style()
	_button.pressed.connect(_on_button_pressed)

func _apply_style() -> void:
	_button.custom_minimum_size = button_size
	_button.set_deferred("size", button_size)

	var normal := StyleBoxFlat.new()
	normal.bg_color = placeholder_color
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	_button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = placeholder_color.lightened(0.15)
	hover.corner_radius_top_left = 6
	hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_left = 6
	hover.corner_radius_bottom_right = 6
	_button.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = placeholder_color.darkened(0.1)
	pressed.corner_radius_top_left = 6
	pressed.corner_radius_top_right = 6
	pressed.corner_radius_bottom_left = 6
	pressed.corner_radius_bottom_right = 6
	_button.add_theme_stylebox_override("pressed", pressed)

func _on_button_pressed() -> void:
	var pause_menu = get_tree().root.get_node_or_null("PauseMenu")
	if pause_menu and pause_menu.has_method("toggle_pause"):
		pause_menu.toggle_pause()
	else:
		push_warning("ESCButton: PauseMenu not found")
