from pathlib import Path
import json, hashlib, collections, statistics, subprocess, os, sys
work=Path(__file__).resolve().parent
folder=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[2]/'project/reports/p6_m6_t7/final'
data=[json.loads(p.read_text()) for p in sorted(folder.glob('*.json'))]
checks=0
def check(ok,msg):
    global checks
    checks+=1
    assert ok,msg
if folder.name=='final': check(len(data)==128,'complete final cohort')
for r in data:
    check(r['complete'],'completed accepted report')
    balance=0
    for e in r['events']:
        check(e['before']==balance,'continuous ledger')
        check(e['after']-e['before']==e['delta'],'ledger delta')
        balance=e['after']
        check(balance>=0,'nonnegative')
        if e['action'] in ['buy','reroll']: check(e['delta']==-e['price'],'spending')
        if e['action']=='sale': check(e['delta']==e['price'],'sale')
        if e['action']=='theft': check(e['delta']==e['amount'],'theft')
        if e['action']=='reward': check(e['delta']==e['amount'],'reward')
    check(balance==r['ending_gold'],'ending ledger')
    rewards=[e for e in r['events'] if e['action']=='reward']
    check(len(rewards)==sum(f['win'] for f in r['fights']),'one reward per victory')
    check(len([e for e in r['events'] if e['action']=='theft'])==len(r['fights']),'one theft event per attempt')
    check(r['survived']==(r['completed_contracts']==r['horizon']),'stop at failure or horizon')
    previous=None
    for f in r['fights']:
        check(f['win']==(f['damage']>=f['enemy']['hp']),'outcome')
        check(sum(f['ranks'].values())==f['points'],'spent budget')
        check(f['raw_overkill_gold']==(min(50,int(f['overkill']//100)*10) if f['win'] else 0),'overkill')
        if f['stage'].startswith('C'): check(f['points']==min(45,6+3*(int(f['stage'][1:])-1)),'stage budget')
        if f['attempt']:
            check(previous is not None and previous['key']==f['key'] and not previous['win'],'retry only loss')
            check(f['gold']==previous['gold']+previous['theft'],'retry gold retention')
            check(f['gear']==previous['gear'] and f['ranks']==previous['ranks'],'no retry gear or respec')
        previous=f
    if r['policy']=='weak': check(not any(e['action'] in ['buy','reroll'] for e in r['events']),'no weak spending')
summary=[]
for tree in ['bladedancer','thief','assassin','shadow']:
    for policy in ['weak','typical','strong']:
        group=[r for r in data if r['primary']==tree and r['policy']==policy and 84001<=r['seed']<=84008]
        if not group: continue
        fs=[f for r in group for f in r['fights']]
        summary.append(dict(tree=tree,policy=policy,n=len(group),cleared_C1=sum(r['completed_contracts']>=1 for r in group),cleared_C10=sum(r['completed_contracts']>=10 for r in group),cleared_C20=sum(r['completed_contracts']>=20 for r in group),median_contracts=statistics.median(r['completed_contracts'] for r in group),failures=dict(collections.Counter(r['last_stage'] for r in group if not r['survived'])),median_gold=statistics.median(r['ending_gold'] for r in group),theft=sum(f['theft'] for f in fs),raw_overkill=sum(f['raw_overkill_gold'] for f in fs),purchases=sum(e['action']=='buy' for r in group for e in r['events']),rerolls=sum(e['action']=='reroll' for r in group for e in r['events'])))
out=dict(runs=len(data),attempts=sum(len(r['fights']) for r in data),wins=sum(f['win'] for r in data for f in r['fights']),retries=sum(f['attempt']>0 for r in data for f in r['fights']),checks=checks,summary=summary)
if len(data)==128:
    check(len({(r['primary'],r['secondary'],r['policy'],r['seed']) for r in data})==128,'unique runs')
    check(len({(r['primary'],r['secondary']) for r in data})==12,'all ordered role pairs')
    for tree in ['bladedancer','thief','assassin','shadow']:
        for policy in ['weak','typical','strong']:
            check(sum(r['primary']==tree and r['policy']==policy and 84001<=r['seed']<=84008 for r in data)==8,'matched cohort')
    check(sum(94001<=r['seed']<=94004 for r in data)==32,'additional pair cohort')
    controls=list((folder.parent/'shadow_armor160').glob('*.json'))
    check(len(controls)==8,'eight armor controls')
    for p in controls:
        c=json.loads(p.read_text())
        check(c['complete'],'completed control')
        check(all(f['enemy']['armor']==160 for f in c['fights'] if f['stage']=='T1'),'old armor applied')
        check(all(f['enemy']['armor']==140 for f in json.loads((folder/p.name).read_text())['fights'] if f['stage']=='T1'),'approved armor applied')
    for p in (folder.parent/'replay').glob('*.json'):
        check(json.loads(p.read_text())==json.loads((folder/p.name).read_text()),'exact full-run replay')
    out['checks']=checks
(folder.parent/('summary.json' if folder.name=='final' else folder.name+'_summary.json')).write_text(json.dumps(out,indent=2))
print(json.dumps(out,indent=2))
