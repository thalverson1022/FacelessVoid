extends RefCounted
## M5-T6 reviewed resources; source drafts remain documentation only.
const TALENT_PATHS := [
	"res://data/p6/thief/sticky_fingers.tres",
	"res://data/p6/thief/fast_hands.tres",
	"res://data/p6/thief/fill_your_pockets.tres",
	"res://data/p6/thief/charisma.tres",
	"res://data/p6/thief/bribery.tres",
	"res://data/p6/thief/silvered_edge.tres",
	"res://data/p6/thief/finders_keepers.tres",
	"res://data/p6/thief/load_dice.tres",
	"res://data/p6/thief/gilded_blade.tres",
]

static func extend_registry(registry: BuildContentRegistry) -> void:
	var tree: SubclassTree = registry.trees["tree.thief"]
	tree.icon = preload("res://assets/subclass_icons/rogue/thief.png")
	for path in TALENT_PATHS:
		var talent := load(path).duplicate(true) as Talent
		tree.talents.append(talent)
		registry.talents[talent.id] = talent
	for spec in [[6, "pick_pocket"], [9, ""], [12, "big_score"]]:
		var unlock := TreeSkillUnlock.new()
		unlock.required_points = spec[0]
		if spec[1] != "":
			unlock.skill = preload("res://scripts/systems/p6_thief_contracts.gd").skill(spec[1])
		tree.automatic_unlocks.append(unlock)
