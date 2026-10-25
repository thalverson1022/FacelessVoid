extends SceneTree
## Authored T5 contract and shared unlock ownership; isolated runner only.
const Catalog = preload("res://scripts/systems/legendary_catalog.gd")
const ExsanguinateEffect = preload("res://scripts/resources/exsanguinate_effect.gd")
const EXPECTED := {
	"wyvern_kriss": ["wyvern", 0, {"base_elemental_damage": 8.0, "percent_elemental_damage": 0.4, "chance_to_decay": 0.12}],
	"umbral_stiletto": ["umbral", 0, {"crit_chance": 0.1, "crit_damage": 1.0, "crit_applies_element": 0.5}],
	"mithril_karambit": ["mithril", 0, {"increased_attack_speed": 0.15, "crit_chance": 0.15, "chance_to_shred": 0.2}],
	"bandit_blade": ["bandit", 0, {"percent_physical_damage": 0.2, "crit_chance": 0.12, "increased_gold": 0.5}],
	"bejeweled_push_dagger": ["bejeweled", 0, {"base_damage": 8.0, "percent_physical_damage": 0.2, "crit_chance": 0.1}],
	"decrepit_blade": ["decrepit", 0, {"base_damage": 10.0, "base_elemental_damage": 10.0, "chance_for_retrigger": 0.12}],
	"nightkiss_kitana": ["nightkiss", 0, {"shred_value": 50.0, "increased_all_stacks": 5.0, "chance_to_shred": 0.2}],
	"crown_of_concertation": ["crown", 3, {"increased_attack_speed": 0.2, "increased_buff_duration": 0.2, "cooldown_reduction": 0.15}],
	"helm_of_the_samurai": ["samurai", 3, {"crit_chance": 0.12, "increased_attack_speed": 0.2, "chance_for_retrigger": 0.08}],
	"cloak_of_speed": ["cloak", 4, {"percent_physical_damage": 0.7, "crit_applies_penetration": 0.25}],
	"deaths_door": ["death_door", 4, {"percent_physical_damage": 0.35, "percent_elemental_damage": 0.35, "increased_gold": 0.6}],
	"signet_of_the_old_kings": ["signet", 2, {"crit_chance": 0.2, "crit_damage": 1.0, "chance_to_shred": 0.2}],
	"lolzorzs_locket": ["locket", 2, {"base_damage": 15.0, "base_elemental_damage": 15.0, "cooldown_reduction": 0.15}],
	"serpents_coil": ["coil", 1, {"crit_chance": 0.15, "increased_attack_speed": 0.15, "chance_for_retrigger": 0.1}],
	"wingjammer": ["wingjammer", 1, {"base_damage": 15.0, "increased_gold": 0.5, "crit_applies_penetration": 0.3}],
	"mysterious_lucky_coin": ["coin", 1, {"crit_chance": 1.0, "cooldown_reduction": 0.15}],
}

func _initialize() -> void:
	var ids: Array[String] = []
	assert(Catalog.all_paths().size() == 16)
	for item in Catalog.all_items():
		assert(item != null)
		assert(not ids.has(item.id))
		ids.append(item.id)
		var key := item.id.trim_prefix("gear.legendary.")
		assert(EXPECTED.has(key))
		var expected: Array = EXPECTED[key]
		assert(item.legendary_effect_id == expected[0])
		assert(item.slot == expected[1])
		assert(item.tier == GearItem.Tier.LEGENDARY)
		assert(item.source_kind == GearItem.SourceKind.LEGENDARY)
		var affixes := {}
		for affix in item.affixes:
			if affix.stat == StatModifier.StatType.POISON_TICK_INTERVAL:
				assert(key == "wyvern_kriss" and is_equal_approx(affix.value, 0.5))
				continue
			assert(not affixes.has(affix.stat_id))
			affixes[affix.stat_id] = affix.value
		assert(affixes.size() == expected[2].size())
		for stat_id in expected[2]:
			assert(affixes.has(stat_id))
			assert(is_equal_approx(affixes[stat_id], expected[2][stat_id]))
		assert(not Catalog.effect_text(item).is_empty())
		var has_damage_line := false
		for line in Catalog.tooltip_lines(item):
			has_damage_line = has_damage_line or line.begins_with("Weapon Damage:")
		assert(has_damage_line == (item.slot == GearItem.SlotType.WEAPON))
		if item.slot == GearItem.SlotType.WEAPON:
			var damage_range := WeaponDamageCatalog.damage_range_for_weapon(item)
			assert(damage_range["min"] == 21 and damage_range["max"] == 27)
		if key == "mithril_karambit":
			assert(item.triggered_skill_effects.is_empty())
		if key == "bejeweled_push_dagger":
			assert(is_equal_approx(item.min_cast_time_proc_chance, 0.4))
	for key in ["decrepit_blade", "nightkiss_kitana", "crown_of_concertation", "helm_of_the_samurai", "cloak_of_speed", "deaths_door", "signet_of_the_old_kings", "lolzorzs_locket", "serpents_coil", "wingjammer", "mysterious_lucky_coin"]:
		assert(GameIcons.icon_for("gear.legendary." + key) != null)
		var icon_item: GearItem = load("res://data/gear/%s.tres" % key)
		assert(GearIcons.icon_for(icon_item) == GameIcons.icon_for(icon_item.id))
	assert(GameIcons.icon_for("buff.meditation") != null)
	assert(GameIcons.icon_for("buff.dash") != null)
	var exsanguinate: Skill = load("res://data/skills/exsanguinate.tres")
	assert(exsanguinate.id == "skill.exsanguinate")
	assert(exsanguinate.category == Skill.Category.DEBUFF)
	assert(exsanguinate.base_execution_ms == 300 and exsanguinate.min_execution_ms == 300)
	assert(exsanguinate.cooldown_ms == 8000)
	assert(exsanguinate.effects.size() == 1 and exsanguinate.effects[0] is ExsanguinateEffect)
	assert(exsanguinate.icon != null)
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	for pair in [["umbral_stiletto", "skill.killers_mark"], ["decrepit_blade", "skill.poison_strike"], ["nightkiss_kitana", "skill.exsanguinate"], ["cloak_of_speed", "skill.quick_cut"]]:
		var gear: GearItem = load("res://data/gear/%s.tres" % pair[0])
		assert(gear.unlocked_skills.size() == 1 and gear.unlocked_skills[0].id == pair[1])
		var source := Talent.new()
		source.unlocked_skills = gear.unlocked_skills
		var skills := BuildResolver.resolve_unlocked_skills(rogue, [], [source], [gear])
		assert(_count(skills, pair[1]) == 1)
		assert(_count(BuildResolver.resolve_unlocked_skills(rogue, [], [source], []), pair[1]) == 1)
		assert(_count(BuildResolver.resolve_unlocked_skills(null, [], [], []), pair[1]) == 0)
	print("T7 roster: PASS (16 identities, exact affixes, icons, slot tooltips, skill ownership)")
	quit()

func _count(skills: Array[Skill], id: String) -> int:
	var count := 0
	for skill in skills:
		if skill.id == id:
			count += 1
	return count
