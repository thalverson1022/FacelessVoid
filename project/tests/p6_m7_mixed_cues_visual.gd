extends "res://tests/p6_m7_retrigger_flurry_visual.gd"
# Actual resolver playback plus explicitly synthetic outcome events for G06.
var observations: Array = []
func emit(view, mode, e) -> void:
	e.time_ms = int(view._playback.elapsed_ms())
	if mode == "practice": view._on_playback_event(e)
	else: view._on_event(e)
func diagnostic(kind: int) -> CombatPlayback.PlaybackEvent:
	var e := CombatPlayback.PlaybackEvent.new()
	e.cast = CombatResolver.CastEvent.new()
	e.cast.skill = load("res://data/skills/stab.tres")
	e.cast.time_ms = 1000
	e.cast.cast_start_ms = 0
	e.cast.physical_damage = 37.4
	e.damage = 37.4
	match kind:
		0: e.cast.is_crit = true
		1:
			e.cast.is_crit = true
			e.cast.skill = e.cast.skill.duplicate()
			e.cast.skill.display_name = "Touch of Darkness"
			e.cast.physical_damage = 1234.5
			e.cast.crit_negation_damage_prevented = 2469.0
		2: e.cast.gold_stolen = 3
		3:
			e.cast.was_dodged = true
			e.cast.physical_damage = 0
			e.damage = 0
		4:
			e.cast.was_interrupted = true
			e.cast.interrupt_skipped = true
			e.cast.physical_damage = 0
			e.damage = 0
	return e
func snapshot(view, mode, speed, phase, reduced) -> void:
	await RenderingServer.frame_post_draw
	var labels: Array = []
	var cue_rects: Array[Rect2] = []
	var stage_rect: Rect2 = view._combat_stage.play_area_global_rect()
	var echoes: Array[Rect2] = []
	var ticks: Array[Rect2] = []
	for child in view._popup_layer.get_children():
		if child is Control and child.visible and not child.is_queued_for_deletion():
			var r: Rect2 = child.get_global_rect()
			if child.has_meta("retrigger_hit"): echoes.append(r)
			if child.get_meta("cue_lane",-1) == 2: ticks.append(r)
			if child.has_meta("cue_lane"):
				check(stage_rect.grow(1).encloses(r),mode + ": normal/tick popup inside stage")
				check(r.position.y >= stage_rect.position.y+150,mode + ": status clearance")
				for old in cue_rects: check(not old.intersects(r),mode + ": normal/tick lanes do not overlap")
				cue_rects.append(r)
			labels.append({"name":child.name,"text":child.text if child is Label else str(child.name),"x":r.position.x,"y":r.position.y,"w":r.size.x,"h":r.size.y,"alpha":child.modulate.a,"echo":child.has_meta("retrigger_hit")})
	for tick_rect in ticks:
		for echo_rect in echoes: check(not tick_rect.intersects(echo_rect),mode + ": Poison stays clear of echo labels")
		if mode == "practice":
			for button in view._content.find_children("*","Button",true,false):
				if button.visible and button.text in ["Fight","Fight!","Combat Log"]: check(not tick_rect.intersects(button.get_global_rect()),mode + ": Poison stays clear of footer actions")
	observations.append({"mode":mode,"speed":speed,"phase":phase,"reduced":reduced,"labels":labels,"ghost_visible":not ghost_clear(view._combat_stage),"stage":str(view._combat_stage.play_area_global_rect())})
	SaveSystem.write_json("res://reports/mixed_cues/observations.json",{"rows":observations})
	root.get_texture().get_image().save_png("res://reports/mixed_cues/%s_%dx_%s%s.png" % [mode,speed,phase,"_reduced" if reduced else ""])
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/mixed_cues")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.assassin","tree.shadow")
	var state = root.get_node("BuildState")
	var enemy := Monster.new()
	enemy.display_name = "Mouthy Drunk"
	enemy.hp = 100000
	var registry := BuildContentRegistry.test_mode()
	var build := RankedBuild.new()
	# Previously recorded legal Assassin/Shadow density fixture.
	var ranks := {"talent.assassin.quick_hands":5,"talent.assassin.precision":3,"talent.assassin.hastened_poison":4,"talent.assassin.echoing_toxin":2,"talent.assassin.toxic_tradeoff":2,"talent.assassin.poison_strike":1,"talent.assassin.bypass":1,"talent.shadow.blind_spot":5,"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.deception":4,"talent.shadow.death_pact":2,"talent.shadow.death_touch":2,"talent.shadow.shadow_mastery":4,"talent.shadow.death_blade":1,"talent.shadow.dusk_strike":1,"talent.umbral_pressure":1}
	check(build.configure(registry.trees["tree.assassin"],registry.trees["tree.shadow"],45,ranks),"Legal inherited Assassin/Shadow ranks")
	var resolved = BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],build,[load("res://data/gear/crude_dagger.tres")])
	var skills := {}
	for skill in resolved.skills: skills[skill.id] = skill
	var rotation: Array[Skill] = [skills["skill.venom_jab"],skills["skill.poison_strike"],skills["skill.stab"]]
	var dense := CombatResolver.resolve(rotation,resolved.stats,enemy,10000,7,true)
	check(dense.is_valid and dense.tick_events.size() > 0,"Inherited build actually resolves Poison")
	var stats := PlayerStats.new()
	stats.weapon_damage_min = 100
	stats.weapon_damage_max = 100
	stats.retrigger_chance = 1.0
	stats.poison_damage_per_tick = 10
	stats.readiness_enabled = true
	var ghosts := CombatResolver.resolve([load("res://data/skills/venom_jab.tres"),preload("res://scripts/systems/p6_poison_contracts.gd").poison_strike()],stats,enemy,4000,7,true)
	var originals := [JSON.stringify(dense.trace.presentation_records),JSON.stringify(ghosts.trace.presentation_records)]
	for mode in ([OS.get_environment("FACELESSVOID_MIXED_MODE")] if not OS.get_environment("FACELESSVOID_MIXED_MODE").is_empty() else ["test","adventure","practice"]):
		if mode == "practice": game._show_training_room()
		else:
			state.is_test_mode = mode == "test"
			game._show_combat_screen()
		await settle()
		var screen = game._current_screen
		var view = screen._combat_view if mode == "practice" else screen._playback_presenter
		if mode != "practice":
			view.finished.disconnect(screen._on_playback_finished) # Diagnostic results do not commit Adventure outcomes.
			if screen._story_overlay.visible: screen._story_overlay._on_proceed_pressed()
			screen._contract_overlay.hide()
			screen._map_overlay.hide()
			state.run_phase = state.RunPhase.FIGHTING
		for speed in [1.0,2.0,4.0]:
			for reduced in [false,true]:
				CombatEffectIcons.reduced_motion = reduced
				begin(screen,view,mode,dense,enemy,speed)
				# Play actual resolver events on this surface, not fabricated status values.
				for frame in 36:
					drive(screen,view,mode,0.05)
					await create_timer(0.015).timeout
				await snapshot(view,mode,speed,"resolver",reduced)
				if mode == "practice": view._skip()
				else: view.skip()
				await create_timer(1.4).timeout
				begin(screen,view,mode,ghosts,enemy,speed)
				drive(screen,view,mode,1.261/speed)
				# Special outcomes injected alongside actual ghost result. No mechanics mutation.
				for kind in 5:
					emit(view,mode,diagnostic(kind))
					await create_timer(0.16).timeout
					drive(screen,view,mode,0.16)
					await snapshot(view,mode,speed,"special%d" % kind,reduced)
				var tick := CombatPlayback.PlaybackEvent.new()
				tick.is_tick = true
				tick.tick = CombatResolver.TickEvent.new()
				tick.tick.damage = 15.5
				tick.tick.had_active_stack = true
				tick.damage = 15.5
				emit(view,mode,tick)
				await create_timer(0.08).timeout
				drive(screen,view,mode,0.08)
				await snapshot(view,mode,speed,"mixed",reduced)
				if reduced: check(view._popup_layer.get_children().filter(func(n): return n.visible and not n.is_queued_for_deletion()).is_empty(),mode + ": reduced-motion popup suppression")
				if mode == "practice": view._skip()
				else: view.skip()
				await create_timer(1.4).timeout
		CombatEffectIcons.reduced_motion = false
		game._on_main_menu_pressed()
		await settle()
	check(JSON.stringify(dense.trace.presentation_records) == originals[0] and JSON.stringify(ghosts.trace.presentation_records) == originals[1],"Resolver records remain unchanged")
	SaveSystem.write_json("res://reports/mixed_cues/measurements.json",{"observations":observations,"dense":{"ranks":ranks,"casts":dense.cast_events.size(),"ticks":dense.tick_events.size(),"damage":dense.total_damage,"rng":dense.rng_final_state},"ghost":{"casts":ghosts.cast_events.size(),"ticks":ghosts.tick_events.size(),"damage":ghosts.total_damage},"disclosure":"Dense phase advances 36x50ms with short waits to stress layout; special phase advances ghosts between synthetic outcome injections. These are layout captures, not wall-time movies. Special outcomes are injected diagnostic events on actual playback surfaces. Dense and ghost phases use actual resolver results; Adventure build is diagnostic, not earned progression."})
	game.queue_free()
	await settle()
	print("Mixed cues PASS" if not failed else "Mixed cues FAILED")
	quit(1 if failed else 0)
