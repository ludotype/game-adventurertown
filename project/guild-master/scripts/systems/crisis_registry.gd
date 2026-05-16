extends Node

## CrisisRegistry
## data/crises/ 폴더 내 모든 위기 JSON을 스캔하여 인덱싱합니다.

const CRISES_DIR := "res://data/crises/"

var _crises: Dictionary = {}  # crisis_id -> crisis_data


func _ready() -> void:
	_load_all_crises()


func _load_all_crises() -> void:
	var dir := DirAccess.open(CRISES_DIR)
	if dir == null:
		push_error("CrisisRegistry: cannot open directory: " + CRISES_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var path := CRISES_DIR + file_name
			_load_crisis_file(path)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("CrisisRegistry: loaded ", _crises.size(), " crises")


func _load_crisis_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("CrisisRegistry: failed to open: " + path)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("CrisisRegistry: JSON parse error in " + path + ": " + json.get_error_message())
		return

	var data: Dictionary = json.get_data()
	if not data.has("crisis_id"):
		push_error("CrisisRegistry: missing 'crisis_id' in " + path)
		return

	var crisis_id: String = data["crisis_id"]
	if not data.has("ongoing_effects"):
		data["ongoing_effects"] = []
	if not data.has("resolution"):
		data["resolution"] = {}
	if not data.has("escalation"):
		data["escalation"] = {}

	_crises[crisis_id] = data


func get_crisis(crisis_id: String) -> Dictionary:
	if _crises.has(crisis_id):
		return _crises[crisis_id]
	return {}


func has_crisis(crisis_id: String) -> bool:
	return _crises.has(crisis_id)


func get_all_crisis_ids() -> Array:
	return _crises.keys()


func get_candidate_crises() -> Array:
	var candidates: Array = []
	for crisis_id in _crises.keys():
		var data: Dictionary = _crises[crisis_id]
		var trigger: Dictionary = data.get("trigger", {})
		var exclude_if: Dictionary = trigger.get("exclude_if", {})
		if not exclude_if.is_empty() and ConditionEvaluator.evaluate(exclude_if):
			continue
		candidates.append(data)
	return candidates
