extends Node
## 유틸리티 함수들을 제공하는 Autoload
## Dialogue Manager에서 전역 함수를 사용하기 위한 래퍼 제공

## 0.0에서 1.0 사이의 랜덤 float 반환
func random() -> float:
	return randf()

## min과 max 사이의 랜덤 int 반환 (max 포함)
func random_int(min_val: int, max_val: int) -> int:
	return randi_range(min_val, max_val)

## min과 max 사이의 랜덤 float 반환
func random_range(min_val: float, max_val: float) -> float:
	return randf_range(min_val, max_val)

## 확률 체크 (0.0 ~ 1.0)
func chance(probability: float) -> bool:
	return randf() < probability

## 배열에서 랜덤 요소 선택
func pick_random(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[randi() % array.size()]
