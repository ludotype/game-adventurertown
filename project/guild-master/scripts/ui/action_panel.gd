class_name ActionPanel
extends Control

signal action_pressed(interaction_id: String, scope: String, npc_id: String)
signal move_pressed(place_id: String)

@export var bg_color: Color = Color("#1a1a1e")
@export var border_color: Color = Color("#3a3a40")
@export var title_font_size: int = 22
@export var section_font_size: int = 18
@export var action_font_size: int = 18
@export var separation: int = 10
@export var flow_separation_x: int = 16
@export var flow_separation_y: int = 8
@export var text_color: Color = Color("#EAE6DF")
@export var section_color: Color = Color("#c0bcb5")
@export var separator_color: Color = Color("#3a3a40")

@onready var _bg: Panel = $Background
@onready var _title: Label = $MarginContainer/VBoxContainer/Title
@onready var _sections: VBoxContainer = $MarginContainer/VBoxContainer/Sections

var _current_flow: HFlowContainer = null

func _ready() -> void:
	_apply_style()

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
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_size_override("font_size", section_font_size)
	label.add_theme_color_override("font_color", section_color)
	section.add_child(label)

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", flow_separation_x)
	flow.add_theme_constant_override("v_separation", flow_separation_y)
	section.add_child(flow)

	_sections.add_child(section)
	_current_flow = flow

func add_separator() -> void:
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.color = separator_color
	_sections.add_child(line)
	_current_flow = null

func add_action(text: String, interaction_id: String, scope: String = "common", npc_id: String = "") -> void:
	if _current_flow == null:
		push_warning("ActionPanel: add_action called before add_section")
		return
	var lbl := TextActionLabel.new()
	lbl.set_action_text(text)
	lbl.font_size = action_font_size
	lbl.normal_color = text_color
	lbl.clicked.connect(func(): action_pressed.emit(interaction_id, scope, npc_id))
	_current_flow.add_child(lbl)

func add_movement(display_name: String, place_id: String) -> void:
	if _current_flow == null:
		push_warning("ActionPanel: add_movement called before add_section")
		return
	var lbl := TextActionLabel.new()
	lbl.set_action_text(display_name)
	lbl.font_size = action_font_size
	lbl.normal_color = text_color
	lbl.clicked.connect(func(): move_pressed.emit(place_id))
	_current_flow.add_child(lbl)
