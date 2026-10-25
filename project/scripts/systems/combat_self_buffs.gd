extends RefCounted
## Independent instances; charges are never amplified by enemy stack modifiers.
var instances: Array[Dictionary] = []
var _next_id := 0
var trace = null
const TimerMath = preload("res://scripts/systems/combat_timer_math.gd")
var initialization_error := ""
var legendary_crown := false
var _durations: Dictionary = {}

func _init(event_trace = null, duration_increase: float = 0.0) -> void:
	trace = event_trace
	for kind in ["master_of_poisons", "beguiling_presence"]:
		var timer := TimerMath.scaled_duration(5000 if kind == "master_of_poisons" else 10000, duration_increase)
		if timer.error != "":
			initialization_error = timer.error
			return
		_durations[kind] = timer.duration_ms

func grant(kind: String, time_ms: int, context: Dictionary, magnitude: float = 0.0, consumed_decay: int = 0) -> String:
	if initialization_error != "":
		return initialization_error
	var expires_at_ms := -1
	if kind != "virulent_poison":
		var timer := TimerMath.deadline(time_ms, int(_durations.get(kind, 10000)))
		if timer.error != "":
			return timer.error
		expires_at_ms = timer.expires_at_ms
	advance(time_ms)
	_next_id += 1
	var item := {"instance_id": "self_buff.%d" % _next_id, "kind": kind,
		"source_id": context.get("source_id", ""), "charges": 5 if kind == "virulent_poison" else 0,
		"magnitude": magnitude, "expires_at_ms": expires_at_ms}
	if kind == "beguiling_presence":
		item["magnitude"] = magnitude * (2.0 if legendary_crown else 1.0)
		item["units"] = consumed_decay
		item["crit_chance_bonus"] = 0.02 * consumed_decay * (2.0 if legendary_crown else 1.0)
		item["unit"] = "Decay stacks absorbed"
	elif kind == "virulent_poison":
		item["poison_multiplier"] = 3.0 if legendary_crown else 2.0
	instances.append(item)
	_record(item, time_ms, "granted", {}, item)
	return ""

func advance(time_ms: int) -> void:
	for item in instances.duplicate():
		if int(item.expires_at_ms) >= 0 and int(item.expires_at_ms) <= time_ms:
			instances.erase(item)
			_record(item, time_ms, "expired", item, {})

func values() -> Dictionary:
	var value := {"ignore_resistance": false, "elemental_base": 0.0, "poison_multiplier": 1.0, "crit_chance": 0.0}
	for item in instances:
		match item.kind:
			"master_of_poisons": value.ignore_resistance = true
			"beguiling_presence":
				value.elemental_base += float(item.magnitude)
				value.crit_chance += float(item.get("crit_chance_bonus",0.0))
			"virulent_poison": value.poison_multiplier *= float(item.poison_multiplier)
	return value

func spend_poison_charges(time_ms: int) -> Array[Dictionary]:
	var spent: Array[Dictionary] = []
	for item in instances.duplicate():
		if item.kind != "virulent_poison":
			continue
		var before: Dictionary = item.duplicate(true)
		item.charges -= 1
		spent.append({"instance_id": item.instance_id, "source_id": item.source_id,
			"before": before.charges, "after": item.charges})
		if item.charges == 0:
			instances.erase(item)
		_record(item, time_ms, "charge_spent", before, item if item.charges > 0 else {})
	return spent

func reset(time_ms: int, reason: String) -> void:
	for item in instances:
		_record(item, time_ms, reason, item, {})
	instances.clear()

func _record(item: Dictionary, time_ms: int, reason: String, before: Dictionary, after: Dictionary) -> void:
	if trace != null:
		trace.record("effect_lifecycle", time_ms, {"source_id": item.source_id,
			"effect_instance_id": item.instance_id, "lifecycle_reason": reason},
			{"owner_id": "player", "effect_id": item.kind, "before": before.duplicate(true), "after": after.duplicate(true)})
