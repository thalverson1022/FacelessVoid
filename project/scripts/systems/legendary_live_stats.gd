class_name LegendaryLiveStats
extends RefCounted
## Signatures replace their prior contribution; raw numeric crit inputs remain
## available for live gold/buff conversions and are suppressed at hit resolution.
const Gold = preload("res://scripts/systems/combat_gold.gd")
static func resolve(raw: PlayerStats, stash: int, stolen: int, buffs: Dictionary = {}) -> PlayerStats:
	if not raw.legendary_signet and not raw.legendary_bandit:
		return raw
	var p := raw.duplicate(true) as PlayerStats
	if raw.derivation_base != null:
		p.derivation_base = raw.derivation_base.duplicate(true)
	p.attack_speed -= p.legendary_added_ias
	p.gear_physical_damage_multiplier -= p.legendary_added_physical
	p.bonus_physical_damage -= p.legendary_added_flat
	p.legendary_added_ias = 0.0
	p.legendary_added_physical = 0.0
	p.legendary_added_flat = 0.0
	for index in range(p.stat_sources.size() - 1, -1, -1):
		if p.stat_sources[index].get("source_id", "") in ["legendary.signet", "legendary.bandit"]:
			p.stat_sources.remove_at(index)
	if p.legendary_signet:
		var inputs := Gold.crit_values(p, stash, stolen)
		p.legendary_added_ias = 1.5 * maxf(0.0, inputs.crit_chance + float(buffs.get("crit_chance", 0.0)))
		p.legendary_added_physical = 1.5 * maxf(0.0, inputs.crit_multiplier - 1.0)
		p.attack_speed += p.legendary_added_ias
		p.gear_physical_damage_multiplier += p.legendary_added_physical
		p.stat_sources.append({"source_id": "legendary.signet", "source_kind": "legendary_signature", "raw_crit_chance": inputs.crit_chance + float(buffs.get("crit_chance", 0.0)), "raw_crit_multiplier": inputs.crit_multiplier})
	if p.legendary_bandit:
		p.legendary_added_flat = minf(100.0, floori(maxi(0, stash) / 10.0))
		p.bonus_physical_damage += p.legendary_added_flat
		p.stat_sources.append({"source_id": "legendary.bandit", "source_kind": "legendary_signature", "stash": stash, "base_physical_damage": p.legendary_added_flat})
	if not p.physical_damage_uses_buckets:
		p.physical_damage_uses_buckets = true
		p.talent_physical_damage_multiplier = raw.physical_damage_multiplier
	p.sync_physical_damage_multiplier()
	return p
static func chance(player: PlayerStats, ordinary: float) -> float:
	return 0.0 if player.legendary_signet else clampf(ordinary, 0.0, 1.0)
