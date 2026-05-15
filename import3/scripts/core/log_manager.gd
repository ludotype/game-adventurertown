extends Node

## LogManager: 인게임 로그 메시지를 관리하고 브로드캐스트합니다.

signal message_posted(text: String, type: String)

enum Type { INFO, WARN, ERROR, SYSTEM }

## 메시지를 게시합니다. 에디터 콘솔(print)과 인게임 UI에 동시에 출력합니다.
func post(text: String, type: String = "INFO") -> void:
	var timestamp = Time.get_time_string_from_system()
	var formatted_text = "[%s] %s" % [timestamp, text]
	
	# 1. 에디터 콘솔에 출력 (시스템 오류와 일반 로그 분리)
	if type == "ERROR":
		printerr(formatted_text)
	else:
		print(formatted_text)
	
	# 2. 인게임 UI를 위한 신호 발생 (타임스탬프 포함된 텍스트 전달)
	message_posted.emit(formatted_text, type)

# 편의용 함수들
func info(text: String) -> void: post(text, "INFO")
func warn(text: String) -> void: post(text, "WARN")
func warning(text: String) -> void: warn(text) # Alias 추가
func error(text: String) -> void: post(text, "ERROR")
func system(text: String) -> void: post(text, "SYSTEM")
