"""Summarize fixed earned paths without imputing unreachable checkpoints."""
import argparse,csv,json,statistics,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
SLOTS=['Weapon','Trinket','Charm','Helm','Armor','Pants','Gloves']
def item_data(item):
 if 'slot' in item:return item
 source=ROOT/'project'/item['resource_path'].removeprefix('res://')
 text=source.read_text(encoding='utf-8-sig')
 data=dict(item)
 for name,default in [('slot',0),('tier',0)]:
  match=re.search(r'^'+name+r' = (\d+)',text,re.M);data[name]=int(match[1])if match else default
 match=re.search(r'^id = "([^"]+)"',text,re.M);data['id']=match[1]if match else item['resource_path']
 return data
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--name',default='earned_v1');a=ap.parse_args();out=ROOT/'project/reports/m9_t10'/a.name
 runs=[];checkpoints=[];slotrows=[];pairs=[]
 for path in sorted(out.glob('*_*.json')):
  if path.name in ['source_audit.json','import_status.json']:continue
  d=json.loads(path.read_text(encoding='utf-8-sig'))
  if not isinstance(d,dict) or 'fights' not in d or not d['fights']:continue
  events=d['events'];fights=d['fights']
  for event in events:
   if 'item'in event:event['item']=item_data(event['item'])
  for fight in fights:
   if fight['candidates_total']>0 and not fight.get('budget_event_kind_maxima'):fight['max_root_budget_consumed']=None
  base={k:d[k]for k in ['arm','build','seed']}
  econ={action:sum(e['delta']for e in events if e['action']==action)for action in ['reward','theft','buy','sale','reroll','equip','choose_reward']}
  run={**base,'completed_contracts':d['completed_contracts'],'stop':d['last_stage'],'reason':d['stop_reason'],'fights':len(fights),'wins':sum(f['win']for f in fights),'gold':d['gold'],'earned_points':d['earned_points'],'purchases':sum(e['action']=='buy'for e in events),'sales':sum(e['action']=='sale'for e in events),'rerolls':sum(e['action']=='reroll'for e in events),'ending_equipped':len(d['checkpoints'][-1]['gear']),'validity_failures':d['validity_failures'],'all_seed_replays_equal':all(f['seed_replay_equal']for f in fights),'max_fight_candidate_total_upper_bound':max((f['candidates_total']for f in fights),default=0),'max_depth':max((f['max_depth']for f in fights),default=0),'max_root_budget_consumed':None if any(f.get('max_root_budget_consumed')is None and f['candidates_total']>0 for f in fights)else max((f.get('max_root_budget_consumed',0)for f in fights),default=0),'currency_deltas':econ,'currency_reconciles':sum(econ.values())==d['gold'],'overkill_gold':sum(e.get('overkill_gold',0)for e in events if e['action']=='reward'),'starting_gear':[x['id']for x in fights[0]['gear']],'ending_run_phase':d.get('ending_run_phase'),'ending_run_outcome':d.get('ending_run_outcome'),'can_retry_at_stop':d.get('can_retry_at_stop')}
  runs.append(run)
  has_snapshots=any('equipment_changes'in e for e in events)
  for slot,name in enumerate(SLOTS):
   offered=[e for e in events if e['action']in ['shop_offer','reward_offer']and e['item']['slot']==slot]
   equips=[e for e in events if e['action']=='equip'and e['item']['slot']==slot]
   if has_snapshots:
    equips=[{**e,'first_fill':change['first_fill'],'item':item_data(change['after'])}for e in events for change in e.get('equipment_changes',[])if change['slot']==slot]
   initial=any(item_data(item)['slot']==slot for item in fights[0]['gear'])
   first={'reward_opportunity':0,'fight_opportunity':0,'stage':'start'}if initial else next((e for e in equips if e['first_fill']),None)
   slotrows.append({**base,'slot':name,'offers_seen':len(offered),'equip_events':len(equips),'replacement_events':sum(not e['first_fill']for e in equips),'first_offer_reward_opportunity':offered[0]['reward_opportunity']if offered else None,'first_fill_reward_opportunity':first['reward_opportunity']if first else None,'first_fill_fight_opportunity':first['fight_opportunity']if first else None,'first_fill_stage':first['stage']if first else None,'last_replacement_reward_opportunity':equips[-1]['reward_opportunity']if equips else None,'replacement_intervals_rewards':[equips[i]['reward_opportunity']-equips[i-1]['reward_opportunity']for i in range(1,len(equips))],'equipment_changes_complete':has_snapshots})
  for cp in d['checkpoints']:
   if cp['label']=='final':continue
   # terminal fight before claim: fixed input DPS, no future enemy selection.
   relevant=[f for f in fights[:cp['fight_opportunity']]if f['win']]
   f=relevant[-1]
   before_cp=[e for e in events if e['reward_opportunity']<=cp['reward_opportunity']]
   cp_economy={action:sum(e['delta']for e in before_cp if e['action']==action)for action in ['reward','theft','buy','sale','reroll','equip','choose_reward']}
   checkpoints.append({**base,'checkpoint':cp['label'],'cumulative_currency_deltas':cp_economy,'cumulative_purchases':sum(e['action']=='buy'for e in before_cp),'cumulative_sales':sum(e['action']=='sale'for e in before_cp),'cumulative_rerolls':sum(e['action']=='reroll'for e in before_cp),'fight_opportunity':cp['fight_opportunity'],'reward_opportunity':cp['reward_opportunity'],'gold_after_preparation':cp['gold'],'earned_points':cp['points'],'equipped_count':len(cp['gear']),'damage':f['damage'],'health_removed':f['health_removed'],'dps':f['dps'],'required_dps':f['required_dps'],'margin':f['margin'],'elapsed_ms':f['elapsed_ms'],'nominal_ms':f['nominal_ms'],'fight_candidate_total_upper_bound':f['candidates_total'],'max_depth':f['max_depth'],'max_root_budget_consumed':f.get('max_root_budget_consumed'),'poison_tick_damage_share':f.get('poison_tick_damage_share'),'new_slot_marginals':f.get('new_slot_marginals',{})})
 for build in ['bladedancer','assassin']:
  for seed in [101,307]:
   paired=[r for r in runs if r['build']==build and r['seed']==seed]
   pairs.append({'build':build,'seed':seed,'arms':paired,'interpretation':'Paired seed and fixed policy, not identical draws; historical Basic weights, catalog and runtime revision differ; both start with Crude Dagger.'})
 summary={'runs':runs,'checkpoints':checkpoints,'slot_timing':slotrows,'pairs':pairs,'method':{'route':'first offered contract/default plus first connected route node; no future encounter oracle','rank':'fixed legal primary priority, then first earned offered secondary and tree resource order; never refund','combat':'fixed ordered macro filtered to unlocked skills, same actual seed replay','gear':'one fixed seed701 same current enemy immediate health-loss score; carried economy supplied; no rotation search; strict positive improvement only','shop':'Normal UI skips final Tavern reward shop; one pass through six offers, one reroll if reserve >=18 after reroll; one pass rerolled offers; no buying for resale','retry':'maximum two attempts per encounter including Tavern; cap is probe stop, not game terminal proof','horizon':'earned C13 maximum; unreachable checkpoints omitted','comparison':'Current seven versus actual accepted historical D097 five; bundled version comparison, cannot isolate slots from D008 weights/new roster; both start Crude Dagger','isolation':'disposable source copies; APPDATA and LOCALAPPDATA; Adventure/Practice/core explicit save paths, plus legacy and epoch paths for current only','technical':'Godot4.7 headless; import certificate/theme/leak messages retained; no engine/export claim'}}
 (out/'analysis.json').write_text(json.dumps(summary,indent=2))
 for name,rows in [('runs',runs),('checkpoints',checkpoints),('slot_timing',slotrows)]:
  if not rows:continue
  with (out/f'{name}.csv').open('w',newline='',encoding='utf-8')as f:
   writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
 print(json.dumps(runs,indent=2))
if __name__=='__main__':main()





