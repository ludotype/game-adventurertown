# 위기 이벤트 시스템 (Crisis System) 설계서

> Eldritch Horror 보드게임의 Mythos / Reckoning / Condition 시스템을 GuildMaster에 녹인 설계.
> **단계**: 기획/설계 완료 후 구현 착수 예정. 현재는 시스템 골격과 데이터 스키마 정의 단계.
>
> **핵심 결정 사항**: 7일 사이클, 다중 위기 최대 3개 동시 활성, 전체 게임오버+지역 봉쇄 복합.

---

## 1. 시스템 개요

### 1.1 핵심 메커닉 3종

Eldritch Horror의 3가지 핵심 메커닉을 게임의 시간/일상 루프에 녹인다.

| EH 메커닉 | 게임 내 변형 | 설명 |
|-----------|-------------|------|
| **Mythos Phase** | **위기 페이즈 (Crisis Phase)** | 7일마다 랜덤으로 새 위기 발생 또는 기존 위기 악화 |
| **Reckoning** | **정산 (Reckoning)** | 지속 효과가 있는 카드/조건의 주기적 악화. 매일 자정 또는 특정 행동 시 트리거 |
| **Condition 카드** | **상태 카드 (Condition Card)** | 플레이어에게 부여되는 지속 상태. "저주", "부상", "정신 쇠약" 등. 보유 중일 때 정산 효과 발생 |

### 1.2 위기의 생명주기

```
[잠재] → [발생] → [활성] → [악화] → [해결] or [파멸]
   ↓         ↓         ↓          ↓
 7일 체크  랜덤 롤   지속 효과   효과 증폭
           선택      적용       + doom 타이머
```

---

## 2. 데이터 스키마

### 2.1 위기 정의 — `data/crises/{crisis_id}.json`

```json
{
  "crisis_id": "nightmare_town",
  "display_name": "마을에 악몽이 찾아오다",
  "description": "어둠이 마을을 덮치기 시작했다...",
  "severity": "minor",
  "tags": ["mental", "town_wide"],
  "trigger": {
    "cycle": "weekly",
    "day_interval": 7,
    "probability": 0.3,
    "max_active": 3,
    "exclude_if": { "flag_eq": ["crisis.nightmare_town.resolved", true] }
  },
  "ongoing_effects": [
    {
      "effect_id": "nightmare_rest_penalty",
      "trigger_on": "rest_attempt",
      "when": { "time_block": "night" },
      "action": {
        "type": "attribute_check",
        "attribute": "will",
        "difficulty": 2,
        "pass_message": "의지력으로 악몽을 견뎌냈다.",
        "fail_actions": [
          { "type": "change_metric", "key": "player.mental", "amount": -5 },
          { "type": "add_condition", "condition_id": "haunted", "duration": 3 },
          { "type": "log", "message": "악몽 때문에 휴식을 취하지 못했다." }
        ]
      }
    }
  ],
  "resolution": {
    "conditions": {
      "all_of": [
        { "flag_eq": ["investigated_nightmare", true] },
        { "has_item": ["holy_symbol", 1] }
      ]
    },
    "actions": [
      { "type": "set_flag", "key": "crisis.nightmare_town.resolved", "value": true },
      { "type": "remove_condition", "condition_id": "haunted" },
      { "type": "change_metric", "key": "npc.luise.trust", "amount": 5 },
      { "type": "dialogue", "dialogue_id": "nightmare_resolved" }
    ]
  },
  "escalation": {
    "doom_days": 14,
    "warning_days": 10,
    "warning_dialogue": "nightmare_warning",
    "per_day_effects": [
      { "type": "change_metric", "key": "player.mental", "amount": -1 }
    ],
    "doom_type": "compound",
    "doom_actions": [
      { "type": "set_flag", "key": "crisis.nightmare_town.doomed", "value": true },
      { "type": "block_place", "place_id": "tavern" },
      { "type": "dialogue", "dialogue_id": "nightmare_doom" },
      { "type": "game_over", "reason": "마을이 영원한 악몽에 잠겼다.", "type": "normal" }
    ]
  }
}
```

#### severity 등급

| 등급 | 설명 | 동시 활성 수 카운트 |
|------|------|-------------------|
| `minor` | 경미한 위기. 지속 효과만 있음. 파멸 없음. | 0.5 (2개가 1개 슬롯 차지) |
| `major` | 심각한 위기. 지속 효과 + 파멸 타이머. | 1 |
| `doom` | 파멸 위기. 게임오버 또는 지역 파괴 유발. | 2 |

**다중 위기 규칙**: `minor`(×2) + `major`(×1) = 3슬롯 중 2개 사용.

### 2.2 상태 카드 — `data/conditions/{condition_id}.json`

```json
{
  "condition_id": "haunted",
  "display_name": "악몽에 시달림",
  "description": "잠들 때마다 끔찍한 환영이 뇌리를 맴돈다.",
  "icon_path": "res://assets/icons/condition_haunted.png",
  "tags": ["mental", "reckoning"],
  "max_stack": 3,
  "reckoning": {
    "trigger": "daily_midnight",
    "action": {
      "type": "attribute_check",
      "attribute": "will",
      "difficulty": 1,
      "fail_actions": [
        { "type": "change_metric", "key": "player.mental", "amount": -3 }
      ]
    }
  },
  "on_remove": {
    "actions": [
      { "type": "log", "message": "악몽에서 벗어났다." }
    ]
  }
}
```

**정산(Reckoning) 트리거 종류:**

| 트리거 | 시점 | 예시 |
|--------|------|------|
| `daily_midnight` | 매일 자정 | 대부분의 상태 카드 |
| `rest_attempt` | 휴식 시도 시 | `haunted` — 휴식 시 정산 |
| `place_entered` | 특정 장소 입장 시 | `poisoned` — 독성 지역 입장 시 |
| `combat_start` | 전투 시작 시 | `bleeding` — 전투 시 HP 추가 감소 |
| `manual` | 플레이어가 "정산" 행동 선택 시 | 보드게임의 "Reckoning" 페이즈 재현 |

### 2.3 둠 트래커 — 게임 전체 파멸 게이지

```json
// data/global_doom.json (단일 파일, 게임 전체 설정)
{
  "doom_track": {
    "max": 20,
    "initial": 0,
    "increment_sources": [
      { "source": "crisis_doom", "amount": 2 },
      { "source": "failed_reckoning", "amount": 1 },
      { "source": "dungeon_death", "amount": 1 }
    ],
    "decrement_sources": [
      { "source": "crisis_resolved", "amount": -1 },
      { "source": "special_item", "item_id": "ancient_scroll", "amount": -2 }
    ],
    "thresholds": [
      { "at": 10, "action": { "type": "play_bgm", "bgm_id": "tension_rising" } },
      { "at": 15, "action": { "type": "dialogue", "dialogue_id": "doom_warning_15" } },
      { "at": 20, "action": { "type": "game_over", "reason": "세계가 암흑에 잠겼다.", "type": "doom" } }
    ]
  }
}
```

**둠 트래커는 게임 전체의 "시계" 역할을 한다.** 위기가 파멸되거나 정산 실패 시 둠이 쌓인다. 둠 20 도달 = 무조건 게임오버.

---

## 3. 게임 흐름 통합

### 3.1 7일 위기 페이즈 (Mythos Phase)

```
[Day 7 자정] TimeSystem.day_advanced 시그널
    ↓
CrisisManager.on_weekly_cycle()
    ↓
1. 활성 위기 수 < 3 ?
   → max_active 계산 (minor=0.5, major=1, doom=2)
    ↓
2. 사용 가능한 슬롯이 있다면:
   - 후보 위기 중 probability 기반 랜덤 선택
   - exclude_if 조건으로 이미 해결/파멸된 위기 제외
    ↓
3. 선택된 위기 활성화:
   - GameFlags: `crisis.{id}.active = true`
   - MetricStore: `crisis.{id}.doom_timer = escalation.doom_days`
   - EventBus.emit("crisis_triggered", crisis_data)
    ↓
4. 기존 활성 위기의 doom_timer -1
   → 0 이하인 위기: 파멸 처리
    ↓
5. 둠 트래커 평가
   → 임계값 도달 시 효과 실행
```

### 3.2 매일 정산 (Daily Reckoning)

```
[매일 자정 또는 휴식 시도 시]
    ↓
CrisisManager.apply_reckoning(context)
    ↓
플레이어가 보유한 모든 상태 카드 순회:
  - reckoning.trigger == context 인 것만 실행
    ↓
각 상태 카드의 정산 액션 실행:
  - attribute_check (will/observation/strength)
  - 성공: stack -1 또는 유지
  - 실패: 지정된 패널티 + 둠 +1
    ↓
결과 로그 출력
```

### 3.3 지역 봉쇄 (Place Block)

파멸된 위기가 `block_place` 액션을 가지면, 해당 장소가 잠긴다.

```json
{ "type": "block_place", "place_id": "tavern", "reason": "악몽으로 주점이 폐쇄되었다." }
```

**봉쇄 효과:**
- 해당 장소로 이동 불가
- 해당 장소에 등장하는 NPC 스케줄 무효화
- 루이제가 주점 주인이라면 → 루이제 조우 불가 (스토리적 타격)
- 봉쇄 해제: 위기 해결 또는 특별 이벤트

### 3.4 게임오버 종류

| 종류 | 트리거 | 결과 |
|------|--------|------|
| **위기 파멸 오버** | 특정 위기의 doom_days 도달 | 해당 위기 파멸 대화 → 오버 |
| **둠 트래커 오버** | 둠 20 도달 | 세계 멸망 대화 → 오버 |
| **히로인 게임오버** | 루이제 납치 이벤트 실패 | 루이제 관련 오버 → 해당 히로인 루트 종료 |
| **생존 실패** | HP/mental 0 이하 | 던전 또는 정산으로 사망 |

**오버 후 처리:**
- `game_over` action의 `type` 필드로 구분:
  - `"normal"`: 일반 엔딩 → 세이브 유지, 계속하기 가능
  - `"doom"`: 파멸 엔딩 → 세이브 삭제 또는 NG+ 제안
  - `"heroine"`: 히로인 오버 → 해당 히로인만 비활성화, 다른 히로인 계속 가능

---

## 4. 루이제/연애 루프와의 통합

### 4.1 위기 상태에 따른 루이제 변화

루이제의 대사/행동/조우 가능성이 `CrisisManager.active_crises`에 의해 동적으로 변경된다.

**구현 방식:**
- 루이제의 스케줄 JSON에 `crisis_conditions` 추가 (선택사항)
- 또는 InteractionRegistry의 `when` 조건에 `crisis_active` 조건 타입 추가

```json
// luise의 대화 이벤트에 위기 반응 분기
{
  "id": "luise_talk_nightmare_active",
  "priority": 50,
  "when": { "crisis_active": "nightmare_town" },
  "actions": [
    { "type": "dialogue", "dialogue_id": "luise_nightmare_worried" }
  ]
}
```

### 4.2 루이제가 위기 해결을 의뢰

루이제와의 대화 중 특정 호감도 이상일 때, 위기 관련 의뢰 대화가 등장:

```
루이제: "요즘 밤에 소리가 들려... 무서워."
선택지:
- "무슨 소리?" → 단서 획득 (investigated_nightmare 플래그)
- "신경 쓰지 마" → 호감도 -1, 루이제 불안 증가
- "내가 알아볼게" → 호감도 +1, 의뢰 수락
```

의뢰 수락 시:
- 던전에서 `holy_symbol` 아이템 획득 목표로 설정
- 획득 시 위기 해결 조건 충족

### 4.3 위기 파멸이 관계에 미치는 영향

| 파멸 유형 | 루이제 반응 | 관계 영향 |
|-----------|------------|----------|
| 주점 봉쇄 | 루이제 다른 장소로 이동 (lobby 또는 inn_room) | 조우 패턴 변화, 대사에 불만 |
| 마을 전체 파멸 | 특별 오버 대화 | 해당 히로인 루트 종료 또는 엔딩 분기 |

---

## 5. 현재 아키텍처에 필요한 확장

### 5.1 새 autoload

| 이름 | 역할 | 기존 시스템과의 관계 |
|------|------|---------------------|
| **CrisisRegistry** | `data/crises/*.json` 스캔, 위기 데이터 인덱싱 | PlaceRegistry 패턴 그대로 적용 |
| **CrisisManager** | 활성 위기 상태 관리, 7일 체크, 정산 실행, 둠 트래커 | TimeSystem에 연결. EventBus로 알림 |
| **ConditionManager** | 플레이어의 상태 카드 보유 목록, 정산 트리거, 지속 기간 | MetricStore 기반. `player.conditions[]` 형태 |

### 5.2 새 action type (ActionRunner 확장)

| type | 인자 | 설명 |
|------|------|------|
| `game_over` | `reason`, `type` | 게임오버 처리. 세이브 보존/삭제 분기 |
| `attribute_check` | `attribute`, `difficulty`, `pass_actions`, `fail_actions` | EH 다이스 풀 체크. `player.{attribute}` 값 기반 |
| `add_condition` | `condition_id`, `duration`, `stack` | 상태 카드 부여 |
| `remove_condition` | `condition_id` | 상태 카드 제거 |
| `change_doom` | `amount` | 둠 트래커 증감 |
| `block_place` | `place_id`, `reason` | 장소 봉쇄 |
| `unblock_place` | `place_id` | 장소 봉쇄 해제 |

### 5.3 새 condition type (ConditionEvaluator 확장)

| condition | 예시 | 설명 |
|-----------|------|------|
| `crisis_active` | `{ "crisis_active": "nightmare_town" }` | 특정 위기가 활성 상태인지 |
| `doom_gte` | `{ "doom_gte": 10 }` | 둠 트래커가 N 이상인지 |
| `has_condition` | `{ "has_condition": ["haunted", 1] }` | 특정 상태 카드를 N개 보유 중인지 |
| `place_blocked` | `{ "place_blocked": "tavern" }` | 특정 장소가 봉쇄 상태인지 |

### 5.4 TimeSystem 연결

```gdscript
# TimeSystem.gd
func advance_day():
    day += 1
    emit_signal("day_advanced", day)
    
    # 7일마다 위기 페이즈 트리거
    if day % 7 == 0:
        CrisisManager.on_mythos_phase()
    
    # 매일 자정 정산
    CrisisManager.on_daily_reckoning()
```

---

## 6. 구현 로드맵

### Phase 1: 시스템 골격 (2주)

| 작업 | 설명 |
|------|------|
| CrisisRegistry | `data/crises/` 폴더 스캔, JSON 파싱 |
| CrisisManager | 활성 위기 목록 관리, 7일 체크, doom 타이머 |
| ConditionManager | 상태 카드 보유/추가/제거/정산 |
| Action 확장 | `game_over`, `attribute_check`, `add_condition`, `remove_condition`, `change_doom`, `block_place` |
| Condition 확장 | `crisis_active`, `doom_gte`, `has_condition`, `place_blocked` |
| 둠 트래커 | `global.doom` metric 관리, 임계값 체크 |
| 디버그 UI | 현재 활성 위기 목록, 둠 수치, 보유 상태 카드 (F1 오버레이) |

**검수 기준:**
- 7일째 되는 날 위기가 자동으로 발생한다
- 활성 위기의 지속 효과가 rest_attempt 시 적용된다
- 상태 카드의 정산이 매일 자정에 실행된다
- 둠 20 도달 시 게임오버 대화가 실행된다

### Phase 2: 콘텐츠 통합 (2주)

| 작업 | 설명 |
|------|------|
| 샘플 위기 3종 | `nightmare_town` (minor), `plague_rats` (major), `eldritch_awakening` (doom) |
| 샘플 상태 카드 5종 | `haunted`, `poisoned`, `bleeding`, `cursed`, `terrified` |
| 루이제 위기 반응 | 위기 활성 시 대사 분기 3종 |
| 루이제 의뢰 시스템 | 위기 관련 던전 의뢰 대화 + 아이템 연결 |
| 주점 봉쇄 시나리오 | `nightmare_town` 파멸 → tavern 봉쇄 → 루이제 이동 → 특별 대화 |

**검수 기준:**
- 루이제가 악몽 위기 중 걱정하는 대사를 한다
- 던전에서 `holy_symbol`을 얻어 오면 위기가 해결된다
- 위기 해결 시 루이제의 신뢰 호감도가 상승한다
- 파멸 시 주점이 봉쇄되고 루이제의 조우 장소가 변경된다

### Phase 3: 폴리시/밸런싱 (1주)

| 작업 | 설명 |
|------|------|
| 위기 발생 확률 튜닝 | 너무 자주 또는 너무 드물지 않게 |
| attribute_check 난이도 | will 1~5 기준으로 difficulty 밸런싱 |
| 둠 증감량 조정 | 게임오버까지 적절한 템포 |
| 다중 위기 조합 테스트 | minor+major+doom 동시 활성 시나리오 |

---

## 7. 보드게임 원본과의 차이점 정리 (향후 변형 가이드)

현재는 EH를 "카피캣"하지만, 구현 후 다음과 같이 이름과 메커닉을 변형할 예정.

| EH 원본 | 현재 게임 내 명칭 | 변형 방향 |
|---------|------------------|----------|
| Mythos Phase | 위기 페이즈 (Crisis Phase) | 유지. 7일 사이클은 게임에 적합 |
| Reckoning | 정산 (Reckoning) | 유지. 보드게임 용어 그대로 사용 가능 |
| Condition 카드 | 상태 카드 (Condition Card) | 유지. RPG에서도 일반적인 용어 |
| Doom Track | 둠 트래커 (Doom Track) | 유지 또는 "어둠의 시계" 등으로 변경 검토 |
| Ancient One | 고대의 존재 | → "어둠의 근원", "깊은 자" 등으로 변경 |
| Gate | 차원문 | → "균열", "어둠의 틈" 등으로 변경 |
| Investigator | 조사자 | → "모험가" (이미 게임 내 용어) |
| Eldritch Token | 엘드리치 토큰 | → "어둠의 흔적", "저주의 조각" 등으로 변경 |

---

## 8. 체크리스트

구현 착수 전에 다음이 준비되어야 한다:

- [ ] `data/crises/` 폴더 생성
- [ ] `data/conditions/` 폴더 생성
- [ ] `data/global_doom.json` 파일 생성
- [ ] ActionRunner에 새 action type 추가 (코드)
- [ ] ConditionEvaluator에 새 condition type 추가 (코드)
- [ ] TimeSystem에 7일 체크 / 자정 정산 연결 (코드)
- [ ] CrisisRegistry autoload 등록 (project.godot)
- [ ] CrisisManager autoload 등록 (project.godot)
- [ ] ConditionManager autoload 등록 (project.godot)
- [ ] 샘플 위기 JSON 1개 작성 (nightmare_town)
- [ ] 샘플 상태 카드 JSON 1개 작성 (haunted)

---

**문서 버전**: 1.0
**최종 업데이트**: 2026-05-16
**다음 단계**: Phase 1 구현 착수 (사용자 승인 시)