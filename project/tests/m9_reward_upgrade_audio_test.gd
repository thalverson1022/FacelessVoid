extends SceneTree

var failures: Array[String] = []
var state: Node
var audio: Node
var screen: Control

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for i in 5: await process_frame

func gear(id: String, tiers: Array[int], magic_find: bool = false) -> GearItem:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var item := GearGenerator.generate(tiers[-1], GearItem.SlotType.WEAPON, rng, id)
	item.reward_base_tier = tiers[0]
	item.reward_tier_steps = tiers
	item.reward_magic_find_upgraded = magic_find
	return item

func begin_reveal(items: Array[GearItem]) -> void:
	state.pending_reward_choices.assign(items)
	screen._show_reward_choice_overlay()
	# Headless entry intentionally skips animation; explicitly drive the same
	# production coroutine on its real overlay/buttons to exercise timed beats.
	if DisplayServer.get_name() == "headless":
		screen._play_reward_choice_reveal(screen._reward_choice_reveal_generation)

func wait_until_complete() -> Array[String]:
	var seen: Array[String] = []
	var deadline := Time.get_ticks_msec() + 6000
	while screen._reward_choice_reveal_active and Time.get_ticks_msec() < deadline:
		for effect in screen._reward_choice_overlay.find_children("GearUpgradeEffect", "Control", true, false):
			if not seen.has(effect.name): seen.append(effect.name)
		await process_frame
	check(not screen._reward_choice_reveal_active, "Real reveal sequence completes")
	return seen

func wait_shop_complete() -> void:
	var deadline := Time.get_ticks_msec() + 12000
	while screen._shop_overlay.is_busy() and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not screen._shop_overlay.is_busy(), "Sequential shop reveal completes")

func run() -> void:
	await process_frame
	state = root.get_node("BuildState")
	audio = root.get_node("AudioManager")
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	screen = load("res://scenes/combat/combat_screen.tscn").instantiate()
	root.add_child(screen)
	await settle()
	for field in ["_contract_overlay", "_map_overlay", "_story_overlay", "_talent_overlay", "_secondary_subclass_overlay"]:
		screen.get(field).hide()
	var natural := gear("audio.natural", [GearItem.Tier.BASIC, GearItem.Tier.MASTER, GearItem.Tier.EPIC])
	var magic := gear("audio.magic", [GearItem.Tier.BASIC, GearItem.Tier.MASTER], true)
	var unchanged := gear("audio.unchanged", [GearItem.Tier.BASIC])
	var before: int = audio.magic_find_sfx_play_count
	begin_reveal([natural, magic, unchanged])
	var labels := await wait_until_complete()
	check(labels.has("GearUpgradeEffect"), "Timed natural/MF reveal uses shared upgrade animation")
	check(audio.magic_find_sfx_play_count == before + 3, "Each of two natural beats and one MF beat sounds exactly once")
	for button in screen._reward_choice_reveal_buttons:
		check(not button.disabled, "Completed reveal enables actual reward buttons")
	before = audio.magic_find_sfx_play_count
	begin_reveal([unchanged])
	await wait_until_complete()
	check(audio.magic_find_sfx_play_count == before, "An unchanged reward has no upgrade cue")
	begin_reveal([natural])
	screen._finish_reward_choice_reveal()
	await create_timer(1.0).timeout
	check(audio.magic_find_sfx_play_count == before, "Skip before first beat suppresses the entire sequence")
	begin_reveal([natural])
	var deadline := Time.get_ticks_msec() + 3000
	while audio.magic_find_sfx_play_count == before and Time.get_ticks_msec() < deadline:
		await process_frame
	check(audio.magic_find_sfx_play_count == before + 1, "First natural upgrade plays during actual animation")
	screen._finish_reward_choice_reveal()
	await create_timer(0.7).timeout
	check(audio.magic_find_sfx_play_count == before + 1, "Skip after first beat suppresses remaining beats")
	for player in audio._magic_find_sfx_players:
		check(not player.playing, "Skip cancels active upgrade tails")
	before = audio.magic_find_sfx_play_count
	begin_reveal([natural])
	screen._reward_choice_overlay.hide()
	await create_timer(1.0).timeout
	check(audio.magic_find_sfx_play_count == before and not screen._reward_choice_reveal_active, "Closing invalidates delayed beats")
	state.shop_round_pending = true
	state.gold = 100
	state.shop_offers.assign([natural])
	screen._show_shop_overlay()
	await settle()
	await wait_shop_complete()
	check(audio.magic_find_sfx_play_count == before + 2, "Natural shop offer cues each recorded upgrade")
	screen._shop_overlay.refresh()
	await settle()
	check(audio.magic_find_sfx_play_count == before + 2, "Shop refresh never repeats an upgrade")
	screen._shop_overlay.hide()
	state.shop_offers.assign([unchanged])
	screen._show_shop_overlay()
	await settle()
	await wait_shop_complete()
	check(audio.magic_find_sfx_play_count == before + 2, "Unchanged shop offers remain silent")
	screen.queue_free()
	await settle()
	if failures.is_empty(): print("PASS: actual natural/MF reward sequence, no-upgrade, skip, close and shop upgrade audio")
	else: print("FAILED: ", failures)
	quit(0 if failures.is_empty() else 1)
