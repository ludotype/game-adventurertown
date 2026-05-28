# 🤖 Kimi 2.6 Agent Instructions: City Map Editor Refactoring (Sidebar Redesign)

## 1. 역할 정의 (Role Definition)
당신은 Godot 4.x 에디터 플러그인 개발의 달인인 **구현 엔지니어(Implementation Engineer)**입니다. 

당신의 새로운 임무는 Antigravity가 설계한 리파인 스펙(`implementation_plan.md`)에 따라, 맵 노드를 슬림화하고 에디터 도크 우측에 **상세 정보 상세 속성 패널(Sidebar Inspector)**을 구축하여 이전 구현의 투박함과 데이터 무결성 결함을 완전히 리팩토링하여 고도화하는 것입니다.

---

## 2. 핵심 리팩토링 구현 사양 및 GDScript 가이드

### 2.1 `map_place_node.gd` (슬림 노드로 개편)
노드 내부에 더 이상 `LineEdit`이나 버튼을 두지 말고, 런타임 라벨 2개만 배치하십시오.
```gdscript
@tool
extends GraphNode

var place_id: String = ""
var display_name_kr: String = ""
var base_npc: Array = []
var events: Array = []

func _ready() -> void:
    set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
    _update_node_view()

func setup_node(data: Dictionary) -> void:
    place_id = data.get("id", "")
    display_name_kr = data.get("display_name_kr", "")
    base_npc = data.get("base_npc", [])
    events = data.get("events", [])
    
    # 중요: 노드의 물리적 name을 place_id와 완전히 동기화하여 @@ 임시 노드명 생성을 방지
    name = place_id
    
    position_offset = Vector2(
        data.get("coordinate", {}).get("x", 100),
        data.get("coordinate", {}).get("y", 100)
    )
    _update_node_view()

func _update_node_view() -> void:
    title = display_name_kr if display_name_kr != "" else place_id
    
    # 기존 자식 노드 제거 후 깔끔한 정보 라벨들만 렌더링
    for child in get_children():
        child.queue_free()
        
    var vbox = VBoxContainer.new()
    add_child(vbox)
    
    var label_id = Label.new()
    label_id.text = "ID: " + place_id
    label_id.modulate = Color(0.7, 0.7, 0.7) # 흐린 회색으로 서브 텍스트 처리
    vbox.add_child(label_id)
```

### 2.2 `map_editor_dock.tscn` (HSplitContainer 레이아웃 개편)
도크의 상위 레이아웃을 개편하여 우측에 사이드바 컨테이너를 신설합니다.
```
- MapEditorDock (Control)
  - Toolbar (HBoxContainer)
    - SaveButton
    - LoadButton
  - HSplitContainer (가로 분할 컨테이너)
    - GraphEdit (좌측 75% 영역)
    - Sidebar (PanelContainer 또는 ScrollContainer - 우측 25% 영역)
      - SidebarContent (VBoxContainer)
        - TitleLabel ("장소 정보 상세")
        - IDLineEdit (장소 ID 입력)
        - NameLineEdit (장소 한글명 입력)
        - NPCLineEdit (상주 NPC 입력)
        - EventSection (VBoxContainer)
          - AddEventButton ("+ 이벤트 추가")
          - EventListContainer (VBoxContainer)
```

### 2.3 `map_editor_dock.gd` (상세 패널 바인딩 및 저장 보완)
노드가 클릭되어 활성화될 때 우측 상세 패널과 데이터를 바인딩합니다.
```gdscript
@tool
extends Control

@onready var graph_edit: GraphEdit = $HSplitContainer/GraphEdit
@onready var sidebar: Control = $HSplitContainer/Sidebar
@onready var id_edit: LineEdit = $HSplitContainer/Sidebar/SidebarContent/IDLineEdit
@onready var name_edit: LineEdit = $HSplitContainer/Sidebar/SidebarContent/NameLineEdit
@onready var npc_edit: LineEdit = $HSplitContainer/Sidebar/SidebarContent/NPCLineEdit
@onready var event_list_container: VBoxContainer = $HSplitContainer/Sidebar/SidebarContent/EventSection/EventListContainer
@onready var add_event_button: Button = $HSplitContainer/Sidebar/SidebarContent/EventSection/AddEventButton

var selected_node: GraphNode = null
var _connections: Array[Dictionary] = []
var _node_counter: int = 0

func _ready() -> void:
    # 기존 시그널들 매핑 유지...
    graph_edit.node_selected.connect(_on_node_selected)
    graph_edit.node_deselected.connect(_on_node_deselected)
    
    id_edit.text_changed.connect(_on_id_changed)
    name_edit.text_changed.connect(_on_name_changed)
    npc_edit.text_changed.connect(_on_npc_changed)
    add_event_button.pressed.connect(_on_add_event_pressed)
    
    sidebar.hide() # 처음에는 상세창 숨김

func _on_node_selected(node: Node) -> void:
    if node is GraphNode:
        selected_node = node
        sidebar.show()
        _load_node_to_sidebar()

func _on_node_deselected(node: Node) -> void:
    if selected_node == node:
        selected_node = null
        sidebar.hide()

func _load_node_to_sidebar() -> void:
    if not selected_node:
        return
    id_edit.text = selected_node.place_id
    name_edit.text = selected_node.display_name_kr
    npc_edit.text = ", ".join(selected_node.base_npc)
    _refresh_sidebar_event_list()

func _on_id_changed(new_text: String) -> void:
    if selected_node:
        selected_node.place_id = new_text
        selected_node.name = new_text # 중요: Godot 노드명도 강제 동기화
        selected_node._update_node_view()

func _on_name_changed(new_text: String) -> void:
    if selected_node:
        selected_node.display_name_kr = new_text
        selected_node._update_node_view()

func _on_npc_changed(new_text: String) -> void:
    if selected_node:
        selected_node.base_npc.clear()
        for s in new_text.split(","):
            var trimmed := s.strip_edges()
            if trimmed != "":
                selected_node.base_npc.append(trimmed)

func _on_add_event_pressed() -> void:
    if not selected_node:
        return
    selected_node.events.append({
        "event_id": "evt_new_" + str(selected_node.events.size()),
        "display_name": "새 이벤트",
        "dialogue_file": "",
        "dialogue_title": "",
        "triggers": {}
    })
    _refresh_sidebar_event_list()

func _refresh_sidebar_event_list() -> void:
    for child in event_list_container.get_children():
        child.queue_free()
        
    if not selected_node:
        return
        
    for i in range(selected_node.events.size()):
        var ev = selected_node.events[i]
        var hbox = HBoxContainer.new()
        event_list_container.add_child(hbox)
        
        # 이벤트 명 수정 LineEdit
        var edit_ev_name = LineEdit.new()
        edit_ev_name.text = ev.get("display_name", "")
        edit_ev_name.placeholder_text = "이벤트명"
        edit_ev_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        edit_ev_name.text_changed.connect(func(new_text: String):
            ev["display_name"] = new_text
        )
        hbox.add_child(edit_ev_name)
        
        # 파일 점프용 Dialogue 버튼
        var btn_jump = Button.new()
        btn_jump.text = "점프"
        btn_jump.pressed.connect(func():
            _jump_to_dialogue(ev.get("dialogue_file", ""), ev.get("dialogue_title", ""))
        )
        hbox.add_child(btn_jump)
        
        # 삭제 버튼
        var btn_del = Button.new()
        btn_del.text = "🗑️"
        btn_del.pressed.connect(func():
            selected_node.events.remove_at(i)
            _refresh_sidebar_event_list()
        )
        hbox.add_child(btn_del)
```

---

## 3. 단계별 수행 지시서 (Step-by-Step Prompt Set)

이 텍스트 프롬프트를 차례대로 실행하여 맵 에디터 리팩토링의 품질을 극대화하십시오.

### 📋 STEP 1: map_editor_dock.tscn을 HSplitContainer 2계층 구조로 레이아웃 개편
> **지시**: 
> "map_editor_dock.tscn 레이아웃을 개편하십시오. HSplitContainer를 최상위 Toolbar 밑에 두고, 좌측 75% 공간에 GraphEdit를, 우측 25% 공간에 Sidebar PanelContainer 및 ScrollContainer를 배치하십시오. 우측 Sidebar의 세부 노드로 TitleLabel, IDLineEdit, NameLineEdit, NPCLineEdit, EventListContainer, AddEventButton을 명세서 2.2 레이아웃 설계에 맞게 완벽히 계층 구조로 정돈 배치하십시오."

### 📋 STEP 2: map_place_node.gd를 슬림 라벨 뷰 컴포넌트로 전면 교체
> **지시**: 
> "map_place_node.gd 파일을 명세서 2.1 설계안으로 전면 교체 리팩토링하십시오. 노드 내부에서 LineEdit나 Button들을 모두 소멸시키고, 오직 장소 한글 표시명(title)과 ID(Label)만을 표시하는 심플하고 아름다운 슬림 노드로 렌더링하도록 작성하십시오. 또한 노드가 초기화되거나 ID가 변경될 때 Godot의 물리 노드 이름(name)을 장소의 place_id로 강제 동기화하는 로직을 견고히 구현하십시오."

### 📋 STEP 3: 노드 선택(node_selected/deselected) 시그널 연동 및 사이드바 바인딩
> **지시**: 
> "map_editor_dock.gd 스크립트에서 GraphEdit의 node_selected 및 node_deselected 시그널을 연동하십시오. 노드가 마우스 클릭으로 선택되었을 때 우측 상세 사이드바가 슬라이드 인(Show)되도록 연동하고, 선택된 노드의 ID, 이름, NPC 텍스트 필드를 사이드바 속성 입력창들과 정확히 바인딩(Binding)하여 데이터의 양방향 싱크를 완성하십시오. 빈 공간 클릭 시 상세창이 정상 소멸하는지 확인하십시오."

### 📋 STEP 4: 사이드바 이벤트 리스트업, 추가, 삭제, 대화 파일 점프 최종 고도화
> **지시**: 
> "사이드바 내부의 AddEventButton 및 EventListContainer에 대한 이벤트 추가/삭제/수정 조작 로직을 완벽히 구축하십시오. 사이드바 내 각 이벤트 줄에 이벤트 한글 이름 입력창, Dialogue 에디터 탭으로 포커싱을 전환하여 점프해 주는 점프 버튼, 그리고 이벤트를 삭제하는 🗑️ 휴지통 버튼을 각각 바인딩하여 복잡성 없이 안정되게 작동하도록 완료하십시오."

### 📋 STEP 5: 세이브/로드 시 place_id 기반 커넥션 파일 입출력 무결성 확보
> **지시**: 
> "이제 노드들의 Godot 물리 이름(name)이 place_id로 강제 일치되므로, connections.json 입출력 시 '@@35' 등의 임시 이름이 아닌 실제 장소 ID(fireside_amber 등)가 완벽히 저장되도록 저장/로드 코드를 연동하고, 저장된 JSON 파일들을 육안 검수하여 데이터 싱크 무결성을 최종 검증하십시오."
