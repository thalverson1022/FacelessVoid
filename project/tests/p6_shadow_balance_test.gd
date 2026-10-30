extends SceneTree
const Full = preload("res://tests/p6_full_shadow_test.gd")
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT := "res://reports/balance/shadow_d012"
var failed := false
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed=true
		printerr("FAILED: "+message)
func payload(registry: BuildContentRegistry, points: int, partner := "", reverse := false) -> Dictionary:
	var ranks := {}
	var left := points
	for pair in Full.PURCHASES:
		var amount := mini(left,pair[1])
		if amount>0: ranks[pair[0]]=amount
		left-=amount
	if partner!="": ranks.merge(Full.PARTNERS[partner])
	var b := RankedBuild.new()
	check(b.configure(registry.trees[partner] if reverse else registry.trees["tree.shadow"],registry.trees["tree.shadow"] if reverse else (registry.trees[partner] if partner!="" else null),45,ranks),"Lab legal allocation")
	var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],b)
	var available := {}
	for s in content.skills: available[s.id]=s
	var ids := []
	for id in ["toxic_flurry","distilled_corruption","beguiling_presence","touch_of_darkness","stab","killers_mark"]:
		ids.append("skill."+id if available.has("skill."+id) else "skill.stab")
	return {"build_schema_version":1,"content_revision":registry.revision,"allocation_mode":"ranked","class_id":"class.rogue","primary_tree_id":b.primary_tree().id,"secondary_tree_id":b.secondary_tree().id if b.secondary_tree()!=null else null,"earned_talent_points":45 if partner!="" else points,"talent_ranks":ranks,"rotation_skill_ids":ids}
func _run() -> void:
	var registry := BuildContentRegistry.test_mode()
	DirAccess.make_dir_recursive_absolute(OUT)
	var cohorts := []
	for points in [1,10,20,25,35]: cohorts.append({"id":"shadow_"+str(points),"payload":payload(registry,points)})
	for partner in Full.PARTNERS:
		for reverse in [false,true]: cohorts.append({"id":"shadow_35_"+partner.trim_prefix("tree.")+"_10_"+str(reverse),"payload":payload(registry,35,partner,reverse)})
	var summary := []
	for cohort in cohorts:
		var spec := {"id":cohort.id,"label":"Shadow reference build; correctness and balance inquiry","ranked_build":cohort.payload,"monster":"res://data/monsters/training_dummy.tres","monster_overrides":{"hp":100000000},"gear":["res://data/gear/crude_dagger.tres"],"gold":0,"duration_ms":30000,"seed_start":1,"seed_count":200}
		var result := Lab.run_scenario_spec(spec,registry)
		check(result.status=="pass","Lab "+cohort.id)
		SaveSystem.write_json(OUT+"/"+cohort.id+".json",result)
		if result.status=="pass":
			summary.append({"id":cohort.id,"dps":result.aggregate.dps,"physical_damage":result.aggregate.physical_damage,"poison_damage":result.aggregate.poison_damage,"payload":cohort.payload})
			print("%s mean DPS %.5f" % [cohort.id,result.aggregate.dps.mean])
		# A second identical seed independently checks the Lab/native contract and captures mechanics.
		var decoded := BuildSaveCodec.decode(cohort.payload,registry)
		var gear: Array[GearItem]=[load("res://data/gear/crude_dagger.tres")]
		var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],decoded.model,gear)
		var rotation: Array[Skill]=[]
		for id in cohort.payload.rotation_skill_ids:
			for s in content.skills:
				if s.id==id: rotation.append(s)
		var enemy: Monster=load("res://data/monsters/training_dummy.tres").duplicate(true)
		enemy.hp=100000000
		var traced := CombatResolver.resolve(rotation,content.stats,enemy,30000,1,true)
		var off := CombatResolver.resolve(rotation,content.stats,enemy,30000,1,false)
		check(traced.is_valid and traced.total_damage==off.total_damage and traced.rng_final_state==off.rng_final_state,"Trace parity "+cohort.id)
		var sources := {}
		var consumed := {"poison":0,"decay":0}
		var procs := 0
		for event in traced.cast_events:
			sources[event.skill.id]=float(sources.get(event.skill.id,0))+event.physical_damage
			if event.origin_kind=="proc": procs+=1
			for transaction in event.status_transactions:
				if transaction.get("keyword_consume",false):
					var status: String=transaction.get("status","")
					consumed[status]=int(consumed.get(status,0))+int(transaction.get("consumed",0))
		SaveSystem.write_json(OUT+"/"+cohort.id+"_diagnostic.json",{"seed":1,"direct_damage_by_skill":sources,"actual_consumed":consumed,"proc_casts":procs,"trace":traced.trace.records})
	SaveSystem.write_json(OUT+"/summary.json",{"passed":not failed,"scope":"Reference allocations and macro, not user reproduction or broad balance approval. 200 seeds per cohort; diagnostics seed 1.","cohorts":summary})
	quit(1 if failed else 0)
