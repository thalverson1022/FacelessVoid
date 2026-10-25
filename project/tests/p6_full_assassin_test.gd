extends SceneTree
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")
const Lab = preload("res://scripts/tools/balance_lab.gd")
const View = preload("res://scripts/ui/ranked_talent_view.gd")
const Passives = preload("res://scripts/systems/assassin_passives.gd")
const PURCHASES := [["talent.assassin.quick_hands",5],["talent.assassin.precision",5],["talent.assassin.hastened_poison",5],["talent.assassin.echoing_toxin",3],["talent.assassin.poison_strike",1],["talent.assassin.bypass",1],["talent.assassin.toxic_tradeoff",5],["talent.assassin.accelerant",5],["talent.assassin.resonance",4],["talent.assassin.critical_poison",1]]
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

static func full_ranks() -> Dictionary:
	var ranks := {}
	for pair in PURCHASES: ranks[pair[0]] = pair[1]
	return ranks

func build(ranks: Dictionary, reverse := false) -> RankedBuild:
	var b := RankedBuild.new()
	var assassin: SubclassTree = registry.trees["tree.assassin"]
	var blade: SubclassTree = registry.trees["tree.bladedancer"]
	check(b.configure(blade if reverse else assassin, assassin if reverse else blade,45,ranks),"Legal Assassin allocation")
	return b

func resolve(b: RankedBuild, gear: Array[GearItem] = []) -> Dictionary:
	var result := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], b, gear)
	check(result.error == "", "Actual allocated Assassin resolves")
	return result

func skill(content: Dictionary, id: String) -> Skill:
	for s in content.skills:
		if s.id == id: return s
	check(false, "Missing " + id)
	return null

func assert_stats(ranks: Dictionary, stats: PlayerStats, reverse := false) -> void:
	var points := 0
	for pair in PURCHASES: points += int(ranks.get(pair[0],0))
	check(stats.assassin_tree_points == points, "Powder counts investment in both roles")
	check(is_equal_approx(stats.bonus_base_elemental_damage,5 if reverse else 5+0.5*points),"Flat intrinsic role")
	check(is_equal_approx(stats.attack_speed,.01*int(ranks.get("talent.assassin.quick_hands",0))),"IAS rank")
	var base: PlayerStats = registry.classes["class.rogue"].base_stats
	check(is_equal_approx(stats.crit_chance,base.crit_chance+.01*int(ranks.get("talent.assassin.precision",0))),"Crit rank")
	for field in ["hastened_poison_rank","accelerant_rank","echoing_toxin_rank","resonance_rank"]:
		check(stats.get(field)==int(ranks.get("talent.assassin."+field.trim_suffix("_rank"),0)),"Rank binding "+field)
	check(stats.critical_poison_enabled == ranks.has("talent.assassin.critical_poison"),"Critical Poison binding")
	check(stats.bypass_enabled == ranks.has("talent.assassin.bypass"),"Bypass binding")
	var toxic: int = ranks.get("talent.assassin.toxic_tradeoff",0)
	check(is_equal_approx(stats.poison_tick_damage_multiplier,1+.1*toxic),"Poison-only factor")
	check(is_equal_approx(stats.physical_damage_multiplier,1-.1*toxic),"Physical penalty factor")
	check(is_equal_approx(stats.elemental_damage_multiplier,1),"Toxic does not change general elemental factor")

func allocation() -> void:
	var view := View.new()
	for talent in registry.trees["tree.assassin"].talents:
		for rank in range(talent.max_ranks+1):
			var ranks := full_ranks()
			if rank: ranks[talent.id] = rank
			else:
				ranks.erase(talent.id)
				if talent.id == "talent.assassin.hastened_poison": ranks.erase("talent.assassin.accelerant")
				if talent.id == "talent.assassin.echoing_toxin": ranks.erase("talent.assassin.resonance")
			for reverse in [false,true]: assert_stats(ranks,resolve(build(ranks,reverse)).stats,reverse)
			if rank: check(not "See skill effects" in view.effects(talent,rank),"Real rank text "+talent.id)
	view.free()
	var b := build({})
	check(not b.buy("talent.assassin.bypass"),"Early gate rejected")
	for pair in PURCHASES:
		for i in pair[1]:
			check(b.buy(pair[0]),"Incremental purchase "+pair[0])
			var content := resolve(b)
			var ids := []
			for item in content.skills: ids.append(item.id)
			for slot in [[1,"venom_jab"],[3,"blinding_powder"],[6,"virulent_poison"],[9,"master_of_poisons"],[12,"poison_vile"]]:
				check(ids.has("skill."+slot[1]) == (b.points_spent()>=slot[0]),"Unlock boundary")
	check(b.points_spent()==35 and resolve(b).skills.size()==9,"Full 35 ranks/six skills plus base three")
	check(not b.set_budget(34),"Budget rejected")
	check(not b.buy(PURCHASES[0][0]),"Rank six rejected")
	check(b.refund_tree("tree.assassin",true),"Reset all")
	assert_stats({},resolve(b).stats)
	b=build({"talent.assassin.quick_hands":5,"talent.assassin.hastened_poison":5})
	check(not b.refund("talent.assassin.quick_hands",true) and b.rank_of("talent.assassin.quick_hands")==5,"Lower tier protected atomically")
	for field in Passives.LIMITS:
		var invalid: SubclassTree = registry.trees["tree.assassin"].duplicate(true)
		invalid.talents[0].ranks[0].set(field,99)
		check(RankedBuild.content_error(invalid)!="","Malformed carrier rejected "+field)
	var no_pre := full_ranks()
	no_pre.erase("talent.assassin.hastened_poison")
	var invalid := RankedBuild.new()
	check(not invalid.configure(registry.trees["tree.assassin"],null,45,no_pre),"Accelerant requires Hastened")
	no_pre=full_ranks()
	no_pre.erase("talent.assassin.echoing_toxin")
	check(not invalid.configure(registry.trees["tree.assassin"],null,45,no_pre),"Resonance requires Echoing")

func boundaries() -> void:
	var content := resolve(build(full_ranks()))
	var stats: PlayerStats = content.stats.duplicate(true)
	stats.derivation_base=null
	stats.retrigger_chance=0
	stats.crit_chance=0
	stats.critical_poison_enabled=false
	var enemy := Monster.new()
	enemy.hp=1000000
	var venom := skill(content,"skill.venom_jab")
	check(venom.base_execution_ms==1000 and venom.min_execution_ms==500 and venom.cooldown_ms==0,"Venom descriptor")
	check(is_equal_approx(CombatResolver.weapon_scaling_for_skill(venom),.22),"Venom 22 percent")
	check(venom.effects[1].stacks_applied==5 and load("res://data/skills/venom_jab.tres").effects[1].stacks_applied==8,"New five stacks/legacy eight unchanged")
	for id in ["virulent_poison","master_of_poisons","poison_vile","blinding_powder","poison_strike"]:
		check(SkillTooltipFormatter.effect_summary(skill(content,"skill."+id))!="No effect","Skill description "+id)
	var strike := skill(content,"skill.poison_strike")
	check(strike.base_execution_ms==1200 and strike.min_execution_ms==500 and strike.effects.size()==2,"Reviewed forced tick descriptor")
	# Compare Poison-only factor on identical stat baselines; isolate hit and tick paths.
	var vile := skill(content,"skill.poison_vile")
	var rotation: Array[Skill] = [vile,strike]
	var normal: PlayerStats = stats.duplicate(true)
	normal.poison_tick_damage_multiplier=1
	for conversion in [false,true]:
		stats.special_effects["damage_conversion"]={"physical":conversion}
		normal.special_effects["damage_conversion"]={"physical":conversion}
		var doubled := CombatResolver.resolve(rotation,stats,enemy,8000,7,true)
		var plain := CombatResolver.resolve(rotation,normal,enemy,8000,7,true)
		check(doubled.is_valid and doubled.tick_events.size()==plain.tick_events.size(),"Conversion comparison valid")
		for i in doubled.tick_events.size():
			check(is_equal_approx(doubled.tick_events[i].raw_damage,1.5*plain.tick_events[i].raw_damage),"Toxic factor before conversion")
		for i in doubled.cast_events.size():
			check(doubled.cast_events[i].physical_damage==plain.cast_events[i].physical_damage,"Poison factor does not alter direct hits")
	stats.special_effects.erase("damage_conversion")
	var powder := skill(content,"skill.blinding_powder")
	check(powder.base_execution_ms==1200 and powder.min_execution_ms==500 and powder.cooldown_ms==0,"D013 Powder 1200/500 ms, no cooldown")
	var result := CombatResolver.resolve([powder],stats,enemy,1200,7,true)
	check(result.is_valid and result.cast_events[0].status_snapshot.defenses.absorb==-35,"Powder actual 35 points")
	# Live state derivation must preserve the separate factor and ignore it for Mastery.
	var state = preload("res://scripts/systems/combat_stat_state.gd").new(stats)
	check(state.snapshot().poison_tick_damage_multiplier==1.5,"Live state preserves Poison factor")

func integration() -> void:
	var ranks := full_ranks()
	ranks.merge(Core.RANKS)
	var reports := []
	for reverse in [false,true]:
		var b := build(ranks,reverse)
		var content := resolve(b)
		var rotation: Array[Skill] = []
		for id in ["virulent_poison","master_of_poisons","poison_vile","blinding_powder","stab","poison_strike","venom_jab"]:
			rotation.append(skill(content,"skill."+id))
		for seed_value in range(1,21):
			for mode in range(4):
				var enemy := Monster.new()
				enemy.hp=10000000
				enemy.armor=100
				if mode==1: enemy.dodge_chance=1
				if mode==2: enemy.cleanse_threshold=2
				if mode==3: enemy.crit_negation=1
				var a := CombatResolver.resolve(rotation,content.stats,enemy,20000,seed_value,true)
				var again := CombatResolver.resolve(rotation,content.stats,enemy,20000,seed_value,true)
				var off := CombatResolver.resolve(rotation,content.stats,enemy,20000,seed_value,false)
				check(a.is_valid and a.trace.records==again.trace.records and a.total_damage==off.total_damage and a.rng_final_state==off.rng_final_state,"Allocated deterministic cohort")
		var practice := TrainingRoomState.new()
		practice.content_registry=registry
		practice.set_class(registry.classes["class.rogue"])
		practice.configure_ranked_build(b.primary_tree(),b.secondary_tree())
		for pair in PURCHASES:
			for i in pair[1]: check(practice.select_talent(registry.talents[pair[0]]),"Practice real rank")
		for id in Core.RANKS:
			for i in Core.RANKS[id]: check(practice.select_talent(registry.talents[id]),"Practice partner")
		practice.set_rotation(rotation)
		var payload := BuildSaveCodec.encode(practice,registry)
		check(BuildSaveCodec.decode(payload,registry).error=="","Assassin persistence codec")
		for revision in ["p6.playable.thief.1","p6.playable.bladedancer.1","p6.playable.mixed.1","p6.playable.bladedancer_core.1"]:
			var old := preload("res://tests/fixtures/p6/mixed_build.gd").payload()
			old.content_revision=revision
			check(BuildSaveCodec.decode(old,registry).error=="","Prior revision accepted")
		var spec := {"id":"assassin_"+str(reverse),"label":"Assassin correctness","ranked_build":payload,"monster":"res://data/monsters/mouthy_drunk.tres","monster_overrides":{"hp":1000000},"gear":[],"duration_ms":30000,"seed_start":1,"seed_count":20}
		var first := Lab.run_scenario_spec(spec,registry)
		var second := Lab.run_scenario_spec(spec,registry)
		check(first.status=="pass" and first.samples==second.samples and first.aggregate==second.aggregate,"Lab role repeatability")
		reports.append(first)
	DirAccess.make_dir_recursive_absolute("res://reports/p6_m5_t7")
	SaveSystem.write_json("res://reports/p6_m5_t7/lab.json",{"scope":"Correctness; balance M6","scenarios":reports})

func _run() -> void:
	registry=BuildContentRegistry.test_mode()
	check(registry.error=="" and registry.talents.size()==44,"Four complete trees")
	if registry.error!="":
		printerr(registry.error)
		quit(1)
		return
	allocation()
	boundaries()
	integration()
	print("Full Assassin: %d checks %s" % [checks,"FAIL" if failed else "PASS"])
	quit(1 if failed else 0)
