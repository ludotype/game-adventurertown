# Import Batch 3 - 누락된 번역 및 Core 스크립트

## 에러 요약
다음 파일들이 누락되어 Godot 프로젝트가 실행되지 않음:

### 1. 번역 파일 (Translation Files)
**경로:** `assets/translations/`

| 파일 | 설명 |
|------|------|
| `dialogue/common_strings.en.translation` | 공통 문자열 영어 |
| `dialogue/common_strings.ko.translation` | 공통 문자열 한국어 |
| `dialogue/common_strings.ja.translation` | 공통 문자열 일본어 |
| `dialogue/intro.en.translation` | 인트로 영어 |
| `dialogue/intro.ko.translation` | 인트로 한국어 |
| `dialogue/intro.ja.translation` | 인트로 일본어 |
| `dialogue/elevator_interior.en.translation` | 엘리베이터 영어 |
| `dialogue/elevator_interior.ko.translation` | 엘리베이터 한국어 |
| `dialogue/elevator_interior.ja.translation` | 엘리베이터 일본어 |
| `dialogue/room_encounters.en.translation` | 랜덤 조우 영어 |
| `dialogue/room_encounters.ko.translation` | 랜덤 조우 한국어 |
| `dialogue/room_encounters.ja.translation` | 랜덤 조우 일본어 |
| `dialogue/complaints.en.translation` | 불만처리 영어 |
| `dialogue/complaints.ko.translation` | 불만처리 한국어 |
| `dialogue/complaints.ja.translation` | 불만처리 일본어 |
| `ui/ui_common.en.translation` | UI 공통 영어 |
| `ui/ui_common.ko.translation` | UI 공통 한국어 |
| `ui/ui_common.ja.translation` | UI 공통 일본어 |

### 2. Core Manager 스크립트
**경로:** `scripts/core/`

| 파일 | 설명 | Autoload 이름 |
|------|------|---------------|
| `balance_config.gd` | 게임 밸런스/설정값 | Config |
| `location_manager.gd` | 위치/맵 관리 | LocationManager |
| `log_manager.gd` | 게임 로그 | LogManager |
| `time_manager.gd` | 게임 시간 | TimeManager |
| `guest_manager.gd` | 손님 관리 | GuestManager |
| `encounter_manager.gd` | 랜덤 조우 관리 | EncounterManager |
| `entity_manager.gd` | 엔티티 관리 | EntityManager |
| `game_manager.gd` | 메인 게임 관리 | GameManager |

---

## Import 단계

### 단계 1: 파일 복사
`filestoimport/import3/`의 모든 내용을 대상 프로젝트 루트로 복사:

```bash
# 폴더 구조 유지하며 복사
cp -r filestoimport/import3/assets/translations/* [프로젝트]/assets/translations/
cp -r filestoimport/import3/scripts/core/* [프로젝트]/scripts/core/
```

### 단계 2: Autoload 등록 확인
Project Settings → Autoload 탭에서 다음이 등록되어 있는지 확인:

```
Config → res://scripts/core/balance_config.gd
LocationManager → res://scripts/core/location_manager.gd
LogManager → res://scripts/core/log_manager.gd
TimeManager → res://scripts/core/time_manager.gd
GuestManager → res://scripts/core/guest_manager.gd
EncounterManager → res://scripts/core/encounter_manager.gd
EntityManager → res://scripts/core/entity_manager.gd
GameManager → res://scripts/core/game_manager.gd
```

### 단계 3: Internationalization 설정
Project Settings → Internationalization → Translations:

다음 파일들이 등록되어 있는지 확인:
```
res://assets/translations/dialogue/common_strings.en.translation
res://assets/translations/dialogue/common_strings.ko.translation
res://assets/translations/dialogue/common_strings.ja.translation
res://assets/translations/dialogue/intro.en.translation
res://assets/translations/dialogue/intro.ko.translation
res://assets/translations/dialogue/intro.ja.translation
res://assets/translations/dialogue/elevator_interior.en.translation
res://assets/translations/dialogue/elevator_interior.ko.translation
res://assets/translations/dialogue/elevator_interior.ja.translation
res://assets/translations/dialogue/room_encounters.en.translation
res://assets/translations/dialogue/room_encounters.ko.translation
res://assets/translations/dialogue/room_encounters.ja.translation
res://assets/translations/dialogue/complaints.en.translation
res://assets/translations/dialogue/complaints.ko.translation
res://assets/translations/dialogue/complaints.ja.translation
res://assets/translations/ui/ui_common.en.translation
res://assets/translations/ui/ui_common.ko.translation
res://assets/translations/ui/ui_common.ja.translation
```

---

## 의존성 관계

복사된 스크립트들은 다음 의존성을 가짐:

### game_manager.gd
- `SettingsManager` (설정 로드/저장)
- `LocationManager` (위치 전환)
- `SaveManager` (저장/불러오기)
- `BGMManager` (배경음악)

### location_manager.gd
- `GameFlags` (위치 잠금/해제)
- `LogManager` (이동 로깅)

### guest_manager.gd
- `GameFlags` (손님 상태)
- `TimeManager` (시간 체크)

### encounter_manager.gd
- `GuestManager` (손님 정보)
- `EntityManager` (엔티티 생성)
- `DialogueManager` (대화 트리거)

---

## 테스트 체크리스트

Import 후 확인:

- [ ] `balance_config.gd` 에러 없음
- [ ] `location_manager.gd` 에러 없음
- [ ] `log_manager.gd` 에러 없음
- [ ] `time_manager.gd` 에러 없음
- [ ] `guest_manager.gd` 에러 없음
- [ ] `encounter_manager.gd` 에러 없음
- [ ] `entity_manager.gd` 에러 없음
- [ ] `game_manager.gd` 에러 없음
- [ ] 번역 파일 로드 에러 없음
- [ ] 게임 정상 실행

---

## 참고사항

1. **.translation 파일**: Godot가 .csv나 .po 파일에서 자동 생성하는 바이너리 파일
2. **재생성 필요 시**: 원본 CSV/PO 파일이 있다면 Godot 에디터에서 Import 탭에서 재생성 가능
3. **폴더 구조**: `assets/translations/dialogue/`와 `assets/translations/ui/` 폴더가 반드시 존재해야 함
