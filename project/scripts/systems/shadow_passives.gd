extends RefCounted
## P6M5-D011. Explicit complete-rank Shadow carriers.
const LIMITS := {"death_pact_rank": 3, "death_blade_rank": 2}
const FIELDS := ["death_pact_rank", "death_blade_rank", "dusk_strike_enabled", "umbral_presence_enabled"]

static func validation_error(value: Resource) -> String:
	for field in LIMITS:
		var rank: int = value.get(field)
		if rank < 0 or rank > int(LIMITS[field]):
			return "Invalid Shadow passive " + field
	return ""

static func apply(stats: PlayerStats, talent: Talent) -> String:
	var error := validation_error(talent)
	if error != "":
		return error + ": " + talent.id
	for field in FIELDS:
		if not talent.get(field):
			continue
		for source in stats.stat_sources:
			if source.get("shadow_passive", "") == field:
				return "Duplicate Shadow passive " + field
		stats.stat_sources.append({"source_id": talent.id, "source_kind": "combat_passive", "shadow_passive": field, "value": talent.get(field)})
		match field:
			"death_pact_rank": stats.death_pact_rank = talent.death_pact_rank
			"death_blade_rank":
				stats.death_blade_enabled = true
				stats.death_blade_chance = 0.4 * talent.death_blade_rank
			"dusk_strike_enabled":
				stats.special_effects["decay_applies_shred"] = true
				stats.independent_decay_shred = true
			"umbral_presence_enabled": stats.poison_stack_cap = maxi(80, stats.poison_stack_cap)
	return ""
