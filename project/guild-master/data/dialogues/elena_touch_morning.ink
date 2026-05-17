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

(나는 조심스럽게 엘레나의 소매 끝을 건드렸다.) # speaker=선생
어머, 무슨 일이세요? 아침이라 아직 조금 정신이 없네요. # speaker=엘레나

* 미안, 별일 아니야
	괜찮아요. 그래도 다음엔 먼저 말해 주세요. # speaker=엘레나

-> END
