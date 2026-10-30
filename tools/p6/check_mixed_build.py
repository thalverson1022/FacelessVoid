"""Verify the T10 injected mixed fixture against exact T5 plans and stable IDs."""
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main():
    source = ROOT / "project/tests/fixtures/p6/mixed_build.gd"
    script = source.read_text(encoding="utf-8")
    ranks = json.loads(re.search(r"const RANKS := (\{.*?\})", script, re.S)[1])
    rotation = json.loads(re.search(r"const ROTATION := (\[.*?\])", script, re.S)[1])
    planning = json.loads((ROOT / "docs/P6M2_T5_Build_Fixtures.json").read_text())
    for fixture_id in ["m4_bladedancer_thief", "m4_thief_bladedancer"]:
        fixture = next(x for x in planning["fixtures"] if x["id"] == fixture_id)
        expected = {}
        for role in ["primary", "secondary"]:
            side = fixture[role]
            remaining = side["points"]
            for purchase in planning["profiles"][side["profile"]]["purchases"]:
                key = purchase["talent_id"]
                amount = min(remaining, purchase["to_rank"] - expected.get(key, 0))
                expected[key] = expected.get(key, 0) + amount
                remaining -= amount
                if remaining == 0:
                    break
            assert remaining == 0
        assert ranks == expected and rotation == fixture["rotation_skill_ids"], fixture_id
    identities = json.loads((ROOT / "docs/P6M2_T4_Content_Identity_Manifest.json").read_text())
    allowed = {x["runtime_id"] for x in identities["records"]}
    assert set(ranks) | set(rotation) <= allowed
    manifest = json.loads((ROOT / "project/data/p6/compatibility_manifest.json").read_text())
    assert manifest["content_revision"] == "p6.compat.1"
    assert not any("mixed_build" in x for x in manifest["resource_paths"])
    sources = ["docs/P6M2_T5_Build_Fixtures.json", "docs/P6M2_T4_Content_Identity_Manifest.json",
               "docs/talent_tree_drafts/Bladedancer.json", "docs/talent_tree_drafts/Thief.json"]
    print(json.dumps({"pass": True, "release_ready": False, "source_hashes": {
        name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in sources}}, indent=2))


if __name__ == "__main__":
    main()
