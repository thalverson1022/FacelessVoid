extends SceneTree

func _initialize() -> void:
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	var gear: GearItem = load("res://data/gear/crude_dagger.tres").duplicate(true)
	var modifier := StatModifier.new()
	modifier.stat_id = StatCatalog.BASE_ELEMENTAL_DAMAGE
	modifier.value = 10.0
	gear.affixes.append(modifier)
	var talent := Talent.new()
	talent.id = "test.source_talent"
	var speed := StatModifier.new()
	speed.stat_id = StatCatalog.INCREASED_ATTACK_SPEED
	speed.value = 0.25
	talent.stat_modifiers = [speed]
	var stats := BuildResolver.resolve_stats(rogue, [], [talent], [gear])
	var source_found := false
	for source in stats.stat_sources:
		if source.source_id == gear.id and source.get("stat_id") == StatCatalog.BASE_ELEMENTAL_DAMAGE:
			assert(source.value == 10.0 and source.source_kind == "gear")
			source_found = true
	assert(source_found)
	assert(stats.stat_sources[0].source_id == rogue.id)
	assert(stats.stat_sources.back().source_kind == "gear_aggregate")
	assert(stats.stat_sources.back().values[StatCatalog.BASE_ELEMENTAL_DAMAGE] == 10.0)
	var recorded := stats.stat_sources.duplicate(true)
	modifier.value = 20.0
	speed.value = 0.5
	assert(stats.stat_sources == recorded)
	var changed := BuildResolver.resolve_stats(rogue, [], [talent], [gear])
	assert(changed.bonus_base_elemental_damage == stats.bonus_base_elemental_damage + 10.0)
	assert(is_equal_approx(changed.attack_speed, stats.attack_speed + 0.25))
	assert(modifier.value == 20.0 and speed.value == 0.5)
	print("P6 T3 stat source snapshots: PASS")
	quit()
