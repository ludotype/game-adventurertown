extends Node

## ItemRegistry
## data/items/ 폴더 내 모든 JSON을 스캔하여 아이템 정의를 관리합니다.

const ITEMS_DIR := "res://data/items/"

var _items: Dictionary = {}  # item_id -> item_data


func _ready() -> void:
	_load_all_items()


func _load_all_items() -> void:
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		push_error("ItemRegistry: cannot open directory: " + ITEMS_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var path := ITEMS_DIR + file_name
			_load_item_file(path)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("ItemRegistry: loaded ", _items.size(), " items")


func _load_item_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ItemRegistry: failed to open: " + path)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("ItemRegistry: JSON parse error in " + path + ": " + json.get_error_message())
		return

	var data: Dictionary = json.get_data()
	if not data.has("item_id"):
		push_error("ItemRegistry: missing 'item_id' in " + path)
		return

	var item_id: String = data["item_id"]
	if not data.has("max_stack"):
		data["max_stack"] = 99
	if not data.has("category"):
		data["category"] = "material"
	if not data.has("effects"):
		data["effects"] = []

	_items[item_id] = data


func get_item(item_id: String) -> Dictionary:
	if _items.has(item_id):
		return _items[item_id]
	return {}


func has_item(item_id: String) -> bool:
	return _items.has(item_id)


func get_all_item_ids() -> Array:
	return _items.keys()
