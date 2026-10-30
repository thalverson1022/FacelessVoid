extends RefCounted
## Explicitly injected T8 slice. Never selected by the packaged registry or saves.
const REVISION := "p6.test.bladedancer_core.1"
const RANKS := {"talent.bladedancer.wet_stone": 4, "talent.bladedancer.rending_slash": 1, "talent.bladedancer.fancy_footwork": 5}
const ROTATION := ["skill.quick_cut", "skill.quick_cut", "skill.parry_strike", "skill.leaping_plunge", "skill.rending_thrust"]

static func registry() -> BuildContentRegistry:
	var value := BuildContentRegistry.new()
	value.mode = "ranked"
	value.revision = REVISION
	value.compatible = [REVISION]
	var rogue: ClassDef = load("res://data/classes/rogue.tres").duplicate(true)
	var tree: SubclassTree = load("res://tests/fixtures/p6/bladedancer_core/tree.tres").duplicate(true)
	# External rank resources inside typed arrays need explicit copies.
	var source_talents := tree.talents.duplicate()
	tree.talents = []
	for source in source_talents:
		var talent: Talent = source.duplicate(true)
		talent.ranks = []
		for rank in source.ranks:
			talent.ranks.append(rank.duplicate(true))
		tree.talents.append(talent)
	rogue.trees = [tree]
	value.classes[rogue.id] = rogue
	value.trees[tree.id] = tree
	for talent in tree.talents:
		value.talents[talent.id] = talent
	return value

static func build(registry_value: BuildContentRegistry) -> RankedBuild:
	var model := RankedBuild.new()
	if not model.configure(registry_value.trees["tree.bladedancer"], null, 10):
		return null
	# Preserve the exact reviewed purchase sequence, including gate entry.
	for id in RANKS:
		for rank in RANKS[id]:
			if not model.buy(id):
				return null
	return model

static func payload() -> Dictionary:
	return {"build_schema_version": 1, "content_revision": REVISION, "allocation_mode": "ranked",
		"class_id": "class.rogue", "primary_tree_id": "tree.bladedancer", "secondary_tree_id": null,
		"earned_talent_points": 10, "talent_ranks": RANKS.duplicate(), "rotation_skill_ids": ROTATION.duplicate()}

static func rotation(skills: Array[Skill]) -> Array[Skill]:
	var requested: Array[Skill] = []
	for id in ROTATION:
		var skill := Skill.new()
		skill.id = id
		requested.append(skill)
	return BuildResolver.resolve_rotation(requested, skills)
