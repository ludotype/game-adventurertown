extends Node

## ConditionEvaluator
## JSON의 when 조건을 평가합니다.
## 지원 어휘: flag_eq, metric_*, at_place, target_npc, has_target_npc, time_in, time_block, hour_range, time_range, day_eq, day_gte, all_of, any_of, not


func evaluate(condition, context: Dictionary = {}) -> bool:
	if condition == null:
		return true
	if typeof(condition) != TYPE_DICTIONARY:
		push_warning("ConditionEvaluator: condition must be a Dictionary")
		return false

	var condition_dict: Dictionary = condition
	if condition_dict.is_empty():
		return true

	if condition_dict.has("all_of"):
		return _evaluate_all(condition_dict["all_of"], context)
	if condition_dict.has("any_of"):
		return _evaluate_any(condition_dict["any_of"], context)
	if condition_dict.has("not"):
		return not evaluate(condition_dict["not"], context)
	if condition_dict.has("flag_eq"):
		return _evaluate_flag_eq(condition_dict["flag_eq"])
	if condition_dict.has("metric_eq"):
		return _evaluate_metric_compare(condition_dict["metric_eq"], "eq")
	if condition_dict.has("metric_gte"):
		return _evaluate_metric_compare(condition_dict["metric_gte"], "gte")
	if condition_dict.has("metric_lte"):
		return _evaluate_metric_compare(condition_dict["metric_lte"], "lte")
	if condition_dict.has("metric_gt"):
		return _evaluate_metric_compare(condition_dict["metric_gt"], "gt")
	if condition_dict.has("metric_lt"):
		return _evaluate_metric_compare(condition_dict["metric_lt"], "lt")
	if condition_dict.has("at_place"):
		return _evaluate_at_place(condition_dict["at_place"], context)
	if condition_dict.has("target_npc"):
		return _evaluate_target_npc(condition_dict["target_npc"], context)
	if condition_dict.has("has_target_npc"):
		return _evaluate_has_target_npc(condition_dict["has_target_npc"], context)
	if condition_dict.has("time_in"):
		return _evaluate_time_in(condition_dict["time_in"])
	if condition_dict.has("time_block"):
		return _evaluate_time_block(condition_dict["time_block"])
	if condition_dict.has("hour_range"):
		return _evaluate_hour_range(condition_dict["hour_range"])
	if condition_dict.has("time_range"):
		return _evaluate_time_range(condition_dict["time_range"])
	if condition_dict.has("day_eq"):
		return _evaluate_day_eq(condition_dict["day_eq"])
	if condition_dict.has("day_gte"):
		return _evaluate_day_gte(condition_dict["day_gte"])
	if condition_dict.has("crisis_active"):
		return _evaluate_crisis_active(condition_dict["crisis_active"])
	if condition_dict.has("doom_gte"):
		return _evaluate_doom_gte(condition_dict["doom_gte"])
	if condition_dict.has("has_condition"):
		return _evaluate_has_condition(condition_dict["has_condition"])
	if condition_dict.has("place_blocked"):
		return _evaluate_place_blocked(condition_dict["place_blocked"])
	if condition_dict.has("has_item"):
		return _evaluate_has_item(condition_dict["has_item"])

	push_warning("ConditionEvaluator: unknown condition keys: " + str(condition_dict.keys()))
	return false


func _evaluate_all(conditions, context: Dictionary) -> bool:
	if typeof(conditions) != TYPE_ARRAY:
		push_warning("ConditionEvaluator: all_of must be an Array")
		return false

	for condition in conditions:
		if not evaluate(condition, context):
			return false
	return true


func _evaluate_any(conditions, context: Dictionary) -> bool:
	if typeof(conditions) != TYPE_ARRAY:
		push_warning("ConditionEvaluator: any_of must be an Array")
		return false

	for condition in conditions:
		if evaluate(condition, context):
			return true
	return false


func _evaluate_flag_eq(args) -> bool:
	if typeof(args) != TYPE_ARRAY or args.size() < 2:
		push_warning("ConditionEvaluator: flag_eq must be [key, value]")
		return false
	if not has_node("/root/Flags") or not Flags.has_method("get_flag"):
		push_warning("ConditionEvaluator: Flags autoload is missing")
		return false

	var key := String(args[0])
	var expected = args[1]
	var default_value = null
	if expected is bool:
		default_value = false
	return Flags.get_flag(key, default_value) == expected


func _evaluate_metric_compare(args, operator: String) -> bool:
	if typeof(args) != TYPE_ARRAY or args.size() < 2:
		push_warning("ConditionEvaluator: metric condition must be [key, value]")
		return false
	if not has_node("/root/MetricStore") or not MetricStore.has_method("get_metric"):
		push_warning("ConditionEvaluator: MetricStore autoload is missing")
		return false

	var key := String(args[0])
	var expected = args[1]
	var actual = MetricStore.get_metric(key, 0)

	match operator:
		"eq":
			return actual == expected
		"gte":
			return float(actual) >= float(expected)
		"lte":
			return float(actual) <= float(expected)
		"gt":
			return float(actual) > float(expected)
		"lt":
			return float(actual) < float(expected)
		_:
			push_warning("ConditionEvaluator: unknown metric operator: " + operator)
			return false


func _evaluate_at_place(args, context: Dictionary) -> bool:
	var expected_place_id := String(args)
	var current_place_id := String(context.get("place_id", ""))
	return not expected_place_id.is_empty() and current_place_id == expected_place_id


func _evaluate_target_npc(args, context: Dictionary) -> bool:
	var current_npc_id := String(context.get("target_npc", ""))
	if typeof(args) == TYPE_ARRAY:
		return current_npc_id in args
	return not current_npc_id.is_empty() and current_npc_id == String(args)


func _evaluate_has_target_npc(args, context: Dictionary) -> bool:
	return bool(args) == not String(context.get("target_npc", "")).is_empty()


func _evaluate_time_in(args) -> bool:
	if not has_node("/root/TimeSystem"):
		push_warning("ConditionEvaluator: TimeSystem autoload is missing")
		return false
	if typeof(args) != TYPE_ARRAY:
		push_warning("ConditionEvaluator: time_in must be an Array")
		return false

	return TimeSystem.current_time_of_day in args


func _evaluate_time_block(args) -> bool:
	if not has_node("/root/TimeSystem"):
		push_warning("ConditionEvaluator: TimeSystem autoload is missing")
		return false

	if typeof(args) == TYPE_ARRAY:
		return TimeSystem.current_time_of_day in args
	return TimeSystem.current_time_of_day == String(args)


func _evaluate_hour_range(args) -> bool:
	if not has_node("/root/TimeSystem"):
		push_warning("ConditionEvaluator: TimeSystem autoload is missing")
		return false
	if typeof(args) != TYPE_ARRAY or args.size() < 2:
		push_warning("ConditionEvaluator: hour_range must be [start_hour, end_hour]")
		return false

	return TimeSystem.is_current_hour_in_range(int(args[0]), int(args[1]))


func _evaluate_time_range(args) -> bool:
	if not has_node("/root/TimeSystem"):
		push_warning("ConditionEvaluator: TimeSystem autoload is missing")
		return false
	if typeof(args) != TYPE_ARRAY or args.size() < 2:
		push_warning("ConditionEvaluator: time_range must be [start, end]")
		return false

	var start_minutes: int = TimeSystem.parse_time_to_minutes(String(args[0]))
	var end_minutes: int = TimeSystem.parse_time_to_minutes(String(args[1]))
	return TimeSystem.is_current_time_in_range(start_minutes, end_minutes)


func _evaluate_day_eq(args) -> bool:
	if not has_node("/root/TimeSystem"):
		push_warning("ConditionEvaluator: TimeSystem autoload is missing")
		return false
	return TimeSystem.day == int(args)


func _evaluate_day_gte(args) -> bool:
	if not has_node("/root/TimeSystem"):
		push_warning("ConditionEvaluator: TimeSystem autoload is missing")
		return false
	return TimeSystem.day >= int(args)


func _evaluate_crisis_active(args) -> bool:
	if not has_node("/root/CrisisManager") or not CrisisManager.has_method("is_crisis_active"):
		push_warning("ConditionEvaluator: CrisisManager autoload is missing")
		return false
	var crisis_id := String(args)
	return CrisisManager.is_crisis_active(crisis_id)


func _evaluate_doom_gte(args) -> bool:
	if not has_node("/root/CrisisManager") or not CrisisManager.has_method("get_doom"):
		push_warning("ConditionEvaluator: CrisisManager autoload is missing")
		return false
	return CrisisManager.get_doom() >= int(args)


func _evaluate_has_condition(args) -> bool:
	if not has_node("/root/ConditionManager") or not ConditionManager.has_method("has_condition"):
		push_warning("ConditionEvaluator: ConditionManager autoload is missing")
		return false
	var condition_id := String(args)
	if typeof(args) == TYPE_ARRAY and args.size() >= 1:
		condition_id = String(args[0])
	var required_stack: int = 1
	if typeof(args) == TYPE_ARRAY and args.size() >= 2:
		required_stack = int(args[1])
	if not ConditionManager.has_condition(condition_id):
		return false
	return ConditionManager.get_condition_stack(condition_id) >= required_stack


func _evaluate_place_blocked(args) -> bool:
	if not has_node("/root/CrisisManager") or not CrisisManager.has_method("is_place_blocked"):
		push_warning("ConditionEvaluator: CrisisManager autoload is missing")
		return false
	var place_id := String(args)
	return CrisisManager.is_place_blocked(place_id)


func _evaluate_has_item(args) -> bool:
	if not has_node("/root/InventoryManager") or not InventoryManager.has_method("has_item"):
		push_warning("ConditionEvaluator: InventoryManager autoload is missing")
		return false
	var item_id := String(args)
	var required_count: int = 1
	if typeof(args) == TYPE_ARRAY and args.size() >= 1:
		item_id = String(args[0])
		if args.size() >= 2:
			required_count = int(args[1])
	return InventoryManager.has_item(item_id, required_count)
