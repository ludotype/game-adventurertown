extends CanvasLayer

# 여기에 간단한 변수를 추가해주세요.
var var_in_balloon

## The action to use for advancing the dialogue
const NEXT_ACTION = &"ui_accept"

## The action to use to skip typing the dialogue
const SKIP_ACTION = &"ui_cancel"

# 패스트 포워드 배속 설정
const FF_SPEED = 4.0

@onready var balloon: Control = %Balloon
@onready var character_label: RichTextLabel = %CharacterLabel
@onready var character_nickname_label: Label = %CharacterNicknameLabel
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var responses_container: PanelContainer = %Responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu
@onready var ff_indicator: Label = %FFIndicator

@export var hop_sound:AudioStream = null
var hop_sound_player:AudioStreamPlayer = null
@export var sink_sound:AudioStream = null
var sink_sound_player:AudioStreamPlayer = null

## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

# UI 숨김 상태 관리
var is_ui_hidden: bool = false

## The current line
var dialogue_line: DialogueLine:
	set(next_dialogue_line):
		is_waiting_for_input = false
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()

		# The dialogue has finished so close the balloon
		if not next_dialogue_line:
			queue_free()
			return

		# If the node isn't ready yet then none of the labels will be ready yet either
		if not is_node_ready():
			await ready

		dialogue_line = next_dialogue_line
		
		if dialogue_line.text.begins_with("[scg"):
			var scg_args = dialogue_line.text.substr(1, dialogue_line.text.length() - 2).split(' ')
			
			set_scg(scg_args[0], scg_args[1], scg_args[2])
			next(dialogue_line.next_id)
			return

		character_label.visible = not dialogue_line.character.is_empty()
		character_label.text = "[center][wave amp=25 freq=2]" + tr(dialogue_line.character, "dialogue") + "[/wave][/center]"
		
		var nickname = Nickname.get_nickname(dialogue_line.character)
		character_nickname_label.visible = not nickname.is_empty()
		character_nickname_label.text = nickname

		dialogue_label.hide()
		dialogue_label.dialogue_line = dialogue_line

		responses_container.hide()
		responses_menu.responses = dialogue_line.responses

		# Show our balloon
		balloon.show()
		will_hide_balloon = false

		dialogue_label.show()
		if not dialogue_line.text.is_empty():
			dialogue_line.text = "[center]" + dialogue_line.text
			dialogue_label.type_out()
			is_dialogue_type_end = false
			await dialogue_label.finished_typing
			is_dialogue_type_end = true

		# Wait for input
		if dialogue_line.responses.size() > 0:
			balloon.focus_mode = Control.FOCUS_NONE
			_show_responses()
			# 첫 번째 선택지에 포커스 강제 할당
			await get_tree().process_frame
			if responses_menu.get_child_count() > 0:
				responses_menu.get_child(0).grab_focus()
		elif dialogue_line.time != "":
			var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
			await get_tree().create_timer(time).timeout
			next(dialogue_line.next_id)
		else:
			is_waiting_for_input = true
			balloon.focus_mode = Control.FOCUS_ALL
			balloon.grab_focus()
	get:
		return dialogue_line


func _ready() -> void:
	balloon.hide()
	# 루트에서 쉽게 찾을 수 있도록 이름 설정
	name = "CustomBalloon"
	
	responses_menu.response_template = %ResponseTemplate
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)
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
	# 벌룬이 닫힐 때 반드시 시간 배속 초기화
	Engine.time_scale = 1.0

func _unhandled_input(event: InputEvent) -> void:
	# 탭(Tab) 키로 UI 숨기기 토글
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		is_ui_hidden = !is_ui_hidden
		%DialogueBox.visible = !is_ui_hidden
		if responses_container.visible or is_ui_hidden:
			responses_container.visible = !is_ui_hidden
		get_viewport().set_input_as_handled()
		return

	# UI가 숨겨진 상태에서는 입력을 처리하지 않음
	if is_ui_hidden: return

	# [한 손 조작 및 입력 이원화 로직]
	# Space, J, Enter 키로 대화 진행
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_J or event.keycode == KEY_ENTER:
			if dialogue_label.is_typing:
				dialogue_label.skip_typing()
				get_viewport().set_input_as_handled()
			elif is_waiting_for_input and dialogue_line.responses.size() == 0:
				next(dialogue_line.next_id)
				get_viewport().set_input_as_handled()
			elif responses_container.visible:
				# 선택지가 있을 때는 포커스된 버튼 실행
				var current_focus = get_viewport().gui_get_focus_owner()
				if current_focus and current_focus.get_parent() == responses_menu:
					current_focus.emit_signal("pressed")
					get_viewport().set_input_as_handled()

var is_dialogue_type_end = false
var dialogue_type_end_timer = 0
var dialogue_type_end_animation_speed = 30
var dialogue_type_end_img_config = {
	'original_width': 64, # 이미지의 원래 가로세로 크기
	'original_height': 64,
	'width': 64, # 표시 할 사이즈 (1080p에 맞춰 키움)
	'height': 64,
	'offset_y': -40 # Y 위치 조정 (1080p에 맞춰 조정)
}
@onready var dialogue_type_end_img_config_text = (
	"=top,top," + str(dialogue_type_end_img_config.width) + "x" + str(dialogue_type_end_img_config.height - dialogue_type_end_img_config.offset_y) +
	" region=0," + str(dialogue_type_end_img_config.offset_y) + "," 
	+ str(dialogue_type_end_img_config.original_width) + "," + str(dialogue_type_end_img_config.original_height - dialogue_type_end_img_config.original_height*dialogue_type_end_img_config.offset_y/dialogue_type_end_img_config.height)
)

@onready var next_indicator: Control = %NextIndicator
@onready var next_indicator_icon: TextureRect = %NextIndicator/Icon

func _process(delta):
	_handle_fast_forward()
	_handle_response_navigation()
	
	if is_dialogue_type_end:
		dialogue_type_end_timer += delta
		
		# 인디케이터 노드 표시 및 애니메이션
		next_indicator.show()
		var frame = int(dialogue_type_end_timer * dialogue_type_end_animation_speed) % 23 + 1
		var path = "res://assets/sprites/ui/dialogue/cursor/dialogue_icon_next_" + str(frame) + ".png"
		next_indicator_icon.texture = load(path)
	else:
		if next_indicator: next_indicator.hide()
		
	check_animation()
	check_move(delta)

func _handle_fast_forward() -> void:
	if is_ui_hidden: return # 숨겨진 상태에선 FF 방지
	
	# 컨트롤 키가 눌려있는지 확인
	var is_ff = Input.is_key_pressed(KEY_CTRL)
	
	if is_ff:
		Engine.time_scale = FF_SPEED
		if ff_indicator: ff_indicator.visible = true
		
		# 만약 대기가 끝난 상태라면 자동으로 다음으로 넘김
		if is_waiting_for_input and dialogue_line.responses.size() == 0:
			next(dialogue_line.next_id)
	else:
		Engine.time_scale = 1.0
		if ff_indicator: ff_indicator.visible = false

# 선택지 WASD 조작 처리
func _handle_response_navigation() -> void:
	if not responses_container.visible or is_ui_hidden: return
	
	var current_focus = get_viewport().gui_get_focus_owner()
	if not current_focus or not current_focus.get_parent() == responses_menu:
		# 포커스가 없거나 메뉴 밖이면 첫 번째 버튼으로 강제 할당
		if responses_menu.get_child_count() > 0:
			responses_menu.get_child(0).grab_focus()
		return

	var idx = current_focus.get_index()
	var total = responses_menu.get_child_count()

	if Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		if idx > 0:
			responses_menu.get_child(idx - 1).grab_focus()
			get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		if idx < total - 1:
			responses_menu.get_child(idx + 1).grab_focus()
			get_viewport().set_input_as_handled()
	
	# 스페이스/엔터로 선택
	if Input.is_action_just_pressed("ui_accept"):
		current_focus.emit_signal("pressed")
		get_viewport().set_input_as_handled()

## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	temporary_game_states =  [self] + extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)


## Go to the next line
func next(next_id: String) -> void:
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)


func set_scg(scg_id, scg_appearance, scg_file_name):
	var scg = %LeftSCG
	if scg_id == "scgl":
		scg = %LeftSCG
	if scg_id == "scgr":
		scg = %RightSCG
		if scg_appearance == 'slidex':
			scg_appearance += '_scgr'
	if scg_id == "scgc":
		scg = %CenterSCG
	
	# 캐릭터 Standing CG 이미지 동적 로드 로직
	# 1. res://graphics/scg/{character_name}/{expression}.png (폴더 매핑 우선)
	# 2. res://graphics/scg/{character_name}_{expression}.png (기존 플랫 매핑)
	# 3. res://graphics/scg/{scg_file_name}.png (폴오버 기본 로드)
	var scg_texture: Texture2D = null
	var paths_to_try: Array[String] = []
	
	if "/" in scg_file_name or "_" in scg_file_name:
		var character_name = ""
		var expression = ""
		if "/" in scg_file_name:
			var parts = scg_file_name.split("/")
			character_name = parts[0]
			expression = parts[1]
		else:
			var parts = scg_file_name.split("_", true, 1)
			character_name = parts[0]
			expression = parts[1]
			
		paths_to_try.append("res://graphics/scg/" + character_name + "/" + expression + ".png")
		paths_to_try.append("res://graphics/scg/" + character_name + "_" + expression + ".png")
	
	paths_to_try.append("res://graphics/scg/" + scg_file_name + ".png")
	
	for path in paths_to_try:
		if ResourceLoader.exists(path):
			scg_texture = load(path)
			break
			
	if scg_texture == null:
		# 파일이 디스크에 존재하지 않더라도 Godot 엔진 내에서 에러 로그를 출력할 수 있게 기본 경로 로드 시도
		scg_texture = load("res://graphics/scg/" + scg_file_name + ".png")
		
	scg.texture = scg_texture
	var scg_animation_player:AnimationPlayer = scg.get_node_or_null("AnimationPlayer")
	if scg_animation_player:
		scg_animation_player.play("scg/" + scg_appearance)
	
	play_sound_by_scg_animation(scg_appearance)

func play_sound_by_scg_animation(scg_appearance:String):
	if scg_appearance == "hop" && hop_sound_player:
		hop_sound_player.play()
	if scg_appearance == "sink" && sink_sound_player:
		sink_sound_player.play()


### Animation And Moves

func get_action_scene():
	return get_tree().root.get_node_or_null("ActionScene")

var character_animation = {}

func play_animation(character_name:String, animation:String, wait_for_end:bool = true, end_animation:String = "idle"):
	if get_action_scene():
		var character = get_action_scene().get_node_or_null(character_name)
		if character:
			var animated_sprite_2d:AnimatedSprite2D = character.get_node("AnimatedSprite2D")
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
		if !character.get_node("AnimatedSprite2D").is_playing():
			var end_animation = character_animation[character].end_animation
			var wait_for_end = character_animation[character].wait_for_end
			character.get_node("AnimatedSprite2D").play(end_animation)
			character_animation.erase(character)
			if wait_for_end:
				animation_ended.emit()

signal animation_ended


var character_move = {}

func move_to_relative_position(character_name:String, relative_position:Vector2, speed:float, wait_for_end:bool = true):
	if get_action_scene():
		var character = get_action_scene().get_node_or_null(character_name)
		await move_to_target_position(character_name, character.global_position + relative_position, speed, wait_for_end)

func move_to_relative_character(character_name:String, other_character_name:String, relative_position:Vector2, speed:float, wait_for_end:bool = true):
	if get_action_scene():
		var other_character = get_action_scene().get_node_or_null(other_character_name)
		await move_to_target_position(character_name, other_character.global_position + relative_position, speed, wait_for_end)		

func move_to_target_position(character_name:String, target_position:Vector2, speed:float, wait_for_end:bool = true):
	if get_action_scene():
		var character = get_action_scene().get_node_or_null(character_name)
		if character:
			character_move.clear()
			character.get_node("AnimatedSprite2D").play("walk")
			character_move[character] = {
					target_position= target_position,
					speed= speed
				}
			if wait_for_end:
				await move_ended
	else:
		print("action scene is null")

func check_move(delta):
	for character in character_move.keys():
		var target_position = character_move[character].target_position
		var speed = character_move[character].speed
		var move_vector:Vector2 = target_position - character.global_position
		if move_vector.length() < speed * delta:
			character.global_position = target_position
			character.get_node("AnimatedSprite2D").play("idle")
			move_ended.emit()
		else:
			character.global_position += move_vector.normalized() * (speed * delta)
		 
	
signal move_ended



### FadeInOut

func fade_out():
	# FadeInOut removed. Dummy implementation.
	await get_tree().process_frame
	fade_ended.emit()
	
func fade_in():
	# FadeInOut removed. Dummy implementation.
	await get_tree().process_frame
	fade_ended.emit()
	
#direction => 0:좌->우, 1:우->좌ㅓ, 2:하->상, 3:상->하
func fade_out_swipe(_direction):
	# FadeInOut removed. Dummy implementation.
	await get_tree().process_frame
	fade_ended.emit()
	
func fade_in_swipe(_direction):
	# FadeInOut removed. Dummy implementation.
	await get_tree().process_frame
	fade_ended.emit()
	
func fade_end_callback():
	fade_ended.emit()

func set_speaker(character_name:String, speaker_name:String):
	Nickname.set_nickname(character_name, speaker_name)

signal fade_ended


### Camera Control

func set_camera_target_node(node_name):
	set_camera_target_node_and_position(node_name, Vector2.ZERO)

func set_camera_target_node_and_position(node_name, target_position):
	get_action_scene().get_node("%MainCamera").set_target_node(get_action_scene().get_node(node_name), target_position)

func reset_camera_target_node():
	get_action_scene().get_node("%MainCamera").reset_target_node()


### Signals


func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false


func _on_balloon_gui_input(event: InputEvent) -> void:
	if is_ui_hidden: return # 숨겨진 상태에선 입력 무시
	
	# See if we need to skip typing of the dialogue
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(SKIP_ACTION)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(NEXT_ACTION) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	await _hide_responses()
	next(response.next_id)

func random_range(p_start, p_end):
	return randi_range(p_start, p_end)


### Response Animations

func _show_responses() -> void:
	responses_container.modulate.a = 0
	responses_container.scale = Vector2.ZERO
	responses_container.show()
	
	# 레이아웃 계산을 위해 한 프레임 대기 후 피벗 설정
	await get_tree().process_frame
	responses_container.pivot_offset = responses_container.size / 2
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(responses_container, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(responses_container, "modulate:a", 1.0, 0.2)

func _hide_responses() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(responses_container, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(responses_container, "modulate:a", 0.0, 0.15)
	await tween.finished
	responses_container.hide()
