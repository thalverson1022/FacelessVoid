"""Render the scoped M9 playtest layout with report-only save paths."""
from pathlib import Path
import hashlib
import json
import os
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "project/reports/m9_character_sheet_polish"
OUT.mkdir(parents=True, exist_ok=True)
sources = [
    "project/scenes/combat/active_talents_panel.gd",
    "project/scenes/combat/character_stats_panel.gd",
    "project/scenes/combat/combat_screen.gd",
    "project/scenes/training_room/training_room.gd",
    "project/scenes/training_room/training_target_panel.gd",
    "project/scenes/training_room/training_room_combat_view.gd",
    "project/scripts/ui/combat_popup_layout.gd",
    "project/scripts/ui/ranked_talent_view.gd",
    "project/tests/m9_playtest_layout_test.gd",
    "tools/p6/render_playtest_layout.py",
]
protected = [Path(os.environ["APPDATA"]) / "FacelessVoid" / name for name in
             ["save.json", "adventure_p6_m6.json", "practice_build.json",
              "practice_bladedancer_core.json", "seven_slot_epoch.json"]]
protected += [Path(os.environ["APPDATA"]) / "Godot/app_userdata/Project Enigma" / name
              for name in ["save.json", "practice_build.json"]]
def fingerprint(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
before = {str(path): fingerprint(path) for path in protected}
command = [r"F:\Applications\Godot\Godot_v4.7-stable_win64_console.exe", "--path",
           str(ROOT / "project"), "--rendering-method", "gl_compatibility",
           "--position", "20000,20000", "--resolution", "1600x900", "--log-file",
           str(OUT / "render.log"), "-s", "res://tests/m9_playtest_layout_test.gd"]
run = subprocess.run(command, capture_output=True, text=True, timeout=60,
                     creationflags=subprocess.CREATE_NO_WINDOW)
console = run.stdout + run.stderr
(OUT / "render_console.txt").write_text(console, encoding="utf-8")
images = {path.name: list(struct.unpack(">II", path.read_bytes()[16:24])) for path in OUT.glob("*.png")}
after = {str(path): fingerprint(path) for path in protected}
passed = (run.returncode == 0 and "M9 PLAYTEST LAYOUT PASS" in console and
          "SCRIPT ERROR" not in console and before == after and len(images) >= 8 and
          all(size == [1600, 900] for size in images.values()))
summary = {"pass": passed, "exit_code": run.returncode, "command": command,
           "images": images, "source_sha256": {name: fingerprint(ROOT / name) for name in sources},
           "protected_unchanged": before == after, "protected_before": before, "protected_after": after,
           "limits": "Scoped layout checks. Known shader, certificate-store and teardown diagnostics retained; no broad engine qualification."}
(OUT / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"pass": passed, "images": len(images), "protected_unchanged": before == after}))
raise SystemExit(0 if passed else 1)
