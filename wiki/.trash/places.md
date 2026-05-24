# ⚠️ [ARCHIVED/LEGACY] 장소 목록 및 아트 에셋 요구사항

> [!WARNING]
> **본 문서는 과거 레거시 시스템 기준의 장소 및 에셋 요구사항 정리서입니다.**  
> **최신 지역/장소 설정, 정적 NPC들의 역할 및 관련 이벤트 기획은 [[world_and_places]] 문서를 참고해 주십시오.**


---

## 현재 지도 구조

```
[여관방] — [복도] — [여관 로비] — [남쪽 거리] — [중앙 광장] — [치료소]
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
| sub_npcs | `[{ "npc_id":"stray_cat", "display_name":"a stray cat", "description":"curls up on the windowsill, purring softly." }]` | — |
| 정경 텍스트 | 기본: 낡지만 정갈한 여관 방... / morning: Morning light spills... / night: The room is lit only by... | — |
| 행동 | 쉬기 (HP 회복, `haunted` 시 악몽), 잠자고 하루 넘기기, 소지품 확인, 둘러보기 | — |

### 1.2 복도 (`hallway`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/hallway.png` | ✅ 배경 일러스트 |
| `bgm` | (지정 없음, 로비와 동일 또는 무음) | □ BGM (선택) |
| `empty_weight` | 100 | — |
| `connections` | `inn_room`, `lobby` | — |
| 배치 NPC | 없음 | — |
| 행동 | 둘러보기, 잠시 기다리기, 문 너머 소리 듣기 | — |

### 1.3 여관 로비 (`lobby`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/lobby.png` | ✅ 배경 일러스트 |
| `bgm` | (지정 없음) | □ BGM (선택) |
| `empty_weight` | 6 | — |
| `connections` | `hallway`, `street_south` | — |
| 배치 NPC | 루이제 (아침/오후) | 루이제 스탠딩 CG, 표정 변화 |
| 행동 | 둘러보기, 루이제와 이야기한다 | — |

### 1.4 남쪽 거리 (`street_south`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/street_south.png` | ✅ 배경 일러스트 |
| `bgm` | `town_day` | ✅ BGM |
| `empty_weight` | 100 | — |
| `connections` | `lobby`, `town_square`, `weapon_shop` | — |
| 배치 NPC | 무기상 주인 (예정) | □ NPC 초상화 |
| 행동 | 둘러보기, 바닥을 수색한다 | — |

### 1.5 중앙 광장 (`town_square`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/town_square.png` | ✅ 배경 일러스트 |
| `bgm` | `town_day` | ✅ BGM |
| `empty_weight` | 8 | — |
| `connections` | `street_south`, `street_north`, `street_west`, `clinic` | — |
| 배치 NPC | 엘레나, 꽃집 주인, 기타 마을 NPC | □ 엘레나 초상화, □ 꽃집 주인 초상화 |
| sub_npcs | `[{ "npc_id":"merchant", "display_name":"a tired merchant", "description":"counts copper coins with glazed eyes." }, { "npc_id":"dog", "display_name":"a stray dog", "description":"sniffs at a discarded fish bone." }]` | — |
| 정경 텍스트 | 기본: The town square bustles... / morning: Morning mist... / night: The square is nearly empty... | — |
| 행동 | 둘러보기 | — |

### 1.6 북쪽 거리 (`street_north`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/street_north.png` | ✅ 배경 일러스트 |
| `bgm` | `town_day` | ✅ BGM |
| `empty_weight` | 10 | — |
| `connections` | `town_square`, `tavern`, `flower_shop`, `dungeon_01` | — |
| 배치 NPC | 없음 | — |
| 행동 | 둘러보기, 고대 유적으로 들어간다, 유적을 멀리서 관찰한다 | — |

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
| 행동 | 둘러보기, 도박, 정보 수집 (술값 내고), 술 한 잔 | — |
| **특이사항** | 위기 "nightmare_town" 파멸 시 `block_place`로 봉쇄됨 | □ 봉쇄 상태 배경 (선택) |

### 1.9 무기상 (`weapon_shop`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/weapon_shop.png` | ✅ 배경 일러스트 |
| `bgm` | (지정 없음) | □ BGM (선택) |
| `empty_weight` | 0 | — |
| `connections` | `street_south` | — |
| 배치 NPC | 무기상 주인 | □ NPC 초상화 |
| 행동 | 둘러보기, 무기 수리, 무기 강화 (일시적) | — |

### 1.10 꽃집 (`flower_shop`)

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/flower_shop.png` | ✅ 배경 일러스트 |
| `bgm` | (지정 없음) | □ BGM (선택) |
| `empty_weight` | 0 | — |
| `connections` | `street_north` | — |
| 배치 NPC | 꽃집 주인 | □ NPC 초상화 |
| 행동 | 둘러보기, 꽃다발 구매 | — |

### 1.11 경비대 본부 (`guard_hq`) — **신규 추가**

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/guard_hq.png` | ❌ **배경 일러스트 (필요)** |
| `bgm` | `guard_hq` | ❌ **BGM (필요)** |
| `empty_weight` | 0 | — |
| `connections` | `street_west` | — |
| 배치 NPC | 셰퍼드 (아침/오후/밤) | ❌ **셰퍼드 초상화 (필요)** |
| 행동 | 둘러보기, 잠시 기다리기, 정보 수집, 구호 요청, 순찰대 동행, 추적자 조언 | — |

### 1.12 치료소 (`clinic`) — **신규 추가**

| 항목 | 현재 상태 | 필요 에셋 |
|------|----------|----------|
| `background_path` | `res://assets/bg/clinic.png` | ❌ **배경 일러스트 (필요)** |
| `bgm` | `town_day` | ✅ BGM (중앙 광장과 공유 가능) |
| `empty_weight` | 100 | — |
| `connections` | `town_square` | — |
| 배치 NPC | 없음 | — |
| 행동 | 둘러보기, 치료받기 (`injured` 회복, HP 회복) | — |

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

## 4. 장소 JSON 필드 정의

새 장소를 추가할 때 사용하는 공통 필드입니다.

| 필드 | 타입 | 설명 | 필수 |
|------|------|------|------|
| `place_id` | string | 고유 ID (파일명과 일치 권장) | O |
| `display_name` | string | 화면에 표시될 이름 | O |
| `description` | string | **기본 정경 텍스트** (시간대별 오버라이드가 없을 때 사용) | — |
| `descriptions` | object | **시간대별 정경 텍스트**. `morning`, `afternoon`, `evening`, `night` 등의 키 사용 | — |
| `sub_npcs` | array | **배경 NPC 목록**. `{ npc_id, display_name, description }` 형태 | — |
| `background_path` | string | 배경 이미지 리소스 경로 | — |
| `bgm` | string | 재생할 BGM ID | — |
| `empty_weight` | int | "아무도 없음" 가중치 (메인 NPC 미등장 확률 조절) | — |
| `connections` | string[] | 연결된 장소 ID 목록 | — |
| `tags` | string[] | 태그 (indoor, shop 등) | — |

> `sub_npcs`의 `description`은 문장 끝에 동사(~is here, ~counts coins) 형태로 작성합니다. 출력 시 `display_name + " " + description`으로 조합됩니다.

---

## 5. 아트 에셋 체크리스트

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
- [ ] `assets/bg/clinic.png` — **신규 필요**
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
- [ ] `assets/icons/flower_bouquet.png` — **신규 필요**

### BGM

- [x] `inn_calm`
- [x] `town_day`
- [x] `tavern_evening`
- [ ] `guard_hq` — **신규 필요**
- [ ] `dungeon_ambient` — **신규 필요**

---

**문서 버전**: 1.2
**최종 업데이트**: 2026-05-20
