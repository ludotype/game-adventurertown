extends Node

## SettingsManager: 게임 설정을 관리하고 파일(user://settings.cfg)에 영구 저장합니다.

const SETTINGS_FILE = "user://settings.cfg"

# 설정 값 저장 변수
var display_mode: int = 0
var resolution_index: int = 2
var vsync_enabled: bool = true
var music_volume: float = 80.0
var sound_volume: float = 80.0
var current_language: String = "en"

const RESOLUTIONS = [
	Vector2i(1280, 720),
	Vector2i(1706, 960),
	Vector2i(1920, 1080)
]

func _ready() -> void:
	# 1. 파일에서 설정 불러오기 (실패 시 기본값 유지)
	load_settings()
	
	# 2. 초기 설정 적용
	apply_display_settings()
	set_language(current_language)
	set_volume("Master", music_volume) # 초기 볼륨 적용

## 현재 설정을 파일에 저장합니다.
func save_settings() -> void:
	var config = ConfigFile.new()
	
	config.set_value("video", "display_mode", display_mode)
	config.set_value("video", "resolution_index", resolution_index)
	config.set_value("video", "vsync_enabled", vsync_enabled)
	
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sound_volume", sound_volume)
	
	config.set_value("system", "language", current_language)
	
	var err = config.save(SETTINGS_FILE)
	if err != OK:
		printerr("[SettingsManager] 설정 저장 실패: ", err)
	else:
		print("[SettingsManager] 설정 저장 완료.")

## 파일에서 설정을 읽어옵니다.
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	
	if err != OK:
		print("[SettingsManager] 저장된 설정 파일이 없습니다. 기본값을 사용합니다.")
		return
		
	display_mode = config.get_value("video", "display_mode", display_mode)
	resolution_index = config.get_value("video", "resolution_index", resolution_index)
	vsync_enabled = config.get_value("video", "vsync_enabled", vsync_enabled)
	
	music_volume = config.get_value("audio", "music_volume", music_volume)
	sound_volume = config.get_value("audio", "sound_volume", sound_volume)
	
	current_language = config.get_value("system", "language", current_language)
	print("[SettingsManager] 설정 로드 완료: ", current_language)

func apply_display_settings() -> void:
	if vsync_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		Engine.max_fps = 0
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 60
	
	match display_mode:
		0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		2: 
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(RESOLUTIONS[resolution_index])
			# 명시적으로 float 연산 후 Vector2i로 변환하여 경고 원천 차단
			var screen_size: Vector2i = DisplayServer.screen_get_size()
			var window_size: Vector2i = DisplayServer.window_get_size()
			var diff: Vector2 = Vector2(screen_size - window_size)
			DisplayServer.window_set_position(Vector2i(diff / 2.0))

func set_volume(bus_name: String, value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		var db = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(bus_index, db)
		AudioServer.set_bus_mute(bus_index, value <= 0)

func set_language(locale: String) -> void:
	current_language = locale
	TranslationServer.set_locale(locale)
