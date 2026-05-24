# 시간(Time Unit) 시스템 아카이브 및 AP 전환 작업 계획

이 문서는 게임 루프가 기존의 시간 단위(Time Unit) 추적 방식에서 보드게임식 액션 포인트(AP) 턴제 루프로 전환됨에 따라, 기획 문서 내의 레거시 시간 시스템 정보를 정리하고 아카이브하는 작업을 관리합니다.

## 작업 목록

- [x] `new_direction.md` 내 '순찰대 동행' 행동의 시간(3 unit) 소비 기획을 행동력(AP) 소비로 변경 (완료)
- [x] `new_direction.md` 전체에서 다른 '시간 unit' 관련 언급 탐색 및 정정 (완료 - 탐색 결과 다른 부분에는 레거시 시간 unit이 없음 확인)
- [x] `planner_guide.md` 내의 '시간 시스템 (Time System)' 섹션에 아카이브/폐기(Deprecated) 안내 추가 및 AP 시스템과의 연계 명시 (완료 - AP 도입 안내문 및 레거시 표시 적용 완료)
- [x] `architecture.md` 내의 `advance_time` 등 시간 관련 API 및 액션 명세를 폐기(Deprecated)로 마킹 (완료 - spend_ap 액션 및 ap_gte 등 AP 기준 검증 설계 추가와 Phase 2 아카이브 경고문 반영)
- [x] `wiki` 폴더 전체에서 레거시 시간(unit) 흔적 추가 검색 및 보완 정리 (완료 - `ink_guide.md` 내 시간 함수 및 대화 예시들을 레거시화하고 `spend_ap` 신규 사양 가이드를 보완해 완벽히 동기화함)
- [x] 최종 검토 및 정리 (완료)

## 2차 추가 작업 계획 (슬럼가 살 붙이기)
- [x] `new_direction.md` 의 Districts 슬럼가 파트 기획 고도화 및 구체적인 3대 장소 구체화 (완료)
  - [x] 도적들의 소굴 (The Rogue's Den) 특수행동, 효과, AP 비용, 텍스트 예시 기입 (완료)
  - [x] 부랑자 골목 (Beggar's Alley) 특수행동, 효과, AP 비용, 텍스트 예시 기입 (완료)
  - [x] 폐양조장 & 마녀의 오두막 (The Abandoned Distillery / Witch's Hovel) 특수행동, 효과, AP 비용, 텍스트 예시 기입 (완료)
- [x] 최종 검토 및 사용자 보고 (완료)

## 3차 추가 작업 계획 (위키 대청소 및 레거시 아카이빙)
- [x] 레거시 및 피벗 이전 구버전 기획서 8개 파일을 `wiki/.trash/` 폴더로 이동 (완료)
- [x] `wiki/00_헌법/README.md` 인덱스를 `new_direction` 및 `glossary` 참조로 정돈 (완료)
- [x] `wiki/01_시스템/README.md` 인덱스를 최신 설계(`npa_simulation_system`, `condition_cards_design`, `dialogue_manager_guide`) 참조로 정돈 (완료)
- [x] `wiki/02_콘텐츠/README.md` 인덱스를 `world_and_places`, `planner_guide` 참조로 정돈하고 레거시 링크 제거 (완료)
- [x] 메인 포털 인덱스 `wiki/README.md`를 나무위키 스타일의 아름다운 대문으로 완벽히 재작성 (완료)
- [x] `audit_wiki_pivot.py` 기획 적합성 감사 수행 및 `dialogue_manager_guide.md` 내 잔존하던 레거시 `time_units` 완벽 정정 (완료)
- [x] Git 커밋 및 Push (완료)

