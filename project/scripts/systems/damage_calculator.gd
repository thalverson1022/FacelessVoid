class_name DamageCalculator
extends RefCounted

const MIN_DAMAGE_MULTIPLIER := 0.05


static func physical_mitigation_multiplier(armor: int) -> float:
	if armor >= 0:
		var reduction: float = (0.75 * armor) / (armor + 100.0)
		return 1.0 - reduction
	var vulnerability: float = (0.75 * absf(armor)) / (absf(armor) + 100.0)
	return 1.0 + vulnerability


static func magical_mitigation_multiplier(resistance: float) -> float:
	return 1.0 - clampf(resistance, 0.0, 1.0)


static func poison_mitigation_multiplier(poison_resistance: float) -> float:
	return magical_mitigation_multiplier(poison_resistance)


## Resolves one direct-hit physical damage effect: crit roll, crit negation,
## armor mitigation, then block. Dodge is handled by CombatResolver so the
## whole attack can skip attached effects.
## Returns {"amount": float, "is_crit": bool, "blocked_amount": float,
## "crit_negation_applied": float, "crit_negation_damage_prevented": float}.
static func resolve_physical_hit(
	raw_amount: float,
	armor: int,
	crit_chance: float,
	crit_multiplier: float,
	rng: RandomNumberGenerator,
	physical_damage_multiplier: float = 1.0,
	crit_negation: float = 0.0,
	block: float = 0.0,
	gear_physical_damage_multiplier: float = 1.0,
	talent_physical_damage_multiplier: float = 1.0
) -> Dictionary:
	return resolve_damage_packet(
		raw_amount,
		"physical",
		armor,
		0.0,
		crit_chance,
		crit_multiplier,
		rng,
		physical_damage_multiplier,
		crit_negation,
		block,
		0.0,
		gear_physical_damage_multiplier,
		talent_physical_damage_multiplier
	)


static func resolve_damage_packet(
	raw_amount: float,
	original_type: String,
	armor: int,
	resistance: float,
	crit_chance: float,
	crit_multiplier: float,
	rng: RandomNumberGenerator = null,
	physical_damage_multiplier: float = 1.0,
	crit_negation: float = 0.0,
	block: float = 0.0,
	absorb: float = 0.0,
	gear_physical_damage_multiplier: float = 1.0,
	talent_physical_damage_multiplier: float = 1.0,
	convert_to_physical: bool = false,
	convert_to_magical: bool = false,
	ignore_armor: bool = false,
	ignore_resistance: bool = false,
	physical_damage_penalty: float = 1.0
) -> Dictionary:
	var is_crit := false
	if rng != null:
		is_crit = rng.randf() < clampf(crit_chance, 0.0, 1.0)
	var amount: float = raw_amount
	var began_physical := original_type == "physical"
	if began_physical:
		var damage_multiplier := physical_damage_multiplier * gear_physical_damage_multiplier * talent_physical_damage_multiplier
		amount *= maxf(MIN_DAMAGE_MULTIPLIER, damage_multiplier)
	amount *= maxf(1.0, crit_multiplier) if is_crit else 1.0
	if began_physical:
		amount *= maxf(0.0, physical_damage_penalty)
	if not is_finite(amount):
		return _invalid_packet(is_crit)

	var entered_mitigation := amount > 0.0
	var fully_prevented := not entered_mitigation
	var mitigation_types := _mitigation_types_for(original_type, convert_to_physical, convert_to_magical)
	var before_negation_final := 0.0
	var crit_negation_applied := 0.0
	var blocked_amount := 0.0
	var absorbed_amount := 0.0
	for mitigation_type in mitigation_types:
		if mitigation_type == "physical":
			var effective_armor := 0 if ignore_armor else armor
			if is_crit and crit_negation > 0.0:
				var before_negation := amount
				amount *= 1.0 - clampf(crit_negation, 0.0, 1.0)
				crit_negation_applied += before_negation - amount
				before_negation_final = maxf(0.0, before_negation * physical_mitigation_multiplier(effective_armor) - maxf(block, 0.0))
				if before_negation > 0.0 and amount <= 0.0:
					fully_prevented = true
			amount *= physical_mitigation_multiplier(effective_armor)
			var before_block := amount
			amount = maxf(0.0, amount - maxf(block, 0.0))
			blocked_amount += before_block - amount
			if before_block > 0.0 and amount <= 0.0:
				fully_prevented = true
		elif mitigation_type == "magical":
			var effective_resistance := 0.0 if ignore_resistance else resistance
			var after_resistance := amount * magical_mitigation_multiplier(effective_resistance)
			amount = maxf(0.0, after_resistance - maxf(absorb, 0.0))
			absorbed_amount += after_resistance - amount
			if after_resistance > 0.0 and amount <= 0.0:
				fully_prevented = true
		if not is_finite(amount) or not is_finite(blocked_amount) or not is_finite(absorbed_amount) or not is_finite(crit_negation_applied):
			return _invalid_packet(is_crit)
	amount = _final_damage_amount(amount, entered_mitigation, fully_prevented)
	return {
		"amount": amount,
		"is_crit": is_crit,
		"blocked_amount": blocked_amount,
		"absorbed_amount": absorbed_amount,
		"crit_negation_applied": crit_negation_applied,
		"crit_negation_damage_prevented": maxf(0.0, before_negation_final - amount),
	}


static func resolve_magical_damage(raw_amount: float, resistance: float, absorb: float = 0.0) -> Dictionary:
	return resolve_damage_packet(raw_amount, "magical", 0, resistance, 0.0, 1.0, null, 1.0, 0.0, 0.0, absorb)


## Poison ticks do not crit.
static func resolve_poison_tick(poison_damage_per_tick: float, poison_resistance: float) -> float:
	return resolve_magical_damage(poison_damage_per_tick, poison_resistance)["amount"]


static func _mitigation_types_for(original_type: String, convert_to_physical: bool, convert_to_magical: bool) -> PackedStringArray:
	if convert_to_physical and convert_to_magical:
		return PackedStringArray(["physical", "magical"])
	if convert_to_physical:
		return PackedStringArray(["physical"])
	if convert_to_magical:
		return PackedStringArray(["magical"])
	if original_type == "physical":
		return PackedStringArray(["physical"])
	return PackedStringArray(["magical"])


static func _final_damage_amount(amount: float, entered_mitigation: bool, fully_prevented: bool) -> float:
	if not entered_mitigation or fully_prevented or amount <= 0.0:
		return 0.0
	# Damage is a float; an intermediate int64 conversion can wrap a large but
	# finite hit. Preserve rounding without introducing an integer damage cap.
	return maxf(1.0, round(amount))

static func _invalid_packet(is_crit: bool) -> Dictionary:
	return {"amount": NAN, "is_crit": is_crit, "blocked_amount": 0.0,
		"absorbed_amount": 0.0, "crit_negation_applied": 0.0,
		"crit_negation_damage_prevented": 0.0}
