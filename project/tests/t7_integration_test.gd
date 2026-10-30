extends SceneTree

var checks := 0
func ck(value: bool, message: String) -> void:
	assert(value, message)
	checks += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var s = root.get_node("BuildState")
	s.reset()
	s.set_class(load("res://data/classes/rogue.tres"))
	SaveSystem.save_path = "res://prototype_saves/t7_all_items.json"
	# Actual canonical fixed resources must survive the production codec.
	for item in LegendaryCatalog.all_items():
		s.inventory.assign([item])
		ck(SaveSystem.save_run(s), "save actual item " + item.id + SaveSystem.last_error)
		s.inventory.clear()
		ck(SaveSystem.load_run(s), "load actual item " + item.id)
		ck(s.inventory.size() == 1 and s.inventory[0].id == item.id and s.inventory[0].legendary_effect_id == item.legendary_effect_id, "identity/signature round trip " + item.id)
		ck(s.inventory[0].affixes.size() == item.affixes.size(), "fixed affixes round trip " + item.id)
		var actual_stats := BuildResolver.resolve_stats(s.selected_class, [], [], [s.inventory[0]])
		ck(actual_stats.special_effects.legendary.get(item.legendary_effect_id, false), "actual authored signature wiring " + item.id)
	var wyvern_stats := BuildResolver.resolve_stats(s.selected_class, [], [], [load("res://data/gear/wyvern_kriss.tres")])
	ck(is_equal_approx(wyvern_stats.poison_tick_interval_multiplier, .5), "actual Wyvern halves natural cadence")
	var bandit_item: GearItem = load("res://data/gear/bandit_blade.tres")
	var bandit_low := BuildResolver.resolve_stats(s.selected_class, [], [], [bandit_item], 9)
	var bandit_high := BuildResolver.resolve_stats(s.selected_class, [], [], [bandit_item], 100000)
	ck(is_equal_approx(bandit_high.bonus_physical_damage - bandit_low.bonus_physical_damage, 100.0), "actual Bandit stash floor and cap")
	var mf := Talent.new()
	var mf_mod := StatModifier.new()
	mf_mod.stat_id = "increased_magic_find"
	mf_mod.value = 1.5
	mf.stat_modifiers = [mf_mod]
	var coin_stats := BuildResolver.resolve_stats(s.selected_class, [], [mf], [load("res://data/gear/mysterious_lucky_coin.tres")])
	ck(is_equal_approx(coin_stats.magic_find, 3.0), "actual Coin doubles total MF150 to300")
	var ordinary := load("res://data/gear/placeholder_dagger.tres") as GearItem
	s.inventory.assign([ordinary])
	s.current_encounter_index = 1
	s.finish_fight(false)
	var stats: PlayerStats = s.current_player_stats()
	ck(stats.special_effects.legendary.missing_attempts == 1 and not stats.special_effects.legendary.get("death_door", false), "real retry context independent of armor descriptor")
	var attack := Skill.new()
	attack.id = "test.boundary"
	attack.base_execution_ms = 300
	attack.min_execution_ms = 300
	var damage := PhysicalDamageEffect.new()
	damage.amount = 100
	attack.effects = [damage]
	var target := Monster.new()
	target.hp = 100000
	var without := CombatResolver.resolve([attack], stats, target, 300, 5, true)
	s.equipped_armor = load("res://data/gear/deaths_door.tres")
	var with_door := CombatResolver.resolve([attack], s.current_player_stats(), target, 300, 5, true)
	ck(without.is_valid and with_door.is_valid and with_door.cast_events[0].physical_damage > without.cast_events[0].physical_damage, "actual encounter context reaches equipped Death Door only")
	var replay := preload("res://scripts/ui/combat_presentation_state.gd").new()
	var observation := CombatResolver.CombatResult.new()
	observation.trace.record("legendary_buff_grant", 100, {"source_id":"skill.stab"}, {"kind":"meditation", "after":{"units":2,"stacks":2,"expires_at_ms":3100,"magnitude":1.4}})
	observation.trace.record("legendary_buff_grant", 100, {"source_id":"skill.stab"}, {"kind":"dash", "after":{"units":3,"stacks":3,"expires_at_ms":3100,"magnitude":.3}})
	observation.trace.record("cooldown_started", 100, {"source_id":"skill.stab"}, {"cooldown_available_at_ms":2000})
	observation.trace.record("legendary_locket_trial", 100, {}, {"deadlines":{"skill.stab":{"before":2000,"after":1000}}})
	replay.begin(observation)
	replay.advance_to(100)
	ck(replay.active.has("legendary.meditation") and replay.active.has("legendary.dash"), "Meditation and Dash reach presentation replay")
	ck(replay.cooldowns.get("skill.stab") == 1000, "Locket reduction reaches cooldown replay")
	replay.advance_to(3100)
	ck(replay.active.is_empty(), "Legendary icons expire on deadline")
	# Full actual Practice UI routes each choice to its slot and can remove it.
	SaveSystem.session_only = true
	var scene := load("res://scenes/game_root.tscn") as PackedScene
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game._current_screen.training_room_pressed.emit()
	await process_frame
	var room = game._current_screen
	for item in LegendaryCatalog.all_items():
		var slot_name: String = GearGenerator.universal_slot_label(item.slot)
		var custom: GearItem
		match item.slot:
			GearItem.SlotType.WEAPON: custom = room._state.practice_weapon
			GearItem.SlotType.HELM: custom = room._state.practice_helm
			GearItem.SlotType.ARMOR: custom = room._state.practice_armor
			GearItem.SlotType.CHARM: custom = room._state.practice_charm
			GearItem.SlotType.TRINKET: custom = room._state.practice_trinket
		room._show_gear_slot_editor(slot_name, custom, item.slot == GearItem.SlotType.WEAPON)
		var legend_index: int = room._gear_rarity_option.get_item_index(GearItem.Tier.LEGENDARY)
		ck(legend_index >= 0, "Legendary tier accessible " + slot_name)
		room._on_editor_rarity_selected(legend_index)
		var choices: Array[GearItem] = room._legendary_items_for_editor()
		ck(choices.all(func(candidate): return candidate.slot == item.slot), "slot filtered UI " + item.id)
		room._on_weapon_legendary_selected(choices.find(item))
		ck(room._equipped_editor_item() == item, "actual UI equip " + item.id)
		room._on_editor_rarity_selected(room._gear_rarity_option.get_item_index(room.NONE_RARITY_ID))
		ck(room._equipped_editor_item() == null, "actual UI None removes " + item.id)
	room._missing_attempts_spin.value = 3
	ck(room._state.legendary_missing_attempts == 3, "user facing missing attempts input")
	# Render real final slot selector for review, not a fabricated test bench.
	room._show_gear_slot_editor("Helm", room._state.practice_helm, false)
	room._on_editor_rarity_selected(room._gear_rarity_option.get_item_index(GearItem.Tier.LEGENDARY))
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://reports/t7_review")
		get_root().get_texture().get_image().save_png("res://reports/t7_review/practice_helm.png")
	print("PASS T7 integration checks=", checks)
	game.queue_free()
	await process_frame
	quit()
