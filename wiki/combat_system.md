# 전투 시스템 (Combat System)

## 개요

길드 마스터의 전투 시스템은 **턴제 자동 전투(Turn-based Auto Battle)**를 기반으로 합니다. 플레이어는 직접 개입하지 않고 결과를 지켜보지만, **스피드 컨트롤(홀드 액셀러레이션)**을 통해 전투 속도를 조절할 수 있습니다.

### 핵심 특징
- **완전 자동화**: AI가 모든 결정(스킬 선택, 타겟팅)을 담당
- **속도 조절**: 1x → 2x → 4x 단계별 가속 (홀드 버튼)
- **시각적 피드백**: 공격, 피해, 회복 등 모든 행동에 명확한 애니메이션
- **세션 기반**: 한 전투는 30초~2분 내외로 완결

---

## 시스템 아키텍처

### 클래스 다이어그램

```
TurnManager (Singleton)
├── Combatant[] participants
├── TurnQueue queue
└── SpeedController

Combatant (Entity)
├── Stats (HP, MP, STR, DEX, INT, SPD)
├── AutoBattleAI ai
├── Skill[] skills
└── StatusEffect[] buffs/debuffs

AutoBattleAI
├── TargetPriority strategy
└── SkillSelector skill_ai

CombatRenderer
├── DamageLabelPool
├── EffectAnimator
└── CameraController
```

---

## 핵심 컴포넌트

### 1. TurnManager

턴 순서와 시간 흐름을 총괄하는 싱글톤 매니저입니다.

**속성:**
| 속성 | 타입 | 설명 |
|------|------|------|
| `base_time_scale` | float | 기본 시간 배속 (기본값: 1.0) |
| `max_speed_mult` | float | 최대 가속 배율 (기본값: 4.0) |
| `current_turn` | int | 현재 턴 인덱스 |
| `is_holding` | bool | 홀드 버튼 눌림 상태 |

**시그널:**
```gdscript
signal turn_started(combatant: Combatant)
signal turn_ended(combatant: Combatant)
signal battle_ended(result: BattleResult)
signal speed_changed(new_speed: float)
```

**턴 순서 계산:**
```gdscript
func calculate_turn_order() -> Array[Combatant]:
    # 속도( Speed ) 기반으로 정렬
    var sorted = participants.duplicate()
    sorted.sort_custom(func(a, b): return a.stats.speed > b.stats.speed)
    return sorted
```

---

### 2. Combatant

전투 참여자(플레이어 파티 또는 적)의 기본 단위입니다.

**구조:**
```gdscript
class_name Combatant
extends Node2D

@export var stats: CharacterStats
@export var is_player_controlled: bool = false
@export var formation_position: int  # 0~3 (전열/후열)

var ai: AutoBattleAI
var current_hp: int
var current_mp: int
var status_effects: Array[StatusEffect] = []
var is_alive: bool = true
```

**Formation (진영):**
- **전열 (Front Row 0-1)**: 받는 피해 -20%, 주는 피해 +10%
- **후열 (Back Row 2-3)**: 받는 피해 +0%, 주는 물리 피해 -10%, 마법 피해 +10%

---

### 3. AutoBattleAI

자동 전투의 의사결정 로직을 담당합니다.

**타겟 우선순위 전략:**
```gdscript
enum TargetPriority {
    LOWEST_HP,        # 마무리 (Execute)
    HIGHEST_THREAT,   # DPS 우선 제거
    HEALER_FIRST,     # 지원가 제거
    TANK_LAST,        # 탱커는 나중에
    RANDOM            # 무작위
}
```

**AI 의사결정 흐름:**
```gdscript
func decide_action(combatants: Array[Combatant]) -> BattleAction:
    # 1. 생존 가능한 적 필터링
    var enemies = get_alive_enemies(combatants)
    
    # 2. 스킬 선택 (쿨다운/MP 체크)
    var available_skills = owner.skills.filter(func(s): return s.is_available())
    var selected_skill = select_optimal_skill(available_skills, enemies)
    
    # 3. 타겟 선택
    var target = select_target_by_priority(selected_skill.target_priority, enemies)
    
    return BattleAction.new(selected_skill, target)
```

**역할별 AI 행동 패턴:**

| 역할 | 공격 우선순위 | 스킬 우선순위 |
|------|--------------|--------------|
| **전사 (Warrior)** | 전열 적, 높은 위협 | 방어 버프 > 단일 공격 |
| **마법사 (Mage)** | 후열 적, 힐러 | 광역 공격 > 단일 공격 |
| **힐러 (Healer)** | - | 아군 HP 50% 이하 시 힐링 > 버프 |
| **궁수 (Archer)** | 후열 적, 낮은 HP | 연속 공격 > 치명타 강화 |

---

### 4. SpeedController

플레이어 입력을 받아 전투 속도를 실시간으로 조절합니다.

**동작 방식:**
```gdscript
extends Button

var hold_duration: float = 0.0
var speed_levels = [1.0, 2.0, 4.0, 8.0]  # 4단계 가속
var current_level: int = 0

func _process(delta):
    if is_pressed():
        hold_duration += delta
        
        # 0.5초마다 단계 상승
        var new_level = mini(int(hold_duration / 0.5), speed_levels.size() - 1)
        
        if new_level != current_level:
            current_level = new_level
            Engine.time_scale = speed_levels[current_level]
            emit_signal("speed_changed", speed_levels[current_level])
            update_visual()
    else:
        # 버튼 릴리즈 시 즉시 1x로 복귀
        hold_duration = 0.0
        current_level = 0
        Engine.time_scale = 1.0
```

**UI 표시:**
- 1x: `▶`
- 2x: `▶▶`
- 4x: `▶▶▶`
- 8x: `▶▶▶▶` (최고속)

---

## 전투 흐름

### 1. 전투 시작 (Battle Initiation)

```gdscript
func start_battle(player_party: Array[Combatant], enemy_party: Array[Combatant]):
    # 참가자 등록
    participants = player_party + enemy_party
    
    # 진영 배치 (시각적 위치 설정)
    arrange_formation()
    
    # 턴 순서 계산
    turn_queue = calculate_turn_order()
    
    # 카메라 인트로
    await camera.play_intro_animation()
    
    # 전투 루프 시작
    start_turn_loop()
```

### 2. 턴 루프 (Turn Loop)

```gdscript
func start_turn_loop():
    while not is_battle_ended():
        var current = turn_queue[current_turn]
        
        if not current.is_alive:
            advance_turn()
            continue
        
        # 턴 시작
        emit_signal("turn_started", current)
        await process_turn(current)
        emit_signal("turn_ended", current)
        
        # 상태이상 체크 (독, 화상 등)
        await process_status_effects(current)
        
        advance_turn()
    
    end_battle()
```

### 3. 행동 처리 (Action Processing)

```gdscript
func process_turn(combatant: Combatant):
    # AI 결정
    var action = combatant.ai.decide_action(participants)
    
    # 스킬 시전 애니메이션
    await play_cast_animation(combatant, action.skill)
    
    # 효과 적용
    var results = action.execute()
    
    # 결과 시각화
    for result in results:
        await show_combat_result(result)
        
    # 킬 체크
    check_deaths()
```

### 4. 전투 종료 조건

- **승리**: 모든 적 처치
- **패배**: 모든 아군 전투 불능
- **탈출**: 특정 스킬/아이템 사용 (일부 전투 한정)

---

## 시각 시스템

### 1. DamageLabel (플로팅 텍스트)

```gdscript
class_name DamageLabel
extends Label

func setup(value: int, type: DamageType, is_critical: bool = false):
    text = str(value)
    
    match type:
        DamageType.PHYSICAL: modulate = Color.ORANGE_RED
        DamageType.MAGIC: modulate = Color.CORNFLOWER_BLUE
        DamageType.HEAL: modulate = Color.LIME_GREEN
        DamageType.SHIELD: modulate = Color.CYAN
    
    if is_critical:
        scale = Vector2.ONE * 1.5
        text += "!"
    
    # 애니메이션
    var tween = create_tween()
    tween.set_parallel()
    tween.tween_property(self, "position:y", position.y - 50, 0.8)
    tween.tween_property(self, "modulate:a", 0.0, 0.8)
    await tween.finished
    queue_free()
```

### 2. 효과 이펙트

**공격 유형별 시각 효과:**

| 공격 유형 | 이펙트 | 카메라 효과 |
|-----------|--------|-------------|
| **근접** | 검/도검 휘두름, 잔상 | 타겟 흔들림 (Shake 0.1s) |
| **원거리** | 화살/마법 투사체 | 추적 카메라 |
| **광역** | 폭발/충격파 | 줌 아웃 0.2s |
| **치명타** | 붉은 번쩍임, 슬로우 모션 | 타임 스케일 0.3x (0.3s) |

**히트 스톱 (Hit Stop):**
```gdscript
func apply_hit_stop(duration: float = 0.05):
    Engine.time_scale = 0.0
    await get_tree().create_timer(duration, true).timeout  # 프로세스 타임 무시
    Engine.time_scale = current_speed
```

### 3. 카메라 워크

```gdscript
class_name CombatCamera
extends Camera2D

func focus_action(attacker: Combatant, target: Combatant):
    var center = (attacker.global_position + target.global_position) / 2
    var distance = attacker.global_position.distance_to(target.global_position)
    
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    
    # 거리 기반 줌 계산
    var zoom_level = clamp(250.0 / distance, 1.0, 1.8)
    
    tween.parallel().tween_property(self, "position", center, 0.3)
    tween.parallel().tween_property(self, "zoom", Vector2.ONE * zoom_level, 0.3)
    
    await tween.finished

func reset_position():
    var tween = create_tween()
    tween.tween_property(self, "position", default_position, 0.5)
    tween.parallel().tween_property(self, "zoom", Vector2.ONE, 0.5)
```

---

## 스킬 시스템

### 스킬 구조

```gdscript
class_name Skill
extends Resource

@export var name: String
@export var description: String
@export var skill_type: SkillType
@export var target_type: TargetType
@export var power: int
@export var mp_cost: int
@export var cooldown: int  # 턴 단위
@export var priority: TargetPriority

enum SkillType {
    ATTACK_SINGLE,
    ATTACK_AOE,      # 광역
    HEAL_SINGLE,
    HEAL_AOE,
    BUFF,
    DEBUFF,
    SPECIAL          # 특수 메커닉
}

enum TargetType {
    ENEMY_SINGLE,
    ENEMY_ALL,
    ALLY_SINGLE,
    ALLY_ALL,
    SELF,
    ALL
}
```

### 스킬 예시

| 스킬명 | 유형 | 효과 | 쿨다운 |
|--------|------|------|--------|
| **파워 슬래시** | 단일 물리 | 150% 물리 피해 | 0 |
| **파이어볼트** | 단일 마법 | 120% 마법 피해 + 화상(3턴) | 1 |
| **힐링 라이트** | 단일 회복 | HP 30% 회복 + 디버프 1개 제거 | 2 |
| **배틀 크라이** | 버프 | 전체 아군 공격력 +20% (5턴) | 4 |
| **스위프트 어택** | 연속 공격 | 3회 연속 70% 피해 | 3 |

---

## 상태이상 (Status Effects)

### 기본 상태이상

| 이름 | 효과 | 지속 | 중첩 |
|------|------|------|------|
| **독 (Poison)** | 턴 종료 시 MaxHP의 5% 피해 | 3턴 | 가능 (최대 3중첩) |
| **화상 (Burn)** | 턴 종료 시 받는 피해 +10% | 3턴 | 불가 |
| **동결 (Freeze)** | 행동 불능, 받는 피해 +50% | 1턴 | 불가 |
| **속박 (Bind)** | 스킬 사용 불가, 기본공격만 | 2턴 | 불가 |
| **공포 (Fear)** | 공격력 -30% | 3턴 | 불가 |
| **격분 (Berserk)** | 공격력 +50%, 방어력 -30% | 4턴 | 불가 |

### 버프/디버프 규칙

```gdscript
func apply_status(effect: StatusEffect):
    # 동일한 효과가 있으면
    var existing = get_status(effect.type)
    if existing:
        if effect.can_stack:
            existing.stack_count += 1
            existing.refresh_duration()
        else:
            existing.refresh_duration()  # 지속시간만 갱신
    else:
        status_effects.append(effect)
```

---

## UI/UX 설계

### 전투 화면 레이아웃

```
┌─────────────────────────────────────────────────────┐
│  [적 파티]                    [아군 파티]              │
│   🐺(보스)  🐀 🐀             🧙‍♂️ ⚔️ 🏹 💚           │
│   [████████] [████    ]       [████████] [████    ]   │ ← HP바
│                                                      │
│           (전투 애니메이션 영역)                      │
│                                                      │
├─────────────────────────────────────────────────────┤
│  [홀드 1x ▶] [2x ▶▶] [4x ▶▶▶] [8x ▶▶▶▶]           │ ← 스피드
│  ─────────────────────────────────────────────────  │
│  [전투 로그]                                         │
│  > ⚔️ 전사가 고블린에게 파워 슬래시! (45 피해)        │
│  > 🔥 고블린이 화상 상태! (3턴)                      │
│  > 💚 힐러가 전사에게 힐링 라이트! (32 회복)          │
└─────────────────────────────────────────────────────┘
```

### HP/MP 바 디자인

```gdscript
# HPBar.gd
extends ProgressBar

func update_display(current: int, maximum: int):
    max_value = maximum
    value = current
    
    var ratio = float(current) / maximum
    
    # 색상 변화 (Green → Yellow → Red)
    if ratio > 0.6:
        tint_progress = Color.LIME_GREEN
    elif ratio > 0.3:
        tint_progress = Color.GOLD
    else:
        tint_progress = Color.CRIMSON
        # 위험 상태 애니메이션
        if not animation_player.is_playing():
            animation_player.play("pulse_red")
```

---

## 최적화 가이드

### 1. 오브젝트 풀링 (Object Pooling)

**문제**: 매 턴 생성/소멸되는 DamageLabel, ParticleEffect가 GC를 유발

**해결:**
```gdscript
class_name EffectPool
extends Node

var damage_label_pool: Array[Label] = []
var max_pool_size: int = 20

func get_damage_label() -> Label:
    if damage_label_pool.is_empty():
        return preload("res://DamageLabel.tscn").instantiate()
    return damage_label_pool.pop_back()

func return_damage_label(label: Label):
    if damage_label_pool.size() < max_pool_size:
        label.reset()
        damage_label_pool.append(label)
    else:
        label.queue_free()
```

### 2. LOD (Level of Detail) 시스템

**고속 배속 시:**
```gdscript
func _process(delta):
    if Engine.time_scale >= 4.0:
        # 고속 모드: 간략화
        particle_system.emitting = false  # 파티클 끔
        show_damage_numbers_only()        # 숫자만 표시
        skip_camera_animations()          # 카메라 움직임 생략
    else:
        # 정속 모드: 풀 퀄리티
        particle_system.emitting = true
```

### 3. 애니메이션 최적화

**Tween 재사용:**
```gdscript
var tween_cache: Dictionary = {}

func shake_sprite(sprite: Sprite2D, intensity: float):
    var key = sprite.get_instance_id()
    
    if tween_cache.has(key) and tween_cache[key].is_valid():
        tween_cache[key].kill()
    
    var tween = create_tween()
    tween_cache[key] = tween
    
    for i in range(5):
        var offset = Vector2(randf() - 0.5, randf() - 0.5) * intensity
        tween.tween_property(sprite, "position", offset, 0.05)
    tween.tween_property(sprite, "position", Vector2.ZERO, 0.05)
```

### 4. 모바일 최적화

- **타겟 FPS**: 60fps 고정 (vsync 활성화)
- **텍스처**: 512x512 이하로 제한, 압축 포맷 사용
- **드로우콜**: 파티클을 CanvasItem 그룹으로 합치기
- **배터리**: 8x 속도는 선택적으로 비활성화 (발열 방지)

---

## 확장 가능성 (Future Roadmap)

### Phase 1: 기본 시스템 강화

- **시너지 시스템**: 특정 직업 조합 시 버프
  - 전사+힐러: "수호의 결속" - 받는 피해 10% 감소
  - 마법사+마법사: "원소 융합" - 마법 피해 15% 증가

- **환경 상호작용**: 맵 타입별 전투 보정
  - 숲: 궁수 공격력 +10%
  - 동굴: 마법사 MP 소모 -20%

### Phase 2: 플레이어 개입 요소

- **긴급 개입 (Emergency Intervention)**: 연 3회 제한
  - 즉시 회복: 아군 1명 HP 50% 회복
  - 전략 변경: 다음 턴 AI 우선순위 변경
  - 필살기 게이지: 전투 중 축적 → 필살기 발동

- **전투 예측**: 전투 시작前 승률 예측 표시
  - 80%+ 녹색 (안전)
  - 50-80% 노란색 (주의)
  - <50% 빨간색 (위험)

### Phase 3: 고급 전투 메커닉

- **콤보 시스템**: 연속 공격 시 데미지 증가
  - 같은 적 3회 공격 시 3번째 공격 피해 +50%

- **카운터/가드**: 확률 기반 반격
  - 전사 20% 확률로 받은 피해의 50% 반사

- **전투 페이즈**: 보스전 3단계 변화
  - 1페이즈: 일반 패턴
  - 2페이즈 (HP 50%): 광역 공격 추가
  - 3페이즈 (HP 20%): 공격력 50% 증가, 방어력 50% 감소

### Phase 4: 콘텐츠 확장

- **레이드 보스**: 8인 파티, 10분 이상 지속되는 장기전
- **PvP 아레나**: AI 대 AI 자동 시뮬레이션 (플레이어는 사전 준비만)
- **시즌 보스**: 주간 순위제, 길드 협력 콘텐츠

---

## 디버깅 도구

### 개발자용 콘솔 커맨드

```gdscript
# debug_commands.gd

func _input(event):
    if not OS.is_debug_build(): return
    
    if event is InputEventKey:
        match event.keycode:
            KEY_F1:
                kill_all_enemies()  # 즉시 승리
            KEY_F2:
                heal_all_party()    # 전체 회복
            KEY_F3:
                toggle_ai_debug()   # AI 결정 로그 표시
            KEY_F4:
                speed_up_100x()     # 최고속 테스트
```

### 전투 리플레이

```gdscript
class_name BattleRecorder
extends Node

var action_log: Array[Dictionary] = []

func record_action(turn: int, actor: String, action: String, result: Dictionary):
    action_log.append({
        "turn": turn,
        "timestamp": Time.get_unix_time_from_system(),
        "actor": actor,
        "action": action,
        "result": result
    })

func export_replay() -> String:
    return JSON.stringify(action_log)
```

---

## 기술 사양

### 최소 사양
- **엔진**: Godot 4.2+
- **해상도**: 1280x720 (모바일), 1920x1080 (PC)
- **동시 전투 유닛**: 최대 8v8 (16체)
- **파티클**: 동시 50개 이하 유지

### 파일 구조

```
res://
├── systems/
│   ├── combat/
│   │   ├── TurnManager.gd
│   │   ├── Combatant.gd
│   │   ├── AutoBattleAI.gd
│   │   └── BattleAction.gd
│   ├── skills/
│   │   ├── SkillDatabase.gd
│   │   └── SkillEffect.gd
│   └── rendering/
│       ├── CombatRenderer.gd
│       ├── DamageLabel.gd
│       └── CameraController.gd
├── scenes/
│   ├── combat/
│   │   ├── CombatScene.tscn
│   │   ├── CombatantDisplay.tscn
│   │   └── EffectParticles.tscn
│   └── ui/
│       ├── SpeedControlButton.tscn
│       └── BattleLogPanel.tscn
└── resources/
    ├── skills/
    ├── status_effects/
    └── ai_personalities/
```

---

## 참고 자료

### 디자인 영감
- **Loop Hero**: 자동 전투의 간결함
- **Idle Heroes**: 시각적 피드백의 풍부함
- **Darkest Dungeon**: 스트레스/포지션 시스템
- **Slay the Spire**: 턴제 전투의 전략성

### 최적화 참고
- Godot Docs: Object Pooling Best Practices
- Mobile Game Optimization Guide (GDQuest)
- "Frame Budget" 개념 적용 (16.6ms per frame @ 60fps)
