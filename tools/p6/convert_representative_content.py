"""Explicit reviewed scalar mappings. Generates TEST-ONLY slices, never promotes a tree."""
import argparse
import hashlib
import json
from pathlib import Path
from source_provenance import validate_source

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "project/tests/fixtures/p6"
# Source labels are deliberately not used to select handlers. These mappings are
# based on the audited descriptions and T4 semantic corrections, with explicit units.
MAPPINGS = {
    "talent.bladedancer.wet_stone": [("base_damage", 1.0)],
    "talent.keen_eye": [("percent_physical_damage", 0.02), ("percent_elemental_damage", 0.02)],
}


def artifacts():
    manifest = json.loads((ROOT / "docs/P6M2_T4_Content_Identity_Manifest.json").read_text(encoding="utf-8"))
    sources = {}
    for source in manifest["sources"]:
        raw = (ROOT / source["file"]).read_bytes()
        validate_source(source["file"], source["sha256"], raw)
        sources[source["file"]] = json.loads(raw)
    ids = [r["runtime_id"] for r in manifest["records"]]
    assert len(ids) == len(set(ids)), "Duplicate reserved ID"
    outputs = {}
    records = []
    for runtime_id, modifiers in MAPPINGS.items():
        record = next(r for r in manifest["records"] if r["runtime_id"] == runtime_id)
        source = sources[record["source_file"]]
        for part in record["pointer"].strip("/").split("/"):
            source = source[int(part)] if isinstance(source, list) else source[part]
        assert source["id"] == record["source_id"] and source["name"] == record["source_name"], "Stale identity pointer; review required"
        assert source["max_ranks"] == 5 and source["prerequisite_ids"] == [] and source["level_id"] == "level.1"
        tree = record["tree_id"].split(".")[-1]
        name = runtime_id.split(".")[-1]
        lines = ['[gd_resource type="Resource" script_class="Talent" format=3]', '',
                 '[ext_resource type="Script" path="res://scripts/resources/talent.gd" id="talent"]',
                 '[ext_resource type="Script" path="res://scripts/resources/talent_rank.gd" id="rank"]',
                 '[ext_resource type="Script" path="res://scripts/resources/stat_modifier.gd" id="modifier"]']
        for rank in range(1, 6):
            refs = []
            for index, (stat_id, amount) in enumerate(modifiers):
                sid = f"m{rank}_{index}"
                refs.append(f'SubResource("{sid}")')
                lines += ['', f'[sub_resource type="Resource" id="{sid}"]', 'script = ExtResource("modifier")',
                          f'stat_id = "{stat_id}"', f'value = {rank * amount:.8f}']
            lines += ['', f'[sub_resource type="Resource" id="r{rank}"]', 'script = ExtResource("rank")',
                      'stat_modifiers = Array[ExtResource("modifier")]([' + ', '.join(refs) + '])']
        lines += ['', '[resource]', 'script = ExtResource("talent")', f'id = "{runtime_id}"',
                  f'display_name = "{source["name"]}"', 'max_ranks = 5',
                  'ranks = Array[ExtResource("rank")]([' + ', '.join(f'SubResource("r{r}")' for r in range(1, 6)) + '])']
        outputs[name + '.tres'] = '\n'.join(lines) + '\n'
        outputs[tree + '.tres'] = f'''[gd_resource type="Resource" script_class="SubclassTree" format=3]

[ext_resource type="Script" path="res://scripts/resources/subclass_tree.gd" id="tree"]
[ext_resource type="Script" path="res://scripts/resources/talent.gd" id="talent"]
[ext_resource type="Resource" path="res://tests/fixtures/p6/{name}.tres" id="content"]

[resource]
script = ExtResource("tree")
id = "tree.{tree}"
display_name = "{tree.title()} â€” scalar fixture only"
ranked_content_ready = true
talents = Array[ExtResource("talent")]([ExtResource("content")])
'''
        records.append({"id": runtime_id, "source_file": record['source_file'], "pointer": record['pointer'], "resource": name+'.tres', "rank_effects": modifiers})
    outputs['manifest.json'] = json.dumps({"schema_version": 1, "content_revision": "p6.test.scalars.1", "scope": "test-only", "release_ready": False,
        "identity_revision": manifest['revision'], "sources": manifest['sources'], "specifications": ['P6M2_T3_Progression_And_Allocation_Rules', 'P6M2_T4_Content_Workflow_And_Compatibility'],
        "records": records, "excluded": "All intrinsic, skill, trigger and temporary-effect behavior. M3/M5 review blocks whole-tree release."}, indent=2) + '\n'
    return outputs


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--write', action='store_true')
    parser.add_argument('--release', action='store_true')
    args = parser.parse_args()
    if args.release:
        parser.error('Representative slices are test-only; incomplete mechanics block release')
    outputs = artifacts()
    if args.write:
        OUT.mkdir(parents=True, exist_ok=True)
        for name, text in outputs.items():
            (OUT / name).write_text(text, encoding='utf-8')
    else:
        for name, text in outputs.items():
            assert (OUT / name).read_text(encoding='utf-8') == text, f'Stale converted content: {name}'
    print('PASS: source hashes, identity mapping and explicit representative resources (test-only)')

if __name__ == '__main__':
    main()
