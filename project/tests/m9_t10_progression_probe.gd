extends SceneTree
## Bounded earned-run observation, not a balance optimizer.
const OUT := "res://reports/m9_t10_probe"
var state
var registry
var build_name := "bladedancer"
var run_seed := 101
var arm := "seven_current"
var variant := "fixed"
var events := []
var fights := []
var checkpoints := []
var failures := []
var stage := "T0"
var opportunity := 0
var stop_reason := "horizon"
var upgrades := {}
var tracked_gear := {}
const PRIORITY := {
 "bladedancer": ["wet_stone", "precision_attacks", "weakness", "sharpened_edge", "rending_slash", "double_dip", "weapon_master", "fancy_footwork", "riposte", "opportunity", "cloak_and_dagger"],
 "assassin": ["hastened_poison", "precision", "quick_hands", "echoing_toxin", "poison_strike", "bypass", "accelerant", "toxic_tradeoff", "resonance", "critical_poison"]
}
func _initialize() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--build="): build_name = arg.trim_prefix("--build=")
  if arg.begins_with("--seed="): run_seed = int(arg.trim_prefix("--seed="))
  if arg.begins_with("--arm="): arm = arg.trim_prefix("--arm=")
  if arg.begins_with("--variant="): variant = arg.trim_prefix("--variant=")
 SaveSystem.session_only = true
 call_deferred("run")
func check(ok: bool, message: String) -> bool:
 if not ok: failures.append(message)
 return ok
func log_event(action: String, before: int, extra: Dictionary = {}) -> void:
 var row := {"action": action, "stage": stage, "fight_opportunity": fights.size(), "reward_opportunity": opportunity, "gold_before": before, "gold_after": state.gold, "delta": state.gold-before}
 var changes := []
 var now := {}
 for item in state.equipped_gear():
  var slot := str(int(item.slot))
  var serialized = SaveSystem._gear_entry_to_data(item)
  now[slot]=serialized
  if JSON.stringify(tracked_gear.get(slot)) != JSON.stringify(serialized):
   changes.append({"slot":int(item.slot),"before":tracked_gear.get(slot),"after":serialized,"first_fill":not tracked_gear.has(slot)})
   upgrades[slot]=int(upgrades.get(slot,0))+1
 tracked_gear=now
 row["equipment_changes"]=changes
 row.merge(extra)
 events.append(row)
 check(state.gold >= 0, "negative gold")
func run() -> void:
 registry = BuildContentRegistry.adventure()
 state = root.get_node("BuildState")
 state.reset()
 state.set_adventure_seed(run_seed)
 state.set_class(registry.classes["class.rogue"])
 check(state.configure_ranked_build(registry.trees["tree."+build_name]), "configure primary")
 for item in state.equipped_gear(): tracked_gear[str(int(item.slot))]=SaveSystem._gear_entry_to_data(item)
 var alive := true
 for index in 4:
  stage = "T"+str(index)
  spend_points()
  if not check(state.choose_current_tavern_encounter(), "choose Tavern"): break
  if not fight():
   alive = false
   break
  reward()
  if index == 3: checkpoint("Tavern_complete")
 if alive and failures.is_empty():
  for depth in range(1,14):
   stage = "C"+str(depth)
   spend_points()
   if state.needs_secondary_subclass_choice():
    var offered: Array = state.secondary_subclass_choices()
    check(not offered.is_empty(), "secondary offer empty")
    if not offered.is_empty(): check(state.choose_secondary_tree(offered[0]), "first offered secondary")
   spend_points()
   if not check(state.accept_contract_offer(), "accept contract"): break
   var terminal := false
   while not terminal and failures.is_empty():
    var choices: Array = state.current_route_node.next_nodes
    if not check(not choices.is_empty(), "connected route"): break
    if not check(state.choose_contract_route_node(choices[0]), "choose first route"): break
    terminal = state.current_route_node.next_nodes.is_empty()
    if not fight():
     alive = false
     break
    reward()
   if not alive: break
   if depth in [1,3,6,10,13]: checkpoint(stage+"_complete")
 if not alive: stop_reason = "earned_encounter_loss_or_retry_cap"
 if not failures.is_empty(): stop_reason = "validity_failure"
 checkpoint("final")
 DirAccess.make_dir_recursive_absolute(OUT)
 SaveSystem.write_json(OUT+"/%s_%s_%d.json"%[arm,build_name,run_seed], {"schema":1,"arm":arm,"build":build_name,"seed":run_seed,"stop_reason":stop_reason,"completed_contracts":state.completed_contract_count,"last_stage":stage,"gold":state.gold,"earned_points":state.earned_talent_points,"variant":variant,"ending_run_phase":state.run_phase,"ending_run_outcome":state.run_outcome,"can_retry_at_stop":state.can_retry_current_encounter(),"events":events,"fights":fights,"checkpoints":checkpoints,"validity_failures":failures,"slot_upgrade_counts":upgrades,"user_data_dir":OS.get_user_data_dir()})
 print("PROBE_COMPLETE ", arm," ",build_name," ",run_seed," contracts=",state.completed_contract_count," fights=",fights.size()," failures=",failures)
 quit(0 if failures.is_empty() else 1)
func spend_points() -> void:
 for iteration in 45:
  if state.ranked_build.unspent_points() <= 0: break
  var spent := false
  for tree in state.ranked_build.trees():
   var ordered := []
   for suffix in PRIORITY.get(tree.id.trim_prefix("tree."),[]):
    for talent in tree.talents:
     if talent.id.ends_with("."+suffix): ordered.append(talent)
   for talent in tree.talents:
    if not ordered.has(talent): ordered.append(talent)
   for talent in ordered:
    if state.select_talent(talent):
     spent = true
     break
   if spent: break
  if not spent: break
 check(state.ranked_build.points_spent() <= state.earned_talent_points, "unearned point allocation")
func resolve(gear: Array[GearItem], bank: int, carried: Array[GearItem]) -> Dictionary:
 return BuildResolver.resolve_ranked_build(state.selected_class,state.ranked_build,gear,bank,carried)
func macro(content: Dictionary) -> Array[Skill]:
 var ids: Array = ["quick_cut", "stab", "quick_cut", "heavy_slash"] if build_name == "bladedancer" else ["venom_jab", "venom_jab", "poison_strike"]
 if variant == "mixed_rotation" and build_name == "assassin": ids = ["venom_jab", "stab", "heavy_slash"]
 var selected: Array[Skill] = []
 for id in ids:
  for skill in content.skills:
   if skill.id == "skill."+id: selected.append(skill)
 if selected.is_empty():
  for skill in content.skills:
   if skill.id != "skill.hold":
    selected.append(skill)
    break
 return selected
func evaluate(gear: Array[GearItem], bank: int, carried: Array[GearItem], seed_value: int = 701):
 var content := resolve(gear,bank,carried)
 if not check(content.get("error", "") == "", "build derivation"): return null
 var result = CombatResolver.resolve(macro(content),content.stats,state.current_target_monster(),state.current_target_duration_ms(),seed_value)
 check(result.is_valid, "invalid resolver "+str(result.failure))
 return result
func replacement(item: GearItem, bank: int):
 var gear: Array[GearItem] = state.equipped_gear().duplicate()
 for old in gear.duplicate():
  if old.slot == item.slot: gear.erase(old)
 gear.append(item)
 var carried: Array[GearItem] = state.inventory.duplicate()
 carried.erase(item)
 return evaluate(gear,bank,carried)
func fight() -> bool:
 for attempt in 2:
  var content := resolve(state.equipped_gear(),state.gold,state.inventory)
  var rotation := macro(content)
  check(not rotation.is_empty(), "empty macro")
  state.set_rotation(rotation)
  state.set_locked(true)
  var seed_value: int = state.current_combat_rng_seed()
  var before: int = state.gold
  if not check(state.start_fight(), "start legal fight"): return false
  var result = CombatResolver.resolve(rotation,content.stats,state.current_target_monster(),state.current_target_duration_ms(),seed_value)
  var again = CombatResolver.resolve(rotation,content.stats,state.current_target_monster(),state.current_target_duration_ms(),seed_value,true)
  check(result.is_valid, "invalid actual combat "+str(result.failure))
  check(result.total_damage == again.total_damage and result.is_win == again.is_win and result.rng_final_state == again.rng_final_state, "combat determinism")
  var ids := []
  for skill in rotation: ids.append(skill.id)
  var max_root_budget := 0
  var budget_kinds := {}
  for record in again.trace.records:
   if record.payload.has("budget_consumed"):
    var consumed := int(record.payload.budget_consumed)
    max_root_budget=maxi(max_root_budget,consumed)
    budget_kinds[record.kind]=maxi(int(budget_kinds.get(record.kind,0)),consumed)
  var poison_tick_damage := 0.0
  for tick in result.tick_events: poison_tick_damage += tick.damage
  var monster_stats := {}
  for field in ["id","hp","armor","poison_resistance","dodge_chance","crit_negation","block","absorb","cleanse_threshold","suppress","slow","stun_duration_ms","interrupt_skip_count"]: monster_stats[field]=state.current_target_monster().get(field)
  var max_depth := 0
  for cast in result.cast_events: max_depth = maxi(max_depth,cast.retrigger_depth)
  var row := {"stage":stage,"key":state._current_fight_key(),"attempt":attempt+1,"combat_seed":seed_value,"gold":before,"gear":SaveSystem._gear_list_to_data(state.equipped_gear()),"carried":SaveSystem._gear_list_to_data(state.inventory),"ranks":state.ranked_build.rank_map(),"earned_points":state.earned_talent_points,"spent_points":state.ranked_build.points_spent(),"macro":ids,"monster":state.current_target_monster().id,"hp":state.current_target_monster().hp,"nominal_ms":state.current_target_duration_ms(),"elapsed_ms":result.duration_ms,"damage":result.total_damage,"health_removed":result.total_health_removed,"dps":result.dps,"required_dps":float(state.current_target_monster().hp)/maxf(0.001,result.duration_ms/1000.0),"margin":result.total_health_loss()-state.current_target_monster().hp,"win":result.is_win,"valid":result.is_valid,"failure":result.failure,"candidates_total":result.trigger_candidates_evaluated,"last_root_candidates":result.root_trigger_candidates,"max_depth":max_depth,"stolen_gold":result.gold_stolen,"overkill":result.overkill_damage,"overkill_gold":state.overkill_gold_for_result(result),"seed_replay_equal":result.total_damage==again.total_damage and result.rng_final_state==again.rng_final_state}
  if stage in ["T3","C1","C3","C6","C10","C13"] and attempt == 0:
   var marginals := {}
   for slot in [5,6]:
    var removed: Array[GearItem] = state.equipped_gear().duplicate()
    for item in removed.duplicate():
     if int(item.slot) == slot: removed.erase(item)
    var minus = evaluate(removed,before,state.inventory,seed_value)
    marginals[str(slot)] = {"damage_without":minus.total_damage,"damage_delta":result.total_damage-minus.total_damage,"win_without":minus.is_win}
   row["new_slot_marginals"] = marginals
  row["monster_stats"]=monster_stats
  row["max_root_budget_consumed"]=max_root_budget
  row["budget_event_kind_maxima"]=budget_kinds
  row["poison_tick_damage"]=poison_tick_damage
  row["poison_tick_damage_share"]=poison_tick_damage/maxf(0.001,result.total_damage)
  fights.append(row)
  if not result.is_valid: return false
  state.record_combat_stolen_gold(result.gold_stolen)
  log_event("theft",before,{"amount":result.gold_stolen})
  state.record_fight_result(result,state.current_target_monster())
  state.finish_fight(result.is_win)
  row["run_phase_after"] = state.run_phase
  row["run_outcome_after"] = state.run_outcome
  row["can_retry_after"] = state.can_retry_current_encounter()
  if result.is_win: return true
  if attempt == 1 or not state.can_retry_current_encounter(): return false
  check(state.retry_current_encounter(), "legal retry")
 return false
func tidy() -> void:
 for item in state.inventory.duplicate():
  var current = evaluate(state.equipped_gear(),state.gold,state.inventory)
  var candidate = replacement(item,state.gold)
  if candidate.total_health_loss() > current.total_health_loss()+0.0001:
   var before: int = state.gold
   var old: GearItem = state.equipped_item_for_slot(item.slot)
   check(state.equip_from_inventory(item), "equip owned")
   log_event("equip",before,{"item":SaveSystem._gear_entry_to_data(item),"first_fill":old==null,"score_gain":candidate.total_health_loss()-current.total_health_loss()})
 for item in state.inventory.duplicate():
  var content := resolve(state.equipped_gear(),state.gold,state.inventory)
  var without: Array[GearItem] = state.inventory.duplicate()
  without.erase(item)
  var stripped := resolve(state.equipped_gear(),state.gold,without)
  # Retain useful carried economy. Never cycle buy/sell for profit.
  if content.stats.gold_reward_multiplier > stripped.stats.gold_reward_multiplier or content.stats.shop_discount > stripped.stats.shop_discount or content.stats.magic_find > stripped.stats.magic_find: continue
  var before: int = state.gold
  var price: int = state.sell_value_for(item)
  check(state.sell_inventory_item(item), "sell carried")
  log_event("sale",before,{"price":price,"item":SaveSystem._gear_entry_to_data(item)})
func reward() -> void:
 opportunity += 1
 var before: int = state.gold
 var expected: int = state.current_modified_reward_gold()
 var overkill: int = state.overkill_gold_for_result(state.last_combat_result)
 check(state.claim_current_reward(), "claim earned reward")
 check(state.gold == before+expected, "reward accounting")
 log_event("reward",before,{"amount":expected,"overkill_gold":overkill,"points":state.earned_talent_points})
 tidy()
 var best: GearItem = null
 var score: float = evaluate(state.equipped_gear(),state.gold,state.inventory).total_health_loss()
 for item in state.pending_reward_choices:
  var candidate_score := -1.0
  if not item.is_unidentified: candidate_score = replacement(item,state.gold).total_health_loss()
  log_event("reward_offer",state.gold,{"item":SaveSystem._gear_entry_to_data(item),"candidate_score":candidate_score,"equipped_score":score})
  if candidate_score > score+0.0001:
   best=item
   score=candidate_score
 if best != null:
  before=state.gold
  check(state.choose_pending_reward_gear(best), "choose offered reward")
  log_event("choose_reward",before,{"item":SaveSystem._gear_entry_to_data(best)})
  tidy()
 elif state.has_pending_reward_choice(): check(state.skip_pending_reward_gear(),"skip reward")
 if state.should_open_shop_after_current_reward() and not state.is_last_tavern_reward():
  check(state.open_shop_round(), "open earned shop")
  for round_index in 2:
   for item in state.shop_offers.duplicate():
    var price: int = state.shop_purchase_price_for(item)
    var baseline: float = evaluate(state.equipped_gear(),state.gold,state.inventory).total_health_loss()
    var value := -1.0
    if not item.is_unidentified and price <= state.gold: value=replacement(item,state.gold-price).total_health_loss()
    log_event("shop_offer",state.gold,{"item":SaveSystem._gear_entry_to_data(item),"price":price,"affordable":price<=state.gold,"candidate_score":value,"equipped_score":baseline,"reroll":round_index})
    if value > baseline+0.0001 and state.can_store_shop_offer(item):
     before=state.gold
     check(state.buy_shop_offer(item), "buy affordable improvement")
     log_event("buy",before,{"price":price,"item":SaveSystem._gear_entry_to_data(item)})
     tidy()
   if round_index == 1 or state.gold < state.shop_reroll_cost+18: break
   before=state.gold
   if not state.reroll_shop_offers(): break
   log_event("reroll",before)
  check(state.close_shop_round(), "close shop")
 check(state.continue_after_win(), "continue earned victory")
func checkpoint(label: String) -> void:
 checkpoints.append({"label":label,"fight_opportunity":fights.size(),"reward_opportunity":opportunity,"gold":state.gold,"points":state.earned_talent_points,"completed_contracts":state.completed_contract_count,"gear":SaveSystem._gear_list_to_data(state.equipped_gear()),"carried":SaveSystem._gear_list_to_data(state.inventory),"upgrades":upgrades.duplicate()})



