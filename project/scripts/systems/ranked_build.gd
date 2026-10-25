class_name RankedBuild
extends RefCounted
const StatRule := preload("res://scripts/resources/stat_derivation_rule.gd")
## T6 pure allocation model. No disk IO, live singleton or combat execution.
## Graph-only fixtures can allocate; resolution requires reviewed rank content.
signal changed

var _primary: SubclassTree
var _secondary: SubclassTree
var _ranks: Dictionary = {}
var _budget: int = 0
var last_error := ""

func primary_tree() -> SubclassTree:
	return _primary

func secondary_tree() -> SubclassTree:
	return _secondary

func trees() -> Array[SubclassTree]:
	var result: Array[SubclassTree] = []
	if _primary != null:
		result.append(_primary)
	if _secondary != null:
		result.append(_secondary)
	return result

func budget() -> int:
	return _budget

func rank_of(id: String) -> int:
	return int(_ranks.get(id, 0))

func rank_map() -> Dictionary:
	return _ranks.duplicate()

func points_spent() -> int:
	var total := 0
	for value in _ranks.values():
		total += int(value)
	return total

func tree_points(tree: SubclassTree) -> int:
	var total := 0
	if tree != null:
		for talent in tree.talents:
			total += rank_of(talent.id)
	return total

func unspent_points() -> int:
	return _budget - points_spent()

func _fail(message: String) -> bool:
	last_error = message
	return false

func _commit(primary: SubclassTree, secondary: SubclassTree, ranks: Dictionary, points: int) -> bool:
	_primary = primary
	_secondary = secondary
	_ranks = ranks.duplicate()
	_budget = points
	last_error = ""
	changed.emit()
	return true

## Initialization/validated restore API for T7; not a player respec operation.
func configure(primary: SubclassTree, secondary: SubclassTree, points: Variant, ranks: Dictionary = {}) -> bool:
	var error := validate(primary, secondary, points, ranks)
	if error != "":
		return _fail(error)
	return _commit(primary, secondary, ranks, int(points))

func set_budget(points: Variant) -> bool:
	var error := validate(_primary, _secondary, points, _ranks)
	if error != "":
		return _fail(error)
	return _commit(_primary, _secondary, _ranks, int(points))

func choose_secondary(tree: SubclassTree, access_allowed: bool) -> bool:
	if not access_allowed or _primary == null or _secondary != null or tree == null:
		return _fail("Secondary selection is unavailable.")
	return configure(_primary, tree, _budget, _ranks)

## Practice-only role editing. Removing primary explicitly clears both roles.
func set_practice_trees(primary: SubclassTree, secondary: SubclassTree) -> bool:
	if primary == null:
		return configure(null, null, _budget)
	var kept := {}
	for tree in [primary, secondary]:
		if tree == null:
			continue
		for talent in tree.talents:
			if _ranks.has(talent.id):
				kept[talent.id] = _ranks[talent.id]
	return configure(primary, secondary, _budget, kept)

static func supporting_points(tree: SubclassTree, gate: int, ranks: Dictionary) -> int:
	var total := 0
	for talent in tree.talents:
		if talent.required_tree_points < gate:
			total += int(ranks.get(talent.id, 0))
	return total

func buy(id: String) -> bool:
	var owner := _owner(id)
	if owner == null:
		return _fail("Unknown talent: %s" % id)
	var talent := _talent(owner, id)
	if supporting_points(owner, talent.required_tree_points, _ranks) < talent.required_tree_points:
		return _fail("%s requires %d points in lower tiers of %s before purchase." % [id, talent.required_tree_points, owner.id])
	var candidate := _ranks.duplicate()
	candidate[id] = rank_of(id) + 1
	return configure(_primary, _secondary, _budget, candidate)

func refund(id: String, respec_allowed: bool) -> bool:
	if not respec_allowed:
		return _fail("Respec is available during Tavern planning and between contracts.")
	if rank_of(id) == 0:
		return _fail("Talent has no rank to refund: %s" % id)
	var candidate := _ranks.duplicate()
	if rank_of(id) == 1:
		candidate.erase(id)
	else:
		candidate[id] = rank_of(id) - 1
	return configure(_primary, _secondary, _budget, candidate)

func refund_all(respec_allowed: bool) -> bool:
	if not respec_allowed:
		return _fail("Respec is available during Tavern planning and between contracts.")
	return configure(_primary, _secondary, _budget)

func refund_tree(tree_id: String, respec_allowed: bool) -> bool:
	if not respec_allowed:
		return _fail("Respec is available during Tavern planning and between contracts.")
	for tree in trees():
		if tree.id != tree_id: continue
		var retained := rank_map()
		for talent in tree.talents: retained.erase(talent.id)
		return configure(_primary, _secondary, _budget, retained)
	return _fail("Tree is not selected.")

func _owner(id: String) -> SubclassTree:
	for tree in trees():
		if _talent(tree, id) != null:
			return tree
	return null

static func _talent(tree: SubclassTree, id: String) -> Talent:
	for talent in tree.talents:
		if talent != null and talent.id == id:
			return talent
	return null

static func validate(primary: SubclassTree, secondary: SubclassTree, points: Variant, ranks: Dictionary) -> String:
	if typeof(points) != TYPE_INT or points < 0 or points > BuildProgression.POINT_CAP:
		return "Budget must be an integer from 0 to 45."
	if primary == null:
		return "A primary tree is required." if secondary != null or not ranks.is_empty() else ""
	if primary.id == "" or (secondary != null and (secondary.id == "" or secondary.id == primary.id)):
		return "Tree roles must have distinct, nonempty IDs."
	var definitions := {}
	var owners := {}
	var totals := {}
	for tree in [primary, secondary]:
		if tree == null:
			continue
		totals[tree.id] = 0
		for talent in tree.talents:
			if talent == null or talent.id == "" or definitions.has(talent.id) or talent.max_ranks < 1 or talent.required_tree_points < 0:
				return "Invalid or duplicate talent definition."
			definitions[talent.id] = talent
			owners[talent.id] = tree.id
	var visited: Array[String] = []
	while visited.size() < definitions.size():
		var previous_size := visited.size()
		for id in definitions:
			if visited.has(id):
				continue
			var ready := true
			for prerequisite in definitions[id].prerequisite_ids:
				if not definitions.has(prerequisite) or owners[prerequisite] != owners[id]:
					return "Invalid prerequisite reference: %s" % prerequisite
				if not visited.has(prerequisite):
					ready = false
			if ready:
				visited.append(id)
		if visited.size() == previous_size:
			return "Talent prerequisites contain a cycle."
	for id in ranks:
		if typeof(id) != TYPE_STRING or not definitions.has(id):
			return "Unknown talent: %s" % str(id)
		var rank: Variant = ranks[id]
		if typeof(rank) != TYPE_INT or rank < 1 or rank > definitions[id].max_ranks:
			return "Invalid rank for %s; omit zero ranks." % id
		totals[owners[id]] += rank
	var total := 0
	for amount in totals.values():
		total += int(amount)
	if total > points:
		return "Allocated ranks exceed earned budget."
	for id in ranks:
		var talent: Talent = definitions[id]
		var supporting := 0
		for other_id in ranks:
			if owners[other_id] == owners[id] and definitions[other_id].required_tree_points < talent.required_tree_points:
				supporting += int(ranks[other_id])
		if supporting < talent.required_tree_points:
			return "%s requires %d retained points in lower tiers of %s (would have %d)." % [id, talent.required_tree_points, owners[id], supporting]
		for prerequisite in talent.prerequisite_ids:
			if owners.get(prerequisite) != owners[id] or int(ranks.get(prerequisite, 0)) < 1:
				return "%s requires one rank in %s." % [id, prerequisite]
	return ""

static func content_error(tree: SubclassTree) -> String:
	var candidate := RankedBuild.new()
	if not candidate.configure(tree, null, 0):
		return candidate.last_error
	return candidate.resolved_content()["error"]

## Adapt full rank effects into the established stat/gear resolver, without
## repeating modifiers or inferring per-rank arithmetic from draft text.
func resolved_content() -> Dictionary:
	var resolved_trees: Array[SubclassTree] = []
	var resolved_talents: Array[Talent] = []
	for tree in trees():
		if not tree.ranked_content_ready:
			return {"error": "Ranked content is not ready: %s" % tree.id}
		for talent in tree.talents:
			if talent.ranks.size() != talent.max_ranks or talent.ranks.has(null):
				return {"error": "Missing explicit rank effects: %s" % talent.id}
			for rank_effects in talent.ranks:
				var shadow_error: String = preload("res://scripts/systems/shadow_passives.gd").validation_error(rank_effects)
				if shadow_error != "":
					return {"error": shadow_error + ": " + talent.id}
				var assassin_error: String = preload("res://scripts/systems/assassin_passives.gd").validation_error(rank_effects)
				if assassin_error != "":
					return {"error": assassin_error + ": " + talent.id}
				if rank_effects.bribery_base_stacks not in [0, 2, 4, 6] or rank_effects.finders_keepers_rank not in [0, 1, 2] or rank_effects.silvered_edge_rank not in [0, 1, 2, 3]:
					return {"error": "Invalid Thief passive rank: " + talent.id}
				if rank_effects.riposte_rank < 0 or rank_effects.riposte_rank > 2:
					return {"error": "Invalid Riposte rank: " + talent.id}
				if rank_effects.footwork_rank < 0 or rank_effects.footwork_rank > 5:
					return {"error": "Invalid Footwork rank: " + talent.id}
				var derivation_kinds := {}
				for rule in rank_effects.stat_derivations:
					if not rule is StatRule:
						return {"error": "Unsupported stat derivation resource: " + talent.id}
					if rule.validation_error() != "":
						return {"error": rule.validation_error()}
					if derivation_kinds.has(rule.kind):
						return {"error": "Duplicate rank stat derivation: " + talent.id}
					derivation_kinds[rule.kind] = true
		var copy := tree.duplicate(false) as SubclassTree
		copy.innate_modifiers = tree.innate_modifiers.duplicate()
		copy.unlocked_skills = tree.unlocked_skills.duplicate()
		copy.skill_augments = tree.skill_augments.duplicate()
		for modifier in tree.primary_point_modifiers:
			if modifier == null or modifier.operation != StatModifier.OperationType.ADD:
				return {"error": "Per-point intrinsic must be an explicit additive contribution."}
		if tree == _primary:
			for modifier in tree.primary_point_modifiers:
				var scaled := modifier.duplicate() as StatModifier
				scaled.value *= tree_points(tree)
				copy.innate_modifiers.append(scaled)
		for unlock in tree.automatic_unlocks:
			if unlock != null and unlock.skill != null and tree_points(tree) >= unlock.required_points:
				copy.unlocked_skills.append(unlock.skill)
		for talent in tree.talents:
			var rank := rank_of(talent.id)
			if rank == 0:
				continue
			if talent.ranks.size() != talent.max_ranks or talent.ranks[rank - 1] == null:
				return {"error": "Missing explicit rank effects: %s" % talent.id}
			var effects := talent.ranks[rank - 1]
			var selected := talent.duplicate(false) as Talent
			selected.stat_modifiers = effects.stat_modifiers
			selected.triggered_skill_effects = effects.triggered_skill_effects
			selected.stat_derivations = effects.stat_derivations.duplicate()
			selected.footwork_rank = effects.footwork_rank
			selected.gilded_blade_enabled = effects.gilded_blade_enabled
			selected.silvered_edge_rank = effects.silvered_edge_rank
			selected.precision_enabled = effects.precision_enabled
			selected.riposte_rank = effects.riposte_rank
			selected.side_step_enabled = effects.side_step_enabled
			selected.shred_cleanse_immune = effects.shred_cleanse_immune
			selected.bribery_base_stacks = effects.bribery_base_stacks
			selected.finders_keepers_rank = effects.finders_keepers_rank
			for field in preload("res://scripts/systems/assassin_passives.gd").FIELDS:
				selected.set(field, effects.get(field))
			for field in preload("res://scripts/systems/shadow_passives.gd").FIELDS:
				selected.set(field, effects.get(field))
			resolved_talents.append(selected)
			copy.skill_augments.append_array(effects.skill_augments)
		resolved_trees.append(copy)
	return {"error": "", "trees": resolved_trees, "talents": resolved_talents}
