class_name ContractRouteGenerator
extends RefCounted

const GENERATOR_VERSION := "p4m9.t4.v1"
const RNG_CONTEXT := "contract_route_generator"
const PRESENTATION_TABLE_VERSION := "p4m10.presentation.v1"
const REWARD_TABLE_VERSION := "p4m9.rewards.v2"
const MODIFIER_MODEL_VERSION := "p4m8.modifiers.v1"
const ELITE_VARIANT_MODEL_VERSION := "p4m8.elite_variants.v1"
const BOSS_VARIANT_MODEL_VERSION := "p4m8.boss_variants.v1"
const MAX_MONSTER_DIFFICULTY_ID := 5
## Bound on how many times _generate_with_pressure_retry() re-seeds a draft
## whose own pressure model flagged "over_band" (required DPS well outside
## the intended difficulty window). Attempt 0 always uses the original,
## unsuffixed seed, so an already-in-tolerance encounter is unaffected.
const MAX_PRESSURE_RETRY_ATTEMPTS := 5
const PRESSURE_AXIS_PHYSICAL := "physical_mitigation"
const PRESSURE_AXIS_MAGICAL_POISON := "magical_poison_mitigation"
const PRESSURE_AXIS_DEBUFF_POISON := "debuff_poison_disruption"
const PRESSURE_AXIS_TIMING := "timing_control"
const PRESSURE_AXIS_RELIABILITY := "reliability_evasion"
const PRESSURE_AXIS_MIXED := "mixed"
const DEFAULT_ROUTE_DIFFICULTY := "medium"
const CONTRACT_PROGRESSION_STAGE_COUNT := 5
const COMPLETED_CONTRACT_PRESSURE_STEP := 2
const TALENT_POINT_REWARD_CAP := 10
const DEFAULT_ALLOWED_BIOMES := ["Swamp", "Cave", "Graveyard", "Haunted Forest", "Ruined Keep", "Ancient Ruins"]
const ROUTE_DIFFICULTY_IDS := {
	"easy": 1,
	"medium": 2,
	"hard": 3,
	"ultra": 4,
	"nightmare": 5,
}
const ROUTE_DIFFICULTY_LABELS_BY_ID := {
	1: "easy",
	2: "medium",
	3: "hard",
	4: "ultra",
	5: "nightmare",
}
const PRESSURE_AXIS_BY_ARCHETYPE := {
	"fortified": PRESSURE_AXIS_PHYSICAL,
	"armored": PRESSURE_AXIS_PHYSICAL,
	"warded": PRESSURE_AXIS_MAGICAL_POISON,
	"resistant": PRESSURE_AXIS_MAGICAL_POISON,
	"hexed": PRESSURE_AXIS_DEBUFF_POISON,
	"nimble": PRESSURE_AXIS_RELIABILITY,
	"devious": PRESSURE_AXIS_TIMING,
	"arcane": PRESSURE_AXIS_TIMING,
	"relentless": PRESSURE_AXIS_MIXED,
	"unstable": PRESSURE_AXIS_MIXED,
	"aegis": PRESSURE_AXIS_PHYSICAL,
	"nullify": PRESSURE_AXIS_MAGICAL_POISON,
	"spiteful": PRESSURE_AXIS_DEBUFF_POISON,
	"riftbound": PRESSURE_AXIS_MIXED,
}
const PRESSURE_AXIS_LABELS := {
	PRESSURE_AXIS_PHYSICAL: "Bulwark Hunt",
	PRESSURE_AXIS_MAGICAL_POISON: "Null Hunt",
	PRESSURE_AXIS_DEBUFF_POISON: "Hex Hunt",
	PRESSURE_AXIS_TIMING: "Tempo Hunt",
	PRESSURE_AXIS_RELIABILITY: "Evasion Hunt",
	PRESSURE_AXIS_MIXED: "Mixed Hunt",
}
const BIOME_HAZARD_LABELS := {
	"Swamp": "Mire Hazard",
	"Cave": "Echo Hazard",
	"Graveyard": "Grave Hazard",
	"Haunted Forest": "Briar Hazard",
	"Ruined Keep": "Ruin Hazard",
	"Ancient Ruins": "Rune Hazard",
}
const MODIFIER_CATALOG := [
	{
		"id": "pressure_emphasis",
		"kind": "route_pressure_emphasis",
		"label": "Pressure Emphasis",
		"preview_policy": "matching_axis",
		"metadata_only": true,
		"description": "Highlights one pressure axis so matching encounters read as the route's threat emphasis.",
	},
	{
		"id": "elite_spotlight",
		"kind": "elite_density_flavor",
		"label": "Marked Elite",
		"preview_policy": "elite_and_boss",
		"metadata_only": true,
		"description": "Calls out existing elite and boss spikes without adding fights or changing rewards.",
	},
	{
		"id": "biome_hazard",
		"kind": "biome_hazard_flavor",
		"label": "Hazard",
		"preview_policy": "matching_biome",
		"metadata_only": true,
		"description": "Adds biome hazard identity to matching combat nodes without combat payload effects.",
	},
	{
		"id": "volatile_pacing",
		"kind": "route_texture",
		"label": "Volatile Route",
		"preview_policy": "boss",
		"metadata_only": true,
		"description": "Marks the route endpoint as the payoff for a volatile contract texture.",
	},
]
const ELITE_VARIANT_CATALOG := [
	{
		"id": "shieldbreaker_captain",
		"label": "Shieldbreaker Captain",
		"primary_archetype": "aegis",
		"secondary_archetype": "fortified",
		"pressure_axis": PRESSURE_AXIS_PHYSICAL,
		"metadata_only": true,
		"description": "A block-led physical mitigation branch spike.",
	},
	{
		"id": "null_priest",
		"label": "Null Priest",
		"primary_archetype": "nullify",
		"secondary_archetype": "warded",
		"pressure_axis": PRESSURE_AXIS_MAGICAL_POISON,
		"metadata_only": true,
		"description": "An absorb/suppress magical mitigation branch spike.",
	},
	{
		"id": "venom_speaker",
		"label": "Venom Speaker",
		"primary_archetype": "spiteful",
		"secondary_archetype": "hexed",
		"pressure_axis": PRESSURE_AXIS_DEBUFF_POISON,
		"metadata_only": true,
		"description": "A cleanse/suppress poison and debuff branch spike.",
	},
	{
		"id": "phase_duelist",
		"label": "Phase Duelist",
		"primary_archetype": "nimble",
		"secondary_archetype": "devious",
		"pressure_axis": PRESSURE_AXIS_RELIABILITY,
		"metadata_only": true,
		"description": "An evasion/reliability branch spike with light tempo pressure.",
	},
	{
		"id": "riftbound_marauder",
		"label": "Riftbound Marauder",
		"primary_archetype": "riftbound",
		"secondary_archetype": "unstable",
		"pressure_axis": PRESSURE_AXIS_MIXED,
		"metadata_only": true,
		"description": "A mixed-pressure branch spike that keeps layered elite defenses in the route pool.",
	},
]
const BOSS_VARIANT_CATALOG := [
	{
		"id": "apex_bulwark",
		"label": "Apex Bulwark",
		"primary_archetype": "aegis",
		"secondary_archetype": "fortified",
		"pressure_axis": PRESSURE_AXIS_PHYSICAL,
		"metadata_only": true,
		"description": "A block-led physical mitigation endpoint.",
	},
	{
		"id": "void_regent",
		"label": "Void Regent",
		"primary_archetype": "nullify",
		"secondary_archetype": "warded",
		"pressure_axis": PRESSURE_AXIS_MAGICAL_POISON,
		"metadata_only": true,
		"description": "An absorb/suppress magical mitigation endpoint.",
	},
	{
		"id": "plague_court",
		"label": "Plague Court",
		"primary_archetype": "spiteful",
		"secondary_archetype": "hexed",
		"pressure_axis": PRESSURE_AXIS_DEBUFF_POISON,
		"metadata_only": true,
		"description": "A cleanse/suppress poison and debuff disruption endpoint.",
	},
	{
		"id": "chrono_tyrant",
		"label": "Chrono Tyrant",
		"primary_archetype": "devious",
		"secondary_archetype": "arcane",
		"pressure_axis": PRESSURE_AXIS_TIMING,
		"metadata_only": true,
		"description": "A slow/stun/interrupt timing-control endpoint.",
	},
]
const EncounterPreviewFormatterScript := preload("res://scripts/systems/runtime_monster_generator/encounter_preview_formatter.gd")
const DEFAULT_SETTINGS := {
	"min_path_length": 3,
	"max_path_length": 6,
	"shortest_path_max": 4,
	"longest_path_min": 5,
	"template_family": "p4m9_width_v1",
	"route_difficulty": DEFAULT_ROUTE_DIFFICULTY,
	"completed_contract_count": 0,
}

const REWARD_TABLE := {
	"normal": {
		"gold_base": 5,
		"gold_depth_step": 2,
		"gold_pressure_step": 3,
		"gear_choice_count": 2,
		"gear_depth_threshold": 3,
		"quality": "Steady",
	},
	"captain": {
		"gold_base": 8,
		"gold_depth_step": 2,
		"gold_pressure_step": 3,
		"gear_choice_count": 2,
		"gear_depth_threshold": 3,
		"quality": "Captain",
	},
	"elite": {
		"gold_base": 11,
		"gold_depth_step": 2,
		"gold_pressure_step": 5,
		"gear_choice_count": 2,
		"talent_depth_threshold": 4,
		"quality": "Elite",
	},
	"boss": {
		"gold_base": 22,
		"gold_depth_step": 3,
		"gold_pressure_step": 8,
		"gear_choice_count": 2,
		"talent_points": 1,
		"quality": "Contract Victory",
	},
}

const BIOME_PRESENTATION := {
	"Swamp": {
		"normal": ["Green Slime", "Swamp Goblin", "Bog Rat", "Giant Leech", "Poison Frog"],
		"captain": ["Troll", "Bog Witch"],
		"elite": ["Hydra Spawn", "Mire Knight", "Green Hag"],
		"boss": ["Swamp Hydra", "Ancient Troll", "Slime Queen", "The Drowned Matriarch", "Bogheart Colossus"],
		"tags": ["swamp"],
	},
	"Cave": {
		"normal": ["Vampire Bat", "Wolf Spider", "Goblin", "Troglodyte", "Ogre"],
		"captain": ["Troll", "Giant Centipede"],
		"elite": ["Basilisk", "Cave Brute", "Echoing Seer"],
		"boss": ["Purple Cave Wyrm", "The Goblin King", "Ancient Basilisk", "The Deep Maw", "Gemvein Tyrant"],
		"tags": ["cave"],
	},
	"Graveyard": {
		"normal": ["Restless Spirit", "Giant Rat", "Wolf", "Skeleton", "Zombie"],
		"captain": ["Flesh Golem", "Grave Robber"],
		"elite": ["Wight", "Necromancer", "Mire Knight"],
		"boss": ["Bone Colossus", "Lich", "Headless Knight", "The Bell-Tower Revenant", "King Leoric"],
		"tags": ["graveyard"],
	},
	"Haunted Forest": {
		"normal": ["Spider", "Forest Goblin", "Wisp", "Treant Sapling", "Dire Wolf"],
		"captain": ["Werewolf", "Treant"],
		"elite": ["Green Hag", "Night Stalker", "Hollow-Eyed Witch"],
		"boss": ["Ancient Treant", "Forest Witch", "Great Warebear", "The Root-Crowned Widow", "Moonless Huntmaster"],
		"tags": ["haunted forest"],
	},
	"Ruined Keep": {
		"normal": ["Rat", "Undead Guard", "Bandit", "Cultist", "Animated Armor"],
		"captain": ["Gargoyle", "Warlock"],
		"elite": ["Dark Knight", "Oathbreaker Captain", "Arcane Golem"],
		"boss": ["Fallen King", "Bejeweled Iron Golem", "The Half-blood Prince", "The Last Castellan", "Faithless Executioner"],
		"tags": ["ruined keep"],
	},
	"Ancient Ruins": {
		"normal": ["Cultist", "Animated Statue", "Scarab", "Wisp"],
		"captain": ["Minotaur", "Guardian Construct"],
		"elite": ["Arcane Golem", "Runemark Sentinel", "Scarab Queen"],
		"boss": ["Ancient Guardian", "Sphinx", "Runic Colossus", "The First Idol", "Ancient Archivist"],
		"tags": ["ancient ruins"],
	},
}

const CAPTAIN_PROMOTED_NORMAL_NAMES := {
	"Green Slime": "Giant Green Slime",
	"Swamp Goblin": "Veteran Swamp Goblin",
	"Bog Rat": "Giant Bog Rat",
	"Giant Leech": "Elder Leech",
	"Poison Frog": "Giant Poison Frog",
	"Vampire Bat": "Giant Vampire Bat",
	"Wolf Spider": "Giant Wolf Spider",
	"Goblin": "Veteran Goblin",
	"Troglodyte": "Veteran Troglodyte",
	"Ogre": "Veteran Ogre",
	"Restless Spirit": "Ancient Restless Spirit",
	"Giant Rat": "Dire Rat",
	"Wolf": "Giant Wolf",
	"Skeleton": "Ancient Skeleton",
	"Zombie": "Ancient Zombie",
	"Spider": "Giant Spider",
	"Forest Goblin": "Veteran Forest Goblin",
	"Wisp": "Ancient Wisp",
	"Treant Sapling": "Ancient Treant Sapling",
	"Dire Wolf": "Alpha Dire Wolf",
	"Rat": "Giant Rat",
	"Undead Guard": "Ancient Undead Guard",
	"Bandit": "Veteran Bandit",
	"Cultist": "Veteran Cultist",
	"Animated Armor": "Ancient Animated Armor",
	"Animated Statue": "Ancient Animated Statue",
	"Scarab": "Giant Scarab",
}

const ARCHETYPE_TAG_SETS := [
	["fortified"],
	["warded"],
	["nimble"],
	["hexed"],
	["devious"],
	["fortified", "warded"],
	["aegis"],
	["nullify"],
	["spiteful"],
	["riftbound"],
]

const TEMPLATES := [
	{
		"id": "braided_sideboard",
		"display_label": "Braided Sideboard",
		"pacing_profile": "braided_elite_sideboard",
		"min_path_length": 4,
		"max_path_length": 4,
		"shortest_path_max": 4,
		"longest_path_min": 4,
		"nodes": [
			{"id": "start", "type": ContractRouteNode.NodeType.START, "depth": 0, "lane": 0},
			{"id": "low_road", "type": ContractRouteNode.NodeType.FIGHT, "depth": 1, "lane": 0, "intent": "safe", "intent_tags": ["safe", "steady"]},
			{"id": "main_road", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 1, "lane": 1, "intent": "risky", "intent_tags": ["risky", "captain_gate"]},
			{"id": "high_road", "type": ContractRouteNode.NodeType.FIGHT, "depth": 1, "lane": 2, "intent": "safe", "intent_tags": ["safe", "matchup_choice"]},
			{"id": "toll_fight", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 2, "lane": 0, "intent": "captain_gate", "intent_tags": ["risky", "captain_gate"]},
			{"id": "pressure_fight", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 2, "lane": 2, "intent": "captain_gate", "intent_tags": ["risky", "captain_gate"]},
			{"id": "elite_sideboard", "type": ContractRouteNode.NodeType.ELITE, "depth": 2, "lane": 1, "intent": "elite_detour", "intent_tags": ["risky", "high_reward", "elite_detour"]},
			{"id": "rejoin", "type": ContractRouteNode.NodeType.FIGHT, "depth": 3, "lane": 1, "intent": "recovery", "intent_tags": ["safe", "recovery"]},
			{"id": "boss", "type": ContractRouteNode.NodeType.BOSS, "depth": 4, "lane": 1},
		],
		"edges": {
			"start": ["low_road", "main_road", "high_road"],
			"low_road": ["toll_fight"],
			"main_road": ["toll_fight", "pressure_fight", "elite_sideboard"],
			"high_road": ["pressure_fight"],
			"toll_fight": ["rejoin"],
			"pressure_fight": ["rejoin"],
			"elite_sideboard": ["rejoin"],
			"rejoin": ["boss"],
			"boss": [],
		},
	},
	{
		"id": "split_spill_rejoin",
		"display_label": "Split Spill Rejoin",
		"pacing_profile": "wide_shared_gates",
		"min_path_length": 4,
		"max_path_length": 4,
		"shortest_path_max": 4,
		"longest_path_min": 4,
		"nodes": [
			{"id": "start", "type": ContractRouteNode.NodeType.START, "depth": 0, "lane": 0},
			{"id": "safe_start", "type": ContractRouteNode.NodeType.FIGHT, "depth": 1, "lane": 0, "intent": "safe", "intent_tags": ["safe", "steady", "fork_rejoin"]},
			{"id": "odd_matchup", "type": ContractRouteNode.NodeType.FIGHT, "depth": 1, "lane": 1, "intent": "matchup_choice", "intent_tags": ["safe", "matchup_choice", "fork_rejoin"]},
			{"id": "captain_start", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 1, "lane": 2, "intent": "risky", "intent_tags": ["risky", "high_reward", "captain_gate", "pressure_gauntlet", "fork_rejoin"]},
			{"id": "long_start", "type": ContractRouteNode.NodeType.FIGHT, "depth": 1, "lane": 3, "intent": "safe", "intent_tags": ["safe", "long_safe", "fork_rejoin"]},
			{"id": "shared_gate_a", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 2, "lane": 0, "intent": "captain_gate", "intent_tags": ["risky", "captain_gate", "pressure_gauntlet", "fork_rejoin"]},
			{"id": "recovery", "type": ContractRouteNode.NodeType.FIGHT, "depth": 2, "lane": 2, "intent": "recovery", "intent_tags": ["safe", "recovery", "fork_rejoin"]},
			{"id": "final_gate", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 3, "lane": 1, "intent": "boss_prep", "intent_tags": ["risky", "boss_prep", "pressure_gauntlet"]},
			{"id": "boss", "type": ContractRouteNode.NodeType.BOSS, "depth": 4, "lane": 1},
		],
		"edges": {
			"start": ["safe_start", "odd_matchup", "captain_start", "long_start"],
			"safe_start": ["shared_gate_a"],
			"odd_matchup": ["shared_gate_a"],
			"captain_start": ["recovery"],
			"long_start": ["recovery"],
			"shared_gate_a": ["final_gate"],
			"recovery": ["final_gate"],
			"final_gate": ["boss"],
			"boss": [],
		},
	},
	{
		"id": "elite_orbit",
		"display_label": "Elite Orbit",
		"pacing_profile": "optional_orbit_detour",
		"min_path_length": 3,
		"max_path_length": 4,
		"shortest_path_max": 3,
		"longest_path_min": 4,
		"nodes": [
			{"id": "start", "type": ContractRouteNode.NodeType.START, "depth": 0, "lane": 0},
			{"id": "main", "type": ContractRouteNode.NodeType.FIGHT, "depth": 1, "lane": 0, "intent": "safe", "intent_tags": ["safe", "short_safe"]},
			{"id": "captain", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 1, "lane": 1, "intent": "risky", "intent_tags": ["risky", "captain_gate"]},
			{"id": "alternate", "type": ContractRouteNode.NodeType.FIGHT, "depth": 1, "lane": 2, "intent": "matchup_choice", "intent_tags": ["safe", "matchup_choice"]},
			{"id": "merge_a", "type": ContractRouteNode.NodeType.FIGHT, "depth": 2, "lane": 0, "intent": "safe", "intent_tags": ["safe", "recovery", "boss_approach", "safe_boss_approach"]},
			{"id": "elite_orbit", "type": ContractRouteNode.NodeType.ELITE, "depth": 2, "lane": 1, "intent": "elite_detour", "intent_tags": ["risky", "high_reward", "elite_detour"]},
			{"id": "merge_b", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 3, "lane": 2, "intent": "captain_gate", "intent_tags": ["risky", "boss_prep", "boss_approach", "captain_boss_approach"]},
			{"id": "boss", "type": ContractRouteNode.NodeType.BOSS, "depth": 4, "lane": 1},
		],
		"edges": {
			"start": ["main", "captain", "alternate"],
			"main": ["merge_a", "elite_orbit"],
			"captain": ["merge_a"],
			"alternate": ["merge_b", "elite_orbit"],
			"merge_a": ["boss"],
			"elite_orbit": ["merge_b"],
			"merge_b": ["boss"],
			"boss": [],
		},
	},
	{
		"id": "five_way_market",
		"display_label": "Five-Way Market",
		"pacing_profile": "wide_matchup_market",
		"min_path_length": 3,
		"max_path_length": 3,
		"shortest_path_max": 3,
		"longest_path_min": 3,
		"nodes": [
			{"id": "start", "type": ContractRouteNode.NodeType.START, "depth": 0, "lane": 0},
			{"id": "armor_path", "type": ContractRouteNode.NodeType.FIGHT, "depth": 1, "lane": 0, "intent": "safe", "intent_tags": ["safe", "matchup_choice", "wide_matchup_choice"]},
			{"id": "poison_path", "type": ContractRouteNode.NodeType.FIGHT, "depth": 1, "lane": 1, "intent": "safe", "intent_tags": ["safe", "matchup_choice", "wide_matchup_choice"]},
			{"id": "evasion_path", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 1, "lane": 2, "intent": "risky", "intent_tags": ["risky", "captain_gate", "wide_matchup_choice"]},
			{"id": "warded_path", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 1, "lane": 3, "intent": "risky", "intent_tags": ["risky", "high_reward", "captain_gate", "wide_matchup_choice"]},
			{"id": "elite_prize", "type": ContractRouteNode.NodeType.ELITE, "depth": 1, "lane": 4, "intent": "elite_detour", "intent_tags": ["risky", "high_reward", "elite_detour", "wide_matchup_choice"]},
			{"id": "left_merge", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 2, "lane": 1, "intent": "captain_gate", "intent_tags": ["risky", "captain_gate", "fork_rejoin", "boss_approach", "captain_boss_approach"]},
			{"id": "center_merge", "type": ContractRouteNode.NodeType.FIGHT, "depth": 2, "lane": 3, "intent": "recovery", "intent_tags": ["safe", "recovery", "fork_rejoin", "boss_approach", "safe_boss_approach"]},
			{"id": "boss", "type": ContractRouteNode.NodeType.BOSS, "depth": 3, "lane": 2},
		],
		"edges": {
			"start": ["armor_path", "poison_path", "evasion_path", "warded_path", "elite_prize"],
			"armor_path": ["left_merge"],
			"poison_path": ["left_merge"],
			"evasion_path": ["center_merge"],
			"warded_path": ["center_merge"],
			"elite_prize": ["center_merge"],
			"left_merge": ["boss"],
			"center_merge": ["boss"],
			"boss": [],
		},
	},
	{
		"id": "hourglass_detour",
		"display_label": "Hourglass Detour",
		"pacing_profile": "wide_pinch_wide_exit",
		"min_path_length": 4,
		"max_path_length": 4,
		"shortest_path_max": 4,
		"longest_path_min": 4,
		"nodes": [
			{"id": "start", "type": ContractRouteNode.NodeType.START, "depth": 0, "lane": 0},
			{"id": "safe", "type": ContractRouteNode.NodeType.FIGHT, "depth": 1, "lane": 0, "intent": "safe", "intent_tags": ["safe", "steady"]},
			{"id": "captain", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 1, "lane": 1, "intent": "risky", "intent_tags": ["risky", "captain_gate"]},
			{"id": "weird", "type": ContractRouteNode.NodeType.FIGHT, "depth": 1, "lane": 2, "intent": "matchup_choice", "intent_tags": ["safe", "matchup_choice"]},
			{"id": "pinch_point", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 2, "lane": 1, "intent": "captain_gate", "intent_tags": ["risky", "captain_gate", "pressure_gauntlet"]},
			{"id": "low_exit", "type": ContractRouteNode.NodeType.FIGHT, "depth": 3, "lane": 0, "intent": "recovery", "intent_tags": ["safe", "recovery", "boss_approach", "safe_boss_approach"]},
			{"id": "captain_exit", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 3, "lane": 1, "intent": "boss_prep", "intent_tags": ["risky", "boss_prep", "pressure_gauntlet", "boss_approach", "captain_boss_approach"]},
			{"id": "elite_exit", "type": ContractRouteNode.NodeType.ELITE, "depth": 3, "lane": 2, "intent": "elite_detour", "intent_tags": ["risky", "high_reward", "elite_detour", "boss_approach", "elite_boss_approach", "reward_boss_approach"]},
			{"id": "boss", "type": ContractRouteNode.NodeType.BOSS, "depth": 4, "lane": 1},
		],
		"edges": {
			"start": ["safe", "captain", "weird"],
			"safe": ["pinch_point"],
			"captain": ["pinch_point"],
			"weird": ["pinch_point"],
			"pinch_point": ["low_exit", "captain_exit", "elite_exit"],
			"low_exit": ["boss"],
			"captain_exit": ["boss"],
			"elite_exit": ["boss"],
			"boss": [],
		},
	},
	{
		"id": "woven_boss_approach",
		"display_label": "Woven Boss Approach",
		"pacing_profile": "braided_boss_approach",
		"min_path_length": 3,
		"max_path_length": 3,
		"shortest_path_max": 3,
		"longest_path_min": 3,
		"nodes": [
			{"id": "start", "type": ContractRouteNode.NodeType.START, "depth": 0, "lane": 0},
			{"id": "entry_a", "type": ContractRouteNode.NodeType.FIGHT, "depth": 1, "lane": 0, "intent": "safe", "intent_tags": ["safe", "matchup_choice", "fork_rejoin"]},
			{"id": "entry_b", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 1, "lane": 1, "intent": "risky", "intent_tags": ["risky", "captain_gate", "fork_rejoin"]},
			{"id": "entry_c", "type": ContractRouteNode.NodeType.FIGHT, "depth": 1, "lane": 2, "intent": "safe", "intent_tags": ["safe", "matchup_choice", "fork_rejoin"]},
			{"id": "prep_d", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 2, "lane": 0, "intent": "boss_prep", "intent_tags": ["risky", "boss_prep", "fork_rejoin", "boss_approach", "captain_boss_approach"]},
			{"id": "prep_e", "type": ContractRouteNode.NodeType.FIGHT, "depth": 2, "lane": 1, "intent": "recovery", "intent_tags": ["safe", "recovery", "fork_rejoin", "boss_approach", "safe_boss_approach"]},
			{"id": "prep_f", "type": ContractRouteNode.NodeType.ELITE, "depth": 2, "lane": 2, "intent": "elite_detour", "intent_tags": ["risky", "high_reward", "elite_detour", "fork_rejoin", "boss_approach", "elite_boss_approach", "reward_boss_approach"]},
			{"id": "prep_g", "type": ContractRouteNode.NodeType.CAPTAIN, "depth": 2, "lane": 3, "intent": "boss_prep", "intent_tags": ["risky", "boss_prep", "fork_rejoin", "boss_approach", "captain_boss_approach"]},
			{"id": "boss", "type": ContractRouteNode.NodeType.BOSS, "depth": 3, "lane": 1},
		],
		"edges": {
			"start": ["entry_a", "entry_b", "entry_c"],
			"entry_a": ["prep_d", "prep_e"],
			"entry_b": ["prep_e", "prep_f"],
			"entry_c": ["prep_f", "prep_g"],
			"prep_d": ["boss"],
			"prep_e": ["boss"],
			"prep_f": ["boss"],
			"prep_g": ["boss"],
			"boss": [],
		},
	},
]


static func generate(seed: int, settings: Dictionary = {}) -> ContractDef:
	var route_settings := _normalized_settings(settings)
	var template: Dictionary = _select_template(seed, route_settings)
	var selected_biome := _select_route_biome(seed, route_settings)
	var generated_modifiers := _select_route_modifiers(seed, route_settings, selected_biome)
	var progression := _route_progression_from_settings(route_settings)
	var contract := ContractDef.new()
	contract.id = RunRng.id_for_context("contract.generated", seed, RNG_CONTEXT, [GENERATOR_VERSION, route_settings["template_family"]])
	contract.display_name = "Generated Contract"
	contract.target_display_name = "Generated Boss"
	contract.offer_text = "A generated route waits beyond the Tavern."
	contract.apply_generated_route_state({
		"generated_route_id": RunRng.id_for_context("route.generated", seed, RNG_CONTEXT, [GENERATOR_VERSION, template["id"]]),
		"source_seed": seed,
		"generator_version": GENERATOR_VERSION,
		"route_difficulty": String(progression["effective_contract_difficulty_label"]),
		"selected_biome": selected_biome,
		"allowed_biomes": _allowed_biomes(route_settings),
		"biome_table_version": PRESENTATION_TABLE_VERSION,
		"runtime_monster_generator_version": RuntimeMonsterGenerator.GENERATOR_VERSION,
		"runtime_monster_archetype_library_version": RuntimeArchetypeLibraryLoader.EXPECTED_SCHEMA,
		"modifier_model_version": MODIFIER_MODEL_VERSION,
		"generated_modifier_ids": _modifier_ids(generated_modifiers),
		"generated_modifiers": generated_modifiers,
		"template_id": String(template["id"]),
		"template_display_label": String(template.get("display_label", template["id"])),
		"template_width_summary": _template_width_summary(template),
		"route_settings": route_settings,
		"route_notices": [
			"template:%s" % template["id"],
			"template_label:%s" % String(template.get("display_label", template["id"])),
			"pacing:%s" % template["pacing_profile"],
			"reward_table:%s" % REWARD_TABLE_VERSION,
			"modifier_model:%s" % MODIFIER_MODEL_VERSION,
			"modifiers:%s" % ",".join(_modifier_ids(generated_modifiers)),
			"reward_pressure:completed_contracts:%d:tier:%d" % [
				int(route_settings.get("completed_contract_count", 0)),
				_completed_contract_pressure_bonus_from_count(int(route_settings.get("completed_contract_count", 0))),
			],
			"progression:%s:stage:%d/%d:next:%s:overcap:%d" % [
				String(progression["effective_contract_difficulty_label"]),
				int(progression["stage"]),
				CONTRACT_PROGRESSION_STAGE_COUNT,
				String(progression["next_contract_difficulty_label"]),
				int(progression["band_overcap"]),
			],
		],
	})

	var library := RuntimeArchetypeLibraryLoader.load_default()
	var nodes := _materialize_nodes(seed, template, contract, library)
	_connect_nodes(nodes, template)
	contract.offer_node = nodes["start"]
	return contract


static func validate(contract: ContractDef) -> PackedStringArray:
	var notices := PackedStringArray()
	if contract == null:
		notices.append("contract_missing")
		return notices
	if contract.offer_node == null:
		notices.append("start_missing")
		return notices

	var nodes := _collect_nodes(contract.offer_node)
	var ids := {}
	var start_count := 0
	var boss_count := 0
	var branch_count := 0
	var boss_node: ContractRouteNode = null
	for node in nodes:
		if node == null:
			notices.append("node_null")
			continue
		if ids.has(node.generated_node_id):
			notices.append("duplicate_node_id:%s" % node.generated_node_id)
		ids[node.generated_node_id] = node
		if node.node_type == ContractRouteNode.NodeType.START:
			start_count += 1
		if node.node_type == ContractRouteNode.NodeType.BOSS:
			boss_count += 1
			boss_node = node
		if node.next_nodes.size() > 1:
			branch_count += 1
		if node.node_type == ContractRouteNode.NodeType.BOSS:
			if not node.next_nodes.is_empty():
				notices.append("boss_has_outgoing:%s" % node.generated_node_id)
		elif node.next_nodes.is_empty():
			notices.append("dead_end:%s" % node.generated_node_id)
		for next_node in node.next_nodes:
			if next_node == null:
				notices.append("edge_null:%s" % node.generated_node_id)
			elif next_node.depth <= node.depth:
				notices.append("edge_not_forward:%s>%s" % [node.generated_node_id, next_node.generated_node_id])
	if start_count != 1:
		notices.append("start_count:%d" % start_count)
	if boss_count != 1:
		notices.append("boss_count:%d" % boss_count)
	if branch_count < 1:
		notices.append("branch_missing")
	_validate_template_width(contract, nodes, notices)
	if boss_node == null:
		notices.append("multiple_paths_missing")
		return notices

	var paths := _enumerate_paths(contract.offer_node, boss_node)
	if paths.size() < 2:
		notices.append("multiple_paths_missing")
	_validate_path_pacing(paths, contract.route_settings, notices)
	_validate_elite_pacing(contract.offer_node, paths, notices)
	_validate_branch_quality(nodes, notices)
	_validate_branch_intent_tradeoffs(nodes, notices)
	_validate_elite_detour_and_pressure_gauntlet(nodes, paths, notices)
	_validate_wide_matchup_and_fork_rejoin(nodes, boss_node, notices)
	_validate_boss_approach_lanes(nodes, boss_node, notices)
	_validate_pressure_scale_metadata(nodes, notices)
	_validate_reward_pressure_pacing(contract, nodes, notices)
	_validate_pressure_axis_metadata(nodes, notices)
	_validate_modifier_metadata(contract, nodes, notices)
	_validate_elite_variant_metadata(nodes, notices)
	_validate_boss_variant_metadata(nodes, notices)
	_validate_dead_run_axis_diversity(nodes, paths, boss_node, notices)
	return notices


static func graph_signature(contract: ContractDef) -> String:
	if contract == null or contract.offer_node == null:
		return ""
	var parts := PackedStringArray()
	parts.append(contract.generated_route_id)
	parts.append(str(contract.source_seed))
	parts.append(contract.generator_version)
	parts.append(contract.template_id)
	parts.append(contract.template_display_label)
	parts.append(JSON.stringify(contract.template_width_summary))
	parts.append(",".join(Array(contract.generated_modifier_ids)))
	for node in _collect_nodes(contract.offer_node):
		var outgoing := PackedStringArray()
		for next_node in node.next_nodes:
			outgoing.append(next_node.generated_node_id)
		parts.append("%s:%d:%d:%d:%s:%s:%s:%s:%s:%s" % [
			node.generated_node_id,
			node.node_type,
			node.depth,
			node.lane,
			node.biome,
			String(node.route_preview.get("monster_name", "")),
			String(node.route_preview.get("modifier_label", "")),
			node.elite_variant_id,
			node.boss_variant_id,
			",".join(outgoing),
		])
		parts.append("intent:%s:%s" % [node.branch_intent, ",".join(Array(node.branch_intent_tags))])
		parts.append(_encounter_signature(node))
		parts.append(_reward_signature(node))
	return "|".join(parts)


static func _normalized_settings(settings: Dictionary) -> Dictionary:
	var normalized := DEFAULT_SETTINGS.duplicate(true)
	for key in settings:
		normalized[key] = settings[key]
	if not normalized.has("allowed_biomes"):
		normalized["allowed_biomes"] = DEFAULT_ALLOWED_BIOMES.duplicate()
	return normalized


static func _select_template(seed: int, settings: Dictionary) -> Dictionary:
	var rng := RunRng.rng_for_context(seed, RNG_CONTEXT, [GENERATOR_VERSION, "graph_shape", settings.get("template_family", "")])
	var template: Dictionary = TEMPLATES[rng.randi_range(0, TEMPLATES.size() - 1)]
	settings["template_id"] = template["id"]
	settings["template_display_label"] = String(template.get("display_label", template["id"]))
	settings["template_width_summary"] = _template_width_summary(template)
	settings["pacing_profile"] = template["pacing_profile"]
	for key in ["min_path_length", "max_path_length", "shortest_path_max", "longest_path_min"]:
		if template.has(key):
			settings[key] = int(template[key])
	return template


static func _template_width_summary(template: Dictionary) -> Dictionary:
	var edges: Dictionary = template.get("edges", {})
	var max_width := 0
	var wide_node_ids := PackedStringArray()
	var branch_node_ids := PackedStringArray()
	for node_id in edges:
		var width := (edges[node_id] as Array).size()
		if width > 1:
			branch_node_ids.append(String(node_id))
		if width >= 3:
			wide_node_ids.append(String(node_id))
		max_width = maxi(max_width, width)
	return {
		"max_width": max_width,
		"wide_node_ids": Array(wide_node_ids),
		"branch_node_ids": Array(branch_node_ids),
		"requires_wide_choice": true,
	}


static func _select_route_biome(seed: int, settings: Dictionary) -> String:
	var biomes := _allowed_biomes(settings)
	var rng := RunRng.rng_for_context(seed, RNG_CONTEXT, [GENERATOR_VERSION, "biome", PRESENTATION_TABLE_VERSION])
	return biomes[rng.randi_range(0, biomes.size() - 1)]


static func _allowed_biomes(settings: Dictionary) -> PackedStringArray:
	var biomes := PackedStringArray()
	var raw: Variant = settings.get("allowed_biomes", DEFAULT_ALLOWED_BIOMES)
	if raw is PackedStringArray:
		biomes = raw
	elif raw is Array:
		for biome in raw:
			var name := String(biome)
			if BIOME_PRESENTATION.has(name):
				biomes.append(name)
	if biomes.is_empty():
		return PackedStringArray(DEFAULT_ALLOWED_BIOMES)
	return biomes


static func _select_route_modifiers(seed: int, settings: Dictionary, selected_biome: String) -> Array[Dictionary]:
	var rng := RunRng.rng_for_context(seed, RNG_CONTEXT, [
		GENERATOR_VERSION,
		"route_modifiers",
		MODIFIER_MODEL_VERSION,
		settings.get("template_id", ""),
		settings.get("route_difficulty", DEFAULT_ROUTE_DIFFICULTY),
		selected_biome,
	])
	var template: Dictionary = MODIFIER_CATALOG[rng.randi_range(0, MODIFIER_CATALOG.size() - 1)]
	var modifier: Dictionary = template.duplicate(true)
	modifier["model_version"] = MODIFIER_MODEL_VERSION
	match String(modifier["id"]):
		"pressure_emphasis":
			var axes := PackedStringArray()
			for axis_key in PRESSURE_AXIS_LABELS.keys():
				axes.append(String(axis_key))
			var axis := String(axes[rng.randi_range(0, axes.size() - 1)])
			modifier["axis"] = axis
			modifier["label"] = String(PRESSURE_AXIS_LABELS[axis])
		"biome_hazard":
			modifier["biome"] = selected_biome
			modifier["label"] = String(BIOME_HAZARD_LABELS.get(selected_biome, "%s Hazard" % selected_biome))
	return [modifier]


static func _modifier_ids(modifiers: Array[Dictionary]) -> PackedStringArray:
	var ids := PackedStringArray()
	for modifier in modifiers:
		ids.append(String(modifier.get("id", "")))
	return ids


static func _packed_string_array(value: Variant) -> PackedStringArray:
	var result := PackedStringArray()
	if value is PackedStringArray:
		return value
	if value is Array:
		for item in value:
			result.append(String(item))
	return result


static func _materialize_nodes(seed: int, template: Dictionary, contract: ContractDef, library: RuntimeArchetypeLibrary) -> Dictionary:
	var nodes := {}
	var used_presentation_names := {}
	for spec in template["nodes"]:
		var node := ContractRouteNode.new()
		var generated_id := String(spec["id"])
		node.id = "%s.%s" % [contract.generated_route_id, generated_id]
		node.generated_node_id = generated_id
		node.node_type = int(spec["type"])
		node.depth = int(spec["depth"])
		node.lane = int(spec["lane"])
		node.branch_intent = String(spec.get("intent", ""))
		node.branch_intent_tags = _packed_string_array(spec.get("intent_tags", []))
		node.biome = _node_biome(seed, contract, generated_id)
		node.monster_presentation_type = _presentation_type(seed, node, used_presentation_names)
		node.display_name = node.monster_presentation_type
		node.route_preview = _route_preview(seed, node)
		node.generation_notices = PackedStringArray(["template:%s" % template["id"]])
		_assign_generated_encounter(seed, contract, node, library)
		_assign_generated_reward(seed, contract, node)
		nodes[generated_id] = node
	return nodes


static func _connect_nodes(nodes: Dictionary, template: Dictionary) -> void:
	var edges: Dictionary = template["edges"]
	for node_id in edges:
		var node: ContractRouteNode = nodes[node_id]
		for next_id in edges[node_id]:
			node.next_nodes.append(nodes[String(next_id)])
		node.sync_outgoing_node_ids_from_next_nodes()


static func _node_biome(_seed: int, contract: ContractDef, _node_id: String) -> String:
	if contract.selected_biome != "":
		return contract.selected_biome
	if not contract.allowed_biomes.is_empty():
		return String(contract.allowed_biomes[0])
	return DEFAULT_ALLOWED_BIOMES[0]


static func _presentation_type(seed: int, node: ContractRouteNode, used_names: Dictionary = {}) -> String:
	if node.node_type == ContractRouteNode.NodeType.START:
		return "Route Start"
	var kind := _presentation_kind(node)
	var pool := _presentation_name_candidates(node.biome, kind, used_names)
	if pool.is_empty():
		return "Generated Monster"
	var rng := RunRng.rng_for_context(seed, RNG_CONTEXT, [GENERATOR_VERSION, "presentation", PRESENTATION_TABLE_VERSION, node.generated_node_id])
	var name := String(pool[rng.randi_range(0, pool.size() - 1)])
	used_names[name] = true
	return name


static func _presentation_name_candidates(biome: String, kind: String, used_names: Dictionary = {}) -> Array:
	var table := _presentation_for_biome(biome)
	var primary_pool: Array = table.get(kind, [])
	if kind == "captain":
		var unused_primary := _unused_names(primary_pool, used_names)
		if not unused_primary.is_empty():
			return unused_primary
		var promoted := _promoted_captain_names(table.get("normal", []))
		var unused_promoted := _unused_names(promoted, used_names)
		return unused_promoted if not unused_promoted.is_empty() else promoted
	var unused := _unused_names(primary_pool, used_names)
	return unused if not unused.is_empty() else primary_pool


static func _unused_names(pool: Array, used_names: Dictionary) -> Array:
	var unused := []
	for entry in pool:
		var name := String(entry)
		if not used_names.has(name):
			unused.append(name)
	return unused


static func _promoted_captain_names(normal_pool: Array) -> Array:
	var promoted := []
	for entry in normal_pool:
		var normal_name := String(entry)
		promoted.append(String(CAPTAIN_PROMOTED_NORMAL_NAMES.get(normal_name, "Veteran %s" % normal_name)))
	return promoted


static func _route_preview(seed: int, node: ContractRouteNode) -> Dictionary:
	if node.node_type == ContractRouteNode.NodeType.START:
		return {
			"biome": node.biome,
			"monster_name": node.display_name,
			"encounter_level": "Start",
			"archetype_tags": [],
		}
	var tags := _archetype_tags(seed, node)
	var biome_tags: Array = _presentation_for_biome(node.biome).get("tags", [])
	for tag in biome_tags:
		if not tags.has(String(tag)):
			tags.append(String(tag))
	return {
		"biome": node.biome,
		"monster_name": node.display_name,
		"encounter_level": _encounter_level(node),
		"archetype_tags": tags,
	}


static func _presentation_for_biome(biome: String) -> Dictionary:
	return (BIOME_PRESENTATION.get(biome, BIOME_PRESENTATION[DEFAULT_ALLOWED_BIOMES[0]]) as Dictionary)


static func _assign_generated_encounter(seed: int, contract: ContractDef, node: ContractRouteNode, library: RuntimeArchetypeLibrary) -> void:
	if node.node_type == ContractRouteNode.NodeType.START:
		return

	var monster_kind := _node_kind(node)
	var pressure_scale := _encounter_pressure_scale(contract, node)
	var stat_difficulty_id := int(pressure_scale["monster_difficulty_id"])
	var content_difficulty_id := int(pressure_scale["content_difficulty_id"])
	var elite_variant := _select_elite_variant(seed, node) if node.node_type == ContractRouteNode.NodeType.ELITE else {}
	var boss_variant := _select_boss_variant(seed, node) if node.node_type == ContractRouteNode.NodeType.BOSS else {}
	_assign_elite_variant(node, elite_variant)
	_assign_boss_variant(node, boss_variant)
	var archetypes := _encounter_archetype_ids(seed, node, content_difficulty_id, monster_kind, library, elite_variant, boss_variant)
	var input_overrides := {
		"contract_hp_scaling": _contract_hp_scaling_for_encounter(contract, node),
		"contract_dps_scaling": _contract_dps_scaling_for_encounter(contract, node),
		"contract_armor_scaling": _contract_armor_scaling_for_encounter(contract, node),
		"contract_block_scaling": _contract_block_scaling_for_encounter(contract, node),
		"contract_absorb_scaling": _contract_absorb_scaling_for_encounter(contract, node),
		"mechanic_guardrails": _mechanic_guardrails_for_encounter(contract, node, pressure_scale),
	}
	var draft := _generate_with_pressure_retry(seed, node, archetypes, stat_difficulty_id, monster_kind, input_overrides, library)
	var preview: Dictionary = EncounterPreviewFormatterScript.format_generated(draft, {
		"biome": node.biome,
		"monster_name": node.monster_presentation_type,
		"encounter_level": _encounter_level(node),
	})
	node.generated_encounter_payload = draft.to_dictionary()
	node.generated_encounter_payload["route_pressure_scale"] = pressure_scale.duplicate(true)
	node.generated_encounter_payload["route_pressure_axes"] = _pressure_axis_profile(archetypes)
	_apply_elite_variant_payload(node)
	_apply_boss_variant_payload(node)
	node.route_preview = (preview.get("contract_map", {}) as Dictionary).duplicate(true)
	node.combat_preview = (preview.get("combat", {}) as Dictionary).duplicate(true)
	node.debug_preview = (preview.get("debug", {}) as Dictionary).duplicate(true)
	node.debug_preview["route_pressure_scale"] = pressure_scale.duplicate(true)
	node.debug_preview["route_pressure_axes"] = node.generated_encounter_payload["route_pressure_axes"].duplicate(true)
	node.debug_preview["branch_intent"] = node.branch_intent
	node.debug_preview["branch_intent_tags"] = Array(node.branch_intent_tags)
	node.generated_encounter_payload["branch_intent"] = node.branch_intent
	node.generated_encounter_payload["branch_intent_tags"] = Array(node.branch_intent_tags)
	_apply_elite_variant_previews(node)
	_apply_boss_variant_previews(node)
	_assign_node_modifiers(contract, node)
	for notice in draft.notices:
		node.generation_notices.append("%s:%s" % [notice.severity, notice.code])


static func _select_elite_variant(seed: int, node: ContractRouteNode) -> Dictionary:
	var rng := RunRng.rng_for_context(seed, RNG_CONTEXT, [
		GENERATOR_VERSION,
		"elite_variant",
		ELITE_VARIANT_MODEL_VERSION,
		node.generated_node_id,
	])
	var variant: Dictionary = ELITE_VARIANT_CATALOG[rng.randi_range(0, ELITE_VARIANT_CATALOG.size() - 1)]
	var out := variant.duplicate(true)
	out["model_version"] = ELITE_VARIANT_MODEL_VERSION
	return out


static func _select_boss_variant(seed: int, node: ContractRouteNode) -> Dictionary:
	var rng := RunRng.rng_for_context(seed, RNG_CONTEXT, [
		GENERATOR_VERSION,
		"boss_variant",
		BOSS_VARIANT_MODEL_VERSION,
		node.generated_node_id,
	])
	var variant: Dictionary = BOSS_VARIANT_CATALOG[rng.randi_range(0, BOSS_VARIANT_CATALOG.size() - 1)]
	var out := variant.duplicate(true)
	out["model_version"] = BOSS_VARIANT_MODEL_VERSION
	return out


static func _assign_elite_variant(node: ContractRouteNode, variant: Dictionary) -> void:
	if node.node_type != ContractRouteNode.NodeType.ELITE or variant.is_empty():
		return
	node.elite_variant_model_version = ELITE_VARIANT_MODEL_VERSION
	node.elite_variant_id = String(variant.get("id", ""))
	node.elite_variant_label = String(variant.get("label", ""))


static func _assign_boss_variant(node: ContractRouteNode, variant: Dictionary) -> void:
	if node.node_type != ContractRouteNode.NodeType.BOSS or variant.is_empty():
		return
	node.boss_variant_model_version = BOSS_VARIANT_MODEL_VERSION
	node.boss_variant_id = String(variant.get("id", ""))
	node.boss_variant_label = String(variant.get("label", ""))


static func _apply_elite_variant_payload(node: ContractRouteNode) -> void:
	if node.node_type != ContractRouteNode.NodeType.ELITE or node.elite_variant_id == "":
		return
	var variant := _elite_variant_by_id(node.elite_variant_id)
	node.generated_encounter_payload["elite_variant_model_version"] = node.elite_variant_model_version
	node.generated_encounter_payload["elite_variant_id"] = node.elite_variant_id
	node.generated_encounter_payload["elite_variant_label"] = node.elite_variant_label
	node.generated_encounter_payload["elite_variant_pressure_axis"] = String(variant.get("pressure_axis", ""))


static func _apply_boss_variant_payload(node: ContractRouteNode) -> void:
	if node.node_type != ContractRouteNode.NodeType.BOSS or node.boss_variant_id == "":
		return
	var variant := _boss_variant_by_id(node.boss_variant_id)
	node.generated_encounter_payload["boss_variant_model_version"] = node.boss_variant_model_version
	node.generated_encounter_payload["boss_variant_id"] = node.boss_variant_id
	node.generated_encounter_payload["boss_variant_label"] = node.boss_variant_label
	node.generated_encounter_payload["boss_variant_pressure_axis"] = String(variant.get("pressure_axis", ""))


static func _apply_elite_variant_previews(node: ContractRouteNode) -> void:
	if node.node_type != ContractRouteNode.NodeType.ELITE or node.elite_variant_id == "":
		return
	node.route_preview["elite_variant_label"] = node.elite_variant_label
	node.combat_preview["elite_variant_label"] = node.elite_variant_label
	node.debug_preview["elite_variant_model_version"] = node.elite_variant_model_version
	node.debug_preview["elite_variant_id"] = node.elite_variant_id
	node.debug_preview["elite_variant_label"] = node.elite_variant_label
	node.debug_preview["elite_variant"] = _elite_variant_by_id(node.elite_variant_id)


static func _apply_boss_variant_previews(node: ContractRouteNode) -> void:
	if node.node_type != ContractRouteNode.NodeType.BOSS or node.boss_variant_id == "":
		return
	node.route_preview["boss_variant_label"] = node.boss_variant_label
	node.combat_preview["boss_variant_label"] = node.boss_variant_label
	node.debug_preview["boss_variant_model_version"] = node.boss_variant_model_version
	node.debug_preview["boss_variant_id"] = node.boss_variant_id
	node.debug_preview["boss_variant_label"] = node.boss_variant_label
	node.debug_preview["boss_variant"] = _boss_variant_by_id(node.boss_variant_id)


static func _elite_variant_by_id(variant_id: String) -> Dictionary:
	for variant in ELITE_VARIANT_CATALOG:
		if String((variant as Dictionary).get("id", "")) == variant_id:
			return (variant as Dictionary).duplicate(true)
	return {}


static func _boss_variant_by_id(variant_id: String) -> Dictionary:
	for variant in BOSS_VARIANT_CATALOG:
		if String((variant as Dictionary).get("id", "")) == variant_id:
			return (variant as Dictionary).duplicate(true)
	return {}


static func _assign_node_modifiers(contract: ContractDef, node: ContractRouteNode) -> void:
	var ids := PackedStringArray()
	var labels := PackedStringArray()
	for modifier in contract.generated_modifiers:
		if _modifier_applies_to_node(modifier, node):
			ids.append(String(modifier.get("id", "")))
			labels.append(String(modifier.get("label", "")))
	node.generated_modifier_ids = ids
	node.generated_modifier_labels = labels
	node.generated_encounter_payload["route_modifier_ids"] = Array(contract.generated_modifier_ids)
	node.generated_encounter_payload["node_modifier_ids"] = Array(ids)
	node.generated_encounter_payload["modifier_model_version"] = contract.modifier_model_version
	node.combat_preview["modifier_labels"] = Array(labels)
	node.debug_preview["route_modifiers"] = contract.generated_modifiers.duplicate(true)
	node.debug_preview["node_modifier_ids"] = Array(ids)
	node.debug_preview["node_modifier_labels"] = Array(labels)
	node.debug_preview["modifier_model_version"] = contract.modifier_model_version
	if not labels.is_empty():
		node.route_preview["modifier_label"] = " / ".join(Array(labels))


static func _modifier_applies_to_node(modifier: Dictionary, node: ContractRouteNode) -> bool:
	if node == null or node.node_type == ContractRouteNode.NodeType.START:
		return false
	match String(modifier.get("preview_policy", "")):
		"matching_axis":
			var axis_profile: Dictionary = node.generated_encounter_payload.get("route_pressure_axes", {})
			return String(axis_profile.get("primary", "")) == String(modifier.get("axis", ""))
		"elite_and_boss":
			return node.node_type == ContractRouteNode.NodeType.ELITE or node.node_type == ContractRouteNode.NodeType.BOSS
		"matching_biome":
			return node.biome == String(modifier.get("biome", ""))
		"boss":
			return node.node_type == ContractRouteNode.NodeType.BOSS
	return false


## RuntimeMonsterGenerator's own pressure model can label a draft "over_band"
## (required DPS well outside the difficulty band's intended window) but
## nothing previously acted on that -- the draft still shipped as a real
## fight. Re-rolls with a deterministically-varied seed per attempt (attempt
## 0 always reuses the original, unsuffixed seed, so an already-in-tolerance
## encounter -- the common case -- generates byte-for-byte identically to
## before this retry loop existed) up to MAX_PRESSURE_RETRY_ATTEMPTS, keeping
## whichever attempt landed closest to its target_dps if none land in
## tolerance. A draft that fails validation for reasons other than pressure
## (missing library, bad archetype ids, ...) isn't retried -- those inputs
## don't vary with the seed, so a retry would just reproduce the same error.
static func _generate_with_pressure_retry(
	seed: int,
	node: ContractRouteNode,
	archetypes: Array,
	stat_difficulty_id: int,
	monster_kind: String,
	overrides: Dictionary,
	library: RuntimeArchetypeLibrary
) -> GeneratedMonsterDraft:
	var best_draft: GeneratedMonsterDraft = null
	var best_ratio_distance := INF
	for attempt in range(MAX_PRESSURE_RETRY_ATTEMPTS):
		var input := RuntimeGenerationInput.from_dictionary({
			"seed": _encounter_seed(seed, node.generated_node_id, attempt),
			"archetypeA": archetypes[0],
			"archetypeB": archetypes[1],
			"difficulty": stat_difficulty_id,
			"kind": monster_kind,
			"tempoProfile": _encounter_tempo_profile(seed, node, monster_kind),
			"overrides": overrides,
			"generatorVersion": RuntimeMonsterGenerator.GENERATOR_VERSION,
			"librarySchema": RuntimeArchetypeLibraryLoader.EXPECTED_SCHEMA,
		})
		var draft := RuntimeMonsterGenerator.generate(input, library)
		if String(draft.pressure_metadata.get("status", "")) != "over_band":
			return draft
		var ratio_distance := absf(float(draft.pressure_metadata.get("ratio", 1.0)) - 1.0)
		if best_draft == null or ratio_distance < best_ratio_distance:
			best_draft = draft
			best_ratio_distance = ratio_distance
	return best_draft


static func _encounter_seed(seed: int, node_id: String, attempt: int = 0) -> int:
	var parts := [
		GENERATOR_VERSION,
		"node_encounter",
		RuntimeMonsterGenerator.GENERATOR_VERSION,
		RuntimeArchetypeLibraryLoader.EXPECTED_SCHEMA,
		node_id,
	]
	if attempt > 0:
		parts.append("pressure_retry_%d" % attempt)
	return RunRng.seed_for_context(seed, RNG_CONTEXT, parts)


static func _encounter_difficulty_id(contract: ContractDef, node: ContractRouteNode) -> int:
	return int(_encounter_pressure_scale(contract, node)["monster_difficulty_id"])


static func _encounter_pressure_scale(contract: ContractDef, node: ContractRouteNode) -> Dictionary:
	var explicit_id := int(contract.route_settings.get("encounter_difficulty_id", 0))
	if explicit_id > 0:
		var clamped_explicit := clampi(explicit_id, 1, MAX_MONSTER_DIFFICULTY_ID)
		return {
			"raw_difficulty_id": explicit_id,
			"monster_difficulty_id": clamped_explicit,
			"content_difficulty_id": clamped_explicit,
			"contract_pressure_tier": maxi(0, explicit_id - MAX_MONSTER_DIFFICULTY_ID),
			"route_difficulty_base": clamped_explicit,
			"effective_contract_difficulty_id": clamped_explicit,
			"effective_contract_difficulty_label": _difficulty_label_for_id(clamped_explicit),
			"next_contract_difficulty_id": clamped_explicit,
			"next_contract_difficulty_label": _difficulty_label_for_id(clamped_explicit),
			"contract_progression_stage": 1,
			"contract_progression_stage_count": CONTRACT_PROGRESSION_STAGE_COUNT,
			"content_promotion_reason": "explicit_difficulty",
			"depth_bonus": 0,
			"node_level_bonus": 0,
			"completed_contract_pressure_bonus": 0,
			"completed_contract_count": 0,
			"overcap_pressure": maxi(0, explicit_id - MAX_MONSTER_DIFFICULTY_ID),
			"monster_level": _node_kind(node),
			"monster_difficulty_cap": MAX_MONSTER_DIFFICULTY_ID,
		}

	var route_label := String(contract.route_settings.get("route_difficulty", contract.route_difficulty)).to_lower()
	var base := int(ROUTE_DIFFICULTY_IDS.get(route_label, ROUTE_DIFFICULTY_IDS[DEFAULT_ROUTE_DIFFICULTY]))
	var progression := _contract_progression(contract)
	var depth_bonus := _stat_depth_pressure_bonus(node)
	var completed_bonus := 0
	var kind_bonus := _stat_kind_pressure_bonus(node, int(progression["stage"]))
	var effective_contract_id := int(progression["effective_contract_difficulty_id"])
	var raw_difficulty := effective_contract_id + depth_bonus + kind_bonus
	var content_difficulty_id := _content_difficulty_id_for_node(node, progression)
	return {
		"raw_difficulty_id": raw_difficulty,
		"monster_difficulty_id": clampi(raw_difficulty, 1, MAX_MONSTER_DIFFICULTY_ID),
		"content_difficulty_id": content_difficulty_id,
		"contract_pressure_tier": maxi(0, raw_difficulty - MAX_MONSTER_DIFFICULTY_ID),
		"route_difficulty_base": base,
		"effective_contract_difficulty_id": int(progression["effective_contract_difficulty_id"]),
		"effective_contract_difficulty_label": String(progression["effective_contract_difficulty_label"]),
		"next_contract_difficulty_id": int(progression["next_contract_difficulty_id"]),
		"next_contract_difficulty_label": String(progression["next_contract_difficulty_label"]),
		"contract_progression_stage": int(progression["stage"]),
		"contract_progression_stage_count": CONTRACT_PROGRESSION_STAGE_COUNT,
		"content_promotion_reason": _content_promotion_reason(node, progression, content_difficulty_id),
		"legacy_route_difficulty_base": base,
		"depth_bonus": depth_bonus,
		"node_level_bonus": kind_bonus,
		"completed_contract_pressure_bonus": completed_bonus,
		"completed_contract_count": int(progression["completed_contract_count"]),
		"overcap_pressure": maxi(0, raw_difficulty - MAX_MONSTER_DIFFICULTY_ID),
		"monster_level": _node_kind(node),
		"monster_difficulty_cap": MAX_MONSTER_DIFFICULTY_ID,
	}


static func _contract_progression(contract: ContractDef) -> Dictionary:
	var route_label := String(contract.route_settings.get("route_difficulty", contract.route_difficulty)).to_lower()
	return _progression_for(route_label, int(contract.route_settings.get("completed_contract_count", 0)))


static func _route_progression_from_settings(route_settings: Dictionary) -> Dictionary:
	var route_label := String(route_settings.get("route_difficulty", DEFAULT_ROUTE_DIFFICULTY)).to_lower()
	return _progression_for(route_label, int(route_settings.get("completed_contract_count", 0)))


static func _progression_for(route_label: String, completed_contract_count: int) -> Dictionary:
	var base_id := int(ROUTE_DIFFICULTY_IDS.get(route_label, ROUTE_DIFFICULTY_IDS[DEFAULT_ROUTE_DIFFICULTY]))
	var completed_count := maxi(0, completed_contract_count)
	var band_steps := int(floor(float(completed_count) / float(CONTRACT_PROGRESSION_STAGE_COUNT)))
	var raw_effective_id := base_id + band_steps
	var effective_id := clampi(raw_effective_id, 1, MAX_MONSTER_DIFFICULTY_ID)
	var next_id := clampi(effective_id + 1, 1, MAX_MONSTER_DIFFICULTY_ID)
	return {
		"base_difficulty_id": base_id,
		"base_difficulty_label": _difficulty_label_for_id(base_id),
		"completed_contract_count": completed_count,
		"stage": completed_count % CONTRACT_PROGRESSION_STAGE_COUNT + 1,
		"effective_contract_difficulty_id": effective_id,
		"effective_contract_difficulty_label": _difficulty_label_for_id(effective_id),
		"next_contract_difficulty_id": next_id,
		"next_contract_difficulty_label": _difficulty_label_for_id(next_id),
		"stat_pressure_bonus": _completed_contract_pressure_bonus_from_count(completed_count),
		"band_overcap": maxi(0, raw_effective_id - MAX_MONSTER_DIFFICULTY_ID),
	}


static func _content_difficulty_id_for_node(node: ContractRouteNode, progression: Dictionary) -> int:
	var effective_id := int(progression["effective_contract_difficulty_id"])
	var next_id := int(progression["next_contract_difficulty_id"])
	if next_id <= effective_id:
		return effective_id
	if _node_promotes_to_next_content_band(node, int(progression["stage"])):
		return next_id
	return effective_id


static func _node_promotes_to_next_content_band(node: ContractRouteNode, stage: int) -> bool:
	if node == null:
		return false
	if stage >= 3 and node.node_type == ContractRouteNode.NodeType.BOSS:
		return true
	if stage >= 4 and node.node_type == ContractRouteNode.NodeType.ELITE:
		return true
	if stage >= 5 and node.node_type == ContractRouteNode.NodeType.CAPTAIN:
		return true
	return false


static func _content_promotion_reason(node: ContractRouteNode, progression: Dictionary, content_difficulty_id: int) -> String:
	if content_difficulty_id <= int(progression["effective_contract_difficulty_id"]):
		return "current_band"
	if node == null:
		return "current_band"
	match node.node_type:
		ContractRouteNode.NodeType.BOSS:
			return "stage_3_boss_next_band"
		ContractRouteNode.NodeType.ELITE:
			return "stage_4_elite_next_band"
		ContractRouteNode.NodeType.CAPTAIN:
			return "stage_5_captain_next_band"
	return "current_band"


static func _difficulty_label_for_id(difficulty_id: int) -> String:
	return String(ROUTE_DIFFICULTY_LABELS_BY_ID.get(clampi(difficulty_id, 1, MAX_MONSTER_DIFFICULTY_ID), DEFAULT_ROUTE_DIFFICULTY))


static func _depth_pressure_bonus(node: ContractRouteNode) -> int:
	return maxi(0, int(floor(float(node.depth - 1) / 2.0)))


static func _stat_depth_pressure_bonus(node: ContractRouteNode) -> int:
	if node == null:
		return 0
	if node.node_type == ContractRouteNode.NodeType.BOSS:
		return 0
	return mini(1, _depth_pressure_bonus(node))


static func _stat_kind_pressure_bonus(node: ContractRouteNode, stage: int) -> int:
	if node == null:
		return 0
	match node.node_type:
		ContractRouteNode.NodeType.CAPTAIN:
			return 1 if stage >= 5 else 0
		ContractRouteNode.NodeType.ELITE:
			return 1
		ContractRouteNode.NodeType.BOSS:
			return 2 if stage >= 4 else 1
	return 0


static func _mechanic_guardrails_for_encounter(contract: ContractDef, node: ContractRouteNode, pressure_scale: Dictionary) -> Dictionary:
	var completed_count := maxi(0, int(contract.route_settings.get("completed_contract_count", 0)))
	if completed_count > 2:
		return {}
	var max_hard_counters := 2
	if node.node_type == ContractRouteNode.NodeType.BOSS:
		max_hard_counters = 3
	return {
		"id": "early_contract_c1_c3",
		"completed_contract_count": completed_count,
		"contract_number": completed_count + 1,
		"max_hard_counters": max_hard_counters,
		"caps": {
			"cleanse_threshold": {"min": 4},
			"suppress": {"max": 45},
			"poison_resistance": {"max": 35},
			"slow": {"max": 25},
			"block": {"max": _early_contract_block_cap(completed_count + 1, node)},
			"absorb": {"max": _early_contract_absorb_cap(completed_count + 1, node)},
		},
		"combo_rules": {
			"avoid_poison_triple": true,
			"avoid_physical_triple": true,
			"avoid_timing_triple": true,
		},
		"stat_difficulty_id": int(pressure_scale.get("monster_difficulty_id", 0)),
		"content_difficulty_id": int(pressure_scale.get("content_difficulty_id", 0)),
	}


static func _early_contract_block_cap(contract_number: int, node: ContractRouteNode) -> int:
	var role := _node_kind(node)
	if contract_number <= 1:
		match role:
			"captain":
				return 7
			"elite":
				return 9
			"boss":
				return 10
		return 5
	if contract_number == 2:
		match role:
			"captain":
				return 9
			"elite":
				return 10
			"boss":
				return 12
		return 7
	match role:
		"captain":
			return 10
		"elite":
			return 12
		"boss":
			return 14
	return 8


static func _early_contract_absorb_cap(contract_number: int, node: ContractRouteNode) -> int:
	var role := _node_kind(node)
	if contract_number <= 1:
		match role:
			"captain":
				return 4
			"elite":
				return 5
			"boss":
				return 7
		return 3
	if contract_number == 2:
		match role:
			"captain":
				return 5
			"elite":
				return 7
			"boss":
				return 8
		return 4
	match role:
		"captain":
			return 7
		"elite":
			return 8
		"boss":
			return 10
	return 5


static func _contract_hp_scaling_for_encounter(contract: ContractDef, node: ContractRouteNode) -> Dictionary:
	var completed_count := maxi(0, int(contract.route_settings.get("completed_contract_count", 0)))
	var contract_number := completed_count + 1
	var contract_multiplier := _contract_hp_multiplier_for_number(contract_number)
	var role_scale := _contract_hp_role_scale(node)
	var final_multiplier := 1.0 + (contract_multiplier - 1.0) * role_scale
	return {
		"id": "contract_hp_curve_v2",
		"contract_number": contract_number,
		"completed_contract_count": completed_count,
		"contract_multiplier": contract_multiplier,
		"role_scale": role_scale,
		"multiplier": final_multiplier,
	}


static func _contract_hp_multiplier_for_number(contract_number: int) -> float:
	var anchors := [
		{"contract": 1, "multiplier": 1.0},
		{"contract": 5, "multiplier": 1.4},
		{"contract": 10, "multiplier": 2.3},
		{"contract": 15, "multiplier": 3.8},
		{"contract": 20, "multiplier": 6.0},
		{"contract": 25, "multiplier": 9.0},
		{"contract": 30, "multiplier": 13.0},
	]
	var clamped_contract := maxi(1, contract_number)
	for index in range(anchors.size() - 1):
		var start: Dictionary = anchors[index]
		var finish: Dictionary = anchors[index + 1]
		var start_contract := int(start["contract"])
		var finish_contract := int(finish["contract"])
		if clamped_contract > finish_contract:
			continue
		var span := float(finish_contract - start_contract)
		var progress := clampf(float(clamped_contract - start_contract) / maxf(1.0, span), 0.0, 1.0)
		return lerpf(float(start["multiplier"]), float(finish["multiplier"]), progress)
	return float(anchors[anchors.size() - 1]["multiplier"])


static func _contract_hp_role_scale(node: ContractRouteNode) -> float:
	if node == null:
		return 1.0
	match node.node_type:
		ContractRouteNode.NodeType.FIGHT:
			return 1.0
		ContractRouteNode.NodeType.CAPTAIN:
			return 1.1
		ContractRouteNode.NodeType.ELITE:
			return 1.25
		ContractRouteNode.NodeType.BOSS:
			return 1.25
	return 1.0


static func _contract_dps_scaling_for_encounter(contract: ContractDef, node: ContractRouteNode) -> Dictionary:
	var completed_count := maxi(0, int(contract.route_settings.get("completed_contract_count", 0)))
	var contract_number := completed_count + 1
	var contract_multiplier := _contract_dps_multiplier_for_number(contract_number)
	var role_scale := _contract_dps_role_scale(node)
	var final_multiplier := 1.0 + (contract_multiplier - 1.0) * role_scale
	return {
		"id": "contract_dps_curve_v1",
		"contract_number": contract_number,
		"completed_contract_count": completed_count,
		"contract_multiplier": contract_multiplier,
		"role_scale": role_scale,
		"multiplier": final_multiplier,
		"min_hp_budget_duration_sec": _minimum_hp_budget_duration_for_number(contract_number),
	}


static func _contract_dps_multiplier_for_number(contract_number: int) -> float:
	var anchors := [
		{"contract": 1, "multiplier": 1.0},
		{"contract": 5, "multiplier": 1.8},
		{"contract": 10, "multiplier": 3.5},
		{"contract": 15, "multiplier": 6.0},
		{"contract": 20, "multiplier": 10.0},
		{"contract": 25, "multiplier": 16.0},
		{"contract": 30, "multiplier": 25.0},
	]
	return _interpolated_contract_multiplier(maxi(1, contract_number), anchors)


static func _minimum_hp_budget_duration_for_number(contract_number: int) -> float:
	if contract_number <= 3:
		return 18.0
	if contract_number <= 10:
		return 22.0
	if contract_number <= 20:
		return 26.0
	return 30.0


static func _contract_dps_role_scale(node: ContractRouteNode) -> float:
	if node == null:
		return 1.0
	match node.node_type:
		ContractRouteNode.NodeType.FIGHT:
			return 0.85
		ContractRouteNode.NodeType.CAPTAIN:
			return 1.0
		ContractRouteNode.NodeType.ELITE:
			return 1.2
		ContractRouteNode.NodeType.BOSS:
			return 1.5
	return 1.0


static func _contract_armor_scaling_for_encounter(contract: ContractDef, node: ContractRouteNode) -> Dictionary:
	var completed_count := maxi(0, int(contract.route_settings.get("completed_contract_count", 0)))
	var contract_number := completed_count + 1
	var contract_multiplier := _contract_armor_multiplier_for_number(contract_number)
	var role_scale := _contract_armor_role_scale(node)
	var final_multiplier := 1.0 + (contract_multiplier - 1.0) * role_scale
	return {
		"id": "contract_armor_curve_v1",
		"contract_number": contract_number,
		"completed_contract_count": completed_count,
		"contract_multiplier": contract_multiplier,
		"role_scale": role_scale,
		"multiplier": final_multiplier,
	}


static func _contract_armor_multiplier_for_number(contract_number: int) -> float:
	var anchors := [
		{"contract": 1, "multiplier": 1.0},
		{"contract": 5, "multiplier": 1.6},
		{"contract": 10, "multiplier": 2.8},
		{"contract": 15, "multiplier": 4.8},
		{"contract": 20, "multiplier": 7.5},
		{"contract": 25, "multiplier": 11.0},
		{"contract": 30, "multiplier": 16.0},
	]
	return _interpolated_contract_multiplier(maxi(1, contract_number), anchors)


static func _contract_armor_role_scale(node: ContractRouteNode) -> float:
	if node == null:
		return 1.0
	match node.node_type:
		ContractRouteNode.NodeType.FIGHT:
			return 0.75
		ContractRouteNode.NodeType.CAPTAIN:
			return 1.0
		ContractRouteNode.NodeType.ELITE:
			return 1.2
		ContractRouteNode.NodeType.BOSS:
			return 1.35
	return 1.0


static func _contract_block_scaling_for_encounter(contract: ContractDef, node: ContractRouteNode) -> Dictionary:
	var completed_count := maxi(0, int(contract.route_settings.get("completed_contract_count", 0)))
	var contract_number := completed_count + 1
	var contract_multiplier := _contract_block_multiplier_for_number(contract_number)
	var role_scale := _contract_block_role_scale(node)
	var final_multiplier := 1.0 + (contract_multiplier - 1.0) * role_scale
	return {
		"id": "contract_block_curve_v1",
		"contract_number": contract_number,
		"completed_contract_count": completed_count,
		"contract_multiplier": contract_multiplier,
		"role_scale": role_scale,
		"multiplier": final_multiplier,
	}


static func _contract_block_multiplier_for_number(contract_number: int) -> float:
	var anchors := [
		{"contract": 1, "multiplier": 1.0},
		{"contract": 5, "multiplier": 1.4},
		{"contract": 10, "multiplier": 2.4},
		{"contract": 15, "multiplier": 4.0},
		{"contract": 20, "multiplier": 6.2},
		{"contract": 25, "multiplier": 9.0},
		{"contract": 30, "multiplier": 13.0},
	]
	return _interpolated_contract_multiplier(maxi(1, contract_number), anchors)


static func _contract_block_role_scale(node: ContractRouteNode) -> float:
	if node == null:
		return 1.0
	match node.node_type:
		ContractRouteNode.NodeType.FIGHT:
			return 0.55
		ContractRouteNode.NodeType.CAPTAIN:
			return 0.75
		ContractRouteNode.NodeType.ELITE:
			return 1.0
		ContractRouteNode.NodeType.BOSS:
			return 1.2
	return 1.0


static func _contract_absorb_scaling_for_encounter(contract: ContractDef, node: ContractRouteNode) -> Dictionary:
	var completed_count := maxi(0, int(contract.route_settings.get("completed_contract_count", 0)))
	var contract_number := completed_count + 1
	var contract_multiplier := _contract_absorb_multiplier_for_number(contract_number)
	var role_scale := _contract_absorb_role_scale(node)
	var final_multiplier := 1.0 + (contract_multiplier - 1.0) * role_scale
	return {
		"id": "contract_absorb_curve_v1",
		"contract_number": contract_number,
		"completed_contract_count": completed_count,
		"contract_multiplier": contract_multiplier,
		"role_scale": role_scale,
		"multiplier": final_multiplier,
	}


static func _contract_absorb_multiplier_for_number(contract_number: int) -> float:
	var anchors := [
		{"contract": 1, "multiplier": 1.0},
		{"contract": 5, "multiplier": 1.4},
		{"contract": 10, "multiplier": 2.4},
		{"contract": 15, "multiplier": 4.0},
		{"contract": 20, "multiplier": 6.2},
		{"contract": 25, "multiplier": 9.0},
		{"contract": 30, "multiplier": 13.0},
	]
	return _interpolated_contract_multiplier(maxi(1, contract_number), anchors)


static func _contract_absorb_role_scale(node: ContractRouteNode) -> float:
	if node == null:
		return 1.0
	match node.node_type:
		ContractRouteNode.NodeType.FIGHT:
			return 0.55
		ContractRouteNode.NodeType.CAPTAIN:
			return 0.75
		ContractRouteNode.NodeType.ELITE:
			return 1.0
		ContractRouteNode.NodeType.BOSS:
			return 1.2
	return 1.0


static func _interpolated_contract_multiplier(contract_number: int, anchors: Array) -> float:
	for index in range(anchors.size() - 1):
		var start: Dictionary = anchors[index]
		var finish: Dictionary = anchors[index + 1]
		var start_contract := int(start["contract"])
		var finish_contract := int(finish["contract"])
		if contract_number > finish_contract:
			continue
		var span := float(finish_contract - start_contract)
		var progress := clampf(float(contract_number - start_contract) / maxf(1.0, span), 0.0, 1.0)
		return lerpf(float(start["multiplier"]), float(finish["multiplier"]), progress)
	return float(anchors[anchors.size() - 1]["multiplier"])


static func _completed_contract_pressure_bonus(contract: ContractDef) -> int:
	var completed_count := maxi(0, int(contract.route_settings.get("completed_contract_count", 0)))
	return _completed_contract_pressure_bonus_from_count(completed_count)


static func _completed_contract_pressure_bonus_from_count(completed_count: int) -> int:
	var tier := int(floor(float(completed_count + 1) / float(COMPLETED_CONTRACT_PRESSURE_STEP)))
	return maxi(0, tier)


static func _encounter_tempo_profile(seed: int, node: ContractRouteNode, monster_kind: String) -> String:
	var pool := ["burst", "standard", "extended"]
	if monster_kind == "elite":
		pool = ["standard", "extended"]
	elif monster_kind == "boss":
		pool = ["extended", "endurance"]
	var rng := RunRng.rng_for_context(seed, RNG_CONTEXT, [GENERATOR_VERSION, "node_encounter_tempo", node.generated_node_id])
	return String(pool[rng.randi_range(0, pool.size() - 1)])


static func _encounter_archetype_ids(
	seed: int,
	node: ContractRouteNode,
	difficulty_id: int,
	monster_kind: String,
	library: RuntimeArchetypeLibrary,
	elite_variant: Dictionary = {},
	boss_variant: Dictionary = {}
) -> PackedStringArray:
	var available: Array[RuntimeArchetypeDef] = library.available_for(difficulty_id, monster_kind) if library != null else []
	if available.is_empty():
		return PackedStringArray(["fortified", ""])

	var rng := RunRng.rng_for_context(seed, RNG_CONTEXT, [GENERATOR_VERSION, "node_encounter_archetypes", node.generated_node_id])
	var variant := boss_variant if monster_kind == "boss" else elite_variant if monster_kind == "elite" else {}
	var primary: RuntimeArchetypeDef = _available_archetype_by_id(available, String(variant.get("primary_archetype", "")))
	if primary == null:
		primary = available[rng.randi_range(0, available.size() - 1)]
	var secondary_id := ""
	var wants_secondary := monster_kind == "boss" or monster_kind == "elite" or (monster_kind == "normal" and difficulty_id >= 3 and rng.randi_range(0, 1) == 0)
	if wants_secondary and available.size() > 1:
		var secondary: RuntimeArchetypeDef = _available_archetype_by_id(available, String(variant.get("secondary_archetype", "")))
		if secondary == null:
			secondary = available[rng.randi_range(0, available.size() - 1)]
		var attempts := 0
		while secondary.id == primary.id and attempts < 5:
			secondary = available[rng.randi_range(0, available.size() - 1)]
			attempts += 1
		if secondary.id != primary.id:
			secondary_id = secondary.id
	return PackedStringArray([primary.id, secondary_id])


static func _available_archetype_by_id(available: Array[RuntimeArchetypeDef], archetype_id: String) -> RuntimeArchetypeDef:
	if archetype_id == "":
		return null
	for archetype in available:
		if archetype.id == archetype_id:
			return archetype
	return null


static func _pressure_axis_profile(archetype_ids: PackedStringArray) -> Dictionary:
	var axes := PackedStringArray()
	var sources := PackedStringArray()
	for archetype_id in archetype_ids:
		var id := String(archetype_id)
		if id == "":
			continue
		sources.append(id)
		var axis := String(PRESSURE_AXIS_BY_ARCHETYPE.get(id, PRESSURE_AXIS_MIXED))
		if not axes.has(axis):
			axes.append(axis)
	if axes.is_empty():
		axes.append(PRESSURE_AXIS_MIXED)
	var primary := String(axes[0])
	var secondary := ""
	for axis in axes:
		if String(axis) != primary:
			secondary = String(axis)
			break
	return {
		"primary": primary,
		"secondary": secondary,
		"axes": Array(axes),
		"source_archetype_ids": Array(sources),
	}


static func _archetype_tags(seed: int, node: ContractRouteNode) -> PackedStringArray:
	var rng := RunRng.rng_for_context(seed, RNG_CONTEXT, [GENERATOR_VERSION, "node_preview", node.depth])
	var offset := rng.randi_range(0, ARCHETYPE_TAG_SETS.size() - 1)
	var index := (offset + node.lane) % ARCHETYPE_TAG_SETS.size()
	return PackedStringArray(ARCHETYPE_TAG_SETS[index])


static func _presentation_kind(node: ContractRouteNode) -> String:
	match node.node_type:
		ContractRouteNode.NodeType.CAPTAIN:
			return "captain"
		ContractRouteNode.NodeType.ELITE:
			return "elite"
		ContractRouteNode.NodeType.BOSS:
			return "boss"
	return "normal"


static func _node_kind(node: ContractRouteNode) -> String:
	match node.node_type:
		ContractRouteNode.NodeType.ELITE:
			return "elite"
		ContractRouteNode.NodeType.BOSS:
			return "boss"
	return "normal"


static func _encounter_level(node: ContractRouteNode) -> String:
	match node.node_type:
		ContractRouteNode.NodeType.CAPTAIN:
			return "Captain"
		ContractRouteNode.NodeType.ELITE:
			return "Elite"
		ContractRouteNode.NodeType.BOSS:
			return "Boss"
	return "Normal"


static func _assign_generated_reward(seed: int, contract: ContractDef, node: ContractRouteNode) -> void:
	if node.node_type == ContractRouteNode.NodeType.START:
		return
	var role := _reward_role(node)
	var table: Dictionary = REWARD_TABLE[role]
	var pressure := _reward_pressure_bonus(contract)
	var reward := EncounterReward.new()
	reward.gold_amount = _reward_gold_amount(table, node, pressure)
	reward.talent_points = _reward_talent_points(contract, table, node)
	reward.generated_gear_choice_count = int(table.get("gear_choice_count", 0))
	reward.generated_gear_tier = _reward_gear_tier(contract, node, role)
	reward.generated_gear_slots = _reward_gear_slots(seed, node, role)
	node.reward = reward
	node.reward_quality_label = String(table.get("quality", role.capitalize()))
	node.reward_summary = _reward_summary(reward)


static func _reward_role(node: ContractRouteNode) -> String:
	match node.node_type:
		ContractRouteNode.NodeType.CAPTAIN:
			return "captain"
		ContractRouteNode.NodeType.ELITE:
			return "elite"
		ContractRouteNode.NodeType.BOSS:
			return "boss"
	return "normal"


static func _reward_pressure_bonus(contract: ContractDef) -> int:
	return _completed_contract_pressure_bonus(contract)


static func _reward_gold_amount(table: Dictionary, node: ContractRouteNode, pressure: int) -> int:
	return (
		int(table.get("gold_base", 0))
		+ maxi(0, node.depth - 1) * int(table.get("gold_depth_step", 0))
		+ pressure * int(table.get("gold_pressure_step", 0))
		+ int(floor(float(maxi(0, node.lane)) / 2.0))
		+ _reward_intent_gold_bonus(node)
	)


static func _reward_intent_gold_bonus(node: ContractRouteNode) -> int:
	if node.branch_intent_tags.has("high_reward"):
		return 3
	if node.branch_intent_tags.has("risky"):
		return 2
	return 0


static func _reward_talent_points(contract: ContractDef, table: Dictionary, node: ContractRouteNode) -> int:
	if int(contract.route_settings.get("earned_talent_points", 0)) >= TALENT_POINT_REWARD_CAP:
		return 0
	if table.has("talent_points"):
		return int(table["talent_points"])
	var threshold := int(table.get("talent_depth_threshold", 999))
	return 1 if node.depth >= threshold else 0


static func _reward_gear_tier(contract: ContractDef, node: ContractRouteNode, role: String) -> GearItem.Tier:
	var difficulty_id := _encounter_difficulty_id(contract, node)
	return _reward_gear_tier_for_difficulty(difficulty_id, role)


static func _reward_gear_tier_for_difficulty(difficulty_id: int, role: String) -> GearItem.Tier:
	var score := difficulty_id
	if role == "boss":
		score += 2
	elif role == "elite":
		score += 1
	if score >= 6:
		return GearItem.Tier.CURSED
	if score >= 4:
		return GearItem.Tier.MASTER
	return GearItem.Tier.BASIC


static func _reward_gear_slots(seed: int, node: ContractRouteNode, role: String) -> Array[int]:
	var slots: Array[int] = []
	var pool: Array[int] = []
	for slot in GearGenerator.ALL_SLOTS:
		pool.append(slot)
	if role == "boss":
		return pool
	var count := 2 if role == "elite" else 1
	var rng := RunRng.rng_for_context(seed, RNG_CONTEXT, [GENERATOR_VERSION, "node_reward_slots", REWARD_TABLE_VERSION, node.generated_node_id])
	while slots.size() < count and not pool.is_empty():
		var index := rng.randi_range(0, pool.size() - 1)
		slots.append(pool[index])
		pool.remove_at(index)
	slots.sort()
	return slots


static func _reward_summary(reward: EncounterReward) -> String:
	if reward == null:
		return ""
	var parts := PackedStringArray()
	if reward.generated_gear_choice_count > 0:
		parts.append("%s gear choice" % GearGenerator.tier_name(reward.generated_gear_tier))
	if reward.talent_points > 0:
		parts.append("%d talent point%s" % [reward.talent_points, "" if reward.talent_points == 1 else "s"])
	if reward.gold_amount > 0:
		parts.append("%dg" % reward.gold_amount)
	return " + ".join(parts)


static func _collect_nodes(start: ContractRouteNode) -> Array[ContractRouteNode]:
	var result: Array[ContractRouteNode] = []
	var visited := {}
	_collect_nodes_recursive(start, visited, result)
	result.sort_custom(func(a: ContractRouteNode, b: ContractRouteNode): return a.depth < b.depth if a.depth != b.depth else a.lane < b.lane)
	return result


static func _collect_nodes_recursive(node: ContractRouteNode, visited: Dictionary, result: Array[ContractRouteNode]) -> void:
	if node == null or visited.has(node.generated_node_id):
		return
	visited[node.generated_node_id] = true
	result.append(node)
	for next_node in node.next_nodes:
		_collect_nodes_recursive(next_node, visited, result)


static func _enumerate_paths(start: ContractRouteNode, boss: ContractRouteNode) -> Array:
	var paths := []
	_collect_paths(start, boss, {}, [], paths)
	return paths


static func _collect_paths(node: ContractRouteNode, boss: ContractRouteNode, visited: Dictionary, path: Array, paths: Array) -> void:
	if node == null:
		return
	if visited.has(node.generated_node_id):
		return
	var next_path := path.duplicate()
	next_path.append(node)
	if node == boss:
		paths.append(next_path)
		return
	var next_visited := visited.duplicate()
	next_visited[node.generated_node_id] = true
	for next_node in node.next_nodes:
		_collect_paths(next_node, boss, next_visited, next_path, paths)


static func _validate_path_pacing(paths: Array, settings: Dictionary, notices: PackedStringArray) -> void:
	if paths.is_empty():
		notices.append("path_missing")
		return
	var min_path_length := int(settings.get("min_path_length", DEFAULT_SETTINGS["min_path_length"]))
	var max_path_length := int(settings.get("max_path_length", DEFAULT_SETTINGS["max_path_length"]))
	var shortest_path_max := int(settings.get("shortest_path_max", DEFAULT_SETTINGS["shortest_path_max"]))
	var longest_path_min := int(settings.get("longest_path_min", DEFAULT_SETTINGS["longest_path_min"]))
	var shortest := 999
	var longest := 0
	for path in paths:
		var committed_length := _committed_path_length(path)
		shortest = mini(shortest, committed_length)
		longest = maxi(longest, committed_length)
		if committed_length < min_path_length:
			notices.append("path_too_short:%d" % committed_length)
		if committed_length > max_path_length:
			notices.append("path_too_long:%d" % committed_length)
	if shortest > shortest_path_max:
		notices.append("shortest_path_too_long:%d" % shortest)
	if longest < longest_path_min:
		notices.append("longest_path_too_short:%d" % longest)


static func _validate_elite_pacing(start: ContractRouteNode, paths: Array, notices: PackedStringArray) -> void:
	if start != null and not start.next_nodes.is_empty():
		var all_openers_elite := true
		for next_node in start.next_nodes:
			if next_node.node_type != ContractRouteNode.NodeType.ELITE:
				all_openers_elite = false
				break
		if all_openers_elite:
			notices.append("forced_elite_opener")

	var shortest_length := 999
	var shortest_elite_count := 0
	for path in paths:
		var committed_length := _committed_path_length(path)
		var elite_count := _elite_count(path)
		if committed_length < shortest_length:
			shortest_length = committed_length
			shortest_elite_count = elite_count
		if _has_back_to_back_elites(path):
			notices.append("back_to_back_elites:%s" % _path_id_signature(path))
	if shortest_elite_count > 1:
		notices.append("elite_shortest_path_over_limit:%d" % shortest_elite_count)


static func _validate_branch_quality(nodes: Array[ContractRouteNode], notices: PackedStringArray) -> void:
	for node in nodes:
		if node.next_nodes.size() <= 1:
			continue
		var signatures := {}
		var has_elite := false
		var has_non_elite := false
		for next_node in node.next_nodes:
			signatures[_branch_preview_signature(next_node)] = true
			if next_node.node_type == ContractRouteNode.NodeType.ELITE:
				has_elite = true
			else:
				has_non_elite = true
		if signatures.size() < node.next_nodes.size():
			notices.append("branch_preview_not_distinct:%s" % node.generated_node_id)
		if has_elite and not has_non_elite:
			notices.append("elite_branch_without_alternative:%s" % node.generated_node_id)


static func _validate_branch_intent_tradeoffs(nodes: Array[ContractRouteNode], notices: PackedStringArray) -> void:
	var tradeoff_seen := false
	for node in nodes:
		if node.next_nodes.size() <= 1:
			continue
		var has_safe := false
		var has_risky := false
		var has_high_reward := false
		var missing_intent := false
		var lowest_risk := 999
		var highest_risk := -999
		var lowest_gold := 999999
		var highest_gold := -999999
		for next_node in node.next_nodes:
			if next_node == null or next_node.node_type == ContractRouteNode.NodeType.START:
				continue
			if next_node.branch_intent == "" or next_node.branch_intent_tags.is_empty():
				missing_intent = true
			has_safe = has_safe or next_node.branch_intent_tags.has("safe")
			has_risky = has_risky or next_node.branch_intent_tags.has("risky")
			has_high_reward = has_high_reward or next_node.branch_intent_tags.has("high_reward")
			var risk := _branch_risk_score(next_node)
			lowest_risk = mini(lowest_risk, risk)
			highest_risk = maxi(highest_risk, risk)
			var gold := next_node.reward.gold_amount if next_node.reward != null else 0
			lowest_gold = mini(lowest_gold, gold)
			highest_gold = maxi(highest_gold, gold)
		if missing_intent:
			notices.append("branch_intent_missing:%s" % node.generated_node_id)
		if has_safe and (has_risky or has_high_reward):
			if highest_risk > lowest_risk or highest_gold - lowest_gold >= 6:
				tradeoff_seen = true
	if not tradeoff_seen:
		notices.append("safe_risky_tradeoff_missing")


static func _validate_elite_detour_and_pressure_gauntlet(
	nodes: Array[ContractRouteNode],
	paths: Array,
	notices: PackedStringArray
) -> void:
	var elite_detour_nodes := 0
	var pressure_gauntlet_nodes := 0
	for node in nodes:
		if node.branch_intent_tags.has("elite_detour"):
			elite_detour_nodes += 1
		if node.branch_intent_tags.has("pressure_gauntlet"):
			pressure_gauntlet_nodes += 1
	if elite_detour_nodes > 0:
		_validate_optional_elite_detour(paths, notices)
	if pressure_gauntlet_nodes > 0:
		_validate_pressure_gauntlet_paths(paths, notices)


static func _validate_wide_matchup_and_fork_rejoin(
	nodes: Array[ContractRouteNode],
	boss_node: ContractRouteNode,
	notices: PackedStringArray
) -> void:
	var wide_matchup_nodes := 0
	var fork_rejoin_nodes := 0
	for node in nodes:
		if node.branch_intent_tags.has("wide_matchup_choice"):
			wide_matchup_nodes += 1
		if node.branch_intent_tags.has("fork_rejoin"):
			fork_rejoin_nodes += 1
	if wide_matchup_nodes > 0 and not _has_wide_matchup_choice(nodes):
		notices.append("wide_matchup_choice_missing")
	if fork_rejoin_nodes > 0 and not _has_fork_rejoin_branch(nodes, boss_node):
		notices.append("fork_rejoin_missing")


static func _has_wide_matchup_choice(nodes: Array[ContractRouteNode]) -> bool:
	for node in nodes:
		if node.next_nodes.size() < 3:
			continue
		var matchup_options := 0
		for next_node in node.next_nodes:
			if next_node != null and next_node.branch_intent_tags.has("wide_matchup_choice"):
				matchup_options += 1
		if matchup_options >= 3:
			return true
	return false


static func _has_fork_rejoin_branch(nodes: Array[ContractRouteNode], boss_node: ContractRouteNode) -> bool:
	if boss_node == null:
		return false
	for node in nodes:
		if node.next_nodes.size() < 2:
			continue
		var branch_reach_sets := []
		for next_node in node.next_nodes:
			branch_reach_sets.append(_reachable_node_ids_before_boss(next_node, boss_node))
		for i in range(branch_reach_sets.size()):
			for j in range(i + 1, branch_reach_sets.size()):
				for reached_id in branch_reach_sets[i]:
					if reached_id != "" and reached_id != boss_node.generated_node_id and (branch_reach_sets[j] as Dictionary).has(reached_id):
						return true
	return false


static func _reachable_node_ids_before_boss(start: ContractRouteNode, boss_node: ContractRouteNode) -> Dictionary:
	var reached := {}
	_collect_reachable_node_ids_before_boss(start, boss_node, {}, reached)
	return reached


static func _collect_reachable_node_ids_before_boss(
	node: ContractRouteNode,
	boss_node: ContractRouteNode,
	visited: Dictionary,
	reached: Dictionary
) -> void:
	if node == null or visited.has(node.generated_node_id):
		return
	visited[node.generated_node_id] = true
	reached[node.generated_node_id] = true
	if node == boss_node:
		return
	for next_node in node.next_nodes:
		_collect_reachable_node_ids_before_boss(next_node, boss_node, visited, reached)


static func _validate_boss_approach_lanes(
	nodes: Array[ContractRouteNode],
	boss_node: ContractRouteNode,
	notices: PackedStringArray
) -> void:
	var approach_nodes := _boss_approach_nodes(nodes, boss_node)
	if approach_nodes.is_empty():
		return
	if approach_nodes.size() < 2:
		notices.append("boss_approach_lane_count:%d" % approach_nodes.size())
	var roles := _boss_approach_roles(approach_nodes)
	if roles.size() < 2:
		notices.append("boss_approach_role_variety:%d" % roles.size())
	var has_non_elite := false
	for node in approach_nodes:
		if node.node_type != ContractRouteNode.NodeType.ELITE:
			has_non_elite = true
		if not node.next_nodes.has(boss_node):
			notices.append("boss_approach_not_adjacent:%s" % node.generated_node_id)
	if not has_non_elite:
		notices.append("boss_approach_elite_only")


static func _boss_approach_nodes(nodes: Array[ContractRouteNode], boss_node: ContractRouteNode) -> Array[ContractRouteNode]:
	var result: Array[ContractRouteNode] = []
	if boss_node == null:
		return result
	for node in nodes:
		if node != null and node.branch_intent_tags.has("boss_approach"):
			result.append(node)
	return result


static func _boss_approach_roles(nodes: Array[ContractRouteNode]) -> Dictionary:
	var roles := {}
	for node in nodes:
		if node.branch_intent_tags.has("safe_boss_approach"):
			roles["safe"] = true
		if node.branch_intent_tags.has("captain_boss_approach"):
			roles["captain"] = true
		if node.branch_intent_tags.has("elite_boss_approach"):
			roles["elite"] = true
		if node.branch_intent_tags.has("reward_boss_approach"):
			roles["reward"] = true
	return roles


static func _validate_optional_elite_detour(paths: Array, notices: PackedStringArray) -> void:
	var detour_path_seen := false
	var bypass_path_seen := false
	for path in paths:
		if _path_has_intent_tag(path, "elite_detour"):
			detour_path_seen = true
		else:
			bypass_path_seen = true
	if not detour_path_seen:
		notices.append("elite_detour_path_missing")
	if not bypass_path_seen:
		notices.append("elite_detour_without_bypass")


static func _validate_pressure_gauntlet_paths(paths: Array, notices: PackedStringArray) -> void:
	var gauntlet_path_seen := false
	var recovery_path_seen := false
	for path in paths:
		if _path_intent_tag_count(path, "pressure_gauntlet") >= 2 or _path_captain_count(path) >= 2:
			gauntlet_path_seen = true
		if _path_has_intent_tag(path, "recovery") or _path_has_intent_tag(path, "safe"):
			recovery_path_seen = true
	if not gauntlet_path_seen:
		notices.append("pressure_gauntlet_path_missing")
	if not recovery_path_seen:
		notices.append("pressure_gauntlet_recovery_missing")


static func _path_has_intent_tag(path: Array, tag: String) -> bool:
	return _path_intent_tag_count(path, tag) > 0


static func _path_intent_tag_count(path: Array, tag: String) -> int:
	var count := 0
	for node in path:
		if node != null and node.branch_intent_tags.has(tag):
			count += 1
	return count


static func _path_captain_count(path: Array) -> int:
	var count := 0
	for node in path:
		if node != null and node.node_type == ContractRouteNode.NodeType.CAPTAIN:
			count += 1
	return count


static func _branch_risk_score(node: ContractRouteNode) -> int:
	match node.node_type:
		ContractRouteNode.NodeType.CAPTAIN:
			return 2
		ContractRouteNode.NodeType.ELITE:
			return 3
		ContractRouteNode.NodeType.BOSS:
			return 4
	return 1


static func _validate_template_width(contract: ContractDef, nodes: Array[ContractRouteNode], notices: PackedStringArray) -> void:
	if contract == null or not contract.has_generated_route_state():
		return
	var max_width := 0
	for node in nodes:
		if node == null:
			continue
		max_width = maxi(max_width, node.next_nodes.size())
	if max_width < 3:
		notices.append("template_width_under_minimum:%d" % max_width)
	var summary: Dictionary = contract.template_width_summary
	if not summary.is_empty():
		if int(summary.get("max_width", 0)) != max_width:
			notices.append("template_width_summary_mismatch:%d:%d" % [int(summary.get("max_width", 0)), max_width])
		if (summary.get("wide_node_ids", []) as Array).is_empty():
			notices.append("template_width_summary_missing_wide_node")


static func _validate_pressure_scale_metadata(nodes: Array[ContractRouteNode], notices: PackedStringArray) -> void:
	for node in nodes:
		if node.node_type == ContractRouteNode.NodeType.START:
			continue
		if node.generated_encounter_payload.is_empty():
			continue
		var scale: Dictionary = node.generated_encounter_payload.get("route_pressure_scale", {})
		if scale.is_empty():
			notices.append("pressure_scale_missing:%s" % node.generated_node_id)
			continue
		var raw_difficulty := int(scale.get("raw_difficulty_id", 0))
		var monster_difficulty := int(scale.get("monster_difficulty_id", 0))
		var pressure_tier := int(scale.get("contract_pressure_tier", 0))
		var cap := int(scale.get("monster_difficulty_cap", MAX_MONSTER_DIFFICULTY_ID))
		var expected_pressure := maxi(0, raw_difficulty - cap)
		if monster_difficulty != clampi(raw_difficulty, 1, cap):
			notices.append("pressure_scale_clamp_mismatch:%s" % node.generated_node_id)
		if pressure_tier != expected_pressure:
			notices.append("pressure_scale_overflow_mismatch:%s" % node.generated_node_id)
		var input: Dictionary = node.generated_encounter_payload.get("source_input", {})
		if int(input.get("difficulty_id", 0)) != monster_difficulty:
			notices.append("pressure_scale_input_mismatch:%s" % node.generated_node_id)


static func _validate_reward_pressure_pacing(contract: ContractDef, nodes: Array[ContractRouteNode], notices: PackedStringArray) -> void:
	for node in nodes:
		if node.node_type == ContractRouteNode.NodeType.START or node.reward == null:
			continue
		var scale: Dictionary = node.generated_encounter_payload.get("route_pressure_scale", {})
		if scale.is_empty():
			continue
		var role := _reward_role(node)
		var monster_difficulty := int(scale.get("monster_difficulty_id", 0))
		var expected_tier := _reward_gear_tier_for_difficulty(monster_difficulty, role)
		if int(node.reward.generated_gear_tier) > int(expected_tier):
			notices.append("reward_gear_ahead_of_pressure:%s" % node.generated_node_id)
		var pressure_tier := int(scale.get("contract_pressure_tier", 0))
		if pressure_tier <= 0 and node.node_type != ContractRouteNode.NodeType.BOSS and node.reward.talent_points > 0:
			notices.append("early_talent_without_pressure:%s" % node.generated_node_id)
		var normal_gold_baseline := _reward_gold_amount(REWARD_TABLE["normal"], node, _reward_pressure_bonus(contract))
		if role == "elite" and node.reward.gold_amount > roundi(float(normal_gold_baseline) * 2.75):
			notices.append("elite_gold_outpaces_pressure:%s" % node.generated_node_id)
		elif role == "boss" and node.reward.gold_amount > roundi(float(normal_gold_baseline) * 3.5):
			notices.append("boss_gold_outpaces_pressure:%s" % node.generated_node_id)


static func _validate_pressure_axis_metadata(nodes: Array[ContractRouteNode], notices: PackedStringArray) -> void:
	for node in nodes:
		if node.node_type == ContractRouteNode.NodeType.START:
			continue
		if node.generated_encounter_payload.is_empty():
			continue
		var profile: Dictionary = node.generated_encounter_payload.get("route_pressure_axes", {})
		if profile.is_empty():
			notices.append("pressure_axis_missing:%s" % node.generated_node_id)
			continue
		if String(profile.get("primary", "")) == "":
			notices.append("pressure_axis_primary_missing:%s" % node.generated_node_id)
		var axes: Array = profile.get("axes", [])
		if axes.is_empty():
			notices.append("pressure_axis_list_missing:%s" % node.generated_node_id)
		var source_ids: Array = profile.get("source_archetype_ids", [])
		if source_ids.is_empty():
			notices.append("pressure_axis_source_missing:%s" % node.generated_node_id)


static func _validate_modifier_metadata(contract: ContractDef, nodes: Array[ContractRouteNode], notices: PackedStringArray) -> void:
	if contract.modifier_model_version != MODIFIER_MODEL_VERSION:
		notices.append("modifier_model_version_mismatch:%s" % contract.modifier_model_version)
	if contract.generated_modifiers.is_empty():
		notices.append("modifier_missing")
	if Array(contract.generated_modifier_ids).size() != contract.generated_modifiers.size():
		notices.append("modifier_id_count_mismatch")
	for modifier in contract.generated_modifiers:
		var modifier_id := String(modifier.get("id", ""))
		if modifier_id == "":
			notices.append("modifier_id_missing")
		if not Array(contract.generated_modifier_ids).has(modifier_id):
			notices.append("modifier_not_indexed:%s" % modifier_id)
		if not bool(modifier.get("metadata_only", false)):
			notices.append("modifier_not_metadata_only:%s" % modifier_id)
		for forbidden_key in ["reward_delta", "gold_delta", "gear_delta", "combat_delta", "node_payload", "economy_effect"]:
			if modifier.has(forbidden_key):
				notices.append("modifier_forbidden_payload:%s:%s" % [modifier_id, forbidden_key])
	for node in nodes:
		if node.node_type == ContractRouteNode.NodeType.START:
			continue
		if not node.generated_encounter_payload.has("route_modifier_ids"):
			notices.append("modifier_payload_missing:%s" % node.generated_node_id)
		if Array(node.generated_encounter_payload.get("route_modifier_ids", [])) != Array(contract.generated_modifier_ids):
			notices.append("modifier_payload_route_mismatch:%s" % node.generated_node_id)
		if Array(node.generated_encounter_payload.get("node_modifier_ids", [])) != Array(node.generated_modifier_ids):
			notices.append("modifier_payload_node_mismatch:%s" % node.generated_node_id)
		if Array(node.debug_preview.get("node_modifier_ids", [])) != Array(node.generated_modifier_ids):
			notices.append("modifier_debug_mismatch:%s" % node.generated_node_id)
		if node.route_preview.has("modifier_label") and node.generated_modifier_labels.is_empty():
			notices.append("modifier_preview_without_label:%s" % node.generated_node_id)


static func _validate_elite_variant_metadata(nodes: Array[ContractRouteNode], notices: PackedStringArray) -> void:
	for node in nodes:
		if node.node_type != ContractRouteNode.NodeType.ELITE:
			if node.elite_variant_id != "":
				notices.append("elite_variant_on_non_elite:%s" % node.generated_node_id)
			continue
		if node.elite_variant_model_version != ELITE_VARIANT_MODEL_VERSION:
			notices.append("elite_variant_model_version_mismatch:%s:%s" % [node.generated_node_id, node.elite_variant_model_version])
		if node.elite_variant_id == "":
			notices.append("elite_variant_missing:%s" % node.generated_node_id)
			continue
		if node.elite_variant_label == "":
			notices.append("elite_variant_label_missing:%s" % node.generated_node_id)
		var variant := _elite_variant_by_id(node.elite_variant_id)
		if variant.is_empty():
			notices.append("elite_variant_unknown:%s:%s" % [node.generated_node_id, node.elite_variant_id])
			continue
		if not bool(variant.get("metadata_only", false)):
			notices.append("elite_variant_not_metadata_only:%s" % node.elite_variant_id)
		for forbidden_key in ["reward_delta", "gold_delta", "gear_delta", "combat_delta", "node_payload", "economy_effect"]:
			if variant.has(forbidden_key):
				notices.append("elite_variant_forbidden_payload:%s:%s" % [node.elite_variant_id, forbidden_key])
		if node.generated_encounter_payload.get("elite_variant_id", "") != node.elite_variant_id:
			notices.append("elite_variant_payload_mismatch:%s" % node.generated_node_id)
		if node.generated_encounter_payload.get("elite_variant_model_version", "") != node.elite_variant_model_version:
			notices.append("elite_variant_payload_model_mismatch:%s" % node.generated_node_id)
		if node.debug_preview.get("elite_variant_id", "") != node.elite_variant_id:
			notices.append("elite_variant_debug_mismatch:%s" % node.generated_node_id)
		if node.route_preview.get("elite_variant_label", "") != node.elite_variant_label:
			notices.append("elite_variant_preview_mismatch:%s" % node.generated_node_id)


static func _validate_boss_variant_metadata(nodes: Array[ContractRouteNode], notices: PackedStringArray) -> void:
	for node in nodes:
		if node.node_type != ContractRouteNode.NodeType.BOSS:
			if node.boss_variant_id != "":
				notices.append("boss_variant_on_non_boss:%s" % node.generated_node_id)
			continue
		if node.boss_variant_model_version != BOSS_VARIANT_MODEL_VERSION:
			notices.append("boss_variant_model_version_mismatch:%s:%s" % [node.generated_node_id, node.boss_variant_model_version])
		if node.boss_variant_id == "":
			notices.append("boss_variant_missing:%s" % node.generated_node_id)
			continue
		if node.boss_variant_label == "":
			notices.append("boss_variant_label_missing:%s" % node.generated_node_id)
		var variant := _boss_variant_by_id(node.boss_variant_id)
		if variant.is_empty():
			notices.append("boss_variant_unknown:%s:%s" % [node.generated_node_id, node.boss_variant_id])
			continue
		if not bool(variant.get("metadata_only", false)):
			notices.append("boss_variant_not_metadata_only:%s" % node.boss_variant_id)
		for forbidden_key in ["reward_delta", "gold_delta", "gear_delta", "combat_delta", "node_payload", "economy_effect"]:
			if variant.has(forbidden_key):
				notices.append("boss_variant_forbidden_payload:%s:%s" % [node.boss_variant_id, forbidden_key])
		if node.generated_encounter_payload.get("boss_variant_id", "") != node.boss_variant_id:
			notices.append("boss_variant_payload_mismatch:%s" % node.generated_node_id)
		if node.generated_encounter_payload.get("boss_variant_model_version", "") != node.boss_variant_model_version:
			notices.append("boss_variant_payload_model_mismatch:%s" % node.generated_node_id)
		if node.debug_preview.get("boss_variant_id", "") != node.boss_variant_id:
			notices.append("boss_variant_debug_mismatch:%s" % node.generated_node_id)
		if node.route_preview.get("boss_variant_label", "") != node.boss_variant_label:
			notices.append("boss_variant_preview_mismatch:%s" % node.generated_node_id)


static func _validate_dead_run_axis_diversity(
	nodes: Array[ContractRouteNode],
	paths: Array,
	boss_node: ContractRouteNode,
	notices: PackedStringArray
) -> void:
	_validate_branch_pressure_axes(nodes, notices)
	_validate_path_pressure_axis_domination(paths, boss_node, notices)
	_validate_shortest_path_preparation(paths, boss_node, notices)


static func _validate_branch_pressure_axes(nodes: Array[ContractRouteNode], notices: PackedStringArray) -> void:
	for node in nodes:
		if node.next_nodes.size() <= 1:
			continue
		if node.depth <= 0:
			continue
		var combat_options: Array[ContractRouteNode] = []
		for next_node in node.next_nodes:
			if next_node != null and next_node.node_type != ContractRouteNode.NodeType.START:
				combat_options.append(next_node)
		if combat_options.size() <= 1:
			continue
		var primary_axis := _primary_pressure_axis(combat_options[0])
		if primary_axis == "" or primary_axis == PRESSURE_AXIS_MIXED:
			continue
		var all_same := true
		for option in combat_options:
			if _primary_pressure_axis(option) != primary_axis:
				all_same = false
				break
		if all_same and not _branch_options_have_meaningful_tradeoff(combat_options):
			notices.append("branch_pressure_axis_not_distinct:%s:%s" % [node.generated_node_id, primary_axis])


static func _validate_path_pressure_axis_domination(paths: Array, boss_node: ContractRouteNode, notices: PackedStringArray) -> void:
	if paths.size() < 2 or boss_node == null:
		return
	var boss_axis := _primary_pressure_axis(boss_node)
	if boss_axis == "" or boss_axis == PRESSURE_AXIS_MIXED:
		return
	if _contract_pressure_tier(boss_node) <= 0:
		return
	var required_score := mini(8, 3 + _contract_pressure_tier(boss_node) * 2)
	if _best_path_prep_score(paths) >= required_score:
		return
	var dominated_count := 0
	for path in paths:
		var dominant := _dominant_path_axis(path, false)
		if dominant == boss_axis and _path_axis_count(path, boss_axis, false) >= 2:
			dominated_count += 1
	if dominated_count == paths.size():
		notices.append("all_paths_pressure_axis_dominated:%s" % boss_axis)


static func _validate_shortest_path_preparation(paths: Array, boss_node: ContractRouteNode, notices: PackedStringArray) -> void:
	if paths.is_empty() or boss_node == null:
		return
	var shortest: Array = paths[0]
	for path in paths:
		if _committed_path_length(path) < _committed_path_length(shortest):
			shortest = path
	var boss_pressure := _contract_pressure_tier(boss_node)
	if boss_pressure <= 0:
		return
	var prep_score := _path_prep_score(shortest)
	var required_score := mini(8, 3 + boss_pressure * 2)
	if prep_score < required_score:
		notices.append("low_reward_shortest_path:%d:%d" % [prep_score, required_score])


static func _branch_options_have_meaningful_tradeoff(options: Array[ContractRouteNode]) -> bool:
	for i in range(options.size()):
		for j in range(i + 1, options.size()):
			var a: ContractRouteNode = options[i]
			var b: ContractRouteNode = options[j]
			if a.node_type != b.node_type:
				return true
			if _secondary_pressure_axis(a) != _secondary_pressure_axis(b):
				return true
			if abs(a.depth - b.depth) >= 1:
				return true
			if abs(_contract_pressure_tier(a) - _contract_pressure_tier(b)) >= 1:
				return true
			if a.reward != null and b.reward != null:
				if abs(a.reward.gold_amount - b.reward.gold_amount) >= 8:
					return true
				if a.reward.generated_gear_tier != b.reward.generated_gear_tier:
					return true
				if a.reward.generated_gear_choice_count != b.reward.generated_gear_choice_count:
					return true
	return false


static func _dominant_path_axis(path: Array, include_boss: bool) -> String:
	var counts := {}
	for node in path:
		if node == null or node.node_type == ContractRouteNode.NodeType.START:
			continue
		if node.node_type == ContractRouteNode.NodeType.BOSS and not include_boss:
			continue
		var axis := _primary_pressure_axis(node)
		if axis == "" or axis == PRESSURE_AXIS_MIXED:
			continue
		counts[axis] = int(counts.get(axis, 0)) + 1
	var best_axis := ""
	var best_count := 0
	for axis in counts:
		var count := int(counts[axis])
		if count > best_count:
			best_axis = String(axis)
			best_count = count
	return best_axis


static func _path_axis_count(path: Array, target_axis: String, include_boss: bool) -> int:
	var count := 0
	for node in path:
		if node == null or node.node_type == ContractRouteNode.NodeType.START:
			continue
		if node.node_type == ContractRouteNode.NodeType.BOSS and not include_boss:
			continue
		if _primary_pressure_axis(node) == target_axis:
			count += 1
	return count


static func _path_prep_score(path: Array) -> int:
	var score := 0
	for node in path:
		if node == null or node.node_type == ContractRouteNode.NodeType.START or node.node_type == ContractRouteNode.NodeType.BOSS:
			continue
		score += 1
		if node.node_type == ContractRouteNode.NodeType.CAPTAIN:
			score += 1
		elif node.node_type == ContractRouteNode.NodeType.ELITE:
			score += 2
		if node.reward == null:
			continue
		score += int(floor(float(node.reward.gold_amount) / 12.0))
		score += int(node.reward.generated_gear_choice_count) * maxi(1, int(node.reward.generated_gear_tier) + 1)
		score += int(node.reward.talent_points) * 4
	return score


static func _best_path_prep_score(paths: Array) -> int:
	var best := 0
	for path in paths:
		best = maxi(best, _path_prep_score(path))
	return best


static func _primary_pressure_axis(node: ContractRouteNode) -> String:
	var profile: Dictionary = node.generated_encounter_payload.get("route_pressure_axes", {})
	return String(profile.get("primary", ""))


static func _secondary_pressure_axis(node: ContractRouteNode) -> String:
	var profile: Dictionary = node.generated_encounter_payload.get("route_pressure_axes", {})
	return String(profile.get("secondary", ""))


static func _contract_pressure_tier(node: ContractRouteNode) -> int:
	var scale: Dictionary = node.generated_encounter_payload.get("route_pressure_scale", {})
	return int(scale.get("contract_pressure_tier", 0))


static func _committed_path_length(path: Array) -> int:
	return maxi(0, path.size() - 1)


static func _elite_count(path: Array) -> int:
	var count := 0
	for node in path:
		if node.node_type == ContractRouteNode.NodeType.ELITE:
			count += 1
	return count


static func _has_back_to_back_elites(path: Array) -> bool:
	var previous_elite := false
	for node in path:
		var current_elite: bool = node.node_type == ContractRouteNode.NodeType.ELITE
		if previous_elite and current_elite:
			return true
		previous_elite = current_elite
	return false


static func _path_id_signature(path: Array) -> String:
	var parts := PackedStringArray()
	for node in path:
		parts.append(node.generated_node_id)
	return ">".join(parts)


static func _branch_preview_signature(node: ContractRouteNode) -> String:
	return "%s|%s|%s|%s|%s|%s|%d|%s" % [
		node.route_preview.get("biome", ""),
		node.route_preview.get("monster_name", ""),
		node.route_preview.get("encounter_level", ""),
		node.route_preview.get("elite_variant_label", ""),
		node.route_preview.get("boss_variant_label", ""),
		",".join(_preview_tags(node.route_preview)),
		node.node_type,
		_reward_signature(node),
	]


static func _encounter_signature(node: ContractRouteNode) -> String:
	if node.generated_encounter_payload.is_empty():
		return "encounter:none"
	var input: Dictionary = node.generated_encounter_payload.get("source_input", {})
	var mechanics := PackedStringArray()
	for entry in node.generated_encounter_payload.get("selected_mechanics", []):
		mechanics.append("%s:%s:%s" % [
			String(entry.get("id", "")),
			str(entry.get("value", "")),
			str(entry.get("godot_value", "")),
		])
	var scale: Dictionary = node.generated_encounter_payload.get("route_pressure_scale", {})
	var axes: Dictionary = node.generated_encounter_payload.get("route_pressure_axes", {})
	return "encounter:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [
		String(node.generated_encounter_payload.get("id", "")),
		str(node.generated_encounter_payload.get("source_seed", "")),
		String(input.get("monster_kind", "")),
		str(input.get("difficulty_id", "")),
		str(scale.get("raw_difficulty_id", "")),
		str(scale.get("content_difficulty_id", "")),
		str(scale.get("contract_progression_stage", "")),
		str(scale.get("overcap_pressure", "")),
		str(scale.get("contract_pressure_tier", "")),
		String(axes.get("primary", "")),
		String(axes.get("secondary", "")),
		String(input.get("tempo_profile", "")),
		";".join(mechanics),
		",".join(Array(node.generated_modifier_ids)),
		node.elite_variant_id,
		node.boss_variant_id,
	]


static func _reward_signature(node: ContractRouteNode) -> String:
	if node.reward == null:
		return "reward:none"
	return "reward:%d:%d:%d:%d:%s:%s:%s" % [
		node.reward.gold_amount,
		node.reward.talent_points,
		node.reward.generated_gear_choice_count,
		node.reward.generated_gear_tier,
		",".join(_int_strings(node.reward.generated_gear_slots)),
		node.reward_quality_label,
		node.reward_summary,
	]


static func _int_strings(values: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for value in values:
		out.append(str(int(value)))
	return out


static func _preview_tags(preview: Dictionary) -> PackedStringArray:
	var tags := PackedStringArray()
	for tag in preview.get("archetype_tags", []):
		tags.append(String(tag))
	return tags
