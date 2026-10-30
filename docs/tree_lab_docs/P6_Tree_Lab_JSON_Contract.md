# Tree Lab JSON contract — version 1

Machine schema: `tools/tree-lab/schema/tree-lab-v1.schema.json` (JSON Schema
2020-12). This is a proposed design interchange contract, not a Godot loader.

## Files

- `tools/tree-lab/templates/empty-tree.json`: canonical initial design; five
  levels, no talents, empty intrinsic values, five unassigned automatic slots.
- `tools/tree-lab/examples/assassin-sketch.json`: illustrative screenshot
  transcription, ten talents, two prerequisite links, four described/named
  automatic skills, and one empty slot.
- `tools/tree-lab/data/icon-catalog.json`: stable IDs mapped to existing local
  icons. Paths are relative to `tools/tree-lab/planning/` for this mockup; a
  production renderer resolves them through the catalog, not through imports.

## Envelope and fields

| Field | Meaning |
| --- | --- |
| `format` | Must equal `faceless-void.tree-lab` |
| `schema_version` | Integer 1; unsupported versions rejected without replacing current data |
| `tree.id` | Stable lab identity, independent of display name and filename |
| `tree.name`, `subclass`, `notes` | Designer-facing title, optional subclass text, context/uncertainties |
| `tree.levels` | Exactly five entries: stable ID, order 1–5, required total points |
| `tree.talents` | Any number of talent sketches |
| `tree.intrinsic` | Name, description, icon ID, and zero or more per-tree-point values |
| `tree.automatic_unlocks` | Exactly five ordered slots, each with its own threshold |

Each talent has `id`, `name`, `flavour_text`, `description`, `icon_id`,
`level_id`, `position.x` (0–1), `max_ranks`, `prerequisite_ids`, `values`, and
`skill_grant`. `skill_grant` is null or a `{id, name, description}` design skill.
It is granted at rank 1. Prerequisites are ALL required at rank 1; higher rank
requirements and OR groups are not part of v1.

Each automatic slot has `id`, `order`, `required_points`, `icon_id`, `skill`, and
`values`. `skill: null` represents an unassigned slot. It has no effect even if
its threshold is met. Slot order controls presentation; thresholds need not match
the five upper levels. Skill names and descriptions may remain ideas rather than
runtime mappings. Blank skill descriptions are legal; blank skill names are not.

## Scalable values

Talent values:

```json
{
  "id": "crit",
  "label": "Crit chance",
  "unit": "percentage points",
  "rank_1": 1,
  "per_rank": 1
}
```

This displays 1, 2, 3, 4, 5 percentage points at ranks 1–5. Rank zero is inactive.
A talent can contain multiple values, including negative increments for costs or
tradeoffs. Numbers are finite; no arbitrary expression evaluation is supported.
Units and labels are descriptive; a later adapter must interpret them explicitly.

Intrinsic and automatic-skill values:

```json
{
  "id": "poison_per_point",
  "label": "Increased poison damage",
  "unit": "%",
  "base": 0,
  "per_point": 1
}
```

The descriptive result is `base + total_tree_points * per_point`. Automatic
skill values are active only after their skill unlocks. Empty value lists permit
qualitative effects such as “Poison can crit.” Prose is stored verbatim; angle
brackets in design notes are plain text, not markup or evaluable placeholders.

## Semantic validation beyond JSON Schema

- Level and automatic orders are exactly 1–5 and unique.
- Level 1 requires zero points. Thresholds in each track are nondecreasing.
- Level, talent, automatic-slot, and skill IDs are globally unique within the
  tree; value IDs are unique within their owning value list.
- IDs used as dictionary keys cannot be `constructor`, `prototype`, or `__proto__`.
- Talent level references exist. Prerequisites reference existing talents,
  contain no duplicates, and point strictly upward from a lower level.
- Numbers are finite; thresholds/rank caps are integers in their stated ranges.
- Unassigned automatic slots have no scaling values.
- Unknown icon IDs produce a warning and neutral fallback, preserving the ID.
- Unreachable levels/skills and incomplete descriptions are design warnings,
  not malformed data. Do not reject a sketch merely because its balance or
  progression is unfinished.

No timestamps, calculated totals, allocation state, draft-storage envelope, image
bytes, arbitrary file paths, or executable formulas belong in exported designs.
Array order and authored values survive a round-trip. Editors may sort copies for
display; they must not silently renumber IDs when names or layouts change.

New structural fields require a versioned contract change. Version 1 rejects
unknown structural fields rather than dropping them. Before a future version
ships, define migration and backup behavior; never assume changing this format
automatically migrates existing game talent IDs or saves.

## Planning validation

`python tools/tree-lab/planning/validate_fixtures.py` checks the schema, both
fixtures, semantic references, local icon paths, and illustrative reachability.
It uses the development environment's `jsonschema` package; the browser mockup
does not need Python or that package.

`node tools/tree-lab/planning/build-preview-data.js --check` verifies that the
file-open wrapper exactly matches the JSON sources. Regenerate it without
`--check` after changing examples. Production import/export validation and actual
round-trip behavior remain TL1 acceptance work.
