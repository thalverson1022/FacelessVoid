extends SceneTree
## Read-only Balance Lab inquiry. Diagnostic copies never alter released resources or saves.
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT := "res://reports/balance/assassin_inquiry"
const ORDER := [["quick_hands",5],["precision",5],["hastened_poison",5],["echoing_toxin",3],["poison_strike",1],["bypass",1],["toxic_tradeoff",5],["accelerant",5],["resonance",4],["critical_poison",1]]
const MACRO := ["poison_vile", "blinding_powder", "stab", "stab", "stab", "virulent_poison"]
var registry: BuildContentRegistry
var rows: Array = []
var checks := 0
var bad := false

func _initialize() -> void:
	if not is_equal_approx(preload("res://scripts/systems/p6_poison_contracts.gd").ECHOING_DAMAGE_PER_RANK, 0.1):
		printerr("Archived pre-D010 experiment: current gameplay coefficients differ. Use the saved reports or the live balance acceptance test; do not overwrite historical evidence.")
		quit(1)
		return
	SaveSystem.save_path = OUT + "/isolated_save.json"
	PracticeSaveSystem.save_path = OUT + "/isolated_practice.json"
	PracticeSaveSystem.core_save_path = OUT + "/isolated_core.json"
	call_deferred("run")

func require(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		bad = true
		printerr("FAILED: " + message)

func write(name: String, value) -> void:
	var file := FileAccess.open(OUT + "/" + name, FileAccess.WRITE)
	require(file != null, "open " + name)
	if file: file.store_string(JSON.stringify(value, "  ") + "\n")

func build(points: int) -> Dictionary:
	var ranks := {}
	var left := points
	for pair in ORDER:
		var amount := mini(left, pair[1])
		if amount > 0: ranks["talent.assassin." + pair[0]] = amount
		left -= amount
	var model := RankedBuild.new()
	require(model.configure(registry.trees["tree.assassin"], null, points, ranks), "legal allocation " + str(points))
	var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
	var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], model, gear, 0)
	require(content.error == "", "resolve build")
	var rotation: Array[Skill] = []
	for name in MACRO:
		var requested: String = name
		if name == "poison_vile" and points < 12: requested = "venom_jab"
		if name == "blinding_powder" and points < 3: requested = "stab"
		if name == "virulent_poison" and points < 6: requested = "stab"
		for skill in content.skills:
			if skill.id == "skill." + requested: rotation.append(skill)
	require(rotation.size() == 6, "six available macro slots")
	content["rotation"] = rotation
	content["payload"] = {"build_schema_version":1, "content_revision":registry.revision, "allocation_mode":"ranked", "class_id":"class.rogue", "primary_tree_id":"tree.assassin", "secondary_tree_id":null, "earned_talent_points":points, "talent_ranks":ranks, "rotation_skill_ids":rotation.map(func(s): return s.id)}
	return content

func field(stats: PlayerStats, key: String, value) -> void:
	stats.set(key,value)
	if stats.derivation_base != null: stats.derivation_base.set(key,value)

func variant(content: Dictionary, switches: Array) -> Dictionary:
	var stats: PlayerStats = content.stats.duplicate(true)
	# Resource.duplicate does not copy this non-exported provenance pointer.
	stats.derivation_base = content.stats.derivation_base.duplicate(true) if content.stats.derivation_base != null else null
	var rotation: Array[Skill] = []
	for source in content.rotation: rotation.append(source.duplicate(true))
	for sw in switches:
		match sw:
			"no_resonance": field(stats,"resonance_rank",0)
			"no_echo_resonance":
				field(stats,"echoing_toxin_rank",0)
				field(stats,"resonance_rank",0)
			"no_toxic_bonus": field(stats,"poison_tick_damage_multiplier",1.0)
			"toxic_half_bonus": field(stats,"poison_tick_damage_multiplier",1.5)
			"no_cadence":
				field(stats,"hastened_poison_rank",0)
				field(stats,"accelerant_rank",0)
			"no_poison_crit": field(stats,"critical_poison_enabled",false)
			"no_bypass": field(stats,"bypass_enabled",false)
			"no_point_base":
				field(stats,"bonus_base_elemental_damage",stats.bonus_base_elemental_damage - 35.0)
				stats.sync_poison_damage_per_tick()
				if stats.derivation_base != null: stats.derivation_base.sync_poison_damage_per_tick()
		for skill in rotation:
			if (sw == "no_potency" and skill.id == "skill.blinding_powder") or (sw == "no_virulent" and skill.id == "skill.virulent_poison"):
				skill.effects.clear() # Preserve the original slot, category, timing and cooldown.
			if sw == "potency_half" and skill.id == "skill.blinding_powder":
				for effect in skill.effects:
					effect.use_assassin_points = false
					effect.base_stacks = 18
			if sw == "vile_10" and skill.id == "skill.poison_vile":
				for effect in skill.effects:
					if effect is PoisonDamageEffect: effect.stacks_applied = 10
	return {"stats":stats,"rotation":rotation}

func details(result) -> Dictionary:
	var ticks := []
	var effects := []
	var transactions := []
	for record in result.trace.records:
		if record.kind == "poison_tick": ticks.append(record)
		if record.kind == "effect_lifecycle": effects.append(record)
		if record.kind == "status_transaction": transactions.append(record)
	return {"ticks":ticks,"effects":effects,"status_transactions":transactions,"casts":result.cast_events.map(func(c): return {"time_ms":c.time_ms,"skill":c.skill.id,"damage":c.physical_damage,"status":c.status_snapshot,"applications":c.poison_applications,"stats":c.stat_snapshot})}

func cohort(id: String, content: Dictionary, switches: Array = [], duration := 30000, overrides := {}) -> Dictionary:
	var prepared := variant(content,switches)
	var enemy: Monster = load("res://data/monsters/training_dummy.tres").duplicate(true)
	enemy.hp = 100000000
	for key in overrides: enemy.set(key,overrides[key])
	var dps := []
	var poison := []
	var direct := []
	var samples := []
	var diagnostic := {}
	for seed in range(1,201):
		var result := CombatResolver.resolve(prepared.rotation,prepared.stats,enemy,duration,seed,seed == 1)
		require(result.is_valid and not result.is_win and result.duration_ms == duration,"valid complete fight " + id)
		var summary := Lab._combat_summary(seed,result)
		var consumed := 0
		var empty := 0
		var crits := 0
		for tick in result.tick_events:
			consumed += tick.stacks_consumed
			if not tick.had_active_stack: empty += 1
			if tick.is_crit: crits += 1
		summary["stacks_consumed"] = consumed
		summary["empty_ticks"] = empty
		summary["poison_crits"] = crits
		samples.append(summary)
		dps.append(summary.dps)
		poison.append(summary.poison_damage / (duration / 1000.0))
		direct.append(summary.physical_damage / (duration / 1000.0))
		if seed == 1:
			diagnostic = details(result)
			var again := CombatResolver.resolve(prepared.rotation,prepared.stats,enemy,duration,seed,true)
			var untraced := CombatResolver.resolve(prepared.rotation,prepared.stats,enemy,duration,seed,false)
			require(again.trace.records == result.trace.records and untraced.total_damage == result.total_damage and untraced.rng_final_state == result.rng_final_state,"deterministic and trace parity " + id)
	var row := {"id":id,"switches":switches,"duration_ms":duration,"enemy_overrides":overrides,"build":content.payload,"dps":Lab._distribution(dps),"poison_dps":Lab._distribution(poison),"direct_dps":Lab._distribution(direct),"samples":samples,"diagnostic_seed":1}
	write(id + "_trace.json", diagnostic)
	rows.append(row)
	print("DONE %s: %.2f DPS" % [id,row.dps.mean])
	return row

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	registry = BuildContentRegistry.test_mode()
	require(registry.error == "", "registry valid")
	var content := build(35)
	var spec := {"id":"assassin_baseline","label":"35 Assassin user macro / crude / 30s", "ranked_build":content.payload,"monster":"res://data/monsters/training_dummy.tres","monster_overrides":{"hp":100000000},"gear":["res://data/gear/crude_dagger.tres"],"gold":0,"duration_ms":30000,"seed_start":1,"seed_count":200}
	var native := Lab.run_scenario_spec(spec,registry)
	require(native.status == "pass","native Balance Lab baseline")
	write("native_balance_lab.json", native)
	var baseline := cohort("baseline",content)
	require(is_equal_approx(native.aggregate.dps.mean,baseline.dps.mean),"copied diagnostic baseline equals native Balance Lab")
	for sw in ["no_potency","no_virulent","no_toxic_bonus","no_resonance","no_echo_resonance","no_cadence","no_poison_crit","no_bypass","no_point_base","vile_10","potency_half","toxic_half_bonus"]:
		cohort(sw,content,[sw])
	for pair in [["no_potency","no_virulent"],["no_echo_resonance","no_toxic_bonus"],["no_potency","no_toxic_bonus"],["no_virulent","no_bypass"]]:
		cohort("pair_" + "_".join(pair),content,pair)
	for duration in [5000,10000,60000]: cohort("duration_"+str(duration),content,[],duration)
	for defense in [{"poison_resistance":0.5},{"absorb":35.0},{"suppress":1.0},{"cleanse_threshold":5}]:
		cohort("defense_"+defense.keys()[0],content,[],30000,defense)
	for points in [1,10,11,12,13,14,15,16,17,18,19,20,25,30,31,32,33,34]:
		cohort("reference_points_"+str(points),build(points))
	write("results.json",{"content_revision":registry.revision,"seed_start":1,"seed_count":200,"weapon":"res://data/gear/crude_dagger.tres","reference_allocation_order":ORDER,"scenarios":rows,"checks":checks,"pass":not bad,"scope":"Diagnostic copies only; no gameplay changes. Lower-point allocations are reference paths, not the user's unknown allocations. No causal shares should be summed; RNG draw alignment can differ between variants."})
	print("INQUIRY COMPLETE: %d checks, pass=%s" % [checks,not bad])
	quit(1 if bad else 0)
