# Phase 6 Audited Baseline Integration

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Date: 2026-09-21

## Source and preserved work

FacelessVoid now incorporates Enigma `main` commit
`d0e025ae9ff6b86aa389582443be6382547cb4cc` (2026-09-20),
"Fix combat-hang, save-durability, and inventory-cap bugs from code audit."
The common ancestor is the original Phase 5 closeout `91c1f2f`.
The audit was published in Enigma, not DawnBringer.

Phase 6 work was checkpointed in `b696425` before merging: Tree Lab,
its four documents, the README additions, and removal of inherited Enigma
documents. The audited history was merged without conflicts. Tree Lab files
remain unchanged by the integration. Historical documents stay in Enigma or
Git history; the FacelessVoid docs folder contains Phase 6 documents only.

The active integration branch is `phase-6-skill-tree-redesign`. FacelessVoid's
`main` is not advanced by this integration; the validated Phase 6 branch is the
working baseline. The original Enigma and DawnBringer workspaces are untouched.

## Imported behavior and review

- Combat execution time has a minimum of 1 ms, including slowed casts.
- Saves are written to a temporary file before replacing the target.
- When equipping an external item into a full inventory, displaced gear is
  sold and its sale value added to gold. Equipping from inventory first frees
  the selected item's slot, so the displaced item can normally occupy it.
- Over-band generated encounters receive up to five deterministic attempts,
  including the original seed. If all remain over-band, the closest pressure
  ratio to the target is retained. This can change newly generated fights;
  it does not guarantee every encounter lands within the target band.
- Stat pools and map actor textures are cached.
- The unused legacy Tavern shop scene and script are removed.

These changes are accepted as the audited Phase 5 foundation; they do not
expand Phase 6 into a new gear, economy, or route redesign. No gameplay source
changes were added on top of the imported audit during this integration.

### Remaining save durability limitation

The imported save implementation closes the temporary file, removes the
existing target, then renames the temporary file. This protects the previous
save during temporary-file writing, but is not an atomic replacement: failure
between removal and rename can leave the normal save path missing. Write-error
handling and interruption recovery need separate focused hardening. Passing
normal save/load regression does not prove power-loss safety.

## Validation

The full `tools/p5m12/run_regression.ps1` run exited 0 on 2026-09-21:

- All 34 Godot test scripts passed, including save/load, deterministic replay,
  generated routes, combat, inventory/equipment presentation, and Practice Room.
- Balance Lab: 69 pass, 1 warn, 0 fail. The existing warning remains
  `bladedancer_contract_watchmen` (100% wins above the 95% watch threshold).
- Shop Lab: all 23 checks passed.
- Refreshed Balance Lab reports are saved under `project/reports/balance/latest/`.

The run emitted the expected intentional corrupt-save JSON error and known
Godot shutdown cleanup warnings, plus sandbox certificate-store errors.
No GDScript parse errors or assertion failures appeared in the regression log.

Tree Lab model checks: 22 passed. DOM integration checks: 13 passed.
Generated bundle parity and JavaScript syntax checks passed.
Real-browser visual/drag/download validation remains the pre-existing Tree Lab
limitation documented in its README; DOM checks do not replace it.
