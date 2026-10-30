"""Actual-size Practice Chaos editor review, using isolated saves and preferences."""
from pathlib import Path
import hashlib
import json
import os
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "project/reports/m9_chaos_editor"
OUT.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
for key in ["APPDATA", "LOCALAPPDATA"]:
    folder = ROOT / "work/m9_chaos_editor/render_userdata" / key
    folder.mkdir(parents=True, exist_ok=True)
    env[key] = str(folder)
command = [r"F:\Applications\Godot\Godot_v4.7-stable_win64_console.exe", "--path",
           str(ROOT / "project"), "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy",
           "--position", "20000,20000", "--resolution", "1600x900", "--log-file",
           str(OUT / "render.log"), "-s", "res://tests/m9_chaos_editor_test.gd"]
run = subprocess.run(command, capture_output=True, text=True, timeout=90, env=env,
                     creationflags=subprocess.CREATE_NO_WINDOW)
console = run.stdout + run.stderr
(OUT / "render_console.txt").write_text(console, encoding="utf-8")
images = {path.name: list(struct.unpack(">II", path.read_bytes()[16:24])) for path in OUT.glob("*.png")}
sources = ["project/scenes/training_room/training_room.gd", "project/scripts/systems/training_room_state.gd",
           "project/tests/m9_chaos_editor_test.gd", "tools/p6/render_chaos_editor.py"]
summary = {"pass": run.returncode == 0 and "M9 CHAOS EDITOR PASS" in console and
           "SCRIPT ERROR" not in console and len(images) == 4 and
           all(size == [1600, 900] for size in images.values()), "exit_code": run.returncode,
           "command": command, "isolated_environment": {key:env[key] for key in ["APPDATA", "LOCALAPPDATA"]},
           "images": images, "source_sha256": {name:hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in sources},
           "limits": "Scoped rendering; existing shader/certificate-store/shutdown diagnostics remain."}
(OUT / "render_summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"pass":summary["pass"],"images":len(images)}))
raise SystemExit(0 if summary["pass"] else 1)
