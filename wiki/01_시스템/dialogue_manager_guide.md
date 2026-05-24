# Dialogue Manager 대화 시스템 가이드

> 이 문서는 Godot 네이티브 대화 엔진인 **Godot Dialogue Manager** (`.dialogue`)의 대화 작성법 및 확장 기능 사용 가이드입니다.

---

## 1. 개요

### 왜 Dialogue Manager인가?

- **Godot 네이티브 통합**: Godot 에디터 내에서 대화를 바로 편집하고 신속하게 실시간 테스트 및 오타 교정이 가능합니다.
- **간결하고 가독성 높은 문법**: 프로그래머가 아닌 기획자나 작가도 아주 짧은 시간 안에 문법을 학습해 비주얼 노벨 및 이벤트 연출을 구축할 수 있습니다.
- **풍부한 기능의 커스텀 벌룬**: 캐릭터 Standing CG 연출(Hop, Sink), 타이핑 효과, Fast-Forward 배속 진행, UI 숨김 모드 및 대기 상태 인디케이터 커서 애니메이션을 기본 탑재하고 있습니다.

### 파일 흐름

```
작성: .dialogue  --->  Godot 에디터 빌드/캐시  --->  인게임 격발: ActionRunner ---> 화면 표시: Custom Balloon
```

---

## 2. 폴더 구조 및 리소스 경로

| 경로 | 용도 | 설명 |
|---|---|---|
| `data/dialogues/*.dialogue` | 캐릭터 기본 및 특수 대화 파일 | 인게임 ActionRunner가 탐색하는 핵심 대화 폴더 |
| `scenes/ui/dialogue/` | 커스텀 벌룬 UI 씬 및 스크립트 | `balloon.tscn`, `balloon.gd` 등 커스텀 대화창 컴포넌트 |
| `assets/sprites/ui/dialogue/` | 대화창 UI 스프라이트 리소스 | `dialogue_window_1.png` 등 UI 스킨 파일 |
| `assets/sprites/ui/dialogue/cursor/` | 대기 상태 인디케이터 폴더 | 다음 대사 대기 시 회전/점멸하는 화살표 스프라이트 시트 |
| `graphics/scg/` | 캐릭터 스탠딩 CG(SCG) 이미지 | 캐릭터별 대화 이미지 리소스 저장 폴더 |

---

## 3. 기본 문법

### 3.1 대화 블록 (Title/Knot)

모든 대화 블록은 `~ 블록이름` 형태로 선언하며, `===` 구분선을 넣어 가독성을 높입니다.

```dialogue
~ start
===

루이제: "좋은 아침이에요. 기분 좋은 하루네요!"

=> END
```

- 대화가 끝나는 곳에는 반드시 `=> END` 또는 다른 블록으로의 점프(`=> 다른_블록`)를 명시해 주어야 합니다.

### 3.2 캐릭터 대사 및 화자

```dialogue
화자명: "대사 텍스트가 표시됩니다."
```

- 대사 앞뒤의 따옴표(`"`)는 생략이 가능하지만 비주얼 노벨 폰트 가독성을 위해 사용하는 것을 추천합니다.
- 닉네임 시스템이 연동되어 대사에 적힌 `화자명`은 자동으로 번역 키 및 별명 매핑 프로세스를 통과하게 됩니다.

### 3.3 선택지 (Choice)

선택지는 대시(`-`)로 시작하며, 선택 시 실행할 하위 들여쓰기 내용 또는 다른 블록으로의 점프 경로를 명시합니다.

```dialogue
~ choice_sample
===

루이제: "오늘의 일정을 결정해 주세요."

- 공부를 집중적으로 한다
	루이제: "탁월한 선택이에요. 의지력이 상승할 것 같아요!"
	set player.willpower + 5
	=> start
	
- 외출해서 휴식을 취한다 => ~ go_outside

- 그만 둔다 => END
```

---

## 4. 커스텀 벌룬 확장 연출 기능

### 4.1 스탠딩 CG (SCG) 연출 및 자동 이미지 경로 로드

대사 중간에 캐릭터 스탠딩 CG를 표시하거나 퇴장시킬 수 있도록 `[scg ...]` 커스텀 태그를 지원합니다.

```dialogue
[scg scgl hop luise_smile]
모리건: "후후, 그렇게 긴장하지 않아도 괜찮아."
```

#### SCG 태그 매개변수 구조:
`[scg 위치 연출형태 이미지명]`

1. **위치 (`scg_id`)**: `scgl` (좌측), `scgr` (우측), `scgc` (중앙)
2. **연출형태 (`scg_appearance`)**: `hop` (가볍게 위로 점프), `sink` (아래로 살짝 내려앉기), `slide` / `slidex` (옆에서 미끄러져 들어오기), `fade` (서서히 나타나기)
3. **이미지명 (`scg_file_name`)**: 이미지 로드 경로 결정 키

#### 📂 극도로 편리한 이미지 경로 자동 탐색 매핑:
프로젝트 내에서 캐릭터별, 용도별 애셋 추가 및 관리가 편리하도록 다음 순서대로 디스크의 실재 이미지를 추적하여 매핑합니다:

1. **캐릭터 폴더 구조 (강력 추천)**: 
   `res://graphics/scg/{character_name}/{expression}.png`
   - 예: `luise_smile` 혹은 `luise/smile`로 인자를 받으면 → `res://graphics/scg/luise/smile.png` 자동 로드
2. **플랫 단일 파일 구조**: 
   `res://graphics/scg/{character_name}_{expression}.png`
   - 예: `res://graphics/scg/luise_smile.png` 로드
3. **폴백 직접 구조**: 
   `res://graphics/scg/{scg_file_name}.png`

### 4.2 오디오 연출

스탠딩 CG의 애니메이션 격발과 동기화되어 `hop_1.mp3` 및 `sink_1.mp3` 등의 이펙트 사운드가 에디터 설정 기반으로 자동 출력됩니다.

### 4.3 고급 인게임 상태 제어

대화 리스크립트 구문 내에서 직접 변수나 글로벌 매니저를 호출하여 상호작용할 수 있습니다.

```dialogue
# 1. 턴제 행동력(AP) 또는 스태미나 소모하기
do ActionRunner.run({"type": "spend_ap", "amount": 3})
do ActionRunner.run({"type": "change_metric", "key": "player.stamina", "amount": -10})

# 2. 전역 플래그 설정 및 상태카드 부여
do ActionRunner.run({"type": "set_flag", "key": "is_luise_met", "value": true})
do ActionRunner.run({"type": "add_condition", "condition_id": "exhausted"})

# 3. 브금(BGM) 제어
do BGMManager.push_bgm_by_name("bgm_tension")
루이제: "주변의 공기가 갑자기 무거워진 것 같아요..."
do BGMManager.pop_bgm()
```

---

## 5. 인게임 편의 기능 조작키

유저 인터페이스 조작감 극대화를 위해 커스텀 벌룬 스크립트에 다음과 같은 기능들이 하드코딩 없이 통합 구현되어 있습니다:

- **대화 속도 배속 (Fast-Forward)**: 대화 도중 `Ctrl` 키를 누르고 있으면 4.0배속으로 대화 텍스트가 타이핑되며, 대기 상태에서 선택지가 없는 경우 자동으로 다음 대사로 점프합니다. (배속 시 우측 하단에 `FF` 인디케이터가 활성화됩니다.)
- **대화 UI 숨기기 (Hide UI)**: `Tab` 키를 누르면 진행 중인 대화창 및 선택지 상자가 숨겨져, 백그라운드의 일러스트나 Standing CG를 방해 없이 감상할 수 있습니다. 한 번 더 누르면 이전 상태로 완벽히 복원됩니다.
- **한 손 조작 포커스 분산화**: 마우스 클릭뿐 아니라 키보드의 `Space`, `Enter`, `J` 키로 대사 넘기기 및 타이핑 즉시 스킵(Skip Typing)이 양방향 연동됩니다.

---

*마지막 수정: 2026-05-24 by Antigravity*
