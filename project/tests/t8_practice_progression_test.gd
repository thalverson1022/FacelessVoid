extends SceneTree

var checks: Array[String] = []
var witness := {}
func _initialize() -> void:
	call_deferred("run")
func ck(value: bool, message: String) -> void:
	assert(value, message)
	checks.append(message)
func write_data(path: String, data: Dictionary) -> void:
	ck(SaveSystem.write_json(path, data), "write isolated fixture")
func snapshot(path: String) -> Dictionary:
	return StrictSaveJson.read(FileAccess.get_file_as_string(path)).data
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://prototype_saves/t8_progression")
	var s = root.get_node("BuildState")
	SaveSystem.save_path = "res://prototype_saves/t8_progression/adventure.json"
	PracticeSaveSystem.save_path = "res://prototype_saves/t8_progression/practice.json"
	var path := PracticeSaveSystem.save_path
	var practice := TrainingRoomState.new()
	practice.set_class(load("res://data/classes/rogue.tres"))
	var door: GearItem = load("res://data/gear/deaths_door.tres")
	practice.equip_legendary(door)
	ck(practice.set_legendary_missing_attempts(3), "controlled Practice accepts three missing attempts")
	practice.allocation_locked = true
	ck(not practice.set_legendary_missing_attempts(2) and practice.legendary_missing_attempts == 3, "playback guards attempt changes")
	practice.allocation_locked = false
	ck(not practice.set_legendary_missing_attempts(-1) and not practice.set_legendary_missing_attempts(100), "attempt setter rejects outside UI range")
	practice.set_slot_rarity(practice.practice_weapon, GearItem.Tier.EPIC)
	practice.practice_weapon.affixes[0].value = 17.25
	ck(PracticeSaveSystem.save_setup(practice), "version3 Practice saves: " + PracticeSaveSystem.last_error)
	var data := snapshot(path)
	ck(data.practice_version == 3 and data.setup.legendary_missing_attempts == 3, "new Practice envelope retains attempt input")
	var restored := TrainingRoomState.new()
	var bytes := FileAccess.get_file_as_bytes(path)
	ck(PracticeSaveSystem.load_setup(restored).status == "loaded", "Practice resumes")
	ck(restored.legendary_missing_attempts == 3 and restored.equipped_armor == door and restored.practice_weapon.affixes[0].value == 17.25, "Practice restores controlled input fixed armor and custom values")
	ck(bytes == FileAccess.get_file_as_bytes(path), "Practice load preserves bytes")
	var hit := Skill.new()
	hit.id = "test.practice.hit"
	hit.base_execution_ms = 300
	hit.min_execution_ms = 300
	var effect := PhysicalDamageEffect.new()
	effect.amount = 100
	hit.effects = [effect]
	var target := Monster.new()
	target.hp = 100000
	var boosted := CombatResolver.resolve([hit], restored.current_player_stats(), target, 300, 1)
	ck(restored.set_legendary_missing_attempts(0), "Practice attempts can reset")
	var plain := CombatResolver.resolve([hit], restored.current_player_stats(), target, 300, 1)
	witness["practice_damage"] = {"missing3":boosted.total_damage,"missing0":plain.total_damage}
	ck(boosted.is_valid and plain.is_valid and absf(boosted.total_damage - plain.total_damage * 6) < 6.0, "saved Practice attempts feed actual x6 Death Door damage within normal per-hit rounding")
	for version in [1,2]:
		var old := data.duplicate(true)
		old.practice_version = version
		old.setup.erase("legendary_missing_attempts")
		if version == 1: old.erase("carried_items")
		write_data(path, old)
		bytes = FileAccess.get_file_as_bytes(path)
		restored.legendary_missing_attempts = 9
		ck(PracticeSaveSystem.load_setup(restored).status == "loaded" and restored.legendary_missing_attempts == 0, "older Practice defaults attempts to0 version%d" % version)
		ck(bytes == FileAccess.get_file_as_bytes(path), "older load preserves bytes version%d" % version)
	for fault in ["missing", "negative", "float", "string", "large", "future", "wrong_slot", "fixed_custom", "ambiguous_custom"]:
		var bad := data.duplicate(true)
		match fault:
			"missing": bad.setup.erase("legendary_missing_attempts")
			"negative": bad.setup.legendary_missing_attempts = -1
			"float": bad.setup.legendary_missing_attempts = 1.5
			"string": bad.setup.legendary_missing_attempts = "3"
			"large": bad.setup.legendary_missing_attempts = 100
			"future": bad.practice_version = 99
			"wrong_slot": bad.equipment.helm = SaveSystem._gear_entry_to_data(door)
			"fixed_custom": bad.items.armor = SaveSystem._gear_entry_to_data(door)
			"ambiguous_custom": bad.equipment.weapon = {"custom":"weapon", "resource_path":"res://data/gear/decrepit_blade.tres"}
		write_data(path, bad)
		bytes = FileAccess.get_file_as_bytes(path)
		restored.legendary_missing_attempts = 7
		ck(PracticeSaveSystem.load_setup(restored).status == "failed" and restored.legendary_missing_attempts == 7 and FileAccess.get_file_as_bytes(path) == bytes, "malformed Practice atomic preservation " + fault)
	for version in [1,2,3]:
		for location in ["items","equipment"]:
			var malformed := data.duplicate(true)
			malformed.practice_version = version
			malformed[location].trinket = {"resource_path":"res://data/gear/lucky_coin.tres", "display_name":[]}
			write_data(path, malformed)
			bytes = FileAccess.get_file_as_bytes(path)
			ck(PracticeSaveSystem.load_setup(restored).status == "failed" and restored.legendary_missing_attempts == 7 and bytes == FileAccess.get_file_as_bytes(path), "canonical metadata fails atomically Practice%d %s" % [version, location])
	write_data(path, data)
	ck(PracticeSaveSystem.load_setup(restored).status == "loaded", "restore valid Practice after failures")
	var first := restored.practice_weapon.affixes[0].value
	restored.practice_weapon.affixes[0].value = 123.0
	ck(PracticeSaveSystem.load_setup(practice).status == "loaded" and practice.practice_weapon.affixes[0].value == first and practice.practice_weapon != restored.practice_weapon, "custom editor resources do not alias other restored setups")
	for item in LegendaryCatalog.all_items():
		practice.equip_legendary(item)
		ck(PracticeSaveSystem.save_setup(practice), "Practice saves actual fixed item " + item.id)
		ck(PracticeSaveSystem.load_setup(restored).status == "loaded" and restored.equipped_gear().any(func(g): return g.id == item.id), "Practice fixed item resumes " + item.id)
	# A loaded ordinary authored carried item must be mutable only in this setup.
	var ordinary_coin: GearItem = load("res://data/gear/lucky_coin.tres")
	s.inventory.assign([ordinary_coin])
	s.pending_reward_choices.assign([ordinary_coin])
	var original_slot := ordinary_coin.slot
	var original_value := ordinary_coin.affixes[0].value
	var carried := data.duplicate(true)
	carried.carried_items = [SaveSystem._gear_entry_to_data(ordinary_coin)]
	write_data(path, carried)
	ck(PracticeSaveSystem.load_setup(restored).status == "loaded", "Practice ordinary authored carried item loads")
	var loaded_coin: GearItem = restored.carried_items[0]
	ck(loaded_coin != ordinary_coin, "loaded mutable carried item is detached from canonical resource")
	restored.set_carried_slot(loaded_coin, GearItem.SlotType.HELM)
	restored.set_affix_stat(loaded_coin, 0, "crit_chance")
	loaded_coin.affixes[0].value = 0.99
	ck(ordinary_coin.slot == original_slot and ordinary_coin.affixes[0].value == original_value and s.inventory[0] == ordinary_coin and s.pending_reward_choices[0] == ordinary_coin, "carried edits preserve Adventure owned and pending canonical resources")
	# Explicit historical reset is allowed only after setup shape validation.
	var registry := BuildContentRegistry.adventure()
	registry.incompatible.append("test.incompatible")
	restored.content_registry = registry
	var incompatible := data.duplicate(true)
	incompatible.build.content_revision = "test.incompatible"
	incompatible.setup.erase("legendary_missing_attempts")
	write_data(path, incompatible)
	bytes = FileAccess.get_file_as_bytes(path)
	restored.legendary_missing_attempts = 8
	ck(PracticeSaveSystem.load_setup(restored).status == "failed" and restored.legendary_missing_attempts == 8 and bytes == FileAccess.get_file_as_bytes(path), "malformed incompatible Practice setup does not reset or overwrite")
	incompatible.setup.legendary_missing_attempts = 3
	var malformed_build := incompatible.duplicate(true)
	malformed_build.build.class_id = {}
	write_data(path, malformed_build)
	bytes = FileAccess.get_file_as_bytes(path)
	ck(PracticeSaveSystem.load_setup(restored).status == "failed" and restored.legendary_missing_attempts == 8 and bytes == FileAccess.get_file_as_bytes(path), "malformed incompatible build preserves Practice state and bytes")
	write_data(path, incompatible)
	ck(PracticeSaveSystem.load_setup(restored).status == "reset-incompatible", "valid explicitly incompatible Practice keeps prior reset policy")
	# Current Adventure retry data is saved independently of Practice.
	s.reset()
	s.set_class(load("res://data/classes/rogue.tres"))
	s.equipped_armor = door
	s.current_encounter_index = 1
	s.finish_fight(false)
	ck(SaveSystem.save_run(s), "save limited encounter first loss")
	var stats: PlayerStats = s.current_player_stats()
	var retry_result := CombatResolver.resolve([hit], stats, target, 300, 1)
	var no_attempts := stats.duplicate(true) as PlayerStats
	no_attempts.special_effects.legendary.missing_attempts = 0
	if no_attempts.derivation_base != null: no_attempts.derivation_base.special_effects.legendary.missing_attempts = 0
	var unboosted := CombatResolver.resolve([hit], no_attempts, target, 300, 1)
	ck(is_equal_approx(retry_result.total_damage, unboosted.total_damage * 2), "actual saved limited retry gives x2")
	bytes = FileAccess.get_file_as_bytes(SaveSystem.save_path)
	s.reset()
	ck(SaveSystem.load_run(s), "Adventure retry resumes")
	ck(s.failure_count_for_current_encounter() == 1 and s.attempts_remaining_for_current_encounter() == 1 and s.can_retry_current_encounter(), "retry state and remaining attempts resume")
	ck(FileAccess.get_file_as_bytes(SaveSystem.save_path) == bytes, "Adventure resume preserves bytes")
	ck(s.retry_current_encounter(), "actual retry transition succeeds")
	ck(s.encounter_retry_counts.get(s._current_fight_key()) == 1, "retry seed counter advances once")
	s.finish_fight(false)
	ck(s.run_phase == s.RunPhase.RUN_ENDED and not s.start_fight(), "terminal second loss prevents new fight")
	ck(SaveSystem.save_run(s), "terminal state saves")
	s.reset()
	ck(SaveSystem.load_run(s) and not s.start_fight(), "terminal resume cannot restart fight")
	s.reset()
	s.set_class(load("res://data/classes/rogue.tres"))
	s.equipped_armor = door
	for i in 6: s.finish_fight(false)
	ck(SaveSystem.save_run(s), "unlimited opening failures save")
	s.reset()
	ck(SaveSystem.load_run(s) and s.is_unlimited_retry_encounter() and s.attempts_remaining_for_current_encounter() == -1, "opening unlimited survives resume")
	var opening := CombatResolver.resolve([hit], s.current_player_stats(), target, 300, 1)
	ck(is_equal_approx(opening.total_damage, unboosted.total_damage), "opening Death Door remains x1 after six losses and resume")
	s.current_encounter_index = 1
	ck(s.failure_count_for_current_encounter() == 0 and s.current_player_stats().special_effects.legendary.missing_attempts == 0, "new encounter resets Death Door context")
	# Exercise saved input through actual Practice entry and refresh.
	PracticeSaveSystem.core_save_path = "res://prototype_saves/t8_progression/practice_ui.json"
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	s.gold = 631
	s.mysterious_coin_unlocked = true
	ck(SaveSystem.save_run(s), "Adventure protected snapshot before Practice entry")
	bytes = FileAccess.get_file_as_bytes(SaveSystem.save_path)
	var state_before := JSON.stringify(SaveSystem._serialize(s))
	game._current_screen.training_room_pressed.emit()
	await process_frame
	var room = game._current_screen
	room._missing_attempts_spin.value = 4
	room._state.equip_legendary(door)
	ck(PracticeSaveSystem.save_setup(room._state), "actual UI setup saves attempts and fixed armor")
	room._state.allocation_locked = true
	room._state.lock_changed.emit()
	ck(not room._missing_attempts_spin.editable, "attempt UI disabled during playback")
	room._missing_attempts_spin.value = 2
	ck(room._state.legendary_missing_attempts == 4 and room._missing_attempts_spin.value == 4, "rejected attempt edit synchronizes actual UI")
	room._state.allocation_locked = false
	room._state.lock_changed.emit()
	room._missing_attempts_spin.value = 0
	ck(PracticeSaveSystem.load_setup(room._state).status == "loaded", "actual UI state reloads")
	room._refresh_fight_setup_controls()
	ck(room._missing_attempts_spin.value == 4 and room._state.equipped_armor == door, "actual UI displays restored attempts")
	ck(JSON.stringify(SaveSystem._serialize(s)) == state_before and FileAccess.get_file_as_bytes(SaveSystem.save_path) == bytes, "Practice entry/save/reload preserves Adventure state and bytes")
	if DisplayServer.get_name() != "headless":
		await process_frame
		var ancestor: Node = room._missing_attempts_spin.get_parent()
		while ancestor != null:
			if ancestor is ScrollContainer: ancestor.ensure_control_visible(room._missing_attempts_spin)
			ancestor = ancestor.get_parent()
		await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://reports/t8_review")
		get_root().get_texture().get_image().save_png("res://reports/t8_review/practice_restore.png")
	witness["checks"] = checks
	witness["count"] = checks.size()
	witness["versions"] = {"Adventure":4,"Practice":3,"old_Practice":[1,2]}
	DirAccess.make_dir_recursive_absolute("res://reports")
	var file := FileAccess.open("res://reports/t8_practice_progression_witness.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(witness,"\t"))
	print("PASS T8 Practice/progression checks=", checks.size())
	game.queue_free()
	await process_frame
	quit()
