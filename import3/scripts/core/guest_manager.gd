extends Node

## GuestManager: 호텔의 투숙객 정보와 객실 상태를 관리합니다.

signal guests_randomized
signal guest_stress_threshold_reached(room_id: String, stress: float)

# 활성화된 투숙객 인스턴스 (room_id -> GuestComponent)
var active_guests: Dictionary = {}

# 객실 데이터 (설정값 보관용 및 마스터 데이터)
var room_data: Dictionary = {}

# 데이터 풀
const FIRST_NAMES = ["James", "Mary", "Robert", "Patricia", "John", "Jennifer", "Michael", "Linda", "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica", "Thomas", "Sarah"]
const LAST_NAMES = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas"]
const PERSONALITIES = ["grumpy", "scared", "polite", "dazed"]

func _ready() -> void:
	_initialize_rooms()
	# 시프트가 시작될 때마다 투숙객을 랜덤화하고 컴퍼넌트를 생성함
	if has_node("/root/GameManager"):
		GameManager.phase_changed.connect(_on_phase_changed)

# 층별 관리 데이터
var floor_panic: Dictionary = {"1f": 0.0, "2f": 0.0, "3f": 0.0, "4f": 0.0, "5f": 0.0}
var floor_cooldowns: Dictionary = {"1f": 0, "2f": 0, "3f": 0, "4f": 0, "5f": 0}

const COMPLAINT_COOLDOWN_MINUTES = 60 # 1시간 쿨다운

func _process(delta: float) -> void:
	if GameManager.current_phase == GameManager.Phase.NIGHT_SHIFT:
		# 투숙객 AI 로직 처리
		for room_id in active_guests:
			var guest = active_guests[room_id] as GuestComponent
			if guest:
				guest.process_logic(delta)
		
		# 층별 컴플레인 조건 체크 (중앙 통제)
		_check_floor_complaints()

func _on_phase_changed(new_phase: int) -> void:
	if new_phase == GameManager.Phase.NIGHT_SHIFT:
		# 패닉 및 쿨다운 초기화
		for floor_id in floor_panic:
			floor_panic[floor_id] = 0.0
			floor_cooldowns[floor_id] = 0
		randomize_guests()
		_spawn_guest_components()
	elif new_phase == GameManager.Phase.SUMMARY:
		_clear_guest_components()

func _spawn_guest_components() -> void:
	_clear_guest_components()
	for room_id in room_data:
		var data = room_data[room_id]
		if data.guest_name != "":
			var guest = GuestComponent.new()
			guest.name = "Guest_" + room_id.replace("loc_room_", "")
			add_child(guest)
			guest.initialize(data, room_id)
			active_guests[room_id] = guest
			
	var lm = get_node_or_null("/root/LogManager")
	if lm: lm.system("투숙객 컴퍼넌트 배치 완료: %d명 (객실 상주 모드)" % active_guests.size())

func _clear_guest_components() -> void:
	for room_id in active_guests:
		if is_instance_valid(active_guests[room_id]):
			active_guests[room_id].queue_free()
	active_guests.clear()

func _check_floor_complaints() -> void:
	var current_time = TimeManager.total_game_minutes
	
	for floor_id in floor_panic:
		# 1. 쿨다운 확인
		if current_time < floor_cooldowns[floor_id]: continue
		
		# 2. 패닉 수치 확인 (Config 임계점 사용)
		if floor_panic[floor_id] >= Config.COMPLAINT_THRESHOLD:
			_trigger_floor_complaint(floor_id)

func _trigger_floor_complaint(floor_id: String) -> void:
	var potential_senders = []
	for room_id in active_guests:
		if LocationManager.get_floor_from_node_id(room_id) == floor_id:
			potential_senders.append(active_guests[room_id])
	
	if potential_senders.size() == 0: return
	
	# [최적화] 정렬 대신 1패스 최대값 탐색 (O(n))
	var sender = potential_senders[0]
	for i in range(1, potential_senders.size()):
		if potential_senders[i].stress > sender.stress:
			sender = potential_senders[i]
	
	# 컴플레인 발생 알림
	guest_stress_threshold_reached.emit(sender.home_room_id, sender.stress)
	
	# [랜덤 쿨다운 계산] 30~60분 사이, 5분 단위 (float 나눗셈으로 정수 나눗셈 경고 방지)
	var steps = (Config.COMPLAINT_COOLDOWN_MAX - Config.COMPLAINT_COOLDOWN_MIN) / float(Config.COMPLAINT_COOLDOWN_STEP)
	var random_offset = (randi() % (int(steps) + 1)) * Config.COMPLAINT_COOLDOWN_STEP
	var final_cooldown = Config.COMPLAINT_COOLDOWN_MIN + random_offset
	
	floor_cooldowns[floor_id] = TimeManager.total_game_minutes + final_cooldown
	
	# [패닉 수치 감쇄] Config 비율에 따라 감소
	floor_panic[floor_id] *= (1.0 - Config.COMPLAINT_STRESS_REDUCTION_RATE)
	
	var lm = get_node_or_null("/root/LogManager")
	if lm: lm.info("[컴플레인 발송] %s층 메시지 발송 완료 (다음 쿨다운: %d분, 남은 패닉: %.1f)" % [floor_id.to_upper(), final_cooldown, floor_panic[floor_id]])

func add_stress(room_id: String, amount: float) -> void:
	if active_guests.has(room_id):
		var guest = active_guests[room_id]
		guest.add_stress(amount)
		
		# [신규] 층별 패닉 합산 (증가분만 합산, 감쇄는 별도 처리)
		var floor_id = LocationManager.get_floor_from_node_id(room_id)
		if floor_panic.has(floor_id) and amount > 0.0:
			floor_panic[floor_id] += amount

## 해당 객실 투숙객의 스트레스를 시간에 비례해 감쇄시킨다. (조용한 층일 때 process_environmental_stress에서 호출)
func decay_stress(room_id: String, minutes_passed: int) -> void:
	if not active_guests.has(room_id): return
	var decay_amount = (float(minutes_passed) / 10.0) * Config.GUEST_STRESS_DECAY_PER_10MIN
	add_stress(room_id, -decay_amount)

func get_stress(room_id: String) -> float:
	if active_guests.has(room_id):
		return active_guests[room_id].stress
	return room_data.get(room_id, {}).get("stress", 0.0)

func get_guest_info(room_id: String) -> Dictionary:
	if active_guests.has(room_id):
		var guest = active_guests[room_id]
		return {
			"guest_name": guest.guest_name,
			"gender": guest.gender,
			"personality": guest.personality,
			"stress": guest.stress,
			"current_location": guest.current_node,
			"intel_grade": guest.get_intel_grade()
		}
	return room_data.get(room_id, {})

func is_room_occupied(room_id: String) -> bool:
	if active_guests.has(room_id): return true
	return room_data.has(room_id) and room_data[room_id].guest_name != ""

func get_guest_at(node_id: String) -> GuestComponent:
	for room_id in active_guests:
		if active_guests[room_id].current_node == node_id:
			return active_guests[room_id]
	return null

func unlock_room(room_id: String) -> void:
	if room_data.has(room_id):
		room_data[room_id].is_locked = false

func get_personality(room_id: String) -> String:
	var info = get_guest_info(room_id)
	return info.get("personality", "polite")

func decide_if_guest_responds(room_id: String) -> bool:
	if not is_room_occupied(room_id): return false
	return randf() < 0.5

func _initialize_rooms() -> void:
	# 2층 객실 (201 ~ 210)
	for i in range(201, 211):
		var room_id = "loc_room_2f_" + str(i)
		room_data[room_id] = {
			"guest_name": "", "age": 0, "gender": "", "is_locked": true,
			"is_named": false, "personality": "polite", "stress": 0.0
		}
	# 3층 객실 (301 ~ 310)
	for i in range(301, 311):
		var room_id = "loc_room_3f_" + str(i)
		room_data[room_id] = {
			"guest_name": "", "age": 0, "gender": "", "is_locked": true,
			"is_named": false, "personality": "polite", "stress": 0.0
		}

func randomize_guests() -> void:
	seed(Time.get_ticks_msec())
	for room_id in room_data:
		if room_data[room_id].is_named: continue
		
		if randf() < 0.7:
			room_data[room_id].guest_name = FIRST_NAMES.pick_random() + " " + LAST_NAMES.pick_random()
			room_data[room_id].age = randi_range(20, 70)
			room_data[room_id].gender = ["Male", "Female"].pick_random()
			room_data[room_id].personality = PERSONALITIES.pick_random()
		else:
			room_data[room_id].guest_name = ""
			
	guests_randomized.emit()
	print("[GuestManager] 투숙객 랜덤 배정 완료.")
