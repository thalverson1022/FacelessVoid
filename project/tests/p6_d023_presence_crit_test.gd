extends SceneTree
const Buffs = preload("res://scripts/systems/combat_self_buffs.gd")
const Contracts = preload("res://scripts/systems/p6_status_skill_contracts.gd")
const Formatter = preload("res://scripts/ui/skill_tooltip_formatter.gd")
var failed := false
func _initialize() -> void:
 call_deferred("run")
func check(ok: bool, label: String) -> void:
 if not ok:
  failed = true
  printerr("FAILED: "+label)
func run() -> void:
 var buffs = Buffs.new()
 buffs.grant("beguiling_presence",0,{},20.0,20)
 buffs.grant("beguiling_presence",1000,{},10.0,10)
 check(is_equal_approx(buffs.values().crit_chance,0.6) and buffs.values().elemental_base == 30,"Independent consumed-count crit and elemental bonuses add")
 buffs.advance(9999)
 check(is_equal_approx(buffs.values().crit_chance,0.6),"Presence active before exact deadline")
 buffs.advance(10000)
 check(is_equal_approx(buffs.values().crit_chance,0.2) and buffs.values().elemental_base == 10,"First instance expires both bonuses independently")
 buffs.advance(11000)
 check(is_zero_approx(buffs.values().crit_chance) and is_zero_approx(buffs.values().elemental_base),"All Presence bonuses expire")
 var decay := Skill.new()
 decay.id = "test.decay"
 decay.base_execution_ms = 500
 decay.min_execution_ms = 500
 decay.effects.append(PoisonResistanceReductionEffect.new())
 var presence = Contracts.skill("beguiling_presence")
 var stab: Skill = load("res://data/skills/stab.tres").duplicate(true)
 stab.base_execution_ms = 1000
 stab.min_execution_ms = 1000
 var hold := Skill.new()
 hold.id = "test.long_hold"
 hold.category = Skill.Category.SELF_BUFF
 hold.base_execution_ms = 11000
 hold.min_execution_ms = 11000
 var enemy := Monster.new()
 enemy.hp = 100000000
 var player := PlayerStats.new()
 player.weapon_damage_min = 20
 player.weapon_damage_max = 20
 player.crit_chance = 0.15
 for extra in [9,49]:
  player.bonus_decay_stacks = extra
  var result = CombatResolver.resolve([decay,presence,stab,hold,stab],player,enemy,14000,1,true)
  check(result.is_valid,"Live Presence combat resolves")
  var hits := []
  for event in result.cast_events:
   if event.skill.id == "skill.stab": hits.append(event)
  check(hits.size()==2,"Attack before and after Presence expiry")
  if hits.size()==2:
   check(is_equal_approx(hits[0].stat_snapshot.effective_crit_chance,clampf(0.15+0.02*(extra+1),0,1)),"Presence actual consumed count adds crit and caps at 100 percent")
   check(is_equal_approx(hits[1].stat_snapshot.effective_crit_chance,0.15),"Crit chance returns to baseline after 10 seconds")
   if extra==49: check(hits[0].is_crit,"100 percent crit applies to actual attack")
  check(is_equal_approx(player.crit_chance,0.15),"Presence never mutates input build")
 player.bonus_decay_stacks=9
 player.critical_poison_enabled=true
 var fuel = Contracts.skill("poison_vile")
 fuel.base_execution_ms=500
 var ticks = CombatResolver.resolve([decay,presence,fuel],player,enemy,2200,1,true)
 var fueled := false
 for tick in ticks.tick_events:
  if tick.stacks_consumed>0:
   fueled=true
   check(is_equal_approx(tick.crit_chance,0.35),"Presence applies to eligible critical Poison ticks")
 check(fueled,"Fueled tick observed")
 player.critical_poison_enabled=false
 var normal = CombatResolver.resolve([decay,presence,fuel],player,enemy,2200,1,true)
 for tick in normal.tick_events:check(is_zero_approx(tick.crit_chance),"Presence does not enable Poison crits without talent")
 check(Formatter.conditions_for(presence,null).contains("+2 percentage points"),"Presence tooltip matches live crit coefficient")
 check(presence.cooldown_ms==30000 and Contracts.skill("touch_of_darkness").cooldown_ms==30000,"Both cooldowns remain 30 seconds")
 print("P6 D023 Presence crit: "+("FAIL" if failed else "PASS"))
 quit(1 if failed else 0)
