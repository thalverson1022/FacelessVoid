class_name BuildSaveCodec
extends RefCounted

static func encode(state, registry: BuildContentRegistry) -> Dictionary:
	var roles: Array[SubclassTree] = state.selected_trees
	var ranks := {}
	if state.ranked_build != null:
		ranks = state.ranked_build.rank_map()
	else:
		for talent in state.selected_talents:
			ranks[talent.id] = 1
	return {
		"build_schema_version": 1, "content_revision": registry.revision,
		"allocation_mode": registry.mode if roles.is_empty() and ranks.is_empty() else ("ranked" if state.ranked_build != null else "legacy"),
		"class_id": state.selected_class.id if state.selected_class != null else null,
		"primary_tree_id": roles[0].id if roles.size() > 0 else null,
		"secondary_tree_id": roles[1].id if roles.size() > 1 else null,
		"earned_talent_points": state.earned_talent_points,
		"talent_ranks": ranks, "rotation_skill_ids": SaveSystem._skill_ids(state.rotation),
	}

static func decode(value: Variant, registry: BuildContentRegistry) -> Dictionary:
	var fail := {"error": "Invalid build payload."}
	if typeof(value) != TYPE_DICTIONARY or registry.error != "":
		return fail
	for field in ["build_schema_version", "content_revision", "allocation_mode", "class_id", "primary_tree_id", "secondary_tree_id", "earned_talent_points", "talent_ranks", "rotation_skill_ids"]:
		if not value.has(field):
			return fail
	if typeof(value.build_schema_version) != TYPE_INT or value.build_schema_version != 1 or value.allocation_mode != registry.mode:
		return fail
	if typeof(value.content_revision) != TYPE_STRING or not registry.compatible.has(value.content_revision):
		return {"error": "Unsupported content revision."}
	var class_def: ClassDef
	if value.class_id != null:
		if typeof(value.class_id) != TYPE_STRING or not registry.classes.has(value.class_id):
			return fail
		class_def = registry.classes[value.class_id]
	var roles: Array[SubclassTree] = []
	for field in ["primary_tree_id", "secondary_tree_id"]:
		var id: Variant = value[field]
		if id == null:
			continue
		if typeof(id) != TYPE_STRING or not registry.trees.has(id) or class_def == null:
			return fail
		var tree: SubclassTree = registry.trees[id]
		if not class_def.trees.has(tree) or roles.has(tree):
			return fail
		roles.append(tree)
	if value.primary_tree_id == null and value.secondary_tree_id != null:
		return fail
	var budget: Variant = value.earned_talent_points
	if typeof(budget) != TYPE_INT or budget < 0 or budget > 45 or typeof(value.talent_ranks) != TYPE_DICTIONARY or typeof(value.rotation_skill_ids) != TYPE_ARRAY:
		return fail
	for id in value.rotation_skill_ids:
		if typeof(id) != TYPE_STRING:
			return fail
	var model: RankedBuild
	var selected: Array[Talent] = []
	if registry.mode == "ranked":
		var problem := registry.validate_ranked()
		if problem != "":
			return {"error": problem}
		model = RankedBuild.new()
		if not model.configure(roles[0] if roles.size() > 0 else null, roles[1] if roles.size() > 1 else null, budget, value.talent_ranks):
			return {"error": model.last_error}
		if roles.is_empty():
			model = null # Preserve ordinary class/subclass selection after a fresh reset.
	else:
		for id in value.talent_ranks:
			if typeof(id) != TYPE_STRING or typeof(value.talent_ranks[id]) != TYPE_INT or value.talent_ranks[id] != 1 or not registry.talents.has(id):
				return fail
			var talent: Talent = registry.talents[id]
			var owned := false
			for tree in roles:
				owned = owned or tree.talents.has(talent)
			if not owned:
				return fail
			selected.append(talent)
		if PassiveAllocator.points_spent(selected) > budget:
			return fail
		for talent in selected:
			if not PassiveAllocator.prerequisites_satisfied(selected, talent):
				return fail
	return {"error": "", "class": class_def, "trees": roles, "talents": selected, "model": model, "budget": budget, "rotation_ids": value.rotation_skill_ids}

static func apply(decoded: Dictionary, state) -> void:
	state.selected_class = decoded["class"]
	state.selected_trees = decoded.trees
	state.selected_talents = decoded.talents
	state.ranked_build = decoded.model
	state.earned_talent_points = decoded.budget
	var requested: Array[Skill] = []
	for id in decoded.rotation_ids:
		var skill := Skill.new()
		skill.id = id
		requested.append(skill)
	state.rotation_changes = BuildResolver.normalize_rotation(requested, state.unlocked_skills())
	state.rotation = state.rotation_changes.rotation
	state.build_locked = false
