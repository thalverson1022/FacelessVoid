extends SceneTree
## Focused check for the enemy status HUD added to the black Combat panel
## (user-requested combat-HUD addition to the P2:R7 pass, 2026-07-18):
## pre-fight the HUD shows the current Monster at full HP/base armor/base
## resistance/zero stacks; post-fight it reflects the resolved
## CombatResult (empty bar on a win, remaining HP on a loss, final armor/
## resist after any shred, peak poison stacks); and it resets to the
## pre-fight state at new-fight transitions (retry). Follows
## combat_recap_test.gd's direct-call-plus-live-scene pattern, including its
## fixed _require()/_failed idiom (record failures, quit once at the end,
## await the live checks) so an awaited check can't be masked by an early
## quit().


static var HUD_ARMOR_ICON: Texture2D = GameIcons.icon_for("defense.armor")
static var HUD_RESISTANCE_ICON: Texture2D = GameIcons.icon_for("defense.resistance")
static var HUD_POISON_ICON: Texture2D = GameIcons.icon_for("status.poison")
static var HUD_SHRED_ICON: Texture2D = GameIcons.icon_for("status.shred")
static var HUD_DECAY_ICON: Texture2D = GameIcons.icon_for("status.decay")
static var MECHANIC_DODGE_ICON: Texture2D = GameIcons.icon_for("defense.dodge")
static var MECHANIC_CRIT_NEGATION_ICON: Texture2D = GameIcons.icon_for("defense.crit_negation")
static var MECHANIC_BLOCK_ICON: Texture2D = GameIcons.icon_for("defense.block")
static var MECHANIC_ABSORB_ICON: Texture2D = GameIcons.icon_for("defense.absorb")
static var MECHANIC_CLEANSE_ICON: Texture2D = GameIcons.icon_for("defense.cleanse")
static var MECHANIC_SUPPRESS_ICON: Texture2D = GameIcons.icon_for("defense.suppress")
static var MECHANIC_SLOW_ICON: Texture2D = GameIcons.icon_for("defense.slow")
static var MECHANIC_STUN_ICON: Texture2D = GameIcons.icon_for("defense.stun")
static var MECHANIC_INTERRUPT_ICON: Texture2D = GameIcons.icon_for("defense.interrupt")

var _failed := false


func _initialize() -> void:
	await _check_post_fight_helpers_against_known_fight()
	await _check_post_fight_helpers_honor_cleanse()
	await _check_enemy_effect_indicator_helpers()
	await _check_hidden_before_map_choice()
	await _check_live_pre_fight_and_win()
	await _check_live_loss_and_retry_reset()
	if _failed:
		print("Combat HUD check: FAILED")
		quit(1)
	else:
		print("Combat HUD check: OK")
		quit()


## Deterministic CombatResolver.resolve() fight exercising every mechanic
## the HUD derives (armor reduction, resistance reduction, poison
## stacks) against a monster too big to kill, so the post-fight helpers'
## outputs can be compared against independently computed values (not by
## re-calling the code under test).
func _check_post_fight_helpers_against_known_fight() -> void:
	var build_state = root.get_node("BuildState")
	build_state.reset()
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	build_state.set_class(rogue)

	var poison_strike: Skill = load("res://data/skills/poison_strike.tres")
	var rending_slash: Skill = load("res://data/skills/rending_slash.tres")
	var beguiling_strike: Skill = load("res://data/skills/beguiling_strike.tres")
	var rotation: Array[Skill] = [poison_strike, rending_slash, beguiling_strike]

	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 1.0
	player.crit_multiplier = 2.0
	player.poison_damage_per_tick = 5.0

	var monster := Monster.new()
	monster.display_name = "HUD Dummy"
	monster.hp = 100000
	monster.armor = 200
	monster.poison_resistance = 0.4

	var duration_ms := 9000
	var result: CombatResolver.CombatResult = CombatResolver.resolve(rotation, player, monster, duration_ms, 3)
	_require(not result.cast_events.is_empty(), "Expected at least one cast in the known fight.")
	_require(not result.is_win, "Expected the known fight to be a loss (100000 HP).")

	# -- Independently computed expected values, from the same result. --
	var expected_armor_reduction := 0
	var expected_shred_stacks := 0
	var expected_decay_stacks := 0
	var expected_resist := monster.poison_resistance
	for event in result.cast_events:
		expected_armor_reduction += event.armor_reduction_applied
		if event.armor_reduction_applied > 0:
			expected_shred_stacks += event.shred_stacks_applied
		if event.poison_resistance_reduction_applied > 0.0:
			expected_decay_stacks += event.decay_stacks_applied
			expected_resist *= 1.0 - event.poison_resistance_reduction_applied
	var expected_peak_stacks := 0
	for tick in result.tick_events:
		if tick.damage <= 0.0:
			continue
		var stacks_before: int = tick.stacks_remaining + 1
		if stacks_before > expected_peak_stacks:
			expected_peak_stacks = stacks_before
	_require(expected_armor_reduction > 0, "Expected Rending Slash to shred armor at least once in this known fight.")
	_require(expected_resist < monster.poison_resistance, "Expected Beguiling Strike to reduce resistance in this known fight.")
	_require(expected_peak_stacks > 0, "Expected Poison Strike to stack poison in this known fight.")

	var combat_screen := _instantiate_combat_screen()
	await process_frame
	print("-- Post-fight helper checks (known deterministic fight) --")

	var remaining: float = combat_screen._hud_post_fight_hp(result, monster)
	print("remaining HP: %.1f (total damage %.1f)" % [remaining, result.total_damage])
	_require(
		is_equal_approx(remaining, float(monster.hp) - result.total_damage),
		"Expected post-fight HP to be monster HP minus total damage dealt on a loss."
	)
	_require(remaining > 0.0, "Expected positive remaining HP for a losing fight.")

	var final_armor: int = combat_screen._hud_final_armor(result, monster)
	print("final armor: %d (base %d, reduced %d)" % [final_armor, monster.armor, expected_armor_reduction])
	_require(
		final_armor == monster.armor - expected_armor_reduction,
		"Expected final armor to be base armor minus every applied reduction."
	)

	var final_resist: float = combat_screen._hud_final_poison_resist(result, monster)
	print("final resist: %.3f (base %.3f)" % [final_resist, monster.poison_resistance])
	_require(
		is_equal_approx(final_resist, expected_resist),
		"Expected final resistance to apply each recorded reduction multiplicatively."
	)

	var peak_stacks: int = combat_screen._hud_peak_poison_stacks(result.tick_events)
	print("peak poison stacks: %d" % peak_stacks)
	_require(peak_stacks == expected_peak_stacks, "Expected peak stacks to match the independently computed value.")

	combat_screen._show_enemy_hud_post_fight(result, monster)
	var has_poison_icon := false
	var poison_tooltip := ""
	var has_shred_icon := false
	var shred_tooltip := ""
	var has_decay_icon := false
	var decay_tooltip := ""
	for child in combat_screen._hud_status_row.find_children("*", "HBoxContainer", true, false):
		var icon := child.get_node_or_null("Icon") as TextureRect
		var text := _status_chip_text(child)
		if icon != null and icon.texture == HUD_POISON_ICON and text == "x%d" % peak_stacks:
			has_poison_icon = true
			poison_tooltip = child.tooltip_text
		if icon != null and icon.texture == HUD_SHRED_ICON and text == "x%d" % expected_shred_stacks:
			has_shred_icon = true
			shred_tooltip = child.tooltip_text
		if icon != null and icon.texture == HUD_DECAY_ICON and text == "x%d" % expected_decay_stacks:
			has_decay_icon = true
			decay_tooltip = child.tooltip_text
	_require(has_poison_icon, "Expected the post-fight poison stack chip to use the selected skull icon.")
	_require(poison_tooltip == "Poison: Deals 8.0 damage every 1.0s", "Expected Poison chip tooltip to show the character sheet base tick damage, got: %s" % poison_tooltip)
	_require(has_shred_icon, "Expected the post-fight Shred chip to use the selected rogue icon and count applications.")
	_require(shred_tooltip == "Shred: Each stack reduces armor by 10", "Expected Shred chip tooltip to explain armor reduction value, got: %s" % shred_tooltip)
	_require(has_decay_icon, "Expected the post-fight Decay chip to use the selected mage icon and count applications.")
	_require(decay_tooltip == "Decay: Each stack reduces resistance by 20%", "Expected Decay chip tooltip to show the base Decay reduction, got: %s" % decay_tooltip)
	_require(combat_screen._hud_info_label.text == "%d" % final_armor, "Expected post-fight armor value to show current armor after Shred.")
	_require(combat_screen._hud_resist_label.text == "%.0f%%" % (final_resist * 100.0), "Expected post-fight resistance value to show current resistance after Decay.")

	# A winning result must clamp to exactly zero remaining HP.
	var small_monster := Monster.new()
	small_monster.display_name = "Small Fry"
	small_monster.hp = 10
	_require(
		is_equal_approx(combat_screen._hud_post_fight_hp(result, small_monster), 0.0),
		"Expected post-fight HP to clamp to zero when total damage exceeds monster HP."
	)

	combat_screen.queue_free()


func _check_post_fight_helpers_honor_cleanse() -> void:
	var rending_slash: Skill = load("res://data/skills/rending_slash.tres")
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	player.crit_multiplier = 2.0
	var monster := Monster.new()
	monster.display_name = "Cleanse HUD Dummy"
	monster.hp = 100000
	monster.armor = 100
	monster.cleanse_threshold = 5
	var result: CombatResolver.CombatResult = CombatResolver.resolve([rending_slash], player, monster, 7000, 3)
	_require(result.cast_events.size() == 5, "Expected exactly five Rending Slash casts for the cleanse HUD check.")
	_require(result.cast_events[4].cleanse_triggered, "Expected the fifth Rending Slash cast to trigger cleanse.")

	var combat_screen := _instantiate_combat_screen()
	await process_frame
	print("-- Post-fight helper cleanse reset check --")
	_require(combat_screen._hud_final_armor(result, monster) == monster.armor, "Expected final armor to return to base after cleanse.")
	_require(combat_screen._hud_armor_reduction_cast_count(result.cast_events) == 0, "Expected active Shred count to return to zero after cleanse.")
	combat_screen._show_enemy_hud_post_fight(result, monster)
	_require(combat_screen._hud_info_label.text == "%d" % monster.armor, "Expected post-fight armor readout to return to base after cleanse.")
	var has_zero_shred_icon := false
	for child in combat_screen._hud_status_row.find_children("*", "HBoxContainer", true, false):
		var icon := child.get_node_or_null("Icon") as TextureRect
		if icon != null and icon.texture == HUD_SHRED_ICON and _status_chip_text(child) == "x0":
			has_zero_shred_icon = true
	_require(has_zero_shred_icon, "Expected post-fight Shred chip to show x0 after cleanse.")
	combat_screen.queue_free()


func _check_enemy_effect_indicator_helpers() -> void:
	var combat_screen := _instantiate_combat_screen()
	await process_frame
	print("-- Enemy effect indicator HUD checks --")

	var monster := Monster.new()
	monster.display_name = "Effect HUD Dummy"
	monster.hp = 1000
	monster.armor = 80
	monster.poison_resistance = 0.25
	monster.dodge_chance = 0.12
	monster.crit_negation = 0.5
	monster.block = 3.0
	monster.absorb = 5.0
	monster.cleanse_threshold = 4
	monster.suppress = 0.35
	monster.slow = 0.2
	monster.stun_duration_ms = 300
	monster.interrupt_skip_count = 1

	var indicators: Array = combat_screen._enemy_effect_indicators(monster)
	_require(indicators.size() == 8, "Expected nonzero secondary defenses/effects to produce HUD indicators without duplicating armor/resist or the live interrupt counter.")
	for id in [
		"dodge_chance",
		"crit_negation",
		"block",
		"absorb",
		"cleanse_threshold",
		"suppress",
		"slow",
		"stun_duration_ms",
	]:
		_require(_indicator_ids(indicators).has(id), "Expected effect indicator for %s." % id)
	var expected_icons := {
		"dodge_chance": MECHANIC_DODGE_ICON,
		"crit_negation": MECHANIC_CRIT_NEGATION_ICON,
		"block": MECHANIC_BLOCK_ICON,
		"absorb": MECHANIC_ABSORB_ICON,
		"cleanse_threshold": MECHANIC_CLEANSE_ICON,
		"suppress": MECHANIC_SUPPRESS_ICON,
		"slow": MECHANIC_SLOW_ICON,
		"stun_duration_ms": MECHANIC_STUN_ICON,
	}
	for indicator in indicators:
		var id := String(indicator["id"])
		_require(indicator["icon"] == expected_icons[id], "Expected %s to use its assigned mechanic icon." % id)
	var expected_tooltips := {
		"dodge_chance": "Dodge: 12% chance for cast to miss",
		"crit_negation": "Crit Negation: Reduces crits by 50%",
		"block": "Block: Prevents 3 physical damage",
		"absorb": "Absorb: Prevents 5 elemental damage",
		"cleanse_threshold": "Cleanse: Removes all debuffs after 4 casts",
		"suppress": "Suppress: Damage over time ticks 35% slower",
		"slow": "Slow: Reduces attack speed by 20%",
		"stun_duration_ms": "Stun: Hitting for 12% of total health in a single hit stuns for 0.3s",
	}
	for indicator in indicators:
		var id := String(indicator["id"])
		_require(indicator["tooltip"] == expected_tooltips[id], "Expected %s tooltip to use the new plain-language wording." % id)

	combat_screen._set_enemy_hud_display(monster.display_name, float(monster.hp), monster.hp, monster.armor, monster.poison_resistance)
	combat_screen._refresh_enemy_effect_chips(monster)
	_require(combat_screen._hud_effect_row.get_parent() == combat_screen._enemy_hud, "Expected secondary enemy effect chips to use their own wrapping row under the health bar.")
	_require(combat_screen._hud_effect_row is FlowContainer, "Expected secondary enemy effect chips to wrap instead of overflowing the combat HUD.")
	_require(combat_screen._hud_effect_row.alignment == FlowContainer.ALIGNMENT_END, "Expected secondary enemy effect chips to right-align inside the wrapping row.")
	_require(combat_screen._hud_effect_row.get_index() > combat_screen._hud_health_bar.get_index(), "Expected secondary enemy effect chips below the health bar instead of in the top values row.")
	_require(combat_screen._hud_effect_row.get_child_count() == 8, "Expected the HUD effect row to render secondary enemy effects while interrupt lives in the status row.")
	_require(not _has_effect_chip(combat_screen._hud_effect_row, "armor", HUD_ARMOR_ICON, "80"), "Expected armor to stay in the existing armor value slot, not duplicate as an effect chip.")
	_require(not _has_effect_chip(combat_screen._hud_effect_row, "poison_resistance", HUD_RESISTANCE_ICON, "25%"), "Expected resist to stay in the existing resist value slot, not duplicate as an effect chip.")
	_require(_has_effect_chip(combat_screen._hud_effect_row, "block", MECHANIC_BLOCK_ICON, "3"), "Expected block effect chip in the wrapping effect row.")
	_require(_has_effect_chip(combat_screen._hud_effect_row, "absorb", MECHANIC_ABSORB_ICON, "5"), "Expected absorb effect chip in the wrapping effect row.")
	_require(_has_effect_chip(combat_screen._hud_effect_row, "suppress", MECHANIC_SUPPRESS_ICON, "35%"), "Expected suppress effect chip in the wrapping effect row.")
	_require(_has_effect_chip(combat_screen._hud_effect_row, "cleanse_threshold", MECHANIC_CLEANSE_ICON, "4"), "Expected cleanse effect chip in the wrapping effect row.")
	_require(_has_effect_chip(combat_screen._hud_effect_row, "slow", MECHANIC_SLOW_ICON, "20%"), "Expected slow effect chip in the wrapping effect row.")
	_require(_has_effect_chip(combat_screen._hud_effect_row, "stun_duration_ms", MECHANIC_STUN_ICON, "0.3s"), "Expected stun effect chip in the wrapping effect row.")
	_require(not _indicator_ids(indicators).has("interrupt_skip_count"), "Expected interrupt to stay out of the static effect row.")
	combat_screen._clear_hud_status_chips()
	combat_screen._add_interrupt_status_chip(monster, 0)
	_require(_has_status_chip(combat_screen._hud_status_row, MECHANIC_INTERRUPT_ICON, "0/3"), "Expected interrupt to render as a live status counter.")
	_require(not _effect_row_text(combat_screen._hud_effect_row).contains("seed"), "Enemy effect HUD must not expose seed/debug text.")
	_require(not _effect_row_text(combat_screen._hud_effect_row).contains("fortified"), "Enemy effect HUD must not expose archetype tags.")
	_require(not _effect_row_text(combat_screen._hud_effect_row).contains("budget"), "Enemy effect HUD must not expose budget/debug text.")

	var plain := Monster.new()
	plain.display_name = "Plain HUD Dummy"
	plain.hp = 100
	combat_screen._refresh_enemy_effect_chips(plain)
	_require(combat_screen._hud_effect_row.get_child_count() == 0, "Expected zero-defense monsters to keep the effect row clean.")

	combat_screen.queue_free()


## Before the Tavern map choice is made there is no fightable target, so the
## HUD must stay hidden (mirroring enemy_panel.gd's own empty-state gating).
func _check_hidden_before_map_choice() -> void:
	var build_state = root.get_node("BuildState")
	build_state.reset()
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	build_state.set_class(rogue)
	build_state.select_tree(rogue.trees[1])

	var combat_screen := _instantiate_combat_screen()
	await process_frame
	print("-- HUD hidden before Tavern map choice --")
	_require(build_state.needs_tavern_map_choice(), "Expected a fresh run to need the Tavern map choice.")
	_require(not combat_screen._enemy_hud.visible, "Expected the enemy HUD to stay hidden before a target is chosen.")
	combat_screen.queue_free()


## Live end-to-end: pre-fight display shows the chosen Tavern opener at full
## HP/base stats; a real winning fight (Quick Cut vs. Mouthy Drunk, same
## known-win rotation combat_recap_test.gd uses) empties the bar to exactly
## zero and stays chip-free (Quick Cut applies no poison/armor/resist
## effects).
func _check_live_pre_fight_and_win() -> void:
	var build_state = root.get_node("BuildState")
	build_state.reset()
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	build_state.set_class(rogue)
	build_state.select_tree(rogue.trees[1])
	build_state.choose_current_tavern_encounter()
	var quick_cut: Skill = load("res://data/skills/quick_cut.tres")
	var win_rotation: Array[Skill] = [quick_cut]
	build_state.rotation = win_rotation

	var combat_screen := _instantiate_combat_screen()
	await process_frame

	var fight_enemy_panel = combat_screen._enemy_panel
	var monster: Monster = fight_enemy_panel.monster()

	print("-- Live pre-fight HUD --")
	_require(combat_screen._enemy_hud.visible, "Expected the enemy HUD visible once a target is chosen.")
	print("name: %s | %s" % [combat_screen._hud_name_label.text, combat_screen._hud_hp_text_label.text])
	print(combat_screen._hud_info_label.text)
	_require(combat_screen._hud_name_label.text == monster.display_name, "Expected the HUD to name the current target.")
	_require(combat_screen._hud_hp_text_label.text == "%d/%d" % [monster.hp, monster.hp], "Expected icon-labeled full HP value pre-fight.")
	_require(combat_screen._hud_hp_text_label.get_parent().get_node_or_null("HealthIcon") != null, "Expected the HP text to include the selected heart icon.")
	_require(combat_screen._hud_hp_text_label.get_parent().name == "CombatValuesRow", "Expected HP, armor, and resistance values grouped in the top-right combat HUD row.")
	_require(is_equal_approx(combat_screen._hud_health_bar.value, float(monster.hp)), "Expected a full health bar pre-fight.")
	_require(is_equal_approx(combat_screen._hud_health_bar.max_value, float(monster.hp)), "Expected the health bar max to be monster HP.")
	_require(combat_screen._hud_health_bar.custom_minimum_size.y >= 18.0, "Expected the combat HP bar to use the deeper beveled height.")
	_require(combat_screen._hud_health_bar.get_theme_stylebox("background").border_color == UIColors.HEALTH_BAR_TRACK_BORDER, "Expected the combat HP bar track to use the shared gold-edged treatment.")
	_require(combat_screen._hud_health_bar.get_node_or_null("HealthBarDepthOverlay") != null, "Expected the combat HP bar to include its drawn bevel overlay.")
	_require(
		combat_screen._hud_info_label.text == "%d" % monster.armor,
		"Expected the shield-labeled pre-fight armor value to show base armor."
	)
	var armor_icon := combat_screen._hud_info_label.get_parent().get_node_or_null("ArmorIcon") as TextureRect
	_require(armor_icon != null, "Expected the armor readout to include the selected shield icon.")
	_require(armor_icon != null and armor_icon.tooltip_text == "Armor: Reduces Physical Damage", "Expected Armor tooltip to describe the physical defense role.")
	_require(combat_screen._hud_info_label.tooltip_text == "Armor: Reduces Physical Damage", "Expected Armor value label to share the armor tooltip.")
	_require(combat_screen._hud_resist_label.text == "%.0f%%" % (monster.poison_resistance * 100.0), "Expected the resistance value.")
	var resist_icon := combat_screen._hud_resist_label.get_parent().get_node_or_null("PoisonResistIcon") as TextureRect
	_require(resist_icon != null and resist_icon.texture == HUD_RESISTANCE_ICON, "Expected the resistance readout to include the selected resistance icon.")
	_require(resist_icon != null and resist_icon.tooltip_text == "Resistance: Reduces elemental damage", "Expected Resistance tooltip to describe elemental defense.")
	_require(combat_screen._hud_resist_label.tooltip_text == "Resistance: Reduces elemental damage", "Expected Resistance value label to share the resistance tooltip.")
	_require(_has_status_chip(combat_screen._hud_status_row, HUD_POISON_ICON, "x0"), "Expected Poison stack chip to stay visible at x0 pre-fight.")
	_require(_status_chip_tooltip(combat_screen._hud_status_row, HUD_POISON_ICON, "x0") == "Poison: Deals 8.0 damage every 1.0s", "Expected pre-fight Poison tooltip to show base poison damage.")
	_require(_has_status_chip(combat_screen._hud_status_row, HUD_SHRED_ICON, "x0"), "Expected Shred stack chip to stay visible at x0 pre-fight.")
	_require(_has_status_chip(combat_screen._hud_status_row, HUD_DECAY_ICON, "x0"), "Expected Decay stack chip to stay visible at x0 pre-fight.")
	_require(_status_chip_tooltip(combat_screen._hud_status_row, HUD_DECAY_ICON, "x0") == "Decay: Each stack reduces resistance by 20%", "Expected pre-fight Decay tooltip to show the base Decay reduction.")
	if monster.interrupt_skip_count > 0:
		_require(_has_status_chip(combat_screen._hud_status_row, MECHANIC_INTERRUPT_ICON, "0/3"), "Expected Interrupt counter chip to stay visible at 0/3 pre-fight.")
		_require(_status_chip_tooltip(combat_screen._hud_status_row, MECHANIC_INTERRUPT_ICON, "0/3") == "Interrupt: Casting 3 times prevents next %d casts" % monster.interrupt_skip_count, "Expected Interrupt tooltip to explain the repeat threshold and prevented casts.")
	else:
		_require(not _has_status_chip_with_icon(combat_screen._hud_status_row, MECHANIC_INTERRUPT_ICON), "Expected monsters without Interrupt to omit the interrupt counter chip.")
	_require(combat_screen._hud_status_row is FlowContainer, "Expected debuff stack chips to wrap instead of overflowing the combat HUD.")
	_require(combat_screen._hud_status_row.alignment == FlowContainer.ALIGNMENT_END, "Expected debuff stack chips to sit right-aligned below the health bar.")
	_require(_status_chip_font_size(combat_screen._hud_status_row, HUD_POISON_ICON) == 24, "Expected combat status values to use the larger number font.")
	_require(combat_screen._fight_timer_badge != null and combat_screen._fight_timer_badge.visible, "Expected a raised fight-window timer badge once a target is selected.")
	_require(combat_screen._fight_timer_badge.get_parent().name == "FightTimerCell", "Expected the fight-window timer badge to sit in the HUD top row above the health bar.")
	_require(combat_screen._fight_timer_badge.find_child("ClockIcon", true, false) != null, "Expected the fight-window timer badge to include the clock icon.")
	_require(combat_screen._fight_timer_label.text == "%ds" % ceili(float(fight_enemy_panel.duration_ms()) / 1000.0), "Expected the fight-window timer badge to show the current target duration before combat.")
	var playback_label := combat_screen._playback_controls.find_child("PlaybackLabel", true, false) as Label
	_require(playback_label != null, "Expected the combat playback controls to include a descriptive label.")
	_require(playback_label.text == "playback:", "Expected the combat playback controls label to read playback:.")
	_require(
		playback_label.get_theme_font_size("font_size") == combat_screen._hud_name_label.get_theme_font_size("font_size"),
		"Expected the playback label to match the enemy-name font size."
	)
	_require(combat_screen._playback_controls._speed_buttons[0].disabled, "Expected 1x to be auto-selected as the default playback speed.")
	_require(combat_screen._combat_stage != null, "Expected the combat window to own a stage layer.")
	_require(combat_screen._combat_stage.player_actor_anchor != null, "Expected a player actor anchor on the combat stage.")
	_require(combat_screen._combat_stage.enemy_actor_anchor != null, "Expected an enemy actor anchor on the combat stage.")
	_require(combat_screen._combat_stage.contact_effect_anchor != null, "Expected a contact effect anchor on the combat stage.")
	_require(combat_screen._combat_stage.floating_text_anchor != null, "Expected a floating text anchor on the combat stage.")
	_require(not combat_screen._combat_stage.debug_grid_visible, "Expected Adventure combat to keep the sprite-placement debug grid hidden.")
	_require(combat_screen._combat_stage._enemy_name_label.text == monster.display_name, "Expected the combat stage enemy actor label data to track the current target.")
	_require(not combat_screen._combat_stage._enemy_name_label.visible, "Expected Adventure combat to hide the enemy name inside the combat window.")
	_require(combat_screen._combat_stage.player_actor_anchor.get_node_or_null("PlayerSprite") != null, "Expected the combat stage to expose a configured player sprite slot.")
	_require(combat_screen._combat_stage.enemy_actor_anchor.get_node_or_null("EnemySprite") != null, "Expected the combat stage to expose a configured enemy sprite slot.")
	var expected_player_paths: PackedStringArray = combat_screen._combat_stage.expected_player_sprite_paths()
	var expected_enemy_paths: PackedStringArray = combat_screen._combat_stage.expected_enemy_sprite_paths(monster.display_name)
	_require(expected_player_paths.has("res://assets/placeholder_combat_sprites/rogue_bandit/animations/idle/frames/frame_001.png"), "Expected normalized Rogue idle frame import path configured.")
	_require(expected_player_paths.has("res://assets/placeholder_combat_sprites/rogue_bandit/animations/attack1/frames/frame_001.png"), "Expected normalized Rogue physical attack frame import path configured.")
	_require(expected_player_paths.has("res://assets/placeholder_combat_sprites/rogue_bandit/animations/attack2/frames/frame_001.png"), "Expected normalized Rogue poison attack frame import path configured.")
	_require(expected_enemy_paths.has("res://assets/placeholder_combat_sprites/townsfolk/peasants_sprite_sheet.png"), "Expected Mouthy Drunk peasant sprite sheet import path configured.")
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region(monster.display_name, "idle") == Rect2(Vector2(0, 0), Vector2(32, 32)),
		"Expected Mouthy Drunk idle to use the top-left peasant standing frame."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region(monster.display_name, "hurt") == Rect2(Vector2(0, 64), Vector2(32, 32)),
		"Expected Mouthy Drunk hurt to use the first arms-up recoil frame."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region(monster.display_name, "defeat") == Rect2(Vector2(0, 96), Vector2(32, 32)),
		"Expected Mouthy Drunk defeat to use the first prone frame."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_paths("Drunk Buddy").has("res://assets/placeholder_combat_sprites/townsfolk/peasants_sprite_sheet.png"),
		"Expected Drunk Buddy peasant sprite sheet import path configured."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region("Drunk Buddy", "idle") == Rect2(Vector2(0, 256), Vector2(32, 32)),
		"Expected Drunk Buddy idle to use the first frame from peasant sheet row 9."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region("Drunk Buddy", "hurt") == Rect2(Vector2(0, 320), Vector2(32, 32)),
		"Expected Drunk Buddy hurt to use the first recoil frame from peasant sheet row 11."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region("Drunk Buddy", "defeat") == Rect2(Vector2(0, 352), Vector2(32, 32)),
		"Expected Drunk Buddy defeat to use the first prone frame from peasant sheet row 12."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_paths("Tavern Bouncer").has("res://assets/placeholder_combat_sprites/townsfolk/medieval_townsfolk_sprite_sheet.png"),
		"Expected Tavern Bouncer medieval townsfolk sprite sheet import path configured."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region("Tavern Bouncer", "idle") == Rect2(Vector2(0, 320), Vector2(32, 32)),
		"Expected Tavern Bouncer idle to use the first frame from medieval townsfolk sheet row 11."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region("Tavern Bouncer", "hurt") == Rect2(Vector2(0, 384), Vector2(32, 32)),
		"Expected Tavern Bouncer hurt to use the first recoil frame from medieval townsfolk sheet row 13."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region("Tavern Bouncer", "defeat") == Rect2(Vector2(0, 448), Vector2(32, 32)),
		"Expected Tavern Bouncer defeat to use the first prone frame from medieval townsfolk sheet row 15."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_paths("Hired Goon").has("res://assets/placeholder_combat_sprites/townsfolk/medieval_townsfolk_2_sprite_sheet.png"),
		"Expected Hired Goon medieval townsfolk 2 sprite sheet import path configured."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region("Hired Goon", "idle") == Rect2(Vector2(0, 320), Vector2(32, 32)),
		"Expected Hired Goon idle to use the first frame from medieval townsfolk 2 sheet row 11."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region("Hired Goon", "hurt") == Rect2(Vector2(0, 384), Vector2(32, 32)),
		"Expected Hired Goon hurt to use the first recoil frame from medieval townsfolk 2 sheet row 13."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region("Hired Goon", "defeat") == Rect2(Vector2(0, 448), Vector2(32, 32)),
		"Expected Hired Goon defeat to use the first prone frame from medieval townsfolk 2 sheet row 15."
	)
	var hired_goon_visual_reuse := [
		"Door Guard",
		"Cloaked Watchmen",
		"Armored Guard",
		"Sleeping Henchman",
		"Portly Cook",
		"Patrolling Guard",
		"Lazy Henchman",
		"Venom-Resistant Slime",
		"Training Dummy",
		"Placeholder Dummy",
	]
	for reused_enemy_name in hired_goon_visual_reuse:
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_paths(reused_enemy_name).has("res://assets/placeholder_combat_sprites/townsfolk/medieval_townsfolk_2_sprite_sheet.png"),
			"Expected %s to reuse the Hired Goon medieval townsfolk 2 sprite sheet." % reused_enemy_name
		)
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_region(reused_enemy_name, "idle") == Rect2(Vector2(0, 320), Vector2(32, 32)),
			"Expected %s to reuse the Hired Goon idle frame." % reused_enemy_name
		)
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_region(reused_enemy_name, "hurt") == Rect2(Vector2(0, 384), Vector2(32, 32)),
			"Expected %s to reuse the Hired Goon hurt frame." % reused_enemy_name
		)
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_region(reused_enemy_name, "defeat") == Rect2(Vector2(0, 448), Vector2(32, 32)),
			"Expected %s to reuse the Hired Goon defeat frame." % reused_enemy_name
		)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_paths("Vyra").has("res://assets/placeholder_combat_sprites/townsfolk/medieval_townsfolk_3_sprite_sheet.png"),
		"Expected Vyra medieval townsfolk 3 sprite sheet import path configured."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region("Vyra", "idle") == Rect2(Vector2(0, 320), Vector2(32, 32)),
		"Expected Vyra idle to use the first frame from medieval townsfolk 3 sheet row 11."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region("Vyra", "hurt") == Rect2(Vector2(0, 384), Vector2(32, 32)),
		"Expected Vyra hurt to use the first recoil frame from medieval townsfolk 3 sheet row 13."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region("Vyra", "defeat") == Rect2(Vector2(0, 448), Vector2(32, 32)),
		"Expected Vyra defeat to use the first prone frame from medieval townsfolk 3 sheet row 15."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_paths("Knives").has("res://assets/placeholder_combat_sprites/townsfolk/medieval_thief_sprite_sheet.png"),
		"Expected Knives medieval thief sprite sheet import path configured."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region("Knives", "idle") == Rect2(Vector2(0, 0), Vector2(32, 32)),
		"Expected Knives idle to use the first frame from medieval thief sheet row 1."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region("Knives", "hurt") == Rect2(Vector2(0, 160), Vector2(32, 32)),
		"Expected Knives hurt to use the first recoil frame from medieval thief sheet row 6."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_region("Knives", "defeat") == Rect2(Vector2(0, 224), Vector2(32, 32)),
		"Expected Knives defeat to use the first prone frame from medieval thief sheet row 8."
	)
	var swamp_sprite_cases := [
		{"name": "Green Slime", "path": "res://assets/enemies/swamp/slime.png", "size": Vector2(1254, 1254)},
		{"name": "Swamp Goblin", "path": "res://assets/enemies/swamp/goblin.png", "size": Vector2(1254, 1254)},
		{"name": "Bog Rat", "path": "res://assets/enemies/swamp/rat.png", "size": Vector2(1254, 1254)},
		{"name": "Giant Leech", "path": "res://assets/enemies/swamp/leech.png", "size": Vector2(1254, 1254)},
		{"name": "Poison Frog", "path": "res://assets/enemies/swamp/frog.png", "size": Vector2(1254, 1254)},
		{"name": "Troll", "path": "res://assets/enemies/swamp/Troll.png", "size": Vector2(1254, 1254)},
		{"name": "Bog Witch", "path": "res://assets/enemies/swamp/witch.png", "size": Vector2(1254, 1254)},
		{"name": "Hydra Spawn", "path": "res://assets/enemies/swamp/baby_hydra.png", "size": Vector2(1254, 1254)},
		{"name": "Mire Knight", "path": "res://assets/enemies/swamp/Mire_Knight.png", "size": Vector2(1254, 1254)},
		{"name": "Green Hag", "path": "res://assets/enemies/swamp/Green_Hag.png", "size": Vector2(1254, 1254)},
		{"name": "Swamp Hydra", "path": "res://assets/enemies/swamp/Big_Hydra.png", "size": Vector2(1254, 1254)},
		{"name": "Ancient Troll", "path": "res://assets/enemies/swamp/Troll_Boss.png", "size": Vector2(1254, 1254)},
		{"name": "Slime Queen", "path": "res://assets/enemies/swamp/Slime_Queen.png", "size": Vector2(1254, 1254)},
		{"name": "The Drowned Matriarch", "path": "res://assets/enemies/swamp/Downed_Matriarch.png", "size": Vector2(1360, 1157)},
		{"name": "Bogheart Colossus", "path": "res://assets/enemies/swamp/Bog_Colossus.png", "size": Vector2(1254, 1254)},
	]
	for sprite_case in swamp_sprite_cases:
		var swamp_name: String = sprite_case["name"]
		var swamp_path: String = sprite_case["path"]
		var swamp_size: Vector2 = sprite_case["size"]
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_paths(swamp_name).has(swamp_path),
			"Expected %s to resolve to %s." % [swamp_name, swamp_path]
		)
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_region(swamp_name, "hurt") == Rect2(Vector2.ZERO, swamp_size),
			"Expected %s static hurt frame to use the full PNG." % swamp_name
		)
	var left_facing_swamp_cases := [
		"Green Slime",
		"Troll",
		"Hydra Spawn",
		"Green Hag",
		"Swamp Hydra",
		"Ancient Troll",
		"Slime Queen",
		"Bogheart Colossus",
	]
	for swamp_name in left_facing_swamp_cases:
		var visual_key: String = combat_screen._combat_stage.enemy_visual_key_for(swamp_name)
		_require(
			bool(combat_screen._combat_stage.STATIC_ENEMY_FLIP_H_BY_VISUAL_KEY.get(visual_key, false)),
			"Expected %s to be flipped horizontally so it faces left toward the player." % swamp_name
		)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_paths("Veteran Green Slime").has("res://assets/enemies/swamp/slime.png"),
		"Expected Veteran-prefixed Swamp enemies to reuse their base static sprite."
	)
	var promoted_sprite_cases := [
		{"name": "Giant Green Slime", "path": "res://assets/enemies/swamp/slime.png"},
		{"name": "Veteran Swamp Goblin", "path": "res://assets/enemies/swamp/goblin.png"},
		{"name": "Giant Bog Rat", "path": "res://assets/enemies/swamp/rat.png"},
		{"name": "Elder Leech", "path": "res://assets/enemies/swamp/leech.png"},
		{"name": "Giant Poison Frog", "path": "res://assets/enemies/swamp/frog.png"},
		{"name": "Giant Vampire Bat", "path": "res://assets/enemies/cave/bat.png"},
		{"name": "Giant Wolf Spider", "path": "res://assets/enemies/cave/spider.png"},
		{"name": "Veteran Goblin", "path": "res://assets/enemies/cave/goblin.png"},
		{"name": "Veteran Troglodyte", "path": "res://assets/enemies/cave/troglodyte.png"},
		{"name": "Veteran Ogre", "path": "res://assets/enemies/cave/Ogre.png"},
	]
	for promoted_case in promoted_sprite_cases:
		var promoted_name := String(promoted_case["name"])
		var promoted_path := String(promoted_case["path"])
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_paths(promoted_name).has(promoted_path),
			"Expected promoted captain name %s to reuse %s." % [promoted_name, promoted_path]
		)
	var promoted_map_monster := Monster.new()
	promoted_map_monster.display_name = "Giant Poison Frog"
	_require(
		combat_screen._map_overlay._map_actor_visual_key(promoted_map_monster) == combat_screen._combat_stage.SWAMP_POISON_FROG_VISUAL_KEY,
		"Expected map marker lookup to reuse the base Poison Frog sprite for Giant Poison Frog."
	)
	var cave_sprite_cases := [
		{"name": "Vampire Bat", "path": "res://assets/enemies/cave/bat.png", "size": Vector2(1254, 1254)},
		{"name": "Wolf Spider", "path": "res://assets/enemies/cave/spider.png", "size": Vector2(1254, 1254)},
		{"name": "Goblin", "path": "res://assets/enemies/cave/goblin.png", "size": Vector2(1254, 1254)},
		{"name": "Troglodyte", "path": "res://assets/enemies/cave/troglodyte.png", "size": Vector2(1254, 1254)},
		{"name": "Ogre", "path": "res://assets/enemies/cave/Ogre.png", "size": Vector2(1254, 1254)},
		{"name": "Cave Troll", "path": "res://assets/enemies/cave/Troll.png", "size": Vector2(1254, 1254)},
		{"name": "Giant Centipede", "path": "res://assets/enemies/cave/Giant_Centipede.png", "size": Vector2(1254, 1254)},
		{"name": "Basilisk", "path": "res://assets/enemies/cave/Basilisk.png", "size": Vector2(1254, 1254)},
		{"name": "Cave Brute", "path": "res://assets/enemies/cave/cave_brute.png", "size": Vector2(1254, 1254)},
		{"name": "Echoing Seer", "path": "res://assets/enemies/cave/echoing_seer.png", "size": Vector2(1254, 1254)},
		{"name": "Purple Cave Wyrm", "path": "res://assets/enemies/cave/Purple_cave_wyrm.png", "size": Vector2(1254, 1254)},
		{"name": "The Goblin King", "path": "res://assets/enemies/cave/Goblin_king.png", "size": Vector2(1290, 1219)},
		{"name": "Ancient Basilisk", "path": "res://assets/enemies/cave/Ancient_basilisk.png", "size": Vector2(1254, 1254)},
		{"name": "The Deep Maw", "path": "res://assets/enemies/cave/Deep_maw.png", "size": Vector2(1254, 1254)},
		{"name": "Gemvein Tyrant", "path": "res://assets/enemies/cave/Gemvein_tyrant.png", "size": Vector2(1287, 1222)},
	]
	for sprite_case in cave_sprite_cases:
		var cave_name: String = sprite_case["name"]
		var cave_path: String = sprite_case["path"]
		var cave_size: Vector2 = sprite_case["size"]
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_paths(cave_name).has(cave_path),
			"Expected %s to resolve to %s." % [cave_name, cave_path]
		)
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_region(cave_name, "hurt") == Rect2(Vector2.ZERO, cave_size),
			"Expected %s static hurt frame to use the full PNG." % cave_name
		)
	var graveyard_sprite_cases := [
		{"name": "Restless Spirit", "path": "res://assets/enemies/graveyard/Restless_Spirit.png", "size": Vector2(1151, 1367)},
		{"name": "Giant Rat", "path": "res://assets/enemies/graveyard/rat.png", "size": Vector2(1254, 1254)},
		{"name": "Wolf", "path": "res://assets/enemies/graveyard/wolf.png", "size": Vector2(1254, 1254)},
		{"name": "Skeleton", "path": "res://assets/enemies/graveyard/skeleton.png", "size": Vector2(1254, 1254)},
		{"name": "Zombie", "path": "res://assets/enemies/graveyard/zombie.png", "size": Vector2(1254, 1254)},
		{"name": "Flesh Golem", "path": "res://assets/enemies/graveyard/Flesh_Golem.png", "size": Vector2(1219, 1290)},
		{"name": "Grave Robber", "path": "res://assets/enemies/graveyard/grave_robber.png", "size": Vector2(1224, 1285)},
		{"name": "Wight", "path": "res://assets/enemies/graveyard/wight.png", "size": Vector2(1167, 1347)},
		{"name": "Necromancer", "path": "res://assets/enemies/graveyard/necromancer.png", "size": Vector2(1239, 1269)},
		{"name": "Graveyard Mire Knight", "path": "res://assets/enemies/graveyard/Mire_Knight.png", "size": Vector2(1236, 1272)},
		{"name": "Bone Colossus", "path": "res://assets/enemies/graveyard/Bone_colossus.png", "size": Vector2(1254, 1254)},
		{"name": "Lich", "path": "res://assets/enemies/graveyard/Lich.png", "size": Vector2(1024, 1536)},
		{"name": "Headless Knight", "path": "res://assets/enemies/graveyard/Headless_Knight.png", "size": Vector2(1254, 1254)},
		{"name": "The Bell-Tower Revenant", "path": "res://assets/enemies/graveyard/The_Bell-Tower_Revenant.png", "size": Vector2(1254, 1254)},
		{"name": "King Leoric", "path": "res://assets/enemies/graveyard/King_Leoric.png", "size": Vector2(1254, 1254)},
	]
	for sprite_case in graveyard_sprite_cases:
		var graveyard_name: String = sprite_case["name"]
		var graveyard_path: String = sprite_case["path"]
		var graveyard_size: Vector2 = sprite_case["size"]
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_paths(graveyard_name).has(graveyard_path),
			"Expected %s to resolve to %s." % [graveyard_name, graveyard_path]
		)
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_region(graveyard_name, "hurt") == Rect2(Vector2.ZERO, graveyard_size),
			"Expected %s static hurt frame to use the full PNG." % graveyard_name
		)
	var left_facing_graveyard_cases := [
		"Wolf",
		"Skeleton",
		"Wight",
		"Necromancer",
		"Graveyard Mire Knight",
		"Headless Knight",
		"The Bell-Tower Revenant",
		"King Leoric",
	]
	for graveyard_name in left_facing_graveyard_cases:
		var visual_key: String = combat_screen._combat_stage.enemy_visual_key_for(graveyard_name)
		_require(
			bool(combat_screen._combat_stage.STATIC_ENEMY_FLIP_H_BY_VISUAL_KEY.get(visual_key, false)),
			"Expected %s to be flipped horizontally so it faces left toward the player." % graveyard_name
		)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_paths("Ancient Restless Spirit").has("res://assets/enemies/graveyard/Restless_Spirit.png"),
		"Expected promoted Graveyard Restless Spirit to reuse the base static sprite."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_paths("Dire Rat").has("res://assets/enemies/graveyard/rat.png"),
		"Expected promoted Graveyard Giant Rat to reuse the base static sprite."
	)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_paths("Giant Wolf").has("res://assets/enemies/graveyard/wolf.png"),
		"Expected promoted Graveyard Wolf to reuse the base static sprite."
	)
	var forest_sprite_cases := [
		{"name": "Haunted Forest Spider", "path": "res://assets/enemies/forest/spider.png", "size": Vector2(1254, 1254)},
		{"name": "Haunted Forest Forest Goblin", "path": "res://assets/enemies/forest/goblin.png", "size": Vector2(1254, 1254)},
		{"name": "Haunted Forest Wisp", "path": "res://assets/enemies/forest/wisp.png", "size": Vector2(1254, 1254)},
		{"name": "Haunted Forest Treant Sapling", "path": "res://assets/enemies/forest/sapling.png", "size": Vector2(1254, 1254)},
		{"name": "Haunted Forest Dire Wolf", "path": "res://assets/enemies/forest/wolf.png", "size": Vector2(1254, 1254)},
		{"name": "Haunted Forest Werewolf", "path": "res://assets/enemies/forest/Warewolf.png", "size": Vector2(1254, 1254)},
		{"name": "Haunted Forest Treant", "path": "res://assets/enemies/forest/treant.png", "size": Vector2(1254, 1254)},
		{"name": "Haunted Forest Green Hag", "path": "res://assets/enemies/forest/Green_Hag.png", "size": Vector2(1254, 1254)},
		{"name": "Haunted Forest Night Stalker", "path": "res://assets/enemies/forest/night_stalker.png", "size": Vector2(1254, 1254)},
		{"name": "Haunted Forest Hollow-Eyed Witch", "path": "res://assets/enemies/forest/Hallow_Eyed__Witch.png", "size": Vector2(1254, 1254)},
		{"name": "Haunted Forest Ancient Treant", "path": "res://assets/enemies/forest/Ancient_Treant.png", "size": Vector2(1158, 1359)},
		{"name": "Haunted Forest Forest Witch", "path": "res://assets/enemies/forest/Hallow_Eyed__Witch.png", "size": Vector2(1254, 1254)},
		{"name": "Haunted Forest Great Warebear", "path": "res://assets/enemies/forest/Great_Warebear.png", "size": Vector2(1254, 1254)},
		{"name": "Haunted Forest The Root-Crowned Widow", "path": "res://assets/enemies/forest/Root_Crowned_Widow.png", "size": Vector2(1312, 1199)},
		{"name": "Haunted Forest Moonless Huntmaster", "path": "res://assets/enemies/forest/Moonless_Huntmaster.png", "size": Vector2(1254, 1254)},
	]
	for sprite_case in forest_sprite_cases:
		var forest_name: String = sprite_case["name"]
		var forest_path: String = sprite_case["path"]
		var forest_size: Vector2 = sprite_case["size"]
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_paths(forest_name).has(forest_path),
			"Expected %s to resolve to %s." % [forest_name, forest_path]
		)
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_region(forest_name, "hurt") == Rect2(Vector2.ZERO, forest_size),
			"Expected %s static hurt frame to use the full PNG." % forest_name
		)
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_paths("Green Hag").has("res://assets/enemies/swamp/Green_Hag.png"),
		"Expected unqualified Green Hag to keep resolving to Swamp art."
	)
	var promoted_forest_sprite_cases := [
		{"name": "Haunted Forest Giant Spider", "path": "res://assets/enemies/forest/spider.png"},
		{"name": "Haunted Forest Veteran Forest Goblin", "path": "res://assets/enemies/forest/goblin.png"},
		{"name": "Haunted Forest Ancient Wisp", "path": "res://assets/enemies/forest/wisp.png"},
		{"name": "Haunted Forest Ancient Treant Sapling", "path": "res://assets/enemies/forest/sapling.png"},
		{"name": "Haunted Forest Alpha Dire Wolf", "path": "res://assets/enemies/forest/wolf.png"},
	]
	for promoted_case in promoted_forest_sprite_cases:
		var promoted_forest_name := String(promoted_case["name"])
		var promoted_forest_path := String(promoted_case["path"])
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_paths(promoted_forest_name).has(promoted_forest_path),
			"Expected promoted Forest name %s to reuse %s." % [promoted_forest_name, promoted_forest_path]
		)
	var left_facing_forest_cases := [
		"Haunted Forest Wisp",
		"Haunted Forest Treant Sapling",
		"Haunted Forest Werewolf",
		"Haunted Forest Treant",
		"Haunted Forest Ancient Treant",
		"Haunted Forest Green Hag",
		"Haunted Forest Night Stalker",
		"Haunted Forest Great Warebear",
	]
	for forest_name in left_facing_forest_cases:
		var forest_visual_key: String = combat_screen._combat_stage.enemy_visual_key_for(forest_name)
		_require(
			bool(combat_screen._combat_stage.STATIC_ENEMY_FLIP_H_BY_VISUAL_KEY.get(forest_visual_key, false)),
			"Expected %s to be flipped horizontally so it faces left toward the player." % forest_name
		)
	var keep_sprite_cases := [
		{"name": "Ruined Keep Rat", "path": "res://assets/enemies/keep/rat.png", "size": Vector2(1254, 1254)},
		{"name": "Ruined Keep Undead Guard", "path": "res://assets/enemies/keep/undead_guard.png", "size": Vector2(1242, 1266)},
		{"name": "Ruined Keep Bandit", "path": "res://assets/enemies/keep/bandit.png", "size": Vector2(1254, 1254)},
		{"name": "Ruined Keep Cultist", "path": "res://assets/enemies/keep/cultist.png", "size": Vector2(1254, 1254)},
		{"name": "Ruined Keep Animated Armor", "path": "res://assets/enemies/keep/animated_armor.png", "size": Vector2(1254, 1254)},
		{"name": "Ruined Keep Gargoyle", "path": "res://assets/enemies/keep/Gargoyle.png", "size": Vector2(1254, 1254)},
		{"name": "Ruined Keep Warlock", "path": "res://assets/enemies/keep/warlock.png", "size": Vector2(1254, 1254)},
		{"name": "Ruined Keep Dark Knight", "path": "res://assets/enemies/keep/Dark_Knight.png", "size": Vector2(1254, 1254)},
		{"name": "Ruined Keep Oathbreaker Captain", "path": "res://assets/enemies/keep/Oathbreaker_Captain.png", "size": Vector2(1254, 1254)},
		{"name": "Ruined Keep Arcane Golem", "path": "res://assets/enemies/keep/Arcane_Golem.png", "size": Vector2(1254, 1254)},
		{"name": "Ruined Keep Fallen King", "path": "res://assets/enemies/keep/Fallen_King.png", "size": Vector2(1254, 1254)},
		{"name": "Ruined Keep Bejeweled Iron Golem", "path": "res://assets/enemies/keep/Bejeweled_Iron_Golem.png", "size": Vector2(1254, 1254)},
		{"name": "Ruined Keep The Half-blood Prince", "path": "res://assets/enemies/keep/Half_Blood_Prince.png", "size": Vector2(1254, 1254)},
		{"name": "Ruined Keep The Last Castellan", "path": "res://assets/enemies/keep/Last_Castellan.png", "size": Vector2(1254, 1254)},
		{"name": "Ruined Keep Faithless Executioner", "path": "res://assets/enemies/keep/Faithless_Executioner.png", "size": Vector2(1254, 1254)},
	]
	for sprite_case in keep_sprite_cases:
		var keep_name: String = sprite_case["name"]
		var keep_path: String = sprite_case["path"]
		var keep_size: Vector2 = sprite_case["size"]
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_paths(keep_name).has(keep_path),
			"Expected %s to resolve to %s." % [keep_name, keep_path]
		)
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_region(keep_name, "hurt") == Rect2(Vector2.ZERO, keep_size),
			"Expected %s static hurt frame to use the full PNG." % keep_name
		)
	var left_facing_keep_cases := [
		"Ruined Keep Bandit",
		"Ruined Keep Cultist",
		"Ruined Keep Animated Armor",
		"Ruined Keep Gargoyle",
		"Ruined Keep Dark Knight",
		"Ruined Keep Oathbreaker Captain",
		"Ruined Keep Fallen King",
		"Ruined Keep Bejeweled Iron Golem",
		"Ruined Keep The Half-blood Prince",
		"Ruined Keep The Last Castellan",
		"Ruined Keep Faithless Executioner",
	]
	for keep_name in left_facing_keep_cases:
		var keep_visual_key: String = combat_screen._combat_stage.enemy_visual_key_for(keep_name)
		_require(
			bool(combat_screen._combat_stage.STATIC_ENEMY_FLIP_H_BY_VISUAL_KEY.get(keep_visual_key, false)),
			"Expected %s to be flipped horizontally so it faces left toward the player." % keep_name
		)
	var authored_left_keep_cases := [
		"Ruined Keep Arcane Golem",
		"Ruined Keep Rat",
		"Ruined Keep Undead Guard",
		"Ruined Keep Warlock",
	]
	for keep_name in authored_left_keep_cases:
		var keep_visual_key: String = combat_screen._combat_stage.enemy_visual_key_for(keep_name)
		_require(
			not bool(combat_screen._combat_stage.STATIC_ENEMY_FLIP_H_BY_VISUAL_KEY.get(keep_visual_key, false)),
			"Expected %s to keep its authored facing." % keep_name
		)
	var promoted_keep_sprite_cases := [
		{"name": "Ruined Keep Giant Rat", "path": "res://assets/enemies/keep/rat.png"},
		{"name": "Ruined Keep Ancient Undead Guard", "path": "res://assets/enemies/keep/undead_guard.png"},
		{"name": "Ruined Keep Veteran Bandit", "path": "res://assets/enemies/keep/bandit.png"},
		{"name": "Ruined Keep Veteran Cultist", "path": "res://assets/enemies/keep/cultist.png"},
		{"name": "Ruined Keep Ancient Animated Armor", "path": "res://assets/enemies/keep/animated_armor.png"},
	]
	for promoted_case in promoted_keep_sprite_cases:
		var promoted_keep_name := String(promoted_case["name"])
		var promoted_keep_path := String(promoted_case["path"])
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_paths(promoted_keep_name).has(promoted_keep_path),
			"Expected promoted Keep name %s to reuse %s." % [promoted_keep_name, promoted_keep_path]
		)
	var ruins_sprite_cases := [
		{"name": "Ancient Ruins Cultist", "path": "res://assets/enemies/ruins/cultist.png", "size": Vector2(1254, 1254)},
		{"name": "Ancient Ruins Animated Statue", "path": "res://assets/enemies/ruins/Animated_Statue.png", "size": Vector2(1254, 1254)},
		{"name": "Ancient Ruins Scarab", "path": "res://assets/enemies/ruins/scrarab.png", "size": Vector2(1254, 1254)},
		{"name": "Ancient Ruins Wisp", "path": "res://assets/enemies/ruins/wisp.png", "size": Vector2(1254, 1254)},
		{"name": "Ancient Ruins Minotaur", "path": "res://assets/enemies/ruins/Minotaur.png", "size": Vector2(1254, 1254)},
		{"name": "Ancient Ruins Guardian Construct", "path": "res://assets/enemies/ruins/Guardian_Construct.png", "size": Vector2(1254, 1254)},
		{"name": "Ancient Ruins Arcane Golem", "path": "res://assets/enemies/ruins/Arcane_Golem.png", "size": Vector2(1254, 1254)},
		{"name": "Ancient Ruins Runemark Sentinel", "path": "res://assets/enemies/ruins/Runemark_sentinal.png", "size": Vector2(1254, 1254)},
		{"name": "Ancient Ruins Scarab Queen", "path": "res://assets/enemies/ruins/Scarab_Queen.png", "size": Vector2(1254, 1254)},
		{"name": "Ancient Ruins Ancient Guardian", "path": "res://assets/enemies/ruins/Ancient_Guardian.png", "size": Vector2(1312, 1199)},
		{"name": "Ancient Ruins Sphinx", "path": "res://assets/enemies/ruins/Sphinx.png", "size": Vector2(1408, 1117)},
		{"name": "Ancient Ruins Runic Colossus", "path": "res://assets/enemies/ruins/Runic_Collosus.png", "size": Vector2(1327, 1185)},
		{"name": "Ancient Ruins The First Idol", "path": "res://assets/enemies/ruins/First_idol.png", "size": Vector2(1312, 1199)},
		{"name": "Ancient Ruins Ancient Archivist", "path": "res://assets/enemies/ruins/Ancient_Archivist.png", "size": Vector2(1207, 1303)},
	]
	for sprite_case in ruins_sprite_cases:
		var ruins_name: String = sprite_case["name"]
		var ruins_path: String = sprite_case["path"]
		var ruins_size: Vector2 = sprite_case["size"]
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_paths(ruins_name).has(ruins_path),
			"Expected %s to resolve to %s." % [ruins_name, ruins_path]
		)
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_region(ruins_name, "hurt") == Rect2(Vector2.ZERO, ruins_size),
			"Expected %s static hurt frame to use the full PNG." % ruins_name
		)
	var left_facing_ruins_cases := [
		"Ancient Ruins Cultist",
		"Ancient Ruins Animated Statue",
		"Ancient Ruins Wisp",
		"Ancient Ruins Minotaur",
		"Ancient Ruins Guardian Construct",
	]
	for ruins_name in left_facing_ruins_cases:
		var ruins_visual_key: String = combat_screen._combat_stage.enemy_visual_key_for(ruins_name)
		_require(
			bool(combat_screen._combat_stage.STATIC_ENEMY_FLIP_H_BY_VISUAL_KEY.get(ruins_visual_key, false)),
			"Expected %s to be flipped horizontally so it faces left toward the player." % ruins_name
		)
	var authored_left_ruins_cases := [
		"Ancient Ruins Scarab",
		"Ancient Ruins Arcane Golem",
		"Ancient Ruins Runemark Sentinel",
		"Ancient Ruins Scarab Queen",
		"Ancient Ruins Ancient Guardian",
		"Ancient Ruins Sphinx",
		"Ancient Ruins Runic Colossus",
		"Ancient Ruins The First Idol",
		"Ancient Ruins Ancient Archivist",
	]
	for ruins_name in authored_left_ruins_cases:
		var ruins_visual_key: String = combat_screen._combat_stage.enemy_visual_key_for(ruins_name)
		_require(
			not bool(combat_screen._combat_stage.STATIC_ENEMY_FLIP_H_BY_VISUAL_KEY.get(ruins_visual_key, false)),
			"Expected %s to keep its authored facing." % ruins_name
		)
	var promoted_ruins_sprite_cases := [
		{"name": "Ancient Ruins Veteran Cultist", "path": "res://assets/enemies/ruins/cultist.png"},
		{"name": "Ancient Ruins Ancient Animated Statue", "path": "res://assets/enemies/ruins/Animated_Statue.png"},
		{"name": "Ancient Ruins Giant Scarab", "path": "res://assets/enemies/ruins/scrarab.png"},
		{"name": "Ancient Ruins Ancient Wisp", "path": "res://assets/enemies/ruins/wisp.png"},
	]
	for promoted_case in promoted_ruins_sprite_cases:
		var promoted_ruins_name := String(promoted_case["name"])
		var promoted_ruins_path := String(promoted_case["path"])
		_require(
			combat_screen._combat_stage.expected_enemy_sprite_paths(promoted_ruins_name).has(promoted_ruins_path),
			"Expected promoted Ruins name %s to reuse %s." % [promoted_ruins_name, promoted_ruins_path]
		)
	var ruins_golem_node := ContractRouteNode.new()
	ruins_golem_node.biome = "Ancient Ruins"
	ruins_golem_node.monster = Monster.new()
	ruins_golem_node.monster.display_name = "Arcane Golem"
	build_state.current_route_node = ruins_golem_node
	_require(combat_screen._combat_stage_visual_name(ruins_golem_node.monster) == "Ancient Ruins Arcane Golem", "Expected generated Ancient Ruins Arcane Golem combat to use the biome-qualified visual lookup.")
	_require(combat_screen._map_overlay._map_actor_visual_name(ruins_golem_node) == "Ancient Ruins Arcane Golem", "Expected generated Ancient Ruins Arcane Golem map marker to use the biome-qualified visual lookup.")
	build_state.current_route_node = null
	combat_screen._combat_stage.configure("Rogue", "Green Slime")
	_require(combat_screen._combat_stage.enemy_sprite_available(), "Expected a configured Swamp enemy to show its static sprite.")
	_require(combat_screen._combat_stage._enemy_sprite.size == Vector2(1254, 1254), "Expected static Swamp sprites to use the full PNG dimensions.")
	var expected_normal_static_scale: float = combat_screen._combat_stage.STATIC_ENEMY_SPRITE_SCALE * combat_screen._combat_stage.enemy_combat_role_scale("normal")
	_require(combat_screen._combat_stage._enemy_sprite.scale == Vector2(expected_normal_static_scale, expected_normal_static_scale), "Expected static Swamp sprites to use the normal-role static sprite scale.")
	_require(combat_screen._combat_stage._enemy_sprite.flip_h, "Expected right-facing static Swamp sprites like Green Slime to flip toward the player.")
	combat_screen._combat_stage.configure("Rogue", "Bog Rat")
	_require(not combat_screen._combat_stage._enemy_sprite.flip_h, "Expected already-left-facing static Swamp sprites like Bog Rat to keep their authored facing.")
	combat_screen._combat_stage.configure("Rogue", "Troll", "Cave Troll")
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_paths("Cave Troll").has("res://assets/enemies/cave/Troll.png"),
		"Expected biome-qualified Cave Troll to resolve to Cave art instead of the Swamp Troll name collision."
	)
	_require(combat_screen._combat_stage._enemy_sprite.flip_h, "Expected right-facing Cave Troll to flip toward the player.")
	var cave_troll_node := ContractRouteNode.new()
	cave_troll_node.biome = "Cave"
	cave_troll_node.monster = Monster.new()
	cave_troll_node.monster.display_name = "Troll"
	build_state.current_route_node = cave_troll_node
	_require(combat_screen._combat_stage_visual_name(cave_troll_node.monster) == "Cave Troll", "Expected generated Cave Troll combat to use the biome-qualified visual lookup.")
	_require(combat_screen._map_overlay._map_actor_visual_name(cave_troll_node) == "Cave Troll", "Expected generated Cave Troll map marker to use the biome-qualified visual lookup.")
	build_state.current_route_node = null
	combat_screen._combat_stage.configure("Rogue", "Ogre")
	_require(combat_screen._combat_stage._enemy_sprite.flip_h, "Expected right-facing Cave Ogre to flip toward the player.")
	combat_screen._combat_stage.configure("Rogue", "The Goblin King")
	_require(combat_screen._combat_stage._enemy_sprite.flip_h, "Expected right-facing Cave Goblin King to flip toward the player.")
	combat_screen._combat_stage.configure("Rogue", "Purple Cave Wyrm")
	_require(combat_screen._combat_stage._enemy_sprite.flip_h, "Expected right-facing Purple Cave Wyrm to flip toward the player.")
	var graveyard_mire_node := ContractRouteNode.new()
	graveyard_mire_node.biome = "Graveyard"
	graveyard_mire_node.monster = Monster.new()
	graveyard_mire_node.monster.display_name = "Mire Knight"
	build_state.current_route_node = graveyard_mire_node
	_require(combat_screen._combat_stage_visual_name(graveyard_mire_node.monster) == "Graveyard Mire Knight", "Expected generated Graveyard Mire Knight combat to use the biome-qualified visual lookup.")
	_require(combat_screen._map_overlay._map_actor_visual_name(graveyard_mire_node) == "Graveyard Mire Knight", "Expected generated Graveyard Mire Knight map marker to use the biome-qualified visual lookup.")
	build_state.current_route_node = null
	combat_screen._combat_stage.configure("Rogue", "Mire Knight", "Graveyard Mire Knight")
	_require(combat_screen._combat_stage._enemy_sprite.flip_h, "Expected Graveyard Mire Knight to flip toward the player.")
	var keep_rat_node := ContractRouteNode.new()
	keep_rat_node.biome = "Ruined Keep"
	keep_rat_node.monster = Monster.new()
	keep_rat_node.monster.display_name = "Giant Rat"
	build_state.current_route_node = keep_rat_node
	_require(combat_screen._combat_stage_visual_name(keep_rat_node.monster) == "Ruined Keep Giant Rat", "Expected generated Ruined Keep Giant Rat combat to use the biome-qualified visual lookup.")
	_require(combat_screen._map_overlay._map_actor_visual_name(keep_rat_node) == "Ruined Keep Giant Rat", "Expected generated Ruined Keep Giant Rat map marker to use the biome-qualified visual lookup.")
	build_state.current_route_node = null
	_require(
		combat_screen._combat_stage.expected_enemy_sprite_paths("Ruined Keep Giant Rat").has("res://assets/enemies/keep/rat.png"),
		"Expected Ruined Keep Giant Rat to use Keep rat art instead of Graveyard Giant Rat art."
	)
	_require(
		combat_screen._combat_stage.player_sprite_available() == ResourceLoader.exists("res://assets/placeholder_combat_sprites/rogue_bandit/animations/idle/frames/frame_001.png"),
		"Expected Rogue sprite availability to match whether the imported normalized idle frame exists."
	)
	_require(
		combat_screen._combat_stage.enemy_sprite_available() == ResourceLoader.exists("res://assets/placeholder_combat_sprites/townsfolk/peasants_sprite_sheet.png"),
		"Expected Mouthy Drunk sprite availability to match whether the imported peasant sheet exists."
	)

	print("-- Live win HUD --")
	combat_screen.instant_playback = false
	build_state.set_locked(true)
	fight_enemy_panel.fight_pressed.emit()
	await process_frame
	_require(combat_screen._playback_active, "Expected the live win check to enter real-time playback when instant playback is disabled.")
	var timer_at_start: String = combat_screen._fight_timer_label.text
	combat_screen._process(1.0)
	await process_frame
	_require(combat_screen._fight_timer_label.text != timer_at_start, "Expected the fight-window timer badge to count down during playback.")
	_require(combat_screen._fight_timer_label.text.ends_with("s"), "Expected the live timer to continue displaying seconds.")
	combat_screen._skip_playback()
	await process_frame
	_require(not combat_screen._victory_overlay.visible, "Expected skipped wins to keep the result overlay hidden during the victory pose beat.")
	_require(combat_screen._combat_stage.outcome_pose == "victory", "Expected skipped wins to enter the enemy defeat pose before the overlay.")
	_require(
		combat_screen._combat_stage.enemy_actor_anchor.position == combat_screen._combat_stage._enemy_base_position,
		"Expected skipped wins to keep the defeated enemy anchored instead of dropping toward the macro bar."
	)
	var defeated_enemy_position: Vector2 = combat_screen._combat_stage.enemy_actor_anchor.position
	combat_screen._combat_stage._layout_stage()
	_require(
		combat_screen._combat_stage.enemy_actor_anchor.position == defeated_enemy_position,
		"Expected combat-stage relayout during the reveal hold to preserve the enemy defeat pose position."
	)
	await create_timer(combat_screen.PLAYBACK_OUTCOME_REVEAL_DELAY_SEC + 0.05).timeout
	_require(build_state.last_fight_won, "Expected the Quick Cut Mouthy Drunk fight to be a win.")
	print("post-win: %s | bar %.1f/%.1f" % [combat_screen._hud_hp_text_label.text, combat_screen._hud_health_bar.value, combat_screen._hud_health_bar.max_value])
	_require(combat_screen._enemy_hud.visible, "Expected the HUD to stay visible with the victory banner up.")
	_require(combat_screen._victory_overlay.visible, "Expected skipped wins to reveal the victory overlay after the pose beat.")
	_require(combat_screen._hud_result != null, "Expected the HUD to hold the resolved fight after a win.")
	_require(is_equal_approx(combat_screen._hud_health_bar.value, 0.0), "Expected an empty health bar after a win.")
	_require(combat_screen._hud_hp_text_label.text == "0/%d" % monster.hp, "Expected icon-labeled zero HP value after a win.")
	_require(_has_status_chip(combat_screen._hud_status_row, HUD_POISON_ICON, "x0"), "Expected Poison stack chip to stay visible at x0 for a pure-physical rotation.")
	_require(_has_status_chip(combat_screen._hud_status_row, HUD_SHRED_ICON, "x0"), "Expected Shred stack chip to stay visible at x0 for a pure-physical rotation.")
	_require(_has_status_chip(combat_screen._hud_status_row, HUD_DECAY_ICON, "x0"), "Expected Decay stack chip to stay visible at x0 for a pure-physical rotation.")

	combat_screen.queue_free()


## Live end-to-end: a guaranteed loss (real rotation against an impossible
## HP target) leaves remaining HP consistent with monster HP minus the
## result's total damage, and pressing the real Retry button resets the HUD
## back to the pre-fight display.
func _check_live_loss_and_retry_reset() -> void:
	var build_state = root.get_node("BuildState")
	build_state.reset()
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	build_state.set_class(rogue)
	build_state.select_tree(rogue.trees[1])
	build_state.choose_current_tavern_encounter()
	var stab: Skill = load("res://data/skills/stab.tres")
	var loss_rotation: Array[Skill] = [stab]
	build_state.rotation = loss_rotation

	var combat_screen := _instantiate_combat_screen()
	await process_frame
	build_state.set_locked(true)

	var fight_enemy_panel = combat_screen._enemy_panel
	var monster: Monster = fight_enemy_panel.monster()
	monster.hp = 100000

	print("-- Live loss HUD --")
	fight_enemy_panel.fight_pressed.emit()
	await process_frame
	_require(not build_state.last_fight_won, "Expected the impossible-HP target to guarantee a loss.")
	_require(combat_screen._enemy_hud.visible, "Expected the HUD visible after a loss.")
	_require(combat_screen._hud_result != null, "Expected the HUD to hold the resolved fight after a loss.")
	var expected_remaining: float = float(monster.hp) - combat_screen._hud_result.total_damage
	print("post-loss: %s | bar %.1f/%.1f" % [combat_screen._hud_hp_text_label.text, combat_screen._hud_health_bar.value, combat_screen._hud_health_bar.max_value])
	_require(expected_remaining > 0.0, "Expected positive remaining HP on the loss.")
	_require(
		is_equal_approx(combat_screen._hud_health_bar.value, expected_remaining),
		"Expected the post-loss bar to read monster HP minus total damage dealt."
	)

	print("-- Retry resets the HUD --")
	_require(combat_screen._victory_overlay.visible, "Expected the defeat overlay after a first Tavern loss.")
	_require(combat_screen._view_log_button.visible, "Expected the row Combat Log button to remain visible during defeat.")
	combat_screen._view_log_button.pressed.emit()
	_require(combat_screen._log_overlay.visible, "Expected the row Combat Log button to open the log during defeat.")
	combat_screen._log_overlay.visible = false
	_require(combat_screen._outcome_retry_button.visible, "Expected the retry button after a first Tavern loss.")
	combat_screen._outcome_retry_button.pressed.emit()
	await process_frame
	_require(not combat_screen._victory_overlay.visible, "Expected retry to dismiss the defeat overlay.")
	_require(combat_screen._hud_result == null, "Expected the stored fight result cleared on retry.")
	# RETRY BUG FIX (combat-playback adjustment round 2 + retry bug,
	# 2026-07-19): retry_current_encounter() now restores
	# tavern_map_choice_made directly, since retrying is fighting the exact
	# same target, not making a new map choice -- previously start_fight()'s
	# earlier clear of that flag was never undone, so needs_tavern_map_
	# choice() incorrectly stayed true after a retry and the player had to
	# rediscover that they needed to reopen the Map overlay and re-click the
	# same already-only encounter before the HUD/FIGHT! button worked again.
	# This block used to assert that stale (buggy) gating; it now asserts the
	# fixed, immediately-fightable-again behavior.
	_require(not build_state.needs_tavern_map_choice(), "Expected retry to make the same Tavern encounter immediately available again, with no map re-choice required.")
	_require(combat_screen._enemy_hud.visible, "Expected the HUD visible again immediately after retry, with no map re-choice required.")
	_require(combat_screen._hud_hp_text_label.text == "%d/%d" % [monster.hp, monster.hp], "Expected icon-labeled full HP value again after retry.")
	_require(is_equal_approx(combat_screen._hud_health_bar.value, float(monster.hp)), "Expected a full health bar again after retry.")
	_require(_has_status_chip(combat_screen._hud_status_row, HUD_POISON_ICON, "x0"), "Expected Poison stack chip to reset to visible x0.")
	_require(_has_status_chip(combat_screen._hud_status_row, HUD_SHRED_ICON, "x0"), "Expected Shred stack chip to reset to visible x0.")
	_require(_has_status_chip(combat_screen._hud_status_row, HUD_DECAY_ICON, "x0"), "Expected Decay stack chip to reset to visible x0.")

	combat_screen.queue_free()


func _instantiate_combat_screen() -> Node:
	var combat_scene: PackedScene = load("res://scenes/combat/combat_screen.tscn")
	var combat_screen = combat_scene.instantiate()
	root.add_child(combat_screen)
	return combat_screen


func _status_chip_text(chip: Node) -> String:
	if chip is Label:
		return chip.text
	var label := chip.get_node_or_null("Text") as Label
	if label != null:
		return label.text
	return ""


func _indicator_ids(indicators: Array) -> PackedStringArray:
	var ids := PackedStringArray()
	for indicator in indicators:
		ids.append(String(indicator.get("id", "")))
	return ids


func _has_effect_chip(row: Container, effect_id: String, icon_texture: Texture2D, text: String) -> bool:
	for child in row.get_children():
		var icon := child.get_node_or_null("Icon") as TextureRect
		if icon != null and icon.texture == icon_texture and _status_chip_text(child) == text and child.get_meta("effect_id", "") == effect_id:
			return true
	return false


func _effect_row_text(row: Container) -> String:
	var parts := PackedStringArray()
	for child in row.get_children():
		parts.append(_status_chip_text(child))
		parts.append(String(child.tooltip_text))
	return " ".join(parts).to_lower()


func _has_status_chip(row: Container, icon_texture: Texture2D, text: String) -> bool:
	for child in row.find_children("*", "HBoxContainer", true, false):
		var icon := child.get_node_or_null("Icon") as TextureRect
		if icon != null and icon.texture == icon_texture and _status_chip_text(child) == text:
			return true
	return false


func _status_chip_tooltip(row: Container, icon_texture: Texture2D, text: String) -> String:
	for child in row.find_children("*", "HBoxContainer", true, false):
		var icon := child.get_node_or_null("Icon") as TextureRect
		if icon != null and icon.texture == icon_texture and _status_chip_text(child) == text:
			return child.tooltip_text
	return ""


func _has_status_chip_with_icon(row: Container, icon_texture: Texture2D) -> bool:
	for child in row.find_children("*", "HBoxContainer", true, false):
		var icon := child.get_node_or_null("Icon") as TextureRect
		if icon != null and icon.texture == icon_texture:
			return true
	return false


func _status_chip_font_size(row: Container, icon_texture: Texture2D) -> int:
	for child in row.find_children("*", "HBoxContainer", true, false):
		var icon := child.get_node_or_null("Icon") as TextureRect
		var label := child.get_node_or_null("Text") as Label
		if icon != null and icon.texture == icon_texture and label != null:
			return label.get_theme_font_size("font_size")
	return 0


## Same fixed idiom as combat_recap_test.gd: record failures instead of
## quitting immediately, since several checks run after an awaited frame and
## an early quit(1) would be overwritten by _initialize()'s final quit().
func _require(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
