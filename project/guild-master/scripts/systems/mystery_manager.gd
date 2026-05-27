extends Node

## MysteryManager
## 활성 미스터리 상태 관리, 단계 진행 체크, 해결 처리를 담당합니다.

signal mystery_activated(mystery_id: String, mystery_data: Dictionary)
signal mystery_phase_advanced(mystery_id: String, phase_id: String, phase_index: int)
signal mystery_resolved(mystery_id: String, mystery_data: Dictionary)
signal mystery_doomed(mystery_id: String, reason: String)
signal dungeon_unlocked(dungeon_id: String, mystery_id: String)
signal dungeon_sealed(dungeon_id: String, mystery_id: String)
signal case_unlocked(case_id: String)
signal case_resolved(case_id: String)

var _active_mysteries: Dictionary = {}  # mystery_id -> { current_phase_index: int, data: Dictionary, days_active: int }
var _active_cases: Dictionary = {}  # case_id -> { current_mystery_index: int, mysteries: Array }
var _unlocked_dungeons: Dictionary = {}  # dungeon_id -> mystery_id
var _sealed_dungeons: Array = []
var _escalation_timers: Dictionary = {}  # mystery_id -> { warning_triggered: bool, days_active: int }


func _ready() -> void:
	_reset_state()
	if has_node("/root/TimeSystem"):
		TimeSystem.day_started.connect(_on_day_started)

	# Case 1 자동 활성화 (신규 게임 시작 시 1회)
	if not Flags.get_flag("case.case_01.active", false) and not Flags.get_flag("case.case_01.resolved", false):
		activate_case("case_01")


func _on_day_started(day: int) -> void:
	_check_escalations()
	_check_case_activations()


func reset_state() -> void:
	_active_mysteries.clear()
	_active_cases.clear()
	_unlocked_dungeons.clear()
	_sealed_dungeons.clear()
	_escalation_timers.clear()


func _reset_state() -> void:
	reset_state()


func _emit_log(message: String) -> void:
	if has_node("/root/ActionRunner"):
		ActionRunner.log_emitted.emit(message, {})


# -----------------------------------------------------------------------------
# Case 관리
# -----------------------------------------------------------------------------

func activate_case(case_id: String) -> bool:
	if _active_cases.has(case_id):
		return false

	var case_data: Dictionary = MysteryRegistry.get_case(case_id)
	var mysteries: Array = MysteryRegistry.get_mysteries_for_case(case_id)
	if mysteries.is_empty():
		push_warning("MysteryManager: no mysteries found for case " + case_id)
		return false

	# pending queue 구성: 아직 활성화되지 않은 mystery_id 목록
	var pending: Array = []
	for m in mysteries:
		pending.append(m["mystery_id"])

	_active_cases[case_id] = {
		"mysteries": mysteries,
		"pending_mysteries": pending,
		"days_since_opened": 0,
		"activation_params": case_data.get("activation", {})
	}

	Flags.set_flag("case." + case_id + ".active", true)
	case_unlocked.emit(case_id)
	_emit_log("Activated case " + case_id)

	# Case의 첫 번째 Mystery 즉시 활성화
	var first_mystery_id: String = pending[0]
	_activate_mystery(first_mystery_id)
	_remove_from_pending(case_id, first_mystery_id)
	return true


func get_active_case_id() -> String:
	for case_id in _active_cases.keys():
		var case_state: Dictionary = _active_cases[case_id]
		var pending: Array = case_state.get("pending_mysteries", [])
		var active_count: int = _count_active_mysteries_in_case(case_id)
		if not pending.is_empty() or active_count > 0:
			return case_id
	return ""


func get_case_progress(case_id: String) -> Dictionary:
	if not _active_cases.has(case_id):
		return { "resolved": false, "active_count": 0, "pending_count": 0, "total_mysteries": 0 }

	var case_state: Dictionary = _active_cases[case_id]
	var mysteries: Array = case_state["mysteries"]
	var pending: Array = case_state.get("pending_mysteries", [])
	var active_count: int = _count_active_mysteries_in_case(case_id)
	var resolved_count: int = mysteries.size() - pending.size() - active_count
	return {
		"resolved": pending.is_empty() and active_count == 0,
		"active_count": active_count,
		"pending_count": pending.size(),
		"resolved_count": resolved_count,
		"total_mysteries": mysteries.size()
	}


func _advance_case(case_id: String) -> void:
	if not _active_cases.has(case_id):
		return

	var case_state: Dictionary = _active_cases[case_id]
	var pending: Array = case_state.get("pending_mysteries", [])

	if pending.is_empty():
		# Case 전체 클리어
		Flags.set_flag("case." + case_id + ".active", false)
		Flags.set_flag("case." + case_id + ".resolved", true)
		case_resolved.emit(case_id)
		_emit_log("Case " + case_id + " resolved!")
		_advance_to_next_case(case_id)
	else:
		# Mystery 해결 시 보너스 확률로 다음 pending mystery 즉시 시도
		_try_activate_next_pending(case_id, 0.25)


func _advance_to_next_case(prev_case_id: String) -> void:
	# Case ID 패턴: case_01 -> case_02
	var parts := prev_case_id.split("_")
	if parts.size() >= 2:
		var num: int = int(parts[-1])
		var next_case_id := "case_" + str(num + 1).pad_zeros(2)
		activate_case(next_case_id)


# -----------------------------------------------------------------------------
# Mystery 관리
# -----------------------------------------------------------------------------

func _activate_mystery(mystery_id: String) -> bool:
	var data: Dictionary = MysteryRegistry.get_mystery(mystery_id)
	if data.is_empty():
		push_warning("MysteryManager: unknown mystery_id: " + mystery_id)
		return false
	if _active_mysteries.has(mystery_id):
		return false

	_active_mysteries[mystery_id] = {
		"current_phase_index": 0,
		"data": data,
		"days_active": 0
	}
	_escalation_timers[mystery_id] = {
		"warning_triggered": false,
		"days_active": 0
	}

	Flags.set_flag("mystery." + mystery_id + ".active", true)
	mystery_activated.emit(mystery_id, data)
	_emit_log("Activated mystery: " + data.get("display_name", mystery_id))

	# 연동 Crisis가 있으면 CrisisManager에 위임 (Crisis는 별도로 발생해야 함)
	var linked_crisis_id: String = data.get("linked_crisis_id", "")
	if not linked_crisis_id.is_empty() and has_node("/root/CrisisManager"):
		if not CrisisManager.is_crisis_active(linked_crisis_id):
			# Crisis가 아직 활성화되지 않았다면, CrisisRegistry에서 찾아서 수동 활성화
			var crisis_data: Dictionary = CrisisRegistry.get_crisis(linked_crisis_id)
			if not crisis_data.is_empty() and CrisisManager.has_method("activate_crisis_by_data"):
				CrisisManager.activate_crisis_by_data(crisis_data)

	return true


func get_active_mystery() -> Dictionary:
	for mystery_id in _active_mysteries.keys():
		var state: Dictionary = _active_mysteries[mystery_id]
		var resolved: bool = Flags.get_flag("mystery." + mystery_id + ".resolved", false)
		if not resolved:
			return state["data"]
	return {}


func get_active_mystery_id() -> String:
	for mystery_id in _active_mysteries.keys():
		var resolved: bool = Flags.get_flag("mystery." + mystery_id + ".resolved", false)
		if not resolved:
			return mystery_id
	return ""


func is_mystery_active(mystery_id: String) -> bool:
	return _active_mysteries.has(mystery_id) and not Flags.get_flag("mystery." + mystery_id + ".resolved", false)


func is_mystery_resolved(mystery_id: String) -> bool:
	return Flags.get_flag("mystery." + mystery_id + ".resolved", false)


func get_mystery_current_phase(mystery_id: String) -> int:
	if not _active_mysteries.has(mystery_id):
		return -1
	return _active_mysteries[mystery_id]["current_phase_index"]


# -----------------------------------------------------------------------------
# 단계 진행 (Phase Advancement)
# -----------------------------------------------------------------------------

func advance_mystery_phase(mystery_id: String, context: Dictionary = {}) -> bool:
	if not _active_mysteries.has(mystery_id):
		push_warning("MysteryManager: cannot advance phase for inactive mystery: " + mystery_id)
		return false

	var state: Dictionary = _active_mysteries[mystery_id]
	var data: Dictionary = state["data"]
	var phases: Array = data.get("phases", [])
	var current_idx: int = state["current_phase_index"]

	if current_idx >= phases.size():
		return false

	var phase: Dictionary = phases[current_idx]
	var phase_id: String = phase.get("phase_id", "")

	# 단계 완료 보상 실행
	var rewards: Array = phase.get("rewards_on_phase_complete", [])
	for action in rewards:
		ActionRunner.run(action, context)

	state["current_phase_index"] += 1
	mystery_phase_advanced.emit(mystery_id, phase_id, state["current_phase_index"])
	_emit_log("Mystery " + mystery_id + " advanced to phase " + str(state["current_phase_index"]))

	# 던전 해금 체크
	var objective: Dictionary = phase.get("objective", {})
	if objective.get("type", "") == "dungeon_clear" or objective.has("dungeon_id"):
		var dungeon_id: String = objective.get("dungeon_id", "")
		if not dungeon_id.is_empty():
			_unlock_dungeon(dungeon_id, mystery_id)

	# 모든 단계 완료 시 자동 해결
	if state["current_phase_index"] >= phases.size():
		_resolve_mystery(mystery_id, context)

	return true


func unlock_dungeon(dungeon_id: String, mystery_id: String) -> void:
	"""Public wrapper for _unlock_dungeon."""
	_unlock_dungeon(dungeon_id, mystery_id)


func _unlock_dungeon(dungeon_id: String, mystery_id: String) -> void:
	if dungeon_id.is_empty():
		return
	if _sealed_dungeons.has(dungeon_id):
		return
	_unlocked_dungeons[dungeon_id] = mystery_id
	dungeon_unlocked.emit(dungeon_id, mystery_id)
	Flags.set_flag("dungeon." + dungeon_id + ".unlocked", true)
	_emit_log("Dungeon unlocked: " + dungeon_id)


func seal_dungeon(dungeon_id: String) -> void:
	if dungeon_id.is_empty():
		return
	if _unlocked_dungeons.has(dungeon_id):
		_unlocked_dungeons.erase(dungeon_id)
	if not _sealed_dungeons.has(dungeon_id):
		_sealed_dungeons.append(dungeon_id)
	Flags.set_flag("dungeon." + dungeon_id + ".sealed", true)
	Flags.set_flag("dungeon." + dungeon_id + ".unlocked", false)
	dungeon_sealed.emit(dungeon_id, "")
	_emit_log("Dungeon sealed: " + dungeon_id)


func is_dungeon_unlocked(dungeon_id: String) -> bool:
	return _unlocked_dungeons.has(dungeon_id)


func is_dungeon_sealed(dungeon_id: String) -> bool:
	return _sealed_dungeons.has(dungeon_id)


# -----------------------------------------------------------------------------
# Mystery 해결 (Resolution)
# -----------------------------------------------------------------------------

func try_resolve_mystery(mystery_id: String, context: Dictionary = {}) -> bool:
	if not _active_mysteries.has(mystery_id):
		return false
	var state: Dictionary = _active_mysteries[mystery_id]
	var data: Dictionary = state["data"]
	var phases: Array = data.get("phases", [])
	var current_idx: int = state["current_phase_index"]

	# 모든 phase를 완료했는지 확인
	if current_idx < phases.size():
		return false

	_resolve_mystery(mystery_id, context)
	return true


func _resolve_mystery(mystery_id: String, context: Dictionary = {}) -> void:
	var state: Dictionary = _active_mysteries[mystery_id]
	var data: Dictionary = state["data"]

	Flags.set_flag("mystery." + mystery_id + ".active", false)
	Flags.set_flag("mystery." + mystery_id + ".resolved", true)

	# on_resolve 액션 실행
	var on_resolve: Dictionary = data.get("on_resolve", {})
	var actions: Array = on_resolve.get("actions", [])
	for action in actions:
		ActionRunner.run(action, context)

	# 둠 감소
	if has_node("/root/CrisisManager"):
		CrisisManager.change_doom(-1)

	mystery_resolved.emit(mystery_id, data)
	_emit_log("Mystery resolved: " + data.get("display_name", mystery_id))

	# 연동 Crisis 해제
	var linked_crisis_id: String = data.get("linked_crisis_id", "")
	if not linked_crisis_id.is_empty() and has_node("/root/CrisisManager"):
		CrisisManager.try_resolve_crisis(linked_crisis_id)

	# 던전 봉인
	for phase in data.get("phases", []):
		var obj: Dictionary = phase.get("objective", {})
		var dungeon_id: String = obj.get("dungeon_id", "")
		if not dungeon_id.is_empty():
			seal_dungeon(dungeon_id)

	# Case 진행
	var linked_case_id: String = data.get("linked_case_id", "")
	if not linked_case_id.is_empty():
		_advance_case(linked_case_id)


# -----------------------------------------------------------------------------
# 단서 수집 (Clue Collection) - 조사형 Mystery
# -----------------------------------------------------------------------------

func collect_clue(mystery_id: String, amount: int = 1) -> bool:
	if not is_mystery_active(mystery_id):
		return false

	var data: Dictionary = _active_mysteries[mystery_id]["data"]
	var current_phase_idx: int = _active_mysteries[mystery_id]["current_phase_index"]
	var phases: Array = data.get("phases", [])

	if current_phase_idx >= phases.size():
		return false

	var phase: Dictionary = phases[current_phase_idx]
	var objective: Dictionary = phase.get("objective", {})
	if objective.get("type", "") != "collect_clues":
		return false

	var clue_key := "mystery." + mystery_id + ".clues_collected"
	var current_clues: int = Flags.get_flag(clue_key, 0)
	var needed: int = objective.get("clues_needed", 1)

	current_clues += amount
	Flags.set_flag(clue_key, current_clues)
	_emit_log("Clue collected for " + mystery_id + ": " + str(current_clues) + "/" + str(needed))

	if current_clues >= needed:
		if advance_mystery_phase(mystery_id):
			Flags.set_flag(clue_key, 0)

	return true


# -----------------------------------------------------------------------------
# 정화 진행 (Cleansing) - 정화형 Mystery
# -----------------------------------------------------------------------------

func record_cleanse(mystery_id: String, place_id: String) -> bool:
	if not is_mystery_active(mystery_id):
		return false

	var data: Dictionary = _active_mysteries[mystery_id]["data"]
	var current_phase_idx: int = _active_mysteries[mystery_id]["current_phase_index"]
	var phases: Array = data.get("phases", [])

	if current_phase_idx >= phases.size():
		return false

	var phase: Dictionary = phases[current_phase_idx]
	var objective: Dictionary = phase.get("objective", {})
	if objective.get("type", "") != "cleanse_places":
		return false

	# target_tags 체크: place_id가 해당 태그를 가져야 정화 진행
	var target_tags: Array = objective.get("target_tags", [])
	if not target_tags.is_empty() and not place_id.is_empty():
		var place_data: Dictionary = PlaceRegistry.get_place(place_id)
		var place_tags: Array = place_data.get("tags", []) if not place_data.is_empty() else []
		var has_matching_tag := false
		for tag in place_tags:
			if target_tags.has(tag):
				has_matching_tag = true
				break
		if not has_matching_tag:
			return false

	var cleanse_key := "mystery." + mystery_id + ".cleansed_count"
	var current_cleansed: int = Flags.get_flag(cleanse_key, 0)
	var needed: int = objective.get("cleanse_count", 1)

	current_cleansed += 1
	Flags.set_flag(cleanse_key, current_cleansed)
	_emit_log("Cleansed place for " + mystery_id + ": " + str(current_cleansed) + "/" + str(needed))

	if current_cleansed >= needed:
		if advance_mystery_phase(mystery_id):
			Flags.set_flag(cleanse_key, 0)

	return true


# -----------------------------------------------------------------------------
# 보스 처치 보고 (Boss Defeat) - 처치형 Mystery
# -----------------------------------------------------------------------------

func report_boss_defeated(boss_id: String, dungeon_id: String = "") -> void:
	for mystery_id in _active_mysteries.keys():
		var state: Dictionary = _active_mysteries[mystery_id]
		var data: Dictionary = state["data"]
		var current_phase_idx: int = state["current_phase_index"]
		var phases: Array = data.get("phases", [])

		if current_phase_idx >= phases.size():
			continue

		var phase: Dictionary = phases[current_phase_idx]
		var objective: Dictionary = phase.get("objective", {})
		var obj_type: String = objective.get("type", "")
		var obj_boss: String = objective.get("boss_id", "")
		var obj_dungeon: String = objective.get("dungeon_id", "")

		if obj_type in ["dungeon_clear", "defeat_boss"]:
			if obj_boss == boss_id or (obj_dungeon == dungeon_id and obj_dungeon != ""):
				advance_mystery_phase(mystery_id)
				return


# -----------------------------------------------------------------------------
# 방치 패널티 (Escalation)
# -----------------------------------------------------------------------------

func _check_escalations() -> void:
	for mystery_id in _active_mysteries.keys():
		if is_mystery_resolved(mystery_id):
			continue

		var timer: Dictionary = _escalation_timers.get(mystery_id, { "warning_triggered": false, "days_active": 0 })
		timer["days_active"] += 1
		_escalation_timers[mystery_id] = timer

		var state: Dictionary = _active_mysteries[mystery_id]
		var data: Dictionary = state["data"]
		var escalation: Dictionary = data.get("escalation", {})
		var doom_days: int = escalation.get("doom_if_ignored_days", -1)
		var warning_days: int = escalation.get("warning_days", -1)
		var days_active: int = timer["days_active"]

		# 경고
		if warning_days > 0 and days_active >= warning_days and not timer["warning_triggered"]:
			timer["warning_triggered"] = true
			var warning_dialogue: String = escalation.get("warning_dialogue", "")
			if not warning_dialogue.is_empty():
				ActionRunner.run({ "type": "dialogue", "dialogue_id": warning_dialogue })
			else:
				_emit_log("[WARNING] Mystery " + mystery_id + " is nearing doom threshold!")

		# 파멸
		if doom_days > 0 and days_active >= doom_days:
			_doom_mystery(mystery_id)


func _doom_mystery(mystery_id: String) -> void:
	var state: Dictionary = _active_mysteries[mystery_id]
	var data: Dictionary = state["data"]
	var escalation: Dictionary = data.get("escalation", {})
	var doom_actions: Array = escalation.get("doom_actions", [])

	Flags.set_flag("mystery." + mystery_id + ".active", false)
	Flags.set_flag("mystery." + mystery_id + ".doomed", true)

	for action in doom_actions:
		ActionRunner.run(action)

	if has_node("/root/CrisisManager"):
		CrisisManager.change_doom(3)

	mystery_doomed.emit(mystery_id, data.get("display_name", ""))
	_emit_log("Mystery DOOMED: " + data.get("display_name", mystery_id))

	# 연동 Crisis도 파멸 처리
	var linked_crisis_id: String = data.get("linked_crisis_id", "")
	if not linked_crisis_id.is_empty() and has_node("/root/CrisisManager"):
		if CrisisManager.is_crisis_active(linked_crisis_id):
			CrisisManager.doom_crisis(linked_crisis_id)


# -----------------------------------------------------------------------------
# 확률 기반 Mystery 활성화 (Probability-Based Activation)
# -----------------------------------------------------------------------------

func _check_case_activations() -> void:
	"""매일 호출. 활성 Case의 pending mystery를 확률적으로 활성화합니다."""
	for case_id in _active_cases.keys():
		var case_state: Dictionary = _active_cases[case_id]
		case_state["days_since_opened"] += 1

		var pending: Array = case_state.get("pending_mysteries", [])
		if pending.is_empty():
			continue

		_try_activate_next_pending(case_id, 0.0)


func _try_activate_next_pending(case_id: String, resolve_bonus: float = 0.0) -> void:
	"""pending queue의 첫 번째 mystery를 확률적으로 활성화 시도."""
	var case_state: Dictionary = _active_cases[case_id]
	var pending: Array = case_state.get("pending_mysteries", [])
	if pending.is_empty():
		return

	var probability: float = _calculate_activation_probability(case_id)
	var effective_probability: float = min(probability + resolve_bonus, 1.0)
	var roll: float = randf()

	if roll <= effective_probability:
		var next_mystery_id: String = pending[0]
		_activate_mystery(next_mystery_id)
		_remove_from_pending(case_id, next_mystery_id)
		_emit_log("Mystery " + next_mystery_id + " activated by probability roll (p=" + str(snapped(effective_probability, 0.01)) + ")")


func _calculate_activation_probability(case_id: String) -> float:
	"""Case의 pending mystery 활성화 확률을 계산합니다.
	공식: base_rate + max(0, days - grace) * (growth_rate / (1 + active_count * slowdown))"""
	var case_state: Dictionary = _active_cases[case_id]
	var days: int = case_state["days_since_opened"]
	var params: Dictionary = case_state.get("activation_params", {})

	var grace: int = params.get("grace_period_days", 7)
	var base: float = params.get("base_rate", 0.05)
	var growth: float = params.get("growth_rate", 0.08)
	var slowdown: float = params.get("slowdown_per_active_mystery", 0.25)

	if days < grace:
		return base

	var active_count: int = _count_active_mysteries_in_case(case_id)
	var effective_growth: float = growth / (1.0 + active_count * slowdown)
	var probability: float = base + effective_growth * (days - grace)
	return min(probability, 1.0)


func _count_active_mysteries_in_case(case_id: String) -> int:
	"""해당 Case 내 현재 활성(미해결) mystery 개수를 반환합니다."""
	var case_state: Dictionary = _active_cases[case_id]
	var count := 0
	for m in case_state["mysteries"]:
		var mystery_id: String = m["mystery_id"]
		if is_mystery_active(mystery_id):
			count += 1
	return count


func _remove_from_pending(case_id: String, mystery_id: String) -> void:
	var case_state: Dictionary = _active_cases[case_id]
	var pending: Array = case_state.get("pending_mysteries", [])
	if pending.has(mystery_id):
		pending.erase(mystery_id)


# -----------------------------------------------------------------------------
# 상태 조회 (State Queries)
# -----------------------------------------------------------------------------

# 상태 조회 (State Queries)
# -----------------------------------------------------------------------------

func get_active_mysteries() -> Dictionary:
	return _active_mysteries.duplicate(true)


func get_active_mystery_ids() -> Array:
	var result: Array = []
	for mystery_id in _active_mysteries.keys():
		if not is_mystery_resolved(mystery_id):
			result.append(mystery_id)
	return result


func get_mystery_display_name(mystery_id: String) -> String:
	var data: Dictionary = MysteryRegistry.get_mystery(mystery_id)
	return data.get("display_name", mystery_id)


func get_mystery_progress_text(mystery_id: String) -> String:
	if not _active_mysteries.has(mystery_id):
		return ""
	var state: Dictionary = _active_mysteries[mystery_id]
	var data: Dictionary = state["data"]
	var phases: Array = data.get("phases", [])
	var current_idx: int = state["current_phase_index"]
	var total: int = phases.size()
	var display_name: String = data.get("display_name", mystery_id)
	return display_name + " (" + str(current_idx) + "/" + str(total) + ")"
