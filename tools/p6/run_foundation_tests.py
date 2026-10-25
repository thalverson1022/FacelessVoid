"""Run focused Godot SceneTree tests with isolated save paths and error scanning."""
import argparse
import hashlib
import os
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_TESTS = [
    "p6_ranked_build_test", "p6_build_state_progression_test",
    "p6_persistence_test", "p6_persistence_ui_test",
    "p6_foundation_integration_test", "p6_balance_adapter_test", "p6_save_boundary_integration_test",
    "passive_allocator_test", "rotation_cap_test", "encounter_reward_test",
    "contract_route_data_test", "contract_route_generator_test",
    "generated_contract_outcome_test", "save_load_test",
    "generated_contract_save_load_test", "p5m2_save_load_boundary_test",
    "training_room_build_test", "training_room_fight_test",
    "skill_tooltip_formatter_test", "combat_screen_test",
    "p5m3_stat_sheet_aggregation_test", "p5m11_overkill_gold_test",
    "deterministic_replay_test", "save_load_ui_test", "training_room_entry_test",
    "training_room_fight_setup_test", "generated_route_commit_flow_test", "build_panels_test", "balance_lab_test",
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("tests", nargs="*", default=DEFAULT_TESTS)
    parser.add_argument("--godot", default=r"F:\Applications\Godot\Godot_v4.7-stable_win64_console.exe")
    parser.add_argument("--report-name", default="p6_t8")
    parser.add_argument("--isolate-reports", action="store_true", help="Copy test and rebase report paths to this run")
    parser.add_argument("--timeout", type=int, default=180, help="Per-suite timeout in seconds")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-z0-9_]+", args.report_name):
        parser.error("Expected a report directory basename")
    report_resource = "res://reports/" + args.report_name
    output = ROOT / "project/reports" / args.report_name
    output.mkdir(parents=True, exist_ok=True)
    protected = [Path(os.environ["APPDATA"]) / "FacelessVoid" / name for name in ["save.json", "practice_build.json", "practice_bladedancer_core.json"]]
    protected += [Path(os.environ["APPDATA"]) / "Godot/app_userdata/Project Enigma" / name for name in ["save.json", "practice_build.json"]]
    protected += [ROOT.parent / "Project-Enigma/project" / name for name in ["project.godot", "export_presets.cfg"]]
    def fingerprint(path):
        return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
    before = {str(path): fingerprint(path) for path in protected}
    results = []
    for name in args.tests:
        if not re.fullmatch(r"[a-z0-9_]+_test", name):
            parser.error("Expected a test script basename")
        source = ROOT / 'project/tests' / (name + '.gd')
        parent_resource = f'res://tests/{name}.gd'
        if args.isolate_reports:
            copied = output / (name + '_source.gd')
            def rebase(match):
                relative = match[1]
                target = output / name / relative
                (target.parent if target.suffix else target).mkdir(parents=True, exist_ok=True)
                return '"' + report_resource + '/' + name + '/' + relative + '"'
            source_text = re.sub(r'"res://reports/([^"\n]+)"', rebase, source.read_text(encoding='utf-8-sig'))
            copied.write_text(source_text, encoding='utf-8')
            parent_resource = report_resource + '/' + copied.name
        wrapper = output / (name + "_isolated.gd")
        # Existing tests may override this with their own res:// test paths.
        wrapper.write_text(
            f'extends "{parent_resource}"\n\n'
            'func _initialize() -> void:\n'
            f'\tSaveSystem.save_path = "{report_resource}/{name}_save.json"\n'
            f'\tPracticeSaveSystem.save_path = "{report_resource}/{name}_practice.json"\n'
            f'\tPracticeSaveSystem.core_save_path = "{report_resource}/{name}_core_practice.json"\n'
            '\tif FileAccess.file_exists(PracticeSaveSystem.core_save_path):\n'
            '\t\tDirAccess.remove_absolute(ProjectSettings.globalize_path(PracticeSaveSystem.core_save_path))\n'
            '\tif FileAccess.file_exists(PracticeSaveSystem.save_path):\n'
            '\t\tDirAccess.remove_absolute(ProjectSettings.globalize_path(PracticeSaveSystem.save_path))\n'
            + ('\tsuper._initialize()\n' if 'func _initialize(' in (ROOT / 'project/tests' / (name + '.gd')).read_text(encoding='utf-8') else ''), encoding="utf-8")
        command = [args.godot, "--headless", "--path", str(ROOT / "project"),
                   "--log-file", str(output / (name + ".log")),
                   "-s", report_resource + "/" + wrapper.name]
        try:
            run = subprocess.run(command, capture_output=True, text=True, timeout=args.timeout)
            text = run.stdout + run.stderr
            errors = [line for line in text.splitlines()
                      if re.search(r"SCRIPT ERROR|Assertion failed|Parse Error|Compile Error|FAILED:", line)]
            passed = run.returncode == 0 and not errors
            result = {"test": name, "pass": passed, "exit_code": run.returncode,
                      "errors": errors, "command": command, "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest()}
            (output / (name + "_console.txt")).write_text(text, encoding="utf-8")
        except subprocess.TimeoutExpired as exc:
            result = {"test": name, "pass": False, "errors": ["Timeout (assertion may have stopped a test before quit)"]}
            chunks = [part.decode("utf-8", errors="replace") if isinstance(part, bytes) else (part or "") for part in (exc.stdout, exc.stderr)]
            (output / (name + "_console.txt")).write_text("".join(chunks), encoding="utf-8")
        results.append(result)
        (output / "summary.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(("PASS " if result["pass"] else "FAIL ") + name, flush=True)
        if not result["pass"]:
            print("\n".join(result["errors"]), flush=True)
    unchanged = all(fingerprint(path) == before[str(path)] for path in protected)
    (output / "isolation.json").write_text(json.dumps({"unchanged": unchanged, "before": before, "after": {str(path): fingerprint(path) for path in protected}}, indent=2), encoding="utf-8")
    if not unchanged:
        print("FAIL: protected project/save files changed", flush=True)
    (output / "summary.json").write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")
    raise SystemExit(0 if unchanged and all(r["pass"] for r in results) else 1)


if __name__ == "__main__":
    main()
