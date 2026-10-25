class_name Skill
extends Resource

enum Category { ATTACK, DEBUFF, SELF_BUFF }
@export var category: Category = Category.ATTACK

@export var id: String = ""
@export var display_name: String = ""
## Preferred compact art for skill buttons and macro slot boxes.
@export var icon: Texture2D:
	get:
		return GameIcons.icon_for(id, icon)
## Short fallback glyph shown when no icon has been assigned yet.
@export var icon_letter: String = ""
@export var base_execution_ms: int = 0
@export var min_execution_ms: int = 0
## Fight-local macro cooldown, shared by stable skill ID. Zero disables it.
@export var cooldown_ms: int = 0
@export var poison_stacks_applied: int = 0
@export var effects: Array[SkillEffect] = []
## Unlocking the reviewed Parry contract enables fight-local Readiness grants.
@export var enables_readiness: bool = false
## Current-fight credited theft conversion; floor before capping physical base bonus.
@export var stolen_gold_base_cap: int = 0
@export_range(1, 1000) var stolen_gold_per_damage: int = 1
@export var critical_damage_factor: float = 1.0
## Unlocking Dance enables its reviewed lifecycle in resolved builds.
@export var dance_duration_ms: int = 0


func stolen_gold_damage_bonus(credited_gold: int) -> int:
	return mini(maxi(0, stolen_gold_base_cap), floori(float(maxi(0, credited_gold)) / maxi(1, stolen_gold_per_damage)))
