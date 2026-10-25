extends SceneTree
## Diagnostic stat copies only. Never modifies live content or saves.
const Lab = preload("res://scripts/tools/balance_lab.gd")
const Contracts = preload("res://scripts/systems/p6_poison_contracts.gd")
const ApplyDefense = preload("res://scripts/resources/apply_defense_debuff_effect.gd")
const OUT := "res://reports/balance/echoing_slowdown_probe"
var failed := false
func _initialize() -> void:
	if Contracts.ECHOING_DAMAGE_PER_RANK != 0.05 or CombatResolver.NEGATIVE_DEFENSE_BASE_PER_POINT != 0.5:
		printerr("Archived pre-D015 experiment. Use the live reproduction runner; preserve historical reports.")
		quit(1)
		return
	SaveSystem.save_path = OUT + "/isolated_save.json"
	PracticeSaveSystem.save_path = OUT + "/isolated_practice.json"
	PracticeSaveSystem.core_save_path = OUT + "/isolated_core.json"
	call_deferred("run")
func set_field(stats: PlayerStats, key: String, value: float) -> void:
	stats.set(key,value)
	if stats.derivation_base != null: stats.derivation_base.set(key,value)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var registry := BuildContentRegistry.test_mode()
	var payload := {"build_schema_version":1,"content_revision":registry.revision,"allocation_mode":"ranked","class_id":"class.rogue","primary_tree_id":"tree.assassin","secondary_tree_id":null,"earned_talent_points":10,"talent_ranks":{"talent.assassin.quick_hands":5,"talent.assassin.hastened_poison":2,"talent.assassin.echoing_toxin":3},"rotation_skill_ids":["skill.venom_jab","skill.blinding_powder","skill.virulent_poison"]}
	var decoded := BuildSaveCodec.decode(payload,registry)
	if decoded.error != "":
		printerr(decoded.error)
		quit(1)
		return
	var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
	var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],decoded.model,gear,0)
	var rotation: Array[Skill] = []
	for id in payload.rotation_skill_ids:
		for skill in content.skills:
			if skill.id==id: rotation.append(skill)
	var enemy: Monster = load("res://data/monsters/training_dummy.tres").duplicate(true)
	enemy.hp = 100000000
	var spec := {"id":"live_control","label":"Live exact ten-point Assassin","ranked_build":payload,"monster":"res://data/monsters/training_dummy.tres","monster_overrides":{"hp":100000000},"gear":["res://data/gear/crude_dagger.tres"],"gold":0,"duration_ms":30000,"seed_start":1,"seed_count":200}
	var native := Lab.run_scenario_spec(spec,registry)
	var rows := []
	for variant in [{"id":"live","remove_bonus":false,"interval_factor":1.0},{"id":"remove_bonus_only","remove_bonus":true,"interval_factor":1.0},{"id":"rank3_ten_percent_lower_frequency","remove_bonus":true,"interval_factor":1.0/0.9},{"id":"rank3_ten_percent_longer_interval","remove_bonus":true,"interval_factor":1.1},{"id":"rank3_twenty_percent_suppression","remove_bonus":true,"interval_factor":1.2},{"id":"rank3_suppression20_base4_intrinsic3","remove_bonus":true,"interval_factor":1.2,"base_poison":4.0,"intrinsic_delta":-2.0},{"id":"rank3_suppression20_potency4","remove_bonus":true,"interval_factor":1.2,"potency_stacks":4}]:
		var stats: PlayerStats = content.stats.duplicate(true)
		stats.derivation_base = content.stats.derivation_base.duplicate(true) if content.stats.derivation_base != null else null
		if variant.remove_bonus:
			set_field(stats,"poison_tick_damage_multiplier",stats.poison_tick_damage_multiplier/(1.0+Contracts.ECHOING_DAMAGE_PER_RANK*stats.echoing_toxin_rank))
		set_field(stats,"poison_tick_interval_multiplier",stats.poison_tick_interval_multiplier*variant.interval_factor)
		if variant.has("base_poison"):
			if stats.base_poison_damage != 8.0 or stats.bonus_base_elemental_damage != 10.0: failed=true
			set_field(stats,"base_poison_damage",variant.base_poison)
			set_field(stats,"bonus_base_elemental_damage",stats.bonus_base_elemental_damage+variant.intrinsic_delta)
			stats.sync_poison_damage_per_tick()
			if stats.derivation_base != null: stats.derivation_base.sync_poison_damage_per_tick()
		var dps := []
		var candidate_rotation: Array[Skill] = []
		for skill in rotation:
			var copy: Skill = skill.duplicate(true)
			if variant.has("potency_stacks") and copy.id == "skill.blinding_powder":
				var changed := false
				for effect in copy.effects:
					if effect is ApplyDefense:
						effect.use_assassin_points = false
						effect.base_stacks = variant.potency_stacks
						changed = true
				if not changed: failed = true
			candidate_rotation.append(copy)
		var poison := []
		var ticks := []
		var seed_one := {}
		for seed in range(1,201):
			var result := CombatResolver.resolve(candidate_rotation,stats,enemy,30000,seed)
			if not result.is_valid or result.duration_ms!=30000: failed=true
			var sample := Lab._combat_summary(seed,result)
			dps.append(sample.dps)
			poison.append(sample.poison_damage/30.0)
			ticks.append(sample.poison_damage_ticks)
			if seed==1:
				seed_one=sample
				var trace := CombatResolver.resolve(candidate_rotation,stats,enemy,30000,seed,true)
				if trace.total_damage!=result.total_damage or trace.rng_final_state!=result.rng_final_state: failed=true
				SaveSystem.write_json(OUT+"/"+variant.id+"_trace.json",{"records":trace.trace.records})
		var row := {"variant":variant,"dps":Lab._distribution(dps),"poison_dps":Lab._distribution(poison),"damaging_ticks":Lab._distribution(ticks),"seed_1":seed_one}
		if variant.id=="live" and (native.status!="pass" or not is_equal_approx(row.dps.mean,native.aggregate.dps.mean)): failed=true
		rows.append(row)
		print(JSON.stringify(row))
	SaveSystem.write_json(OUT+"/summary.json",{"passed":not failed,"build":payload,"duration_ms":30000,"seed_start":1,"seed_count":200,"rows":rows,"scope":"Exact rank-3 build only; ranks 1/2 and forced-tick builds not evaluated. Copied stats cancel live Echoing bonus and modify natural tick interval; live content unchanged."})
	quit(1 if failed else 0)
