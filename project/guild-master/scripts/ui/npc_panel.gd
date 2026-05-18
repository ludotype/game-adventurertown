class_name NPCPanel
extends Control

signal clicked()

@export var bg_color: Color = Color("#1a1a1e")
@export var border_color: Color = Color("#3a3a40")
@export var name_font_size: int = 20
@export var text_color: Color = Color("#EAE6DF")

@onready var _bg: Panel = $Background
@onready var _portrait: TextureRect = $MarginContainer/VBoxContainer/Portrait
@onready var _name: Label = $MarginContainer/VBoxContainer/NameLabel

func _ready() -> void:
	_apply_style()
	gui_input.connect(_on_gui_input)
	visible = false

func _apply_style() -> void:
	if _bg:
		var border := StyleBoxFlat.new()
		border.bg_color = bg_color
		border.border_width_left = 2
		border.border_width_top = 2
		border.border_width_right = 2
		border.border_width_bottom = 2
		border.border_color = border_color
		border.corner_radius_top_left = 4
		border.corner_radius_top_right = 4
		border.corner_radius_bottom_left = 4
		border.corner_radius_bottom_right = 4
		_bg.add_theme_stylebox_override("panel", border)
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
