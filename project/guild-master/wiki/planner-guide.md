# 프로젝트 기획자용 가이드

> **대상 독자**: 프로그래머가 아닌 기획자, 디자이너, 스토리 작가  
> **목적**: Godot 에디터에서 작업할 때 알아야 할 기본 구조와 파일 사용법

---

## 1. 프로젝트 개요

**비주얼 노벨 + 라이프 시뮬레이션** 기반의 게임 엔진입니다.  
스토리 중심의 대화 시스템과 행동 선택, 성장 시스템을 조합할 수 있습니다.

### 기본 기능
- **대화 시스템**: Dialogue Manager 플러그인 (코딩 없이 `.dialogue` 파일 작성)
- **BGM 시스템**: 스택 기반 BGM 관리
- **저장/불러오기**: 3개 슬롯
- **설정**: 해상도, 음량, 언어(한국어/영어/일본어)

---

## 2. 폴더 구조

```
project/
├── addons/               ← 플러그인 (수정 금지)
│   └── dialogue_manager/
├── assets/
│   ├── fonts/           ← 글꼴
│   └── translations/    ← 번역 파일
├── audio/               ← 오디오 파일
├── graphics/            ← 이미지 파일
├── scenes/
│   ├── ui/             ← UI 화면
│   └── gameplay/       ← 게임 플레이 화면
├── scripts/
│   ├── core/           ← 시스템 핵심
│   ├── ui/             ← UI 스크립트
│   └── components/     ← 재사용 컴포넌트
└── Story/
    └── Dialogues/       ← 대화 파일
        └── custom_balloon/  ← 대화창 디자인
```

### 기획자 작업 폴더

| 폴더 | 용도 | 파일 형식 |
|------|------|-----------|
| `scenes/ui/` | UI 화면 편집 | `.tscn` |
| `Story/Dialogues/` | 대화 작성 | `.dialogue` |
| `graphics/` | 이미지 추가 | `.png`, `.jpg` |
| `audio/` | 오디오 추가 | `.mp3`, `.ogg` |

---

## 3. 대화 파일 (.dialogue)

**위치**: `Story/Dialogues/`

### 기본 문법

```dialogue
~ start
===

# 캐릭터 대사
주인공: 오늘은 무엇을 할까?

# 선택지
- 공부한다 => 공부_장면
- 외출한다 => 외출_장면
- 휴식한다 => ~ end

~ 공부_장면
주인공: 열심히 공부해야겠다.
set study + 10
=> start

~ 외출_장면
do BGMManager.push_bgm_by_name("bgm_exploration")
주인공: 밖으로 나가볼까.
do BGMManager.pop_bgm()
=> start
```

### 문법 요약

| 문법 | 설명 | 예시 |
|------|------|------|
| `~ 이름` | 대화 블록 시작 | `~ start` |
| `캐릭터: 대사` | 대사 | `주인공: 안녕` |
| `- 선택지 => 목적지` | 선택지 | `- 예 => 다음` |
| `=> 목적지` | 이동 | `=> start` |
| `[if 조건]` | 조건 | `[if score > 10]` |
| `set 변수 +/- 값` | 변수 변경 | `set score + 5` |
| `do 함수()` | 함수 호출 | `do play_sound("sfx")` |

### BGM 제어

| Dialogue 명령 | 설명 |
|---------------|------|
| `do BGMManager.push_bgm_by_name("이름")` | 현재 BGM 저장하고 새 BGM |
| `do BGMManager.pop_bgm()` | 이전 BGM 복원 |
| `do BGMManager.play_bgm_by_name("이름")` | 바로 BGM 변경 |

---

## 4. BGM 설정

### BGMManager 인스펙터 설정

**위치**: `scripts/core/bgm_manager.gd`

```
BGM Tracks
├── Bgm Title       ← 타이틀 화면용
├── Bgm Exploration ← 탐색/기본 플레이용
├── Bgm Event       ← 이벤트/특수 장면용
├── Bgm Emotional   ← 감정/로맨스용
└── Bgm Tension     ← 긴장/위기용
```

### 스택 시스템

1. `push_bgm_by_name("bgm_emotional")` → 현재 BGM 저장 + 새 BGM
2. `pop_bgm()` → 저장된 BGM 복원

---

## 5. UI 씬 (.tscn)

**위치**: `scenes/ui/`

| 파일명 | 용도 |
|--------|------|
| `title_screen.tscn` | 타이틀 화면 |
| `splash_screen.tscn` | 스플래시 화면 |
| `settings_screen.tscn` | 설정 화면 |
| `save_load_screen.tscn` | 저장/불러오기 |

### 편집 방법

1. **FileSystem**에서 `.tscn` 더블클릭
2. **2D 탭**에서 UI 배치
3. **Inspector**로 텍스트, 색상 수정

---

## 6. 새 콘텐츠 추가

### 새 대화 장면

1. `Story/Dialogues/`에 `.dialogue` 파일 생성
2. 대화 작성
3. `project.godot`의 `locale/translations_pot_files`에 경로 추가

### 새 BGM

1. `audio/`에 MP3/OGG 복사
2. **BGMManager** 인스펙터에 드래그

### 새 캐릭터 이미지

1. `graphics/`에 PNG 복사
2. **Import** 탭에서 설정

---

## 7. 번역

### 지원 언어
- 한국어 (ko)
- 영어 (en)
- 일본어 (ja)

### 파일 위치
`assets/translations/dialogue/`, `assets/translations/ui/`

---

## 8. 문제 해결

| 문제 | 해결 방법 |
|------|-----------|
| 대화창 안 나옴 | **Project → Plugins**에서 DialogueManager 활성화 |
| BGM 안 나옴 | BGMManager 인스펙터에서 파일 드래그 |
| 폰트 깨짐 | `assets/fonts/` 확인 |

---

## 9. 단축키

| 단축키 | 기능 |
|--------|------|
| `F5` | 프로젝트 실행 |
| `Ctrl+S` | 저장 |
| `Ctrl+Z` | 실행 취소 |

---

*마지막 수정: 2026-04-20*
