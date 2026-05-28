@tool
extends Control

@onready var graph_edit: GraphEdit = $HSplitContainer/GraphEdit
@onready var sidebar: Control = $HSplitContainer/Sidebar

# 사이드바 세부 컨트롤
@onready var empty_notice: Label = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/EmptyNotice
@onready var duplicate_button: Button = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/DuplicateButton
@onready var id_label: Label = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/IDLabel
@onready var id_edit: LineEdit = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/IDLineEdit
@onready var name_label: Label = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/NameLabel
@onready var name_edit: LineEdit = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/NameLineEdit
@onready var type_label: Label = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/TypeLabel
@onready var type_option: OptionButton = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/TypeOptionButton
@onready var npc_label: Label = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/NPCLabel
@onready var npc_edit: LineEdit = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/NPCLineEdit

@onready var separator: HSeparator = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/HSeparator
@onready var separator2: HSeparator = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/HSeparator2

# 이동 경로 섹션
@onready var path_section: VBoxContainer = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/PathSection
@onready var add_path_button: Button = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/PathSection/AddPathButton
@onready var path_list_container: VBoxContainer = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/PathSection/PathListContainer

# 이벤트 섹션
@onready var event_section: VBoxContainer = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/EventSection
@onready var event_list_container: VBoxContainer = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/EventSection/EventListContainer
@onready var add_event_button: Button = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/EventSection/AddEventButton

# 툴바 버튼
@onready var save_button: Button = $Toolbar/SaveButton
@onready var load_button: Button = $Toolbar/LoadButton

var selected_node: GraphNode = null
var _popup_menu: PopupMenu
var _node_counter: int = 0
var _last_popup_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	_popup_menu = PopupMenu.new()
	_popup_menu.add_item("새 장소 노드 생성")
	_popup_menu.id_pressed.connect(_on_popup_menu_id_pressed)
	add_child(_popup_menu)

	# Godot 4.x GraphEdit 연결선 곡선 설정 및 드래그 연결 해제 기능 활성화
	graph_edit.connection_lines_curvature = 0.5
	graph_edit.right_disconnects = true

	graph_edit.popup_request.connect(_on_popup_request)
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.node_selected.connect(_on_node_selected)
	graph_edit.node_deselected.connect(_on_node_deselected)

	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)

	duplicate_button.pressed.connect(_on_duplicate_pressed)
	id_edit.text_changed.connect(_on_id_changed)
	name_edit.text_changed.connect(_on_name_changed)
	npc_edit.text_changed.connect(_on_npc_changed)
	
	type_option.clear()
	type_option.add_item("실내 / 주요 장소 (Indoors)", 0)
	type_option.add_item("야외 / 통로 (Outdoors)", 1)
	type_option.item_selected.connect(_on_type_selected)
	
	add_path_button.pressed.connect(_on_add_path_pressed)
	add_event_button.pressed.connect(_on_add_event_pressed)

	_update_sidebar_visibility(false)

func _on_popup_request(position: Vector2) -> void:
	var compensated_x = (position.x + graph_edit.scroll_offset.x) / graph_edit.zoom
	var compensated_y = (position.y + graph_edit.scroll_offset.y) / graph_edit.zoom
	_last_popup_position = Vector2(compensated_x, compensated_y)
	
	_popup_menu.position = Vector2i(get_global_mouse_position())
	_popup_menu.popup()

func _on_popup_menu_id_pressed(id: int) -> void:
	match id:
		0:
			var default_coords := {
				"coordinate": {
					"x": int(_last_popup_position.x),
					"y": int(_last_popup_position.y)
				}
			}
			_create_place_node(default_coords)

func _create_place_node(data: Dictionary = {}) -> void:
	var node = preload("res://addons/city_map_editor/map_place_node.gd").new()
	
	var default_data := {
		"id": "place_" + str(_node_counter),
		"display_name_kr": "새 장소",
		"place_type": "indoors",
		"coordinate": {
			"x": int(graph_edit.scroll_offset.x + 200),
			"y": int(graph_edit.scroll_offset.y + 200)
		},
		"size": {
			"x": 200,
			"y": 180
		}
	}
	_node_counter += 1
	for key in data.keys():
		if key == "coordinate":
			for coord_key in data["coordinate"].keys():
				default_data["coordinate"][coord_key] = data["coordinate"][coord_key]
		else:
			default_data[key] = data[key]
			
	var id_lower = default_data["id"].to_lower()
	var auto_outdoors := false
	for keyword in ["street", "path", "alley", "entrance", "road", "way", "passage"]:
		if keyword in id_lower:
			auto_outdoors = true
			break
	if auto_outdoors and not data.has("place_type"):
		default_data["place_type"] = "outdoors"
	
	graph_edit.add_child(node)
	node.setup_node(default_data)
	node.event_jump_requested.connect(_jump_to_dialogue)

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
	empty_notice.visible = not is_node_selected
	
	duplicate_button.visible = is_node_selected
	id_label.visible = is_node_selected
	id_edit.visible = is_node_selected
	name_label.visible = is_node_selected
	name_edit.visible = is_node_selected
	type_label.visible = is_node_selected
	type_option.visible = is_node_selected
	npc_label.visible = is_node_selected
	npc_edit.visible = is_node_selected
	separator.visible = is_node_selected
	path_section.visible = is_node_selected
	separator2.visible = is_node_selected
	event_section.visible = is_node_selected

func _load_node_to_sidebar() -> void:
	if not selected_node:
		return
	id_edit.text = selected_node.place_id
	name_edit.text = selected_node.display_name_kr
	
	var type_idx = 0 if selected_node.place_type == "indoors" else 1
	type_option.select(type_idx)
	
	npc_edit.text = ", ".join(selected_node.base_npc)
	_refresh_sidebar_path_list()
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

func _on_type_selected(index: int) -> void:
	if selected_node:
		selected_node.place_type = "indoors" if index == 0 else "outdoors"
		selected_node._update_node_view()

func _on_npc_changed(new_text: String) -> void:
	if selected_node:
		selected_node.base_npc.clear()
		for s in new_text.split(","):
			var trimmed := s.strip_edges()
			if trimmed != "":
				selected_node.base_npc.append(trimmed)

func _on_duplicate_pressed() -> void:
	if not selected_node:
		return
		
	var original_id = selected_node.place_id
	var copy_id = original_id + "_copy"
	
	var safety_counter = 1
	while graph_edit.has_node(copy_id):
		copy_id = original_id + "_copy" + str(safety_counter)
		safety_counter += 1
		
	var copied_paths: Array = []
	for p in selected_node.paths:
		copied_paths.append({
			"button_name": p.get("button_name", "") + " (복제)",
			"target_place_id": "",
			"movement_cost": p.get("movement_cost", 1)
		})
		
	var copied_events: Array = []
	for ev in selected_node.events:
		copied_events.append({
			"event_id": ev.get("event_id", "") + "_copy",
			"display_name": ev.get("display_name", "") + " (복제)",
			"dialogue_file": ev.get("dialogue_file", ""),
			"dialogue_title": ev.get("dialogue_title", ""),
			"triggers": ev.get("triggers", {}).duplicate(true)
		})
		
	var copied_data := {
		"id": copy_id,
		"display_name_kr": selected_node.display_name_kr + " (복사본)",
		"place_type": selected_node.place_type,
		"coordinate": {
			"x": int(selected_node.position_offset.x + 80),
			"y": int(selected_node.position_offset.y + 80)
		},
		"base_npc": selected_node.base_npc.duplicate(),
		"paths": copied_paths,
		"events": copied_events
	}
	
	_create_place_node(copied_data)
	
	var new_node = graph_edit.get_node(copy_id)
	if new_node is GraphNode:
		if selected_node:
			selected_node.selected = false
		new_node.selected = true
		_on_node_selected(new_node)
		print("Successfully duplicated node: ", original_id, " -> ", copy_id)

func _on_add_path_pressed() -> void:
	if not selected_node:
		return
	selected_node.paths.append({
		"button_name": "새 이동 경로",
		"target_place_id": "",
		"movement_cost": 1
	})
	selected_node._update_node_view()
	_refresh_sidebar_path_list()

func _refresh_sidebar_path_list() -> void:
	for child in path_list_container.get_children():
		child.queue_free()

	if not selected_node:
		return

	for i in range(selected_node.paths.size()):
		var path_idx = i
		var path_data = selected_node.paths[path_idx]
		
		var item_vbox = PathDragDropPanel.new()
		item_vbox.path_index = path_idx
		item_vbox.dock = self
		path_list_container.add_child(item_vbox)
		
		# 첫 번째 줄: 드래그 핸들(↕) + 경로명 입력 + 삭제
		var row1 = HBoxContainer.new()
		item_vbox.add_child(row1)
		
		var label_handle = Label.new()
		label_handle.text = " ↕ "
		label_handle.modulate = Color(0.3, 0.8, 0.5)
		label_handle.mouse_filter = Control.MOUSE_FILTER_PASS
		label_handle.tooltip_text = "이곳을 마우스로 잡아 드래그하면 위아래 순서가 변경됩니다."
		row1.add_child(label_handle)
		
		var edit_name = LineEdit.new()
		edit_name.text = path_data.get("button_name", "")
		edit_name.placeholder_text = "경로 선택지 이름"
		edit_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit_name.text_changed.connect(func(new_text: String):
			path_data["button_name"] = new_text
			if selected_node:
				selected_node._update_node_view()
		)
		row1.add_child(edit_name)
		
		var btn_del = Button.new()
		btn_del.text = "🗑"
		btn_del.pressed.connect(func():
			if selected_node:
				_disconnect_port_visuals_only(selected_node.name, path_idx)
				selected_node.paths.remove_at(path_idx)
				selected_node._update_node_view()
				_refresh_sidebar_path_list()
		)
		row1.add_child(btn_del)
		
		# 두 번째 줄: 목적지 ID 입력
		var row2 = HBoxContainer.new()
		item_vbox.add_child(row2)
		
		var label_target = Label.new()
		label_target.text = "  └ 🎯 대상 ID: "
		label_target.modulate = Color(0.7, 0.7, 0.7)
		row2.add_child(label_target)
		
		var edit_target_id = LineEdit.new()
		edit_target_id.text = path_data.get("target_place_id", "")
		edit_target_id.placeholder_text = "ex) inn_lobby (목적지 장소 ID)"
		edit_target_id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# 중요 🌟: 사이드바 -> 캔버스 실시간 피드백 바인딩!
		edit_target_id.text_changed.connect(func(new_target_id: String):
			var trimmed = new_target_id.strip_edges()
			path_data["target_place_id"] = trimmed
			
			# 1. 캔버스 상의 기존 연결선(있다면) 선제적으로 제거
			_disconnect_port_visuals_only(selected_node.name, path_idx)
			
			# 2. 만약 입력한 ID를 갖는 노드가 실제로 존재한다면, 캔버스 상에 연결선을 시각적으로 이어줌!
			if trimmed != "":
				var target_node = graph_edit.get_node_or_null(trimmed)
				if target_node and target_node is GraphNode:
					graph_edit.connect_node(selected_node.name, path_idx, target_node.name, 0)
		)
		row2.add_child(edit_target_id)
		
		# 아이템 간 구분을 위한 연한 구분선
		var item_sep = HSeparator.new()
		item_sep.modulate = Color(1.0, 1.0, 1.0, 0.2)
		item_vbox.add_child(item_sep)

func _disconnect_port_visuals_only(node_name: String, port_idx: int) -> void:
	for conn in graph_edit.get_connection_list():
		if conn.get("from", "") == node_name and conn.get("from_port", -1) == port_idx:
			graph_edit.disconnect_node(node_name, port_idx, conn.get("to", ""), conn.get("to_port", 0))

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
		var ev_idx = i
		var ev = selected_node.events[ev_idx]
		
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
			if selected_node:
				selected_node.events.remove_at(ev_idx)
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
	var from_node_obj = graph_edit.get_node(str(from_node))
	var to_node_obj = graph_edit.get_node(str(to_node))
	
	if from_node_obj and to_node_obj:
		if from_port < from_node_obj.paths.size():
			from_node_obj.paths[from_port]["target_place_id"] = to_node_obj.place_id
			graph_edit.connect_node(from_node, from_port, to_node, to_port)
			print("Connected path: ", from_node_obj.paths[from_port]["button_name"], " -> ", to_node_obj.place_id)
			
			# 캔버스 -> 사이드바 실시간 동기화 🌟
			if selected_node == from_node_obj:
				_refresh_sidebar_path_list()

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var from_node_obj = graph_edit.get_node(str(from_node))
	if from_node_obj:
		if from_port < from_node_obj.paths.size():
			from_node_obj.paths[from_port]["target_place_id"] = ""
			graph_edit.disconnect_node(from_node, from_port, to_node, to_port)
			print("Disconnected path index: ", from_port)
			
			# 캔버스 -> 사이드바 실시간 동기화 🌟
			if selected_node == from_node_obj:
				_refresh_sidebar_path_list()

func _on_save_pressed() -> void:
	var places: Array = []
	for child in graph_edit.get_children():
		if child is GraphNode:
			var node: GraphNode = child
			places.append({
				"id": node.place_id,
				"display_name_kr": node.display_name_kr,
				"place_type": node.place_type,
				"coordinate": {
					"x": int(node.position_offset.x),
					"y": int(node.position_offset.y)
				},
				"size": {
					"x": int(node.size.x),
					"y": int(node.size.y)
				},
				"base_npc": node.base_npc,
				"events": node.events,
				"paths": node.paths
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
	graph_edit.clear_connections()

	var places_data := _load_json("res://data/places.json")
	var places: Array = places_data.get("places", [])
	for p in places:
		_create_place_node(p)

	await get_tree().process_frame

	# GraphEdit 연결선 직선화 재강제
	graph_edit.connection_lines_curvature = 0.0

	for child in graph_edit.get_children():
		if child is GraphNode:
			var node: GraphNode = child
			for i in range(node.paths.size()):
				var path_data = node.paths[i]
				var target_id = path_data.get("target_place_id", "")
				if target_id != "":
					var target_node = graph_edit.get_node_or_null(target_id)
					if target_node:
						graph_edit.connect_node(node.name, i, target_node.name, 0)
						


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

# ==========================================
# 🌟 이동 경로 드래그 앤 드롭 순서 변경 이너 클래스 및 헬퍼
# ==========================================

func _on_path_reordered(from_idx: int, to_idx: int) -> void:
	if not selected_node:
		return
		
	var paths = selected_node.paths
	if from_idx < 0 or from_idx >= paths.size() or to_idx < 0 or to_idx >= paths.size():
		return
		
	# 1. 데이터 상 순서 체인지
	var moved_item = paths.remove_at(from_idx)
	paths.insert(to_idx, moved_item)
	
	# 2. 캔버스 슬롯 및 연결망 물리적 재건 (데이터 포트 인덱스 동기화 보장)
	selected_node._update_node_view()
	_rebuild_node_connections(selected_node)
	
	# 3. 사이드바 UI 리프레시
	_refresh_sidebar_path_list()
	print("Successfully reordered path: ", from_idx, " -> ", to_idx)

func _rebuild_node_connections(node: GraphNode) -> void:
	# 이 노드에서 출발해 뻗어나가던 모든 선을 임시 제거
	for conn in graph_edit.get_connection_list():
		if conn.get("from", "") == node.name:
			graph_edit.disconnect_node(node.name, conn.get("from_port", 0), conn.get("to", ""), conn.get("to_port", 0))
	
	# 새로운 순서에 대치되도록 시각적 연결 곡선을 완벽히 재배치 복구
	for i in range(node.paths.size()):
		var path_data = node.paths[i]
		var target_id = path_data.get("target_place_id", "")
		if target_id != "":
			var target_node = graph_edit.get_node_or_null(target_id)
			if target_node:
				graph_edit.connect_node(node.name, i, target_node.name, 0)

# 드래그 앤 드롭 정렬 감지 패널
class PathDragDropPanel extends VBoxContainer:
	var path_index: int = 0
	var dock: Control = null
	
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		
	func _get_drag_data(_at_position: Vector2) -> Variant:
		var preview = Label.new()
		preview.text = "↕ 이동 경로 정렬 변경 중..."
		preview.modulate = Color(0.3, 0.8, 0.5)
		set_drag_preview(preview)
		return {"from_idx": path_index}
		
	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("from_idx")
		
	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		var from_idx = data.get("from_idx", -1)
		var to_idx = path_index
		if from_idx != -1 and from_idx != to_idx:
			dock._on_path_reordered(from_idx, to_idx)
