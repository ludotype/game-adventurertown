
class_name Nickname

static var nickname_dict = {}

static func set_nickname(name, nickname):
	nickname_dict[name] = nickname

static func get_nickname(name):
	var raw_nickname = nickname_dict.get(name, "")
	# 번역 서버를 거쳐 현재 언어에 맞는 이름을 반환합니다.
	return TranslationServer.translate(raw_nickname)
