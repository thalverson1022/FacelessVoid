extends RefCounted
## M5-T4: explicit reviewed resources. Never executes draft or display catalog content.
const TALENT_PATHS := [
	"res://data/p6/bladedancer/weakness.tres",
	"res://data/p6/bladedancer/precision_attacks.tres",
	"res://data/p6/bladedancer/double_dip.tres",
	"res://data/p6/bladedancer/sharpened_edge.tres",
	"res://data/p6/bladedancer/riposte.tres",
	"res://data/p6/bladedancer/side_step.tres",
	"res://data/p6/bladedancer/weapon_master.tres",
	"res://data/p6/bladedancer/virulent_corruption.tres",
]

static func extend_registry(registry: BuildContentRegistry) -> void:
	var tree: SubclassTree = registry.trees["tree.bladedancer"]
	tree.icon = preload("res://assets/subclass_icons/rogue/bladedancer.png")
	for path in TALENT_PATHS:
		var talent := load(path).duplicate(true) as Talent
		tree.talents.append(talent)
		registry.talents[talent.id] = talent
