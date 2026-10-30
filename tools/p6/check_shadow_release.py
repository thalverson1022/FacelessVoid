"""Verify complete Shadow release and immutable Assassin predecessor chain."""
import hashlib
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT/'project/data/p6/shadow_release_manifest.json'
PREVIOUS = ROOT/'project/data/p6/assassin_release_manifest.json'
def successor_source(path, old_digest):
    data=json.loads(MANIFEST.read_text(encoding='utf-8'))
    assert data['authority']=='P6M5-D011 / M5-T8'
    assert data['promoted_from']=='p6.playable.assassin.1'
    assert data['previous_manifest_sha256']==hashlib.sha256(PREVIOUS.read_bytes()).hexdigest()
    previous=json.loads(PREVIOUS.read_text(encoding='utf-8'))
    assert previous['source_sha256'][path]==old_digest
    assert data['source_sha256'][path]==hashlib.sha256((ROOT/path).read_bytes()).hexdigest(),path
def main():
    data=json.loads(MANIFEST.read_text(encoding='utf-8'))
    assert data['content_revision']=='p6.playable.shadow.1'
    assert data['balance_authority']=='P6M5-D023'
    assert hashlib.sha256((ROOT/data['previous_balance_manifest']).read_bytes()).hexdigest()==data['previous_balance_manifest_sha256']
    archived=json.loads((ROOT/data['previous_balance_manifest']).read_text(encoding='utf-8'))
    assert archived['balance_authority']=='P6M5-D022'
    assert hashlib.sha256((ROOT/archived['previous_balance_manifest']).read_bytes()).hexdigest()==archived['previous_balance_manifest_sha256']
    assert len(data['compatible_revisions'])==6
    baseline=json.loads((ROOT/'project/reports/p6_m5_t8_review/source_hashes.json').read_text(encoding='utf-8'))
    assert hashlib.sha256(PREVIOUS.read_bytes()).hexdigest()==baseline['project/data/p6/assassin_release_manifest.json']
    for path,digest in data['source_sha256'].items():
        assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,path
    assert len([p for p in data['source_sha256'] if '/shadow/' in p])==11
    successor_source('project/scripts/systems/build_content_registry.gd',json.loads(PREVIOUS.read_text(encoding='utf-8'))['source_sha256']['project/scripts/systems/build_content_registry.gd'])
    registry=(ROOT/'project/scripts/systems/build_content_registry.gd').read_text(encoding='utf-8')
    assert all(r in registry for r in data['compatible_revisions'])
    print('PASS: eleven Shadow resources, release source hashes, unchanged Assassin predecessor, six compatible revisions')
if __name__=='__main__': main()
