"""Reconcile T9's contributing runs, final sources and protected-file baseline."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "project/reports/m9_t9_final"
OUT.mkdir(parents=True, exist_ok=True)

def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None

groups = {
    "m9_t9_mechanics": None,
    "m9_t9_persistence_verified": None,
    "m9_t9_persistence_marker_fixed": {"m9_t5_save_reset_test", "m9_t5_entry_test"},
    "m9_t9_persistence_final": {"m9_t5_foundation_test", "m9_t8_presentation_test", "t3_persistence_inventory_test"},
    "m9_t9_ownership_final": None,
    "m9_t9_acquisition_verified": {"m9_t6_acquisition_test"},
    "m9_t9_legendary_boundary_verified": None,
    "m9_t9_pool_verified": None,
    "m9_t9_stat_foundation_verified": None,
}
rows = []
for group, selected in groups.items():
    for row in read(f"project/reports/{group}/summary.json"):
        if selected is not None and row["test"] not in selected:
            continue
        source = ROOT / "project/tests" / (row["test"] + ".gd")
        assert row["pass"] and row["exit_code"] == 0, (group, row)
        assert row["source_sha256"] == digest(source), (group, "source changed", row["test"])
        rows.append({**row, "contributing_report": f"project/reports/{group}/summary.json"})
assert len(rows) == 15 and len({row["test"] for row in rows}) == 15
(OUT / "summary.json").write_text(json.dumps(rows, indent=2) + "\n", encoding="utf-8")

before = read("work/m9_t9/before.json")
runtime = {str(path.relative_to(ROOT)).replace("\\", "/"): digest(path)
           for directory in ["scripts", "scenes", "data", "assets"]
           for path in (ROOT / "project" / directory).rglob("*")
           if path.is_file() and path.suffix not in [".import", ".uid"]}
runtime["project/project.godot"] = digest(ROOT / "project/project.godot")
runtime_changes = sorted(name for name in set(runtime) | set(before["runtime_art_resource_sha256"])
                         if runtime.get(name) != before["runtime_art_resource_sha256"].get(name))
assert runtime_changes == ["project/scripts/systems/seven_slot_save_boundary.gd"], runtime_changes
protected = {str(path): digest(path)
             for directory in before["profile_roots"] if Path(directory).exists()
             for path in Path(directory).rglob("*") if path.is_file()}
for name in before["protected_sha256"]:
    if name not in protected:
        protected[name] = digest(Path(name))
protected_changes = sorted(name for name in set(protected) | set(before["protected_sha256"])
                           if protected.get(name) != before["protected_sha256"].get(name))
isolation = {"unchanged": not protected_changes, "before_count": len(before["protected_sha256"]),
             "after_count": len([value for value in protected.values() if value is not None]),
             "changed_paths": protected_changes, "before": before["protected_sha256"], "after": protected}
(OUT / "isolation.json").write_text(json.dumps(isolation, indent=2) + "\n", encoding="utf-8")

extra_sources = ["project/tests/t8_acquisition_test.gd", "project/tests/fixtures/m9_t9_mechanics_fixture.gd",
                 "tools/p6/run_retrigger_checks.py", "tools/p6/run_foundation_tests.py",
                 "tools/p6/check_m9_t9_evidence.py"]
final = {"pass": not protected_changes, "passing_suites": len(rows), "runtime_changes": runtime_changes,
         "runtime_art_resource_files": len(runtime), "runtime_art_resource_sha256": runtime,
         "additional_source_sha256": {name: digest(ROOT / name) for name in extra_sources},
         "protected_unchanged": not protected_changes,
         "limits": "Consolidates contributing runs, not one new execution. Endpoint gear and diagnostic skill seams do not establish earned-run power or proc-budget headroom."}
(OUT / "verification.json").write_text(json.dumps(final, indent=2) + "\n", encoding="utf-8")
print(json.dumps({key: final[key] for key in ["pass", "passing_suites", "runtime_changes", "protected_unchanged"]}))
raise SystemExit(0 if final["pass"] else 1)
