class_name Talent
extends Resource

@export var id: String = ""
@export var display_name: String = ""
var icon: Texture2D:
	get:
		return GameIcons.icon_for(id)
@export var cost: int = 1
@export var prerequisites: Array[PrerequisiteGroup] = []
@export var stat_modifiers: Array[StatModifier] = []
@export var unlocked_skills: Array[Skill] = []
@export var triggered_skill_effects: Array[TriggeredSkillEffect] = []
@export var stat_derivations: Array[Resource] = []
@export_range(0, 5) var footwork_rank: int = 0
@export var gilded_blade_enabled: bool = false
@export_range(0, 3) var silvered_edge_rank: int = 0
@export var precision_enabled: bool = false
@export_range(0, 2) var riposte_rank: int = 0
@export var side_step_enabled: bool = false
@export var shred_cleanse_immune: bool = false
@export_range(0, 6) var bribery_base_stacks: int = 0
@export_range(0, 2) var finders_keepers_rank: int = 0

## Phase 6 descriptors; legacy resources retain their binary fields above.
@export var max_ranks: int = 1
@export var required_tree_points: int = 0
@export var prerequisite_ids: Array[String] = []
@export var ranks: Array[TalentRank] = []

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
