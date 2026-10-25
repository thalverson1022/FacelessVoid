import pathlib,json,hashlib,collections,sys,math,argparse
base=pathlib.Path(__file__).resolve().parent
parser=argparse.ArgumentParser()
parser.add_argument('--report',type=pathlib.Path,default=base.parents[1]/'project/reports/p6_m6_t6')
parser.add_argument('--manifest',type=pathlib.Path,default=base.parents[1]/'project/reports/p6_m6_t6/protected_before.json')
args=parser.parse_args()
p=args.report
checks=0
def require(ok,msg):
    global checks
    checks+=1
    if not ok: raise AssertionError(msg)
inventory=json.loads((p/'encounters.json').read_text())
require(len(inventory['graphs'])==70,'70 route-stage graphs')
require(len({g['template'] for g in inventory['graphs']})==6,'six templates')
require(len(inventory['encounters'])==555,'550 generated nodes plus Tavern and Watchmen')
for e in inventory['encounters']:
    if 'payload' not in e: continue
    g=next(g for g in inventory['graphs'] if g['stage']==e['checkpoint'] and g['seed']==e['route_seed'])
    require(e['mandatory']==all(e['node'] in path for path in g['paths']),'graph-based mandatory classification')
totals=collections.Counter(); logs=[]
cohorts={'screen':(100001,12),'trial':(101001,20),'focused':(104001,40),'path':(103001,20),'confirm':(105001,100),'thief':(106001,100)}
for f in p.glob('*.json'):
    kind=f.stem.split('_')[0]
    if kind not in cohorts or f.stem.endswith('_plan'): continue
    d=json.loads(f.read_text())
    require(d.get('complete') is True,f.name+' complete')
    for r in d['rows']:
        start,count=cohorts[kind]
        require(r['count']==count and len(r['samples'])==count,f.name+' count')
        require([s['root'] for s in r['samples']]==list(range(start,start+count)),f.name+' cohort')
        wins=both=0; damage=0
        for s in r['samples']:
            require(s['win']==(s['damage']>=r['enemy']['hp']),'win matches HP')
            require(s['within_two']==(s['win'] or s['retry_damage']>=r['enemy']['hp']),'actual retry accounting')
            wins+=s['win']; both+=s['within_two']; damage+=s['damage']
            totals['retries']+=s['retry_damage']>=0
        require(wins==r['wins'] and both==r['within_two'],'counts derived from samples')
        require(math.isclose(damage/count,r['mean_damage'],abs_tol=1e-7),'mean damage')
        require(math.isclose(damage/count/r['enemy']['hp']-1,r['mean_margin'],abs_tol=1e-7),'mean margin')
        if kind in ['trial','focused','confirm']:
            # Candidate effects may only touch the fields named in the recorded arm.
            a=r['parameters']; allowed=set(a.get('caps',{}))|set(a.get('minimums',{}))|set(a.get('set',{}))
            if 'hp_multiplier' in a or a.get('remove_duration_floor'): allowed.add('hp')
            for field,value in r['baseline_enemy'].items():
                if field not in allowed: require(r['enemy'][field]==value,'isolated candidate field '+field)
        totals[kind+'_rows']+=1; totals['first_attempts']+=count
for name in ['screen_bladedancer','screen_thief','screen_assassin','screen_shadow']:
    require((p/(name+'.json')).exists(),'required screen')
for tree in ['bladedancer','thief','assassin','shadow']:
    for history in [84001,84002,84003]:
        for phase in ['fixtures','trial','path']:
            d=json.loads((p/f'{phase}_{tree}_{history}.json').read_text())
            require(d.get('complete') is True,'complete '+phase+' '+tree)
parity=json.loads((p/'parity_and_watchmen.json').read_text())
require(parity['complete'] and len(parity['parity'])>=40,'Replay and Practice coverage')
require(all(x['replay'] and x['practice'] for x in parity['parity']),'parity passes')
regressions=json.loads((p/'regressions.json').read_text())
require(len(regressions)==5 and all(r['pass'] for r in regressions),'five verification runs')
protected=json.loads(args.manifest.read_text())
for name,digest in protected.items(): require(hashlib.sha256(pathlib.Path(name).read_bytes()).hexdigest()==digest,'source unchanged '+name)
out={'complete':True,'checks':checks,'counts':dict(totals),'protected_files_unchanged':len(protected),'scope':'Recorded samples, graph roles, allowed candidate mutations and original source fingerprints; not full-run balance acceptance.'}
(p/'verification.json').write_text(json.dumps(out,indent=2))
print(json.dumps(out,indent=2))
