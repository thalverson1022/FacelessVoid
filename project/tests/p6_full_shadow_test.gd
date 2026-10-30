extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
const View = preload("res://scripts/ui/ranked_talent_view.gd")
const StatState = preload("res://scripts/systems/combat_stat_state.gd")
const PURCHASES := [["talent.shadow.coated_weapons",1],["talent.shadow.blind_spot",5],["talent.shadow.snake_oil",4],["talent.shadow.deception",5],["talent.shadow.death_from_the_shadows",5],["talent.shadow.death_pact",3],["talent.shadow.death_touch",3],["talent.shadow.shadow_mastery",5],["talent.shadow.dusk_strike",1],["talent.shadow.death_blade",2],["talent.umbral_pressure",1]]
const PARTNERS := {
	"tree.bladedancer": {"talent.bladedancer.wet_stone":4,"talent.bladedancer.rending_slash":1,"talent.bladedancer.fancy_footwork":5},
	"tree.thief": {"talent.keen_eye":5,"talent.sticky_fingers":5},
	"tree.assassin": {"talent.assassin.quick_hands":5,"talent.assassin.precision":5},
}
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
	for pair in PURCHASES: ranks[pair[0]]=pair[1]
	return ranks
func build(ranks: Dictionary, reverse := false, partner := "tree.bladedancer") -> RankedBuild:
	var b := RankedBuild.new()
	check(b.configure(registry.trees[partner] if reverse else registry.trees["tree.shadow"],registry.trees["tree.shadow"] if reverse else registry.trees[partner],45,ranks),"Legal Shadow build")
	return b
func resolve(b: RankedBuild) -> Dictionary:
	var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
	var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],b,gear)
	check(content.error=="","Allocated build resolves")
	return content
func skill(content: Dictionary, id: String) -> Skill:
	for s in content.skills:
		if s.id==id: return s
	check(false,"Missing skill "+id)
	return null
func rank(ranks: Dictionary, name: String) -> int:
	return int(ranks.get("talent.shadow."+name,0))
func assert_stats(ranks: Dictionary, stats: PlayerStats, reverse: bool) -> void:
	var points := 0
	for pair in PURCHASES: points+=int(ranks.get(pair[0],0))
	check(is_equal_approx(stats.elemental_proc_chance,.2 if reverse else .2+.02*points),"Intrinsic role/investment")
	var base: PlayerStats = registry.classes["class.rogue"].base_stats
	check(is_equal_approx(stats.crit_chance,base.crit_chance+.02*rank(ranks,"blind_spot")),"Blind Spot")
	check(is_equal_approx(stats.crit_multiplier,base.crit_multiplier+.2*rank(ranks,"death_from_the_shadows")),"Crit damage")
	check(is_equal_approx(stats.bonus_base_elemental_damage,2*rank(ranks,"snake_oil")),"Snake Oil")
	check(is_equal_approx(stats.elemental_damage_multiplier,1+.1*rank(ranks,"deception")),"Deception")
	check(is_equal_approx(stats.bonus_physical_damage,2*rank(ranks,"snake_oil")*.1*rank(ranks,"shadow_mastery")),"Mastery flat copy")
	check(is_equal_approx(stats.derived_physical_multiplier,1+.1*rank(ranks,"deception")*.1*rank(ranks,"shadow_mastery")),"Mastery percentage copy")
	check(stats.death_pact_rank==rank(ranks,"death_pact"),"Pact binding")
	check(is_equal_approx(stats.death_blade_chance,.4*rank(ranks,"death_blade")),"Death Blade chance")
	check(stats.death_blade_enabled==(rank(ranks,"death_blade")>0),"Death Blade enable")
	check(stats.shred_value==base.shred_value+10*rank(ranks,"dusk_strike"),"Dusk Shred effectiveness")
	check(stats.independent_decay_shred==(rank(ranks,"dusk_strike")>0),"Dusk independent grant")
	check(stats.poison_stack_cap==(80 if ranks.has("talent.umbral_pressure") else base.poison_stack_cap),"Umbral cap")
	for field in ["bonus_poison_stacks","bonus_decay_stacks","bonus_shred_stacks","bonus_potency_stacks","bonus_penetration_stacks","bonus_bypass_stacks","bonus_footwork_stacks"]:
		check(stats.get(field)==3*rank(ranks,"death_touch"),"Death Touch "+field)
func allocation() -> void:
	for reverse in [false,true]:
		var b := build({},reverse)
		var ranks := {}
		assert_stats(ranks,resolve(b).stats,reverse)
		check(not b.buy("talent.shadow.shadow_mastery"),"Gate rejects early purchase")
		for pair in PURCHASES:
			for i in pair[1]:
				check(b.buy(pair[0]),"Buy each rank "+pair[0])
				ranks[pair[0]]=i+1
				var content := resolve(b)
				assert_stats(ranks,content.stats,reverse)
				var live = StatState.new(content.stats).snapshot()
				assert_stats(ranks,live,reverse)
				for slot in [[1,"toxic_flurry"],[3,"killers_mark"],[6,"distilled_corruption"],[9,"touch_of_darkness"],[12,"beguiling_presence"]]:
					var found := false
					for s in content.skills:
						if s.id=="skill."+slot[1]: found=true
					check(found==(b.points_spent()>=slot[0]),"Unlock boundary")
				check(not "See skill effects" in View.effects(registry.talents[pair[0]],i+1),"Explicit rank description")
		check(b.points_spent()==35 and resolve(b).skills.size()==8,"Full inventory")
		check(not b.set_budget(34) and not b.buy(PURCHASES[0][0]),"Over-budget and max-rank rejected")
		var reverse_purchases := PURCHASES.duplicate()
		reverse_purchases.reverse()
		for pair in reverse_purchases:
			for i in pair[1]:
				check(b.refund(pair[0],true),"Refund each rank")
				var remaining: int=int(ranks[pair[0]])-1
				if remaining>0: ranks[pair[0]]=remaining
				else: ranks.erase(pair[0])
				assert_stats(ranks,resolve(b).stats,reverse)
		b=build(full_ranks(),reverse)
		check(b.refund_tree("tree.shadow",true),"Reset")
		assert_stats({},resolve(b).stats,reverse)
	for field in preload("res://scripts/systems/shadow_passives.gd").LIMITS:
		var tree: SubclassTree = registry.trees["tree.shadow"].duplicate(true)
		tree.talents[0].ranks[0].set(field,99)
		check(RankedBuild.content_error(tree)!="","Malformed carrier rejected")
	for pair in [["deception","snake_oil"],["shadow_mastery","deception"],["death_blade","coated_weapons"]]:
		var invalid := full_ranks()
		invalid.erase("talent.shadow."+pair[1])
		var b := RankedBuild.new()
		check(not b.configure(registry.trees["tree.shadow"],null,45,invalid),"Prerequisite enforced "+pair[0])
func coated_weapons_balance() -> void:
	var model := RankedBuild.new()
	check(model.configure(registry.trees["tree.shadow"],null,10,{"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.deception":5}),"D019 ten-point baseline is legal")
	var content := resolve(model)
	check(View.effects(registry.talents["talent.shadow.coated_weapons"],1).contains("2 base Poison"),"Coated tooltip reports live two-stack value")
	var stats: PlayerStats = content.stats.duplicate(true)
	stats.derivation_base = null
	stats.crit_chance = 0
	stats.elemental_proc_chance = 0
	stats.retrigger_chance = 0
	var enemy := Monster.new()
	enemy.hp = 10000000
	for id in ["skill.stab","skill.heavy_slash"]:
		var attack := skill(content,id)
		check(attack.poison_stacks_applied == 2,"Coated augments " + id)
		stats.bonus_poison_stacks = 0
		stats.special_effects["double_applied_stacks"] = false
		var result := CombatResolver.resolve([attack],stats,enemy,attack.base_execution_ms,7)
		check(result.is_valid and result.cast_events[0].poison_stacks_applied == 2,"Connected attack applies two base Poison " + id)
		stats.bonus_poison_stacks = 6
		result = CombatResolver.resolve([attack],stats,enemy,attack.base_execution_ms,7)
		check(result.cast_events[0].poison_stacks_applied == 8,"Stack extras apply once after two base " + id)
		stats.special_effects["double_applied_stacks"] = true
		result = CombatResolver.resolve([attack],stats,enemy,attack.base_execution_ms,7)
		check(result.cast_events[0].poison_stacks_applied == 16,"Doubling applies after stack extras " + id)
func boundaries() -> void:
	var content := resolve(build(full_ranks()))
	for spec in [["toxic_flurry",1700,650,.22],["killers_mark",1500,650,1.11],["distilled_corruption",1500,650,1.0],["touch_of_darkness",500,500,0],["beguiling_presence",500,500,0]]:
		var s := skill(content,"skill."+spec[0])
		check(s.base_execution_ms==spec[1] and s.min_execution_ms==spec[2],"Approved timing")
		check(s.cooldown_ms==(30000 if s.category==Skill.Category.SELF_BUFF else 0),"Approved cooldown")
		check(is_equal_approx(CombatResolver.weapon_scaling_for_skill(s),spec[3]),"Approved scaling "+spec[0])
		check(SkillTooltipFormatter.effect_summary(s)!="No effect","Skill summary")
	var stats: PlayerStats = content.stats.duplicate(true)
	stats.derivation_base=null
	stats.crit_chance=0
	stats.retrigger_chance=0
	stats.elemental_proc_chance=0
	stats.death_blade_enabled=false
	stats.weapon_damage_min=100
	stats.weapon_damage_max=100
	stats.poison_tick_interval_multiplier=100
	var enemy := Monster.new()
	enemy.hp=10000000
	var death := skill(content,"skill.killers_mark")
	for effect in death.effects:
		if effect is StackScalingPhysicalDamageEffect: check(effect.damage_per_stack == 2,"Promoted Death Strike tooltip carrier matches live scaling")
	var result := CombatResolver.resolve([death],stats,enemy,1500,7,true)
	check(result.is_valid and result.cast_events.size()==1 and result.cast_events[0].physical_damage==144,"Death Strike single packet with full-tree Mastery: 104*1.11*1.25")
	var beguiling := skill(content,"skill.toxic_flurry")
	var distilled := skill(content,"skill.distilled_corruption")
	result=CombatResolver.resolve([beguiling,distilled],stats,enemy,3200,7,true)
	check(result.is_valid and result.cast_events.size()==2,"Allocated Distilled sequence")
	check(result.cast_events[0].decay_stacks_applied==10 and result.cast_events[0].shred_stacks_applied==10,"Allocated Death Touch/Dusk independent applications")
	check(result.cast_events[1].poison_stacks_applied==14,"Distilled consumes five then adds nine Poison extras")
	check(result.cast_events[1].status_snapshot.defenses.block==-5 and result.cast_events[1].status_snapshot.defenses.absorb==-5,"Pact uses actual five, not bonus stacks")
	for dodge in [false,true]:
		enemy.dodge_chance=1 if dodge else 0
		var empty := CombatResolver.resolve([distilled],stats,enemy,1500,7,true)
		check(empty.is_valid and empty.cast_events[0].poison_stacks_applied==0,"No fuel or dodge creates no Poison")
		check((empty.total_damage==0)==dodge,"No fuel still hits; dodge prevents damage")
func integration() -> void:
	for partner in PARTNERS:
		for reverse in [false,true]:
			var ranks := full_ranks()
			ranks.merge(PARTNERS[partner])
			var b := build(ranks,reverse,partner)
			var content := resolve(b)
			var rotation: Array[Skill] = []
			for id in ["toxic_flurry","distilled_corruption","beguiling_presence","touch_of_darkness","stab","killers_mark"]: rotation.append(skill(content,"skill."+id))
			for seed_value in range(1,21):
				for mode in range(4):
					var enemy := Monster.new()
					enemy.hp=10000000
					if mode==1: enemy.dodge_chance=1
					if mode==2: enemy.cleanse_threshold=2
					if mode==3: enemy.crit_negation=1
					var a := CombatResolver.resolve(rotation,content.stats,enemy,20000,seed_value,true)
					var replay := CombatResolver.resolve(rotation,content.stats,enemy,20000,seed_value,true)
					var off := CombatResolver.resolve(rotation,content.stats,enemy,20000,seed_value,false)
					check(a.is_valid and a.trace.records==replay.trace.records and a.total_damage==off.total_damage and a.rng_final_state==off.rng_final_state,"Mixed deterministic replay "+partner)
			var payload := {"build_schema_version":1,"content_revision":registry.revision,"allocation_mode":"ranked","class_id":"class.rogue","primary_tree_id":b.primary_tree().id,"secondary_tree_id":b.secondary_tree().id,"earned_talent_points":45,"talent_ranks":ranks,"rotation_skill_ids":[]}
			for s in rotation: payload.rotation_skill_ids.append(s.id)
			check(BuildSaveCodec.decode(payload,registry).error=="","Full mixed save round trip")
func _run() -> void:
	registry=BuildContentRegistry.test_mode()
	check(registry.error=="" and registry.talents.size()==44,"Four complete trees")
	if registry.error!="":
		printerr(registry.error)
		quit(1)
		return
	allocation()
	coated_weapons_balance()
	boundaries()
	integration()
	print("Full Shadow: %d checks %s" % [checks,"FAIL" if failed else "PASS"])
	quit(1 if failed else 0)
