extends SceneTree
## Combined final-content gaps. T5 reset/entry and T8 mechanics/presentation
## remain the authorities for their directed failure and payout edge cases.
var checks: Array[String] = []
var signals_seen := 0
var owned: Dictionary
const TIERS := [GearItem.Tier.BASIC, GearItem.Tier.MASTER, GearItem.Tier.EPIC,
	GearItem.Tier.CURSED, GearItem.Tier.CHAOS, GearItem.Tier.UNIQUE]

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	assert(ok, label)
	checks.append(label)
func erase(path: String) -> void:
	if FileAccess.file_exists(path):
		assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
func clear_owned() -> void:
	for path in owned.values():
		erase(path)
		erase(path + ".tmp")
func old_files() -> void:
	clear_owned()
	for kind in ["adventure", "practice", "core", "legacy"]:
		var data := {"save_version": 4} if kind in ["adventure", "legacy"] else {"practice_version": 3}
		check(SaveSystem.write_json(owned[kind], data), "old " + kind)
		check(SaveSystem.write_json(owned[kind] + ".tmp", data), "old temp " + kind)
func reset_proof() -> void:
	for kind in ["adventure", "practice", "core", "legacy"]:
		check(not FileAccess.file_exists(owned[kind]) and not FileAccess.file_exists(owned[kind] + ".tmp"), "normal entry retired " + kind)
	check(StrictSaveJson.read(FileAccess.get_file_as_string(owned.marker)).data == {"seven_slot_epoch": 1}, "normal entry epoch1 marker")
func normalized(value: Variant) -> Variant:
	var result := StrictSaveJson.read(JSON.stringify(value, "", true, true))
	assert(result.error == "")
	return result.data
func value_snapshot(value: Variant) -> Variant:
	if value is Resource:
		var fields := {}
		for property in value.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_STORAGE:
				fields[property.name] = value_snapshot(value.get(property.name))
		return fields
	if value is Dictionary:
		var fields := {}
		for key in value: fields[key] = value_snapshot(value[key])
		return fields
	if value is Array:
		return value.map(value_snapshot)
	return value
func stat_snapshot(state) -> Dictionary:
	var stats: PlayerStats = state.current_player_stats()
	check(stats.derivation_error == "", "valid derived stats")
	var result := {}
	for property in stats.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_STORAGE:
			result[property.name] = value_snapshot(stats.get(property.name))
	return normalized(result)
func seed_adventure(state) -> void:
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	check(state.configure_ranked_build(BuildContentRegistry.adventure().trees["tree.bladedancer"]), "legal ranked Adventure build")
	state.gold = 741
	state.adventure_seed = 812349
	state.shop_round_index = 4
	state.shop_reroll_count = 2
	state.shop_reroll_cost = 15
	state.shop_round_pending = true
	state.mysterious_coin_unlocked = true
	state.encounter_failure_counts = {"tavern:0": 2}
	state.encounter_retry_counts = {"tavern:0": 1}
func field_for(slot: int, prefix := "equipped_") -> String:
	return prefix + GearItem.SlotType.keys()[slot].to_lower()
func generated(slot: int, tier: int) -> GearItem:
	var key := "m9.t9.%d.%d" % [slot, tier]
	var result := GearGenerator.generate_from_request({"slot": slot, "tier": tier,
		"id": key, "deterministic_key": key, "source_context": "m9_t9_saved_roll",
		"source_seed": 94831 + slot + tier * 10, "value_scale": 1.137, "contract_depth": 9})
	check(result.ok, "generated legal " + key)
	var item: GearItem = result.item
	item.reward_base_tier = GearItem.Tier.BASIC
	item.reward_tier_steps.assign([GearItem.Tier.BASIC, tier])
	item.reward_magic_find_upgraded = true
	return item
func adventure_resume(state, label: String) -> void:
	var before: Dictionary = normalized(SaveSystem._serialize(state))
	var stats := stat_snapshot(state)
	check(SaveSystem.save_run(state), label + " write: " + SaveSystem.last_error)
	var bytes := FileAccess.get_file_as_bytes(owned.adventure)
	state.reset()
	check(SaveSystem.load_run_result(state).status == "loaded", label + " load")
	check(normalized(SaveSystem._serialize(state)) == before, label + " exact build/run/gear/provenance snapshot")
	var after_stats := stat_snapshot(state)
	check(after_stats == stats, label + " exact derived scalar/special stats")
	check(FileAccess.get_file_as_bytes(owned.adventure) == bytes, label + " load preserves bytes")
func room_state() -> TrainingRoomState:
	var room := TrainingRoomState.new()
	room.content_registry = BuildContentRegistry.test_mode()
	room.set_class(load("res://data/classes/rogue.tres"))
	check(room.configure_ranked_build(room.content_registry.trees["tree.bladedancer"]), "legal ranked Practice build")
	return room
func practice_snapshot(room: TrainingRoomState) -> Dictionary:
	var result := {"build": BuildSaveCodec.encode(room, room.content_registry), "gold": room.configured_gold,
		"target": room.target_defense_snapshot(), "items": {}, "equipment": {},
		"carried": SaveSystem._gear_list_to_data(room.carried_items), "setup": {}}
	for name in PracticeSaveSystem.ITEMS:
		result.items[name] = SaveSystem._gear_entry_to_data(room.get("practice_" + name))
		result.equipment[name] = SaveSystem._gear_entry_to_data(room.get("equipped_" + name))
	for name in PracticeSaveSystem.SETUP_FIELDS: result.setup[name] = room.get(name)
	return normalized(result)
func practice_resume(room: TrainingRoomState, label: String) -> TrainingRoomState:
	var before := practice_snapshot(room)
	var stats := stat_snapshot(room)
	check(PracticeSaveSystem.save_setup(room, true), label + " write: " + PracticeSaveSystem.last_error)
	var bytes := FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path)
	var restored := TrainingRoomState.new()
	restored.content_registry = room.content_registry
	check(PracticeSaveSystem.load_setup(restored).status == "loaded", label + " load")
	check(practice_snapshot(restored) == before, label + " exact build/target/setup/gear/provenance snapshot")
	check(stat_snapshot(restored) == stats, label + " exact derived scalar/special stats")
	check(FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path) == bytes, label + " load preserves bytes")
	return restored
func run() -> void:
	owned = SevenSlotSaveBoundary.paths()
	# This must return from the driver, not only assert inside check(): a direct
	# invocation without the isolated wrapper must never reach fixture cleanup.
	if owned.size() != 5:
		push_error("M9 T9 requires all five isolated save paths before entry.")
		quit(1)
		return
	for path in owned.values():
		if not String(path).begins_with("res://reports/"):
			push_error("M9 T9 refuses a save path outside isolated reports.")
			quit(1)
			return
	check(owned.size() == 5, "all five paths installed before entry")
	for path in owned.values(): check(String(path).begins_with("res://reports/"), "isolated fixture path")
	var state = root.get_node("BuildState")
	state.reset()
	SaveSystem.session_only = false
	await normal_entries(state)
	clear_owned()
	check(SevenSlotSaveBoundary.ensure_ready(), "empty isolated epoch")
	catalog_roundtrips(state)
	generated_roundtrips(state)
	custom_roundtrips()
	atomic_failures(state)
	marker_and_memory_gaps(state)
	state.reset()
	var output := {"checks": checks, "count": checks.size(), "versions": [SaveSystem.SAVE_VERSION, PracticeSaveSystem.SAVE_VERSION],
		"catalog_ids": LegendaryCatalog.all_items().map(func(item): return item.id),
		"scope": "Final20 all four Adventure locations; seven slots/six procedural tiers; seven custom shells; normal Title and Practice reset entry; detached mutable values and failed-load signals/state/bytes."}
	check(SaveSystem.write_json("res://reports/m9_t9_persistence_witness.json", output), "write witness")
	print("M9 T9 persistence PASS (%d checks)" % checks.size())
	quit()
func normal_entries(state) -> void:
	old_files()
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	reset_proof()
	game._on_new_game_pressed(92468)
	await process_frame
	state.set_class(load("res://data/classes/rogue.tres"))
	check(state.equipped_gear().size() == 1 and state.equipped_weapon.id == "gear.crude_dagger", "actual Title new Adventure Crude only")
	check(state.equipped_legs == null and state.equipped_hands == null, "actual Title new slots empty")
	for slot in GearItem.universal_slot_order(): state.set(field_for(slot), generated(slot, GearItem.Tier.MASTER))
	adventure_resume(state, "post-reset full7 Adventure")
	game.queue_free()
	await process_frame
	state.reset()
	old_files()
	# Practice's actual normal-entry scene is allowed to be first persistence use.
	var screen = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	reset_proof()
	check(screen._state.equipped_gear().is_empty(), "actual Practice first entry empty")
	for slot in GearItem.universal_slot_order():
		var item := generated(slot, GearItem.Tier.MASTER)
		screen._state.set(field_for(slot), item)
	check(PracticeSaveSystem.save_setup(screen._state), "actual Practice core full7 save")
	var restored := room_state()
	restored.practice_save_path = PracticeSaveSystem.core_save_path
	check(PracticeSaveSystem.load_setup(restored).status == "loaded" and restored.equipped_gear().size() == 7, "actual Practice core full7 reload")
	screen.queue_free()
	await process_frame
	# Losing a marker cannot retire newly saved epoch data.
	seed_adventure(state)
	for slot in GearItem.universal_slot_order(): state.set(field_for(slot), generated(slot, GearItem.Tier.EPIC))
	check(SaveSystem.save_run(state), "new content save before marker loss")
	var adv := FileAccess.get_file_as_bytes(owned.adventure)
	var core := FileAccess.get_file_as_bytes(owned.core)
	erase(owned.marker)
	check(SevenSlotSaveBoundary.ensure_ready() and SevenSlotSaveBoundary.last_reset_count == 0, "marker loss retains current full7 content")
	check(FileAccess.get_file_as_bytes(owned.adventure) == adv and FileAccess.get_file_as_bytes(owned.core) == core, "current Adventure/core bytes preserved")
	check(SevenSlotSaveBoundary.ensure_ready() and SevenSlotSaveBoundary.last_reset_count == 0, "repeat epoch guard idempotent")
func catalog_roundtrips(state) -> void:
	var catalog := LegendaryCatalog.all_items()
	check(catalog.size() == 20, "final20 Legendary catalog")
	for fixed in catalog:
		seed_adventure(state)
		state.set(field_for(fixed.slot), fixed)
		state.inventory.assign([fixed])
		state.shop_offers.assign([fixed])
		state.pending_reward_choices.assign([fixed])
		adventure_resume(state, fixed.id)
		check(state.get(field_for(fixed.slot)) == fixed and state.inventory[0] == fixed and state.shop_offers[0] == fixed and state.pending_reward_choices[0] == fixed, fixed.id + " all4 canonical identities")
		var room := room_state()
		room.set(field_for(fixed.slot), fixed)
		room.carried_items.assign([fixed])
		var restored := practice_resume(room, fixed.id)
		check(restored.get(field_for(fixed.slot)) == fixed and restored.carried_items[0] == fixed, fixed.id + " Practice canonical equipped/carried")
func generated_roundtrips(state) -> void:
	for tier in TIERS:
		for slot in GearItem.universal_slot_order():
			var item := generated(slot, tier)
			var entry: Dictionary = SaveSystem._gear_entry_to_data(item)
			seed_adventure(state)
			state.set(field_for(slot), item)
			state.inventory.assign([item])
			state.shop_offers.assign([item])
			state.pending_reward_choices.assign([item])
			adventure_resume(state, item.id)
			for restored in [state.get(field_for(slot)), state.inventory[0], state.shop_offers[0], state.pending_reward_choices[0]]:
				check(normalized(SaveSystem._gear_entry_to_data(restored)) == normalized(entry), item.id + " affix values/categories/operations/flags and provenance exact")
				check(restored != item and restored.affixes[0] != item.affixes[0], item.id + " mutable resources detached")
			check(state.get(field_for(slot)) != state.inventory[0] and state.inventory[0] != state.shop_offers[0] and state.shop_offers[0] != state.pending_reward_choices[0], item.id + " persisted occurrences detached")
			var room := room_state()
			room.set(field_for(slot), item)
			room.carried_items.assign([item])
			var restored := practice_resume(room, item.id)
			check(restored.get(field_for(slot)) != item and restored.carried_items[0] != item and restored.carried_items[0] != restored.get(field_for(slot)), item.id + " Practice mutable resources detached")
func custom_roundtrips() -> void:
	var room := room_state()
	for slot in GearItem.universal_slot_order():
		var custom: GearItem = room.get(field_for(slot, "practice_"))
		custom.affixes = generated(slot, GearItem.Tier.MASTER).affixes
		custom.source_context = "m9_t9_custom"
		custom.source_seed = 123456 + slot
		room.set(field_for(slot), custom)
	room.configured_gold = 987
	room.gold = 987
	room.duration_ms = 23456
	room.fight_seed = 8675309
	room.legendary_missing_attempts = 37
	room.selected_target.armor = 123
	room.selected_target.poison_resistance = .137
	room.selected_target.hp = 98765
	var restored := practice_resume(room, "full7 custom Practice")
	check(restored.equipped_gear().size() == 7 and restored.selected_target.hp == 98765, "seven custom slots and target HP restored")
	for slot in GearItem.universal_slot_order():
		var original: GearItem = room.get(field_for(slot, "practice_"))
		var custom: GearItem = restored.get(field_for(slot, "practice_"))
		check(restored.get(field_for(slot)) == custom and custom != original and custom.affixes[0] != original.affixes[0], "custom slot own-shell link and detached resources %d" % slot)
		var value := original.affixes[0].value
		custom.affixes[0].value += .001
		check(original.affixes[0].value == value, "custom mutation independent %d" % slot)
func atomic_failures(state) -> void:
	seed_adventure(state)
	for slot in GearItem.universal_slot_order(): state.set(field_for(slot), generated(slot, GearItem.Tier.MASTER))
	check(SaveSystem.save_run(state), "atomic baseline write")
	var data := normalized(SaveSystem._serialize(state)) as Dictionary
	state.build_changed.connect(func(): signals_seen += 1)
	state.run_state_changed.connect(func(): signals_seen += 1)
	state.lock_changed.connect(func(): signals_seen += 1)
	for location in ["equipped_legs", "equipped_hands", "inventory", "shop_offers", "pending_reward_choices"]:
		var invalid := data.duplicate(true)
		var item: Dictionary = invalid.equipped_hands.duplicate(true)
		item.affixes[0].stat_id = "unknown.m9.t9.stat"
		invalid[location] = item if location.begins_with("equipped_") else [item]
		check(SaveSystem.write_json(owned.adventure, invalid), "malformed fixture " + location)
		var bytes := FileAccess.get_file_as_bytes(owned.adventure)
		var before_signals := signals_seen
		check(SaveSystem.load_run_result(state).status == "failed", "malformed rejected " + location)
		check(normalized(SaveSystem._serialize(state)) == data and signals_seen == before_signals, "failed load no state/signals " + location)
		check(FileAccess.get_file_as_bytes(owned.adventure) == bytes, "failed load bytes preserved " + location)
	check(SaveSystem.write_json(owned.adventure, data), "restore atomic fixture")
	var valid_bytes := FileAccess.get_file_as_bytes(owned.adventure)
	state.equipped_hands.affixes[0].stat_id = "unknown.m9.t9.stat"
	check(not SaveSystem.save_run(state) and FileAccess.get_file_as_bytes(owned.adventure) == valid_bytes, "invalid live writer preserves prior full7 save")
	var room := room_state()
	for slot in GearItem.universal_slot_order(): room.set(field_for(slot), generated(slot, GearItem.Tier.MASTER))
	var loaded := practice_resume(room, "Practice atomic baseline")
	var practice_data: Dictionary = StrictSaveJson.read(FileAccess.get_file_as_string(PracticeSaveSystem.save_path)).data
	var before := practice_snapshot(loaded)
	for location in ["items", "equipment", "carried_items"]:
		var invalid := practice_data.duplicate(true)
		if location == "carried_items": invalid.carried_items = [invalid.equipment.hands.duplicate(true)]
		var entry: Dictionary = invalid.carried_items[0] if location == "carried_items" else invalid[location].hands
		if entry.affixes.is_empty(): entry.affixes = invalid.equipment.hands.affixes.duplicate(true)
		entry.affixes[0].stat_id = "unknown.m9.t9.stat"
		check(SaveSystem.write_json(PracticeSaveSystem.save_path, invalid), "Practice invalid " + location)
		var bytes := FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path)
		check(PracticeSaveSystem.load_setup(loaded).status == "failed" and practice_snapshot(loaded) == before, "Practice invalid load atomic " + location)
		check(FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path) == bytes, "Practice invalid bytes preserved " + location)
func file_snapshot() -> Dictionary:
	var result := {}
	for path in owned.values():
		for candidate in [path, path + ".tmp"]:
			result[candidate] = FileAccess.get_file_as_bytes(candidate) if FileAccess.file_exists(candidate) else null
	return result
func marker_and_memory_gaps(state) -> void:
	old_files()
	seed_adventure(state)
	for slot in GearItem.universal_slot_order(): state.set(field_for(slot), generated(slot, GearItem.Tier.MASTER))
	var live: Dictionary = normalized(SaveSystem._serialize(state))
	var room := room_state()
	for marker in [{"seven_slot_epoch": 2}, {"seven_slot_epoch": "1"}, {"seven_slot_epoch": 1.0},
		{"seven_slot_epoch": true}, {"seven_slot_epoch": null}, {"seven_slot_epoch": []}, {"seven_slot_epoch": {}}, {}]:
		check(SaveSystem.write_json(owned.marker, marker), "invalid marker fixture")
		var files := file_snapshot()
		var before_signals := signals_seen
		check(not SevenSlotSaveBoundary.ensure_ready(), "invalid marker blocks reset")
		check(SevenSlotSaveBoundary.last_error.contains("Invalid seven-slot reset marker"), "invalid marker reports recoverable error")
		check(SaveSystem.load_run_result(state).status == "failed" and not SaveSystem.save_run(state), "invalid marker blocks Adventure read/write")
		check(PracticeSaveSystem.load_setup(room).status == "failed" and not PracticeSaveSystem.save_setup(room), "invalid marker blocks Practice read/write")
		check(file_snapshot() == files and normalized(SaveSystem._serialize(state)) == live and signals_seen == before_signals, "invalid marker preserves all files/live/signals")
	erase(owned.marker)
	var raw := FileAccess.open(owned.marker, FileAccess.WRITE)
	raw.store_string("{broken")
	raw.close()
	var malformed_files := file_snapshot()
	check(not SevenSlotSaveBoundary.ensure_ready() and file_snapshot() == malformed_files, "malformed JSON marker preserves all files")
	erase(owned.marker)
	var files := file_snapshot()
	SaveSystem.session_only = true
	check(state.equipped_gear().size() == 7, "memory Test fixture full7")
	check(not SaveSystem.has_save() and not SaveSystem.has_saved_file(), "memory Test advertises no persistence")
	check(SaveSystem.save_run(state) and SaveSystem.delete_save(), "memory Test Adventure write/delete bypass")
	check(SaveSystem.load_run_result(state).status == "failed", "memory Test read blocked")
	check(PracticeSaveSystem.save_setup(room) and PracticeSaveSystem.load_setup(room).status == "failed", "memory Test Practice bypass")
	check(SevenSlotSaveBoundary.ensure_ready() and file_snapshot() == files, "memory Test preserves every old path/temp plus absent marker")
	SaveSystem.session_only = false
	check(SevenSlotSaveBoundary.ensure_ready(), "normal entry resumes isolated reset after Test")
	reset_proof()
