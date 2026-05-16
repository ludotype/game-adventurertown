@tool
extends EditorPlugin

const MAIN_PANEL_SCENE := preload("res://addons/event_editor/main_panel.tscn")
var _main_panel: Control

func _enter_tree():
	_main_panel = MAIN_PANEL_SCENE.instantiate()
	EditorInterface.get_editor_main_screen().add_child(_main_panel)
	_make_visible(false)

func _exit_tree():
	if _main_panel:
		_main_panel.queue_free()
		_main_panel = null

func _has_main_screen():
	return true

func _make_visible(visible: bool):
	if _main_panel:
		_main_panel.visible = visible

func _get_plugin_name():
	return "Event Editor"

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Script", "EditorIcons")
