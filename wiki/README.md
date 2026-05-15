# Guild Master Wiki

> **게임 디자인 문서의 중앙 저장소**

## 폴더 구조 규칙

모든 게임 디자인 관련 문서는 **반드시 이 `wiki/` 폴더에 직접 저장**합니다.

### 올바른 경로 예시
```
wiki/
├── Game_Concept.md        # 게임 전체 컨셉트
├── combat_system.md       # 전투 시스템
├── economy_system.md      # 경제/건설 시스템
├── exploration_system.md  # 맵 탐험 시스템
└── npc_dialogues.md       # NPC/스토리
```

### 잘못된 경로 (금지)
```
❌ docs/wiki/Game_Concept.md
❌ docs/GDD/Game_Concept.md
❌ design/Game_Concept.md
❌ wiki/systems/combat.md   (하위 폴더 없이 직접 저장)
```

## 문서 작성 규칙

1. **파일명**: `snake_case.md` 또는 `PascalCase.md`
2. **폴더 구조**: **모든 파일은 wiki/ 루트에 직접 저장**, 하위 폴더 생성 금지
3. **포맷**: Markdown (.md)
4. **언어**: 한국어 (기본), 코드/기술 용어는 영어 병기

## 현재 문서 목록

| 파일명 | 내용 | 최종 수정 |
|--------|------|----------|
| `Game_Concept.md` | 게임 전체 컨셉트, 비전, 로드맵 | 2025-04-17 |
| `combat_system.md` | 전투 시스템 상세 설계 | 2025-04-17 |

## 새 문서 추가 시 체크리스트

- [ ] 파일을 `wiki/` 폴더에 **직접** 생성했는가?
- [ ] 하위 폴더를 만들지 않았는가?
- [ ] 파일명이 규칙을 따르는가?
- [ ] 위 표에 문서를 추가했는가?
