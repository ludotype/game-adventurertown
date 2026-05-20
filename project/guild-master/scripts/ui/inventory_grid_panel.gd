class_name InventoryGridPanel
extends Control

signal item_selected(item_id: String)
signal inventory_closed()

@export_group("Layout Settings")
@export var padding_size: int = 16
@export var grid_columns: int = 5
@export var slot_size: Vector2 = Vector2(72, 72)
@export var grid_h_separation: int = 8
@export var grid_v_separation: int = 8

@export_group("Colors")
@export var text_color: Color = Color("#e0e0e0")
@export var slot_bg_color: Color = Color("#2a2a30")
@export var slot_border_color: Color = Color("#3a3a40")
@export var selected_slot_border_color: Color = Color("#a0a0a8")
@export var hover_slot_border_color: Color = Color("#4a4a52")

@export_group("Fonts")
@export_range(10, 32, 1) var title_font_size: int = 22
@export_range(8, 24, 1) var count_font_size: int = 12
@export_range(8, 24, 1) var equipped_font_size: int = 12

@export_group("UI References")
@export var title_label: Label
@export var grid_container: GridContainer
@export var empty_label: Label

var _selected_item_id: String = ""
var _slots: Dictionary = {}

func _ready() -> void:
	_resolve_references()
	_apply_dynamic_ui_settings()
	_refresh_grid()

func _resolve_references() -> void:
	if title_label == null:
		title_label = get_node_or_null("MarginContainer/VBoxContainer/Title")
	if grid_container == null:
		grid_container = get_node_or_null("MarginContainer/VBoxContainer/GridContainer")
	if empty_label == null:
		empty_label = get_node_or_null("MarginContainer/VBoxContainer/EmptyLabel")

func _apply_dynamic_ui_settings() -> void:
	if title_label:
		title_label.add_theme_font_size_override("font_size", title_font_size)
		title_label.add_theme_color_override("font_color", text_color)
	if grid_container:
		grid_container.columns = grid_columns
		grid_container.add_theme_constant_override("h_separation", grid_h_separation)
		grid_container.add_theme_constant_override("v_separation", grid_v_separation)

func _refresh_grid() -> void:
	if grid_container == null:
		return
	for child in grid_container.get_children():
		child.queue_free()
	_slots.clear()
	_selected_item_id = ""

	if not has_node("/root/InventoryManager"):
		if empty_label:
			empty_label.visible = true
		return

	var items := InventoryManager.get_all_items()
	if items.is_empty():
		if empty_label:
			empty_label.visible = true
		return

	if empty_label:
		empty_label.visible = false

	for item_id in items.keys():
		var entry: Dictionary = items[item_id]
		var def := ItemRegistry.get_item(item_id)
		if def.is_empty():
			continue
		var slot := _create_slot(item_id, entry, def)
		grid_container.add_child(slot)
		_slots[item_id] = slot

func _create_slot(item_id: String, entry: Dictionary, def: Dictionary) -> Control:
	var container := Control.new()
	container.custom_minimum_size = slot_size
	container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var slot_bg := Panel.new()
	slot_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var slot_style := StyleBoxFlat.new()
	slot_style.bg_color = slot_bg_color
	slot_style.border_width_left = 2
	slot_style.border_width_top = 2
	slot_style.border_width_right = 2
	slot_style.border_width_bottom = 2
	slot_style.border_color = slot_border_color
	slot_style.corner_radius_top_left = 2
	slot_style.corner_radius_top_right = 2
	slot_style.corner_radius_bottom_left = 2
	slot_style.corner_radius_bottom_right = 2
	slot_bg.add_theme_stylebox_override("panel", slot_style)
	container.add_child(slot_bg)

	var icon_path: String = def.get("icon_path", "")
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 4
		icon.offset_top = 4
		icon.offset_right = -4
		icon.offset_bottom = -12
		container.add_child(icon)

	var count: int = entry.get("count", 0)
	if count > 1:
		var count_lbl := Label.new()
		count_lbl.text = "x%d" % count
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_lbl.add_theme_font_size_override("font_size", count_font_size)
		count_lbl.add_theme_color_override("font_color", text_color)
		count_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		count_lbl.offset_left = -28
		count_lbl.offset_top = -16
		count_lbl.offset_right = -2
		count_lbl.offset_bottom = -2
		container.add_child(count_lbl)

	var equipped: bool = entry.get("equipped", false)
	if equipped:
		var eq_lbl := Label.new()
		eq_lbl.text = "E"
		eq_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		eq_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		eq_lbl.add_theme_font_size_override("font_size", equipped_font_size)
		eq_lbl.add_theme_color_override("font_color", selected_slot_border_color)
		eq_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
		eq_lbl.offset_left = 4
		eq_lbl.offset_top = 2
		container.add_child(eq_lbl)

	container.mouse_filter = Control.MOUSE_FILTER_STOP
	container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	container.gui_input.connect(_on_slot_gui_input.bind(item_id))
	container.mouse_entered.connect(_on_slot_mouse_entered.bind(item_id, slot_bg))
	container.mouse_exited.connect(_on_slot_mouse_exited.bind(item_id, slot_bg))

	return container

func _on_slot_gui_input(event: InputEvent, item_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_item(item_id)

func _select_item(item_id: String) -> void:
	_selected_item_id = item_id
	for id in _slots.keys():
		var slot_bg := _slots[id].get_child(0) as Panel
		if slot_bg == null:
			continue
		var style := slot_bg.get_theme_stylebox("panel") as StyleBoxFlat
		if style == null:
			continue
		style.border_color = selected_slot_border_color if id == item_id else slot_border_color
	item_selected.emit(item_id)

func _on_slot_mouse_entered(item_id: String, slot_bg: Panel) -> void:
	if item_id != _selected_item_id:
		var style := slot_bg.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.border_color = hover_slot_border_color

func _on_slot_mouse_exited(item_id: String, slot_bg: Panel) -> void:
	if item_id != _selected_item_id:
		var style := slot_bg.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.border_color = slot_border_color

func open() -> void:
	visible = true
	_refresh_grid()

func close() -> void:
	visible = false
	inventory_closed.emit()

func refresh() -> void:
	if visible:
		_refresh_grid()

func get_selected_item_id() -> String:
	return _selected_item_id
