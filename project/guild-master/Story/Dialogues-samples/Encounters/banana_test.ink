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

-> pickup_banana
=== pickup_banana ===

// TODO: convert conditional block starting: if InventoryManager.has_item("it_banana")
// if InventoryManager.has_item("it_banana")
// 	(데스크 위에 더 이상 남은 바나나가 없다.) [ID:item_pick_banana_already]
// 	do EncounterManager.finish_encounter()
// 	=> END

// (로비 데스크 구석에 노랗게 잘 익은 바나나가 놓여 있다. 누군가 먹으려고 둔 것 같다.) [ID:item_pick_banana_desc]
// - 바나나를 챙긴다 [ID:item_pick_banana_opt_get]
// 	(바나나를 주머니에 넣었다. 배가 고플 때 먹으면 좋을 것 같다.) [ID:item_pick_banana_act_get]
// 	do InventoryManager.add_item("it_banana")
// 	do EncounterManager.finish_encounter()
// - 그냥 둔다 [ID:item_pick_banana_opt_leave]
// 	do EncounterManager.finish_encounter()
-> END
