extends SceneTree
## Headless check for the user-requested rotation/macro cap (10 skills,
## shared between Adventure and Practice Room via BuildResolver.
## resolve_rotation(), the one chokepoint both BuildState.set_rotation() and
## TrainingRoomState.set_rotation() already route through). Run with:
##   godot --headless -s res://tests/rotation_cap_test.gd


func _initialize() -> void:
	_check_pure_resolver_cap()
	await _check_training_room_ui_cap()
	print("")
	print("Rotation cap check: OK")
	quit()


func _check_pure_resolver_cap() -> void:
	print("-- BuildResolver.resolve_rotation() caps at MAX_ROTATION_SIZE --")
	var stab: Skill = load("res://data/skills/stab.tres")
	var requested: Array[Skill] = []
	for i in 15:
		requested.append(stab)
	var unlocked: Array[Skill] = [stab]
	var resolved := BuildResolver.resolve_rotation(requested, unlocked)
	print("resolved size for 15 requested (expect %d): %d" % [BuildResolver.MAX_ROTATION_SIZE, resolved.size()])
	assert(resolved.size() == BuildResolver.MAX_ROTATION_SIZE)


func _check_training_room_ui_cap() -> void:
	print("-- Practice Room: full macro refuses further additions; hover remains available --")
	var game_root_scene: PackedScene = load("res://scenes/game_root.tscn")
	var game_root = game_root_scene.instantiate()
	root.add_child(game_root)
	await process_frame

	var title = game_root._current_screen
	title.training_room_pressed.emit()
	await process_frame
	var training_room = game_root._current_screen

	var stab: Skill = null
	for skill in training_room._state.unlocked_skills():
		if skill.id == "skill.stab":
			stab = skill
	assert(stab != null)

	var available_skills_panel = training_room.find_child("AvailableSkillsPanel", true, false)
	var skill_build_panel = training_room.find_child("SkillBuildPanel", true, false)
	assert(skill_build_panel != null)
	for i in BuildResolver.MAX_ROTATION_SIZE:
		available_skills_panel._on_skill_pressed(stab)
	await process_frame
	print("rotation size after %d presses (expect %d): %d" % [
		BuildResolver.MAX_ROTATION_SIZE, BuildResolver.MAX_ROTATION_SIZE, training_room._state.rotation.size()
	])
	assert(training_room._state.rotation.size() == BuildResolver.MAX_ROTATION_SIZE)
	assert(skill_build_panel._slot_count_label.text == "Slots: 10/10")

	# Further presses cannot grow the rotation. Icons remain enabled for
	# inspection in the accepted compact interaction design.
	available_skills_panel._on_skill_pressed(stab)
	await process_frame
	print("rotation size after one more press past cap (expect still %d): %d" % [
		BuildResolver.MAX_ROTATION_SIZE, training_room._state.rotation.size()
	])
	assert(training_room._state.rotation.size() == BuildResolver.MAX_ROTATION_SIZE)
	for child in available_skills_panel._skills_box.get_children():
		if child is Button:
			assert(not child.disabled)
			child.pressed.emit()
			assert(training_room._state.rotation.size() == BuildResolver.MAX_ROTATION_SIZE)
			assert(not child._get_tooltip(Vector2.ZERO).is_empty())
	game_root.queue_free()
	await process_frame
