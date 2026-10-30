"""Validate and summarize the M6-T4 saved diagnostic matrix. Run from repo root."""
import csv, hashlib, json
from collections import defaultdict
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'project/reports/p6_m6_t4'
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
config = read(ROOT / 'project/data/balance_lab/m6_t4_protocol.json')
rows, provenance, totals = [], {}, defaultdict(int)
pairs, families, templates = set(), set(), set()
for tree in config['trees']:
    base = OUT / tree
    f, e, m = [read(base / (n + '.json')) for n in ['fixtures', 'encounters', 'matrix']]
    assert f['complete'] and m['complete'] and len(f['snapshots']) == 144
    assert len(m['results']) == 182
    assert len({r['id'] for r in m['results']}) == 182
    snapshots = {s['id']: s for s in f['snapshots']}
    enemies = {x['id']: x for x in e['encounters']}
    for s in snapshots.values():
        expected = {'T0':0, 'T1':1, 'T2':1, 'T3':5}.get(s['checkpoint'], min(45, 10 + 5 * (int(s['checkpoint'].split('_')[0][1:])-1)))
        assert s['budget'] == expected and sum(s['ranks'].values()) == expected
        assert s['gold'] >= 0 and s['conditional_victories']
    for x in f['ledger']:
        if x['action'] == 'buy': assert x['gold_after'] == x['gold_before'] - x['price'] >= 0
    samples = defaultdict(list)
    for x in m['samples']: samples[x['case'], x['kind']].append(x)
    assert len(samples) == 2 * len(m['results'])
    for r in m['results']:
        assert r['snapshot'] in snapshots and r['encounter'] in enemies
        assert r['replay_pass'] and r['practice_parity'] and sum(r['ranks'].values()) == r['budget']
        enemy = enemies[r['encounter']]
        best = max(r['search'], key=lambda candidate: candidate['mean_damage'])
        assert r['selected'] == best['macro']
        if 'template' in enemy: templates.add(enemy['template'])
        if r['checkpoint'] == 'C10':
            pairs.add((tree, r['secondary'])); families.add(r['family'])
        for measure in r['measurements']:
            ss = samples[r['id'], measure['kind']]
            assert len(ss) == 20 and {x['root_seed'] for x in ss} == set(config['validation_roots'])
            assert all(x['first_seed'] != x['retry_seed'] and x['first_seed'] not in config['search_seeds'] and x['retry_seed'] not in config['search_seeds'] for x in ss)
            assert sum(x['first_win'] for x in ss) == measure['wins']
            assert sum(x['within_two'] for x in ss) == measure['within_two']
            assert all(x['within_two'] >= x['first_win'] for x in ss)
            assert all(x['first_win'] == (x['first_damage'] >= r['hp']) for x in ss)
            rows.append({**{k:r[k] for k in ['id','checkpoint','primary','secondary','policy','family','role','mandatory','duration_ms','hp']}, 'template':enemy.get('template','authored'), 'extra_template':enemy.get('template_extra',False), 'kind':measure['kind'], 'wins':measure['wins'], 'within_two':measure['within_two'], 'count':20, 'mean_margin':measure['mean_margin'], 'macro':','.join(measure['macro'])})
    for checkpoint in ['C9_pre_shop','C9_post_shop','C10_pre_shop','C10_post_shop']:
        assert len([r for r in m['results'] if r['checkpoint'] == checkpoint]) == 6
    totals['snapshots'] += len(snapshots); totals['cases'] += len(m['results']); totals['samples'] += len(m['samples']); totals['engine_checks'] += f['checks'] + m['checks']
    for name in ['fixtures','encounters','matrix']: provenance[str((base/(name+'.json')).relative_to(ROOT))] = sha(base/(name+'.json'))
for main, secondary in pairs:
    for family in [35,33,24]:
        assert {r['role'] for r in rows if r['primary']==main and r['secondary']==secondary and r['checkpoint']=='C10' and r['family']==family and r['policy']=='typical' and not r['extra_template']} >= {'FIGHT','BOSS'}
assert len(pairs) == 12 and families == {35,33,24} and len(templates) == 6
protected = read(OUT / 'protected_before.json')
changed = [p for p,h in protected.items() if not Path(p).exists() or sha(Path(p)) != h]
assert not changed, f'Protected files changed: {changed}'
for name in ['project/scripts/tools/run_m6_t4_matrix.gd','project/data/balance_lab/m6_t4_protocol.json','project/data/balance_lab/subclass_protocol.json','tools/p6/check_m6_t4.py']:
    provenance[name] = sha(ROOT/name)
with (OUT/'summary.csv').open('w',newline='',encoding='utf-8') as stream:
    writer = csv.DictWriter(stream, fieldnames=list(rows[0])); writer.writeheader(); writer.writerows(rows)
report = ['# M6-T4 diagnostic results', '', f"Validated {totals['snapshots']} snapshots, {totals['cases']} cases, {totals['samples']} first-attempt samples (plus failed-attempt retries); {totals['engine_checks']} engine assertions. All 12 ordered tree pairs, three allocation families and six route templates covered.", '', 'These are conditional acquisition fixtures from one seed, not full-run completion rates or equipment percentiles. Each table cell is wins out of 20 held-out combat seeds. Macro search is a bounded candidate comparison, not a proof of optimal play. No balance acceptance is implied.', '', '## C10 typical-policy, 35/10 representative pairs', '', '| Main / secondary | Role | Reasonable first / within two | Searched first / within two |', '| --- | --- | --- | --- |']
for tree in config['trees']:
    secondary = config['trees'][(config['trees'].index(tree)+1)%4]
    for role in ['FIGHT','BOSS']:
        match = [r for r in rows if r['primary']==tree and r['secondary']==secondary and r['checkpoint']=='C10' and r['policy']=='typical' and r['family']==35 and r['role']==role and not r['extra_template']]
        a,b = sorted(match, key=lambda r:r['kind'])
        report.append(f"| {tree} / {secondary} | {role} | {a['wins']}/20; {a['within_two']}/20 | {b['wins']}/20; {b['within_two']}/20 |")
report += ['', '## Typical-policy cases to investigate before C10', '', 'Base-route 35/10 cases where the reasonable macro still fails at least one validation root after the macro-only retry. This flags investigation; 20 seeds do not certify success probabilities.', '', '| Main | Checkpoint | Role | Within two | Mean damage margin |', '| --- | --- | --- | --- | --- |']
for r in rows:
    if r['kind']=='reasonable' and r['policy']=='typical' and r['family']==35 and not r['extra_template'] and r['checkpoint'] in ['T0','T1','T2','T3','C1','C4','C6','C8'] and r['within_two']<20:
        report.append(f"| {r['primary']} | {r['checkpoint']} | {r['role']} | {r['within_two']}/20 | {r['mean_margin']:+.1%} |")
report += ['', f'Protected-file verification: {len(protected)} pre-existing runtime/content and discovered save/Enigma files unchanged. See summary.csv for every measurement and per-tree matrix.json for raw samples, search candidates and replay/Practice parity.', '']
(OUT/'results.md').write_text('\n'.join(report), encoding='utf-8')
(OUT/'verification.json').write_text(json.dumps({'passed':True, **totals, 'ordered_pairs':len(pairs),'templates':sorted(templates),'protected_files':len(protected),'sha256':provenance},indent=2),encoding='utf-8')
print(json.dumps(dict(totals))); print('T4 verification PASS')
