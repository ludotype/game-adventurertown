extends Node2D

## PlaceScene
## 장소 씬의 기본 템플릿. 배경 그림과 NPC 오버레이를 표시합니다.

@export var place_id: String = ""
@export var default_time_of_day: String = "morning"

@onready var background_sprite: Sprite2D = $BackgroundSprite
@onready var npc_portrait: TextureRect = $NPCOverlay/NPCPortrait
@onready var npc_name_label: Label = $NPCOverlay/NPCNameLabel
@onready var npc_overlay: Control = $NPCOverlay

var _spawner: Node


func _ready() -> void:
	# NPCSpawner 설정
	_spawner = preload("res://scripts/game/npc_spawner.gd").new()
	_spawner.place_id = place_id
	_spawner.npc_spawned.connect(_on_npc_spawned)
	_spawner.empty_spawned.connect(_on_empty_spawned)
	add_child(_spawner)

	# 장소 데이터 로드 및 배경 설정
	_load_place()

	# NPC 추첨 실행
	# 실제 게임에서는 TimeSystem 등에서 current_time을 받아와야 함
	_spawner.spawn(default_time_of_day, _get_current_story_flags())


func _load_place() -> void:
	var place_data := PlaceRegistry.get_place(place_id)
	if place_data.is_empty():
		push_error("PlaceScene: unknown place_id: " + place_id)
		return

	# 배경 그림 설정
	var bg_path: String = place_data.get("background_path", "")
	if not bg_path.is_empty() and ResourceLoader.exists(bg_path):
		background_sprite.texture = load(bg_path)

	# BGM 설정 (선택사항)
	var bgm: String = place_data.get("bgm", "")
	if not bgm.is_empty() and has_node("/root/BGMManager"):
		BGMManager.play(bgm)


func _on_npc_spawned(npc_data: Dictionary) -> void:
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
	npc_overlay.visible = false
	print("PlaceScene: no NPC spawned (empty)")


## TODO: 실제 스토리 플래그 시스템과 연동
func _get_current_story_flags() -> Array:
	if has_node("/root/Flags"):
		return Flags.get_active_flags()
	return []
