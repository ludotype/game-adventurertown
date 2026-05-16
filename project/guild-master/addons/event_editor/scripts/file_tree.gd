extends Tree

signal file_selected(path: String)
signal folder_selected(path: String)

const JsonUtil := preload("res://addons/event_editor/scripts/json_util.gd")
const DATA_ROOT := "res://data/"

var _folder_icon: Texture2D
var _file_icon: Texture2D

func _ready():
	item_selected.connect(_on_item_selected)
	refresh()

func refresh():
	clear()
	_folder_icon = get_theme_icon("Folder", "EditorIcons")
	_file_icon = get_theme_icon("File", "EditorIcons")
	var root := create_item()
	root.set_text(0, "data")
	root.set_metadata(0, DATA_ROOT)
	root.set_icon(0, _folder_icon)
	_populate(root, DATA_ROOT)

func _populate(parent: TreeItem, dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var full_path := dir_path + file_name
		if dir.current_is_dir():
			var item := create_item(parent)
			item.set_text(0, file_name)
			item.set_metadata(0, full_path + "/")
			item.set_icon(0, _folder_icon)
			_populate(item, full_path + "/")
		else:
			if file_name.ends_with(".json"):
				var item := create_item(parent)
				item.set_text(0, file_name)
				item.set_metadata(0, full_path)
				item.set_icon(0, _file_icon)
		file_name = dir.get_next()
	dir.list_dir_end()

func _on_item_selected():
	var item := get_selected()
	if item == null:
		return
	var path: String = item.get_metadata(0)
	if path.ends_with("/"):
		folder_selected.emit(path)
	else:
		file_selected.emit(path)
