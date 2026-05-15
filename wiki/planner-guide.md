# Planner Guide - NPC 등장 시스템

> 이 문서는 프로그래머가 아닌 기획자/디자이너를 위한 가이드입니다.
> JSON 파일만 수정하면 NPC 등장 규칙을 변경할 수 있습니다.

---

## 개요

각 장소(Place)에 들어갈 때, 해당 장소에 **랜덤으로 NPC 1명**이 등장하거나 **아무도 없을** 수 있습니다.

모든 확률은 **가중치(Weight)** 시스템으로 계산됩니다. 각 NPC마다 가중치 숫자를 부여하면, 시스템이 자동으로 "이 장소에서 누가 얼마나 자주 등장하는지"를 계산해줍니다.

**핵심 원칙:** `data/npc_schedules/` 폴더에 JSON 파일을 추가·제거만 하면 됩니다. 어떤 중앙 파일도 수정할 필요가 없어요.

---

## 1. 장소 설정 (`data/places/`)

각 장소마다 하나의 JSON 파일이 있습니다.

### 파일 예시: `town_square.json`

```json
{
  "place_id": "town_square",
  "display_name": "중앙 광장",
  "background_path": "res://assets/bg/town_square.png",
  "bgm": "town_day",
  "empty_weight": 8
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

---

## 2. NPC 스케줄 (`data/npc_schedules/`)

각 NPC마다 하나의 JSON 파일이 있습니다. 이 파일에 "어떤 장소에 언제 등장 가능한지"를 적습니다.

### 파일 예시: `elena.json`

```json
{
  "npc_id": "elena",
  "display_name": "엘레나",
  "default_portrait": "res://assets/portraits/elena.png",
  "schedules": [
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
| `default_portrait` | 대화창에 표시될 초상화 파일 경로 |
| `schedules` | 등장 규칙 배열 (하나의 NPC가 여러 장소에 등장 가능) |
| `schedules[].place_id` | 등장할 장소 ID |
| `schedules[].weight` | 이 장소에서의 추첨 가중치 |
| `schedules[].conditions` | 등장 조건 (선택사항) |
| `schedules[].conditions.time_of_day` | 가능한 시간대 배열 (`morning`, `afternoon`, `evening`, `night`) |
| `schedules[].conditions.story_flags` | 필요한 스토리 플래그 배열 (선택사항) |

---

## 3. 확률 계산 방식 (가중치 시스템)

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
| 길드 접수원 | 5 | 5 / 23 | **21.7%** |
| **총합** | **23** | | **100%** |

- 엘레나는 `time_of_day: ["morning", "afternoon"]` 조건을 만족 → 참여
- 록은 `time_of_day: ["afternoon"]` 조건 불만족 → 제외

---

## 4. `empty_weight` 활용 가이드

`empty_weight`는 **이 장소가 얼마나 한산한지**를 조절하는 값입니다.

| 상황 | 추천 `empty_weight` | 느낌 |
|------|-------------------|------|
| 사람 많은 광장 | 8 ~ 12 | 종종 비어있음, 종종 사람 있음 |
| 심야의 뒷골목 | 20 ~ 30 | 대부분 비어있음. 드물게 의문의 인물 |
| 길드 접수처 | 0 | **항상** 누군가 배치됨 |
| 밤의 선술집 | 2 ~ 4 | 거의 항상 주인이나 단골이 있음 |

`empty_weight = 0`이면, 등장 가능한 NPC가 1명 이상 있다는 가정 하에 **무조건 NPC가 표시**됩니다.

---

## 5. 작업 흐름

### 새로운 NPC 추가하기

1. `data/npc_schedules/` 폴더에 `{npc_id}.json` 파일을 새로 만듭니다.
2. `place_id`, `weight`, `conditions`를 작성합니다.
3. **끝입니다.** 어떤 장소 스크립트도 수정할 필요가 없습니다.

### 새로운 장소 추가하기

1. `data/places/` 폴더에 `{place_id}.json` 파일을 새로 만듭니다.
2. `background_path`와 `empty_weight`를 지정합니다.
3. 기존 NPC 스케줄에 이 장소의 `place_id`를 추가하면 NPC가 거기에도 등장합니다.

### NPC가 특정 장소에서 더 자주 등장하게 하기

- 해당 NPC의 JSON 파일에서 그 장소의 `weight` 값을 올립니다.
- 다른 NPC의 `weight`를 내릴 필요는 없습니다. 총합 비율이 자동으로 재계산되니까요.

---

## 6. 파일 위치 요약

```
project/guild-master/
├── data/places/          ← 장소 설정
├── data/npc_schedules/   ← NPC 등장 규칙
├── scripts/systems/      ← 시스템 코드 (직접 수정 불필요)
└── scripts/game/         ← 게임 로직 코드 (직접 수정 불필요)
```
