extends SceneTree
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")
const State = preload("res://scripts/ui/combat_presentation_state.gd")
var failed := false
var credited := 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		printerr("FAILED: " + message)
func _run() -> void:
	var registry := Core.registry()
	var resolved := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], Core.build(registry), [load("res://data/gear/crude_dagger.tres")])
	var rotation: Array[Skill] = Core.rotation(resolved.skills)
	var enemy := Monster.new()
	enemy.hp = 100000
	var result := CombatResolver.resolve(rotation, resolved.stats, enemy, 20000, 7, false)
	var traced := CombatResolver.resolve(rotation, resolved.stats, enemy, 20000, 7, true)
	check(result.is_valid and result.total_damage == traced.total_damage and result.rng_final_state == traced.rng_final_state, "Trace does not change combat")
	check(result.trace.presentation_records == traced.trace.presentation_records, "Presentation has exact trace-on/off parity")
	var previous := 0
	for record in result.trace.presentation_records:
		check(record.sequence > previous, "Stable total event sequence")
		previous = record.sequence
	var model = State.new()
	model.begin(result)
	model.advance_to(1700)
	check(model.units("buff.footwork") == 3 and model.units("buff.readiness") == 0, "Seed 7 tied grants then Parry consumption at 1700ms")
	model.advance_to(2200)
	check(model.units("buff.footwork") == 0, "Plunge consumes three Footwork at accepted start")
	check(model.attempt_text().contains("1.000s"), "Captured Plunge duration")
	var panel := CombatEffectIcons.new()
	root.add_child(panel)
	await process_frame
	panel.begin(result)
	panel.advance_to(1699)
	var grid: GridContainer = panel._grid
	panel.advance_to(1700)
	check(grid == panel._grid, "Timer refresh preserves buff container")
	check(panel.model.units("buff.readiness") == 0 and panel._chips.has("buff.readiness"), "Spent Readiness stays visible during Parry windup only")
	panel.advance_to(2200)
	check(not panel._chips.has("buff.readiness"), "Parry impact removes spent Readiness")
	check(panel.model.units("buff.footwork") == 0 and panel._chips["buff.footwork"].get_node("StackCount").text == "3", "Plunge retains spent stack count without changing consumed state")
	panel.advance_to(3199)
	check(panel._chips.has("buff.footwork"), "Footwork remains until immediately before impact")
	panel.advance_to(3200)
	check(not panel._chips.has("buff.footwork"), "Plunge impact removes spent Footwork")

	for speed in [1.0, 2.0, 4.0]:
		var playback := CombatPlayback.new()
		var replay = State.new()
		replay.begin(result)
		playback.start(result)
		playback.speed = speed
		while playback.elapsed_ms() < 2200.0:
			playback.advance(minf(0.01, (2200.0 - playback.elapsed_ms()) / 1000.0) / speed)
		replay.advance_to(int(playback.elapsed_ms()))
		check(replay.active == model.active and replay.cooldowns == model.cooldowns, "Speed-independent state at same simulation time")
		playback.skip()
		replay.advance_to(int(playback.elapsed_ms()))
		check(replay.active.is_empty() and replay.held_effects.is_empty(), "Skip clears lifecycle and held display state")
	panel.finish(result)
	check(panel.active.is_empty() and panel.model.cooldowns.is_empty() and not panel.model.journal.is_empty(), "Finish clears effects and retains review")
	panel.begin(result)
	check(panel.model.stolen == 0 and panel.model.time_ms == 0, "Retry resets presentation")
	var parry: Skill
	for skill in resolved.skills:
		if skill.id == "skill.parry_strike": parry = skill
	var missing := CombatResolver.resolve([parry], resolved.stats, enemy, 1000, 7)
	model.begin(missing)
	check(model.attempt_text().contains("No Readiness") and int(model.attempt.execution_ms) == 500, "Missing Readiness spends real cast time")
	var dance := Skill.new()
	dance.id = "skill.dance_of_death"
	dance.display_name = "Dance of Death"
	dance.category = Skill.Category.SELF_BUFF
	dance.base_execution_ms = 500
	dance.min_execution_ms = 500
	dance.cooldown_ms = 20000
	dance.dance_duration_ms = 5000
	var player: PlayerStats = resolved.stats.duplicate(true)
	player.dance_duration_ms = 5000
	var cooldown_result := CombatResolver.resolve([dance, dance], player, enemy, 21000, 7)
	model.begin(cooldown_result)
	model.advance_to(499)
	check(not model.cooldowns.has(dance.id), "Cooldown absent throughout cast windup")
	model.advance_to(500)
	check(model.cooldowns.get(dance.id) == 20500 and model.attempt_text().contains("0.1s"), "Duplicate shared cooldown and failed attempt")
	check(model.units("buff.dance") > 0, "Dance duration starts after activation")
	model.advance_to(5500)
	check(model.units("buff.dance") == 0 and model.cooldowns.has(dance.id), "Buff expiry independent from skill cooldown")
	# Actual Decay consumption must drive the Beguiling icon, not its zero charge field.
	var beguiling_stats := PlayerStats.new()
	beguiling_stats.bonus_decay_stacks = 6
	var beguiling_rotation: Array[Skill] = [load("res://data/skills/beguiling_strike.tres"), preload("res://scripts/systems/p6_status_skill_contracts.gd").skill("beguiling_presence")]
	var beguiling_result := CombatResolver.resolve(beguiling_rotation, beguiling_stats, enemy, 15000, 7, true)
	var absorbed_at := beguiling_result.cast_events[1].time_ms
	panel.begin(beguiling_result)
	panel.advance_to(absorbed_at)
	check(panel._chips.has("buff.beguiling_presence") and panel._chips["buff.beguiling_presence"].get_node("StackCount").text == "7", "Beguiling icon shows seven actual Decay stacks absorbed")
	check(panel._chips["buff.beguiling_presence"].tooltip_text.contains("7 Decay stacks absorbed"), "Beguiling tooltip explains the displayed count")
	check(panel._chips["buff.beguiling_presence"].tooltip_text.contains("Critical chance: +14.0 percentage points"), "Beguiling tooltip shows actual new critical chance bonus")
	panel.advance_to(absorbed_at + 9999)
	check(panel._chips["buff.beguiling_presence"].get_node("StackCount").text == "7", "Beguiling absorbed count persists for buff duration")
	panel.advance_to(absorbed_at + 10000)
	check(not panel._chips.has("buff.beguiling_presence"), "Beguiling absorbed count disappears at expiry")
	# Labelled synthetic lifecycle boundary and overflow; never selectable content.
	var synthetic := CombatResolver.CombatResult.new()
	synthetic.duration_ms = 5000
	for i in 12:
		synthetic.trace.record("effect_lifecycle", 0, {"effect_instance_id": "instance%d" % i, "source_id": "talent.synthetic"}, {"effect_id": "footwork" if i == 0 else "synthetic_%d" % i, "after": {"units": 3, "expires_at_ms": 3000, "unit": "stacks"}})
	synthetic.trace.record("effect_lifecycle", 3000, {"effect_instance_id": "instance0", "lifecycle_reason": "consumed"}, {"effect_id": "footwork", "after": {}, "consumed": 3})
	panel.begin(synthetic)
	check(panel.active.size() == 12 and panel._grid.get_child_count() == 12, "All active buff types visible in wrapped rows")
	panel._open_inspector()
	check(panel._details.text.contains("Synthetic 11"), "Inspector includes final overflow item")
	panel._dialog.hide()
	panel.advance_to(3000)
	check(panel.active.is_empty() and panel.model.journal[-1].contains("3 spent"), "Expiry does not erase exact-deadline consumption evidence")
	# Distinct same-kind instances keep individual timers.
	synthetic.trace.presentation_records.clear()
	for i in 2:
		synthetic.trace.record("effect_lifecycle", 3000, {"effect_instance_id": "touch%d" % i}, {"effect_id": "touch.%d" % i, "after": {"units": 1, "expires_at_ms": 4000 + i * 1000}})
	panel.begin(synthetic)
	panel.advance_to(3000)
	check(panel._grid.get_child_count() == 1 and panel._chips["buff.touch_of_darkness"].get_node("StackCount").text == "2" and panel._chips["buff.touch_of_darkness"].tooltip_text.contains("2 instances"), "Independent instance summary")
	check(is_equal_approx(panel._chips["buff.touch_of_darkness"].get_node("Countdown").progress, 1.0), "Independent instance clock starts full")
	panel.advance_to(3500)
	check(is_equal_approx(panel._chips["buff.touch_of_darkness"].get_node("Countdown").progress, 0.5), "Clock tracks nearest independent expiry")
	panel.advance_to(4000)
	check(panel.active.size() == 1, "Independent expiries")
	var timer_fixture := CombatResolver.CombatResult.new()
	timer_fixture.duration_ms = 6000
	timer_fixture.trace.record("effect_lifecycle", 0, {"effect_instance_id": "charge"}, {"effect_id": "readiness", "after": {"units": 1, "expires_at_ms": -1}})
	for row in [{"time": 0, "expiry": 3000, "units": 1}, {"time": 2000, "expiry": 5000, "units": 2}, {"time": 2500, "expiry": 5000, "units": 1}]:
		timer_fixture.trace.record("effect_lifecycle", row.time, {"effect_instance_id": "clock"}, {"effect_id": "footwork", "after": {"units": row.units, "expires_at_ms": row.expiry}})
	panel.begin(timer_fixture)
	check(panel._chips["buff.footwork"].text.is_empty(), "No large player-buff labels or header")
	check(not panel._chips["buff.readiness"].get_node("Countdown").visible, "Untimed charge has no false clock")
	check(panel._chips["buff.readiness"].tooltip_text.contains("1 stacks") and not panel._chips["buff.readiness"].tooltip_text.contains("charge"), "Readiness visible count/rule uses stacks")
	check(preload("res://scripts/ui/combat_effect_text.gd").count_for("buff.virulent_poison", {"charges":5})=="5 stacks", "Internal charge snapshot uses player stack label")
	panel.advance_to(1500)
	check(is_equal_approx(panel._chips["buff.footwork"].get_node("Countdown").progress, 0.5), "Half-time clock")
	panel.advance_to(2000)
	check(is_equal_approx(panel._chips["buff.footwork"].get_node("Countdown").progress, 1.0) and panel._chips["buff.footwork"].get_node("StackCount").text == "2", "Refresh resets radial clock and centered stack count")
	panel.advance_to(2500)
	check(is_equal_approx(panel._chips["buff.footwork"].get_node("Countdown").progress, 2.5 / 3.0), "Consumption without refreshed expiry preserves timer origin")
	panel.finish(timer_fixture)
	check(not panel.visible and panel._chips.is_empty(), "Finish removes buff display")
	# A partial spend holds only spent units; new grants survive the old cast's impact.
	var held_fixture := CombatResolver.CombatResult.new()
	held_fixture.duration_ms = 1000
	held_fixture.trace.record("effect_lifecycle", 0, {"effect_instance_id": "fw"}, {"effect_id": "footwork", "after": {"units": 3, "expires_at_ms": 300}})
	held_fixture.trace.record("effect_lifecycle", 100, {"effect_instance_id": "fw", "cast_id": 1}, {"effect_id": "footwork", "consumed": 2, "after": {"units": 1, "expires_at_ms": 300}})
	held_fixture.trace.record("cast_resolved", 200, {"cast_id": 2}, {})
	held_fixture.trace.record("effect_lifecycle", 400, {"effect_instance_id": "fw"}, {"effect_id": "footwork", "after": {"units": 1, "expires_at_ms": 900}})
	held_fixture.trace.record("cast_resolved", 500, {"cast_id": 1}, {"interrupted": true})
	panel.begin(held_fixture)
	panel.advance_to(200)
	check(panel._chips["buff.footwork"].get_node("StackCount").text == "3" and panel.model.units("buff.footwork") == 1, "Partial spend is not double counted or cleared by another cast")
	panel.advance_to(300)
	check(panel._chips["buff.footwork"].get_node("StackCount").text == "2" and panel.active.is_empty(), "Spent units remain through original expiry until impact")
	panel.advance_to(500)
	check(panel.model.held_effects.is_empty() and panel._chips["buff.footwork"].get_node("StackCount").text == "1", "Interrupted resolution clears held units and preserves a new grant")
	panel.begin(held_fixture)
	panel.advance_to(100)
	panel.begin(result)
	check(panel.model.held_effects.is_empty(), "Retry discards held units")
	panel.begin(held_fixture)
	panel.advance_to(100)
	panel.finish(held_fixture)
	check(panel.model.held_effects.is_empty() and panel._chips.is_empty(), "Finish discards held units")
	# Absolute credited transaction values: never multiply again in presentation.
	model.clear()
	model.apply({"kind": "gold_transaction", "time_ms": 0, "payload": {"raw_amount": 5, "credited_amount": 10, "stash_after": 510, "stolen_after": 110}})
	check(model.stash == 510 and model.stolen == 110, "Gold credited exactly as recorded")
	var mug: Skill = preload("res://scripts/systems/p6_thief_contracts.gd").skill("mug")
	model.running = true
	check(model.details_for(mug).contains("50/50"), "Mug conversion separate from stash and theft")
	model.stolen=3
	check(model.details_for(mug).contains("3/50"), "Mug presentation restores one damage per gold")
	await _potency_hud()
	_poison_presentation(resolved.stats, enemy)
	await _integrated_views(missing, cooldown_result, enemy, parry, dance, registry, resolved.stats)
	panel.clear()
	panel.queue_free()
	await process_frame
	print("T7 presentation checks complete")
	quit(1 if failed else 0)


func _integrated_views(missing, cooling, enemy, parry, dance, registry, stats) -> void:
	var state := TrainingRoomState.new()
	state.selected_class = registry.classes["class.rogue"]
	state.selected_trees = [registry.trees["tree.bladedancer"]]
	state.ranked_build = Core.build(registry)
	state.rotation = [parry]
	state.build_locked = true
	check(state.can_run_fight(), "Practice can retry when idle")
	state.allocation_locked = true
	check(not state.can_run_fight(), "Practice cannot replace active playback")
	state.allocation_locked = false
	var macro = load("res://scenes/combat/skill_build_panel.gd").new()
	macro.state = state
	root.add_child(macro)
	var stage = load("res://scripts/ui/combat_stage.gd").new()
	root.add_child(stage)
	var icons := CombatEffectIcons.new()
	root.add_child(icons)
	var presenter := CombatPlaybackPresenter.new()
	root.add_child(presenter)
	presenter.effect_icons = icons
	var popups := CombatPopupLayer.new()
	root.add_child(popups)
	presenter.set_popup_layer(popups)
	presenter.set_combat_stage(stage)
	presenter.set_skill_build_panel(macro)
	await process_frame
	CombatEffectIcons.reduced_motion = false
	presenter.start(missing, enemy, false, false, false)
	presenter.advance(0.25)
	check(macro._slot_buttons[0].get_node("CooldownLabel").text == "No stack", "Test Mode spent-time reason")
	popups.spawn("Feedback", CombatPopupLayer.Kind.NORMAL)
	check(popups.get_child_count() == 1, "Motion fixture has visible feedback")
	icons._motion.button_pressed = true
	await process_frame
	check(popups.get_child_count() == 0 and popups._active_count == 0, "Reduced motion clears current feedback and bookkeeping")
	check(CombatEffectIcons.reduced_motion and icons.model.attempt_text().contains("No Readiness"), "Inspector toggles reduced motion without changing event state")
	icons._motion.button_pressed = false
	macro._on_slot_pressed(0)
	check(macro._slot_buttons[0]._get_tooltip(Vector2.ZERO).contains("Readiness"), "Hover explains conditional resource")
	presenter.skip()
	check(stage.cast_windup_count == 0 and stage.cast_impact_count == 0, "Unavailable Parry produces no hit animation")
	check(not state.has_meta("combat_presentation") and icons.active.is_empty(), "Test Mode cleanup drops live details")
	state.rotation = [dance, dance]
	state.build_changed.emit()
	await process_frame
	presenter.start(cooling, enemy, false, false, false)
	presenter.advance(0.51)
	check(macro._slot_buttons[0].get_node("CooldownLabel").text == macro._slot_buttons[1].get_node("CooldownLabel").text, "Cooldown appears on every matching copy")
	check(icons.model.attempt_text().contains("0.1s"), "Failed cooldown remains available in inspector")
	check(stage.cast_windup_count == 1 and stage.cast_impact_count == 1, "Cooling attempts do not animate attacks")
	presenter.skip()
	var view := TrainingRoomCombatView.new()
	view.skill_build_panel = macro
	root.add_child(view)
	await process_frame
	state.rotation = [parry]
	state.build_changed.emit()
	await process_frame
	view._instant_playback = false
	view.play(missing, enemy)
	view.set_process(false)
	view._playback_intro_remaining_sec = 0
	view._process(0.25)
	check(macro._slot_buttons[0].get_node("CooldownLabel").text == "No stack", "Practice spent-time reason")
	view._skip()
	check(view._combat_stage.cast_windup_count == 0 and view._combat_stage.cast_impact_count == 0, "Practice unavailable attempt has no hit animation")
	check(not state.has_meta("combat_presentation") and view._effect_icons.active.is_empty(), "Practice cleanup")
	# Labelled test-only theft skill verifies callbacks and skip, not content promotion.
	var theft := Skill.new()
	theft.id = "test.theft"
	theft.category = Skill.Category.DEBUFF
	theft.base_execution_ms = 500
	theft.min_execution_ms = 500
	var effect = load("res://scripts/resources/steal_gold_effect.gd").new()
	effect.amount = 5
	theft.effects = [effect]
	var player: PlayerStats = stats.duplicate(true)
	player.gold_reward_multiplier = 2.0
	player.current_gold = 40
	var gold_result := CombatResolver.resolve([theft], player, enemy, 2000, 7)
	state.rotation = [theft]
	state.build_changed.emit()
	await process_frame
	credited = 0
	presenter.gold_stolen_played.connect(func(amount): credited += amount)
	presenter.start(gold_result, enemy, false, false, false)
	presenter.advance(0.75)
	presenter.skip()
	presenter.skip()
	check(credited == gold_result.gold_stolen and icons.model.stolen == credited and icons.model.stash == 40 + credited, "Test Mode skip credits theft once with matching displayed stash")
	credited = 0
	view.gold_stolen_callback = func(amount): credited += amount
	view.play(gold_result, enemy)
	view.set_process(false)
	view._playback_intro_remaining_sec = 0
	view._process(0.75)
	view._skip()
	view._skip()
	check(credited == gold_result.gold_stolen and view._effect_icons.model.stash == 40 + credited, "Practice skip credits theft once")
	view.play(gold_result, enemy)
	view.set_process(false)
	check(view._effect_icons.model.stolen == 0 and view._effect_icons.model.stash == 40, "Practice replay starts from configured stash")
	view._skip()
	CombatEffectIcons.reduced_motion = true
	presenter.start(missing, enemy, false, false, true)
	presenter.advance(0.25)
	check(presenter._intro_remaining_sec == 0 and icons.model.attempt_text().contains("No Readiness"), "Reduced motion preserves static state and removes intro")
	presenter.skip()
	CombatEffectIcons.reduced_motion = false
	for node in [view, presenter, icons, stage, macro, popups]: node.queue_free()
	await process_frame


func _poison_presentation(stats: PlayerStats, enemy: Monster) -> void:
	var player: PlayerStats = stats.duplicate(true)
	player.retrigger_chance = 0
	var poison := Skill.new()
	poison.id = "test.poison"
	poison.base_execution_ms = 500
	poison.min_execution_ms = 500
	var apply := PoisonDamageEffect.new()
	apply.stacks_applied = 5
	poison.effects = [apply]
	var consume := Skill.new()
	consume.id = "test.consume"
	consume.category = Skill.Category.DEBUFF
	consume.base_execution_ms = 500
	consume.min_execution_ms = 500
	var effect = load("res://scripts/resources/consume_status_effect.gd").new()
	effect.status = "poison"
	consume.effects = [effect]
	var result := CombatResolver.resolve([poison, consume], player, enemy, 2000, 7)
	var model = State.new()
	model.begin(result)
	model.advance_to(999)
	check(model.statuses.poison == 5, "Poison application snapshot")
	model.advance_to(1000)
	check(model.statuses.poison == 0, "Tied natural tick then Consume snapshot")
	check("\n".join(model.journal).contains("not Consume") and "\n".join(model.journal).contains("consume"), "Tick depletion and Consume distinguished in history")


func _potency_hud() -> void:
	# Synthetic lifecycle isolates placement, refresh and timer boundaries in both HUD paths.
	var fixture := CombatResolver.CombatResult.new()
	fixture.duration_ms = 9000
	for row in [{"time": 0, "expiry": 3000}, {"time": 2000, "expiry": 6000}]:
		for id in ["potency", "penetration"]:
			fixture.trace.record("effect_lifecycle", row.time, {"effect_instance_id": id}, {"effect_id": id, "after": {"units": 5 if row.time == 0 else 100, "expires_at_ms": row.expiry}})
	var view := TrainingRoomCombatView.new()
	root.add_child(view)
	view.size = Vector2(1000, 560)
	var presenter := CombatPlaybackPresenter.new()
	root.add_child(presenter)
	presenter.effect_icons = view._effect_icons
	presenter.set_hud_widgets(null, null, null, null, func():
		for child in view._status_row.get_children():
			view._status_row.remove_child(child)
			child.queue_free(), view._add_status_chip)
	for mode in ["Practice", "Test Mode"]:
		view._effect_icons.begin(fixture)
		var poison_x := -1.0
		for step in [{"time": 1500, "progress": 0.5}, {"time": 2000, "progress": 1.0}, {"time": 4000, "progress": 0.5}, {"time": 6000, "progress": -1.0}]:
			view._effect_icons.advance_to(step.time)
			if mode == "Practice": view._update_status_readout()
			else: presenter._update_hud_readout()
			await process_frame
			await process_frame
			var chips := {}
			for item in view._status_row.find_children("*", "HBoxContainer", true, false):
				if item.has_node("Icon"): chips[item.get_node("Icon").texture] = item
			var poison = chips[GameIcons.icon_for("status.poison")]
			check(poison.get_node("Icon").texture == GameIcons.icon_for("status.poison"), mode + " Poison remains present beside paired defense columns")
			if poison_x < 0: poison_x = poison.position.x
			check(is_equal_approx(poison.position.x, poison_x), mode + " changing or expiring stacks never moves Poison")
			var last = view._status_row.get_child(view._status_row.get_child_count() - 1)
			check(last.global_position.x + last.size.x <= view.global_position.x + view.size.x, mode + " final status stays inside combat view")
			for index in 2:
				var id := "status.penetration" if index == 0 else "status.potency"
				var chip = chips[GameIcons.icon_for(id)]
				check(chip.get_node("Icon").texture == GameIcons.icon_for(id), mode + " permanent " + id)
				if step.progress < 0:
					check(chip.get_node("Text").text == "x0" and chip.get_node("Icon").material != null and not chip.has_node("Icon/Countdown"), mode + " expired defense is grey x0 without timer")
				else:
					check(chip.get_node("Icon").material == null and is_equal_approx(chip.get_node("Icon/Countdown").progress, step.progress), mode + " active defense colored with refreshed timer")
			if mode == "Practice" and "--potency-visual" in OS.get_cmdline_user_args() and step.time in [4000, 6000]:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://reports/p6_potency_hud/defense-%d.png" % step.time)
	view.queue_free()
	presenter.queue_free()
	await process_frame
