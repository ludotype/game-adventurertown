extends ItemList

signal entries_selected(paths: Array)

const JsonUtil := preload("res://addons/event_editor/scripts/json_util.gd")

var _current_folder := ""

func _ready():
	multi_selected.connect(_on_multi_selected)
	item_selected.connect(_on_item_selected)

func show_folder(folder_path: String) -> void:
	_current_folder = folder_path
	clear()
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var full_path := folder_path + file_name
			var json := JsonUtil.load_json(full_path)
			var label = json.get("label", json.get("interaction_id", json.get("condition_id", json.get("event_id", json.get("place_id", file_name)))))
			add_item(str(label))
			set_item_metadata(item_count - 1, full_path)
		file_name = dir.get_next()
	dir.list_dir_end()

func _on_item_selected(index: int) -> void:
	_emit_selection()

func _on_multi_selected(index: int, selected: bool) -> void:
	_emit_selection()

func _emit_selection() -> void:
	var paths: Array = []
	for i in get_selected_items():
		paths.append(get_item_metadata(i))
	entries_selected.emit(paths)
