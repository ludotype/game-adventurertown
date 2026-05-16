extends Node

## LootTableRegistry
## data/loot_tables/ 폴더 내 모든 JSON을 스캔하여 전리품 테이블을 관리합니다.

const TABLES_DIR := "res://data/loot_tables/"

var _tables: Dictionary = {}  # table_id -> { entries: Array }


func _ready() -> void:
	_load_all_tables()


func _load_all_tables() -> void:
	var dir := DirAccess.open(TABLES_DIR)
	if dir == null:
		push_error("LootTableRegistry: cannot open directory: " + TABLES_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var path := TABLES_DIR + file_name
			_load_table_file(path)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("LootTableRegistry: loaded ", _tables.size(), " tables")


func _load_table_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("LootTableRegistry: failed to open: " + path)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("LootTableRegistry: JSON parse error in " + path + ": " + json.get_error_message())
		return

	var data: Dictionary = json.get_data()
	if not data.has("table_id"):
		push_error("LootTableRegistry: missing 'table_id' in " + path)
		return

	var table_id: String = data["table_id"]
	if not data.has("entries"):
		data["entries"] = []
	_tables[table_id] = data


func get_table(table_id: String) -> Dictionary:
	if _tables.has(table_id):
		return _tables[table_id]
	return {}


func has_table(table_id: String) -> bool:
	return _tables.has(table_id)


func roll(table_id: String) -> Dictionary:
	var data := get_table(table_id)
	if data.is_empty():
		push_warning("LootTableRegistry: unknown table_id: " + table_id)
		return { "item_id": "", "count": 0, "message": "" }

	var entries: Array = data.get("entries", [])
	if entries.is_empty():
		return { "item_id": "", "count": 0, "message": "" }

	var total_weight := 0
	for entry in entries:
		var e: Dictionary = entry
		total_weight += e.get("weight", 0)

	if total_weight <= 0:
		return { "item_id": "", "count": 0, "message": "" }

	var roll_value := randi_range(1, total_weight)
	var cumulative := 0
	for entry in entries:
		var e: Dictionary = entry
		cumulative += e.get("weight", 0)
		if roll_value <= cumulative:
			var item_id: String = e.get("item_id", "")
			var min_count: int = e.get("min_count", 1)
			var max_count: int = e.get("max_count", 1)
			var count := randi_range(min_count, max_count) if not item_id.is_empty() else 0
			var message: String = e.get("message", "")
			if message.is_empty() and not item_id.is_empty():
				var def := ItemRegistry.get_item(item_id)
				var display_name: String = def.get("display_name", item_id)
				message = display_name + "을(를) " + str(count) + "개 발견했다."
			return { "item_id": item_id, "count": count, "message": message }

	return { "item_id": "", "count": 0, "message": "" }
