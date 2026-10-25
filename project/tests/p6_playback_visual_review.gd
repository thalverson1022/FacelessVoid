extends SceneTree
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")
func _initialize() -> void:
	call_deferred("_run")
func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/p6_m4_t7_visual/" + label + ".png")
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/p6_m4_t7_visual")
	SaveSystem.save_path = "res://reports/p6_m4_t7_visual/adventure.json"
	PracticeSaveSystem.save_path = "res://reports/p6_m4_t7_visual/legacy.json"
	PracticeSaveSystem.core_save_path = "res://reports/p6_m4_t7_visual/practice.json"
	if FileAccess.file_exists(PracticeSaveSystem.core_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PracticeSaveSystem.core_save_path))
	CombatEffectIcons.reduced_motion = true
	var state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._on_contract_test_pressed(7, 10)
	await process_frame
	var registry := BuildContentRegistry.test_mode()
	for id in Core.RANKS:
		for rank in Core.RANKS[id]: state.select_talent(registry.talents[id])
	state.set_rotation(Core.rotation(state.unlocked_skills()))
	state.accept_contract_offer()
	state.choose_contract_route_node(state.current_route_node.next_nodes[0])
	var screen = game._current_screen
	screen._contract_overlay.hide()
	screen._map_overlay.hide()
	state.set_locked(true)
	screen.set_process(false)
	var enemy := Monster.new()
	enemy.display_name = "T7 core presentation fixture"
	enemy.hp = 100000
	var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
	var resolved := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], Core.build(registry), gear)
	var result := CombatResolver.resolve(Core.rotation(resolved.skills), resolved.stats, enemy, 20000, 7)
	screen._on_fight_pressed()
	screen._playback_presenter._intro_remaining_sec = 0
	screen._playback_presenter.advance(1.69)
	for size in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080)]:
		root.size = size
		await capture("core-effects-%d" % size.x)
	screen._playback_presenter.advance(0.52)
	screen._skill_build_panel._on_slot_pressed(3)
	screen._skill_build_panel._inspect_selected()
	root.size = Vector2i(1280,720)
	await capture("live-plunge-1280")
	screen._skill_build_panel._details.hide()
	screen._effect_icons._open_inspector()
	await capture("core-inspector-1280")
	screen._effect_icons._dialog.hide()
	screen._playback_presenter.skip()
	await capture("finished-1280")
	game._on_main_menu_pressed()
	game._show_training_room()
	await process_frame
	var practice = game._current_screen
	for id in Core.RANKS:
		for rank in Core.RANKS[id]: practice._state.select_talent(registry.talents[id])
	practice._state.set_rotation(Core.rotation(practice._state.unlocked_skills()))
	practice._state.set_locked(true)
	var view = practice._combat_view
	practice._state.fight_seed = 7
	practice._state.random_fight_seed_enabled = false
	view._skip_playback_on_fight = false
	practice._on_fight_button_pressed()
	view.set_process(false)
	view._playback_intro_remaining_sec = 0
	view._process(1.69)
	for size in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080)]:
		root.size = size
		await capture("practice-effects-%d" % size.x)
	view._skip()
	var parry: Skill
	for skill in practice._state.unlocked_skills():
		if skill.id == "skill.parry_strike": parry = skill
	practice._state.set_locked(false)
	var unavailable: Array[Skill] = [parry]
	practice._state.set_rotation(unavailable)
	practice._state.set_locked(true)
	view._skip_playback_on_fight = false
	practice._on_fight_button_pressed()
	view.set_process(false)
	view._playback_intro_remaining_sec = 0
	view._process(0.25)
	root.size = Vector2i(1280,720)
	await capture("missing-readiness-1280")
	view._skip()
	# Test-only Dance resources for shared-cooldown presentation, never saved.
	practice._setup_autosave = false
	var dance := Skill.new()
	dance.id = "skill.dance_of_death"
	dance.display_name = "Dance of Death"
	dance.category = Skill.Category.SELF_BUFF
	dance.base_execution_ms = 500
	dance.min_execution_ms = 500
	dance.cooldown_ms = 20000
	dance.dance_duration_ms = 5000
	var dancing: Array[Skill] = [dance, dance]
	practice._state.rotation = dancing
	practice._state.build_changed.emit()
	var dancer: PlayerStats = resolved.stats.duplicate(true)
	dancer.dance_duration_ms = 5000
	var cooldown_result := CombatResolver.resolve([dance, dance], dancer, enemy, 21000, 7)
	view._skip_playback_on_fight = false
	view.play(cooldown_result, enemy)
	view.set_process(false)
	view._playback_intro_remaining_sec = 0
	view._process(0.55)
	view._effect_icons._inspect.text = "SYNTHETIC cooldown fixture / Inspect"
	await capture("synthetic-cooldown-1280")
	var synthetic := CombatResolver.CombatResult.new()
	synthetic.duration_ms = 10000
	for i in 12:
		synthetic.trace.record("effect_lifecycle", 0, {"source_id": "talent.synthetic", "effect_instance_id": "test%d" % i}, {"effect_id": "footwork" if i == 0 else "readiness" if i == 1 else "dance" if i == 2 else "synthetic_%d" % i, "after": {"units": 3 if i == 0 else 1, "unit": "stacks" if i == 0 else "charges", "expires_at_ms": -1 if i == 1 else 5000}})
	view._effect_icons.begin(synthetic)
	root.size = Vector2i(1280,720)
	view._effect_icons._inspect.text = "SYNTHETIC +8 effects / Inspect"
	await capture("synthetic-overflow-1280")
	view._effect_icons._open_inspector()
	view._effect_icons._dialog.title = "SYNTHETIC layout fixture - not playable content"
	await capture("synthetic-inspector-1280")
	view._effect_icons._details.get_v_scroll_bar().value = 100000
	await capture("synthetic-inspector-bottom-1280")
	game.queue_free()
	await process_frame
	state.reset()
	quit()
