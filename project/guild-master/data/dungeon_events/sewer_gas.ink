EXTERNAL roll_2d6(bonus)
EXTERNAL change_metric(key, amount)
EXTERNAL add_condition(condition_id, duration, stack)
EXTERNAL advance_time(time_units)
EXTERNAL log(message)

=== start ===
독가스가 퍼진 하수도 구간이다. 녹슨 배관에서 초록빛 증기가 피어오른다. 앞으로 나아갈까?

* [숨을 참고 빠르게 통과한다]
	~ temp result = roll_2d6(0)
	{ result >= 10:
		숨을 꾹 참고 무사히 통과했다. 가스는 발끝에서만 맴돌았다.
		~ advance_time(1)
		-> next_event
	- else:
		{ result >= 7:
			가스실을 통과하는 데는 성공했지만, 짙은 가스를 들이마셔 기침이 멈추지 않는다.
			~ change_metric("player.hp", -5)
			~ change_metric("player.sanity", -2)
			~ add_condition("poisoned", 3, 1)
			~ log("sewer_gas: partial success, gained poisoned")
			-> next_event
		- else:
			지독한 독가스에 정신을 잃을 뻔했다. 황급히 뒤로 물러날 수밖에 없었다.
			~ change_metric("player.hp", -10)
			~ change_metric("dungeon.progress", -1)
			~ log("sewer_gas: failure, retreated")
			-> retreat
		}
	}

* [돌아간다]
	뒤로 물러서기로 했다. 안전한 길을 다시 찾아보자.
	-> retreat

=== next_event ===
-> END

=== retreat ===
-> END
