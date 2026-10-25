class_name BuildResolver
extends RefCounted
## Ports the Build Resolution order from
## docs/Phase 1 Context Docs/Current_Mechanics_Reference.md: base stats ->
## tree innate modifiers -> selected talent modifiers -> equipped gear
## modifiers -> filter rotation to unlocked skills.
##
## GOLD_REWARDS feeds both post-fight rewards and any combat effects that
## generate stash gold. The resolved multiplier lives on PlayerStats so the
## reward and combat paths share the same rounding policy.

## Rotation/macro slot cap (user-requested), enforced once here since both
## BuildState.set_rotation() (real Adventure) and TrainingRoomState.
## set_rotation() already route every rotation edit through
## resolve_rotation() -- a single chokepoint covers both screens.
const MAX_ROTATION_SIZE := 10
const GearStatSheet := preload("res://scripts/resources/stat_sheet.gd")
const WeaponDamageCatalog := preload("res://scripts/systems/weapon_damage_catalog.gd")
const StatRule := preload("res://scripts/resources/stat_derivation_rule.gd")
const StatState := preload("res://scripts/systems/combat_stat_state.gd")
const LiveLegendaryStats := preload("res://scripts/systems/legendary_live_stats.gd")
const LEGENDARY_EFFECT_IDS := ["wyvern", "umbral", "mithril", "bandit", "bejeweled", "decrepit", "nightkiss", "crown", "samurai", "cloak", "death_door", "signet", "locket", "coil", "wingjammer", "coin"]


static func resolve_stats(class_def: ClassDef, selected_trees: Array[SubclassTree], selected_talents: Array[Talent], equipped_gear: Array[GearItem] = [], current_gold: int = 0, carried_gear: Array[GearItem] = [], legendary_flags: Dictionary = {}) -> PlayerStats:
	var stats := PlayerStats.new()
	var flags := legendary_flags.duplicate(true)
	for gear in equipped_gear:
		if gear != null and gear.legendary_effect_id in LEGENDARY_EFFECT_IDS:
			flags[gear.legendary_effect_id] = true
	flags["all_stacks"] = 0
	stats.special_effects["legendary"] = flags
	for flag in ["signet", "crown", "coin", "bandit"]:
		stats.set("legendary_" + flag, bool(flags.get(flag, false)))
	if class_def != null:
		stats.attack_speed = class_def.base_stats.attack_speed
		stats.crit_chance = class_def.base_stats.crit_chance
		stats.crit_multiplier = class_def.base_stats.crit_multiplier
		stats.base_poison_damage = class_def.base_stats.poison_damage_per_tick
		stats.poison_damage_per_tick = class_def.base_stats.poison_damage_per_tick
		stats.talent_physical_damage_multiplier = class_def.base_stats.physical_damage_multiplier
		stats.physical_damage_uses_buckets = true
		stats.sync_physical_damage_multiplier()
		stats.bonus_poison_stacks = class_def.base_stats.bonus_poison_stacks
		stats.bonus_armor_reduction = class_def.base_stats.bonus_armor_reduction
		stats.shred_value = class_def.base_stats.shred_value
		stats.bonus_shred_stacks = class_def.base_stats.bonus_shred_stacks
		stats.bonus_decay_stacks = class_def.base_stats.bonus_decay_stacks
		stats.decay_value = class_def.base_stats.decay_value
		stats.poison_stack_cap = class_def.base_stats.poison_stack_cap
		stats.poison_tick_interval_multiplier = class_def.base_stats.poison_tick_interval_multiplier
		stats.gold_reward_multiplier = class_def.base_stats.gold_reward_multiplier
		stats.crit_chance_per_stolen_gold = class_def.base_stats.crit_chance_per_stolen_gold
		stats.crit_multiplier_per_current_gold = class_def.base_stats.crit_multiplier_per_current_gold
	stats.triggered_skill_effects = []
	stats.current_gold = current_gold
	var gold_reward_talent_multiplier := 1.0
	var intrinsic_gold_bonus := 0.0
	if class_def != null:
		stats.stat_sources.append({"source_id": class_def.id, "source_kind": "class",
			"values": stat_value_snapshot(stats)})

	for tree in selected_trees:
		for modifier in tree.innate_modifiers:
			_record_modifier_source(stats, tree.id, "intrinsic", modifier)
			if _is_gold_reward_multiplier_modifier(modifier):
				# Base and primary-point intrinsic bonuses share one Increased Gold bucket.
				if modifier.operation == StatModifier.OperationType.ADD:
					intrinsic_gold_bonus += modifier.value
				else:
					gold_reward_talent_multiplier *= _gold_reward_multiplier_for_modifier(modifier)
				continue
			_apply_modifier(stats, modifier)
	for talent in selected_talents:
		var shadow_error: String = preload("res://scripts/systems/shadow_passives.gd").apply(stats, talent)
		if shadow_error != "":
			stats.derivation_error = shadow_error
			return stats
		var assassin_error: String = preload("res://scripts/systems/assassin_passives.gd").apply(stats, talent)
		if assassin_error != "":
			stats.derivation_error = assassin_error
			return stats
		if talent.bribery_base_stacks not in [0, 2, 4, 6] or (talent.bribery_base_stacks > 0 and stats.bribery_base_stacks > 0):
			stats.derivation_error = "Invalid or duplicate Bribery source: " + talent.id
			return stats
		if talent.finders_keepers_rank not in [0, 1, 2] or (talent.finders_keepers_rank > 0 and stats.finders_keepers_rank > 0):
			stats.derivation_error = "Invalid or duplicate Finders Keepers source: " + talent.id
			return stats
		if talent.bribery_base_stacks > 0:
			stats.bribery_base_stacks = talent.bribery_base_stacks
			stats.stat_sources.append({"source_id": talent.id, "source_kind": "combat_passive", "bribery_base_stacks": talent.bribery_base_stacks})
		if talent.finders_keepers_rank > 0:
			stats.finders_keepers_rank = talent.finders_keepers_rank
			stats.stat_sources.append({"source_id": talent.id, "source_kind": "combat_passive", "finders_keepers_rank": talent.finders_keepers_rank})
		if talent.riposte_rank < 0 or talent.riposte_rank > 2 or (talent.riposte_rank > 0 and stats.riposte_rank > 0):
			stats.derivation_error = "Invalid or duplicate Riposte source: " + talent.id
			return stats
		if talent.riposte_rank > 0:
			stats.riposte_rank = talent.riposte_rank
			stats.stat_sources.append({"source_id": talent.id, "source_kind": "combat_passive", "riposte_rank": talent.riposte_rank})
		if talent.precision_enabled:
			stats.precision_duration_ms = -1
			stats.stat_sources.append({"source_id": talent.id, "source_kind": "combat_passive", "precision_duration_ms": -1})
		if talent.side_step_enabled:
			stats.side_step_enabled = true
			stats.stat_sources.append({"source_id": talent.id, "source_kind": "combat_passive", "side_step_enabled": true})
		if talent.shred_cleanse_immune:
			stats.shred_cleanse_immune = true
			stats.stat_sources.append({"source_id": talent.id, "source_kind": "combat_passive", "shred_cleanse_immune": true})
		if talent.silvered_edge_rank < 0 or talent.silvered_edge_rank > 3 or (talent.silvered_edge_rank > 0 and stats.silvered_edge_rank > 0):
			stats.derivation_error = "Invalid or duplicate Silvered Edge source: " + talent.id
			return stats
		if talent.silvered_edge_rank > 0:
			stats.silvered_edge_rank = talent.silvered_edge_rank
			stats.stat_sources.append({"source_id": talent.id, "source_kind": "combat_passive", "silvered_edge_rank": talent.silvered_edge_rank})
		if talent.gilded_blade_enabled:
			stats.gilded_blade_enabled = true
			stats.stat_sources.append({"source_id": talent.id, "source_kind": "combat_passive", "gilded_blade_enabled": true})
		if talent.footwork_rank < 0 or talent.footwork_rank > 5 or (talent.footwork_rank > 0 and stats.footwork_rank > 0):
			stats.derivation_error = "Invalid or duplicate Footwork source: " + talent.id
			return stats
		if talent.footwork_rank > 0:
			stats.footwork_rank = talent.footwork_rank
			stats.stat_sources.append({"source_id": talent.id, "source_kind": "combat_passive", "footwork_rank": talent.footwork_rank})
		for modifier in talent.stat_modifiers:
			_record_modifier_source(stats, talent.id, "talent", modifier)
			if _is_gold_reward_multiplier_modifier(modifier):
				gold_reward_talent_multiplier *= _gold_reward_multiplier_for_modifier(modifier)
				continue
			_apply_modifier(stats, modifier)
		for trigger in talent.triggered_skill_effects:
			if trigger != null:
				stats.triggered_skill_effects.append(trigger)
	if stats.derivation_error != "":
		return stats
	var gear_stat_sheet = resolve_gear_stat_sheet(equipped_gear, carried_gear)
	gear_stat_sheet.apply_to_player_stats(stats)
	stats.special_effects.legendary["all_stacks"] += gear_stat_sheet.increased_all_stacks()
	if stats.derivation_error != "":
		return stats
	stats.gold_reward_multiplier = maxf(0.0, stats.gold_reward_multiplier * gold_reward_talent_multiplier * (1.0 + intrinsic_gold_bonus))
	_apply_weapon_damage_range(stats, equipped_gear)
	for gear in equipped_gear:
		for modifier in gear.affixes:
			_record_modifier_source(stats, gear.id, "gear", modifier)
		for trigger in gear.triggered_skill_effects:
			if trigger != null:
				stats.triggered_skill_effects.append(trigger)
		if gear.legendary_effect_id != "bandit":
			stats.bonus_physical_damage += gear.physical_damage_per_gold * float(current_gold)
		stats.min_cast_time_proc_chance += gear.min_cast_time_proc_chance
		if gear.physical_damage_per_gold != 0.0 or gear.min_cast_time_proc_chance != 0.0:
			stats.stat_sources.append({"source_id": gear.id, "source_kind": "gear_compatibility",
				"physical_damage_per_gold": gear.physical_damage_per_gold,
				"current_gold": current_gold, "min_cast_time_proc_chance": gear.min_cast_time_proc_chance})
	stats.stat_sources.append({"source_id": "build.gear_aggregate", "source_kind": "gear_aggregate",
		"raw_values": gear_stat_sheet.raw_values.duplicate(true), "values": gear_stat_sheet.values.duplicate(true),
		"all_stats_multiplier": gear_stat_sheet.all_stats_multiplier(),
		"cooldown_factor": gear_stat_sheet.cooldown_factor,
		"cooldown_contributions": gear_stat_sheet.cooldown_contributions.duplicate(true),
		"contribution_sources": gear_stat_sheet.contribution_sources.duplicate(true)})
	stats.derivation_error = preload("res://scripts/systems/combat_timer_math.gd").validation_error(stats)
	if stats.derivation_error != "":
		return stats
	for talent in selected_talents:
		for rule in talent.stat_derivations:
			if not rule is StatRule:
				stats.derivation_error = "Unsupported stat derivation resource: " + talent.id
				return stats
			stats.derivation_error = rule.validation_error()
			if stats.derivation_error != "":
				return stats
			stats.stat_derivations.append(rule.compiled(talent.id))
	# Capture the actual unlocked and augmented skill once; resolving skills does
	# not resolve stats, so the proc descriptor cannot recurse through this build.
	if bool(flags.get("cloak", false)):
		var quick_cut := _find_skill_by_id(resolve_unlocked_skills(class_def, selected_trees, selected_talents, equipped_gear), "skill.quick_cut")
		if quick_cut != null:
			stats.special_effects.legendary["quick_cut"] = quick_cut
	if not stats.stat_derivations.is_empty() or stats.legendary_coin:
		var state := StatState.new(stats)
		if state.initialization_error != "":
			stats.derivation_error = state.initialization_error
			return stats
		return _resolve_legendary_build_stats(state.snapshot())

	return _resolve_legendary_build_stats(stats)


static func _resolve_legendary_build_stats(stats: PlayerStats) -> PlayerStats:
	if not stats.legendary_signet and not stats.legendary_bandit:
		return stats
	var live := LiveLegendaryStats.resolve(stats, stats.current_gold, 0)
	# Resource.duplicate does not retain runtime-only derivation_base. Keep raw
	# inputs explicitly so temporary-source rebuilding never compounds conversion.
	live.derivation_base = (stats.derivation_base if stats.derivation_base != null else stats).duplicate(true)
	live.derivation_base.derivation_base = null
	return live


static func _record_modifier_source(stats: PlayerStats, source_id: String, source_kind: String, modifier: StatModifier) -> void:
	if modifier == null:
		return
	var stat_id := StatCatalog.canonical_id_for_modifier(modifier)
	stats.stat_sources.append({"source_id": source_id, "source_kind": source_kind,
		"stat_id": stat_id, "legacy_stat": modifier.stat, "operation": modifier.operation,
		"value": modifier.value})


static func stat_value_snapshot(stats: PlayerStats) -> Dictionary:
	return StatState.value_snapshot(stats)


static func resolve_gear_stat_sheet(equipped_gear: Array[GearItem] = [], carried_gear: Array[GearItem] = []):
	var sheet = GearStatSheet.new()
	sheet.add_gear_collection(equipped_gear)
	sheet.add_carried_economy(carried_gear)
	sheet.finalize()
	return sheet


static func resolve_weapon_damage_range(equipped_gear: Array[GearItem] = []) -> Dictionary:
	return WeaponDamageCatalog.damage_range_for_equipped_gear(equipped_gear)


static func resolve_unlocked_skills(class_def: ClassDef, selected_trees: Array[SubclassTree], selected_talents: Array[Talent], equipped_gear: Array[GearItem] = []) -> Array[Skill]:
	var skills: Array[Skill] = []
	if class_def != null:
		for skill in class_def.base_skills:
			_append_skill_clone(skills, skill)
	for tree in selected_trees:
		for skill in tree.unlocked_skills:
			_append_skill_clone(skills, skill)
	for talent in selected_talents:
		for skill in talent.unlocked_skills:
			_append_skill_clone(skills, skill)
	for gear in equipped_gear:
		for skill in gear.unlocked_skills:
			_append_skill_clone(skills, skill)
	# Same-ID unlocks share one macro entry. Equipped Decrepit selects its modern
	# forced-Poison definition even when a legacy talent unlocked the ID first.
	# Select the definition before augments so every normal build augment survives.
	for gear in equipped_gear:
		if gear.legendary_effect_id != "decrepit":
			continue
		for index in skills.size():
			if skills[index].id == "skill.poison_strike":
				skills[index] = preload("res://data/skills/poison_strike_legendary.tres").duplicate(true) as Skill
				break
		break
	for tree in selected_trees:
		for augment in tree.skill_augments:
			_apply_skill_augment(skills, augment)
	return skills


static func resolve_rotation(rotation: Array[Skill], unlocked_skills: Array[Skill]) -> Array[Skill]:
	return normalize_rotation(rotation, unlocked_skills)["rotation"]


static func normalize_rotation(rotation: Array[Skill], unlocked_skills: Array[Skill]) -> Dictionary:
	var filtered: Array[Skill] = []
	var removed: Array[String] = []
	var overflow: Array[String] = []
	for skill in rotation:
		if skill == null:
			removed.append("<null>")
			continue
		var resolved_skill := _find_skill_by_id(unlocked_skills, skill.id)
		if resolved_skill == null:
			removed.append(skill.id)
		elif filtered.size() >= MAX_ROTATION_SIZE:
			overflow.append(skill.id)
		else:
			filtered.append(resolved_skill)
	return {"rotation": filtered, "removed": removed, "overflow": overflow}


static func resolve_ranked_build(class_def: ClassDef, build: RankedBuild, gear: Array[GearItem] = [], current_gold: int = 0, carried_gear: Array[GearItem] = []) -> Dictionary:
	var content := build.resolved_content()
	if content["error"] != "":
		return content
	var stats := resolve_stats(class_def, content["trees"], content["talents"], gear, current_gold, carried_gear)
	if stats.derivation_error != "":
		return {"error": stats.derivation_error}
	for tree in build.trees():
		if tree.id == "tree.assassin":
			stats.assassin_tree_points = build.tree_points(tree)
			if stats.derivation_base != null:
				stats.derivation_base.assassin_tree_points = stats.assassin_tree_points
			stats.stat_sources.append({"source_id": tree.id, "source_kind": "tree_investment", "assassin_tree_points": stats.assassin_tree_points})
	var skills := resolve_unlocked_skills(class_def, content["trees"], content["talents"], gear)
	for skill in skills:
		if skill.dance_duration_ms > 0:
			stats.dance_duration_ms = skill.dance_duration_ms
			stats.stat_sources.append({"source_id": skill.id, "source_kind": "skill_unlock", "dance_duration_ms": skill.dance_duration_ms})
		if skill.enables_readiness:
			stats.readiness_enabled = true
			stats.stat_sources.append({"source_id": skill.id, "source_kind": "skill_unlock", "readiness_enabled": true})
	return {
		"error": "",
		"stats": stats,
		"skills": skills,
	}


static func _append_skill_clone(skills: Array[Skill], skill: Skill) -> void:
	if skill == null or _find_skill_by_id(skills, skill.id) != null:
		return
	skills.append(skill.duplicate(true))


static func _find_skill_by_id(skills: Array[Skill], skill_id: String) -> Skill:
	for skill in skills:
		if skill != null and skill.id == skill_id:
			return skill
	return null


static func _apply_skill_augment(skills: Array[Skill], augment: SkillAugment) -> void:
	if augment == null:
		return
	for target_id in augment.target_skill_ids:
		var skill := _find_skill_by_id(skills, target_id)
		if skill == null:
			continue
		var applied_poison_from_extra := false
		for effect in augment.extra_effects:
			if effect != null:
				skill.effects.append(effect.duplicate(true))
				if effect is PoisonDamageEffect:
					applied_poison_from_extra = true
		if augment.poison_stacks_applied > 0:
			skill.poison_stacks_applied += augment.poison_stacks_applied
		if augment.poison_stacks_applied > 0 and not applied_poison_from_extra:
			var poison_effect := PoisonDamageEffect.new()
			poison_effect.stacks_applied = augment.poison_stacks_applied
			skill.effects.append(poison_effect)


static func _apply_modifier(stats: PlayerStats, modifier: StatModifier) -> void:
	if modifier == null:
		return
	var problem := StatCatalog.modifier_validation_error(modifier)
	if problem != "":
		stats.derivation_error = problem
		return
	if _is_legacy_poison_damage_multiplier(modifier):
		stats.talent_elemental_damage_multiplier = stats.talent_elemental_damage_multiplier * modifier.value
		stats.sync_elemental_damage_multiplier()
		stats.sync_poison_damage_per_tick()
		return
	if _apply_canonical_modifier(stats, modifier):
		return
	match modifier.stat:
		StatModifier.StatType.ATTACK_SPEED:
			stats.attack_speed = _apply_op(stats.attack_speed, modifier)
		StatModifier.StatType.CRIT_CHANCE:
			stats.crit_chance = _apply_op(stats.crit_chance, modifier)
		StatModifier.StatType.CRIT_MULTIPLIER:
			stats.crit_multiplier = maxf(1.0, _apply_op(stats.crit_multiplier, modifier))
		StatModifier.StatType.POISON_DAMAGE:
			if modifier.operation == StatModifier.OperationType.MULTIPLY:
				stats.talent_elemental_damage_multiplier = stats.talent_elemental_damage_multiplier * modifier.value
				stats.sync_elemental_damage_multiplier()
			else:
				stats.bonus_base_elemental_damage = stats.bonus_base_elemental_damage + modifier.value
			stats.sync_poison_damage_per_tick()
		StatModifier.StatType.PHYSICAL_DAMAGE:
			stats.talent_physical_damage_multiplier = _apply_op(stats.talent_physical_damage_multiplier, modifier)
			stats.physical_damage_uses_buckets = true
			stats.sync_physical_damage_multiplier()
		StatModifier.StatType.POISON_STACKS_APPLIED:
			_apply_all_stack_bonus(stats, int(round(_modifier_additive_value(modifier))))
		StatModifier.StatType.ARMOR_REDUCTION:
			_apply_all_stack_bonus(stats, int(round(_modifier_additive_value(modifier))))
		StatModifier.StatType.POISON_TICK_INTERVAL:
			stats.poison_tick_interval_multiplier = max(0.05, _apply_op(stats.poison_tick_interval_multiplier, modifier))
		StatModifier.StatType.GOLD_REWARDS:
			stats.gold_reward_multiplier = maxf(0.0, stats.gold_reward_multiplier * (1.0 + modifier.value))
		StatModifier.StatType.CRIT_CHANCE_PER_STOLEN_GOLD:
			stats.crit_chance_per_stolen_gold = _apply_op(stats.crit_chance_per_stolen_gold, modifier)
		StatModifier.StatType.CRIT_MULTIPLIER_PER_CURRENT_GOLD:
			stats.crit_multiplier_per_current_gold = _apply_op(stats.crit_multiplier_per_current_gold, modifier)
		_:
			pass


static func _apply_canonical_modifier(stats: PlayerStats, modifier: StatModifier) -> bool:
	if modifier == null or modifier.stat_id.strip_edges() == "":
		return false
	var stat_id := StatCatalog.canonical_id_for_modifier(modifier)
	if stat_id == "" or not StatCatalog.has_stat(stat_id):
		return false
	match stat_id:
		StatCatalog.COOLDOWN_REDUCTION, StatCatalog.INCREASED_BUFF_DURATION, StatCatalog.CRIT_APPLIES_PENETRATION, StatCatalog.CRIT_APPLIES_POTENCY:
			stats.derivation_error = "Build-static timing/proc inputs require the gear stat sheet: " + stat_id
		StatCatalog.BASE_DAMAGE:
			stats.bonus_physical_damage = stats.bonus_physical_damage + _modifier_additive_value(modifier)
		StatCatalog.PERCENT_PHYSICAL_DAMAGE:
			stats.talent_physical_damage_multiplier = stats.talent_physical_damage_multiplier * _modifier_talent_multiplier(modifier)
			stats.physical_damage_uses_buckets = true
			stats.sync_physical_damage_multiplier()
		StatCatalog.INCREASED_ATTACK_SPEED:
			stats.attack_speed = stats.attack_speed + _modifier_additive_value(modifier)
		StatCatalog.CRIT_CHANCE:
			stats.crit_chance = maxf(0.0, stats.crit_chance + _modifier_additive_value(modifier)) if stats.legendary_signet else clampf(stats.crit_chance + _modifier_additive_value(modifier), 0.0, 1.0)
		StatCatalog.CRIT_DAMAGE:
			stats.crit_multiplier = maxf(1.0, stats.crit_multiplier + _modifier_additive_value(modifier))
		StatCatalog.BASE_ELEMENTAL_DAMAGE:
			stats.bonus_base_elemental_damage = stats.bonus_base_elemental_damage + _modifier_additive_value(modifier)
			stats.sync_poison_damage_per_tick()
		StatCatalog.PERCENT_ELEMENTAL_DAMAGE:
			stats.talent_elemental_damage_multiplier = stats.talent_elemental_damage_multiplier * _modifier_talent_multiplier(modifier)
			stats.sync_elemental_damage_multiplier()
			stats.sync_poison_damage_per_tick()
		StatCatalog.INCREASED_ALL_STACKS:
			_apply_all_stack_bonus(stats, int(round(_modifier_additive_value(modifier))))
		StatCatalog.SHRED_VALUE:
			stats.shred_value = max(0, stats.shred_value + int(round(_modifier_additive_value(modifier))))
		StatCatalog.BONUS_SHRED_STACKS:
			stats.bonus_shred_stacks = max(0, stats.bonus_shred_stacks + int(round(_modifier_additive_value(modifier))))
		StatCatalog.DECAY_VALUE:
			stats.decay_value = maxf(0.0, stats.decay_value + _modifier_additive_value(modifier))
		StatCatalog.INCREASED_GOLD:
			stats.gold_reward_multiplier = maxf(0.0, stats.gold_reward_multiplier * _modifier_talent_multiplier(modifier))
		StatCatalog.SHOP_DISCOUNT:
			stats.shop_discount = maxf(0.0, stats.shop_discount + _modifier_additive_value(modifier))
		StatCatalog.INCREASED_MAGIC_FIND:
			stats.magic_find = maxf(0.0, stats.magic_find + _modifier_additive_value(modifier))
		StatCatalog.CHANCE_FOR_RETRIGGER:
			stats.retrigger_chance = clampf(stats.retrigger_chance + _modifier_additive_value(modifier), 0.0, 1.0)
		StatCatalog.CHANCE_TO_SHRED:
			stats.shred_chance = clampf(stats.shred_chance + _modifier_additive_value(modifier), 0.0, 1.0)
		StatCatalog.CHANCE_TO_DECAY:
			stats.decay_chance = clampf(stats.decay_chance + _modifier_additive_value(modifier), 0.0, 1.0)
		StatCatalog.CRIT_APPLIES_ELEMENT:
			stats.elemental_proc_chance = clampf(stats.elemental_proc_chance + _modifier_additive_value(modifier), 0.0, 1.0)
		_:
			if not StatCatalog.is_special(stat_id):
				return false
			_apply_special_modifier(stats, stat_id)
	return true


static func _apply_all_stack_bonus(stats: PlayerStats, bonus: int) -> void:
	if stats.special_effects.has("legendary"):
		stats.special_effects.legendary["all_stacks"] = maxi(0, int(stats.special_effects.legendary.get("all_stacks", 0)) + bonus)
	stats.bonus_footwork_stacks = max(0, stats.bonus_footwork_stacks + bonus)
	stats.bonus_bypass_stacks = max(0, stats.bonus_bypass_stacks + bonus)
	stats.bonus_poison_stacks = max(0, stats.bonus_poison_stacks + bonus)
	stats.bonus_armor_reduction = max(0, stats.bonus_armor_reduction + bonus)
	stats.bonus_shred_stacks = max(0, stats.bonus_shred_stacks + bonus)
	stats.bonus_decay_stacks = max(0, stats.bonus_decay_stacks + bonus)
	stats.bonus_penetration_stacks = max(0, stats.bonus_penetration_stacks + bonus)
	stats.bonus_potency_stacks = max(0, stats.bonus_potency_stacks + bonus)


static func _apply_special_modifier(stats: PlayerStats, stat_id: String) -> void:
	if not stats.special_stat_ids.has(stat_id):
		stats.special_stat_ids.append(stat_id)
	stats.special_effects[stat_id] = true
	match stat_id:
		StatCatalog.DECAY_APPLIES_SHRED:
			stats.special_effects["decay_applies_shred"] = true
		StatCatalog.POISON_STACK_CAP_40:
			var def := StatCatalog.definition(stat_id)
			stats.poison_stack_cap = maxi(stats.poison_stack_cap, int((def.get("fixed_constants", {}) as Dictionary).get("poison_stack_cap", 40)))


static func _modifier_additive_value(modifier: StatModifier) -> float:
	if modifier.operation == StatModifier.OperationType.MULTIPLY:
		return modifier.value - 1.0
	return modifier.value


static func _modifier_talent_multiplier(modifier: StatModifier) -> float:
	if modifier.operation == StatModifier.OperationType.MULTIPLY:
		return modifier.value
	return 1.0 + modifier.value


static func _is_legacy_poison_damage_multiplier(modifier: StatModifier) -> bool:
	return (
		modifier != null
		and modifier.stat_id.strip_edges() == ""
		and modifier.stat == StatModifier.StatType.POISON_DAMAGE
		and modifier.operation == StatModifier.OperationType.MULTIPLY
	)


static func _apply_op(current: float, modifier: StatModifier) -> float:
	if modifier.operation == StatModifier.OperationType.MULTIPLY:
		return current * modifier.value
	return current + modifier.value


static func _apply_weapon_damage_range(stats: PlayerStats, equipped_gear: Array[GearItem]) -> void:
	var range := resolve_weapon_damage_range(equipped_gear)
	stats.weapon_damage_min = int(range["min"])
	stats.weapon_damage_max = int(range["max"])
	stats.weapon_damage_tier = int(range["tier"])
	stats.weapon_damage_weapon_id = String(range["weapon_id"])
	stats.weapon_damage_uses_fallback = bool(range["uses_fallback"])
	stats.weapon_damage_fallback_reason = String(range["fallback_reason"])


static func _is_gold_reward_multiplier_modifier(modifier: StatModifier) -> bool:
	if modifier == null:
		return false
	if modifier.stat_id.strip_edges() != "":
		return StatCatalog.canonical_id_for_modifier(modifier) == StatCatalog.INCREASED_GOLD
	return modifier.stat == StatModifier.StatType.GOLD_REWARDS


static func _gold_reward_multiplier_for_modifier(modifier: StatModifier) -> float:
	if modifier == null:
		return 1.0
	if modifier.operation == StatModifier.OperationType.MULTIPLY:
		return modifier.value
	return 1.0 + modifier.value
