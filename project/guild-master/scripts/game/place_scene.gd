extends Node2D

## PlaceScene
## 장소 씬의 모듈러 템플릿. 배경, NPC 패널, 이동 패널, 행동 패널을 모듈 단위로 표시합니다.
## 각 UI 모듈은 독립 씬이므로 인스펙터에서 위치/크기/폰트를 자유롭게 조정할 수 있습니다.

@export var place_id: String = "inn_room"
@export var default_time_of_day: String = "morning"

@onready var background_sprite: TextureRect = $UILayer/UIRoot/Background
@onready var info_header: InfoHeader = $UILayer/UIRoot/InfoHeader
@onready var npc_panel: NPCPanel = $UILayer/UIRoot/NPCPanel
@onready var action_panel: ActionPanel = $UILayer/UIRoot/ActionPanel
@onready var dialogue_bar: DialogueBar = $UILayer/UIRoot/DialogueBar
@onready var inventory_grid: InventoryGridPanel = $UILayer/UIRoot/InventoryGridPanel

var _spawner: Node
var _current_npc_data: Dictionary = {}


func _ready() -> void:
	_spawner = preload("res://scripts/game/npc_spawner.gd").new()
	_spawner.npc_spawned.connect(_on_npc_spawned)
	_spawner.empty_spawned.connect(_on_empty_spawned)
	add_child(_spawner)

	if has_node("/root/ActionRunner") and not ActionRunner.move_requested.is_connected(_on_action_move_requested):
		ActionRunner.move_requested.connect(_on_action_move_requested)
	if has_node("/root/ActionRunner") and not ActionRunner.time_changed.is_connected(_on_action_time_changed):
		ActionRunner.time_changed.connect(_on_action_time_changed)
	if has_node("/root/ActionRunner") and not ActionRunner.metric_changed.is_connected(_on_action_metric_changed):
		ActionRunner.metric_changed.connect(_on_action_metric_changed)
	if has_node("/root/ActionRunner") and not ActionRunner.log_emitted.is_connected(_on_log_emitted):
		ActionRunner.log_emitted.connect(_on_log_emitted)
	if has_node("/root/TimeSystem") and not TimeSystem.time_advanced.is_connected(_on_time_advanced):
		TimeSystem.time_advanced.connect(_on_time_advanced)
	if has_node("/root/MetricStore") and not MetricStore.metric_changed.is_connected(_on_metric_changed):
		MetricStore.metric_changed.connect(_on_metric_changed)
	if not action_panel.action_pressed.is_connected(_on_action_pressed):
		action_panel.action_pressed.connect(_on_action_pressed)
	if not action_panel.move_pressed.is_connected(_on_move_pressed):
		action_panel.move_pressed.connect(_on_move_pressed)

	_init_default_metrics()
	_enter_place(place_id)


## 외부에서도 호출 가능한 장소 진입 함수
func _enter_place(target_place_id: String) -> void:
	if target_place_id.is_empty():
		push_error("PlaceScene: empty place_id")
		return
	if not PlaceRegistry.has_place(target_place_id):
		push_error("PlaceScene: unknown place_id: " + target_place_id)
		return

	place_id = target_place_id
	_load_place()
	_refresh_time_label()

	_spawner.place_id = place_id
	_spawn_current_place_npc()
	if has_node("/root/CrisisManager") and CrisisManager.has_method("apply_mandatory_events"):
		CrisisManager.apply_mandatory_events("place_entered", _get_action_context())

	var place_data := PlaceRegistry.get_place(place_id)
	var desc: String = place_data.get("description", "")
	if not desc.is_empty() and dialogue_bar:
		dialogue_bar.append_log(desc)

	_refresh_action_buttons()


func _load_place() -> void:
	var place_data := PlaceRegistry.get_place(place_id)
	if place_data.is_empty():
		return

	info_header.set_place_name(place_data.get("display_name", place_id))
	info_header.set_metrics(_get_player_metrics())

	var bg_path: String = place_data.get("background_path", "")
	if not bg_path.is_empty() and ResourceLoader.exists(bg_path):
		background_sprite.texture = load(bg_path)
	else:
		background_sprite.texture = null

	var bgm: String = place_data.get("bgm", "")
	if not bgm.is_empty() and has_node("/root/BGMManager") and BGMManager.has_method("play_bgm_by_name"):
		BGMManager.play_bgm_by_name(bgm)


func _spawn_current_place_npc() -> void:
	var current_time := default_time_of_day
	if has_node("/root/TimeSystem"):
		current_time = TimeSystem.current_time_of_day
	_spawner.spawn(current_time, _get_current_story_flags())


func _refresh_time_label() -> void:
	if has_node("/root/TimeSystem"):
		info_header.set_time(TimeSystem.get_display_text())
	else:
		info_header.set_time(default_time_of_day)


func _refresh_action_buttons() -> void:
	action_panel.clear()

	var context := _get_action_context()
	var all_place_actions: Array = []
	if has_node("/root/InteractionRegistry"):
		all_place_actions = InteractionRegistry.get_available_place_actions(place_id, context)

	var allowed_general := ["wait", "look_around", "check_inventory", "playmusic"]
	var allowed_place_only := ["rest", "sleep"]
	var allowed_char := ["talk", "touch", "gift"]

	# 1. 일반 행동 (상단)
	action_panel.add_section("일반 행동")
	for definition in all_place_actions:
		var interaction_id := String(definition.get("interaction_id", ""))
		if interaction_id in allowed_general:
			var label := String(definition.get("label", interaction_id))
			var scope := String(definition.get("scope", "common"))
			action_panel.add_action(label, interaction_id, scope, "")

	# 2. 장소 전용 행동
	action_panel.add_separator()
	action_panel.add_section("장소 행동")
	for definition in all_place_actions:
		var interaction_id := String(definition.get("interaction_id", ""))
		if interaction_id in allowed_place_only:
			var label := String(definition.get("label", interaction_id))
			var scope := String(definition.get("scope", "place"))
			action_panel.add_action(label, interaction_id, scope, "")

	# 3. 캐릭터 행동
	action_panel.add_separator()
	var npc_id := String(_current_npc_data.get("npc_id", ""))
	var npc_display := String(_current_npc_data.get("display_name", npc_id))
	if npc_id.is_empty():
		action_panel.add_section("캐릭터 행동")
	else:
		action_panel.add_section(npc_display)
		if has_node("/root/InteractionRegistry"):
			var npc_context := _get_action_context(npc_id)
			var npc_actions: Array = InteractionRegistry.get_available_for_npc(npc_id, npc_context)
			for definition in npc_actions:
				var interaction_id := String(definition.get("interaction_id", ""))
				if interaction_id in allowed_char:
					var label := String(definition.get("label", interaction_id))
					action_panel.add_action(label, interaction_id, "char", npc_id)

	# 4. 이동
	action_panel.add_separator()
	action_panel.add_section("이동")
	var place_data := PlaceRegistry.get_place(place_id)
	if not place_data.is_empty():
		var connections: Array = place_data.get("connections", [])
		for raw_id in connections:
			var target_id := String(raw_id)
			if not PlaceRegistry.has_place(target_id):
				push_warning("PlaceScene: connection to unknown place_id: " + target_id)
				continue
			var target_data := PlaceRegistry.get_place(target_id)
			action_panel.add_movement(target_data.get("display_name", target_id), target_id)






func _on_move_pressed(target_place_id: String) -> void:
	if has_node("/root/ActionRunner"):
		ActionRunner.run({
			"type": "move",
			"target_place": target_place_id
		}, _get_action_context())
	else:
		_enter_place(target_place_id)


func _on_action_pressed(interaction_id: String, scope: String, npc_id: String) -> void:
	if interaction_id == "inventory" or interaction_id == "check_inventory":
		_open_inventory()
		return

	if not has_node("/root/InteractionRegistry") or not has_node("/root/ActionRunner"):
		return

	var context := _get_action_context(npc_id)
	var event := {}
	match scope:
		"place":
			event = InteractionRegistry.resolve_place_event(place_id, interaction_id, context)
		"common":
			event = InteractionRegistry.resolve_common_event(interaction_id, context)
		"char":
			event = InteractionRegistry.resolve_npc_event(npc_id, interaction_id, context)
		_:
			push_warning("PlaceScene: unknown interaction scope: " + scope)
			return

	if event.is_empty():
		push_warning("PlaceScene: no matching interaction event: " + scope + "/" + npc_id + "/" + interaction_id)
		return

	var action := _build_action_from_interaction_event(event)
	if action.is_empty():
		push_warning("PlaceScene: interaction event has no actions: " + String(event.get("id", interaction_id)))
		return

	ActionRunner.run(action, context)
	_refresh_action_buttons()


func _build_action_from_interaction_event(event: Dictionary) -> Dictionary:
	if event.has("actions"):
		return {
			"type": "sequence",
			"actions": event.get("actions", [])
		}
	if event.has("action") and typeof(event["action"]) == TYPE_DICTIONARY:
		return event["action"]
	return {}


func _on_action_move_requested(target_place_id: String) -> void:
	_enter_place(target_place_id)


func _on_action_time_changed() -> void:
	_refresh_time_label()
	_spawn_current_place_npc()
	_refresh_action_buttons()


func _on_action_metric_changed(_key: String, _value) -> void:
	_refresh_action_buttons()


func _on_time_advanced(_day: int, _hour: int, _minute: int, _time_block: String) -> void:
	_refresh_time_label()


func _get_action_context(target_npc_id: String = "") -> Dictionary:
	var context := {
		"place_id": place_id
	}
	if not target_npc_id.is_empty():
		context["target_npc"] = target_npc_id
		context["target_npc_name"] = _current_npc_data.get("display_name", target_npc_id)
	if has_node("/root/TimeSystem"):
		context["day"] = TimeSystem.day
		context["hour"] = TimeSystem.hour
		context["minute"] = TimeSystem.minute
		context["time_of_day"] = TimeSystem.current_time_of_day
		context["time_block"] = TimeSystem.current_time_of_day
	return context


func _on_npc_spawned(npc_data: Dictionary) -> void:
	_current_npc_data = npc_data
	npc_panel.set_npc(npc_data)

	var greeting := String(npc_data.get("greeting", ""))
	var display_name := String(npc_data.get("display_name", ""))
	if not greeting.is_empty() and dialogue_bar:
		dialogue_bar.append_log(greeting, display_name)
	elif dialogue_bar:
		dialogue_bar.clear()

	_refresh_action_buttons()


func _on_empty_spawned() -> void:
	_current_npc_data.clear()
	npc_panel.clear()
	if dialogue_bar:
		dialogue_bar.clear()
		# Optional: scene update text when no NPC is present
		# dialogue_bar.append_log("이 곳에는 아무도 없다.")




func _get_current_story_flags() -> Array:
	if has_node("/root/Flags") and Flags.has_method("get_active_flags"):
		return Flags.get_active_flags()
	return []


func _init_default_metrics() -> void:
	if not has_node("/root/MetricStore"):
		return
	if not MetricStore.has_metric("player.funds"):
		MetricStore.set_metric("player.funds", 100)
	if not MetricStore.has_metric("player.hp"):
		MetricStore.set_metric("player.hp", 80)
	if not MetricStore.has_metric("player.sanity"):
		MetricStore.set_metric("player.sanity", 95)


func _has_instrument() -> bool:
	if not has_node("/root/InventoryManager"):
		return false
	return InventoryManager.has_item("instrument", 1)


func _get_player_metrics() -> Dictionary:
	var metrics := {}
	if not has_node("/root/MetricStore"):
		return metrics
	var known_keys: Array[String] = [
		"player.funds", "player.gold", "player.money",
		"player.hp", "player.health",
		"player.sanity", "player.san", "player.mental",
		"player.strength", "player.str",
		"player.intelligence", "player.int",
		"player.dexterity", "player.dex",
		"player.will", "player.willpower"
	]
	for key in known_keys:
		if MetricStore.has_metric(key):
			metrics[key] = MetricStore.get_metric(key)
	return metrics


func _on_metric_changed(key: String, _value) -> void:
	if key.begins_with("player."):
		info_header.set_metrics(_get_player_metrics())


func _on_log_emitted(message: String, _context: Dictionary) -> void:
	if dialogue_bar:
		dialogue_bar.append_log(message)


func _open_inventory() -> void:
	if inventory_grid:
		inventory_grid.open()
		if not inventory_grid.item_selected.is_connected(_on_inventory_item_selected):
			inventory_grid.item_selected.connect(_on_inventory_item_selected)
	_refresh_inventory_sidebar()


func _close_inventory() -> void:
	if inventory_grid:
		inventory_grid.close()
	_refresh_action_buttons()


func _on_inventory_item_selected(item_id: String) -> void:
	_refresh_inventory_sidebar(item_id)


func _refresh_inventory_sidebar(item_id: String = "") -> void:
	action_panel.clear()
	action_panel.add_back_button("돌아가기", _on_inventory_back)
	action_panel.add_separator()

	if item_id.is_empty():
		action_panel.add_section("아이템 정보")
		action_panel.add_custom_label("아이템을 선택하세요.", 16, Color(0xc0bcb5ff))
		return

	var def := ItemRegistry.get_item(item_id)
	if def.is_empty():
		action_panel.add_section("아이템 정보")
		action_panel.add_custom_label("알 수 없는 아이템입니다.", 16, Color(0xc0bcb5ff))
		return

	action_panel.add_section(def.get("display_name", item_id))
	var icon_path: String = def.get("icon_path", "")
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		action_panel.add_texture_rect(load(icon_path), Vector2(64, 64))
	action_panel.add_custom_label(def.get("description", ""), 16)

	var category: String = def.get("category", "")
	var equipped := InventoryManager.is_equipped(item_id)
	action_panel.add_separator()
	action_panel.add_section("행동")
	match category:
		"weapon", "armor":
			action_panel.add_action_callback("해제" if equipped else "장착", _on_inventory_equip.bind(item_id))
		"consumable":
			action_panel.add_action_callback("사용", _on_inventory_use.bind(item_id))
		_:
			action_panel.add_action_callback("확인", func(): pass)


func _on_inventory_back() -> void:
	_close_inventory()


func _on_inventory_use(item_id: String) -> void:
	if not has_node("/root/InventoryManager"):
		return
	var def := ItemRegistry.get_item(item_id)
	_apply_item_effects(def.get("effects", []))
	InventoryManager.remove_item(item_id, 1)
	inventory_grid.refresh()
	_refresh_inventory_sidebar(inventory_grid.get_selected_item_id())


func _on_inventory_equip(item_id: String) -> void:
	if not has_node("/root/InventoryManager"):
		return
	if InventoryManager.is_equipped(item_id):
		InventoryManager.unequip_item(item_id)
	else:
		InventoryManager.equip_item(item_id)
	inventory_grid.refresh()
	_refresh_inventory_sidebar(item_id)


func _apply_item_effects(effects: Array) -> void:
	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		var effect_dict: Dictionary = effect
		var effect_type: String = effect_dict.get("type", "")
		match effect_type:
			"heal":
				var key: String = effect_dict.get("metric_key", "player.hp")
				var amount: int = effect_dict.get("amount", 0)
				if has_node("/root/MetricStore"):
					MetricStore.change_metric(key, amount)
			"buff":
				var key: String = effect_dict.get("metric_key", "player.attack")
				var amount: int = effect_dict.get("amount", 0)
				if has_node("/root/MetricStore"):
					MetricStore.change_metric(key, amount)
