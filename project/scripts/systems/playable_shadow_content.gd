extends RefCounted
## P6M5-D011. Approved explicit resources; drafts are never executed.
const TALENT_PATHS := [
	"res://data/p6/shadow/coated_weapons.tres",
	"res://data/p6/shadow/blind_spot.tres",
	"res://data/p6/shadow/snake_oil.tres",
	"res://data/p6/shadow/deception.tres",
	"res://data/p6/shadow/death_from_the_shadows.tres",
	"res://data/p6/shadow/death_touch.tres",
	"res://data/p6/shadow/death_pact.tres",
	"res://data/p6/shadow/shadow_mastery.tres",
	"res://data/p6/shadow/dusk_strike.tres",
	"res://data/p6/shadow/death_blade.tres",
	"res://data/p6/shadow/umbral_presence.tres",
]

static func skill(kind: String) -> Skill:
	if kind in ["touch_of_darkness", "beguiling_presence"]:
		return preload("res://scripts/systems/p6_status_skill_contracts.gd").skill(kind)
	if kind == "beguiling_strike":
		return preload("res://data/skills/beguiling_strike.tres").duplicate(true)
	if kind == "death_strike":
		var value: Skill = preload("res://data/skills/death_strike.tres").duplicate(true)
		for effect in value.effects:
			if effect is StackScalingPhysicalDamageEffect:
				effect.damage_per_stack = CombatResolver.DEATH_STRIKE_DAMAGE_PER_POISON_STACK
		return value
	if kind == "distilled_corruption":
		var value := Skill.new()
		value.id = "skill.distilled_corruption"
		value.display_name = "Distilled Corruption"
		value.category = Skill.Category.ATTACK
		value.base_execution_ms = 1500
		value.min_execution_ms = 650
		value.effects.append(PhysicalDamageEffect.new())
		var consume := preload("res://scripts/resources/consume_status_effect.gd").new()
		consume.amount = 5
		consume.poison_per_consumed = 1
		value.effects.append(consume)
		return value
	return null

static func extend_registry(registry: BuildContentRegistry) -> void:
	var tree := SubclassTree.new()
	tree.id = "tree.shadow"
	tree.display_name = "Shadow"
	tree.icon = preload("res://assets/subclass_icons/rogue/shadow.png")
	tree.ranked_content_ready = true
	var mod = preload("res://scripts/systems/playable_mixed_content.gd")
	tree.innate_modifiers = [mod.modifier(StatCatalog.CRIT_APPLIES_ELEMENT, 0.2)]
	tree.primary_point_modifiers = [mod.modifier(StatCatalog.CRIT_APPLIES_ELEMENT, 0.02)]
	for path in TALENT_PATHS:
		var talent := load(path).duplicate(true) as Talent
		tree.talents.append(talent)
		registry.talents[talent.id] = talent
	for spec in [[1,"beguiling_strike"],[3,"death_strike"],[6,"distilled_corruption"],[9,"touch_of_darkness"],[12,"beguiling_presence"]]:
		var unlock := TreeSkillUnlock.new()
		unlock.required_points = spec[0]
		unlock.skill = skill(spec[1])
		tree.automatic_unlocks.append(unlock)
	registry.trees[tree.id] = tree
	registry.classes["class.rogue"].trees.append(tree)
