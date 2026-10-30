extends SceneTree
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")
var failed := false
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
 if not ok:
  failed = true
  printerr("FAILED: " + label)
func settle() -> void:
 await process_frame
 await process_frame
func right_click(button: Button) -> void:
 var event := InputEventMouseButton.new()
 event.button_index = MOUSE_BUTTON_RIGHT
 event.pressed = true
 button.gui_input.emit(event)
func _run() -> void:
 var game = load("res://scenes/game_root.tscn").instantiate()
 root.add_child(game)
 await settle()
 game._on_contract_test_pressed(7, 10)
 await settle()
 var state = root.get_node("BuildState")
 var registry := BuildContentRegistry.test_mode()
 for id in Core.RANKS:
  for rank in Core.RANKS[id]: state.select_talent(registry.talents[id])
 await exercise(state)
 game._on_main_menu_pressed()
 game._show_training_room()
 await settle()
 var practice = game._current_screen._state
 for id in Core.RANKS:
  for rank in Core.RANKS[id]: practice.select_talent(registry.talents[id])
 await exercise(practice)
 game.queue_free()
 await settle()
 state.reset()
 print("Compact skill UI: " + ("FAIL" if failed else "PASS"))
 quit(1 if failed else 0)
func exercise(state) -> void:
 var available = load("res://scenes/combat/available_skills_panel.gd").new()
 var macro = load("res://scenes/combat/skill_build_panel.gd").new()
 available.state = state
 macro.state = state
 root.add_child(available)
 root.add_child(macro)
 await settle()
 check(available.find_children("*", "AcceptDialog", true, false).is_empty() and macro.find_children("*", "AcceptDialog", true, false).is_empty(), "No skill detail dialog")
 check(macro.find_children("*", "HFlowContainer", true, false).is_empty(), "No bottom action row")
 var button: Button = available._skills_box.get_child(1)
 button.pressed.emit()
 button.pressed.emit()
 await settle()
 check(state.rotation.size() == 2 and state.rotation[0].id == state.rotation[1].id, "Click immediately adds and permits duplicates")
 check(button.text.is_empty(), "Available skill is icon only")
 var tooltip: String = button._get_tooltip(Vector2.ZERO)
 check(tooltip.contains("Stab") and tooltip.contains("Attack [Normal]") and tooltip.contains(" damage") and not tooltip.contains("Cast:"), "Skill hover has name, qualitative cast and current damage in all modes")
 var original_gear = state.equipped_weapon
 state.equipped_weapon = load("res://data/gear/crude_dagger.tres") if original_gear != null else load("res://data/gear/bandit_blade.tres")
 check(button._get_tooltip(Vector2.ZERO) != tooltip, "Tooltip resolves changed gear at hover time")
 state.equipped_weapon = original_gear
 macro._slot_buttons[0].pressed.emit()
 check(state.rotation.size() == 2, "Left click does not remove")
 right_click(macro._slot_buttons[0])
 await settle()
 check(state.rotation.size() == 1, "Right click removes exactly one copy")
 state.set_locked(true)
 button.pressed.emit()
 right_click(macro._slot_buttons[0])
 check(state.rotation.size() == 1, "Manual lock blocks add and removal")
 state.set_locked(false)
 macro.set_combat_interaction_locked(true)
 right_click(macro._slot_buttons[0])
 check(state.rotation.size() == 1, "Playback blocks removal")
 macro.set_combat_interaction_locked(false)
 var rotation: Array[Skill] = []
 for i in 10: rotation.append(state.unlocked_skills()[1])
 state.set_rotation(rotation)
 button.pressed.emit()
 check(state.rotation.size() == 10 and macro._slots_box.columns == 10, "Ten-slot cap and compact row")
 rotation.clear()
 state.set_rotation(rotation)
 await settle()
 check(macro._lock_button.disabled, "Empty rotation cannot lock")
 button.grab_focus()
 for pressed in [true, false]:
  var event := InputEventAction.new()
  event.action = "ui_accept"
  event.pressed = pressed
  Input.parse_input_event(event)
  await settle()
 check(state.rotation.size() == 1, "Keyboard activation also adds")
 rotation.clear()
 state.set_rotation(rotation)
 available.queue_free()
 macro.queue_free()
 await settle()
