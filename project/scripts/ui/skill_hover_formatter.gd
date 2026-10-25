extends RefCounted
## Minimal player-facing skill hover. Detailed mechanics remain in SkillTooltipFormatter.
const Keywords=preload("res://scripts/ui/presentation_keywords.gd")
const Formatter = preload("res://scripts/ui/skill_tooltip_formatter.gd")
const Category = preload("res://scripts/ui/skill_category_preview_style.gd")

static func model(skill: Skill, state = null) -> Dictionary:
	var stats := Formatter.resolved_stats(state)
	var damage := planning_damage(skill, stats)
	var speed := Formatter.speed_label_for(skill).trim_prefix("Speed: ")
	if skill.category == Skill.Category.SELF_BUFF: speed = "Fast"
	var cooldown := ""
	if skill.category != Skill.Category.ATTACK:
		cooldown = "Cooldown: %ss" % seconds_text(Formatter.cooldown_ms(skill, stats)) if skill.cooldown_ms > 0 else "Cooldown: None"
	return {"id":skill.id,"name":skill.display_name,"icon":skill.icon,
		"category":Category.NAMES[skill.category],"color":Category.COLORS[skill.category],
		"cast":speed,"cooldown":cooldown,"duration":duration_text(skill,stats),
		"damage":damage,"effect":Keywords.normalize(basic_effect(skill,stats))}

static func plain_text(data: Dictionary) -> String:
	var lines: PackedStringArray = [data.name,"%s [%s]" % [data.category,data.cast]]
	if data.cooldown != "": lines.append(data.cooldown)
	if data.duration != "": lines.append(data.duration)
	if data.damage != "": lines.append(data.damage)
	if data.effect != "": lines.append(data.effect)
	return "\n".join(lines)

static func seconds_text(milliseconds: int) -> String:
	return String.num(milliseconds / 1000.0,3).trim_suffix("0").trim_suffix("0").trim_suffix("0").trim_suffix(".")

static func duration_text(skill: Skill, stats: PlayerStats) -> String:
	if skill.category == Skill.Category.ATTACK or skill.id in ["skill.pick_pocket","skill.virulent_poison","skill.poison_vile"]: return ""
	if skill.dance_duration_ms > 0: return "Duration: %ss" % Formatter.buff_seconds(skill.dance_duration_ms, stats)
	if skill.id == "skill.touch_of_darkness": return "Duration: %ss" % Formatter.buff_seconds(12000, stats)
	if skill.id == "skill.beguiling_presence": return "Duration: %ss" % Formatter.buff_seconds(10000, stats)
	for effect in skill.effects:
		if effect is Formatter.SelfBuff:
			if effect.kind == "virulent_poison": return "Duration: Until stacks are spent"
			if effect.kind == "master_of_poisons": return "Duration: %ss" % Formatter.buff_seconds(5000, stats)
		elif effect is Formatter.DefenseDebuff:
			return "Duration: %ss" % Formatter.buff_seconds(3000+1000*stats.death_pact_rank, stats)
		elif effect is PoisonDamageEffect:
			return "Duration: Until stacks are depleted"
	return "Duration: Instant"

static func planning_damage(skill: Skill, stats: PlayerStats) -> String:
	var fallback := -1.0
	for effect in skill.effects:
		if effect is PhysicalDamageEffect:
			fallback = effect.amount
			break
	if fallback < 0.0: return ""
	var scaling := CombatResolver.weapon_scaling_for_skill(skill)
	var low := float(stats.weapon_damage_min) if scaling > 0 else fallback
	var high := float(stats.weapon_damage_max) if scaling > 0 else fallback
	if scaling > 0 and (low <= 0 or high <= 0):
		low = 1.0
		high = 1.0
	low = maxf(PlayerStats.MIN_DAMAGE_BASE,low+stats.bonus_physical_damage) * (scaling if scaling > 0 else 1.0)
	high = maxf(PlayerStats.MIN_DAMAGE_BASE,high+stats.bonus_physical_damage) * (scaling if scaling > 0 else 1.0)
	var buckets := stats.physical_damage_buckets()
	buckets.talent *= float(stats.skill_damage_multipliers.get(skill.id,1.0))
	# No live Poison/theft, enemy defenses, crit or temporary combat state in planning.
	var neutral := Monster.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	low = CombatResolver._apply_conversion_to_physical_hit(low,0,0.0,0.0,1.0,rng,buckets,stats,neutral,{"block":0.0,"absorb":0.0}).amount
	high = CombatResolver._apply_conversion_to_physical_hit(high,0,0.0,0.0,1.0,rng,buckets,stats,neutral,{"block":0.0,"absorb":0.0}).amount
	return "%s damage" % Formatter._damage_range_text(low,high)

static func basic_effect(skill: Skill, stats: PlayerStats) -> String:
	match skill.id:
		"skill.hold": return "Wait without attacking."
		"skill.killers_mark": return "+%d base physical damage per Poison stack%s" % [roundi(CombatResolver.DEATH_STRIKE_DAMAGE_PER_POISON_STACK), "\n+1 base physical damage per Decay stack" if Formatter.legendary_enabled(stats, "umbral") else ""]
		"skill.mug": return "+1 base physical damage per gold stolen in combat"
		"skill.big_score": return "Critical hits from this skill are increased by %.0fx" % skill.critical_damage_factor
		"skill.pick_pocket": return theft_text(10,stats,"Steals")
		"skill.steal": return theft_text(3,stats,"Critical hits steal")
		"skill.touch_of_darkness": return "Consume all stacks of Poison. Each stack consumed grants x%d%% Attack Speed and +%d Base Physical Damage" % [10*Formatter.buff_strength(stats), 2*Formatter.buff_strength(stats)]
		"skill.beguiling_presence": return "Consume all stacks of Decay. Each stack consumed grants +%d Base Elemental Damage%s" % [Formatter.buff_strength(stats), " and +%d%% Attack Speed" % (4*Formatter.buff_strength(stats)) if stats.legendary_signet else ""]
		"skill.parry_strike": return "Requires and consumes 1 Readiness stack"
		"skill.dance_of_death": return "The first hit of all attacks have 100% Retrigger Chance"
	var parts: PackedStringArray = []
	for effect in skill.effects:
		if effect is PoisonDamageEffect:
			if skill.id == "skill.venom_jab":
				parts.append("On hit: Apply %d stacks of Poison" % Formatter._effective_stack_total(effect.stacks_applied,stats.bonus_poison_stacks,stats))
				continue
			var poison_text: String=("On hit: apply %d Poison stacks." if skill.category == Skill.Category.ATTACK else "Apply %d Poison stacks.") % Formatter._effective_stack_total(effect.stacks_applied,stats.bonus_poison_stacks,stats)
			if skill.id=="skill.poison_vile": poison_text=poison_text.trim_suffix(".")
			parts.append(poison_text)
		elif effect is Formatter.ForcedPoisonTick:
			parts.append("On hit: Consume all Poison stacks, dealing their Poison damage." if Formatter.legendary_enabled(stats, "decrepit") and skill.id == "skill.poison_strike" else "On hit: trigger 1 Poison tick.")
		elif effect is Formatter.Exsanguinate:
			parts.append("Consume all Shred stacks. Remove %d health per stack.\nRetriggers repeat the same health removal." % (2*stats.shred_value))
		elif effect is ArmorReductionEffect: parts.append("On hit: apply %d Shred stacks." % Formatter._effective_stack_total(effect.amount,stats.bonus_shred_stacks,stats))
		elif effect is PoisonResistanceReductionEffect:
			parts.append(("On hit: Apply %d stacks of Decay" if skill.id=="skill.toxic_flurry" else "On hit: apply %d Decay stacks.") % Formatter._effective_stack_total(1,stats.bonus_decay_stacks,stats))
		elif effect is Formatter.DefenseDebuff:
			var base: int = stats.assassin_tree_points if effect.use_assassin_points else effect.base_stacks
			parts.append("Apply %d stacks of Potency" % mini(50,Formatter._effective_stack_total(base,stats.bonus_potency_stacks,stats)))
		elif effect is Formatter.SelfBuff:
			if effect.kind == "virulent_poison": parts.append("Next 5 ticks of Poison deal %dx damage" % Formatter.buff_multiplier(2.0, stats))
			elif effect.kind == "master_of_poisons": parts.append("Elemental damage ignores Resistance")
		elif effect is Formatter.Consume and effect.poison_per_consumed > 0:
			var maximum:=Formatter._effective_stack_total(effect.amount*effect.poison_per_consumed,stats.bonus_poison_stacks,stats)
			parts.append("Consume up to %d stacks of Decay to apply up to %d stacks of Poison" % [effect.amount,maximum])
	return "\n".join(parts)

static func theft_text(raw: int, stats: PlayerStats, prefix: String) -> String:
	return "%s %d gold" % [prefix,Formatter._stolen_gold_amount(raw,stats)]
