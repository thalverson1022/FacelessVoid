class_name GameIcons
extends RefCounted
## Presentation-only lookup. Stable IDs never imply content is playable.
const DATA = preload("res://scripts/ui/assigned_icon_data.gd")

static func icon_for(entity_id: String, fallback: Texture2D = null) -> Texture2D:
	var source: String = DATA.BUFF_SOURCES.get(entity_id, entity_id)
	return DATA.TEXTURES.get(source, fallback)
