"""Reconcile processed media, isolated behavior tests and actual engine PCM."""
from pathlib import Path
import hashlib
import json
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "project/reports/m9_buff_debuff_audio"

def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None

processing = read("project/reports/m9_buff_debuff_audio/processing.json")
assert processing["pass"] and processing["selected_semitones"] == -3
for name, row in processing["sources"].items():
    assert digest(Path(row["source_path"])) == row["source_sha256"], "Original audio changed"
    output = ROOT / row["output"]["path"]
    assert digest(output) == row["output"]["sha256"], "Prepared audio changed"
    assert row["output"]["clipped_samples"] == 0 and row["output"]["peak_dbfs"] < -2.5
    assert abs(row["output"]["rms_dbfs"] + 23.26) < 0.2
    assert set(row["variants"]) == {"-2", "-3", "-4"}

groups = {
    "m9_buff_debuff_audio_verified": "m9_buff_debuff_audio_test",
    "m9_buff_debuff_audio_checks": "attack_sfx_audio_test",
    "m9_buff_debuff_audio_wasapi_capture": "m9_buff_debuff_audio_record",
}
results = []
for group, name in groups.items():
    row = next(row for row in read(f"project/reports/{group}/summary.json") if row["test"] == name)
    assert row["pass"] and row["exit_code"] == 0
    assert row["source_sha256"] == digest(ROOT / "project/tests" / (name + ".gd"))
    assert row["user_data_dir"] and "facelessvoid_flurry_" in row["user_data_dir"]
    results.append({**row, "contributing_report": f"project/reports/{group}/summary.json"})

capture = ROOT / "project/reports/m9_buff_debuff_audio_wasapi_capture/m9_buff_debuff_audio_record/buff_debuff_audio"
measurements = json.loads((capture / "measurements.json").read_text(encoding="utf-8"))
assert measurements["driver"] == "WASAPI"
pcm = []
for row in measurements["rows"]:
    path = capture / row["file"]
    with wave.open(str(path), "rb") as stream:
        assert stream.getsampwidth() == 2 and stream.getnchannels() == 2
        rate = stream.getframerate()
        samples = np.frombuffer(stream.readframes(stream.getnframes()), dtype="<i2").astype(float) / 32768
    peak = float(np.max(np.abs(samples)))
    assert abs(peak - row["peak"]) < 1e-8
    assert peak < 0.98
    if row["file"] == "effects_zero.wav": assert peak == 0
    if row["file"] == "ordinary_and_repeats.wav": assert peak > 0.005
    if row["file"] == "cancel_tail.wav": assert np.max(np.abs(samples[int(0.5 * rate) * 2:])) == 0
    pcm.append({"file": str(path.relative_to(ROOT)), "sha256": digest(path),
                "peak": peak, "peak_dbfs": float(20 * np.log10(max(peak, 1e-12))),
                "clipped_samples": int(np.count_nonzero(np.abs(samples) >= 1)), "rate": rate})

baseline = read("work/buff_debuff_audio/protected_before.json")
protected = {str(path): digest(path) for root in baseline["roots"] if Path(root).exists()
             for path in Path(root).rglob("*") if path.is_file()}
for name in baseline["files"]:
    if name not in protected: protected[name] = digest(Path(name))
changes = sorted(name for name in set(protected) | set(baseline["files"])
                 if protected.get(name) != baseline["files"].get(name))
assert not changes, ("Protected files changed", changes)

prior = read("project/reports/m9_t9_final/verification.json")["runtime_art_resource_sha256"]
runtime = {str(path.relative_to(ROOT)).replace("\\", "/"): digest(path)
           for directory in ["scripts", "scenes", "data", "assets"]
           for path in (ROOT / "project" / directory).rglob("*")
           if path.is_file() and path.suffix not in [".import", ".uid"]}
runtime["project/project.godot"] = digest(ROOT / "project/project.godot")
runtime_changes = sorted(name for name in set(prior) | set(runtime) if prior.get(name) != runtime.get(name))
assert runtime_changes == sorted([
    "project/assets/audio/fx/skills/debuff.mp3", "project/assets/audio/fx/skills/self_buff.mp3",
    "project/scenes/training_room/training_room_combat_view.gd",
    "project/scripts/autoload/audio_manager.gd", "project/scripts/ui/combat_playback_presenter.gd"])
extra = ["tools/p6/prepare_buff_debuff_audio.py", "tools/p6/check_buff_debuff_audio.py",
         "project/tests/m9_buff_debuff_audio_test.gd", "project/tests/m9_buff_debuff_audio_record.gd"]
report = {"pass": True, "contributing_runs": results, "engine_capture_driver": "WASAPI", "pcm": pcm,
          "runtime_changes_since_T9": runtime_changes,
          "source_sha256": {name: digest(ROOT / name) for name in runtime_changes + extra},
          "originals_unchanged": True, "protected_unchanged": True, "protected_count": len(protected),
          "listening_status": "Technical mix/clip checks pass. Original, milder and darker comparison files retained for user listening; no human listening or subjective acceptance claimed.",
          "limits": "Recorded Godot mixer output verifies decoding, gain/cancellation and overlap, not speaker hardware. Known certificate/shutdown diagnostics remain."}
(OUT / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({key: report[key] for key in ["pass", "originals_unchanged", "protected_unchanged", "protected_count", "engine_capture_driver"]}))
