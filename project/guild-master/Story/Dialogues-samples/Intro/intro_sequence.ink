EXTERNAL set_flag(key, value)
EXTERNAL set_metric(key, value)
EXTERNAL change_metric(key, amount)
EXTERNAL advance_time(time_units)
EXTERNAL advance_minutes(minutes)
EXTERNAL sleep_until_next_day()
EXTERNAL add_item(item_id, amount)
EXTERNAL remove_item(item_id, amount)
EXTERNAL equip_item(item_id)
EXTERNAL unequip_item(item_id)
EXTERNAL move(target_place)
EXTERNAL log(message)
EXTERNAL add_condition(condition_id, duration, stack)
EXTERNAL remove_condition(condition_id)
EXTERNAL change_doom(amount)
EXTERNAL block_place(place_id, reason)
EXTERNAL unblock_place(place_id)
EXTERNAL trigger_game_over(reason, game_over_type)
EXTERNAL open_ui(ui_name)
EXTERNAL random_loot(table_id)
EXTERNAL trigger_mandatory(trigger_on)
EXTERNAL start_dialogue(dialogue_id)
EXTERNAL set_nickname(character_name, nickname)
EXTERNAL play_sfx(sound_name)

-> start
=== start ===

// 서막: 버려진 도시의 밤
// BGM: 무거운 빗소리나 적막한 앰비언트 권장
... # id=seq_01
Another rejection email. # id=seq_02
That makes twenty-three this month. # id=seq_03

// 배경 전환: 구인 구직 사이트 화면 (job_site)
 # scgc=slideup_job_site
"Experience required for entry level"... "Must be willing to work 24/7"... "Unpaid internship"... # id=seq_04 # speaker=Player
Is there no place in this city that just needs a warm body? # id=seq_05 # speaker=Player

// 연출: 화면의 구석진 곳이 빛나며 강조 (호텔 모건 구인 광고)
...Wait. What's this? # id=seq_06 # speaker=Player

// 배경 전환: 호텔 모르가나 구인 광고 (job_ad)
 # scgc=slideup_job_ad
Hotel Morgana. Night Auditor Wanted. Immediate Start. High Pay. No Questions Asked. # id=seq_07 # speaker=Player
No interview? Just "Come tonight at 10 PM"? # id=seq_08 # speaker=Player
...It sounds shady as hell. # id=seq_09 # speaker=Player
But look at that salary. # id=seq_10 # speaker=Player

* { true } Apply. # id=seq_opt_1
	I have no choice. Rent is due in three days. # id=seq_11 # speaker=Player

// 배경 전환: 밤길을 달리는 버스 창가 (bus_ride)
 # scgc=slideup_bus_ride
The hotel is located way out in the suburbs. # id=seq_12 # speaker=Player
The bus is empty. The streets are empty. It feels like I'm leaving the world behind. # id=seq_13 # speaker=Player

// 배경 전환: 호텔 모르가나의 웅장한 외관 (hotel_exterior)
 # scgc=slideup_hotel_exterior
There it is. Hotel Morgana. # id=seq_14 # speaker=Player
It looks... older than I expected. And bigger. # id=seq_15 # speaker=Player
Well, no turning back now. # id=seq_16 # speaker=Player

// 인트로 종료 -> ActionScene 전환 대기
-> END
