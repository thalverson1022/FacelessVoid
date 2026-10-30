"""Snapshot/reconcile runtime and protected profiles for the T10 review interval."""
import hashlib
import json
import sys
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'work/m9_t10'
OUT.mkdir(parents=True, exist_ok=True)
BASE = OUT / 'review_before.json'

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def snapshot():
    roots = json.loads((ROOT / 'work/m9_t9/before.json').read_text())['profile_roots']
    runtime = {p.relative_to(ROOT).as_posix(): sha(p)
               for folder in ['scripts', 'scenes', 'data', 'assets']
               for p in (ROOT / 'project' / folder).rglob('*')
               if p.is_file() and p.suffix not in ['.uid', '.import']}
    runtime['project/project.godot'] = sha(ROOT / 'project/project.godot')
    profiles = {str(p): sha(p) for folder in roots for p in Path(folder).rglob('*') if p.is_file()}
    return {'runtime': runtime, 'profiles': profiles, 'profile_roots': roots}

now = snapshot()
if '--before' in sys.argv:
    if BASE.exists():
        raise SystemExit('Existing baseline preserved')
    BASE.write_text(json.dumps(now, indent=2) + '\n')
    print(json.dumps({'runtime_files':len(now['runtime']), 'protected_files':len(now['profiles'])}))
else:
    before = json.loads(BASE.read_text())
    changes = {group: sorted(k for k in set(now[group]) | set(before[group])
                             if now[group].get(k) != before[group].get(k))
               for group in ['runtime', 'profiles']}
    result = {'unchanged': not any(changes.values()), 'changes': changes,
              'before':before, 'after':now,
              'scope':'Parent review interval begins after formal probes started; probe isolation separately recorded in runner manifests.'}
    (OUT / 'review_integrity.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'unchanged':result['unchanged'], 'changes':changes}))
    report_root = ROOT / 'project/reports/m9_t10'
    index = json.loads((report_root / 'evidence_index.json').read_text())
    for key, name in [('harness_sha256','project/tests/m9_t10_progression_probe.gd'),
                      ('runner_sha256','tools/p6/m9_t10_progression_probe.py'),
                      ('analyzer_sha256','tools/p6/m9_t10_analyze_progression.py')]:
        assert index[key] == sha(ROOT / name), name
    records = []
    for folder, count in [('cadence_verified',8),('cadence_mixed_sensitivity',4)]:
        summary = json.loads((report_root / folder / 'summary.json').read_text())
        assert len(summary) == count
        assert all(r['exit_code'] == 0 and not r['log_has_script_error'] for r in summary)
        for p in (report_root / folder).glob('*.json'):
            d = json.loads(p.read_text())
            if not isinstance(d,dict) or not d.get('fights'):
                continue
            assert not d['validity_failures']
            assert all(f['valid'] and f['seed_replay_equal'] and f['spent_points'] <= f['earned_points'] for f in d['fights'])
            assert not any(e['action']=='shop_offer' and e['stage']=='T3' for e in d['events'])
            assert sum(e['delta'] for e in d['events']) == d['gold']
            assert d['stop_reason']=='horizon' or not d['can_retry_at_stop']
            records.append(d)
    assert len(records) == 12
    report = ROOT / 'docs/P6M9_T10_Focused_Progression_Review.md'
    for target in re.findall(r'\]\(([^)]+)\)',report.read_text(encoding='utf-8')):
        if not target.startswith(('http:', 'https:', '#')):
            assert (report.parent / target.split('#')[0]).exists(), target
    final = {'pass':result['unchanged'], 'paths':len(records),
             'actual_combat_attempts':sum(len(d['fights']) for d in records),
             'victories':sum(f['win'] for d in records for f in d['fights']),
             'current_max_root_budget':max(f['max_root_budget_consumed'] for d in records if d['arm']=='seven_current' for f in d['fights']),
             'runtime_and_protected_unchanged':result['unchanged'],
             'source_hashes_match':True,'report_local_links_exist':True}
    (report_root / 'verification.json').write_text(json.dumps(final,indent=2)+'\n')
    print(json.dumps(final))
