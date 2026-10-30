"""Summarize native Balance Lab Exsanguinate samples; no gameplay edits."""
from pathlib import Path
import csv, hashlib, json, re, subprocess
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'work/m8_t9_presentation'
OUT=ROOT/'project/reports/balance/exsanguinate_study_review'
OUT.mkdir(parents=True,exist_ok=True)
def read(group,label):
    path=WORK/group/'project/reports/balance/exsanguinate_study'/label/'summary.json'
    data=json.loads(path.read_text(encoding='utf-8'))
    assert data['complete'] and data['invalid_scenarios']==0,path
    assert all(r['status']=='pass' for r in data['rows']),path
    return data
current=read('exsang_current','profiles_200')
diagnostics=[read('exsang_no_dance_guarantee',label) for label in ['diagnostic_user_200','diagnostic_optimized_200']]
search=read('exsang_current','rotation_search')
references=read('exsang_current','weapon_references_200')
by_id={r['id']:r for r in current['rows']}
diag={r['id']:r for d in diagnostics for r in d['rows']}
def metric(row,key='total_health_removed'): return row['aggregate'][key]
def mean(row,key='total_health_removed'): return metric(row,key)['mean']
labels={
 'zero_fuel':'No Shred fuel', 'low_0pt_stab_exsang':'Nightkiss, no talents',
 'low_10pt':'10 BD points', 'full35_only':'35 BD, no secondary',
 'user_35bd_10thief':'Your rotation: 35 BD / 10 Thief',
 'control_same_weapon_no_exsang':'Same weapon/build, no Exsanguinate',
 'optimized_solo':'Nightkiss only, focused rotation',
 'optimized_full_coil':'Five Legendaries, focused rotation',
 'generated_endpoint_user_rotation':'Depth-12 max-roll gear, your rotation',
 'generated_endpoint_short_rotation':'Depth-12 max-roll gear, focused rotation',
}
fields=['id','label','seeds','ordinary_damage','health_removed_mean','health_removed_min','health_removed_p05','health_removed_p50','health_removed_p95','health_removed_max','removal_per_second','combined_loss_per_second','actual_original_casts','actual_repeat_casts','attempts','stacks_consumed','root_removal','repeated_removal','diagnostic_no_dance_mean']
table=[]
for r in current['rows']:
    a=metric(r)
    table.append(dict(zip(fields,[r['id'],labels.get(r['id'],r['id']),a['count'],mean(r,'total_damage'),a['mean'],a['min'],a['p05'],a['p50'],a['p95'],a['max'],mean(r,'health_removed_per_second'),mean(r,'health_loss_per_second'),mean(r,'exsanguinate_original_casts'),mean(r,'exsanguinate_repeat_casts'),mean(r,'exsanguinate_attempts'),mean(r,'exsanguinate_stacks_consumed'),mean(r,'exsanguinate_original_health_removed'),mean(r,'exsanguinate_repeated_health_removed'),mean(diag[r['id']]) if r['id'] in diag else None])))
with (OUT/'all_profiles.csv').open('w',encoding='utf-8',newline='') as f:
    writer=csv.DictWriter(f,fields);writer.writeheader();writer.writerows(table)
(OUT/'analysis.json').write_text(json.dumps({'rows':table,'references':references['rows'],'current_scenarios':len(current['rows']),'diagnostic_scenarios':len(diag),'search_scenarios':len(search['rows']),'main_windows':sum(r['seed_count'] for r in current['rows'])+sum(r['seed_count'] for r in diag.values())+sum(r['seed_count'] for r in references['rows']),'search_windows':sum(r['seed_count'] for r in search['rows'])},indent=2),encoding='utf-8')

selected=['low_0pt_stab_exsang','full35_only','user_35bd_10thief','optimized_solo','optimized_full_coil','generated_endpoint_short_rotation']
fig,ax=plt.subplots(figsize=(10.5,5.5),layout='constrained')
for i,key in enumerate(selected):
    r=by_id[key];a=metric(r)
    ax.errorbar(a['mean'],i,xerr=[[a['mean']-a['p05']],[a['p95']-a['mean']]],fmt='o',capsize=4,color='#3178a8' if not key.startswith('generated') else '#b45b27')
    extreme=key.startswith('generated')
    ax.annotate(f"{a['mean']:,.0f}",(a['mean'],i),xytext=(-8 if extreme else 7,9),ha='right' if extreme else 'left',textcoords='offset points',fontsize=9)
ax.set_yticks(range(len(selected)),[labels[k] for k in selected]);ax.invert_yaxis();ax.set_xscale('log');ax.grid(axis='x',alpha=.25)
ax.set_xlabel('Exsanguinate health removed over 30 seconds (log scale)')
ax.set_title('Current rules — 200 seeds per build\nPoints show means; whiskers show the 5th–95th percentile simulation range')
fig.savefig(OUT/'overview.png',dpi=160);fig.savefig(OUT/'overview.svg');plt.close(fig)

user=by_id['user_35bd_10thief'];control=by_id['control_same_weapon_no_exsang'];nodance=diag[user['id']]
key='optimized_full_coil';high=by_id[key];extreme=by_id['generated_endpoint_short_rotation']
lines=[
 '# T10 focused Exsanguinate Balance Lab investigation', '',
 '2026-10-24, D086. User requested low/mid/top simulations after observing about64,000 health removal in30 seconds with35 Bladedancer /10 Thief and Nightkiss only. This is a focused T10 investigation; no balance change or overall T10 completion is adopted.', '',
 '## Result', '',
 f"The reported result is reproduced in scale: the matching rotation has median **{metric(user)['p50']:,.0f}**, mean **{mean(user):,.0f}**, and5th–95th percentile range **{metric(user)['p05']:,.0f}–{metric(user)['p95']:,.0f}** health removed in30 seconds. Ordinary damage averages{mean(user,'total_damage'):,.0f} separately. Exsanguinate contributes{mean(user)/mean(user,'total_health_loss'):.1%} of combined health loss.", '',
 '| Tested profile | Mean removal /30s | Removal /second | 5th–95th percentile /30s |',
 '| --- | ---: | ---: | ---: |',
]
for key in selected:
    r=by_id[key];a=metric(r)
    lines.append(f"| {labels[key]} | {a['mean']:,.0f} | {a['mean']/30:,.0f} | {a['p05']:,.0f}–{a['p95']:,.0f} |")
lines += ['', '![Measured Exsanguinate range](../project/reports/balance/exsanguinate_study_review/overview.png)', '',
 'These are sampled build profiles, not progression percentiles or proof of a global optimum. The last row is a deliberately extreme but generator-validated max-roll endpoint, not a normal earned build or an observed drop seed. The zero-fuel floor is0. Damage/DPS retain their existing meanings; health removal and combined health-loss rate are separate measurements.', '',
 '## Reproduction and method', '',
 '- Actual `BalanceLab.run_scenario_spec` with current ranked registry and CombatResolver, full30-second windows. All final profiles use combat seeds1–200, zero starting gold, five-slot ownership limits and no stat overrides. The empty dummy has zero defenses; HP is raised to1 billion solely to keep an endurance target. These are output measurements, not calibrated time-to-kill or earned-run win rates.',
 '- User rotation mapped to current skill names: Dance of Death → Quick Cut → Heavy Slash → Parry Strike → Leaping Plunge → Exsanguinate. All35 BD ranks are maxed. The unspecified10 Thief allocation is assumed to be the existing protocol baseline: Sticky Fingers5 / Fast Hands5. Therefore this is a closely matching reproduction, not an exact saved-setup replay.',
 '- Nightkiss-only comparisons use no other gear. A control removes Exsanguinate from the same build/weapon rotation, avoiding a weapon-base-damage confound.',
 f"- Matched weapon references add3×200 windows. Mithril Karambit with the same five ordinary skills averages{mean(references['rows'][0],'total_damage'):,.0f} damage; with the prior protocol rotation it averages{mean(references['rows'][1],'total_damage'):,.0f}. Nightkiss without Exsanguinate on that protocol averages{mean(references['rows'][2],'total_damage'):,.0f}. Your Exsanguinate rotation averages{mean(user,'total_health_loss'):,.0f} combined health loss. This supports the concern against a relevant Bladedancer weapon reference, without claiming every weapon/build was optimized.",
 f"- Native current-rule profiles:{len(current['rows'])}×200={len(current['rows'])*200:,} windows. Copied-runtime Dance diagnostics:{len(diag)}×200={len(diag)*200:,}. Bounded rotation search:{len(search['rows'])}×12={len(search['rows'])*12:,}. Final candidate rotations are re-evaluated on200 seeds; search is not exhaustive. Pilot runs are retained separately and excluded from these headline totals.",
 '- All selected native scenarios are valid across their complete seed sets. Candidate overflow remains invalid, and the1024-candidate /depth16 rules are unchanged. A pass status here means successful execution, not balanced gameplay.',
 '- Balance Lab now exposes health removal, combined loss, consumed Shred and original/repeated activations. Cooldown-blocked attempts are counted separately: a zero-retrigger cooldown fixture produces292 attempts but only4 actual roots in30 seconds. Existing damage/DPS and native invalid-result handling are unchanged. The focused measurement test passes53 checks; the existing Balance Lab import regression also passes.', '',
 '## Why it scales', '',
 '1. Full BD resolves **185 Shred Value**: base10 + Nightkiss50 + Weakness25 + Virulent Corruption100. Exsanguinate therefore removes **370 health per actual consumed stack**, bypassing damage mitigation.',
 '2. Nightkiss+5 All Stacks and Virulent Corruption+2 turn a normal Shred proc into8 stacks; Rending Slash applies9 plus its separate chance proc. Shred can accumulate to500. Virulent Corruption protects it from cleanse.',
 f"3. The user-like build consumes an average{mean(user,'exsanguinate_stacks_consumed'):.2f} stacks across{mean(user,'exsanguinate_original_casts'):.2f} actual roots. Roots account for{mean(user,'exsanguinate_original_health_removed'):,.0f} removal; free repeats add{mean(user,'exsanguinate_repeated_health_removed'):,.0f} without consuming more Shred.",
 '4. Numeric Retrigger Chance is12%. Repeating the whole captured stack total multiplies the payoff; repeats preserve that capture through depth16. The expected simple-chain multiplier outside Dance is Σ(p^k), k0..16, about1.136 at p=.12. At100%, one root produces17 full-value activations.',
 '5. Cooldown reduction and faster fuel generation combine. The tested rare endpoint has two valid Unique items and two all-positive Chaos items at depth12, using actual generator endpoint values and eligibility checks. Chaos legitimately permits duplicate outcomes. It resolves100% Retrigger Chance, +20 Shred stacks, doubled applications and a393ms Exsanguinate cooldown. It is not arbitrary player-stat inflation.', '',
 '## Dance correctness finding', '',
 'The [approved Dance contract](P6M5_T3_Bladedancer_Design_Review.md) requires connected macro **attacks** and explicitly excludes nonattack skills. Current tooltips still say attacks. The lifecycle currently supplies the Dance guarantee for every macro skill; M8 made Exsanguinate repeat-eligible, exposing that broad flag to a Debuff. No explicit design approval broadening Dance to Debuffs was found.', '',
 f"A copied-runtime diagnostic suppresses only Exsanguinate's Dance guarantee, retaining numeric retriggers, Shred, gear, cooldowns and every other rule. Your rotation's mean falls **{mean(user):,.0f} → {mean(nodance):,.0f}** ({1-mean(nodance)/mean(user):.1%} lower). It still produces{(mean(nodance)+mean(nodance,'total_damage'))/mean(control,'total_health_loss'):.2f}× the control's combined health-loss rate. The focused five-Legendary rotation falls{mean(high):,.0f} → {mean(diag[high['id']]):,.0f}; the100%-retrigger endpoint remains enormous because numeric repeats still reproduce the capture.", '',
 'This is a likely eligibility bug to correct before balance tuning. The diagnostic is not promoted to production. Same seed sets are used, but changed branching can change RNG consumption; comparisons describe distributions rather than claiming identical downstream rolls.', '',
 '## Counterplay and limits', '',
 '- Armor, block and Poison resistance reduce ordinary damage but do not reduce Exsanguinate removal in the matched target comparison. Cleanse does not reduce full-BD Shred because of Virulent Corruption.',
 '- Dodge and slow reduce attack-fed Shred and total output. Exsanguinate itself does not roll an attack hit. The tested32 BD /13 Thief Bribery branch supplies Shred through Pick Pocket and retains removal even against100% dodge; this is a counterplay gap, not generic dodge immunity for every build.',
 '- Maximum captured root at this185 Shred Value and500 cap is185,000 removal;17 activations give3,145,000 per root. This is a per-root bound, not sustained output. The300ms cast minimum gives a very loose30-second envelope, not an achievable global optimum.',
 '- Fixed-roster high build: Nightkiss, Crown of Concentration, Cloak of Speed, Lolzorz’s Locket, Serpent’s Coil. Its searched rotation is Dance → Quick Cut → Quick Cut → Parry Strike → Exsanguinate. Other tested five-Legendary variants include Wingjammer, Mysterious Lucky Coin and Signet branches.',
 '- Loot probability, rarity timing, gold opportunity cost and earned acquisition of extreme gear are not simulated. Full build ranks and endpoint gear are fixtures. No final T10 balance acceptance, full-run validation or export qualification follows from these tests.', '',
 '## Recommendation for review', '',
 '**The concern is supported by the measurements.** First correct Dance’s attack-only eligibility as a focused bug fix, then retest. That alone does not contain Exsanguinate’s ceiling. Next evaluate a constraint on full captured-value repeats, or a revised Shred-to-health conversion, with a stated target contribution for the naked Nightkiss build and an explicit desired relationship to negative-armor physical builds. A coefficient-only nerf cannot remove the17× echo scaling. No tuning value is adopted in this investigation.', '',
 '## Evidence', '',
 '- Runner: `project/scripts/tools/run_exsanguinate_study.gd`; analysis: `tools/p6/analyze_exsanguinate_study.py`.',
 '- Legal endpoint helper: `project/tests/fixtures/exsanguinate_top_gear.gd`; validated actual generation plans, endpoint values, unique slots, SaveSystem domain validation and exact payload round trips.',
 '- [All-profile CSV](../project/reports/balance/exsanguinate_study_review/all_profiles.csv), [analysis JSON](../project/reports/balance/exsanguinate_study_review/analysis.json), [manifest](../work/m8_t9_presentation/exsanguinate_study_verification.json).',
 '- Copied projects and redirected APPDATA/LOCALAPPDATA/save paths only. Production combat, loot, player saves, sibling project and art are unchanged. Existing certificate/resource-exit diagnostics remain. Generated reports are local evidence excluded by the checkpoint ignore policy.',
]
text='\n'.join(lines)+'\n'
for old,new in {
 'about64,000':'about 64,000','in30 seconds':'in 30 seconds','with35 Bladedancer /10 Thief':'with 35 Bladedancer / 10 Thief',
 'and5th':'and 5th','separately. Exsanguinate':'separately. Exsanguinate','full30-second':'full 30-second',
 'All35 BD':'All 35 BD','unspecified10 Thief':'unspecified 10 Thief','Fingers5 / Fast Hands5':'Fingers 5 / Fast Hands 5',
 'seeds1–200':'seeds 1–200','by500':'by 500','to500':'to 500','at100%':'at 100%',
 'to0.':'to 0.','floor is0':'floor is 0','depth16':'depth 16','The300ms':'The 300ms',
 'four positive':'four positive','two all-positive':'two all-positive','53 checks':'53 checks',
 'across88':'across 88','build ranks':'build ranks',
}.items():text=text.replace(old,new)
words='averages|contributes|raised to|add|profiles:|diagnostics:|search:|on|the|generates|only|passes|base|Nightkiss|Weakness|Corruption|into|applies|average|across|for|is|about|At|produces|depth|resolves|a|all|tested|gives|remaining|retains|even against|factor'
text=re.sub(r'\b('+words+r')(?=\d)',r'\1 ',text)
text=text.replace('/30s','/ 30s').replace('at100%','at 100%').replace('k0..16','k 0..16')
(ROOT/'docs/P6M8_T10_Exsanguinate_Balance_Investigation.md').write_text(text,encoding='utf-8')
print('Wrote report and chart')
for key in selected:
    r=by_id[key];print(key,metric(r))
