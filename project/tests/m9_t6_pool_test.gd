extends SceneTree
# Frozen approved T3/D008 input, independent of the runtime catalog.
const EXPECTED = [{"slot":"legs","category":"basic","stat_id":"percent_physical_damage","min":0.1,"max":0.2,"weight":1},{"slot":"legs","category":"basic","stat_id":"crit_damage","min":0.5,"max":0.75,"weight":1},{"slot":"legs","category":"basic","stat_id":"base_elemental_damage","min":3.0,"max":6.0,"weight":1},{"slot":"legs","category":"basic","stat_id":"percent_elemental_damage","min":0.3,"max":0.4,"weight":1},{"slot":"legs","category":"basic","stat_id":"increased_gold","min":0.2,"max":0.3,"weight":1},{"slot":"legs","category":"basic","stat_id":"increased_magic_find","min":0.15,"max":0.3,"weight":1},{"slot":"legs","category":"rare","stat_id":"chance_for_retrigger","min":0.03,"max":0.06,"weight":15},{"slot":"legs","category":"rare","stat_id":"crit_applies_element","min":0.1,"max":0.2,"weight":10},{"slot":"legs","category":"rare","stat_id":"crit_applies_potency","min":0.1,"max":0.15,"weight":10},{"slot":"legs","category":"rare","stat_id":"crit_applies_penetration","min":0.1,"max":0.15,"weight":10},{"slot":"legs","category":"rare","stat_id":"increased_buff_duration","min":0.1,"max":0.2,"weight":8},{"slot":"legs","category":"rare","stat_id":"cooldown_reduction","min":0.06,"max":0.1,"weight":8},{"slot":"legs","category":"rare","stat_id":"shop_discount","min":0.1,"max":0.2,"weight":5},{"slot":"legs","category":"rare","stat_id":"increased_magic_find","min":0.1,"max":0.2,"weight":5},{"slot":"legs","category":"rare","stat_id":"increased_gold","min":0.5,"max":1.0,"weight":5},{"slot":"legs","category":"special","stat_id":"all_stats_increased","min":1.0,"max":1.0,"weight":5},{"slot":"legs","category":"special","stat_id":"disable_enemy_dodge","min":1.0,"max":1.0,"weight":10},{"slot":"legs","category":"special","stat_id":"disable_enemy_block","min":1.0,"max":1.0,"weight":10},{"slot":"legs","category":"special","stat_id":"disable_enemy_absorb","min":1.0,"max":1.0,"weight":10},{"slot":"legs","category":"special","stat_id":"disable_enemy_suppress","min":1.0,"max":1.0,"weight":10},{"slot":"legs","category":"special","stat_id":"disable_enemy_cleanse","min":1.0,"max":1.0,"weight":10},{"slot":"legs","category":"special","stat_id":"immune_to_stun","min":1.0,"max":1.0,"weight":5},{"slot":"legs","category":"special","stat_id":"immune_to_slow","min":1.0,"max":1.0,"weight":5},{"slot":"legs","category":"special","stat_id":"immune_to_interrupt","min":1.0,"max":1.0,"weight":5},{"slot":"legs","category":"special","stat_id":"inventory_economy_stats","min":1.0,"max":1.0,"weight":5},{"slot":"hands","category":"basic","stat_id":"base_damage","min":2.0,"max":5.0,"weight":1},{"slot":"hands","category":"basic","stat_id":"percent_physical_damage","min":0.15,"max":0.25,"weight":1},{"slot":"hands","category":"basic","stat_id":"crit_chance","min":0.06,"max":0.08,"weight":1},{"slot":"hands","category":"basic","stat_id":"crit_damage","min":0.5,"max":0.75,"weight":1},{"slot":"hands","category":"basic","stat_id":"base_elemental_damage","min":3.0,"max":6.0,"weight":1},{"slot":"hands","category":"basic","stat_id":"percent_elemental_damage","min":0.3,"max":0.4,"weight":1},{"slot":"hands","category":"basic","stat_id":"increased_gold","min":0.15,"max":0.3,"weight":1},{"slot":"hands","category":"basic","stat_id":"increased_magic_find","min":0.1,"max":0.2,"weight":1},{"slot":"hands","category":"rare","stat_id":"chance_for_retrigger","min":0.03,"max":0.06,"weight":15},{"slot":"hands","category":"rare","stat_id":"chance_to_shred","min":0.08,"max":0.1,"weight":10},{"slot":"hands","category":"rare","stat_id":"chance_to_decay","min":0.08,"max":0.1,"weight":10},{"slot":"hands","category":"rare","stat_id":"crit_applies_element","min":0.12,"max":0.18,"weight":15},{"slot":"hands","category":"rare","stat_id":"increased_buff_duration","min":0.08,"max":0.14,"weight":8},{"slot":"hands","category":"rare","stat_id":"cooldown_reduction","min":0.06,"max":0.1,"weight":8},{"slot":"hands","category":"special","stat_id":"convert_damage_to_physical","min":1.0,"max":1.0,"weight":5},{"slot":"hands","category":"special","stat_id":"convert_damage_to_magical","min":1.0,"max":1.0,"weight":5},{"slot":"hands","category":"special","stat_id":"ignore_armor_no_shred","min":1.0,"max":1.0,"weight":5},{"slot":"hands","category":"special","stat_id":"ignore_resistance_physical_penalty","min":1.0,"max":1.0,"weight":5},{"slot":"hands","category":"special","stat_id":"double_applied_stacks","min":1.0,"max":1.0,"weight":5},{"slot":"hands","category":"special","stat_id":"disable_enemy_dodge","min":1.0,"max":1.0,"weight":10},{"slot":"hands","category":"special","stat_id":"disable_enemy_block","min":1.0,"max":1.0,"weight":10},{"slot":"hands","category":"special","stat_id":"disable_enemy_absorb","min":1.0,"max":1.0,"weight":10},{"slot":"hands","category":"special","stat_id":"disable_enemy_suppress","min":1.0,"max":1.0,"weight":10},{"slot":"hands","category":"special","stat_id":"disable_enemy_cleanse","min":1.0,"max":1.0,"weight":10}]
var checks := 0
func _initialize() -> void:
 call_deferred("_run")
func check(value: bool, message: String) -> void:
 checks += 1
 assert(value, message)
func generate(slot: int, tier: int, seed_value: int, scale_value := 1.0, depth := 1) -> GearItem:
 return GearGenerator.generate_from_request({"slot":slot,"tier":tier,"seed":seed_value,"id":"m9.fixture","value_scale":scale_value,"contract_depth":depth}).get("item")
func signature(item: GearItem) -> String:
 return JSON.stringify(SaveSystem._gear_entry_to_data(item))
func _run() -> void:
 check(GearGenerator.ALL_SLOTS == GearItem.universal_slot_order(), "stable seven-slot acquisition order")
 check(GearGenerator.PHASE5_ALL_SLOTS == GearItem.universal_slot_order(), "compatibility acquisition order")
 var positives := 0
 var drawbacks := 0
 for slot in GearItem.universal_slot_order():
  for category in ["basic", "rare", "special"]:
   var pool := StatCatalog.pool_for_slot(slot, category)
   positives += pool.size()
   if category == "basic":
    for entry in pool: check(entry.weight == 1, "equal Basic weights in all seven slots")
   if slot < 5: continue
   var expected: Array = EXPECTED.filter(func(row): return row.slot == ("legs" if slot == 5 else "hands") and row.category == category)
   check(pool.size() == expected.size(), "exact new pool size")
   for i in expected.size():
    var row: Dictionary = expected[i]
    check(pool[i].stat_id == row.stat_id and pool[i].weight == row.weight, "exact order/ID/weight")
    if category != "special":
     var bounds := StatCatalog.value_range_for_slot_category(slot, category, row.stat_id)
     check(bounds.ok and bounds.min == row.min and bounds.max == row.max, "category-specific approved range")
  var negative := StatCatalog.drawback_pool_for_slot(slot)
  drawbacks += negative.size()
  check(negative == StatCatalog.pool_for_slot(slot,"basic"), "only Basic drawbacks")
 check(positives == 148 and drawbacks == 47, "148 positive / 47 drawback rows")
 var chaos_duplicate := false
 var chaos_opposite := false
 var chaos_all_negative := false
 for slot in [5,6]:
  for tier in GearGenerator.ACTIVE_GENERATED_TIERS:
   for seed_value in 300:
    var item := generate(slot,tier,seed_value)
    check(item != null, "all new-slot ordinary rarity requests succeed")
    if seed_value < 5: check(signature(item) == signature(generate(slot,tier,seed_value)), "deterministic complete item and provenance")
    check(item.affixes.size() == {0:1,1:2,5:3,2:4,6:4,7:5}[tier], "retained rarity shape")
    var ids := {}
    var negative_count := 0
    for m in item.affixes:
     var id := StatCatalog.canonical_id_for_modifier(m)
     var category: String = "basic" if m.is_drawback or m.category == StatModifier.StatCategory.BASIC else ("special" if m.category == StatModifier.StatCategory.SPECIAL else "rare")
     check(StatCatalog.is_stat_enabled_for_slot(slot,category,id), "enabled category membership")
     check(m.operation == StatModifier.OperationType.ADD, "ADD operation")
     if ids.has(id):
      if tier == GearItem.Tier.CHAOS:
       chaos_duplicate = true
       chaos_opposite = chaos_opposite or (ids[id] != m.is_drawback)
      else: check(false, "ordinary canonical uniqueness crosses categories and signs")
     ids[id] = m.is_drawback
     if m.is_drawback:
      negative_count += 1
      check(m.value < 0 and m.category == StatModifier.StatCategory.DRAWBACK, "negative signed metadata")
     elif category == "special": check(m.value == 1, "binary Specials stay one")
     else: check(m.value > 0, "positive affix")
    if tier == GearItem.Tier.CHAOS: chaos_all_negative = chaos_all_negative or negative_count == 4
    else: check(negative_count == (1 if tier == GearItem.Tier.CURSED else 0), "retained Cursed-only drawback")
  for tier in [GearItem.Tier.CRUDE,GearItem.Tier.LEGENDARY]: check(generate(slot,tier,1) == null,"starter/catalog boundary")
 check(chaos_duplicate and chaos_opposite and chaos_all_negative,"Chaos replacement permits duplicates/opposing signs/all negative")
 for row in EXPECTED:
  if row.category == "special": continue
  var slot := 5 if row.slot == "legs" else 6
  for tier in GearGenerator.ACTIVE_GENERATED_TIERS:
   var result := GearGenerator.max_rolled_value_for_stat_id(row.stat_id,slot,false,tier,2.0,12,row.category)
   var multiplier: float = {0:1.0,1:1.75,5:2.0,2:2.5,6:3.0,7:2.0}[tier]
   var raw: float = row.max * multiplier * 2.0 * 1.35
   var expected: float = 1 if row.category == "special" else (round(raw) if StatCatalog.value_kind_for(row.stat_id) == StatCatalog.VALUE_FLAT else round(raw*100)/100)
   check(result.ok and is_equal_approx(result.value,expected),"retained scaling/rounding/category override")
 # Explicit overlapping economy witnesses cover both signs and category overrides.
 for slot in [5,6]:
  for drawback in [false,true]:
   var rng := RandomNumberGenerator.new()
   rng.seed=90
   var result := GearGenerator._make_modifier_from_stat_id("increased_magic_find","basic",drawback,GearItem.Tier.CURSED,slot,rng,1.0,1)
   check(result.ok,"new-slot Basic MF forced witness")
   var m: StatModifier = result.modifier
   check(m.is_drawback==drawback and (m.value<0 if drawback else m.value>0),"Basic MF sign")
   check(m.category==(StatModifier.StatCategory.DRAWBACK if drawback else StatModifier.StatCategory.BASIC),"global Rare label does not override Basic MF metadata")
  for invalid_scale in [0.0,-1.0,INF,NAN]:
   check(generate(slot,GearItem.Tier.BASIC,4,invalid_scale)==null,"new-slot invalid request scale rejected")
  check(signature(generate(slot,GearItem.Tier.UNIQUE,4,1.0,0))==signature(generate(slot,GearItem.Tier.UNIQUE,4,1.0,0)),"determinism at low depth")
  check(GearGenerator._contract_depth_value_scale(-4)==GearGenerator._contract_depth_value_scale(1) and GearGenerator._contract_depth_value_scale(100)==GearGenerator._contract_depth_value_scale(12),"depth factor clamps")
 for id in ["increased_gold","increased_magic_find"]:
  for category in ["basic","rare"]:
   var rng := RandomNumberGenerator.new()
   var mirror := RandomNumberGenerator.new()
   rng.seed=81
   mirror.seed=81
   var row: Dictionary = EXPECTED.filter(func(entry):return entry.slot=="legs" and entry.category==category and entry.stat_id==id)[0]
   var expected_value: float = round(mirror.randf_range(row.min,row.max)*100)/100
   var actual := GearGenerator._make_modifier_from_stat_id(id,category,false,GearItem.Tier.BASIC,5,rng,1.0,1)
   check(actual.ok and is_equal_approx(actual.modifier.value,expected_value),"Pants overlapping economy selects exact category range")
  for second in [{"category":"rare","forced_stat_id":id},{"category":"basic","is_drawback":true,"forced_stat_id":id}]:
   var errors := GearGenerator._validate_roll_plan_for_slot(5,[{"category":"basic","forced_stat_id":id},second])
   check(not errors.is_empty(),"ordinary gold/MF cannot duplicate across categories or signs")
   check(GearGenerator._validate_roll_plan_for_slot(5,[{"category":"basic","forced_stat_id":id},second],true).is_empty(),"Chaos permits overlapping gold/MF across categories or signs")
 print("M9 T6 pool PASS (%d checks)" % checks)
 quit()
