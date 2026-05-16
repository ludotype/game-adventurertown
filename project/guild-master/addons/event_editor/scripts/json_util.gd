## JsonUtil
## Event Editor에서 사용하는 JSON 읽기/쓰기 유틸리티.

static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("JsonUtil: file not found: " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("JsonUtil: failed to open " + path)
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("JsonUtil: JSON parse error in " + path + ": " + json.get_error_message())
		return {}
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("JsonUtil: root must be Dictionary: " + path)
		return {}
	return data


static func save_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("JsonUtil: failed to write " + path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("JsonUtil: saved ", path)
	return true
