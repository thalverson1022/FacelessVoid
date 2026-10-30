extends RefCounted
## Checked timer arithmetic. The float upper bound is exclusive: float(INT64_MAX)
## rounds up to 2^63 and must never be converted to an integer.
const INT64_MAX: int = 9223372036854775807
const INT64_LIMIT: float = 9223372036854775808.0

static func scaled_duration(authored_ms: int, increase: float) -> Dictionary:
	if not is_finite(increase) or increase < 0.0 or authored_ms < 0:
		return {"error": "Invalid buff duration stat or authored timer."}
	if authored_ms == 0 or increase == 0.0:
		return {"error": "", "duration_ms": authored_ms}
	return _checked_product(authored_ms, 1.0 + increase)

static func cooldown(authored_ms: int, factor: float) -> Dictionary:
	if not is_finite(factor) or factor < 0.0 or factor > 1.0 or authored_ms < 0:
		return {"error": "Invalid cooldown factor or authored timer."}
	if authored_ms == 0 or factor == 1.0:
		return {"error": "", "duration_ms": authored_ms}
	return _checked_product(authored_ms, factor)

static func _checked_product(authored_ms: int, factor: float) -> Dictionary:
	var value: float = ceilf(float(authored_ms) * factor)
	if not is_finite(value) or value >= INT64_LIMIT or value < 0.0:
		return {"error": "Buff/cooldown timer is outside signed 64-bit range."}
	return {"error": "", "duration_ms": maxi(1, int(value))}

static func deadline(time_ms: int, duration_ms: int) -> Dictionary:
	if time_ms < 0 or duration_ms < 0 or time_ms > INT64_MAX - duration_ms:
		return {"error": "Timer deadline is outside signed 64-bit range."}
	return {"error": "", "expires_at_ms": time_ms + duration_ms}

static func validation_error(player: PlayerStats) -> String:
	for chance in [player.crit_applies_penetration, player.crit_applies_potency]:
		if not is_finite(chance) or chance < 0.0 or chance > 1.0:
			return "Invalid critical defense proc probability."
	var check := cooldown(1, player.cooldown_factor)
	if check.error != "":
		return check.error
	# Validate every eligible authored family, even when its skill is inactive.
	for duration in [3000, 5000, 10000, 12000, 3000 + 1000 * player.death_pact_rank]:
		check = scaled_duration(duration, player.increased_buff_duration)
		if check.error != "":
			return check.error
	return ""

## Nominal encounter countdown and actual elapsed simulation are separate clocks.
static func fight_window(nominal_ms: int, arctic_enabled: bool) -> Dictionary:
	if nominal_ms <= 0:
		return {"error": "Encounter duration must be positive."}
	var effective_ms := nominal_ms
	if arctic_enabled:
		@warning_ignore("integer_division")
		var extra_ms: int = nominal_ms / 3
		if nominal_ms % 3 != 0:
			extra_ms += 1
		if nominal_ms > INT64_MAX - extra_ms:
			return {"error": "Encounter duration is outside signed 64-bit range."}
		effective_ms += extra_ms
	return {"error": "", "nominal_duration_ms": nominal_ms, "duration_ms": effective_ms,
		"countdown_rate": 0.75 if arctic_enabled else 1.0}
