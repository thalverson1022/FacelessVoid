extends SceneTree
const Buffs = preload("res://scripts/systems/combat_talent_buffs.gd")
const Contracts = preload("res://scripts/systems/p6_status_skill_contracts.gd")
const Trace = preload("res://scripts/systems/combat_event_trace.gd")
const Observation = preload("res://tests/helpers/p6_combat_observation_cases.gd")
var failed := false

func _initialize() -> void:
	_riposte()
	_bypass()
	_touch()
	_sources_and_boundaries()
	_final_boundaries()
	print("P6 T4 completion: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + label)

func hit(id: String, ms: int = 1000, minimum: int = 1) -> Skill:
	var s := Skill.new()
	s.id = id
	s.base_execution_ms = ms
	s.min_execution_ms = minimum
	var damage := PhysicalDamageEffect.new()
	damage.amount = 10
	s.effects = [damage]
	return s

func _riposte() -> void:
	for rank in [1, 2]:
		for stacks in range(1, 6):
			var p := PlayerStats.new()
			p.footwork_rank = 5
			p.weapon_damage_min = 1000
			p.weapon_damage_max = 1000
			p.riposte_rank = rank
			p.bonus_footwork_stacks = stacks - 1
			var rotation: Array[Skill] = [hit("skill.quick_cut", 100), hit("skill.leaping_plunge", 1000, 500)]
			var result := CombatResolver.resolve(rotation, p, Monster.new(), 1100, 7, true)
			var plunge := result.cast_events[1]
			check(result.is_valid and is_equal_approx(plunge.lifecycle_snapshot.riposte_multiplier, 1.0 + 0.2 * rank * stacks), "Riposte rank/stack mapping")
			p.riposte_rank = 0
			var baseline := CombatResolver.resolve(rotation, p, Monster.new(), 1100, 7)
			check(is_equal_approx(plunge.physical_damage, float(roundi(baseline.cast_events[1].physical_damage * (1.0 + 0.2 * rank * stacks)))), "Riposte scales damage once: rank %d stacks %d actual %s baseline %s" % [rank, stacks, plunge.physical_damage, baseline.cast_events[1].physical_damage])
	var p := PlayerStats.new()
	p.footwork_rank = 5
	p.riposte_rank = 2
	p.bonus_footwork_stacks = 1
	p.special_effects = {"double_applied_stacks": true}
	var trigger := TriggeredSkillEffect.new()
	trigger.skill = hit("skill.leaping_plunge", 1000, 500)
	trigger.chance = 1.0
	trigger.source_skill_ids = ["skill.leaping_plunge"]
	p.triggered_skill_effects = [trigger]
	var result := CombatResolver.resolve([hit("skill.quick_cut", 100), trigger.skill], p, Monster.new(), 700, 7, true)
	check(result.cast_events[1].lifecycle_snapshot.footwork_consumed == 4, "Footwork adds then doubles")
	check(result.cast_events[2].lifecycle_snapshot.footwork_consumed == 0 and result.cast_events[2].lifecycle_snapshot.riposte_multiplier == 1.0, "Plunge repeat cannot inherit consumed Riposte stacks")
	check(result.effect_lifecycle.state.snapshot().is_empty(), "Footwork cleanup")
	p.riposte_rank = 3
	check(not CombatResolver.resolve([hit("skill.quick_cut")], p, Monster.new(), 1000).is_valid, "invalid Riposte rank rejected")

func _bypass() -> void:
	var p := PlayerStats.new()
	p.bypass_enabled = true
	p.bonus_bypass_stacks = 1
	p.special_effects = {"double_applied_stacks": true}
	p.poison_damage_per_tick = 10.0
	var trace := Trace.new()
	trace.enabled = true
	var buffs := Buffs.new(p, trace)
	check(buffs.finish_cast("skill.stab", true, 100, {}) == "", "Bypass grant")
	check(buffs.state.snapshot("bypass").stacks == 3 and is_equal_approx(buffs.live_player(p).elemental_damage_multiplier, 1.3), "Bypass add/double/cap gives 1.3x")
	var initial: Dictionary = trace.records.back().duplicate(true)
	var initial_index := trace.records.size() - 1
	buffs.finish_cast("skill.stab", true, 200, {})
	check(buffs.state.snapshot("bypass").expires_at_ms == 3200, "Bypass refreshes at cap")
	buffs.state.advance(3200)
	check(buffs.state.snapshot().is_empty() and buffs.live_player(p).elemental_damage_multiplier == 1.0, "Bypass exact expiry removes bonus")
	check(trace.records[initial_index] == initial, "later refresh/expiry cannot mutate earlier trace snapshot")
	var fuel := Contracts.skill("poison_vile")
	fuel.base_execution_ms = 500
	var stab := hit("skill.stab", 500)
	var result := CombatResolver.resolve([fuel, stab], p, Monster.new(), 2000, 7, true)
	check(result.tick_events[0].damage == 10.0 and result.tick_events[1].damage == 13.0, "Bypass affects live Poison after the granting Stab, not simultaneous earlier tick")
	var blocked := Monster.new()
	blocked.block = 10000
	result = CombatResolver.resolve([stab], p, blocked, 500, 7, true)
	check(_grant_count(result, "bypass") == 1, "fully blocked Stab grants Bypass")
	blocked.dodge_chance = 1.0
	result = CombatResolver.resolve([stab], p, blocked, 500, 7, true)
	check(_grant_count(result, "bypass") == 0, "dodged Stab grants no Bypass")
	var child := TriggeredSkillEffect.new()
	child.skill = hit("test.child", 500)
	child.chance = 1.0
	child.source_skill_ids = ["skill.stab"]
	p.triggered_skill_effects = [child]
	result = CombatResolver.resolve([stab], p, Monster.new(), 500, 7, true)
	check(result.cast_events[1].stat_snapshot.elemental_multiplier == 1.0, "Bypass grants after children")
	check(result.talent_buffs.state.snapshot().is_empty(), "Bypass fight cleanup")

func _touch() -> void:
	var p := PlayerStats.new()
	p.attack_speed = 1.0
	p.poison_stack_cap = 80
	p.poison_tick_interval_multiplier = 100.0
	p.death_pact_rank = 1
	var touch := Contracts.skill("touch_of_darkness")
	var fuel := Contracts.skill("poison_vile")
	fuel.base_execution_ms = 500
	fuel.effects[0].stacks_applied = 80
	var attack := hit("test.slow", 20000, 500)
	var rotation: Array[Skill] = [fuel, touch, attack]
	var result := CombatResolver.resolve(rotation, p, Monster.new(), 3100, 7, true)
	check(result.is_valid and result.cast_events.size() == 3, "Touch integration casts")
	if result.cast_events.size() < 3:
		return
	check(result.cast_events[1].time_ms - result.cast_events[1].cast_start_ms == 500, "Touch ignores ordinary IAS")
	check(result.cast_events[1].status_snapshot.poison == 0 and result.cast_events[1].status_snapshot.defenses.block == -50.0, "Touch consumes all actual Poison and triggers Pact capped at 50 Potency")
	check(result.cast_events[2].time_ms - result.cast_events[2].cast_start_ms == 2000, "Touch +800% adds to existing +100% IAS")
	check(p.attack_speed == 1.0 and result.talent_buffs.state.snapshot().is_empty(), "Touch never mutates input and cleans up")
	var quiet := CombatResolver.resolve(rotation, p, Monster.new(), 3100, 7)
	var replay := CombatResolver.resolve(rotation, p, Monster.new(), 3100, 7, true)
	check(Observation.signature(quiet) == Observation.signature(result) and quiet.rng_final_state == result.rng_final_state, "Touch trace/RNG parity")
	check(replay.trace.records == result.trace.records, "Touch seeded replay")
	var zero := CombatResolver.resolve([touch], p, Monster.new(), 1000, 7, true)
	check(zero.cast_events.size() == 6 and zero.cast_events[1].cooldown_blocked, "zero fuel spends cast and starts cooldown")
	check(_grant_count(zero, "touch.1") == 0, "zero fuel grants no Touch")
	var buffs := Buffs.new(p)
	buffs.grant_touch(50, 0, {})
	buffs.grant_touch(80, 1000, {})
	check(buffs.live_player(p).attack_speed == 14.0, "future overlap adds +500% and +800% to +100%")
	check(CombatTiming.execution_time_ms(hit("test.fast", 1000, 500), buffs.live_player(p).attack_speed) == 500, "Touch respects minimum")
	buffs.grant_touch(0, 2000, {})
	check(buffs.state.snapshot().size() == 2, "zero fuel preserves prior independent instances")
	check(buffs.live_player(p).bonus_physical_damage == p.bonus_physical_damage + 260, "Touch gives +2 base physical per actual consumed stack")
	buffs.state.advance(11999)
	check(buffs.live_player(p).bonus_physical_damage == p.bonus_physical_damage + 260, "Touch damage active before expiry")
	buffs.state.advance(12000)
	check(buffs.live_player(p).bonus_physical_damage == p.bonus_physical_damage + 160, "First Touch damage expires independently")
	check(buffs.live_player(p).attack_speed == 9.0, "first Touch expires independently")
	buffs.state.advance(13000)
	check(buffs.live_player(p).bonus_physical_damage == p.bonus_physical_damage, "All Touch damage expires without mutating base")
	check(buffs.live_player(p).attack_speed == 1.0, "all Touch bonuses expire")
	# A long cast keeps its start-time speed even when the buff expires mid-cast.
	attack.base_execution_ms = 100000
	result = CombatResolver.resolve(rotation, p, Monster.new(), 15000, 7, true)
	check(result.cast_events[2].time_ms - result.cast_events[2].cast_start_ms == 10000, "Touch expiry does not retime an in-flight cast")

func _sources_and_boundaries() -> void:
	var gear: GearItem = load("res://data/gear/crude_dagger.tres").duplicate(true)
	var extra := StatModifier.new()
	extra.stat_id = StatCatalog.INCREASED_ALL_STACKS
	extra.value = 1.0
	gear.affixes.append(extra)
	var talent := Talent.new()
	talent.id = "test.extra"
	talent.stat_modifiers = [extra]
	var base := BuildResolver.resolve_stats(load("res://data/classes/rogue.tres"), [], [talent], [gear])
	var p: PlayerStats = Contracts.apply_passives(base, 3, false)
	check(base.bonus_footwork_stacks == 2 and p.bonus_footwork_stacks == 11 and p.bonus_bypass_stacks == 11, "gear/talent/Death Touch extra stacks feed both buffs exactly once")
	p.bypass_enabled = true
	p.special_effects["double_applied_stacks"] = true
	var buffs := Buffs.new(p)
	buffs.grant_touch(2, 0, {})
	check(is_equal_approx(buffs.live_player(p).attack_speed, p.attack_speed + 0.2), "Touch conversion ignores extra stacks and doubling")
	buffs.state.reset(1, "invalid_simulation")
	check(buffs.state.snapshot().is_empty() and buffs.live_player(p).attack_speed == p.attack_speed, "invalid cleanup removes temporary stat sources")
	var invalid := Contracts.skill("touch_of_darkness")
	invalid.category = Skill.Category.ATTACK
	check(not CombatResolver.resolve([invalid], p, Monster.new(), 500).is_valid, "invalid Touch category rejected")

func _grant_count(result, id: String) -> int:
	var count := 0
	for row in result.trace.records:
		if row.kind == "effect_lifecycle" and row.payload.effect_id == id and row.lifecycle_reason == "granted":
			count += 1
	return count

func _final_boundaries() -> void:
	var p := PlayerStats.new()
	p.footwork_rank = 5
	p.riposte_rank = 2
	p.bonus_footwork_stacks = 2
	p.special_effects = {"double_applied_stacks": true}
	var quick := hit("skill.quick_cut", 100)
	var plunge := hit("skill.leaping_plunge", 1000, 500)
	var result := CombatResolver.resolve([quick, plunge], p, Monster.new(), 600, 7, true)
	check(result.cast_events[1].lifecycle_snapshot.footwork_consumed == 5 and result.cast_events[1].lifecycle_snapshot.riposte_multiplier == 3.0, "doubled Footwork clips to five and rank-two Riposte triples Plunge")
	var hold := hit("skill.hold", 3000)
	result = CombatResolver.resolve([quick, hold, plunge], p, Monster.new(), 3600, 7, true)
	check(result.cast_events[2].lifecycle_snapshot.riposte_multiplier == 3.0, "Riposte shares inclusive Footwork expiry consumption")
	hold.base_execution_ms = 3001
	result = CombatResolver.resolve([quick, hold, plunge], p, Monster.new(), 4101, 7, true)
	check(result.cast_events[2].lifecycle_snapshot.riposte_multiplier == 1.0, "expired Footwork cannot boost Riposte")
	result = CombatResolver.resolve([quick, plunge], p, Monster.new(), 599, 7, true)
	check(result.cast_events.size() == 1, "clipped Plunge cannot consume or gain Riposte")
	for row in result.trace.records:
		check(row.lifecycle_reason != "consumed", "clipped Plunge keeps consumption out of diagnostics")
	# A proc Stab can grant Bypass; an interrupted Stab cannot refresh it.
	p.bypass_enabled = true
	var stab := hit("skill.stab", 500)
	var trigger := TriggeredSkillEffect.new()
	trigger.skill = stab
	trigger.chance = 1.0
	trigger.source_skill_ids = ["skill.quick_cut"]
	p.triggered_skill_effects = [trigger]
	result = CombatResolver.resolve([quick], p, Monster.new(), 100, 7, true)
	check(_grant_count(result, "bypass") == 1, "proc Stab grants Bypass")
	p.triggered_skill_effects = []
	var target := Monster.new()
	target.interrupt_skip_count = 1
	result = CombatResolver.resolve([stab], p, target, 1500, 7, true)
	check(result.cast_events[2].was_interrupted, "interruption fixture")
	for row in result.trace.records:
		check(not (row.kind == "effect_lifecycle" and row.payload.effect_id == "bypass" and row.time_ms == 1500 and row.lifecycle_reason == "refreshed"), "interrupted Stab does not refresh Bypass")
	# Bypass's elemental bucket participates in live Shadow Mastery copying.
	p = PlayerStats.new()
	p.bypass_enabled = true
	p.bonus_bypass_stacks = 2
	p.base_poison_damage = 10.0
	p.stat_derivations = [{"source_id": "talent.shadow.shadow_mastery", "kind": "shadow_mastery", "fraction": 0.5}]
	var buffs := Buffs.new(p)
	buffs.finish_cast("skill.stab", true, 0, {})
	check(is_equal_approx(buffs.live_player(p).physical_damage_multiplier, 1.15), "Bypass participates in live Shadow Mastery percentage copying")
	buffs.state.advance(3000)
	check(buffs.stats.snapshot().physical_damage_multiplier == 1.0, "Bypass expiry removes derived physical benefit")
	var derived: PlayerStats = buffs.stats.snapshot()
	derived.riposte_rank = 2
	derived.death_blade_enabled = true
	var composed := Buffs.new(derived)
	composed.grant_touch(2, 0, {})
	check(composed.live_player(derived).riposte_rank == 2 and composed.live_player(derived).death_blade_enabled, "temporary stats preserve opt-in descriptors added after build resolution")
	# Thirty-second cooldown prevents normal twelve-second Touch overlap.
	p = PlayerStats.new()
	p.poison_tick_interval_multiplier = 100.0
	var fuel := Contracts.skill("poison_vile")
	fuel.base_execution_ms = 500
	var touch := Contracts.skill("touch_of_darkness")
	result = CombatResolver.resolve([fuel, touch], p, Monster.new(), 40000, 7, true)
	var previous_expiry := -1
	var touch_count := 0
	for row in result.trace.records:
		if row.kind == "effect_lifecycle" and String(row.payload.effect_id).begins_with("touch.") and row.lifecycle_reason == "granted":
			check(row.time_ms >= previous_expiry, "normal Touch cooldown prevents overlap")
			previous_expiry = row.payload.after.expires_at_ms
			touch_count += 1
	check(touch_count == 2, "normal cooldown permits a later independent Touch")
	# Final cleanup observes a deadline even when no cast/tick lands on it.
	p.poison_tick_interval_multiplier = 1000.0
	var wait := hit("skill.hold", 100000)
	result = CombatResolver.resolve([fuel, touch, wait], p, Monster.new(), 13000, 7, true)
	var expired := false
	for row in result.trace.records:
		if row.kind == "effect_lifecycle" and String(row.payload.effect_id).begins_with("touch.") and row.lifecycle_reason == "expired":
			expired = true
	check(expired and result.talent_buffs.state.snapshot().is_empty(), "fight-end deadline expires Touch before cleanup")
