class_name ActionPanel
extends Control

signal action_pressed(interaction_id: String, scope: String, npc_id: String)
signal move_pressed(place_id: String)

@export_group("Layout Settings")
@export var padding_size: int = 16
@export var section_separation: int = 12
@export var flow_h_separation: int = 12
@export var flow_v_separation: int = 8

@export_group("Colors")
@export var text_color: Color = Color("#e0e0e0")
@export var section_color: Color = Color("#a0a0a8")
@export var dim_color: Color = Color("#808088")
@export var separator_color: Color = Color("#3a3a40")

@export_group("Fonts")
@export_range(10, 32, 1) var title_font_size: int = 22
@export_range(10, 28, 1) var section_font_size: int = 18
@export_range(10, 28, 1) var action_font_size: int = 18

@export_group("UI References")
@export var margin_container: MarginContainer
@export var title_label: Label
@export var sections_container: VBoxContainer

var _current_flow: HFlowContainer = null

func _ready() -> void:
	_resolve_references()
	_apply_dynamic_ui_settings()

func _resolve_references() -> void:
	if margin_container == null:
		margin_container = get_node_or_null("MarginContainer")
	if title_label == null:
		title_label = get_node_or_null("MarginContainer/VBoxContainer/Title")
	if sections_container == null:
		sections_container = get_node_or_null("MarginContainer/VBoxContainer/Sections")

func _apply_dynamic_ui_settings() -> void:
	if margin_container:
		margin_container.add_theme_constant_override("margin_left", padding_size)
		margin_container.add_theme_constant_override("margin_right", padding_size)
		margin_container.add_theme_constant_override("margin_top", padding_size)
		margin_container.add_theme_constant_override("margin_bottom", padding_size)
	if title_label:
		title_label.add_theme_font_size_override("font_size", title_font_size)
		title_label.add_theme_color_override("font_color", text_color)
	if sections_container:
		sections_container.add_theme_constant_override("separation", section_separation)

func set_title(text: String) -> void:
	if title_label:
		title_label.text = text

func clear() -> void:
	if sections_container:
		for child in sections_container.get_children():
			child.queue_free()
	_current_flow = null

func add_section(text: String) -> void:
	if sections_container == null:
		return
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_size_override("font_size", section_font_size)
	label.add_theme_color_override("font_color", section_color)
	section.add_child(label)

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", flow_h_separation)
	flow.add_theme_constant_override("v_separation", flow_v_separation)
	section.add_child(flow)

	sections_container.add_child(section)
	_current_flow = flow

func add_separator() -> void:
	if sections_container == null:
		return
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, 2)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.color = separator_color
	margin.add_child(line)
	sections_container.add_child(margin)
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
	if sections_container == null:
		push_warning("ActionPanel: sections_container is null")
		return
	var lbl := TextActionLabel.new()
	lbl.set_action_text(display_name)
	lbl.font_size = action_font_size
	lbl.normal_color = text_color
	lbl.clicked.connect(func(): move_pressed.emit(place_id))
	if _current_flow != null:
		_current_flow.add_child(lbl)
	else:
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", flow_h_separation)
		flow.add_theme_constant_override("v_separation", flow_v_separation)
		sections_container.add_child(flow)
		_current_flow = flow
		_current_flow.add_child(lbl)

func add_spacer() -> void:
	if sections_container == null:
		return
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sections_container.add_child(spacer)
	_current_flow = null

func add_back_button(text: String, callback: Callable) -> void:
	var lbl := TextActionLabel.new()
	lbl.set_action_text(text)
	lbl.font_size = action_font_size
	lbl.normal_color = text_color
	lbl.clicked.connect(callback)
	sections_container.add_child(lbl)
	_current_flow = null

func add_custom_label(text: String, font_size_override: int = -1, color_override: Color = Color()) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font_size_override > 0:
		lbl.add_theme_font_size_override("font_size", font_size_override)
	if color_override != Color():
		lbl.add_theme_color_override("font_color", color_override)
	else:
		lbl.add_theme_color_override("font_color", text_color)
	sections_container.add_child(lbl)
	return lbl

func add_texture_rect(texture: Texture2D, p_size: Vector2) -> TextureRect:
	var tex_rect := TextureRect.new()
	tex_rect.texture = texture
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.custom_minimum_size = p_size
	sections_container.add_child(tex_rect)
	return tex_rect

func add_action_callback(text: String, callback: Callable) -> void:
	if _current_flow == null:
		push_warning("ActionPanel: add_action_callback called before add_section")
		return
	var lbl := TextActionLabel.new()
	lbl.set_action_text(text)
	lbl.font_size = action_font_size
	lbl.normal_color = text_color
	lbl.clicked.connect(callback)
	_current_flow.add_child(lbl)
