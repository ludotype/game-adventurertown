extends Node2D

## PlaceScene
## 장소 씬의 기본 템플릿. 배경, NPC 오버레이, 이동 커맨드, 행동 선택지를 표시합니다.
## connections는 data/places/*.json, 행동 버튼은 data/interactions/ 에서 데이터 기반으로 정의됩니다.

@export var place_id: String = "inn_room"
@export var default_time_of_day: String = "morning"

@onready var background_sprite: Sprite2D = $BackgroundSprite
@onready var npc_overlay: Control = $UILayer/UIRoot/NPCOverlay
@onready var npc_portrait: TextureRect = $UILayer/UIRoot/NPCOverlay/NPCPortrait
@onready var npc_name_label: Label = $UILayer/UIRoot/NPCOverlay/NPCNameLabel
@onready var place_name_label: Label = $UILayer/UIRoot/PlaceNameLabel
@onready var time_label: Label = $UILayer/UIRoot/TimeLabel
@onready var action_list: VBoxContainer = $UILayer/UIRoot/RightPanel/RightMargin/ActionContainer/ActionList
@onready var move_list: HBoxContainer = $UILayer/UIRoot/BottomPanel/BottomMargin/MoveContainer/MoveList

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
	if not npc_overlay.gui_input.is_connected(_on_npc_overlay_gui_input):
		npc_overlay.gui_input.connect(_on_npc_overlay_gui_input)

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

	place_name_label.text = place_data.get("display_name", place_id)

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
		time_label.text = TimeSystem.get_display_text()
	else:
		time_label.text = default_time_of_day


func _refresh_move_buttons() -> void:
	for child in move_list.get_children():
		child.queue_free()

	var place_data := PlaceRegistry.get_place(place_id)
	var connections: Array = place_data.get("connections", [])

	for raw_id in connections:
		var target_id := String(raw_id)
		if not PlaceRegistry.has_place(target_id):
			push_warning("PlaceScene: connection to unknown place_id: " + target_id)
			continue

		var target_data := PlaceRegistry.get_place(target_id)
		var button := Button.new()
		button.text = target_data.get("display_name", target_id)
		button.custom_minimum_size = Vector2(180, 64)
		button.pressed.connect(_on_move_pressed.bind(target_id))
		move_list.add_child(button)


func _refresh_action_buttons() -> void:
	for child in action_list.get_children():
		child.queue_free()

	if not has_node("/root/InteractionRegistry"):
		return

	var context := _get_action_context()
	var place_interactions: Array = InteractionRegistry.get_available_place_actions(place_id, context)
	if not place_interactions.is_empty():
		_add_section_label("장소 행동")
		for definition in place_interactions:
			var interaction_id := String(definition.get("interaction_id", ""))
			var label := String(definition.get("label", interaction_id))
			var scope := String(definition.get("scope", "common"))
			_add_action_button(label, _on_interaction_pressed.bind(scope, interaction_id, ""))

	var npc_id := String(_current_npc_data.get("npc_id", ""))
	if npc_id.is_empty():
		return

	var npc_context := _get_action_context(npc_id)
	var npc_interactions: Array = InteractionRegistry.get_available_for_npc(npc_id, npc_context)
	if npc_interactions.is_empty():
		return

	_add_section_label(String(_current_npc_data.get("display_name", npc_id)))
	for definition in npc_interactions:
		var interaction_id := String(definition.get("interaction_id", ""))
		var label := String(definition.get("label", interaction_id))
		_add_action_button(label, _on_interaction_pressed.bind("char", interaction_id, npc_id))


func _add_section_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_list.add_child(label)


func _add_action_button(text, callable: Callable) -> void:
	var button := Button.new()
	button.text = String(text)
	button.custom_minimum_size = Vector2(0, 56)
	button.pressed.connect(callable)
	action_list.add_child(button)


func _on_move_pressed(target_place_id: String) -> void:
	if has_node("/root/ActionRunner"):
		ActionRunner.run({
			"type": "move",
			"target_place": target_place_id
		}, _get_action_context())
	else:
		_enter_place(target_place_id)


func _on_interaction_pressed(scope: String, interaction_id: String, npc_id: String) -> void:
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
	npc_overlay.visible = true
	npc_name_label.text = npc_data.get("display_name", "")

	var portrait_path: String = npc_data.get("portrait_path", "")
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		npc_portrait.texture = load(portrait_path)
	else:
		npc_portrait.texture = null

	print("PlaceScene: NPC spawned - ", npc_data.get("npc_id"),
		" (probability: ", "%.1f" % (npc_data.get("probability", 0.0) * 100.0), "%)")


func _on_empty_spawned() -> void:
	_current_npc_data.clear()
	npc_overlay.visible = false
	npc_name_label.text = ""
	npc_portrait.texture = null
	print("PlaceScene: no NPC spawned (empty) @ ", place_id)


func _on_npc_overlay_gui_input(event: InputEvent) -> void:
	if not npc_overlay.visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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
