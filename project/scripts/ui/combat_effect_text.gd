extends RefCounted
## Presentation only: stable identities retain their runtime meaning.
const NAMES := {
	"skill.rending_thrust": "Rending Slash", "skill.killers_mark": "Death Strike",
	"skill.toxic_flurry": "Beguiling Strike", "skill.heavy_slash": "Heavy Slash",
	"buff.dance": "Dance of Death", "combat.theft": "Credited theft",
	"buff.meditation": "Meditation", "buff.dash": "Dash",
	"gear.legendary.lolzorzs_locket": "Lolzorz's Locket",
}
static func name_for(id: String) -> String:
	if id.begins_with("dance."): return "Dance of Death instance " + id.get_slice(".", 1)
	if id.begins_with("touch."): return "Touch of Darkness instance " + id.get_slice(".", 1)
	return NAMES.get(id, id.get_slice(".", id.get_slice_count(".") - 1).replace("_", " ").capitalize())

static func is_health_removal(cast: CombatResolver.CastEvent) -> bool:
	# Zero-Shred Exsanguinate is still a health-removal operation.
	return cast.health_removal_captured or cast.damage_contributions.any(func(entry): return entry.get("kind") == "health_removal")
static func rule_for(id: String) -> String:
	match id:
		"buff.footwork": return "Quick Cut grants stacks (max 5, refreshed 3s base). Leaping Plunge spends them at cast start to shorten windup, respecting the minimum cast time; spent stacks remain displayed until impact."
		"buff.readiness": return "One untimed stack from connected retriggers. Parry Strike requires and spends it at cast start; spent stack remains displayed until impact."
		"buff.precision": return "One untimed stack from Quick Cut. Stab or Heavy Slash spends it for a guaranteed Retrigger on connection, including proc casts. Dance and Precision give one guarantee."
		"buff.dance": return "Connected macro attacks gain a guaranteed Retrigger for a base 5s; triggered and retriggered attacks receive no Dance guarantee."
		"buff.bypass": return "Stab grants stacks (max 3, refreshed 3s base); each grants +10% elemental damage, or +20% with Crown."
		"buff.virulent_poison": return "Each activation has 5 independent untimed stacks. Natural, forced and free retriggered Poison packets deal double damage per active instance, or triple with Crown, and spend one stack from each. Empty activations spend none. Retriggers calculate with current buffs; exhausted stacks give no bonus."
		"buff.master_of_poisons": return "Elemental damage ignores resistance for a base 5s. Stored Decay remains; normal resistance resumes on expiry."
		"buff.touch_of_darkness": return "Each consumed Poison stack grants +10% attack speed and +2 base physical damage for a base 12s. Crown doubles both bonuses. Independent activations add bonuses."
		"buff.beguiling_presence": return "Each consumed Decay stack grants +1 base elemental damage and +2 percentage points critical chance for a base 10s. Crown doubles both bonuses. Independent activations add bonuses; Signet converts the uncapped critical chance input."
		"buff.greed": return "Counts credited theft after Increased Gold; adds no independent stat bonus and resets each fight."
		"buff.meditation": return "Retriggers grant one base stack, modified by All Stacks and normal stack doubling. Each gives 20% more physical damage, up to 5 stacks. Every grant refreshes the shared 3s base duration."
		"buff.dash": return "Critical packets have a 30% chance to grant one base stack, modified by All Stacks and normal stack doubling. Each grants +5% attack speed, or +10% with Crown, up to 20 stacks. Every grant refreshes the shared 3s base duration."
		"status.penetration": return "Each stack removes 1 block. Further grants refresh the timer; Death Pact changes base duration to 4/5/6s."
		"status.potency": return "Each stack removes 1 absorb. Further grants refresh the timer; Death Pact changes base duration to 4/5/6s."
	return ""
static func magnitude_for(id: String, state: Dictionary) -> String:
	var units := int(state.get("units", state.get("charges", 0)))
	var amount := float(state.get("magnitude", 0))
	match id:
		"buff.footwork": return "Cast reduction: %.1f%%" % (amount * 100)
		"buff.bypass": return "Elemental damage bonus: +%.1f%%" % (amount * 100)
		"buff.touch_of_darkness": return "Attack speed: +%.1f%% | Base physical damage: +%d" % [amount * 100.0, roundi(amount * 20.0)]
		"buff.virulent_poison": return "Poison damage multiplier: ×%.1f" % float(state.get("poison_multiplier", 2.0))
		"buff.meditation": return "Physical damage multiplier: ×%.1f" % (1.0 + amount)
		"buff.dash": return "Attack speed: +%.1f%%" % (amount * 100.0)
		"buff.beguiling_presence": return "Base elemental damage: +%.1f | Critical chance: +%.1f percentage points" % [amount, float(state.get("crit_chance_bonus", 0)) * 100]
		"status.penetration": return "Block removed: %d" % units
		"status.potency": return "Absorb removed: %d" % units
	return ""

static func count_for(id: String, state: Dictionary) -> String:
	var units := int(state.get("units", state.get("charges", 0)))
	match id:
		"buff.master_of_poisons": return "Resistance ignore active"
		"buff.dance": return "Guaranteed macro Retrigger active"
		"buff.greed": return "%d credited gold stolen this fight" % units
		"buff.beguiling_presence": return "%d Decay stacks absorbed" % units
		"buff.touch_of_darkness": return "%d Poison stacks consumed" % units
		"buff.readiness", "buff.precision", "buff.virulent_poison": return "%d stacks" % units
	return "%d stacks" % units
