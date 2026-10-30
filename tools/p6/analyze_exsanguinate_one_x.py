"""Compare the isolated 1x experiment with frozen D087 2x native Lab output.

No simulations are run. Fail closed on incomplete or mismatched studies.
Native Lab total_damage is ordinary damage; D088 CombatLog presentation combines
ordinary damage and health removal, which Lab calls total_health_loss.
"""
from pathlib import Path
import csv
import hashlib
import json
import math

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/m8_t9_presentation'
OLD = WORK / 'exsang_dance_fixed/project/reports/balance/exsanguinate_study'
NEW = WORK / 'exsang_one_x/project/reports/balance/exsanguinate_study'
OUT = ROOT / 'project/reports/balance/exsanguinate_one_x_review'
EXPECTED = {'profiles_200': (24, 200), 'shadow_profiles_200': (20, 200),
            'shadow_search_12': (72, 12), 'shadow_defenses_200': (8, 200),
            'winner_other_200': (4, 200), 'winner_shadow_solo_200': (1, 200),
            'winner_shadow_full_200': (1, 200)}
REMOVAL = {'total_health_removed', 'health_removed_per_second',
           'exsanguinate_original_health_removed', 'exsanguinate_repeated_health_removed'}
COMBINED = {'total_health_loss', 'health_loss_per_second'}


def equal(actual, expected, context):
    assert math.isclose(actual, expected, rel_tol=1e-12, abs_tol=1e-8), (context, actual, expected)


def read(path, count, seeds):
    data = json.loads(path.read_text(encoding='utf-8'))
    assert data['complete'] and data['invalid_scenarios'] == 0, path
    assert not data.get('validation_only', False), path
    assert len(data['rows']) == count and data['seed_count'] == seeds, path
    assert len({r['id'] for r in data['rows']}) == count, path
    for row in data['rows']:
        assert row['status'] == 'pass' and row['seed_count'] == seeds, (path, row['id'])
        assert row['duration_ms'] == 30000, (path, row['id'])
        assert row['monster_overrides']['hp'] == 1_000_000_000, row['id']
        assert row['aggregate']['win_rate'] == 0, row['id']
        assert row['aggregate']['total_health_loss']['max'] < 1_000_000_000, row['id']
        assert len(row['samples']) == min(seeds, 24), row['id']
        for metric in row['aggregate'].values():
            if isinstance(metric, dict):
                assert metric['count'] == seeds, (path, row['id'])
    return data


def compare_row(old, new, label, seeds):
    context = f"{label}/{old['id']}"
    for key in ['study_spec', 'resolved_fields', 'seed_start', 'duration_ms',
                'rotation', 'gear', 'monster_overrides']:
        assert old[key] == new[key], (context, key)
    a, b = old['aggregate'], new['aggregate']
    assert a.keys() == b.keys(), context
    for key in a:
        if key in REMOVAL:
            assert a[key].keys() == b[key].keys(), (context, key)
            for stat in a[key]:
                equal(b[key][stat], a[key][stat] if stat == 'count' else a[key][stat] / 2,
                      (context, key, stat))
        elif key not in COMBINED:
            assert a[key] == b[key], (context, key)
    for metrics in [a, b]:
        equal(metrics['total_health_loss']['mean'],
              metrics['total_damage']['mean'] + metrics['total_health_removed']['mean'], context)
        equal(metrics['health_loss_per_second']['mean'], metrics['total_health_loss']['mean'] / 30, context)
        equal(metrics['health_removed_per_second']['mean'], metrics['total_health_removed']['mean'] / 30, context)
    assert len(old['samples']) == len(new['samples']), context
    for x, y in zip(old['samples'], new['samples']):
        assert x.keys() == y.keys(), context
        for key in x:
            if key in REMOVAL:
                equal(y[key], x[key] / 2, (context, x['seed'], key))
            elif key not in COMBINED:
                assert x[key] == y[key], (context, x['seed'], key)
        for sample in [x, y]:
            assert not sample['win'], context
            equal(sample['total_health_loss'], sample['total_damage'] + sample['total_health_removed'], context)
            equal(sample['health_loss_per_second'], sample['total_health_loss'] / 30, context)
        equal(y['total_health_loss'], x['total_damage'] + x['total_health_removed'] / 2, context)
    result = {'dataset': label, 'id': old['id'], 'label': old['label'], 'seeds': seeds,
              'shred_value': old['resolved_fields']['shred_value'],
              'bonus_shred_stacks': old['resolved_fields']['bonus_shred_stacks']}
    for name, metrics in [('2x', a), ('1x', b)]:
        for stat in ['mean', 'min', 'p05', 'p50', 'p95', 'max']:
            result[f'removal_{name}_{stat}'] = metrics['total_health_removed'][stat]
        for key in ['total_damage', 'total_health_loss', 'health_loss_per_second',
                    'dps',
                    'exsanguinate_original_casts', 'exsanguinate_repeat_casts',
                    'exsanguinate_stacks_consumed', 'exsanguinate_original_health_removed',
                    'exsanguinate_repeated_health_removed']:
            result[f'{key}_{name}_mean'] = metrics[key]['mean']
    denominator = a['total_health_loss']['mean']
    result['combined_reduction_percent'] = 100 * (1 - b['total_health_loss']['mean'] / denominator) if denominator else 0.0
    result['removal_reduction_percent'] = 50.0 if a['total_health_removed']['mean'] else 0.0
    return result


def main():
    rows, datasets = [], {}
    for label, (count, seeds) in EXPECTED.items():
        paths = [base / label / 'summary.json' for base in [OLD, NEW]]
        old, new = [read(p, count, seeds) for p in paths]
        for key in ['duration_ms', 'phase', 'seed_count']:
            assert old[key] == new[key], (label, key)
        old_rows, new_rows = [{r['id']: r for r in d['rows']} for d in [old, new]]
        assert old_rows.keys() == new_rows.keys(), label
        rows += [compare_row(row, new_rows[key], label, seeds) for key, row in old_rows.items()]
        datasets[label] = {'scenarios': count, 'seeds': seeds, 'invalid': 0,
                           'sources': {name: {'path': str(path), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
                                       for name, path in zip(['2x', '1x'], paths)}}
    assert len(rows) == 130 and sum(r['seeds'] for r in rows) == 12464
    OUT.mkdir(parents=True, exist_ok=True)
    with (OUT / 'comparison.csv').open('w', newline='', encoding='utf-8') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    report = {'scenario_evaluations': len(rows), 'windows_per_coefficient': 12464,
              'final_200_seed_evaluations': 58, 'screen_12_seed_evaluations': 72,
              'validation': {'complete': True, 'all_pass': True, 'invalid': 0,
                             'study_spec_equal': True, 'resolved_fields_equal': True,
                             'all_removal_aggregate_statistics_halved': True,
                             'all_unaffected_aggregate_metrics_equal': True,
                             'paired_samples_checked': sum(min(r['seeds'], 24) for r in rows),
                             'combined_means_and_sample_totals_and_rates_reconstructed': True,
                             'one_billion_hp_targets_never_killed': True},
              'metric_definitions': {'total_damage': 'Native Lab ordinary damage only; unchanged.',
                                     'total_health_removed': 'Separate native Lab Exsanguinate removal; halved.',
                                     'total_health_loss': 'Ordinary damage plus removal; D088 CombatLog presents this combined amount as damage.',
                                     'quantile_note': 'Combined quantiles are native observations, not sums of marginal quantiles.'},
              'datasets': datasets, 'rows': rows}
    (OUT / 'analysis.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    chosen = [('profiles_200', 'low_0pt_stab_exsang', 'Nightkiss, no talents'),
              ('profiles_200', 'user_35bd_10thief', 'User rotation: 35 BD / 10 Thief'),
              ('shadow_profiles_200', 'sh35_bd10_decay_solo', '35 Shadow / 10 BD, Nightkiss'),
              ('shadow_profiles_200', 'bd29_sh16_solo', '29 BD / 16 Shadow, Nightkiss'),
              ('profiles_200', 'optimized_full_coil', '35 BD / 10 Thief, five Legendaries'),
              ('shadow_profiles_200', 'bd29_sh16_full_coil', '29 BD / 16 Shadow, five Legendaries'),
              ('profiles_200', 'five_legendaries_signet', 'User rotation, five Legendaries + Signet'),
              ('profiles_200', 'control_same_weapon_no_exsang', 'Same Nightkiss gear, no Exsanguinate'),
              ('profiles_200', 'generated_endpoint_short_rotation', 'Max-roll endpoint: 35 BD / 10 Thief')]
    fig, axes = plt.subplots(1, 2, figsize=(17, 7), sharey=True, layout='constrained')
    for ax, template, title in zip(axes, ['removal_{}_mean', 'total_health_loss_{}_mean'],
                                  ['Exsanguinate removal only', 'Combined health loss: ordinary damage + removal']):
        for i, (dataset, key, label) in enumerate(chosen):
            row = next(r for r in rows if r['dataset'] == dataset and r['id'] == key)
            for prefix, offset, color in [('2x', -.16, '#9b5c32'), ('1x', .16, '#2d7796')]:
                mean = row[template.format(prefix)]
                if mean > 0:
                    ax.scatter(mean, i + offset, color=color, label=f'{prefix} Shred' if i == 0 else None)
                    ax.annotate(f'{mean:,.0f}', (mean, i + offset), xytext=(6, 0), textcoords='offset points', va='center', fontsize=8, color=color)
                elif prefix == '1x':
                    ax.text(.01, i, '0 (both coefficients)', transform=ax.get_yaxis_transform(), va='center', fontsize=8)
        ax.set_xscale('log')
        ax.set_xlim(300, 4e8)
        ax.xaxis.set_major_formatter(FuncFormatter(lambda x, _: f'{x/1e6:g}M' if x >= 1e6 else f'{x/1000:g}k'))
        ax.set_xlabel('Mean in 30 seconds (log scale)')
        ax.set_title(title, fontsize=11)
        ax.grid(axis='x', alpha=.2)
    axes[0].set_yticks(range(len(chosen)), [r[2] for r in chosen])
    axes[0].invert_yaxis()
    axes[1].legend(loc='upper right')
    fig.suptitle('1x Shred experiment versus frozen 2x baseline — same 200 seeds per profile')
    fig.savefig(OUT / 'overview.png', dpi=160)
    fig.savefig(OUT / 'overview.svg')
    plt.close(fig)
    print(json.dumps({'scenario_evaluations': len(rows), 'windows_per_coefficient': 12464,
                      'paired_samples': report['validation']['paired_samples_checked'],
                      'output': str(OUT)}, indent=2))


if __name__ == '__main__':
    main()
