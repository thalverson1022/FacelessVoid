extends RefCounted

const PoisonCadence = preload("res://scripts/systems/poison_cadence.gd")
const Gold = preload("res://scripts/systems/combat_gold.gd")
const PoisonContracts = preload("res://scripts/systems/p6_poison_contracts.gd")
const EventTrace = preload("res://scripts/systems/combat_event_trace.gd")
const TalentBuffs = preload("res://scripts/systems/combat_talent_buffs.gd")
const SelfBuffs = preload("res://scripts/systems/combat_self_buffs.gd")
const SelfBuffEffect = preload("res://scripts/resources/self_buff_effect.gd")
const ForcedPoisonTick = preload("res://scripts/resources/forced_poison_tick_effect.gd")
const StealGold = preload("res://scripts/resources/steal_gold_effect.gd")
const BladedancerLifecycle = preload("res://scripts/systems/bladedancer_effect_lifecycle.gd")
const StatState = preload("res://scripts/systems/combat_stat_state.gd")
const MacroScheduler = preload("res://scripts/systems/combat_macro_scheduler.gd")
const DefenseDebuffs = preload("res://scripts/systems/combat_defense_debuffs.gd")
const ApplyDefenseEffect = preload("res://scripts/resources/apply_defense_debuff_effect.gd")
const ConsumeEffect = preload("res://scripts/resources/consume_status_effect.gd")
const POISON_TICK_INTERVAL_MS: int = 1000
const MAX_POISON_STACKS: int = 20
const MAX_SHRED_STACKS: int = 500
const MAX_RETRIGGER_CHAIN_DEPTH: int = 16
## P6M3-T2 user-approved budget, shared across a root cast's entire subtree.
const MAX_TRIGGER_CANDIDATES_PER_ROOT: int = 1024
const BASE_DECAY_REDUCTION_FRACTION: float = 0.2
const STUN_TRIGGER_HIT_PERCENT: float = 0.12
const INTERRUPT_REPEAT_THRESHOLD: int = 3
const NEGATIVE_DEFENSE_BASE_PER_POINT := 0.1
const DEATH_STRIKE_SKILL_ID := "skill.killers_mark"
const DEATH_STRIKE_DAMAGE_SCALING := 1.11
const DEATH_STRIKE_DAMAGE_PER_POISON_STACK := 2.0
const WEAPON_SCALING_BY_SKILL_ID := {
	"skill.stab": 1.00,
	"skill.heavy_slash": 1.66,
	"skill.quick_cut": 0.66,
	"skill.parry_strike": 1.20,
	"skill.leaping_plunge": 1.90,
	"skill.steal": 1.06,
	"skill.mug": 1.0,
	"skill.big_score": 0.9,
	"skill.venom_jab": 0.22,
	"skill.poison_strike": 0.83,
	"skill.rending_thrust": 0.78,
	DEATH_STRIKE_SKILL_ID: DEATH_STRIKE_DAMAGE_SCALING,
	"skill.toxic_flurry": 0.22,
	"skill.distilled_corruption": 1.0,
}


const CastEvent = CombatResolver.CastEvent
const TickEvent = CombatResolver.TickEvent
const CombatResult = CombatResolver.CombatResult

static func resolve(rotation: Array[Skill], player: PlayerStats, monster: Monster, duration_ms: int, rng_seed: int = 1, trace_enabled: bool = false) -> CombatResult:
	var result := CombatResult.new()
	result.presentation_initial = {"stash": player.current_gold, "poison": 0, "shred": 0, "decay": 0,
		"armor": monster.armor, "poison_resistance": monster.poison_resistance,
		"slow": effective_enemy_slow(player, monster), "gold_stats": Gold.crit_values(player, player.current_gold, 0)}
	result.trace.enabled = trace_enabled
	result.self_buffs.trace = result.trace
	result.duration_ms = duration_ms
	var schedule_error := MacroScheduler.validation_error(rotation, duration_ms)
	if schedule_error != "":
		result.is_valid = false
		result.failure = {"code": "invalid_macro_schedule", "time_ms": 0, "message": schedule_error}
		result.trace.record("simulation_failed", 0, {}, result.failure)
		return result
	if PoisonContracts.apply_passives(player, player.hastened_poison_rank, player.accelerant_rank, player.echoing_toxin_rank, player.resonance_rank, player.critical_poison_enabled) == null:
		result.is_valid = false
		result.failure = {"code": "invalid_poison_ranks", "time_ms": 0, "message": "Invalid Poison ranks or missing prerequisite."}
		return result
	result.poison_stack_cap = _poison_stack_cap(player)
	if player.derivation_error != "":
		result.is_valid = false
		result.failure = {"code": "invalid_stat_derivation", "time_ms": 0, "message": player.derivation_error}
		result.trace.record("simulation_failed", 0, {}, result.failure)
		return result
	if player.riposte_rank < 0 or player.riposte_rank > 2:
		_fail_effect_lifecycle(result, "Riposte rank must be between zero and two.")
		return result
	result.talent_buffs = TalentBuffs.new(player, result.trace)
	if result.talent_buffs.initialization_error != "":
		_fail_effect_lifecycle(result, result.talent_buffs.initialization_error)
		return result
	result.defense_debuffs = DefenseDebuffs.new(player, _effective_enemy_block(player, monster), _effective_enemy_absorb(player, monster), result.trace)
	if result.defense_debuffs.initialization_error != "":
		_fail_effect_lifecycle(result, result.defense_debuffs.initialization_error)
		return result
	if player.footwork_rank != 0 or player.readiness_enabled or player.precision_duration_ms != 0 or player.dance_duration_ms != 0:
		result.effect_lifecycle = BladedancerLifecycle.new(player.footwork_rank, player.readiness_enabled, null, result.trace,
			{"precision": player.precision_duration_ms, "dance": player.dance_duration_ms})
		result.footwork_grant = TalentBuffs.stack_grant(player.bonus_footwork_stacks, player)
		if result.effect_lifecycle.initialization_error != "":
			_fail_effect_lifecycle(result, result.effect_lifecycle.initialization_error)
			return result
	result.trace.record("build_stats", 0, {"source_id": "build.baseline"}, {
		"values": StatState.value_snapshot(player), "sources": player.stat_sources,
		"derivations": player.derivation_details})

	if rotation.is_empty():
		return result

	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	result.combat_rng = rng

	var current_armor: int = monster.armor
	var current_shred_stacks: int = 0
	var current_poison_resistance: float = monster.poison_resistance
	var active_stacks: int = 0
	result.poison_clock.interval_ms = PoisonCadence.interval(player, _effective_enemy_suppress(player, monster))
	var cast_time_ms: int = 0
	var rotation_index: int = 0
	var cleanse_counter: int = 0
	var interrupt_state := {
		"repeat_skill_id": "",
		"repeat_count": 0,
		"skips_by_skill": {},
	}
	var gold_stolen_this_fight := 0
	var simulated_current_gold := player.current_gold
	var clipped_plan: Dictionary = {}
	while true:
		# Advance beats before sampling temporary IAS at the next cast start.
		active_stacks = _advance_poison(result, mini(cast_time_ms, duration_ms), active_stacks, player, current_armor, current_poison_resistance, monster)
		var buff_error: String = result.talent_buffs.state.advance(mini(cast_time_ms, duration_ms))
		if buff_error != "":
			_fail_effect_lifecycle(result, buff_error)
			_cleanup_effects(result, result.trace.last_time_ms, "invalid_simulation")
			return result
		var cast_player: PlayerStats = result.talent_buffs.live_player(player)
		var skill: Skill = rotation[rotation_index % rotation.size()]
		var cooldown_deadline: int = result.scheduler.available_at(skill.id)
		var used_min_cast_time: bool = cast_time_ms >= cooldown_deadline and player.min_cast_time_proc_chance > 0.0 and rng.randf() <= player.min_cast_time_proc_chance
		var plan := MacroScheduler.plan(skill, cast_player, effective_enemy_slow(player, monster),
			cast_time_ms, duration_ms, used_min_cast_time, result.effect_lifecycle, cooldown_deadline)
		var ordinary_exec_ms: int = plan.ordinary_execution_ms
		var cast_end_ms: int = plan.end_ms
		if not plan.fits_window:
			clipped_plan = plan
			clipped_plan["rotation_index"] = rotation_index % rotation.size()
			break
		var event := CastEvent.new()
		event.cast_start_ms = cast_time_ms
		event.time_ms = cast_end_ms
		event.skill = skill
		event.rotation_index = rotation_index % rotation.size()
		event.cooldown_blocked = plan.cooldown_blocked
		event.cooldown_available_at_ms = cooldown_deadline
		event.min_cast_time_proc_applied = used_min_cast_time
		_begin_cast(result, event, null, cast_player, ordinary_exec_ms)
		if not result.is_valid:
			_cleanup_effects(result, result.trace.last_time_ms, "invalid_simulation")
			result.rng_final_state = rng.state
			return result
		result.root_trigger_candidates = 0
		active_stacks = _advance_poison(result, cast_end_ms, active_stacks, player, current_armor, current_poison_resistance, monster)
		# Cooldown begins at completed windup, including dodged/interrupted attempts.
		# Missing resources and clipped casts retain their no-cooldown behavior.
		if not event.cooldown_blocked and not event.resource_unavailable and result.is_valid and skill.cooldown_ms > 0:
			result.scheduler.start(skill, cast_end_ms)
			event.cooldown_available_at_ms = result.scheduler.available_at(skill.id)
			result.trace.record("cooldown_started", cast_end_ms, _event_context(event), {
				"cooldown_available_at_ms": event.cooldown_available_at_ms,
				"cooldown_ms": skill.cooldown_ms})


		var counts_for_mechanics := skill.category == Skill.Category.ATTACK and not _skill_is_hold(skill)
		var is_direct_attack := counts_for_mechanics and _skill_is_direct_attack(skill)
		if event.cooldown_blocked or event.resource_unavailable or _apply_interrupt_to_event(event, skill, player, monster, interrupt_state):
			result.cast_events.append(event)
			_record_cast(result, event)
			_end_cast(result, event)
			cast_time_ms = cast_end_ms
			rotation_index += 1
			continue
		var state := _apply_skill_effects(
			skill, event, player, monster, current_armor, current_poison_resistance,
			active_stacks, current_shred_stacks, rng, "cast", gold_stolen_this_fight, simulated_current_gold, result
		)
		current_armor = state["armor"]
		current_shred_stacks = state["shred_stacks"]
		current_poison_resistance = state["poison_resistance"]
		gold_stolen_this_fight += int(state.get("gold_stolen", 0))
		simulated_current_gold += int(state.get("gold_stolen", 0))
		var finalize_state := _finalize_cast_event(
			result, event, player, monster, active_stacks, current_armor,
			current_poison_resistance, current_shred_stacks, cleanse_counter, counts_for_mechanics
		)
		active_stacks = finalize_state["active_stacks"]
		current_armor = finalize_state["armor"]
		current_shred_stacks = finalize_state["shred_stacks"]
		current_poison_resistance = finalize_state["poison_resistance"]
		cleanse_counter = finalize_state["cleanse_counter"]
		if (is_direct_attack or (player.death_blade_enabled and not event.poison_applications.is_empty())) and not bool(state.get("dodged", false)):
			var retrigger_state := _resolve_retrigger_chain(
				event, result, player, monster, current_armor, current_poison_resistance,
				current_shred_stacks, active_stacks, rng, gold_stolen_this_fight, simulated_current_gold,
				cleanse_counter, interrupt_state, 0
			)
			active_stacks = retrigger_state["active_stacks"]
			current_armor = retrigger_state["armor"]
			current_shred_stacks = retrigger_state["shred_stacks"]
			current_poison_resistance = retrigger_state["poison_resistance"]
			cleanse_counter = retrigger_state["cleanse_counter"]
			gold_stolen_this_fight = retrigger_state["gold_stolen_this_fight"]
			simulated_current_gold = retrigger_state["simulated_current_gold"]
		if not result.is_valid:
			_cleanup_effects(result, result.trace.last_time_ms, "invalid_simulation")
			result.rng_final_state = rng.state
			return result
		_end_cast(result, event)
		_sync_poison_cadence(result, cast_end_ms, player, monster)
		cast_time_ms = cast_end_ms + event.stun_duration_ms
		rotation_index += 1

	active_stacks = _advance_poison(result, duration_ms, active_stacks, player, current_armor, current_poison_resistance, monster)

	_cleanup_effects(result, duration_ms, "fight_end")
	if not clipped_plan.is_empty():
		clipped_plan["decision"] = "window_exhausted"
		result.trace.record("schedule_decision", duration_ms,
			{"source_id": clipped_plan.source_id, "origin_kind": "macro"}, clipped_plan)
	result.dps = result.total_damage / (float(duration_ms) / 1000.0)
	result.is_win = result.total_damage >= float(monster.hp)
	result.overkill_damage = maxf(0.0, result.total_damage - float(monster.hp)) if result.is_win else 0.0
	result.rng_final_state = rng.state
	return result


static func _event_context(event: CastEvent) -> Dictionary:
	return {"source_id": event.skill.id if event.skill != null else "",
		"cast_id": event.cast_id, "parent_cast_id": event.parent_cast_id,
		"root_cast_id": event.root_cast_id, "origin_kind": event.origin_kind}


static func _begin_cast(result: CombatResult, event: CastEvent, parent: CastEvent = null, player: PlayerStats = null, ordinary_ms: int = 0) -> void:
	event.cast_id = result.trace.allocate_cast_id()
	event.parent_cast_id = parent.cast_id if parent != null else 0
	event.root_cast_id = parent.root_cast_id if parent != null else event.cast_id
	if result.talent_buffs != null and player != null:
		var error: String = result.talent_buffs.state.advance(event.cast_start_ms)
		if error != "":
			_fail_effect_lifecycle(result, error)
			return
		player = result.talent_buffs.live_player(player)
	if event.cooldown_blocked:
		_advance_effects(result, event.cast_start_ms)
	elif result.effect_lifecycle != null:
		event.lifecycle_snapshot = result.effect_lifecycle.begin_cast(event.skill.id,
			ordinary_ms, event.skill.min_execution_ms, event.cast_start_ms, _event_context(event))
		if event.lifecycle_snapshot.error != "":
			_fail_effect_lifecycle(result, event.lifecycle_snapshot.error)
		else:
			event.resource_unavailable = not event.lifecycle_snapshot.eligible
			if event.skill.id == "skill.leaping_plunge" and player != null and player.riposte_rank > 0:
				event.lifecycle_snapshot["riposte_multiplier"] = 1.0 + 0.2 * player.riposte_rank * int(event.lifecycle_snapshot.footwork_consumed)
			if parent != null:
				event.lifecycle_snapshot.execution_ms = 0
	event.cooldown_available_at_ms = result.scheduler.available_at(event.skill.id)
	result.trace.record("schedule_decision", event.cast_start_ms, _event_context(event), {
		"rotation_index": event.rotation_index,
		"decision": "cooldown_skip" if event.cooldown_blocked else "spend_time_without_effect" if event.resource_unavailable else "cast",
		"cooldown_available_at_ms": event.cooldown_available_at_ms,
		"cooldown_bypassed": parent != null,
		"reason": "cooldown" if event.cooldown_blocked else "missing_readiness" if event.resource_unavailable else "ready",
		"requested_start_ms": event.cast_start_ms, "end_ms": event.time_ms,
		"execution_ms": event.time_ms - event.cast_start_ms,
		"ordinary_execution_ms": ordinary_ms if parent == null else 0,
		"lifecycle": event.lifecycle_snapshot})
	result.trace.record("cast_start", event.cast_start_ms, _event_context(event), {
		"rotation_index": event.rotation_index, "end_ms": event.time_ms,
		"attack_speed": player.attack_speed if player != null else 0.0,
		"min_cast_time_proc_applied": event.min_cast_time_proc_applied,
		"lifecycle": event.lifecycle_snapshot})


static func _record_cast(result: CombatResult, event: CastEvent) -> void:
	_advance_effects(result, event.time_ms)
	event.sequence = result.trace.record("cast_resolved", event.time_ms, _event_context(event), {
		"damage": event.physical_damage, "gold_stolen": event.gold_stolen,
		"connected": not event.cooldown_blocked and not event.was_dodged and not event.was_interrupted and not event.resource_unavailable and _skill_is_direct_attack(event.skill),
		"resource_unavailable": event.resource_unavailable,
		"cooldown_blocked": event.cooldown_blocked,
		"dodged": event.was_dodged, "interrupted": event.was_interrupted, "stun_duration_ms": event.stun_duration_ms,
		"crit": event.is_crit, "blocked_amount": event.blocked_amount,
		"poison_stacks_applied": event.poison_stacks_applied,
		"shred_stacks_applied": event.shred_stacks_applied,
		"decay_stacks_applied": event.decay_stacks_applied,
		"cleanse_triggered": event.cleanse_triggered,
		"status_after": event.status_snapshot,
		"stats_at_impact": event.stat_snapshot,
		"weapon_damage_rolls": event.weapon_damage_rolls})
	for transaction in event.status_transactions:
		result.trace.record("status_transaction", event.time_ms, _event_context(event), transaction)
	for transaction in event.gold_transactions:
		result.trace.record("gold_transaction", event.time_ms, _event_context(event), transaction)
	if _has_guaranteed_repeat(event) and (event.was_dodged or event.was_interrupted or event.resource_unavailable):
		_trigger_decision(result, event, -1, "guarantee_suppressed", {
			"cause": "dodge" if event.was_dodged else "interruption" if event.was_interrupted else "missing_resource",
			"guarantee_sources": event.lifecycle_snapshot.guaranteed_repeat_sources})
	if bool(event.stat_snapshot.get("poison_suppressed", false)):
		result.trace.record("poison_suppressed", event.time_ms, _event_context(event), {"reason": "death_blade"})


static func _end_cast(result: CombatResult, event: CastEvent) -> void:
	if result.effect_lifecycle != null and result.is_valid:
		var connected := not event.cooldown_blocked and not event.was_dodged and not event.was_interrupted and not event.resource_unavailable and _skill_is_direct_attack(event.skill)
		var error: String = result.effect_lifecycle.finish_cast(event.skill.id, connected,
			event.trigger_label == "RETRIGGER", event.time_ms, result.footwork_grant, _event_context(event))
		if error != "":
			_fail_effect_lifecycle(result, error)
		if result.is_valid and event.skill.id == "skill.dance_of_death" and not event.cooldown_blocked and not event.was_dodged and not event.was_interrupted and not event.resource_unavailable:
			var dance_error: String = result.effect_lifecycle.activate_dance(event.time_ms, _event_context(event))
			if dance_error != "":
				_fail_effect_lifecycle(result, dance_error)
	if result.talent_buffs != null and result.is_valid:
		var connected := not event.cooldown_blocked and not event.was_dodged and not event.was_interrupted and not event.resource_unavailable and _skill_is_direct_attack(event.skill)
		var error: String = result.talent_buffs.finish_cast(event.skill.id, connected, event.time_ms, _event_context(event))
		if error != "":
			_fail_effect_lifecycle(result, error)
	result.trace.record("cast_end", event.time_ms, _event_context(event))


static func _advance_effects(result: CombatResult, time_ms: int) -> void:
	if result.talent_buffs != null:
		var error: String = result.talent_buffs.state.advance(time_ms)
		if error != "":
			_fail_effect_lifecycle(result, error)
	result.self_buffs.advance(time_ms)
	if result.defense_debuffs != null:
		var defense_error: String = result.defense_debuffs.state.advance(time_ms)
		if defense_error != "":
			_fail_effect_lifecycle(result, defense_error)
	if result.effect_lifecycle != null:
		var error: String = result.effect_lifecycle.state.advance(time_ms, true)
		if error != "":
			_fail_effect_lifecycle(result, error)


static func _cleanup_effects(result: CombatResult, time_ms: int, reason: String) -> void:
	if result.talent_buffs != null:
		if reason == "fight_end":
			var expiry_error: String = result.talent_buffs.state.advance(time_ms)
			if expiry_error != "":
				_fail_effect_lifecycle(result, expiry_error)
		var error: String = result.talent_buffs.state.reset(time_ms, reason)
		if error != "":
			_fail_effect_lifecycle(result, error)
	result.self_buffs.advance(time_ms)
	result.self_buffs.reset(time_ms, reason)
	result.scheduler.reset()
	if result.defense_debuffs != null:
		var defense_error: String = result.defense_debuffs.state.reset(time_ms, reason)
		if defense_error != "":
			_fail_effect_lifecycle(result, defense_error)
	if result.effect_lifecycle != null:
		if reason == "fight_end":
			var expiry_error: String = result.effect_lifecycle.state.advance(time_ms)
			if expiry_error != "":
				_fail_effect_lifecycle(result, expiry_error)
		var error: String = result.effect_lifecycle.state.reset(time_ms, reason)
		if error != "":
			_fail_effect_lifecycle(result, error)


static func _fail_effect_lifecycle(result: CombatResult, message: String) -> void:
	result.is_valid = false
	result.failure = {"code": "invalid_effect_lifecycle", "time_ms": result.trace.last_time_ms, "message": message}
	result.trace.record("simulation_failed", result.trace.last_time_ms, {}, result.failure)


static func _trigger_decision(result: CombatResult, source: CastEvent, index: int, reason: String, payload: Dictionary = {}) -> void:
	payload["candidate_index"] = index
	payload["reason"] = reason
	result.trace.record("trigger_decision", source.time_ms, _event_context(source), payload)


static func _fail_trigger_budget(result: CombatResult, source: CastEvent, index: int) -> void:
	result.is_valid = false
	result.failure = {"code": "trigger_candidate_limit", "time_ms": source.time_ms,
		"source_id": source.skill.id, "cast_id": source.cast_id,
		"root_cast_id": source.root_cast_id, "candidate_index": index,
		"limit": MAX_TRIGGER_CANDIDATES_PER_ROOT, "evaluated": result.root_trigger_candidates}
	# This failure remains available with tracing off; partial totals are diagnostic only.
	result.trace.record("simulation_failed", source.time_ms, _event_context(source), result.failure)


static func _trigger_matches_source(trigger: TriggeredSkillEffect, source_skill: Skill) -> bool:
	if trigger.source_skill_ids.is_empty():
		return true
	if source_skill == null:
		return false
	return trigger.source_skill_ids.has(source_skill.id)


static func _has_guaranteed_repeat(event: CastEvent) -> bool:
	return not event.lifecycle_snapshot.get("guaranteed_repeat_sources", PackedStringArray()).is_empty()


static func _triggers_for_source(source_event: CastEvent, player: PlayerStats) -> Array[Dictionary]:
	var triggers: Array[Dictionary] = []
	if player == null or source_event == null or source_event.skill == null or _skill_is_hold(source_event.skill):
		return triggers
	if _skill_is_direct_attack(source_event.skill):
		for effect in player.triggered_skill_effects:
			triggers.append({"effect": effect, "origin": "proc"})
	if player.death_blade_enabled and player.death_blade_chance > 0.0:
		for application_index in source_event.poison_applications.size():
			var effect := TriggeredSkillEffect.new()
			effect.skill = load("res://data/skills/stab.tres") as Skill
			effect.chance = clampf(player.death_blade_chance, 0.0, 1.0)
			triggers.append({"effect": effect, "origin": "proc", "application_index": application_index,
				"application": source_event.poison_applications[application_index]})
	if (player.retrigger_chance > 0.0 or _has_guaranteed_repeat(source_event)) and _skill_is_direct_attack(source_event.skill):
		var self_retrigger := TriggeredSkillEffect.new()
		self_retrigger.skill = source_event.skill
		self_retrigger.chance = 1.0 if _has_guaranteed_repeat(source_event) else clampf(player.retrigger_chance, 0.0, 1.0)
		self_retrigger.source_skill_ids = PackedStringArray([source_event.skill.id])
		triggers.append({"effect": self_retrigger, "origin": "guaranteed_repeat" if _has_guaranteed_repeat(source_event) else "random_repeat"})
	return triggers


static func _apply_interrupt_to_event(event: CastEvent, skill: Skill, player: PlayerStats, monster: Monster, interrupt_state: Dictionary) -> bool:
	if skill.category != Skill.Category.ATTACK:
		event.interrupt_repeat_count_after = int(interrupt_state.get("repeat_count", 0))
		return false
	var counts_for_mechanics := not _skill_is_hold(skill)
	var is_direct_attack := counts_for_mechanics and _skill_is_direct_attack(skill)
	if not is_direct_attack:
		interrupt_state["repeat_skill_id"] = ""
		interrupt_state["repeat_count"] = 0
		return false
	var skill_key := _interrupt_skill_key(skill)
	var skips_by_skill: Dictionary = interrupt_state["skips_by_skill"]
	if int(skips_by_skill.get(skill_key, 0)) > 0:
		event.was_interrupted = true
		event.interrupt_skipped = true
		skips_by_skill[skill_key] = maxi(0, int(skips_by_skill.get(skill_key, 0)) - 1)
		interrupt_state["repeat_skill_id"] = ""
		interrupt_state["repeat_count"] = 0
		event.interrupt_repeat_count_after = 0
		return true
	var repeat_skill_id := String(interrupt_state.get("repeat_skill_id", ""))
	var repeat_count := int(interrupt_state.get("repeat_count", 0))
	if skill_key == repeat_skill_id:
		repeat_count += 1
	else:
		repeat_skill_id = skill_key
		repeat_count = 1
	interrupt_state["repeat_skill_id"] = repeat_skill_id
	interrupt_state["repeat_count"] = repeat_count
	event.interrupt_repeat_count = repeat_count
	event.interrupt_repeat_count_after = repeat_count
	if _effective_enemy_interrupt_skip_count(player, monster) <= 0 or repeat_count < INTERRUPT_REPEAT_THRESHOLD:
		return false
	event.was_interrupted = true
	event.interrupt_triggered = true
	event.interrupt_skip_count_applied = _effective_enemy_interrupt_skip_count(player, monster)
	skips_by_skill[skill_key] = event.interrupt_skip_count_applied
	interrupt_state["repeat_skill_id"] = ""
	interrupt_state["repeat_count"] = 0
	event.interrupt_repeat_count_after = 0
	return true


static func _finalize_cast_event(result: CombatResult, event: CastEvent, player: PlayerStats, monster: Monster, active_stacks: int, current_armor: int, current_poison_resistance: float, current_shred_stacks: int, cleanse_counter: int, counts_for_mechanics: bool) -> Dictionary:
	result.total_damage += event.physical_damage
	result.gold_stolen += event.gold_stolen
	if not event.was_dodged and not event.was_interrupted and not event.resource_unavailable:
		for effect in event.skill.effects:
			if effect is SelfBuffEffect:
				result.self_buffs.grant(effect.kind, event.time_ms, _event_context(event))
			elif effect is ForcedPoisonTick:
				active_stacks = _resolve_poison_tick(result, event.time_ms, active_stacks, player, current_armor, current_poison_resistance, monster, 0, true, _event_context(event))
			elif effect is ConsumeEffect:
				var before: int = active_stacks if effect.status == "poison" else result.active_decay_stacks
				var consumed: int = before if effect.amount == -1 else mini(before, maxi(0, effect.amount))
				var after := before - consumed
				if effect.status == "poison":
					active_stacks = after
				else:
					result.active_decay_stacks = after
					current_poison_resistance = monster.poison_resistance * pow(1.0 - _decay_value(player), after)
				_status_transaction(event, effect.status, "consumed", before, after, 0)
				event.status_transactions.back()["consumed"] = consumed
				event.status_transactions.back()["requested_consumption"] = effect.amount
				event.status_transactions.back()["keyword_consume"] = true
				if consumed > 0:
					if effect.grants_touch_of_darkness:
						var error: String = result.talent_buffs.grant_touch(consumed, event.time_ms, _event_context(event))
						if error != "":
							_fail_effect_lifecycle(result, error)
					if effect.elemental_per_consumed > 0.0:
						result.self_buffs.grant("beguiling_presence", event.time_ms, _event_context(event), consumed * effect.elemental_per_consumed, consumed)
					if player.death_pact_rank > 0:
						for status in ["penetration", "potency"]:
							var grant: Dictionary = result.defense_debuffs.grant(status, consumed, player, event.time_ms, _event_context(event), true)
							if grant.error != "":
								_fail_effect_lifecycle(result, grant.error)
					if effect.poison_per_consumed > 0 and not (player.death_blade_enabled and event.skill.id == "skill.stab"):
						var requested := _applied_poison_stacks(consumed * effect.poison_per_consumed, player)
						event.poison_stacks_applied += requested
						event.poison_applications.append({"source": "conversion", "requested": requested})
						_record_damage_contribution(event, event.skill, event.cast_kind, 0.0, false, 0, 0.0, requested)
			elif effect is ApplyDefenseEffect:
				var base: int = player.assassin_tree_points if effect.use_assassin_points else effect.base_stacks
				var grant: Dictionary = result.defense_debuffs.grant(effect.status, base, player, event.time_ms, _event_context(event))
				if grant.error != "":
					_fail_effect_lifecycle(result, grant.error)
	var stun_duration_ms := _effective_enemy_stun_duration_ms(player, monster)
	if stun_duration_ms > 0 and _stun_should_trigger(event, monster):
		event.stun_duration_ms = stun_duration_ms
	var poison_before := active_stacks
	active_stacks = mini(active_stacks + event.poison_stacks_applied, _poison_stack_cap(player))
	var application_count := poison_before
	for application in event.poison_applications:
		var next_count: int = mini(application_count + int(application.requested), _poison_stack_cap(player))
		application["before"] = application_count
		application["after"] = next_count
		application["applied"] = next_count - application_count
		application["overflow"] = int(application.requested) - int(application.applied)
		_status_transaction(event, "poison", String(application.source), application_count, next_count, int(application.requested))
		application_count = next_count
	if event.decay_stacks_applied > 0:
		var decay_before := result.active_decay_stacks
		result.active_decay_stacks += event.decay_stacks_applied
		_status_transaction(event, "decay", "applied", decay_before, result.active_decay_stacks, event.decay_stacks_applied)
	if counts_for_mechanics and monster.cleanse_threshold > 0 and not _denies_enemy_cleanse(player):
		cleanse_counter += 1
		event.cleanse_counter = cleanse_counter
		if cleanse_counter >= monster.cleanse_threshold:
			cleanse_counter = 0
			_status_transaction(event, "poison", "cleansed", active_stacks, 0, 0)
			if not player.shred_cleanse_immune:
				_status_transaction(event, "shred", "cleansed", current_shred_stacks, 0, 0)
			_status_transaction(event, "decay", "cleansed", result.active_decay_stacks, 0, 0)
			result.active_decay_stacks = 0
			active_stacks = 0
			if not player.shred_cleanse_immune:
				current_shred_stacks = 0
				current_armor = monster.armor
			var cleanse_error: String = result.defense_debuffs.cleanse(event.time_ms, _event_context(event))
			if cleanse_error != "":
				_fail_effect_lifecycle(result, cleanse_error)
			current_poison_resistance = monster.poison_resistance
			event.cleanse_triggered = true
			event.cleanse_counter = 0
	event.status_snapshot = {"armor": current_armor, "poison_resistance": current_poison_resistance,
		"poison": active_stacks, "shred": current_shred_stacks, "decay": result.active_decay_stacks,
		"defenses": result.defense_debuffs.values()}
	result.cast_events.append(event)
	_record_cast(result, event)
	if result.effect_lifecycle != null and result.is_valid:
		var connected := not event.was_dodged and not event.was_interrupted and not event.resource_unavailable and _skill_is_direct_attack(event.skill)
		var hit_error: String = result.effect_lifecycle.on_hit(event.skill.id, connected, event.time_ms, _event_context(event))
		if hit_error != "":
			_fail_effect_lifecycle(result, hit_error)
	return {
		"active_stacks": active_stacks,
		"armor": current_armor,
		"shred_stacks": current_shred_stacks,
		"poison_resistance": current_poison_resistance,
		"cleanse_counter": cleanse_counter,
	}


static func _resolve_retrigger_chain(source_event: CastEvent, result: CombatResult, player: PlayerStats, monster: Monster, current_armor: int, current_poison_resistance: float, current_shred_stacks: int, active_stacks: int, rng: RandomNumberGenerator, gold_stolen_this_fight: int, simulated_current_gold: int, cleanse_counter: int, interrupt_state: Dictionary, depth: int) -> Dictionary:
	if depth >= MAX_RETRIGGER_CHAIN_DEPTH:
		source_event.retrigger_cap_reached = true
		_trigger_decision(result, source_event, -1, "depth_limit", {"limit": MAX_RETRIGGER_CHAIN_DEPTH})
		return {
			"active_stacks": active_stacks,
			"armor": current_armor,
			"shred_stacks": current_shred_stacks,
			"poison_resistance": current_poison_resistance,
			"cleanse_counter": cleanse_counter,
			"gold_stolen_this_fight": gold_stolen_this_fight,
			"simulated_current_gold": simulated_current_gold,
		}

	var triggers := _triggers_for_source(source_event, player)
	for candidate_index in range(triggers.size()):
		if result.root_trigger_candidates >= MAX_TRIGGER_CANDIDATES_PER_ROOT:
			_fail_trigger_budget(result, source_event, candidate_index)
			break
		result.root_trigger_candidates += 1
		result.trigger_candidates_evaluated += 1
		var candidate: Dictionary = triggers[candidate_index]
		var trigger: TriggeredSkillEffect = candidate.effect
		if trigger == null or trigger.skill == null:
			_trigger_decision(result, source_event, candidate_index, "missing_skill")
			continue
		var effect_error := MacroScheduler.skill_effect_error(trigger.skill)
		if effect_error != "":
			_fail_effect_lifecycle(result, effect_error)
			break
		if candidate.has("application") and int(candidate.application.applied) <= 0:
			_trigger_decision(result, source_event, candidate_index, "poison_not_added", {
				"application_index": candidate.application_index, "application": candidate.application})
			continue
		if not _trigger_matches_source(trigger, source_event.skill):
			_trigger_decision(result, source_event, candidate_index, "source_filtered", {"target_skill_id": trigger.skill.id})
			continue
		if not trigger.source_origin_kinds.is_empty() and not trigger.source_origin_kinds.has(source_event.origin_kind):
			_trigger_decision(result, source_event, candidate_index, "origin_filtered", {
				"target_skill_id": trigger.skill.id, "allowed_origins": trigger.source_origin_kinds})
			continue
		var guaranteed: bool = candidate.origin == "guaranteed_repeat"
		var roll: Variant = null if guaranteed else rng.randf()
		if not guaranteed and float(roll) > trigger.chance:
			_trigger_decision(result, source_event, candidate_index, "roll_failed", {
				"target_skill_id": trigger.skill.id, "chance": trigger.chance, "roll": roll,
				"application_index": candidate.get("application_index", -1), "application": candidate.get("application", {})})
			continue

		var event := CastEvent.new()
		event.cast_start_ms = source_event.time_ms
		event.time_ms = source_event.time_ms
		event.skill = trigger.skill
		event.rotation_index = source_event.rotation_index
		event.cast_kind = "proc"
		# Explicit origin separates chance-one authored procs from guaranteed repeats.
		event.origin_kind = String(candidate.origin)
		event.trigger_source_skill_id = source_event.skill.id if source_event.skill != null else ""
		event.trigger_label = _trigger_label(trigger, source_event.skill)
		event.retrigger_depth = depth + 1
		_trigger_decision(result, source_event, candidate_index, "child_emitted", {
			"target_skill_id": trigger.skill.id, "chance": trigger.chance, "roll": roll,
			"guaranteed": guaranteed, "guarantee_sources": source_event.lifecycle_snapshot.get("guaranteed_repeat_sources", PackedStringArray()) if guaranteed else PackedStringArray(),
			"application_index": candidate.get("application_index", -1), "application": candidate.get("application", {}),
			"child_cast_id": result.trace.next_cast_id + 1, "child_origin_kind": event.origin_kind})
		_begin_cast(result, event, source_event, player)
		if not result.is_valid:
			break
		if event.resource_unavailable or _apply_interrupt_to_event(event, trigger.skill, player, monster, interrupt_state):
			result.cast_events.append(event)
			_record_cast(result, event)
			_end_cast(result, event)
			continue
		var state := _apply_skill_effects(
			trigger.skill, event, player, monster, current_armor, current_poison_resistance,
			active_stacks, current_shred_stacks, rng, "proc", gold_stolen_this_fight, simulated_current_gold, result
		)
		current_armor = state["armor"]
		current_shred_stacks = state["shred_stacks"]
		current_poison_resistance = state["poison_resistance"]
		gold_stolen_this_fight += int(state.get("gold_stolen", 0))
		simulated_current_gold += int(state.get("gold_stolen", 0))
		if not bool(state.get("dodged", false)):
			source_event.triggered_skill_names.append(trigger.skill.display_name)
			if not source_event.trigger_labels.has(event.trigger_label):
				source_event.trigger_labels.append(event.trigger_label)
		var finalize_state := _finalize_cast_event(
			result, event, player, monster, active_stacks, current_armor,
			current_poison_resistance, current_shred_stacks, cleanse_counter, trigger.skill.category == Skill.Category.ATTACK and not _skill_is_hold(trigger.skill)
		)
		active_stacks = finalize_state["active_stacks"]
		current_armor = finalize_state["armor"]
		current_shred_stacks = finalize_state["shred_stacks"]
		current_poison_resistance = finalize_state["poison_resistance"]
		cleanse_counter = finalize_state["cleanse_counter"]
		if (_skill_is_direct_attack(trigger.skill) or (player.death_blade_enabled and not event.poison_applications.is_empty())) and not bool(state.get("dodged", false)):
			var chain_state := _resolve_retrigger_chain(
				event, result, player, monster, current_armor, current_poison_resistance,
				current_shred_stacks, active_stacks, rng, gold_stolen_this_fight, simulated_current_gold,
				cleanse_counter, interrupt_state, depth + 1
			)
			active_stacks = chain_state["active_stacks"]
			current_armor = chain_state["armor"]
			current_shred_stacks = chain_state["shred_stacks"]
			current_poison_resistance = chain_state["poison_resistance"]
			cleanse_counter = chain_state["cleanse_counter"]
			gold_stolen_this_fight = chain_state["gold_stolen_this_fight"]
			simulated_current_gold = chain_state["simulated_current_gold"]
		if not result.is_valid:
			break
		_end_cast(result, event)
	return {
		"active_stacks": active_stacks,
		"armor": current_armor,
		"shred_stacks": current_shred_stacks,
		"poison_resistance": current_poison_resistance,
		"cleanse_counter": cleanse_counter,
		"gold_stolen_this_fight": gold_stolen_this_fight,
		"simulated_current_gold": simulated_current_gold,
	}


static func _interrupt_skill_key(skill: Skill) -> String:
	if skill == null:
		return ""
	if skill.id.strip_edges() != "":
		return skill.id
	return skill.display_name


static func _trigger_label(trigger: TriggeredSkillEffect, source_skill: Skill) -> String:
	if trigger == null or trigger.skill == null:
		return "PROC"
	if source_skill != null and trigger.skill.id == source_skill.id:
		return "RETRIGGER"
	if (
		source_skill != null
		and source_skill.id == "skill.quick_cut"
		and trigger.skill.id == "skill.rending_thrust"
	):
		return "Opportunity Strike"
	return "PROC"


static func _skill_is_direct_attack(skill: Skill) -> bool:
	if skill != null and skill.category != Skill.Category.ATTACK:
		return false
	if skill == null:
		return false
	for effect in skill.effects:
		if (effect is PhysicalDamageEffect) or (effect is StackScalingPhysicalDamageEffect):
			return true
	return false


static func _skill_is_hold(skill: Skill) -> bool:
	return skill != null and skill.id == "skill.hold"


static func _stun_should_trigger(event: CastEvent, monster: Monster) -> bool:
	if event == null or monster == null or monster.hp <= 0:
		return false
	var trigger_damage := float(monster.hp) * STUN_TRIGGER_HIT_PERCENT
	return _largest_direct_hit(event) >= trigger_damage


static func _largest_direct_hit(event: CastEvent) -> float:
	if event.damage_contributions.is_empty():
		return event.physical_damage
	var largest := 0.0
	for contribution in event.damage_contributions:
		largest = maxf(largest, float(contribution.get("damage", 0.0)))
	return largest


static func _sync_poison_cadence(result: CombatResult, time_ms: int, player: PlayerStats, monster: Monster) -> void:
	result.poison_clock.advance(time_ms)
	var live: PlayerStats = result.talent_buffs.live_player(player)
	var interval: int = PoisonCadence.interval(live, _effective_enemy_suppress(live, monster))
	if interval != result.poison_clock.interval_ms:
		var before: int = result.poison_clock.interval_ms
		result.poison_clock.interval_ms = interval
		result.trace.record("poison_cadence", time_ms, {"source_id": "status.poison"},
			{"before_interval_ms": before, "interval_ms": interval,
			"progress": result.poison_clock.progress, "next_tick_ms": result.poison_clock.deadline()})


static func _advance_poison(result: CombatResult, until_ms: int, stacks: int, player: PlayerStats, armor: int, resistance: float, monster: Monster) -> int:
	var dynamic := player.hastened_poison_rank + player.accelerant_rank > 0
	while true:
		var tick_at: int = result.poison_clock.deadline()
		var boundary := tick_at
		if dynamic:
			for item in result.talent_buffs.state.snapshot().values():
				var expiry := int(item.expires_at_ms)
				if expiry > result.poison_clock.time_ms:
					boundary = mini(boundary, expiry)
		if boundary > until_ms:
			break
		result.poison_clock.advance(boundary)
		if boundary == tick_at:
			stacks = _resolve_poison_tick(result, boundary, stacks, player, armor, resistance, monster, result.poison_clock.interval_ms)
			result.poison_clock.tick()
		if dynamic:
			result.talent_buffs.state.advance(boundary)
			_sync_poison_cadence(result, boundary, player, monster)
	result.poison_clock.advance(until_ms)
	return stacks


static func _resolve_poison_tick(result: CombatResult, tick_time_ms: int, active_stacks: int, player: PlayerStats, current_armor: int, current_poison_resistance: float, monster: Monster, tick_interval_ms: int, forced: bool = false, context: Dictionary = {}) -> int:
	_advance_effects(result, tick_time_ms)
	if result.talent_buffs != null:
		player = result.talent_buffs.live_player(player)
	var defenses: Dictionary = result.defense_debuffs.values() if result.defense_debuffs != null else {"block": _effective_enemy_block(player, monster), "absorb": _effective_enemy_absorb(player, monster)}
	var buffs: Dictionary = result.self_buffs.values()
	var negative_absorb_bonus := NEGATIVE_DEFENSE_BASE_PER_POINT * maxf(0.0, -float(defenses.absorb))
	var tick := TickEvent.new()
	tick.stacks_before = active_stacks
	tick.time_ms = tick_time_ms
	tick.origin_kind = "forced_tick" if forced else "natural_tick"
	tick.tick_interval_ms = tick_interval_ms
	tick.requested_stacks = 3 if player.resonance_rank > 0 else (2 if player.echoing_toxin_rank > 0 else 1)
	var talent_multiplier := (1.0 + PoisonContracts.ECHOING_DAMAGE_PER_RANK * player.echoing_toxin_rank) * (1.0 + PoisonContracts.RESONANCE_DAMAGE_PER_RANK * player.resonance_rank) * player.poison_tick_damage_multiplier
	if active_stacks > 0:
		tick.had_active_stack = true
		tick.stacks_consumed = mini(active_stacks, tick.requested_stacks)
		active_stacks -= tick.stacks_consumed
		tick.raw_damage = (player.poison_damage_per_tick + (negative_absorb_bonus + float(buffs.elemental_base)) * player.elemental_damage_multiplier) * float(buffs.poison_multiplier) * tick.stacks_consumed * talent_multiplier
		if player.critical_poison_enabled:
			var gold_values := Gold.crit_values(player, player.current_gold + result.gold_stolen, result.gold_stolen)
			tick.crit_chance = clampf(gold_values.crit_chance, 0.0, 1.0)
			tick.crit_multiplier = gold_values.crit_multiplier
		var damage := DamageCalculator.resolve_damage_packet(
			tick.raw_damage,
			"magical",
			current_armor,
			0.0 if buffs.ignore_resistance else current_poison_resistance,
			tick.crit_chance,
			tick.crit_multiplier,
			result.combat_rng if player.critical_poison_enabled else null,
			1.0,
			monster.crit_negation,
			float(defenses.block),
			float(defenses.absorb),
			1.0,
			1.0,
			_converts_damage_to_physical(player),
			_converts_damage_to_magical(player),
			_ignores_armor_without_shred(player),
			_ignores_resistance_with_physical_penalty(player),
			1.0
		)
		tick.charge_spends = result.self_buffs.spend_poison_charges(tick_time_ms)
		tick.damage = damage["amount"]
		tick.is_crit = damage.is_crit
		tick.blocked_amount = damage.blocked_amount
		tick.crit_negation_applied = damage.crit_negation_applied
		tick.absorbed_amount = damage["absorbed_amount"]
		result.total_damage += tick.damage
	tick.stacks_remaining = active_stacks
	result.tick_events.append(tick)
	tick.sequence = result.trace.record("poison_tick", tick_time_ms,
		{"source_id": "status.poison", "origin_kind": tick.origin_kind,
		"cast_id": context.get("cast_id", 0), "parent_cast_id": context.get("parent_cast_id", 0),
		"root_cast_id": context.get("root_cast_id", 0),
		"lifecycle_reason": "depleted" if tick.stacks_consumed > 0 else ("forced_tick" if tick.had_active_stack else "empty_tick")},
		{"damage": tick.damage, "absorbed_amount": tick.absorbed_amount,
		"raw_damage": tick.raw_damage, "is_crit": tick.is_crit,
		"crit_chance": tick.crit_chance, "crit_multiplier": tick.crit_multiplier,
		"blocked_amount": tick.blocked_amount, "crit_negation_applied": tick.crit_negation_applied,
		"requested_stacks": tick.requested_stacks, "talent_multiplier": talent_multiplier,
		"stacks_before": tick.stacks_before, "charge_spends": tick.charge_spends,
		"tick_interval_ms": tick.tick_interval_ms, "trigger_source_id": context.get("source_id", ""),
		"poison_damage_per_tick": player.poison_damage_per_tick,
		"defenses": defenses, "negative_absorb_base_bonus": negative_absorb_bonus if tick.had_active_stack else 0.0,
		"stacks_consumed": tick.stacks_consumed, "stacks_remaining": tick.stacks_remaining,
		"buffs": buffs, "keyword_consume": false, "stacks_depleted": tick.stacks_consumed})
	return active_stacks


static func _apply_skill_effects(skill: Skill, event: CastEvent, player: PlayerStats, monster: Monster, current_armor: int, current_poison_resistance: float, active_poison_stacks: int, active_shred_stacks: int, rng: RandomNumberGenerator, contribution_kind: String, gold_stolen_this_fight: int = 0, current_gold: int = 0, result: CombatResult = null) -> Dictionary:
	if result != null:
		_advance_effects(result, event.time_ms)
		if result.talent_buffs != null:
			player = result.talent_buffs.live_player(player)
	var defenses: Dictionary = result.defense_debuffs.values() if result != null and result.defense_debuffs != null else {"block": _effective_enemy_block(player, monster), "absorb": _effective_enemy_absorb(player, monster)}
	var damage_resistance := 0.0 if result != null and result.self_buffs.values().ignore_resistance else current_poison_resistance
	var theft_events := 0
	var negative_block_bonus := NEGATIVE_DEFENSE_BASE_PER_POINT * maxf(0.0, -float(defenses.block))
	event.stat_snapshot = StatState.value_snapshot(player)
	if result != null:
		event.stat_snapshot["self_buffs"] = result.self_buffs.values()
		event.stat_snapshot["damage_resistance"] = damage_resistance
	event.stat_snapshot["effective_block"] = defenses.block
	event.stat_snapshot["effective_absorb"] = defenses.absorb
	event.stat_snapshot["negative_block_base_bonus"] = negative_block_bonus
	if _skill_can_be_dodged(skill, active_poison_stacks) and rng.randf() < clampf(_effective_enemy_dodge_chance(player, monster), 0.0, 1.0):
		event.was_dodged = true
		event.dodged_attacks += 1
		return {
			"armor": current_armor,
			"shred_stacks": active_shred_stacks,
			"poison_resistance": current_poison_resistance,
			"dodged": true,
			"gold_stolen": 0,
		}
	var effect_poison_stacks := 0
	var effect_shred_stacks := 0
	var effect_decay_stacks := 0
	var contribution_damage := 0.0
	var contribution_crit := false
	var contribution_armor_reduction := 0
	var contribution_resistance_reduction := 0.0
	var contribution_gold_stolen := 0
	var contribution_weapon_roll := _roll_weapon_damage_for_skill(skill, player, active_poison_stacks, rng)
	if not contribution_weapon_roll.is_empty():
		if event.weapon_damage_roll <= 0:
			event.weapon_damage_roll = int(contribution_weapon_roll["roll"])
			event.weapon_damage_min = int(contribution_weapon_roll["min"])
			event.weapon_damage_max = int(contribution_weapon_roll["max"])
		contribution_weapon_roll["kind"] = contribution_kind
		contribution_weapon_roll["skill_id"] = skill.id if skill != null else ""
		contribution_weapon_roll["name"] = skill.display_name if skill != null else ""
		event.weapon_damage_rolls.append(contribution_weapon_roll)
	var gold_values := Gold.crit_values(player, current_gold, gold_stolen_this_fight)
	event.stat_snapshot["gold"] = gold_values
	var crit_chance: float = gold_values.crit_chance
	if skill.id == "skill.stab" and player.death_blade_enabled:
		crit_chance += float(player.special_effects.get("trial_death_blade_stab_crit_bonus", 0.0))
	if player.side_step_enabled and skill.id == "skill.parry_strike":
		crit_chance = 1.0
	var crit_multiplier: float = maxf(1.0, gold_values.crit_multiplier * skill.critical_damage_factor)
	var stolen_base := skill.stolen_gold_damage_bonus(gold_stolen_this_fight)
	event.stat_snapshot["stolen_gold_base_damage"] = stolen_base
	var physical_buckets := player.physical_damage_buckets()
	var skill_multiplier := float(player.skill_damage_multipliers.get(skill.id, 1.0)) * float(event.lifecycle_snapshot.get("riposte_multiplier", 1.0))
	physical_buckets["talent"] = float(physical_buckets["talent"]) * skill_multiplier
	event.stat_snapshot["skill_damage_multiplier"] = skill_multiplier
	event.stat_snapshot["effective_crit_chance"] = clampf(crit_chance, 0.0, 1.0)
	event.stat_snapshot["effective_crit_multiplier"] = crit_multiplier
	var death_strike_packet_applied := false
	for effect in skill.effects:
		if _skill_is_death_strike(skill) and not death_strike_packet_applied and ((effect is PhysicalDamageEffect) or (effect is StackScalingPhysicalDamageEffect)):
			death_strike_packet_applied = true
			var roll_amount := float(contribution_weapon_roll.get("roll", 0))
			var raw_base := _damage_base_with_bonus(roll_amount + (DEATH_STRIKE_DAMAGE_PER_POISON_STACK * float(active_poison_stacks)), player.bonus_physical_damage + negative_block_bonus)
			var raw_amount := raw_base * DEATH_STRIKE_DAMAGE_SCALING
			var hit := _apply_conversion_to_physical_hit(
				raw_amount,
				current_armor,
				damage_resistance,
				crit_chance,
				crit_multiplier,
				rng,
				physical_buckets,
				player,
				monster, defenses
			)
			event.physical_damage += hit.amount
			event.is_crit = event.is_crit or hit.is_crit
			event.blocked_amount += hit.blocked_amount
			event.crit_negation_applied += hit.crit_negation_applied
			event.crit_negation_damage_prevented += hit.crit_negation_damage_prevented
			contribution_damage += hit.amount
			contribution_crit = contribution_crit or hit.is_crit
		elif _skill_is_death_strike(skill) and ((effect is PhysicalDamageEffect) or (effect is StackScalingPhysicalDamageEffect)):
			continue
		elif effect is PhysicalDamageEffect:
			var physical_effect: PhysicalDamageEffect = effect
			var raw_amount := _damage_base_with_bonus(physical_effect.amount, player.bonus_physical_damage + negative_block_bonus + stolen_base)
			var weapon_scaling := _weapon_scaling_for_skill(skill)
			if weapon_scaling > 0.0:
				raw_amount = _damage_base_with_bonus(float(contribution_weapon_roll.get("roll", 0)), player.bonus_physical_damage + negative_block_bonus + stolen_base) * weapon_scaling
			var hit := _apply_conversion_to_physical_hit(
				raw_amount,
				current_armor,
				damage_resistance,
				crit_chance,
				crit_multiplier,
				rng,
				physical_buckets,
				player,
				monster, defenses
			)
			event.physical_damage += hit.amount
			event.is_crit = event.is_crit or hit.is_crit
			event.blocked_amount += hit.blocked_amount
			event.crit_negation_applied += hit.crit_negation_applied
			event.crit_negation_damage_prevented += hit.crit_negation_damage_prevented
			contribution_damage += hit.amount
			contribution_crit = contribution_crit or hit.is_crit
		elif effect is StackScalingPhysicalDamageEffect:
			var stack_effect: StackScalingPhysicalDamageEffect = effect
			if active_poison_stacks > 0:
				var raw_amount := _damage_base_with_bonus(stack_effect.damage_per_stack * float(active_poison_stacks), player.bonus_physical_damage + negative_block_bonus)
				var hit := _apply_conversion_to_physical_hit(
					raw_amount,
					current_armor,
					damage_resistance,
					crit_chance,
					crit_multiplier,
					rng,
					physical_buckets,
					player,
					monster, defenses
				)
				event.physical_damage += hit.amount
				event.is_crit = event.is_crit or hit.is_crit
				event.blocked_amount += hit.blocked_amount
				event.crit_negation_applied += hit.crit_negation_applied
				event.crit_negation_damage_prevented += hit.crit_negation_damage_prevented
				contribution_damage += hit.amount
				contribution_crit = contribution_crit or hit.is_crit
		elif effect is PoisonDamageEffect:
			var poison_effect: PoisonDamageEffect = effect
			effect_poison_stacks += poison_effect.stacks_applied
		elif effect is ArmorReductionEffect:
			var armor_effect: ArmorReductionEffect = effect
			if _ignores_armor_without_shred(player):
				continue
			effect_shred_stacks += max(0, armor_effect.amount)
		elif effect is PoisonResistanceReductionEffect:
			effect_decay_stacks += 1
		elif effect is StealGold:
			var transaction := Gold.theft(effect.amount, player.gold_reward_multiplier, current_gold + contribution_gold_stolen, gold_stolen_this_fight + contribution_gold_stolen, skill.id, player)
			event.gold_transactions.append(transaction)
			var stolen: int = transaction.credited_amount
			contribution_gold_stolen += stolen
			if stolen > 0:
				theft_events += 1
		elif effect is StealGoldOnCritEffect:
			var steal_effect: StealGoldOnCritEffect = effect
			if contribution_crit:
				var transaction := Gold.theft(steal_effect.amount, player.gold_reward_multiplier, current_gold + contribution_gold_stolen, gold_stolen_this_fight + contribution_gold_stolen, skill.id, player)
				event.gold_transactions.append(transaction)
				var stolen: int = transaction.credited_amount
				contribution_gold_stolen += stolen
				if stolen > 0:
					theft_events += 1
	if player.bribery_base_stacks > 0 and not _ignores_armor_without_shred(player):
		for theft in theft_events:
			var applied := _apply_shred_stacks(player.bribery_base_stacks + player.bonus_shred_stacks, active_shred_stacks, player, event, "bribery")
			active_shred_stacks = int(applied.stacks)
			current_armor = _armor_after_shred(monster.armor, active_shred_stacks, player)
			event.shred_stacks_applied += int(applied.applied)
			event.shred_value = player.shred_value
			event.armor_reduction_applied += int(applied.applied) * player.shred_value
			contribution_armor_reduction += int(applied.applied) * player.shred_value
	event.gold_stolen += contribution_gold_stolen
	var poison_stacks := effect_poison_stacks if effect_poison_stacks > 0 else skill.poison_stacks_applied
	var applied_poison_stacks := 0
	var suppress_poison := player.death_blade_enabled and skill.id == "skill.stab"
	if suppress_poison:
		event.stat_snapshot["poison_suppressed"] = true
	if poison_stacks > 0 and not suppress_poison:
		applied_poison_stacks = _applied_poison_stacks(poison_stacks, player)
		event.poison_stacks_applied += applied_poison_stacks
		event.poison_applications.append({"source": "skill", "requested": applied_poison_stacks})
	if not suppress_poison and _skill_is_direct_attack(skill) and contribution_crit and player.elemental_proc_chance > 0.0 and rng.randf() <= clampf(player.elemental_proc_chance, 0.0, 1.0):
		var crit_poison_stacks := _applied_poison_stacks(1, player)
		applied_poison_stacks += crit_poison_stacks
		event.poison_stacks_applied += crit_poison_stacks
		event.poison_applications.append({"source": "critical_proc", "requested": crit_poison_stacks})
	if effect_decay_stacks > 0:
		var decay_state := _apply_decay_stacks(effect_decay_stacks, current_poison_resistance, player)
		current_poison_resistance = float(decay_state["poison_resistance"])
		var applied_decay_stacks := int(decay_state["applied"])
		event.decay_stacks_applied += applied_decay_stacks
		event.decay_value = _decay_value(player)
		event.poison_resistance_reduction_applied = _combine_reduction(event.poison_resistance_reduction_applied, float(decay_state["reduction"]))
		contribution_resistance_reduction = _combine_reduction(contribution_resistance_reduction, float(decay_state["reduction"]))
		if applied_decay_stacks > 0 and _decay_applies_shred(player) and not _ignores_armor_without_shred(player):
			var mirrored_shred_state := _apply_shred_stacks(1 + player.bonus_shred_stacks, active_shred_stacks, player, event, "decay_triggered") if player.independent_decay_shred else _apply_shred_stack_total(applied_decay_stacks, active_shred_stacks, event, "mirrored_decay")
			active_shred_stacks = int(mirrored_shred_state["stacks"])
			current_armor = _armor_after_shred(monster.armor, active_shred_stacks, player)
			event.shred_stacks_applied += int(mirrored_shred_state["applied"])
			event.shred_value = player.shred_value
			event.armor_reduction_applied += int(mirrored_shred_state["applied"]) * player.shred_value
			contribution_armor_reduction += int(mirrored_shred_state["applied"]) * player.shred_value
	if effect_shred_stacks > 0:
		var shred_state := _apply_shred_stacks(effect_shred_stacks + player.bonus_shred_stacks, active_shred_stacks, player, event, "skill")
		active_shred_stacks = int(shred_state["stacks"])
		current_armor = _armor_after_shred(monster.armor, active_shred_stacks, player)
		event.shred_stacks_applied += int(shred_state["applied"])
		event.shred_value = player.shred_value
		event.armor_reduction_applied += int(shred_state["applied"]) * player.shred_value
		contribution_armor_reduction += int(shred_state["applied"]) * player.shred_value
	if _skill_is_direct_attack(skill) and player.shred_chance > 0.0 and not _ignores_armor_without_shred(player) and rng.randf() <= clampf(player.shred_chance, 0.0, 1.0):
		var shred_state := _apply_shred_stacks(1 + player.bonus_shred_stacks, active_shred_stacks, player, event, "chance_proc")
		active_shred_stacks = int(shred_state["stacks"])
		current_armor = _armor_after_shred(monster.armor, active_shred_stacks, player)
		event.shred_stacks_applied += int(shred_state["applied"])
		event.shred_value = player.shred_value
		event.armor_reduction_applied += int(shred_state["applied"]) * player.shred_value
		contribution_armor_reduction += int(shred_state["applied"]) * player.shred_value
	if _skill_is_direct_attack(skill) and player.decay_chance > 0.0 and rng.randf() <= clampf(player.decay_chance, 0.0, 1.0):
		var chance_decay_state := _apply_decay_stacks(1, current_poison_resistance, player)
		current_poison_resistance = float(chance_decay_state["poison_resistance"])
		var chance_decay_stacks := int(chance_decay_state["applied"])
		event.decay_stacks_applied += chance_decay_stacks
		event.decay_value = _decay_value(player)
		event.poison_resistance_reduction_applied = _combine_reduction(event.poison_resistance_reduction_applied, float(chance_decay_state["reduction"]))
		contribution_resistance_reduction = _combine_reduction(contribution_resistance_reduction, float(chance_decay_state["reduction"]))
		if chance_decay_stacks > 0 and _decay_applies_shred(player) and not _ignores_armor_without_shred(player):
			var chance_mirrored_shred_state := _apply_shred_stacks(1 + player.bonus_shred_stacks, active_shred_stacks, player, event, "decay_triggered") if player.independent_decay_shred else _apply_shred_stack_total(chance_decay_stacks, active_shred_stacks, event, "mirrored_decay")
			active_shred_stacks = int(chance_mirrored_shred_state["stacks"])
			current_armor = _armor_after_shred(monster.armor, active_shred_stacks, player)
			event.shred_stacks_applied += int(chance_mirrored_shred_state["applied"])
			event.shred_value = player.shred_value
			event.armor_reduction_applied += int(chance_mirrored_shred_state["applied"]) * player.shred_value
			contribution_armor_reduction += int(chance_mirrored_shred_state["applied"]) * player.shred_value
	_record_damage_contribution(
		event,
		skill,
		contribution_kind,
		contribution_damage,
		contribution_crit,
		contribution_armor_reduction,
		contribution_resistance_reduction,
		applied_poison_stacks,
		contribution_gold_stolen
	)
	return {
		"armor": current_armor,
		"shred_stacks": active_shred_stacks,
		"poison_resistance": current_poison_resistance,
		"dodged": false,
		"gold_stolen": contribution_gold_stolen,
	}


static func _apply_conversion_to_physical_hit(raw_amount: float, current_armor: int, current_poison_resistance: float, crit_chance: float, crit_multiplier: float, rng: RandomNumberGenerator, physical_buckets: Dictionary, player: PlayerStats, monster: Monster, defenses: Dictionary = {}) -> Dictionary:
	return DamageCalculator.resolve_damage_packet(
		raw_amount,
		"physical",
		current_armor,
		current_poison_resistance,
		crit_chance,
		crit_multiplier,
		rng,
		float(physical_buckets["legacy"]),
		monster.crit_negation,
		float(defenses.get("block", _effective_enemy_block(player, monster))),
		float(defenses.get("absorb", _effective_enemy_absorb(player, monster))),
		float(physical_buckets["gear"]),
		float(physical_buckets["talent"]),
		_converts_damage_to_physical(player),
		_converts_damage_to_magical(player),
		_ignores_armor_without_shred(player),
		_ignores_resistance_with_physical_penalty(player),
		_physical_damage_penalty(player)
	)


static func _skill_can_be_dodged(skill: Skill, active_poison_stacks: int) -> bool:
	if skill == null or skill.category != Skill.Category.ATTACK:
		return false
	for effect in skill.effects:
		if effect is PhysicalDamageEffect:
			return true
		if effect is StackScalingPhysicalDamageEffect and active_poison_stacks > 0:
			return true
	return false


static func _skill_is_death_strike(skill: Skill) -> bool:
	return skill != null and skill.id == DEATH_STRIKE_SKILL_ID


static func _damage_base_with_bonus(base_amount: float, bonus_physical_damage: float) -> float:
	return maxf(PlayerStats.MIN_DAMAGE_BASE, base_amount + bonus_physical_damage)


static func _weapon_scaling_for_skill(skill: Skill) -> float:
	return weapon_scaling_for_skill(skill)


static func weapon_scaling_for_skill(skill: Skill) -> float:
	if skill == null:
		return 0.0
	return float(WEAPON_SCALING_BY_SKILL_ID.get(skill.id, 0.0))


static func _applied_poison_stacks(base_stacks: int, player: PlayerStats) -> int:
	var total := base_stacks + player.bonus_poison_stacks
	if _doubles_applied_stacks(player):
		total *= 2
	return total


static func _poison_stack_cap(player: PlayerStats) -> int:
	if player == null:
		return MAX_POISON_STACKS
	return maxi(1, player.poison_stack_cap)


static func _decay_value(player: PlayerStats) -> float:
	if player == null:
		return BASE_DECAY_REDUCTION_FRACTION
	return clampf(player.decay_value, 0.0, 1.0)


static func _applied_decay_stacks(base_stacks: int, player: PlayerStats) -> int:
	var total := base_stacks + player.bonus_decay_stacks
	if _doubles_applied_stacks(player):
		total *= 2
	return max(0, total)


static func _apply_decay_stacks(base_stacks: int, current_poison_resistance: float, player: PlayerStats) -> Dictionary:
	var applied := _applied_decay_stacks(base_stacks, player)
	var decay_value := _decay_value(player)
	var retained_multiplier := pow(1.0 - decay_value, applied)
	var reduction := 1.0 - retained_multiplier
	return {
		"applied": applied,
		"poison_resistance": current_poison_resistance * retained_multiplier,
		"reduction": reduction,
	}


static func _apply_shred_stacks(base_stacks: int, active_shred_stacks: int, player: PlayerStats, event: CastEvent = null, reason: String = "applied") -> Dictionary:
	var total: int = max(0, base_stacks)
	if _doubles_applied_stacks(player):
		total *= 2
	return _apply_shred_stack_total(total, active_shred_stacks, event, reason)


static func _apply_shred_stack_total(total: int, active_shred_stacks: int, event: CastEvent = null, reason: String = "applied") -> Dictionary:
	total = max(0, total)
	var new_total: int = mini(MAX_SHRED_STACKS, active_shred_stacks + total)
	if event != null:
		_status_transaction(event, "shred", reason, active_shred_stacks, new_total, total)
	return {
		"stacks": new_total,
		"applied": max(0, new_total - active_shred_stacks),
	}


static func _status_transaction(event: CastEvent, status: String, reason: String, before: int, after: int, requested: int) -> void:
	var applied := maxi(0, after - before)
	event.status_transactions.append({"status": status, "reason": reason,
		"before": before, "after": after, "requested": requested,
		"applied": applied, "consumed": 0, "removed": maxi(0, before - after),
		"overflow": maxi(0, requested - applied)})


static func _combine_reduction(existing: float, added: float) -> float:
	return 1.0 - ((1.0 - clampf(existing, 0.0, 1.0)) * (1.0 - clampf(added, 0.0, 1.0)))


static func _armor_after_shred(base_armor: int, active_shred_stacks: int, player: PlayerStats) -> int:
	if player == null:
		return base_armor
	return base_armor - (active_shred_stacks * max(0, player.shred_value))


static func _effective_enemy_dodge_chance(player: PlayerStats, monster: Monster) -> float:
	if _denies_enemy_dodge(player) or monster == null:
		return 0.0
	return monster.dodge_chance


static func _effective_enemy_block(player: PlayerStats, monster: Monster) -> float:
	if _denies_enemy_block(player) or monster == null:
		return 0.0
	return monster.block


static func _effective_enemy_absorb(player: PlayerStats, monster: Monster) -> float:
	if _denies_enemy_absorb(player) or monster == null:
		return 0.0
	return monster.absorb


static func _effective_enemy_suppress(player: PlayerStats, monster: Monster) -> float:
	if _denies_enemy_suppress(player) or monster == null:
		return 0.0
	return monster.suppress


static func effective_enemy_slow(player: PlayerStats, monster: Monster) -> float:
	if _immune_to_slow(player) or monster == null:
		return 0.0
	return monster.slow


static func _effective_enemy_stun_duration_ms(player: PlayerStats, monster: Monster) -> int:
	if _immune_to_stun(player) or monster == null:
		return 0
	return monster.stun_duration_ms


static func _effective_enemy_interrupt_skip_count(player: PlayerStats, monster: Monster) -> int:
	if _immune_to_interrupt(player) or monster == null:
		return 0
	return monster.interrupt_skip_count


static func _denies_enemy_dodge(player: PlayerStats) -> bool:
	var denial := _special_dict(player, "enemy_denial")
	return bool(denial.get("dodge", false))


static func _denies_enemy_block(player: PlayerStats) -> bool:
	var denial := _special_dict(player, "enemy_denial")
	return bool(denial.get("block", false))


static func _denies_enemy_absorb(player: PlayerStats) -> bool:
	var denial := _special_dict(player, "enemy_denial")
	return bool(denial.get("absorb", false))


static func _denies_enemy_suppress(player: PlayerStats) -> bool:
	var denial := _special_dict(player, "enemy_denial")
	return bool(denial.get("suppress", false))


static func _denies_enemy_cleanse(player: PlayerStats) -> bool:
	var denial := _special_dict(player, "enemy_denial")
	return bool(denial.get("cleanse", false))


static func _immune_to_slow(player: PlayerStats) -> bool:
	var immunities := _special_dict(player, "immunities")
	return bool(immunities.get("slow", false))


static func _immune_to_stun(player: PlayerStats) -> bool:
	var immunities := _special_dict(player, "immunities")
	return bool(immunities.get("stun", false))


static func _immune_to_interrupt(player: PlayerStats) -> bool:
	var immunities := _special_dict(player, "immunities")
	return bool(immunities.get("interrupt", false))


static func _doubles_applied_stacks(player: PlayerStats) -> bool:
	if player == null:
		return false
	return bool(player.special_effects.get("double_applied_stacks", false))


static func _decay_applies_shred(player: PlayerStats) -> bool:
	if player == null:
		return false
	return bool(player.special_effects.get("decay_applies_shred", false))


static func _converts_damage_to_physical(player: PlayerStats) -> bool:
	var conversion := _special_dict(player, "damage_conversion")
	return bool(conversion.get("physical", false))


static func _converts_damage_to_magical(player: PlayerStats) -> bool:
	var conversion := _special_dict(player, "damage_conversion")
	return bool(conversion.get("magical", false))


static func _ignores_armor_without_shred(player: PlayerStats) -> bool:
	if player == null:
		return false
	return bool(player.special_effects.get("ignore_armor_no_shred", false))


static func _ignores_resistance_with_physical_penalty(player: PlayerStats) -> bool:
	if player == null:
		return false
	return bool(player.special_effects.get("ignore_resistance_physical_penalty", false))


static func _physical_damage_penalty(player: PlayerStats) -> float:
	if not _ignores_resistance_with_physical_penalty(player):
		return 1.0
	if player == null:
		return 1.0
	return float(player.special_effects.get("physical_damage_penalty", 0.5))


static func _special_dict(player: PlayerStats, key: String) -> Dictionary:
	if player == null:
		return {}
	var value = player.special_effects.get(key, {})
	if value is Dictionary:
		return value
	return {}


static func _roll_weapon_damage_for_skill(skill: Skill, player: PlayerStats, active_poison_stacks: int, rng: RandomNumberGenerator) -> Dictionary:
	if not _skill_uses_weapon_roll(skill, active_poison_stacks):
		return {}
	var minimum := mini(player.weapon_damage_min, player.weapon_damage_max)
	var maximum := maxi(player.weapon_damage_min, player.weapon_damage_max)
	if minimum <= 0 or maximum <= 0:
		minimum = 1
		maximum = 1
	return {
		"roll": rng.randi_range(minimum, maximum),
		"min": minimum,
		"max": maximum,
		"tier": player.weapon_damage_tier,
		"weapon_id": player.weapon_damage_weapon_id,
		"uses_fallback": player.weapon_damage_uses_fallback,
		"fallback_reason": player.weapon_damage_fallback_reason,
	}


static func _skill_uses_weapon_roll(skill: Skill, active_poison_stacks: int) -> bool:
	if skill == null:
		return false
	for effect in skill.effects:
		if effect is PhysicalDamageEffect:
			return true
		if effect is StackScalingPhysicalDamageEffect and active_poison_stacks > 0:
			return true
	return false


static func _record_damage_contribution(event: CastEvent, skill: Skill, kind: String, damage: float, is_crit: bool, armor_reduction: int, poison_resistance_reduction: float, poison_stacks: int, gold_stolen: int = 0) -> void:
	if skill == null:
		return
	if damage <= 0.0 and armor_reduction <= 0 and poison_resistance_reduction <= 0.0 and poison_stacks <= 0 and gold_stolen <= 0:
		return
	event.damage_contributions.append({
		"skill_id": skill.id,
		"name": skill.display_name,
		"icon": skill.icon,
		"kind": kind,
		"damage": damage,
		"is_crit": is_crit,
		"armor_reduction_applied": armor_reduction,
		"poison_resistance_reduction_applied": poison_resistance_reduction,
		"poison_stacks_applied": poison_stacks,
		"gold_stolen": gold_stolen,
	})
