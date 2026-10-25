extends SceneTree
## Runtime-resolved presentation contracts. Never reads or writes player saves.
const Presentation = preload("res://scripts/ui/combat_presentation_state.gd")
const Text = preload("res://scripts/ui/combat_effect_text.gd")
const Keywords = preload("res://scripts/ui/presentation_keywords.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAILED: " + message)

static func fixture(kind: String, seed_value: int = 7) -> Dictionary:
	var gear: Array[GearItem] = []
	var names := ["nightkiss_kitana", "helm_of_the_samurai", "lolzorzs_locket", "wingjammer", "cloak_of_speed"]
	if kind in ["crown", "poison", "natural"]: names = ["decrepit_blade", "serpents_coil", "crown_of_concertation", "lolzorzs_locket", "wingjammer"]
	for name in names: gear.append(load("res://data/gear/" + name + ".tres"))
	var p := BuildResolver.resolve_stats(load("res://data/classes/rogue.tres"), [], [], gear)
	p.retrigger_chance = 1.0
	p.crit_chance = 1.0
	var target := Monster.new()
	target.display_name = "Practice Target"
	target.hp = 100000
	target.armor = 100
	var skills: Array[Skill] = []
	var duration := 600
	if kind in ["nightkiss", "empty"]:
		var unlocked := BuildResolver.resolve_unlocked_skills(load("res://data/classes/rogue.tres"), [], [], gear)
		var ex: Skill = unlocked.filter(func(skill): return skill.id == "skill.exsanguinate")[0].duplicate(true)
		ex.base_execution_ms = 300
		ex.min_execution_ms = 300
		if kind == "nightkiss":
			var shred := Skill.new()
			shred.id = "fixture.shred"
			shred.display_name = "Shred setup"
			shred.category = Skill.Category.DEBUFF
			shred.base_execution_ms = 300
			shred.min_execution_ms = 300
			var effect := ArmorReductionEffect.new()
			effect.amount = 1
			shred.effects = [effect]
			skills.append(shred)
		else: duration = 300
		skills.append(ex)
	else:
		var buff := Skill.new()
		buff.id = "skill.virulent_poison"
		buff.display_name = "Virulent Poison"
		buff.category = Skill.Category.SELF_BUFF
		buff.base_execution_ms = 100
		buff.min_execution_ms = 100
		var buff_effect := preload("res://scripts/resources/self_buff_effect.gd").new()
		buff_effect.kind = "virulent_poison"
		buff.effects = [buff_effect]
		var fuel := Skill.new()
		fuel.id = "fixture.poison"
		fuel.display_name = "Poison setup"
		fuel.category = Skill.Category.DEBUFF
		fuel.base_execution_ms = 100
		fuel.min_execution_ms = 100
		var poison := PoisonDamageEffect.new()
		poison.stacks_applied = 4
		fuel.effects = [poison]
		var strike := preload("res://scripts/systems/p6_poison_contracts.gd").poison_strike()
		strike.base_execution_ms = 100
		strike.min_execution_ms = 100
		strike.cooldown_ms = 8000
		p.critical_poison_enabled = true
		skills = [buff, fuel, strike]
		duration = 300
		if kind == "natural":
			p.retrigger_chance = 0.0
			p.special_effects.legendary.decrepit = false
			skills = [fuel, load("res://data/skills/hold.tres")]
			duration = 2100
	return {"result": CombatResolver.resolve(skills, p, target, duration, seed_value, true), "target": target, "stats": p, "gear": gear}

func verify_health(f: Dictionary) -> void:
	var r: CombatResolver.CombatResult = f.result
	check(r.is_valid, "legal five-slot Nightkiss runtime fixture valid")
	check(r.total_health_removed > 0 and r.total_damage == 0, "health removal remains outside damage and DPS")
	var playback := CombatPlayback.new()
	var fired: Array = []
	playback.event_callback = func(event): fired.append(event)
	playback.start(r)
	playback.skip()
	check(playback.damage_dealt() == r.total_damage and playback.health_removed() == r.total_health_removed, "skip replays distinct damage and health-removal totals")
	check(fired.back().chain_health_removed == r.total_health_removed and fired.back().chain_damage == 0, "recursive chain keeps separate totals")
	var recap := CombatRecap.summarize(r, f.target)
	check(recap.health_removed == r.total_health_removed and recap.biggest_hit == 0 and recap.physical_pct == 0, "removal never counted as hit or damage mix")
	var data := CombatLogInspectorData.build(r, f.target)
	check(data.damage_rows.is_empty() and data.health_removal_rows.size() == 1 and data.health_removal_rows[0].health_removed == r.total_health_removed, "chart separately totals health removal")
	check(data.timeline_rows.any(func(row): return row.kind == "health_removal"), "timeline distinguishes typed health-removal operations")
	var model := Presentation.new()
	model.begin(r)
	for event in fired:
		model.advance_to(event.time_ms, event.sequence)
		if event.health_removed > 0:
			check(model.statuses.shred == 0 and model.statuses.armor == f.target.armor, "same-contact replay shows consumed Shred and restored armor")
	var recap_view = load("res://scenes/combat/combat_screen.gd").new()
	check("\n".join(recap_view._build_victory_recap_lines(r, f.target)).contains("health removed:"), "actual Adventure victory recap separates removal from damage")
	recap_view.free()
	var text := CombatResultFormatter.format(r, f.target)
	check(text.contains("removes 720.0 health") and text.contains("Health removed:"), "narrative identifies removal")
	var view := TrainingRoomCombatView.new()
	root.add_child(view)
	view.play(r, f.target)
	check(view._damage_dealt == 0 and view._health_removed == r.total_health_removed and view._health_removed_label.visible, "actual Practice view exposes health removal independently")
	CombatEffectIcons.reduced_motion = true
	view._instant_playback = false
	view.play(r, f.target)
	view._skip()
	check(view._health_removed == r.total_health_removed and view._popup_layer.get_children().filter(func(node): return not node.is_queued_for_deletion()).is_empty(), "reduced-motion Practice skip preserves removal without popups")
	CombatEffectIcons.reduced_motion = false
	view.queue_free()
	var presenter := CombatPlaybackPresenter.new()
	root.add_child(presenter)
	var hp_label := Label.new()
	var hp_bar := ProgressBar.new()
	hp_bar.max_value = f.target.hp
	presenter.add_child(hp_label)
	presenter.add_child(hp_bar)
	presenter.set_hud_widgets(hp_label, hp_bar, null, null, Callable(), Callable())
	presenter.start(r, f.target, false, false, false)
	presenter.skip()
	check(presenter._hp == maxf(0, f.target.hp - r.total_health_loss()) and hp_bar.value == presenter._hp, "Adventure presenter HP applies removal on skip")
	presenter.queue_free()
	for speed_value in [1.0, 4.0]:
		var clock := CombatPlayback.new()
		clock.start(r)
		clock.speed = speed_value
		for step in 1200:
			clock.advance(1.0 / 60.0)
			if clock.is_finished(): break
		check(clock.is_finished() and clock.health_removed() == r.total_health_removed and clock.events_fired() == r.cast_events.size() + r.tick_events.size(), "natural playback at speed preserves all authoritative events")

func verify_empty() -> void:
	var f := fixture("empty")
	var r: CombatResolver.CombatResult = f.result
	var cast := r.cast_events[0]
	check(r.is_valid and cast.health_removed == 0 and Text.is_health_removal(cast), "zero-Shred Exsanguinate retains typed health removal")
	check(CombatResultFormatter._cast_line(cast).contains("removes 0.0 health"), "zero-Shred narrative remains explicit")
	var layer := CombatPopupLayer.new()
	root.add_child(layer)
	layer.size = Vector2(600, 300)
	var echo := layer.spawn_retrigger(cast, 2)
	check(echo.text.contains("removes 0 health"), "Adventure echo popup identifies zero removal")
	var view := TrainingRoomCombatView.new()
	root.add_child(view)
	view._instant_playback = false
	var event := CombatPlayback._merge_events(r)[0] as CombatPlayback.PlaybackEvent
	check(view._popup_text(event).contains("removes 0.0 health"), "Practice initial popup identifies zero removal")
	echo = view._spawn_retrigger_popup(event)
	check(echo.text.contains("removes 0.0 health"), "Practice echo popup identifies zero removal")
	view.queue_free()
	layer.queue_free()

func verify_poison() -> void:
	var f := fixture("poison")
	var r: CombatResolver.CombatResult = f.result
	check(r.is_valid and r.tick_events.any(func(tick): return tick.origin_kind == "poison_repeat"), "runtime Coil fixture emits free Poison repeats")
	var log_text := CombatResultFormatter.format_practice(r, f.target)
	check(log_text.contains("Consume 4 stacks") and log_text.contains("Retrigger; free, current buffs; no Consume"), "Poison narrative distinguishes all-stack Consume and free live repeats")
	check(r.tick_events[0].raw_damage > r.tick_events.back().raw_damage, "actual Virulent charges exhaust across live Poison repeats")
	var model := Presentation.new()
	model.begin(r)
	var locket_changes := 0
	var crown_seen := false
	var last_dash: Dictionary = {}
	for record in r.trace.presentation_records:
		model.advance_to(record.time_ms, record.sequence)
		if record.kind == "effect_lifecycle" and record.payload.get("effect_id") == "virulent_poison" and not record.payload.get("after", {}).is_empty():
			crown_seen = crown_seen or Text.magnitude_for("buff.virulent_poison", record.payload.after).contains("×3.0")
		if record.kind == "legendary_buff_grant":
			last_dash = model.active["legendary." + record.payload.kind].duplicate(true)
			var effect: Dictionary = model.active["legendary." + record.payload.kind]
			check(effect.source == record.payload.after.source_id and effect.state.magnitude == record.payload.after.magnitude, "buff source and Crown strength replay from authoritative payload")
			check(Text.magnitude_for(effect.id, effect.state).contains("Attack speed:"), "Dash tooltip shows actual magnitude")
		if record.kind == "legendary_locket_trial":
			for id in record.payload.deadlines:
				locket_changes += 1
				check(int(model.cooldowns.get(id, record.time_ms)) == int(record.payload.deadlines[id].after), "Locket replay updates existing shared deadline")
	check(locket_changes > 0, "runtime critical packets actually recover a running Locket cooldown")
	check(crown_seen, "Crown Virulent inspector magnitude reads recorded triple multiplier")
	check(not last_dash.is_empty() and last_dash.state.magnitude == last_dash.state.units * 0.1, "Crown Dash inspector magnitude doubles bonus per recorded stack")
	model.records = []
	model.cursor = 0
	model.active["legendary.dash"] = last_dash
	model.advance_to(int(last_dash.state.expires_at_ms) - 1)
	check(model.units("buff.dash") == last_dash.state.units, "Dash still displays one millisecond before shared expiry")
	model.advance_to(int(last_dash.state.expires_at_ms))
	check(model.units("buff.dash") == 0, "Dash display expires at shared authoritative deadline")
	check(model.journal.any(func(line): return line.contains("free packet")), "effect journal identifies free current-buff retriggers")
	var natural := fixture("natural")
	check(CombatResultFormatter.format_practice(natural.result, natural.target).contains("not Consume"), "natural Poison depletion remains distinct")

func verify_meditation() -> void:
	var f := fixture("nightkiss")
	var r: CombatResolver.CombatResult = f.result
	var model := Presentation.new()
	model.begin(r)
	var last_deadline := 0
	for record in r.trace.presentation_records:
		model.advance_to(record.time_ms, record.sequence)
		if record.kind == "legendary_buff_grant":
			var state: Dictionary = model.active["legendary.meditation"].state
			last_deadline = state.expires_at_ms
			check(state.units == 5 and state.cap == 5 and Text.magnitude_for("buff.meditation", state) == "Physical damage multiplier: ×2.0", "Meditation count/cap/multiplier follows actual capped grant")
	model.advance_to(last_deadline)
	check(model.units("buff.meditation") == 0, "shared Meditation timer expires at exact deadline")
	for id in ["buff.footwork", "buff.bypass", "buff.dance", "buff.master_of_poisons", "buff.touch_of_darkness", "buff.beguiling_presence", "status.penetration", "status.potency"]:
		check(Text.rule_for(id).contains("base"), "buff rule distinguishes base duration from scaled live timer: " + id)
	var matches := Keywords.runs("Meditation and Dash")
	check(matches.filter(func(run): return run.kind == "buff").size() == 2, "new named buffs use canonical buff presentation")

func run() -> void:
	verify_health(fixture("nightkiss"))
	verify_empty()
	verify_poison()
	verify_meditation()
	await process_frame
	print("T9_COMBAT_FEEDBACK ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
