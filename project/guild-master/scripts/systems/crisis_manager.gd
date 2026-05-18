extends Node

## CrisisManager
## 활성 위기 상태 관리, 7일 위기 페이즈(Mythos), 둠 트래커, 정산(Reckoning)을 담당합니다.

signal crisis_triggered(crisis_data: Dictionary)
signal crisis_resolved(crisis_id: String)
signal crisis_doomed(crisis_id: String, reason: String)
signal doom_changed(new_doom: int)
signal game_over_triggered(reason: String, game_over_type: String)
signal place_blocked(place_id: String, reason: String)
signal place_unblocked(place_id: String)

const SEVERITY_SLOTS := {
	"minor": 0.5,
	"major": 1.0,
	"doom": 2.0
}

var _active_crises: Dictionary = {}  # crisis_id -> { doom_timer: int, data: Dictionary }
var _blocked_places: Dictionary = {}  # place_id -> reason
var _doom: int = 0
var _global_doom: Dictionary = {}
var _doom_thresholds_triggered: Dictionary = {}
var _mandatory_events: Dictionary = {}


func _ready() -> void:
	_load_global_doom()
	_load_mandatory_events()
	_reset_state()
	if has_node("/root/TimeSystem"):
		TimeSystem.day_started.connect(_on_day_started)


func _on_day_started(day: int) -> void:
	on_daily_reckoning("daily_midnight")
	if day % 7 == 0:
		on_mythos_phase()


func _load_global_doom() -> void:
	var path := "res://data/global_doom.json"
	if not FileAccess.file_exists(path):
		push_warning("CrisisManager: global_doom.json not found")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	if error == OK:
		var data = json.get_data()
		if typeof(data) == TYPE_DICTIONARY:
			_global_doom = data.get("doom_track", {})


func _load_mandatory_events() -> void:
	var dir := DirAccess.open("res://data/mandatory_events/")
	if dir == null:
		push_warning("CrisisManager: mandatory_events directory not found")
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var path := "res://data/mandatory_events/" + file_name
			var file := FileAccess.open(path, FileAccess.READ)
			if file != null:
				var json := JSON.new()
				var error := json.parse(file.get_as_text())
				file.close()
				if error == OK:
					var data = json.get_data()
					if typeof(data) == TYPE_DICTIONARY and data.has("event_id"):
						_mandatory_events[data["event_id"]] = data
					else:
						push_warning("CrisisManager: missing event_id in " + path)
				else:
					push_warning("CrisisManager: JSON parse error in " + path)
		file_name = dir.get_next()
	dir.list_dir_end()
	print("[DEBUG] CrisisManager: loaded ", _mandatory_events.size(), " mandatory events")


func reset_state() -> void:
	_active_crises.clear()
	_blocked_places.clear()
	_doom_thresholds_triggered.clear()
	_doom = _global_doom.get("initial", 0)


func _reset_state() -> void:
	reset_state()


func _emit_log(message: String) -> void:
	if has_node("/root/ActionRunner"):
		ActionRunner.log_emitted.emit(message, {})


func on_mythos_phase() -> void:
	_emit_log("Mythos Phase triggered on day " + str(TimeSystem.day))

	# 1. 기존 활성 위기 doom_timer 감소 및 파멸 체크
	var doomed: Array = []
	for crisis_id in _active_crises.keys():
		var state: Dictionary = _active_crises[crisis_id]
		state["doom_timer"] -= 1
		if state["doom_timer"] <= 0:
			doomed.append(crisis_id)

	for crisis_id in doomed:
		_doom_crisis(crisis_id)

	# 2. 슬롯 여유 확인 후 새 위기 발생
	var used_slots := _calculate_used_slots()
	var max_slots: int = 3
	var available_slots := max_slots - used_slots

	if available_slots > 0:
		var candidates: Array = CrisisRegistry.get_candidate_crises()
		var valid_candidates := _filter_valid_candidates(candidates, available_slots)
		if not valid_candidates.is_empty():
			var chosen: Dictionary = valid_candidates.pick_random()
			_activate_crisis(chosen)

	# 3. 활성 위기의 per_day_effects 적용
	for crisis_id in _active_crises.keys():
		var data: Dictionary = _active_crises[crisis_id]["data"]
		var escalation: Dictionary = data.get("escalation", {})
		var per_day: Array = escalation.get("per_day_effects", [])
		for effect in per_day:
			ActionRunner.run(effect)

	# 4. 둠 트래커 임계값 체크
	_evaluate_doom_thresholds()


func on_daily_reckoning(trigger_context: String = "daily_midnight") -> void:
	ConditionManager.apply_reckoning(trigger_context)


func _calculate_used_slots() -> float:
	var used: float = 0.0
	for crisis_id in _active_crises.keys():
		var data: Dictionary = _active_crises[crisis_id]["data"]
		var severity: String = data.get("severity", "major")
		used += SEVERITY_SLOTS.get(severity, 1.0)
	return used


func _filter_valid_candidates(candidates: Array, available_slots: float) -> Array:
	var valid: Array = []
	for c in candidates:
		var data: Dictionary = c
		var severity: String = data.get("severity", "major")
		var needed: float = SEVERITY_SLOTS.get(severity, 1.0)
		if needed <= available_slots and not _active_crises.has(data["crisis_id"]):
			valid.append(data)
	return valid


func _activate_crisis(data: Dictionary) -> void:
	var crisis_id: String = data["crisis_id"]
	var escalation: Dictionary = data.get("escalation", {})
	var doom_days: int = escalation.get("doom_days", 14)

	_active_crises[crisis_id] = {
		"doom_timer": doom_days,
		"data": data
	}
	Flags.set_flag("crisis." + crisis_id + ".active", true)
	crisis_triggered.emit(data)
	_emit_log("Activated crisis " + crisis_id + " (doom_timer=" + str(doom_days) + ")")


func _doom_crisis(crisis_id: String) -> void:
	if not _active_crises.has(crisis_id):
		return
	var state: Dictionary = _active_crises[crisis_id]
	var data: Dictionary = state["data"]
	var escalation: Dictionary = data.get("escalation", {})
	var doom_actions: Array = escalation.get("doom_actions", [])

	_active_crises.erase(crisis_id)
	Flags.set_flag("crisis." + crisis_id + ".active", false)
	Flags.set_flag("crisis." + crisis_id + ".doomed", true)

	for action in doom_actions:
		ActionRunner.run(action)

	change_doom(2)
	crisis_doomed.emit(crisis_id, data.get("display_name", ""))


func try_resolve_crisis(crisis_id: String) -> bool:
	if not _active_crises.has(crisis_id):
		return false
	var data: Dictionary = _active_crises[crisis_id]["data"]
	var resolution: Dictionary = data.get("resolution", {})
	var conditions: Dictionary = resolution.get("conditions", {})

	if not conditions.is_empty() and not ConditionEvaluator.evaluate(conditions):
		return false

	var actions: Array = resolution.get("actions", [])
	for action in actions:
		ActionRunner.run(action)

	_active_crises.erase(crisis_id)
	Flags.set_flag("crisis." + crisis_id + ".active", false)
	Flags.set_flag("crisis." + crisis_id + ".resolved", true)
	change_doom(-1)
	crisis_resolved.emit(crisis_id)
	return true


func change_doom(amount: int) -> void:
	_doom = clampi(_doom + amount, 0, _global_doom.get("max", 20))
	doom_changed.emit(_doom)
	_evaluate_doom_thresholds()


func get_doom() -> int:
	return _doom


func _evaluate_doom_thresholds() -> void:
	var thresholds: Array = _global_doom.get("thresholds", [])
	for t in thresholds:
		var threshold: Dictionary = t
		var at: int = threshold.get("at", 0)
		var key := str(at)
		if _doom >= at and not _doom_thresholds_triggered.get(key, false):
			_doom_thresholds_triggered[key] = true
			var action: Dictionary = threshold.get("action", {})
			if not action.is_empty():
				ActionRunner.run(action)


func is_crisis_active(crisis_id: String) -> bool:
	return _active_crises.has(crisis_id)


func get_active_crises() -> Dictionary:
	return _active_crises.duplicate(true)


func get_active_crisis_ids() -> Array:
	return _active_crises.keys()


func apply_ongoing_effects(trigger_on: String, context: Dictionary = {}) -> void:
	for crisis_id in _active_crises.keys():
		var data: Dictionary = _active_crises[crisis_id]["data"]
		var effects: Array = data.get("ongoing_effects", [])
		for effect in effects:
			var effect_dict: Dictionary = effect
			if effect_dict.get("trigger_on", "") != trigger_on:
				continue
			if effect_dict.has("when") and not ConditionEvaluator.evaluate(effect_dict.get("when"), context):
				continue
			var action: Dictionary = effect_dict.get("action", {})
			if not action.is_empty():
				ActionRunner.run(action, context)


func apply_mandatory_events(trigger_on: String, context: Dictionary = {}) -> void:
	for event_id in _mandatory_events.keys():
		var data: Dictionary = _mandatory_events[event_id]
		if data.get("trigger_on", "") != trigger_on:
			continue
		if data.has("when") and not ConditionEvaluator.evaluate(data.get("when"), context):
			continue
		var actions: Array = data.get("actions", [])
		for action in actions:
			ActionRunner.run(action, context)
		_emit_log("Applied mandatory event " + event_id + " on " + trigger_on)


func block_place(place_id: String, reason: String = "") -> void:
	_blocked_places[place_id] = reason
	place_blocked.emit(place_id, reason)
	_emit_log("Blocked place " + place_id + (" reason=" + reason if not reason.is_empty() else ""))


func unblock_place(place_id: String) -> void:
	if _blocked_places.has(place_id):
		_blocked_places.erase(place_id)
		place_unblocked.emit(place_id)


func is_place_blocked(place_id: String) -> bool:
	return _blocked_places.has(place_id)


func get_block_reason(place_id: String) -> String:
	return _blocked_places.get(place_id, "")


func trigger_game_over(reason: String, game_over_type: String = "normal") -> void:
	game_over_triggered.emit(reason, game_over_type)
	_emit_log("GAME OVER - " + reason + " (type=" + game_over_type + ")")
