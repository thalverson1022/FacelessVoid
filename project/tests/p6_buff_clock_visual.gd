extends SceneTree
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")
const OUT := "res://reports/p6_buff_clock_visual"
func _initialize() -> void: call_deferred("run")
func settle() -> void:
 await process_frame
 await process_frame
func capture(label: String) -> void:
 await settle()
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OUT + "/" + label + ".png")
func build(state) -> void:
 var registry := BuildContentRegistry.test_mode()
 for id in Core.RANKS:
  for rank in Core.RANKS[id]: state.select_talent(registry.talents[id])
 state.set_rotation(Core.rotation(state.unlocked_skills()))
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 SaveSystem.save_path = OUT + "/adventure.json"
 PracticeSaveSystem.save_path = OUT + "/legacy.json"
 PracticeSaveSystem.core_save_path = OUT + "/practice.json"
 if FileAccess.file_exists(PracticeSaveSystem.core_save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(PracticeSaveSystem.core_save_path))
 CombatEffectIcons.reduced_motion = true
 var game = load("res://scenes/game_root.tscn").instantiate()
 root.add_child(game)
 await settle()
 game._on_contract_test_pressed(7, 10)
 await settle()
 var state = root.get_node("BuildState")
 build(state)
 state.accept_contract_offer()
 state.choose_contract_route_node(state.current_route_node.next_nodes[0])
 var screen = game._current_screen
 screen._contract_overlay.hide()
 screen._map_overlay.hide()
 state.set_locked(true)
 screen._on_fight_pressed()
 screen.set_process(false)
 screen._playback_presenter.advance(1.69)
 for dimensions in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
  root.size = dimensions
  await capture("test-buffs-%d" % dimensions.x)
 screen._playback_presenter.advance(1.5)
 root.size = Vector2i(1280,720)
 await capture("test-buffs-later")
 screen._on_playback_skip_pressed()
 game._on_main_menu_pressed()
 await settle()
 game._show_training_room()
 await settle()
 var practice = game._current_screen
 build(practice._state)
 practice._state.equipped_weapon = load("res://data/gear/crude_dagger.tres")
 practice._state.set_fight_seed(7)
 practice._state.set_random_fight_seed_enabled(false)
 practice._state.set_locked(true)
 practice._combat_view._instant_playback = false
 practice._on_fight_button_pressed()
 practice._combat_view.set_process(false)
 practice._combat_view._process(1.69)
 for dimensions in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
  root.size = dimensions
  await capture("practice-buffs-%d" % dimensions.x)
 practice._combat_view._skip()
 game.queue_free()
 await settle()
 state.reset()
 quit()
