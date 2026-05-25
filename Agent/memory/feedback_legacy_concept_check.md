---
name: Legacy Concept Check
description: CLAUDE.md 및 프로젝트 메모리의 레거시 컨셉/아키텍처 정보를 확인하는 원칙
type: feedback
---

# 레거시 컨셉 확인 필수

## 규칙
CLAUDE.md나 기존 메모리 파일의 "프로젝트 개요", "아키텍처", "컨셉" 섹션은 **피벗 이후에도 레거시 정보가 그대로 남아 있을 수 있다.** 이를 현재 상태로 blindly 신뢰하지 말 것.

## Why
CLAUDE.md 25줄에 "프린세스 메이커 스타일"이라는 피벗 이전 문구가 남아 있었고, architecture.md 473줄에도 `Princess Maker` 참조가 남아 있었다. 이를 현재 컨셉으로 착각하여 다이스 풀(Arkham Horror 스타일) 메카닉에 맞지 않는 "스케줄 기반 성장" 답변을 작성함. 사용자가 직접 지적하여 수정.

## How to apply
1. 답변/설계 시 CLAUDE.md의 "프로젝트 개요"만 보고 판단하지 말 것
2. `wiki/00_헌법/new_direction.md`, `wiki/00_헌법/architecture.md` 등 최신 기획 문서와 항상 교차 확인
3. 특히 메카닉, 컨셉, 장르 관련 정보는 `new_direction.md`가 우선
4. 메모리 저장/갱신 시에도 기존 파일이 outdated일 가능성을 염두에 둘 것
