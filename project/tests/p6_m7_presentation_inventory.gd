extends SceneTree
## Read-only T2 inventory extractor. Run through the isolated closeout runner.
const View = preload("res://scripts/ui/ranked_talent_view.gd")
var skills := {}

func _initialize() -> void:
	call_deferred("run")

func add_skill(skill: Skill, origin: String) -> void:
	if skill == null: return
	if not skills.has(skill.id):
		skills[skill.id] = {"id": skill.id, "name": skill.display_name, "icon": skill.icon.resource_path if skill.icon != null else "", "origins": [], "summary": SkillTooltipFormatter.effect_summary(skill), "conditions": SkillTooltipFormatter.conditions_for(skill, null), "base_ms": skill.base_execution_ms, "minimum_ms": skill.min_execution_ms, "cooldown_ms": skill.cooldown_ms}
	if origin not in skills[skill.id].origins: skills[skill.id].origins.append(origin)

func run() -> void:
	var registry := BuildContentRegistry.test_mode()
	assert(registry.error == "", registry.error)
	var trees := []
	var total_ranks := 0
	for character in registry.classes.values():
		for skill in character.base_skills: add_skill(skill, character.id)
	for tree in registry.trees.values():
		var row := {"id": tree.id, "name": tree.display_name, "talents": [], "unlocks": []}
		for talent in tree.talents:
			var ranks := []
			for rank in range(1, talent.max_ranks + 1): ranks.append(View.effects(talent, rank))
			total_ranks += talent.max_ranks
			row.talents.append({"id": talent.id, "name": talent.display_name, "icon": talent.icon.resource_path if talent.icon != null else "", "max_ranks": talent.max_ranks, "gate": talent.required_tree_points, "prerequisites": talent.prerequisite_ids, "rank_descriptions": ranks})
			for skill in talent.unlocked_skills: add_skill(skill, talent.id)
		for unlock in tree.automatic_unlocks:
			row.unlocks.append({"points": unlock.required_points, "skill": unlock.skill.id if unlock.skill != null else null})
			add_skill(unlock.skill, tree.id + ":" + str(unlock.required_points))
		for skill in tree.unlocked_skills: add_skill(skill, tree.id)
		trees.append(row)
	var out := "res://reports/p6_m7_t2_inventory"
	DirAccess.make_dir_recursive_absolute(out)
	SaveSystem.write_json(out + "/inventory.json", {"revision": registry.revision, "adventure_revision": BuildContentRegistry.adventure().revision, "trees": trees, "talent_count": registry.talents.size(), "rank_count": total_ranks, "skills": skills.values(), "description_context": "Skill summaries use default planning stats; rank descriptions use each live TalentRank. Conditional build-specific wording is reviewed separately."})
	print("PASS M7 T2 inventory: ", registry.talents.size(), " talents, ", total_ranks, " ranks, ", skills.size(), " skills")
	quit()
