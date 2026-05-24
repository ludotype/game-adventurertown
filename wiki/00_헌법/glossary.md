# 프로젝트 공식 용어 사전 (Glossary)

> 이 문서는 **City of Eldritch** 프로젝트의 공식 캐릭터명, 지명, 시스템 용어에 대한 한국어 및 영어 표준 표기법을 정리한 용어 사전입니다.
> 모든 개발 작업 및 대화 파일 작성 시 이 사전의 명칭과 식별자(ID)를 항상 최우선 참조하여 작성해 주십시오.

---

## 1. 지명 및 장소 (Places & Locations)

| 한국어 명칭 | 영어 명칭 (ID) | 구역 (District) | 비고 |
|---|---|---|---|
| **나틀락** | **Natlach** | - | 크툴루 신화의 아틀락 나챠에서 유래한 메인 고대 도시 명칭 (구 에밀도르) |
| 루이제의 여관 로비 | Lobby (`lobby`) | 북부 | 모험가 대기실 및 의뢰 접수. 루이제가 운영하는 여관 로비 |
| 골동품 상점 | Curio Shop (`curio_shop`) | 북부 | 고대 유물 및 신비 용품 거래 상점 |
| 경비대 | Guard Station (`guard_station`) | 북부 | 치안 유지 및 파멸 억제 공간 |
| 대도서관 | Grand Library (`grand_library`) | 대학가 | 고대 역사 및 금기 지식 보관 도서관 |
| 천문탑 | Astronomy Tower (`astronomy_tower`) | 대학가 | 별의 궤적 연구 및 파멸 예측 탑 |
| 도적들의 소굴 | Rogue's Den (`rogues_den`) | 슬럼가 | 범죄 조직 아지트 및 지하 투기장 |
| 부랑자 골목 | Beggar's Alley (`beggars_alley`) | 슬럼가 | 소외받은 이들의 거주지 및 정보 온상 |
| 폐양조장 & 마녀의 오두막 | Abandoned Distillery (`abandoned_distillery`) | 슬럼가 | 금기 주술 및 비약 조제 장소 |
| 성당 본당 | Cathedral Nave (`cathedral_nave`) | 대성당 구역 | 치유와 정화의 신앙 중심지 |
| 주요 대로 | Main Avenue (`main_avenue`) | 거리 | 도시 중심 동맥. 상대적으로 안전한 연결선 |
| 뒷골목 | Back Alley (`back_alley`) | 거리 | 범죄자와 사교도가 출몰하는 위험한 통로 |
| 하수도 입구 | Sewer Entrance (`sewer_entrance`) | 거리 | 지하 던전으로 통하는 입구 |

---

## 2. 캐릭터 (Characters)

### 2.1 정적 NPC (Static NPCs)

| 한국어 이름 | 영어 이름 (ID) | 위치 (Location) | 주 역할 (Role) |
|---|---|---|---|
| **루이제** | **Luise** | 여관 로비 (`lobby`) | 여관 주인, 객실 휴식 조율 및 전체 위기 퀘스트 안내 |
| **셰퍼드** | **Shepard** | 경비대 (`guard_station`) | 경비대원, 단서 토큰 수집을 통한 도시 파멸도(Doom) 하락 |
| **경비대장** | **Guard Captain** | 경비대 (`guard_station`) | 경비대 지휘관, 고난이도 치안 퀘스트 발행 |
| **신부** | **Priest** | 성당 본당 (`cathedral_nave`) | 성직자, 치유/정화 및 정보원 |
| **수녀** | **Nun** | 성당 본당 (`cathedral_nave`) | 소문통, 고해성사 이벤트 제공 |
| **골동품 상인** | **Curio Dealer** | 골동품 상점 (`curio_shop`) | 유물 감정 및 희귀 아이템 판매 |
| **마녀** | **Witch** | 폐양조장 (`abandoned_distillery`) | 금기 주술 연구자, 비약 조제 및 상태 면역 버프 |

### 2.2 자율 액터 (NPA: Non-Playable Actors)

| 한국어 이름 | 영어 이름 (ID) | 주 활동 영역 | 캐릭터 성향 및 클래스 |
|---|---|---|---|
| **마슈** | **Marsh** | 경비대, 주요 대로 | 호탕한 전사 (Warrior), 잦은 유적 출입, 부상(Wounded) 잦음 |
| **렐리아나** | **Relliana** | 성당 본당, 주요 대로 | 차분한 신관 (Cleric), 고성공률 탐사, 축복(Blessed) 버프 공유 |
| **케이** | **Kay** | 뒷골목, 도적들의 소굴 | 냉소적인 도적 (Rogue), 높은 기동력, 단서(Clue) 공유 조건 까다로움 |

---

## 3. 핵심 시스템 용어 (Core Systems)

| 한국어 명칭 | 영어 명칭 (ID) | 설명 |
|---|---|---|
| **단서 토큰** | **Clue Token** | 엘드리치 호러식 단서 자원. 위기 해결 및 파멸 억제에 소모됨 |
| **상태 카드** | **Condition Card** | 수치적 정신력을 완전 배제하고 심리/육체적 영구 장해를 주는 카드 시스템 |
| **행동력** | **AP (Action Points)** | 하루 단위 시간 및 탐색 진행에 사용되는 핵심 자원 |
| **스태미나** | **Stamina** | 육체적 피로도 지표. 바닥나면 `탈진한(exhausted)` 카드를 획득함 |
| **도시 파멸도** | **Doom Level** | 도시가 파멸로 다다르는 글로벌 파멸 게이지 수치 |
| **도시 소보** | **TownNews** | 매일 아침 NPA들의 던전 모험 성공/실패 여부를 알리는 시스템 메일 큐 |

---

*문서 버전: 2.0 (피벗 후 재작성)*
*최종 업데이트: 2026-05-24*
