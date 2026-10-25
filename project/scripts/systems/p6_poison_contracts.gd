extends RefCounted
# P6M5-D015: Echoing suppression replaces its damage bonus; fuel unchanged.
const ECHOING_DAMAGE_PER_RANK := 0.0
const RESONANCE_DAMAGE_PER_RANK := 0.05

## D015: additive with enemy suppression; forced ticks do not use the clock.
static func echoing_suppression(rank: int) -> float:
	return [0.0, 0.4, 0.3, 0.2][clampi(rank, 0, 3)]

## Reviewed T9 fixtures/content adapters. Does not promote the playable registry.
static func apply_passives(base: PlayerStats, hastened: int, accelerant: int, echoing: int, resonance: int, critical: bool) -> PlayerStats:
	if hastened < 0 or hastened > 5 or accelerant < 0 or accelerant > 5 or echoing < 0 or echoing > 3 or resonance < 0 or resonance > 4:
		return null
	if (accelerant > 0 and hastened == 0) or (resonance > 0 and echoing == 0):
		return null
	var value: PlayerStats = base.duplicate(true)
	value.hastened_poison_rank = hastened
	value.accelerant_rank = accelerant
	value.echoing_toxin_rank = echoing
	value.resonance_rank = resonance
	value.critical_poison_enabled = critical
	return value

static func poison_strike() -> Skill:
	var skill := Skill.new()
	skill.id = "skill.poison_strike"
	skill.display_name = "Poison Strike"
	skill.category = Skill.Category.ATTACK
	skill.base_execution_ms = 1200
	skill.min_execution_ms = 500
	skill.cooldown_ms = 0
	var damage := PhysicalDamageEffect.new()
	damage.amount = 1.0 # Resolver's stable-ID weapon scaling is 0.83.
	skill.effects = [damage, preload("res://scripts/resources/forced_poison_tick_effect.gd").new()]
	return skill
