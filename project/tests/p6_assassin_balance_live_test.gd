extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
const Full = preload("res://tests/p6_full_assassin_test.gd")
const View = preload("res://scripts/ui/ranked_talent_view.gd")
var failed := false
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + message)
func _run() -> void:
	var registry := BuildContentRegistry.test_mode()
	var build := RankedBuild.new()
	check(build.configure(registry.trees["tree.assassin"],null,35,Full.full_ranks()),"full single-tree build")
	var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
	var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],build,gear,0)
	check(content.error == "", "release build resolves")
	check(is_equal_approx(content.stats.bonus_base_elemental_damage,22.5),"innate five plus 17.5 primary")
	check(content.stats.assassin_tree_points==35,"Powder still counts all 35 invested points")
	check(content.stats.poison_tick_damage_multiplier==1.5 and content.stats.physical_damage_multiplier==0.5,"Toxic selected factors")
	var view := View.new()
	check(view.bonus_summary(registry.trees["tree.assassin"],true).contains("+0.5 Base Elemental Damage"),"fractional primary bonus displayed accurately")
	for spec in [["echoing_toxin",3,"20% Suppression"],["resonance",4,"20%"],["toxic_tradeoff",5,"50%"]]:
		check(view.effects(registry.talents["talent.assassin."+spec[0]],spec[1]).contains(spec[2]),"updated rank description " + spec[0])
	view.free()
	var payload := {"build_schema_version":1,"content_revision":registry.revision,"allocation_mode":"ranked","class_id":"class.rogue","primary_tree_id":"tree.assassin","secondary_tree_id":null,"earned_talent_points":35,"talent_ranks":Full.full_ranks(),"rotation_skill_ids":["skill.poison_vile","skill.blinding_powder","skill.stab","skill.stab","skill.stab","skill.virulent_poison"]}
	var result := Lab.run_scenario_spec({"id":"assassin_d015_live","label":"Live approved Assassin balance","ranked_build":payload,"monster":"res://data/monsters/training_dummy.tres","monster_overrides":{"hp":100000000},"gear":["res://data/gear/crude_dagger.tres"],"gold":0,"duration_ms":30000,"seed_start":1,"seed_count":200},registry)
	check(result.status=="pass","native Balance Lab succeeds without diagnostic scaling")
	check(absf(result.aggregate.dps.mean-245.12117)<0.05,"D015 full-build reference matches Echoing suppression and one-tenth negative defenses")
	DirAccess.make_dir_recursive_absolute("res://reports/p6_d015_assassin_balance_live")
	SaveSystem.write_json("res://reports/p6_d015_assassin_balance_live/lab.json",result)
	print("Live Assassin 200-seed mean DPS: %.5f" % result.aggregate.dps.mean)
	quit(1 if failed else 0)
