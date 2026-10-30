extends SceneTree
## Run only in a copied/imported project. All fixtures stay below res://reports.

var checks: Array[String] = []
var witness := {}
var signal_count := 0
const FIXTURE_DIR := "res://reports/t8_persistence_saves"

func _initialize() -> void:
	call_deferred("_run")

func ck(ok: bool, label: String) -> void:
	assert(ok, label)
	checks.append(label)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIXTURE_DIR))
	SaveSystem.save_path = FIXTURE_DIR + "/adventure.json"
	SaveSystem.session_only = false
	SaveSystem.registry_override = null
	var state = root.get_node("BuildState")
	state.build_changed.connect(_signal_seen)
	state.run_state_changed.connect(_signal_seen)
	state.lock_changed.connect(_signal_seen)
	_seed_state(state)
	var baseline := SaveSystem._serialize(state)
	var sentinel_path := FIXTURE_DIR + "/unrelated_legacy_save.json"
	ck(SaveSystem.write_json(sentinel_path, {"save_version": 1, "sentinel": "unrelated bytes survive"}), "create isolated unrelated/legacy sentinel")
	var sentinel_bytes := FileAccess.get_file_as_bytes(sentinel_path)
	var focused := OS.get_cmdline_user_args().has("--focused-boundaries")
	if not focused:
		_check_catalog_locations(state, baseline)
		_check_inline_values(state, baseline)
		_check_malformed_and_future(state, baseline)
		_check_gear_migrations(state, baseline)
	_check_transactions(state)
	_check_generated_contract_resume(state)
	_check_incompatible_preflight(state, baseline)
	_check_legacy_policies(state)
	ck(FileAccess.get_file_as_bytes(sentinel_path) == sentinel_bytes, "all persistence journeys preserve unrelated legacy sentinel bytes")
	witness["checks"] = checks
	witness["count"] = checks.size()
	witness["versions"] = [2, 3, 4]
	witness["focused_boundaries"] = focused
	witness["catalog_ids"] = LegendaryCatalog.all_paths().map(func(path): return (load(path) as GearItem).id)
	witness["limits"] = ["Copied synthetic supported-version fixtures qualify current reader; no real player userdata opened.", "Historical compatibility registry reset remains intentional; current Adventure rejects version1.", "Pinned previous-v3 reader is separately qualified by parent using retained T7 source/evidence.", "No power-loss or broad generated-route parser redesign claim."]
	var report := FileAccess.open("res://reports/t8_persistence_witness.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(witness, "\t"))
	report.close()
	SaveSystem.registry_override = null
	state.reset()
	print("PASS T8 persistence: ", checks.size())
	quit()

func _signal_seen() -> void:
	signal_count += 1

func _seed_state(state) -> void:
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	for field in ["equipped_weapon", "equipped_helm", "equipped_armor", "equipped_trinket", "equipped_charm"]:
		state.set(field, null)
	state.gold = 741
	state.adventure_seed = 812349
	state.current_encounter_index = 2
	state.contract_offer_index = 7
	state.shop_round_index = 4
	state.shop_reroll_count = 2
	state.shop_reroll_cost = 15
	state.shop_reroll_used = true
	state.shop_round_pending = true
	state.shop_unlocked = true
	state.mysterious_coin_unlocked = true
	state.encounter_failure_counts = {"tavern:2": 1}
	state.encounter_retry_counts = {"tavern:2": 1}
	state.claimed_reward_encounter_indices.assign([0, 1])
	state.claimed_route_reward_ids.assign(["prior.reward"])
	state.defeated_generated_boss_ids.assign(["prior.boss"])
	state.highest_run_dps = 71.125
	state.run_encounter_history.assign([{"fight_number": 1, "contract_count": 0, "contract_name": "Tavern", "enemy_name": "Witness", "enemy_role": "test", "enemy_color": "ffffff", "enemy_hp": 100, "duration_ms": 2000, "total_damage": 101.5, "player_dps": 50.75, "required_dps": 50.0, "dps_difference": .75, "is_win": true}])

func _equipped_field(slot: int) -> String:
	return {GearItem.SlotType.WEAPON: "equipped_weapon", GearItem.SlotType.HELM: "equipped_helm", GearItem.SlotType.ARMOR: "equipped_armor", GearItem.SlotType.TRINKET: "equipped_trinket", GearItem.SlotType.CHARM: "equipped_charm"}[slot]

func _load_fixture(state, data: Dictionary, label: String) -> void:
	ck(SaveSystem.write_json(SaveSystem.save_path, data), label + " fixture write")
	var bytes := FileAccess.get_file_as_bytes(SaveSystem.save_path)
	ck(SaveSystem.load_run_result(state).status == "loaded", label + " loaded")
	ck(FileAccess.get_file_as_bytes(SaveSystem.save_path) == bytes, label + " load preserves bytes")

func _assert_unrelated(state, source: Dictionary, label: String) -> void:
	var actual := SaveSystem._serialize(state)
	for field in ["build", "adventure_seed", "gold", "current_encounter_index", "contract_offer_index", "shop_round_index", "shop_reroll_count", "shop_reroll_cost", "shop_reroll_used", "shop_round_pending", "shop_unlocked", "encounter_failure_counts", "encounter_retry_counts", "claimed_reward_encounter_indices", "claimed_route_reward_ids", "defeated_generated_boss_ids", "highest_run_dps", "run_encounter_history"]:
		assert(actual[field] == source[field], label + " unrelated field " + field)
	ck(true, label + " unrelated build/run/economy/history fields exact")

func _check_catalog_locations(state, baseline: Dictionary) -> void:
	for version in [2, 3, 4]:
		for path in LegendaryCatalog.all_paths():
			var item: GearItem = load(path)
			for location in ["equipped", "inventory", "shop_offers", "pending_reward_choices"]:
				for encoding in ["path", "stable_id"]:
					var label := "v%d %s %s %s" % [version, item.id, location, encoding]
					var data := baseline.duplicate(true)
					data.save_version = version
					var entry: Dictionary = {"resource_path": path} if encoding == "path" else {"id": item.id}
					var field: String = _equipped_field(item.slot) if location == "equipped" else location
					data[field] = entry if location == "equipped" else [entry]
					_load_fixture(state, data, label)
					var restored: GearItem = state.get(field) if location == "equipped" else state.get(field)[0]
					ck(restored == item and restored.resource_path == path, label + " canonical fixed resource and signature")
					ck(state.mysterious_coin_unlocked, label + " run-local unlock preserved")
					_assert_unrelated(state, baseline, label)

func _runtime_item(id: String, stat_id: String, value: float) -> GearItem:
	var item := GearItem.new()
	item.id = id
	item.display_name = "Saved rolled witness"
	item.slot = GearItem.SlotType.HELM
	item.item_family = GearGenerator.rogue_item_family_for_slot(item.slot)
	item.tier = GearItem.Tier.UNIQUE
	item.source_kind = GearItem.SourceKind.GENERATED
	item.source_seed = 98431
	item.source_context = "t8.saved.roll"
	item.deterministic_key = "t8.exact.saved.roll"
	item.generation_value_scale = 1.137
	item.generation_contract_depth = 9
	item.reward_base_tier = GearItem.Tier.EPIC
	item.reward_tier_steps.assign([GearItem.Tier.EPIC, GearItem.Tier.UNIQUE])
	item.reward_magic_find_upgraded = true
	var modifier := StatModifier.new()
	modifier.stat_id = stat_id
	modifier.value = value
	modifier.category = StatModifier.StatCategory.RARE
	item.affixes.assign([modifier])
	return item

func _check_inline_values(state, baseline: Dictionary) -> void:
	for version in [2, 3, 4]:
		for stat_id in ["increased_magic_find", "cooldown_reduction", "increased_buff_duration", "crit_applies_penetration", "crit_applies_potency"]:
			var item := _runtime_item("t8." + stat_id, stat_id, .137)
			var entry: Dictionary = SaveSystem._gear_entry_to_data(item)
			for location in ["equipped_helm", "inventory", "shop_offers", "pending_reward_choices"]:
				var label := "v%d exact inline %s %s" % [version, stat_id, location]
				var data := baseline.duplicate(true)
				data.save_version = version
				data[location] = entry if location == "equipped_helm" else [entry]
				if version == 2 and stat_id != "increased_magic_find":
					_reject_fixture(state, data, label + " T3 version2 exclusion")
					continue
				_load_fixture(state, data, label)
				var restored: GearItem = state.get(location) if location == "equipped_helm" else state.get(location)[0]
				ck(SaveSystem._gear_entry_to_data(restored) == entry, label + " numeric roll and generation provenance exact")
				_assert_unrelated(state, baseline, label)
	# Inventory-economy special remains valid in modern envelopes without rerolling.
	var special := _runtime_item("t8.inventory_economy", "inventory_economy_stats", 1.0)
	special.affixes[0].category = StatModifier.StatCategory.SPECIAL
	for version in [3, 4]:
		var data := baseline.duplicate(true)
		data.save_version = version
		data.equipped_helm = SaveSystem._gear_entry_to_data(special)
		_load_fixture(state, data, "modern inventory economy special")
		ck(state.equipped_helm.affixes[0].value == 1.0, "inventory economy special exact value")

func _reject_fixture(state, data: Dictionary, label: String) -> void:
	var live := SaveSystem._serialize(state)
	var before_signals := signal_count
	ck(SaveSystem.write_json(SaveSystem.save_path, data), label + " fixture write")
	var bytes := FileAccess.get_file_as_bytes(SaveSystem.save_path)
	ck(SaveSystem.load_run_result(state).status == "failed", label + " rejected")
	ck(SaveSystem._serialize(state) == live and signal_count == before_signals, label + " live state and signals preserved")
	ck(FileAccess.get_file_as_bytes(SaveSystem.save_path) == bytes, label + " file bytes preserved")

func _check_malformed_and_future(state, baseline: Dictionary) -> void:
	for version in [2, 3, 4]:
		var data := baseline.duplicate(true)
		data.save_version = version
		data.erase("mysterious_coin_unlocked")
		_load_fixture(state, data, "v%d missing unlock" % version)
		ck(not state.mysterious_coin_unlocked, "v%d missing unlock defaults locked" % version)
		for invalid_flag in [null, 0, 1, "false", [], {}]:
			var invalid := data.duplicate(true)
			invalid.mysterious_coin_unlocked = invalid_flag
			_reject_fixture(state, invalid, "v%d malformed unlock %s" % [version, str(invalid_flag)])
		for location in ["equipped_helm", "inventory", "shop_offers", "pending_reward_choices"]:
			for bad_slot in ["1", 1.25, [], {}]:
				var invalid := data.duplicate(true)
				var entry: Dictionary = SaveSystem._gear_entry_to_data(_runtime_item("t8.slot", "increased_magic_find", .137))
				entry.slot = bad_slot
				invalid[location] = entry if location == "equipped_helm" else [entry]
				_reject_fixture(state, invalid, "v%d malformed slot %s %s" % [version, location, str(bad_slot)])
		for location in ["inventory", "shop_offers", "pending_reward_choices", "equipped_weapon"]:
			var invalid := data.duplicate(true)
			var entry := {"resource_path": {"invalid": "path"}, "id": "gear.wyvern_kriss"}
			invalid[location] = entry if location == "equipped_weapon" else [entry]
			_reject_fixture(state, invalid, "v%d malformed path %s" % [version, location])
			for encoding in ["path", "stable_id"]:
				for metadata in ["display_name", "reward_tier_steps"]:
					invalid = data.duplicate(true)
					var canonical: Dictionary = {"resource_path": "res://data/gear/wyvern_kriss.tres"} if encoding == "path" else {"id": "gear.legendary.wyvern_kriss"}
					canonical[metadata] = [] if metadata == "display_name" else {}
					invalid[location] = canonical if location == "equipped_weapon" else [canonical]
					_reject_fixture(state, invalid, "v%d %s canonical malformed %s in %s" % [version, encoding, metadata, location])
		for field in ["active_contract", "current_route_node"]:
			var invalid := data.duplicate(true)
			invalid[field] = {"invalid": "nongear path"}
			_reject_fixture(state, invalid, "v%d malformed nongear %s" % [version, field])
		var invalid_offer := data.duplicate(true)
		invalid_offer.pending_contract_offers = [{"kind": "authored", "resource_path": [1]}]
		_reject_fixture(state, invalid_offer, "v%d malformed pending contract path" % version)
		for field in ["encounter_failure_counts", "encounter_retry_counts"]:
			var invalid := data.duplicate(true)
			invalid[field] = {"fight": {"malformed": "count"}}
			_reject_fixture(state, invalid, "v%d malformed %s" % [version, field])
		var wrong_history := data.duplicate(true)
		wrong_history.run_encounter_history = [{"total_damage": {"malformed": "number"}}]
		_reject_fixture(state, wrong_history, "v%d malformed history" % version)
	for version in [-1, 0, 5, 999]:
		var data := baseline.duplicate(true)
		data.save_version = version
		_reject_fixture(state, data, "unsupported version %d" % version)
	var raw := FileAccess.open(SaveSystem.save_path, FileAccess.WRITE)
	raw.store_string("{invalid JSON")
	raw.close()
	var live := SaveSystem._serialize(state)
	var bytes := FileAccess.get_file_as_bytes(SaveSystem.save_path)
	ck(SaveSystem.load_run_result(state).status == "failed" and SaveSystem._serialize(state) == live and FileAccess.get_file_as_bytes(SaveSystem.save_path) == bytes, "invalid JSON atomic live/file preservation")

func _check_gear_migrations(state, baseline: Dictionary) -> void:
	var helm: GearItem = load("res://data/gear/helm_of_the_samurai.tres")
	var data := baseline.duplicate(true)
	data.equipped_weapon = {"resource_path": helm.resource_path}
	_load_fixture(state, data, "legacy wrong equipment field")
	ck(state.equipped_weapon == null and state.equipped_helm == helm and not SaveSystem.last_gear_load_notices.is_empty(), "valid canonical item migrates to correct existing slot with notice")
	for fault in ["slot", "tier", "source_kind"]:
		data = baseline.duplicate(true)
		var entry: Dictionary = SaveSystem._gear_entry_to_data(_runtime_item("t8.invalid_enum", "increased_magic_find", .137))
		entry[fault] = 999
		data.inventory = [entry]
		_load_fixture(state, data, "legacy invalid integer enum " + fault)
		ck(state.inventory.is_empty() and not SaveSystem.last_gear_load_notices.is_empty(), "legacy enum drop policy retained " + fault)
	data = baseline.duplicate(true)
	data.inventory = [{"resource_path": "res://data/classes/rogue.tres"}, {"resource_path": "res://deleted_gear.tres"}, {"id": "old.runtime", "slot": 0, "tier": 0, "affixes": []}]
	_load_fixture(state, data, "nongear missing and obsolete gear paths")
	ck(state.inventory.is_empty(), "nongear resources never become gear; missing/obsolete drop policy retained")

func _resume(state, label: String) -> void:
	ck(SaveSystem.save_run(state), label + " save: " + SaveSystem.last_error)
	var data := _persisted_snapshot(SaveSystem._serialize(state))
	state.reset()
	ck(SaveSystem.load_run_result(state).status == "loaded", label + " resume")
	var actual := _persisted_snapshot(SaveSystem._serialize(state))
	if actual != data:
		var differences: Array[String] = []
		_diff(data, actual, "root", differences)
		var report := FileAccess.open("res://reports/t8_resume_diff.json", FileAccess.WRITE)
		report.store_string(JSON.stringify({"label": label, "differences": differences, "before": data, "after": actual}, "\t"))
		report.close()
		print("RESUME DIFFERENCES ", JSON.stringify(differences))
	ck(actual == data, label + " exact current-version persisted snapshot")

func _persisted_snapshot(data: Dictionary) -> Dictionary:
	# Generated metadata may contain packed arrays in memory. JSON intentionally
	# stores those as ordinary arrays; compare the exact writer representation.
	var parsed := StrictSaveJson.read(JSON.stringify(data, "\t", true, true))
	assert(parsed.error == "" and typeof(parsed.data) == TYPE_DICTIONARY)
	return parsed.data

func _diff(before: Variant, after: Variant, path: String, differences: Array[String]) -> void:
	if typeof(before) == TYPE_DICTIONARY and typeof(after) == TYPE_DICTIONARY:
		for key in before:
			if not after.has(key): differences.append(path + "." + str(key) + " missing after")
			else: _diff(before[key], after[key], path + "." + str(key), differences)
		for key in after:
			if not before.has(key): differences.append(path + "." + str(key) + " added after")
	elif typeof(before) == TYPE_ARRAY and typeof(after) == TYPE_ARRAY:
		if before.size() != after.size(): differences.append("%s length %d -> %d" % [path, before.size(), after.size()])
		for i in mini(before.size(), after.size()): _diff(before[i], after[i], "%s[%d]" % [path, i], differences)
	elif before != after:
		differences.append("%s: %s -> %s" % [path, JSON.stringify(before), JSON.stringify(after)])

func _check_transactions(state) -> void:
	_seed_state(state)
	state.mysterious_coin_unlocked = false
	var ordinary_coin: GearItem = load("res://data/gear/lucky_coin.tres")
	var mystery: GearItem = load("res://data/gear/mysterious_lucky_coin.tres")
	var coil: GearItem = load("res://data/gear/serpents_coil.tres")
	ck(state.add_inventory_item(ordinary_coin), "actual Lucky Coin acquisition")
	ck(state.destroy_inventory_item(ordinary_coin) and state.mysterious_coin_unlocked and state.inventory.is_empty(), "actual destruction unlocks without immediate grant")
	state.shop_offers.assign([mystery])
	state.pending_reward_choices.assign([coil])
	state.gold = 5000
	_resume(state, "unlocked pending shop/reward offers")
	ck(state.mysterious_coin_unlocked and state.shop_offers[0] == mystery and state.pending_reward_choices.size() == 1, "resume preserves unlock and both pending offers")
	var price: int = state.shop_purchase_price_for(mystery)
	ck(state.buy_shop_offer(state.shop_offers[0]) and state.gold == 5000 - price and state.inventory.has(mystery), "actual resumed shop purchase pays once")
	ck(state.equip_from_inventory(mystery) and state.equipped_trinket == mystery, "actual purchased Legendary equip")
	ck(state.choose_pending_reward_gear(state.pending_reward_choices[0]) and state.equipped_trinket == coil and state.inventory.has(mystery), "actual resumed explicit reward equips canonical trinket slot and stores displaced Coin")
	_resume(state, "purchased and claimed Legendary state")
	ck(state.mysterious_coin_unlocked and state.shop_offers.is_empty() and state.pending_reward_choices.is_empty(), "claimed offers remain consumed after resume")
	# Loading keeps a historically pending locked offer; the actual transaction rejects it.
	state.equipped_trinket = null
	state.inventory.clear()
	state.mysterious_coin_unlocked = false
	state.shop_offers.assign([mystery])
	_resume(state, "locked historical pending offer")
	var old_gold: int = state.gold
	ck(not state.buy_shop_offer(state.shop_offers[0]) and state.gold == old_gold and state.shop_offers.size() == 1 and not state.mysterious_coin_unlocked, "resumed locked offer cannot purchase or unlock itself")
	state.reset()
	ck(not state.mysterious_coin_unlocked, "actual new-run reset locks Coin")

func _check_generated_contract_resume(state) -> void:
	_seed_state(state)
	ck(state.start_generated_contract_loop_offer(), "actual generated pending contract offers")
	var ids: Array[String] = []
	for offer in state.pending_contract_offers:
		ids.append(offer.id)
	var active_id: String = state.active_contract.id
	_resume(state, "generated pending contract and route data")
	var restored_ids: Array[String] = []
	for offer in state.pending_contract_offers:
		restored_ids.append(offer.id)
	ck(restored_ids == ids and state.active_contract.id == active_id and state.pending_contract_offer(), "generated pending offer identities/current route survive exact resume")
	ck(state.accept_contract_offer(), "resumed generated offer can actually be accepted")
	_resume(state, "accepted generated route")

func _check_legacy_policies(state) -> void:
	_seed_state(state)
	_reject_fixture(state, {"save_version": 1, "gold": 99999}, "current Adventure version1 preserves old run")
	SaveSystem.registry_override = BuildContentRegistry.current()
	ck(SaveSystem.write_json(SaveSystem.save_path, {"save_version": 1, "selected_class": "res://nonexistent.tres", "gold": 99999}), "historical registry isolated fixture")
	var result := SaveSystem.load_run_result(state)
	ck(result.status == "reset-incompatible" and result.persisted and state.gold == 0, "explicit historical registry retains version1 reset policy")
	SaveSystem.registry_override = null

func _check_incompatible_preflight(state, baseline: Dictionary) -> void:
	var compatibility := BuildContentRegistry.current()
	var old_revision := "t8.injected.incompatible.old"
	compatibility.incompatible.append(old_revision)
	SaveSystem.registry_override = compatibility
	for version in [2, 3, 4]:
		for fault in ["run_shape", "gear_path", "canonical_metadata", "build_class", "build_budget", "build_rank", "build_rotation"]:
			var invalid := baseline.duplicate(true)
			invalid.save_version = version
			invalid.build.content_revision = old_revision
			match fault:
				"run_shape": invalid.encounter_retry_counts = {"fight": {"bad": "count"}}
				"gear_path": invalid.inventory = [{"resource_path": {"bad": "path"}}]
				"canonical_metadata": invalid.inventory = [{"id": "gear.legendary.wyvern_kriss", "reward_tier_steps": {}}]
				"build_class": invalid.build.class_id = {}
				"build_budget": invalid.build.earned_talent_points = []
				"build_rank": invalid.build.talent_ranks = {"historical.talent": {}}
				"build_rotation": invalid.build.rotation_skill_ids = [[]]
			_reject_fixture(state, invalid, "v%d incompatible malformed %s preserves state/file" % [version, fault])
	# A legitimate old envelope can still reset without resolving its old build IDs.
	var legitimate := baseline.duplicate(true)
	legitimate.build.content_revision = old_revision
	legitimate.build["class_id"] = "historical.unresolvable.class"
	ck(SaveSystem.write_json(SaveSystem.save_path, legitimate), "legitimate incompatible fixture write")
	var result := SaveSystem.load_run_result(state)
	ck(result.status == "reset-incompatible" and result.persisted and state.gold == 0, "legitimate incompatible revision retains explicit reset policy")
	SaveSystem.registry_override = null
