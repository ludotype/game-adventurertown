# 🧹 Wiki Document Cleanup & Project Pivot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clean up all legacy design concepts (Dating sim, Time Units, Sanity metrics) across the `wiki/` directory to completely align the documentation with the pivoted "City of Eldritch" Cosmic Horror Roguelite RPG (`new_direction.md`).

**Architecture:** Mark outdated GDDs as archived/deprecated with standard warning boxes. Completely refactor `planner_guide.md`, `ink_guide.md`, and `dungeon_exploration.md` to delete `player.sanity` and replace legacy `time_units` with `spend_ap` / `Movement` points in all examples.

**Tech Stack:** Markdown, GFM, Shell scripts.

---

## 🛠️ Boundary Map & Audit Checklist

We will audit and align the following files:

| Path | Current State | Target State |
|---|---|---|
| `wiki/00_헌법/game_concept.md` | Dating sim GDD | **[ARCHIVED]** banner + redirect to `new_direction.md` |
| `wiki/00_헌법/new_direction_quiz.md` | Brainstorming quiz with Sanity | **[ARCHIVED]** banner + deprecated note |
| `wiki/01_시스템/ink_guide.md` | Outdated `sanity` & `advance_time` examples | Refactored to use `stamina` and `spend_ap` in code blocks |
| `wiki/02_콘텐츠/planner_guide.md` | References to `player.sanity` & `time_units` | Refactored to use `player.stamina` and `spend_ap` / `Movement` |
| `wiki/01_시스템/dungeon_exploration.md` | Legacy `player.sanity` reduction | Refactored to `player.stamina` |

---

## 📋 Implementation Tasks

### Task 1: Deprecate Legacy GDDs & Quiz

**Files:**
- Modify: `wiki/00_헌법/game_concept.md`
- Modify: `wiki/00_헌법/new_direction_quiz.md`

- [ ] **Step 1: Add Archive warning block to game_concept.md**

  Open `wiki/00_헌법/game_concept.md` and add the standard legacy alert banner at the very top:

  ```markdown
  # ⚠️ [ARCHIVED/LEGACY] Guild Master - 게임 컨셉트 문서
  
  > [!WARNING]
  > **본 문서는 과거 데이트 시뮬레이션 및 레거시 시간/정신력 시스템 설계안이며, 현재는 아카이빙된 레거시 기획서입니다.**  
  > **최신 행동력(AP), 야간 단계, 상태 카드 기반의 턴제 코스믹 호러 RPG 게임 루프는 [[new_direction]] 문서를 전적으로 참고해 주십시오.**
  ```

- [ ] **Step 2: Add Archive warning block to new_direction_quiz.md**

  Open `wiki/00_헌법/new_direction_quiz.md` and add the legacy warning banner at the top to clarify that the brainstormed answers have been fully absorbed and pivoted in `new_direction.md`.

  ```markdown
  # ⚠️ [ARCHIVED/LEGACY] City of Eldritch — GDD 완성 퀴즈
  
  > [!WARNING]
  > **본 문서는 초기 기획 완성 및 조율을 위해 활용되었던 퀴즈 및 답변 자료로, 현재는 아카이빙된 레거시 문서입니다.**  
  > **정신력(Sanity) 수치가 완전히 제거되고 개별 상태 카드(Condition Cards) 및 행동력(AP) 시스템으로 전환된 최신 스펙은 [[new_direction]] 문서를 전적으로 참고해 주십시오.**
  ```

- [ ] **Step 3: Commit Task 1 Changes**

  `git add wiki/00_헌법/game_concept.md wiki/00_헌법/new_direction_quiz.md`
  `git commit -m "docs(archive): deprecate legacy game_concept.md and GDD quiz"`

---

### Task 2: Align Ink Scripting Guide (Metric & API Sanitization)

**Files:**
- Modify: `wiki/01_시스템/ink_guide.md`
- Modify: `wiki/01_시스템/dungeon_exploration.md`

- [ ] **Step 1: Replace Sanity with Stamina and update time functions in ink_guide.md**

  Edit `wiki/01_시스템/ink_guide.md` to completely eliminate any tutorial blocks or examples referencing `sanity` and `advance_time`.

  * *Replace:*
  ```ink
  ~ change_metric("sanity", -5)
  ~ change_metric("sanity", 10)
  ~ set_metric("sanity", 50)
  VAR sanity = 50
  EXTERNAL advance_time(time_units)
  ```
  * *With:*
  ```ink
  ~ change_metric("stamina", -5)
  ~ change_metric("stamina", 10)
  ~ set_metric("stamina", 100)
  VAR stamina = 100
  EXTERNAL spend_ap(amount)
  ```

- [ ] **Step 2: Replace player.sanity in dungeon_exploration.md**

  Edit `wiki/01_시스템/dungeon_exploration.md` and update the legacy sanity metric reduction at line 122.
  * *Replace:* `~ change_metric("player.sanity", -2)`
  * *With:* `~ change_metric("player.stamina", -2)`

- [ ] **Step 3: Commit Task 2 Changes**

  `git add wiki/01_시스템/ink_guide.md wiki/01_시스템/dungeon_exploration.md`
  `git commit -m "docs(pivot): align Ink guides with stamina and spend_ap metrics"`

---

### Task 3: Align Planner Guide (Full Spec Synchronization)

**Files:**
- Modify: `wiki/02_콘텐츠/planner_guide.md`

- [ ] **Step 1: Sanitize player.sanity and player.san in planner_guide.md**

  Open `wiki/02_콘텐츠/planner_guide.md` and search for all instances of `player.sanity` and `player.san`. Replace them with `player.stamina` and explain that Sanity has been completely replaced by custom Condition Cards (like `인지 왜곡`, `정신 쇠약`).

- [ ] **Step 2: Deprecate legacy time_units in action definitions**

  Update the action reference tables in `planner_guide.md` to remove `time_units` properties, replacing them with `spend_ap` and `Movement` points in all JSON example snippets.

- [ ] **Step 3: Commit Task 3 Changes**

  `git add wiki/02_콘텐츠/planner_guide.md`
  `git commit -m "docs(pivot): sanitize player.sanity and time_units in planner_guide.md"`

---

## 🧪 Verification Plan

### Automated Text Audit Script
- Create verification script: `project/guild-master/tools/audit_wiki_pivot.py`
- This python script scans the entire `wiki/` directory and asserts that no active/non-archived files contain clashing metrics like `player.sanity` or `time_units` without a deprecated mark.

```python
# project/guild-master/tools/audit_wiki_pivot.py
import os
import sys

TARGET_DIR = "wiki/"
ILLEGAL_METRICS = ["player.sanity", "player.san", "time_units"]

def audit():
    errors = 0
    for root, dirs, files in os.walk(TARGET_DIR):
        for file in files:
            if file.endswith(".md"):
                path = os.path.join(root, file)
                with open(path, "r", encoding="utf-8") as f:
                    content = f.read()
                
                # Skip officially archived files
                if "[ARCHIVED/LEGACY]" in content or "아카이빙된 레거시" in content:
                    continue
                
                for metric in ILLEGAL_METRICS:
                    if metric in content:
                        print(f"ERROR: Legacy metric '{metric}' found in active file: {path}")
                        errors += 1
                        
    if errors > 0:
        print(f"AUDIT FAILED: Found {errors} occurrences of legacy metrics in active wiki files!")
        sys.exit(1)
    else:
        print("AUDIT SUCCESS: All active wiki files are perfectly sanitized and pivoted!")
        sys.exit(0)
```

Run Python CLI:
`python project/guild-master/tools/audit_wiki_pivot.py`
Expected output:
`AUDIT SUCCESS: All active wiki files are perfectly sanitized and pivoted!`
