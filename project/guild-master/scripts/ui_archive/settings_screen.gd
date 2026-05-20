extends Control

@onready var mode_label: Label = %ModeLabel
@onready var res_label: Label = %ResLabel
@onready var vsync_label: Label = %VSyncLabel
@onready var lang_label: Label = %LangLabel
@onready var music_gauge: ProgressBar = %MusicGauge
@onready var sound_gauge: ProgressBar = %SoundGauge

# 언어 변경 버튼 참조 추가
@onready var lang_prev_button: Button = $VBoxContainer/GridContainer/LangControl/LangPrev
@onready var lang_next_button: Button = $VBoxContainer/GridContainer/LangControl/LangNext

func _ready() -> void:
	# 일시정지 중에도 UI가 작동하도록 설정
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 툴팁 폰트 크기 설정을 위한 테마 생성 (14px)
	var tooltip_theme = Theme.new()
	tooltip_theme.set_font_size("font_size", "TooltipLabel", 14)
	theme = tooltip_theme
	
	_setup_tooltips()
	update_ui()
	_check_ingame_restrictions()

func _setup_tooltips() -> void:
	# 각 항목의 제목과 조작부 전체에 툴팁을 적용합니다.
	var grid = $VBoxContainer/GridContainer
	
	var rows = [
		["ModeLabelTitle", "ModeControl", "TIP_DISPLAY_MODE"],
		["ResLabelTitle", "ResControl", "TIP_RESOLUTION"],
		["VSyncLabelTitle", "VSyncControl", "TIP_VSYNC"],
		["MusicLabelTitle", "MusicControl", "TIP_MUSIC"],
		["SoundLabelTitle", "SoundControl", "TIP_SOUND"],
		["LangLabelTitle", "LangControl", "TIP_LANGUAGE"]
	]
	
	for row in rows:
		var title_node = grid.get_node(row[0])
		var control_node = grid.get_node(row[1])
		var tt_text = tr(row[2])
		
		if title_node:
			title_node.tooltip_text = tt_text
			title_node.mouse_filter = Control.MOUSE_FILTER_STOP
			
		if control_node:
			control_node.tooltip_text = tt_text
			control_node.mouse_filter = Control.MOUSE_FILTER_STOP
			# 버튼 등 자식 노드들에게도 툴팁을 전파합니다.
			for child in control_node.get_children():
				if child is Control:
					child.tooltip_text = tt_text

func _check_ingame_restrictions() -> void:
	# 타이틀 화면에서만 언어 변경이 가능하도록 엄격히 제한
	var current_scene_path = get_tree().current_scene.scene_file_path
	var is_title_screen = current_scene_path == "res://scenes/ui/title_screen.tscn"
	
	if not is_title_screen:
		lang_prev_button.disabled = true
		lang_next_button.disabled = true
		lang_label.modulate = Color(0.4, 0.4, 0.4, 1)

func update_ui() -> void:
	# 디스플레이 모드 텍스트 업데이트
	var modes = ["FULLSCREEN", "BORDERLESS", "WINDOWED"]
	mode_label.text = modes[SettingsManager.display_mode]
	
	# 해상도 텍스트 업데이트 및 비활성화 처리
	var res_texts = ["1280x720", "1706x960", "1920x1080"]
	res_label.text = res_texts[SettingsManager.resolution_index]
	
	if SettingsManager.display_mode == 2: # Windowed
		res_label.modulate = Color(1, 1, 1, 1) # 흰색
	else:
		res_label.modulate = Color(0.4, 0.4, 0.4, 1) # 회색
	
	# VSync 텍스트 업데이트
	vsync_label.text = "ON" if SettingsManager.vsync_enabled else "OFF"
	
	# 언어 텍스트 업데이트 (EN, KO, JA 지원)
	match SettingsManager.current_language:
		"en": lang_label.text = tr("ui_lang_english")
		"ko": lang_label.text = tr("ui_lang_korean")
		"ja": lang_label.text = tr("ui_lang_japanese")
	
	# 볼륨 게이지 업데이트
	music_gauge.value = SettingsManager.music_volume
	sound_gauge.value = SettingsManager.sound_volume

# --- 버튼 신호 처리 ---

func _on_mode_prev_pressed() -> void:
	SettingsManager.display_mode = posmod(SettingsManager.display_mode - 1, 3)
	SettingsManager.apply_display_settings()
	SettingsManager.save_settings()
	update_ui()

func _on_mode_next_pressed() -> void:
	SettingsManager.display_mode = posmod(SettingsManager.display_mode + 1, 3)
	SettingsManager.apply_display_settings()
	SettingsManager.save_settings()
	update_ui()

func _on_res_prev_pressed() -> void:
	if SettingsManager.display_mode != 2: return
	SettingsManager.resolution_index = posmod(SettingsManager.resolution_index - 1, 3)
	SettingsManager.apply_display_settings()
	SettingsManager.save_settings()
	update_ui()

func _on_res_next_pressed() -> void:
	if SettingsManager.display_mode != 2: return
	SettingsManager.resolution_index = posmod(SettingsManager.resolution_index + 1, 3)
	SettingsManager.apply_display_settings()
	SettingsManager.save_settings()
	update_ui()

func _on_vsync_toggle_pressed() -> void:
	SettingsManager.vsync_enabled = !SettingsManager.vsync_enabled
	SettingsManager.apply_display_settings()
	SettingsManager.save_settings()
	update_ui()

func _on_lang_toggle_pressed() -> void:
	var next_lang = "en"
	match SettingsManager.current_language:
		"en": next_lang = "ko"
		"ko": next_lang = "ja"
		"ja": next_lang = "en"
	
	SettingsManager.set_language(next_lang)
	SettingsManager.save_settings()
	update_ui()
	_setup_tooltips()
	
	if get_tree().current_scene.has_method("update_translations"):
		get_tree().current_scene.update_translations()

func _on_music_down_pressed() -> void:
	SettingsManager.music_volume = clamp(SettingsManager.music_volume - 10, 0, 100)
	SettingsManager.set_volume("Master", SettingsManager.music_volume)
	SettingsManager.save_settings()
	update_ui()

func _on_music_up_pressed() -> void:
	SettingsManager.music_volume = clamp(SettingsManager.music_volume + 10, 0, 100)
	SettingsManager.set_volume("Master", SettingsManager.music_volume)
	SettingsManager.save_settings()
	update_ui()

func _on_sound_down_pressed() -> void:
	SettingsManager.sound_volume = clamp(SettingsManager.sound_volume - 10, 0, 100)
	SettingsManager.save_settings()
	update_ui()

func _on_sound_up_pressed() -> void:
	SettingsManager.sound_volume = clamp(SettingsManager.sound_volume + 10, 0, 100)
	SettingsManager.save_settings()
	update_ui()

func _on_back_button_pressed() -> void:
	queue_free()
