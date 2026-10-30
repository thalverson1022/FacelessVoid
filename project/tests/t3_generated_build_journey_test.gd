extends SceneTree
## Seed-searched legal drops; synthetic acquisition, not an earned Adventure run.
func _initialize() -> void:
	call_deferred("_run")

func _find(slot: int, desired: String, tier: int = GearItem.Tier.UNIQUE) -> GearItem:
	for seed_value in range(1, 2001):
		var request := {"tier": tier, "slot": slot, "source_seed": seed_value,
			"contract_depth": 12, "source_context": "t3.legal_journey",
			"id": "t3.journey.%d.%d" % [slot, seed_value]}
		var generated := GearGenerator.generate_from_request(request)
		assert(generated.ok)
		var item: GearItem = generated.item
		for modifier in item.affixes:
			if StatCatalog.canonical_id_for_modifier(modifier) == desired:
				return item
	assert(false, "No deterministic witness found for " + desired)
	return null

func _run() -> void:
	var state = root.get_node("BuildState")
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	var desired := ["inventory_economy_stats", "cooldown_reduction", "increased_buff_duration", "crit_applies_penetration", "crit_applies_potency"]
	var slots := GearItem.universal_slot_order()
	for index in slots.size():
		state.equip(_find(slots[index], desired[index]))
	state.inventory.clear() # Displaced starter is not part of this fixture.
	var carried := _find(GearItem.SlotType.WEAPON, "shop_discount", GearItem.Tier.EPIC)
	assert(state.add_inventory_item(carried))
	var stats: PlayerStats = state.current_player_stats()
	assert(stats.derivation_error == "")
	assert(stats.cooldown_factor < 1 and stats.increased_buff_duration > 0)
	assert(stats.crit_applies_penetration > 0 and stats.crit_applies_potency > 0 and stats.shop_discount > 0)
	var source_ledger: StatSheet = BuildResolver.resolve_gear_stat_sheet(state.equipped_gear(), state.inventory)
	assert(not source_ledger.cooldown_contributions.is_empty())
	var source_found := false
	for source in source_ledger.contribution_sources:
		if source.source_kind == "carried" and source.stat_id == "shop_discount":
			source_found = true
	assert(source_found)
	var macro: Array[Skill] = [load("res://data/skills/stab.tres")]
	var target := Monster.new()
	var fight := CombatResolver.resolve(macro, stats, target, 30000, 42, true)
	assert(fight.is_valid and fight.cast_events.size() > 0)
	assert(SaveSystem.save_run(state), SaveSystem.last_error)
	var saved := SaveSystem._serialize(state)
	state.reset()
	assert(SaveSystem.load_run_result(state).status == "loaded")
	assert(SaveSystem._serialize(state) == saved, "All generated metadata and saved rolls round-trip exactly.")
	var restored: PlayerStats = state.current_player_stats()
	var replay := CombatResolver.resolve(macro, restored, target, 30000, 42, true)
	assert(replay.is_valid and fight.total_damage == replay.total_damage and fight.rng_final_state == replay.rng_final_state)
	var presentation: Array = []
	for gear in state.equipped_gear():
		var lines := CardStyle.gear_tooltip_lines(gear)
		assert(not lines.is_empty())
		presentation.append({"item": gear.id, "lines": Array(lines)})
	assert(SaveSystem.write_json("res://reports/generated_build_journey.json", {
		"scope": "Legal generated items with seed-searched synthetic acquisition; no earned progression claim",
		"equipment": saved, "cooldown_factor": restored.cooldown_factor,
		"duration_increase": restored.increased_buff_duration,
		"crit_penetration": restored.crit_applies_penetration, "crit_potency": restored.crit_applies_potency,
		"source_ledger": source_ledger.contribution_sources, "cooldown_ledger": source_ledger.cooldown_contributions,
		"tooltip_lines": presentation, "fight_casts": fight.cast_events.size(), "fight_damage": fight.total_damage,
		"reloaded_damage": replay.total_damage, "deterministic_reload": true
	}))
	state.reset()
	print("T3 generated build journey: PASS")
	quit()
