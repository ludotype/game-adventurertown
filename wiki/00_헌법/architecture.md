# GuildMaster — 아키텍처 설계 기준

> 본 문서는 GuildMaster 프로젝트의 **장기 설계 기준**이다.
> 모든 시스템 추가·수정 결정은 이 문서의 원칙(§0)을 최우선으로 따른다.
>
> 작성 시점: Phase 0-3 (장소·이동·행동·NPC 추첨 + 인터랙션 + 시간 + 메트릭 완료)

---

## 0. 설계 원칙 (Design Pillars)

이 7개가 모든 결정의 기준이다. 충돌 시 항상 이 순서대로 가중치를 둔다.

| # | 원칙 | 핵심 명제 |
|---|---|---|
| **P1** | **Auto-Discovery** | 새 데이터는 폴더에 JSON을 떨궈두면 끝. 어떤 중앙 인덱스도 수정하지 않는다. |
| **P2** | **ID-First Referencing** | 모든 엔티티는 고유 ID를 가진다. 파일 경로·노드 경로 직접 참조 금지. |
| **P3** | **Definition ≠ State** | JSON(정의)은 읽기 전용. 런타임 가변 상태는 별도 싱글톤에 격리한다. |
| **P4** | **Vocabulary, not Table** | 행동·조건·효과를 작은 어휘로 정의하고 JSON에서 조합한다. |
| **P5** | **EventBus 결합** | 시스템 간 직접 호출 금지. 신호(signal)로만 소통. |
| **P6** | **Composable Depth** | 단순 케이스도 복잡 케이스도 같은 스키마. `sequence`/`if`/`random`로 깊이는 데이터에서 생긴다. |
| **P7** | **Fail Fast 검증** | 부팅 시 ID 참조 무결성 검사. 잘못된 데이터는 콘솔에서 즉시 비명을 지른다. |

> **"중앙 컨트롤 타워 금지" = P1 + P2.** Registry는 폴더를 스캔할 뿐, 그 안에 무엇이 있는지 미리 알지 못한다.

---

## 1. 시스템 지도

```
┌────────────────────── AUTOLOAD LAYER (싱글톤) ──────────────────────┐
│                                                                     │
│  ┌─ Registries (cold data) ──┐  ┌─ Runtime State (warm) ─────────┐  │
│  │ PlaceRegistry              │  │ TimeSystem                    │  │
│  │ NPCRegistry                │  │ GameFlags                     │  │
│  │ ItemRegistry               │  │ Inventory                     │  │
│  │ DialogueRegistry           │  │ MetricStore                   │  │
│  │ EventRegistry              │  │ QuestLog                      │  │
│  └────────────────────────────┘  └───────────────────────────────┘  │
│                                                                     │
│  ┌─ Runtime Engines (logic) ─────────────────────────────────────┐  │
│  │ ActionRunner   ConditionEvaluator   EventBus                   │  │
│  │ AtmosphereDescriber (정경 텍스트 조합)                            │  │
│  │ DialogueManager (애드온)            BGMManager   AudioManager │  │
│  │ SaveManager                                                   │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                ▲
                                │ uses (read only)
                                │
┌─────────────────────── SCENE LAYER ────────────────────────────────┐
│  PlaceScene (단일 씬, 모든 장소를 데이터로 처리)                   │
│   ├─ MoveBar       (connections → 버튼)                            │
│   ├─ ActionBar     (actions → 버튼, when 조건으로 활성/비활성)       │
│   ├─ NPCOverlay    (NPCSpawner 추첨 결과 + 클릭 입력)              │
│   ├─ MessageLog    (정경 텍스트 패널: 장소/시간/상태/NPC 묘사)       │
│   └─ PlaceLabel                                                   │
└────────────────────────────────────────────────────────────────────┘
                                ▲
                                │ reads via Registry
                                │
┌─────────────────────── DATA LAYER (JSON) ──────────────────────────┐
│  data/places/      data/npcs/        data/items/                   │
│  data/dialogues/   data/events/      data/actions/ (재사용 매크로) │
└────────────────────────────────────────────────────────────────────┘
```

**의존 규칙:**

- DATA → 어떤 코드도 모른다.
- SCENE → Registry만 읽는다. 다른 Scene을 모른다.
- Engine → Registry/State에 의존한다. Scene을 직접 부르지 않는다 (EventBus 경유).
- Registry → Data만 본다.

---

## 2. 데이터 스키마 (정의)

### 2.1 Place — `data/places/{place_id}.json`

```json
{
  "place_id": "flower_shop",
  "display_name": "꽃집",
  "description": "The scent of roses and lavender fills the small shop.",
  "descriptions": {
    "morning": "Morning light streams through the windows, illuminating rows of fresh-cut flowers.",
    "night": "The shop is dark, only a single lantern flickering over the counter."
  },
  "sub_npcs": [
    { "npc_id": "cat", "display_name": "a stray cat", "description": "sleeps among the flower pots." }
  ],
  "background_path": "res://assets/bg/flower_shop.png",
  "bgm": "town_day",
  "empty_weight": 6,
  "tags": ["indoor", "shop"],
  "connections": ["street_north"],
  "on_enter": [
    { "type": "set_flag", "key": "visited_flower_shop", "value": true }
  ]
}
```

### 2.2 NPC — `data/npc_schedules/{npc_id}.json`

> 현재 `data/npc_schedules/` 구조를 사용 중. 추후 `data/npcs/`로 통합 예정 (Phase 3 마이그레이션).

```json
{
  "npc_id": "luise",
  "display_name": "루이제",
  "default_portrait": "res://assets/portraits/luise.png",
  "default_dialogue": "luise_default",
  "tags": ["inn_owner", "human"],
  "schedules": [
    { "place_id": "lobby", "weight": 10,
      "conditions": { "time_of_day": ["morning", "afternoon"] } },
    { "place_id": "tavern", "weight": 4,
      "conditions": { "time_of_day": ["evening", "night"] } }
  ]
}
```

### 2.3 Item — `data/items/{item_id}.json`

> 소지품, 선물, 퀘스트 아이템 등에 사용. 던전 보상이나 NPC 교류에 활용.

```json
{
  "item_id": "flower_bouquet",
  "display_name": "꽃다발",
  "icon_path": "res://assets/items/flower_bouquet.png",
  "stackable": false,
  "tags": ["gift", "flower"]
}
```

### 2.4 Dialogue — `data/dialogues/{dialogue_id}.dialogue`

- Godot DialogueManager의 `.dialogue` 파일을 그대로 사용한다.
- `DialogueRegistry`가 `res://data/dialogues/`를 자동 스캔하고, 파일명을 `dialogue_id`로 등록한다.
- 대화 내부에서도 `do ActionRunner.run({...})` 형태로 액션 호출이 가능하다 → **대화에서 게임 상태 변경 가능.**

### 2.5 Event — `data/events/{event_id}.json` (트리거 기반 자동 발화)

```json
{
  "event_id": "luise_first_evening_tavern",
  "trigger": {
    "on": "place_entered",
    "place_id": "tavern",
    "when": { "flag_eq": ["met_luise_evening", false] }
  },
  "actions": [
    { "type": "set_flag", "key": "met_luise_evening", "value": true },
    { "type": "dialogue", "dialogue_id": "luise_first_evening" }
  ],
  "consume": true
}
```

---

## 3. Action Vocabulary (행동 어휘)

ActionRunner가 인식하는 **공식 어휘 카탈로그**다. 이게 어휘의 전부이며, 이 외는 코드 추가로만 확장한다.

| type | 인자 | 설명 |
|---|---|---|
| `log` | `message` | 디버그 출력 |
| `move` | `target_place` | 장소 이동 |
| `dialogue` | `dialogue_id` | 대화 시작 (DialogueManager) |
| `set_flag` | `key`, `value` | 플래그 설정 |
| `set_metric` | `key`, `value` | key 기반 숫자 값 설정 |
| `change_metric` | `key`, `amount` | key 기반 숫자 값 증감 |
| `toggle_flag` | `key` | 플래그 반전 |
| `advance_time` **(Legacy)** | `time_units=1` | [폐기 예정] 레거시 시간 진행 (AP 소모 시스템으로 대체) |
| `advance_minutes` **(Legacy)** | `minutes` | [폐기 예정] 레거시 분 진행 (AP 소모 시스템으로 대체) |
| `spend_ap` **(New)** | `amount` | 지정한 양만큼 행동력(AP) 소모 |
| `give_item` | `item_id`, `qty=1` | 인벤토리 추가 |
| `take_item` | `item_id`, `qty=1` | 인벤토리 제거 |
| `change_relation` | `npc_id`, `delta` | 추후 편의 별칭. 내부적으로 `npc.{npc_id}.affection` metric 사용 |
| `play_bgm` | `bgm_id` | BGM 변경 |
| `play_sfx` | `sfx_id` | 효과음 |
| **`sequence`** | `actions[]` | 순차 실행 (합성) |
| **`if`** | `when`, `then`, `else` | 조건 분기 (합성) |
| **`choice`** | `prompt`, `branches[]` | UI 선택지 (합성) |
| **`random`** | `branches[]` (가중치) | 가중치 랜덤 (합성) |
| **`call`** | `action_id` | `data/actions/{id}.json` 매크로 호출 |

**핵심 포인트:** `sequence`/`if`/`choice`/`random`/`call` 5개의 합성 어휘만으로 거의 모든 게임 이벤트를 표현할 수 있다. 깊이는 어휘 수가 아니라 **조합 가능성**에서 나온다.

---

## 4. Condition Vocabulary (조건 어휘)

ConditionEvaluator가 인식하는 어휘. JSON 어디서든 `when` 키로 등장 가능 (액션·이벤트 트리거·NPC 스케줄 등).

```json
{
  "all_of": [
    { "flag_eq": ["guild_member", true] },
    { "time_block": "morning" },
    { "hour_range": [9, 18] },
    { "has_item": ["lockpick", 1] },
    { "metric_gte": ["npc.elena.affection", 10] },
    { "not": { "at_place": "tavern" } }
  ]
}
```

| condition | 인자 |
|---|---|
| `flag_eq` | key, value |
| `flag_in` | key, values[] |
| `metric_eq` / `metric_gte` / `metric_lte` / `metric_gt` / `metric_lt` | key, value |
| `time_block` **(Legacy)** | block 또는 block[] | [폐기 예정] 레거시 시간 블록 판정 |
| `time_in` **(Legacy)** | time block[] | [폐기 예정] 레거시 시간 블록 판정 (호환용) |
| `hour_range` **(Legacy)** | start_hour, end_hour | [폐기 예정] 레거시 정밀 시간 판정 |
| `time_range` **(Legacy)** | start_time, end_time | [폐기 예정] 레거시 시간 범위 판정 |
| `day_eq` / `day_gte` | day | 일자 판정 (AP 시스템 하에서도 Day는 유지) |
| `ap_gte` / `ap_lte` **(New)** | amount | 현재 남은 행동력(AP) 비교 판정 |
| `at_place` | place_id |
| `has_item` | item_id, qty |
| `relation_gte` | 추후 편의 별칭. 기본은 `metric_gte` 사용 |
| `all_of` / `any_of` / `not` | 합성 |

---

## 5. MetricStore 원칙

MetricStore는 게임 안의 자잘한 숫자 상태를 key 기반으로 저장하는 범용 런타임 상태 저장소다.

전용 시스템을 만들지 않고 다음 형식의 key를 사용한다.

| 범위 | 형식 | 예시 |
|---|---|---|
| NPC | `npc.{npc_id}.{metric}` | `npc.luise.affection`, `npc.luise.mood` |
| 장소 | `place.{place_id}.{metric}` | `place.tavern.clean_count` |
| 플레이어 | `player.{metric}` | `player.music`, `player.strength` |
| 전역 | `global.{metric}` | `global.guild_reputation` |

핵심 원칙:

- 새 metric 추가 시 코드 등록을 요구하지 않는다.
- 조건은 `metric_gte`, `metric_lt` 같은 범용 비교를 사용한다.
- 효과는 `set_metric`, `change_metric`을 사용한다.
- `relation_gte` 같은 전용 문법은 필요성이 반복적으로 증명된 뒤 편의 별칭으로만 추가한다.
- 오타 검증은 Phase 7의 데이터 검증 도구에서 다룬다.

이 방식은 P1 Auto Discovery, P3 Definition vs State, P4 Vocabulary 원칙을 지키기 위한 기반이다.

---

## 6. 폴더 구조 (목표)

```
project/guild-master/
├── data/
│   ├── places/            # Place JSON
│   ├── npcs/              # NPC JSON (Phase 3 통합 후)
│   ├── items/             # Item JSON
│   ├── dialogues/         # .dialogue (DialogueManager)
│   ├── interactions/      # common/place/char 컨텍스트 상호작용
│   ├── events/            # Event JSON
│   └── actions/           # 재사용 액션 매크로 JSON
├── scenes/
│   ├── places/place_scene.tscn
│   └── ui/                # 공통 UI 컴포넌트 (Inventory, Dialog, ...)
├── scripts/
│   ├── core/              # SaveManager, Utils, ...
│   ├── systems/           # *Registry (cold data)
│   ├── state/             # TimeSystem, MetricStore, Inventory (warm)
│   ├── engines/           # ActionRunner, ConditionEvaluator, EffectApplier, EventBus
│   ├── components/        # UI 컴포넌트
│   └── game/              # PlaceScene 등 씬 스크립트
└── wiki/
    ├── planner-guide.md   # 기획자용
    └── architecture.md    # 본 문서
```

> 기존 `scripts/core/`의 시스템 코드(save/audio/bgm)는 그대로 둔다. 새 분류(`state/`, `engines/`)는 **추가만** 한다.

---

## 7. 구현 단계 (Phase Plan)

각 Phase는 **독립적으로 테스트 가능한 deliverable**을 갖는다. Phase 단위로 중단·재개 가능하다.

### Phase 0 — 골격 (완료)

- PlaceRegistry, ScheduleRegistry, NPCSpawner
- PlaceScene (배경 + NPC 오버레이 + 이동 바 + 행동 바)
- Splash → Title → GameScene(여관방) 진입 흐름
- 데이터: `data/places/inn_room.json`, `hallway.json`

### Phase 1 — Action 시스템 토대 (진행 중)

**목표:** 행동 선택지가 실제 효과를 갖는다.

- `ActionRunner` autoload — type별 디스패치, depth limit
- `ConditionEvaluator` autoload — `when` 평가
- 1차 어휘: `log`, `move`, `dialogue`, `set_flag`, `sequence`, `if`
- 1차 조건: `flag_eq`, `at_place`, `all_of`/`any_of`/`not`
- `place_scene.gd` 리팩토링: `_on_action_pressed` → `ActionRunner.run(action)`
- ActionBar가 `when`을 평가해 비활성/숨김 처리

**현재 완료:** `log`, `move`, `dialogue`, `set_flag`, `sequence`, `if` 및 `flag_eq`, `at_place`, `all_of`, `any_of`, `not` 구현.

**검수 기준:** NPC 상호작용 시퀀스(여러 액션 합성 + 플래그 분기)가 JSON만으로 동작한다.

### Phase 2 — TimeSystem (아카이브됨 / Legacy)

> [!WARNING]
> **시간 시스템(TimeSystem) 아카이브 알림 (2026-05-22)**
> 기존의 24시간제 세밀한 시간 흐름 시스템은 보드게임식 **행동력(AP) 및 주/야간 턴 루프(Action & Night Phase)** 방향성 전환에 따라 **폐기 및 아카이브(Deprecated)**되었습니다.
> - 시간 진행 액션(`advance_time`, `advance_minutes`)과 시간 조건들은 레거시 호환용으로만 임시 유지되며, 순차적으로 AP 소모(`spend_ap`) 및 페이즈 조건으로 마이그레이션됩니다.
> - 하루 단위의 시간(Day)은 유지하되, 하루의 끝(Night Phase 진입)은 AP 소모 완료 및 휴식 행동에 의해 제어됩니다.

**목표:** 시간이 흐른다. NPC 스케줄이 진짜로 시간을 따른다. (레거시 사양)

- `TimeSystem` autoload — `day`, `hour`, `minute`, `minutes_per_time_unit`, signal `time_advanced` (레거시)
- 액션 추가: `advance_time`, `advance_minutes`, `sleep_until_next_day` (레거시)
- 조건 추가: `time_block`, `time_in`, `hour_range`, `time_range`, `day_eq`, `day_gte` (레거시)
- `NPCSpawner`가 하드코딩된 `"morning"` 대신 `TimeSystem.current_time_of_day` 참조 (레거시)

**현재 완료 (아카이브):** 24시간제 `TimeSystem` autoload 추가, `time_units` 기반 `advance_time`, `advance_minutes`, `sleep_until_next_day`, 시간 블록/정밀 시간 조건 구현, 장소 UI에 `Day N HH:MM` 표시. (레거시 구현 완료 상태에서 동결)

**검수 기준:** "잠자고 하루 넘기기" 행동이 시간을 진행시키고, NPC 스케줄이 실제로 시간 따라 바뀐다. (레거시 검수 완료)

### Phase 3 — Interaction System + NPC 상호작용 (진행 중)

**목표:** 현재 장소, 시간, 대상 NPC, 상태 조건에 따라 가능한 interaction 버튼을 표시하고, 가장 적합한 이벤트를 자동 선택한다.

- `data/interactions/common/{interaction_id}.json` — 어디서나 쓰는 기본 동사
- `data/interactions/place/{place_id}/{interaction_id}.json` — 장소 전용·장소 맞춤 동사 (같은 id면 common 덮어씀)
- `data/interactions/char/{npc_id}/{interaction_id}.json` — 특정 NPC 대상 행동
- 하나의 interaction JSON은 여러 이벤트 후보(`events[]`)를 포함한다.
- `InteractionRegistry`가 모든 interaction 폴더를 자동 스캔한다.
- `InteractionRegistry`가 `available_when`, `events[].when`, `priority`, `weight`로 실행 이벤트를 선택한다.
- 선택된 이벤트의 `actions`는 `ActionRunner`가 실행한다.
- `data/npc_schedules/` → `data/npcs/`로 통합 (한 NPC = 한 JSON, 스케줄 포함)
- `NPCRegistry` (기존 ScheduleRegistry 흡수)
- NPC 정의에 `default_dialogue`, `tags` 추가
- `NPCOverlay`에 클릭 입력 → `ActionRunner.run({"type":"dialogue", "dialogue_id": npc.default_dialogue})`
- `MetricStore` 기반으로 affection, mood, clean_count 같은 자잘한 상태를 관리한다.
- 액션 `set_metric`, `change_metric`, 조건 `metric_gte` 등으로 interaction 분기를 만든다.

**현재 완료:** 기존 `data/npc_schedules/` 구조를 유지한 채 `default_dialogue`, `dialogue_id` 전달, NPC 초상화 클릭 대화 실행, `data/dialogues/` 샘플 대화 추가, `InteractionRegistry` 및 `data/interactions/common`, `place/{place_id}`, `char/elena` 샘플 추가, `places/*.json`의 과도기 `actions` 제거, `MetricStore`와 metric 조건/액션 추가.

**검수 기준:** 루이제 interaction에서 `npc.luise.affection`, `npc.luise.mood` 값을 JSON 액션으로 변경하고, metric 조건에 따라 다른 이벤트가 선택된다.

### Phase 4 — Inventory & Items

**목표:** 아이템 흐름.

- `ItemRegistry`
- `Inventory` autoload (warm state)
- 액션: `give_item`, `take_item`
- 조건: `has_item`
- 인벤토리 UI 컴포넌트

### Phase 5 — Event 시스템 (자동 트리거)

**목표:** 조건이 맞으면 이벤트가 알아서 발화한다.

- `EventRegistry`
- `EventBus` signals: `place_entered`, `time_advanced`, `flag_changed`, `item_changed`, `relation_changed`
- 각 신호 발생 시 EventRegistry가 해당 trigger를 가진 이벤트들을 평가한다.
- `consume: true`면 일회성이다.

**검수 기준:** 첫 만남 이벤트가 `place_entered: tavern` + `met_luise=false` 조건으로 자동 발화하고, 두 번 발화하지 않는다.

### Phase 6 — SaveManager 통합

**목표:** 게임이 저장된다.

- 정의(JSON)는 절대 저장하지 않는다.
- 직렬화 대상: `current_place_id`, `TimeSystem`, `GameFlags`, `Inventory`, `NPCRelations`, `consumed_events`
- 타이틀의 "계속하기" 흐름과 연결한다.

### Phase 7 — 검증 / 디버그 도구

**목표:** 비프로그래머도 자기 실수를 본다.

- 부팅 시 무결성 검사
  - 존재하지 않는 `place_id`/`npc_id`/`item_id`/`dialogue_id` 참조 → 콘솔 경고
  - 양방향 connections 누락 감지 → 경고 (강제는 아님)
  - 고립된 장소 감지 (어디서도 도달 불가)
- 디버그 오버레이 (F1 토글): 현재 place, time, flags, inventory, relations
- 액션 빠른 실행 콘솔 (디버그용)

### Phase 8 (선택) — 편집 보조

- 마을 그래프 시각화 (장소 노드 / 이동 엣지)
- 위키 자동 생성: 장소·NPC·아이템 목록 마크다운 자동 출력

---

## 8. 비프로그래머 워크플로우 (검증 시나리오)

### 시나리오 A — "꽃집 + 꽃집 주인 마르코 + 시간대별 상호작용"

```
1. data/places/flower_shop.json 작성
   - connections: ["street_north"]

2. data/npc_schedules/marco.json 작성
   - schedules: [{ "place_id":"flower_shop", "weight":10,
                   "conditions": {"time_of_day":["morning","afternoon"]} }]
   - default_dialogue: "marco_default"

3. data/dialogues/marco_default.dialogue 작성
   - 시간대별 분기 (DialogueManager 표준 문법)
   - 안에서 do ActionRunner.run({"type":"sequence","actions":[
       {"type":"give_item","item_id":"flower_bouquet","qty":1},
       {"type":"change_metric","key":"npc.marco.affection","amount":1}
     ]})

4. data/items/flower_bouquet.json 작성 (없으면)
```

**중앙 테이블 수정 0건. 코드 수정 0건. 게임 재시작 1회.**

### 시나리오 B — "비 오는 날 광장에서 첫 만남" 같은 분기 이벤트

```json
// data/events/luise_first_meet.json
{
  "event_id": "luise_first_meet",
  "trigger": {
    "on": "place_entered",
    "place_id": "town_square",
    "when": {
      "all_of": [
        { "flag_eq": ["met_luise", false] },
        { "time_in": ["morning"] }
      ]
    }
  },
  "actions": [
    { "type": "set_flag", "key": "met_luise", "value": true },
    { "type": "dialogue", "dialogue_id": "luise_meet_cute" }
  ],
  "consume": true
}
```

---

## 9. 트레이드오프 / 리스크

| # | 리스크 | 대응 |
|---|---|---|
| R1 | JSON 손작성 부담 | Phase 8에서 간단한 에디터 검토. 단기엔 풍부한 예시 + 검증 메시지로 완화한다. |
| R2 | DialogueManager ↔ ActionRunner 책임 혼동 | **원칙**: 텍스트/분기 = Dialogue, 게임 상태 변경 = Action. Dialogue 내부에서 Action 호출은 허용한다. |
| R3 | 무한 시퀀스/순환 호출 | ActionRunner에 depth limit (예: 32) + 액션 ID 호출 스택 추적. |
| R4 | 합성 어휘 학습 곡선 | `planner-guide.md`에 시나리오 카탈로그 비치 (위 §7 같은 식). |
| R5 | 너무 자유로워서 디자인 일관성 흐트러짐 | tags 시스템으로 "이 장소/NPC는 어느 카테고리"를 명시. 추후 분석 도구의 기반이다. |
| R6 | 비프로그래머가 자기 실수를 못 봄 | Phase 7 검증 도구 필수. 늦추지 말 것. |
| R7 | 시나리오 작업량 (NPC 대사) | 단일 히로인 집중으로 범위 제한. 단계별 이벤트를 점진적 추가. |

---

## 10. 깊이 보장 (Composable Depth)

"기획자 친화 = 깊이 희생"이라는 오해를 막기 위한 구조적 장치는 다음과 같다.

1. **합성 어휘 (sequence/if/choice/random/call)** — 단순 어휘만으로 관계 진행 이벤트와 던전 이벤트 모두 표현 가능.
2. **Dialogue 내 Action 호출 허용** — 대화 트리에서 시간 진행, 호감도 변화, 아이템 지급, 분기 모두 가능.
3. **EventBus + 트리거 이벤트** — 절차적 이벤트가 아니라 **세계가 반응하는** 형태 (예: 특정 플래그 + 특정 시간이면 이벤트 자동 발화).
4. **tags 시스템** — 단순 ID 매칭을 넘어 "indoor 장소에서만", "tavern 태그 NPC만" 같은 패턴 매칭 가능 (Phase 후반 확장).
5. **NPC schedule + condition** — NPC가 시간/플래그/날짜에 따라 다른 곳에 있고, 다른 대사를 한다.

Princess Maker · Stardew Valley · Persona의 커뮤니티 링크 · Harvest Moon — 이 정도 깊이까지 본 구조로 도달 가능하다. 한계는 어휘를 얼마나 늘리느냐에 달려 있다.

---

## 11. 변경 이력

| 날짜 | 변경 | 비고 |
|---|---|---|
| 2026-05-15 | 초안 작성 | Phase 0 완료 시점 |
| 2026-05-16 | Phase 1 착수 | ActionRunner, ConditionEvaluator 추가 |
| 2026-05-16 | Phase 2 착수 | 24시간제 TimeSystem, time_units 기반 시간 액션, 시간 조건 추가 |
| 2026-05-16 | Phase 3 착수 | InteractionRegistry, common/char interaction, NPC 클릭 대화, data/dialogues 샘플 추가 |
| 2026-05-16 | MetricStore 추가 | key 기반 범용 상태 저장소, metric 조건/액션, 문서화 추가 |
| 2026-05-16 | 컨셉 정리 | 길드 관리/자동전투 컨셉 제거, 1인칭 연애 어드벤처 방향으로 예시/용어 전면 정리 |
| 2026-05-16 | 정경 텍스트 시스템 | `AtmosphereDescriber` 추가. 장소 JSON에 `descriptions`(시간대별), `sub_npcs` 필드 추가. 메시지 창을 로그→단일 정경 텍스트 패널로 개조. |
| 2026-05-22 | 시간 시스템 아카이브 | 24시간제 시간 시스템(Time Unit)을 보드게임식 행동력(AP) 시스템으로 전환하고 관련 명세를 레거시로 분류 및 아카이브 |

---

## 관련 문서

- 헌법 폴더: [[00_헌법/README]]
- game_concept: [[game_concept]]
- game_loop: [[game_loop]] **(Legacy/Archived)**
- 기획자 가이드: [[planner_guide]]
- Ink 대화 시스템: [[ink_guide]]
