extends Control

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var lang_label: Label = %LangLabel

func _ready() -> void:
	# 로드 직후 즉시 페이드 인 연출 시작
	_start_fade_in()

	# BGM은 BGMManager에서 자동으로 관리됩니다
	# (인스펙터에서 BGMManager의 bgm_title에 할당)

	# 애니메이션 시작 (안전하게 라이브러리 내 이름 확인 후 재생)
	if animation_player and animation_player.has_animation("float"):
		animation_player.play("float")
	elif animation_player and animation_player.has_animation("main/float"):
		animation_player.play("main/float")

	update_translations()

## 언어 변경 시 UI 텍스트를 즉시 갱신합니다.
func update_translations() -> void:
	start_button.text = tr("UI_START")
	continue_button.text = tr("UI_CONTINUE")
	settings_button.text = tr("UI_SETTINGS")
	quit_button.text = tr("UI_QUIT")
	
	# 퀵 셀렉터 텍스트 업데이트
	match SettingsManager.current_language:
		"en": lang_label.text = tr("ui_lang_english")
		"ko": lang_label.text = tr("ui_lang_korean")
		"ja": lang_label.text = tr("ui_lang_japanese")

func _on_start_button_pressed() -> void:
	# 새 게임 시작
	get_tree().change_scene_to_file("res://scenes/gameplay/game_scene.tscn")

func _on_continue_button_pressed() -> void:
	var save_screen = load("res://scenes/ui/save_load_screen.tscn").instantiate()
	add_child(save_screen)

func _on_settings_button_pressed() -> void:
	var settings_scene = load("res://scenes/ui/settings_screen.tscn").instantiate()
	add_child(settings_scene)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_lang_toggle_pressed() -> void:
	var next_lang = "en"
	match SettingsManager.current_language:
		"en": next_lang = "ko"
		"ko": next_lang = "ja"
		"ja": next_lang = "en"
	
	SettingsManager.set_language(next_lang)
	SettingsManager.save_settings() # 저장 추가!
	update_translations()

func _start_fade_in() -> void:
	var fade_overlay = get_node_or_null("FadeOverlay")
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0
		var tween = create_tween()
		tween.tween_property(fade_overlay, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		fade_overlay.visible = false
