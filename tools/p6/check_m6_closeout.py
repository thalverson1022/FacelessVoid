"""Check current M6 closeout against retained T10 evidence, not obsolete M5 hashes."""
import hashlib,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    baseline=json.loads((ROOT/'project/reports/p6_m6_t10/protected_before.json').read_text())
    test_repairs={'balance_lab_test.gd','combat_screen_test.gd','p6_core_journey_test.gd','save_load_ui_test.gd'}
    unchanged=[];repairs=[]
    for old,expected in baseline.items():
        relative='project/'+old.replace('\\','/').split('/project/',1)[1]
        path=ROOT/relative
        if digest(path)!=expected:
            assert relative.startswith('project/tests/') and path.name in test_repairs, 'Unapproved runtime drift: '+relative
            repairs.append({'path':relative,'before':expected,'after':digest(path)})
        else:unchanged.append(relative)
    text=lambda p:(ROOT/p).read_text(encoding='utf-8-sig')
    assert 'base_execution_ms = 1100' in text('project/data/skills/steal.tres')
    assert 'min_execution_ms = 650' in text('project/data/skills/steal.tres')
    buddy=text('project/data/monsters/drunk_buddy.tres')
    assert all(v in buddy for v in ['hp = 155','armor = 140','poison_resistance = 0.10'])
    assert 'duration_ms = 18000' in text('project/data/encounters/02_drunk_buddy.tres')
    assert 'physical_damage_per_gold = 0.1' in text('project/data/gear/bandit_blade.tres')
    assert 'user://adventure_p6_m6.json' in text('project/scripts/systems/save_system.gd')
    assert 'user://save.json' in text('project/scripts/systems/save_system.gd')
    assert 'p6.adventure.1' in text('project/scripts/systems/build_content_registry.gd')
    ledger=json.loads(text('docs/P6M5_T2_Content_Coverage_Ledger.json'))
    assert len(ledger['rank_slots'])==140 and all(r['status']=='P' for r in ledger['rank_slots'])
    assert len([r for r in ledger['records'] if r['kind']=='talent'])==44
    result={'pass':True,'unchanged_from_accepted_T10':len(unchanged),'test_repairs':repairs,'runtime_unchanged':True,'talents':44,'ranks':140,'note':'Historical M5 exact-hash checks are superseded by the accepted T10 protected snapshot. No candidate patch applied.'}
    out=ROOT/'project/reports/p6_m6_t11_static/current_baseline.json';out.parent.mkdir(exist_ok=True);out.write_text(json.dumps(result,indent=2))
    print('PASS current M6 baseline: '+str(len(unchanged))+' unchanged protected files; '+str(len(repairs))+' test-only repairs; 44 talents / 140 ranks')
if __name__=='__main__':main()
