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

# 이벤트 섹션 및 팝업 에디터
@onready var event_section: VBoxContainer = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/EventSection
@onready var open_event_editor_button: Button = $HSplitContainer/Sidebar/ScrollContainer/SidebarContent/EventSection/OpenEventEditorButton
@onready var event_editor_dialog: AcceptDialog = $EventEditorDialog
@onready var add_event_popup_button: Button = $EventEditorDialog/DialogVBox/AddEventPopupButton
@onready var event_popup_list_container: VBoxContainer = $EventEditorDialog/DialogVBox/DialogScroll/EventPopupListContainer

# 툴바 버튼
@onready var save_button: Button = $Toolbar/SaveButton
@onready var load_button: Button = $Toolbar/LoadButton

var selected_node: GraphNode = null
var _popup_menu: PopupMenu
var _node_counter: int = 0
var _last_popup_position: Vector2 = Vector2.ZERO

# EditorFileDialog 탐색기 바인딩 변수 🌟
var _file_dialog: EditorFileDialog
var _active_event_line_edit: LineEdit
var _active_event_dict: Dictionary

func _ready() -> void:
	_popup_menu = PopupMenu.new()
	_popup_menu.add_item("새 장소 노드 생성")
	_popup_menu.id_pressed.connect(_on_popup_menu_id_pressed)
	add_child(_popup_menu)

	# EditorFileDialog 동적 초기화 🌟
	_file_dialog = EditorFileDialog.new()
	_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.add_filter("*.dialogue", "Dialogue Files (*.dialogue)")
	_file_dialog.title = "대화 스크립트 파일 선택"
	_file_dialog.file_selected.connect(_on_dialogue_file_selected)
	add_child(_file_dialog)

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
	open_event_editor_button.pressed.connect(_on_open_event_editor_pressed)
	add_event_popup_button.pressed.connect(_on_add_event_popup_pressed)
	event_editor_dialog.confirmed.connect(_on_event_dialog_closed)
	event_editor_dialog.canceled.connect(_on_event_dialog_closed)

	_update_sidebar_visibility(false)

func _on_popup_request(position: Vector2) -> void:
	var compensated_x = (position.x + graph_edit.scroll_offset.x) / graph_edit.zoom
	var compensated_y = (position.y + graph_edit.scroll_offset.y) / graph_edit.zoom
	_last_popup_position = Vector2(compensated_x, compensated_y)

	_popup_menu.clear()
	_popup_menu.add_item("새 장소 노드 생성")
	_popup_menu.position = Vector2i(get_global_mouse_position())
	_popup_menu.popup()

func _on_node_context_menu_requested(node: GraphNode, position: Vector2) -> void:
	node.selected = true
	_on_node_selected(node)

	_popup_menu.clear()
	_popup_menu.add_item("새 장소 노드 생성")
	_popup_menu.add_item("현재 노드 삭제")
	_popup_menu.position = Vector2i(position)
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
		1:
			_delete_selected_node()

func _delete_selected_node() -> void:
	if not selected_node:
		return

	var node_name = selected_node.name

	# 타 노드의 경로 중 이 노드를 가리키는 target_place_id를 정리
	for child in graph_edit.get_children():
		if child is GraphNode and child != selected_node:
			for path in child.paths:
				if path.get("target_place_id", "") == node_name:
					path["target_place_id"] = ""

	# 이 노드와 연결된 모든 연결선 제거
	for conn in graph_edit.get_connection_list():
		if conn.get("from", "") == node_name or conn.get("to", "") == node_name:
			graph_edit.disconnect_node(
				conn.get("from", ""),
				conn.get("from_port", 0),
				conn.get("to", ""),
				conn.get("to_port", 0)
			)

	graph_edit.remove_child(selected_node)
	selected_node.queue_free()
	selected_node = null

	_update_sidebar_visibility(false)
	print("Deleted node: ", node_name)

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
	node.context_menu_requested.connect(func(pos: Vector2):
		_on_node_context_menu_requested(node, pos)
	)

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

# ==========================================
# 🌟 사이드바 경로 리스트 헬퍼 (클로저 버그 방지)
# ==========================================

func _create_path_up_button(idx: int) -> Button:
	var btn = Button.new()
	btn.text = "▲"
	btn.tooltip_text = "이 이동 경로를 위로 한 칸 올립니다."
	btn.disabled = (idx == 0)
	btn.pressed.connect(func():
		_on_path_swapped(idx, idx - 1)
	)
	return btn

func _create_path_down_button(idx: int, max_idx: int) -> Button:
	var btn = Button.new()
	btn.text = "▼"
	btn.tooltip_text = "이 이동 경로를 아래로 한 칸 내립니다."
	btn.disabled = (idx == max_idx)
	btn.pressed.connect(func():
		_on_path_swapped(idx, idx + 1)
	)
	return btn

func _create_path_name_edit(path_data: Dictionary) -> LineEdit:
	var edit = LineEdit.new()
	edit.text = path_data.get("button_name", "")
	edit.placeholder_text = "경로 선택지 이름"
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(func(new_text: String):
		path_data["button_name"] = new_text
		if selected_node:
			selected_node._update_node_view()
	)
	return edit

func _create_path_target_edit(path_data: Dictionary, path_idx: int) -> LineEdit:
	var edit = LineEdit.new()
	edit.text = path_data.get("target_place_id", "")
	edit.placeholder_text = "ex) inn_lobby (목적지 장소 ID)"
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(func(new_target_id: String):
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
	return edit

func _create_path_delete_button(node: GraphNode, idx: int) -> Button:
	var btn = Button.new()
	btn.text = "🗑"
	btn.pressed.connect(func():
		_disconnect_port_visuals_only(node.name, idx)
		node.paths.remove_at(idx)
		node._update_node_view()
		_refresh_sidebar_path_list()
	)
	return btn

func _refresh_sidebar_path_list() -> void:
	for child in path_list_container.get_children():
		child.queue_free()

	if not selected_node:
		return

	for i in range(selected_node.paths.size()):
		var path_data = selected_node.paths[i]
		var max_idx = selected_node.paths.size() - 1

		var item_vbox = VBoxContainer.new()
		path_list_container.add_child(item_vbox)

		# 첫 번째 줄: 정렬 버튼(▲/▼) + 경로명 입력 + 삭제
		var row1 = HBoxContainer.new()
		item_vbox.add_child(row1)

		row1.add_child(_create_path_up_button(i))
		row1.add_child(_create_path_down_button(i, max_idx))
		row1.add_child(_create_path_name_edit(path_data))
		row1.add_child(_create_path_delete_button(selected_node, i))

		# 두 번째 줄: 목적지 ID 입력
		var row2 = HBoxContainer.new()
		item_vbox.add_child(row2)

		var label_target = Label.new()
		label_target.text = "  └ 🎯 대상 ID: "
		label_target.modulate = Color(0.7, 0.7, 0.7)
		row2.add_child(label_target)

		row2.add_child(_create_path_target_edit(path_data, i))

		# 아이템 간 구분을 위한 연한 구분선
		var item_sep = HSeparator.new()
		item_sep.modulate = Color(1.0, 1.0, 1.0, 0.2)
		item_vbox.add_child(item_sep)

func _disconnect_port_visuals_only(node_name: String, port_idx: int) -> void:
	for conn in graph_edit.get_connection_list():
		if conn.get("from", "") == node_name and conn.get("from_port", -1) == port_idx:
			graph_edit.disconnect_node(node_name, port_idx, conn.get("to", ""), conn.get("to_port", 0))

func _on_open_event_editor_pressed() -> void:
	if not selected_node:
		return
	event_editor_dialog.title = "💬 [" + selected_node.display_name_kr + "] 대화 이벤트 트리거 매니저"
	_refresh_popup_event_list()
	event_editor_dialog.popup_centered()

func _on_add_event_popup_pressed() -> void:
	if not selected_node:
		return
	selected_node.events.append({
		"event_id": "evt_" + str(selected_node.events.size()) + "_" + str(Time.get_ticks_msec()),
		"display_name": "새 이벤트",
		"dialogue_file": "res://data/dialogues/test_dialogue.dialogue", # 기본 템플릿 경로 가이드 제공 🌟
		"dialogue_title": "start",
		"triggers": {}
	})
	_refresh_popup_event_list()

func _on_event_dialog_closed() -> void:
	if selected_node:
		selected_node._update_node_view()

# ==========================================
# 🌟 팝업 이벤트 리스트 헬퍼 (클로저 버그 방지)
# ==========================================

func _create_event_name_edit(ev: Dictionary) -> LineEdit:
	var edit = LineEdit.new()
	edit.text = ev.get("display_name", "")
	edit.placeholder_text = "이벤트 이름 (ex: 루이세의 고민)"
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size = Vector2(160, 0)
	edit.text_changed.connect(func(new_text: String):
		ev["display_name"] = new_text
	)
	return edit

func _create_event_file_edit(ev: Dictionary) -> LineEdit:
	var edit = LineEdit.new()
	edit.text = ev.get("dialogue_file", "")
	edit.placeholder_text = "dialogue 리소스 경로 (ex: res://data/dialogues/inn.dialogue)"
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size = Vector2(320, 0)
	edit.text_changed.connect(func(new_text: String):
		ev["dialogue_file"] = new_text.strip_edges()
	)
	return edit

func _create_event_label_edit(ev: Dictionary) -> LineEdit:
	var edit = LineEdit.new()
	edit.text = ev.get("dialogue_title", "")
	edit.placeholder_text = "대화 라벨 (ex: morigan_talk)"
	edit.custom_minimum_size = Vector2(140, 0)
	edit.text_changed.connect(func(new_text: String):
		ev["dialogue_title"] = new_text.strip_edges()
	)
	return edit

func _create_event_jump_button(file_path: String, title_label: String) -> Button:
	var btn = Button.new()
	btn.text = "🔗 점프"
	btn.tooltip_text = "이 대화 스크립트 파일을 Dialogue Manager에서 즉시 열어줍니다."
	btn.pressed.connect(func():
		_jump_to_dialogue(file_path, title_label)
	)
	return btn

func _create_event_delete_button(node: GraphNode, idx: int) -> Button:
	var btn = Button.new()
	btn.text = "🗑"
	btn.pressed.connect(func():
		node.events.remove_at(idx)
		_refresh_popup_event_list()
	)
	return btn

# ==========================================
# 🌟 EditorFileDialog 탐색기 헬퍼 (클로저 버그 방지)
# ==========================================

func _open_file_dialog_for_event(line_edit: LineEdit, ev: Dictionary) -> void:
	_active_event_line_edit = line_edit
	_active_event_dict = ev
	_file_dialog.popup_centered_ratio()

func _on_dialogue_file_selected(path: String) -> void:
	if _active_event_line_edit:
		_active_event_line_edit.text = path
	if _active_event_dict:
		_active_event_dict["dialogue_file"] = path

func _create_file_browse_button(line_edit: LineEdit, ev: Dictionary) -> Button:
	var btn = Button.new()
	btn.text = "📁"
	btn.tooltip_text = "프로젝트 내의 .dialogue 파일을 탐색합니다."
	btn.pressed.connect(func():
		_open_file_dialog_for_event(line_edit, ev)
	)
	return btn

func _refresh_popup_event_list() -> void:
	for child in event_popup_list_container.get_children():
		child.queue_free()

	if not selected_node:
		return

	for i in range(selected_node.events.size()):
		var ev = selected_node.events[i]

		# 750px 이상의 드넓은 가로 공간을 적극적으로 나누어 활용하는 테이블 뷰 구성 🌟
		var item_hbox = HBoxContainer.new()
		event_popup_list_container.add_child(item_hbox)

		# 1. 이벤트명 입력
		item_hbox.add_child(_create_event_name_edit(ev))

		# 2. dialogue 스크립트 리소스 경로 입력 + 📁 탐색기 버튼 🌟
		var hbox_file = HBoxContainer.new()
		item_hbox.add_child(hbox_file)
		var file_edit = _create_event_file_edit(ev)
		hbox_file.add_child(file_edit)
		hbox_file.add_child(_create_file_browse_button(file_edit, ev))

		# 3. 대화 라벨 이름 입력
		item_hbox.add_child(_create_event_label_edit(ev))

		# 4. 점프 단추 🔗
		var file_path = ev.get("dialogue_file", "")
		var title_label = ev.get("dialogue_title", "")
		item_hbox.add_child(_create_event_jump_button(file_path, title_label))

		# 5. 삭제 단추 🗑️
		item_hbox.add_child(_create_event_delete_button(selected_node, i))

func _jump_to_dialogue(file_path: String, title_label: String) -> void:
	if file_path == "":
		return

	var clean_label = title_label.strip_edges()
	if clean_label == "":
		clean_label = "start"

	# 1. 파일 자동 생성 검증 🌟
	if not FileAccess.file_exists(file_path):
		print("Dialogue file does not exist. Creating new file at: ", file_path)
		var base_dir = file_path.get_base_dir()
		if not DirAccess.dir_exists_absolute(base_dir):
			DirAccess.make_dir_recursive_absolute(base_dir)

		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if file:
			file.store_string("~ " + clean_label + "\n")
			file.store_string("# 여기에 [" + clean_label + "] 대화 스크립트를 작성해 주세요.\n")
			file.close()
			EditorInterface.get_resource_filesystem().scan()
		else:
			printerr("Failed to create dialogue file: ", file_path)
			return
	else:
		# 2. 기존 파일 내 라벨 자동 보완(Append) 검증 🌟
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()

			var label_pattern = "~ " + clean_label
			if not label_pattern in content:
				print("Label '", clean_label, "' not found in dialogue file. Appending new label section.")
				var append_file = FileAccess.open(file_path, FileAccess.READ_WRITE)
				if append_file:
					append_file.seek_end()
					append_file.store_string("\n\n~ " + clean_label + "\n")
					append_file.store_string("# 여기에 [" + clean_label + "] 이벤트 대화를 작성해 주세요.\n")
					append_file.close()
					EditorInterface.get_resource_filesystem().scan()

	# 3. Dialogue Manager 플러그인을 활용한 정밀 점프 격발 🌟
	if DMPlugin.instance != null:
		DMPlugin.open_file_at_title(file_path, clean_label)
		print("Successfully jumped to dialogue: ", file_path, " -> ", clean_label)
	else:
		var dialogue_resource = load(file_path)
		if dialogue_resource:
			EditorInterface.edit_resource(dialogue_resource)
			EditorInterface.select_file(file_path)
			print("Dialogue Manager plugin instance not found. Opened file without title jump: ", file_path)

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

func _on_path_swapped(idx1: int, idx2: int) -> void:
	if not selected_node:
		return
		
	var paths = selected_node.paths
	if idx1 < 0 or idx1 >= paths.size() or idx2 < 0 or idx2 >= paths.size():
		return
		
	# 1. 두 경로 데이터 스왑 (순서 교체 🌟)
	var temp = paths[idx1]
	paths[idx1] = paths[idx2]
	paths[idx2] = temp
	
	# 2. 캔버스 슬롯 및 연결망 물리적 재건 (데이터 포트 인덱스 동기화 보장)
	selected_node._update_node_view()
	_rebuild_node_connections(selected_node)
	
	# 3. 사이드바 UI 리프레시
	_refresh_sidebar_path_list()
	print("Successfully swapped paths: ", idx1, " <-> ", idx2)

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
