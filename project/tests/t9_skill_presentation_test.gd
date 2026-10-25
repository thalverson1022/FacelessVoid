extends SceneTree
## T9 presentation-only checks using authored resources and real Practice state.
const Hover = preload("res://scripts/ui/skill_hover_formatter.gd")
const Formatter = preload("res://scripts/ui/skill_tooltip_formatter.gd")
const Category = preload("res://scripts/ui/skill_category_preview_style.gd")
const SelfBuffs = preload("res://scripts/systems/combat_self_buffs.gd")
const TalentBuffs = preload("res://scripts/systems/combat_talent_buffs.gd")
var checks := 0
var failures: Array[String] = []
var skills: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		printerr("FAILED: ", message)

func context() -> TrainingRoomState:
	var state := TrainingRoomState.new()
	state.selected_class = load("res://data/classes/rogue.tres")
	return state

func gear(name: String) -> GearItem:
	return load("res://data/gear/%s.tres" % name)

func text(id: String, state: TrainingRoomState) -> String:
	return Hover.plain_text(Hover.model(skills[id], state))

func collect_skills() -> void:
	var registry := BuildContentRegistry.test_mode()
	for character in registry.classes.values():
		for skill in character.base_skills: skills[skill.id] = skill
	for tree in registry.trees.values():
		for talent in tree.talents:
			for skill in talent.unlocked_skills: skills[skill.id] = skill
		for unlock in tree.automatic_unlocks:
			if unlock.skill != null: skills[unlock.skill.id] = unlock.skill
	skills["skill.exsanguinate"] = load("res://data/skills/exsanguinate.tres")

func normal_contracts() -> void:
	var state := context()
	check(Hover.model(skills["skill.virulent_poison"], state).effect == "Next 5 ticks of Poison deal 2x damage", "Normal Virulent retains accepted M7 text")
	check(Hover.model(skills["skill.touch_of_darkness"], state).effect == "Consume all stacks of Poison. Each stack consumed grants x10% Attack Speed and +2 Base Physical Damage", "Normal Touch retains M7 text")
	check(Hover.model(skills["skill.beguiling_presence"], state).effect == "Consume all stacks of Decay. Each stack consumed grants +1 Base Elemental Damage", "Normal Beguiling retains M7 minimal omission")
	check(not text("skill.killers_mark", state).contains("Decay"), "Normal Death Strike has no Umbral bonus")
	check(Formatter.conditions_for(skills["skill.beguiling_presence"], state).contains("caps at 100%"), "Normal effective crit still capped")
	var forced: Skill = load("res://data/skills/poison_strike_legendary.tres")
	check(Hover.model(forced, state).effect == "On hit: trigger 1 Poison tick.", "Flags off forced tick stays one tick")
	check(Formatter.conditions_for(forced, state).contains("one fueled Poison tick"), "Flags off detailed forced tick unchanged")
	var legacy: Skill = load("res://data/skills/poison_strike.tres")
	check(Formatter.effect_summary(legacy, state).contains("+1 poison stack"), "Legacy ordinary Poison Strike still applies Poison")
	check(Hover.model(skills["skill.touch_of_darkness"], state).duration == "Duration: 12s", "Normal Touch duration")
	check(Hover.model(skills["skill.master_of_poisons"], state).duration == "Duration: 5s", "Normal Master duration")
	check(Hover.model(skills["skill.blinding_powder"], state).duration == "Duration: 3s", "Normal Potency duration")
	check(Hover.model(skills["skill.exsanguinate"], state).effect.contains("%d health" % (2*state.current_player_stats().shred_value)), "Exsanguinate works without Nightkiss flag too")

func legendary_skills() -> void:
	var state := context()
	state.equipped_weapon = gear("nightkiss_kitana")
	var exsanguinate: Skill = state.unlocked_skills().filter(func(s): return s.id == "skill.exsanguinate")[0]
	var data := Hover.model(exsanguinate, state)
	var coefficient := 2 * state.current_player_stats().shred_value
	check(data.category == "Debuff" and data.damage == "", "Exsanguinate remains health-removing Debuff")
	check(data.cooldown == "Cooldown: 8s" and data.duration == "Duration: Instant", "Exsanguinate timing rows")
	check(data.effect.contains("Remove %d health per stack" % coefficient), "Exsanguinate uses resolved Shred Value including Nightkiss")
	check(data.effect.contains("Retriggers repeat the same health removal"), "Exsanguinate captured repeats described")
	check(Formatter.unlock_source(exsanguinate, state) == "Gear: Nightkiss Kitana", "Nightkiss named as gear-only source")
	var detail := Formatter.conditions_for(exsanguinate, state)
	for expected in ["all actual Shred once", "2 x resolved Shred Value", "Bypasses mitigation", "cannot crit or gain damage bonuses", "without consuming more Shred", "does not grant Death Pact"]:
		check(detail.contains(expected), "Exsanguinate detail: " + expected)
	state.equipped_weapon = gear("decrepit_blade")
	var poison_strike: Skill = state.unlocked_skills().filter(func(s): return s.id == "skill.poison_strike")[0]
	data = Hover.model(poison_strike, state)
	check(data.damage != "" and data.category == "Attack", "Decrepit retains normal direct hit row")
	check(data.effect.contains("Consume all Poison stacks") and not data.effect.contains("1 Poison tick"), "Decrepit replaces single tick description")
	check(Formatter.unlock_source(poison_strike, state) == "Gear: Decrepit Blade", "Decrepit named as gear-only source")
	detail = Formatter.conditions_for(poison_strike, state)
	for expected in ["normal direct hit", "all actual Poison once", "normal Poison damage modifiers and Consume hooks", "No Poison grants no burst"]:
		check(detail.contains(expected), "Decrepit detail: " + expected)
	check(not detail.contains("Coil retriggers"), "No unsolicited Coil behavior while unequipped")
	state.equipped_trinket = gear("serpents_coil")
	detail = Formatter.conditions_for(poison_strike, state)
	for expected in ["free Poison activations", "no extra Poison is required or consumed", "recalculates with live buffs", "captured stack count"]:
		check(detail.contains(expected), "Coil detail: " + expected)
	state.equipped_weapon = gear("umbral_stiletto")
	var death_strike: Skill = state.unlocked_skills().filter(func(s): return s.id == "skill.killers_mark")[0]
	check(Hover.model(death_strike, state).effect.contains("+1 Base Physical Damage per Decay stack"), "Umbral minimal Death Strike shows Decay bonus")
	check(Hover.model(death_strike, state).effect.contains("+2 Base Physical Damage per Poison stack"), "Umbral keeps Poison scaling")
	detail = Formatter.conditions_for(death_strike, state)
	check(detail.contains("+ current Decay count") and detail.contains("Does not consume Poison or Decay"), "Umbral adds current Decay and leaves both statuses")
	check(Formatter.effect_summary(death_strike, state).contains("current Decay count"), "Umbral effect summary includes Decay")
	check(Formatter.unlock_source(death_strike, state) == "Gear: Umbral Stiletto", "Umbral named as gear-only source")
	# A selected but uninvested tree must not mask its equipped-only unlock.
	var registry := BuildContentRegistry.test_mode()
	state.configure_ranked_build(registry.trees["tree.assassin"], registry.trees["tree.shadow"])
	check(Formatter.unlock_source(death_strike, state) == "Gear: Umbral Stiletto", "Uninvested tree does not mask Umbral source")
	state.equipped_weapon = gear("decrepit_blade")
	check(Formatter.unlock_source(poison_strike, state) == "Gear: Decrepit Blade", "Uninvested Assassin does not mask Decrepit source")

func crown_and_timers() -> void:
	var state := context()
	state.equipped_helm = gear("crown_of_concertation")
	var stats := state.current_player_stats()
	check(stats.legendary_crown and is_equal_approx(stats.increased_buff_duration, 0.2), "Actual Crown resolves strength flag and duration affix")
	check(Hover.model(skills["skill.virulent_poison"], state).effect == "Next 5 ticks of Poison deal 3x damage", "Crown doubles bonus above baseline, not multiplier")
	check(Hover.model(skills["skill.touch_of_darkness"], state).effect.contains("x20% Attack Speed and +4 Base Physical Damage"), "Crown doubles Touch bonuses only")
	check(Hover.model(skills["skill.beguiling_presence"], state).effect.contains("+2 Base Elemental Damage"), "Crown doubles Beguiling strength")
	check(Hover.model(skills["skill.touch_of_darkness"], state).duration == "Duration: 14.4s", "Actual Crown Touch duration")
	check(Hover.model(skills["skill.beguiling_presence"], state).duration == "Duration: 12s", "Actual Crown Beguiling duration")
	check(Hover.model(skills["skill.master_of_poisons"], state).duration == "Duration: 6s", "Actual Crown Master duration")
	check(Hover.model(skills["skill.dance_of_death"], state).duration == "Duration: 6s", "Actual Crown Dance duration")
	check(Hover.model(skills["skill.blinding_powder"], state).duration == "Duration: 3.6s", "Actual Crown Potency duration")
	check(Hover.model(skills["skill.touch_of_darkness"], state).cooldown == "Cooldown: 25.5s", "Actual Crown cooldown reduction")
	check(Hover.model(skills["skill.virulent_poison"], state).duration == "", "Crown preserves untimed Virulent omission")
	check(Category.tooltip(skills["skill.virulent_poison"], state).contains("3x damage"), "Category preview cannot bypass resolved Crown strength")
	state.equipped_charm = gear("signet_of_the_old_kings")
	check(Hover.model(skills["skill.beguiling_presence"], state).effect.contains("+2 Base Elemental Damage and +8% Attack Speed"), "Crown and Signet show actual converted per-stack bonuses")
	var detail := Formatter.conditions_for(skills["skill.beguiling_presence"], state)
	check(detail.contains("uncapped critical chance") and detail.contains("cannot crit") and not detail.contains("caps at 100%"), "Signet details preserve uncapped conversion input")
	state.equipped_helm = null
	check(Hover.model(skills["skill.beguiling_presence"], state).effect.contains("+1 Base Elemental Damage and +4% Attack Speed"), "Signet alone conversion")
	state.equipped_charm = null
	check(not Hover.model(skills["skill.beguiling_presence"], state).effect.contains("Attack Speed"), "Unequip refresh removes conversion wording")
	# Fractional authored affix tests the ceiling to milliseconds used by combat.
	var duration_gear := GearItem.new()
	duration_gear.slot = GearItem.SlotType.CHARM
	var modifier := StatModifier.new()
	modifier.stat_id = "increased_buff_duration"
	modifier.value = 0.3334
	duration_gear.affixes = [modifier]
	state.equipped_charm = duration_gear
	stats = state.current_player_stats()
	var self_buffs := SelfBuffs.new(null, stats.increased_buff_duration)
	self_buffs.grant("master_of_poisons", 0, {})
	check(self_buffs.instances[0].expires_at_ms == 6667, "Combat witness: fractional Master timer")
	check(Hover.model(skills["skill.master_of_poisons"], state).duration == "Duration: 6.667s", "Hover matches actual fractional combat timer")
	var talent_buffs := TalentBuffs.new(stats)
	check(talent_buffs.grant_touch(1, 0, {}) == "", "Combat witness: Touch grant accepted")
	check(talent_buffs.state.snapshot("touch.1").expires_at_ms == 16001, "Combat witness: fractional Touch timer")
	check(Hover.model(skills["skill.touch_of_darkness"], state).duration == "Duration: 16.001s", "Touch displays millisecond ceiling")
	check(Formatter.conditions_for(skills["skill.touch_of_darkness"], state).contains("16.001 seconds"), "Detailed Touch agrees with hover duration")
	for id in ["skill.touch_of_darkness", "skill.beguiling_presence", "skill.virulent_poison", "skill.master_of_poisons", "skill.exsanguinate"]:
		var data := Hover.model(skills[id], state)
		var simple := Hover.plain_text(data)
		for clutter in ["resolved", "modifier", "mitigation", "skill.", "Build unlock", "shared cooldown", "captured", "%d", "%s"]:
			check(not simple.contains(clutter), id + " keeps M7 minimal: " + clutter)

func run() -> void:
	collect_skills()
	normal_contracts()
	legendary_skills()
	crown_and_timers()
	print("PASS T9 skill presentation: " if failures.is_empty() else "FAIL T9 skill presentation: ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
