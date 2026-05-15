extends Node

## [EntityManager]
## 호텔 내의 엔티티(이상개체)들을 관리하고 추적하는 시스템.

signal entity_moved(ent_id: String, from_node: String, to_node: String)
signal entity_presence_detected(location_id: String, is_nearby: bool)
@warning_ignore("unused_signal")
signal footstep_visual_requested(fx_data: Dictionary)

# 활성화된 엔티티 인스턴스 (Node -> EntityComponent)
var active_entities: Dictionary = {}

# 현재 플레이어 근처에 엔티티가 있는지 여부
var is_player_nearby: bool = false

# 노드별 엔티티 점유 현황 (node_id -> Array[ent_id])
var node_occupancy: Dictionary = {}

# 매니저 캐시
var _guest_manager = null
var _log_manager = null

func _ready() -> void:
	set_process(true)
	_guest_manager = get_node_or_null("/root/GuestManager")
	_log_manager = get_node_or_null("/root/LogManager")

var _last_stress_minute: int = 0

func _process(delta: float) -> void:
	if GameManager.current_phase == GameManager.Phase.NIGHT_SHIFT:
		# 개별 엔티티 로직 수행
		for ent_id in active_entities:
			var component = active_entities[ent_id] as EntityComponent
			if component:
				component.process_logic(delta)
		
		# 실시간 프레임에서는 1분 단위 연산 시도 (내부에서 중복 방지됨)
		_process_proximity_stress(1)
		_update_proximity_status()

func _process_proximity_stress(minutes_passed: int) -> void:
	var current_min = TimeManager.total_game_minutes
	
	# 어떤 호출이든 해당 분에 이미 연산했다면 즉시 종료 (중복 방지 락)
	if current_min == _last_stress_minute and minutes_passed <= 1: 
		return
	
	_last_stress_minute = current_min
	
	if not _guest_manager: 
		_guest_manager = get_node_or_null("/root/GuestManager")
		if not _guest_manager: return
	
	for ent_id in active_entities:
		var component = active_entities[ent_id] as EntityComponent
		var res = component.resource
		var ent_loc = component.current_node
		
		# fear_value 보정 (리소스에서 0일 가능성 대비)
		var base_fear = res.fear_value if "fear_value" in res else 10.0
		if base_fear <= 0: continue
		
		for guest_id in _guest_manager.active_guests:
			var guest = _guest_manager.active_guests[guest_id]
			if not guest.has_method("add_stress"): continue
			
			var dist = LocationManager.get_node_distance(ent_loc, guest.current_node)
			
			if dist <= 2:
				var weight = 0.0
				match dist:
					0: weight = 3.0 # 동일 노드
					1: weight = 1.5 # 인접 노드
					2: weight = 0.5 # 인접의 인접
				
				# (Entity_Level * Fear_Value) * Proximity_Weight * Minutes
				var amount = (float(res.level) * base_fear) * weight * float(minutes_passed)
				if amount > 0:
					_guest_manager.add_stress(guest_id, amount) # Manager를 통해 호출 (층별 합산 보장)
					
					if _log_manager:
						var dist_str = "동일 구역" if dist == 0 else (str(dist) + "칸 거리")
						_log_manager.info("[공포전이] %s -> %s (%s, +%.1f, %d분 경과)" % [res.entity_name, guest.guest_name, dist_str, amount, minutes_passed])

func process_entity_behaviors(_delta: float) -> void:
	# 이제 개별 EntityComponent.process_logic()에서 처리됨 (하위 호환성을 위해 빈 함수로 유지)
	pass

## 게임 시간이 경과했을 때 엔티티에 의한 정신력 피해를 처리합니다.
func process_time_skip_sanity_damage(minutes: int) -> void:
	var current_loc = LocationManager.current_location_id
	
	for ent_id in active_entities:
		var component = active_entities[ent_id] as EntityComponent
		var ent_loc = component.current_node
		var res = component.resource
		
		# 플레이어와 동일한 장소에 있을 때 피해 발생
		if ent_loc == current_loc:
			var damage = (float(minutes) / 10.0) * res.sanity_damage
			if damage > 0:
				GameManager.take_damage(maxi(1, floori(damage)) if damage >= 1.0 else (1 if randf() < damage else 0))
				print("[EntityManager] 엔티티(%s)에 의한 정신력 피해: %d (경과: %d분)" % [res.entity_name, damage, minutes])

func _update_proximity_status() -> void:
	var current_loc = LocationManager.current_location_id
	var entities = get_entities_at(current_loc)
	var nearby = entities.size() > 0
	if nearby != is_player_nearby:
		is_player_nearby = nearby
		entity_presence_detected.emit(current_loc, is_player_nearby)

func remove_entity(ent_id: String) -> void:
	if active_entities.has(ent_id):
		var component = active_entities[ent_id]
		var node = component.current_node
		_remove_from_occupancy(node, ent_id)
		
		component.queue_free()
		active_entities.erase(ent_id)
		
		entity_moved.emit(ent_id, node, "OUTSIDE")
		
		var lm = get_node_or_null("/root/LogManager")
		if lm: lm.system("엔티티 제거: " + ent_id)
		
		_update_proximity_status()

func initialize_shift(entities_to_spawn: Array[EntityResource]) -> void:
	clear_entities()
	for res in entities_to_spawn:
		spawn_entity(res)
	
	var lm = get_node_or_null("/root/LogManager")
	if lm: lm.system("시프트 엔티티 배치 완료: %d 개체" % active_entities.size())

func spawn_entity(res: EntityResource) -> void:
	var spawn_node = ""
	if res.spawn_nodes.size() > 0:
		spawn_node = res.spawn_nodes.pick_random()
	else:
		var all_nodes = LocationManager.locations.keys()
		if all_nodes.size() > 0:
			spawn_node = all_nodes.pick_random()
	
	if spawn_node == "": return
	
	# EntityComponent 노드 생성 (커스텀 스크립트가 있으면 사용)
	var component: EntityComponent
	if res.custom_script:
		component = res.custom_script.new()
	else:
		component = EntityComponent.new()
		
	component.name = "Entity_" + res.entity_id
	add_child(component)
	component.initialize(res, spawn_node)
	
	# 시그널 연결
	component.moved.connect(_on_entity_moved.bind(res.entity_id))
	
	active_entities[res.entity_id] = component
	_add_to_occupancy(spawn_node, res.entity_id)
	_update_location_entity_status(spawn_node, true)
	
	var lm = get_node_or_null("/root/LogManager")
	if lm: lm.info("엔티티 생성: %s (위치: %s)" % [res.entity_name, spawn_node])

func _on_entity_moved(from_node: String, to_node: String, ent_id: String) -> void:
	_update_location_entity_status(from_node, false)
	_remove_from_occupancy(from_node, ent_id)
	
	_add_to_occupancy(to_node, ent_id)
	_update_location_entity_status(to_node, true)
	
	entity_moved.emit(ent_id, from_node, to_node)
	_update_proximity_status()

func clear_entities() -> void:
	for ent_id in active_entities:
		active_entities[ent_id].queue_free()
	active_entities.clear()
	node_occupancy.clear()
	is_player_nearby = false

func process_entity_movements() -> void:
	# 이제 개별 EntityComponent._process_movement()에서 처리됨
	pass

func _update_location_entity_status(node_id: String, has_ent: bool) -> void:
	if node_id == "" or node_id == "OUTSIDE": return
	var loc_res = LocationManager.get_location_resource(node_id)
	if loc_res:
		loc_res.has_entity = has_ent
		if has_ent and node_id.begins_with("loc_room_"):
			if loc_res.door_state != LocationResource.DoorState.LOCKED:
				if randf() < 0.7:
					loc_res.door_state = LocationResource.DoorState.SLIGHTLY_OPEN

func _add_to_occupancy(node_id: String, ent_id: String) -> void:
	if not node_occupancy.has(node_id): node_occupancy[node_id] = []
	node_occupancy[node_id].append(ent_id)

func _remove_from_occupancy(node_id: String, ent_id: String) -> void:
	if node_occupancy.has(node_id): node_occupancy[node_id].erase(ent_id)

func get_entities_at(node_id: String) -> Array:
	return node_occupancy.get(node_id, [])

func get_entity_name(ent_id: String) -> String:
	if active_entities.has(ent_id):
		return tr(active_entities[ent_id].resource.entity_name)
	return "Unknown"

func is_any_entity_on_same_floor(location_id: String) -> bool:
	var target_floor = LocationManager.get_floor_from_node_id(location_id)
	for ent_id in active_entities:
		if LocationManager.get_floor_from_node_id(active_entities[ent_id].current_node) == target_floor:
			return true
	return false
