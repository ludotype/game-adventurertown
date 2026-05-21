class_name AtmosphereDescriber

## 매 턴(장소 진입/시간 경과)마다 동적으로 정경 텍스트를 조합합니다.
## 구성: [장소 묘사] [이벤트] / [플레이어 상태] / [NPC 묘사]

static func describe(context: Dictionary) -> String:
	var paragraphs: Array[String] = []

	# 1. 장소 묘사 (시간대별 오버라이드 지원)
	var place_data: Dictionary = context.get("place_data", {})
	var time_of_day: String = context.get("time_of_day", "")
	var place_text := _get_place_description(place_data, time_of_day)
	if not place_text.is_empty():
		paragraphs.append(place_text)

	# 2. 글로벌 이벤트/상태 묘사
	var event_text := _get_global_event_text(context)
	if not event_text.is_empty():
		paragraphs.append(event_text)

	# 3. 플레이어 상태 묘사
	var player_text := _get_player_status_text(context.get("player_metrics", {}))
	if not player_text.is_empty():
		paragraphs.append(player_text)

	# 4. NPC 묘사 (메인 + 서브)
	var main_npc: Dictionary = context.get("main_npc", {})
	var sub_npcs: Array = context.get("sub_npcs", [])
	var npc_lines := _get_npc_lines(main_npc, sub_npcs)
	if not npc_lines.is_empty():
		paragraphs.append("\n".join(npc_lines))

	return "\n\n".join(paragraphs)


static func _get_place_description(place_data: Dictionary, time_of_day: String) -> String:
	var descriptions: Dictionary = place_data.get("descriptions", {})
	if not time_of_day.is_empty() and descriptions.has(time_of_day):
		return descriptions[time_of_day]
	return place_data.get("description", "")


static func _get_global_event_text(context: Dictionary) -> String:
	var lines: Array[String] = []

	# CrisisManager에서 활성화된 이벤트 텍스트가 있다면 추가
	if context.has("crisis_events"):
		var events: Array = context["crisis_events"]
		for ev in events:
			if typeof(ev) == TYPE_DICTIONARY:
				var desc := String(ev.get("atmosphere_text", ""))
				if not desc.is_empty():
					lines.append(desc)

	return " ".join(lines)


static func _get_player_status_text(metrics: Dictionary) -> String:
	var lines: Array[String] = []

	var hp: int = _get_metric(metrics, ["player.hp", "player.health"], 100)
	var sanity: int = _get_metric(metrics, ["player.sanity", "player.san", "player.mental"], 100)
	var stamina: int = _get_metric(metrics, ["player.stamina", "player.energy", "player.vigor"], 100)
	var hunger: int = _get_metric(metrics, ["player.hunger", "player.satiation"], 50)

	if hp <= 20:
		lines.append("You are barely clinging to consciousness.")
	elif hp <= 40:
		lines.append("You are seriously injured.")
	elif hp <= 60:
		lines.append("You are hurt.")

	if sanity <= 20:
		lines.append("Whispers claw at the edge of your mind.")
	elif sanity <= 40:
		lines.append("You feel your grip on reality slipping.")
	elif sanity <= 60:
		lines.append("A nameless dread gnaws at you.")

	if stamina <= 20:
		lines.append("Exhaustion weighs down every limb.")
	elif stamina <= 40:
		lines.append("You are tired.")

	# hunger 메트릭이 낮을수록 배고픔 (0 = starving)
	if hunger <= 10:
		lines.append("You are starving.")
	elif hunger <= 30:
		lines.append("You are hungry.")
	elif hunger >= 90:
		lines.append("You are completely full.")

	return "\n".join(lines)


static func _get_npc_lines(main_npc: Dictionary, sub_npcs: Array) -> Array[String]:
	var lines: Array[String] = []

	if not main_npc.is_empty():
		var name := String(main_npc.get("display_name", main_npc.get("npc_id", "Someone")))
		var greeting := String(main_npc.get("greeting", ""))
		if greeting.is_empty():
			lines.append(name + " is here.")
		else:
			lines.append(name + " " + greeting)

	for raw in sub_npcs:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var sub: Dictionary = raw
		var sub_name := String(sub.get("display_name", sub.get("npc_id", "Someone")))
		var sub_desc := String(sub.get("description", "is here."))
		lines.append(sub_name + " " + sub_desc)

	return lines


static func _get_metric(metrics: Dictionary, keys: Array[String], default_value: int) -> int:
	for key in keys:
		if metrics.has(key):
			var val = metrics[key]
			if typeof(val) == TYPE_INT or typeof(val) == TYPE_FLOAT:
				return int(val)
	return default_value
