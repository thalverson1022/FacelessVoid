extends SceneTree
## T9: actual released allocations, both roles, gear and hostile mechanics.
const Lab = preload("res://scripts/tools/balance_lab.gd")
const State = preload("res://scripts/systems/combat_stat_state.gd")
const Gold = preload("res://scripts/systems/combat_gold.gd")
const TREES := ["bladedancer", "thief", "assassin", "shadow"]
const ORDERS := {
	"bladedancer": [["talent.bladedancer.weakness",5],["talent.bladedancer.wet_stone",5],["talent.bladedancer.rending_slash",1],["talent.bladedancer.fancy_footwork",5],["talent.bladedancer.precision_attacks",1],["talent.bladedancer.double_dip",2],["talent.bladedancer.opportunity",3],["talent.bladedancer.sharpened_edge",5],["talent.bladedancer.cloak_and_dagger",2],["talent.bladedancer.riposte",2],["talent.bladedancer.side_step",1],["talent.bladedancer.weapon_master",2],["talent.bladedancer.virulent_corruption",1]],
	"thief": [["talent.keen_eye",5],["talent.sticky_fingers",5],["talent.thief.fast_hands",5],["talent.thief.fill_your_pockets",5],["talent.thief.charisma",3],["talent.thief.bribery",3],["talent.thief.silvered_edge",3],["talent.thief.finders_keepers",2],["talent.thief.load_dice",3],["talent.gilded_blade",1]],
	"assassin": [["talent.assassin.quick_hands",5],["talent.assassin.precision",5],["talent.assassin.hastened_poison",5],["talent.assassin.echoing_toxin",3],["talent.assassin.poison_strike",1],["talent.assassin.bypass",1],["talent.assassin.toxic_tradeoff",5],["talent.assassin.accelerant",5],["talent.assassin.resonance",4],["talent.assassin.critical_poison",1]],
	"shadow": [["talent.shadow.coated_weapons",1],["talent.shadow.blind_spot",5],["talent.shadow.snake_oil",4],["talent.shadow.deception",5],["talent.shadow.death_from_the_shadows",5],["talent.shadow.death_pact",3],["talent.shadow.death_touch",3],["talent.shadow.shadow_mastery",5],["talent.shadow.dusk_strike",1],["talent.shadow.death_blade",2],["talent.umbral_pressure",1]]
}
const DEEP := {
	"bladedancer": {"talent.bladedancer.weakness":4,"talent.bladedancer.wet_stone":4,"talent.bladedancer.rending_slash":1,"talent.bladedancer.fancy_footwork":5,"talent.bladedancer.precision_attacks":1,"talent.bladedancer.double_dip":2,"talent.bladedancer.opportunity":3,"talent.bladedancer.sharpened_edge":2},
	"thief": {"talent.keen_eye":5,"talent.sticky_fingers":5,"talent.thief.fast_hands":5,"talent.thief.fill_your_pockets":1,"talent.thief.bribery":1,"talent.thief.charisma":1,"talent.thief.finders_keepers":2,"talent.thief.silvered_edge":1,"talent.thief.load_dice":1},
	"assassin": {"talent.assassin.quick_hands":5,"talent.assassin.precision":5,"talent.assassin.hastened_poison":1,"talent.assassin.echoing_toxin":1,"talent.assassin.poison_strike":1,"talent.assassin.bypass":1,"talent.assassin.toxic_tradeoff":5,"talent.assassin.accelerant":1,"talent.assassin.resonance":1,"talent.assassin.critical_poison":1},
	"shadow": {"talent.shadow.coated_weapons":1,"talent.shadow.blind_spot":5,"talent.shadow.snake_oil":4,"talent.shadow.deception":5,"talent.shadow.death_pact":2,"talent.shadow.death_touch":3,"talent.shadow.shadow_mastery":1,"talent.shadow.dusk_strike":1,"talent.shadow.death_blade":1}
}
const MACROS := {
	"bladedancer": ["skill.dance_of_death","skill.quick_cut","skill.leaping_plunge","skill.parry_strike"],
	"thief": ["skill.pick_pocket","skill.steal","skill.mug","skill.big_score"],
	"assassin": ["skill.virulent_poison","skill.venom_jab","skill.poison_strike","skill.blinding_powder"],
	"shadow": ["skill.toxic_flurry","skill.distilled_corruption","skill.beguiling_presence","skill.touch_of_darkness"]
}
const TARGETS := {
	"neutral": {}, "armor": {"armor":300},
	"resistance_absorb": {"poison_resistance":0.75,"absorb":15.0},
	"block": {"block":30.0}, "cleanse": {"cleanse_threshold":2},
	"dodge": {"dodge_chance":1.0}, "interrupt": {"interrupt_skip_count":2},
	"slow_suppress": {"slow":0.5,"suppress":0.75},
	"crit_negation": {"crit_negation":1.0}
}
const GEAR_PROFILES := {
	"scalar": {"base_damage":7,"percent_physical_damage":0.3,"base_elemental_damage":4,"percent_elemental_damage":0.4,"increased_attack_speed":0.2,"crit_chance":0.15,"crit_damage":0.5,"chance_for_retrigger":0.15,"increased_gold":0.5,"increased_magic_find":1.0,"shop_discount":0.1},
	"stacks": {"increased_all_stacks":2,"double_applied_stacks":1,"shred_value":3,"decay_value":0.01,"chance_to_shred":0.3,"chance_to_decay":0.3},
	"denial": {"disable_enemy_block":1,"disable_enemy_absorb":1},
	"physical": {"convert_damage_to_physical":1},
	"magical": {"convert_damage_to_magical":1},
	"both_conversions": {"convert_damage_to_physical":1,"convert_damage_to_magical":1}
}
var registry: BuildContentRegistry
var failed := false
var checks := 0
var rows: Array = []
var witnesses := {}
var context := ""

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAILED: " + context + " " + label)

func near(actual: float, expected: float, label: String) -> void:
	check(is_equal_approx(actual,expected), "%s expected %s got %s" % [label,expected,actual])

func ranks_for(tree: String, points: int) -> Dictionary:
	var ranks := {}
	for pair in ORDERS[tree]:
		var take := mini(points,int(pair[1]))
		if take > 0: ranks[pair[0]] = take
		points -= take
	return ranks

func gear_for(profile: String) -> Array[GearItem]:
	var gear: Array[GearItem] = [load("res://data/gear/bandit_blade.tres") if profile == "bandit" else load("res://data/gear/crude_dagger.tres")]
	if GEAR_PROFILES.has(profile):
		var item := GearItem.new()
		item.id = "test.t9." + profile
		item.slot = GearItem.SlotType.TRINKET
		for id in GEAR_PROFILES[profile]:
			var modifier := StatModifier.new()
			modifier.stat_id = id
			modifier.value = GEAR_PROFILES[profile][id]
			item.affixes.append(modifier)
		gear.append(item)
	return gear

func enemy_for(mode: String) -> Monster:
	var enemy := Monster.new()
	enemy.hp = 100000000
	for field in TARGETS[mode]: enemy.set(field,TARGETS[mode][field])
	return enemy

func model_for(primary: String, secondary: String, ranks: Dictionary) -> RankedBuild:
	var model := RankedBuild.new()
	var legal := model.configure(registry.trees["tree."+primary],registry.trees["tree."+secondary],45,ranks)
	check(legal,"legal 45-point allocation: " + model.last_error)
	return model

func resolve(model: RankedBuild, profile := "plain", stash := 100) -> Dictionary:
	var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear_for(profile),stash)
	check(content.error == "","released build resolves")
	return content

func find_skill(content: Dictionary, id: String) -> Skill:
	for s in content.skills:
		if s.id == id: return s
	return null

func rotation_for(content: Dictionary, first: String, second: String) -> Array[Skill]:
	var rotation: Array[Skill] = []
	for index in range(4):
		for tree in [first,second]:
			var s := find_skill(content,MACROS[tree][index])
			if s != null: rotation.append(s)
	rotation.append(find_skill(content,"skill.stab"))
	rotation.append(find_skill(content,"skill.heavy_slash"))
	check(rotation.size() <= 10,"legal macro size")
	return rotation

func payload(model: RankedBuild, ranks: Dictionary, rotation: Array[Skill]) -> Dictionary:
	var ids: Array = []
	for s in rotation: ids.append(s.id)
	return {"build_schema_version":1,"content_revision":registry.revision,"allocation_mode":"ranked","class_id":"class.rogue","primary_tree_id":model.primary_tree().id,"secondary_tree_id":model.secondary_tree().id,"earned_talent_points":45,"talent_ranks":ranks,"rotation_skill_ids":ids}

func scalar_contracts(model: RankedBuild, ranks: Dictionary) -> void:
	var stats: PlayerStats = resolve(model,"scalar").stats
	var raw: PlayerStats = registry.classes["class.rogue"].base_stats
	var blade_points := model.tree_points(registry.trees["tree.bladedancer"]) if model.primary_tree().id == "tree.bladedancer" else 0
	var thief_points := model.tree_points(registry.trees["tree.thief"]) if model.primary_tree().id == "tree.thief" else 0
	var assassin_points := model.tree_points(registry.trees["tree.assassin"]) if model.primary_tree().id == "tree.assassin" else 0
	var shadow_points := model.tree_points(registry.trees["tree.shadow"]) if model.primary_tree().id == "tree.shadow" else 0
	var has_blade := model.primary_tree().id == "tree.bladedancer" or model.secondary_tree().id == "tree.bladedancer"
	var has_thief := model.primary_tree().id == "tree.thief" or model.secondary_tree().id == "tree.thief"
	var has_assassin := model.primary_tree().id == "tree.assassin" or model.secondary_tree().id == "tree.assassin"
	var has_shadow := model.primary_tree().id == "tree.shadow" or model.secondary_tree().id == "tree.shadow"
	var retrigger := 0.15 + (0.05 + 0.002*blade_points if has_blade else 0.0)
	near(stats.retrigger_chance,retrigger,"primary-only retrigger with gear")
	near(stats.crit_chance,raw.crit_chance+0.15+0.01*ranks.get("talent.assassin.precision",0)+0.02*ranks.get("talent.shadow.blind_spot",0)+retrigger*0.5*ranks.get("talent.bladedancer.double_dip",0),"Double Dip copies numeric retrigger with gear")
	var gold: float = 1.5 * (1.1+0.02*thief_points if has_thief else 1.0)*(1+0.1*ranks.get("talent.sticky_fingers",0))
	near(stats.gold_reward_multiplier,gold,"role and gear gold buckets")
	near(stats.attack_speed,0.2+0.01*ranks.get("talent.assassin.quick_hands",0)+(gold-1)*0.1*ranks.get("talent.thief.fast_hands",0),"Fast Hands sees final gold bonus")
	var elemental: float = 1.4*(1+0.02*ranks.get("talent.keen_eye",0))*(1+0.1*ranks.get("talent.shadow.deception",0))*(1+(1.0+ranks.get("talent.thief.load_dice",0))*0.2*ranks.get("talent.thief.fill_your_pockets",0))
	near(stats.elemental_damage_multiplier,elemental,"Fill Your Pockets final elemental bucket")
	var flat: float = 4.0 + 2*ranks.get("talent.shadow.snake_oil",0) + (5.0+0.5*assassin_points if has_assassin else 0.0)
	near(stats.bonus_base_elemental_damage,flat,"primary Assassin and gear elemental base")
	var mastery: float = 0.1*ranks.get("talent.shadow.shadow_mastery",0)
	near(stats.bonus_physical_damage,7+ranks.get("talent.bladedancer.wet_stone",0)+flat*mastery,"Mastery copies bonuses once")
	near(stats.derived_physical_multiplier,1+(elemental-1)*mastery,"Mastery after Fill Your Pockets")
	near(stats.elemental_proc_chance,0.2+0.02*shadow_points if has_shadow else raw.elemental_proc_chance,"Shadow role scaling")
	near(stats.physical_damage_multiplier,1.3*(1+0.02*ranks.get("talent.keen_eye",0))*(1-0.1*ranks.get("talent.assassin.toxic_tradeoff",0))*(1+0.5*ranks.get("talent.bladedancer.weapon_master",0))*(1+(elemental-1)*mastery),"Toxic and Weapon Master multiply")
	var state := State.new(stats)
	check(State.value_snapshot(state.snapshot()) == State.value_snapshot(stats),"derived rebuild does not double count")
	var mod := StatModifier.new()
	mod.stat_id = StatCatalog.BASE_ELEMENTAL_DAMAGE
	mod.value = 3
	check(state.replace_source("t9.temp","test.t9",[mod],0) == "","temporary source accepted")
	near(state.snapshot().bonus_physical_damage,stats.bonus_physical_damage+3*mastery,"temporary elemental flows into Mastery")
	check(state.remove_source("t9.temp",1) == "" and State.value_snapshot(state.snapshot()) == State.value_snapshot(stats),"temporary expiry restores all derived values")
	var before: PlayerStats = resolve(model,"bandit",100).stats
	var after: PlayerStats = resolve(model,"bandit",0).stats
	near(before.bonus_physical_damage-after.bonus_physical_damage,10,"Bandit Blade rebuild after spending")

func inspect_result(result, stats: PlayerStats) -> void:
	var direct := 0.0
	var poison := 0.0
	var stolen := 0
	for event in result.cast_events:
		direct += event.physical_damage
		stolen += event.gold_stolen
		check(event.physical_damage >= 0 and event.poison_stacks_applied >= 0,"nonnegative event accounting")
		if stats.death_blade_enabled and event.skill.id == "skill.stab": check(event.poison_applications.is_empty(),"all Stab Poison suppressed with Death Blade")
		if event.origin_kind == "proc" and int(event.lifecycle_snapshot.get("precision_consumed",0)) > 0: witnesses["precision_death_blade"] = true
		if event.shred_stacks_applied > 0 and event.decay_stacks_applied > 0: witnesses["decay_and_shred"] = true
		if event.gold_stolen > 0: witnesses["theft"] = true
		if event.was_interrupted: witnesses["interruption"] = true
		if event.cleanse_triggered: witnesses["cleanse"] = true
		if event.cooldown_blocked:
			check(event.time_ms-event.cast_start_ms == 100 and event.physical_damage == 0 and event.gold_stolen == 0,"cooldown skip is 100 ms without effects")
		for application in event.poison_applications:
			check(int(application.get("applied",0)) <= int(application.get("requested",0)),"Poison grant cannot exceed requested quantity")
	for tick in result.tick_events:
		poison += tick.damage
		check(tick.stacks_remaining >= 0 and tick.stacks_remaining <= stats.poison_stack_cap,"Poison cap and depletion")
		check(tick.stacks_consumed <= tick.stacks_before,"no invented tick fuel")
		if tick.is_crit: witnesses["critical_poison"] = true
	near(result.total_damage,direct+poison,"damage ledger reconciliation")
	check(result.gold_stolen == stolen,"gold ledger reconciliation")
	check((result.effect_lifecycle == null or result.effect_lifecycle.state.snapshot().is_empty()) and result.talent_buffs.state.snapshot().is_empty() and result.defense_debuffs.state.snapshot().is_empty(),"fight-local lifecycle cleanup")

func scenario(model: RankedBuild, ranks: Dictionary, first: String, second: String, profile: String, mode: String) -> void:
	var content := resolve(model,profile)
	var rotation := rotation_for(content,first,second)
	var stats_before := State.value_snapshot(content.stats)
	var samples: Array = []
	for seed_value in range(1,6):
		var enemy := enemy_for(mode)
		var a := CombatResolver.resolve(rotation,content.stats,enemy,30000,seed_value,true)
		var b := CombatResolver.resolve(rotation,content.stats,enemy,30000,seed_value,true)
		var off := CombatResolver.resolve(rotation,content.stats,enemy,30000,seed_value,false)
		check(a.is_valid and b.is_valid and off.is_valid,"valid resolution")
		check(a.trace.records == b.trace.records and a.total_damage == b.total_damage and a.gold_stolen == b.gold_stolen,"identical seeded replay")
		check(a.total_damage == off.total_damage and a.gold_stolen == off.gold_stolen and a.rng_final_state == off.rng_final_state,"trace-neutral outcomes and RNG")
		inspect_result(a,content.stats)
		samples.append({"seed":seed_value,"damage":a.total_damage,"gold":a.gold_stolen,"rng_final_state":str(a.rng_final_state),"casts":a.cast_events.size(),"ticks":a.tick_events.size()})
	check(State.value_snapshot(content.stats) == stats_before,"source stats immutable across fights")
	var rebuilt := resolve(model,profile)
	check(State.value_snapshot(rebuilt.stats) == stats_before,"fresh resolution matches source after repeated fights")
	rows.append({"case":context,"build":payload(model,ranks,rotation),"gear_profile":profile,"target":mode,"duration_ms":30000,"samples":samples})

func lab_parity(model: RankedBuild, ranks: Dictionary, first: String, second: String) -> void:
	var content := resolve(model,"plain",0)
	var rotation := rotation_for(content,first,second)
	var build_payload := payload(model,ranks,rotation)
	check(BuildSaveCodec.decode(build_payload,registry).error == "","mixed payload round trip")
	var spec := {"id":context,"label":context,"ranked_build":build_payload,"monster":"res://data/monsters/mouthy_drunk.tres","monster_overrides":{"hp":100000000,"armor":0,"poison_resistance":0.0},"gear":["res://data/gear/crude_dagger.tres"],"gold":0,"duration_ms":30000,"seed_start":1,"seed_count":5}
	var report := Lab.run_scenario_spec(spec,registry)
	check(report.status == "pass","standard Balance Lab accepts actual mixed build")
	var mean_damage := 0.0
	for seed_value in range(1,6): mean_damage += CombatResolver.resolve(rotation,content.stats,enemy_for("neutral"),30000,seed_value).total_damage/5.0
	near(float(report.aggregate.total_damage.mean),mean_damage,"Balance Lab and direct resolver parity")

func _run() -> void:
	registry = BuildContentRegistry.test_mode()
	check(registry.error == "" and registry.revision == "p6.playable.shadow.1","current released registry")
	for i in range(TREES.size()):
		for j in range(i+1,TREES.size()):
			var first: String = TREES[i]
			var second: String = TREES[j]
			for allocation in ["first_full","second_full","deep"]:
				var ranks: Dictionary
				if allocation == "deep":
					ranks = DEEP[first].duplicate(true)
					var other: Dictionary = DEEP[second].duplicate(true)
					if second == "thief": other["talent.thief.fill_your_pockets"] += 1
					if second == "assassin": other["talent.assassin.hastened_poison"] += 1
					ranks.merge(other)
				else:
					ranks = ranks_for(first,35 if allocation == "first_full" else 10)
					ranks.merge(ranks_for(second,10 if allocation == "first_full" else 35))
				for reverse in [false,true]:
					context = "%s_%s_%s_%s" % [first,second,allocation,"reverse" if reverse else "forward"]
					var model := model_for(second if reverse else first,first if reverse else second,ranks)
					if model.points_spent() != 45:
						check(false,"expected exactly 45 points")
						continue
					scalar_contracts(model,ranks)
					lab_parity(model,ranks,first,second)
					for mode in TARGETS: scenario(model,ranks,first,second,"plain",mode)
					for profile in GEAR_PROFILES: scenario(model,ranks,first,second,profile,"resistance_absorb" if profile in ["physical","magical","both_conversions"] else "block" if profile == "denial" else "neutral")
					scenario(model,ranks,first,second,"bandit","neutral")
					print("T9 finished " + context)
	for witness in ["precision_death_blade","decay_and_shred","theft","critical_poison","cleanse","interruption"]: check(witnesses.has(witness),"observed integration path " + witness)
	var report_path: String = get_script().resource_path.get_base_dir().path_join("matrix.json")
	check(SaveSystem.write_json(report_path,{"pass":not failed,"checks":checks,"revision":registry.revision,"gear_profiles":GEAR_PROFILES,"targets":TARGETS,"witnesses":witnesses,"scenarios":rows}),"write reproducible matrix")
	print("T9 mixed/gear: %d checks, %d scenarios %s" % [checks,rows.size(),"FAIL" if failed else "PASS"])
	quit(1 if failed else 0)
