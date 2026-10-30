extends SceneTree
## M5-T4 actual registry allocations, complete ranks, combat, saves and lab inputs.
const Mixed = preload("res://tests/fixtures/p6/mixed_build.gd")
const View = preload("res://scripts/ui/ranked_talent_view.gd")
const PREFIX := "talent.bladedancer."
const PURCHASES := [["weakness",5],["wet_stone",5],["rending_slash",1],["fancy_footwork",5],["precision_attacks",1],["double_dip",2],["opportunity",3],["sharpened_edge",5],["cloak_and_dagger",2],["riposte",2],["side_step",1],["weapon_master",2],["virulent_corruption",1]]
var registry: BuildContentRegistry
var failed := false
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAILED: " + label)

func full_ranks() -> Dictionary:
	var result := {}
	for pair in PURCHASES: result[PREFIX + pair[0]] = pair[1]
	return result

func build(ranks: Dictionary, reverse := false, mixed := false) -> RankedBuild:
	var value := RankedBuild.new()
	var blade: SubclassTree = registry.trees["tree.bladedancer"]
	var thief: SubclassTree = registry.trees["tree.thief"]
	check(value.configure(thief if reverse else blade, blade if reverse else thief if mixed else null, 45, ranks), "Legal allocated build " + str(ranks))
	return value

func resolved(value: RankedBuild) -> Dictionary:
	var result := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], value)
	check(result.error == "", "Complete content resolves")
	return result

func skill(content: Dictionary, id: String) -> Skill:
	for item in content.skills:
		if item.id == id: return item
	check(false, "Missing skill " + id)
	return null

func target() -> Monster:
	var value := Monster.new()
	value.hp = 100000000
	return value

func assert_stats(ranks: Dictionary, result: Dictionary, reverse := false) -> void:
	var stats: PlayerStats = result.stats
	var total := 0
	for id in ranks:
		if id.begins_with(PREFIX): total += int(ranks[id])
	var r := func(id: String) -> int: return int(ranks.get(PREFIX + id, 0))
	var base: PlayerStats = registry.classes["class.rogue"].base_stats
	var chance := 0.05 + (0.0 if reverse else 0.002 * total)
	check(is_equal_approx(stats.retrigger_chance, chance), "Role/investment retrigger")
	check(stats.shred_value == base.shred_value + 5*r.call("weakness") + 100*r.call("virulent_corruption"), "Base Shred Value additions")
	check(stats.bonus_shred_stacks == base.bonus_shred_stacks + 2*r.call("virulent_corruption"), "Shred grants, not cap")
	check(stats.shred_cleanse_immune == (r.call("virulent_corruption") > 0), "Selective immunity bound")
	check(is_equal_approx(stats.bonus_physical_damage, float(r.call("wet_stone"))), "Whetstone complete rank")
	check(stats.precision_duration_ms == (-1 if r.call("precision_attacks") else 0), "Precision bound")
	check(stats.riposte_rank == r.call("riposte") and stats.side_step_enabled == (r.call("side_step") > 0), "Riposte and Side Step bound")
	check(stats.footwork_rank == r.call("fancy_footwork"), "Footwork rank")
	check(is_equal_approx(stats.crit_chance, clampf(base.crit_chance + chance * 0.5 * r.call("double_dip"),0,1)), "Double Dip no guarantee contribution")
	check(is_equal_approx(stats.crit_multiplier, base.crit_multiplier + 0.5*r.call("cloak_and_dagger")), "Crit damage percentage points")
	var keen := 1.1 if ranks.get("talent.keen_eye",0) == 5 else 1.0
	check(is_equal_approx(stats.physical_damage_multiplier, base.physical_damage_multiplier*(1.0+0.5*r.call("weapon_master"))*keen), "Multiplicative physical sources")
	check(is_equal_approx(float(stats.skill_damage_multipliers.get("skill.stab",1.0)),1.0+0.2*r.call("sharpened_edge")), "Sharpened Edge factor")
	check(not stats.skill_damage_multipliers.has("skill.quick_cut"), "Sharpened is skill-local")
	check(stats.triggered_skill_effects.size() == (1 if r.call("opportunity") else 0), "Opportunity binding")
	if r.call("opportunity"):
		check(is_equal_approx(stats.triggered_skill_effects[0].chance,0.1*r.call("opportunity")), "Opportunity exact rank chance")

func _ranks_and_edits() -> void:
	var baseline := full_ranks()
	var view := View.new()
	for talent in registry.trees["tree.bladedancer"].talents:
		for rank in range(talent.max_ranks + 1):
			var ranks := baseline.duplicate()
			if rank: ranks[talent.id] = rank
			else:
				ranks.erase(talent.id)
				for dependent in registry.trees["tree.bladedancer"].talents:
					if dependent.prerequisite_ids.has(talent.id): ranks.erase(dependent.id)
			var value := build(ranks)
			assert_stats(ranks, resolved(value))
			if rank > 0:
				var text: String = view.effects(talent, rank)
				check(text != "" and not "See skill effects" in text and not "Preview" in text, "Explicit rank description " + talent.id)
			if rank == talent.max_ranks:
				check(not value.buy(talent.id), "Max rank rejects atomically")
	view.free()
	var value := build({})
	check(not value.buy(PREFIX+"precision_attacks"), "Cannot bypass five-point gate")
	for pair in PURCHASES:
		for i in pair[1]:
			check(value.buy(PREFIX+pair[0]), "Legal purchase " + pair[0])
			var count: int = value.points_spent()
			var ids := {}
			for item in resolved(value).skills: ids[item.id] = true
			for entry in [[1,"skill.quick_cut"],[3,"skill.leaping_plunge"],[6,"skill.parry_strike"],[12,"skill.dance_of_death"]]:
				check(ids.has(entry[1]) == (count >= entry[0]), "Exact automatic threshold " + str(entry))
	check(value.points_spent() == 35 and resolved(value).skills.size() == 8, "Complete 35-point tree and eight including class skills")
	check(not value.set_budget(34) and value.budget()==45, "Budget reduction atomic")
	check(not value.refund(PREFIX+"precision_attacks",true), "Sharpened prerequisite cannot be removed")
	check(value.refund(PREFIX+"weapon_master",true), "Refund rank two to one")
	check(is_equal_approx(resolved(value).stats.physical_damage_multiplier,1.5), "Refund replaces 2x with 1.5x")
	check(value.buy(PREFIX+"weapon_master"), "Rebuy rank")
	check(value.refund_tree("tree.bladedancer",true), "Reset tree")
	assert_stats({},resolved(value))
	var invalid := registry.trees["tree.bladedancer"].duplicate(true) as SubclassTree
	RankedBuild._talent(invalid,PREFIX+"riposte").ranks[0].riposte_rank = 3
	check(RankedBuild.content_error(invalid) != "", "Invalid new rank field rejected")

func _combat() -> void:
	var content := resolved(build(full_ranks()))
	var stats: PlayerStats = content.stats
	var enemy := target()
	enemy.armor = 600
	var rend := skill(content,"skill.rending_thrust")
	var result := CombatResolver.resolve([rend],stats,enemy,1400,7,true)
	check(result.is_valid and result.cast_events[0].shred_stacks_applied == 4 and result.cast_events[0].shred_value == 135, "Actual allocated Virulent Rending grants four at base+125")
	check(result.cast_events[0].armor_reduction_applied == 540, "Four-stack application removes 540 armor")
	var quick := skill(content,"skill.quick_cut")
	var stab := skill(content,"skill.stab")
	var plunge := skill(content,"skill.leaping_plunge")
	var parry := skill(content,"skill.parry_strike")
	var dance := skill(content,"skill.dance_of_death")
	var rotation: Array[Skill] = [dance,quick,stab,quick,plunge,parry,rend,skill(content,"skill.heavy_slash")]
	var consumed_precision := false
	var consumed_footwork := false
	var side_step_hit := false
	var protected_cleanse := false
	for seed_value in range(1,21):
		for mode in range(4):
			var monster := target()
			if mode == 1: monster.cleanse_threshold = 2
			if mode == 2:
				monster.block = 10000
				monster.crit_negation = 1.0
			if mode == 3:
				monster.dodge_chance = 0.25
				monster.slow = 0.5
			var a := CombatResolver.resolve(rotation,stats,monster,20000,seed_value,true)
			var b := CombatResolver.resolve(rotation,stats,monster,20000,seed_value,true)
			var off := CombatResolver.resolve(rotation,stats,monster,20000,seed_value,false)
			check(a.is_valid and a.trace.records == b.trace.records and a.rng_final_state == off.rng_final_state and a.total_damage == off.total_damage, "Full-tree deterministic cohort %d/%d" % [seed_value,mode])
			var prior_shred := 0
			for event in a.cast_events:
				if event.cleanse_triggered and prior_shred > 0:
					protected_cleanse = true
					check(event.status_snapshot.shred == mini(500, prior_shred + event.shred_stacks_applied), "Allocated Virulent retains all existing Shred through cleanse")
				prior_shred = int(event.status_snapshot.get("shred", prior_shred))
				if event.lifecycle_snapshot.get("precision_consumed",0)>0: consumed_precision = true
				if event.lifecycle_snapshot.get("footwork_consumed",0)>0:
					consumed_footwork = true
					check(is_equal_approx(event.lifecycle_snapshot.riposte_multiplier,1.0+0.4*event.lifecycle_snapshot.footwork_consumed), "Allocated Riposte applies captured stacks")
				if event.skill.id == parry.id and not event.resource_unavailable and not event.was_dodged and event.physical_damage > 0:
					side_step_hit = true
					check(event.is_crit, "Allocated Side Step forces eligible Parry crit")
			if a.effect_lifecycle != null: check(a.effect_lifecycle.state.snapshot().is_empty(), "Fight cleanup")
	check(consumed_precision and consumed_footwork and side_step_hit, "New passives exercised through actual allocation")
	check(protected_cleanse, "Actual cohort exercised Shred protection")
	check(stats.precision_duration_ms == -1 and stats.riposte_rank == 2, "Resolver leaves input descriptors unchanged")

func _persistence_and_roles() -> void:
	var ranks := full_ranks()
	ranks["talent.keen_eye"] = 5
	for reverse in [false,true]:
		assert_stats(ranks,resolved(build(ranks,reverse,true)),reverse)
	var state := TrainingRoomState.new()
	state.content_registry = registry
	state.practice_save_path = "res://reports/p6_m5_t4_practice.json"
	state.set_class(registry.classes["class.rogue"])
	state.configure_ranked_build(registry.trees["tree.bladedancer"],registry.trees["tree.thief"])
	for pair in PURCHASES:
		for i in pair[1]: check(state.select_talent(registry.talents[PREFIX+pair[0]]), "Practice actual allocation")
	for i in 5: state.select_talent(registry.talents["talent.keen_eye"])
	var content := resolved(state.ranked_build)
	state.set_rotation([skill(content,"skill.stab"),skill(content,"skill.dance_of_death"),skill(content,"skill.stab")])
	check(PracticeSaveSystem.save_setup(state), "New revision persists")
	var restored := TrainingRoomState.new()
	restored.content_registry = registry
	restored.practice_save_path = state.practice_save_path
	check(PracticeSaveSystem.load_setup(restored).status == "loaded", "New revision loads")
	check(restored.ranked_build.rank_map()==state.ranked_build.rank_map() and restored.rotation.size()==3, "Full rank/duplicate rotation round trip")
	var payload := BuildSaveCodec.encode(state,registry)
	var lab := preload("res://scripts/tools/balance_lab.gd")
	var scenarios := []
	for reverse in [false,true]:
		var spec := {"id":"full_blade_"+str(reverse),"label":"Complete Bladedancer correctness", "ranked_build":payload.duplicate(true), "monster":"res://data/monsters/mouthy_drunk.tres", "monster_overrides":{"hp":1000000,"armor":600,"cleanse_threshold":2}, "gear":[],"duration_ms":30000,"seed_start":1,"seed_count":20}
		if reverse:
			spec.ranked_build.primary_tree_id = "tree.thief"
			spec.ranked_build.secondary_tree_id = "tree.bladedancer"
		var first := lab.run_scenario_spec(spec,registry)
		var again := lab.run_scenario_spec(spec,registry)
		check(first.status == "pass" and first.samples == again.samples and first.aggregate == again.aggregate, "Actual released Lab fixture repeats in both roles")
		scenarios.append(first)
	SaveSystem.write_json("res://reports/p6_m5_t4_mechanics/lab.json", {"scope":"Correctness only; balance remains M6", "scenarios":scenarios})
	for revision in ["p6.playable.mixed.1","p6.playable.bladedancer_core.1"]:
		var old := Mixed.payload()
		old.content_revision = revision
		if revision.ends_with("core.1"):
			old.secondary_tree_id = null
			old.talent_ranks = {PREFIX+"wet_stone":4,PREFIX+"rending_slash":1,PREFIX+"fancy_footwork":5}
			old.earned_talent_points = 10
		check(BuildSaveCodec.decode(old,registry).error == "", "Compatible prior revision " + revision)
	var bad := payload.duplicate(true)
	bad.content_revision = "p6.future.unknown"
	check(BuildSaveCodec.decode(bad,registry).error != "", "Future revision rejects")
	bad = payload.duplicate(true)
	bad.talent_ranks[PREFIX+"riposte"] = 3
	check(BuildSaveCodec.decode(bad,registry).error != "", "Corrupt rank rejects")
	check(restored.refund_tree_talents("tree.bladedancer"), "Practice tree reset")
	check(restored.ranked_build.rank_of("talent.keen_eye")==5 and restored.rotation.size()==2, "Other tree and duplicate base skills survive; Dance pruned")

func _run() -> void:
	registry = BuildContentRegistry.test_mode()
	check(registry.error == "" and registry.talents.size()==44, "Complete four-tree registry")
	if registry.error != "":
		printerr(registry.error)
		quit(1)
		return
	_ranks_and_edits()
	_combat()
	_persistence_and_roles()
	print("M5 full Bladedancer checks: ",checks)
	quit(1 if failed else 0)

