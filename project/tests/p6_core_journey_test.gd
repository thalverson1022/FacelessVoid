extends SceneTree
## T8: actual mode controllers, controls and resolver; no fabricated win/loss.
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")
var failed := false
var checks := 0
var visual := false
var evidence: Array = []
var report := "res://reports/p6_m4_t8_journey"
func _initialize() -> void:
 call_deferred("_run")
func check(ok: bool, label: String) -> void:
 checks += 1
 evidence.append({"check": label, "pass": ok})
 if not ok:
  failed = true
  printerr("FAILED: " + label)
func settle() -> void:
 await process_frame
 await process_frame
 await process_frame
func outcome(screen) -> void:
 var deadline := Time.get_ticks_msec() + 6000
 while not screen._victory_overlay.visible and Time.get_ticks_msec() < deadline:
  await create_timer(0.05).timeout
 check(screen._victory_overlay.visible, "Outcome controls become visible after presentation delay")
 await create_timer(0.25).timeout
func capture(label: String) -> void:
 if not visual: return
 for dimensions in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080)]:
  root.size = dimensions
  await settle()
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(report + "/%s-%d.png" % [label, dimensions.x])
  evidence.append({"screenshot": "%s-%d.png" % [label, dimensions.x], "window": [dimensions.x,dimensions.y], "logical_viewport": [root.get_visible_rect().size.x,root.get_visible_rect().size.y], "reduced_motion": CombatEffectIcons.reduced_motion})
func press_rank(view, key: String) -> void:
 check(view.actions.has(key), "Rank action exists " + key)
 if view.actions.has(key):
  view.actions[key].grab_focus()
  view.actions[key].pressed.emit()
 await settle()
func allocate(view, state) -> void:
 await press_rank(view, "buy:talent.bladedancer.fancy_footwork")
 check(state.ranked_build.points_spent() == 0 and "5 points" in view.feedback, "Tier gate rejects and explains")
 for id in Core.RANKS:
  for rank in Core.RANKS[id]:
   await press_rank(view, "buy:" + id)
   if state.ranked_build.points_spent() == 9:
    check(state.unlocked_skills().size() == 7, "Empty nine-point slot grants no extra skill")
 check(state.ranked_build.rank_map() == Core.RANKS and state.unlocked_skills().size() == 7, "Exact core allocation unlocks seven skills")
func available_panel(screen):
 for node in screen.find_children("*", "Control", true, false):
  if node.get_script() == load("res://scenes/combat/available_skills_panel.gd"): return node
 return null
func add_skill(panel, id: String) -> void:
 var skills: Array[Skill] = panel.state.unlocked_skills()
 for i in skills.size():
  if skills[i].id == id:
   panel._skills_box.get_child(i).pressed.emit()
   await settle()
   return
 check(false, "Skill available " + id)
func ids(rotation) -> Array:
 var result: Array = []
 for skill in rotation: result.append(skill.id)
 return result
func build_rotation(screen, state) -> void:
 var panel = available_panel(screen)
 for id in Core.ROTATION: await add_skill(panel, id)
 check(ids(state.rotation) == Core.ROTATION, "Rotation built through direct icon clicks")
 var macro = screen._skill_build_panel
 macro._slot_buttons[2].pressed.emit()
 check(ids(state.rotation) == Core.ROTATION, "Left click preserves duplicates and order")
func fresh(state) -> void:
 check(state.is_test_mode and SaveSystem.session_only and state.earned_talent_points == 10 and state.ranked_build.points_spent() == 0 and state.rotation.is_empty() and state.gold == 100, "Fresh Test Mode defaults")
func _run() -> void:
 visual = "--visual" in OS.get_cmdline_user_args()
 DirAccess.make_dir_recursive_absolute(report)
 # Explicit isolated paths also protect direct rendered invocation.
 SaveSystem.save_path = report + "/adventure.json"
 PracticeSaveSystem.save_path = report + "/legacy-practice.json"
 PracticeSaveSystem.core_save_path = report + "/core-practice.json"
 if FileAccess.file_exists(PracticeSaveSystem.core_save_path):
  DirAccess.remove_absolute(ProjectSettings.globalize_path(PracticeSaveSystem.core_save_path))
 SaveSystem.write_json(SaveSystem.save_path, {"sentinel": "Adventure untouched"})
 SaveSystem.write_json(PracticeSaveSystem.save_path, {"sentinel": "Legacy Practice untouched"})
 var adventure := FileAccess.get_file_as_bytes(SaveSystem.save_path)
 var legacy := FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path)
 CombatEffectIcons.reduced_motion = true
 var game = load("res://scenes/game_root.tscn").instantiate()
 root.add_child(game)
 await settle()
 var state = root.get_node("BuildState")
 var count := 0
 for button in game._current_screen.find_children("*", "Button", true, false):
  if "Adventure" in button.text:
   check(not button.disabled, "Adventure entries enabled when save exists; load validation is separate")
   count += 1
 check(count == 2, "New and resume Adventure entries present")
 game._on_contract_test_pressed(7, 10)
 await settle()
 fresh(state)
 var screen = game._current_screen
 var ranks = screen._talent_overlay._talent_panel._ranked_view
 await allocate(ranks, state)
 await build_rotation(screen, state)
 # Refund crossing loses automatic skills and prunes macro entries silently.
 await press_rank(ranks, "reset:tree.bladedancer")
 check(state.ranked_build.points_spent() == 0 and state.rotation.is_empty() and ranks.feedback == "Allocation updated.", "Refund resets ranks and prunes macro skills without removal status")
 await allocate(ranks, state)
 check(state.rotation.is_empty(), "Reallocation does not silently restore macro")
 await build_rotation(screen, state)
 screen._contract_overlay.accept_requested.emit("")
 await settle()
 await press_rank(ranks, "reset:tree.bladedancer")
 check(state.ranked_build.points_spent() == 0 and state.ranked_build.unspent_points() == 10 and state.rotation.is_empty(), "Test Mode resets points and prunes rotation inside active contract")
 await allocate(ranks, state)
 await build_rotation(screen, state)
 screen._map_overlay.route_node_pressed.emit(state.current_route_node.next_nodes[0])
 await settle()
 screen._contract_overlay.hide()
 screen._map_overlay.hide()
 await capture("test-core-ready")
 screen.instant_playback = false
 screen._skill_build_panel._lock_button.pressed.emit()
 screen._on_fight_pressed()
 screen.set_process(false)
 check(state.last_combat_result != null and state.last_combat_result.is_valid and state.last_combat_result.is_win, "Real seed-7 core fight wins against generated target")
 evidence.append({"fixture": "Test Mode", "seed": 7, "target": screen._enemy_panel.monster().display_name, "gear": state.equipped_weapon.id, "damage": state.last_combat_result.total_damage})
 for speed in [1.0,2.0,4.0]:
  screen._set_playback_speed(speed)
  screen._playback_presenter.advance(0.2)
 check(screen._playback_active and screen._view_log_button.disabled, "Playback keeps result actions locked")
 await capture("test-core-playing")
 screen._on_playback_skip_pressed()
 await outcome(screen)
 check(not screen._playback_active and screen._effect_icons.active.is_empty(), "Skip completes and clears Test Mode effects")
 var before_gold: int = state.gold
 var reward_gold: int = state.current_modified_reward_gold()
 await screen._on_continue_pressed()
 check(state.gold == before_gold + reward_gold, "Actual win rewards deposited exactly once")
 var after_gold: int = state.gold
 check(not state.claim_current_reward() and state.gold == after_gold, "Repeated reward claim rejected")
 if state.has_pending_reward_choice():
  screen._finish_reward_choice_reveal()
  await capture("test-reward")
  await screen._on_reward_choice_pressed(state.pending_reward_choices[0])
  check(not state.has_pending_reward_choice(), "Reward equipment chosen through controller")
 if state.shop_round_pending:
  screen._on_shop_continue_pressed()
 await settle()
 check(state.run_phase == state.RunPhase.CONTRACT_ROUTE, "Reward and shop continue to next route choice")
 screen._autosave()
 screen._on_save_and_quit_pressed()
 await settle()
 check(not state.is_test_mode and not SaveSystem.session_only, "Save-and-quit returns to Title and clears session")
 game._on_contract_test_pressed(7, 10)
 await settle()
 fresh(state)
 # Hold is supported content: actual resolver loss followed by UI retry and terminal loss.
 screen = game._current_screen
 await add_skill(available_panel(screen), "skill.hold")
 screen._contract_overlay.accept_requested.emit("")
 screen._map_overlay.route_node_pressed.emit(state.current_route_node.next_nodes[0])
 screen._skill_build_panel._lock_button.pressed.emit()
 screen.instant_playback = false
 screen._on_fight_pressed()
 screen.set_process(false)
 screen._on_playback_skip_pressed()
 await outcome(screen)
 check(not state.last_combat_result.is_win and state.can_retry_current_encounter(), "Real Hold-only loss allows retry")
 screen._outcome_retry_button.pressed.emit()
 check(not state.build_locked, "Retry permits build editing before relock")
 screen._skill_build_panel._lock_button.pressed.emit()
 check(state.can_start_current_fight(), "Retry controller returns to fight readiness")
 screen._on_fight_pressed()
 screen.set_process(false)
 screen._on_playback_skip_pressed()
 await outcome(screen)
 check(state.run_outcome == state.RunOutcome.CONTRACT_FAILED, "Second actual loss ends contract")
 check("Test Mode" in screen._next_action_text(), "Terminal header names Test Mode")
 check(not screen._outcome_restart_button.get_global_rect().intersects(screen._fight_button_row.get_global_rect()), "Restart action clears Fight and Log controls")
 await capture("test-terminal-loss")
 screen._outcome_restart_button.pressed.emit()
 await settle()
 fresh(state)
 game._on_main_menu_pressed()
 await settle()
 check(FileAccess.get_file_as_bytes(SaveSystem.save_path) == adventure and FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path) == legacy, "All Test Mode paths preserve saved sentinels")
 # Practice allocation, editing, real playback, retry and scene reopening.
 game._show_training_room()
 await settle()
 var practice = game._current_screen
 var p = practice._state
 var practice_ranks = practice._talent_panel._ranked_view
 check(p.set_talent_budget(0), "Set isolated zero-budget model fixture")
 await settle()
 await press_rank(practice_ranks, "buy:talent.bladedancer.wet_stone")
 check(p.ranked_build.points_spent() == 0 and "No unspent" in practice_ranks.feedback, "Zero Practice budget rejects purchase")
 check(p.set_talent_budget(10), "Set isolated ten-point model fixture")
 await settle()
 await allocate(practice_ranks, p)
 await build_rotation(practice, p)
 practice._on_fight_seed_changed(7)
 practice._on_random_fight_seed_toggled(false)
 practice._on_practice_gold_changed(321)
 await settle()
 var saved_ids := ids(p.rotation)
 var saved_target: String = p.selected_target.display_name
 var combat = practice._combat_view
 combat._instant_playback = false
 combat._skip_playback_on_fight = false
 practice._skill_build_panel._lock_button.pressed.emit()
 practice._fight_button.pressed.emit()
 combat.set_process(false)
 check(p.allocation_locked and practice._fight_button.disabled and p.last_result.is_valid, "Practice controller locks edits and second fight during playback")
 var original = p.last_result
 practice._on_fight_button_pressed()
 check(p.last_result == original, "Second fight cannot replace ongoing playback")
 for speed in [1.0,2.0,4.0]:
  combat._set_speed(speed)
  combat._process(0.2)
 await capture("practice-core-playing")
 combat._skip()
 check(not p.allocation_locked and combat._effect_icons.active.is_empty() and not practice._view_log_button.disabled, "Practice finish unlocks editing and result review")
 var damage: float = p.last_result.total_damage
 combat._skip_playback_on_fight = false
 practice._fight_button.pressed.emit()
 combat.set_process(false)
 check(p.last_result.total_damage == damage and p.gold == 321, "Fixed-seed retry repeats outcome and configured stash")
 combat._process(100.0)
 if p.allocation_locked: await combat.finished
 check(not p.allocation_locked and combat._effect_icons.active.is_empty(), "Natural playback completion clears effects and releases Practice lock")
 practice._skill_build_panel._lock_button.pressed.emit()
 await settle()
 practice._skill_build_panel._slot_buttons[0].pressed.emit()
 practice._skill_build_panel._remove_selected()
 await add_skill(available_panel(practice), "skill.quick_cut")
 saved_ids = ids(p.rotation)
 await settle()
 check(FileAccess.file_exists(p.practice_save_path), "Practice edit autosaved")
 for button in practice.find_children("*", "Button", true, false):
  if button.text == "Save Setup": button.pressed.emit()
 await settle()
 var saved := FileAccess.get_file_as_bytes(p.practice_save_path)
 game._on_main_menu_pressed()
 await settle()
 game._show_training_room()
 await settle()
 practice = game._current_screen
 p = practice._state
 check(p.earned_talent_points == 10 and p.ranked_build.rank_map() == Core.RANKS and ids(p.rotation) == saved_ids, "Reopened Practice restores ranks, duplicates and edited order")
 check(p.configured_gold == 321 and p.fight_seed == 7 and not p.random_fight_seed_enabled and p.selected_target.display_name == saved_target, "Reopened Practice restores gold, seed and target")
 check(not p.allocation_locked and p.last_result == null and not p.has_meta("combat_presentation"), "Reopened Practice has no stale combat state")
 var keyboard_button: Button = available_panel(practice)._skills_box.get_child(0)
 keyboard_button.grab_focus()
 for pressed in [true, false]:
  var action := InputEventAction.new()
  action.action = "ui_accept"
  action.pressed = pressed
  Input.parse_input_event(action)
  await settle()
 check(p.rotation.size() == saved_ids.size() + 1, "Keyboard directly adds a skill in actual Practice scene")
 practice._skill_build_panel._on_slot_pressed(p.rotation.size() - 1)
 practice._skill_build_panel._remove_selected()
 await settle()
 check(ids(p.rotation) == saved_ids, "Remove restores persisted rotation after keyboard add")
 await capture("practice-restored")
 # Reopened state must be immediately fightable after the normal lock action.
 practice._combat_view._instant_playback = false
 practice._skill_build_panel._lock_button.pressed.emit()
 practice._fight_button.pressed.emit()
 practice._combat_view.set_process(false)
 check(p.last_result != null and p.last_result.is_valid, "Reopened Practice can fight again")
 practice._combat_view._skip()
 # A subsequent Test Mode session must also preserve the now-real Practice setup.
 game._on_main_menu_pressed()
 game._on_contract_test_pressed(7, 10)
 await settle()
 fresh(state)
 game._current_screen._autosave()
 game._current_screen._on_abandon_confirmed()
 await settle()
 check(FileAccess.get_file_as_bytes(PracticeSaveSystem.core_save_path) == saved, "Test Mode entry/autosave/abandon preserve saved core Practice")
 check(FileAccess.get_file_as_bytes(SaveSystem.save_path) == adventure and FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path) == legacy, "All journeys preserve Adventure and legacy Practice")
 game.queue_free()
 await settle()
 state.reset()
 CombatEffectIcons.reduced_motion = false
 SaveSystem.write_json(report + ("/visual-checks.json" if visual else "/checks.json"), {"passed": not failed, "count": checks, "evidence": evidence})
 print("T8 core journeys: %d checks %s" % [checks, "FAIL" if failed else "PASS"])
 quit(1 if failed else 0)
