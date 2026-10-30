extends "res://tests/m9_reward_upgrade_audio_test.gd"

const OUT := "res://reports/shop_sequential/"
var events: Array = []
var shop: Control
var initial_rects := {}

func payload() -> String:
	return JSON.stringify(SaveSystem._gear_list_to_data(state.shop_offers))

func capture(label: String) -> void:
	if OS.get_cmdline_user_args().has("--visual"):
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(OUT + label + ".png") == OK, "Rendered shop " + label)

func await_cue(count: int) -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while audio.magic_find_sfx_play_count < count and Time.get_ticks_msec() < deadline:
		await process_frame
	check(audio.magic_find_sfx_play_count == count, "Expected sequential peak cue arrives")

func inspect_peak(items: Array[GearItem]) -> void:
	var current := -1
	for index in items.size():
		if shop._revealed_ids.has(items[index].id): current = index
	check(current >= 0, "Sound belongs to a revealed card")
	if current < 0: return
	var card: Button = shop._upgrade_cards[items[current].id]
	var effect = card.get_node_or_null("GearUpgradeEffect")
	check(effect != null and effect._peak_played, "Sound is synchronized with current card shimmer")
	check(card.scale == Vector2.ONE, "Sequential upgrade leaves card scale unchanged")
	for index in items.size():
		var other: Button = shop._upgrade_cards[items[index].id]
		if initial_rects.has(items[index].id): check(other.get_global_rect() == initial_rects[items[index].id], "Placeholder/base/upgrade card geometry stays fixed: %s -> %s" % [initial_rects[items[index].id], other.get_global_rect()])
		check(other.disabled, "All purchases remain disabled until entire rollout completes")
		if index > current:
			check(not other.has_node("Icon") and not other.has_node("GearUpgradeEffect") and other.tooltip_text == "", "Future cards reveal no icon, stats or shimmer")
		elif index < current:
			check(shop._display_tiers[items[index].id] == items[index].tier, "Previous item settles before next item")
	events.append({"id": items[current].id, "tier": shop._display_tiers[items[current].id], "cue": audio.magic_find_sfx_play_count})

func finish_sequence(items: Array[GearItem], before: int, expected_cues: int) -> void:
	var observed: int = audio.magic_find_sfx_play_count
	var deadline := Time.get_ticks_msec() + 16000
	while shop.is_busy() and Time.get_ticks_msec() < deadline:
		if audio.magic_find_sfx_play_count != observed:
			check(audio.magic_find_sfx_play_count == observed + 1, "Only one current-item cue starts at once")
			observed = audio.magic_find_sfx_play_count
			inspect_peak(items)
		await process_frame
	check(not shop.is_busy(), "All six offers finish sequentially")
	check(audio.magic_find_sfx_play_count == before + expected_cues, "Exactly one sound for every recorded tier transition")
	check(shop._shop_skip_animations_button.visible, "Compact animation toggle remains visible after completion")

func run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1600, 900)
	root.content_scale_size = Vector2i(1600, 900)
	root.theme = load("res://assets/ui_theme.tres")
	state = root.get_node("BuildState")
	audio = root.get_node("AudioManager")
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	screen = load("res://scenes/combat/combat_screen.tscn").instantiate()
	root.add_child(screen)
	await settle()
	shop = screen._shop_overlay
	for field in ["_contract_overlay", "_map_overlay", "_story_overlay", "_talent_overlay", "_secondary_subclass_overlay"]: screen.get(field).hide()
	var items: Array[GearItem] = [
		gear("sequence.natural", [GearItem.Tier.BASIC, GearItem.Tier.MASTER, GearItem.Tier.EPIC]),
		gear("sequence.magic", [GearItem.Tier.BASIC, GearItem.Tier.MASTER, GearItem.Tier.EPIC, GearItem.Tier.CURSED], true),
		gear("sequence.unchanged", [GearItem.Tier.MASTER]),
		gear("sequence.chaos", [GearItem.Tier.EPIC, GearItem.Tier.CHAOS], true),
		gear("sequence.natural2", [GearItem.Tier.BASIC, GearItem.Tier.MASTER]),
		gear("sequence.basic", [GearItem.Tier.BASIC])]
	items[3].is_unidentified = true
	state.shop_round_pending = true
	state.gold = 10000
	state.shop_offers.assign(items)
	var frozen := payload()
	var before: int = audio.magic_find_sfx_play_count
	var reveal_start := Time.get_ticks_msec()
	screen._show_shop_overlay()
	await settle()
	var toggle: Button = shop._shop_skip_animations_button
	check(toggle.visible and not toggle.button_pressed and toggle.tooltip_text.contains("OFF"), "Fresh profile defaults to animated shop with an always-present OFF toggle")
	check(toggle.get_theme_font("font") == CardStyle.DATA_FONT and toggle.get_theme_font_size("font_size") == 16, "Skip action uses talent reset typography")
	check(toggle.get_theme_stylebox("normal").content_margin_left == 7 and toggle.get_theme_stylebox("normal").content_margin_right == 7, "Skip action uses talent reset compact margins")
	check(shop.is_revealing() and shop._shop_offers_box.get_child_count() == 6, "Initial shop opens with six frozen placeholders")
	var identities := {}
	for item in items:
		var card: Button = shop._upgrade_cards[item.id]
		identities[item.id] = card.get_instance_id()
		initial_rects[item.id] = card.get_global_rect()
		check(card.disabled and not card.has_node("Icon") and card.tooltip_text == "", "Hidden placeholder has no item information")
	check(shop._shop_reroll_button.disabled and not shop._shop_leave_button.disabled, "Reroll locks while Leave remains usable")
	await capture("initial_placeholders")
	var gold_before: int = state.gold
	screen._on_shop_buy_pressed(items[0], shop._upgrade_cards[items[0].id])
	screen._on_shop_reroll_pressed()
	shop._upgrade_cards[items[0].id].pressed.emit()
	await settle()
	check(state.gold == gold_before and state.shop_reroll_count == 0 and payload() == frozen, "Programmatic buy/reroll and signal purchase are blocked during reveal")
	var base_deadline := Time.get_ticks_msec() + 3000
	while not shop._revealed_ids.has(items[0].id) and Time.get_ticks_msec() < base_deadline: await process_frame
	check(shop._display_tiers.get(items[0].id, -1) == GearItem.Tier.BASIC, "First offer is initially shown at recorded base rarity")
	check(shop._upgrade_cards[items[0].id].tooltip_text == "Revealing item...", "Intermediate rarity hides final stat hover")
	await capture("initial_base")
	await await_cue(before + 1)
	inspect_peak(items)
	await capture("first_item_peak")
	var generation: int = shop._reveal_generation
	var sold := gear("sequence.sell", [GearItem.Tier.MASTER])
	state.inventory.append(sold)
	var price: int = state.shop_purchase_price_for(items[0])
	state.gold = price - state.sell_value_for(sold)
	shop.set_status_text("Inventory full -- make space first.")
	state.build_changed.emit()
	check(shop._shop_status_label.text == "", "State refresh clears stale shop errors")
	check(state.sell_inventory_item(sold), "Gear may be sold while shop is revealing")
	check(state.gold == price and shop._reveal_generation == generation, "Sale updates affordability without restarting reveal")
	for item in items:
		check(shop._upgrade_cards[item.id].get_instance_id() == identities[item.id], "Sale preserves every card identity")
	check(payload() == frozen, "Presentation and sale never change frozen offer data")
	await finish_sequence(items, before, 7)
	events.append({"initial_rollout_ms": Time.get_ticks_msec() - reveal_start, "transitions": 7, "cards": 6})
	check(not shop._upgrade_cards[items[0].id].disabled, "Sale-funded purchase becomes enabled only after all offers settle")
	for item in items: check(shop._upgrade_cards[item.id].get_global_rect() == initial_rects[item.id], "Completion cannot resize or move shop cards: %s -> %s" % [initial_rects[item.id], shop._upgrade_cards[item.id].get_global_rect()])
	check(items[3].is_unidentified and shop._upgrade_cards[items[3].id].tooltip_text.contains("Unidentified"), "Unidentified Chaos still hides item stats")
	await capture("initial_completed")
	before = audio.magic_find_sfx_play_count
	shop.hide()
	screen._show_shop_overlay()
	await create_timer(0.8).timeout
	check(not shop.is_busy() and audio.magic_find_sfx_play_count == before, "Reopening the same batch stays settled and silent")
	screen._on_shop_buy_pressed(items[0], shop._upgrade_cards[items[0].id])
	await create_timer(0.8).timeout
	check(not state.shop_offers.has(items[0]) and shop._shop_offers_box.get_child_count() == 5, "Normal purchase removes only purchased card")
	for index in range(1, items.size()): check(shop._upgrade_cards[items[index].id].get_instance_id() == identities[items[index].id], "Purchase preserves remaining cards")
	check(audio.magic_find_sfx_play_count == before, "Purchase refresh never replays upgrades")
	# Find a genuine deterministic reroll with natural, MF and unchanged items.
	var finder := gear("sequence.finder", [GearItem.Tier.BASIC])
	finder.affixes.clear()
	var modifier := StatModifier.new()
	modifier.stat_id = "increased_magic_find"
	modifier.value = 1.0
	finder.affixes.append(modifier)
	state.equipped_weapon = finder
	state.active_contract = load("res://data/contracts/the_gilded_serpent.tres")
	state.gold = 10000
	var expected: Array[GearItem] = []
	var found := false
	for seed in 1000:
		state.adventure_seed = seed
		expected = state._generate_tavern_shop_offers(state.shop_round_index, 1)
		var natural := false
		var magic := false
		var unchanged := false
		var multi := false
		for item in expected:
			natural = natural or (item.reward_tier_steps.size() > 1 and not item.reward_magic_find_upgraded)
			magic = magic or item.reward_magic_find_upgraded
			unchanged = unchanged or item.reward_tier_steps.size() <= 1
			multi = multi or item.reward_tier_steps.size() > 2
		if natural and magic and unchanged and multi:
			found = true
			break
	check(found, "Real reroll fixture covers natural/MF/multiple tiers/unchanged")
	var expected_payload := JSON.stringify(SaveSystem._gear_list_to_data(expected))
	var cost: int = state.shop_reroll_cost
	screen._on_shop_reroll_pressed()
	check(shop.is_busy(), "Actual reroll callback locks immediately during gold flight")
	check(shop._shop_skip_animations_button.visible, "Animation preference stays available during gold flight")
	var deadline := Time.get_ticks_msec() + 4000
	while state.shop_reroll_count == 0 and Time.get_ticks_msec() < deadline: await process_frame
	check(state.shop_reroll_count == 1 and state.gold == 10000 - cost, "Actual reroll pays once and rolls once")
	check(payload() == expected_payload, "Reveal preserves exact deterministic actual-reroll offers")
	items.assign(state.shop_offers)
	var transitions := 0
	for item in items: transitions += maxi(item.reward_tier_steps.size() - 1, 0)
	await capture("reroll_placeholders")
	await finish_sequence(items, before, transitions)
	check(payload() == expected_payload, "Sequential reroll leaves original IDs/affixes/rarities unchanged")
	await capture("reroll_completed")
	# Toggling during the gold flight preserves its payment/roll lifecycle.
	before = audio.magic_find_sfx_play_count
	gold_before = state.gold
	cost = state.shop_reroll_cost
	screen._on_shop_reroll_pressed()
	var operation: int = shop._operation_generation
	shop._shop_skip_animations_button.button_pressed = true
	check(shop.is_reroll_current(operation), "Animation toggle preserves the in-flight reroll token")
	await create_timer(1.5).timeout
	check(state.shop_reroll_count == 2 and state.gold == gold_before - cost and not shop.is_busy(), "Toggled gold flight commits exactly one payment/roll and settles its cards")
	check(audio.magic_find_sfx_play_count == before, "Skipped reroll has no reveal cues")
	var toggle_rect: Rect2 = shop._shop_skip_animations_button.get_global_rect()
	var skipped_rects := {}
	for item in state.shop_offers: skipped_rects[item.id] = shop._upgrade_cards[item.id].get_global_rect()
	check(shop._shop_skip_animations_button.button_pressed and shop._shop_skip_animations_button.tooltip_text.contains("ON"), "Skip preference has explicit pressed and ON feedback")
	check(toggle.get_theme_stylebox("pressed").bg_color == Color("a77b29"), "Enabled skip has a gold face")
	await capture("toggle_on_settled")
	shop.hide()
	screen._show_shop_overlay()
	await settle()
	check(shop._shop_skip_animations_button.button_pressed and not shop.is_busy(), "Skip preference survives shop reopen")
	var fresh_shop = load("res://scenes/combat/shop_overlay.tscn").instantiate()
	root.add_child(fresh_shop)
	check(fresh_shop._skip_animations and fresh_shop._shop_skip_animations_button.button_pressed, "New shop instance retains this session's skip preference")
	fresh_shop.queue_free()
	shop._shop_skip_animations_button.button_pressed = false
	await settle()
	check(not preload("res://scripts/ui/shop_reveal_preferences.gd").load_skip_animations(), "OFF is retained for this session")
	check(shop._shop_skip_animations_button.get_global_rect() == toggle_rect, "ON/OFF labels preserve toggle geometry")
	check(toggle.size.y < shop._shop_leave_button.size.y and toggle.size.x < 70, "Skip action stays reset-sized beside the larger Leave action")
	for item in state.shop_offers: check(shop._upgrade_cards[item.id].get_global_rect() == skipped_rects[item.id], "ON/OFF does not move settled cards")
	await create_timer(0.5).timeout
	check(not shop.is_busy() and audio.magic_find_sfx_play_count == before, "Turning animation back on does not replay settled batch")
	# A hidden or explicitly cancelled gold flight cannot commit a deferred reroll.
	before = audio.magic_find_sfx_play_count
	gold_before = state.gold
	expected_payload = payload()
	screen._on_shop_reroll_pressed()
	shop.hide()
	await create_timer(1.0).timeout
	check(state.shop_reroll_count == 2 and state.gold == gold_before and payload() == expected_payload, "Hide during gold flight prevents deferred reroll mutation")
	screen._show_shop_overlay()
	await settle()
	screen._on_shop_reroll_pressed()
	shop.skip_reveal()
	await create_timer(1.0).timeout
	check(state.shop_reroll_count == 2 and state.gold == gold_before, "Explicit lifecycle cancellation during gold flight invalidates its transaction")
	# New pending batch can be skipped or hidden before its first reveal.
	var pending := gear("sequence.pending", [GearItem.Tier.BASIC, GearItem.Tier.MASTER, GearItem.Tier.EPIC], true)
	state.shop_offers.assign([pending])
	shop.refresh()
	shop._shop_skip_animations_button.button_pressed = true
	await create_timer(1.0).timeout
	check(not shop.is_busy() and shop._display_tiers[pending.id] == pending.tier and audio.magic_find_sfx_play_count == before, "Skip settles all offers without pending audio")
	shop._shop_skip_animations_button.button_pressed = false
	pending = gear("sequence.skip_active", [GearItem.Tier.BASIC, GearItem.Tier.MASTER, GearItem.Tier.EPIC], true)
	state.shop_offers.assign([pending])
	shop.refresh()
	await await_cue(before + 1)
	shop._shop_skip_animations_button.button_pressed = true
	await create_timer(0.8).timeout
	check(not shop.is_busy() and audio.magic_find_sfx_play_count == before + 1, "Skip during shimmer cancels the remaining tiers")
	for player in audio._magic_find_sfx_players: check(not player.playing, "Skip stops active audio tails")
	shop._shop_skip_animations_button.button_pressed = false
	before = audio.magic_find_sfx_play_count
	pending = gear("sequence.hidden", [GearItem.Tier.BASIC, GearItem.Tier.MASTER], true)
	state.shop_offers.assign([pending])
	shop.refresh()
	shop.hide()
	screen._show_shop_overlay()
	await create_timer(1.0).timeout
	check(not shop.is_busy() and audio.magic_find_sfx_play_count == before, "Hide/reentry cannot restart pending batch")
	state.shop_offers.assign([gear("sequence.exit", [GearItem.Tier.BASIC, GearItem.Tier.MASTER, GearItem.Tier.EPIC], true)])
	shop.refresh()
	await await_cue(before + 1)
	screen.queue_free()
	await create_timer(1.0).timeout
	check(audio.magic_find_sfx_play_count == before + 1, "Scene exit during shimmer cancels pending tier/effect cues")
	var file := FileAccess.open(OUT + "events.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(events, "\t"))
	if failures.is_empty(): print("PASS: sequential initial and actual reroll, frozen offers, sale/buy guards, skip/hide/reentry/exit")
	else: print("FAILED: ", failures)
	quit(0 if failures.is_empty() else 1)
