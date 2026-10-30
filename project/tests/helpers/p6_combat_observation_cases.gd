extends RefCounted
## Stable compatibility probes captured before T2 resolver changes.

static func setup() -> Dictionary:
	var stats := PlayerStats.new()
	stats.weapon_damage_min = 8
	stats.weapon_damage_max = 23
	stats.crit_chance = 0.35
	stats.crit_multiplier = 1.7
	stats.retrigger_chance = 0.27
	stats.min_cast_time_proc_chance = 0.2
	stats.poison_damage_per_tick = 9.0
	stats.shred_chance = 0.3
	stats.decay_chance = 0.2
	stats.elemental_proc_chance = 0.4
	var monster := Monster.new()
	monster.hp = 100
	monster.armor = 14
	monster.poison_resistance = 0.25
	monster.dodge_chance = 0.15
	monster.block = 2.0
	monster.cleanse_threshold = 4
	monster.stun_duration_ms = 1750
	monster.interrupt_skip_count = 1
	var rotation: Array[Skill] = [load("res://data/skills/quick_cut.tres"), load("res://data/skills/rending_slash.tres"), load("res://data/skills/venom_jab.tres")]
	return {"stats": stats, "monster": monster, "rotation": rotation}


static func signature(result: RefCounted) -> String:
	var data := {"duration": result.duration_ms, "damage": result.total_damage,
		"dps": result.dps, "win": result.is_win, "overkill": result.overkill_damage,
		"gold": result.gold_stolen, "cap": result.poison_stack_cap, "casts": [], "ticks": []}
	for event in result.cast_events:
		data.casts.append(_old_fields(event))
	for event in result.tick_events:
		data.ticks.append(_old_fields(event))
	return JSON.stringify(_normalize(data)).sha256_text()


static func _normalize(value: Variant) -> Variant:
	if value is Resource:
		# Icon Lab replaced presentation art in M4. Preserve the pre-T2 art
		# identity in historical snapshots without changing gameplay fields.
		var legacy_icons := {
			"res://assets/ui/assigned_flat/skills/quick_cut.png": "res://assets/skill_icons/rogue/quick_cut.png",
			"res://assets/ui/assigned_flat/skills/rending_slash.png": "res://assets/skill_icons/rogue/rending_slash.png",
			"res://assets/ui/assigned_flat/skills/venom_jab.png": "res://assets/skill_icons/rogue/venom_jab.png",
			"res://assets/ui/assigned/skills/quick_cut.png": "res://assets/skill_icons/rogue/quick_cut.png",
			"res://assets/ui/assigned/skills/rending_slash.png": "res://assets/skill_icons/rogue/rending_slash.png",
			"res://assets/ui/assigned/skills/venom_jab.png": "res://assets/skill_icons/rogue/venom_jab.png",
		}
		if legacy_icons.has(value.resource_path):
			return legacy_icons[value.resource_path]
		return value.resource_path
	if value is Dictionary:
		var normalized := {}
		for key in value:
			normalized[key] = _normalize(value[key])
		return normalized
	if value is Array:
		var normalized := []
		for entry in value:
			normalized.append(_normalize(entry))
		return normalized
	return value


static func _old_fields(event: RefCounted) -> Dictionary:
	var data := {}
	for property in event.get_property_list():
		if not (int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if property.name == "gold_transactions":
			continue
		# M7-M9 observation fields were absent from the historical pre-T2 schema.
		if property.name in ["health_removed", "health_removal_captured", "potency_stacks_applied", "legendary_fuel", "legendary_depth", "stacks_preserved", "keyword_consume", "preservation_roll", "available_fuel"]:
			continue
		# T9 observation fields did not exist in the pre-T2 gameplay snapshot.
		if event is CombatResolver.TickEvent and property.name in ["is_crit", "blocked_amount", "crit_negation_applied"]:
			continue
		if property.name in ["stacks_before", "charge_spends", "requested_stacks", "raw_damage", "crit_chance", "crit_multiplier"]:
			continue
		if property.name in ["cast_id", "parent_cast_id", "root_cast_id", "origin_kind", "sequence", "stacks_consumed", "stat_snapshot", "lifecycle_snapshot", "resource_unavailable", "cooldown_blocked", "cooldown_available_at_ms", "status_transactions", "poison_applications", "status_snapshot"]:
			continue
		var value: Variant = event.get(property.name)
		data[property.name] = value.id if value is Skill else value
	return data
