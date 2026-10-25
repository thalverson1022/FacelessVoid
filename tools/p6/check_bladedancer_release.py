"""Verify explicit T4 promotion provenance without changing compatibility data."""
import hashlib
import json
from check_assassin_release import successor_source
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
data = json.loads((ROOT / 'project/data/p6/bladedancer_release_manifest.json').read_text())
assert data['content_revision'] == 'p6.playable.bladedancer.1'
assert data['compatible_revisions'] == ['p6.playable.bladedancer.1', 'p6.playable.mixed.1', 'p6.playable.bladedancer_core.1']
for path, digest in data['source_sha256'].items():
    actual = hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
    if path in ['project/scripts/systems/build_content_registry.gd', 'project/scripts/systems/p6_thief_contracts.gd'] and actual != digest:
        successor = json.loads((ROOT / 'project/data/p6/thief_release_manifest.json').read_text())
        assert successor['promoted_from'] == data['content_revision']
        assert successor['previous_manifest_sha256'] == hashlib.sha256((ROOT / 'project/data/p6/bladedancer_release_manifest.json').read_bytes()).hexdigest()
        if successor['source_sha256'][path] != actual:
            successor_source(path, successor['source_sha256'][path])
        else:
            assert successor['source_sha256'][path] == actual
        if path.endswith('p6_thief_contracts.gd'):
            assert successor['approved_tuning']['authority'] == 'P6M5-D008'
            assert successor['approved_tuning']['previous_contract_sha256'] == digest
    else:
        assert actual == digest, path
assert len([p for p in data['source_sha256'] if '/bladedancer/' in p]) == 8
assert 'docs/P6M5_T3_Bladedancer_Design_Review.md' in data['source_sha256']
registry = (ROOT / 'project/scripts/systems/build_content_registry.gd').read_text()
assert all(revision in registry for revision in data['compatible_revisions'])
print('PASS: explicit full-Bladedancer promotion hashes and declared compatibility')
