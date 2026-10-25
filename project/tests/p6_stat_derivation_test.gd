extends SceneTree
const Rule = preload("res://scripts/resources/stat_derivation_rule.gd")
const State = preload("res://scripts/systems/combat_stat_state.gd")
const Trace = preload("res://scripts/systems/combat_event_trace.gd")
var failed := false

func _initialize() -> void:
	_check_formulas()
	_check_core_bladedancer()
	_check_shadow_buckets()
	_check_ranked_rules()
	_check_temporary_sources()
	_check_caps_and_source_order()
	_check_damage_and_trace()
	print("P6 T3 stat derivation: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + message)

func near(actual: float, expected: float, message: String) -> void:
	check(is_equal_approx(actual, expected), "%s: expected %s, got %s" % [message, expected, actual])

func modifier(id: String, amount: float) -> StatModifier:
	var item := StatModifier.new()
	item.stat_id = id
	item.value = amount
	return item

func talent(kind: String, fraction: float) -> Talent:
	var item := Talent.new()
	item.id = "test." + kind
	var rule := Rule.new()
	rule.kind = kind
	rule.fraction = fraction
	item.stat_derivations = [rule]
	return item

func base_class() -> ClassDef:
	var item := ClassDef.new()
	item.id = "test.class"
	item.base_stats = PlayerStats.new()
	item.base_stats.poison_damage_per_tick = 10.0
	item.base_stats.crit_chance = 0.2
	return item

func _check_formulas() -> void:
	var intrinsic := SubclassTree.new()
	intrinsic.id = "test.intrinsic"
	intrinsic.innate_modifiers = [modifier(StatCatalog.CHANCE_FOR_RETRIGGER, 0.05)]
	var weapon := GearItem.new()
	weapon.id = "test.gear"
	weapon.affixes = [modifier(StatCatalog.CHANCE_FOR_RETRIGGER, 0.25),
		modifier(StatCatalog.INCREASED_GOLD, 2.0), modifier(StatCatalog.INCREASED_MAGIC_FIND, 1.5)]
	for rank in [1, 2]:
		var stats := BuildResolver.resolve_stats(base_class(), [intrinsic], [talent("double_dip", rank * 0.5)], [weapon])
		near(stats.crit_chance, [0.35, 0.5][rank - 1], "Double Dip rank " + str(rank))
		near(stats.retrigger_chance, 0.3, "Double Dip retains retrigger")
	for rank in range(1, 6):
		var stats := BuildResolver.resolve_stats(base_class(), [], [talent("fast_hands", rank * 0.1), talent("fill_your_pockets", rank * 0.2)], [weapon])
		near(stats.attack_speed, [0.2, 0.4, 0.6, 0.8, 1.0][rank - 1], "Fast Hands rank " + str(rank))
		near(stats.elemental_damage_multiplier, [1.3, 1.6, 1.9, 2.2, 2.5][rank - 1], "Fill Your Pockets rank " + str(rank))
		near(stats.gold_reward_multiplier, 3.0, "Fast Hands keeps source gold bonus")
		near(stats.magic_find, 1.5, "Fill Your Pockets keeps Magic Find")
	var gold_talent := talent("fast_hands", 0.5)
	gold_talent.stat_modifiers = [modifier(StatCatalog.INCREASED_GOLD, 1.0)]
	var gold_stats := BuildResolver.resolve_stats(base_class(), [], [gold_talent], [weapon])
	near(gold_stats.gold_reward_multiplier, 6.0, "gold retains gear-then-talent buckets")
	near(gold_stats.attack_speed, 2.5, "Fast Hands reads final +500%, excluding baseline")

func _check_shadow_buckets() -> void:
	var elemental := Talent.new()
	elemental.id = "test.elemental"
	elemental.stat_modifiers = [modifier(StatCatalog.PERCENT_ELEMENTAL_DAMAGE, 0.5)]
	var gear := GearItem.new()
	gear.id = "test.elemental_gear"
	gear.affixes = [modifier(StatCatalog.PERCENT_ELEMENTAL_DAMAGE, 1.0), modifier(StatCatalog.BASE_ELEMENTAL_DAMAGE, 10.0)]
	for rank in [1, 5]:
		var stats := BuildResolver.resolve_stats(base_class(), [], [elemental, talent("shadow_mastery", rank * 0.1)], [gear])
		near(stats.elemental_damage_multiplier, 3.0, "normal elemental buckets retained")
		near(stats.bonus_base_elemental_damage, 10.0, "flat elemental retained")
		near(stats.bonus_physical_damage, float(rank), "only flat bonus is copied, not class poison base")
		near(stats.derived_physical_multiplier, 1.2 if rank == 1 else 2.0, "Shadow Mastery copies effective +200%")
		near(stats.poison_damage_per_tick, 60.0, "elemental output unchanged by copy")
	# The originally settled isolated +150% example is a separate x1.15.
	gear.affixes[0].value = 1.5
	var example := BuildResolver.resolve_stats(base_class(), [], [talent("shadow_mastery", 0.1)], [gear])
	near(example.derived_physical_multiplier, 1.15, "settled +150% example")
	gear.affixes.append(modifier(StatCatalog.INCREASED_MAGIC_FIND, 1.5))
	var a := talent("shadow_mastery", 0.1)
	var b := talent("fill_your_pockets", 1.0)
	var mixed := BuildResolver.resolve_stats(base_class(), [], [a, b], [gear])
	var reversed := BuildResolver.resolve_stats(base_class(), [], [b, a], [gear])
	near(mixed.elemental_damage_multiplier, 6.25, "Fill Your Pockets participates in normal elemental buckets")
	near(mixed.derived_physical_multiplier, 1.525, "Shadow Mastery sees Fill Your Pockets first")
	check(mixed.derivation_details == reversed.derivation_details, "dependency order independent of talent enumeration")
	gear.affixes = [modifier(StatCatalog.BASE_ELEMENTAL_DAMAGE, -4.0), modifier(StatCatalog.PERCENT_ELEMENTAL_DAMAGE, -0.5)]
	var negative := BuildResolver.resolve_stats(base_class(), [], [talent("shadow_mastery", 0.5)], [gear])
	near(negative.bonus_physical_damage, -2.0, "negative flat bonus remains signed")
	near(negative.derived_physical_multiplier, 0.75, "negative elemental bonus reduces copied benefit")
	# Fractional copied base is not rounded before it reaches packet calculation.
	gear.affixes = [modifier(StatCatalog.BASE_ELEMENTAL_DAMAGE, 3.0)]
	near(BuildResolver.resolve_stats(base_class(), [], [talent("shadow_mastery", 0.1)], [gear]).bonus_physical_damage, 0.3, "retain fractional copied base")

func _check_core_bladedancer() -> void:
	# Scalar-only first-slice fixture, not released Footwork or skill mechanics.
	var tree := SubclassTree.new()
	tree.id = "test.core_bladedancer"
	tree.ranked_content_ready = true
	tree.innate_modifiers = [modifier(StatCatalog.CHANCE_FOR_RETRIGGER, 0.05)]
	tree.primary_point_modifiers = [modifier(StatCatalog.CHANCE_FOR_RETRIGGER, 0.002)]
	var ranks := {}
	for entry in [["wet_stone", 4], ["rending_slash", 1], ["fancy_footwork", 5]]:
		var item := Talent.new()
		item.id = "test.core." + entry[0]
		item.max_ranks = entry[1]
		for index in range(item.max_ranks):
			var rank := TalentRank.new()
			if entry[0] == "wet_stone":
				rank.stat_modifiers = [modifier(StatCatalog.BASE_DAMAGE, float(index + 1))]
			item.ranks.append(rank)
		tree.talents.append(item)
		ranks[item.id] = item.max_ranks
	var other := SubclassTree.new()
	other.id = "test.other"
	other.ranked_content_ready = true
	var build := RankedBuild.new()
	check(build.configure(tree, other, 10, ranks), "core ten-point allocation")
	var gear := GearItem.new()
	gear.affixes = [modifier(StatCatalog.CHANCE_FOR_RETRIGGER, 0.25), modifier(StatCatalog.BASE_DAMAGE, 3.0)]
	var primary := BuildResolver.resolve_ranked_build(base_class(), build, [gear])
	check(primary.error == "", "core scalar resolution")
	near(primary.stats.retrigger_chance, 0.32, "core intrinsic plus primary points plus gear")
	near(primary.stats.bonus_physical_damage, 7.0, "Whetstone adds to gear base damage")
	check(build.set_practice_trees(other, tree), "core role reversal")
	var secondary := BuildResolver.resolve_ranked_build(base_class(), build, [gear])
	near(secondary.stats.retrigger_chance, 0.30, "secondary excludes primary scaling")
	near(tree.primary_point_modifiers[0].value, 0.002, "primary scaling source unmodified")

func _check_caps_and_source_order() -> void:
	var stats := BuildResolver.resolve_stats(base_class(), [], [talent("double_dip", 1.0), talent("shadow_mastery", 0.5)])
	# Sentinel for a separate guarantee, which T6 will implement; it is not chance.
	stats.derivation_base.special_effects["guaranteed_repeat"] = true
	var state := State.new(stats)
	check(state.snapshot().special_effects.get("guaranteed_repeat", false), "separate guarantee sentinel retained")
	near(state.snapshot().crit_chance, 0.2, "separate guaranteed effect does not become numeric chance")
	var capped: Array[StatModifier] = [modifier(StatCatalog.CHANCE_FOR_RETRIGGER, 2.0)]
	check(state.replace_source("chance", "test.chance", capped, 1) == "", "chance above cap input")
	near(state.snapshot().retrigger_chance, 1.0, "numeric retrigger cap")
	near(state.snapshot().crit_chance, 1.0, "copied crit cap")
	check(state.remove_source("chance", 2) == "", "remove capped source")
	near(state.snapshot().crit_chance, 0.2, "remove capped source restores baseline")
	var percent: Array[StatModifier] = [modifier(StatCatalog.PERCENT_ELEMENTAL_DAMAGE, 0.5)]
	check(state.replace_source("b", "test.b", percent, 3) == "", "first percent source")
	check(state.replace_source("a", "test.a", percent, 3) == "", "second percent source")
	near(state.snapshot().elemental_damage_multiplier, 2.25, "independent bonus sources multiply")
	near(state.snapshot().derived_physical_multiplier, 1.625, "copy combined temporary buckets")
	var reversed := State.new(stats)
	check(reversed.replace_source("a", "test.a", percent, 3) == "", "reverse insertion a")
	check(reversed.replace_source("b", "test.b", percent, 3) == "", "reverse insertion b")
	check(State.value_snapshot(reversed.snapshot()) == State.value_snapshot(state.snapshot()), "temporary insertion order irrelevant")
	var low: Array[StatModifier] = [modifier(StatCatalog.PERCENT_ELEMENTAL_DAMAGE, -1.0), modifier(StatCatalog.INCREASED_ATTACK_SPEED, -10.0)]
	check(state.replace_source("zero", "test.zero", low, 4) == "", "floor inputs")
	near(state.snapshot().elemental_damage_multiplier, 0.05, "final elemental multiplier floor")
	near(state.snapshot().derived_physical_multiplier, 0.525, "copy floored effective bonus")
	var skill := Skill.new()
	skill.base_execution_ms = 1000
	skill.min_execution_ms = 100
	check(state.cast_start_snapshot(skill).execution_ms == 20000, "speed floor remains at timing consumer")

func _check_ranked_rules() -> void:
	var tree := SubclassTree.new()
	tree.id = "test.ranked"
	tree.ranked_content_ready = true
	var item := talent("double_dip", 0.5)
	item.max_ranks = 2
	for fraction in [0.5, 1.0]:
		var rank := TalentRank.new()
		rank.stat_derivations = talent("double_dip", fraction).stat_derivations
		rank.stat_modifiers = [modifier(StatCatalog.CHANCE_FOR_RETRIGGER, 0.3)]
		item.ranks.append(rank)
	tree.talents = [item]
	var build := RankedBuild.new()
	check(build.configure(tree, null, 2), "ranked fixture configures")
	check(build.buy(item.id) and build.buy(item.id), "buy second complete rank")
	var resolved := BuildResolver.resolve_ranked_build(base_class(), build)
	check(resolved.error == "", "ranked derivation resolves")
	near(resolved.stats.crit_chance, 0.5, "rank 2 replaces rank 1 rather than adding fractions")
	near(item.ranks[0].stat_derivations[0].fraction, 0.5, "rank source resource unchanged")
	item.ranks[0].stat_derivations[0].fraction = NAN
	check(RankedBuild.content_error(tree) != "", "invalid unselected rank is rejected")
	var invalid := talent("double_dip", 1.5)
	var stats := BuildResolver.resolve_stats(base_class(), [], [invalid])
	check(stats.derivation_error != "", "invalid legacy rule rejected")
	var monster := Monster.new()
	var invalid_result := CombatResolver.resolve([], stats, monster, 1000, 1, true)
	check(not invalid_result.is_valid and invalid_result.failure.code == "invalid_stat_derivation", "no silent invalid formula simulation")
	var duplicate := BuildResolver.resolve_stats(base_class(), [], [talent("double_dip", 0.5), talent("double_dip", 1.0)])
	check(duplicate.derivation_error != "", "duplicate rule rejected")

func _check_temporary_sources() -> void:
	var stats := BuildResolver.resolve_stats(base_class(), [], [talent("double_dip", 1.0), talent("shadow_mastery", 0.5), talent("fill_your_pockets", 1.0)])
	var state := State.new(stats)
	check(state.initialization_error == "", "state accepts resolved build")
	var original := State.value_snapshot(state.snapshot())
	var trace := Trace.new()
	trace.enabled = true
	var source: Array[StatModifier] = [modifier(StatCatalog.CHANCE_FOR_RETRIGGER, 0.3), modifier(StatCatalog.BASE_ELEMENTAL_DAMAGE, 10.0), modifier(StatCatalog.INCREASED_MAGIC_FIND, 1.5)]
	check(state.replace_source("buff:1", "test.buff", source, 100, trace) == "", "add source")
	near(state.snapshot().crit_chance, 0.5, "temporary chance feeds Double Dip")
	near(state.snapshot().bonus_physical_damage, 5.0, "temporary flat bonus feeds Shadow Mastery")
	near(state.snapshot().derived_physical_multiplier, 1.75, "temporary Magic Find feeds both copies")
	check(state.replace_source("buff:1", "test.buff", source, 200, trace) == "", "replace same instance")
	near(state.snapshot().bonus_physical_damage, 5.0, "replacement does not double count")
	source[1].value = 99.0
	near(state.snapshot().bonus_physical_damage, 5.0, "caller modifier edits cannot mutate state")
	var retained_snapshot := state.snapshot()
	retained_snapshot.derivation_base.bonus_physical_damage = 1000
	near(state.snapshot().bonus_physical_damage, 5.0, "returned baseline snapshot is isolated")
	check(state.remove_source("buff:1", 300, trace) == "", "remove source")
	check(State.value_snapshot(state.snapshot()) == original, "removal restores raw baseline without accumulated copy")
	near(retained_snapshot.bonus_physical_damage, 5.0, "older snapshot remains fixed")
	check(state.remove_source("buff:missing", 300, trace) != "", "unknown removal rejected")
	var invalid: Array[StatModifier] = [modifier(StatCatalog.CHANCE_FOR_RETRIGGER, NAN)]
	check(state.replace_source("bad", "test.bad", invalid, 300, trace) != "", "NaN rejected atomically")
	check(trace.records.size() == 3 and State.value_snapshot(state.snapshot()) == original, "invalid changes leave stats and trace unchanged")
	check(state.replace_source("old", "test.old", [], 299, trace) != "", "backwards time rejected")
	check(trace.records[0].payload.after.bonus_physical_damage == 5.0, "trace before/after values fixed")
	check(trace.records[0].effect_instance_id == "buff:1", "temporary source identified in T2 envelope")
	# Rebase against changed gear while retaining active temporary sources.
	var flat: Array[StatModifier] = [modifier(StatCatalog.BASE_ELEMENTAL_DAMAGE, 2.0)]
	check(state.replace_source("buff:2", "test.flat", flat, 400) == "", "second source")
	var gear := GearItem.new()
	gear.affixes = [modifier(StatCatalog.BASE_ELEMENTAL_DAMAGE, 8.0)]
	var changed := BuildResolver.resolve_stats(base_class(), [], [talent("shadow_mastery", 0.5)], [gear])
	check(state.rebase(changed, 400) == "", "rebase after gear change")
	near(state.snapshot().bonus_physical_damage, 5.0, "new gear plus retained temporary source copied once")
	check(state.remove_source("buff:2", 500) == "", "remove after rebase")
	near(state.snapshot().bonus_physical_damage, 4.0, "remove restores changed gear baseline")

func _check_damage_and_trace() -> void:
	var skill := Skill.new()
	skill.id = "skill.stab"
	skill.base_execution_ms = 1000
	skill.min_execution_ms = 100
	var effect := PhysicalDamageEffect.new()
	effect.amount = 10.0
	skill.effects = [effect]
	var monster := Monster.new()
	monster.hp = 100000
	for rank in range(1, 6):
		var stats := BuildResolver.resolve_stats(base_class(), [], [talent("sharpened_edge", rank * 0.2)])
		stats.crit_chance = 0.0
		stats.weapon_damage_min = 10
		stats.weapon_damage_max = 10
		var off := CombatResolver.resolve([skill], stats, monster, 1000, 7)
		var on := CombatResolver.resolve([skill], stats, monster, 1000, 7, true)
		near(on.total_damage, [12.0, 14.0, 16.0, 18.0, 20.0][rank - 1], "Sharpened Edge real damage rank " + str(rank))
		check(on.cast_events.size() == 1 and on.cast_events[0].damage_contributions.size() == 1, "Sharpened Edge does not add a hit or RNG roll")
		check(on.total_damage == off.total_damage and on.rng_final_state == off.rng_final_state, "tracing does not change derived combat or RNG")
		near(on.cast_events[0].stat_snapshot.skill_damage_multiplier, 1.0 + rank * 0.2, "impact records actual skill multiplier")
		check(on.trace.records[0].kind == "build_stats" and not on.trace.records[0].payload.derivations.is_empty(), "combat carries source/derived explanations")
		var unrelated := skill.duplicate(true) as Skill
		unrelated.id = "test.unrelated"
		near(CombatResolver.resolve([unrelated], stats, monster, 1000, 7).total_damage, 10.0, "Sharpened Edge filters unrelated skills")
	# Start-time duration is a value snapshot; later damage and ticks use current stats.
	var initial := PlayerStats.new()
	initial.weapon_damage_min = 10
	initial.weapon_damage_max = 10
	initial.poison_damage_per_tick = 10.0
	var state := State.new(initial)
	var start := state.cast_start_snapshot(skill)
	var buff: Array[StatModifier] = [modifier(StatCatalog.INCREASED_ATTACK_SPEED, 1.0), modifier(StatCatalog.BASE_DAMAGE, 10.0), modifier(StatCatalog.BASE_ELEMENTAL_DAMAGE, 5.0)]
	check(state.replace_source("windup", "test.windup", buff, 500) == "", "change source during conceptual windup")
	check(start.execution_ms == 1000 and state.cast_start_snapshot(skill).execution_ms == 500, "existing windup fixed, next cast uses new speed")
	var event := CombatResolver.CastEvent.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	CombatResolver._apply_skill_effects(skill, event, state.snapshot(), monster, 0, 0.0, 0, 0, rng, "cast")
	near(event.physical_damage, 20.0, "impact uses updated damage")
	var result := CombatResolver.CombatResult.new()
	CombatResolver._resolve_poison_tick(result, 1000, 1, state.snapshot(), 0, 0.0, monster, 1000)
	near(result.tick_events[0].damage, 15.0, "poison tick uses updated elemental base")
	check(initial.bonus_physical_damage == 0.0 and initial.poison_damage_per_tick == 10.0, "input PlayerStats unchanged")
