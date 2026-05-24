# Emergent Storytelling 시스템

> 엘드리치 호러 / 아컴 호러의 장소 특수 행동 + 상태 이상 체인 + 강제 이벤트를 GuildMaster의 데이터 드리븐 아키텍처로 녹이는 설계 방식.
>
> **핵심 원칙**: "도박 → 부채 → 추적 → 기습 → 부상 → 입원" 같은 체인을 JSON + ConditionManager + MandatoryEvent로 표현. 코드 변경 없이 기획자가 직접 체인을 설계할 수 있어야 한다.

---

## 1. 시스템 구성 요소 3종

| EH 개념 | 게임 내 구현 | 데이터 위치 |
|---------|-------------|------------|
| **장소 특수 행동** (Rest/Gather Info/Gamble) | `data/interactions/place/{place_id}/{action_id}.json` | 기존 Interaction 시스템에 `outcome_check` action으로 통합 |
| **상태 이상 체인** (Debt → Hunted → Ambushed → Injured) | `data/conditions/*.json`의 `on_remove` + `reckoning` + `mandatory_events` | ConditionManager가 중간 매개체 |
| **강제 이벤트** (Mandatory/Compelled) | `data/mandatory_events/{event_id}.json` | trigger_on으로 발동, 플레이어 의사와 무관 |

---

## 2. 장소 특수 행동 (Place Special Action)

장소 특수 행동은 기존 **Interaction 시스템** (`data/interactions/place/{place_id}/`)에 구현되며, `outcome_check` action으로 4분기 판정을 처리합니다.

### 폴더 구조

```
data/interactions/place/
├── lobby/
│   ├── gamble.json
│   ├── gossip.json
│   └── drink.json
├── guard_station/
│   ├── guard_quest.json
│   ├── accompany_patrol.json
│   └── emergency_aid.json
├── cathedral_nave/
│   ├── pray.json
│   └── cleanse.json
├── curio_shop/
│   ├── browse_wares.json
│   └── appraise_relic.json
├── rogues_den/
│   ├── fight_in_pit.json
│   └── black_market.json
├── beggars_alley/
│   ├── alms_for_clues.json
│   └── scavenge.json
└── abandoned_distillery/
    ├── witchs_brew.json
    └── decipher_ritual.json
```

### 실제 구현 예시: `lobby/gamble.json`

```json
{
  "interaction_id": "gamble",
  "label": "도박을 한다",
  "available_when": { "metric_gte": ["player.gold", 10] },
  "events": [
    {
      "id": "gamble_lobby",
      "priority": 0,
      "actions": [
        { "type": "change_metric", "key": "player.gold", "amount": -10 },
        {
          "type": "outcome_check",
          "attribute": "luck",
          "difficulty": 2,
          "outcomes": {
            "critical_success": {
              "actions": [
                { "type": "change_metric", "key": "player.gold", "amount": 50 },
                { "type": "set_flag", "key": "gamble_big_win", "value": true }
              ],
              "message": "엄청난 대박! 상상도 못한 큰돈을 따냈다!"
            },
            "success": {
              "actions": [
                { "type": "change_metric", "key": "player.gold", "amount": 30 }
              ],
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
      ]
    }
  ]
}
```

**핵심 규칙:**
- `outcome_check` action으로 다이스 풀 판정 (`player.{attribute}`만큼 d6 굴림, 4+ 성공 개수 vs `difficulty`)
- `critical_success` / `success` / `failure` / `critical_failure` 4분기
- `available_when`으로 cost/선행조건 제어 (예: 골드 10 이상 필요)
- 결과는 ActionRunner action으로 표현 → 기획자가 직접 체인을 설계

---

## 3. 상태 이상 체인 (Condition Chain)

### 체인 예시: 도박의 대가

```
[도박 실패] → Debt(5일) → Hunted(3일) → Ambush/Night Intruder → Injured → Clinic Treatment
```

### 각 단계의 구현 방식

| 단계 | 구현 | 설명 |
|------|------|------|
| **Debt** | `data/conditions/debt.json` | duration=5. `on_remove`에서 `player.gold >= 50`이면 상환, 아니면 `hunted` 추가 |
| **Hunted** | `data/conditions/hunted.json` | duration=3. `rest_attempt` / `place_entered` trigger로 강제 이벤트 발동. `data/interactions/char/shepard/resolve_hunted.json`로 해결 가능 |
| **Ambush** | `data/mandatory_events/ambush.json` | trigger_on: `place_entered`. when: `has_condition: hunted`. insight 체크 실패 시 HP-15, `injured` 추가 |
| **Night Intruder** | `data/mandatory_events/night_intruder.json` | trigger_on: `rest_attempt`. when: `has_condition: hunted`. physique 체크 실패 시 HP-10, stamina -5 |
| **Injured** | `data/conditions/injured.json` | `add_condition` by Ambush event. `daily_midnight` reckoning으로 HP 추가 감소. `lobby/rest.json` 또는 `cathedral_nave/pray.json`로 회복 |

### debt.json 예시

```json
{
  "condition_id": "debt",
  "display_name": "빚",
  "description": "사채업자에게 돈을 졌다. 시간이 지날수록 상황은 악화될 것이다.",
  "tags": ["social"],
  "max_stack": 1,
  "duration": 5,
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

### JSON 스키마 예시

#### ambush.json (`place_entered` trigger)

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
      "attribute": "insight",
      "difficulty": 2,
      "pass_actions": [
        { "type": "log", "message": "적의 기습을 미리 눈치채고 피했다." }
      ],
      "fail_actions": [
        { "type": "change_metric", "key": "player.hp", "amount": -15 },
        { "type": "add_condition", "condition_id": "injured", "duration": 4 },
        { "type": "remove_condition", "condition_id": "hunted" }
      ]
    }
  ]
}
```

#### night_intruder.json (`rest_attempt` trigger)

```json
{
  "event_id": "night_intruder",
  "trigger_on": "rest_attempt",
  "when": { "has_condition": "hunted" },
  "priority": 90,
  "actions": [
    { "type": "log", "message": "어둠 속에서 누군가가 방문을 두드린다..." },
    {
      "type": "attribute_check",
      "attribute": "physique",
      "difficulty": 2,
      "pass_actions": [
        { "type": "log", "message": "침입자를 격퇴하고 밤을 지새웠다." }
      ],
      "fail_actions": [
        { "type": "change_metric", "key": "player.hp", "amount": -10 },
        { "type": "change_metric", "key": "player.stamina", "amount": -5 },
        { "type": "log", "message": "침입자에게 당했다. 밤새 잠을 이루지 못했다." }
      ]
    }
  ]
}
```

### 트리거 종류

| trigger_on | 발동 시점 | 예시 |
|-----------|----------|------|
| `day_started` | 하루 시작 시 (자정) | 위기 이벤트의 `per_day_effects`와 함께 처리 |
| `place_entered` | 특정 장소 입장 시 | `hunted` 상태로 으슥한 곳에 들어갈 때 기습 |
| `rest_attempt` | 휴식 시도 시 | `lobby/rest.json`의 첫 번째 action으로 `trigger_mandatory` 실행 |
| `condition_removed` | 상태 이상 제거 시 | 빚 갚았을 때 후속 |
| `crisis_triggered` | 위기 발생 시 | 전역 이벤트 |

---

## 5. 장소별 특수 행동 카탈로그 (구현 현황)

### 현재 마을 장소별 구현된 행동

| 장소 | 특수 행동 | 결과 체인 | 상태 |
|------|----------|----------|------|
| **여관 로비** | 도박 | `outcome_check`(luck, 2). 대성공: +50골드 / 성공: +30 / 실패: `debt` + 추가 -20 / 대실패: `debt` + `hunted` | ✅ 구현 |
| **여관 로비** | 소문 귀동냥 | `outcome_check`(insight, 1). 성공: `clue_token` +1 / 실패: stamina -1 | ✅ 구현 |
| **여관 로비** | 술 한 잔의 여유 | stamina +2, HP +3. 다음 날 '숙취'(stamina -2) | ✅ 구현 |
| **여관 로비** | 휴식 | HP 회복. `haunted` 상태 시 `rest_attempt` trigger 발동, 악몽 | ✅ 구현 |
| **골동품 상점** | 진열대 살펴보기 | `outcome_check`(influence, 1). 성공 시 희귀 아이템 구매 기회 또는 `holy_symbol` 등장 | ✅ 구현 |
| **골동품 상점** | 신비물 감정 | `outcome_check`(insight, 1). 성공: 고급 단서 + 30골드 / 실패: 10골드 | ✅ 구현 |
| **경비대** | 순찰대 동행 | HP +15, `npc.shepard.trust` +1, 행동력 3 AP 소모 | ✅ 구현 |
| **경비대** | 응급 구호 요청 | HP < 20% 시 무료 HP +10 | ✅ 구현 |
| **경비대** | 경비 기여 | `clue_token` 기부 → `global.doom` 하락 | ✅ 구현 |
| **성당 본당** | 기도 | `outcome_check`(willpower, 1) 또는 luck. 치유/고해성사/축복/무반응 분기 | ✅ 구현 |
| **성당 본당** | 정화 | `outcome_check`(willpower, 2). 파멸 토큰 제거 및 장소 위기 해제 | ✅ 구현 |
| **도적들의 소굴** | 지하 투기장 참전 | `outcome_check`(physique, 2). 대성공: +80골드 + `용기` / 성공: +40골드 / 실패: HP -30 + `부상` | ✅ 구현 |
| **도적들의 소굴** | 암시장 밀거래 | `outcome_check`(insight, 1) 또는 influence. 특수 아이템 구매 또는 할인 | ✅ 구현 |
| **부랑자 골목** | 자선과 정보 수집 | `outcome_check`(influence, 1). 성공: 평판 +1, `clue_token` +1 | ✅ 구현 |
| **부랑자 골목** | 골목 폐허 수색 | `outcome_check`(insight, 1). 성공: 정크 부품 획득 / 실패: HP -5 | ✅ 구현 |
| **폐양조장** | 마녀의 비약 조제 | `outcome_check`(insight, 1). 성공: stamina +10 + `강화된 신체` / 실패: stamina -5, HP -10 | ✅ 구현 |
| **폐양조장** | 금기된 주술 전수 | `outcome_check`(willpower, 2). 성공: `정화의 의식` 단서 / 실패: stamina -5 | ✅ 구현 |
| **대도서관** | 고서 조사 | `outcome_check`(insight, 1). 성공: 단서 또는 던전 해금 정보 | ✅ 구현 |
| **천문탑** | 천체 관측 | `outcome_check`(insight, 2) 또는 willpower. 위기 다음 단계 예측 힌트 | ✅ 구현 |

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
| **장소별 특수 행동 목록** | 각 장소의 interaction 정의 (`outcome_check` 포함) | `data/interactions/place/{place_id}/` |
| **상태 이상 정의** | condition JSON과 체인 로직 | `data/conditions/` |
| **강제 이벤트 정의** | mandatory_events JSON | `data/mandatory_events/` |
| **기획서/설명서** | 위 문서들의 설계 의도와 예시 | `wiki/emergent_storytelling.md` (본 문서) |

---

**문서 버전**: 2.0 (피벗 후 재작성)
**최종 업데이트**: 2026-05-24
