extends SceneTree
const State = preload("res://scripts/ui/combat_presentation_state.gd")
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + message)
func fixture(count: int):
	var result := CombatResolver.CombatResult.new()
	result.duration_ms = 1000
	for i in count:
		var cast := CombatResolver.CastEvent.new()
		cast.skill = load("res://data/skills/stab.tres")
		cast.time_ms = 500
		cast.cast_start_ms = 0 if i == 0 else 500
		cast.cast_id = i + 1
		cast.root_cast_id = 1
		cast.parent_cast_id = i
		cast.origin_kind = "macro" if i == 0 else "random_repeat"
		cast.physical_damage = i + 1
		cast.sequence = result.trace.record("cast_resolved",500,{"cast_id": i + 1,"root_cast_id":1},{"damage":cast.physical_damage,"status_after":{"poison":i}})
		result.cast_events.append(cast)
		result.total_damage += cast.physical_damage
	return result
func run() -> void:
	for count in [2,4,8,16,17,200]:
		var result = fixture(count)
		var playback := CombatPlayback.new()
		var seen: Array = []
		var contacts: Array = []
		playback.event_callback = func(event):
			seen.append(event.cast.cast_id)
			if event.visual_beat: contacts.append(event.presentation_ms)
		playback.start(result)
		playback.advance(0.5)
		check(seen.size() == 1, "Opening hit is discrete")
		playback.advance(0.259)
		check(seen.size() == 1 and playback.elapsed_ms() == 500, "260ms opening pause freezes combat countdown")
		playback.advance(0.0011)
		check(seen.size() == 2, "First repeat at 260ms")
		playback.advance(4.5)
		check(playback.is_finished() and seen.size() == count, "Bounded schedule retains every state callback")
		check(contacts.size() == mini(count,16) and contacts[-1] - contacts[0] <= 2920, "Up to sixteen distinct animated/audio beats and 2920ms per root")
		check(is_equal_approx(playback.damage_dealt(), result.total_damage), "No manufactured finishing damage")
		for i in count: check(seen[i] == i + 1,"Original event order")
	var deadline = fixture(17)
	deadline.duration_ms = 500
	var last_beat := CombatPlayback.new()
	last_beat.start(deadline)
	last_beat.advance(3.421)
	check(last_beat.events_fired() == 17 and not last_beat.is_finished(),"Deadline final hit has a rendered finishing dwell")
	last_beat.advance(0.26)
	check(last_beat.is_finished(),"Deadline dwell is bounded at 260ms")
	# Exact timestamp frontier must hold later impacts and post-subtree grants.
	var tied = fixture(3)
	tied.trace.presentation_records.insert(0,{"sequence":0,"time_ms":0,"kind":"effect_lifecycle","effect_instance_id":"f","payload":{"effect_id":"footwork","after":{"units":3,"expires_at_ms":500}}})
	tied.trace.presentation_records.append({"sequence":100,"time_ms":500,"kind":"effect_lifecycle","effect_instance_id":"g","payload":{"effect_id":"readiness","after":{"units":1,"expires_at_ms":-1}}})
	var replay = State.new()
	replay.begin(tied)
	replay.advance_to(500,tied.cast_events[0].sequence)
	check(replay.units("buff.footwork") == 3 and replay.units("buff.readiness") == 0 and replay.statuses.poison == 0,"Equal deadline and later grants held behind frontier")
	replay.advance_to(500)
	check(replay.units("buff.footwork") == 0 and replay.units("buff.readiness") == 1 and replay.statuses.poison == 2,"Completed timestamp applies remaining records then expires")
	# Real recursive repeats + forced and natural poison ticks, trace on/off parity.
	var stats := PlayerStats.new()
	stats.weapon_damage_min = 100
	stats.weapon_damage_max = 100
	stats.retrigger_chance = 1.0
	stats.poison_damage_per_tick = 10
	stats.readiness_enabled = true
	var enemy := Monster.new()
	enemy.hp = 1000000
	var rotation: Array[Skill] = [load("res://data/skills/venom_jab.tres"), preload("res://scripts/systems/p6_poison_contracts.gd").poison_strike()]
	var result := CombatResolver.resolve(rotation,stats,enemy,4000,7,true)
	var off := CombatResolver.resolve(rotation,stats,enemy,4000,7,false)
	check(result.is_valid and result.cast_events.size() > 20 and result.tick_events.size() > 4,"Actual resolver dense recursive fixture with forced ticks")
	check(result.total_damage == off.total_damage and result.rng_final_state == off.rng_final_state,"Trace parity")
	var opening := CombatPlayback.new()
	opening.start(result)
	opening.advance(float(result.cast_events[0].time_ms)/1000.0)
	var held_grants = State.new()
	held_grants.begin(result)
	held_grants.advance_to(int(opening.elapsed_ms()),opening.record_frontier())
	check(held_grants.units("buff.readiness") == 0,"Actual resolver post-subtree Readiness grant stays hidden during opening contact")
	var original := JSON.stringify(result.trace.presentation_records)
	var playback := CombatPlayback.new()
	var model = State.new()
	model.begin(result)
	var ordered: Array = []
	playback.event_callback = func(event):
		model.advance_to(event.time_ms,event.sequence)
		ordered.append(event.sequence)
		check(model.time_ms == event.time_ms,"Effects synchronized at each contact")
		if event.is_tick:
			check(int(model.statuses.get("poison",0)) == event.tick.stacks_remaining,"Forced/natural depletion appears at its exact presented tick")
		elif event.cast.status_snapshot.has("poison"):
			check(model.statuses.poison == event.cast.status_snapshot.poison,"Actual cast status snapshot matches presented contact")
	playback.start(result)
	while not playback.is_finished():
		playback.advance(0.017)
		model.advance_to(int(playback.elapsed_ms()),playback.record_frontier())
	check(ordered.size() == result.cast_events.size() + result.tick_events.size(),"All actual cast/tick callbacks")
	for i in range(1,ordered.size()): check(ordered[i] > ordered[i-1],"Actual resolver sequence preserved including forced ticks")
	check(is_equal_approx(playback.damage_dealt(), result.total_damage),"Actual complete damage parity")
	check(JSON.stringify(result.trace.presentation_records) == original and result.rng_final_state == off.rng_final_state,"Playback leaves resolver records and RNG unchanged")
	# Actual post-subtree grants survive the last echo recovery. The next
	# macro's Footwork/Readiness consumption waits for its visible windup.
	var core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")
	var registry = core.registry()
	var built = BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],core.build(registry),[load("res://data/gear/crude_dagger.tres")])
	var quick: Skill
	for skill in built.skills:
		if skill.id == "skill.quick_cut": quick = skill
	for consumer_id in ["skill.leaping_plunge","skill.parry_strike"]:
		var consumer: Skill
		for skill in built.skills:
			if skill.id == consumer_id: consumer = skill
		var consumer_stats: PlayerStats = built.stats.duplicate()
		consumer_stats.retrigger_chance = 1.0
		var consuming := CombatResolver.resolve([quick,consumer],consumer_stats,enemy,5000,7,true)
		var macros: Array = consuming.cast_events.filter(func(cast): return cast.origin_kind == "macro")
		check(consuming.is_valid and macros.size() >= 2,"Actual immediate next-macro fixture")
		var scheduled := CombatPlayback.new()
		var consumer_state = State.new()
		consumer_state.begin(consuming)
		scheduled.start(consuming)
		var last_contact := 0.0
		for event in scheduled._events:
			if event.root_id == macros[0].root_cast_id: last_contact = maxf(last_contact,event.presentation_ms)
		scheduled.advance((last_contact+0.001)/1000.0)
		consumer_state.advance_to(int(scheduled.elapsed_ms()),scheduled.record_frontier())
		var buff := "buff.footwork" if consumer_id.ends_with("leaping_plunge") else "buff.readiness"
		check(consumer_state.units(buff) > 0,"Prior root post-subtree grant retained during final ghost recovery: " + buff)
		check(scheduled._next_cast_start_index == 1,"Next macro visual start waits for ghost fade")
		scheduled.advance(0.201)
		consumer_state.advance_to(int(scheduled.elapsed_ms()),scheduled.record_frontier())
		check(consumer_state.units(buff) == 0 and scheduled._next_cast_start_index == 2,"Consumer starts and spends only after recovery: " + buff)
	# Real-time contact floors hold at every speed, including a public-var
	# speed change partway through a pause; natural cast time still scales.
	for speed in [0.5,1.0,2.0,4.0]:
		var fast := CombatPlayback.new()
		fast.speed = speed
		fast.start(fixture(17))
		var wall := [0.0]
		var times: Array = []
		fast.event_callback = func(event):
			if event.visual_beat: times.append(wall[0])
		while not fast.is_finished():
			wall[0] += 1.0
			fast.advance(0.001)
		check(absf(times[0] - 500.0/speed) <= 1.1,"Ordinary cast honors selected speed")
		for i in range(1,times.size()):
			check(times[i]-times[i-1] >= 139.0,"Real-time contact floor at %.1fx" % speed)
		check(fast.events_fired() == 17 and fast.damage_dealt() == 153,"Speed preserves final events and damage")
	var changed := CombatPlayback.new()
	changed.start(fixture(17))
	changed.advance(0.55)
	check(changed.events_fired() == 1 and changed.elapsed_ms() == 500,"Mid-gap state remains held")
	changed.speed = 4.0
	changed.advance(0.11)
	check(changed.events_fired() == 1 and changed.elapsed_ms() == 500,"Mid-chain4x cannot catch up whole flurry")
	changed.advance(0.004)
	check(changed.events_fired() == 2,"Mid-chain speed consumes remaining pause fraction")
	changed.speed = 1.0
	changed.advance(0.1)
	check(changed.events_fired() == 2,"Slowing midchain retains remaining pause")
	changed.skip()
	check(changed.is_finished() and changed.events_fired() == 17 and changed.damage_dealt() == 153,"Skip drains exact ordered state")
	var uneven := CombatPlayback.new()
	uneven.speed = 4.0
	uneven.start(fixture(200))
	uneven.advance(0.9)
	check(not uneven.is_finished() and uneven.events_fired() < 200,"Large delta crosses boundaries without bypassing floors")
	uneven.advance(10.0)
	check(uneven.is_finished() and uneven.damage_dealt() == 20100,"Large delta loses no events")
	await process_frame
	var stage := CombatStage.new()
	stage.size = Vector2(1280,500)
	root.add_child(stage)
	stage.configure("Rogue","Mouthy Drunk")
	var echo := CombatPlayback.PlaybackEvent.new()
	echo.cast = fixture(2).cast_events[1]
	echo.chain_count = 2
	echo.chain_index = 2
	echo.damage = echo.cast.physical_damage
	stage.play_retrigger_event(echo,4.0,true)
	var ghost = stage._retrigger_ghost
	check(is_instance_valid(ghost) and ghost.visible and is_equal_approx(ghost.modulate.a,0.48),"Follow-up uses one faded Rogue copy")
	check(ghost.duration >= 0.125 and ghost.textures.size() > 1,"Ghost retains real-time duration and original attack frames")
	check(stage.player_actor_anchor.position == stage._player_base_position,"Main actor anchored at ghost contact")
	ghost.set_process(false)
	ghost._process(0.10)
	check(ghost.modulate.a > 0 and ghost.modulate.a < 0.48,"Ghost visibly fades during attack")
	check(stage.player_actor_anchor.position == stage._player_base_position,"Ghost motion leaves main actor anchored")
	ghost._process(0.06)
	check(not ghost.visible and ghost.modulate.a == 0,"Ghost ends fully transparent and hidden")
	stage.play_retrigger_event(echo,1.0,true)
	check(stage._retrigger_ghost == ghost,"Consecutive follow-ups reuse the same ghost")
	for failure in ["was_dodged","was_interrupted","resource_unavailable","cooldown_blocked"]:
		echo.cast.set(failure,true)
		stage.play_retrigger_event(echo,4.0,true)
		check(not ghost.visible and stage.player_actor_anchor.position == stage._player_base_position,"Failed repeat has no successful ghost hit or main movement: " + failure)
		echo.cast.set(failure,false)
	stage.play_retrigger_event(echo,4.0,false)
	check(not ghost.visible,"Reduced motion creates no moving ghost")
	stage.play_retrigger_event(echo,4.0,true)
	CombatEffectIcons.reduced_motion = true
	ghost._process(0.001)
	check(not ghost.visible,"Mid-ghost reduced motion immediately stops copy")
	CombatEffectIcons.reduced_motion = false
	for cleanup in ["clear_transient_effects","reset_state","clear_target"]:
		stage.play_retrigger_event(echo,4.0,true)
		stage.call(cleanup)
		check(not ghost.visible,"Lifecycle clears ghost: " + cleanup)
	stage.configure("Rogue","Mouthy Drunk")
	stage.play_retrigger_event(echo,4.0,true)
	stage.play_cast_windup(fixture(2).cast_events[0],1.0,false)
	check(not ghost.visible,"Next macro cannot inherit ghost")
	check(stage.find_child("RetriggerChainTotal",true,false) == null and stage.find_child("RetriggerSlash",true,false) == null,"No combo badge or X slash nodes")
	stage.queue_free()
	var audio = root.get_node("AudioManager")
	var queued := CombatResolver.CastEvent.new()
	queued.physical_damage = 10
	queued.damage_contributions = [{"kind":"proc","damage":3},{"kind":"proc","damage":2}]
	audio.play_attack_sfx_for_cast(queued,1.0)
	audio.cancel_combat_sfx()
	var audio_count: int = audio.attack_sfx_play_count
	await create_timer(0.3).timeout
	check(audio.attack_sfx_play_count == audio_count,"Cancelled proc audio cannot fire into retry/exit/skip")
	queued.was_dodged = true
	var dodge_count: int = audio.dodge_sfx_play_count
	audio.play_retrigger_sfx(queued,1.0)
	check(audio.dodge_sfx_play_count == dodge_count+1 and audio.attack_sfx_play_count == audio_count,"Dodge beat has dodge sound without false contact")
	queued.was_dodged = false
	queued.resource_unavailable = true
	check(audio.play_retrigger_sfx(queued,1.0) == 0,"Unavailable repeat has no successful hit sound")
	audio.cancel_combat_sfx()
	print("Retrigger flurry PASS" if not failed else "Retrigger flurry FAILED")
	quit(1 if failed else 0)
