extends Resource
## Explicit complete-rank formula, never inferred from a talent's name or ID.
const KINDS := ["double_dip", "sharpened_edge", "fast_hands", "fill_your_pockets", "shadow_mastery"]
@export_enum("double_dip", "sharpened_edge", "fast_hands", "fill_your_pockets", "shadow_mastery") var kind := "double_dip"
@export var fraction: float = 0.0

func validation_error() -> String:
	if kind not in KINDS:
		return "Unsupported stat derivation: " + kind
	if not is_finite(fraction) or fraction <= 0.0 or fraction > 1.0:
		return "Stat derivation fraction must be in (0, 1]."
	return ""

func compiled(source_id: String) -> Dictionary:
	return {"source_id": source_id, "kind": kind, "fraction": fraction}
