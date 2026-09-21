# Project FacelessVoid

## Design labs

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
- Godot project: `project/project.godot`
- Godot version: `4.7`
- Standalone remote: `https://github.com/thalverson1022/FacelessVoid.git`
- Audited source baseline: Enigma `d0e025ae9ff6b86aa389582443be6382547cb4cc`
- Start here: [Phase 6 onboarding](docs/P6_Project_Onboarding_Context.md)
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
release/itchio/project-enigma-phase5-itch.zip
```

This package is the historical Phase 5 export, not a newly validated Phase 6
release. Historical Phase 5 documents remain in Enigma and Git history; this
repository's docs folder contains Phase 6 context only.
