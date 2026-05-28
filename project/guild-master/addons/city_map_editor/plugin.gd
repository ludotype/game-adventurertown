@tool
extends EditorPlugin

const DOCK_SCENE = preload("res://addons/city_map_editor/map_editor_dock.tscn")
var dock_instance: Control

func _enter_tree() -> void:
	dock_instance = DOCK_SCENE.instantiate()
	add_control_to_bottom_panel(dock_instance, "City Map Editor")

func _exit_tree() -> void:
	if dock_instance:
		remove_control_from_bottom_panel(dock_instance)
		dock_instance.queue_free()
