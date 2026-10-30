extends RefCounted
## Replace the popup's gold wording with the shared coin artwork before layout.
const GOLD := preload("res://assets/ui/icons/gold.png")
const WORDS := "Gold Stolen"

static func decorate(label: Label) -> void:
	if not WORDS in label.text: return
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var side := roundf(font_size * 0.9)
	var lines := label.text.split("\n")
	var row := 0
	for index in lines.size():
		if WORDS in lines[index]:
			row = index
			break
	var prefix := lines[row].get_slice(WORDS, 0)
	var x := font.get_string_size(prefix, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var height := font.get_height(font_size)
	var spacing := label.get_theme_constant("line_spacing")
	var icon := TextureRect.new()
	icon.name = "GoldAmountIcon"
	icon.texture = GOLD
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(side, side)
	icon.position = Vector2(x, row * (height + spacing) + (height - side) * 0.5)
	# Reserve real space for the icon, including when more effects follow it.
	var space_width := maxf(1, font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	label.set_meta("gold_amount_description", label.text)
	label.text = label.text.replace(WORDS, " ".repeat(ceili((side + 4) / space_width)))
	label.add_child(icon)
