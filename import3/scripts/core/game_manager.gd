extends Node

## GameManager: 게임의 전반적인 라이프사이클과 페이즈를 제어하는 중앙 컨트롤러입니다.

enum Phase {
	DAY_SHIFT,
	PRE_NIGHT_EVENTS,
	NIGHT_SHIFT,
	POST_NIGHT_EVENTS,
	SUMMARY
}

signal phase_changed(new_phase: Phase)
signal sanity_changed(new_value: int)

var current_phase: Phase = Phase.DAY_SHIFT
const CUSTOM_BALLOON = preload("res://Story/Dialogues/custom_balloon/balloon.tscn")
const GAMEPLAY_SCENE_PATH = "res://scenes/gameplay/action_scene.tscn"

# 내부 상태 관리
var is_dialogue_playing: bool = false
var _active_balloon: CanvasLayer = null
var _sequence_aborted: bool = false
var _intro_blackout: CanvasLayer = null
var _pause_menu: CanvasLayer = null
var _log_console: CanvasLayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_global_ui()

func _setup_global_ui() -> void:
	_pause_menu = load("res://scenes/ui/pause_menu.tscn").instantiate()
	get_tree().root.add_child.call_deferred(_pause_menu)
	
	var log_scene = load("res://scenes/ui/log_console.tscn")
	if log_scene:
		_log_console = CanvasLayer.new()
		_log_console.layer = 2000
		_log_console.add_child(log_scene.instantiate())
		get_tree().root.add_child.call_deferred(_log_console)

## 새로운 게임 세션을 시작합니다. 모든 매니저의 상태를 초기화합니다.
func start_new_game() -> void:
	print("[GameManager] === 신규 게임 세션 초기화 시작 ===")
	_sequence_aborted = false
	
	# 1. 모든 전역 매니저 리셋 (순서 중요)
	Flags.reset_flags()
	TimeManager.reset_state()
	LocationManager.reset_state()
	ElevatorManager.reset_state()
	EntityManager.clear_entities() # EntityManager 내부에 이미 존재한다고 가정
	
	var tree = get_tree()
	
	# 2. 인트로 무대 세팅
	tree.change_scene_to_file("res://scenes/ui/intro_background.tscn")
	await tree.process_frame
	if _sequence_aborted: return

	# 3. 인트로 시퀀스 재생
	var intro_res = load("res://Story/Dialogues/Intro/prologue_main.dialogue")
	if intro_res:
		await _play_dialogue(intro_res, "start")
	
	if _sequence_aborted: return
	
	# 4. 초기 게임 데이터 설정 (Day 1 진입 준비)
	Flags.shift_day = 1
	Flags.sanity = Flags.max_sanity
	
	# 5. 본격적인 게임 씬으로 전환
	tree.change_scene_to_file(GAMEPLAY_SCENE_PATH)
	while true:
		await tree.process_frame
		if _sequence_aborted: return
		if tree.current_scene and tree.current_scene.scene_file_path == GAMEPLAY_SCENE_PATH:
			break
	
	await tree.create_timer(0.5).timeout
	if _sequence_aborted: return
	
	# 6. 첫 페이즈 시작
	change_phase(Phase.PRE_NIGHT_EVENTS)

## 페이즈를 전환합니다.
func change_phase(next_phase: Phase) -> void:
	if _sequence_aborted: return
	
	# Exit 현재 페이즈
	_exit_current_phase()
	
	current_phase = next_phase
	print("[GameManager] >>> 페이즈 진입: ", Phase.keys()[current_phase], " <<<")
	
	# Enter 다음 페이즈
	match current_phase:
		Phase.DAY_SHIFT: _enter_day_shift()
		Phase.PRE_NIGHT_EVENTS: _enter_pre_night_events()
		Phase.NIGHT_SHIFT: _enter_night_shift()
		Phase.POST_NIGHT_EVENTS: _enter_post_night_events()
		Phase.SUMMARY: _enter_summary()
	
	phase_changed.emit(current_phase)

func _exit_current_phase() -> void:
	# 페이즈 전환 시 공통 청소 로직
	abort_all_dialogues(false)

func _enter_day_shift() -> void:
	TimeManager.is_paused = true

func _enter_pre_night_events() -> void:
	if has_node("/root/EventManager"):
		await EventManager.check_and_trigger_events(Phase.PRE_NIGHT_EVENTS)
	
	if _sequence_aborted: return
	change_phase(Phase.NIGHT_SHIFT)

func _enter_night_shift() -> void:
	TimeManager.is_paused = false
	var gm = get_node_or_null("/root/GuestManager")
	if gm: gm.randomize_guests() # 시프트 시작 전 투숙객 랜덤 배치
	var entities = _load_entities()
	if entities.size() > 0:
		EntityManager.initialize_shift(entities)

func _enter_post_night_events() -> void:
	TimeManager.is_paused = true
	change_phase(Phase.SUMMARY)

func _enter_summary() -> void:
	print("[GameManager] 시프트 종료. 일일 결산 데이터를 생성합니다.")
	
	# 시프트 종료 시 리뷰 생성
	var reviews = generate_daily_reviews()
	
	# Summary UI 생성 및 데이터 전달
	var summary_scene = load("res://scenes/ui/summary_screen.tscn")
	if summary_scene:
		var summary = summary_scene.instantiate()
		get_tree().current_scene.add_child(summary)
		# 만약 summary_screen에 set_reviews 같은 함수가 있다면 여기서 호출 가능
		if summary.has_method("setup_reviews"):
			summary.setup_reviews(reviews)

## 일일 결산 리뷰를 생성합니다.
func generate_daily_reviews() -> Array:
	var gm = get_node_or_null("/root/GuestManager")
	if not gm: return []
	
	var all_reviews = []
	
	for room_id in gm.room_data:
		var data = gm.room_data[room_id]
		if data.guest_name == "": continue
		
		# 리뷰 생성이 필요한 경우 (스트레스가 있거나 해결된 경우)
		if data.review_points > 0 or data.is_resolved:
			var review = {
				"room_id": room_id,
				"guest_name": data.guest_name,
				"stars": 5,
				"text": ""
			}
			
			# 별점 계산 (0 ~ 100 포인트를 5 ~ 1 별점으로 환산)
			review.stars = clamp(5 - floori(data.review_points / 20.0), 1, 5)
			
			# 해결 시 별점 보정
			if data.is_resolved:
				review.stars = clamp(review.stars + 2, 1, 5)
			
			# 리뷰 텍스트 생성
			review.text = _generate_review_text(data)
			all_reviews.append(review)
	
	# 점수가 나쁜 순으로 정렬하여 최대 3개 추출
	all_reviews.sort_custom(func(a, b): return a.stars < b.stars)
	return all_reviews.slice(0, 3)

func _generate_review_text(data: Dictionary) -> String:
	var complaint = data.last_complaint_type
	var is_resolved = data.is_resolved
	var personality = data.personality
	
	if is_resolved:
		if personality == "grumpy":
			return "불만이 많았지만 직원이 뇌물을... 아니, 선물을 가져와서 참기로 했다."
		return "문제가 있었지만 직원이 매우 친절하게 대응해주어 기분 좋게 머물렀다."
	
	if complaint == "noise":
		return "밤새도록 복도에서 쿵쾅거리는 소음 때문에 한숨도 못 잤다. 최악의 호텔이다."
	elif complaint == "plumbing":
		return "화장실 수도꼭지가 제멋대로 돌아간다. 관리가 전혀 안 되는 것 같다."
	
	return "호텔 분위기가 너무 음산하고 기분 나쁘다. 다시는 오고 싶지 않다."

## 대화 재생 및 벌룬 관리
func _play_dialogue(resource: DialogueResource, title: String) -> void:
	if _sequence_aborted: return
	
	is_dialogue_playing = true
	abort_all_dialogues(false)
	var balloon = CUSTOM_BALLOON.instantiate()
	_active_balloon = balloon
	get_tree().root.add_child(balloon)
	balloon.start(resource, title)
	await balloon.tree_exited
	
	if _active_balloon == balloon:
		_active_balloon = null
	is_dialogue_playing = false

## 게임 세션 종료 및 모든 상태 중단 (메인 메뉴 이동 시 호출)
func cleanup_game_session() -> void:
	print("[GameManager] 게임 세션 종료 및 클린업 수행.")
	_sequence_aborted = true
	abort_all_dialogues(true)
	
	# 모든 매니저 초기화하여 잔재 제거
	Flags.reset_flags()
	TimeManager.reset_state()
	LocationManager.reset_state()
	ElevatorManager.reset_state()
	
	if get_tree(): get_tree().paused = false

func abort_all_dialogues(full_abort: bool = true) -> void:
	if full_abort: _sequence_aborted = true
	if is_instance_valid(_active_balloon):
		_active_balloon.queue_free()
		_active_balloon = null
	if is_instance_valid(_intro_blackout):
		_intro_blackout.queue_free()
		_intro_blackout = null

func _load_entities() -> Array[EntityResource]:
	var result: Array[EntityResource] = []
	var path = "res://resources/entities/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if !dir.current_is_dir() and file.ends_with(".tres"):
				var res = load(path + file)
				if res is EntityResource: result.append(res)
			file = dir.get_next()
	return result

func take_damage(amount: int) -> void:
	Flags.sanity = clampi(Flags.sanity - amount, 0, Flags.max_sanity)
	sanity_changed.emit(Flags.sanity)
	if Flags.sanity <= 0 and not Flags.is_fainted:
		_trigger_faint()

func restore_sanity(amount: int) -> void:
	Flags.sanity = clampi(Flags.sanity + amount, 0, Flags.max_sanity)
	sanity_changed.emit(Flags.sanity)
	print("[GameManager] 정신력 회복: +", amount, " (현재: ", Flags.sanity, ")")

## 특정 위치에 엔티티가 있을 경우 주변 스트레스를 처리합니다. (레거시 보정 및 컴플레인 체크)
func process_environmental_stress(minutes_passed: int) -> void:
	var em = get_node_or_null("/root/EntityManager")
	var gm = get_node_or_null("/root/GuestManager")
	if not em or not gm: return
	
	# [플레이어 정신력 피해 처리]
	em.process_time_skip_sanity_damage(minutes_passed)
	
	# [신규: 투숙객 근접도 스트레스 처리]
	if em.has_method("_process_proximity_stress"):
		em._process_proximity_stress(minutes_passed)
	
	# [투숙객 환경 스트레스 누적]
	for room_id in gm.room_data:
		if not gm.is_room_occupied(room_id): continue
		
		var floor_is_noisy = em.is_any_entity_on_same_floor(room_id)
		if floor_is_noisy:
			var stress_gain = (float(minutes_passed) / 10.0) * Config.ENTITY_FLOOR_STRESS_GAIN
			gm.add_stress(room_id, stress_gain)
		else:
			gm.decay_stress(room_id, minutes_passed)

func _trigger_faint() -> void:
	print("[GameManager] 정신력 고갈! 플레이어가 기절합니다.")
	Flags.is_fainted = true
	
	# 1. 모든 진행 중인 액션 중단
	abort_all_dialogues(true)
	
	# 2. 시간 가속 시뮬레이션 시작
	_simulate_fainted_time()

func _simulate_fainted_time() -> void:
	while Flags.is_fainted:
		# 6시가 되면 기절 해제 (TimeManager는 0~24시 시스템이라고 가정)
		# 현재 시스템이 22시 시작 ~ 익일 6시 종료라면 6을 체크
		if TimeManager.current_hour == 6:
			Flags.is_fainted = false
			break
		
		# 매 루프마다 10분씩 흐름 (가속)
		TimeManager.advance_minutes(10)
		
		# 시각적 피드백을 위해 아주 짧게 대기 (프레임 확보)
		await get_tree().create_timer(0.1).timeout
	
	print("[GameManager] 아침이 밝았습니다. 플레이어가 정신을 차립니다.")
	# 기절 해제 후 처리 (예: 페이즈 전환)
	if GameManager.current_phase != Phase.SUMMARY:
		change_phase(Phase.POST_NIGHT_EVENTS)
