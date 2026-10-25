# Project FacelessVoid

M1–M7 are Complete within their recorded scopes. Adventure is enabled with all four redesigned Rogue trees. M8 Legendary Item Revamp and Expansion is In progress: T1–T8 Complete; T9 presentation and combat feedback await user review under D084; T10–T12 Not started. All16 approved Legendaries are implemented. M9 owns broader integrated playtesting/refinement, and M10 owns final regression/closeout. See the [M8 tracker](docs/P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md) and [current checkpoint scope](docs/P6_2026-10-24_Git_Checkpoint.md).

Combat rules: [Combat Mechanics Reference](docs/Combat_Mechanics_Reference.md) — current formulas, skill values, interaction exceptions and implementation status.

## Design labs

- [Icon Lab](tools/icon-lab/README.md): 92-entry mechanics icon library, image
  imports, assignment previews and portable JSON workspaces. Open
  `tools/icon-lab/index.html` directly in a browser.

- [Tree Lab](tools/tree-lab/README.md): visual talent-tree editor, JSON import/export,
  browser draft recovery, and point-allocation preview. Open
  `tools/tree-lab/index.html` directly in a browser; no server or install is needed.
- [Shop Lab](tools/shop-lab/README.md)
- [Monster Lab](tools/monster-lab/README.md)
- [Balance Lab](tools/balance-lab/README.md)
- [Sprite Lab](tools/sprite-lab/README.md)

Project FacelessVoid is the Phase 6 Rogue skill-tree redesign, built on Enigma's
audited Phase 5 generated-contract Rogue adventure loop. The current baseline is a
playable fantasy roguelite deck-and-build RPG prototype focused on readable
buildcraft, generated contracts, deterministic rewards, and gear-driven matchup
decisions.

Phase 5 replaces the old gear assumptions with a five-slot Rogue gear system:
Dagger, Hood, Doublet, Ring, and Necklace. It adds deterministic item
generation, new rarity rules, Cursed and Chaos drawbacks, Unique Specials,
fixed retained Rogue Legendary daggers, reward/shop integration, readable item
cards, Practice Room validation, and Balance Lab coverage.

## Repository Setup

- Primary branch: `main`
- Development branch: `phase-6-skill-tree-redesign`
- Godot project: `project/project.godot` (Project Manager name: **FacelessVoid**)
- Separate Windows saves/settings: `%APPDATA%/FacelessVoid/`; Enigma keeps its original data.
- Godot version: `4.7`
- Standalone remote: `https://github.com/thalverson1022/FacelessVoid.git`
- Audited source baseline: Enigma `d0e025ae9ff6b86aa389582443be6382547cb4cc`
- Start here: [Phase 6 onboarding](docs/P6_Project_Onboarding_Context.md)
- Progress and decisions: [Phase 6 milestone tracker](docs/P6_Milestone_Tracker.md)
- M2 tasks: [Build model and progression foundations tracker](docs/P6M2_Build_Model_And_Progression_Foundations_Tracker.md)
- Phase status: M1–M7 Complete within their scopes; M8 In progress, T9 Pending input; M9/M10 Not started. [M7 final closeout, regression exceptions and M8 handoff](docs/P6M7_T11_Closeout_And_M8_Handoff.md); [M8 tracker](docs/P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md).
- M2 closeout: [Evidence and M3 handoff](docs/P6M2_T9_Closeout_And_M3_Handoff.md)
- Integration and validation: [audited baseline](docs/P6_Audited_Baseline_Integration.md)

## Inherited validation and export tools

Run the final regression and itch.io export package scripts from the repository
root:

```powershell
tools/p5m12/run_regression.ps1
tools/p5m12/export_itchio.ps1
```

The itch.io-ready web package is written to:

```text
release/itchio/facelessvoid-phase6-itch.zip
```

The inherited exporter now targets FacelessVoid. A new package must be built
and validated before it is treated as a Phase 6 release. Historical Phase 5 documents remain in Enigma and Git history; this
repository's docs folder contains Phase 6 context only.
