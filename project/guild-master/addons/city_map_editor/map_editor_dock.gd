@tool
extends Control

@onready var graph_edit: GraphEdit = $HSplitContainer/GraphEdit
@onready var sidebar: Control = $HSplitContainer/Sidebar

# 사이드바 세부 컨트롤
@onready var empty_notice: Label = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/EmptyNotice
@onready var id_label: Label = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/IDLabel
@onready var id_edit: LineEdit = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/IDLineEdit
@onready var name_label: Label = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/NameLabel
@onready var name_edit: LineEdit = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/NameLineEdit
@onready var npc_label: Label = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/NPCLabel
@onready var npc_edit: LineEdit = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/NPCLineEdit
@onready var separator: HSeparator = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/HSeparator
@onready var event_section: VBoxContainer = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/EventSection
@onready var event_list_container: VBoxContainer = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/EventSection/EventListContainer
@onready var add_event_button: Button = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/EventSection/AddEventButton

# 툴바 버튼
@onready var save_button: Button = $Toolbar/SaveButton
@onready var load_button: Button = $Toolbar/LoadButton

var selected_node: GraphNode = null
var _popup_menu: PopupMenu
var _node_counter: int = 0

func _ready() -> void:
	_popup_menu = PopupMenu.new()
	_popup_menu.add_item("새 장소 노드 생성")
	_popup_menu.id_pressed.connect(_on_popup_menu_id_pressed)
	add_child(_popup_menu)

	graph_edit.popup_request.connect(_on_popup_request)
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.node_selected.connect(_on_node_selected)
	graph_edit.node_deselected.connect(_on_node_deselected)

	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)

	id_edit.text_changed.connect(_on_id_changed)
	name_edit.text_changed.connect(_on_name_changed)
	npc_edit.text_changed.connect(_on_npc_changed)
	add_event_button.pressed.connect(_on_add_event_pressed)

	# 초기에 사이드바 입력창들 숨김 처리 (플레이스홀더 안내 라벨만 출력)
	_update_sidebar_visibility(false)

func _on_popup_request(_position: Vector2) -> void:
	_popup_menu.position = Vector2i(get_global_mouse_position())
	_popup_menu.popup()

func _on_popup_menu_id_pressed(id: int) -> void:
	match id:
		0:
			_create_place_node()

func _create_place_node(data: Dictionary = {}) -> void:
	var node = preload("res://addons/city_map_editor/map_place_node.gd").new()
	var default_data := {
		"id": "place_" + str(_node_counter),
		"display_name_kr": "새 장소",
		"coordinate": {
			"x": int(graph_edit.scroll_offset.x + 200),
			"y": int(graph_edit.scroll_offset.y + 200)
		}
	}
	_node_counter += 1
	for key in data.keys():
		default_data[key] = data[key]
	node.setup_node(default_data)
	graph_edit.add_child(node)

func _on_node_selected(node: Node) -> void:
	if node is GraphNode:
		selected_node = node
		_update_sidebar_visibility(true)
		_load_node_to_sidebar()

func _on_node_deselected(node: Node) -> void:
	if selected_node == node:
		selected_node = null
		_update_sidebar_visibility(false)

func _update_sidebar_visibility(is_node_selected: bool) -> void:
	# 노드 선택 여부에 따라 사이드바 컨트롤들의 노출 상태 전환
	empty_notice.visible = not is_node_selected
	
	id_label.visible = is_node_selected
	id_edit.visible = is_node_selected
	name_label.visible = is_node_selected
	name_edit.visible = is_node_selected
	npc_label.visible = is_node_selected
	npc_edit.visible = is_node_selected
	separator.visible = is_node_selected
	event_section.visible = is_node_selected

func _load_node_to_sidebar() -> void:
	if not selected_node:
		return
	id_edit.text = selected_node.place_id
	name_edit.text = selected_node.display_name_kr
	npc_edit.text = ", ".join(selected_node.base_npc)
	_refresh_sidebar_event_list()

func _on_id_changed(new_text: String) -> void:
	if selected_node:
		selected_node.place_id = new_text
		selected_node.name = new_text
		selected_node._update_node_view()

func _on_name_changed(new_text: String) -> void:
	if selected_node:
		selected_node.display_name_kr = new_text
		selected_node._update_node_view()

func _on_npc_changed(new_text: String) -> void:
	if selected_node:
		selected_node.base_npc.clear()
		for s in new_text.split(","):
			var trimmed := s.strip_edges()
			if trimmed != "":
				selected_node.base_npc.append(trimmed)

func _on_add_event_pressed() -> void:
	if not selected_node:
		return
	selected_node.events.append({
		"event_id": "evt_new_" + str(selected_node.events.size()),
		"display_name": "새 이벤트",
		"dialogue_file": "",
		"dialogue_title": "",
		"triggers": {}
	})
	_refresh_sidebar_event_list()

func _refresh_sidebar_event_list() -> void:
	for child in event_list_container.get_children():
		child.queue_free()

	if not selected_node:
		return

	for i in range(selected_node.events.size()):
		var ev = selected_node.events[i]
		var hbox = HBoxContainer.new()
		event_list_container.add_child(hbox)

		var edit_ev_name = LineEdit.new()
		edit_ev_name.text = ev.get("display_name", "")
		edit_ev_name.placeholder_text = "이벤트명"
		edit_ev_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit_ev_name.text_changed.connect(func(new_text: String):
			ev["display_name"] = new_text
		)
		hbox.add_child(edit_ev_name)

		var btn_jump = Button.new()
		btn_jump.text = "점프"
		btn_jump.pressed.connect(func():
			_jump_to_dialogue(ev.get("dialogue_file", ""), ev.get("dialogue_title", ""))
		)
		hbox.add_child(btn_jump)

		var btn_del = Button.new()
		btn_del.text = "🗑"
		btn_del.pressed.connect(func():
			selected_node.events.remove_at(i)
			_refresh_sidebar_event_list()
		)
		hbox.add_child(btn_del)

func _jump_to_dialogue(file_path: String, title_label: String) -> void:
	if file_path == "":
		return
	if not FileAccess.file_exists(file_path):
		printerr("Dialogue file does not exist: ", file_path)
		return

	var dialogue_resource = load(file_path)
	if dialogue_resource:
		EditorInterface.edit_resource(dialogue_resource)
		EditorInterface.select_file(file_path)
		print("Successfully opened and jumped to dialogue: ", file_path)

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_edit.connect_node(from_node, from_port, to_node, to_port)

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)

func _on_save_pressed() -> void:
	var places: Array = []
	for child in graph_edit.get_children():
		if child is GraphNode:
			var node: GraphNode = child
			places.append({
				"id": node.place_id,
				"display_name_kr": node.display_name_kr,
				"coordinate": {
					"x": int(node.position_offset.x),
					"y": int(node.position_offset.y)
				},
				"base_npc": node.base_npc,
				"events": node.events
			})
	var places_data := {"places": places}
	var connections_data := {"connections": _get_connections_from_graph_edit()}
	_save_json("res://data/places.json", places_data)
	_save_json("res://data/connections.json", connections_data)

func _get_connections_from_graph_edit() -> Array:
	var result: Array = []
	for conn in graph_edit.get_connection_list():
		result.append({
			"from": str(conn.get("from", "")),
			"from_port": conn.get("from_port", 0),
			"to": str(conn.get("to", "")),
			"to_port": conn.get("to_port", 0),
			"movement_cost": 1
		})
	return result

func _on_load_pressed() -> void:
	for child in graph_edit.get_children():
		if child is GraphNode:
			child.queue_free()

	var places_data := _load_json("res://data/places.json")
	var connections_data := _load_json("res://data/connections.json")

	var places: Array = places_data.get("places", [])
	for p in places:
		_create_place_node(p)

	var connections: Array = connections_data.get("connections", [])
	for c in connections:
		var from_node := StringName(c.get("from", ""))
		var from_port: int = c.get("from_port", 0)
		var to_node := StringName(c.get("to", ""))
		var to_port: int = c.get("to_port", 0)
		graph_edit.connect_node(from_node, from_port, to_node, to_port)

func _save_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("Saved: ", path)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file for reading: " + path)
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		push_error("JSON parse error in " + path + ": " + json.get_error_message())
		return {}
	var result = json.get_data()
	if result is Dictionary:
		return result
	return {}
