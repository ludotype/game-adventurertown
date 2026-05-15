---
title: 모딩 가이드
description: 유저가 OC를 추가하기 위해 작성해야 할 JSON 형식 및 이미지 규격 가이드
category: Modding
type: Documentation
version: 1.0
created: 2026-04-17
last_updated: 2026-04-17
tags: [modding, oc, guide, json, community]
---

# 모딩 가이드 (Modding Guide)

## 1. 개요

GuildMaster는 커뮤니티가 직접 제작한 콘텐츠(OC - Original Character, 아이템, 이벤트)를 게임에 통합할 수 있는 **데이터 중심 모딩 시스템**을 제공합니다.

---

## 2. 모딩 폴더 구조

```
03-GM-Project/user_mods/
├── adventurers/           # 모험가 OC
│   ├── my_character/
│   │   ├── data.json      # 캐릭터 데이터
│   │   ├── portrait.png   # CG 일러스트 (512x768)
│   │   ├── sprite.png     # 타일맵 스프라이트 (32x32)
│   │   └── avatar.png     # UI 아바타 (64x64)
│   └── ...
│
├── npcs/                  # NPC OC
│   └── ...
│
├── items/                 # 커스텀 아이템
│   └── ...
│
├── events/                # 커스텀 이벤트
│   └── ...
│
└── manifest.json          # 모드 메타데이터
```

---

## 3. 캐릭터 OC 만들기

### 3.1. JSON 파일 구조

```json
{
  "_comment": "GuildMaster OC - 모험가 템플릿",
  "schema_version": "1.0",
  
  "basic_info": {
    "name": "캐릭터 이름",
    "author": "제작자 닉네임",
    "created_date": "2026-04-17",
    "description": "캐릭터에 대한 간단한 설명"
  },
  
  "appearance": {
    "portrait_file": "portrait.png",
    "sprite_file": "sprite.png",
    "avatar_file": "avatar.png",
    "color_theme": "#4A5568",
    "_note": "이미지는 위 경로에 실제 파일로 배치해야 함"
  },
  
  "personality": {
    "core_traits": ["무모한", "의리파"],
    "secondary_traits": ["허세부리는"],
    "special_traits": [],
    "intensity": {
      "무모한": 7,
      "의리파": 8,
      "허세부리는": 5
    }
  },
  
  "class": {
    "primary": "전사",
    "subclass": "버서커"
  },
  
  "base_stats": {
    "level": 1,
    "hp": 110,
    "mp": 40,
    "strength": 14,
    "agility": 8,
    "intelligence": 6,
    "luck": 5,
    "_note": "스탯 총합은 60-70 사이 권장"
  },
  
  "starting_equipment": {
    "weapon": {
      "name": "초보자의 검",
      "rarity": "common",
      "attack": 10
    },
    "armor": {
      "name": "가죽 갑옷",
      "rarity": "common",
      "defense": 5
    }
  },
  
  "backstory": "캐릭터의 배경 이야기 (최소 100자)",
  
  "dialogue_samples": {
    "greeting": "처음 인사말",
    "combat_start": "전투 시작 시 대사",
    "victory": "승리 시 대사",
    "defeat": "패배 시 대사",
    "retreat": "퇴각 시 대사"
  },
  
  "special_conditions": {
    "unlock_requirement": null,
    "starting_guild_reputation": 50
  }
}
```

### 3.2. 이미지 규격

| 용도 | 크기 | 포맷 | 투명도 | 비고 |
|------|------|------|--------|------|
| portrait (CG) | 512×768 | PNG | O | 캐릭터 감정 표현 |
| sprite | 32×32 또는 64×64 | PNG | O | 타일맵 이동용 |
| avatar | 64×64 | PNG | O | UI 표시용 |

#### 이미지 가이드라인
- **스타일**: 일관된 아트 스타일 권장 (애니메이션풍, 판타지)
- **portrait**: 상반신 또는 흉상, 배경은 단색 또는 투명
- **sprite**: 4방향(상하좌우) 또는 8방향 스프라이트 시트 권장
- **색상**: color_theme와 일치하는 포인트 색상 사용

### 3.3. 성향 태그 목록

#### 사용 가능한 태그
```json
{
  "core_traits": [
    "무모한(Reckless)",
    "신중한(Cautious)",
    "의리파(Loyal)",
    "기회주의자(Opportunist)",
    "탐욕스러운(Greedy)",
    "관대한(Generous)",
    "금사빠(Romantic)",
    "냉혈한(Cold-hearted)",
    "다정한(Warm)",
    "질투심강한(Jealous)",
    "대범한(Magnanimous)",
    "허세부리는(Braggart)",
    "겸손한(Humble)"
  ],
  "special_traits": [
    "불운한(Unlucky)",
    "재능있는(Talented)",
    "집착하는(Obsessive)",
    "방랑자(Wanderer)"
  ]
}
```

#### 태그 조합 규칙
- **core_traits**: 1~2개 선택 (필수)
- **secondary_traits**: 0~2개 선택 (선택)
- **special_traits**: 0~1개 선택 (희귀)
- **충돌 금지**: `무모한`과 `신중한`, `의리파`와 `기회주의자`는 동시 선택 불가

---

## 4. NPC OC 만들기

### 4.1. JSON 파일 구조

```json
{
  "_comment": "GuildMaster OC - NPC 템플릿",
  "schema_version": "1.0",
  "type": "NPC",
  
  "basic_info": {
    "name": "NPC 이름 (직함 포함 권장)",
    "author": "제작자",
    "npc_type": "MERCHANT",
    "npc_subtype": "WEAPON_DEALER"
  },
  
  "appearance": {
    "portrait_file": "portrait.png",
    "sprite_file": "sprite.png",
    "avatar_file": "avatar.png",
    "color_theme": "#D69E2E"
  },
  
  "shop_data": {
    "shop_name": "상점 이름",
    "operating_hours": {
      "open": "08:00",
      "close": "20:00"
    },
    "services": ["identify", "repair"],
    "item_categories": ["weapon", "armor"]
  },
  
  "personality": {
    "core_traits": ["실리적인", "수다쟁이"],
    "liked_adventurer_traits": ["신중한", "관대한"],
    "disliked_adventurer_traits": ["무모한"]
  },
  
  "dialogue": {
    "greetings": [
      "어서 오시게.",
      "오늘은 어떤 일로?"
    ],
    "gossip_topics": [
      "시장 동향",
      "모험가 소문"
    ]
  },
  
  "schedule": {
    "monday": [
      { "time": "08:00-20:00", "location": "shop", "activity": "OPEN" }
    ]
  },
  
  "backstory": "NPC의 배경 이야기"
}
```

### 4.2. NPC 타입별 필수 필드

| 타입 | 필수 필드 | 선택 필드 |
|------|-----------|-----------|
| MERCHANT | shop_name, item_categories, services | discount_policy, special_sales |
| FACILITY_MANAGER | facility_name, facility_type, services | operation_cost, facility_effects |
| QUEST_GIVER | quest_pool | unlock_conditions, reward_preferences |

---

## 5. 아이템 모드 만들기

### 5.1. JSON 구조

```json
{
  "item_id": "mod_item_001",
  "name": "커스텀 아이템 이름",
  "type": "WEAPON",
  "rarity": "rare",
  
  "stats": {
    "attack": 25,
    "critical_rate": 0.1
  },
  
  "effects": [
    {
      "type": "on_hit",
      "trigger": "combat_hit",
      "effect": "burn",
      "chance": 0.2,
      "duration": 3
    }
  ],
  
  "flavor_text": "아이템에 대한 설명",
  "author": "제작자",
  
  "visual": {
    "icon_file": "item_icon.png",
    "equip_sprite": "equip_sprite.png"
  }
}
```

---

## 6. 이벤트 모드 만들기

### 6.1. JSON 구조

```json
{
  "event_id": "mod_event_001",
  "name": "커스텀 이벤트",
  "type": "SOCIAL",
  
  "trigger_conditions": {
    "location": "tavern",
    "time": "evening",
    "required_traits": ["금사빠"],
    "min_party_size": 2
  },
  
  "scenes": [
    {
      "id": 1,
      "text": "장면 설명 텍스트",
      "choices": [
        {
          "text": "선택지 1",
          "effects": [
            { "target": "actor_a", "relationship_change": +10 }
          ],
          "next_scene": 2
        }
      ]
    }
  ],
  
  "outcomes": {
    "success": {
      "description": "성공 결과",
      "rewards": ["gold: 100"]
    },
    "failure": {
      "description": "실패 결과",
      "penalties": ["relationship_damage: 20"]
    }
  }
}
```

---

## 7. 매니페스트 파일 (manifest.json)

모드 폴더의 루트에 위치하는 메타데이터 파일입니다.

```json
{
  "mod_id": "my_guildmaster_mod",
  "name": "모드 이름",
  "version": "1.0.0",
  "author": "제작자 이름",
  "description": "모드 설명",
  
  "compatibility": {
    "game_version": ">=1.0.0",
    "required_mods": [],
    "incompatible_mods": []
  },
  
  "content": {
    "adventurers": ["adventurers/my_character"],
    "npcs": [],
    "items": [],
    "events": []
  },
  
  "config": {
    "enabled": true,
    "spawn_rate": 0.1,
    "unlock_condition": null
  }
}
```

---

## 8. 제출 및 공유

### 8.1. 로컬 테스트
```bash
# 모드 폴더를 user_mods/에 복사
# 게임 실행 → 설정 → 모드 → "My Mod" 확인
# 길드 관리 화면에서 OC 등장 확인
```

### 8.2. 커뮤니티 공유
```
1. 모드 폴더를 ZIP으로 압축
2. 공식 디스코드/포럼의 #oc-sharing 채널에 업로드
3. 템플릿에 따라 설명 작성:
   - OC 이름/컨셉
   - 성향 태그
   - 스크린샷
   - 설치 방법
```

### 8.3. 공식 채택 프로세스
```
1. 커뮤니티 투표 (2주)
2. 밸런스 팀 검토 (내부 테스트)
3. 아트/로어 검수
4. 다음 패치에 포함
```

---

## 9. 제약사항 및 가이드라인

### 9.1. 금지 사항
- 저작권 침해 콘텐츠 (타 게임/미디어 직접 복사)
- 부적절한 콘텐츠 (성적/폭력적/혐오 표현)
- 현실 인물 명예훼손
- 과도한 밸런스 붕괴 (스탯 조작 등)

### 9.2. 권장 사항
- 게임 세계관과의 일관성
- 다른 OC와의 관계 가능성 열어두기
- 적절한 밸런스 (너무 강/약하지 않게)
- 고유한 캐릭터성

### 9.3. 밸런스 체크리스트
```
□ 스탯 총합이 60-70 범위인가?
□ 성향 태그가 1-4개인가?
□ 초기 장비가 레어 이상이 아닌가?
□ 특수 능력이 없거나 게임 내 시스템을 사용하는가?
□ 관계도가 비어있거나 적절히 초기화되는가?
```

---

## 10. 샘플 파일 제공

### 10.1. 최소 OC 예시
```json
{
  "basic_info": {
    "name": "엘라",
    "author": "NewbieModder"
  },
  "appearance": {
    "portrait_file": "ella_portrait.png",
    "color_theme": "#E53E3E"
  },
  "personality": {
    "core_traits": ["신중한", "다정한"]
  },
  "class": {
    "primary": "마법사"
  },
  "base_stats": {
    "level": 1,
    "hp": 80,
    "mp": 100,
    "strength": 4,
    "agility": 7,
    "intelligence": 15,
    "luck": 6
  },
  "backstory": "마을의 약초상 딸로 자라 마법에 재능을 보여 길드에 합류했다."
}
```

### 10.2. 고급 OC 예시
```json
{
  "basic_info": {
    "name": "제로드 아케인",
    "author": "ProModder",
    "description": "전설의 마검사를 목표로 하는 자"
  },
  "appearance": {
    "portrait_file": "zerod_portrait.png",
    "sprite_file": "zerod_sprite.png",
    "avatar_file": "zerod_avatar.png",
    "color_theme": "#805AD5"
  },
  "personality": {
    "core_traits": ["집착하는", "냉혈한"],
    "secondary_traits": ["허세부리는"],
    "intensity": {
      "집착하는": 9,
      "냉혈한": 7,
      "허세부리는": 6
    }
  },
  "class": {
    "primary": "다크나이트",
    "subclass": "소울리퍼"
  },
  "base_stats": {
    "level": 5,
    "hp": 130,
    "mp": 60,
    "strength": 14,
    "agility": 10,
    "intelligence": 12,
    "luck": 4
  },
  "starting_equipment": {
    "weapon": {
      "name": "실낙원의 검",
      "rarity": "rare",
      "attack": 35
    }
  },
  "backstory": "한때 명문 기사단장이었으나, 사랑하는 사람을 구하지 못한 죄책감에 타락했다. 이제는 전설의 마검을 손에 넣어 그녀를 되살리겠다는 일념으로 던전을 누빈다.",
  "dialogue_samples": {
    "combat_start": "내 검에 영혼을 바쳐라.",
    "victory": "한 걸음 더 가까워졌다.",
    "retreat": "...지금은 후퇴한다."
  },
  "special_conditions": {
    "unlock_requirement": "complete_dungeon: forgotten_temple",
    "starting_guild_reputation": 30
  }
}
```

---

## 11. 도구 및 리소스

### 11.1. 검증 도구
```bash
# JSON 스키마 검증
python tools/validate_mod.py user_mods/my_mod/

# 밸런스 검사
python tools/check_balance.py user_mods/my_mod/adventurers/

# 이미지 크기 검증
python tools/check_images.py user_mods/my_mod/
```

### 11.2. 참고 자료
- `Template_Adventurer.md`: 전체 데이터 스키마
- `Relationship_Calculation_Table.md`: 성향 태그 상호작용
- 공식 Discord: #modding-help 채널
