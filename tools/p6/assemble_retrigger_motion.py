"""Assemble actual viewport captures using their measured real frame durations."""
import argparse,json
from pathlib import Path
from PIL import Image,ImageDraw

def main():
 parser=argparse.ArgumentParser()
 parser.add_argument('motion_directory',type=Path)
 args=parser.parse_args()
 out=args.motion_directory.resolve()
 data=json.loads((out/'measurements.json').read_text(encoding='utf-8-sig'))
 groups={}
 for row in data['rows']:
  groups.setdefault((row['mode'],int(row['speed'])),[]).append(row)
 manifest=[]
 for (mode,speed),rows in groups.items():
  prefix=f'{mode}_{speed}x'
  frames=[Image.open(out/f'{prefix}_{row["frame"]:03d}.png').convert('RGB') for row in rows]
  durations=[]
  elapsed=previous=0
  for row in rows:
   elapsed+=row['delta_ms']
   mark=round(elapsed/10)*10
   durations.append(max(10,mark-previous))
   previous=mark
  frames[0].save(out/f'{prefix}_ghost.gif',save_all=True,append_images=frames[1:],duration=durations,loop=0,optimize=True,disposal=2)
  crop=(440,280,770,405) if mode=='practice' else (440,190,770,335)
  cell_w,cell_h=330,170
  sheet=Image.new('RGB',(cell_w*4,cell_h*4),(20,20,20))
  draw=ImageDraw.Draw(sheet)
  selected=sorted(set(round(i*(len(rows)-1)/15) for i in range(16)))
  for cell,index in enumerate(selected):
   x,y=cell%4*cell_w,cell//4*cell_h
   sheet.paste(frames[index].crop(crop),(x,y+20))
   row=rows[index]
   draw.text((x+5,y+4),f'{mode} {speed}x | {sum(durations[:index+1])/1000:.2f}s | alpha {row["ghost_alpha"]:.2f}',fill='white')
  sheet.save(out/f'{prefix}_contact_sheet.png')
  visible=[(i,row) for i,row in enumerate(rows) if row['ghost_visible']]
  if visible:
   index,_=max(visible,key=lambda item:item[1]['ghost_alpha'])
   frames[index].save(out/f'{prefix}_ghost_contact.png')
  manifest.append({'mode':mode,'speed':speed,'frames':len(frames),'measured_wall_ms':round(sum(row['delta_ms'] for row in rows),2),'visible_ghost_samples':len(visible),'unanchored_main_during_ghost':sum(not row['main_anchored'] for _,row in visible),'gif_duration_ms':sum(durations),'gif':f'{prefix}_ghost.gif','contact_sheet':f'{prefix}_contact_sheet.png'})
 (out/'media.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
 print(json.dumps(manifest,indent=2))
if __name__=='__main__':main()
