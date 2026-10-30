extends RefCounted
const TOXIC_POISON_DAMAGE_PER_RANK := 0.10
## Shared validation/transfer for explicit approved Assassin rank carriers.
const LIMITS := {"hastened_poison_rank": 5, "accelerant_rank": 5, "echoing_toxin_rank": 3, "resonance_rank": 4, "toxic_tradeoff_rank": 5}
const FIELDS := ["hastened_poison_rank", "accelerant_rank", "echoing_toxin_rank", "resonance_rank", "toxic_tradeoff_rank", "critical_poison_enabled", "bypass_enabled"]

static func validation_error(value: Resource) -> String:
	for field in LIMITS:
		var rank: int = value.get(field)
		if rank < 0 or rank > int(LIMITS[field]):
			return "Invalid Assassin passive " + field
	return ""

static func apply(stats: PlayerStats, talent: Talent) -> String:
	var error := validation_error(talent)
	if error != "":
		return error + ": " + talent.id
	for field in FIELDS:
		if not talent.get(field):
			continue
		# Each carrier has one source. Do not silently overwrite malformed duplicate data.
		for source in stats.stat_sources:
			if source.get("assassin_passive", "") == field:
				return "Duplicate Assassin passive " + field
		stats.stat_sources.append({"source_id": talent.id, "source_kind": "combat_passive", "assassin_passive": field, "value": talent.get(field)})
		if field == "toxic_tradeoff_rank":
			# Poison-only factor deliberately excluded from elemental and Shadow Mastery buckets.
			stats.poison_tick_damage_multiplier = 1.0 + TOXIC_POISON_DAMAGE_PER_RANK * talent.toxic_tradeoff_rank
		else:
			stats.set(field, talent.get(field))
	return ""
