extends SceneTree
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")
const Gold = preload("res://scripts/systems/combat_gold.gd")
const Lab = preload("res://scripts/tools/balance_lab.gd")
const View = preload("res://scripts/ui/ranked_talent_view.gd")
const PURCHASES := [["talent.keen_eye",5],["talent.sticky_fingers",5],["talent.thief.fast_hands",5],["talent.thief.fill_your_pockets",5],["talent.thief.charisma",3],["talent.thief.bribery",3],["talent.thief.silvered_edge",3],["talent.thief.finders_keepers",2],["talent.thief.load_dice",3],["talent.gilded_blade",1]]
var registry: BuildContentRegistry
var failed := false
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAILED: "+label)

static func full_ranks() -> Dictionary:
	var ranks := {}
	for pair in PURCHASES: ranks[pair[0]] = pair[1]
	return ranks

func build(ranks: Dictionary, reverse := false, mixed := false) -> RankedBuild:
	var b := RankedBuild.new()
	var thief: SubclassTree = registry.trees["tree.thief"]
	var blade: SubclassTree = registry.trees["tree.bladedancer"]
	check(b.configure(blade if reverse else thief, thief if reverse else blade if mixed else null,45,ranks),"Legal Thief allocation")
	return b

func resolve(b: RankedBuild, stash := 0, gear: Array[GearItem] = []) -> Dictionary:
	var r := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],b,gear,stash)
	check(r.error=="","Actual Thief resolves")
	return r

func skill(content: Dictionary, id: String) -> Skill:
	for s in content.skills:
		if s.id==id: return s
	check(false,"Missing "+id)
	return null

func assert_stats(ranks: Dictionary, stats: PlayerStats, reverse := false) -> void:
	var points := 0
	for pair in PURCHASES: points += int(ranks.get(pair[0],0))
	var gold := (1.1+(0.0 if reverse else .02*points))*(1+.1*int(ranks.get("talent.sticky_fingers",0)))
	check(is_equal_approx(stats.gold_reward_multiplier,gold),"Multiplicative Sticky/intrinsic")
	check(is_equal_approx(stats.attack_speed,(gold-1)*.1*int(ranks.get("talent.thief.fast_hands",0))),"Fast Hands final gold bonus")
	var mf := float(ranks.get("talent.thief.load_dice",0))
	check(is_equal_approx(stats.magic_find,mf),"Loaded Dice exact rank")
	check(is_equal_approx(stats.shop_discount,.1*int(ranks.get("talent.thief.charisma",0))),"Charisma exact rank")
	var keen := 1+.02*int(ranks.get("talent.keen_eye",0))
	check(is_equal_approx(stats.physical_damage_multiplier,keen),"Keen physical rank")
	check(is_equal_approx(stats.elemental_damage_multiplier,keen*(1+mf*.2*int(ranks.get("talent.thief.fill_your_pockets",0)))),"Fill separate elemental factor")
	check(stats.bribery_base_stacks==2*int(ranks.get("talent.thief.bribery",0)),"Bribery bound")
	check(stats.finders_keepers_rank==int(ranks.get("talent.thief.finders_keepers",0)),"Finders bound")
	check(stats.silvered_edge_rank==int(ranks.get("talent.thief.silvered_edge",0)),"Silvered bound")
	check(stats.gilded_blade_enabled==(int(ranks.get("talent.gilded_blade",0))==1),"Gilded bound")

func ranks_and_edits() -> void:
	var view := View.new()
	for talent in registry.trees["tree.thief"].talents:
		for rank in range(talent.max_ranks+1):
			var ranks := full_ranks()
			if rank: ranks[talent.id]=rank
			else:
				ranks.erase(talent.id)
				if talent.id=="talent.thief.charisma": ranks.erase("talent.thief.load_dice")
			var b := build(ranks)
			assert_stats(ranks,resolve(b).stats)
			assert_stats(ranks,resolve(build(ranks,true)).stats,true)
			if rank:
				check(not "See skill effects" in view.effects(talent,rank),"Meaningful rank text "+talent.id)
				check(b.refund(talent.id,true)==(rank>1 or talent.id!="talent.thief.charisma" or not ranks.has("talent.thief.load_dice")),"Atomic prerequisite-aware refund")
				if b.rank_of(talent.id)==rank-1:
					check(b.buy(talent.id),"Rebuy restores rank")
					assert_stats(ranks,resolve(b).stats)
			if rank==talent.max_ranks: check(not b.buy(talent.id),"Max+1 rejected")
	view.free()
	var b := build({})
	check(not b.buy("talent.thief.load_dice"),"Gate prevents early cap-tier buy")
	for pair in PURCHASES:
		for i in pair[1]:
			check(b.buy(pair[0]),"Legal incremental purchase")
			var count := b.points_spent()
			var content := resolve(b)
			var ids := []
			for item in content.skills: ids.append(item.id)
			for slot in [[1,"skill.steal"],[3,"skill.mug"],[6,"skill.pick_pocket"],[12,"skill.big_score"]]:
				check(ids.has(slot[1])==(count>=slot[0]),"Threshold including empty nine")
	check(b.points_spent()==35 and resolve(b).skills.size()==7,"Full 35 ranks and four plus three class skills")
	check(not b.set_budget(34),"Budget rejection")
	check(b.refund_tree("tree.thief",true),"Full reset")
	assert_stats({},resolve(b).stats)
	for field in ["bribery_base_stacks","finders_keepers_rank","silvered_edge_rank"]:
		var invalid: SubclassTree = registry.trees["tree.thief"].duplicate(true)
		invalid.talents[0].ranks[0].set(field,99)
		check(RankedBuild.content_error(invalid)!="","Invalid passive rejected "+field)

func combat_and_lab() -> void:
	var ranks := full_ranks()
	ranks.merge(Core.RANKS)
	var reports := []
	for reverse in [false,true]:
		var b := build(ranks,reverse,true)
		var content := resolve(b,499)
		var stats: PlayerStats = content.stats
		assert_stats(ranks,stats,reverse)
		var pick := skill(content,"skill.pick_pocket")
		var rotation: Array[Skill] = [pick,skill(content,"skill.steal"),skill(content,"skill.mug"),skill(content,"skill.big_score"),skill(content,"skill.quick_cut"),skill(content,"skill.parry_strike")]
		for seed_value in range(1,21):
			for mode in range(4):
				var enemy := Monster.new()
				enemy.hp=10000000
				enemy.armor=600
				enemy.block=40
				if mode==1: enemy.dodge_chance=1.0
				if mode==2: enemy.cleanse_threshold=2
				if mode==3: enemy.crit_negation=1.0
				var a := CombatResolver.resolve(rotation,stats,enemy,20000,seed_value,true)
				var again := CombatResolver.resolve(rotation,stats,enemy,20000,seed_value,true)
				var off := CombatResolver.resolve(rotation,stats,enemy,20000,seed_value,false)
				check(a.is_valid and a.trace.records==again.trace.records and a.total_damage==off.total_damage and a.rng_final_state==off.rng_final_state,"Deterministic allocated Thief cohort")
				var first = a.cast_events[0]
				check(first.gold_stolen==floori(10*stats.gold_reward_multiplier) and first.physical_damage==0 and not first.was_dodged,"Actual Pick Pocket credit/category")
				check(first.shred_stacks_applied==6 and first.status_snapshot.defenses.block==0,"Allocated Bribery/Finders")
				check(enemy.block==40 and stats.current_gold==499,"Immutable inputs")
		var values := Gold.crit_values(stats,501,120)
		check(values.gilded_crit_bonus==5.0 and values.silvered_crit_bonus==.75,"Allocated source caps")
		var state := TrainingRoomState.new()
		state.content_registry=registry
		state.practice_save_path="res://reports/p6_m5_t6/practice.json"
		state.set_class(registry.classes["class.rogue"])
		state.configure_ranked_build(b.primary_tree(),b.secondary_tree())
		for pair in PURCHASES:
			for i in pair[1]: state.select_talent(registry.talents[pair[0]])
		for id in Core.RANKS:
			for i in Core.RANKS[id]: state.select_talent(registry.talents[id])
		state.set_rotation(rotation)
		var payload := BuildSaveCodec.encode(state,registry)
		check(BuildSaveCodec.decode(payload,registry).error=="","Full mixed save codec")
		for revision in ["p6.playable.bladedancer.1","p6.playable.mixed.1","p6.playable.bladedancer_core.1"]:
			var old := preload("res://tests/fixtures/p6/mixed_build.gd").payload()
			old.content_revision=revision
			check(BuildSaveCodec.decode(old,registry).error=="","Old revision remains accepted")
		var spec := {"id":"full_thief_"+str(reverse),"label":"Approved Thief correctness", "ranked_build":payload,"monster":"res://data/monsters/mouthy_drunk.tres","monster_overrides":{"hp":1000000,"block":40,"armor":600},"gear":[],"duration_ms":30000,"seed_start":1,"seed_count":20}
		var first := Lab.run_scenario_spec(spec,registry)
		var second := Lab.run_scenario_spec(spec,registry)
		check(first.status=="pass" and first.samples==second.samples and first.aggregate==second.aggregate,"Actual Lab role repeatability")
		reports.append(first)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/p6_m5_t6"))
	check(SaveSystem.write_json("res://reports/p6_m5_t6/lab.json",{"scope":"Correctness; balance remains M6","scenarios":reports}),"Lab evidence written")

func composition() -> void:
	var mixed = preload("res://tests/fixtures/p6/mixed_build.gd")
	var gear := GearItem.new()
	gear.id="gear.test.thief.composition"
	gear.affixes.append(mixed.modifier(StatCatalog.INCREASED_GOLD,.2))
	gear.affixes.append(mixed.modifier(StatCatalog.INCREASED_MAGIC_FIND,1.0))
	for reverse in [false,true]:
		var content := resolve(build(full_ranks(),reverse),499,[gear])
		var expected := (1.1 if reverse else 1.8)*1.5*1.2
		check(is_equal_approx(content.stats.gold_reward_multiplier,expected),"Three distinct gold buckets")
		check(is_equal_approx(content.stats.attack_speed,(expected-1)*.5),"Fast Hands includes gear gold")
		check(is_equal_approx(content.stats.elemental_damage_multiplier,1.1*5),"Fill includes gear Magic Find")
	# Legal 45-point fixture: Blade capstone 21 plus Thief 24.
	var ranks := {"talent.bladedancer.weakness":5,"talent.bladedancer.wet_stone":5,"talent.bladedancer.rending_slash":1,"talent.bladedancer.fancy_footwork":5,"talent.bladedancer.precision_attacks":1,"talent.bladedancer.double_dip":2,"talent.bladedancer.opportunity":1,"talent.bladedancer.virulent_corruption":1,"talent.keen_eye":5,"talent.sticky_fingers":5,"talent.thief.fast_hands":5,"talent.thief.charisma":3,"talent.thief.bribery":3,"talent.thief.finders_keepers":2,"talent.gilded_blade":1}
	var b := build(ranks,false,true)
	check(b.points_spent()==45,"Legal capstone cross-tree budget")
	var content := resolve(b)
	var target := Monster.new()
	target.hp=1000000
	target.armor=5000
	target.block=40
	var pocket := skill(content,"skill.pick_pocket")
	var result := CombatResolver.resolve([pocket],content.stats,target,2000,7,true)
	check(result.cast_events[0].shred_stacks_applied==8 and result.cast_events[0].shred_value==135 and result.cast_events[0].armor_reduction_applied==1080,"Allocated Bribery plus Weakness/Virulent")
	gear.affixes.clear()
	gear.affixes.append(mixed.modifier(StatCatalog.INCREASED_ALL_STACKS,1))
	gear.affixes.append(mixed.modifier("double_applied_stacks",1))
	content=resolve(b,0,[gear])
	result=CombatResolver.resolve([pocket],content.stats,target,2000,7,true)
	check(result.cast_events[0].shred_stacks_applied==18 and result.cast_events[0].armor_reduction_applied==2430,"Allocated stack bonuses then gear doubling")

func _run() -> void:
	registry=BuildContentRegistry.test_mode()
	check(registry.error=="" and registry.talents.size()==44,"Four complete playable trees")
	if registry.error!="":
		printerr(registry.error)
		quit(1)
		return
	ranks_and_edits()
	composition()
	combat_and_lab()
	print("Full Thief: %d checks %s" % [checks,"FAIL" if failed else "PASS"])
	quit(1 if failed else 0)
