extends CanvasLayer

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	%ResumeButton.mouse_entered.connect(%ResumeButton.grab_focus)
	%SaveLoadButton.mouse_entered.connect(%SaveLoadButton.grab_focus)
	%SettingsButton.mouse_entered.connect(%SettingsButton.grab_focus)
	%QuitButton.mouse_entered.connect(%QuitButton.grab_focus)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# 인게임(ActionScene) 상태일 때만 일시정지 메뉴 허용
		var current_scene = get_tree().current_scene
		if current_scene and "action_scene.tscn" in current_scene.scene_file_path:
			toggle_pause()

func toggle_pause() -> void:
	var tree = get_tree()
	if not tree: return
	
	tree.paused = not tree.paused
	
	if tree.paused:
		show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		var balloon = tree.root.get_node_or_null("CustomBalloon")
		if balloon:
			%SaveLoadButton.disabled = true
			%SaveLoadButton.modulate = Color(0.5, 0.5, 0.5, 1)
		else:
			%SaveLoadButton.disabled = false
			%SaveLoadButton.modulate = Color(1, 1, 1, 1)
			
		%ResumeButton.grab_focus()
	else:
		hide()

func _on_resume_button_pressed() -> void:
	toggle_pause()

func _on_save_load_button_pressed() -> void:
	var screen = load("res://scenes/ui/save_load_screen.tscn").instantiate()
	get_tree().root.add_child(screen)
	hide()

func _on_settings_button_pressed() -> void:
	var scene = load("res://scenes/ui/settings_screen.tscn").instantiate()
	var settings_layer = CanvasLayer.new()
	settings_layer.layer = 1300
	settings_layer.add_child(scene)
	get_tree().root.add_child(settings_layer)
	hide()
	
	# 설정 화면이 닫힐 때(tree_exited) 처리
	scene.tree_exited.connect(func():
		if is_instance_valid(settings_layer):
			settings_layer.queue_free()
		# 게임 일시정지 해제 및 마우스 모드 복구 (항상 보이게 설정)
		var tree = get_tree()
		if tree:
			tree.paused = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	)

func _on_quit_button_pressed() -> void:
	# GameManager에게 모든 세션 종료를 명령합니다.
	if has_node("/root/GameManager"):
		GameManager.cleanup_game_session()
	
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
	hide()
