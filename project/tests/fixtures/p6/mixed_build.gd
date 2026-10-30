extends RefCounted
## T10 exact mixed fixture, explicitly injected; never packaged content.
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")
const Contracts = preload("res://scripts/systems/p6_thief_contracts.gd")
const REVISION := "p6.test.mixed.1"
const ROTATION := ["skill.dance_of_death", "skill.quick_cut", "skill.quick_cut", "skill.parry_strike", "skill.leaping_plunge", "skill.rending_thrust", "skill.steal", "skill.mug"]
const RANKS := {"talent.bladedancer.wet_stone": 4, "talent.bladedancer.rending_slash": 1,
	"talent.bladedancer.fancy_footwork": 5, "talent.bladedancer.opportunity": 3,
	"talent.bladedancer.cloak_and_dagger": 2, "talent.keen_eye": 5}

static func modifier(id: String, value: float) -> StatModifier:
	var m := StatModifier.new()
	m.stat_id = id
	m.value = value
	return m

static func registry() -> BuildContentRegistry:
	var registry_value: BuildContentRegistry = Core.registry()
	registry_value.revision = REVISION
	registry_value.compatible = [registry_value.revision]
	var blade: SubclassTree = registry_value.trees["tree.bladedancer"]
	var opportunity := Talent.new()
	opportunity.id = "talent.bladedancer.opportunity"
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
	thief.display_name = "Thief (mixed fixture)"
	thief.ranked_content_ready = true
	thief.innate_modifiers = [modifier(StatCatalog.INCREASED_GOLD, 0.1)]
	thief.primary_point_modifiers = [modifier(StatCatalog.INCREASED_GOLD, 0.02)]
	var keen := Talent.new()
	keen.id = "talent.keen_eye"
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
	registry_value.trees[thief.id] = thief
	registry_value.classes["class.rogue"].trees.append(thief)
	for talent in [opportunity, cloak, keen]:
		registry_value.talents[talent.id] = talent
	return registry_value

static func build(registry_value: BuildContentRegistry, reversed_roles: bool = false, zero_secondary: bool = false) -> RankedBuild:
	var model := RankedBuild.new()
	var blade: SubclassTree = registry_value.trees["tree.bladedancer"]
	var thief: SubclassTree = registry_value.trees["tree.thief"]
	if not model.configure(thief if reversed_roles else blade, blade if reversed_roles else thief, 20):
		return null
	for id in RANKS:
		if zero_secondary and id == "talent.keen_eye":
			continue
		for i in RANKS[id]:
			if not model.buy(id):
				return null
	return model

static func payload(reversed_roles: bool = false, zero_secondary: bool = false) -> Dictionary:
	var ranks := RANKS.duplicate()
	if zero_secondary:
		ranks.erase("talent.keen_eye")
	var rotation := ROTATION.duplicate()
	if zero_secondary:
		rotation.erase("skill.steal")
		rotation.erase("skill.mug")
	return {"build_schema_version": 1, "content_revision": REVISION, "allocation_mode": "ranked",
		"class_id": "class.rogue", "primary_tree_id": "tree.thief" if reversed_roles else "tree.bladedancer",
		"secondary_tree_id": "tree.bladedancer" if reversed_roles else "tree.thief",
		"earned_talent_points": 20, "talent_ranks": ranks, "rotation_skill_ids": rotation}
