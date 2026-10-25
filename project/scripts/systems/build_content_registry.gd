class_name BuildContentRegistry
extends RefCounted
## A complete declared set. Fixture registries are injected explicitly, never discovered from saves.
const MANIFEST := "res://data/p6/compatibility_manifest.json"
var revision := ""
var mode := "legacy"
var classes: Dictionary = {}
var trees: Dictionary = {}
var talents: Dictionary = {}
var allowed_paths: Array = []
var compatible: Array = []
var incompatible: Array = []
var error := ""

const ADVENTURE_REVISION := "p6.adventure.1"
const ADVENTURE_ENABLED := true

## Reviewed M6 content; separate revision prevents legacy/Practice saves becoming runs.
static func adventure() -> BuildContentRegistry:
	var registry := test_mode()
	registry.revision = ADVENTURE_REVISION
	registry.compatible = [ADVENTURE_REVISION]
	registry.allowed_paths = current().allowed_paths.duplicate()
	return registry

## Test Mode/Practice retain their existing content revision and save contract.
static func test_mode() -> BuildContentRegistry:
	var registry := BuildContentRegistry.new()
	registry.revision = "p6.playable.shadow.1"
	registry.mode = "ranked"
	registry.compatible = [registry.revision, "p6.playable.assassin.1", "p6.playable.thief.1", "p6.playable.bladedancer.1", "p6.playable.mixed.1", "p6.playable.bladedancer_core.1"]
	var rogue: ClassDef = preload("res://data/classes/rogue.tres").duplicate(true)
	var tree: SubclassTree = preload("res://data/p6/test_mode/tree.tres").duplicate(true)
	rogue.trees = [tree]
	registry.classes[rogue.id] = rogue
	registry.trees[tree.id] = tree
	for talent in tree.talents:
		registry.talents[talent.id] = talent
	preload("res://scripts/systems/playable_mixed_content.gd").extend_registry(registry)
	preload("res://scripts/systems/playable_bladedancer_content.gd").extend_registry(registry)
	preload("res://scripts/systems/playable_thief_content.gd").extend_registry(registry)
	preload("res://scripts/systems/playable_assassin_content.gd").extend_registry(registry)
	preload("res://scripts/systems/playable_shadow_content.gd").extend_registry(registry)
	registry.error = registry.validate_ranked()
	return registry

## Retained packaged compatibility registry for legacy fixtures/resource allowlists.
## New player runs use adventure(); Practice uses test_mode().
static func current() -> BuildContentRegistry:
	var registry := BuildContentRegistry.new()
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if typeof(raw) != TYPE_DICTIONARY:
		registry.error = "Missing or invalid packaged content registry."
		return registry
	var data: Dictionary = raw
	registry.revision = data.content_revision
	registry.mode = data.mode
	registry.compatible = data.compatible_revisions
	registry.incompatible = data.incompatible_revisions
	registry.allowed_paths = data.resource_paths
	for path in data.classes:
		var class_def := load(path) as ClassDef
		if class_def == null:
			registry.error = "Missing registered class."
			return registry
		registry.classes[class_def.id] = class_def
		for tree in class_def.trees:
			registry.trees[tree.id] = tree
			for talent in tree.talents:
				if registry.talents.has(talent.id):
					registry.error = "Duplicate runtime talent ID."
				registry.talents[talent.id] = talent
	return registry

func validate_ranked() -> String:
	if revision == "" or mode != "ranked" or trees.is_empty():
		return "Ranked registry is incomplete."
	var all_ids := {}
	for tree in trees.values():
		var problem := RankedBuild.content_error(tree)
		if problem != "":
			return problem
		if not _valid_modifiers(tree.innate_modifiers) or not _valid_modifiers(tree.primary_point_modifiers):
			return "Invalid intrinsic modifier."
		for talent in tree.talents:
			for rank in talent.ranks:
				if rank.footwork_rank < 0 or rank.footwork_rank > 5:
					return "Invalid Footwork rank: " + talent.id
				if not _valid_modifiers(rank.stat_modifiers):
					return "Unsupported or invalid rank modifier: " + talent.id
				for trigger in rank.triggered_skill_effects:
					if trigger == null or trigger.skill == null or not is_finite(trigger.chance) or trigger.chance < 0 or trigger.chance > 1:
						return "Invalid triggered skill contract."
				for augment in rank.skill_augments:
					if augment == null or augment.target_skill_ids.is_empty() or augment.poison_stacks_applied < 0:
						return "Invalid skill augment contract."
			if all_ids.has(talent.id) or talent.required_tree_points not in [0, 5, 10, 15, 20]:
				return "Duplicate talent ID or unsupported gate."
			all_ids[talent.id] = true
		var thresholds := []
		for unlock in tree.automatic_unlocks:
			if unlock == null or unlock.required_points not in [1, 3, 6, 9, 12] or thresholds.has(unlock.required_points):
				return "Invalid automatic unlock slot."
			thresholds.append(unlock.required_points)
		var reach := RankedBuild.new()
		reach.configure(tree, null, 45)
		var progress := true
		while progress:
			progress = false
			for talent in tree.talents:
				if reach.buy(talent.id):
					progress = true
		for talent in tree.talents:
			if reach.rank_of(talent.id) == 0:
				return "Unreachable talent: " + talent.id
	return ""


static func _valid_modifiers(modifiers: Array[StatModifier]) -> bool:
	for modifier in modifiers:
		if modifier != null and modifier.stat_id != "" and not StatCatalog.has_stat(modifier.stat_id):
			return false
		if modifier == null or not is_finite(modifier.value) or modifier.operation not in [StatModifier.OperationType.ADD, StatModifier.OperationType.MULTIPLY] or not StatCatalog.has_stat(StatCatalog.canonical_id_for_modifier(modifier)):
			return false
	return true
