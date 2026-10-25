class_name CombatLogInspectorData
extends RefCounted
## Shared presentation data for the Combat Log inspector. This keeps timeline
## row grouping and damage ranking out of scene scripts; combat math still
## comes only from CombatResolver's already-resolved event arrays.


const KIND_CAST := "cast"
const KIND_POISON := "poison"
const KIND_PROC := "proc"
const KIND_HEALTH_REMOVAL := "health_removal"
static var POISON_ICON: Texture2D = GameIcons.icon_for("status.poison")


static func build(result: CombatResolver.CombatResult, monster: Monster = null) -> Dictionary:
	return {
		"is_valid": result.is_valid,
		"failure": result.failure.duplicate(true),
		"summary": CombatRecap.summarize(result, monster),
		"duration_ms": result.duration_ms,
		"is_win": result.is_win,
		"timeline_rows": _timeline_rows(result),
		"damage_rows": _damage_rows(result),
		"health_removal_rows": _health_removal_rows(result),
		"max_event_damage": _max_event_damage(result),
	}


static func _timeline_rows(result: CombatResolver.CombatResult) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var row_by_key := {}
	var consume_by_sequence := {}
	for record in result.trace.presentation_records:
		if record.kind == "poison_tick": consume_by_sequence[int(record.sequence)] = bool(record.payload.get("keyword_consume", false))
	for event in result.cast_events:
		var skill_name := _skill_name(event.skill)
		var health_removal := preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(event)
		var cast_row: Dictionary = _row_for(row_by_key, rows, skill_name, KIND_HEALTH_REMOVAL if health_removal else KIND_CAST, event.skill.icon if event.skill != null else null)
		var cast_events: Array = cast_row["events"]
		var cast_contribution := _combined_contribution(event, KIND_CAST)
		cast_events.append({
			"health_removed": event.health_removed,
			"start_ms": event.cast_start_ms,
			"end_ms": event.time_ms,
			"contact_ms": event.time_ms,
			"damage": cast_contribution["damage"] if not cast_contribution.is_empty() else event.physical_damage,
			"is_crit": cast_contribution["is_crit"] if not cast_contribution.is_empty() else event.is_crit,
			"has_armor": int(cast_contribution["armor_reduction_applied"]) > 0 if not cast_contribution.is_empty() else event.armor_reduction_applied > 0,
			"has_poison_apply": int(cast_contribution["poison_stacks_applied"]) > 0 if not cast_contribution.is_empty() else event.poison_stacks_applied > 0,
			"min_cast_proc": event.min_cast_time_proc_applied,
		})
		cast_row["events"] = cast_events
		for contribution in event.damage_contributions:
			if String(contribution.get("kind", "")) != KIND_PROC:
				continue
			var triggered_name := String(contribution.get("name", "Triggered Skill"))
			var proc_row: Dictionary = _row_for(row_by_key, rows, triggered_name, KIND_PROC, contribution.get("icon", null))
			var proc_start: int = maxi(event.cast_start_ms, event.time_ms - 180)
			var proc_events: Array = proc_row["events"]
			proc_events.append({
				"start_ms": proc_start,
				"end_ms": event.time_ms,
				"contact_ms": event.time_ms,
				"damage": float(contribution.get("damage", 0.0)),
				"is_crit": bool(contribution.get("is_crit", false)),
				"has_armor": int(contribution.get("armor_reduction_applied", 0)) > 0,
				"has_poison_apply": int(contribution.get("poison_stacks_applied", 0)) > 0,
				"min_cast_proc": true,
			})
			proc_row["events"] = proc_events

	var poison_row: Dictionary = {}
	var has_poison_row := false
	for tick in result.tick_events:
		if not tick.had_active_stack:
			continue
		if not has_poison_row:
			poison_row = _row_for(row_by_key, rows, "Poison Ticks", KIND_POISON, POISON_ICON)
			has_poison_row = true
		var poison_events: Array = poison_row["events"]
		poison_events.append({
			"time_ms": tick.time_ms,
			"damage": tick.damage,
			"is_crit": tick.is_crit,
			"origin_kind": tick.origin_kind,
			"stacks_before": tick.stacks_before,
			"stacks_depleted": tick.stacks_consumed,
			"free_retrigger": tick.origin_kind == "poison_repeat",
			"keyword_consume": bool(consume_by_sequence.get(tick.sequence, false)),
			"charge_spends": tick.charge_spends.duplicate(true),
			"stacks_remaining": tick.stacks_remaining,
		})
		poison_row["events"] = poison_events
	return rows


static func _health_removal_rows(result: CombatResolver.CombatResult) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var by_name := {}
	for event in result.cast_events:
		if not preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(event): continue
		var name := _skill_name(event.skill)
		if not by_name.has(name):
			by_name[name] = {"name": name, "kind": KIND_HEALTH_REMOVAL, "health_removed": 0.0, "icon": event.skill.icon if event.skill != null else null}
			rows.append(by_name[name])
		by_name[name].health_removed += event.health_removed
	rows.sort_custom(func(a, b): return a.health_removed > b.health_removed)
	return rows


static func _damage_rows(result: CombatResolver.CombatResult) -> Array[Dictionary]:
	var totals := {}
	var kinds := {}
	var icons := {}
	for event in result.cast_events:
		if event.damage_contributions.is_empty():
			if event.physical_damage <= 0.0:
				continue
			var skill_name := _skill_name(event.skill)
			totals[skill_name] = float(totals.get(skill_name, 0.0)) + event.physical_damage
			kinds[skill_name] = KIND_CAST
			if event.skill != null and event.skill.icon != null:
				icons[skill_name] = event.skill.icon
			continue
		for contribution in event.damage_contributions:
			var damage := float(contribution.get("damage", 0.0))
			if damage <= 0.0:
				continue
			var name := String(contribution.get("name", "Unknown Skill"))
			totals[name] = float(totals.get(name, 0.0)) + damage
			kinds[name] = String(contribution.get("kind", KIND_CAST))
			var icon = contribution.get("icon", null)
			if icon != null:
				icons[name] = icon
	for tick in result.tick_events:
		if tick.damage <= 0.0:
			continue
		totals["Poison Ticks"] = float(totals.get("Poison Ticks", 0.0)) + tick.damage
		kinds["Poison Ticks"] = KIND_POISON
		icons["Poison Ticks"] = POISON_ICON

	var rows: Array[Dictionary] = []
	for name in totals.keys():
		rows.append({
			"name": name,
			"damage": float(totals[name]),
			"kind": str(kinds.get(name, KIND_CAST)),
			"icon": icons.get(name, null),
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var damage_a: float = a["damage"]
		var damage_b: float = b["damage"]
		if not is_equal_approx(damage_a, damage_b):
			return damage_a > damage_b
		return String(a["name"]) < String(b["name"])
	)
	return rows


static func _max_event_damage(result: CombatResolver.CombatResult) -> float:
	var max_damage := 0.0
	for event in result.cast_events:
		if event.damage_contributions.is_empty():
			max_damage = maxf(max_damage, event.physical_damage)
			continue
		for contribution in event.damage_contributions:
			max_damage = maxf(max_damage, float(contribution.get("damage", 0.0)))
	for tick in result.tick_events:
		if tick.damage > 0.0 or tick.absorbed_amount > 0.0:
			max_damage = maxf(max_damage, tick.damage)
	return max_damage


static func _combined_contribution(event: CombatResolver.CastEvent, kind: String) -> Dictionary:
	var combined := {
		"damage": 0.0,
		"is_crit": false,
		"armor_reduction_applied": 0,
		"poison_stacks_applied": 0,
	}
	var found := false
	for contribution in event.damage_contributions:
		if String(contribution.get("kind", "")) != kind:
			continue
		found = true
		combined["damage"] = float(combined["damage"]) + float(contribution.get("damage", 0.0))
		combined["is_crit"] = bool(combined["is_crit"]) or bool(contribution.get("is_crit", false))
		combined["armor_reduction_applied"] = int(combined["armor_reduction_applied"]) + int(contribution.get("armor_reduction_applied", 0))
		combined["poison_stacks_applied"] = int(combined["poison_stacks_applied"]) + int(contribution.get("poison_stacks_applied", 0))
	return combined if found else {}


static func _row_for(row_by_key: Dictionary, rows: Array[Dictionary], label: String, kind: String, icon: Texture2D) -> Dictionary:
	var key := "%s:%s" % [kind, label]
	if row_by_key.has(key):
		return row_by_key[key]
	var row := {
		"label": label,
		"kind": kind,
		"icon": icon,
		"events": [],
	}
	row_by_key[key] = row
	rows.append(row)
	return row


static func _skill_name(skill: Skill) -> String:
	if skill == null or skill.display_name.strip_edges() == "":
		return "Unknown Skill"
	return skill.display_name
