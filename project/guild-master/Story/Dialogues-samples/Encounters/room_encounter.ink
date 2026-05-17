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

VAR current_guest_personality = 0
VAR current_room_id = 0
VAR enc_is_room_occupied = 0
VAR has_entity = 0

-> room_door_start
=== room_door_start ===

// EncounterManager에서 이미 Flags에 필요한 데이터를 주입했습니다.
// Flags.current_room_id, Flags.enc_is_room_occupied, Flags.has_entity 등을 사용합니다.

// TODO: convert conditional block starting: if Flags.enc_is_room_occupied:
// if Flags.enc_is_room_occupied:
// 	# [CASE 1: 투숙객이 있는 경우]
// 	# if GuestManager.has_unresolved_complaint(Flags.current_room_id):
// 	# 	선생: (이 방의 손님이 컴플레인을 넣었었지...)
// 	# 	- [Address the Complaint]
// 	# 		선생: 실례합니다, 호텔 직원입니다. 컴플레인 건으로 방문했습니다.
// 	# 		=> END
// 	# 	- 떠난다
// 	# 		=> END

// 	if Utils.random() < 0.5:
// 		선생: 여기에 볼 일은 없다.
// 	else:
// 		선생: 이런 늦은 시각에 손님 방에 노크할 이유는 없어.
// 	=> END

// TODO: manual convert conditional: else:
	// [CASE 2: 빈 방인 경우]
	// TODO: convert conditional block starting: if Utils.random() < 0.5:
	// if Utils.random() < 0.5:
// 		선생: 빈 방이다.
	// TODO: manual convert conditional: else:
		이렇게 빈 방이 남으면 손해인데, 모리건은 관심 없는 걸까. # speaker=선생
	

	* 노크한다
		// TODO: convert conditional block starting: if Flags.has_entity:
		// if Flags.has_entity:
// 			# 안에서 무언가 반응이 있는 경우 (Squatter / Entity)
// 			do AudioManager.play_sfx("knock_wood")
// 			...
// 			선생: (......!)
// 			선생: (안에서 작게 대답하는 소리가 들린 것 같다. 아니, 거꾸로 노크하는 소리였나?)
		// TODO: manual convert conditional: else:
			// 아무도 없는 경우
			// TODO: manual convert: do AudioManager.play_sfx("knock_wood")
			// TODO: convert conditional block starting: if Utils.random() < 0.5:
			// if Utils.random() < 0.5:
// 				선생: 아무 반응이 없다.
			// TODO: manual convert conditional: else:
				누가 안에서 대답하면 무서울 거야. # speaker=선생
		-> room_door_start
		

	* 문을 열고 들어간다
		(마스터키로 문을 열고 들어간다.) # speaker=선생
		// TODO: manual convert: do LocationManager.move_to(Flags.current_room_id)
		-> END
		

	* 떠난다
		-> END

=== phone_complaint_start ===
(데스크 전화기가 울린다.) # speaker=선생
리셉션입니다. 무엇을 도와드릴까요? # speaker=선생
// TODO: convert conditional block starting: if Flags.current_guest_personality == "grumpy":
// if Flags.current_guest_personality == "grumpy":
// 	투숙객: 지금 제정신입니까? 복도가 너무 시끄러워서 잠을 못 자겠어요!
// TODO: manual convert conditional: elif Flags.current_guest_personality == "scared":
	저... 실례합니다. 자꾸 문 밖에서 누가 지켜보는 것 같은 소리가 들려요... # speaker=투숙객
// TODO: manual convert conditional: else:
	실례지만 복도 관리를 조금만 더 신경 써주실 수 있을까요? 소음이 심하네요. # speaker=투숙객
* 알겠습니다. 즉시 확인해 보겠습니다.
	불편을 드려 죄송합니다. 바로 현장을 확인해 보겠습니다. # speaker=선생
	// TODO: manual convert: do GuestManager.resolve_complaint(Flags.current_room_id)
* [Ignore] 그럴 리가 없습니다. 기분 탓이겠죠.
	호텔 내부 점검 결과 특이 사항은 없었습니다. 안심하고 주무십시오. # speaker=선생
	// TODO: manual convert: do GuestManager.add_stress(Flags.current_room_id, 10.0)
-> END

-> END
