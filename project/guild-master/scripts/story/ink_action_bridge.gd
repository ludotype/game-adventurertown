extends Node

## InkActionBridge
## Ink 외부 함수(EXTERNAL)를 ActionRunner 액션으로 연결하는 브리지입니다.
## Ink 스크립트에서 게임 상태를 변경할 수 있도록 각 액션 타입을 외부 함수로 노출합니다.

func bind_all(ink_player: InkPlayer) -> void:
	if ink_player == null:
		push_error("InkActionBridge: ink_player is null")
		return

	# Side-effect 함수는 lookahead_safe = false 로 등록
	ink_player.bind_external_function("set_flag",       self, "_ext_set_flag",       false)
	ink_player.bind_external_function("set_metric",     self, "_ext_set_metric",     false)
	ink_player.bind_external_function("change_metric",  self, "_ext_change_metric",  false)
	ink_player.bind_external_function("advance_time",   self, "_ext_advance_time",   false)
	ink_player.bind_external_function("advance_minutes",self, "_ext_advance_minutes",false)
	ink_player.bind_external_function("sleep_until_next_day", self, "_ext_sleep_until_next_day", false)
	ink_player.bind_external_function("add_item",       self, "_ext_add_item",       false)
	ink_player.bind_external_function("remove_item",    self, "_ext_remove_item",    false)
	ink_player.bind_external_function("equip_item",     self, "_ext_equip_item",     false)
	ink_player.bind_external_function("unequip_item",   self, "_ext_unequip_item",   false)
	ink_player.bind_external_function("move",           self, "_ext_move",           false)
	ink_player.bind_external_function("log",            self, "_ext_log",            false)
	ink_player.bind_external_function("add_condition",  self, "_ext_add_condition",  false)
	ink_player.bind_external_function("remove_condition",self, "_ext_remove_condition",false)
	ink_player.bind_external_function("change_doom",    self, "_ext_change_doom",    false)
	ink_player.bind_external_function("block_place",    self, "_ext_block_place",    false)
	ink_player.bind_external_function("unblock_place",  self, "_ext_unblock_place",  false)
	ink_player.bind_external_function("trigger_game_over", self, "_ext_trigger_game_over", false)
	ink_player.bind_external_function("open_ui",        self, "_ext_open_ui",        false)
	ink_player.bind_external_function("random_loot",    self, "_ext_random_loot",    false)
	ink_player.bind_external_function("trigger_mandatory", self, "_ext_trigger_mandatory", false)
	ink_player.bind_external_function("start_dialogue", self, "_ext_start_dialogue", false)


func _ext_set_flag(key: String, value: bool) -> void:
	ActionRunner.run({"type": "set_flag", "key": key, "value": value})


func _ext_set_metric(key: String, value: int) -> void:
	ActionRunner.run({"type": "set_metric", "key": key, "value": value})


func _ext_change_metric(key: String, amount: int) -> void:
	ActionRunner.run({"type": "change_metric", "key": key, "amount": amount})


func _ext_advance_time(time_units: int) -> void:
	ActionRunner.run({"type": "advance_time", "time_units": time_units})


func _ext_advance_minutes(minutes: int) -> void:
	ActionRunner.run({"type": "advance_minutes", "minutes": minutes})


func _ext_sleep_until_next_day() -> void:
	ActionRunner.run({"type": "sleep_until_next_day"})


func _ext_add_item(item_id: String, amount: int) -> void:
	ActionRunner.run({"type": "add_item", "item_id": item_id, "amount": amount})


func _ext_remove_item(item_id: String, amount: int) -> void:
	ActionRunner.run({"type": "remove_item", "item_id": item_id, "amount": amount})


func _ext_equip_item(item_id: String) -> void:
	ActionRunner.run({"type": "equip_item", "item_id": item_id})


func _ext_unequip_item(item_id: String) -> void:
	ActionRunner.run({"type": "unequip_item", "item_id": item_id})


func _ext_move(target_place: String) -> void:
	ActionRunner.run({"type": "move", "target_place": target_place})


func _ext_log(message: String) -> void:
	ActionRunner.run({"type": "log", "message": message})


func _ext_add_condition(condition_id: String, duration: int = -1, stack: int = 1) -> void:
	ActionRunner.run({"type": "add_condition", "condition_id": condition_id, "duration": duration, "stack": stack})


func _ext_remove_condition(condition_id: String) -> void:
	ActionRunner.run({"type": "remove_condition", "condition_id": condition_id})


func _ext_change_doom(amount: int) -> void:
	ActionRunner.run({"type": "change_doom", "amount": amount})


func _ext_block_place(place_id: String, reason: String = "") -> void:
	ActionRunner.run({"type": "block_place", "place_id": place_id, "reason": reason})


func _ext_unblock_place(place_id: String) -> void:
	ActionRunner.run({"type": "unblock_place", "place_id": place_id})


func _ext_trigger_game_over(reason: String, game_over_type: String = "normal") -> void:
	ActionRunner.run({"type": "game_over", "reason": reason, "game_over_type": game_over_type})


func _ext_open_ui(ui_name: String) -> void:
	ActionRunner.run({"type": "open_ui", "ui_name": ui_name})


func _ext_random_loot(table_id: String) -> void:
	ActionRunner.run({"type": "random_loot", "table_id": table_id})


func _ext_trigger_mandatory(trigger_on: String) -> void:
	ActionRunner.run({"type": "trigger_mandatory", "trigger_on": trigger_on})


func _ext_start_dialogue(dialogue_id: String) -> void:
	ActionRunner.run({"type": "dialogue", "dialogue_id": dialogue_id})
