# City Map Editor — Implementation Handoff

> 작성자: Kimi (구현 에이전트)  
> 대상: Antigravity (설계/상위 AI)  
> 날짜: 2026-05-28

---

## 1. 구현 완료 상태

`implementation_plan.md` 및 `kimi_instruction.md`에 따라 Phase 1~5 모두 코드로 구현 완료했습니다.

| 파일 | 경로 | 상태 |
|------|------|------|
| plugin.cfg | `addons/city_map_editor/plugin.cfg` | ✅ |
| plugin.gd | `addons/city_map_editor/plugin.gd` | ✅ |
| map_editor_dock.tscn | `addons/city_map_editor/map_editor_dock.tscn` | ✅ |
| map_editor_dock.gd | `addons/city_map_editor/map_editor_dock.gd` | ✅ |
| map_place_node.gd | `addons/city_map_editor/map_place_node.gd` | ✅ |
| places.json | `data/places.json` | ✅ (템플릿) |
| connections.json | `data/connections.json` | ✅ (템플릿) |

### 기능 요약

- **도크 등록**: Godot 하단 Bottom Panel에 "City Map Editor" 탭 노출
- **우클릭 노드 생성**: `GraphEdit` 캔버스 빈 공간 우클릭 → "새 장소 노드 생성"
- **드래그 이동**: 노드 자유롭게 드래그 가능
- **연결/해제**: 소켓 간 마우스 드래그로 연결선 생성 및 해제
- **Save/Load**: `data/places.json` + `data/connections.json` 동기화
- **편집 UI**: `LineEdit` 3개 (ID, 한글 표시명, 상주 NPC)
- **Dialogue Manager 연동**: 이벤트 버튼 더블 클릭 → `EditorInterface.edit_resource()` 점프

### 컴파일 이슈 수정 내역

- `show_close_button` / `close_request` → Godot 4.x `GraphNode` API 미지원으로 제거
- 우클릭 팝업 위치 → `get_global_mouse_position()` 사용으로 글로벌 좌표 정합성 확보

---

## 2. 사용자 테스트 결과 (스크린샷)

사용자가 Godot에서 실제로 플러그인을 활성화하고 노드를 생성한 결과:

- 노드 내부에 `ID`, `한글 표시명`, `상주 NPC` 입력창이 정상 렌더링됨
- `+ 이벤트 추가` 버튼과 `Ev: 새 이벤트` 버튼이 노드 하단에 같이 노출됨

---

## 3. 상위 AI 의견 필요 사항

**핵심 질문: `map_place_node` 내부에 이벤트 목록을 노출시킬 것인가?**

- `implementation_plan.md` 3.3 및 Phase 5에는 "이벤트 목록을 렌더링하고", "이벤트의 진입 조건 데이터를 입력할 수 있는 텍스트 상자를 만든다"고 명시되어 있습니다.
- 하지만 **사용자(개발자)는 "맵 에디터에서는 이벤트 목록을 노출시키지 않기로 한 것 같은데"**라고 의견을 제시했습니다.
- 현재 스크린샷 상 `+ 이벤트 추가` 버튼과 `Ev: 새 이벤트` 버튼이 노드에 붙어 있는 상태입니다.

**결정 필요**:
1. **이벤트 UI 유지**: `implementation_plan.md` 원안대로 이벤트 목록/추가/편집을 노드 내부에 유지
2. **이벤트 UI 제거**: 맵 에디터는 오직 장소의 위치, 이름, 연결만 관리하고, 이벤트 데이터는 별도 도구에서 관리
3. **절충**: 이벤트는 노드에 표시하지 않되, Dialogue Manager 점프 연동은 다른 방식(예: 인스펙터)에서 유지

---

## 4. 다음 단계 제안

- 상위 AI(Antigravity)의 의사결정 후 이벤트 UI 유지/제거 적용
- `new_direction.md`의 District/Place 구조를 실제로 에디터에 그려보는 프로토타입
- 런타임 `PlaceRegistry`가 `data/places.json` 통합 포맷을 로드하도록 전환

---

## 5. 첨부 파일

- `addons/city_map_editor/` (5개 파일)
- `data/places.json`
- `data/connections.json`
