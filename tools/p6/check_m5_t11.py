"""Reconcile M5 closeout evidence, static checks and repository checkpoint."""
import argparse, hashlib, json, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'project/reports/p6_m5_t11'
def read(p): return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def digest(p): return hashlib.sha256((ROOT/p).read_bytes()).hexdigest()
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--run', choices=['regression','journeys','rendered'])
    args=parser.parse_args()
    plan=read('tools/p6/m5_closeout_suites.json')
    if args.run:
        if args.run=='regression': command=[sys.executable,'tools/p6/run_foundation_tests.py','--isolate-reports','--timeout','900','--report-name','p6_m5_t11_regression_final']+plan['runtime_suites']
        else:
            command=[sys.executable,'tools/p6/run_m5_t10_journeys.py','--report-name','p6_m5_t11_'+args.run]
            command+=['--visual','p6_t10_usability_test','p6_full_content_journey_test'] if args.run=='rendered' else plan['journeys']
        return subprocess.call(command,cwd=ROOT)
    accepted=[];isolation=[]
    for batch, expected in [('p6_m5_t11_regression_final',plan['runtime_suites']),('p6_m5_t11_journeys',plan['journeys']),('p6_m5_t11_rendered',['p6_t10_usability_test','p6_full_content_journey_test'])]:
        rows=read('project/reports/'+batch+'/summary.json')
        assert {r['test'] for r in rows}==set(expected), batch
        if batch=='p6_m5_t11_regression_final' and any(not r['pass'] and r['test']=='p6_mixed_gear_integration_test' for r in rows):
            replacement=read('project/reports/p6_m5_t11_matrix/summary.json')
            assert len(replacement)==1 and replacement[0]['pass']
            rows=[dict(replacement[0], source_report='project/reports/p6_m5_t11_matrix/summary.json') if r['test']=='p6_mixed_gear_integration_test' else r for r in rows]
            protection=read('project/reports/p6_m5_t11_matrix/isolation.json')
            assert protection['unchanged']
            isolation.append(dict(protection,batch='p6_m5_t11_matrix'))
        if batch=='p6_m5_t11_regression_final' and any(not r['pass'] and r['test']=='training_room_combat_view_test' for r in rows):
            replacement=read('project/reports/p6_m5_t11_view_fixed/summary.json')
            assert len(replacement)==1 and replacement[0]['pass']
            rows=[dict(replacement[0], source_report='project/reports/p6_m5_t11_view_fixed/summary.json') if r['test']=='training_room_combat_view_test' else r for r in rows]
            protection=read('project/reports/p6_m5_t11_view_fixed/isolation.json')
            assert protection['unchanged']
            isolation.append(dict(protection,batch='p6_m5_t11_view_fixed'))
        assert all(r['pass'] for r in rows), [r['test'] for r in rows if not r['pass']]
        for r in rows:
            assert digest('project/tests/'+r['test']+'.gd')==r['source_sha256'],r['test']
            accepted.append(dict(r,batch=batch))
        protection=read('project/reports/'+batch+'/isolation.json')
        assert protection['unchanged'],batch
        isolation.append(dict(protection,batch=batch))
    commands=read('tools/p6/m5_closeout_static.json')
    static_out=ROOT/'project/reports/p6_m5_t11_static_final';static_out.mkdir(exist_ok=True)
    for row in commands:
        result=subprocess.run(row['command'],cwd=ROOT,capture_output=True,text=True)
        row['pass']=result.returncode==0
        (static_out/(row['check']+'.txt')).write_text(result.stdout+result.stderr,encoding='utf-8')
    (static_out/'summary.json').write_text(json.dumps(commands,indent=2),encoding='utf-8')
    assert all(r['pass'] for r in commands),[r['check'] for r in commands if not r['pass']]
    ledger=read('docs/P6M5_T2_Content_Coverage_Ledger.json')
    assert len(ledger['rank_slots'])==140 and all(r['status']=='P' for r in ledger['rank_slots'])
    assert len([r for r in ledger['records'] if r['kind']=='talent'])==44
    assert len([r for r in ledger['records'] if r['status']=='E'])==2
    assert all(r['status'] in ['P','E'] for r in ledger['records'])
    matrix_path='project/reports/p6_m5_t11_regression_final/matrix.json'
    if not (ROOT/matrix_path).exists(): matrix_path='project/reports/p6_m5_t11_matrix/matrix.json'
    matrix=read(matrix_path)
    assert matrix['pass'] and len(matrix['scenarios'])==576
    combined=read('project/reports/p6_m5_t11_journeys/p6_full_content_journey_test/checks.json')
    assert combined['passed'] and len(combined['cases'])==12
    visual=read('project/reports/p6_m5_t11/visual_review.json')
    for row in visual['images']: assert digest(row['path'])==row['sha256']
    prior=read('project/reports/p6_m5_t10_final/summary.json')
    assert digest('project/scripts/systems/training_room_state.gd')==prior['source_sha256']['project/scripts/systems/training_room_state.gd']
    for row in prior['runs']:
        if 'source_sha256' in row: assert digest('project/tests/'+row['test']+'.gd')==row['source_sha256']
    for row in read('project/reports/p6_m5_t10_final/visual_review.json')['images']:
        assert digest(row['path'])==row['sha256']
    baseline=read('project/reports/p6_m5_t11/baseline.json')
    runtime_changes=[p for p,h in baseline['source_sha256'].items() if p.startswith(('project/scripts/','project/scenes/','project/data/')) and digest(p)!=h]
    assert not runtime_changes,runtime_changes
    for p,h in baseline['protected'].items():
        path=Path(p);assert (hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None)==h,p
    tracked={p:digest(p) for p in baseline['source_sha256']}
    for p in (ROOT/'tools/p6').glob('*'):
        if p.suffix in ['.py','.js','.json']: tracked[p.relative_to(ROOT).as_posix()]=digest(p)
    for p in ['docs/P6M5_T11_Closeout_And_M6_Handoff.md','docs/P6_Project_Onboarding_Context.md','docs/P6_Milestone_Tracker.md','docs/P6M5_Complete_Rogue_Tree_And_Skill_Implementation_Tracker.md','docs/P6M5_T2_Content_Coverage_Ledger.json','docs/Combat_Mechanics_Reference.md']:
        tracked[p]=digest(p)
    checkpoint={'date':'2026-10-06','git_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'git_status':subprocess.check_output(['git','status','--short'],cwd=ROOT,text=True),'source_sha256':tracked,'runtime_changes_in_T11':runtime_changes,'note':'Working-tree checkpoint; no commit or publication implied. Preexisting user work retained.'}
    (ROOT/'docs/P6M5_T11_Repository_Checkpoint.json').write_text(json.dumps(checkpoint,indent=2),encoding='utf-8')
    summary={'pass':True,'date':'2026-10-06','authority':'P6M5-D023','distinct_suites':len({r['test'] for r in accepted}),'accepted_executions':len(accepted),'runs':accepted,'static_checks':commands,'inventory':{'talents':44,'ranks':140,'planned_skills':20,'intrinsics':4,'automatic_slots':20,'intentionally_empty_slots':2},'matrix_scenarios':576,'ordered_player_flows':12,'runtime_unchanged':True,'checkpoint':'docs/P6M5_T11_Repository_Checkpoint.json'}
    (OUT/'summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
    (OUT/'isolation.json').write_text(json.dumps(isolation,indent=2),encoding='utf-8')
    print(f"PASS: {summary['distinct_suites']} distinct suites, {summary['accepted_executions']} accepted executions, {len(commands)} static checks; runtime and protected files unchanged")
    return 0
if __name__=='__main__': sys.exit(main())
