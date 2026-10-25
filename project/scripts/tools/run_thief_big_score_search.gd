extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT = "res://reports/balance/thief_big_score4_search"
var stats: PlayerStats
var skills := {}
var enemy: Monster
var candidates := {}
var rng := RandomNumberGenerator.new()
const USER := ["pick_pocket","mug"]
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
	for talent in registry.trees["tree.thief"].talents: ranks[talent.id]=talent.max_ranks
	assert(model.configure(registry.trees["tree.thief"],null,35,ranks))
	var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
	var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear,0)
	stats=content.stats
	for skill in content.skills: skills[skill.id.trim_prefix("skill.")]=skill.duplicate(true)
	assert(skills.big_score.critical_damage_factor==2.0)
	skills.big_score.critical_damage_factor=4.0
	enemy=load("res://data/monsters/training_dummy.tres").duplicate(true)
	enemy.hp=100000000
	rng.seed=160035
	add(USER)
	# Exhaust all sequences through four slots; longer seeded candidates and local edits.
	var pool := ["pick_pocket","steal","mug","big_score","stab","heavy_slash","hold"]
	var principal := ["pick_pocket","steal","mug","big_score"]
	var frontier: Array = [[]]
	for length in range(1,5):
		var next: Array = []
		for parent in frontier:
			for id in principal:
				var ids: Array = parent.duplicate()
				ids.append(id)
				add(ids)
				next.append(ids)
		frontier=next
	for count in range(1,10):
		for filler in ["big_score","mug","steal"]:
			var ids: Array=["pick_pocket"]
			for n in range(count): ids.append(filler)
			add(ids)
	for trial in range(400):
		var ids := []
		for n in range(rng.randi_range(5,10)): ids.append(pool[rng.randi_range(0,pool.size()-1)])
		add(ids)
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
	var simple := []
	for ids in [["pick_pocket","big_score"],["pick_pocket","steal","big_score"],["pick_pocket","mug","big_score"]]: simple.append(score(ids,1,200))
	var heldout:=[]
	for row in finalists.slice(0,5): heldout.append(score(row.rotation,201,200))
	heldout.append(score(USER,201,200))
	skills.big_score.critical_damage_factor=2.0
	var live_best:=score(finalists[0].rotation,1,200)
	var live_simple:=score(["pick_pocket","big_score"],1,200)
	SaveSystem.write_json(OUT+"/summary.json",{"candidates":candidates.size(),"baseline":baseline,"finalists":finalists,"heldout":heldout,"simple":simple,"live_best":live_best,"live_simple":live_simple,"scope":"Heuristic search; full35 Thief, copied Big Score factor 4, all other live values, 30s blank dummy, crude dagger, zero starting gold."})
	print(JSON.stringify({"baseline":baseline,"top":finalists.slice(0,5),"heldout":heldout,"simple":simple,"live_best":live_best,"live_simple":live_simple}))
	quit()
