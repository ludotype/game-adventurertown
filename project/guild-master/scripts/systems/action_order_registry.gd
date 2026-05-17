extends Node

## ActionOrderRegistry
## data/interactions/ 를 스캔하여 발견된 모든 interaction_id를 수집하고,
## data/action_order.json 과 병합하여 기획자가 편집 가능한 표시 순서를 관리합니다.
##
## 규칙:
## - 기존 action_order.json 의 순서를 유지합니다.
## - json 에 없는 새로운 행동은 맨 아래에 추가되고 tags 에 "new" 가 붙습니다.
## - 스캔 결과에서 사라진 행동은 tags 에 "not_found" 가 붙습니다.
## - 기획자가 json 을 편집하여 순서를 바꾸면 그 순서가 유지됩니다.

const ORDER_FILE := "res://data/action_order.json"
const INTERACTIONS_DIR := "res://data/interactions/"

var _entries: Array = []


func _ready() -> void:
	await get_tree().process_frame
	_refresh()


func _refresh() -> void:
	var scanned := _scan_interaction_ids()
	var existing := _load_order_file()
	var merged := _merge_entries(existing, scanned)
	_entries = merged.get("entries", [])
	_save_order_file(merged)
	print("ActionOrderRegistry: merged ", _entries.size(), " entries")


func _scan_interaction_ids() -> Dictionary:
	var ids := {}
	_scan_dir(INTERACTIONS_DIR + "common/", ids)
	_scan_nested_dirs(INTERACTIONS_DIR + "place/", ids)
	_scan_nested_dirs(INTERACTIONS_DIR + "char/", ids)
	return ids


func _scan_dir(dir_path: String, out_ids: Dictionary) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var id := _extract_id(dir_path + file_name)
			if not id.is_empty():
				out_ids[id] = true
		file_name = dir.get_next()
	dir.list_dir_end()


func _scan_nested_dirs(root_path: String, out_ids: Dictionary) -> void:
	var root := DirAccess.open(root_path)
	if root == null:
		return
	root.list_dir_begin()
	var sub := root.get_next()
	while sub != "":
		if root.current_is_dir() and not sub.begins_with("."):
			_scan_dir(root_path + sub + "/", out_ids)
		sub = root.get_next()
	root.list_dir_end()


func _extract_id(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return ""
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return ""
	return String(data.get("interaction_id", ""))


func _load_order_file() -> Dictionary:
	var file := FileAccess.open(ORDER_FILE, FileAccess.READ)
	if file == null:
		return { "version": 1, "entries": [] }
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return { "version": 1, "entries": [] }
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return { "version": 1, "entries": [] }
	return data


func _merge_entries(existing: Dictionary, scanned: Dictionary) -> Dictionary:
	var entries: Array = []
	var used_scanned: Dictionary = {}

	for raw in existing.get("entries", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw.duplicate(true)
		var id := String(entry.get("id", ""))
		if id.is_empty():
			continue
		var tags: Array = entry.get("tags", []).duplicate()
		if scanned.has(id):
			tags.erase("not_found")
			used_scanned[id] = true
		else:
			if not tags.has("not_found"):
				tags.append("not_found")
		entry["tags"] = tags
		entries.append(entry)

	for id in scanned.keys():
		if not used_scanned.has(id):
			entries.append({
				"id": id,
				"label": "",
				"tags": ["new"]
			})
			used_scanned[id] = true

	return { "version": 1, "entries": entries }


func _save_order_file(data: Dictionary) -> void:
	var file := FileAccess.open(ORDER_FILE, FileAccess.WRITE)
	if file == null:
		push_warning("ActionOrderRegistry: failed to write " + ORDER_FILE)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


## 주어진 definition 배열을 action_order.json 의 순서대로 정렬하여 반환합니다.
func get_sorted(definitions: Array) -> Array:
	var order_map := {}
	var idx := 0
	for entry in _entries:
		order_map[String(entry.get("id", ""))] = idx
		idx += 1

	var sorted := definitions.duplicate()
	sorted.sort_custom(func(a, b) -> int:
		var a_id := ""
		var b_id := ""
		if typeof(a) == TYPE_DICTIONARY:
			a_id = String(a.get("interaction_id", ""))
		else:
			a_id = String(a)
		if typeof(b) == TYPE_DICTIONARY:
			b_id = String(b.get("interaction_id", ""))
		else:
			b_id = String(b)
		var a_idx := order_map.get(a_id, 999999)
		var b_idx := order_map.get(b_id, 999999)
		if a_idx < b_idx:
			return -1
		elif a_idx > b_idx:
			return 1
		return 0
	)
	return sorted
