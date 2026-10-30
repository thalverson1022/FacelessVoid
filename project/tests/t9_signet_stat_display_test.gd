extends SceneTree
const Live = preload("res://scripts/systems/legendary_live_stats.gd")
const Model = preload("res://scripts/ui/combat_presentation_state.gd")
const SelfBuffs = preload("res://scripts/systems/combat_self_buffs.gd")
var checks := 0

class Context extends RefCounted:
	signal build_changed
	var selected_class: ClassDef = load("res://data/classes/rogue.tres")
	var stats := PlayerStats.new()
	var gold := 10
	var combat_stolen_gold := 0
	func current_player_stats() -> PlayerStats: return stats

func _initialize() -> void: call_deferred("run")
func ck(ok: bool, message: String) -> void:
	assert(ok, message)
	checks += 1
func text(panel) -> String: return panel._stats_label.get_parsed_text()
func snapshot(state: TrainingRoomState) -> String:
	return JSON.stringify({"build":BuildSaveCodec.encode(state,BuildContentRegistry.test_mode()),"gear":SaveSystem._gear_list_to_data(state.equipped_gear()),"gold":state.gold})
func rendered(panel, expected: PlayerStats) -> void:
	ck(text(panel).contains("Crit Chance: 0%") and text(panel).contains("Crit Damage: 0%"), "Signet displays zero critical outputs")
	ck(text(panel).contains("Attack Speed: %.0f%%" % (expected.attack_speed * 100)), "display uses resolved converted IAS")
	ck(text(panel).contains("Physical Damage Increase: %+.0f%%" % ((expected.physical_damage_multiplier - 1) * 100)), "display uses resolved converted physical increase")
func settle() -> void:
	for i in 3: await process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
func run() -> void:
	var panel = load("res://scenes/combat/character_stats_panel.gd").new()
	var practice := TrainingRoomState.new()
	practice.set_class(load("res://data/classes/rogue.tres"))
	practice.equip_legendary(load("res://data/gear/signet_of_the_old_kings.tres"))
	practice.equip_legendary(load("res://data/gear/mysterious_lucky_coin.tres"))
	panel.state = practice
	panel.theme = load("res://assets/ui_theme.tres")
	panel.position = Vector2(30,30)
	panel.custom_minimum_size.x = 400
	root.add_child(panel)
	await settle()
	rendered(panel, practice.current_player_stats())
	ck(text(panel).contains("Attack Speed: 188%"), "real equipped Signet and Coin convert uncapped 125percent")
	var saved := snapshot(practice)
	for i in 3: panel._refresh()
	ck(saved == snapshot(practice), "rendering leaves actual Practice build unchanged")
	practice.equip_legendary(load("res://data/gear/lolzorzs_locket.tres"))
	await settle()
	ck(not text(panel).contains("Crit Damage: 0%"), "unequipping Signet restores ordinary critical display")
	var context := Context.new()
	context.stats.legendary_signet = true
	context.stats.crit_chance = 1.5
	context.stats.crit_multiplier = 2.5
	context.stats.crit_multiplier_per_current_gold = 0.002
	context.stats.crit_chance_per_stolen_gold = 0.01
	context.stats.attack_speed = 0.2
	context.stats.physical_damage_multiplier = 1.1
	panel.state = context
	panel._refresh()
	rendered(panel, Live.resolve(context.stats,10,0))
	var original := [context.stats.crit_chance,context.stats.crit_multiplier,context.stats.attack_speed,context.stats.physical_damage_multiplier,context.stats.legendary_added_ias,context.stats.legendary_added_physical]
	var result := CombatResolver.CombatResult.new()
	result.presentation_initial = {"stash":10}
	var buffs := SelfBuffs.new(result.trace)
	buffs.grant("beguiling_presence",100,{"source_id":"skill.beguiling_presence"},4,4)
	buffs.advance(10100)
	var model := Model.new()
	model.begin(result)
	context.set_meta("combat_presentation", model)
	model.advance_to(100)
	await settle()
	rendered(panel, Live.resolve(context.stats,10,0,{"crit_chance":0.08}))
	ck(text(panel).contains("Attack Speed: 257%"), "recorded temporary Crit Chance buff updates IAS live")
	model.stash = 20
	model.stolen = 10
	await settle()
	rendered(panel, Live.resolve(context.stats,20,10,{"crit_chance":0.08}))
	model.advance_to(10100)
	await settle()
	rendered(panel, Live.resolve(context.stats,20,10))
	ck(text(panel).contains("Attack Speed: 260%"), "expiry removes only temporary conversion contribution")
	context.remove_meta("combat_presentation")
	await settle()
	rendered(panel, Live.resolve(context.stats,10,0))
	ck(original == [context.stats.crit_chance,context.stats.crit_multiplier,context.stats.attack_speed,context.stats.physical_damage_multiplier,context.stats.legendary_added_ias,context.stats.legendary_added_physical] and context.gold == 10 and context.combat_stolen_gold == 0, "replay display never changes raw stats or stash")
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute("res://reports/t9_tooltip_revision")
		root.get_texture().get_image().save_png("res://reports/t9_tooltip_revision/signet_stats.png")
	panel.queue_free()
	await process_frame
	await teardown()
	print("PASS Signet stat display checks=",checks)
	quit()

func teardown() -> void:
	SaveSystem.save_path = "res://prototype_saves/signet_teardown.json"
	var state = root.get_node("BuildState")
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	state.equipped_charm = load("res://data/gear/signet_of_the_old_kings.tres")
	state.gold = 10
	var screen = load("res://scenes/combat/combat_screen.tscn").instantiate()
	root.add_child(screen)
	await settle()
	var result := CombatResolver.CombatResult.new()
	result.duration_ms = 20000
	result.presentation_initial = {"stash":9000}
	var buffs := SelfBuffs.new(result.trace)
	buffs.grant("beguiling_presence",0,{"source_id":"skill.beguiling_presence"},4,4)
	var target := Monster.new()
	target.hp = 1000
	screen._playback_presenter.start(result,target,false,false,false)
	ck(state.has_meta("combat_presentation") and state.get_meta("combat_presentation").running,"actual Adventure presenter registers running replay")
	screen.queue_free()
	await settle()
	ck(not state.has_meta("combat_presentation"),"leaving Adventure clears abandoned combat metadata")
	var replacement = load("res://scenes/combat/character_stats_panel.gd").new()
	replacement.state = state
	root.add_child(replacement)
	await settle()
	rendered(replacement,state.current_player_stats())
	replacement.queue_free()
	var practice := TrainingRoomState.new()
	practice.set_class(load("res://data/classes/rogue.tres"))
	var macro = load("res://scenes/combat/skill_build_panel.tscn").instantiate()
	macro.state = practice
	root.add_child(macro)
	var view := TrainingRoomCombatView.new()
	view.skill_build_panel = macro
	view._instant_playback = false
	root.add_child(view)
	await settle()
	var empty_gear: Array[GearItem] = []
	view.play(result,target,empty_gear,10)
	ck(practice.has_meta("combat_presentation"),"actual Practice view registers replay")
	view.queue_free()
	await settle()
	ck(not practice.has_meta("combat_presentation"),"leaving Practice clears abandoned combat metadata")
	# An old presenter must not clear a newer presentation on the same state.
	var old := CombatPlaybackPresenter.new()
	root.add_child(old)
	old._presentation_owner = state
	old._owned_presentation_model = Model.new()
	var newer := Model.new()
	state.set_meta("combat_presentation",newer)
	old.queue_free()
	await settle()
	ck(state.has_meta("combat_presentation") and state.get_meta("combat_presentation") == newer,"old teardown preserves newer replay ownership")
	state.remove_meta("combat_presentation")
	macro.queue_free()
	await process_frame
