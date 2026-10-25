extends SceneTree
## Render actual build-panel controls using the isolated reviewed core fixture.
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var registry := Core.registry()
	var state := TrainingRoomState.new()
	state.set_class(registry.classes["class.rogue"])
	state.ranked_build = Core.build(registry)
	state.selected_trees = state.ranked_build.trees()
	state.earned_talent_points = 10
	var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
	var resolved := BuildResolver.resolve_ranked_build(state.selected_class, state.ranked_build, gear)
	state.rotation = Core.rotation(resolved.skills)
	var background := ColorRect.new()
	background.color = Color("121b25")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_"+side, 16)
	root.add_child(margin)
	var columns := VBoxContainer.new()
	margin.add_child(columns)
	var talents = load("res://scenes/combat/talent_panel.gd").new()
	talents.state = state
	var talent_rows := VBoxContainer.new()
	columns.add_child(talent_rows)
	talents._populate_ranked_tree(state.selected_trees[0], talent_rows)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	for scene in ["available_skills_panel", "skill_build_panel"]:
		var panel = load("res://scenes/combat/"+scene+".tscn").instantiate()
		panel.state = state
		right.add_child(panel)
	var monster := Monster.new()
	monster.hp = 100000
	var result := CombatResolver.resolve(state.rotation, resolved.stats, monster, 20000, 7)
	var effects := CombatEffectIcons.new()
	right.add_child(effects)
	effects.begin(result)
	effects.advance_to(4000)
	var label := Label.new()
	label.text = "Installed examples (talents, buffs and statuses)"
	right.add_child(label)
	var grid := GridContainer.new()
	grid.columns = 3
	right.add_child(grid)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/ui/icon_assignments.json"))
	for id in ["talent.assassin.precision", "buff.precision", "buff.readiness", "talent.gilded_blade", "talent.bladedancer.wet_stone", "talent.thief.finders_keepers", "status.penetration", "status.potency", "skill.big_score"]:
		assert(GameIcons.icon_for(id) != null, id)
		grid.add_child(CardStyle.make_icon_label_row(GameIcons.icon_for(id), manifest.entries[id].name, Vector2(32,32)))
	for dimensions in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080)]:
		root.size = dimensions
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reports/icon_integration/game-icons-%d.png" % dimensions.x)
	print("Rendered actual talent, skill, rotation and effect controls at three sizes.")
	talents.free()
	margin.queue_free()
	background.queue_free()
	await process_frame
	quit()
