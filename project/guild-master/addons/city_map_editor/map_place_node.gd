@tool
extends GraphNode

var place_id: String = ""
var display_name_kr: String = ""
var base_npc: Array = []
var events: Array = []

func _ready() -> void:
	# 선택 가능 및 마우스 필터 명시적 설정
	selectable = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	title = display_name_kr if display_name_kr != "" else place_id

func setup_node(data: Dictionary) -> void:
	place_id = data.get("id", "")
	display_name_kr = data.get("display_name_kr", "")
	base_npc = data.get("base_npc", [])
	events = data.get("events", [])

	name = place_id
	position_offset = Vector2(
		data.get("coordinate", {}).get("x", 100),
		data.get("coordinate", {}).get("y", 100)
	)

	_update_node_view()

func _update_node_view() -> void:
	title = display_name_kr if display_name_kr != "" else place_id

	# 기존 자식 노드 제거 후 깔끔한 정보 라벨들만 렌더링
	for child in get_children():
		child.queue_free()

	var vbox = VBoxContainer.new()
	# 자식 컨트롤이 클릭 입력을 가로채서 GraphNode의 선택 시그널을 방해하지 않도록 마우스 필터 처리
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	var label_id = Label.new()
	label_id.text = "ID: " + place_id
	label_id.modulate = Color(0.7, 0.7, 0.7) # 흐린 회색으로 서브 텍스트 처리
	label_id.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(label_id)
