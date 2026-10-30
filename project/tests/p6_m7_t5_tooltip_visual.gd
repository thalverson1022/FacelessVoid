extends SceneTree
var failed := false
var evidence: Array = []
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
func capture(name: String) -> void:
	await settle()
	root.get_texture().get_image().save_png("res://reports/t5_visual/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/t5_visual")
	var state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.shadow","tree.thief")
	await settle()
	var registry := BuildContentRegistry.test_mode()
	var skills: Array[Skill] = []
	for tree in registry.trees.values():
		for unlock in tree.automatic_unlocks:
			if unlock.skill != null: skills.append(unlock.skill)
	for mode in ["test","adventure","practice"]:
		if mode == "practice": game._show_training_room()
		else:
			state.is_test_mode = mode == "test"
			game._show_combat_screen()
		await settle()
		var screen = game._current_screen
		var mode_state = screen._state if mode == "practice" else state
		if mode != "practice":
			screen._contract_overlay.hide()
			screen._map_overlay.hide()
		for width in [1280,1600,1920]:
			root.size = Vector2i(width,width*9/16)
			await settle()
			for text_percent in [100,125]:
				# Construct the exact custom tooltip returned by the live icon button.
				var button := IconTooltipButton.new()
				button.tooltip_icon = GameIcons.icon_for("skill.killers_mark")
				root.add_child(button)
				var skill: Skill = registry.trees["tree.shadow"].automatic_unlocks[1].skill
				var popup: Control = button._make_custom_tooltip(SkillTooltipFormatter.compact_tooltip(skill,mode_state))
				root.add_child(popup)
				popup.position = Vector2(30,110)
				var label: Label = popup.get_child(0).get_child(1)
				label.add_theme_font_size_override("font_size",roundi(22*text_percent/100.0))
				await settle()
				var popup_rect := popup.get_global_rect()
				if popup_rect.end.y > root.size.y or popup_rect.end.x > root.size.x: failed = true
				evidence.append({"mode":mode,"width":width,"text_percent":text_percent,"tooltip_rect":[popup_rect.position.x,popup_rect.position.y,popup_rect.size.x,popup_rect.size.y]})
				await capture("%s-tooltip-%d-%d" % [mode,width,text_percent])
				popup.queue_free()
				button.queue_free()
				await settle()
				var dialog = load("res://scripts/ui/skill_details_dialog.gd").new()
				dialog.state = mode_state
				root.add_child(dialog)
				await settle()
				dialog.inspect(skill,screen._skill_build_panel)
				dialog._text.add_theme_font_size_override("normal_font_size",roundi(20*text_percent/100.0))
				await capture("%s-details-%d-%d" % [mode,width,text_percent])
				dialog._text.scroll_to_line(1000)
				await capture("%s-details-bottom-%d-%d" % [mode,width,text_percent])
				dialog.hide()
				dialog.queue_free()
	SaveSystem.write_json("res://reports/t5_visual/geometry.json",{"cases":evidence})
	game.queue_free()
	await process_frame
	state.reset()
	print("PASS T5 rendered mode, size and text matrix" if not failed else "FAILED T5 tooltip clipping")
	quit(1 if failed else 0)
