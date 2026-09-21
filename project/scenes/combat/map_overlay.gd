extends Control
## The Map overlay: the Tavern encounter ladder, the Contract Offer node, and
## the Gilded Serpent route schematic all share this one window, switching
## which of the three it renders off BuildState. Extracted from
## combat_screen.gd's inline overlay builder
## (docs/Phase_3_Technical_Debt_Architecture_Cleanup.md Phase 3) -- gates a
## real decision with no defined "cancel" behavior, so it stays locked (no
## dismiss on outside click), matching its behavior before extraction.
##
## Like the other extracted overlays, this scene owns its own construction,
## refresh, and node/story presentation, but NOT the consequences of a
## choice: `tavern_proceed_pressed`, `contract_offer_pressed`, and
## `route_node_pressed(node)` hand those to combat_screen.gd, which owns
## BuildState mutation, the dashboard chrome, and autosaving.
##
## No `class_name` -- this script references the BuildState autoload; see
## contract_overlay.gd's header for why that rules out a global class.
##
## NOTE (carried over unchanged from combat_screen.gd): the Gilded Serpent
## route schematic below is hardcoded to one contract's node ids and
## hand-tuned pixel positions. That is finding 1.4 in the tech-debt doc,
## deliberately deferred until a second contract exists rather than
## generalized speculatively during this extraction.

## The player picked a Tavern encounter and pressed Proceed.
signal tavern_proceed_pressed
## The player clicked the single Contract Offer node.
signal contract_offer_pressed
## The player backed out of an accepted contract before committing a route.
signal contract_back_requested
## The player clicked a selectable contract-route node.
signal route_node_pressed(node: ContractRouteNode)

const MAP_NODE_SIZE := Vector2(190, 150)
const CONTRACT_MAP_SIZE := Vector2(840, 470)
const CONTRACT_NODE_SIZE := Vector2(164, 108)
const HIDEOUT_CONTRACT_MAP_SIZE := Vector2(1020, 500)
const HIDEOUT_NODE_FRAME_TEXTURE_PATH := "res://assets/ui/map/biome_frames/hideout_box.png"
const HIDEOUT_NODE_HIGHLIGHT_TEXTURE_PATH := "res://assets/ui/map/biome_frames/hideout_box_gray.png"
const HIDEOUT_NODE_SIZE := Vector2(150, 118)
const HIDEOUT_NODE_FRAME_VISUAL_SIZE := Vector2(176, 176)
const HIDEOUT_NODE_GLOW_PADDING := Vector2(20, 20)
const HIDEOUT_MAP_TEXT_INSET := Vector2(8, 34)
const HIDEOUT_MAP_TEXT_MIN_WIDTH := 156.0
const HIDEOUT_MAP_TEXT_BOTTOM_MARGIN := 64.0
const HIDEOUT_REWARD_STACK_SIZE := Vector2(150, 52)
const HIDEOUT_REWARD_STACK_OFFSET_Y := 68.0
const GENERATED_CONTRACT_MAP_SIZE := Vector2(980, 640)
const GENERATED_CONTRACT_NODE_SIZE := Vector2(148, 116)
const GENERATED_MAP_TEXT_INSET := Vector2(14, 10)
const GENERATED_MAP_TEXT_MIN_WIDTH := 216.0
const GENERATED_ENEMY_NAME_FONT_SIZE := 23
const GENERATED_REWARD_STACK_SIZE := Vector2(216, 58)
const GENERATED_REWARD_STACK_OFFSET_Y := 60.0
const GENERATED_REWARD_ICON_SIZE := Vector2(17, 17)
const GENERATED_REWARD_ICON_BACKING_SIZE := Vector2(21, 21)
const GENERATED_REWARD_PILL_MIN_SIZE := Vector2(58, 23)
const GENERATED_REWARD_AMOUNT_FONT_SIZE := 21
const GENERATED_MAP_MARGIN := Vector2(16, 16)
const GENERATED_MAP_OFFSET_LIMIT := Vector2(14, 12)
const GENERATED_MAP_NODE_GAP := Vector2(18, 6)
const GENERATED_DENSE_OPENER_RESERVED_WIDTH := 320.0
const GENERATED_DENSE_SHORT_ROUTE_RESERVED_WIDTH := 500.0
const GENERATED_DENSE_OPENER_STAGGER_X := 100.0
const GENERATED_DENSE_SHORT_ROUTE_STAGGER_X := 155.0
const GENERATED_DENSE_BOSS_APPROACH_RESERVED_WIDTH := 450.0
const GENERATED_DENSE_BOSS_APPROACH_STAGGER_X := 140.0
const GENERATED_EDGE_SAMPLE_COUNT := 18
const GENERATED_EDGE_THICKNESS := 5.0
const GENERATED_EDGE_THICKNESS_ACTIVE := 7.0
const GENERATED_EDGE_TRAIL_DASH_LENGTH := 15.0
const GENERATED_EDGE_TRAIL_GAP_LENGTH := 10.0
const GENERATED_BIOME_FRAME_VISUAL_SIZE := Vector2(174, 174)
const GENERATED_BIOME_GLOW_PADDING := Vector2(24, 24)
const TAVERN_MAP_SIZE := Vector2(860, 250)
const TAVERN_NODE_FRAME_TEXTURE_PATH := "res://assets/ui/map/biome_frames/tavern_box.png"
const TAVERN_NODE_HIGHLIGHT_TEXTURE_PATH := "res://assets/ui/map/biome_frames/tavern_box_gray.png"
const TAVERN_NODE_FRAME_VISUAL_SIZE := Vector2(188, 188)
const TAVERN_NODE_GLOW_PADDING := Vector2(24, 24)
const TAVERN_MAP_TEXT_INSET := Vector2(18, 58)
const TAVERN_MAP_TEXT_MIN_WIDTH := 152.0
const TAVERN_MAP_TEXT_BOTTOM_MARGIN := 86.0
const TAVERN_REWARD_STACK_SIZE := Vector2(132, 58)
const TAVERN_REWARD_STACK_OFFSET_Y := 112.0
const MAP_ACTOR_MARKER_SIZE := Vector2(76, 76)
const MAP_ACTOR_MARKER_OFFSET := Vector2(10, -4)
const MAP_REWARD_ICON_SIZE := Vector2(24, 24)
const MAP_TEXT_BLOCK_LEFT := 76.0
const MAP_TEXT_BLOCK_TOP := 26.0
const MAP_TEXT_BLOCK_BOTTOM := 34.0
const TOP_CHROME_CLICKTHROUGH_CLEARANCE := 88.0
## Tavern map's art box -- the exterior shot shown while choosing a Tavern
## encounter, replacing the earlier plain black placeholder.
const TAVERN_MAP_ART_TEXTURE := preload("res://assets/backgrounds/Tavern__Exterior.jpg")
## Smaller than MAP_NODE_SIZE -- the Tavern map (P2:R7 story pass) makes room
## for TAVERN_ART_BOX_SIZE above it and sits lower in the panel, so its own
## node buttons shrink to match rather than crowding the reduced space.
const TAVERN_MAP_NODE_SIZE := TAVERN_NODE_FRAME_VISUAL_SIZE
## Placeholder for future scene art above the Tavern's node row -- same
## "solid near-black fill, art to come later" convention as the combat
## window's own UIColors.PANEL_DEEP background.
const TAVERN_ART_BOX_SIZE := Vector2(760, 200)
const FLOW_TEXT := preload("res://scripts/ui/adventure_flow_text.gd")

## The Tavern map's default flavor line, shown until a node is clicked to
## preview it (see _tavern_story_text()).
const TAVERN_INTRO_TEXT := "You find a nice respite from the rain in the dim light of a warm tavern. You do your best to mind your own business, but fate does not always abide."

## Per-encounter flavor line shown once its node is clicked (preview state,
## before Proceed commits the choice) -- keyed by Monster.display_name, the
## same key _tavern_story_text() already reads off BuildState.current_encounter().
const TAVERN_ENCOUNTER_FLAVOR_TEXT := {
	"Mouthy Drunk": "A red-faced patron decides your quiet corner is somehow his business.",
	"Drunk Buddy": "Leaping to his fallen companion's aid, another drunk patron wants to try his hand.",
	"Tavern Bouncer": "The burley bouncer grabs you to politely show you the door.",
	"Hired Goon": "A mysterious and sinister figure in the corner takes notice. His large bodyguard steps over to have a word with you.",
}

## Shown on the map when returning to it after winning that encounter --
## i.e. while choosing the *next* encounter, before its own node is previewed
## (see _tavern_pre_choice_story_text()). Keyed the same way as
## TAVERN_ENCOUNTER_FLAVOR_TEXT. Reflects the new state of the story rather
## than replaying TAVERN_INTRO_TEXT a second time.
const TAVERN_VICTORY_TEXT := {
	"Mouthy Drunk": "You easily dispatch him with a few well-placed strikes. He falls into a heap on the floor. However, this has caused quite the commotion.",
	"Drunk Buddy": "He lands with a thud atop the fallen body of his companion, but now the tavern is abuzz with action. You have made your pressence known; however you are not sure that was the best idea.",
	"Tavern Bouncer": "The night is cold and the fire warm, so you not-so politely decline his invitation. The rest of the patrons have scattered. Now you might get some peace and quite.",
	"Hired Goon": "Being in no mood for this, you \"pursuede\" the large gentlemen to joins the gorwing pile of bodies.",
}

const GENERATED_CONTRACT_ROUTE_FLAVOR_BY_BIOME := {
	"Swamp": [
		"Many heads, one payday. Try not to become soup.",
		"The swamp has teeth today. Bring yours.",
		"A wet, awful job. Naturally, Ghit calls it asset recovery.",
	],
	"Cave": [
		"The thing below has been eating workers, witnesses, and profit margins.",
		"Dark tunnels, sharp echoes, generous hazard pay. Probably fine.",
		"Ghit wants the cave cleared. He was very careful not to say why.",
	],
	"Graveyard": [
		"Something is rearranging the dead. Ghit would like it rearranged back.",
		"The locals are restless, unpaid, and mostly deceased. Perfect contract work.",
		"Bring a shovel if you want. Bring a sharper plan if you want to live.",
	],
	"Haunted Forest": [
		"The trees are whispering. Ghit insists they are saying invoiceable things.",
		"Into the woods, then. Try not to negotiate with anything that rhymes.",
		"Branches, curses, and a payday tucked somewhere unpleasant.",
	],
	"Ruined Keep": [
		"Old walls, fresh trouble, and Ghit's favorite kind of history: billable.",
		"The keep is ruined already, so do not be shy about improving it.",
		"Someone dangerous moved into broken stone. Evict them with enthusiasm.",
	],
	"Ancient Ruins": [
		"Go ruin something ancient and profitable.",
		"The stones are older than the contract. The danger is much more current.",
		"Ghit says archaeology is easier when everything stops trying to kill you.",
	],
}

const GENERATED_CONTRACT_MAP_THEME_FALLBACK := {
	"id": "default",
	"background": Color(0.075, 0.052, 0.036, 1.0),
	"wash": Color(0.32, 0.23, 0.13, 0.18),
	"accent": Color(0.79, 0.64, 0.35, 0.72),
	"route": Color(0.46, 0.37, 0.25, 0.64),
	"available": Color(0.79, 0.64, 0.35, 0.76),
	"selected": Color(0.93, 0.74, 0.39, 0.94),
	"completed": Color(0.56, 0.75, 0.45, 0.60),
	"boss": Color(0.70, 0.25, 0.22, 0.34),
}

const GENERATED_CONTRACT_MAP_THEMES := {
	"Swamp": {
		"id": "swamp",
		"background": Color(0.045, 0.073, 0.043, 1.0),
		"wash": Color(0.30, 0.47, 0.22, 0.19),
		"accent": Color(0.57, 0.75, 0.45, 0.78),
		"route": Color(0.40, 0.51, 0.25, 0.66),
		"available": Color(0.62, 0.79, 0.42, 0.82),
		"selected": Color(0.83, 0.91, 0.53, 0.96),
		"completed": Color(0.47, 0.68, 0.42, 0.64),
		"boss": Color(0.34, 0.58, 0.22, 0.34),
	},
	"Cave": {
		"id": "cave",
		"background": Color(0.045, 0.049, 0.057, 1.0),
		"wash": Color(0.35, 0.39, 0.47, 0.17),
		"accent": Color(0.58, 0.65, 0.73, 0.76),
		"route": Color(0.38, 0.42, 0.47, 0.66),
		"available": Color(0.70, 0.69, 0.55, 0.82),
		"selected": Color(0.86, 0.81, 0.58, 0.96),
		"completed": Color(0.42, 0.59, 0.66, 0.62),
		"boss": Color(0.42, 0.46, 0.55, 0.34),
	},
	"Graveyard": {
		"id": "graveyard",
		"background": Color(0.058, 0.055, 0.048, 1.0),
		"wash": Color(0.48, 0.48, 0.39, 0.15),
		"accent": Color(0.66, 0.65, 0.52, 0.76),
		"route": Color(0.43, 0.42, 0.33, 0.66),
		"available": Color(0.76, 0.70, 0.47, 0.82),
		"selected": Color(0.91, 0.80, 0.49, 0.96),
		"completed": Color(0.47, 0.62, 0.55, 0.60),
		"boss": Color(0.53, 0.48, 0.39, 0.32),
	},
	"Haunted Forest": {
		"id": "haunted_forest",
		"background": Color(0.039, 0.060, 0.055, 1.0),
		"wash": Color(0.26, 0.45, 0.39, 0.17),
		"accent": Color(0.50, 0.72, 0.62, 0.76),
		"route": Color(0.31, 0.46, 0.39, 0.66),
		"available": Color(0.65, 0.78, 0.50, 0.82),
		"selected": Color(0.84, 0.87, 0.58, 0.96),
		"completed": Color(0.39, 0.65, 0.55, 0.62),
		"boss": Color(0.29, 0.55, 0.48, 0.34),
	},
	"Ruined Keep": {
		"id": "ruined_keep",
		"background": Color(0.067, 0.052, 0.048, 1.0),
		"wash": Color(0.52, 0.32, 0.25, 0.16),
		"accent": Color(0.70, 0.52, 0.39, 0.76),
		"route": Color(0.45, 0.33, 0.28, 0.66),
		"available": Color(0.78, 0.62, 0.43, 0.82),
		"selected": Color(0.92, 0.72, 0.48, 0.96),
		"completed": Color(0.52, 0.63, 0.48, 0.60),
		"boss": Color(0.63, 0.31, 0.24, 0.34),
	},
	"Ancient Ruins": {
		"id": "ancient_ruins",
		"background": Color(0.055, 0.048, 0.070, 1.0),
		"wash": Color(0.39, 0.33, 0.59, 0.16),
		"accent": Color(0.64, 0.56, 0.82, 0.74),
		"route": Color(0.39, 0.33, 0.50, 0.66),
		"available": Color(0.72, 0.64, 0.88, 0.82),
		"selected": Color(0.88, 0.78, 0.96, 0.96),
		"completed": Color(0.49, 0.59, 0.72, 0.60),
		"boss": Color(0.48, 0.34, 0.70, 0.34),
	},
}

const CONTRACT_LINE_COLOR := UIColors.STRUCTURE_LINE
const CONTRACT_LINE_HIGHLIGHT_COLOR := Color(0.79, 0.64, 0.35, 0.42)
const CONTRACT_LINE_THICKNESS := 5.0
## Map/contract-route/secondary-tree buttons carry dense multi-line data
## text (stats, difficulty, reward tags) rather than a short action label,
## so they stay on the VT323 body/data font instead of the theme's default
## Press Start 2P button font -- Press Start 2P's width would clip or
## badly overflow these fixed-size, multi-line buttons (P2:R7:T2 Phase 2
## legibility pass).
const DATA_BUTTON_FONT := preload("res://assets/fonts/VT323-Regular.ttf")
const MAP_ICON := preload("res://assets/ui/icons/map.png")
const CONTRACT_ICON := preload("res://assets/ui/icons/contract.png")
const FIGHT_ICON := preload("res://assets/ui/icons/fight.png")
const GOLD_ICON := preload("res://assets/ui/icons/gold.png")
const MAP_FRAME_OUTLINE_SHADER := preload("res://assets/ui/map/map_frame_outline.gdshader")
const GEAR_DROP_ICON_PATHS := {
	GearItem.Tier.CRUDE: "res://assets/ui/icons/gear_drop_helm_basic.png",
	GearItem.Tier.BASIC: "res://assets/ui/icons/gear_drop_helm_basic.png",
	GearItem.Tier.MASTER: "res://assets/ui/icons/gear_drop_helm_master.png",
	GearItem.Tier.EPIC: "res://assets/ui/icons/gear_drop_helm_master.png",
	GearItem.Tier.CURSED: "res://assets/ui/icons/gear_drop_helm_cursed.png",
	GearItem.Tier.CHAOS: "res://assets/ui/icons/gear_drop_helm_cursed.png",
	GearItem.Tier.UNIQUE: "res://assets/ui/icons/gear_drop_helm_legendary.png",
	GearItem.Tier.LEGENDARY: "res://assets/ui/icons/gear_drop_helm_legendary.png",
}
const GENERATED_BIOME_FRAME_TEXTURE_PATHS := {
	"Graveyard": "res://assets/ui/map/biome_frames/grave_box.png",
	"Swamp": "res://assets/ui/map/biome_frames/swap_box.png",
	"Cave": "res://assets/ui/map/biome_frames/cave_box.png",
	"Haunted Forest": "res://assets/ui/map/biome_frames/forest_box.png",
	"Ruined Keep": "res://assets/ui/map/biome_frames/keep_box.png",
	"Ancient Ruins": "res://assets/ui/map/biome_frames/ruins_box.png",
}
const GENERATED_BIOME_HIGHLIGHT_TEXTURE_PATHS := {
	"Graveyard": "res://assets/ui/map/biome_frames/grave_box_gray.png",
	"Swamp": "res://assets/ui/map/biome_frames/swap_box_gray.png",
	"Cave": "res://assets/ui/map/biome_frames/cave_box_gray.png",
	"Haunted Forest": "res://assets/ui/map/biome_frames/forest_box_gray.png",
	"Ruined Keep": "res://assets/ui/map/biome_frames/keep_box_gray.png",
	"Ancient Ruins": "res://assets/ui/map/biome_frames/ruins_box_gray.png",
}

enum TavernNodeState { DEFEATED, AVAILABLE, PREVIEWED, LOCKED }
const AVAILABLE_PULSE_DURATION_SEC := 0.72

var _map_phase_label: Label
var _map_story_label: Label
var _map_art_box: Control
var _map_nodes_box: HBoxContainer
var _map_node_buttons: Array[Button] = []
var _map_contract_back_button: Button
var _map_close_button: Button
var _map_proceed_button: Button
var _map_manual_open: bool = false
var _pending_contract_route_node: ContractRouteNode = null
var _gear_drop_icon_cache: Dictionary = {}
var _biome_frame_texture_cache: Dictionary = {}
var _map_actor_texture_cache: Dictionary = {}
## Which Tavern node the player has clicked to preview but not yet committed
## via Proceed; -1 when nothing is previewed.
var _tavern_preview_index: int = -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	var panel := CardStyle.build_modal_panel(self, false)
	var backdrop := get_child(0) as Control
	if backdrop != null:
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.offset_top = TOP_CHROME_CLICKTHROUGH_CLEARANCE
	var style := CardStyle.make_stylebox(18)
	style.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(940, 560)
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	content.add_child(title_row)

	title_row.add_child(CardStyle.make_pixel_icon(MAP_ICON, CardStyle.UI_ICON_SIZE))

	var title := Label.new()
	title.text = "Map"
	title.theme_type_variation = &"PanelHeader"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", CardStyle.ACCENT_COLOR)
	title_row.add_child(title)

	_map_phase_label = Label.new()
	_map_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_map_phase_label.add_theme_font_size_override("font_size", 24)
	content.add_child(_map_phase_label)

	_map_story_label = Label.new()
	_map_story_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_map_story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_map_story_label.custom_minimum_size = Vector2(860, 0)
	_map_story_label.add_theme_constant_override("line_spacing", 0)
	content.add_child(_map_story_label)

	# Tavern-only scene art (hidden for Contract Offer/Route, which never set
	# it visible) -- sized/positioned so the node row below reads as smaller
	# and pushed toward the bottom of the panel, per the story pass's mockup.
	_map_art_box = PanelContainer.new()
	_map_art_box.custom_minimum_size = TAVERN_ART_BOX_SIZE
	_map_art_box.visible = false
	var art_box_style := CardStyle.make_stylebox(8)
	art_box_style.bg_color = UIColors.PANEL_DEEP
	_map_art_box.add_theme_stylebox_override("panel", art_box_style)
	content.add_child(_map_art_box)

	var map_art_image := TextureRect.new()
	map_art_image.texture = TAVERN_MAP_ART_TEXTURE
	map_art_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_art_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	map_art_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_art_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_art_box.add_child(map_art_image)

	var center_row := CenterContainer.new()
	center_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(center_row)

	_map_nodes_box = HBoxContainer.new()
	_map_nodes_box.add_theme_constant_override("separation", 0)
	center_row.add_child(_map_nodes_box)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_END
	button_row.add_theme_constant_override("separation", 8)
	content.add_child(button_row)

	# Tavern and Contract Route both use select-then-Proceed: node clicks
	# preview/select, while this button is the actual commit step.
	_map_contract_back_button = Button.new()
	_map_contract_back_button.text = "Back"
	CardStyle.configure_icon_button(_map_contract_back_button, CONTRACT_ICON)
	_map_contract_back_button.visible = false
	_map_contract_back_button.pressed.connect(func():
		if _can_show_contract_back_button():
			contract_back_requested.emit()
	)
	button_row.add_child(_map_contract_back_button)

	_map_proceed_button = Button.new()
	_map_proceed_button.text = FLOW_TEXT.ACTION_PROCEED
	CardStyle.configure_icon_button(_map_proceed_button, FIGHT_ICON)
	_map_proceed_button.visible = false
	_map_proceed_button.disabled = true
	_map_proceed_button.pressed.connect(_on_map_proceed_pressed)
	button_row.add_child(_map_proceed_button)

	_map_close_button = Button.new()
	_map_close_button.text = FLOW_TEXT.ACTION_CLOSE_MAP
	_map_close_button.pressed.connect(func(): visible = false)
	button_row.add_child(_map_close_button)
	refresh()


func refresh() -> void:
	if _map_nodes_box == null:
		return
	_sync_pending_contract_route_node()
	if _map_contract_back_button != null:
		_map_contract_back_button.visible = _can_show_contract_back_button()
		_map_contract_back_button.tooltip_text = "Return to contract offers before starting combat."
	if _map_close_button != null:
		_map_close_button.visible = _map_manual_open or not _map_requires_choice()
	for child in _map_nodes_box.get_children():
		child.queue_free()
	_map_node_buttons = []
	if BuildState.run_phase == BuildState.RunPhase.CONTRACT_OFFER:
		_refresh_contract_offer_map()
	elif BuildState.active_contract != null:
		_refresh_contract_route_map()
	else:
		_refresh_tavern_map()


func _refresh_tavern_map() -> void:
	_map_phase_label.text = "The Nooby Tavern"
	_map_story_label.text = _tavern_story_text()
	_map_art_box.visible = true
	_map_proceed_button.text = FLOW_TEXT.ACTION_PROCEED
	# Always visible while a choice is pending (not just once previewed),
	# just disabled until then -- same "always there, grayed out until you
	# act" pattern as the Contract Window's own Proceed button, deliberately,
	# so this teaches the player what to expect there.
	_map_proceed_button.visible = BuildState.needs_tavern_map_choice()
	_map_proceed_button.disabled = _tavern_preview_index != BuildState.current_encounter_index
	_map_proceed_button.tooltip_text = (
		"Click the available Tavern fight first."
		if _map_proceed_button.disabled
		else "Commit this Tavern fight."
	)
	var schematic := _make_tavern_map_schematic()
	_map_nodes_box.add_child(schematic)


func _make_tavern_map_schematic() -> Control:
	var canvas := Control.new()
	canvas.name = "TavernMapSchematic"
	canvas.custom_minimum_size = TAVERN_MAP_SIZE
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in RunFlow.tavern_encounter_count() - 1:
		_add_tavern_map_edge(canvas, i, i + 1)
	for i in RunFlow.tavern_encounter_count():
		var button := _make_tavern_map_node_button(i)
		_map_node_buttons.append(button)
		button.position = _tavern_map_node_position(i)
		canvas.add_child(button)
	return canvas


func _tavern_map_node_position(index: int) -> Vector2:
	var y_offsets := [34.0, 0.0, 42.0, 14.0]
	var gap := (TAVERN_MAP_SIZE.x - TAVERN_MAP_NODE_SIZE.x * float(RunFlow.tavern_encounter_count())) / float(maxi(RunFlow.tavern_encounter_count() - 1, 1))
	return Vector2(
		float(index) * (TAVERN_MAP_NODE_SIZE.x + gap),
		y_offsets[index % y_offsets.size()]
	)


func _add_tavern_map_edge(canvas: Control, from_index: int, to_index: int) -> void:
	var from_position := _tavern_map_node_position(from_index)
	var to_position := _tavern_map_node_position(to_index)
	var from_center := _tavern_node_center(from_position)
	var to_center := _tavern_node_center(to_position)
	var start := Vector2(from_position.x + TAVERN_MAP_NODE_SIZE.x - 18.0, from_center.y)
	var end := Vector2(to_position.x + 18.0, to_center.y)
	var points := _tavern_edge_curve_points(start, end, from_index)
	var state := _tavern_edge_state(from_index, to_index)
	var color := _tavern_edge_color(state)
	var width := GENERATED_EDGE_THICKNESS_ACTIVE if state == "selected" or state == "available" else GENERATED_EDGE_THICKNESS
	var trail_segments := _generated_edge_trail_segments(points)
	for segment in trail_segments:
		var shadow := _make_generated_edge_line(segment, Color(0.02, 0.018, 0.014, 0.58), width + 3.0)
		shadow.name = "TavernRouteEdgeShadow"
		canvas.add_child(shadow)
	for segment_index in range(trail_segments.size()):
		var segment := trail_segments[segment_index]
		var line := _make_generated_edge_line(segment, color, width)
		line.name = "TavernRouteEdge"
		line.set_meta("edge_kind", "tavern_path")
		line.set_meta("edge_visual_state", state)
		line.set_meta("from_tavern_index", from_index)
		line.set_meta("to_tavern_index", to_index)
		line.set_meta("trail_segment_count", trail_segments.size())
		line.set_meta("trail_segment_index", segment_index)
		line.set_meta("trail_dash_length", GENERATED_EDGE_TRAIL_DASH_LENGTH)
		line.set_meta("trail_gap_length", GENERATED_EDGE_TRAIL_GAP_LENGTH)
		canvas.add_child(line)


func _tavern_edge_curve_points(start: Vector2, end: Vector2, index: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var distance_x := maxf(end.x - start.x, 48.0)
	var bend := -24.0 if index % 2 == 0 else 24.0
	var control_a := start + Vector2(distance_x * 0.42, bend)
	var control_b := end - Vector2(distance_x * 0.42, bend)
	for sample_index in range(GENERATED_EDGE_SAMPLE_COUNT + 1):
		var t := float(sample_index) / float(GENERATED_EDGE_SAMPLE_COUNT)
		points.append(_cubic_bezier(start, control_a, control_b, end, t))
	return points


func _tavern_edge_state(from_index: int, to_index: int) -> String:
	var from_state := _tavern_node_state(from_index)
	var to_state := _tavern_node_state(to_index)
	if from_state == TavernNodeState.DEFEATED and to_state == TavernNodeState.DEFEATED:
		return "completed"
	if from_state == TavernNodeState.AVAILABLE or from_state == TavernNodeState.PREVIEWED:
		return "available"
	return "locked"


func _tavern_edge_color(state: String) -> Color:
	match state:
		"available":
			return Color(0.93, 0.74, 0.39, 0.86)
		"completed":
			return Color(0.56, 0.75, 0.45, 0.64)
		"selected":
			return Color(1.0, 0.90, 0.30, 0.95)
	return Color(0.46, 0.37, 0.25, 0.64)


func _can_show_contract_back_button() -> bool:
	return BuildState.can_return_to_contract_offer() and not _map_manual_open


func _refresh_contract_offer_map() -> void:
	var contract := BuildState.active_contract
	_map_phase_label.text = "Contract"
	_map_story_label.text = contract.offer_text if contract != null else "The trail out of the Tavern has gone cold."
	_map_art_box.visible = false
	_map_proceed_button.visible = false
	_map_proceed_button.tooltip_text = ""
	var button := Button.new()
	button.custom_minimum_size = MAP_NODE_SIZE
	button.text = contract.display_name if contract != null else "Unknown Contract"
	CardStyle.configure_icon_button(button, CONTRACT_ICON)
	button.disabled = contract == null
	button.pressed.connect(func(): contract_offer_pressed.emit())
	_style_map_node(button, true)
	_map_node_buttons.append(button)
	_map_nodes_box.add_child(button)


func _refresh_contract_route_map() -> void:
	_map_phase_label.text = _contract_route_title_text()
	_map_story_label.text = _contract_route_story_text()
	_map_art_box.visible = false
	_refresh_contract_route_proceed_button()
	var schematic := _make_contract_route_schematic()
	if schematic != null:
		_map_nodes_box.add_child(schematic)
		return
	var node := BuildState.current_route_node
	var choices: Array[ContractRouteNode] = []
	if BuildState.run_phase == BuildState.RunPhase.CONTRACT_ROUTE and node != null:
		choices = node.next_nodes
	if choices.is_empty():
		var button := Button.new()
		button.custom_minimum_size = MAP_NODE_SIZE
		button.text = _route_node_button_text(node) if node != null else "Route Pending"
		button.disabled = true
		_style_map_node(button, false)
		_map_node_buttons.append(button)
		_map_nodes_box.add_child(button)
		return
	for i in choices.size():
		var choice := choices[i]
		var button := Button.new()
		button.custom_minimum_size = MAP_NODE_SIZE
		button.text = _route_node_button_text(choice)
		_disable_map_entry_tooltip(button)
		var selectable := _route_node_is_selectable(choice)
		button.disabled = not selectable
		if selectable:
			button.pressed.connect(_on_contract_route_node_previewed.bind(choice))
		_style_contract_route_node(button, choice, selectable)
		_map_node_buttons.append(button)
		_map_nodes_box.add_child(button)
		if i < choices.size() - 1:
			_map_nodes_box.add_child(_make_map_connector())


func _make_contract_route_schematic() -> Control:
	if BuildState.active_contract != null and BuildState.active_contract.has_generated_route_state():
		return _make_generated_contract_route_schematic()
	var secondary := _gilded_serpent_secondary_node()
	if secondary == null or secondary.next_nodes.size() < 2:
		return null
	var door_guard := ContractRouteNode.find_by_id(secondary, "route.gilded_serpent.door_guard")
	var portly_cook := ContractRouteNode.find_by_id(secondary, "route.gilded_serpent.portly_cook")
	var sleeping := ContractRouteNode.find_by_id(secondary, "route.gilded_serpent.sleeping_henchman")
	var cloaked := ContractRouteNode.find_by_id(secondary, "route.gilded_serpent.cloaked_watchmen")
	var lazy := ContractRouteNode.find_by_id(secondary, "route.gilded_serpent.lazy_henchman")
	var patrol := ContractRouteNode.find_by_id(secondary, "route.gilded_serpent.patrolling_guard")
	var knives := ContractRouteNode.find_by_id(secondary, "route.gilded_serpent.knives")
	var vyra := ContractRouteNode.find_by_id(secondary, "route.gilded_serpent.vyra")
	if door_guard == null or portly_cook == null or sleeping == null or cloaked == null or lazy == null or patrol == null or knives == null or vyra == null:
		return null

	var canvas := Control.new()
	canvas.custom_minimum_size = HIDEOUT_CONTRACT_MAP_SIZE

	var positions := {
		door_guard: Vector2(40, 45),
		portly_cook: Vector2(40, 325),
		sleeping: Vector2(290, 0),
		cloaked: Vector2(425, 118),
		lazy: Vector2(290, 260),
		patrol: Vector2(425, 390),
		knives: Vector2(610, 246),
		vyra: Vector2(850, 244),
	}
	var nodes := [door_guard, portly_cook, sleeping, cloaked, lazy, patrol, knives, vyra]
	for node in nodes:
		for next_node in node.next_nodes:
			if positions.has(next_node):
				_add_hideout_map_edge(canvas, node, next_node, positions[node], positions[next_node])
	for node in nodes:
		_add_hideout_contract_route_button(canvas, node, positions[node])
	return canvas


func _make_generated_contract_route_schematic() -> Control:
	var root_node := BuildState.active_contract.offer_node if BuildState.active_contract != null else null
	var route_nodes := _generated_schematic_nodes(root_node)
	if route_nodes.is_empty():
		return null

	var canvas := Control.new()
	canvas.custom_minimum_size = GENERATED_CONTRACT_MAP_SIZE
	var theme := _generated_contract_map_theme()
	_apply_generated_contract_map_theme(canvas, theme)
	var positions := _generated_schematic_positions(route_nodes)
	for node in route_nodes:
		for next_node in node.next_nodes:
			if positions.has(next_node):
				_add_generated_map_edge(canvas, node, next_node, positions[node], positions[next_node], theme)
	for node in route_nodes:
		_add_contract_route_button(
			canvas,
			node,
			positions[node],
			GENERATED_CONTRACT_NODE_SIZE,
			GENERATED_MAP_TEXT_INSET,
			false
		)
	return canvas


func _generated_contract_map_theme(biome_override: String = "") -> Dictionary:
	var biome := biome_override.strip_edges()
	if biome == "":
		var contract := BuildState.active_contract
		if contract != null and contract.selected_biome != "":
			biome = contract.selected_biome
	if biome == "":
		biome = _active_contract_boss_biome()
	var source: Dictionary = GENERATED_CONTRACT_MAP_THEMES.get(biome, GENERATED_CONTRACT_MAP_THEME_FALLBACK)
	var theme := source.duplicate(true)
	theme["biome"] = biome if biome != "" else "default"
	return theme


func _apply_generated_contract_map_theme(canvas: Control, theme: Dictionary) -> void:
	canvas.set_meta("generated_map_theme", String(theme.get("id", "default")))
	canvas.set_meta("generated_map_biome", String(theme.get("biome", "default")))


func _hideout_contract_map_theme() -> Dictionary:
	var theme := GENERATED_CONTRACT_MAP_THEME_FALLBACK.duplicate(true)
	theme["id"] = "hideout"
	theme["biome"] = "Hideout"
	theme["route"] = Color(0.38, 0.35, 0.31, 0.70)
	theme["available"] = Color(0.76, 0.68, 0.42, 0.86)
	theme["selected"] = Color(0.93, 0.84, 0.46, 0.98)
	theme["completed"] = Color(0.52, 0.68, 0.45, 0.66)
	return theme


func _generated_schematic_nodes(root_node: ContractRouteNode) -> Array[ContractRouteNode]:
	return _visible_generated_schematic_nodes(_collect_generated_route_nodes(root_node))


func _visible_generated_schematic_nodes(all_nodes: Array[ContractRouteNode]) -> Array[ContractRouteNode]:
	var route_nodes: Array[ContractRouteNode] = []
	for node in all_nodes:
		if node.node_type != ContractRouteNode.NodeType.START:
			route_nodes.append(node)
	route_nodes.sort_custom(func(a: ContractRouteNode, b: ContractRouteNode) -> bool:
		if a.depth == b.depth:
			return a.lane < b.lane
		return a.depth < b.depth
	)
	return route_nodes


func _collect_generated_route_nodes(root_node: ContractRouteNode) -> Array[ContractRouteNode]:
	var out: Array[ContractRouteNode] = []
	var visited := {}
	_collect_generated_route_nodes_recursive(root_node, visited, out)
	return out


func _collect_generated_route_nodes_recursive(
	node: ContractRouteNode,
	visited: Dictionary,
	out: Array[ContractRouteNode]
) -> void:
	if node == null or visited.has(node.id):
		return
	visited[node.id] = true
	out.append(node)
	for next_node in node.next_nodes:
		_collect_generated_route_nodes_recursive(next_node, visited, out)


func _generated_schematic_positions(nodes: Array[ContractRouteNode]) -> Dictionary:
	var by_depth := {}
	var min_depth := 999999
	var max_depth := -999999
	var min_lane := 999999
	var max_lane := -999999
	for node in nodes:
		var depth: int = maxi(0, node.depth)
		min_depth = mini(min_depth, depth)
		max_depth = maxi(max_depth, depth)
		min_lane = mini(min_lane, node.lane)
		max_lane = maxi(max_lane, node.lane)
		if not by_depth.has(depth):
			by_depth[depth] = []
		(by_depth[depth] as Array).append(node)

	var positions := {}
	var depth_span: int = max(1, max_depth - min_depth)
	var lane_span: int = max(1, max_lane - min_lane)
	var left: float = GENERATED_MAP_MARGIN.x
	var right: float = GENERATED_CONTRACT_MAP_SIZE.x - GENERATED_CONTRACT_NODE_SIZE.x - GENERATED_MAP_MARGIN.x
	var top: float = GENERATED_MAP_MARGIN.y
	var bottom: float = GENERATED_CONTRACT_MAP_SIZE.y - GENERATED_CONTRACT_NODE_SIZE.y - GENERATED_MAP_MARGIN.y
	var depths: Array = by_depth.keys()
	depths.sort()
	var dense_opener_depth := int(depths[0]) if not depths.is_empty() else min_depth
	var has_dense_opener := depth_span > 1 and (by_depth.get(dense_opener_depth, []) as Array).size() >= 4
	var depth_width_signature := _generated_depth_width_signature(by_depth, depths)
	var has_dense_short_route := has_dense_opener and depth_span <= 2
	var has_dense_boss_approach := depth_width_signature == "4-2-1-1"
	for depth in depths:
		var column_nodes: Array = by_depth[depth]
		column_nodes.sort_custom(func(a: ContractRouteNode, b: ContractRouteNode) -> bool:
			if a.lane == b.lane:
				return a.id < b.id
			return a.lane < b.lane
		)
		var x := _generated_column_x(int(depth), min_depth, depth_span, left, right, has_dense_opener, has_dense_boss_approach)
		for column_index in range(column_nodes.size()):
			var node: ContractRouteNode = column_nodes[column_index]
			var lane_position := float(node.lane - min_lane) / float(lane_span)
			var y: float = lerpf(top, bottom, lane_position)
			var offset := _generated_node_visual_offset(node)
			if has_dense_opener and int(depth) == dense_opener_depth:
				offset.x = 0.0
			var stagger_x := _generated_dense_opener_stagger_x(int(depth), dense_opener_depth, column_index, column_nodes.size(), has_dense_opener, has_dense_short_route, has_dense_boss_approach)
			var node_x := clampf(x + offset.x + stagger_x, left, right)
			var node_y := clampf(y + offset.y, top, bottom)
			if node.node_type == ContractRouteNode.NodeType.BOSS:
				node_x = clampf(x + offset.x * 0.35, left, right)
			positions[node] = Vector2(node_x, node_y)
		_normalize_generated_column_positions(column_nodes, positions, top, bottom)
	return positions


func _generated_column_x(
	depth: int,
	min_depth: int,
	depth_span: int,
	left: float,
	right: float,
	has_dense_opener: bool,
	has_dense_boss_approach: bool
) -> float:
	if not has_dense_opener or depth == min_depth:
		return lerpf(left, right, float(depth - min_depth) / float(depth_span))
	var remaining_span := maxi(1, depth_span - 1)
	var reserved_width := GENERATED_DENSE_BOSS_APPROACH_RESERVED_WIDTH if has_dense_boss_approach else GENERATED_DENSE_SHORT_ROUTE_RESERVED_WIDTH if depth_span <= 2 else GENERATED_DENSE_OPENER_RESERVED_WIDTH
	var reserved_left := minf(left + reserved_width, right)
	return lerpf(reserved_left, right, float(depth - min_depth - 1) / float(remaining_span))


func _generated_dense_opener_stagger_x(
	depth: int,
	dense_opener_depth: int,
	column_index: int,
	column_size: int,
	has_dense_opener: bool,
	has_dense_short_route: bool,
	has_dense_boss_approach: bool
) -> float:
	if not has_dense_opener or depth != dense_opener_depth or column_size < 4:
		return 0.0
	var stagger_width := GENERATED_DENSE_BOSS_APPROACH_STAGGER_X if has_dense_boss_approach else GENERATED_DENSE_SHORT_ROUTE_STAGGER_X if has_dense_short_route else GENERATED_DENSE_OPENER_STAGGER_X
	return stagger_width if column_index % 2 == 1 else 0.0


func _generated_depth_width_signature(by_depth: Dictionary, depths: Array) -> String:
	var widths := PackedStringArray()
	for depth in depths:
		widths.append(str((by_depth[depth] as Array).size()))
	return "-".join(widths)


func _normalize_generated_column_positions(
	column_nodes: Array,
	positions: Dictionary,
	top: float,
	bottom: float
) -> void:
	if column_nodes.size() <= 1:
		return
	column_nodes.sort_custom(func(a: ContractRouteNode, b: ContractRouteNode) -> bool:
		return positions[a].y < positions[b].y if not is_equal_approx(positions[a].y, positions[b].y) else a.id < b.id
	)
	var minimum_step := GENERATED_CONTRACT_NODE_SIZE.y + GENERATED_MAP_NODE_GAP.y
	for i in range(1, column_nodes.size()):
		var previous: ContractRouteNode = column_nodes[i - 1]
		var current: ContractRouteNode = column_nodes[i]
		var previous_position: Vector2 = positions[previous]
		var current_position: Vector2 = positions[current]
		current_position.y = maxf(current_position.y, previous_position.y + minimum_step)
		positions[current] = current_position
	var last: ContractRouteNode = column_nodes[column_nodes.size() - 1]
	var overflow: float = positions[last].y - bottom
	if overflow > 0.0:
		for node in column_nodes:
			var adjusted: Vector2 = positions[node]
			adjusted.y -= overflow
			positions[node] = adjusted
	var first: ContractRouteNode = column_nodes[0]
	var underflow: float = top - positions[first].y
	if underflow > 0.0:
		for node in column_nodes:
			var adjusted: Vector2 = positions[node]
			adjusted.y += underflow
			positions[node] = adjusted
	for node in column_nodes:
		var clamped: Vector2 = positions[node]
		clamped.x = clampf(clamped.x, GENERATED_MAP_MARGIN.x, GENERATED_CONTRACT_MAP_SIZE.x - GENERATED_CONTRACT_NODE_SIZE.x - GENERATED_MAP_MARGIN.x)
		clamped.y = clampf(clamped.y, top, bottom)
		positions[node] = clamped


func _generated_node_visual_offset(node: ContractRouteNode) -> Vector2:
	if node == null:
		return Vector2.ZERO
	var key := node.generated_node_id if node.generated_node_id != "" else node.id
	if key == "":
		return Vector2.ZERO
	var x := _stable_signed_unit("%s:x:%d:%d" % [key, node.depth, node.lane]) * GENERATED_MAP_OFFSET_LIMIT.x
	var y := _stable_signed_unit("%s:y:%d:%d" % [key, node.depth, node.lane]) * GENERATED_MAP_OFFSET_LIMIT.y
	if node.node_type == ContractRouteNode.NodeType.BOSS:
		y *= 0.45
	return Vector2(x, y)


func _stable_signed_unit(text: String) -> float:
	var hash := 5381
	for i in range(text.length()):
		hash = int((hash * 33 + text.unicode_at(i)) % 2000003)
	return float((hash % 2001) - 1000) / 1000.0


func _add_contract_route_lines(canvas: Control, positions: Dictionary, door_guard: ContractRouteNode, portly_cook: ContractRouteNode, sleeping: ContractRouteNode, cloaked: ContractRouteNode, lazy: ContractRouteNode, patrol: ContractRouteNode, knives: ContractRouteNode, vyra: ContractRouteNode) -> void:
	var door_center := _contract_node_center(positions[door_guard])
	var cook_center := _contract_node_center(positions[portly_cook])
	var sleeping_center := _contract_node_center(positions[sleeping])
	var cloaked_center := _contract_node_center(positions[cloaked])
	var lazy_center := _contract_node_center(positions[lazy])
	var patrol_center := _contract_node_center(positions[patrol])
	var knives_center := _contract_node_center(positions[knives])
	var vyra_center := _contract_node_center(positions[vyra])
	var opener_branch_x := 195.0
	var convergence_x := 465.0

	_add_map_line(canvas, Vector2(door_center.x + CONTRACT_NODE_SIZE.x * 0.5, door_center.y), Vector2(opener_branch_x, door_center.y))
	_add_map_line(canvas, Vector2(opener_branch_x, sleeping_center.y), Vector2(opener_branch_x, cloaked_center.y))
	_add_map_line(canvas, Vector2(opener_branch_x, sleeping_center.y), Vector2(sleeping_center.x - CONTRACT_NODE_SIZE.x * 0.5, sleeping_center.y))
	_add_map_line(canvas, Vector2(opener_branch_x, cloaked_center.y), Vector2(cloaked_center.x - CONTRACT_NODE_SIZE.x * 0.5, cloaked_center.y))

	_add_map_line(canvas, Vector2(cook_center.x + CONTRACT_NODE_SIZE.x * 0.5, cook_center.y), Vector2(opener_branch_x, cook_center.y))
	_add_map_line(canvas, Vector2(opener_branch_x, lazy_center.y), Vector2(opener_branch_x, patrol_center.y))
	_add_map_line(canvas, Vector2(opener_branch_x, lazy_center.y), Vector2(lazy_center.x - CONTRACT_NODE_SIZE.x * 0.5, lazy_center.y))
	_add_map_line(canvas, Vector2(opener_branch_x, patrol_center.y), Vector2(patrol_center.x - CONTRACT_NODE_SIZE.x * 0.5, patrol_center.y))

	for center in [sleeping_center, cloaked_center, lazy_center, patrol_center]:
		_add_map_line(canvas, Vector2(center.x + CONTRACT_NODE_SIZE.x * 0.5, center.y), Vector2(convergence_x, center.y))
	_add_map_line(canvas, Vector2(convergence_x, sleeping_center.y), Vector2(convergence_x, patrol_center.y))
	_add_map_line(canvas, Vector2(convergence_x, knives_center.y), Vector2(knives_center.x - CONTRACT_NODE_SIZE.x * 0.5, knives_center.y))
	_add_map_line(canvas, Vector2(knives_center.x + CONTRACT_NODE_SIZE.x * 0.5, knives_center.y), Vector2(vyra_center.x - CONTRACT_NODE_SIZE.x * 0.5, vyra_center.y))


func _contract_node_center(top_left: Vector2) -> Vector2:
	return top_left + CONTRACT_NODE_SIZE * 0.5


func _hideout_node_center(top_left: Vector2) -> Vector2:
	return top_left + HIDEOUT_NODE_SIZE * 0.5


func _generated_node_center(top_left: Vector2) -> Vector2:
	return top_left + GENERATED_CONTRACT_NODE_SIZE * 0.5


func _tavern_node_center(top_left: Vector2) -> Vector2:
	return top_left + TAVERN_MAP_NODE_SIZE * 0.5


func _add_generated_map_edge(
	canvas: Control,
	from_node: ContractRouteNode,
	to_node: ContractRouteNode,
	from_position: Vector2,
	to_position: Vector2,
	theme: Dictionary = {}
) -> void:
	var from_center := _generated_node_center(from_position)
	var to_center := _generated_node_center(to_position)
	var start := Vector2(from_position.x + GENERATED_CONTRACT_NODE_SIZE.x, from_center.y)
	var end := Vector2(to_position.x, to_center.y)
	var points := _generated_edge_curve_points(from_node, to_node, start, end)
	var state := _generated_map_edge_state(from_node, to_node)
	var edge_theme := theme if not theme.is_empty() else _generated_contract_map_theme()
	var color := _generated_map_edge_color(state, edge_theme)
	var width := _generated_map_edge_width(state)
	_add_generated_map_curve(canvas, points, color, width, state, from_node, to_node, edge_theme)


func _add_hideout_map_edge(
	canvas: Control,
	from_node: ContractRouteNode,
	to_node: ContractRouteNode,
	from_position: Vector2,
	to_position: Vector2
) -> void:
	var start := _hideout_edge_start_point(from_node, to_node, from_position)
	var end := _hideout_edge_end_point(from_node, to_node, to_position)
	var points := _generated_edge_curve_points(from_node, to_node, start, end)
	var state := _generated_map_edge_state(from_node, to_node)
	var theme := _hideout_contract_map_theme()
	var color := _generated_map_edge_color(state, theme)
	var width := _generated_map_edge_width(state)
	_add_generated_map_curve(canvas, points, color, width, state, from_node, to_node, theme)


func _hideout_edge_start_point(from_node: ContractRouteNode, to_node: ContractRouteNode, from_position: Vector2) -> Vector2:
	var anchor := "right"
	if _hideout_route_node_matches(from_node, "patrolling_guard") and _hideout_route_node_matches(to_node, "knives"):
		anchor = "top"
	return _hideout_edge_anchor_point(from_position, anchor)


func _hideout_edge_end_point(from_node: ContractRouteNode, to_node: ContractRouteNode, to_position: Vector2) -> Vector2:
	var anchor := "left"
	if _hideout_route_node_matches(to_node, "knives"):
		if _hideout_route_node_matches(from_node, "sleeping_henchman") or _hideout_route_node_matches(from_node, "cloaked_watchmen"):
			anchor = "top"
		elif _hideout_route_node_matches(from_node, "patrolling_guard"):
			anchor = "bottom"
	return _hideout_edge_anchor_point(to_position, anchor)


func _hideout_edge_anchor_point(position: Vector2, anchor: String) -> Vector2:
	var center := _hideout_node_center(position)
	match anchor:
		"top":
			return Vector2(center.x, position.y + 8.0)
		"bottom":
			return Vector2(center.x, position.y + HIDEOUT_NODE_SIZE.y - 8.0)
		"left":
			return Vector2(position.x + 10.0, center.y)
		_:
			return Vector2(position.x + HIDEOUT_NODE_SIZE.x - 10.0, center.y)


func _hideout_route_node_matches(node: ContractRouteNode, suffix: String) -> bool:
	return node != null and node.id.ends_with(".%s" % suffix)


func _generated_edge_curve_points(
	from_node: ContractRouteNode,
	to_node: ContractRouteNode,
	start: Vector2,
	end: Vector2
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var distance_x := maxf(end.x - start.x, 48.0)
	var key := "%s>%s" % [
		from_node.generated_node_id if from_node.generated_node_id != "" else from_node.id,
		to_node.generated_node_id if to_node.generated_node_id != "" else to_node.id,
	]
	var bend := _stable_signed_unit("%s:bend" % key) * 24.0
	var control_a := start + Vector2(distance_x * 0.42, bend)
	var control_b := end - Vector2(distance_x * 0.42, bend)
	for index in range(GENERATED_EDGE_SAMPLE_COUNT + 1):
		var t := float(index) / float(GENERATED_EDGE_SAMPLE_COUNT)
		points.append(_cubic_bezier(start, control_a, control_b, end, t))
	return points


func _cubic_bezier(start: Vector2, control_a: Vector2, control_b: Vector2, end: Vector2, t: float) -> Vector2:
	var inv := 1.0 - t
	return (
		start * inv * inv * inv
		+ control_a * 3.0 * inv * inv * t
		+ control_b * 3.0 * inv * t * t
		+ end * t * t * t
	)


func _generated_map_edge_state(from_node: ContractRouteNode, to_node: ContractRouteNode) -> String:
	if _pending_contract_route_node == to_node and BuildState.current_route_node == from_node:
		return "selected"
	if _pending_contract_route_node == from_node and not _route_node_is_completed(to_node):
		return "selected"
	if _pending_contract_route_node != null:
		if _route_node_is_completed(from_node) and _route_node_is_completed(to_node):
			return "completed"
		return "locked"
	if BuildState.current_route_node == from_node and _route_node_is_selectable(to_node):
		return "available"
	if _route_node_is_completed(from_node) and _route_node_is_completed(to_node):
		return "completed"
	return "locked"


func _generated_map_edge_color(state: String, theme: Dictionary = {}) -> Color:
	var edge_theme := theme if not theme.is_empty() else GENERATED_CONTRACT_MAP_THEME_FALLBACK
	match state:
		"selected":
			return edge_theme.get("selected", GENERATED_CONTRACT_MAP_THEME_FALLBACK["selected"])
		"available":
			return edge_theme.get("available", GENERATED_CONTRACT_MAP_THEME_FALLBACK["available"])
		"completed":
			return edge_theme.get("completed", GENERATED_CONTRACT_MAP_THEME_FALLBACK["completed"])
	return edge_theme.get("route", GENERATED_CONTRACT_MAP_THEME_FALLBACK["route"])


func _generated_map_edge_width(state: String) -> float:
	return GENERATED_EDGE_THICKNESS_ACTIVE if state == "selected" or state == "available" or state == "completed" else GENERATED_EDGE_THICKNESS


func _add_generated_map_curve(
	canvas: Control,
	points: PackedVector2Array,
	color: Color,
	width: float,
	state: String,
	from_node: ContractRouteNode,
	to_node: ContractRouteNode,
	theme: Dictionary = {}
) -> void:
	var trail_segments := _generated_edge_trail_segments(points)
	for segment in trail_segments:
		var shadow := _make_generated_edge_line(segment, Color(0.02, 0.018, 0.014, 0.58), width + 3.0)
		shadow.name = "GeneratedRouteEdgeShadow"
		canvas.add_child(shadow)

	for segment_index in range(trail_segments.size()):
		var segment := trail_segments[segment_index]
		var line := _make_generated_edge_line(segment, color, width)
		line.name = "GeneratedRouteEdge"
		line.set_meta("edge_kind", "map_path")
		line.set_meta("edge_visual_state", state)
		line.set_meta("edge_theme", String(theme.get("id", "default")))
		line.set_meta("from_route_node_id", from_node.id if from_node != null else "")
		line.set_meta("to_route_node_id", to_node.id if to_node != null else "")
		line.set_meta("trail_segment_count", trail_segments.size())
		line.set_meta("trail_segment_index", segment_index)
		line.set_meta("trail_dash_length", GENERATED_EDGE_TRAIL_DASH_LENGTH)
		line.set_meta("trail_gap_length", GENERATED_EDGE_TRAIL_GAP_LENGTH)
		canvas.add_child(line)

	if state == "selected" or state == "available" or state == "completed":
		var glint_color := _theme_color(theme, "accent", CONTRACT_LINE_HIGHLIGHT_COLOR, CONTRACT_LINE_HIGHLIGHT_COLOR.a)
		for segment in trail_segments:
			var glint := _make_generated_edge_line(segment, glint_color, 1.7)
			glint.name = "GeneratedRouteEdgeHighlight"
			canvas.add_child(glint)


func _generated_edge_trail_segments(points: PackedVector2Array) -> Array[PackedVector2Array]:
	var segments: Array[PackedVector2Array] = []
	if points.size() < 2:
		return segments
	var dash_remaining := GENERATED_EDGE_TRAIL_DASH_LENGTH
	var gap_remaining := 0.0
	var drawing := true
	var current_segment := PackedVector2Array()
	current_segment.append(points[0])
	var previous := points[0]
	for point_index in range(1, points.size()):
		var target := points[point_index]
		var segment_vector := target - previous
		var segment_length := segment_vector.length()
		if segment_length <= 0.01:
			previous = target
			continue
		var direction := segment_vector / segment_length
		var consumed := 0.0
		while consumed < segment_length:
			var step_remaining := segment_length - consumed
			if drawing:
				var step := minf(dash_remaining, step_remaining)
				var next_point := previous + direction * (consumed + step)
				current_segment.append(next_point)
				dash_remaining -= step
				consumed += step
				if dash_remaining <= 0.01:
					if current_segment.size() >= 2:
						segments.append(current_segment)
					current_segment = PackedVector2Array()
					drawing = false
					gap_remaining = GENERATED_EDGE_TRAIL_GAP_LENGTH
			else:
				var step := minf(gap_remaining, step_remaining)
				consumed += step
				gap_remaining -= step
				if gap_remaining <= 0.01:
					drawing = true
					dash_remaining = GENERATED_EDGE_TRAIL_DASH_LENGTH
					current_segment = PackedVector2Array()
					current_segment.append(previous + direction * consumed)
		previous = target
	if drawing and current_segment.size() >= 2:
		segments.append(current_segment)
	return segments


func _make_generated_edge_line(points: PackedVector2Array, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.z_index = 1
	line.points = points
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	return line


func _theme_color(theme: Dictionary, key: String, fallback: Color, alpha_override: float = -1.0) -> Color:
	var color: Color = theme.get(key, fallback)
	if alpha_override >= 0.0:
		color.a = alpha_override
	return color


func _add_map_line(canvas: Control, start: Vector2, end: Vector2) -> void:
	var rail := Control.new()
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if absf(end.x - start.x) >= absf(end.y - start.y):
		rail.position = Vector2(minf(start.x, end.x), start.y - CONTRACT_LINE_THICKNESS * 0.5)
		rail.custom_minimum_size = Vector2(absf(end.x - start.x), CONTRACT_LINE_THICKNESS + 2.0)
	else:
		rail.position = Vector2(start.x - CONTRACT_LINE_THICKNESS * 0.5, minf(start.y, end.y))
		rail.custom_minimum_size = Vector2(CONTRACT_LINE_THICKNESS + 2.0, absf(end.y - start.y))
	rail.size = rail.custom_minimum_size
	canvas.add_child(rail)

	var core := ColorRect.new()
	core.color = CONTRACT_LINE_COLOR
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	core.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rail.add_child(core)

	var highlight := ColorRect.new()
	highlight.color = CONTRACT_LINE_HIGHLIGHT_COLOR
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if rail.size.x >= rail.size.y:
		highlight.size = Vector2(rail.size.x, 1)
	else:
		highlight.size = Vector2(1, rail.size.y)
	rail.add_child(highlight)


func _add_contract_route_button(
	canvas: Control,
	node: ContractRouteNode,
	position: Vector2,
	node_size: Vector2 = Vector2.ZERO,
	text_inset: Vector2 = Vector2.ZERO,
	include_actor_reward: bool = true
) -> void:
	var size := CONTRACT_NODE_SIZE if node_size == Vector2.ZERO else node_size
	var inset := Vector2(MAP_TEXT_BLOCK_LEFT, MAP_TEXT_BLOCK_TOP) if text_inset == Vector2.ZERO else text_inset
	var button := Button.new()
	button.set_meta("route_node_id", node.id)
	button.z_index = 2
	button.position = position
	button.custom_minimum_size = size
	button.size = size
	button.clip_contents = false
	var schematic_text := _contract_schematic_node_text(node)
	button.text = "" if _uses_generated_compact_preview(node) else schematic_text
	_disable_map_entry_tooltip(button)
	var selectable := _route_node_is_selectable(node)
	button.disabled = not selectable
	if selectable:
		button.pressed.connect(_on_contract_route_node_previewed.bind(node))
	_style_contract_route_node(button, node, selectable)
	if _uses_generated_compact_preview(node):
		_add_generated_biome_frame(button, node, not button.disabled)
	_add_map_text_block(
		button,
		schematic_text,
		not button.disabled,
		inset,
		8.0,
		GENERATED_MAP_TEXT_MIN_WIDTH if _uses_generated_compact_preview(node) else 0.0
	)
	if _uses_generated_compact_preview(node):
		_add_generated_reward_stack(button, node.reward, not button.disabled)
	if include_actor_reward:
		_add_map_actor_marker(button, node.monster, not button.disabled, _map_actor_visual_name(node))
		_add_reward_icon_row(button, node.reward, not button.disabled)
	_map_node_buttons.append(button)
	canvas.add_child(button)


func _add_hideout_contract_route_button(canvas: Control, node: ContractRouteNode, position: Vector2) -> void:
	var button := Button.new()
	button.set_meta("route_node_id", node.id)
	button.z_index = 2
	button.position = position
	button.custom_minimum_size = HIDEOUT_NODE_SIZE
	button.size = HIDEOUT_NODE_SIZE
	button.clip_contents = false
	button.text = ""
	_disable_map_entry_tooltip(button)
	var selectable := _route_node_is_selectable(node)
	button.disabled = not selectable
	if selectable:
		button.pressed.connect(_on_contract_route_node_previewed.bind(node))
	_style_generated_contract_route_node(button, node, selectable)
	_add_hideout_node_frame(button, String(button.get_meta("route_visual_state", "locked")))
	_add_map_text_block(
		button,
		_authored_route_compact_text(node),
		not button.disabled,
		HIDEOUT_MAP_TEXT_INSET,
		HIDEOUT_MAP_TEXT_BOTTOM_MARGIN,
		HIDEOUT_MAP_TEXT_MIN_WIDTH
	)
	_add_hideout_reward_stack(button, node.reward, not button.disabled)
	_map_node_buttons.append(button)
	canvas.add_child(button)


func _add_generated_biome_frame(button: Button, node: ContractRouteNode, _enabled: bool) -> void:
	var biome := _generated_route_node_biome(node)
	var frame_texture := _generated_biome_frame_texture(biome)
	if frame_texture == null:
		return
	var visual_state := String(button.get_meta("route_visual_state", "locked"))
	var highlight_texture_path := String(GENERATED_BIOME_HIGHLIGHT_TEXTURE_PATHS.get(biome, ""))
	var highlight_texture := _texture_from_path(highlight_texture_path)
	_add_generated_biome_glow(
		button,
		highlight_texture if highlight_texture != null else frame_texture,
		visual_state,
		highlight_texture_path
	)
	var frame := TextureRect.new()
	frame.name = "GeneratedBiomeFrame"
	frame.z_index = 3
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.texture = frame_texture
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.custom_minimum_size = GENERATED_BIOME_FRAME_VISUAL_SIZE
	frame.size = GENERATED_BIOME_FRAME_VISUAL_SIZE
	frame.position = (button.custom_minimum_size - GENERATED_BIOME_FRAME_VISUAL_SIZE) * 0.5
	frame.modulate = _generated_biome_frame_modulate(visual_state)
	frame.set_meta("biome", biome)
	frame.set_meta("texture_path", String(GENERATED_BIOME_FRAME_TEXTURE_PATHS.get(biome, "")))
	frame.set_meta("layout_size", button.custom_minimum_size)
	button.add_child(frame)


func _add_hideout_node_frame(button: Button, visual_state: String) -> void:
	var frame_texture := _texture_from_path(HIDEOUT_NODE_FRAME_TEXTURE_PATH)
	if frame_texture == null:
		return
	var highlight_texture := _texture_from_path(HIDEOUT_NODE_HIGHLIGHT_TEXTURE_PATH)
	_add_hideout_node_glow(
		button,
		highlight_texture if highlight_texture != null else frame_texture,
		visual_state,
		HIDEOUT_NODE_HIGHLIGHT_TEXTURE_PATH
	)
	var frame := TextureRect.new()
	frame.name = "HideoutBiomeFrame"
	frame.z_index = 3
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.texture = frame_texture
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.custom_minimum_size = HIDEOUT_NODE_FRAME_VISUAL_SIZE
	frame.size = HIDEOUT_NODE_FRAME_VISUAL_SIZE
	frame.position = (button.custom_minimum_size - HIDEOUT_NODE_FRAME_VISUAL_SIZE) * 0.5
	frame.modulate = _generated_biome_frame_modulate(visual_state)
	frame.set_meta("texture_path", HIDEOUT_NODE_FRAME_TEXTURE_PATH)
	frame.set_meta("layout_size", button.custom_minimum_size)
	button.add_child(frame)


func _add_generated_biome_glow(button: Button, highlight_texture: Texture2D, visual_state: String, texture_path: String = "") -> void:
	var glow_color := _generated_biome_glow_color(visual_state)
	if glow_color.a <= 0.0 or highlight_texture == null:
		return
	var glow := TextureRect.new()
	glow.name = "GeneratedBiomeGlow"
	glow.z_index = 2
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.texture = highlight_texture
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.custom_minimum_size = GENERATED_BIOME_FRAME_VISUAL_SIZE + GENERATED_BIOME_GLOW_PADDING
	glow.size = GENERATED_BIOME_FRAME_VISUAL_SIZE + GENERATED_BIOME_GLOW_PADDING
	glow.position = (button.custom_minimum_size - glow.size) * 0.5
	glow.modulate = glow_color
	glow.material = _make_map_frame_outline_material()
	glow.set_meta("route_visual_state", visual_state)
	glow.set_meta("highlight_style", "gray_silhouette_texture")
	glow.set_meta("texture_path", texture_path)
	button.add_child(glow)
	if visual_state == "available":
		var tween := glow.create_tween()
		tween.set_loops()
		tween.tween_property(glow, "modulate:a", minf(glow_color.a + 0.22, 0.86), AVAILABLE_PULSE_DURATION_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(glow, "modulate:a", glow_color.a, AVAILABLE_PULSE_DURATION_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _add_hideout_node_glow(button: Button, highlight_texture: Texture2D, visual_state: String, texture_path: String = "") -> void:
	var glow_color := _generated_biome_glow_color(visual_state)
	if glow_color.a <= 0.0 or highlight_texture == null:
		return
	var glow := TextureRect.new()
	glow.name = "HideoutBiomeGlow"
	glow.z_index = 2
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.texture = highlight_texture
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.custom_minimum_size = HIDEOUT_NODE_FRAME_VISUAL_SIZE + HIDEOUT_NODE_GLOW_PADDING
	glow.size = HIDEOUT_NODE_FRAME_VISUAL_SIZE + HIDEOUT_NODE_GLOW_PADDING
	glow.position = (button.custom_minimum_size - glow.size) * 0.5
	glow.modulate = glow_color
	glow.material = _make_map_frame_outline_material()
	glow.set_meta("route_visual_state", visual_state)
	glow.set_meta("highlight_style", "gray_silhouette_texture")
	glow.set_meta("texture_path", texture_path)
	button.add_child(glow)
	if visual_state == "available":
		var tween := glow.create_tween()
		tween.set_loops()
		tween.tween_property(glow, "modulate:a", minf(glow_color.a + 0.22, 0.86), AVAILABLE_PULSE_DURATION_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(glow, "modulate:a", glow_color.a, AVAILABLE_PULSE_DURATION_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _add_tavern_node_frame(button: Button, state: int) -> void:
	var frame_texture := _texture_from_path(TAVERN_NODE_FRAME_TEXTURE_PATH)
	if frame_texture == null:
		return
	var visual_state := _tavern_visual_state_name(state)
	var highlight_texture := _texture_from_path(TAVERN_NODE_HIGHLIGHT_TEXTURE_PATH)
	_add_tavern_node_glow(
		button,
		highlight_texture if highlight_texture != null else frame_texture,
		visual_state,
		TAVERN_NODE_HIGHLIGHT_TEXTURE_PATH
	)
	var frame := TextureRect.new()
	frame.name = "TavernBiomeFrame"
	frame.z_index = 3
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.texture = frame_texture
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.custom_minimum_size = TAVERN_NODE_FRAME_VISUAL_SIZE
	frame.size = TAVERN_NODE_FRAME_VISUAL_SIZE
	frame.position = (button.custom_minimum_size - TAVERN_NODE_FRAME_VISUAL_SIZE) * 0.5
	frame.modulate = _generated_biome_frame_modulate(visual_state)
	frame.set_meta("texture_path", TAVERN_NODE_FRAME_TEXTURE_PATH)
	frame.set_meta("layout_size", button.custom_minimum_size)
	button.add_child(frame)


func _add_tavern_node_glow(button: Button, highlight_texture: Texture2D, visual_state: String, texture_path: String = "") -> void:
	var glow_color := _generated_biome_glow_color(visual_state)
	if glow_color.a <= 0.0 or highlight_texture == null:
		return
	var glow := TextureRect.new()
	glow.name = "TavernBiomeGlow"
	glow.z_index = 2
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.texture = highlight_texture
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.custom_minimum_size = TAVERN_NODE_FRAME_VISUAL_SIZE + TAVERN_NODE_GLOW_PADDING
	glow.size = TAVERN_NODE_FRAME_VISUAL_SIZE + TAVERN_NODE_GLOW_PADDING
	glow.position = (button.custom_minimum_size - glow.size) * 0.5
	glow.modulate = glow_color
	glow.material = _make_map_frame_outline_material()
	glow.set_meta("route_visual_state", visual_state)
	glow.set_meta("highlight_style", "gray_silhouette_texture")
	glow.set_meta("texture_path", texture_path)
	button.add_child(glow)
	if visual_state == "available":
		var tween := glow.create_tween()
		tween.set_loops()
		tween.tween_property(glow, "modulate:a", minf(glow_color.a + 0.22, 0.86), AVAILABLE_PULSE_DURATION_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(glow, "modulate:a", glow_color.a, AVAILABLE_PULSE_DURATION_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _make_map_frame_outline_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = MAP_FRAME_OUTLINE_SHADER
	return material


func _generated_biome_glow_color(visual_state: String) -> Color:
	match visual_state:
		"selected":
			return Color(1.0, 0.90, 0.30, 0.95)
		"available":
			return Color(0.94, 0.70, 0.30, 0.58)
		"completed":
			return Color(0.55, 0.86, 0.46, 0.30)
	return Color(0, 0, 0, 0)


func _generated_biome_frame_modulate(visual_state: String) -> Color:
	if visual_state == "locked":
		return Color(0.72, 0.72, 0.72, 0.92)
	return Color.WHITE


func _generated_route_node_biome(node: ContractRouteNode) -> String:
	if node != null:
		var preview_biome := String(node.route_preview.get("biome", "")).strip_edges()
		if preview_biome != "":
			return preview_biome
		if node.biome != "":
			return node.biome
	var theme := _generated_contract_map_theme()
	return String(theme.get("biome", ""))


func _generated_biome_frame_texture(biome: String) -> Texture2D:
	var texture_path := String(GENERATED_BIOME_FRAME_TEXTURE_PATHS.get(biome, ""))
	if texture_path == "":
		return null
	if not _biome_frame_texture_cache.has(texture_path):
		_biome_frame_texture_cache[texture_path] = load(texture_path) as Texture2D
	return _biome_frame_texture_cache[texture_path] as Texture2D


func _contract_schematic_node_text(node: ContractRouteNode) -> String:
	var preview := _route_node_compact_preview(node)
	if not preview.is_empty():
		return _route_compact_preview_text_for_node(node, preview)
	var lines: PackedStringArray = []
	lines.append(node.display_name)
	for reward_line in _contract_schematic_reward_lines(node):
		lines.append(reward_line)
	return "\n".join(lines)


func _uses_generated_compact_preview(node: ContractRouteNode) -> bool:
	return node != null and node.has_generated_state() and not node.route_preview.is_empty()


func _contract_schematic_reward_lines(node: ContractRouteNode) -> PackedStringArray:
	var lines: PackedStringArray = []
	if node == null or node.reward == null:
		return lines
	var reward_label := _contract_reward_display(node)
	if reward_label != "":
		lines.append("Reward: %s" % reward_label)
	return lines


func _contract_reward_display(node: ContractRouteNode) -> String:
	if node == null or node.reward == null:
		return ""
	if node.reward.gear_choice_rewards.size() > 0:
		return _tier_name_for_reward_gear(node.reward.gear_choice_rewards[0])
	if node.reward.generated_gear_choice_count > 0:
		return GearGenerator.tier_name(node.reward.generated_gear_tier)
	if node.reward_quality_label == "Contract Victory":
		return node.reward_quality_label
	return ""


func _tier_name_for_reward_gear(gear: GearItem) -> String:
	if gear == null:
		return "Gear"
	return GearGenerator.tier_name(gear.tier)


func _route_node_is_selectable(node: ContractRouteNode) -> bool:
	return BuildState.can_commit_contract_route_node(node)


func _route_node_is_selected(node: ContractRouteNode) -> bool:
	return _pending_contract_route_node == node or BuildState.current_route_node == node


func _route_node_is_completed(node: ContractRouteNode) -> bool:
	return node != null and BuildState.claimed_route_reward_ids.has(node.id)


func _gilded_serpent_secondary_node() -> ContractRouteNode:
	if BuildState.active_contract == null or BuildState.active_contract.offer_node == null:
		return null
	if BuildState.active_contract.offer_node.next_nodes.is_empty():
		return null
	return BuildState.active_contract.offer_node.next_nodes[0]


func _make_tavern_map_node_button(index: int) -> Button:
	var state := _tavern_node_state(index)
	var encounter := RunFlow.load_encounter(index)
	var button := Button.new()
	button.name = "TavernNode%d" % index
	button.custom_minimum_size = TAVERN_MAP_NODE_SIZE
	button.clip_contents = false
	button.text = encounter.monster.display_name if state != TavernNodeState.LOCKED and encounter != null else "Unknown"
	button.disabled = not _tavern_node_is_clickable(state)
	_disable_map_entry_tooltip(button)
	button.pressed.connect(_on_tavern_node_previewed.bind(index))
	_style_tavern_map_node(button, state)
	_add_tavern_node_frame(button, state)
	_add_map_text_block(
		button,
		_tavern_map_node_text(encounter, state),
		state != TavernNodeState.LOCKED,
		TAVERN_MAP_TEXT_INSET,
		TAVERN_MAP_TEXT_BOTTOM_MARGIN,
		TAVERN_MAP_TEXT_MIN_WIDTH
	)
	if state != TavernNodeState.LOCKED and encounter != null:
		_add_tavern_reward_stack(button, encounter.reward, not button.disabled)
	if state == TavernNodeState.DEFEATED:
		_add_tavern_defeated_marker(button)
	return button


func _tavern_map_node_text(encounter, state: int) -> String:
	if state == TavernNodeState.LOCKED or encounter == null or encounter.monster == null:
		return _tavern_name_line("Unknown", UIColors.TEXT_DISABLED)
	var lines := PackedStringArray()
	lines.append(_tavern_name_line(encounter.monster.display_name, UIColors.TEXT_POISON))
	var tags := _tavern_archetype_tags(encounter.monster)
	if not tags.is_empty():
		lines.append(_route_preview_tag_line(tags))
	return "\n".join(lines)


func _tavern_name_line(enemy_name: String, color: Color) -> String:
	return "[center][font_size=%d][color=%s][b]%s[/b][/color][/font_size][/center]" % [
		GENERATED_ENEMY_NAME_FONT_SIZE,
		_color_to_html(color),
		_escape_bbcode(enemy_name),
	]


func _tavern_archetype_tags(monster: Monster) -> Array:
	var tags := []
	if monster == null:
		return tags
	if monster.armor > 0:
		tags.append("armored")
	if monster.poison_resistance > 0.0:
		tags.append("resistant")
	return tags


func _tavern_node_state(index: int) -> int:
	var current_index := BuildState.current_encounter_index
	if index < current_index:
		return TavernNodeState.DEFEATED
	if not BuildState.is_tavern_planning() or index > current_index:
		return TavernNodeState.LOCKED
	if _tavern_preview_index == index or not BuildState.needs_tavern_map_choice():
		return TavernNodeState.PREVIEWED
	return TavernNodeState.AVAILABLE


func _tavern_node_is_clickable(state: int) -> bool:
	return BuildState.needs_tavern_map_choice() and (state == TavernNodeState.AVAILABLE or state == TavernNodeState.PREVIEWED)


func _tavern_node_tooltip(state: int, encounter) -> String:
	match state:
		TavernNodeState.DEFEATED:
			if encounter != null and encounter.monster != null:
				return "%s defeated." % encounter.monster.display_name
			return "Defeated."
		TavernNodeState.AVAILABLE:
			return "Click to preview this fight, then press Proceed."
		TavernNodeState.PREVIEWED:
			return "Ready. Press Proceed to commit this fight."
	return "Defeat the previous fight to reveal this one."


func _disable_map_entry_tooltip(button: Button) -> void:
	# Keep the tooltip builder functions nearby; map-entry tooltips are only
	# disabled for the current cleaner card treatment.
	button.tooltip_text = ""


func _make_map_connector() -> Control:
	var connector := Control.new()
	connector.custom_minimum_size = Vector2(80, 6)
	connector.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	connector.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var core := ColorRect.new()
	core.color = CONTRACT_LINE_COLOR
	core.custom_minimum_size = Vector2(80, 6)
	core.size = core.custom_minimum_size
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	connector.add_child(core)

	var highlight := ColorRect.new()
	highlight.color = CONTRACT_LINE_HIGHLIGHT_COLOR
	highlight.custom_minimum_size = Vector2(80, 1)
	highlight.size = highlight.custom_minimum_size
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	connector.add_child(highlight)
	return connector


func _style_map_node(button: Button, is_current: bool) -> void:
	var fill := UIColors.MAP_NODE_CURRENT if is_current else UIColors.MAP_NODE_INACTIVE
	var border := CardStyle.ACCENT_COLOR if is_current else UIColors.STRUCTURE_LINE_LIGHT
	_apply_map_node_styles(button, fill, border, 5 if is_current else 2, is_current, not is_current)


func _style_tavern_map_node(button: Button, state: int) -> void:
	_apply_generated_map_node_style(button)
	button.set_meta("tavern_visual_state", _tavern_visual_state_name(state))


func _tavern_visual_state_name(state: int) -> String:
	match state:
		TavernNodeState.DEFEATED:
			return "completed"
		TavernNodeState.AVAILABLE:
			return "available"
		TavernNodeState.PREVIEWED:
			return "selected"
	return "locked"


func _style_contract_route_node(button: Button, node: ContractRouteNode, selectable: bool) -> void:
	if _uses_generated_compact_preview(node):
		_style_generated_contract_route_node(button, node, selectable)
		return
	var is_selected := _route_node_is_selected(node)
	if selectable and not is_selected:
		_style_available_choice_node(button)
		_add_available_pulse(button, "ContractAvailablePulse")
	elif is_selected:
		_style_selected_choice_node(button)
	else:
		_style_map_node(button, false)


func _style_generated_contract_route_node(button: Button, node: ContractRouteNode, selectable: bool) -> void:
	var visual_state := _generated_route_node_visual_state(node, selectable)
	_apply_generated_map_node_style(button)
	button.set_meta("route_visual_state", visual_state)
	button.set_meta("route_role", _generated_route_node_role_name(node))


func _apply_generated_map_node_style(button: Button) -> void:
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = UIColors.TRANSPARENT
		style.border_color = UIColors.TRANSPARENT
		style.set_border_width_all(0)
		style.content_margin_top = 0
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.content_margin_bottom = 0
		button.add_theme_stylebox_override(state_name, style)
	button.add_theme_color_override("font_color", UIColors.TRANSPARENT)
	button.add_theme_color_override("font_disabled_color", UIColors.TRANSPARENT)
	button.add_theme_font_override("font", DATA_BUTTON_FONT)
	button.add_theme_font_size_override("font_size", 18)


func _generated_route_node_visual_state(node: ContractRouteNode, selectable: bool) -> String:
	if _route_node_is_selected(node):
		return "selected"
	if selectable:
		return "available"
	if _route_node_is_completed(node):
		return "completed"
	return "locked"


func _generated_route_node_role_name(node: ContractRouteNode) -> String:
	if node == null:
		return "normal"
	match node.node_type:
		ContractRouteNode.NodeType.CAPTAIN:
			return "captain"
		ContractRouteNode.NodeType.ELITE:
			return "elite"
		ContractRouteNode.NodeType.BOSS:
			return "boss"
	return "normal"


func _generated_route_node_role_color(node: ContractRouteNode) -> Color:
	match _generated_route_node_role_name(node):
		"captain":
			return UIColors.TIER_MASTER
		"elite":
			return UIColors.TIER_LEGENDARY
		"boss":
			return UIColors.TEXT_WARNING
	return UIColors.TEXT_POISON


func _style_available_choice_node(button: Button) -> void:
	_apply_map_node_styles(button, UIColors.PANEL, UIColors.STRUCTURE_LINE_LIGHT, 4, false, false)


func _style_selected_choice_node(button: Button) -> void:
	_apply_map_node_styles(button, UIColors.MAP_NODE_CURRENT, CardStyle.ACCENT_COLOR, 5, true, false)


func _apply_map_node_styles(button: Button, fill: Color, border: Color, border_width: int, selected: bool, recessed: bool) -> void:
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var state_fill := fill
		var state_border := border
		var state_width := border_width
		if not button.disabled and (state_name == "hover" or state_name == "focus"):
			state_border = UIColors.PANEL_EDGE_LIGHT
			state_width = maxi(border_width, 5)
		elif not button.disabled and state_name == "pressed":
			state_fill = fill.darkened(0.14)
		var style := CardStyle.make_slot_stylebox(state_fill, state_border, state_width, state_name)
		style.set_corner_radius_all(8)
		style.content_margin_top = 12
		if selected:
			style.shadow_color = UIColors.BUTTON_INNER_GLOW
			style.shadow_size = 7
		elif recessed:
			style.shadow_size = 1
			style.shadow_offset = Vector2(0, 1)
		button.add_theme_stylebox_override(state_name, style)
	button.add_theme_color_override("font_color", UIColors.TEXT_NORMAL)
	button.add_theme_color_override("font_disabled_color", UIColors.TEXT_DISABLED)
	button.add_theme_font_override("font", DATA_BUTTON_FONT)
	button.add_theme_font_size_override("font_size", 18)


func _add_map_text_block(
	button: Button,
	text: String,
	enabled: bool,
	inset: Vector2 = Vector2(MAP_TEXT_BLOCK_LEFT, MAP_TEXT_BLOCK_TOP),
	bottom_margin: float = MAP_TEXT_BLOCK_BOTTOM,
	minimum_width: float = 0.0
) -> void:
	_hide_button_text_for_composed_map_node(button)
	var uses_rich_text := _map_text_uses_bbcode(text)
	var label: Control = RichTextLabel.new() if uses_rich_text else Label.new()
	label.name = "MapTextBlock"
	label.z_index = 7
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if label is RichTextLabel:
		var rich_label := label as RichTextLabel
		rich_label.bbcode_enabled = true
		rich_label.text = text
		rich_label.fit_content = false
		rich_label.scroll_active = false
		rich_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rich_label.add_theme_font_override("normal_font", DATA_BUTTON_FONT)
		rich_label.add_theme_font_override("bold_font", DATA_BUTTON_FONT)
		rich_label.add_theme_font_size_override("normal_font_size", 18)
		rich_label.add_theme_color_override("default_color", UIColors.TEXT_NORMAL if enabled else UIColors.TEXT_DISABLED)
		rich_label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE_STRONG)
		rich_label.add_theme_constant_override("outline_size", 2)
	else:
		var plain_label := label as Label
		plain_label.text = text
		plain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		plain_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		plain_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		plain_label.add_theme_font_override("font", DATA_BUTTON_FONT)
		plain_label.add_theme_font_size_override("font_size", 18)
		plain_label.add_theme_color_override("font_color", UIColors.TEXT_NORMAL if enabled else UIColors.TEXT_DISABLED)
		plain_label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE_STRONG)
		plain_label.add_theme_constant_override("outline_size", 2)
	var calculated_width := maxf(button.custom_minimum_size.x - inset.x - 8.0, 1.0)
	var label_width := maxf(calculated_width, minimum_width)
	label.position = Vector2(
		(button.custom_minimum_size.x - label_width) * 0.5 if minimum_width > calculated_width else inset.x,
		inset.y
	)
	label.size = Vector2(
		label_width,
		maxf(button.custom_minimum_size.y - inset.y - bottom_margin, 1.0)
	)
	button.add_child(label)


func _map_text_uses_bbcode(text: String) -> bool:
	return text.contains("[font_size=") or text.contains("[color=") or text.contains("[b]")


func _hide_button_text_for_composed_map_node(button: Button) -> void:
	for color_name in [
		"font_color",
		"font_hover_color",
		"font_pressed_color",
		"font_focus_color",
		"font_hover_pressed_color",
		"font_disabled_color",
		"font_outline_color",
	]:
		button.add_theme_color_override(color_name, UIColors.TRANSPARENT)


func _add_reward_icon_row(button: Button, reward: EncounterReward, enabled: bool) -> void:
	if reward == null:
		return
	var gear_tier := _map_reward_gear_tier(reward)
	if reward.gold_amount <= 0 and reward.talent_points <= 0 and gear_tier < 0:
		return
	var row := HBoxContainer.new()
	row.name = "MapRewardIconRow"
	row.z_index = 9
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	var reward_piece_count := _map_reward_piece_count(reward, gear_tier)
	row.offset_left = -12 if reward_piece_count >= 3 else 10
	row.offset_top = -28
	row.offset_right = -10
	row.offset_bottom = -2
	row.modulate.a = 1.0 if enabled else 0.58
	if reward.talent_points > 0:
		_add_map_reward_piece(row, CardStyle.talent_point_icon(), "x%d" % reward.talent_points)
	if gear_tier >= 0:
		_add_map_reward_piece(
			row,
			_gear_drop_icon_for_tier(gear_tier),
			"x1",
			"MapGearRewardIcon",
			gear_tier
		)
	if reward.gold_amount > 0:
		_add_map_reward_piece(row, GOLD_ICON, "%dg" % reward.gold_amount)
	button.add_child(row)
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := button.get_theme_stylebox(state_name)
		if style is StyleBoxFlat:
			style.content_margin_bottom = 42


func _add_map_reward_piece(row: HBoxContainer, texture: Texture2D, text: String, icon_name: String = "Icon", gear_tier: int = -1) -> void:
	var backing := PanelContainer.new()
	backing.name = "MapRewardBacking"
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backing_style := StyleBoxFlat.new()
	backing_style.bg_color = Color(0.035, 0.026, 0.020, 0.86)
	backing_style.border_color = Color(0.90, 0.78, 0.52, 0.48)
	backing_style.set_border_width_all(1)
	backing_style.set_corner_radius_all(4)
	backing.add_theme_stylebox_override("panel", backing_style)
	row.add_child(backing)

	var content := HBoxContainer.new()
	content.name = "MapRewardBackingContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 2)
	backing.add_child(content)

	var icon := CardStyle.make_pixel_icon(texture, MAP_REWARD_ICON_SIZE)
	icon.name = icon_name
	if gear_tier >= 0:
		icon.set_meta("gear_tier", gear_tier)
		icon.set_meta("gear_rarity_color", _tier_color_for_map_reward(gear_tier))
	content.add_child(icon)
	var label := Label.new()
	label.name = "MapRewardAmount"
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", DATA_BUTTON_FONT)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", UIColors.TEXT_NORMAL)
	label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE_STRONG)
	label.add_theme_constant_override("outline_size", 3)
	content.add_child(label)


func _add_generated_reward_stack(button: Button, reward: EncounterReward, enabled: bool) -> void:
	var entries := _generated_reward_icon_entries(reward)
	if entries.is_empty():
		return
	var stack := VBoxContainer.new()
	stack.name = "GeneratedRewardStack"
	stack.z_index = 8
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", -1)
	stack.position = Vector2((button.custom_minimum_size.x - GENERATED_REWARD_STACK_SIZE.x) * 0.5, GENERATED_REWARD_STACK_OFFSET_Y)
	stack.size = GENERATED_REWARD_STACK_SIZE
	stack.modulate.a = 1.0 if enabled else 0.72
	button.add_child(stack)
	for entry in entries:
		stack.add_child(_make_generated_reward_row(entry))


func _add_tavern_reward_stack(button: Button, reward: EncounterReward, enabled: bool) -> void:
	var entries := _generated_reward_icon_entries(reward)
	if entries.is_empty():
		return
	var stack := VBoxContainer.new()
	stack.name = "TavernRewardStack"
	stack.z_index = 8
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", -1)
	stack.position = Vector2((button.custom_minimum_size.x - TAVERN_REWARD_STACK_SIZE.x) * 0.5, TAVERN_REWARD_STACK_OFFSET_Y)
	stack.size = TAVERN_REWARD_STACK_SIZE
	stack.modulate.a = 1.0 if enabled else 0.72
	button.add_child(stack)
	for entry in entries:
		stack.add_child(_make_generated_reward_row(entry, TAVERN_REWARD_STACK_SIZE.x))


func _add_hideout_reward_stack(button: Button, reward: EncounterReward, enabled: bool) -> void:
	var entries := _generated_reward_icon_entries(reward)
	if entries.is_empty():
		return
	var stack := VBoxContainer.new()
	stack.name = "HideoutRewardStack"
	stack.z_index = 8
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", -2)
	stack.position = Vector2((button.custom_minimum_size.x - HIDEOUT_REWARD_STACK_SIZE.x) * 0.5, HIDEOUT_REWARD_STACK_OFFSET_Y)
	stack.size = HIDEOUT_REWARD_STACK_SIZE
	stack.modulate.a = 1.0 if enabled else 0.72
	button.add_child(stack)
	for entry in entries:
		stack.add_child(_make_generated_reward_row(entry, HIDEOUT_REWARD_STACK_SIZE.x))


func _generated_reward_icon_entries(reward: EncounterReward) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if reward == null:
		return entries
	var gear_tier := _map_reward_gear_tier(reward)
	if gear_tier >= 0:
		var gear_count := maxi(1, reward.generated_gear_choice_count)
		entries.append({
			"icon": _gear_drop_icon_for_tier(gear_tier),
			"text": "x %d" % gear_count,
			"color": _tier_color_for_map_reward(gear_tier),
			"name": "GeneratedGearReward",
			"gear_tier": gear_tier,
		})
	if reward.talent_points > 0:
		entries.append({
			"icon": CardStyle.talent_point_icon(),
			"text": "x %d" % reward.talent_points,
			"color": UIColors.TEXT_POISON,
			"name": "GeneratedTalentReward",
		})
	if reward.gold_amount > 0:
		entries.append({
			"icon": GOLD_ICON,
			"text": "%dg" % reward.gold_amount,
			"color": UIColors.TEXT_GOLD,
			"name": "GeneratedGoldReward",
		})
	return entries


func _make_generated_reward_row(entry: Dictionary, row_width: float = GENERATED_REWARD_STACK_SIZE.x) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = String(entry.get("name", "GeneratedReward"))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3)
	row.custom_minimum_size = Vector2(row_width, GENERATED_REWARD_PILL_MIN_SIZE.y)

	var backing := PanelContainer.new()
	backing.name = "GeneratedRewardIconBacking"
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.custom_minimum_size = GENERATED_REWARD_PILL_MIN_SIZE
	var backing_style := StyleBoxFlat.new()
	backing_style.bg_color = Color(0.035, 0.026, 0.020, 0.82)
	backing_style.border_color = Color(0.90, 0.78, 0.52, 0.42)
	backing_style.set_border_width_all(1)
	backing_style.set_corner_radius_all(4)
	backing.add_theme_stylebox_override("panel", backing_style)

	var backing_content := HBoxContainer.new()
	backing_content.name = "GeneratedRewardBackingContent"
	backing_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing_content.alignment = BoxContainer.ALIGNMENT_CENTER
	backing_content.add_theme_constant_override("separation", 3)
	backing.add_child(backing_content)

	var icon := CardStyle.make_pixel_icon(entry.get("icon", null), GENERATED_REWARD_ICON_SIZE)
	icon.name = "GeneratedRewardIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gear_tier := int(entry.get("gear_tier", -1))
	if gear_tier >= 0:
		icon.set_meta("gear_tier", gear_tier)
		icon.set_meta("gear_rarity_color", _tier_color_for_map_reward(gear_tier))
	backing_content.add_child(icon)

	var label := Label.new()
	label.name = "GeneratedRewardAmount"
	label.text = String(entry.get("text", ""))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", DATA_BUTTON_FONT)
	label.add_theme_font_size_override("font_size", GENERATED_REWARD_AMOUNT_FONT_SIZE)
	label.add_theme_color_override("font_color", entry.get("color", UIColors.TEXT_NORMAL))
	label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE_STRONG)
	label.add_theme_constant_override("outline_size", 3)
	backing_content.add_child(label)
	row.add_child(backing)
	return row


func _map_reward_gear_tier(reward: EncounterReward) -> int:
	if reward.gear_choice_rewards.size() > 0:
		var best := -1
		for gear in reward.gear_choice_rewards:
			if gear != null:
				best = maxi(best, gear.tier)
		return best
	if reward.legendary_choice_count > 0 and not reward.legendary_choice_pool.is_empty():
		return GearItem.Tier.LEGENDARY
	if reward.generated_gear_choice_count > 0:
		return reward.generated_gear_tier
	if reward.fixed_gear_rewards.size() > 0:
		var best_fixed := -1
		for gear in reward.fixed_gear_rewards:
			if gear != null:
				best_fixed = maxi(best_fixed, gear.tier)
		return best_fixed
	return -1


func _map_reward_piece_count(reward: EncounterReward, gear_tier: int) -> int:
	var count := 0
	if reward.talent_points > 0:
		count += 1
	if gear_tier >= 0:
		count += 1
	if reward.gold_amount > 0:
		count += 1
	return count


func _gear_drop_icon_for_tier(tier: int) -> Texture2D:
	var normalized_tier := tier if GEAR_DROP_ICON_PATHS.has(tier) else GearItem.Tier.BASIC
	if _gear_drop_icon_cache.has(normalized_tier):
		return _gear_drop_icon_cache[normalized_tier]
	var texture := load(GEAR_DROP_ICON_PATHS[normalized_tier]) as Texture2D
	if texture == null:
		return null
	texture.resource_name = GEAR_DROP_ICON_PATHS[normalized_tier]
	_gear_drop_icon_cache[normalized_tier] = texture
	return texture


func _tier_color_for_map_reward(tier: int) -> Color:
	return GearGenerator.tier_color(tier)


func _add_map_actor_marker(button: Button, monster: Monster, enabled: bool, visual_name: String = "") -> void:
	var texture := _map_actor_texture(monster, visual_name)
	if texture == null:
		return
	var visual_key := _map_actor_visual_key(monster, visual_name)
	var actor := TextureRect.new()
	actor.name = "MapActorMarker"
	actor.z_index = 8
	actor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actor.texture = texture
	actor.custom_minimum_size = MAP_ACTOR_MARKER_SIZE
	actor.size = MAP_ACTOR_MARKER_SIZE
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	actor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	actor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	actor.flip_h = bool(CombatStage.STATIC_ENEMY_FLIP_H_BY_VISUAL_KEY.get(visual_key, false))
	actor.position = MAP_ACTOR_MARKER_OFFSET
	actor.modulate.a = 1.0 if enabled else 0.55
	button.add_child(actor)


## Every marker for a given visual_key resolves to the same path/region, so
## the constructed texture is cached instead of reloading + re-wrapping a new
## AtlasTexture per marker on every map refresh (mirrors _gear_drop_icon_cache
## above).
func _map_actor_texture(monster: Monster, visual_name: String = "") -> Texture2D:
	var visual_key := _map_actor_visual_key(monster, visual_name)
	if visual_key == "":
		return null
	if _map_actor_texture_cache.has(visual_key):
		return _map_actor_texture_cache[visual_key]
	var animation_paths: Dictionary = CombatStage.ENEMY_ANIMATION_PATHS.get(visual_key, {})
	var path: String = animation_paths.get("idle", "")
	if path == "":
		return null
	var texture: Texture2D
	if CombatStage.STATIC_ENEMY_VISUAL_KEYS.has(visual_key):
		texture = _texture_from_path(path)
	else:
		var animation_regions: Dictionary = CombatStage.ENEMY_ANIMATION_REGIONS.get(visual_key, {})
		var region: Rect2 = animation_regions.get("idle", Rect2(Vector2.ZERO, Vector2(CombatStage.PEASANT_FRAME_SIZE)))
		texture = _atlas_texture_from_path(path, region)
	if texture != null:
		_map_actor_texture_cache[visual_key] = texture
	return texture


func _map_actor_visual_key(monster: Monster, visual_name: String = "") -> String:
	if monster == null:
		return ""
	var lookup_name := visual_name if visual_name != "" else monster.display_name
	return CombatStage.enemy_visual_key_for(lookup_name)


func _texture_from_path(path: String) -> Texture2D:
	if path == "":
		return null
	var texture := load(path) as Texture2D
	if texture != null:
		return texture
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _map_actor_visual_name(node: ContractRouteNode) -> String:
	if node == null or node.monster == null:
		return ""
	var biome := _generated_route_node_biome(node)
	var biome_name := "%s %s" % [biome, node.monster.display_name]
	if CombatStage.enemy_visual_key_for(biome_name) != "":
		return biome_name
	return node.monster.display_name


func _atlas_texture_from_path(path: String, region: Rect2) -> Texture2D:
	if path == "":
		return null
	var source := load(path) as Texture2D
	if source == null:
		var image := Image.new()
		if image.load(path) != OK:
			return null
		source = ImageTexture.create_from_image(image)
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = region
	return atlas


func _add_tavern_defeated_marker(button: Button) -> void:
	var marker := Label.new()
	marker.name = "TavernDefeatedMarker"
	marker.text = "X"
	marker.z_index = 20
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker.add_theme_font_size_override("font_size", 70)
	marker.add_theme_color_override("font_color", UIColors.TEXT_WARNING)
	marker.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE_STRONG)
	marker.add_theme_constant_override("outline_size", 5)
	marker.position = Vector2((button.custom_minimum_size.x - MAP_ACTOR_MARKER_SIZE.x) * 0.5, 68.0)
	marker.size = MAP_ACTOR_MARKER_SIZE
	if button.find_child("TavernBiomeFrame", true, false) != null:
		marker.position = Vector2((button.custom_minimum_size.x - MAP_ACTOR_MARKER_SIZE.x) * 0.5, 82.0)
	button.add_child(marker)


func _add_available_pulse(button: Button, marker_name: String) -> void:
	var pulse := PanelContainer.new()
	pulse.name = marker_name
	pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pulse.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pulse_style := StyleBoxFlat.new()
	pulse_style.bg_color = UIColors.TRANSPARENT
	pulse_style.border_color = UIColors.TEXT_GOLD
	pulse_style.set_border_width_all(5)
	pulse_style.set_corner_radius_all(8)
	pulse.add_theme_stylebox_override("panel", pulse_style)
	button.add_child(pulse)

	pulse.modulate.a = 0.35
	var tween := pulse.create_tween()
	tween.set_loops()
	tween.tween_property(pulse, "modulate:a", 1.0, AVAILABLE_PULSE_DURATION_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(pulse, "modulate:a", 0.35, AVAILABLE_PULSE_DURATION_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
## Before any node is (re-)previewed, _tavern_pre_choice_story_text() sets
## the scene; clicking the current node previews its
## TAVERN_ENCOUNTER_FLAVOR_TEXT without committing (see
## _on_tavern_node_previewed()); Proceed then commits it, after which this
## falls to the same "marked" line it always has.
func _tavern_story_text() -> String:
	var encounter := BuildState.current_encounter()
	if encounter == null:
		return "The Tavern is quiet for the moment."
	if BuildState.needs_tavern_map_choice():
		if _tavern_preview_index == BuildState.current_encounter_index:
			return TAVERN_ENCOUNTER_FLAVOR_TEXT.get(
				encounter.monster.display_name, "A stranger's business becomes yours."
			)
		return _tavern_pre_choice_story_text()
	return FLOW_TEXT.marked_target_story(encounter.monster.display_name)


## The very first Tavern choice (nothing defeated yet) sets the scene with
## TAVERN_INTRO_TEXT; every later choice instead shows the encounter just
## defeated's TAVERN_VICTORY_TEXT, so returning to the map after a win
## reflects the new state of the story instead of replaying the intro.
func _tavern_pre_choice_story_text() -> String:
	if BuildState.current_encounter_index == 0:
		return TAVERN_INTRO_TEXT
	var previous_encounter := RunFlow.load_encounter(BuildState.current_encounter_index - 1)
	if previous_encounter == null or previous_encounter.monster == null:
		return TAVERN_INTRO_TEXT
	return TAVERN_VICTORY_TEXT.get(previous_encounter.monster.display_name, TAVERN_INTRO_TEXT)


## P2:R7:T6: when the player is choosing between exactly two branches, this
## appends a data-derived tradeoff sentence (see _route_tradeoff_text())
## naming the harder branch and comparing reward tier, so the choice isn't
## blind. Applies at every branch point, not only the opener choice -- the
## base line no longer says "first route" since this story text is reused
## for every later fork too (Door Guard's/Portly Cook's own next-node choice).
func _contract_route_story_text() -> String:
	var node := BuildState.current_route_node
	if node == null:
		return "The route has not been charted yet."
	if BuildState.is_contract_fight_active():
		return FLOW_TEXT.marked_target_story(node.display_name)
	if _pending_contract_route_node != null and _route_node_is_selectable(_pending_contract_route_node):
		return _selected_contract_route_story_text(_pending_contract_route_node)
	var authored_before := _before_selection_contract_route_story_text(node)
	if authored_before != "":
		return authored_before
	if BuildState.active_contract != null and BuildState.active_contract.has_generated_route_state():
		return _generated_contract_route_flavor_text()
	var base := "Choose your next route into The Gilded Serpent. Enemy pressure and reward quality matter from here."
	if node.next_nodes.size() == 2:
		var tradeoff := _route_tradeoff_text(node.next_nodes[0], node.next_nodes[1])
		if tradeoff != "":
			return "%s %s" % [base, tradeoff]
	return base


func _contract_route_title_text() -> String:
	var boss_name := _active_contract_boss_name()
	if boss_name != "":
		return _defeat_title_for_boss(boss_name)
	return BuildState.active_contract.display_name if BuildState.active_contract != null else "Contract Route"


func _defeat_title_for_boss(boss_name: String) -> String:
	var clean_name := boss_name.strip_edges()
	if clean_name.begins_with("The "):
		return "Defeat %s" % clean_name
	if clean_name.find(",") >= 0:
		return "Defeat %s" % clean_name
	return "Defeat the %s" % clean_name


func _generated_contract_route_flavor_text() -> String:
	var contract := BuildState.active_contract
	var boss_name := _active_contract_boss_name()
	var biome := contract.selected_biome if contract != null and contract.selected_biome != "" else _active_contract_boss_biome()
	if biome == "Swamp" and boss_name.contains("Hydra"):
		return "Many heads, one payday. Try not to become soup."
	var options: Array = GENERATED_CONTRACT_ROUTE_FLAVOR_BY_BIOME.get(biome, [])
	if options.is_empty():
		return "A dangerous target, a suspiciously cheerful payday, and Ghit pretending those are unrelated."
	var basis := "%s:%s:%s" % [biome, boss_name, contract.generated_route_id if contract != null else ""]
	var index := absi(basis.hash()) % options.size()
	return String(options[index])


func _active_contract_boss_name() -> String:
	var contract := BuildState.active_contract
	if contract == null:
		return ""
	if contract.target_display_name != "":
		return contract.target_display_name
	var boss := _active_contract_boss_node()
	if boss != null:
		if boss.route_preview.has("monster_name"):
			var preview_name := String(boss.route_preview.get("monster_name", ""))
			if preview_name != "":
				return preview_name
		if boss.display_name != "":
			return boss.display_name
	return ""


func _active_contract_boss_biome() -> String:
	var boss := _active_contract_boss_node()
	if boss != null:
		if boss.biome != "":
			return boss.biome
		return String(boss.route_preview.get("biome", ""))
	return ""


func _active_contract_boss_node() -> ContractRouteNode:
	if BuildState.active_contract == null:
		return null
	for route_node in _collect_generated_route_nodes(BuildState.active_contract.offer_node):
		if route_node.node_type == ContractRouteNode.NodeType.BOSS:
			return route_node
	return null


func _selected_contract_route_story_text(node: ContractRouteNode) -> String:
	if node.selected_text != "":
		return node.selected_text
	return FLOW_TEXT.pending_route_status(node.display_name)


func _before_selection_contract_route_story_text(node: ContractRouteNode) -> String:
	if node.next_nodes.size() == 1 and node.next_nodes[0].before_selection_text != "":
		return node.next_nodes[0].before_selection_text
	if node.before_selection_text != "":
		return node.before_selection_text
	return ""


## Relative pressure score for a route branch, used only to rank two
## branches against each other (not shown as an absolute number) --
## higher armor/resistance reads as a harder branch, from the same
## real Monster fields enemy_panel.gd's _build_pressure_text() (P2:R7:T5)
## already reads.
func _route_pressure_score(node: ContractRouteNode) -> float:
	if node == null or node.monster == null:
		return 0.0
	return float(node.monster.armor) + node.monster.poison_resistance * 200.0


## Reward tier rank for a route branch's reward, covering both the
## authored gear_choice_rewards path (Knives' Legendary pair) and the
## generated_gear_tier path every other route reward uses. Returns -1 when
## the node has no gear reward to rank (e.g. Vyra's gold-only reward).
func _route_reward_tier_rank(node: ContractRouteNode) -> int:
	if node == null or node.reward == null:
		return -1
	if node.reward.gear_choice_rewards.size() > 0:
		var best := -1
		for gear in node.reward.gear_choice_rewards:
			if gear != null:
				best = maxi(best, gear.tier)
		return best
	if node.reward.generated_gear_choice_count > 0:
		return node.reward.generated_gear_tier
	return -1


## Data-derived tradeoff sentence for a pair of route branches, comparing
## real Monster pressure and reward tier rather than authored per-node
## flavor text -- so a newly authored branch pair reads correctly with zero
## additional authoring, matching the same discipline as T5's
## _build_pressure_text(). Pure ContractRouteNode -> String, no BuildState
## writes.
func _route_tradeoff_text(node_a: ContractRouteNode, node_b: ContractRouteNode) -> String:
	if node_a == null or node_b == null:
		return ""
	var pressure_a := _route_pressure_score(node_a)
	var pressure_b := _route_pressure_score(node_b)
	var pressure_line: String
	if is_equal_approx(pressure_a, pressure_b):
		pressure_line = "%s and %s carry similar pressure" % [node_a.display_name, node_b.display_name]
	elif pressure_a > pressure_b:
		pressure_line = "%s is the harder branch" % node_a.display_name
	else:
		pressure_line = "%s is the harder branch" % node_b.display_name
	var tier_a := _route_reward_tier_rank(node_a)
	var tier_b := _route_reward_tier_rank(node_b)
	var tier_a_name: String = GearGenerator.tier_name(tier_a) if tier_a >= 0 else "no gear"
	var tier_b_name: String = GearGenerator.tier_name(tier_b) if tier_b >= 0 else "no gear"
	return "%s. %s reward: %s -- %s reward: %s." % [pressure_line, node_a.display_name, tier_a_name, node_b.display_name, tier_b_name]


func _route_node_button_text(node: ContractRouteNode) -> String:
	if node == null:
		return "Route Pending"
	var preview := _route_node_compact_preview(node)
	if not preview.is_empty():
		return _route_compact_preview_text_for_node(node, preview)
	var lines: PackedStringArray = []
	lines.append(node.display_name)
	if node.monster != null:
		lines.append("HP %d | Armor %d" % [node.monster.hp, node.monster.armor])
		lines.append("Resist %.0f%% | %.0fs" % [node.monster.poison_resistance * 100.0, node.duration_ms / 1000.0])
	if node.difficulty_label != "":
		lines.append(node.difficulty_label)
	if node.reward_quality_label != "":
		lines.append(node.reward_quality_label)
	return "\n".join(lines)


func _authored_route_compact_text(node: ContractRouteNode) -> String:
	if node == null:
		return _route_preview_monster_name_line(null, "Unknown")
	var lines := PackedStringArray()
	lines.append(_route_preview_monster_name_line(node, node.display_name))
	var tags := _authored_route_archetype_tags(node)
	if not tags.is_empty():
		lines.append(_route_preview_tag_line(tags))
	return "\n".join(lines)


func _authored_route_archetype_tags(node: ContractRouteNode) -> Array:
	var tags := []
	if node == null or node.monster == null:
		return tags
	if node.monster.armor > 0:
		tags.append("armored")
	if node.monster.poison_resistance > 0.0:
		tags.append("resistant")
	return tags


func _route_node_compact_preview(node: ContractRouteNode) -> Dictionary:
	if node == null or node.route_preview.is_empty():
		return {}
	var preview := {
		"biome": String(node.route_preview.get("biome", "")),
		"monster_name": String(node.route_preview.get("monster_name", node.display_name)),
		"encounter_level": String(node.route_preview.get("encounter_level", _route_node_encounter_level(node))),
		"archetype_tags": _route_preview_tags(node.route_preview.get("archetype_tags", [])),
		"modifier_label": String(node.route_preview.get("modifier_label", "")),
		"elite_variant_label": String(node.route_preview.get("elite_variant_label", "")),
		"boss_variant_label": String(node.route_preview.get("boss_variant_label", "")),
	}
	if preview["monster_name"] == "":
		preview["monster_name"] = node.display_name
	if preview["encounter_level"] == "":
		preview["encounter_level"] = _route_node_encounter_level(node)
	return preview


func _route_compact_preview_text_for_node(node: ContractRouteNode, preview: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append(_route_compact_preview_text(node, preview))
	return "\n".join(lines)


func _route_compact_preview_text(node: ContractRouteNode, preview: Dictionary) -> String:
	var lines := PackedStringArray()
	var monster_name := String(preview.get("monster_name", "Unknown"))
	var archetype_tags: Array = preview.get("archetype_tags", [])
	lines.append(_route_preview_monster_name_line(node, monster_name))
	if not archetype_tags.is_empty():
		lines.append(_route_preview_tag_line(archetype_tags))
	return "\n".join(lines)


func _route_preview_identity_line(preview: Dictionary) -> String:
	var labels := PackedStringArray()
	for key in ["modifier_label", "elite_variant_label", "boss_variant_label"]:
		var label := _escape_bbcode(String(preview.get(key, ""))).strip_edges()
		if label != "":
			labels.append(label)
	return " / ".join(Array(labels))


func _route_preview_monster_name_line(node: ContractRouteNode, monster_name: String) -> String:
	var clean_name := _escape_bbcode(monster_name)
	var name_color := UIColors.TEXT_POISON
	if node != null:
		match node.node_type:
			ContractRouteNode.NodeType.CAPTAIN:
				name_color = UIColors.TIER_MASTER
			ContractRouteNode.NodeType.ELITE:
				name_color = UIColors.TIER_LEGENDARY
			ContractRouteNode.NodeType.BOSS:
				name_color = UIColors.TEXT_WARNING
			_:
				name_color = UIColors.TEXT_POISON
	if clean_name == "":
		clean_name = "Unknown"
	return "[center][font_size=%d][color=%s][b]%s[/b][/color][/font_size][/center]" % [
		GENERATED_ENEMY_NAME_FONT_SIZE,
		_color_to_html(name_color),
		clean_name,
	]


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "").replace("]", "")


func _color_to_html(color: Color) -> String:
	return "#%s" % color.to_html(false)


func _route_preview_tags(value: Variant) -> Array:
	var tags := []
	if value is PackedStringArray:
		for tag in value:
			tags.append(String(tag))
	elif value is Array:
		for tag in value:
			tags.append(String(tag))
	return tags


func _route_preview_tag_line(tags: Array) -> String:
	var parts := PackedStringArray()
	for tag in tags:
		parts.append(String(tag))
	return "[center][color=%s][b]%s[/b][/color][/center]" % [
		_color_to_html(UIColors.TEXT_GOLD),
		_escape_bbcode(" + ".join(parts)),
	]


func _route_node_encounter_level(node: ContractRouteNode) -> String:
	match node.node_type:
		ContractRouteNode.NodeType.BOSS:
			return "Boss"
		ContractRouteNode.NodeType.ELITE:
			return "Elite"
		ContractRouteNode.NodeType.CAPTAIN:
			return "Captain"
	return "Normal"


func _route_node_tooltip(node: ContractRouteNode) -> String:
	var parts: PackedStringArray = []
	parts.append(node.summary_text)
	if node.difficulty_label != "":
		parts.append("Difficulty: %s" % node.difficulty_label)
	var reward_label := _contract_reward_display(node)
	if reward_label != "":
		parts.append("Reward: %s" % reward_label)
	return "\n".join(parts)


## Opens the map. `manual_open` marks a player-initiated open via the Map
## button (as opposed to the flow pushing the map up at a decision point) --
## it's what keeps Close Map available even while a choice is still pending.
func show_map(manual_open: bool = false) -> void:
	_map_manual_open = manual_open
	refresh()
	visible = true


## Hides the map and clears the manual-open flag. combat_screen.gd calls this
## after a choice commits, so the next automatic open starts from a clean
## state rather than inheriting the previous manual-open exemption.
func close() -> void:
	visible = false
	_map_manual_open = false
	_pending_contract_route_node = null


## Clears the pending Tavern preview. combat_screen.gd calls this once a
## Tavern choice actually commits, since the preview no longer applies.
func clear_tavern_preview() -> void:
	_tavern_preview_index = -1
	_pending_contract_route_node = null


func _map_requires_choice() -> bool:
	return (
		BuildState.needs_tavern_map_choice()
		or BuildState.run_phase == BuildState.RunPhase.CONTRACT_OFFER
		or BuildState.run_phase == BuildState.RunPhase.CONTRACT_ROUTE
	)


## Clicking a Tavern node only previews its flavor text (_tavern_story_text())
## and enables the Proceed button -- it never commits the choice itself.
## Proceed is what commits, restoring a two-step "read the flavor, then
## commit" flow. Purely local state, so it stays in this scene.
func _on_tavern_node_previewed(index: int) -> void:
	if index != BuildState.current_encounter_index or not BuildState.needs_tavern_map_choice():
		return
	_tavern_preview_index = -1 if _tavern_preview_index == index else index
	refresh()


func _on_contract_route_node_previewed(node: ContractRouteNode) -> void:
	if not _route_node_is_selectable(node):
		return
	_pending_contract_route_node = null if _pending_contract_route_node == node else node
	refresh()


func _on_map_proceed_pressed() -> void:
	if BuildState.needs_tavern_map_choice() and _tavern_preview_index == BuildState.current_encounter_index:
		tavern_proceed_pressed.emit()
		return
	if _pending_contract_route_node != null and _route_node_is_selectable(_pending_contract_route_node):
		var selected := _pending_contract_route_node
		_pending_contract_route_node = null
		route_node_pressed.emit(selected)
		return
	CardStyle.pulse_blocked_control(_map_proceed_button)


func _refresh_contract_route_proceed_button() -> void:
	var has_pending_choices := (
		BuildState.run_phase == BuildState.RunPhase.CONTRACT_ROUTE
		and BuildState.current_route_node != null
		and not BuildState.current_route_node.next_nodes.is_empty()
	)
	_map_proceed_button.visible = has_pending_choices
	_map_proceed_button.disabled = _pending_contract_route_node == null
	_map_proceed_button.text = FLOW_TEXT.ACTION_PROCEED
	_map_proceed_button.tooltip_text = (
		FLOW_TEXT.TOOLTIP_ROUTE_NEEDS_SELECTION
		if _pending_contract_route_node == null
		else FLOW_TEXT.tooltip_mark_route(_pending_contract_route_node.display_name)
	)


func _sync_pending_contract_route_node() -> void:
	if _pending_contract_route_node == null:
		return
	if not _route_node_is_selectable(_pending_contract_route_node):
		_pending_contract_route_node = null
