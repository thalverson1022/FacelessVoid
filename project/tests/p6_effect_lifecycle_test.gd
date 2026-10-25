extends SceneTree
const Effects = preload("res://scripts/systems/combat_effect_state.gd")
const Bladedancer = preload("res://scripts/systems/bladedancer_effect_lifecycle.gd")
const Stats = preload("res://scripts/systems/combat_stat_state.gd")
const Trace = preload("res://scripts/systems/combat_event_trace.gd")
var failed := false

func _initialize() -> void:
	_footwork()
	_readiness()
	_temporary_stats()
	_boundaries_and_validation()
	_simultaneous_expiry()
	_trace_equivalence()
	print("P6 T4 effect lifecycle: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + label)

func _footwork() -> void:
	var trace = Trace.new()
	trace.enabled = true
	var core = Bladedancer.new(5, true, null, trace)
	check(core.finish_cast("skill.quick_cut", true, false, 1000, 4) == "", "grant four")
	var first: Dictionary = core.state.snapshot("footwork")
	check(first.stacks == 4 and first.expires_at_ms == 4000, "shared timer")
	check(core.finish_cast("skill.quick_cut", true, true, 2000, 3) == "", "repeat grants")
	check(core.state.snapshot("footwork").stacks == 5, "hard cap clips bonus grant")
	core.finish_cast("skill.quick_cut", true, false, 2500)
	check(core.state.snapshot("footwork").expires_at_ms == 5500, "cap refresh")
	var cast: Dictionary = core.begin_cast("skill.leaping_plunge", 700, 500, 5500)
	check(cast.footwork_consumed == 5 and cast.execution_ms == 500, "inclusive consume and minimum")
	check(core.state.snapshot("footwork").is_empty(), "all consumed")
	core.finish_cast("skill.leaping_plunge", false, false, 6000)
	check(core.state.snapshot("footwork").is_empty(), "miss never refunds")
	core.finish_cast("skill.quick_cut", true, false, 6100, 5)
	var old_id: String = core.state.snapshot("footwork").instance_id
	core.finish_cast("skill.quick_cut", true, false, 9100)
	var fresh: Dictionary = core.state.snapshot("footwork")
	check(fresh.stacks == 1 and fresh.expires_at_ms == 12100 and fresh.instance_id != old_id, "grant at expiry creates fresh instance")
	check(first.stacks == 4 and first.expires_at_ms == 4000, "snapshots are immutable")
	core.state.advance(12101, true)
	check(core.state.snapshot("footwork").is_empty(), "entire buff expires")
	for rank in range(1, 6):
		var ranked = Bladedancer.new(rank)
		ranked.finish_cast("skill.quick_cut", true, false, 0, 5)
		var snapshot: Dictionary = ranked.begin_cast("skill.leaping_plunge", 2000, 500, 0)
		check(snapshot.execution_ms == maxi(500, 2000 - rank * 400), "rank timing " + str(rank))
	var three = Bladedancer.new(5)
	three.finish_cast("skill.quick_cut", true, false, 0, 3)
	check(three.begin_cast("skill.leaping_plunge", 2000, 500, 0).execution_ms == 800, "approved three-stack example")
	check(three.begin_cast("skill.leaping_plunge", 2000, 500, 0).execution_ms == 2000, "zero stack timing")

func _readiness() -> void:
	var core = Bladedancer.new(5, true)
	var unready: Dictionary = core.begin_cast("skill.parry_strike", 500, 300, 0)
	check(not unready.eligible and unready.execution_ms == 500, "unready spends cast time")
	core.finish_cast("skill.quick_cut", false, true, 100)
	check(core.state.snapshot().is_empty(), "dodged repeat grants nothing")
	core.finish_cast("skill.quick_cut", true, true, 200)
	check(not unready.eligible, "late grant cannot enable earlier cast")
	core.finish_cast("skill.quick_cut", true, true, 200)
	check(core.state.snapshot("readiness").charges == 1, "readiness cap")
	var ready: Dictionary = core.begin_cast("skill.parry_strike", 500, 300, 50000)
	check(ready.eligible and ready.readiness_consumed == 1, "readiness has no timer")
	var child: Dictionary = core.begin_cast("skill.parry_strike", 0, 0, 50500)
	check(not child.eligible, "child cannot consume future parent grant")
	core.finish_cast("skill.parry_strike", true, true, 50500)
	check(core.state.snapshot("readiness").charges == 1, "post-subtree connected repeat grant")
	core.state.reset(50500, "invalid_simulation")
	check(core.state.snapshot().is_empty(), "invalid fight cleanup")
	var retry = Bladedancer.new(5, true)
	check(retry.state.snapshot().is_empty(), "retry owns fresh state")

func _temporary_stats() -> void:
	var base := PlayerStats.new()
	base.bonus_base_elemental_damage = 10
	base.stat_derivations = [{"kind": "shadow_mastery", "fraction": 0.5, "source_id": "test.shadow"}]
	var stats = Stats.new(base)
	var trace = Trace.new()
	trace.enabled = true
	var effects = Effects.new(stats, trace)
	check(effects.define("test.buff", {"source_id": "test.buff", "duration_ms": 1000, "cap": 3,
		"mode": "add", "unit": "stacks", "magnitude_per_unit": 0.1,
		"stat_inputs": {StatCatalog.PERCENT_ELEMENTAL_DAMAGE: 0.1}}) == "", "define stat buff")
	effects.grant("test.buff", 3, 0)
	check(is_equal_approx(stats.snapshot().elemental_damage_multiplier, 1.3), "within-effect additive stacks")
	check(is_equal_approx(stats.snapshot().physical_damage_multiplier, 1.15), "T3 live derived copy")
	var old := stats.snapshot()
	effects.consume("test.buff", 1, 500)
	check(is_equal_approx(stats.snapshot().elemental_damage_multiplier, 1.2), "partial consumption updates source")
	check(effects.snapshot("test.buff").expires_at_ms == 1000, "consumption retains deadline")
	effects.advance(1000)
	check(is_equal_approx(stats.snapshot().elemental_damage_multiplier, 1.0), "expiry removes source")
	check(is_equal_approx(old.elemental_damage_multiplier, 1.3), "stat snapshot preserved")
	effects.grant("test.buff", 2, 1100)
	effects.reset(1200, "retry")
	check(is_equal_approx(stats.snapshot().physical_damage_multiplier, 1.0), "reset removes derived benefit")
	check(base.stat_sources.is_empty(), "source baseline untouched")
	check(trace.records.back().lifecycle_reason == "retry", "reset reason emitted")

func _boundaries_and_validation() -> void:
	var effects = Effects.new()
	var definition := {"source_id": "test.charge", "duration_ms": -1, "cap": 5, "mode": "replace", "unit": "charges"}
	check(effects.define("charges", definition) == "", "define charges")
	definition.cap = 99
	effects.grant("charges", 20, 0)
	check(effects.snapshot("charges").charges == 5, "definition copy and cap")
	effects.consume("charges", 2, 10)
	effects.grant("charges", 5, 20)
	check(effects.snapshot("charges").charges == 5, "reapplication replaces charges")
	effects.grant("charges", 0, 20)
	check(effects.snapshot("charges").charges == 5, "zero grant is no-op")
	check(effects.consume("charges", 99, 30).consumed == 5, "overconsumption bounded")
	check(effects.consume("charges", 1, 30).consumed == 0, "empty consumption")
	check(effects.grant("charges", 1, 29).error != "", "backwards time rejected")
	check(effects.grant("missing", 1, 30).error != "", "unknown effect rejected")
	check(effects.grant("charges", -1, 30).error != "", "negative grant rejected")
	check(effects.define("bad", {"source_id": "test", "duration_ms": 0, "cap": 1, "mode": "add", "unit": "charges"}) != "", "zero duration rejected")
	check(Bladedancer.new(6).initialization_error != "", "invalid rank rejected")

func _trace_equivalence() -> void:
	var results: Array[Dictionary] = []
	for enabled in [false, true]:
		var trace = Trace.new()
		trace.enabled = enabled
		var core = Bladedancer.new(5, true, null, trace)
		core.finish_cast("skill.quick_cut", true, true, 1000)
		var cast: Dictionary = core.begin_cast("skill.leaping_plunge", 2500, 500, 4000)
		core.state.reset(5000)
		results.append({"cast": cast, "state": core.state.snapshot(), "counts": trace.counts, "sequence": trace.sequence})
		if enabled:
			for event in trace.records:
				check(event.payload.has("before") and event.payload.has("after"), "lifecycle before/after envelope")
	check(results[0] == results[1], "trace on/off state equivalence")

func _simultaneous_expiry() -> void:
	var trace = Trace.new()
	trace.enabled = true
	var stats = Stats.new(PlayerStats.new())
	var effects = Effects.new(stats, trace)
	for id in ["z", "a"]:
		effects.define(id, {"source_id": "test." + id, "duration_ms": 1000, "cap": -1, "mode": "replace", "unit": "stacks", "stat_inputs": {StatCatalog.INCREASED_ATTACK_SPEED: 0.1}})
		effects.grant(id, 2, 0)
	check(is_equal_approx(stats.snapshot().attack_speed, 0.4), "independent source composition")
	check(effects.advance(5000) == "", "advance across multiple expirations")
	var removed: Array[String] = []
	for record in trace.records:
		if record.kind == "effect_lifecycle" and record.lifecycle_reason == "expired":
			removed.append(record.payload.effect_id)
			check(record.time_ms == 1000 and record.payload.stacks_after == 0, "actual expiry timestamp and zero state")
	check(removed == ["a", "z"], "stable tied expiry order")
	check(is_equal_approx(stats.snapshot().attack_speed, 0.0), "all sources removed")
	effects.grant("a", 0, 6000)
	check(effects.grant("a", 1, 5999).error != "", "zero grants still advance clock")
