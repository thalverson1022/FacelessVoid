"""Build/check presentation-only full-tree data. Never generates combat resources."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'project/data/ui/full_tree_display.json'


def catalog():
    manifest = json.loads((ROOT / 'docs/P6M2_T4_Content_Identity_Manifest.json').read_text())
    icons = json.loads((ROOT / 'project/data/ui/icon_assignments.json').read_text())['entries']
    result = {'schema_version': 1, 'purpose': 'Presentation only; never allocate or resolve this catalog.', 'trees': []}
    for name in ['Bladedancer', 'Thief', 'Assassin', 'Shadow']:
        source = 'docs/talent_tree_drafts/' + name + '.json'
        tree = json.loads((ROOT / source).read_text())['tree']
        records = [r for r in manifest['records'] if r['source_file'] == source]
        by_pointer = {r['pointer']: r for r in records}
        ids = {r['source_id']: r['runtime_id'] for r in records if r['source_id']}
        tiers = {v['id']: v for v in tree['levels']}
        out = {'id': 'tree.' + name.lower(), 'name': name, 'source': source,
               'source_sha256': hashlib.sha256((ROOT / source).read_bytes()).hexdigest(), 'talents': [], 'unlocks': []}
        for i, talent in enumerate(tree['talents']):
            pointer = f'/tree/talents/{i}'
            identity = by_pointer[pointer]['runtime_id']
            assert identity in icons
            grant = by_pointer.get(pointer + '/skill_grant')
            out['talents'].append({'id': identity, 'name': icons[identity]['name'],
                'position': talent['position'], 'tier': tiers[talent['level_id']]['order'], 'required_points': tiers[talent['level_id']]['required_points'],
                'max_ranks': talent['max_ranks'], 'prerequisites': [ids[v] for v in talent['prerequisite_ids']],
                'draft_description': talent['description'], 'icon_path': icons[identity]['path'],
                'skill_grant': grant['runtime_id'] if grant else None})
        for i, unlock in enumerate(tree['automatic_unlocks']):
            pointer = f'/tree/automatic_unlocks/{i}'
            skill = by_pointer.get(pointer + '/skill')
            identity = skill['runtime_id'] if skill else None
            if identity: assert identity in icons
            out['unlocks'].append({'id': by_pointer[pointer]['runtime_id'], 'required_points': unlock['required_points'],
                'draft_description': unlock['skill']['description'].strip() if unlock['skill'] else '',
                'skill_id': identity, 'name': icons[identity]['name'] if identity else 'Unassigned',
                'icon_path': icons[identity]['path'] if identity else None})
        result['trees'].append(out)
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    text = json.dumps(catalog(), indent=2, ensure_ascii=False) + '\n'
    if args.check:
        assert DEST.read_text(encoding='utf-8') == text, 'Display catalog needs regeneration'
    else:
        DEST.write_text(text, encoding='utf-8')
    built = catalog()
    talents = [t for tree in built['trees'] for t in tree['talents']]
    print(f"PASS: {len(talents)} canonical talents, {sum(len(t['prerequisites']) for t in talents)} dependencies, {sum(len(t['unlocks']) for t in built['trees'])} unlock positions; display-only catalog")
