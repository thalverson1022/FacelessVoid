extends "res://tests/p6_macro_scheduler_test.gd"
const TimerMath = preload("res://scripts/systems/combat_timer_math.gd")
const Buffs = preload("res://scripts/systems/combat_self_buffs.gd")
const Talents = preload("res://scripts/systems/combat_talent_buffs.gd")
const Defenses = preload("res://scripts/systems/combat_defense_debuffs.gd")
const Effects = preload("res://scripts/systems/combat_effect_state.gd")

func _initialize() -> void:
	_cooldowns()
	_durations()
	_overflow()
	print("T3 combat timing: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func _cooldowns() -> void:
	var clock := Scheduler.new()
	var skill := make_skill("test.cdr", 100)
	skill.cooldown_ms = 10000
	var factor := pow(0.712, 4) * pow(0.616, 4) * pow(0.508, 4)
	check(clock.start(skill, 100, factor) == "" and clock.available_at(skill.id) == 125, "accepted 99.7536 percent extreme gives 25ms")
	check(skill.cooldown_ms == 10000, "authored cooldown remains unchanged")
	check(clock.start(skill, 200, 0.0) == "" and clock.available_at(skill.id) == 201, "zero retained factor gives positive 1ms floor")
	var zero := make_skill("test.zero", 100)
	check(clock.start(zero, 300, 0.0) == "" and clock.available_at(zero.id) == 0, "authored zero gains no interval")
	var stats := PlayerStats.new()
	stats.cooldown_factor = 0.5
	var result := CombatResolver.resolve([skill, skill.duplicate(true)], stats, Monster.new(), 5400, 1, true)
	check(result.is_valid and result.cast_events[0].cooldown_available_at_ms == 5100, "resolved cooldown factor used by root scheduler")
	check(result.cast_events[1].cooldown_blocked and result.cast_events[1].time_ms == 200, "blocked slot still costs exactly 100ms")
	var activations := []
	for event in result.cast_events:
		if not event.cooldown_blocked:
			activations.append(event.time_ms)
	check(activations == [100, 5200], "same-ID slots share exact deadline and next windup")

func _durations() -> void:
	var player := PlayerStats.new()
	player.increased_buff_duration = 0.5
	player.death_pact_rank = 3
	player.bypass_enabled = true
	var defs := Defenses.new(player, 0, 0)
	check(defs.grant("penetration", 50, player, 100, {}).state.expires_at_ms == 9100, "Pact seconds precede duration scaling")
	check(defs.grant("penetration", 1, player, 200, {}).state.expires_at_ms == 9200, "positive grant refreshes at cap")
	check(defs.grant("penetration", 0, player, 300, {}).state.expires_at_ms == 9200, "zero grant does not refresh")
	check(defs.grant("potency", 1, player, 300, {}, true).state.expires_at_ms == 9300, "Consume defense grant has same scaled timer")
	var talents := Talents.new(player)
	check(talents.finish_cast("skill.stab", true, 100, {}) == "" and talents.state.snapshot("bypass").expires_at_ms == 4600, "Bypass 4500ms")
	check(talents.grant_touch(2, 100, {}) == "" and talents.state.snapshot("touch.1").expires_at_ms == 18100, "Touch 18000ms uses actual units")
	talents.grant_touch(1, 200, {})
	check(talents.state.snapshot("touch.1").units == 2 and talents.state.snapshot("touch.2").expires_at_ms == 18200, "Touch independent overlap")
	var buffs := Buffs.new(null, 0.5)
	check(buffs.grant("master_of_poisons", 100, {}) == "" and buffs.instances[0].expires_at_ms == 7600, "Master of Poisons 7500ms")
	buffs.grant("beguiling_presence", 200, {}, 4.0, 2)
	check(buffs.instances[1].expires_at_ms == 15200 and buffs.instances[1].units == 2, "Beguiling Presence 15000ms retains magnitude")
	buffs.grant("virulent_poison", 300, {})
	check(buffs.instances[2].expires_at_ms == -1 and buffs.instances[2].charges == 5, "Virulent remains untimed five charges")
	var dance := Lifecycle.new(1, true, null, null, {"dance": 5000, "precision": -1, "increased_buff_duration": 0.5})
	check(dance.finish_cast("skill.quick_cut", true, false, 100, 5) == "", "Footwork grant")
	check(dance.state.snapshot("footwork").expires_at_ms == 4600, "Footwork 4500ms")
	check(dance.begin_cast("skill.leaping_plunge", 1000, 0, 4600).footwork_consumed == 5, "Footwork inclusive exact cast-start boundary retained")
	dance.activate_dance(4600)
	dance.activate_dance(4700)
	check(dance.state.snapshot("dance").expires_at_ms == 12100 and dance.state.snapshot("dance.2").expires_at_ms == 12200, "Dance independent 7500ms instances")
	var used: Dictionary = defs.state.consume("penetration", 1, 400)
	check(used.error == "" and defs.state.snapshot("penetration").expires_at_ms == 9200, "partial consumption preserves expiry")
	check(TimerMath.scaled_duration(5000, 7.48).duration_ms == 42400, "duration is uncapped 8.48 multiplier")

func _overflow() -> void:
	check(TimerMath.scaled_duration(12000, 1e308).error != "", "finite duration multiplication overflow rejected")
	check(TimerMath.scaled_duration(1, 9223372036854775808.0).error != "", "rounded int64 limit rejected before conversion")
	check(TimerMath.deadline(TimerMath.INT64_MAX - 1, 1).expires_at_ms == TimerMath.INT64_MAX, "integer MAX boundary stays valid")
	check(TimerMath.deadline(TimerMath.INT64_MAX - 1, 2).error != "", "timestamp overflow rejected with integer arithmetic")
	var state := Effects.new()
	state.define("test", {"source_id": "test", "duration_ms": TimerMath.INT64_MAX, "cap": 1, "mode": "add", "unit": "stacks"})
	check(state.grant("test", 1, 1).error != "" and state.snapshot().is_empty(), "overflow grant creates no active instance")
	var stats := PlayerStats.new()
	stats.increased_buff_duration = 1e308
	check(not CombatResolver.resolve([make_skill("test", 100)], stats, Monster.new(), 200).is_valid, "timer overflow produces invalid simulation")
	stats = PlayerStats.new()
	stats.physical_damage_multiplier = 1e308
	check(not CombatResolver.resolve([make_skill("test", 100)], stats, Monster.new(), 200).is_valid, "finite inputs overflowing direct damage produce invalid simulation")
	stats.physical_damage_multiplier = 1e20
	var large := CombatResolver.resolve([make_skill("test", 100)], stats, Monster.new(), 100)
	check(large.is_valid and large.total_damage > 1e20, "large finite damage has no integer wrap or invented balance cap")
	var virulent := make_skill("test.virulent_stockpile", 1)
	virulent.category = Skill.Category.SELF_BUFF
	var effect := preload("res://scripts/resources/self_buff_effect.gd").new()
	effect.kind = "virulent_poison"
	virulent.effects = [effect]
	check(not CombatResolver.resolve([virulent], PlayerStats.new(), Monster.new(), 1100).is_valid, "unbounded stockpile overflow surfaces invalid simulation instead of a win")
