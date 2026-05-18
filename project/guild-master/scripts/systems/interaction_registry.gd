extends Node

## InteractionRegistry
## data/interactions/ 폴더를 자동 스캔하여 common / place / char interaction을 인덱싱합니다.

const INTERACTIONS_DIR := "res://data/interactions/"
const COMMON_DIR := INTERACTIONS_DIR + "common/"
const PLACE_DIR := INTERACTIONS_DIR + "place/"
const CHAR_DIR := INTERACTIONS_DIR + "char/"

var _common_interactions: Dictionary = {}  # interaction_id -> definition
var _place_interactions: Dictionary = {}  # place_id -> interaction_id -> definition
var _char_interactions: Dictionary = {}  # npc_id -> interaction_id -> definition
var _ccom_definitions: Dictionary = {}  # ccom_id -> { label }


func _ready() -> void:
	_load_ccom_definitions()
	_load_all_interactions()


func get_available_common(context: Dictionary) -> Array:
	var result: Array = []
	for interaction_id in _common_interactions.keys():
		var definition: Dictionary = _common_interactions[interaction_id]
		if _is_interaction_available(definition, context):
			result.append(definition)
	if has_node("/root/ActionOrderRegistry"):
		return ActionOrderRegistry.get_sorted(result)
	return result


func get_available_for_place(place_id: String, context: Dictionary) -> Array:
	var result: Array = []
	if place_id.is_empty() or not _place_interactions.has(place_id):
		return result

	for interaction_id in _place_interactions[place_id].keys():
		var definition: Dictionary = _place_interactions[place_id][interaction_id]
		if _is_interaction_available(definition, context):
			result.append(definition)
	return result


## common + place 병합. 같은 interaction_id는 place 정의가 우선합니다.
func get_available_place_actions(place_id: String, context: Dictionary) -> Array:
	var merged: Dictionary = {}

	for definition in get_available_common(context):
		var interaction_id := String(definition.get("interaction_id", ""))
		if not interaction_id.is_empty():
			merged[interaction_id] = definition

	for definition in get_available_for_place(place_id, context):
		var interaction_id := String(definition.get("interaction_id", ""))
		if not interaction_id.is_empty():
			merged[interaction_id] = definition

	var result: Array = []
	for interaction_id in merged.keys():
		result.append(merged[interaction_id])
	if has_node("/root/ActionOrderRegistry"):
		return ActionOrderRegistry.get_sorted(result)
	return result


func get_available_for_npc(npc_id: String, context: Dictionary) -> Array:
	var result: Array = []
	if npc_id.is_empty() or not _char_interactions.has(npc_id):
		return result

	for interaction_id in _char_interactions[npc_id].keys():
		var definition: Dictionary = _char_interactions[npc_id][interaction_id]
		if _is_interaction_available(definition, context):
			result.append(definition)
	if has_node("/root/ActionOrderRegistry"):
		return ActionOrderRegistry.get_sorted(result)
	return result


func resolve_common_event(interaction_id: String, context: Dictionary) -> Dictionary:
	if not _common_interactions.has(interaction_id):
		push_warning("InteractionRegistry: unknown common interaction: " + interaction_id)
		return {}
	return _resolve_event(_common_interactions[interaction_id], context)


func resolve_place_event(place_id: String, interaction_id: String, context: Dictionary) -> Dictionary:
	if not _place_interactions.has(place_id) or not _place_interactions[place_id].has(interaction_id):
		push_warning("InteractionRegistry: unknown place interaction: " + place_id + "/" + interaction_id)
		return {}
	return _resolve_event(_place_interactions[place_id][interaction_id], context)


func resolve_npc_event(npc_id: String, interaction_id: String, context: Dictionary) -> Dictionary:
	if not _char_interactions.has(npc_id) or not _char_interactions[npc_id].has(interaction_id):
		push_warning("InteractionRegistry: unknown character interaction: " + npc_id + "/" + interaction_id)
		return {}
	return _resolve_event(_char_interactions[npc_id][interaction_id], context)


func _load_ccom_definitions() -> void:
	var path := "res://data/ccom_definitions.json"
	if not FileAccess.file_exists(path):
		push_warning("InteractionRegistry: ccom definitions not found: " + path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("InteractionRegistry: failed to open ccom definitions")
		return

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	if error != OK:
		push_warning("InteractionRegistry: ccom JSON parse error: " + json.get_error_message())
		return

	var data = json.get_data()
	if typeof(data) == TYPE_DICTIONARY:
		_ccom_definitions = data
		print("[DEBUG] InteractionRegistry: loaded ", _ccom_definitions.size(), " ccom definitions")
	else:
		push_warning("InteractionRegistry: ccom root must be Dictionary")


func _get_ccom_label(ccom_id: String) -> String:
	if _ccom_definitions.has(ccom_id):
		var def = _ccom_definitions[ccom_id]
		if typeof(def) == TYPE_DICTIONARY and def.has("label"):
			return String(def["label"])
	return ""


func _load_all_interactions() -> void:
	_common_interactions.clear()
	_place_interactions.clear()
	_char_interactions.clear()

	_load_common_interactions()
	_load_place_interactions()
	_load_character_interactions()

	print("[DEBUG] InteractionRegistry: loaded ", _common_interactions.size(), " common, ",
		_place_interactions.size(), " place, ",
		_char_interactions.size(), " character interaction groups")


func _load_common_interactions() -> void:
	var dir := DirAccess.open(COMMON_DIR)
	if dir == null:
		push_warning("InteractionRegistry: missing common directory: " + COMMON_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var definition := _load_interaction_file(COMMON_DIR + file_name, "common", "")
			if not definition.is_empty():
				_common_interactions[definition["interaction_id"]] = definition
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_place_interactions() -> void:
	var place_root := DirAccess.open(PLACE_DIR)
	if place_root == null:
		push_warning("InteractionRegistry: missing place directory: " + PLACE_DIR)
		return

	place_root.list_dir_begin()
	var place_dir_name := place_root.get_next()
	while place_dir_name != "":
		if place_root.current_is_dir() and not place_dir_name.begins_with("."):
			_load_place_folder_interactions(place_dir_name)
		place_dir_name = place_root.get_next()
	place_root.list_dir_end()


func _load_place_folder_interactions(place_id: String) -> void:
	var place_dir_path := PLACE_DIR + place_id + "/"
	var dir := DirAccess.open(place_dir_path)
	if dir == null:
		return

	if not _place_interactions.has(place_id):
		_place_interactions[place_id] = {}

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var definition := _load_interaction_file(place_dir_path + file_name, "place", "")
			if not definition.is_empty():
				definition["place_id"] = place_id
				_place_interactions[place_id][definition["interaction_id"]] = definition
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_character_interactions() -> void:
	var char_dir := DirAccess.open(CHAR_DIR)
	if char_dir == null:
		push_warning("InteractionRegistry: missing char directory: " + CHAR_DIR)
		return

	char_dir.list_dir_begin()
	var npc_dir_name := char_dir.get_next()
	while npc_dir_name != "":
		if char_dir.current_is_dir() and not npc_dir_name.begins_with("."):
			_load_npc_interactions(npc_dir_name)
		npc_dir_name = char_dir.get_next()
	char_dir.list_dir_end()


func _load_npc_interactions(npc_id: String) -> void:
	var npc_dir_path := CHAR_DIR + npc_id + "/"
	var dir := DirAccess.open(npc_dir_path)
	if dir == null:
		return

	if not _char_interactions.has(npc_id):
		_char_interactions[npc_id] = {}

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var definition := _load_interaction_file(npc_dir_path + file_name, "char", npc_id)
			if not definition.is_empty():
				_char_interactions[npc_id][definition["interaction_id"]] = definition
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_interaction_file(path: String, scope: String, npc_id: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("InteractionRegistry: failed to open: " + path)
		return {}

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("InteractionRegistry: JSON parse error in " + path + ": " + json.get_error_message())
		return {}

	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("InteractionRegistry: root must be a Dictionary: " + path)
		return {}

	var definition: Dictionary = data
	var interaction_id := String(definition.get("interaction_id", path.get_file().get_basename()))
	if interaction_id.is_empty():
		push_error("InteractionRegistry: missing interaction_id: " + path)
		return {}

	definition["interaction_id"] = interaction_id
	definition["scope"] = scope
	definition["npc_id"] = npc_id
	definition["source_path"] = path
	if not definition.has("events"):
		definition["events"] = []

	if scope == "char" and not definition.has("label"):
		var ccom_label := _get_ccom_label(interaction_id)
		if not ccom_label.is_empty():
			definition["label"] = ccom_label

	return definition


func _is_interaction_available(definition: Dictionary, context: Dictionary) -> bool:
	if definition.has("available_when") and not ConditionEvaluator.evaluate(definition["available_when"], context):
		return false
	return not _resolve_event(definition, context).is_empty()


func _resolve_event(definition: Dictionary, context: Dictionary) -> Dictionary:
	var events: Array = definition.get("events", [])
	var candidates: Array = []
	var best_priority := -2147483648

	for raw_event in events:
		if typeof(raw_event) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = raw_event
		if event.has("when") and not ConditionEvaluator.evaluate(event["when"], context):
			continue

		var priority := int(event.get("priority", 0))
		if priority > best_priority:
			best_priority = priority
			candidates.clear()
		if priority == best_priority:
			candidates.append(event)

	if candidates.is_empty():
		return {}
	if candidates.size() == 1:
		return candidates[0]
	return _pick_weighted_event(candidates)


func _pick_weighted_event(candidates: Array) -> Dictionary:
	var total_weight := 0
	for event in candidates:
		total_weight += max(1, int(event.get("weight", 1)))

	var roll := randi_range(1, total_weight)
	var cumulative := 0
	for event in candidates:
		cumulative += max(1, int(event.get("weight", 1)))
		if roll <= cumulative:
			return event
	return candidates[0]
