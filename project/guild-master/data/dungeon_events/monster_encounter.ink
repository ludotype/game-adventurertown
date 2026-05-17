EXTERNAL roll_2d6(bonus)
EXTERNAL change_metric(key, amount)
EXTERNAL add_condition(condition_id, duration, stack)
EXTERNAL advance_time(time_units)
EXTERNAL log(message)
EXTERNAL add_item(item_id, amount)

=== start ===
~ temp result = 0
어둠 속에서 래틀링의 치열한 소리가 들린다. 뼈마개 한 무리가 앞을 가로막고 있다.

* [숨어서 살핀 뒤 빈틈을 지나간다]
	~ result = roll_2d6(0)
	{ result >= 10:
		그림자에 몸을 숨기고 숨을 죽였다. 래틀링들은 지나가는 소리에 정신이 팔려, 틈새로 조용히 빠져나갔다.
		~ advance_time(1)
		~ log("monster_encounter: stealth full success")
		-> next_event
	- else:
		{ result >= 7:
			대부분은 지나갔지만, 맨 끝 래틀링 하나가 날카로운 손톱으로 팔을 할퀴었다.
			~ change_metric("player.hp", -6)
			~ add_condition("bleeding", 3, 1)
			~ log("monster_encounter: stealth partial success, scratched")
			-> next_event
		- else:
			발밑에 돌멩이를 차는 바람에 래틀링 전체가 돌아섰다. 죽음의 소리가 귓가를 채운다.
			~ change_metric("player.hp", -15)
			~ change_metric("player.sanity", -5)
			~ log("monster_encounter: stealth failure, attacked")
			-> retreat
		}
	}

* [횃불을 휘두르며 위협한다]
	~ result = roll_2d6(1)
	{ result >= 10:
		횃불을 세차게 내저으며 소리쳤다. 래틀링들은 불을 두려워하는지, 쩍벌거리며 물러섰다.
		~ advance_time(1)
		~ add_item("bone_fragment", 1)
		~ log("monster_encounter: intimidate success, collected bone_fragment")
		-> next_event
	- else:
		{ result >= 7:
			횃불이 래틀링 하나를 그을렸지만, 나머지가 달려들었다. 간신히 물리쳤지만 녹초가 됐다.
			~ change_metric("player.hp", -8)
			~ change_metric("player.sanity", -3)
			~ advance_time(2)
			~ log("monster_encounter: intimidate partial success, exhausted")
			-> next_event
		- else:
			횃불이 역풍에 꺼져버렸다. 어둠 속에서 뼈마개들이 달려들었다.
			~ change_metric("player.hp", -18)
			~ change_metric("player.sanity", -8)
			~ log("monster_encounter: intimidate failure, torch extinguished")
			-> retreat
		}
	}

* [후퇴한다]
	숫자가 너무 많다. 무리하지 않기로 했다.
	-> retreat

=== next_event ===
-> END

=== retreat ===
-> END
