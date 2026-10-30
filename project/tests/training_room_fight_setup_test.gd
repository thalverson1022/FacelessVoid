extends SceneTree
## Headless P2:R10:T5 check: the target/duration/seed/practice-gold controls
## actually set TrainingRoomState's fight-setup fields, practice gold feeds
## resolved stats live (Bandit Blade's gold-scaling damage becomes testable
## here), and none of it ever touches the real BuildState singleton. The
## target exposes adjustable functional defenses, including general magical
## resistance through the current poison_resistance runtime field, never a
## killable HP target. Run with:
##   godot --headless -s res://tests/training_room_fight_setup_test.gd

static var MECHANIC_DODGE_ICON: Texture2D = GameIcons.icon_for("defense.dodge")
static var MECHANIC_BLOCK_ICON: Texture2D = GameIcons.icon_for("defense.block")
static var MECHANIC_INTERRUPT_ICON: Texture2D = GameIcons.icon_for("defense.interrupt")


func _initialize() -> void:
	var build_state = root.get_node("BuildState")

	var game_root_scene: PackedScene = load("res://scenes/game_root.tscn")
	var game_root = game_root_scene.instantiate()
	root.add_child(game_root)
	await process_frame

	# Real Adventure gold, set after game_root's own startup reset (see
	# training_room_entry_test.gd for why this must happen after, not
	# before).
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	build_state.set_class(rogue)
	build_state.gold = 888
	var real_gold_before: int = build_state.gold

	var title = game_root._current_screen
	title.training_room_pressed.emit()
	await process_frame
	var training_room = game_root._current_screen

	var character_stats_panel = training_room.find_child("CharacterStatsPanel", true, false)
	var target_panel: TrainingTargetPanel = training_room.find_child("TargetPanel", true, false)
	var primary_archetype_option: OptionButton = training_room.find_child("PrimaryArchetypeOption", true, false)
	var secondary_archetype_option: OptionButton = training_room.find_child("SecondaryArchetypeOption", true, false)
	var generated_difficulty_option: OptionButton = training_room.find_child("GeneratedDifficultyOption", true, false)
	var generated_type_option: OptionButton = training_room.find_child("GeneratedTypeOption", true, false)
	var generated_contract_level_spin: SpinBox = training_room.find_child("GeneratedContractLevelSpin", true, false)
	var fight_seed_spin: SpinBox = training_room.find_child("FightSeedSpin", true, false)
	var random_fight_seed_toggle: CheckBox = training_room.find_child("RandomFightSeedToggle", true, false)
	var practice_gold_spin: SpinBox = training_room.find_child("PracticeGoldSpin", true, false)
	var roll_generated_button: Button = training_room.find_child("RollGeneratedMonsterButton", true, false)
	assert(character_stats_panel != null)
	assert(target_panel != null)
	assert(primary_archetype_option != null)
	assert(secondary_archetype_option != null)
	assert(generated_difficulty_option != null)
	assert(generated_type_option != null)
	assert(generated_contract_level_spin != null)
	assert(fight_seed_spin != null)
	assert(random_fight_seed_toggle != null)
	assert(practice_gold_spin != null)
	assert(roll_generated_button != null)
	assert(training_room.find_child("GeneratedMonsterInfo", true, false) == null)
	assert(_all_label_texts(training_room).has("Seed"))
	assert(_all_label_texts(training_room).has("Contract Level"))
	assert(random_fight_seed_toggle.text == "Random")
	assert(not training_room._state.random_fight_seed_enabled)
	assert(fight_seed_spin.editable)
	assert(primary_archetype_option.get_item_text(0) == "None")
	assert(secondary_archetype_option.get_item_text(0) == "None")
	assert(_option_texts(generated_type_option) == PackedStringArray(["normal", "captain", "elite", "boss"]))
	assert(_target_control_labels(target_panel) == PackedStringArray([
		"Contract Level",
		"Difficulty",
		"Type",
		"Main",
		"Secondary",
		"Armor",
		"Block",
		"Dodge %",
		"Crit Negate %",
		"Resist %",
		"Absorb",
		"Suppress %",
		"Slow %",
		"Cleanse",
		"Stun ms",
		"Interrupt",
	]))

	# -- Defaults: all defenses 0, 20s, seed 1, 0 practice gold --
	var target: Monster = training_room._state.selected_target
	print("default defenses: armor=%d, poison_resist=%.2f, dodge=%.2f, crit_negation=%.2f, block=%.2f, absorb=%.2f, cleanse=%d, suppress=%.2f, slow=%.2f, stun=%d, interrupt=%d" % [
		target.armor,
		target.poison_resistance,
		target.dodge_chance,
		target.crit_negation,
		target.block,
		target.absorb,
		target.cleanse_threshold,
		target.suppress,
		target.slow,
		target.stun_duration_ms,
		target.interrupt_skip_count,
	])
	print("default duration=%d (expect 20000), seed=%d (expect 1), gold=%d (expect 0)" % [
		training_room._state.duration_ms,
		training_room._state.fight_seed,
		training_room._state.gold,
	])
	_assert_target_defenses(target, {
		"armor": 0,
		"poison_resistance": 0.0,
		"dodge_chance": 0.0,
		"crit_negation": 0.0,
		"block": 0.0,
		"absorb": 0.0,
		"cleanse_threshold": 0,
		"suppress": 0.0,
		"slow": 0.0,
		"stun_duration_ms": 0,
		"interrupt_skip_count": 0,
	})
	assert(training_room._state.duration_ms == 20000)
	assert(training_room._state.fight_seed == 1)
	assert(int(fight_seed_spin.value) == 1)
	assert(int(generated_contract_level_spin.value) == 1)
	assert(training_room._state.generated_contract_level == 1)
	assert(training_room._state.gold == 0)
	_select_option_by_id(generated_difficulty_option, 1)
	_select_option_by_metadata(generated_type_option, "normal")
	assert(_option_has_metadata(primary_archetype_option, "fortified"))
	assert(not _option_has_metadata(primary_archetype_option, "riftbound"))
	_select_option_by_id(generated_difficulty_option, 3)
	_select_option_by_metadata(generated_type_option, "elite")
	assert(_option_has_metadata(primary_archetype_option, "riftbound"))
	_select_option_by_metadata(primary_archetype_option, "riftbound")
	_select_option_by_id(generated_difficulty_option, 1)
	assert(primary_archetype_option.get_item_text(0) == "None")
	assert(primary_archetype_option.selected == 0)
	assert(not _option_has_metadata(primary_archetype_option, "riftbound"))
	var default_target_id: String = target.id
	var default_fight_seed: int = training_room._state.fight_seed
	roll_generated_button.pressed.emit()
	await process_frame
	assert(training_room._state.generated_monster_draft == null)
	assert(training_room._state.selected_target == target)
	assert(training_room._state.selected_target.id == default_target_id)
	assert(training_room._state.fight_seed == default_fight_seed)

	# -- Testing-only runtime generated target roller --
	_select_option_by_id(generated_difficulty_option, 2)
	_select_option_by_metadata(generated_type_option, "normal")
	_select_option_by_metadata(primary_archetype_option, "fortified")
	fight_seed_spin.value = 777
	fight_seed_spin.value_changed.emit(777.0)
	roll_generated_button.pressed.emit()
	await process_frame
	assert(training_room._state.generated_monster_draft != null)
	assert(training_room._state.generated_monster_difficulty_id == 2)
	assert(training_room._state.generated_monster_draft.source_seed == 777)
	var random_draft: GeneratedMonsterDraft = training_room._state.generated_monster_draft
	var random_seed := random_draft.source_seed

	roll_generated_button.pressed.emit()
	await process_frame
	assert(training_room._state.generated_monster_draft != null)
	assert(training_room._state.generated_monster_draft.source_seed == random_seed)

	random_fight_seed_toggle.button_pressed = true
	random_fight_seed_toggle.toggled.emit(true)
	await process_frame
	assert(training_room._state.random_fight_seed_enabled)
	assert(not fight_seed_spin.editable)
	roll_generated_button.pressed.emit()
	await process_frame
	assert(training_room._state.generated_monster_draft.source_seed != random_seed)
	random_fight_seed_toggle.button_pressed = false
	random_fight_seed_toggle.toggled.emit(false)
	await process_frame
	assert(not training_room._state.random_fight_seed_enabled)
	assert(fight_seed_spin.editable)

	_select_option_by_id(generated_difficulty_option, 3)
	_select_option_by_metadata(generated_type_option, "captain")
	generated_contract_level_spin.value = 12
	generated_contract_level_spin.value_changed.emit(12.0)
	_select_option_by_metadata(primary_archetype_option, "fortified")
	_select_option_by_metadata(secondary_archetype_option, "warded")
	roll_generated_button.pressed.emit()
	await process_frame
	var draft: GeneratedMonsterDraft = training_room._state.generated_monster_draft
	assert(not draft.has_errors())
	assert(draft.source_input.monster_kind == "captain")
	assert(training_room._state.generated_contract_level == 12)
	assert(int(draft.source_input.overrides["contract_hp_scaling"]["contract_number"]) == 12)
	assert(float(draft.source_input.overrides["contract_hp_scaling"]["multiplier"]) > 1.0)
	assert(draft.archetype_ids == PackedStringArray(["fortified", "warded"]))
	var hard_draft := draft

	_select_option_by_id(generated_difficulty_option, 4)
	_select_option_by_metadata(generated_type_option, "boss")
	roll_generated_button.pressed.emit()
	await process_frame
	assert(training_room._state.generated_monster_draft != null)
	assert(training_room._state.generated_monster_draft.source_input.difficulty_id == 4)
	assert(training_room._state.generated_monster_draft.source_input.monster_kind == "boss")
	assert(training_room._state.generated_monster_draft.budget_metadata["budget"] > hard_draft.budget_metadata["budget"])
	assert(training_room._state.generated_monster_draft.pressure_metadata["target_dps_range"][0] > hard_draft.pressure_metadata["target_dps_range"][0])

	_select_option_by_id(generated_difficulty_option, 3)
	_select_option_by_metadata(generated_type_option, "normal")
	_select_option_by_metadata(primary_archetype_option, "warded")
	_select_option_by_metadata(secondary_archetype_option, "")
	roll_generated_button.pressed.emit()
	await process_frame
	draft = training_room._state.generated_monster_draft
	target = training_room._state.selected_target
	print("generated target=%s hp=%d duration=%d seed=%d archetypes=%s" % [
		target.display_name,
		target.hp,
		training_room._state.duration_ms,
		training_room._state.fight_seed,
		draft.archetype_ids,
	])
	assert(not draft.has_errors())
	assert(training_room._state.generated_monster_draft == draft)
	assert(target.id == draft.id)
	assert(target.display_name == draft.display_name)
	assert(target.hp == draft.hp)
	assert(training_room._state.duration_ms == draft.duration_ms)
	assert(training_room._state.fight_seed == draft.source_seed)
	assert((training_room._duration_spin as SpinBox).value == roundi(float(draft.duration_ms) / 1000.0))
	assert(int(fight_seed_spin.value) == draft.source_seed)
	for field in draft.defense_overrides:
		var spin: SpinBox = target_panel._defense_spins[field]
		var expected: Variant = draft.defense_overrides[field]
		if TrainingTargetPanel.PERCENT_FIELDS.has(field):
			assert(spin.value == roundi(float(expected) * 100.0))
		else:
			assert(absf(spin.value - float(expected)) <= maxf(0.001, spin.step))

	# -- Target defense adjustment --
	training_room._on_target_defense_changed("armor", 160)
	training_room._on_target_defense_changed("poison_resistance", 0.35)
	training_room._on_target_defense_changed("dodge_chance", 0.2)
	training_room._on_target_defense_changed("crit_negation", 0.45)
	training_room._on_target_defense_changed("block", 4.0)
	training_room._on_target_defense_changed("absorb", 3.0)
	training_room._on_target_defense_changed("cleanse_threshold", 2)
	training_room._on_target_defense_changed("suppress", 0.5)
	training_room._on_target_defense_changed("slow", 0.25)
	training_room._on_target_defense_changed("stun_duration_ms", 450)
	training_room._on_target_defense_changed("interrupt_skip_count", 2)
	await process_frame
	print("target after full adjustment: armor=%d, poison_resist=%.2f, dodge=%.2f, crit_negation=%.2f, block=%.2f, absorb=%.2f, cleanse=%d, suppress=%.2f, slow=%.2f, stun=%d, interrupt=%d" % [
		target.armor,
		target.poison_resistance,
		target.dodge_chance,
		target.crit_negation,
		target.block,
		target.absorb,
		target.cleanse_threshold,
		target.suppress,
		target.slow,
		target.stun_duration_ms,
		target.interrupt_skip_count,
	])
	_assert_target_defenses(target, {
		"armor": 160,
		"poison_resistance": 0.35,
		"dodge_chance": 0.2,
		"crit_negation": 0.45,
		"block": 4.0,
		"absorb": 3.0,
		"cleanse_threshold": 2,
		"suppress": 0.5,
		"slow": 0.25,
		"stun_duration_ms": 450,
		"interrupt_skip_count": 2,
	})
	assert((target_panel._defense_spins["armor"] as SpinBox).value == 160)
	assert((target_panel._defense_spins["poison_resistance"] as SpinBox).value == 35)
	assert((target_panel._defense_spins["dodge_chance"] as SpinBox).value == 20)
	assert((target_panel._defense_spins["crit_negation"] as SpinBox).value == 45)
	assert((target_panel._defense_spins["cleanse_threshold"] as SpinBox).value == 2)
	assert((target_panel._defense_spins["stun_duration_ms"] as SpinBox).value == 450)
	assert((target_panel._defense_spins["interrupt_skip_count"] as SpinBox).value == 2)
	assert(training_room._combat_view._info_label.text == "160")
	assert(training_room._combat_view._resist_label.text == "35%")
	assert(_has_chip(training_room._combat_view._mechanic_row, MECHANIC_DODGE_ICON, "20%"))
	assert(_has_chip(training_room._combat_view._mechanic_row, MECHANIC_BLOCK_ICON, "4"))
	assert(_has_chip(training_room._combat_view._status_row, MECHANIC_INTERRUPT_ICON, "0/3"))
	assert(training_room._state.generated_monster_draft == null)

	# -- Presets mirror Monster Lab archetype identities and reset fields not
	# used by that identity. Devious now includes timing disruption because
	# stun/interrupt have Practice Room runtime behavior.
	training_room._on_target_preset_selected("fortified")
	await process_frame
	_assert_target_defenses(target, {"armor": 100, "crit_negation": 0.5, "block": 3.0})
	assert(target.dodge_chance == 0.0)
	assert(target.slow == 0.0)

	training_room._on_target_preset_selected("warded")
	await process_frame
	_assert_target_defenses(target, {"poison_resistance": 0.25, "absorb": 5.0, "suppress": 0.25})
	assert(target.armor == 0)
	assert(target.block == 0.0)

	training_room._on_target_preset_selected("nimble")
	await process_frame
	_assert_target_defenses(target, {"dodge_chance": 0.12, "crit_negation": 0.55})
	assert(target.poison_resistance == 0.0)
	assert(target.absorb == 0.0)

	training_room._on_target_preset_selected("hexed")
	await process_frame
	_assert_target_defenses(target, {"cleanse_threshold": 5, "suppress": 0.35})
	assert(target.dodge_chance == 0.0)

	training_room._on_target_preset_selected("devious")
	await process_frame
	_assert_target_defenses(target, {"cleanse_threshold": 5, "slow": 0.25, "stun_duration_ms": 300, "interrupt_skip_count": 1})

	# -- Duration --
	training_room._on_duration_changed(35.0)
	training_room._on_fight_seed_changed(12345.0)
	await process_frame
	print("duration_ms after setting 35s (expect 35000): %d" % training_room._state.duration_ms)
	assert(training_room._state.duration_ms == 35000)
	assert(training_room._state.fight_seed == 12345)
	assert(int(fight_seed_spin.value) == 12345)
	assert(training_room._combat_view._fight_timer_label.text == "35s")
	random_fight_seed_toggle.button_pressed = true
	random_fight_seed_toggle.toggled.emit(true)
	await process_frame
	var seed_before_random_fight: int = training_room._state.fight_seed
	# Use an unlocked base skill in the scoped registry, without assuming
	# the legacy tree-array order or an intrinsic Quick Cut grant.
	var stab: Skill = null
	for skill in training_room._state.unlocked_skills():
		if skill.id == "skill.stab": stab = skill
	assert(stab != null)
	var practice_rotation: Array[Skill] = [stab]
	training_room._state.set_rotation(practice_rotation)
	training_room._state.set_locked(true)
	training_room._state.run_fight()
	await process_frame
	assert(training_room._state.fight_seed != seed_before_random_fight)

	# -- Generated target seeds stay internal to Practice Room --
	build_state.set_adventure_seed(999)
	print("practice fight_seed=%d, real adventure_seed=%d (expect 999, unchanged by Practice Room)" % [
		training_room._state.fight_seed, build_state.adventure_seed
	])
	assert(build_state.adventure_seed == 999)

	# -- Practice gold feeds resolved stats live (Bandit Blade gold-scaling,
	# P2:R9:T2), without touching the real BuildState.gold --
	var bandit_blade: GearItem = load("res://data/gear/bandit_blade.tres")
	training_room._state.equip_legendary(bandit_blade)
	await process_frame
	var stats_text_before_gold: String = character_stats_panel._stats_label.text

	training_room._on_practice_gold_changed(200.0)
	await process_frame
	print("practice gold=%d (expect 200), real gold=%d (expect %d, unchanged)" % [
		training_room._state.gold, build_state.gold, real_gold_before
	])
	assert(training_room._state.gold == 200)
	assert(int(practice_gold_spin.value) == 200)
	assert(build_state.gold == real_gold_before)
	assert(character_stats_panel._stats_label.text != stats_text_before_gold)

	var resolved := BuildResolver.resolve_stats(
		training_room._state.selected_class, training_room._state.selected_trees,
		training_room._state.selected_talents, training_room._state.equipped_gear(),
		training_room._state.gold
	)
	print("resolved bonus_physical_damage at 200 practice gold (expect 20.0): %.2f" % resolved.bonus_physical_damage)
	assert(is_equal_approx(resolved.bonus_physical_damage, 20.0))

	training_room._state.add_practice_combat_gold(3)
	await process_frame
	print("practice stolen-gold preview=%d, practice gold spin=%d (expect 3, 203)" % [
		training_room._state.combat_stolen_gold, int(practice_gold_spin.value)
	])
	assert(training_room._state.combat_stolen_gold == 3)
	assert(training_room._state.gold == 203)
	assert(int(practice_gold_spin.value) == 203)

	print("")
	print("Practice Room fight setup check: OK")
	quit()


func _assert_target_defenses(target: Monster, expected: Dictionary) -> void:
	if expected.has("armor"):
		assert(target.armor == int(expected["armor"]))
	if expected.has("poison_resistance"):
		assert(is_equal_approx(target.poison_resistance, float(expected["poison_resistance"])))
	if expected.has("dodge_chance"):
		assert(is_equal_approx(target.dodge_chance, float(expected["dodge_chance"])))
	if expected.has("crit_negation"):
		assert(is_equal_approx(target.crit_negation, float(expected["crit_negation"])))
	if expected.has("block"):
		assert(is_equal_approx(target.block, float(expected["block"])))
	if expected.has("absorb"):
		assert(is_equal_approx(target.absorb, float(expected["absorb"])))
	if expected.has("cleanse_threshold"):
		assert(target.cleanse_threshold == int(expected["cleanse_threshold"]))
	if expected.has("suppress"):
		assert(is_equal_approx(target.suppress, float(expected["suppress"])))
	if expected.has("slow"):
		assert(is_equal_approx(target.slow, float(expected["slow"])))
	if expected.has("stun_duration_ms"):
		assert(target.stun_duration_ms == int(expected["stun_duration_ms"]))
	if expected.has("interrupt_skip_count"):
		assert(target.interrupt_skip_count == int(expected["interrupt_skip_count"]))


func _has_chip(row: Container, icon_texture: Texture2D, text: String) -> bool:
	for child in row.get_children():
		var icon := child.get_node_or_null("Icon") as TextureRect
		var label := child.get_node_or_null("Text") as Label
		if icon != null and label != null and icon.texture == icon_texture and label.text == text:
			return true
	return false


func _option_texts(option: OptionButton) -> PackedStringArray:
	var texts := PackedStringArray()
	for index in range(option.item_count):
		texts.append(option.get_item_text(index))
	return texts


func _select_option_by_metadata(option: OptionButton, metadata: String) -> void:
	for index in range(option.item_count):
		if str(option.get_item_metadata(index)) == metadata:
			option.select(index)
			option.item_selected.emit(index)
			return
	assert(false)


func _select_option_by_id(option: OptionButton, id: int) -> void:
	var index := option.get_item_index(id)
	assert(index >= 0)
	option.select(index)
	option.item_selected.emit(index)


func _option_has_metadata(option: OptionButton, metadata: String) -> bool:
	for index in range(option.item_count):
		if str(option.get_item_metadata(index)) == metadata:
			return true
	return false


func _all_label_texts(root: Node) -> PackedStringArray:
	var labels := PackedStringArray()
	for label in root.find_children("*", "Label", true, false):
		labels.append((label as Label).text)
	return labels


func _target_control_labels(target_panel: TrainingTargetPanel) -> PackedStringArray:
	var labels := PackedStringArray()
	for label in target_panel.find_children("*", "Label", true, false):
		var text := (label as Label).text
		if [
			"Contract Level",
			"Difficulty",
			"Type",
			"Main",
			"Secondary",
			"Armor",
			"Block",
			"Dodge %",
			"Crit Negate %",
			"Resist %",
			"Absorb",
			"Suppress %",
			"Slow %",
			"Cleanse",
			"Stun ms",
			"Interrupt",
		].has(text):
			labels.append(text)
	return labels
