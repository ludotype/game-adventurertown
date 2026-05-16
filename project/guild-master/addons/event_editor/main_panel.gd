extends Control

const FileTreeScript := preload("res://addons/event_editor/scripts/file_tree.gd")
const EntryListScript := preload("res://addons/event_editor/scripts/entry_list.gd")
const FormBuilderScript := preload("res://addons/event_editor/scripts/form_builder.gd")

var _file_tree: Tree
var _entry_list: ItemList
var _form_builder: VBoxContainer

func _ready():
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Toolbar
	var toolbar := HBoxContainer.new()
	toolbar.custom_minimum_size = Vector2(0, 36)
	var refresh_btn := Button.new()
	refresh_btn.text = "Refresh"
	refresh_btn.pressed.connect(_on_refresh)
	toolbar.add_child(refresh_btn)
	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_on_save)
	toolbar.add_child(save_btn)
	add_child(toolbar)

	# Main split: left area (tree + list) vs right area (form)
	var outer_split := HSplitContainer.new()
	outer_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_split.split_offset = -350
	add_child(outer_split)

	# Inner split: tree vs list
	var inner_split := HSplitContainer.new()
	inner_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner_split.split_offset = 220
	outer_split.add_child(inner_split)

	# Left: FileTree panel
	var tree_panel := VBoxContainer.new()
	tree_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var tree_lbl := Label.new()
	tree_lbl.text = "Data Tree"
	tree_lbl.add_theme_font_size_override("font_size", 14)
	tree_panel.add_child(tree_lbl)
	_file_tree = FileTreeScript.new()
	_file_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_file_tree.file_selected.connect(_on_file_selected)
	_file_tree.folder_selected.connect(_on_folder_selected)
	tree_panel.add_child(_file_tree)
	inner_split.add_child(tree_panel)

	# Center: EntryList panel
	var list_panel := VBoxContainer.new()
	list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list_lbl := Label.new()
	list_lbl.text = "Entries"
	list_lbl.add_theme_font_size_override("font_size", 14)
	list_panel.add_child(list_lbl)
	_entry_list = EntryListScript.new()
	_entry_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_entry_list.entries_selected.connect(_on_entries_selected)
	list_panel.add_child(_entry_list)
	inner_split.add_child(list_panel)

	# Right: FormBuilder panel
	var form_panel := VBoxContainer.new()
	form_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var form_lbl := Label.new()
	form_lbl.text = "Editor"
	form_lbl.add_theme_font_size_override("font_size", 14)
	form_panel.add_child(form_lbl)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	form_panel.add_child(scroll)
	_form_builder = FormBuilderScript.new()
	_form_builder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_form_builder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_form_builder.saved.connect(_on_form_saved)
	scroll.add_child(_form_builder)
	outer_split.add_child(form_panel)

func _on_refresh():
	_file_tree.refresh()

func _on_save():
	_form_builder.save()

func _on_form_saved(path: String):
	print("EventEditor: saved ", path)

func _on_folder_selected(path: String):
	_entry_list.show_folder(path)

func _on_file_selected(path: String):
	var folder := path.get_base_dir() + "/"
	if _entry_list._current_folder != folder:
		_entry_list.show_folder(folder)
	# Select corresponding item in list
	for i in _entry_list.item_count:
		if _entry_list.get_item_metadata(i) == path:
			_entry_list.select(i)
			break
	_form_builder.load_file(path)

func _on_entries_selected(paths: Array):
	if paths.size() == 1:
		_form_builder.load_file(paths[0])
	elif paths.is_empty():
		_form_builder.clear()
	else:
		# Multi-select: show first item for now (batch editing future work)
		_form_builder.load_file(paths[0])
