extends Control

## SplashScreen: 게임 시작 시 회사 로고를 연출하고 타이틀 화면으로 넘깁니다.

@onready var logo: TextureRect = %Logo
@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var sparks: GPUParticles2D = get_node_or_null("%Sparks")
@onready var welding_point: GPUParticles2D = get_node_or_null("%WeldingPoint")

func _ready() -> void:
	# 칠흑 같은 어둠에서 시작
	logo.material.set_shader_parameter("progress", 0.0)
	if sparks: sparks.emitting = false
	if welding_point: welding_point.emitting = false
	
	# 인트로 애니메이션 재생
	anim_player.play("intro_sequence")
	anim_player.animation_finished.connect(_on_intro_finished)

func _process(_delta: float) -> void:
	# 쉐이더의 진행도를 읽어와서 파티클 위치를 업데이트
	if sparks and logo.material:
		var raw_progress = logo.material.get_shader_parameter("progress")
		# 쉐이더 내부 로직인 (progress * 1.2 - 0.1)과 완벽히 동기화
		var p = raw_progress * 1.2 - 0.1
		
		if raw_progress > 0.01 and raw_progress < 0.99:
			sparks.emitting = true
			if welding_point: welding_point.emitting = true
			
			var rect = logo.get_global_rect()
			# X 좌표 정밀 동기화
			var current_x = rect.position.x + (rect.size.x * p)
			
			# 메인 스파크 (로고 박스 높이에 맞춤)
			sparks.global_position.x = current_x
			sparks.global_position.y = rect.position.y + (rect.size.y / 2.0)
			
			# 레이저 용접 포인트 (로고 박스의 상단 테두리 한 점)
			if welding_point:
				welding_point.global_position.x = current_x
				# 로고 박스 높이(약 100px)를 고려한 상단 위치 (중앙에서 50px 위)
				welding_point.global_position.y = (rect.position.y + rect.size.y / 2.0) - 50.0
		else:
			sparks.emitting = false
			if welding_point: welding_point.emitting = false

func _input(event: InputEvent) -> void:
	# ESC 키를 누르면 즉시 타이틀로 전환
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_go_to_title()

func _on_intro_finished(_anim_name: String) -> void:
	# 로고가 사라지는 연출(애니메이션 끝부분) 이후 아주 짧게 대기 후 전환
	_go_to_title()

func _go_to_title() -> void:
	# 중복 호출 방지
	if is_queued_for_deletion(): return
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
