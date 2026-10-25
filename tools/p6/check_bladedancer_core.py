"""Check T8 core provenance, exact planned allocation and resource references."""
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CORE = ROOT / "project/tests/fixtures/p6/bladedancer_core"


def main():
    manifest = json.loads((CORE / "manifest.json").read_text())
    assert manifest["release_ready"] is False
    for name, expected in manifest["sources"].items():
        assert hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == expected, name
    planning = json.loads((ROOT / "docs/P6M2_T5_Build_Fixtures.json").read_text())
    fixture = next(row for row in planning["fixtures"] if row["id"] == manifest["fixture_id"])
    assert fixture["budget"] == 10 and fixture["secondary"] is None
    profile = planning["profiles"][fixture["primary"]["profile"]]
    ranks = {}
    remaining = fixture["primary"]["points"]
    for purchase in profile["purchases"]:
        key = purchase["talent_id"]
        count = min(remaining, purchase["to_rank"] - ranks.get(key, 0))
        ranks[key] = ranks.get(key, 0) + count
        remaining -= count
        if remaining == 0:
            break
    script = (CORE / "core.gd").read_text()
    actual_ranks = json.loads(re.search(r"const RANKS := (.*)", script)[1])
    actual_rotation = json.loads(re.search(r"const ROTATION := (.*)", script)[1])
    assert actual_ranks == ranks and actual_rotation == fixture["rotation_skill_ids"]
    identity = json.loads((ROOT / "docs/P6M2_T4_Content_Identity_Manifest.json").read_text())
    allowed = {row["runtime_id"] for row in identity["records"]}
    references = set()
    for path in CORE.glob("*.tres"):
        text = path.read_text()
        resource_id = re.search(r'^id = "([^"]+)"', text, re.M)[1]
        assert resource_id in allowed, resource_id
        for ref in re.findall(r'path="(res://[^"]+)"', text):
            assert (ROOT / "project" / ref.removeprefix("res://")).is_file(), ref
            references.add(ref)
    packaged = json.loads((ROOT / "project/data/p6/compatibility_manifest.json").read_text())
    assert packaged["content_revision"] == "p6.compat.1"
    assert not any("bladedancer_core" in path for path in packaged["resource_paths"])
    print(f"PASS: exact T5 allocation/rotation, source hashes, stable IDs, {len(references)} references, test-only release gate")


if __name__ == "__main__":
    main()
