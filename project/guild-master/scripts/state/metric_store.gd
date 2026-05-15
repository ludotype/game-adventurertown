extends Node

## MetricStore
## NPC, 장소, 플레이어, 전역 상태의 숫자 값을 key 기반으로 저장합니다.
## 예: npc.elena.affection, npc.luise.mood, place.tavern.clean_count, player.music

signal metric_changed(key: String, value)

var _metrics: Dictionary = {}


func get_metric(key: String, default_value = 0):
	if key.is_empty():
		push_warning("MetricStore: empty metric key")
		return default_value
	return _metrics.get(key, default_value)


func set_metric(key: String, value) -> void:
	if key.is_empty():
		push_warning("MetricStore: empty metric key")
		return

	_metrics[key] = value
	metric_changed.emit(key, value)


func change_metric(key: String, amount) -> void:
	if key.is_empty():
		push_warning("MetricStore: empty metric key")
		return

	var current = get_metric(key, 0)
	var next_value = current + amount
	set_metric(key, next_value)


func has_metric(key: String) -> bool:
	return _metrics.has(key)


func clear_metrics() -> void:
	_metrics.clear()


func get_all_metrics() -> Dictionary:
	return _metrics.duplicate(true)
