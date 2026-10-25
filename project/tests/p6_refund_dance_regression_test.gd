extends SceneTree
const Contracts = preload("res://scripts/systems/p6_thief_contracts.gd")
var failed := false
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok:
		failed=true
		printerr("FAILED: "+label)
func _run() -> void:
	var registry := BuildContentRegistry.test_mode()
	var thief: SubclassTree = registry.trees["tree.thief"]
	var blade: SubclassTree = registry.trees["tree.bladedancer"]
	for reverse in [false,true]:
		var model := RankedBuild.new()
		check(model.configure(blade if reverse else thief,thief if reverse else blade,45),"Both tree roles")
		for i in 5: check(model.buy("talent.keen_eye"),"Buy five tier-one points")
		for i in 5: check(model.buy("talent.thief.fast_hands"),"Buy five tier-two points")
		var before := model.rank_map()
		for i in 5:
			check(not model.refund("talent.keen_eye",true) and model.rank_map()==before,"Supporting lower-tier refund blocked atomically")
		check(model.last_error.contains("lower tiers"),"Explain blocked dependency")
		for i in 5: check(model.refund("talent.thief.fast_hands",true),"Upper ranks remain refundable")
		for i in 5: check(model.refund("talent.keen_eye",true),"Lower ranks refundable once upper cleared")
		check(not model.configure(thief,blade,45,{"talent.thief.fast_hands":5,"talent.thief.fill_your_pockets":5}),"Peers cannot support each other")
		check(model.points_spent()==0,"Invalid restored allocation rejected atomically")
		check(model.configure(thief,blade,45,before) and model.refund_tree("tree.thief",true),"Full tree reset allowed")
		check(model.configure(thief,blade,45,before) and model.refund_all(true),"Full reset allowed")
	# Actual Dance descriptor, repeated cooldown attempts before/after its expiry.
	var dance: Skill = Contracts.skill("dance_of_death")
	var hit := Skill.new()
	hit.id="test.plain_attack"
	hit.base_execution_ms=1000
	hit.min_execution_ms=1000
	var damage := PhysicalDamageEffect.new()
	damage.amount=1
	hit.effects.append(damage)
	var stats := PlayerStats.new()
	stats.weapon_damage_min=100
	stats.weapon_damage_max=100
	stats.dance_duration_ms=dance.dance_duration_ms
	stats.retrigger_chance=0.0
	var target := Monster.new()
	target.hp=1000000
	var result := CombatResolver.resolve([dance,dance,hit],stats,target,19000,7,true)
	check(result.is_valid,"Dance scenario valid")
	var skipped := 0
	var post_expiry := 0
	var guarantees := 0
	for event in result.cast_events:
		if event.cooldown_blocked:
			skipped+=1
			check(event.time_ms-event.cast_start_ms==100 and event.physical_damage==0,"Cooldown attempts spend 100ms without effects")
		if event.origin_kind=="guaranteed_repeat":
			guarantees+=1
			check(event.cast_start_ms<6500,"No guarantee from Dance cooldown skips after expiry")
		if event.skill==hit and event.origin_kind=="macro" and event.cast_start_ms>=5500:
			post_expiry+=1
			check(event.lifecycle_snapshot.get("guaranteed_repeat_sources",[]).is_empty(),"Expired Dance cannot guarantee later attacks")
	check(skipped>10 and post_expiry>5 and guarantees>0,"Exercises active buff and many expired cooldown skips")
	var grants := 0
	for row in result.trace.records:
		if row.kind=="effect_lifecycle" and row.source_id==dance.id and row.lifecycle_reason=="granted": grants+=1
	check(grants==1,"Cooldown skips never refresh or regrant Dance")
	check(stats.retrigger_chance==0,"Dance leaves numeric retrigger chance unchanged")
	var off := CombatResolver.resolve([dance,dance,hit],stats,target,19000,7,false)
	check(off.total_damage==result.total_damage and off.rng_final_state==result.rng_final_state,"Trace-neutral deterministic outcomes")
	print("Refund and Dance regressions: "+("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
