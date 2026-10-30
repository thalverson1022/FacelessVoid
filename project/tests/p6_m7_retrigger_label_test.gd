extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + message)
func echoes(layer) -> Array:
	return layer.get_children().filter(func(n): return n.has_meta("retrigger_hit") and not n.is_queued_for_deletion())
func run() -> void:
	var layer := CombatPopupLayer.new()
	layer.size = Vector2(1000,600)
	root.add_child(layer)
	var practice := TrainingRoomCombatView.new()
	root.add_child(practice)
	await process_frame
	practice.set_process(false)
	practice._instant_playback = false
	var event := CombatPlayback.PlaybackEvent.new()
	event.cast = CombatResolver.CastEvent.new()
	event.cast.skill = load("res://data/skills/stab.tres")
	event.cast.physical_damage = 17.4
	event.cast.triggered_skill_names = ["Extra proc"]
	event.chain_count = 200
	event.chain_index = 2
	event.visual_beat = true
	for mode in ["shared","practice"]:
		var owner = layer if mode == "shared" else practice._popup_layer
		var label: Label = layer.spawn_retrigger(event.cast,2) if mode == "shared" else practice._spawn_retrigger_popup(event)
		check(label.text == ("Stab -17" if mode == "shared" else "Stab 17.4"), mode + ": actual damage convention")
		check(label.get_theme_font_size("font_size") == (39 if mode == "shared" else 27),mode + ": 75 percent normal size")
		check(is_equal_approx(label.modulate.a,0.65) and label.get_theme_color("font_color").a == 1.0,mode + ": opacity applied once")
		check(label.scale == Vector2.ONE and label.get_theme_constant("outline_size") == 2,mode + ": no punch and subtle outline")
		for i in 200:
			if mode == "shared": layer.spawn_retrigger(event.cast,i)
			else:
				event.chain_index = i
				practice._spawn_retrigger_popup(event)
		check(echoes(owner).size() == 2, mode + ": global live cap despite large delta burst")
		event.cast.is_crit = true
		event.cast.crit_negation_damage_prevented = 100
		event.cast.gold_stolen = 3
		label = layer.spawn_retrigger(event.cast,2) if mode == "shared" else practice._spawn_retrigger_popup(event)
		check(label.text.contains("17") and not label.text.contains("117") and label.text.contains("+3 gold"),mode + ": actual negated crit plus actual gold in one label")
		check(label.get_theme_font_size("font_size") == (51 if mode == "shared" else 36),mode + ": subordinate critical size")
		event.cast.was_dodged = true
		label = layer.spawn_retrigger(event.cast,2) if mode == "shared" else practice._spawn_retrigger_popup(event)
		check(label.text.contains("0.0 dodged") and not label.text.contains("17"),mode + ": dodge cannot display damage")
		event.cast.was_dodged = false
		event.cast.was_interrupted = true
		event.cast.interrupt_skipped = true
		label = layer.spawn_retrigger(event.cast,2) if mode == "shared" else practice._spawn_retrigger_popup(event)
		check(label.text.contains("skipped") and not label.text.contains("17"),mode + ": interruption cannot display damage")
		event.cast.resource_unavailable = true
		label = layer.spawn_retrigger(event.cast,2) if mode == "shared" else practice._spawn_retrigger_popup(event)
		check(label == null,mode + ": unavailable attempt retains no-hit convention")
		event.cast.resource_unavailable = false
		event.cast.was_interrupted = false
		event.cast.is_crit = false
		event.cast.gold_stolen = 0
		event.cast.crit_negation_damage_prevented = 0
		await create_timer(0.3).timeout
		check(echoes(owner).is_empty(),mode + ": short lifetime retires every echo")
	# Verify event gating independently from the popup factory.
	var presenter := CombatPlaybackPresenter.new()
	root.add_child(presenter)
	presenter.set_popup_layer(layer)
	presenter._monster = Monster.new()
	presenter._playback = CombatPlayback.new()
	presenter._hp = 1000
	practice._monster = Monster.new()
	practice._playback = CombatPlayback.new()
	event.chain_index = 2
	event.visual_beat = false
	presenter._on_event(event)
	practice._on_playback_event(event)
	check(echoes(layer).is_empty() and echoes(practice._popup_layer).is_empty(),"Suppressed logical beats never emit labels")
	event.visual_beat = true
	presenter._on_event(event)
	practice._on_playback_event(event)
	check(echoes(layer).size() == 1 and echoes(practice._popup_layer).size() == 1,"Visible followups emit one label without triggered proc spam")
	presenter.skip()
	practice._skip()
	check(not echoes(layer)[0].visible if not echoes(layer).is_empty() else true,"Shared skip hides active echo")
	await process_frame
	check(echoes(layer).is_empty() and echoes(practice._popup_layer).is_empty(),"Skip removes all compact labels")
	CombatEffectIcons.reduced_motion = true
	presenter._on_event(event)
	practice._on_playback_event(event)
	check(echoes(layer).is_empty() and echoes(practice._popup_layer).is_empty(),"Reduced motion follows existing popup suppression")
	CombatEffectIcons.reduced_motion = false
	presenter.queue_free()
	practice.queue_free()
	layer.queue_free()
	print("Retrigger label PASS" if not failed else "Retrigger label FAILED")
	quit(1 if failed else 0)

