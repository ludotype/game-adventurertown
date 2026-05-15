---
name: user_coding_style
description: 사용자의 코딩 스타일 및 포매터 선호도 (Python, GDScript)
type: user
---

# 사용자 코딩 스타일

## Python
- **포매터**: Black 사용
- 기본 설정 따름

## GDScript (Godot 4.x)
- **변수/함수**: snake_case (예: `player_health`, `get_input()`)
- **클래스/노드/파일명**: PascalCase (예: `class PlayerController`, `PlayerController.gd`)
- **상수**: UPPER_SNAKE_CASE (예: `MAX_SPEED`, `DEFAULT_HP`)
- **시그널**: snake_case (예: `signal health_changed`)
- **들여쓰기**: Tab 사용 (공백 4칸 대신)

## JavaScript/TypeScript
- **네이밍**: camelCase (GDScript와 구분하여 사용 시)
