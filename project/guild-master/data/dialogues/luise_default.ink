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

안녕하세요, 길드마스터님. 무슨 일이신가요? # speaker=루이제

* 그냥 안부를 물으러 왔다
  감사합니다. 저는... 여기서 일하는 게 익숙해졌어요. # speaker=루이제
  -> END

* 오늘 일은 어때?
  손님도 많고, 바쁘긴 하지만... 그래도 괜찮아요. # speaker=루이제
  -> END

* 다음에 다시 올게
  네, 조심히 다녀오세요. # speaker=루이제
  -> END

-> END
