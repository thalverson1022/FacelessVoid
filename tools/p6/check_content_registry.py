"""Verify the complete declared compatibility resource set before packaging."""
import hashlib
import json
from pathlib import Path
root = Path(__file__).resolve().parents[2]
data = json.loads((root / 'project/data/p6/compatibility_manifest.json').read_text(encoding='utf-8'))
assert data['content_revision'] == 'p6.compat.1' and data['mode'] == 'legacy'
assert len(data['resource_paths']) == len(set(data['resource_paths']))
actual = {'res://' + p.relative_to(root / 'project').as_posix() for p in (root / 'project/data').rglob('*.tres')}
# M4's explicitly scoped playable resources coexist with the unchanged legacy
# manifest. Do not expand the compatibility registry or admit arbitrary files.
playable = {'res://data/p6/test_mode/' + name + '.tres' for name in (
    'tree', 'whetstone', 'rending_slash', 'fancy_footwork', 'leaping_plunge', 'parry_strike')}
full_blade = {'res://data/p6/bladedancer/' + name + '.tres' for name in (
    'weakness', 'precision_attacks', 'double_dip', 'sharpened_edge',
    'riposte', 'side_step', 'weapon_master', 'virulent_corruption')}
full_thief = {'res://data/p6/thief/' + name + '.tres' for name in ('sticky_fingers','fast_hands','fill_your_pockets','charisma','bribery','silvered_edge','finders_keepers','load_dice','gilded_blade')}
full_assassin = {'res://data/p6/assassin/' + name + '.tres' for name in ('quick_hands','precision','hastened_poison','echoing_toxin','poison_strike','bypass','toxic_tradeoff','accelerant','resonance','critical_poison')}
full_shadow = {'res://data/p6/shadow/' + name + '.tres' for name in ('umbral_presence', 'coated_weapons', 'blind_spot', 'snake_oil', 'death_touch', 'dusk_strike', 'shadow_mastery', 'deception', 'death_from_the_shadows', 'death_pact', 'death_blade')}
assert actual == set(data['resource_paths']) | playable | full_blade | full_thief | full_assassin | full_shadow, 'Update the reviewed resource allowlist'
assert not playable.intersection(data['resource_paths'])
for path, expected in data['resource_sha256'].items():
    assert path in actual
    assert hashlib.sha256((root / 'project' / path.removeprefix('res://')).read_bytes()).hexdigest() == expected, path
assert set(data['resource_sha256']) == set(data['resource_paths'])
assert 'data/p6/*.json' in (root / 'project/export_presets.cfg').read_text()
print(f'PASS: {len(data["resource_paths"])} unchanged compatibility resources, six scoped M4 resources, eight approved Bladedancer resources and export inclusion')
