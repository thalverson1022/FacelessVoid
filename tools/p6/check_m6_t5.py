"""Verify and summarize T5 review evidence, without adopting tuning values."""
from pathlib import Path
from collections import defaultdict
import json, hashlib, csv
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'project/reports/p6_m6_t5'
TREES=['bladedancer','thief','assassin','shadow']
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
files=TREES+['bladedancer_primary','shadow_primary','steal_timing','tavern_paths']
summary=[];total=0;checks=0;hashes={};max_retrigger=0
for name in files:
 d=read(OUT/(name+'.json'));assert d['complete'],name
 checks+=d['checks'];hashes[name+'.json']=sha(OUT/(name+'.json'))
 for r in d.get('measurements',d.get('trials',[])):
  ss=r['samples'];assert len(ss)==r['count']
  assert sum(x['win'] for x in ss)==r['wins']
  assert sum(x['within_two'] for x in ss)==r['within_two']
  assert all(not x['win'] or x['within_two'] for x in ss)
  expected=set(range(98001,98101)) if name=='tavern_paths' else set(range(97001,97061)) if name=='steal_timing' else set(range(96001,96041))
  assert {x['root'] for x in ss}==expected
  assert all(x.get('seed',0) not in [501,502,503,504] for x in ss)
  max_retrigger=max(max_retrigger,r.get('diagnostic',{}).get('retrigger_chance',0))
  total+=len(ss)
  summary.append({'source':name,'main':r.get('main',name.split('_')[0]),'stage':r['stage'],'policy':r['policy'],'role':r['role'],'arm':r.get('arm',str(r.get('base_execution_ms'))),'wins':r['wins'],'within_two':r['within_two'],'count':r['count'],'mean_margin':r['mean_margin'],'macro':','.join(r['macro']),'ranks':json.dumps(r['ranks'],sort_keys=True)})
 if name.endswith('_primary'):
  # Talent IDs use exceptions for a few shared historical IDs. Compare actual
  # candidate membership rather than infer ownership from a string prefix.
  for stage,winner in d['winners'].items():
   assert any(x['stage']==stage and any(c['ranks']==winner['ranks'] for c in x['finalists']) for x in d['search'])
 if name=='tavern_paths':
  for path in d['paths']:
   assert all(path['three_points'].get(k,0)>=v for k,v in path['one_point'].items())
  for entry in d['ledger']:
   if entry['action']=='buy':assert entry['gold_after']==entry['gold_before']-entry['price']>=0
assert max_retrigger<1.0,max_retrigger
protected=read(OUT/'protected_before.json')
changed=[p for p,h in protected.items() if not Path(p).exists() or sha(Path(p))!=h]
assert not changed,changed
for p in (ROOT/'project/scripts/tools').glob('run_m6_t5*.gd'):hashes[str(p.relative_to(ROOT))]=sha(p)
hashes['tools/p6/check_m6_t5.py']=sha(Path(__file__))
with (OUT/'summary.csv').open('w',newline='',encoding='utf-8') as f:
 w=csv.DictWriter(f,fieldnames=list(summary[0]));w.writeheader();w.writerows(summary)
lines=['# T5 investigation and copied-data trial results','','Gameplay values are unchanged. Review proposal: Steal base execution 1300 ms to 1100 ms; minimum remains 650 ms. All tables are diagnostic, conditional on the saved gear histories. No full-run success rate is claimed.','',f'{len(summary)} measurements, {total:,} held-out first attempts plus failures retried, {checks:,} engine checks. {len(protected)} protected files unchanged. Maximum resolved retrigger chance in search diagnostics: {max_retrigger:.3f}.','','## Typical-policy boss comparison: reference / macro search / build search','','| Tree | Stage | Reference | Macro | Build |','| --- | --- | --- | --- | --- |']
for tree in TREES:
 groups=defaultdict(dict)
 for r in summary:
  if r['source']==tree and r['policy']=='typical' and r['role']=='BOSS':groups[r['stage']][r['arm']]=r
 for stage,arms in groups.items():
  lines.append(f"| {tree} | {stage} | {arms['reference']['within_two']}/40 | {arms['macro_search']['within_two']}/40 | {arms['build_search']['within_two']}/40 |")
lines+=['','Mixed build winners can invest mainly in the secondary; see primary-only controls and exact rank maps before attributing a win to the named main tree.','','## Primary-only allocations, typical policy','','| Tree | Stage | Within two |','| --- | --- | --- |']
for r in summary:
 if r['source'].endswith('_primary') and r['policy']=='typical' and r['role']=='BOSS' and r['arm']=='build_search':lines.append(f"| {r['main']} | {r['stage']} | {r['within_two']}/40 |")
lines+=['','## Reacquired Tavern path, typical policy','','| Main | Fight | Steal timing | First / within two |','| --- | --- | --- | --- |']
for r in summary:
 if r['source']=='tavern_paths' and r['policy']=='typical':lines.append(f"| {r['main']} | {r['stage']} | {r['arm']} ms | {r['wins']}/100; {r['within_two']}/100 |")
lines+=['','For non-Thief rows, 1300 ms denotes unchanged skills; no Steal is available. Training uses seeds 501-504. Search validation uses 96001-96040; timing sweep 97001-97060; fresh Tavern confirmation 98001-98100. Gear acquisition remains conditional on earlier wins and excludes combat theft income.','','## Timing effects in later/mixed controls','','| Main | Stage / role | Mean damage 1300 to 1100 | Mean theft 1300 to 1100 |','| --- | --- | --- | --- |']
sweep=read(OUT/'steal_timing.json')['trials']
for a in sweep:
 if a['base_execution_ms']!=1300 or a['policy']!='typical' or a['stage'] not in ['C10','C15','C20']:continue
 b=next(x for x in sweep if x['main']==a['main'] and x['snapshot']==a['snapshot'] and x['encounter']==a['encounter'] and x['base_execution_ms']==1100)
 lines.append(f"| {a['main']} | {a['stage']} / {a['role']} | {a['mean_damage']:.1f} to {b['mean_damage']:.1f} | {a['mean_gold_stolen']:.1f} to {b['mean_gold_stolen']:.1f} |")
(OUT/'results.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
(OUT/'verification.json').write_text(json.dumps({'passed':True,'measurements':len(summary),'first_attempts':total,'engine_checks':checks,'protected_count':len(protected),'max_retrigger':max_retrigger,'sha256':hashes},indent=2),encoding='utf-8')
print('T5 evidence PASS',len(summary),total,checks)
