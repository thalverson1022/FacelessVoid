"""Verify captured Effects-bus PCM and queued-callback cancellation evidence."""
import argparse,json,wave,array
from pathlib import Path

def main():
 ap=argparse.ArgumentParser();ap.add_argument('directory',type=Path);a=ap.parse_args()
 source=json.loads((a.directory/'measurements.json').read_text());rows=[]
 for row in source['rows']:
  with wave.open(str(a.directory/row['file'])) as wav:
   assert wav.getsampwidth()==2
   samples=array.array('h',wav.readframes(wav.getnframes()))
   late=samples[int((row.get('action_at_sec',0)+.15)*wav.getframerate()*wav.getnchannels()):]
   result={'file':row['file'],'peak':max(map(abs,samples),default=0),'clipped_samples':sum(abs(v)>=32767 for v in samples),'seconds':wav.getnframes()/wav.getframerate(),'nonzero_samples':sum(v!=0 for v in samples),'late_peak':max(map(abs,late),default=0)}
   if row['action'] not in ('reference','real_resolver_ghost'):
    result['callback_delta']=row['count_after']-row['count_at_action']
    result['pass']=result['late_peak']==0 and result['callback_delta']==0
   else:result['pass']=result['nonzero_samples']>0
   rows.append(result)
 report={'driver':source['driver'],'tail_grace_sec':.15,'rows':rows,'pass':all(r['pass'] for r in rows),'limitation':'Effects bus recording verifies engine mix and callback timing. It does not record speakers or certify host hardware. Human acceptance is recorded separately.'}
 (a.directory/'pcm_analysis.json').write_text(json.dumps(report,indent=2))
 print('PCM PASS' if report['pass'] else 'PCM FAILED')
 return 0 if report['pass'] else 1
if __name__=='__main__':raise SystemExit(main())
