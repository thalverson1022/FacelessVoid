extends SceneTree
## Focused live-resolver contract: Dance guarantees macro attacks only.
## Run in a disposable project; no player save access.
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAILED: " + message)


func player() -> PlayerStats:
	var stats := PlayerStats.new()
	stats.dance_duration_ms = 5000
	stats.shred_value = 60.0
	return stats


func target() -> Monster:
	var monster := Monster.new()
	monster.hp = 999999999
	return monster


func skill(id: String, category: Skill.Category = Skill.Category.ATTACK) -> Skill:
	var value := Skill.new()
	value.id = id
	value.category = category
	value.base_execution_ms = 100
	value.min_execution_ms = 100
	return value


func dance() -> Skill:
	return skill("skill.dance_of_death", Skill.Category.SELF_BUFF)


func attack() -> Skill:
	var value := skill("fixture.attack")
	var hit := PhysicalDamageEffect.new()
	hit.amount = 25.0
	value.effects = [hit]
	return value


func shred() -> Skill:
	var value := skill("fixture.shred", Skill.Category.DEBUFF)
	var effect := ArmorReductionEffect.new()
	effect.amount = 3
	value.effects = [effect]
	return value


func count_origin(result: CombatResolver.CombatResult, origin: String) -> int:
	var count := 0
	for event in result.cast_events:
		if event.origin_kind == origin:
			count += 1
	return count


func nonattacks() -> void:
	var poison_only := skill("fixture.poison_only")
	var poison := PoisonDamageEffect.new()
	poison.stacks_applied = 1
	poison_only.effects = [poison]
	var debuff_with_hit := attack()
	debuff_with_hit.id = "fixture.debuff_with_hit"
	debuff_with_hit.category = Skill.Category.DEBUFF
	var buff_with_hit := attack()
	buff_with_hit.id = "fixture.buff_with_hit"
	buff_with_hit.category = Skill.Category.SELF_BUFF
	var ex: Skill = load("res://data/skills/exsanguinate.tres")
	var cases: Array[Skill] = [shred(), skill("fixture.buff", Skill.Category.SELF_BUFF),
		skill("fixture.empty_attack"), poison_only, debuff_with_hit, buff_with_hit, ex]
	for nonattack in cases:
		var result := CombatResolver.resolve([dance(), nonattack], player(), target(), 100 + nonattack.base_execution_ms, 22, true)
		check(result.is_valid and result.cast_events.size() == 2, nonattack.id + " emits no Dance repeat")
		for event in result.cast_events:
			check(event.lifecycle_snapshot.get("guaranteed_repeat_sources", PackedStringArray()).is_empty(), event.skill.id + " has no attack guarantee")
		check(count_origin(result, "guaranteed_repeat") == 0, nonattack.id + " has no guaranteed child")
	# A real Shred payload makes an accidental Exsanguinate repeat observable in health loss.
	var fueled := CombatResolver.resolve([dance(), shred(), ex], player(), target(), 500, 22, true)
	check(fueled.is_valid and fueled.cast_events.size() == 3, "fueled Exsanguinate casts once under Dance at zero numeric chance")
	check(fueled.total_health_removed == 180.0 and fueled.cast_events.back().stat_snapshot.actual_consumed == 3, "one Exsanguinate removes health and consumes its three Shred once")


func connected_and_dodged_attacks() -> void:
	var stack_attack := skill("fixture.stack_attack")
	var hit := StackScalingPhysicalDamageEffect.new()
	hit.damage_per_stack = 10.0
	stack_attack.effects = [hit]
	for strike in [attack(), stack_attack]:
		var connected := CombatResolver.resolve([dance(), strike], player(), target(), 200, 22, true)
		check(connected.is_valid and connected.cast_events.size() == 3, strike.id + " receives one Dance repeat")
		check(connected.cast_events[1].lifecycle_snapshot.guaranteed_repeat_sources == PackedStringArray(["dance"]), strike.id + " records Dance at cast start")
		check(count_origin(connected, "guaranteed_repeat") == 1 and count_origin(connected, "random_repeat") == 0, strike.id + " cannot inherit Dance recursively")
	var blocked_target := target()
	blocked_target.block = 100000
	var blocked := CombatResolver.resolve([dance(), attack()], player(), blocked_target, 200, 22, true)
	check(blocked.is_valid and blocked.cast_events.size() == 3 and blocked.total_damage == 0.0, "fully blocked connected attack still repeats")
	var dodge_target := target()
	dodge_target.dodge_chance = 1.0
	var dodged := CombatResolver.resolve([dance(), attack()], player(), dodge_target, 200, 22, true)
	check(dodged.is_valid and dodged.cast_events.size() == 2 and dodged.cast_events[1].was_dodged, "dodged attack emits no repeat")
	var suppression := false
	for row in dodged.trace.records:
		if row.kind == "trigger_decision" and row.payload.reason == "guarantee_suppressed":
			suppression = row.payload.cause == "dodge"
	check(suppression, "dodge suppression remains diagnosed")
	var proc := TriggeredSkillEffect.new()
	proc.skill = attack()
	proc.skill.id = "fixture.proc_attack"
	proc.source_skill_ids = PackedStringArray(["fixture.attack"])
	proc.chance = 1.0
	var stats := player()
	stats.triggered_skill_effects = [proc]
	var triggered := CombatResolver.resolve([dance(), attack()], stats, target(), 200, 22, true)
	check(triggered.is_valid and count_origin(triggered, "proc") == 2 and count_origin(triggered, "guaranteed_repeat") == 1, "authored attacks triggered by macro and repeat receive no separate Dance guarantee")
	for event in triggered.cast_events:
		if event.origin_kind == "proc":
			check(event.lifecycle_snapshot.guaranteed_repeat_sources.is_empty(), "proc attack has no macro-only Dance grant")


func ordinary_numeric_repeats() -> void:
	var stats := player()
	stats.retrigger_chance = 1.0
	var ex: Skill = load("res://data/skills/exsanguinate.tres")
	var on := CombatResolver.resolve([dance(), shred(), ex], stats, target(), 500, 22, true)
	check(on.is_valid and on.cast_events.size() == 3 and count_origin(on, "random_repeat") == 0, "Exsanguinate cannot repeat at 100 percent numeric chance")
	check(count_origin(on, "guaranteed_repeat") == 0 and on.total_health_removed == 180.0, "Exsanguinate removes health once with Dance and numeric chance")
	var consumed := 0
	for event in on.cast_events:
		if event.skill.id == ex.id:
			check(event.lifecycle_snapshot.guaranteed_repeat_sources.is_empty(), "Exsanguinate has no Dance grant")
			check(event.health_removed == 180.0 and event.origin_kind == "macro", "only the root Exsanguinate removes health")
			consumed += int(event.stat_snapshot.actual_consumed)
	check(consumed == 3, "Exsanguinate consumes three Shred once")
	var source := CombatResolver.CastEvent.new()
	source.skill = ex
	source.lifecycle_snapshot = {"guaranteed_repeat_sources": PackedStringArray(["precision", "dance"])}
	check(CombatResolver._triggers_for_source(source, stats).is_empty(), "even an explicit guarantee cannot make Exsanguinate repeat")
	var replay := CombatResolver.resolve([dance(), shred(), ex], stats, target(), 500, 22, true)
	var off := CombatResolver.resolve([dance(), shred(), ex], stats, target(), 500, 22)
	check(on.trace.records == replay.trace.records, "same seed replays the exact numeric trace")
	check(on.rng_final_state == off.rng_final_state and on.total_health_removed == off.total_health_removed, "trace does not alter RNG or removal")
	stats.retrigger_chance = 0.0
	var no_chance := CombatResolver.resolve([dance(), shred(), ex], stats, target(), 500, 22, true)
	check(on.rng_final_state == no_chance.rng_final_state and on.trigger_candidates_evaluated == 0, "Exsanguinate performs no phantom repeat trial or RNG draw")
	stats.retrigger_chance = 1.0
	stats.dance_duration_ms = 0
	var ordinary := CombatResolver.resolve([attack()], stats, target(), 100, 22, true)
	check(ordinary.is_valid and ordinary.cast_events.size() == 17 and count_origin(ordinary, "random_repeat") == 16, "ordinary attack numeric repeats remain depth bounded")


func run() -> void:
	nonattacks()
	connected_and_dodged_attacks()
	ordinary_numeric_repeats()
	print("T10 Dance attack-only repeats: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAILED", checks])
	quit(0 if failures.is_empty() else 1)
