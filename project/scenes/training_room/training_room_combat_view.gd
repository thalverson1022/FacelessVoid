class_name TrainingRoomCombatView
extends PanelContainer
const PopupLayout = preload("res://scripts/ui/combat_popup_layout.gd")
## Practice Room's own animated combat area (user-requested "blank area where
## we show the combat animations, like in Adventure mode"). Built directly on
## `CombatPlayback` (project/scripts/ui/combat_playback.gd -- already
## logic-only and BuildState-free) as a fresh, self-contained rendering
## surface, rather than extracting combat_screen.gd's playback rendering
## (HP bar/popups/HUD/speed controls, ~500 lines entangled with its own
## outcome-reveal/reward-claim code across a 2685-line file). That refactor
## remains a reasonable future cleanup once both screens' playback views
## exist, but duplicating a small rendering surface here is lower-risk than
## touching Adventure's already-playtested combat screen and its 3 existing
## whole-scene tests. No BuildState reference anywhere in this file.
##
## Visual design mirrors combat_screen.gd's popup/HUD/speed-control approach,
## but this is independent code against its own `CombatPlayback` instance --
## combat still resolves synchronously and completely inside
## `CombatResolver.resolve()` before `play()` is ever called; this class only
## re-plays the recorded timeline in real time. Unlike combat_screen.gd,
## there's no HP bar here at all (post-R10 UI-feedback pass) -- Practice Room
## only measures damage dealt in a fixed window, never whether the target is
## "killed", so a running Damage Dealt readout replaces it.

signal finished

## Tall enough to match Adventure's M5 combat-window treatment: the fight/log
## action row now lives inside this panel, with the animation stage reserved
## above it instead of letting controls sit below the window.
const PANEL_MIN_HEIGHT := 520
const POPUP_FONT := preload("res://assets/fonts/PirataOne-Regular.ttf")
const POPUP_LIFETIME_SEC := 1.35
const POPUP_RISE_PX := 24.0
const POPUP_RISE_SEC := 1.05
const POPUP_TICK_RISE_SEC := 1.5
const POPUP_FADE_DELAY_SEC := 0.45
const POPUP_JITTER_X_FRACTION := 0.36
const POPUP_JITTER_Y_PX := 28.0
const POPUP_FONT_SIZE := 36
const POPUP_CRIT_FONT_SIZE := 48
const POPUP_TICK_FONT_SIZE := 18
const POPUP_WYVERN_TICK_FONT_SIZE := 14
const POPUP_PROC_FONT_SIZE := 40
const POPUP_CRIT_PUNCH_SCALE := 1.25
const POPUP_CRIT_PUNCH_SEC := 0.12
const POPUP_NEGATED_ACTUAL_FONT_SIZE := 38
const POPUP_NEGATED_GAP_PX := 14.0
const GOLD_POPUP_ICON_SIZE := Vector2(42.0, 42.0)
const POPUP_POISON_TICK_JITTER_X_PX := 28.0
const POPUP_POISON_TICK_JITTER_Y_PX := 12.0
const SPEED_OPTIONS := [1.0, 2.0, 4.0]
const OUTCOME_REVEAL_HOLD_SEC := 0.35

## User-supplied background art, replacing the earlier black placeholder.
## Same TextureRect+tint approach as combat_screen.gd's tavern background
## (EXPAND_IGNORE_SIZE/STRETCH_KEEP_ASPECT_COVERED so it fills the panel
## without distortion). Practice Room uses a slightly darker black tint than
## Adventure because the workshop background is busier behind the actors.
const BACKGROUND_TEXTURE := preload("res://assets/backgrounds/Training_Room_background.jpg")
const BACKGROUND_TINT := Color(0, 0, 0, 0.66)
const COMBAT_STAGE_SCRIPT := preload("res://scripts/ui/combat_stage.gd")
const COMBAT_STATUS_ICONS := preload("res://scripts/ui/combat_status_icons.gd")
const PRACTICE_TARGET_VISUAL_NAME := "Practice Target"
const COMBAT_STATUS_ICON_SIZE := Vector2(22, 22)
const COMBAT_STATUS_FONT_SIZE := 24
const UI_CLOCK_ICON_PATH := "res://assets/ui/icons/clock.png"
const FIGHT_TIMER_ICON_SIZE := Vector2(28, 28)
const FIGHT_TIMER_FONT_SIZE := 26
const FIGHT_TIMER_BADGE_SIZE := Vector2(112, 46)
const HUD_TOP_LANE_HEIGHT := 200.0
static var HUD_ARMOR_ICON: Texture2D = GameIcons.icon_for("defense.armor")
static var HUD_RESISTANCE_ICON: Texture2D = GameIcons.icon_for("defense.resistance")
const HUD_DAMAGE_ICON_PATH := "res://assets/combat_ui_icons/damage_sword.png"
static var HUD_POISON_ICON: Texture2D = GameIcons.icon_for("status.poison")
static var HUD_SHRED_ICON: Texture2D = GameIcons.icon_for("status.shred")
static var HUD_DECAY_ICON: Texture2D = GameIcons.icon_for("status.decay")
static var MECHANIC_DODGE_ICON: Texture2D = GameIcons.icon_for("defense.dodge")
static var MECHANIC_CRIT_NEGATION_ICON: Texture2D = GameIcons.icon_for("defense.crit_negation")
static var MECHANIC_BLOCK_ICON: Texture2D = GameIcons.icon_for("defense.block")
static var MECHANIC_ABSORB_ICON: Texture2D = GameIcons.icon_for("defense.absorb")
static var MECHANIC_CLEANSE_ICON: Texture2D = GameIcons.icon_for("defense.cleanse")
static var MECHANIC_SUPPRESS_ICON: Texture2D = GameIcons.icon_for("defense.suppress")
static var MECHANIC_SLOW_ICON: Texture2D = GameIcons.icon_for("defense.slow")
static var MECHANIC_STUN_ICON: Texture2D = GameIcons.icon_for("defense.stun")
static var MECHANIC_INTERRUPT_ICON: Texture2D = GameIcons.icon_for("defense.interrupt")


class CritCrossOutOverlay:
	extends Control

	const LINE_COLOR := Color(1.0, 0.08, 0.05, 0.96)
	const LINE_OUTLINE := Color(0.16, 0.0, 0.0, 0.88)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var pad := 6.0
		var start := Vector2(pad, size.y - pad)
		var finish := Vector2(size.x - pad, pad)
		draw_line(start, finish, LINE_OUTLINE, 8.0, true)
		draw_line(start, finish, LINE_COLOR, 5.0, true)

## Same headless-detection instant-mode pattern combat_screen.gd uses so
## headless tests don't have to wait out a real-time animation.
var _instant_playback: bool = DisplayServer.get_name() == "headless"
var _playback: CombatPlayback = null
var _presentation_owner: Object
var _owned_presentation_model
var _playback_intro_remaining_sec := 0.0
var _playback_intro_duration_sec := 0.0
## Running damage total for the current fight (post-R10 UI-feedback pass:
## Practice Room only measures damage dealt in a fixed window, it never
## tracks the target's remaining HP -- there's no "killing" it here at all).
var _damage_dealt := 0.0
var _health_removed := 0.0
var _health_removed_label: Label
## Real-time armor/poison-resist/poison-stack tracking (user-requested,
## mirrors combat_screen.gd's _playback_armor/_playback_resist/
## _playback_stacks/_playback_armor_reduced) -- _armor and _monster's base
## resistance never changes after being set in play(); the *_reduced/
## _resist/_stacks fields accumulate per-cast the same way
## combat_screen.gd's _on_playback_event() does, so the player can watch
## these mechanics change live instead of only seeing the final numbers.
var _monster: Monster = null
var _current_result: CombatResolver.CombatResult = null
var _effect_icons: CombatEffectIcons
var _armor := 0
var _armor_reduced := 0
var _shred_value := 10
var _decay_value := 0.2
var _poison_base_damage := 8.0
var _shred_stacks := 0
var _decay_stacks := 0
var _resist := 0.0
var _stacks := 0
var _interrupt_repeat_count := 0
var _interrupt_skill_lock_counts := {}

var _name_label: Label
var _damage_label: Label
var _info_label: Label
var _resist_label: Label
var _mechanic_row: FlowContainer
var _status_row: HBoxContainer
var _fight_timer_badge: PanelContainer
var _clock_frost: Control
var _fight_timer_label: Label
var _combat_stage
var _category_preview
var _popup_layer: Control
var _content: VBoxContainer
var _controls_row: PlaybackControls
var _speed_buttons: Array[Button] = []
var _skip_button: Button
var _last_speed: float = SPEED_OPTIONS[0]
var _fight_window_ms := TrainingRoomState.DEFAULT_DURATION_MS
var _popup_generation := 0
var _wyvern_kriss_effect_active := false
var _playback_skipping := false
var _skip_playback_on_fight := false
var _pending_action_row: Control = null
var skill_build_panel = null
var gold_stolen_callback: Callable = Callable()
var _pending_cleanse_status_flash := false
var status_chip_flash_count := 0


func _ready() -> void:
	# Near-black fallback fill (matches combat_screen.gd's own
	# UIColors.PANEL_DEEP under its tavern background) -- mostly hidden
	# behind the background art below, visible only at the panel's edges/
	# before the texture would show through any transparency.
	var style := CardStyle.make_stylebox()
	style.bg_color = UIColors.PANEL_DEEP
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(0, PANEL_MIN_HEIGHT)
	set_process(false)

	var background := TextureRect.new()
	background.name = "Background"
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var background_tint := ColorRect.new()
	background_tint.name = "BackgroundTint"
	background_tint.color = BACKGROUND_TINT
	background_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background_tint)

	_combat_stage = COMBAT_STAGE_SCRIPT.new()
	_combat_stage.name = "CombatStage"
	_combat_stage.safe_top_px = 186.0
	_combat_stage.safe_bottom_px = 96.0
	_combat_stage.debug_grid_visible = false
	add_child(_combat_stage)
	_combat_stage.configure("Rogue", "Practice Target")
	_combat_stage.reset_state()
	if _category_preview == null:
		_category_preview = preload("res://scripts/ui/skill_category_preview.gd").new()
		_category_preview.screen = self
		_category_preview.practice_view = true
		add_child(_category_preview)
	else:
		_category_preview.clear()

	var content := VBoxContainer.new()
	# Keep HUD and actions above actor art when the editor reserves more space.
	content.z_index = 20
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 6)
	add_child(content)
	_content = content

	var hud_lane := Control.new()
	hud_lane.name = "CombatHudLane"
	hud_lane.custom_minimum_size = Vector2(0, HUD_TOP_LANE_HEIGHT)
	content.add_child(hud_lane)

	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.text = "Practice Target"
	_name_label.visible = false
	_name_label.anchor_left = 0.0
	_name_label.anchor_right = 0.0
	_name_label.anchor_top = 0.0
	_name_label.anchor_bottom = 0.0
	_name_label.offset_left = 0.0
	_name_label.offset_right = 260.0
	_name_label.offset_top = 12.0
	_name_label.offset_bottom = 36.0
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_lane.add_child(_name_label)

	var values_row := HBoxContainer.new()
	values_row.name = "CombatValuesRow"
	values_row.add_theme_constant_override("separation", 14)
	values_row.alignment = BoxContainer.ALIGNMENT_END
	values_row.anchor_left = 1.0
	values_row.anchor_right = 1.0
	values_row.anchor_top = 0.0
	values_row.anchor_bottom = 0.0
	values_row.offset_left = -360.0
	values_row.offset_right = 0.0
	values_row.offset_top = 42.0
	values_row.offset_bottom = 70.0
	hud_lane.add_child(values_row)

	_damage_label = Label.new()
	_damage_label.name = "DamageLabel"
	_damage_label.add_theme_font_size_override("font_size", COMBAT_STATUS_FONT_SIZE)
	var damage_icon := TextureRect.new()
	damage_icon.name = "DamageIcon"
	damage_icon.texture = _damage_icon_texture()
	damage_icon.custom_minimum_size = COMBAT_STATUS_ICON_SIZE
	damage_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	damage_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	damage_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	values_row.add_child(damage_icon)
	values_row.add_child(_damage_label)

	var armor_icon := TextureRect.new()
	armor_icon.name = "ArmorIcon"
	armor_icon.texture = HUD_ARMOR_ICON
	armor_icon.custom_minimum_size = COMBAT_STATUS_ICON_SIZE
	armor_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	armor_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	armor_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	armor_icon.tooltip_text = "Armor: Reduces Physical Damage"
	values_row.add_child(armor_icon)

	_info_label = Label.new()
	_info_label.name = "InfoLabel"
	_info_label.tooltip_text = armor_icon.tooltip_text
	_info_label.add_theme_font_size_override("font_size", COMBAT_STATUS_FONT_SIZE)
	values_row.add_child(_info_label)

	var poison_resist_icon := TextureRect.new()
	poison_resist_icon.name = "PoisonResistIcon"
	poison_resist_icon.texture = HUD_RESISTANCE_ICON
	poison_resist_icon.custom_minimum_size = COMBAT_STATUS_ICON_SIZE
	poison_resist_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	poison_resist_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	poison_resist_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	poison_resist_icon.tooltip_text = "Resistance: Reduces elemental damage"
	values_row.add_child(poison_resist_icon)

	_resist_label = Label.new()
	_resist_label.name = "ResistText"
	_resist_label.tooltip_text = poison_resist_icon.tooltip_text
	_resist_label.add_theme_font_size_override("font_size", COMBAT_STATUS_FONT_SIZE)
	values_row.add_child(_resist_label)

	_mechanic_row = FlowContainer.new()
	_mechanic_row.name = "MechanicIconRow"
	_mechanic_row.alignment = FlowContainer.ALIGNMENT_END
	_mechanic_row.anchor_left = 1.0
	_mechanic_row.anchor_right = 1.0
	_mechanic_row.anchor_top = 0.0
	_mechanic_row.anchor_bottom = 0.0
	_mechanic_row.offset_left = -520.0
	_mechanic_row.offset_right = 0.0
	_mechanic_row.offset_top = 84.0
	_mechanic_row.offset_bottom = 110.0
	_mechanic_row.add_theme_constant_override("h_separation", 8)
	_mechanic_row.add_theme_constant_override("v_separation", 2)
	hud_lane.add_child(_mechanic_row)

	_status_row = HBoxContainer.new()
	_status_row.name = "StatusRow"
	_status_row.alignment = BoxContainer.ALIGNMENT_END
	_status_row.anchor_left = 0.0
	_status_row.anchor_right = 1.0
	_status_row.anchor_top = 0.0
	_status_row.anchor_bottom = 0.0
	_status_row.offset_left = 0.0
	_status_row.offset_right = 0.0
	_status_row.offset_top = 128.0
	_status_row.offset_bottom = 190.0
	_status_row.add_theme_constant_override("separation", 8)
	hud_lane.add_child(_status_row)
	_health_removed_label = Label.new()
	_health_removed_label.name = "HealthRemovedLabel"
	_health_removed_label.position = Vector2(4, 32)
	_health_removed_label.add_theme_font_size_override("font_size", 20)
	_health_removed_label.add_theme_color_override("font_color", UIColors.TEXT_MAGIC)
	_health_removed_label.tooltip_text = "Direct health removal is separate from damage and DPS."
	hud_lane.add_child(_health_removed_label)
	_effect_icons = CombatEffectIcons.new()
	_effect_icons.name = "TemporaryEffectIcons"
	_effect_icons.motion_changed.connect(_on_motion_changed)
	hud_lane.add_child(_effect_icons)
	_effect_icons.position = Vector2(4, 60)
	_effect_icons.z_index = 25
	_update_damage_label()
	_update_status_readout()

	var timer_cell := Control.new()
	timer_cell.name = "FightTimerCell"
	timer_cell.custom_minimum_size = FIGHT_TIMER_BADGE_SIZE
	timer_cell.anchor_left = 0.5
	timer_cell.anchor_right = 0.5
	timer_cell.anchor_top = 0.0
	timer_cell.anchor_bottom = 0.0
	timer_cell.offset_left = -FIGHT_TIMER_BADGE_SIZE.x * 0.5
	timer_cell.offset_right = FIGHT_TIMER_BADGE_SIZE.x * 0.5
	timer_cell.offset_top = 8.0
	timer_cell.offset_bottom = 8.0 + FIGHT_TIMER_BADGE_SIZE.y
	timer_cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_lane.add_child(timer_cell)
	timer_cell.add_child(_build_fight_timer_badge())

	_controls_row = PlaybackControls.new()
	_controls_row.name = "PlaybackControls"
	_controls_row.anchor_left = 1.0
	_controls_row.anchor_right = 1.0
	_controls_row.anchor_top = 0.0
	_controls_row.anchor_bottom = 0.0
	_controls_row.offset_left = -395.0
	_controls_row.offset_right = 0.0
	_controls_row.offset_top = 6.0
	_controls_row.offset_bottom = 34.0
	_controls_row.alignment = BoxContainer.ALIGNMENT_END
	_controls_row.speed_selected.connect(_set_speed)
	_controls_row.skip_pressed.connect(_on_playback_skip_pressed)
	hud_lane.add_child(_controls_row)
	_speed_buttons = _controls_row._speed_buttons
	_skip_button = _controls_row._skip_button

	# Popups spawn and animate here, over the background art -- no
	# character/monster sprites yet (no such assets exist in the project;
	# matches combat_screen.gd's own tavern-background-only approach).
	_popup_layer = Control.new()
	_popup_layer.name = "PopupLayer"
	_popup_layer.set_meta("target_near_poison_ticks", true)
	_popup_layer.z_index = 35
	_popup_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_popup_layer)
	if _pending_action_row != null:
		add_action_row(_pending_action_row)
		_pending_action_row = null
	set_fight_window_ms(_fight_window_ms)


func add_action_row(row: Control) -> void:
	if row == null:
		return
	if _content == null:
		_pending_action_row = row
		return
	if row.get_parent() != null:
		row.get_parent().remove_child(row)
	_content.add_child(row)
	_popup_layer.set_meta("footer_row", row)
	var bottom_spacer := Control.new()
	bottom_spacer.name = "ActionRowBottomSpacer"
	bottom_spacer.custom_minimum_size = Vector2(0, 14)
	_content.add_child(bottom_spacer)


func set_fight_window_ms(window_ms: int) -> void:
	_fight_window_ms = maxi(window_ms, 1000)
	if _playback == null:
		_refresh_fight_timer_badge()


func set_target_preview(monster: Monster) -> void:
	if monster == null:
		return
	if _playback != null:
		return
	_monster = monster
	_armor = monster.armor
	_armor_reduced = 0
	_shred_stacks = 0
	_decay_stacks = 0
	_resist = monster.poison_resistance
	_stacks = 0
	_interrupt_repeat_count = 0
	_update_status_readout()


func _build_fight_timer_badge() -> PanelContainer:
	var badge := PanelContainer.new()
	badge.name = "FightTimerBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.custom_minimum_size = FIGHT_TIMER_BADGE_SIZE
	var badge_style := CardStyle.make_stylebox(8)
	badge_style.bg_color = UIColors.BADGE_BACKDROP
	badge_style.border_color = UIColors.PANEL_BORDER
	badge_style.content_margin_left = 10
	badge_style.content_margin_right = 12
	badge_style.content_margin_top = 4
	badge_style.content_margin_bottom = 6
	badge.add_theme_stylebox_override("panel", badge_style)
	_fight_timer_badge = badge
	_clock_frost = preload("res://scripts/ui/combat_clock_frost.gd").new()
	badge.add_child(_clock_frost)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	badge.add_child(row)

	var icon := CardStyle.make_pixel_icon(_clock_icon_texture(), FIGHT_TIMER_ICON_SIZE)
	icon.name = "ClockIcon"
	row.add_child(icon)

	_fight_timer_label = Label.new()
	_fight_timer_label.name = "FightTimerLabel"
	_fight_timer_label.text = "0s"
	_fight_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fight_timer_label.add_theme_font_size_override("font_size", FIGHT_TIMER_FONT_SIZE)
	_fight_timer_label.add_theme_color_override("font_color", UIColors.TEXT_NORMAL)
	_fight_timer_label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE_STRONG)
	_fight_timer_label.add_theme_constant_override("outline_size", 4)
	row.add_child(_fight_timer_label)
	return badge


func _clock_icon_texture() -> Texture2D:
	return load(UI_CLOCK_ICON_PATH) as Texture2D


func _damage_icon_texture() -> Texture2D:
	var texture := load(HUD_DAMAGE_ICON_PATH) as Texture2D
	if texture != null:
		texture.resource_name = "PracticeDamageSwordIcon"
	return texture


func _refresh_fight_timer_badge() -> void:
	if _fight_timer_label == null:
		return
	_fight_timer_label.text = _format_fight_timer_ms(_fight_window_ms, false)


func _update_fight_timer_countdown() -> void:
	if _fight_timer_label == null or _playback == null:
		return
	var remaining_ms := _playback.countdown_remaining_ms()
	_fight_timer_label.text = _format_fight_timer_ms(roundi(remaining_ms), true)


func _format_fight_timer_ms(time_ms: int, show_decimal: bool) -> String:
	var seconds := maxf(0.0, float(time_ms) / 1000.0)
	if show_decimal:
		return "%.1fs" % seconds
	return "%ds" % ceili(seconds)


## Starts animating `result` against `monster`'s Armor/Resist --
## `result` is already a fully-resolved CombatResolver.CombatResult; this
## never re-resolves combat, only re-plays its recorded timeline. Emits
## `finished` when the animation (or, in headless/instant mode, the
## immediate skip) completes.
func play(result: CombatResolver.CombatResult, monster: Monster, equipped_gear: Array[GearItem] = [], shred_value: int = 10, effective_slow: float = -1.0, poison_base_damage: float = 8.0, decay_value: float = 0.2) -> void:
	_cancel_combat_audio()
	_monster = monster
	_current_result = result
	_clock_frost.set_active(result.countdown_rate < 1.0 and not _instant_playback)
	_shred_value = shred_value
	_poison_base_damage = poison_base_damage
	_decay_value = decay_value
	var slow := monster.slow if effective_slow < 0.0 else effective_slow
	_damage_dealt = 0.0
	_health_removed = 0.0
	_popup_generation += 1
	_playback_skipping = false
	_name_label.text = monster.display_name
	_update_damage_label()
	_armor = monster.armor
	_armor_reduced = 0
	_shred_stacks = 0
	_decay_stacks = 0
	_resist = monster.poison_resistance
	_stacks = 0
	_interrupt_repeat_count = 0
	_interrupt_skill_lock_counts.clear()
	_wyvern_kriss_effect_active = _gear_has_id(equipped_gear, "gear.legendary.wyvern_kriss")
	_update_status_readout()
	_category_preview.clear()
	_combat_stage.configure("Rogue", monster.display_name, PRACTICE_TARGET_VISUAL_NAME, monster.combat_role)
	_combat_stage.set_bandit_blade_effect_active(_gear_has_id(equipped_gear, _combat_stage.BANDIT_BLADE_ID))
	_combat_stage.reset_state()
	_combat_stage.configure_legendary_effects(result.presentation_initial.get("legendary_visuals", {}))
	_combat_stage.set_slow_effect_active(slow > 0.0, slow, not _instant_playback and not CombatEffectIcons.reduced_motion)
	if skill_build_panel != null and skill_build_panel.has_method("clear_combat_highlight"):
		skill_build_panel.clear_combat_highlight()
	if skill_build_panel != null and skill_build_panel.has_method("clear_interrupt_locks"):
		skill_build_panel.clear_interrupt_locks()
	if skill_build_panel != null and skill_build_panel.has_method("set_slow_effect_active"):
		skill_build_panel.set_slow_effect_active(slow > 0.0)
	if skill_build_panel != null and skill_build_panel.has_method("clear_stun_effect"):
		skill_build_panel.clear_stun_effect()
	if skill_build_panel != null and skill_build_panel.has_method("set_combat_interaction_locked"):
		skill_build_panel.set_combat_interaction_locked(true)
	for child in _popup_layer.get_children():
		child.queue_free()

	_playback = CombatPlayback.new()
	_playback.event_callback = _on_playback_event
	_playback.cast_start_callback = _on_playback_cast_start
	_playback.finished_callback = _on_playback_finished
	_playback.start(result)
	if skill_build_panel != null: skill_build_panel.clear_presentation()
	_effect_icons.begin(result)
	if skill_build_panel != null:
		skill_build_panel.state.set_meta("combat_presentation", _effect_icons.model)
		_presentation_owner = skill_build_panel.state
		_owned_presentation_model = _effect_icons.model
	_playback_intro_duration_sec = _combat_stage.play_fight_intro(not _instant_playback and not CombatEffectIcons.reduced_motion) if _combat_stage != null else 0.0
	_playback_intro_remaining_sec = _playback_intro_duration_sec
	_fight_window_ms = _playback.nominal_window_ms()

	if _instant_playback:
		_playback_intro_remaining_sec = 0.0
		_playback.skip()
		return

	_set_speed(_last_speed, false)
	_update_time_label()
	set_process(true)
	if _skip_playback_on_fight:
		_skip()


func _process(delta: float) -> void:
	if _playback == null:
		return
	if _playback_intro_remaining_sec > 0.0:
		var playback_speed := maxf(_playback.speed, 0.0)
		var intro_advance := delta * playback_speed
		if intro_advance < _playback_intro_remaining_sec:
			_playback_intro_remaining_sec -= intro_advance
			_update_time_label()
			return
		var overflow_delta := 0.0
		if playback_speed > 0.0:
			overflow_delta = (intro_advance - _playback_intro_remaining_sec) / playback_speed
		_playback_intro_remaining_sec = 0.0
		if overflow_delta <= 0.0:
			_update_time_label()
			return
		delta = overflow_delta
	_playback.advance(delta)
	if _playback != null:
		_effect_icons.advance_to(int(_playback.elapsed_ms()), _playback.record_frontier())
		_sync_presentation()
	_update_macro_cast_progress()
	if _playback != null:
		_update_time_label()


func _on_playback_event(event: CombatPlayback.PlaybackEvent) -> void:
	_effect_icons.advance_to(event.time_ms, event.sequence if event.sequence > 0 else 9223372036854775807)
	_damage_dealt += event.damage
	_health_removed += event.health_removed
	_update_damage_label()
	if event.is_tick:
		# The tick's own stacks_remaining is authoritative (CombatResolver
		# consumes exactly one stack per tick when stacks are active) --
		# matches combat_screen.gd's _on_playback_event(), and fixes a real
		# gap here where stacks previously only ever increased from casts
		# and never reflected a tick consuming one.
		_stacks = event.tick.stacks_remaining
		_combat_stage.set_poison_stacks(_stacks, not _instant_playback and not _playback_skipping and not CombatEffectIcons.reduced_motion)
		_update_status_readout()
		# A cadence beat with no active stacks still fires (fixed cadence
		# independent of stacks, per CombatResolver.resolve()) but has no
		# absorbed amount either. Fully absorbed ticks are still real hits and
		# should animate/log as 0 damage.
		if event.tick.had_active_stack:
			_combat_stage.play_poison_tick_pulse(not _instant_playback and event.chain_count <= 1 and not CombatEffectIcons.reduced_motion)
			_combat_stage.play_poison_retrigger_event(event, _playback.speed if _playback != null else 1.0, not _instant_playback and not _playback_skipping and not CombatEffectIcons.reduced_motion)
			if event.tick.keyword_consume:
				_combat_stage.play_legendary_poison_consume(not _instant_playback and not _playback_skipping and not CombatEffectIcons.reduced_motion)
			if event.chain_count <= 1 or event.tick.stacks_preserved: _spawn_popup(event)
		_sync_presentation()
		return
	var cast := event.cast
	if event.chain_count <= 1 and _category_preview.handles(cast):
		_category_preview.activate(cast,_playback.speed if _playback != null else _last_speed,not _instant_playback and not _playback_skipping)
	if cast.gold_stolen > 0 and gold_stolen_callback.is_valid():
		gold_stolen_callback.call(cast.gold_stolen)
	var popup_delay := 0.0
	if event.chain_count > 1 and not _instant_playback and not _playback_skipping:
		_combat_stage.play_retrigger_event(event, _playback.speed, not CombatEffectIcons.reduced_motion)
	elif not cast.cooldown_blocked and not cast.resource_unavailable and not _category_preview.handles(cast):
		popup_delay = _combat_stage.play_cast_impact(cast, not _instant_playback and not _playback_skipping and not CombatEffectIcons.reduced_motion)
	if event.chain_count <= 1 and _category_preview.handles(cast):
		_combat_stage.play_legendary_cast_effect(cast, not _instant_playback and not _playback_skipping and not CombatEffectIcons.reduced_motion)
	if not _instant_playback and not _playback_skipping:
		var audio_manager := get_node_or_null("/root/AudioManager")
		if audio_manager != null and audio_manager.has_method("play_skill_sfx_for_cast"):
			audio_manager.play_skill_sfx_for_cast(cast, _playback.speed, false, event.chain_count > 1, event.visual_beat)
	if not cast.triggered_skill_names.is_empty() and skill_build_panel != null and skill_build_panel.has_method("highlight_rotation_index"):
		skill_build_panel.highlight_rotation_index(cast.rotation_index, true)
	_armor_reduced += cast.armor_reduction_applied
	_shred_stacks += cast.shred_stacks_applied
	if cast.poison_resistance_reduction_applied > 0.0:
		_resist *= 1.0 - clampf(cast.poison_resistance_reduction_applied, 0.0, 1.0)
		_decay_stacks += cast.decay_stacks_applied
	_stacks = mini(_stacks + cast.poison_stacks_applied, _poison_stack_cap())
	if cast.poison_stacks_applied > 0:
		_combat_stage.set_poison_stacks(_stacks, not _instant_playback and not _playback_skipping and not CombatEffectIcons.reduced_motion)
	if cast.cleanse_triggered:
		_armor_reduced = 0
		_shred_stacks = 0
		_decay_stacks = 0
		_resist = _monster.poison_resistance
		_stacks = 0
		_combat_stage.set_poison_stacks(_stacks, not _instant_playback and not _playback_skipping and not CombatEffectIcons.reduced_motion)
		_combat_stage.play_cleanse_effect(not _instant_playback and not _playback_skipping and not CombatEffectIcons.reduced_motion)
		_pending_cleanse_status_flash = true
	if cast.stun_duration_ms > 0 and _combat_stage != null:
		_combat_stage.play_stun_effect(cast.stun_duration_ms, not _instant_playback and not _playback_skipping and not CombatEffectIcons.reduced_motion, event.chain_count > 1 and event.chain_index > 1)
	if cast.stun_duration_ms > 0 and skill_build_panel != null and skill_build_panel.has_method("play_stun_effect"):
		skill_build_panel.play_stun_effect(cast.stun_duration_ms, not _instant_playback and not _playback_skipping and not CombatEffectIcons.reduced_motion, _playback.speed if _playback != null else _last_speed)
	_update_interrupt_skill_lock(cast)
	_interrupt_repeat_count = cast.interrupt_repeat_count_after if _monster != null and _monster.interrupt_skip_count > 0 else 0
	_update_status_readout()
	if event.chain_count <= 1 or event.chain_index == 1:
		_schedule_cast_popup(event, popup_delay)
	elif event.visual_beat and not _playback_skipping and not _instant_playback and not CombatEffectIcons.reduced_motion and not _is_hold_cast(cast):
		_spawn_retrigger_popup(event)
	_sync_presentation()


func _on_playback_cast_start(cast: CombatResolver.CastEvent) -> void:
	if _playback_skipping:
		return
	if _category_preview.handles(cast) and not cast.cooldown_blocked and not cast.resource_unavailable:
		if not _instant_playback: _category_preview.windup(cast, _playback.speed if _playback != null else _last_speed)
	elif _combat_stage != null and not cast.cooldown_blocked and not cast.resource_unavailable:
		_combat_stage.play_cast_windup(cast, _playback.speed if _playback != null else _last_speed, not _instant_playback and not CombatEffectIcons.reduced_motion)
	if skill_build_panel != null and skill_build_panel.has_method("set_cast_progress"):
		skill_build_panel.set_cast_progress(cast.rotation_index, 0.0, cast.min_cast_time_proc_applied)


func _update_interrupt_skill_lock(cast: CombatResolver.CastEvent) -> void:
	if cast == null or cast.skill == null or skill_build_panel == null or not skill_build_panel.has_method("set_interrupt_locked_skill"):
		return
	var key := _skill_lock_key(cast.skill)
	if key == "":
		return
	if cast.interrupt_triggered and cast.interrupt_skip_count_applied > 0:
		_interrupt_skill_lock_counts[key] = cast.interrupt_skip_count_applied
		skill_build_panel.set_interrupt_locked_skill(cast.skill, true)
		return
	if cast.interrupt_skipped:
		var remaining := maxi(0, int(_interrupt_skill_lock_counts.get(key, 0)) - 1)
		if remaining <= 0:
			_interrupt_skill_lock_counts.erase(key)
			skill_build_panel.set_interrupt_locked_skill(cast.skill, false)
		else:
			_interrupt_skill_lock_counts[key] = remaining


func _skill_lock_key(skill: Skill) -> String:
	if skill == null:
		return ""
	if skill.id != "":
		return skill.id
	return skill.resource_path if skill.resource_path != "" else skill.display_name


func _update_macro_cast_progress() -> void:
	if _playback == null:
		return
	var cast := _playback.active_cast()
	if cast == null:
		return
	_category_preview.update_cast_progress(cast,_playback.active_cast_progress(),_playback.speed)
	if skill_build_panel != null and skill_build_panel.has_method("set_cast_progress"):
		skill_build_panel.set_cast_progress(cast.rotation_index, _playback.active_cast_progress(), cast.min_cast_time_proc_applied)


func _on_playback_finished() -> void:
	_clock_frost.set_active(false)
	_clear_retrigger_popups()
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null: audio.cancel_combat_sfx(false)
	if _category_preview != null: _category_preview.clear()
	_effect_icons.finish(_current_result)
	_update_status_readout()
	if skill_build_panel != null:
		skill_build_panel.clear_presentation()
	set_process(false)
	var was_skipping := _playback_skipping
	if _combat_stage != null and _combat_stage.has_method("restore_practice_idle_pose"):
		_combat_stage.restore_practice_idle_pose()
	_playback = null
	_current_result = null
	_playback_intro_remaining_sec = 0.0
	_playback_intro_duration_sec = 0.0
	_refresh_fight_timer_badge()
	if skill_build_panel != null and skill_build_panel.has_method("clear_combat_highlight"):
		skill_build_panel.clear_combat_highlight()
	if skill_build_panel != null and skill_build_panel.has_method("clear_interrupt_locks"):
		skill_build_panel.clear_interrupt_locks()
	if skill_build_panel != null and skill_build_panel.has_method("set_slow_effect_active"):
		skill_build_panel.set_slow_effect_active(false)
	if skill_build_panel != null and skill_build_panel.has_method("clear_stun_effect"):
		skill_build_panel.clear_stun_effect()
	if skill_build_panel != null and skill_build_panel.has_method("set_combat_interaction_locked"):
		skill_build_panel.set_combat_interaction_locked(false)
	_interrupt_skill_lock_counts.clear()
	if not _instant_playback and not was_skipping:
		await get_tree().create_timer(OUTCOME_REVEAL_HOLD_SEC).timeout
	finished.emit()


## Current armor and resistance stay in the defense readout; poison,
## Shred, and Decay application counts stay in the debuff row. Mirrors
## combat_screen.gd's _update_playback_hud_readout()/_add_hud_status_chip().
func _update_status_readout() -> void:
	_info_label.text = "%d" % (_armor - _armor_reduced)
	_resist_label.text = "%.0f%%" % (_resist * 100.0)
	_refresh_mechanic_row()
	for child in _status_row.get_children():
		_status_row.remove_child(child)
		child.queue_free()
	COMBAT_STATUS_ICONS.add_timed_defense_chips(_effect_icons.model if _effect_icons != null else null, _add_status_chip)
	_add_status_chip("x%d" % _stacks, UIColors.TEXT_POISON, HUD_POISON_ICON)
	_add_status_chip("x%d" % _shred_stacks, UIColors.TEXT_WARNING, HUD_SHRED_ICON, _shred_status_tooltip())
	_add_status_chip("x%d" % _decay_stacks, UIColors.TEXT_MAGIC, HUD_DECAY_ICON)
	_add_status_chip(_interrupt_status_text(), UIColors.TEXT_MAGIC, MECHANIC_INTERRUPT_ICON)
	if _pending_cleanse_status_flash:
		_pending_cleanse_status_flash = false
		_flash_status_chips()


func _refresh_mechanic_row() -> void:
	if _mechanic_row == null:
		return
	for child in _mechanic_row.get_children():
		_mechanic_row.remove_child(child)
		child.queue_free()
	var monster := _monster if _monster != null else Monster.new()
	_add_mechanic_chip("block", MECHANIC_BLOCK_ICON, "%.0f" % monster.block, UIColors.TEXT_WARNING, _enemy_mechanic_tooltip("block", monster))
	_add_mechanic_chip("dodge_chance", MECHANIC_DODGE_ICON, "%.0f%%" % (monster.dodge_chance * 100.0), UIColors.TEXT_WARNING, _enemy_mechanic_tooltip("dodge_chance", monster))
	_add_mechanic_chip("crit_negation", MECHANIC_CRIT_NEGATION_ICON, "%.0f%%" % (monster.crit_negation * 100.0), UIColors.TEXT_WARNING, _enemy_mechanic_tooltip("crit_negation", monster))
	_add_mechanic_chip("absorb", MECHANIC_ABSORB_ICON, "%.0f" % monster.absorb, UIColors.TEXT_MAGIC, _enemy_mechanic_tooltip("absorb", monster))
	_add_mechanic_chip("suppress", MECHANIC_SUPPRESS_ICON, "%.0f%%" % (monster.suppress * 100.0), UIColors.TEXT_MAGIC, _enemy_mechanic_tooltip("suppress", monster))
	_add_mechanic_chip("slow", MECHANIC_SLOW_ICON, "%.0f%%" % (monster.slow * 100.0), UIColors.TEXT_MAGIC, _enemy_mechanic_tooltip("slow", monster))
	_add_mechanic_chip("cleanse_threshold", MECHANIC_CLEANSE_ICON, "%d" % monster.cleanse_threshold, UIColors.TEXT_POISON, _enemy_mechanic_tooltip("cleanse_threshold", monster))
	_add_mechanic_chip("stun_duration_ms", MECHANIC_STUN_ICON, _format_stun_duration(monster.stun_duration_ms), UIColors.TEXT_MAGIC, _enemy_mechanic_tooltip("stun_duration_ms", monster))


func _add_mechanic_chip(effect_id: String, icon: Texture2D, text: String, color: Color, tooltip: String) -> void:
	var chip: HBoxContainer = COMBAT_STATUS_ICONS.add_icon_label(_mechanic_row, icon, text, color, "MechanicChip")
	chip.set_meta("effect_id", effect_id)
	chip.tooltip_text = tooltip


func _interrupt_status_text() -> String:
	if _monster == null or _monster.interrupt_skip_count <= 0:
		return "0/0"
	return "%d/%d" % [_interrupt_repeat_count, CombatResolver.INTERRUPT_REPEAT_THRESHOLD]


func _add_status_chip(text: String, color: Color, icon: Texture2D = null, tooltip: String = "", countdown: float = -1.0) -> void:
	if tooltip == "":
		tooltip = _status_chip_tooltip(icon)
	if icon != null:
		var icon_chip: HBoxContainer = COMBAT_STATUS_ICONS.add_status_icon_label(_status_row, icon, text, color, countdown)
		if tooltip != "":
			icon_chip.tooltip_text = tooltip
		return
	var chip := Label.new()
	chip.name = "StatusChip"
	chip.text = text
	chip.add_theme_color_override("font_color", color)
	chip.add_theme_font_size_override("font_size", COMBAT_STATUS_FONT_SIZE)
	_status_row.add_child(chip)


func _shred_status_tooltip() -> String:
	return "Shred: Each stack reduces armor by %d" % _shred_value


func _status_chip_tooltip(icon: Texture2D) -> String:
	if icon == HUD_POISON_ICON:
		return "Poison: Deals %.1f damage every 1.0s" % _poison_base_damage
	if icon == HUD_SHRED_ICON:
		return _shred_status_tooltip()
	if icon == HUD_DECAY_ICON:
		return "Decay: Each stack reduces resistance by %.0f%%" % (_decay_value * 100.0)
	if icon == MECHANIC_INTERRUPT_ICON:
		return _interrupt_status_tooltip(_monster)
	return ""


func _interrupt_status_tooltip(monster: Monster) -> String:
	var prevented := monster.interrupt_skip_count if monster != null else 0
	return "Interrupt: Casting %d times prevents next %d casts" % [CombatResolver.INTERRUPT_REPEAT_THRESHOLD, prevented]


func _poison_stack_cap() -> int:
	if _current_result == null:
		return CombatResolver.MAX_POISON_STACKS
	return maxi(1, _current_result.poison_stack_cap)


func _enemy_mechanic_tooltip(effect_id: String, monster: Monster) -> String:
	match effect_id:
		"block":
			return "Block: Prevents %.0f physical damage" % monster.block
		"dodge_chance":
			return "Dodge: %.0f%% chance for cast to miss" % (monster.dodge_chance * 100.0)
		"crit_negation":
			return "Crit Negation: Reduces crits by %.0f%%" % (monster.crit_negation * 100.0)
		"absorb":
			return "Absorb: Prevents %.0f elemental damage" % monster.absorb
		"suppress":
			return "Suppress: Damage over time ticks %.0f%% slower" % (monster.suppress * 100.0)
		"slow":
			return "Slow: Reduces attack speed by %.0f%%" % (monster.slow * 100.0)
		"cleanse_threshold":
			return "Cleanse: Removes all debuffs after %d casts" % monster.cleanse_threshold
		"stun_duration_ms":
			return "Stun: Hitting for %.0f%% of total health in a single hit stuns for %s" % [CombatResolver.STUN_TRIGGER_HIT_PERCENT * 100.0, _format_stun_duration(monster.stun_duration_ms)]
	return ""


func _flash_status_chips() -> void:
	status_chip_flash_count += 1
	for child in _status_row.find_children("*", "HBoxContainer", true, false):
		var icon := child.get_node_or_null("Icon") as TextureRect
		if icon == null or not [HUD_POISON_ICON, HUD_SHRED_ICON, HUD_DECAY_ICON].has(icon.texture):
			continue
		child.modulate = Color.WHITE
		child.scale = Vector2.ONE
		child.pivot_offset = child.size * 0.5
		if _instant_playback:
			continue
		var tween := child.create_tween()
		tween.set_parallel(true)
		tween.tween_property(child, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(child, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
		tween.chain().tween_property(child, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(child, "modulate", Color.WHITE, 0.18)


func _set_speed(speed: float, clear_skip_mode: bool = true) -> void:
	if _combat_stage != null: _combat_stage._clear_flurry()
	_cancel_combat_audio()
	if _category_preview != null: _category_preview.clear_feedback()
	_last_speed = speed
	if clear_skip_mode:
		_skip_playback_on_fight = false
	if _playback != null:
		_playback.speed = speed
	if _controls_row != null:
		_controls_row.set_active_speed(speed)
		if _skip_playback_on_fight and not clear_skip_mode:
			_controls_row.set_skip_mode_active(true)


func _on_playback_skip_pressed() -> void:
	if _playback != null:
		_skip()
		return
	_skip_playback_on_fight = true
	if _controls_row != null:
		_controls_row.set_skip_mode_active(true)


func _skip() -> void:
	_clear_retrigger_popups()
	_cancel_combat_audio()
	if _category_preview != null: _category_preview.clear()
	if _playback != null:
		_popup_generation += 1
		_playback_intro_remaining_sec = 0.0
		_playback_skipping = true
		_playback.skip()
		_playback_skipping = false


func _schedule_cast_popup(event: CombatPlayback.PlaybackEvent, delay_sec: float) -> void:
	if _playback_skipping: return
	var generation := _popup_generation
	if delay_sec <= 0.0 or _instant_playback:
		_spawn_popup(event)
		return
	await get_tree().create_timer(delay_sec).timeout
	if generation != _popup_generation:
		return
	_spawn_popup(event)


func _update_damage_label() -> void:
	_damage_label.text = "%.1f" % _damage_dealt
	_damage_label.tooltip_text = "Damage dealt (excludes direct health removal)"
	if _health_removed_label != null:
		_health_removed_label.text = "Health removed: %.1f" % _health_removed
		_health_removed_label.visible = _health_removed > 0 or (_current_result != null and _current_result.cast_events.any(func(cast): return preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(cast)))


func _format_stun_duration(duration_ms: int) -> String:
	var seconds := float(duration_ms) / 1000.0
	if is_equal_approx(seconds, roundf(seconds)):
		return "%ds" % int(roundf(seconds))
	return "%.1fs" % seconds


func _update_time_label() -> void:
	if _playback == null:
		return
	_update_fight_timer_countdown()


func _gear_has_id(equipped_gear: Array[GearItem], gear_id: String) -> bool:
	for gear in equipped_gear:
		if gear != null and gear.id == gear_id:
			return true
	return false


## Ticks always use TEXT_POISON; crit casts use the same TEXT_GOLD language
## as Adventure; casts use TEXT_MAGIC whenever a legendary effect actually
## fired on that cast (Bejeweled Push Dagger's minimum-cast-time proc), so it
## reads visually distinct from an ordinary hit. Any triggered skill
## (Mithril Karambit) gets its own separate magic-colored popup, mirroring
## combat_screen.gd's per-trigger popup exactly.
func _spawn_popup(event: CombatPlayback.PlaybackEvent) -> void:
	if _playback_skipping: return
	if CombatEffectIcons.reduced_motion or (not event.is_tick and (event.cast.cooldown_blocked or event.cast.resource_unavailable)):
		return
	if event.is_tick:
		var critical := event.tick != null and event.tick.is_crit
		var tick_size := roundi(_poison_tick_font_size() * 1.5) if critical else _poison_tick_font_size()
		var label := _spawn_text_popup(_popup_text(event), UIColors.TEXT_POISON, tick_size, critical, POPUP_TICK_RISE_SEC, true)
		if event.tick.stacks_preserved: preload("res://scripts/ui/poison_preservation_feedback.gd").apply(label)
		return
	var cast := event.cast
	if _category_preview.handles(cast):
		if not _playback_skipping: _category_preview.show_cast(cast)
		return
	if _is_hold_cast(cast):
		return
	var color := UIColors.TEXT_NORMAL
	var font_size := POPUP_FONT_SIZE
	var punch := false
	if cast.is_crit:
		color = UIColors.TEXT_GOLD
		font_size = POPUP_CRIT_FONT_SIZE
		punch = true
	elif cast.min_cast_time_proc_applied:
		color = UIColors.TEXT_MAGIC
		font_size = POPUP_PROC_FONT_SIZE
	var category_style = preload("res://scripts/ui/skill_category_preview_style.gd")
	if category_style.popup_selected(cast.skill): color = category_style.COLORS[cast.skill.category]
	if cast.is_crit and cast.crit_negation_damage_prevented > 0.0:
		_spawn_crit_negation_popup(cast)
	elif cast.gold_stolen > 0:
		_spawn_gold_hit_popup(cast, color, font_size, punch)
	else:
		var label := _spawn_text_popup(_popup_text(event), color, font_size, punch)
		if label != null and preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(cast): label.set_meta("health_removal_initial", true)
	for triggered_name in [] if event.chain_count > 1 else cast.triggered_skill_names:
		_spawn_text_popup(String(triggered_name), UIColors.TEXT_MAGIC, POPUP_PROC_FONT_SIZE, false)


func _is_hold_cast(cast: CombatResolver.CastEvent) -> bool:
	return cast != null and cast.skill != null and cast.skill.id == "skill.hold"


func _clear_retrigger_popups() -> void:
	for popup in _popup_layer.get_children():
		if popup.has_meta("retrigger_hit"):
			popup.hide()
			popup.queue_free()


func _spawn_retrigger_popup(event: CombatPlayback.PlaybackEvent) -> Label:
	var cast := event.cast
	var chain_index := event.chain_index
	var color_override := Color.TRANSPARENT
	var category_style = preload("res://scripts/ui/skill_category_preview_style.gd")
	if category_style.popup_selected(cast.skill): color_override = category_style.COLORS[cast.skill.category]
	if _playback_skipping or cast.cooldown_blocked or cast.resource_unavailable:
		return null
	var skill_name := cast.skill.display_name if cast.skill != null else "Attack"
	var text := "%s %.1f" % [skill_name, cast.physical_damage]
	if preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(cast): text = "%s removes %.1f health" % [skill_name, cast.health_removed]
	var font_size := POPUP_FONT_SIZE
	var color := UIColors.TEXT_NORMAL
	if cast.was_interrupted:
		text = "%s %s" % [skill_name, "skipped" if cast.interrupt_skipped else "interrupted"]
	elif cast.was_dodged:
		text = "%s 0.0 dodged" % skill_name
	elif cast.is_crit:
		text += "!"
		font_size = POPUP_CRIT_FONT_SIZE
		color = UIColors.TEXT_GOLD
	elif cast.min_cast_time_proc_applied:
		text += " PROC!"
		font_size = POPUP_PROC_FONT_SIZE
		color = UIColors.TEXT_MAGIC
	if cast.gold_stolen > 0: text += " +%d gold" % cast.gold_stolen
	if color_override.a > 0 and cast.crit_negation_damage_prevented <= 0 and cast.gold_stolen <= 0:
		color = color_override
	if cast.skill != null and cast.skill.category in [Skill.Category.DEBUFF, Skill.Category.SELF_BUFF]:
		text = skill_name + "\n" + category_style.outcome(cast)
		color = category_style.COLORS[cast.skill.category]
	var label := _make_popup_label(text, color, roundi(font_size * 0.75))
	label.name = "RetriggerHitText"
	label.set_meta("retrigger_hit", true)
	var live_echoes: Array[Node] = []
	for popup in _popup_layer.get_children():
		if popup.has_meta("retrigger_hit") and not popup.is_queued_for_deletion(): live_echoes.append(popup)
	# Long health-removal labels occupy one centered lane.
	for popup in _popup_layer.get_children():
		if popup.has_meta("health_removal_initial") and preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(cast): popup.hide()
	var wide := preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(cast) and label.get_combined_minimum_size().x > _popup_layer.size.x * 0.45
	while live_echoes.size() >= (1 if wide else 2):
		var oldest = live_echoes.pop_front()
		oldest.hide()
		oldest.queue_free()
	label.add_theme_constant_override("outline_size", 2)
	_popup_layer.add_child(label)
	label.reset_size()
	var fit := minf(1.0, maxf(1.0, _popup_layer.size.x - 16.0) / maxf(1.0, label.size.x))
	fit = fit if preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(cast) else 1.0
	label.scale = Vector2.ONE * fit
	var anchor := _popup_layer.size * Vector2(0.65, 0.5)
	if _combat_stage != null:
		anchor = _popup_layer.get_global_transform().affine_inverse() * _combat_stage.enemy_popup_global_position()
	# PopupLayer is a separate VBox child below the stage: clamp in stage space.
	var top_margin := 0.0
	if _combat_stage != null:
		top_margin = (_popup_layer.get_global_transform().affine_inverse() * _combat_stage.play_area_global_rect().position).y + 200.0
	# Two horizontal lanes fit between the status strip and the target head.
	var lane_x := 0.0 if wide else (-96.0 if chain_index % 2 == 0 else 96.0)
	label.position = Vector2(clampf(anchor.x + lane_x - label.size.x * fit * 0.5, 8.0, maxf(8.0, _popup_layer.size.x - label.size.x * fit - 8.0)), top_margin)
	label.modulate.a = CombatPopupLayer.RETRIGGER_OPACITY
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 6.0, CombatPopupLayer.RETRIGGER_LIFETIME_SEC)
	tween.tween_property(label, "modulate:a", 0.0, 0.17).set_delay(0.07)
	tween.finished.connect(label.queue_free)
	return label


func _spawn_gold_hit_popup(cast: CombatResolver.CastEvent, color: Color, font_size: int, punch: bool) -> void:
	var root := HBoxContainer.new()
	root.name = "GoldHitPopup"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 8)
	_popup_layer.add_child(root)

	var skill_name := cast.skill.display_name if cast.skill != null else "Attack"
	var crit_suffix := "!" if cast.is_crit else ""
	var hit_text := "%s %.1f%s" % [skill_name, cast.physical_damage, crit_suffix]
	if preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(cast): hit_text = "%s removes %.1f health" % [skill_name, cast.health_removed]
	var hit_label := _make_popup_label(hit_text, color, font_size)
	root.add_child(hit_label)

	var icon := TextureRect.new()
	icon.name = "GoldIcon"
	icon.texture = preload("res://assets/ui/icons/gold.png")
	icon.custom_minimum_size = GOLD_POPUP_ICON_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon)

	var gold_label := _make_popup_label("%d" % cast.gold_stolen, UIColors.TEXT_GOLD, font_size)
	root.add_child(gold_label)

	root.reset_size()
	var fit := PopupLayout.place(root, _popup_layer, _combat_stage, false)
	var start_position := root.position
	root.position = start_position
	root.scale = Vector2.ONE * (POPUP_CRIT_PUNCH_SCALE if punch else 0.92) * fit

	var tween := root.create_tween()
	tween.set_parallel(true)
	if punch:
		tween.tween_property(root, "scale", Vector2.ONE * fit, POPUP_CRIT_PUNCH_SEC)
	else:
		tween.tween_property(root, "scale", Vector2.ONE * fit, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "position:y", start_position.y - POPUP_RISE_PX, POPUP_RISE_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "modulate:a", 0.0, POPUP_LIFETIME_SEC - POPUP_FADE_DELAY_SEC).set_delay(POPUP_FADE_DELAY_SEC)
	tween.finished.connect(root.queue_free)


func _spawn_text_popup(text: String, color: Color, font_size: int = POPUP_FONT_SIZE, punch: bool = false, rise_sec: float = POPUP_RISE_SEC, is_poison_tick: bool = false) -> Label:
	var label := Label.new()
	if is_poison_tick and punch:
		label.set_meta("critical_poison", true)
	label.text = text
	label.add_theme_font_override("font", POPUP_FONT)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	_popup_layer.add_child(label)
	preload("res://scripts/ui/combat_gold_text_icon.gd").decorate(label)
	label.reset_size()
	var area_size := _popup_layer.size
	var fit := PopupLayout.place(label, _popup_layer, _combat_stage, is_poison_tick)
	var start_position := label.position
	label.position = start_position
	if punch:
		label.scale = Vector2.ONE * POPUP_CRIT_PUNCH_SCALE * fit
	else:
		label.scale = Vector2.ONE * 0.92 * fit

	var tween := label.create_tween()
	tween.set_parallel(true)
	if punch:
		tween.tween_property(label, "scale", Vector2.ONE * fit, POPUP_CRIT_PUNCH_SEC)
	else:
		tween.tween_property(label, "scale", Vector2.ONE * fit, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", start_position.y - POPUP_RISE_PX, rise_sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, POPUP_LIFETIME_SEC - POPUP_FADE_DELAY_SEC).set_delay(POPUP_FADE_DELAY_SEC)
	tween.finished.connect(label.queue_free)
	return label


func _spawn_crit_negation_popup(cast: CombatResolver.CastEvent) -> void:
	var skill_name := cast.skill.display_name if cast.skill != null else "Attack"
	var original_damage := cast.physical_damage + maxf(cast.crit_negation_damage_prevented, 0.0)
	var root := Control.new()
	root.name = "CritNegationPopup"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup_layer.add_child(root)

	var skill_label := _make_popup_label(skill_name, UIColors.TEXT_GOLD, POPUP_CRIT_FONT_SIZE)
	root.add_child(skill_label)
	skill_label.reset_size()
	skill_label.position = Vector2.ZERO

	var original := _make_popup_label("%.1f!" % original_damage, UIColors.TEXT_GOLD, POPUP_CRIT_FONT_SIZE)
	root.add_child(original)
	original.reset_size()
	original.position = Vector2(skill_label.size.x + 8.0, 0.0)

	var cross := CritCrossOutOverlay.new()
	cross.name = "CritCrossOutOverlay"
	cross.size = original.size
	cross.position = original.position
	cross.z_index = 3
	root.add_child(cross)

	var actual := _make_popup_label("%.1f!" % cast.physical_damage, UIColors.TEXT_GOLD, POPUP_NEGATED_ACTUAL_FONT_SIZE)
	root.add_child(actual)
	actual.reset_size()
	actual.position = Vector2(original.position.x + original.size.x + POPUP_NEGATED_GAP_PX, maxf(0.0, (original.size.y - actual.size.y) * 0.5))

	root.size = Vector2(skill_label.size.x + 8.0 + original.size.x + POPUP_NEGATED_GAP_PX + actual.size.x, maxf(original.size.y, actual.size.y))
	var fit := PopupLayout.place(root, _popup_layer, _combat_stage, false)
	root.scale = Vector2.ONE * POPUP_CRIT_PUNCH_SCALE * fit
	root.pivot_offset = root.size * 0.5
	var tween := root.create_tween()
	tween.set_parallel(true)
	tween.tween_property(root, "scale", Vector2.ONE * fit, POPUP_CRIT_PUNCH_SEC)
	tween.tween_property(root, "position:y", root.position.y - POPUP_RISE_PX, POPUP_RISE_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "modulate:a", 0.0, POPUP_LIFETIME_SEC - POPUP_FADE_DELAY_SEC).set_delay(POPUP_FADE_DELAY_SEC)
	tween.finished.connect(root.queue_free)


func _make_popup_label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", POPUP_FONT)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE_STRONG)
	label.add_theme_constant_override("outline_size", 5)
	preload("res://scripts/ui/combat_gold_text_icon.gd").decorate(label)
	return label


func _popup_start_position(is_poison_tick: bool, area_size: Vector2, label_size: Vector2) -> Vector2:
	if is_poison_tick and _combat_stage != null:
		var enemy_local: Vector2 = _popup_layer.get_global_transform().affine_inverse() * _combat_stage.enemy_popup_global_position()
		return Vector2(
			enemy_local.x - label_size.x * 0.5 + randf_range(-POPUP_POISON_TICK_JITTER_X_PX, POPUP_POISON_TICK_JITTER_X_PX),
			enemy_local.y - label_size.y * 0.5 + randf_range(-POPUP_POISON_TICK_JITTER_Y_PX, POPUP_POISON_TICK_JITTER_Y_PX)
		)
	var jitter_x := area_size.x * POPUP_JITTER_X_FRACTION
	var start_x: float = area_size.x * 0.5 + randf_range(-jitter_x, jitter_x) if area_size.x > 0.0 else 0.0
	var start_y := area_size.y * 0.5 + randf_range(-POPUP_JITTER_Y_PX, POPUP_JITTER_Y_PX)
	return Vector2(start_x, start_y)


func _poison_tick_font_size() -> int:
	return POPUP_WYVERN_TICK_FONT_SIZE if _wyvern_kriss_effect_active else POPUP_TICK_FONT_SIZE


func _popup_text(event: CombatPlayback.PlaybackEvent) -> String:
	if event.is_tick:
		return "Poison %.1f%s" % [event.damage, "!" if event.tick != null and event.tick.is_crit else ""]
	var cast := event.cast
	var skill_name := cast.skill.display_name if cast.skill != null else "Attack"
	if cast.was_interrupted:
		var interrupt_text := "skipped" if cast.interrupt_skipped else "interrupted"
		return "%s %s" % [skill_name, interrupt_text]
	var crit_suffix := "!" if cast.is_crit else ""
	var proc_suffix := " PROC!" if cast.min_cast_time_proc_applied else ""
	if preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(cast): return "%s removes %.1f health%s" % [skill_name, cast.health_removed, proc_suffix]
	return "%s %.1f%s%s" % [skill_name, cast.physical_damage, crit_suffix, proc_suffix]


func _sync_presentation() -> void:
	var snapshot: Dictionary = _effect_icons.model.statuses
	_stacks = int(snapshot.get("poison", _stacks))
	_shred_stacks = int(snapshot.get("shred", _shred_stacks))
	_decay_stacks = int(snapshot.get("decay", _decay_stacks))
	_resist = float(snapshot.get("poison_resistance", _resist))
	if _monster != null:
		_armor_reduced = _monster.armor - int(snapshot.get("armor", _monster.armor - _armor_reduced))
	_update_status_readout()
	if skill_build_panel != null:
		skill_build_panel.update_presentation(_effect_icons.model, not _instant_playback and not _playback_skipping)


func _on_motion_changed(enabled: bool) -> void:
	_cancel_combat_audio()
	if _category_preview != null: _category_preview.clear()
	if not enabled:
		return
	_playback_intro_remaining_sec = 0
	_combat_stage.clear_transient_effects()
	_popup_generation += 1
	for child in _popup_layer.get_children():
		child.queue_free()
	if skill_build_panel != null:
		skill_build_panel.clear_stun_effect()
		skill_build_panel.clear_legendary_feedback()


func _cancel_combat_audio() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null: audio.cancel_combat_sfx()


func _exit_tree() -> void:
	_cancel_combat_audio()
	if is_instance_valid(_presentation_owner) and _presentation_owner.has_meta("combat_presentation"):
		if _presentation_owner.get_meta("combat_presentation") == _owned_presentation_model:
			_presentation_owner.remove_meta("combat_presentation")
