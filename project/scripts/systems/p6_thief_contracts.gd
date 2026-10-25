extends RefCounted
## Reviewed skill descriptors. Registries explicitly choose which ones are playable.
static func skill(kind: String) -> Skill:
	if kind == "steal":
		return load("res://data/skills/steal.tres").duplicate(true)
	if kind not in ["mug", "pick_pocket", "big_score", "dance_of_death"]:
		return null
	var value := Skill.new()
	value.id = "skill." + kind
	value.display_name = kind.capitalize()
	value.base_execution_ms = 1500 if kind == "mug" else 1300
	value.min_execution_ms = 700 if kind == "mug" else 800
	if kind == "dance_of_death":
		value.category = Skill.Category.SELF_BUFF
		value.base_execution_ms = 500
		value.min_execution_ms = 500
		value.cooldown_ms = 20000
		value.dance_duration_ms = 5000
	elif kind in ["mug", "big_score"]:
		value.stolen_gold_base_cap = 50 if kind == "mug" else 0
		value.stolen_gold_per_damage = 1
		if kind == "big_score":
			value.base_execution_ms = 1800
			value.min_execution_ms = 700
			value.critical_damage_factor = 6.0
		var effect := PhysicalDamageEffect.new()
		effect.amount = 1.0
		value.effects = [effect]
	else:
		value.category = Skill.Category.DEBUFF
		value.base_execution_ms = 1800
		value.cooldown_ms = 8000
		var effect := preload("res://scripts/resources/steal_gold_effect.gd").new()
		effect.amount = 10
		value.effects = [effect]
	return value
