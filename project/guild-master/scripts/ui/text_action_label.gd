class_name TextActionLabel
extends RichTextLabel

signal clicked()

@export_group("Colors")
@export var normal_color: Color = Color("#e0e0e0")
@export var hover_color: Color = Color("#a0a0a8")

@export_group("Fonts")
@export_range(10, 32, 1) var font_size: int = 18

@export_group("Behavior")
@export var underline_on_hover: bool = true

var _base_text: String = ""

func _ready() -> void:
	bbcode_enabled = true
	fit_content = true
	scroll_active = false
	autowrap_mode = TextServer.AUTOWRAP_OFF
	mouse_filter = MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_size_override("normal_font_size", font_size)
	add_theme_color_override("default_color", normal_color)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_action_text(p_text: String) -> void:
	_base_text = p_text
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
