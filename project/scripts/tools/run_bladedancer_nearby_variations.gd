extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT = "res://reports/balance/bladedancer_rotation_search_d017"
var stats: PlayerStats
var skills := {}
var enemy: Monster
var candidates := {}
var rng := RandomNumberGenerator.new()
const USER := ["dance_of_death","quick_cut","stab","parry_strike","quick_cut","stab","parry_strike","leaping_plunge"]
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
	for talent in registry.trees["tree.bladedancer"].talents: ranks[talent.id]=talent.max_ranks
	assert(model.configure(registry.trees["tree.bladedancer"],null,35,ranks))
	var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
	var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear,0)
	stats=content.stats
	for skill in content.skills: skills[skill.id.trim_prefix("skill.")]=skill
	enemy=load("res://data/monsters/training_dummy.tres").duplicate(true)
	enemy.hp=100000000
	var rows := []
	for ids in [["dance_of_death","quick_cut","heavy_slash","parry_strike"],["dance_of_death","quick_cut","stab","parry_strike"],["dance_of_death","quick_cut","heavy_slash","parry_strike","quick_cut","heavy_slash","parry_strike","leaping_plunge"],["dance_of_death","quick_cut","heavy_slash","parry_strike","leaping_plunge"],["dance_of_death","quick_cut","heavy_slash"],["dance_of_death","quick_cut","heavy_slash","quick_cut","heavy_slash","parry_strike"],["dance_of_death","quick_cut","heavy_slash","parry_strike","quick_cut","heavy_slash","parry_strike"]]:
		rows.append(score(ids,1,200))
	SaveSystem.write_json(OUT+"/nearby_variations.json",{"rows":rows})
	print(JSON.stringify(rows))
	quit()
