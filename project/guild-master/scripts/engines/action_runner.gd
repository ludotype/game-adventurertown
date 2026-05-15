extends Node

## ActionRunner
## JSON action을 실행하는 중앙 라우터입니다.
## 지원 어휘: log, move, dialogue, set_flag, set_metric, change_metric, sequence, if, advance_time, advance_minutes, sleep_until_next_day

signal move_requested(target_place_id: String)
signal action_started(action: Dictionary)
signal action_finished(action: Dictionary)
signal action_failed(action: Dictionary, reason: String)
signal time_changed()
signal metric_changed(key: String, value)

const MAX_DEPTH := 32
const DIALOGUE_SEARCH_DIRS: PackedStringArray = [
	"res://data/dialogues/",
	"res://Story/Dialogues-samples/",
	"res://Story/Dialogues/"
]


func run(action, context: Dictionary = {}, depth: int = 0) -> bool:
	if depth > MAX_DEPTH:
		return _fail({}, "max action depth exceeded")
	if typeof(action) != TYPE_DICTIONARY:
		return _fail({}, "action must be a Dictionary")

	var action_dict: Dictionary = action
	var action_type := String(action_dict.get("type", "log"))
	if action_type != "if" and action_dict.has("when") and not ConditionEvaluator.evaluate(action_dict.get("when"), context):
		return true

	action_started.emit(action_dict)
	var ok := false
	match action_type:
		"log":
			ok = _run_log(action_dict, context)
		"move":
			ok = _run_move(action_dict)
		"dialogue":
			ok = _run_dialogue(action_dict)
		"set_flag":
			ok = _run_set_flag(action_dict)
		"set_metric":
			ok = _run_set_metric(action_dict)
		"change_metric":
			ok = _run_change_metric(action_dict)
		"advance_time":
			ok = _run_advance_time(action_dict)
		"advance_minutes":
			ok = _run_advance_minutes(action_dict)
		"sleep_until_next_day":
			ok = _run_sleep_until_next_day(action_dict)
		"sequence":
			ok = _run_sequence(action_dict, context, depth)
		"if":
			ok = _run_if(action_dict, context, depth)
		_:
			ok = _fail(action_dict, "unknown action type: " + action_type)

	if ok:
		action_finished.emit(action_dict)
	return ok


func _run_log(action: Dictionary, context: Dictionary) -> bool:
	var message := String(action.get("message", action.get("id", "log")))
	print("ActionRunner: ", message, " @ ", context.get("place_id", ""))
	return true


func _run_move(action: Dictionary) -> bool:
	var target_place_id := String(action.get("target_place", action.get("target_place_id", "")))
	if target_place_id.is_empty():
		return _fail(action, "move action requires target_place")
	if not PlaceRegistry.has_place(target_place_id):
		return _fail(action, "unknown target_place: " + target_place_id)

	move_requested.emit(target_place_id)
	return true


func _run_dialogue(action: Dictionary) -> bool:
	var dialogue_id := String(action.get("dialogue_id", ""))
	if dialogue_id.is_empty():
		return _fail(action, "dialogue action requires dialogue_id")

	var resource_path := _find_dialogue_resource_path(dialogue_id)
	if resource_path.is_empty():
		return _fail(action, "dialogue resource not found: " + dialogue_id)

	var resource := load(resource_path)
	if resource == null:
		return _fail(action, "failed to load dialogue resource: " + resource_path)
	if not has_node("/root/DialogueManager") or not DialogueManager.has_method("show_dialogue_balloon"):
		return _fail(action, "DialogueManager is missing")

	var title := String(action.get("title", ""))
	if title.is_empty():
		var first_title = resource.get("first_title")
		if first_title != null:
			title = String(first_title)
	DialogueManager.show_dialogue_balloon(resource, title)
	return true


func _run_set_flag(action: Dictionary) -> bool:
	var key := String(action.get("key", ""))
	if key.is_empty():
		return _fail(action, "set_flag action requires key")
	if not action.has("value"):
		return _fail(action, "set_flag action requires value")
	if not has_node("/root/Flags") or not Flags.has_method("set_flag"):
		return _fail(action, "Flags autoload is missing")

	Flags.set_flag(key, action["value"])
	return true


func _run_set_metric(action: Dictionary) -> bool:
	var key := String(action.get("key", ""))
	if key.is_empty():
		return _fail(action, "set_metric action requires key")
	if not action.has("value"):
		return _fail(action, "set_metric action requires value")
	if not has_node("/root/MetricStore") or not MetricStore.has_method("set_metric"):
		return _fail(action, "MetricStore autoload is missing")

	MetricStore.set_metric(key, action["value"])
	metric_changed.emit(key, action["value"])
	return true


func _run_change_metric(action: Dictionary) -> bool:
	var key := String(action.get("key", ""))
	if key.is_empty():
		return _fail(action, "change_metric action requires key")
	if not action.has("amount"):
		return _fail(action, "change_metric action requires amount")
	if not has_node("/root/MetricStore") or not MetricStore.has_method("change_metric"):
		return _fail(action, "MetricStore autoload is missing")

	MetricStore.change_metric(key, action["amount"])
	metric_changed.emit(key, MetricStore.get_metric(key, 0))
	return true


func _run_advance_time(action: Dictionary) -> bool:
	if not has_node("/root/TimeSystem") or not TimeSystem.has_method("advance_time_units"):
		return _fail(action, "TimeSystem autoload is missing")

	var time_units := int(action.get("time_units", action.get("amount", 1)))
	TimeSystem.advance_time_units(time_units)
	time_changed.emit()
	return true


func _run_advance_minutes(action: Dictionary) -> bool:
	if not has_node("/root/TimeSystem") or not TimeSystem.has_method("advance_minutes"):
		return _fail(action, "TimeSystem autoload is missing")

	var minutes := int(action.get("minutes", 0))
	if minutes <= 0:
		return _fail(action, "advance_minutes action requires minutes > 0")

	TimeSystem.advance_minutes(minutes)
	time_changed.emit()
	return true


func _run_sleep_until_next_day(action: Dictionary) -> bool:
	if not has_node("/root/TimeSystem") or not TimeSystem.has_method("sleep_until_next_day"):
		return _fail(action, "TimeSystem autoload is missing")

	TimeSystem.sleep_until_next_day()
	time_changed.emit()
	return true


func _run_sequence(action: Dictionary, context: Dictionary, depth: int) -> bool:
	var actions = action.get("actions", [])
	if typeof(actions) != TYPE_ARRAY:
		return _fail(action, "sequence action requires actions array")

	for child_action in actions:
		if not run(child_action, context, depth + 1):
			return false
	return true


func _run_if(action: Dictionary, context: Dictionary, depth: int) -> bool:
	var condition = action.get("when", {})
	var branch_key := "then" if ConditionEvaluator.evaluate(condition, context) else "else"
	var branch = action.get(branch_key, [])
	if branch == null:
		return true
	if typeof(branch) == TYPE_ARRAY:
		for child_action in branch:
			if not run(child_action, context, depth + 1):
				return false
		return true
	return run(branch, context, depth + 1)


func _find_dialogue_resource_path(dialogue_id: String) -> String:
	if dialogue_id.begins_with("res://") and ResourceLoader.exists(dialogue_id):
		return dialogue_id

	var file_name := dialogue_id
	if not file_name.ends_with(".dialogue"):
		file_name += ".dialogue"

	for base_dir: String in DIALOGUE_SEARCH_DIRS:
		var path: String = base_dir + file_name
		if ResourceLoader.exists(path):
			return path
	return ""


func _fail(action: Dictionary, reason: String) -> bool:
	push_warning("ActionRunner: " + reason)
	action_failed.emit(action, reason)
	return false
