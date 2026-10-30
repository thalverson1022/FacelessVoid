"""Run 8 fixed-policy earned Adventures in disposable source copies."""
import argparse, hashlib, json, os, re, shutil, subprocess, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
GODOT=Path(r'F:\Applications\Godot\Godot_v4.7-stable_win64_console.exe')
SOURCES={'seven_current':ROOT/'project','five_accepted_d097':ROOT/'work/m8_t9_presentation/crown_meditation_d097/project'}
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def run(cmd,env,log,timeout):
 startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
 start=time.monotonic()
 with log.open('w',encoding='utf-8') as stream:
  proc=subprocess.Popen(cmd,env=env,stdout=stream,stderr=subprocess.STDOUT,startupinfo=startup)
  while proc.poll() is None:
   time.sleep(.2)
   text=log.read_text(errors='replace')
   if re.search(r'SCRIPT ERROR|Parse Error|Compile Error',text) or time.monotonic()-start>timeout:
    subprocess.run(['taskkill','/PID',str(proc.pid),'/T','/F'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    break
  proc.wait()
 return {'log_has_script_error':bool(re.search(r'SCRIPT ERROR|Parse Error|Compile Error',log.read_text(errors='replace'))),'exit_code':proc.returncode,'seconds':round(time.monotonic()-start,3),'command':cmd}
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--name',default='earned_v1');ap.add_argument('--arms',nargs='+',default=list(SOURCES));ap.add_argument('--builds',nargs='+',default=['bladedancer','assassin']);ap.add_argument('--seeds',nargs='+',type=int,default=[101,307]);ap.add_argument('--variant',default='fixed');a=ap.parse_args()
 assert re.fullmatch('[a-z0-9_]+',a.name)
 base=ROOT/'work/m9_t10'/a.name;base.mkdir(parents=True,exist_ok=True)
 output=ROOT/'project/reports/m9_t10'/a.name;output.mkdir(parents=True,exist_ok=True)
 harness=ROOT/'project/tests/m9_t10_progression_probe.gd';rows=[];source_audit={}
 for arm in a.arms:
  source=SOURCES[arm];copy=base/arm/'project'
  if not copy.exists(): shutil.copytree(source,copy,ignore=shutil.ignore_patterns('.godot','reports','prototype_saves','shader_cache','editor'))
  target=copy/'tests/m9_t10_progression_probe.gd';target.write_bytes(harness.read_bytes())
  sub=copy/'reports/m9_t10_probe';sub.mkdir(parents=True,exist_ok=True)
  wrapper='extends "res://tests/m9_t10_progression_probe.gd"\nfunc _initialize() -> void:\n'
  for name,path in [('SaveSystem.save_path','adventure.json'),('PracticeSaveSystem.save_path','practice.json'),('PracticeSaveSystem.core_save_path','core.json')]: wrapper+=f' {name} = "res://reports/m9_t10_probe/{path}"\n'
  if (copy/'scripts/systems/seven_slot_save_boundary.gd').exists():
   wrapper+=' SevenSlotSaveBoundary.legacy_path = "res://reports/m9_t10_probe/legacy.json"\n SevenSlotSaveBoundary.marker_path = "res://reports/m9_t10_probe/epoch.json"\n'
  wrapper+=' print("ISOLATED_USER_DATA_DIR=", OS.get_user_data_dir())\n super._initialize()\n'
  (copy/'tests/m9_t10_isolated.gd').write_text(wrapper,encoding='utf-8')
  source_audit[arm]={'source':str(source),'hashes':{str(p.relative_to(source)):sha(p) for folder in ['scripts','data','scenes'] for p in (source/folder).rglob('*') if p.is_file() and p.suffix in ['.gd','.tres','.tscn','.json']},'control':'Unmodified historical D097 gameplay with original unequal Basic weights' if arm.startswith('five') else 'Current seven-slot gameplay with D008 equal Basic weights'}
  env=os.environ.copy()
  for key in ['APPDATA','LOCALAPPDATA']:
   folder=base/arm/'userdata'/key;folder.mkdir(parents=True,exist_ok=True);env[key]=str(folder)
  imported=run([str(GODOT),'--headless','--path',str(copy),'--editor','--import'],env,output/f'{arm}_import.log',120)
  (output/'import_status.json').write_text(json.dumps(imported,indent=2))
  for build in a.builds:
   for seed in a.seeds:
    tag=f'{arm}_{build}_{seed}'
    result=run([str(GODOT),'--headless','--path',str(copy),'--audio-driver','Dummy','--script','res://tests/m9_t10_isolated.gd','--',f'--arm={arm}',f'--build={build}',f'--seed={seed}',f'--variant={a.variant}'],env,output/f'{tag}.log',90)
    raw=sub/f'{tag}.json'
    result.update({'arm':arm,'build':build,'seed':seed,'source_sha256':sha(harness),'complete':raw.exists(),'isolated_copy':str(copy)})
    if raw.exists():
     shutil.copy2(raw,output/raw.name)
     data=json.loads(raw.read_text(encoding='utf-8-sig'));result.update({key:data[key] for key in ['stop_reason','completed_contracts','last_stage','gold','earned_points','validity_failures']})
    rows.append(result);print(json.dumps(result),flush=True)
    (output/'summary.json').write_text(json.dumps(rows,indent=2))
    if result['exit_code']!=0 or result['log_has_script_error']: break
   if rows[-1]['exit_code']!=0 or rows[-1]['log_has_script_error']: break
  if rows[-1]['exit_code']!=0 or rows[-1]['log_has_script_error']: break
 (output/'source_audit.json').write_text(json.dumps(source_audit,indent=2))
 return 0 if rows and all(x['exit_code']==0 and not x['log_has_script_error'] and x['complete'] for x in rows) else 1
if __name__=='__main__': raise SystemExit(main())

