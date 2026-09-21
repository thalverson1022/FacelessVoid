extends Node
## Shared in-progress build state for the P2:M3 Build Planner screens.
## Holds only data + signals per docs/Conventions.md's UI architecture
## principle -- screens read/write this instead of holding game state
## themselves.

signal build_changed
signal lock_changed
signal run_state_changed
signal stats_preview_changed

enum RunPhase {
	PLANNING,
	FIGHTING,
	RESULT,
	CONTRACT_OFFER,
	CONTRACT_ROUTE,
	RUN_ENDED,
}

enum RunOutcome {
	NONE,
	FIGHT_WIN,
	FIGHT_LOSS_RETRY,
	ADVENTURE_RESTART_REQUIRED,
	CONTRACT_FAILED,
	CONTRACT_VICTORY,
	ALL_BOSSES_DEFEATED,
}

const INVENTORY_CAPACITY := 3
const TALENT_POINT_CAP := 10
const SELL_VALUE_RATIO := 0.5
const DEFAULT_ADVENTURE_SEED := 1
const RunRngSystem = preload("res://scripts/systems/run_rng.gd")
const ContractOfferSourceScript = preload("res://scripts/systems/contract_offer_source.gd")
const StatCatalog := preload("res://scripts/systems/stat_catalog.gd")
const STARTER_DAGGER_PATH := "res://data/gear/crude_dagger.tres"
const SHOP_REROLL_INITIAL_COST := 5
const SHOP_REROLL_COST_STEP := 5
const OVERKILL_GOLD_DAMAGE_STEP := 100.0
const OVERKILL_GOLD_PER_STEP := 10
const OVERKILL_GOLD_CAP := 50

var selected_class: ClassDef = null
var selected_trees: Array[SubclassTree] = []
var selected_talents: Array[Talent] = []
var rotation: Array[Skill] = []
var adventure_seed: int = DEFAULT_ADVENTURE_SEED
var gold: int = 0
var combat_stolen_gold: int = 0
var earned_talent_points: int = 0
var inventory: Array[GearItem] = []
var claimed_reward_encounter_indices: Array[int] = []
var shop_unlocked: bool = false
var shop_round_pending: bool = false
var shop_reroll_used: bool = false
var shop_reroll_count: int = 0
var shop_reroll_cost: int = SHOP_REROLL_INITIAL_COST
var shop_round_index: int = 0
var shop_offers: Array[GearItem] = []
const SHOP_OFFER_COUNT := 6
const CONTRACT_SHOP_RARITY_CURVE := [
	{
		"depth": 1,
		"weights": {
			GearItem.Tier.BASIC: 65,
			GearItem.Tier.MASTER: 23,
			GearItem.Tier.EPIC: 6,
			GearItem.Tier.CURSED: 2,
			GearItem.Tier.CHAOS: 3,
			GearItem.Tier.UNIQUE: 1,
			GearItem.Tier.LEGENDARY: 1,
		},
	},
	{
		"depth": 6,
		"weights": {
			GearItem.Tier.BASIC: 54,
			GearItem.Tier.MASTER: 26,
			GearItem.Tier.EPIC: 10,
			GearItem.Tier.CURSED: 4,
			GearItem.Tier.CHAOS: 4,
			GearItem.Tier.UNIQUE: 2,
			GearItem.Tier.LEGENDARY: 2,
		},
	},
	{
		"depth": 12,
		"weights": {
			GearItem.Tier.BASIC: 41,
			GearItem.Tier.MASTER: 29,
			GearItem.Tier.EPIC: 15,
			GearItem.Tier.CURSED: 7,
			GearItem.Tier.CHAOS: 5,
			GearItem.Tier.UNIQUE: 3,
			GearItem.Tier.LEGENDARY: 3,
		},
	},
]
const SHOP_ROLL_TIERS: Array[GearItem.Tier] = [
	GearItem.Tier.BASIC,
	GearItem.Tier.MASTER,
	GearItem.Tier.EPIC,
	GearItem.Tier.CURSED,
	GearItem.Tier.CHAOS,
	GearItem.Tier.UNIQUE,
	GearItem.Tier.LEGENDARY,
]
const SHOP_UNIQUE_ROLL_ATTEMPTS := 80
const STANDARD_MAX_ATTEMPTS := 2
const REWARD_UPGRADE_BASIC_TO_MASTER_BP := 1500
const REWARD_UPGRADE_MASTER_TO_EPIC_BP := 800
const REWARD_UPGRADE_EPIC_TO_HIGH_TIER_BP := 300
const REWARD_HIGH_TIER_CURSED_BP := 5000
const REWARD_HIGH_TIER_CHAOS_BP := 3000
const REWARD_HIGH_TIER_UNIQUE_BP := 2000
const REWARD_UPGRADE_BP_DENOMINATOR := 10000
const REWARD_UPGRADE_MIN_CONTRACT_DEPTH := 1
const REWARD_UPGRADE_MAX_CONTRACT_DEPTH := 12
const REWARD_UPGRADE_MAX_RELATIVE_DEPTH_BONUS := 0.5
var pending_reward_choices: Array[GearItem] = []
var equipped_weapon: GearItem = null
var equipped_helm: GearItem = null
var equipped_armor: GearItem = null
var equipped_trinket: GearItem = null
var equipped_charm: GearItem = null
var pending_contract_offers: Array[ContractDef] = []
var active_contract: ContractDef = null
var current_route_node: ContractRouteNode = null
var claimed_route_reward_ids: Array[String] = []
var completed_contract_count: int = 0
var highest_run_dps: float = 0.0
var run_encounter_history: Array[Dictionary] = []
var contract_offer_index: int = 0
var defeated_generated_boss_ids: Array[String] = []
var current_encounter_index: int = 0
var encounter_failure_counts: Dictionary = {}
var encounter_retry_counts: Dictionary = {}
var run_phase: int = RunPhase.PLANNING
var run_outcome: int = RunOutcome.NONE
var last_fight_won: bool = false
var last_combat_result: CombatResolver.CombatResult = null
var tavern_map_choice_made: bool = false
## Build lock flag: locking the build enables the FIGHT button. Any build
## mutation (talents, macro, gear, ...) automatically clears it, since the
## lock refers to the build as it was when locked -- see _ready().
var build_locked: bool = false


func _ready() -> void:
	build_changed.connect(_clear_lock_on_change)


func _clear_lock_on_change() -> void:
	if build_locked:
		build_locked = false
		lock_changed.emit()


func set_locked(locked: bool) -> void:
	if locked and rotation.is_empty():
		locked = false
	if build_locked == locked:
		return
	build_locked = locked
	lock_changed.emit()


func reset(preserve_adventure_seed: bool = false) -> void:
	var kept_seed := adventure_seed
	selected_class = null
	selected_trees = []
	selected_talents = []
	rotation = []
	adventure_seed = kept_seed if preserve_adventure_seed else DEFAULT_ADVENTURE_SEED
	gold = 0
	combat_stolen_gold = 0
	earned_talent_points = 0
	inventory = []
	claimed_reward_encounter_indices = []
	shop_unlocked = false
	shop_round_pending = false
	shop_reroll_used = false
	shop_reroll_count = 0
	shop_reroll_cost = SHOP_REROLL_INITIAL_COST
	shop_round_index = 0
	shop_offers = []
	pending_reward_choices = []
	equipped_weapon = null
	equipped_helm = null
	equipped_armor = null
	equipped_trinket = null
	equipped_charm = null
	pending_contract_offers = []
	active_contract = null
	current_route_node = null
	claimed_route_reward_ids = []
	completed_contract_count = 0
	highest_run_dps = 0.0
	run_encounter_history = []
	contract_offer_index = 0
	defeated_generated_boss_ids = []
	current_encounter_index = 0
	encounter_failure_counts = {}
	encounter_retry_counts = {}
	run_phase = RunPhase.PLANNING
	run_outcome = RunOutcome.NONE
	last_fight_won = false
	last_combat_result = null
	tavern_map_choice_made = false
	build_changed.emit()
	run_state_changed.emit()


func set_adventure_seed(seed: int) -> void:
	adventure_seed = max(0, seed)
	run_state_changed.emit()


func current_encounter() -> Encounter:
	return RunFlow.load_encounter(current_encounter_index)


func is_contract_fight_active() -> bool:
	return (
		active_contract != null
		and current_route_node != null
		and current_route_node.monster != null
		and (
			run_phase == RunPhase.PLANNING
			or run_phase == RunPhase.FIGHTING
			or run_phase == RunPhase.RESULT
		)
	)


func current_target_monster() -> Monster:
	if is_contract_fight_active():
		return current_route_node.monster
	var encounter := current_encounter()
	return encounter.monster if encounter != null else null


func current_target_duration_ms() -> int:
	if is_contract_fight_active():
		return current_route_node.duration_ms
	var encounter := current_encounter()
	return encounter.duration_ms if encounter != null else 0


func current_reward() -> EncounterReward:
	if is_contract_fight_active():
		return current_route_node.reward
	var encounter := current_encounter()
	return encounter.reward if encounter != null else null


func current_fight_label() -> String:
	if is_contract_fight_active():
		return current_route_node.display_name
	var encounter := current_encounter()
	return encounter.monster.display_name if encounter != null and encounter.monster != null else ""


func current_combat_rng_seed() -> int:
	var fight_key := _current_fight_key()
	return RunRngSystem.seed_for_context(adventure_seed, RunRngSystem.CONTEXT_COMBAT, [fight_key, int(encounter_retry_counts.get(fight_key, 0))])


func can_start_current_fight() -> bool:
	return (
		build_locked
		and not rotation.is_empty()
		and run_phase == RunPhase.PLANNING
		and current_target_monster() != null
		and current_target_duration_ms() > 0
		and not needs_tavern_map_choice()
	)


func is_tavern_planning() -> bool:
	return (
		run_phase == RunPhase.PLANNING
		and not is_contract_fight_active()
		and current_encounter_index < RunFlow.tavern_encounter_count()
	)


func needs_tavern_map_choice() -> bool:
	return is_tavern_planning() and not tavern_map_choice_made


func choose_current_tavern_encounter() -> bool:
	if not is_tavern_planning():
		return false
	tavern_map_choice_made = true
	run_state_changed.emit()
	return true


func pending_contract_offer() -> bool:
	return (
		run_phase == RunPhase.CONTRACT_OFFER
		and active_contract != null
		and current_route_node != null
		and not pending_contract_offers.is_empty()
	)


func start_contract_offer(context: Dictionary = {}) -> bool:
	var offer_context := context.duplicate(true)
	if offer_context.is_empty():
		offer_context = ContractOfferSourceScript.offer_context(
			adventure_seed,
			contract_offer_index,
			completed_contract_count
		)
	if not offer_context.has("earned_talent_points"):
		offer_context["earned_talent_points"] = earned_talent_points
	var defeated_value: Variant = offer_context.get("defeated_generated_boss_ids", [])
	if not offer_context.has("defeated_generated_boss_ids") or (typeof(defeated_value) == TYPE_ARRAY and defeated_value.is_empty()):
		offer_context["defeated_generated_boss_ids"] = defeated_generated_boss_ids.duplicate()
	var offers: Array[ContractDef] = ContractOfferSourceScript.contract_offers(offer_context)
	var contract: ContractDef = offers[0] if not offers.is_empty() else null
	if contract == null or contract.offer_node == null:
		return false
	contract_offer_index = int(offer_context.get("contract_offer_index", contract_offer_index))
	completed_contract_count = int(offer_context.get("completed_contract_count", completed_contract_count))
	pending_contract_offers = offers
	active_contract = contract
	current_route_node = contract.offer_node
	run_phase = RunPhase.CONTRACT_OFFER
	run_outcome = RunOutcome.NONE
	last_fight_won = false
	tavern_map_choice_made = false
	set_locked(false)
	run_state_changed.emit()
	return true


func start_generated_contract_loop_offer(settings: Dictionary = {}, generated_offer_count: int = 3) -> bool:
	return start_contract_offer(ContractOfferSourceScript.offer_context(
		adventure_seed,
		contract_offer_index,
		completed_contract_count,
		-1,
		settings,
		false,
		true,
		generated_offer_count
	))


func select_pending_contract_offer(contract_id: String) -> bool:
	if not pending_contract_offer():
		return false
	var contract := pending_contract_offer_by_id(contract_id)
	if contract == null or contract.offer_node == null:
		return false
	active_contract = contract
	current_route_node = contract.offer_node
	run_state_changed.emit()
	return true


func pending_contract_offer_by_id(contract_id: String) -> ContractDef:
	if contract_id == "":
		return null
	for contract in pending_contract_offers:
		if contract != null and _contract_offer_key(contract) == contract_id:
			return contract
	return null


func contract_offer_key(contract: ContractDef) -> String:
	return _contract_offer_key(contract)


func _contract_offer_key(contract: ContractDef) -> String:
	if contract == null:
		return ""
	if contract.id != "":
		return contract.id
	if contract.generated_route_id != "":
		return contract.generated_route_id
	return "%s:%s" % [contract.display_name, contract.source_seed]


func accept_contract_offer(contract_id: String = "") -> bool:
	if contract_id != "" and not select_pending_contract_offer(contract_id):
		return false
	if not pending_contract_offer():
		return false
	if current_route_node.next_nodes.is_empty():
		return false
	if active_contract == null or not active_contract.has_generated_route_state():
		current_route_node = current_route_node.next_nodes[0]
	run_phase = RunPhase.CONTRACT_ROUTE
	run_outcome = RunOutcome.NONE
	set_locked(false)
	run_state_changed.emit()
	return true


func can_return_to_contract_offer() -> bool:
	return (
		run_phase == RunPhase.CONTRACT_ROUTE
		and active_contract != null
		and active_contract.offer_node != null
		and current_route_node == active_contract.offer_node
		and not pending_contract_offers.is_empty()
		and claimed_route_reward_ids.is_empty()
	)


func return_to_contract_offer() -> bool:
	if not can_return_to_contract_offer():
		return false
	if active_contract.offer_node == null:
		return false
	current_route_node = active_contract.offer_node
	run_phase = RunPhase.CONTRACT_OFFER
	run_outcome = RunOutcome.NONE
	last_fight_won = false
	set_locked(false)
	run_state_changed.emit()
	return true


func needs_secondary_subclass_choice() -> bool:
	return (
		active_contract != null
		and run_phase in [RunPhase.CONTRACT_ROUTE, RunPhase.PLANNING]
		and selected_trees.size() < PassiveAllocator.MAX_TREES
	)


func choose_secondary_tree(tree: SubclassTree) -> bool:
	if not needs_secondary_subclass_choice() or tree == null:
		return false
	if selected_trees.has(tree):
		return false
	if not PassiveAllocator.can_select_tree(selected_trees, tree):
		return false
	selected_trees.append(tree)
	_prune_rotation_to_unlocked()
	build_changed.emit()
	run_state_changed.emit()
	return true


func choose_contract_route_node(node: ContractRouteNode) -> bool:
	if not can_commit_contract_route_node(node):
		return false
	if not _prepare_contract_route_node_for_combat(node):
		return false
	current_route_node = node
	run_phase = RunPhase.PLANNING
	run_outcome = RunOutcome.NONE
	last_fight_won = false
	set_locked(false)
	run_state_changed.emit()
	return true


func can_commit_contract_route_node(node: ContractRouteNode) -> bool:
	if run_phase != RunPhase.CONTRACT_ROUTE:
		return false
	if node == null or current_route_node == null:
		return false
	if not current_route_node.next_nodes.has(node):
		return false
	return _contract_route_node_has_commit_payload(node)


func _contract_route_node_has_commit_payload(node: ContractRouteNode) -> bool:
	if node == null:
		return false
	if node.monster != null and node.duration_ms > 0:
		return true
	if active_contract == null or not active_contract.has_generated_route_state():
		return false
	if not (node.node_type in [
		ContractRouteNode.NodeType.FIGHT,
		ContractRouteNode.NodeType.CAPTAIN,
		ContractRouteNode.NodeType.ELITE,
		ContractRouteNode.NodeType.BOSS,
	]):
		return false
	return not node.generated_encounter_payload.is_empty()


func _prepare_contract_route_node_for_combat(node: ContractRouteNode) -> bool:
	if node == null:
		return false
	if node.monster != null and node.duration_ms > 0:
		return true
	if active_contract == null or not active_contract.has_generated_route_state():
		return false
	if node.generated_encounter_payload.is_empty():
		return false
	var draft := GeneratedMonsterDraft.from_dictionary(node.generated_encounter_payload)
	if draft == null or draft.hp <= 0 or draft.duration_ms <= 0:
		return false
	var monster := draft.to_monster()
	monster.display_name = _generated_route_monster_display_name(node, draft)
	node.monster = monster
	node.duration_ms = draft.duration_ms
	return true


func _generated_route_monster_display_name(node: ContractRouteNode, draft: GeneratedMonsterDraft) -> String:
	var combat_name := String(node.combat_preview.get("monster_name", ""))
	if combat_name != "":
		return combat_name
	var route_name := String(node.route_preview.get("monster_name", ""))
	if route_name != "":
		return route_name
	return draft.display_name


func start_fight() -> bool:
	if not can_start_current_fight():
		return false
	combat_stolen_gold = 0
	last_combat_result = null
	tavern_map_choice_made = false
	if is_contract_fight_active():
		pending_contract_offers = []
	run_phase = RunPhase.FIGHTING
	run_outcome = RunOutcome.NONE
	stats_preview_changed.emit()
	run_state_changed.emit()
	return true


func finish_fight(won: bool) -> void:
	last_fight_won = won
	if won:
		if _is_generated_boss_fight_active():
			mark_generated_boss_defeated(active_contract)
		run_outcome = RunOutcome.FIGHT_WIN
		run_phase = RunPhase.RESULT
	else:
		var key := _current_fight_key()
		encounter_failure_counts[key] = failure_count_for_current_encounter() + 1
		if is_unlimited_retry_encounter():
			# Project Bane revision to the R5/Phase 1 baseline rule (combat-
			# playback adjustment round 2 + retry bug, 2026-07-19, corrected
			# 2026-07-19; see docs/Phase_2_R5_Run_Rules_And_Determinism.md's
			# revision note): every other fight gets exactly one do-over
			# before a losing contract/Adventure forces a restart, but the
			# very first Tavern encounter (Mouthy Drunk, encounter index 0)
			# gets unlimited
			# retries instead, so a new player isn't forced back to class
			# selection while still getting comfortable at the very start of
			# the Adventure. A loss on the first encounter always resolves to
			# FIGHT_LOSS_RETRY, never ADVENTURE_RESTART_REQUIRED, regardless
			# of how many times it's already been attempted
			# (encounter_failure_counts is still incremented above for
			# bookkeeping/telemetry, it's just never consulted to force a
			# restart for that specific encounter).
			run_outcome = RunOutcome.FIGHT_LOSS_RETRY
			run_phase = RunPhase.RESULT
		elif failure_count_for_current_encounter() <= 1:
			run_outcome = RunOutcome.FIGHT_LOSS_RETRY
			run_phase = RunPhase.RESULT
		else:
			run_outcome = RunOutcome.CONTRACT_FAILED if is_contract_fight_active() else RunOutcome.ADVENTURE_RESTART_REQUIRED
			run_phase = RunPhase.RUN_ENDED
			set_locked(false)
	clear_combat_stolen_gold()
	run_state_changed.emit()


func record_fight_dps(dps: float) -> void:
	highest_run_dps = maxf(highest_run_dps, maxf(0.0, dps))


func record_fight_result(result: CombatResolver.CombatResult, monster: Monster) -> void:
	if result == null or monster == null:
		return
	last_combat_result = result
	record_fight_dps(result.dps)
	var summary := CombatRecap.summarize(result, monster)
	run_encounter_history.append({
		"fight_number": run_encounter_history.size() + 1,
		"contract_count": completed_contract_count + 1 if active_contract != null else 0,
		"contract_name": active_contract.display_name if active_contract != null else "Tavern",
		"enemy_name": monster.display_name,
		"enemy_role": _current_enemy_history_role(),
		"enemy_color": _current_enemy_history_color().to_html(false),
		"enemy_hp": monster.hp,
		"duration_ms": result.duration_ms,
		"total_damage": result.total_damage,
		"player_dps": result.dps,
		"required_dps": float(summary.get("required_dps", 0.0)),
		"dps_difference": result.dps - float(summary.get("required_dps", 0.0)),
		"is_win": result.is_win,
	})


func failure_count_for_current_encounter() -> int:
	return int(encounter_failure_counts.get(_current_fight_key(), 0))


func attempts_remaining_for_current_encounter() -> int:
	if is_unlimited_retry_encounter():
		return -1
	return max(0, STANDARD_MAX_ATTEMPTS - failure_count_for_current_encounter())


func current_attempts_text() -> String:
	if is_unlimited_retry_encounter():
		return "Attempts: unlimited"
	return "Attempts: %d/%d remaining" % [
		attempts_remaining_for_current_encounter(),
		STANDARD_MAX_ATTEMPTS,
	]


## The very first Tavern encounter (Mouthy Drunk, encounter index 0 in
## RunFlow.ENCOUNTER_PATHS) -- see docs/Phase_2_R5_Run_Rules_And_Determinism.md
## for the unlimited-retry exception this identifies. Must be an actual
## Tavern encounter (not a contract route node -- route nodes never reuse
## current_encounter_index) so a contract fight can never accidentally match
## on a stale index 0.
func is_unlimited_retry_encounter() -> bool:
	return not is_contract_fight_active() and current_encounter_index == 0


func can_retry_current_encounter() -> bool:
	return (
		run_phase == RunPhase.RESULT
		and run_outcome == RunOutcome.FIGHT_LOSS_RETRY
		and not last_fight_won
	)


func retry_current_encounter() -> bool:
	if not can_retry_current_encounter():
		return false
	var key := _current_fight_key()
	encounter_retry_counts[key] = int(encounter_retry_counts.get(key, 0)) + 1
	run_phase = RunPhase.PLANNING
	run_outcome = RunOutcome.NONE
	last_fight_won = false
	# RETRY BUG FIX (combat-playback adjustment round 2 + retry bug,
	# 2026-07-19): Tavern retries must make the same encounter fightable
	# again without forcing a redundant map click. Contract retries do not
	# use tavern_map_choice_made, but setting it true here is harmless and
	# keeps the retry path uniform.
	tavern_map_choice_made = true
	set_locked(false)
	run_state_changed.emit()
	return true


func has_claimed_current_reward() -> bool:
	if is_contract_fight_active():
		return current_route_node != null and claimed_route_reward_ids.has(current_route_node.id)
	return claimed_reward_encounter_indices.has(current_encounter_index)


func claim_current_reward(defer_currency: bool = false) -> bool:
	if run_phase != RunPhase.RESULT or not last_fight_won:
		return false
	if has_claimed_current_reward():
		return false
	var reward := current_reward()
	if not can_claim_current_reward():
		return false
	if is_contract_fight_active():
		claimed_route_reward_ids.append(current_route_node.id)
	else:
		var encounter := current_encounter()
		if encounter == null:
			return false
		claimed_reward_encounter_indices.append(current_encounter_index)
	if reward != null:
		if not defer_currency:
			add_gold(current_modified_reward_gold())
			add_talent_points(reward.talent_points)
		for gear in reward.fixed_gear_rewards:
			grant_gear(gear)
		pending_reward_choices = _gear_choices_for_reward(reward)
		if reward.unlocks_shop:
			shop_unlocked = true
	build_changed.emit()
	run_state_changed.emit()
	return true


func can_claim_current_reward() -> bool:
	if run_phase != RunPhase.RESULT or not last_fight_won:
		return false
	if has_claimed_current_reward():
		return false
	var reward := current_reward()
	if reward == null:
		return true
	return inventory_space_available() >= _fixed_reward_inventory_slots_needed(reward)


func has_pending_reward_choice() -> bool:
	return not pending_reward_choices.is_empty()


func can_choose_pending_reward_gear(gear: GearItem) -> bool:
	if gear == null or not pending_reward_choices.has(gear):
		return false
	if gear.tier == GearItem.Tier.LEGENDARY:
		return true
	return can_add_inventory_item()


func choose_pending_reward_gear(gear: GearItem) -> bool:
	if not can_choose_pending_reward_gear(gear):
		return false
	var should_auto_equip := gear.tier == GearItem.Tier.LEGENDARY
	var granted := grant_gear(gear, should_auto_equip)
	if not granted:
		return false
	pending_reward_choices = []
	build_changed.emit()
	run_state_changed.emit()
	return true


func skip_pending_reward_gear() -> bool:
	if not has_pending_reward_choice():
		return false
	pending_reward_choices = []
	build_changed.emit()
	run_state_changed.emit()
	return true


func should_open_shop_after_current_reward() -> bool:
	if is_contract_fight_active():
		if _is_generated_boss_fight_active() and all_generated_bosses_defeated():
			return false
		return _is_terminal_contract_victory_pending()
	return shop_unlocked and current_encounter_index + 1 < RunFlow.encounter_count()


## True right when claiming the current reward is what starts the Contract
## Offer -- the P2:R7 story pass's "skip the shop, head straight into the
## contract story" transition hooks off this. Mirrors continue_after_win()'s
## own "last tavern encounter" check exactly, evaluated before that call
## changes current_encounter_index, so the two stay in lockstep.
func is_last_tavern_reward() -> bool:
	return not is_contract_fight_active() and current_encounter_index + 1 >= RunFlow.tavern_encounter_count()


func open_shop_round() -> bool:
	if not should_open_shop_after_current_reward():
		return false
	shop_round_pending = true
	shop_reroll_used = false
	shop_reroll_count = 0
	shop_reroll_cost = SHOP_REROLL_INITIAL_COST
	shop_offers = _generate_tavern_shop_offers(shop_round_index, false)
	build_changed.emit()
	run_state_changed.emit()
	return true


func can_reroll_shop_offers() -> bool:
	return shop_round_pending and gold >= shop_reroll_cost


func reroll_shop_offers() -> bool:
	if not can_reroll_shop_offers():
		return false
	var paid_cost := shop_reroll_cost
	if not spend_gold(paid_cost):
		return false
	shop_reroll_count += 1
	shop_reroll_used = true
	shop_offers = _generate_tavern_shop_offers(shop_round_index, shop_reroll_count)
	shop_reroll_cost = SHOP_REROLL_INITIAL_COST + (shop_reroll_count * SHOP_REROLL_COST_STEP)
	build_changed.emit()
	run_state_changed.emit()
	return true


func buy_shop_offer(offer: GearItem) -> bool:
	if not shop_round_pending or offer == null or not shop_offers.has(offer):
		return false
	if not can_store_shop_offer(offer):
		return false
	var price := shop_purchase_price_for(offer)
	if not spend_gold(price):
		return false
	shop_offers.erase(offer)
	offer.is_unidentified = false
	grant_gear(offer)
	build_changed.emit()
	run_state_changed.emit()
	return true


func can_store_shop_offer(offer: GearItem) -> bool:
	return offer != null and can_add_inventory_item()


func has_open_equipment_slot(slot: GearItem.SlotType) -> bool:
	return equipped_item_for_slot(slot) == null


func close_shop_round() -> bool:
	if not shop_round_pending:
		return false
	shop_round_pending = false
	shop_round_index += 1
	shop_offers = []
	shop_reroll_used = false
	shop_reroll_count = 0
	shop_reroll_cost = SHOP_REROLL_INITIAL_COST
	run_state_changed.emit()
	return true


func continue_after_win() -> bool:
	if run_phase != RunPhase.RESULT or not last_fight_won:
		return false
	if is_contract_fight_active():
		if current_route_node.next_nodes.is_empty():
			return _complete_contract_and_offer_next()
		run_phase = RunPhase.CONTRACT_ROUTE
		run_outcome = RunOutcome.NONE
		last_fight_won = false
		set_locked(false)
		run_state_changed.emit()
		return true
	if current_encounter_index + 1 >= RunFlow.tavern_encounter_count():
		return start_generated_contract_loop_offer()
	var has_next := advance_encounter()
	if has_next:
		run_phase = RunPhase.PLANNING
		run_outcome = RunOutcome.NONE
		tavern_map_choice_made = false
	else:
		run_phase = RunPhase.RUN_ENDED
		run_outcome = RunOutcome.CONTRACT_VICTORY if active_contract != null else RunOutcome.FIGHT_WIN
	run_state_changed.emit()
	return has_next


func _complete_contract_and_offer_next() -> bool:
	mark_generated_boss_defeated(active_contract)
	completed_contract_count += 1
	contract_offer_index += 1
	claimed_route_reward_ids = []
	pending_contract_offers = []
	active_contract = null
	current_route_node = null
	run_outcome = RunOutcome.NONE
	last_fight_won = false
	shop_unlocked = false
	set_locked(false)
	if all_generated_bosses_defeated():
		end_run(true, RunOutcome.ALL_BOSSES_DEFEATED)
		return false
	run_phase = RunPhase.CONTRACT_OFFER
	if start_generated_contract_loop_offer():
		return true
	end_run(true, RunOutcome.CONTRACT_VICTORY)
	return false


func generated_boss_id_for_contract(contract: ContractDef) -> String:
	return ContractOfferSourceScript.boss_id_for_contract(contract)


func generated_boss_catalog() -> Array[Dictionary]:
	return ContractOfferSourceScript.generated_boss_catalog()


func mark_generated_boss_defeated(contract: ContractDef) -> void:
	var boss_id := generated_boss_id_for_contract(contract)
	if boss_id == "" or defeated_generated_boss_ids.has(boss_id):
		return
	defeated_generated_boss_ids.append(boss_id)
	run_state_changed.emit()


func is_generated_boss_defeated(boss_id: String) -> bool:
	return boss_id != "" and defeated_generated_boss_ids.has(boss_id)


func defeated_generated_boss_count() -> int:
	return defeated_generated_boss_ids.size()


func generated_bosses_total_count() -> int:
	return generated_boss_catalog().size()


func all_generated_bosses_defeated() -> bool:
	var catalog := generated_boss_catalog()
	if catalog.is_empty():
		return false
	for entry in catalog:
		if not defeated_generated_boss_ids.has(String(entry.get("id", ""))):
			return false
	return true


func _is_generated_boss_fight_active() -> bool:
	return (
		is_contract_fight_active()
		and active_contract != null
		and active_contract.has_generated_route_state()
		and current_route_node != null
		and current_route_node.node_type == ContractRouteNode.NodeType.BOSS
	)


func _generate_tavern_shop_offers(round_index: int, reroll_key: Variant) -> Array[GearItem]:
	var shop_context := _current_reward_context_key()
	var roll_key := _shop_offer_roll_key(reroll_key)
	var contract_depth := _current_shop_contract_depth()
	var magic_find := current_magic_find()
	var rng := RunRngSystem.rng_for_context(
		adventure_seed,
		RunRngSystem.CONTEXT_SHOP_OFFER,
		[shop_context, round_index, roll_key, contract_depth]
	)
	var offers: Array[GearItem] = []
	var seen_signatures := {}
	for i in SHOP_OFFER_COUNT:
		var stable_id := RunRngSystem.id_for_context(
			"gear.generated.shop",
			adventure_seed,
			RunRngSystem.CONTEXT_SHOP_OFFER,
			[shop_context, round_index, roll_key, i, contract_depth]
		)
		offers.append(_generate_unique_shop_offer(rng, stable_id, contract_depth, seen_signatures, magic_find))
	return offers


func _shop_offer_roll_key(reroll_key: Variant) -> String:
	if typeof(reroll_key) == TYPE_BOOL:
		return "reroll:1" if bool(reroll_key) else "initial"
	var reroll_index := int(reroll_key)
	return "initial" if reroll_index <= 0 else "reroll:%d" % reroll_index


func _generate_unique_shop_offer(rng: RandomNumberGenerator, stable_id: String, contract_depth: int, seen_signatures: Dictionary, magic_find: float = 0.0) -> GearItem:
	var fallback_offer: GearItem = null
	var fallback_signature := ""
	for attempt in SHOP_UNIQUE_ROLL_ATTEMPTS:
		var slot: GearItem.SlotType = GearGenerator.ALL_SLOTS[rng.randi_range(0, GearGenerator.ALL_SLOTS.size() - 1)]
		var tier := _shop_tier_for_current_phase(rng, contract_depth)
		tier = _upgraded_shop_tier(tier, stable_id, attempt, contract_depth, magic_find)
		var offer := _shop_offer_for_tier(tier, slot, rng, stable_id, contract_depth)
		var signature := _shop_offer_signature(offer)
		if fallback_offer == null:
			fallback_offer = offer
			fallback_signature = signature
		if not seen_signatures.has(signature):
			seen_signatures[signature] = true
			return offer
	# The visible item space is much larger than SHOP_OFFER_COUNT, so this is
	# a deterministic guardrail rather than an expected path.
	seen_signatures[fallback_signature] = true
	return fallback_offer


func _shop_tier_for_current_phase(rng: RandomNumberGenerator, contract_depth: int = REWARD_UPGRADE_MIN_CONTRACT_DEPTH) -> GearItem.Tier:
	if active_contract == null:
		return GearItem.Tier.BASIC
	var weights := _shop_rarity_weights_for_depth(contract_depth)
	var total_weight := 0
	for tier in SHOP_ROLL_TIERS:
		total_weight += int(weights.get(tier, 0))
	var roll := rng.randi_range(1, total_weight)
	var cumulative := 0
	for tier in SHOP_ROLL_TIERS:
		cumulative += int(weights.get(tier, 0))
		if roll <= cumulative:
			return tier
	return GearItem.Tier.BASIC


func _upgraded_shop_tier(base_tier: GearItem.Tier, shop_context: String, offer_index: int, contract_depth: int = REWARD_UPGRADE_MIN_CONTRACT_DEPTH, magic_find: float = 0.0) -> GearItem.Tier:
	var tier := base_tier
	if tier == GearItem.Tier.LEGENDARY or _is_reward_upgrade_high_tier(tier):
		return tier
	if tier == GearItem.Tier.BASIC and _shop_upgrade_roll(shop_context, offer_index, base_tier, contract_depth, "basic_to_master", REWARD_UPGRADE_BASIC_TO_MASTER_BP, magic_find):
		tier = GearItem.Tier.MASTER
	if tier == GearItem.Tier.MASTER and _shop_upgrade_roll(shop_context, offer_index, base_tier, contract_depth, "master_to_epic", REWARD_UPGRADE_MASTER_TO_EPIC_BP, magic_find):
		tier = GearItem.Tier.EPIC
	if tier == GearItem.Tier.EPIC and _shop_upgrade_roll(shop_context, offer_index, base_tier, contract_depth, "epic_to_high_tier", REWARD_UPGRADE_EPIC_TO_HIGH_TIER_BP, magic_find):
		tier = _shop_high_tier_roll(shop_context, offer_index, base_tier, contract_depth)
	return tier


func _shop_upgrade_roll(
	shop_context: String,
	offer_index: int,
	base_tier: GearItem.Tier,
	contract_depth: int,
	step: String,
	chance_bp: int,
	magic_find: float = 0.0
) -> bool:
	var scaled_chance := _scaled_reward_upgrade_chance_bp(chance_bp, contract_depth, magic_find)
	var rng := RunRngSystem.rng_for_context(
		adventure_seed,
		RunRngSystem.CONTEXT_SHOP_OFFER,
		[shop_context, "rarity_upgrade", offer_index, base_tier, _reward_upgrade_contract_depth(contract_depth), step]
	)
	return rng.randi_range(1, REWARD_UPGRADE_BP_DENOMINATOR) <= scaled_chance


func _shop_high_tier_roll(shop_context: String, offer_index: int, base_tier: GearItem.Tier, contract_depth: int = REWARD_UPGRADE_MIN_CONTRACT_DEPTH) -> GearItem.Tier:
	var rng := RunRngSystem.rng_for_context(
		adventure_seed,
		RunRngSystem.CONTEXT_SHOP_OFFER,
		[shop_context, "rarity_upgrade", offer_index, base_tier, _reward_upgrade_contract_depth(contract_depth), "high_tier_split"]
	)
	var roll := rng.randi_range(1, REWARD_HIGH_TIER_CURSED_BP + REWARD_HIGH_TIER_CHAOS_BP + REWARD_HIGH_TIER_UNIQUE_BP)
	if roll <= REWARD_HIGH_TIER_CURSED_BP:
		return GearItem.Tier.CURSED
	if roll <= REWARD_HIGH_TIER_CURSED_BP + REWARD_HIGH_TIER_CHAOS_BP:
		return GearItem.Tier.CHAOS
	return GearItem.Tier.UNIQUE


func _shop_rarity_weights_for_depth(contract_depth: int) -> Dictionary:
	var depth := _reward_upgrade_contract_depth(contract_depth)
	var previous: Dictionary = CONTRACT_SHOP_RARITY_CURVE[0]
	for i in range(1, CONTRACT_SHOP_RARITY_CURVE.size()):
		var next: Dictionary = CONTRACT_SHOP_RARITY_CURVE[i]
		if depth <= int(next["depth"]):
			return _interpolated_shop_rarity_weights(previous, next, depth)
		previous = next
	return (CONTRACT_SHOP_RARITY_CURVE[CONTRACT_SHOP_RARITY_CURVE.size() - 1]["weights"] as Dictionary).duplicate()


func _interpolated_shop_rarity_weights(from_anchor: Dictionary, to_anchor: Dictionary, depth: int) -> Dictionary:
	var from_depth := int(from_anchor["depth"])
	var to_depth := int(to_anchor["depth"])
	var span := maxf(1.0, float(to_depth - from_depth))
	var progress := clampf(float(depth - from_depth) / span, 0.0, 1.0)
	var from_weights: Dictionary = from_anchor["weights"]
	var to_weights: Dictionary = to_anchor["weights"]
	var weights := {}
	for tier in SHOP_ROLL_TIERS:
		var from_weight := float(from_weights.get(tier, 0))
		var to_weight := float(to_weights.get(tier, 0))
		weights[tier] = int(round(lerpf(from_weight, to_weight, progress)))
	return weights


func _current_shop_contract_depth() -> int:
	return _current_contract_reward_depth()


func _shop_offer_for_tier(tier: GearItem.Tier, slot: GearItem.SlotType, rng: RandomNumberGenerator, stable_id: String, contract_depth: int = REWARD_UPGRADE_MIN_CONTRACT_DEPTH) -> GearItem:
	if tier != GearItem.Tier.LEGENDARY:
		var generated: GearItem = GearGenerator.generate_from_request({
			"tier": tier,
			"slot": slot,
			"rng": rng,
			"id": stable_id,
			"deterministic_key": stable_id,
			"source_context": "shop_offer:%s" % _current_reward_context_key(),
			"source_seed": adventure_seed,
			"contract_depth": _reward_upgrade_contract_depth(contract_depth),
			"value_scale": 1.0,
		}).get("item")
		if generated != null and generated.tier == GearItem.Tier.CHAOS:
			generated.is_unidentified = true
		return generated
	var available_paths := _unowned_shop_legendary_paths()
	if available_paths.is_empty():
		# Every Legendary is already owned -- fall back to the next-lower
		# tier rather than offering a duplicate the player can't use.
		return GearGenerator.generate_from_request({
			"tier": GearItem.Tier.CURSED,
			"slot": slot,
			"rng": rng,
			"id": stable_id,
			"deterministic_key": stable_id,
			"source_context": "shop_offer:legendary_fallback:%s" % _current_reward_context_key(),
			"source_seed": adventure_seed,
			"contract_depth": _reward_upgrade_contract_depth(contract_depth),
			"value_scale": 1.0,
		}).get("item")
	var path := available_paths[rng.randi_range(0, available_paths.size() - 1)]
	var offer: GearItem = load(path)
	return offer


## Excludes Legendaries already owned (inventory or equipped) from the
## shop's Legendary roll (P2:R9:T6) -- compares by `.id` rather than object
## identity, consistent with `_shop_offer_signature()`'s property-based
## comparison.
## The full Legendary path list, sourced from `LegendaryCatalog` (P2:R9/R10's
## single shared source) rather than a duplicated literal here.
func shop_legendary_paths() -> Array[String]:
	return LegendaryCatalog.all_paths()


func _unowned_shop_legendary_paths() -> Array[String]:
	var owned_ids := {}
	for gear in inventory:
		if gear != null:
			owned_ids[gear.id] = true
	for gear in equipped_gear():
		if gear != null:
			owned_ids[gear.id] = true
	var available: Array[String] = []
	for path in shop_legendary_paths():
		var candidate: GearItem = load(path)
		if not owned_ids.has(candidate.id):
			available.append(path)
	return available


func _shop_offer_signature(offer: GearItem) -> String:
	var affix_parts: PackedStringArray = []
	for affix in offer.affixes:
		affix_parts.append(_affix_signature(affix))
	affix_parts.sort()
	return "%d|%d|%s" % [offer.tier, offer.slot, ",".join(affix_parts)]


func _gear_choices_for_reward(reward: EncounterReward) -> Array[GearItem]:
	var choices: Array[GearItem] = []
	for gear in reward.gear_choice_rewards:
		if gear != null:
			choices.append(gear)
	var reward_context := _current_reward_context_key()
	if reward.legendary_choice_count > 0 and not reward.legendary_choice_pool.is_empty():
		var legendary_rng := RunRngSystem.rng_for_context(
			adventure_seed,
			RunRngSystem.CONTEXT_REWARD_CHOICE,
			[reward_context, "legendary", reward.legendary_choice_count]
		)
		choices.append_array(_sample_distinct_gear(reward.legendary_choice_pool, reward.legendary_choice_count, legendary_rng))
	if reward.generated_gear_choice_count <= 0:
		return choices
	var rng := RunRngSystem.rng_for_context(
		adventure_seed,
		RunRngSystem.CONTEXT_REWARD_CHOICE,
		[reward_context, reward.generated_gear_tier, reward.generated_gear_choice_count]
	)
	var slots: Array = reward.generated_gear_slots if not reward.generated_gear_slots.is_empty() else GearGenerator.ALL_SLOTS
	var seen_stat_signatures := {}
	var contract_depth := _current_contract_reward_depth()
	var magic_find := current_magic_find()
	for i in reward.generated_gear_choice_count:
		var upgrade_story := _reward_tier_upgrade_story(reward.generated_gear_tier, reward_context, i, contract_depth, magic_find)
		var upgraded_tier := int(upgrade_story["final_tier"])
		var generated := _generate_reward_choice_item(upgraded_tier, slots, rng, reward_context, i, contract_depth, seen_stat_signatures)
		_apply_reward_upgrade_story(generated, upgrade_story)
		choices.append(generated)
	return choices


func _upgraded_reward_tier(base_tier: GearItem.Tier, reward_context: String, choice_index: int, contract_depth: int = REWARD_UPGRADE_MIN_CONTRACT_DEPTH, magic_find: float = 0.0) -> GearItem.Tier:
	return int(_reward_tier_upgrade_story(base_tier, reward_context, choice_index, contract_depth, magic_find)["final_tier"])


func _reward_tier_upgrade_story(base_tier: GearItem.Tier, reward_context: String, choice_index: int, contract_depth: int = REWARD_UPGRADE_MIN_CONTRACT_DEPTH, magic_find: float = 0.0) -> Dictionary:
	var tier := int(base_tier)
	var steps: Array[int] = [tier]
	var magic_find_upgraded := false
	if tier == GearItem.Tier.BASIC:
		var basic_roll := _reward_upgrade_roll_result(reward_context, choice_index, base_tier, contract_depth, "basic_to_master", REWARD_UPGRADE_BASIC_TO_MASTER_BP, magic_find)
		if bool(basic_roll["succeeded"]):
			tier = GearItem.Tier.MASTER
			steps.append(tier)
			magic_find_upgraded = magic_find_upgraded or bool(basic_roll["magic_find_upgraded"])
	if tier == GearItem.Tier.MASTER:
		var master_roll := _reward_upgrade_roll_result(reward_context, choice_index, base_tier, contract_depth, "master_to_epic", REWARD_UPGRADE_MASTER_TO_EPIC_BP, magic_find)
		if bool(master_roll["succeeded"]):
			tier = GearItem.Tier.EPIC
			steps.append(tier)
			magic_find_upgraded = magic_find_upgraded or bool(master_roll["magic_find_upgraded"])
	if tier == GearItem.Tier.EPIC:
		var high_roll := _reward_upgrade_roll_result(reward_context, choice_index, base_tier, contract_depth, "epic_to_high_tier", REWARD_UPGRADE_EPIC_TO_HIGH_TIER_BP, magic_find)
		if bool(high_roll["succeeded"]):
			tier = _reward_high_tier_roll(reward_context, choice_index, base_tier, contract_depth)
			steps.append(tier)
			magic_find_upgraded = magic_find_upgraded or bool(high_roll["magic_find_upgraded"])
	return {
		"base_tier": int(base_tier),
		"final_tier": tier,
		"tier_steps": steps,
		"magic_find_upgraded": magic_find_upgraded,
	}


func _apply_reward_upgrade_story(gear: GearItem, story: Dictionary) -> void:
	if gear == null:
		return
	gear.reward_base_tier = int(story.get("base_tier", gear.tier))
	gear.reward_tier_steps = _reward_upgrade_int_array(story.get("tier_steps", [gear.tier]))
	gear.reward_magic_find_upgraded = bool(story.get("magic_find_upgraded", false))


func _reward_upgrade_roll(
	reward_context: String,
	choice_index: int,
	base_tier: GearItem.Tier,
	contract_depth: int,
	step: String,
	chance_bp: int,
	magic_find: float = 0.0
) -> bool:
	return bool(_reward_upgrade_roll_result(reward_context, choice_index, base_tier, contract_depth, step, chance_bp, magic_find)["succeeded"])


func _reward_upgrade_roll_result(
	reward_context: String,
	choice_index: int,
	base_tier: GearItem.Tier,
	contract_depth: int,
	step: String,
	chance_bp: int,
	magic_find: float = 0.0
) -> Dictionary:
	var scaled_chance := _scaled_reward_upgrade_chance_bp(chance_bp, contract_depth, magic_find)
	var depth_scaled_chance := _scaled_reward_upgrade_chance_bp(chance_bp, contract_depth, 0.0)
	var rng := RunRngSystem.rng_for_context(
		adventure_seed,
		RunRngSystem.CONTEXT_REWARD_CHOICE,
		[reward_context, "rarity_upgrade", choice_index, base_tier, _reward_upgrade_contract_depth(contract_depth), step]
	)
	var roll := rng.randi_range(1, REWARD_UPGRADE_BP_DENOMINATOR)
	return {
		"succeeded": roll <= scaled_chance,
		"magic_find_upgraded": magic_find > 0.0 and roll > depth_scaled_chance and roll <= scaled_chance,
		"roll": roll,
		"chance_bp": scaled_chance,
		"base_chance_bp": depth_scaled_chance,
	}


func _reward_high_tier_roll(reward_context: String, choice_index: int, base_tier: GearItem.Tier, contract_depth: int = REWARD_UPGRADE_MIN_CONTRACT_DEPTH) -> GearItem.Tier:
	var rng := RunRngSystem.rng_for_context(
		adventure_seed,
		RunRngSystem.CONTEXT_REWARD_CHOICE,
		[reward_context, "rarity_upgrade", choice_index, base_tier, _reward_upgrade_contract_depth(contract_depth), "high_tier_split"]
	)
	var roll := rng.randi_range(1, REWARD_HIGH_TIER_CURSED_BP + REWARD_HIGH_TIER_CHAOS_BP + REWARD_HIGH_TIER_UNIQUE_BP)
	if roll <= REWARD_HIGH_TIER_CURSED_BP:
		return GearItem.Tier.CURSED
	if roll <= REWARD_HIGH_TIER_CURSED_BP + REWARD_HIGH_TIER_CHAOS_BP:
		return GearItem.Tier.CHAOS
	return GearItem.Tier.UNIQUE


func _current_contract_reward_depth() -> int:
	return _reward_upgrade_contract_depth(completed_contract_count + 1)


func _reward_upgrade_contract_depth(contract_depth: int) -> int:
	return clampi(contract_depth, REWARD_UPGRADE_MIN_CONTRACT_DEPTH, REWARD_UPGRADE_MAX_CONTRACT_DEPTH)


func _reward_upgrade_depth_bonus_bp(base_chance_bp: int, contract_depth: int) -> int:
	var depth := _reward_upgrade_contract_depth(contract_depth)
	var depth_progress := float(depth - REWARD_UPGRADE_MIN_CONTRACT_DEPTH) / float(REWARD_UPGRADE_MAX_CONTRACT_DEPTH - REWARD_UPGRADE_MIN_CONTRACT_DEPTH)
	return int(round(float(base_chance_bp) * REWARD_UPGRADE_MAX_RELATIVE_DEPTH_BONUS * depth_progress))


func _scaled_reward_upgrade_chance_bp(base_chance_bp: int, contract_depth: int, magic_find: float = 0.0) -> int:
	var depth_scaled_chance := base_chance_bp + _reward_upgrade_depth_bonus_bp(base_chance_bp, contract_depth)
	var magic_find_multiplier := maxf(0.0, 1.0 + magic_find)
	return clampi(int(round(float(depth_scaled_chance) * magic_find_multiplier)), 0, REWARD_UPGRADE_BP_DENOMINATOR)


func _reward_upgrade_high_tier_options() -> Array:
	return [
		GearItem.Tier.CURSED,
		GearItem.Tier.CHAOS,
		GearItem.Tier.UNIQUE,
	]


func _is_reward_upgrade_high_tier(tier: GearItem.Tier) -> bool:
	return _reward_upgrade_high_tier_options().has(tier)


func _reward_upgrade_int_array(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if value is PackedInt32Array:
		for item in value:
			result.append(int(item))
	elif value is Array:
		for item in value:
			result.append(int(item))
	return result


func _generate_reward_choice_item(
	tier: GearItem.Tier,
	slots: Array,
	rng: RandomNumberGenerator,
	reward_context: String,
	choice_index: int,
	contract_depth: int,
	seen_stat_signatures: Dictionary
) -> GearItem:
	var max_attempts := 64
	var fallback: GearItem = null
	for attempt in max_attempts:
		var slot: GearItem.SlotType = slots[rng.randi_range(0, slots.size() - 1)]
		var stable_id := RunRngSystem.id_for_context(
			"gear.generated.reward",
			adventure_seed,
			RunRngSystem.CONTEXT_REWARD_CHOICE,
			[reward_context, tier, choice_index, attempt, slot, _reward_upgrade_contract_depth(contract_depth)]
		)
		var item: GearItem = GearGenerator.generate_from_request({
			"tier": tier,
			"slot": slot,
			"rng": rng,
			"id": stable_id,
			"deterministic_key": stable_id,
			"source_context": "reward_choice:%s" % reward_context,
			"source_seed": adventure_seed,
			"contract_depth": _reward_upgrade_contract_depth(contract_depth),
			"value_scale": 1.0,
		}).get("item")
		if fallback == null:
			fallback = item
		var stat_signature := _generated_reward_stat_signature(item)
		if not seen_stat_signatures.has(stat_signature):
			seen_stat_signatures[stat_signature] = true
			return item
	return fallback


func _generated_reward_stat_signature(item: GearItem) -> String:
	if item == null:
		return ""
	var affix_parts: PackedStringArray = []
	for affix in item.affixes:
		affix_parts.append(_affix_signature(affix))
	affix_parts.sort()
	return "%d|%s" % [item.tier, ",".join(affix_parts)]


func _affix_signature(affix: StatModifier) -> String:
	if affix == null:
		return "null"
	return "%s:%d:%d:%s:%0.4f" % [
		StatCatalog.canonical_id_for_modifier(affix),
		affix.category,
		affix.operation,
		"drawback" if affix.is_drawback else "positive",
		affix.value,
	]


## Picks `count` distinct entries from `pool` using seeded `rng`, without
## replacement. Used for Knives' randomized Legendary choice (P2:R9:T5) so
## the same Adventure seed always produces the same 2-of-5 result.
func _sample_distinct_gear(pool: Array[GearItem], count: int, rng: RandomNumberGenerator) -> Array[GearItem]:
	var remaining: Array[GearItem] = pool.duplicate()
	var picked: Array[GearItem] = []
	var take := mini(count, remaining.size())
	for i in take:
		var index := rng.randi_range(0, remaining.size() - 1)
		picked.append(remaining[index])
		remaining.remove_at(index)
	return picked


func _current_reward_context_key() -> String:
	if is_contract_fight_active() and current_route_node != null:
		return "route:%s" % current_route_node.id
	return "encounter:%d" % current_encounter_index


func _is_terminal_contract_victory_pending() -> bool:
	return (
		is_contract_fight_active()
		and run_phase == RunPhase.RESULT
		and last_fight_won
		and current_route_node != null
		and current_route_node.next_nodes.is_empty()
	)


func end_run(won: bool, outcome: int = RunOutcome.NONE) -> void:
	last_fight_won = won
	if outcome != RunOutcome.NONE:
		run_outcome = outcome
	elif won:
		run_outcome = RunOutcome.CONTRACT_VICTORY if active_contract != null else RunOutcome.FIGHT_WIN
	else:
		run_outcome = RunOutcome.CONTRACT_FAILED if active_contract != null else RunOutcome.ADVENTURE_RESTART_REQUIRED
	run_phase = RunPhase.RUN_ENDED
	run_state_changed.emit()


## Advances to the next encounter. Returns false when the ladder is
## exhausted (i.e. the just-fought encounter was the last one).
func advance_encounter() -> bool:
	current_encounter_index += 1
	build_changed.emit()
	return current_encounter_index < RunFlow.encounter_count()


func _current_fight_key() -> String:
	if active_contract != null and current_route_node != null and current_route_node.monster != null:
		return current_route_node.id
	return "encounter:%d" % current_encounter_index


func _current_enemy_history_role() -> String:
	if current_route_node == null:
		return "Normal"
	match current_route_node.node_type:
		ContractRouteNode.NodeType.BOSS:
			return "Boss"
		ContractRouteNode.NodeType.ELITE:
			return "Elite"
		ContractRouteNode.NodeType.CAPTAIN:
			return "Captain"
		_:
			if current_route_node.monster_presentation_type.strip_edges() != "":
				return current_route_node.monster_presentation_type.capitalize()
			return "Normal"


func _current_enemy_history_color() -> Color:
	if current_route_node == null:
		return UIColors.TEXT_POISON
	match current_route_node.node_type:
		ContractRouteNode.NodeType.BOSS:
			return UIColors.TEXT_WARNING
		ContractRouteNode.NodeType.ELITE:
			return UIColors.TEXT_MAGIC
		ContractRouteNode.NodeType.CAPTAIN:
			return UIColors.TIER_MASTER
		_:
			return UIColors.TEXT_POISON


func add_gold(amount: int) -> void:
	gold += amount
	build_changed.emit()


func record_combat_stolen_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	combat_stolen_gold += amount
	stats_preview_changed.emit()


func clear_combat_stolen_gold() -> void:
	if combat_stolen_gold == 0:
		return
	combat_stolen_gold = 0
	stats_preview_changed.emit()


func modified_gold_reward(base_amount: int) -> int:
	var stats := current_player_stats()
	return max(0, int(floor(float(base_amount) * stats.gold_reward_multiplier)))


func overkill_gold_for_result(result: CombatResolver.CombatResult) -> int:
	if result == null or not result.is_win:
		return 0
	var steps := int(floor(maxf(0.0, result.overkill_damage) / OVERKILL_GOLD_DAMAGE_STEP))
	return clampi(steps * OVERKILL_GOLD_PER_STEP, 0, OVERKILL_GOLD_CAP)


func current_overkill_gold() -> int:
	return overkill_gold_for_result(last_combat_result)


func current_base_reward_gold() -> int:
	var reward := current_reward()
	if reward == null:
		return 0
	return max(0, reward.gold_amount) + current_overkill_gold()


func current_modified_reward_gold() -> int:
	return modified_gold_reward(current_base_reward_gold())


func current_player_stats() -> PlayerStats:
	return BuildResolver.resolve_stats(selected_class, selected_trees, selected_talents, equipped_gear(), gold)


func current_shop_discount() -> float:
	return maxf(0.0, current_player_stats().shop_discount)


func current_magic_find() -> float:
	return maxf(0.0, current_player_stats().magic_find)


func shop_purchase_price_for(offer: GearItem) -> int:
	if offer == null:
		return 0
	var base_price := GearGenerator.price_for_tier(offer.tier)
	if base_price <= 0:
		return 0
	var multiplier := maxf(0.0, 1.0 - current_shop_discount())
	return maxi(1, int(floor(float(base_price) * multiplier)))


func add_talent_points(amount: int) -> void:
	earned_talent_points = clampi(earned_talent_points + amount, 0, TALENT_POINT_CAP)
	build_changed.emit()


func spend_gold(amount: int) -> bool:
	if amount > gold:
		return false
	gold -= amount
	build_changed.emit()
	return true


func add_inventory_item(gear: GearItem) -> bool:
	if gear == null or inventory.has(gear) or not can_add_inventory_item():
		return false
	inventory.append(gear)
	build_changed.emit()
	return true


func can_add_inventory_item() -> bool:
	return inventory.size() < INVENTORY_CAPACITY


func inventory_space_available() -> int:
	return max(0, INVENTORY_CAPACITY - inventory.size())


func _fixed_reward_inventory_slots_needed(reward: EncounterReward) -> int:
	if reward == null:
		return 0
	var needed := 0
	for gear in reward.fixed_gear_rewards:
		if gear != null:
			needed += 1
	return needed


func remove_inventory_item(gear: GearItem) -> bool:
	if gear == null or not inventory.has(gear):
		return false
	inventory.erase(gear)
	build_changed.emit()
	return true


func has_inventory_item(gear: GearItem) -> bool:
	return gear != null and inventory.has(gear)


func grant_gear(gear: GearItem, auto_equip: bool = false) -> bool:
	if gear == null:
		return false
	if auto_equip:
		equip(gear)
	else:
		return add_inventory_item(gear)
	return true


func sell_inventory_item(gear: GearItem) -> bool:
	if not has_inventory_item(gear):
		return false
	inventory.erase(gear)
	gold += sell_value_for(gear)
	build_changed.emit()
	run_state_changed.emit()
	return true


func sell_equipped_item(slot: GearItem.SlotType) -> bool:
	var gear := equipped_item_for_slot(slot)
	if gear == null:
		return false
	match slot:
		GearItem.SlotType.WEAPON:
			equipped_weapon = null
		GearItem.SlotType.HELM:
			equipped_helm = null
		GearItem.SlotType.ARMOR:
			equipped_armor = null
		GearItem.SlotType.TRINKET:
			equipped_trinket = null
		GearItem.SlotType.CHARM:
			equipped_charm = null
	gold += sell_value_for(gear)
	build_changed.emit()
	run_state_changed.emit()
	return true


func destroy_inventory_item(gear: GearItem) -> bool:
	if not has_inventory_item(gear):
		return false
	inventory.erase(gear)
	build_changed.emit()
	run_state_changed.emit()
	return true


func destroy_equipped_item(slot: GearItem.SlotType) -> bool:
	var gear := equipped_item_for_slot(slot)
	if gear == null:
		return false
	match slot:
		GearItem.SlotType.WEAPON:
			equipped_weapon = null
		GearItem.SlotType.HELM:
			equipped_helm = null
		GearItem.SlotType.ARMOR:
			equipped_armor = null
		GearItem.SlotType.TRINKET:
			equipped_trinket = null
		GearItem.SlotType.CHARM:
			equipped_charm = null
	build_changed.emit()
	run_state_changed.emit()
	return true


func sell_value_for(gear: GearItem) -> int:
	if gear == null:
		return 0
	if _is_starter_weapon(gear):
		return 5
	return max(1, int(floor(float(GearGenerator.price_for_tier(gear.tier)) * SELL_VALUE_RATIO)))


func equip_from_inventory(gear: GearItem) -> bool:
	if not has_inventory_item(gear):
		return false
	equip(gear)
	return true


func equip(gear: GearItem) -> void:
	if gear == null:
		return
	inventory.erase(gear)
	var replaced: GearItem = equipped_item_for_slot(gear.slot)
	match gear.slot:
		GearItem.SlotType.WEAPON:
			equipped_weapon = gear
		GearItem.SlotType.HELM:
			equipped_helm = gear
		GearItem.SlotType.ARMOR:
			equipped_armor = gear
		GearItem.SlotType.TRINKET:
			equipped_trinket = gear
		GearItem.SlotType.CHARM:
			equipped_charm = gear
	# A full inventory must not silently grow past INVENTORY_CAPACITY when a
	# swap displaces the previously-equipped item -- every other way to
	# acquire gear (buy/reward/claim) is gated on inventory space, so this
	# would otherwise be the one path that isn't. Selling the displaced item
	# for gold mirrors sell_equipped_item()'s existing resolution for "this
	# gear is going away" and keeps equip() always succeeding, which
	# choose_pending_reward_gear() relies on for auto-equipped Legendaries.
	var sold_displaced_for_gold := false
	if replaced != null and replaced != gear and not inventory.has(replaced):
		if can_add_inventory_item():
			inventory.append(replaced)
		else:
			gold += sell_value_for(replaced)
			sold_displaced_for_gold = true
	build_changed.emit()
	if sold_displaced_for_gold:
		run_state_changed.emit()


func unequip(slot: GearItem.SlotType) -> void:
	var removed: GearItem = equipped_item_for_slot(slot)
	if removed == null:
		return
	match slot:
		GearItem.SlotType.WEAPON:
			equipped_weapon = null
		GearItem.SlotType.HELM:
			equipped_helm = null
		GearItem.SlotType.ARMOR:
			equipped_armor = null
		GearItem.SlotType.TRINKET:
			equipped_trinket = null
		GearItem.SlotType.CHARM:
			equipped_charm = null
	if not inventory.has(removed):
		inventory.append(removed)
	build_changed.emit()


## Public so other screens (e.g. combat_screen.gd's shop/reward gear-compare
## tooltips) can look up what's currently equipped in a slot without keeping
## their own mirrored copy of this lookup.
func equipped_item_for_slot(slot: GearItem.SlotType) -> GearItem:
	match slot:
		GearItem.SlotType.WEAPON:
			return equipped_weapon
		GearItem.SlotType.HELM:
			return equipped_helm
		GearItem.SlotType.ARMOR:
			return equipped_armor
		GearItem.SlotType.TRINKET:
			return equipped_trinket
		GearItem.SlotType.CHARM:
			return equipped_charm
	return null


## Universal Phase 5 paper-doll order.
func equipped_gear() -> Array[GearItem]:
	var gear: Array[GearItem] = []
	for item in [equipped_weapon, equipped_helm, equipped_armor, equipped_trinket, equipped_charm]:
		if item != null:
			gear.append(item)
	return gear


func set_class(class_def: ClassDef) -> void:
	selected_class = class_def
	selected_trees = []
	selected_talents = []
	rotation = []
	equipped_weapon = _starter_weapon_for_class(class_def)
	build_changed.emit()


func _starter_weapon_for_class(class_def: ClassDef) -> GearItem:
	if class_def == null:
		return null
	var starter: GearItem = load(STARTER_DAGGER_PATH)
	return starter.duplicate(true) if starter != null else null


func _is_starter_weapon(gear: GearItem) -> bool:
	return gear != null and gear.id == "gear.crude_dagger"


## Picks exactly one subclass tree, clearing any other selection -- distinct
## from toggle_tree()'s multi-select (up to PassiveAllocator.MAX_TREES)
## semantics, used by the single-choice subclass_select screen.
func select_tree(tree: SubclassTree) -> void:
	selected_trees = [tree]
	var remaining: Array[Talent] = []
	for talent in selected_talents:
		if tree.talents.has(talent):
			remaining.append(talent)
	selected_talents = remaining
	_prune_rotation_to_unlocked()
	build_changed.emit()


func toggle_tree(tree: SubclassTree) -> bool:
	if selected_trees.has(tree):
		selected_trees.erase(tree)
		var remaining: Array[Talent] = []
		for talent in selected_talents:
			for kept_tree in selected_trees:
				if kept_tree.talents.has(talent):
					remaining.append(talent)
					break
		selected_talents = remaining
	elif PassiveAllocator.can_select_tree(selected_trees, tree):
		selected_trees.append(tree)
	else:
		return false
	_prune_rotation_to_unlocked()
	build_changed.emit()
	return true


func select_talent(talent: Talent) -> bool:
	if not PassiveAllocator.can_select_talent(selected_trees, selected_talents, talent, earned_talent_points):
		return false
	selected_talents.append(talent)
	_prune_rotation_to_unlocked()
	build_changed.emit()
	return true


func deselect_talent(talent: Talent) -> bool:
	if not PassiveAllocator.can_deselect_talent(selected_talents, talent):
		return false
	selected_talents.erase(talent)
	_prune_rotation_to_unlocked()
	build_changed.emit()
	return true


func set_rotation(skills: Array[Skill]) -> void:
	rotation = BuildResolver.resolve_rotation(skills, unlocked_skills())
	build_changed.emit()


func unlocked_skills() -> Array[Skill]:
	return BuildResolver.resolve_unlocked_skills(selected_class, selected_trees, selected_talents, equipped_gear())


func _prune_rotation_to_unlocked() -> void:
	var unlocked := unlocked_skills()
	var pruned := BuildResolver.resolve_rotation(rotation, unlocked)
	rotation = pruned
