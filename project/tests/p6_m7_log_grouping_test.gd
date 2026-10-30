extends SceneTree
func _initialize() -> void:
	var result := CombatResolver.CombatResult.new()
	var skill: Skill = load("res://data/skills/stab.tres")
	for time in [1000,1000,1001]:
		var cast := CombatResolver.CastEvent.new()
		cast.skill = skill
		cast.time_ms = time
		cast.physical_damage = 3
		result.cast_events.append(cast)
	var tick := CombatResolver.TickEvent.new()
	tick.time_ms = 1000
	tick.damage = 2
	tick.had_active_stack = true
	result.tick_events.append(tick)
	var log := "\n".join(CombatResultFormatter._timeline(result))
	assert(log.count("[1.0s]") == 4)
	assert(log.find("DOT") < log.find("CAST"))
	assert(log.count("Stab") == 3 and log.count("Poison ticks") == 1)
	var category: String = preload("res://scripts/ui/skill_category_preview_style.gd").log_text(result)
	assert(category.count("[1.0s]") == 4)
	assert(category.count("Stab[/color] - 3.0 damage") == 3)
	assert(not category.contains("\n        3.0 damage"))
	# Skills outside the original four-skill prototype must remain visible.
	var strike := CombatResolver.CastEvent.new()
	strike.skill = preload("res://scripts/systems/p6_poison_contracts.gd").poison_strike()
	strike.time_ms = 2000
	strike.physical_damage = 7
	result.cast_events.append(strike)
	var forced := CombatResolver.TickEvent.new()
	forced.time_ms = 2000
	forced.origin_kind = "forced_tick"
	forced.had_active_stack = true
	forced.damage = 4
	result.tick_events.append(forced)
	category = preload("res://scripts/ui/skill_category_preview_style.gd").log_text(result)
	assert(category.contains("Poison Strike[/color] hits for 7.0"))
	assert(category.contains("Poison ticks for 4.0 (forced)"))
	assert(category.count("[2.0s]") == 2)
	assert(category.count("Poison ticks") == 2)
	var monster := Monster.new()
	assert(CombatResultFormatter.format(result,monster).contains("  [1.0s] DOT"))
	assert(CombatResultFormatter.format_practice(result,monster).contains("  [1.0s] DOT"))
	print("Combat log grouping: PASS")
	quit()
