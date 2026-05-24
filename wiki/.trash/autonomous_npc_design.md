# ⚠️ [ARCHIVED/LEGACY] 자율 NPC 시스템 설계서

> [!WARNING]
> **본 문서는 수치적 정신력(Sanity/Mental)이 존재하던 과거 기획 설계서로, 현재는 아카이빙된 레거시 시스템 사양입니다.**  
> **상태 카드 기반 자율 활동 및 위기 대응 시스템에 대한 최신 설계는 [[npa_simulation_system]] 문서를 참고해 주십시오.**


---

## 1. 시스템 개요

### 1.1 무엇을 하지 않는가 (Boundaries)

| 하지 않을 것 | 이유 |
|-------------|------|
| 파티 시스템 | 공동 전투, 버프 공유, AI 동행 등 복잡도 폭발 |
| 실시간 던전 진행 | NPC가 실제로 던전 씬에 들어가 전투하는 것 아님 |
| NPC 간 대화/관계 그래프 | 2인 대화, 갈등, 연애 등 관계 네트워크 복잡도 |
| 동적 스케줄 생성 | NPC가 자기 마음대로 새로운 행동 패턴을 만드는 것 아님 |

### 1.2 무엇을 하는가

플레이어는 "모험가" 중 한 명일 뿐. 마을에는 전사, 마법사, 신관 등 다른 모험가 NPC들이 존재한다.

```
[자정] NPC가 오늘의 행동 결정
    ↓
던전 갈 것인가? (HP/mental/날씨/위기 상태 기반 확률)
    ↓
YES → 던전 결과를 확률 + 스탯으로 계산
        ↓
        [귀환 시각] → TownNews 메시지 출력
        "전사 마슈가 던전에서 돌아왔다: 단서 토큰 1 습득, HP -20"

NO  → 평소 스케줄대로 마을 생활
        ↓
        [플레이어 조우] → 일반 대화/선물/단서 요청 가능
```

---

## 2. 데이터 스키마

### 2.1 NPC 정의 확장 — `data/npc_schedules/{npc_id}.json`

기존 스케줄 JSON에 `autonomous` 블록 하나만 추가. 기존 데이터는 전부 호환.

```json
{
  "npc_id": "marsh_warrior",
  "display_name": "전사 마슈",
  "portrait_path": "res://assets/portraits/marsh.png",
  "schedule": {
    "morning": { "place_id": "tavern", "weight": 80 },
    "afternoon": { "place_id": "street_north", "weight": 60 },
    "evening": { "place_id": "tavern", "weight": 90 },
    "night": { "place_id": "inn_room", "weight": 70 }
  },
  "autonomous": {
    "archetype": "warrior",
    "stats": {
      "hp": 80,
      "max_hp": 80,
      "mental": 30,
      "max_mental": 30,
      "combat_power": 5
    },
    "dungeon_behavior": {
      "go_probability": 0.3,
      "go_conditions": {
        "all_of": [
          { "metric_gt": ["npc.marsh_warrior.hp", 30] },
          { "metric_gt": ["npc.marsh_warrior.mental", 10] }
        ]
      },
      "preferred_dungeon": "dungeon_sewer",
      "return_time_blocks": ["afternoon", "evening"]
    },
    "outcome_table": {
      "success_rate": 0.6,
      "critical_rate": 0.15,
      "rewards": [
        { "type": "clue_token", "amount": 1, "probability": 0.5 },
        { "type": "item", "item_id": "rusty_sword", "probability": 0.2 },
        { "type": "item", "item_id": "healing_herb", "probability": 0.3 }
      ],
      "penalties": {
        "hp_damage_range": [10, 30],
        "mental_damage_range": [0, 10]
      }
    },
    "player_interaction": {
      "can_request_clue": true,
      "request_cost_metric": "npc.marsh_warrior.trust",
      "request_cost_amount": -2,
      "gift_preferences": ["ale", "healing_herb"]
    }
  }
}
```

#### 필드 설명

| 필드 | 설명 |
|------|------|
| `archetype` | 전사/마법사/신관/도적 등. 뉴스 메시지 템플릿에 쓰임 |
| `stats` | HP, mental, combat_power. 던전 판정 + 플레이어 대화 조건용 |
| `go_probability` | 자정마다 "던전 갈까?" 판정의 기본 확률 |
| `go_conditions` | 확률 적용 전 필수 조건 (HP/mental 임계값) |
| `preferred_dungeon` | 가장 자주 가는 던전 ID. 없으면 랜덤 |
| `return_time_blocks` | 귀환 시간대. 이 시간에 스케줄 무시하고 귀환 메시지 발생 |
| `outcome_table` | 던전 성공률, 보상, 패널티 정의 |
| `rewards` | 성공 시 획득 가능한 것들. `clue_token`은 위기 해결 자원 |
| `can_request_clue` | 플레이어가 이 NPC에게 단서 토큰을 요청 가능한지 |
| `request_cost` | 단서 요청 시 신뢰도 변화량 (보통 음수) |
| `gift_preferences` | 선물로 주면 호감도 보너스가 있는 아이템 |

---

## 3. 행동 흐름

### 3.1 자정 판정 (Daily Decision)

```
TimeSystem.advance_day() → signal "day_advanced"
    ↓
NPCAutonomyManager.on_day_advanced()
    ↓
각 NPC (autonomous 블록 보유한 것만):
  1. 현재 HP/mental 확인 → go_conditions 충족?
     NO  → 오늘은 스케줄대로 마을 생활
     YES → go_probability로 판정
           NO  → 마을 생활
           YES → 던전 출발
                ↓
                "{name}가 던전으로 떠났다" → TownNews (아침에 표시)
                귀환 시간 = return_time_blocks 중 랜덤 선택
                스케줄 해당 시간대를 "dungeon"으로 오버라이드
```

**HP/mental 회복 규칙 (마을에 있을 때):**
- 잠자는 시간대(night)에 HP +5, mental +5
- 여관/주점에서 쉬는 시간대에 mental +2
- 던전에서 돌아온 날은 회복량 반감

### 3.2 귀환 처리 (Return Processing)

```
NPC의 오버라이드 귀환 시간대 도달
    ↓
outcome_table로 결과 계산:
  1. 주사위 굴림 (0.0 ~ 1.0)
     - 0.00~0.15: critical → 보상 2배, HP 데미지 절반
     - 0.15~0.75: success → 보상 정상
     - 0.75~1.00: failure → 보상 없음, HP/mental 추가 데미지
  2. 보상 적용:
     - clue_token → npc.{id}.clue_tokens += amount
     - item → 마을 상점/인벤토리에 흘림 (또는 플레이어에게 직접 주지 않음)
  3. 패널티 적용:
     - HP 감소 (penalties.hp_damage_range 랜덤)
     - mental 감소 (penalties.mental_damage_range 랜덤)
     - HP <= 0 → "{name}가 던전에서 중상을 입고 마을로 끌려왔다"
       → 2일간 마을 강제 대기, HP 1로 회복
  4. TownNews 메시지 생성
```

### 3.3 TownNews 메시지 시스템

```gdscript
# 새 autoload: TownNews ( 또는 DialogueManager/Log 시스템 확장 )
func post(message: String, category: String = "general"):
    # 메시지를 큐에 쌓아두었다가 플레이어가 "다음 날" 시작 시 한 번에 보여줌
    # 또는 실시간으로 화면 우측 상단에 팝업
```

**메시지 카테고리:**

| 카테고리 | 색상/아이콘 | 예시 |
|----------|------------|------|
| `departure` | 회색 | "전사 마슈가 하수도 던전으로 떠났다" |
| `return_success` | 초록 | "전사 마슈가 던전에서 돌아왔다: 단서 토큰 1 습득" |
| `return_critical` | 금색 | "전사 마슈가 대성공! 단서 토큰 2, 고대 조각 1 습득" |
| `return_fail` | 빨강 | "전사 마슈가 던전에서 패배했다: HP -30, 부상 상태" |
| `return_injured` | 진빨강 | "마슈가 중상을 입고 끌려왔다. 2일간 회복 필요" |
| `crisis_help` | 파랑 | "신관 렐리아나가 의식을 완료했다: 위기 '마을의 악몽' 해결에 도움" |

**메시지 템플릿 (i18n key 기반):**

```json
// data/autonomy_messages.json
{
  "return_success": "{npc_name}가 던전에서 돌아왔다: {rewards}",
  "return_critical": "{npc_name}가 던전에서 엄청난 성과를 거두었다! {rewards}",
  "return_fail": "{npc_name}가 던전에서 패배했다. {penalties}",
  "return_injured": "{npc_name}가 중상을 입고 마을로 끌려왔다. {recovery_days}일간 회복이 필요하다.",
  "departure": "{npc_name}가 {dungeon_name}으로 떠났다."
}
```

---

## 4. 플레이어와의 상호작용

### 4.1 NPC 조우 시 추가 선택지

기존 `talk`/`touch`/`give` 외에 아래 선택지가 NPC 대화에 동적으로 추가된다.

```
[전사 마슈]와 대화 중...
- "요즘 어떻게 지내?" → 상태 확인 대화
- "단서 토큰 좀 줄 수 있어?" → 단서 요청 (trust -2, clue_token +1)
- "이거 받아." (선물) → 호감도 상승
```

**상태 확인 대화 (`ask_status` action):**

```json
{
  "type": "dialogue",
  "dialogue_id": "marsh_status_check",
  "condition": { "metric_gt": ["npc.marsh_warrior.trust", 3] }
}
```

```
마슈: "최근 하수도에서 쥐떼가 늘어났더라고. 내일 또 가볼 생각이야."
→ 플레이어에게 던전 정보/위험도 힌트 제공
```

### 4.2 단서 토큰 요청

```
요청 전 체크:
1. npc.{id}.clue_tokens > 0 ?
2. npc.{id}.trust >= 2 ?  (request_cost_metric 기준 최소값)

성공:
- 플레이어 clue_tokens +1
- NPC clue_tokens -1
- NPC trust += request_cost_amount (보통 -2)
- "마슈: "이거밖에 없어. 조심히 써.""

실패 (trust 부족):
- "마슈: "우리 그렇게 친한 사이 아니잖아?""

실패 (단서 없음):
- "마슈: "나도 지금 바닥났어. 미안.""
```

### 4.3 선물 시스템

```
gift_preferences에 있는 아이템:
- trust +3, affection +2 (보너스)

gift_preferences에 없는 아이템:
- trust +1, affection +0 (기본)

힐링 포션/약초 등 회복 아이템:
- NPC HP/mental 회복 + 선물 보너스
```

---

## 5. 위기 시스템과의 연결

### 5.1 단서 토큰 (Clue Token)

엘드리치 호러의 "Clue"를 변형. 위기 해결의 핵심 자원.

| 속성 | 설명 |
|------|------|
| 보관 위치 | `player.clue_tokens` (MetricStore) 또는 개별 NPC의 `npc.{id}.clue_tokens` |
| 용도 | 위기 해결 조건 `has_clue_tokens: N` |
| 획득 | 던전 성공 시 확률, NPC에게 요청, 특정 이벤트 |
| 소모 | 위기 해결 action `consume_clue_tokens` |

### 5.2 위기 해결에 NPC 기여

```
위기 "마을의 악몽" 해결 조건:
{ "all_of": [
  { "has_item": ["holy_symbol", 1] },
  { "has_clue_tokens": 3 }
]}

플레이어가 단서 토큰 2개, NPC들이 단서 토큰 1개 모아둔 상태면
→ 플레이어가 NPC로부터 1개를 요청받아 해결 가능
```

**NPC의 자동 기여 (고신뢰 NPC):**
- trust >= 8인 NPC는 단서 토큰을 가지고 있을 때, 위기 파멸 3일 전 자동으로 기부
- "신관 렐리아나가 단서 토큰 1개를 길드에 기부했다" → TownNews

### 5.3 위기 상태에 따른 NPC 행동 변화

```json
// npc_schedules/marsh_warrior.json 의 dungeon_behavior
"crisis_modifiers": {
  "nightmare_town": {
    "go_probability": 0.5,
    "return_fail_extra_mental": 10,
    "status_dialogue": "marsh_scared"
  }
}
```

위기 "마을의 악몽" 활성화 시:
- 마슈의 던전 출발 확률 0.3 → 0.5 (더 적극적으로)
- 귀환 실패 시 추가 mental 데미지 +10
- 상태 확인 대화가 `marsh_scared`로 교체

---

## 6. 아키텍처 통합

### 6.1 기존 시스템과의 관계

```
┌─────────────────────────────────────────────────────────┐
│  기존 시스템 (코드 변경 없음)                             │
│  ├─ ScheduleRegistry  ←  JSON 그대로 사용                 │
│  ├─ MetricStore     ←  npc.{id}.hp, trust 등 동적 생성   │
│  ├─ NPCSpawner      ←  spawn 로직 그대로 사용            │
│  ├─ ActionRunner    ←  dialogue, set_metric 등 동일     │
│  └─ ConditionEvaluator ←  metric 조건 그대로 사용        │
├─────────────────────────────────────────────────────────┤
│  새로 추가되는 것 (3가지)                                │
│  ├─ NPCAutonomyManager (autoload)                        │
│  │   └─ 자정 판정, 귀환 계산, HP/mental 회복            │
│  ├─ TownNews (autoload 또는 DialogueManager 확장)        │
│  │   └─ 메시지 큐잉, 표시, 카테고리별 스타일             │
│  └─ ActionRunner 확장 (2개 type)                        │
│      ├─ request_clue: NPC에게 단서 요청                  │
│      └─ ask_status: NPC 상태 확인 대화                   │
└─────────────────────────────────────────────────────────┘
```

### 6.2 NPCAutonomyManager (GDScript pseudo)

```gdscript
class_name NPCAutonomyManager
extends Node

# data/npc_schedules/*.json 중 "autonomous" 블록 보유한 NPC 목록
var autonomous_npcs: Array[Dictionary] = []

# 오늘 던전 간 NPC: { npc_id: { return_time_block, outcome } }
var active_runs: Dictionary = {}

func on_day_advanced(day: int):
    recover_hp_mental()
    process_returns()  # 어제 귀환 처리
    decide_departures(day)

func recover_hp_mental():
    for id in autonomous_npcs:
        var hp = MetricStore.get("npc." + id + ".hp", 0)
        var max_hp = MetricStore.get("npc." + id + ".max_hp", 0)
        var mental = MetricStore.get("npc." + id + ".mental", 0)
        var max_mental = MetricStore.get("npc." + id + ".max_mental", 0)
        var was_in_dungeon = active_runs.has(id)
        var recovery = 5 if not was_in_dungeon else 2
        MetricStore.set_metric("npc." + id + ".hp", min(hp + recovery, max_hp))
        MetricStore.set_metric("npc." + id + ".mental", min(mental + recovery, max_mental))

func decide_departures(day: int):
    for data in autonomous_npcs:
        var id = data.npc_id
        var auto = data.autonomous
        # go_conditions 체크
        if not ConditionEvaluator.evaluate(auto.dungeon_behavior.go_conditions):
            continue
        # 기본 확률 + 위기 변동
        var prob = auto.dungeon_behavior.go_probability
        prob = apply_crisis_modifiers(id, prob)
        if randf() < prob:
            var dungeon = auto.dungeon_behavior.preferred_dungeon
            var return_block = pick_return_block(auto.dungeon_behavior.return_time_blocks)
            active_runs[id] = { "dungeon": dungeon, "return": return_block }
            TownNews.post(tr("departure", { "name": data.display_name, "dungeon": dungeon }), "departure")

func process_returns():
    for id in active_runs.keys():
        var run = active_runs[id]
        var time_now = TimeSystem.get_current_time_block()
        if time_now == run.return:
            resolve_dungeon_run(id, run)
            active_runs.erase(id)

func resolve_dungeon_run(npc_id: String, run: Dictionary):
    var data = get_npc_data(npc_id)
    var outcome = data.autonomous.outcome_table
    var roll = randf()
    var rewards = []
    var penalties = {}
    var category = "return_success"
    if roll < outcome.critical_rate:
        category = "return_critical"
        rewards = calculate_rewards(outcome.rewards, 2.0)
        penalties = calculate_penalties(outcome.penalties, 0.5)
    elif roll < outcome.critical_rate + outcome.success_rate:
        category = "return_success"
        rewards = calculate_rewards(outcome.rewards, 1.0)
        penalties = calculate_penalties(outcome.penalties, 1.0)
    else:
        category = "return_fail"
        penalties = calculate_penalties(outcome.penalties, 2.0)
    # 적용
    apply_rewards_and_penalties(npc_id, rewards, penalties)
    # 뉴스
    TownNews.post(format_return_message(data.display_name, rewards, penalties), category)
```

### 6.3 ActionRunner 확장

| type | 인자 | 설명 |
|------|------|------|
| `request_clue` | `npc_id`, `min_trust` | NPC에게 단서 토큰 요청. trust 체크 후 교환 |
| `ask_status` | `npc_id` | NPC의 현재 상태(HP/mental/최근 활동)를 대화로 출력 |

### 6.4 ConditionEvaluator 확장

| condition | 예시 | 설명 |
|-----------|------|------|
| `npc_in_dungeon` | `{ "npc_in_dungeon": "marsh_warrior" }` | 해당 NPC가 현재 던전에 있는지 |
| `npc_trust_gte` | `{ "npc_trust_gte": ["marsh_warrior", 5] }` | 해당 NPC 신뢰도 >= N |

---

## 7. 샘플 NPC 3종

### 7.1 전사 마슈 (Marsh) — 공격형

```json
{
  "npc_id": "marsh_warrior",
  "display_name": "전사 마슈",
  "autonomous": {
    "archetype": "warrior",
    "stats": { "hp": 80, "max_hp": 80, "mental": 30, "max_mental": 30, "combat_power": 5 },
    "dungeon_behavior": {
      "go_probability": 0.3,
      "go_conditions": { "metric_gt": ["npc.marsh_warrior.hp", 30] },
      "preferred_dungeon": "dungeon_sewer",
      "return_time_blocks": ["afternoon", "evening"]
    },
    "outcome_table": {
      "success_rate": 0.6, "critical_rate": 0.15,
      "rewards": [
        { "type": "clue_token", "amount": 1, "probability": 0.5 },
        { "type": "item", "item_id": "rusty_sword", "probability": 0.2 }
      ],
      "penalties": { "hp_damage_range": [10, 30], "mental_damage_range": [0, 10] }
    },
    "player_interaction": {
      "can_request_clue": true,
      "request_cost_metric": "npc.marsh_warrior.trust",
      "request_cost_amount": -2,
      "gift_preferences": ["ale", "healing_herb"]
    }
  }
}
```

**성격**: 던전을 자주 감. 단서 토큰 생산량 높음. HP 소모 큼.

### 7.2 신관 렐리아나 (Relliana) — 보조형

```json
{
  "npc_id": "relliana_cleric",
  "display_name": "신관 렐리아나",
  "autonomous": {
    "archetype": "cleric",
    "stats": { "hp": 50, "max_hp": 50, "mental": 50, "max_mental": 50, "combat_power": 3 },
    "dungeon_behavior": {
      "go_probability": 0.15,
      "go_conditions": { "metric_gt": ["npc.relliana_cleric.mental", 20] },
      "preferred_dungeon": "dungeon_chapel",
      "return_time_blocks": ["afternoon"]
    },
    "outcome_table": {
      "success_rate": 0.7, "critical_rate": 0.2,
      "rewards": [
        { "type": "clue_token", "amount": 1, "probability": 0.3 },
        { "type": "buff", "buff_id": "blessing", "probability": 0.4 }
      ],
      "penalties": { "hp_damage_range": [5, 15], "mental_damage_range": [5, 15] }
    },
    "player_interaction": {
      "can_request_clue": true,
      "request_cost_metric": "npc.relliana_cleric.trust",
      "request_cost_amount": -1,
      "gift_preferences": ["holy_water", "incense"]
    }
  }
}
```

**성격**: 던전 출발 확률 낮음. 대신 성공률 높고, "축복" 버프를 플레이어에게 줄 수 있음. 단서 요청 cost가 낮음 (친절함).

### 7.3 도적 케이 (Kay) — 기동형

```json
{
  "npc_id": "kay_rogue",
  "display_name": "도적 케이",
  "autonomous": {
    "archetype": "rogue",
    "stats": { "hp": 60, "max_hp": 60, "mental": 40, "max_mental": 40, "combat_power": 4 },
    "dungeon_behavior": {
      "go_probability": 0.5,
      "go_conditions": { "metric_gt": ["npc.kay_rogue.hp", 20] },
      "preferred_dungeon": "dungeon_ruins",
      "return_time_blocks": ["morning", "night"]
    },
    "outcome_table": {
      "success_rate": 0.5, "critical_rate": 0.25,
      "rewards": [
        { "type": "clue_token", "amount": 1, "probability": 0.6 },
        { "type": "item", "item_id": "rare_gem", "probability": 0.15 }
      ],
      "penalties": { "hp_damage_range": [5, 20], "mental_damage_range": [0, 5] }
    },
    "player_interaction": {
      "can_request_clue": false,
      "request_cost_metric": "npc.kay_rogue.trust",
      "request_cost_amount": -5,
      "gift_preferences": ["rare_gem", "dagger"]
    }
  }
}
```

**성격**: 던전 출발 확률 가장 높음. 단서 토큰 생산량 최고. 단, 단서 요청이 불가능 (은밀행동, 믿음 부족). trust 높아야 대화 가능.

---

## 8. 구현 체크리스트

구현 착수 전/후에 체크:

- [ ] `data/npc_schedules/`에 `autonomous` 블록 추가된 샘플 1개
- [ ] `data/autonomy_messages.json` 메시지 템플릿 파일 생성
- [ ] NPCAutonomyManager autoload 등록 (project.godot)
- [ ] TownNews autoload 등록 또는 DialogueManager에 통합
- [ ] ActionRunner에 `request_clue`, `ask_status` 추가
- [ ] ConditionEvaluator에 `npc_in_dungeon`, `npc_trust_gte` 추가
- [ ] TimeSystem에 `day_advanced` 시그널 → NPCAutonomyManager 연결
- [ ] MetricStore 기본값 설정: 각 자율 NPC의 HP/mental/clue_tokens 초기화
- [ ] TownNews UI: 우측 상단 팝업 또는 아침에 한 번에 표시
- [ ] 테스트: 자정마다 NPC가 확률적으로 던전에 가는지
- [ ] 테스트: 던전 결과가 TownNews에 표시되는지
- [ ] 테스트: 플레이어가 NPC에게 단서 요청이 가능한지

---

**문서 버전**: 1.0
**최종 업데이트**: 2026-05-16
**다음 단계**: 구현 착수 (사용자 승인 시)
