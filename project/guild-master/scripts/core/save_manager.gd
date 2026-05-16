extends Node

## SaveManager
## 현재 아키텍처의 모든 상태를 슬롯 기반 JSON으로 저장/로드합니다.

const SAVE_DIR = "user://saves/"
const SAVE_FILE_PREFIX = "save_"
const SAVE_FILE_EXT = ".dat"
const CURRENT_VERSION = "1.0"

signal save_completed(slot_index: int)
signal load_completed(slot_index: int)

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)


## 저장할 데이터 수집
func get_save_data() -> Dictionary:
	var data := {
		"version": CURRENT_VERSION,
		"timestamp": Time.get_datetime_dict_from_system(),
		"metric_store": {},
		"time_system": {},
		"game_flags": {},
		"condition_manager": {},
		"crisis_manager": {},
		"inventory_manager": {},
		"current_place_id": ""
	}

	if has_node("/root/MetricStore") and MetricStore.has_method("get_all_metrics"):
		data["metric_store"] = MetricStore.get_all_metrics()

	if has_node("/root/TimeSystem"):
		data["time_system"] = {
			"day": TimeSystem.day,
			"hour": TimeSystem.hour,
			"minute": TimeSystem.minute
		}

	if has_node("/root/Flags"):
		data["game_flags"] = {
			"day": Flags.day,
			"score": Flags.score,
			"flags": Flags.flags.duplicate(true)
		}

	if has_node("/root/ConditionManager") and ConditionManager.has_method("get_all_active_conditions"):
		data["condition_manager"] = ConditionManager.get_all_active_conditions()

	if has_node("/root/CrisisManager"):
		var crisis_save := {}
		if CrisisManager.has_method("get_active_crises"):
			crisis_save["active_crises"] = _serialize_active_crises(CrisisManager.get_active_crises())
		if CrisisManager.has_method("get_doom"):
			crisis_save["doom"] = CrisisManager.get_doom()
		if CrisisManager.has_method("get_all_blocked_places"):
			crisis_save["blocked_places"] = CrisisManager.get_all_blocked_places()
		else:
			crisis_save["blocked_places"] = _get_blocked_places_direct()
		if CrisisManager.get("_doom_thresholds_triggered") != null:
			crisis_save["doom_thresholds_triggered"] = CrisisManager.get("_doom_thresholds_triggered").duplicate()
		data["crisis_manager"] = crisis_save

	if has_node("/root/InventoryManager") and InventoryManager.has_method("get_inventory_data"):
		data["inventory_manager"] = InventoryManager.get_inventory_data()

	data["current_place_id"] = _get_current_place_id()
	return data


func _serialize_active_crises(active_crises: Dictionary) -> Dictionary:
	var result := {}
	for crisis_id in active_crises.keys():
		var state: Dictionary = active_crises[crisis_id]
		result[crisis_id] = {
			"doom_timer": state.get("doom_timer", 0)
		}
	return result


func _get_blocked_places_direct() -> Dictionary:
	if CrisisManager.get("_blocked_places") != null:
		return CrisisManager.get("_blocked_places").duplicate()
	return {}


func _get_current_place_id() -> String:
	var place_scene = _find_place_scene()
	if place_scene != null:
		return place_scene.get("place_id") if place_scene.get("place_id") != null else ""
	return ""


func _find_place_scene() -> Node:
	var root := get_tree().current_scene
	if root == null:
		return null
	return _find_place_scene_recursive(root)


func _find_place_scene_recursive(node: Node) -> Node:
	if node.has_method("_enter_place") and node.get("place_id") != null:
		return node
	for child in node.get_children():
		var found := _find_place_scene_recursive(child)
		if found != null:
			return found
	return null


## 특정 슬롯에 게임 저장
func save_game(slot_index: int) -> bool:
	var path := _get_slot_path(slot_index)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("[SaveManager] 세이브 실패 (Slot %d): %s" % [slot_index, FileAccess.get_open_error()])
		return false

	var json_string := JSON.stringify(get_save_data(), "\t")
	file.store_string(json_string)
	file.close()
	print("[SaveManager] 슬롯 %d 저장 완료." % slot_index)
	save_completed.emit(slot_index)
	return true


## 특정 슬롯의 게임 불러오기
func load_game(slot_index: int) -> bool:
	var path := _get_slot_path(slot_index)
	if not FileAccess.file_exists(path):
		printerr("[SaveManager] 파일 없음 (Slot %d)" % slot_index)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		printerr("[SaveManager] 데이터 파손 (Slot %d): %s" % [slot_index, json.get_error_message()])
		return false

	_apply_save_data(json.data)
	print("[SaveManager] 슬롯 %d 로드 완료." % slot_index)
	load_completed.emit(slot_index)
	return true


func _apply_save_data(data: Dictionary) -> void:
	# 1. Reset all stateful autoloads
	if has_node("/root/Flags") and Flags.has_method("reset_flags"):
		Flags.reset_flags()
	if has_node("/root/MetricStore") and MetricStore.has_method("clear_metrics"):
		MetricStore.clear_metrics()
	if has_node("/root/ConditionManager") and ConditionManager.has_method("clear_all_conditions"):
		ConditionManager.clear_all_conditions()
	if has_node("/root/CrisisManager") and CrisisManager.has_method("reset_state"):
		CrisisManager.reset_state()
	if has_node("/root/InventoryManager") and InventoryManager.has_method("clear_inventory"):
		InventoryManager.clear_inventory()
	if has_node("/root/TimeSystem") and TimeSystem.has_method("reset_time"):
		TimeSystem.reset_time()

	# 2. Restore MetricStore
	var metrics: Dictionary = data.get("metric_store", {})
	if has_node("/root/MetricStore") and MetricStore.has_method("set_metric"):
		for key in metrics.keys():
			MetricStore.set_metric(key, metrics[key])

	# 3. Restore TimeSystem
	var ts: Dictionary = data.get("time_system", {})
	if has_node("/root/TimeSystem") and TimeSystem.has_method("set_time"):
		TimeSystem.set_time(
			ts.get("day", 1),
			ts.get("hour", 7),
			ts.get("minute", 0)
		)

	# 4. Restore GameFlags
	var gf: Dictionary = data.get("game_flags", {})
	if has_node("/root/Flags"):
		Flags.day = gf.get("day", 1)
		Flags.score = gf.get("score", 0)
		var saved_flags: Dictionary = gf.get("flags", {})
		if Flags.has_method("set_flag"):
			for key in saved_flags.keys():
				Flags.set_flag(key, saved_flags[key])

	# 5. Restore ConditionManager
	var cm: Dictionary = data.get("condition_manager", {})
	if has_node("/root/ConditionManager") and ConditionManager.has_method("add_condition"):
		for condition_id in cm.keys():
			var info: Dictionary = cm[condition_id]
			ConditionManager.add_condition(
				condition_id,
				info.get("duration_remaining", -1),
				info.get("stack", 1)
			)

	# 6. Restore CrisisManager
	var crisis_data: Dictionary = data.get("crisis_manager", {})
	if has_node("/root/CrisisManager"):
		# active_crises
		var active: Dictionary = crisis_data.get("active_crises", {})
		for crisis_id in active.keys():
			var timer: int = active[crisis_id].get("doom_timer", 14)
			var def: Dictionary = CrisisRegistry.get_crisis(crisis_id)
			if not def.is_empty():
				CrisisManager.get("_active_crises")[crisis_id] = {
					"doom_timer": timer,
					"data": def
				}
		# doom
		var saved_doom: int = crisis_data.get("doom", 0)
		if CrisisManager.has_method("change_doom"):
			var current_doom: int = CrisisManager.get_doom()
			CrisisManager.change_doom(saved_doom - current_doom)
		# blocked_places
		var blocked: Dictionary = crisis_data.get("blocked_places", {})
		for place_id in blocked.keys():
			if CrisisManager.has_method("block_place"):
				CrisisManager.block_place(place_id, blocked[place_id])
		# thresholds
		var thresholds: Dictionary = crisis_data.get("doom_thresholds_triggered", {})
		var crisis_mgr_thresholds = CrisisManager.get("_doom_thresholds_triggered")
		if crisis_mgr_thresholds != null:
			for key in thresholds.keys():
				crisis_mgr_thresholds[key] = thresholds[key]

	# 7. Restore InventoryManager
	var inv: Dictionary = data.get("inventory_manager", {})
	if has_node("/root/InventoryManager") and InventoryManager.has_method("set_inventory_data"):
		InventoryManager.set_inventory_data(inv)

	# 8. Scene transition if loading from title screen
	var saved_place_id: String = data.get("current_place_id", "")
	if get_tree().current_scene != null and get_tree().current_scene.scene_file_path == "res://scenes/ui/title_screen.tscn":
		get_tree().change_scene_to_file("res://scenes/gameplay/game_scene.tscn")
		await get_tree().process_frame
		await get_tree().process_frame
		if not saved_place_id.is_empty() and has_node("/root/ActionRunner"):
			ActionRunner.run({ "type": "move", "target_place": saved_place_id })

	get_tree().paused = false


## 슬롯의 메타데이터(표시용 정보)만 가져오기
func get_slot_info(slot_index: int) -> Dictionary:
	var path := _get_slot_path(slot_index)
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return {"error": "Corrupted"}

	var data = json.data
	var ts: Dictionary = data.get("time_system", {})
	var gf: Dictionary = data.get("game_flags", {})
	return {
		"day": ts.get("day", 1),
		"hour": ts.get("hour", 7),
		"minute": ts.get("minute", 0),
		"score": gf.get("score", 0),
		"timestamp": data.get("timestamp", {}),
		"place_id": data.get("current_place_id", ""),
		"has_save": true
	}


func has_save(slot_index: int) -> bool:
	return FileAccess.file_exists(_get_slot_path(slot_index))


func delete_save(slot_index: int) -> void:
	var path := _get_slot_path(slot_index)
	if FileAccess.file_exists(path):
		var dir := DirAccess.open(SAVE_DIR)
		if dir:
			dir.remove(path)
			print("[SaveManager] 슬롯 %d 삭제 완료." % slot_index)


func has_save_file() -> bool:
	var dir := DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(SAVE_FILE_EXT):
				return true
			file_name = dir.get_next()
	return false


func _get_slot_path(index: int) -> String:
	return "%s%s%d%s" % [SAVE_DIR, SAVE_FILE_PREFIX, index, SAVE_FILE_EXT]
