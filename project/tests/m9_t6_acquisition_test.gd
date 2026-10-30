extends SceneTree
const RouteGenerator = preload("res://scripts/systems/contract_route_generator/contract_route_generator.gd")
class CollisionState extends "res://scripts/autoload/build_state.gd":
 var forced_slot := -1
 var collisions := 0
 func _shop_offer_signature(offer: GearItem) -> String:
  collisions += 1
  return "collision" if offer.slot == forced_slot else "other"
 func _generated_reward_stat_signature(offer: GearItem) -> String:
  collisions += 1
  return "collision" if offer.slot == forced_slot else "other"
class MagicFindState extends "res://scripts/autoload/build_state.gd":
 var magic_find_reads := 0
 func current_magic_find() -> float:
  magic_find_reads += 1
  return 0.5
var checks := 0
func _initialize() -> void: call_deferred("_run")
func check(value: bool, message: String) -> void:
 checks += 1
 assert(value,message)
func rng_for(seed_value: int) -> RandomNumberGenerator:
 var rng := RandomNumberGenerator.new()
 rng.seed = seed_value
 return rng
func signature(items: Array) -> String:
 var result := []
 for item in items: result.append(SaveSystem._gear_entry_to_data(item))
 return JSON.stringify(result)
func _run() -> void:
 var state = root.get_node("BuildState")
 state.reset()
 state.set_class(load("res://data/classes/rogue.tres"))
 check(state.equipped_legs == null and state.equipped_hands == null and state.equipped_gear().size()==1,"Crude-only fresh Adventure")
 var probe := CollisionState.new()
 root.add_child(probe)
 var histogram := {}
 var reward := EncounterReward.new()
 reward.generated_gear_choice_count = 3
 reward.generated_gear_tier = GearItem.Tier.CURSED
 for seed_value in 140:
  state.adventure_seed = seed_value
  var offers: Array = state._generate_tavern_shop_offers(0,false)
  check(offers.size()==state.SHOP_OFFER_COUNT,"retained shop frequency")
  check(signature(offers)==signature(state._generate_tavern_shop_offers(0,false)),"deterministic shop including provenance")
  for offer in offers: histogram[offer.slot] = true
  var choices: Array = state._gear_choices_for_reward(reward)
  check(choices.size()==3 and signature(choices)==signature(state._gear_choices_for_reward(reward)),"deterministic unrestricted rewards")
  # Adversarial signature collision: retries can never move to a different slot.
  for slots in [GearGenerator.ALL_SLOTS,[0,2],[5],[5,6]]:
   var expected_slot: int = slots[rng_for(seed_value).randi_range(0,slots.size()-1)]
   probe.forced_slot = expected_slot
   probe.collisions = 0
   var item: GearItem = probe._generate_reward_choice_item(GearItem.Tier.BASIC,slots,rng_for(seed_value),"collision",0,1,{"collision":true})
   check(item.slot==expected_slot and probe.collisions==64,"reward holds uniform eligible-slot draw across exhausted retries")
  probe.forced_slot = GearGenerator.ALL_SLOTS[rng_for(seed_value).randi_range(0,6)]
  probe.collisions = 0
  var shop: GearItem = probe._generate_unique_shop_offer(rng_for(seed_value),"collision",1,{"collision":true})
  check(shop.slot==probe.forced_slot and probe.collisions==probe.SHOP_UNIQUE_ROLL_ATTEMPTS,"shop holds uniform slot draw across exhausted retries")
 check(histogram.size()==7,"ordinary shops reach all seven slots")
 probe.queue_free()
 # Authored restrictions are intentionally retained; empty means all seven.
 for name in ["sleeping_henchman","portly_cook","patrolling_guard","door_guard","lazy_henchman","cloaked_watchmen"]:
  var node: ContractRouteNode = load("res://data/contract_routes/gilded_serpent/%s.tres"%name)
  var authored: Array = node.reward.generated_gear_slots
  check(authored.size()==2 and authored.all(func(slot): return slot in [0,1,2]),"authored two-slot restrictions retained")
  var reached := {}
  for seed_value in 20:
   state.adventure_seed = seed_value
   for item in state._gear_choices_for_reward(node.reward):
    if item.source_kind == GearItem.SourceKind.GENERATED:
     check(authored.has(item.slot),"authored reward remains within eligible subset")
     reached[item.slot]=true
  check(reached.size()==2,"both authored eligible slots reachable")
 var route_seen := {"normal":{},"elite":{},"boss":{}}
 for seed_value in 70:
  var node := ContractRouteNode.new()
  node.generated_node_id = "m9.slot.fixture"
  for role in ["normal","elite","boss"]:
   var slots: Array = RouteGenerator._reward_gear_slots(seed_value,node,role)
   check(slots.size()=={"normal":1,"elite":2,"boss":7}[role],"generated reward subset counts retained")
   var distinct := {}
   for slot in slots:
    distinct[slot]=true
    route_seen[role][slot]=true
   check(distinct.size()==slots.size(),"route subset without replacement")
   check(slots==RouteGenerator._reward_gear_slots(seed_value,node,role),"route subset deterministic")
 for role in route_seen: check(route_seen[role].size()==7,"each generated role reaches all seven slots: "+role)
 check(RouteGenerator._reward_gear_slots(4,ContractRouteNode.new(),"boss")==GearGenerator.ALL_SLOTS,"boss eligible slots retain universal order")
 # MF is snapshotted once per acquisition batch, before rolling its offers.
 var mf_probe := MagicFindState.new()
 root.add_child(mf_probe)
 mf_probe.reset()
 mf_probe.set_class(load("res://data/classes/rogue.tres"))
 mf_probe.adventure_seed = 887
 mf_probe._generate_tavern_shop_offers(0,false)
 check(mf_probe.magic_find_reads==1,"shop takes one MF snapshot for entire offer batch")
 mf_probe.magic_find_reads=0
 mf_probe._gear_choices_for_reward(reward)
 check(mf_probe.magic_find_reads==1,"reward takes one MF snapshot for entire choice batch")
 mf_probe.queue_free()
 # Pending generated items survive independent save decoding and ordinary transactions.
 state.reset()
 state.set_class(load("res://data/classes/rogue.tres"))
 state.adventure_seed = 887
 var pants := GearGenerator.generate(GearItem.Tier.CURSED,5,rng_for(77),"m9.pending.pants")
 var gloves := GearGenerator.generate(GearItem.Tier.UNIQUE,6,rng_for(88),"m9.pending.gloves")
 state.pending_reward_choices.assign([pants])
 state.shop_round_pending = true
 state.shop_offers.assign([gloves])
 state.gold=1000
 var saved_signature := signature([pants,gloves])
 check(SaveSystem.save_run(state),SaveSystem.last_error)
 state.reset()
 check(SaveSystem.load_run_result(state).status=="loaded","pending Adventure reload")
 check(signature([state.pending_reward_choices[0],state.shop_offers[0]])==saved_signature,"pending exact affixes/provenance survive")
 check(state.pending_reward_choices[0]!=pants and state.shop_offers[0]!=gloves,"pending resources detached")
 var loaded_gloves: GearItem = state.shop_offers[0]
 var price: int = state.shop_purchase_price_for(loaded_gloves)
 check(price==70 and state.buy_shop_offer(loaded_gloves) and state.gold==1000-price,"new-slot purchase retained pricing/payment")
 check(not state.buy_shop_offer(loaded_gloves),"offer cannot be purchased twice")
 var loaded_pants: GearItem = state.pending_reward_choices[0]
 check(state.choose_pending_reward_gear(loaded_pants) and not state.has_pending_reward_choice(),"new-slot reward claim consumes pending offer")
 check(not state.choose_pending_reward_gear(loaded_pants),"reward cannot claim twice")
 check(state.equipped_legs==null and state.equipped_hands==null,"ordinary acquisitions wait for player equip")
 check(state.equip_from_inventory(loaded_gloves) and state.equip_from_inventory(loaded_pants),"player equips both slots")
 check(SaveSystem.save_run(state),SaveSystem.last_error)
 state.reset()
 check(SaveSystem.load_run_result(state).status=="loaded" and state.equipped_legs.id==pants.id and state.equipped_hands.id==gloves.id,"acquired/equipped round trip")
 var practice := TrainingRoomState.new()
 practice.content_registry = BuildContentRegistry.test_mode()
 practice.set_class(load("res://data/classes/rogue.tres"))
 practice.practice_legs = pants
 practice.practice_hands = gloves
 practice._equip_practice_item(pants)
 practice._equip_practice_item(gloves)
 check(PracticeSaveSystem.save_setup(practice),PracticeSaveSystem.last_error)
 var second := TrainingRoomState.new()
 second.content_registry = practice.content_registry
 check(PracticeSaveSystem.load_setup(second).status=="loaded",PracticeSaveSystem.last_error)
 check(signature([second.equipped_legs,second.equipped_hands])==signature([practice.equipped_legs,practice.equipped_hands]),"Practice generated item round trip")
 check(LegendaryCatalog.all_paths().size()==20,"integrated fixed Legendary catalog contains twenty")
 print("M9 T6 acquisition PASS (%d checks)"%checks)
 quit()
