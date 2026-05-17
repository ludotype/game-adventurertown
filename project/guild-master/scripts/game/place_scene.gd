extends Node2D

## PlaceScene
## 장소 씬의 모듈러 템플릿. 배경, NPC 패널, 이동 패널, 행동 패널을 모듈 단위로 표시합니다.
## 각 UI 모듈은 독립 씬이므로 인스펙터에서 위치/크기/폰트를 자유롭게 조정할 수 있습니다.

@export var place_id: String = "inn_room"
@export var default_time_of_day: String = "morning"

@onready var background_sprite: Sprite2D = $BackgroundSprite
@onready var info_header: InfoHeader = $UILayer/UIRoot/InfoHeader
@onready var npc_panel: NPCPanel = $UILayer/UIRoot/NPCPanel
@onready var action_panel: ActionPanel = $UILayer/UIRoot/ActionPanel
@onready var move_panel: MovePanel = $UILayer/UIRoot/MovePanel

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
	if has_node("/root/TimeSystem") and not TimeSystem.time_advanced.is_connected(_on_time_advanced):
		TimeSystem.time_advanced.connect(_on_time_advanced)
	if not npc_panel.clicked.is_connected(_on_npc_panel_clicked):
		npc_panel.clicked.connect(_on_npc_panel_clicked)
	if not move_panel.move_pressed.is_connected(_on_move_pressed):
		move_panel.move_pressed.connect(_on_move_pressed)
	if not action_panel.action_pressed.is_connected(_on_action_pressed):
		action_panel.action_pressed.connect(_on_action_pressed)

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
	_refresh_move_buttons()

	_spawner.place_id = place_id
	_spawn_current_place_npc()
	if has_node("/root/CrisisManager") and CrisisManager.has_method("apply_mandatory_events"):
		CrisisManager.apply_mandatory_events("place_entered", _get_action_context())
	_refresh_action_buttons()


func _load_place() -> void:
	var place_data := PlaceRegistry.get_place(place_id)
	if place_data.is_empty():
		return

	info_header.set_place_name(place_data.get("display_name", place_id))

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


func _refresh_move_buttons() -> void:
	move_panel.clear()

	var place_data := PlaceRegistry.get_place(place_id)
	var connections: Array = place_data.get("connections", [])

	for raw_id in connections:
		var target_id := String(raw_id)
		if not PlaceRegistry.has_place(target_id):
			push_warning("PlaceScene: connection to unknown place_id: " + target_id)
			continue

		var target_data := PlaceRegistry.get_place(target_id)
		move_panel.add_destination(target_data.get("display_name", target_id), target_id)


func _refresh_action_buttons() -> void:
	action_panel.clear()

	if not has_node("/root/InteractionRegistry"):
		return

	var context := _get_action_context()
	var place_interactions: Array = InteractionRegistry.get_available_place_actions(place_id, context)
	if not place_interactions.is_empty():
		action_panel.add_section("장소 행동")
		for definition in place_interactions:
			var interaction_id := String(definition.get("interaction_id", ""))
			var label := String(definition.get("label", interaction_id))
			var scope := String(definition.get("scope", "common"))
			action_panel.add_action(label, interaction_id, scope, "")

	var npc_id := String(_current_npc_data.get("npc_id", ""))
	if npc_id.is_empty():
		return

	var npc_context := _get_action_context(npc_id)
	var npc_interactions: Array = InteractionRegistry.get_available_for_npc(npc_id, npc_context)
	if npc_interactions.is_empty():
		return

	action_panel.add_section(String(_current_npc_data.get("display_name", npc_id)))
	for definition in npc_interactions:
		var interaction_id := String(definition.get("interaction_id", ""))
		var label := String(definition.get("label", interaction_id))
		action_panel.add_action(label, interaction_id, "char", npc_id)


func _on_move_pressed(target_place_id: String) -> void:
	if has_node("/root/ActionRunner"):
		ActionRunner.run({
			"type": "move",
			"target_place": target_place_id
		}, _get_action_context())
	else:
		_enter_place(target_place_id)


func _on_action_pressed(interaction_id: String, scope: String, npc_id: String) -> void:
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
	print("PlaceScene: move to ", target_place_id)
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

	print("PlaceScene: NPC spawned - ", npc_data.get("npc_id"),
		" (probability: ", "%.1f" % (npc_data.get("probability", 0.0) * 100.0), "%)")


func _on_empty_spawned() -> void:
	_current_npc_data.clear()
	npc_panel.clear()
	print("PlaceScene: no NPC spawned (empty) @ ", place_id)


func _on_npc_panel_clicked() -> void:
	var dialogue_id := String(_current_npc_data.get("dialogue_id", ""))
	if dialogue_id.is_empty():
		push_warning("PlaceScene: NPC has no dialogue_id: " + String(_current_npc_data.get("npc_id", "")))
		return
	if has_node("/root/ActionRunner"):
		ActionRunner.run({
			"type": "dialogue",
			"dialogue_id": dialogue_id
		}, _get_action_context(String(_current_npc_data.get("npc_id", ""))))


func _get_current_story_flags() -> Array:
	if has_node("/root/Flags") and Flags.has_method("get_active_flags"):
		return Flags.get_active_flags()
	return []
