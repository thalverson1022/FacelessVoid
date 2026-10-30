extends SceneTree
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")
const OUT := "res://reports/p6_compact_ui_visual"
func _initialize() -> void: call_deferred("run")
func settle() -> void:
 await process_frame
 await process_frame
func capture(label: String) -> void:
 await settle()
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OUT + "/" + label + ".png")
func add_core(state) -> void:
 var registry := BuildContentRegistry.test_mode()
 for id in Core.RANKS:
  for rank in Core.RANKS[id]: state.select_talent(registry.talents[id])
 state.set_rotation(Core.rotation(state.unlocked_skills()))
func tooltip(button: Button, label: String) -> void:
 var panel = button._make_custom_tooltip(button._get_tooltip(Vector2.ZERO))
 root.add_child(panel)
 panel.position = Vector2(680, 390)
 await capture(label)
 panel.queue_free()
 await settle()
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 SaveSystem.save_path = OUT + "/adventure.json"
 PracticeSaveSystem.save_path = OUT + "/legacy.json"
 PracticeSaveSystem.core_save_path = OUT + "/practice.json"
 if FileAccess.file_exists(PracticeSaveSystem.core_save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(PracticeSaveSystem.core_save_path))
 var game = load("res://scenes/game_root.tscn").instantiate()
 root.add_child(game)
 await settle()
 game._on_contract_test_pressed(7, 10)
 await settle()
 var state = root.get_node("BuildState")
 add_core(state)
 state.accept_contract_offer()
 state.choose_contract_route_node(state.current_route_node.next_nodes[0])
 var screen = game._current_screen
 screen._contract_overlay.hide()
 screen._map_overlay.hide()
 var full: Array[Skill] = state.rotation.duplicate()
 full.append_array(state.rotation)
 state.set_rotation(full)
 for dimensions in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
  root.size = dimensions
  await capture("test-build-%d" % dimensions.x)
  screen._talent_overlay.show_overlay()
  await capture("test-tree-%d" % dimensions.x)
  screen._talent_overlay.hide()
 root.size = Vector2i(1280,720)
 await tooltip(screen._skill_build_panel._slot_buttons[0], "skill-tooltip")
 screen._talent_overlay.show_overlay()
 await settle()
 await tooltip(screen._talent_overlay._talent_panel._ranked_view.actions["buy:talent.bladedancer.fancy_footwork"], "talent-tooltip")
 game._on_main_menu_pressed()
 await settle()
 game._show_training_room()
 await settle()
 var practice = game._current_screen
 practice._state.set_talent_budget(10)
 add_core(practice._state)
 for dimensions in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
  root.size = dimensions
  await capture("practice-build-%d" % dimensions.x)
  practice._show_talent_overlay()
  await capture("practice-tree-%d" % dimensions.x)
  practice._talent_overlay.hide()
 game.queue_free()
 await settle()
 state.reset()
 quit()
