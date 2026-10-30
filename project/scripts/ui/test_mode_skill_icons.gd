extends RefCounted
## Original skill artwork for the shared skill palette and macro presentation.
const ORIGINALS := {
	"skill.beguiling_presence": preload("res://assets/ui/assigned/skills/beguiling_presence.png"),
	"skill.big_score": preload("res://assets/ui/assigned/skills/big_score.png"),
	"skill.blinding_powder": preload("res://assets/ui/assigned/skills/blinding_powder.png"),
	"skill.dance_of_death": preload("res://assets/ui/assigned/skills/dance_of_death.png"),
	"skill.distilled_corruption": preload("res://assets/ui/assigned/skills/distilled_corruption.png"),
	"skill.heavy_slash": preload("res://assets/ui/assigned/skills/heavy_slash.png"),
	"skill.hold": preload("res://assets/ui/assigned/skills/hold.png"),
	"skill.killers_mark": preload("res://assets/ui/assigned/skills/death_strike.png"),
	"skill.leaping_plunge": preload("res://assets/ui/assigned/skills/leaping_plunge.png"),
	"skill.master_of_poisons": preload("res://assets/ui/assigned/skills/master_of_poisons.png"),
	"skill.mug": preload("res://assets/ui/assigned/skills/mug.png"),
	"skill.parry_strike": preload("res://assets/ui/assigned/skills/parry_strike.png"),
	"skill.pick_pocket": preload("res://assets/ui/assigned/skills/pick_pocket.png"),
	"skill.poison_strike": preload("res://assets/ui/assigned/skills/poison_strike.png"),
	"skill.poison_vile": preload("res://assets/ui/assigned/skills/poison_vile.png"),
	"skill.quick_cut": preload("res://assets/ui/assigned/skills/quick_cut.png"),
	"skill.rending_thrust": preload("res://assets/ui/assigned/skills/rending_slash.png"),
	"skill.stab": preload("res://assets/ui/assigned/skills/stab.png"),
	"skill.steal": preload("res://assets/ui/assigned/skills/steal.png"),
	"skill.touch_of_darkness": preload("res://assets/ui/assigned/skills/touch_of_darkness.png"),
	"skill.toxic_flurry": preload("res://assets/ui/assigned/skills/beguiling_strike.png"),
	"skill.venom_jab": preload("res://assets/ui/assigned/skills/venom_jab.png"),
	"skill.virulent_poison": preload("res://assets/ui/assigned/skills/virulent_poison.png"),
}
static var _tiles: Dictionary = {}

static func icon_for(id: String, fallback: Texture2D, pixel_scale: int = 1) -> Texture2D:
	assert(pixel_scale == 1 or pixel_scale == 2)
	var key := "%s/%d" % [id, pixel_scale]
	if _tiles.has(key): return _tiles[key]
	var original: Texture2D = ORIGINALS.get(id)
	if original == null: return fallback
	var source := original.get_image()
	if source.get_size() != Vector2i(32, 32): return fallback
	source.convert(Image.FORMAT_RGBA8)
	var art_size := 32 * pixel_scale
	if pixel_scale == 2:
		source.resize(art_size, art_size, Image.INTERPOLATE_NEAREST)
	var tile := Image.create(art_size + 8, art_size + 8, false, Image.FORMAT_RGBA8)
	tile.fill(Color("28282b"))
	tile.blend_rect(source, Rect2i(0, 0, art_size, art_size), Vector2i(4, 4))
	var texture := ImageTexture.create_from_image(tile)
	_tiles[key] = texture
	return texture
