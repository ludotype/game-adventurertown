extends Node

## TimeManager: 게임 내 시간의 흐름을 관리합니다.

signal time_updated(hour: int, minute: int)
signal shift_ended

var is_paused: bool = false
var total_game_minutes: int = 0

# 외부 접근 가능 속성 (Getter)
var current_hour: int: get = get_hour
var current_minute: int: get = get_minute

func get_hour() -> int: return _current_hour
func get_minute() -> int: return _current_minute

# 내부 상태
var _current_hour: int = 22
var _current_minute: int = 0

func _ready() -> void:
	LocationManager.action_performed.connect(_on_action_performed)
	reset_state()

## 모든 시간 상태를 초기값으로 되돌립니다.
func reset_state() -> void:
	is_paused = true # 초기에는 정지 상태
	_current_hour = 22
	_current_minute = 0
	total_game_minutes = _current_hour * 60
	_sync_to_dialogue_state()
	time_updated.emit(_current_hour, _current_minute)
	print("[TimeManager] 시간 상태 초기화 완료.")

func _on_action_performed(time_cost: int) -> void:
	if not is_paused:
		advance_minutes(time_cost)

func advance_minutes(minutes: int) -> void:
	total_game_minutes += minutes
	_update_clock(minutes)
	
	# [스트레스 시뮬레이션 연동]
	var gm = get_node_or_null("/root/GameManager")
	if gm: gm.process_environmental_stress(minutes)

## 대화 시스템에서 호출하는 별칭 함수
func add_minutes(minutes: int) -> void:
	advance_minutes(minutes)

func _update_clock(added_minutes: int) -> void:
	var new_total_min = _current_minute + added_minutes
	_current_minute = new_total_min % 60
	_current_hour = (_current_hour + floori(new_total_min / 60.0)) % 24
	
	_sync_to_dialogue_state()
	time_updated.emit(_current_hour, _current_minute)
	
	if _current_hour == 6:
		shift_ended.emit()
		is_paused = true
		var gm = get_node_or_null("/root/GameManager")
		if gm: gm.change_phase(gm.Phase.POST_NIGHT_EVENTS)

func _sync_to_dialogue_state() -> void:
	Flags.current_hour = _current_hour
	Flags.current_minute = _current_minute

func get_time_string() -> String:
	return "%02d:%02d" % [_current_hour, _current_minute]
