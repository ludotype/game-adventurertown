# 🧙‍♂️ [WIZARD MODE] Kimi 작업용 대화 이벤트 맵 에디터 UX 고도화 태스크 카드

이 작업 지침은 Kimi가 개입하여 **1) 캔버스 노드 카드 슬림화**, **2) 대화 파일 탐색 단추(📁) 연동**, **3) 파일/라벨 자동 생성 및 정밀 점프(🔗) 고도화**를 무결하게 빌드하고 검증하도록 구조화된 태스크 명세서입니다.

---

## 📌 Phase 1: 캔버스 노드 카드 시각화 슬림화 (`map_place_node.gd`)
- [ ] **1.1 개별 이벤트 나열 루프 제거 및 통계 요약 표시**
  - [ ] `addons/city_map_editor/map_place_node.gd` 파일의 `_update_node_view()` 함수에서 기존 `events` 배열을 개별 행으로 순회하며 이벤트 이름과 🔗 버튼을 출력하던 로직을 완전히 소멸시킵니다.
  - [ ] 대신, 연보라색(`Color(0.85, 0.55, 0.85)`) 텍스트로 **`💬 매핑된 대화 이벤트: X개`** 형태의 콤팩트한 통계 요약 라벨 `1개`만 VBoxContainer에 단일 추가하도록 변경합니다.
  - [ ] **구현 참조 예시**:
    ```gdscript
    if events.size() > 0:
        var hbox_summary = HBoxContainer.new()
        hbox_summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(hbox_summary)
        
        var child_idx_ev = get_child_count() - 1
        set_slot(child_idx_ev, false, 0, Color.WHITE, false, 0, Color.WHITE)
        
        var label_summary = Label.new()
        label_summary.text = "💬 매핑된 대화 이벤트: " + str(events.size()) + "개"
        label_summary.modulate = Color(0.85, 0.55, 0.85)
        label_summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
        label_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        hbox_summary.add_child(label_summary)
        
        # 하단 이동 경로와의 구분을 위해 연한 구분선 추가
        var sep_ev = HSeparator.new()
        sep_ev.modulate = Color(1.0, 1.0, 1.0, 0.3)
        add_child(sep_ev)
        var child_idx_sep_ev = get_child_count() - 1
        set_slot(child_idx_sep_ev, false, 0, Color.WHITE, false, 0, Color.WHITE)
    ```

---

## 🛠️ Phase 2: EditorFileDialog 탐색기 도입 및 바인딩 (`map_editor_dock.gd`)
- [ ] **2.1 `EditorFileDialog` 동적 초기화**
  - [ ] `addons/city_map_editor/map_editor_dock.gd` 클래스 변수로 `var _file_dialog: EditorFileDialog`와 활성 바인딩용 변수(`var _active_event_line_edit: LineEdit`, `var _active_event_dict: Dictionary`)를 선언합니다.
  - [ ] `_ready()` 함수 내부에 `EditorFileDialog` 인스턴스를 동적으로 생성 및 설정하고 자식으로 추가합니다:
    ```gdscript
    _file_dialog = EditorFileDialog.new()
    _file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
    _file_dialog.add_filter("*.dialogue", "Dialogue Files (*.dialogue)")
    _file_dialog.title = "대화 스크립트 파일 선택"
    add_child(_file_dialog)
    ```
- [ ] **2.2 파일 선택 콜백 및 바인딩 함수 구현**
  - [ ] `_open_file_dialog_for_event(line_edit: LineEdit, ev: Dictionary)`와 `_on_dialogue_file_selected(path: String)` 헬퍼 함수를 추가하여 마우스 클릭 시 선택된 파일 경로가 팝업 입력창 및 데이터 사전에 정상 갱신되도록 연동합니다.
- [ ] **2.3 팝업 리스트 내 `📁` 단추 배치 및 람다 클로저 버그 예방**
  - [ ] `_refresh_popup_event_list()` 내부의 대화 파일 경로 입력 영역을 HBoxContainer로 감싸고, LineEdit 옆에 `btn_browse` 버튼(텍스트 `"📁"`)을 신설 배치합니다.
  - [ ] 클로저 꼬임 버그를 예방하기 위해, 파일 브라우저 버튼 생성을 위한 헬퍼 함수 `_create_file_browse_button(line_edit: LineEdit, ev: Dictionary) -> Button`을 설계하여 안전하게 연결해 줍니다.

---

## 🚀 Phase 3: 파일/라벨 자동 생성 및 정밀 점프 고도화 (`map_editor_dock.gd`)
- [ ] **3.1 `_jump_to_dialogue` 내 자동 생성 및 Append 알고리즘 주입**
  - [ ] **동작 사양**:
    1. **대화 파일이 없는 경우**: 디렉토리를 자동 감지/생성하고, `~ [라벨명]` 및 기본 주석이 달린 빈 `.dialogue` 파일을 새로 만들어 기획 작업을 도모합니다.
    2. **대화 파일이 있으나 라벨이 없는 경우**: 기존 파일 뒤에 `\n\n~ [라벨명]\n# 여기에 대화를 작성해 주세요.\n` 형태로 새 대화 시작 지점을 안전하게 이어 붙여줍니다(Append).
    3. **스캔 처리**: 파일 변경 발생 시 `EditorInterface.get_resource_filesystem().scan()`을 호출하여 에디터가 신설 리소스를 즉각 인지하게 만듭니다.
    4. **정밀 점프**: `DMPlugin.open_file_at_title(file_path, clean_label)`을 격발하여 완벽하게 해당 라벨 포커스로 뷰를 순간이동시킵니다.
  - [ ] **구현 코드 레퍼런스**:
    ```gdscript
    func _jump_to_dialogue(file_path: String, title_label: String) -> void:
        if file_path == "":
            return
            
        var clean_label = title_label.strip_edges()
        if clean_label == "":
            clean_label = "start"

        # 1. 파일 자동 생성 검증
        if not FileAccess.file_exists(file_path):
            print("Dialogue file does not exist. Creating new file at: ", file_path)
            var base_dir = file_path.get_base_dir()
            if not DirAccess.dir_exists_absolute(base_dir):
                DirAccess.make_dir_recursive_absolute(base_dir)
                
            var file = FileAccess.open(file_path, FileAccess.WRITE)
            if file:
                file.store_string("~ " + clean_label + "\n")
                file.store_string("# 여기에 [" + clean_label + "] 대화 스크립트를 작성해 주세요.\n")
                file.close()
                EditorInterface.get_resource_filesystem().scan()
            else:
                printerr("Failed to create dialogue file: ", file_path)
                return
        else:
            # 2. 기존 파일 내 라벨 자동 보완(Append) 검증
            var file = FileAccess.open(file_path, FileAccess.READ)
            if file:
                var content = file.get_as_text()
                file.close()
                
                var label_pattern = "~ " + clean_label
                if not label_pattern in content:
                    print("Label '", clean_label, "' not found in dialogue file. Appending new label section.")
                    var append_file = FileAccess.open(file_path, FileAccess.READ_WRITE)
                    if append_file:
                        append_file.seek_end()
                        append_file.store_string("\n\n~ " + clean_label + "\n")
                        append_file.store_string("# 여기에 [" + clean_label + "] 이벤트 대화를 작성해 주세요.\n")
                        append_file.close()
                        EditorInterface.get_resource_filesystem().scan()

        # 3. Dialogue Manager 플러그인을 활용한 정밀 점프 격발
        if DMPlugin.instance != null:
            DMPlugin.open_file_at_title(file_path, clean_label)
            print("Successfully jumped to dialogue: ", file_path, " -> ", clean_label)
        else:
            var dialogue_resource = load(file_path)
            if dialogue_resource:
                EditorInterface.edit_resource(dialogue_resource)
                EditorInterface.select_file(file_path)
    ```

---

## 🔍 Phase 4: 최종 컴파일 및 동작 검증
- [ ] **4.1 헤드리스 구문 구동 테스트**
  - [ ] Godot 엔진을 헤드리스 모드로 기동하여 새로 추가된 `EditorFileDialog` 및 파일 입출력 코드로 인한 컴파일/구문 오류가 없는지 사전 검증을 완수합니다:
    ```bash
    Godot_v4.6.3-stable_win64_console.exe --path project/guild-master --headless --quit
    ```
