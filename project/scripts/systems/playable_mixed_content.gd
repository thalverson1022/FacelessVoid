extends RefCounted
## M4-T9 production extension: only the reviewed 15/5 integration slice.
const Contracts = preload("res://scripts/systems/p6_thief_contracts.gd")

static func modifier(id: String, value: float) -> StatModifier:
	var result := StatModifier.new()
	result.stat_id = id
	result.value = value
	return result

static func extend_registry(registry: BuildContentRegistry) -> void:
	var blade: SubclassTree = registry.trees["tree.bladedancer"]
	var opportunity := Talent.new()
	opportunity.id = "talent.bladedancer.opportunity"
	opportunity.display_name = "Opportunity"
	opportunity.max_ranks = 3
	opportunity.required_tree_points = 10
	opportunity.prerequisite_ids = ["talent.bladedancer.rending_slash"]
	for i in range(1, 4):
		var rank := TalentRank.new()
		var trigger := TriggeredSkillEffect.new()
		trigger.skill = load("res://data/skills/rending_slash.tres")
		trigger.chance = 0.1 * i
		trigger.source_skill_ids = PackedStringArray(["skill.quick_cut"])
		rank.triggered_skill_effects = [trigger]
		opportunity.ranks.append(rank)
	var cloak := Talent.new()
	cloak.id = "talent.bladedancer.cloak_and_dagger"
	cloak.display_name = "Cloak & Dagger"
	cloak.max_ranks = 2
	cloak.required_tree_points = 10
	for i in range(1, 3):
		var rank := TalentRank.new()
		rank.stat_modifiers = [modifier(StatCatalog.CRIT_DAMAGE, 0.5 * i)]
		cloak.ranks.append(rank)
	blade.talents.append_array([opportunity, cloak])
	var dance := TreeSkillUnlock.new()
	dance.required_points = 12
	dance.skill = Contracts.skill("dance_of_death")
	blade.automatic_unlocks.append(dance)
	var thief := SubclassTree.new()
	thief.id = "tree.thief"
	thief.display_name = "Thief"
	thief.ranked_content_ready = true
	thief.innate_modifiers = [modifier(StatCatalog.INCREASED_GOLD, 0.1)]
	thief.primary_point_modifiers = [modifier(StatCatalog.INCREASED_GOLD, 0.02)]
	var keen := Talent.new()
	keen.id = "talent.keen_eye"
	keen.display_name = "Keen Eye"
	keen.max_ranks = 5
	for i in range(1, 6):
		var rank := TalentRank.new()
		rank.stat_modifiers = [modifier(StatCatalog.PERCENT_PHYSICAL_DAMAGE, 0.02 * i), modifier(StatCatalog.PERCENT_ELEMENTAL_DAMAGE, 0.02 * i)]
		keen.ranks.append(rank)
	thief.talents = [keen]
	for spec in [[1, "steal"], [3, "mug"]]:
		var unlock := TreeSkillUnlock.new()
		unlock.required_points = spec[0]
		unlock.skill = Contracts.skill(spec[1])
		thief.automatic_unlocks.append(unlock)
	registry.trees[thief.id] = thief
	registry.classes["class.rogue"].trees.append(thief)
	for talent in [opportunity, cloak, keen]:
		registry.talents[talent.id] = talent
