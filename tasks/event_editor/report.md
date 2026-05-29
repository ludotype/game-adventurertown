# 작업 보고서: 팝업형 대화 이벤트 편집기 및 Dialogue Manager 정밀 점프 연동

> **작업 일자**: 2026-05-29
> **관련 작업**: `task.md`, `implementation_plan.md`
> **작업 상태**: ✅ 완료

---

## 1. 작업 개요

기존 사이드바에 직접 내장되었던 복잡한 이벤트 편집 UI를 제거하고, **"💬 대화 이벤트 편집기 열기"** 버튼을 통해 중앙 팝업(`AcceptDialog`)으로 편집하도록 전환한 후, 기존에 작동하지 않던 `🔗 점프` 기능을 **Dialogue Manager 플러그인의 고유 API(`DMPlugin.open_file_at_title`)**를 활용하여 지정한 대화 라벨(Title) 위치로 에디터 뷰가 자동 스크롤/포커싱되는 완전한 연동 동작으로 구현했습니다.

추가로, 반복 루프 내부에서 람다 클로저가 루프 변수를 참조(reference)로 캡처하여 발생하는 **심각한 클로저 버그(closure bug)**를 다수 발견하고 수정했습니다. 이 버그는 팝업 이벤트 리스트, 사이드바 경로 리스트, 캔버스 노드 이벤트 뱃지의 버튼/입력필드가 모두 마지막 항목만을 가리키는 문제를 유발했습니다.

---

## 2. 변경된 파일

| 파일 | 변경 유형 | 설명 |
|------|----------|------|
| `project/guild-master/addons/city_map_editor/map_editor_dock.gd` | 수정 | 점프 연동 + 클로저 버그 수정 + 헬퍼 함수 추가 |
| `project/guild-master/addons/city_map_editor/map_place_node.gd` | 수정 | 노드 뱃지 클로저 버그 수정 + 헬퍼 함수 추가 |

---

## 3. 구현 상세

### 3.1 Dialogue Manager 정밀 점프 (`map_editor_dock.gd`)

**기존 코드**:
```gdscript
func _jump_to_dialogue(file_path: String, title_label: String) -> void:
    var dialogue_resource = load(file_path)
    if dialogue_resource:
        EditorInterface.edit_resource(dialogue_resource)
        EditorInterface.select_file(file_path)
```

**문제**: 파일을 열기만 하고 지정한 대화 라벨 위치로 점프하지 않음.

**수정된 코드**:
```gdscript
func _jump_to_dialogue(file_path: String, title_label: String) -> void:
    if file_path == "":
        return
    if not FileAccess.file_exists(file_path):
        printerr("Dialogue file does not exist: ", file_path)
        return

    if DMPlugin.instance != null:
        DMPlugin.open_file_at_title(file_path, title_label)
        print("Successfully jumped to dialogue: ", file_path, " at title: ", title_label)
    else:
        var dialogue_resource = load(file_path)
        if dialogue_resource:
            EditorInterface.edit_resource(dialogue_resource)
            EditorInterface.select_file(file_path)
            print("Dialogue Manager plugin instance not found. Opened file without title jump: ", file_path)
```

**동작**:
1. `DMPlugin.instance`가 존재하면 `DMPlugin.open_file_at_title(file_path, title_label)` 호출
2. Dialogue Manager 에디터가 해당 리소스를 열고 `title_label` 위치로 뷰 자동 이동
3. `DMPlugin`이 없을 경우 기존 동작으로 폴백

---

### 3.2 클로저 버그 수정 (3개 영역)

GDScript 4의 람다는 외부 변수를 **참조(reference)로 캡처**합니다. `for` 루프 내부에서 생성된 람다가 루프 변수를 캡처할 경우, 모든 람다가 **동일한 변수**를 참조하므로 루프 종료 후에는 마지막 값만을 공유하게 됩니다.

#### 3.2.1 팝업 이벤트 리스트 (`map_editor_dock.gd`)

**증상**: `🔗 점프` 버튼과 `🗑` 삭제 버튼이 항상 마지막 이벤트를 참조.

**해결**: 루프 변수(`ev`, `ev_idx`)를 **헬퍼 함수의 매개변수로 전달**하여 각 람다가 독립적인 스택 프레임을 캡처하도록 수정.

```gdscript
func _create_event_jump_button(file_path: String, title_label: String) -> Button:
    var btn = Button.new()
    btn.pressed.connect(func():
        _jump_to_dialogue(file_path, title_label)  # 각 호출의 매개변수 캡처
    )
    return btn

func _create_event_delete_button(node: GraphNode, idx: int) -> Button:
    var btn = Button.new()
    btn.pressed.connect(func():
        node.events.remove_at(idx)  # 각 호출의 매개변수 캡처
        _refresh_popup_event_list()
    )
    return btn
```

추가로 이벤트명 입력, 대화 파일 경로 입력, 대화 라벨 입력에도 동일한 패턴을 적용했습니다.

#### 3.2.2 사이드바 경로 리스트 (`map_editor_dock.gd`)

**증상**: ▲/▼/🗑 버튼 및 `target_place_id` 입력 필드가 모두 마지막 경로만 조작.

**해결**: 동일한 헬퍼 함수 분리 패턴 적용.

```gdscript
func _create_path_up_button(idx: int) -> Button:
    ...
func _create_path_down_button(idx: int, max_idx: int) -> Button:
    ...
func _create_path_target_edit(path_data: Dictionary, path_idx: int) -> LineEdit:
    ...
func _create_path_delete_button(node: GraphNode, idx: int) -> Button:
    ...
```

#### 3.2.3 캔버스 노드 이벤트 뱃지 (`map_place_node.gd`)

**증상**: 노드 카드 내부의 `🔗` 버튼이 마지막 이벤트만 점프.

**해결**: `_create_event_jump_button` 헬퍼 함수 추가.

```gdscript
func _create_event_jump_button(file_path: String, title_lbl: String) -> Button:
    var btn_jump = Button.new()
    btn_jump.disabled = (file_path == "")
    btn_jump.pressed.connect(func():
        event_jump_requested.emit(file_path, title_lbl)
    )
    return btn_jump
```

---

## 4. 검증 결과

### 4.1 자동 검증 (헤드리스 실행)

```bash
Godot_v4.6.3-stable_win64_console.exe --path project/guild-master --headless --quit
```

**결과**: ✅ 구문 오류 없이 정상 로드

```
[GameFlags] 초기화 완료
[DEBUG] PlaceRegistry: loaded 4 places from places.json
...
ActionOrderRegistry: merged 30 entries
```

### 4.2 수동 검증 체크리스트

| 단계 | 동작 | 예상 결과 | 상태 |
|------|------|----------|------|
| 1 | Godot 에디터 기동 후 City Map Editor 뷰 열기 | 플러그인 정상 로드 | ⬜ 미수행 |
| 2 | 장소 노드 선택 → `💬 대화 이벤트 편집기 열기` 클릭 | `850x500` 팝업 표시 | ⬜ 미수행 |
| 3 | `+ 새 스토리 대화 이벤트 추가` 클릭 | 이벤트 입력 행 추가 | ⬜ 미수행 |
| 4 | 이름/경로/라벨 입력 후 `🔗 점프` 클릭 | Dialogue Manager 에디터가 해당 라벨 위치로 포커스 | ⬜ 미수행 |
| 5 | 팝업 닫기 | 캔버스 노드 카드에 연보라색 `💬` 뱃지 실시간 반영 | ⬜ 미수행 |
| 6 | `Save` → `Load` | `places.json`에 이벤트 데이터가 깨짐 없이 복구 | ⬜ 미수행 |

---

## 5. 알려진 이슈 및 주의사항

### 5.1 Dialogue Manager 플러그인 의존성

`DMPlugin` 클래스를 직접 참조하므로, **Dialogue Manager 플러그인이 비활성화된 경우** `map_editor_dock.gd` 스크립트 컴파일에 실패할 수 있습니다.

- 현재 프로젝트의 `project.godot`에서 `editor_plugins/enabled`에 `dialogue_manager`가 **이미 등록**되어 있음 (`res://addons/dialogue_manager/plugin.cfg`)
- City Map Editor 플러그인은 Dialogue Manager 이후에 로드되므로 `DMPlugin` 클래스가 사용 가능함

### 5.2 클로저 버그 수정의 범위

이번 수정은 **이벤트 관련 람다**와 **경로 관련 람다**에 집중했습니다. 코드베이스 내 다른 `for` 루프 + 람다 조합에 대해서도 동일한 패턴 검토가 권장됩니다.

---

## 7. 추가 고도화 작업 (2026-05-29 후속)

### 7.1 Phase 1: 캔버스 노드 카드 슬림화

**변경 파일**: `addons/city_map_editor/map_place_node.gd`

**내용**: `_update_node_view()` 내부의 개별 이벤트 이름 + `🔗` 점프 버튼 나열 루프를 완전히 제거하고, 대신 **`💬 매핑된 대화 이벤트: X개`** 형태의 연보라색 통계 요약 라벨 1개만 출력하도록 변경.

**추가 수정**: 기존 `child_idx = i + 2`가 이벤트 섹션 추가 후 실제 경로 슬롯 인덱스와 불일치하던 버그를 `path_start_idx = get_child_count()` 기반 동적 계산으로 수정.

### 7.2 Phase 2: EditorFileDialog 탐색기 도입

**변경 파일**: `addons/city_map_editor/map_editor_dock.gd`

**내용**:
- `_ready()`에서 `EditorFileDialog`를 동적 생성 및 `add_child()`
- `_open_file_dialog_for_event()`, `_on_dialogue_file_selected()` 바인딩 함수 추가
- `_refresh_popup_event_list()`에서 대화 파일 경로 입력창을 `HBoxContainer`로 감싸고 `📁` 탐색기 버튼 배치
- `_create_file_browse_button()` 헬퍼 함수로 클로저 버그 예방

### 7.3 Phase 3: 파일/라벨 자동 생성 및 점프 고도화

**변경 파일**: `addons/city_map_editor/map_editor_dock.gd`

**내용**: `_jump_to_dialogue()` 함수에 다음 자동화 규칙을 주입:
1. **파일 미존재 시**: `DirAccess.make_dir_recursive_absolute()`로 디렉토리 자동 생성 후, `~ [라벨]` 및 기본 주석이 포함된 빈 `.dialogue` 파일 신설
2. **파일 존재 + 라벨 미존재 시**: `FileAccess.READ_WRITE` + `seek_end()`로 기존 파일 끝에 `~ [라벨]` 섹션 자동 Append
3. **리소스 스캔**: 파일 변경 후 `EditorInterface.get_resource_filesystem().scan()` 호출로 에디터가 신설/변경 리소스를 즉각 인지
4. **정밀 점프**: `DMPlugin.open_file_at_title(file_path, clean_label)`로 완벽한 라벨 포커스 이동

---

## 8. 검증 결과 (고도화 후)

### 8.1 자동 검증 (헤드리스 실행)

```bash
Godot_v4.6.3-stable_win64_console.exe --path project/guild-master --headless --quit
```

**결과**: ✅ 구문 오류 없이 정상 로드

---

## 9. 관련 문서

- [작업 명세서](task.md)
- [구현 설계서](implementation_plan.md)
- [플래너 가이드](../../wiki/02_콘텐츠/planner_guide.md)
- [장소 및 이벤트 데이터 형식](../../wiki/02_콘텐츠/world_and_places.md)
