@tool
extends SceneTree

func _init() -> void:
	print("=== Dialogue Manager Verification ===")
	
	# Verify that the custom balloon tscn can be loaded and instantiated
	var balloon_path = "res://scenes/ui/dialogue/balloon.tscn"
	print("Loading balloon scene: ", balloon_path)
	var scene = load(balloon_path)
	if scene == null:
		print("ERROR: Failed to load balloon.tscn")
		quit(1)
		return
	print("Instantiating balloon scene...")
	var instance = scene.instantiate()
	if instance == null:
		print("ERROR: Failed to instantiate balloon.tscn")
		quit(1)
		return
	print("SUCCESS: Balloon scene instantiated correctly.")
	
	# Verify DialogueManager autoload/script is loadable
	var dm_path = "res://addons/dialogue_manager/dialogue_manager.gd"
	print("Loading DialogueManager script: ", dm_path)
	var dm_script = load(dm_path)
	if dm_script == null:
		print("ERROR: Failed to load DialogueManager script")
		quit(1)
		return
	print("SUCCESS: DialogueManager script loaded successfully.")
	
	# Try parsing one of the resurrected .dialogue files
	var dialogue_file = "res://data/dialogues/elena_default.dialogue"
	print("Loading dialogue file: ", dialogue_file)
	var dialogue_res = load(dialogue_file)
	if dialogue_res == null:
		print("ERROR: Failed to load dialogue file resource: ", dialogue_file)
		quit(1)
		return
	print("SUCCESS: Resurrected dialogue file loaded successfully.")
	
	print("All verification steps passed successfully!")
	quit(0)
