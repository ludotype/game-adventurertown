@tool
extends GraphNode

var place_id: String = ""
var display_name_kr: String = ""
var place_type: String = "indoors" # "indoors" 또는 "outdoors"
var base_npc: Array = []
var events: Array = []
var paths: Array = []

signal event_jump_requested(file_path: String, title_label: String)

func _ready() -> void:
	selectable = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	resizable = true # 마우스로 크기 자유 조절 활성화 🌟
	resize_request.connect(_on_resize_request)
	_update_node_view()

func _on_resize_request(new_size: Vector2) -> void:
	size = new_size

func setup_node(data: Dictionary) -> void:
	place_id = data.get("id", "")
	display_name_kr = data.get("display_name_kr", "")
	place_type = data.get("place_type", "indoors")
	base_npc = data.get("base_npc", [])
	events = data.get("events", [])
	paths = data.get("paths", [])

	name = place_id
	position_offset = Vector2(
		data.get("coordinate", {}).get("x", 100),
		data.get("coordinate", {}).get("y", 100)
	)
	
	# 크기 복구 (저장된 크기가 있으면 대입, 없으면 기본 규격 200 x 180 적용 🌟)
	var s_data = data.get("size", {})
	size = Vector2(s_data.get("x", 200), s_data.get("y", 180))

	_update_node_view()

func _update_node_view() -> void:
	# 0. 부모 GraphEdit와 연결 정보 임시 백업 (리프레시 시 연결 붕괴 방지 🌟)
	var parent_graph: GraphEdit = get_parent() as GraphEdit
	var my_connections: Array = []
	if parent_graph:
		for conn in parent_graph.get_connection_list():
			var from_n = str(conn.get("from", ""))
			var to_n = str(conn.get("to", ""))
			if from_n == name or to_n == name:
				my_connections.append(conn)
				parent_graph.disconnect_node(
					from_n,
					conn.get("from_port", 0),
					to_n,
					conn.get("to_port", 0)
				)

	# 1. 노드 타입별 컬러 테마 적용 (self_modulate)
	match place_type:
		"indoors":
			self_modulate = Color(0.3, 0.55, 0.85, 1.0) # 은은한 푸른색 (실내 주요 장소)
			title = "🏠 " + (display_name_kr if display_name_kr != "" else place_id)
		"outdoors":
			self_modulate = Color(0.85, 0.55, 0.25, 1.0) # 은은한 황금/주황색 (야외 통로/거리)
			title = "🗺️ " + (display_name_kr if display_name_kr != "" else place_id)
		_:
			self_modulate = Color.WHITE
			title = display_name_kr if display_name_kr != "" else place_id

	# 2. 기존의 모든 자식 및 슬롯 즉각 초기화 (인덱스 꼬임 방지를 위해 즉시 제거 🌟)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	clear_all_slots()

	# 3. 자식 0: 장소 ID 정보 라벨 (진입용 양방향 좌/우 소켓 전면 개방 🌟)
	var vbox_info = VBoxContainer.new()
	vbox_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox_info)
	
	var label_id = Label.new()
	label_id.text = "ID: " + place_id
	label_id.modulate = Color(0.85, 0.85, 0.85)
	label_id.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox_info.add_child(label_id)

	# 자식 0: 좌측 화이트 포트(진입 In)만 활성화 (진입구)
	set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)

	# 4. 자식 1: HSeparator 구분선
	var sep = HSeparator.new()
	add_child(sep)
	set_slot(1, false, 0, Color.WHITE, false, 0, Color.WHITE)

	# [신설 🌟] 자식 2: 장소별 이벤트(대화) 트리거 비주얼 목록 및 점프 단추 연동
	if events.size() > 0:
		var vbox_events = VBoxContainer.new()
		vbox_events.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(vbox_events)
		
		# 이 슬롯은 포트 비활성화
		var child_idx_ev = get_child_count() - 1
		set_slot(child_idx_ev, false, 0, Color.WHITE, false, 0, Color.WHITE)
		
		for ev in events:
			var hbox_ev = HBoxContainer.new()
			hbox_ev.mouse_filter = Control.MOUSE_FILTER_PASS
			vbox_events.add_child(hbox_ev)
			
			var label_ev = Label.new()
			label_ev.text = "💬 " + ev.get("display_name", "새 이벤트")
			label_ev.modulate = Color(0.85, 0.55, 0.85) # 연보라색
			label_ev.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label_ev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox_ev.add_child(label_ev)
			
			var btn_jump = Button.new()
			btn_jump.text = "🔗"
			btn_jump.tooltip_text = "이 대화 이벤트를 Dialogue Manager에서 즉시 열어봅니다."
			var file_path = ev.get("dialogue_file", "")
			var title_lbl = ev.get("dialogue_title", "")
			btn_jump.disabled = (file_path == "")
			btn_jump.pressed.connect(func():
				event_jump_requested.emit(file_path, title_lbl)
			)
			hbox_ev.add_child(btn_jump)
			
		# 아래 이동 경로와의 구분을 위한 얇은 구분선
		var sep_ev = HSeparator.new()
		sep_ev.modulate = Color(1.0, 1.0, 1.0, 0.3)
		add_child(sep_ev)
		var child_idx_sep_ev = get_child_count() - 1
		set_slot(child_idx_sep_ev, false, 0, Color.WHITE, false, 0, Color.WHITE)

	# 5. 자식 2번 이후: 이동 경로 선택지 목록 (진출용 양방향 좌/우 소켓 전면 개방 🌟)
	for i in range(paths.size()):
		var path_data = paths[i]
		var child_idx = i + 2

		var hbox_path = HBoxContainer.new()
		hbox_path.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hbox_path)

		var label_path = Label.new()
		label_path.text = "☞ " + path_data.get("button_name", "새 이동 경로")
		label_path.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox_path.add_child(label_path)

		# 각 이동 경로 행에 대해: 우측 그린 포트(진출 Out)만 활성화 (출구)
		set_slot(child_idx, false, 0, Color.GREEN, true, 0, Color.GREEN)
		
	# 노드의 최소 크기 규격을 설정 (가로세로 비율 균형감 제어)
	custom_minimum_size = Vector2(200, 120)
	
	queue_redraw()

	# 7. 백업했던 내 연결선 복구 (포트 세팅 준비 완료 1프레임 뒤 안전 🌟)
	if parent_graph and my_connections.size() > 0:
		parent_graph.get_tree().process_frame.connect(func():
			for conn in my_connections:
				var from_n = str(conn.get("from", ""))
				var to_n = str(conn.get("to", ""))
				if parent_graph.has_node(from_n) and parent_graph.has_node(to_n):
					parent_graph.connect_node(
						from_n,
						conn.get("from_port", 0),
						to_n,
						conn.get("to_port", 0)
					)
		, CONNECT_ONE_SHOT)
