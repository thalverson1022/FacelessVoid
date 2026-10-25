extends "res://scripts/tools/run_assassin_balance_inquiry.gd"

func control(tree_id: String, macro: Array, gold: int = 0) -> Dictionary:
	var tree: SubclassTree = registry.trees[tree_id]
	var ranks := {}
	for talent in tree.talents: ranks[talent.id] = talent.max_ranks
	var b := RankedBuild.new()
	require(b.configure(tree,null,35,ranks),"full control allocation")
	var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
	var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],b,gear,gold)
	require(content.error == "","control resolution")
	var rotation: Array[Skill] = []
	for id in macro:
		for skill in content.skills:
			if skill.id == "skill."+id: rotation.append(skill)
	require(rotation.size() == macro.size(),"control macro complete")
	content["rotation"] = rotation
	content["payload"] = {"tree":tree_id,"points":35,"ranks":ranks,"rotation":macro,"starting_gold":gold}
	return content

func run() -> void:
	registry = BuildContentRegistry.test_mode()
	var blade := control("tree.bladedancer",["dance_of_death","quick_cut","stab","parry_strike","quick_cut","stab","parry_strike","leaping_plunge"])
	cohort("control_bladedancer",blade)
	var thief := control("tree.thief",["pick_pocket","steal","mug","big_score"])
	cohort("control_thief_gold0",thief)
	cohort("control_thief_gold500",control("tree.thief",["pick_pocket","steal","mug","big_score"],500))
	write("controls.json",{"pass":not bad,"checks":checks,"scenarios":rows,"scope":"Same Crude Dagger for all trees; Thief tested with 0 and 500 starting gold."})
	quit(1 if bad else 0)
