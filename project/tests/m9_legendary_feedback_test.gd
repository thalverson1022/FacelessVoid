extends "res://tests/m9_poison_crit_presentation_test.gd"
## Actual resolver recordings delivered through both dashboard event handlers.
const LEGENDARY_REPORT := "res://reports/m9_legendary_feedback/"
const Assassin = preload("res://scripts/systems/playable_assassin_content.gd")
var fixture: Dictionary
var normal_fixture: Dictionary

func _initialize() -> void:
	SaveSystem.save_path = LEGENDARY_REPORT + "adventure.json"
	PracticeSaveSystem.save_path = LEGENDARY_REPORT + "practice.json"
	PracticeSaveSystem.core_save_path = LEGENDARY_REPORT + "core.json"
	SevenSlotSaveBoundary.legacy_path = LEGENDARY_REPORT + "legacy.json"
	SevenSlotSaveBoundary.marker_path = LEGENDARY_REPORT + "marker.json"
	call_deferred("run")

func make_fixture(enabled: bool = true, critical: bool = true) -> Dictionary:
	var add := Skill.new()
	add.id = "test.legendary_fuel"
	add.display_name = "Apply Poison"
	add.base_execution_ms = 100
	add.min_execution_ms = 100
	add.poison_stacks_applied = 20
	var hit := PhysicalDamageEffect.new()
	hit.amount = 10
	add.effects.append(hit)
	var strike: Skill = Assassin.skill("poison_strike")
	var death: Skill = load("res://data/skills/death_strike.tres")
	var exsanguinate: Skill = load("res://data/skills/exsanguinate.tres")
	var rotation: Array[Skill] = [add, strike, death, exsanguinate]
	var player := PlayerStats.new()
	player.assassin_tree_points = 10
	player.poison_damage_per_tick = 10
	player.crit_chance = 1 if critical else 0
	player.shred_chance = 1
	player.bonus_shred_stacks = 9
	player.critical_poison_enabled = true
	player.retrigger_chance = 0.5
	player.legendary_arctic_mittens = enabled
	player.special_effects = {"legendary": {}}
	if enabled:
		for flag in ["umbral", "nightkiss", "decrepit", "serpents_scales", "coil", "hands_of_the_lightning_lord", "locket"]:
			player.special_effects.legendary[flag] = true
	var monster := Monster.new()
	monster.display_name = "Bandit"
	monster.hp = 1000000000
	for seed_value in range(1, 101):
		var result := CombatResolver.resolve(rotation, player, monster, 6000, seed_value, true)
		assert(result.is_valid, "Seeded resolver fixture valid")
		var playback := CombatPlayback.new()
		playback.start(result)
		var witnesses := {}
		for event in playback._events:
			if event.is_tick and event.tick.had_active_stack:
				if (event.tick.is_crit or not critical) and (event.tick.stacks_preserved or event.chain_count <= 1):
					witnesses["preserved" if event.tick.stacks_preserved else "paid"] = event
				if event.tick.keyword_consume: witnesses["decrepit"] = event
				if event.tick.origin_kind == "poison_repeat": witnesses["coil"] = event
			elif event.cast != null and not event.cast.cooldown_blocked and not event.cast.resource_unavailable:
				if event.cast.skill.id == "skill.killers_mark": witnesses["umbral"] = event
				if event.cast.skill.id == "skill.exsanguinate" and event.cast.health_removed > 0: witnesses["nightkiss"] = event
				if event.cast.origin_kind == "lightning_repeat" and event.visual_beat and event.chain_index > 1: witnesses["hands"] = event
		var credits: Array = result.trace.presentation_records.filter(func(row): return row.kind == "legendary_locket_trial" and not row.payload.get("deadlines", {}).is_empty())
		if not enabled or (not critical and witnesses.has("preserved")) or (witnesses.size() == 7 and not credits.is_empty()):
			return {"result": result, "monster": monster, "rotation": rotation, "events": witnesses, "credits": credits, "seed": seed_value}
	assert(false, "Seed search covers each actual Legendary activation")
	return {}

func owner_for(screen: Node, mode: String) -> Node:
	return screen._playback_presenter if mode == "adventure" else screen

func panel_for(screen: Node, mode: String) -> Node:
	return screen._playback_presenter._skill_build_panel if mode == "adventure" else screen.skill_build_panel

func begin_case(screen: Node, mode: String, data: Dictionary, speed: float) -> void:
	CombatEffectIcons.reduced_motion = false
	var owner := owner_for(screen, mode)
	if mode == "adventure":
		screen._begin_playback(data.result, data.monster)
		owner._intro_remaining_sec = 0
		owner.set_speed(speed)
		owner.skipping = false
		owner._popup_layer.skip_active = false
	else:
		screen.skill_build_panel.state.last_result = data.result
		screen.skill_build_panel.state.selected_target = data.monster
		screen._instant_playback = false
		screen.play(data.result, data.monster)
		screen._set_speed(speed)
	# Test owns delivery; the real dashboard remains rendered but its clock stops.
	screen.set_process(false)
	owner._sync_presentation()
	for old in screen._popup_layer.get_children(): old.hide()

func capture_legendary(screen: Node, key: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	assert(picture.get_size() == Vector2i(1600, 900), "Actual 1600x900 dashboard render")
	assert(picture.save_png(LEGENDARY_REPORT + key + ".png") == OK)
	evidence[key] = {"render": key + ".png", "viewport": [1600, 900]}

func assert_transients_clear(screen: Node, mode: String) -> void:
	var stage: CombatStage = screen._combat_stage
	for accent in stage._legendary_accents.values():
		assert(not accent.visible, "Legendary accent cleaned up")
	if is_instance_valid(stage._retrigger_ghost): assert(not stage._retrigger_ghost.visible, "Repeat ghost cleaned up")
	assert(panel_for(screen, mode)._cooldown_pulses.is_empty(), "Locket pulse cancelled")
	var owner := owner_for(screen, mode)
	var aura: Control = owner.clock_frost if mode == "adventure" else screen._clock_frost
	assert(not aura.visible, "Arctic aura cleaned up")

func check_preservation_motion(label: Label) -> void:
	var origin_x := label.position.x
	assert(label.get_meta("poison_preservation_active", false), "Scales glow active")
	assert(label.get_theme_color("font_outline_color").g > 0.8, "Scales green outline")
	# Hidden-window rendering can take longer than the 275ms wiggle. Sample
	# the actual tweens before awaiting a render, at a deterministic 25ms.
	for tween in get_processed_tweens():
		if tween.is_valid(): tween.custom_step(0.025)
	assert(absf(label.position.x - origin_x) > 0.1, "Scales visibly wiggles sideways")

func check_preservation_expired(label: Label) -> void:
	for tween in get_processed_tweens():
		if tween.is_valid(): tween.custom_step(0.46)
	assert(is_instance_valid(label) and not label.get_meta("poison_preservation_active", true), "Scales glow expires")
	assert(label.get_theme_color("font_outline_color").g < 0.8, "Scales restores ordinary outline")

func check_legendary_mode(screen: Node, mode: String) -> void:
	var owner := owner_for(screen, mode)
	var stage: CombatStage = screen._combat_stage
	var panel := panel_for(screen, mode)
	panel.state.rotation.assign(fixture.rotation)
	panel._refresh()
	await settle()
	for speed in [1.0, 4.0]:
		for kind in ["umbral", "nightkiss", "decrepit", "coil", "hands", "preserved", "paid"]:
			begin_case(screen, mode, fixture, speed)
			var event: CombatPlayback.PlaybackEvent = fixture.events[kind]
			deliver(screen, mode, event)
			match kind:
				"umbral": assert(stage.umbral_slash_count == 1, "Umbral actual Death Strike slash")
				"nightkiss": assert(stage.nightkiss_swoosh_count == 1, "Nightkiss actual health removal swoosh")
				"decrepit": assert(stage.decrepit_burst_count == 1, "Decrepit recorded Consume burst")
				"coil": assert(stage.poison_retrigger_ghost_count == 1, "Coil repeated Poison ghost")
				"hands": assert(is_instance_valid(stage._retrigger_ghost) and stage._retrigger_ghost.visible, "Hands actual repeated cast ghost")
				"preserved", "paid":
					var labels := visible_popups(screen._popup_layer)
					assert(not labels.is_empty(), "Real critical Poison popup shown")
					var label: Label = labels[-1]
					assert(label.get_meta("poison_stack_preserved", false) == (kind == "preserved"), "Scales outline only on preserved packets")
					assert(label.text.ends_with("!") and not "preserv" in label.text.to_lower(), "Scales retains numeric critical feedback")
					var font := 26 if mode == "adventure" else 18
					assert(label.get_theme_font_size("font_size") == roundi(font * 1.5), "Scales retains critical 1.5x")
			var aura: Control = owner.clock_frost if mode == "adventure" else screen._clock_frost
			assert(aura.active and aura.visible, "Recorded Arctic budget activates aura")
			if kind == "preserved":
				check_preservation_motion(visible_popups(screen._popup_layer)[-1])
			await capture_legendary(screen, "%s_%dx_%s" % [mode, int(speed), kind])
			if kind == "preserved":
				check_preservation_expired(visible_popups(screen._popup_layer)[-1])
		begin_case(screen, mode, normal_fixture, speed)
		deliver(screen, mode, normal_fixture.events.preserved)
		var normal_label: Label = visible_popups(screen._popup_layer)[-1]
		assert(normal_label.get_meta("poison_stack_preserved", false), "Noncritical Scales preserves recorded packet")
		assert(not normal_label.text.ends_with("!"), "Noncritical preserved packet stays noncritical")
		assert(normal_label.get_theme_font_size("font_size") == (26 if mode == "adventure" else 18), "Noncritical Scales retains base font size")
		check_preservation_motion(normal_label)
		await capture_legendary(screen, "%s_%dx_preserved_normal" % [mode, int(speed)])
		check_preservation_expired(normal_label)
		# Real Locket reduction records pulse their actual macro countdown labels.
		begin_case(screen, mode, fixture, speed)
		var icons: CombatEffectIcons = owner.effect_icons if mode == "adventure" else screen._effect_icons
		for step in 10000:
			owner._playback.advance(0.01)
			if not icons.model.cooldown_credits.is_empty(): break
		owner._sync_presentation()
		assert(not icons.model.cooldown_credits.is_empty(), "Real Locket record supplies credits")
		assert(not panel._cooldown_pulses.is_empty(), "Real macro countdown label pulses")
		var previous: int = panel.locket_pulse_count
		panel.update_presentation(icons.model)
		assert(panel.locket_pulse_count == previous, "Same credit never pulses twice")
		await capture_legendary(screen, "%s_%dx_locket_arctic" % [mode, int(speed)])
		if mode == "adventure": owner.skip()
		else: screen._skip()
		await process_frame
		assert_transients_clear(screen, mode)
		# Exercise suppression through the same handlers, not just stage helpers.
		for suppression in ["motion", "skip"]:
			begin_case(screen, mode, fixture, speed)
			if suppression == "motion":
				CombatEffectIcons.reduced_motion = true
				owner._on_motion_changed(true)
			elif mode == "adventure":
				owner.skipping = true
				owner._popup_layer.skip_active = true
			else: screen._playback_skipping = true
			var suppression_events: Array = fixture.events.values()
			suppression_events.sort_custom(func(a, b): return a.time_ms < b.time_ms or (a.time_ms == b.time_ms and a.sequence < b.sequence))
			for event in suppression_events: deliver(screen, mode, event)
			assert(stage.umbral_slash_count == 0 and stage.nightkiss_swoosh_count == 0 and stage.decrepit_burst_count == 0 and stage.poison_retrigger_ghost_count == 0, "Reduced motion/skip suppress all Legendary transient accents")
			stage.clear_transient_effects()
			panel.clear_legendary_feedback()
			CombatEffectIcons.reduced_motion = false
			if mode == "adventure": owner.skipping = false
			else: screen._playback_skipping = false
		# No equipment: actual base recordings never produce equipment accents.
		var plain := make_fixture(false)
		begin_case(screen, mode, plain, speed)
		var plain_playback := CombatPlayback.new()
		plain_playback.start(plain.result)
		for event in plain_playback._events: deliver(screen, mode, event)
		assert(stage.umbral_slash_count == 0 and stage.nightkiss_swoosh_count == 0 and stage.decrepit_burst_count == 0 and stage.poison_retrigger_ghost_count == 0, "Unequipped negative control")
		var aura: Control = owner.clock_frost if mode == "adventure" else screen._clock_frost
		assert(not aura.active, "Normal countdown has no Arctic aura")
		if mode == "adventure": owner._on_finished()
		else: screen._on_playback_finished()
		assert_transients_clear(screen, mode)
		evidence["%s_%dx_controls" % [mode, int(speed)]] = {"reduced_motion": true, "skip": true, "unequipped": true, "finish_cleanup": true, "skip_cleanup": true}

func run() -> void:
	root.size = Vector2i(1600, 900)
	root.gui_embed_subwindows = true
	fixture = make_fixture()
	normal_fixture = make_fixture(true, false)
	evidence["fixture"] = {"seed": fixture.seed, "witnesses": fixture.events.keys(), "locket_reductions": fixture.credits.size()}
	state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_new_game_pressed(1928)
	state.set_class(BuildContentRegistry.adventure().classes["class.rogue"])
	assert(state.configure_ranked_build(BuildContentRegistry.adventure().trees["tree.assassin"]))
	game._show_combat_screen()
	await settle()
	var screen: Node = game._current_screen
	dismiss(screen)
	await check_legendary_mode(screen, "adventure")
	game.queue_free()
	await settle()
	state.reset()
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await settle()
	room._setup_autosave = false
	await check_legendary_mode(room._combat_view, "practice")
	SaveSystem.write_json(LEGENDARY_REPORT + "evidence.json", evidence)
	room.queue_free()
	await settle()
	state.reset()
	print("M9 LEGENDARY FEEDBACK PASS")
	quit()








