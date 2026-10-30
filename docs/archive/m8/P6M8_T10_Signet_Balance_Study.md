# T10 Signet of the Old Kings balance study

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

**Superseded production coefficient:** D095 subsequently adopts1.5× for both conversions. The2×/1×/0.5× results below retain their original tested coefficients. [Current adoption](P6M8_T10_Signet_Adopted_Balance.md).

P6M8-D094, 2026-10-25. User requested actual DPS comparisons for Signet, particularly Crude Dagger and 35 Bladedancer /10 Thief, plus higher-end physical builds. This is an investigation for review, not an adopted balance change. **Production remains at2× Crit Chance conversion and2× bonus Crit Damage conversion.** T10 remains In progress; T9 Pending input.

## Findings

The concern is supported for lightly geared physical builds. Signet’s conversion dominates the basic comparison, not merely its fixed affixes. It does not universally dominate physical builds: crit-specialized Big Score rotations and extreme generated crit-damage gear provide meaningful competitors. Lowering the conversion is a reasonable tuning step before introducing additional drawbacks.

## Method and scope

- Native Balance Lab and the current CombatResolver in disposable project copies with isolated save paths. No production launch or player-save access. No Alchemist/account upgrades, carried gear, pre-stacked buffs or missing-attempt bonuses.
-30-second windows; zero-starting-defense dummy with1,000,000,000 health, preventing early kills. These are **dummy DPS**, including the build’s actual Shred/negative-armor and Penetration effects, rather than abstract pre-mitigation packet totals. They are not contract30 win thresholds. No Exsanguinate casts or health removal appear in these cases.
- Main comparisons use200 seeds,1–200. Small screens select candidates; endpoint comparators use20 seeds, matched against the same first20 Signet seeds. Percentile ranges describe individual runs, not confidence intervals. Reusing seed numbers across configurations does not hold their internal RNG event streams identical after build changes.
- Full35 BD allocation from current ranked content; initial10 Thief is Sticky Fingers5/Fast Hands5, matching the earlier representative studies. The alternative Keen Eye5/Fast Hands5 allocation is also checked. A single build/rotation is not claimed optimal.
- Main rotation: Dance → Quick Cut → Heavy Slash → Parry Strike → Plunging Strike. Stable IDs: `dance_of_death`, `quick_cut`, `heavy_slash`, `parry_strike`, `leaping_plunge`. No Exsanguinate is added to the Crude Dagger comparison.
- All final ranks, exact gear paths, rotation IDs, starting gold and target settings are in the saved `study_spec` objects. No player scalar overrides were used for normal profiles. Coefficient experiments change exactly two lines in copied-only `legendary_live_stats.gd`; both coefficients change jointly and fixed item affixes remain identical.

## Requested Crude Dagger comparison

35 BD /10 Thief, zero starting gold, otherwise empty equipment slots. All rows200 seeds.

| Setup | Mean DPS | 5th–95th percentile | Relative to dagger alone |
|---|---:|---:|---:|
| Crude Dagger only | **346** | 253–426 | 1.00× |
| Crude + Signet affixes, conversion disabled (research control) | **567** | 466–676 | 1.64× |
| Crude + Lolzorz’s Locket | **570** | 413–689 | 1.65× |
| Crude + actual Signet | **2,540** | 2,343–2,770 | 7.35× |

Actual Signet gives **7.35× DPS (+635%)** against no necklace, and **4.46×** against Locket. The affix-only control is a deliberately modified research item, not a player-obtainable item. It retains+20% Crit Chance,+100% Crit Damage,+20% Shred Chance and removes only the signature; actual Signet is4.48× stronger than that control.

The zero-talent Stab test also increases13.24→109.55 DPS (8.27×). The alternate Keen Eye/Fast Hands35/10 allocation increases312.93→2,543.80 DPS (8.13×). The result is not confined to the initial10-point Thief selection. Other Crude rotations give6.13× to13.34× gains; macro cadence and per-skill crit benefits matter.

Why it is so large: without talents, ordinary2× crit damage plus Signet’s own+100% crit damage gives3× raw crit damage. Converting the bonus above a normal hit at2× grants **+400% physical damage**, alongside+50% attack speed from25% raw crit chance. In the35 BD baseline, raw crit chance37% gives **+74% attack speed**, and raw4× crit damage gives **+600% physical damage**. That changes the gear damage bucket from1× to7×, which multiplies the existing talent bucket. The resolved fields match this formula; no additional double-conversion was observed.

## Higher-end fixed Legendary equipment

All comparisons below use200 seeds and current legal45-point allocations. “Best” means the better of the tested macros, not a proven optimum. Different optimized rotations are explicitly separated from identical-rotation comparisons.

| Allocation / starting gold | Signet DPS | Locket DPS | Comparison |
|---|---:|---:|---|
|35 BD /10 Thief;500g |32,965 |21,217 | Same rotation and other four items: Bandit, Samurai, Cloak, Serpent’s Coil |
|24 BD /21 Thief;500g |57,161 |20,642 | Same original five-skill rotation; Bandit, Samurai, Cloak, Coin |
|24 BD /21 Thief;500g |57,161 |55,211 | Each uses its better tested rotation; Locket uses Big Score |
|24 BD /21 Thief;1,000g |93,342 |31,589 | Same original rotation; Bandit reaches its+100 base-damage cap |
|24 BD /21 Thief;1,000g |93,342 |78,897 | Each uses its better tested rotation; same other four items |
|35 Thief /10 BD;500g |4,724 |11,889 | Each uses its better tested rotation; same Bandit/Samurai/Cloak/Coin |
|33 BD /12 Shadow;500g |36,358 |15,168 | Same original rotation; same Bandit/Samurai/Cloak/Coin |
|33 BD /12 Shadow;500g |22,137 |26,867 | Same Touch-of-Darkness rotation; same Mithril/Samurai/Cloak/Coin |

Rich build allocation: BD24 = Wet Stone5, Weakness5, Rending Slash1, Precision Attacks1, Double Dip2, Cloak and Dagger2, Sharpened Edge5, Weapon Master2, Virulent Corruption1. Thief21 = Keen Eye5, Sticky Fingers5, Fast Hands5, Bribery3, Silvered Edge2, Gilded Blade1. The Locket Big Score macro is Pick Pocket → Dance → Big Score → Heavy Slash → Quick Cut. On that exact macro at500g, Signet39,071 loses to Locket55,211, rather than nearly matching it.

Gilded caps at500 stash gold (+500% crit damage), while Bandit caps at1,000g (+100 base physical damage). Silvered is limited by its rank and gold stolen this fight. Approved ranked gold talents therefore do not give an unlimited Signet multiplier. `resolved_fields.raw_crit_multiplier` excludes live Gilded: the rich Signet4× field becomes9× live at500g, producing+1,600% converted physical damage. Matched Locket3× becomes8× live; Big Score can then apply its6× critical factor for48× critical hits. Signet loses that skill-specific factor entirely.

The fixed-roster screen covers all168 five-slot combinations of seven weapons, two helms, two chests, three rings and the two necklaces, across three macros (504 evaluations, three seeds each). Six selected matched cases were confirmed at200 seeds. Hybrid screening adds104 five-seed evaluations; eight selected comparisons were confirmed at200 seeds. The screen is not an exhaustive rotation/talent optimization.

## Constructed generated-gear endpoint

A bounded extreme within current generation tables: depth12, value scale1, five slots,1,000 starting gold, full35 BD /10 Thief, no missing attempts or carried items. This is **not an acquired save, observed RNG drop, typical build or global maximum**. Exact maximum values are assigned after the production generator validates the permitted rolls; item requests and save payloads are validated. Four positive Chaos rolls are possible, but obtaining exact ideal combinations is not established by this test.

The matched four items are Bandit Blade; Unique helm (physical damage, Crit Chance, attack speed, CDR, Double Applied Stacks); Unique armor (physical damage, Crit Chance, All Stacks, crit-applied Penetration, All Stats); Chaos ring with four Retrigger positives. Only the necklace changes. Rotation: Dance → Quick Cut → Quick Cut → Parry Strike → Quick Cut → Stab → Plunging Strike.

| Necklace | Mean DPS, matched seeds1–20 |
|---|---:|
| Signet |257,525 |
| Locket |236,483 |
| Chaos, four maximum Crit Damage positives |1,164,565 |
| Chaos, four maximum Cooldown Reduction positives |213,647 |

Signet separately averages **257,042 DPS over200 seeds** (first20 above come from that same run). At this endpoint it narrowly beats Locket but loses heavily to the generated crit-damage necklace. The four Crit Damage rolls are+243% each before All Stats scaling. High crit chance and attack-speed floors reduce Signet’s relative advantage. The tested Signet setup resolves to+486.4% total attack speed,100% ordinary Retrigger Chance,18.208× combined physical multiplier and+105 physical base. Further IAS often cannot shorten the authored cast minimum.

This is a tested high-output example, not a claim that257k is the highest possible Signet output. Additional Shadow consumption packages, generated stat choices, longer windows, missing attempts, editable Practice values and legacy compatibility inputs were not exhaustively optimized. The generator also supports externally specified value scales, so an unconstrained universal ceiling is not meaningful.

## Conversion sensitivity — experiments only

Identical affixes and scenario inputs; both Crit Chance→IAS and bonus Crit Damage→physical conversions changed together in disposable copies.

| Profile | Current2× | Candidate1× | Candidate0.5× |
|---|---:|---:|---:|
|35 BD /10 Thief, Crude, zero gold |2,540 |1,258 |711 |
|24 BD /21 Thief, fixed Legendaries,500g, original macro |57,161 |29,245 |Not tested |
|33 BD /12 Shadow, fixed Legendaries,500g, original macro |36,358 |20,715 |Not tested |

At1×, the Crude comparison still gives3.64× dagger-alone DPS and2.21× Locket DPS. The rich1× result remains1.42× the identical-macro Locket but falls47% below the better tested Big Score/Locket macro. At0.5×, only the Crude profile was tested:711 DPS is still1.25× Locket. Neither candidate is a finalized balance recommendation, and physical-only versus attack-speed-only coefficient changes were not isolated.

**Recommendation:** start the next balance decision with1× conversions. This roughly halves the tested Signet output while retaining a strong physical conversion identity. Assess whether its remaining baseline advantage is acceptable before adding another drawback. The existing no-crit cost already matters: loss of Side Step’s guaranteed crit, Big Score’s critical factor, Steal’s crit theft, critical Poison, crit-applied Poison/Penetration/Potency, Locket recovery and Wingjammer Dash. Damage-oriented BD builds sacrifice fewer of those benefits than dedicated crit builds. A new broad penalty risks suppressing already-competitive niches without addressing the large free baseline physical conversion as directly.

## Evidence and verification

[Manifest](../../../work/m8_t9_presentation/d094_verification.json), [compact results](../../../work/m8_t9_presentation/d094_results_compact.json), [DPS table](../../../work/m8_t9_presentation/d094_dps_summary.csv). Runners, exact specs, copied projects, per-case results and console logs remain under `work/m8_t9_presentation/signet_d094` and `signet_d094_candidates`. Coefficient source snapshots and two-line patches are preserved separately; the candidate checkout’s final source is1×, while the0.5× evidence retains its own snapshot.

**11,332 completed valid native windows across704 evaluations**, including small screens, repeated confirmations and experimental candidates. All counted evaluations pass with zero invalid scenarios. Balance Lab computes aggregates from every seed but retains only the first24 individual samples (all20 in20-seed cases). No claim is made that all200 individual records are retained.

The initial large roster invocation hit its time budget after494 completed case files because it repeatedly rewrote a growing full summary. A compact resumption reused those exact files and completed the remaining10 cases; all504 are included once. The original long endpoint confirmation was intentionally stopped after its first completed200-seed Signet row, and the remaining necklaces were completed with matched20-seed comparisons. Uncompleted windows are excluded, and neither interrupted invocation is represented as a full successful phase. Existing certificate-store,10 ObjectDB and9-resource shutdown diagnostics remain visible. No new script/parse failures in the successful runs.

A separate read-only audit checked the conversion math, legal talent packages, gold caps, crit-dependent losses and34 completed baseline/hybrid/Thief/Keen/candidate rows before final consolidation. All2,411 pre-existing project files are hash-identical to the initial snapshot, including combat code, item resources, artwork, loot rules and save systems. Only documentation/evidence was added. No balance changes are adopted by this report.
