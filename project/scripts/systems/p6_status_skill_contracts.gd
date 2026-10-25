extends RefCounted
## Reviewed descriptors for fixtures/content promotion. Does not alter p6.compat.1.
const Buff = preload("res://scripts/resources/self_buff_effect.gd")
const Consume = preload("res://scripts/resources/consume_status_effect.gd")

static func skill(kind: String) -> Skill:
	if kind not in ["master_of_poisons", "virulent_poison", "beguiling_presence", "poison_vile", "touch_of_darkness"]:
		return null
	var value := Skill.new()
	value.id = "skill." + kind
	value.display_name = kind.capitalize()
	value.category = Skill.Category.DEBUFF if kind == "poison_vile" else Skill.Category.SELF_BUFF
	value.base_execution_ms = 1800 if kind == "poison_vile" else 500
	value.min_execution_ms = 500
	match kind:
		"touch_of_darkness":
			value.cooldown_ms = 30000
			var effect := Consume.new()
			effect.status = "poison"
			effect.grants_touch_of_darkness = true
			value.effects.append(effect)
		"poison_vile":
			var effect := PoisonDamageEffect.new()
			effect.stacks_applied = 20
			value.effects.append(effect)
		"beguiling_presence":
			value.cooldown_ms = 30000
			var effect := Consume.new()
			effect.elemental_per_consumed = 1.0
			value.effects.append(effect)
		_:
			value.cooldown_ms = 10000
			var effect := Buff.new()
			effect.kind = kind
			value.effects.append(effect)
	return value

static func apply_passives(base: PlayerStats, death_touch_rank: int, umbral_presence: bool, bribery_rank: int = 0) -> PlayerStats:
	if death_touch_rank < 0 or death_touch_rank > 3 or bribery_rank < 0 or bribery_rank > 3:
		return null
	var value: PlayerStats = base.duplicate(true)
	BuildResolver._apply_all_stack_bonus(value, 3 * death_touch_rank)
	if umbral_presence:
		value.poison_stack_cap = maxi(80, value.poison_stack_cap)
	value.bribery_base_stacks = 2 * bribery_rank
	return value

## Attach the approved forced tick to a separately reviewed attack descriptor.
## Does not guess Poison Strike's remaining T9 attack values or promote content.
static func with_forced_poison_tick(attack: Skill) -> Skill:
	var value: Skill = attack.duplicate(true)
	value.effects.append(preload("res://scripts/resources/forced_poison_tick_effect.gd").new())
	return value
