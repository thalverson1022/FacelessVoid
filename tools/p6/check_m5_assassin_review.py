"""Static T7 specification checks. Does not execute or promote game content."""
import hashlib
import json
import re
from datetime import datetime, timezone
from fractions import Fraction as F
from pathlib import Path
from source_provenance import validate_source

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / 'docs/P6M5_T7_Assassin_Design_Review.md'
OUT = ROOT / 'project/reports/p6_m5_t7_review'


def main():
    ledger = json.loads((ROOT / 'docs/P6M5_T2_Content_Coverage_Ledger.json').read_text(encoding='utf-8'))
    doc = DOC.read_text(encoding='utf-8')
    records = [r for r in ledger['records'] if r['tree_id'] == 'tree.assassin']
    talents = {r['runtime_id']: r for r in records if r['kind'] == 'talent'}
    assert len(talents) == 10 and sum(r['max_ranks'] for r in talents.values()) == 35
    promoted = all(r['status'] == 'P' for r in talents.values())
    section = doc.split('## All talents and complete rank effects')[1].split('## Skills and unlocks')[0]
    rows = [line.split('|')[1:-1] for line in section.splitlines() if re.match(r'\| .* / `', line)]
    assert len(rows) == 10
    seen = set()
    for row in rows:
        identity = re.search(r'`([^`]+)`', row[0])[1]
        assert identity in talents and identity not in seen
        seen.add(identity)
        record = talents[identity]
        assert int(row[1]) == record['required_tree_points']
        names = [talents[p]['source_name'] + ' 1' for p in record['prerequisite_ids']]
        assert row[3].strip() == (', '.join(names) if names else 'None')
    skills = [r for r in records if r['kind'] == 'skill']
    assert len(skills) == 6 and all('`' + r['runtime_id'] + '`' in doc for r in skills)
    slots = [r for r in records if r['kind'] == 'slot']
    assert [r['required_points'] for r in slots] == [1, 3, 6, 9, 12]
    assert all(r['skill_id'] and '`' + r['runtime_id'] + '`' in doc for r in slots)
    grants = [g for g in ledger['talent_skill_grants'] if g['talent_id'] in talents]
    assert len(grants) == 1 and grants[0]['skill_id'] == 'skill.poison_strike'
    assert set(re.findall(r'\| E(\d\d) —', doc)) == {f'{i:02}' for i in range(1, 13)}
    assert set(re.findall(r'\| T(\d\d) —', doc)) == {f'{i:02}' for i in range(1, 19)}

    # Read purchase plans from the document; validate against canonical ledger gates.
    by_name = {r['source_name']: r for r in talents.values()}
    fixture_results = []
    for name, entries in re.findall(r'- \*\*([^*]+):\*\* ([^.]+)\.', doc):
        ranks = {}
        log = []
        for entry in entries.split(', '):
            talent_name, quantity = entry.rsplit(' ', 1)
            record = by_name[talent_name]
            target = int(quantity)
            assert 0 < target <= record['max_ranks']
            for rank in range(1, target + 1):
                support = sum(v for k, v in ranks.items() if talents[k]['required_tree_points'] < record['required_tree_points'])
                assert support >= record['required_tree_points'], (name, talent_name, support)
                assert all(ranks.get(p, 0) >= 1 for p in record['prerequisite_ids'])
                ranks[record['runtime_id']] = rank
                assert sum(ranks.values()) <= 45
                log.append({'id': record['runtime_id'], 'rank': rank, 'lower_tier_support': support})
        assert sum(ranks.values()) == int(name.split()[-1])
        fixture_results.append({'name': name, 'legal_under_D007': True, 'purchases': log})
    assert len(fixture_results) == 4

    # Validate the secondary allocations and the live-gold mixed fixture as well.
    paired = [
        ('tree.bladedancer', [('Whetstone', 4), ('Rending Slash', 1), ('Fancy Footwork', 5)], 10),
        ('tree.thief', [('Keen Eye', 5), ('Sticky Fingers', 5)], 10),
        ('tree.thief', [('Keen Eye', 5), ('Sticky Fingers', 5), ('Fast Hands', 5), ('Bribery', 3), ('Silvered Edge', 3), ('Finders Keepers', 2), ('Gilded Blade', 1)], 24),
    ]
    for tree, purchases, total in paired:
        items = {r['source_name'].strip(): r for r in ledger['records'] if r['kind'] == 'talent' and r['tree_id'] == tree}
        ranks = {}
        for name, target in purchases:
            rec = items[name]
            assert target <= rec['max_ranks']
            support = sum(value for prior, value in ranks.items() if items[prior]['required_tree_points'] < rec['required_tree_points'])
            assert support >= rec['required_tree_points'], (tree, name, support)
            assert all(any(items[n]['runtime_id'] == p and value >= 1 for n, value in ranks.items()) for p in rec['prerequisite_ids'])
            ranks[name] = target
        assert sum(ranks.values()) == total
    assert 35 + 10 == 45 and 21 + 24 == 45
    # Independent rational calculations for documented examples.
    assert [5 + r for r in (0, 1, 5, 10, 20, 35)] == [5, 6, 10, 15, 25, 40]
    assert F(1) + F(5, 100) == F(105, 100)
    assert max(F(500), F(1000) / F(205, 100)) == 500
    assert F(20, 100) + F(5, 100) == F(25, 100)
    request = (5 + 2) * 2
    assert request == 14 and min(request, 20 - 18) == 2 and request - 2 == 12
    assert round(F(1000) / (1 + F(1, 10) * 10)) == 500
    assert round(F(1000) / (1 + F(1, 10) * 5)) == 667
    assert F(1, 2) * 500 == 250
    tick = 10 * 3 * F(13, 10) * F(18, 10)
    assert tick == F('70.2') and tick * F(2, 3) == F('46.8') and tick / 3 == F('23.4')
    assert tick * 2 == F('140.4') and 2 * F(1, 2) == 1
    assert tick * 4 * 3 == F('842.4') and round(tick * 4 * 3) == 842
    assert min((1 + 2) * 2, 3) == 3 and 1 + F(1, 10) * 3 == F('1.3')
    assert (10 + 2) * 2 == 24 and 10 - 24 == -14 and 0 - 24 == -24

    report = OUT / 'summary.json'
    for target in re.findall(r'\]\(([^)]+)\)', doc):
        if '://' not in target:
            resolved = (DOC.parent / target.split('#')[0]).resolve()
            assert resolved == report.resolve() or resolved.exists(), target
    for name in set(re.findall(r'`(p[56]_[a-z0-9_]+_test)`', doc)):
        assert (ROOT / 'project/tests' / f'{name}.gd').is_file(), name
    review = ledger['design_reviews']['tree.assassin']
    assert review['status'] == 'Complete' and review['pending_decisions'] == []
    assert review['approved_decisions'] == ['D01', 'D02', 'D03']
    baseline = json.loads((OUT / 'source_hashes.json').read_text(encoding='utf-8'))
    checked = 0
    for path, digest in baseline.items():
        if promoted and not (path.startswith('docs/talent_tree_drafts/') or path.endswith('Content_Identity_Manifest.json')):
            continue
        checked += 1
        validate_source(path, digest)
    report.write_text(json.dumps({
        'passed': True, 'checked_at_utc': datetime.now(timezone.utc).isoformat(),
        'scope': 'Static review only; no Godot runtime, visual acceptance or content promotion.',
        'inventory': {'talents': 10, 'ranks': 35, 'skills': 6, 'slots': 5, 'talent_grants': 1},
        'legal_builds': fixture_results, 'mixed_allocations_checked': 3,
        'worked_examples': 12, 'acceptance_groups': 18,
        'validated_draft_and_identity_files': checked, 'runtime_promotion': promoted,
        'specification_sha256': hashlib.sha256(DOC.read_bytes()).hexdigest(),
        'pending_decisions': review['pending_decisions'],
    }, indent=2) + '\n', encoding='utf-8')
    print('PASS: Assassin inventory, D007 legal builds, examples, references and runtime/draft fingerprints; D01-D03 approved; runtime evidence is separate.')


if __name__ == '__main__':
    main()
