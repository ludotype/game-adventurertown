# Ink 대화 시스템 가이드

> 이 문서는 Dialogue Manager (`.dialogue`)에서 Ink (`.ink`)로 전환한 후의 새로운 대화 작성 방법을 설명합니다.

---

## 1. 개요

### 왜 Ink인가?

- **검증된 컴파일러**: `inklecate`가 문법 오류를 미리 잡아줍니다.
- **강력한 변수/조건**: 게임 상태에 따라 선택지를 숨기거나 노출할 수 있습니다.
- **표준 도구**: Inky 에디터로 시각적으로 편집 가능합니다.
- **산업 표준**: `Hades`, `80 Days`, `Overboard` 등에서 사용됩니다.

### 파일 흐름

```
작성: .ink  --->  컴파일: inklecate  --->  런타임: .ink.json  --->  Godot: InkBalloon
```

---

## 2. 폴더 구조

| 경로 | 용도 |
|---|---|
| `data/dialogues/*.ink` | NPC 기본 대화 (엘레나, 루이세 등) |
| `Story/Dialogues-samples/**/*.ink` | 이벤트/서막/엔카운터 등 샘플 대화 |
| `tools/convert_dialogue_to_ink.py` | (레거시) `.dialogue` → `.ink` 변환기 |

**컴파일된 `.ink.json` 파일도 같은 폴더에 함께 두세요.** ActionRunner는 `.ink.json`를 검색합니다.

---

## 3. 기본 문법

### 3.1 매듭 (Knot) — 대화의 시작점

Ink에서는 `~ title` 대신 `=== title ===`를 사용합니다.

```ink
=== start ===

안녕하세요. # speaker=엘레나

-> END
```

- 첫 번째 매듭 위에 `-> start` 같은 진입점이 자동으로 삽입됩니다.
- `=> END` 대신 `-> END`를 사용합니다.

### 3.2 텍스트와 화자

```ink
좋은 아침이에요. # speaker=엘레나
```

- **Dialogue Manager**: `엘레나: "좋은 아침이에요."`
- **Ink**: `"좋은 아침이에요. # speaker=엘레나"`

화자 이름 뒤에 태그를 붙이는 형태입니다.

### 3.3 선택지 (Choice)

```ink
* 지금 시간이 어떻게 되지?
  시간은 화면 왼쪽 위에 표시되고 있어. # speaker=엘레나

* 잠시 이야기한다
  ~ advance_time(1)
  짧은 대화였지만, 시간은 흘렀어요. # speaker=엘레나

* 그만 간다
  필요하면 다시 말을 걸어 주세요. # speaker=엘레나

-> END
```

- `*` 로 시작합니다.
- 선택지 본문은 **탭(indent)**으로 들여씁니다.
- Ink 선택지는 `[대괄호]`로 텍스트를 감싸지 **않습니다**. (감싸면 파서 오류가 날 수 있어요.)

### 3.4 이동 (Divert)

```ink
-> other_knot
-> END
```

- 다른 매듭으로 이동할 때 사용합니다.

---

## 4. 태그 시스템

Ink 태그는 `# 키=값` 형태로, 줄 끝에 붙입니다. InkBalloon이 이를 해석합니다.

| 태그 | 예시 | 설명 |
|---|---|---|
| `# speaker` | `# speaker=모리건` | 화자 이름 표시 |
| `# id` | `# id=intro_01` | 대사 고유 ID (로컬라이제이션/디버깅) |
| `# scgc` | `# scgc=hop_morigan_smile` | **중앙** 캐릭터 CG (appearance_fileName) |
| `# scgl` | `# scgl=slideup_elena_default` | **왼쪽** 캐릭터 CG |
| `# scgr` | `# scgr=sink_luise_angry` | **오른쪽** 캐릭터 CG |
| `# bg` | `# bg=inn_room` | 배경 변경 |
| `# sfx` | `# sfx=knock_wood` | 효과음 재생 |
| `# camera` | `# camera=pan_left` | 카메라 연출 |
| `# auto` | `# auto` | 자동 진행 |
| `# time` | `# time=2.0` | 자동 진행 대기 시간 |

### CG 태그 상세

```ink
# scgc=slideup_placeholder_staffroom
```

- `scgc` = 위치 (c=center, l=left, r=right)
- `slideup` = 애니메이션 이름
- `placeholder_staffroom` = 파일명 (또는 캐릭터_파일명)

---

## 5. 외부 함수 (External Functions)

Ink 내부에서 Godot 게임 상태를 직접 조작할 수 있습니다. `~` 기호로 호출합니다.

```ink
~ set_flag("has_manual", true)
~ change_metric("sanity", -5)
~ add_item("it_managers_badge", 1)
~ advance_time(1)
~ play_sfx("knock_wood")
~ move("loc_lobby")
~ trigger_game_over("doom_maxed", "normal")
```

### 지원 목록

| 함수 | 예시 | 설명 |
|---|---|---|
| `set_flag(key, value)` | `~ set_flag("has_key", true)` | 불리언/숫자/문자열 플래그 설정 |
| `set_metric(key, value)` | `~ set_metric("sanity", 50)` | 수치형 변수 설정 |
| `change_metric(key, amount)` | `~ change_metric("sanity", 10)` | 수치 증감 (+/-) |
| `spend_ap(amount)` **(New)** | `~ spend_ap(3)` | 행동력(AP) 소모 |
| `advance_time(units)` **(Legacy)** | `~ advance_time(1)` | [폐기 예정] 레거시 시간 진행 |
| `advance_minutes(min)` **(Legacy)** | `~ advance_minutes(30)` | [폐기 예정] 레거시 분 단위 시간 진행 |
| `sleep_until_next_day()` **(Legacy)** | `~ sleep_until_next_day()` | [폐기 예정] 다음 날까지 휴면 (AP 소모 완료 후 휴식 행동으로 대체) |
| `add_item(id, amount)` | `~ add_item("potion", 2)` | 인벤토리에 아이템 추가 |
| `remove_item(id, amount)` | `~ remove_item("potion", 1)` | 아이템 제거 |
| `equip_item(id)` | `~ equip_item("sword")` | 아이템 장착 |
| `move(target)` | `~ move("loc_basement")` | 플레이어 이동 |
| `change_doom(amount)` | `~ change_doom(10)` | Doom 게이지 증가 |
| `block_place(id, reason)` | `~ block_place("loc_basement", "locked")` | 장소 차단 |
| `unblock_place(id)` | `~ unblock_place("loc_basement")` | 장소 차단 해제 |
| `add_condition(id, dur, stack)` | `~ add_condition("poison", 3, 1)` | 상태 이상 부여 |
| `remove_condition(id)` | `~ remove_condition("poison")` | 상태 이상 제거 |
| `open_ui(name)` | `~ open_ui("inventory")` | UI 열기 |
| `random_loot(table)` | `~ random_loot("dungeon_a")` | 랜덤 전리품 |
| `trigger_mandatory(on)` | `~ trigger_mandatory("morning")` | 강제 이벤트 트리거 |
| `start_dialogue(id)` | `~ start_dialogue("elena_touch")` | 다른 대화 시작 |
| `set_nickname(char, nick)` | `~ set_nickname("Player", "NICK_PLAYER")` | 캐릭터 별명 설정 |
| `play_sfx(name)` | `~ play_sfx("click")` | 효과음 재생 |
| `trigger_game_over(r, t)` | `~ trigger_game_over("death", "normal")` | 게임 오버 |
| `log(message)` | `~ log("Something happened")` | 로그 출력 |

---

## 6. 조건과 변수

### 6.1 선택지 조건

```ink
* { sanity > 50 } 자신감 있게 대답한다.
  오? 당신 자신감 있네요. # speaker=모리건

* { sanity <= 50 } 겁먹은 채 대답한다.
  ...뭔가 위험한 건가요? # speaker=모리건
```

- `{ 조건 }`을 선택지 `*` 바로 뒤에 붙입니다.
- `Flags.` 접두사는 **생략**합니다. `Flags.sanity > 50` → `sanity > 50`
- Ink 내부 변수와 Godot의 `MetricStore`/`Flags`는 실행 시 동기화됩니다.

### 6.2 VAR 선언

조건에 쓰이 변수는 파일 최상단에 선언해야 컴파일이 됩니다.

```ink
VAR sanity = 50
VAR has_manual = false
VAR current_room_id = ""
```

변환 스크립트는 자동으로 `Flags.xxx`를 찾아 `VAR xxx = 0`를 생성하지만, 기본값이 0이므로 필요하면 `.ink` 파일에서 직접 수정하세요.

---

## 7. 컴파일 방법

### 7.1 Python 스크립트로 일괄 변환 (레거시 `.dialogue`가 있을 때)

```bash
cd D:\GIT\game-guildmaster
python tools/convert_dialogue_to_ink.py
```

- 모든 `.dialogue`를 `.ink`로 변환하고 `inklecate`로 `.ink.json`를 생성합니다.

### 7.2 단일 파일 수동 컴파일

```bash
cd project/guild-master
tools/inklecate/inklecate.exe -o data/dialogues/my_dialogue.ink.json data/dialogues/my_dialogue.ink
```

`.ink` 파일을 수정한 후 **반드시** `.ink.json`를 재컴파일해야 게임에 반영됩니다.

---

## 8. 실전 예시

### 8.1 간단한 NPC 대화 (레거시 사양)

> [!NOTE]
> 아래 예시는 24시간제 세밀한 시간 시스템(`advance_time`) 기준의 레거시 작성 방식입니다.
> 현재 기획 표준인 행동력(AP) 시스템을 따를 때는 `spend_ap(amount)` 외부 함수를 사용해야 합니다.

```ink
EXTERNAL advance_time(time_units) // 레거시
EXTERNAL spend_ap(amount)         // 신규

-> start
=== start ===

좋은 아침이에요. # speaker=엘레나

* 지금 시간이 어떻게 되지?
  시간은 화면 왼쪽 위에 표시되고 있어. # speaker=선생
  시스템: 시간이 흐르면 제가 다른 장소에 등장하도록 만들 수 있어요. # speaker=엘레나

* 잠시 이야기하며 힌트를 얻는다 [3 AP 소모]
  ~ spend_ap(3) // 3 AP 소모
  짧은 대화였지만, 행동력을 소모해 단서를 얻었습니다. # speaker=엘레나

* 그만 간다
  필요하면 다시 말을 걸어 주세요. # speaker=엘레나

-> END
```

### 8.2 서막 (Prologue) — 태그와 외부 함수

```ink
EXTERNAL set_flag(key, value)
EXTERNAL add_item(item_id, amount)
EXTERNAL equip_item(item_id)

-> start
=== start ===

# scgc=slideup_placeholder_staffroom
Staff Room, Hotel Morgana. Late night. # id=pro_01

Hey, Are you listening to me? # id=pro_04 # speaker=Morigan

* "Sorry, you were saying?" # id=pro_opt_1
  Morigan sighs, clearly annoyed. # id=pro_06

I am *not* accepting your resignation. # id=pro_07 # speaker=Morigan

* [Pick up Eric's Manual] # id=pro_opt_6
  // TODO: manual convert: do Flags.has_manual = true
  The TV hums to life. # id=pro_28

* [Pick up the Manager's Badge] # id=pro_opt_8
  ~ add_item("it_managers_badge", 1)
  [Open your INVENTORY...] # id=pro_42 # speaker=System

-> END
```

---

## 9. 주의사항

1. **항상 컴파일하세요**: `.ink`를 고쳤으면 `.ink.json`도 같이 재생성해야 합니다.
2. **선택지에 `]`를 쓸 때**: `[Pick up]` 같은 텍스트는 그대로 쓰면 됩니다. (이전 버전에서는 `[대괄호]`로 감싸서 문제가 생겼지만, 현재는 감싸지 않습니다.)
3. **화자 콜론 주의**: `Morigan: text` 형태는 **쓰지 마세요**. Ink에서는 콜론을 화자 구분자로 인식하지 않습니다. 반드시 `# speaker=화자` 태그를 사용하세요.
4. **조건문 블록**: `if / else`는 Ink의 `{ }` 문법으로 직접 변환해야 합니다. 자동 변환기는 `// TODO` 주석으로 남겨둡니다.

---

## 10. `.dialogue` → `.ink` 비교표

| Dialogue Manager | Ink | 비고 |
|---|---|---|
| `~ start` | `=== start ===` | 매듭 선언 |
| `Character: "Line"` | `Line # speaker=Character` | 화자는 태그로 |
| `- "Choice"` | `* Choice` | 선택지 본문은 탭 들여쓰기 |
| `=> END` | `-> END` | 종료 |
| `=> title` | `-> title` | 매듭 이동 |
| `[ID:xxx]` | `# id=xxx` | 고유 ID 태그 |
| `[scgc slideup file]` | `# scgc=slideup_file` | CG 태그 |
| `do ActionRunner.run(...)` | `~ function_name(...)` | 외부 함수 |
| `[if Flags.xxx > 0]` | `{ xxx > 0 }` | `Flags.` 생략 |
| `set Flags.xxx = true` | `~ set_flag("xxx", true)` | 플래그 설정 |
| `do Flags.xxx += 10` | `~ change_metric("xxx", 10)` | 수치 변경 |

---

## 참고 링크

- [Ink Language Tutorial](https://www.inklestudios.com/ink/) (공식)
- [inkgd 문서](https://github.com/ephread/inkgd) (Godot 런타임)
- 프로젝트 내 예시: `data/dialogues/elena_default.ink`
- 프로젝트 내 예시: `Story/Dialogues-samples/Intro/prologue_main.ink`

---

## 관련 문서

- 시스템 폴더: [[01_시스템/README]]
- 기획자 가이드: [[planner_guide]]
- 아키텍처 원칙: [[architecture]]
- 컨텐츠 전달함: [[content-inbox/README]]
