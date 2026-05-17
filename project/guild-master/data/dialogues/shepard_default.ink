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

...무슨 일이지? # speaker=셰퍼드

* 마을의 안전 상태는 어떤가?
  최근 들어 이상한 소문이 많아. 밤에는 외출을 삼가는 게 좋을 거다. # speaker=셰퍼드
  -> END

* 신고할 것이 있다
  낮에는 경비대 본부로, 밤에는 급한 경우만 찾아오게. # speaker=셰퍼드
  -> END

* 그냥 지나가겠다
  ...조심하라고. # speaker=셰퍼드
  -> END

-> END
