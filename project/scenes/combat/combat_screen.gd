extends Control
## The persistent combat HUD, laid out per the user's mockups: a dominant
## central combat window (future home of animated combat) flanked by side
## columns -- left: Character Stats over Talent Trees; right: Enemy Stats
## over Gear -- with Fight/Combat Log, then the Available Skills and Skill
## Build strips, under the combat window. Each panel reads BuildState directly and
## refreshes on BuildState.build_changed -- no cross-panel coupling, per
## docs/Conventions.md's UI architecture principle. This script itself only
## owns the combat window, the log overlay, the top bar, and the Fight
## action.
##
## The combat log lives in a dismissible overlay rather than inline in the
## combat window -- once real combat animation exists, the window needs
## that space for the fight itself, not a wall of text. The log remains
## fully available on demand via "View Combat Log," since reading exactly
## what happened is core to the game (see docs/DPS_Engine_Phase2_Context.md's
## design philosophy), it just doesn't have to compete with animation for
## screen space.

signal main_menu_pressed
signal adventure_restart_pressed
signal save_and_quit_pressed

const CHARACTER_STATS_SCENE := preload("res://scenes/combat/character_stats_panel.tscn")
const ENEMY_SCENE := preload("res://scenes/combat/enemy_panel.tscn")
const ACTIVE_TALENTS_SCENE := preload("res://scenes/combat/active_talents_panel.tscn")
const AVAILABLE_SKILLS_SCENE := preload("res://scenes/combat/available_skills_panel.tscn")
const SKILL_BUILD_SCENE := preload("res://scenes/combat/skill_build_panel.tscn")
const GEAR_SCENE := preload("res://scenes/combat/gear_panel.tscn")
const LOG_OVERLAY_SCENE := preload("res://scenes/combat/log_overlay.tscn")
const TALENT_OVERLAY_SCENE := preload("res://scenes/combat/talent_overlay.tscn")
const STORY_OVERLAY_SCENE := preload("res://scenes/combat/story_overlay.tscn")
const SECONDARY_SUBCLASS_OVERLAY_SCENE := preload("res://scenes/combat/secondary_subclass_overlay.tscn")
const REWARD_CHOICE_OVERLAY_SCENE := preload("res://scenes/combat/reward_choice_overlay.tscn")
const SHOP_OVERLAY_SCENE := preload("res://scenes/combat/shop_overlay.tscn")
const CONTRACT_OVERLAY_SCENE := preload("res://scenes/combat/contract_overlay.tscn")
const MAP_OVERLAY_SCENE := preload("res://scenes/combat/map_overlay.tscn")
const MONSTER_MANUAL_OVERLAY_SCENE := preload("res://scenes/combat/monster_manual_overlay.tscn")
const COMBAT_STAGE_SCRIPT := preload("res://scripts/ui/combat_stage.gd")
const COMBAT_STATUS_ICONS := preload("res://scripts/ui/combat_status_icons.gd")
const TAVERN_FIREPLACE_GLOW_OVERLAY_SCRIPT := preload("res://scripts/ui/tavern_fireplace_glow_overlay.gd")
const CONTRACT_MOON_BAT_OVERLAY_SCRIPT := preload("res://scripts/ui/contract_moon_bat_overlay.gd")
const FLOW_TEXT := preload("res://scripts/ui/adventure_flow_text.gd")
const COMBAT_STATUS_ICON_SIZE := Vector2(22, 22)
const COMBAT_STATUS_FONT_SIZE := 24
const HUD_HEALTH_ICON := preload("res://assets/combat_ui_icons/enemy_health.png")
static var HUD_ARMOR_ICON: Texture2D = GameIcons.icon_for("defense.armor")
static var HUD_RESISTANCE_ICON: Texture2D = GameIcons.icon_for("defense.resistance")
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
const UI_MAP_ICON := preload("res://assets/ui/icons/map.png")
const UI_MONSTER_MANUAL_ICON := preload("res://assets/ui/icons/monster_manual.png")
const UI_GOLD_ICON := preload("res://assets/ui/icons/gold.png")
const UI_CLOCK_ICON_PATH := "res://assets/ui/icons/clock.png"
const UI_SAVE_QUIT_ICON_PATH := "res://assets/ui/icons/save_quit_inventory.png"
const UI_ABANDON_ICON_PATH := "res://assets/ui/icons/abandon_ex.png"
const HEALTH_BAR_HEIGHT := 18.0
const HEALTH_BAR_INSET := 3.0
const FIGHT_TIMER_ICON_SIZE := Vector2(28, 28)
const FIGHT_TIMER_FONT_SIZE := 26
const FIGHT_TIMER_BADGE_SIZE := Vector2(112, 46)
const TOP_ACTION_BUTTON_SIZE := Vector2(56, 56)
const SETTINGS_BUTTON_RESERVED_WIDTH := 50.0
const TOP_BAR_CHROME_Z_INDEX := 900
const MAP_OVERLAY_Z_INDEX := TOP_BAR_CHROME_Z_INDEX + 10
const TOP_MODAL_OVERLAY_Z_INDEX := MAP_OVERLAY_Z_INDEX + 20
const REWARD_CHOICE_INITIAL_REVEAL_DELAY_SEC := 0.55

const SIDE_COLUMN_WIDTH := 300
const SCREEN_MARGIN := 16
const PANEL_SEPARATION := 16
const CARD_TITLE_FONT_SIZE := 20
const VICTORY_TITLE_FONT_SIZE := 36
const VICTORY_REWARD_FONT_SIZE := 24
const VICTORY_REWARD_ICON_SIZE := Vector2(34, 34)
const COMBAT_CONTENT_SEPARATION := 8
const COMBAT_BUTTON_BAND_FALLBACK_HEIGHT := 94.0
const RESULT_OVERLAY_Z_INDEX := 20
const COMBAT_BUTTON_ROW_DEFAULT_Z_INDEX := 0
const COMBAT_BUTTON_ROW_Z_INDEX := 30
const OUTCOME_TITLE_FONT_SIZE := 24
const OUTCOME_LOSS_COLOR := UIColors.OUTCOME_LOSS
const BACKDROP_COLOR := UIColors.OVERLAY_BACKDROP

# -- Combat playback tuning (user-requested combat-playback addition,
# 2026-07-19). Every knob for the first-draft adjustment round lives here:
# playback speeds, HP-bar tween snappiness, and the comic-book skill-popup
# font sizes/colors/motion. The playback timeline itself is driven by
# CombatPlayback (scripts/ui/combat_playback.gd); these constants only shape
# how each fired event LOOKS. --
## Combat-playback adjustment round 1 (2026-07-19): a short pause between
## the timeline finishing and _reveal_fight_outcome() actually running, so
## the last spawned popup's float+fade (CombatPopupLayer.POPUP_DURATION_SEC
## 1.35s, fading after POPUP_FADE_DELAY_SEC 0.45s) has visibly finished before the
## outcome banner/recap pops in on top of it. Deliberately a little under
## the full 0.9s popup lifetime rather than a full match -- close enough
## that the last popup reads as "done" without adding a full extra second
## of dead air after every fight. Skipped entirely in instant_playback mode
## and when the reveal was reached via the Skip button (no popups spawn
## during a skip flush, so there is nothing left to outlast) -- see
## _on_playback_finished().
const PLAYBACK_OUTCOME_REVEAL_DELAY_SEC := 0.75
const PLAYER_DEFEAT_POSE_HOLD_SEC := 1.0
const TAVERN_BACKGROUND_TEXTURE := preload("res://assets/backgrounds/tavern_dummy_background_2.jpg")
const CONTRACT_BACKGROUND_TEXTURE := preload("res://assets/backgrounds/contract_exterior.jpg")
const BIOME_BACKGROUND_TEXTURE_PATHS := {
	"Swamp": "res://assets/backgrounds/biomes/swamp.jpg",
	"Cave": "res://assets/backgrounds/biomes/cave.jpg",
	"Graveyard": "res://assets/backgrounds/biomes/graveyard.jpg",
	"Haunted Forest": "res://assets/backgrounds/biomes/forest.jpg",
	"Ruined Keep": "res://assets/backgrounds/biomes/keep.jpg",
	"Ancient Ruins": "res://assets/backgrounds/biomes/ruins.jpg",
}
const TAVERN_BACKGROUND_TINT := UIColors.SCRIM_SOFT


class HealthBarDepthOverlay:
	extends Control

	var source_bar: ProgressBar

	func bind(bar: ProgressBar) -> void:
		source_bar = bar
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if source_bar != null and not source_bar.value_changed.is_connected(_on_bar_value_changed):
			source_bar.value_changed.connect(_on_bar_value_changed)

	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		if source_bar == null:
			return
		var track_rect := Rect2(Vector2.ZERO, size)
		var inner_rect := track_rect.grow(-HEALTH_BAR_INSET)
		if inner_rect.size.x <= 0.0 or inner_rect.size.y <= 0.0:
			return
		var ratio := 0.0
		if source_bar.max_value > source_bar.min_value:
			ratio = clampf(
				(float(source_bar.value) - float(source_bar.min_value))
				/ (float(source_bar.max_value) - float(source_bar.min_value)),
				0.0,
				1.0
			)
		var fill_width := inner_rect.size.x * ratio
		draw_rect(Rect2(inner_rect.position, Vector2(inner_rect.size.x, 1.0)), UIColors.PANEL_EDGE_LIGHT, true)
		draw_rect(
			Rect2(Vector2(inner_rect.position.x, inner_rect.end.y - 2.0), Vector2(inner_rect.size.x, 2.0)),
			UIColors.HEALTH_BAR_TRACK_INNER,
			true
		)
		if fill_width <= 0.0:
			return
		var fill_rect := Rect2(inner_rect.position, Vector2(fill_width, inner_rect.size.y))
		draw_rect(Rect2(fill_rect.position, Vector2(fill_rect.size.x, 3.0)), UIColors.HEALTH_BAR_SHEEN, true)
		draw_rect(
			Rect2(Vector2(fill_rect.position.x, fill_rect.end.y - 3.0), Vector2(fill_rect.size.x, 3.0)),
			UIColors.HEALTH_BAR_FILL_SHADOW,
			true
		)
		if fill_width >= 8.0:
			draw_line(
				Vector2(fill_rect.end.x - 1.0, fill_rect.position.y + 2.0),
				Vector2(fill_rect.end.x - 1.0, fill_rect.end.y - 2.0),
				UIColors.HEALTH_BAR_FILL_LIGHT,
				1.0
			)

	func _on_bar_value_changed(_value: float) -> void:
		queue_redraw()


var _status_label: Label
var _outcome_title_label: Label
var _seed_label: Label
var _phase_label: Label
var _lock_label: Label
var _next_action_label: Label
var _view_log_button: Button
var _fight_button_row: HBoxContainer
var _map_button: Button
var _monster_manual_button: Button
var _retry_button: Button
var _restart_adventure_button: Button
var _combat_content: VBoxContainer
var _category_preview
var _log_overlay
var _map_overlay
var _monster_manual_overlay
var _talent_overlay
var _contract_offer_after_talents := false
var _story_overlay
var _contract_overlay
var _victory_overlay: Control
var _victory_center: Control
var _victory_combat_dim: ColorRect
var _victory_stack: Control
var _victory_title_label: Label
var _victory_top_rule: ColorRect
var _outcome_message_label: Label
var _victory_recap_label: Label
var _victory_reward_row: HBoxContainer
var _victory_button_row: HBoxContainer
var _outcome_retry_button: Button
var _outcome_restart_button: Button
var _recap_label: Label
# -- Enemy status HUD (user-requested combat-HUD addition, 2026-07-18):
# compact enemy name/health-bar/status-row/info-line block anchored at the
# top of the black Combat panel, leaving the panel's center free for the
# future fight-action animations that black space is reserved for. --
var _enemy_hud: VBoxContainer
var _fight_timer_badge: PanelContainer
var _fight_timer_label: Label
var _hud_name_label: Label
var _hud_hp_text_label: Label
var _hud_health_bar: ProgressBar
var _hud_effect_row: FlowContainer
var _hud_status_row: FlowContainer
var _hud_info_label: Label
var _hud_resist_label: Label
## Combat resolves synchronously in one CombatResolver.resolve() call, so
## the HUD can't animate live values mid-fight. Instead it has exactly two
## display states: pre-fight (full HP / base armor / base resist / zero
## stacks, from the current Monster resource) and post-fight (the resolved
## outcome, derived from the stored CombatResult below). _hud_result is
## cleared at every new-fight setup transition, the same call sites that
## clear the T7 recap label. Not persisted across save/load, matching the
## combat log overlay's existing behavior.
var _hud_result: CombatResolver.CombatResult = null
var _hud_result_monster: Monster = null
# -- Real-time combat playback (user-requested combat-playback addition,
# 2026-07-19). Combat still resolves synchronously and BuildState still
# mutates/autosaves immediately in _on_fight_pressed() -- ONLY the visual
# reveal (HUD post-fight state, victory banner, outcome presentation, recap)
# waits for the playback timeline to finish. instant_playback collapses the
# whole playback to the pre-playback behavior: it defaults to true under the
# headless display server so every existing headless test keeps observing
# post-fight UI state synchronously, while the real game window gets 1x
# playback; tests that exercise playback itself set it to false explicitly. --
var instant_playback: bool = DisplayServer.get_name() == "headless"
## Raised BEFORE BuildState.finish_fight() runs (see _on_fight_pressed()) so
## a run_state_changed refresh it emits doesn't clobber the animated HUD --
## that ordering need is why this flag stays here instead of being owned or
## mirrored by _playback_presenter. See combat_playback_presenter.gd's
## header for the full rationale.
var _playback_active := false
var _playback_contract_traversal_active := false
var _current_playback_slow := 0.0
var _contract_route_player_entered := false
var _playback_presenter: CombatPlaybackPresenter
var _playback_controls: PlaybackControls
var hud_status_chip_flash_count := 0
var _effect_icons: CombatEffectIcons
var _skip_playback_on_fight := false
var _skill_build_panel
var _gear_panel
var _active_talents_panel
## Session-persistent playback speed (combat-playback adjustment round 2 +
## retry bug, 2026-07-19): the user asked for their last-chosen speed to
## carry forward into the next fight instead of always resetting to 1x.
## combat_screen.tscn is the persistent dashboard scene, not re-instantiated
## per fight (see game_root.gd -- _show_combat_screen() is only ever called
## once per run), so a plain instance var here already survives across every
## _on_fight_pressed() call for the rest of the session; no BuildState/
## SaveSystem plumbing needed for "carries into the next fight." Not
## persisted across a save/reload (the user asked for "into the next fight,"
## not "across sessions") -- a fresh session or a loaded save always starts
## back at PlaybackControls.SPEED_OPTIONS[0] (1x), which is judged an acceptable,
## easy-to-revisit default rather than adding save-file schema churn for a
## same-session-only ask.
var _last_playback_speed: float = PlaybackControls.SPEED_OPTIONS[0]
var _combat_window: PanelContainer
var _tavern_background: TextureRect
var _tavern_fireplace_overlay
var _contract_moon_bat_overlay
var _tavern_background_tint: ColorRect
var _biome_background_texture_cache := {}
var _combat_play_area: Control
var _combat_stage
var _popup_layer: CombatPopupLayer
var _reward_label: Label
var _reward_gold_icon: TextureRect
var _reward_talent_icon: TextureRect
var _continue_button: Button
var _shop_overlay
var _reward_choice_overlay
var _secondary_subclass_overlay
var _enemy_panel
var _confirm_dialog: ConfirmationDialog
var _last_inventory_blocked_source: Control = null
var _reward_choice_reveal_active := false
var _reward_choice_reveal_generation := 0
var _reward_choice_reveal_buttons: Array[Button] = []
var _reward_upgrade_effects: Array[Control] = []


func _ready() -> void:
	var canvas := ColorRect.new()
	canvas.name = "ScreenCanvas"
	canvas.color = UIColors.BACKGROUND
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(canvas)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, SCREEN_MARGIN)
	add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", PANEL_SEPARATION)
	margin.add_child(root_vbox)

	# -- Top bar: compact always-visible status (Phase/Build/Seed/Next) on
	# the left, Map/Save & Quit/Abandon Run buttons on the right.
	#
	# P2:R7 playtest-feedback pass (2026-07-18, revises T3): T3 originally
	# added a full-width status-bar row of its own, inserted between this
	# top bar and the three-column HUD body, with Target and Gold fields
	# plus a "Next" line on a second row underneath. Playtesting found that
	# row ate vertical space the loaded-state dashboard didn't have to
	# spare (see the overflow-bug notes in
	# docs/Phase_2_R7_Game_Like_UI_Pass.md), and that Target/Gold were
	# redundant with the enemy panel's own "Target:" line and the Gear
	# panel's stash readout. The status concept is kept,
	# just consolidated directly into this top bar row instead of a
	# separate one -- Phase/Build/Seed on the left, the "Next" action line
	# expanding to fill the middle (clipped rather than wrapped, so a long
	# instruction can't push the buttons off the right edge), and the
	# existing Map/Save & Quit/Abandon Run buttons unchanged on the right.
	# Every field still reads BuildState only and refreshes off BuildState's
	# existing signals (build_changed/run_state_changed/lock_changed).
	var top_bar := HBoxContainer.new()
	top_bar.name = "TopActionBar"
	top_bar.z_index = TOP_BAR_CHROME_Z_INDEX
	top_bar.add_theme_constant_override("separation", 20)

	_phase_label = Label.new()
	top_bar.add_child(_phase_label)

	_lock_label = Label.new()
	top_bar.add_child(_lock_label)

	_seed_label = Label.new()
	top_bar.add_child(_seed_label)

	_next_action_label = Label.new()
	_next_action_label.add_theme_color_override("font_color", CardStyle.ACCENT_COLOR)
	_next_action_label.clip_text = true
	_next_action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(_next_action_label)

	_map_button = Button.new()
	_configure_top_icon_button(_map_button, "MapButton", UI_MAP_ICON, "Map")
	_map_button.pressed.connect(_on_map_button_pressed)
	top_bar.add_child(_map_button)
	_monster_manual_button = Button.new()
	_configure_top_icon_button(_monster_manual_button, "MonsterManualButton", UI_MONSTER_MANUAL_ICON, "Monster Manual")
	_monster_manual_button.pressed.connect(_on_monster_manual_pressed)
	top_bar.add_child(_monster_manual_button)
	var save_quit_button := Button.new()
	_configure_top_icon_button(save_quit_button, "SaveQuitButton", _icon_texture_from_path(UI_SAVE_QUIT_ICON_PATH), "Save & Quit")
	if BuildState.is_test_mode:
		save_quit_button.tooltip_text = "Exit Test Mode (session progress is discarded)"
	save_quit_button.pressed.connect(_on_save_and_quit_pressed)
	top_bar.add_child(save_quit_button)
	var menu_button := Button.new()
	_configure_top_icon_button(menu_button, "AbandonRunButton", _icon_texture_from_path(UI_ABANDON_ICON_PATH), "Abandon Run")
	menu_button.pressed.connect(func(): _confirm_dialog.popup_centered())
	top_bar.add_child(menu_button)
	var settings_reserved_space := Control.new()
	settings_reserved_space.custom_minimum_size = Vector2(SETTINGS_BUTTON_RESERVED_WIDTH, 0)
	top_bar.add_child(settings_reserved_space)
	root_vbox.add_child(top_bar)

	# -- Three-column HUD body --
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", PANEL_SEPARATION)
	root_vbox.add_child(columns)

	# Left column: Character Stats over Active Talents. The full tree lives
	# in a modal overlay so talent allocation remains available without
	# implying that every fight should begin with tree tinkering.
	var left_column := VBoxContainer.new()
	left_column.custom_minimum_size = Vector2(SIDE_COLUMN_WIDTH, 0)
	left_column.add_theme_constant_override("separation", PANEL_SEPARATION)
	columns.add_child(left_column)

	# Character Stats shrinks to its content; Subclass absorbs the leftover
	# column height (room for a second tree row once that's added).
	var character_stats_panel = CHARACTER_STATS_SCENE.instantiate()
	character_stats_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_child(character_stats_panel)

	_active_talents_panel = ACTIVE_TALENTS_SCENE.instantiate()
	_active_talents_panel.size_flags_vertical = Control.SIZE_FILL
	_active_talents_panel.open_talents_pressed.connect(_show_talent_overlay)
	left_column.add_child(_active_talents_panel)

	# Center column: the combat window, then the two skill strips.
	var center_column := VBoxContainer.new()
	center_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_column.add_theme_constant_override("separation", PANEL_SEPARATION)
	columns.add_child(center_column)

	center_column.add_child(_build_combat_window())

	center_column.add_child(AVAILABLE_SKILLS_SCENE.instantiate())
	_skill_build_panel = SKILL_BUILD_SCENE.instantiate()
	center_column.add_child(_skill_build_panel)

	_playback_presenter = CombatPlaybackPresenter.new()
	_playback_presenter.clock_frost = _fight_timer_badge.get_node("ArcticClockAura")
	_playback_presenter.effect_icons = _effect_icons
	_playback_presenter.set_combat_stage(_combat_stage)
	_playback_presenter.set_skill_build_panel(_skill_build_panel)
	_playback_presenter.set_popup_layer(_popup_layer)
	_playback_presenter.set_hud_widgets(_hud_hp_text_label, _hud_health_bar, _hud_info_label, _hud_resist_label, _clear_hud_status_chips, _add_hud_status_chip, _flash_hud_status_chips)
	_playback_presenter.finished.connect(_on_playback_finished)
	_playback_presenter.gold_stolen_played.connect(BuildState.record_combat_stolen_gold)
	add_child(_playback_presenter)

	# Right column: Enemy Stats over Gear.
	var right_column := VBoxContainer.new()
	right_column.custom_minimum_size = Vector2(SIDE_COLUMN_WIDTH, 0)
	right_column.add_theme_constant_override("separation", PANEL_SEPARATION)
	columns.add_child(right_column)

	# Enemy Stats keeps a fixed viewport and scrolls overflow; Gear absorbs the leftover column
	# height.
	_enemy_panel = ENEMY_SCENE.instantiate()
	_enemy_panel.fight_pressed.connect(_on_fight_pressed)
	right_column.add_child(_enemy_panel)

	# enemy_panel.gd builds its Fight button but deliberately never adds it
	# to its own tree -- it lives in the centered row above instead. Reparented
	# via the panel's public fight_button() accessor rather than reaching
	# into its private field.
	var fight_button: Button = _enemy_panel.fight_button()
	fight_button.custom_minimum_size = Vector2(148, 52)
	_fight_button_row.add_child(fight_button)
	_view_log_button = Button.new()
	_view_log_button.text = "Combat Log"
	_view_log_button.custom_minimum_size = fight_button.custom_minimum_size
	_view_log_button.disabled = true
	_view_log_button.pressed.connect(func(): _log_overlay.show_log())
	_fight_button_row.add_child(_view_log_button)
	_sync_combat_play_area_reserved_height()
	call_deferred("_sync_combat_play_area_reserved_height")

	_gear_panel = GEAR_SCENE.instantiate()
	_gear_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.add_child(_gear_panel)

	_build_confirm_dialog()
	_build_victory_overlay()
	_shop_overlay = SHOP_OVERLAY_SCENE.instantiate()
	_shop_overlay.buy_pressed.connect(_on_shop_buy_pressed)
	_shop_overlay.reroll_pressed.connect(_on_shop_reroll_pressed)
	_shop_overlay.continue_pressed.connect(_on_shop_continue_pressed)
	add_child(_shop_overlay)
	_shop_overlay._focus_dimmer.clear_control = _gear_panel
	preload("res://scripts/ui/play_area_focus.gd").fit_below(_shop_overlay, columns)
	_reward_choice_overlay = REWARD_CHOICE_OVERLAY_SCENE.instantiate()
	_reward_choice_overlay.skip_pressed.connect(_on_reward_choice_skip_pressed)
	add_child(_reward_choice_overlay)
	_reward_choice_overlay.visibility_changed.connect(func():
		if not _reward_choice_overlay.visible:
			_cancel_reward_upgrade_effects()
			_reward_choice_reveal_generation += 1
			_reward_choice_reveal_active = false
			AudioManager.cancel_magic_find_sfx()
	)
	_map_overlay = MAP_OVERLAY_SCENE.instantiate()
	_map_overlay.tavern_proceed_pressed.connect(_on_tavern_proceed_pressed)
	_map_overlay.contract_offer_pressed.connect(_on_contract_map_pressed)
	_map_overlay.contract_back_requested.connect(_on_contract_back_requested)
	_map_overlay.route_node_pressed.connect(_on_contract_route_node_pressed)
	add_child(_map_overlay)
	_map_overlay.z_index = MAP_OVERLAY_Z_INDEX
	_monster_manual_overlay = MONSTER_MANUAL_OVERLAY_SCENE.instantiate()
	add_child(_monster_manual_overlay)
	_monster_manual_overlay.z_index = TOP_MODAL_OVERLAY_Z_INDEX
	_talent_overlay = TALENT_OVERLAY_SCENE.instantiate()
	_talent_overlay.secondary_tree_chosen.connect(_on_talent_secondary_tree_chosen)
	_talent_overlay.visibility_changed.connect(_on_talent_overlay_visibility_changed)
	add_child(_talent_overlay)
	_talent_overlay.z_index = TOP_MODAL_OVERLAY_Z_INDEX
	preload("res://scripts/ui/play_area_focus.gd").fit_below(_talent_overlay, columns)
	_story_overlay = STORY_OVERLAY_SCENE.instantiate()
	_story_overlay.proceed_pressed.connect(_on_intro_story_proceed_pressed)
	add_child(_story_overlay)
	_contract_overlay = CONTRACT_OVERLAY_SCENE.instantiate()
	_contract_overlay.accept_requested.connect(_on_contract_accept_requested)
	_contract_overlay.route_requested.connect(_on_contract_route_requested)
	add_child(_contract_overlay)
	_secondary_subclass_overlay = SECONDARY_SUBCLASS_OVERLAY_SCENE.instantiate()
	_secondary_subclass_overlay.tree_chosen.connect(_on_secondary_tree_pressed)
	add_child(_secondary_subclass_overlay)
	_log_overlay = LOG_OVERLAY_SCENE.instantiate()
	add_child(_log_overlay)
	_log_overlay.z_index = TOP_MODAL_OVERLAY_Z_INDEX
	preload("res://scripts/ui/play_area_focus.gd").fit_below(_log_overlay, columns)
	_log_overlay.set_run_history(BuildState.run_encounter_history)
	_category_preview = preload("res://scripts/ui/skill_category_preview.gd").new()
	_category_preview.screen = self
	add_child(_category_preview)
	BuildState.build_changed.connect(_on_build_state_changed)
	BuildState.run_state_changed.connect(_on_run_state_changed)
	BuildState.lock_changed.connect(_update_header_status)
	# A loaded save can resume directly into a terminal outcome (e.g. a
	# do-over still pending, or a contract already failed/won at save time).
	# _apply_outcome_presentation() no-ops for RunOutcome.NONE, so this is
	# safe for the normal fresh-run case too.
	_apply_outcome_presentation(BuildState.run_outcome)
	_update_header_status()
	_refresh_enemy_hud()
	# _process only runs while a combat playback is active.
	set_process(false)
	call_deferred("_show_initial_map_if_needed")


## Kept here (not moved to a _process() on _playback_presenter) specifically
## so headless tests can keep driving frame advancement by calling
## combat_screen._process(delta) directly in single-shot scripts with no
## real running game loop -- see combat_playback_presenter.gd's header.
func _process(delta: float) -> void:
	if not _playback_active:
		return
	_playback_presenter.advance(delta)
	_update_playback_time_label()


## The central combat window -- the future home of animated combat. For now
## it just shows a status line and a button to review the last fight's log.
func _build_combat_window() -> PanelContainer:
	var window := PanelContainer.new()
	window.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# P2:R7 playtest feedback (2026-07-18): the Combat panel is the future
	# home of animated combat, the same role the shop overlay's shopkeeper
	# box already reserves for future shopkeeper art -- give it the same
	# solid near-black fill (UIColors.PANEL_DEEP, reused rather than a new
	# constant) so both "reserved for future art" panels read consistently.
	var window_style := CardStyle.make_stylebox()
	window_style.bg_color = UIColors.PANEL_DEEP
	window.add_theme_stylebox_override("panel", window_style)
	_combat_window = window

	_tavern_background = TextureRect.new()
	_tavern_background.texture = TAVERN_BACKGROUND_TEXTURE
	_tavern_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tavern_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_tavern_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tavern_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tavern_background.visible = false
	window.add_child(_tavern_background)

	_tavern_fireplace_overlay = TAVERN_FIREPLACE_GLOW_OVERLAY_SCRIPT.new()
	_tavern_fireplace_overlay.name = "TavernFireplaceGlowOverlay"
	_tavern_fireplace_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tavern_fireplace_overlay.bind_background(_tavern_background)
	_tavern_fireplace_overlay.visible = false
	window.add_child(_tavern_fireplace_overlay)

	_contract_moon_bat_overlay = CONTRACT_MOON_BAT_OVERLAY_SCRIPT.new()
	_contract_moon_bat_overlay.name = "ContractMoonBatOverlay"
	_contract_moon_bat_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_contract_moon_bat_overlay.bind_background(_tavern_background)
	_contract_moon_bat_overlay.visible = false
	window.add_child(_contract_moon_bat_overlay)

	_tavern_background_tint = ColorRect.new()
	_tavern_background_tint.color = TAVERN_BACKGROUND_TINT
	_tavern_background_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tavern_background_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tavern_background_tint.visible = false
	window.add_child(_tavern_background_tint)

	_combat_play_area = Control.new()
	_combat_play_area.name = "CombatPlayArea"
	_combat_play_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_play_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	window.add_child(_combat_play_area)

	_combat_stage = COMBAT_STAGE_SCRIPT.new()
	_combat_stage.name = "CombatStage"
	_combat_stage.safe_top_px = 132.0
	_combat_stage.safe_bottom_px = 28.0
	_combat_stage.actor_names_visible = false
	_combat_play_area.add_child(_combat_stage)

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", COMBAT_CONTENT_SEPARATION)
	window.add_child(content)
	_combat_content = content

	var title := Label.new()
	title.text = "Combat"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.theme_type_variation = &"PanelHeader"
	title.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	content.add_child(title)

	_playback_controls = PlaybackControls.new()
	_playback_controls.name = "PlaybackControls"
	_playback_controls.speed_selected.connect(_set_playback_speed)
	_playback_controls.skip_pressed.connect(_on_playback_skip_pressed)

	# Enemy status HUD, pinned directly under the panel title so the black
	# center of the window stays clear for future fight-action animations.
	content.add_child(_build_enemy_hud())

	_outcome_title_label = Label.new()
	_outcome_title_label.visible = false
	_outcome_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outcome_title_label.theme_type_variation = &"PanelHeader"
	_outcome_title_label.add_theme_font_size_override("font_size", OUTCOME_TITLE_FONT_SIZE)
	content.add_child(_outcome_title_label)

	_status_label = Label.new()
	_status_label.text = "Assemble your build and press FIGHT!"
	_status_label.visible = false
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(_status_label)

	# Kept for non-overlay outcome checks and legacy direct presentation calls;
	# live fight results now use the combat-window overlay built below.
	_recap_label = Label.new()
	_recap_label.visible = false
	_recap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_recap_label)

	_retry_button = Button.new()
	_retry_button.text = FLOW_TEXT.ACTION_RETRY_ENCOUNTER
	_retry_button.visible = false
	_retry_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_retry_button.pressed.connect(_on_retry_pressed)
	content.add_child(_retry_button)

	_restart_adventure_button = Button.new()
	_restart_adventure_button.text = FLOW_TEXT.ACTION_RESTART_ADVENTURE
	_restart_adventure_button.visible = false
	_restart_adventure_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_restart_adventure_button.pressed.connect(func(): adventure_restart_pressed.emit())
	content.add_child(_restart_adventure_button)

	var combat_content_spacer := Control.new()
	combat_content_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(combat_content_spacer)

	# Fight + Combat Log now live inside the Combat window's lower band. The
	# band is reserved out of the combat play area, so sprites/HUD/outcome
	# presentation stay anchored where they were before the panel grew.
	_fight_button_row = HBoxContainer.new()
	_fight_button_row.name = "FightButtonRow"
	_fight_button_row.add_theme_constant_override("separation", 8)
	_fight_button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fight_button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_fight_button_row.z_index = COMBAT_BUTTON_ROW_DEFAULT_Z_INDEX
	content.add_child(_fight_button_row)

	var combat_button_bottom_spacer := Control.new()
	combat_button_bottom_spacer.custom_minimum_size = Vector2(0, PANEL_SEPARATION)
	content.add_child(combat_button_bottom_spacer)

	# Popup layer: a full-panel, mouse-transparent layer the comic-book skill
	# popups spawn into (scripts/ui/combat_popup_layer.gd). Added after the
	# stage inside the play area, so popups follow the same reserved combat
	# rectangle as the actors instead of drifting into the button band.
	_popup_layer = CombatPopupLayer.new()
	_popup_layer.set_combat_stage(_combat_stage)
	_popup_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_combat_play_area.add_child(_popup_layer)

	window.resized.connect(_sync_combat_play_area_reserved_height)

	return window


func _build_fight_timer_badge() -> PanelContainer:
	var badge := PanelContainer.new()
	badge.name = "FightTimerBadge"
	badge.visible = false
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
	var frost := preload("res://scripts/ui/combat_clock_frost.gd").new()
	badge.add_child(frost)

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
	return _icon_texture_from_path(UI_CLOCK_ICON_PATH)


func _icon_texture_from_path(path: String) -> Texture2D:
	return load(path) as Texture2D


func _configure_top_icon_button(button: Button, button_name: String, texture: Texture2D, tooltip: String) -> void:
	button.name = button_name
	button.text = ""
	button.tooltip_text = tooltip
	button.custom_minimum_size = TOP_ACTION_BUTTON_SIZE
	button.icon = texture
	button.expand_icon = true
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_constant_override("h_separation", 0)
	button.add_theme_stylebox_override("normal", _top_icon_button_style(UIColors.BUTTON_FILL, UIColors.PANEL_BORDER))
	button.add_theme_stylebox_override("hover", _top_icon_button_style(UIColors.BUTTON_TOP_LIGHT, UIColors.PANEL_BORDER))
	button.add_theme_stylebox_override("pressed", _top_icon_button_style(UIColors.BUTTON_FILL_PRESSED, UIColors.PANEL_BORDER))
	button.add_theme_stylebox_override("focus", _top_icon_button_style(UIColors.BUTTON_FILL, UIColors.TEXT_GOLD))


func _top_icon_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 4
	style.border_width_bottom = 5
	style.border_blend = true
	style.set_corner_radius_all(6)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 5
	style.content_margin_bottom = 6
	style.shadow_color = UIColors.PANEL_DROP_SHADOW
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 3)
	return style


func _sync_combat_play_area_reserved_height() -> void:
	if _combat_play_area == null:
		return
	var button_band_height := COMBAT_BUTTON_BAND_FALLBACK_HEIGHT
	if _fight_button_row != null:
		var row_height := _fight_button_row.get_combined_minimum_size().y
		if row_height > 0.0:
			button_band_height = row_height + float(PANEL_SEPARATION * 2 + COMBAT_CONTENT_SEPARATION)
	if _combat_stage != null:
		_combat_stage.reserved_bottom_px = button_band_height
	_combat_play_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	_combat_play_area.offset_bottom = -button_band_height


## The enemy status HUD (user-requested combat-HUD addition, 2026-07-18):
## a compact block at the top of the black Combat panel -- enemy name + HP
## text over a health bar, a small status-chip row (poison stacks / armor
## shredded / resist shredded, post-fight only), and a one-line info readout
## of current armor / resistance. Intended to sit beside
## the enemy animations once those exist in a later phase; for now it's the
## HUD alone, anchored to the top edge so the panel center stays free.
## Presentation-only: every value comes from the current Monster resource
## (pre-fight) or the stored CombatResult (post-fight) -- no combat math is
## reimplemented here, per docs/Conventions.md's UI architecture principle.
func _build_enemy_hud() -> VBoxContainer:
	_enemy_hud = VBoxContainer.new()
	_enemy_hud.visible = false
	_enemy_hud.add_theme_constant_override("separation", 4)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	var name_cell := Control.new()
	name_cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_cell)

	_hud_name_label = Label.new()
	_hud_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_name_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_cell.add_child(_hud_name_label)

	var timer_cell := Control.new()
	timer_cell.name = "FightTimerCell"
	timer_cell.custom_minimum_size = FIGHT_TIMER_BADGE_SIZE
	timer_cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(timer_cell)

	var timer_badge := _build_fight_timer_badge()
	timer_badge.position = Vector2(0.0, -30.0)
	timer_cell.add_child(timer_badge)

	var values_cell := Control.new()
	values_cell.name = "CombatRightHudCell"
	values_cell.custom_minimum_size = Vector2(310, FIGHT_TIMER_BADGE_SIZE.y)
	values_cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(values_cell)

	var controls_row := HBoxContainer.new()
	controls_row.name = "PlaybackControlsRow"
	controls_row.alignment = BoxContainer.ALIGNMENT_END
	controls_row.anchor_left = 1.0
	controls_row.anchor_right = 1.0
	controls_row.anchor_top = 0.0
	controls_row.anchor_bottom = 0.0
	controls_row.offset_left = -395.0
	controls_row.offset_right = 0.0
	controls_row.offset_top = -28.0
	controls_row.offset_bottom = 0.0
	values_cell.add_child(controls_row)
	controls_row.add_child(_playback_controls)

	var values_row := HBoxContainer.new()
	values_row.name = "CombatValuesRow"
	values_row.add_theme_constant_override("separation", 14)
	values_row.alignment = BoxContainer.ALIGNMENT_END
	values_row.anchor_left = 1.0
	values_row.anchor_right = 1.0
	values_row.anchor_top = 0.0
	values_row.anchor_bottom = 0.0
	values_row.offset_left = -560.0
	values_row.offset_right = 0.0
	values_row.offset_top = 18.0
	values_row.offset_bottom = FIGHT_TIMER_BADGE_SIZE.y
	values_cell.add_child(values_row)

	var hp_icon := TextureRect.new()
	hp_icon.name = "HealthIcon"
	hp_icon.texture = HUD_HEALTH_ICON
	hp_icon.custom_minimum_size = COMBAT_STATUS_ICON_SIZE
	hp_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hp_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hp_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	values_row.add_child(hp_icon)
	_hud_hp_text_label = Label.new()
	_hud_hp_text_label.add_theme_font_size_override("font_size", COMBAT_STATUS_FONT_SIZE)
	values_row.add_child(_hud_hp_text_label)

	var armor_icon := TextureRect.new()
	armor_icon.name = "ArmorIcon"
	armor_icon.texture = HUD_ARMOR_ICON
	armor_icon.custom_minimum_size = COMBAT_STATUS_ICON_SIZE
	armor_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	armor_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	armor_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	armor_icon.tooltip_text = "Armor: Reduces Physical Damage"
	values_row.add_child(armor_icon)
	_hud_info_label = Label.new()
	_hud_info_label.tooltip_text = armor_icon.tooltip_text
	_hud_info_label.add_theme_font_size_override("font_size", COMBAT_STATUS_FONT_SIZE)
	values_row.add_child(_hud_info_label)

	var poison_resist_icon := TextureRect.new()
	poison_resist_icon.name = "PoisonResistIcon"
	poison_resist_icon.texture = HUD_RESISTANCE_ICON
	poison_resist_icon.custom_minimum_size = COMBAT_STATUS_ICON_SIZE
	poison_resist_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	poison_resist_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	poison_resist_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	poison_resist_icon.tooltip_text = "Resistance: Reduces elemental damage"
	values_row.add_child(poison_resist_icon)
	_hud_resist_label = Label.new()
	_hud_resist_label.name = "ResistText"
	_hud_resist_label.tooltip_text = poison_resist_icon.tooltip_text
	_hud_resist_label.add_theme_font_size_override("font_size", COMBAT_STATUS_FONT_SIZE)
	values_row.add_child(_hud_resist_label)

	_enemy_hud.add_child(name_row)

	_hud_health_bar = ProgressBar.new()
	_hud_health_bar.name = "EnemyHealthBar"
	_hud_health_bar.show_percentage = false
	_hud_health_bar.custom_minimum_size = Vector2(0, HEALTH_BAR_HEIGHT)
	_hud_health_bar.clip_contents = true
	var bar_background := StyleBoxFlat.new()
	bar_background.bg_color = UIColors.HEALTH_BAR_TRACK
	bar_background.border_color = UIColors.HEALTH_BAR_TRACK_BORDER
	bar_background.set_border_width_all(2)
	bar_background.border_width_top = 1
	bar_background.border_width_left = 1
	bar_background.border_width_right = 3
	bar_background.border_width_bottom = 4
	bar_background.border_blend = true
	bar_background.set_corner_radius_all(6)
	bar_background.shadow_color = UIColors.PANEL_DROP_SHADOW
	bar_background.shadow_size = 4
	bar_background.shadow_offset = Vector2(0, 2)
	_hud_health_bar.add_theme_stylebox_override("background", bar_background)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = UIColors.HEALTH_BAR_FILL
	bar_fill.border_color = UIColors.HEALTH_BAR_FILL_SHADOW
	bar_fill.border_width_top = 1
	bar_fill.border_width_left = 1
	bar_fill.border_width_right = 2
	bar_fill.border_width_bottom = 3
	bar_fill.border_blend = true
	bar_fill.set_corner_radius_all(5)
	_hud_health_bar.add_theme_stylebox_override("fill", bar_fill)
	var bar_depth_overlay := HealthBarDepthOverlay.new()
	bar_depth_overlay.name = "HealthBarDepthOverlay"
	bar_depth_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar_depth_overlay.bind(_hud_health_bar)
	_hud_health_bar.add_child(bar_depth_overlay)
	_enemy_hud.add_child(_hud_health_bar)

	_hud_effect_row = FlowContainer.new()
	_hud_effect_row.name = "EnemyEffectRow"
	_hud_effect_row.alignment = FlowContainer.ALIGNMENT_END
	_hud_effect_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_effect_row.custom_minimum_size = Vector2(0, 24)
	_hud_effect_row.add_theme_constant_override("h_separation", 8)
	_hud_effect_row.add_theme_constant_override("v_separation", 2)
	_enemy_hud.add_child(_hud_effect_row)

	_hud_status_row = FlowContainer.new()
	_hud_status_row.alignment = FlowContainer.ALIGNMENT_END
	_hud_status_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_status_row.custom_minimum_size = Vector2(0, 26)
	_hud_status_row.add_theme_constant_override("h_separation", 8)
	_hud_status_row.add_theme_constant_override("v_separation", 2)
	_enemy_hud.add_child(_hud_status_row)
	_effect_icons = CombatEffectIcons.new()
	_effect_icons.name = "TemporaryEffectIcons"
	var effects_layer := Control.new()
	effects_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects_layer.z_index = RESULT_OVERLAY_Z_INDEX - 1
	_combat_play_area.add_child(effects_layer)
	effects_layer.add_child(_effect_icons)
	_effect_icons.position = Vector2(8, 104)
	return _enemy_hud


## Single refresh for both HUD display states. Hidden whenever there is no
## enemy to show: the shop/reward overlays own the combat window in their
## states, and the pre-fight gating mirrors enemy_panel.gd::_refresh()'s
## own empty-state checks so the two enemy displays agree about when a
## target exists.
func _refresh_enemy_hud() -> void:
	if _enemy_hud == null:
		return
	# During a playback the timeline drives the HUD directly (per fired
	# event); signal-driven refreshes must not overwrite the animated values
	# or leak the already-resolved outcome early.
	if _playback_active:
		return
	if _shop_overlay != null and _shop_overlay.visible:
		_enemy_hud.visible = false
		_set_fight_timer_visible(false)
		return
	if _reward_choice_overlay != null and _reward_choice_overlay.visible:
		_enemy_hud.visible = false
		_set_fight_timer_visible(false)
		return
	if _hud_result != null and _hud_result_monster != null:
		_render_enemy_hud_post_fight()
		return
	var enemy := _hud_pre_fight_monster()
	if enemy == null:
		_enemy_hud.visible = false
		_set_fight_timer_visible(false)
		_update_combat_stage_target(null)
		return
	_set_enemy_hud_display(enemy.display_name, float(enemy.hp), enemy.hp, enemy.armor, enemy.poison_resistance)
	_refresh_enemy_effect_chips(enemy)
	_clear_hud_status_chips()
	COMBAT_STATUS_ICONS.add_timed_defense_chips(null, _add_hud_status_chip)
	_add_hud_status_chip("x0", UIColors.TEXT_POISON, HUD_POISON_ICON)
	_add_hud_status_chip("x0", UIColors.TEXT_WARNING, HUD_SHRED_ICON, _shred_status_tooltip())
	_add_hud_status_chip("x0", UIColors.TEXT_MAGIC, HUD_DECAY_ICON)
	_add_interrupt_status_chip(enemy, 0)
	_enemy_hud.visible = true
	_refresh_fight_timer_badge()
	_update_combat_stage_target(enemy)
	if _combat_stage != null and _should_stage_generated_contract_enemy_only():
		_combat_stage.show_enemy_waiting_for_player()


## The monster the HUD should show before a fight, or null when the current
## state has no fightable target -- the same gating enemy_panel.gd's
## _refresh() uses for its own empty state.
func _hud_pre_fight_monster() -> Monster:
	if BuildState.run_phase == BuildState.RunPhase.RUN_ENDED:
		return null
	if BuildState.run_phase == BuildState.RunPhase.CONTRACT_OFFER:
		return null
	if BuildState.run_phase == BuildState.RunPhase.CONTRACT_ROUTE and not BuildState.is_contract_fight_active():
		return null
	if BuildState.needs_tavern_map_choice():
		return null
	return BuildState.current_target_monster()


func _render_enemy_hud_post_fight() -> void:
	var monster := _hud_result_monster
	var result := _hud_result
	var remaining := _hud_post_fight_hp(result, monster)
	var final_armor := _hud_final_armor(result, monster)
	var final_resist := _hud_final_poison_resist(result, monster)
	var peak_stacks := _hud_peak_poison_stacks(result.tick_events)
	var shred_stacks := _hud_armor_reduction_cast_count(result.cast_events)
	var decay_stacks := _hud_poison_resistance_reduction_cast_count(result.cast_events)
	var interrupt_repeats := _hud_interrupt_repeat_count(result.cast_events)
	_set_enemy_hud_display(monster.display_name, remaining, monster.hp, final_armor, final_resist)
	_refresh_enemy_effect_chips(monster)
	_clear_hud_status_chips()
	COMBAT_STATUS_ICONS.add_timed_defense_chips(null, _add_hud_status_chip)
	_add_hud_status_chip("x%d" % peak_stacks, UIColors.TEXT_POISON, HUD_POISON_ICON)
	_add_hud_status_chip("x%d" % shred_stacks, UIColors.TEXT_WARNING, HUD_SHRED_ICON, _shred_status_tooltip())
	_add_hud_status_chip("x%d" % decay_stacks, UIColors.TEXT_MAGIC, HUD_DECAY_ICON)
	_add_interrupt_status_chip(monster, interrupt_repeats)
	_enemy_hud.visible = true
	_refresh_fight_timer_badge()


func _set_enemy_hud_display(display_name: String, hp_remaining: float, hp_max: int, armor: int, poison_resistance: float) -> void:
	_hud_name_label.text = display_name
	# ceili() so a not-quite-dead enemy never displays a misleading "0" --
	# hp_remaining is only exactly 0.0 on a win (total damage >= HP).
	_hud_hp_text_label.text = "%d/%d" % [ceili(hp_remaining), hp_max]
	_hud_health_bar.max_value = hp_max
	_hud_health_bar.value = hp_remaining
	var depth_overlay := _hud_health_bar.get_node_or_null("HealthBarDepthOverlay") as Control
	if depth_overlay != null:
		depth_overlay.queue_redraw()
	_hud_info_label.text = "%d" % armor
	if _hud_resist_label != null:
		_hud_resist_label.text = "%.0f%%" % (poison_resistance * 100.0)
	_refresh_fight_timer_badge()


func _refresh_enemy_effect_chips(monster: Monster) -> void:
	if _hud_effect_row == null:
		return
	_clear_enemy_effect_chips()
	if monster == null:
		return
	for indicator in _enemy_effect_indicators(monster):
		_add_enemy_effect_chip(indicator)


func _clear_enemy_effect_chips() -> void:
	if _hud_effect_row == null:
		return
	for child in _hud_effect_row.get_children():
		_hud_effect_row.remove_child(child)
		child.queue_free()


func _add_enemy_effect_chip(indicator: Dictionary) -> void:
	var chip: HBoxContainer = COMBAT_STATUS_ICONS.add_icon_label(
		_hud_effect_row,
		indicator["icon"],
		String(indicator["text"]),
		indicator["color"],
		"EnemyEffectChip"
	)
	chip.set_meta("effect_id", indicator["id"])
	chip.tooltip_text = String(indicator["tooltip"])


func _enemy_effect_indicators(monster: Monster) -> Array:
	if monster == null:
		return []
	var indicators := []
	_add_enemy_effect_indicator(indicators, "dodge_chance", monster.dodge_chance > 0.0, MECHANIC_DODGE_ICON, "%.0f%%" % (monster.dodge_chance * 100.0), UIColors.TEXT_WARNING, _enemy_mechanic_tooltip("dodge_chance", monster))
	_add_enemy_effect_indicator(indicators, "crit_negation", monster.crit_negation > 0.0, MECHANIC_CRIT_NEGATION_ICON, "%.0f%%" % (monster.crit_negation * 100.0), UIColors.TEXT_WARNING, _enemy_mechanic_tooltip("crit_negation", monster))
	_add_enemy_effect_indicator(indicators, "block", monster.block > 0.0, MECHANIC_BLOCK_ICON, "%.0f" % monster.block, UIColors.TEXT_WARNING, _enemy_mechanic_tooltip("block", monster))
	_add_enemy_effect_indicator(indicators, "absorb", monster.absorb > 0.0, MECHANIC_ABSORB_ICON, "%.0f" % monster.absorb, UIColors.TEXT_MAGIC, _enemy_mechanic_tooltip("absorb", monster))
	_add_enemy_effect_indicator(indicators, "cleanse_threshold", monster.cleanse_threshold > 0, MECHANIC_CLEANSE_ICON, "%d" % monster.cleanse_threshold, UIColors.TEXT_POISON, _enemy_mechanic_tooltip("cleanse_threshold", monster))
	_add_enemy_effect_indicator(indicators, "suppress", monster.suppress > 0.0, MECHANIC_SUPPRESS_ICON, "%.0f%%" % (monster.suppress * 100.0), UIColors.TEXT_MAGIC, _enemy_mechanic_tooltip("suppress", monster))
	_add_enemy_effect_indicator(indicators, "slow", monster.slow > 0.0, MECHANIC_SLOW_ICON, "%.0f%%" % (monster.slow * 100.0), UIColors.TEXT_MAGIC, _enemy_mechanic_tooltip("slow", monster))
	_add_enemy_effect_indicator(indicators, "stun_duration_ms", monster.stun_duration_ms > 0, MECHANIC_STUN_ICON, _format_stun_duration(monster.stun_duration_ms), UIColors.TEXT_MAGIC, _enemy_mechanic_tooltip("stun_duration_ms", monster))
	return indicators


func _add_enemy_effect_indicator(indicators: Array, id: String, enabled: bool, icon: Texture2D, text: String, color: Color, tooltip: String) -> void:
	if not enabled:
		return
	indicators.append({
		"id": id,
		"icon": icon,
		"text": text,
		"color": color,
		"tooltip": tooltip,
	})


func _set_fight_timer_visible(is_visible: bool) -> void:
	if _fight_timer_badge != null:
		_fight_timer_badge.visible = is_visible


func _refresh_fight_timer_badge() -> void:
	if _fight_timer_badge == null or _fight_timer_label == null:
		return
	var has_target := _enemy_panel != null and _enemy_panel.monster() != null
	if not has_target:
		_set_fight_timer_visible(false)
		return
	_fight_timer_label.text = _format_fight_timer_ms(_enemy_panel.duration_ms(), false)
	_set_fight_timer_visible(_enemy_hud != null and _enemy_hud.visible)

func _update_fight_timer_countdown(elapsed_ms: float, window_ms: int) -> void:
	if _fight_timer_badge == null or _fight_timer_label == null:
		return
	var remaining_ms := _playback_presenter.countdown_remaining_ms() if _playback_presenter != null else maxf(0.0, float(window_ms) - elapsed_ms)
	_fight_timer_label.text = _format_fight_timer_ms(roundi(remaining_ms), true)
	_set_fight_timer_visible(true)


func _format_fight_timer_ms(time_ms: int, show_decimal: bool) -> String:
	var seconds := maxf(0.0, float(time_ms) / 1000.0)
	if show_decimal:
		return "%.1fs" % seconds
	return "%ds" % ceili(seconds)


func _clear_hud_status_chips() -> void:
	# remove_child() before queue_free() so the chip row's child list is
	# accurate immediately -- several HUD refreshes happen in the same frame
	# during a synchronous fight resolution, and stale queued-free chips
	# would otherwise coexist with the fresh ones until end of frame (the
	# same stale-child class of bug P2:R7:T4's _refresh() note documents).
	for child in _hud_status_row.get_children():
		_hud_status_row.remove_child(child)
		child.queue_free()


func _add_hud_status_chip(text: String, color: Color, icon: Texture2D = null, tooltip: String = "", countdown: float = -1.0) -> void:
	if tooltip == "":
		tooltip = _status_chip_tooltip(icon)
	if icon != null:
		var icon_chip: HBoxContainer = COMBAT_STATUS_ICONS.add_status_icon_label(_hud_status_row, icon, text, color, countdown)
		if tooltip != "":
			icon_chip.tooltip_text = tooltip
		return
	var chip := Label.new()
	chip.name = "StatusChip"
	chip.text = text
	chip.add_theme_color_override("font_color", color)
	chip.add_theme_font_size_override("font_size", COMBAT_STATUS_FONT_SIZE)
	_hud_status_row.add_child(chip)


func _shred_status_tooltip() -> String:
	return "Shred: Each stack reduces armor by %d" % _current_shred_value()


func _status_chip_tooltip(icon: Texture2D) -> String:
	if icon == HUD_POISON_ICON:
		return "Poison: Deals %s damage every 1.0s" % _current_base_poison_damage_text()
	if icon == HUD_SHRED_ICON:
		return _shred_status_tooltip()
	if icon == HUD_DECAY_ICON:
		return "Decay: Each stack reduces resistance by %.0f%%" % (_current_player_stats().decay_value * 100.0)
	if icon == MECHANIC_INTERRUPT_ICON:
		var monster := _hud_result_monster
		if monster == null:
			monster = _hud_pre_fight_monster()
		return _interrupt_status_tooltip(monster)
	return ""


func _current_base_poison_damage_text() -> String:
	var stats := _current_player_stats()
	var base_damage := stats.base_poison_damage + stats.bonus_base_elemental_damage
	if stats.base_poison_damage > 0.0 or stats.bonus_base_elemental_damage != 0.0:
		base_damage = maxf(PlayerStats.MIN_DAMAGE_BASE, base_damage)
	return "%.1f" % base_damage


func _current_shred_value() -> int:
	return _current_player_stats().shred_value


func _current_player_stats() -> PlayerStats:
	if BuildState.selected_class == null:
		return PlayerStats.new()
	return BuildState.current_player_stats()


func _interrupt_status_tooltip(monster: Monster) -> String:
	var prevented := monster.interrupt_skip_count if monster != null else 0
	return "Interrupt: Casting %d times prevents next %d casts" % [CombatResolver.INTERRUPT_REPEAT_THRESHOLD, prevented]


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


func _flash_hud_status_chips() -> void:
	hud_status_chip_flash_count += 1
	_flash_status_chip_row(_hud_status_row)


func _flash_status_chip_row(row: Container) -> void:
	if row == null:
		return
	for child in row.find_children("*", "HBoxContainer", true, false):
		var icon := child.get_node_or_null("Icon") as TextureRect
		if icon == null or not [HUD_POISON_ICON, HUD_SHRED_ICON, HUD_DECAY_ICON].has(icon.texture):
			continue
		child.modulate = Color(1.0, 1.0, 1.0, 1.0)
		child.scale = Vector2.ONE
		child.pivot_offset = child.size * 0.5
		var tween := child.create_tween()
		tween.set_parallel(true)
		tween.tween_property(child, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(child, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
		tween.chain().tween_property(child, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(child, "modulate", Color.WHITE, 0.18)


func _add_interrupt_status_chip(monster: Monster, repeat_count: int) -> void:
	if monster == null or monster.interrupt_skip_count <= 0:
		return
	_add_hud_status_chip("%d/%d" % [repeat_count, CombatResolver.INTERRUPT_REPEAT_THRESHOLD], UIColors.TEXT_MAGIC, MECHANIC_INTERRUPT_ICON)


func _format_stun_duration(duration_ms: int) -> String:
	var seconds := float(duration_ms) / 1000.0
	if is_equal_approx(seconds, roundf(seconds)):
		return "%ds" % int(roundf(seconds))
	return "%.1fs" % seconds


## Stores a resolved fight for the HUD's post-fight display state and
## refreshes immediately. Called from _on_fight_pressed() for both outcomes.
func _show_enemy_hud_post_fight(result: CombatResolver.CombatResult, monster: Monster) -> void:
	_hud_result = result
	_hud_result_monster = monster
	_refresh_enemy_hud()
	_update_combat_stage_target(monster)


## Drops the stored post-fight result so the HUD returns to its pre-fight
## display for whatever target the run state now points at. Called at every
## new-fight setup transition, the same call sites that clear the T7 recap.
func _reset_enemy_hud() -> void:
	_hud_result = null
	_hud_result_monster = null
	_refresh_enemy_hud()


func _update_combat_stage_target(monster: Monster) -> void:
	if _combat_stage == null:
		return
	if monster == null:
		_combat_stage.clear_target()
		return
	_combat_stage.configure("Rogue", monster.display_name, _combat_stage_visual_name(monster), _combat_stage_visual_role(monster))


func _combat_stage_visual_name(monster: Monster) -> String:
	if monster == null:
		return ""
	if BuildState.current_route_node == null:
		return monster.display_name
	var biome := BuildState.current_route_node.biome
	if biome == "" and BuildState.active_contract != null:
		biome = BuildState.active_contract.selected_biome
	var biome_name := "%s %s" % [biome, monster.display_name]
	if CombatStage.enemy_visual_key_for(biome_name) != "":
		return biome_name
	return monster.display_name


func _combat_stage_visual_role(monster: Monster) -> String:
	if BuildState.current_route_node != null:
		match BuildState.current_route_node.node_type:
			ContractRouteNode.NodeType.CAPTAIN:
				return CombatStage.ENEMY_COMBAT_ROLE_CAPTAIN
			ContractRouteNode.NodeType.ELITE:
				return CombatStage.ENEMY_COMBAT_ROLE_ELITE
			ContractRouteNode.NodeType.BOSS:
				return CombatStage.ENEMY_COMBAT_ROLE_BOSS
	if monster != null:
		return monster.combat_role
	return CombatStage.ENEMY_COMBAT_ROLE_NORMAL


func _should_use_contract_traversal_animation() -> bool:
	return (
		BuildState.is_contract_fight_active()
		and BuildState.active_contract != null
		and BuildState.active_contract.has_generated_route_state()
	)


func _should_stage_generated_contract_enemy_only() -> bool:
	return (
		_should_use_contract_traversal_animation()
		and BuildState.run_phase == BuildState.RunPhase.PLANNING
		and not _playback_active
		and _hud_result == null
		and not _contract_route_player_entered
	)


## Enemy HP left after the resolved fight, clamped to [0, monster.hp] --
## exactly 0 on a win (CombatResolver sets is_win when total damage reaches
## HP), positive on a loss where the damage fell short.
func _hud_post_fight_hp(result: CombatResolver.CombatResult, monster: Monster) -> float:
	if monster == null or result == null:
		return 0.0
	return clampf(float(monster.hp) - result.total_health_loss(), 0.0, float(monster.hp))


## Active armor reduction at fight end, replaying cleanse resets from the
## resolved event timeline.
func _hud_total_armor_reduction(cast_events: Array) -> int:
	var total := 0
	for event in cast_events:
		total += event.armor_reduction_applied
		if event.cleanse_triggered:
			total = 0
	return total


func _hud_armor_reduction_cast_count(cast_events: Array) -> int:
	var total := 0
	for event in cast_events:
		total += event.shred_stacks_applied
		if event.cleanse_triggered:
			total = 0
	return total


func _hud_poison_resistance_reduction_cast_count(cast_events: Array) -> int:
	var total := 0
	for event in cast_events:
		if event.poison_resistance_reduction_applied > 0.0:
			total += event.decay_stacks_applied
		if event.cleanse_triggered:
			total = 0
	return total


func _hud_interrupt_repeat_count(cast_events: Array) -> int:
	var repeat_count := 0
	for event in cast_events:
		repeat_count = event.interrupt_repeat_count_after
	return repeat_count


## The monster's armor at fight end: base armor minus active reduction after
## replaying any cleanse resets. Not new combat math -- just replaying the
## recorded events.
func _hud_final_armor(result: CombatResolver.CombatResult, monster: Monster) -> int:
	if monster == null or result == null:
		return 0
	return monster.armor - _hud_total_armor_reduction(result.cast_events)


## The monster's resistance at fight end: the base value with active
## reductions replayed and cleanse resets honored.
func _hud_final_poison_resist(result: CombatResolver.CombatResult, monster: Monster) -> float:
	if monster == null or result == null:
		return 0.0
	var resist := monster.poison_resistance
	for event in result.cast_events:
		if event.poison_resistance_reduction_applied > 0.0:
			resist *= 1.0 - clampf(event.poison_resistance_reduction_applied, 0.0, 1.0)
		if event.cleanse_triggered:
			resist = monster.poison_resistance
	return resist


## Highest concurrent poison stack count observed across the fight's ticks
## -- the same stacks_remaining + 1 read that CombatRecap uses
## (TickEvent records the count after its own decrement).
func _hud_peak_poison_stacks(tick_events: Array) -> int:
	var peak := 0
	for tick in tick_events:
		if tick.damage <= 0.0:
			continue
		var stacks_before_tick: int = tick.stacks_remaining + 1
		if stacks_before_tick > peak:
			peak = stacks_before_tick
	return peak


## Victory banner: shown automatically after a winning fight, with a compact
## recap (total damage, biggest hit, physical/poison damage split from
## CombatRecap). A true full-rect overlay added at the screen root -- same
## shape as the combat log overlay -- not a normal flow child of
## _combat_content (bug fix: it used to be a CenterContainer added straight
## into _combat_content's VBoxContainer, so becoming visible immediately grew
## that VBox's required height by the whole reward panel's worth of content,
## pushing every later sibling down and, with no ScrollContainer anywhere in
## this screen, off the bottom of the viewport with no way to reach it).
## Deliberately non-modal: the visible result content sits over the combat
## window, but dashboard controls such as View Combat Log remain usable.
func _build_victory_overlay() -> void:
	_victory_overlay = Control.new()
	_victory_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_victory_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_victory_overlay.z_index = RESULT_OVERLAY_Z_INDEX
	_victory_overlay.visible = false
	add_child(_victory_overlay)

	var backdrop := ColorRect.new()
	backdrop.name = "VictoryClickBlocker"
	backdrop.color = Color(0.0, 0.0, 0.0, 0.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_victory_overlay.add_child(backdrop)

	# Deliberately positioned over the combat window only: the screen-level
	# overlay is non-modal, and the visible result state belongs to the fight
	# stage instead of reading as a separate full-screen modal.
	var center := Control.new()
	center.name = "VictoryCombatWindowOverlay"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_victory_center = center
	_victory_overlay.add_child(center)

	var combat_dim := ColorRect.new()
	combat_dim.name = "VictoryCombatDim"
	combat_dim.color = UIColors.RESULT_DIM
	combat_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combat_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_victory_combat_dim = combat_dim
	center.add_child(combat_dim)

	var content_center := CenterContainer.new()
	content_center.name = "VictoryContentCenter"
	content_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_child(content_center)

	var stack := VBoxContainer.new()
	stack.name = "VictoryStack"
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.custom_minimum_size = Vector2(430, 0)
	stack.add_theme_constant_override("separation", 10)
	_victory_stack = stack
	content_center.add_child(stack)

	var banner_title := Label.new()
	_victory_title_label = banner_title
	banner_title.text = "VICTORY!"
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_title.theme_type_variation = &"PanelHeader"
	banner_title.add_theme_font_size_override("font_size", VICTORY_TITLE_FONT_SIZE)
	banner_title.add_theme_color_override("font_color", CardStyle.ACCENT_COLOR)
	stack.add_child(banner_title)

	var top_rule := ColorRect.new()
	top_rule.name = "VictoryTopRule"
	_victory_top_rule = top_rule
	top_rule.color = Color(CardStyle.ACCENT_COLOR.r, CardStyle.ACCENT_COLOR.g, CardStyle.ACCENT_COLOR.b, 0.72)
	top_rule.custom_minimum_size = Vector2(0, 2)
	stack.add_child(top_rule)

	_outcome_message_label = Label.new()
	_outcome_message_label.visible = false
	_outcome_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outcome_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_outcome_message_label)

	_victory_recap_label = Label.new()
	_victory_recap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(_victory_recap_label)

	var reward_row := HBoxContainer.new()
	_victory_reward_row = reward_row
	reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_row.add_theme_constant_override("separation", 9)
	_reward_label = Label.new()
	_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reward_label.add_theme_color_override("font_color", UIColors.TEXT_GOLD)
	reward_row.add_child(_reward_label)
	stack.add_child(reward_row)

	var button_row := HBoxContainer.new()
	_victory_button_row = button_row
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 12)

	var continue_button := Button.new()
	continue_button.text = "Claim Rewards"
	continue_button.pressed.connect(_on_continue_pressed)
	_continue_button = continue_button
	button_row.add_child(_continue_button)

	_outcome_retry_button = Button.new()
	_outcome_retry_button.text = FLOW_TEXT.ACTION_RETRY_ENCOUNTER
	_outcome_retry_button.visible = false
	_outcome_retry_button.pressed.connect(_on_retry_pressed)
	button_row.add_child(_outcome_retry_button)

	_outcome_restart_button = Button.new()
	_outcome_restart_button.text = FLOW_TEXT.ACTION_RESTART_ADVENTURE
	_outcome_restart_button.visible = false
	_outcome_restart_button.pressed.connect(func(): adventure_restart_pressed.emit())
	button_row.add_child(_outcome_restart_button)

	stack.add_child(button_row)


func _show_victory_banner(result: CombatResolver.CombatResult, monster: Monster) -> void:
	_set_result_button_layer_active(true)
	_status_label.visible = false
	_outcome_title_label.visible = false
	_recap_label.visible = false
	_view_log_button.visible = true
	_retry_button.visible = false
	_restart_adventure_button.visible = false
	_victory_title_label.text = "VICTORY!"
	_victory_title_label.add_theme_color_override("font_color", CardStyle.ACCENT_COLOR)
	_victory_top_rule.color = Color(CardStyle.ACCENT_COLOR.r, CardStyle.ACCENT_COLOR.g, CardStyle.ACCENT_COLOR.b, 0.72)
	_outcome_message_label.visible = false
	_victory_recap_label.text = "\n".join(_build_victory_recap_lines(result, monster))
	_victory_reward_row.visible = true
	_populate_reward_row()
	_continue_button.disabled = BuildState.has_claimed_current_reward()
	_continue_button.tooltip_text = _claim_reward_tooltip()
	_continue_button.visible = true
	_outcome_retry_button.visible = false
	_outcome_restart_button.visible = false
	_position_victory_center_over_combat_window()
	_prepare_victory_reveal_animation()
	_victory_overlay.visible = true
	_play_victory_reveal_animation()


func _show_defeat_banner(result: CombatResolver.CombatResult, monster: Monster) -> void:
	_set_result_button_layer_active(true)
	var presentation := _outcome_presentation(BuildState.run_outcome)
	_status_label.visible = false
	_outcome_title_label.visible = false
	_recap_label.visible = false
	_view_log_button.visible = true
	_retry_button.visible = false
	_restart_adventure_button.visible = false
	var title_color: Color = presentation["color"]
	_victory_title_label.text = String(presentation["title"])
	_victory_title_label.add_theme_color_override("font_color", title_color)
	_victory_top_rule.color = Color(title_color.r, title_color.g, title_color.b, 0.72)
	_outcome_message_label.visible = false
	_victory_recap_label.text = "\n".join(_build_defeat_recap_lines(result, monster))
	_victory_reward_row.visible = false
	_continue_button.visible = false
	_outcome_retry_button.visible = bool(presentation["show_retry"])
	_outcome_retry_button.disabled = false
	_outcome_restart_button.visible = bool(presentation["show_restart"])
	_outcome_restart_button.disabled = false
	_outcome_restart_button.text = String(presentation["restart_text"])
	_position_victory_center_over_combat_window()
	_prepare_victory_reveal_animation()
	_victory_overlay.visible = true
	_play_victory_reveal_animation()


func _set_result_button_layer_active(active: bool) -> void:
	if _fight_button_row == null:
		return
	_fight_button_row.z_index = COMBAT_BUTTON_ROW_Z_INDEX if active else COMBAT_BUTTON_ROW_DEFAULT_Z_INDEX


## Recomputes _victory_center's rect from the combat window's current global
## rect -- done live (not just once at build time) so the banner still lands
## in the right place after any window resize between fights.
func _position_victory_center_over_combat_window() -> void:
	if _combat_window == null or _victory_center == null:
		return
	if _victory_overlay != null:
		_victory_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var target_rect := _combat_window.get_global_rect()
	var overlay_origin := _victory_overlay.get_global_rect().position
	_victory_center.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_victory_center.position = target_rect.position - overlay_origin
	_victory_center.size = target_rect.size
	# Keep result actions above the independently raised Fight/Log row.
	var content_center := _victory_center.get_node("VictoryContentCenter") as Control
	var button_top := _fight_button_row.get_global_rect().position.y
	content_center.offset_bottom = -maxf(0.0, target_rect.end.y - button_top + PANEL_SEPARATION)
	if _victory_combat_dim != null:
		_victory_combat_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _victory_overlay != null:
		var click_blocker := _victory_overlay.find_child("VictoryClickBlocker", true, false) as ColorRect
		if click_blocker != null:
			click_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _prepare_victory_reveal_animation() -> void:
	if _victory_combat_dim != null:
		_victory_combat_dim.modulate.a = 0.0
	if _victory_stack != null:
		_victory_stack.modulate.a = 0.0
		_victory_stack.scale = Vector2.ONE * 0.96
		_victory_stack.pivot_offset = _victory_stack.size * 0.5


func _play_victory_reveal_animation() -> void:
	if _victory_combat_dim != null:
		var dim_tween := create_tween()
		dim_tween.tween_property(_victory_combat_dim, "modulate:a", 1.0, 0.18)
	if _victory_stack != null:
		var stack_tween := create_tween()
		stack_tween.set_parallel(true)
		stack_tween.tween_property(_victory_stack, "modulate:a", 1.0, 0.22)
		stack_tween.tween_property(_victory_stack, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## P2:R7:T7 -- compact, buildcraft-focused fight recap shared by the win
## banner (_victory_recap_label, inside _victory_overlay) and the loss path
## (_recap_label, shown inline in the main _combat_content column since a
## loss has no overlay of its own). Two always-present headline lines
## restate the actual result next to the target's required number (per the
## task's "needed X, did Y" framing), followed by a short list of secondary
## highlight lines; armor-reduction and poison lines are omitted entirely
## when that mechanic didn't come up in the fight, keeping a build with
## neither poison nor armor shred from reading a wall of "0"/"N/A" lines.
## Every field is read directly off the already-resolved CombatResult's
## CastEvent/TickEvent arrays -- no combat math is reimplemented here, per
## docs/Conventions.md's UI architecture principle.
func _build_recap_lines(result: CombatResolver.CombatResult, monster: Monster) -> PackedStringArray:
	var lines: PackedStringArray = []
	var summary := CombatRecap.summarize(result, monster)
	lines.append("Elapsed combat: %ss" % LegendaryCatalog.number_text(result.duration_ms / 1000.0))
	if result.countdown_rate != 1.0:
		lines.append("Encounter countdown: %ss at %.0f%% speed" % [LegendaryCatalog.number_text(result.nominal_duration_ms / 1000.0), result.countdown_rate * 100.0])
	if result.total_health_removed > 0:
		lines.append("Health lost: %.1f (needed %d)" % [result.total_health_loss(), monster.hp])
		lines.append("Damage: %.1f; health removed: %.1f" % [result.total_damage, result.total_health_removed])
	else:
		lines.append("Total Damage: %.1f (needed %d)" % [summary["total_damage"], summary["damage_required"]])
	lines.append("DPS: %.1f (damage only)" % summary["actual_dps"] if result.total_health_removed > 0 else "DPS: %.1f (needed %.1f)" % [summary["actual_dps"], summary["required_dps"]])
	lines.append(_biggest_hit_text(summary))
	lines.append(_damage_split_text(summary))
	lines.append(_crit_count_text(summary))
	var armor_line := _armor_reduction_summary(summary)
	if armor_line != "":
		lines.append(armor_line)
	var poison_line := _poison_summary_text(summary)
	if poison_line != "":
		lines.append(poison_line)
	return lines


## Result overlays should show the proof result without handing the player
## every diagnostic. Deeper stack, crit, DPS, and armor behavior stays
## discoverable through playback and the Combat Log.
func _build_victory_recap_lines(result: CombatResolver.CombatResult, monster: Monster) -> PackedStringArray:
	var lines: PackedStringArray = []
	var summary := CombatRecap.summarize(result, monster)
	if result.total_health_removed > 0:
		lines.append("Health lost: %.1f (needed %d)" % [result.total_health_loss(), monster.hp])
		lines.append("Damage: %.1f; health removed: %.1f" % [result.total_damage, result.total_health_removed])
	else:
		lines.append("Total Damage: %.1f (needed %d)" % [summary["total_damage"], summary["damage_required"]])
	lines.append(_biggest_hit_text(summary))
	lines.append(_damage_split_text(summary))
	return lines


func _build_defeat_recap_lines(result: CombatResolver.CombatResult, monster: Monster) -> PackedStringArray:
	var lines := _build_victory_recap_lines(result, monster)
	lines.append("Contracts Completed: %d" % BuildState.completed_contract_count)
	lines.append("Highest DPS This Run: %.1f" % BuildState.highest_run_dps)
	return lines


## Largest single direct cast (poison ticks are damage-over-time, not a
## "hit"), naming the skill and whether that specific cast crit -- e.g.
## "Biggest Hit: Heavy Slash for 84.0 (crit)".
func _biggest_hit_text(summary: Dictionary) -> String:
	if String(summary["biggest_hit_skill"]) == "":
		return "Biggest Hit: none."
	var crit_note := " (crit)" if bool(summary["biggest_hit_was_crit"]) else ""
	return "Biggest Hit: %s for %.1f%s" % [summary["biggest_hit_skill"], summary["biggest_hit"], crit_note]


## Physical (direct cast damage) vs. poison (tick damage) split, both as raw
## amounts and as a share of total damage -- Rogue's Assassin/Bladedancer/Shadow/Thief
## identity hinges on this split per the Phase 1 reference docs.
func _damage_split_text(summary: Dictionary) -> String:
	return "Physical: %.0f (%.0f%%) / Poison: %.0f (%.0f%%)" % [
		summary["physical_damage"], summary["physical_pct"], summary["poison_damage"], summary["poison_pct"]
	]


## Counts crit occurrences across every direct cast (a triggered skill's own
## hit can also crit independently of its source cast).
func _crit_count_text(summary: Dictionary) -> String:
	return "Crits: %d" % summary["crit_count"]


## Only returns a non-empty line when at least one cast actually applied
## armor reduction (Rending Slash, Sunder, etc. via ArmorReductionEffect) --
## omitted entirely otherwise so a build with no armor shred doesn't show a
## dead "0" line.
func _armor_reduction_summary(summary: Dictionary) -> String:
	var casts: int = summary["armor_reduction_casts"]
	if casts == 0:
		return ""
	return "Armor reduced by %d (%d cast%s)" % [
		summary["armor_reduction_total"], casts, "" if casts == 1 else "s"
	]


## Only returns a non-empty line when poison actually ticked this fight --
## omitted entirely for a build with no poison stacks applied. "Peak stacks"
## reads the stack count immediately before each tick consumed one (i.e.
## TickEvent.stacks_remaining + 1 for any tick that actually dealt damage),
## since TickEvent only records the count left *after* the tick.
func _poison_summary_text(summary: Dictionary) -> String:
	var ticks: int = summary["poison_tick_count"]
	if ticks == 0:
		return ""
	return "Poison: %d ticks, peak %d stacks, %.1f tick damage" % [
		ticks, summary["peak_poison_stacks"], summary["poison_tick_damage"]
	]


func _reward_text() -> String:
	var reward := BuildState.current_reward()
	if reward == null:
		return "Rewards: none."
	var parts: PackedStringArray = []
	var total_gold := BuildState.current_modified_reward_gold()
	var overkill_gold := BuildState.current_overkill_gold()
	if total_gold > 0:
		var gold_text := "%dg" % total_gold
		if overkill_gold > 0:
			gold_text += " (%dg overkill)" % overkill_gold
		parts.append(gold_text)
	if reward.talent_points > 0:
		parts.append("%d talent point%s" % [
			reward.talent_points,
			"" if reward.talent_points == 1 else "s",
		])
	for gear in reward.fixed_gear_rewards:
		if gear != null:
			parts.append(gear.display_name)
	if reward.unlocks_shop:
		parts.append("shop access")
	if reward.gear_choice_rewards.size() > 0:
		var gear_names: PackedStringArray = []
		for gear in reward.gear_choice_rewards:
			if gear != null:
				gear_names.append(gear.display_name)
		if not gear_names.is_empty():
			parts.append("choose %s" % " or ".join(gear_names))
	var generated_choice_text := _generated_reward_choice_text(reward)
	if generated_choice_text != "":
		parts.append(generated_choice_text)
	if parts.is_empty():
		return "Rewards: none."
	return "Rewards: %s." % ", ".join(parts)


func _populate_reward_row() -> void:
	if _victory_reward_row == null:
		return
	_reward_label = null
	_reward_gold_icon = null
	_reward_talent_icon = null
	for child in _victory_reward_row.get_children():
		_victory_reward_row.remove_child(child)
		child.queue_free()

	var reward := BuildState.current_reward()
	if reward == null:
		_victory_reward_row.add_child(_make_reward_label("No rewards.", UIColors.TEXT_DISABLED))
		return

	var added_reward_piece := false
	var text_parts: PackedStringArray = []
	for gear in reward.fixed_gear_rewards:
		if gear != null:
			text_parts.append(gear.display_name)
	if reward.unlocks_shop:
		text_parts.append("shop access")
	if reward.gear_choice_rewards.size() > 0:
		var gear_names: PackedStringArray = []
		for gear in reward.gear_choice_rewards:
			if gear != null:
				gear_names.append(gear.display_name)
		if not gear_names.is_empty():
			text_parts.append("choose %s" % " or ".join(gear_names))
	var generated_choice_text := _generated_reward_choice_text(reward)
	if generated_choice_text != "":
		text_parts.append(generated_choice_text)

	var text_absorbs_next_separator := false
	if not text_parts.is_empty():
		_add_reward_piece_separator(added_reward_piece)
		var text_label := ", ".join(text_parts)
		if reward.talent_points > 0 or BuildState.current_base_reward_gold() > 0:
			text_label += ","
			text_absorbs_next_separator = true
		_victory_reward_row.add_child(_make_reward_label(text_label, UIColors.TEXT_GOLD))
		added_reward_piece = true
	if reward.talent_points > 0:
		if text_absorbs_next_separator:
			text_absorbs_next_separator = false
		else:
			_add_reward_piece_separator(added_reward_piece)
		_reward_talent_icon = CardStyle.make_pixel_icon(CardStyle.talent_point_icon(), VICTORY_REWARD_ICON_SIZE)
		_victory_reward_row.add_child(_reward_talent_icon)
		_victory_reward_row.add_child(_make_reward_label("x %d" % reward.talent_points, UIColors.TEXT_GOLD))
		added_reward_piece = true
	var total_gold := BuildState.current_modified_reward_gold()
	var overkill_gold := BuildState.current_overkill_gold()
	if total_gold > 0:
		if text_absorbs_next_separator:
			text_absorbs_next_separator = false
		else:
			_add_reward_piece_separator(added_reward_piece)
		_reward_gold_icon = CardStyle.make_pixel_icon(UI_GOLD_ICON, VICTORY_REWARD_ICON_SIZE)
		_victory_reward_row.add_child(_reward_gold_icon)
		var gold_label := ": %dg" % total_gold
		if overkill_gold > 0:
			gold_label += " (%dg overkill)" % overkill_gold
		_victory_reward_row.add_child(_make_reward_label(gold_label, UIColors.TEXT_GOLD))
		added_reward_piece = true
	if not added_reward_piece:
		_victory_reward_row.add_child(_make_reward_label("No rewards.", UIColors.TEXT_DISABLED))


func _generated_reward_choice_text(reward: EncounterReward) -> String:
	if reward == null:
		return ""
	if reward.generated_gear_choice_count > 0:
		return "Choice of %s Gear" % GearGenerator.tier_name(reward.generated_gear_tier)
	if reward.legendary_choice_count > 0:
		return "Choice of Legendary Gear"
	return ""


func _add_reward_piece_separator(has_previous: bool) -> void:
	if not has_previous:
		return
	_victory_reward_row.add_child(_make_reward_label(","))


func _make_reward_label(text: String, color: Color = UIColors.TEXT_NORMAL) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_font_size_override("font_size", VICTORY_REWARD_FONT_SIZE)
	if _reward_label == null:
		_reward_label = label
	return label


## Shared "full-screen modal" shell used by every blocking overlay except
## Victory (which deliberately overlays only the combat window, not a
## generic centered card) and Shop (which is intentionally not a blocking
## modal at all -- see shop_overlay.gd's own comment). Builds the
## full-rect root, backdrop, and centered bare PanelContainer that all seven
## overlays built identically before this refactor; each caller still styles
## its own panel (content margin, border width, bg color) and builds its own
## content inside it, since those genuinely differ per overlay.
##
## `dismissable` preserves each overlay's existing, deliberate behavior
## exactly -- this refactor changes no overlay's dismiss behavior. Log and
## Talent Trees are pure informational views and already close on an outside
## click. Story/Map/Contract/Reward-Choice/Secondary-Subclass each gate a
## real decision (accept a contract, choose a reward, pick a route) with no
## defined "cancel" semantics, so they stay locked exactly as they were.
func _build_modal_shell(dismissable: bool) -> Dictionary:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)
	var panel := CardStyle.build_modal_panel(overlay, dismissable)
	return {"overlay": overlay, "panel": panel}


func _on_talent_overlay_visibility_changed() -> void:
	if _talent_overlay.visible or not _contract_offer_after_talents:
		return
	_contract_offer_after_talents = false
	# Defer until the dismissal input and talent focus restoration finish.
	_show_contract_offer_overlay.call_deferred()


func _show_talent_overlay() -> void:
	if _talent_overlay == null:
		return
	if _talent_overlay.has_method("show_overlay"):
		_talent_overlay.show_overlay()
	else:
		_talent_overlay.visible = true


## Resumes into whichever overlay a loaded save left mid-transition -- the
## intro story only ever gates the very first Tavern choice (encounter index
## 0; once proceeded past, tavern_map_choice_made or a higher
## current_encounter_index means that branch is never hit again, so no
## separate "already shown" flag is needed), and the three Contract-sequence
## checks below cover a save made mid-conversation, mid-subclass-choice, or
## between choosing the subclass and confirming Vyra's contract card --
## none of these steps persist their own "which screen was showing" state,
## so this reconstructs it from the BuildState fields that do persist.
func _show_initial_map_if_needed() -> void:
	if not BuildState.is_test_mode and BuildState.needs_secondary_subclass_choice():
		_secondary_subclass_overlay.show_overlay()
		return
	if BuildState.run_phase == BuildState.RunPhase.CONTRACT_OFFER:
		_show_contract_offer_overlay()
		return
	if _is_awaiting_contract_choice():
		_contract_overlay.show_contract_choice()
		return
	if not BuildState.needs_tavern_map_choice():
		return
	if BuildState.current_encounter_index == 0:
		_show_story_overlay()
	else:
		_show_map_overlay(false)


## True once the accepted contract has moved to the contract-choice hub.
## `current_route_node` only moves off the SUBCLASS_CHOICE node when a real
## route node is chosen, so sitting on it means the contract picker should
## own the flow. The second subclass can now be chosen later in Talents.
func _is_awaiting_contract_choice() -> bool:
	var node := BuildState.current_route_node
	return (
		BuildState.run_phase == BuildState.RunPhase.CONTRACT_ROUTE
		and node != null
		and node.node_type == ContractRouteNode.NodeType.SUBCLASS_CHOICE
	)


func _show_contract_offer_overlay() -> void:
	if not BuildState.is_test_mode and BuildState.needs_secondary_subclass_choice():
		_contract_overlay.visible = false
		_secondary_subclass_overlay.show_overlay()
		return
	if _should_show_contract_intro_before_generated_offers():
		_contract_overlay.show_greeting()
	elif BuildState.pending_contract_offers.size() > 1:
		_contract_overlay.show_offer_choice()
	else:
		_contract_overlay.show_greeting()


func _should_show_contract_intro_before_generated_offers() -> bool:
	return (
		BuildState.run_phase == BuildState.RunPhase.CONTRACT_OFFER
		and BuildState.active_contract != null
		and BuildState.active_contract.has_generated_route_state()
		and BuildState.completed_contract_count == 0
		and BuildState.contract_offer_index == 0
		and BuildState.current_encounter_index == RunFlow.tavern_encounter_count() - 1
	)


func _on_map_button_pressed() -> void:
	_show_map_overlay(true)


func _on_monster_manual_pressed() -> void:
	if _monster_manual_overlay != null:
		_monster_manual_overlay.show_manual()


func _show_map_overlay(manual_open: bool = false) -> void:
	if _story_overlay != null:
		_story_overlay.visible = false
	_map_overlay.show_map(manual_open)


func _show_story_overlay() -> void:
	_story_overlay.visible = true


func _on_intro_story_proceed_pressed() -> void:
	_story_overlay.visible = false
	AudioManager.transition_to_tavern_intro_ambience()
	_show_map_overlay(false)


func _on_tavern_proceed_pressed() -> void:
	if BuildState.choose_current_tavern_encounter():
		_map_overlay.clear_tavern_preview()
		_map_overlay.close()
		_status_label.visible = false
		_recap_label.visible = false
		_reset_enemy_hud()
		var encounter := BuildState.current_encounter()
		if encounter != null:
			_status_label.text = FLOW_TEXT.selected_encounter_status(encounter.monster.display_name)
		_autosave()


func _on_contract_map_pressed() -> void:
	if BuildState.accept_contract_offer():
		_map_overlay.close()
		_contract_overlay.show_contract_choice()
		_autosave()


func _on_contract_route_node_pressed(node: ContractRouteNode) -> void:
	if node == null:
		return
	if BuildState.choose_contract_route_node(node):
		var audio_biome := _contract_audio_biome_for_node(node)
		if audio_biome != "":
			AudioManager.transition_to_contract_biome_ambience(audio_biome)
		else:
			AudioManager.transition_to_contract_ambience()
		_map_overlay.close()
		_status_label.visible = false
		_recap_label.visible = false
		_contract_route_player_entered = false
		_reset_enemy_hud()
		if _combat_stage != null and _should_use_contract_traversal_animation():
			_contract_route_player_entered = true
			var run_in_sec: float = _combat_stage.play_player_run_in(not instant_playback)
			if run_in_sec > 0.0:
				AudioManager.play_footsteps_sfx(run_in_sec)
		_status_label.text = FLOW_TEXT.selected_route_status(node.display_name)
		_autosave()


func _on_contract_back_requested() -> void:
	if BuildState.return_to_contract_offer():
		_contract_route_player_entered = false
		_map_overlay.close()
		_status_label.visible = false
		_recap_label.visible = false
		_reset_enemy_hud()
		if BuildState.pending_contract_offers.size() > 1:
			_contract_overlay.show_offer_choice()
		else:
			_show_contract_offer_overlay()
		_autosave()



## The real commit point: contract_overlay.gd's PITCH step hands off here
## rather than mutating BuildState itself. On failure the overlay correctly
## stays on PITCH, since only a success path hides it.
func _on_contract_accept_requested(contract_id: String = "") -> void:
	if BuildState.accept_contract_offer(contract_id):
		_contract_route_player_entered = false
		_contract_overlay.visible = false
		if _is_awaiting_contract_choice():
			_contract_overlay.show_contract_choice()
		else:
			_status_label.visible = false
			_recap_label.visible = false
			_reset_enemy_hud()
			_show_map_overlay(false)
		_autosave()


## contract_overlay.gd's VYRA_DETAIL step: the contract is accepted, so hand
## the player to the (unchanged) interactive route schematic.
func _on_contract_route_requested() -> void:
	_contract_route_player_entered = false
	_contract_overlay.visible = false
	_status_label.visible = false
	_recap_label.visible = false
	_reset_enemy_hud()
	_status_label.text = FLOW_TEXT.contract_accepted_status(_contract_overlay.CONTRACT_VYRA_NAME)
	_show_map_overlay(false)
	_autosave()


func _show_shop_overlay() -> void:
	if _map_overlay != null:
		_map_overlay.visible = false
	_status_label.visible = false
	_recap_label.visible = false
	_view_log_button.visible = false
	_retry_button.visible = false
	_outcome_title_label.visible = false
	_restart_adventure_button.visible = false
	_shop_overlay.refresh()
	_shop_overlay.visible = true
	# The shop owns the combat window in this state; _refresh_enemy_hud()
	# keeps the HUD hidden while the overlay is visible.
	_refresh_enemy_hud()


func _show_reward_choice_overlay() -> void:
	_cancel_reward_upgrade_effects()
	AudioManager.cancel_magic_find_sfx()
	if _map_overlay != null:
		_map_overlay.visible = false
	_status_label.visible = false
	_recap_label.visible = false
	_view_log_button.visible = false
	_retry_button.visible = false
	_restart_adventure_button.visible = false
	var options_container: HBoxContainer = _reward_choice_overlay.options_container()
	for child in options_container.get_children():
		child.queue_free()
	_reward_choice_overlay.set_status_text("")
	_reward_choice_reveal_generation += 1
	_reward_choice_reveal_active = false
	_reward_choice_reveal_buttons.clear()
	for gear in BuildState.pending_reward_choices:
		var placeholder := _make_reward_choice_placeholder()
		options_container.add_child(placeholder)
		_reward_choice_reveal_buttons.append(placeholder)
	_reward_choice_overlay.visible = true
	if DisplayServer.get_name() == "headless":
		_finish_reward_choice_reveal()
	else:
		_play_reward_choice_reveal(_reward_choice_reveal_generation)
	# Same overlay-owns-the-window rule as _show_shop_overlay().
	_refresh_enemy_hud()


func _make_reward_choice_placeholder() -> Button:
	var item_box := GearCompareButton.new()
	item_box.custom_minimum_size = Vector2(112, 112)
	item_box.disabled = true
	item_box.focus_mode = Control.FOCUS_NONE
	item_box.modulate.a = 0.62
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		item_box.add_theme_stylebox_override(state, CardStyle.make_gear_item_stylebox(null, false, state))
	return item_box


func _make_reward_choice_button(gear: GearItem) -> Button:
	var item_box := GearCompareButton.new()
	item_box.custom_minimum_size = Vector2(112, 112)
	_populate_reward_choice_button(item_box, gear)
	return item_box


func _populate_reward_choice_button(item_box: Button, gear: GearItem) -> void:
	for child in item_box.get_children():
		child.queue_free()
	item_box.tooltip_text = _reward_choice_text(gear)
	item_box.tooltip_builder = func(): return CardStyle.build_gear_tooltip(self, gear, _reward_choice_text(gear))
	if not bool(item_box.get_meta("reward_choice_configured", false)):
		item_box.pressed.connect(_on_reward_choice_pressed.bind(gear, item_box))
		item_box.set_meta("reward_choice_configured", true)
	CardStyle.style_shop_item_box(item_box, gear)
	CardStyle.build_gear_box_content(item_box, gear)


func _play_reward_choice_reveal(generation: int) -> void:
	_reward_choice_reveal_active = true
	_reward_choice_overlay.set_status_text("Revealing rewards...")
	await get_tree().create_timer(REWARD_CHOICE_INITIAL_REVEAL_DELAY_SEC).timeout
	if generation != _reward_choice_reveal_generation or not _reward_choice_reveal_active:
		return
	for i in BuildState.pending_reward_choices.size():
		if generation != _reward_choice_reveal_generation or not _reward_choice_reveal_active:
			return
		if i >= _reward_choice_reveal_buttons.size():
			break
		var button := _reward_choice_reveal_buttons[i]
		var gear := BuildState.pending_reward_choices[i]
		_reveal_reward_choice_button(button, gear)
		await get_tree().create_timer(0.18).timeout
		var steps := _reward_reveal_tier_steps(gear)
		for step_index in range(1, steps.size()):
			if generation != _reward_choice_reveal_generation or not _reward_choice_reveal_active:
				return
			_apply_reward_choice_visual_tier(button, gear, int(steps[step_index]))
			_play_reward_choice_upgrade(button, int(steps[step_index]))
			await get_tree().create_timer(0.42).timeout
		await get_tree().create_timer(0.12).timeout
	if generation == _reward_choice_reveal_generation:
		_complete_reward_choice_reveal()


func _finish_reward_choice_reveal() -> void:
	_cancel_reward_upgrade_effects()
	AudioManager.cancel_magic_find_sfx()
	_reward_choice_reveal_generation += 1
	for i in BuildState.pending_reward_choices.size():
		if i >= _reward_choice_reveal_buttons.size():
			break
		_reveal_reward_choice_button(_reward_choice_reveal_buttons[i], BuildState.pending_reward_choices[i], true)
	_complete_reward_choice_reveal()


func _complete_reward_choice_reveal() -> void:
	_reward_choice_reveal_active = false
	_reward_choice_overlay.set_status_text("")
	for button in _reward_choice_reveal_buttons:
		if button != null:
			button.disabled = false
			button.focus_mode = Control.FOCUS_ALL
			button.modulate.a = 1.0


func _reveal_reward_choice_button(button: Button, gear: GearItem, final_visual: bool = false) -> void:
	if button == null or gear == null:
		return
	_populate_reward_choice_button(button, gear)
	button.disabled = true
	button.focus_mode = Control.FOCUS_NONE
	button.modulate.a = 1.0
	var steps := _reward_reveal_tier_steps(gear)
	var display_tier := gear.tier if final_visual else int(steps[0])
	_apply_reward_choice_visual_tier(button, gear, display_tier)
	if not final_visual:
		button.scale = Vector2(0.88, 0.88)
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _reward_reveal_tier_steps(gear: GearItem) -> Array[int]:
	var steps: Array[int] = []
	if gear != null:
		for tier in gear.reward_tier_steps:
			steps.append(int(tier))
	if steps.is_empty() and gear != null:
		steps.append(gear.tier)
	return steps


func _apply_reward_choice_visual_tier(button: Button, gear: GearItem, tier: int) -> void:
	var display_gear := GearItem.new()
	display_gear.id = gear.id
	display_gear.slot = gear.slot
	display_gear.tier = tier
	display_gear.item_family = gear.item_family
	display_gear.class_family = gear.class_family
	display_gear.source_kind = gear.source_kind
	display_gear.is_unidentified = gear.is_unidentified and tier == GearItem.Tier.CHAOS
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, CardStyle.make_gear_item_stylebox(display_gear, false, state))
	var icon := button.get_node_or_null("Icon") as TextureRect
	if icon != null:
		icon.texture = GearIcons.icon_for(display_gear)


func _play_reward_choice_upgrade(button: Button, tier: int) -> void:
	_reward_upgrade_effects.append(preload("res://scripts/ui/gear_upgrade_effect.gd").play(button, tier))


func _cancel_reward_upgrade_effects() -> void:
	for effect in _reward_upgrade_effects:
		if is_instance_valid(effect): effect.cancel()
	_reward_upgrade_effects.clear()


## Reward item details and the current choice/capacity hint share one card.
## Button.tooltip_text also retains this plain-text accessibility fallback.
func _reward_choice_text(gear: GearItem) -> String:
	var lines := CardStyle.gear_tooltip_lines(gear)
	var reason: String = preload("res://scripts/ui/gear_action_feedback.gd").legendary_reason(BuildState, gear)
	if reason != "":
		lines.append(reason)
	elif BuildState.pending_reward_choices.has(gear) and not BuildState.can_choose_pending_reward_gear(gear):
		lines.append("Inventory full -- make space before choosing.")
	else:
		lines.append("Click to choose.")
	return "\n".join(lines)


func _claim_reward_tooltip() -> String:
	if BuildState.can_claim_current_reward() or BuildState.has_claimed_current_reward():
		return ""
	return "Inventory full -- make space before claiming this reward."


func _on_build_state_changed() -> void:
	if _shop_overlay != null and _shop_overlay.visible:
		_shop_overlay.refresh()
	_update_header_status()
	if _playback_active:
		return
	_refresh_enemy_hud()
	_update_combat_background()


func _on_run_state_changed() -> void:
	if _map_overlay != null:
		_map_overlay.refresh()
	_update_header_status()
	if _playback_active:
		return
	_refresh_enemy_hud()
	_update_combat_background()




func _build_confirm_dialog() -> void:
	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.title = "Abandon Run"
	_confirm_dialog.dialog_text = "Are you sure you want to abandon this run? Any saved progress will be deleted."
	if BuildState.is_test_mode:
		_confirm_dialog.dialog_text = "End this Test Mode session? Adventure and Practice saves will be preserved."
	_confirm_dialog.confirmed.connect(_on_abandon_confirmed)
	add_child(_confirm_dialog)


func _on_abandon_confirmed() -> void:
	SaveSystem.delete_save()
	main_menu_pressed.emit()


func _on_save_and_quit_pressed() -> void:
	SaveSystem.save_run(BuildState)
	save_and_quit_pressed.emit()


## Autosave point (P2:R6:T6): called after each meaningful state
## transition (encounter/route choice, fight result, reward claim, shop
## action, retry) so a crash or unexpected quit loses at most the current
## in-progress build edit, not the whole run. Never called while
## BuildState.run_phase == FIGHTING -- BuildState.finish_fight() always
## resolves the fight synchronously before any of these handlers reach
## their autosave call, so there's no mid-fight state to snapshot.
func _autosave() -> void:
	SaveSystem.save_run(BuildState)


func _on_fight_pressed() -> void:
	if not BuildState.start_fight():
		return
	if _map_overlay != null:
		_map_overlay.close()
	var stats := BuildState.current_player_stats()
	var rotation := BuildResolver.resolve_rotation(BuildState.rotation, BuildState.unlocked_skills())
	_apply_shadow_export_fallback(rotation)
	var monster: Monster = _enemy_panel.monster()
	var duration_ms: int = _enemy_panel.duration_ms()
	var result: CombatResolver.CombatResult = CombatResolver.resolve(rotation, stats, monster, duration_ms, BuildState.current_combat_rng_seed())
	if not result.is_valid:
		BuildState.cancel_invalid_fight(result)
		_log_overlay.set_result(result, monster, CombatResultFormatter.format(result, monster))
		_status_label.text = CombatResultFormatter.invalid_simulation_message(result)
		_view_log_button.disabled = false
		return
	_current_playback_slow = CombatResolver.effective_enemy_slow(stats, monster)
	if instant_playback and result.gold_stolen > 0:
		BuildState.record_combat_stolen_gold(result.gold_stolen)
	BuildState.record_fight_result(result, monster)
	_log_overlay.set_result(result, monster, CombatResultFormatter.format(result, monster))
	_log_overlay.set_run_history(BuildState.run_encounter_history)
	if not instant_playback:
		_playback_contract_traversal_active = _should_use_contract_traversal_animation()
		_contract_route_player_entered = false
		# Real-time playback path (user-requested combat-playback addition):
		# every state mutation below is IDENTICAL to instant mode and happens
		# right now -- finish_fight() advances the run state machine exactly
		# as before and the result is autosaved immediately, so killing the
		# process mid-playback resumes exactly like killing it post-fight.
		# Only the visual reveal (_reveal_fight_outcome) waits for the
		# timeline to finish or be skipped. _playback_active is raised BEFORE
		# finish_fight() so the run_state_changed refreshes it emits neither
		# overwrite the animated HUD nor leak the outcome into the header.
		_playback_active = true
		if _enemy_panel != null and _enemy_panel.has_method("show_presented_target"):
			_enemy_panel.show_presented_target(monster, duration_ms)
		_update_combat_stage_target(monster)
		BuildState.finish_fight(result.is_win)
		_autosave()
		_begin_playback(result, monster)
		return
	# Stored before finish_fight() so the run_state_changed refresh it emits
	# already renders the HUD's post-fight state, not a pre-fight flicker.
	_show_enemy_hud_post_fight(result, monster)
	BuildState.finish_fight(result.is_win)
	if _combat_stage != null:
		_combat_stage.play_outcome_pose(result.is_win, false)
	_reveal_fight_outcome(result, monster)
	_autosave()


func _apply_shadow_export_fallback(rotation: Array[Skill]) -> void:
	# Ranked content supplies its own intrinsic and talent augments. The old
	# guaranteed-Poison export fallback belongs only to legacy binary builds.
	if BuildState.ranked_build != null:
		return
	if not _has_selected_tree("tree.shadow"):
		return
	for skill in rotation:
		if skill == null:
			continue
		if skill.id == "skill.stab" or skill.id == "skill.heavy_slash":
			skill.poison_stacks_applied = max(skill.poison_stacks_applied, 1)


func _has_selected_tree(tree_id: String) -> bool:
	for tree in BuildState.selected_trees:
		if tree != null and tree.id == tree_id:
			return true
	return false


func _equipped_gear_has_id(gear_id: String) -> bool:
	for gear in BuildState.equipped_gear():
		if gear != null and gear.id == gear_id:
			return true
	return false


## The full post-fight presentation reveal -- everything that used to happen
## inline the moment a fight resolved: status line, log access, and the
## win/loss outcome UI (victory banner or outcome title + retry/restart +
## inline recap). Instant mode calls this synchronously from
## _on_fight_pressed(); playback calls it once from _on_playback_finished().
func _reveal_fight_outcome(result: CombatResolver.CombatResult, monster: Monster) -> void:
	_status_label.text = "Fight complete: %s" % ("WIN" if result.is_win else "LOSS")
	_status_label.visible = false
	_view_log_button.visible = true
	_view_log_button.disabled = false
	if result.is_win:
		_outcome_title_label.visible = false
		_retry_button.visible = false
		_restart_adventure_button.visible = false
		_show_victory_banner(result, monster)
	else:
		_show_defeat_banner(result, monster)


## Starts the real-time visual playback of an already-resolved fight. Locks
## every outcome-revealing dashboard control, sets the pre-fight HUD state,
## and hands off to _playback_presenter for the actual timeline/animation
## mechanics -- it reports back exactly once via its `finished` signal (see
## _on_playback_finished() below).
func _begin_playback(result: CombatResolver.CombatResult, monster: Monster) -> void:
	_playback_active = true
	_update_combat_stage_target(monster)
	# Lock out everything that would reveal or act on the outcome early. The
	# build panels are already locked (build_locked stays true through the
	# fight), and the enemy panel's FIGHT! button is already disabled because
	# can_start_current_fight() is false in the post-fight run state.
	_status_label.visible = false
	_recap_label.visible = false
	# Stays visible (P2:R7 playtest feedback: it shouldn't disappear mid-fight)
	# but disabled -- the log overlay already holds the new fight's full
	# result at this point (set synchronously before playback starts), so
	# leaving it clickable here would let the log spoil the outcome before
	# the animation finishes.
	_view_log_button.disabled = true
	_retry_button.visible = false
	_restart_adventure_button.visible = false
	_outcome_title_label.visible = false
	_victory_overlay.visible = false
	_set_result_button_layer_active(false)
	_map_button.disabled = true
	# Pre-fight HUD state, driven directly (signal refreshes are suspended
	# while _playback_active).
	_set_enemy_hud_display(monster.display_name, float(monster.hp), monster.hp, monster.armor, monster.poison_resistance)
	_refresh_enemy_effect_chips(monster)
	_clear_hud_status_chips()
	COMBAT_STATUS_ICONS.add_timed_defense_chips(null, _add_hud_status_chip)
	_add_hud_status_chip("x0", UIColors.TEXT_POISON, HUD_POISON_ICON)
	_add_hud_status_chip("x0", UIColors.TEXT_WARNING, HUD_SHRED_ICON, _shred_status_tooltip())
	_add_hud_status_chip("x0", UIColors.TEXT_MAGIC, HUD_DECAY_ICON)
	_add_interrupt_status_chip(monster, 0)
	_enemy_hud.visible = true
	# Full window always plays on both a win and a loss (adjustment round 1,
	# 2026-07-19) -- a win used to truncate at the recorded kill moment; the
	# user wants the "overkill" feel of watching every remaining cast/tick
	# still land on the corpse. The HUD's HP bar clamps at 0 in the
	# presenter's own event handler so it never dips below dead or un-dies.
	_playback_presenter.start(
		result,
		monster,
		_equipped_gear_has_id("gear.legendary.wyvern_kriss"),
		_combat_stage != null and _equipped_gear_has_id(_combat_stage.BANDIT_BLADE_ID),
		not instant_playback and not _playback_contract_traversal_active,
		false,
		_current_playback_slow
	)
	# Session-persistent speed (adjustment round 2, 2026-07-19): initialize
	# from the last speed the player chose instead of always defaulting back
	# to 1x -- see _last_playback_speed's declaration.
	_set_playback_speed(_last_playback_speed, false)
	_playback_controls.visible = true
	_update_playback_time_label()
	_update_header_status()
	set_process(true)
	if _skip_playback_on_fight:
		_skip_playback()


## Remembers the choice (_last_playback_speed, adjustment round 2,
## 2026-07-19) so the next fight's playback starts at this speed instead of
## always resetting to 1x -- called both from a real speed-button press and
## from _begin_playback() initializing a fresh playback from the remembered
## speed, so recording it here covers both without a second call site.
func _set_playback_speed(speed: float, clear_skip_mode: bool = true) -> void:
	_last_playback_speed = speed
	if clear_skip_mode:
		_skip_playback_on_fight = false
	_playback_presenter.set_speed(speed)
	_playback_controls.set_active_speed(speed)
	if _skip_playback_on_fight and not clear_skip_mode:
		_playback_controls.set_skip_mode_active(true)


func _on_playback_skip_pressed() -> void:
	if _playback_active:
		_skip_playback()
		return
	_skip_playback_on_fight = true
	_playback_controls.set_skip_mode_active(true)


## Fires every remaining timeline event instantly -- the Skip button's
## action, and the path the playback-enabled headless checks drive.
func _skip_playback() -> void:
	if not _playback_active:
		return
	_playback_presenter.skip()


func _update_playback_time_label() -> void:
	if not _playback_active or _playback_presenter == null:
		return
	var elapsed_ms := _playback_presenter.elapsed_ms()
	var window_ms := _playback_presenter.window_ms()
	if _playback_controls != null:
		_playback_controls.set_time_text("%.1fs / %ss" % [elapsed_ms / 1000.0, LegendaryCatalog.number_text(window_ms / 1000.0)])
	_update_fight_timer_countdown(elapsed_ms, window_ms)


## The dashboard-level end of a playback (natural or skipped): unlocks the
## controls the playback froze, snaps the HUD to the exact resolved
## post-fight state, and runs the deferred outcome reveal.
## _playback_presenter's `finished` signal guarantees this fires exactly
## once per fight.
func _on_playback_finished(result: CombatResolver.CombatResult, monster: Monster, was_skipped: bool) -> void:
	set_process(false)
	_update_playback_time_label()
	_playback_active = false
	_playback_controls.visible = true
	# Exact final HUD state (bar value, chips, info line) from the stored
	# result -- the same rendering the instant path uses.
	_show_enemy_hud_post_fight(result, monster)
	if _combat_stage != null:
		var should_animate_outcome := not instant_playback and (not was_skipped or not result.is_win)
		_combat_stage.play_outcome_pose(result.is_win, should_animate_outcome)
	# Brief pause so the last popup's float+fade finishes before the outcome
	# reveal pops in on top of it (adjustment round 1). Skip cuts the attack
	# timeline, but still preserves the authored victory/defeat pose beat so
	# the outcome does not feel like it appears on the same frame.
	if not instant_playback:
		var reveal_delay_sec := PLAYBACK_OUTCOME_REVEAL_DELAY_SEC
		if not result.is_win and _combat_stage != null and _combat_stage.has_method("player_defeat_animation_duration_sec"):
			reveal_delay_sec = maxf(reveal_delay_sec, _combat_stage.player_defeat_animation_duration_sec() + PLAYER_DEFEAT_POSE_HOLD_SEC)
		await get_tree().create_timer(reveal_delay_sec).timeout
	if result.is_win and _playback_contract_traversal_active and _combat_stage != null:
		var run_out_sec: float = _combat_stage.play_player_run_out(not instant_playback and not was_skipped)
		if run_out_sec > 0.0:
			AudioManager.play_footsteps_sfx(run_out_sec)
			await get_tree().create_timer(run_out_sec).timeout
	_playback_contract_traversal_active = false
	var stole_gold_during_playback := BuildState.combat_stolen_gold > 0
	BuildState.clear_combat_stolen_gold()
	_reveal_fight_outcome(result, monster)
	if _enemy_panel != null and _enemy_panel.has_method("clear_presented_target"):
		_enemy_panel.clear_presented_target()
	_map_button.disabled = false
	_update_header_status()
	if stole_gold_during_playback:
		_autosave()


func _on_continue_pressed() -> void:
	var should_return_to_tavern_audio := _is_terminal_contract_reward_pending()
	var reward_gold := 0
	var reward_talent_points := 0
	var reward_gold_source_rect := Rect2()
	var reward_talent_source_rect := Rect2()
	var reward := BuildState.current_reward()
	if reward != null:
		reward_gold = BuildState.current_modified_reward_gold()
		reward_talent_points = reward.talent_points
		reward_gold_source_rect = _global_rect_for(_reward_gold_icon)
		reward_talent_source_rect = _global_rect_for(_reward_talent_icon)
	var claimed := BuildState.claim_current_reward(true)
	if claimed:
		reward_gold = BuildState.committed_reward_gold
	if not claimed:
		_pulse_inventory_blocked_control(_continue_button)
		_continue_button.tooltip_text = _claim_reward_tooltip()
		return
	_victory_overlay.visible = false
	_set_result_button_layer_active(false)
	var pending_reward_deposits := [0]
	if reward_talent_points > 0:
		pending_reward_deposits[0] += 1
		_deposit_talent_reward_after_animation(reward_talent_source_rect, reward_talent_points, pending_reward_deposits)
	if reward_gold > 0:
		pending_reward_deposits[0] += 1
		_deposit_gold_reward_after_animation(reward_gold_source_rect, reward_gold, pending_reward_deposits)
	while pending_reward_deposits[0] > 0:
		await get_tree().process_frame
	if claimed:
		_autosave()
	if claimed and BuildState.has_pending_reward_choice():
		_show_reward_choice_overlay()
		return
	# Skip the shop for the Hired Goon -> Contract Offer transition
	# (user-requested story pass): head straight into Ghit Gudd's Contract
	# Window instead. `and` short-circuits before open_shop_round() runs, so
	# it never mutates shop_round_pending/shop_offers for this one
	# transition -- the shop still opens normally everywhere else.
	if claimed and not BuildState.is_last_tavern_reward() and BuildState.open_shop_round():
		_status_label.text = FLOW_TEXT.STATUS_SHOP_DECISION
		_show_shop_overlay()
		return
	if should_return_to_tavern_audio:
		AudioManager.transition_to_tavern_ambience()
	_advance_after_reward_or_shop()


func _deposit_talent_reward_after_animation(source_rect: Rect2, amount: int, pending_reward_deposits: Array) -> void:
	if _active_talents_panel != null:
		await _active_talents_panel.animate_talent_points_from_rect(source_rect, amount, true)
	# Talent points were committed atomically by claim_current_reward().
	pending_reward_deposits[0] -= 1


func _deposit_gold_reward_after_animation(source_rect: Rect2, amount: int, pending_reward_deposits: Array) -> void:
	if _gear_panel != null:
		await _gear_panel.animate_gold_from_rect(source_rect, amount, true)
	BuildState.add_gold(amount)
	pending_reward_deposits[0] -= 1


func _global_rect_for(node: Control) -> Rect2:
	if node == null or not node.is_inside_tree():
		return Rect2()
	return node.get_global_rect()


func _on_shop_buy_pressed(offer: GearItem, source: Control = null) -> void:
	if not _shop_overlay.visible or _shop_overlay.is_busy():
		return
	if BuildState.buy_shop_offer(offer):
		_shop_overlay.set_status_text("")
		AudioManager.play_shop_change_sfx()
		if _gear_panel != null:
			await _gear_panel.animate_gain_from_source(offer, source)
		_autosave()
	elif not BuildState.can_store_shop_offer(offer):
		_pulse_inventory_blocked_control(source)
		_shop_overlay.set_status_text("Inventory full -- make space first.")
		return
	else:
		_shop_overlay.set_status_text("")
	_shop_overlay.refresh()


func _on_shop_reroll_pressed() -> void:
	if not _shop_overlay.visible or _shop_overlay.is_busy():
		return
	if not BuildState.can_reroll_shop_offers():
		_shop_overlay.refresh()
		_shop_overlay.set_status_text("Not enough gold.")
		_shop_overlay.pulse_reroll_blocked()
		return
	var reroll_cost := BuildState.shop_reroll_cost
	var reroll_target_rect: Rect2 = _shop_overlay.reroll_action_rect()
	var generation: int = _shop_overlay.begin_reroll()
	if _gear_panel != null:
		await _gear_panel.animate_gold_to_rect(reroll_target_rect, reroll_cost, true)
	if not is_instance_valid(_shop_overlay) or not _shop_overlay.is_reroll_current(generation):
		return
	if BuildState.reroll_shop_offers():
		_autosave()
		_shop_overlay.refresh()
	else:
		_shop_overlay.refresh()
	_shop_overlay.end_reroll(generation)


func _on_shop_continue_pressed() -> void:
	_shop_overlay.skip_reveal()
	if not BuildState.close_shop_round():
		return
	_shop_overlay.visible = false
	_set_result_button_layer_active(false)
	_status_label.visible = false
	_view_log_button.visible = true
	_advance_after_reward_or_shop()


func _on_secondary_tree_pressed(tree: SubclassTree) -> void:
	if BuildState.choose_secondary_tree(tree):
		_secondary_subclass_overlay.visible = false
		_status_label.visible = false
		_recap_label.visible = false
		_reset_enemy_hud()
		_status_label.text = "Second tree chosen: %s." % tree.display_name
		_show_initial_map_if_needed()
		_autosave()


func _on_talent_secondary_tree_chosen(tree: SubclassTree) -> void:
	_status_label.visible = false
	_recap_label.visible = false
	_reset_enemy_hud()
	_status_label.text = "Second tree chosen: %s." % tree.display_name
	_autosave()


func _on_reward_choice_pressed(gear: GearItem, source: Control = null) -> void:
	var should_return_to_tavern_audio := _is_terminal_contract_reward_pending()
	if BuildState.choose_pending_reward_gear(gear):
		if _gear_panel != null:
			await _gear_panel.animate_gain_from_source(gear, source)
		_reward_choice_overlay.visible = false
		_autosave()
		if BuildState.open_shop_round():
			_status_label.text = FLOW_TEXT.STATUS_SHOP_DECISION
			_show_shop_overlay()
			return
		_status_label.visible = false
		_view_log_button.visible = true
		if should_return_to_tavern_audio:
			AudioManager.transition_to_tavern_ambience()
		_advance_after_reward_or_shop()
	else:
		_pulse_inventory_blocked_control(source)
		var reason: String = preload("res://scripts/ui/gear_action_feedback.gd").legendary_reason(BuildState, gear)
		_reward_choice_overlay.set_status_text(reason if reason != "" else "Inventory full -- make space before choosing.")


func _on_reward_choice_skip_pressed() -> void:
	if _reward_choice_reveal_active:
		_finish_reward_choice_reveal()
		return
	var should_return_to_tavern_audio := _is_terminal_contract_reward_pending()
	if not BuildState.skip_pending_reward_gear():
		return
	_reward_choice_overlay.visible = false
	_autosave()
	if BuildState.open_shop_round():
		_status_label.text = FLOW_TEXT.STATUS_SHOP_DECISION
		_show_shop_overlay()
		return
	_status_label.visible = false
	_view_log_button.visible = true
	if should_return_to_tavern_audio:
		AudioManager.transition_to_tavern_ambience()
	_advance_after_reward_or_shop()


func _contract_audio_biome_for_node(node: ContractRouteNode) -> String:
	if node != null and _has_biome_contract_audio(node.biome):
		return node.biome
	if BuildState.active_contract != null:
		if _has_biome_contract_audio(BuildState.active_contract.selected_biome):
			return BuildState.active_contract.selected_biome
	return ""


func _has_biome_contract_audio(biome: String) -> bool:
	return (
		AudioManager.BIOME_MUSIC_PATHS.has(biome)
		or biome in ["Forest", "Keep", "Ancient Keep", "Ruins"]
	)


func _is_terminal_contract_reward_pending() -> bool:
	return (
		BuildState.is_contract_fight_active()
		and BuildState.run_phase == BuildState.RunPhase.RESULT
		and BuildState.last_fight_won
		and BuildState.current_route_node != null
		and BuildState.current_route_node.next_nodes.is_empty()
	)


func _pulse_inventory_blocked_control(control: Control) -> void:
	if control == null or not control.is_inside_tree():
		return
	_last_inventory_blocked_source = control
	CardStyle.pulse_blocked_control(control, "inventory_blocked_pulse")


func _on_retry_pressed() -> void:
	if BuildState.retry_current_encounter():
		_victory_overlay.visible = false
		_set_result_button_layer_active(false)
		_outcome_title_label.visible = false
		_retry_button.visible = false
		_restart_adventure_button.visible = false
		_recap_label.visible = false
		_view_log_button.visible = true
		_reset_enemy_hud()
		_status_label.text = FLOW_TEXT.STATUS_RETRY_READY
		_autosave()


func _advance_after_reward_or_shop() -> void:
	# The finished fight is behind us -- drop its stored HUD result so the
	# HUD reads the next target (or hides in map/offer states).
	_contract_route_player_entered = false
	_reset_enemy_hud()
	var advanced := BuildState.continue_after_win()
	if BuildState.run_phase == BuildState.RunPhase.CONTRACT_OFFER:
		if BuildState.is_test_mode:
			_show_contract_offer_overlay()
		else:
			_contract_offer_after_talents = true
			_show_talent_overlay()
	elif BuildState.run_phase == BuildState.RunPhase.CONTRACT_ROUTE:
		_status_label.text = FLOW_TEXT.NEXT_ROUTE_ON_MAP
		_show_map_overlay(false)
	elif advanced:
		_status_label.text = FLOW_TEXT.NEXT_TAVERN_OPPONENT_ON_MAP
		_show_map_overlay(false)
	else:
		_apply_outcome_presentation(BuildState.run_outcome)
	_autosave()


func _seed_label_text() -> String:
	if BuildState.is_test_mode:
		return "Test Mode | Seed: %d" % BuildState.adventure_seed
	return "Seed: %d" % BuildState.adventure_seed


## Refreshes every status field in the top bar from BuildState. Called from
## every signal the dashboard already listens to (build_changed,
## run_state_changed, lock_changed) so no call site needs to remember to
## refresh the header on top of its own work (P2:R7:T3). Target and Gold
## were dropped from this readout in the P2:R7 playtest-feedback pass --
## both were redundant with the enemy panel's own "Target:" line and the
## Gear panel's stash readout.
func _update_header_status() -> void:
	# During a playback the run state has ALREADY advanced to the resolved
	# outcome (state mutates instantly; only presentation waits), so the
	# normal phase/next-action lookups would spoil the result mid-fight.
	# Freeze the header on "Fighting" until the reveal.
	if _playback_active:
		if _seed_label != null:
			_seed_label.text = _seed_label_text()
		if _phase_label != null:
			_phase_label.text = "Phase: Fighting"
		if _lock_label != null:
			_lock_label.text = "Build: %s" % _build_lock_text()
		if _next_action_label != null:
			_next_action_label.text = "Next: Watch the fight play out."
		return
	if _seed_label != null:
		_seed_label.text = _seed_label_text()
	if _phase_label != null:
		_phase_label.text = "Phase: %s" % _run_phase_text()
	if _lock_label != null:
		_lock_label.text = "Build: %s" % _build_lock_text()
	if _next_action_label != null:
		_next_action_label.text = "Next: %s" % _next_action_text()
	_update_combat_background()


func _update_combat_background() -> void:
	if _tavern_background == null or _tavern_background_tint == null:
		return
	var background_texture := _combat_background_texture()
	_tavern_background.texture = background_texture
	var show_background := background_texture != null
	_tavern_background.visible = show_background
	if _tavern_fireplace_overlay != null:
		_tavern_fireplace_overlay.visible = show_background and background_texture == TAVERN_BACKGROUND_TEXTURE
	if _contract_moon_bat_overlay != null:
		_contract_moon_bat_overlay.visible = show_background and background_texture == CONTRACT_BACKGROUND_TEXTURE
	_tavern_background_tint.visible = show_background


func _combat_background_texture() -> Texture2D:
	match BuildState.run_phase:
		BuildState.RunPhase.PLANNING, BuildState.RunPhase.FIGHTING, BuildState.RunPhase.RESULT, BuildState.RunPhase.RUN_ENDED:
			var biome_texture := _current_route_biome_background_texture()
			if biome_texture != null:
				return biome_texture
			return CONTRACT_BACKGROUND_TEXTURE if BuildState.active_contract != null else TAVERN_BACKGROUND_TEXTURE
	return null


func _current_route_biome_background_texture() -> Texture2D:
	if BuildState.active_contract == null or BuildState.current_route_node == null:
		return null
	var biome := BuildState.current_route_node.biome
	if biome == "" and BuildState.active_contract != null:
		biome = BuildState.active_contract.selected_biome
	return _biome_background_texture(biome)


func _biome_background_texture(biome: String) -> Texture2D:
	var resource_path := String(BIOME_BACKGROUND_TEXTURE_PATHS.get(biome, ""))
	if resource_path == "":
		return null
	if _biome_background_texture_cache.has(resource_path):
		return _biome_background_texture_cache[resource_path] as Texture2D
	var image := Image.load_from_file(ProjectSettings.globalize_path(resource_path))
	if image == null or image.is_empty():
		return null
	var texture := ImageTexture.create_from_image(image)
	_biome_background_texture_cache[resource_path] = texture
	return texture


## Pure BuildState -> label lookup for the current run phase, matching the
## priority order a player actually experiences: an open shop round or
## pending reward/subclass choice always takes precedence over the
## underlying RunPhase, since RunPhase itself doesn't change while those
## overlays are open (see BuildState.open_shop_round()/claim_current_reward()
## /choose_secondary_tree()).
func _run_phase_text() -> String:
	if BuildState.shop_round_pending:
		return FLOW_TEXT.PHASE_SHOP
	if BuildState.has_pending_reward_choice():
		return FLOW_TEXT.PHASE_REWARD_CHOICE
	match BuildState.run_phase:
		BuildState.RunPhase.PLANNING:
			return FLOW_TEXT.PHASE_CONTRACT_ROUTE_PLANNING if BuildState.is_contract_fight_active() else FLOW_TEXT.PHASE_TAVERN_PLANNING
		BuildState.RunPhase.FIGHTING:
			return FLOW_TEXT.PHASE_FIGHTING
		BuildState.RunPhase.RESULT:
			return FLOW_TEXT.PHASE_VICTORY_CLAIM_REWARD if BuildState.last_fight_won else FLOW_TEXT.PHASE_FIGHT_RESULT
		BuildState.RunPhase.CONTRACT_OFFER:
			return FLOW_TEXT.PHASE_CONTRACT_OFFER
		BuildState.RunPhase.CONTRACT_ROUTE:
			return FLOW_TEXT.PHASE_CONTRACT_ROUTE_CHOOSE
		BuildState.RunPhase.RUN_ENDED:
			if BuildState.run_outcome == BuildState.RunOutcome.ALL_BOSSES_DEFEATED or BuildState.run_outcome == BuildState.RunOutcome.CONTRACT_VICTORY or BuildState.run_outcome == BuildState.RunOutcome.FIGHT_WIN:
				return FLOW_TEXT.PHASE_CONTRACT_VICTORY
			return FLOW_TEXT.PHASE_RUN_FAILED
	return "Unknown"


## Pure BuildState -> label lookup for the build lock state.
func _build_lock_text() -> String:
	return "Locked" if BuildState.build_locked else "Unlocked"


## Pure BuildState -> short instruction lookup: "what should the player do
## right now." Priority mirrors _run_phase_text() -- an open shop round or
## pending reward/subclass choice takes precedence over the underlying
## RunPhase for the same reason. Kept as a single small function so the next
## action is easy to reason about and test in isolation (P2:R7:T3), separate
## from _apply_outcome_presentation()'s richer loss/victory body text.
func _next_action_text() -> String:
	if not BuildState.is_test_mode and BuildState.needs_secondary_subclass_choice():
		return "Choose your earned second subclass."
	if BuildState.shop_round_pending:
		return FLOW_TEXT.NEXT_BUY_OR_LEAVE_SHOP
	if BuildState.has_pending_reward_choice():
		return FLOW_TEXT.NEXT_CHOOSE_REWARD
	match BuildState.run_phase:
		BuildState.RunPhase.RUN_ENDED:
			match BuildState.run_outcome:
				BuildState.RunOutcome.CONTRACT_FAILED, BuildState.RunOutcome.ADVENTURE_RESTART_REQUIRED:
					return "Restart Test Mode." if BuildState.is_test_mode else FLOW_TEXT.NEXT_RESTART_ADVENTURE
				BuildState.RunOutcome.ALL_BOSSES_DEFEATED, BuildState.RunOutcome.CONTRACT_VICTORY, BuildState.RunOutcome.FIGHT_WIN:
					return "Start a fresh Test Mode session." if BuildState.is_test_mode else FLOW_TEXT.NEXT_START_NEW_ADVENTURE
			return FLOW_TEXT.NEXT_CHOOSE_NEXT_STEP
		BuildState.RunPhase.RESULT:
			if BuildState.last_fight_won:
				return FLOW_TEXT.NEXT_CLAIM_REWARD
			if BuildState.run_outcome == BuildState.RunOutcome.FIGHT_LOSS_RETRY:
				return FLOW_TEXT.NEXT_RETRY_FIGHT
			return FLOW_TEXT.NEXT_REVIEW_FIGHT_RESULT
		BuildState.RunPhase.CONTRACT_OFFER:
			return FLOW_TEXT.NEXT_HEAR_CONTRACT_WINDOW
		BuildState.RunPhase.CONTRACT_ROUTE:
			return FLOW_TEXT.NEXT_ROUTE_ON_MAP
		BuildState.RunPhase.PLANNING:
			if BuildState.needs_tavern_map_choice():
				return FLOW_TEXT.NEXT_TAVERN_OPPONENT_ON_MAP
			if not BuildState.build_locked:
				return FLOW_TEXT.NEXT_LOCK_BUILD_THEN_FIGHT
			if BuildState.can_start_current_fight():
				return FLOW_TEXT.NEXT_FIGHT_WHEN_READY
			return FLOW_TEXT.NEXT_FINISH_BUILD_TO_FIGHT
		BuildState.RunPhase.FIGHTING:
			return FLOW_TEXT.PHASE_FIGHTING + "..."
	return ""


## Central mapping from BuildState.RunOutcome to a headline, body text, and
## available actions, so every loss/do-over/restart/victory state is
## explicit instead of scattered inline status text (P2:R5:T8). Called both
## right after a losing fight and after claiming the final contract/Tavern
## reward, since a terminal win outcome is only known post-claim.
func _apply_outcome_presentation(outcome: int) -> void:
	_status_label.visible = false
	var presentation := _outcome_presentation(outcome)
	if String(presentation["title"]) == "":
		_outcome_title_label.visible = false
		_retry_button.visible = false
		_restart_adventure_button.visible = false
		return
	_set_outcome_title(String(presentation["title"]), presentation["color"])
	_status_label.text = String(presentation["body"])
	_status_label.visible = _status_label.text != ""
	_retry_button.visible = bool(presentation["show_retry"])
	_retry_button.disabled = false
	_restart_adventure_button.visible = bool(presentation["show_restart"])
	_restart_adventure_button.disabled = false
	_restart_adventure_button.text = String(presentation["restart_text"])


func _outcome_presentation(outcome: int) -> Dictionary:
	match outcome:
		BuildState.RunOutcome.FIGHT_LOSS_RETRY:
			# First-encounter revision (combat-playback adjustment round 2 +
			# retry bug, 2026-07-19; corrected 2026-07-19): the first Tavern
			# encounter gets unlimited retries, so "One retry available"
			# would be misleading for it specifically -- every other
			# encounter that reaches this outcome only ever gets it once
			# before a second loss becomes ADVENTURE_RESTART_REQUIRED, so the
			# original wording stays accurate for them.
			var body := (
				"This opener has unlimited retries. Adjust your build, then retry this encounter."
				if BuildState.is_unlimited_retry_encounter()
				else "One standard do-over is available (%s). Adjust your build, then retry this encounter." % BuildState.current_attempts_text()
			)
			return _make_outcome_presentation("DEFEATED", OUTCOME_LOSS_COLOR, body, true, false, FLOW_TEXT.ACTION_RESTART_ADVENTURE)
		BuildState.RunOutcome.CONTRACT_FAILED:
			return _make_outcome_presentation(
				"CONTRACT FAILED",
				OUTCOME_LOSS_COLOR,
				"This contract route has no retries remaining. Restart begins a fresh Adventure and preserves Seed %d." % BuildState.adventure_seed,
				false,
				true,
				FLOW_TEXT.ACTION_RESTART_ADVENTURE
			)
		BuildState.RunOutcome.ADVENTURE_RESTART_REQUIRED:
			return _make_outcome_presentation(
				"ADVENTURE OVER",
				OUTCOME_LOSS_COLOR,
				"No retries remain for this Tavern encounter. Restart begins a fresh Adventure and preserves Seed %d." % BuildState.adventure_seed,
				false,
				true,
				FLOW_TEXT.ACTION_RESTART_ADVENTURE
			)
		BuildState.RunOutcome.CONTRACT_VICTORY:
			return _make_outcome_presentation(
				"CONTRACT COMPLETE",
				CardStyle.ACCENT_COLOR,
				"Vyra is defeated. Seed %d is preserved if you start a new Adventure." % BuildState.adventure_seed,
				false,
				true,
				FLOW_TEXT.ACTION_START_NEW_ADVENTURE
			)
		BuildState.RunOutcome.ALL_BOSSES_DEFEATED:
			return _make_outcome_presentation(
				"YOU KILLED ALL BOSSES",
				CardStyle.ACCENT_COLOR,
				"Every boss in the Monster Manual is defeated. Seed %d is preserved if you start a new Adventure." % BuildState.adventure_seed,
				false,
				true,
				FLOW_TEXT.ACTION_START_NEW_ADVENTURE
			)
		BuildState.RunOutcome.FIGHT_WIN:
			# Only reached if the Tavern ladder ends without an active contract.
			return _make_outcome_presentation(
				"RUN COMPLETE",
				CardStyle.ACCENT_COLOR,
				"Tavern sequence cleared. Seed %d is preserved if you start a new Adventure." % BuildState.adventure_seed,
				false,
				true,
				FLOW_TEXT.ACTION_START_NEW_ADVENTURE
			)
	return _make_outcome_presentation("", Color.WHITE, "", false, false, FLOW_TEXT.ACTION_RESTART_ADVENTURE)


func _make_outcome_presentation(
	title: String,
	color: Color,
	body: String,
	show_retry: bool,
	show_restart: bool,
	restart_text: String
) -> Dictionary:
	if BuildState.is_test_mode and show_restart:
		restart_text = "Restart Test Mode"
		body = "Restart begins a fresh Test Mode session and preserves Seed %d. Adventure and Practice saves are preserved." % BuildState.adventure_seed
	return {
		"title": title,
		"color": color,
		"body": body,
		"show_retry": show_retry,
		"show_restart": show_restart,
		"restart_text": restart_text,
	}


func _set_outcome_title(text: String, color: Color) -> void:
	_outcome_title_label.text = text
	_outcome_title_label.add_theme_color_override("font_color", color)
	_outcome_title_label.visible = true
