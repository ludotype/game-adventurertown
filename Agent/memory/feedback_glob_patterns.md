---
name: Glob Pattern Usage
description: Windows에서 Glob 패턴 사용 시 주의사항
type: feedback
---

# Glob 패턴 사용 규칙

## 규칙
Windows 환경에서 Glob 패턴 사용 시 **경로 시작에 `./`를 사용하지 않는다.**

## 문제 증상
- `"./Agent/memory/**/*.md"` → `No files found`
- `"Agent/memory/**/*.md"` → 정상 동작

## 원인
Glob 도구가 Windows에서 leading dot-slash를 처리하지 못함.

## 적용 방법
- ❌ `"./folder/**/*.md"`
- ✅ `"folder/**/*.md"`

**Why:** 2025-04-17 검색 실패 후 확인. CLI `ls`는 `./`로 동작하지만 Glob는 실패함.

**How to apply:** 모든 Glob 패턴에서 leading `./` 제거하고 상대 경로만 사용.
