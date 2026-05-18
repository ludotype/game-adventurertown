extends Node

## PlaceRegistry
## data/places/ 폴더 내 모든 JSON을 스캔하여 장소 메타데이터를 관리합니다.

const PLACES_DIR := "res://data/places/"

var _places: Dictionary = {}  # place_id -> place_data


func _ready() -> void:
	_load_all_places()


func _load_all_places() -> void:
	var dir := DirAccess.open(PLACES_DIR)
	if dir == null:
		push_error("PlaceRegistry: cannot open directory: " + PLACES_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and not dir.current_is_dir():
			var path := PLACES_DIR + file_name
			_load_place_file(path)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("[DEBUG] PlaceRegistry: loaded ", _places.size(), " places")


func _load_place_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("PlaceRegistry: failed to open: " + path)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("PlaceRegistry: JSON parse error in " + path + ": " + json.get_error_message())
		return

	var data: Dictionary = json.get_data()
	if not data.has("place_id"):
		push_error("PlaceRegistry: missing 'place_id' in " + path)
		return

	var place_id: String = data["place_id"]
	if not data.has("empty_weight"):
		data["empty_weight"] = 0

	_places[place_id] = data


func get_place(place_id: String) -> Dictionary:
	if _places.has(place_id):
		return _places[place_id]
	return {}


func has_place(place_id: String) -> bool:
	return _places.has(place_id)
