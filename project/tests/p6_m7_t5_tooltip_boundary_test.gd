extends SceneTree
const View = preload("res://scripts/ui/ranked_talent_view.gd")
const EffectText = preload("res://scripts/ui/combat_effect_text.gd")
class TooltipContext extends RefCounted:
	var is_test_mode := true
	var selected_class: ClassDef
	var selected_trees: Array[SubclassTree] = []
	var source
	func current_player_stats() -> PlayerStats: return source.current_player_stats()
var failed := false
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAILED: " + message)
func run() -> void:
	var registry := BuildContentRegistry.test_mode()
	var state := TrainingRoomState.new()
	state.selected_class = registry.classes["class.rogue"]
	var skills := {}
	for skill in state.selected_class.base_skills: skills[skill.id] = skill
	var context := TooltipContext.new()
	context.selected_class = state.selected_class
	context.source = state
	var rank_count := 0
	for tree in registry.trees.values():
		for talent in tree.talents:
			for rank in range(1, talent.max_ranks + 1):
				var text := View.effects(talent, rank)
				check(text != "" and not text.contains("See skill effects"), talent.id + " rank " + str(rank))
				rank_count += 1
			for skill in talent.unlocked_skills: skills[skill.id] = skill
		for unlock in tree.automatic_unlocks:
			if unlock.skill != null: skills[unlock.skill.id] = unlock.skill
	check(rank_count == 140 and registry.talents.size() == 44 and skills.size() == 23, "Full live roster")
	for skill in skills.values():
		for preview in [false,true]:
			context.set_meta("category_preview", preview)
			for text in [SkillTooltipFormatter.tooltip_for(skill,context),SkillTooltipFormatter.compact_tooltip(skill,context),SkillTooltipFormatter.details_for(skill,context)]:
				check(not text.contains("No effect"), skill.id + " useful wording")
			check(SkillTooltipFormatter.details_for(skill,context).contains("Minimum:"),skill.id + " inspection timing")
	# Category comparison must actually switch the four-skill override.
	context.set_meta("category_preview", false)
	check(not SkillTooltipFormatter.compact_tooltip(skills["skill.virulent_poison"],context).contains("[+ Self Buff]"),"Original tooltip path")
	context.set_meta("category_preview", true)
	check(SkillTooltipFormatter.compact_tooltip(skills["skill.virulent_poison"],context).contains("[+ Self Buff]"),"Category tooltip path")
	var death: Skill = skills["skill.killers_mark"]
	for poison in [0,1,10]:
		var stats := PlayerStats.new()
		stats.weapon_damage_min = 100
		stats.weapon_damage_max = 100
		stats.bonus_physical_damage = 0
		var enemy := Monster.new()
		enemy.hp = 100000
		# Use the approved formula boundary; runtime implementation is separately covered by Shadow suites.
		check(is_equal_approx(CombatResolver.weapon_scaling_for_skill(death)*(100+CombatResolver.DEATH_STRIKE_DAMAGE_PER_POISON_STACK*poison),111+2.22*poison),"Death formula at " + str(poison))
		check(SkillTooltipFormatter.effect_summary(death,state).contains("2 x current Poison count") and SkillTooltipFormatter.conditions_for(death,state).contains("Does not consume"),"Death wording")
	var mug: Skill = skills["skill.mug"]
	for stolen in [0,1,49,50,51]:
		check(mug.stolen_gold_damage_bonus(stolen) == mini(stolen,50),"Mug cap at " + str(stolen))
	check(SkillTooltipFormatter.effect_summary(mug,state).contains("+1 base physical") and SkillTooltipFormatter.conditions_for(mug,state).contains("Starting stash"),"Mug wording")
	var pocket: Skill = skills["skill.pick_pocket"]
	check(SkillTooltipFormatter.effect_summary(pocket,state).contains("10 credited"),"Pick Pocket baseline")
	var gear := GearItem.new()
	gear.slot = GearItem.SlotType.CHARM
	var modifier := StatModifier.new()
	modifier.stat_id = "increased_gold"
	modifier.value = 0.55
	gear.affixes = [modifier]
	state.equipped_charm = gear
	check(SkillTooltipFormatter.effect_summary(pocket,state).contains("15 credited"),"Pick Pocket floored Increased Gold")
	check(SkillTooltipFormatter.compact_tooltip(pocket,state).contains("8.0s shared cooldown"),"Pick Pocket shared cooldown")
	check(SkillTooltipFormatter.effect_summary(skills["skill.big_score"],state).contains("6x your full crit"),"Big Score defining condition")
	var toxic: Talent = registry.talents["talent.assassin.toxic_tradeoff"]
	for rank in 5:
		var text := View.effects(toxic,rank+1)
		check(text.count("physical damage") == 1,"Toxic penalty once")
	var effects := ["footwork","readiness","precision","dance","bypass","virulent_poison","master_of_poisons","touch_of_darkness","beguiling_presence","greed"]
	for effect in effects:
		check(EffectText.rule_for("buff."+effect) != "",effect + " explanation")
	for id in ["skill.rending_thrust","skill.killers_mark","skill.toxic_flurry"]:
		check(not EffectText.name_for(id).contains(id.get_slice(".",1).capitalize()),"Current name " + id)
	check(EffectText.magnitude_for("buff.beguiling_presence",{"units":7,"magnitude":7.0,"crit_chance_bonus":0.14}).contains("Base elemental damage: +7.0"),"Beguiling elemental bonus")
	check(EffectText.magnitude_for("buff.touch_of_darkness",{"units":2}).contains("Base physical damage: +4"),"Touch actual consumed quantity")
	print("PASS T5 boundary checks: ",checks)
	quit(1 if failed else 0)
