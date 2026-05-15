extends Node

## EncounterManager: NPC나 객체와의 특수 대면 상황(인카운터)을 관리합니다.

signal encounter_started(target_id: String)
signal encounter_finished

var is_in_encounter: bool = false
var current_target_id: String = ""
var encounter_ui_scene = preload("res://scenes/ui/encounter_ui.tscn")
var _ui_instance: CanvasLayer = null

func start_encounter(target_id: String, dialogue_res: DialogueResource, title: String = "start") -> void:
	if is_in_encounter: return
	
	is_in_encounter = true
	current_target_id = target_id
	
	# --- [ 대화 전용 데이터 브릿지 주입 ] ---
	var gm = get_node_or_null("/root/GuestManager")
	var em = get_node_or_null("/root/EntityManager")
	
	Flags.current_room_id = target_id
	if target_id.begins_with("loc_room_"):
		Flags.current_room_number = target_id.replace("loc_room_1f_", "").replace("loc_room_2f_", "").replace("loc_room_3f_", "")
	else:
		Flags.current_room_number = "---"
	
	if gm:
		Flags.current_guest_personality = gm.get_personality(target_id)
		Flags.enc_is_room_occupied = gm.is_room_occupied(target_id)
		Flags.enc_guest_responds_now = gm.decide_if_guest_responds(target_id)
	
	if em:
		Flags.enc_is_floor_noisy = em.is_any_entity_on_same_floor(target_id)
	
	# --- [ 객실 특수 상태 주입 ] ---
	var loc_res = LocationManager.get_location_resource(target_id)
	if loc_res:
		Flags.door_state = int(loc_res.door_state)
		Flags.has_entity = loc_res.has_entity
	# ---------------------------------------

	# UI 생성 및 표시
	_ui_instance = encounter_ui_scene.instantiate()
	get_tree().root.add_child(_ui_instance)
	_ui_instance.setup(target_id)
	
	encounter_started.emit(target_id)
	
	# 대화 시작
	if dialogue_res:
		var balloon = DialogueManager.show_dialogue_balloon(dialogue_res, title)
		if balloon:
			await balloon.tree_exited
	
	finish_encounter()

func finish_encounter() -> void:
	if not is_in_encounter: return
	
	if is_instance_valid(_ui_instance):
		_ui_instance.queue_free()
	
	is_in_encounter = false
	current_target_id = ""
	encounter_finished.emit()
	print("[EncounterManager] 인카운터 종료.")
