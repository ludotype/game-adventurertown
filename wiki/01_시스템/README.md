# 01_시스템

> **시스템 설계 및 엔진 문서**
>
> 프로그래머와 기획자가 함께 보는 시스템 구조 설계서입니다.

---

## 포함 문서

| 문서 | 설명 |
|------|------|
| [[autonomous_npc_design]] | 자율 NPC 행동 설계 |
| [[crisis_system_design]] | 위기(크라이시스) 시스템 설계 |
| [[emergent_storytelling]] | 에머전트 스토리텔링 체인 |
| [[evaluation_report]] | 시스템 평가 및 검수 보고서 |
| [[ink_guide]] | **Ink 대화 엔진** 사용법 및 문법 |
| [[tool_design_editor.md]] | 툴/에디터 설계 |

---

## 시스템 흐름도

```
[PlaceScene] → [NPCSpawner] → [InteractionRegistry] → [ActionRunner]
                                     ↓
                              [ConditionEvaluator]
                                     ↓
                        [InkBalloon] / [EventBus]
```

---

## 관련 문서

- 상위: [[README]]
- 핵심 원칙: [[00_헌법/README]]
- 콘텐츠 작성법: [[02_콘텐츠/README]]
