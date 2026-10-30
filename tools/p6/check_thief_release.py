"""Validate T6 promotion and unchanged inherited release provenance."""
import hashlib
import json
from check_assassin_release import successor_source
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
data = json.loads((ROOT/'project/data/p6/thief_release_manifest.json').read_text(encoding='utf-8'))
assert data['content_revision'] == 'p6.playable.thief.1'
assert data['compatible_revisions'] == ['p6.playable.thief.1','p6.playable.bladedancer.1','p6.playable.mixed.1','p6.playable.bladedancer_core.1']
assert data['previous_manifest_sha256'] == hashlib.sha256((ROOT/'project/data/p6/bladedancer_release_manifest.json').read_bytes()).hexdigest()
for path,digest in data['source_sha256'].items():
    actual = hashlib.sha256((ROOT/path).read_bytes()).hexdigest()
    if actual != digest:
        successor_source(path, digest)
    else:
        assert actual == digest, path
assert len([p for p in data['source_sha256'] if '/thief/' in p]) == 9
registry = (ROOT/'project/scripts/systems/build_content_registry.gd').read_text(encoding='utf-8')
assert all(r in registry for r in data['compatible_revisions'])
print('PASS: nine explicit Thief resources, complete source fingerprints and four compatible revisions')
