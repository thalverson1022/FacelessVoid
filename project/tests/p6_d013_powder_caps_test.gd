extends "res://tests/p6_macro_scheduler_test.gd"
const Defense = preload("res://scripts/systems/combat_defense_debuffs.gd")
func _initialize() -> void:
	var stats := PlayerStats.new()
	stats.bonus_penetration_stacks=2
	stats.bonus_potency_stacks=2
	stats.special_effects={"double_applied_stacks":true}
	for status in ["penetration","potency"]:
		for conversion in [false,true]:
			var d := Defense.new(stats,0,0)
			check(d.grant(status,49,stats,0,{},true).error=="","Initial 49 stacks")
			check(d.grant(status,5,stats,100,{},conversion).error=="","Partial-cap grant")
			check(d.state.snapshot(status).stacks==50,"Both normal/doubled and Pact grants cap at 50")
			check(d.grant(status,100,stats,200,{},conversion).error=="","Overflow grant")
			check(d.state.snapshot(status).stacks==50 and d.state.snapshot(status).expires_at_ms==3200,"Capped grants refresh without increasing stacks")
			check(d.state.advance(3200)=="" and d.values().block==0 and d.values().absorb==0,"Exact expiry restores defenses")
	var powder: Skill=preload("res://scripts/systems/playable_assassin_content.gd").skill("blinding_powder")
	stats=PlayerStats.new()
	stats.assassin_tree_points=35
	var target := Monster.new()
	target.hp=10000000
	var r := CombatResolver.resolve([powder],stats,target,2400,7,true)
	check(r.is_valid and r.cast_events.size()==2 and r.cast_events[0].time_ms==1200 and r.cast_events[1].time_ms==2400,"Base Powder casts every 1.2s")
	check(r.cast_events[0].status_snapshot.defenses.absorb==-35 and r.cast_events[1].status_snapshot.defenses.absorb==-50,"Repeated Powder hits shared 50 cap")
	stats.attack_speed=100
	r=CombatResolver.resolve([powder],stats,target,1000,7,true)
	check(r.cast_events.size()==2 and r.cast_events[0].time_ms==500,"Powder minimum remains 500ms")
	check(powder.cooldown_ms==0,"Powder still has no cooldown")
	print("D013 Powder and defense caps: "+("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
