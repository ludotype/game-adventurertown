class_name TextActionLabel
extends RichTextLabel

signal clicked()

@export var normal_color: Color = Color("#EAE6DF")
@export var hover_color: Color = Color("#A91D22")
@export var font_size: int = 18
@export var underline_on_hover: bool = true
@export var min_width: float = 80.0
@export var min_height: float = 32.0

var _base_text: String = ""

func _ready() -> void:
	bbcode_enabled = true
	fit_content = true
	scroll_active = false
	mouse_filter = MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_size_override("normal_font_size", font_size)
	add_theme_color_override("default_color", normal_color)
	custom_minimum_size = Vector2(min_width, min_height)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func set_action_text(text: String) -> void:
	_base_text = text
	_update_appearance(false)


func _on_mouse_entered() -> void:
	_update_appearance(true)


func _on_mouse_exited() -> void:
	_update_appearance(false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()


func _update_appearance(hovering: bool) -> void:
	if hovering:
		add_theme_color_override("default_color", hover_color)
		if underline_on_hover:
			text = "[u]" + _base_text + "[/u]"
		else:
			text = _base_text
	else:
		add_theme_color_override("default_color", normal_color)
		text = _base_text
