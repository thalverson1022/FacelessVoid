"""Summarize the reproducible live D018 35-point boss and isolated-mechanic runs."""
import json
import statistics
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "project/reports/balance/full35_random_bosses_d018"
CONTROL = ROOT / "project/reports/balance/full35_isolated_mechanics_d018"
d = json.loads((OUT / "summary.json").read_text(encoding="utf-8"))
c = json.loads((CONTROL / "summary.json").read_text(encoding="utf-8"))
assert d["complete"] and c["complete"]
for folder in (OUT, CONTROL):
    diagnostic = json.loads((folder / "diagnostics_seed1.json").read_text(encoding="utf-8"))
    assert diagnostic["all_seed1_dps_match_native"]

TREES = ["assassin", "bladedancer", "thief", "shadow"]
NAMES = dict(assassin="Assassin", bladedancer="Bladedancer", thief="Thief", shadow="Shadow")
rows, bosses = d["rows"], d["bosses"]
base = {r["tree"]: r["aggregate"]["dps"]["mean"] for r in rows if r["boss_index"] == -1}
by_boss = {b["index"]: {r["tree"]: r for r in rows if r["boss_index"] == b["index"]} for b in bosses}
winners = Counter(max(rr, key=lambda t: rr[t]["aggregate"]["dps"]["mean"]) for rr in by_boss.values())
summary = []
for tree in TREES:
    rr = [r for r in rows if r["tree"] == tree and r["boss_index"] >= 0]
    vals = [r["aggregate"]["dps"]["mean"] for r in rr]
    summary.append(dict(tree=tree, dummy_dps=base[tree], mean_boss_dps=statistics.mean(vals), retention=statistics.mean(vals)/base[tree], min_boss_mean=min(vals), max_boss_mean=max(vals), leading_bosses=winners[tree], hp_met_fraction=statistics.mean(r["aggregate"]["win_rate"] for r in rr)))

lines = ["# 35-point live builds against random bosses", "", "Live content: " + d["content_revision"] + "; balance authority D018. No gameplay content was changed.", "", "36 Ultra bosses from the active runtime generator: two independently generated examples of each of its 12 archetypes, followed by 12 mixed pairs. Generation seeds 351001–351036; partner-selection seed 351042; extended tempo. All four builds face exactly the same bosses and combat seeds 1–100. Each full tree has all 35 talent points, Crude Dagger only, no other equipment, zero starting stash gold. Gold stolen during combat contributes to Thief's damage effects.", "", "Each DPS value is the average of 100 full 30-second simulations. Boss HP and defenses are preserved. The simulator continues measuring damage for the full window after HP is exceeded; these numbers are not time-to-kill or DPS measured only while the boss is alive. Bosses use the generator's native, unscaled HP and are not calibrated to level-35 progression. HP changes stun triggering, so it was not replaced by dummy HP. The dummy baselines were rerun on the same 100 seeds; they differ slightly from the earlier 200-seed figures.", "", "Total: 19,600 simulation windows, including two sets of dummy baselines and 11 isolated-mechanic conditions. An additional 188 seed-1 diagnostic replays exactly matched native Balance Lab DPS for every boss and isolated condition. Every native scenario passed. Godot produced its existing certificate-store and resource-exit warnings.", "", "## Rotations", ""]
for tree in TREES:
    r = next(r for r in rows if r["tree"] == tree and r["boss_index"] == -1)
    lines.append("- **" + NAMES[tree] + ":** " + " → ".join(r["rotation"]))
lines += ["", "## Overall comparison", "", "| Build | Dummy DPS | Mean boss DPS | DPS retained | Worst–best boss mean | Bosses led |", "|---|---:|---:|---:|---:|---:|"]
for r in summary:
    lines.append(f"| {NAMES[r['tree']]} | {r['dummy_dps']:.1f} | {r['mean_boss_dps']:.1f} | {r['retention']:.1%} | {r['min_boss_mean']:.1f}–{r['max_boss_mean']:.1f} | {r['leading_bosses']}/36 |")
lines += ["", "Means weight every generated boss equally. 'Bosses led' compares the four 100-seed mean DPS values, not individual seed winners. Two bosses per archetype is an exploratory sample, not an estimate of all possible bosses in that archetype.", "", "## Single-archetype bosses", "", "Each row averages its two generated bosses. Mixed bosses are listed individually below.", "", "| Archetype | Assassin | Bladedancer | Thief | Shadow |", "|---|---:|---:|---:|---:|"]
groups = []
for name in [b["archetype_a"] for b in bosses if b["archetype_b"] == ""][::2]:
    inds = {b["index"] for b in bosses if b["archetype_a"] == name and not b["archetype_b"]}
    vals = {t: statistics.mean(by_boss[i][t]["aggregate"]["dps"]["mean"] for i in inds) for t in TREES}
    groups.append(dict(archetype=name, dps=vals))
    lines.append("| " + name.title() + " | " + " | ".join(f"{vals[t]:.1f}" for t in TREES) + " |")
lines += ["", "## Isolated mechanics", "", "Each mechanic is tested alone, with the same rotations and combat seeds. Strength is the median positive value among the 36 bosses (integer fields rounded); HP is the sample median, 791. Percentages below are the change versus the zero-defense control at that same HP. These controls separate direct effects from combinations of defenses.", "", "| Mechanic | Strength | Assassin | Bladedancer | Thief | Shadow |", "|---|---:|---:|---:|---:|---:|"]
controls = []
cb = {r["tree"]: r["aggregate"]["dps"]["mean"] for r in c["rows"] if r["boss_index"] == -1}
for b in c["bosses"]:
    field = b["archetype_a"]
    value = b["draft"]["defense_overrides"][field]
    rr = {r["tree"]: r for r in c["rows"] if r["boss_index"] == b["index"]}
    delta = {t: rr[t]["aggregate"]["dps"]["mean"] / cb[t] - 1 for t in TREES}
    controls.append(dict(mechanic=field, strength=value, delta=delta))
    lines.append("| " + field + " | " + f"{value:g}" + " | " + " | ".join(f"{delta[t]:+.1%}" for t in TREES) + " |")
lines += ["", "## Interpretation", "", "- Assassin is countered by poison resistance, especially when combined with slow and cleanse: the two Relentless bosses average 96.7 DPS, and Warded averages 160.7. Nevertheless, it retains the most damage overall and leads 22 of 36 bosses. Its high dummy DPS is not fully offset by counters in this sample.", "- Shadow is relatively resilient to resistance and suppression, but vulnerable to cleanse, dodge, and slow. Cleanse every four qualifying attacks drops its isolated DPS by 61.8%. Runtime cleanse clears Poison, Decay, and the defense debuffs produced by consuming stacks; that disrupts the Distilled Corruption / Touch of Darkness / Death Strike chain. It leads no bosses, and its worst mixed boss yields only 7.9 DPS.", "- Bladedancer does well into poison defenses and cleanse. It struggles with dodge, slow, stun, and crit negation. Its cleanse-immune Shred preserves its armor-reduction setup, while missed attacks and timing disruption reduce its attack throughput.", "- Thief's sixfold Big Score crit scaling makes crit negation particularly costly: isolated 56% crit negation reduces DPS by 52.5%. Slow and stun also hurt. Its sample-leading mixed boss is Arcane + Riftbound (generation seed 351032), at 179.8 DPS.", "- Interrupt is rotation-dependent and considers actual direct-attack sequences, including triggered attacks. The isolated condition lowers Assassin by 15.0% and Bladedancer by 17.2%, while these particular Thief and Shadow rotations are unchanged. This is not a general immunity for those trees.", "- The isolated 637 ms stun reduces Bladedancer by 34.1%, Thief by 37.8%, and Shadow by 15.3%; Assassin is unchanged. The runtime checks whether the largest direct hit reaches 12% of boss HP. Poison damage does not trigger that condition. Seed-1 traces show no Assassin stun events, versus 19 Bladedancer, 11 Thief, and five Shadow events in the isolated condition. This advantage depends on boss HP.", "", "These are the previously optimized dummy rotations, held fixed. They are not optimized separately for each boss. A mechanic-aware rotation search could recover some losses, particularly against Interrupt or Cleanse. Losses from different mechanics are not additive.", "", "## Every generated boss", "", "| Seed | Archetypes | HP | Actual defenses | Assassin | Bladedancer | Thief | Shadow |", "|---:|---|---:|---|---:|---:|---:|---:|"]
for b in bosses:
    name = b["archetype_a"] + (" + " + b["archetype_b"] if b["archetype_b"] else "")
    defense = "; ".join(f"{k}={v:g}" for k,v in b["draft"]["defense_overrides"].items())
    vals = [by_boss[b["index"]][t]["aggregate"]["dps"]["mean"] for t in TREES]
    lines.append(f"| {b['input']['seed']} | {name} | {b['draft']['hp']} | {defense} | " + " | ".join(f"{v:.1f}" for v in vals) + " |")
lines += ["", "## Reproduction and raw results", "", "- Boss runner: `project/scripts/tools/run_full35_random_bosses.gd`", "- Isolated runner: `project/scripts/tools/run_full35_isolated_mechanics.gd` (uses `isolated_mechanics.json` saved with the boss report).", "- Diagnostic runner: `project/scripts/tools/run_full35_boss_diagnostics.gd`", "- Report generator: `tools/p6/analyze_full35_random_bosses.py`", "- `bosses.json`: full generator inputs, defenses, notices, and drafts.", "- `summary.json`: all aggregate metrics and rotations.", "- Per-scenario JSON: native Balance Lab result, build/gear/skill/monster snapshots, damage distributions, defense statistics, and first 24 combat-seed samples. Aggregate metrics include all 100 seeds.", "- `diagnostics_seed1.json`: illustrative stun/interrupt counts, stolen gold, and exact seed-1 replay parity; these diagnostic counts are not 100-seed averages.", ""]
(OUT / "comparison.md").write_text("\n".join(lines), encoding="utf-8")
(OUT / "analysis.json").write_text(json.dumps(dict(overall=summary, archetypes=groups, isolated_mechanics=controls), indent=2) + "\n", encoding="utf-8")
print("Wrote", OUT / "comparison.md")
