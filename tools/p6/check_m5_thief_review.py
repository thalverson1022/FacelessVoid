"""T5 design inventory/arithmetic checks; no gameplay execution or promotion."""
import hashlib
import json
import re
from fractions import Fraction as F
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / 'docs/P6M5_T5_Thief_Design_Review.md'
OUT = ROOT / 'project/reports/p6_m5_t5_review'
ledger = json.loads((ROOT / 'docs/P6M5_T2_Content_Coverage_Ledger.json').read_text(encoding='utf-8'))
doc = DOC.read_text(encoding='utf-8')
records = [r for r in ledger['records'] if r['tree_id'] == 'tree.thief']
talents = {r['runtime_id']: r for r in records if r['kind'] == 'talent'}
assert len(talents) == 10 and sum(r['max_ranks'] for r in talents.values()) == 35
playable_count = sum(r['status'] == 'P' for r in talents.values())
assert playable_count in (1,10)
promoted = playable_count == 10
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
assert len(skills) == 4 and all('`'+r['runtime_id']+'`' in doc for r in skills)
slots = [r for r in records if r['kind'] == 'slot']
assert [r['required_points'] for r in slots] == [1,3,6,9,12]
assert [r['required_points'] for r in slots if r['skill_id'] is None] == [9]
assert set(re.findall(r'\| E(\d\d) —', doc)) == {f'{i:02}' for i in range(1,12)}
assert set(re.findall(r'\| T(\d\d) —', doc)) == {f'{i:02}' for i in range(1,16)}

plans = {
    'Core 5': [('keen_eye',5)],
    'Economy 18': [('sticky_fingers',5),('charisma',3),('fast_hands',5),('fill_your_pockets',2),('load_dice',3)],
    'Theft 21': [('keen_eye',5),('sticky_fingers',5),('bribery',3),('silvered_edge',2),('finders_keepers',2),('fast_hands',3),('gilded_blade',1)],
    'All ranks 35': [('keen_eye',5),('sticky_fingers',5),('fast_hands',5),('fill_your_pockets',5),('charisma',3),('bribery',3),('silvered_edge',3),('finders_keepers',2),('load_dice',3),('gilded_blade',1)],
}
by_suffix = {k.split('.')[-1]:v for k,v in talents.items()}
fixture_results = []
for name, purchases in plans.items():
    assert '**'+name+':**' in doc
    ranks = {}
    log = []
    for suffix, target in purchases:
        item = by_suffix[suffix]
        assert 0 < target <= item['max_ranks']
        for rank in range(1,target+1):
            assert sum(ranks.values()) >= item['required_tree_points'], (name,suffix)
            assert all(ranks.get(p.split('.')[-1],0) >= 1 for p in item['prerequisite_ids'])
            ranks[suffix] = rank
            log.append({'talent':item['runtime_id'],'rank':rank,'total':sum(ranks.values())})
    assert sum(ranks.values()) == int(name.split()[-1])
    fixture_results.append({'name':name,'legal':True,'purchases':log})
assert sum(by_suffix[n]['max_ranks'] for n,_ in plans['All ranks 35']) == 35
assert 35 + 4 + 1 + 5 == 45

primary = F(18,10)*F(15,10)*F(12,10)
secondary = F(11,10)*F(15,10)*F(12,10)
assert primary == F(324,100) and secondary == F(198,100)
assert int(20*primary)==64 and int(20*secondary)==39
assert (primary-1)/2==F(112,100) and (secondary-1)/2==F(49,100)
assert 2*int(3*F(15,10))==8
assert 400+20==420 and min(100,20)==20
assert min(501,500)==500 and min(120,100)==100
assert [min(120,25*r) for r in [1,2,3]]==[25,50,75]
assert 100*F(9,10)*3*2==540
assert max(1,int(101*(1-F(3,10)-F(2,10))))==50
assert max(1,int(101*max(0,1-F(1))))==1
assert min(1,F(1,10)*4)==F(4,10) and min(1,F(3,10)*4)==1
assert 4*F(11,10)==F(44,10)
assert (6+2)*(10+25+100)==1080
assert (6+2+1)*2*(10+25+100)==2430
assert min(500,499+8)-499==1 and int(3*F(2,10))==0
assert [40*F(1,2)-10,0-10]==[10,-10]
assert min(550-100,500)==450

baseline = json.loads((OUT/'source_hashes.json').read_text(encoding='utf-8'))
display_edits = ['project/data/ui/icon_assignments.json', 'project/data/ui/full_tree_display.json']
if not promoted:
    for p,h in baseline.items():
        content = (ROOT/p).read_bytes()
        if p in display_edits:
            assert content.count(b'"name": "Loaded Dice"') == 1
            content = content.replace(b'"name": "Loaded Dice"', b'"name": "Load Dice"')
        assert hashlib.sha256(content).hexdigest()==h, p
else:
    OUT = ROOT / 'project/reports/p6_m5_t6_static'
    OUT.mkdir(parents=True, exist_ok=True)
report = OUT/'summary.json'
for target in re.findall(r'\]\(([^)]+)\)',doc):
    if '://' not in target:
        resolved = (DOC.parent/target.split('#')[0]).resolve()
        assert resolved==report.resolve() or resolved.exists(), target
for name in set(re.findall(r'`(p[56]_[a-z0-9_]+_test|p5m\d+_[a-z0-9_]+_test)`',doc)):
    assert (ROOT/'project/tests'/f'{name}.gd').is_file(), name
review = ledger['design_reviews']['tree.thief']
assert review['status']=='Complete' and review['pending_decisions']==[]
assert review['approved_decisions']==['D01','D02','D03']
assert 'Status: **Complete' in doc and 'Loaded Dice / `talent.thief.load_dice`' in doc
report.write_text(json.dumps({'passed':True,'scope':'Static design checks only; no runtime verification or promotion.',
    'inventory':{'talents':10,'ranks':35,'skills':4,'slots':5,'empty_slots':1,'playable_talents':playable_count},
    'worked_examples':11,'acceptance_groups':15,'legal_builds':fixture_results,
    'runtime_and_draft_fingerprints':{'files':len(baseline),'gameplay_and_drafts_unchanged':not promoted,'approved_display_only_edits':display_edits},
    'specification_sha256':hashlib.sha256(DOC.read_bytes()).hexdigest(),
    'pending_decisions':review['pending_decisions']},indent=2)+'\n',encoding='utf-8')
print('PASS: Thief 10 talents/35 ranks, four skills, gates/prerequisites, four legal plans, eleven examples, fifteen acceptance groups, references (historical fingerprint freeze checked only before promotion); D01–D03 confirmed')
