"""Validate and compare four complete native Exsanguinate studies; never simulate.

Repeat eligibility changes RNG consumption. Comparisons across eligibility modes
use actual native results, not paired RNG claims or subtraction of old repeats.
"""
from pathlib import Path
import csv
import hashlib
import importlib.util
import json

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter

_spec = importlib.util.spec_from_file_location(
    'exsanguinate_one_x_validation', Path(__file__).with_name('analyze_exsanguinate_one_x.py'))
_baseline = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_baseline)
EXPECTED = _baseline.EXPECTED
ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'work/m8_t9_presentation'
OUT = ROOT / 'project/reports/balance/exsanguinate_no_repeat_review'
GROUPS = {'repeat_2x': 'exsang_dance_fixed', 'repeat_1x': 'exsang_one_x',
          'no_repeat_2x': 'exsang_no_repeat_2x', 'no_repeat_1x': 'exsang_no_repeat_1x'}
INPUT_KEYS = ['study_spec', 'resolved_fields', 'seed_start', 'duration_ms',
              'rotation', 'gear', 'monster_overrides']


def percent_drop(before, after):
    # Zero fuel has no percentage baseline; preserve a finite value in artifacts.
    return 100 * (1 - after / before) if before else 0.0


def validate_no_repeat(row, context):
    metrics = row['aggregate']
    for key in ['exsanguinate_repeat_casts', 'exsanguinate_repeated_health_removed']:
        assert all(value == 0 for stat, value in metrics[key].items() if stat != 'count'), (context, key)
    assert metrics['exsanguinate_casts'] == metrics['exsanguinate_original_casts'], context
    for sample in row['samples']:
        assert sample['exsanguinate_repeat_casts'] == 0, (context, sample['seed'])
        assert sample['exsanguinate_repeated_health_removed'] == 0, (context, sample['seed'])
        assert sample['exsanguinate_casts'] == sample['exsanguinate_original_casts'], (context, sample['seed'])


def extract_row(label, key, versions, seeds):
    first = versions['repeat_2x']
    for name, row in versions.items():
        for field in INPUT_KEYS:
            assert row[field] == first[field], (label, key, name, field)
        assert [s['seed'] for s in row['samples']] == [s['seed'] for s in first['samples']], (label, key, name, 'seed IDs')
        assert len({s['seed'] for s in row['samples']}) == len(row['samples']), (label, key, name)
    # Within each eligibility mode, coefficient is the sole changed variable.
    _baseline.compare_row(versions['repeat_2x'], versions['repeat_1x'], label, seeds)
    _baseline.compare_row(versions['no_repeat_2x'], versions['no_repeat_1x'], label, seeds)
    for name in ['no_repeat_2x', 'no_repeat_1x']:
        validate_no_repeat(versions[name], (label, key, name))
    result = {'dataset': label, 'id': key, 'label': first['label'], 'seeds': seeds,
              'shred_value': first['resolved_fields']['shred_value'],
              'bonus_shred_stacks': first['resolved_fields']['bonus_shred_stacks']}
    for name, row in versions.items():
        metrics = row['aggregate']
        for component, total, rate in [
                ('removal', 'total_health_removed', 'health_removed_per_second'),
                ('ordinary', 'total_damage', 'dps'),
                ('combined', 'total_health_loss', 'health_loss_per_second')]:
            result[f'{name}_{component}_30s_mean'] = metrics[total]['mean']
            result[f'{name}_{component}_dps_mean'] = metrics[rate]['mean']
            _baseline.equal(metrics[rate]['mean'], metrics[total]['mean'] / 30, (label, key, name, rate))
        for metric in ['exsanguinate_casts', 'exsanguinate_original_casts',
                       'exsanguinate_repeat_casts', 'exsanguinate_stacks_consumed',
                       'exsanguinate_original_health_removed', 'exsanguinate_repeated_health_removed']:
            result[f'{name}_{metric}_mean'] = metrics[metric]['mean']
    for before, after in [('repeat_2x', 'no_repeat_2x'), ('repeat_1x', 'no_repeat_1x'),
                          ('no_repeat_2x', 'no_repeat_1x'), ('repeat_2x', 'no_repeat_1x')]:
        for component in ['removal', 'ordinary', 'combined']:
            result[f'{before}_to_{after}_{component}_drop_percent'] = percent_drop(
                result[f'{before}_{component}_30s_mean'], result[f'{after}_{component}_30s_mean'])
    return result


def chart(rows):
    chosen = [('profiles_200', 'low_0pt_stab_exsang', 'Nightkiss, no talents'),
              ('profiles_200', 'user_35bd_10thief', 'User rotation: 35 BD / 10 Thief'),
              ('shadow_profiles_200', 'sh35_bd10_decay_solo', '35 Shadow / 10 BD, Nightkiss'),
              ('shadow_profiles_200', 'bd29_sh16_solo', '29 BD / 16 Shadow, Nightkiss'),
              ('profiles_200', 'optimized_full_coil', '35 BD / 10 Thief, five Legendaries'),
              ('shadow_profiles_200', 'bd29_sh16_full_coil', '29 BD / 16 Shadow, five Legendaries'),
              ('profiles_200', 'five_legendaries_signet', 'User rotation, five Legendaries + Signet'),
              ('profiles_200', 'control_same_weapon_no_exsang', 'Same Nightkiss gear, no Exsanguinate'),
              ('profiles_200', 'generated_endpoint_short_rotation', 'Max-roll endpoint: 35 BD / 10 Thief')]
    fig, axes = plt.subplots(1, 2, figsize=(18, 8), sharey=True, layout='constrained')
    for ax, coefficient in zip(axes, ['2x', '1x']):
        for i, (dataset, key, _) in enumerate(chosen):
            row = next(r for r in rows if r['dataset'] == dataset and r['id'] == key)
            for mode, offset, color in [('repeat', -.17, '#a65a32'), ('no_repeat', .17, '#267d9b')]:
                value = row[f'{mode}_{coefficient}_combined_dps_mean']
                ax.scatter(value, i + offset, color=color, marker='o' if mode == 'repeat' else 's',
                           label='Repeats allowed' if mode == 'repeat' and i == 0 else 'No repeats' if i == 0 else None)
                ax.annotate(f'{value:,.0f}', (value, i + offset), xytext=(6, 0),
                            textcoords='offset points', va='center', fontsize=8, color=color)
        ax.set_xscale('symlog', linthresh=100)
        ax.set_xlim(0, max(r[f'{mode}_{coefficient}_combined_dps_mean']
                           for r in rows for mode in ['repeat', 'no_repeat']) * 5)
        ax.xaxis.set_major_formatter(FuncFormatter(lambda x, _: f'{x/1e6:g}M' if x >= 1e6 else f'{x/1000:g}k' if x >= 1000 else f'{x:g}'))
        ax.set_title(f'{coefficient} Shred: repeats allowed vs. no repeats')
        ax.set_xlabel('Mean whole-build DPS: ordinary damage + removal (symlog scale)')
        ax.grid(axis='x', alpha=.2)
        ax.legend(loc='upper right')
    axes[0].set_yticks(range(len(chosen)), [entry[2] for entry in chosen])
    axes[0].invert_yaxis()
    fig.suptitle('Exsanguinate repeat eligibility — actual native 30-second runs, 200 seeds per profile\n'
                 'Shared seed IDs and inputs; RNG streams can diverge when repeat rolls are removed', fontsize=12)
    fig.savefig(OUT / 'overview.png', dpi=160)
    fig.savefig(OUT / 'overview.svg')
    plt.close(fig)


def main():
    rows, datasets = [], {}
    for label, (count, seeds) in EXPECTED.items():
        paths = {name: WORK / group / 'project/reports/balance/exsanguinate_study' / label / 'summary.json'
                 for name, group in GROUPS.items()}
        studies = {name: _baseline.read(path, count, seeds) for name, path in paths.items()}
        first = studies['repeat_2x']
        for name, study in studies.items():
            for field in ['duration_ms', 'phase', 'seed_count']:
                assert study[field] == first[field], (label, name, field)
        indexed = {name: {r['id']: r for r in data['rows']} for name, data in studies.items()}
        assert all(index.keys() == indexed['repeat_2x'].keys() for index in indexed.values()), label
        for key in indexed['repeat_2x']:
            rows.append(extract_row(label, key, {name: index[key] for name, index in indexed.items()}, seeds))
        datasets[label] = {'scenarios': count, 'seeds': seeds, 'invalid': 0,
                           'sources': {name: {'path': str(path), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
                                       for name, path in paths.items()}}
    assert len(rows) == 130 and sum(row['seeds'] for row in rows) == 12464
    # Do not create or overwrite artifacts until every dataset in every group passes.
    report = {'scenario_evaluations_per_group': 130, 'windows_per_group': 12464,
              'groups': GROUPS, 'datasets': datasets,
              'validation': {'complete': True, 'all_pass': True, 'invalid': 0,
                             'same_study_specs_resolved_fields_inputs_seed_ids': True,
                             'no_repeat_casts_and_repeated_removal_exactly_zero': True,
                             'no_repeat_total_casts_equal_original_casts': True,
                             'coefficient_only_pairs_all_removal_statistics_halved': True,
                             'coefficient_only_pairs_all_unaffected_metrics_identical': True,
                             'coefficient_only_sample_pairs_checked_per_mode': sum(min(r['seeds'], 24) for r in rows),
                             'one_billion_hp_targets_never_killed': True},
              'metric_definitions': {'ordinary': 'Native Lab total_damage / dps.',
                                     'removal': 'Native Lab total_health_removed / health_removed_per_second.',
                                     'combined': 'Ordinary plus removal, matching D088 CombatLog whole-build damage presentation.',
                                     'comparison': 'Actual rerun observations. No paired RNG claim across repeat eligibility modes; removing repeat chance rolls can change ordinary damage, casts and stack generation.',
                                     'percent_drop': '100 * (before - after) / before; 0 when before is zero. Negative values indicate an increase.',
                                     'quantiles': 'Native coefficient pairs validate removal quantiles; combined quantiles are never reconstructed from marginal quantiles.'},
              'rows': rows}
    OUT.mkdir(parents=True, exist_ok=True)
    with (OUT / 'comparison.csv').open('w', newline='', encoding='utf-8') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    (OUT / 'analysis.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    chart(rows)
    print(json.dumps({'scenario_evaluations_per_group': 130, 'windows_per_group': 12464,
                      'groups': len(GROUPS), 'output': str(OUT)}, indent=2))


if __name__ == '__main__':
    main()
