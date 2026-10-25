extends "res://tests/p6_full_assassin_test.gd"
const State = preload("res://scripts/systems/combat_stat_state.gd")
const Cadence = preload("res://scripts/systems/poison_cadence.gd")

func _initialize() -> void:
	super._initialize()

func _run() -> void:
	registry=BuildContentRegistry.test_mode()
	var enemy := Monster.new()
	enemy.hp=1000000
	# Exercise all approved Toxic ranks with actually allocated Poison passives,
	# partial/empty fuel, natural/forced origins, Virulent and current critical stats.
	for rank in range(6):
		print("T7 boundary rank ",rank)
		var ranks := full_ranks()
		if rank: ranks["talent.assassin.toxic_tradeoff"]=rank
		else: ranks.erase("talent.assassin.toxic_tradeoff")
		var allocated := resolve(build(ranks))
		var stats: PlayerStats = allocated.stats.duplicate(true)
		stats.derivation_base=null
		stats.crit_chance=1
		stats.crit_multiplier=3
		for fuel in range(5):
			for forced in [false,true]:
				var result := CombatResolver.CombatResult.new()
				result.combat_rng=RandomNumberGenerator.new()
				result.combat_rng.seed=7
				result.self_buffs.grant("virulent_poison",0,{"source_id":"test.one"})
				result.self_buffs.grant("virulent_poison",0,{"source_id":"test.two"})
				var before := result.combat_rng.state
				CombatResolver._resolve_poison_tick(result,1000,fuel,stats,0,0,enemy,1000,forced)
				var tick = result.tick_events[0]
				var expected := stats.poison_damage_per_tick * mini(3,fuel) * 1.2 * (1+.1*rank) * 4
				check(is_equal_approx(tick.raw_damage,expected),"Actual rank/fuel multipliers")
				check(tick.damage==roundf(expected*3),"One critical packet after factors")
				check(tick.stacks_consumed==mini(3,fuel),"Three replaces two")
				check(tick.charge_spends.size()==(2 if fuel else 0),"Independent charges")
				check((result.combat_rng.state==before)==(fuel==0),"Only fueled ticks roll crit")
	print("T7 boundary source rebuilds")
	# The new factor survives source rebuilds, and never enters Shadow Mastery's input.
	var content := build(full_ranks()).resolved_content()
	var mastery := Talent.new()
	mastery.id="test.shadow_mastery"
	var rule := preload("res://scripts/resources/stat_derivation_rule.gd").new()
	rule.kind="shadow_mastery"
	rule.fraction=.5
	mastery.stat_derivations=[rule]
	var selected: Array[Talent]=content.talents
	selected.append(mastery)
	var stats := BuildResolver.resolve_stats(registry.classes["class.rogue"],content.trees,selected)
	check(stats.derived_physical_multiplier==1 and stats.poison_tick_damage_multiplier==1.5,"Poison factor excluded from Mastery")
	var state := State.new(stats)
	var modifier := StatModifier.new()
	modifier.stat_id=StatCatalog.PERCENT_ELEMENTAL_DAMAGE
	modifier.value=1
	check(state.replace_source("test.elemental","test.buff",[modifier],1)=="","Temporary source accepted")
	check(state.snapshot().derived_physical_multiplier==1.5 and state.snapshot().poison_tick_damage_multiplier==1.5,"Only true elemental bonus copied")
	check(state.remove_source("test.elemental",2)=="" and state.snapshot().poison_tick_damage_multiplier==1.5,"Source expiry retains Toxic factor")
	# Powder points survive a Bypass-triggered live stat rebuild.
	var actual := resolve(build(full_ranks()))
	var live := State.new(actual.stats)
	check(live.snapshot().assassin_tree_points==35,"Actual baseline keeps Powder points")
	check(live.replace_source("test.bypass","talent.assassin.bypass",[modifier],1)=="" and live.snapshot().assassin_tree_points==35,"Rebuild keeps Powder points")
	print("T7 boundary gear")
	# Stack gear and immunity composition use the actual production descriptors.
	var gear := GearItem.new()
	var extra := StatModifier.new()
	extra.stat_id=StatCatalog.INCREASED_ALL_STACKS
	extra.value=2
	var double := StatModifier.new()
	double.stat_id="double_applied_stacks"
	double.value=1
	gear.affixes=[extra,double]
	var geared := resolve(build(full_ranks()),[gear])
	var rotation: Array[Skill]=[skill(geared,"skill.venom_jab"),skill(geared,"skill.blinding_powder")]
	var result := CombatResolver.resolve(rotation,geared.stats,enemy,2500,7,true)
	check(result.cast_events[0].poison_stacks_applied==14,"Venom bonuses then doubling")
	check(result.cast_events[1].status_snapshot.defenses.absorb==-50,"Powder bonuses then doubling then 50-stack cap")
	var cadence: PlayerStats=actual.stats.duplicate(true)
	cadence.attack_speed=1
	check(Cadence.interval(cadence,0)==600,"Both rank-five cadence inputs use 100 percent IAS")
	print("T7 boundary mixed")
	# Actual legal Thief 24 / Assassin 21 pairing, both roles; live gold/Poison crit.
	var mixed_ranks := {"talent.assassin.quick_hands":5,"talent.assassin.precision":5,"talent.assassin.echoing_toxin":3,"talent.assassin.poison_strike":1,"talent.assassin.bypass":1,"talent.assassin.resonance":4,"talent.assassin.hastened_poison":1,"talent.assassin.critical_poison":1,"talent.keen_eye":5,"talent.sticky_fingers":5,"talent.thief.fast_hands":5,"talent.thief.bribery":3,"talent.thief.silvered_edge":3,"talent.thief.finders_keepers":2,"talent.gilded_blade":1}
	for reverse in [false,true]:
		var b := RankedBuild.new()
		check(b.configure(registry.trees["tree.thief" if reverse else "tree.assassin"],registry.trees["tree.assassin" if reverse else "tree.thief"],45,mixed_ranks),"Legal full-budget gold/Poison build")
		var resolved := resolve(b)
		var macro: Array[Skill]=[skill(resolved,"skill.poison_vile"),skill(resolved,"skill.pick_pocket"),skill(resolved,"skill.poison_strike")]
		var combat := CombatResolver.resolve(macro,resolved.stats,enemy,10000,7,true)
		check(combat.is_valid and combat.gold_stolen>0,"Mixed gold and poison run")
		var first_chance := -1.0
		var saw_live := false
		for tick in combat.tick_events:
			if not tick.had_active_stack: continue
			if first_chance<0: first_chance=tick.crit_chance
			if tick.crit_chance>first_chance: saw_live=true
		check(saw_live,"Later Poison crit reads credited theft")
	print("Assassin boundaries: %d checks %s" % [checks,"FAIL" if failed else "PASS"])
	quit(1 if failed else 0)
