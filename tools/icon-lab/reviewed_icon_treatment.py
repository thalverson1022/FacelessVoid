"""Package approved artwork inside the shared native-size UI tile.
No source artwork is overwritten; every framed output is rebuilt from its source.
"""
from pathlib import Path
import json,hashlib
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
def apply_treatment(rows):
    spec_path=ROOT/'tools/icon-lab/approved/m7-t4/treatment.json'
    spec=json.loads(spec_path.read_text(encoding='utf-8'))
    assert spec['size']==32 and spec['border_px']==1 and spec['padding_px']==1
    for identity,row in rows.items():
        if row.get('inherits'):continue
        original_path=row['path']
        override=spec['overrides'].get(identity)
        source=ROOT/override['file'] if override else ROOT/'project'/original_path.removeprefix('res://')
        expected=override['sha256'] if override else row['sha256']
        assert hashlib.sha256(source.read_bytes()).hexdigest()==expected,identity
        relative=original_path.removeprefix('res://').replace('assets/ui/assigned/','assets/ui/assigned_flat/',1)
        target=ROOT/'project'/relative;target.parent.mkdir(parents=True,exist_ok=True)
        tile=Image.new('RGBA',(32,32),spec['border'])
        tile.paste(Image.new('RGBA',(30,30),spec['background']),(1,1))
        with Image.open(source) as artwork:
            artwork=artwork.convert('RGBA').resize((28,28),Image.Resampling.NEAREST)
            tile.alpha_composite(artwork,(2,2))
        tile.save(target)
        if override:
            row['previous_source_asset_id']=row['source_asset_id']
            row['source_asset_id']='approved:m7-t4/'+source.name
            row['source_sha256']=expected
        row.update(path='res://'+relative,sha256=hashlib.sha256(target.read_bytes()).hexdigest(),artwork_path=source.relative_to(ROOT).as_posix(),artwork_sha256=expected,previous_path=original_path,treatment='m7-t4-flat-charcoal')
    for identity,row in rows.items():
        if row.get('inherits'):
            source=rows[row['inherits']]
            for key in ['path','sha256','artwork_path','artwork_sha256','previous_path','treatment','source_asset_id']:row[key]=source[key]
    return {'spec':'tools/icon-lab/approved/m7-t4/treatment.json','sha256':hashlib.sha256(spec_path.read_bytes()).hexdigest(),'decision':spec['decision']}
