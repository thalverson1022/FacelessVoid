"""D087 corrected-runtime comparison. Read native Lab aggregates, never player saves."""
from pathlib import Path
import csv
import hashlib
import json
import re
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/m8_t9_presentation'
BASE = WORK / 'exsang_dance_fixed/project/reports/balance/exsanguinate_study'
OUT = ROOT / 'project/reports/balance/exsanguinate_corrected_review'


def read(path):
    data = json.loads(path.read_text(encoding='utf-8'))
    assert data['complete'] and data['invalid_scenarios'] == 0, path
    assert all(row['status'] == 'pass' for row in data['rows']), path
    for row in data['rows']:
        assert row['aggregate']['total_health_removed']['count'] == data['seed_count'], row['id']
    return data


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    labels = ['profiles_200', 'shadow_profiles_200', 'shadow_search_12', 'shadow_defenses_200']
    labels += sorted(p.parent.name for p in BASE.glob('winner_*/summary.json'))
    datasets = {label: read(BASE / label / 'summary.json') for label in labels}
    old = read(WORK / 'exsang_current/project/reports/balance/exsanguinate_study/profiles_200/summary.json')
    before = {r['id']: r for r in old['rows']}
    rows = []
    for label, data in datasets.items():
        for row in data['rows']:
            a = row['aggregate']
            removal = a['total_health_removed']
            fields = row['resolved_fields']
            rows.append({'dataset': label, 'id': row['id'], 'seeds': data['seed_count'],
                         **{key: removal[key] for key in ['mean', 'min', 'p05', 'p50', 'p95', 'max']},
                         'ordinary_damage': a['total_damage']['mean'],
                         'combined_loss': a['total_health_loss']['mean'],
                         'original_casts': a['exsanguinate_original_casts']['mean'],
                         'repeat_casts': a['exsanguinate_repeat_casts']['mean'],
                         'consumed_stacks': a['exsanguinate_stacks_consumed']['mean'],
                         'root_removal': a['exsanguinate_original_health_removed']['mean'],
                         'repeat_removal': a['exsanguinate_repeated_health_removed']['mean'],
                         'shred_value': fields['shred_value'],
                         'bonus_shred_stacks': fields['bonus_shred_stacks'],
                         'before_fix_mean': before[row['id']]['aggregate']['total_health_removed']['mean'] if label == 'profiles_200' else ''})
    with (OUT / 'profiles.csv').open('w', newline='', encoding='utf-8') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    (OUT / 'analysis.json').write_text(json.dumps({'rows': rows,
        'windows': sum(d['seed_count'] * len(d['rows']) for d in datasets.values()),
        'scenario_evaluations': sum(len(d['rows']) for d in datasets.values())}, indent=2), encoding='utf-8')

    chosen = [('profiles_200', 'low_0pt_stab_exsang', 'Nightkiss, no talents'),
              ('profiles_200', 'user_35bd_10thief', 'Your rotation: 35 BD / 10 Thief'),
              ('shadow_profiles_200', 'sh35_bd10_decay_solo', '35 Shadow / 10 BD, Nightkiss'),
              ('shadow_profiles_200', 'bd29_sh16_solo', '29 BD / 16 Shadow, Nightkiss'),
              ('profiles_200', 'optimized_full_coil', '35 BD / 10 Thief, five Legendaries'),
              ('shadow_profiles_200', 'bd29_sh16_full_coil', '29 BD / 16 Shadow, five Legendaries'),
              ('profiles_200', 'generated_endpoint_short_rotation', 'Max-roll gear endpoint (35 BD / 10 Thief)')]
    fig, ax = plt.subplots(figsize=(11, 5.4), layout='constrained')
    for y, (dataset, key, label) in enumerate(chosen):
        row = next(r for r in rows if r['dataset'] == dataset and r['id'] == key)
        ax.errorbar(row['mean'], y, xerr=[[row['mean']-row['p05']], [row['p95']-row['mean']]],
                    fmt='o', capsize=4, color='#2d7796')
        ax.annotate(f"{row['mean']:,.0f}", (row['mean'], y), xytext=(-9, -17),
                    textcoords='offset points', ha='right', fontsize=9)
    ax.set_yticks(range(len(chosen)), [x[2] for x in chosen])
    ax.invert_yaxis()
    ax.set_ylim(len(chosen)-.2, -.4)
    ax.set_xscale('log')
    ax.set_xlim(700, 2e8)
    ax.set_xlabel('Exsanguinate health removed in 30 seconds (log scale); mean and 5th–95th percentile')
    ax.set_title('After the Dance fix: 200 seeds per profile')
    ax.grid(axis='x', alpha=.2)
    fig.savefig(OUT / 'overview.png', dpi=160)
    fig.savefig(OUT / 'overview.svg')
    plt.close(fig)

    baseline = json.loads((WORK / 'd087_start_hashes.json').read_text(encoding='utf-8'))
    changed = [key for key, digest in baseline.items()
               if hashlib.sha256((ROOT / key).read_bytes()).hexdigest() != digest]
    assert set(changed) == {'project/scripts/systems/bladedancer_effect_lifecycle.gd',
                            'project/scripts/systems/combat_resolver.gd',
                            'project/tests/p6_status_completion_test.gd'}, changed
    runtime = list((ROOT / 'project/scripts/systems').glob('*.gd')) + [ROOT / 'project/scripts/tools/balance_lab.gd']
    for path in runtime:
        relative = path.relative_to(ROOT / 'project')
        actual = (WORK / 'exsang_dance_fixed/project' / relative).read_text(encoding='utf-8')
        if path.name in ['save_system.gd', 'practice_save_system.gd']:
            actual = actual.replace('res://prototype_saves/', 'user://')
        assert actual == path.read_text(encoding='utf-8'), relative
    manifest = {'production_existing_files_changed': changed,
                'runtime_source_parity': True,
                'runtime_sha256': {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in runtime},
                'datasets': {label: {'path': str(BASE / label / 'summary.json'),
                    'sha256': hashlib.sha256((BASE / label / 'summary.json').read_bytes()).hexdigest(),
                    'scenarios': len(data['rows']), 'seeds': data['seed_count'], 'invalid': 0}
                    for label, data in datasets.items()}}
    for label in labels:
        console = (WORK / 'exsang_dance_fixed/evidence' / label / 'console.txt').read_text(encoding='utf-8')
        errors = [line for line in console.splitlines() if re.search(r'SCRIPT ERROR|Parse Error|Compile Error|^ERROR:', line)
                  and 'Failed to read the root certificate store.' not in line
                  and '9 resources still in use at exit' not in line]
        assert not errors, (label, errors)
        assert json.loads((WORK / 'exsang_dance_fixed/evidence' / label / 'result.json').read_text(encoding='utf-8'))['passed'], label
    manifest['selected_console_audit'] = 'No unexpected script/engine errors; inherited certificate and 9-resource exit diagnostics retained.'
    (WORK / 'd087_verification.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    print(json.dumps({'rows': len(rows), 'windows': sum(d['seed_count']*len(d['rows']) for d in datasets.values()),
                      'changed': changed}))


if __name__ == '__main__':
    main()
