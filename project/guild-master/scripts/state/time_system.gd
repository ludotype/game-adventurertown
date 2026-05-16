extends Node

## TimeSystem
## 게임의 날짜와 24시간제 시각을 관리합니다.

signal time_advanced(day: int, hour: int, minute: int, time_block: String)
signal day_started(day: int)

const MINUTES_PER_DAY := 1440
const DEFAULT_WAKE_HOUR := 7
const DEFAULT_WAKE_MINUTE := 0

## 기획자가 쓰는 기본 시간 단위입니다. time_units 1개가 몇 분인지 정합니다.
@export var minutes_per_time_unit: int = 30

var day: int = 1
var hour: int = DEFAULT_WAKE_HOUR
var minute: int = DEFAULT_WAKE_MINUTE


## 기존 NPC 스케줄 호환용 별칭입니다. 내부는 24시간제지만 스케줄은 블록명으로도 쓸 수 있습니다.
var current_time_of_day: String:
	get:
		return get_current_time_block()


func reset_time() -> void:
	day = 1
	hour = DEFAULT_WAKE_HOUR
	minute = DEFAULT_WAKE_MINUTE
	day_started.emit(day)
	_emit_time_advanced()


func set_time(new_day: int, new_hour: int, new_minute: int) -> void:
	day = maxi(1, new_day)
	hour = clampi(new_hour, 0, 23)
	minute = clampi(new_minute, 0, 59)
	_emit_time_advanced()


func advance(time_units: int = 1) -> void:
	advance_time_units(time_units)


func advance_time_units(time_units: int = 1) -> void:
	if time_units <= 0:
		return
	advance_minutes(time_units * minutes_per_time_unit)


func advance_minutes(minutes: int) -> void:
	if minutes <= 0:
		return

	var total_minutes := get_minutes_since_midnight() + minutes
	while total_minutes >= MINUTES_PER_DAY:
		total_minutes -= MINUTES_PER_DAY
		day += 1
		day_started.emit(day)

	hour = int(total_minutes / 60)
	minute = total_minutes % 60
	_emit_time_advanced()


func sleep_until_next_day() -> void:
	day += 1
	hour = DEFAULT_WAKE_HOUR
	minute = DEFAULT_WAKE_MINUTE
	day_started.emit(day)
	_emit_time_advanced()


func get_display_text() -> String:
	return "Day %d %02d:%02d" % [day, hour, minute]


func get_current_time_block() -> String:
	var minutes_now := get_minutes_since_midnight()
	if _is_minutes_in_range(minutes_now, 5 * 60, 7 * 60):
		return "dawn"
	if _is_minutes_in_range(minutes_now, 7 * 60, 12 * 60):
		return "morning"
	if _is_minutes_in_range(minutes_now, 12 * 60, 13 * 60):
		return "noon"
	if _is_minutes_in_range(minutes_now, 13 * 60, 18 * 60):
		return "afternoon"
	if _is_minutes_in_range(minutes_now, 18 * 60, 22 * 60):
		return "evening"
	if _is_minutes_in_range(minutes_now, 22 * 60, 24 * 60):
		return "night"
	return "late_night"


func get_minutes_since_midnight() -> int:
	return hour * 60 + minute


func is_current_hour_in_range(start_hour: int, end_hour: int) -> bool:
	return is_current_time_in_range(start_hour * 60, end_hour * 60)


func is_current_time_in_range(start_minutes: int, end_minutes: int) -> bool:
	return _is_minutes_in_range(get_minutes_since_midnight(), start_minutes, end_minutes)


func parse_time_to_minutes(time_text: String) -> int:
	var parts := time_text.split(":")
	if parts.size() < 2:
		push_warning("TimeSystem: invalid time text: " + time_text)
		return 0

	var parsed_hour := clampi(int(parts[0]), 0, 23)
	var parsed_minute := clampi(int(parts[1]), 0, 59)
	return parsed_hour * 60 + parsed_minute


func get_time_label(time_block: String) -> String:
	match time_block:
		"dawn":
			return "새벽"
		"morning":
			return "아침"
		"noon":
			return "정오"
		"afternoon":
			return "오후"
		"evening":
			return "저녁"
		"night":
			return "밤"
		"late_night":
			return "심야"
		_:
			return time_block


func _emit_time_advanced() -> void:
	time_advanced.emit(day, hour, minute, get_current_time_block())


func _is_minutes_in_range(value: int, start_minutes: int, end_minutes: int) -> bool:
	if start_minutes == end_minutes:
		return true
	if start_minutes < end_minutes:
		return value >= start_minutes and value < end_minutes
	return value >= start_minutes or value < end_minutes
