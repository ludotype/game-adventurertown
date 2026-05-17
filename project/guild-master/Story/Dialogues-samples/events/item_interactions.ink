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

-> linen_room_slippers
=== linen_room_slippers ===

// TODO: convert conditional block starting: if InventoryManager.has_item("slippers"):
// if InventoryManager.has_item("slippers"):
// 	선생: (더 이상 챙길 슬리퍼는 없는 것 같다.)
// 	=> END

// 선생: (정리가 덜 된 린넨 더미 사이에서 깨끗한 슬리퍼 한 켤레를 발견했다.)
// - 가져간다
// 	do InventoryManager.add_item("slippers")
// 	선생: (슬리퍼를 챙겼다. 어딘가 쓸모가 있을지도 모른다.)
// - 그대로 둔다
// 	선생: (남의 물건에 손을 대는 건 합리적이지 않다.)

-> END

=== window_interaction ===

// TODO: convert conditional block starting: if LocationManager.get_location_resource(LocationManager.current_location_id).placed_item_id == "slippers":
// if LocationManager.get_location_resource(LocationManager.current_location_id).placed_item_id == "slippers":
// 	선생: (창틀에 슬리퍼가 가지런히 놓여 있다. 달빛을 받아 기괴한 분위기를 풍긴다.)
// 	- 다시 챙긴다
// 		do InventoryManager.add_item("slippers")
// 		set LocationManager.get_location_resource(LocationManager.current_location_id).placed_item_id = ""
// 		선생: (슬리퍼를 다시 회수했다.)
// 	- 그대로 둔다
// 		선생: (이대로 두면 무언가 일어날지도 모른다.)
// 	=> END

// 선생: (어두운 밖이 내다보이는 창문이다. 호텔의 정적만이 느껴진다.)
// TODO: convert conditional block starting: if InventoryManager.has_item("slippers"):
// if InventoryManager.has_item("slippers"):
// 	- 창틀에 슬리퍼를 올린다
// 		do InventoryManager.use_item("slippers")
// 		set LocationManager.get_location_resource(LocationManager.current_location_id).placed_item_id = "slippers"
// 		선생: (슬리퍼를 창틀에 올렸다. 기묘한 전설이 현실이 되지 않기를 빌자.)
// 	- 그냥 지나간다
// 		=> END
// TODO: manual convert conditional: else:
	(창문 너머로는 아무것도 보이지 않는다.) # speaker=선생

-> END
