extends SkillEffect
## Explicit Consume keyword. Natural depletion/cleanse never execute this effect.
@export_enum("poison", "decay") var status: String = "decay"
## -1 means all available stacks.
@export var amount: int = -1
## Distilled Corruption uses amount=5, poison_per_consumed=1.
@export var poison_per_consumed: int = 0

## Beguiling Presence: independent base-elemental buff from actual consumption.
@export var elemental_per_consumed: float = 0.0
@export var elemental_duration_ms: int = 10000

## Touch of Darkness: +10% ordinary IAS per actual Poison consumed, eight seconds.
@export var grants_touch_of_darkness: bool = false
