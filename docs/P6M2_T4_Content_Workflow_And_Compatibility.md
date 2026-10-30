# P6M2-T4 Content Workflow and Compatibility

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Date: 2026-09-22. Status: **Complete — design specification and handoff.**

This specifies the T4 content pipeline, identity rules, persistence contract and
acceptance cases. Implementation belongs to T6/T7; integrated verification belongs
to T8. No source draft, gameplay resource or player save is changed by this work.
The [T3 rules](P6M2_T3_Progression_And_Allocation_Rules.md) remain authoritative
for progression and allocation. Detailed mechanics remain M3/M5 work.

## Inspected baseline

| Surface | Current implementation | T4 consequence |
| --- | --- | --- |
| Adventure persistence | `project/scripts/systems/save_system.gd`: save version 1; class, trees and selected talents use resource paths; rotation uses Skill.id. | Version the ranked-build representation and resolve IDs through an explicit registry. Do not load old talent paths as new ranked allocations. |
| Tree roles | `build_state.gd` appends secondary; Practice Room's `tree_at_slot` uses compact-array order. | Persist primary/secondary explicitly. Never sort trees or infer roles from investment. |
| Talents | `resources/talent.gd`: binary selection, cost and arrays of OR prerequisite groups. | New content has ranks and flat ALL prerequisites at rank one. Translate each prerequisite into a singleton group if retaining the old resource shape; never flatten old OR groups into ALL. |
| Rotation | `BuildResolver.resolve_rotation` filters by ID, preserves duplicates and stops at ten; `SaveSystem._deserialize` reconstructs directly without that limit. | All load/edit paths must use the same normalization contract. |
| Practice Room | Scene creates `TrainingRoomState.new()` on entry; no disk serializer. | A separate Practice Room persistence format is new work. There are no inherited on-disk practice builds to migrate. |
| Durability | Existing writer removes the destination before renaming its temporary file. | Normal round-trip and migration checks do not prove power-loss safety. Preserve the limitation in the [baseline integration notes](P6_Audited_Baseline_Integration.md). |

## 1. Content authority and promotion

Use three explicit layers:

1. **Design evidence:** the four JSON files in `docs/talent_tree_drafts/`, their
   recorded hashes, and subsequent version-controlled exports. Preserve their
   original text and identity, including mistakes. Tree Lab examples are not game
   content. External originals are not consulted automatically during conversion.
2. **Approved specification:** T3 plus the applicable M3/M5 mechanic specifications
   and decision records. These override ambiguous draft prose only where a decision
   is explicit. The [identity manifest](P6M2_T4_Content_Identity_Manifest.json)
   connects each source object to its reserved runtime identity. Identity reservation
   does not approve its numbers, effects or availability for a release.
3. **Executable content:** reviewed Godot resources in `project/data/` and their
   supporting implementation. T7 establishes a release manifest identifying the
   exact source hashes, approved specification revisions and runtime resources.

For this phase, use **explicit, reviewed conversion into Godot resources**. Do not
execute draft prose, infer effects from value IDs, or automatically overwrite runtime
resources whenever a Tree Lab export changes. T7 may automate deterministic field
copying, but executable effects require an approved mapping and supported handler.
There must be one released definition per runtime ID. Test-only representative
content is explicitly scoped to fixtures until its dependencies are implemented.

Promotion sequence: import a candidate export; compare with the previous hash;
validate its structure; review the semantic diff and affected decisions; update the
identity/revision record; implement approved fields; validate the complete reference
graph and focused behavior; then update the release manifest. Unsupported effects
block release of the affected content, rather than disappearing as no-ops. Partial
milestone builds must declare the available subset and must not claim all four trees
are implemented. Do not activate new persistence against an incomplete content registry.

## 2. Versions and validation

Keep these independent:

- Tree Lab interchange `schema_version` stays 1 until that tool's contract changes.
  Do not insert unsupported revision fields into its exports.
- Source SHA-256 identifies the exact audited export. Array pointers are locators
  within that revision, not permanent identities across reordered exports.
- The identity manifest has its own schema version and revision. The first is
  `p6m2-t4-1`; current `p6m2-t4-2` finalizes the save policy without changing
  identity mappings. Later identity changes retain old mappings and append explicit
  replacements.
- The first released Phase 6 content revision is `p6.1`, assigned only by T7 when
  executable content is ready. Subsequent numeric revisions identify content changes.
- Adventure's new envelope is `save_version: 2`, containing
  `build_schema_version: 1` and a released `content_revision`. Practice uses its own
  envelope version 1 with the same build schema. Unsupported future versions or
  content revisions are rejected without altering live state or files.

Validation layers:

| Layer | Required checks |
| --- | --- |
| Interchange | Existing Tree Lab structural/semantic checks; finite numbers; valid local references; known schema; exact source hash. Unknown icons retain IDs and use a placeholder during design. |
| Combined identity | Source identity is keyed by file, revision, kind and source ID; all targets exist or are explicitly reserved; global runtime uniqueness; tree membership; no accidental merging of the six collisions. Multiple sources may grant one skill only through an explicit shared-skill mapping. |
| Approved build content | Integer positive rank caps; one point per rank; gates 0/5/10/15/20; unlocks 1/3/6/9/12; prerequisite references within the tree; no cycles; reachable purchase paths within the 45-point budget. Empty slots grant nothing and do not block later slots. |
| Executable content | Every enabled effect has an approved specification, supported type, explicit unit/bucket and required timing fields; references, resource types and icon paths resolve; release manifest and runtime IDs agree. Missing mechanic definitions fail promotion. |
| Saved build | Strict field types before conversion; distinct valid roles; integer budget 0–45; integer ranks within bounds; selected-tree membership; total spend within budget; all retained prerequisites and resulting-total gates legal. No allocation-history reconstruction. |

Content edits must report changed rank caps, gates, prerequisites, grants, effects
and retired IDs. Cosmetic renames retain IDs. Changed meaning is reviewed explicitly;
new concepts get new IDs. Retired IDs are tombstoned and never reused for unrelated
content. Each release declares supported revisions and explicit incompatible older
revisions. Compatible revisions retain valid builds; known incompatible older saves
use the fresh-run policy below. Do not classify corrupt or future data as a known
older incompatible save merely to bypass validation.

## 3. Identity and ambiguity decisions

The linked JSON manifest inventories all four trees, four intrinsics, 44 talents,
20 automatic slots (including two empty slots), 20 distinct skill definitions and
the existing class/skill/talent resource paths. Source objects are identified by
file, hash and JSON pointer as well as their exact authored ID when present.

Reserve existing `tree.assassin`, `tree.bladedancer`, `tree.shadow`, `tree.thief`
and their resource paths. New talents use `talent.<tree>.<concept>`; retain
unambiguous existing identities for Umbral Presence, Gilded Blade, Keen Eye and
Sticky Fingers. This is content identity continuity only. Old binary allocations
are not migrated: the user selected a complete fresh-run reset.

Retain current skill IDs, including `skill.rending_thrust` for Rending Slash,
`skill.toxic_flurry` for Beguiling Strike and `skill.killers_mark` for Death Strike.
Keep their existing filenames. New skill identities use `skill.<concept>`.
Existing Stab, Heavy Slash and Hold remain class skill identities.

For newly created resources, use `res://data/talents/<tree>/<concept>.tres`
and `res://data/skills/<concept>.tres`; the manifest's null existing path means
the file does not exist yet, not an unresolved identity. T7 records actual new
paths in its release registry. Intrinsics and unlock slots may remain embedded
tree data rather than separate resources. Legacy placeholder skills remain
test-only and gain no player-facing grant from their presence in the inventory.

| Source collision | Explicit destinations |
| --- | --- |
| `draft.assassin` in Assassin / Bladedancer | `tree.assassin` / `tree.bladedancer` |
| `talent.quick_hands` in Assassin / Bladedancer | `talent.assassin.quick_hands` / `talent.bladedancer.weakness` |
| `talent.precision` in Assassin / Bladedancer | `talent.assassin.precision` / `talent.bladedancer.wet_stone` |
| `talent.bypass` in Assassin / Bladedancer | `talent.assassin.bypass` / `talent.bladedancer.opportunity` |
| `talent.critical_poison` in Assassin / Bladedancer | `talent.assassin.critical_poison` / `talent.bladedancer.virulent_corruption` |
| `draft.skill.venom_jab` in Assassin / Bladedancer | `skill.venom_jab` / `skill.quick_cut` |

The old Bladedancer `talent.quick_hands` is **not** an alias for Assassin's new
Quick Hands or Bladedancer's Weakness. Likewise, Silvered Blade is not silently
renamed to Silvered Edge, and the old Big Score talent is not a skill alias.
Their legacy entries are recorded separately in the manifest.

Resolve other Q16 inputs as follows:

- Shadow's empty subclass is explicitly mapped to Shadow by this reviewed source
  file; the importer must not guess from the UUID or missing field.
- Preserve authored spelling: Poison Vile, Load Dice and Pick pocket. On 2026-10-01,
  the user approved correcting Wet Stone to Whetstone. Its stable runtime ID
  remains `talent.bladedancer.wet_stone`; this is a display-name-only correction.
  Trim Beguiling Presence's trailing whitespace for display only; retain raw source.
- Keep Assassin's populated fifth slot; its contradictory note remains historical
  evidence, not an instruction to delete the skill.
- Keep both empty 9-point slots as null. T5/M5 decide future content; do not invent
  skill IDs, fallback grants or value effects for them.
- Weakness's `ias`, Whetstone's `crit`, and intrinsic `poison_per_point` keys are
  source labels, not handler selectors. Explicit semantic mappings must encode the
  approved Shred Value, base physical, retrigger and flat elemental meanings.
- Charisma's empty value label can display Shop Discount from its explicit mapping.
  Death Pact's `%` timer remains an unresolved mechanic/unit owned by M3/M5; block
  its executable conversion until specified.
- Heavy Strike is an unresolved prose reference. Do not add a Heavy Slash alias
  until the Bladedancer review confirms it; only affected mechanics are blocked.
- Icon validity permits a placeholder, not final-art approval. M4/M7 own art review.

## 4. Ranked save contract and migration

Build payload (field names are the T7 implementation contract):

```json
{
  "build_schema_version": 1,
  "content_revision": "p6.1",
  "primary_tree_id": "tree.assassin",
  "secondary_tree_id": "tree.shadow",
  "earned_talent_points": 10,
  "talent_ranks": {"talent.assassin.quick_hands": 5},
  "rotation_skill_ids": ["skill.stab", "skill.stab", "skill.hold"]
}
```

Adventure keeps its non-build save fields and gear/generated-contract formats.
The build payload is the sole source of budget and allocations; do not save a
second disagreeing copy. Unspent points, intrinsics, unlocked skills and resolved
stats are derived. Zero ranks are omitted when writing; duplicate object keys must
be rejected during parsing rather than silently overwritten. Null primary is valid
only in the existing preselection state, with no secondary or allocated ranks.
Secondary selection remains gated by inherited Adventure access; Practice has
immediate access. Do not infer role changes from a compact array after deletion.

Loads first classify the save envelope. Supported saves resolve and validate a
candidate before committing it to live state. Malformed or unsupported future data
leaves live state and files unchanged and reports a useful reason. A **known older
incompatible save** follows the explicit reset outcome below instead. T7 must give
callers distinct loaded, reset-incompatible, missing and failed outcomes rather than
using one boolean to treat every failure as a new run.

### Agreed legacy-save policy — full fresh run

User decision on 2026-09-22 (P6M2-D006): **“Invalidate old saves and reset everything
to a fresh run.”** This supersedes the proposed progress-preserving talent refund.

- Phase 5/version-1 Adventure saves cannot resume in Phase 6. Recognize their
  envelope before loading any legacy class, tree, talent, gear or route resources.
  There is no per-talent migration, point refund, catch-up reward or migration editor.
- Initialize the same complete state as the ordinary New Run flow, including its
  normal seed policy. Retain no old selected class/trees/roles, talent points,
  allocations, rotation, gold, equipment, inventory, shop offers/state, pending
  rewards, route/contract position, completed-contract count, claim markers,
  encounter history, records, retries, failures or combat state. Use the normal
  fresh-run starting defaults rather than copying any of these from the old save.
- Enter the normal new-run/class-selection flow and show a concise notice that
  the skill-tree redesign invalidated the old save and started a fresh run. Do not
  present a resumable old run or require a second migration-policy choice.
- Replace the active incompatible save with the fresh current-format state through
  the normal save lifecycle. No old gameplay state is retained as a fallback or
  merged into the new save. If writing fails, report it; do not claim persistence
  succeeded. A later launch seeing the old envelope again starts fresh again,
  rather than importing its data. This does not assert atomic-write durability.
- Once a current-format save exists, ordinary load resumes it. Loading again must
  not reset a compatible new run, replay old rewards or preserve a special respec
  privilege. T3 respec rules apply without migration exceptions.

The legacy resource inventory remains useful for content continuity, tooling and
reference checks. It is not an import allowlist for version-1 player progress.
“Everything” here is the saved run; this policy creates no filesystem-wide deletion
operation. T4 records the rule; T7 implements it and T8 verifies its behavior.

### Subsequent Phase 6 revisions and invalid data

Use explicit aliases only for recorded identity continuity. Compatible prior Phase 6
revisions retain allocations that are legal under the current approved content.
Cosmetic or numerical changes alone do not force a reset. A release that removes
content or changes legality without a supported compatibility path must explicitly
mark the affected older revision incompatible; the same complete fresh-run reset
applies. No automatic talent-only refund or arbitrary rank trimming is adopted.
T7 records supported versus incompatible revisions in its release manifest.

Malformed current-revision allocations (fractional/negative/over-max ranks, unknown
IDs, bad roles, overspend, missing prerequisites or failed retained gates) reject
the load without repair or reset. Unsupported future schema/revision data rejects
similarly. Do not overwrite these files merely because loading failed. Resource-path
aliases for supported content must be allowlisted, acyclic and version-scoped.
Never load arbitrary paths supplied by a build save.

## 5. Practice Room, rotation and edit persistence

Implement a separate `user://practice_build.json` (practice envelope version 1),
never reuse `save.json` or the Adventure singleton. Save the last committed setup:
class, explicit tree roles, ranks, budget 0–45, ordered rotation IDs, practice gold,
all five editable practice items plus equipment selections, target snapshot,
duration, fight seed, random-seed setting and generated-target configuration.
Retain the actual target snapshot and seed for reproducibility rather than rerolling
on load. Use existing gear value encodings where applicable; do not redesign gear.

Persist successful setup edits and restore on entry. Batch a UI transaction into
one write, never write intermediate invalid ranks or an in-progress fight. Store
the configured pre-fight gold separately from gold gained in practice playback.
Do not persist combat result objects, temporary buffs, stolen-gold counters, RNG
continuation or build locks. Closing/reopening begins a new fight from the setup.
No practice file means current default setup. An explicitly incompatible older
practice revision resets the entire practice setup to defaults and replaces only
the practice save through its normal save lifecycle, with a notice. An invalid file produces a notice
and a clean in-memory setup, leaving the invalid file untouched until an explicit
reset/save. Never clear or modify Adventure because practice restoration failed.

Practice permits changing roles/trees freely as a sandbox; removing a tree clears
only that tree's ranks. Do not promote secondary implicitly when primary is removed:
clear both roles, their ranks and affected rotation entries as an explicit reset.
Changing primary while retaining a distinct secondary preserves secondary ranks
if legal. Reject a budget reduction below current spend atomically; refund first.
No general undo history or named preset library is required in T4/T7.

For every load or completed edit, resolve skills once from the final build, then
map each rotation entry by exact ID, preserve surviving order and repeated entries,
and retain the first ten available entries. Report unavailable entries and overflow
separately. Skills granted by another retained talent/tree/gear source survive.
Do not deduplicate, auto-insert newly unlocked skills or restore previously removed
entries. Empty rotation is a valid editing state, but cannot lock/start combat.
Loading and changing a build clear its lock. Persist only the committed normalized
rotation; a canceled draft edit changes neither live state nor disk state.

## 6. Acceptance cases for T7/T8

These are required future tests, not gameplay tests executed during T4.

| ID | Input/action | Required outcome |
| --- | --- | --- |
| T4-C01 | Four audited exports | Exact hash/object coverage; 44 talents, 140 ranks, four intrinsics, 20 slots, 20 skill definitions; all six collision groups map without merges. |
| T4-C02 | Change source hash, reorder objects, duplicate target ID or remove a mapping | Reject stale/ambiguous manifest; explicit revision review required. |
| T4-C03 | Unresolved Death Pact unit, misleading value ID, Heavy Strike reference | Preserve source; no inferred handler/unit/alias; affected executable promotion fails. |
| T4-C04 | Bladedancer/Thief empty slot at 9 and populated slot at 12 | No grant at empty slot; later grant still works. |
| T4-C05 | Existing OR prerequisite A-or-B versus draft ALL A-and-B | Legacy is not flattened; each approved ALL reference becomes its own singleton group if using existing resources. |
| T4-S01 | Valid v2 mixed build, 45 budget, repeated skills | Round-trip roles/ranks/budget/rotation; resolve fresh; lock cleared. |
| T4-S02 | Future version/revision, malformed JSON, duplicate key, unknown tree | Reject with live state and files unchanged; caller does not silently start/save a new run. |
| T4-S03 | Negative/fractional/over-max ranks, overspend, bad prerequisite/gate | Reject current-revision build; no cascade or lost earned points. |
| T4-S04 | T3's retained Quick Hands 4 + Hastened Poison 1 | Accept retained five-point tree despite insufficient lower-row points to reconstruct purchase order. |
| T4-S05 | Moved resource path but stable known ID | Resolve via registry/versioned alias; display rename does not lose allocation. |
| T4-S06 | Old Bladedancer Quick Hands / Silvered Blade / Big Score | Never infer new talent/skill equivalence from display names. Version-1 saves reset in full before resource resolution. |
| T4-S07 | Legacy save before Tavern end, at old cap, between contracts, mid-contract | Each resets to the ordinary New Run state. Verify all run fields against a clean-run fixture: no retained progress, gear, gold, points, roles, claims, history or seed from the old save. |
| T4-S08 | Load same old save twice, then save new format and reload | Old envelope always resets without importing resources. After fresh current-format save succeeds, reload preserves the new run. Simulated write failure is reported; no false success or old-state merge. |
| T4-S09 | Approved later content revision removes talent/dependency | Explicitly incompatible older revision resets the entire run; a supported cosmetic revision preserves the legal build. No talent-only refund or arbitrary rank trimming. |
| T4-R01 | Unknown/unavailable IDs interleaved with 12 available entries | Keep first ten available entries in order, including repeats; report removed and overflow entries. |
| T4-R02 | Refund last grant, retain alternate grant, re-unlock later | Remove only truly unavailable skills; no automatic restoration after a later unlock. |
| T4-R03 | Empty rotation after load/edit | Editing allowed; combat and locking rejected. |
| T4-P01 | Save/reopen practice with 0/10/45 budget, custom gear/target/seed | Restore committed setup; Adventure bytes/state unchanged; temporary fight data absent. |
| T4-P02 | Missing/corrupt/future practice file | Defaults or notice as specified; no silent overwrite or Adventure effects. |
| T4-P03 | Lower budget below spend; cancel edit; remove primary | Atomic rejection/cancel; explicit primary reset; no implicit secondary promotion. |
| T4-P04 | Practice fight steals gold; reopen | Restore configured gold, not fight gains; stolen-gold counter zero. |
| T4-P05 | Explicitly incompatible older practice revision | Reset all practice setup fields and replace only the practice save; Adventure is unchanged. |

T7 should extend existing save/load, generated-contract, allocation, resolver and
Practice Room checks, using isolated temporary save paths. T8 verifies integrated
behavior and notices. Keep the inherited gear and route regression coverage.

## Handoff and completion evidence

T5 owns sequencing, representative builds and UI/diagnostic requirements. T6 owns
rank/role legality. T7 owns runtime conversion, release validation, the new save
envelopes, migration and isolated Practice Room persistence. M3/M5 settle the
explicit mechanic blockers; M7 completes icons. Source draft revisions stay intact.

T4 is complete after the user selected full fresh-run invalidation and the policy,
manifest and acceptance outcomes were reconciled. T5 is next. Identity-map checks
validate documentation coverage and references, not executable mechanics, balance
or save durability. Runtime implementation remains T6/T7 and integration T8.

Validation on 2026-09-22: `node tools/p6/check_content_identity_manifest.js`
passes for 92 source objects, 140 rank slots and 37 legacy resources;
`node tools/p6/audit_tree_drafts.js` passes with the original four hashes and
unchanged audit appendix. The manifest checker is a read-only documentation check,
not a runtime converter. T4-S07 through T4-S09 now specify fresh-run invalidation,
repeat loading/write failures and compatible versus incompatible content revisions.
Document links, whitespace and active-status consistency were checked at closeout.
No gameplay tests were run because this task changes documentation only.
