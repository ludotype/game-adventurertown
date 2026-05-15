---
title: 모험가 템플릿
description: 성격, 관계도, 장비, 과거 로그를 포함한 YAML 스키마
category: Entities
type: Data Template
version: 1.0
created: 2026-04-17
last_updated: 2026-04-17
tags: [adventurer, entity, yaml, schema, template]
---

# 모험가 템플릿 (Template: Adventurer)

## 1. 개요

모험가(Entity: Adventurer)는 GuildMaster의 핵심 게임 요소입니다. 각 모험가는 고유한 성격, 관계, 과거 로그를 가지며, 데이터 중심의 YAML 스키마로 정의됩니다.

---

## 2. YAML 스키마

```yaml
# ============================================================
# 모험가 기본 정보 (Basic Info)
# ============================================================
adventurer:
  # --- 필수 필드 ---
  id: "adv_001"                    # 고유 식별자 (adv_ 접두사)
  name: "크로우 리버스"             # 캐릭터 이름
  created_at: "2026-04-17"         # 생성 날짜
  version: 1                       # 데이터 버전
  
  # --- 외형 ---
  appearance:
    portrait: "portrait_crow.png"  # CG 일러스트 파일명
    sprite: "sprite_crow.png"      # 타일맵용 스프라이트
    avatar: "avatar_crow.png"      # UI용 아바타
    color_theme: "#4A5568"         # UI 강조색
    
  # --- 기본 속성 ---
  base_stats:
    level: 1
    hp: 100
    mp: 50
    strength: 12
    agility: 10
    intelligence: 8
    luck: 5
    
  class:
    primary: "전사"                 # 직업
    subclass: "버서커"              # 부직업 (선택)
    
  # ============================================================
  # 성격 시스템 (Personality System)
  # ============================================================
  personality:
    # --- 핵심 성향 (1-2개 권장) ---
    core_traits:
      - "무모한(Reckless)"
      - "의리파(Loyal)"
    
    # --- 보조 성향 (0-2개) ---
    secondary_traits:
      - "허세부리는(Braggart)"
    
    # --- 특수 성향 (0-1개, 희귀) ---
    special_traits:
      - "재능있는(Talented)"
    
    # --- 성향 강도 (1-10) ---
    trait_intensity:
      무모한: 8
      의리파: 7
      허세부리는: 5
      
    # --- 성격 설명 ---
    description: |
      전장의 화신. 동료를 위해 몸을 아끼지 않지만,
      때로는 무모한 돌진으로 파티를 위기에 빠뜨리기도 한다.
      승리 후에는 반드시 술집에서 허세를 부린다.
      
  # ============================================================
  # 관계도 (Relationship Web)
  # ============================================================
  relationships:
    # --- 길드 충성도 ---
    guild_loyalty: 65              # 0-100 (낮으면 방랑자 성향)
    
    # --- 개별 관계 (동적 생성) ---
    with_others:
      - target_id: "adv_002"        # 상대방 ID
        target_name: "미아 송"
        score: 45                   # 호감도 (-100 ~ +100)
        status: "친밀"               # 상태: 적대/불편/중립/친구/친밀/연인/영혼의동반자
        history:
          - { date: "2026-04-15", event: "위기구출", change: +20 }
          - { date: "2026-04-16", event: "말다툼", change: -5 }
          - { date: "2026-04-17", event: "전투승리", change: +10 }
        last_interaction: "2026-04-17"
        
      - target_id: "adv_003"
        target_name: "잭 스파로우"
        score: -30
        status: "불편"
        history:
          - { date: "2026-04-14", event: "전리품다툼", change: -20 }
          - { date: "2026-04-16", event: "말다툼", change: -10 }
        known_conflicts: ["전리품분배", "전략이견"]
        
    # --- 특수 관계 임계값 플래그 ---
    flags:
      has_rival: true               # 라이벌 존재
      rival_id: "adv_003"
      has_lover: false
      has_mentor: false
      has_student: false
      
  # ============================================================
  # 장비 (Equipment)
  # ============================================================
  equipment:
    # --- 장착 중 ---
    equipped:
      weapon:
        id: "wep_iron_sword_01"
        name: "철검"
        rarity: "common"
        stats: { attack: +15 }
        
      armor:
        id: "arm_leather_01"
        name: "가죽 갑옷"
        rarity: "common"
        stats: { defense: +8 }
        
      accessory_1:
        id: "acc_ring_01"
        name: "힘의 반지"
        rarity: "uncommon"
        stats: { strength: +2 }
        
      accessory_2: null
      
    # --- 소지품 (인벤토리) ---
    inventory:
      max_slots: 20
      current_weight: 12.5
      max_weight: 50.0
      items:
        - { id: "item_potion_hp", name: "회복약", quantity: 5 }
        - { id: "item_scroll_return", name: "귀환 주문서", quantity: 1 }
        
  # ============================================================
  # 과거 로그 (Event History)
  # ============================================================
  history_log:
    # --- 전투 기록 ---
    combat_record:
      total_battles: 23
      victories: 18
      defeats: 3
      retreats: 2
      kills: 45
      assists: 12
      deaths: 0
      near_deaths: 2                #濒死经历
      
    # --- 탐험 기록 ---
    exploration_record:
      dungeons_visited:
        - { name: "안개의 폐광", visits: 5, clears: 3 }
        - { name: "잊힌 신전", visits: 2, clears: 0 }
      tiles_explored: 156
      treasures_found: 8
      traps_triggered: 4
      
    # --- 사회적 기록 ---
    social_record:
      brawls_participated: 3        # 주점 난투 참여
      brawls_initiated: 2
      counseling_sessions: 1        # 상담 횟수
      gifts_given: 5
      gifts_received: 3
      
    # --- 길드 활동 ---
    guild_record:
      joined_at: "2026-04-01"
      quests_completed: 12
      gold_earned: 5000
      gold_spent: 3200
      times_penalized: 1
      times_rewarded: 3
      
    # --- 이벤트 타임라인 (최근 30일) ---
    recent_events:
      - date: "2026-04-17"
        type: "COMBAT"
        description: "안개의 폐광 보스 격파"
        outcome: "VICTORY"
        party: ["adv_002", "adv_004"]
        
      - date: "2026-04-16"
        type: "SOCIAL"
        description: "달빛 주점에서 잭과 말다툼"
        outcome: "RELATIONSHIP_DAMAGE"
        related: ["adv_003"]
        
      - date: "2026-04-15"
        type: "RELATIONSHIP"
        description: "미아가 위기에서 구출"
        outcome: "RELATIONSHIP_BOOST"
        related: ["adv_002"]
        
  # ============================================================
  # 동적 상태 (Runtime State)
  # ============================================================
  runtime:
    current_status: "IDLE"          # IDLE, EXPLORING, COMBAT, RESTING, INJURED
    location: "guild_hall"          # 현재 위치
    current_party: null               # 현재 파티 (null = 솔로)
    
    # --- 컨디션 ---
    conditions:
      physical: "healthy"            # healthy, injured, sick, exhausted
      mental: "stable"               # stable, stressed, traumatized, inspired
      
    # --- 버프/디버프 ---
    active_effects:
      - { name: "의리의 결속", type: "buff", duration: 3, source: "adv_002" }
      - { name: "피로", type: "debuff", duration: 1, source: "combat" }
      
    # --- 현재 퀘스트 ---
    active_quests:
      - quest_id: "qst_001"
        progress: 0.6
        
  # ============================================================
  # OC/모딩 데이터 (Modding)
  # ============================================================
  modding:
    source_file: "user_mods/adventurer_crow.json"
    author: "PlayerName"
    is_official: false
    tags: ["fanmade", "warrior", "popular"]
    
  # --- 백스토리 ---
  backstory: |
    북부의 작은 마을 출신. 고아로 자라 마을 경비대에서 검을 익혔다.
    3년 전 마을을 습격한 오크 무리와의 전투에서 유일한 생존자가 되었고,
    그 트라우마를 극복하기 위해 더욱 무모해졌다.
    "이번엔 내가 모두를 지키겠다"는 일념으로 길드에 합류했다.
    
  # --- 비밀 (히든 정보) ---
  secrets:
    - type: "TRAUMA"
      description: "고향 마을 습격 트라우마"
      known_by: ["adv_002"]         # 미아만 알고 있음
      reveal_condition: "mental_state: traumatized"
      
    - type: "AMBITION"
      description: "전설의 검 '드래곤슬레이어'를 찾고 싶음"
      known_by: []
      reveal_condition: "dungeon: dragon_lair"
```

---

## 3. 데이터 검증 규칙

### 3.1. 필수 필드 체크
```yaml
required_fields:
  - id (format: "adv_\d+")
  - name (min: 1, max: 20 chars)
  - personality.core_traits (min: 1, max: 3)
  - base_stats.level (min: 1, max: 99)
```

### 3.2. 관계도 제약
```yaml
relationship_constraints:
  max_relationships: 20             # 한 캐릭터당 최대 관계 수
  score_range: [-100, 100]          # 유효 호감도 범위
  self_relationship: false          # 자기 자신과의 관계 금지
  duplicate_target: false           # 동일 대상 중복 금지
```

### 3.3. 성향 호환성
```yaml
trait_compatibility:
  conflicting_pairs:                # 동시 보유 불가
    - ["냉혈한", "금사빠"]
    - ["의리파", "기회주의자"]
    - ["신중한", "무모한"]
    
  synergistic_pairs:              # 함께 보유 시 보너스
    - ["의리파", "신중한"]: "신뢰의 수호자"
    - ["탐욕스러운", "기회주의자"]: "정략가"
```

---

## 4. 생성 알고리즘 참조

### 4.1. 랜덤 생성
```yaml
random_generation:
  # 성별/이름
  name_pool: "data/names_korean.json"
  
  # 성향 선택
  core_trait_selection:
    method: "weighted_random"
    weights:
      무모한: 0.15
      신중한: 0.15
      의리파: 0.12
      탐욕스러운: 0.12
      금사빠: 0.10
      냉혈한: 0.10
      질투심강한: 0.10
      허세부리는: 0.08
      기회주의자: 0.08
      
  # 스탯 분배
  stat_allocation:
    method: "class_based_with_variance"
    variance: ±20%
```

### 4.2. 초기 관계 설정
```yaml
initial_relationships:
  # 길드 합류 시 기존 길드원과의 관계
  on_join:
    base_score: 0
    trait_modifiers:
      금사빠: +10  # 빠르게 친해지려 함
      냉혈한: -10  # 거리를 둠
      의리파: +5   # 우호적
```

---

## 5. 인덱스 및 쿼리

### 5.1. 주요 인덱스
```yaml
indexes:
  - field: id (unique)
  - field: name (text search)
  - field: personality.core_traits (array search)
  - field: relationships.with_others[].score (range query)
  - field: runtime.current_status (filter)
  - field: history_log.combat_record.deaths (filter)
```

### 5.2. 자주 사용하는 쿼리
```yaml
example_queries:
  # "무모한" 성향 모험가 검색
  query_1: { "personality.core_traits": "무모한(Reckless)" }
  
  # 특정 관계 상태인 쌍 검색
  query_2: { "relationships.with_others.status": "연인" }
  
  # 현재 탐험 중인 모험가
  query_3: { "runtime.current_status": "EXPLORING" }
  
  # 죽음 경험이 있는 모험가
  query_4: { "history_log.combat_record.deaths": { $gt: 0 } }
```

---

## 6. OC 포탈 통합

### 6.1. 유저 제출 폼
```yaml
oc_submission_form:
  required:
    - name
    - appearance.portrait (PNG, 512x768)
    - personality.core_traits (1-2개)
    - class.primary
    - backstory (min: 100 chars)
    
  optional:
    - subclass
    - secondary_traits
    - equipment.equipped.weapon
    - secrets
    
  validation:
    - 이미지 크기 체크
    - 성향 중복/충돌 체크
    - 밸런스 검사 (초과 스탯 여부)
```

### 6.2. 자동 생성 필드
```yaml
auto_generated_fields:
  - id ("usr_" prefix + timestamp)
  - created_at
  - base_stats (클래스 기반)
  - relationships (빈 배열)
  - history_log (초기값)
  - runtime (기본값)
```
