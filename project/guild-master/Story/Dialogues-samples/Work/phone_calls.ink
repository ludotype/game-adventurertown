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

-> phone_call_generic
=== phone_call_generic ===
선생님, 전화가 왔어요.
-> START

=== START ===
~ set_flag("phone_ringing", true)
전화벨이 울린다...
-> phone_ringing

=== phone_ringing ===
전화를 받으시겠습니까?
-> ANSWER_PHONE
-> IGNORE_PHONE

=== ANSWER_PHONE ===
~ set_flag("phone_ringing", false)
// TODO: manual convert: do TimeManager.add_minutes(2)
네, 호텔 모르가나입니다.
-> call_response

=== IGNORE_PHONE ===
// TODO: manual convert: do TimeManager.add_minutes(1)
전화를 무시했다. 벨소리가 멈췄다.
~ set_flag("phone_ringing", false)
-> END

=== call_response ===
{~ -> call_guest_complaint | -> call_room_service | -> call_maintenance | -> call_mysterious }

=== call_guest_complaint ===
안녕하세요, 2층 복도에 이상한 소리가 들려요... # speaker=손님
~ set_flag("phone_ringing", false)
// TODO: manual convert: do TaskManager.add_task_from_dialogue("task_complaint_2f", "SERVICE", "loc_corridor_2f_main", "2층 복도 소음 확인")
알겠습니다. 바로 확인하겠습니다.
-> END

=== call_room_service ===
룸 서비스 좀 부탁드려요... # speaker=손님
~ set_flag("phone_ringing", false)
// TODO: manual convert: do TaskManager.add_task_from_dialogue("task_room_service", "SERVICE", "loc_room_2f_205", "룸 서비스 요청")
네, 바로 준비하겠습니다.
-> END

=== call_maintenance ===
3층 화장실 수도꼭지가 고장났어요. 확인 부탁드립니다. # speaker=관리실
~ set_flag("phone_ringing", false)
// TODO: manual convert: do TaskManager.add_task_from_dialogue("task_maintenance_3f", "REPAIR", "loc_toilet_3f", "3층 화장실 수리")
알겠습니다. 수리팀에 연락하겠습니다.
-> END

=== call_mysterious ===
... ... ...
~ set_flag("phone_ringing", false)
// TODO: manual convert: do GameManager.take_damage(5)
이상한 침묵이 흐른다. 전화가 끊겼다.
-> END

=== END ===
~ set_flag("phone_ringing", false)
대화 종료
