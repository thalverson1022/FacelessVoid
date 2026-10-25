extends Control
## Ghit Gudd's Contract Window: a multi-step conversation that introduces and
## commits The Gilded Serpent contract. Extracted from combat_screen.gd's
## inline overlay builder (docs/Phase_3_Technical_Debt_Architecture_Cleanup.md
## Phase 3) -- gates a real decision with no defined "cancel" behavior, so it
## stays locked (no dismiss on outside click), matching its behavior before
## extraction.
##
## Visually mirrors the shop overlay's layout (a portrait box beside the
## text/action content) since this is explicitly meant to grow into the same
## kind of hub the shop already is, just for choosing contracts instead of
## gear, per the user's stated plan.
##
## This scene owns the conversation's step state and advances itself through
## the two purely-narrative transitions (GREETING -> PITCH, CONTRACT_CHOICE ->
## VYRA_DETAIL). It deliberately does NOT own the two steps with cross-cutting
## consequences: `accept_requested` and `route_requested` hand those back to
## combat_screen.gd, which owns BuildState mutation, the secondary-subclass
## overlay, the enemy HUD, the route map, and autosaving.
##
## Two semantic signals rather than one `action_pressed(step)` signal is
## deliberate: the `Step` enum then never has to cross the scene boundary.
## This script can't declare a `class_name` (it references the BuildState
## autoload, and global-class scripts compile during Godot's project scan
## before autoloads register -- "Identifier not found: BuildState"), and
## preloading the *script* from combat_screen.gd to reach the enum forces that
## same premature compile. Preloading the `.tscn` is fine, so the enum simply
## stays private to this file.

## PITCH's action button: the real commit point. combat_screen.gd runs
## BuildState.accept_contract_offer() and only hides this window if it
## succeeds -- on failure the conversation correctly stays on PITCH.
signal accept_requested(contract_id: String)

## VYRA_DETAIL's action button: the player has accepted; combat_screen.gd
## reveals the route map.
signal route_requested

enum Step { GREETING, PITCH, OFFER_CHOICE, CONTRACT_CHOICE, VYRA_DETAIL }

const FLOW_TEXT := preload("res://scripts/ui/adventure_flow_text.gd")
const CARD_TITLE_FONT_SIZE := 20
const CONTRACT_CHOICE_CARD_WIDTH := 340
const CONTRACT_CHOICE_CARD_HEIGHT := 110
const CONTRACT_HEADER_ICON_SIZE := Vector2(36, 36)
const CONTRACT_OPTION_ICON_SIZE := Vector2(64, 64)
const CONTRACT_REWARD_ICON_SIZE := Vector2(20, 20)
const CONTRACT_REWARD_PILL_MIN_SIZE := Vector2(70, 28)
const CONTRACT_OPTION_BOSS_FONT_SIZE := 24
const CONTRACT_OPTION_DETAIL_FONT_SIZE := 18
const CONTRACT_CHOICE_PULSE_DURATION_SEC := 0.72
const TOP_CHROME_CLICKTHROUGH_CLEARANCE := 88.0
const CONTRACT_PORTRAIT_TEXTURE := preload("res://assets/backgrounds/Ghit_Guud.jpg")
const CONTRACT_ICON := preload("res://assets/ui/icons/contract.png")
const GOLD_ICON := preload("res://assets/ui/icons/gold.png")
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

## Ghit Gudd's introduction sequence (P2:R7 story pass) -- replaces the old
## single-click "Map"-styled Contract Offer overlay with a multi-step
## conversation, restoring a Phase 1-style narrative beat around accepting The
## Gilded Serpent contract. Verbatim user-authored copy (including its
## typos/inconsistent spelling of the broker's name -- not this codebase's to
## silently correct).
const CONTRACT_GREETING_TEXT := "Calm my friend. My name is Ghit Gudd. I am just a humble local... businessman. You are quite handy. You dispatched one of my best with such ease. I am always looking for useful individuals like yourself. How would you like to make a little coin?"
const CONTRACT_PITCH_TEXT := "There are many creatures in the surrounding area that provide valuable... materials. I would go harvest them myself, but I am better with a pen than I am with a sword. I can provide you with the location of these creatures, and if you return with their hides, I will pay you handsomely."
const CONTRACT_OFFER_PROMPT_TEXT := ""
## The post-subclass-choice step -- a single option today, but user-stated to
## grow into a real multi-contract hub later, hence a dedicated options row
## rather than a single fixed button.
const CONTRACT_CHOICE_PROMPT_TEXT := ""
const CONTRACT_VYRA_NAME := "Vyra, the Leader of the Gilded Fang"
const CONTRACT_VYRA_DETAIL_TEXT := "Vyra is the leader of a rival gang. Ghet wants you to take her out so he can expand his business. She is hold up in her hideout at the edge of town. Ghet tells you that there are two ways in: through the front door and through the back door."
## The real route node backing the Vyra contract card -- read for its authored
## gold reward (see _contract_choice_reward_text()).
const VYRA_ROUTE_NODE_ID := "route.gilded_serpent.vyra"

var _contract_step: Step = Step.GREETING
var _contract_title_icon: TextureRect
var _contract_title_label: Label
var _contract_body_label: Label
var _contract_options_box: VBoxContainer
var _contract_footer_spacer: Control
var _contract_action_button: Button
var _selected_contract_id := ""
var _gear_drop_icon_cache: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var panel := CardStyle.build_modal_panel(self, false)
	var backdrop := get_child(0) as Control
	if backdrop != null:
		backdrop.offset_top = TOP_CHROME_CLICKTHROUGH_CLEARANCE
	panel.add_theme_stylebox_override("panel", CardStyle.make_stylebox())

	var content := HBoxContainer.new()
	content.custom_minimum_size = Vector2(700, 420)
	content.add_theme_constant_override("separation", 16)
	panel.add_child(content)

	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(260, 0)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var portrait_style := CardStyle.make_stylebox(8)
	portrait_style.bg_color = UIColors.PANEL_DEEP
	portrait.add_theme_stylebox_override("panel", portrait_style)
	content.add_child(portrait)

	var portrait_image := TextureRect.new()
	portrait_image.texture = CONTRACT_PORTRAIT_TEXTURE
	portrait_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.add_child(portrait_image)

	var contract_content := VBoxContainer.new()
	contract_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contract_content.add_theme_constant_override("separation", 14)
	content.add_child(contract_content)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	contract_content.add_child(title_row)

	_contract_title_icon = CardStyle.make_pixel_icon(CONTRACT_ICON, CONTRACT_HEADER_ICON_SIZE)
	_contract_title_icon.name = "ContractTitleIcon"
	title_row.add_child(_contract_title_icon)

	var title := Label.new()
	_contract_title_label = title
	title.text = "Contract"
	title.theme_type_variation = &"PanelHeader"
	title.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", CardStyle.ACCENT_COLOR)
	title_row.add_child(title)

	_contract_body_label = Label.new()
	_contract_body_label.name = "ContractBodyLabel"
	_contract_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contract_content.add_child(_contract_body_label)

	# Empty/hidden except during Step.CONTRACT_CHOICE -- one option today
	# (Vyra), stacked vertically so future contracts naturally form a list.
	_contract_options_box = VBoxContainer.new()
	_contract_options_box.name = "ContractOptionsBox"
	_contract_options_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_contract_options_box.add_theme_constant_override("separation", 12)
	contract_content.add_child(_contract_options_box)

	_contract_footer_spacer = Control.new()
	_contract_footer_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contract_content.add_child(_contract_footer_spacer)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_END
	contract_content.add_child(button_row)

	_contract_action_button = Button.new()
	_contract_action_button.name = "ContractActionButton"
	_contract_action_button.pressed.connect(_on_action_button_pressed)
	button_row.add_child(_contract_action_button)


## Opens the window at Ghit Gudd's greeting -- the start of the conversation.
func show_greeting() -> void:
	_selected_contract_id = ""
	_show_step(Step.GREETING)


## Opens the window at the post-subclass-choice contract picker. Reached after
## the secondary-tree choice, not by advancing from PITCH.
func show_contract_choice() -> void:
	_selected_contract_id = ""
	_show_step(Step.CONTRACT_CHOICE)


func show_offer_choice() -> void:
	_selected_contract_id = ""
	_show_step(Step.OFFER_CHOICE)


func _show_step(step: Step) -> void:
	_contract_step = step
	refresh()
	visible = true


## Drives the Contract Window through Ghit Gudd's introduction -- see the
## CONTRACT_* text constants above for the exact copy at each step.
func refresh() -> void:
	for child in _contract_options_box.get_children():
		child.queue_free()
	_contract_options_box.visible = false
	_contract_action_button.visible = true
	_contract_action_button.disabled = false
	_contract_body_label.visible = true
	_contract_title_label.text = "Contract"
	if _contract_title_icon != null:
		_contract_title_icon.visible = true
	match _contract_step:
		Step.GREETING:
			_contract_body_label.text = CONTRACT_GREETING_TEXT
			_contract_action_button.text = "Hear Him Out"
			CardStyle.configure_icon_button(_contract_action_button, CONTRACT_ICON)
		Step.PITCH:
			_contract_body_label.text = CONTRACT_PITCH_TEXT
			_contract_action_button.text = "Accept Contract Work"
			CardStyle.configure_icon_button(_contract_action_button, CONTRACT_ICON)
		Step.OFFER_CHOICE:
			_contract_title_label.text = "Choose a Contract"
			if _contract_title_icon != null:
				_contract_title_icon.visible = false
			_contract_body_label.text = CONTRACT_OFFER_PROMPT_TEXT
			_contract_body_label.visible = false
			_contract_action_button.text = "Preview"
			CardStyle.configure_icon_button(_contract_action_button, CONTRACT_ICON)
			_contract_action_button.disabled = _selected_contract_id == ""
			_contract_options_box.visible = true
			for contract in BuildState.pending_contract_offers:
				_contract_options_box.add_child(_build_pending_contract_offer_card(contract))
		Step.CONTRACT_CHOICE:
			_contract_title_label.text = "Choose a Contract"
			if _contract_title_icon != null:
				_contract_title_icon.visible = false
			_contract_body_label.text = CONTRACT_CHOICE_PROMPT_TEXT
			_contract_body_label.visible = false
			_contract_action_button.text = "Preview"
			CardStyle.configure_icon_button(_contract_action_button, CONTRACT_ICON)
			_contract_action_button.disabled = _selected_contract_id == ""
			_contract_options_box.visible = true
			var vyra_node: ContractRouteNode = null
			if BuildState.active_contract != null:
				vyra_node = ContractRouteNode.find_by_id(BuildState.active_contract.offer_node, VYRA_ROUTE_NODE_ID)
			_contract_options_box.add_child(_build_contract_choice_card(VYRA_ROUTE_NODE_ID, CONTRACT_VYRA_NAME, vyra_node))
		Step.VYRA_DETAIL:
			_contract_body_label.text = CONTRACT_VYRA_DETAIL_TEXT
			_contract_action_button.text = "Accept"
			CardStyle.configure_icon_button(_contract_action_button, CONTRACT_ICON)
	if BuildState.is_test_mode:
		_contract_body_label.visible = true
		_contract_body_label.text = "Test Mode — Bladedancer core only: Whetstone, Rending Slash and Fancy Footwork. Other talents, Dance and secondary trees are unavailable. Rewards continue normally; points beyond this core remain unspent. Session progress is not saved."


## A larger, toggleable rectangle (not a plain button) naming the contract and
## its boss, location, and final-fight gold reward -- selecting one only
## enables the bottom Proceed button rather than committing immediately,
## since this step is meant to grow into a real multi-contract picker later.
func _build_contract_choice_card(contract_id: String, display_name: String, node: ContractRouteNode) -> Button:
	var card := Button.new()
	card.name = "VyraContractButton"
	card.custom_minimum_size = Vector2(CONTRACT_CHOICE_CARD_WIDTH, CONTRACT_CHOICE_CARD_HEIGHT)
	card.text = ""
	_add_contract_offer_card_content(
		card,
		_contract_boss_name_from_display(display_name),
		_contract_biome_label_from_contract(BuildState.active_contract),
		node.reward if node != null else null
	)
	card.pressed.connect(_on_contract_choice_pressed.bind(contract_id))
	if _selected_contract_id == contract_id:
		_style_contract_choice_selected(card)
	else:
		_style_contract_choice_available(card)
		_add_contract_choice_pulse(card)
	return card


func _build_pending_contract_offer_card(contract: ContractDef) -> Button:
	var contract_id := BuildState.contract_offer_key(contract)
	var card := Button.new()
	card.name = _contract_offer_button_name(contract)
	card.custom_minimum_size = Vector2(CONTRACT_CHOICE_CARD_WIDTH, CONTRACT_CHOICE_CARD_HEIGHT)
	card.text = ""
	_add_contract_offer_card_content(
		card,
		_contract_offer_boss_name(contract),
		_contract_biome_label_from_contract(contract),
		_contract_offer_reward(contract)
	)
	card.pressed.connect(_on_contract_choice_pressed.bind(contract_id))
	if _selected_contract_id == contract_id:
		_style_contract_choice_selected(card)
	else:
		_style_contract_choice_available(card)
		_add_contract_choice_pulse(card)
	return card


func _contract_offer_button_name(contract: ContractDef) -> String:
	if contract == null or not contract.has_generated_route_state():
		return "AuthoredContractOfferButton"
	return "GeneratedContractOfferButton"


func _contract_offer_card_text(contract: ContractDef) -> String:
	if contract == null:
		return "Unknown Contract\nLocation: Unknown\nReward: unknown"
	var lines := PackedStringArray()
	lines.append(_contract_offer_boss_name(contract))
	lines.append(_contract_biome_label_from_contract(contract))
	lines.append(_contract_reward_summary_text(_contract_offer_reward(contract)))
	return "\n".join(lines)


func _add_contract_offer_card_content(card: Button, boss_name: String, location_text: String, reward: EncounterReward) -> void:
	var row := HBoxContainer.new()
	row.name = "ContractOfferContent"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 26.0
	row.offset_top = 12.0
	row.offset_right = -18.0
	row.offset_bottom = -12.0
	row.add_theme_constant_override("separation", 18)
	card.add_child(row)

	row.add_child(CardStyle.make_pixel_icon(CONTRACT_ICON, CONTRACT_OPTION_ICON_SIZE))

	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)

	text_box.add_child(_make_contract_offer_label("ContractBossNameLabel", boss_name, CONTRACT_OPTION_BOSS_FONT_SIZE, CardStyle.ACCENT_COLOR))
	text_box.add_child(_make_contract_offer_label("ContractLocationLabel", location_text, CONTRACT_OPTION_DETAIL_FONT_SIZE, UIColors.TEXT_NORMAL))
	text_box.add_child(_make_contract_reward_stack(reward))


func _make_contract_offer_label(label_name: String, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", CardStyle.DATA_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE_STRONG)
	label.add_theme_constant_override("outline_size", 2)
	return label


func _contract_offer_boss_name(contract: ContractDef) -> String:
	if contract == null:
		return "Unknown Boss"
	if contract.target_display_name != "":
		return contract.target_display_name
	if contract.target_monster != null and contract.target_monster.display_name != "":
		return contract.target_monster.display_name
	return "Unknown Boss"


func _contract_biome_label_from_contract(contract: ContractDef) -> String:
	var biome := "Unknown"
	if contract != null:
		if contract.selected_biome != "":
			biome = contract.selected_biome
		elif contract.display_name.ends_with(" Contract"):
			biome = contract.display_name.trim_suffix(" Contract")
	return "Location: %s" % biome


func _contract_offer_reward(contract: ContractDef) -> EncounterReward:
	if contract == null:
		return null
	if contract.has_generated_route_state():
		var boss := _contract_offer_boss_node(contract)
		return boss.reward if boss != null else null
	if contract.offer_node != null:
		var vyra_node := ContractRouteNode.find_by_id(contract.offer_node, VYRA_ROUTE_NODE_ID)
		return vyra_node.reward if vyra_node != null else null
	return null


func _make_contract_reward_stack(reward: EncounterReward) -> HBoxContainer:
	var stack := HBoxContainer.new()
	stack.name = "ContractRewardStack"
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.alignment = BoxContainer.ALIGNMENT_BEGIN
	stack.add_theme_constant_override("separation", 5)
	for entry in _contract_reward_icon_entries(reward):
		stack.add_child(_make_contract_reward_row(entry))
	if stack.get_child_count() == 0:
		stack.add_child(_make_contract_offer_label("ContractRewardEmptyLabel", "Reward unknown", CONTRACT_OPTION_DETAIL_FONT_SIZE, UIColors.TEXT_DISABLED))
	return stack


func _contract_reward_icon_entries(reward: EncounterReward) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if reward == null:
		return entries
	var gear_tier := _contract_reward_gear_tier(reward)
	if gear_tier >= 0:
		entries.append({
			"icon": _gear_drop_icon_for_tier(gear_tier),
			"text": "x %d" % _contract_reward_gear_count(reward),
			"color": _tier_color_for_contract_reward(gear_tier),
			"name": "ContractGearReward",
		})
	if reward.talent_points > 0:
		entries.append({
			"icon": CardStyle.talent_point_icon(),
			"text": "x %d" % reward.talent_points,
			"color": UIColors.TEXT_POISON,
			"name": "ContractTalentReward",
		})
	if reward.gold_amount > 0:
		entries.append({
			"icon": GOLD_ICON,
			"text": "%dg" % reward.gold_amount,
			"color": UIColors.TEXT_GOLD,
			"name": "ContractGoldReward",
		})
	return entries


func _contract_reward_summary_text(reward: EncounterReward) -> String:
	var parts := PackedStringArray()
	for entry in _contract_reward_icon_entries(reward):
		parts.append(String(entry.get("text", "")))
	return " + ".join(parts) if not parts.is_empty() else "Reward unknown"


func _make_contract_reward_row(entry: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = String(entry.get("name", "ContractReward"))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 4)
	row.custom_minimum_size = CONTRACT_REWARD_PILL_MIN_SIZE

	var backing := PanelContainer.new()
	backing.name = "ContractRewardBacking"
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.custom_minimum_size = CONTRACT_REWARD_PILL_MIN_SIZE
	var backing_style := StyleBoxFlat.new()
	backing_style.bg_color = Color(0.035, 0.026, 0.020, 0.86)
	backing_style.border_color = Color(0.90, 0.78, 0.52, 0.48)
	backing_style.set_border_width_all(1)
	backing_style.set_corner_radius_all(4)
	backing.add_theme_stylebox_override("panel", backing_style)
	row.add_child(backing)

	var backing_content := HBoxContainer.new()
	backing_content.name = "ContractRewardBackingContent"
	backing_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing_content.alignment = BoxContainer.ALIGNMENT_CENTER
	backing_content.add_theme_constant_override("separation", 4)
	backing.add_child(backing_content)

	var icon := CardStyle.make_pixel_icon(entry.get("icon", null), CONTRACT_REWARD_ICON_SIZE)
	icon.name = "ContractRewardIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing_content.add_child(icon)

	var amount := Label.new()
	amount.name = "ContractRewardAmount"
	amount.text = String(entry.get("text", ""))
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount.add_theme_font_override("font", CardStyle.DATA_FONT)
	amount.add_theme_font_size_override("font_size", CONTRACT_OPTION_DETAIL_FONT_SIZE)
	amount.add_theme_color_override("font_color", entry.get("color", UIColors.TEXT_GOLD))
	amount.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE_STRONG)
	amount.add_theme_constant_override("outline_size", 2)
	backing_content.add_child(amount)
	return row


func _contract_reward_gear_tier(reward: EncounterReward) -> int:
	if reward == null:
		return -1
	if reward.generated_gear_choice_count > 0 or not reward.generated_gear_slots.is_empty():
		return int(reward.generated_gear_tier)
	if not reward.gear_choice_rewards.is_empty() and reward.gear_choice_rewards[0] != null:
		return int(reward.gear_choice_rewards[0].tier)
	if not reward.fixed_gear_rewards.is_empty() and reward.fixed_gear_rewards[0] != null:
		return int(reward.fixed_gear_rewards[0].tier)
	return -1


func _contract_reward_gear_count(reward: EncounterReward) -> int:
	if reward == null:
		return 0
	if reward.generated_gear_choice_count > 0:
		return reward.generated_gear_choice_count
	if not reward.gear_choice_rewards.is_empty():
		return reward.gear_choice_rewards.size()
	if not reward.fixed_gear_rewards.is_empty():
		return reward.fixed_gear_rewards.size()
	return 1


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


func _tier_color_for_contract_reward(tier: int) -> Color:
	return GearGenerator.tier_color(tier)


func _contract_offer_boss_node(contract: ContractDef) -> ContractRouteNode:
	if contract == null or contract.offer_node == null:
		return null
	return _find_boss_node(contract.offer_node)


func _find_boss_node(node: ContractRouteNode, visited: Array[String] = []) -> ContractRouteNode:
	if node == null or visited.has(node.id):
		return null
	if node.node_type == ContractRouteNode.NodeType.BOSS:
		return node
	visited.append(node.id)
	for next_node in node.next_nodes:
		var found := _find_boss_node(next_node, visited)
		if found != null:
			return found
	return null


func _contract_boss_name_from_display(display_name: String) -> String:
	if display_name == CONTRACT_VYRA_NAME:
		return "Vyra"
	return display_name


func _on_contract_choice_pressed(contract_id: String) -> void:
	_selected_contract_id = "" if _selected_contract_id == contract_id else contract_id
	refresh()


func _style_contract_choice_available(card: Button) -> void:
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := CardStyle.make_stylebox()
		style.bg_color = UIColors.PANEL
		style.border_color = UIColors.STRUCTURE_LINE_LIGHT
		style.set_border_width_all(3)
		card.add_theme_stylebox_override(state_name, style)


func _style_contract_choice_selected(card: Button) -> void:
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := CardStyle.make_stylebox()
		style.bg_color = UIColors.MAP_NODE_CURRENT
		style.border_color = CardStyle.ACCENT_COLOR
		style.set_border_width_all(5)
		card.add_theme_stylebox_override(state_name, style)


func _add_contract_choice_pulse(card: Button) -> void:
	var pulse := PanelContainer.new()
	pulse.name = "ContractChoicePulse"
	pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pulse.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pulse_style := StyleBoxFlat.new()
	pulse_style.bg_color = UIColors.TRANSPARENT
	pulse_style.border_color = UIColors.TEXT_GOLD
	pulse_style.set_border_width_all(5)
	pulse_style.set_corner_radius_all(8)
	pulse.add_theme_stylebox_override("panel", pulse_style)
	card.add_child(pulse)

	pulse.modulate.a = 0.35
	var tween := pulse.create_tween()
	tween.set_loops()
	tween.tween_property(pulse, "modulate:a", 1.0, CONTRACT_CHOICE_PULSE_DURATION_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(pulse, "modulate:a", 0.35, CONTRACT_CHOICE_PULSE_DURATION_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## The single action button means something different at each step:
## GREETING/CONTRACT_CHOICE are purely narrative advances handled here;
## PITCH and VYRA_DETAIL hand off to combat_screen.gd (see the signals above).
func _on_action_button_pressed() -> void:
	match _contract_step:
		Step.GREETING:
			_show_step(Step.PITCH)
		Step.PITCH:
			if BuildState.pending_contract_offers.size() > 1:
				_selected_contract_id = ""
				_show_step(Step.OFFER_CHOICE)
			else:
				accept_requested.emit("")
		Step.OFFER_CHOICE:
			if _selected_contract_id != "":
				accept_requested.emit(_selected_contract_id)
		Step.CONTRACT_CHOICE:
			if _selected_contract_id != "":
				_show_step(Step.VYRA_DETAIL)
		Step.VYRA_DETAIL:
			route_requested.emit()
