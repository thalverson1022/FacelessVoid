extends RefCounted
## Category popup feedback for every Debuff and Self Buff skill.
const IDS := ["skill.stab", "skill.venom_jab", "skill.poison_vile", "skill.virulent_poison", "skill.blinding_powder"]
const COLORS := [Color("EE8880"), Color("D2B3EE"), Color("9ED5EF")]
const NAMES := ["Attack", "Debuff", "Self Buff"]
const SYMBOLS := ["/", "v", "+"]
static func selected(skill: Skill) -> bool:
	return skill != null and skill.id in IDS
static func popup_selected(skill: Skill) -> bool:
	return skill != null and (skill.category in [Skill.Category.DEBUFF, Skill.Category.SELF_BUFF] or selected(skill))
# Icon accents cover every skill category in all modes.
static func icon_selected(skill: Skill) -> bool:
	return skill != null
static func enabled(state) -> bool:
	return state != null and (state.get("is_test_mode") != true or bool(state.get_meta("category_preview", true)))
static func badge(skill: Skill) -> String:
	return "%s %s" % [SYMBOLS[skill.category], NAMES[skill.category]]
static func outcome(cast: CombatResolver.CastEvent) -> String:
	if cast.cooldown_blocked: return "On cooldown - no effect"
	if cast.resource_unavailable: return "Missing resource - no effect"
	if cast.was_interrupted: return "Interrupted - no effect"
	if cast.was_dodged: return "Dodged - no effect"
	if cast.skill.id == "skill.blinding_powder": return "+%d Potency Stacks" % cast.potency_stacks_applied
	if cast.skill.id == "skill.virulent_poison": return "+5 stacks (one per fueled Poison tick)"
	if cast.skill.id == "skill.poison_vile": return "+%d Poison stacks" % cast.poison_stacks_applied if cast.poison_stacks_applied > 0 else "No Poison added"
	if cast.skill.id == "skill.pick_pocket": return "+%d Gold Stolen" % cast.gold_stolen
	if cast.skill.id == "skill.exsanguinate": return "Removes %.0f Health" % cast.health_removed
	if cast.skill.category == Skill.Category.SELF_BUFF:
		match cast.skill.id:
			"skill.dance_of_death": return "Guaranteed Retriggers"
			"skill.master_of_poisons": return "Ignore Elemental Resistance"
			"skill.beguiling_presence": return "Elemental Damage Buff" if _consumed(cast, "decay") > 0 else "No Decay Consumed"
			"skill.touch_of_darkness": return "Attack Speed Buff" if _consumed(cast, "poison") > 0 else "No Poison Consumed"
		return "Buff Applied"
	if cast.skill.category == Skill.Category.DEBUFF:
		var effects: PackedStringArray = []
		if cast.poison_stacks_applied > 0: effects.append("+%d Poison stacks" % cast.poison_stacks_applied)
		if cast.potency_stacks_applied > 0: effects.append("+%d Potency Stacks" % cast.potency_stacks_applied)
		if cast.shred_stacks_applied > 0: effects.append("+%d Shred stacks" % cast.shred_stacks_applied)
		if cast.decay_stacks_applied > 0: effects.append("+%d Decay stacks" % cast.decay_stacks_applied)
		if cast.gold_stolen > 0: effects.append("+%d Gold Stolen" % cast.gold_stolen)
		if cast.health_removed > 0: effects.append("Removes %.0f Health" % cast.health_removed)
		return " | ".join(effects) if not effects.is_empty() else "Debuff Applied"
	return "%.1f damage%s%s" % [cast.physical_damage, " CRIT" if cast.is_crit else "", " | +%d Poison" % cast.poison_stacks_applied if cast.poison_stacks_applied > 0 else ""]
static func _consumed(cast: CombatResolver.CastEvent, status: String) -> int:
	var amount := 0
	for transaction in cast.status_transactions:
		if transaction.get("status", "") == status: amount += int(transaction.get("consumed", 0))
	return amount

static func tooltip(skill: Skill, state) -> String:
	var description := ""
	match skill.id:
		"skill.stab":
			description = SkillTooltipFormatter.effect_summary(skill, state)
			if SkillTooltipFormatter.conditions_for(skill, state) != "": description += "\n" + SkillTooltipFormatter.conditions_for(skill, state)
		"skill.venom_jab": description = SkillTooltipFormatter.effect_summary(skill, state) + "\nPoison applies on a connected hit."
		"skill.poison_vile": description = SkillTooltipFormatter.effect_summary(skill, state) + "\nNo direct damage. Added Poison deals damage on fueled ticks; stack cap applies."
		"skill.blinding_powder": description = SkillTooltipFormatter.effect_summary(skill, state)
		"skill.virulent_poison": description = SkillTooltipFormatter.conditions_for(skill, state) + "\nNo direct damage."
	var stats := SkillTooltipFormatter.resolved_stats(state)
	return "%s\n[%s]\n%s\nCast: %.2fs%s\nCooldown: %s" % [skill.display_name, badge(skill), description, CombatTiming.execution_time_ms(skill, stats.attack_speed) / 1000.0, " (ignores attack speed)" if skill.category == Skill.Category.SELF_BUFF else "", "%.1fs; unavailable casts have no effect" % (SkillTooltipFormatter.cooldown_ms(skill, stats) / 1000.0) if skill.cooldown_ms > 0 else "None"]
static func log_text(result: CombatResolver.CombatResult) -> String:
	var lines: PackedStringArray = ["CATEGORY PREVIEW - combat timeline", "[/ Attack]  [v Debuff]  [+ Self Buff]", ""]
	var casts := CombatResultFormatter._cast_index(result)
	var observations := {}
	for record in result.trace.presentation_records:
		observations[int(record.get("sequence", 0))] = record
	for entry in CombatPlayback._merge_events(result):
		if entry.is_tick:
			if entry.tick.had_active_stack:
				var record: Dictionary = observations.get(entry.sequence, {})
				lines.append(CombatResultFormatter._tick_hierarchy_line(CombatResultFormatter._tick_line(entry.tick, record.get("payload", {})), entry.tick, record, casts))
		else:
			var cast: CombatResolver.CastEvent = entry.cast
			var text := CombatResultFormatter._cast_line(cast)
			if selected(cast.skill):
				text = "[%.1fs] %s [%s] %s - %s" % [cast.time_ms / 1000.0, CombatResultFormatter._event_type_label(cast), badge(cast.skill), cast.skill.display_name, outcome(cast)]
			var colored_name := "[color=#%s]%s[/color]" % [COLORS[cast.skill.category].to_html(false), cast.skill.display_name]
			text = text.replace(cast.skill.display_name, colored_name)
			lines.append(CombatResultFormatter._hierarchy_line(text, cast, casts))
	return "\n".join(lines)
