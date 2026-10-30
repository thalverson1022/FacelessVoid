class_name CombatStatusIcons
extends RefCounted

const ICON_SIZE := Vector2(22, 22)
const VALUE_FONT_SIZE := 24
## Numeric warnings need readable foregrounds; blood-red fills and artwork stay unchanged.
const WARNING_TEXT := Color("F28E86")
const HEALTH_ICON := preload("res://assets/combat_ui_icons/enemy_health.png")
static var ARMOR_ICON: Texture2D = GameIcons.icon_for("defense.armor")
static var RESISTANCE_ICON: Texture2D = GameIcons.icon_for("defense.resistance")
static var POISON_ICON: Texture2D = GameIcons.icon_for("status.poison")
static var SHRED_ICON: Texture2D = GameIcons.icon_for("status.shred")
static var INACTIVE_MATERIAL: ShaderMaterial
static var DECAY_ICON: Texture2D = GameIcons.icon_for("status.decay")


static func add_icon_label(parent: Container, icon: Texture2D, text: String, color: Color, node_name: String = "", countdown: float = -1.0) -> HBoxContainer:
	var row := HBoxContainer.new()
	if node_name != "":
		row.name = node_name
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)

	var icon_rect := TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.texture = icon
	icon_rect.custom_minimum_size = ICON_SIZE
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_rect)
	var timed_defense := icon == GameIcons.icon_for("status.potency") or icon == GameIcons.icon_for("status.penetration")
	if timed_defense and text == "x0":
		if INACTIVE_MATERIAL == null:
			var shader := Shader.new()
			shader.code = "shader_type canvas_item; void fragment() { vec4 c = texture(TEXTURE, UV) * COLOR; float grey = dot(c.rgb, vec3(0.299, 0.587, 0.114)); COLOR = vec4(vec3(grey * 0.6), c.a); }"
			INACTIVE_MATERIAL = ShaderMaterial.new()
			INACTIVE_MATERIAL.shader = shader
		icon_rect.material = INACTIVE_MATERIAL
	if countdown >= 0.0:
		icon_rect.clip_contents = true
		var clock := preload("res://scripts/ui/combat_radial_countdown.gd").new()
		clock.name = "Countdown"
		clock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		clock.progress = countdown
		icon_rect.add_child(clock)

	var label := Label.new()
	label.name = "Text"
	label.text = text
	label.add_theme_color_override("font_color", WARNING_TEXT if color == UIColors.TEXT_WARNING else color)
	label.add_theme_font_size_override("font_size", VALUE_FONT_SIZE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	if timed_defense:
		# Reserve the maximum counter width even while inactive, preventing row movement.
		label.custom_minimum_size.x = label.get_theme_font("font").get_string_size("x100", HORIZONTAL_ALIGNMENT_LEFT, -1, VALUE_FONT_SIZE).x
	return row


static func add_timed_defense_chips(model, add_chip: Callable) -> void:
	for id in ["status.penetration", "status.potency"]:
		var count: int = model.units(id) if model != null else 0
		var progress := -1.0
		var tooltip := "Potency: each stack reduces absorb by 1 (max 50 stacks). Each point of absorb below zero adds 0.1 elemental base damage." if id == "status.potency" else "Penetration: each stack reduces block by 1 (max 50 stacks). Each point of block below zero adds 0.1 physical base damage."
		if count > 0:
			for value in model.active.values():
				if value.id != id:
					continue
				var deadline := int(value.state.get("expires_at_ms", -1))
				var duration := deadline - int(value.get("timer_started_ms", model.time_ms))
				var remaining := maxi(0, deadline - model.time_ms)
				progress = clampf(float(remaining) / duration, 0.0, 1.0) if duration > 0 else -1.0
				tooltip += "\n%.1fs remaining" % (remaining / 1000.0)
				break
		add_chip.call("x%d" % count, UIColors.TEXT_MAGIC if count > 0 else Color(0.55, 0.55, 0.55), GameIcons.icon_for(id), tooltip, progress)


## Keep related physical and elemental counters in indivisible vertical columns.
static func add_status_icon_label(parent: Container, icon: Texture2D, text: String, color: Color, countdown: float = -1.0) -> HBoxContainer:
	var penetration := GameIcons.icon_for("status.penetration")
	var potency := GameIcons.icon_for("status.potency")
	var key := "PhysicalStatusColumn" if icon == SHRED_ICON or icon == penetration else "ElementalStatusColumn" if icon == DECAY_ICON or icon == potency else ""
	if key == "":
		var chip := add_icon_label(parent, icon, text, color, "StatusChip", countdown)
		if icon == POISON_ICON: parent.move_child(chip, 0)
		chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		return chip
	var column := parent.get_node_or_null(NodePath(key)) as VBoxContainer
	if column == null:
		column = VBoxContainer.new()
		column.name = key
		column.add_theme_constant_override("separation", 2)
		parent.add_child(column)
	var row := add_icon_label(column, icon, text, color, "StatusChip", countdown)
	if icon == SHRED_ICON or icon == DECAY_ICON: column.move_child(row, 0)
	return row
