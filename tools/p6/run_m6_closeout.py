"""M6 retained-baseline regression in a disposable project and isolated user data."""
import argparse, hashlib, json, os, re, shutil, subprocess, sys, tempfile, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
ROOT=Path(__file__).resolve().parents[2]
GODOT=r'F:\Applications\Godot\Godot_v4.7-stable_win64_console.exe'
def hashes():
    files=[p for d in ('scripts','scenes','data','tests') for p in (ROOT/'project'/d).rglob('*') if p.is_file()]
    files += [ROOT/'project/project.godot',ROOT/'project/export_presets.cfg']
    return {p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--report-name',default='p6_m6_t11');ap.add_argument('--tests',nargs='*');ap.add_argument('--visual',action='store_true');args=ap.parse_args()
    assert re.fullmatch('[a-z0-9_]+',args.report_name)
    out=ROOT/'project/reports'/args.report_name;out.mkdir()
    scratch=Path(tempfile.mkdtemp(prefix='facelessvoid_m6_t11_'));before=hashes()
    (out/'baseline.json').write_text(json.dumps(before,indent=2))
    (out/'workspace.json').write_text(json.dumps({'scratch':str(scratch),'git_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()},indent=2))
    (out/'git_status_before.txt').write_text(subprocess.check_output(['git','status','--short'],cwd=ROOT,text=True),encoding='utf-8')
    print('Copying baseline to '+str(scratch),flush=True)
    for d in ('project','tools','docs'):shutil.copytree(ROOT/d,scratch/d,ignore=shutil.ignore_patterns(args.report_name,'shader_cache','editor','__pycache__'))
    plan=json.loads((ROOT/'tools/p6/m5_closeout_suites.json').read_text())
    tests=args.tests if args.tests is not None else plan['runtime_suites']+plan['journeys']+['p6_m6_adventure_integration_test','p6_m6_adventure_ui_test','p6_test_mode_tree_selection_test','map_overlay_route_preview_test']
    (out/'roster.json').write_text(json.dumps(tests,indent=2))
    def run(name):
        start=time.monotonic();sub=scratch/'project/reports'/args.report_name/name;sub.mkdir(parents=True)
        resource='res://reports/'+args.report_name+'/'+name;original=ROOT/'project/tests'/(name+'.gd');source=original.read_text(encoding='utf-8-sig')
        def rebase(m):
            target=sub/m[1];(target.parent if target.suffix else target).mkdir(parents=True,exist_ok=True)
            return '"'+resource+'/'+m[1]+'"'
        source=re.sub(r'"res://reports/([^"\n]+)"',rebase,source);(sub/'source.gd').write_text(source,encoding='utf-8')
        wrapper=f'extends "{resource}/source.gd"\nfunc _initialize() -> void:\n'
        wrapper+=f'\tSaveSystem.save_path = "{resource}/save.json"\n\tPracticeSaveSystem.save_path = "{resource}/practice.json"\n\tPracticeSaveSystem.core_save_path = "{resource}/core.json"\n'
        if 'func _initialize(' in source:wrapper+='\tsuper._initialize()\n'
        (sub/'isolated.gd').write_text(wrapper,encoding='utf-8');env=os.environ.copy()
        for key in ('APPDATA','LOCALAPPDATA'):env[key]=str(scratch/'userdata'/name/key);Path(env[key]).mkdir(parents=True)
        cmd=[GODOT,'--path',str(scratch/'project'),'--audio-driver','Dummy','--log-file',str(sub/'engine.log')]
        cmd+=['--rendering-method','gl_compatibility','--resolution','1280x720'] if args.visual else ['--headless']
        cmd+=['--script',resource+'/isolated.gd']
        if args.visual:cmd+=['--','--visual']
        startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
        console=sub/'console.txt';stopped=None
        with console.open('w',encoding='utf-8') as log:
            process=subprocess.Popen(cmd,env=env,cwd=scratch,stdout=log,stderr=subprocess.STDOUT,startupinfo=startup)
            while process.poll() is None:
                time.sleep(.5);text=console.read_text(encoding='utf-8',errors='replace')
                if re.search(r'SCRIPT ERROR|Assertion failed|Parse Error|Compile Error',text):stopped='Script/assertion error';process.kill();break
                if time.monotonic()-start>900:stopped='Timeout';process.kill();break
            process.wait()
        text=console.read_text(encoding='utf-8',errors='replace');errors=[line for line in text.splitlines() if re.search(r'SCRIPT ERROR|Assertion failed|Parse Error|Compile Error|\bFAIL(?:ED)?\b',line)]
        markers={'p6_assassin_balance_live_test':r'Live Assassin 200-seed mean DPS: [0-9.]+','p6_combat_presentation_test':r'T7 presentation checks complete','p6_full_bladedancer_test':r'M5 full Bladedancer checks: [0-9]+'}
        success=bool(re.search(markers.get(name,r'\b(?:PASS|PASSED|OK)\b'),text,re.I))
        if name=='p6_shadow_balance_test':
            detail=json.loads((sub/'balance/shadow_d012/summary.json').read_text())
            success=detail.get('passed') is True and len(detail.get('cohorts',[]))==11
        row={'test':name,'pass':process.returncode==0 and not errors and success,'exit_code':process.returncode,'errors':errors,'stopped':stopped,'success_marker':success,'seconds':round(time.monotonic()-start,2),'visual':args.visual,'source_sha256':hashlib.sha256(original.read_bytes()).hexdigest(),'command':cmd}
        shutil.copytree(sub,out/name);print(('PASS ' if row['pass'] else 'FAIL ')+name,flush=True);return row
    results=[]
    with ThreadPoolExecutor(max_workers=1 if args.visual else 4) as pool:
        for future in as_completed([pool.submit(run,name) for name in tests]):results.append(future.result());(out/'summary.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    after=hashes();(out/'isolation.json').write_text(json.dumps({'unchanged':before==after,'changed':[p for p in before if before[p]!=after.get(p)],'user_data':'Per-suite APPDATA and LOCALAPPDATA under scratch; no real player save paths used.'},indent=2))
    return 0 if before==after and all(r['pass'] for r in results) else 1
if __name__=='__main__':sys.exit(main())
