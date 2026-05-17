class_name NPCPanel
extends Control

signal clicked()

@export var bg_color: Color = Color(0.1, 0.1, 0.12, 0.7)
@export var name_font_size: int = 22
@export var text_color: Color = Color(1, 1, 1, 1)

@onready var _bg: ColorRect = $Background
@onready var _portrait: TextureRect = $MarginContainer/VBoxContainer/Portrait
@onready var _name: Label = $MarginContainer/VBoxContainer/NameLabel

func _ready() -> void:
	_apply_style()
	gui_input.connect(_on_gui_input)
	visible = false

func _apply_style() -> void:
	if _bg:
		_bg.color = bg_color
	if _name:
		_name.add_theme_font_size_override("font_size", name_font_size)
		_name.add_theme_color_override("font_color", text_color)

func set_npc(npc_data: Dictionary) -> void:
	visible = true
	_name.text = npc_data.get("display_name", "")
	var path: String = npc_data.get("portrait_path", "")
	if not path.is_empty() and ResourceLoader.exists(path):
		_portrait.texture = load(path)
	else:
		_portrait.texture = null

func clear() -> void:
	visible = false
	_name.text = ""
	_portrait.texture = null

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
