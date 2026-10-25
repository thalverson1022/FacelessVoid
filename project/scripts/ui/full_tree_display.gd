extends RefCounted
## Detached presentation copies only. Never pass these to RankedBuild or a resolver.
const CATALOG := "res://data/ui/full_tree_display.json"

static func tree_for(source: SubclassTree) -> SubclassTree:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	var display: SubclassTree = source.duplicate(false)
	display.talents = source.talents.duplicate()
	display.automatic_unlocks = source.automatic_unlocks.duplicate()
	for tree in data.trees:
		if tree.id != source.id: continue
		var layout := {}
		for entry in tree.talents:
			layout[entry.id] = Vector2(float(entry.position.x), int(entry.tier) - 1)
			if RankedBuild._talent(source, entry.id) != null: continue
			var talent := Talent.new()
			talent.id = entry.id
			talent.display_name = entry.name
			talent.max_ranks = int(entry.max_ranks)
			talent.required_tree_points = int(entry.required_points)
			for id in entry.prerequisites: talent.prerequisite_ids.append(str(id))
			talent.set_meta("display_only", true)
			display.talents.append(talent)
		display.set_meta("authored_layout", layout)
		for entry in tree.unlocks:
			var found := false
			for existing in source.automatic_unlocks:
				if existing.required_points == int(entry.required_points): found = true
			if found: continue
			var unlock := TreeSkillUnlock.new()
			unlock.required_points = int(entry.required_points)
			if entry.skill_id != null:
				unlock.skill = Skill.new()
				unlock.skill.id = entry.skill_id
				unlock.skill.display_name = entry.name
				unlock.skill.set_meta("display_only", true)
				unlock.skill.set_meta("draft_description", entry.draft_description)
			display.automatic_unlocks.append(unlock)
	return display
