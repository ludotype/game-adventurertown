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

-> ask_call_elevator
=== ask_call_elevator ===

엘리베이터를 부를까? # id=elv_call_01
* 부른다 # id=elv_call_opt_1
	[wait 0.5]
	(......)
	[wait 1.0]
	(띵-)
	// 현재 플레이어가 있는 위치에 기반하여 엘리베이터를 부릅니다.
	// TODO: manual convert: do ElevatorManager.call_to_location(LocationManager.current_location_id)
	엘리베이터가 도착했다. # id=elv_call_02
* 부르지 않는다 # id=elv_call_opt_2
	-> END

-> END
