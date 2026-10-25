extends SceneTree
## Model fixtures are allocation graphs only, never executable game content.

func _initialize() -> void:
	_check_boundaries()
	_check_resolution()
	_check_planning_fixtures()
	print("P6 ranked build: PASS (121 fixtures, boundaries, resolution, rotation)")
	quit()

func _talent(id: String, maximum: int, gate: int = 0) -> Talent:
	var talent := Talent.new()
	talent.id = id
	talent.max_ranks = maximum
	talent.required_tree_points = gate
	return talent

func _tree(id: String, talents: Array[Talent]) -> SubclassTree:
	var tree := SubclassTree.new()
	tree.id = id
	tree.talents = talents
	return tree

func _check_boundaries() -> void:
	var root_talent := _talent("a.root", 5)
	var upper := _talent("a.upper", 5, 5)
	upper.prerequisite_ids = ["a.root"]
	var a := _tree("a", [root_talent, upper])
	var b := _tree("b", [_talent("b.root", 5)])
	var model := RankedBuild.new()
	assert(model.configure(a, b, 10))
	for i in 4:
		assert(model.buy("a.root"))
	assert(model.buy("b.root"))
	assert(not model.buy("a.upper")) # Other-tree spend cannot open this gate.
	assert(model.buy("a.root"))
	assert(model.buy("a.upper"))
	assert(not model.refund("a.root", true)) # Upper ranks cannot support their own gate.
	var before := model.rank_map()
	assert(not model.refund("a.root", true))
	assert(model.rank_map() == before)
	assert(model.last_error.contains("retained"))
	assert(not model.refund("a.upper", false))
	assert(not model.set_budget(4))
	assert(model.budget() == 10)
	for invalid in [-1, 0, 6, 1.5, "1", true]:
		assert(not model.configure(a, b, 10, {"a.root": invalid}))
		assert(model.rank_map() == before)
	assert(not model.configure(a, b, 45.0))
	assert(not model.configure(a, a, 10))
	assert(not model.configure(null, b, 10))
	assert(not model.configure(a, b, 3, {"a.root": 4}))
	assert(not model.configure(a, b, 10, {"unknown": 1}))
	assert(not model.choose_secondary(b, true))
	assert(model.refund_all(true))
	assert(model.primary_tree() == a and model.secondary_tree() == b)
	assert(model.budget() == 10 and model.unspent_points() == 10)
	# One prerequisite rank suffices; last rank removal is rejected, never cascaded.
	upper.required_tree_points = 0
	assert(model.configure(a, null, 10, {"a.root": 2, "a.upper": 1}))
	assert(model.refund("a.root", true))
	assert(not model.refund("a.root", true))
	assert(model.rank_of("a.upper") == 1)
	assert(not model.choose_secondary(b, false))
	assert(model.choose_secondary(b, true))
	assert(model.set_practice_trees(null, b))
	assert(model.primary_tree() == null and model.secondary_tree() == null)
	assert(model.points_spent() == 0)
	# Malformed cyclic graphs fail even if a retained rank map could mask the cycle.
	root_talent.prerequisite_ids = ["a.upper"]
	assert(not model.configure(a, null, 10))
	root_talent.prerequisite_ids = []
	# Every gate, including 20, is checked before purchase and after refund.
	for gate in [5, 10, 15, 20]:
		var base := _talent("g.base", 35)
		var gated := _talent("g.high", 2, gate)
		var graph := _tree("g", [base, gated])
		assert(model.configure(graph, null, 45, {"g.base": gate - 1}))
		assert(not model.buy("g.high"))
		assert(model.buy("g.base"))
		assert(model.buy("g.high"))
		assert(not model.refund("g.base", true))
		assert(not model.refund("g.base", true))

func _modifier(stat_id: String, value: float) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.stat_id = stat_id
	modifier.value = value
	return modifier

func _skill(id: String) -> Skill:
	var skill := Skill.new()
	skill.id = id
	return skill

func _check_resolution() -> void:
	var talent := _talent("a.rank", 12)
	for rank in 12:
		var effects := TalentRank.new()
		effects.stat_modifiers = [_modifier(StatCatalog.CRIT_CHANCE, (rank + 1) * 0.01)]
		var augment := SkillAugment.new()
		augment.target_skill_ids = ["skill.granted"]
		augment.poison_stacks_applied = rank + 1
		effects.skill_augments.append(augment)
		talent.ranks.append(effects)
	var granted := _skill("skill.granted")
	talent.unlocked_skills = [granted]
	var a := _tree("a", [talent])
	a.innate_modifiers = [_modifier(StatCatalog.BASE_ELEMENTAL_DAMAGE, 5)]
	a.primary_point_modifiers = [_modifier(StatCatalog.BASE_ELEMENTAL_DAMAGE, 1)]
	var b := _tree("b", [])
	b.innate_modifiers = [_modifier(StatCatalog.BASE_ELEMENTAL_DAMAGE, 7)]
	b.primary_point_modifiers = [_modifier(StatCatalog.BASE_ELEMENTAL_DAMAGE, 100)]
	for threshold in [1, 3, 6, 9, 12]:
		var unlock := TreeSkillUnlock.new()
		unlock.required_points = threshold
		unlock.skill = _skill("skill.auto%d" % threshold) if threshold != 9 else null
		a.automatic_unlocks.append(unlock)
	var model := RankedBuild.new()
	assert(model.configure(a, b, 45))
	assert(BuildResolver.resolve_ranked_build(null, model)["error"] != "")
	a.ranked_content_ready = true
	b.ranked_content_ready = true
	var zero := BuildResolver.resolve_ranked_build(null, model)
	assert(is_equal_approx(zero["stats"].bonus_base_elemental_damage, 12))
	assert(zero["skills"].is_empty())
	for amount in range(1, 13):
		assert(model.buy(talent.id))
		var result := BuildResolver.resolve_ranked_build(null, model)
		assert(result["error"] == "")
		var content := model.resolved_content()
		assert(content["trees"][0].skill_augments.size() == 1)
		assert(content["trees"][0].skill_augments[0].poison_stacks_applied == amount)
		assert(a.skill_augments.is_empty())
		assert(is_equal_approx(result["stats"].bonus_base_elemental_damage, 12 + amount))
		assert(is_equal_approx(result["stats"].crit_chance, amount * 0.01)) # Rank total, not sum.
		for threshold in [1, 3, 6, 12]:
			assert(_has_skill(result["skills"], "skill.auto%d" % threshold) == (amount >= threshold))
	assert(is_equal_approx(a.innate_modifiers[0].value, 5)) # Shared resource untouched.
	var final_result := BuildResolver.resolve_ranked_build(null, model)
	var macro: Array[Skill] = [granted, granted, _skill("missing")]
	for i in 11:
		macro.append(_skill("skill.auto12"))
	var normalized := BuildResolver.normalize_rotation(macro, final_result["skills"])
	assert(normalized["rotation"].size() == 10)
	assert(normalized["rotation"][0].id == normalized["rotation"][1].id)
	assert(normalized["removed"] == ["missing"])
	assert(normalized["overflow"].size() == 3)
	assert(model.refund(talent.id, true))
	var reduced := BuildResolver.resolve_ranked_build(null, model)
	assert(not _has_skill(reduced["skills"], "skill.auto12"))
	# An independent gear grant keeps a skill available after refunding all talents.
	var gear := GearItem.new()
	gear.unlocked_skills = [granted]
	assert(model.refund_all(true))
	var retained := BuildResolver.resolve_ranked_build(null, model, [gear])
	assert(_has_skill(retained["skills"], granted.id))
	# Changing role explicitly in Practice preserves rank stats but changes only scaling.
	assert(model.configure(b, a, 45, {talent.id: 2}))
	assert(is_equal_approx(BuildResolver.resolve_ranked_build(null, model)["stats"].bonus_base_elemental_damage, 12))

func _has_skill(skills: Array, id: String) -> bool:
	for skill in skills:
		if skill.id == id:
			return true
	return false

func _read_json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://../" + path)))

func _check_planning_fixtures() -> void:
	var fixtures := _read_json("docs/P6M2_T5_Build_Fixtures.json")
	var manifest := _read_json("docs/P6M2_T4_Content_Identity_Manifest.json")
	var graphs := {}
	for source in manifest["sources"]:
		var draft: Dictionary = _read_json(source["file"])["tree"]
		var mappings := {}
		for record in manifest["records"]:
			if record["source_file"] == source["file"] and record["kind"] == "talent":
				mappings[record["source_id"]] = record["runtime_id"]
		var graph := _tree(source["tree_id"], [])
		for raw in draft["talents"]:
			var gate := 0
			for level in draft["levels"]:
				if level["id"] == raw["level_id"]:
					gate = int(level["required_points"])
			var talent := _talent(mappings[raw["id"]], int(raw["max_ranks"]), gate)
			for prerequisite in raw["prerequisite_ids"]:
				talent.prerequisite_ids.append(mappings[prerequisite])
			graph.talents.append(talent)
		graphs[graph.id] = graph
	var snapshots := {}
	for name in fixtures["profiles"]:
		var profile: Dictionary = fixtures["profiles"][name]
		var model := RankedBuild.new()
		assert(model.configure(graphs[profile["tree_id"]], null, 45))
		var states: Array = [{}]
		for step in profile["purchases"]:
			while model.rank_of(step["talent_id"]) < int(step["to_rank"]):
				assert(model.buy(step["talent_id"]), model.last_error)
				states.append(model.rank_map())
		snapshots[name] = states
	for fixture in fixtures["fixtures"]:
		var primary: Dictionary = fixture["primary"]
		var secondary: Variant = fixture["secondary"]
		var primary_tree: SubclassTree = graphs[fixtures["profiles"][primary["profile"]]["tree_id"]]
		var secondary_tree: SubclassTree = null
		var ranks: Dictionary = snapshots[primary["profile"]][int(primary["points"])].duplicate()
		if secondary != null:
			secondary_tree = graphs[fixtures["profiles"][secondary["profile"]]["tree_id"]]
			ranks.merge(snapshots[secondary["profile"]][int(secondary["points"])])
		var model := RankedBuild.new()
		assert(model.configure(primary_tree, secondary_tree, int(fixture["budget"]), ranks), fixture["id"])
		assert(model.unspent_points() >= 0)
		assert(model.resolved_content()["error"] != "") # Drafts remain model-only.
	assert(fixtures["fixtures"].size() == 121)
