extends RefCounted
## Independent instances; charges are never amplified by enemy stack modifiers.
static var presence_crit_per_stack := 0.0
var instances: Array[Dictionary] = []
var _next_id := 0
var trace = null

func _init(event_trace = null) -> void:
	trace = event_trace

func grant(kind: String, time_ms: int, context: Dictionary, magnitude: float = 0.0, consumed_decay: int = 0) -> void:
	advance(time_ms)
	_next_id += 1
	var item := {"instance_id": "self_buff.%d" % _next_id, "kind": kind,
		"source_id": context.get("source_id", ""), "charges": 5 if kind == "virulent_poison" else 0,
		"magnitude": magnitude, "expires_at_ms": -1 if kind == "virulent_poison" else time_ms + (5000 if kind == "master_of_poisons" else 10000)}
	if kind == "beguiling_presence":
		item["units"] = consumed_decay
		item["unit"] = "Decay stacks absorbed"
	instances.append(item)
	_record(item, time_ms, "granted", {}, item)

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
				value.crit_chance += int(item.get("units",0)) * presence_crit_per_stack
			"virulent_poison": value.poison_multiplier *= 2.0
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
