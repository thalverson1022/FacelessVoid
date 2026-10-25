"""Summarize the read-only Assassin Balance Lab inquiry and audit its captured ticks."""
import csv, hashlib, html, json, math, re
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'project/reports/balance/assassin_inquiry'
# Historical evidence must never be relabeled with a later runtime fingerprint.
manifest_path=OUT/'source_manifest.json'
if manifest_path.exists():
 recorded=json.loads(manifest_path.read_text(encoding='utf-8'))
 resolver='project/scripts/systems/combat_resolver.gd'
 assert hashlib.sha256((ROOT/resolver).read_bytes()).hexdigest()==recorded[resolver], 'Archived pre-D010 analysis: restore its recorded runtime baseline before regenerating historical reports.'

data=json.loads((OUT/'results.json').read_text(encoding='utf-8'))
controls=json.loads((OUT/'controls.json').read_text(encoding='utf-8'))
assert data['pass'] and controls['pass']
rows=data['scenarios']+controls['scenarios']
by={r['id']:r for r in rows}
b=by['baseline']; baseline=b['dps']['mean']
native=json.loads((OUT/'native_balance_lab.json').read_text(encoding='utf-8'))
assert math.isclose(native['aggregate']['dps']['mean'],baseline)
for r in rows:
 assert r['dps']['count']==200 and len(r['samples'])==200
 assert all(math.isclose(s['total_damage']/ (r['duration_ms']/1000),s['dps']) for s in r['samples'])

labels={
'baseline':'Full Assassin baseline','no_potency':'Powder: no Potency','no_virulent':'Virulent multiplier disabled',
'no_toxic_bonus':'Toxic damage bonus disabled','no_resonance':'Resonance disabled',
'no_echo_resonance':'Echoing + Resonance disabled','no_cadence':'Hastened + Accelerant disabled',
'no_poison_crit':'Critical Poison disabled','no_bypass':'Bypass disabled','no_point_base':'35-point base elemental bonus removed',
'vile_10':'Poison Vile: 10 stacks instead of 20','potency_half':'Powder: 18 Potency instead of 35',
' toxic_half_bonus':'Toxic bonus halved', 'toxic_half_bonus':'Toxic multiplier: 1.5 instead of 2',
'control_bladedancer':'Full Bladedancer','control_thief_gold0':'Full Thief: 0 starting gold',
'control_thief_gold500':'Full Thief: 500 starting gold'}

def table(items):
 out=['| Diagnostic scenario | Mean DPS | Median | 5th–95th percentile | Change vs baseline |', '|---|---:|---:|---:|---:|']
 for r in items:
  d=r['dps']; delta=100*(d['mean']/baseline-1)
  out.append(f"| {labels.get(r['id'],r['id'])} | {d['mean']:.1f} | {d['p50']:.1f} | {d['p05']:.1f}–{d['p95']:.1f} | {delta:+.1f}% |")
 return '\n'.join(out)

trace=json.loads((OUT/'baseline_trace.json').read_text())
ticks=trace['ticks']; live=[r for r in ticks if r['payload']['stacks_consumed']]
base=trace['casts'][0]['stats']; base_elemental=base['base_poison_damage']+base['bonus_base_elemental_damage']
max_error=0
for r in live:
 p=r['payload']; elemental=p['poison_damage_per_tick']/base_elemental
 raw=(p['poison_damage_per_tick']+(p['negative_absorb_base_bonus']+p['buffs']['elemental_base'])*elemental)*p['buffs']['poison_multiplier']*p['stacks_consumed']*1.3*1.8*2
 max_error=max(max_error,abs(raw-p['raw_damage']))
 assert math.isclose(raw,p['raw_damage'],abs_tol=1e-7)
 expected=math.floor(raw*(p['crit_multiplier'] if p['is_crit'] else 1)+0.5)
 assert p['damage']==expected, (p['damage'],expected)
# Integrate recorded post-event state. Equal timestamps retain resolver sequence order.
events=sorted(trace['status_transactions']+ticks,key=lambda r:r['sequence'])
last=0; stacks=0; fueled_ms=0
for r in events:
 if r['kind']=='status_transaction' and r['payload']['status']!='poison': continue
 time=r['time_ms']; fueled_ms+=(time-last) if stacks>0 else 0; last=time
 stacks=r['payload']['stacks_remaining'] if r['kind']=='poison_tick' else r['payload']['after']
fueled_ms+=(30000-last) if stacks else 0
active={}; last=0; uptime={'potency':0,'virulent_poison':0,'bypass':0}; peak_virulent=0
for r in trace['effects']:
 time=r['time_ms']
 for effect in uptime:
  if any(v[0]==effect for v in active.values()): uptime[effect]+=time-last
 last=time
 p=r['payload']; key=r['effect_instance_id']
 if p.get('after'): active[key]=(p['effect_id'],p['after'])
 else: active.pop(key,None)
 peak_virulent=max(peak_virulent,sum(v[0]=='virulent_poison' for v in active.values()))
for effect in uptime:
 if any(v[0]==effect for v in active.values()): uptime[effect]+=30000-last
transactions=[r['payload'] for r in trace['status_transactions'] if r['payload']['status']=='poison']
diagnostics={'seed':1,'ticks':len(ticks),'damaging_ticks':len(live),'forced_ticks':sum(r['origin_kind']=='forced_tick' for r in ticks),
 'stacks_applied':sum(p['applied'] for p in transactions),'overflow':sum(p['overflow'] for p in transactions),
 'stacks_consumed':sum(r['payload']['stacks_consumed'] for r in ticks),'fuel_uptime_ms':fueled_ms,'effect_uptime_ms':uptime,
 'peak_virulent_instances':peak_virulent,'max_tick_formula_error':max_error,'poison_dps_share':b['poison_dps']['mean']/baseline}
(OUT/'diagnostics.json').write_text(json.dumps(diagnostics,indent=2)+'\n')

main=[by[i] for i in ['baseline','no_echo_resonance','no_resonance','no_toxic_bonus','no_point_base','no_virulent','no_potency','no_bypass','no_poison_crit','no_cadence']]
plt.rcParams.update({'font.size':10})
fig, ax=plt.subplots(figsize=(10,5.5),layout='constrained')
vals=list(reversed(main)); ax.barh([labels[r['id']] for r in vals],[r['dps']['mean'] for r in vals],color=['#739caf']*(len(vals)-1)+['#8a58aa'])
for i,r in enumerate(vals): ax.text(r['dps']['mean']+12,i,f"{r['dps']['mean']:.0f}",va='center')
ax.set_xlim(0,1800); ax.set_xlabel('Mean DPS • 200 seeds • 30 seconds'); ax.set_title('Assassin: controlled effect removals'); ax.spines[['top','right']].set_visible(False)
fig.savefig(OUT/'contributions.png',dpi=160); plt.close(fig)
progress=sorted([r for r in rows if r['id'].startswith('reference_points_')]+[b],key=lambda r:r['build']['earned_talent_points'])
fig,ax=plt.subplots(figsize=(9,4),layout='constrained'); ax.plot([r['build']['earned_talent_points'] for r in progress],[r['dps']['mean'] for r in progress],marker='o',color='#8956a7'); ax.set_xlabel('Assassin points'); ax.set_ylabel('Mean DPS'); ax.set_title('Reference allocation path — not the user’s original lower-point builds'); ax.grid(alpha=.2); fig.savefig(OUT/'progression.png',dpi=160); plt.close(fig)

pair_rows=[r for r in rows if r['id'].startswith('pair_')]
interaction=[]
for r in pair_rows:
 a,c=r['switches']; prediction=by[a]['dps']['mean']+by[c]['dps']['mean']-baseline
 interaction.append({'effects':[a,c],'double_disabled_dps':r['dps']['mean'],'additive_prediction_dps':prediction,'interaction_dps':baseline-by[a]['dps']['mean']-by[c]['dps']['mean']+r['dps']['mean']})
(OUT/'interactions.json').write_text(json.dumps(interaction,indent=2)+'\n')

report=f'''# Assassin Balance Lab inquiry

The full Assassin build averages **{baseline:.1f} DPS**, versus **{by['control_bladedancer']['dps']['mean']:.1f}** for the specified Bladedancer macro and **{by['control_thief_gold0']['dps']['mean']:.1f}** for Thief at zero starting gold. Assassin's 5th–95th percentile range is **{b['dps']['p05']:.1f}–{b['dps']['p95']:.1f}**, encompassing the user's 1625.9 DPS observation.

**The dominant mechanism is well-fueled multi-stack ticks multiplied by several independent damage bonuses.** Removing Echoing and Resonance together brings Assassin to {by['no_echo_resonance']['dps']['mean']:.1f} DPS. Removing Resonance alone leaves {by['no_resonance']['dps']['mean']:.1f}. These are diagnostic removals, not proposed balanced builds. No gameplay values were edited.

## Conditions and reproducibility

- Current registry `{data['content_revision']}`; all 35 points in one tree, no secondary tree.
- Crude Dagger, no other gear. Same weapon across all three controls. The user's “crude sword” wording was normalized to the repository's Crude Dagger rather than inventing another item.
- Assassin: Poison Vile → Blinding Powder → Stab → Stab → Stab → Virulent Poison.
- Bladedancer: Dance of Death → Quick Cut → Stab → Parry Strike → Quick Cut → Stab → Parry Strike → Leaping Plunge. User names normalized to available content IDs.
- Thief: Pick Pocket → Steal → Mug → Big Score. Zero starting gold baseline; 500-gold sensitivity control.
- Zero-defense Training Dummy, HP raised to 100,000,000 so every run lasts the full window. 30 seconds, seeds 1–200 unless duration/defense is explicitly varied.
- Original ranked Balance Lab baseline matches the diagnostic runner's mean. Every scenario also repeats seed 1 with tracing and compares a trace-disabled run for damage/RNG parity.
- Diagnostic copies preserve talent investment, unlocked skills, macro slots, cast category, execution times and cooldowns. Toxic bonus removal retains its physical penalty to isolate Poison damage. Echoing is removed together with Resonance because Resonance requires it. No legal build is implied by diagnostic combinations.
- All 200 samples are retained. Seed 1 has detailed ticks, casts, lifecycles and stack transactions. Reused seed numbers do not guarantee identical RNG draw alignment after a mechanic is removed.
- Lower-point builds use the explicit order in `results.json`; exact original lower-point allocations were unavailable. Those results must not be presented as reproductions of the user's curve.

## Main comparisons

{table(main)}

![Effect removals](contributions.png)

Loss percentages overlap because effects multiply; they are not slices of a 100% attribution pie.

## Damage explanation

Poison contributes **{100*diagnostics['poison_dps_share']:.2f}%** of baseline mean DPS. The inspected trace has {len(live)} damaging ticks out of {len(ticks)} scheduled ticks, {diagnostics['forced_ticks']} forced ticks, {diagnostics['stacks_applied']} stacks applied, {diagnostics['stacks_consumed']} consumed, and {diagnostics['overflow']} lost to the cap. Poison has fuel for {fueled_ms/1000:.3f} of 30 seconds. Potency is active for {uptime['potency']/1000:.3f}s; Virulent for {uptime['virulent_poison']/1000:.3f}s. Maximum simultaneous Virulent instances: **{peak_virulent}**. Timings and uptime here are seed-1 diagnostics, not aggregate estimates.

At 10.472 seconds, a noncritical tick is independently reconstructed as:

`(8 class base + 5 Assassin innate + 35 invested points + 35 Potency) × 2 Virulent × 3 stacks × 1.3 Echoing × 1.8 Resonance × 2 Toxic = 2330.64 → 2331 damage`.

Bypass can further increase the elemental amount on other ticks. Each of the {len(live)} damaging baseline seed-1 ticks matched the raw formula and final crit/rounding result. This check finds no duplicated multiplier in those ticks; it is not a proof that every build or interaction is bug-free.

Poison speed is a weak contributor in this low-IAS setup: 5% IAS with the full cadence talents yields a 952ms interval versus 1000ms without them. The small DPS increase when disabled is consistent with changed timing/fuel/buff alignment, not evidence that these talents are universally harmful.

## Pair interactions

{table(pair_rows)}

`interactions.json` records the four-run contrast baseline − A-disabled − B-disabled + both-disabled. Positive values indicate overlapping amplification on the additive DPS scale; they are not additional independent damage sources.

## Small numerical probes (not applied to gameplay)

{table([by[i] for i in ['vile_10','potency_half','toxic_half_bonus']])}

Each isolated probe still leaves Assassin far above the current crude-weapon controls. Halving Powder alone is unlikely to address the whole gap; a blanket nerf to base Poison would also penalize early progression.

## Fight length, defenses and controls

{table([r for r in rows if r['id'].startswith(('duration_','defense_','control_'))])}

The change column always compares against the 30-second, zero-defense Assassin baseline. These are sensitivity probes, not equivalent encounters. Starting gold changes Thief materially; 500 gold yields {by['control_thief_gold500']['dps']['mean']:.1f} DPS. Crude-weapon DPS parity is not yet an approved global balance target, and higher-tier gear and optimized macros have not been surveyed.

## Reference progression

{table(progress)}

![Reference progression](progression.png)

Order: Quick Hands 5 → Precision 5 → Hastened 5 → Echoing 3 → Poison Strike 1 → Bypass 1 → Toxic 5 → Accelerant 5 → Resonance 4 → Critical Poison 1. Before 12 points, Venom Jab replaces unavailable Poison Vile; before six, Stab replaces Virulent; before three, Stab replaces Powder. This deliberately documented legal reference is not an optimized allocation path.

## Recommended next design decision

Review the combined multi-stack tick payoff first: Echoing/Resonance grant more stacks consumed per tick **and** independent damage multipliers, which then multiply with Toxic and Virulent. Preserve the supply/consumption identity, but decide how much extra DPS faster stack spending should buy before selecting new coefficients. Then test candidate values across early and late budgets, multiple macros, weapon tiers and defensive enemies. The experiment does not justify deleting these talents or immediately targeting exactly 250 DPS.

## Validation and files

{data['checks']+controls['checks']} runner checks passed. Python independently audits baseline tick arithmetic, scenario sample counts and full-duration DPS denominators. The first control attempt used an unavailable `quick_strike` ID; its macro-completeness check failed. It was corrected to `quick_cut` and all controls rerun successfully; only the successful results above are accepted.

Existing Godot certificate and exit-resource warnings remain in run logs. No gameplay resources or live save paths are written by these scripts. This inquiry does not claim that all unrelated saves remained unchanged while other game instances were open.

Reproduce from the repository root using the installed Godot executable with `--headless --path project --log-file <workspace-log>` and `-s res://scripts/tools/run_assassin_balance_inquiry.gd`, then `-s res://scripts/tools/run_assassin_balance_controls.gd`; finally run `python tools/p6/analyze_assassin_inquiry.py`.

Files: `results.json`, `controls.json`, `native_balance_lab.json`, per-scenario `*_trace.json`, `diagnostics.json`, `interactions.json`, `summary.csv`, and `source_manifest.json`.
'''
(OUT/'report.md').write_text(report,encoding='utf-8')
with (OUT/'summary.csv').open('w',newline='',encoding='utf-8') as f:
 writer=csv.writer(f); writer.writerow(['scenario','duration_ms','mean_dps','median_dps','p05','p95','poison_dps','direct_dps','delta_percent'])
 for r in rows: writer.writerow([r['id'],r['duration_ms'],r['dps']['mean'],r['dps']['p50'],r['dps']['p05'],r['dps']['p95'],r['poison_dps']['mean'],r['direct_dps']['mean'],100*(r['dps']['mean']/baseline-1)])
# Standalone report, no network dependencies.
try:
 import markdown
 body=markdown.markdown(report,extensions=['tables'])
except ImportError:
 def inline(text):
  text=html.escape(text)
  text=re.sub(r'`([^`]+)`',r'<code>\1</code>',text)
  return re.sub(r'\*\*([^*]+)\*\*',r'<strong>\1</strong>',text)
 parts=[]; in_table=False; in_list=False
 for line in report.splitlines():
  if not line.startswith('|') and in_table: parts.append('</tbody></table>'); in_table=False
  if not line.startswith('- ') and in_list: parts.append('</ul>'); in_list=False
  if line.startswith('|'):
   cells=[v.strip() for v in line.strip('|').split('|')]
   if all(re.fullmatch(r'[-:]+',c) for c in cells): continue
   tag='td' if in_table else 'th'
   if not in_table: parts.append('<table><tbody>'); in_table=True
   parts.append('<tr>'+''.join(f'<{tag}>{inline(c)}</{tag}>' for c in cells)+'</tr>')
  elif line.startswith('- '):
   if not in_list: parts.append('<ul>'); in_list=True
   parts.append('<li>'+inline(line[2:])+'</li>')
  elif line.startswith('#'):
   level=len(line)-len(line.lstrip('#')); parts.append(f'<h{level}>'+inline(line[level:].strip())+f'</h{level}>')
  elif line.startswith('!['):
   match=re.fullmatch(r'!\[([^]]*)\]\(([^)]+)\)',line)
   if match: parts.append(f'<img alt="{html.escape(match[1])}" src="{html.escape(match[2])}">')
  elif line.strip(): parts.append('<p>'+inline(line)+'</p>')
 if in_table: parts.append('</tbody></table>')
 if in_list: parts.append('</ul>')
 body='\n'.join(parts)
(OUT/'index.html').write_text('<!doctype html><meta charset="utf-8"><title>Assassin Balance Lab inquiry</title><style>body{max-width:1100px;margin:40px auto;padding:0 24px;font:16px/1.55 system-ui;color:#20232b}table{border-collapse:collapse;width:100%;font-size:14px}td,th{padding:7px;border-bottom:1px solid #ddd;text-align:left}th{background:#eee}img{max-width:100%}code{background:#eee;white-space:normal}pre{white-space:pre-wrap}</style>'+body,encoding='utf-8')
paths=list((ROOT/'project/scripts/systems').glob('*.gd'))+list((ROOT/'project/scripts/resources').glob('*.gd'))+list((ROOT/'project/data/p6').rglob('*.tres'))
paths += [ROOT/p for p in ['project/data/classes/rogue.tres','project/data/gear/crude_dagger.tres','project/data/monsters/training_dummy.tres','project/scripts/tools/balance_lab.gd','project/scripts/tools/run_assassin_balance_inquiry.gd','project/scripts/tools/run_assassin_balance_controls.gd','tools/p6/analyze_assassin_inquiry.py']]
paths += list((ROOT/'project/data/skills').glob('*.tres'))
(OUT/'source_manifest.json').write_text(json.dumps({str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(set(paths))},indent=2)+'\n')
print(json.dumps(diagnostics,indent=2)); print('PASS: report, plots, CSV, provenance and independent tick audit')
