"""Focused retrigger verification; reuses a disposable imported project between checks."""
import argparse,json,os,re,shutil,subprocess,tempfile,time,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
GODOT=r'F:\Applications\Godot\Godot_v4.7-stable_win64_console.exe'
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--scratch');ap.add_argument('--timeout',type=float,default=180);ap.add_argument('--report-name',required=True);ap.add_argument('--visual',action='store_true');ap.add_argument('--audio-driver',default='Dummy');ap.add_argument('--tests',nargs='+',required=True);a=ap.parse_args()
 assert re.fullmatch('[a-z0-9_]+',a.report_name)
 out=ROOT/'project/reports'/a.report_name;out.mkdir(exist_ok=False)
 scratch=Path(a.scratch) if a.scratch else Path(tempfile.mkdtemp(prefix='facelessvoid_flurry_'))
 if not a.scratch:
  shutil.copytree(ROOT/'project',scratch/'project',ignore=shutil.ignore_patterns('reports','shader_cache','editor'),dirs_exist_ok=True)
 for folder in ['scripts','scenes','tests']:
  shutil.copytree(ROOT/'project'/folder,scratch/'project'/folder,dirs_exist_ok=True)
 rows=[]
 for name in a.tests:
  sub=scratch/'project/reports'/a.report_name/name;sub.mkdir(parents=True)
  resource='res://reports/'+a.report_name+'/'+name
  source=(ROOT/'project/tests'/(name+'.gd')).read_text(encoding='utf-8-sig')
  def rebase(m):
   dest=sub/m[1];(dest.parent if dest.suffix else dest).mkdir(parents=True,exist_ok=True)
   return '"'+resource+'/'+m[1]+'"'
  source=re.sub(r'"res://reports/([^"\n]+)"',rebase,source)
  (sub/'source.gd').write_text(source,encoding='utf-8')
  wrapper=f'extends "{resource}/source.gd"\nfunc _initialize() -> void:\n'
  wrapper+=f'\tprint("ISOLATED_USER_DATA_DIR=", OS.get_user_data_dir())\n\tSaveSystem.save_path = "{resource}/save.json"\n\tPracticeSaveSystem.save_path = "{resource}/practice.json"\n\tPracticeSaveSystem.core_save_path = "{resource}/core.json"\n\tsuper._initialize()\n'
  (sub/'isolated.gd').write_text(wrapper,encoding='utf-8')
  env=os.environ.copy()
  for key in ['APPDATA','LOCALAPPDATA']:
   env[key]=str(scratch/'userdata'/a.report_name/name/key);Path(env[key]).mkdir(parents=True,exist_ok=True)
  cmd=[GODOT,'--path',str(scratch/'project'),'--audio-driver',a.audio_driver,'--log-file',str(sub/'engine.log')]
  cmd+=['--rendering-method','gl_compatibility','--resolution','1280x720'] if a.visual else ['--headless']
  cmd+=['--script',resource+'/isolated.gd']
  if a.visual:cmd+=['--','--visual']
  startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
  start=time.monotonic()
  with (sub/'console.txt').open('w',encoding='utf-8') as log:
   proc=subprocess.Popen(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,startupinfo=startup)
   while proc.poll() is None:
    time.sleep(.2);text=(sub/'console.txt').read_text(errors='replace')
    if re.search(r'SCRIPT ERROR|Assertion failed|Parse Error|Compile Error',text) or time.monotonic()-start>a.timeout:
     # The Windows console binary launches a child; terminate this owned tree.
     subprocess.run(['taskkill','/PID',str(proc.pid),'/T','/F'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
     break
   proc.wait()
  text=(sub/'console.txt').read_text(errors='replace')
  passed=proc.returncode==0 and not re.search(r'SCRIPT ERROR|Assertion failed|Parse Error|Compile Error|FAILED',text) and bool(re.search(r'PASS|checks complete|: OK',text))
  user_dir=re.search(r'ISOLATED_USER_DATA_DIR=(.+)',text)
  rows.append({'user_data_dir':user_dir[1].strip() if user_dir else None,'test':name,'pass':passed,'exit_code':proc.returncode,'seconds':round(time.monotonic()-start,2),'command':cmd,'source_sha256':hashlib.sha256((ROOT/'project/tests'/(name+'.gd')).read_bytes()).hexdigest()})
  shutil.copytree(sub,out/name)
  print(('PASS ' if passed else 'FAIL ')+name,flush=True)
 (out/'summary.json').write_text(json.dumps(rows,indent=2),encoding='utf-8');(out/'workspace.json').write_text(json.dumps({'scratch':str(scratch),'isolated_user_data':True},indent=2),encoding='utf-8')
 return 0 if all(r['pass'] for r in rows) else 1
if __name__=='__main__':raise SystemExit(main())
