class_name CombatPopupLayer
extends Control
const PopupLayout = preload("res://scripts/ui/combat_popup_layout.gd")
## Comic-book skill-popup subsystem: spawns, tweens, and retires the floating
## damage/crit/poison-tick/proc text over the combat stage. Extracted from
## combat_screen.gd's inline playback/VFX layer
## (docs/Phase_3_Technical_Debt_Architecture_Cleanup.md Phase 4) -- fully
## self-contained (no BuildState/autoload dependency), so it's a plain
## global-class script rather than a scene, matching GearCompareButton's
## precedent. combat_screen.gd instantiates it directly via
## CombatPopupLayer.new() and adds it as a child of the combat window, same
## as the bare Control it replaces.
##
## Two pieces of state the presenter still owns are threaded in rather than
## duplicated here: `skip_active` (Skip suppresses new spawns -- decided by
## the resolved playback's skip state, not by this layer) and
## `wyvern_tick_font_active` (Wyvern Kriss's smaller poison-tick text is an
## equipped-gear check, not a popup-layer concern).
##
## NOTE: `training_room_combat_view.gd` has its own separate, parallel popup
## implementation (own POPUP_* constants, own spawn logic) that this
## extraction does not touch -- discovered during this Phase 4 pass but out
## of scope for it. Worth unifying onto this shared class later; see the
## tech-debt doc.

enum Kind { NORMAL, CRIT, POISON_TICK, PROC }

const RETRIGGER_OPACITY := 0.65
const RETRIGGER_LIFETIME_SEC := 0.24
const RETRIGGER_RISE_PX := 18.0


class CritCrossOutOverlay:
	extends Control

	const LINE_COLOR := Color(1.0, 0.08, 0.05, 0.96)
	const LINE_OUTLINE := Color(0.16, 0.0, 0.0, 0.88)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var pad := 8.0
		var start := Vector2(pad, size.y - pad)
		var finish := Vector2(size.x - pad, pad)
		draw_line(start, finish, LINE_OUTLINE, 10.0, true)
		draw_line(start, finish, LINE_COLOR, 6.0, true)

## Popup lifetime from spawn to fully faded/freed.
const POPUP_DURATION_SEC := 1.35
## Comic-book popup font (Pirata One reads as a heavy action word; swap for
## MedievalSharp-Regular.ttf here if it lands better in real play).
const POPUP_FONT := preload("res://assets/fonts/PirataOne-Regular.ttf")
## How far a popup floats upward over its lifetime.
const POPUP_RISE_PX := 24.0
## Gentle lift duration; avoids damage text feeling launched from the target.
const POPUP_RISE_SEC := 1.05
## Poison ticks drift more slowly so they read as damage-over-time.
const POPUP_TICK_RISE_SEC := 1.5
## Fade starts after this long, so the word is readable before it dissolves.
const POPUP_FADE_DELAY_SEC := 0.45
## Horizontal/vertical random jitter around the spawn point so rapid casts
## don't stack into one unreadable pile.
const POPUP_JITTER_X_PX := 120.0
const POPUP_JITTER_Y_PX := 34.0
## Vertical spawn anchor as a fraction of the combat panel's height.
const POPUP_BASE_Y_FRACTION := 0.55
## Popups never spawn above this y -- keeps the enemy HUD strip clear.
const POPUP_TOP_MARGIN_PX := 96.0
## Font sizes per popup kind.
const POPUP_FONT_SIZE := 52
const POPUP_CRIT_FONT_SIZE := 68
const POPUP_TICK_FONT_SIZE := 26
const POPUP_WYVERN_TICK_FONT_SIZE := 20
const POPUP_PROC_FONT_SIZE := 56
const POPUP_POISON_TICK_JITTER_X_PX := 34.0
const POPUP_POISON_TICK_JITTER_Y_PX := 16.0
## Crit punch-scale: the label spawns at this scale and snaps to 1.0.
const POPUP_CRIT_PUNCH_SCALE := 1.35
const POPUP_CRIT_PUNCH_SEC := 0.12
## Simultaneous popup caps so long fights don't flood the panel -- poison
## ticks (1/second, low-stakes) get a tighter cap of their own.
const POPUP_MAX_ACTIVE := 10
const POPUP_MAX_TICK_ACTIVE := 3
## Popup colors per kind, all from UIColors: normal cast, crit (gold, per
## the agreed design), poison tick (low-key green), proc (flashy magic
## purple for Opportunity Strikes / Mithril Karambit triggers).
const POPUP_NORMAL_COLOR := UIColors.TEXT_NORMAL
const POPUP_CRIT_COLOR := UIColors.TEXT_GOLD
const POPUP_TICK_COLOR := UIColors.TEXT_POISON
const POPUP_PROC_COLOR := UIColors.TEXT_MAGIC
const POPUP_NEGATED_ACTUAL_FONT_SIZE := 54
const POPUP_NEGATED_GAP_PX := 18.0
const GOLD_ICON := preload("res://assets/ui/icons/gold.png")
const GOLD_ICON_SIZE := Vector2(56.0, 56.0)

## Set true while a Skip flush is in progress -- suppresses new spawns so a
## skip doesn't spray the whole remaining timeline's popups at once.
var skip_active: bool = false
## Wyvern Kriss's identity is faster/smaller poison ticks -- the presenter
## sets this from an equipped-gear check at fight start.
var wyvern_tick_font_active: bool = false

var _combat_stage
var _rng := RandomNumberGenerator.new()
var _generation := 0
var _active_count := 0
var _active_tick_count := 0


func _ready() -> void:
	z_index = 35 # Above stage actors/ghosts; bounded lanes stay below HUD values.
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Optional anchor source for poison-tick popups, which spawn near the enemy
## rather than at the panel's general popup anchor.
func set_combat_stage(stage) -> void:
	_combat_stage = stage


## Resets popup bookkeeping for a fresh fight.
func reset_for_new_fight() -> void:
	clear_retrigger_popups()
	_active_count = 0
	_active_tick_count = 0
	_generation += 1
	_rng.randomize()


## Bumped by reset_for_new_fight() and skip_generation(). The presenter reads
## this to detect a stale delayed popup spawn: a popup scheduled with a delay
## (a triggered-skill follow-up hit beat) that's still pending when a new
## fight starts or a skip flush happens should be dropped, not spawned late
## into the wrong fight/moment.
func generation() -> int:
	return _generation


## Bumps generation without resetting active counts -- used when Skip starts
## a flush, so any already-scheduled delayed popup drops itself (see
## generation()) without needing to also reset the max-active bookkeeping
## Skip's own suppression (skip_active) already handles.
func skip_generation() -> void:
	_generation += 1


## Clear visible and delayed feedback when reduced motion is enabled.
func clear_transient_effects() -> void:
	skip_generation()
	_active_count = 0
	_active_tick_count = 0
	for popup in get_children():
		popup.hide()
		popup.queue_free()


func spawn_poison_tick(damage: float, critical: bool, preserved: bool = false) -> Label:
	var label := spawn("Poison -%.0f%s" % [damage, "!" if critical else ""], Kind.POISON_TICK, Color.TRANSPARENT, false, 0, critical)
	if preserved and label != null:
		preload("res://scripts/ui/poison_preservation_feedback.gd").apply(label)
	return label


func spawn(text: String, kind: int, color_override: Color = Color.TRANSPARENT, static_motion: bool = false, size_override: int = 0, poison_critical: bool = false) -> Label:
	if skip_active:
		return null
	if _visible_popup_count() >= POPUP_MAX_ACTIVE:
		return null
	if kind == Kind.POISON_TICK and _visible_popup_count(true) >= POPUP_MAX_TICK_ACTIVE:
		return null
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", POPUP_FONT)
	var font_size := POPUP_FONT_SIZE
	var color := POPUP_NORMAL_COLOR
	match kind:
		Kind.CRIT:
			font_size = POPUP_CRIT_FONT_SIZE
			color = POPUP_CRIT_COLOR
		Kind.POISON_TICK:
			font_size = _poison_tick_font_size()
			if poison_critical:
				font_size = roundi(font_size * 1.5)
				label.set_meta("critical_poison", true)
			color = POPUP_TICK_COLOR
		Kind.PROC:
			font_size = POPUP_PROC_FONT_SIZE
			color = POPUP_PROC_COLOR
	if color_override.a > 0:
		color = color_override
		label.name = "CategoryFloatingText"
	if size_override > 0: font_size = size_override
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	preload("res://scripts/ui/combat_gold_text_icon.gd").decorate(label)
	add_child(label)
	label.reset_size()
	label.pivot_offset = label.size * 0.5
	var fit := PopupLayout.place(label, self, _combat_stage, kind == Kind.POISON_TICK)
	var spawn_position := label.position
	var spawn_x := spawn_position.x
	var spawn_y := spawn_position.y
	label.position = Vector2(spawn_x, spawn_y)
	_active_count += 1
	if kind == Kind.POISON_TICK:
		_active_tick_count += 1
	var tween := label.create_tween()
	tween.set_parallel(true)
	if static_motion:
		label.scale = Vector2.ONE * fit
	elif kind == Kind.CRIT or (kind == Kind.POISON_TICK and poison_critical):
		label.scale = Vector2.ONE * POPUP_CRIT_PUNCH_SCALE * fit
		tween.tween_property(label, "scale", Vector2.ONE * fit, POPUP_CRIT_PUNCH_SEC)
	else:
		label.scale = Vector2.ONE * 0.92 * fit
		tween.tween_property(label, "scale", Vector2.ONE * fit, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var rise_sec := POPUP_TICK_RISE_SEC if kind == Kind.POISON_TICK else POPUP_RISE_SEC
	if not static_motion:
		tween.tween_property(label, "position:y", spawn_y - POPUP_RISE_PX, rise_sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, POPUP_DURATION_SEC - POPUP_FADE_DELAY_SEC).set_delay(POPUP_FADE_DELAY_SEC)
	tween.finished.connect(_on_popup_finished.bind(label, kind))
	return label


## One subordinate label per visible echo; never expands triggered proc names.
## The actual resolved damage is shown even when a critical bonus was negated.
func clear_retrigger_popups() -> void:
	for popup in get_children():
		if popup.has_meta("retrigger_hit"):
			popup.hide()
			popup.queue_free()


func spawn_retrigger(cast: CombatResolver.CastEvent, chain_index: int, color_override: Color = Color.TRANSPARENT) -> Label:
	if skip_active or cast.cooldown_blocked or cast.resource_unavailable:
		return null
	var skill_name := cast.skill.display_name if cast.skill != null else "Attack"
	var text := "%s -%.0f" % [skill_name, cast.physical_damage]
	if preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(cast):
		text = "%s removes %.0f health" % [skill_name, cast.health_removed]
	var font_size := POPUP_FONT_SIZE
	var color := POPUP_NORMAL_COLOR
	if cast.was_interrupted:
		text = "%s %s" % [skill_name, "skipped" if cast.interrupt_skipped else "interrupted"]
	elif cast.was_dodged:
		text = "%s 0.0 dodged" % skill_name
	elif cast.is_crit:
		text += "!"
		font_size = POPUP_CRIT_FONT_SIZE
		color = POPUP_CRIT_COLOR
	elif cast.min_cast_time_proc_applied:
		text += " PROC!"
		font_size = POPUP_PROC_FONT_SIZE
		color = POPUP_PROC_COLOR
	if cast.gold_stolen > 0: text += " +%d gold" % cast.gold_stolen
	if color_override.a > 0 and cast.crit_negation_damage_prevented <= 0 and cast.gold_stolen <= 0:
		color = color_override
	if cast.skill != null and cast.skill.category in [Skill.Category.DEBUFF, Skill.Category.SELF_BUFF]:
		var category_style = preload("res://scripts/ui/skill_category_preview_style.gd")
		text = skill_name + "\n" + category_style.outcome(cast)
		color = category_style.COLORS[cast.skill.category]
	var label := _make_popup_label(text, roundi(font_size * 0.75), color)
	label.name = "RetriggerHitText"
	label.set_meta("retrigger_hit", true)
	var live_echoes: Array[Node] = []
	for popup in self.get_children():
		if popup.has_meta("retrigger_hit") and not popup.is_queued_for_deletion(): live_echoes.append(popup)
	# Long health-removal labels occupy one centered lane.
	for popup in get_children():
		if popup.has_meta("health_removal_initial") and preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(cast): popup.hide()
	var wide := preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(cast) and label.get_combined_minimum_size().x > self.size.x * 0.45
	while live_echoes.size() >= (1 if wide else 2):
		var oldest = live_echoes.pop_front()
		oldest.hide()
		oldest.queue_free()
	label.add_theme_constant_override("outline_size", 2)
	add_child(label)
	label.reset_size()
	var fit := minf(1.0, maxf(1.0, self.size.x - 16.0) / maxf(1.0, label.size.x))
	fit = fit if preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(cast) else 1.0
	label.scale = Vector2.ONE * fit
	var anchor := _popup_area_size() * Vector2(0.65, 0.5)
	if _combat_stage != null:
		anchor = get_global_transform().affine_inverse() * _combat_stage.enemy_popup_global_position()
	# Two fixed heights keep adjacent high-speed contacts distinct, without jitter.
	label.position = Vector2(clampf(anchor.x - label.size.x * fit * 0.5, 8.0, maxf(8.0, size.x - label.size.x * fit - 8.0)), maxf(POPUP_TOP_MARGIN_PX, anchor.y - label.size.y - 60.0 - (chain_index % 2) * 36.0))
	label.modulate.a = RETRIGGER_OPACITY
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - RETRIGGER_RISE_PX, RETRIGGER_LIFETIME_SEC)
	tween.tween_property(label, "modulate:a", 0.0, 0.17).set_delay(0.07)
	tween.finished.connect(label.queue_free)
	return label


func spawn_gold_hit(skill_name: String, damage: float, gold_amount: int, is_crit: bool = true) -> void:
	if skip_active:
		return
	if _visible_popup_count() >= POPUP_MAX_ACTIVE:
		return
	var font_size := POPUP_CRIT_FONT_SIZE if is_crit else POPUP_FONT_SIZE
	var text_color := POPUP_CRIT_COLOR if is_crit else POPUP_NORMAL_COLOR
	var root := HBoxContainer.new()
	root.name = "GoldHitPopup"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var crit_suffix := "!" if is_crit else ""
	var hit_label := _make_popup_label("%s %.0f%s" % [skill_name, damage, crit_suffix], font_size, text_color)
	root.add_child(hit_label)

	var icon := TextureRect.new()
	icon.name = "GoldIcon"
	icon.texture = GOLD_ICON
	icon.custom_minimum_size = GOLD_ICON_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon)

	var gold_label := _make_popup_label("%d" % gold_amount, font_size, POPUP_CRIT_COLOR)
	root.add_child(gold_label)

	root.reset_size()
	root.pivot_offset = root.size * 0.5
	var fit := PopupLayout.place(root, self, _combat_stage, false)
	_active_count += 1
	root.scale = Vector2.ONE * (POPUP_CRIT_PUNCH_SCALE if is_crit else 0.92) * fit

	var tween := root.create_tween()
	tween.set_parallel(true)
	if is_crit:
		tween.tween_property(root, "scale", Vector2.ONE * fit, POPUP_CRIT_PUNCH_SEC)
	else:
		tween.tween_property(root, "scale", Vector2.ONE * fit, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "position:y", root.position.y - POPUP_RISE_PX, POPUP_RISE_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "modulate:a", 0.0, POPUP_DURATION_SEC - POPUP_FADE_DELAY_SEC).set_delay(POPUP_FADE_DELAY_SEC)
	tween.finished.connect(_on_gold_hit_popup_finished.bind(root))


func spawn_crit_negated(skill_name: String, reduced_damage: float, prevented_damage: float) -> void:
	if skip_active:
		return
	if _visible_popup_count() >= POPUP_MAX_ACTIVE:
		return
	var original_damage := reduced_damage + maxf(prevented_damage, 0.0)
	var root := Control.new()
	root.name = "CritNegationPopup"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var skill_label := _make_popup_label(skill_name, POPUP_CRIT_FONT_SIZE, POPUP_CRIT_COLOR)
	root.add_child(skill_label)
	skill_label.reset_size()
	skill_label.position = Vector2.ZERO

	var original := _make_popup_label("-%.0f!" % original_damage, POPUP_CRIT_FONT_SIZE, POPUP_CRIT_COLOR)
	root.add_child(original)
	original.reset_size()
	original.position = Vector2(skill_label.size.x + 8.0, 0.0)

	var cross := CritCrossOutOverlay.new()
	cross.name = "CritCrossOutOverlay"
	cross.size = original.size
	cross.position = original.position
	cross.z_index = 3
	root.add_child(cross)

	var actual := _make_popup_label("-%.0f!" % reduced_damage, POPUP_NEGATED_ACTUAL_FONT_SIZE, POPUP_CRIT_COLOR)
	root.add_child(actual)
	actual.reset_size()
	actual.position = Vector2(original.position.x + original.size.x + POPUP_NEGATED_GAP_PX, maxf(0.0, (original.size.y - actual.size.y) * 0.5))

	root.size = Vector2(skill_label.size.x + 8.0 + original.size.x + POPUP_NEGATED_GAP_PX + actual.size.x, maxf(original.size.y, actual.size.y))
	root.pivot_offset = root.size * 0.5
	var fit := PopupLayout.place(root, self, _combat_stage, false)
	root.scale = Vector2.ONE * POPUP_CRIT_PUNCH_SCALE * fit
	_active_count += 1

	var tween := root.create_tween()
	tween.set_parallel(true)
	tween.tween_property(root, "scale", Vector2.ONE * fit, POPUP_CRIT_PUNCH_SEC)
	tween.tween_property(root, "position:y", root.position.y - POPUP_RISE_PX, POPUP_RISE_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "modulate:a", 0.0, POPUP_DURATION_SEC - POPUP_FADE_DELAY_SEC).set_delay(POPUP_FADE_DELAY_SEC)
	tween.finished.connect(_on_crit_negation_popup_finished.bind(root))


func _make_popup_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", POPUP_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE_STRONG)
	label.add_theme_constant_override("outline_size", 5)
	preload("res://scripts/ui/combat_gold_text_icon.gd").decorate(label)
	return label


func _spawn_position(kind: int, label_size: Vector2) -> Vector2:
	if kind == Kind.POISON_TICK and _combat_stage != null:
		var enemy_local: Vector2 = get_global_transform().affine_inverse() * _combat_stage.enemy_popup_global_position()
		return Vector2(
			enemy_local.x - label_size.x * 0.5 + _rng.randf_range(-POPUP_POISON_TICK_JITTER_X_PX, POPUP_POISON_TICK_JITTER_X_PX),
			maxf(enemy_local.y - label_size.y * 0.5 + _rng.randf_range(-POPUP_POISON_TICK_JITTER_Y_PX, POPUP_POISON_TICK_JITTER_Y_PX), POPUP_TOP_MARGIN_PX)
		)
	return Vector2(
		_popup_area_size().x * 0.5 - label_size.x * 0.5 + _rng.randf_range(-POPUP_JITTER_X_PX, POPUP_JITTER_X_PX),
		maxf(_popup_area_size().y * POPUP_BASE_Y_FRACTION + _rng.randf_range(-POPUP_JITTER_Y_PX, POPUP_JITTER_Y_PX), POPUP_TOP_MARGIN_PX)
	)


func _popup_area_size() -> Vector2:
	if _combat_stage != null and _combat_stage.has_method("play_area_global_rect"):
		return _combat_stage.play_area_global_rect().size
	return size


func _on_popup_finished(label: Label, kind: int) -> void:
	_active_count = maxi(_active_count - 1, 0)
	if kind == Kind.POISON_TICK:
		_active_tick_count = maxi(_active_tick_count - 1, 0)
	label.queue_free()


func _on_crit_negation_popup_finished(root: Control) -> void:
	_active_count = maxi(_active_count - 1, 0)
	root.queue_free()


func _on_gold_hit_popup_finished(root: Control) -> void:
	_active_count = maxi(_active_count - 1, 0)
	root.queue_free()


func _poison_tick_font_size() -> int:
	return POPUP_WYVERN_TICK_FONT_SIZE if wyvern_tick_font_active else POPUP_TICK_FONT_SIZE


func _visible_popup_count(ticks_only: bool = false) -> int:
	var count := 0
	for popup in get_children():
		if popup is Control and popup.visible and not popup.is_queued_for_deletion() and not popup.has_meta("retrigger_hit"):
			if not ticks_only or popup.get_meta("cue_lane",-1) == 2: count += 1
	return count
