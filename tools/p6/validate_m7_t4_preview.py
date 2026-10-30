"""Validate T4 candidates only in the existing isolated visual-test checkout."""
from pathlib import Path
import json,hashlib,os,subprocess,shutil,tempfile
ROOT=Path(__file__).resolve().parents[2]
GODOT=r'F:\Applications\Godot\Godot_v4.7-stable_win64_console.exe'
def main():
 evidence=ROOT/'project/reports/p6_m7_t4_candidate_visual';evidence.mkdir(exist_ok=False)
 source_report=ROOT/'project/reports/p6_m7_t4_visual'
 scratch=Path(json.loads((source_report/'workspace.json').read_text())['scratch']).resolve()
 assert scratch.parent==Path(tempfile.gettempdir()).resolve() and scratch.name.startswith('facelessvoid_m6_t11_')
 project=scratch/'project';mapping_path=project/'data/ui/icon_assignments.json'
 mapping=json.loads(mapping_path.read_text());proposal=ROOT/'tools/icon-lab/proposals/m7-t4'
 manifest=json.loads((proposal/'manifest.json').read_text());live=json.loads((ROOT/'project/data/ui/icon_assignments.json').read_text())
 for row in manifest['candidates']:
  original=ROOT/'project'/row['original'].removeprefix('res://');assert hashlib.sha256(original.read_bytes()).hexdigest()==row['original_sha256']
  target=(project/row['original'].removeprefix('res://')).resolve();assert target.is_relative_to(project.resolve())
  shutil.copy2(proposal/row['candidate'],target);mapping['entries'][row['id']]['sha256']=row['sha256']
 mapping_path.write_text(json.dumps(mapping,indent=2),encoding='utf-8')
 env=os.environ.copy()
 for key in ['APPDATA','LOCALAPPDATA']:
  env[key]=str(scratch/'userdata/t4_candidate_preview'/key);Path(env[key]).mkdir(parents=True,exist_ok=True)
 startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
 commands=[]
 def run(label,args):
  cmd=[GODOT,'--path',str(project),'--audio-driver','Dummy']+args;commands.append(cmd)
  result=subprocess.run(cmd,env=env,cwd=scratch,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',errors='replace',startupinfo=startup,timeout=240)
  (evidence/(label+'.log')).write_text(result.stdout,encoding='utf-8')
  assert result.returncode==0 and not any(x in result.stdout for x in ['SCRIPT ERROR','Parse Error','FAILED:']),label
  return result.stdout
 run('import',['--headless','--editor','--quit'])
 resource='res://reports/p6_m7_t4_visual/p6_m7_icon_accents_test/isolated.gd'
 result=run('visual',['--rendering-method','gl_compatibility','--resolution','1280x720','--script',resource,'--','--visual'])
 assert 'PASS' in result
 shutil.copytree(project/'reports/p6_m7_t4_visual/p6_m7_icon_accents_test/icon_accents',evidence/'screenshots')
 unchanged=all(hashlib.sha256((ROOT/'project'/r['original'].removeprefix('res://')).read_bytes()).hexdigest()==r['original_sha256'] for r in manifest['candidates'])
 assert unchanged and json.loads((ROOT/'project/data/ui/icon_assignments.json').read_text())==live
 (evidence/'summary.json').write_text(json.dumps(dict(pass_=True,candidate_count=5,live_unchanged=unchanged,commands=commands,scratch=str(scratch),scope='Candidate art staged only in disposable copy; existing cross-mode visual assertions passed. User art approval remains pending.'),indent=2),encoding='utf-8')
 print('PASS candidate art staged in isolated game; cross-mode visual checks; live mappings and art unchanged.')
if __name__=='__main__':main()
