# 프로젝트 의존성 구조

> **복사 가이드**: 이 폴더/파일만 복사하면 다른 프로젝트에서 동작합니다

## 레이어 구조 (의존성 방향: 아래 → 위)

```
Layer 4: game/              ← 프로젝트 고유 (복사 대상 아님)
        ↓ depends on
Layer 3: features/          ← 선택적 시스템
        ↓ depends on
Layer 2: systems/           ← 핵심 게임 시스템
        ↓ depends on
Layer 1: core/              ← 순수 유틸리티 (의존성 없음)
```

---

## Layer 1: Core (무조건 필요)

**경로**: `scripts/core/`, `scenes/ui/`

**파일**:
```
scripts/core/
├── utils.gd              (의존성: 없음)
├── game_flags.gd         (의존성: 없음)
├── settings_manager.gd   (의존성: 없음)
├── save_manager.gd       (의존성: settings_manager)
├── audio_manager.gd      (의존성: 없음)
└── bgm_manager.gd        (의존성: audio_manager)

scenes/ui/
├── splash_screen.tscn    (의존성: 없음)
├── title_screen.tscn     (의존성: settings_manager, bgm_manager)
├── settings_screen.tscn  (의존성: settings_manager)
├── save_load_screen.tscn (의존성: save_manager)
└── pause_menu.tscn       (의존성: settings_manager)
```

**복사 시 함께 필요**:
- `addons/dialogue_manager/` (외부 플러그인)
- `assets/fonts/` (UI 필수)
- `project.godot` (Autoload 설정)

---

## Layer 2: Systems (선택적)

**경로**: `scripts/systems/` (아직 없음)

**정의**: 핵심 게임 시스템. 프로젝트 성격에 따라 선택.

| 시스템 | 의존성 | 설명 |
|--------|--------|------|
| inventory_system | core/save_manager | 인벤토리 |
| time_system | core/game_flags | 게임 시간 |
| quest_system | core/save_manager | 퀘스트 |
| relationship_system | core/save_manager | 호감도 |

**복사 규칙**: `systems/` 폴더 전체 또는 필요한 것만 선택 복사

---

## Layer 3: Features (게임 타입별)

**경로**: `scripts/features/` (아직 없음)

**정의**: 특정 게임 장르에 특화된 기능.

| Feature | 대상 장르 | 의존성 |
|---------|----------|--------|
| visual_novel_mode | VN | systems/ |
| life_sim_mode | 라이프 심 | systems/time_system |
| rpg_battle | RPG | systems/inventory |

**복사 규칙**: 해당 장르만 복사

---

## Layer 4: Game (프로젝트 고유)

**경로**: `scripts/game/`, `scenes/game/`, `Story/`

**정의**: 실제 게임 콘텐츠. 템플릿에서 복사하지 않음.

```
scripts/game/
├── main_story.gd         (의존성: 모든 레이어)
└── characters/

scenes/game/
└── game_scene.tscn       (의존성: features/)

Story/
└── Dialogues/
```

---

## 복사 체크리스트

새 프로젝트 시작할 때:

### [ ] Step 1: Core 복사 (필수)
```
복사 대상:
├── scripts/core/
├── scenes/ui/
├── addons/dialogue_manager/
├── assets/fonts/
├── assets/translations/ (공통만)
└── project.godot (Autoload 설정 확인)
```

### [ ] Step 2: Systems 선택 (옵션)
```
복사 대상:
└── scripts/systems/ (필요한 것만)
```

### [ ] Step 3: Features 선택 (옵션)
```
복사 대상:
└── scripts/features/ (장르에 맞는 것만)
```

### [ ] Step 4: 프로젝트 설정
- `project.godot`에서 `config/name` 변경
- `assets/translations/`에서 프로젝트 이름/용어 수정
- `scenes/ui/`에서 타이틀 화면 디자인 변경

---

## 의존성 체크 스크립트

```gdscript
# scripts/editor/dependency_checker.gd (에디터 도구)
tool
extends EditorScript

func _run():
    check_dependency("scripts/core/bgm_manager.gd", "scripts/core/audio_manager.gd")
    check_dependency("scenes/ui/title_screen.tscn", "scripts/core/bgm_manager.gd")
    # ... 체크 목록
```

---

## 예시: 비주얼 노벨 프로젝트 복사

```bash
# 1. 템플릿 복사
cp -r template/ project_vn/

# 2. 불필요한 systems 제거
rm project_vn/scripts/systems/time_system/
rm project_vn/scripts/systems/inventory_system/

# 3. VN feature 추가
mkdir project_vn/scripts/features/visual_novel_mode/

# 4. Game 레이어 생성
mkdir project_vn/scripts/game/
mkdir project_vn/scenes/game/
mkdir project_vn/Story/Dialogues/
```

---

*마지막 수정: 2026-04-21*
