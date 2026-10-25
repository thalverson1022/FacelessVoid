extends SceneTree

const SkillTooltipFormatterScript := preload("res://scripts/ui/skill_tooltip_formatter.gd")


func _initialize() -> void:
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	var rending_slash: Skill = load("res://data/skills/rending_slash.tres")
	var poison_strike: Skill = load("res://data/skills/poison_strike.tres")
	var beguiling_strike: Skill = load("res://data/skills/beguiling_strike.tres")
	var steal: Skill = load("res://data/skills/steal.tres")
	var state := TrainingRoomState.new()
	state.selected_class = rogue

	_require(
		SkillTooltipFormatterScript.effect_summary(rending_slash, state).contains("Applies 2 Stacks of Shred"),
		"Expected Rending Slash's baseline tooltip to show two Shred stacks."
	)
	_require(
		SkillTooltipFormatterScript.effect_summary(poison_strike, state).contains("+1 poison stack"),
		"Expected Poison Strike's baseline tooltip to show one poison stack."
	)
	_require(
		SkillTooltipFormatterScript.effect_summary(beguiling_strike, state).contains("Applies 1 Stack of Decay (-20% resist each)"),
		"Expected Beguiling Strike's tooltip to name its Decay stack."
	)
	_require(
		SkillTooltipFormatterScript.effect_summary(steal, state).contains("crits steal 3g"),
		"Expected Steal's baseline tooltip to show baseline stolen gold."
	)

	state.equipped_helm = _gear_with_modifier(GearItem.SlotType.HELM, StatCatalog.INCREASED_ALL_STACKS, 2.0)
	state.equipped_charm = _gear_with_modifier(GearItem.SlotType.CHARM, StatCatalog.INCREASED_GOLD, 0.50)
	var stats := BuildResolver.resolve_stats(rogue, [], [], state.equipped_gear(), 0)
	_require(stats.bonus_poison_stacks == 2, "Expected test gear to add two poison stacks.")
	_require(stats.bonus_shred_stacks == 2, "Expected test gear to add two Shred stacks.")
	_require(stats.bonus_decay_stacks == 2, "Expected test gear to add two Decay stacks.")
	_require(is_equal_approx(stats.gold_reward_multiplier, 1.5), "Expected test gear to add 50% Increased Gold.")

	_require(
		SkillTooltipFormatterScript.effect_summary(rending_slash, state).contains("Applies 4 Stacks of Shred"),
		"Expected Rending Slash tooltip to include bonus Shred stacks from gear."
	)
	_require(
		SkillTooltipFormatterScript.effect_summary(poison_strike, state).contains("+3 poison stacks"),
		"Expected Poison Strike tooltip to include bonus poison stacks from gear."
	)
	_require(
		SkillTooltipFormatterScript.effect_summary(beguiling_strike, state).contains("Applies 3 Stacks of Decay (-20% resist each)"),
		"Expected Beguiling Strike tooltip to include bonus Decay stacks from gear."
	)
	_require(
		SkillTooltipFormatterScript.effect_summary(steal, state).contains("crits steal 4g"),
		"Expected Steal tooltip to apply Increased Gold to stolen gold."
	)

	state.rotation = [rending_slash]
	var skill_build_panel_script := load("res://scenes/combat/skill_build_panel.gd")
	var skill_build_panel = skill_build_panel_script.new()
	skill_build_panel.state = state
	root.add_child(skill_build_panel)
	await process_frame
	var slot: Button = skill_build_panel._slots_box.get_child(0)
	_require(
		slot._get_tooltip(Vector2.ZERO).contains("On hit: apply 4 Shred stacks."),
		"Expected macro skill hover to reuse current-build Shred count."
	)

	print("Skill tooltip formatter check: OK")
	quit()


func _gear_with_modifier(slot: GearItem.SlotType, stat_id: String, value: float) -> GearItem:
	var gear := GearItem.new()
	gear.id = "test.tooltip.%s.%s" % [str(slot), stat_id]
	gear.display_name = "Tooltip Test Gear"
	gear.slot = slot
	gear.tier = GearItem.Tier.BASIC
	var modifier := StatModifier.new()
	modifier.stat_id = stat_id
	modifier.stat = StatModifier.StatType.ATTACK_SPEED
	modifier.operation = StatModifier.OperationType.ADD
	modifier.value = value
	gear.affixes = [modifier]
	return gear


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	assert(condition, message)
