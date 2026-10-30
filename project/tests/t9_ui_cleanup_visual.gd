extends SceneTree
## Actual dashboard and Practice surfaces; run only in disposable validation copies.
const OUT := "res://reports/t9_ui_cleanup"
const IDS := ["footwork", "readiness", "precision", "dance", "meditation", "dash", "bypass", "virulent_poison", "master_of_poisons", "touch.1", "beguiling_presence", "greed"]
var checks := 0
func _initialize() -> void: call_deferred("run")
func ck(value: bool, message: String) -> void:
	assert(value, message)
	checks += 1
func settle() -> void:
	for i in 5: await process_frame
func shot(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "/" + name + ".png")
func fixture(count: int):
	var result := CombatResolver.CombatResult.new()
	result.duration_ms = 20000
	for i in count:
		result.trace.record("effect_lifecycle", 0, {"effect_instance_id":"ui%d" % i}, {"effect_id":IDS[i],"after":{"units":3,"cap":20,"expires_at_ms":10000}})
	return result
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.bladedancer","tree.thief")
	await settle()
	var state = root.get_node("BuildState")
	for mode in ["adventure","practice"]:
		if mode == "practice": game._show_training_room()
		else:
			state.is_test_mode = false
			game._show_combat_screen()
		await settle()
		var screen = game._current_screen
		if mode == "adventure":
			if screen._story_overlay.visible: screen._story_overlay._on_proceed_pressed()
			screen._contract_overlay.hide()
			screen._map_overlay.hide()
		var icons = screen._combat_view._effect_icons if mode == "practice" else screen._effect_icons
		for count in [5,12]:
			icons.begin(fixture(count))
			icons.advance_to(1500)
			await settle()
			ck(icons._chips.size() == count, "Every buff remains visible")
			var bounds: Rect2 = icons.get_global_rect()
			ck(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(bounds), "Wrapped icons fit viewport")
			var last: Control = icons._grid.get_child(count-1)
			ck(bounds.encloses(last.get_global_rect()), "Last buff fits panel")
			await shot(mode + "_buffs_" + str(count))
		icons.clear()
		if mode == "adventure":
			var panel = screen.find_child("CharacterStatsPanel",true,false)
			ck(panel._stats_label.text.contains("Crits Apply Potency:"), "Canonical new stat labels")
			ck(not panel._stats_label.text.contains(".0000%"), "Stat precision matches existing rows")
			await shot("character_stats")
			var item := GearItem.new()
			item.display_name = "Tooltip formatting fixture"
			item.slot = GearItem.SlotType.CHARM
			for id in ["cooldown_reduction","increased_buff_duration","crit_applies_penetration","crit_applies_potency"]:
				var mod := StatModifier.new()
				mod.stat_id = id
				mod.value = 0.15
				item.affixes.append(mod)
			var body := "\n".join(CardStyle.gear_tooltip_lines(item))
			for label in ["+15% Cooldown Reduction","+15% Increased Buff Duration","+15% Crits Apply Penetration","+15% Crits Apply Potency"]:
				ck(body.contains(label), "Short affix: " + label)
			ck(not body.contains("per-affix") and not body.contains("contribution"), "No internal math in item hover")
			var layer := CanvasLayer.new()
			layer.layer = 200
			screen.add_child(layer)
			var tip := CardStyle.build_gear_tooltip(screen,item)
			layer.add_child(tip)
			tip.position = Vector2(380,80)
			await shot("new_stat_affixes")
			layer.queue_free()
	game.queue_free()
	await settle()
	print("PASS T9 UI cleanup checks=",checks," screenshots=6")
	call_deferred("quit")
