extends RefCounted
## Fight-local lifecycle storage. Callers own hit eligibility and scheduling.
## Definitions and snapshots are copied; no source resource becomes mutable state.
const StatState = preload("res://scripts/systems/combat_stat_state.gd")
const TimerMath = preload("res://scripts/systems/combat_timer_math.gd")
var initialization_error := ""
var _stats
var _trace
var _definitions: Dictionary = {}
var _active: Dictionary = {}
var _serial := 0
var _time_ms := 0


func _init(stats = null, trace = null) -> void:
	_stats = stats
	_trace = trace
	if stats != null:
		initialization_error = stats.initialization_error


## duration_ms=-1 means no timer; cap=-1 means uncapped. Refresh shares one timer.
## mode=add accumulates units; mode=replace replaces them. Magnitudes are per unit.
func define(id: String, definition: Dictionary) -> String:
	if id.strip_edges().is_empty() or _definitions.has(id):
		return "Effect IDs must be nonempty and unique."
	var d := definition.duplicate(true)
	if String(d.get("source_id", "")).strip_edges().is_empty():
		return "Effects require a content source ID."
	for key in ["duration_ms", "cap"]:
		if typeof(d.get(key)) != TYPE_INT or int(d[key]) == 0 or int(d[key]) < -1:
			return "Invalid effect " + key
	if d.get("mode", "") not in ["add", "replace"] or d.get("unit", "") not in ["stacks", "charges"]:
		return "Invalid effect mode or unit."
	var magnitude: Variant = d.get("magnitude_per_unit", 1.0)
	if typeof(magnitude) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(magnitude)):
		return "Invalid effect magnitude."
	d["magnitude_per_unit"] = float(magnitude)
	d["cast_start_inclusive"] = bool(d.get("cast_start_inclusive", false))
	var inputs: Variant = d.get("stat_inputs", {})
	if not inputs is Dictionary:
		return "Invalid effect stat inputs."
	if not inputs.is_empty() and _stats == null:
		return "Stat effects require a stat state."
	for stat_id in inputs:
		if not StatState.TEMP_FIELDS.has(stat_id) and stat_id not in [StatCatalog.PERCENT_PHYSICAL_DAMAGE, StatCatalog.PERCENT_ELEMENTAL_DAMAGE]:
			return "Unsupported effect stat: " + str(stat_id)
		if typeof(inputs[stat_id]) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(inputs[stat_id])):
			return "Invalid effect stat amount."
	d["stat_inputs"] = inputs.duplicate(true)
	_definitions[id] = d
	return ""


## Removal without keyword Consume (e.g. enemy cleansing).
func clear_effect(id: String, time_ms: int, reason: String, context: Dictionary = {}) -> String:
	var error := _operation_error(id, time_ms)
	if error != "":
		return error
	error = advance(time_ms)
	if error != "" or not _active.has(id):
		return error
	return _remove(id, time_ms, reason, context)


func snapshot(id: String = "") -> Dictionary:
	return (_active if id.is_empty() else _active.get(id, {})).duplicate(true)


## Preserve only explicitly inclusive cast-start deadlines. Grants independently
## expire their old instance at equality. This permits T1's asymmetric tie.
func advance(time_ms: int, preserve_cast_start: bool = false) -> String:
	var error := _time_error(time_ms)
	if error != "":
		return error
	var due: Array[Dictionary] = []
	for id in _active:
		var state: Dictionary = _active[id]
		var deadline := int(state.expires_at_ms)
		if deadline < 0 or deadline > time_ms:
			continue
		if deadline == time_ms and preserve_cast_start and _definitions[id].cast_start_inclusive:
			continue
		due.append(state)
	due.sort_custom(func(a, b): return a.expires_at_ms < b.expires_at_ms if a.expires_at_ms != b.expires_at_ms else a.effect_id < b.effect_id)
	for state in due:
		# A preserved boundary may already have trace events at its deadline.
		var observed := maxi(int(state.expires_at_ms), _time_ms)
		if _trace != null:
			observed = maxi(observed, _trace.last_time_ms)
		error = _remove(state.effect_id, observed, "expired", {})
		if error != "":
			return error
	_time_ms = time_ms
	return ""


func grant(id: String, units: int, time_ms: int, context: Dictionary = {}) -> Dictionary:
	var error := _operation_error(id, time_ms)
	if error != "" or units < 0:
		return {"error": error if error != "" else "Cannot grant negative units."}
	error = advance(time_ms, true)
	if error != "":
		return {"error": error}
	# A zero-fuel conversion does not refresh or replace a previous buff.
	if units == 0:
		return {"error": "", "applied": 0, "state": snapshot(id)}
	var d: Dictionary = _definitions[id]
	var expires_at_ms := -1
	if int(d.duration_ms) > 0:
		var timer := TimerMath.deadline(time_ms, int(d.duration_ms))
		if timer.error != "":
			return {"error": timer.error}
		expires_at_ms = timer.expires_at_ms
	if _active.has(id) and int(_active[id].expires_at_ms) >= 0 and int(_active[id].expires_at_ms) <= time_ms:
		error = _remove(id, time_ms, "expired", context)
		if error != "":
			return {"error": error}
	var before := snapshot(id)
	var old_units := int(before.get("units", 0))
	var requested := units + old_units if d.mode == "add" else units
	var count := mini(requested, int(d.cap)) if int(d.cap) > 0 else requested
	var state := before.duplicate(true)
	if state.is_empty():
		_serial += 1
		state = {"effect_id": id, "instance_id": "%s:%d" % [id, _serial],
			"source_id": d.source_id, "owner_id": d.get("owner_id", "player"), "unit": d.unit}
	state["units"] = count
	state["stacks"] = count if d.unit == "stacks" else 0
	state["charges"] = count if d.unit == "charges" else 0
	state["magnitude"] = count * float(d.magnitude_per_unit)
	state["expires_at_ms"] = expires_at_ms
	error = _sync_stats(id, state, time_ms, context)
	if error != "":
		return {"error": error}
	_active[id] = state
	_record(id, before, state, time_ms, "granted" if before.is_empty() else "refreshed" if d.mode == "add" else "replaced", context,
		{"requested": units, "overflow": maxi(0, requested - count)})
	return {"error": "", "applied": count - old_units, "state": state.duplicate(true)}


## amount=-1 consumes all. Eligibility is decided by the named consumer adapter.
func consume(id: String, amount: int, time_ms: int, at_cast_start: bool = false, context: Dictionary = {}) -> Dictionary:
	var error := _operation_error(id, time_ms)
	if error != "" or amount < -1:
		return {"error": error if error != "" else "Invalid consumption amount."}
	error = advance(time_ms, at_cast_start)
	if error != "":
		return {"error": error}
	var before := snapshot(id)
	if before.is_empty() or amount == 0:
		_record(id, before, before, time_ms, "empty_consumption", context)
		return {"error": "", "consumed": 0, "before": before}
	var count := int(before.units) if amount == -1 else mini(amount, int(before.units))
	var after := before.duplicate(true)
	after.units -= count
	after.stacks = after.units if after.unit == "stacks" else 0
	after.charges = after.units if after.unit == "charges" else 0
	after.magnitude = after.units * float(_definitions[id].magnitude_per_unit)
	if int(after.units) == 0:
		error = _remove(id, time_ms, "consumed", context, {"consumed": count})
	else:
		error = _sync_stats(id, after, time_ms, context)
		if error == "":
			_active[id] = after
			_record(id, before, after, time_ms, "consumed", context, {"consumed": count})
	return {"error": error, "consumed": count if error == "" else 0, "before": before}


func reset(time_ms: int, reason: String = "fight_end") -> String:
	var error := _time_error(time_ms)
	if error != "":
		return error
	var ids := _active.keys()
	ids.sort()
	for id in ids:
		error = _remove(id, time_ms, reason, {})
		if error != "":
			return error
	_time_ms = time_ms
	return ""


func _sync_stats(id: String, state: Dictionary, time_ms: int, context: Dictionary) -> String:
	var d: Dictionary = _definitions[id]
	if d.stat_inputs.is_empty():
		return ""
	var modifiers: Array[StatModifier] = []
	for stat_id in d.stat_inputs:
		var modifier := StatModifier.new()
		modifier.stat_id = stat_id
		modifier.value = float(d.stat_inputs[stat_id]) * int(state.units)
		modifiers.append(modifier)
	return _stats.replace_source(state.instance_id, d.source_id, modifiers, time_ms, _trace, context)


func _remove(id: String, time_ms: int, reason: String, context: Dictionary, details: Dictionary = {}) -> String:
	var before := snapshot(id)
	if not _definitions[id].stat_inputs.is_empty():
		var error: String = _stats.remove_source(before.instance_id, time_ms, _trace, context)
		if error != "":
			return error
	_active.erase(id)
	_record(id, before, {}, time_ms, reason, context, details)
	return ""


func _operation_error(id: String, time_ms: int) -> String:
	if not _definitions.has(id):
		return "Unknown effect: " + id
	return _time_error(time_ms)


func _time_error(time_ms: int) -> String:
	if initialization_error != "":
		return initialization_error
	if time_ms < _time_ms or (_trace != null and time_ms < _trace.last_time_ms):
		return "Effect changes cannot move simulation time backwards."
	return ""


func _record(id: String, before: Dictionary, after: Dictionary, time_ms: int, reason: String, context: Dictionary, details: Dictionary = {}) -> void:
	_time_ms = time_ms
	if _trace == null:
		return
	var event_context := context.duplicate(true)
	event_context.merge({"source_id": _definitions[id].source_id,
		"effect_instance_id": after.get("instance_id", before.get("instance_id", "")), "lifecycle_reason": reason}, true)
	var payload := {"effect_id": id, "before": before, "after": after,
		"stacks_before": before.get("stacks", 0), "stacks_after": after.get("stacks", 0),
		"charges_before": before.get("charges", 0), "charges_after": after.get("charges", 0),
		"magnitude_before": before.get("magnitude", 0.0), "magnitude_after": after.get("magnitude", 0.0),
		"expires_at_ms_before": before.get("expires_at_ms", -1), "expires_at_ms_after": after.get("expires_at_ms", -1)}
	payload.merge(details, true)
	_trace.record("effect_lifecycle", time_ms, event_context, payload)
