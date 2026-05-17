extends CanvasLayer

## InkBalloon
## Ink 스토리를 위한 전용 풍선 UI입니다.
## DialogueManager 의 balloon.gd 와 동일한 UX를 제공합니다.

const NEXT_ACTION := &"ui_accept"
const SKIP_ACTION := &"ui_cancel"
const FF_SPEED := 4.0
const TYPING_SPEED := 0.03

@onready var balloon: Control = %Balloon
@onready var character_label: RichTextLabel = %CharacterLabel
@onready var character_nickname_label: Label = %CharacterNicknameLabel
@onready var dialogue_label: RichTextLabel = %DialogueLabel
@onready var responses_container: PanelContainer = %Responses
@onready var responses_menu: VBoxContainer = %ResponsesMenu
@onready var response_template: Button = %ResponseTemplate
@onready var ff_indicator: Label = %FFIndicator
@onready var next_indicator: Control = %NextIndicator
@onready var next_indicator_icon: TextureRect = %NextIndicator/Icon

@export var hop_sound: AudioStream = null
var hop_sound_player: AudioStreamPlayer = null
@export var sink_sound: AudioStream = null
var sink_sound_player: AudioStreamPlayer = null

var ink_player: InkPlayer = null

var is_waiting_for_input: bool = false
var is_ui_hidden: bool = false
var is_typing: bool = false
var is_dialogue_type_end: bool = false

var current_text: String = ""
var current_tags: Array = []
var has_choices: bool = false
var pending_choices: Array = []

var _typing_timer: float = 0.0
var _typing_speed: float = TYPING_SPEED

var dialogue_type_end_timer: float = 0.0
const DIALOGUE_TYPE_END_ANIMATION_SPEED := 30.0
const NEXT_INDICATOR_FRAME_COUNT := 23


func _ready() -> void:
	balloon.hide()
	name = "InkBalloon"
	%LeftSCG.texture = null
	%RightSCG.texture = null
	%CenterSCG.texture = null
	if hop_sound:
		hop_sound_player = AudioStreamPlayer.new()
		hop_sound_player.stream = hop_sound
		$Sound.add_child(hop_sound_player)
	if sink_sound:
		sink_sound_player = AudioStreamPlayer.new()
		sink_sound_player.stream = sink_sound
		$Sound.add_child(sink_sound_player)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


## Ink 스토리를 시작합니다.
func start(ink_file_path: String) -> void:
	var ink_resource = load(ink_file_path)
	if ink_resource == null:
		push_error("InkBalloon: failed to load ink file: " + ink_file_path)
		queue_free()
		return
	if not ("json" in ink_resource):
		push_error("InkBalloon: resource is not an InkResource: " + ink_file_path)
		queue_free()
		return

	ink_player = InkPlayer.new()
	ink_player.name = "InkPlayer"
	add_child(ink_player)
	ink_player.ink_file = ink_resource

	ink_player.loaded.connect(_on_ink_loaded)
	ink_player.continued.connect(_on_ink_continued)
	ink_player.prompt_choices.connect(_on_ink_prompt_choices)
	ink_player.ended.connect(_on_ink_ended)

	ink_player.create_story()


func _on_ink_loaded(success: bool) -> void:
	if not success:
		push_error("InkBalloon: ink story failed to load")
		queue_free()
		return
	InkActionBridge.bind_all(ink_player)
	_continue_story()


func _continue_story() -> void:
	if ink_player == null:
		return
	ink_player.continue_story()


func _on_ink_continued(text: String, tags: Array) -> void:
	current_text = text
	current_tags = tags
	_parse_tags(tags)

	if text.is_empty():
		is_dialogue_type_end = true
		_on_typing_finished()
		return

	_show_text(text)


func _show_text(text: String) -> void:
	is_waiting_for_input = false
	is_dialogue_type_end = false
	has_choices = false
	balloon.show()
	responses_container.hide()
	_clear_responses()

	dialogue_label.hide()
	dialogue_label.text = "[center]" + text
	dialogue_label.visible_characters = 0
	dialogue_label.show()

	_typing_timer = 0.0
	_typing_speed = TYPING_SPEED
	is_typing = true


func _parse_tags(tags: Array) -> void:
	for tag in tags:
		var tag_str := String(tag)
		if tag_str.begins_with("speaker="):
			var speaker := tag_str.substr(8)
			character_label.visible = not speaker.is_empty()
			character_label.text = "[center][wave amp=25 freq=2]" + tr(speaker, "dialogue") + "[/wave][/center]"
			var nickname := Nickname.get_nickname(speaker)
			character_nickname_label.visible = not nickname.is_empty()
			character_nickname_label.text = nickname
		elif tag_str.begins_with("scgc="):
			var parts := tag_str.substr(5).split("_")
			if parts.size() >= 2:
				_set_scg("scgc", parts[0], parts[1])
		elif tag_str.begins_with("scgl="):
			var parts := tag_str.substr(5).split("_")
			if parts.size() >= 2:
				_set_scg("scgl", parts[0], parts[1])
		elif tag_str.begins_with("scgr="):
			var parts := tag_str.substr(5).split("_")
			if parts.size() >= 2:
				_set_scg("scgr", parts[0], parts[1])
		elif tag_str.begins_with("bg="):
			# Background change signal (future use)
			pass
		elif tag_str.begins_with("sfx="):
			var sfx_name := tag_str.substr(4)
			_play_sfx(sfx_name)
		elif tag_str.begins_with("camera="):
			# Camera control (future use)
			pass


func _set_scg(scg_id: String, scg_appearance: String, scg_file_name: String) -> void:
	var scg := %LeftSCG
	if scg_id == "scgl":
		scg = %LeftSCG
	elif scg_id == "scgr":
		scg = %RightSCG
		if scg_appearance == "slidex":
			scg_appearance += "_scgr"
	elif scg_id == "scgc":
		scg = %CenterSCG

	scg.texture = load("res://graphics/scg/" + scg_file_name + ".png")
	var scg_animation_player: AnimationPlayer = scg.get_node_or_null("AnimationPlayer")
	if scg_animation_player:
		scg_animation_player.play("scg/" + scg_appearance)

	_play_sound_by_scg_animation(scg_appearance)


func _play_sound_by_scg_animation(scg_appearance: String) -> void:
	if scg_appearance == "hop" and hop_sound_player:
		hop_sound_player.play()
	if scg_appearance == "sink" and sink_sound_player:
		sink_sound_player.play()


func _play_sfx(_sfx_name: String) -> void:
	# SFX implementation can be added here
	pass


func _on_ink_prompt_choices(choices: Array) -> void:
	has_choices = true
	pending_choices = choices
	_show_responses(choices)


func _show_responses(choices: Array) -> void:
	_clear_responses()
	for i in range(choices.size()):
		var choice = choices[i]
		var button: Button = response_template.duplicate()
		button.visible = true
		button.response = { "text": choice.text }
		button.pressed.connect(_on_choice_selected.bind(i))
		responses_menu.add_child(button)

	responses_container.modulate.a = 0
	responses_container.scale = Vector2.ZERO
	responses_container.show()

	await get_tree().process_frame
	responses_container.pivot_offset = responses_container.size / 2

	var tween := create_tween().set_parallel(true)
	tween.tween_property(responses_container, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(responses_container, "modulate:a", 1.0, 0.2)

	if responses_menu.get_child_count() > 0:
		responses_menu.get_child(0).grab_focus()


func _clear_responses() -> void:
	for child in responses_menu.get_children():
		if child != response_template:
			child.queue_free()


func _on_choice_selected(index: int) -> void:
	if ink_player == null:
		return
	_hide_responses()
	ink_player.choose_choice_index(index)
	_continue_story()


func _hide_responses() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(responses_container, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(responses_container, "modulate:a", 0.0, 0.15)
	await tween.finished
	responses_container.hide()


func _on_ink_ended() -> void:
	queue_free()


func _process(delta: float) -> void:
	_handle_fast_forward()
	_handle_response_navigation()
	_handle_typing(delta)

	if is_dialogue_type_end:
		dialogue_type_end_timer += delta
		next_indicator.show()
		var frame := int(dialogue_type_end_timer * DIALOGUE_TYPE_END_ANIMATION_SPEED) % NEXT_INDICATOR_FRAME_COUNT + 1
		var path := "res://Story/Dialogues/custom_balloon/assets/sprite/cursor1/dialogue_icon_next_" + str(frame) + ".png"
		next_indicator_icon.texture = load(path)
	else:
		if next_indicator:
			next_indicator.hide()

	check_animation()
	check_move(delta)


func _handle_typing(delta: float) -> void:
	if not is_typing:
		return

	var is_ff := Input.is_key_pressed(KEY_CTRL) and not is_ui_hidden
	var speed := _typing_speed / FF_SPEED if is_ff else _typing_speed

	_typing_timer += delta
	var target_chars := dialogue_label.get_total_character_count()
	if target_chars == 0:
		is_typing = false
		is_dialogue_type_end = true
		_on_typing_finished()
		return

	var chars_to_show := int(_typing_timer / speed)
	if chars_to_show >= target_chars:
		chars_to_show = target_chars
		is_typing = false
		is_dialogue_type_end = true
		_on_typing_finished()

	dialogue_label.visible_characters = chars_to_show


func _on_typing_finished() -> void:
	# Auto-advance tags
	for tag in current_tags:
		var tag_str := String(tag)
		if tag_str == "auto":
			var time := current_text.length() * 0.02
			await get_tree().create_timer(time).timeout
			if is_instance_valid(self):
				_continue_story()
			return
		elif tag_str.begins_with("time="):
			var time := tag_str.substr(5).to_float()
			await get_tree().create_timer(time).timeout
			if is_instance_valid(self):
				_continue_story()
			return

	# If choices are available, show them
	if ink_player != null and ink_player.has_choices:
		has_choices = true
		pending_choices = ink_player.current_choices
		_show_responses(pending_choices)
		return

	is_waiting_for_input = true


func _skip_typing() -> void:
	is_typing = false
	dialogue_label.visible_characters = dialogue_label.get_total_character_count()
	is_dialogue_type_end = true
	_on_typing_finished()


func _handle_fast_forward() -> void:
	if is_ui_hidden:
		return
	var is_ff := Input.is_key_pressed(KEY_CTRL)
	if is_ff:
		Engine.time_scale = FF_SPEED
		if ff_indicator:
			ff_indicator.visible = true
		if is_waiting_for_input and not has_choices:
			_continue_story()
	else:
		Engine.time_scale = 1.0
		if ff_indicator:
			ff_indicator.visible = false


func _handle_response_navigation() -> void:
	if not responses_container.visible or is_ui_hidden:
		return
	var current_focus := get_viewport().gui_get_focus_owner()
	if not current_focus or not current_focus.get_parent() == responses_menu:
		if responses_menu.get_child_count() > 0:
			responses_menu.get_child(0).grab_focus()
		return
	var idx := current_focus.get_index()
	var total := responses_menu.get_child_count()
	if Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		if idx > 0:
			responses_menu.get_child(idx - 1).grab_focus()
			get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		if idx < total - 1:
			responses_menu.get_child(idx + 1).grab_focus()
			get_viewport().set_input_as_handled()
	if Input.is_action_just_pressed("ui_accept"):
		current_focus.emit_signal("pressed")
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		is_ui_hidden = !is_ui_hidden
		%DialogueBox.visible = !is_ui_hidden
		if responses_container.visible or is_ui_hidden:
			responses_container.visible = !is_ui_hidden
		get_viewport().set_input_as_handled()
		return
	if is_ui_hidden:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_J or event.keycode == KEY_ENTER:
			if is_typing:
				_skip_typing()
				get_viewport().set_input_as_handled()
			elif is_waiting_for_input and not has_choices:
				_continue_story()
				get_viewport().set_input_as_handled()
			elif responses_container.visible:
				var current_focus := get_viewport().gui_get_focus_owner()
				if current_focus and current_focus.get_parent() == responses_menu:
					current_focus.emit_signal("pressed")
					get_viewport().set_input_as_handled()


func _on_balloon_gui_input(event: InputEvent) -> void:
	if is_ui_hidden:
		return
	if is_typing:
		var mouse_was_clicked := event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed := event.is_action_pressed(SKIP_ACTION)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			_skip_typing()
			return
	if not is_waiting_for_input:
		return
	if has_choices:
		return
	get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		_continue_story()
	elif event.is_action_pressed(NEXT_ACTION) and get_viewport().gui_get_focus_owner() == balloon:
		_continue_story()


### Animation And Moves (copied from existing balloon)

func get_action_scene():
	return get_tree().root.get_node_or_null("ActionScene")

var character_animation = {}

func play_animation(character_name: String, animation: String, wait_for_end: bool = true, end_animation: String = "idle"):
	if get_action_scene():
		var character = get_action_scene().get_node_or_null(character_name)
		if character:
			var animated_sprite_2d: AnimatedSprite2D = character.get_node("AnimatedSprite2D")
			animated_sprite_2d.play(animation)
			character_animation[character] = {
				end_animation = end_animation,
				wait_for_end = wait_for_end
			}
			if wait_for_end:
				await animation_ended
	else:
		print("action scene is null")

func check_animation():
	for character in character_animation.keys():
		if not character.get_node("AnimatedSprite2D").is_playing():
			var end_animation = character_animation[character].end_animation
			var wait_for_end = character_animation[character].wait_for_end
			character.get_node("AnimatedSprite2D").play(end_animation)
			character_animation.erase(character)
			if wait_for_end:
				animation_ended.emit()

signal animation_ended

var character_move = {}

func move_to_relative_position(character_name: String, relative_position: Vector2, speed: float, wait_for_end: bool = true):
	if get_action_scene():
		var character = get_action_scene().get_node_or_null(character_name)
		await move_to_target_position(character_name, character.global_position + relative_position, speed, wait_for_end)

func move_to_relative_character(character_name: String, other_character_name: String, relative_position: Vector2, speed: float, wait_for_end: bool = true):
	if get_action_scene():
		var other_character = get_action_scene().get_node_or_null(other_character_name)
		await move_to_target_position(character_name, other_character.global_position + relative_position, speed, wait_for_end)

func move_to_target_position(character_name: String, target_position: Vector2, speed: float, wait_for_end: bool = true):
	if get_action_scene():
		var character = get_action_scene().get_node_or_null(character_name)
		if character:
			character_move.clear()
			character.get_node("AnimatedSprite2D").play("walk")
			character_move[character] = {
				target_position = target_position,
				speed = speed
			}
			if wait_for_end:
				await move_ended
	else:
		print("action scene is null")

func check_move(delta):
	for character in character_move.keys():
		var target_position = character_move[character].target_position
		var speed = character_move[character].speed
		var move_vector: Vector2 = target_position - character.global_position
		if move_vector.length() < speed * delta:
			character.global_position = target_position
			character.get_node("AnimatedSprite2D").play("idle")
			move_ended.emit()
		else:
			character.global_position += move_vector.normalized() * (speed * delta)

signal move_ended

### FadeInOut

func fade_out():
	await get_tree().process_frame
	fade_ended.emit()

func fade_in():
	await get_tree().process_frame
	fade_ended.emit()

func fade_out_swipe(_direction):
	await get_tree().process_frame
	fade_ended.emit()

func fade_in_swipe(_direction):
	await get_tree().process_frame
	fade_ended.emit()

func fade_end_callback():
	fade_ended.emit()

func set_speaker(character_name: String, speaker_name: String):
	Nickname.set_nickname(character_name, speaker_name)

signal fade_ended

### Camera Control

func set_camera_target_node(node_name):
	set_camera_target_node_and_position(node_name, Vector2.ZERO)

func set_camera_target_node_and_position(node_name, target_position):
	get_action_scene().get_node("%MainCamera").set_target_node(get_action_scene().get_node(node_name), target_position)

func reset_camera_target_node():
	get_action_scene().get_node("%MainCamera").reset_target_node()
