extends Node

## GameFlags: 게임 상태와 플래그를 관리하는 중앙 저장소입니다.

signal flag_changed(key: String, value)

# 기본 스탯
var day: int = 1
var score: int = 0

# 이벤트 플래그 (동적으로 추가 가능)
var flags: Dictionary = {}

func _ready() -> void:
	reset_flags()

## 모든 플래그 초기화
func reset_flags() -> void:
	day = 1
	score = 0
	flags.clear()
	print("[GameFlags] 초기화 완료")

## 플래그 설정
func set_flag(key: String, value) -> void:
	flags[key] = value
	flag_changed.emit(key, value)

## 플래그 확인
func get_flag(key: String, default_value = false):
	return flags.get(key, default_value)

## 플래그가 있는지 확인
func has_flag(key: String) -> bool:
	return flags.has(key)


## true로 설정된 플래그 키 목록 반환
func get_active_flags() -> Array:
	var active_flags: Array = []
	for key in flags.keys():
		if flags[key] == true:
			active_flags.append(key)
	return active_flags
