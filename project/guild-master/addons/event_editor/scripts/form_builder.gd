extends VBoxContainer

signal saved(path: String)

const JsonUtil := preload("res://addons/event_editor/scripts/json_util.gd")

var _current_path := ""
var _current_data := {}
var _editors: Dictionary = {}  # key -> Control

func load_file(path: String) -> void:
	_current_path = path
	_current_data = JsonUtil.load_json(path).duplicate(true)
	_build_form()

func clear() -> void:
	_current_path = ""
	_current_data = {}
	_clear_editors()

func save() -> bool:
	if _current_path.is_empty():
		return false
	var ok := JsonUtil.save_json(_current_path, _current_data)
	if ok:
		saved.emit(_current_path)
	return ok

func _clear_editors() -> void:
	for child in get_children():
		child.queue_free()
	_editors.clear()

func _build_form() -> void:
	_clear_editors()
	if _current_data.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Select a JSON file to edit."
		add_child(empty_lbl)
		return

	# Header
	var header := Label.new()
	header.text = _current_path.get_file()
	header.add_theme_font_size_override("font_size", 18)
	add_child(header)

	# Basic string fields
	_add_line_edit("interaction_id", "Interaction ID")
	_add_line_edit("label", "Label")
	_add_line_edit("condition_id", "Condition ID")
	_add_line_edit("event_id", "Event ID")
	_add_line_edit("place_id", "Place ID")
	_add_line_edit("item_id", "Item ID")
	_add_line_edit("table_id", "Table ID")
	_add_line_edit("npc_id", "NPC ID")
	_add_line_edit("dialogue_id", "Dialogue ID")
	_add_line_edit("target_place", "Target Place")
	_add_line_edit("attribute", "Attribute")
	_add_spin_box("difficulty", "Difficulty", 0, 10)
	_add_spin_box("priority", "Priority", -100, 100)
	_add_spin_box("weight", "Weight", 1, 1000)
	_add_spin_box("duration", "Duration", -1, 100)
	_add_spin_box("stack", "Stack", 1, 100)
	_add_spin_box("amount", "Amount", -999, 999)
	_add_spin_box("minutes", "Minutes", 0, 1440)
	_add_spin_box("time_units", "Time Units", 0, 100)
	_add_check_box("alwaysActive", "Always Active")
	_add_check_box("selective", "Selective")
	_add_check_box("useRegex", "Use Regex")
	_add_check_box("disabled", "Disabled")
	_add_text_edit("content", "Content")
	_add_text_edit("message", "Message")
	_add_text_edit("key", "Key / Keys (comma separated)")
	_add_text_edit("secondkey", "Secondary Key")
	_add_json_text_edit("available_when", "Available When (JSON)")
	_add_json_text_edit("when", "When (JSON)")
	_add_json_text_edit("events", "Events (JSON Array)")
	_add_json_text_edit("actions", "Actions (JSON Array)")
	_add_json_text_edit("outcomes", "Outcomes (JSON)")
	_add_json_text_edit("pass_actions", "Pass Actions (JSON)")
	_add_json_text_edit("fail_actions", "Fail Actions (JSON)")
	_add_json_text_edit("then", "Then (JSON)")
	_add_json_text_edit("else", "Else (JSON)")
	_add_json_text_edit("on_remove", "On Remove (JSON)")
	_add_json_text_edit("reckoning", "Reckoning (JSON)")
	_add_json_text_edit("tags", "Tags (JSON)")

	# Save button
	add_child(HSeparator.new())
	var save_btn := Button.new()
	save_btn.text = "Save JSON"
	save_btn.pressed.connect(save)
	add_child(save_btn)

func _add_line_edit(key: String, label_text: String) -> void:
	if not _current_data.has(key):
		return
	var lbl := Label.new()
	lbl.text = label_text
	add_child(lbl)
	var edit := LineEdit.new()
	edit.text = str(_current_data.get(key, ""))
	edit.text_changed.connect(func(new_text): _current_data[key] = new_text)
	add_child(edit)
	_editors[key] = edit

func _add_spin_box(key: String, label_text: String, min_val: int, max_val: int) -> void:
	if not _current_data.has(key):
		return
	var lbl := Label.new()
	lbl.text = label_text
	add_child(lbl)
	var spin := SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.value = float(_current_data.get(key, 0))
	spin.value_changed.connect(func(new_val): _current_data[key] = int(new_val))
	add_child(spin)
	_editors[key] = spin

func _add_check_box(key: String, label_text: String) -> void:
	if not _current_data.has(key):
		return
	var chk := CheckBox.new()
	chk.text = label_text
	chk.button_pressed = bool(_current_data.get(key, false))
	chk.toggled.connect(func(on): _current_data[key] = on)
	add_child(chk)
	_editors[key] = chk

func _add_text_edit(key: String, label_text: String) -> void:
	if not _current_data.has(key):
		return
	var lbl := Label.new()
	lbl.text = label_text
	add_child(lbl)
	var edit := TextEdit.new()
	edit.custom_minimum_size = Vector2(0, 80)
	var val = _current_data.get(key, "")
	edit.text = str(val)
	edit.text_changed.connect(func(): _current_data[key] = edit.text)
	add_child(edit)
	_editors[key] = edit

func _add_json_text_edit(key: String, label_text: String) -> void:
	if not _current_data.has(key):
		return
	var lbl := Label.new()
	lbl.text = label_text
	add_child(lbl)
	var edit := TextEdit.new()
	edit.custom_minimum_size = Vector2(0, 150)
	var val = _current_data.get(key, {})
	edit.text = JSON.stringify(val, "\t")
	edit.text_changed.connect(func():
		var parsed = JSON.parse_string(edit.text)
		if parsed != null:
			_current_data[key] = parsed
	)
	add_child(edit)
	_editors[key] = edit
