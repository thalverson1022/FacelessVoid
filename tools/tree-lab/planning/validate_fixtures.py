"""Validate planning data only; this is not the future editor's validator."""
import json
from pathlib import Path
from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"),
                      parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)))


def check(condition, message):
    if not condition:
        raise ValueError(message)


def validate(data, validator, icon_ids):
    validator.validate(data)
    tree = data["tree"]
    ids = set()
    def register(value):
        check(value not in ids, f"Duplicate ID: {value}")
        ids.add(value)
    register(tree["id"])
    for track in [tree["levels"], tree["automatic_unlocks"]]:
        check(sorted(item["order"] for item in track) == [1, 2, 3, 4, 5], "Invalid track orders")
        thresholds = [item["required_points"] for item in sorted(track, key=lambda item: item["order"])]
        check(thresholds == sorted(thresholds), "Non-monotone thresholds")
        for item in track:
            register(item["id"])
    levels = {item["id"]: item for item in tree["levels"]}
    check(next(item for item in levels.values() if item["order"] == 1)["required_points"] == 0, "Level 1 must require zero points")
    talents = {item["id"]: item for item in tree["talents"]}
    for node in tree["talents"]:
        register(node["id"])
        check(node["level_id"] in levels, "Missing level")
        for source in node["prerequisite_ids"]:
            check(source in talents, "Missing prerequisite")
            check(levels[talents[source]["level_id"]]["order"] < levels[node["level_id"]]["order"], "Prerequisite must be lower")
    for item in [tree["intrinsic"], *tree["talents"], *tree["automatic_unlocks"]]:
        value_ids = [v["id"] for v in item["values"]]
        check(len(set(value_ids)) == len(value_ids), "Duplicate value IDs")
        if item["icon_id"] not in icon_ids:
            print("WARNING: unknown icon", item["icon_id"])
        skill = item.get("skill") or item.get("skill_grant")
        if skill:
            register(skill["id"])
        if "skill" in item and item["skill"] is None:
            check(not item["values"], "Unassigned skill slot has values")
    # Unlimited-budget reachability is a design check, not a balance score.
    ranks = {node_id: 0 for node_id in talents}
    changed = True
    while changed:
        changed = False
        for node in tree["talents"]:
            if (ranks[node["id"]] < node["max_ranks"]
                    and sum(ranks.values()) >= levels[node["level_id"]]["required_points"]
                    and all(ranks[p] >= 1 for p in node["prerequisite_ids"])):
                ranks[node["id"]] += 1
                changed = True
    unreachable = [node["name"] for node in tree["talents"] if not ranks[node["id"]]]
    return unreachable


schema = read("schema/tree-lab-v1.schema.json")
Draft202012Validator.check_schema(schema)
validator = Draft202012Validator(schema)
icons = read("data/icon-catalog.json")
icon_ids = {item["id"] for item in icons}
check(len(icon_ids) == len(icons), "Duplicate icon ID")
for icon in icons:
    if icon["path"]:
        check((ROOT / "planning" / icon["path"]).is_file(), "Missing icon: " + icon["id"])
for path in ["templates/empty-tree.json", "examples/assassin-sketch.json"]:
    data = read(path)
    unreachable = validate(data, validator, icon_ids)
    check(not unreachable, "Unreachable example talents: " + repr(unreachable))
    check(json.loads(json.dumps(data)) == data, "JSON serialization changed data")
    print("PASS", path)
empty = read("templates/empty-tree.json")["tree"]
check(not empty["talents"], "Default must have no talents")
check(all(slot["skill"] is None for slot in empty["automatic_unlocks"]), "Default must have no skill content")
sample = read("examples/assassin-sketch.json")["tree"]
check(len(sample["talents"]) == 10, "Assassin transcription needs ten talents")
check(sum(len(node["prerequisite_ids"]) for node in sample["talents"]) == 2, "Expected two source-sketch links")
check(sum(slot["skill"] is not None for slot in sample["automatic_unlocks"]) == 4, "Leave fifth automatic slot blank")
print("PASS schema, semantic references, JSON serialization, icon paths, empty defaults, and Assassin reachability")
