# 01_시스템

> **시스템 설계 및 엔진 문서**
>
> 프로그래머와 기획자가 함께 보는 시스템 구조 설계서입니다.

---

## 포함 문서

| 문서 | 설명 |
|------|------|
| [[npa_simulation_system]] | **NPA 시뮬레이션** — 자율 탐사 액터 행동 및 위기 대응 시뮬레이션 설계 |
| [[crisis_system_design]] | 위기(크라이시스) 시스템 설계 |
| [[emergent_storytelling]] | 에머전트 스토리텔링 체인 |
| [[condition_cards_design]] | **상태 카드 시스템** — 정신(환각/편집증 등) 및 신체 상태 카드 설계서 |
| [[dialogue_manager_guide]] | **대화 엔진 가이드** — Godot Dialogue Manager 사용법 및 연출 태그 가이드 |
| [[tool_design_editor.md]] | 툴/에디터 설계 |

---

## 시스템 흐름도

```
[PlaceScene] → [NPCSpawner] → [InteractionRegistry] → [ActionRunner]
                                     ↓
                              [ConditionEvaluator]
                                     ↓
                        [CustomBalloon] / [EventBus]
```

---

## 관련 문서

- 상위: [[README]]
- 핵심 원칙: [[00_헌법/README]]
- 콘텐츠 작성법: [[02_콘텐츠/README]]
