class_name SkillTooltipFormatter
extends RefCounted
const CategoryStyle = preload("res://scripts/ui/skill_category_preview_style.gd")
const SelfBuff = preload("res://scripts/resources/self_buff_effect.gd")
const DefenseDebuff = preload("res://scripts/resources/apply_defense_debuff_effect.gd")
const Consume = preload("res://scripts/resources/consume_status_effect.gd")
const ForcedPoisonTick = preload("res://scripts/resources/forced_poison_tick_effect.gd")
const Exsanguinate = preload("res://scripts/resources/exsanguinate_effect.gd")
const TimerMath = preload("res://scripts/systems/combat_timer_math.gd")

const SPEED_LABEL_BY_SKILL_ID := {
	"skill.stab": "Speed: Normal",
	"skill.heavy_slash": "Speed: Slow",
	"skill.hold": "Speed: Brief",
	"skill.quick_cut": "Speed: Fast",
	"skill.parry_strike": "Speed: Fast",
	"skill.leaping_plunge": "Speed: Slow",
	"skill.rending_thrust": "Speed: Normal",
	"skill.venom_jab": "Speed: Fast",
	"skill.poison_strike": "Speed: Fast",
	"skill.steal": "Speed: Normal",
	"skill.toxic_flurry": "Speed: Normal",
	"skill.killers_mark": "Speed: Normal",
}


static func tooltip_for(skill: Skill, state) -> String:
	if CategoryStyle.enabled(state) and CategoryStyle.selected(skill): return CategoryStyle.tooltip(skill, state)
	var lines: PackedStringArray = []
	lines.append(speed_label_for(skill))
	lines.append(effect_summary(skill, state))
	var conditions := conditions_for(skill, state)
	if not conditions.is_empty():
		lines.append(conditions)
	return "\n".join(lines)


static func compact_tooltip(skill: Skill, state) -> String:
	if CategoryStyle.enabled(state) and CategoryStyle.selected(skill): return CategoryStyle.tooltip(skill, state)
	var stats := resolved_stats(state)
	var lines: PackedStringArray = [skill.display_name, "%s | %.2fs" % [speed_label_for(skill), CombatTiming.execution_time_ms(skill, stats.attack_speed) / 1000.0]]
	lines.append(effect_summary(skill, state))
	var extra := ""
	if skill.id == "skill.quick_cut" and stats.footwork_rank > 0:
		extra = "Hit: +1 Footwork (%ss, max 5)." % buff_seconds(3000, stats)
	elif skill.id == "skill.leaping_plunge" and stats.footwork_rank > 0:
		extra = "Consumes Footwork: %d%% faster per stack." % (stats.footwork_rank * 4 * buff_strength(stats))
	if skill.id == "skill.pick_pocket":
		extra = "Cannot be dodged; not an attack for Retrigger or enemy counters. Credited theft can trigger Bribery."
	elif skill.id in ["skill.touch_of_darkness", "skill.beguiling_presence"]:
		extra = "Bonuses use actual consumed stacks; no fuel grants no buff. Independent activations add bonuses."
	if skill.cooldown_ms > 0:
		extra += (" " if extra != "" else "") + "%.1fs shared cooldown." % (cooldown_ms(skill, stats) / 1000.0)
	if extra != "": lines.append(extra)
	if skill.stolen_gold_base_cap > 0 and state != null and state.has_meta("combat_presentation"):
		var live = state.get_meta("combat_presentation")
		if live.running:
			lines.append("Live stash: %d | Stolen this fight: %d | Mug bonus: +%d/%d" % [live.stash, live.stolen, skill.stolen_gold_damage_bonus(live.stolen), skill.stolen_gold_base_cap])
	return "\n".join(lines)


static func unlock_source(skill: Skill, state) -> String:
	if state == null or state.selected_class == null:
		return "Skill library"
	for base in state.selected_class.base_skills:
		if base.id == skill.id:
			return "Base Rogue skill"
	var sources: PackedStringArray = []
	if state.has_method("equipped_gear"):
		for gear in state.equipped_gear():
			for granted in gear.unlocked_skills:
				if granted.id == skill.id and not sources.has(gear.display_name):
					sources.append(gear.display_name)
	# A selected tree can list a locked skill. Do not hide an actual gear grant
	# behind that potential unlock when no invested talent/threshold grants it.
	var ranked = state.get("ranked_build")
	for tree in state.selected_trees:
		for automatic in tree.automatic_unlocks:
			if automatic.skill != null and automatic.skill.id == skill.id:
				if sources.is_empty() or (ranked != null and ranked.tree_points(tree) >= automatic.required_points):
					return "%s: %d invested points" % [tree.display_name, automatic.required_points]
		for talent in tree.talents:
			for granted in talent.unlocked_skills:
				if granted.id == skill.id:
					var active: bool = ranked.rank_of(talent.id) > 0 if ranked != null else state.selected_talents.has(talent)
					if sources.is_empty() or active:
						return "%s talent: %s" % [tree.display_name, talent.display_name]
		for granted in tree.unlocked_skills:
			if granted.id == skill.id:
				return tree.display_name
	if not sources.is_empty(): return "Gear: " + ", ".join(sources)
	return "Build unlock"


static func conditions_for(skill: Skill, state) -> String:
	var stats := resolved_stats(state)
	if skill.dance_duration_ms > 0:
		return "For %s seconds, connected macro attacks gain a guaranteed Retrigger. Triggered and retriggered attacks do not gain a Dance guarantee; ordinary Retrigger rules still apply. Self Buff timing ignores attack speed." % buff_seconds(skill.dance_duration_ms, stats)
	if skill.id == "skill.toxic_flurry":
		return "Deals 22% weapon damage, then applies 1 base Decay on a connected hit. Stack bonuses apply; dodge prevents Decay, full block does not."
	if skill.id == "skill.killers_mark":
		return "Deals one physical hit: 111%% x (weapon damage + 2 x current Poison count%s + flat physical base bonuses). Reads stacks at impact, before new applications. Does not consume Poison%s." % [" + current Decay count" if legendary_enabled(stats, "umbral") else "", " or Decay" if legendary_enabled(stats, "umbral") else ""]
	if skill.id == "skill.distilled_corruption":
		return "Deals 100% weapon damage, then consumes up to 5 Decay on a connected hit and converts the actual consumed amount into Poison. Poison bonuses apply once, then doubling and cap. No refund at cap; no Decay still permits the hit."
	if skill.id == "skill.touch_of_darkness":
		return "Consumes all Poison and grants +%d%% attack speed and +%d base physical damage per stack actually consumed for %s seconds. Bonuses add to other sources. No fuel grants no buff." % [10 * buff_strength(stats), 2 * buff_strength(stats), buff_seconds(12000, stats)]
	if skill.id == "skill.beguiling_presence":
		var critical_note := "Signet converts the uncapped critical chance bonus to attack speed at 1.5x; cannot crit." if stats.legendary_signet else "Effective critical chance caps at 100%."
		return "Consumes all Decay and grants +%d base elemental damage and +%d percentage points of critical chance per stack actually consumed for %s seconds. %s No fuel grants no buff." % [buff_strength(stats), 2 * buff_strength(stats), buff_seconds(10000, stats), critical_note]

	if skill.stolen_gold_base_cap > 0:
		return "Adds +1 physical base damage per %d gold stolen this fight, rounded down, capped at +%d before damage bonuses and critical hits. Starting stash and reward gold do not count. Does not spend gold. Practice retry resets stolen gold to zero." % [skill.stolen_gold_per_damage, skill.stolen_gold_base_cap]
	if skill.id == "skill.steal":
		return "Critical hits steal 3 raw gold. Increased Gold applies once, rounded down per theft. Credited theft increases both stash and this fight's stolen total."
	if skill.id == "skill.pick_pocket":
		return "Steals 10 raw gold without dealing damage. Increased Gold applies once, rounded down. Cannot be dodged and does not count as an attack for Retrigger or enemy attack counters. Credited theft can trigger Bribery."
	if skill.id == "skill.big_score":
		return "Critical hits multiply your full current crit damage multiplier by %.0fx, including gold-based bonuses. Noncritical hits do not gain this multiplier. Enemy critical-damage negation still applies." % skill.critical_damage_factor
	for effect in skill.effects:
		if effect is Exsanguinate:
			return "Consumes all actual Shred once and removes %d health per stack (1 x resolved Shred Value). Bypasses mitigation; cannot crit or gain damage bonuses. Cannot Retrigger. Shred consumption does not grant Death Pact." % stats.shred_value
		if effect is ForcedPoisonTick:
			if legendary_enabled(stats, "decrepit") and skill.id == "skill.poison_strike":
				var coil_note := " Coil retriggers are free Poison activations: no extra Poison is required or consumed; each recalculates with live buffs using the captured stack count." if legendary_enabled(stats, "coil") else ""
				return "Keeps the normal direct hit, then Consumes all actual Poison once in one burst using normal Poison damage modifiers and Consume hooks. No Poison grants no burst. Does not reset natural Poison timing." + coil_note
			return "Connected hits trigger one fueled Poison tick after damage, including Retriggers. Natural ticks due at the same time resolve first. Uses available stacks without resetting Poison timing; tick depletion is not Consume."
		if effect is DefenseDebuff and effect.use_assassin_points:
			return "Base Potency equals invested Assassin points in either role. Stack bonuses and doubling apply, up to 50. Each stack reduces absorb by 1 for %s seconds; further applications refresh the timer. Cannot be dodged and does not count as an attack." % buff_seconds(3000 + 1000 * stats.death_pact_rank, stats)
		if effect is SelfBuff:
			if effect.kind == "virulent_poison":
				return "Each activation grants 5 independent stacks. Fueled natural, forced and free retriggered Poison activations deal %dx damage per active instance and spend one stack from each. Empty activations spend none. Stacks have no timer; Increased Stacks does not add stacks." % buff_multiplier(2.0, stats)
			if effect.kind == "master_of_poisons":
				return "Elemental damage ignores resistance for %s seconds, including existing Poison. Stored Decay remains; normal resistance resumes when the buff expires." % buff_seconds(5000, stats)
	var notes: PackedStringArray = []
	if skill.id == "skill.parry_strike" and skill.enables_readiness:
		if stats.side_step_enabled and not stats.legendary_signet:
			notes.append("Side Step: 100% crit chance; enemy critical-damage negation still applies.")
	if skill.id == "skill.leaping_plunge":
		if stats.footwork_rank > 0:
			notes.append("Consumes all Footwork at cast start to shorten this cast by %d%% per stack (maximum 5 stacks), respecting its minimum. Later buffs do not change an accepted cast. Planning starts with 0 Footwork; live stacks are fight-local." % (4 * stats.footwork_rank * buff_strength(stats)))
		if stats.riposte_rank > 0:
			notes.append("Riposte: +%d%% damage per Footwork stack actually consumed by this cast." % (20 * stats.riposte_rank * buff_strength(stats)))
	if skill.id == "skill.quick_cut":
		if stats.footwork_rank > 0:
			notes.append("A connected hit grants 1 base Footwork stack after child effects. Increased/doubled grants apply, then cap at 5. All stacks share a refreshed %s-second timer." % buff_seconds(3000, stats))
		if stats.precision_duration_ms != 0:
			notes.append("Precision: connected hits grant one untimed stack before child effects. Stab or Heavy Slash can consume it for one guaranteed Retrigger.")
	if skill.id in ["skill.stab", "skill.heavy_slash"] and stats.precision_duration_ms != 0:
		notes.append("Consumes Precision at cast start for one guaranteed Retrigger if connected, including proc casts. Precision and Dance together give one guarantee.")
	if skill.id == "skill.rending_thrust":
		notes.append("Damage resolves before Shred. Each stack removes %d armor; the stack cap remains 500." % stats.shred_value)
		if stats.shred_cleanse_immune:
			notes.append("Virulent Corruption: Shred cannot be cleansed; other statuses remain cleansable.")
	return "\n".join(notes)


static func details_for(skill: Skill, state) -> String:
	var stats := resolved_stats(state)
	var category: String = ["Attack", "Debuff", "Self Buff"][skill.category]
	var lines: PackedStringArray = [skill.display_name, category + " | " + unlock_source(skill, state), "", effect_summary(skill, state)]
	var conditions := conditions_for(skill, state)
	if not conditions.is_empty():
		lines.append(conditions)
	lines.append("")
	lines.append("Base cast: %.2fs | Minimum: %.2fs" % [skill.base_execution_ms / 1000.0, skill.min_execution_ms / 1000.0])
	lines.append("Planning estimate: %.3fs (current build, no slow or temporary effects)." % (CombatTiming.execution_time_ms(skill, stats.attack_speed) / 1000.0))
	lines.append("Increased attack speed: %.1f%%. %s" % [stats.attack_speed * 100.0, "Self Buff timing ignores attack speed." if skill.category == Skill.Category.SELF_BUFF else "Speed and slow apply before conditional cast reductions."])
	if skill.cooldown_ms > 0:
		lines.append("Cooldown: %.2fs after cast completion, shared by all copies of this skill. A cooling slot spends 0.1s and advances without effects." % (cooldown_ms(skill, stats) / 1000.0))
	else:
		lines.append("Cooldown: none. Duplicate slots are allowed.")
	if skill.id == "skill.exsanguinate":
		lines.append("Health removal uses resolved Shred Value and actual Shred consumed. Cannot Retrigger.")
	else:
		lines.append("Damage and stack values above are current-build estimates. Enemy defenses, critical hits and live temporary stats can change the outcome.")
	return "\n".join(lines)


static func speed_label_for(skill: Skill) -> String:
	if skill == null:
		return "Speed: Normal"
	return SPEED_LABEL_BY_SKILL_ID.get(skill.id, "Speed: Normal")


static func effect_summary(skill: Skill, state = null) -> String:
	if skill == null:
		return "No effect"
	if skill.id == "skill.hold":
		return "Holds for 1.0s"
	if skill.id == "skill.parry_strike":
		return "Requires and consumes Readiness. Readiness is granted by any skill retrigger"
	if skill.id == "skill.killers_mark":
		var umbral := legendary_enabled(resolved_stats(state), "umbral")
		return "One hit: 111%% x (weapon damage + 2 x current Poison count%s + flat physical bonuses), before multipliers. Does not consume Poison%s." % [" + current Decay count" if umbral else "", " or Decay" if umbral else ""]
	if skill.id == "skill.pick_pocket":
		return "Steals %d credited gold (10 raw gold before Increased Gold); no direct damage" % _stolen_gold_amount(10, resolved_stats(state))
	var parts: PackedStringArray = []
	var has_poison_effect := false
	var stats := resolved_stats(state)
	if skill.dance_duration_ms > 0:
		parts.append("Dance: connected macro attacks gain a guaranteed Retrigger for %.1fs" % (buff_duration_ms(skill.dance_duration_ms, stats) / 1000.0))
	if skill.stolen_gold_base_cap > 0:
		parts.append("+1 base physical damage per %d credited gold stolen this fight, rounded down (max +%d; starting stash excluded)" % [skill.stolen_gold_per_damage, skill.stolen_gold_base_cap])
	if skill.id == "skill.big_score":
		parts.append("Critical hits: %.0fx your full crit damage multiplier; noncritical hits unchanged" % skill.critical_damage_factor)
	for effect in skill.effects:
		if effect is PhysicalDamageEffect:
			parts.append(_physical_damage_summary(skill, stats, effect.amount))
		elif effect is PoisonDamageEffect:
			has_poison_effect = true
			parts.append(_poison_stack_summary(effect.stacks_applied, stats))
		elif effect is ForcedPoisonTick:
			parts.append("On hit: Consume all Poison in one burst" if legendary_enabled(stats, "decrepit") and skill.id == "skill.poison_strike" else "On hit: one fueled Poison tick")
		elif effect is Exsanguinate:
			parts.append("Removes %d health per stack of Shred consumed\nCannot Retrigger" % stats.shred_value)
		elif effect is DefenseDebuff:
			var base: int = stats.assassin_tree_points if effect.use_assassin_points else effect.base_stacks
			parts.append("Apply %d Potency (%ss, max 50)" % [mini(50, _effective_stack_total(base, stats.bonus_potency_stacks, stats)), buff_seconds(3000 + 1000 * stats.death_pact_rank, stats)])
		elif effect is SelfBuff:
			if effect.kind == "virulent_poison": parts.append("Each activation: 5 independent stacks; fueled Poison activations deal %dx damage per active instance" % buff_multiplier(2.0, stats))
			elif effect.kind == "master_of_poisons": parts.append("Ignore elemental resistance for %ss" % buff_seconds(5000, stats))
		elif effect is ArmorReductionEffect:
			parts.append(_shred_stack_summary(effect.amount, stats))
		elif effect is PoisonResistanceReductionEffect:
			parts.append(_decay_stack_summary(1, stats))
		elif effect is Consume:
			if effect.grants_touch_of_darkness: parts.append("Consume all Poison: +%d%% IAS and +%d base physical damage per stack for %ss" % [10 * buff_strength(stats), 2 * buff_strength(stats), buff_seconds(12000, stats)])
			elif effect.elemental_per_consumed > 0: parts.append("Consume all Decay: +%d base elemental and +%d percentage points of crit chance per stack for %ss%s" % [buff_strength(stats), 2 * buff_strength(stats), buff_seconds(10000, stats), " (uncapped input converted by Signet; cannot crit)" if stats.legendary_signet else ""])
			elif effect.poison_per_consumed > 0: parts.append("Consume up to %d Decay into Poison" % effect.amount)
		elif effect is StackScalingPhysicalDamageEffect:
			parts.append("+%d dmg/poison stack" % roundi(CombatResolver.DEATH_STRIKE_DAMAGE_PER_POISON_STACK if skill.id == CombatResolver.DEATH_STRIKE_SKILL_ID else effect.damage_per_stack))
		elif effect is StealGoldOnCritEffect:
			parts.append("crits steal %dg" % _stolen_gold_amount(effect.amount, stats))
	if skill.poison_stacks_applied > 0 and not has_poison_effect:
		parts.append(_poison_stack_summary(skill.poison_stacks_applied, stats))
	if parts.is_empty():
		return "No effect"
	return ", ".join(parts)


static func resolved_stats(state = null) -> PlayerStats:
	if state == null or state.selected_class == null:
		var fallback := PlayerStats.new()
		fallback.base_poison_damage = fallback.poison_damage_per_tick
		return fallback
	return state.current_player_stats()


static func _physical_damage_summary(skill: Skill, stats: PlayerStats, fallback_amount: float) -> String:
	var scaling := CombatResolver.weapon_scaling_for_skill(skill)
	if scaling <= 0.0:
		return "%d physical dmg" % roundi(maxf(PlayerStats.MIN_DAMAGE_BASE, fallback_amount + stats.bonus_physical_damage) * stats.physical_damage_multiplier)
	var min_base := maxf(PlayerStats.MIN_DAMAGE_BASE, float(stats.weapon_damage_min) + stats.bonus_physical_damage)
	var max_base := maxf(PlayerStats.MIN_DAMAGE_BASE, float(stats.weapon_damage_max) + stats.bonus_physical_damage)
	if skill != null and skill.id == CombatResolver.DEATH_STRIKE_SKILL_ID:
		return "%s physical dmg +%d/poison stack" % [
			_damage_range_text(min_base * scaling * stats.physical_damage_multiplier, max_base * scaling * stats.physical_damage_multiplier),
			roundi(CombatResolver.DEATH_STRIKE_DAMAGE_PER_POISON_STACK * scaling * stats.physical_damage_multiplier),
		]
	var factor := stats.physical_damage_multiplier * float(stats.skill_damage_multipliers.get(skill.id, 1.0))
	var min_damage := min_base * scaling * factor
	var max_damage := max_base * scaling * factor
	return "%s physical dmg" % _damage_range_text(min_damage, max_damage)


static func _poison_stack_summary(base_stacks: int, stats: PlayerStats) -> String:
	var total := _effective_stack_total(base_stacks, stats.bonus_poison_stacks, stats)
	return "+%d poison stack%s" % [total, "" if total == 1 else "s"]


static func _shred_stack_summary(base_stacks: int, stats: PlayerStats) -> String:
	var total := _effective_stack_total(base_stacks, stats.bonus_shred_stacks, stats)
	return "Applies %d Stack%s of Shred" % [total, "" if total == 1 else "s"]


static func _decay_stack_summary(base_stacks: int, stats: PlayerStats) -> String:
	var total := _effective_stack_total(base_stacks, stats.bonus_decay_stacks, stats)
	return "Applies %d Stack%s of Decay (-%d%% resist each)" % [
		total,
		"" if total == 1 else "s",
		roundi(stats.decay_value * 100.0),
	]


static func _effective_stack_total(base_stacks: int, bonus_stacks: int, stats: PlayerStats) -> int:
	var total := maxi(0, base_stacks + bonus_stacks)
	if stats != null and bool(stats.special_effects.get("double_applied_stacks", false)):
		total *= 2
	return total


static func _stolen_gold_amount(base_amount: int, stats: PlayerStats) -> int:
	if stats == null:
		return maxi(0, base_amount)
	return maxi(0, int(floor(float(base_amount) * stats.gold_reward_multiplier)))


static func _damage_range_text(min_damage: float, max_damage: float) -> String:
	var low := roundi(minf(min_damage, max_damage))
	var high := roundi(maxf(min_damage, max_damage))
	return "%d-%d" % [low, high]


# Presentation reads the resolved flags; timer arithmetic is shared with combat.
static func legendary_enabled(stats: PlayerStats, id: String) -> bool:
	return bool(stats.special_effects.get("legendary", {}).get(id, false))


static func buff_strength(stats: PlayerStats) -> int:
	return 2 if stats.legendary_crown else 1


static func buff_multiplier(multiplier: float, stats: PlayerStats) -> float:
	return 1.0 + buff_strength(stats) * (multiplier - 1.0)


static func buff_duration_ms(base_ms: int, stats: PlayerStats) -> int:
	var timer := TimerMath.scaled_duration(base_ms, stats.increased_buff_duration)
	return int(timer.get("duration_ms", base_ms))


static func buff_seconds(base_ms: int, stats: PlayerStats) -> String:
	return seconds_text(buff_duration_ms(base_ms, stats))


static func seconds_text(milliseconds: int) -> String:
	return String.num(milliseconds / 1000.0, 3).trim_suffix("0").trim_suffix("0").trim_suffix("0").trim_suffix(".")


static func cooldown_ms(skill: Skill, stats: PlayerStats) -> int:
	var timer := TimerMath.cooldown(skill.cooldown_ms, stats.cooldown_factor)
	return int(timer.get("duration_ms", skill.cooldown_ms))
