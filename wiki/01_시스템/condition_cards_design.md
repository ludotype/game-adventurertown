# 상태 카드 (Condition Cards) 시스템 설계서

> 이 문서는 고대 도시 **나틀락 (Natlach)**에서 벌어지는 코스믹 호러 탐험 중 획득하게 되는 **상태 카드(Condition Cards)**의 참조 자료 분석 및 게임 내 자체 카드 설계 사양서입니다.
> **핵심 사양**: 기획 피벗 사양(`new_direction.md`)에 따라 기존의 수치형 정신력(Sanity)을 100% 대체하며, 덱 빌딩 로그라이트의 묘미를 살려 플레이어와 NPA에게 지속적인 디버프/버프 및 게임 플레이의 전술적 변수를 제공합니다.

---

## 1. 참고 자료 (Reference): 아캄/엘드리치 호러의 상태 카드 분석

본 기획은 판타지 플라이트 게임즈(FFG)의 크툴루 신화 보드게임군인 **엘드리치 호러 (Eldritch Horror)** 및 **아캄 호러 (Arkham Horror LCG)**의 핵심 상태 카드 메커니즘을 벤치마킹하여 설계되었습니다.

### 1.1 엘드리치 호러 (Eldritch Horror) 상태 카드 체계
엘드리치 호러의 상태 카드는 **양면(Double-Sided)** 구조와 **응징(Reckoning)** 이라는 강력한 격발 메커니즘을 지니고 있습니다.

1.  **정신이상 상태 (Insanity / Mental Damage)**:
    *   **편집증 (Paranoia)**: 동료를 신뢰할 수 없게 됨. (응징 격발 시: 자산이나 아이템을 잃거나 동료와 불화 발생)
    *   **환각 (Hallucinations)**: 허상을 봄. (응징 격발 시: 환각에 굴복하여 자신의 체력/정신력을 깎거나 몬스터와 조우 처리)
    *   **기억상실 (Amnesia)**: 자신의 과거를 잊음. (응징 격발 시: 획득한 단서 토큰이나 마법 스펠 카드를 망각하여 상실)
2.  **신체 부상 상태 (Injury / Physical Damage)**:
    *   **다리 부상 (Leg Injury)**: 이동 제약. (체력 판정 실패 시 뒤집혀 심각한 골절 및 이동 불가 적용)
    *   **내상 (Internal Injury)**: 신체 내부 출혈. (응징 격발 시마다 체력 지속 감소)
3.  **초자연적 계약 및 영적 상태 (Deals & Boon/Bane)**:
    *   **어둠의 계약 (Dark Pact)**: 고대 어둠의 존재와 거래를 맺음. (자정마다 주사위를 굴려 1이 나오면 뒤집힘 → **강제 즉사** 또는 **파멸 게이지 대량 증가**로 연결)
    *   **부채 (Debt)**: 소지금 대출. (자정에 채권자가 찾아와 판정 진행, 실패 시 감옥 갇힘 또는 신체 포기 계약서 적용)
    *   **축복받은 (Blessed)**: 모든 판정에서 주사위 성공 확률 비약적 상승.
    *   **저주받은 (Cursed)**: 모든 판정에서 성공 확률 비약적 하락. (축복과 저주는 양립 불가, 획득 시 서로 상쇄됨)

### 1.2 아캄 호러 LCG (Arkham Horror LCG) 약점(Weakness) 카드 체계
아캄 호러 LCG는 덱에서 직접 드로우되는 **기본 약점(Basic Weaknesses)** 카드들을 통해 플레이어의 행동을 직접 강제합니다.

1.  **정신적 트라우마 사건**:
    *   **조현병 (Schizophrenia)**: 다중인격 발현. 드로우 시 손에 들고 있는 카드 크기나 자원을 버리거나 행동력 소모.
    *   **시간 상실 (Lost in Time and Space)**: 차원의 틈새로 빨려 들어감. 1턴 동안 물리적인 모든 조작 불가.
2.  **집착 및 지속 행동 방해**:
    *   **과잉보호 (Overzealous)**: 무모하게 행동하려 함. 신화 단계에서 조우 카드를 강제로 추가 드로우.
    *   **크로노포비아 (Chronophobia)**: 시간 강박증. 매 라운드 종료 시 행동(Action)을 소모해 카드를 버리지 않으면 지속 공포 획득.
    *   **완벽주의 (Kleptomania)**: 도벽 증세. 특정 장소 수색에 성공해도 아이템을 가로채거나 잃어버리는 불이익 적용.

---

## 2. 나틀락 (Natlach) 게임 상태 카드 설계

참고 자료의 훌륭한 시스템을 이식하여, 나틀락 도시와 유적 지하 심연에서 작동할 **3대 상태 카드 계열**을 설계합니다.

```
┌────────────────────────────────────────────────────────┐
│  나틀락 상태 카드 시스템 (Condition Cards)               │
├────────────────────────────────────────────────────────┤
│  1. 정신 이상 계열 (Insanity)                           │
│     - 환각 (Hallucinations)   - 편집증 (Paranoia)       │
│     - 기억상실 (Amnesia)      - 우울증 (Melancholy)     │
│  2. 신체 부상 계열 (Injury)                             │
│     - 출혈 (Bleeding)         - 다리 골절 (Fractured)   │
│     - 뇌진탕 (Concussion)                               │
│  3. 영적 및 초자연 계열 (Supernatural/Deals)           │
│     - 어둠의 계약 (Dark Pact) - 저주받은 (Cursed)       │
│     - 축복받은 (Blessed)                                │
└────────────────────────────────────────────────────────┘
```

### 2.1 정신 이상 상태 카드 (Mental / Insanity) — 정신력(Sanity) 대체

#### A. 환각 (Hallucinations)
- **효과**: 
  - 플레이어: 대화 씬 진행 시 글자들이 물결치며 헛소리가 기습적으로 섞여 나옵니다. (예: `[wave amp=30 freq=3]보라색 거미가 춤춘다...[/wave]`). 또한 장소 이동 시 15% 확률로 엉뚱한 장소로 강제 워프됩니다.
  - NPA: 자정마다 10% 확률로 조건(HP 등)을 무시하고 자율적으로 유적 던전으로 방황하며 떠납니다.
- **제거 방법**: 꽃집에서 `진정제 꽃잎(Flower Petal Tea)`을 사서 복용하거나 치료소의 **엘레나 (Elena)**에게 `정신 정화` 시술을 받습니다.

#### B. 편집증 (Paranoia)
- **효과**: 
  - 플레이어: NPA와의 단서 교환(`request_clue`) 시 요구되는 신뢰도(Trust) 장벽이 2배로 상승합니다.
  - NPA: 플레이어와의 대화를 거부하며, 밤이 되면 구석에 숨어 조우가 불가능해집니다.
- **제거 방법**: 치료소의 엘레나와 장기 심리 상담을 받거나 주점에서 술을 대량 구매하여 NPA들과 나누어 마십니다.

#### C. 기억상실 (Amnesia)
- **효과**:
  - 매일 자정 단계(Midnight Phase)가 될 때마다 소지하고 있는 **단서 토큰(Clue Tokens)을 무조건 1개씩 망각하여 소멸**시킵니다.
- **제거 방법**: 여관방에서 2일간 아무것도 하지 않고 순수하게 수면을 취해 뇌 세포를 안정시킵니다.

#### D. 우울증 (Melancholy)
- **효과**:
  - 여관방이나 치료소에서 휴식 취하기 행동 시 획득하는 HP 및 스태미나 회복 효율이 반감(50%)됩니다.
- **제거 방법**: 주점에서 NPA들과 함께 골드를 소비하여 파티를 벌이거나 특정 돌발 긍정 이벤트를 마주합니다.

---

### 2.2 신체 부상 상태 카드 (Physical / Injury) — 물리 생존 제약

#### A. 출혈 (Bleeding)
- **효과**:
  - 플레이어: 장소를 이동하거나 대화/수색 행동(AP 소소)을 할 때마다 HP가 5씩 지속적으로 하락합니다.
  - NPA: 자정마다 HP가 15씩 지속 누적 하락하여 사망 위험이 극대화됩니다.
- **제거 방법**: 치료소에서 치료를 받거나 약초꾼에게서 `지혈대(Bandage)` 혹은 `치료 약초(Healing Herb)`를 구매해 자가 지혈합니다.

#### B. 다리 골절 (Fractured Leg)
- **효과**:
  - 도시 내 장소 이동 시 기본으로 소모되는 행동력(AP) 또는 이동력(Movement) 수치가 **2배로 증가**합니다. (예: 1 AP 소모 골목길 이동이 2 AP 소모로 변경)
- **제거 방법**: 치료소 엘레나에게서 골절 접합 치료 수술을 받거나 여관방에서 3일간 요양합니다.

#### C. 뇌진탕 (Concussion)
- **효과**:
  - 던전이나 퀘스트 도중 수행되는 모든 능력치 판정(Attribute Check) 주사위 굴림의 **목표 난이도(Difficulty Check)가 +2 증가**합니다. 또한 유적 내 고대 비문 텍스트가 깨져서 표시됩니다.
- **제거 방법**: 24시간 동안 유적 탐사를 정지하고 마을에서 가벼운 휴식을 취합니다.

---

### 2.3 초자연적 및 영적 상태 카드 (Supernatural / Deal) — 파멸과의 거래

#### A. 어둠의 계약 (Dark Pact)
- **효과 (응징/Reckoning)**:
  - 매일 자정 단계가 시작될 때마다 숨겨진 운명의 주사위(D6)를 굴립니다. **주사위 눈이 1이 나올 경우, 계약서 카드가 뒤집히며(Flipped) 즉시 최대 HP의 50%가 소멸**하거나, 현재 위치에 강력한 심연의 암살자 몬스터가 소환되어 기습합니다.
- **획득 경로**: 유적 속 검은 비석과 속삭이거나, 죽어가는 의문의 신도에게 피로 계약서를 넘겨받을 시 획득.
- **제거 방법**: 신관 **렐리아나 (Relliana)**에게 단서 토큰 3개를 제공하고 강력한 `성화 해제 의식`을 진행하여 영혼을 해방합니다.

#### B. 저주받은 (Cursed)
- **효과**:
  - 전투 판정 및 사건 판정 시, 1이나 2가 나오면 무조건 자동 대실패(Fumble) 처리되며 공격력이 20% 하락합니다. (Blessed 획득 시 자동 상쇄되어 소멸)
- **제거 방법**: 치료소 옆 예배당 성수대에서 `성수(Holy Water)`를 받아 전신을 정화합니다.

#### C. 축복받은 (Blessed)
- **효과 (버프)**:
  - 전투 판정 및 사건 판정 시 성공 확률이 20% 상승하며, 주사위 보너스 +2를 가산받습니다. (Cursed 획득 시 자동 상쇄되어 소멸)
- **제거 방법**: 플레이어 혹은 NPA가 어떠한 경로로든 몬스터에게 물리적 타격을 입어 대미지를 입으면 축복 상태가 깨져 소멸합니다.

---

## 3. 인게임 데이터 모델 및 연동 메커니즘

### 3.1 JSON 데이터 정의 — `data/conditions/{condition_id}.json`

```json
{
  "condition_id": "hallucinations",
  "display_name": "환각",
  "type": "mental",
  "is_negative": true,
  "description": "보라색 안개와 환청이 현실을 왜곡합니다. 글씨가 물결치고 엉뚱한 곳으로 방황합니다.",
  "reckoning_on_midnight": {
    "probability": 0.15,
    "action": {
      "type": "teleport_random",
      "dialogue_id": "hallucination_whisper"
    }
  },
  "dialogue_modifiers": {
    "speech_prefix": "[wave amp=30 freq=3]",
    "speech_suffix": "[/wave]"
  }
}
```

### 3.2 정적 NPC 치료소 연동 코드 (GDScript 의사코드)

```gdscript
# scripts/state/condition_manager.gd
extends Node

# 현재 액터(플레이어 혹은 NPA)들이 보유한 상태 카드 맵: { actor_id: Array[String] }
var active_conditions: Dictionary = {}

func add_condition(actor_id: String, condition_id: String) -> void:
	if not active_conditions.has(actor_id):
		active_conditions[actor_id] = []
	
	if condition_id in active_conditions[actor_id]:
		return # 중복 카드 소유 불가
		
	# 상쇄 로직 (Blessed <-> Cursed)
	if condition_id == "blessed" and "cursed" in active_conditions[actor_id]:
		active_conditions[actor_id].erase("cursed")
		return
	if condition_id == "cursed" and "blessed" in active_conditions[actor_id]:
		active_conditions[actor_id].erase("blessed")
		return
		
	active_conditions[actor_id].append(condition_id)
	print("Condition added to: ", actor_id, " -> ", condition_id)

func remove_condition(actor_id: String, condition_id: String) -> void:
	if active_conditions.has(actor_id) and condition_id in active_conditions[actor_id]:
		active_conditions[actor_id].erase(condition_id)
		print("Condition removed from: ", actor_id, " -> ", condition_id)
```

---

*문서 버전: 1.0*  
*최종 업데이트: 2026-05-24 by Antigravity*
