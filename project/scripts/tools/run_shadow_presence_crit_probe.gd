extends SceneTree
const Buffs = preload("res://scripts/tools/shadow_presence_crit_trial_self_buffs.gd")
func _initialize() -> void:
 Buffs.presence_crit_per_stack = 0.01
 var buffs = Buffs.new()
 buffs.grant("beguiling_presence",0,{"source_id":"skill.beguiling_presence"},20.0,20)
 assert(is_equal_approx(buffs.values().crit_chance,0.2))
 assert(is_equal_approx(buffs.values().elemental_base,20.0))
 buffs.advance(9999)
 assert(is_equal_approx(buffs.values().crit_chance,0.2))
 buffs.advance(10000)
 assert(is_zero_approx(buffs.values().crit_chance) and is_zero_approx(buffs.values().elemental_base))
 print("Presence crit trial probe PASS: actual 20 consumed grants +20 percentage points and +20 elemental base; both expire at 10000ms")
 quit()
