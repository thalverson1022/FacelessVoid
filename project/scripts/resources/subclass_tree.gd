class_name SubclassTree
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var icon: Texture2D
@export_multiline var intrinsic_text: String = ""
@export var talents: Array[Talent] = []
@export var innate_modifiers: Array[StatModifier] = []
## Skills granted just by having this tree selected (no talent required),
## e.g. Quick Cut for Bladedancer.
@export var unlocked_skills: Array[Skill] = []
## Data-driven skill changes granted by selecting this tree, e.g. Shadow's
## innate poison on Stab and Heavy Slash.
@export var skill_augments: Array[SkillAugment] = []

## Enabled only when T7 has converted and reviewed the executable content.
@export var ranked_content_ready: bool = false
## Additive per-point contributions, applied only for the primary role.
@export var primary_point_modifiers: Array[StatModifier] = []
@export var automatic_unlocks: Array[TreeSkillUnlock] = []
