extends SceneTree
## Focused P5M2-T7 check: save/load has an explicit Phase 5 gear boundary.

const TEST_SAVE_PATH := "res://.test_p5m2_save_load_boundary.json"


func _initialize() -> void:
	# This suite intentionally exercises the retained legacy save fixture registry.
	SaveSystem.registry_override = BuildContentRegistry.current()
	var build_state = root.get_node("BuildState")
	build_state.reset()
	SaveSystem.save_path = TEST_SAVE_PATH
	SaveSystem.delete_save()

	print("-- P5M2 save/load boundary --")
	_check_new_save_writes_five_equipped_fields(build_state)
	_check_partial_old_save_loads_with_empty_new_slots(build_state)
	_check_lucky_coin_migrates_from_old_trinket_field(build_state)
	_check_known_authored_gear_survives_old_runtime_entries(build_state)
	_check_obsolete_generated_runtime_gear_is_quarantined(build_state)
	_check_invalid_runtime_gear_is_quarantined(build_state)

	SaveSystem.delete_save()
	SaveSystem.save_path = SaveSystem.SAVE_PATH
	build_state.reset()
	print("P5M2 save/load boundary check: OK")
	quit(0)


func _check_new_save_writes_five_equipped_fields(build_state) -> void:
	build_state.reset()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7107
	for slot in GearItem.universal_slot_order():
		build_state.equip(GearGenerator.generate(GearItem.Tier.BASIC, slot, rng, "gear.test.t7.saved_%s" % slot))
	_require(SaveSystem.save_run(build_state), "Expected save_run to write a five-slot save.")
	var data := _read_save()
	for field in ["equipped_weapon", "equipped_helm", "equipped_armor", "equipped_trinket", "equipped_charm"]:
		_require(data.has(field), "Expected save to include %s." % field)
		_require(data[field] != null, "Expected save field %s to hold equipped gear." % field)
	build_state.reset()
	_require(SaveSystem.load_run(build_state), "Expected five-slot save to load.")
	_require(build_state.equipped_gear().size() == 5, "Expected all five equipped slots to roundtrip.")


func _check_partial_old_save_loads_with_empty_new_slots(build_state) -> void:
	build_state.reset()
	_write_save({
		"save_version": SaveSystem.SAVE_VERSION,
		"gold": 12,
		"equipped_weapon": null,
		"equipped_trinket": null,
		"equipped_charm": null,
	})
	_require(SaveSystem.load_run(build_state), "Expected partial old three-slot save to load.")
	_require(build_state.gold == 12, "Expected partial old save scalar state to load.")
	_require(build_state.equipped_helm == null, "Expected missing Helm field to load as empty.")
	_require(build_state.equipped_armor == null, "Expected missing Armor field to load as empty.")


func _check_lucky_coin_migrates_from_old_trinket_field(build_state) -> void:
	build_state.reset()
	_write_save({
		"save_version": SaveSystem.SAVE_VERSION,
		"equipped_trinket": {
			"id": "gear.lucky_coin",
			"display_name": "Lucky Coin",
			"slot": GearItem.SlotType.TRINKET,
			"tier": GearItem.Tier.BASIC,
			"affixes": [{
				"stat": StatModifier.StatType.CRIT_CHANCE,
				"operation": StatModifier.OperationType.ADD,
				"value": 0.05,
			}],
		},
	})
	_require(SaveSystem.load_run(build_state), "Expected old Lucky Coin save to load.")
	_require(build_state.equipped_trinket != null, "Expected Lucky Coin to occupy Trinket.")
	_require(build_state.equipped_trinket.id == "gear.lucky_coin", "Expected migrated Lucky Coin id.")
	_require(build_state.equipped_trinket.slot == GearItem.SlotType.TRINKET, "Expected migrated Lucky Coin to use current Trinket resource.")
	_require(build_state.equipped_charm == null, "Expected Lucky Coin not to occupy Charm.")


func _check_known_authored_gear_survives_old_runtime_entries(build_state) -> void:
	build_state.reset()
	_write_save({
		"save_version": SaveSystem.SAVE_VERSION,
		"inventory": [{
			"id": "gear.legendary.wyvern_kriss",
			"display_name": "Wyvern Kriss",
			"slot": GearItem.SlotType.WEAPON,
			"tier": GearItem.Tier.LEGENDARY,
			"affixes": [],
		}],
	})
	_require(SaveSystem.load_run(build_state), "Expected old known Legendary save to load.")
	_require(build_state.inventory.size() == 1, "Expected retained Legendary to survive in inventory.")
	_require(build_state.inventory[0].id == "gear.legendary.wyvern_kriss", "Expected canonical Wyvern Kriss resource.")
	_require(build_state.inventory[0].source_kind == GearItem.SourceKind.LEGENDARY, "Expected canonical Legendary source kind.")


func _check_obsolete_generated_runtime_gear_is_quarantined(build_state) -> void:
	build_state.reset()
	var old_generated := {
		"id": "gear.generated.old_ring",
		"display_name": "Old Generated Ring",
		"slot": GearItem.SlotType.TRINKET,
		"tier": GearItem.Tier.MASTER,
		"affixes": [{
			"stat": StatModifier.StatType.ATTACK_SPEED,
			"operation": StatModifier.OperationType.ADD,
			"value": 0.1,
		}],
	}
	_write_save({
		"save_version": SaveSystem.SAVE_VERSION,
		"inventory": [old_generated],
		"shop_offers": [old_generated],
		"pending_reward_choices": [old_generated],
		"equipped_trinket": old_generated,
	})
	_require(SaveSystem.load_run(build_state), "Expected obsolete generated runtime gear save to load with gear quarantined.")
	_require(build_state.inventory.is_empty(), "Expected obsolete generated inventory gear to be dropped.")
	_require(build_state.shop_offers.is_empty(), "Expected obsolete generated shop gear to be dropped.")
	_require(build_state.pending_reward_choices.is_empty(), "Expected obsolete generated reward choices to be dropped.")
	_require(build_state.equipped_trinket == null, "Expected obsolete generated equipped gear to be dropped.")
	_require(_has_notice("dropped_obsolete_runtime_gear:inventory[0]:gear.generated.old_ring"), "Expected obsolete inventory gear notice.")


func _check_invalid_runtime_gear_is_quarantined(build_state) -> void:
	build_state.reset()
	_write_save({
		"save_version": SaveSystem.SAVE_VERSION,
		"inventory": [{
			"id": "gear.test.invalid_slot",
			"display_name": "Invalid Slot",
			"slot": 99,
			"tier": GearItem.Tier.BASIC,
			"source_kind": GearItem.SourceKind.GENERATED,
			"affixes": [],
		}, {
			"id": "gear.test.invalid_tier",
			"display_name": "Invalid Tier",
			"slot": GearItem.SlotType.HELM,
			"tier": 99,
			"source_kind": GearItem.SourceKind.GENERATED,
			"affixes": [],
		}],
	})
	_require(SaveSystem.load_run(build_state), "Expected invalid runtime gear save to load with gear quarantined.")
	_require(build_state.inventory.is_empty(), "Expected invalid runtime gear to be dropped.")
	_require(_has_notice("dropped_invalid_slot:inventory[0]:gear.test.invalid_slot"), "Expected invalid slot notice.")
	_require(_has_notice("dropped_invalid_tier:inventory[1]:gear.test.invalid_tier"), "Expected invalid tier notice.")


func _write_save(data: Dictionary) -> void:
	# Exercise inherited gear encodings inside a valid current envelope.
	# Whole version-1 saves are covered by P6 reset tests instead.
	data["build"] = BuildSaveCodec.encode(root.get_node("BuildState"), SaveSystem.registry())
	SaveSystem.delete_save()
	var file := FileAccess.open(SaveSystem.save_path, FileAccess.WRITE)
	_require(file != null, "Expected test save file to open for writing.")
	file.store_string(JSON.stringify(data))
	file.close()


func _read_save() -> Dictionary:
	var file := FileAccess.open(SaveSystem.save_path, FileAccess.READ)
	_require(file != null, "Expected test save file to open for reading.")
	var parsed = StrictSaveJson.read(file.get_as_text())["data"]
	file.close()
	_require(typeof(parsed) == TYPE_DICTIONARY, "Expected saved JSON object.")
	return parsed


func _has_notice(prefix: String) -> bool:
	for notice in SaveSystem.last_gear_load_notices:
		if String(notice).begins_with(prefix):
			return true
	return false


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	assert(false, message)
