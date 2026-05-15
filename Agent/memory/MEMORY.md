# Memory Index

Claude가 세션 간에 기억하는 정보 목록입니다. (최대 200줄, 그 이후는 truncate)

## 메모리 목록

<!-- 새 메모리 추가 시 여기에 입력 -->

## 타입별 분류

### [user] — 사용자 프로필
- [user_coding_style.md](user_coding_style.md) — Python Black, GDScript 표준 스타일 (snake_case/PascalCase)

### [feedback] — 작업 방식 피드백
- [feedback_coding_style.md](feedback_coding_style.md) — Python PEP8, JS camelCase 선호
- [feedback_glob_patterns.md](feedback_glob_patterns.md) — Windows Glob 패턴: leading ./ 사용 금지
- [feedback_lessons_from_failures.md](feedback_lessons_from_failures.md) — 중요한 실패 후 자동 기록 원칙

### [project] — 프로젝트 상태
<!-- 예: [project_milestones.md](project_milestones.md) — 6월 출시 목표 -->

### [reference] — 외부 참조
<!-- 예: [reference_notion.md](reference_notion.md) — 기획서 Notion 위치 -->

---

## 파일 관리 규칙

- **파일 10개 이상**: 타입별 폴더로 분리 고려
- **이름 규칙**: `[타입]_[주제].md` (예: `user_role.md`)
- **업데이트**: 정보가 바뀌면 파일 수정, MEMORY.md는 인덱스만 유지
