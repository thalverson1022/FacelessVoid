extends Control
## Class select: lists real ClassDefs from data/classes/ (data-driven, zero
## code changes to add a class -- same _scan_resources pattern as the old
## build_planner/class_select.gd), plus static disabled "Mage"/"Crusader"
## cards. These are pure UI placeholders, not data resources -- there's no
## real content behind them yet, so no ClassDef is invented for them.
##
## Layout per user direction: centered on the canvas, large "Choose Your
## Class" instruction above, three class cards arranged horizontally, each
## with a title and flavor text. Flavor text is UI copy, not gameplay data,
## so it's kept here rather than added to the ClassDef schema -- it doesn't
## affect BuildResolver/combat and Mage/Crusader have nowhere real to hold
## it anyway (no ClassDef exists for them).

signal advanced
signal back_pressed

const CLASS_DIR := "res://data/classes"
const CARD_WIDTH := 280
const MAIN_MENU_BACKGROUND_PATH := "res://assets/backgrounds/main_menu.jpg"
const TITLE_LIGHTNING_FLASH_OVERLAY_SCRIPT := preload("res://scripts/ui/title_lightning_flash_overlay.gd")

const INSTRUCTION_FONT_SIZE := 40
const CARD_TITLE_FONT_SIZE := 24
const FLAVOR_FONT_SIZE := 15

const FLAVOR_TEXT := {
	"Rogue": "The master of subterfuge. Slay your enemies with cunning and guile... and poison, of course poison.",
	"Mage": "Age before beauty. Command the elements and wield arcane energies, all while wearing a fun hat.",
	"Crusader": "Only God can judge you. Smite all who stand in your way as you bring peace through superior fire power.",
}
const COMING_SOON_CLASSES := ["Mage", "Crusader"]

var _card_box: HBoxContainer


func _ready() -> void:
	_add_entry_background()

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)

	var label := Label.new()
	label.text = "Choose Your Class"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.theme_type_variation = &"PanelHeader"
	label.add_theme_font_size_override("font_size", INSTRUCTION_FONT_SIZE)
	vbox.add_child(label)

	_card_box = HBoxContainer.new()
	_card_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_box.add_theme_constant_override("separation", 20)
	vbox.add_child(_card_box)

	var back_button := Button.new()
	back_button.text = "Go Back"
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(func(): back_pressed.emit())
	vbox.add_child(back_button)

	_populate_classes()


func _scan_resources(dir_path: String) -> Array[Resource]:
	var found: Array[Resource] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			if _is_resource_dir_entry(file_name):
				var resource_file_name := _resource_file_name_from_dir_entry(file_name)
				found.append(load("%s/%s" % [dir_path, resource_file_name]))
		file_name = dir.get_next()
	dir.list_dir_end()
	return found


func _resource_file_name_from_dir_entry(file_name: String) -> String:
	if file_name.ends_with(".remap"):
		return file_name.trim_suffix(".remap")
	return file_name


func _is_resource_dir_entry(file_name: String) -> bool:
	return _resource_file_name_from_dir_entry(file_name).ends_with(".tres")


func _populate_classes() -> void:
	for child in _card_box.get_children():
		child.queue_free()
	for res in BuildContentRegistry.adventure().classes.values():
		var class_def: ClassDef = res
		var select_button := Button.new()
		select_button.text = "Select"
		select_button.pressed.connect(_on_class_selected.bind(class_def))
		_card_box.add_child(_build_card(class_def.display_name, select_button))
	for coming_soon_name in COMING_SOON_CLASSES:
		var select_button := Button.new()
		select_button.text = "Coming Soon"
		select_button.disabled = true
		_card_box.add_child(_build_card(coming_soon_name, select_button))


func _build_card(class_name_text: String, select_button: Button) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	card.add_theme_stylebox_override("panel", CardStyle.make_stylebox())

	var card_vbox := VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 10)
	card.add_child(card_vbox)

	var title_label := Label.new()
	title_label.text = class_name_text
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.theme_type_variation = &"PanelHeader"
	title_label.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	card_vbox.add_child(title_label)

	var flavor_label := Label.new()
	flavor_label.text = FLAVOR_TEXT.get(class_name_text, "")
	flavor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	flavor_label.add_theme_font_size_override("font_size", FLAVOR_FONT_SIZE)
	card_vbox.add_child(flavor_label)

	card_vbox.add_child(select_button)
	return card


func _on_class_selected(class_def: ClassDef) -> void:
	BuildState.set_class(class_def)
	advanced.emit()


func _add_entry_background() -> void:
	var background := TextureRect.new()
	background.name = "ClassSelectBackground"
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
	scrim.name = "ClassSelectScrim"
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = UIColors.SCRIM_SOFT
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	var lightning_overlay := TITLE_LIGHTNING_FLASH_OVERLAY_SCRIPT.new()
	lightning_overlay.name = "ClassSelectLightningFlashOverlay"
	lightning_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	lightning_overlay.bind_background(background)
	add_child(lightning_overlay)
