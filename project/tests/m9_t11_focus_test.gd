extends "res://tests/m9_log_tabs_test.gd"
const FOCUS_OUT := "res://reports/m9_t11_focus/"
var BuildState
var AudioManager

func shot(label: String) -> void:
	await settle()
	if OS.get_cmdline_user_args().has("--visual"):
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(FOCUS_OUT+label+".png") == OK)

func check_modal(screen: Control, modal: Control, label: String) -> void:
	modal.show()
	await settle()
	var top := screen.find_child("TopActionBar",true,false) as Control
	verify(top != null and modal.get_global_rect().position.y >= top.get_global_rect().end.y, "modal leaves system bar clear: "+label)
	var backdrop := modal.get_child(0) as Button
	verify(backdrop != null and not backdrop.flat, "normal modal backdrop is drawn")
	verify(is_equal_approx(backdrop.get_theme_stylebox("normal").bg_color.a,0.6), "transparent black fill")
	verify(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(modal.get_global_rect()), "modal within viewport")
	var panel: Control = modal.get_child(1).get_child(0)
	verify(panel.get_global_rect().position.y >= top.get_global_rect().end.y,"modal panel leaves system bar clear")
	verify(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(panel.get_global_rect()),"modal panel within viewport")
	await shot(label)
	modal.hide()
	await settle()

func run() -> void:
	BuildState = root.get_node("BuildState")
	AudioManager = root.get_node("AudioManager")
	DirAccess.make_dir_recursive_absolute(FOCUS_OUT)
	root.theme = load("res://assets/ui_theme.tres")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_new_game_pressed(1928)
	BuildState.set_class(load("res://data/classes/rogue.tres"))
	var registry := BuildContentRegistry.adventure()
	assert(BuildState.configure_ranked_build(registry.trees["tree.thief"]))
	game._show_combat_screen()
	await settle()
	var screen = game._current_screen
	for field in ["_contract_overlay","_map_overlay","_story_overlay","_talent_overlay","_secondary_subclass_overlay"]:
		screen.get(field).hide()
	for resolution in [Vector2i(1600,900),Vector2i(1280,720)]:
		root.size = resolution
		root.content_scale_size = resolution
		await settle()
		var label := "adventure_%dx%d" % [resolution.x,resolution.y]
		await check_modal(screen,screen._talent_overlay,label+"_talent")
		await check_modal(screen,screen._log_overlay,label+"_log")
		BuildState.shop_round_pending = true
		BuildState.gold = 100
		var offer: GearItem = load("res://data/gear/lucky_coin.tres").duplicate(true)
		offer.id = "focus.offer"
		BuildState.shop_offers.assign([offer])
		screen._show_shop_overlay()
		await settle()
		var dim = screen._shop_overlay._focus_dimmer
		var gear_rect: Rect2 = screen._gear_panel.get_global_rect()
		for region in dim._regions:
			if region.size.x <= 0 or region.size.y <= 0: continue
			verify(not region.get_global_rect().intersects(gear_rect), "shop leaves Gear clear")
			verify(region.get_global_rect().position.y >= screen.find_child("TopActionBar",true,false).get_global_rect().end.y,"shop leaves top bar clear")
		verify(not screen._shop_overlay._shop_offer_text(offer).contains("Bought items enter"),"removed redundant tooltip")
		await shot(label+"_shop")
		screen._shop_overlay.hide()
	# Sound routing: one new MF shop batch cue, no repeats on purchase refresh.
	var mf: GearItem = load("res://data/gear/lucky_coin.tres").duplicate(true)
	mf.id = "focus.mf.offer"
	mf.tier = GearItem.Tier.MASTER
	mf.reward_base_tier = GearItem.Tier.BASIC
	mf.reward_tier_steps.assign([GearItem.Tier.BASIC, GearItem.Tier.MASTER])
	mf.reward_magic_find_upgraded = true
	BuildState.shop_offers.assign([mf])
	var before: int = AudioManager.magic_find_sfx_play_count
	screen._show_shop_overlay()
	await settle()
	await create_timer(1.05).timeout
	verify(AudioManager.magic_find_sfx_play_count == before+1,"new MF shop batch sounds once")
	screen._shop_overlay.refresh()
	await settle()
	verify(AudioManager.magic_find_sfx_play_count == before+1,"refresh does not repeat MF sound")
	screen._shop_overlay.hide()
	var button := Button.new()
	screen.add_child(button)
	screen._play_reward_choice_upgrade(button,GearItem.Tier.MASTER)
	await create_timer(0.25).timeout
	verify(AudioManager.magic_find_sfx_play_count == before+2,"ordinary reward upgrade sounds")
	screen._play_reward_choice_upgrade(button,GearItem.Tier.EPIC)
	await create_timer(0.25).timeout
	verify(AudioManager.magic_find_sfx_play_count == before+3,"next rarity reward beat sounds")
	screen._finish_reward_choice_reveal()
	for player in AudioManager._magic_find_sfx_players: verify(not player.playing,"skip stops MF tails")
	game.queue_free()
	await settle()
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await settle()
	for resolution in [Vector2i(1600,900),Vector2i(1280,720)]:
		root.size = resolution
		root.content_scale_size = resolution
		await settle()
		var label := "practice_%dx%d" % [resolution.x,resolution.y]
		await check_modal(room,room._talent_overlay,label+"_talent")
		await check_modal(room,room._log_overlay,label+"_log")
	room.queue_free()
	await settle()
	print("PASS T11 focus: ",checks)
	quit()
