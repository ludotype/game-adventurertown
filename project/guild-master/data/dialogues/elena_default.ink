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

좋은 아침이에요. 아직은 임시 대화지만, 이제 NPC를 클릭하면 대화가 열리네요. # speaker=엘레나

* 지금 시간이 어떻게 되지?
	시간은 화면 왼쪽 위에 표시되고 있어. # speaker=선생
	시간이 흐르면 제가 다른 장소에 등장하도록 만들 수 있어요. # speaker=엘레나

* 잠시 이야기한다
	~ advance_time(1)
	짧은 대화였지만, 시간은 흘렀어요. # speaker=엘레나

* 그만 간다
	필요하면 다시 말을 걸어 주세요. # speaker=엘레나

-> END
