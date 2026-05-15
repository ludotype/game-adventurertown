---
title: NPC 템플릿
description: 마을 상인 및 시설 관리자의 고유 기능 및 선호도 명세
category: Entities
type: Data Template
version: 1.0
created: 2026-04-17
last_updated: 2026-04-17
tags: [npc, entity, merchant, facility, template]
---

# NPC 템플릿 (Template: NPC)

## 1. 개요

NPC(Entity: Non-Player Character)는 마을/길드의 상인, 시설 관리자, 퀘스트 발행자 등 플레이어가 직접 관리하지 않는 캐릭터들입니다. 모험가와 유사한 구조를 가지지만, 고유한 기능 및 선호도를 추가로 지닙니다.

---

## 2. YAML 스키마

```yaml
# ============================================================
# NPC 기본 정보 (Basic Info)
# ============================================================
npc:
  # --- 필수 필드 ---
  id: "npc_001"                    # 고유 식별자 (npc_ 접두사)
  name: "브라운 상인"               # 이름 (직함 포함 권장)
  created_at: "2026-04-17"
  version: 1
  
  # --- NPC 타입 ---
  type: "MERCHANT"                 # MERCHANT, FACILITY_MANAGER, QUEST_GIVER, STORY
  subtype: "WEAPON_DEALER"          # 세분화 타입 (optional)
  
  # --- 외형 ---
  appearance:
    portrait: "portrait_brown.png"
    sprite: "sprite_merchant.png"
    avatar: "avatar_brown.png"
    color_theme: "#D69E2E"          # 직업/상점 색상
    
  # --- 기본 속성 ---
  base_stats:
    level: 5                       # NPC도 레벨 개념 적용 (영향력)
    hp: 50                         # NPC는 전투 불참 (무한체력 처리)
    
  # ============================================================
  # NPC 고유 기능 (NPC Functions)
  # ============================================================
  functions:
    # --- 상인 기능 (MERCHANT 타입) ---
    merchant_data:
      shop_name: "브라운의 무기상"   # 상점 이름
      shop_type: "WEAPON"           # WEAPON, ARMOR, ACCESSORY, GENERAL, POTION, BLACKMARKET
      
      # --- 영업 시간 ---
      operating_hours:
        open: 08:00
        close: 20:00
        closed_days: []             # 휴무일 (요일)
        
      # --- 상품 구성 ---
      inventory:
        refresh_interval: "daily"   # daily, weekly, on_visit
        item_pool:
          - category: "weapon"
            rarity_weights:
              common: 50
              uncommon: 35
              rare: 13
              epic: 2
            level_range: "player_avg ± 2"
            
      # --- 가격 정책 ---
      pricing:
        base_markup: 1.3              # 기본 마진 30%
        dynamic_pricing: true       # 시세 연동
        
        # --- 길드 관계에 따른 할인 ---
        guild_discount:
          friendly: 0.95              # 친밀: 5% 할인
          allied: 0.85              # 동맹: 15% 할인
          
      # --- 특수 서비스 ---
      services:
        - "identify"                 # 미확인 아이템 감정
        - "repair"                   # 장비 수리
        - "appraise"                 # 아이템 감정 (가치)
        
    # --- 시설 관리자 기능 (FACILITY_MANAGER 타입) ---
    facility_data:
      facility_name: "달빛 상담소"
      facility_type: "COUNSELING"   # COUNSELING, TRAINING, HEALING, INN, TAVERN
      
      # --- 운영 비용 ---
      operation_cost: 500             # 일일 운영비
      
      # --- 제공 서비스 ---
      services:
        - type: "counseling"
          name: "관계 상담"
          cost: 100
          effect: "relationship_score_reset:minor"
          cooldown: 3               # 일 단위
          
        - type: "therapy"
          name: "트라우마 치료"
          cost: 500
          effect: "remove_trauma"
          requirement: "mental_state: traumatized"
          
      # --- 시설 효과 ---
      facility_effects:
        - "guild_stress_reduction: 5%"
        - "relationship_conflict_prevention: +10%"
        
    # --- 퀘스트 발행자 기능 (QUEST_GIVER 타입) ---
    quest_giver_data:
      quest_pool:
        - quest_id: "qst_brown_001"
          name: "희귀 광석 수집"
          type: "GATHERING"
          difficulty: 3
          reward_gold: 2000
          unlock_condition: "guild_rank >= 2"
          
        - quest_id: "qst_brown_002"
          name: "도적단 토벌"
          type: "COMBAT"
          difficulty: 5
          reward_gold: 5000
          unlock_condition: "completed: qst_brown_001"
          
      # --- 퀘스트 갱신 ---
      quest_refresh: "weekly"
      
  # ============================================================
  # 성격 및 선호도 (Personality & Preferences)
  # ============================================================
  personality:
    # --- NPC 특화 성향 ---
    core_traits:
      - "실리적인(Pragmatic)"
      - "수다쟁이(Chatty)"
      
    # --- 대화 스타일 ---
    dialogue_style:
      greeting: "어서 오시게, 오늘은 어떤 물건을 찾는가?"
      farewell: "다음에 또 오게나."
      gossip_frequency: "high"      # none, low, medium, high
      gossip_topics:
        - "market_trends"            # 시장 동향
        - "adventurer_rumors"        # 모험가 소문
        
  # --- 모험가 선호도 (Adventurer Preferences) ---
  preferences:
    # --- 좋아하는 성향 ---
    liked_traits:
      - trait: "신중한(Cautious)"
        reason: "무모한 짓으로 물건 파손하지 않음"
        discount_bonus: 0.02
        
      - trait: "관대한(Generous)"
        reason: "장사가 잘됨"
        discount_bonus: 0.05
        
    # --- 싫어하는 성향 ---
    disliked_traits:
      - trait: "무모한(Reckless)"
        reason: "무기를 자주 부숨"
        markup_penalty: 0.10          # 10% 추가 비용
        
      - trait: "탐욕스러운(Greedy)"
        reason: "흥정이 과함"
        service_restriction: "appraise" # 감정 서비스 거부
        
    # --- 특별 관계 (특정 모험가와) ---
    special_relations:
      - adventurer_id: "adv_001"
        status: "GRUDGE"            # FAVOR, GRUDGE, NEUTRAL
        reason: "과거에 무기 미지급"
        effect: "service_denial"
        
      - adventurer_id: "adv_002"
        status: "FAVOR"
        reason: "단골 고객"
        effect: "special_discount: 20%"
        
  # ============================================================
  # 관계도 (Relationship Web)
  # ============================================================
  relationships:
    # --- 다른 NPC와의 관계 ---
    with_npcs:
      - target_id: "npc_002"        # 경쟁 상인
        target_name: "실버 마법상점"
        type: "RIVAL"
        intensity: 7                  # 1-10
        description: "무기 vs 마법, 시장 점유율 다툼"
        
      - target_id: "npc_005"        # 친구
        target_name: "주점 주인 마리"
        type: "FRIEND"
        intensity: 8
        description: "정보 공유 관계"
        
    # --- 길드와의 관계 ---
    with_guild:
      reputation: 45                # -100 ~ 100
      trade_volume: 15000             # 누적 거래액
      last_interaction: "2026-04-17"
      
      # --- 길드 평판 영향 ---
      reputation_effects:
        positive:
          - "가격 할인"
          - "희귀 아이템 노출"
          - "정보 제공"
        negative:
          - "가격 인상"
          - "서비스 제한"
          - "거절 가능성"
          
  # ============================================================
  # 일정/이벤트 (Schedule & Events)
  # ============================================================
  schedule:
    # --- 요일별 일과 ---
    weekly_routine:
      monday:
        - time: "08:00-12:00"
          location: "shop"
          activity: "OPEN"
        - time: "12:00-13:00"
          location: "tavern"
          activity: "LUNCH_WITH: npc_005"
        - time: "13:00-20:00"
          location: "shop"
          activity: "OPEN"
          
      tuesday:
        - time: "08:00-20:00"
          location: "shop"
          activity: "OPEN"
          
      # ... (나머지 요일)
      
    # --- 특수 이벤트 ---
    special_events:
      - name: "월간 시장 축제"
        trigger: "first_sunday_of_month"
        location: "town_square"
        activity: "SPECIAL_SALE"
        discount_rate: 0.8
        
      - name: "경쟁상인 방해"
        trigger: "random: 0.1"
        condition: "rival_reputation < -20"
        activity: "SPREAD_RUMOR"
        target: "npc_002"
        
  # ============================================================
  # 대화/퀘스트 데이터 (Dialogue & Quest)
  # ============================================================
  dialogue:
    # --- 기본 대화 ---
    greetings:
      - "어서 오시게, {player_name}."
      - "오늘은 어떤 일로?"
      - "요즘 안개가 짙어서 무기가 잘 팔리는구만."
      
    # --- 상황별 대화 ---
    situational:
      low_reputation:
        - "음... 우리 가게는 좋은 물건만 취급한단 말일세."
        - "돈은 먼저 받고 해야겠네."
        
      high_reputation:
        - "자네라면 특별히 싸게 해주지!"
        - "좋은 물건 하나 비춰둘게."
        
      rainy_day:
        - "비 오는 날엔 갑옷 관리가 중요하지."
        
    # --- 퀘스트 관련 대화 ---
    quest_related:
      available_quest:
        - "이 물건을 구해줄 수 있겠나?"
      
      quest_in_progress:
        - "아직인가? 서두르게나."
        
      quest_completed:
        - "고맙네, 이거 받게."
        
    # --- 뉴스/소문 대화 ---
    gossip:
      - "{adventurer_name}가 또 주점에서 난동을 부렸다던데..."
      - "{rival_merchant}가 이번에 가짜 물건을 팔았다는 소문이 있네."
      - "시장에 드래곤 비늘이 입고될 예정이라더군."
      
  # ============================================================
  # 과거 로그 (History Log)
  # ============================================================
  history_log:
    # --- 거래 기록 ---
    transaction_record:
      total_sales: 150000
      total_purchases: 80000
      unique_customers: 25
      
    # --- 중요 이벤트 ---
    key_events:
      - date: "2026-04-10"
        type: "ECONOMIC"
        description: "드래곤 비늘 거래로 대박"
        effect: "wealth: +50000"
        
      - date: "2026-04-15"
        type: "CONFLICT"
        description: "{adv_003}와 말다툼"
        effect: "disliked_traits: 무모한 추가"
        
    # --- NPC 간 상호작용 ---
    npc_interactions:
      - date: "2026-04-16"
        with: "npc_002"
        type: "RIVALRY"
        description: "가격 경쟁"
        outcome: "WON"
        
  # ============================================================
  # 동적 상태 (Runtime State)
  # ============================================================
  runtime:
    current_location: "shop"
    current_activity: "OPEN"
    is_available: true              # 현재 대화/거래 가능 여부
    
    # --- 현재 재화 ---
    wealth: 50000                   # NPC 개인 자금
    
    # --- 임시 상태 ---
    temporary_effects:
      - { name: "축제 분위기", type: "buff", sales_boost: 0.1 }
      
  # ============================================================
  # 스토리/퀘스트 연동 (Story Integration)
  # ============================================================
  story_hooks:
    # --- 메인 스토리 연동 ---
    main_story:
      chapter: 2
      role: "WEAPON_SUPPLIER"
      unlock_condition: "completed_chapter_1"
      
    # --- 사이드 퀘스트 ---
    side_quests:
      - quest_id: "sq_brown_001"
        name: "상인의 과거"
        trigger: "reputation > 80"
        type: "STORY"
        
      - quest_id: "sq_brown_002"
        name: "경쟁상인 견제"
        trigger: "rival_conflict > 5"
        type: "SABOTAGE"
        
  # --- 비밀 (Hidden Info) ---
  secrets:
    - type: "PAST"
      description: "과거에 용병이었음"
      known_by: ["npc_005"]
      reveal_condition: "friendship_with_player > 90"
      
    - type: "CORRUPTION"
      description: "가끔 불법 무기도 취급"
      known_by: []
      reveal_condition: "blackmarket_access"
```

---

## 3. NPC 타입별 상세

### 3.1. 상인 (MERCHANT)

| 서브타입 | 특화 | 고유 기능 |
|----------|------|-----------|
| WEAPON_DEALER | 무기 | 수리, 강화 |
| ARMOR_DEALER | 방어구 | 맞춤 제작 |
| POTION_SHOP | 포션 | 처방 |
| GENERAL_STORE | 잡화 | 식료품, 기본 장비 |
| BLACKMARKET | 불법 물품 | 레어 아이템, 높은 리스크 |
| MAGIC_SHOP | 마법 도구 | 감정, 마법 부여 |

### 3.2. 시설 관리자 (FACILITY_MANAGER)

| 서브타입 | 기능 | 효과 |
|----------|------|------|
| COUNSELING | 관계 상담 | 관계도 회복, 트라우마 치료 |
| TRAINING | 훈련 시설 | 스탯 성속도 증가 |
| HEALING | 치료소 | 체력/상태이상 회복 |
| INN | 여관 | 스트레스 해소, 저장 |
| TAVERN | 주점 | 사교, 뉴스 수집 |

### 3.3. 퀘스트 발행자 (QUEST_GIVER)

| 서브타입 | 퀘스트 특성 |
|----------|-------------|
| NOBLE | 정식 의뢰, 높은 보상, 명예 관련 |
| VILLAGER | 소규모 문제, 낮은 보상, 신뢰 구축 |
| MYSTERIOUS | 정보 부족, 높은 리스크, 큰 보상 |
| GUILD_OFFICIAL | 길드 관련, 순위 영향 |

---

## 4. 모험가와의 상호작용 시스템

### 4.1. 선호도 계산식
```
NPC_호감도 = 기본값(50)
  + (선호 성향 보유 × 가중치)
  - (비선호 성향 보유 × 가중치)
  + (거래량 × 0.001)
  + (특별 이벤트 보너스)
```

### 4.2. 영향 효과 테이블

| 호감도 범위 | 상호작용 변화 |
|-------------|---------------|
| -100 ~ -51 | 거래 거부 가능, 소문 확산 |
| -50 ~ -11 | 가격 +20%, 서비스 제한 |
| -10 ~ +9 | 기본 가격 |
| +10 ~ +29 | 가격 -5%, 기본 정보 제공 |
| +30 ~ +49 | 가격 -10%, 희귀 아이템 노출 |
| +50 ~ +79 | 가격 -15%, 특수 퀘스트 제공 |
| +80 ~ +100 | 가격 -20%, 독점 정보, 히든 퀘스트 |

### 4.3. NPC 간 관계 영향
```yaml
# NPC 간 관계가 플레이어에게 미치는 영향
npc_relationship_effects:
  FRIEND:
    - "A를 돕면 B도 호감도 상승"
    - "A-B 동시 접촉 시 추가 보너스"
    
  RIVAL:
    - "A를 돕면 B 호감도 하락"
    - "양측에 대한 균형 잡기 미니게임"
    
  FAMILY:
    - "가족 NPC 중 한 명만 접촉 가능"
    - "한 명을 배신하면 전체 관계 파탄"
```

---

## 5. 동적 이벤트 시스템

### 5.1. NPC 자체 이벤트
```yaml
npc_autonomous_events:
  - trigger: "random_daily"
    probability: 0.05
    events:
      - "Economic_Boom": 매출 급증, 할인 행사
      - "Economic_Crisis": 매출 감소, 가격 인상
      - "Personal_Trouble": 일시적 영업 중단
      - "Rumor_Spread": 특정 모험가에 대한 소문
```

### 5.2. 모험가 행동에 의한 이벤트
```yaml
adventurer_triggered_events:
  - condition: "adventurer_brawl_in_tavern"
    affected_npc: "TAVERN_OWNER"
    effect: "stress_increase"
    
  - condition: "adventurer_completed_quest"
    affected_npc: "QUEST_GIVER"
    effect: "reputation_boost"
    
  - condition: "adventurer_betrayed_party"
    affected_npc: "ALL_MERCHANTS"
    effect: "rumor_spread"
    discount_penalty: -0.1
```

---

## 6. OC 포탈 통합

### 6.1. NPC 제출 (플레이어 제작 NPC)
```yaml
oc_npc_submission:
  allowed_types: ["MERCHANT", "QUEST_GIVER"]
  
  required_fields:
    - name
    - type
    - portrait
    - backstory
    - at_least_one_service
    
  restrictions:
    - no_combat_npc              # 전투 NPC 제작 불가
    - max_3_oc_per_player        # 플레이어당 3개 제한
    - must_be_town_related       # 마을/길드 관련만
```

### 6.2. 검수 프로세스
```yaml
review_process:
  automated_checks:
    - name_uniqueness
    - image_format
    - lore_consistency
    - balance_check
    
  manual_review:
    - story_team_approval
    - integration_planning
    
  approval_time: "3-7 days"
```
