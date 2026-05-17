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
const INK_BALLOON_SCENE := "res://Story/InkBalloon/ink_balloon.tscn"
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
		"game_over":
			ok = _run_game_over(action_dict)
		"attribute_check":
			ok = _run_attribute_check(action_dict, context)
		"add_condition":
			ok = _run_add_condition(action_dict)
		"remove_condition":
			ok = _run_remove_condition(action_dict)
		"change_doom":
			ok = _run_change_doom(action_dict)
		"block_place":
			ok = _run_block_place(action_dict)
		"unblock_place":
			ok = _run_unblock_place(action_dict)
		"add_item":
			ok = _run_add_item(action_dict)
		"remove_item":
			ok = _run_remove_item(action_dict)
		"equip_item":
			ok = _run_equip_item(action_dict)
		"unequip_item":
			ok = _run_unequip_item(action_dict)
		"open_ui":
			ok = _run_open_ui(action_dict)
		"random_loot":
			ok = _run_random_loot(action_dict)
		"outcome_check":
			ok = _run_outcome_check(action_dict, context)
		"trigger_mandatory":
			ok = _run_trigger_mandatory(action_dict, context)
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

	# Load Ink story
	var ink_path := _find_ink_resource_path(dialogue_id)
	if ink_path.is_empty():
		return _fail(action, "ink story not found: " + dialogue_id)

	var balloon_scene := load(INK_BALLOON_SCENE)
	if balloon_scene == null:
		return _fail(action, "failed to load InkBalloon scene")
	var balloon = balloon_scene.instantiate()
	get_tree().root.add_child(balloon)
	balloon.start(ink_path)
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


func _find_ink_resource_path(dialogue_id: String) -> String:
	if dialogue_id.begins_with("res://") and ResourceLoader.exists(dialogue_id):
		return dialogue_id

	var file_name := dialogue_id
	if not file_name.ends_with(".ink.json"):
		file_name += ".ink.json"

	for base_dir: String in DIALOGUE_SEARCH_DIRS:
		var path: String = base_dir + file_name
		if ResourceLoader.exists(path):
			return path
	return ""


func _run_game_over(action: Dictionary) -> bool:
	var reason := String(action.get("reason", ""))
	var game_over_type := String(action.get("game_over_type", action.get("type", "normal")))
	if not has_node("/root/CrisisManager") or not CrisisManager.has_method("trigger_game_over"):
		return _fail(action, "CrisisManager autoload is missing")
	CrisisManager.trigger_game_over(reason, game_over_type)
	return true


func _run_attribute_check(action: Dictionary, context: Dictionary) -> bool:
	var attribute := String(action.get("attribute", "will"))
	var difficulty: int = action.get("difficulty", 1)
	var attr_key := "player." + attribute
	var attr_value: int = MetricStore.get_metric(attr_key, 0)
	var roll := randi_range(1, 6)
	var total := roll + attr_value
	var threshold := difficulty * 3
	var passed := total >= threshold

	if passed:
		var pass_actions: Array = action.get("pass_actions", [])
		for pa in pass_actions:
			run(pa, context)
		if action.has("pass_message"):
			run({ "type": "log", "message": action["pass_message"] }, context)
	else:
		var fail_actions: Array = action.get("fail_actions", [])
		for fa in fail_actions:
			run(fa, context)
	return true


func _run_add_condition(action: Dictionary) -> bool:
	var condition_id := String(action.get("condition_id", ""))
	if condition_id.is_empty():
		return _fail(action, "add_condition requires condition_id")
	if not has_node("/root/ConditionManager") or not ConditionManager.has_method("add_condition"):
		return _fail(action, "ConditionManager autoload is missing")
	var duration: int = action.get("duration", -1)
	var stack: int = action.get("stack", 1)
	ConditionManager.add_condition(condition_id, duration, stack)
	return true


func _run_remove_condition(action: Dictionary) -> bool:
	var condition_id := String(action.get("condition_id", ""))
	if condition_id.is_empty():
		return _fail(action, "remove_condition requires condition_id")
	if not has_node("/root/ConditionManager") or not ConditionManager.has_method("remove_condition"):
		return _fail(action, "ConditionManager autoload is missing")
	ConditionManager.remove_condition(condition_id)
	return true


func _run_change_doom(action: Dictionary) -> bool:
	var amount: int = action.get("amount", 0)
	if not has_node("/root/CrisisManager") or not CrisisManager.has_method("change_doom"):
		return _fail(action, "CrisisManager autoload is missing")
	CrisisManager.change_doom(amount)
	return true


func _run_block_place(action: Dictionary) -> bool:
	var place_id := String(action.get("place_id", ""))
	if place_id.is_empty():
		return _fail(action, "block_place requires place_id")
	if not has_node("/root/CrisisManager") or not CrisisManager.has_method("block_place"):
		return _fail(action, "CrisisManager autoload is missing")
	var reason := String(action.get("reason", ""))
	CrisisManager.block_place(place_id, reason)
	return true


func _run_unblock_place(action: Dictionary) -> bool:
	var place_id := String(action.get("place_id", ""))
	if place_id.is_empty():
		return _fail(action, "unblock_place requires place_id")
	if not has_node("/root/CrisisManager") or not CrisisManager.has_method("unblock_place"):
		return _fail(action, "CrisisManager autoload is missing")
	CrisisManager.unblock_place(place_id)
	return true


func _run_add_item(action: Dictionary) -> bool:
	var item_id := String(action.get("item_id", ""))
	if item_id.is_empty():
		return _fail(action, "add_item requires item_id")
	if not has_node("/root/InventoryManager") or not InventoryManager.has_method("add_item"):
		return _fail(action, "InventoryManager autoload is missing")
	var amount: int = action.get("amount", 1)
	InventoryManager.add_item(item_id, amount)
	return true


func _run_remove_item(action: Dictionary) -> bool:
	var item_id := String(action.get("item_id", ""))
	if item_id.is_empty():
		return _fail(action, "remove_item requires item_id")
	if not has_node("/root/InventoryManager") or not InventoryManager.has_method("remove_item"):
		return _fail(action, "InventoryManager autoload is missing")
	var amount: int = action.get("amount", 1)
	InventoryManager.remove_item(item_id, amount)
	return true


func _run_equip_item(action: Dictionary) -> bool:
	var item_id := String(action.get("item_id", ""))
	if item_id.is_empty():
		return _fail(action, "equip_item requires item_id")
	if not has_node("/root/InventoryManager") or not InventoryManager.has_method("equip_item"):
		return _fail(action, "InventoryManager autoload is missing")
	InventoryManager.equip_item(item_id)
	return true


func _run_unequip_item(action: Dictionary) -> bool:
	var item_id := String(action.get("item_id", ""))
	if item_id.is_empty():
		return _fail(action, "unequip_item requires item_id")
	if not has_node("/root/InventoryManager") or not InventoryManager.has_method("unequip_item"):
		return _fail(action, "InventoryManager autoload is missing")
	InventoryManager.unequip_item(item_id)
	return true


func _run_open_ui(action: Dictionary) -> bool:
	var ui_name := String(action.get("ui_name", ""))
	if ui_name.is_empty():
		return _fail(action, "open_ui requires ui_name")
	var scene_path := ""
	match ui_name:
		"inventory":
			scene_path = "res://scenes/ui/inventory_window.tscn"
		_:
			return _fail(action, "unknown ui_name: " + ui_name)
	if not ResourceLoader.exists(scene_path):
		return _fail(action, "UI scene not found: " + scene_path)
	var scene = load(scene_path)
	if scene == null:
		return _fail(action, "failed to load UI scene: " + scene_path)
	var instance = scene.instantiate()
	get_tree().root.add_child(instance)
	return true


func _run_random_loot(action: Dictionary) -> bool:
	var table_id := String(action.get("table_id", ""))
	if table_id.is_empty():
		return _fail(action, "random_loot requires table_id")
	if not has_node("/root/LootTableRegistry") or not LootTableRegistry.has_method("roll"):
		return _fail(action, "LootTableRegistry autoload is missing")
	var result: Dictionary = LootTableRegistry.roll(table_id)
	var item_id: String = result.get("item_id", "")
	var count: int = result.get("count", 0)
	var message: String = result.get("message", "")
	if not item_id.is_empty() and count > 0:
		if has_node("/root/InventoryManager") and InventoryManager.has_method("add_item"):
			InventoryManager.add_item(item_id, count)
	if not message.is_empty():
		print("Loot: ", message)
	return true


func _run_outcome_check(action: Dictionary, context: Dictionary) -> bool:
	var attribute := String(action.get("attribute", "will"))
	var difficulty: int = action.get("difficulty", 1)
	var attr_key := "player." + attribute
	var attr_value: int = MetricStore.get_metric(attr_key, 0)
	var roll := randi_range(1, 6)
	var total := roll + attr_value
	var threshold := difficulty * 3
	var diff := total - threshold

	var outcome_key := ""
	if diff >= 3:
		outcome_key = "critical_success"
	elif diff >= 0:
		outcome_key = "success"
	elif diff > -3:
		outcome_key = "failure"
	else:
		outcome_key = "critical_failure"

	var outcomes: Dictionary = action.get("outcomes", {})
	var outcome: Dictionary = outcomes.get(outcome_key, {})

	if outcome.is_empty():
		if outcome_key == "critical_success":
			outcome = outcomes.get("success", {})
		elif outcome_key == "critical_failure":
			outcome = outcomes.get("failure", {})

	var actions: Array = outcome.get("actions", [])
	for child_action in actions:
		run(child_action, context)

	if outcome.has("message"):
		run({ "type": "log", "message": outcome["message"] }, context)

	return true


func _run_trigger_mandatory(action: Dictionary, context: Dictionary) -> bool:
	var trigger_on := String(action.get("trigger_on", ""))
	if trigger_on.is_empty():
		return _fail(action, "trigger_mandatory requires trigger_on")
	if not has_node("/root/CrisisManager") or not CrisisManager.has_method("apply_mandatory_events"):
		return _fail(action, "CrisisManager autoload is missing")
	CrisisManager.apply_mandatory_events(trigger_on, context)
	return true


func _fail(action: Dictionary, reason: String) -> bool:
	push_warning("ActionRunner: " + reason)
	action_failed.emit(action, reason)
	return false
