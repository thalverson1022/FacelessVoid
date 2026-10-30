"""Reconcile fresh M5 T10 acceptance and current static contracts."""
import hashlib
import json
import subprocess
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
REPORTS = ROOT / 'project/reports'
OUT = REPORTS / 'p6_m5_t10_final'
def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))
def main():
    OUT.mkdir(exist_ok=True)
    runs, isolation = [], []
    for batch in ['p6_m5_t10_contracts', 'p6_m5_t10_journeys', 'p6_m5_t10_rendered', 'p6_m5_t10_combined_headless', 'p6_m5_t10_combined_rendered']:
        results = read(REPORTS / batch / 'summary.json')
        assert all(r['pass'] for r in results), batch
        for r in results:
            if 'source_sha256' in r:
                assert hashlib.sha256((ROOT / 'project/tests' / (r['test']+'.gd')).read_bytes()).hexdigest() == r['source_sha256'], r['test']
            runs.append(dict(r, batch=batch))
        protection = read(REPORTS / batch / 'isolation.json')
        assert protection['unchanged'], batch
        isolation.append(dict(protection, batch=batch))
    assert len(runs) == 25
    for batch, name in [('p6_m5_t10_combined_headless','checks.json'),('p6_m5_t10_combined_rendered','visual-checks.json')]:
        cases = read(REPORTS / batch / 'p6_full_content_journey_test' / name)['cases']
        assert len(cases) == 12
        assert len({(c['build']['primary_tree_id'], c['build']['secondary_tree_id']) for c in cases}) == 12
        assert all(c['lab_status'] == 'pass' for c in cases)
    commands = [[sys.executable, 'tools/p6/' + name] for name in ['check_shadow_release.py','check_assassin_release.py','check_thief_release.py','check_bladedancer_release.py','check_content_registry.py','check_bladedancer_core.py','check_mixed_build.py']]
    commands += [[sys.executable,'tools/p6/'+name,'--check'] for name in ['build_tree_display_catalog.py','build_m5_coverage_ledger.py']]
    static = []
    for command in commands:
        result = subprocess.run(command,cwd=ROOT,capture_output=True,text=True)
        name = Path(command[1]).stem
        (OUT / (name+'.txt')).write_text(result.stdout+result.stderr,encoding='utf-8')
        static.append({'check':name,'pass':result.returncode==0,'command':command})
    (OUT/'static.json').write_text(json.dumps(static,indent=2),encoding='utf-8')
    assert all(s['pass'] for s in static)
    visual = read(OUT/'visual_review.json')
    assert visual['reviewed'] and visual['limitations']
    for item in visual['images']:
        assert hashlib.sha256((ROOT/item['path']).read_bytes()).hexdigest() == item['sha256'], item['path']
    sources = ['project/scripts/systems/training_room_state.gd','project/tests/p6_full_content_journey_test.gd','tools/p6/run_m5_t10_journeys.py','tools/p6/check_m5_t10.py','tools/p6/build_m5_coverage_ledger.py']
    summary = {'pass':True,'date':'2026-10-06','authority':'P6M5-D023','runtime_executions':len(runs),'distinct_runtime_suites':len({r['test'] for r in runs}),'runs':runs,'static_checks':static,'ordered_player_flow_pairings':12,'visual_review':'visual_review.json','source_sha256':{s:hashlib.sha256((ROOT/s).read_bytes()).hexdigest() for s in sources}}
    (OUT/'summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
    (OUT/'isolation.json').write_text(json.dumps(isolation,indent=2),encoding='utf-8')
    print('PASS: 25 runtime executions, 19 distinct suites, 9 static checks, 12 ordered player-flow pairings; protected files unchanged')
if __name__ == '__main__': main()
