# 02_콘텐츠

> **콘텐츠 기획 및 작성 가이드**
>
> 기획자가 JSON 데이터, 대화 스크립트, 장소 설정을 작성할 때 참조하는 문서입니다.

---

## 포함 문서

| 문서 | 설명 | 대상 독자 |
|------|------|----------|
| [[planner_guide]] | **핵심 기획 가이드** — JSON 데이터 규격, 대화 매니저 연동, 기획 표준 | 기획자 |
| [[world_and_places]] | **세계 및 장소 설정** — 나틀락(Natlach) 도시의 구역, 장소, NPC와 이벤트 총망라 | 기획자 |

---

## 콘텐츠 파이프라인

```
1. 장소 JSON 작성 → data/places/
2. NPC 스케줄 JSON 작성 → data/npc_schedules/
3. 대화 .ink 작성 → data/dialogues/ 또는 Story/
4. 이벤트 JSON 작성 → data/events/
5. interaction JSON 작성 → data/interactions/
6. (선택) content-inbox에 기획서 전달 → 프로그래머가 구현
```

---

## 관련 문서

- 상위: [[README]]
- 핵심 원칙: [[00_헌법/README]]
- 시스템 상세: [[01_시스템/README]]
- 컨텐츠 전달함: [[content-inbox/README]]
