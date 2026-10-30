extends RefCounted
## Pure cast planning: no RNG draws, resource consumption or source mutation.
## Cooldown slots spend exactly 100ms, independently of speed/slow/procs.
const COOLDOWN_ATTEMPT_MS := 100
const SelfBuffEffect = preload("res://scripts/resources/self_buff_effect.gd")
const ConsumeEffect = preload("res://scripts/resources/consume_status_effect.gd")
const ApplyDefenseEffect = preload("res://scripts/resources/apply_defense_debuff_effect.gd")
const ExsanguinateEffect = preload("res://scripts/resources/exsanguinate_effect.gd")
const TimerMath = preload("res://scripts/systems/combat_timer_math.gd")
var _deadlines: Dictionary = {}

func available_at(skill_id: String) -> int:
	return int(_deadlines.get(skill_id, 0))

## Called at completion of an eligible macro cast, never for its proc children.
func start(skill: Skill, time_ms: int, cooldown_factor: float = 1.0) -> String:
	if skill.cooldown_ms > 0:
		var timer := TimerMath.cooldown(skill.cooldown_ms, cooldown_factor)
		if timer.error != "":
			return timer.error
		var end := TimerMath.deadline(time_ms, timer.duration_ms)
		if end.error != "":
			return end.error
		_deadlines[skill.id] = end.expires_at_ms
	return ""

func reset() -> void:
	_deadlines.clear()

static func validation_error(rotation: Array[Skill], duration_ms: int) -> String:
	if duration_ms <= 0:
		return "Combat duration must be positive."
	var durations := {}
	for skill in rotation:
		if skill == null:
			return "Macro slots cannot contain a missing skill."
		var effect_error := skill_effect_error(skill)
		if effect_error != "":
			return effect_error
		if skill.cooldown_ms < 0 or (skill.cooldown_ms > 0 and skill.id.strip_edges().is_empty()):
			return "Cooldowns require a nonnegative duration and stable skill ID."
		if durations.has(skill.id) and durations[skill.id] != skill.cooldown_ms:
			return "Duplicate skill IDs must have the same cooldown."
		durations[skill.id] = skill.cooldown_ms
	return ""


static func skill_effect_error(skill: Skill) -> String:
	if skill.category not in [Skill.Category.ATTACK, Skill.Category.DEBUFF, Skill.Category.SELF_BUFF]:
		return "Unknown skill category."
	if skill.id == "skill.exsanguinate" and (skill.category != Skill.Category.DEBUFF or skill.effects.size() != 1 or not skill.effects[0] is ExsanguinateEffect):
		return "Exsanguinate requires its explicit health-removal Debuff effect."
	for effect in skill.effects:
		if effect is ExsanguinateEffect and (skill.id != "skill.exsanguinate" or skill.category != Skill.Category.DEBUFF or skill.effects.size() != 1):
			return "Health removal requires the Exsanguinate Debuff."
		if effect is SelfBuffEffect and (skill.category != Skill.Category.SELF_BUFF or effect.kind not in ["master_of_poisons", "virulent_poison"]):
			return "Invalid self buff effect."
		if effect is ConsumeEffect:
			if effect.grants_touch_of_darkness and (skill.category != Skill.Category.SELF_BUFF or effect.status != "poison" or effect.amount != -1 or effect.poison_per_consumed != 0 or effect.elemental_per_consumed != 0.0):
				return "Touch of Darkness requires Self Buff and Consume all Poison."
			if effect.status not in ["poison", "decay"] or effect.amount < -1 or effect.poison_per_consumed < 0 or not is_finite(effect.elemental_per_consumed) or effect.elemental_per_consumed < 0.0 or effect.elemental_duration_ms != 10000:
				return "Invalid Consume effect."
		elif effect is ApplyDefenseEffect:
			if effect.status not in ["penetration", "potency"] or effect.base_stacks < 0:
				return "Invalid defense debuff application."
	return ""


static func plan(skill: Skill, player: PlayerStats, slow: float, start_ms: int, window_ms: int, use_minimum: bool, lifecycle = null, available_at_ms: int = 0) -> Dictionary:
	var ordinary_ms := maxi(1, skill.min_execution_ms) if use_minimum else CombatTiming.execution_time_ms_with_slow(skill, player.attack_speed, slow)
	var execution_ms := ordinary_ms
	if lifecycle != null:
		execution_ms = lifecycle.preview_execution_ms(skill.id, ordinary_ms, skill.min_execution_ms, start_ms)
	var cooling := start_ms < available_at_ms
	if cooling:
		ordinary_ms = COOLDOWN_ATTEMPT_MS
		execution_ms = COOLDOWN_ATTEMPT_MS
	return {"source_id": skill.id, "requested_start_ms": start_ms,
		"cooldown_blocked": cooling, "cooldown_available_at_ms": available_at_ms,
		"ordinary_execution_ms": ordinary_ms, "execution_ms": execution_ms,
		"end_ms": start_ms + execution_ms, "attack_speed": player.attack_speed,
		"slow": slow, "min_cast_time_proc_applied": use_minimum,
		"fits_window": start_ms + execution_ms <= window_ms}

## Reduce only currently running skill cooldowns; unused recovery never carries.
func reduce_running_cooldowns(time_ms: int, amount_ms: int) -> Dictionary:
	var changes := {}
	if amount_ms <= 0:
		return changes
	for id in _deadlines:
		var before: int = _deadlines[id]
		if before > time_ms:
			_deadlines[id] = maxi(time_ms, before - amount_ms)
			changes[id] = {"before": before, "after": _deadlines[id]}
	return changes
