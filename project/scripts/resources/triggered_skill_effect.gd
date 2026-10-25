class_name TriggeredSkillEffect
extends Resource

@export var skill: Skill
@export_range(0.0, 1.0, 0.01) var chance: float = 0.0
@export var source_skill_ids: PackedStringArray = []
## Empty preserves inherited eligibility. Nonempty accepts only listed cast origins.
## Content-specific policies require review before setting this on shipped resources.
@export var source_origin_kinds: PackedStringArray = []
