extends Node

## ScheduleRegistry
## data/npc_schedules/ 폴더 내 모든 JSON을 스캔하여
## {place_id: [ScheduleEntry]} 형태의 인덱스를 구축합니다.

const SCHEDULES_DIR := "res://data/npc_schedules/"

# place_id -> Array[ScheduleEntry]
var _index: Dictionary = {}


class ScheduleEntry:
	var npc_id: String
	var display_name: String
	var portrait_path: String
	var dialogue_id: String
	var place_id: String
	var weight: int
	var conditions: Dictionary

	func _init(data: Dictionary, npc_data: Dictionary) -> void:
		npc_id = npc_data.get("npc_id", "")
		display_name = npc_data.get("display_name", "")
		portrait_path = npc_data.get("default_portrait", "")
		dialogue_id = data.get("dialogue_id", npc_data.get("default_dialogue", ""))
		place_id = data.get("place_id", "")
		weight = data.get("weight", 1)
		conditions = data.get("conditions", {})

	## 현재 시간과 스토리 플래그가 조건을 만족하는지 검사
	func matches(time_of_day: String, story_flags: Array) -> bool:
		# time_of_day 조건 검사
		if conditions.has("time_of_day"):
			var valid_times: Array = conditions["time_of_day"]
			if not valid_times.has(time_of_day):
				return false

		# story_flags 조건 검사 (모든 플래그가 존재해야 함)
		if conditions.has("story_flags"):
			var required_flags: Array = conditions["story_flags"]
			for flag in required_flags:
				if not story_flags.has(flag):
					return false

		return true


func _ready() -> void:
	_build_index()


func _build_index() -> void:
	var dir := DirAccess.open(SCHEDULES_DIR)
	if dir == null:
		push_error("ScheduleRegistry: cannot open directory: " + SCHEDULES_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var path := SCHEDULES_DIR + file_name
			_load_schedule_file(path)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("ScheduleRegistry: indexed schedules for ", _index.size(), " places")


func _load_schedule_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ScheduleRegistry: failed to open: " + path)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("ScheduleRegistry: JSON parse error in " + path + ": " + json.get_error_message())
		return

	var data: Dictionary = json.get_data()
	var schedules: Array = data.get("schedules", [])

	for sched in schedules:
		if sched is not Dictionary:
			continue
		var entry := ScheduleEntry.new(sched, data)
		var place_id: String = entry.place_id
		if place_id.is_empty():
			continue
		if not _index.has(place_id):
			_index[place_id] = []
		_index[place_id].append(entry)


## 특정 장소에 등장 가능한 모든 ScheduleEntry를 반환
func get_entries_for_place(place_id: String) -> Array:
	if _index.has(place_id):
		return _index[place_id]
	return []
