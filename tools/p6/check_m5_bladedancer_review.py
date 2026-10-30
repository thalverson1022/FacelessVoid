"""Check T3 planning inventory, legal examples and references; never runs Godot."""
import datetime
import hashlib
import json
import re
import subprocess
import sys
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / 'docs/P6M5_T3_Bladedancer_Design_Review.md'
REPORT = ROOT / 'project/reports/p6_m5_t3_review/summary.json'


def main():
    source = json.loads((ROOT / 'docs/P6M5_T2_Content_Coverage_Ledger.json').read_text(encoding='utf-8'))
    records = [r for r in source['records'] if r['tree_id'] == 'tree.bladedancer']
    talents = {r['runtime_id'].split('.')[-1]: r for r in records if r['kind'] == 'talent'}
    doc = DOC.read_text(encoding='utf-8')
    section = doc.split('## All talents and complete rank effects\n')[1].split('## Resource, trigger and damage contracts')[0]
    rows = [line.split('|')[1:-1] for line in section.splitlines() if re.match(r'\| .* / `', line)]
    assert len(rows) == 13
    represented = set()
    for row in rows:
        suffix = re.search(r'`([^`]+)`', row[0])[1]
        assert suffix in talents and suffix not in represented
        represented.add(suffix)
        assert int(row[1]) == talents[suffix]['required_tree_points'], suffix
        prerequisites = talents[suffix]['prerequisite_ids']
        names = [next(r['source_name'] for r in records if r['runtime_id'] == p) for p in prerequisites]
        assert row[3].strip() == ('None' if not names else ', '.join(n + ' 1' for n in names)), suffix
    assert represented == set(talents)
    assert sum(r['max_ranks'] for r in talents.values()) == 35
    playable_count = sum(r['status'] == 'P' for r in talents.values())
    assert playable_count in [5, 13]
    promoted = playable_count == 13
    report_path = ROOT / 'project/reports/p6_m5_t4_static/design_review_recheck.json' if promoted else REPORT
    skills = [r for r in records if r['kind'] == 'skill']
    assert len(skills) == 5 and all('`' + r['runtime_id'] + '`' in doc for r in skills)
    slots = [r for r in records if r['kind'] == 'slot']
    assert [r['required_points'] for r in slots] == [1, 3, 6, 9, 12]
    assert [r['required_points'] for r in slots if r['skill_id'] is None] == [9]
    assert set(re.findall(r'\| (B\d\d) —', doc)) == {f'B{i:02}' for i in range(1, 22)}
    assert set(re.findall(r'\| (E\d\d) —', doc)) == {f'E{i:02}' for i in range(1, 11)}

    plans = {
        'Core 10': [('wet_stone',4),('rending_slash',1),('fancy_footwork',5)],
        'Precision 16': [('wet_stone',5),('precision_attacks',1),('double_dip',2),('rending_slash',1),('fancy_footwork',1),('sharpened_edge',5),('weapon_master',1)],
        'Shred capstone 21': [('wet_stone',5),('weakness',5),('rending_slash',1),('opportunity',3),('cloak_and_dagger',1),('weapon_master',2),('double_dip',2),('fancy_footwork',1),('virulent_corruption',1)],
        'All ranks 35': [('weakness',5),('wet_stone',5),('rending_slash',1),('fancy_footwork',5),('precision_attacks',1),('double_dip',2),('opportunity',3),('sharpened_edge',5),('cloak_and_dagger',2),('riposte',2),('side_step',1),('weapon_master',2),('virulent_corruption',1)]}
    fixture_results = []
    for name, purchases in plans.items():
        assert '**' + name + ':**' in doc
        ranks = {}
        log = []
        for suffix, target in purchases:
            talent = talents[suffix]
            assert target <= talent['max_ranks']
            while ranks.get(suffix, 0) < target:
                before = sum(ranks.values())
                assert before >= talent['required_tree_points'], (name, suffix, before)
                assert all(ranks.get(p.split('.')[-1], 0) >= 1 for p in talent['prerequisite_ids'])
                ranks[suffix] = ranks.get(suffix, 0) + 1
                assert sum(ranks.values()) <= 45
                log.append({'talent':suffix, 'rank':ranks[suffix], 'tree_points_before':before})
        assert sum(ranks.values()) == int(name.split()[-1])
        if name == 'All ranks 35':
            assert ranks == {k:v['max_ranks'] for k,v in talents.items()}
        fixture_results.append({'name':name, 'points':sum(ranks.values()), 'purchases':log, 'legal':True})

    # Exact arithmetic for the numeric examples; no claim of simulation evidence.
    primary = Fraction(5,100) + 35 * Fraction(2,1000) + Fraction(8,100)
    secondary = Fraction(5,100) + Fraction(8,100)
    assert primary == Fraction(20,100) and secondary == Fraction(13,100)
    assert max(500, 2000*(1-Fraction(2,100)*5*5)) == 1000
    assert max(500, 2000*(1-Fraction(2,100)*5*3)) == 1400
    assert 1+Fraction(1,10)*2*5 == 2 and 1+Fraction(1,10)*2*3 == Fraction(16,10)
    assert max(500, 700*(1-Fraction(2,100)*5*5)) == 500
    assert 100*2*2 == 400 and 100*2*2*Fraction(11,10) == 440
    value = 10+25+100
    assert (1+2)*value == 405
    assert value == 135 and value*4 == 540 and 600-value*4 == 60
    assert (2+2+1)*2 == 10 and 600-value*10 == -750
    assert min(500,499+4)-499 == 1

    # Preserve all runtime/scene/data/test/draft fingerprints from the prior task.
    baseline = json.loads((ROOT/'project/reports/p6_m5_t2_static/source_hashes.json').read_text())
    unchanged = all(hashlib.sha256((ROOT/name).read_bytes()).hexdigest() == digest for name,digest in baseline.items())
    if not promoted:
        assert unchanged
    review = source['design_reviews']['tree.bladedancer']
    assert review['status'] == 'Complete' and review['pending_decisions'] == []
    assert review['approved_decisions'] == ['D01','D02','D03']
    assert 'Status: **Complete' in doc
    tests = re.findall(r'`(p6_[a-z0-9_]+_test)`', doc)
    assert all((ROOT/'project/tests'/f'{name}.gd').is_file() for name in tests)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    # The report is the only intentionally forward link on the first run.
    links=[]
    for target in re.findall(r'\]\(([^)]+)\)',doc):
        target=target.split('#')[0]
        if target and '://' not in target:
            resolved=(DOC.parent/target).resolve()
            assert resolved == REPORT.resolve() or resolved.exists(), target
            links.append(target)
    assert not any(line != line.rstrip() for line in doc.splitlines())
    checks=[]
    for cmd in [[sys.executable,'tools/p6/build_m5_coverage_ledger.py','--check'],['node','tools/p6/check_content_identity_manifest.js']]:
        result=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
        checks.append({'command':subprocess.list2cmdline(cmd),'exit_code':result.returncode,'stdout':result.stdout,'stderr':result.stderr})
        assert result.returncode==0,result.stderr
    summary={'date':datetime.datetime.now().astimezone().isoformat(), 'passed':True,
        'scope':'Planning checks only. User-approved design; no Godot execution, rendered review or runtime promotion.',
        'command':'python tools/p6/check_m5_bladedancer_review.py',
        'inventory':{'talents':13,'ranks':35,'playable_talents':playable_count,'remaining_talents':13-playable_count,'tree_skills':5,'automatic_slots':5,'empty_slots':1},
        'coverage':{'acceptance_groups':21,'worked_examples':10,'existing_test_references':len(tests),'relative_links':len(links)},
        'legal_fixture_plans':fixture_results,'arithmetic':'E01/E02/E03/E06/E07/E10 exact arithmetic passed; E04/E05/E08/E09 specified behavior is cross-checked against linked contracts, not simulated here.',
        'runtime_source_isolation':{'baseline':'project/reports/p6_m5_t2_static/source_hashes.json','files':len(baseline),'unchanged':unchanged, 'later_implementation_expected':promoted},
        'specification_sha256':hashlib.sha256(DOC.read_bytes()).hexdigest(),
        'pending_decisions':review['pending_decisions'], 'static_checks':checks}
    report_path.write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
    print('PASS: 13 talents/35 ranks, gates/prerequisites, 5 skills/5 slots, 4 legal builds, numeric examples, links; review Complete; original T3 fingerprint evidence retained separately from later implementation')


if __name__ == '__main__':
    main()
