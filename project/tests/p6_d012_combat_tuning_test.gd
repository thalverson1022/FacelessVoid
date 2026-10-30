extends "res://tests/p6_macro_scheduler_test.gd"
func _initialize() -> void:
	var enemy := Monster.new()
	enemy.hp=1000000
	for value in [0,1,2,3,4,5,20]:
		for converted in [false,true]:
			var stats := PlayerStats.new()
			stats.physical_damage_multiplier=2
			enemy.block=-value
			enemy.absorb=0
			if converted: stats.special_effects={"damage_conversion":{"magical":true}}
			var r := CombatResolver.resolve([make_skill("test.damage",1000)],stats,enemy,1000,7,true)
			check(r.is_valid and r.cast_events[0].physical_damage==roundf(20+value*.2),"Negative block adds one tenth before multiplier/conversion")
			check(r.cast_events[0].stat_snapshot.negative_block_base_bonus==value*.1,"Odd negative block stays fractional")
			stats=PlayerStats.new()
			stats.poison_damage_per_tick=10
			stats.elemental_damage_multiplier=2
			if converted: stats.special_effects={"damage_conversion":{"physical":true}}
			enemy.block=0
			enemy.absorb=-value
			var poison := make_skill("test.poison",100)
			poison.category=Skill.Category.DEBUFF
			poison.effects.clear()
			poison.poison_stacks_applied=5
			r=CombatResolver.resolve([poison],stats,enemy,1000,7,true)
			check(r.is_valid and r.tick_events[0].damage==roundf(10+value*.2),"Negative absorb adds one tenth before elemental scaling/conversion")
	# Long cast proves cooldown is not shortened by its own execution time.
	enemy.block=0
	enemy.absorb=0
	var attack := make_skill("test.long",2000)
	attack.cooldown_ms=1000
	var r := CombatResolver.resolve([attack,attack],PlayerStats.new(),enemy,5000,7,true)
	var impacts := []
	for event in r.cast_events:
		if not event.cooldown_blocked: impacts.append(event.time_ms)
	check(impacts==[2000,5000],"Two-second cast plus one-second cooldown before next cast")
	var view=preload("res://scripts/ui/combat_presentation_state.gd").new()
	view.begin(r)
	view.advance_to(1999)
	check(view.cooldowns.is_empty(),"No displayed timer while casting")
	view.advance_to(2000)
	check(view.cooldowns.get(attack.id)==3000,"Displayed full cooldown starts at completion")
	view.advance_to(3000)
	check(view.cooldowns.is_empty(),"Timer expires at exact next-cast start")
	print("D012 cooldown and negative-defense boundaries: "+("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
