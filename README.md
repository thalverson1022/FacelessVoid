# Project Enigma

## Design labs

- [Tree Lab](tools/tree-lab/README.md): visual talent-tree editor, JSON import/export,
  browser draft recovery, and point-allocation preview. Open
  `tools/tree-lab/index.html` directly in a browser; no server or install is needed.
- [Shop Lab](tools/shop-lab/README.md)
- [Monster Lab](tools/monster-lab/README.md)
- [Balance Lab](tools/balance-lab/README.md)
- [Sprite Lab](tools/sprite-lab/README.md)

Project Enigma is the Phase 5 continuation of the generated-contract Rogue
adventure loop that began in earlier project branches. The current baseline is a
playable fantasy roguelite deck-and-build RPG prototype focused on readable
buildcraft, generated contracts, deterministic rewards, and gear-driven matchup
decisions.

Phase 5 replaces the old gear assumptions with a five-slot Rogue gear system:
Dagger, Hood, Doublet, Ring, and Necklace. It adds deterministic item
generation, new rarity rules, Cursed and Chaos drawbacks, Unique Specials,
fixed retained Rogue Legendary daggers, reward/shop integration, readable item
cards, Practice Room validation, and Balance Lab coverage.

## Repository Setup

- Active branch: `phase-5-gear-redesign`
- Godot project: `project/project.godot`
- Godot version: `4.7`
- Standalone remote: `https://github.com/thalverson1022/Enigma.git`
- Current closeout milestone: P5M12 Phase 5 Regression, Smoke, And Closeout

## P5M12 Closeout

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

Use `docs/Itch_IO_Release_Checklist.md` when uploading the web package to
itch.io.
