extends Control
## M6 Adventure uses reviewed ranked content; Test Mode remains memory-only.
## No game logic here, per docs/Conventions.md's UI architecture principle.
##
## Layout per user direction: everything centered on the canvas, large
## title / smaller subtitle, menu set apart in a bordered card. Uses direct
## per-node overrides rather than a shared Theme resource -- a full palette/
## typography pass across all screens is still a deferred follow-up: this
## is card, no attempt to move that direction until it's decided.

signal adventure_pressed
signal continue_pressed
signal training_room_pressed
signal contract_test_pressed

const FLOW_TEXT := preload("res://scripts/ui/adventure_flow_text.gd")
const TITLE_FONT_SIZE := 48
const SUBTITLE_FONT_SIZE := 20
const CARD_TITLE_FONT_SIZE := 22
const SEED_CHECK_ICON_SIZE := 16
const RANDOM_SEED_MAX := 2147483647
const MAIN_MENU_BACKGROUND_PATH := "res://assets/backgrounds/main_menu.jpg"
const TITLE_LIGHTNING_FLASH_OVERLAY_SCRIPT := preload("res://scripts/ui/title_lightning_flash_overlay.gd")

var _new_game_confirm_dialog: ConfirmationDialog
var _random_seed_check_box: CheckBox
var _seed_spin_box: SpinBox
var _lightning_flash_overlay: Control
var _test_points: OptionButton
var _test_main_tree: OptionButton
var _test_secondary_tree: OptionButton

func _ready() -> void:
	var background := TextureRect.new()
	background.name = "MainMenuBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background_texture: Texture2D = null
	if ResourceLoader.exists(MAIN_MENU_BACKGROUND_PATH):
		background_texture = load(MAIN_MENU_BACKGROUND_PATH)
	if background_texture == null:
		var image: Image = Image.load_from_file(ProjectSettings.globalize_path(MAIN_MENU_BACKGROUND_PATH))
		if image != null:
			background_texture = ImageTexture.create_from_image(image)
	if background_texture != null:
		background.texture = background_texture
	add_child(background)

	var scrim := ColorRect.new()
	scrim.name = "MainMenuScrim"
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = UIColors.SCRIM_SOFT
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	_lightning_flash_overlay = TITLE_LIGHTNING_FLASH_OVERLAY_SCRIPT.new()
	_lightning_flash_overlay.name = "TitleLightningFlashOverlay"
	_lightning_flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lightning_flash_overlay.bind_background(background)
	add_child(_lightning_flash_overlay)

	var center := CenterContainer.new()
	center.name = "MainMenuCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	var heading := Label.new()
	heading.text = "The Road to Peak Deeps"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Title/logo role -- Pirata One, not the shared MedievalSharp
	# PanelHeader variation (P2:R7:T2 font system, title screen only).
	heading.theme_type_variation = &"TitleHeading"
	heading.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	vbox.add_child(heading)

	var subtitle := Label.new()
	subtitle.text = "Do you have what it takes?"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", SUBTITLE_FONT_SIZE)
	vbox.add_child(subtitle)

	var card_spacer := Control.new()
	card_spacer.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(card_spacer)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", CardStyle.make_stylebox(24))
	vbox.add_child(card)

	var card_vbox := VBoxContainer.new()
	card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_vbox.add_theme_constant_override("separation", 10)
	card.add_child(card_vbox)

	var card_label := Label.new()
	card_label.text = "Pick Your Poison"
	card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_label.theme_type_variation = &"PanelHeader"
	card_label.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	card_vbox.add_child(card_label)

	# Menu order per the P3:M5:T3 entry cleanup: New Adventure, Resume,
	# Practice Room. All three are always present;
	# unavailable entries are disabled rather than hidden, per the same
	# disabled-state convention as class_select.gd's Mage/Crusader cards.
	var adventure_button := Button.new()
	adventure_button.text = FLOW_TEXT.ACTION_START_ADVENTURE
	adventure_button.name = "AdventureButton"
	var boundary_ready := SevenSlotSaveBoundary.ensure_ready()
	adventure_button.disabled = not BuildContentRegistry.ADVENTURE_ENABLED or not boundary_ready
	adventure_button.tooltip_text = "Start with a Crude Dagger and earn your build through the Tavern and contracts."
	adventure_button.pressed.connect(_on_adventure_button_pressed)
	card_vbox.add_child(adventure_button)

	# Resume: always visible, grayed out (disabled) when there is no saved
	# run to resume -- previously hidden entirely, which made the menu shape
	# shift between sessions.
	var continue_button := Button.new()
	continue_button.text = FLOW_TEXT.ACTION_RESUME_ADVENTURE
	continue_button.name = "ResumeAdventureButton"
	continue_button.disabled = not BuildContentRegistry.ADVENTURE_ENABLED or not SaveSystem.has_save()
	continue_button.tooltip_text = "Resume your current Adventure." if SaveSystem.has_save() else "No current Adventure to resume."
	continue_button.pressed.connect(func(): continue_pressed.emit())
	card_vbox.add_child(continue_button)

	if SevenSlotSaveBoundary.last_error != "":
		var reset_notice := Label.new()
		reset_notice.text = SevenSlotSaveBoundary.last_error
		reset_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_vbox.add_child(reset_notice)

	var test_row := HBoxContainer.new()
	test_row.visible = false
	card_vbox.add_child(test_row)
	var test_button := Button.new()
	test_button.name = "TestModeButton"
	test_button.text = "Test Mode"
	test_button.tooltip_text = "Fresh session with your selected trees, point budget and an empty rotation. Adventure and Practice saves are preserved."
	test_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	test_button.pressed.connect(func(): contract_test_pressed.emit())
	test_row.add_child(test_button)
	_test_points = OptionButton.new()
	_test_points.name = "TestPointBudget"
	_test_points.add_item("6 points (Tavern exit)", BuildProgression.TAVERN_TOTAL)
	_test_points.add_item("45 points", 45)
	_test_points.add_item("10 points", 10)
	_test_points.tooltip_text = "Choose the starting talent point budget for your build."
	test_row.add_child(_test_points)

	var tree_row := HBoxContainer.new()
	tree_row.visible = false
	card_vbox.add_child(tree_row)
	var registry := BuildContentRegistry.test_mode()
	for role in ["Main", "Secondary"]:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tree_row.add_child(column)
		var label := Label.new()
		label.text = role + " tree"
		column.add_child(label)
		var picker := OptionButton.new()
		picker.name = "Test" + role + "Tree"
		column.add_child(picker)
		if role == "Secondary":
			_test_secondary_tree = picker
			picker.add_item("None")
			picker.set_item_metadata(0, "")
		else:
			_test_main_tree = picker
		for tree in registry.classes["class.rogue"].trees:
			picker.add_item(tree.display_name)
			picker.set_item_metadata(picker.item_count - 1, tree.id)
			if role == "Main" and tree.id == "tree.bladedancer":
				picker.select(picker.item_count - 1)
	_test_main_tree.tooltip_text = "Your main tree receives per-point intrinsic scaling."
	_test_secondary_tree.tooltip_text = "Optional second tree; shares your talent point budget."
	_test_main_tree.item_selected.connect(_on_test_main_tree_selected)
	_on_test_main_tree_selected(_test_main_tree.selected)

	var training_room_button := Button.new()
	training_room_button.text = "Practice Room"
	training_room_button.tooltip_text = FLOW_TEXT.TOOLTIP_PRACTICE_ROOM
	training_room_button.pressed.connect(func(): training_room_pressed.emit())
	card_vbox.add_child(training_room_button)

	var exit_button := Button.new()
	exit_button.text = "Exit"
	exit_button.pressed.connect(func(): get_tree().quit())
	card_vbox.add_child(exit_button)

	var seed_spacer := Control.new()
	seed_spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(seed_spacer)

	var seed_card := PanelContainer.new()
	seed_card.add_theme_stylebox_override("panel", CardStyle.make_stylebox(16))
	vbox.add_child(seed_card)

	var seed_row := HBoxContainer.new()
	seed_row.alignment = BoxContainer.ALIGNMENT_CENTER
	seed_row.add_theme_constant_override("separation", 8)
	seed_card.add_child(seed_row)

	var seed_label := Label.new()
	seed_label.text = "Seed"
	seed_row.add_child(seed_label)

	_seed_spin_box = SpinBox.new()
	_seed_spin_box.min_value = 0
	_seed_spin_box.max_value = 2147483647
	_seed_spin_box.step = 1
	_seed_spin_box.rounded = true
	_seed_spin_box.value = BuildState.adventure_seed
	_seed_spin_box.custom_minimum_size = Vector2(160, 0)
	_seed_spin_box.tooltip_text = FLOW_TEXT.TOOLTIP_ADVENTURE_SEED
	_style_seed_spin_box(_seed_spin_box)
	seed_row.add_child(_seed_spin_box)

	_random_seed_check_box = CheckBox.new()
	_random_seed_check_box.text = "Random"
	_random_seed_check_box.button_pressed = true
	_random_seed_check_box.tooltip_text = FLOW_TEXT.TOOLTIP_RANDOM_ADVENTURE_SEED
	_style_random_seed_check_box(_random_seed_check_box)
	_random_seed_check_box.toggled.connect(_on_random_seed_toggled)
	seed_row.add_child(_random_seed_check_box)
	_on_random_seed_toggled(_random_seed_check_box.button_pressed)

	_new_game_confirm_dialog = ConfirmationDialog.new()
	_new_game_confirm_dialog.title = "New Adventure"
	_new_game_confirm_dialog.dialog_text = "Starting a new Adventure will discard your saved run. Continue?"
	_new_game_confirm_dialog.confirmed.connect(func(): adventure_pressed.emit())
	add_child(_new_game_confirm_dialog)


func _on_adventure_button_pressed() -> void:
	if not BuildContentRegistry.ADVENTURE_ENABLED: return
	if SaveSystem.has_saved_file():
		_new_game_confirm_dialog.popup_centered()
	else:
		adventure_pressed.emit()


func selected_seed() -> int:
	if _seed_spin_box == null:
		return BuildState.DEFAULT_ADVENTURE_SEED
	if is_random_seed_enabled():
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		return rng.randi_range(0, RANDOM_SEED_MAX)
	return int(_seed_spin_box.value)


func is_random_seed_enabled() -> bool:
	return _random_seed_check_box != null and _random_seed_check_box.button_pressed


func _style_seed_spin_box(spin_box: SpinBox) -> void:
	var field_style := _make_seed_field_style(false)
	var focus_style := _make_seed_field_style(true)
	for state_name in ["normal", "read_only"]:
		spin_box.add_theme_stylebox_override(state_name, field_style)
	spin_box.add_theme_stylebox_override("focus", focus_style)
	spin_box.add_theme_color_override("font_color", UIColors.TEXT_NORMAL)
	spin_box.add_theme_color_override("font_readonly_color", UIColors.TEXT_DISABLED)
	spin_box.add_theme_color_override("font_selected_color", UIColors.TEXT_NORMAL)
	spin_box.add_theme_color_override("selection_color", UIColors.BUTTON_INNER_GLOW)
	var line_edit := spin_box.get_line_edit()
	if line_edit == null:
		return
	for state_name in ["normal", "read_only"]:
		line_edit.add_theme_stylebox_override(state_name, field_style)
	line_edit.add_theme_stylebox_override("focus", focus_style)
	line_edit.add_theme_color_override("font_color", UIColors.TEXT_NORMAL)
	line_edit.add_theme_color_override("font_readonly_color", UIColors.TEXT_DISABLED)
	line_edit.add_theme_color_override("font_selected_color", UIColors.TEXT_NORMAL)
	line_edit.add_theme_color_override("selection_color", UIColors.BUTTON_INNER_GLOW)


func _make_seed_field_style(focused: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UIColors.PANEL_DEEP
	style.border_color = UIColors.PANEL_EDGE_LIGHT if focused else UIColors.PANEL_BORDER
	style.set_border_width_all(2)
	style.border_blend = true
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _style_random_seed_check_box(check_box: CheckBox) -> void:
	# CheckBox inherits the project's Button style unless explicitly cleared.
	# The Random seed control is just a checkbox, not a raised action button.
	var empty_style := StyleBoxEmpty.new()
	for state_name in [
		"normal",
		"hover",
		"pressed",
		"disabled",
		"focus",
		"hover_pressed",
	]:
		check_box.add_theme_stylebox_override(state_name, empty_style)
	check_box.add_theme_color_override("font_color", UIColors.TEXT_NORMAL)
	check_box.add_theme_color_override("font_hover_color", UIColors.TEXT_NORMAL)
	check_box.add_theme_color_override("font_focus_color", UIColors.TEXT_NORMAL)
	check_box.add_theme_color_override("font_pressed_color", UIColors.TEXT_NORMAL)
	check_box.add_theme_color_override("font_disabled_color", UIColors.TEXT_DISABLED)
	var unchecked_icon := _make_seed_check_icon(false)
	var checked_icon := _make_seed_check_icon(true)
	for icon_name in [
		"unchecked",
		"unchecked_hover",
		"unchecked_pressed",
		"unchecked_focus",
		"unchecked_hover_pressed",
	]:
		check_box.add_theme_icon_override(icon_name, unchecked_icon)
	for icon_name in [
		"checked",
		"checked_hover",
		"checked_pressed",
		"checked_focus",
		"checked_hover_pressed",
	]:
		check_box.add_theme_icon_override(icon_name, checked_icon)


func _make_seed_check_icon(checked: bool) -> Texture2D:
	var image := Image.create_empty(SEED_CHECK_ICON_SIZE, SEED_CHECK_ICON_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(UIColors.TRANSPARENT)
	for y in range(SEED_CHECK_ICON_SIZE):
		for x in range(SEED_CHECK_ICON_SIZE):
			var on_border := x == 0 or y == 0 or x == SEED_CHECK_ICON_SIZE - 1 or y == SEED_CHECK_ICON_SIZE - 1
			if on_border:
				image.set_pixel(x, y, UIColors.PANEL_BORDER)
			elif x >= 2 and y >= 2 and x < SEED_CHECK_ICON_SIZE - 2 and y < SEED_CHECK_ICON_SIZE - 2:
				image.set_pixel(x, y, UIColors.PANEL_DEEP)
	if checked:
		for offset in range(3):
			image.set_pixel(4 + offset, 8 + offset, UIColors.TEXT_NORMAL)
			image.set_pixel(7 + offset, 10 - offset, UIColors.TEXT_NORMAL)
			image.set_pixel(8 + offset, 9 - offset, UIColors.TEXT_NORMAL)
	var texture := ImageTexture.create_from_image(image)
	texture.resource_name = "SeedRandomChecked" if checked else "SeedRandomUnchecked"
	return texture


func _on_random_seed_toggled(enabled: bool) -> void:
	if _seed_spin_box == null:
		return
	_seed_spin_box.editable = not enabled
	_seed_spin_box.tooltip_text = (
		FLOW_TEXT.TOOLTIP_RANDOM_ADVENTURE_SEED
		if enabled
		else FLOW_TEXT.TOOLTIP_ADVENTURE_SEED
	)


func selected_test_points() -> int:
	return _test_points.get_selected_id()


func selected_test_main_tree() -> String:
	return str(_test_main_tree.get_selected_metadata())


func selected_test_secondary_tree() -> String:
	return str(_test_secondary_tree.get_selected_metadata())


func _on_test_main_tree_selected(_index: int) -> void:
	for index in _test_secondary_tree.item_count:
		var duplicate := str(_test_secondary_tree.get_item_metadata(index)) == selected_test_main_tree()
		_test_secondary_tree.set_item_disabled(index, duplicate)
		if duplicate and _test_secondary_tree.selected == index:
			_test_secondary_tree.select(0)
