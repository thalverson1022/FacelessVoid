"""Generate/check the M5-T2 audit snapshot. No game resources or saves are written.

Annotations are reviewed audit conclusions, not inferred executable mechanics.
--check detects source drift and incomplete identities/ranks/evidence references.
"""
import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path
from source_provenance import validate_source

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'docs/P6M5_T2_Content_Coverage_Ledger.json'
VIEW = ROOT / 'docs/P6M5_T2_Content_Coverage_Ledger.md'
MANIFEST = 'docs/P6M2_T4_Content_Identity_Manifest.json'
PLAN = 'P6M5_T2_Content_Reconciliation_And_Coverage_Plan.md'
OWNERS = {'assassin': ['T7', 'T7'], 'bladedancer': ['T3', 'T4'], 'shadow': ['T8', 'T8'], 'thief': ['T5', 'T6']}
CONTRACTS = {
    'build': 'docs/P6M2_T3_Progression_And_Allocation_Rules.md',
    'stats': 'docs/P6M3_T3_Stat_Derivation_And_Temporary_Modifiers.md',
    'buff': 'docs/P6M3_T4_Timed_Effects_And_Charges.md',
    'repeat': 'docs/P6M3_T6_Triggers_Repeats_And_Critical_Interactions.md',
    'status': 'docs/P6M3_T7_Status_And_Mitigation_Interactions.md',
    'poison': 'docs/P6M3_T9_Poison_Timing_And_Consumption.md',
    'gold': 'docs/P6M3_T10_Gold_And_Mixed_Build_Handoff.md',
    'core': 'docs/P6M4_T8_Core_End_To_End_Acceptance.md',
    'mixed': 'docs/P6M4_T9_Mixed_Playable_Integration.md',
}
# P = playable subset; S = shared support but no released binding; R = content review needed.
# Every non-P talent remains unavailable regardless of existence in legacy/representative fixtures.
# name: status, contract, validation family, implementation evidence, targeted reconciliation
TALENTS = {
    'Quick Hands': ('S', 'build', 'V02', 'build_resolver.gd', 'Canonical IAS modifier exists; review and author complete 1..5% ranks.'),
    'Precision': ('S', 'build', 'V02', 'build_resolver.gd', 'Canonical crit chance exists; 1..5 percentage points are draft rank inputs, not the Precision charge mechanic.'),
    'Hastened Poison': ('S', 'poison', 'V05', 'p6_poison_contracts.gd', 'Reviewed 10% IAS contribution per rank; add rank-to-PlayerStats binding.'),
    'Echoing Toxin': ('S', 'poison', 'V05', 'p6_poison_contracts.gd', 'Reviewed 10/20/30% separate multiplier and two-stack depletion; not keyword Consume.'),
    'Poison Strike': ('S', 'poison', 'V05', 'p6_poison_contracts.gd', 'Bind talent grant to reviewed forced-tick descriptor, not inherited same-ID resource.'),
    'Bypass': ('S', 'buff', 'V03', 'combat_talent_buffs.gd', 'Reviewed Stab grant, three-stack cap, three-second timer and 1+0.1*n elemental multiplier; binding absent.'),
    'Toxic Tradeoff': ('R', 'stats', 'V02', 'build_resolver.gd', 'Q03: approve poison-versus-elemental scope, modifier buckets and provisional +20/-10% per rank; generic modifiers alone do not settle it.'),
    'Accelerant': ('S', 'poison', 'V05', 'p6_poison_contracts.gd', 'Reviewed additive cadence contribution; requires Hastened rank >=1; binding absent.'),
    'Resonance': ('S', 'poison', 'V05', 'p6_poison_contracts.gd', 'Reviewed three-stack replacement fuel and separate 20/40/60/80% multiplier; requires Echoing; binding absent.'),
    'Critical Poison': ('S', 'poison', 'V05', 'p6_poison_contracts.gd', 'One live crit roll per fueled natural/forced tick; does not invoke direct-hit crit hook; binding absent.'),
    'Weakness': ('P', 'stats', 'V02', '../data/p6/bladedancer/weakness.tres', 'Approved T3 values bound and validated by p6_full_bladedancer_test; see T4 closeout.'),
    'Whetstone': ('P', 'stats', 'V02', '../data/p6/test_mode/whetstone.tres', 'Authored +1 base physical per rank; retain stable wet_stone ID and approved display spelling.'),
    'Opportunity': ('P', 'repeat', 'V04', 'playable_mixed_content.gd', 'Authored 10/20/30% Quick Cut proc; Rending prerequisite; inherited exact mixed evidence uses rank 3.'),
    'Virulent Corruption': ('P', 'status', 'V06', '../data/p6/bladedancer/virulent_corruption.tres', 'Approved T3 values bound and validated by p6_full_bladedancer_test; see T4 closeout.'),
    'Rending Slash': ('P', 'repeat', 'V04', '../data/p6/test_mode/rending_slash.tres', 'One-rank grant to stable skill.rending_thrust; same-ID compatibility resource intentionally reused.'),
    'Fancy Footwork': ('P', 'buff', 'V03', '../data/p6/test_mode/fancy_footwork.tres', 'Draft 10..50% display means full five-stack reduction; current D018 formula is 4% * rank * consumed stacks, minimum 500 ms.'),
    'Precision Attacks': ('P', 'repeat', 'V04', '../data/p6/bladedancer/precision_attacks.tres', 'Approved T3 values bound and validated by p6_full_bladedancer_test; see T4 closeout.'),
    'Double Dip': ('P', 'stats', 'V02', '../data/p6/bladedancer/double_dip.tres', 'Approved T3 values bound and validated by p6_full_bladedancer_test; see T4 closeout.'),
    'Sharpened Edge': ('P', 'stats', 'V02', '../data/p6/bladedancer/sharpened_edge.tres', 'Approved T3 values bound and validated by p6_full_bladedancer_test; see T4 closeout.'),
    'Cloak & Dagger': ('P', 'gold', 'V02', 'playable_mixed_content.gd', 'Authored +50/+100 percentage-point crit damage; exact mixed evidence uses rank 2.'),
    'Riposte': ('P', 'buff', 'V03', '../data/p6/bladedancer/riposte.tres', 'Approved T3 values bound and validated by p6_full_bladedancer_test; see T4 closeout.'),
    'Side Step': ('P', 'repeat', 'V04', '../data/p6/bladedancer/side_step.tres', 'Approved T3 values bound and validated by p6_full_bladedancer_test; see T4 closeout.'),
    'Weapon Master': ('P', 'stats', 'V02', '../data/p6/bladedancer/weapon_master.tres', 'Approved T3 values bound and validated by p6_full_bladedancer_test; see T4 closeout.'),
    'Umbral Presence': ('S', 'status', 'V06', 'p6_status_skill_contracts.gd', 'Reviewed cap at least 80; legacy cap-40 special is not a valid redesigned binding.'),
    'Coated Weapons': ('S', 'repeat', 'V04', 'build_resolver.gd', 'SkillAugment supports Stab/Heavy Slash Poison; verify all-source Stab suppression under Death Blade.'),
    'Blind Spot': ('S', 'stats', 'V02', 'build_resolver.gd', 'Canonical crit chance exists; review/author draft 2..10 percentage-point ranks.'),
    'Snake Oil': ('S', 'stats', 'V02', 'build_resolver.gd', 'Canonical base elemental modifier exists; review/author draft +2/+4/+6/+8 and Shadow Mastery source attribution.'),
    'Death Touch': ('S', 'status', 'V06', 'p6_status_skill_contracts.gd', 'Reviewed +2/+4/+6 eligible stacks, not every charge/Consume conversion; canonical all-stack route exists.'),
    'Dusk Strike': ('S', 'status', 'V06', 'combat_resolver.gd', 'Bind Decay-to-Shred enablement AND independent_decay_shred; legacy copied Decay quantity is not redesigned rule.'),
    'Shadow Mastery': ('S', 'stats', 'V02', 'combat_stat_state.gd', 'Copy, not remove, elemental flat bonuses and effective percent bonus; exclude class Poison base; author 10..50% ranks.'),
    'Deception': ('S', 'stats', 'V02', 'build_resolver.gd', 'Canonical elemental multiplier exists; review/author 10..50% ranks and Snake Oil prerequisite.'),
    'Death from the Shadows': ('S', 'stats', 'V02', 'build_resolver.gd', 'Canonical crit damage exists; review/author +20..100 percentage-point ranks.'),
    'Death Pact': ('S', 'status', 'V06', 'combat_defense_debuffs.gd', 'Draft buff/%/2-4-6 wording superseded: actual Consume grants both defense debuffs, durations 4/5/6 seconds; add rank carrier.'),
    'Death Blade': ('S', 'repeat', 'V04', 'combat_resolver.gd', 'Reviewed application-based proc and all-source Stab Poison suppression; bind enabled/chance fields for 10/20% ranks.'),
    'Gilded Blade': ('P', 'gold', 'V07', '../data/p6/thief/gilded_blade.tres', 'Approved T5 ranks implemented; T6 allocation, combat, economy and player-flow evidence.'),
    'Keen Eye': ('P', 'gold', 'V02', 'playable_mixed_content.gd', 'Authored +2..10% physical and elemental, established buckets; exact mixed uses rank 5.'),
    'Sticky Fingers': ('P', 'gold', 'V07', '../data/p6/thief/sticky_fingers.tres', 'Approved T5 ranks implemented; T6 allocation, combat, economy and player-flow evidence.'),
    'Silvered Edge': ('P', 'gold', 'V07', '../data/p6/thief/silvered_edge.tres', 'Approved T5 ranks implemented; T6 allocation, combat, economy and player-flow evidence.'),
    'Fast Hands': ('P', 'gold', 'V07', '../data/p6/thief/fast_hands.tres', 'Approved T5 ranks implemented; T6 allocation, combat, economy and player-flow evidence.'),
    'Fill Your Pockets': ('P', 'gold', 'V07', '../data/p6/thief/fill_your_pockets.tres', 'Approved T5 ranks implemented; T6 allocation, combat, economy and player-flow evidence.'),
    'Charisma': ('P', 'gold', 'V07', '../data/p6/thief/charisma.tres', 'Approved T5 ranks implemented; T6 allocation, combat, economy and player-flow evidence.'),
    'Load Dice': ('P', 'gold', 'V07', '../data/p6/thief/load_dice.tres', 'Approved T5 ranks implemented; T6 allocation, combat, economy and player-flow evidence.'),
    'Bribery': ('P', 'gold', 'V07', '../data/p6/thief/bribery.tres', 'Approved T5 ranks implemented; T6 allocation, combat, economy and player-flow evidence.'),
    'Finders Keepers': ('P', 'gold', 'V07', '../data/p6/thief/finders_keepers.tres', 'Approved T5 ranks implemented; T6 allocation, combat, economy and player-flow evidence.'),
}
for _name, _suffix in {'Quick Hands':'quick_hands','Precision':'precision','Hastened Poison':'hastened_poison','Echoing Toxin':'echoing_toxin','Poison Strike':'poison_strike','Bypass':'bypass','Toxic Tradeoff':'toxic_tradeoff','Accelerant':'accelerant','Resonance':'resonance','Critical Poison':'critical_poison'}.items():
    _old = TALENTS[_name]
    TALENTS[_name] = ('P', _old[1], _old[2], '../data/p6/assassin/' + _suffix + '.tres', 'P6M5-D009 content and D010 balance approved; T7 allocated rank/combat/journey evidence. ' + ('Poison-only tick multiplier, separate physical penalty before conversion.' if _suffix == 'toxic_tradeoff' else 'Full Assassin binding.'))

for _name, _suffix in {'Umbral Presence': 'umbral_presence', 'Coated Weapons': 'coated_weapons', 'Blind Spot': 'blind_spot', 'Snake Oil': 'snake_oil', 'Death Touch': 'death_touch', 'Dusk Strike': 'dusk_strike', 'Shadow Mastery': 'shadow_mastery', 'Deception': 'deception', 'Death from the Shadows': 'death_from_the_shadows', 'Death Pact': 'death_pact', 'Death Blade': 'death_blade'}.items():
    _old = TALENTS[_name]
    TALENTS[_name] = ('P', _old[1], _old[2], '../data/p6/shadow/' + _suffix + '.tres', 'P6M5-D011 approved; T8 complete rank, combat, boundary and player-flow evidence.')

SKILLS = {
    'skill.venom_jab': ('R', 'build', 'V05', '../data/skills/venom_jab.tres', 'Q01: draft five Poison versus inherited eight; full damage/timing descriptor review required.'),
    'skill.blinding_powder': ('S', 'status', 'V06', 'combat_resolver.gd', 'D013 Debuff 1200/500 ms, no cooldown; Potency uses invested Assassin points in both roles, capped at 50.'),
    'skill.virulent_poison': ('S', 'status', 'V05', 'p6_status_skill_contracts.gd', 'D014 Self Buff 500/500 ms, 10 s cooldown after completion; independent five-charge 2x instances.'),
    'skill.master_of_poisons': ('S', 'status', 'V06', 'p6_status_skill_contracts.gd', 'Reviewed Self Buff 500/500 ms, 10 s cooldown, five-second resistance ignore.'),
    'skill.poison_vile': ('S', 'status', 'V05', 'p6_status_skill_contracts.gd', 'Reviewed Debuff 1800/500 ms, no cooldown, twenty base Poison; preserve authored name.'),
    'skill.poison_strike': ('S', 'poison', 'V05', 'p6_poison_contracts.gd', 'Reviewed Attack 83%, 1200/500 ms, no cooldown; fueled forced tick; inherited resource lacks this adapter effect.'),
    'skill.quick_cut': ('P', 'repeat', 'V04', '../data/skills/quick_cut.tres', 'Reviewed Attack 66%, 850/500 ms; additional passive grants require actual bound talents.'),
    'skill.leaping_plunge': ('P', 'buff', 'V03', '../data/p6/test_mode/leaping_plunge.tres', 'Reviewed Attack 190%, 2500/500 ms; consumes Footwork at cast start.'),
    'skill.parry_strike': ('P', 'repeat', 'V03', '../data/p6/test_mode/parry_strike.tres', 'Reviewed Attack 120%, 500/300 ms; unlock enables Readiness and cast requires it.'),
    'skill.dance_of_death': ('P', 'repeat', 'V04', 'p6_thief_contracts.gd', 'Reviewed Self Buff 500/500 ms, 20 s cooldown, five-second macro-only guarantee.'),
    'skill.rending_thrust': ('P', 'repeat', 'V04', '../data/skills/rending_slash.tres', 'Rending Slash stable ID; Attack 78%, 1400/650 ms, two base Shred.'),
    'skill.toxic_flurry': ('R', 'status', 'V06', '../data/skills/beguiling_strike.tres', 'Q02: inherited Beguiling Strike resistance effect already requests one Decay in the resolver; full redesigned damage/timing descriptor and provenance still need T8 certification.'),
    'skill.killers_mark': ('R', 'build', 'V06', '../data/skills/death_strike.tres', 'Q04: inherited Death Strike physical plus Poison-stack scaling exists; certify full redesigned descriptor, timing and non-Consume behavior in T8.'),
    'skill.distilled_corruption': ('R', 'status', 'V06', '../resources/consume_status_effect.gd', 'Q05: consume up to five Decay/conversion settled; full attack scaling, timing and descriptor remain unapproved.'),
    'skill.touch_of_darkness': ('S', 'buff', 'V03', 'p6_status_skill_contracts.gd', 'Reviewed Self Buff 500/500 ms, 30 s cooldown; actual Poison Consume gives +10% additive IAS each for eight seconds.'),
    'skill.beguiling_presence': ('S', 'status', 'V06', 'p6_status_skill_contracts.gd', 'Reviewed Self Buff 500/500 ms, 30 s cooldown; actual Decay Consume gives +1 elemental base each for ten seconds.'),
    'skill.steal': ('P', 'gold', 'V07', '../data/skills/steal.tres', 'Reviewed Attack 106%, 1300/650 ms; critical connected hit steals three raw gold.'),
    'skill.mug': ('P', 'gold', 'V07', 'p6_thief_contracts.gd', 'Reviewed Attack 100%, 1500/700 ms; adds credited fight theft to physical base, cap 50; P6M5-D008.'),
    'skill.pick_pocket': ('P', 'gold', 'V07', 'p6_thief_contracts.gd', 'Draft low damage superseded: zero-damage Debuff 1800/800 ms, ten raw gold, no cooldown.'),
    'skill.big_score': ('P', 'gold', 'V07', 'p6_thief_contracts.gd', 'Reviewed Attack 90%, 1800/700 ms, no cooldown; doubles full live crit multiplier on crit.'),
}
for _id in ['venom_jab','blinding_powder','virulent_poison','master_of_poisons','poison_vile','poison_strike']:
    _old = SKILLS['skill.' + _id]
    SKILLS['skill.' + _id] = ('P', _old[1], _old[2], 'playable_assassin_content.gd', 'T7 reviewed production descriptor and allocated acceptance; P6M5-D009. ' + ('Venom Jab: five Poison, 22% weapon, 1000/500 ms, no cooldown.' if _id == 'venom_jab' else _old[4]))

for _id in ['skill.toxic_flurry','skill.killers_mark','skill.distilled_corruption','skill.touch_of_darkness','skill.beguiling_presence']:
    _old = SKILLS[_id]
    SKILLS[_id] = ('P', _old[1], _old[2], 'playable_shadow_content.gd', 'P6M5-D011 full descriptor approved and implemented; T8 allocation/combat/journey evidence.')

TESTS = {
    'V01': ['p6_full_assassin_test', 'p6_assassin_boundaries_test', 'p6_full_assassin_journey_test', 'p6_full_bladedancer_test', 'p6_full_bladedancer_journey_test', 'p6_ranked_build_test', 'p6_foundation_integration_test', 'p6_full_tree_display_test'],
    'V02': ['p6_stat_derivation_test', 'p6_stat_sources_test', 'p6_bladedancer_core_test', 'p6_gold_contract_test'],
    'V03': ['p6_effect_lifecycle_test', 'p6_effect_combat_test', 'p6_t4_completion_test', 'p6_macro_scheduler_test', 'p6_cooldown_scheduler_test'],
    'V04': ['p6_repeat_contracts_test', 'p6_trigger_origins_test', 'p6_combat_ordering_test', 'p6_combat_failure_consumers_test'],
    'V05': ['p6_poison_contract_test', 'p6_status_completion_test'],
    'V06': ['p6_status_accounting_test', 'p6_status_interactions_test', 'p6_status_completion_test', 'p6_t4_completion_test'],
    'V07': ['p6_full_thief_test', 'p6_thief_economy_test', 'p6_full_thief_journey_test', 'p6_gold_contract_test', 'p6_status_completion_test', 'p5m7_gold_gain_economy_test', 'p5m11_overkill_gold_test'],
    'V08': ['p5m11_economy_stats_test', 'p6_stat_derivation_test'],
    'V09': ['p6_core_journey_test', 'p6_mixed_journey_test', 'p6_persistence_test', 'p6_save_boundary_integration_test', 'p6_balance_adapter_test'],
    'V10': ['p6_t10_usability_test', 'p6_skill_ui_test', 'p6_combat_presentation_test'],
}


def read(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8-sig'))


def evidence_path(value):
    if value.startswith('../data/'):
        return 'project/' + value[3:]
    if value.startswith('../resources/'):
        return 'project/scripts/' + value[3:]
    return 'project/scripts/systems/' + value


def make():
    manifest = read(MANIFEST)
    # Preserve historical identity hashes; allow only the reviewed D023 successor.
    current_sources = {}
    for source in manifest['sources']:
        path = source['file']
        validate_source(path, source['sha256'])
        current_sources[path] = hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
    source_data = {s['file']: read(s['file']) for s in manifest['sources']}
    rows, ranks, grants = [], [], []
    for rec in manifest['records']:
        obj = source_data[rec['source_file']]
        for part in rec['pointer'].strip('/').split('/'):
            obj = obj[int(part)] if isinstance(obj, list) else obj[part]
        tree = rec['tree_id'].split('.')[1]
        row = dict(rec)
        row.update(review_owner=OWNERS[tree][0], implementation_owner=OWNERS[tree][1],
                   validation=['V01', 'V09', 'V10'], dependencies=['B01', 'B03', 'B04'],
                   source_sha256=current_sources[rec['source_file']],
                   identity_source_sha256=next(s['sha256'] for s in manifest['sources'] if s['file'] == rec['source_file']))
        kind = rec['kind']
        if kind in ('talent', 'skill'):
            name = obj['name'].strip()
            spec = TALENTS[name] if kind == 'talent' else SKILLS[rec['runtime_id']]
            status, contract, family, impl, note = spec
            row.update(status=status, contract=CONTRACTS[contract], implementation_evidence=[evidence_path(impl)],
                       reconciliation=note, validation=list(dict.fromkeys(row['validation'] + [family])),
                       draft_description=obj['description'])
            row['existing_test_candidates'] = [f'project/tests/{t}.gd' for t in TESTS[family]]
            if kind == 'talent':
                row['display_status'] = 'playable' if status == 'P' else ('preview' if tree in ['bladedancer', 'thief'] else 'not_in_current_display_catalog')
                row['max_ranks'] = obj['max_ranks']
                tree_obj = source_data[rec['source_file']]['tree']
                row['required_tree_points'] = next(x['required_points'] for x in tree_obj['levels'] if x['id'] == obj['level_id'])
                row['prerequisite_ids'] = [next(x['runtime_id'] for x in manifest['records'] if x['source_file'] == rec['source_file'] and x['kind'] == 'talent' and x['source_id'] == pre) for pre in obj['prerequisite_ids']]
                row['dependencies'] += row['prerequisite_ids']
                if status != 'P':
                    row['dependencies'].append('B02')
                row['rank_coverage'] = 'Owning full-tree suite exercises legal rank allocation/refund and bindings; mixed/player journeys sample complete builds. See M5-T11 acceptance map for final suite reconciliation.' if status == 'P' else 'Every rank requires allocation-to-combat validation; shared tests do not certify full node binding.'
                for rank in range(1, obj['max_ranks'] + 1):
                    ranks.append({'talent_id': rec['runtime_id'], 'rank': rank, 'status': status,
                        'review_owner': row['review_owner'], 'implementation_owner': row['implementation_owner'],
                        'dependencies': row['dependencies'], 'validation': row['validation'],
                        'contract': row['contract'], 'reconciliation': note,
                        'draft_values_not_runtime_approval': [dict(id=v['id'], label=v['label'], unit=v['unit'], value=v['rank_1'] + (rank-1)*v['per_rank']) for v in obj['values']],
                        'planned_case': f"{rec['runtime_id']}@{rank}: buy legally, resolve complete rank (not sum), verify effects/description, refund and restore; apply owning validation-family boundaries.",
                        'existing_evidence_scope': row['rank_coverage']})
                if obj['skill_grant']:
                    skill = next(x for x in manifest['records'] if x['source_file'] == rec['source_file'] and x['pointer'] == rec['pointer'] + '/skill_grant')
                    grants.append({'talent_id': rec['runtime_id'], 'skill_id': skill['runtime_id'], 'rank': 1, 'status': status,
                        'review_owner': row['review_owner'], 'implementation_owner': row['implementation_owner'],
                        'dependencies': [rec['runtime_id'], skill['runtime_id']], 'validation': ['V01', 'V09', 'V10']})
        elif kind == 'intrinsic':
            notes = {
                'assassin': ('P', 'D010: flat +5 elemental base and +0.5 per primary point; misleading source increased/poison key is not a percent handler.'),
                'bladedancer': ('P', 'Base retrigger 5% plus 0.2 percentage points per primary point; current tree resource binds both.'),
                'shadow': ('P', '20% conditional direct-critical-hit Poison chance plus 2 percentage points per primary point; both roles and all investment boundaries verified in T8.'),
                'thief': ('P', 'Base Increased Gold 10% plus 2 percentage points per primary point; mixed registry binds both in intrinsic bucket.'),
            }
            row.update(status=notes[tree][0], reconciliation=notes[tree][1], contract=CONTRACTS['build'],
                       draft_description=obj['description'], validation=['V01', 'V02', 'V04' if tree == 'shadow' else 'V07' if tree == 'thief' else 'V02', 'V09', 'V10'],
                       implementation_evidence=['project/scripts/systems/build_resolver.gd', 'project/scripts/systems/ranked_build.gd'],
                       existing_test_candidates=['project/tests/p6_ranked_build_test.gd', 'project/tests/p6_mixed_journey_test.gd'])
        elif kind == 'slot':
            skill = next((x for x in manifest['records'] if x['source_file'] == rec['source_file'] and x['pointer'] == rec['pointer']+'/skill'), None)
            row.update(required_points=obj['required_points'], skill_id=skill['runtime_id'] if skill else None,
                       status='E' if not skill else ('P' if SKILLS[skill['runtime_id']][0] == 'P' else 'S'),
                       contract=CONTRACTS['build'], implementation_evidence=['project/scripts/systems/ranked_build.gd'],
                       existing_test_candidates=['project/tests/p6_ranked_build_test.gd'],
                       reconciliation='Intentionally empty: grant nothing and do not block the 12-point slot. Thief registry explicitly preserves its empty nine-point slot.' if not skill else 'Check points immediately below/at/above threshold, both roles; promote only with referenced skill, refund/prune and alternate-grant retention.')
            row['dependencies'] += [skill['runtime_id']] if skill else []
        else:
            row.update(status='P' if tree in ['bladedancer','thief','assassin','shadow'] else 'S', contract=CONTRACTS['build'],
                       implementation_evidence=['project/scripts/systems/build_content_registry.gd'],
                       existing_test_candidates=['project/tests/p6_ranked_build_test.gd'],
                       reconciliation=('Complete reviewed Bladedancer tree; T4 allocation/combat evidence.' if tree == 'bladedancer' else 'Complete reviewed Assassin tree; T7 evidence.' if tree == 'assassin' else 'Complete reviewed Shadow tree; T8 rank/combat/journey evidence.' if tree == 'shadow' else 'Complete reviewed Thief tree; T6 allocation/combat/economy evidence.') if tree in ['bladedancer','thief','assassin','shadow'] else 'Redesigned tree absent from current playable registry; compatibility/representative tree is not promotion.')
        if row['runtime_id'] == 'talent.thief.load_dice':
            row['approved_display_name'] = 'Loaded Dice'
            row['reconciliation'] = 'P6M5-D004 approves +100/200/300% Magic Find and Loaded Dice display name; stable ID retained. Shop/reward and derived damage validation passed in T6.'
        if tree == 'shadow':
            row['existing_test_candidates'] += ['project/tests/p6_full_shadow_test.gd', 'project/tests/p6_shadow_boundaries_test.gd', 'project/tests/p6_full_shadow_journey_test.gd']
        rows.append(row)
    assert len(rows) == 92 and len(ranks) == 140 and len(grants) == 2
    assert len({r['runtime_id'] for r in rows}) == len(rows)
    assert Counter(r['kind'] for r in rows) == {'tree':4,'intrinsic':4,'talent':44,'slot':20,'skill':20}
    assert Counter(r['status'] for r in rows if r['kind']=='talent')['P'] == 44
    assert sum(r['status']=='P' for r in ranks) == 140
    assert sum(r['status']=='E' for r in rows) == 2
    assert {r['source_name'].strip() for r in rows if r['kind']=='talent'} == set(TALENTS)
    assert {r['runtime_id'] for r in rows if r['kind']=='skill'} == set(SKILLS)
    tracked = {MANIFEST, 'docs/Combat_Mechanics_Reference.md', 'project/scripts/resources/talent_rank.gd',
               'project/scripts/resources/player_stats.gd', 'project/scripts/resources/stat_derivation_rule.gd',
               'project/data/ui/full_tree_display.json', 'tools/p6/build_tree_display_catalog.py',
               'project/scenes/game_root.gd', 'project/scenes/training_room/training_room.gd',
               'project/scripts/systems/training_room_state.gd', 'tools/p6/source_provenance.py', 'tools/p6/approved_source_successors.json'}
    tracked.update(source_data)
    for row in rows:
        tracked.add(row['contract'])
        tracked.update(row['implementation_evidence'])
        tracked.update(row['existing_test_candidates'])
    for names in TESTS.values():
        tracked.update(f'project/tests/{n}.gd' for n in names)
    tracked.update(['project/tests/p6_mixed_gear_integration_test.gd', 'project/tests/p6_mixed_interactions_test.gd', 'project/tests/p6_full_content_journey_test.gd'])
    for path in tracked:
        assert (ROOT / path).is_file(), f'Missing evidence: {path}'
    for rec in manifest['records']:
        obj = source_data[rec['source_file']]
        for part in rec['pointer'].strip('/').split('/'):
            obj = obj[int(part)] if isinstance(obj, list) else obj[part]
        assert obj.get('id') == rec['source_id'], f'Source identity drift: {rec["pointer"]}' 
    summary = {tree: {'talents': sum(r['kind']=='talent' and r['tree_id']=='tree.'+tree for r in rows),
                      'ranks': sum(r.get('max_ranks',0) for r in rows if r['tree_id']=='tree.'+tree),
                      'playable_talents': sum(r['kind']=='talent' and r['status']=='P' and r['tree_id']=='tree.'+tree for r in rows)} for tree in OWNERS}
    return {'schema_version':1, 'audit_date':'2026-10-06', 'scope':'M5 Complete through T11; complete content, mixed/gear integration, player flows and closeout reconciled',
            'plan': 'docs/'+PLAN, 'summary':summary,
            'milestone_closeout': {'status':'Complete', 'document':'docs/P6M5_T11_Closeout_And_M6_Handoff.md', 'report':'project/reports/p6_m5_t11/summary.json', 'acceptance_map':'project/reports/p6_m5_t11/acceptance_map.json'},
            'player_flow_acceptance': {'status':'Complete', 'document':'docs/P6M5_T10_Full_Content_Player_Flow_Acceptance.md', 'report':'project/reports/p6_m5_t10_final/summary.json', 'ordered_pairings':12},
            'mixed_gear_integration': {'status':'Complete', 'authority':'P6M5-D023 baseline', 'document':'docs/P6M5_T9_Mixed_Tree_And_Gear_Integration.md', 'tests':['project/tests/p6_mixed_gear_integration_test.gd','project/tests/p6_mixed_interactions_test.gd'], 'ordered_pairings':12, 'main_allocations':36, 'additional_allocations':4},
            'design_reviews': {'tree.shadow': {'document':'docs/P6M5_T8_Shadow_Design_Review.md', 'status':'Complete', 'pending_decisions':[], 'approved_decisions':['D01','D02','D03','D04'], 'authority':'P6M5-D011', 'note':'User approved all four proposals; full Shadow runtime and focused acceptance complete.'}, 'tree.assassin': {'document':'docs/P6M5_T7_Assassin_Design_Review.md', 'status':'Complete', 'pending_decisions':[], 'approved_decisions':['D01','D02','D03'], 'authority':'P6M5-D009', 'note':'User confirmed all proposals. Full Assassin bindings, focused combat, boundary and player-flow acceptance in T7.'}, 'tree.bladedancer': {'document':'docs/P6M5_T3_Bladedancer_Design_Review.md', 'status':'Complete', 'pending_decisions':[], 'approved_decisions':['D01', 'D02', 'D03'], 'authority':'P6M5-D003', 'note':'Full specification reconciled with user confirmation; T4 implements all 13 talents and 35 ranks.'}, 'tree.thief': {'document':'docs/P6M5_T5_Thief_Design_Review.md', 'status':'Complete', 'pending_decisions':[], 'approved_decisions':['D01','D02','D03'], 'authority':'P6M5-D004', 'note':'User confirmed all three proposals and the Loaded Dice display name. T6 implements all ten talents and 35 ranks.'}},
            'status_legend':{'P':'Playable binding; Bladedancer full-tree evidence in T4, full Thief evidence in T6', 'S':'Shared support or reserved slot; full binding/verification pending', 'R':'Content review required; inherited/generic/partial support only', 'E':'Intentionally empty'},
            'source_hashes':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sorted(tracked)},
            'records': rows, 'rank_slots':ranks, 'talent_skill_grants':grants,
            'validation_test_candidates':{k:[f'project/tests/{n}.gd' for n in v] for k,v in TESTS.items()}}


def markdown(data):
    lines = ['# M5-T2 content coverage ledger', '',
        'Generated by `python tools/p6/build_m5_coverage_ledger.py`; check with `--check`.', '',
        f'See the [reconciliation and validation plan]({PLAN}) for dependency IDs B01–B04, questions Q01–Q07 and validation families V01–V10.', '',
        'The [JSON ledger](P6M5_T2_Content_Coverage_Ledger.json) contains all 92 source records, all 140 individual rank cases, both talent grants, canonical prerequisites, source pointers/hashes, implementation references and existing test candidates.', '',
        '**P** = scoped playable binding; **S** = shared support, full binding pending; **R** = content review required; **E** = intentionally empty. These are audit classifications, not new gameplay acceptance. Draft numbers remain design inputs except where an explicit approved contract is linked.', '',
        'All 44 talents have 140 playable rank definitions (Bladedancer 13/35, Thief 10/35, Assassin 10/35, Shadow 11/35). T4/T6/T7/T8 establish full-tree evidence; all twenty planned skills are reachable.', '',
        '[T3 Bladedancer specification](P6M5_T3_Bladedancer_Design_Review.md) is Complete under P6M5-D003; D01–D03 are user-confirmed. T4 promotes the remaining eight Bladedancer nodes; see [T4 closeout](P6M5_T4_Bladedancer_Implementation.md).', '']
    lines += ['[T5 Thief specification](P6M5_T5_Thief_Design_Review.md) is Complete under P6M5-D004; Loaded Dice is the approved display name. T6 implementation is complete. [T7 Assassin specification](P6M5_T7_Assassin_Design_Review.md) is approved under P6M5-D009; [T7 implementation](P6M5_T7_Assassin_Implementation.md) verifies all ten talents / 35 ranks and six skills.', '']
    lines += ['[T8 Shadow specification](P6M5_T8_Shadow_Design_Review.md) is approved under P6M5-D011; [T8 implementation](P6M5_T8_Shadow_Implementation.md) verifies all eleven talents / 35 ranks and five skills.', '']
    lines += ['[T9 mixed-tree and gear integration](P6M5_T9_Mixed_Tree_And_Gear_Integration.md): ' + data['mixed_gear_integration']['status'] + '. Twelve ordered pairings, 36 main allocations and four additional targeted allocations use actual released ranks and gear consumers. T10 full player flows and T11 milestone closeout are Complete.', '']
    lines += ['[T10 full-content player-flow acceptance](P6M5_T10_Full_Content_Player_Flow_Acceptance.md): Complete. Fresh per-tree and mixed UI journeys, persistence, seeded Practice/Lab parity and rendered usability checks; gear replacement now prunes unavailable skills.', '']
    lines += ['[T11 closeout and M6 handoff](P6M5_T11_Closeout_And_M6_Handoff.md): Complete. Final regression, source provenance, requirement-to-evidence mapping and downstream owners are reconciled.', '']
    for tree in ['bladedancer','thief','assassin','shadow']:
        lines += ['## '+tree.capitalize(), '', '| Item / canonical ID | Ranks or threshold | State | Review / implementation | Planned checks | Reconciliation |', '| --- | --- | --- | --- | --- | --- |']
        for row in data['records']:
            if row['tree_id'] != 'tree.'+tree or row['kind'] == 'tree':
                continue
            label = (row.get('approved_display_name') or row.get('source_name') or row.get('skill_id') or 'Empty slot').strip()
            amount = ('1–'+str(row['max_ranks'])) if 'max_ranks' in row else str(row.get('required_points', '—'))
            note = row['reconciliation'].replace('|','/')
            lines.append(f"| {label}<br>`{row['runtime_id']}` | {amount} | {row['status']} | {row['review_owner']} / {row['implementation_owner']} | {', '.join(row['validation'])} | {note} |")
        lines.append('')
    lines += ['## Talent-granted skills', '', '| Talent | Skill | Required rank | State | Owner |', '| --- | --- | --- | --- | --- |']
    for g in data['talent_skill_grants']:
        lines.append(f"| `{g['talent_id']}` | `{g['skill_id']}` | 1 | {g['status']} | {g['implementation_owner']} |")
    return '\n'.join(lines)+'\n'


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    data = make()
    outputs = {DEST:json.dumps(data, indent=2, ensure_ascii=False)+'\n', VIEW:markdown(data)}
    for path, value in outputs.items():
        if args.check:
            assert path.read_text(encoding='utf-8') == value, f'Stale ledger: {path.name}; review source drift before regeneration'
        else:
            path.write_text(value, encoding='utf-8')
    print('PASS: 92 identities, 44 talents, 140 individual rank cases, 4 intrinsics, 20 slots (2 empty), 20 skills, 2 talent grants; 44 playable talents/140 ranks; evidence paths and hashes checked')
