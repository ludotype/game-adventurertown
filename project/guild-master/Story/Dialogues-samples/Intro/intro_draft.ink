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

VAR sanity = 0

-> intro_event
=== intro_event ===

// 지배인 닉네임 설정
// TODO: manual convert: do Nickname.set_nickname("Morigan", "NICK_OWNER")
// TODO: manual convert: do Nickname.set_nickname("Player", "NICK_PLAYER")

// 모리건 등장 연출 (티징)
 # scgc=slideup_morigan_tease

Hmm... So you are the new Night Auditor? # id=intro_01 # speaker=Morigan
You have a rather... [b]delicious[/b] looking soul. Fufu. # id=intro_02 # speaker=Morigan

// 모리건 오너 소개 (미소)
 # scgc=hop_morigan_smile
Nice to meet you. I am the owner of this hotel, [b]Morigan[/b]. # id=intro_03 # speaker=Morigan
Well, none of your predecessors lasted more than 3 days... I wonder how long you will endure? Good luck~ # id=intro_04 # speaker=Morigan

* { sanity > 50 } Leave it to me. # id=intro_opt_1
	// TODO: manual convert: do Flags.sanity += 10
	 # scgc=hop_morigan_smile
	Oh? I like your confidence. Let's see how long that attitude lasts. # id=intro_05 # speaker=Morigan
	

* ...Is it dangerous? # id=intro_opt_2
	// TODO: manual convert: do Flags.sanity -= 5
	 # scgc=0_morigan_tease
	Well? It depends on your definition of "dangerous". # id=intro_06 # speaker=Morigan
	Don't worry about ghosts. I absolutely hate those things. # id=intro_07 # speaker=Morigan

* I will get paid on time, right? # id=intro_opt_3
	 # scgc=sink_morigan_angry
	...Hah? Are you daring to question my financial status? # id=intro_08 # speaker=Morigan
	Of course you will! ...As long as Daddy doesn't cut off my cards. # id=intro_09 # speaker=Morigan

 # scgc=slideup_morigan_default
Now, get to work. Watch the phones, keep an eye out for weirdos. # id=intro_10 # speaker=Morigan
I'll be in the lounge on the 2nd floor. Don't call me unless it's an emergency. # id=intro_11 # speaker=Morigan

-> END
