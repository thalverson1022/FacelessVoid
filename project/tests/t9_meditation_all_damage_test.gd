extends SceneTree
## Focused live-combat regression for Meditation's all-damage revision.
## Run only in a disposable T9 project; never reads or writes player saves.
const Poison = preload("res://scripts/systems/p6_poison_contracts.gd")
const Text = preload("res://scripts/ui/combat_effect_text.gd")
const Buff = preload("res://scripts/resources/self_buff_effect.gd")
var failures: Array[String] = []
var checks := 0
var witnesses: Dictionary = {}

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAILED: " + message)

func near(actual: float, expected: float, message: String) -> void:
	check(is_equal_approx(actual, expected), "%s: actual=%s expected=%s" % [message, actual, expected])

func player(config: Dictionary = {}) -> PlayerStats:
	var p := PlayerStats.new()
	p.weapon_damage_min = 100
	p.weapon_damage_max = 100
	p.base_poison_damage = 100.0
	p.poison_damage_per_tick = 100.0
	p.retrigger_chance = 1.0
	p.special_effects = {"legendary": config.merged({"samurai": true})}
	return p

func target() -> Monster:
	var m := Monster.new()
	m.hp = 999999999
	return m

func skill(id: String, category: Skill.Category = Skill.Category.ATTACK, time_ms: int = 100) -> Skill:
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
	return s

func fuel(stacks: int) -> Skill:
	var s := skill("fixture.poison", Skill.Category.DEBUFF)
	var effect := PoisonDamageEffect.new()
	effect.stacks_applied = stacks
	s.effects = [effect]
	return s

func rows(r: CombatResolver.CombatResult, kind: String) -> Array:
	return r.trace.records.filter(func(row): return row.kind == kind)

func repeat_multiplier(index: int, crown: bool = false) -> float:
	# A completed repeat grants its stack after its own damage resolves.
	return 1.0 + (0.4 if crown else 0.2) * clampi(index - 1, 0, 5)

func physical_and_natural() -> void:
	for crown in [false, true]:
		var p := player()
		p.legendary_crown = crown
		var r := CombatResolver.resolve([skill("fixture.hit"), fuel(8), skill("skill.hold", Skill.Category.DEBUFF, 5000)], p, target(), 4000, 19, true)
		check(r.is_valid and r.cast_events.size() == 18, "live attack resolves root, sixteen repeats and Poison setup")
		for i in mini(17, r.cast_events.size()):
			near(r.cast_events[i].physical_damage, 100.0 * repeat_multiplier(i, crown), "physical recursive damage applies one additive factor at index %d" % i)
		check(r.tick_events.size() == 4, "four natural Poison ticks cross the shared expiry")
		for i in r.tick_events.size():
			near(r.tick_events[i].raw_damage, (300.0 if crown else 200.0) if i < 3 else 100.0, "natural Poison reads current Meditation at tick %d" % i)
			near(r.tick_events[i].damage, r.tick_events[i].raw_damage, "natural Poison multiplier is applied once")
		check(rows(r, "legendary_buff_grant").size() == 16, "all physical repeats still grant and refresh at cap")
		check(rows(r, "legendary_buff_expired").size() == 1, "natural tick observes shared Meditation expiry")
		near(p.temporary_physical_multiplier, 1.0, "combat never mutates source physical multiplier")
		near(p.poison_damage_per_tick, 100.0, "combat never rebakes source Poison damage")
		witnesses["physical_natural_crown_" + str(crown)] = {"casts": r.cast_events.size(), "ticks": r.tick_events.map(func(t): return {"time": t.time_ms, "raw": t.raw_damage, "damage": t.damage})}

func natural_coil() -> void:
	for crown in [false, true]:
		var p := player({"coil": true})
		p.legendary_crown = crown
		var r := CombatResolver.resolve([fuel(4), skill("skill.hold", Skill.Category.DEBUFF, 5000)], p, target(), 1000, 7, true)
		check(r.is_valid and r.tick_events.size() == 17, "live natural tick produces sixteen free Coil repeats")
		var consumed := 0
		for i in r.tick_events.size():
			var tick := r.tick_events[i]
			consumed += tick.stacks_consumed
			near(tick.raw_damage, 100.0 * repeat_multiplier(i, crown), "Poison independently observes each additive stack index %d" % i)
			near(tick.damage, tick.raw_damage, "recursive Poison never compounds prior packet damage")
			check(tick.legendary_fuel == 1 and tick.stacks_remaining == 3, "free repeats preserve one-stack fuel without consuming remaining Poison")
		check(consumed == 1 and rows(r, "legendary_buff_grant").size() == 16, "natural repeats consume once and still grant Meditation")
		witnesses["natural_coil_crown_" + str(crown)] = r.tick_events.map(func(t): return {"depth": t.legendary_depth, "raw": t.raw_damage, "consumed": t.stacks_consumed})

func forced_and_exact_poison_expiry() -> void:
	var strike := Poison.poison_strike()
	strike.base_execution_ms = 100
	strike.min_execution_ms = 100
	var r := CombatResolver.resolve([skill("fixture.hit"), fuel(4), strike], player(), target(), 300, 19, true)
	var active := r.tick_events.filter(func(t): return t.had_active_stack)
	check(r.is_valid and active.size() == 4, "ordinary forced activations retain single-stack fuel on skill repeats")
	for tick in active:
		check(tick.origin_kind == "forced_tick" and tick.stacks_consumed == 1, "ordinary forced Poison remains distinct from free Coil repeat")
		near(tick.raw_damage, 200.0, "ordinary forced Poison receives capped Meditation once")
	check(rows(r, "legendary_poison_consume").is_empty(), "ordinary forced depletion remains outside keyword Consume")
	r = CombatResolver.resolve([skill("fixture.hit", Skill.Category.ATTACK, 1000), fuel(4), skill("skill.hold", Skill.Category.DEBUFF, 5000)], player(), target(), 4000, 19, true)
	check(r.is_valid and r.tick_events.size() == 4, "natural clock includes tick exactly at shared Meditation deadline")
	check(not r.tick_events[0].had_active_stack, "natural tick precedes first attack at same timestamp")
	near(r.tick_events[1].raw_damage, 200.0, "natural Poison receives capped bonus before expiry")
	near(r.tick_events[2].raw_damage, 200.0, "natural Poison retains bonus through last pre-expiry tick")
	near(r.tick_events[3].raw_damage, 100.0, "Poison at exact 4000ms expiry loses bonus before damage")
	witnesses.exact_poison_expiry = r.tick_events.map(func(t): return {"time": t.time_ms, "raw": t.raw_damage})

func consumed_coil() -> void:
	var p := player({"coil": true, "decrepit": true})
	p.elemental_damage_multiplier = 2.0
	p.poison_damage_per_tick = 200.0
	p.physical_damage_multiplier = 3.0
	p.critical_poison_enabled = true
	p.crit_chance = 1.0
	p.special_effects.damage_conversion = {"physical": true, "magical": true}
	var virulent := skill("skill.virulent_poison", Skill.Category.SELF_BUFF)
	var effect := Buff.new()
	effect.kind = "virulent_poison"
	virulent.effects = [effect]
	var strike := Poison.poison_strike()
	strike.base_execution_ms = 100
	strike.min_execution_ms = 100
	var m := target()
	m.armor = 100
	m.poison_resistance = 0.25
	m.block = 5.0
	m.absorb = 7.0
	var r := CombatResolver.resolve([virulent, fuel(4), strike], p, m, 300, 7, true)
	var ticks := r.tick_events.filter(func(t): return t.had_active_stack)
	check(r.is_valid and ticks.size() == 17, "actual Poison Strike consumes all fuel and resolves sixteen free repeats")
	var consumed := 0
	for i in ticks.size():
		var tick: CombatResolver.TickEvent = ticks[i]
		consumed += tick.stacks_consumed
		var expected_raw := 200.0 * 4.0 * (2.0 if i < 5 else 1.0) * repeat_multiplier(i)
		near(tick.raw_damage, expected_raw, "all-stack live Virulent calculation includes Meditation exactly once index %d" % i)
		# Crit, armor/block, then resistance/absorb; converted Poison never
		# acquires the player's independent x3 physical damage bucket.
		var expected_damage: float = round(((expected_raw * 2.0 * 0.625) - 5.0) * 0.75 - 7.0)
		near(tick.damage, expected_damage, "conversion and defenses follow one all-damage factor index %d" % i)
		check(tick.legendary_fuel == 4 and tick.is_crit, "free consumed-Poison repeats retain fuel and fresh talent-enabled crit")
	check(consumed == 4 and rows(r, "legendary_poison_consume").size() == 1, "all-stack Consume occurs once across recursive chain")
	check(ticks[4].charge_spends.size() == 1 and ticks[5].charge_spends.is_empty(), "Virulent charges still exhaust after five activations")
	witnesses.consumed_coil = ticks.map(func(t): return {"depth": t.legendary_depth, "raw": t.raw_damage, "damage": t.damage, "consumed": t.stacks_consumed})

func grants_and_exact_expiry() -> void:
	for crown in [false, true]:
		var p := player({"all_stacks": 1})
		p.legendary_crown = crown
		p.special_effects.double_applied_stacks = true
		p.increased_buff_duration = 0.3334
		var r := CombatResolver.CombatResult.new()
		r.trace.enabled = true
		CombatResolver._legendary_grant(r, p, "meditation", 100, {})
		check(r.legendary_buffs.meditation.stacks == 4, "All Stacks precedes doubling; Crown leaves grants unchanged")
		near(CombatResolver._legendary_live(r, p, 100).temporary_physical_multiplier, 2.6 if crown else 1.8, "Crown doubles Meditation bonus strength only")
		CombatResolver._legendary_grant(r, p, "meditation", 200, {})
		CombatResolver._legendary_grant(r, p, "meditation", 300, {})
		check(r.legendary_buffs.meditation.stacks == 5 and r.legendary_buffs.meditation.expires_at_ms == 4301, "cap five refreshes all stacks with ceiling-scaled 3s duration")
		near(CombatResolver._legendary_live(r, p, 4300).temporary_physical_multiplier, 3.0 if crown else 2.0, "all stacks retain normal or Crown strength one millisecond before expiry")
		check(Text.magnitude_for("buff.meditation", r.legendary_buffs.meditation) == ("All damage multiplier: ×3.0" if crown else "All damage multiplier: ×2.0"), "inspector reports the actual Crown-amplified bonus")
		near(CombatResolver._legendary_live(r, p, 4301).temporary_physical_multiplier, 1.0, "all stacks expire before equal-time damage read")
		check(r.legendary_buffs.is_empty(), "shared expiry removes complete Meditation state")
	check(Text.rule_for("buff.meditation").contains("20% more damage"), "Meditation rule describes all damage")
	check(Text.magnitude_for("buff.meditation", {"magnitude": 1.0}) == "All damage multiplier: ×2.0", "live Meditation magnitude describes all damage")

func health_removal_exclusion() -> void:
	var shred := skill("fixture.shred", Skill.Category.DEBUFF)
	var effect := ArmorReductionEffect.new()
	effect.amount = 3
	shred.effects = [effect]
	var ex := skill("skill.exsanguinate", Skill.Category.DEBUFF)
	ex.effects = [preload("res://scripts/resources/exsanguinate_effect.gd").new()]
	var p := player({"all_stacks": 5})
	p.legendary_crown = true
	var r := CombatResolver.resolve([skill("fixture.hit"), shred, ex], p, target(), 300, 19, true)
	var removals := r.cast_events.filter(func(e): return e.skill.id == "skill.exsanguinate")
	check(r.is_valid and removals.size() == 1, "Exsanguinate remains unable to retrigger")
	for event in removals:
		near(event.health_removed, 30.0, "Meditation never multiplies captured pure health removal")
		near(event.physical_damage, 0.0, "health removal remains outside ordinary damage")
	var last_grant: Dictionary = rows(r, "legendary_buff_grant").back().payload.after
	check(is_equal_approx(last_grant.magnitude, 2.0) and last_grant.expires_at_ms > removals[0].time_ms, "Crown Meditation grant is capped at +200% and unexpired during health removal")
	check(rows(r, "legendary_buff_grant").size() == 16, "only preceding attack repeats grant Meditation; Exsanguinate grants none")

func run() -> void:
	physical_and_natural()
	natural_coil()
	forced_and_exact_poison_expiry()
	consumed_coil()
	grants_and_exact_expiry()
	health_removal_exclusion()
	DirAccess.make_dir_recursive_absolute("res://reports/t9_meditation_revision")
	var file := FileAccess.open("res://reports/t9_meditation_revision/witnesses.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "witnesses": witnesses}, "\t"))
	file.close()
	print("T9_MEDITATION_ALL_DAMAGE %s checks=%d failures=%d" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
