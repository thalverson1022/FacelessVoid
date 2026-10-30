"""Reconcile accepted T9 runs and static checks without rerunning combat."""
import hashlib
import json
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REPORTS = ROOT / 'project/reports'
OUT = REPORTS / 'p6_m5_t9_final'


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def main():
    OUT.mkdir(exist_ok=True)
    accepted = {}
    batches = ['p6_m5_t9_contracts', 'p6_m5_t9_scheduler',
               'p6_m5_t9_matrix_final', 'p6_m5_t9_interactions_final']
    isolation = []
    for batch in batches:
        for result in read(REPORTS / batch / 'summary.json'):
            accepted[result['test']] = dict(result, source_report=f'project/reports/{batch}/summary.json')
        protection = read(REPORTS / batch / 'isolation.json')
        assert protection['unchanged'], batch
        isolation.append({'batch': batch, **protection})
    assert len(accepted) == 22
    assert all(r['pass'] for r in accepted.values()), 'Accepted runtime suite failed'
    matrix = read(REPORTS / 'p6_m5_t9_matrix_final/matrix.json')
    focused = read(REPORTS / 'p6_m5_t9_interactions_final/focused.json')
    assert matrix['pass'] and focused['pass']
    assert len(matrix['scenarios']) == 576 and len(focused['scenarios']) == 4
    cases = Counter(row['case'] for row in matrix['scenarios'])
    assert len(cases) == 36 and set(cases.values()) == {16}
    pairs = set()
    for row in matrix['scenarios']:
        build = row['build']
        assert sum(build['talent_ranks'].values()) == 45
        assert len(build['rotation_skill_ids']) <= 10
        pairs.add((build['primary_tree_id'], build['secondary_tree_id']))
        assert [sample['seed'] for sample in row['samples']] == list(range(1, 6))
    assert len(pairs) == 12
    for row in focused['scenarios']:
        assert sum(row['build']['talent_ranks'].values()) == 45
        assert [sample['seed'] for sample in row['samples']] == list(range(1, 21))
    commands = [[sys.executable, 'tools/p6/' + name] for name in [
        'check_shadow_release.py', 'check_assassin_release.py', 'check_thief_release.py',
        'check_bladedancer_release.py', 'check_content_registry.py',
        'check_bladedancer_core.py', 'check_mixed_build.py']]
    commands += [[sys.executable, 'tools/p6/' + name, '--check'] for name in [
        'build_tree_display_catalog.py', 'build_m5_coverage_ledger.py']]
    static = []
    for command in commands:
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        name = Path(command[1]).stem
        (OUT / (name + '.txt')).write_text(result.stdout + result.stderr, encoding='utf-8')
        static.append({'check': name, 'command': command, 'pass': result.returncode == 0})
    (OUT / 'static.json').write_text(json.dumps(static, indent=2), encoding='utf-8')
    assert all(row['pass'] for row in static), 'Static check failed; see logs'
    sources = ['project/tests/p6_mixed_gear_integration_test.gd',
               'project/tests/p6_mixed_interactions_test.gd',
               'project/tests/p6_macro_scheduler_test.gd',
               'tools/p6/run_foundation_tests.py', 'tools/p6/build_m5_coverage_ledger.py',
               'tools/p6/check_m5_t9.py', 'project/data/p6/shadow_release_manifest.json']
    report = {'pass': True, 'date': '2026-10-06', 'authority': 'P6M5-D023',
              'runtime_suites': list(accepted.values()), 'static_checks': static,
              'ordered_pairings': 12, 'allocations': 40, 'matrix_scenarios': 576,
              'matrix_seeded_cases': 2880, 'matrix_checks': matrix['checks'],
              'targeted_seeded_cases': 80, 'targeted_checks': focused['checks'],
              'note': 'The initial scheduler result is superseded by its focused passing rerun. '
                      'Initial matrix runs are diagnostic history, not accepted evidence.',
              'source_sha256': {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
                                for name in sources}}
    (OUT / 'summary.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    (OUT / 'isolation.json').write_text(json.dumps(isolation, indent=2) + '\n', encoding='utf-8')
    print('PASS: 22 runtime suites, 9 static checks, 12 ordered pairings, 40 legal allocations; protected files unchanged')


if __name__ == '__main__':
    main()
