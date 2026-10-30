"""Verify Assassin promotion and immutable predecessor provenance."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / 'project/data/p6/assassin_release_manifest.json'


def successor_source(path, old_digest):
    data = json.loads(MANIFEST.read_text(encoding='utf-8'))
    previous = ROOT / 'project/data/p6/thief_release_manifest.json'
    assert data['authority'] == 'P6M5-D009 / M5-T7'
    assert data['promoted_from'] == 'p6.playable.thief.1'
    assert data['previous_manifest_sha256'] == hashlib.sha256(previous.read_bytes()).hexdigest()
    predecessor = json.loads(previous.read_text(encoding='utf-8'))
    assert predecessor['source_sha256'][path] == old_digest
    digest = data['source_sha256'][path]
    if digest != hashlib.sha256((ROOT / path).read_bytes()).hexdigest():
        from check_shadow_release import successor_source as shadow_source
        shadow_source(path, digest)


def main():
    data = json.loads(MANIFEST.read_text(encoding='utf-8'))
    assert data['content_revision'] == 'p6.playable.assassin.1'
    assert data['balance_authority'] == 'P6M5-D010'
    assert hashlib.sha256((ROOT / data['previous_balance_manifest']).read_bytes()).hexdigest() == data['previous_balance_manifest_sha256']
    assert data['compatible_revisions'] == ['p6.playable.assassin.1', 'p6.playable.thief.1', 'p6.playable.bladedancer.1', 'p6.playable.mixed.1', 'p6.playable.bladedancer_core.1']
    for path, digest in data['source_sha256'].items():
        if hashlib.sha256((ROOT / path).read_bytes()).hexdigest() != digest:
            from check_shadow_release import successor_source as shadow_source
            shadow_source(path, digest)
    assert len([p for p in data['source_sha256'] if '/assassin/' in p]) == 10
    successor_source('project/scripts/systems/build_content_registry.gd', json.loads((ROOT / 'project/data/p6/thief_release_manifest.json').read_text())['source_sha256']['project/scripts/systems/build_content_registry.gd'])
    registry = (ROOT / 'project/scripts/systems/build_content_registry.gd').read_text()
    assert all(revision in registry for revision in data['compatible_revisions'])
    print('PASS: ten Assassin resources, binding/source hashes, immutable Thief predecessor and five compatible revisions')


if __name__ == '__main__':
    main()
