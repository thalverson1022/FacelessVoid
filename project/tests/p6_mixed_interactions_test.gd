extends "res://tests/p6_mixed_gear_integration_test.gd"
## Focused reachable combinations missing from simple 35/10 coverage.
const Defense = preload("res://scripts/systems/combat_defense_debuffs.gd")
const Buffs = preload("res://scripts/systems/combat_talent_buffs.gd")
var focused_rows: Array = []

func _initialize() -> void:
	call_deferred("_run")

func run_pair(first: String, second: String, ranks: Dictionary, ids: Array, required: Array) -> void:
	for reverse in [false,true]:
		context = first + "_" + second + ("_reverse" if reverse else "_forward")
		var model := model_for(second if reverse else first,first if reverse else second,ranks)
		if model.points_spent() != 45:
			check(false,"focused split uses 45 legal points")
			continue
		var content := resolve(model,"stacks",0)
		var rotation: Array[Skill] = []
		for id in ids:
			var s := find_skill(content,id)
			check(s != null,"required skill " + id)
			if s != null: rotation.append(s)
		var found := {}
		var samples: Array = []
		for seed_value in range(1,21):
			var enemy := enemy_for("cleanse" if first == "bladedancer" else "block")
			var result := CombatResolver.resolve(rotation,content.stats,enemy,30000,seed_value,true)
			check(result.is_valid,"valid targeted combat")
			inspect_result(result,content.stats)
			for event in result.cast_events:
				if event.gold_stolen > 0 and event.shred_stacks_applied > 0: found["bribery"] = true
				if event.cleanse_triggered and event.status_snapshot.shred > 0: found["immune_shred"] = true
				if event.skill.id == "skill.stab" and content.stats.bypass_enabled: found["bypass"] = true
				for transaction in event.status_transactions:
					check(transaction.after == transaction.before + transaction.applied - transaction.removed,"status quantity ledger reconciles")
					check(transaction.requested == transaction.applied + transaction.overflow,"requested status grant reconciles with overflow")
					if transaction.get("keyword_consume",false): check(transaction.consumed == transaction.removed,"Consume equals actual removal")
					if transaction.get("keyword_consume",false) and transaction.get("consumed",0) > 0: found["consume"] = true
			for tick in result.tick_events:
				if tick.is_crit: found["critical_poison"] = true
				if tick.stacks_before > 30: found["above_ordinary_cap"] = true
				if not tick.charge_spends.is_empty(): found["virulent"] = true
				if tick.origin_kind == "forced_tick": found["forced_tick"] = true
			for record in result.trace.records:
				if record.kind == "effect_lifecycle" and record.payload.get("effect_id","") == "master_of_poisons" and record.lifecycle_reason == "granted": found["master"] = true
			samples.append({"seed":seed_value,"damage":result.total_damage,"gold":result.gold_stolen})
			if seed_value == 1:
				check(SaveSystem.write_json(get_script().resource_path.get_base_dir().path_join(context+"_trace.json"),{"records":result.trace.records}),"seed-one trace")
		for key in required: check(found.has(key),"observed " + key)
		focused_rows.append({"case":context,"build":payload(model,ranks,rotation),"gear_profile":"stacks","duration_ms":30000,"target":"cleanse" if first == "bladedancer" else "block","witnesses":found,"samples":samples})

func defense_and_bypass() -> void:
	for partner in ["thief","assassin"]:
		for reverse in [false,true]:
			context = "exact_"+partner+"_shadow_"+str(reverse)
			var ranks: Dictionary = DEEP[partner].duplicate(true)
			ranks.merge(DEEP.shadow)
			var model := model_for("shadow" if reverse else partner,partner if reverse else "shadow",ranks)
			var content := resolve(model,"stacks",0)
			var stats: PlayerStats = content.stats
			var defenses := Defense.new(stats,30,20)
			var ordinary: Dictionary = defenses.grant("potency",1,stats,0,{})
			check(ordinary.error == "","ordinary Potency accepts allocated stack modifiers")
			near(defenses.values().absorb,20-(1+9+2)*2,"add Death Touch and gear before doubling")
			defenses = Defense.new(stats,30,20)
			check(defenses.grant("penetration",5,stats,0,{},true).error == "","actual Consume grants defense stacks")
			near(defenses.values().block,(0 if partner == "thief" else 30)-5,"Pact does not reapply bonus stacks or doubling")
			check(defenses.state.advance(4999) == "","before Pact expiry")
			near(defenses.values().block,(0 if partner == "thief" else 30)-5,"rank-two Pact remains active before expiry")
			check(defenses.state.advance(5000) == "","at Pact expiry")
			near(defenses.values().block,0 if partner == "thief" else 30,"Pact expires at exact deadline")
			defenses = Defense.new(stats,30,20)
			check(defenses.grant("potency",100,stats,0,{}).error == "","cap stress grant")
			near(defenses.values().absorb,-30,"Potency caps at fifty with Death Touch and gear")
			if partner == "assassin":
				var buffs := Buffs.new(stats)
				check(buffs.finish_cast("skill.stab",true,0,{}) == "","actual mixed Bypass carrier")
				check(buffs.state.snapshot("bypass").stacks == 3,"Bypass caps at three after Death Touch/doubling")
				var live: PlayerStats = buffs.live_player(stats)
				near(live.elemental_damage_multiplier,stats.elemental_damage_multiplier*1.3,"Bypass multiplies elemental")
				near(live.derived_physical_multiplier,1+(live.elemental_damage_multiplier-1)*0.1,"Mastery rebuild includes Bypass once")
				check(buffs.state.advance(3000) == "","Bypass exact expiry")
				near(buffs.live_player(stats).physical_damage_multiplier,stats.physical_damage_multiplier,"Bypass expiry restores Mastery")
			else:
				var rotation: Array[Skill] = [find_skill(content,"skill.toxic_flurry"),find_skill(content,"skill.distilled_corruption")]
				var result := CombatResolver.resolve(rotation,stats,enemy_for("block"),3000,7,true)
				var seen := false
				for event in result.cast_events:
					if event.skill.id == "skill.distilled_corruption" and event.origin_kind == "macro":
						near(event.status_snapshot.defenses.block,-5,"live Finders/Pact creates negative block")
						seen = true
				check(seen,"actual Distilled landed")

func _run() -> void:
	registry = BuildContentRegistry.test_mode()
	var blade: Dictionary = DEEP.bladedancer.duplicate(true)
	blade.erase("talent.bladedancer.sharpened_edge")
	blade["talent.bladedancer.virulent_corruption"] = 1
	var thief: Dictionary = DEEP.thief.duplicate(true)
	thief["talent.thief.fill_your_pockets"] += 2
	blade.merge(thief)
	run_pair("bladedancer","thief",blade,["skill.dance_of_death","skill.quick_cut","skill.pick_pocket","skill.steal","skill.leaping_plunge","skill.big_score","skill.stab"],["bribery","immune_shred"])
	var assassin: Dictionary = DEEP.assassin.duplicate(true)
	assassin["talent.assassin.toxic_tradeoff"] -= 1
	var shadow: Dictionary = DEEP.shadow.duplicate(true)
	shadow["talent.umbral_pressure"] = 1
	assassin.merge(shadow)
	run_pair("assassin","shadow",assassin,["skill.virulent_poison","skill.master_of_poisons","skill.poison_vile","skill.venom_jab","skill.poison_strike","skill.stab","skill.toxic_flurry","skill.distilled_corruption","skill.touch_of_darkness","skill.blinding_powder"],["bypass","consume","critical_poison","above_ordinary_cap","virulent","forced_tick","master"])
	defense_and_bypass()
	check(SaveSystem.write_json(get_script().resource_path.get_base_dir().path_join("focused.json"),{"pass":not failed,"checks":checks,"scenarios":focused_rows}),"write focused evidence")
	print("T9 focused interactions: %d checks %s" % [checks,"FAIL" if failed else "PASS"])
	quit(1 if failed else 0)
