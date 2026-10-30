# Tree Lab interaction rules — v1 proposal

## Editing

Edit mode never requires points to create or inspect nodes. Add talent creates a
stable ID and opens the inspector. A node needs a name before Apply; unfinished
text remains in the inspector until Apply or Cancel. Blank descriptions and
unfilled effect ideas are allowed. Apply changes is one undoable action.

Dragging snaps to one of five rows and updates `level_id`; horizontal position
is a normalized 0–1 coordinate. The inspector also offers level and horizontal
position controls. A row can contain any number of talents; overlapping nodes
receive a layout warning and can be rearranged. Responsive presentation must not
rewrite saved coordinates. No free vertical coordinates are stored.

Horizontal grid (implemented): 21 equally spaced column centers at `i / 20`
for i = 0 through 20. Snapping defaults on for the session and applies only when
dragging or changing the horizontal-position field. Turning it off permits free
placement. Guides appear in Edit mode; Allocate mode hides them. Align all to grid
rounds each talent to its nearest column as one undoable edit. Loading, importing,
restoring, toggling snap, or editing unrelated fields preserves existing positions.
The JSON format is unchanged. Nodes sharing a column are not merged or displaced;
the existing overlap warning helps identify collisions.

Prerequisites are selected through a searchable node dropdown and displayed as
upward arrows. Each source must be on a strictly lower level. Multiple sources
use AND semantics, each requiring rank 1. Reject self-links, duplicate links,
missing IDs, and links from the same/higher level. Moving a node cannot silently
break links: reject the edit with the specific affected connections until they
are removed or changed. Purely descriptive synergy notes belong in prose.

Deleting a talent removes its incoming/outgoing connections and preview ranks in
one undoable action. Show a short notification listing the affected connections.
Deleting an automatic unlock's content clears its slot, not the five-slot track.
The intrinsic remains an editable singleton. Levels and automatic slots remain
exactly five in v1.

Level 1 always requires zero points, preventing an unusable empty starting row.
Levels 2–5 require nonnegative integer thresholds in nondecreasing order; equal
thresholds are legal. Automatic thresholds are independently nondecreasing
nonnegative integers; zero permits a free starting skill. Warn on unreachable
tiers/unlocks but allow export of structurally valid incomplete sketches.

## Allocating points

Let P be the sum of purchased talent ranks in this tree. Automatic unlocks and
the intrinsic neither spend nor contribute points. Each rank costs one point.

Before buying a rank, require all of:

- At least one unspent budget point.
- Current rank is below the talent's maximum.
- P is at least the talent level's threshold (before the purchase).
- Every prerequisite source has rank >= 1.

Points in any purchased talent count, including ranks in the same or higher
level. There is no requirement to spend N points in the immediately previous
row. Unlocks are recalculated, not permanently latched. Blocked nodes remain
selectable so their tooltip/inspector can explain the missing points or source.

Keep click-to-select consistent across modes. In Allocate, expose labelled + and
minus controls on the selected talent; never make right-click the only refund
path. Show rank/current maximum, spent/budget, level gates, intrinsic result,
and automatic unlock states after every operation.

## Refunds and validity

Proposed rule: refund one rank, then remove allocations that are no longer
reachable by a legal sequence of purchases. This avoids a high-tier talent
supporting its own gate after its foundational points were refunded.

For deterministic normalization, keep the requested ranks as targets and replay
from zero. Visit candidates in ascending level order, then stable talent ID;
buy one desired rank whenever its gate and prerequisites hold, repeating until
no purchase is possible or the budget is exhausted. The result retains every
reachable requested rank when budget is sufficient. A budget decrease uses the
same order, favoring earlier levels; it never spends ranks the user did not
request. Show all removed ranks and return the points to the available budget.
One Undo restores the entire operation, including the original budget when
appropriate. Reset preview clears all ranks and is also undoable.

Examples with a 3-point level-2 gate:

- Three rank-1 talents in level 1 open level 2, just like three ranks in one
  level-1 talent. A fourth point may then buy a level-2 talent.
- A level-2 talent linked to A stays blocked if A has zero ranks, even when
  other talents provide three total points. A at rank 1 is sufficient.
- With A=3 and B(level 2)=1, refunding A to 2 removes B too. B cannot supply
  its own third qualifying point during replay.
- With A=4 and B=1, refunding A to 3 keeps B.
- At a 1-point automatic threshold, the first spent point unlocks the skill;
  refunding to zero relocks it. A blank automatic slot never grants a skill.

Applying edits to thresholds, maximum ranks, prerequisites, or node membership
replays the preview using the same rule and reports changes. Name, icon, prose,
scaling values, and horizontal-position edits do not change allocation legality.

## Values and descriptions

Each scalable value has a label, unit, rank-1 value, and per-additional-rank
increment. At rank r >= 1, display `rank_1 + (r - 1) * per_rank`.
At rank zero show “Not allocated” and the next-rank value; do not imply an active
effect. Negative increments are allowed (for drawbacks); numbers must be finite.
Whole percentage points are used: 1 means 1%, not 0.01. Labels distinguish
percentage points, multipliers, flat values, stacks, and other designer units.
No stacking interpretation or damage calculation is inferred from a label.

Intrinsic values use `base + P * per_point`, labelled as descriptive totals.
Automatic skill descriptions may carry scalable values labelled by tree points,
using that same formula; plain text alone is also valid. Optional upper-tree
skill grants activate at the talent's first rank and use its description. These
are displayed design promises, not executable skill implementations.

## Import, export, and recovery

Validate a file in isolation before replacing the current design. Reject invalid
JSON, unsupported format/version, duplicate IDs, bad types/ranges, unknown
structural fields, broken references, and invalid links. Present useful paths,
such as `tree.talents[2].level_id`; retain the open design and draft on failure.
Render imported text as text, never HTML. Unknown icon IDs render a neutral
fallback and preserve the original ID, with a warning.

Structural errors block import/export. Design warnings (empty rows, incomplete
descriptions, unreachable payoff, node overlap) do not. Export preserves all
authored data and uses readable JSON; editor state and preview allocations are
not exported. Reimport starts with zero allocations and retains the proposed
default budget. A successful import can be undone to the previous design.

First launch uses the empty default. A valid stored draft prompts Restore; a
corrupt or newer-version draft is retained for download/recovery and never
silently overwritten. Storage failure shows “Draft not saved; export JSON to
keep your work.” Export cancellation is not success. Direct file-open browser
storage behavior varies; JSON is the portable source of truth.

## Accessibility

Names, ranks, and locked/unlocked text supplement icon/color states. Details are
available on hover, keyboard focus, and click. All actions have labelled native
controls and visible focus. Keep dragging optional; provide level/position
fields. Tooltips stay in view; inspector remains usable when content is long.
