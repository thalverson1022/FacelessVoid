extends SceneTree
## Real fixed resources + shared production tooltip builders. Isolated runner only.
const EXPECTED := {
	"wyvern_kriss": ["Wyvern Kriss", 0, ["+8 Base Elemental Damage", "+40% Increased Elemental Damage", "+12% Chance to Decay"]],
	"mithril_karambit": ["Mithril Karambit", 0, ["+15% Increased Attack Speed", "+15% Crit Chance", "+20% Chance to Shred"]],
	"bandit_blade": ["Bandit Blade", 0, ["+20% Increased Physical Damage", "+12% Crit Chance", "+50% Increased Gold"]],
	"umbral_stiletto": ["Umbral Stiletto", 0, ["+10% Crit Chance", "+100% Crit Damage", "+50% Crits Apply Poison"]],
	"bejeweled_push_dagger": ["Bejeweled Push Dagger", 0, ["+8 Base Physical Damage", "+20% Increased Physical Damage", "+10% Crit Chance"]],
	"decrepit_blade": ["Decrepit Blade", 0, ["+10 Base Physical Damage", "+10 Base Elemental Damage", "+12% Retrigger Chance"]],
	"nightkiss_kitana": ["Nightkiss Kitana", 0, ["+50 Armor Decrease per Shred Stack", "+5 All Stacks", "+20% Chance to Shred"]],
	"crown_of_concertation": ["Crown of Concentration", 3, ["+20% Increased Attack Speed", "+20% Buff Duration", "+15% Cooldown Reduction"]],
	"helm_of_the_samurai": ["Helm of the Samurai", 3, ["+12% Crit Chance", "+20% Increased Attack Speed", "+8% Retrigger Chance"]],
	"cloak_of_speed": ["Cloak of Speed", 4, ["+70% Increased Physical Damage", "+25% Crits Apply Penetration"]],
	"deaths_door": ["Death's Door", 4, ["+35% Increased Physical Damage", "+35% Increased Elemental Damage", "+60% Increased Gold"]],
	"signet_of_the_old_kings": ["The Signet of the Old Kings", 2, ["+20% Crit Chance", "+100% Crit Damage", "+20% Chance to Shred"]],
	"lolzorzs_locket": ["Lolzorz's Locket", 2, ["+15 Base Physical Damage", "+15 Base Elemental Damage", "+15% Cooldown Reduction"]],
	"serpents_coil": ["Serpent's Coil", 1, ["+15% Crit Chance", "+15% Increased Attack Speed", "+10% Retrigger Chance"]],
	"wingjammer": ["Wingjammer", 1, ["+15 Base Physical Damage", "+15 Base Elemental Damage", "+50% Increased Gold", "+30% Crits Apply Penetration", "+30% Crits Apply Potency"]],
	"mysterious_lucky_coin": ["Mysterious Lucky Coin", 1, ["+100% Crit Chance", "+15% Cooldown Reduction"]],
	"serpents_scales": ["Serpent’s Scales", 5, ["+12 Base Elemental Damage", "+70% Increased Elemental Damage", "+30% Crits Apply Potency"]],
	"golden_greeves": ["Golden Greeves", 5, ["+100% Increased Gold", "+50% Increased Magic Find", "+40% Shop Discount"]],
	"hands_of_the_lightning_lord": ["Hands of the Lightning Lord", 6, ["+12 Base Physical Damage", "+15% Crit Chance", "+120% Crit Damage"]],
	"arctic_mittens": ["Arctic Mittens", 6, ["+30% Increased Attack Speed", "+25% Buff Duration", "+20% Cooldown Reduction"]],
}

var checks: Array[String] = []
var witness := {"items": {}, "comparisons": {}}
var state: TrainingRoomState
var owner
var stats_panel_script: Script

func _initialize() -> void:
	call_deferred("run")

func ck(value: bool, message: String) -> void:
	assert(value, message)
	checks.append(message)

func gear(key: String) -> GearItem:
	return load("res://data/gear/" + key + ".tres")

func compare(key: String) -> String:
	return "\n".join(CardStyle.gear_comparison_lines(gear(key), owner))

func fresh() -> void:
	state = TrainingRoomState.new()
	state.set_class(load("res://data/classes/rogue.tres"))
	owner.state = state

func run() -> void:
	root.size = Vector2i(1280, 720)
	stats_panel_script = load("res://scenes/combat/character_stats_panel.gd")
	owner = stats_panel_script.new()
	owner.theme = load("res://assets/ui_theme.tres")
	owner.position = Vector2(900, 20)
	owner.custom_minimum_size = Vector2(340, 0)
	fresh()
	root.add_child(owner)
	await process_frame
	var slots := {}
	ck(LegendaryCatalog.all_items().size() == 20, "all20 fixed resources")
	for item in LegendaryCatalog.all_items():
		var key: String = item.id.trim_prefix("gear.legendary.")
		var expected: Array = EXPECTED[key]
		ck(item.display_name == expected[0] and item.slot == expected[1], key + " approved identity and slot")
		slots[item.slot] = true
		var text := "\n".join(CardStyle.gear_tooltip_lines(item))
		ck(text.contains(item.display_name) and text.contains("Legendary") and text.contains(GearGenerator.universal_slot_label(item.slot)), key + " shared header")
		for stat_text in expected[2]:
			ck(text.to_lower().contains(String(stat_text).to_lower()), key + " fixed stat " + stat_text)
		ck(text.contains(LegendaryCatalog.effect_text(item)), key + " current signature")
		ck(text.contains("Weapon Damage: 21-27") == (item.slot == GearItem.SlotType.WEAPON), key + " weapon range only for weapons")
		ck(not text.contains("Poison Tick Interval"), key + " no duplicate cadence implementation affix")
		ck(not text.contains("per-affix factor") and not text.contains("critical direct contribution") and not text.contains(".0000%"), key + " readable fixed affixes without implementation math")
		ck(GearIcons.icon_for(item) == GearIcons.NAMED_ICONS[item.id], key + " supplied identity icon")
		var catalog_text := "\n".join(LegendaryCatalog.tooltip_lines(item))
		for line in CardStyle.gear_tooltip_lines(item):
			ck(catalog_text.contains(line), key + " catalog and visible tooltip agree: " + line)
		fresh()
		var replacement := _replacement_for(item)
		state.equip_legendary(replacement)
		state.set_practice_gold(1010)
		state.set_legendary_missing_attempts(3)
		owner._refresh()
		var before_equipment := state.equipped_gear().duplicate()
		var before_gold := state.gold
		var preview := CardStyle.build_gear_compare_tooltip(owner, text + "\nPrice: 123 gold", replacement, item)
		preview.position = Vector2(20, 20)
		root.add_child(preview)
		await process_frame
		await process_frame
		ck(preview.size.x <= 1240 and preview.size.y <= 680, key + " actual item tooltip fits1280x720")
		var backing: StyleBox = preview.get_child(0).get_theme_stylebox("panel")
		ck(backing is StyleBoxFlat and is_equal_approx(backing.bg_color.a, 1.0), key + " opaque tooltip backing preserves legibility")
		var rendered_text := _visible_text(preview)
		var offer_text := _visible_text(preview.get_child(0))
		for effect_line in LegendaryCatalog.effect_text(item).split("\n", false):
			ck(offer_text.count(effect_line) == 1, key + " effect line appears once: " + effect_line)
		ck(offer_text.count("Price: 123 gold") == 1, key + " shop footer retained once")
		ck(preview.get_child_count() == 1 and rendered_text.contains(item.display_name) and not rendered_text.contains(replacement.display_name), key + " actual hover renders only candidate identity")
		ck(not rendered_text.contains("Equipped") and not rendered_text.contains("On equip:") and not rendered_text.contains(" -> "), key + " actual hover hides all comparison text")
		ck(not rendered_text.contains("Signature gained") and not rendered_text.contains("Signature lost") and not rendered_text.contains("owned carried gear") and not rendered_text.contains("replacement resale"), key + " actual comparison omits duplicate effects and ownership prose")
		ck(state.gold == before_gold and state.equipped_gear() == before_equipment, key + " preview is read only")
		witness.items[key] = {"tooltip": text, "comparison": compare(key), "size": [preview.size.x, preview.size.y], "icon": GearIcons.icon_for(item).resource_path}
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("res://reports/t9_items")
			root.get_texture().get_image().save_png("res://reports/t9_items/" + key + ".png")
		root.remove_child(preview)
		preview.free()
	ck(slots.size() == 7, "all seven equipment slots rendered")
	ck(LegendaryCatalog.effect_text(gear("nightkiss_kitana")) == "Grants: Exsanguinate\nConsume all Shred to remove 1x the Armor Shred value in health.", "Nightkiss requested Armor Shred wording")
	_test_conditions()
	_test_skills()
	_test_effective_stats()
	# Refresh the real CharacterStatsPanel with its new state, including no-crit text.
	owner._refresh()
	ck(owner._stats_label.text.contains("Crit Chance: 0%") and owner._stats_label.text.contains("Crit Damage: 0%"), "actual stat card suppresses crit outputs under Signet")
	var detail: String = stats_panel_script.stat_detail_text(state.current_player_stats())
	ck(detail.contains("150% Crit Chance gives +225% Attack Speed") and detail.contains("uncapped"), "actual detail explains raw overcap conversion")
	DirAccess.make_dir_recursive_absolute("res://reports")
	witness["checks"] = checks.size()
	var output := FileAccess.open("res://reports/t9_items_witness.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(witness, "\t"))
	print("T9 item presentation: PASS (%d checks,20 actual resource tooltips/comparisons, seven slots, conditions, skills, effective stats)" % checks.size())
	quit()

func _replacement_for(item: GearItem) -> GearItem:
	for candidate in LegendaryCatalog.all_items():
		if candidate.slot == item.slot and candidate.id != item.id:
			return candidate
	return null

func _visible_text(node: Node) -> String:
	var text := ""
	if node is Label: text = node.text
	elif node is RichTextLabel: text = node.get_parsed_text()
	for child in node.get_children(): text += "\n" + _visible_text(child)
	return text

func _test_conditions() -> void:
	ck(LegendaryCatalog.number_text(15.0) == "15" and LegendaryCatalog.number_text(12.3456) == "12.3456", "number formatting trims integer zeros and preserves actual fractions")
	var mithril := LegendaryCatalog.effect_text(gear("mithril_karambit"))
	ck(mithril == "Stab and Heavy Slash gain 50% Retrigger Chance", "Mithril approved concise copy")
	ck(LegendaryCatalog.effect_text(gear("crown_of_concertation")) == "Doubles the effects of self buffs", "Crown approved concise copy")
	ck(LegendaryCatalog.effect_text(gear("lolzorzs_locket")) == "Critical hits have a 20% chance to reduce all cooldowns by 1 sec.", "retains user fixed Locket sentence")
	var coin := LegendaryCatalog.effect_text(gear("mysterious_lucky_coin"))
	ck(coin == "Grants x100% Magic Find", "Coin approved concise copy")
	fresh()
	state.equip_legendary(gear("bandit_blade"))
	for pair in [[9, 0], [10, 1], [999, 99], [1000, 100], [5000, 100]]:
		state.set_practice_gold(pair[0])
		var lines := "\n".join(CardStyle.legendary_stat_lines(state.current_player_stats()))
		ck(lines.contains("+%d Base Physical Damage from current stash (cap +100)" % pair[1]), "Bandit live floor/cap at%d" % pair[0])
	state.equip_legendary(gear("deaths_door"))
	for pair in [[0, 1], [1, 2], [2, 4], [3, 6], [4, 8]]:
		state.set_legendary_missing_attempts(pair[0])
		var stats := state.current_player_stats()
		ck("\n".join(CardStyle.legendary_stat_lines(stats)).contains("Death's Door: x%d damage; Exsanguinate excluded" % pair[1]), "Door attempt output%d" % pair[0])
		stats.special_effects.legendary.unlimited_retries = true
		ck("\n".join(CardStyle.legendary_stat_lines(stats)).contains("Death's Door: x1 damage"), "opening unlimited retries staysx1 at%d" % pair[0])
	state.equipped_armor = null
	ck(not "\n".join(CardStyle.legendary_stat_lines(state.current_player_stats())).contains("Death's Door"), "no Door output without armor")

func _test_skills() -> void:
	for pair in [["umbral_stiletto", "Death Strike"], ["decrepit_blade", "Poison Strike"], ["nightkiss_kitana", "Exsanguinate"], ["cloak_of_speed", "Quick Cut"]]:
		fresh()
		var gained := compare(pair[0])
		ck(gained.contains("Skill gained: " + pair[1]), pair[0] + " real unlock shown")
		state.equip_legendary(gear(pair[0]))
		var other := _replacement_for(gear(pair[0]))
		ck(compare(other.id.trim_prefix("gear.legendary.")).contains("Skill lost: " + pair[1]), pair[0] + " lost unlock shown")
		var talent := Talent.new()
		talent.unlocked_skills = gear(pair[0]).unlocked_skills
		state.selected_talents = [talent]
		ck(not compare(other.id.trim_prefix("gear.legendary.")).contains("Skill lost: " + pair[1]), pair[0] + " shared skill source retained")
	fresh()
	state.equip_legendary(gear("umbral_stiletto"))
	var swap := compare("nightkiss_kitana")
	ck(swap.contains("Skill lost: Death Strike") and swap.contains("Skill gained: Exsanguinate"), "same-slot skill swap compares both directions")
	witness.comparisons["skill_swap"] = swap

func _test_effective_stats() -> void:
	fresh()
	var mithril := compare("mithril_karambit")
	ck(not mithril.contains("Retrigger Chance:") and not mithril.contains("rolls only"), "Mithril does not create false numeric retrigger comparison or duplicate effect explanation")
	fresh()
	state.equip_legendary(gear("mysterious_lucky_coin"))
	var signet := compare("signet_of_the_old_kings")
	var before: PlayerStats = state.current_player_stats()
	var after := BuildResolver.resolve_stats(state.selected_class, [], [], [gear("mysterious_lucky_coin"), gear("signet_of_the_old_kings")])
	ck(signet.contains("Cannot crit") and signet.contains("Attack Speed: 0%% -> %s%%" % LegendaryCatalog.number_text(after.attack_speed * 100.0)), "overcap Coin input shown as actual Signet conversion")
	ck(signet.contains("Attack Speed: 0%% -> %s%%" % LegendaryCatalog.number_text(after.attack_speed * 100.0)) and not signet.contains(".0000"), "Legendary comparisons use readable percentages and multipliers")
	ck(after.legendary_added_ias > 1.5 and before.crit_chance == 1.0, "fixture crosses100percent without inventing multiple crits")
	state.equip_legendary(gear("signet_of_the_old_kings"))
	ck(compare("signet_of_the_old_kings") == "Already equipped.", "already equipped preview does not duplicate owned contributions")
	var unequip := compare("lolzorzs_locket")
	ck(unequip.contains("Cannot crit ->") and unequip.contains("Attack Speed:"), "replacement restores actual crit output")
	witness.comparisons["signet_overcap"] = signet
	witness.comparisons["signet_replaced"] = unequip
