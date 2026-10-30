extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT = "res://reports/balance/assassin_rotation_search_d016"
var stats: PlayerStats
var skills := {}
var enemy: Monster
var candidates := {}
var rng := RandomNumberGenerator.new()
const USER := ["poison_vile","blinding_powder","virulent_poison","poison_strike","poison_strike","poison_strike"]
func _initialize() -> void:
	call_deferred("run")
func score(ids: Array, start: int, count: int) -> Dictionary:
	var rotation: Array[Skill] = []
	for id in ids: rotation.append(skills[id])
	var values := []
	var poison := 0.0
	for seed in range(start,start+count):
		var result := CombatResolver.resolve(rotation,stats,enemy,30000,seed)
		assert(result.is_valid and result.duration_ms==30000)
		values.append(result.dps)
		for tick in result.tick_events: poison+=tick.damage
	return {"rotation":ids.duplicate(),"dps":Lab._distribution(values),"poison_dps":poison/count/30.0,"seed_start":start}
func add(ids: Array) -> void:
	var key := JSON.stringify(ids)
	if not candidates.has(key): candidates[key]=score(ids,1,5)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var registry := BuildContentRegistry.test_mode()
	var model := RankedBuild.new()
	var ranks := {}
	for talent in registry.trees["tree.assassin"].talents: ranks[talent.id]=talent.max_ranks
	assert(model.configure(registry.trees["tree.assassin"],null,35,ranks))
	var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
	var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear,0)
	stats=content.stats
	for skill in content.skills: skills[skill.id.trim_prefix("skill.")]=skill
	enemy=load("res://data/monsters/training_dummy.tres").duplicate(true)
	enemy.hp=100000000
	rng.seed=160035
	add(USER)
	# All opening orders of the four principal skills, with 0-6 Strike fillers.
	for fuel in ["poison_vile","venom_jab"]:
		for powder in [false,true]:
			for buff in [false,true]:
				for strikes in range(7):
					var ids: Array = [fuel]
					if powder: ids.append("blinding_powder")
					if buff: ids.append("virulent_poison")
					for n in range(strikes): ids.append("poison_strike")
					for opening in range(ids.size()):
						add(ids)
						ids.append(ids.pop_front())
	var pool := ["poison_vile","venom_jab","blinding_powder","virulent_poison","poison_strike","poison_strike","stab","heavy_slash","master_of_poisons","hold"]
	for trial in range(500):
		var ids := []
		for n in range(rng.randi_range(2,10)): ids.append(pool[rng.randi_range(0,pool.size()-1)])
		if "poison_vile" in ids or "venom_jab" in ids: add(ids)
	print("Initial candidates: ",candidates.size())
	# Improve top candidates via substitutions, deletions and insertions.
	for generation in range(2):
		var ranked: Array = candidates.values()
		ranked.sort_custom(func(a,b):return a.dps.mean>b.dps.mean)
		for parent in ranked.slice(0,8):
			for trial in range(30):
				var ids: Array=parent.rotation.duplicate()
				var pos:=rng.randi_range(0,ids.size()-1)
				var op:=rng.randi_range(0,2)
				var skill=pool[rng.randi_range(0,pool.size()-1)]
				if op==0: ids[pos]=skill
				elif op==1 and ids.size()<10: ids.insert(pos,skill)
				elif ids.size()>1: ids.remove_at(pos)
				add(ids)
		print("Generation ",generation," candidates ",candidates.size())
	var ranked: Array = candidates.values()
	ranked.sort_custom(func(a,b):return a.dps.mean>b.dps.mean)
	var finalists := []
	for row in ranked.slice(0,20): finalists.append(score(row.rotation,1,200))
	finalists.sort_custom(func(a,b):return a.dps.mean>b.dps.mean)
	var baseline:=score(USER,1,200)
	var heldout:=[]
	for row in finalists.slice(0,5): heldout.append(score(row.rotation,201,200))
	heldout.append(score(USER,201,200))
	SaveSystem.write_json(OUT+"/summary.json",{"candidates":candidates.size(),"baseline":baseline,"finalists":finalists,"heldout":heldout,"scope":"Heuristic search, not proof of global optimum; full35 current live content, 30s zero-defense dummy, crude dagger only."})
	print(JSON.stringify({"baseline":baseline,"top":finalists.slice(0,5),"heldout":heldout}))
	quit()
