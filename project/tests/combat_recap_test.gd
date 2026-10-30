extends SceneTree
## Focused P2:R7:T7 / P3:M2:T2 check for CombatRecap's shared summary data:
## required-DPS-vs-actual, shortfall/overkill, biggest hit (with crit flag),
## physical/poison split, crit count, armor-reduction summary facts, poison
## tick/stack facts, and mitigation-relevant final values. Follows the same
## direct-call-plus-live-scene pattern as enemy_panel_test.gd (P2:R7:T5) and
## deterministic_replay_test.gd (P2:R5:T10): a known deterministic
## CombatResolver.resolve() call feeds the pure recap summary, and the
## expected values are computed independently in this test (not by calling
## the same aggregation code under test) so the assertions are a real check,
## not a tautology.


var _failed := false
const CombatLogInspectorDataScript := preload("res://scripts/systems/combat_log_inspector_data.gd")


func _initialize() -> void:
	_check_summary_with_poison_crit_and_armor_reduction()
	_check_summary_with_physical_only()
	_check_summary_with_zero_damage_cast()
	_check_summary_with_no_casts()
	_check_log_inspector_data()
	_check_combat_log_readability_format()
	_check_zero_value_mitigated_hits_remain_visible()
	await _check_live_win_recap()
	await _check_live_loss_recap()
	if _failed:
		print("Combat recap check: FAILED")
		quit(1)
	else:
		print("Combat recap check: OK")
		quit()


## A rotation of Poison Strike (poison) + Rending Slash (armor reduction),
## guaranteed crits (crit_chance = 1.0) so biggest-hit's crit flag and the
## crit count are both unambiguous, against a monster with enough HP that
## the fight runs the full window (armor reduction and poison stacking both
## need multiple casts to be interesting).
func _check_summary_with_poison_crit_and_armor_reduction() -> void:
	var poison_strike: Skill = load("res://data/skills/poison_strike.tres")
	var rending_slash: Skill = load("res://data/skills/rending_slash.tres")
	var rotation: Array[Skill] = [poison_strike, rending_slash]

	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 1.0
	player.crit_multiplier = 2.0
	player.poison_damage_per_tick = 50.0

	var monster := Monster.new()
	monster.display_name = "Recap Dummy"
	monster.hp = 100000
	monster.armor = 200
	monster.poison_resistance = 0.0

	var duration_ms := 8000
	var result: CombatResolver.CombatResult = CombatResolver.resolve(rotation, player, monster, duration_ms, 3)
	_require(not result.cast_events.is_empty(), "Expected at least one cast in the known fight.")

	# -- Independently computed expected values, from the same result. --
	var expected_biggest := 0.0
	var expected_biggest_skill := ""
	var expected_biggest_crit := false
	var expected_crit_count := 0
	var expected_physical := 0.0
	var expected_armor_total := 0
	var expected_armor_casts := 0
	for event in result.cast_events:
		expected_physical += event.physical_damage
		if event.physical_damage > expected_biggest:
			expected_biggest = event.physical_damage
			expected_biggest_skill = event.skill.display_name
			expected_biggest_crit = event.is_crit
		if event.is_crit:
			expected_crit_count += 1
		if event.armor_reduction_applied > 0:
			expected_armor_total += event.armor_reduction_applied
			expected_armor_casts += 1
	var expected_poison := 0.0
	var expected_ticks := 0
	var expected_peak_stacks := 0
	for tick in result.tick_events:
		if tick.damage <= 0.0:
			continue
		expected_ticks += 1
		expected_poison += tick.damage
		var stacks_before: int = tick.stacks_remaining + 1
		if stacks_before > expected_peak_stacks:
			expected_peak_stacks = stacks_before
	_require(expected_armor_casts > 0, "Expected Rending Slash to apply armor reduction at least once in this known fight.")
	_require(expected_ticks > 0, "Expected Poison Strike to produce at least one poison tick in this known fight.")

	var summary := CombatRecap.summarize(result, monster)
	print("-- CombatRecap summary (poison + armor reduction + crits) --")
	print(summary)
	_require(is_equal_approx(summary["total_damage"], result.total_damage), "Expected summary total damage to match the result.")
	_require(is_equal_approx(summary["actual_dps"], result.dps), "Expected summary actual DPS to match the result.")
	_require(summary["damage_required"] == monster.hp, "Expected required damage to come from monster HP.")
	_require(is_equal_approx(summary["damage_shortfall"], float(monster.hp) - result.total_damage), "Expected losing damage shortfall.")
	_require(is_equal_approx(summary["overkill"], 0.0), "Expected no overkill for the high-HP dummy.")
	_require(is_equal_approx(summary["damage_delta"], result.total_damage - float(monster.hp)), "Expected signed damage delta.")
	_require(is_equal_approx(summary["required_dps"], float(monster.hp) / (float(duration_ms) / 1000.0)), "Expected required-DPS to be HP / window seconds.")
	_require(is_equal_approx(summary["biggest_hit"], expected_biggest), "Expected biggest hit to match the independently computed largest cast.")
	_require(summary["biggest_hit_skill"] == expected_biggest_skill, "Expected biggest-hit skill name to match.")
	_require(summary["biggest_hit_was_crit"] == expected_biggest_crit, "Expected biggest-hit crit flag to match.")
	_require(expected_biggest_crit, "Expected the biggest hit to be a crit with crit_chance = 1.0.")
	_require(summary["crit_count"] == expected_crit_count, "Expected crit count to match.")
	_require(expected_crit_count == result.cast_events.size(), "Expected every cast to crit with crit_chance = 1.0.")
	var expected_total := expected_physical + expected_poison
	var expected_physical_pct := expected_physical / expected_total * 100.0
	var expected_poison_pct := expected_poison / expected_total * 100.0
	_require(is_equal_approx(summary["physical_damage"], expected_physical), "Expected physical damage to match direct casts.")
	_require(is_equal_approx(summary["poison_damage"], expected_poison), "Expected poison damage to match damaging poison ticks.")
	_require(summary["poison_damage"] > summary["physical_damage"], "Expected this fixture to cover a poison-heavy damage mix.")
	_require(is_equal_approx(summary["physical_pct"], expected_physical_pct), "Expected physical percentage to match.")
	_require(is_equal_approx(summary["poison_pct"], expected_poison_pct), "Expected poison percentage to match.")
	_require(summary["armor_reduction_total"] == expected_armor_total, "Expected armor reduction total to match.")
	_require(summary["armor_reduction_casts"] == expected_armor_casts, "Expected armor reduction cast count to match.")
	_require(summary["base_armor"] == monster.armor, "Expected base armor copied from the monster.")
	_require(summary["final_armor"] == monster.armor - expected_armor_total, "Expected final armor to include every armor reduction.")
	_require(summary["poison_tick_count"] == expected_ticks, "Expected damaging poison tick count to match.")
	_require(summary["peak_poison_stacks"] == expected_peak_stacks, "Expected peak poison stacks to match.")
	_require(is_equal_approx(summary["poison_tick_damage"], expected_poison), "Expected poison tick damage alias to match poison damage.")
	_require(summary["base_poison_resistance"] == monster.poison_resistance, "Expected base poison resistance copied from the monster.")
	_require(is_equal_approx(summary["final_poison_resistance"], monster.poison_resistance), "Expected unchanged final poison resistance in this fixture.")


## A rotation of Stab (pure physical, no poison/armor effects) so the recap
## must omit the armor-reduction and poison-summary lines entirely rather
## than showing a zero/N-A line, per the task's explicit "keep it scannable"
## requirement.
func _check_summary_with_physical_only() -> void:
	var stab: Skill = load("res://data/skills/stab.tres")
	var rotation: Array[Skill] = [stab]

	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0

	var monster := Monster.new()
	monster.display_name = "No Frills Dummy"
	monster.hp = 100000
	monster.armor = 0
	monster.poison_resistance = 0.0

	var duration_ms := 4000
	var result: CombatResolver.CombatResult = CombatResolver.resolve(rotation, player, monster, duration_ms, 1)
	_require(not result.cast_events.is_empty(), "Expected at least one cast in the no-frills fight.")

	var summary := CombatRecap.summarize(result, monster)
	print("-- CombatRecap summary (physical only) --")
	print(summary)
	_require(summary["cast_count"] == result.cast_events.size(), "Expected cast count to match the result.")
	_require(summary["physical_damage"] > 0.0, "Expected physical-only fixture to deal physical damage.")
	_require(is_equal_approx(summary["poison_damage"], 0.0), "Expected no poison damage for Stab.")
	_require(is_equal_approx(summary["physical_pct"], 100.0), "Expected all damage to be physical.")
	_require(is_equal_approx(summary["poison_pct"], 0.0), "Expected zero poison share.")
	_require(summary["armor_reduction_casts"] == 0, "Expected no armor reduction casts.")
	_require(summary["armor_reduction_total"] == 0, "Expected no armor reduction total.")
	_require(summary["poison_tick_count"] == 0, "Expected no damaging poison ticks.")
	_require(summary["peak_poison_stacks"] == 0, "Expected no peak poison stacks.")
	_require(summary["crit_count"] == 0, "Expected no crits with crit_chance = 0.")


func _check_summary_with_zero_damage_cast() -> void:
	var feint := Skill.new()
	feint.id = "skill.test_feint"
	feint.display_name = "Feint"
	feint.base_execution_ms = 1000
	feint.min_execution_ms = 1000
	var rotation: Array[Skill] = [feint]

	var player := PlayerStats.new()
	var monster := Monster.new()
	monster.display_name = "Zero Damage Dummy"
	monster.hp = 50
	monster.armor = 0
	monster.poison_resistance = 0.0

	var result: CombatResolver.CombatResult = CombatResolver.resolve(rotation, player, monster, 3000, 1)
	_require(result.cast_events.size() == 3, "Expected the no-effect skill to still produce cast events.")
	_require(is_equal_approx(result.total_damage, 0.0), "Expected the no-effect skill to deal zero damage.")

	var summary := CombatRecap.summarize(result, monster)
	print("-- CombatRecap summary (zero damage cast) --")
	print(summary)
	_require(summary["cast_count"] == 3, "Expected zero-damage casts to be counted.")
	_require(is_equal_approx(summary["total_damage"], 0.0), "Expected zero total damage.")
	_require(summary["biggest_hit_skill"] == "", "Expected no biggest-hit skill when every cast deals zero physical damage.")
	_require(is_equal_approx(summary["damage_shortfall"], 50.0), "Expected full HP shortfall at zero damage.")
	_require(is_equal_approx(summary["overkill"], 0.0), "Expected no overkill at zero damage.")
	_require(is_equal_approx(summary["physical_pct"], 0.0), "Expected zero physical percentage with zero total damage.")
	_require(is_equal_approx(summary["poison_pct"], 0.0), "Expected zero poison percentage with zero total damage.")


func _check_summary_with_no_casts() -> void:
	var rotation: Array[Skill] = []
	var player := PlayerStats.new()
	var monster := Monster.new()
	monster.display_name = "No Cast Dummy"
	monster.hp = 75
	monster.armor = 12
	monster.poison_resistance = 0.25

	var result: CombatResolver.CombatResult = CombatResolver.resolve(rotation, player, monster, 5000, 1)
	_require(result.cast_events.is_empty(), "Expected empty rotation to produce no casts.")

	var summary := CombatRecap.summarize(result, monster)
	print("-- CombatRecap summary (no casts) --")
	print(summary)
	_require(summary["cast_count"] == 0, "Expected no casts counted.")
	_require(is_equal_approx(summary["total_damage"], 0.0), "Expected no-cast result to deal zero damage.")
	_require(is_equal_approx(summary["required_dps"], 15.0), "Expected required DPS to still be computed from HP/window.")
	_require(is_equal_approx(summary["damage_shortfall"], 75.0), "Expected full HP shortfall for no casts.")
	_require(summary["base_armor"] == 12 and summary["final_armor"] == 12, "Expected armor unchanged without casts.")
	_require(is_equal_approx(summary["base_poison_resistance"], 0.25), "Expected base resistance copied.")
	_require(is_equal_approx(summary["final_poison_resistance"], 0.25), "Expected resistance unchanged without casts.")


func _check_log_inspector_data() -> void:
	var poison_strike: Skill = load("res://data/skills/poison_strike.tres")
	var rending_slash: Skill = load("res://data/skills/rending_slash.tres")
	var rotation: Array[Skill] = [poison_strike, rending_slash]

	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 1.0
	player.crit_multiplier = 2.0
	player.poison_damage_per_tick = 50.0

	var monster := Monster.new()
	monster.display_name = "Inspector Dummy"
	monster.hp = 100000
	monster.armor = 200
	monster.poison_resistance = 0.0

	var result: CombatResolver.CombatResult = CombatResolver.resolve(rotation, player, monster, 8000, 3)
	var inspector := CombatLogInspectorDataScript.build(result, monster)
	print("-- Combat Log inspector data --")
	_require(inspector["duration_ms"] == result.duration_ms, "Expected inspector duration to come from the combat result.")
	_require(inspector["summary"]["damage_required"] == monster.hp, "Expected inspector summary to include monster HP threshold.")
	_require(is_equal_approx(float(inspector["max_event_damage"]), _expected_max_event_damage(result)), "Expected max event damage to include casts, procs, and poison ticks.")

	var timeline_rows: Array = inspector["timeline_rows"]
	_require(_has_timeline_row(timeline_rows, "Poison Strike"), "Expected a Poison Strike timeline row.")
	_require(_has_timeline_row(timeline_rows, "Rending Slash"), "Expected a Rending Slash timeline row.")
	_require(_has_timeline_row(timeline_rows, "Poison Ticks"), "Expected a Poison Ticks timeline row for damaging poison ticks.")
	_require(_timeline_row(timeline_rows, "Poison Strike")["icon"] is Texture2D, "Expected skill timeline rows to carry skill icons.")
	var poison_row := _timeline_row(timeline_rows, "Poison Ticks")
	_require(poison_row["kind"] == CombatLogInspectorDataScript.KIND_POISON, "Expected poison ticks to use the poison row kind.")
	_require(poison_row["icon"] is Texture2D, "Expected poison tick row to carry the poison icon.")
	_require(poison_row["events"].size() > 0, "Expected poison row to include damaging tick markers.")

	var damage_rows: Array = inspector["damage_rows"]
	_require(damage_rows.size() >= 2, "Expected multiple ranked damage rows.")
	for i in range(1, damage_rows.size()):
		_require(float(damage_rows[i - 1]["damage"]) >= float(damage_rows[i]["damage"]), "Expected damage rows to be sorted descending.")
	_require(_has_damage_row(damage_rows, "Poison Ticks"), "Expected poison tick damage to aggregate into its own ranked row.")
	_require(_damage_row(damage_rows, "Poison Ticks")["icon"] is Texture2D, "Expected poison damage row to carry the poison icon.")


func _check_combat_log_readability_format() -> void:
	var poison_strike: Skill = load("res://data/skills/poison_strike.tres")
	var quick_cut: Skill = load("res://data/skills/quick_cut.tres")
	var rotation: Array[Skill] = [poison_strike, quick_cut]

	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	player.poison_damage_per_tick = 8.0

	var monster := Monster.new()
	monster.display_name = "Readable Dummy"
	monster.hp = 40
	monster.armor = 0
	monster.poison_resistance = 0.0

	var result: CombatResolver.CombatResult = CombatResolver.resolve(rotation, player, monster, 5000, 1)
	result.cast_events[0].min_cast_time_proc_applied = true
	var adventure_log := CombatResultFormatter.format(result, monster)
	var practice_log := CombatResultFormatter.format_practice(result, monster)
	print("-- Combat Log readability format --")
	print(adventure_log)
	_require(adventure_log.begins_with("Target:\n  Readable Dummy -- 40 HP"), "Expected Adventure log to begin with a clear target section.")
	_require(adventure_log.contains("\nTimeline:\n"), "Expected Adventure log to label the chronological timeline section.")
	_require(adventure_log.contains("\nSummary:\n"), "Expected Adventure log to label the summary section.")
	_require(adventure_log.contains("procs at minimum cast speed"), "Expected minimum-cast procs to retain their body explanation.")
	_require(not adventure_log.contains(">>> "), "Expected roots to retain CAST labels without child markers.")
	_require(adventure_log.contains("CAST"), "Expected normal casts to carry a readable cast line label.")
	_require(adventure_log.contains("DOT       Poison ticks for"), "Expected poison tick lines to carry a readable DOT label.")
	_require(not adventure_log.contains("Poison ticks for 0.0"), "Expected zero-damage poison cadence ticks to remain omitted.")
	_require(adventure_log.contains("Result: "), "Expected Adventure log summary to label the result line.")
	_require(practice_log.begins_with("Practice Target:\n  Readable Dummy -- 0 Armor"), "Expected Practice Room log to use practice-safe target language.")
	_require(practice_log.contains("\nTimeline:\n"), "Expected Practice Room log to share the readable timeline section.")
	_require(practice_log.contains("\nSummary:\n  Damage:"), "Expected Practice Room log to share the readable damage summary.")
	_require(not practice_log.contains("VICTORY") and not practice_log.contains("DEFEAT") and not practice_log.contains("Result:"), "Expected Practice Room log to avoid Adventure win/loss language.")


func _check_zero_value_mitigated_hits_remain_visible() -> void:
	var blocked_skill := Skill.new()
	blocked_skill.display_name = "Blocked Jab"
	blocked_skill.base_execution_ms = 1000
	blocked_skill.min_execution_ms = 500
	var physical := PhysicalDamageEffect.new()
	physical.amount = 10.0
	blocked_skill.effects = [physical]
	var blocked_monster := Monster.new()
	blocked_monster.display_name = "Blocking Dummy"
	blocked_monster.hp = 1000
	blocked_monster.block = 50.0
	var blocked_result := CombatResolver.resolve([blocked_skill], PlayerStats.new(), blocked_monster, 1000, 3)
	var blocked_log := CombatResultFormatter.format_practice(blocked_result, blocked_monster)
	_require(blocked_log.contains("Blocked Jab hits for 0.0 (blocked 10.0)"), "Expected fully blocked physical hits to remain visible as zero-value hits.")

	var poison_strike: Skill = load("res://data/skills/poison_strike.tres")
	var absorb_player := PlayerStats.new()
	absorb_player.poison_damage_per_tick = 8.0
	var absorb_monster := Monster.new()
	absorb_monster.display_name = "Absorbing Dummy"
	absorb_monster.hp = 1000
	absorb_monster.absorb = 20.0
	var absorb_result := CombatResolver.resolve([poison_strike], absorb_player, absorb_monster, 2500, 3)
	var absorb_log := CombatResultFormatter.format_practice(absorb_result, absorb_monster)
	_require(absorb_log.contains("Poison ticks for 0.0 (absorbed 8.0)"), "Expected fully absorbed poison ticks to remain visible as zero-value hits.")


func _has_timeline_row(rows: Array, label: String) -> bool:
	return not _timeline_row(rows, label).is_empty()


func _timeline_row(rows: Array, label: String) -> Dictionary:
	for row in rows:
		if String(row["label"]) == label:
			return row
	return {}


func _has_damage_row(rows: Array, label: String) -> bool:
	return not _damage_row(rows, label).is_empty()


func _expected_max_event_damage(result: CombatResolver.CombatResult) -> float:
	var max_damage := 0.0
	for event in result.cast_events:
		if event.damage_contributions.is_empty():
			max_damage = maxf(max_damage, event.physical_damage)
		else:
			for contribution in event.damage_contributions:
				max_damage = maxf(max_damage, float(contribution.get("damage", 0.0)))
	for tick in result.tick_events:
		max_damage = maxf(max_damage, tick.damage)
	return max_damage


func _damage_row(rows: Array, label: String) -> Dictionary:
	for row in rows:
		if String(row["name"]) == label:
			return row
	return {}


## Live end-to-end check: a real winning Tavern fight through the actual
## combat_screen scene shows the compact victory recap inside the result
## banner. Deeper DPS/crit/stack diagnostics belong in playback and Combat Log.
func _check_live_win_recap() -> void:
	var build_state = root.get_node("BuildState")
	build_state.reset()
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	build_state.set_class(rogue)
	build_state.select_tree(rogue.trees[1])
	build_state.choose_current_tavern_encounter()
	# Quick Cut alone (Bladedancer's tree unlock, no talents needed) casts every
	# 850ms for 12 damage -- roughly 14 casts in the Mouthy Drunk opener's
	# 12s window, ~168 baseline damage before any crits, comfortably above
	# the current Mouthy Drunk HP check regardless of this fight's deterministic
	# crit rolls.
	# Set directly here since this test only needs the resulting fight, not
	# a click-through of the build panels (combat_screen_test.gd already
	# covers that UI path).
	var quick_cut: Skill = load("res://data/skills/quick_cut.tres")
	var win_rotation: Array[Skill] = [quick_cut]
	build_state.rotation = win_rotation

	var combat_screen := _instantiate_combat_screen()
	await process_frame
	build_state.set_locked(true)

	# combat_screen builds its own EnemyPanel instance internally; drive the
	# fight the same way the user does, via the public fight_pressed signal
	# the panel exposes (same pattern combat_screen_test.gd already uses).
	var fight_enemy_panel = combat_screen._enemy_panel
	var monster: Monster = fight_enemy_panel.monster()

	print("-- Live win recap --")
	fight_enemy_panel.fight_pressed.emit()
	await process_frame
	_require(build_state.last_fight_won, "Expected the Mouthy Drunk Tavern fight to be winnable for this recap check.")
	_require(combat_screen._victory_overlay.visible, "Expected the victory overlay to be visible after a win.")
	var recap_text: String = combat_screen._victory_recap_label.text
	print(recap_text)
	_require(recap_text.contains("(needed %d)" % monster.hp), "Expected the live win recap to restate required damage.")
	_require(recap_text.contains("Biggest Hit:"), "Expected the live win recap to report the best landed hit.")
	_require(recap_text.contains("Physical:"), "Expected the live win recap to include the physical/poison split.")
	_require(not recap_text.contains("DPS:"), "Expected victory recap to omit DPS detail.")
	_require(not recap_text.contains("Contracts Completed:"), "Expected victory recap to omit run-loss summary detail.")
	_require(not recap_text.contains("Highest DPS This Run:"), "Expected victory recap to omit run-loss summary detail.")
	_require(not recap_text.contains("Crits:"), "Expected victory recap to omit crit count detail.")
	_require(not combat_screen._recap_label.visible, "Expected the loss-path recap label to stay hidden on a win.")

	combat_screen.queue_free()


## Live end-to-end check: a real losing fight (guaranteed by an intentionally
## impossible HP target, not an empty macro) shows the recap inside the same
## combat-window result overlay shape as victory.
func _check_live_loss_recap() -> void:
	var build_state = root.get_node("BuildState")
	build_state.reset()
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	build_state.set_class(rogue)
	build_state.select_tree(rogue.trees[1])
	build_state.choose_current_tavern_encounter()
	build_state.completed_contract_count = 3
	build_state.record_fight_dps(123.4)
	var stab: Skill = load("res://data/skills/stab.tres")
	var loss_rotation: Array[Skill] = [stab]
	build_state.rotation = loss_rotation

	var combat_screen := _instantiate_combat_screen()
	await process_frame
	build_state.set_locked(true)

	var fight_enemy_panel = combat_screen._enemy_panel
	var monster: Monster = fight_enemy_panel.monster()
	monster.hp = 100000

	print("-- Live loss recap --")
	fight_enemy_panel.fight_pressed.emit()
	await process_frame
	_require(not build_state.last_fight_won, "Expected the impossible-HP target to guarantee a loss.")
	_require(combat_screen._victory_overlay.visible, "Expected the result overlay to be visible after a loss.")
	_require(combat_screen._victory_title_label.text == "DEFEATED", "Expected the shared result overlay to present the defeat title.")
	_require(not combat_screen._outcome_message_label.visible, "Expected the defeat overlay to omit the older explanatory body copy.")
	var recap_text: String = combat_screen._victory_recap_label.text
	print(recap_text)
	_require(recap_text.contains("(needed %d)" % monster.hp), "Expected the loss recap to show damage against the required amount.")
	_require(recap_text.contains("Biggest Hit: Stab"), "Expected the loss recap to report the best landed hit.")
	_require(recap_text.contains("Physical:"), "Expected the loss recap to include the physical/poison split.")
	_require(not recap_text.contains("DPS:"), "Expected defeat recap to match victory by omitting DPS detail.")
	_require(recap_text.contains("Contracts Completed: 3"), "Expected defeat recap to include completed contract count.")
	_require(recap_text.contains("Highest DPS This Run: 123.4"), "Expected defeat recap to include best run DPS.")
	_require(not recap_text.contains("Crits:"), "Expected defeat recap to match victory by omitting crit count detail.")
	_require(not recap_text.contains("Armor reduced"), "Expected no armor reduction line for a no-op rotation.")
	_require(not recap_text.contains("ticks"), "Expected no poison summary line for a physical-only rotation.")
	_require(not combat_screen._recap_label.visible, "Expected the legacy inline recap label to stay hidden on a live defeat overlay.")

	combat_screen.queue_free()


func _instantiate_combat_screen() -> Node:
	var combat_scene: PackedScene = load("res://scenes/combat/combat_screen.tscn")
	var combat_screen = combat_scene.instantiate()
	root.add_child(combat_screen)
	return combat_screen


## Tracks failure via _failed rather than quitting immediately: several
## checks in this file run after an `await process_frame` (the live win/loss
## checks), and an immediate quit(1) here would only request a shutdown that
## the still-in-flight coroutine execution wouldn't actually stop at, while
## _initialize()'s own final bare quit() would then silently overwrite the
## exit code back to 0. Recording the failure and quitting once at the very
## end of _initialize() keeps a real failure from being masked.
func _require(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
