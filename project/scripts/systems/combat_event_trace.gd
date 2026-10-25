extends RefCounted
## Versioned observation stream. Never owns RNG or changes combat state.
## Sequence order is execution order; timestamps may tie but never go backwards.
const SCHEMA_VERSION := 1

var enabled := false
var records: Array[Dictionary] = []
## Minimal presentation stream retained even when diagnostic tracing is off.
var presentation_records: Array[Dictionary] = []
var counts: Dictionary = {}
var sequence := 0
var last_time_ms := 0
var next_cast_id := 0


func allocate_cast_id() -> int:
	next_cast_id += 1
	return next_cast_id


func record(kind: String, time_ms: int, context: Dictionary = {}, payload: Dictionary = {}) -> int:
	assert(time_ms >= last_time_ms, "Combat events must be chronological")
	last_time_ms = time_ms
	sequence += 1
	counts[kind] = int(counts.get(kind, 0)) + 1
	if kind in ["effect_lifecycle", "cooldown_started", "schedule_decision", "cast_resolved", "status_transaction", "gold_transaction", "poison_tick", "legendary_buff_grant", "legendary_buff_expired", "legendary_buff_reset", "legendary_locket_trial"]:
		var observed := payload
		if kind == "cast_resolved":
			observed = {}
			for key in ["damage", "health_removed", "health_loss", "status_after", "interrupted", "stun_duration_ms", "cooldown_blocked", "resource_unavailable"]:
				if payload.has(key): observed[key] = payload[key]
		elif kind == "poison_tick":
			observed = {"stacks_remaining": payload.get("stacks_remaining", 0), "stacks_depleted": payload.get("stacks_depleted", 0), "keyword_consume": payload.get("keyword_consume", false)}
		presentation_records.append({"presentation_version": 1, "sequence": sequence, "kind": kind, "time_ms": time_ms,
			"source_id": context.get("source_id", ""), "origin_kind": context.get("origin_kind", "system"),
			"cast_id": context.get("cast_id", 0), "root_cast_id": context.get("root_cast_id", 0),
			"lifecycle_reason": context.get("lifecycle_reason", ""),
			"effect_instance_id": context.get("effect_instance_id", ""), "payload": observed.duplicate(true)})
	if enabled:
		records.append({
			"schema_version": SCHEMA_VERSION,
			"sequence": sequence,
			"time_ms": time_ms,
			"kind": kind,
			"source_id": context.get("source_id", ""),
			"cast_id": context.get("cast_id", 0),
			"parent_cast_id": context.get("parent_cast_id", 0),
			"root_cast_id": context.get("root_cast_id", 0),
			"origin_kind": context.get("origin_kind", "system"),
			"effect_instance_id": context.get("effect_instance_id", ""),
			"lifecycle_reason": context.get("lifecycle_reason", ""),
			"payload": payload.duplicate(true),
		})
	return sequence
