# Emergent Storytelling 시스템

> 엘드리치 호러 / 아컴 호러의 장소 특수 행동 + 상태 이상 체인 + 강제 이벤트를 GuildMaster의 데이터 드리븐 아키텍처로 녹이는 설계 방식.
>
> **핵심 원칙**: "도박 → 부채 → 추적 → 기습 → 부상 → 입원" 같은 체인을 JSON + ConditionManager + MandatoryEvent로 표현. 코드 변경 없이 기획자가 직접 체인을 설계할 수 있어야 한다.

---

## 1. 시스템 구성 요소 3종

| EH 개념 | 게임 내 구현 | 데이터 위치 |
|---------|-------------|------------|
| **장소 특수 행동** (Rest/Gather Info/Gamble) | `data/special_actions/{place_id}/{action_id}.json` | JSON 기반, ActionRunner로 결과 실행 |
| **상태 이상 체인** (Debt → Tracked → Ambushed → Injured) | `data/conditions/*.json`의 `on_remove` + `reckoning` + `mandatory_events` | ConditionManager가 중간 매개체 |
| **강제 이벤트** (Mandatory/Compelled) | `data/mandatory_events/{event_id}.json` | trigger_on으로 발동, 플레이어 의사와 무관 |

---

## 2. 장소 특수 행동 (Place Special Action)

### 폴더 구조

```
data/special_actions/
├── tavern/
│   └── gamble.json
├── guard_hq/
│   └── gather_intel.json
├── inn_room/
│   └── rest.json
└── hospital/
    └── receive_treatment.json
```

### JSON 스키마

```json
{
  "action_id": "gamble",
  "label": "도박을 한다",
  "place_id": "tavern",
  "cost": {
    "time_units": 2,
    "metric": { "key": "player.gold", "amount": -10 }
  },
  "when": { "time_block": "evening" },
  "outcomes": {
    "check": {
      "type": "attribute_check",
      "attribute": "luck",
      "difficulty": 2
    },
    "success": {
      "actions": [
        { "type": "change_metric", "key": "player.gold", "amount": 30 },
        { "type": "log", "message": "큰돈을 따냈다!" }
      ]
    },
    "failure": {
      "actions": [
        { "type": "change_metric", "key": "player.gold", "amount": -20 },
        { "type": "add_condition", "condition_id": "debt", "duration": 5 },
        { "type": "log", "message": "빚을 졌다. 사채업자가 당신을 기억할 것이다." }
      ]
    },
    "critical_failure": {
      "actions": [
        { "type": "add_condition", "condition_id": "debt", "duration": 5 },
        { "type": "add_condition", "condition_id": "hunted", "duration": 3 },
        { "type": "log", "message": "짝패들에게 들켰다. 뒷골목을 조심하자." }
      ]
    }
  }
}
```

**핵심 규칙:**
- `outcomes.check`로 1d6+attribute vs difficulty*3 판정
- `success` / `failure` / `critical_success` / `critical_failure` 4분기
- 결과는 ActionRunner action으로 표현 → 기획자가 직접 체인을 설계

---

## 3. 상태 이상 체인 (Condition Chain)

### 체인 예시: 도박의 대가

```
[도박 실패] → Debt(5일) → Tracked(3일) → Ambush 이벤트 → Injured → Hospitalized
```

### 각 단계의 구현 방식

| 단계 | 구현 | 설명 |
|------|------|------|
| **Debt** | `data/conditions/debt.json` | duration=5. `on_remove`에서 50% 확률로 `hunted` 추가 |
| **Tracked** | `data/conditions/hunted.json` | duration=3. `reckoning: daily_midnight`로 추적 강화. `on_remove`에서 강제 이벤트 트리거 |
| **Ambush** | `data/mandatory_events/ambush.json` | trigger_on: `day_started`. when: `has_condition: hunted` |
| **Injured** | `data/conditions/injured.json` | `add_condition` by Ambush event |
| **Hospitalized** | `data/mandatory_events/hospitalized.json` | trigger_on: `day_started`. when: `has_condition: injured` AND `metric_lte: player.hp, 10` |

### debt.json 예시

```json
{
  "condition_id": "debt",
  "display_name": "빚",
  "description": "사채업자에게 돈을 졌다. 시간이 지날수록 상황은 악화될 것이다.",
  "tags": ["social", "reckoning"],
  "max_stack": 1,
  "on_remove": {
    "actions": [
      {
        "type": "if",
        "when": { "metric_gte": ["player.gold", 50] },
        "then": [
          { "type": "change_metric", "key": "player.gold", "amount": -50 },
          { "type": "log", "message": "빚을 갚았다. 한숨 돌린다." }
        ],
        "else": [
          { "type": "add_condition", "condition_id": "hunted", "duration": 3 },
          { "type": "log", "message": "빚을 갚지 못했다. 누군가가 당신을 쫓기 시작했다." }
        ]
      }
    ]
  }
}
```

---

## 4. 강제 이벤트 (Mandatory Event)

### 폴더 구조

```
data/mandatory_events/
├── ambush.json
├── hospitalized.json
└── crisis_warning.json
```

### JSON 스키마

```json
{
  "event_id": "ambush",
  "trigger_on": "day_started",
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

### 트리거 종류

| trigger_on | 발동 시점 | 예시 |
|-----------|----------|------|
| `day_started` | 하루 시작 시 (자정) | 추적 이벤트, 입원 이벤트 |
| `place_entered` | 특정 장소 입장 시 | 위험 지역 진입 시 함정 |
| `rest_attempt` | 휴식/잠자기 시도 시 | 악몽 이벤트 (기존 위기 시스템과 동일) |
| `condition_removed` | 상태 이상 제거 시 | 빚 갚았을 때 후속 |
| `crisis_triggered` | 위기 발생 시 | 전역 이벤트 |

---

## 5. 장소별 특수 행동 카탈로그 (Backlog)

### 현재 마을 장소별 예정 행동

| 장소 | 특수 행동 | 결과 체인 |
|------|----------|----------|
| **선술집** | 도박 | 성공: 골드 획득 / 실패: `debt` → `hunted` → 기습 |
| **선술집** | 정보 수집 (술값 내고) | `clue_token` 획득 또는 소문 (metric 변화) |
| **경비대 본부** | 정보 수집 | `clue_token` 획득, 위기 관련 힌트 |
| **경비대 본부** | 순찰대 동행 | `player.hp` 회복, `npc.shepard.trust` 상승 |
| **여관방** | 휴식 | HP 회복. 단 `haunted` 상태 시 악몽 이벤트 |
| **꽃집** | 꽃 구매 | `npc.luise.affection` 상승용 선물 |
| **무기상** | 무기 수리/강화 | 공격력 상승, 골드 소모 |
| **고대 유적** | 깊숙이 탐험 | 전리품 또는 함정. `rusty_sword`, `holy_symbol`, `potion` |

---

## 6. 기획 체크리스트 (Emergent Chain 설계 시)

새로운 체인을 만들 때 다음 순서로 기획하세요.

1. **시작점 정하기**: 어떤 행동이나 이벤트가 체인을 발동하는가?
2. **상태 이상 설계**: 중간 단계를 `data/conditions/{id}.json`로 정의. `on_remove`와 `reckoning` 활용.
3. **강제 이벤트 설계**: `data/mandatory_events/{id}.json`로 상태 이상이 유발하는 강제적 결과 정의.
4. **종결점 정하기**: 체인은 어떻게 끝나는가? (회복, 사망, 위기 해결, 관계 변화)
5. **검증**: JSON 문법 오류 없는지, `ConditionEvaluator`가 평가 가능한지, `ActionRunner`가 실행 가능한지 확인.

---

## 7. 문서 위치 규칙

| 문서 | 내용 | 보관 위치 |
|------|------|----------|
| **장소별 특수 행동 목록** | 각 장소의 special_actions 정의 | `data/special_actions/{place_id}/` |
| **상태 이상 정의** | condition JSON과 체인 로직 | `data/conditions/` |
| **강제 이벤트 정의** | mandatory_events JSON | `data/mandatory_events/` |
| **기획서/설명서** | 위 문서들의 설계 의도와 예시 | `wiki/emergent_storytelling.md` (본 문서) |

---

**문서 버전**: 1.0
**최종 업데이트**: 2026-05-16
