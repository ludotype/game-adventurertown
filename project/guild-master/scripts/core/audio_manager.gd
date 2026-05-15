extends Node

## AudioManager: 실제 오디오 재생과 페이드 처리를 담당하는 로우 레벨 매니저.

var _player1: AudioStreamPlayer
var _player2: AudioStreamPlayer
var _active_player: AudioStreamPlayer
var _tween: Tween

# SFX 재생을 위한 풀
var _sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS: int = 16
var _sfx_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # 일시정지 중에도 음악은 나와야 하니까요.
	
	_player1 = AudioStreamPlayer.new()
	_player2 = AudioStreamPlayer.new()
	
	_player1.bus = "Master"
	_player2.bus = "Master"
	
	add_child(_player1)
	add_child(_player2)
	
	_active_player = _player1
	
	# SFX 플레이어 풀 초기화
	for i in range(MAX_SFX_PLAYERS):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = "SFX"
		add_child(sfx_player)
		_sfx_players.append(sfx_player)

## 새로운 곡을 재생합니다. (기존 곡 페이드 아웃 후 새 곡 시작)
func play_music(stream: AudioStream, fade_time: float = 1.0) -> void:
	if not stream:
		stop_all(fade_time)
		return
		
	if _active_player.stream == stream and _active_player.playing:
		return # 이미 같은 곡이 재생 중이면 무시합니다.
		
	var next_player = _player2 if _active_player == _player1 else _player1
	
	# 트윈 초기화
	if _tween: _tween.kill()
	_tween = create_tween().set_parallel(true)
	
	# 1. 현재 플레이어 페이드 아웃 및 정지
	_tween.tween_property(_active_player, "volume_db", -80.0, fade_time)
	
	# 2. 새 플레이어 설정 (미리 로드만 해두고, 페이드 아웃이 어느 정도 진행된 후 재생 시작)
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	next_player.stream = stream
	next_player.volume_db = -80.0
	
	# 교차 시점을 살짝 겹치게 하여 끊김 방지 (fade_time의 절반 시점에 시작)
	_tween.chain().tween_callback(next_player.play)
	_tween.tween_property(next_player, "volume_db", 0.0, fade_time)
	_tween.chain().tween_callback(_active_player.stop)
	
	_active_player = next_player

## 모든 음악을 정지합니다.
func stop_all(fade_time: float = 1.5) -> void:
	if _tween: _tween.kill()
	_tween = create_tween().set_parallel(true)
	
	_tween.tween_property(_player1, "volume_db", -80.0, fade_time)
	_tween.tween_property(_player2, "volume_db", -80.0, fade_time)
	_tween.chain().tween_callback(_player1.stop)
	_tween.chain().tween_callback(_player2.stop)

func is_playing() -> bool:
	return _player1.playing or _player2.playing

## SFX를 재생합니다. (파일 경로 또는 AudioStream)
func play_sfx(sfx_name_or_stream: Variant, volume_db: float = 0.0) -> void:
	var stream: AudioStream = null
	
	# 문자열이면 경로로 간주하여 로드
	if sfx_name_or_stream is String:
		var sfx_path = sfx_name_or_stream
		
		# 캐시 확인
		if _sfx_cache.has(sfx_path):
			stream = _sfx_cache[sfx_path]
		else:
			# 경로에서 로드 시도 (여러 확장자 지원)
			var possible_paths = [
				"res://assets/sounds/%s.wav" % sfx_path,
				"res://assets/sounds/%s.ogg" % sfx_path,
				"res://assets/sounds/%s.mp3" % sfx_path,
				"res://audio/ui/%s.wav" % sfx_path,
				"res://audio/ui/%s.ogg" % sfx_path,
				sfx_path  # 직접 경로일 수도 있음
			]
			
			for path in possible_paths:
				if ResourceLoader.exists(path):
					stream = load(path)
					_sfx_cache[sfx_path] = stream
					break
			
			if not stream:
				push_error("AudioManager: SFX 파일을 찾을 수 없습니다: %s" % sfx_path)
				return
	elif sfx_name_or_stream is AudioStream:
		stream = sfx_name_or_stream
	else:
		push_error("AudioManager: play_sfx는 문자열(경로) 또는 AudioStream만 받을 수 있습니다.")
		return
	
	# 사용 가능한 플레이어 찾기
	var available_player: AudioStreamPlayer = null
	for player in _sfx_players:
		if not player.playing:
			available_player = player
			break
	
	# 모든 플레이어가 사용 중이면 가장 오래된 것 중단
	if not available_player:
		available_player = _sfx_players[0]
		available_player.stop()
	
	# 재생
	available_player.stream = stream
	available_player.volume_db = volume_db
	available_player.play()
