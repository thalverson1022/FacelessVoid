class_name PassiveAllocator
extends RefCounted
## Validates passive/tree selection against the Adventure passive rules in
## docs/Phase 1 Context Docs/Current_Mechanics_Reference.md: point budget,
## max trees, tree membership, OR-group prerequisites, and dependent locks.

const POINT_BUDGET: int = BuildProgression.POINT_CAP
const MAX_TREES: int = 2


static func can_select_tree(selected_trees: Array[SubclassTree], tree: SubclassTree) -> bool:
	if selected_trees.has(tree):
		return true
	return selected_trees.size() < MAX_TREES


static func points_spent(selected_talents: Array[Talent]) -> int:
	var total: int = 0
	for talent in selected_talents:
		total += talent.cost
	return total


## True if removing `talent` would actually break a selected dependent's
## prerequisites -- i.e. some dependent has an OR-group containing `talent`
## where `talent` is the ONLY currently-selected option in that group. If
## another option in the same group is already selected too (e.g. both
## Quick Hands and Piercing Blades chosen, satisfying "Quick Hands or
## Piercing Blades"), removing `talent` is safe since the group stays
## satisfied via the other option.
static func has_dependents(selected_talents: Array[Talent], talent: Talent) -> bool:
	for other in selected_talents:
		if other == talent:
			continue
		for group in other.prerequisites:
			if not group.options.has(talent):
				continue
			var other_option_selected: bool = false
			for option in group.options:
				if option != talent and selected_talents.has(option):
					other_option_selected = true
					break
			if not other_option_selected:
				return true
	return false


static func prerequisites_satisfied(selected_talents: Array[Talent], talent: Talent) -> bool:
	for group in talent.prerequisites:
		if group.options.is_empty():
			continue
		var satisfied: bool = false
		for option in group.options:
			if selected_talents.has(option):
				satisfied = true
				break
		if not satisfied:
			return false
	return true


static func can_select_talent(selected_trees: Array[SubclassTree], selected_talents: Array[Talent], talent: Talent, point_budget: int = POINT_BUDGET) -> bool:
	if selected_talents.has(talent):
		return false
	var in_selected_tree: bool = false
	for tree in selected_trees:
		if tree.talents.has(talent):
			in_selected_tree = true
			break
	if not in_selected_tree:
		return false
	if not prerequisites_satisfied(selected_talents, talent):
		return false
	return points_spent(selected_talents) + talent.cost <= point_budget


static func can_deselect_talent(selected_talents: Array[Talent], talent: Talent) -> bool:
	return not has_dependents(selected_talents, talent)
