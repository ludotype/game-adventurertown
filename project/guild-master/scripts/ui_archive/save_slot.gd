extends Button

signal slot_pressed(index: int)

@onready var empty_label: Label = $EmptyLabel
@onready var margin: MarginContainer = $MarginContainer
@onready var day_label: Label = $MarginContainer/VBoxContainer/Header/DayLabel
@onready var rank_label: Label = $MarginContainer/VBoxContainer/Header/RankLabel
@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeLabel

var _index: int = 0

func setup(index: int) -> void:
	_index = index
	var info := {}
	if has_node("/root/SaveManager") and SaveManager.has_method("get_slot_info"):
		info = SaveManager.get_slot_info(index)

	if info.is_empty() or info.has("error"):
		_show_empty()
	else:
		_show_data(info)

func _show_empty() -> void:
	empty_label.visible = true
	margin.visible = false
	day_label.text = ""
	rank_label.text = ""
	time_label.text = ""

func _show_data(info: Dictionary) -> void:
	empty_label.visible = false
	margin.visible = true
	day_label.text = "DAY %d" % info.get("day", 1)
	rank_label.text = "SCORE %d" % info.get("score", 0)
	var hour: int = info.get("hour", 7)
	var minute: int = info.get("minute", 0)
	time_label.text = "%02d:%02d" % [hour, minute]

func _on_pressed() -> void:
	slot_pressed.emit(_index)
