class_name TalentRank
extends Resource
## Complete effects at this rank, not deltas to accumulate from earlier ranks.
@export var stat_modifiers: Array[StatModifier] = []
@export var triggered_skill_effects: Array[TriggeredSkillEffect] = []
@export var skill_augments: Array[SkillAugment] = []
@export var stat_derivations: Array[Resource] = []
## Explicit reviewed Fancy Footwork rank; zero leaves the lifecycle disabled.
@export_range(0, 5) var footwork_rank: int = 0
@export var gilded_blade_enabled: bool = false
@export_range(0, 3) var silvered_edge_rank: int = 0
## Approved M5 Bladedancer passives. False/zero leaves compatibility content unchanged.
@export var precision_enabled: bool = false
@export_range(0, 2) var riposte_rank: int = 0
@export var side_step_enabled: bool = false
@export var shred_cleanse_immune: bool = false
@export_range(0, 6) var bribery_base_stacks: int = 0
@export_range(0, 2) var finders_keepers_rank: int = 0

## M5-T7 explicit Assassin passives; zero/false preserves compatibility.
@export_range(0, 5) var hastened_poison_rank: int = 0
@export_range(0, 5) var accelerant_rank: int = 0
@export_range(0, 3) var echoing_toxin_rank: int = 0
@export_range(0, 4) var resonance_rank: int = 0
@export_range(0, 5) var toxic_tradeoff_rank: int = 0
@export var critical_poison_enabled: bool = false
@export var bypass_enabled: bool = false

## P6M5-D011 explicit Shadow carriers.
@export_range(0, 3) var death_pact_rank: int = 0
@export_range(0, 2) var death_blade_rank: int = 0
@export var dusk_strike_enabled: bool = false
@export var umbral_presence_enabled: bool = false
