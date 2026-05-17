# Planner Guide - 장소 / NPC 등장 / 이동·행동 시스템

> 이 문서는 프로그래머가 아닌 기획자/디자이너를 위한 가이드입니다.
> JSON 파일만 수정하면 장소 구성, NPC 등장 규칙, 이동 경로, 행동 선택지를 변경할 수 있습니다.

---

## 개요

각 장소(Place)에 들어갈 때, 해당 장소에 **랜덤으로 NPC 1명**이 등장하거나 **아무도 없을** 수 있습니다.

모든 확률은 **가중치(Weight)** 시스템으로 계산됩니다. 각 NPC마다 가중치 숫자를 부여하면, 시스템이 자동으로 "이 장소에서 누가 얼마나 자주 등장하는지"를 계산해줍니다.

**핵심 원칙:** `data/npc_schedules/` 폴더에 JSON 파일을 추가·제거만 하면 됩니다. 어떤 중앙 파일도 수정할 필요가 없어요.

---

## 1. 장소 설정 (`data/places/`)

각 장소마다 하나의 JSON 파일이 있습니다.

### 파일 예시: `inn_room.json`

```json
{
  "place_id": "inn_room",
  "display_name": "여관방",
  "background_path": "res://assets/bg/inn_room.png",
  "bgm": "inn_calm",
  "empty_weight": 100,
  "connections": ["hallway"]
}
```

### 필드 설명

| 필드 | 설명 |
|------|------|
| `place_id` | 내부 ID. 파일명과 같아야 합니다. |
| `display_name` | 게임 화면에 표시될 장소 이름 |
| `background_path` | 배경 그림 파일 경로 |
| `bgm` | 이 장소에서 재생될 배경음 ID |
| `empty_weight` | **아무도 없음** 상태의 가중치 (아래 참조) |
| `connections` | 이 장소에서 **이동 가능한 다른 장소 ID 배열** (화면 하단 이동 바에 자동 표시) |

> **플레이어 행동(쉬기, 대화, 연주 등)은 `places` JSON에 넣지 않습니다.** 우측 행동 버튼은 `data/interactions/` 폴더의 JSON 파일이 자동 스캔되어 만들어집니다. 아래 [4. Interaction 시스템](#4-interaction-시스템-datainteractions)을 참고하세요.

### `connections` 작성 규칙

- 배열에 적은 `place_id` 순서대로 화면 하단의 이동 버튼이 좌→우로 배치됩니다.
- 양방향 이동이 필요하면 **두 장소 양쪽에 서로의 ID를 적어야** 합니다.
  - 예: `inn_room.json`의 `connections: ["hallway"]` + `hallway.json`의 `connections: ["inn_room"]`
- 존재하지 않는 `place_id`를 적으면 콘솔에 경고가 출력되고 해당 버튼은 표시되지 않습니다.

### 맵을 텍스트로 표현하기

기획 단계에서는 다음처럼 `-`로 연결해서 쓰면 충분합니다.

```
여관방 - 복도 - 여관 로비 - 남쪽 거리 - 중앙 광장 - 북쪽 거리 - 선술집
                         |                        |
                      무기상                    꽃집
```

남쪽 거리에서 **무기상**, 북쪽 거리에서 **꽃집**으로 들어갈 수 있습니다. 되돌아오는 이동은 각 상점 JSON의 `connections`로 연결됩니다.

| 표시 이름 | place_id |
|------|------|
| 여관방 | `inn_room` |
| 복도 | `hallway` |
| 여관 로비 | `lobby` |
| 남쪽 거리 | `street_south` |
| 무기상 | `weapon_shop` |
| 중앙 광장 | `town_square` |
| 북쪽 거리 | `street_north` |
| 꽃집 | `flower_shop` |
| 선술집 | `tavern` |

### 현재 지원하는 행동 타입 (ActionRunner)

| type | 필수 필드 | 설명 |
|------|----------|------|
| `log` | `message` | 콘솔에 메시지를 출력합니다. 임시 행동 확인용입니다. |
| `move` | `target_place` | 지정한 장소로 이동합니다. |
| `dialogue` | `dialogue_id` | 대화 파일을 실행합니다. 현재 `data/dialogues/`, `Story/Dialogues-samples/`, `Story/Dialogues/`에서 찾습니다. |
| `set_flag` | `key`, `value` | 게임 플래그를 설정합니다. |
| `set_metric` | `key`, `value` | 이름표가 붙은 숫자 값을 지정합니다. |
| `change_metric` | `key`, `amount` | 이름표가 붙은 숫자 값을 증가/감소시킵니다. |
| `advance_time` | `time_units` | 기본 시간 단위만큼 시간을 진행합니다. 기본값은 1입니다. |
| `advance_minutes` | `minutes` | 예외적으로 정확한 분 단위만큼 시간을 진행합니다. |
| `sleep_until_next_day` | 없음 | 다음 날 아침으로 이동합니다. |
| `sequence` | `actions` | 여러 행동을 순서대로 실행합니다. |
| `if` | `when`, `then`, `else` | 조건에 따라 다른 행동을 실행합니다. |
| `game_over` | `reason`, `game_over_type` | 게임 오버를 발생시킵니다. (`normal`, `doom`, `heroine`) |
| `attribute_check` | `attribute`, `difficulty` | 속성 체크를 수행합니다. 성공/실패 시 각각 다른 행동을 실행합니다. |
| `add_condition` | `condition_id`, `duration`, `stack` | 플레이어에게 상태 카드를 부여합니다. |
| `remove_condition` | `condition_id` | 플레이어의 상태 카드를 제거합니다. |
| `change_doom` | `amount` | 전역 둠 트래커를 증감합니다. |
| `block_place` | `place_id`, `reason` | 특정 장소를 봉쇄하여 이동 불가로 만듭니다. |
| `unblock_place` | `place_id` | 봉쇄된 장소를 다시 이동 가능하게 합니다. |
| `add_item` | `item_id`, `amount` | 아이템을 인벤토리에 추가합니다. |
| `remove_item` | `item_id`, `amount` | 아이템을 인벤토리에서 제거합니다. |
| `equip_item` | `item_id` | 장비 아이템을 장착합니다. |
| `unequip_item` | `item_id` | 장비 아이템을 해제합니다. |
| `open_ui` | `ui_name` | UI 창을 엽니다. (`inventory` 지원) |
| `random_loot` | `table_id` | 지정된 전리품 테이블에서 랜덤 아이템을 획득합니다. |
| `outcome_check` | `attribute`, `difficulty`, `outcomes` | 속성 체크를 4분기로 수행합니다. (`critical_success` / `success` / `failure` / `critical_failure`) |
| `trigger_mandatory` | `trigger_on` | 특정 trigger를 발동시켜 `data/mandatory_events/`의 강제 이벤트를 검사합니다. |

### `outcome_check` 작성 예시

`outcome_check`는 속성 체크 결과를 **4분기**로 나눠서 서로 다른 행동을 실행합니다.

```json
{
  "type": "outcome_check",
  "attribute": "luck",
  "difficulty": 2,
  "outcomes": {
    "critical_success": {
      "actions": [{ "type": "change_metric", "key": "player.gold", "amount": 50 }],
      "message": "대박! 상상도 못한 큰돈을 따냈다!"
    },
    "success": {
      "actions": [{ "type": "change_metric", "key": "player.gold", "amount": 30 }],
      "message": "큰돈을 따냈다!"
    },
    "failure": {
      "actions": [
        { "type": "change_metric", "key": "player.gold", "amount": -20 },
        { "type": "add_condition", "condition_id": "debt", "duration": 5 }
      ],
      "message": "빚을 졌다. 사채업자가 당신을 기억할 것이다."
    },
    "critical_failure": {
      "actions": [
        { "type": "change_metric", "key": "player.gold", "amount": -30 },
        { "type": "add_condition", "condition_id": "debt", "duration": 5 },
        { "type": "add_condition", "condition_id": "hunted", "duration": 3 }
      ],
      "message": "짝패들에게 들켰다. 뒷골목을 조심하자."
    }
  }
}
```

판정 공식은 `1d6 + attribute >= difficulty * 3`입니다.
- **대성공**: 성공치가 3 이상 높음
- **성공**: 기준치 이상
- **실패**: 기준치 미만
- **대실패**: 기준치보다 3 이상 낮음

### 현재 지원하는 조건 타입

| condition | 예시 | 설명 |
|-----------|------|------|
| `flag_eq` | `{ "flag_eq": ["met_luise", true] }` | 플래그 값이 같은지 확인합니다. |
| `metric_eq` | `{ "metric_eq": ["npc.elena.affection", 3] }` | metric 값이 정확히 같은지 확인합니다. |
| `metric_gte` | `{ "metric_gte": ["npc.elena.affection", 3] }` | metric 값이 지정값 이상인지 확인합니다. |
| `metric_lte` | `{ "metric_lte": ["npc.elena.affection", 3] }` | metric 값이 지정값 이하인지 확인합니다. |
| `metric_gt` | `{ "metric_gt": ["npc.elena.affection", 3] }` | metric 값이 지정값보다 큰지 확인합니다. |
| `metric_lt` | `{ "metric_lt": ["npc.elena.affection", 3] }` | metric 값이 지정값보다 작은지 확인합니다. |
| `at_place` | `{ "at_place": "inn_room" }` | 현재 장소가 맞는지 확인합니다. |
| `time_block` | `{ "time_block": "morning" }` | 현재 시간 블록이 맞는지 확인합니다. |
| `time_in` | `{ "time_in": ["morning", "afternoon"] }` | 현재 시간 블록이 목록 안에 있는지 확인합니다. |
| `hour_range` | `{ "hour_range": [9, 18] }` | 현재 시각이 09:00 이상 18:00 미만인지 확인합니다. |
| `time_range` | `{ "time_range": ["23:00", "02:00"] }` | 현재 시각이 정확한 시간 범위 안에 있는지 확인합니다. 자정을 넘는 범위도 가능합니다. |
| `day_eq` | `{ "day_eq": 3 }` | 현재 날짜가 정확히 같은지 확인합니다. |
| `day_gte` | `{ "day_gte": 5 }` | 현재 날짜가 지정한 날짜 이상인지 확인합니다. |
| `all_of` | `{ "all_of": [조건1, 조건2] }` | 모든 조건을 만족해야 합니다. |
| `any_of` | `{ "any_of": [조건1, 조건2] }` | 하나라도 만족하면 됩니다. |
| `not` | `{ "not": 조건 }` | 조건 결과를 반대로 뒤집습니다. |
| `crisis_active` | `{ "crisis_active": "nightmare_town" }` | 특정 위기가 현재 활성 상태인지 확인합니다. |
| `doom_gte` | `{ "doom_gte": 10 }` | 전역 둠 트래커가 지정값 이상인지 확인합니다. |
| `has_condition` | `{ "has_condition": "haunted" }` | 플레이어가 특정 상태 카드를 보유 중인지 확인합니다. |
| `place_blocked` | `{ "place_blocked": "tavern" }` | 특정 장소가 봉쇄 상태인지 확인합니다. |
| `has_item` | `{ "has_item": "holy_symbol" }` 또는 `{ "has_item": ["holy_symbol", 2] }` | 인벤토리에 특정 아이템(지정 개수 이상)이 있는지 확인합니다. |

### 시간 시스템

게임 내부 시간은 24시간제입니다. 화면에는 `Day 1 07:00`처럼 표시됩니다.

기본 행동 시간 소모량은 **time unit**으로 작성합니다. JSON에서는 `time_units` 필드를 사용합니다.

- 기본값: `time_units: 1`
- 현재 기준: `1 time_unit = 30분`
- 밸런스 변경 시 `TimeSystem.minutes_per_time_unit`만 바꾸면 전체 행동 시간이 같이 조정됩니다.

시간 블록은 기획자가 편하게 쓰기 위한 별칭입니다.

```
dawn        05:00 ~ 07:00
morning     07:00 ~ 12:00
noon        12:00 ~ 13:00
afternoon   13:00 ~ 18:00
evening     18:00 ~ 22:00
night       22:00 ~ 24:00
late_night  00:00 ~ 05:00
```

예를 들어 복도에서 "잠시 기다리기" 행동을 만들려면 다음처럼 작성합니다.

```json
{ "id": "wait", "label": "잠시 기다리기", "type": "advance_time", "time_units": 1 }
```

정확히 10분만 흐르게 해야 하는 예외 상황은 `advance_minutes`를 사용합니다.

```json
{ "id": "short_wait", "label": "잠깐 기다리기", "type": "advance_minutes", "minutes": 10 }
```

여관방에서 잠을 자고 다음 날 아침으로 넘기려면 다음처럼 작성합니다.

```json
{
  "id": "sleep",
  "label": "잠자고 하루 넘기기",
  "type": "sequence",
  "actions": [
    { "type": "trigger_mandatory", "trigger_on": "rest_attempt" },
    { "type": "sleep_until_next_day" },
    { "type": "set_flag", "key": "rested_today", "value": false },
    { "type": "log", "message": "새로운 아침이 밝았다." }
  ]
}
```

시간 조건이 붙은 행동도 만들 수 있습니다.

```json
{
  "id": "night_watch",
  "label": "밤 경비를 살핀다",
  "type": "log",
  "message": "복도 끝에서 야간 경비의 발소리가 들린다.",
  "when": { "time_block": "night" }
}
```

---

## 2. Metric 시스템 (`MetricStore`)

Metric은 게임 안에서 계속 변하는 숫자 값입니다.

예를 들어 다음 값들은 모두 metric으로 관리할 수 있습니다.

```
npc.elena.affection
npc.elena.mood
npc.luise.trust
place.tavern.clean_count
player.music
global.town_safety
```

MetricStore는 이 이름표와 숫자 값을 저장합니다. 코드에는 미리 `affection`, `mood`, `clean_count` 같은 목록을 등록하지 않습니다.

즉, 새 변수가 필요하면 JSON에서 새 key를 쓰면 됩니다.

```json
{ "type": "change_metric", "key": "npc.elena.affection", "amount": 1 }
```

위 행동을 실행하면 `npc.elena.affection` 값이 1 증가합니다. 기존 값이 없다면 0으로 보고 시작합니다.

### 권장 key 규칙

| 범위 | 형식 | 예시 |
|------|------|------|
| NPC 값 | `npc.{npc_id}.{metric}` | `npc.elena.affection`, `npc.luise.mood` |
| 장소 값 | `place.{place_id}.{metric}` | `place.tavern.clean_count` |
| 플레이어 값 | `player.{metric}` | `player.music`, `player.strength` |
| 전역 값 | `global.{metric}` | `global.town_safety` |

### 값 변경

값을 정확히 지정하려면 `set_metric`을 사용합니다.

```json
{ "type": "set_metric", "key": "npc.elena.mood", "value": 50 }
```

값을 더하거나 빼려면 `change_metric`을 사용합니다.

```json
{ "type": "change_metric", "key": "npc.elena.affection", "amount": 1 }
```

```json
{ "type": "change_metric", "key": "npc.elena.mood", "amount": -2 }
```

### 조건으로 사용

interaction 이벤트의 `when`에 metric 조건을 넣을 수 있습니다.

```json
{
  "id": "elena_touch_friendly",
  "priority": 60,
  "when": { "metric_gte": ["npc.elena.affection", 3] },
  "actions": [
    { "type": "dialogue", "dialogue_id": "elena_touch_friendly" }
  ]
}
```

위 예시는 `npc.elena.affection` 값이 3 이상일 때만 선택됩니다.

### 왜 코드 등록이 필요 없는가

MetricStore는 key 이름의 의미를 해석하지 않습니다. `npc.elena.affection`이 호감도인지, `place.tavern.clean_count`가 청소 횟수인지 몰라도 됩니다.

시스템은 단순히 다음 규칙으로 동작합니다.

1. 해당 key가 있으면 값을 읽는다.
2. 해당 key가 없으면 기본값 0으로 본다.
3. 값을 바꾸면 그 key로 저장한다.

그래서 새 metric을 만들 때 코드 수정이 필요 없습니다.

### 주의할 점

오타가 나면 새 key로 취급됩니다.

```
npc.luise.affection
npc.lusie.affection
```

위 둘은 서로 다른 값입니다. 따라서 자주 쓰는 key는 문서나 예시 JSON에서 복사해서 쓰는 것을 권장합니다.

---

## 3. NPC 스케줄 (`data/npc_schedules/`)

각 NPC마다 하나의 JSON 파일이 있습니다. 이 파일에 "어떤 장소에 언제 등장 가능한지"를 적습니다.

### 파일 예시: `elena.json`

```json
{
  "npc_id": "elena",
  "display_name": "엘레나",
  "default_portrait": "res://graphics/scg/morigan_default.png",
  "default_dialogue": "elena_default",
  "schedules": [
    {
      "place_id": "hallway",
      "weight": 10,
      "conditions": {
        "time_of_day": ["morning", "afternoon"]
      }
    },
    {
      "place_id": "town_square",
      "weight": 10,
      "conditions": {
        "time_of_day": ["morning", "afternoon"]
      }
    },
    {
      "place_id": "tavern",
      "weight": 4,
      "conditions": {
        "time_of_day": ["evening", "night"]
      }
    }
  ]
}
```

### 필드 설명

| 필드 | 설명 |
|------|------|
| `npc_id` | NPC 고유 ID |
| `display_name` | 게임 화면에 표시될 이름 |
| `default_portrait` | 장소 화면에 표시될 NPC 초상화 파일 경로 |
| `default_dialogue` | NPC를 클릭했을 때 실행할 기본 대화 ID (`data/dialogues/{id}.ink`) |
| `schedules` | 등장 규칙 배열 (하나의 NPC가 여러 장소에 등장 가능) |
| `schedules[].place_id` | 등장할 장소 ID |
| `schedules[].weight` | 이 장소에서의 추첨 가중치 |
| `schedules[].dialogue_id` | 특정 장소/시간에만 다른 대화를 쓰고 싶을 때 지정 (선택사항) |
| `schedules[].conditions` | 등장 조건 (선택사항) |
| `schedules[].conditions.time_of_day` | 가능한 시간대 배열 (`morning`, `afternoon`, `evening`, `night`) |
| `schedules[].conditions.story_flags` | 필요한 스토리 플래그 배열 (선택사항) |

### NPC 클릭 대화

장소에 등장한 NPC 초상화를 클릭하면 `default_dialogue` 또는 `schedules[].dialogue_id`에 지정된 대화가 실행됩니다.

기본 대화 파일은 다음 위치에 둡니다.

```
project/guild-master/data/dialogues/{dialogue_id}.ink
```

`.ink` 파일을 수정한 후에는 반드시 `inklecate`로 `.ink.json`를 컴파일해야 게임에 반영됩니다.

최소 대화 예시는 다음과 같습니다.

```ink
EXTERNAL advance_time(time_units)

-> start
=== start ===

좋은 아침이에요. # speaker=엘레나

* 잠시 이야기한다
  ~ advance_time(1)
  짧은 대화였지만, 시간은 흘렀어요. # speaker=엘레나

* 그만 간다
  필요하면 다시 말을 걸어 주세요. # speaker=엘레나

-> END
```

---

## 4. Interaction 시스템 (`data/interactions/`)

Interaction은 플레이어가 현재 상황에서 고르는 **맥락 행동(동사)** 입니다.

### 플레이어 행동 목록은 어디에 정의되나?

**한 파일에 전체 목록이 있는 구조가 아닙니다.** 실행 가능한 행동은 아래 폴더에 **JSON 파일 1개 = 버튼 1개** 형태로 흩어져 있고, 게임 시작 시 `InteractionRegistry`가 폴더를 스캔해 우측 패널을 만듭니다.

| 폴더 | 용도 | 예시 `interaction_id` |
|------|------|----------------------|
| `data/interactions/common/` | 어느 장소에서나 (장소 전용이 없을 때) | `standby`, `wait`, `playmusic` |
| `data/interactions/place/{place_id}/` | 특정 장소에서만, 또는 그 장소 맞춤 연출 | `rest`, `sleep`, `look_around` |
| `data/interactions/char/{npc_id}/` | 해당 NPC가 있을 때만 | `talk`, `touch` |

같은 `interaction_id`가 common과 place에 동시에 있으면 **place 쪽이 우선**합니다. (예: `inn_room/standby.json`이 공통 `standby.json`을 덮어씀)

새 행동을 추가하려면 해당 폴더에 JSON 파일을 추가하면 됩니다. 별도의 "행동 마스터 리스트" 파일은 없습니다.

### 폴더 예시

```
data/interactions/
├── common/
│   ├── standby.json
│   ├── wait.json
│   └── playmusic.json
├── place/
│   └── inn_room/
│       ├── rest.json
│       └── sleep.json
└── char/
    └── elena/
        ├── talk.json
        ├── touch.json
        └── standby.json
```

- NPC가 없어도 가능한 행동 → `common/` (또는 장소 전용이면 `place/{place_id}/`)
- 특정 NPC를 대상으로 하는 행동 → `char/{npc_id}/`
- 게임 시작 시 폴더를 자동 스캔하므로 중앙 목록 파일을 수정할 필요가 없습니다.

### 파일 구조

하나의 JSON 파일은 한 interaction에 대한 **여러 이벤트 후보 목록**입니다.

```json
{
  "interaction_id": "touch",
  "label": "접촉",
  "available_when": { "target_npc": "elena" },
  "events": [
    {
      "id": "elena_touch_morning",
      "priority": 30,
      "when": { "time_block": "morning" },
      "actions": [
        { "type": "dialogue", "dialogue_id": "elena_touch_morning" }
      ]
    },
    {
      "id": "elena_touch_default",
      "priority": 0,
      "actions": [
        { "type": "dialogue", "dialogue_id": "elena_touch_default" }
      ]
    }
  ]
}
```

### 필드 설명

| 필드 | 설명 |
|------|------|
| `interaction_id` | 행동 ID. 파일명과 같게 쓰는 것을 권장합니다. |
| `label` | 버튼에 표시될 텍스트 |
| `available_when` | 이 interaction 버튼 자체가 표시될 조건 (선택사항) |
| `events` | 실제로 실행될 이벤트 후보 목록 |
| `events[].id` | 이벤트 고유 ID |
| `events[].priority` | 조건이 여러 개 맞을 때 높은 값이 우선 선택됨 |
| `events[].weight` | 같은 priority 후보가 여러 개일 때 랜덤 가중치 (선택사항) |
| `events[].when` | 이 이벤트가 선택될 조건 (선택사항) |
| `events[].actions` | 선택 시 실행할 ActionRunner 행동 목록 |

### 선택 방식

1. 현재 장소, 시간, 대상 NPC 등 컨텍스트를 만든다.
2. **장소 행동**: `common/` + `place/{현재 place_id}/`를 합치고, 같은 `interaction_id`는 place가 우선한다.
3. **NPC 행동**: `char/{npc_id}/`에서 대상 NPC가 있을 때만 버튼을 붙인다.
4. `available_when`을 만족하고, 실행 가능한 `events`가 하나라도 있는 interaction만 버튼으로 표시한다.
5. 버튼을 누르면 `events` 중 `when`을 만족하는 후보만 남긴다.
6. 후보 중 `priority`가 가장 높은 이벤트를 실행한다.
7. 같은 priority가 여러 개면 `weight`로 랜덤 선택한다.

### Common Interaction 예시

```json
{
  "interaction_id": "playmusic",
  "label": "연주한다",
  "events": [
    {
      "id": "playmusic_late_noise",
      "priority": 50,
      "when": {
        "all_of": [
          { "time_block": ["night", "late_night"] },
          { "not": { "at_place": "inn_room" } }
        ]
      },
      "actions": [
        { "type": "log", "message": "늦은 시각의 서툰 연주에 누군가가 벽을 두드렸다." },
        { "type": "advance_time", "time_units": 1 }
      ]
    }
  ]
}
```

---

## 5. 강제 이벤트 (`data/mandatory_events/`)

강제 이벤트는 플레이어의 의사와 무관하게 **특정 조건이 맞으면 자동으로 실행**되는 이벤트입니다.

`data/mandatory_events/` 폴더에 JSON 파일을 넣으면 `CrisisManager`가 자동으로 스캔합니다.

### 필드 설명

| 필드 | 설명 |
|------|------|
| `event_id` | 이벤트 고유 ID |
| `trigger_on` | 발동 시점 (`day_started`, `place_entered`, `rest_attempt`, `condition_removed`) |
| `when` | 실행 조건 (선택사항). `has_condition` 등을 사용합니다. |
| `priority` | 여러 이벤트가 동시에 발동할 때의 우선순위 (높을수록 먼저) |
| `actions` | 실행할 ActionRunner 행동 목록 |

### 발동 시점

| trigger_on | 언제 발동되는가 |
|-----------|----------------|
| `day_started` | 하루가 시작될 때 (자정, `CrisisManager`가 처리) |
| `place_entered` | 플레이어가 장소에 들어갈 때 (`PlaceScene`이 처리) |
| `rest_attempt` | 잠자기/휴식을 시도할 때 (`sleep.json`의 `trigger_mandatory` action으로 처리) |
| `condition_removed` | 상태 카드가 사라질 때 (`ConditionManager`가 처리) |

### 예시: 추적자 기습

```json
{
  "event_id": "ambush",
  "trigger_on": "place_entered",
  "when": { "has_condition": "hunted" },
  "priority": 80,
  "actions": [
    { "type": "log", "message": "뒷골목에서 누군가가 당신을 덮친다!" },
    {
      "type": "attribute_check",
      "attribute": "observation",
      "difficulty": 2,
      "pass_message": "적의 기습을 미리 눈치채고 피했다.",
      "fail_actions": [
        { "type": "change_metric", "key": "player.hp", "amount": -15 },
        { "type": "add_condition", "condition_id": "injured", "duration": 4 },
        { "type": "remove_condition", "condition_id": "hunted" }
      ]
    }
  ]
}
```

---

## 6. 확률 계산 방식 (가중치 시스템)

### 계산 공식

```
총 가중치 = empty_weight + (조건에 맞는 NPC 가중치들의 합)

각 대상의 등장 확률 = 해당 대상의 가중치 / 총 가중치
```

### 예시: 중앙 광장 (오전)

| 대상 | 가중치 | 계산 | 확률 |
|------|--------|------|------|
| (아무도 없음) | 8 | 8 / 23 | **34.8%** |
| 엘레나 | 10 | 10 / 23 | **43.5%** |
| 꽃집 주인 | 5 | 5 / 23 | **21.7%** |
| **총합** | **23** | | **100%** |

- 엘레나는 `time_of_day: ["morning", "afternoon"]` 조건을 만족 → 참여
- 록은 `time_of_day: ["afternoon"]` 조건 불만족 → 제외

---

## 7. `empty_weight` 활용 가이드

`empty_weight`는 **이 장소가 얼마나 한산한지**를 조절하는 값입니다.

| 상황 | 추천 `empty_weight` | 느낌 |
|------|-------------------|------|
| 사람 많은 광장 | 8 ~ 12 | 종종 비어있음, 종종 사람 있음 |
| 심야의 뒷골목 | 20 ~ 30 | 대부분 비어있음. 드물게 의문의 인물 |
| 여관 로비 | 0 | **항상** 누군가 배치됨 |
| 밤의 선술집 | 2 ~ 4 | 거의 항상 주인이나 단골이 있음 |

`empty_weight = 0`이면, 등장 가능한 NPC가 1명 이상 있다는 가정 하에 **무조건 NPC가 표시**됩니다.

---

## 8. 작업 흐름

### 새로운 NPC 추가하기

1. `data/npc_schedules/` 폴더에 `{npc_id}.json` 파일을 새로 만듭니다.
2. `place_id`, `weight`, `conditions`를 작성합니다.
3. **끝입니다.** 어떤 장소 스크립트도 수정할 필요가 없습니다.

### 새로운 장소 추가하기

1. `data/places/` 폴더에 `{place_id}.json` 파일을 새로 만듭니다.
2. `background_path`와 `empty_weight`를 지정합니다.
3. 이동 가능한 인접 장소가 있다면 `connections` 배열에 추가합니다. **양방향 이동을 원하면 반대쪽 장소 JSON에도 ID를 추가해야 합니다.**
4. 그 장소 전용 행동이 필요하면 `data/interactions/place/{place_id}/`에 JSON 파일을 추가합니다.
5. 기존 NPC 스케줄에 이 장소의 `place_id`를 추가하면 NPC가 거기에도 등장합니다.

### 이동 경로 / 행동 변경하기

- 이동 경로 추가/제거: 해당 장소의 `connections` 배열을 수정합니다.
- 행동 추가/제거: `data/interactions/common/` 또는 `place/{place_id}/` 또는 `char/{npc_id}/`에 JSON 파일을 추가·삭제합니다.
- **스크립트나 씬 파일은 수정할 필요가 없습니다.** JSON 저장 후 게임 실행만 하면 됩니다.

### NPC가 특정 장소에서 더 자주 등장하게 하기

- 해당 NPC의 JSON 파일에서 그 장소의 `weight` 값을 올립니다.
- 다른 NPC의 `weight`를 내릴 필요는 없습니다. 총합 비율이 자동으로 재계산되니까요.

---

## 9. 파일 위치 요약

```
project/guild-master/
├── data/places/          ← 장소 설정 (이동 connections, 배경, BGM 등)
├── data/dialogues/       ← NPC 클릭 및 이벤트 대화 파일
├── data/interactions/    ← 컨텍스트 행동 및 이벤트 후보 목록
├── data/npc_schedules/   ← NPC 등장 규칙
├── data/crises/          ← 위기 이벤트 정의
├── data/conditions/      ← 상태 카드 정의
├── data/items/           ← 아이템 정의
├── data/loot_tables/     ← 전리품 테이블 정의
├── data/mandatory_events/ ← 강제 이벤트 정의 (상태 이상으로 발동)
├── scenes/places/        ← 장소 씬 (place_scene.tscn 1개로 모든 장소 처리)
├── scripts/systems/      ← 시스템 코드 (직접 수정 불필요)
├── scripts/state/        ← 날짜/시간, MetricStore, InventoryManager 등 (직접 수정 불필요)
├── scripts/engines/      ← 행동 실행 및 조건 평가 코드 (직접 수정 불필요)
└── scripts/game/         ← 게임 로직 코드 (직접 수정 불필요)
```

## 10. 세이브 데이터

게임 상태는 다음 autoload들의 조합으로 구성됩니다.

| 시스템 | 저장 대상 | 복원 방법 |
|--------|----------|----------|
| `MetricStore` | 모든 metric 값 | `set_metric` |
| `TimeSystem` | day, hour, minute | `set_time()` |
| `GameFlags` | day, score, flags | `reset_flags` 후 `set_flag` |
| `ConditionManager` | 상태 카드 목록 | `clear_all_conditions` 후 `add_condition` |
| `CrisisManager` | 활성 위기, 둠, 봉쇄 장소 | `reset_state` 후 직접 복원 |
| `InventoryManager` | 아이템 목록 | `clear_inventory` 후 `set_inventory_data` |
| `PlaceScene` | 현재 장소 | `current_place_id` 저장 후 `move` action |

세이브 파일은 `user://saves/save_{slot}.dat`에 JSON 형태로 저장됩니다.

---

## 11. 화면 UI 구조 (place_scene.tscn)

장소 씬은 다음 4영역으로 구성됩니다. 모두 데이터에 의해 자동 갱신됩니다.

| 영역 | 위치 | 내용 |
|------|------|------|
| 배경 | 화면 전체 | `background_path`의 이미지 |
| 장소 이름 | 좌상단 | `display_name` |
| 날짜/시간 | 좌상단 장소 이름 아래 | 현재 `Day`와 시간대 |
| NPC 오버레이 | 우측 중앙 | 추첨된 NPC 초상화 + 이름 (없을 시 숨김) |
| 행동 패널 | 우측 (세로) | `interactions` JSON 스캔 → 버튼 (라벨 가나다순) |
| 이동 패널 | 하단 (가로) | `connections` 배열 → 버튼 (좌→우) |

### MVP 시작점

- `place_scene.tscn`의 기본 `place_id`는 **`inn_room` (여관방)** 으로 설정되어 있습니다.
- 단독 실행(F6) 시 여관방에서 시작하며, 하단 "복도" 버튼으로 이동할 수 있습니다.

### 게임 진입 흐름 (F5, 전체 실행)

```
splash_screen.tscn  →  title_screen.tscn  →  game_scene.tscn  (여관방)
   (로고 인트로)        ("새 게임" 버튼)        (PlaceScene 인스턴스 컨테이너)
```

- `game_scene.tscn`은 `place_scene.tscn` 인스턴스를 하나 품고 있는 컨테이너입니다.
- 시작 장소를 바꾸려면 `game_scene.tscn`을 에디터에서 열고 PlaceScene 노드의 `place_id` 인스펙터 값을 수정하세요.
- 시간대(`default_time_of_day`)도 동일한 방식으로 변경 가능합니다.

---

## 관련 문서

- 콘텐츠 폴더: [[02_콘텐츠/README]]
- Ink 대화 시스템: [[ink_guide]]
- 아키텍처 원칙: [[architecture]]
- 게임 루프: [[game_loop]]
- 컨텐츠 전달함: [[content-inbox/README]]
