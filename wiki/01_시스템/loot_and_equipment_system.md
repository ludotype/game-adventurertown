# Loot & Equipment System Design

> 이 문서는 Loop Hero의 메카닉에서 영감을 받아, Natlach 프로젝트의 장비 및 루트 시스템을 설계합니다.
> 기획자는 `data/items/`와 `data/loot_tables/`의 JSON 파일만 수정하면 됩니다.

---

## 1. 아이템 타입 (Item Types)

Loop Hero처럼 슬롯 기반 장비 시스템을 도입합니다.

| 슬롯 | 타입 (category) | 설명 |
|------|----------------|------|
| 주무기 | `weapon` | 근접/원거리 무기 |
| 보조장비 | `offhand` | 방패, 랜턴, 의식용 단검 등 |
| 방어구 | `armor` | 갑옷, 코트, 로브 |
| 장신구1 | `ring` | 반지 |
| 장신구2 | `amulet` | 부적, 목걸이 |
| 소비품 | `consumable` | 물약, 음식 |
| 재료 | `material` | 조합/강화용 |
| 특수 | `relic` | 고대 유물 (캠프 효과) |

---

## 2. 등급 시스템 (Rarity & Item Points)

Loop Hero의 "Item Points" 메카닉을 적용합니다.

### 2.1 등급
| 등급 | 색상 | 속성 개수 | 용도 |
|------|------|----------|------|
| Common (Grey) | 회색 | 1개 | 단일 스탯 극대화 |
| Magic (Blue) | 파랑 | 2개 | 2가지 스탯 조합 |
| Rare (Gold) | 금색 | 3개 | 빌드 다양화 |
| Eldritch (Orange) | 주황 | 4개 | 전설급, 높은 총 포인트 |

### 2.2 Item Points 계산
```
Base Points = (던전 계수 x 난이도 보정)
Rarity Multiplier = Common(1.0) / Magic(1.5) / Rare(2.0) / Eldritch(2.5)
Total Points = Base Points x Rarity Multiplier

각 속성에 랜덤 분배 (주요 속성에 가중치)
```

---

## 3. 루트 생성 알고리즘 (Loot Generation)

### 3.1 몬스터 기반 드롭
```
1. 몬스터가 가진 loot_chance (%)로 아이템 드롭 여부 판정
2. minimum_loot가 1 이상이면 최소 1개는 무조건 드롭
3. 드롭 결정 후:
   - 아이템 타입 가중치로 슬롯 결정 (예: 전사형 몬스터는 weapon 가중치 증가)
   - 등급 롤 (테이블 기반)
   - 아이템 레벨 = 현재 던전 레벨 x (0.8 ~ 1.2 랜덤)
   - Item Points를 속성에 분배하여 최종 아이템 생성
```

### 3.2 몬스터별 특수 수정자 (Signature Drops)
특정 몬스터/적은 특정 속성을 높은 확률로 가진 아이템을 드롭합니다.

| 적 유형 | 시그니처 속성 | 확률 |
|---------|-------------|------|
| 피의 사교도 | Vampirism (흡혈) | ~30% |
| 구울/좀비 | Poison (독) | ~25% |
| 고대 수호자 | Defense (방어) | ~20% |
| 그림자 정령 | Evasion (회피) | ~20% |

---

## 4. JSON 데이터 구조

### 4.1 아이템 베이스 (`data/items/{item_id}.json`)
```json
{
  "item_id": "rusty_sword",
  "display_name": "녹슨 검",
  "category": "weapon",
  "equippable": true,
  "slot": "weapon",
  "icon_path": "res://assets/icons/rusty_sword.png",
  "max_stack": 1,
  "base_stats": {
    "attack": 3
  },
  "possible_prefixes": ["sharp", "cursed", "blessed"],
  "possible_suffixes": ["of_the_abyss", "of_vampirism"]
}
```

### 4.2 루트 테이블 (`data/loot_tables/{table_id}.json`)
```json
{
  "table_id": "sewer_rats",
  "entries": [
    { "type": "item", "item_id": "rusty_sword", "weight": 30, "rarity_roll": true },
    { "type": "item", "item_id": "rat_fang", "weight": 40, "rarity_roll": false },
    { "type": "empty", "weight": 30, "message": "아무것도 찾지 못했다." }
  ],
  "monster_level": 2,
  "signature_mod": { "stat": "poison", "chance": 0.25 }
}
```

### 4.3 전리품 테이블 아이템 생성 규칙
```json
{
  "table_id": "elder_guardian",
  "loot_chance": 0.85,
  "min_loot": 1,
  "item_type_weights": {
    "weapon": 40,
    "armor": 30,
    "ring": 15,
    "amulet": 15
  },
  "rarity_weights": {
    "common": 50,
    "magic": 30,
    "rare": 15,
    "eldritch": 5
  },
  "level_range": [0.8, 1.2],
  "signature_mod": { "stat": "defense", "chance": 0.20 }
}
```

---

## 5. 플래너 워크플로우

### 새 장비 추가
1. `data/items/`에 베이스 아이템 JSON 생성
2. `data/loot_tables/`에 드롭 규칙 추가 (또는 기존 테이블에 weight 추가)
3. 필요시 `signature_mod`로 몬스터 특성 연결

### 밸런스 조정
- `loot_chance`: 드롭 빈도
- `rarity_weights`: 등급 분포
- `item_type_weights`: 클래스별 드롭 편중
- `level_range`: 아이템 레벨 변동폭

---

## 6. 관련 시스템 연동

- **인벤토리**: `InventoryGridPanel`에서 장착/해제
- **ActionRunner**: `random_loot`, `add_item`, `equip_item` 액션 사용
- **Condition Cards**: 특정 장비는 상태 카드 면역/취약성 제공 가능 (향후 확장)
