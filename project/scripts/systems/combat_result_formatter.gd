class_name CombatResultFormatter
extends RefCounted
## Renders a CombatResolver.CombatResult as a human-readable fight
## narrative: a header describing the matchup, a single chronological
## timeline (casts and poison ticks merged, in seconds), and a summary
## verdict. Zero-damage poison ticks (cadence beats with no stacks active)
## are noise and get skipped.


static func format(result: CombatResolver.CombatResult, monster: Monster) -> String:
	if not result.is_valid:
		return invalid_simulation_message(result)
	var lines: PackedStringArray = []
	lines.append("Target:")
	lines.append("  %s -- %d HP, %d Armor, %.0f%% Resist" % [
		monster.display_name, monster.hp, monster.armor, monster.poison_resistance * 100.0
	])
	lines.append("  Combat window: %.0fs" % (result.duration_ms / 1000.0))
	lines.append("")
	lines.append("Timeline:")

	var timeline := _timeline(result)
	if timeline.is_empty():
		lines.append("  Nothing happened -- no skills were cast.")
	else:
		for line in timeline:
			lines.append("  %s" % line)

	lines.append("")
	lines.append("Summary:")
	lines.append("  Damage: %.1f in %.0fs -- %.1f DPS." % [
		result.total_damage, result.duration_ms / 1000.0, result.dps
	])
	if result.total_health_removed > 0:
		lines.append("  Health removed: %.1f." % result.total_health_removed)
	if result.gold_stolen > 0:
		lines.append("  Gold stolen: %dg." % result.gold_stolen)
	if result.is_win and result.overkill_damage > 0.0:
		lines.append("  Overkill: %.1f health loss." % result.overkill_damage)
	if result.is_win:
		lines.append("  Result: VICTORY! %s is defeated (needed %d health loss)." % [monster.display_name, monster.hp])
	else:
		lines.append("  Result: DEFEAT -- fell %.1f health loss short of the %d needed." % [
			float(monster.hp) - result.total_health_loss(), monster.hp
		])
	return "\n".join(lines)


## Practice Room's own result narrative -- same timeline/summary shape as
## format() above, but with no HP/win-loss framing at all: Practice Room only
## measures damage dealt against a target's Armor/Resist in a fixed
## window, it never checks whether the target is "defeated" (post-R10
## UI-feedback pass removed the HP concept from Practice Room entirely).
static func format_practice(result: CombatResolver.CombatResult, monster: Monster) -> String:
	if not result.is_valid:
		return invalid_simulation_message(result)
	var lines: PackedStringArray = []
	lines.append("Practice Target:")
	lines.append("  %s -- %d Armor, %.0f%% Resist" % [
		monster.display_name, monster.armor, monster.poison_resistance * 100.0
	])
	lines.append("  Combat window: %.0fs" % (result.duration_ms / 1000.0))
	lines.append("")
	lines.append("Timeline:")

	var timeline := _timeline(result)
	if timeline.is_empty():
		lines.append("  Nothing happened -- no skills were cast.")
	else:
		for line in timeline:
			lines.append("  %s" % line)

	lines.append("")
	lines.append("Summary:")
	lines.append("  Damage: %.1f in %.0fs -- %.1f DPS." % [
		result.total_damage, result.duration_ms / 1000.0, result.dps
	])
	if result.total_health_removed > 0:
		lines.append("  Health removed: %.1f." % result.total_health_removed)
	if result.gold_stolen > 0:
		lines.append("  Gold stolen: %dg." % result.gold_stolen)
	return "\n".join(lines)


static func invalid_simulation_message(result: CombatResolver.CombatResult) -> String:
	if result.failure.get("code") in ["invalid_stat_derivation", "invalid_effect_lifecycle", "invalid_macro_schedule", "invalid_poison_ranks"]:
		return "Simulation stopped: %s. No fight outcome or rewards were applied." % result.failure.get("message", "Invalid stat derivation")
	return "Simulation stopped: %s at %.3fs (root cast %d, limit %d). No fight outcome or rewards were applied." % [
		result.failure.get("code", "unknown"), float(result.failure.get("time_ms", 0)) / 1000.0,
		int(result.failure.get("root_cast_id", 0)), int(result.failure.get("limit", 0))]


## Merges cast and tick events into one time-ordered list of prose lines.
## Both source arrays are already time-sorted; ties go to the tick, matching
## how the resolver processes cadence beats before same-time casts.
static func _timeline(result: CombatResolver.CombatResult) -> PackedStringArray:
	var lines: PackedStringArray = []
	var observations := {}
	for record in result.trace.presentation_records:
		observations[int(record.get("sequence", 0))] = record.get("payload", {})
	for entry in CombatPlayback._merge_events(result):
		if entry.is_tick:
			if entry.tick.had_active_stack:
				lines.append(_tick_line(entry.tick, observations.get(entry.sequence, {})))
		else:
			lines.append(_cast_line(entry.cast))
	return lines


## Group by authoritative milliseconds, never by rounded display strings.
static func _append_timeline_entry(lines: PackedStringArray, time_ms: int, previous_time: int, text: String) -> int:
	if time_ms != previous_time:
		if previous_time >= 0: lines.append("")
		lines.append("[%.3fs]" % (time_ms / 1000.0))
	# Existing event formatters retain their standalone timestamp contract.
	var start := text.find("[")
	var end := text.find("] ", start)
	var detail := text.substr(0, start) + text.substr(end + 2) if start >= 0 and end >= 0 else text
	lines.append("    " + detail.replace("\n", "\n    "))
	return time_ms


## `>>> ` prefixes any line where a proc-like effect actually fired, so
## retriggers, Opportunity Strikes, and Legendary minimum-cast procs are easy
## to spot while scanning the log instead of reading like ordinary hits.
static func _cast_line(event: CombatResolver.CastEvent) -> String:
	if event.cooldown_blocked:
		return "[%.1fs] %s on cooldown; spent 0.1s with no effect" % [event.time_ms / 1000.0, event.skill.display_name]
	if event.resource_unavailable:
		return "[%.1fs] %s had no Readiness at cast start; no effect" % [event.time_ms / 1000.0, event.skill.display_name]
	if event.was_interrupted:
		var interrupt_note := "skipped" if event.interrupt_skipped else "interrupted"
		var skill_name := event.skill.display_name if event.skill != null else "Attack"
		var skip_note := ""
		if event.interrupt_triggered and event.interrupt_skip_count_applied > 0:
			skip_note = " (%d future skip%s)" % [
				event.interrupt_skip_count_applied,
				"" if event.interrupt_skip_count_applied == 1 else "s",
			]
		return "[%.1fs] INTERRUPT %s %s%s" % [event.time_ms / 1000.0, skill_name, interrupt_note, skip_note]
	var event_type := _event_type_label(event)
	var marker := ">>> " if _is_proc_like_event(event) else ""
	if event.was_dodged:
		return "%s[%.1fs] %s %s was DODGED" % [
			marker,
			event.time_ms / 1000.0,
			event_type,
			event.skill.display_name,
		]
	var clauses: PackedStringArray = []
	if preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(event):
		clauses.append("removes %.1f health" % event.health_removed)
	var source_kind := "proc" if event.cast_kind == "proc" else "cast"
	var source_damage := _contribution_damage(event, source_kind)
	var source_crit := _contribution_crit(event, source_kind)
	if source_damage <= 0.0 and event.damage_contributions.is_empty():
		source_damage = event.physical_damage
		source_crit = event.is_crit
	if source_damage > 0.0:
		clauses.append(("CRITS for %.1f" if source_crit else "hits for %.1f") % source_damage)
	elif event.blocked_amount > 0.0:
		clauses.append("hits for 0.0 (blocked %.1f)" % event.blocked_amount)
	if event.poison_stacks_applied > 0:
		clauses.append("applies %d poison stack%s" % [
			event.poison_stacks_applied, "" if event.poison_stacks_applied == 1 else "s"
		])
	if event.shred_stacks_applied > 0:
		clauses.append("applies %d Shred" % event.shred_stacks_applied)
	if event.decay_stacks_applied > 0:
		clauses.append("applies %d Decay" % event.decay_stacks_applied)
	if event.gold_stolen > 0:
		clauses.append("steals %dg" % event.gold_stolen)
	if event.min_cast_time_proc_applied:
		clauses.append("procs at minimum cast speed")
	if event.stun_duration_ms > 0:
		clauses.append("triggers stun for %s" % _format_stun_duration(event.stun_duration_ms))
	var trigger_clauses: PackedStringArray = []
	if event.cast_kind != "proc":
		trigger_clauses = _triggered_contribution_clauses(event)
	if not trigger_clauses.is_empty():
		clauses.append_array(trigger_clauses)
	elif not event.triggered_skill_names.is_empty():
		clauses.append("triggers %s" % ", ".join(event.triggered_skill_names))
	if clauses.is_empty():
		clauses.append("connects, to no effect")
	var ending := "!" if event.is_crit else ""
	return "%s[%.1fs] %s %s %s%s" % [marker, event.time_ms / 1000.0, event_type, event.skill.display_name, _join_clauses(clauses), ending]


static func _event_type_label(event: CombatResolver.CastEvent) -> String:
	if event.cast_kind == "proc":
		return event.trigger_label if event.trigger_label.strip_edges() != "" else "PROC"
	if not event.trigger_labels.is_empty():
		return event.trigger_labels[0]
	if event.min_cast_time_proc_applied:
		return "LEGENDARY"
	return "CAST"


static func _is_proc_like_event(event: CombatResolver.CastEvent) -> bool:
	return (
		event.min_cast_time_proc_applied
		or event.cast_kind == "proc"
		or not event.triggered_skill_names.is_empty()
	)


static func _contribution_damage(event: CombatResolver.CastEvent, kind: String) -> float:
	var total := 0.0
	for contribution in event.damage_contributions:
		if String(contribution.get("kind", "")) == kind:
			total += float(contribution.get("damage", 0.0))
	return total


static func _contribution_crit(event: CombatResolver.CastEvent, kind: String) -> bool:
	for contribution in event.damage_contributions:
		if String(contribution.get("kind", "")) == kind and bool(contribution.get("is_crit", false)):
			return true
	return false


static func _triggered_contribution_clauses(event: CombatResolver.CastEvent) -> PackedStringArray:
	var clauses: PackedStringArray = []
	for contribution in event.damage_contributions:
		if String(contribution.get("kind", "")) != "proc":
			continue
		var name := String(contribution.get("name", "Triggered Skill"))
		var damage := float(contribution.get("damage", 0.0))
		var text := "triggers %s" % name
		if damage > 0.0:
			text += (" for %.1f" if not bool(contribution.get("is_crit", false)) else " for %.1f (crit)") % damage
		clauses.append(text)
	return clauses


static func _format_stun_duration(duration_ms: int) -> String:
	var seconds := float(duration_ms) / 1000.0
	if is_equal_approx(seconds, roundf(seconds)):
		return "%ds" % int(roundf(seconds))
	return "%.1fs" % seconds


## "a" / "a and b" / "a, b and c" -- reads as prose instead of a
## comma-separated field list.
static func _join_clauses(clauses: PackedStringArray) -> String:
	if clauses.size() == 1:
		return clauses[0]
	var head := ", ".join(clauses.slice(0, clauses.size() - 1))
	return "%s and %s" % [head, clauses[clauses.size() - 1]]


static func _tick_line(tick: CombatResolver.TickEvent, record: Dictionary = {}) -> String:
	var stacks_note := "1 stack remains" if tick.stacks_remaining == 1 else "%d stacks remain" % tick.stacks_remaining
	var absorb_note := " (absorbed %.1f)" % tick.absorbed_amount if tick.absorbed_amount > 0.0 else ""
	var detail := ""
	if tick.is_crit:
		detail += " CRIT"
	if tick.origin_kind == "forced_tick":
		detail += " (forced)"
	if tick.origin_kind == "poison_repeat":
		detail += " (Retrigger; free, current buffs; no Consume)"
	elif bool(record.get("keyword_consume", false)):
		detail += " (Consume %d stacks)" % tick.stacks_consumed
	else:
		detail += " (%d stacks depleted; not Consume)" % tick.stacks_consumed
	return "[%.1fs] DOT       Poison ticks for %.1f%s%s -- %s" % [tick.time_ms / 1000.0, tick.damage, absorb_note, detail, stacks_note]
