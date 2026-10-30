"""Package M7-T4 generated candidates and actual-size review; never install live art."""
from pathlib import Path
import json, hashlib, base64, shutil
from PIL import Image, ImageDraw, ImageFont, ImageOps
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'tools/icon-lab/proposals/m7-t4'
SOURCES=Path('C:/Users/tommh/.codex/generated_images/01a12179-aee0-7012-9bd9-ed89ef1346cb')
CANDIDATES=[
 ('talent.shadow.shadow_mastery','shadow_mastery','exec-6e5b8d8f-4f9c-4d1c-8f9f-ac0efeba1f55.png'),
 ('talent.shadow.dusk_strike','dusk_strike','exec-6823d366-2ac3-4403-8f50-4ceb26d9242b.png'),
 ('status.potency','potency','exec-0c78c546-95d7-4c24-844c-31a04590216d.png'),
 ('talent.assassin.toxic_tradeoff','toxic_tradeoff','exec-74072f87-52df-41ec-87cc-97a026aed043.png'),
 ('talent.bladedancer.sharpened_edge','sharpened_edge','exec-483a4912-b9dd-4e93-a1ce-c4e114829666.png')]
def main():
 OUT.mkdir(parents=True,exist_ok=True);(OUT/'masters').mkdir(exist_ok=True)
 data=json.loads((ROOT/'tools/icon-lab/data/catalog.json').read_text(encoding='utf-8'))
 installed=json.loads((ROOT/'project/data/ui/icon_assignments.json').read_text(encoding='utf-8'))['entries']
 workspace=dict(format='facelessvoid.icon-lab',schema_version=1,catalog_fingerprint=data['fingerprint'],assignments={e['id']:e['current_icon'] for e in data['entries']},imported_assets=[])
 font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',16)
 small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',12)
 canvas=Image.new('RGB',(1080,860),(19,22,29));draw=ImageDraw.Draw(canvas)
 draw.text((24,14),'M7-T4 icon candidates | Current above, proposed below | Not installed',font=font,fill='white')
 for x,label in [(260,'22px'),(330,'24px'),(405,'32px'),(495,'52px'),(600,'32px gray'),(710,'32px + count'),(845,'64px detail')]:draw.text((x,52),label,font=small,fill='#b8c2d5')
 rows=[]
 for i,(identity,name,source) in enumerate(CANDIDATES):
  master=OUT/'masters'/f'{name}.png'
  if not master.exists():shutil.copy2(SOURCES/source,master)
  with Image.open(master) as im:
   assert im.mode=='RGBA' and im.getchannel('A').getextrema()[0]==0
   im.resize((32,32),Image.Resampling.NEAREST).save(OUT/f'{name}.png')
  raw=(OUT/f'{name}.png').read_bytes();digest=hashlib.sha256(raw).hexdigest();asset='import:'+digest
  workspace['imported_assets'].append(dict(id=asset,name=name+'-m7-t4.png',mime='image/png',data_url='data:image/png;base64,'+base64.b64encode(raw).decode(),sha256=digest,width=32,height=32,bytes=len(raw)))
  workspace['assignments'][identity]=asset
  row=dict(id=identity,name=installed[identity]['name'],candidate=f'{name}.png',sha256=digest,master_sha256=hashlib.sha256(master.read_bytes()).hexdigest(),original=installed[identity]['path'],original_sha256=installed[identity]['sha256'])
  rows.append(row);y=86+i*151;draw.text((24,y+30),row['name'],font=font,fill='white')
  for offset,path,label in [(0,ROOT/'project'/row['original'].removeprefix('res://'),'Current'),(65,OUT/f'{name}.png','Proposed')]:
   art=Image.open(path).convert('RGBA');draw.text((170,y+offset+8),label,font=small,fill='#b8c2d5')
   for x,size in [(260,22),(330,24),(405,32),(495,52),(845,64)]:
    tile=art.resize((size,size),Image.Resampling.NEAREST);canvas.paste(tile,(x,y+offset),tile)
   gray=ImageOps.grayscale(art).convert('RGBA');gray.putalpha(art.getchannel('A'));canvas.paste(gray,(610,y+offset),gray)
   canvas.paste(art,(730,y+offset),art);draw.text((750,y+offset+21),'50' if identity=='status.potency' else '3',font=small,fill='white',stroke_width=1,stroke_fill='black')
  draw.line((24,y+138,1040,y+138),fill='#303743')
 draw.text((24,838),'Grayscale/count examples are review approximations; integrated UI acceptance remains separate.',font=small,fill='#b8c2d5')
 canvas.save(OUT/'comparison.png')
 (OUT/'workspace.json').write_text(json.dumps(workspace,indent=2)+'\n',encoding='utf-8')
 (OUT/'manifest.json').write_text(json.dumps(dict(status='Pending concrete user review',candidates=rows),indent=2)+'\n',encoding='utf-8')
 print('Packaged five 32px RGBA candidates, masters, portable workspace and actual-size comparison.')
if __name__=='__main__':main()
