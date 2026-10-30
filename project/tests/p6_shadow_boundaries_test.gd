extends "res://tests/p6_full_shadow_test.gd"
const Defense = preload("res://scripts/systems/combat_defense_debuffs.gd")
func _initialize() -> void:
	super._initialize()
func fuel(count: int) -> Skill:
	var s := Skill.new()
	s.id="test.poison_fuel"
	s.category=Skill.Category.DEBUFF
	s.base_execution_ms=100
	s.min_execution_ms=100
	var effect := PoisonDamageEffect.new()
	effect.stacks_applied=count
	s.effects.append(effect)
	return s
func _run() -> void:
	registry=BuildContentRegistry.test_mode()
	var content := resolve(build(full_ranks()))
	check(View.effects(registry.talents["talent.shadow.dusk_strike"],1).contains("+10"),"Dusk tooltip includes added Shred effectiveness")
	var touch_tooltip := preload("res://scripts/ui/skill_tooltip_formatter.gd").conditions_for(skill(content,"skill.touch_of_darkness"),null)
	check(touch_tooltip.contains("12 seconds") and touch_tooltip.contains("+2 base physical"),"Touch tooltip includes both new live parameters")
	var stats: PlayerStats = content.stats.duplicate(true)
	stats.derivation_base=null
	stats.weapon_damage_min=100
	stats.weapon_damage_max=100
	stats.crit_chance=0
	stats.elemental_proc_chance=0
	stats.retrigger_chance=0
	stats.death_blade_enabled=false
	stats.poison_tick_interval_multiplier=100
	stats.bonus_poison_stacks=0
	var enemy := Monster.new()
	enemy.hp=10000000
	var death := skill(content,"skill.killers_mark")
	for stacks in [0,1,20,80]:
		var r := CombatResolver.resolve([fuel(stacks),death],stats,enemy,1600,7,true)
		check(r.is_valid and r.cast_events[1].physical_damage==roundf((100+2*stacks+4)*1.11*1.25),"Death stack base "+str(stacks))
		check(r.cast_events[1].status_snapshot.poison==stacks,"Death does not Consume")
		check(r.cast_events[1].damage_contributions.size()==1,"One Death contribution")
	var decay := skill(content,"skill.toxic_flurry")
	var distilled := skill(content,"skill.distilled_corruption")
	for count in [1,2,5,7]:
		stats.bonus_decay_stacks=count-1
		stats.bonus_poison_stacks=6
		for doubled in [false,true]:
			stats.special_effects["double_applied_stacks"]=doubled
			var r := CombatResolver.resolve([decay,distilled],stats,enemy,3200,7,true)
			var consumed := mini(5,count*(2 if doubled else 1))
			var expected := (consumed+6)*(2 if doubled else 1)
			check(r.is_valid and r.cast_events[1].poison_applications[0].applied==expected,"Conversion bonuses applied once")
			check(r.cast_events[1].status_snapshot.decay==count*(2 if doubled else 1)-consumed,"Actual Decay consumed")
			check(r.cast_events[1].status_snapshot.defenses.block==-consumed,"Pact exact actual Consume, no doubling")
			check(r.cast_events[0].shred_stacks_applied==10*(2 if doubled else 1),"Dusk independent from unequal Decay bonuses")
	stats.special_effects["double_applied_stacks"]=false
	stats.bonus_decay_stacks=6
	stats.bonus_poison_stacks=0
	var cap := CombatResolver.resolve([fuel(80),decay,distilled],stats,enemy,3300,7,true)
	check(cap.is_valid and cap.cast_events[2].poison_applications[0].applied==0,"Conversion at cap accepts zero")
	check(cap.cast_events[2].status_snapshot.decay==2 and cap.cast_events[2].status_snapshot.defenses.absorb==-5,"No refund at cap; Pact still applies")
	# Full block keeps applications; dodge suppresses attack-side Consume and Decay.
	enemy.block=100000
	var blocked := CombatResolver.resolve([decay,distilled],stats,enemy,3200,7,true)
	check(blocked.cast_events[0].physical_damage==0 and blocked.cast_events[0].decay_stacks_applied==7 and blocked.cast_events[1].status_snapshot.decay==2,"Full block does not stop stack mechanics")
	enemy.block=0
	enemy.dodge_chance=1
	var dodged := CombatResolver.resolve([decay,distilled],stats,enemy,3200,7,true)
	check(dodged.cast_events[0].decay_stacks_applied==0 and dodged.cast_events[1].poison_applications.is_empty(),"Dodge prevents applications/conversion")
	enemy.dodge_chance=0
	# Pact duration applies to every source and expires at the deadline.
	for pact in range(1,4):
		var ranks := full_ranks()
		ranks["talent.shadow.death_pact"]=pact
		var allocated: PlayerStats=resolve(build(ranks)).stats
		var trace := preload("res://scripts/systems/combat_event_trace.gd").new()
		var defense := Defense.new(allocated,0,0,trace)
		check(defense.grant("potency",2,allocated,0,{}).error=="","Generic source grant")
		var deadline := 3000+1000*pact
		check(defense.state.advance(deadline-1)=="" and defense.values().absorb<0,"Pact duration active")
		check(defense.state.advance(deadline)=="" and defense.values().absorb==0,"Pact exact expiry")
	# Verify suppression and natural chance through actual allocated Death Blade ranks.
	var procs := [0,0]
	for blade in [1,2]:
		var ranks := full_ranks()
		ranks["talent.shadow.death_blade"]=blade
		var allocated=resolve(build(ranks))
		var live: PlayerStats=allocated.stats
		check(View.effects(registry.talents["talent.shadow.death_blade"],blade).contains(str(40*blade)+"%"),"Death Blade tooltip uses live chance")
		live.retrigger_chance=.2
		var rotation: Array[Skill]=[skill(allocated,"skill.heavy_slash"),skill(allocated,"skill.distilled_corruption"),skill(allocated,"skill.toxic_flurry")]
		for seed_value in range(1,51):
			var r := CombatResolver.resolve(rotation,live,enemy,10000,seed_value,true)
			check(r.is_valid,"Allocated Death Blade combat")
			for event in r.cast_events:
				if event.skill.id=="skill.stab":
					procs[blade-1]+=1
					check(is_equal_approx(event.stat_snapshot.effective_crit_chance,live.crit_chance),"Death Blade adds no Stab crit chance")
					check(event.poison_applications.is_empty() and event.poison_stacks_applied==0,"All-source Stab Poison suppression")
	check(procs[0]>0 and procs[1]>0,"Both approved Death Blade ranks proc")
	# Actual allocated Mastery rebuilds its copy once when a temporary source changes.
	var derived = StatState.new(content.stats)
	var extra := StatModifier.new()
	extra.stat_id=StatCatalog.BASE_ELEMENTAL_DAMAGE
	extra.value=7
	var modifiers: Array[StatModifier]=[extra]
	check(derived.replace_source("test.beguiling","skill.beguiling_presence",modifiers,10)=="","Temporary elemental source accepted")
	check(is_equal_approx(derived.snapshot().bonus_physical_damage,7.5),"Mastery copies temporary +7 into +3.5")
	check(derived.remove_source("test.beguiling",10010)=="" and is_equal_approx(derived.snapshot().bonus_physical_damage,4),"Mastery recomputes on expiry without accumulation")
	var selected: Talent=registry.talents["talent.shadow.death_pact"].duplicate(true)
	selected.death_pact_rank=1
	var isolated := PlayerStats.new()
	var passives=preload("res://scripts/systems/shadow_passives.gd")
	check(passives.apply(isolated,selected)=="" and passives.apply(isolated,selected)!="","Duplicate Shadow source rejected")
	print("Shadow boundaries: %d checks %s" % [checks,"FAIL" if failed else "PASS"])
	quit(1 if failed else 0)
