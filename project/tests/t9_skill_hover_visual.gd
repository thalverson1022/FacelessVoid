extends SceneTree
## T9: production Practice macro button -> actual engine SkillHover popup.
const OUT := "res://reports/t9_skill_hover"
var cases: Array = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	assert(value, message)
	checks += 1

func settle() -> void:
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw

func hover_panel(node: Node) -> Control:
	if node.name == "SkillHover": return node
	for child in node.get_children(true):
		var found := hover_panel(child)
		if found != null: return found
	return null

func pointer(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	root.push_input(motion, true)

func capture(button: IconTooltipButton, name: String, expected: String) -> void:
	pointer(Vector2(800, 50))
	await create_timer(0.2).timeout
	pointer(button.get_global_rect().get_center())
	await create_timer(0.85).timeout
	check(root.gui_get_hovered_control() == button, name + " actual macro button hovered")
	var panel := hover_panel(root)
	check(panel != null, name + " actual engine tooltip visible")
	check(panel.find_child("SkillHoverEffect", true, false).get_parsed_text().contains(expected), name + " actual rendered state-aware effect")
	await settle()
	check(panel.get_theme_stylebox("panel") == button.get_theme_stylebox("panel", "TooltipPanel"), name + " accepted M7 item tooltip background")
	check(panel.find_child("SkillHoverName", true, false).get_theme_font_size("font_size") == 22, name + " accepted M7 name typography")
	check(panel.find_child("SkillHoverCategory", true, false).get_theme_font_size("font_size") == 18, name + " accepted M7 category typography")
	var window := panel.get_window()
	# Embedded windows use the stretched logical 1600x900 viewport coordinates.
	# The physical screenshot remains 1280x720 under the isolated runner.
	var bounds := root.get_visible_rect()
	var popup_rect := Rect2(Vector2(window.position), Vector2(window.size))
	check(bounds.encloses(popup_rect), name + " popup fits actual logical viewport")
	print("HOVER GEOMETRY ", name, " popup=", popup_rect, " viewport=", bounds)
	await settle()
	var screenshot := root.get_texture().get_image()
	check(screenshot.get_width() == 1280 and screenshot.get_height() == 720, name + " actual 1280x720 screenshot")
	screenshot.save_png(OUT + "/" + name + ".png")
	cases.append({"name":name,"window_position":[window.position.x,window.position.y],"window_size":[window.size.x,window.size.y],"logical_viewport":[bounds.size.x,bounds.size.y],"screenshot_size":[screenshot.get_width(),screenshot.get_height()],"text":button._get_tooltip(Vector2.ZERO)})

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	DirAccess.make_dir_recursive_absolute("res://prototype_saves/t9_skill_hover")
	SaveSystem.save_path = "res://prototype_saves/t9_skill_hover/adventure.json"
	PracticeSaveSystem.core_save_path = "res://prototype_saves/t9_skill_hover/practice.json"
	root.size = Vector2i(1280,720)
	print("ROOT COORDINATES visible=", root.get_visible_rect(), " content_scale_size=", root.content_scale_size, " screen_transform=", root.get_screen_transform())
	var adventure = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	adventure.set_class(load("res://data/classes/rogue.tres"))
	adventure.gold = 631
	var before := JSON.stringify(SaveSystem._serialize(adventure))
	game._current_screen.training_room_pressed.emit()
	await settle()
	var room = game._current_screen
	var state: TrainingRoomState = room._state
	state.set_locked(false)
	var registry := BuildContentRegistry.test_mode()
	state.set_primary_tree(registry.trees["tree.assassin"])
	state.set_secondary_tree(registry.trees["tree.shadow"])
	var ranks := {"talent.assassin.quick_hands":5,"talent.assassin.precision":5,"talent.assassin.hastened_poison":2,"talent.shadow.blind_spot":5,"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.deception":2}
	check(state.ranked_build.configure(registry.trees["tree.assassin"],registry.trees["tree.shadow"],45,ranks), "Legal Practice skill fixture")
	state._finish_rank_edit(true)
	var fixtures := [
		{"name":"exsanguinate_nightkiss","id":"skill.exsanguinate","gear":["nightkiss_kitana"],"expected":"health per stack"},
		{"name":"poison_strike_decrepit","id":"skill.poison_strike","gear":["decrepit_blade","serpents_coil"],"expected":"Consume all Poison stacks"},
		{"name":"virulent_crown","id":"skill.virulent_poison","gear":["crown_of_concertation"],"expected":"3x damage"},
		{"name":"death_strike_umbral","id":"skill.killers_mark","gear":["umbral_stiletto"],"expected":"per Decay stack"},
		{"name":"beguiling_signet","id":"skill.beguiling_presence","gear":["signet_of_the_old_kings"],"expected":"+3% Attack Speed"},
		{"name":"parry_readiness","id":"skill.parry_strike","gear":[],"expected":"Requires and consumes Readiness."},
	]
	for fixture in fixtures:
		pointer(Vector2(800,50))
		await create_timer(0.2).timeout
		if fixture.id == "skill.parry_strike":
			check(state.ranked_build.configure(registry.trees["tree.bladedancer"],null,45,{"talent.bladedancer.wet_stone":4,"talent.bladedancer.rending_slash":1,"talent.bladedancer.fancy_footwork":5}), "Legal Parry Practice fixture")
			state._finish_rank_edit(true)
		for property in ["equipped_weapon","equipped_helm","equipped_armor","equipped_charm","equipped_trinket"]: state.set(property,null)
		for name in fixture.gear: state.equip_legendary(load("res://data/gear/%s.tres" % name))
		var skill: Skill = null
		for unlocked in state.unlocked_skills():
			if unlocked.id == fixture.id: skill = unlocked
		check(skill != null, fixture.name + " actual resolved skill unlocked")
		var rotation: Array[Skill] = [skill]
		state.set_rotation(rotation)
		await settle()
		var button: IconTooltipButton = room._skill_build_panel._slot_buttons[0]
		check(button.skill_hover_provider.is_valid() and button.skill_hover_provider.call().id == fixture.id, fixture.name + " actual macro provider")
		await capture(button, fixture.name, fixture.expected)
	check(JSON.stringify(SaveSystem._serialize(adventure)) == before, "Practice tooltip inspection preserves Adventure state")
	SaveSystem.write_json(OUT + "/geometry.json", {"cases":cases,"checks":checks})
	game.queue_free()
	await process_frame
	print("PASS T9 actual skill hover renders: ", cases.size(), "; checks: ", checks)
	quit()
