extends "res://tests/m9_reward_upgrade_audio_test.gd"
const OUT := "res://reports/upgrade_shimmer/"

func capture(label: String) -> void:
	if OS.get_cmdline_user_args().has("--visual"):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+label+".png")

func await_cue(count: int) -> void:
	var deadline := Time.get_ticks_msec()+8000
	while audio.magic_find_sfx_play_count < count and Time.get_ticks_msec()<deadline:
		await process_frame
	check(audio.magic_find_sfx_play_count==count,"cue occurs at scheduled glint peak")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1600,900)
	root.content_scale_size=Vector2i(1600,900)
	root.theme=load("res://assets/ui_theme.tres")
	state=root.get_node("BuildState")
	audio=root.get_node("AudioManager")
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	var registry := BuildContentRegistry.adventure()
	assert(state.configure_ranked_build(registry.trees["tree.bladedancer"]))
	screen=load("res://scenes/combat/combat_screen.tscn").instantiate()
	root.add_child(screen)
	await settle()
	for field in ["_contract_overlay","_map_overlay","_story_overlay","_talent_overlay","_secondary_subclass_overlay"]:screen.get(field).hide()
	var natural := gear("shimmer.natural",[GearItem.Tier.BASIC,GearItem.Tier.MASTER,GearItem.Tier.EPIC])
	var magic := gear("shimmer.magic",[GearItem.Tier.BASIC,GearItem.Tier.MASTER],true)
	var unchanged := gear("shimmer.unchanged",[GearItem.Tier.BASIC])
	state.shop_round_pending=true
	state.gold=1000
	state.shop_offers.assign([natural,magic,unchanged])
	var before: int=audio.magic_find_sfx_play_count
	screen._show_shop_overlay()
	await settle()
	var a: Control=screen._shop_overlay._upgrade_cards[natural.id]
	var b: Control=screen._shop_overlay._upgrade_cards[magic.id]
	var c: Control=screen._shop_overlay._upgrade_cards[unchanged.id]
	var pos := a.position
	await await_cue(before+1)
	check(a.has_node("GearUpgradeEffect") and not b.has_node("Icon"),"first shop card upgrades while future card remains hidden")
	check(not c.has_node("GearUpgradeEffect"),"unchanged future card has no shimmer")
	var shared_script = a.get_node("GearUpgradeEffect").get_script()
	check(a.position==pos and a.scale==Vector2.ONE,"upgrade does not move or enlarge shop card")
	await capture("shop_first_peak")
	await await_cue(before+2)
	await capture("shop_second_tier_peak")
	await await_cue(before+3)
	check(b.has_node("GearUpgradeEffect") and b.get_node("GearUpgradeEffect").get_script()==shared_script,"MF shop item uses same effect after first item settles")
	await capture("shop_second_item_peak")
	await wait_shop_complete()
	screen._shop_overlay.refresh()
	await create_timer(0.7).timeout
	check(audio.magic_find_sfx_play_count==before+3,"purchase-style refresh cannot repeat upgrade")
	screen._shop_overlay.hide()
	before=audio.magic_find_sfx_play_count
	state.pending_reward_choices.assign([natural,magic,unchanged])
	screen._show_reward_choice_overlay()
	if DisplayServer.get_name()=="headless": screen._play_reward_choice_reveal(screen._reward_choice_reveal_generation)
	await await_cue(before+1)
	var button: Button=screen._reward_choice_reveal_buttons[0]
	check(button.has_node("GearUpgradeEffect") and button.get_node("GearUpgradeEffect").get_script()==shared_script,"rewards use exactly the shop effect component")
	check(button.scale==Vector2.ONE,"reward upgrade does not enlarge card")
	await capture("reward_first_peak")
	await await_cue(before+2)
	await capture("reward_second_tier_peak")
	await wait_until_complete()
	check(audio.magic_find_sfx_play_count==before+3,"two natural tiers and one MF tier each cue once")
	await capture("reward_completed")
	screen.queue_free()
	await settle()
	print("PASS shared shop/reward shimmer integration" if failures.is_empty() else "FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
