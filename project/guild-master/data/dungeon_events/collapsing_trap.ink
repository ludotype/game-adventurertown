EXTERNAL roll_2d6(bonus)
EXTERNAL change_metric(key, amount)
EXTERNAL add_condition(condition_id, duration, stack)
EXTERNAL advance_time(time_units)
EXTERNAL log(message)

=== start ===
바닥이 불안정하게 떨린다. 얇은 석판 아래로 어둠이 깔려 있다. 함정이다.

* [달려서 건너뛴다]
	~ temp result = roll_2d6(0)
	{ result >= 10:
		발딱 일어나 장판 끝까지 달렸다. 바닥이 무너지는 순간 안전한 곳에 착지했다.
		~ advance_time(1)
		-> next_event
	- else:
		{ result >= 7:
			간신히 뛰어넘었지만, 발목을 삐끗했다. 일단 걸을 수는 있다.
			~ change_metric("player.hp", -3)
			~ add_condition("sprained_ankle", -1, 1)
			~ log("collapsing_trap: partial success, sprained ankle")
			-> next_event
		- else:
			뛰는 순간 바닥이 꺼졌다. 엉덩이를 크게 다쳤다.
			~ change_metric("player.hp", -12)
			~ change_metric("dungeon.progress", -2)
			~ log("collapsing_trap: failure, fell through")
			-> retreat
		}
	}

* [조심스럽게 옆으로 돌아간다]
	시간은 더 걸리지만 안전하게 우회하기로 했다.
	~ advance_time(2)
	-> next_event

=== next_event ===
-> END

=== retreat ===
-> END
