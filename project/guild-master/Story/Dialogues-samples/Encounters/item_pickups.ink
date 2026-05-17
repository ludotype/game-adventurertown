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

-> pickup_slippers
=== pickup_slippers ===

// TODO: convert conditional block starting: if InventoryManager.has_item("it_slippers")
// if InventoryManager.has_item("it_slippers")
// 	(더 이상 이곳에는 쓸만한 물건이 없는 것 같다.) [ID:item_pick_slip_already]
// 	do EncounterManager.finish_encounter()
// 	=> END

// (린넨실 구석, 세탁물 더미 사이에 낡은 슬리퍼 한 켤레가 놓여 있다.) [ID:item_pick_slip_desc]
// - 슬리퍼를 챙긴다 [ID:item_pick_slip_opt_get]
// 	(슬리퍼를 가방에 넣었다. 무언가 기묘한 느낌이 들지만, 쓸모가 있을 것 같다.) [ID:item_pick_slip_act_get]
// 	do InventoryManager.add_item("it_slippers")
// 	do EncounterManager.finish_encounter()
// - 그냥 둔다 [ID:item_pick_slip_opt_leave]
// 	do EncounterManager.finish_encounter()
-> END
