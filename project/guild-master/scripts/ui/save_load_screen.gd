extends CanvasLayer

# 모드: SAVE(0), LOAD(1)
var mode: int = 0
var selected_slot: int = -1

# 확인창 목적 정의
enum ConfirmPurpose { NONE, OVERWRITE, LOAD, DELETE }
var current_purpose: ConfirmPurpose = ConfirmPurpose.NONE

@onready var grid: GridContainer = %SlotGrid
@onready var title_label: Label = %Title
@onready var details_label: RichTextLabel = %DetailsText
@onready var context_menu: Control = %ContextMenu
@onready var overwrite_button: Button = $ContextMenu/VBox/OverwriteButton
@onready var load_button: Button = $ContextMenu/VBox/LoadButton
@onready var delete_button: Button = %DeleteButton

# 커스텀 다이얼로그 노드
@onready var confirm_dialog: Control = %CustomConfirmDialog
@onready var confirm_message: Label = %ConfirmMessage

const SLOT_SCENE = preload("res://scenes/ui/save_slot.tscn")

func _ready() -> void:
	# 일시정지 중에도 UI가 작동하도록 설정
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 초기화
	_refresh_slots()
	context_menu.hide()
	delete_button.hide()
	confirm_dialog.hide()
	
	# 타이틀 화면에서 진입했는지 확인
	var is_title = get_tree().current_scene.scene_file_path == "res://scenes/ui/title_screen.tscn"
	
	if is_title:
		mode = 1 # 타이틀에서는 무조건 LOAD 모드로 고정
		title_label.text = tr("UI_LOAD")
		overwrite_button.hide() # 덮어쓰기 버튼 숨김
	else:
		if mode == 0:
			title_label.text = tr("UI_SAVE")
		else:
			title_label.text = tr("UI_LOAD")

func _refresh_slots() -> void:
	for child in grid.get_children():
		child.queue_free()
	
	for i in range(99):
		var slot = SLOT_SCENE.instantiate()
		grid.add_child(slot)
		slot.setup(i)
		slot.slot_pressed.connect(_on_slot_pressed)

func _on_slot_pressed(index: int) -> void:
	selected_slot = index
	var sm = get_node_or_null("/root/SaveManager")
	var info = sm.get_slot_info(index) if sm else {}
	
	_update_details(info)
	
	var slot_node = grid.get_child(index)
	context_menu.global_position = slot_node.global_position + Vector2(0, slot_node.size.y / 2)
	context_menu.show()
	
	delete_button.visible = !info.is_empty()
	
	var is_title = get_tree().current_scene.scene_file_path == "res://scenes/ui/title_screen.tscn"
	if not is_title and mode == 0 and info.is_empty():
		_execute_save()
		context_menu.hide()

func _update_details(info: Dictionary) -> void:
	if info.is_empty():
		details_label.text = "[center]" + tr("UI_EMPTY_SLOT") + "[/center]"
	else:
		var ts = info.get("timestamp", {})
		var time_str = "Unknown"
		if not ts.is_empty():
			time_str = "%d-%02d-%02d %02d:%02d:%02d" % [
				ts.get("year", 0), ts.get("month", 0), ts.get("day", 0),
				ts.get("hour", 0), ts.get("minute", 0), ts.get("second", 0)
			]
		
		var day_str = tr("UI_DAY_FORMAT") % info.get("day", 1)
		var game_time_str = tr("UI_GAME_TIME") % [info.get("hour", 22), info.get("minute", 0)]
		var rank_str = tr("UI_RANK") % str(info.get("rank", "D"))
		var sanity_str = tr("UI_SANITY") % info.get("sanity", 100)
		var saved_at_str = tr("UI_SAVED_AT") % time_str
		
		details_label.text = "[center][b]%s[/b]
%s

%s
%s

[color=gray][font_size=14]%s[/font_size][/color][/center]" % [
			day_str, game_time_str, rank_str, sanity_str, saved_at_str
		]

func _on_overwrite_pressed() -> void:
	if get_tree().current_scene.scene_file_path == "res://scenes/ui/title_screen.tscn": return
	current_purpose = ConfirmPurpose.OVERWRITE
	confirm_message.text = tr("CONFIRM_OVERWRITE")
	confirm_dialog.show()

func _on_load_pressed() -> void:
	if mode == 1:
		_execute_load()
	else:
		current_purpose = ConfirmPurpose.LOAD
		confirm_message.text = tr("CONFIRM_LOAD")
		confirm_dialog.show()

func _on_delete_pressed() -> void:
	current_purpose = ConfirmPurpose.DELETE
	confirm_message.text = tr("CONFIRM_DELETE")
	confirm_dialog.show()

func _on_confirmed() -> void:
	match current_purpose:
		ConfirmPurpose.OVERWRITE:
			_execute_save()
		ConfirmPurpose.LOAD:
			_execute_load()
		ConfirmPurpose.DELETE:
			_execute_delete()
	confirm_dialog.hide()
	current_purpose = ConfirmPurpose.NONE

func _on_confirm_cancel_pressed() -> void:
	confirm_dialog.hide()
	current_purpose = ConfirmPurpose.NONE

func _execute_save() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.save_game(selected_slot):
		_refresh_slots()
		_update_details(sm.get_slot_info(selected_slot))

func _execute_load() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.load_game(selected_slot):
		queue_free()

func _execute_delete() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		sm.delete_save(selected_slot)
		_refresh_slots()
		_update_details({})
		delete_button.hide()
		context_menu.hide()

func _on_back_pressed() -> void:
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if context_menu.visible and not context_menu.get_global_rect().has_point(event.position):
			if not delete_button.get_global_rect().has_point(event.position) and not confirm_dialog.visible:
				context_menu.hide()
