extends SceneTree

const Poison = preload("res://scripts/systems/p6_poison_contracts.gd")
const Forced = preload("res://scripts/resources/forced_poison_tick_effect.gd")
const Buff = preload("res://scripts/resources/self_buff_effect.gd")
const Defense = preload("res://scripts/systems/combat_defense_debuffs.gd")
const ExsanguinateEffect = preload("res://scripts/resources/exsanguinate_effect.gd")
const SelfBuffs = preload("res://scripts/systems/combat_self_buffs.gd")
const Cadence = preload("res://scripts/systems/poison_cadence.gd")
const Talent = preload("res://scripts/systems/combat_talent_buffs.gd")
var failures: Array[String] = []
var assertions := 0
var witnesses: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures.append(message)
		print("FAILED: ", message)

func skill(id: String, category: Skill.Category = Skill.Category.ATTACK, time_ms: int = 300) -> Skill:
	var s := Skill.new()
	s.id = id
	s.display_name = id
	s.category = category
	s.base_execution_ms = time_ms
	s.min_execution_ms = time_ms
	if category == Skill.Category.ATTACK:
		var hit := PhysicalDamageEffect.new()
		hit.amount = 100.0
		s.effects = [hit]
	if id == "skill.exsanguinate":
		s.effects = [ExsanguinateEffect.new()]
	return s

func player(config: Dictionary = {}) -> PlayerStats:
	var p := PlayerStats.new()
	p.weapon_damage_min = 100
	p.weapon_damage_max = 100
	p.poison_damage_per_tick = 10.0
	p.special_effects = {"legendary": config}
	return p

func monster() -> Monster:
	var m := Monster.new()
	m.hp = 999999999
	return m

func rows(result: CombatResolver.CombatResult, kind: String) -> Array:
	return result.trace.records.filter(func(row): return row.kind == kind)

func save_witness(name: String, result: CombatResolver.CombatResult) -> void:
	var casts: Array = []
	for e in result.cast_events:
		casts.append({"id": e.cast_id, "parent": e.parent_cast_id, "root": e.root_cast_id, "skill": e.skill.id, "time": e.time_ms, "depth": e.retrigger_depth, "origin": e.origin_kind, "damage": e.physical_damage, "health_removed":e.health_removed, "crit": e.is_crit, "dodged": e.was_dodged, "snapshot": e.stat_snapshot, "status": e.status_snapshot})
	var ticks: Array = []
	for t in result.tick_events:
		ticks.append({"time": t.time_ms, "raw": t.raw_damage, "damage": t.damage, "fuel": t.legendary_fuel, "consumed": t.stacks_consumed, "remaining": t.stacks_remaining, "depth": t.legendary_depth, "origin": t.origin_kind, "crit": t.is_crit, "charge_spends": t.charge_spends})
	witnesses[name] = {"valid": result.is_valid, "failure": result.failure, "damage": result.total_damage, "health_removed":result.total_health_removed, "health_loss":result.total_health_loss(), "casts": casts, "ticks": ticks, "trace": result.trace.records}

func chance_and_depth() -> void:
	var p := player({"mithril": true, "samurai": true})
	p.retrigger_chance = 0.1
	var e := CombatResolver.CastEvent.new()
	e.skill = skill("skill.stab")
	var candidates := CombatResolver._triggers_for_source(e, p)
	check(candidates.size() == 1 and is_equal_approx(candidates[0].effect.chance, 0.6), "Mithril adds 50 percentage points in one local candidate")
	check(p.retrigger_chance == 0.1, "Mithril leaves numeric Retrigger Chance input unchanged")
	e.skill = skill("skill.heavy_slash")
	check(is_equal_approx(CombatResolver._triggers_for_source(e,p)[0].effect.chance,0.6), "Heavy Slash local chance")
	e.skill = skill("skill.quick_cut")
	check(is_equal_approx(CombatResolver._triggers_for_source(e,p)[0].effect.chance,0.1), "Quick Cut receives no Mithril bonus")
	e.lifecycle_snapshot = {"guaranteed_repeat_sources": PackedStringArray(["precision", "dance"])}
	candidates = CombatResolver._triggers_for_source(e,p)
	check(candidates.size() == 1 and candidates[0].effect.chance == 1.0, "guaranteed sources replace one numeric repeat candidate")
	p.retrigger_chance = 1.5
	var r := CombatResolver.resolve([skill("skill.stab")],p,monster(),300,19,true)
	check(r.is_valid and r.cast_events.size() == 17 and r.cast_events.back().retrigger_depth == 16, "overcap chain stops at retained depth 16")
	check(r.cast_events[0].physical_damage == 100.0 and r.cast_events[1].physical_damage == 100.0 and r.cast_events[2].physical_damage == 120.0 and r.cast_events[7].physical_damage == 200.0, "Meditation applies after completed repeat; physical cap x2")
	check(rows(r,"legendary_buff_grant").size() == 16, "every skill repeat grants Meditation including cap refreshes")
	save_witness("mithril_depth16_meditation",r)

func buffs_and_deadlines() -> void:
	var p := player({"all_stacks": 2})
	p.special_effects["double_applied_stacks"] = true
	p.increased_buff_duration = 0.3334
	var r := CombatResolver.CombatResult.new()
	r.trace.enabled = true
	CombatResolver._legendary_grant(r,p,"meditation",100,{"source_id":"samurai"})
	CombatResolver._legendary_grant(r,p,"dash",100,{"source_id":"wingjammer"})
	check(r.legendary_buffs.meditation.stacks == 5 and r.legendary_buffs.dash.stacks == 6, "All Stacks then doubling then remaining capacity")
	check(r.legendary_buffs.dash.expires_at_ms == 4101, "shared 3 sec duration uses ceiling with Buff Duration")
	for time_ms in [200,300,400,500]:
		CombatResolver._legendary_grant(r,p,"dash",time_ms,{"source_id":"wingjammer"})
	check(r.legendary_buffs.dash.stacks == 20 and r.legendary_buffs.dash.expires_at_ms == 4501, "cap20 refreshes shared timer even at cap")
	var live := CombatResolver._legendary_live(r,p,4500)
	check(live.attack_speed == 1.0 and live.temporary_physical_multiplier == 1.0, "Dash additive IAS survives while Meditation expired")
	check(CombatResolver._legendary_live(r,p,4501).attack_speed == 0.0, "expiry precedes equal deadline stat read")
	var cooldown_a := skill("test.a")
	cooldown_a.cooldown_ms = 800
	var cooldown_b := skill("test.b")
	cooldown_b.cooldown_ms = 2000
	r.scheduler.start(cooldown_a,100)
	r.scheduler.start(cooldown_b,100)
	var changes: Dictionary = r.scheduler.reduce_running_cooldowns(200,1000)
	check(changes.size() == 2 and r.scheduler.available_at("test.a") == 200 and r.scheduler.available_at("test.b") == 1100, "Locket recovers every running skill with now floor")
	r.scheduler.reduce_running_cooldowns(200,1000)
	r.scheduler.start(cooldown_a,200)
	check(r.scheduler.available_at("test.a") == 1000, "no cooldown recovery credit stored")
	witnesses["buff_timer_and_scheduler"] = {"trace":r.trace.records,"deadlines":changes}
	var poison_only := player()
	poison_only.bonus_poison_stacks = 10
	var isolated := CombatResolver.CombatResult.new()
	CombatResolver._legendary_grant(isolated,poison_only,"meditation",0,{})
	check(isolated.legendary_buffs.meditation.stacks == 1, "Poison-only stack bonuses never increase Meditation grants")

func exsanguinate() -> void:
	var p := player({"samurai":true,"all_stacks":5,"death_door":true,"missing_attempts":3,"locket":true,"wingjammer":true})
	p.retrigger_chance = 1.0
	p.shred_value = 60
	p.bonus_shred_stacks = 2
	p.special_effects["double_applied_stacks"] = true
	p.physical_damage_multiplier = 20.0
	p.crit_chance = 1.0
	p.death_pact_rank = 3
	var shred := skill("test.shred",Skill.Category.DEBUFF,300)
	var shred_effect := ArmorReductionEffect.new()
	shred_effect.amount = 3
	shred.effects = [shred_effect]
	var ex := skill("skill.exsanguinate",Skill.Category.DEBUFF,300)
	ex.cooldown_ms = 8000
	var m := monster()
	m.hp = 500
	m.armor = 30
	m.block = 999.0
	m.absorb = 999.0
	m.poison_resistance = 1.0
	m.crit_negation = 1.0
	m.dodge_chance = 1.0
	m.stun_duration_ms = 2000
	var r := CombatResolver.resolve([shred,ex],p,m,600,22,true)
	check(r.cast_events.size() == 2, "Exsanguinate executes once despite100 percent Retrigger")
	check(r.total_damage == 0.0 and r.dps == 0.0 and r.total_health_removed == 600.0 and r.total_health_loss() == 600.0 and r.is_win, "health removal wins through explicit health-loss total without inflating damage or DPS")
	check(rows(r,"health_removal").size() == 1 and r.cast_events.all(func(e):return e.stun_duration_ms == 0), "one health-removal operation never triggers damage-based stun")
	check(rows(r,"legendary_locket_trial").is_empty() and rows(r,"legendary_wingjammer_trial").is_empty(), "health removal creates no critical packet item hooks")
	check(r.cast_events[1].damage_contributions[0].kind == "health_removal" and r.cast_events[1].damage_contributions[0].damage == 0.0, "health-removal contribution carries a distinct type")
	for e in r.cast_events:
		if e.skill.id == "skill.exsanguinate":
			check(e.health_removed == 600.0 and e.physical_damage == 0.0 and not e.is_crit and not e.was_dodged, "captured direct removal bypasses defenses bonuses crit dodge")
			check(e.status_snapshot.shred == 0 and e.status_snapshot.armor == 30 and e.status_snapshot.defenses.block == 999.0, "Exsanguinate restores armor and grants no Death Pact")
	check(r.cast_events[1].stat_snapshot.actual_consumed == 10 and r.cast_events[1].origin_kind == "macro", "root Exsanguinate consumes all actual Shred")
	check(rows(r,"legendary_buff_grant").is_empty(), "Exsanguinate grants no phantom repeat Meditation")
	check(rows(r,"cooldown_started")[0].payload.cooldown_available_at_ms == 8600 and ex.min_execution_ms == 300, "Debuff min300 cooldown8sec")
	var above := m.duplicate(true) as Monster
	above.hp = 601
	var boundary := CombatResolver.resolve([shred,ex],p,above,600,22,true)
	check(boundary.is_valid and boundary.total_health_removed == 600.0 and not boundary.is_win, "one-times removal cannot defeat601 health with ten Shred at value60")
	save_witness("exsanguinate_defenses_capture",r)
	var empty := CombatResolver.resolve([ex],p,m,300,22,true)
	check(empty.cast_events.size() == 1 and empty.total_damage == 0.0 and empty.total_health_removed == 0.0 and rows(empty,"legendary_buff_grant").is_empty(), "zero fuel Exsanguinate removes zero and grants no repeat Meditation")
	check(rows(empty,"legendary_locket_trial").is_empty() and rows(empty,"legendary_wingjammer_trial").is_empty(), "Exsanguinate has no critical item hooks")
	var invalid := ex.duplicate(true) as Skill
	invalid.category = Skill.Category.ATTACK
	check(not CombatResolver.resolve([invalid],p,m,300).is_valid, "Exsanguinate rejects an attack-category health-removal effect")
	invalid = ex.duplicate(true) as Skill
	invalid.effects = []
	check(not CombatResolver.resolve([invalid],p,m,300).is_valid, "Exsanguinate rejects missing explicit effect data")

func tick_result(p: PlayerStats, m: Monster, seed_value: int = 1) -> CombatResolver.CombatResult:
	var r := CombatResolver.CombatResult.new()
	r.trace.enabled = true
	r.combat_rng = RandomNumberGenerator.new()
	r.combat_rng.seed = seed_value
	r.talent_buffs = Talent.new(p,r.trace)
	r.defense_debuffs = Defense.new(p,m.block,m.absorb,r.trace)
	r.self_buffs = SelfBuffs.new(r.trace,p.increased_buff_duration)
	r.self_buffs.legendary_crown = p.legendary_crown
	return r

func coil_and_decrepit() -> void:
	var p := player({"coil":true,"samurai":true,"decrepit":true,"locket":true,"wingjammer":true})
	p.retrigger_chance = 1.0
	p.critical_poison_enabled = true
	p.crit_chance = 0.5
	var m := monster()
	var r := tick_result(p,m,7)
	r.self_buffs.grant("virulent_poison",0,{"source_id":"virulent"})
	var remains := CombatResolver._resolve_poison_tick(r,100,4,p,0,0.0,m,0,true,{"source_id":"skill.poison_strike","root_cast_id":1},0,-1,true)
	check(remains == 0 and r.tick_events.size() == 17, "Decrepit consumes all4 once and Coil emits16 free repeats")
	var consumed := 0
	var crits := 0
	for t in r.tick_events:
		consumed += t.stacks_consumed
		crits += int(t.is_crit)
		check(t.legendary_fuel == 4 and t.stacks_remaining == 0, "Coil carries original packet fuel without stacks")
	check(consumed == 4 and crits > 0 and crits < 17, "fresh talent enabled crit rolls and no second fuel cost")
	check(r.tick_events[0].raw_damage == 80.0 and is_equal_approx(r.tick_events[4].raw_damage,128.0) and is_equal_approx(r.tick_events[5].raw_damage,72.0), "Virulent charges expire while later repeats recalculate live all-damage Meditation")
	check(rows(r,"legendary_poison_consume").size() == 1 and rows(r,"legendary_poison_depth_limit").size() == 1, "one keyword Consume and depth16 retained")
	check(rows(r,"legendary_locket_trial").size() == crits and rows(r,"legendary_wingjammer_trial").size() == crits, "one Locket then Wingjammer roll per Poison crit")
	check(rows(r,"legendary_buff_grant").filter(func(x):return x.payload.kind == "meditation").size() == 16, "every Poison repeat grants Meditation")
	save_witness("decrepit_coil_live_virulent",r)
	p.death_pact_rank = 3
	p.critical_poison_enabled = false
	p.special_effects.legendary.erase("locket")
	p.special_effects.legendary.erase("wingjammer")
	r = tick_result(p,m,7)
	CombatResolver._resolve_poison_tick(r,100,4,p,0,0.0,m,0,true,{"source_id":"skill.poison_strike"},0,-1,true)
	check(r.tick_events[0].raw_damage == 40.0 and is_equal_approx(r.tick_events[1].raw_damage,41.6), "Pact grant follows original damage; repeat reads live negative Absorb")
	check(r.defense_debuffs.values().block == -4.0 and rows(r,"legendary_poison_consume").size() == 1, "Pact gets actual4 once despite16 repeats")
	check(r.tick_events.all(func(t):return not t.is_crit), "Poison crit talent gate retained")
	save_witness("decrepit_pact_once",r)
	var empty := tick_result(p,m,7)
	var initial_rng := empty.combat_rng.state
	CombatResolver._resolve_poison_tick(empty,100,0,p,0,0.0,m,0,true,{},0,-1,true)
	check(empty.tick_events.size() == 1 and empty.total_damage == 0 and empty.combat_rng.state == initial_rng, "empty Poison has no packet crit or repeat draws")
	# Integrate ordinary natural clock and actual Poison Strike forced call site.
	var fuel := skill("test.fuel",Skill.Category.DEBUFF,100)
	var effect := PoisonDamageEffect.new()
	effect.stacks_applied = 4
	fuel.effects = [effect]
	var strike := Poison.poison_strike()
	strike.base_execution_ms = 100
	strike.min_execution_ms = 100
	p.retrigger_chance = 0.0
	r = CombatResolver.resolve([fuel,strike],p,m,200,7,true)
	check(r.tick_events.size() == 1 and r.tick_events[0].stacks_consumed == 4 and r.cast_events[1].physical_damage > 0.0, "real Poison Strike retains direct hit and replaces single forced tick")
	save_witness("decrepit_actual_skill_callsite",r)
	p.special_effects.legendary.erase("decrepit")
	p.retrigger_chance = 1.0
	var wait := skill("skill.hold",Skill.Category.DEBUFF,2000)
	r = CombatResolver.resolve([fuel,wait],p,m,1100,7,true)
	check(r.tick_events.size() == 17 and r.tick_events[0].origin_kind == "natural_tick" and r.tick_events[0].stacks_consumed == 1 and r.tick_events.back().stacks_remaining == 3, "natural Poison repeats free without advancing or resetting cadence")
	save_witness("natural_coil",r)

func crit_hooks_and_legal_chain() -> void:
	# Five legal slots: Mithril weapon, Samurai helm, Cloak armor, Locket charm, Wingjammer trinket.
	var gear: Array[GearItem] = [load("res://data/gear/mithril_karambit.tres"),
		load("res://data/gear/helm_of_the_samurai.tres"), load("res://data/gear/cloak_of_speed.tres"),
		load("res://data/gear/lolzorzs_locket.tres"), load("res://data/gear/wingjammer.tres")]
	var p := BuildResolver.resolve_stats(load("res://data/classes/rogue.tres"),[],[],gear)
	check(p.derivation_error == "" and is_equal_approx(p.retrigger_chance,0.08), "legal5 slots resolve real affixes through BuildResolver")
	witnesses["legal_build_sources"] = {"sources":p.stat_sources,"gear":gear.map(func(item):return {"id":item.id,"slot":item.slot}),"numeric_retrigger":p.retrigger_chance,"crit_chance":p.crit_chance}
	check(["mithril","samurai","cloak","locket","wingjammer"].all(func(key):return p.special_effects.legendary.get(key,false)), "actual five equipped resources wire all signature flags")
	var local := CombatResolver.CastEvent.new()
	local.skill = skill("skill.stab")
	check(CombatResolver._triggers_for_source(local,p).size() == 1, "real Mithril authored signature rolls replaced, not retained beside local candidate")
	p.footwork_rank = 2
	p.precision_duration_ms = -1
	var quick := load("res://data/skills/quick_cut.tres").duplicate(true) as Skill
	quick.poison_stacks_applied = 2 # build-resolved representative on-hit augmentation
	p.special_effects.legendary["quick_cut"] = quick
	var root_skill := skill("skill.stab")
	root_skill.cooldown_ms = 2000
	var r: CombatResolver.CombatResult
	var chosen_seed := -1
	for seed_value in range(1,2001):
		r = CombatResolver.resolve([root_skill],p,monster(),300,seed_value,true)
		if r.cast_events.any(func(e):return e.origin_kind == "cloak_proc") and rows(r,"legendary_locket_trial").any(func(row):return not row.payload.deadlines.is_empty()) and not rows(r,"legendary_buff_grant").filter(func(row):return row.payload.kind == "dash").is_empty():
			chosen_seed = seed_value
			break
	check(chosen_seed > 0 and r.is_valid, "real legal5 item chain includes Cloak QuickCut Locket and Dash")
	var cloak_casts := r.cast_events.filter(func(e):return e.origin_kind == "cloak_proc")
	check(cloak_casts.all(func(e):return e.skill == quick and e.poison_stacks_applied == 2), "Cloak uses supplied build-resolved Quick Cut object effects")
	check(rows(r,"effect_lifecycle").any(func(row):return row.payload.get("effect_id","") == "precision") and rows(r,"effect_lifecycle").any(func(row):return row.payload.get("effect_id","") == "footwork"), "Cloak Quick Cut participates in actual Precision and Footwork lifecycle")
	check(rows(r,"legendary_locket_trial").any(func(row):return row.payload.deadlines.has(root_skill.id) and row.payload.deadlines[root_skill.id].before > row.payload.deadlines[root_skill.id].after), "Locket actual critical packet recovers its own already running root cooldown")
	witnesses["combined_seed"] = chosen_seed
	save_witness("legal_combined_five_slots",r)
	var dodge := monster()
	dodge.dodge_chance = 1.0
	r = CombatResolver.resolve([root_skill],p,dodge,300,chosen_seed,true)
	check(r.cast_events.size() == 1 and rows(r,"legendary_locket_trial").is_empty() and rows(r,"legendary_wingjammer_trial").is_empty(), "dodge emits no crit hooks or descendants")
	var block := monster()
	block.block = 99999
	p.crit_chance = 1.0
	r = CombatResolver.resolve([root_skill],p,block,300,chosen_seed,true)
	check(r.total_damage == 0.0 and not rows(r,"legendary_locket_trial").is_empty(), "connected zero-damage crit qualifies for item trials")
	save_witness("blocked_zero_damage_crit",r)

func umbral_and_deathdoor() -> void:
	var p := player({"umbral":true})
	var decay := skill("test.decay",Skill.Category.DEBUFF,300)
	var effect := PoisonResistanceReductionEffect.new()
	decay.effects = [effect,effect,effect]
	var death := skill("skill.killers_mark")
	var r := CombatResolver.resolve([decay,death],p,monster(),600,8,true)
	check(r.cast_events[1].physical_damage == 114.0 and r.cast_events[1].status_snapshot.decay == 3, "Umbral adds actual3 Decay to raw DeathStrike base then1.11 scaling")
	save_witness("umbral_raw_base",r)
	var table := []
	for missing in range(4):
		p = player({"death_door":true,"missing_attempts":missing})
		r = CombatResolver.resolve([skill("test.attack")],p,monster(),300,8,true)
		var tick := tick_result(p,monster(),8)
		CombatResolver._resolve_poison_tick(tick,100,1,p,0,0.0,monster(),0,true)
		table.append({"missing":missing,"direct":r.total_damage,"poison":tick.total_damage})
		check(r.total_damage == 100.0 * [1,2,4,6][missing] and tick.total_damage == 10.0 * [1,2,4,6][missing], "DeathDoor approved direct and Poison attempt multiplier")
	witnesses["deathdoor_table"] = table

func boundaries_and_flags_off() -> void:
	var p := player({"coil":true,"locket":true,"wingjammer":true})
	p.retrigger_chance = 1.0
	var m := monster()
	m.poison_resistance = 0.5
	m.absorb = 3.0
	var r := tick_result(p,m)
	CombatResolver._resolve_poison_tick(r,100,2,p,100,0.5,m,0,true,{},0,-1,true)
	check(r.tick_events.all(func(t):return t.raw_damage == 20.0 and t.damage == 7.0), "all-stack original and free repeats retain ordinary resistance and Absorb")
	p.special_effects["damage_conversion"] = {"physical":true}
	m.block = 2.0
	m.absorb = 999.0
	r = tick_result(p,m)
	CombatResolver._resolve_poison_tick(r,100,2,p,100,1.0,m,0,true,{},0,-1,true)
	check(r.tick_events.all(func(t):return t.damage == 11.0), "converted Poison uses armor and Block for every repeat")
	p.critical_poison_enabled = true
	p.crit_chance = 1.0
	m.crit_negation = 1.0
	r = tick_result(p,m)
	CombatResolver._resolve_poison_tick(r,100,2,p,100,1.0,m,0,true,{},0,-1,true)
	check(r.tick_events.all(func(t):return t.damage == 0.0 and t.is_crit) and rows(r,"legendary_locket_trial").size() == 17, "converted zero damage critical Poison retains item trials")
	var multi := skill("test.multi")
	multi.effects.append(multi.effects[0].duplicate(true))
	p = player({"locket":true,"wingjammer":true})
	p.crit_chance = 1.0
	r = CombatResolver.resolve([multi],p,monster(),300,5,true)
	check(rows(r,"legendary_locket_trial").size() == 2 and rows(r,"legendary_wingjammer_trial").size() == 2, "two direct packets generate two ordered item trials")
	var order: Array = r.trace.records.filter(func(row):return row.kind in ["legendary_locket_trial","legendary_wingjammer_trial"]).map(func(row):return row.kind)
	check(order == ["legendary_locket_trial","legendary_wingjammer_trial","legendary_locket_trial","legendary_wingjammer_trial"], "critical hooks have deterministic Locket then Wingjammer order")
	p = player({"death_door":true,"missing_attempts":3,"unlimited_retries":true})
	r = CombatResolver.resolve([skill("test.attack")],p,monster(),300,5,true)
	check(r.total_damage == 100.0, "opening unlimited retries override missing attempt descriptor to x1")
	var ex := skill("skill.exsanguinate",Skill.Category.DEBUFF,300)
	ex.cooldown_ms = 8000
	p.attack_speed = 100.0
	p.cooldown_factor = 0.5
	r = CombatResolver.resolve([ex],p,monster(),300,5,true)
	check(r.cast_events[0].time_ms == 300 and rows(r,"cooldown_started")[0].payload.cooldown_available_at_ms == 4300, "Exsanguinate retains min300 with IAS and ordinary multiplicative CDR")
	# Actual current Wyvern resource routes its 500ms clock into free Coil repeats.
	p = BuildResolver.resolve_stats(load("res://data/classes/rogue.tres"),[],[],[load("res://data/gear/wyvern_kriss.tres")])
	p.special_effects["legendary"] = {"coil":true}
	p.retrigger_chance = 1.0
	var fuel := skill("test.wyvern_fuel",Skill.Category.DEBUFF,100)
	var application := PoisonDamageEffect.new()
	application.stacks_applied = 4
	fuel.effects = [application]
	r = CombatResolver.resolve([fuel,skill("test.wait",Skill.Category.DEBUFF,2000)],p,monster(),600,5,true)
	check(r.tick_events.size() == 17 and r.tick_events[0].time_ms == 500 and r.tick_events[0].tick_interval_ms == 500 and r.tick_events.back().stacks_remaining == 3, "actual Wyvern cadence plus Coil costs one natural fuel only")
	save_witness("wyvern_coil",r)
	# A guarantee must not admit a health-removal skill to self-repeat eligibility.
	p = player()
	p.retrigger_chance = 1.5
	var guaranteed := CombatResolver.CastEvent.new()
	guaranteed.skill = ex
	guaranteed.lifecycle_snapshot = {"guaranteed_repeat_sources": PackedStringArray(["dance", "precision"])}
	check(CombatResolver._triggers_for_source(guaranteed,p).is_empty(), "Exsanguinate cannot self-repeat from overcap chance or guarantees")
	p = player({"cloak":true,"samurai":true})
	p.retrigger_chance = 1.0
	p.footwork_rank = 1
	p.precision_duration_ms = -1
	var quick := load("res://data/skills/quick_cut.tres").duplicate(true) as Skill
	p.special_effects.legendary["quick_cut"] = quick
	for seed_value in range(1,31):
		r = CombatResolver.resolve([quick],p,monster(),850,seed_value,true)
		if r.is_valid and r.cast_events.any(func(e):return e.origin_kind == "cloak_proc"): break
	check(r.is_valid and r.cast_events.any(func(e):return e.origin_kind == "cloak_proc" and e.trigger_source_skill_id == "skill.quick_cut"), "normal Quick Cut repeats recursively activate Cloak at30 percent")
	check(rows(r,"trigger_decision").any(func(row):return row.payload.get("child_origin_kind","") == "cloak_proc" and row.payload.chance == 0.3), "recursive Cloak uses unchanged30 percent chance")
	save_witness("recursive_cloak_quickcut",r)
	# Dash IAS must enter live Hastened Poison cadence, including mid-phase expiry.
	p = player()
	p.hastened_poison_rank = 5
	p.accelerant_rank = 5
	p.increased_buff_duration = 0.0
	r = tick_result(p,monster())
	p.special_effects.legendary["all_stacks"] = 19
	CombatResolver._legendary_grant(r,p,"dash",0,{"source_id":"wingjammer"})
	CombatResolver._sync_poison_cadence(r,0,p,monster())
	check(r.poison_clock.interval_ms == 500, "Dash20 IAS enters Hastened plus Accelerant Poison rate")
	CombatResolver._advance_poison(r,3000,0,p,0,0.0,monster())
	check(r.poison_clock.interval_ms == 1000 and not r.legendary_buffs.has("dash") and rows(r,"legendary_buff_expired").size() == 1, "Dash expires at3000 boundary and live Poison interval returns1000")
	check(r.tick_events.size() == 6 and r.tick_events.back().time_ms == 3000, "expiry boundary preserves natural cadence progress without extra tick")
	# Independent natural roots reset their budget; forced descendants share owner budget.
	p = player({"coil":true})
	p.retrigger_chance = 1.0
	r = tick_result(p,monster())
	for index in range(65):
		CombatResolver._resolve_poison_tick(r,index,1,p,0,0.0,monster(),1000)
	check(r.is_valid and r.trigger_candidates_evaluated == 1040 and r.root_trigger_candidates == 16 and r.tick_events.size() == 1105, "65 independent natural tick roots do not accumulate candidate1024 failure")
	r = tick_result(p,monster())
	r.root_trigger_candidates = 1024
	CombatResolver._resolve_poison_tick(r,0,1,p,0,0.0,monster(),0,true)
	check(not r.is_valid and r.root_trigger_candidates == 1024, "forced Poison shares owning root candidate budget")
	witnesses["natural_tick_budget_isolation"] = {"independent_natural_roots":65,"total_candidates":1040,"last_root_candidates":16,"forced_limit_failure":r.failure}
	# Forced Poison inherits its owning skill depth; it cannot start another16-level budget.
	p = player({"coil":true})
	p.retrigger_chance = 1.0
	r = tick_result(p,monster())
	CombatResolver._resolve_poison_tick(r,0,1,p,0,0.0,monster(),0,true,{"source_id":"skill.poison_strike","retrigger_depth":15})
	check(r.tick_events.size() == 2 and r.tick_events[0].origin_kind == "forced_tick" and r.tick_events[1].origin_kind == "poison_repeat" and r.tick_events[1].legendary_depth == 16, "forced Poison at skilldepth15 permits one repeat only with shared ancestrydepth16")
	r = tick_result(p,monster())
	CombatResolver._resolve_poison_tick(r,0,1,p,0,0.0,monster(),0,true,{"retrigger_depth":16})
	check(r.tick_events.size() == 1 and r.trigger_candidates_evaluated == 0, "forced Poison at owning skilldepth16 cannot add any repeat")
	var setup_fuel := skill("test.shared_fuel",Skill.Category.DEBUFF,100)
	var poison_effect := PoisonDamageEffect.new()
	poison_effect.stacks_applied = 1
	setup_fuel.effects = [poison_effect]
	var poison_strike := Poison.poison_strike()
	poison_strike.base_execution_ms = 100
	poison_strike.min_execution_ms = 100
	r = CombatResolver.resolve([setup_fuel,poison_strike],p,monster(),200,5,true)
	check(r.tick_events.all(func(t):return t.legendary_depth <= 16) and r.cast_events.back().retrigger_depth == 16, "real skill repeat plus forced Poison uses shared maximumdepth16")
	save_witness("shared_skill_poison_depth",r)
	# Natural-at-impact candidates cannot leak into the next macro root's subtree.
	var natural_fuel := skill("test.natural_fuel",Skill.Category.DEBUFF,100)
	natural_fuel.effects = [poison_effect]
	r = CombatResolver.resolve([natural_fuel,skill("test.after_natural",Skill.Category.ATTACK,900)],p,monster(),1000,5,true)
	check(r.is_valid and r.trigger_candidates_evaluated == 32 and r.root_trigger_candidates == 16, "macro root resets budget after same-time natural tick subtree")
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/t7_combat_baseline.json"))
	var cases = load("res://tests/helpers/p6_combat_observation_cases.gd")
	var setup: Dictionary = cases.setup()
	for seed_text in baseline:
		r = CombatResolver.resolve(setup.rotation,setup.stats,setup.monster,12000,int(seed_text),true)
		var signature := baseline_signature(r)
		check(signature == baseline[seed_text].signature and str(r.rng_final_state) == baseline[seed_text].rng, "flags off exact current-source gameplay and RNG parity seed " + seed_text)
	witnesses["flags_off_current_baseline"] = baseline

func baseline_signature(r: CombatResolver.CombatResult) -> String:
	var cases = load("res://tests/helpers/p6_combat_observation_cases.gd")
	var data := {"damage":r.total_damage,"dps":r.dps,"win":r.is_win,"casts":[],"ticks":[]}
	for event in r.cast_events + r.tick_events:
		var values: Dictionary = cases._old_fields(event)
		for key in values.keys():
			if String(key).begins_with("legendary_") or key in ["health_removed", "health_removal_captured"]: values.erase(key)
		data["casts" if event is CombatResolver.CastEvent else "ticks"].append(values)
	return JSON.stringify(cases._normalize(data)).sha256_text()

func candidate_failure() -> void:
	var p := player()
	var attack := skill("test.branch")
	for i in range(2):
		var trigger := TriggeredSkillEffect.new()
		trigger.skill = attack
		trigger.chance = 1.0
		p.triggered_skill_effects.append(trigger)
	var r := CombatResolver.resolve([attack],p,monster(),300,9,true)
	check(not r.is_valid and r.root_trigger_candidates == 1024 and r.failure.get("code","") == "trigger_candidate_limit", "candidate1024 safeguard invalidates accepted recursive branching honestly")
	witnesses["candidate1024_failure"] = {"valid":r.is_valid,"failure":r.failure,"candidates":r.root_trigger_candidates,"casts":r.cast_events.size(),"max_depth":r.cast_events.map(func(e):return e.retrigger_depth).max(),"trace_tail":r.trace.records.slice(-8)}

func equipped_production_weapons() -> void:
	var rogue := load("res://data/classes/rogue.tres") as ClassDef
	var gear: Array[GearItem] = [load("res://data/gear/mithril_karambit.tres")]
	var p := BuildResolver.resolve_stats(rogue,[],[],gear)
	var e := CombatResolver.CastEvent.new()
	e.skill = load("res://data/skills/stab.tres")
	var candidates := CombatResolver._triggers_for_source(e,p)
	check(p.special_effects.legendary.mithril and p.retrigger_chance == 0.0 and candidates.size() == 1 and candidates[0].effect.chance == 0.5, "actual equipped Mithril wires one local50-point candidate without numeric retrigger")
	var r := CombatResolver.resolve([e.skill],p,monster(),10000,3,true)
	check(r.is_valid and r.cast_events.any(func(event):return event.origin_kind == "random_repeat"), "actual equipped Mithril produces recursive skill repeats")
	save_witness("production_mithril",r)
	# Decrepit unlocks the production skill, including its explicit forced tick.
	gear = [load("res://data/gear/decrepit_blade.tres"),load("res://data/gear/serpents_coil.tres")]
	p = BuildResolver.resolve_stats(rogue,[],[],gear)
	var unlocked := BuildResolver.resolve_unlocked_skills(rogue,[],[],gear)
	var strike: Skill = unlocked.filter(func(s):return s.id == "skill.poison_strike")[0]
	check(strike.effects.any(func(effect):return effect is Forced) and p.special_effects.legendary.decrepit and p.special_effects.legendary.coil, "actual equipped Decrepit and Coil wire the production Poison Strike forced activation")
	var fuel := skill("test.production_poison_fuel",Skill.Category.DEBUFF,100)
	var poison := PoisonDamageEffect.new()
	poison.stacks_applied = 4
	fuel.effects = [poison]
	var duration := 100 + CombatTiming.execution_time_ms_with_slow(strike,p.attack_speed,0.0)
	var chosen := -1
	for seed_value in range(1,101):
		r = CombatResolver.resolve([fuel,strike],p,monster(),duration,seed_value,true)
		if r.tick_events.any(func(t):return t.origin_kind == "poison_repeat"):
			chosen = seed_value
			break
	var forced_ticks := r.tick_events.filter(func(t):return t.origin_kind == "forced_tick")
	check(chosen > 0 and r.is_valid and forced_ticks.size() >= 1 and forced_ticks[0].stacks_consumed > 1 and r.cast_events[1].physical_damage > 0.0, "actual Decrepit retains direct damage then all-stack burst and actual Coil yields a free repeat")
	check(r.tick_events.filter(func(t):return t.origin_kind == "poison_repeat").all(func(t):return t.stacks_consumed == 0), "production Coil repeats never consume further Poison")
	save_witness("production_decrepit_coil",r)
	# The real Nightkiss affixes supply both +50 Shred Value and +5 All Stacks.
	gear = [load("res://data/gear/nightkiss_kitana.tres")]
	p = BuildResolver.resolve_stats(rogue,[],[],gear)
	unlocked = BuildResolver.resolve_unlocked_skills(rogue,[],[],gear)
	var ex: Skill = unlocked.filter(func(s):return s.id == "skill.exsanguinate")[0]
	check(ex.category == Skill.Category.DEBUFF and ex.effects[0] is ExsanguinateEffect and p.shred_value == 60 and p.bonus_shred_stacks == 5, "production Nightkiss unlocks typed Exsanguinate and resolves fixed Shred plus All Stacks affixes")
	var shred := skill("test.production_shred",Skill.Category.DEBUFF,100)
	var shred_effect := ArmorReductionEffect.new()
	shred_effect.amount = 1
	shred.effects = [shred_effect]
	var target := monster()
	target.armor = 99999
	target.block = 99999.0
	target.hp = 350
	r = CombatResolver.resolve([shred,ex],p,target,400,3,true)
	check(r.is_valid and r.cast_events[1].health_removed == 360.0 and r.total_damage == 0.0 and r.is_win and r.cast_events[1].status_snapshot.armor == target.armor, "production Nightkiss consumes actual six Shred for360 direct health removal and restores armor")
	save_witness("production_nightkiss",r)
	# Real Umbral keeps Decay and augments Death Strike's existing weapon packet.
	gear = [load("res://data/gear/umbral_stiletto.tres")]
	p = BuildResolver.resolve_stats(rogue,[],[],gear)
	unlocked = BuildResolver.resolve_unlocked_skills(rogue,[],[],gear)
	var death: Skill = unlocked.filter(func(s):return s.id == "skill.killers_mark")[0]
	var decay := skill("test.production_decay",Skill.Category.DEBUFF,100)
	var decay_effect := PoisonResistanceReductionEffect.new()
	decay.effects = [decay_effect,decay_effect,decay_effect]
	duration = 100 + CombatTiming.execution_time_ms_with_slow(death,p.attack_speed,0.0)
	r = CombatResolver.resolve([decay,death],p,monster(),duration,3,true)
	var control := p.duplicate(true) as PlayerStats
	control.special_effects.legendary["umbral"] = false
	var without := CombatResolver.resolve([decay,death],control,monster(),duration,3,true)
	check(r.is_valid and r.cast_events[1].physical_damage > without.cast_events[1].physical_damage and r.cast_events[1].status_snapshot.decay == 3, "production Umbral increases actual Death Strike's hit while retaining actual Decay")
	save_witness("production_umbral",r)
	# Bejeweled uses the ready-root scheduler's existing40 percent draw.
	gear = [load("res://data/gear/bejeweled_push_dagger.tres")]
	p = BuildResolver.resolve_stats(rogue,[],[],gear)
	var heavy := load("res://data/skills/heavy_slash.tres") as Skill
	var minimum_seen := false
	var ordinary_seen := false
	for seed_value in range(1,31):
		r = CombatResolver.resolve([heavy],p,monster(),2200,seed_value,true)
		var first := r.cast_events[0]
		minimum_seen = minimum_seen or (first.min_cast_time_proc_applied and first.time_ms == heavy.min_execution_ms)
		ordinary_seen = ordinary_seen or (not first.min_cast_time_proc_applied and first.time_ms == CombatTiming.execution_time_ms_with_slow(heavy,p.attack_speed,0.0))
	check(is_equal_approx(p.min_cast_time_proc_chance,0.4) and minimum_seen and ordinary_seen, "actual Bejeweled produces both40-percent minimum casts and ordinary root windup")
	var cooling := heavy.duplicate(true) as Skill
	cooling.cooldown_ms = 6000
	r = CombatResolver.resolve([cooling],p,monster(),3000,3,true)
	check(r.cast_events.slice(1).all(func(event):return event.cooldown_blocked and not event.min_cast_time_proc_applied and event.time_ms - event.cast_start_ms == 100), "Bejeweled cannot bypass cooldown or roll minimum timing on blocked slots")
	save_witness("production_bejeweled_cooldown",r)
	# Encounter failure context is present for every build; only the armor owns damage scaling.
	var attempts := {"missing_attempts":3,"unlimited_retries":false}
	p = BuildResolver.resolve_stats(rogue,[],[],[],0,[],attempts)
	var unchanged := BuildResolver.resolve_stats(rogue,[],[],[])
	var attack := skill("test.production_death_door_control")
	r = CombatResolver.resolve([attack],p,monster(),300,3,true)
	without = CombatResolver.resolve([attack],unchanged,monster(),300,3,true)
	var control_tick := tick_result(p,monster(),3)
	CombatResolver._resolve_poison_tick(control_tick,0,1,p,0,0.0,monster(),0,true)
	check(r.total_damage == without.total_damage and control_tick.tick_events[0].raw_damage == p.poison_damage_per_tick, "actual build without Death's Door ignores encounter failures for direct damage and Poison")
	gear = [load("res://data/gear/deaths_door.tres")]
	p = BuildResolver.resolve_stats(rogue,[],[],gear,0,[],attempts)
	control = p.duplicate(true) as PlayerStats
	control.special_effects.legendary["death_door"] = false
	r = CombatResolver.resolve([attack],p,monster(),300,3,true)
	without = CombatResolver.resolve([attack],control,monster(),300,3,true)
	var door_tick := tick_result(p,monster(),3)
	CombatResolver._resolve_poison_tick(door_tick,0,1,p,0,0.0,monster(),0,true)
	check(p.special_effects.legendary.death_door and r.total_damage == without.total_damage * 6.0 and is_equal_approx(door_tick.tick_events[0].raw_damage,p.poison_damage_per_tick * 6.0), "actual Death's Door armor applies approved missing3 multiplier to direct damage and Poison")
	save_witness("production_deaths_door",r)

func signet_beguiling_cadence_boundary() -> void:
	var gear: Array[GearItem] = [load("res://data/gear/crown_of_concertation.tres"),load("res://data/gear/signet_of_the_old_kings.tres")]
	var p := BuildResolver.resolve_stats(load("res://data/classes/rogue.tres"),[],[],gear)
	p.hastened_poison_rank = 5
	p.accelerant_rank = 5
	var m := monster()
	var r := tick_result(p,m)
	var ordinary_interval := Cadence.interval(p,0.0)
	check(r.self_buffs.grant("beguiling_presence",0,{"source_id":"test.long_cast_beguiling"},3.0,3) == "", "combined actual Crown and Signet accept Beguiling instance")
	var expiry: int = r.self_buffs.instances[0].expires_at_ms
	CombatResolver._sync_poison_cadence(r,0,p,m)
	var accelerated_interval: int = r.poison_clock.interval_ms
	check(accelerated_interval < ordinary_interval, "Crown-strength Beguiling Crit Chance converts through Signet to accelerated Poison cadence")
	CombatResolver._advance_poison(r,expiry - 1,0,p,0,0.0,m)
	var phase_at_expiry: float = r.poison_clock.progress + 1.0 / accelerated_interval
	var expected_next: int = expiry + maxi(0,ceili((1.0 - phase_at_expiry) * ordinary_interval - 0.0000001))
	CombatResolver._advance_poison(r,expiry,0,p,0,0.0,m)
	check(r.self_buffs.instances.is_empty() and r.poison_clock.interval_ms == ordinary_interval, "Beguiling expiry during a long cast restores Signet-derived Poison cadence at its exact deadline")
	check(r.poison_clock.deadline() == expected_next, "Beguiling cadence expiry retains fractional natural tick phase")
	check(rows(r,"effect_lifecycle").any(func(row):return row.time_ms == expiry and row.lifecycle_reason == "expired"), "self-buff expiry is traced at the actual shared deadline")
	CombatResolver._advance_poison(r,expected_next,0,p,0,0.0,m)
	check(r.tick_events.back().time_ms == expected_next, "first post-Beguiling natural tick follows the preserved phase")
	save_witness("production_signet_crown_beguiling_expiry",r)

func run() -> void:
	chance_and_depth()
	buffs_and_deadlines()
	exsanguinate()
	coil_and_decrepit()
	crit_hooks_and_legal_chain()
	umbral_and_deathdoor()
	boundaries_and_flags_off()
	candidate_failure()
	equipped_production_weapons()
	signet_beguiling_cadence_boundary()
	DirAccess.make_dir_recursive_absolute("res://reports")
	var file := FileAccess.open("res://reports/t7_combat_witness.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions":assertions,"failures":failures,"witnesses":witnesses},"\t"))
	file.close()
	print("PASS" if failures.is_empty() else "FAILED", " T7 combat assertions=",assertions," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
