extends SkillEffect
## One application instance, modified once by its own stack bonuses.
@export_enum("penetration", "potency") var status: String = "potency"
@export var base_stacks: int = 1
@export var use_assassin_points: bool = false
