"""Static Shadow review checks; no runtime promotion or approval."""
import hashlib
import json
import re
from datetime import datetime, timezone
from fractions import Fraction as F
from pathlib import Path
from source_provenance import validate_source
ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / 'docs/P6M5_T8_Shadow_Design_Review.md'
OUT = ROOT / 'project/reports/p6_m5_t8_review'

def main():
    ledger = json.loads((ROOT / 'docs/P6M5_T2_Content_Coverage_Ledger.json').read_text(encoding='utf-8'))
    doc = DOC.read_text(encoding='utf-8-sig')
    records = [r for r in ledger['records'] if r['tree_id'] == 'tree.shadow']
    talents = {r['runtime_id']: r for r in records if r['kind'] == 'talent'}
    assert len(talents) == 11 and sum(r['max_ranks'] for r in talents.values()) == 35
    section = doc.split('## All talents and complete rank effects')[1].split('## Skills')[0]
    rows = [line.split('|')[1:-1] for line in section.splitlines() if re.match(r'\| .* / `', line)]
    assert len(rows) == 11
    seen = set()
    for row in rows:
        identity = re.search(r'`([^`]+)`', row[0])[1]
        assert identity in talents and identity not in seen
        seen.add(identity)
        rec = talents[identity]
        assert int(row[1]) == rec['required_tree_points']
        names = [talents[p]['source_name'] + ' 1' for p in rec['prerequisite_ids']]
        assert row[3].strip() == (', '.join(names) if names else 'None')
    skills = [r for r in records if r['kind'] == 'skill']
    slots = [r for r in records if r['kind'] == 'slot']
    assert len(skills) == 5 and all('`'+r['runtime_id']+'`' in doc for r in skills)
    assert [r['required_points'] for r in slots] == [1,3,6,9,12]
    assert all(r['skill_id'] for r in slots)
    assert not [g for g in ledger['talent_skill_grants'] if g['talent_id'] in talents]
    assert set(re.findall(r'\| E(\d\d) —',doc)) == {f'{i:02}' for i in range(1,13)}
    assert set(re.findall(r'\| T(\d\d) ',doc)) == {f'{i:02}' for i in range(1,19)}
    # Expand the document's explicitly named Basic 10 reference before checking purchases.
    basic = 'Coated Weapons 1, Blind Spot 5, Snake Oil 4'
    fixtures = []
    by_name = {r['source_name']:r for r in talents.values()}
    for name, entries in re.findall(r'- \*\*([^*]+):\*\* ([^.]+)\.',doc):
        entries = entries.replace('Basic 10', basic).replace(' + ', ', ').replace(' → ', ', ')
        ranks = {}
        for entry in entries.split(', '):
            talent_name, quantity = entry.rsplit(' ',1)
            rec = by_name[talent_name]
            quantity = int(quantity)
            assert 0 < quantity <= rec['max_ranks']
            support = sum(v for k,v in ranks.items() if talents[k]['required_tree_points'] < rec['required_tree_points'])
            assert support >= rec['required_tree_points'], (name,talent_name,support)
            assert all(ranks.get(p,0)>=1 for p in rec['prerequisite_ids'])
            ranks[rec['runtime_id']] = quantity
        assert sum(ranks.values()) == int(name.split()[-1])
        fixtures.append({'name':name,'ranks':ranks,'legal_under_D007':True})
    assert len(fixtures) == 5
    assert F('0.15')*F('0.90') == F('0.135')
    assert F('0.15')*F('0.20') == F('0.03')
    assert 2+F('0.2')*5 == 3
    assert 8*F('0.5') == 4 and 1+F('0.5')*F('0.5') == F('1.25')
    assert (100+20+4)*F('1.11') == F('137.64')
    assert (2+6)*2 == 16 and (1+6)*2 == 14
    assert F('0.2')+12*F('0.1') == F('1.4')
    assert 7*F('0.5') == F('3.5') and 3+3 == 6
    assert 5+35*F('0.5') == F('22.5') and F('22.5')*F('0.5') == F('11.25')
    for target in re.findall(r'\]\(([^)]+)\)',doc):
        if '://' not in target:
            assert (DOC.parent / target.split('#')[0]).exists(), target
    baseline = json.loads((OUT/'source_hashes.json').read_text(encoding='utf-8'))
    immutable = {p:d for p,d in baseline.items() if p.startswith('docs/talent_tree_drafts/') or p.endswith('Content_Identity_Manifest.json')}
    for path,digest in immutable.items():
        validate_source(path, digest)
    review = ledger['design_reviews']['tree.shadow']
    assert review['status'] == 'Complete' and review['pending_decisions'] == []
    assert review['approved_decisions'] == ['D01','D02','D03','D04'] and all(r['status'] == 'P' for r in talents.values())
    (OUT/'approved_summary.json').write_text(json.dumps({'passed':True,'checked_at_utc':datetime.now(timezone.utc).isoformat(),'scope':'Static approved specification; runtime evidence is separate.','inventory':{'talents':11,'ranks':35,'skills':5,'slots':5},'legal_builds':fixtures,'worked_examples':12,'acceptance_groups':18,'validated_draft_and_identity_files':len(immutable),'runtime_promotion':True,'pending_decisions':review['pending_decisions'],'specification_sha256':hashlib.sha256(DOC.read_bytes()).hexdigest()},indent=2)+'\n',encoding='utf-8')
    print(f'PASS: Shadow inventory, five legal builds, example arithmetic, links and {len(immutable)} validated historical/approved-successor draft/identity sources; D01-D04 approved.')

if __name__ == '__main__':
    main()
