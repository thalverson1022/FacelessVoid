extends RefCounted
## Fight-local scalar state. T4 owns lifetimes; T5 owns scheduled casts.
## Always rebuild from raw build inputs, never subtract from derived totals.
const Rule = preload("res://scripts/resources/stat_derivation_rule.gd")
const TEMP_FIELDS := {
	StatCatalog.BASE_DAMAGE: "bonus_physical_damage",
	StatCatalog.BASE_ELEMENTAL_DAMAGE: "bonus_base_elemental_damage",
	StatCatalog.INCREASED_ATTACK_SPEED: "attack_speed",
	StatCatalog.CRIT_CHANCE: "crit_chance",
	StatCatalog.CRIT_DAMAGE: "crit_multiplier",
	StatCatalog.CHANCE_FOR_RETRIGGER: "retrigger_chance",
	StatCatalog.INCREASED_GOLD: "gold_reward_multiplier",
	StatCatalog.INCREASED_MAGIC_FIND: "magic_find",
}
var initialization_error := ""
var _base: PlayerStats
var _current: PlayerStats
var _sources: Dictionary = {}
var _last_time_ms := 0


func _init(initial: PlayerStats = null) -> void:
	if initial != null:
		initialization_error = rebase(initial)


static func validate_rules(rules: Array[Dictionary]) -> String:
	var seen := {}
	for rule in rules:
		if rule.get("kind", "") not in Rule.KINDS or String(rule.get("source_id", "")).strip_edges() == "":
			return "Invalid derived-stat kind or source ID."
		var fraction: Variant = rule.get("fraction")
		if typeof(fraction) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(fraction)) or float(fraction) <= 0.0 or float(fraction) > 1.0:
			return "Invalid derived-stat fraction."
		if seen.has(rule.kind):
			return "Duplicate derived-stat rule: " + String(rule.kind)
		seen[rule.kind] = true
	return ""


func rebase(initial: PlayerStats, time_ms: int = 0, trace = null) -> String:
	if initial == null:
		return "Missing stat baseline."
	if initial.derivation_error != "":
		return initial.derivation_error
	var problem := validate_rules(initial.stat_derivations)
	if problem != "":
		return problem
	problem = _time_error(time_ms, trace)
	if problem != "":
		return problem
	var before := value_snapshot(_current) if _current != null else {}
	_base = (initial.derivation_base if initial.derivation_base != null else initial).duplicate(true)
	_base.derivation_base = null
	# Deep-copied resolved Resources can lose the runtime-only raw baseline.
	# Remove marked signatures before rebuilding those compatibility inputs.
	_base.attack_speed -= _base.legendary_added_ias
	_base.gear_physical_damage_multiplier -= _base.legendary_added_physical
	_base.bonus_physical_damage -= _base.legendary_added_flat
	if _base.physical_damage_uses_buckets:
		_base.sync_physical_damage_multiplier()
	_base.legendary_added_ias = 0.0
	_base.legendary_added_physical = 0.0
	_base.legendary_added_flat = 0.0
	if _base.legendary_coin_applied:
		_base.magic_find *= 0.5
		_base.legendary_coin_applied = false
	_base.stat_derivations = initial.stat_derivations.duplicate(true)
	_recompute()
	_last_time_ms = time_ms
	_record(trace, time_ms, "build.baseline", "", "rebased", before)
	return ""


func replace_source(instance_id: String, source_id: String, modifiers: Array[StatModifier], time_ms: int, trace = null, context: Dictionary = {}) -> String:
	if _base == null:
		return "Missing stat baseline."
	if instance_id.strip_edges() == "" or source_id.strip_edges() == "":
		return "Temporary stat sources require stable instance and content IDs."
	var problem := _time_error(time_ms, trace)
	if problem != "":
		return problem
	var values := {}
	for modifier in modifiers:
		if modifier == null or modifier.operation != StatModifier.OperationType.ADD or not is_finite(modifier.value):
			return "Temporary stat inputs must be finite additive amounts."
		var id := modifier.stat_id
		if not TEMP_FIELDS.has(id) and id not in [StatCatalog.PERCENT_PHYSICAL_DAMAGE, StatCatalog.PERCENT_ELEMENTAL_DAMAGE]:
			return "Unsupported temporary stat: " + id
		var strength := 2.0 if _base.legendary_crown and source_id in ["talent.assassin.bypass", "skill.touch_of_darkness", "skill.dash"] else 1.0
		values[id] = float(values.get(id, 0.0)) + modifier.value * strength
	var before := value_snapshot(_current)
	var reason := "replaced" if _sources.has(instance_id) else "added"
	_sources[instance_id] = {"source_id": source_id, "values": values}
	_recompute()
	_last_time_ms = time_ms
	_record(trace, time_ms, source_id, instance_id, reason, before, context)
	return ""


func remove_source(instance_id: String, time_ms: int, trace = null, context: Dictionary = {}) -> String:
	var problem := _time_error(time_ms, trace)
	if problem != "":
		return problem
	if not _sources.has(instance_id):
		return "Unknown temporary stat source: " + instance_id
	var before := value_snapshot(_current)
	var source_id: String = _sources[instance_id].source_id
	_sources.erase(instance_id)
	_recompute()
	_last_time_ms = time_ms
	_record(trace, time_ms, source_id, instance_id, "removed", before, context)
	return ""


func snapshot() -> PlayerStats:
	if _current == null:
		return null
	var output := _current.duplicate(true) as PlayerStats
	output.derivation_base = _base.duplicate(true)
	return output


func cast_start_snapshot(skill: Skill, slow: float = 0.0) -> Dictionary:
	return {"attack_speed": _current.attack_speed,
		"execution_ms": CombatTiming.execution_time_ms_with_slow(skill, _current.attack_speed, slow)}


func _time_error(time_ms: int, trace) -> String:
	if time_ms < _last_time_ms or (trace != null and time_ms < trace.last_time_ms):
		return "Stat changes cannot move simulation time backwards."
	return ""


func _record(trace, time_ms: int, source_id: String, instance_id: String, reason: String, before: Dictionary, context: Dictionary = {}) -> void:
	if trace == null:
		return
	var event_context := context.duplicate(true)
	event_context.merge({"source_id": source_id, "effect_instance_id": instance_id, "lifecycle_reason": reason}, true)
	trace.record("stats_recalculated", time_ms, event_context, {
		"before": before, "after": value_snapshot(_current),
		"sources": _current.stat_sources, "derivations": _current.derivation_details})


func _recompute() -> void:
	_current = _base.duplicate(true)
	_current.derivation_details.clear()
	# No normalization on the compatibility path: direct legacy fixtures may only
	# set poison_damage_per_tick or the legacy physical multiplier.
	if _sources.is_empty() and _base.stat_derivations.is_empty() and not _base.legendary_coin:
		return
	if not _current.physical_damage_uses_buckets:
		_current.talent_physical_damage_multiplier = _current.physical_damage_multiplier
		_current.gear_physical_damage_multiplier = 1.0
		_current.physical_damage_uses_buckets = true
	if _current.base_poison_damage == 0.0 and _current.bonus_base_elemental_damage == 0.0:
		_current.base_poison_damage = _current.poison_damage_per_tick / maxf(0.05, _current.elemental_damage_multiplier)
	var totals := {}
	var physical_factor := 1.0
	var elemental_factor := 1.0
	var instances := _sources.keys()
	instances.sort()
	for instance in instances:
		var source: Dictionary = _sources[instance]
		_current.stat_sources.append({"source_id": source.source_id, "source_kind": "temporary",
			"instance_id": instance, "values": source.values.duplicate(true)})
		# Each independent damage-bonus source is its own multiplier, like talents.
		physical_factor *= maxf(0.0, 1.0 + float(source.values.get(StatCatalog.PERCENT_PHYSICAL_DAMAGE, 0.0)))
		elemental_factor *= maxf(0.0, 1.0 + float(source.values.get(StatCatalog.PERCENT_ELEMENTAL_DAMAGE, 0.0)))
		for id in source.values:
			totals[id] = float(totals.get(id, 0.0)) + float(source.values[id])
	for id in TEMP_FIELDS:
		var field: String = TEMP_FIELDS[id]
		_current.set(field, float(_current.get(field)) + float(totals.get(id, 0.0)))
	_current.crit_chance = maxf(0.0, _current.crit_chance) if _current.legendary_signet else clampf(_current.crit_chance, 0.0, 1.0)
	_current.retrigger_chance = clampf(_current.retrigger_chance, 0.0, 1.0)
	_current.crit_multiplier = maxf(1.0, _current.crit_multiplier)
	_current.gold_reward_multiplier = maxf(0.0, _current.gold_reward_multiplier)
	_current.magic_find = maxf(0.0, _current.magic_find)
	if _current.legendary_coin:
		_current.magic_find *= 2.0
		_current.legendary_coin_applied = true
	_current.temporary_physical_multiplier = physical_factor
	_current.temporary_elemental_multiplier = elemental_factor
	# Dependency order is explicit and independent of resource enumeration order.
	for kind in ["fill_your_pockets", "double_dip", "fast_hands", "sharpened_edge"]:
		for rule in _base.stat_derivations:
			if rule.kind == kind:
				_apply_rule(rule)
	_current.sync_elemental_damage_multiplier()
	for rule in _base.stat_derivations:
		if rule.kind == "shadow_mastery":
			_apply_rule(rule)
	_current.sync_physical_damage_multiplier()
	_current.sync_poison_damage_per_tick()


func _apply_rule(rule: Dictionary) -> void:
	var fraction := float(rule.fraction)
	var input := 0.0
	var output := 0.0
	match rule.kind:
		"fill_your_pockets":
			input = _current.magic_find
			output = input * fraction
			_current.derived_elemental_multiplier = 1.0 + output
		"double_dip":
			input = _current.retrigger_chance
			output = input * fraction
			_current.crit_chance = maxf(0.0, _current.crit_chance + output) if _current.legendary_signet else clampf(_current.crit_chance + output, 0.0, 1.0)
		"fast_hands":
			input = _current.gold_reward_multiplier - 1.0
			output = input * fraction
			_current.attack_speed += output
		"sharpened_edge":
			input = 1.0
			output = 1.0 + fraction
			_current.skill_damage_multipliers["skill.stab"] = output
			_current.skill_damage_multipliers["skill.heavy_slash"] = output
		"shadow_mastery":
			input = _current.elemental_damage_multiplier - 1.0
			output = 1.0 + input * fraction
			_current.derived_physical_multiplier = output
			var flat_copy := _current.bonus_base_elemental_damage * fraction
			_current.bonus_physical_damage += flat_copy
			_current.derivation_details.append({"source_id": rule.source_id, "kind": "shadow_mastery_flat",
				"fraction": fraction, "input": _current.bonus_base_elemental_damage, "output": flat_copy})
	_current.derivation_details.append({"source_id": rule.source_id, "kind": rule.kind,
		"fraction": fraction, "input": input, "output": output})


static func value_snapshot(stats: PlayerStats) -> Dictionary:
	return {"cooldown_factor": stats.cooldown_factor, "cooldown_reduction": stats.cooldown_reduction,
		"increased_buff_duration": stats.increased_buff_duration,
		"crit_applies_penetration": stats.crit_applies_penetration, "crit_applies_potency": stats.crit_applies_potency,
		"attack_speed": stats.attack_speed, "crit_chance": stats.crit_chance,
		"crit_multiplier": stats.crit_multiplier, "retrigger_chance": stats.retrigger_chance,
		"base_poison_damage": stats.base_poison_damage, "bonus_base_elemental_damage": stats.bonus_base_elemental_damage,
		"bonus_physical_damage": stats.bonus_physical_damage,
		"gear_physical_multiplier": stats.gear_physical_damage_multiplier,
		"talent_physical_multiplier": stats.talent_physical_damage_multiplier,
		"physical_multiplier": stats.physical_damage_multiplier,
		"gear_elemental_multiplier": stats.gear_elemental_damage_multiplier,
		"talent_elemental_multiplier": stats.talent_elemental_damage_multiplier,
		"elemental_multiplier": stats.elemental_damage_multiplier,
		"poison_damage_per_tick": stats.poison_damage_per_tick,
		"gold_reward_multiplier": stats.gold_reward_multiplier, "magic_find": stats.magic_find,
		"temporary_physical_multiplier": stats.temporary_physical_multiplier,
		"temporary_elemental_multiplier": stats.temporary_elemental_multiplier,
		"derived_physical_multiplier": stats.derived_physical_multiplier,
		"derived_elemental_multiplier": stats.derived_elemental_multiplier,
		"skill_damage_multipliers": stats.skill_damage_multipliers.duplicate(true)}
