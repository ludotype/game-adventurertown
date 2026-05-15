extends Node

## SaveManager: 다중 슬롯을 지원하는 게임 데이터 관리자.

const SAVE_DIR = "user://saves/"
const SAVE_FILE_PREFIX = "save_"
const SAVE_FILE_EXT = ".dat"

func _ready() -> void:
	# 세이브 디렉토리 확인 및 생성
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)

## 저장할 데이터 수집
func get_save_data() -> Dictionary:
	var gm_node = get_node_or_null("/root/GameManager")
	var tm_node = get_node_or_null("/root/TaskManager")
	var lm_node = get_node_or_null("/root/LocationManager")
	
	return {
		"version": "0.2",
		"timestamp": Time.get_datetime_dict_from_system(),
		"game_manager": { "current_phase": gm_node.current_phase if gm_node else 0 },
		"location_manager": { "current_location_id": lm_node.current_location_id if lm_node else "loc_desk_1f" },
		"dialogue_state": {
			"sanity": Flags.sanity,
			"shift_day": Flags.shift_day,
			"current_hour": Flags.current_hour,
			"current_minute": Flags.current_minute,
			"current_location": Flags.current_location,
			"tasks_completed": Flags.tasks_completed,
			"hotel_rank": Flags.hotel_rank,
			"met_bartender": Flags.met_bartender,
			"met_kikimora": Flags.met_kikimora,
			"has_manual": Flags.has_manual
		},
		"task_manager": { "active_tasks": tm_node.active_tasks if tm_node else {} }
	}

## 특정 슬롯에 게임 저장
func save_game(slot_index: int) -> bool:
	var path = _get_slot_path(slot_index)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("[SaveManager] 세이브 실패 (Slot %d): %s" % [slot_index, FileAccess.get_open_error()])
		return false
		
	var json_string = JSON.stringify(get_save_data(), "\t")
	file.store_string(json_string)
	file.close()
	print("[SaveManager] 슬롯 %d 저장 완료." % slot_index)
	return true

## 특정 슬롯의 게임 불러오기
func load_game(slot_index: int) -> bool:
	var path = _get_slot_path(slot_index)
	if not FileAccess.file_exists(path):
		printerr("[SaveManager] 파일 없음 (Slot %d)" % slot_index)
		return false
		
	var file = FileAccess.open(path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		printerr("[SaveManager] 데이터 파손 (Slot %d): %s" % [slot_index, json.get_error_message()])
		return false
		
	_apply_save_data(json.data)
	var lm = get_node_or_null("/root/LogManager")
	if lm: lm.info("슬롯 %d 로드 완료." % slot_index)
	return true

## 슬롯의 메타데이터(표시용 정보)만 가져오기
func get_slot_info(slot_index: int) -> Dictionary:
	var path = _get_slot_path(slot_index)
	if not FileAccess.file_exists(path):
		return {} # 빈 슬롯
		
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	
	if err != OK: return {"error": "Corrupted"}
	
	var data = json.data
	var ds = data.get("dialogue_state", {})
	
	# UI 표시에 필요한 핵심 정보만 리턴
	return {
		"day": ds.get("shift_day", 1),
		"hour": ds.get("current_hour", 22),
		"minute": ds.get("current_minute", 0),
		"rank": ds.get("hotel_rank", "D"),
		"timestamp": data.get("timestamp", {}),
		"sanity": ds.get("sanity", 100)
	}

func has_save(slot_index: int) -> bool:
	return FileAccess.file_exists(_get_slot_path(slot_index))

## 특정 슬롯의 세이브 파일 삭제
func delete_save(slot_index: int) -> void:
	var path = _get_slot_path(slot_index)
	if FileAccess.file_exists(path):
		var dir = DirAccess.open(SAVE_DIR)
		if dir:
			dir.remove(path)
			print("[SaveManager] 슬롯 %d 삭제 완료." % slot_index)

## 저장된 슬롯이 하나라도 있는지 확인 (타이틀 화면용)
func has_save_file() -> bool:
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(SAVE_FILE_EXT):
				return true
			file_name = dir.get_next()
	return false

func _get_slot_path(index: int) -> String:
	return "%s%s%d%s" % [SAVE_DIR, SAVE_FILE_PREFIX, index, SAVE_FILE_EXT]

func _apply_save_data(data: Dictionary) -> void:
	var ds = data.get("dialogue_state", {})
	for key in ds:
		Flags.set(key, ds[key])
		
	var lm_data = data.get("location_manager", {})
	var lm_node = get_node_or_null("/root/LocationManager")
	if lm_node:
		lm_node.force_move(lm_data.get("current_location_id", "loc_desk_1f"))
	
	var tm_data = data.get("task_manager", {})
	var tm_node = get_node_or_null("/root/TaskManager")
	if tm_node:
		tm_node.active_tasks = tm_data.get("active_tasks", {})
	
	var gm_data = data.get("game_manager", {})
	var gm_node = get_node_or_null("/root/GameManager")
	var saved_phase = gm_data.get("current_phase", 0)
	
	if get_tree().current_scene.scene_file_path == "res://scenes/ui/title_screen.tscn":
		get_tree().change_scene_to_file("res://scenes/gameplay/action_scene.tscn")
		await get_tree().process_frame
	
	# 화면 즉시 갱신 트리거
	if lm_node:
		lm_node.location_changed.emit(lm_node.current_location_id)
	
	# 일시정지 해제 (로드 직후 화면 갱신 보장)
	get_tree().paused = false
	if gm_node:
		gm_node.change_phase(saved_phase)
