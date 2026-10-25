class_name RuntimeMechanicDef
extends RefCounted

var id: String = ""
var godot_field: String = ""
var name: String = ""
var short_name: String = ""
var description: String = ""
var icon_path: String = ""
var tags: PackedStringArray = []
var matchup: Dictionary = {}
var value_label: String = ""
var min_value: float = 0.0
var max_value: float = 0.0
var export_scale: float = 1.0
var preview_only: bool = false
var runtime_supported: bool = true
var base_cost: float = 0.0
var cost_per_value: float = 0.0
var effective_hp_per_value: float = 0.0
var poison_modifier: float = 0.0
var burst_modifier: float = 0.0
var sustained_modifier: float = 0.0
var invert_cost: bool = false
var curves: Dictionary = {}
var conflicts: PackedStringArray = []
var extra_fields: Array = []


static func from_dictionary(source: Dictionary, supported_override: Variant = null) -> RuntimeMechanicDef:
	var data := RuntimeMonsterDataNormalizer.snake_keys(source)
	var def := RuntimeMechanicDef.new()
	def.id = String(data.get("id", ""))
	def.godot_field = String(data.get("godot_field", def.id))
	def.name = String(data.get("name", def.id))
	def.short_name = String(data.get("short_name", def.name))
	def.description = String(data.get("description", ""))
	def.icon_path = String(data.get("icon_path", data.get("icon", "")))
	var icon_key: String = {"dodge_chance": "dodge", "cleanse_threshold": "cleanse",
		"stun_duration_ms": "stun", "interrupt_skip_count": "interrupt"}.get(def.id, def.id)
	var assigned_icon := GameIcons.icon_for("defense." + icon_key)
	if assigned_icon != null:
		def.icon_path = assigned_icon.resource_path
	def.tags = RuntimeMonsterDataNormalizer.string_array(data.get("tags", []))
	def.matchup = RuntimeMonsterDataNormalizer.preserve_dictionary(data.get("matchup", {}))
	def.value_label = String(data.get("value_label", ""))
	def.min_value = float(data.get("min", data.get("min_value", 0.0)))
	def.max_value = float(data.get("max", data.get("max_value", 0.0)))
	def.export_scale = float(data.get("export_scale", 1.0))
	def.preview_only = bool(data.get("preview_only", false))
	def.runtime_supported = bool(supported_override) if supported_override != null else not def.preview_only
	def.base_cost = float(data.get("base_cost", 0.0))
	def.cost_per_value = float(data.get("cost_per_value", 0.0))
	def.effective_hp_per_value = float(data.get("effective_hp_per_value", 0.0))
	def.poison_modifier = float(data.get("poison_modifier", 0.0))
	def.burst_modifier = float(data.get("burst_modifier", 0.0))
	def.sustained_modifier = float(data.get("sustained_modifier", 0.0))
	def.invert_cost = bool(data.get("invert_cost", false))
	def.curves = RuntimeMonsterDataNormalizer.preserve_dictionary(data.get("curves", {}))
	def.conflicts = RuntimeMonsterDataNormalizer.string_array(data.get("conflicts", []))
	def.extra_fields = RuntimeMonsterDataNormalizer.preserve_array(data.get("extra_fields", []))
	return def


func export_value(raw_value: float) -> float:
	return RuntimeMonsterDataNormalizer.scaled_export_value(raw_value, export_scale)
