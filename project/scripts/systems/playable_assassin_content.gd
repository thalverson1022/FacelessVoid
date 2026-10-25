extends RefCounted
const PRIMARY_ELEMENTAL_PER_POINT := 0.5
## P6M5-D009. Explicit release resources, never executable draft data.
const TALENT_PATHS := [
	"res://data/p6/assassin/quick_hands.tres",
	"res://data/p6/assassin/precision.tres",
	"res://data/p6/assassin/hastened_poison.tres",
	"res://data/p6/assassin/echoing_toxin.tres",
	"res://data/p6/assassin/poison_strike.tres",
	"res://data/p6/assassin/bypass.tres",
	"res://data/p6/assassin/toxic_tradeoff.tres",
	"res://data/p6/assassin/accelerant.tres",
	"res://data/p6/assassin/resonance.tres",
	"res://data/p6/assassin/critical_poison.tres",
]

static func skill(kind: String) -> Skill:
	if kind == "poison_strike":
		return preload("res://scripts/systems/p6_poison_contracts.gd").poison_strike()
	if kind in ["virulent_poison", "master_of_poisons", "poison_vile"]:
		return preload("res://scripts/systems/p6_status_skill_contracts.gd").skill(kind)
	if kind == "venom_jab":
		var value: Skill = preload("res://data/skills/venom_jab.tres").duplicate(true)
		for effect in value.effects:
			if effect is PoisonDamageEffect:
				effect.stacks_applied = 5
		return value
	if kind == "blinding_powder":
		var value := Skill.new()
		value.id = "skill.blinding_powder"
		value.display_name = "Blinding Powder"
		value.category = Skill.Category.DEBUFF
		value.base_execution_ms = 1200
		value.min_execution_ms = 500
		var effect := preload("res://scripts/resources/apply_defense_debuff_effect.gd").new()
		effect.use_assassin_points = true
		value.effects.append(effect)
		return value
	return null

static func extend_registry(registry: BuildContentRegistry) -> void:
	var tree := SubclassTree.new()
	tree.id = "tree.assassin"
	tree.display_name = "Assassin"
	tree.icon = preload("res://assets/subclass_icons/rogue/assassin.png")
	tree.ranked_content_ready = true
	var mod = preload("res://scripts/systems/playable_mixed_content.gd")
	tree.innate_modifiers = [mod.modifier(StatCatalog.BASE_ELEMENTAL_DAMAGE, 5.0)]
	tree.primary_point_modifiers = [mod.modifier(StatCatalog.BASE_ELEMENTAL_DAMAGE, PRIMARY_ELEMENTAL_PER_POINT)]
	for path in TALENT_PATHS:
		var talent := load(path).duplicate(true) as Talent
		if talent.id == "talent.assassin.poison_strike":
			talent.unlocked_skills = [skill("poison_strike")]
		tree.talents.append(talent)
		registry.talents[talent.id] = talent
	for spec in [[1, "venom_jab"], [3, "blinding_powder"], [6, "virulent_poison"], [9, "master_of_poisons"], [12, "poison_vile"]]:
		var unlock := TreeSkillUnlock.new()
		unlock.required_points = spec[0]
		unlock.skill = skill(spec[1])
		tree.automatic_unlocks.append(unlock)
	registry.trees[tree.id] = tree
	registry.classes["class.rogue"].trees.append(tree)
