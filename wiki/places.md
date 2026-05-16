# 장소 목록 및 아트 에셋 요구사항

> 현재 게임에 등록된 모든 장소(Place)와 각 장소에 필요한 아트 에셋, BGM, 배치 NPC를 정리한 문서입니다.
> 기획자와 아티스트가 "앞으로 뭘 그려야 할지" 확인하기 위한 체크리스트입니다.

---

## 현재 지도 구조

```
[여관방] — [복도] — [여관 로비] — [남쪽 거리] — [중앙 광장]
                                            |            |
                                         [무기상]    [북쪽 거리] — [선술집]
                                                       |            |
                                                    [꽃집]    [고대 유적]
                                                                  |
                                                              [서쪽 거리] — [경비대 본부]
```

---

## 1. 마을 내 장소 (Town)

### 1.1 여관방 (`inn_room`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/inn_room.png` | ✅ 배경 일러스트 |
| `bgm` | `inn_calm` | ✅ BGM |
| `empty_weight` | 100 | — |
| `connections` | `hallway` | — |
| 배치 NPC | 없음 (플레이어 전용) | — |
| 행동 | 잠자기, 소지품 확인, 둘러보기 | — |

### 1.2 복도 (`hallway`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/hallway.png` | ✅ 배경 일러스트 |
| `bgm` | (지정 없음, 로비와 동일 또는 무음) | □ BGM (선택) |
| `empty_weight` | 100 | — |
| `connections` | `inn_room`, `lobby` | — |
| 배치 NPC | 없음 | — |
| 행동 | 둘러보기, 잠시 기다리기 | — |

### 1.3 여관 로비 (`lobby`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/lobby.png` | ✅ 배경 일러스트 |
| `bgm` | (지정 없음) | □ BGM (선택) |
| `empty_weight` | 0 | — |
| `connections` | `hallway`, `street_south` | — |
| 배치 NPC | 루이제 (아침 업무 중) | 루이제 스탠딩 CG, 표정 변화 |
| 행동 | 둘러보기 | — |

### 1.4 남쪽 거리 (`street_south`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/street_south.png` | ✅ 배경 일러스트 |
| `bgm` | `town_day` | ✅ BGM |
| `empty_weight` | 100 | — |
| `connections` | `lobby`, `town_square`, `weapon_shop` | — |
| 배치 NPC | 무기상 주인 (예정) | □ NPC 초상화 |
| 행동 | 둘러보기 | — |

### 1.5 중앙 광장 (`town_square`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/town_square.png` | ✅ 배경 일러스트 |
| `bgm` | `town_day` | ✅ BGM |
| `empty_weight` | 8 | — |
| `connections` | `street_south`, `street_north`, `street_west` | — |
| 배치 NPC | 엘레나, 꽃집 주인, 기타 마을 NPC | □ 엘레나 초상화, □ 꽃집 주인 초상화 |
| 행동 | 둘러보기 | — |

### 1.6 북쪽 거리 (`street_north`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/street_north.png` | ✅ 배경 일러스트 |
| `bgm` | `town_day` | ✅ BGM |
| `empty_weight` | 10 | — |
| `connections` | `town_square`, `tavern`, `flower_shop`, `dungeon_01` | — |
| 배치 NPC | 없음 | — |
| 행동 | 둘러보기, 고대 유적으로 들어간다 | — |

### 1.7 서쪽 거리 (`street_west`) — **신규 추가**

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/street_west.png` | ❌ **배경 일러스트 (필요)** |
| `bgm` | `town_day` | ✅ BGM (중앙 광장과 공유 가능) |
| `empty_weight` | 12 | — |
| `connections` | `town_square`, `guard_hq` | — |
| 배치 NPC | 셰퍼드 (저녁 순찰) | ❌ **셰퍼드 초상화 (필요)** |
| 행동 | 둘러보기, 경비대 본부로 들어간다 | — |

### 1.8 선술집 (`tavern`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/tavern.png` | ✅ 배경 일러스트 |
| `bgm` | `tavern_evening` | ✅ BGM |
| `empty_weight` | 2 | — |
| `connections` | `street_north` | — |
| 배치 NPC | 루이제 (저녁/밤), 기타 NPC | 루이제 스탠딩 CG |
| 행동 | 둘러보기 | — |
| **특이사항** | 위기 "nightmare_town" 파멸 시 `block_place`로 봉쇄됨 | □ 봉쇄 상태 배경 (선택) |

### 1.9 무기상 (`weapon_shop`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/weapon_shop.png` | ✅ 배경 일러스트 |
| `bgm` | (지정 없음) | □ BGM (선택) |
| `empty_weight` | 0 | — |
| `connections` | `street_south` | — |
| 배치 NPC | 무기상 주인 | □ NPC 초상화 |
| 행동 | 둘러보기 | — |

### 1.10 꽃집 (`flower_shop`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/flower_shop.png` | ✅ 배경 일러스트 |
| `bgm` | (지정 없음) | □ BGM (선택) |
| `empty_weight` | 0 | — |
| `connections` | `street_north` | — |
| 배치 NPC | 꽃집 주인 | □ NPC 초상화 |
| 행동 | 둘러보기 | — |

### 1.11 경비대 본부 (`guard_hq`) — **신규 추가**

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/guard_hq.png` | ❌ **배경 일러스트 (필요)** |
| `bgm` | `guard_hq` | ❌ **BGM (필요)** |
| `empty_weight` | 0 | — |
| `connections` | `street_west` | — |
| 배치 NPC | 셰퍼드 (아침/오후/밤) | ❌ **셰퍼드 초상화 (필요)** |
| 행동 | 둘러보기, 잠시 기다리기 | — |

---

## 2. 던전 장소 (Dungeon)

### 2.1 고대 유적 (`dungeon_01`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/dungeon_01.png` | ❌ **배경 일러스트 (필요)** |
| `bgm` | `dungeon_ambient` | ❌ **BGM (필요)** |
| `empty_weight` | 100 | — |
| `connections` | `street_north` | — |
| 배치 NPC | 없음 | — |
| 행동 | 둘러보기, 깊숙이 탐험, 돌아가기 | — |
| **특이사항** | 전리품 테이블: `rusty_sword`, `potion`, `holy_symbol` | — |

---

## 3. 향후 추가 예정 장소 (Backlog)

| 장소 ID | 예상 이름 | 설명 | 필요 에셋 |
|---------|----------|------|----------|
| `dungeon_02` | 하수도 | 쥐떼와 곰팡이가 있는 어두운 하수도 | 배경, BGM, 몬스터 스프라이트 |
| `dungeon_03` | 폐교회 | 신관 렐리아나 관련 의뢰 장소 | 배경, BGM |
| `tavern_blocked` | (봉쇄된 선술집) | `nightmare_town` 파멸 시 교체 배경 | 봉쇄 상태 배경 (선택) |
| `elena_house` | 엘레나의 집 | 엘레나 호감도 이벤트용 | 배경 (선택) |
| `luise_room` | 루이제의 방 | 친밀 단계 이벤트용 | 배경 (선택) |

---

## 4. 아트 에셋 체크리스트

### 배경 일러스트 (Background)

- [x] `assets/bg/inn_room.png`
- [x] `assets/bg/hallway.png`
- [x] `assets/bg/lobby.png`
- [x] `assets/bg/street_south.png`
- [x] `assets/bg/town_square.png`
- [x] `assets/bg/street_north.png`
- [x] `assets/bg/tavern.png`
- [x] `assets/bg/weapon_shop.png`
- [x] `assets/bg/flower_shop.png`
- [ ] `assets/bg/street_west.png` — **신규 필요**
- [ ] `assets/bg/guard_hq.png` — **신규 필요**
- [ ] `assets/bg/dungeon_01.png` — **신규 필요**
- [ ] `assets/bg/dungeon_02.png` — 향후
- [ ] `assets/bg/dungeon_03.png` — 향후

### NPC 초상화 (Portrait)

- [ ] `assets/portraits/luise.png` — 히로인, 최우선
- [ ] `assets/portraits/elena.png`
- [ ] `assets/portraits/rock.png`
- [ ] `assets/portraits/shepard.png` — **신규 필요 (경비대장)**
- [ ] `assets/portraits/weapon_shop_owner.png`
- [ ] `assets/portraits/flower_shop_owner.png`

### 아이템 아이콘 (Item Icon)

- [ ] `assets/icons/holy_symbol.png`
- [ ] `assets/icons/potion.png`
- [ ] `assets/icons/rusty_sword.png`
- [ ] `assets/icons/condition_haunted.png`

### BGM

- [x] `inn_calm`
- [x] `town_day`
- [x] `tavern_evening`
- [ ] `guard_hq` — **신규 필요**
- [ ] `dungeon_ambient` — **신규 필요**

---

**문서 버전**: 1.0
**최종 업데이트**: 2026-05-16
