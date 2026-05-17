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
매뉴얼을 읽는다...
-> manual_content

=== manual_content ===
호텔 모르가나 야간 근무 매뉴얼

[기본 규칙]
1. 손님을 방해하지 마세요.
2. 모든 업무를 시간 내에 완료하세요.
3. 이상한 현상이 보이면 무시하세요.

[업무 처리]
* 전화: 데스크의 전화기를 통해 업무를 받습니다.
* 장부: 컴퓨터에서 일일 장부를 정리합니다.
* 청소: 지정된 장소를 청소합니다.

[주의사항]
밤 10시부터 아침 6시까지 근무합니다.
시간을 잘 관리하세요.
-> END
