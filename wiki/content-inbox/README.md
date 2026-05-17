# Content Inbox (컨텐츠 전달함)

> **기획자 → 프로그래머(Claude) 컨텐츠 전달 전용 공간**
>
> 완성된 시스템에 채워넣을 콘텐츠(대사, 퀘스트, 아이템 기획 등)를 여기에 두고, Claude에게 "content-inbox의 {파일명}을 읽고 구현해"라고 요청하세요.

---

## 사용법

### 1. 파일 작성

```
wiki/content-inbox/
├── quest_luise_chapter1.md
├── item_new_weapons.md
└── dialogue_elena_birthday.md
```

- Markdown (.md) 또는 JSON (.json)으로 작성
- 파일명은 `snake_case.md`

### 2. Claude에게 전달

> "content-inbox의 `quest_luise_chapter1.md`를 읽고, 퀘스트 시스템에 추가해줘."

Claude가 파일을 읽고:
1. 기획意도를 이해
2. 필요한 JSON 파일을 `data/` 폴더에 생성
3. `.ink` 대화 파일을 작성 및 컴파일
4. `wiki/planner_guide.md`에 변경 사항을 반영

### 3. 완료 후 처리

- 구현이 끝난 파일은 `wiki/.trash/`로 이동하거나 삭제
- 또는 `content-inbox/archive/` 폴더를 만들어 보관

---

## 파일 템플릿

### 대사 기획서

```markdown
# {NPC명} 대사 기획 — {상황}

## 개요
- 대상 NPC: {npc_id}
- 트리거: {조건}
- 참조 파일: data/dialogues/{dialogue_id}.ink

## 대사 흐름

### 시작
- {첫 대사}

### 선택지 A: {선택지 텍스트}
- 결과: {대사}
- 효과: {게임 상태 변화}

### 선택지 B: {선택지 텍스트}
- ...

## 필요 리소스
- SCG: {scgc 파일명}
- BGM: {bgm_id}
- SFX: {sfx_name}
```

### 퀘스트 기획서

```markdown
# 퀘스트 기획 — {퀘스트명}

## 개요
- 퀘스트 ID: {quest_id}
- 수여자: {npc_id}
- 시작 조건: {when}

## 단계
1. {목표}
2. {목표}

## 보상
- {아이템/메트릭/플래그}
```

---

## 관련 문서

- 상위: [[README]]
- 기획 가이드: [[planner_guide]]
- Ink 대화 가이드: [[ink_guide]]
