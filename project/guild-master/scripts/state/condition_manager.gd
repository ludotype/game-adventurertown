extends Node

## ConditionManager
## 플레이어의 상태 카드(Condition Card) 보유 목록과 정산(Reckoning)을 관리합니다.

signal condition_added(condition_id: String, stack: int)
signal condition_removed(condition_id: String)
signal condition_stack_changed(condition_id: String, new_stack: int)
signal reckoning_applied(condition_id: String, passed: bool)

const CONDITIONS_DIR := "res://data/conditions/"

var _condition_defs: Dictionary = {}  # condition_id -> definition
var _active_conditions: Dictionary = {}  # condition_id -> { stack: int, duration_remaining: int }


func _ready() -> void:
	_load_all_conditions()


func _load_all_conditions() -> void:
	var dir := DirAccess.open(CONDITIONS_DIR)
	if dir == null:
		push_error("ConditionManager: cannot open directory: " + CONDITIONS_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var path := CONDITIONS_DIR + file_name
			_load_condition_file(path)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("ConditionManager: loaded ", _condition_defs.size(), " condition definitions")


func _load_condition_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ConditionManager: failed to open: " + path)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("ConditionManager: JSON parse error in " + path + ": " + json.get_error_message())
		return

	var data: Dictionary = json.get_data()
	if not data.has("condition_id"):
		push_error("ConditionManager: missing 'condition_id' in " + path)
		return

	var condition_id: String = data["condition_id"]
	if not data.has("max_stack"):
		data["max_stack"] = 1
	_condition_defs[condition_id] = data


func get_condition_def(condition_id: String) -> Dictionary:
	if _condition_defs.has(condition_id):
		return _condition_defs[condition_id]
	return {}


func has_condition(condition_id: String) -> bool:
	return _active_conditions.has(condition_id)


func get_condition_stack(condition_id: String) -> int:
	if _active_conditions.has(condition_id):
		return _active_conditions[condition_id].get("stack", 1)
	return 0


func add_condition(condition_id: String, duration: int = -1, stack: int = 1) -> void:
	var def := get_condition_def(condition_id)
	if def.is_empty():
		push_warning("ConditionManager: unknown condition_id: " + condition_id)
		return

	var max_stack: int = def.get("max_stack", 1)
	if _active_conditions.has(condition_id):
		var current: Dictionary = _active_conditions[condition_id]
		var new_stack: int = mini(current.get("stack", 1) + stack, max_stack)
		current["stack"] = new_stack
		if duration > 0:
			current["duration_remaining"] = duration
		condition_stack_changed.emit(condition_id, new_stack)
	else:
		_active_conditions[condition_id] = {
			"stack": clampi(stack, 1, max_stack),
			"duration_remaining": duration
		}
		condition_added.emit(condition_id, stack)


func remove_condition(condition_id: String) -> void:
	if not _active_conditions.has(condition_id):
		return
	_active_conditions.erase(condition_id)
	condition_removed.emit(condition_id)
	var def := get_condition_def(condition_id)
	if not def.is_empty() and def.has("on_remove"):
		var on_remove: Dictionary = def.get("on_remove", {})
		var actions: Array = on_remove.get("actions", [])
		for action in actions:
			ActionRunner.run(action)


func clear_all_conditions() -> void:
	var ids := _active_conditions.keys().duplicate()
	for condition_id in ids:
		remove_condition(condition_id)


func get_all_active_conditions() -> Dictionary:
	return _active_conditions.duplicate(true)


func apply_reckoning(trigger_context: String = "daily_midnight", context: Dictionary = {}) -> void:
	for condition_id in _active_conditions.keys():
		var def := get_condition_def(condition_id)
		var reckoning: Dictionary = def.get("reckoning", {})
		if reckoning.is_empty():
			continue
		var trigger: String = reckoning.get("trigger", "daily_midnight")
		if trigger != trigger_context:
			continue

		var action: Dictionary = reckoning.get("action", {})
		if action.is_empty():
			continue

		var passed := _evaluate_reckoning_action(action, context)
		reckoning_applied.emit(condition_id, passed)

		# duration 감소
		var info: Dictionary = _active_conditions[condition_id]
		var dur: int = info.get("duration_remaining", -1)
		if dur > 0:
			dur -= 1
			info["duration_remaining"] = dur
			if dur <= 0:
				remove_condition(condition_id)


func _evaluate_reckoning_action(action: Dictionary, context: Dictionary) -> bool:
	var action_type := String(action.get("type", ""))
	match action_type:
		"attribute_check":
			return _run_attribute_check(action, context)
		"change_metric", "log":
			ActionRunner.run(action, context)
			return true
		_:
			ActionRunner.run(action, context)
			return true


func _run_attribute_check(action: Dictionary, context: Dictionary) -> bool:
	var attribute := String(action.get("attribute", "will"))
	var difficulty: int = action.get("difficulty", 1)
	var attr_key := "player." + attribute
	var attr_value: int = MetricStore.get_metric(attr_key, 0)

	# difficulty vs attribute value: 1d6 + attr >= difficulty * 3 (간단한 규칙)
	var roll := randi_range(1, 6)
	var total := roll + attr_value
	var threshold := difficulty * 3
	var passed := total >= threshold

	if passed:
		var pass_actions: Array = action.get("pass_actions", [])
		for pa in pass_actions:
			ActionRunner.run(pa, context)
		if action.has("pass_message"):
			ActionRunner.run({ "type": "log", "message": action["pass_message"] }, context)
	else:
		var fail_actions: Array = action.get("fail_actions", [])
		for fa in fail_actions:
			ActionRunner.run(fa, context)
	return passed


func tick_duration() -> void:
	var ids := _active_conditions.keys().duplicate()
	for condition_id in ids:
		var info: Dictionary = _active_conditions[condition_id]
		var dur: int = info.get("duration_remaining", -1)
		if dur > 0:
			dur -= 1
			info["duration_remaining"] = dur
			if dur <= 0:
				remove_condition(condition_id)
