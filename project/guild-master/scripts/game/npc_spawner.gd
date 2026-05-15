extends Node

## NPCSpawner
## 장소 입장 시 등장할 NPC를 가중치 기반으로 추첨합니다.
## empty_weight를 포함한 총합 대비 개별 가중치 확률로 동작합니다.

signal npc_spawned(npc_data: Dictionary)
signal empty_spawned()

@export var place_id: String = ""


func spawn(current_time: String = "morning", story_flags: Array = []) -> void:
	if place_id.is_empty():
		push_error("NPCSpawner: place_id is not set")
		return

	if not PlaceRegistry.has_place(place_id):
		push_error("NPCSpawner: unknown place_id: " + place_id)
		return

	var place_data := PlaceRegistry.get_place(place_id)
	var empty_weight: int = place_data.get("empty_weight", 0)

	# 1. 필터링: 현재 시간과 플래그에 맞는 후보 수집
	var all_entries := ScheduleRegistry.get_entries_for_place(place_id)
	var candidates: Array = []
	var total_weight: int = empty_weight

	for entry in all_entries:
		if entry.matches(current_time, story_flags):
			candidates.append(entry)
			total_weight += entry.weight

	# 2. 추첨
	if total_weight <= 0:
		empty_spawned.emit()
		return

	var roll := randf() * float(total_weight)
	var cumulative := 0.0

	# empty_weight 구간 검사
	cumulative += float(empty_weight)
	if roll <= cumulative:
		empty_spawned.emit()
		return

	# NPC 후보 순회
	for entry in candidates:
		cumulative += float(entry.weight)
		if roll <= cumulative:
			var npc_data := {
				"npc_id": entry.npc_id,
				"display_name": entry.display_name,
				"portrait_path": entry.portrait_path,
				"place_id": entry.place_id,
				"weight": entry.weight,
				"probability": float(entry.weight) / float(total_weight)
			}
			npc_spawned.emit(npc_data)
			return

	# 이론상 도달하지 않지만 안전장치
	empty_spawned.emit()


## 디버그용: 현재 장소의 확률 표를 반환
func get_probability_table(current_time: String = "morning", story_flags: Array = []) -> Dictionary:
	if place_id.is_empty() or not PlaceRegistry.has_place(place_id):
		return {}

	var place_data := PlaceRegistry.get_place(place_id)
	var empty_weight: int = place_data.get("empty_weight", 0)
	var all_entries := ScheduleRegistry.get_entries_for_place(place_id)
	var candidates: Array = []
	var total_weight: int = empty_weight

	for entry in all_entries:
		if entry.matches(current_time, story_flags):
			candidates.append(entry)
			total_weight += entry.weight

	var result := {
		"place_id": place_id,
		"total_weight": total_weight,
		"entries": []
	}

	# 아무도 없음 항목
	result["entries"].append({
		"npc_id": "",
		"display_name": "(아무도 없음)",
		"weight": empty_weight,
		"probability": float(empty_weight) / float(total_weight) if total_weight > 0 else 0.0
	})

	for entry in candidates:
		result["entries"].append({
			"npc_id": entry.npc_id,
			"display_name": entry.display_name,
			"weight": entry.weight,
			"probability": float(entry.weight) / float(total_weight)
		})

	return result
