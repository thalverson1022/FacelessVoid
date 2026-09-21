class_name CombatTiming
extends RefCounted


## Floored at 1ms so a skill misconfigured with base_execution_ms = 0 and
## min_execution_ms = 0 can't stall CombatResolver.resolve()'s cast loop.
static func execution_time_ms(skill: Skill, attack_speed: float) -> int:
	var speed_multiplier := maxf(0.05, 1.0 + attack_speed)
	var scaled_ms: float = float(skill.base_execution_ms) / speed_multiplier
	return maxi(1, int(ceil(max(float(skill.min_execution_ms), scaled_ms))))


static func execution_time_ms_with_slow(skill: Skill, attack_speed: float, slow: float) -> int:
	var slowed_ms: float = float(execution_time_ms(skill, attack_speed)) * (1.0 + maxf(slow, 0.0))
	return maxi(1, int(ceil(max(float(skill.min_execution_ms), slowed_ms))))
