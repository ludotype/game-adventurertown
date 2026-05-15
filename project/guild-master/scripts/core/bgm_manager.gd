extends Node

## BGMManager: 게임의 배경음악을 관리합니다.
## 인스펙터에서 BGM 트랙을 자유롭게 추가/제거/할당할 수 있습니다.

## BGM 트랙 정의 - 인스펙터에서 자유롭게 추가/수정/제거
@export_group("BGM Tracks")
@export var bgm_title: AudioStream  ## 타이틀/메뉴 화면용 BGM
@export var bgm_exploration: AudioStream  ## 탐색/기본 플레이용 BGM
@export var bgm_event: AudioStream  ## 이벤트/특수 장면용 BGM
@export var bgm_emotional: AudioStream  ## 감정/로맨스용 BGM
@export var bgm_tension: AudioStream  ## 긴장/위기용 BGM

# 현재 상태 추적
var _current_bgm: AudioStream = null
var _bgm_stack: Array[AudioStream] = []

func _ready() -> void:
	# 초기 BGM 재생 (타이틀)
	if bgm_title:
		play_bgm(bgm_title)


# ============================================================================
# PUBLIC API
# ============================================================================

## BGM을 즉시 재생합니다
func play_bgm(stream: AudioStream) -> void:
	if stream == _current_bgm:
		return
	_current_bgm = stream
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_music"):
		am.play_music(stream, 0.5)


## 현재 BGM을 스택에 저장하고 새 BGM 재생
func push_bgm(stream: AudioStream) -> void:
	if _current_bgm:
		_bgm_stack.append(_current_bgm)
	play_bgm(stream)


## 스택에서 이전 BGM 복원
func pop_bgm() -> void:
	if _bgm_stack.size() > 0:
		play_bgm(_bgm_stack.pop_back())


## BGM 이름으로 재생
func play_bgm_by_name(track_name: String) -> void:
	var track = _get_bgm_by_name(track_name)
	if track:
		play_bgm(track)


## 이름으로 BGM 스택에 저장하고 재생 (Dialogue용)
## Dialogue: do BGMManager.push_bgm_by_name("bgm_emotional")
func push_bgm_by_name(track_name: String) -> void:
	var track = _get_bgm_by_name(track_name)
	if track:
		push_bgm(track)


## 모든 BGM 스택 클리어
## Dialogue: do BGMManager.clear_bgm_stack()
func clear_bgm_stack() -> void:
	_bgm_stack.clear()


## 사용 가능한 BGM 트랙 이름 목록 반환
func get_available_tracks() -> PackedStringArray:
	var tracks: PackedStringArray = []
	if bgm_title: tracks.append("bgm_title")
	if bgm_exploration: tracks.append("bgm_exploration")
	if bgm_event: tracks.append("bgm_event")
	if bgm_emotional: tracks.append("bgm_emotional")
	if bgm_tension: tracks.append("bgm_tension")
	return tracks


## 이름으로 BGM 트랙을 찾습니다
func _get_bgm_by_name(track_name: String) -> AudioStream:
	match track_name:
		"bgm_title": return bgm_title
		"bgm_exploration": return bgm_exploration
		"bgm_event": return bgm_event
		"bgm_emotional": return bgm_emotional
		"bgm_tension": return bgm_tension
		_:
			if track_name in self:
				var value = get(track_name)
				if value is AudioStream:
					return value
			return null
