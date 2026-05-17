class_name ActionPanel
extends Control

signal action_pressed(interaction_id: String, scope: String, npc_id: String)

@export var bg_color: Color = Color(0.12, 0.12, 0.15, 0.9)
@export var title_font_size: int = 24
@export var section_font_size: int = 18
@export var button_font_size: int = 20
@export var button_min_width: float = 0.0
@export var button_min_height: float = 56.0
@export var separation: int = 12
@export var flow_separation_x: int = 8
@export var flow_separation_y: int = 8
@export var text_color: Color = Color(1, 1, 1, 1)

@onready var _bg: ColorRect = $Background
@onready var _title: Label = $MarginContainer/VBoxContainer/Title
@onready var _sections: VBoxContainer = $MarginContainer/VBoxContainer/Sections

var _current_flow: HFlowContainer = null

func _ready() -> void:
	_apply_style()

func _apply_style() -> void:
	if _bg:
		_bg.color = bg_color
	if _title:
		_title.add_theme_font_size_override("font_size", title_font_size)
		_title.add_theme_color_override("font_color", text_color)
	if _sections:
		_sections.add_theme_constant_override("separation", separation)

func set_title(text: String) -> void:
	if _title:
		_title.text = text

func clear() -> void:
	for child in _sections.get_children():
		child.queue_free()
	_current_flow = null

func add_section(text: String) -> void:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 6)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", section_font_size)
	label.add_theme_color_override("font_color", text_color)
	section.add_child(label)

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", flow_separation_x)
	flow.add_theme_constant_override("v_separation", flow_separation_y)
	section.add_child(flow)

	_sections.add_child(section)
	_current_flow = flow

func add_action(text: String, interaction_id: String, scope: String = "common", npc_id: String = "") -> void:
	if _current_flow == null:
		push_warning("ActionPanel: add_action called before add_section")
		return
	var btn := ModularButton.new()
	btn.text = text
	btn.font_size = button_font_size
	btn.min_width = button_min_width
	btn.min_height = button_min_height
	btn.pressed.connect(func(): action_pressed.emit(interaction_id, scope, npc_id))
	_current_flow.add_child(btn)
