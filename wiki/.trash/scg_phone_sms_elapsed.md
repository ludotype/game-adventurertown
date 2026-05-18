# SCG·전화·SMS 마지막 시각 및 elapsed 조건 가이드

본 문서는 트리거 JSON과 스토리 스크립트에서 **마지막 표시·대화 시각**을 활용하는 방법을 정리한다.

---

## 1. 자동으로 갱신되는 전역 변수

게임 시간 축은 **`total_minutes`**와 동일한 값이 `UserManager` 전역 변수 `total_minutes`에 들어 있다.

아래 변수들은 **코드에서 자동 갱신**된다. 스크립트로 매 이벤트마다 넣을 필요가 없다.

| 변수 키 패턴 | 갱신 시점 |
|--------------|-----------|
| `scg.last_seen.{npc}` | 스토리에서 `character seha.…`처럼 **메인 NPC CG**가 화면에 표시될 때 |
| `phone.last_seen.{npc}` | `character call.portrait.{npc}…` (예: `call.portrait.seha1`)가 표시될 때 |
| `sms.last_seen.{npc}` | `character sms.portrait.{npc}…` (예: `sms.portrait.noru1`)가 표시될 때 |

**`{npc}`**는 현재 다음 다섯 명만 대상이다: `seha`, `noru`, `taemin`, `junho`, `yujin`.

**예:** `character call.portrait.seha1` → `phone.last_seen.seha`에 현재 `total_minutes` 저장.

---

## 2. 트리거 JSON용 — `elapsed` 연산자

`event_triggers.json`, `incomingcall_triggers.json`, `outgoingcall_triggers.json`의 이벤트 **`conditions`** 배열에서만 아래 연산자를 사용한다. (스토리 `if` 문법과는 별개다.)

### 2.1 공통 형식

```json
{ "key": "<마지막 시각이 들어 있는 전역 키>", "op": "<elapsed 연산자>", "value": "<분, 정수 또는 다른 키>" }
```

`value`는 기존 트리거와 같이 **숫자 문자열**이거나, **다른 전역 변수 이름**이면 그 값으로 치환된다.

### 2.2 지원 연산자

| op | 의미 |
|----|------|
| `elapsed>=` | (현재 `total_minutes` − `key`에 저장된 시각) **≥** `value` 분 |
| `elapsed>` | **>** |
| `elapsed<=` | **≤** |
| `elapsed<` | **<** |
| `elapsed==` | **==** |
| `elapsed!=` | **!=** |

### 2.3 `key`에 기록이 없을 때

`key`가 없거나 숫자가 아니면 **“오래 전”**으로 간주한다.

- `elapsed>=`, `elapsed>` → **통과(true)**  
  (기존 세이브 등에서 기록이 없어도 이벤트가 막히지 않게 하기 위함.)
- `elapsed<=`, `elapsed<`, `elapsed==` 등 → 기록 없음은 **큰 경과**로 취급되어, 상한 조건은 보통 **실패**에 가깝게 동작한다.

### 2.4 JSON 예시

**세하 CG를 본 뒤 최소 30분이 지난 뒤에만 조건 충족**

```json
{ "key": "scg.last_seen.seha", "op": "elapsed>=", "value": "30" }
```

**세하에게 수신 전화 UI(초상)가 뜬 뒤 60분 이후에만**

```json
{ "key": "phone.last_seen.seha", "op": "elapsed>=", "value": "60" }
```

**노루 SMS 초상이 뜬 뒤 45분 이내에만** (직후 한정 이벤트 등)

```json
{ "key": "sms.last_seen.noru", "op": "elapsed<=", "value": "45" }
```

**여러 줄 AND:** `conditions` 배열에 위 객체들을 나란히 넣으면 된다.

---

## 3. 스크립트용 — `elapsed` 연산자는 쓰지 않는다

`elapsed>=` 같은 문자열은 **트리거 JSON 전용**이다. 스토리 `if` 등에서는 쓰이지 않는다.

대신 **`total_minutes`**와 **`scg.last_seen.*` / `phone.last_seen.*` / `sms.last_seen.*`** 숫자를 빼서 비교한다.

### 3.1 경과 분을 변수에 넣기 (`calculate`)

프로젝트에 이미 있는 `calculate` 명령으로 차이를 구한다.

```text
calculate seha_scg_elapsed {global.total_minutes} - {global.scg.last_seen.seha}
```

전화·SMS도 동일 패턴이다.

```text
calculate seha_phone_elapsed {global.total_minutes} - {global.phone.last_seen.seha}
```

```text
calculate noru_sms_elapsed {global.total_minutes} - {global.sms.last_seen.noru}
```

**주의:** `scg.last_seen.seha` 등이 아직 없으면 스토리 쪽 변수 치환 규칙상 **0에 가깝게 잡힐 수 있어** 경과가 크게 나온다. 분기가 민감하면 `if`로 “키 존재 여부”를 먼저 두거나, 트리거 쪽은 JSON `elapsed`로 처리하는 편이 안전하다.

### 3.2 마지막 시각을 직접 덮어쓰기 (`variable`)

스크립트에서 임의로 타임스탬프를 찍을 때는 기존과 같이 `variable` 한 줄로 쓴다.

```text
{global.phone.last_seen.seha}={global.total_minutes}
```

```text
{global.sms.last_seen.noru}={global.total_minutes}
```

자동 추적과 중복되면 **나중에 실행된 값이 남는다.** 보통은 통화/SMS 스크립트 끝에 수동 줄을 넣지 않아도 된다.

---

## 4. 한 줄 요약

- **CG·수신 전화 초상·SMS 초상**이 뜨면 각각 `scg.last_seen.*`, `phone.last_seen.*`, `sms.last_seen.*`가 갱신된다.
- **JSON 트리거**에서는 `elapsed>=` 등으로 “그 시각 이후 N분”을 조건에 넣는다.
- **스토리**에서는 `calculate`로 `total_minutes − last_seen`을 구한 뒤, 기존 방식으로 숫자 비교한다.
