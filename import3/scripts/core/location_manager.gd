extends Node

## LocationManager: 호텔의 논리적 공간 구조와 엔티티 위치를 관리합니다.

signal location_changed(new_location_id: String)
signal action_performed(time_cost: int)

# 런타임에 로드된 장소 데이터 캐시
var locations: Dictionary = {}

# 현재 플레이어 위치
var current_location_id: String = "loc_desk_1f"

# 환경 상태 관리
var is_main_door_open: bool = false

# 노드 그룹 정의: { "group_name": ["node_id_1", "node_id_2", ...] }
var location_groups: Dictionary = {
	"corridor1f": ["loc_corridor_1f_n1", "loc_corridor_1f_n2", "loc_corridor_1f_n3", "loc_corridor_1f_s1", "loc_corridor_1f_s2", "loc_corridor_1f_sw1", "loc_corridor_1f_sw2"],
	"corridor2f": ["loc_corridor_2f_main", "loc_corridor_2f_n1", "loc_corridor_2f_n2", "loc_corridor_2f_n3", "loc_corridor_2f_s1", "loc_corridor_2f_s2", "loc_corridor_2f_sw1", "loc_corridor_2f_sw2"],
	"corridor3f": ["loc_corridor_3f_main", "loc_corridor_3f_n1", "loc_corridor_3f_n2", "loc_corridor_3f_n3", "loc_corridor_3f_s1", "loc_corridor_3f_s2", "loc_corridor_3f_sw1", "loc_corridor_3f_sw2"],
	"corridor4f": ["loc_corridor_4f_main", "loc_corridor_4f_n1", "loc_corridor_4f_n2", "loc_corridor_4f_n3", "loc_corridor_4f_s1", "loc_corridor_4f_s2", "loc_corridor_4f_sw1", "loc_corridor_4f_sw2"],
	"stairs_1f": ["loc_stairs_1f_n", "loc_stairs_1f_s"],
	"stairs_2f": ["loc_stairs_2f_n", "loc_stairs_2f_s"],
	"stairs_3f": ["loc_stairs_3f_n", "loc_stairs_3f_s"],
	"stairs_4f": ["loc_stairs_4f_n", "loc_stairs_4f_s"],
	"stairs_5f": ["loc_stairs_5f_n"],
	"rooms_2f": ["loc_room_2f_201", "loc_room_2f_202", "loc_room_2f_203", "loc_room_2f_204", "loc_room_2f_205", "loc_room_2f_206", "loc_room_2f_207", "loc_room_2f_208", "loc_room_2f_209", "loc_room_2f_210"],
	"rooms_3f": ["loc_room_3f_301", "loc_room_3f_302", "loc_room_3f_303", "loc_room_3f_304", "loc_room_3f_305", "loc_room_3f_306", "loc_room_3f_307", "loc_room_3f_308", "loc_room_3f_309", "loc_room_3f_310"],
	"rooms_4f": ["loc_room_4f_401", "loc_room_4f_402", "loc_room_4f_403", "loc_room_4f_404", "loc_room_4f_405", "loc_room_4f_406", "loc_room_4f_407", "loc_room_4f_408", "loc_room_4f_409", "loc_room_4f_410"]
}

func _ready() -> void:
	_load_locations_from_resources()
	reset_state()

## 관리자의 상태를 초기화합니다.
func reset_state() -> void:
	current_location_id = "loc_desk_1f"
	is_main_door_open = false
	print("[LocationManager] 위치 상태 초기화 완료.")

## 두 노드 사이의 최단 거리(칸 수)를 계산합니다.
func get_node_distance(node_a: String, node_b: String) -> int:
	if node_a == node_b: return 0
	if not locations.has(node_a) or not locations.has(node_b): return 999
	
	var queue = [[node_a, 0]]
	var visited = {node_a: true}
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var node_id = current[0]
		var dist = current[1]
		
		if node_id == node_b: return dist
		
		var loc_res = locations.get(node_id)
		if loc_res:
			for direction in loc_res.connections:
				var neighbor = loc_res.connections[direction]
				if neighbor != "" and not visited.has(neighbor):
					visited[neighbor] = true
					queue.append([neighbor, dist + 1])
					
	return 999 # 연결되지 않은 경우

func _load_locations_from_resources() -> void:
	var path = "res://resources/locations/"
	if not DirAccess.dir_exists_absolute(path):
		return
		
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".tres.remap")):
				var res_path = path + file_name.replace(".remap", "")
				var res = load(res_path)
				if res is LocationResource:
					locations[res.location_id] = res
			file_name = dir.get_next()

func move_to(target_id: String) -> bool:
	if not locations.has(target_id):
		return false
		
	current_location_id = target_id
	action_performed.emit(5) # 기본 5분 소모 (상수로 관리 권장)
	location_changed.emit(current_location_id)
	return true

func move_in_direction(direction: String) -> bool:
	if not locations.has(current_location_id): return false
	var connections = locations[current_location_id].connections
	if connections.has(direction) and connections[direction] != "":
		return move_to(connections[direction])
	return false

func force_move(target_id: String) -> void:
	if locations.has(target_id):
		current_location_id = target_id
		location_changed.emit(current_location_id)

func get_current_location_name() -> String:
	if locations.has(current_location_id):
		return locations[current_location_id].display_name
	return "Unknown"

## 특정 위치의 인접 노드 목록을 반환합니다.
func get_adjacent_locations(location_id: String) -> Array:
	if locations.has(location_id):
		var adj = []
		for target in locations[location_id].connections.values():
			if target != "" and target != null:
				adj.append(target)
		return adj
	return []

## 특정 위치 ID에 해당하는 리소스를 반환합니다.
func get_location_resource(location_id: String) -> LocationResource:
	if locations.has(location_id):
		return locations[location_id]
	return null

## 노드 ID로부터 층 정보를 추출합니다 (1f, 2f, 3f, 4f, 5f, b1).
func get_floor_from_node_id(node_id: String) -> String:
	for f in ["1f", "2f", "3f", "4f", "5f", "b1"]:
		if f in node_id: return f
	return "unknown"
