# Agent 워크스페이스

이 폴더는 Claude Code가 GuildMaster 프로젝트에서 작업할 때 사용하는 지침과 자료를 저장합니다.

## 폴더 구조

```
Agent/
├── README.md              ← 이 파일 (구조 설명)
├── CLAUDE.md              ← 마스터 가이드 (페르소나, 정책, 필수 지침)
├── SELF_IMPROVEMENT.md    ← 봇의 자체 개선/적응 방법
├── memory/                ← 장기 기억 저장소 (flat 구조)
├── workflows/             ← 작업 유형별 가이드
├── prompts/               ← 재사용 가능한 프롬프트 조각
└── config/                ← 설정 파일 (향후 확장용)
```

## 파일 추가 규칙

### memory/ 추가 시
- `MEMORY.md`에 항목 추가 (형식: `- [파일명](파일명.md) — 한줄 설명`)
- 파일명 접두사로 타입 표시: `[user]`, `[feedback]`, `[project]`, `[reference]`
- **10개 이상**이 되면 타입별 폴더(`user/`, `feedback/` 등)로 정리 고려

### workflows/ 추가 시
- `_template.md`를 복사하여 시작
- 명확한 작업 유형이 정의될 때만 생성

### prompts/ 추가 시
- 재사용 가능한 프롬프트 조각만 저장
- 특정 작업 전용은 workflows/에 포함

## 확장 규칙 (Adaptability)

- 새 카테고리가 필요하면 `SELF_IMPROVEMENT.md` 검토
- 파일/폴더 구조 변경은 README.md 업데이트 필수
- 불필요해진 파일은 즉시 삭제 (눈덩이 방지)
