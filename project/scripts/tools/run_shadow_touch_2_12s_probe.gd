extends SceneTree
const Buffs = preload("res://scripts/tools/shadow_touch_physical_12s_trial_buffs.gd")
func _initialize() -> void:
 var player := PlayerStats.new()
 player.special_effects["trial_touch_physical_per_stack"] = 2.0
 var buffs = Buffs.new(player)
 assert(buffs.initialization_error == "")
 var before: float = buffs.stats.snapshot().bonus_physical_damage
 assert(buffs.grant_touch(10,0,{}) == "")
 assert(is_equal_approx(buffs.stats.snapshot().bonus_physical_damage,before+20))
 assert(buffs.state.advance(11999) == "")
 assert(is_equal_approx(buffs.stats.snapshot().bonus_physical_damage,before+20))
 assert(buffs.state.advance(12000) == "")
 assert(is_equal_approx(buffs.stats.snapshot().bonus_physical_damage,before))
 print("Touch trial probe PASS: 10 consumed grants +20 base physical, lasts 12000ms, expires exactly at boundary")
 quit()
