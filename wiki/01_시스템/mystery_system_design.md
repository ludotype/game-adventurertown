# 미스터리 시스템 설계서 (Mystery System Design)

> 엘드리치 호러(Eldritch Horror)의 Mystery 카드와 아컴 호러(Arkham Horror)의 Mythos 페이즈를 City of Eldritch의 콘텐츠 아키텍처에 통합한 설계입니다.
> **목적**: 기존의 Case, Crisis, Doom Track, 던전 탐사를 하나의 서사적/기계적 흐름으로 묶는 상위 컨테이너 시스템을 정의합니다.
> **기준 문서**: `wiki/00_헌법/new_direction.md`, `wiki/01_시스템/crisis_system_design.md`

---

## 1. 미스터리란 무엇인가? (Core Concept)

### 1.1 비유: 엘드리치 호러의 Mystery 카드

엘드리치 호러에서 **미스터리(Mystery)**는 고대 신(Ancient One)을 저지하기 위해 조사자들이 반드시 풀어야 하는 단계적 목표입니다.

- 미스터리를 3개 해결하면 게임 승리 (고대 신 각성 전)
- 고대 신이 각성하면 **최종 미스터리(Final Mystery)**를 추가로 해결해야 함
- 각 미스터리는 고유한 다단계 과제(클루 토큰 배치, 엘드리치 토큰 수집, 몬스터 처치, 특수 조우 완료)를 요구

### 1.2 본 게임에서의 정의

> **미스터리(Mystery)**는 나틀락에 퍼진 특정 괴현상의 **근원(root cause)** 을 규명하고 봉인하는 것을 목표로 하는, 단계적 서사 목표입니다.

미스터리는 기존 시스템들을 하나의 서사로 묶습니다:

```
[Mystery]  ←── 상위 컨테이너 (서사 목표)
  ├── [Crisis]      ←── 7일 사이클 위기 (지속 효과 + 둠 타이머)
  ├── [Dungeon]     ←── 사건 던전 (핵심 오염원 처치)
  ├── [Clue Chain]  ←── 단서 체인 (조사 행동으로 해금)
  ├── [Local Crisis]←── 장소 위기 (파멸 토큰 → 장소 변이)
  └── [Boss]        ←── 최종 보스/의식 (미스터리 해결 조건)
```

### 1.3 미스터리 vs Case vs Crisis의 관계

| 개념 | 역할 | 활성화 방식 | 예시 |
|------|------|------------|------|
| **Case** | 메인 스토리라인의 큰 장(chapter) | 순차적 해금 (Case 1 클리어 → Case 2) | "제1장: 잠든 자의 눈" |
| **Mystery** | Case 내부의 단계적 수수께끼 | Case 활성 시 자동 배치, 단계별 순차 진행 | "거대 쥐의 근원", "사라지는 글자" |
| **Crisis** | 세계관적 재난 (Mythos 페이즈) | 7일 사이클 또는 미스터리와 연동 | "쥐의 행진", "지식의 만찬" |
| **Dungeon** | 미스터리의 물리적 결전장 | 조사 진척도 임계점 도달 시 해금 | "지하 수로", "대성당 지하실" |

> **핵심 규칙**: 한 번에 **하나의 Case**만 활성화되며, 각 Case에는 **1~3개의 Mystery**가 순차적으로 배치됩니다. Mystery를 모두 해결해야 Case가 클리어되고 다음 Case로 넘어갑니다.

---

## 2. 미스터리의 생명주기 (Lifecycle)

```
[잠재] → [활성화] → [단계 1: 조사] → [단계 2: 던전 해금] → [단계 3: 최종 결전] → [해결] → [보상]
   ↓         ↓              ↓                  ↓                     ↓              ↓         ↓
  Case    Mystery     소문/괴현상      사건 던전 개방          보스 처치/의식     해결 플래그   해금 포인트
  해금    배치         단서 수집        (AP 소모 탐사)          (전투/판정)      다음 단계    +NPC 신뢰
```

### 2.1 단계별 상세

| 단계 | 명칭 | 설명 | 플레이어 행동 |
|------|------|------|--------------|
| 0 | **잠재 (Dormant)** | Case가 아직 해금되지 않음. 미스터리는 데이터상 존재하나 게임 내에 노출되지 않음. | - |
| 1 | **활성화 (Active)** | Case 해금으로 미스터리가 게임에 등장. 첫 번째 단계의 목표가 공개됨. | 소문 수집, 뉴스 확인 |
| 2 | **조사 (Investigation)** | 도시에서 괴현상을 추적. AP를 소모하여 조사 판정. 단서(Clue Token) 수집. | `조사` 행동, NPC 대화, `고서 조사` |
| 3 | **던전 해금 (Dungeon Unlock)** | 단서 충족 시 사건 던전이 맵에 표시됨. 던전 내 특수 이벤트 체인 활성화. | 던전 이동, 던전 탐사(2 AP/칸) |
| 4 | **최종 결전 (Confrontation)** | 던전 최심부에서 보스 조우 또는 의식/판정 이벤트. | 전투 또는 `의지력`/`통찰` 체크 |
| 5 | **해결 (Resolved)** | 최종 결전 성공. 미스터리 해결 플래그 설정. 지역 위기(Local Crisis) 해제. | - |
| 6 | **보상 (Reward)** | 해금 포인트, NPC 신뢰도 상승, 둠 트래커 감소, 다음 Mystery 또는 Case 해금. | - |

---

## 3. 미스터리 유형 (Mystery Types)

엘드리치 호러의 Mystery 카드 3종을 본 게임 메카닉에 맞게 변형합니다.

### 3.1 유형 A: 조사형 (Research Mystery)

> **개념**: 도시 여러 장소에서 `조사` 행동을 반복하여 단서(Clue Token)를 모으는 미스터리.
> **엘드리치 호러 원형**: Research Encounter를 통해 Mystery 카드에 Clue Token을 배치.

**메카닉**:
- 특정 태그의 장소(예: `[지식]`)에서 `조사` 행동 시 성공하면 `clue_token` +1
- Mystery 카드에 필요한 `clue_tokens_needed` 만큼 모으면 자동 해결
- 중간 단계(예: 1개 수집 시)마다 **힌트 텍스트** 또는 **새로운 장소 위기** 해금

**예시**: **"사라지는 글자"**
- 필요 단서: 3개
- 대상 태그: `[지식]` (대도서관, 천문탑)
- 1개 수집: *"책의 글자가 사라지는 방향을 추적하면... 지하로 이어진다."* (던전 힌트)
- 2개 수집: *"고대 룬 문자가 흡수되는 중심지가 대도서관 지하임이 확인되었다."* (`grand_library`에 파멸 토큰 +1)
- 3개 수집: 자동 해결 또는 던전 해금

---

### 3.2 유형 B: 정화형 (Cleansing Mystery)

> **개념**: 도시 특정 구역의 장소 위기(Local Crisis)를 모두 정화(Cleanse)해야 해결되는 미스터리.
> **엘드리치 호러 원형**: Eldritch Token을 보드에 배치하고, 조사자가 해당 장소에서 조우를 성공시켜 토큰을 Mystery 카드로 옮김.

**메카닉**:
- 미스터리 활성화 시, 대상 태그의 장소들에 자동으로 **파멸 토큰**을 배치 (Crisis 연동)
- 플레이어는 각 장소에서 `정화(Cleanse)` 행동(AP 4 소모)을 성공시켜 파멸 토큰 제거
- 모든 대상 장소의 파멸 토큰이 0이 되면 미스터리 해결
- 정화 실패 시 `change_doom` +1

**예시**: **"피의 대성당"**
- 대상: `[신앙]` 태그 장소 — `cathedral_nave`
- 활성화 시: `cathedral_nave`에 파멸 토큰 3개 배치
- 1회 정화 성공: 파멸 토큰 -1, *"성수의 붉은색이 조금 옅어진다."*
- 3회 정화 성공: 미스터리 해결, *"성당의 종소리가 다시 맑게 울려 퍼진다."*

---

### 3.3 유형 C: 처치형 (Confrontation Mystery)

> **개념**: 사건 던전의 보스를 처치하거나 특수 이벤트를 완료해야 해결되는 미스터리.
> **엘드리치 호러 원형**: Special Encounter 또는 Monster Ambush를 통해 목표 달성.

**메카닉**:
- 미스터리 활성화 시 특정 **사건 던전**이 맵에 해금됨 (또는 기존 던전에 새로운 경로 추가)
- 플레이어는 던전 탐사를 통해 최심부의 **보스/의식**에 도달해야 함
- 보스 처치 또는 `의지력`/`통찰` 체크 성공 시 해결
- 보스 전투 패배 시 `change_doom` +2, 플레이어는 여관으로 강제 귀환

**예시**: **"굶주린 심연의 쥐왕"**
- 해금 던전: `sewer_depths` (하수도 깊은 곳)
- 최종 이벤트: 던전 최심부에서 `rat_king_boss` 조우
- 전투 승리: 미스터리 해결, `rat_king_defeated` 플래그 설정
- 전투 패배: HP 50% 회복, `lobby`로 강제 이동, `change_doom` +2

---

### 3.4 유형 D: 복합형 (Compound Mystery)

> **개념**: 위 3가지 유형을 조합한 다단계 미스터리. 본 게임의 **메인 Case**는 모두 복합형.
> **엘드리치 호러 원형**: 일부 고대 신(Ancient One)의 Mystery는 Clue 수집 + Token 배치 + 아이템 소모를 동시에 요구.

**메카닉**:
```
단계 1: 단서 수집 (조사형) → 던전 해금
단계 2: 장소 정화 (정화형) → 보스 약화
단계 3: 보스 처치 (처치형) → 최종 해결
```

**예시**: **Case 1 — "잠든 자의 눈"**
- Mystery 1-A (조사형): `대도서관` 및 `천문탑`에서 2개의 단서 수집 → "지하 제단" 던전 해금
- Mystery 1-B (정화형): `cathedral_nave`에 발생한 "피의 대성당" 장소 위기 정화 → 보스 약화
- Mystery 1-C (처치형): `지하 제단` 던전 최심부에서 `sleeping_eye_cultist` 보스 처치 → Case 1 클리어

---

## 4. 미스터리와 기존 시스템의 연동

### 4.1 CrisisManager와의 연동

```
[Mystery 활성화]
    ↓
CrisisManager가 해당 미스터리와 연계된 Crisis를 "연동 위기"로 등록
    ↓
7일 사이클 시 연동 Crisis의 효과 강화:
    - 미스터리 미해결 상태일 경우: doom_timer 감소폭 증가
    - 미스터리 단계 진행 시: Crisis의 per_day_effects 약화
    - 미스터리 해결 시: Crisis 자동 해제 + 둠 -1
```

**데이터 연결**: `mystery.json`의 `linked_crisis_id` 필드로 Crisis와 1:1 또는 1:N 연결.

### 4.2 Doom Track과의 연동

| 상황 | Doom 변화 |
|------|----------|
| Mystery 활성화 (Case 해금) | +0 (Case 자체에서 관리) |
| Mystery 단계 진행 (단서 수집 등) | +0 |
| Mystery 정화 실패 | +1 |
| Mystery 보스 전투 패배 | +2 |
| Mystery 해결 | -1 |
| Mystery 방치 (연동 Crisis 파멸) | +3 ~ +5 (Crisis의 doom_type에 따라) |

### 4.3 NPC와의 연동

| NPC | 미스터리 연동 역할 |
|-----|-------------------|
| **루이제** | Mystery 활성화 시 "소문 귀동냥"에서 해당 미스터리 관련 힌트 확률 증가. 해결 시 Trust +2 |
| **셰퍼드** | 연동 Crisis 발생 시 `guard_station`에서 "위기 의뢰" 퀘스트 등장. 해결 시 Trust +3 |
| **신부** | 정화형 Mystery에서 `cathedral_nave`의 정화 행동 효과 +1 (보너스 주사위) |
| **마녀** | 처치형 Mystery에서 던전 입장 시 버프 묘약 구매 가능. 단, 부작용 위험 |

### 4.4 Dungeon과의 연동

- Mystery의 `dungeon_id` 필드가 설정되면, 해당 Mystery가 **단계 2(조사 완료)** 에 도달하면 자동으로 던전이 맵에 표시됨.
- 던전은 Mystery가 해결되기 전까지 상시 개방.
- Mystery 해결 시 던전은 **봉인(Sealed)** 상태로 전환 — 재입장 불가 또는 일반 몬스터만 남음.

---

## 5. 데이터 스키마

### 5.1 미스터리 정의 — `data/mysteries/{mystery_id}.json`

```json
{
  "mystery_id": "the_vanishing_letters",
  "display_name": "사라지는 글자",
  "description": "대도서관의 고서에서 글자가 사라지기 시작했다. 누군가 고대 룬을 흡수하고 있는 것 같다.",
  "mystery_type": "research",
  "linked_case_id": "case_01",
  "linked_crisis_id": "the_slumbering_great_mind",
  "order_in_case": 1,
  "phases": [
    {
      "phase_id": "phase_01_clues",
      "phase_name": "단서 추적",
      "objective": {
        "type": "collect_clues",
        "target_tags": ["지식"],
        "clues_needed": 3,
        "check_attribute": "insight",
        "check_difficulty": 2
      },
      "rewards_on_phase_complete": [
        { "type": "set_flag", "key": "mystery.vanishing_letters.phase_01_done", "value": true },
        { "type": "log", "message": "글자가 사라지는 근원지를 추적했다. 대도서관 지하에서 불길한 기운이 느껴진다." }
      ]
    },
    {
      "phase_id": "phase_02_dungeon",
      "phase_name": "던전 탐사",
      "prerequisite": { "flag_eq": ["mystery.vanishing_letters.phase_01_done", true] },
      "objective": {
        "type": "dungeon_clear",
        "dungeon_id": "library_underground",
        "boss_id": "rune_eater",
        "required_item": null
      },
      "rewards_on_phase_complete": [
        { "type": "set_flag", "key": "mystery.vanishing_letters.resolved", "value": true },
        { "type": "change_doom", "amount": -1 },
        { "type": "change_metric", "key": "npc.luise.trust", "amount": 2 },
        { "type": "log", "message": "사라지는 글자의 미스터리를 해결했다. 고서관의 지식이 다시금 안전해졌다." }
      ]
    }
  ],
  "escalation": {
    "doom_if_ignored_days": 14,
    "warning_days": 10,
    "warning_dialogue": "mystery_vanishing_letters_warning",
    "doom_actions": [
      { "type": "change_doom", "amount": 3 },
      { "type": "block_place", "place_id": "grand_library", "reason": "모든 책의 글자가 사라져 대도서관이 폐쇄되었다." },
      { "type": "dialogue", "dialogue_id": "mystery_vanishing_letters_doom" }
    ]
  },
  "on_resolve": {
    "actions": [
      { "type": "remove_condition", "condition_id": "cognitive_distortion" },
      { "type": "unblock_place", "place_id": "grand_library" },
      { "type": "change_metric", "key": "player.unlock_points", "amount": 50 }
    ]
  }
}
```

### 5.2 필드 설명

| 필드 | 타입 | 설명 |
|------|------|------|
| `mystery_id` | string | 고유 ID. 파일명과 동일해야 함 |
| `display_name` | string | 게임 내 표시 이름 |
| `mystery_type` | enum | `research` / `cleansing` / `confrontation` / `compound` |
| `linked_case_id` | string | 속한 Case ID |
| `linked_crisis_id` | string | 연동 Crisis ID (선택사항) |
| `order_in_case` | int | Case 내 Mystery 순서 (1부터) |
| `phases` | array | 단계별 목표 배열 |
| `phases[].objective.type` | enum | `collect_clues` / `dungeon_clear` / `cleanse_places` / `defeat_boss` / `ritual_check` |
| `escalation` | object | 방치 시 파멸 규칙 |
| `on_resolve` | object | 해결 시 실행할 액션 |

### 5.3 objective.type 상세

| 타입 | 필요 필드 | 설명 |
|------|----------|------|
| `collect_clues` | `target_tags`, `clues_needed`, `check_attribute`, `check_difficulty` | 지정 태그 장소에서 조사 성공 시 단서 수집 |
| `cleanse_places` | `target_tags`, `cleanse_count`, `doom_tokens_per_place` | 지정 태그 장소의 파멸 토큰을 모두 제거 |
| `dungeon_clear` | `dungeon_id`, `boss_id` | 지정 던전의 보스 처치 |
| `defeat_boss` | `boss_id`, `location` | 특정 장소의 보스 처치 (던전 외) |
| `ritual_check` | `location`, `attribute`, `difficulty` | 특정 장소에서 의식/판정 성공 |

---

## 6. Case — Mystery 매핑 (5개 메인 Case)

> ⚠️ **아래는 기획 예시입니다.** 실제 콘텐츠는 스토리팀/기획자가 작성합니다.

### Case 1: 잠든 자의 눈 (The Sleeping Eye)

**배경**: 나틀락의 대도서관과 천문탑에서 기이한 현상이 발생합니다. 책의 글자가 사라지고, 별들의 궤적이 왜곡됩니다. The Slumbering Maw의 첫 번째 "눈"이 떠오르려 합니다.

| 순서 | Mystery ID | 유형 | 이름 | 연동 Crisis | 연동 던전 |
|------|-----------|------|------|------------|----------|
| 1 | `myst_01a_vanishing_letters` | research | 사라지는 글자 | `the_slumbering_great_mind` | `library_underground` |
| 2 | `myst_01b_twisted_stars` | cleansing | 왜곡된 별빛 | `the_slumbering_great_mind` | `astronomy_tower_basement` |
| 3 | `myst_01c_sleeping_eye` | confrontation | 잠든 자의 눈 | - | `catacombs_depths` |

**Case 클리어 조건**: 3개 Mystery 모두 해결
**Case 클리어 보상**: Unlock Points +100, 둠 -2, `case_02_unlocked` 플래그

### Case 2: 피의 대성당 (The Sanguine Basilica)

**배경**: 대성당의 성수가 피로 변하기 시작합니다. 신부와 수녀의 대사가 왜곡되고, `cathedral_nave`의 치유 기능이 독 데미지로 역전됩니다.

| 순서 | Mystery ID | 유형 | 이름 | 연동 Crisis | 연동 던전 |
|------|-----------|------|------|------------|----------|
| 1 | `myst_02a_blood_font` | cleansing | 피의 성혈 | `sanguine_cathedral_crisis` | `cathedral_crypt` |
| 2 | `myst_02b_heretical_ritual` | research | 이교도의 의식 | `sanguine_cathedral_crisis` | - |
| 3 | `myst_02c_crimson_priest` | confrontation | 진홍의 사제 | - | `cathedral_depths` |

### Case 3: 쥐의 행진 (March of the Rats)

**배경**: 슬럼가와 하수도에서 거대 쥐들이 출몰합니다. 루이제의 소문("하수도에서 집채만한 쥐를 봤다")이 현실이 됩니다.

| 순서 | Mystery ID | 유형 | 이름 | 연동 Crisis | 연동 던전 |
|------|-----------|------|------|------------|----------|
| 1 | `myst_03a_sewer_whispers` | research | 하수도의 속삭임 | `rat_march_crisis` | `sewer_depths` |
| 2 | `myst_03b_plague_nest` | confrontation | 역병의 둥지 | `rat_march_crisis` | `sewer_depths` |

### Case 4: 검은 칼날의 계약 (The Black Blade Pact)

**배경**: 도적들의 소굴에서 금기된 거래가 시작됩니다. '검은 칼날' 조직이 외신과 계약하려 합니다.

| 순서 | Mystery ID | 유형 | 이름 | 연동 Crisis | 연동 던전 |
|------|-----------|------|------|------------|----------|
| 1 | `myst_04a_underground_pact` | research | 지하 계약서 | `black_blade_crisis` | `rogues_den_vault` |
| 2 | `myst_04b_pit_master_secret` | confrontation | 투기장 주인의 비밀 | `black_blade_crisis` | `rogues_den_vault` |

### Case 5: 굶주린 심연 (The Slumbering Maw)

**배경**: 최종 Case. The Slumbering Maw가 완전히 각성하기 직전입니다. 도시 전역에 파멸의 힘이 퍼지고, 둠 트래커가 임계점에 도달합니다.

| 순서 | Mystery ID | 유형 | 이름 | 연동 Crisis | 연동 던전 |
|------|-----------|------|------|------------|----------|
| 1 | `myst_05a_doom_sigils` | cleansing | 파멸의 인장 | `final_awakening_crisis` | 다중 장소 |
| 2 | `myst_05b_ancient_seal` | research | 고대 봉인의 단서 | `final_awakening_crisis` | `natlach_depths` |
| 3 | `myst_05c_the_maw` | confrontation | 굶주린 심연 | - | `natlach_depths` |

**Case 클리어 (Normal Ending)**: `natlach_depths` 최심부에서 봉인 의식 성공 → The Slumbering Maw 일시 봉인
**True Ending 조건**: 모든 이전 Case의 Hidden Mystery도 해결 + 특정 유물 조합 보유

---

## 7. 미스터리 UI 및 피드백

### 7.1 현재 활성 미스터리 표시

상단 메트릭 바 또는 별도 UI 패널에 표시:

```
[Active Mystery] 사라지는 글자 (1/3 Clues)
[Case Progress] Case 1 — 잠든 자의 눈  (1/3 Mysteries)
[Doom Track] ████████░░░░░░░░░░░░  8/20
```

### 7.2 미스터리 단계 진행 로그

플레이어가 단서를 수집하거나 던전을 해금할 때, 화면 하단 로그에 피드백:

```
> 대도서관에서 조사를 성공했다. (단서 +1)  —  사라지는 글자: 2/3
> 사라지는 글자의 근원지를 특정했다!  [지하 제단] 던전이 해금되었습니다.
```

### 7.3 방치 경고

`escalation.warning_days` 도달 시:

```
[경고] '사라지는 글자' 미스터리를 너무 오래 방치했습니다.
        대도서관의 글자가 완전히 사라지기 직전입니다.
        4일 내에 해결하지 않으면 둠 +3 및 대도서관 봉쇄.
```

---

## 8. 구현 체크리스트

### Phase 1: 시스템 골격 (1주)

| 작업 | 설명 | 관련 시스템 |
|------|------|------------|
| MysteryRegistry | `data/mysteries/` 폴더 스캔, JSON 파싱, Case 기준 인덱싱 | PlaceRegistry 패턴 따름 |
| MysteryManager | 활성 Mystery 상태 관리, 단계 진행 체크, 해결 처리 | CrisisManager, ConditionManager 연동 |
| ActionRunner 확장 | `mystery_phase_check`, `unlock_dungeon`, `seal_dungeon` action type 추가 | 기존 ActionRunner 확장 |
| ConditionEvaluator 확장 | `mystery_active`, `mystery_phase_eq`, `mystery_resolved` condition type 추가 | 기존 evaluator 확장 |
| UI 연동 | 상단 메트릭 바 또는 별도 패널에 Active Mystery / Case Progress 표시 | MetricStore, UI |

### Phase 2: 콘텐츠 통합 (1주)

| 작업 | 설명 |
|------|------|
| Case 1 Mystery 3종 JSON | `myst_01a`, `myst_01b`, `myst_01c` 데이터 작성 |
| 연동 Crisis 수정 | `the_slumbering_great_mind` Crisis의 `linked_mystery_id` 필드 추가 |
| Dungeon 연동 | `library_underground`, `astronomy_tower_basement`, `catacombs_depths`의 `unlock_by_mystery` 필드 추가 |
| 루이제 Mystery 반응 | Mystery 활성/해결 시 대사 분기 추가 |
| 테스트 플레이 | Case 1 전체 플로우 통과 테스트 |

### Phase 3: 밸런싱 (3일)

| 작업 | 설명 |
|------|------|
| 단서 수집 난이도 | `insight` 1~5 기준으로 `check_difficulty` 밸런싱 |
| 정화 횟수/파멸 토큰 | `cleanse_places` 유형의 적정 횟수 (3~5회) |
| 보스 처치 난이도 | `confrontation` 유형의 보스 스탯 및 전투 밸런스 |
| 방치 패널티 | `escalation.doom_if_ignored_days` 및 `warning_days` 템포 조정 |

---

## 9. 기존 시스템과의 차이점 요약

| 기존 시스템 | 미스터리 시스템 도입 후 변화 |
|------------|---------------------------|
| Case는 단순한 "퀘스트 ID" | Case가 Mystery 컨테이너가 됨. Mystery를 모두 해결해야 Case 클리어 |
| Crisis는 독립적 랜덤 이벤트 | Crisis가 Mystery와 연동됨. Mystery 진행 시 Crisis 약화, 방치 시 Crisis 강화 |
| Dungeon은 독립적 콘텐츠 | Dungeon이 Mystery의 단계적 목표가 됨. Mystery 해금 → 던전 개방 |
| Clue Token은 단순 재화 | Clue Token이 Mystery의 단계적 진행도가 됨. 3개 수집 = 단계 완료 |
| Doom Track은 전역 타이머 | Doom Track이 Mystery 방치 패널티와 직결. Mystery 해결 = 둠 감소 |
| NPC 대사는 고정 | NPC 대사가 Mystery 활성/진행/해결 상태에 따라 동적 분기 |

---

**문서 버전**: 1.0 (안)
**작성일**: 2026-05-26
**다음 단계**: 사용자 피드백 수렴 후 스키마 확정 및 Phase 1 구현 계획 수립
