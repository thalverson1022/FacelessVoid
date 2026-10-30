extends SceneTree
## Paired 20/21-point builds with level-five capstones; live D019, no overrides.
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT := "res://reports/balance/twenty_one_point_capstones_d019_live"
const CASES := [
 {"name":"BD1","tree":"bladedancer","ranks":{"weakness":3,"whetstone":5,"rending_slash":1,"precision_attacks":1,"sharpened_edge":5,"opportunity":3,"weapon_master":1,"side_step":1},"rotation":["dance_of_death","quick_cut","stab","parrying_strike"]},
 {"name":"BD2","tree":"bladedancer","ranks":{"whetstone":5,"rending_slash":1,"fancy_footwork":5,"cloak_and_dagger":2,"opportunity":3,"weapon_master":2,"riposte":2},"rotation":["dance_of_death","quick_cut","quick_cut","quick_cut","quick_cut","quick_cut","leaping_plunge"]},
 {"name":"Thief","tree":"thief","ranks":{"keen_eye":4,"sticky_fingers":5,"fast_hands":5,"silvered_edge":3,"bribery":3},"rotation":["pick_pocket","mug"]},
 {"name":"Assassin","tree":"assassin","ranks":{"quick_hands":5,"hastened_poison":2,"echoing_toxin":3,"bypass":1,"toxic_tradeoff":5,"resonance":4},"rotation":["venom_jab","blinding_powder","virulent_poison"]},
]
var failed := false
func _initialize() -> void:
	SaveSystem.save_path = OUT + "/isolated_save.json"
	PracticeSaveSystem.save_path = OUT + "/isolated_practice.json"
	PracticeSaveSystem.core_save_path = OUT + "/isolated_core.json"
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr(message)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var registry := BuildContentRegistry.test_mode()
	var rows := []
	var entries := []
	for baseline in CASES:
		for points in [20,21]:
			var entry: Dictionary = baseline.duplicate(true)
			entry["points"] = points
			entry["name"] = baseline.name + "_" + str(points)
			if points == 21:
				match entry.tree:
					"bladedancer": entry.ranks["virulent_corruption"] = 1
					"thief": entry.ranks["gilded_blade"] = 1
					"assassin": entry.ranks["critical_poison"] = 1
			entries.append(entry)
	for entry in entries:
		var ranks := {}
		for key in entry.ranks:
			var talent_id: String = "talent." + entry.tree + "." + key
			if key == "whetstone": talent_id = "talent.bladedancer.wet_stone"
			if key == "sticky_fingers": talent_id = "talent.sticky_fingers"
			if key == "keen_eye": talent_id = "talent.keen_eye"
			if key == "gilded_blade": talent_id = "talent.gilded_blade"
			ranks[talent_id] = entry.ranks[key]
		var ids := []
		for key in entry.rotation:
			var skill_id: String = "skill." + key
			if key == "rending_slash": skill_id = "skill.rending_thrust"
			if key == "parrying_strike": skill_id = "skill.parry_strike"
			ids.append(skill_id)
		var payload := {"build_schema_version":1,"content_revision":registry.revision,"allocation_mode":"ranked","class_id":"class.rogue","primary_tree_id":"tree."+entry.tree,"secondary_tree_id":null,"earned_talent_points":entry.points,"talent_ranks":ranks,"rotation_skill_ids":ids}
		var spec := {"id":entry.name,"label":"Paired 20/21-point builds / Crude Dagger / 30 seconds / live D019","ranked_build":payload,"monster":"res://data/monsters/training_dummy.tres","monster_overrides":{"hp":100000000},"gear":["res://data/gear/crude_dagger.tres"],"gold":0,"duration_ms":30000,"seed_start":1,"seed_count":200}
		var result := Lab.run_scenario_spec(spec,registry)
		check(result.status=="pass", "Lab failed: " + JSON.stringify(result))
		if result.status!="pass": continue
		SaveSystem.write_json(OUT+"/"+entry.name+".json",result)
		var decoded := BuildSaveCodec.decode(payload,registry)
		var practice := TrainingRoomState.new()
		practice.content_registry = registry
		practice.selected_class = registry.classes["class.rogue"]
		practice.ranked_build = decoded.model
		practice.selected_trees = decoded.model.trees()
		practice.earned_talent_points = entry.points
		practice.equipped_weapon = load("res://data/gear/crude_dagger.tres")
		var rotation: Array[Skill] = []
		for id in ids:
			for skill in practice.unlocked_skills():
				if skill.id==id: rotation.append(skill)
		practice.set_rotation(rotation)
		practice.set_duration_ms(30000)
		practice.set_fight_seed(1)
		practice.set_locked(true)
		practice.run_fight()
		check(practice.last_result!=null,"Practice produced result")
		if practice.last_result==null: continue
		var summary := Lab._combat_summary(1,practice.last_result)
		check(practice.last_result.duration_ms==30000,"Full 30-second window")
		check(is_equal_approx(summary.dps,result.samples[0].dps),"Practice and Lab seed-1 parity")
		var row := {"name":entry.name,"points":entry.points,"tree":entry.tree,"seed_1":summary,"dps":result.aggregate.dps,"mean_direct_dps":result.aggregate.physical_damage.mean/30.0,"mean_poison_dps":result.aggregate.poison_damage.mean/30.0,"spec":spec}
		rows.append(row)
		print(JSON.stringify(row))
	SaveSystem.write_json(OUT+"/summary.json",{"passed":not failed,"content_revision":registry.revision,"rows":rows})
	quit(1 if failed else 0)
