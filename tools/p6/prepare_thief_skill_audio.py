"""Reproducibly prepare Thief cues; never modify the supplied originals."""
import argparse
import json
import shutil
import subprocess
from pathlib import Path

import numpy as np

from prepare_buff_debuff_audio import RATE, CHANNELS, ROOT, decode, digest, measure, write_wav

SETTINGS = {
    "poison_vile": {"source": "vile.mp3", "start": 0.04, "end": 0.40,
                    "filters": "anull", "target_rms_dbfs": -26, "peak_ceiling_dbfs": -6,
                    "fade_in": 0.002, "fade_out": 0.015},
    "blinding_powder": {"source": "powder.mp3", "start": 0.49, "end": 0.98,
                        "filters": "anull", "fade_in": 0.002, "fade_out": 0.015},
    "pick_pocket": {"source": "pick_pocket.mp3", "start": 0.17, "end": 0.72,
                    "filters": "equalizer=f=3200:t=q:w=0.8:g=-2.5,lowpass=f=6500,"
                               "acompressor=threshold=0.125:ratio=2:attack=5:release=45:makeup=1,volume=-5dB",
                    "fade_in": 0.005, "fade_out": 0.06},
    "gold_steal": {"source": "gold_steal.mp3", "copy": True},
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path("F:/Data/Junk/DPS Game/Sounds"))
    parser.add_argument("--ffmpeg", type=Path)
    args = parser.parse_args()
    ffmpeg = args.ffmpeg or next((ROOT / "work/buff_debuff_audio/dependencies/imageio_ffmpeg/binaries").glob("*.exe"))
    assets = ROOT / "project/assets/audio/fx/skills"
    report_dir = ROOT / "project/reports/m9_thief_skill_audio_assets"
    previews = report_dir / "previews"
    previews.mkdir(parents=True, exist_ok=True)
    assets.mkdir(parents=True, exist_ok=True)
    report = {"sample_rate": RATE, "channels": CHANNELS, "ffmpeg": str(ffmpeg),
              "pitch_shift_semitones": 0, "listening_acceptance": "Not claimed; envelope and decoded signal measurements verified.",
              "rationale": {
                  "poison_vile": "Remove near-silent padding, then target -26 dBFS RMS with a -6 dBFS peak ceiling to make the unusually quiet cue usable.",
                  "blinding_powder": "Remove approximately half a second of leading silence and near-silent tail; retain level and timbre.",
                  "pick_pocket": "Keep recognizable opening, rise and main hit; shorten tail, soften transient, gently reduce highs and lower level.",
                  "gold_steal": "Faithful byte copy; no obvious padding or clipping requires correction."}, "sources": {}}
    for name, settings in SETTINGS.items():
        source = args.source / settings["source"]
        source_hash = digest(source)
        original = decode(ffmpeg, source)
        output = assets / (name + ".mp3")
        row = {"source_path": str(source), "source_sha256": source_hash,
               "before": measure(original), "processing": settings}
        if settings.get("copy"):
            shutil.copyfile(source, output)
        else:
            trimmed = original[round(settings["start"] * RATE):round(settings["end"] * RATE)]
            filters = settings["filters"]
            if "target_rms_dbfs" in settings:
                stats = measure(trimmed)
                gain_db = min(settings["target_rms_dbfs"] - stats["rms_dbfs"],
                              settings["peak_ceiling_dbfs"] - stats["peak_dbfs"])
                filters = f"volume={gain_db:.9f}dB"
                row["gain_db"] = gain_db
            row["applied_filters"] = filters
            run = subprocess.run([str(ffmpeg), "-v", "error", "-f", "f32le", "-ar", str(RATE),
                                  "-ac", str(CHANNELS), "-i", "-", "-af", filters,
                                  "-f", "f32le", "-"], input=trimmed.astype("<f4").tobytes(),
                                 capture_output=True, check=True)
            rendered = np.frombuffer(run.stdout, dtype="<f4").reshape(-1, CHANNELS).copy()
            for key, start in [("fade_in", True), ("fade_out", False)]:
                count = min(round(settings[key] * RATE), len(rendered))
                if start:
                    rendered[:count] *= np.linspace(0, 1, count)[:, None]
                else:
                    rendered[-count:] *= np.linspace(1, 0, count)[:, None]
            wav = previews / (name + "_after.wav")
            write_wav(wav, rendered)
            subprocess.run([str(ffmpeg), "-v", "error", "-y", "-i", str(wav), "-codec:a", "libmp3lame",
                            "-b:a", "192k", "-ar", str(RATE), "-map_metadata", "-1", str(output)], check=True)
        final = decode(ffmpeg, output)
        row["after"] = {**measure(final), "path": str(output.relative_to(ROOT)), "sha256": digest(output)}
        assert row["after"]["clipped_samples"] == 0
        assert digest(source) == source_hash, "Original changed"
        if name == "pick_pocket":
            assert row["after"]["seconds"] <= 0.56
            assert row["after"]["peak_dbfs"] < row["before"]["peak_dbfs"] - 5
            assert row["after"]["rms_dbfs"] < row["before"]["rms_dbfs"]
            write_wav(previews / "pick_pocket_before.wav", original)
            write_wav(previews / "pick_pocket_comparison.wav", np.concatenate([
                original, np.zeros((round(0.5 * RATE), CHANNELS), dtype="<f4"), final]))
        row["source_unchanged"] = True
        report["sources"][name] = row
    report["pass"] = True
    (report_dir / "processing.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({name: row["after"] for name, row in report["sources"].items()}, indent=2))


if __name__ == "__main__":
    main()
