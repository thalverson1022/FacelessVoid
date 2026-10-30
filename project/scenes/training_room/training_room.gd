extends Control
## Practice Room: freeform practice mode (P2:R10), distinct from the locked
## Adventure flow. Deliberately touches no BuildState/save fields -- practice
## builds, gear, and results here must never affect or be affected by a real
## Adventure run, per the P2:R10 scope decision. Owns its own
## `TrainingRoomState` (never the real `BuildState` autoload) and hands it to
## the reused dashboard panels via their `state` property.
##
## P2:R10:T3 scope: freeform tree/passive/rotation selection (reusing
## talent_panel/available_skills_panel/skill_build_panel/
## character_stats_panel, each parameterized to accept an injected state).
## Tree selection is two dropdowns (Primary/Secondary Tree) next to the
## Talents panel, backed by TrainingRoomState.set_primary_tree()/
## set_secondary_tree() (post-R10 UI-feedback pass).
##
## P2:R10:T4 scope, reworked into a compact paper-doll gear editor after
## Practice Room overflow feedback: the right panel shows equipment slots only,
## and clicking a slot opens its focused Rarity/stat popup. Each slot's
## non-Legendary Rarity dropdown follows the active generated Phase 5 tiers;
## each affix then gets a stat-choice dropdown that auto-fills a real tier
## value while staying editable. Every slot offers its fixed Legendary roster
## through a slot-filtered selector. Fixed affixes remain read-only.
##
## P2:R10:T5 scope: fight-setup controls -- a target stats card
## (TrainingTargetPanel, styled like Adventure's enemy_panel.gd), a direct
## combat-duration input, a seed separate from the real Adventure seed, and a
## practice-gold input (feeds `BuildResolver.resolve_stats()`'s
## `current_gold` parameter so Bandit Blade's gold-scaling damage is actually
## testable here). Reworked post-R10 (UI-feedback pass): the target card no
## longer picks between 3 preset monsters -- Practice Room only measures
## damage dealt in a fixed window, never whether the target dies, so it's
## just adjustable defenses on a single practice target
## with no HP concept anywhere in the UI.
##
## P2:R10:T6 scope, extended post-R10: a Fight button (centered under the
## combat view rather than spanning the screen) that runs
## `TrainingRoomState.run_fight()`, then plays the result through
## TrainingRoomCombatView -- a dedicated animated combat area (HP bar/skill
## popups/speed controls) built directly on the already-reusable
## CombatPlayback logic class, rather than extracting combat_screen.gd's
## entangled playback rendering. The result log (CombatResultFormatter/
## CombatRecap, same presentation logic Adventure's recap uses) now appears
## once that animation finishes rather than instantly.

signal back_pressed

const HEADING_FONT_SIZE := 32
const CARD_TITLE_FONT_SIZE := 20
const SIDE_COLUMN_WIDTH := 300
const ACTION_BUTTON_FONT_SIZE := 16
const FIGHT_BUTTON_SIZE := Vector2(148, 52)
const LOG_BUTTON_SIZE := Vector2(148, 52)
const PRACTICE_SKILL_BUILD_MIN_HEIGHT := 148
const PAPER_DOLL_HELM_SLOT_SIZE := Vector2(66, 66)
const PAPER_DOLL_ARMOR_SLOT_SIZE := Vector2(96, 96)
const PAPER_DOLL_WEAPON_SLOT_SIZE := Vector2(78, 78)
const PAPER_DOLL_SMALL_SLOT_SIZE := Vector2(56, 56)
const GEAR_EDITOR_POPUP_SIZE := Vector2(390, 285)
const ROGUE_CLASS_PATH := "res://data/classes/rogue.tres"
const BACKDROP_COLOR := UIColors.OVERLAY_BACKDROP
const FIGHT_ICON := preload("res://assets/ui/icons/fight.png")
const UI_BACK_ICON_PATH := "res://assets/ui/icons/abandon_ex.png"
const TOP_ACTION_BUTTON_SIZE := Vector2(56, 56)
const SETTINGS_BUTTON_RESERVED_WIDTH := 50.0

const ACTIVE_TALENTS_PANEL_SCENE := preload("res://scenes/combat/active_talents_panel.tscn")
const TALENT_PANEL_SCENE := preload("res://scenes/combat/talent_panel.tscn")
const AVAILABLE_SKILLS_PANEL_SCENE := preload("res://scenes/combat/available_skills_panel.tscn")
const SKILL_BUILD_PANEL_SCENE := preload("res://scenes/combat/skill_build_panel.tscn")
const CHARACTER_STATS_PANEL_SCENE := preload("res://scenes/combat/character_stats_panel.tscn")
const LOG_OVERLAY_SCENE := preload("res://scenes/combat/log_overlay.tscn")

const RARITY_NAMES := {
	GearItem.Tier.CRUDE: "Crude",
	GearItem.Tier.BASIC: "Basic",
	GearItem.Tier.MASTER: "Master",
	GearItem.Tier.EPIC: "Epic",
	GearItem.Tier.CURSED: "Cursed",
	GearItem.Tier.CHAOS: "Chaos",
	GearItem.Tier.UNIQUE: "Unique",
}

# P5M2 practice customization started on Basic/Master/Cursed; P5M9 brings the
# editor up to the active generated Phase 5 rarity set now shown in Adventure.
const PRACTICE_CUSTOM_TIERS := [
	GearItem.Tier.BASIC,
	GearItem.Tier.MASTER,
	GearItem.Tier.EPIC,
	GearItem.Tier.CURSED,
	GearItem.Tier.CHAOS,
	GearItem.Tier.UNIQUE,
]

## Sentinel OptionButton item id for the "None" rarity choice (empties the
## slot entirely) -- distinct from any real GearItem.Tier enum value (0-3).
## Deliberately NOT -1: Godot's OptionButton/PopupMenu.add_item() treats an
## explicit id of -1 as "auto-assign the item's index as its id" (the same
## sentinel meaning as omitting the id argument entirely), so passing -1
## here would silently collide with Basic's real id of 0 (since "None" is
## added at index 0) instead of ever comparing equal to -1 anywhere.
const NONE_RARITY_ID := 100

var _state: TrainingRoomState
var _weapon_slot_button: Button
var _helm_slot_button: Button
var _armor_slot_button: Button
var _trinket_slot_button: Button
var _charm_slot_button: Button
var _legs_slot_button: Button
var _hands_slot_button: Button
var _carried_button: Button
var _carried_overlay: Control
var _carried_rows: VBoxContainer
var _carried_slot_row: HBoxContainer
var _carried_slot_option: OptionButton
var _gear_validation_label: Label
var _gear_slot_buttons: Dictionary = {}
var _gear_editor_overlay: Control
var _gear_editor_title: Label
var _gear_rarity_option: OptionButton
var _gear_legendary_option: OptionButton
var _legendary_details: VBoxContainer
var _gear_affix_column: VBoxContainer
var _editing_gear_item: GearItem = null
var _editing_gear_slot_name := ""
var _editing_gear_is_weapon := false
var _target_panel: TrainingTargetPanel
var _duration_spin: SpinBox
var _seed_spin: SpinBox
var _random_seed_toggle: CheckBox
var _missing_attempts_spin: SpinBox
var _gold_spin: SpinBox
var _combat_view: TrainingRoomCombatView
var _skill_build_panel
var _fight_button: Button
var _view_log_button: Button
var _log_overlay: Control
var _log_inspector
var _result_log: RichTextLabel
var _talent_overlay: Control
var _talent_overlay_content: VBoxContainer
var _talent_overlay_scroll: ScrollContainer
var _talent_panel


var _setup_save_queued := false
var _setup_autosave := true
var _persistence_notice: Label

func _ready() -> void:
	_state = TrainingRoomState.new()
	_state.content_registry = BuildContentRegistry.test_mode()
	_state.practice_save_path = PracticeSaveSystem.core_save_path
	_state.set_class(_state.content_registry.classes["class.rogue"])
	_state.configure_ranked_build(_state.content_registry.trees["tree.bladedancer"])
	var restored := PracticeSaveSystem.load_setup(_state)
	_setup_autosave = restored.status != "failed"

	var canvas := ColorRect.new()
	canvas.name = "ScreenCanvas"
	canvas.color = UIColors.BACKGROUND
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(canvas)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.name = "TopActionBar"
	header.add_theme_constant_override("separation", 20)
	vbox.add_child(header)

	var heading := Label.new()
	heading.text = "Practice Room"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.theme_type_variation = &"TitleHeading"
	heading.add_theme_font_size_override("font_size", HEADING_FONT_SIZE)
	header.add_child(heading)

	var back_button := Button.new()
	_configure_top_icon_button(back_button, "BackButton", _texture_from_path(UI_BACK_ICON_PATH), "Back to Title")
	back_button.pressed.connect(func(): back_pressed.emit())
	header.add_child(back_button)

	var settings_reserved_space := Control.new()
	settings_reserved_space.custom_minimum_size = Vector2(SETTINGS_BUTTON_RESERVED_WIDTH, 0)

	var subtitle := Label.new()
	subtitle.text = "Where questionable builds go to become slightly less questionable."
	vbox.add_child(subtitle)
	_persistence_notice = Label.new()
	_persistence_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_persistence_notice.text = restored.message
	if not _state.rotation_changes.get("removed", []).is_empty() or not _state.rotation_changes.get("overflow", []).is_empty():
		_persistence_notice.text += " Rotation entries removed: %s; beyond ten slots: %s." % [str(_state.rotation_changes.get("removed", [])), str(_state.rotation_changes.get("overflow", []))]
	vbox.add_child(_persistence_notice)
	var save_setup_button := Button.new()
	save_setup_button.text = "Save Setup"
	save_setup_button.pressed.connect(func():
		_commit_setup_save(true)
	)
	header.add_child(save_setup_button)
	# Reserve the far-right space for global Settings after all header actions.
	header.add_child(settings_reserved_space)
	_state.build_changed.connect(_queue_setup_save)
	_state.fight_setup_changed.connect(_queue_setup_save)

	# Three-column layout mirroring Adventure's real combat_screen.gd column
	# structure (Left: character stats + talents, Center: combat view +
	# skill strips, Right: target/fight-setup + gear), per user feedback
	# that Practice Room should read as a variant of Adventure mode rather
	# than a flat stack of sections.
	var columns := HBoxContainer.new()
	columns.name = "Columns"
	columns.add_theme_constant_override("separation", 10)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(columns)

	var left_column := VBoxContainer.new()
	left_column.name = "LeftColumn"
	left_column.add_theme_constant_override("separation", 6)
	left_column.custom_minimum_size = Vector2(SIDE_COLUMN_WIDTH, 0)
	columns.add_child(left_column)

	var character_stats_panel := CHARACTER_STATS_PANEL_SCENE.instantiate()
	character_stats_panel.name = "CharacterStatsPanel"
	character_stats_panel.state = _state
	character_stats_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_child(character_stats_panel)

	var active_talents_panel := ACTIVE_TALENTS_PANEL_SCENE.instantiate()
	active_talents_panel.name = "ActiveTalentsPanel"
	active_talents_panel.state = _state
	active_talents_panel.enable_open_button_attention = false
	active_talents_panel.size_flags_vertical = Control.SIZE_FILL
	active_talents_panel.open_talents_pressed.connect(_show_talent_overlay)
	left_column.add_child(active_talents_panel)

	var center_column := VBoxContainer.new()
	center_column.name = "CenterColumn"
	center_column.add_theme_constant_override("separation", 6)
	center_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_column.size_flags_stretch_ratio = 2.0
	columns.add_child(center_column)

	_combat_view = TrainingRoomCombatView.new()
	_combat_view.name = "CombatView"
	_combat_view.finished.connect(_on_combat_view_finished)
	_combat_view.gold_stolen_callback = Callable(_state, "add_practice_combat_gold")
	_combat_view.set_fight_window_ms(_state.duration_ms)
	center_column.add_child(_combat_view)
	# Reserve room for all ten rotation slots and explicit editing actions.
	_combat_view.custom_minimum_size.y = 280
	_combat_view.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Fight + Combat Log live inside the combat view's lower band, matching
	# Adventure's M5 combat-window treatment.
	var fight_button_row := HBoxContainer.new()
	fight_button_row.name = "FightButtonRow"
	fight_button_row.add_theme_constant_override("separation", 8)
	fight_button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fight_button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_combat_view.add_action_row(fight_button_row)

	_fight_button = Button.new()
	_fight_button.name = "FightButton"
	_fight_button.text = "Fight"
	CardStyle.configure_icon_button(_fight_button, FIGHT_ICON, 6)
	_fight_button.custom_minimum_size = FIGHT_BUTTON_SIZE
	_fight_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_fight_button.add_theme_font_size_override("font_size", ACTION_BUTTON_FONT_SIZE)
	_fight_button.pressed.connect(_on_fight_button_pressed)
	fight_button_row.add_child(_fight_button)

	_view_log_button = Button.new()
	_view_log_button.name = "ViewLogButton"
	_view_log_button.text = "Combat Log"
	_view_log_button.custom_minimum_size = LOG_BUTTON_SIZE
	_view_log_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_view_log_button.add_theme_font_size_override("font_size", ACTION_BUTTON_FONT_SIZE)
	_view_log_button.disabled = true
	_view_log_button.pressed.connect(func(): _log_overlay.show_log())
	fight_button_row.add_child(_view_log_button)

	var available_skills_panel := AVAILABLE_SKILLS_PANEL_SCENE.instantiate()
	available_skills_panel.state = _state
	center_column.add_child(available_skills_panel)

	_skill_build_panel = SKILL_BUILD_PANEL_SCENE.instantiate()
	_skill_build_panel.state = _state
	_combat_view.skill_build_panel = _skill_build_panel
	center_column.add_child(_skill_build_panel)
	_skill_build_panel.custom_minimum_size = Vector2(0, PRACTICE_SKILL_BUILD_MIN_HEIGHT)

	var right_scroll := ScrollContainer.new()
	right_scroll.name = "RightColumnScroll"
	right_scroll.custom_minimum_size = Vector2(SIDE_COLUMN_WIDTH, 0)
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(right_scroll)

	var right_column := VBoxContainer.new()
	right_column.name = "RightColumn"
	right_column.add_theme_constant_override("separation", 6)
	right_column.custom_minimum_size = Vector2(SIDE_COLUMN_WIDTH, 0)
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(right_column)

	_build_gear_paper_doll(right_column)

	_target_panel = TrainingTargetPanel.new()
	_target_panel.name = "TargetPanel"
	_target_panel.defense_changed.connect(_on_target_defense_changed)
	_target_panel.preset_selected.connect(_on_target_preset_selected)
	_target_panel.generated_roll_requested.connect(_on_generated_roll_requested)
	right_column.add_child(_target_panel)

	_build_fight_setup_panel(right_column)

	_build_talent_overlay()
	_build_gear_editor_overlay()
	_build_log_overlay()
	preload("res://scripts/ui/play_area_focus.gd").fit_below(_talent_overlay, header, true)
	_talent_overlay.resized.connect(_resize_talent_overlay_to_viewport)
	preload("res://scripts/ui/play_area_focus.gd").fit_below(_log_overlay, columns)

	_state.build_changed.connect(_refresh_talent_panel)
	_state.build_changed.connect(_refresh_gear_editor)
	_state.build_changed.connect(_refresh_fight_button)
	_state.build_changed.connect(_refresh_fight_setup_controls)
	_state.build_changed.connect(_invalidate_result_review)
	_state.stats_preview_changed.connect(_refresh_fight_setup_controls)
	_state.lock_changed.connect(_refresh_fight_button)
	_state.fight_setup_changed.connect(_refresh_target_panel)
	_state.fight_setup_changed.connect(_refresh_fight_setup_controls)
	_state.fight_setup_changed.connect(_refresh_combat_view_fight_window)
	_state.fight_setup_changed.connect(_refresh_combat_view_target)
	_state.fight_setup_changed.connect(_invalidate_result_review)
	_state.fight_finished.connect(_on_state_fight_finished)
	_refresh_talent_panel()
	_refresh_gear_editor()
	_refresh_fight_button()
	_refresh_target_panel()
	_refresh_combat_view_target()


func _refresh_talent_panel() -> void:
	if _talent_panel != null and _talent_panel.has_method("refresh_panel"):
		_talent_panel.refresh_panel()


func _on_primary_tree_selected(tree: SubclassTree) -> void:
	_state.set_primary_tree(tree)
	_refresh_talent_panel()


func _on_secondary_tree_selected(tree: SubclassTree) -> void:
	_state.set_secondary_tree(tree)
	_refresh_talent_panel()


func _show_talent_overlay() -> void:
	_talent_overlay.visible = true


func _build_talent_overlay() -> void:
	_talent_overlay = Control.new()
	_talent_overlay.name = "TalentOverlay"
	_talent_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_talent_overlay.visible = false
	add_child(_talent_overlay)

	var panel := CardStyle.build_modal_panel(_talent_overlay, true, true)
	var style := CardStyle.make_stylebox(18)
	style.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	_talent_overlay_content = content
	content.custom_minimum_size = Vector2(940, 740)
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "Talent Trees"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.theme_type_variation = &"PanelHeader"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", CardStyle.ACCENT_COLOR)
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(func(): _talent_overlay.visible = false)
	header.add_child(close_button)
	content.add_child(header)

	var scroll := ScrollContainer.new()
	_talent_overlay_scroll = scroll
	scroll.name = "TalentTreeScroll"
	scroll.custom_minimum_size = Vector2(900, 660)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	_talent_panel = TALENT_PANEL_SCENE.instantiate()
	_talent_panel.name = "TalentPanel"
	_talent_panel.state = _state
	_talent_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_talent_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.add_child(_talent_panel)
	var navigation := preload("res://scripts/ui/talent_modal_navigation.gd").new()
	navigation.name = "TalentKeyboardNavigation"
	_talent_overlay.add_child(navigation)
	_talent_panel.minimum_size_changed.connect(_resize_talent_overlay_to_viewport.call_deferred)
	if get_viewport() != null:
		get_viewport().size_changed.connect(_resize_talent_overlay_to_viewport)
	_resize_talent_overlay_to_viewport()


func _resize_talent_overlay_to_viewport() -> void:
	if _talent_overlay_content == null or _talent_overlay_scroll == null:
		return
	# Use the space below the system bar, including the subtitle area.
	# Budget panel borders explicitly instead of losing another96px to padding.
	var panel := _talent_overlay_content.get_parent() as PanelContainer
	var frame := panel.get_theme_stylebox("panel").get_minimum_size()
	var available := _talent_overlay.size - Vector2(96, 32 + frame.y)
	_talent_overlay_content.custom_minimum_size = Vector2(minf(940, available.x), 0)
	var chrome: float = _talent_overlay_content.get_child(0).get_combined_minimum_size().y + 10
	_talent_overlay_scroll.custom_minimum_size = Vector2(0, minf(_talent_panel.get_combined_minimum_size().y, maxf(180, available.y - chrome)))


func _build_gear_paper_doll(parent: Container) -> void:
	var panel := PanelContainer.new()
	panel.name = "PracticeGearPanel"
	panel.add_theme_stylebox_override("panel", CardStyle.make_stylebox(12))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var title := Label.new()
	title.text = "Gear"
	title.theme_type_variation = &"PanelHeader"
	title.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	content.add_child(title)

	var doll := HBoxContainer.new()
	doll.name = "PracticeGearDoll"
	doll.alignment = BoxContainer.ALIGNMENT_CENTER
	doll.add_theme_constant_override("separation", 8)
	content.add_child(doll)
	var left := VBoxContainer.new()
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 6)
	doll.add_child(left)
	var center := VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 6)
	doll.add_child(center)
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 6)
	doll.add_child(right)
	_weapon_slot_button = _add_practice_slot(left, PAPER_DOLL_WEAPON_SLOT_SIZE, GearItem.SlotType.WEAPON, "Weapon")
	_hands_slot_button = _add_practice_slot(left, Vector2(60, 60), GearItem.SlotType.HANDS, "Gloves")
	_helm_slot_button = _add_practice_slot(center, PAPER_DOLL_HELM_SLOT_SIZE, GearItem.SlotType.HELM, "Helm")
	_armor_slot_button = _add_practice_slot(center, PAPER_DOLL_ARMOR_SLOT_SIZE, GearItem.SlotType.ARMOR, "Armor")
	_legs_slot_button = _add_practice_slot(center, Vector2(88, 88), GearItem.SlotType.LEGS, "Pants")
	_charm_slot_button = _add_practice_slot(right, PAPER_DOLL_SMALL_SLOT_SIZE, GearItem.SlotType.CHARM, "Charm")
	_trinket_slot_button = _add_practice_slot(right, PAPER_DOLL_SMALL_SLOT_SIZE, GearItem.SlotType.TRINKET, "Trinket")



func _add_practice_slot(parent: Container, slot_size: Vector2, slot_id: int, label: String) -> Button:
	var button := _make_gear_slot_button(slot_size, slot_id)
	button.name = "%sSlot" % label
	# Resolve the current shell on click: loading a setup replaces item resources.
	button.pressed.connect(func(): _show_gear_slot_editor(label, _state.get("practice_" + GearItem.SlotType.keys()[slot_id].to_lower()), slot_id == GearItem.SlotType.WEAPON))
	button.gui_input.connect(func(event: InputEvent): _on_practice_slot_gui_input(event, slot_id, button))
	parent.add_child(button)
	_gear_slot_buttons[slot_id] = button
	return button


func _on_practice_slot_gui_input(event: InputEvent, slot_id: int, button: Button) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_RIGHT or not event.pressed:
		return
	button.accept_event()
	if _state.allocation_locked:
		return
	# Resolve the current custom shell, even when a Legendary occupies the slot
	# or a restored setup has replaced the original resource.
	_state.clear_slot(_state.get("practice_" + GearItem.SlotType.keys()[slot_id].to_lower()))


func _show_carried_editor() -> void:
	if _carried_overlay == null:
		_carried_overlay = Control.new()
		_carried_overlay.name = "CarriedGearOverlay"
		_carried_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_carried_overlay)
		var panel := CardStyle.build_modal_panel(_carried_overlay, true)
		var column := VBoxContainer.new()
		column.custom_minimum_size = Vector2(360, 0)
		column.add_theme_constant_override("separation", 8)
		panel.add_child(column)
		var title := Label.new()
		title.text = "Carried Gear  -  Practice Only"
		column.add_child(title)
		_carried_rows = VBoxContainer.new()
		column.add_child(_carried_rows)
		var done := Button.new()
		done.text = "Done"
		done.pressed.connect(func(): _carried_overlay.hide())
		column.add_child(done)
	_refresh_carried_editor()
	_carried_overlay.show()


func _refresh_carried_editor() -> void:
	if _carried_button != null:
		_carried_button.text = "Carried Gear (%d/3)" % _state.carried_items.size()
	if _carried_rows == null:
		return
	for child in _carried_rows.get_children():
		_carried_rows.remove_child(child)
		child.queue_free()
	for i in _state.carried_items.size():
		var item: GearItem = _state.carried_items[i]
		var row := HBoxContainer.new()
		_carried_rows.add_child(row)
		var edit := Button.new()
		edit.text = "%d. %s" % [i + 1, item.display_name]
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.tooltip_text = _gear_tooltip(item)
		edit.pressed.connect(func(): _show_gear_slot_editor("Carried %d" % (i + 1), item, false))
		row.add_child(edit)
		var remove := Button.new()
		remove.text = "Remove"
		remove.pressed.connect(func(): _state.remove_carried_item(i))
		row.add_child(remove)
	var add := Button.new()
	add.text = "Add Carried Item"
	add.disabled = _state.carried_items.size() >= TrainingRoomState.MAX_CARRIED_ITEMS
	add.pressed.connect(func(): _state.add_carried_item())
	_carried_rows.add_child(add)


func _texture_from_path(path: String) -> Texture2D:
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
	style.shadow_offset = Vector2(2, 4)
	return style


func _make_gear_slot_button(slot_size: Vector2, gear_slot: int) -> Button:
	var slot := GearCompareButton.new()
	slot.text = ""
	slot.custom_minimum_size = slot_size
	slot.focus_mode = Control.FOCUS_NONE
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var slot_background := TextureRect.new()
	slot_background.name = "SlotTypeBackground"
	slot_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slot_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot_background.texture = GearIcons.slot_background_for(gear_slot)
	slot_background.modulate = Color(1, 1, 1, 0.46)
	slot_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	if gear_slot in [GearItem.SlotType.LEGS, GearItem.SlotType.HANDS]:
		slot_background.offset_left = 4
		slot_background.offset_top = 4
		slot_background.offset_right = -4
		slot_background.offset_bottom = -4
	slot.add_child(slot_background)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	if gear_slot in [GearItem.SlotType.LEGS, GearItem.SlotType.HANDS]:
		icon.offset_left = 4
		icon.offset_top = 4
		icon.offset_right = -4
		icon.offset_bottom = -4
	slot.add_child(icon)
	return slot


func _build_gear_editor_overlay() -> void:
	_gear_editor_overlay = Control.new()
	_gear_editor_overlay.name = "GearEditorOverlay"
	_gear_editor_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gear_editor_overlay.visible = false
	add_child(_gear_editor_overlay)

	var panel := CardStyle.build_modal_panel(_gear_editor_overlay, true)
	panel.add_theme_stylebox_override("panel", CardStyle.make_stylebox())

	var content := VBoxContainer.new()
	content.custom_minimum_size = GEAR_EDITOR_POPUP_SIZE
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var header := HBoxContainer.new()
	_gear_editor_title = Label.new()
	_gear_editor_title.text = "Edit Gear"
	_gear_editor_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gear_editor_title.theme_type_variation = &"PanelHeader"
	_gear_editor_title.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	header.add_child(_gear_editor_title)

	var close_button := Button.new()
	close_button.text = "Done"
	close_button.pressed.connect(func(): _gear_editor_overlay.visible = false)
	header.add_child(close_button)
	content.add_child(header)

	_carried_slot_row = _build_labeled_row(content, "Slot")
	_carried_slot_option = OptionButton.new()
	for slot in GearItem.SlotType.values():
		_carried_slot_option.add_item("Pants" if slot == GearItem.SlotType.LEGS else ("Gloves" if slot == GearItem.SlotType.HANDS else GearGenerator.universal_slot_label(slot)), slot)
	_carried_slot_option.item_selected.connect(func(index): _state.set_carried_slot(_editing_gear_item, _carried_slot_option.get_item_id(index)))
	_carried_slot_row.add_child(_carried_slot_option)
	var rarity_row := _build_labeled_row(content, "Rarity")
	_gear_rarity_option = OptionButton.new()
	_gear_rarity_option.name = "RarityOption"
	_gear_rarity_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gear_rarity_option.item_selected.connect(_on_editor_rarity_selected)
	rarity_row.add_child(_gear_rarity_option)

	_gear_legendary_option = OptionButton.new()
	_gear_legendary_option.name = "LegendaryOption"
	_gear_legendary_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gear_legendary_option.item_selected.connect(_on_weapon_legendary_selected)
	content.add_child(_gear_legendary_option)

	var separator := HSeparator.new()
	content.add_child(separator)

	_legendary_details = VBoxContainer.new()
	_legendary_details.name = "LegendaryDetails"
	_legendary_details.add_theme_constant_override("separation", 5)
	content.add_child(_legendary_details)

	_gear_affix_column = VBoxContainer.new()
	_gear_affix_column.name = "AffixRows"
	_gear_affix_column.add_theme_constant_override("separation", 4)
	content.add_child(_gear_affix_column)
	_gear_validation_label = Label.new()
	_gear_validation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gear_validation_label.custom_minimum_size.x = GEAR_EDITOR_POPUP_SIZE.x
	content.add_child(_gear_validation_label)


func _show_gear_slot_editor(slot_name: String, item: GearItem, is_weapon: bool) -> void:
	if _state.allocation_locked:
		return
	_editing_gear_slot_name = slot_name
	_editing_gear_item = item
	_editing_gear_is_weapon = is_weapon
	_gear_editor_title.text = slot_name
	_refresh_gear_editor()
	if _carried_overlay != null: _carried_overlay.hide()
	move_child(_gear_editor_overlay, get_child_count() - 1)
	_gear_editor_overlay.visible = true


func _configure_editor_rarity() -> void:
	var item := _editing_gear_item
	_populate_rarity_option(_editing_gear_is_weapon)
	if _state.carried_items.has(item):
		_gear_rarity_option.remove_item(_gear_rarity_option.get_item_index(NONE_RARITY_ID))
		if item.tier == GearItem.Tier.LEGENDARY and _gear_rarity_option.get_item_index(GearItem.Tier.LEGENDARY) < 0:
			_gear_rarity_option.add_item("Legendary (fixed)", GearItem.Tier.LEGENDARY)
	var fixed_carried := _state.carried_items.has(item) and item.tier == GearItem.Tier.LEGENDARY
	_gear_rarity_option.disabled = fixed_carried
	_carried_slot_option.disabled = fixed_carried


func _populate_rarity_option(is_weapon: bool) -> void:
	_gear_rarity_option.clear()
	_gear_rarity_option.add_item("None", NONE_RARITY_ID)
	if is_weapon:
		_gear_rarity_option.add_item(RARITY_NAMES[GearItem.Tier.CRUDE], GearItem.Tier.CRUDE)
	for tier in PRACTICE_CUSTOM_TIERS:
		_gear_rarity_option.add_item(RARITY_NAMES[tier], tier)
	if not _state.carried_items.has(_editing_gear_item) and not _legendary_items_for_editor().is_empty():
		_gear_rarity_option.add_item("Legendary", GearItem.Tier.LEGENDARY)


func _on_editor_rarity_selected(index: int) -> void:
	if _editing_gear_item == null:
		return
	_on_rarity_selected(index, _gear_rarity_option, _editing_gear_item, _editing_gear_is_weapon)


func _on_rarity_selected(index: int, option: OptionButton, item: GearItem, is_weapon: bool) -> void:
	var tier: int = option.get_item_id(index)
	if tier == GearItem.Tier.LEGENDARY:
		if _state.carried_items.has(item):
			return
		var items := _legendary_items_for_editor()
		if items.is_empty():
			return
		var current_index := items.find(_equipped_editor_item())
		_state.equip_legendary(items[current_index] if current_index >= 0 else items[0])
		return
	if is_weapon and _state.is_weapon_legendary():
		_state.use_custom_weapon()
	if tier == NONE_RARITY_ID:
		_state.clear_slot(item)
	else:
		_state.set_slot_rarity(item, tier)


func _on_weapon_legendary_selected(index: int) -> void:
	var items := _legendary_items_for_editor()
	if not _state.carried_items.has(_editing_gear_item) and index >= 0 and index < items.size():
		_state.equip_legendary(items[index])


func _refresh_gear_editor() -> void:
	_refresh_carried_editor()
	_refresh_paper_doll_slots()
	if _editing_gear_item == null or _gear_affix_column == null:
		return
	var content := _gear_affix_column.get_parent() as Control
	content.custom_minimum_size.x = 550.0 if _editing_gear_item.tier == GearItem.Tier.CHAOS else GEAR_EDITOR_POPUP_SIZE.x
	_configure_editor_rarity()
	_carried_slot_row.visible = _state.carried_items.has(_editing_gear_item)
	_carried_slot_option.select(_carried_slot_option.get_item_index(_editing_gear_item.slot))
	_refresh_gear_validation()
	_refresh_popup_slot(_editing_gear_item, _editing_gear_item.tier == GearItem.Tier.LEGENDARY or (not _state.carried_items.has(_editing_gear_item) and _equipped_editor_item() != null and _equipped_editor_item().tier == GearItem.Tier.LEGENDARY))


func _refresh_paper_doll_slots() -> void:
	_update_paper_doll_slot(_weapon_slot_button, "Weapon", _state.equipped_weapon)
	_update_paper_doll_slot(_helm_slot_button, "Helm", _state.equipped_helm)
	_update_paper_doll_slot(_armor_slot_button, "Armor", _state.equipped_armor)
	_update_paper_doll_slot(_charm_slot_button, "Charm", _state.equipped_charm)
	_update_paper_doll_slot(_trinket_slot_button, "Trinket", _state.equipped_trinket)
	_update_paper_doll_slot(_legs_slot_button, "Pants", _state.equipped_legs)
	_update_paper_doll_slot(_hands_slot_button, "Gloves", _state.equipped_hands)


func _update_paper_doll_slot(slot: Button, slot_name: String, gear: GearItem) -> void:
	if slot == null:
		return
	_style_gear_slot_button(slot, gear)
	(slot.get_node("Icon") as TextureRect).texture = GearIcons.icon_for(gear)
	(slot.get_node("SlotTypeBackground") as TextureRect).modulate = Color(1, 1, 1, 0.28 if gear != null else 0.56)
	slot.tooltip_text = "%s: Empty" % slot_name if gear == null else _gear_tooltip(gear)
	var compare_slot := slot as GearCompareButton
	if compare_slot == null:
		return
	if gear == null:
		compare_slot.tooltip_builder = Callable()
	else:
		compare_slot.tooltip_builder = func() -> Control:
			return CardStyle.build_gear_tooltip(self, gear)


func _style_gear_slot_button(slot: Button, gear: GearItem) -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		slot.add_theme_stylebox_override(state, CardStyle.make_gear_item_stylebox(gear, gear != null, state))


func _refresh_popup_slot(item: GearItem, showing_legendary: bool) -> void:
	if _gear_rarity_option.item_count == 0:
		_populate_rarity_option(_editing_gear_is_weapon)
	if showing_legendary:
		_gear_rarity_option.select(_gear_rarity_option.get_item_index(GearItem.Tier.LEGENDARY))
	elif item.affixes.is_empty() and not _state.carried_items.has(item):
		_gear_rarity_option.select(_gear_rarity_option.get_item_index(NONE_RARITY_ID))
	else:
		_gear_rarity_option.select(_gear_rarity_option.get_item_index(item.tier))

	var fixed_carried := _state.carried_items.has(item) and item.tier == GearItem.Tier.LEGENDARY
	_refresh_legendary_details(item if fixed_carried else _equipped_editor_item(), showing_legendary)
	_gear_legendary_option.visible = showing_legendary and not fixed_carried
	_gear_affix_column.visible = not showing_legendary or fixed_carried
	for child in _gear_affix_column.get_children():
		child.queue_free()

	if fixed_carried:
		return
	if showing_legendary:
		_refresh_legendary_option()
		return
	for i in item.affixes.size():
		_gear_affix_column.add_child(_build_affix_row(item, i))
	if item.affixes.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No gear equipped."
		empty_label.add_theme_color_override("font_color", UIColors.TEXT_DISABLED)
		_gear_affix_column.add_child(empty_label)


func _refresh_legendary_option() -> void:
	_gear_legendary_option.clear()
	var items := _legendary_items_for_editor()
	for legendary_item in items:
		_gear_legendary_option.add_item(legendary_item.display_name)
	var current_index := items.find(_equipped_editor_item())
	_gear_legendary_option.select(maxi(current_index, 0))
	_gear_legendary_option.tooltip_text = _gear_tooltip(_equipped_editor_item())


func _legendary_items_for_editor() -> Array[GearItem]:
	var items: Array[GearItem] = []
	for item in LegendaryCatalog.all_items():
		if _editing_gear_item != null and item.slot == _editing_gear_item.slot:
			items.append(item)
	return items


func _equipped_editor_item() -> GearItem:
	if _editing_gear_item == null: return null
	match _editing_gear_item.slot:
		GearItem.SlotType.WEAPON: return _state.equipped_weapon
		GearItem.SlotType.HELM: return _state.equipped_helm
		GearItem.SlotType.ARMOR: return _state.equipped_armor
		GearItem.SlotType.CHARM: return _state.equipped_charm
		GearItem.SlotType.TRINKET: return _state.equipped_trinket
		GearItem.SlotType.LEGS: return _state.equipped_legs
		GearItem.SlotType.HANDS: return _state.equipped_hands
	return null


func _gear_tooltip(gear: GearItem) -> String:
	if gear == null:
		return ""
	return "\n".join(CardStyle.gear_tooltip_lines(gear))


func _build_affix_row(item: GearItem, index: int) -> HBoxContainer:
	var modifier: StatModifier = item.affixes[index]
	var pool := _stat_ids_for_affix_slot(item, index)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var stat_option := OptionButton.new()
	stat_option.name = "StatOption"
	stat_option.fit_to_longest_item = false
	stat_option.clip_text = true
	stat_option.custom_minimum_size.x = 230
	stat_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for stat_id in pool:
		stat_option.add_item(StatCatalog.label_for(stat_id))
		stat_option.set_item_tooltip(stat_option.item_count - 1, StatCatalog.label_for(stat_id))
		stat_option.set_item_metadata(stat_option.item_count - 1, stat_id)
	var current_id := StatCatalog.canonical_id_for_modifier(modifier)
	if not pool.has(current_id) and item.tier != GearItem.Tier.CHAOS:
		stat_option.add_item("Legacy: " + StatCatalog.label_for(current_id))
		stat_option.set_item_metadata(stat_option.item_count - 1, current_id)
	stat_option.select(_stat_option_index(stat_option, current_id))
	stat_option.tooltip_text = StatCatalog.label_for(current_id)
	stat_option.item_selected.connect(_on_affix_stat_selected.bind(item, index, stat_option))
	row.add_child(stat_option)

	var value_spin := SpinBox.new()
	value_spin.name = "AffixValue"
	value_spin.custom_minimum_size.x = 110
	value_spin.min_value = -1000.0
	value_spin.max_value = 1000.0
	value_spin.allow_greater = true
	value_spin.allow_lesser = true
	value_spin.step = _editor_step_for_modifier(modifier)
	value_spin.rounded = _editor_uses_integer_steps(modifier)
	value_spin.value = _editor_value_for_modifier(modifier)
	value_spin.value_changed.connect(_on_affix_value_changed.bind(modifier))
	row.add_child(value_spin)

	if item.tier == GearItem.Tier.CHAOS:
		var type_option := OptionButton.new()
		type_option.name = "AffixTypeOption"
		type_option.add_item("Positive Basic", StatModifier.StatCategory.BASIC)
		type_option.add_item("Positive Rare", StatModifier.StatCategory.RARE)
		type_option.add_item("Negative Basic", StatModifier.StatCategory.DRAWBACK)
		type_option.select(type_option.get_item_index(modifier.category))
		type_option.tooltip_text = "Affix type: positive Basic, positive Rare, or negative Basic"
		type_option.item_selected.connect(_on_chaos_affix_type_selected.bind(item, index, type_option))
		row.add_child(type_option)

	return row


func _on_chaos_affix_type_selected(index: int, item: GearItem, affix_index: int, type_option: OptionButton) -> void:
	_state.set_chaos_affix_type(item, affix_index, type_option.get_item_id(index))


func _on_affix_stat_selected(index: int, item: GearItem, affix_index: int, stat_option: OptionButton) -> void:
	var metadata: Variant = stat_option.get_item_metadata(index)
	_state.set_affix_stat(item, affix_index, metadata if metadata != null else stat_option.get_item_id(index))


## Still freely editable after the stat pick auto-fills a real tier value,
## per the confirmed design -- this preserves the raw editor's original
## magnitude-testing power on top of the new rarity-first defaults.
func _on_affix_value_changed(new_value: float, modifier: StatModifier) -> void:
	if _state.allocation_locked:
		return
	modifier.value = _modifier_value_from_editor(modifier, new_value)
	_state.notify_gear_edited()


func _refresh_gear_validation() -> void:
	if _gear_validation_label == null or _editing_gear_item == null:
		return
	var errors: PackedStringArray = []
	for modifier in _editing_gear_item.affixes:
		var error := "Non-finite affix value." if not is_finite(modifier.value) else StatCatalog.modifier_validation_error(modifier)
		if error != "": errors.append(error)
	_gear_validation_label.text = "\n".join(errors)
	_gear_validation_label.visible = not errors.is_empty()


func _editor_value_for_modifier(modifier: StatModifier) -> float:
	var kind := _value_kind_for_modifier(modifier)
	match kind:
		StatCatalog.VALUE_PERCENT, StatCatalog.VALUE_CHANCE:
			return modifier.value * 100.0
		StatCatalog.VALUE_FLAT, StatCatalog.VALUE_STACKS:
			return round(modifier.value)
	return modifier.value


func _modifier_value_from_editor(modifier: StatModifier, editor_value: float) -> float:
	var kind := _value_kind_for_modifier(modifier)
	match kind:
		StatCatalog.VALUE_PERCENT, StatCatalog.VALUE_CHANCE:
			return editor_value / 100.0
		StatCatalog.VALUE_FLAT, StatCatalog.VALUE_STACKS:
			return round(editor_value)
	return editor_value


func _editor_step_for_modifier(modifier: StatModifier) -> float:
	return 1.0 if _editor_uses_integer_steps(modifier) else 0.0001


func _editor_uses_integer_steps(modifier: StatModifier) -> bool:
	var kind := _value_kind_for_modifier(modifier)
	return (
		kind == StatCatalog.VALUE_FLAT
		or kind == StatCatalog.VALUE_STACKS
	)


func _value_kind_for_modifier(modifier: StatModifier) -> String:
	if modifier == null:
		return ""
	return StatCatalog.value_kind_for(StatCatalog.canonical_id_for_modifier(modifier))


func _stat_ids_for_affix_slot(item: GearItem, index: int) -> Array[String]:
	if item == null or index < 0 or index >= item.affixes.size():
		return []
	var modifier: StatModifier = item.affixes[index]
	if modifier.category == StatModifier.StatCategory.DRAWBACK:
		return StatCatalog.drawback_stat_ids_for_slot(item.slot)
	var category := StatCatalog.CATEGORY_BASIC
	if modifier.category == StatModifier.StatCategory.RARE:
		category = StatCatalog.CATEGORY_RARE
	elif modifier.category == StatModifier.StatCategory.SPECIAL:
		category = StatCatalog.CATEGORY_SPECIAL
	return StatCatalog.stat_ids_for_slot(item.slot, category)


func _stat_option_index(option: OptionButton, stat_id: String) -> int:
	for i in option.item_count:
		if String(option.get_item_metadata(i)) == stat_id:
			return i
	return 0


func _build_fight_setup_panel(parent: Container) -> void:
	var panel := PanelContainer.new()
	panel.name = "FightSetupPanel"
	panel.add_theme_stylebox_override("panel", CardStyle.make_stylebox(12))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var title := Label.new()
	title.text = "Fight Setup"
	title.theme_type_variation = &"PanelHeader"
	title.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	content.add_child(title)

	var controls := VBoxContainer.new()
	controls.name = "FightSetupRow"
	controls.add_theme_constant_override("separation", 6)
	content.add_child(controls)

	_build_fight_setup_controls(controls)


## Duration/practice-gold (P2:R10:T5; target now lives in its own
## TrainingTargetPanel card, see _refresh_target_panel()) -- built once,
## unlike the build/gear sections above, since nothing external changes
## these values; only this row's own controls do.
func _build_fight_setup_controls(parent: VBoxContainer) -> void:
	var timing_row := HBoxContainer.new()
	timing_row.add_theme_constant_override("separation", 6)
	parent.add_child(timing_row)

	var duration_label := Label.new()
	duration_label.text = "Seconds"
	duration_label.custom_minimum_size = Vector2(62, 0)
	timing_row.add_child(duration_label)

	_duration_spin = SpinBox.new()
	_duration_spin.min_value = 1
	_duration_spin.max_value = 120
	_duration_spin.step = 1
	_duration_spin.value = _state.duration_ms / 1000.0
	_duration_spin.custom_minimum_size = Vector2(72, 0)
	_duration_spin.value_changed.connect(_on_duration_changed)
	timing_row.add_child(_duration_spin)

	var seed_label := Label.new()
	seed_label.text = "Seed"
	seed_label.custom_minimum_size = Vector2(40, 0)
	timing_row.add_child(seed_label)

	_seed_spin = SpinBox.new()
	_seed_spin.name = "FightSeedSpin"
	_seed_spin.min_value = 0
	_seed_spin.max_value = 2147483647
	_seed_spin.step = 1
	_seed_spin.rounded = true
	_seed_spin.value = _state.fight_seed
	_seed_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seed_spin.value_changed.connect(_on_fight_seed_changed)
	timing_row.add_child(_seed_spin)

	_random_seed_toggle = CheckBox.new()
	_random_seed_toggle.name = "RandomFightSeedToggle"
	_random_seed_toggle.text = "Random"
	_random_seed_toggle.tooltip_text = "Use a fresh random seed for each practice fight and generated target roll"
	_random_seed_toggle.button_pressed = _state.random_fight_seed_enabled
	_random_seed_toggle.toggled.connect(_on_random_fight_seed_toggled)
	timing_row.add_child(_random_seed_toggle)

	var gold_row := _build_labeled_row(parent, "Practice Gold")
	_gold_spin = SpinBox.new()
	_gold_spin.name = "PracticeGoldSpin"
	_gold_spin.min_value = 0
	_gold_spin.max_value = 99999
	_gold_spin.step = 1
	_gold_spin.rounded = true
	_gold_spin.value = _state.gold
	_gold_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gold_spin.value_changed.connect(_on_practice_gold_changed)
	gold_row.add_child(_gold_spin)
	var attempts_row := _build_labeled_row(parent, "Missing attempts")
	_missing_attempts_spin = SpinBox.new()
	_missing_attempts_spin.name = "MissingAttemptsSpin"
	_missing_attempts_spin.min_value = 0
	_missing_attempts_spin.max_value = 99
	_missing_attempts_spin.step = 1
	_missing_attempts_spin.value = _state.legendary_missing_attempts
	_missing_attempts_spin.tooltip_text = "Death’s Door test input: 0 gives x1, 1 gives x2, 2 gives x4. Adventure lives are unchanged."
	_missing_attempts_spin.value_changed.connect(func(value):
		if not _state.set_legendary_missing_attempts(int(value)):
			_refresh_fight_setup_controls())
	attempts_row.add_child(_missing_attempts_spin)


## One label + control row, stacked in the narrow right column rather than
## all three pairs crammed into a single horizontal row (which fit fine when
## this sat in its own full-width section, but not in a column this narrow).
func _build_labeled_row(parent: VBoxContainer, label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(100, 0)
	row.add_child(label)
	return row


func _on_target_armor_changed(value: int) -> void:
	_state.set_target_armor(value)


func _on_target_poison_resist_changed(value: float) -> void:
	_state.set_target_poison_resistance(value)


func _on_target_defense_changed(field: String, value: Variant) -> void:
	_state.set_target_defense(field, value)


func _on_target_preset_selected(preset_id: String) -> void:
	_state.apply_target_preset(preset_id)


func _on_generated_roll_requested(contract_level: int, difficulty_id: int, monster_kind: String, archetype_a_id: String, archetype_b_id: String) -> void:
	var seed := -1 if _state.random_fight_seed_enabled else _state.fight_seed
	_state.roll_generated_target(difficulty_id, seed, monster_kind, archetype_a_id, archetype_b_id, contract_level)


## Pushes the target's current defenses into the card -- called
## once up front and again on every fight_setup_changed (target or duration
## edits).
func _refresh_target_panel() -> void:
	_target_panel.refresh_defenses(_state.target_defense_snapshot())
	_target_panel.refresh_generated_info(_state.generated_monster_draft)


func _refresh_fight_setup_controls() -> void:
	if _missing_attempts_spin != null:
		_missing_attempts_spin.set_block_signals(true)
		_missing_attempts_spin.value = _state.legendary_missing_attempts
		_missing_attempts_spin.set_block_signals(false)
	if _duration_spin != null:
		_duration_spin.set_block_signals(true)
		_duration_spin.value = _state.duration_ms / 1000.0
		_duration_spin.set_block_signals(false)
	if _seed_spin != null:
		_seed_spin.set_block_signals(true)
		_seed_spin.value = _state.fight_seed
		_seed_spin.editable = not _state.random_fight_seed_enabled
		_seed_spin.set_block_signals(false)
	if _random_seed_toggle != null:
		_random_seed_toggle.set_block_signals(true)
		_random_seed_toggle.button_pressed = _state.random_fight_seed_enabled
		_random_seed_toggle.set_block_signals(false)
	if _gold_spin != null:
		_gold_spin.set_block_signals(true)
		_gold_spin.value = _state.gold
		_gold_spin.set_block_signals(false)


func _refresh_combat_view_fight_window() -> void:
	if _combat_view != null:
		_combat_view.set_fight_window_ms(_state.duration_ms)


func _refresh_combat_view_target() -> void:
	if _combat_view != null:
		_combat_view.set_target_preview(_state.selected_target)


func _on_duration_changed(seconds: float) -> void:
	_state.set_duration_ms(roundi(seconds * 1000.0))


func _on_fight_seed_changed(value: float) -> void:
	_state.set_fight_seed(int(value))


func _on_random_fight_seed_toggled(enabled: bool) -> void:
	_state.set_random_fight_seed_enabled(enabled)


func _on_practice_gold_changed(value: float) -> void:
	_state.set_practice_gold(int(value))


## An empty macro is a guaranteed zero-damage loss -- same guard
## `skill_build_panel.gd`'s Lock button already uses for the same reason.
func _refresh_fight_button() -> void:
	if _missing_attempts_spin != null:
		_missing_attempts_spin.editable = not _state.allocation_locked
		_missing_attempts_spin.set_value_no_signal(_state.legendary_missing_attempts)
	_fight_button.disabled = not _state.can_run_fight()
	if _state.rotation.is_empty():
		_fight_button.tooltip_text = "Slot at least one skill before fighting"
	elif not _state.build_locked:
		_fight_button.tooltip_text = "Lock your skill build to fight"
	else:
		_fight_button.tooltip_text = ""


func _on_fight_button_pressed() -> void:
	if not _state.can_run_fight():
		_refresh_fight_button()
		CardStyle.pulse_blocked_control(_fight_button)
		return
	_state.run_fight()


## Combat has already fully resolved synchronously inside _state.run_fight()
## by this point -- this only starts the combat view's re-play of the
## already-recorded timeline. The result log itself is filled in once that
## animation (or its headless instant-skip) finishes, via _combat_view's
## `finished` signal -> _on_combat_view_finished().
func _on_state_fight_finished() -> void:
	if not _state.last_result.is_valid:
		_on_combat_view_finished()
		return
	_state.allocation_locked = true
	_state.lock_changed.emit()
	var stats := _state.current_player_stats()
	_combat_view.play(
		_state.last_result,
		_state.selected_target,
		_state.equipped_gear(),
		stats.shred_value,
		CombatResolver.effective_enemy_slow(stats, _state.selected_target),
		_base_poison_damage_for_stats(stats),
		stats.decay_value
	)


func _base_poison_damage_for_stats(stats: PlayerStats) -> float:
	var base_damage := stats.base_poison_damage + stats.bonus_base_elemental_damage
	if stats.base_poison_damage > 0.0 or stats.bonus_base_elemental_damage != 0.0:
		base_damage = maxf(PlayerStats.MIN_DAMAGE_BASE, base_damage)
	return base_damage


## Fills the (button-gated, see _build_log_overlay()) Combat Log and enables
## the button that reveals it -- mirrors combat_screen.gd's
## _view_log_button/_log_overlay pattern (disabled until the first fight
## resolves, dismissible via Close or clicking the backdrop).
func _on_combat_view_finished() -> void:
	_state.allocation_locked = false
	_state.lock_changed.emit()
	_log_overlay.set_result(_state.last_result, _state.selected_target, CombatResultFormatter.format_practice(_state.last_result, _state.selected_target))
	_view_log_button.disabled = false


func _invalidate_result_review() -> void:
	if _view_log_button != null:
		_view_log_button.disabled = true
	if _log_overlay != null:
		_log_overlay.visible = false
	if _log_overlay != null:
		_log_overlay.set_result_text("")


## Dimmed backdrop (click to dismiss) + a centered card holding the actual
## log -- same shape as combat_screen.gd's _build_log_overlay(). Hidden until
## the first fight resolves.
func _build_log_overlay() -> void:
	_log_overlay = LOG_OVERLAY_SCENE.instantiate()
	_log_overlay.practice_mode = true
	add_child(_log_overlay)
	_log_inspector = _log_overlay._inspector
	_result_log = _log_overlay._log_label


func _queue_setup_save() -> void:
	if not _setup_autosave or _setup_save_queued:
		return
	_setup_save_queued = true
	call_deferred("_commit_setup_save")

func _commit_setup_save(replace_existing: bool = false) -> void:
	_setup_save_queued = false
	if not PracticeSaveSystem.save_setup(_state, replace_existing):
		_setup_autosave = false
		_persistence_notice.text = PracticeSaveSystem.last_error
	else:
		_setup_autosave = true
		_persistence_notice.text = ""
	var changes: Dictionary = _state.rotation_changes
	if not changes.get("removed", []).is_empty() or not changes.get("overflow", []).is_empty():
		_persistence_notice.text += " Rotation entries removed: %s; beyond ten slots: %s." % [str(changes.get("removed", [])), str(changes.get("overflow", []))]


func _refresh_legendary_details(item: GearItem, showing: bool) -> void:
	for child in _legendary_details.get_children():
		_legendary_details.remove_child(child)
		child.queue_free()
	_legendary_details.visible = showing and item != null
	if not _legendary_details.visible: return
	var text := Label.new()
	text.custom_minimum_size.x = GEAR_EDITOR_POPUP_SIZE.x
	text.add_theme_font_size_override("font_size", 17)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var lines := CardStyle.gear_tooltip_lines(item)
	if lines.size() > 2: lines = lines.slice(2)
	text.text = "\n".join(lines)
	_legendary_details.add_child(text)
