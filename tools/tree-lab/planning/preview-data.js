window.TREE_LAB_PREVIEW = {
  "empty": {
    "format": "faceless-void.tree-lab",
    "schema_version": 1,
    "tree": {
      "id": "draft.untitled",
      "name": "Untitled tree",
      "subclass": "",
      "notes": "",
      "levels": [
        {
          "id": "level.1",
          "order": 1,
          "required_points": 0
        },
        {
          "id": "level.2",
          "order": 2,
          "required_points": 3
        },
        {
          "id": "level.3",
          "order": 3,
          "required_points": 6
        },
        {
          "id": "level.4",
          "order": 4,
          "required_points": 9
        },
        {
          "id": "level.5",
          "order": 5,
          "required_points": 12
        }
      ],
      "talents": [],
      "intrinsic": {
        "name": "Intrinsic",
        "description": "",
        "icon_id": "placeholder",
        "values": []
      },
      "automatic_unlocks": [
        {
          "id": "unlock.1",
          "order": 1,
          "required_points": 1,
          "icon_id": "placeholder",
          "skill": null,
          "values": []
        },
        {
          "id": "unlock.2",
          "order": 2,
          "required_points": 3,
          "icon_id": "placeholder",
          "skill": null,
          "values": []
        },
        {
          "id": "unlock.3",
          "order": 3,
          "required_points": 6,
          "icon_id": "placeholder",
          "skill": null,
          "values": []
        },
        {
          "id": "unlock.4",
          "order": 4,
          "required_points": 9,
          "icon_id": "placeholder",
          "skill": null,
          "values": []
        },
        {
          "id": "unlock.5",
          "order": 5,
          "required_points": 12,
          "icon_id": "placeholder",
          "skill": null,
          "values": []
        }
      ]
    }
  },
  "assassin": {
    "format": "faceless-void.tree-lab",
    "schema_version": 1,
    "tree": {
      "id": "draft.assassin",
      "name": "Assassin",
      "subclass": "Assassin",
      "notes": "Illustrative transcription of the user sketch, not an approved redesign. Names, thresholds, rank caps and unspecified values are proposals. Fifth automatic slot intentionally blank. IAS means increased attack speed. Bypass and bonus tick damage are unimplemented concepts.",
      "levels": [
        {
          "id": "level.1",
          "order": 1,
          "required_points": 0
        },
        {
          "id": "level.2",
          "order": 2,
          "required_points": 3
        },
        {
          "id": "level.3",
          "order": 3,
          "required_points": 6
        },
        {
          "id": "level.4",
          "order": 4,
          "required_points": 9
        },
        {
          "id": "level.5",
          "order": 5,
          "required_points": 12
        }
      ],
      "talents": [
        {
          "id": "talent.quick_hands",
          "name": "Quick Hands",
          "flavour_text": "",
          "description": "Increase attack speed by 1% per point.",
          "icon_id": "rogue.quick_cut",
          "level_id": "level.1",
          "position": {
            "x": 0.34
          },
          "max_ranks": 5,
          "prerequisite_ids": [],
          "values": [
            {
              "id": "ias",
              "label": "Attack speed",
              "unit": "%",
              "rank_1": 1,
              "per_rank": 1
            }
          ],
          "skill_grant": null
        },
        {
          "id": "talent.precision",
          "name": "Precision",
          "flavour_text": "",
          "description": "Increase crit chance by 1 percentage point per rank.",
          "icon_id": "rogue.stab",
          "level_id": "level.1",
          "position": {
            "x": 0.68
          },
          "max_ranks": 5,
          "prerequisite_ids": [],
          "values": [
            {
              "id": "crit",
              "label": "Crit chance",
              "unit": "percentage points",
              "rank_1": 1,
              "per_rank": 1
            }
          ],
          "skill_grant": null
        },
        {
          "id": "talent.hastened_poison",
          "name": "Hastened Poison",
          "flavour_text": "",
          "description": "Poison tick rate is increased by attack speed. Exact scaling is undecided.",
          "icon_id": "rogue.venom_jab",
          "level_id": "level.2",
          "position": {
            "x": 0.13
          },
          "max_ranks": 1,
          "prerequisite_ids": [],
          "values": [],
          "skill_grant": null
        },
        {
          "id": "talent.echoing_toxin",
          "name": "Echoing Toxin",
          "flavour_text": "",
          "description": "Poison now ticks twice for bonus damage. Bonus amount is undecided.",
          "icon_id": "rogue.beguiling_strike",
          "level_id": "level.2",
          "position": {
            "x": 0.5
          },
          "max_ranks": 1,
          "prerequisite_ids": [],
          "values": [],
          "skill_grant": null
        },
        {
          "id": "talent.poison_strike",
          "name": "Poison Strike",
          "flavour_text": "",
          "description": "Unlock Poison Strike: hits from Poison Strike cause poison ticks.",
          "icon_id": "rogue.poison_strike",
          "level_id": "level.2",
          "position": {
            "x": 0.86
          },
          "max_ranks": 1,
          "prerequisite_ids": [],
          "values": [],
          "skill_grant": {
            "id": "draft.skill.poison_strike",
            "name": "Poison Strike",
            "description": "Hits cause poison ticks."
          }
        },
        {
          "id": "talent.bypass",
          "name": "Bypass",
          "flavour_text": "",
          "description": "Stab grants a stack of Bypass. Each stack grants x10% poison damage. Stack lifetime and cap are undecided.",
          "icon_id": "rogue.heavy_slash",
          "level_id": "level.3",
          "position": {
            "x": 0.32
          },
          "max_ranks": 1,
          "prerequisite_ids": [],
          "values": [
            {
              "id": "bypass",
              "label": "Poison damage per Bypass stack",
              "unit": "% multiplicative (draft)",
              "rank_1": 10,
              "per_rank": 0
            }
          ],
          "skill_grant": null
        },
        {
          "id": "talent.toxic_tradeoff",
          "name": "Toxic Tradeoff",
          "flavour_text": "",
          "description": "Increase poison damage; reduce physical damage. Both values are illustrative.",
          "icon_id": "rogue.venom_jab",
          "level_id": "level.3",
          "position": {
            "x": 0.75
          },
          "max_ranks": 3,
          "prerequisite_ids": [],
          "values": [
            {
              "id": "poison",
              "label": "Poison damage",
              "unit": "%",
              "rank_1": 10,
              "per_rank": 10
            },
            {
              "id": "physical",
              "label": "Physical damage",
              "unit": "%",
              "rank_1": -5,
              "per_rank": -5
            }
          ],
          "skill_grant": null
        },
        {
          "id": "talent.accelerant",
          "name": "Accelerant",
          "flavour_text": "",
          "description": "Increase the attack-speed scaling of poison ticks. Value is illustrative.",
          "icon_id": "rogue.quick_cut",
          "level_id": "level.4",
          "position": {
            "x": 0.13
          },
          "max_ranks": 3,
          "prerequisite_ids": [
            "talent.hastened_poison"
          ],
          "values": [
            {
              "id": "ias_scaling",
              "label": "Additional IAS scaling",
              "unit": "%",
              "rank_1": 10,
              "per_rank": 10
            }
          ],
          "skill_grant": null
        },
        {
          "id": "talent.resonance",
          "name": "Resonance",
          "flavour_text": "",
          "description": "Increase the bonus damage of the extra poison tick. Value is illustrative.",
          "icon_id": "rogue.beguiling_strike",
          "level_id": "level.4",
          "position": {
            "x": 0.5
          },
          "max_ranks": 3,
          "prerequisite_ids": [
            "talent.echoing_toxin"
          ],
          "values": [
            {
              "id": "bonus",
              "label": "Bonus tick damage",
              "unit": "%",
              "rank_1": 10,
              "per_rank": 10
            }
          ],
          "skill_grant": null
        },
        {
          "id": "talent.critical_poison",
          "name": "Critical Poison",
          "flavour_text": "",
          "description": "Poison can crit. Crit rules and interaction details are undecided.",
          "icon_id": "rogue.death_strike",
          "level_id": "level.5",
          "position": {
            "x": 0.5
          },
          "max_ranks": 1,
          "prerequisite_ids": [],
          "values": [],
          "skill_grant": null
        }
      ],
      "intrinsic": {
        "name": "Assassin intrinsic",
        "description": "x1% increased poison damage per point invested; displayed value is descriptive, stacking rule undecided.",
        "icon_id": "rogue.venom_jab",
        "values": [
          {
            "id": "poison_per_point",
            "label": "Increased poison damage",
            "unit": "%",
            "base": 0,
            "per_point": 1
          }
        ]
      },
      "automatic_unlocks": [
        {
          "id": "unlock.1",
          "order": 1,
          "required_points": 1,
          "icon_id": "rogue.venom_jab",
          "skill": {
            "id": "draft.skill.venom_jab",
            "name": "Venom Jab",
            "description": "Apply 5 stacks of poison."
          },
          "values": []
        },
        {
          "id": "unlock.2",
          "order": 2,
          "required_points": 3,
          "icon_id": "rogue.hold",
          "skill": {
            "id": "draft.skill.blinding_powder",
            "name": "Blinding Powder",
            "description": "Poison ignores <Assassin Level> absorb. Assassin Level means tree points in this mockup; definition remains a design question."
          },
          "values": [
            {
              "id": "absorb",
              "label": "Absorb ignored (draft)",
              "unit": "",
              "base": 0,
              "per_point": 1
            }
          ]
        },
        {
          "id": "unlock.3",
          "order": 3,
          "required_points": 6,
          "icon_id": "rogue.poison_strike",
          "skill": {
            "id": "draft.skill.virulent_poison",
            "name": "Virulent Poison",
            "description": "The next 5 ticks of poison do bonus damage. Amount undecided."
          },
          "values": []
        },
        {
          "id": "unlock.4",
          "order": 4,
          "required_points": 9,
          "icon_id": "rogue.death_strike",
          "skill": {
            "id": "draft.skill.master_of_poisons",
            "name": "Master of Poisons",
            "description": ""
          },
          "values": []
        },
        {
          "id": "unlock.5",
          "order": 5,
          "required_points": 12,
          "icon_id": "placeholder",
          "skill": null,
          "values": []
        }
      ]
    }
  },
  "icons": [
    {
      "id": "placeholder",
      "label": "Unassigned",
      "path": null
    },
    {
      "id": "rogue.stab",
      "label": "Stab",
      "path": "../../../project/assets/skill_icons/rogue/stab.png"
    },
    {
      "id": "rogue.heavy_slash",
      "label": "Heavy Slash",
      "path": "../../../project/assets/skill_icons/rogue/heavy_slash.png"
    },
    {
      "id": "rogue.quick_cut",
      "label": "Quick Cut",
      "path": "../../../project/assets/skill_icons/rogue/quick_cut.png"
    },
    {
      "id": "rogue.venom_jab",
      "label": "Venom Jab",
      "path": "../../../project/assets/skill_icons/rogue/venom_jab.png"
    },
    {
      "id": "rogue.poison_strike",
      "label": "Poison Strike",
      "path": "../../../project/assets/skill_icons/rogue/poison_strike.png"
    },
    {
      "id": "rogue.rending_slash",
      "label": "Rending Slash",
      "path": "../../../project/assets/skill_icons/rogue/rending_slash.png"
    },
    {
      "id": "rogue.beguiling_strike",
      "label": "Beguiling Strike",
      "path": "../../../project/assets/skill_icons/rogue/beguiling_strike.png"
    },
    {
      "id": "rogue.death_strike",
      "label": "Death Strike",
      "path": "../../../project/assets/skill_icons/rogue/death_strike.png"
    },
    {
      "id": "rogue.steal",
      "label": "Steal",
      "path": "../../../project/assets/skill_icons/rogue/steal.png"
    },
    {
      "id": "rogue.hold",
      "label": "Hold",
      "path": "../../../project/assets/skill_icons/rogue/hold.png"
    }
  ]
};
