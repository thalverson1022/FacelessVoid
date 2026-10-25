extends SceneTree

const StatCatalog := preload("res://scripts/systems/stat_catalog.gd")
const StatSheet := preload("res://scripts/resources/stat_sheet.gd")
const SaveSystemScript := preload("res://scripts/systems/save_system.gd")

const TEST_SAVE_PATH := "res://.test_p5m3_foundation_regression.json"


func _initialize() -> void:
	print("-- P5M3 foundation regression --")
	_check_end_to_end_stat_foundation()
	_check_save_load_keeps_foundation_canonical()
	print("P5M3 foundation regression check: OK")
	quit(0)


func _check_end_to_end_stat_foundation() -> void:
	_require(StatCatalog.has_stat(StatCatalog.PERCENT_PHYSICAL_DAMAGE), "Expected canonical percent physical stat.")
	_require(StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_BASIC, StatCatalog.PERCENT_PHYSICAL_DAMAGE), "Expected Weapon Basic slot eligibility.")
	_require(not StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_BASIC, StatCatalog.CRIT_CHANCE), "Expected invalid slot/stat pair to fail.")

	var weapon := _gear(GearItem.SlotType.WEAPON, [
		_numeric_modifier(StatCatalog.BASE_DAMAGE, 6.0),
		_numeric_modifier(StatCatalog.PERCENT_PHYSICAL_DAMAGE, 0.20),
		_numeric_modifier(StatCatalog.CRIT_DAMAGE, 0.25),
		_special_modifier(StatCatalog.ALL_STATS_INCREASED),
	])
	var helm := _gear(GearItem.SlotType.HELM, [
		_numeric_modifier(StatCatalog.CRIT_CHANCE, 0.90),
		_numeric_modifier(StatCatalog.INCREASED_ATTACK_SPEED, 0.10),
		_special_modifier(StatCatalog.IGNORE_RESISTANCE_PHYSICAL_PENALTY),
	])
	var armor := _gear(GearItem.SlotType.ARMOR, [
		_numeric_modifier(StatCatalog.PERCENT_PHYSICAL_DAMAGE, -0.05, true),
		_numeric_modifier(StatCatalog.CHANCE_TO_SHRED, 0.30),
		_special_modifier(StatCatalog.DISABLE_ENEMY_DODGE),
		_special_modifier(StatCatalog.DISABLE_ENEMY_DODGE),
	])
	var trinket := _gear(GearItem.SlotType.TRINKET, [
		_numeric_modifier(StatCatalog.PERCENT_ELEMENTAL_DAMAGE, 0.40),
		_numeric_modifier(StatCatalog.CHANCE_FOR_RETRIGGER, 0.95),
		_special_modifier(StatCatalog.DOUBLE_APPLIED_STACKS),
	])
	var charm := _gear(GearItem.SlotType.CHARM, [
		_numeric_modifier(StatCatalog.INCREASED_ELEMENTAL_STACKS, 2.0),
		_numeric_modifier(StatCatalog.INCREASED_GOLD, 0.25),
		_special_modifier(StatCatalog.IMMUNE_TO_STUN),
		_special_modifier(StatCatalog.IMMUNE_TO_INTERRUPT),
	])

	var sheet = _sheet([weapon, helm, armor, trinket, charm])
	_require_approx(sheet.base_damage(), 6.0, "Expected base damage to remain unscaled.")
	_require_approx(sheet.percent_physical_damage(), 0.18, "Expected positive and drawback physical stats to net, floor, then scale.")
	_require_approx(sheet.crit_chance(), 1.0, "Expected crit chance to cap after scaling.")
	_require_approx(sheet.increased_attack_speed(), 0.12, "Expected attack speed to scale.")
	_require_approx(sheet.crit_damage(), 0.30, "Expected crit damage to scale.")
	_require_approx(sheet.percent_elemental_damage(), 0.48, "Expected elemental percent to scale.")
	_require_approx(sheet.chance_for_retrigger(), 1.0, "Expected Rare chance to cap after scaling.")
	_require_approx(sheet.chance_to_shred(), 0.36, "Expected Rare chance to scale when uncapped.")
	_require(sheet.increased_elemental_stacks() == 2, "Expected scaled stack accessor to round deterministically.")
	_require_approx(sheet.increased_gold(), 0.30, "Expected gold increase to scale.")

	_require(sheet.active_specials().size() == 6, "Expected duplicate Special collapse and different Specials to combine.")
	_require(sheet.count_for(StatCatalog.DISABLE_ENEMY_DODGE) == 2, "Expected duplicate source count to remain visible.")
	_require(sheet.denies_enemy_dodge(), "Expected enemy dodge denial hook.")
	_require(sheet.doubles_applied_stacks(), "Expected stack doubling hook.")
	_require(sheet.immune_to_stun(), "Expected stun immunity hook.")
	_require(sheet.immune_to_interrupt(), "Expected interrupt immunity hook.")
	_require_approx(sheet.physical_damage_penalty(), 0.5, "Expected fixed Special constant to remain unscaled.")

	var stats := BuildResolver.resolve_stats(null, [], [], [weapon, helm, armor, trinket, charm])
	_require_approx(stats.bonus_physical_damage, 6.0, "Expected PlayerStats bridge to preserve base damage exception.")
	_require_approx(stats.physical_damage_multiplier, 1.18, "Expected PlayerStats bridge to use scaled physical percent.")
	_require_approx(stats.crit_chance, 1.0, "Expected PlayerStats bridge to use capped crit chance.")
	_require_approx(stats.attack_speed, 0.12, "Expected PlayerStats bridge to use scaled attack speed.")
	_require(stats.special_stat_ids.size() == 6, "Expected PlayerStats bridge to carry collapsed Specials.")
	var denial: Dictionary = stats.special_effects["enemy_denial"]
	var immunities: Dictionary = stats.special_effects["immunities"]
	_require(denial["dodge"], "Expected PlayerStats summary to carry dodge denial.")
	_require(immunities["stun"] and immunities["interrupt"], "Expected PlayerStats summary to carry immunities.")

	var lucky_coin: GearItem = load("res://data/gear/lucky_coin.tres")
	_require(lucky_coin != null, "Expected Lucky Coin resource.")
	_require_approx(_sheet([lucky_coin]).crit_chance(), 0.05, "Expected Lucky Coin authored gear compatibility.")


func _check_save_load_keeps_foundation_canonical() -> void:
	var build_state = root.get_node("BuildState")
	build_state.reset()
	SaveSystemScript.save_path = TEST_SAVE_PATH
	SaveSystemScript.delete_save()

	var runtime_gear := {
		"id": "gear.test.p5m3.foundation",
		"display_name": "Foundation Gear",
		"slot": GearItem.SlotType.ARMOR,
		"tier": GearItem.Tier.UNIQUE,
		"source_kind": GearItem.SourceKind.GENERATED,
		"deterministic_key": "gear.test.p5m3.foundation",
		"affixes": [{
			"stat_id": "physical_damage",
			"stat": StatModifier.StatType.PHYSICAL_DAMAGE,
			"category": StatModifier.StatCategory.BASIC,
			"operation": StatModifier.OperationType.MULTIPLY,
			"value": 1.1,
		}, {
			"stat_id": StatCatalog.ALL_STATS_INCREASED,
			"stat": StatModifier.StatType.ATTACK_SPEED,
			"category": StatModifier.StatCategory.SPECIAL,
			"operation": StatModifier.OperationType.ADD,
			"value": 1.0,
		}],
	}
	_write_save({"save_version": SaveSystemScript.SAVE_VERSION, "equipped_armor": runtime_gear})
	_require(SaveSystemScript.load_run(build_state), "Expected runtime gear save to load.")
	_require(build_state.equipped_armor.affixes[0].stat_id == StatCatalog.PERCENT_PHYSICAL_DAMAGE, "Expected old alias to canonicalize on load.")
	_require(build_state.equipped_armor.affixes[1].stat_id == StatCatalog.ALL_STATS_INCREASED, "Expected Special ID to survive load.")
	_require_approx(BuildResolver.resolve_stats(null, [], [], build_state.equipped_gear()).physical_damage_multiplier, 1.12, "Expected loaded canonicalized gear to resolve with all-stats scaling.")

	_require(SaveSystemScript.save_run(build_state), "Expected canonicalized runtime gear to save.")
	var saved := _read_save()
	_require(saved["equipped_armor"]["affixes"][0]["stat_id"] == StatCatalog.PERCENT_PHYSICAL_DAMAGE, "Expected save data to persist canonical ID.")
	SaveSystemScript.delete_save()
	SaveSystemScript.save_path = SaveSystemScript.SAVE_PATH
	build_state.reset()


func _gear(slot: GearItem.SlotType, affixes: Array) -> GearItem:
	var item := GearItem.new()
	item.slot = slot
	item.tier = GearItem.Tier.UNIQUE
	item.source_kind = GearItem.SourceKind.GENERATED
	for affix in affixes:
		item.affixes.append(affix)
	return item


func _sheet(equipped_gear: Array):
	var sheet = StatSheet.new()
	sheet.add_gear_collection(equipped_gear)
	sheet.finalize()
	return sheet


func _special_modifier(stat_id: String) -> StatModifier:
	var modifier := _numeric_modifier(stat_id, 1.0)
	modifier.category = StatModifier.StatCategory.SPECIAL
	return modifier


func _numeric_modifier(stat_id: String, value: float, is_drawback: bool = false) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.stat_id = stat_id
	modifier.stat = StatModifier.StatType.ATTACK_SPEED
	modifier.operation = StatModifier.OperationType.ADD
	modifier.value = value
	modifier.category = StatModifier.StatCategory.DRAWBACK if is_drawback else StatModifier.StatCategory.BASIC
	modifier.is_drawback = is_drawback
	return modifier


func _write_save(data: Dictionary) -> void:
	# Keep this gear canonicalization test inside the current Phase 6 envelope.
	data["build"] = BuildSaveCodec.encode(root.get_node("BuildState"), SaveSystemScript.registry())
	SaveSystemScript.delete_save()
	var file := FileAccess.open(SaveSystemScript.save_path, FileAccess.WRITE)
	_require(file != null, "Expected test save file to open for writing.")
	file.store_string(JSON.stringify(data))
	file.close()


func _read_save() -> Dictionary:
	var file := FileAccess.open(SaveSystemScript.save_path, FileAccess.READ)
	_require(file != null, "Expected test save file to open for reading.")
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	_require(typeof(parsed) == TYPE_DICTIONARY, "Expected saved JSON object.")
	return parsed


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	assert(false, message)
	quit(1)


func _require_approx(actual: float, expected: float, message: String) -> void:
	_require(is_equal_approx(actual, expected), "%s Expected %.4f, got %.4f." % [message, expected, actual])
