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

VAR has_manual = 0

-> start
=== start ===

// 서막: 호텔 모르가나의 야간 관리인 (Prologue: The Night Manager of Hotel Morgana)

// 배경: 스태프 룸 (Staff Room)
 # scgc=slideup_placeholder_staffroom
// TODO: manual convert: do Nickname.set_nickname("Morigan", "Morigan")
// TODO: manual convert: do Nickname.set_nickname("Player", "NICK_PLAYER")

Staff Room, Hotel Morgana. Late night. # id=pro_01
The room is cramped, smelling of stale coffee and old paper. Through the half-open door, the polished mahogany of the front desk is visible. # id=pro_02

Eric's jacket is still draped over the back of a chair, as if he'll be back any second. But we both know he won't. # id=pro_03

Hey, Are you listening to me? # id=pro_04 # speaker=Morigan

Morigan is leaning against a stack of filing cabinets, her arms crossed. She looks completely out of place in this dingy backroom. # id=pro_05

* Sorry, you were saying? # id=pro_opt_1
	Morigan sighs, clearly annoyed that I'm not paying attention. # id=pro_06

I am *not* accepting your resignation. Not after Eric decided this is a good time to have an 'accident'. # id=pro_07 # speaker=Morigan

* But that's exactly why I want to leave. # id=pro_opt_2
	I try to argue that I don't want to stay and go through whatever Eric has experienced down there. # id=pro_08

Oh, please. What's the big drama? He went missing for an hour and turned up in the basement. # id=pro_09 # speaker=Morigan
The man probably tripped and got turned around in the dark. It’s a maze down there, nothing more. # id=pro_10 # speaker=Morigan

* He looked like he’d been wandering for weeks, not an hour... # id=pro_opt_3
	I describe how gaunt and dehydrated he looked, like the life had been sucked right out of him. # id=pro_11

It’s the boiler room, darling! It’s a furnace in there. Of course he’d look a bit... weathered. A glass of water and a nap, and he'll be fine. # id=pro_12 # speaker=Morigan

She says it with a sharp confidence, but I catch the way her gaze wavers momentarily. # id=pro_13

Look, I get it. You're a bit rattled. # id=pro_14 # speaker=Morigan
I can't let you quit... not when I'm this close to selling off this money-pit. I won't let a 'staffing crisis' tank the inspection. # id=pro_15 # speaker=Morigan
There's a mystery guest lurking around, and everything depends on them not noticing a single whiff of chaos. If they report 'instability', the buyers will walk. # id=pro_16 # speaker=Morigan

* You're selling the hotel? # id=pro_opt_4
	Yes. Who'd have known that running a hotel would be this boring and, most importantly, costly!? # id=pro_17 # speaker=Morigan
	The 'Mistress of the Grand Morgana' had a nice ring to it, but the novelty has worn thin. I've had enough of 'upholding the legacy'. # id=pro_18 # speaker=Morigan
	Maybe I'll open a high-end boutique in the capital after this. Something that doesn't involve managing a literal maze of rooms. # id=pro_19 # speaker=Morigan

Three nights. That's all I need from you. # id=pro_20 # speaker=Morigan

* And do what? # id=pro_opt_5
	I dunno! Just keep the lights on and the smiles fake until the inspection is over. # id=pro_21 # speaker=Morigan
	After that, you can stay, quit, go wherever you want. But until then, you aren't going anywhere. # id=pro_22 # speaker=Morigan

Without waiting for a response, she pivots on her heels, her heels clicking sharply against the linoleum floor as she exits the staff room. # id=pro_23
A moment later, the roar of an engine fades into the winter night. # id=pro_24

// --- 파트 2 ---

Silence returns to the staff room, heavier than before. # id=pro_25
My eyes fall on the desk. Amidst the clutter of receipts and half-empty mugs, there's a leather-bound folder I've never seen before. # id=pro_26

Eric always kept it locked in the top drawer. Now, the drawer is hanging open. # id=pro_27

* [Pick up Eric's Manual] # id=pro_opt_6
	// TODO: manual convert: do Flags.has_manual = true
	The moment my fingers touch the worn leather, the old vacuum-tube TV in the corner hums to life. # id=pro_28

Static flickers across the screen, then settles into a high-contrast, grainy cartoon. # id=pro_29

 # scgc=slideup_placeholder_tv_bellhop
A cheerful, bobble-headed bellhop character appears on the screen, waving frantically. The music is a tinny, upbeat orchestral track from the 40s. # id=pro_30

Greetings, New Recruit! Welcome to the Grand Morgana family! # id=pro_31 # speaker=Cartoon Bellhop
Being a Night Manager is a snap! Just follow these simple rules to ensure a 'Splendid Stay' for our guests! # id=pro_32 # speaker=Cartoon Bellhop

 # scgc=hop_placeholder_tv_grime
RULE 1: Keep it Tidy! A clean hotel is a happy hotel. Don't let the grime settle! # id=pro_33 # speaker=Cartoon Bellhop

 # scgc=slideup_placeholder_tv_vigilant
RULE 2: Stay Vigilant! Patrol the hotel, and keep an eye out for anything that doesn't feel right. # id=pro_34 # speaker=Cartoon Bellhop

 # scgc=hop_placeholder_tv_fixit
**RULE 3: FIX IT.** If something looks odd, out of place, or just plain 'wrong'... put it back where it belongs! No questions asked! # id=pro_35 # speaker=Cartoon Bellhop

 # scgc=slideup_placeholder_tv_connected
RULE 4: Stay Connected! If the desk phone rings, it means somebody's got a request to make! # id=pro_36 # speaker=Cartoon Bellhop

* We don't have that. # id=pro_opt_7
	 # scgc=hop_placeholder_tv_annoyed
	Oh, right. Kids these days have a... what's that? A smartie phone. Eh, it's all the same. Check your little 'app' on your 'phone', then. # id=pro_37 # speaker=Cartoon Bellhop

 # scgc=slideup_placeholder_tv_close
Now, for the finishing touch! A manager isn't a manager without his authority! # id=pro_38
Reach out and take it! Put on the badge of the Grand Hotel Morgana Night Manager! # id=pro_39 # speaker=Cartoon Bellhop

The TV screen stays on, showing the Bellhop pointing directly at the desk in front of me. # id=pro_40
A silver badge, tarnished but still gleaming, has appeared where the manual was. # id=pro_41

* [Pick up the Manager's Badge] # id=pro_opt_8
	// TODO: manual convert: do InventoryManager.add_item("it_managers_badge")
	[Open your INVENTORY to view the badge. Select 'EQUIP' to officially begin your shift.] # id=pro_42 # speaker=System

// [개발 노트] 장비 장착 대기 로직은 이후 아이템 시스템 연동 시 구현
Splendid! You look just like the real thing! Welcome aboard, Manager! We're *so* glad you're staying with us. # id=pro_43 # speaker=Cartoon Bellhop

The TV screen cuts to black with a sharp 'pop'. # id=pro_44
The room is quiet again, but the silver badge feels heavy on my chest. # id=pro_45

The exit is right there. Time to see what's actually waiting in the lobby. # id=pro_46

-> END
