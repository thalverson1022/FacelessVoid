"""Run fresh isolated T10 journeys, optionally with rendered screenshot capture."""
import argparse,hashlib,json,os,re,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]

def fingerprint(paths):
 return {str(p):hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else None for p in paths}

def main():
 ap=argparse.ArgumentParser()
 ap.add_argument('--visual',action='store_true')
 ap.add_argument('--report-name',required=True)
 ap.add_argument('tests',nargs='+')
 args=ap.parse_args()
 assert re.fullmatch('[a-z0-9_]+',args.report_name)
 output=ROOT/'project/reports'/args.report_name
 output.mkdir(parents=True,exist_ok=True)
 protected=[Path(os.environ['APPDATA'])/'FacelessVoid'/n for n in ['save.json','practice_build.json','practice_bladedancer_core.json']]
 protected += [Path(os.environ['APPDATA'])/'Godot/app_userdata/Project Enigma'/n for n in ['save.json','practice_build.json']]
 protected += [ROOT.parent/'Project-Enigma/project'/n for n in ['project.godot','export_presets.cfg']]
 before=fingerprint(protected)
 results=[]
 for name in args.tests:
  assert re.fullmatch('[a-z0-9_]+_test',name)
  source=ROOT/'project/tests'/(name+'.gd')
  sub=output/name; sub.mkdir(exist_ok=True)
  resource='res://reports/'+args.report_name+'/'+name
  # Test-owned copies preserve prior acceptance artifacts; inherited helpers use report.
  text=source.read_text(encoding='utf-8')
  text,count=re.subn(r'(\breport\s*(?::=|=)\s*)"res://reports/[^"\n]+"',lambda m:m[1]+'"'+resource+'"',text)
  assert count>0, 'Journey must explicitly choose an isolated report: '+name
  script=sub/(name+'_isolated.gd'); script.write_text(text,encoding='utf-8')
  command=[r'F:\Applications\Godot\Godot_v4.7-stable_win64_console.exe','--path',str(ROOT/'project'),'--log-file',str(sub/'engine.log'),'--audio-driver','Dummy']
  command += ['--rendering-method','gl_compatibility','--resolution','1280x720'] if args.visual else ['--headless']
  command += ['--script',resource+'/'+script.name]
  if args.visual: command += ['--','--visual']
  try:
   run=subprocess.run(command,capture_output=True,text=True,timeout=240)
   log=run.stdout+run.stderr
   errors=[line for line in log.splitlines() if re.search('SCRIPT ERROR|Assertion failed|Parse Error|Compile Error|FAILED:',line)]
   checkfile=sub/('visual-checks.json' if args.visual else 'checks.json')
   detail=json.loads(checkfile.read_text(encoding='utf-8')) if checkfile.exists() else {}
   passed=run.returncode==0 and not errors and detail.get('passed',False)
   result={'test':name,'visual':args.visual,'pass':passed,'exit_code':run.returncode,'checks':detail.get('count'), 'errors':errors,'command':command,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'report':str(checkfile.relative_to(ROOT))}
  except subprocess.TimeoutExpired as ex:
   log=''.join(x.decode(errors='replace') if isinstance(x,bytes) else x or '' for x in [ex.stdout,ex.stderr])
   result={'test':name,'pass':False,'errors':['Timeout'],'command':command}
  (sub/'console.txt').write_text(log,encoding='utf-8')
  results.append(result)
  print(('PASS ' if result['pass'] else 'FAIL ')+name,flush=True)
  if not result['pass']: print('\n'.join(result['errors']),flush=True)
  (output/'summary.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
 after=fingerprint(protected)
 (output/'isolation.json').write_text(json.dumps({'unchanged':before==after,'before':before,'after':after},indent=2),encoding='utf-8')
 return 0 if before==after and all(x['pass'] for x in results) else 1
if __name__=='__main__': sys.exit(main())
