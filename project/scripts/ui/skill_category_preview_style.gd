extends RefCounted
## Deliberately limited to four representative skills during T3 review.
const IDS := ["skill.stab", "skill.venom_jab", "skill.poison_vile", "skill.virulent_poison"]
const COLORS := [Color("EE8880"), Color("D2B3EE"), Color("9ED5EF")]
const NAMES := ["Attack", "Debuff", "Self Buff"]
const SYMBOLS := ["/", "v", "+"]
static func selected(skill: Skill) -> bool:
	return skill != null and skill.id in IDS
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
	if cast.skill.id == "skill.virulent_poison": return "+5 stacks (one per fueled Poison tick)"
	if cast.skill.id == "skill.poison_vile": return "+%d Poison stacks" % cast.poison_stacks_applied if cast.poison_stacks_applied > 0 else "No Poison added"
	return "%.1f damage%s%s" % [cast.physical_damage, " CRIT" if cast.is_crit else "", " | +%d Poison" % cast.poison_stacks_applied if cast.poison_stacks_applied > 0 else ""]
static func tooltip(skill: Skill, state) -> String:
	var description := ""
	match skill.id:
		"skill.stab":
			description = SkillTooltipFormatter.effect_summary(skill, state)
			if SkillTooltipFormatter.conditions_for(skill, state) != "": description += "\n" + SkillTooltipFormatter.conditions_for(skill, state)
		"skill.venom_jab": description = SkillTooltipFormatter.effect_summary(skill, state) + "\nPoison applies on a connected hit."
		"skill.poison_vile": description = SkillTooltipFormatter.effect_summary(skill, state) + "\nNo direct damage. Added Poison deals damage on fueled ticks; stack cap applies."
		"skill.virulent_poison": description = SkillTooltipFormatter.conditions_for(skill, state) + "\nNo direct damage."
	var stats := SkillTooltipFormatter.resolved_stats(state)
	return "%s\n[%s]\n%s\nCast: %.2fs%s\nCooldown: %s" % [skill.display_name, badge(skill), description, CombatTiming.execution_time_ms(skill, stats.attack_speed) / 1000.0, " (ignores attack speed)" if skill.category == Skill.Category.SELF_BUFF else "", "%.1fs; unavailable casts have no effect" % (SkillTooltipFormatter.cooldown_ms(skill, stats) / 1000.0) if skill.cooldown_ms > 0 else "None"]
static func log_text(result: CombatResolver.CombatResult) -> String:
	var lines: PackedStringArray = ["CATEGORY PREVIEW - combat timeline", "[/ Attack]  [v Debuff]  [+ Self Buff]", ""]
	var previous_time := -1
	var cast_index := 0
	var tick_index := 0
	while cast_index < result.cast_events.size() or tick_index < result.tick_events.size():
		var cast_time := result.cast_events[cast_index].time_ms if cast_index < result.cast_events.size() else -1
		var tick_time := result.tick_events[tick_index].time_ms if tick_index < result.tick_events.size() else -1
		if cast_time >= 0 and (tick_time < 0 or cast_time < tick_time):
			var cast := result.cast_events[cast_index]
			cast_index += 1
			var text := CombatResultFormatter._cast_line(cast)
			if selected(cast.skill):
				text = "[%.3fs] [%s] %s - %s" % [cast_time / 1000.0, badge(cast.skill), cast.skill.display_name, outcome(cast)]
			var colored_name := "[color=#%s]%s[/color]" % [COLORS[cast.skill.category].to_html(false), cast.skill.display_name]
			text = text.replace(cast.skill.display_name, colored_name)
			previous_time = CombatResultFormatter._append_timeline_entry(lines, cast_time, previous_time, text)
		else:
			var tick := result.tick_events[tick_index]
			tick_index += 1
			if tick.had_active_stack:
				previous_time = CombatResultFormatter._append_timeline_entry(lines, tick_time, previous_time, CombatResultFormatter._tick_line(tick))
	return "\n".join(lines)
