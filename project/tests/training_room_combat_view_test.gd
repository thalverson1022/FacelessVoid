extends SceneTree
## Headless check for TrainingRoomCombatView (Practice Room's own animated
## combat area, user-requested "combat area, like Adventure mode"): a known
## CombatResolver.CombatResult drives the view's Damage Dealt readout/labels
## correctly, the headless instant-playback path fires `finished` exactly
## once synchronously (same pattern combat_screen.gd's `instant_playback`
## already relies on for its own tests), and the view never touches the real
## BuildState singleton -- it has no reference to it at all, unlike every
## other Practice Room panel which is explicitly parameterized away from
## BuildState.
## Run with:
##   godot --headless -s res://tests/training_room_combat_view_test.gd


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
var _finished_count := 0


func _initialize() -> void:
	var build_state = root.get_node("BuildState")
	var real_gold_before: int = build_state.gold

	var view := TrainingRoomCombatView.new()
	root.add_child(view)
	view.size = Vector2(1000,600) # Give the isolated panel a real combat area for bounded-popup assertions.
	await process_frame
	view.finished.connect(func(): _finished_count += 1)

	_check_initial_practice_target_sprite(view)
	_check_custom_named_practice_target_keeps_dummy_sprite(view)
	_check_damage_readout(view)
	_check_stun_effect_uses_shared_stage(view)
	_check_dodge_effect_uses_shared_stage(view)
	_check_interrupt_effect_uses_shared_stage(view)
	_check_slow_effect_uses_shared_stage(view)
	_check_slow_immunity_disables_practice_room_slow_visual(view)
	_check_realtime_status_readout(view)
	_check_crit_poison_proc_status_readout(view)
	_check_shred_stack_chip_uses_applied_stack_count(view)
	_check_cleanse_resets_visible_shred(view)
	# A frame between checks that spawn/free popups: play() only
	# queue_free()s the previous fight's popups, which stay in
	# get_children() until the next idle frame (same well-known Godot quirk
	# available_skills_panel.gd's own _refresh() documents) -- without this,
	# the next check's popup count would include stale ones from this fight.
	await process_frame
	_check_hold_cast_spawns_no_practice_room_popup(view)
	await process_frame
	_check_no_popup_for_zero_stack_ticks(view)
	await process_frame
	_check_absorbed_zero_damage_tick_still_presents(view)
	await process_frame
	_check_resisted_zero_damage_tick_still_presents(view)
	await process_frame
	_check_poison_stack_application_tints_enemy_without_popup(view)
	await process_frame
	_check_popup_for_damaging_poison_ticks(view)
	await process_frame
	_check_wyvern_kriss_uses_smaller_poison_tick_text(view)
	await process_frame
	_check_legendary_proc_popup_highlight(view)
	await process_frame
	_check_crit_popup_highlight(view)
	await process_frame
	_check_steal_crit_popup_shows_gold(view)
	await process_frame
	_check_crit_negation_popup(view)
	await process_frame
	await _check_realtime_intro_gates_timeline(view)
	await process_frame
	_check_skip_bypasses_realtime_outcome_hold(view)

	print("real BuildState.gold unchanged (expect %d): %d" % [real_gold_before, build_state.gold])
	_require(build_state.gold == real_gold_before, "TrainingRoomCombatView must never touch the real BuildState.")

	if _failed:
		print("Practice Room combat view check: FAILED")
		quit(1)
	else:
		print("Practice Room combat view check: OK")
	quit()


func _check_initial_practice_target_sprite(view: TrainingRoomCombatView) -> void:
	print("-- Initial Practice Room stage shows the Practice Target sprite --")
	_require(view._combat_stage != null, "Expected Practice Room combat view to own a stage layer before playback.")
	_require(view._combat_stage._enemy_name_label.text == "Practice Target", "Expected initial Practice Room stage enemy label to be Practice Target, not the default Enemy card.")
	_require(not view._combat_stage.debug_grid_visible, "Expected Practice Room to hide the combat-stage debug grid outside placement tuning.")
	_require(view._combat_stage.enemy_sprite_available(), "Expected initial Practice Room stage to show the imported Practice Target sprite.")
	_require(view._combat_stage._enemy_sprite.size.distance_to(Vector2(32, 32)) < 0.01, "Expected Practice Target sprite rect to stay at one 32px training-dummy frame, not stretch to the actor box; got %s." % view._combat_stage._enemy_sprite.size)
	var normal_dummy_scale: float = view._combat_stage.PRACTICE_DUMMY_SPRITE_SCALE * view._combat_stage.enemy_combat_role_scale("normal")
	_require(view._combat_stage._enemy_sprite.scale == Vector2(normal_dummy_scale, normal_dummy_scale), "Expected Practice Target sprite to use the normal-role Practice dummy scale.")
	_require(not view._name_label.visible, "Expected Practice Room to hide the redundant upper-left target label.")
	var dummy_anchor_y: float = view._combat_stage._sprite_anchor_point(view._combat_stage.enemy_actor_anchor, view._combat_stage._enemy_sprite, view._combat_stage.PRACTICE_DUMMY_ANCHOR_POINT).y
	var shadow_center_y: float = view._combat_stage.enemy_actor_anchor.position.y + view._combat_stage._enemy_contact_shadow.position.y + view._combat_stage._enemy_contact_shadow.size.y * 0.5
	_require(dummy_anchor_y > shadow_center_y + 10.0, "Expected Practice Target art to be lowered while its contact shadow stays on the shared floor line.")
	_require(view._damage_label.text == "0.0", "Expected initial Practice Room damage value to be visible before fighting.")
	var damage_icon := view._damage_label.get_parent().get_node_or_null("DamageIcon") as TextureRect
	_require(damage_icon != null and damage_icon.texture != null, "Expected Practice Room damage readout to use the sword icon.")
	_require(damage_icon.texture.resource_name == "PracticeDamageSwordIcon", "Expected Practice Room damage readout to use the copied sword icon.")
	_require(view._info_label.text == "0", "Expected initial Practice Room armor readout to be visible before fighting.")
	var armor_icon := view._info_label.get_parent().get_node_or_null("ArmorIcon") as TextureRect
	_require(armor_icon != null and armor_icon.tooltip_text == "Armor: Reduces Physical Damage", "Expected initial Practice Room Armor tooltip to describe physical defense.")
	_require(view._info_label.tooltip_text == "Armor: Reduces Physical Damage", "Expected initial Practice Room Armor value to share the armor tooltip.")
	_require(view._resist_label.text == "0%", "Expected initial Practice Room resistance readout to be visible before fighting.")
	var resist_icon := view._resist_label.get_parent().get_node_or_null("PoisonResistIcon") as TextureRect
	_require(resist_icon != null and resist_icon.tooltip_text == "Resistance: Reduces elemental damage", "Expected initial Practice Room Resistance tooltip to describe elemental defense.")
	_require(view._resist_label.tooltip_text == "Resistance: Reduces elemental damage", "Expected initial Practice Room Resistance value to share the resistance tooltip.")
	_require(view._fight_timer_badge != null and view._fight_timer_badge.visible, "Expected Practice Room to show the Adventure-style fight timer badge.")
	_require(view._fight_timer_badge.get_parent().name == "FightTimerCell", "Expected Practice Room fight timer to sit centered in the combat HUD lane.")
	_require(view._fight_timer_badge.find_child("ClockIcon", true, false) != null, "Expected Practice Room fight timer to include the clock icon.")
	_require(view._fight_timer_label.text == "20s", "Expected initial Practice Room fight timer to show the default 20s duration.")
	_require(view._controls_row.visible, "Expected Practice Room playback controls to be permanently visible.")
	_require(view._controls_row.find_child("PlaybackLabel", true, false) != null, "Expected Practice Room playback controls to include the playback label.")
	_require(view._controls_row.find_child("TimeLabel", true, false) == null, "Expected Practice Room to remove the old tiny onscreen playback timer.")
	_require(view._speed_buttons[0].disabled, "Expected Practice Room 1x playback speed to be selected by default.")
	_require(view._status_row.alignment == BoxContainer.ALIGNMENT_END, "Expected Practice Room status chips to align to the right like Adventure.")
	_require(view._mechanic_row.get_parent().name == "CombatHudLane", "Expected Practice Room mechanic icons to live in the combat area HUD lane.")
	_require(view._mechanic_row.get_index() < view._status_row.get_index(), "Expected mechanic icons between the value row and stack row.")
	_require(view._mechanic_row.offset_top >= 80.0, "Expected Practice Room mechanic icon row to sit below the top values row without overlap.")
	_require(view._status_row.offset_top >= view._mechanic_row.offset_bottom + 12.0, "Expected Practice Room stack row to sit below the mechanic icon row without overlap.")
	_require(view._combat_stage.safe_top_px >= view.HUD_TOP_LANE_HEIGHT - 16.0, "Expected Practice Room actor safe area to account for the taller HUD stack.")
	_require(view._mechanic_row.get_child_count() == 8, "Expected Practice Room to always show every target mechanic icon.")
	_require(
		_mechanic_chip_ids(view._mechanic_row)
		== PackedStringArray(["block", "dodge_chance", "crit_negation", "absorb", "suppress", "slow", "cleanse_threshold", "stun_duration_ms"]),
		"Expected Practice Room mechanic row order: Block, Dodge, Crit Negation, Absorb, Suppress, Slow, Cleanse, Stun."
	)
	_require(_has_chip(view._mechanic_row, MECHANIC_DODGE_ICON, "0%"), "Expected Dodge icon to be visible at 0%.")
	_require(_has_chip(view._mechanic_row, MECHANIC_CRIT_NEGATION_ICON, "0%"), "Expected Crit Negate icon to be visible at 0%.")
	_require(_has_chip(view._mechanic_row, MECHANIC_BLOCK_ICON, "0"), "Expected Block icon to be visible at 0.")
	_require(_chip_tooltip(view._mechanic_row, MECHANIC_BLOCK_ICON, "0") == "Block: Prevents 0 physical damage", "Expected Block tooltip to show prevented physical damage.")
	_require(_has_chip(view._mechanic_row, MECHANIC_ABSORB_ICON, "0"), "Expected Absorb icon to be visible at 0.")
	_require(_chip_tooltip(view._mechanic_row, MECHANIC_ABSORB_ICON, "0") == "Absorb: Prevents 0 elemental damage", "Expected Absorb tooltip to show prevented elemental damage.")
	_require(_has_chip(view._mechanic_row, MECHANIC_CLEANSE_ICON, "0"), "Expected Cleanse icon to be visible at 0.")
	_require(_has_chip(view._mechanic_row, MECHANIC_SUPPRESS_ICON, "0%"), "Expected Suppress icon to be visible at 0%.")
	_require(_has_chip(view._mechanic_row, MECHANIC_SLOW_ICON, "0%"), "Expected Slow icon to be visible at 0%.")
	_require(_has_chip(view._mechanic_row, MECHANIC_STUN_ICON, "0s"), "Expected Stun icon to be visible at 0s.")
	var initial_chips: PackedStringArray = []
	for child in view._status_row.find_children("*", "HBoxContainer", true, false):
		initial_chips.append(_status_chip_text(child))
	_require(initial_chips == PackedStringArray(["x0", "x0", "x0", "x0", "x0", "0/0"]), "Expected initial Practice Room Penetration/Potency/Poison/Shred/Decay/Interrupt chips to be visible at zero.")
	_require(_chip_tooltip(view._status_row, HUD_POISON_ICON, "x0") == "Poison: Deals 8.0 damage every 1.0s", "Expected initial Practice Room Poison tooltip to show base poison damage.")
	_require(_chip_tooltip(view._status_row, HUD_SHRED_ICON, "x0") == "Shred: Each stack reduces armor by 10", "Expected initial Practice Room Shred tooltip to show base armor reduction.")
	_require(_chip_tooltip(view._status_row, HUD_DECAY_ICON, "x0") == "Decay: Each stack reduces resistance by 20%", "Expected initial Practice Room Decay tooltip to show base Decay reduction.")
	_require(_has_chip(view._status_row, MECHANIC_INTERRUPT_ICON, "0/0"), "Expected Interrupt stack chip to be visible at 0/0 when disabled.")
	_require(_chip_tooltip(view._status_row, MECHANIC_INTERRUPT_ICON, "0/0") == "Interrupt: Casting 3 times prevents next 0 casts", "Expected disabled Practice Room Interrupt tooltip to explain the threshold with zero prevented casts.")

	var preview_monster := Monster.new()
	preview_monster.display_name = "Preview Dummy"
	preview_monster.armor = 18
	preview_monster.poison_resistance = 0.25
	preview_monster.dodge_chance = 0.35
	preview_monster.crit_negation = 0.45
	preview_monster.block = 7.0
	preview_monster.absorb = 5.0
	preview_monster.cleanse_threshold = 4
	preview_monster.suppress = 0.2
	preview_monster.slow = 0.15
	preview_monster.stun_duration_ms = 350
	preview_monster.interrupt_skip_count = 1
	view.set_target_preview(preview_monster)
	_require(view._info_label.text == "18", "Expected target preview edits to update Practice Room armor.")
	_require(view._resist_label.text == "25%", "Expected target preview edits to update Practice Room resistance.")
	_require(_has_chip(view._mechanic_row, MECHANIC_DODGE_ICON, "35%"), "Expected Dodge preview value to update in the combat area.")
	_require(_chip_tooltip(view._mechanic_row, MECHANIC_DODGE_ICON, "35%") == "Dodge: 35% chance for cast to miss", "Expected Dodge preview tooltip to show miss chance.")
	_require(_has_chip(view._mechanic_row, MECHANIC_CRIT_NEGATION_ICON, "45%"), "Expected Crit Negate preview value to update in the combat area.")
	_require(_chip_tooltip(view._mechanic_row, MECHANIC_CRIT_NEGATION_ICON, "45%") == "Crit Negation: Reduces crits by 45%", "Expected Crit Negation preview tooltip to show reduction.")
	_require(_has_chip(view._mechanic_row, MECHANIC_BLOCK_ICON, "7"), "Expected Block preview value to update in the combat area.")
	_require(_chip_tooltip(view._mechanic_row, MECHANIC_BLOCK_ICON, "7") == "Block: Prevents 7 physical damage", "Expected Block preview tooltip to show prevented damage.")
	_require(_has_chip(view._mechanic_row, MECHANIC_ABSORB_ICON, "5"), "Expected Absorb preview value to update in the combat area.")
	_require(_chip_tooltip(view._mechanic_row, MECHANIC_ABSORB_ICON, "5") == "Absorb: Prevents 5 elemental damage", "Expected Absorb preview tooltip to show prevented damage.")
	_require(_has_chip(view._mechanic_row, MECHANIC_CLEANSE_ICON, "4"), "Expected Cleanse preview value to update in the combat area.")
	_require(_chip_tooltip(view._mechanic_row, MECHANIC_CLEANSE_ICON, "4") == "Cleanse: Removes all debuffs after 4 casts", "Expected Cleanse preview tooltip to show cast threshold.")
	_require(_has_chip(view._mechanic_row, MECHANIC_SUPPRESS_ICON, "20%"), "Expected Suppress preview value to update in the combat area.")
	_require(_chip_tooltip(view._mechanic_row, MECHANIC_SUPPRESS_ICON, "20%") == "Suppress: Damage over time ticks 20% slower", "Expected Suppress preview tooltip to show slower tick rate.")
	_require(_has_chip(view._mechanic_row, MECHANIC_SLOW_ICON, "15%"), "Expected Slow preview value to update in the combat area.")
	_require(_chip_tooltip(view._mechanic_row, MECHANIC_SLOW_ICON, "15%") == "Slow: Reduces attack speed by 15%", "Expected Slow preview tooltip to show attack speed reduction.")
	_require(_has_chip(view._mechanic_row, MECHANIC_STUN_ICON, "0.3s"), "Expected Stun preview value to update in the combat area.")
	_require(_chip_tooltip(view._mechanic_row, MECHANIC_STUN_ICON, "0.3s") == "Stun: Hitting for 12% of total health in a single hit stuns for 0.3s", "Expected Stun preview tooltip to show trigger size and duration.")
	_require(_has_chip(view._status_row, MECHANIC_INTERRUPT_ICON, "0/3"), "Expected enabled Interrupt to use the Adventure-style repeat counter.")
	_require(_chip_tooltip(view._status_row, MECHANIC_INTERRUPT_ICON, "0/3") == "Interrupt: Casting 3 times prevents next 1 casts", "Expected enabled Practice Room Interrupt tooltip to explain threshold and prevented casts.")


func _check_custom_named_practice_target_keeps_dummy_sprite(view: TrainingRoomCombatView) -> void:
	print("-- Custom-named Practice Room target keeps the training dummy sprite --")
	var stab: Skill = load("res://data/skills/stab.tres")
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	var monster := Monster.new()
	monster.display_name = "Generated Test Monster"
	monster.combat_role = "boss"
	monster.hp = 100
	var result := CombatResolver.resolve([stab], player, monster, 1500, 11)

	view.play(result, monster)
	_require(view._combat_stage._enemy_name_label.text == monster.display_name, "Expected Practice Room stage label to keep the generated monster name.")
	_require(view._combat_stage.enemy_sprite_available(), "Expected custom-named Practice Room targets to keep using the training dummy sprite.")
	_require(view._combat_stage._enemy_sprite.size == Vector2(32, 32), "Expected custom-named Practice Room target to render as one 32px dummy frame.")
	var boss_dummy_scale: float = view._combat_stage.PRACTICE_DUMMY_SPRITE_SCALE * view._combat_stage.enemy_combat_role_scale("boss")
	_require(view._combat_stage._enemy_sprite.scale == Vector2(boss_dummy_scale, boss_dummy_scale), "Expected custom-named Practice Room targets to keep the dummy art while honoring the monster role scale.")


## Returns [CombatResolver.CombatResult, Monster] -- GDScript has no tuple
## return, so this is a plain 2-element Array the callers index into.
## `monster.hp` is left at its default (0) -- Practice Room's own view never
## reads it (post-R10 UI-feedback pass removed the HP concept entirely), it
## only exists on Monster at all for the shared CombatResolver/
## CombatResultFormatter API.
func _known_result() -> Array:
	var poison_strike: Skill = load("res://data/skills/poison_strike.tres")
	var rending_slash: Skill = load("res://data/skills/rending_slash.tres")
	var rotation: Array[Skill] = [poison_strike, rending_slash]
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	player.crit_multiplier = 2.0
	player.poison_damage_per_tick = 5.0
	var monster := Monster.new()
	monster.display_name = "Practice Target"
	monster.armor = 0
	monster.poison_resistance = 0.0
	var result := CombatResolver.resolve(rotation, player, monster, 8000, 3)
	return [result, monster]


func _check_damage_readout(view: TrainingRoomCombatView) -> void:
	print("-- Damage Dealt readout accumulates to the fight's total damage, finished fires once --")
	var result_and_monster: Array = _known_result()
	var result: CombatResolver.CombatResult = result_and_monster[0]
	var monster: Monster = result_and_monster[1]
	var before_count := _finished_count
	view.play(result, monster)
	print("finished signal fired once (expect true): %s" % (_finished_count == before_count + 1))
	_require(_finished_count == before_count + 1, "Expected exactly one finished emission per play() in instant mode.")

	var expected_text := "%.1f" % result.total_damage
	print("damage label=%s (expect %s)" % [view._damage_label.text, expected_text])
	_require(view._damage_label.text == expected_text, "Damage readout should end at the fight's total damage.")
	_require(view._name_label.text == monster.display_name, "Name label should show the target's display name.")


func _check_stun_effect_uses_shared_stage(view: TrainingRoomCombatView) -> void:
	print("-- Practice Room playback triggers the shared stun-star stage effect --")
	var stab: Skill = load("res://data/skills/stab.tres")
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	var monster := Monster.new()
	monster.display_name = "Practice Target"
	monster.hp = 50
	monster.stun_duration_ms = 500
	var result := CombatResolver.resolve([stab], player, monster, 3000, 3)
	view.play(result, monster)
	_require(view._combat_stage.stun_effect_count > 0, "Expected Practice Room playback to trigger the shared player stun stars.")
	_require(view._combat_stage.last_stun_duration_ms == monster.stun_duration_ms, "Expected Practice Room stun stars to use the monster stun duration.")


func _check_dodge_effect_uses_shared_stage(view: TrainingRoomCombatView) -> void:
	print("-- Practice Room playback triggers the shared dodge afterimage effect --")
	var stab: Skill = load("res://data/skills/stab.tres")
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	var monster := Monster.new()
	monster.display_name = "Dodging Target"
	monster.hp = 50
	monster.dodge_chance = 1.0
	var result := CombatResolver.resolve([stab], player, monster, 1500, 3)
	_require(result.cast_events.size() > 0 and result.cast_events[0].was_dodged, "Test setup error: expected the target to dodge the first Practice Room cast.")
	view.play(result, monster)
	_require(view._combat_stage.dodge_effect_count > 0, "Expected Practice Room playback to trigger the shared enemy dodge afterimages.")
	_require(view._combat_stage.last_mechanic_text == "Dodged", "Expected Practice Room dodge playback to show the Dodged mechanic label.")
	var found_zero_popup := false
	for child in view._popup_layer.get_children():
		if child.is_queued_for_deletion():
			continue
		if child is Label and child.text == "Stab 0.0":
			found_zero_popup = true
	_require(found_zero_popup, "Expected dodged Practice Room attacks to keep the numeric Stab 0.0 popup.")


func _check_interrupt_effect_uses_shared_stage(view: TrainingRoomCombatView) -> void:
	print("-- Practice Room playback triggers the shared interrupt slash effect --")
	var stab: Skill = load("res://data/skills/stab.tres")
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	var monster := Monster.new()
	monster.display_name = "Interrupting Target"
	monster.hp = 100000
	monster.interrupt_skip_count = 1
	var result := CombatResolver.resolve([stab], player, monster, 5200, 3)
	_require(result.cast_events.any(func(cast): return cast.interrupt_triggered), "Test setup error: expected repeated Stab casts to trigger Interrupt.")
	view.play(result, monster)
	_require(view._combat_stage.interrupt_effect_count > 0, "Expected Practice Room playback to trigger the shared interrupt slash.")
	_require(view._combat_stage.last_mechanic_text == "Interrupted", "Expected Practice Room interrupt playback to show the Interrupted mechanic label.")
	var found_interrupt_popup := false
	for child in view._popup_layer.get_children():
		if child.is_queued_for_deletion():
			continue
		if child is Label and child.text == "Stab interrupted":
			found_interrupt_popup = true
	_require(found_interrupt_popup, "Expected Practice Room interrupted casts to keep the Stab interrupted popup.")


func _check_slow_effect_uses_shared_stage(view: TrainingRoomCombatView) -> void:
	print("-- Practice Room playback triggers the shared slow frost and breath effect --")
	var stab: Skill = load("res://data/skills/stab.tres")
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	var monster := Monster.new()
	monster.display_name = "Chilling Target"
	monster.hp = 100000
	monster.slow = 0.35
	var result := CombatResolver.resolve([stab], player, monster, 3000, 3)
	view.play(result, monster)
	_require(view._combat_stage.slow_effect_count > 0, "Expected Practice Room playback to trigger the shared player frost aura.")
	_require(is_equal_approx(view._combat_stage.last_slow_strength, monster.slow), "Expected Practice Room slow aura to use the monster slow strength.")


func _check_slow_immunity_disables_practice_room_slow_visual(view: TrainingRoomCombatView) -> void:
	print("-- Practice Room slow immunity disables the slow visual --")
	var stab: Skill = load("res://data/skills/stab.tres")
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	player.special_effects = {"immunities": {"slow": true}}
	var monster := Monster.new()
	monster.display_name = "Chilling Target"
	monster.hp = 100000
	monster.slow = 0.35
	var result := CombatResolver.resolve([stab], player, monster, 3000, 3)
	view.play(result, monster, [], 10, CombatResolver.effective_enemy_slow(player, monster))
	_require(not view._combat_stage.slow_effect_active, "Expected slow immunity to avoid the Practice Room frost aura.")
	_require(is_equal_approx(view._combat_stage.last_slow_strength, 0.0), "Expected slow immunity to clear the visual slow strength.")


func _check_realtime_intro_gates_timeline(view: TrainingRoomCombatView) -> void:
	print("-- Realtime Practice Room playback waits for the shared fight intro --")
	var result_and_monster: Array = _known_result()
	var result: CombatResolver.CombatResult = result_and_monster[0]
	var monster: Monster = result_and_monster[1]
	monster.hp = 60
	var before_count := _finished_count
	var audio_manager = root.get_node("AudioManager")
	var sfx_before_count: int = audio_manager.attack_sfx_play_count
	view._instant_playback = false
	view.play(result, monster)
	_require(_finished_count == before_count, "Expected realtime Practice Room playback not to finish synchronously.")
	_require(view._controls_row.visible, "Expected realtime Practice Room playback controls to stay visible during playback.")
	_require(view._fight_timer_label.text == "8.0s", "Expected Practice Room fight timer to start counting down from the fight window.")
	_require(view._playback_intro_remaining_sec > 0.0, "Expected realtime Practice Room playback to begin with an intro delay.")
	_require(view._combat_stage.fight_intro_count == 1, "Expected Practice Room to request one shared fight intro from the stage.")
	_require(view._playback.events_fired() == 0, "Expected no Practice Room events to fire before the intro advances.")

	view._process(view._playback_intro_duration_sec * 0.5)
	_require(view._playback.events_fired() == 0, "Expected Practice Room events to stay gated during the intro.")
	_require(is_equal_approx(view._playback.elapsed_ms(), 0.0), "Expected Practice Room combat time to stay at zero during the intro.")
	_require(view._fight_timer_label.text == "8.0s", "Expected Practice Room timer to hold at the full duration during the intro.")
	_require(_finished_count == before_count, "Expected Practice Room playback not to finish during the intro.")

	view._process(view._playback_intro_remaining_sec + result.duration_ms / 1000.0 + 0.1)
	_require(_finished_count == before_count, "Expected realtime Practice Room playback to hold briefly before emitting finished.")
	_require(audio_manager.attack_sfx_play_count > sfx_before_count, "Expected realtime Practice Room physical attacks to play sword SFX.")
	_require(view._playback == null, "Expected Practice Room playback to clear itself before the final hold.")
	_require(view._combat_stage.outcome_pose == "", "Expected Practice Room to return to idle instead of showing a win/loss pose.")
	_require(view._combat_stage.get_node_or_null("OutcomeFlash") == null, "Expected Practice Room to avoid Adventure-style outcome flashes.")
	_require(view._controls_row.visible, "Expected Practice Room playback controls to stay visible during the final hold.")
	_require(view._fight_timer_label.text == "8s", "Expected Practice Room timer to return to the configured duration after playback clears.")

	await create_timer(view.OUTCOME_REVEAL_HOLD_SEC + 0.05).timeout
	_require(_finished_count == before_count + 1, "Expected realtime Practice Room playback to emit finished after the outcome hold.")
	view._instant_playback = DisplayServer.get_name() == "headless"
	_require(view._combat_stage != null, "Expected Practice Room combat view to own a stage layer.")
	_require(view._combat_stage.player_actor_anchor != null, "Expected a player actor anchor in Practice Room.")
	_require(view._combat_stage.enemy_actor_anchor != null, "Expected an enemy actor anchor in Practice Room.")
	_require(view._combat_stage.player_actor_anchor.z_index > view._combat_stage.enemy_actor_anchor.z_index, "Expected Rogue to render above the Practice dummy during overlapping swings.")
	_require(view._combat_stage.contact_effect_anchor != null, "Expected a contact effect anchor in Practice Room.")
	_require(view._combat_stage.floating_text_anchor != null, "Expected a floating text anchor in Practice Room.")
	_require(view._combat_stage._enemy_name_label.text == monster.display_name, "Expected the Practice Room stage enemy actor label to track the target.")
	_require(view._combat_stage.player_actor_anchor.get_node_or_null("PlayerSprite") != null, "Expected Practice Room to expose a configured player sprite slot.")
	_require(view._combat_stage.enemy_actor_anchor.get_node_or_null("EnemySprite") != null, "Expected Practice Room to expose a configured enemy sprite slot.")
	_require(view._combat_stage.enemy_sprite_available(), "Expected Practice Room Practice Target to use the imported training dummy sprite.")
	_require(
		view._combat_stage.expected_enemy_sprite_paths("Practice Target").has("res://assets/characters/practice_dummy/dummy_bounce/frames/frame_001.png"),
		"Expected Practice Target idle to use the imported training dummy frame."
	)
	_require(
		view._combat_stage.expected_enemy_sprite_region("Practice Target", "idle") == Rect2(Vector2(0, 0), Vector2(32, 32)),
		"Expected Practice Target idle to use a full 32px training dummy frame in Practice Room."
	)


func _check_skip_bypasses_realtime_outcome_hold(view: TrainingRoomCombatView) -> void:
	print("-- Realtime Practice Room skip reveals outcome immediately --")
	var result_and_monster: Array = _known_result()
	var result: CombatResolver.CombatResult = result_and_monster[0]
	var monster: Monster = result_and_monster[1]
	monster.hp = 60
	var before_count := _finished_count
	view._instant_playback = false
	view.play(result, monster)
	_require(_finished_count == before_count, "Expected realtime Practice Room playback to be active before skip.")
	_require(view._controls_row.visible, "Expected controls visible before Practice Room skip.")
	var before_reaction_count: int = view._combat_stage.practice_dummy_reaction_count
	view._playback_intro_remaining_sec = 0.0
	view._process((result.cast_events[0].time_ms + 1.0) / 1000.0)
	_require(view._combat_stage.practice_dummy_reaction_count > before_reaction_count, "Expected a presented damaging hit to request a training dummy reaction.")
	_require(view._combat_stage.last_practice_dummy_reaction_frame_count >= 4, "Expected a presented dummy reaction to include multiple frames.")
	before_reaction_count = view._combat_stage.practice_dummy_reaction_count

	view._skip_button.pressed.emit()
	_require(_finished_count == before_count + 1, "Expected Practice Room skip to emit finished immediately.")
	_require(view._playback == null, "Expected Practice Room skip to clear playback.")
	_require(view._controls_row.visible, "Expected Practice Room controls to stay visible after skip.")
	_require(view._combat_stage.outcome_pose == "", "Expected Practice Room skip to return both actors to idle, not a win/loss pose.")
	_require(view._combat_stage.get_node_or_null("OutcomeFlash") == null, "Expected Practice Room skip to avoid Adventure-style outcome flashes.")
	_require(view._combat_stage.practice_dummy_reaction_count == before_reaction_count, "Skip applies remaining damage without scheduling new dummy reaction animations.")
	_require(view._combat_stage.enemy_sprite_available(), "Expected the training dummy to stay visible after reaction frames are flushed.")
	_require(view._combat_stage.enemy_actor_anchor.position == view._combat_stage._enemy_base_position, "Expected training dummy reactions to avoid old humanoid recoil movement.")
	view._instant_playback = DisplayServer.get_name() == "headless"


## User-requested: armor/poison-resist/poison-stacks should be visible and
## change live during the fight, like Adventure mode's HUD
## (combat_screen.gd's _update_playback_hud_readout()). Rending Slash
## reduces armor by 20/cast (persists, so _armor_reduced must end up > 0
## for any multi-cast fight); Poison Strike applies 1 poison stack/cast but
## each poison tick then *consumes* one stack (CombatResolver.resolve()),
## so unlike armor reduction, the final _stacks value isn't simply "> 0" --
## it's whatever an independent replay of the same merged timeline says it
## should be, which _expected_final_stacks() computes separately from the
## view under test so this isn't just restating the same code.
func _check_realtime_status_readout(view: TrainingRoomCombatView) -> void:
	print("-- Real-time armor/resist/poison-stacks readout updates during the fight --")
	var poison_strike: Skill = load("res://data/skills/poison_strike.tres")
	var rending_slash: Skill = load("res://data/skills/rending_slash.tres")
	var beguiling_strike: Skill = load("res://data/skills/beguiling_strike.tres")
	var rotation: Array[Skill] = [poison_strike, rending_slash, beguiling_strike]
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	var monster := Monster.new()
	monster.display_name = "Armored Dummy"
	monster.hp = 100000
	monster.armor = 200
	monster.poison_resistance = 0.3
	var result := CombatResolver.resolve(rotation, player, monster, 8000, 3)
	_require(not result.cast_events.is_empty(), "Expected casts in this known fight.")
	var expected_stacks := _expected_final_stacks(result)

	view.play(result, monster)
	print("armor_reduced=%d (expect > 0), stacks=%d (expect %d, an independent replay)" % [
		view._armor_reduced, view._stacks, expected_stacks
	])
	_require(view._armor_reduced > 0, "Rending Slash should have reduced armor at least once.")
	_require(view._stacks == expected_stacks, "Stacks should reflect ticks consuming them, not just casts accumulating them.")

	var expected_current_armor := monster.armor - view._armor_reduced
	print("armor value label (expect current armor %d): %s" % [expected_current_armor, view._info_label.text])
	_require(view._info_label.text == "%d" % expected_current_armor, "Shield-labeled armor value should show current armor after Shred.")
	_require(view._info_label.get_parent().get_node_or_null("ArmorIcon") != null, "Expected the Practice Room combat window's armor readout to include the shield icon.")
	_require(view._resist_label.text == "%.0f%%" % (view._resist * 100.0), "Resistance value should show current magical resistance after Decay.")
	var resist_icon := view._resist_label.get_parent().get_node_or_null("PoisonResistIcon") as TextureRect
	_require(resist_icon != null and resist_icon.texture == HUD_RESISTANCE_ICON, "Expected the Practice Room combat window's resistance readout to include the resistance icon.")

	var chip_texts: PackedStringArray = []
	for child in view._status_row.find_children("*", "HBoxContainer", true, false):
		chip_texts.append(_status_chip_text(child))
	print("status chips: %s" % [chip_texts])
	var has_poison_chip := false
	var has_shred_chip := false
	var has_decay_chip := false
	var has_poison_icon := false
	var has_shred_icon := false
	var shred_tooltip := ""
	var has_decay_icon := false
	var has_interrupt_chip := false
	for child in view._status_row.find_children("*", "HBoxContainer", true, false):
		var icon := child.get_node_or_null("Icon") as TextureRect
		var text := _status_chip_text(child)
		if icon != null and icon.texture == HUD_POISON_ICON and text == "x%d" % view._stacks:
			has_poison_chip = true
			has_poison_icon = true
		if icon != null and icon.texture == HUD_SHRED_ICON and text == "x%d" % view._shred_stacks:
			has_shred_chip = true
			has_shred_icon = true
			shred_tooltip = child.tooltip_text
		if icon != null and icon.texture == HUD_DECAY_ICON and text == "x%d" % view._decay_stacks:
			has_decay_chip = true
			has_decay_icon = true
		if icon != null and icon.texture == MECHANIC_INTERRUPT_ICON and text == "0/0":
			has_interrupt_chip = true
	_require(has_poison_chip, "Poison chip should stay visible even at x0.")
	_require(has_shred_chip, "Expected a Shred stack chip.")
	_require(has_decay_chip, "Expected a Decay stack chip.")
	_require(has_interrupt_chip, "Expected Interrupt chip to stay visible at 0/0 when the target has no Interrupt.")
	_require(has_poison_icon, "Poison stack chip should use the selected skull icon.")
	_require(has_shred_icon, "Shred chip should use the selected rogue icon.")
	_require(shred_tooltip == "Shred: Each stack reduces armor by 10", "Shred chip should explain the active armor reduction value.")
	_require(has_decay_icon, "Decay chip should use the selected mage icon.")
	_require(_chip_tooltip(view._status_row, HUD_DECAY_ICON, "x%d" % view._decay_stacks) == "Decay: Each stack reduces resistance by 20%", "Decay chip should explain the active resistance reduction value.")
	_require(_status_chip_font_size(view._status_row, HUD_POISON_ICON) == 24, "Expected Practice Room combat status values to use the larger number font.")


func _check_crit_poison_proc_status_readout(view: TrainingRoomCombatView) -> void:
	print("-- Crit poison proc updates Practice Room stack chip and log --")
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 1.0
	player.crit_multiplier = 2.0
	player.elemental_proc_chance = 1.0
	player.weapon_damage_min = 10
	player.weapon_damage_max = 10
	var monster := Monster.new()
	monster.display_name = "Crit Poison View Dummy"
	monster.hp = 100000
	monster.armor = 0
	monster.poison_resistance = 0.0
	var skill := Skill.new()
	skill.id = "skill.test_crit_poison_view"
	skill.display_name = "Crit Poison View"
	skill.base_execution_ms = 500
	skill.min_execution_ms = 500
	var damage := PhysicalDamageEffect.new()
	damage.amount = 10.0
	skill.effects = [damage]
	var result := CombatResolver.resolve([skill], player, monster, 900, 17)
	_require(result.cast_events.size() == 1, "Expected one cast before the first global poison tick.")
	_require(result.cast_events[0].is_crit, "Expected forced crit in visual-path setup.")
	_require(result.cast_events[0].poison_stacks_applied == 1, "Expected crit proc to apply one poison stack in visual-path setup.")
	_require(CombatResultFormatter.format_practice(result, monster).contains("applies 1 poison stack"), "Expected Practice Room log to mention the crit-applied poison stack.")

	view.play(result, monster)
	_require(view._stacks == 1, "Expected Practice Room stack state to retain the crit-applied poison stack before the first tick.")
	_require(_has_chip(view._status_row, HUD_POISON_ICON, "x1"), "Expected Practice Room poison chip to display x1 after crit poison proc.")
	_require(view._combat_stage.poison_stack_tint_updates > 0, "Expected crit poison proc to tint the target like other poison applications.")


func _check_shred_stack_chip_uses_applied_stack_count(view: TrainingRoomCombatView) -> void:
	print("-- Practice Room Shred chip uses applied stack count, not one per armor event --")
	var rending_slash: Skill = load("res://data/skills/rending_slash.tres")
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	player.bonus_shred_stacks = 2
	player.special_effects = {"double_applied_stacks": true}
	var monster := Monster.new()
	monster.display_name = "Stack Dummy"
	monster.hp = 100000
	monster.armor = 100
	var result := CombatResolver.resolve([rending_slash], player, monster, rending_slash.base_execution_ms, 7)

	view.play(result, monster)
	_require(result.cast_events[0].shred_stacks_applied == 8, "Expected the known Rending Slash setup to apply eight Shred stacks.")
	_require(view._shred_stacks == 8, "Practice Room visible Shred stacks should include bonus stacks and doubled stacks.")
	_require(_has_chip(view._status_row, HUD_SHRED_ICON, "x8"), "Practice Room Shred chip should display x8.")


func _check_cleanse_resets_visible_shred(view: TrainingRoomCombatView) -> void:
	print("-- Cleanse resets visible Shred from an armor-only Rending Slash macro --")
	var rending_slash: Skill = load("res://data/skills/rending_slash.tres")
	var rotation: Array[Skill] = [rending_slash]
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	player.crit_multiplier = 2.0
	var monster := Monster.new()
	monster.display_name = "Cleansing Dummy"
	monster.hp = 100000
	monster.armor = 100
	monster.cleanse_threshold = 5
	var result := CombatResolver.resolve(rotation, player, monster, 7000, 3)
	_require(result.cast_events.size() == 5, "Expected exactly five Rending Slash casts before the cleanse assertion.")
	_require(result.cast_events[4].cleanse_triggered, "Expected the fifth Rending Slash cast to trigger cleanse.")
	var flash_count_before := view.status_chip_flash_count

	view.play(result, monster)
	print("visible armor=%s, armor_reduced=%d, shred_stacks=%d (expect 100, 0, 0)" % [
		view._info_label.text, view._armor_reduced, view._shred_stacks
	])
	_require(view._armor_reduced == 0, "Cleanse should clear active visible armor reduction.")
	_require(view._shred_stacks == 0, "Cleanse should clear the visible Shred stack chip.")
	_require(view._info_label.text == "100", "Cleanse should restore the visible armor readout to base armor.")
	_require(view._combat_stage.cleanse_effect_count > 0, "Cleanse should trigger the shared cleanse burst animation in Practice Room.")
	_require(view._combat_stage.last_mechanic_text == "Cleansed", "Cleanse should spawn a small Cleansed mechanic label in Practice Room.")
	_require(view.status_chip_flash_count > flash_count_before, "Cleanse should flash the zeroed Practice Room status chips.")
	var summary := CombatRecap.summarize(result, monster)
	_require(summary["final_armor"] == 100, "Combat recap final armor should honor cleanse resets.")
	_require(summary["active_armor_reduction_casts"] == 0, "Combat recap active Shred stacks should honor cleanse resets.")


func _check_hold_cast_spawns_no_practice_room_popup(view: TrainingRoomCombatView) -> void:
	print("-- Hold casts spawn no Practice Room floating text --")
	var hold: Skill = load("res://data/skills/hold.tres")
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	var monster := Monster.new()
	monster.display_name = "Hold Dummy"
	monster.hp = 100000
	var result := CombatResolver.resolve([hold], player, monster, 3000, 5)
	_require(result.cast_events.size() == 3, "Test setup error: expected three Hold casts.")
	view.play(result, monster)
	var found_hold_popup := false
	for child in view._popup_layer.get_children():
		if child is Label and child.text.begins_with("Hold"):
			found_hold_popup = true
	print("found Hold popup (expect false): %s" % found_hold_popup)
	_require(not found_hold_popup, "Expected Hold to spawn no Practice Room floating text.")


func _status_chip_text(chip: Node) -> String:
	if chip is Label:
		return chip.text
	var label := chip.get_node_or_null("Text") as Label
	if label != null:
		return label.text
	return ""


func _status_chip_font_size(row: Container, icon_texture: Texture2D) -> int:
	for child in row.find_children("*", "HBoxContainer", true, false):
		var icon := child.get_node_or_null("Icon") as TextureRect
		var label := child.get_node_or_null("Text") as Label
		if icon != null and icon.texture == icon_texture and label != null:
			return label.get_theme_font_size("font_size")
	return 0


func _has_chip(row: Container, icon_texture: Texture2D, text: String) -> bool:
	for child in row.find_children("*", "HBoxContainer", true, false):
		var icon := child.get_node_or_null("Icon") as TextureRect
		if icon == null or icon.texture != icon_texture:
			continue
		if _status_chip_text(child) == text:
			return true
	return false


func _chip_tooltip(row: Container, icon_texture: Texture2D, text: String) -> String:
	for child in row.find_children("*", "HBoxContainer", true, false):
		var icon := child.get_node_or_null("Icon") as TextureRect
		if icon == null or icon.texture != icon_texture:
			continue
		if _status_chip_text(child) == text:
			return child.tooltip_text
	return ""


func _mechanic_chip_ids(row: Container) -> PackedStringArray:
	var ids := PackedStringArray()
	for child in row.get_children():
		ids.append(String(child.get_meta("effect_id", "")))
	return ids


## Independently replays the same merged cast/tick timeline
## TrainingRoomCombatView itself plays, using CombatPlayback's own
## time-ordered merge (CombatPlayback._merge_events()) so this is a real
## cross-check of the view's bookkeeping, not a restatement of its code.
func _expected_final_stacks(result: CombatResolver.CombatResult) -> int:
	var events: Array = CombatPlayback._merge_events(result)
	var stacks := 0
	var poison_stack_cap := maxi(1, result.poison_stack_cap)
	for event in events:
		if event.is_tick:
			stacks = event.tick.stacks_remaining
		else:
			stacks = mini(stacks + event.cast.poison_stacks_applied, poison_stack_cap)
			if event.cast.cleanse_triggered:
				stacks = 0
	return stacks


## User-reported: the poison cadence beat still fires every 1000ms even with
## zero active stacks (CombatResolver.resolve()'s documented "fixed cadence
## independent of cast timing" behavior), always at 0 damage --
## CombatResultFormatter already treats these as noise and skips them in the
## text log; the popup must too, instead of showing a "Poison 0.0" popup
## with nothing actually happening. Stab has no poison effect at all, so
## every tick in this fight is a guaranteed zero-stack cadence beat.
func _check_no_popup_for_zero_stack_ticks(view: TrainingRoomCombatView) -> void:
	print("-- No popup for a poison tick with zero active stacks --")
	var stab: Skill = load("res://data/skills/stab.tres")
	var rotation: Array[Skill] = [stab]
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	var monster := Monster.new()
	monster.display_name = "Unpoisoned Dummy"
	monster.hp = 100000
	var result := CombatResolver.resolve(rotation, player, monster, 8000, 5)
	_require(not result.tick_events.is_empty(), "Expected cadence ticks to fire even with no poison skill.")
	var any_nonzero_tick := false
	for tick in result.tick_events:
		if tick.damage > 0.0:
			any_nonzero_tick = true
	_require(not any_nonzero_tick, "Test setup error: expected every tick to be a zero-stack cadence beat.")

	view.play(result, monster)
	var poison_popups := 0
	for child in view._popup_layer.get_children():
		# Exclude nodes already queue_free()'d by a *previous* check's
		# play() -- they linger in get_children() until the next idle frame
		# (is_queued_for_deletion() is the robust check, not frame timing).
		if child.is_queued_for_deletion():
			continue
		if child is Label and child.text.begins_with("Poison"):
			poison_popups += 1
	print("poison popups spawned for an all-zero-stack fight (expect 0): %d" % poison_popups)
	_require(poison_popups == 0, "A zero-damage poison tick must not spawn a popup.")


func _check_absorbed_zero_damage_tick_still_presents(view: TrainingRoomCombatView) -> void:
	print("-- Fully absorbed poison tick still presents as a 0-damage hit --")
	var poison_strike: Skill = load("res://data/skills/poison_strike.tres")
	var rotation: Array[Skill] = [poison_strike]
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	player.poison_damage_per_tick = 8.0
	var monster := Monster.new()
	monster.display_name = "Absorbing Dummy"
	monster.hp = 100000
	monster.absorb = 20.0
	var result := CombatResolver.resolve(rotation, player, monster, 2500, 3)
	_require(result.tick_events.any(func(tick): return tick.damage == 0.0 and tick.absorbed_amount > 0.0), "Test setup error: expected a fully absorbed poison tick.")

	view.play(result, monster)
	var found_absorbed_popup := false
	for child in view._popup_layer.get_children():
		if child.is_queued_for_deletion():
			continue
		if child is Label and child.text == "Poison 0.0":
			found_absorbed_popup = true
	print("found Poison 0.0 popup for fully absorbed tick (expect true): %s" % found_absorbed_popup)
	_require(found_absorbed_popup, "A fully absorbed poison tick should still spawn a 0-damage popup.")

	var practice_log := CombatResultFormatter.format_practice(result, monster)
	print(practice_log)
	_require(practice_log.contains("Poison ticks for 0.0 (absorbed 8.0)"), "Combat log should show fully absorbed poison ticks as 0-damage hits.")
	var inspector := CombatLogInspectorData.build(result, monster)
	var poison_rows: Array = (inspector["timeline_rows"] as Array).filter(func(row): return String(row["kind"]) == CombatLogInspectorData.KIND_POISON)
	_require(poison_rows.size() == 1, "Combat Log inspector should include a poison timeline row for fully absorbed ticks.")


func _check_resisted_zero_damage_tick_still_presents(view: TrainingRoomCombatView) -> void:
	print("-- Fully resisted poison tick still presents as a 0-damage hit --")
	var poison_strike: Skill = load("res://data/skills/poison_strike.tres")
	var rotation: Array[Skill] = [poison_strike]
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	player.poison_damage_per_tick = 8.0
	var monster := Monster.new()
	monster.display_name = "Resisting Dummy"
	monster.hp = 100000
	monster.poison_resistance = 1.0
	var result := CombatResolver.resolve(rotation, player, monster, 2500, 3)
	_require(result.tick_events.any(func(tick): return tick.had_active_stack and tick.damage == 0.0 and tick.absorbed_amount == 0.0), "Test setup error: expected a fully resisted poison tick.")

	view.play(result, monster)
	var found_resisted_popup := false
	for child in view._popup_layer.get_children():
		if child.is_queued_for_deletion():
			continue
		if child is Label and child.text == "Poison 0.0":
			found_resisted_popup = true
	print("found Poison 0.0 popup for fully resisted tick (expect true): %s" % found_resisted_popup)
	_require(found_resisted_popup, "A fully resisted poison tick should still spawn a 0-damage popup.")


func _check_popup_for_damaging_poison_ticks(view: TrainingRoomCombatView) -> void:
	print("-- Damaging poison tick spawns green half-size poison text near the enemy --")
	var poison_strike: Skill = load("res://data/skills/poison_strike.tres")
	var rotation: Array[Skill] = [poison_strike]
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	player.poison_damage_per_tick = 5.0
	var monster := Monster.new()
	monster.display_name = "Poisoned Dummy"
	monster.hp = 100000
	monster.poison_resistance = 0.0
	var result := CombatResolver.resolve(rotation, player, monster, 4500, 3)
	_require(result.tick_events.any(func(tick): return tick.damage > 0.0), "Test setup error: expected at least one damaging poison tick.")

	view.play(result, monster)
	var found_poison_popup := false
	var found_bounded_target_popup := false
	var enemy_local: Vector2 = view._popup_layer.get_global_transform().affine_inverse() * view._combat_stage.enemy_popup_global_position()
	for child in view._popup_layer.get_children():
		if child.is_queued_for_deletion():
			continue
		if child is Label and child.text.begins_with("Poison"):
			var color: Color = child.get_theme_color("font_color")
			var font_size: int = child.get_theme_font_size("font_size")
			if color == UIColors.TEXT_POISON and font_size == view.POPUP_TICK_FONT_SIZE:
				found_poison_popup = true
				# G06 reserves Poison a bounded target-side band, below the ghost/status lanes.
				# The old <=48px enemy-center rule caused overlap with accepted ghost labels.
				var popup_rect: Rect2 = child.get_global_rect()
				var stage_rect: Rect2 = view._combat_stage.play_area_global_rect()
				if stage_rect.grow(1).encloses(popup_rect) and popup_rect.position.x >= stage_rect.position.x + stage_rect.size.x*0.7 and popup_rect.position.y >= stage_rect.position.y+150:
					found_bounded_target_popup = true
				for button in view._content.find_children("*","Button",true,false):
					if button.visible and button.text in ["Fight","Fight!","Combat Log"]:
						_require(not popup_rect.intersects(button.get_global_rect()),"Poison text must not overlap footer actions.")
	print("found a green half-size poison popup for damaging poison tick (expect true): %s" % found_poison_popup)
	_require(found_poison_popup, "A damaging poison tick should spawn green half-size poison text.")
	_require(found_bounded_target_popup, "Poison tick text should stay inside the target-side combat band below status values.")


func _check_wyvern_kriss_uses_smaller_poison_tick_text(view: TrainingRoomCombatView) -> void:
	print("-- Wyvern Kriss uses smaller poison tick text --")
	var poison_strike: Skill = load("res://data/skills/poison_strike.tres")
	var wyvern_kriss: GearItem = load("res://data/gear/wyvern_kriss.tres")
	var rotation: Array[Skill] = [poison_strike]
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	player.poison_damage_per_tick = 5.0
	var monster := Monster.new()
	monster.display_name = "Wyvern Poison Dummy"
	monster.hp = 100000
	monster.poison_resistance = 0.0
	var result := CombatResolver.resolve(rotation, player, monster, 4500, 3)
	_require(result.tick_events.any(func(tick): return tick.damage > 0.0), "Test setup error: expected at least one damaging poison tick.")

	var equipped_gear: Array[GearItem] = [wyvern_kriss]
	view.play(result, monster, equipped_gear)
	var found_wyvern_tick_popup := false
	for child in view._popup_layer.get_children():
		if child.is_queued_for_deletion():
			continue
		if child is Label and child.text.begins_with("Poison"):
			var color: Color = child.get_theme_color("font_color")
			var font_size: int = child.get_theme_font_size("font_size")
			if color == UIColors.TEXT_POISON and font_size == view.POPUP_WYVERN_TICK_FONT_SIZE:
				found_wyvern_tick_popup = true
	print("found smaller Wyvern poison tick popup (expect true): %s" % found_wyvern_tick_popup)
	_require(found_wyvern_tick_popup, "Wyvern Kriss should make poison tick text smaller than the default poison tick popup.")


func _check_poison_stack_application_tints_enemy_without_popup(view: TrainingRoomCombatView) -> void:
	print("-- Poison stack application tints the enemy without floating stack text --")
	var poison_strike: Skill = load("res://data/skills/poison_strike.tres")
	var rotation: Array[Skill] = [poison_strike]
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	player.poison_damage_per_tick = 5.0
	var monster := Monster.new()
	monster.display_name = "Poison Stack Dummy"
	monster.hp = 100000
	monster.poison_resistance = 0.0
	var result := CombatResolver.resolve(rotation, player, monster, 2200, 3)
	_require(result.cast_events.any(func(cast): return cast.poison_stacks_applied > 0), "Test setup error: expected at least one poison-applying cast.")

	view.play(result, monster)
	_require(view._combat_stage.poison_stack_tint_updates > 0, "Expected poison-applying casts to update the shared poison tint.")
	_require(view._combat_stage.last_poison_stack_tint_stacks >= 0, "Expected shared poison tint to record the active stack count.")
	var found_stack_popup := false
	for child in view._popup_layer.get_children():
		if child.is_queued_for_deletion():
			continue
		if child is Label and child.text.begins_with("Poison x"):
			found_stack_popup = true
	print("found a poison-stack popup (expect false): %s" % found_stack_popup)
	_require(not found_stack_popup, "Poison stack counts should stay in the UI chips, not spawn floating text.")


## User-requested: a Legendary effect actually firing (Bejeweled Push
## Dagger's minimum-cast-time proc here) should be visually distinct in the
## combat animation, not read identically to an ordinary hit. Forces the
## proc chance to 1.0 so every cast is guaranteed to trigger it.
func _check_legendary_proc_popup_highlight(view: TrainingRoomCombatView) -> void:
	print("-- Legendary proc (minimum-cast-time) gets a highlighted popup --")
	var stab: Skill = load("res://data/skills/stab.tres")
	var rotation: Array[Skill] = [stab]
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	player.min_cast_time_proc_chance = 1.0
	var monster := Monster.new()
	monster.display_name = "Proc Dummy"
	monster.hp = 100000
	var result := CombatResolver.resolve(rotation, player, monster, 4000, 1)
	_require(not result.cast_events.is_empty(), "Expected casts in this known fight.")
	for cast in result.cast_events:
		_require(cast.min_cast_time_proc_applied, "Test setup error: expected every cast to proc at 100% chance.")

	view.play(result, monster)
	var found_magic_proc_popup := false
	for child in view._popup_layer.get_children():
		if child is Label and child.text.ends_with("PROC!"):
			var color: Color = child.get_theme_color("font_color")
			if color == preload("res://scripts/ui/skill_category_preview_style.gd").COLORS[Skill.Category.ATTACK]:
				found_magic_proc_popup = true
	print("found a attack-colored PROC! popup (expect true): %s" % found_magic_proc_popup)
	_require(found_magic_proc_popup, "Expected at least one attack-colored 'PROC!' popup for the guaranteed proc.")

	var log_text := CombatResultFormatter.format(result, monster)
	print("combat log marks the proc line (expect true): %s" % log_text.contains(">>> "))
	_require(log_text.contains(">>> "), "Expected the '>>> ' legendary-proc marker in the text log.")
	_require(log_text.contains("procs at minimum cast speed"), "Expected the proc clause in the text log.")


func _check_crit_popup_highlight(view: TrainingRoomCombatView) -> void:
	print("-- Crit gets a attack-colored, larger popup without literal CRIT text in Practice Room playback --")
	var stab: Skill = load("res://data/skills/stab.tres")
	var rotation: Array[Skill] = [stab]
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 1.0
	player.crit_multiplier = 2.0
	var monster := Monster.new()
	monster.display_name = "Crit Dummy"
	monster.hp = 100000
	var result := CombatResolver.resolve(rotation, player, monster, 2200, 1)
	_require(not result.cast_events.is_empty(), "Expected casts in this known crit fight.")
	for cast in result.cast_events:
		_require(cast.is_crit, "Test setup error: expected every cast to crit at 100% chance.")

	view.play(result, monster)
	var found_gold_crit_popup := false
	for child in view._popup_layer.get_children():
		if child is Label and child.text.ends_with("!") and not child.text.contains("CRIT"):
			var color: Color = child.get_theme_color("font_color")
			var font_size: int = child.get_theme_font_size("font_size")
			var font: Font = child.get_theme_font("font")
			if color == preload("res://scripts/ui/skill_category_preview_style.gd").COLORS[Skill.Category.ATTACK] and font_size == view.POPUP_CRIT_FONT_SIZE and font == view.POPUP_FONT:
				found_gold_crit_popup = true
	print("found a attack-colored larger crit popup without literal CRIT text (expect true): %s" % found_gold_crit_popup)
	_require(found_gold_crit_popup, "Expected at least one attack-colored, larger crit popup using color/size/font instead of literal 'CRIT' text.")


func _check_steal_crit_popup_shows_gold(view: TrainingRoomCombatView) -> void:
	print("-- Steal crit popup shows damage, gold icon, and stolen gold --")
	var steal: Skill = load("res://data/skills/steal.tres")
	var rotation: Array[Skill] = [steal]
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 1.0
	player.crit_multiplier = 2.0
	player.gold_reward_multiplier = 1.2
	var monster := Monster.new()
	monster.display_name = "Coin Dummy"
	monster.hp = 100000
	var result := CombatResolver.resolve(rotation, player, monster, 1300, 1)
	_require(result.gold_stolen == 3, "Test setup error: expected Steal to steal 3 gold.")
	var expected_damage_text := "Steal %.1f!" % result.cast_events[0].physical_damage

	var callback_state := {"gold": 0}
	view.gold_stolen_callback = func(amount: int): callback_state["gold"] = int(callback_state["gold"]) + amount
	view.play(result, monster)
	var found_gold_hit_popup := false
	for child in view._popup_layer.get_children():
		if child.name != "GoldHitPopup":
			continue
		var icon := child.get_node_or_null("GoldIcon")
		var labels: Array[Label] = []
		for grandchild in child.get_children():
			if grandchild is Label:
				labels.append(grandchild)
		if icon != null and icon.custom_minimum_size == view.GOLD_POPUP_ICON_SIZE and labels.size() >= 2 and labels[0].text == expected_damage_text and labels[1].text == "3":
			found_gold_hit_popup = true
	print("found Steal gold-hit popup (expect true): %s" % found_gold_hit_popup)
	_require(found_gold_hit_popup, "Expected Steal crit popup to include damage text, gold icon, and stolen gold value.")
	_require(int(callback_state["gold"]) == 3, "Expected Steal playback to report stolen gold when the popup event plays.")
	view.gold_stolen_callback = Callable()


func _check_crit_negation_popup(view: TrainingRoomCombatView) -> void:
	print("-- Crit negation shows crossed-out would-have-been crit plus reduced damage --")
	var stab: Skill = load("res://data/skills/stab.tres")
	var rotation: Array[Skill] = [stab]
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 1.0
	player.crit_multiplier = 2.0
	var monster := Monster.new()
	monster.display_name = "Crit Negation Dummy"
	monster.hp = 100000
	monster.crit_negation = 0.5
	var result := CombatResolver.resolve(rotation, player, monster, 1600, 1)
	_require(not result.cast_events.is_empty(), "Expected casts in this known crit-negation fight.")
	_require(result.cast_events[0].is_crit and result.cast_events[0].crit_negation_damage_prevented > 0.0, "Test setup error: expected crit negation to prevent final damage.")

	view.play(result, monster)
	var found_negation_popup := false
	for child in view._popup_layer.get_children():
		if child.is_queued_for_deletion():
			continue
		var cross := child.get_node_or_null("CritCrossOutOverlay")
		if child.name == "CritNegationPopup" and cross != null and cross.position.x > 0.0:
			found_negation_popup = true
	print("found crossed-out crit-negation popup (expect true): %s" % found_negation_popup)
	_require(found_negation_popup, "Expected crit-negated crits to show the crossed-out crit popup.")


func _require(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		print("FAILED: %s" % message)
