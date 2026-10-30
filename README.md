# Project FacelessVoid

**Phase 6 is Complete. M1–M11 and M11 T1–T6 are Complete within their accepted scopes.** Final user acceptance is recorded under M11 D012 (2026-10-30). [Current documentation](docs/README.md), [Phase 6 roadmap](docs/P6_Milestone_Tracker.md) and [accepted regression/closeout record](docs/P6M11_Regression_And_Closeout_Tracker.md) summarize verification, retained engine/environment limitations and deferred economy/trigger/balance work. Export/package readiness is conditional on separate validation.

Combat rules: [Combat Mechanics Reference](docs/Combat_Mechanics_Reference.md) — current formulas, skill values, interaction exceptions and implementation status.

## Design labs

- [Icon Lab](tools/icon-lab/README.md): mechanics icon library, image
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
fixed Legendary equipment, reward/shop integration, readable item
cards, Practice Room validation, and Balance Lab coverage.

Seven-slot Legs/Pants and Hands/Gloves ownership/save and ordinary acquisition are implemented under M9-T5/T6, with approved stat pools and equal eligible-slot selection. Fresh Adventures equip only Crude Dagger. Seven-slot UI is implemented, verified and accepted under D018; T8 supplied artwork, catalog20 and four new Legendary signatures are integrated, verified and accepted; M9–M11 closeout records retain their evidence and limits.

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
- Phase status and milestone boundaries: [current roadmap](docs/P6_Milestone_Tracker.md).
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
