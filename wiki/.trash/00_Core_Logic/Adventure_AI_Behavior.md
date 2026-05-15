---
title: 모험가 AI 행동 로직
description: 성격에 따른 탐험/전투 AI 로직 (Pseudocode)
category: Core Logic
type: System Design
version: 1.0
created: 2026-04-17
last_updated: 2026-04-17
tags: [ai, behavior, personality, combat, exploration, pseudocode]
---

# 모험가 AI 행동 로직 (Adventure AI Behavior)

## 1. 개요

던전 탐험 중 모험가들은 자율적으로 행동하며, 그들의 **성격 태그(Personality Tags)**가 의사결정의 핵심 축이 됩니다. 이 문서는 탐험/전투 상황에서의 AI 의사결정 트리와 슈도코드를 명세합니다.

---

## 2. AI 의사결정 레이어

```
┌─────────────────────────────────────────┐
│  Layer 4: 개인적 행동 (Individual Act)   │ ← 성격 태그 반영
├─────────────────────────────────────────┤
│  Layer 3: 관계 기반 행동 (Social Act)    │ ← 파티 내 관계 영향
├─────────────────────────────────────────┤
│  Layer 2: 전략적 행동 (Strategic Act)    │ ← 길드 마스터 명령
├─────────────────────────────────────────┤
│  Layer 1: 생존 기반 행동 (Survival Act)  │ ← 체력/마나 임계값
└─────────────────────────────────────────┘
```

---

## 3. 레이어 1: 생존 기반 행동

### 3.1. 체력 임계값 반응
```pseudocode
function survival_check(character):
    hp_ratio = character.hp / character.max_hp
    
    if hp_ratio < 0.15:
        trigger_emergency(character)
    else if hp_ratio < 0.30:
        suggest_retreat(character)
    else if hp_ratio < 0.50:
        request_healing(character)
    
function trigger_emergency(character):
    if has_tag(character, "의리파"):
        // 동료를 먼저 생각하지만 위험
        if ally_in_danger:
            return "COVER_ALLY"  // 대신 막기
        else:
            return "URGENT_RETREAT"
    
    else if has_tag(character, "냉혈한"):
        // 효율 계산
        if estimated_loot > character.value * 3:
            return "CONTINUE_FIGHT"  // 이익이 더 크면 계속
        else:
            return "SELFISH_RETREAT"  // 혼자 도주
    
    else if has_tag(character, "무모한"):
        // 무모하게 계속 싸움
        return "BERSERK_MODE"  // 공격력 +30%, 방어력 -50%
    
    else if has_tag(character, "신중한"):
        return "DEFENSIVE_STANCE"  // 방어 +50%, 힐링 아이템 사용
    
    else:
        return "STANDARD_RETREAT"
```

### 3.2. 마나/자원 관리
```pseudocode
function resource_management(character, skill_cost):
    resource_ratio = character.mp / character.max_mp
    
    if has_tag(character, "신중한"):
        // 마나 30% 이하 시 스킬 보존
        return resource_ratio > 0.30
    
    else if has_tag(character, "무모한"):
        // 전력 투구
        return true  // 항상 스킬 사용
    
    else if has_tag(character, "탐욕스러운"):
        // 보스만 스킬 사용 (비용 효율)
        return target.is_boss or target.has_valuable_loot
    
    else:
        return resource_ratio > 0.20
```

---

## 4. 레이어 2: 전략적 행동

### 4.1. 탐험 방향 결정
```pseudocode
function choose_exploration_direction(character, dungeon_map):
    available_tiles = get_adjacent_tiles(character.position)
    
    scored_tiles = []
    for tile in available_tiles:
        score = 0
        
        // 기본 탐험 점수
        if tile.is_unexplored:
            score += 10
        
        // 성격 태그 가중치
        if has_tag(character, "무모한"):
            if tile.has_enemy_signs:
                score += 20  // 위험을 즐김
            if tile.is_dangerous:
                score += 10
        
        else if has_tag(character, "신중한"):
            if tile.has_trap_probability > 0.5:
                score -= 30  // 함정 회피
            if tile.is_safe_zone:
                score += 15
        
        else if has_tag(character, "탐욕스러운"):
            if tile.has_treasure_signs:
                score += 25  // 보물 우선
            if tile.has_enemy_signs:
                score += 5   // 전리품 기대
        
        else if has_tag(character, "허세부리는"):
            if other_allies_nearby:
                score += 15  // 보여주기식 행동
        
        // 안개(포그) 영향
        fog_penalty = tile.fog_density * 5
        score -= fog_penalty
        
        scored_tiles.append({tile: tile, score: score})
    
    return max_by(scored_tiles, score).tile
```

### 4.2. 길드 명령 반응
```pseudocode
function process_guild_order(character, order):
    obedience = calculate_obedience(character)
    // obedience = 길드 충성도 + 성격 계수
    
    if has_tag(character, "의리파"):
        obedience += 20
    else if has_tag(character, "방랑자"):
        obedience -= 30
    else if has_tag(character, "기회주의자"):
        // 명령에 따라 순응도 변화
        if order.profit_potential > 100:
            obedience += 25
    
    if obedience > 50:
        return "OBEY"  // 명령 수행
    else if obedience > 20:
        return "MODIFY"  // 일부 수정하여 수행
    else:
        return "IGNORE"  // 명령 무시, 자율 행동
```

---

## 5. 레이어 3: 관계 기반 행동

### 5.1. 파티 내 우선순위
```pseudocode
function social_priority(character, party_members):
    for ally in party_members:
        relationship = get_relationship(character, ally)
        
        if relationship.score >= 50:
            // 친밀한 동료
            if ally.hp < ally.max_hp * 0.3:
                return {
                    action: "PROTECT",
                    target: ally,
                    priority: 90
                }
        
        else if relationship.score <= -30:
            // 적대적인 동료
            if has_tag(character, "질투심강한") and ally.has_valuable_item:
                return {
                    action: "STEAL_ATTEMPT",
                    target: ally,
                    priority: 70
                }
            else:
                return {
                    action: "AVOID",
                    target: ally,
                    priority: 60
                }
        
        else if has_tag(character, "금사빠") and relationship.score > 20:
            // 호감 있는 동료와 함께 행동
            if ally.is_moving:
                return {
                    action: "FOLLOW",
                    target: ally,
                    priority: 50
                }
```

### 5.2. 전리품 분배 분쟁
```pseudocode
function loot_distribution_conflict(character, loot, party):
    desire = calculate_loot_desire(character, loot)
    
    // 기본 욕구
    desire += loot.value * 0.5
    
    // 성격 계수
    if has_tag(character, "탐욕스러운"):
        desire *= 2.0
        if loot.is_unique:
            desire *= 1.5
    
    else if has_tag(character, "관대한"):
        desire *= 0.3
        // 다른 사람에게 양보 가능성
        if ally.has_lower_gear_score:
            return "YIELD"  // 양보
    
    else if has_tag(character, "의리파"):
        // 동료에게 필요한 아이템이면 양보
        if loot.is_needed_by_ally:
            return "YIELD"
    
    // 최종 결정
    if desire > 80:
        return "DEMAND"  // 강하게 요구
    else if desire > 50:
        return "REQUEST"  // 정중히 요청
    else:
        return "ACCEPT_SHARE"  // 기본 분배 수락
```

---

## 6. 레이어 4: 개인적 행동 (성격 특수)

### 6.1. `무모한` 태그 의사결정
```pseudocode
function reckless_behavior(character, situation):
    risk_assessment = calculate_risk(situation)
    
    // 위험을 과소평가
    perceived_risk = risk_assessment * 0.5
    
    if situation.type == "COMBAT":
        if perceived_risk < 0.3:
            return "CHARGE"  // 돌격
        else:
            return "RISKY_ATTACK"  // 반격 불가능한 공격
    
    else if situation.type == "EXPLORATION":
        if situation.is_unknown_tile:
            return "RUSH_AHEAD"  // 먼저 들어감
        if situation.has_trap_signs:
            return "DISARM_CARELESSLY"  // 함정 해제 시도 (실패율 +20%)
    
    else if situation.type == "RETREAT_DECISION":
        // 퇴각 결정 내릴 때
        if party.any_has_valuable_loot:
            return "STAY_FOR_LOOT"  // 전리품을 위해 남음
        else:
            return "CONTINUE_ANYWAY"  // 그냥 계속
```

### 6.2. `신중한` 태그 의사결정
```pseudocode
function cautious_behavior(character, situation):
    if situation.type == "COMBAT":
        if not situation.has_analyzed_enemy:
            return "ANALYZE"  // 적 분석 먼저
        if character.hp < character.max_hp * 0.8:
            return "DEFENSIVE_POSITION"  // 체력 80% 이하면 방어적
    
    else if situation.type == "EXPLORATION":
        if situation.tile.has_fog:
            return "SCOUT_CAUTIOUSLY"  // 신중하게 정찰
        if situation.has_unidentified_item:
            return "IDENTIFY_FIRST"  // 미확인 아이템 감정 먼저
    
    else if situation.type == "RETREAT_DECISION":
        // 조기 퇴각 성향
        if character.hp < character.max_hp * 0.5:
            return "SUGGEST_RETREAT"
        if party.average_hp < 0.6:
            return "URGENT_RETREAT_VOTE"
```

### 6.3. `탐욕스러운` 태그 의사결정
```pseudocode
function greedy_behavior(character, situation):
    if situation.type == "LOOT_DISCOVERED":
        if situation.is_dangerous_guarded:
            // 위험 감수하고 보물 획득 시도
            if expected_value > risk_cost * 2:
                return "RISK_FOR_TREASURE"
        if situation.is_party_shared_loot:
            return "ATTEMPT_SOLO_CLAIM"  // 혼자 차지 시도
    
    else if situation.type == "DUNGEON_EXIT":
        // 퇴각 시 전리품 운반 우선
        if character.inventory_value > character.carry_capacity * 0.8:
            return "DROP_LESSER_ITEMS"  // 저가 아이템 버림
        if ally.has_valuable_item and relationship < -20:
            return "CONSIDER_BETRAYAL"  // 배신 검토
    
    else if situation.type == "TRADE_OPPORTUNITY":
        // 시세 차익 노림
        if situation.buy_price < situation.market_price * 0.7:
            return "BUY_ALL"
```

---

## 7. 파티 AI 조정

### 7.1. 파티 리더 선출
```pseudocode
function elect_party_leader(party):
    candidates = {}
    
    for member in party:
        score = member.level * 2
        score += member.guild_loyalty * 0.1
        
        if has_tag(member, "신중한"):
            score += 15
        if has_tag(member, "의리파"):
            score += 10
        if has_tag(member, "허세부리는"):
            score += 5  // 자처하는 경향
        if has_tag(member, "무모한"):
            score -= 10
        if has_tag(member, "방랑자"):
            score -= 20
        
        candidates[member] = score
    
    return max_by(candidates, score)
```

### 7.2. 파티 충돌 해결
```pseudocode
function resolve_party_conflict(party, conflict_type):
    if conflict_type == "DIRECTION_DISPUTE":
        // 방향 분쟁
        votes = {}
        for member in party:
            direction = choose_exploration_direction(member)
            votes[direction] += calculate_influence(member)
        
        return max_by(votes)  // 다수결
    
    else if conflict_type == "LOOT_FIGHT":
        // 전리품 분쟁
        aggressors = filter(party, p => loot_distribution_conflict(p) == "DEMAND")
        
        if aggressors.length > 1:
            // 결투 발생 가능성
            for a in aggressors:
                for b in aggressors:
                    if a != b and get_relationship(a, b) < -20:
                        return trigger_duel(a, b)
        
        return "PARTY_SPLIT"  // 파티 해산
```

---

## 8. 전투 AI 행동 선택

### 8.1. 행동 우선순위 트리
```pseudocode
function combat_decision_tree(character, battle_state):
    // 1. 생존 체크
    if character.hp < character.max_hp * 0.15:
        return survival_check(character)
    
    // 2. 관계 기반 행동
    social_action = social_priority(character, battle_state.allies)
    if social_action.priority > 80:
        return social_action
    
    // 3. 성격 기반 전투 스타일
    if has_tag(character, "무모한"):
        return reckless_combat(character, battle_state)
    else if has_tag(character, "신중한"):
        return cautious_combat(character, battle_state)
    else if has_tag(character, "의리파"):
        return supportive_combat(character, battle_state)
    else:
        return standard_combat(character, battle_state)

function reckless_combat(character, state):
    // 항상 공격, 방어 무시
    target = select_weakest_enemy(state.enemies)
    return { action: "ALL_OUT_ATTACK", target: target, damage_bonus: 0.3 }

function cautious_combat(character, state):
    // 방어적 위치, 체력 관리
    if state.threatened_by > 1:
        return { action: "DEFENSIVE_STANCE", defense_bonus: 0.5 }
    
    target = select_safest_target(state.enemies)
    return { action: "SAFE_ATTACK", target: target }

function supportive_combat(character, state):
    // 동료 보호/버프 우선
    weakest_ally = min_by(state.allies, hp)
    if weakest_ally.hp < weakest_ally.max_hp * 0.5:
        return { action: "PROTECT", target: weakest_ally }
    
    return { action: "ATTACK_WITH_COVER", target: state.closest_enemy }
```

---

## 9. 디버그/테스트 도구

### 9.1. AI 시뮬레이션
```yaml
simulation_scenario:
  name: "무모한 vs 신중한"
  party:
    - name: "레오"
      tags: [무모한, 허세부리는]
      class: 전사
    - name: "미아"
      tags: [신중한, 의리파]
      class: 힐러
    - name: "잭"
      tags: [탐욕스러운, 기회주의자]
      class: 도적
  
  dungeon: "안개의 폐광"
  
  expected_behaviors:
    레오: 먼저 진입, 함정 유발 가능성 높음
    미아: 레오를 구출하려 함, 퇴각 제안
    잭: 보물 발견 시 배신 가능성
  
  success_criteria:
    - 레오가 함정을 1회 이상 발동
    - 미아가 레오에게 힐링을 집중
    - 관계도: 레오-미아 상승, 잭-파티 하락
```
