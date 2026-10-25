extends RefCounted
## T10 source math. Resolution is read-only; playback owns stash crediting.
static func crit_values(player: PlayerStats, stash: int, stolen: int) -> Dictionary:
	var counted := mini(maxi(0, stash), 500) if player.gilded_blade_enabled else 0
	var gilded := counted * 0.01
	var silvered := minf(maxi(0, stolen) * 0.01, 0.25 * player.silvered_edge_rank)
	return {"stash": stash, "fight_stolen": stolen, "gilded_counted_gold": counted,
		"gilded_crit_bonus": gilded,
		"silvered_crit_bonus": silvered, "silvered_cap": 0.25 * player.silvered_edge_rank,
		"crit_chance": player.crit_chance + stolen * player.crit_chance_per_stolen_gold + silvered,
		"crit_multiplier": maxf(1.0, player.crit_multiplier + stash * player.crit_multiplier_per_current_gold + gilded)}

static func theft(raw: int, multiplier: float, stash: int, stolen: int, source: String, player: PlayerStats) -> Dictionary:
	var credited := maxi(0, floori(raw * multiplier))
	return {"kind": "theft", "source_id": source, "raw_amount": raw,
		"multiplier": multiplier, "credited_amount": credited,
		"stash_before": stash, "stash_after": stash + credited,
		"stolen_before": stolen, "stolen_after": stolen + credited,
		"stats_before": crit_values(player, stash, stolen),
		"stats_after": crit_values(player, stash + credited, stolen + credited)}
