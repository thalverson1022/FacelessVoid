class_name CombatPlaybackPresenter
extends Node
var category_preview
## Owns the CombatPlayback instance and translates each fired timeline event
## into HUD/stage/popup/macro-strip updates. Extracted from combat_screen.gd's
## inline playback/VFX layer (docs/Phase_3_Technical_Debt_Architecture_Cleanup.md
## Phase 4).
##
## A Node (added as a permanent child of the combat window) so it gets
## get_tree()/create_tween() for free, but it deliberately never defines its
## own _process() -- combat_screen.gd's own _process() still exists and
## calls advance() every frame instead, specifically because headless tests
## drive frame advancement by calling combat_screen._process(delta) directly
## in single-shot scripts with no real running game loop. Moving _process()
## itself onto this node would have silently broken every one of those calls.
##
## Configured with direct references to the widgets/panels it needs to write
## to (set_combat_stage()/set_skill_build_panel()/set_popup_layer()/
## set_hud_widgets()) rather than a wider abstraction -- this mirrors exactly
## how the pre-extraction code already reached into those same widgets, just
## relocated. combat_screen.gd still owns constructing every widget and
## everything NOT related to live playback rendering: dashboard chrome
## (status/recap/log/retry/restart/map-button visibility), pre-fight HUD
## setup, the outcome reveal, and autosave -- those hand off through the
## `finished` signal exactly like every Phase 3 overlay's cross-cutting
## effects did.
##
## `_playback_active` intentionally stays a combat_screen.gd field, not
## something this class owns or mirrors: combat_screen.gd raises it BEFORE
## BuildState.finish_fight() even runs (see _on_fight_pressed()'s comment) so
## a run_state_changed signal fired by finish_fight() doesn't clobber the
## animated HUD -- that ordering requirement means the flag has to be
## settable independently of when start() is called here.

signal finished(result: CombatResolver.CombatResult, monster: Monster, was_skipped: bool)
signal gold_stolen_played(amount: int)

const PLAYBACK_HP_TWEEN_SEC := 0.15
const PLAYBACK_TICK_HP_TWEEN_SEC := 0.3
static var HUD_POISON_ICON: Texture2D = GameIcons.icon_for("status.poison")
static var HUD_SHRED_ICON: Texture2D = GameIcons.icon_for("status.shred")
static var HUD_DECAY_ICON: Texture2D = GameIcons.icon_for("status.decay")
static var MECHANIC_INTERRUPT_ICON: Texture2D = GameIcons.icon_for("defense.interrupt")

var skipping := false
var effect_icons: CombatEffectIcons

var _playback: CombatPlayback = null
var _intro_remaining_sec := 0.0
var _intro_duration_sec := 0.0
var _intro_scales_with_playback_speed := true
var _result: CombatResolver.CombatResult = null
var _monster: Monster = null

var _hp := 0.0
var _armor := 0
var _resist := 0.0
var _stacks := 0
var _armor_reduced := 0
var _shred_stacks := 0
var _decay_stacks := 0
var _interrupt_repeat_count := 0
var _interrupt_skill_lock_counts := {}
var _hp_bar_tween: Tween

var _combat_stage
var _skill_build_panel
var _popup_layer: CombatPopupLayer
var _hud_hp_text_label: Label
var _hud_health_bar: ProgressBar
var _hud_info_label: Label
var _hud_resist_label: Label
var _clear_status_chips: Callable
var _add_status_chip: Callable
var _flash_status_chips: Callable
var _pending_cleanse_status_flash := false


func set_combat_stage(stage) -> void:
	_combat_stage = stage


func set_skill_build_panel(panel) -> void:
	_skill_build_panel = panel


func set_popup_layer(layer: CombatPopupLayer) -> void:
	_popup_layer = layer


## `clear_chips`/`add_chip` mirror combat_screen.gd's private
## _clear_hud_status_chips()/_add_hud_status_chip() signatures exactly --
## shared with the pre/post-fight HUD render, so they stay owned there
## rather than duplicated here.
func set_hud_widgets(hp_text_label: Label, health_bar: ProgressBar, info_label: Label, resist_label: Label, clear_chips: Callable, add_chip: Callable, flash_chips: Callable = Callable()) -> void:
	_hud_hp_text_label = hp_text_label
	_hud_health_bar = health_bar
	_hud_info_label = info_label
	_hud_resist_label = resist_label
	_clear_status_chips = clear_chips
	_add_status_chip = add_chip
	_flash_status_chips = flash_chips


func is_active() -> bool:
	return _playback != null


func elapsed_ms() -> float:
	return _playback.elapsed_ms() if _playback != null else 0.0


func window_ms() -> int:
	return _playback.window_ms() if _playback != null else 0


func set_speed(speed: float) -> void:
	if _combat_stage != null: _combat_stage._clear_flurry()
	_cancel_combat_audio()
	if category_preview != null: category_preview.clear()
	if _playback != null:
		_playback.speed = speed


## Starts real-time visual playback of an already-resolved fight: builds the
## CombatPlayback timeline, resets the popup layer/combat stage/macro
## highlight, applies the Bandit Blade/Wyvern Kriss always-on visual effects
## (equipped-gear checks stay with the caller, which has BuildState access),
## and begins the intro countdown that advance() ticks down before the first
## timeline event can fire. Does not touch dashboard chrome, pre-fight HUD
## text, or _playback_active -- see this class's header for why those stay
## with the caller.
func start(result: CombatResolver.CombatResult, monster: Monster, wyvern_effect_active: bool, bandit_blade_effect_active: bool, play_intro_animation: bool, play_contract_traversal: bool = false, effective_slow: float = -1.0) -> void:
	_cancel_combat_audio()
	if category_preview != null: category_preview.clear()
	play_intro_animation = play_intro_animation and not CombatEffectIcons.reduced_motion
	_result = result
	if effect_icons != null:
		if not effect_icons.motion_changed.is_connected(_on_motion_changed):
			effect_icons.motion_changed.connect(_on_motion_changed)
		effect_icons.begin(result)
		if _skill_build_panel != null:
			_skill_build_panel.state.set_meta("combat_presentation", effect_icons.model)
	_monster = monster
	_hp = float(monster.hp)
	_armor = monster.armor
	_resist = monster.poison_resistance
	_stacks = 0
	_armor_reduced = 0
	_shred_stacks = 0
	_decay_stacks = 0
	_interrupt_repeat_count = 0
	_interrupt_skill_lock_counts.clear()
	var slow := monster.slow if effective_slow < 0.0 else effective_slow
	if _popup_layer != null:
		_popup_layer.reset_for_new_fight()
		_popup_layer.wyvern_tick_font_active = wyvern_effect_active
	if _combat_stage != null:
		_combat_stage.reset_state()
		_combat_stage.set_bandit_blade_effect_active(bandit_blade_effect_active)
		_combat_stage.set_slow_effect_active(slow > 0.0, slow, play_intro_animation)
	if _skill_build_panel != null and _skill_build_panel.has_method("clear_combat_highlight"):
		_skill_build_panel.clear_combat_highlight()
	if _skill_build_panel != null and _skill_build_panel.has_method("clear_interrupt_locks"):
		_skill_build_panel.clear_interrupt_locks()
	if _skill_build_panel != null and _skill_build_panel.has_method("set_slow_effect_active"):
		_skill_build_panel.set_slow_effect_active(slow > 0.0)
	if _skill_build_panel != null and _skill_build_panel.has_method("clear_stun_effect"):
		_skill_build_panel.clear_stun_effect()
	if _skill_build_panel != null and _skill_build_panel.has_method("set_combat_interaction_locked"):
		_skill_build_panel.set_combat_interaction_locked(true)
	_playback = CombatPlayback.new()
	_playback.event_callback = _on_event
	_playback.cast_start_callback = _on_cast_start
	_playback.finished_callback = _on_finished
	# Full window always plays on both a win and a loss -- a win used to
	# truncate at the recorded kill moment; the full window keeps the
	# "overkill" feel of watching every remaining cast/tick still land on the
	# corpse. The HUD's HP bar clamps at 0 in _on_event() so it never dips
	# below dead or un-dies.
	_playback.start(result)
	if _combat_stage != null and play_contract_traversal:
		_intro_duration_sec = _combat_stage.play_player_run_in(play_intro_animation)
		_intro_scales_with_playback_speed = false
	else:
		_intro_duration_sec = _combat_stage.play_fight_intro(play_intro_animation) if _combat_stage != null else 0.0
		_intro_scales_with_playback_speed = true
	_intro_remaining_sec = _intro_duration_sec


## Advances the playback clock by one frame. Called from combat_screen.gd's
## own _process() every frame while a fight is active -- see this class's
## header for why advancement isn't driven by a _process() defined here.
func advance(delta: float) -> void:
	if _playback == null:
		return
	if _intro_remaining_sec > 0.0:
		var playback_speed := maxf(_playback.speed, 0.0) if _intro_scales_with_playback_speed else 1.0
		var intro_advance := delta * playback_speed
		if intro_advance < _intro_remaining_sec:
			_intro_remaining_sec -= intro_advance
			return
		var overflow_delta := 0.0
		if playback_speed > 0.0:
			overflow_delta = (intro_advance - _intro_remaining_sec) / playback_speed
		_intro_remaining_sec = 0.0
		if overflow_delta <= 0.0:
			return
		delta = overflow_delta
	_playback.advance(delta)
	if _playback != null and effect_icons != null:
		effect_icons.advance_to(int(_playback.elapsed_ms()), _playback.record_frontier())
		_sync_presentation()
	_update_macro_progress()


## Fires every remaining timeline event instantly -- the Skip button's
## action, and the path the playback-enabled headless checks drive. Popup
## spawning and per-hit tweening are suppressed while the burst of remaining
## events fires.
func skip() -> void:
	if _popup_layer != null: _popup_layer.clear_retrigger_popups()
	_cancel_combat_audio()
	if category_preview != null: category_preview.clear()
	if _playback == null:
		return
	skipping = true
	if _popup_layer != null:
		_popup_layer.skip_active = true
		_popup_layer.skip_generation()
	_intro_remaining_sec = 0.0
	_playback.skip()
	skipping = false
	if _popup_layer != null:
		_popup_layer.skip_active = false


func _update_macro_progress() -> void:
	if _playback == null or _skill_build_panel == null or not _skill_build_panel.has_method("set_cast_progress"):
		return
	var cast := _playback.active_cast()
	if cast == null:
		return
	_skill_build_panel.set_cast_progress(cast.rotation_index, _playback.active_cast_progress(), cast.min_cast_time_proc_applied)


## Applies one fired timeline event to the live HUD: drains HP with a quick
## tween, replays the event's recorded armor/resist/stack changes (the same
## event-replay reads combat_screen.gd's _hud_final_armor()/
## _hud_final_poison_resist() use -- no combat math reimplemented), refreshes
## the info line and status chips, and spawns the matching comic-book popup.
func _on_event(event: CombatPlayback.PlaybackEvent) -> void:
	if effect_icons != null:
		effect_icons.advance_to(event.time_ms, event.sequence if event.sequence > 0 else 9223372036854775807)
	if event.is_tick:
		_stacks = event.tick.stacks_remaining
		if _combat_stage != null:
			_combat_stage.set_poison_stacks(_stacks, not skipping and not CombatEffectIcons.reduced_motion)
		if event.tick.had_active_stack:
			if _combat_stage != null:
				_combat_stage.play_poison_tick_pulse(not skipping and event.chain_count <= 1 and not CombatEffectIcons.reduced_motion)
			_hp = maxf(_hp - event.tick.damage, 0.0)
			_apply_hp(PLAYBACK_TICK_HP_TWEEN_SEC)
			# "Poison -N" matches the "SkillName -N" pattern the physical
			# cast popups use, for visual cohesion; font size/color are
			# unchanged, only the text gained a label.
			if _popup_layer != null and event.chain_count <= 1 and not CombatEffectIcons.reduced_motion:
				_popup_layer.spawn("Poison -%.0f" % event.tick.damage, CombatPopupLayer.Kind.POISON_TICK)
	else:
		var cast := event.cast
		if cast.gold_stolen > 0:
			gold_stolen_played.emit(cast.gold_stolen)
		var popup_delay := 0.0
		if event.chain_count > 1 and _combat_stage != null and not skipping:
			_combat_stage.play_retrigger_event(event, _playback.speed, not CombatEffectIcons.reduced_motion)
		elif _combat_stage != null and not cast.cooldown_blocked and not cast.resource_unavailable and not (category_preview != null and category_preview.handles(cast)):
			popup_delay = _combat_stage.play_cast_impact(cast, not skipping and not CombatEffectIcons.reduced_motion)
		if (cast.was_dodged or cast.physical_damage > 0.0 or cast.blocked_amount > 0.0) and not skipping:
			var audio_manager := get_node_or_null("/root/AudioManager")
			if audio_manager != null and audio_manager.has_method("play_attack_sfx_for_cast"):
				if event.chain_count > 1:
					if event.visual_beat:
						audio_manager.play_retrigger_sfx(cast, _playback.speed)
				else:
					audio_manager.play_attack_sfx_for_cast(cast, _playback.speed, false)
		if not cast.triggered_skill_names.is_empty() and _skill_build_panel != null and _skill_build_panel.has_method("highlight_rotation_index"):
			_skill_build_panel.highlight_rotation_index(cast.rotation_index, true)
		if cast.total_health_loss() > 0.0:
			_hp = maxf(_hp - cast.total_health_loss(), 0.0)
		_armor -= cast.armor_reduction_applied
		_armor_reduced += cast.armor_reduction_applied
		_shred_stacks += cast.shred_stacks_applied
		if cast.poison_resistance_reduction_applied > 0.0:
			_resist *= 1.0 - clampf(cast.poison_resistance_reduction_applied, 0.0, 1.0)
			_decay_stacks += cast.decay_stacks_applied
		_stacks = mini(_stacks + cast.poison_stacks_applied, _poison_stack_cap())
		if cast.poison_stacks_applied > 0:
			if _combat_stage != null:
				_combat_stage.set_poison_stacks(_stacks, not skipping and not CombatEffectIcons.reduced_motion)
		if cast.cleanse_triggered:
			_armor = _monster.armor
			_armor_reduced = 0
			_shred_stacks = 0
			_decay_stacks = 0
			_resist = _monster.poison_resistance
			_stacks = 0
			if _combat_stage != null:
				_combat_stage.set_poison_stacks(_stacks, not skipping and not CombatEffectIcons.reduced_motion)
				_combat_stage.play_cleanse_effect(not skipping and not CombatEffectIcons.reduced_motion)
			_pending_cleanse_status_flash = not skipping
		if cast.stun_duration_ms > 0 and _combat_stage != null:
			_combat_stage.play_stun_effect(cast.stun_duration_ms, not skipping and not CombatEffectIcons.reduced_motion, event.chain_count > 1 and event.chain_index > 1)
		if cast.stun_duration_ms > 0 and _skill_build_panel != null and _skill_build_panel.has_method("play_stun_effect"):
			_skill_build_panel.play_stun_effect(cast.stun_duration_ms, not skipping and not CombatEffectIcons.reduced_motion, _playback.speed)
		_interrupt_repeat_count = cast.interrupt_repeat_count_after
		_update_interrupt_skill_lock(cast)
		_apply_hp(PLAYBACK_HP_TWEEN_SEC)
		if event.chain_count <= 1 or event.chain_index == 1:
			_schedule_cast_popups(cast, popup_delay)
		elif event.visual_beat and not skipping and not CombatEffectIcons.reduced_motion and _popup_layer != null and not _is_hold_cast(cast):
			var echo_color := Color.TRANSPARENT
			if category_preview != null and category_preview.enabled and category_preview.Style.selected(cast.skill):
				echo_color = category_preview.Style.COLORS[cast.skill.category]
			_popup_layer.spawn_retrigger(cast, event.chain_index, echo_color)
	_update_hud_readout()
	if effect_icons != null: _sync_presentation()


func _on_cast_start(cast: CombatResolver.CastEvent) -> void:
	if _monster != null and _monster.interrupt_skip_count > 0:
		_interrupt_repeat_count = cast.interrupt_repeat_count
		_update_hud_readout()
	if skipping:
		return
	if _combat_stage != null and not cast.cooldown_blocked and not cast.resource_unavailable and not (category_preview != null and category_preview.handles(cast)):
		_combat_stage.play_cast_windup(cast, _playback.speed, not CombatEffectIcons.reduced_motion)
	if category_preview != null and category_preview.handles(cast) and not cast.cooldown_blocked and not cast.resource_unavailable:
		category_preview.windup(cast, _playback.speed)
	if _skill_build_panel != null and _skill_build_panel.has_method("set_cast_progress"):
		_skill_build_panel.set_cast_progress(cast.rotation_index, 0.0, cast.min_cast_time_proc_applied)


func _update_interrupt_skill_lock(cast: CombatResolver.CastEvent) -> void:
	if cast == null or cast.skill == null or _skill_build_panel == null or not _skill_build_panel.has_method("set_interrupt_locked_skill"):
		return
	var key := _skill_lock_key(cast.skill)
	if key == "":
		return
	if cast.interrupt_triggered and cast.interrupt_skip_count_applied > 0:
		_interrupt_skill_lock_counts[key] = cast.interrupt_skip_count_applied
		_skill_build_panel.set_interrupt_locked_skill(cast.skill, true)
		return
	if cast.interrupt_skipped:
		var remaining := maxi(0, int(_interrupt_skill_lock_counts.get(key, 0)) - 1)
		if remaining <= 0:
			_interrupt_skill_lock_counts.erase(key)
			_skill_build_panel.set_interrupt_locked_skill(cast.skill, false)
		else:
			_interrupt_skill_lock_counts[key] = remaining


func _skill_lock_key(skill: Skill) -> String:
	if skill == null:
		return ""
	if skill.id != "":
		return skill.id
	return skill.resource_path if skill.resource_path != "" else skill.display_name


func _schedule_cast_popups(cast: CombatResolver.CastEvent, delay_sec: float) -> void:
	var generation := _popup_layer.generation() if _popup_layer != null else 0
	if delay_sec <= 0.0 or skipping:
		_spawn_cast_popups(cast)
		return
	await get_tree().create_timer(delay_sec).timeout
	if _popup_layer == null or generation != _popup_layer.generation() or skipping:
		return
	_spawn_cast_popups(cast)


func _spawn_cast_popups(cast: CombatResolver.CastEvent) -> void:
	if cast.cooldown_blocked: return
	if category_preview != null and category_preview.handles(cast):
		if not skipping: category_preview.show_cast(cast)
		return
	if CombatEffectIcons.reduced_motion or cast.cooldown_blocked or cast.resource_unavailable:
		return
	if _popup_layer == null:
		return
	var skill_name := cast.skill.display_name if cast.skill != null else "Attack"
	if cast.was_interrupted:
		var interrupt_text := "skipped" if cast.interrupt_skipped else "interrupted"
		_popup_layer.spawn("%s %s" % [skill_name, interrupt_text], CombatPopupLayer.Kind.NORMAL)
		return
	if _is_hold_cast(cast):
		return
	# Damage number appended in the same "-N" style poison ticks already use.
	# The number is the event's full physical_damage, which already includes
	# any triggered-skill damage folded into the same cast by the resolver;
	# presentation splits the attack, but combat math stays merged.
	var category_color := Color.TRANSPARENT
	if category_preview != null and category_preview.enabled and category_preview.Style.selected(cast.skill):
		category_color = category_preview.Style.COLORS[cast.skill.category]
	var damage_suffix := ""
	if cast.was_dodged:
		damage_suffix = " 0.0"
	elif preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(cast):
		damage_suffix = " removes %.0f health" % cast.health_removed
	elif cast.physical_damage > 0.0 or cast.blocked_amount > 0.0:
		damage_suffix = " -%.0f" % cast.physical_damage
	if cast.is_crit and cast.crit_negation_damage_prevented > 0.0 and _popup_layer.has_method("spawn_crit_negated"):
		_popup_layer.spawn_crit_negated(skill_name, cast.physical_damage, cast.crit_negation_damage_prevented)
	elif cast.gold_stolen > 0 and _popup_layer.has_method("spawn_gold_hit"):
		_popup_layer.spawn_gold_hit(skill_name, cast.physical_damage, cast.gold_stolen, cast.is_crit)
	elif cast.is_crit:
		_popup_layer.spawn("%s%s!" % [skill_name, damage_suffix], CombatPopupLayer.Kind.CRIT, category_color)
	elif cast.min_cast_time_proc_applied:
		_popup_layer.spawn("%s%s PROC!" % [skill_name, damage_suffix], CombatPopupLayer.Kind.PROC, category_color)
	else:
		var label := _popup_layer.spawn("%s%s" % [skill_name, damage_suffix], CombatPopupLayer.Kind.NORMAL, category_color)
		if label != null and preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(cast): label.set_meta("health_removal_initial", true)
	for triggered_name in [] if _playback != null and _playback.current_event_is_chain() else cast.triggered_skill_names:
		_popup_layer.spawn(String(triggered_name), CombatPopupLayer.Kind.PROC)


func _is_hold_cast(cast: CombatResolver.CastEvent) -> bool:
	return cast != null and cast.skill != null and cast.skill.id == "skill.hold"


## Updates the HP text immediately and tweens the bar to the new value --
## discrete per-hit chunks rather than one smooth constant drain. Skipping
## sets the value directly (no tween churn for dozens of events at once).
func _apply_hp(tween_sec: float) -> void:
	if _hud_hp_text_label != null:
		_hud_hp_text_label.text = "%d/%d" % [ceili(_hp), _monster.hp]
	if _hp_bar_tween != null and _hp_bar_tween.is_valid():
		_hp_bar_tween.kill()
	if _hud_health_bar == null:
		return
	if skipping or CombatEffectIcons.reduced_motion:
		_hud_health_bar.value = _hp
		return
	_hp_bar_tween = create_tween()
	_hp_bar_tween.tween_property(_hud_health_bar, "value", _hp, tween_sec)


## Refreshes the HUD info line and status chips from the live playback
## values -- the real-time version of combat_screen.gd's
## _render_enemy_hud_post_fight()'s chip logic, updating as each event lands.
func _update_hud_readout() -> void:
	if _hud_info_label != null:
		_hud_info_label.text = "%d" % _armor
	if _hud_resist_label != null:
		_hud_resist_label.text = "%.0f%%" % (_resist * 100.0)
	if _clear_status_chips.is_valid():
		_clear_status_chips.call()
	if _add_status_chip.is_valid():
		CombatStatusIcons.add_timed_defense_chips(effect_icons.model if effect_icons != null else null, _add_status_chip)
		_add_status_chip.call("x%d" % _stacks, UIColors.TEXT_POISON, HUD_POISON_ICON)
		_add_status_chip.call("x%d" % _shred_stacks, UIColors.TEXT_WARNING, HUD_SHRED_ICON)
		_add_status_chip.call("x%d" % _decay_stacks, UIColors.TEXT_MAGIC, HUD_DECAY_ICON)
		if _monster != null and _monster.interrupt_skip_count > 0:
			_add_status_chip.call("%d/%d" % [_interrupt_repeat_count, CombatResolver.INTERRUPT_REPEAT_THRESHOLD], UIColors.TEXT_MAGIC, MECHANIC_INTERRUPT_ICON)
	if _pending_cleanse_status_flash:
		_pending_cleanse_status_flash = false
		if _flash_status_chips.is_valid():
			_flash_status_chips.call()


## CombatPlayback guarantees this fires exactly once per fight, whether the
## timeline ran to completion naturally or was cut short by skip(). Emits
## `finished` BEFORE clearing internal state (not after) so a handler that
## reads elapsed_ms()/window_ms()/is_active() during the signal still sees
## the fight's final values, not already-reset defaults.
func _on_finished() -> void:
	if _popup_layer != null: _popup_layer.clear_retrigger_popups()
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null: audio.cancel_combat_sfx(false)
	if category_preview != null: category_preview.clear()
	if effect_icons != null:
		effect_icons.finish(_result)
	if _skill_build_panel != null:
		_skill_build_panel.clear_presentation()
	if _hp_bar_tween != null and _hp_bar_tween.is_valid():
		_hp_bar_tween.kill()
	var result := _result
	var monster := _monster
	var was_skipped := skipping
	if _skill_build_panel != null and _skill_build_panel.has_method("clear_combat_highlight"):
		_skill_build_panel.clear_combat_highlight()
	if _skill_build_panel != null and _skill_build_panel.has_method("clear_interrupt_locks"):
		_skill_build_panel.clear_interrupt_locks()
	if _skill_build_panel != null and _skill_build_panel.has_method("set_slow_effect_active"):
		_skill_build_panel.set_slow_effect_active(false)
	if _skill_build_panel != null and _skill_build_panel.has_method("clear_stun_effect"):
		_skill_build_panel.clear_stun_effect()
	if _skill_build_panel != null and _skill_build_panel.has_method("set_combat_interaction_locked"):
		_skill_build_panel.set_combat_interaction_locked(false)
	if _combat_stage != null and _combat_stage.has_method("set_slow_effect_active"):
		_combat_stage.set_slow_effect_active(false)
	if _combat_stage != null: _combat_stage._clear_flurry()
	if was_skipped and _combat_stage != null and _combat_stage.has_method("clear_transient_effects"):
		_combat_stage.clear_transient_effects()
	_interrupt_skill_lock_counts.clear()
	finished.emit(result, monster, was_skipped)
	_playback = null
	_result = null
	_monster = null
	_intro_remaining_sec = 0.0
	_intro_duration_sec = 0.0
	_intro_scales_with_playback_speed = true


func _poison_stack_cap() -> int:
	if _result == null:
		return CombatResolver.MAX_POISON_STACKS
	return maxi(1, _result.poison_stack_cap)


func _sync_presentation() -> void:
	var snapshot: Dictionary = effect_icons.model.statuses
	_stacks = int(snapshot.get("poison", _stacks))
	_shred_stacks = int(snapshot.get("shred", _shred_stacks))
	_decay_stacks = int(snapshot.get("decay", _decay_stacks))
	_armor = int(snapshot.get("armor", _armor))
	_resist = float(snapshot.get("poison_resistance", _resist))
	_update_hud_readout()
	if _skill_build_panel != null:
		_skill_build_panel.update_presentation(effect_icons.model)


func _on_motion_changed(enabled: bool) -> void:
	_cancel_combat_audio()
	if not enabled:
		return
	_intro_remaining_sec = 0
	if _combat_stage != null:
		_combat_stage.clear_transient_effects()
	if _popup_layer != null:
		_popup_layer.clear_transient_effects()
	if _skill_build_panel != null:
		_skill_build_panel.clear_stun_effect()
	if _hp_bar_tween != null and _hp_bar_tween.is_valid():
		_hp_bar_tween.kill()
	if _hud_health_bar != null:
		_hud_health_bar.value = _hp


func _cancel_combat_audio() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null: audio.cancel_combat_sfx()


func _exit_tree() -> void:
	_cancel_combat_audio()
