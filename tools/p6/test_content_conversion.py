"""Negative conversion checks using disposable source copies."""
import json
import hashlib
import shutil
import tempfile
from pathlib import Path
import convert_representative_content as converter

converter.artifacts()
original_root = converter.ROOT
with tempfile.TemporaryDirectory() as folder:
    fixture_root = Path(folder)
    (fixture_root / 'docs').mkdir()
    shutil.copytree(original_root / 'docs/talent_tree_drafts', fixture_root / 'docs/talent_tree_drafts')
    manifest_path = fixture_root / 'docs/P6M2_T4_Content_Identity_Manifest.json'
    original = (original_root / manifest_path.relative_to(fixture_root)).read_text(encoding='utf-8')
    manifest_path.write_text(original, encoding='utf-8')
    converter.ROOT = fixture_root
    for case in ['hash', 'duplicate', 'missing', 'reordered']:
        manifest = json.loads(original)
        if case == 'hash':
            manifest['sources'][0]['sha256'] = '0' * 64
        elif case == 'duplicate':
            manifest['records'][1]['runtime_id'] = manifest['records'][0]['runtime_id']
        elif case == 'reordered':
            source = next(s for s in manifest['sources'] if s['tree_id'] == 'tree.bladedancer')
            path = fixture_root / source['file']
            draft = json.loads(path.read_text(encoding='utf-8'))
            draft['tree']['talents'][0], draft['tree']['talents'][1] = draft['tree']['talents'][1], draft['tree']['talents'][0]
            path.write_text(json.dumps(draft), encoding='utf-8')
            source['sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
        else:
            manifest['records'] = [r for r in manifest['records'] if r['runtime_id'] != 'talent.bladedancer.wet_stone']
        manifest_path.write_text(json.dumps(manifest), encoding='utf-8')
        try:
            converter.artifacts()
        except (AssertionError, StopIteration):
            pass
        else:
            raise AssertionError('Invalid conversion input accepted: ' + case)
converter.ROOT = original_root
print('PASS: changed hash, duplicate runtime ID missing mapping and reordered identity pointers reject conversion')
