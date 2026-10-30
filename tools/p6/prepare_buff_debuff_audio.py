"""Prepare lower, softer category cues while preserving supplied source files.

Requires numpy and an FFmpeg build with rubberband + libmp3lame. A local
imageio-ffmpeg wheel may be installed under work/buff_debuff_audio/dependencies.
"""
import argparse
import hashlib
import json
import math
import subprocess
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "work/buff_debuff_audio"
RATE = 48000
CHANNELS = 2
SETTINGS = {
    "self_buff": {"start": 0.025, "end": 1.35, "fade_out": 0.08, "highpass": 90},
    "debuff": {"start": 0.16, "end": 1.05, "fade_out": 0.045, "highpass": 70},
}

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def decode(ffmpeg, path):
    run = subprocess.run([str(ffmpeg), "-v", "error", "-i", str(path),
                          "-f", "f32le", "-ac", "2", "-ar", str(RATE), "-"],
                         capture_output=True, check=True)
    return np.frombuffer(run.stdout, dtype="<f4").reshape(-1, CHANNELS).copy()

def db(value):
    return 20 * math.log10(max(float(value), 1e-12))

def measure(samples):
    chunks = samples[:len(samples) // 480 * 480].reshape(-1, 480, CHANNELS)
    rms = np.sqrt(np.mean(chunks.astype(float) ** 2, axis=(1, 2)))
    active = np.flatnonzero(rms > 10 ** (-48 / 20))
    mono = samples.astype(float).mean(axis=1)
    spectrum = np.abs(np.fft.rfft(mono)) ** 2
    frequencies = np.fft.rfftfreq(len(mono), 1 / RATE)
    return {"seconds": len(samples) / RATE, "peak_dbfs": db(np.max(np.abs(samples))),
            "rms_dbfs": db(np.sqrt(np.mean(samples.astype(float) ** 2))),
            "clipped_samples": int(np.count_nonzero(np.abs(samples) >= 1.0)),
            "first_active_sec": float(active[0] / 100) if len(active) else None,
            "last_active_sec": float((active[-1] + 1) / 100) if len(active) else None,
            "spectral_centroid_hz": float(np.sum(frequencies * spectrum) / max(np.sum(spectrum), 1e-20)),
            "energy_above_6khz_fraction": float(spectrum[frequencies > 6000].sum() / max(spectrum.sum(), 1e-20))}

def balance(samples, target_db=-23.0):
    rms = np.sqrt(np.mean(samples.astype(float) ** 2))
    peak = float(np.max(np.abs(samples)))
    gain = min(10 ** (target_db / 20) / max(rms, 1e-12),
               10 ** (-3 / 20) / max(peak, 1e-12))
    return (samples * gain).astype("<f4"), db(gain)

def write_wav(path, samples):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as stream:
        stream.setnchannels(CHANNELS)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(np.rint(np.clip(samples, -1, 1) * 32767).astype("<i2").tobytes())

def process(ffmpeg, samples, semitones, settings):
    pitch = 2 ** (semitones / 12)
    filters = (f"rubberband=tempo=1:pitch={pitch:.12f}:transients=mixed:channels=together,"
               f"highpass=f={settings['highpass']},equalizer=f=3200:t=q:w=0.8:g=-2.5,lowpass=f=6500")
    run = subprocess.run([str(ffmpeg), "-v", "error", "-f", "f32le", "-ar", str(RATE),
                          "-ac", "2", "-i", "-", "-af", filters, "-f", "f32le", "-"],
                         input=samples.astype("<f4").tobytes(), capture_output=True, check=True)
    result = np.frombuffer(run.stdout, dtype="<f4").reshape(-1, CHANNELS).copy()
    # Retain the transient while making edits click-free; fade the quiet reverb tail.
    attack = min(round(0.003 * RATE), len(result))
    tail = min(round(settings["fade_out"] * RATE), len(result))
    result[:attack] *= np.linspace(0, 1, attack)[:, None]
    result[-tail:] *= np.linspace(1, 0, tail)[:, None]
    balanced, gain_db = balance(result)
    return balanced, filters, gain_db

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=Path(r"F:\Data\Junk\DPS Game\Sounds"))
    parser.add_argument("--ffmpeg", type=Path)
    args = parser.parse_args()
    ffmpeg = args.ffmpeg or next((WORK / "dependencies/imageio_ffmpeg/binaries").glob("*.exe"))
    previews = ROOT / "project/reports/m9_buff_debuff_audio/previews"
    previews.mkdir(parents=True, exist_ok=True)
    assets = ROOT / "project/assets/audio/fx/skills"
    assets.mkdir(parents=True, exist_ok=True)
    report = {"ffmpeg": str(ffmpeg), "sample_rate": RATE, "channels": CHANNELS,
              "selected_semitones": -3, "rms_target_dbfs": -23, "peak_ceiling_dbfs": -3,
              "no_added_reverb": True, "sources": {}}
    for name, settings in SETTINGS.items():
        source = args.source / (name + ".mp3")
        before = digest(source)
        original = decode(ffmpeg, source)
        trimmed = original[round(settings["start"] * RATE):round(settings["end"] * RATE)]
        reference, _ = balance(trimmed)
        write_wav(previews / (name + "_trimmed_reference.wav"), reference)
        row = {"source_path": str(source), "source_sha256": before, "original": measure(original),
               "trim": settings, "variants": {}}
        chosen = None
        for semitones in [-2, -3, -4]:
            rendered, filters, gain_db = process(ffmpeg, trimmed, semitones, settings)
            path = previews / f"{name}_minus{abs(semitones)}.wav"
            write_wav(path, rendered)
            row["variants"][str(semitones)] = {**measure(rendered), "filters": filters,
                                              "balance_gain_db": gain_db, "wav": str(path.relative_to(ROOT))}
            if semitones == -3:
                chosen = rendered
                subprocess.run([str(ffmpeg), "-v", "error", "-y", "-i", str(path),
                                "-codec:a", "libmp3lame", "-b:a", "192k", "-ar", str(RATE),
                                "-map_metadata", "-1", str(assets / (name + ".mp3"))], check=True)
        output = assets / (name + ".mp3")
        row["output"] = {**measure(decode(ffmpeg, output)), "path": str(output.relative_to(ROOT)), "sha256": digest(output)}
        assert row["output"]["clipped_samples"] == 0 and row["output"]["peak_dbfs"] < -2.5
        assert row["output"]["seconds"] < row["original"]["seconds"]
        assert row["output"]["seconds"] <= len(trimmed) / RATE + 0.05, "Pitch shift changed duration"
        assert digest(source) == before, "Source file changed"
        # Loudness-matched trimmed original -> selected, separated by silence.
        silence = np.zeros((round(0.55 * RATE), CHANNELS), dtype="<f4")
        write_wav(previews / (name + "_comparison.wav"), np.concatenate([reference, silence, chosen]))
        row["source_unchanged"] = True
        report["sources"][name] = row
    report["pass"] = True
    (previews.parent / "processing.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({name: row["output"] for name, row in report["sources"].items()}, indent=2))

if __name__ == "__main__":
    main()
