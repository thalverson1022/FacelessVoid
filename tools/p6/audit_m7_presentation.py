"""T2: reproduce asset coverage and native-size contact sheets without changing assets."""
import json, hashlib, subprocess
from pathlib import Path
from collections import Counter, defaultdict
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'project/reports/p6_m7_t2_audit'
OUT.mkdir(exist_ok=True)
runtime=json.loads((ROOT/'project/reports/p6_m7_t2_inventory/p6_m7_presentation_inventory/p6_m7_t2_inventory/inventory.json').read_text())
entries=json.loads((ROOT/'project/data/ui/icon_assignments.json').read_text())['entries']
rows=[]
groups=defaultdict(list)
for identity,entry in entries.items():
    path=ROOT/'project'/entry['path'].removeprefix('res://')
    with Image.open(path) as im: dimensions=list(im.size)
    rows.append(dict(id=identity,**entry,dimensions=dimensions,hash_matches=hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256']))
    groups[entry['path']].append(identity)
talents=[x for t in runtime['trees'] for x in t['talents']]
missing=[x['id'] for x in talents+runtime['skills'] if not x['icon'] or x['id'] not in entries]
report=dict(git_head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),working_tree='Inherited dirty baseline; see isolated runner baseline.json for source hashes.',counts=dict(Counter(x['category'] for x in rows)),identities=len(rows),distinct_asset_paths=len(groups),missing_live_mappings=missing,all_hashes_match=all(x['hash_matches'] for x in rows),all_32px=all(x['dimensions']==[32,32] for x in rows),shared_paths={k:v for k,v in groups.items() if len(v)>1},assets=rows,runtime=runtime)
(OUT/'coverage.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',12)
for page,start in enumerate(range(0,len(rows),24),1):
    subset=rows[start:start+24]
    canvas=Image.new('RGB',(1080,80+len(subset)*58),(19,22,29)); draw=ImageDraw.Draw(canvas)
    draw.text((12,10),'M7 T2 installed icons at 22 / 32 / 52 px; assignments unchanged',font=font,fill='white')
    for i,row in enumerate(subset):
        y=55+i*58
        draw.text((12,y+15),row['id'],font=font,fill='white')
        with Image.open(ROOT/'project'/row['path'].removeprefix('res://')).convert('RGBA') as im:
            for x,size in [(390,22),(430,32),(480,52)]:
                art=im.resize((size,size),Image.Resampling.NEAREST); canvas.paste(art,(x,y),art)
        draw.text((555,y+15),row['name'],font=font,fill='white')
    canvas.save(OUT/f'icons-{page}.png')
lines=['# M7-T2 live presentation inventory','','Generated with `python tools/p6/audit_m7_presentation.py`. Full rank descriptions, unlocks and asset hashes: [coverage JSON](../project/reports/p6_m7_t2_audit/coverage.json).','','Mappings are retained as the baseline; flagged readability candidates need T3/T4 review before changes. Text dispositions are audit findings, not final T5 acceptance. Skill text uses default planning stats; conditional build wording needs the T5 matrix. Gap IDs refer to the [audit](P6M7_T2_Presentation_And_Asset_Audit.md).','']
for t in runtime['trees']:
    lines += ['## '+t['name'],'','| Talent / stable ID | Ranks | Gate | Text disposition |','| --- | ---: | ---: | --- |']
    for x in t['talents']:
        disposition='Improve - G04 terminology' if x['name'] in ['Toxic Tradeoff','Death Touch','Weapon Master','Keen Eye','Deception'] else 'Retain - no specific discrepancy found'
        lines.append(f"| {x['name']} (`{x['id']}`) | {x['max_ranks']} | {x['gate']} | {disposition} |")
    lines += ['', 'Automatic unlocks: '+', '.join(str(x['points'])+' -> '+str(x['skill']) for x in t['unlocks'])+'.','']
lines += ['## Skills','','| Skill / stable ID | Unlock source | Description disposition |','| --- | --- | --- |']
for x in runtime['skills']:
    gap={'skill.killers_mark':'G01','skill.mug':'G02','skill.pick_pocket':'G03','skill.big_score':'G05'}.get(x['id'])
    disposition='Improve - '+gap if gap else 'Retain - conditional/build estimates require T5 matrix'
    lines.append(f"| {x['name']} (`{x['id']}`) | {', '.join(x['origins'])} | {disposition} |")
lines += ['','## All mapped assets','','| Identity | Asset path | Disposition |','| --- | --- | --- |']
candidates={'talent.shadow.shadow_mastery','talent.shadow.dusk_strike','status.potency','talent.assassin.toxic_tradeoff','talent.bladedancer.sharpened_edge'}
lines += [f"| `{x['id']}` | `{x['path']}` | "+('Improve - G09 readability review' if x['id'] in candidates else 'Retain; T4 actual-size acceptance')+' |' for x in rows]
(ROOT/'docs/P6M7_T2_Presentation_Inventory.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
assert not missing and report['all_hashes_match'] and report['all_32px']
print(json.dumps({k:report[k] for k in ['counts','identities','distinct_asset_paths','missing_live_mappings','all_hashes_match','all_32px']},indent=2))
