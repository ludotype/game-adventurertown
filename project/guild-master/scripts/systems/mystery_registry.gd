extends Node

## MysteryRegistry
## data/mysteries/ 및 data/cases/ 폴더 내 모든 JSON을 스캔하여 인덱싱합니다.

const MYSTERIES_DIR := "res://data/mysteries/"
const CASES_DIR := "res://data/cases/"

var _mysteries: Dictionary = {}  # mystery_id -> mystery_data
var _cases: Dictionary = {}  # case_id -> case_data


func _ready() -> void:
	_load_all_mysteries()
	_load_all_cases()


func _load_all_mysteries() -> void:
	var dir := DirAccess.open(MYSTERIES_DIR)
	if dir == null:
		push_error("MysteryRegistry: cannot open directory: " + MYSTERIES_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var path := MYSTERIES_DIR + file_name
			_load_mystery_file(path)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("MysteryRegistry: loaded ", _mysteries.size(), " mysteries")


func _load_all_cases() -> void:
	var dir := DirAccess.open(CASES_DIR)
	if dir == null:
		push_warning("MysteryRegistry: cannot open cases directory: " + CASES_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var path := CASES_DIR + file_name
			_load_case_file(path)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("MysteryRegistry: loaded ", _cases.size(), " cases")


func _load_case_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("MysteryRegistry: failed to open case: " + path)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("MysteryRegistry: case JSON parse error in " + path + ": " + json.get_error_message())
		return

	var data: Dictionary = json.get_data()
	if not data.has("case_id"):
		push_error("MysteryRegistry: missing 'case_id' in case " + path)
		return

	var case_id: String = data["case_id"]
	if not data.has("mystery_ids"):
		data["mystery_ids"] = []
	if not data.has("activation"):
		data["activation"] = {}

	_cases[case_id] = data


func get_case(case_id: String) -> Dictionary:
	return _cases.get(case_id, {})


func has_case(case_id: String) -> bool:
	return _cases.has(case_id)


func get_case_ids() -> Array:
	return _cases.keys()


func _load_mystery_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("MysteryRegistry: failed to open: " + path)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("MysteryRegistry: JSON parse error in " + path + ": " + json.get_error_message())
		return

	var data: Dictionary = json.get_data()
	if not data.has("mystery_id"):
		push_error("MysteryRegistry: missing 'mystery_id' in " + path)
		return

	var mystery_id: String = data["mystery_id"]
	if not data.has("phases"):
		data["phases"] = []
	if not data.has("escalation"):
		data["escalation"] = {}
	if not data.has("on_resolve"):
		data["on_resolve"] = {}

	_mysteries[mystery_id] = data


func get_mystery(mystery_id: String) -> Dictionary:
	if _mysteries.has(mystery_id):
		return _mysteries[mystery_id]
	return {}


func has_mystery(mystery_id: String) -> bool:
	return _mysteries.has(mystery_id)


func get_all_mystery_ids() -> Array:
	return _mysteries.keys()


func get_mysteries_for_case(case_id: String) -> Array:
	var result: Array = []
	var case_data: Dictionary = get_case(case_id)
	if not case_data.is_empty() and case_data.has("mystery_ids"):
		# Case JSON 기반 순서
		var mystery_ids: Array = case_data["mystery_ids"]
		for mystery_id in mystery_ids:
			if _mysteries.has(mystery_id):
				result.append(_mysteries[mystery_id])
	else:
		# Fallback: linked_case_id 기반
		for mystery_id in _mysteries.keys():
			var data: Dictionary = _mysteries[mystery_id]
			if data.get("linked_case_id", "") == case_id:
				result.append(data)
		result.sort_custom(func(a, b): return a.get("order_in_case", 0) < b.get("order_in_case", 0))
	return result


func get_candidate_mysteries() -> Array:
	var candidates: Array = []
	for mystery_id in _mysteries.keys():
		var data: Dictionary = _mysteries[mystery_id]
		var linked_case_id: String = data.get("linked_case_id", "")
		if linked_case_id.is_empty():
			continue
		var case_resolved: bool = Flags.get_flag("case." + linked_case_id + ".resolved", false)
		if case_resolved:
			continue
		var mystery_resolved: bool = Flags.get_flag("mystery." + mystery_id + ".resolved", false)
		if mystery_resolved:
			continue
		candidates.append(data)
	return candidates
