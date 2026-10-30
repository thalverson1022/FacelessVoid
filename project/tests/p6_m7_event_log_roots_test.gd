extends SceneTree
const Style = preload("res://scripts/ui/skill_category_preview_style.gd")
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + label)
func snapshot(result: CombatResolver.CombatResult) -> String:
	var values: Array = []
	for event in result.cast_events + result.tick_events:
		var fields := {}
		for property in event.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				fields[property.name] = event.get(property.name)
		values.append(fields)
	return JSON.stringify([values, result.trace.presentation_records, result.total_damage, result.rng_final_state])
func fixture() -> Dictionary:
	var stats := PlayerStats.new()
	stats.weapon_damage_min = 100
	stats.weapon_damage_max = 100
	stats.retrigger_chance = 0.4
	stats.dance_duration_ms = 5000
	stats.readiness_enabled = true
	stats.poison_damage_per_tick = 10
	var opportunity := TriggeredSkillEffect.new()
	opportunity.skill = load("res://data/skills/rending_slash.tres")
	opportunity.chance = 0.3
	opportunity.source_skill_ids = ["skill.quick_cut"]
	stats.triggered_skill_effects = [opportunity]
	var enemy := Monster.new()
	enemy.hp = 100000000
	var dance: Skill = preload("res://scripts/systems/p6_thief_contracts.gd").skill("dance_of_death")
	var rotation: Array[Skill] = [dance, load("res://data/skills/quick_cut.tres"), load("res://data/skills/venom_jab.tres"), preload("res://scripts/systems/p6_poison_contracts.gd").poison_strike()]
	return {"result": CombatResolver.resolve(rotation, stats, enemy, 10000, 7, true), "target": enemy}
func run() -> void:
	var data := fixture()
	var result: CombatResolver.CombatResult = data.result
	check(result.is_valid, "real resolver fixture valid")
	var before := snapshot(result)
	var text := CombatResultFormatter.event_log(result)
	var lines := text.split("\n")
	var index := CombatResultFormatter._cast_index(result)
	var row := 0
	var origins := {}
	var labels := {}
	for entry in CombatPlayback._merge_events(result):
		if entry.is_tick:
			if not entry.tick.had_active_stack: continue
			var tick_text := CombatResultFormatter._tick_line(entry.tick)
			check(lines[row].ends_with(tick_text.substr(tick_text.find("Poison ticks"))), "tick sequence and values preserved")
		else:
			var cast: CombatResolver.CastEvent = entry.cast
			origins[cast.origin_kind] = true
			labels[cast.trigger_label] = true
			var depth := CombatResultFormatter._cast_depth(cast, index)
			check(lines[row] == CombatResultFormatter._hierarchy_line(CombatResultFormatter._cast_line(cast), cast, index), "cast sequence and narrative preserved")
			if cast.parent_cast_id == 0:
				check(depth == 0 and not lines[row].begins_with(" "), "each macro stays left aligned")
				if not cast.cooldown_blocked and not cast.resource_unavailable and not cast.was_interrupted:
					check(lines[row].contains("] CAST "), "each successful macro remains CAST despite child trigger labels")
			else:
				check(depth > 0 and lines[row].begins_with("    ") and lines[row].contains("-> "), "each actual child has visible ancestry")
		row += 1
	check(row == lines.size(), "one line per visible chronological event")
	check(origins.has("guaranteed_repeat") and origins.has("random_repeat") and labels.has("Opportunity Strike"), "real guaranteed/random repeats and Opportunity Strike witnesses")
	check(text.contains("CAST Dance Of Death - Guaranteed Retriggers"), "self buff explains its successful outcome")
	check(not text.contains("Dance Of Death connects"), "successful Dance is not described as no effect")
	CombatResultFormatter.format(result, data.target)
	CombatResultFormatter.format_practice(result, data.target)
	Style.log_text(result)
	check(snapshot(result) == before, "all source event fields, trace, totals and RNG unchanged by all formatters")
	FileAccess.open("res://reports/event_log_roots.txt", FileAccess.WRITE).store_string(text)
	# Explicit ancestry takes precedence over a stale depth, independent roots
	# remain separate even when their rounded timestamps and milliseconds tie.
	var tied := CombatResolver.CombatResult.new()
	for i in 12:
		var event := CombatResolver.CastEvent.new()
		event.skill = load("res://data/skills/quick_cut.tres")
		event.cast_id = i + 1
		event.root_cast_id = 1
		event.parent_cast_id = i
		event.cast_kind = "cast" if i == 0 else "proc"
		event.trigger_label = "RETRIGGER"
		event.time_ms = 1200
		event.sequence = i + 1
		event.retrigger_depth = 99
		tied.cast_events.append(event)
	var root2 := CombatResolver.CastEvent.new()
	root2.skill = load("res://data/skills/stab.tres")
	root2.cast_id = 13
	root2.root_cast_id = 13
	root2.sequence = 13
	root2.time_ms = 1200
	root2.trigger_labels = ["Opportunity Strike"]
	root2.triggered_skill_names = ["Rending Thrust"]
	root2.min_cast_time_proc_applied = true
	tied.cast_events.append(root2)
	var tied_lines := CombatResultFormatter._timeline(tied)
	check(tied_lines[0].begins_with("[1.2s] CAST") and tied_lines[12].begins_with("[1.2s] CAST"), "same timestamp independent roots keep distinct CAST rows")
	check(tied_lines[12].contains("procs at minimum cast speed"), "minimum cast proc remains a body clause")
	check(tied_lines[2].begins_with("        -> "), "authoritative parent chain overrides stale reported depth")
	check(tied_lines[11].begins_with("                        -> [depth 11]"), "deep chain bounded to six indent levels with actual depth")
	var legacy := CombatResolver.CastEvent.new()
	legacy.cast_kind = "proc"
	legacy.skill = root2.skill
	check(CombatResultFormatter._cast_depth(legacy, {}) == 1 and CombatResultFormatter._event_type_label(legacy) == "PROC", "legacy child without IDs remains child")
	legacy.cast_id = 1
	legacy.parent_cast_id = 1
	check(CombatResultFormatter._cast_depth(legacy, {1:legacy}) == 1, "self cycle terminates")
	var tick := CombatResolver.TickEvent.new()
	tick.origin_kind = "natural_tick"
	check(CombatResultFormatter._tick_hierarchy_line("tick", tick, {"cast_id":1}, CombatResultFormatter._cast_index(tied)) == "tick", "independent natural cadence stays at left even with nearby context")
	tick.origin_kind = "forced_tick"
	check(CombatResultFormatter._tick_hierarchy_line("DOT       tick", tick, {"cast_id":2}, CombatResultFormatter._cast_index(tied)) == "        -> DOT (from Quick Cut)       tick", "forced tick uses recorded source cast ancestry")
	check(CombatResultFormatter._tick_hierarchy_line("tick", tick, {}, CombatResultFormatter._cast_index(tied)) == "tick", "missing tick context never invents a parent from timestamp")
	tick.origin_kind = "poison_repeat"
	tick.legendary_depth = 2
	check(CombatResultFormatter._tick_hierarchy_line("DOT       tick", tick, {"cast_id":1}, CombatResultFormatter._cast_index(tied)) == "            -> DOT (from Quick Cut)       tick", "recorded free poison repeat retains depth")
	legacy.trigger_label = "LEGENDARY"
	check(CombatResultFormatter._event_type_label(legacy) == "LEGENDARY", "explicit legendary child label retained")
	legacy.origin_kind = "lightning_repeat"
	check(CombatResultFormatter._event_type_label(legacy) == "LIGHTNING RETRIGGER", "lightning child label retained")
	print("Event log roots PASS" if not failed else "Event log roots FAILED")
	quit(1 if failed else 0)
