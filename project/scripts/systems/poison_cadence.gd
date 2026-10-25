extends RefCounted
## Fight-wide phase; forced ticks never touch this clock.
var time_ms := 0
var progress := 0.0
var interval_ms := 1000

func advance(to_ms: int) -> void:
	progress += float(to_ms - time_ms) / interval_ms
	time_ms = to_ms

func deadline() -> int:
	return time_ms + maxi(0, ceili((1.0 - progress) * interval_ms - 0.0000001))

func tick() -> void:
	progress = 0.0

static func interval(player: PlayerStats, suppress: float) -> int:
	var scaling := 0.1 * (player.hastened_poison_rank + player.accelerant_rank)
	var rate := 1.0 + maxf(0.0, player.attack_speed) * scaling
	var echoing := preload("res://scripts/systems/p6_poison_contracts.gd").echoing_suppression(player.echoing_toxin_rank)
	return maxi(1, roundi(1000.0 * player.poison_tick_interval_multiplier * (1.0 + maxf(suppress, 0.0) + echoing) / rate))
