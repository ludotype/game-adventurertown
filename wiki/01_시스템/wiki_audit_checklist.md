# 위키 전체 점검 보고서 및 청소 체크리스트

> 작성일: 2026-05-24
> 대상: City of Eldritch (Cosmic Horror Roguelite RPG) 위키 전체
> 기준 문서: `wiki/00_헌법/new_direction.md` (확정 GDD)

---

## 🔴 CRITICAL (도시명/세계관 불일치)

- [x] **`new_direction.md` 도시명 통일**: Nighthaven → Natlach
  - 위치: §1 (Core Loop), §2 (World Setting), §3 (Districts) 전반
  - 이유: `glossary.md`, `world_and_places.md`, `npa_simulation_system.md` 등 전 프로젝트가 Natlach 기준
- [x] **`new_direction.md` §3 장소 구조 통일**: Nighthaven 구역(북부/대학가/슬럼가/대성당/거리) vs Natlach 구역(주거/생활/중앙광장/북쪽유적/서쪽경비대)
  - 이유: 장소 ID, connections, NPC 스케줄 전체가 영향받음. 둘 중 하나를 기준으로 통일해야 함
  - 상태: **완료**. `new_direction.md` §3은 이미 canonical 5 구역(북부/대학가/슬럼가/대성당/거리) 및 12 장소 ID로 통일됨. `world_and_places.md`와 100% 일치.
- [x] **`new_direction.md` §3 루이제 위치/역할 통일**: Fireside Amber 선술집 주인 → 여관 로비 주인
  - 이유: `world_and_places.md`, `glossary.md`에서는 루이제=여관 주인

---

## 🟠 HIGH (구 스탯/구 시스템 잔여물)

- [x] **`crisis_system_design.md`**: `player.mental` → `player.stamina` 교체 / `will` → `willpower` 교체
  - 위치: §2.1 (ongoing_effects), §2.2 (condition reckoning), §2.3 (doom track), §3.4 (game_over)
- [x] **`crisis_system_design.md`**: `attribute_check`를 다이스 풀 시스템으로 이식
  - 위치: §5.2 (새 action type 정의)
  - 상태: `attribute_check`가 이미 다이스 풀 규칙(스탯값만큼 d6 굴림, 4+ 성공 개수 >= difficulty)으로 문서화됨.
- [x] **`emergent_storytelling.md`**: `outcome_check` 공식을 다이스 풀로 교체
  - 현재: ~~`1d6 + attribute >= difficulty * 3`~~ → **완료**
  - 확정: 스탯값만큼 d6 굴림, 4+ 성공 개수로 분기. §2 gamble.json, §5 장소별 행동 카탈로그 전체 교체 완료.
- [x] **`emergent_storytelling.md`**: 구 속성명 `observation` → `insight`, `combat` → `physique` 교체
  - 위치: §2 (tavern/gather_intel), §4 (ambush, night_intruder)
- [x] **`emergent_storytelling.md`**: `player.mental` → `player.stamina` 교체
  - 위치: §4.2 (night_intruder.json)
- [x] **`dungeon_exploration.md`**: PbtA 2d6 + `.ink` 시스템 → 상단에 `[DEPRECATED]` 폐기 공지 추가
  - 현재 컨셉과 100% 충돌 (다이스 풀 + Dialogue Manager `.dialogue`)
- [x] **`architecture.md`**: `player.strength` → `player.physique` 예시 교체
  - 위치: §5 MetricStore 원칙
- [x] **`planner_guide.md`**: `outcome_check` 공식 및 `observation` 속성명 교체
  - 위치: §5.2 (outcome_check 작성 예시), §5 (장소별 행동 카탈로그)
  - 상태: `observation` → `insight`, `combat` → `physique`, `1d6 + attribute` → 다이스 풀 전부 교체 완료.

---

## 🟠 HIGH (구 컨셉: 연애 시뮬 잔여물)

- [x] **`evaluation_report.md` 전체 → `[DEPRECATED]` 폐기 공지 추가**
  - 현재 내용: 1인칭 연애 어드벤처 + 히로인 3명 평가
  - 현재 컨셉: 코스믹 호러 로그라이트 RPG
- [x] **`crisis_system_design.md` §4**: 루이제/연애 루프 → `[DEPRECATED]` 폐기 공지 추가
  - 위치: §4.1 ~ §4.3 (위기 상태에 따른 루이제 변화, 의뢰, 파멸 영향)
  - 히로인/연애 언어를 NPC 구출/신뢰 언어로 교체
- [x] **`crisis_system_design.md` §3.4**: `heroine` 게임오버 타입 제거
  - `heroine` → `npc_loss`, `히로인 게임오버` → `NPC 구출 실패 오버`
- [x] **`architecture.md`**: `change_relation` / `affection` → `trust` 메트릭 교체
  - 위치: §3 Action Vocabulary, §5 MetricStore, §2.3 Phase 3 검수 기준
  - 예시 metric 키 `affection` → `trust` 일괄 교체

---

## 🟡 MEDIUM (정신력/Sanity 단어 잔여)

- [x] **`new_direction.md` §5.2**: "정신력 회복" → "스태미나 회복" 교체
  - 위치: NPC 조력 효과 설명
- [x] **`new_direction.md` §3**: Sanity/정신력 개념 언어 정리
  - 위치: Fireside Amber → 여관 로비 관련 묘사, 치료소/성소 관련 묘사
  - 결과: `정신력 회복` → `스태미나 회복`, `Fireside Amber` → `루이제의 여관`, `선술집` → `여관` 완료
- [x] **`world_and_places.md` §2.1**: `haunted` 카드 관련 "정신 이상" 문맥 검토
  - 상태 카드 시스템으로 대체되었으나, "정신 이상"이라는 범주명은 유지 가능
  - 결정: `정신 이상 상태 카드` 문맥 그대로 유지

---

## 🟢 LOW (기타)

- [x] **`dialogue_manager_guide.md`**: SCG 예시 `morigan_smile` → `luise_smile` 교체
- [ ] **`planner_guide.md` §11**: UI 스타일 묘사와 `new_direction.md` §7.2 사이드 스크롤 전투 시각적 표현 통일
- [x] **`planner_guide.md`**: `outcome_check` 공식 및 `observation` 속성명 교체
  - 상태: §5.2, §5 전부 교체 완료. 위 HIGH 섹션 참조.
- [x] **`architecture.md` §11**: `[[game_loop]]` 링크 → `[[dialogue_manager_guide]]`로 갱신
- [x] **`planner_guide.md` 관련 문서**: `[[ink_guide]]` → `[[dialogue_manager_guide]]` 갱신
- [x] **`.trash/new_direction_quiz.md`**: 기획 참고용으로 유지할지, 완전 삭제할지 결정
  - 상태: `.trash/` 아카이브 내 보존으로 결정. 삭제 불필요.

---

## 진행 현황

| 우선순위 | 항목 | 상태 | 수정일 |
|---------|------|------|--------|
| 🔴 | `new_direction.md` Nighthaven → Natlach | 완료 | 2026-05-24 |
| 🔴 | `new_direction.md` §3 장소 구조 통일 | 완료 | 2026-05-24 |
| 🟠 | `crisis_system_design.md` mental/will 정리 | 완료 | 2026-05-24 |
| 🟠 | `crisis_system_design.md` §3.4/§4 히로인 제거 | 완료 | 2026-05-24 |
| 🟠 | `dungeon_exploration.md` 폐기/재작성 | 완료 (DEPRECATED) | 2026-05-24 |
| 🟠 | `evaluation_report.md` 재평가/아카이브 | 완료 (DEPRECATED) | 2026-05-24 |
| 🟠 | `architecture.md` affection → trust | 완료 | 2026-05-24 |
| 🟠 | `emergent_storytelling.md` 다이스 풀 이식 | 완료 | 2026-05-24 |
| 🟡 | `new_direction.md` 정신력 언어 정리 | 완료 | 2026-05-24 |
| 🟡 | `world_and_places.md` 정신 이상 문맥 검토 | 완료 | 2026-05-24 |
| 🟢 | `dialogue_manager_guide.md` SCG 예시 교체 | 완료 | 2026-05-24 |
| 🟢 | `architecture.md`/`planner_guide.md` 링크 갱신 | 완료 | 2026-05-24 |

---

*문서 버전: 1.0*
*최종 업데이트: 2026-05-24*
