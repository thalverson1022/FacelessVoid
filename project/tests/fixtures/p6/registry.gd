extends RefCounted

static func make() -> BuildContentRegistry:
	var registry := BuildContentRegistry.new()
	registry.mode = "ranked"
	registry.revision = "p6.test.scalars.1"
	registry.compatible = [registry.revision]
	var rogue := load("res://data/classes/rogue.tres").duplicate(false) as ClassDef
	rogue.trees = [load("res://tests/fixtures/p6/bladedancer.tres"), load("res://tests/fixtures/p6/thief.tres")]
	registry.classes[rogue.id] = rogue
	for tree in rogue.trees:
		registry.trees[tree.id] = tree
		for talent in tree.talents:
			registry.talents[talent.id] = talent
	assert(registry.validate_ranked() == "")
	return registry
