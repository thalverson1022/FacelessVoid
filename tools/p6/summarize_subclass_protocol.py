from pathlib import Path
import argparse, hashlib, json, re

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'project/reports/balance/subclass_protocol_d023'
FIXTURE = ROOT / 'project/data/balance_lab/subclass_protocol.json'
TREES = ['bladedancer', 'thief', 'assassin', 'shadow']
LABELS = {'bladedancer': 'Bladedancer', 'thief': 'Thief', 'assassin': 'Assassin', 'shadow': 'Shadow'}

def resource_labels(folder):
    labels = {}
    paths = list((ROOT / 'project/data' / folder).rglob('*.tres')) + list((ROOT / 'project/data/p6').rglob('*.tres'))
    for path in paths:
        body = path.read_text(encoding='utf-8').split('[resource]')[-1]
        ident = re.search(r'^id = "([^"]+)"', body, re.M)
        label = re.search(r'^display_name = "([^"]+)"', body, re.M)
        if ident and label:
            labels[ident.group(1)] = label.group(1)
    return labels

SKILLS = resource_labels('skills')
TALENTS = resource_labels('talents')

def macro(ids):
    chunks = []
    for ident in ids:
        label = SKILLS.get('skill.' + ident, ident.replace('_', ' ').title())
        if chunks and chunks[-1][0] == label:
            chunks[-1][1] += 1
        else:
            chunks.append([label, 1])
    return ' → '.join((f'{n}× ' if n > 1 else '') + name for name, n in chunks)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--select-bd21', action='store_true', help='Retain the stronger BD21 allocation in the canonical fixture.')
    args = parser.parse_args()
    original = json.loads((REPORT / 'protocol_used.json').read_text(encoding='utf-8'))
    rows = []
    for tree in TREES:
        summary = json.loads((REPORT / tree / 'summary.json').read_text(encoding='utf-8'))
        assert summary['passed'] and summary['complete'], f'{tree} unfinished'
        rows.extend(summary['rows'])
    expected = {(case['id'], ms) for case in original['cases'] for ms in original['durations_ms']}
    actual = {(row['id'], row['duration_ms']) for row in rows}
    canonical = json.loads(FIXTURE.read_text(encoding='utf-8'))
    canonical_expected = {(case['id'], ms) for case in canonical['cases'] for ms in canonical['durations_ms']}
    assert actual == expected or actual == canonical_expected
    assert len(rows) == len(actual)
    # A canonical 16-build rerun uses the archived omitted BD21 candidate for comparison.
    for ident, ms in sorted(expected - actual):
        row = json.loads((REPORT / 'bladedancer' / f'{ident}_{ms//1000}s.json').read_text(encoding='utf-8'))
        rows.append(row)
    manifest_hash = hashlib.sha256((ROOT / 'project/data/p6/shadow_release_manifest.json').read_bytes()).hexdigest()
    for row in rows:
        assert row['release_manifest_sha256'] == manifest_hash
        assert row['source_balance_authority'] == original['source_balance_authority']
        assert row['practice_lab_native_seed1_parity']
        assert row['winner']['dps']['count'] == row['validation']['dps']['count'] == 200
        assert row['winner']['seed_start'] == 1 and row['validation']['seed_start'] == 201
        assert row['winner']['dps']['mean'] >= row['baseline']['dps']['mean']
        assert row['winner']['rotation'] == row['validation']['rotation']
        assert sum(row['talent_ranks'].values()) == row['points']
    lookup = {(row['id'], row['duration_ms']): row for row in rows}
    alternatives = ['bladedancer_21_bd1', 'bladedancer_21_bd2']
    winners = [max(alternatives, key=lambda ident: lookup[ident, ms]['winner']['dps']['mean']) for ms in original['durations_ms']]
    assert len(set(winners)) == 1, 'BD21 windows disagree; review selection explicitly'
    kept = winners[0]
    removed = next(ident for ident in alternatives if ident != kept)
    retained = [row for row in rows if row['id'] != removed]
    retained.sort(key=lambda row: (row['points'], TREES.index(row['tree']), row['duration_ms']))
    result = {'complete': True, 'source_balance_authority': original['source_balance_authority'], 'release_manifest_sha256': manifest_hash,
              'conditions': {key: original[key] for key in ['gear', 'starting_gold', 'monster', 'monster_hp', 'durations_ms', 'seed_count', 'baseline_seed_start', 'validation_seed_start', 'search']},
              'bd21_retained': kept, 'bd21_comparison': [row for row in rows if row['id'] in alternatives], 'rows': retained}
    (REPORT / 'results.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    lines = ['# Subclass balance results — P6M5-D023', '', 'Crude Dagger only, zero-defense training dummy, zero starting stash. Each fixed allocation is optimized independently for 30 and 120 seconds. Means use seeds 1–200; independent validation uses seeds 201–400. All winners match standard Balance Lab and Practice at seed one.', '', 'These are the strongest macros found by the recorded heuristic search (maximum ten slots), not a proof of global optimality. Repeat each macro continuously. Cooldown handling uses the live game rules. Heavy Strike is named Heavy Slash in the game.', '', '## Optimized mean DPS', '', '| Points | Subclass | 30s DPS | 120s DPS |', '|---|---|---:|---:|']
    for points in [1, 10, 21, 35]:
        for tree in TREES:
            pair = [row for row in retained if row['points'] == points and row['tree'] == tree]
            short, long = sorted(pair, key=lambda row: row['duration_ms'])
            lines.append(f"| {points} | {LABELS[tree]} | {short['winner']['dps']['mean']:.2f} | {long['winner']['dps']['mean']:.2f} |")
    lines += ['', '## 21-point Bladedancer selection', '', '| Allocation | 30s optimized | 120s optimized |', '|---|---:|---:|']
    for ident in alternatives:
        lines.append(f"| {ident.rsplit('_', 1)[-1].upper()} | {lookup[ident, 30000]['winner']['dps']['mean']:.2f} | {lookup[ident, 120000]['winner']['dps']['mean']:.2f} |")
    lines += ['', f"Retain **{kept.rsplit('_', 1)[-1].upper()}** in the protocol; the lower build remains archived in the original fixture and comparison reports.", '', '## Fixed builds and optimized rotations']
    for points in [1, 10, 21, 35]:
        for tree in TREES:
            short, long = sorted([row for row in retained if row['points'] == points and row['tree'] == tree], key=lambda row: row['duration_ms'])
            lines += ['', f'### {points} points — {LABELS[tree]}', '', ', '.join(f"{TALENTS.get(ident, ident)} {int(rank)}" for ident, rank in short['talent_ranks'].items() if rank > 0) + '.', '', '| Window | Optimized macro | Mean DPS | Independent validation | Baseline DPS |', '|---|---|---:|---:|---:|']
            for row in [short, long]:
                lines.append(f"| {row['duration_ms']//1000}s | {macro(row['winner']['rotation'])} | {row['winner']['dps']['mean']:.2f} | {row['validation']['dps']['mean']:.2f} | {row['baseline']['dps']['mean']:.2f} |")
            lines += ['', '| Window | Direct DPS | Poison DPS | Fight DPS p05–p95 | Candidates searched |', '|---|---:|---:|---:|---:|']
            for row in [short, long]:
                score = row['winner']
                lines.append(f"| {row['duration_ms']//1000}s | {score['direct_dps']['mean']:.2f} | {score['poison_dps']['mean']:.2f} | {score['dps']['p05']:.2f}–{score['dps']['p95']:.2f} | {row['candidate_count']} |")
    lines += ['', '## Reproduction and evidence', '', '- [Protocol](../../../../docs/P6_Subclass_Balance_Protocol.md)', '- [Combined machine-readable results](results.json)', '- [Original 17-build search fixture](protocol_used.json)', '', f'Release manifest SHA-256: `{manifest_hash}`.', '', 'Each subclass folder contains the complete worker summary and individual scenario reports with all finalists, exact allocations, seed ranges and executable Balance Lab specs. No gameplay balance values were changed by this run.', '']
    (REPORT / 'results.md').write_text('\n'.join(lines), encoding='utf-8')
    if args.select_bd21:
        fixture = json.loads(FIXTURE.read_text(encoding='utf-8'))
        fixture['cases'] = [case for case in fixture['cases'] if case['id'] != removed]
        fixture['comparison_candidates'] = [case for case in original['cases'] if case['id'] == removed]
        fixture['bd21_retained'] = kept
        for case in fixture['cases']:
            case['reference_optimized_rotations'] = {str(ms // 1000): lookup[case['id'], ms]['winner']['rotation'] for ms in original['durations_ms']}
        fixture['notes'] = [note for note in fixture['notes'] if not note.startswith('Compare both 21-point')]
        fixture['notes'].append(f'Retain {kept}; both original BD21 candidates and their results are archived in subclass_protocol_d023.')
        FIXTURE.write_text(json.dumps(fixture, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'passed': True, 'rows': len(retained), 'builds': len(retained)//2, 'bd21_retained': kept, 'report': str(REPORT / 'results.md')}))

if __name__ == '__main__':
    main()
