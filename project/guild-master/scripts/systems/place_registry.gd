extends Node

## PlaceRegistry
## 단일 places.json 파일을 스캔하여 도시의 장소 메타데이터를 통합 관리합니다.

const PLACES_FILE := "res://data/places.json"

var _places: Dictionary = {}  # place_id -> place_data


func _ready() -> void:
	_load_all_places()


func _load_all_places() -> void:
	if not FileAccess.file_exists(PLACES_FILE):
		push_error("PlaceRegistry: places.json file does not exist: " + PLACES_FILE)
		return

	var file := FileAccess.open(PLACES_FILE, FileAccess.READ)
	if file == null:
		push_error("PlaceRegistry: failed to open: " + PLACES_FILE)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("PlaceRegistry: JSON parse error in " + PLACES_FILE + ": " + json.get_error_message())
		return

	var result = json.get_data()
	if not (result is Dictionary) or not result.has("places"):
		push_error("PlaceRegistry: malformed json structure in " + PLACES_FILE)
		return

	var places_list: Array = result.get("places", [])
	for data in places_list:
		if not (data is Dictionary):
			continue
			
		var place_dict: Dictionary = data
		var place_id: String = place_dict.get("id", "")
		if place_id == "":
			push_error("PlaceRegistry: missing 'id' in place definition")
			continue

		# 하위 호환성 보장: id 필드를 place_id 필드로 동시 바인딩
		place_dict["place_id"] = place_id
		
		# 필수 기본 필드 기본값 보충
		if not place_dict.has("empty_weight"):
			place_dict["empty_weight"] = 0
		if not place_dict.has("tags"):
			place_dict["tags"] = []
		if not place_dict.has("connections"):
			place_dict["connections"] = []
		if not place_dict.has("paths"):
			place_dict["paths"] = []

		_places[place_id] = place_dict

	print("[DEBUG] PlaceRegistry: loaded ", _places.size(), " places from places.json")


func get_place(place_id: String) -> Dictionary:
	if _places.has(place_id):
		return _places[place_id]
	return {}


func has_place(place_id: String) -> bool:
	return _places.has(place_id)
