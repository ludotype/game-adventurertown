class_name NPCPanel
extends Control

signal clicked()

@export_group("Layout Settings")
@export var padding_size: int = 8
@export var portrait_size: Vector2 = Vector2(64, 64)

@export_group("Colors")
@export var text_color: Color = Color("#e0e0e0")
@export var accent_color: Color = Color("#a0a0a8")
@export var dim_color: Color = Color("#808088")

@export_group("Fonts")
@export_range(10, 32, 1) var name_font_size: int = 16

@export_group("UI References")
@export var portrait_rect: TextureRect
@export var name_label: Label
@export var background: Panel

var _current_npc_data: Dictionary = {}

func _ready() -> void:
	_resolve_references()
	visible = false
	gui_input.connect(_on_gui_input)
	if portrait_rect:
		portrait_rect.custom_minimum_size = portrait_size
		portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _resolve_references() -> void:
	if portrait_rect == null:
		portrait_rect = get_node_or_null("MarginContainer/VBoxContainer/Portrait")
	if name_label == null:
		name_label = get_node_or_null("MarginContainer/VBoxContainer/NameLabel")
	if background == null:
		background = get_node_or_null("Background")

func set_npc(npc_data: Dictionary) -> void:
	_current_npc_data = npc_data
	visible = true
	if name_label:
		name_label.text = npc_data.get("display_name", "")
		name_label.add_theme_font_size_override("font_size", name_font_size)
		name_label.add_theme_color_override("font_color", text_color)
	var path: String = npc_data.get("portrait_path", "")
	if not path.is_empty() and ResourceLoader.exists(path):
		if portrait_rect:
			portrait_rect.texture = load(path)
	else:
		if portrait_rect:
			portrait_rect.texture = null

func clear() -> void:
	visible = false
	_current_npc_data.clear()
	if name_label:
		name_label.text = ""
	if portrait_rect:
		portrait_rect.texture = null

func get_current_npc_id() -> String:
	return _current_npc_data.get("npc_id", "")

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
