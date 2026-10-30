extends "res://tests/p6_core_journey_test.gd"
class StressTooltip extends IconTooltipButton:
	func _make_custom_tooltip(for_text: String) -> Object:
		var panel = super._make_custom_tooltip(for_text)
		for label in panel.find_children("*", "Label", true, false):
			label.add_theme_font_size_override("font_size", 28)
		return panel

const Mixed = preload("res://tests/fixtures/p6/mixed_build.gd")
const Gold = preload("res://scripts/systems/combat_gold.gd")

func _initialize() -> void:
	super._initialize()

func key(code: Key, shift := false, target: Window = root) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.shift_pressed = shift
	event.pressed = true
	target.push_input(event)
	await settle()
	event.pressed = false
	target.push_input(event)
	await settle()

func tab_to(view, action: String) -> bool:
	for i in 100:
		if root.gui_get_focus_owner() == view.actions[action]: return true
		await key(KEY_TAB)
	return false

func scale_text(node: Node) -> void:
	if node is Control:
		var control := node as Control
		if control is Label or control is Button or control is LineEdit or control is RichTextLabel:
			control.add_theme_font_size_override("font_size", ceili(control.get_theme_font_size("font_size") * 1.25))
	for child in node.get_children(): scale_text(child)

func geometry(view: Control, label_text: String) -> void:
	var visible_rect := root.get_visible_rect()
	check(visible_rect.encloses(view.find_child("TreesSideBySide", true, false).get_global_rect()), label_text + ": trees remain on screen")
	for node in view.find_children("*", "Label", true, false):
		if node.is_visible_in_tree() and node.text != "":
			check(node.size.y + 1 >= node.get_minimum_size().y, label_text + ": label has required height: " + node.text)

func windows(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children(true):
		if child is Window and child.visible: result.append(child)
		result.append_array(windows(child))
	return result

func _run() -> void:
	report = "res://reports/p6_t10_usability"
	visual = "--visual" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(report)
	SaveSystem.save_path = report + "/adventure.json"
	PracticeSaveSystem.save_path = report + "/legacy.json"
	PracticeSaveSystem.core_save_path = report + "/practice.json"
	if FileAccess.file_exists(PracticeSaveSystem.core_save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(PracticeSaveSystem.core_save_path))
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._show_training_room()
	await settle()
	var scene = game._current_screen
	var state = scene._state
	state.set_talent_budget(20)
	scene._show_talent_overlay()
	await settle()
	var view = scene._talent_panel._ranked_view
	check(await tab_to(view, "secondary:tree.thief"), "Keyboard reaches secondary choice card")
	await key(KEY_ENTER)
	check(state.ranked_build.secondary_tree().id == "tree.thief", "Keyboard selects secondary tree")
	check(await tab_to(view, "swap"), "Keyboard reaches role swap")
	await key(KEY_ENTER)
	check(state.ranked_build.primary_tree().id == "tree.thief", "Keyboard swaps tree roles")
	await key(KEY_ENTER)
	check(state.ranked_build.primary_tree().id == "tree.bladedancer", "Keyboard restores roles after refresh")
	check(await tab_to(view, "buy:talent.bladedancer.wet_stone"), "Keyboard Tab reaches talent")
	await key(KEY_ENTER)
	check(state.ranked_build.rank_of("talent.bladedancer.wet_stone") == 1, "Keyboard Enter allocates a point")
	await key(KEY_DELETE)
	check(state.ranked_build.rank_of("talent.bladedancer.wet_stone") == 0, "Keyboard Delete refunds a point")
	await key(KEY_ENTER)
	check(await tab_to(view, "reset:tree.bladedancer"), "Keyboard reaches per-tree reset")
	await key(KEY_ENTER)
	check(state.ranked_build.points_spent() == 0, "Keyboard reset refunds the tree")
	var preview_key := "buy:talent.thief.load_dice"
	check(await tab_to(view, preview_key), "Keyboard Tab reaches locked high-tier talent")
	await key(KEY_F1)
	var navigation = scene._talent_overlay.get_node("TalentKeyboardNavigation")
	check(navigation.details.visible and "Loaded Dice" in navigation.details.dialog_text, "F1 inspects locked talent without allocating")
	await capture("keyboard-locked-talent-details")
	await key(KEY_ESCAPE, false, navigation.details)
	check(not navigation.details.visible, "Escape closes keyboard inspection")
	var contained := true
	for i in navigation.controls().size() + 2:
		await key(KEY_TAB)
		contained = contained and scene._talent_overlay.is_ancestor_of(root.gui_get_focus_owner())
	check(contained, "Full keyboard traversal wraps inside modal")
	await key(KEY_TAB, true)
	check(scene._talent_overlay.is_ancestor_of(root.gui_get_focus_owner()), "Shift Tab stays within modal")
	await key(KEY_ESCAPE)
	check(not scene._talent_overlay.visible, "Escape closes talent modal")
	scene._show_talent_overlay()
	await settle()
	for id in Mixed.RANKS:
		for rank in Mixed.RANKS[id]: state.select_talent(state.content_registry.talents[id])
	await settle()
	view.feedback = ""
	view.refresh()
	await settle()
	scale_text(scene._talent_overlay)
	await settle()
	await settle()
	geometry(view, "Practice 125%")
	await capture("practice-text-125")
	# Actual engine hover tooltips at all four corners, using the longest live talent tooltip.
	if visual:
		var probe := StressTooltip.new()
		probe.size = Vector2(40, 40)
		probe.z_index = 4090
		probe.tooltip_text = view.actions["buy:talent.bladedancer.fancy_footwork"]._get_tooltip(Vector2.ZERO)
		root.add_child(probe)
		for dimensions in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080)]:
			root.size = dimensions
			await settle()
			for corner in [Vector2(2,2), Vector2(1558,2), Vector2(2,858), Vector2(1558,858)]:
				probe.tooltip_text = view.unlock_tooltip(state.unlocked_skills().filter(func(skill): return skill.id == "skill.dance_of_death")[0]) if corner.x > 100 else view.actions["buy:talent.bladedancer.fancy_footwork"]._get_tooltip(Vector2.ZERO)
				probe.position = corner
				var motion := InputEventMouseMotion.new()
				motion.position = corner + Vector2(20,20)
				motion.global_position = motion.position
				root.warp_mouse(motion.position)
				root.push_input(motion, true)
				await create_timer(1.5).timeout
				await settle()
				var popups := windows(root)
				check(not popups.is_empty(), "Engine tooltip appears at " + str(corner))
				for popup in popups:
					check(Rect2i(root.get_visible_rect()).encloses(Rect2i(popup.position, popup.size)), "Tooltip bounded at %s window %s rect %s" % [corner, root.size, Rect2i(popup.position,popup.size)])
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(report + "/tooltip-%d-%d-%d.png" % [dimensions.x,corner.x,corner.y])
		probe.queue_free()
	# Dense playable skill library and full rotation.
	scene._talent_overlay.hide()
	var rotation: Array[Skill] = state.unlocked_skills().duplicate()
	state.set_rotation(rotation)
	check(state.rotation.size() >= 10, "Dense mixed skill rotation accepted")
	await settle()
	await capture("dense-mixed-rotation")
	state.selected_target = state.selected_target.duplicate(true)
	state.selected_target.hp = 100000
	state.set_locked(true)
	CombatEffectIcons.reduced_motion = false
	scene._combat_view._skip_playback_on_fight = false
	scene._on_fight_button_pressed()
	scene._combat_view.set_process(false)
	scene._combat_view._playback_intro_remaining_sec = 0
	scene._combat_view._process(6.0)
	check(state.last_result != null and state.last_result.is_valid, "Mixed busy combat resolves through actual Practice controls")
	await capture("busy-combat")
	var preserved_records: Array = scene._combat_view._effect_icons.model.records.duplicate(true)
	scene._combat_view._effect_icons._motion.button_pressed = true
	check(CombatEffectIcons.reduced_motion and scene._combat_view._effect_icons.model.records == preserved_records, "Reduced motion retains actual combat observations")
	await capture("busy-combat-reduced-motion")
	scene._combat_view._skip()
	CombatEffectIcons.reduced_motion = false
	# Current inspector with test-only oversized effects and gold-cap boundaries.
	var effects: CombatEffectIcons = scene._combat_view._effect_icons
	var synthetic := CombatResolver.CombatResult.new()
	synthetic.duration_ms = 10000
	for i in 12:
		synthetic.trace.record("effect_lifecycle", 0, {"source_id": "talent.synthetic", "effect_instance_id": "test%d" % i}, {"effect_id": "footwork" if i == 0 else "synthetic_%d" % i, "after": {"units": 3, "expires_at_ms": 5000}})
	effects.begin(synthetic)
	check(effects.active.size() == 12 and effects._inspect.text.contains("+8"), "Current compact effect view exposes twelve synthetic effects")
	effects._open_inspector()
	check(effects._details.text.contains("Synthetic 11"), "Overflow inspector includes last synthetic effect")
	await capture("synthetic-effects-inspector")
	effects._dialog.hide()
	var stats := PlayerStats.new()
	stats.gilded_blade_enabled = true
	stats.silvered_edge_rank = 1
	stats.crit_chance = 0.1
	for stash in [499,500,501]:
		for stolen in [24,25,26]:
			effects.model.stash = stash
			effects.model.stolen = stolen
			effects.model.gold_stats = Gold.crit_values(stats, stash, stolen)
			effects._refresh_inspector()
			check(effects._details.text.contains("Gilded counted stash: %d/500" % mini(stash,500)), "Gilded cap presentation %d / %d" % [stash,stolen])
			check(effects._details.text.contains("Silvered crit chance contribution: +%d%% (cap 25%%)" % mini(stolen,25)), "Silvered cap presentation %d / %d" % [stash,stolen])
			check(effects._details.text.contains("Total crit chance: %.1f%%" % ((0.1 + minf(stolen * 0.01, 0.25)) * 100)), "Combined crit total separately presented")
			check(is_equal_approx(float(effects.model.gold_stats.silvered_crit_bonus), minf(stolen * 0.01,0.25)), "Silvered contribution independent of base crit")
	effects.model.active.clear()
	effects.model.journal.clear()
	effects._open_inspector()
	await settle()
	effects._details.get_v_scroll_bar().value = 0
	await settle()
	await capture("synthetic-gold-caps")
	effects._dialog.hide()
	game._on_contract_test_pressed(7, 10)
	await settle()
	var combat = game._current_screen
	combat._talent_overlay.show_overlay()
	await settle()
	scale_text(combat._talent_overlay)
	await settle()
	await settle()
	geometry(combat._talent_overlay._talent_panel._ranked_view, "Test Mode 125%")
	await capture("test-text-125")
	game.queue_free()
	await settle()
	SaveSystem.write_json(report + ("/visual-checks.json" if visual else "/checks.json"), {"passed": not failed, "count": checks, "evidence": evidence})
	print("T10 usability: %d checks %s" % [checks, "FAIL" if failed else "PASS"])
	quit(1 if failed else 0)
