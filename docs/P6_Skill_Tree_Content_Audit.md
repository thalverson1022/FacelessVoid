# P6 Skill Tree Content Audit

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Date: 2026-09-16
Source baseline: Project Enigma audited Phase 5, commit `d0e025ae9ff6b86aa389582443be6382547cb4cc` on `main` (integrated 2026-09-21; original closeout `91c1f2fdfaae7b48aa1e193adfb910956b1d6574`). See `docs/P6_Audited_Baseline_Integration.md`.

## Purpose

This document audits the current Rogue tree content before Phase 6 redesign. It is not a final design proposal. Its job is to show what exists, what each tree currently implies, where overlap or risk exists, and what decisions should be made before implementation.

Use this document with `P6_Skill_Tree_Redesign_Brief.md` and `P6_Current_Player_Build_System_Map.md`.

## Current Rogue Tree List

Rogue currently has four subclass trees:

- Assassin: poison and crit-supported poison scaling.
- Bladedancer: attack speed, physical damage, shred, retrigger, and triggered Rending Slash.
- Shadow: poison, decay, crit poison, Death Strike, and decay-to-shred pressure.
- Thief: Steal, gold reward scaling, crit scaling from stolen/current gold, and economy-combat conversion.

The trees are functional but uneven. Some have clear active-skill identity, some mostly grant stat multipliers, and some use older internal names or legacy stat modifiers. Phase 6 should redesign them as a coherent set rather than tuning each in isolation.

## Current Shared Skill Pool

Important Rogue skills and roles:

| Skill | Current Role | Notes |
| --- | --- | --- |
| Stab | Basic attack | Shadow currently augments it with poison stacks. |
| Heavy Slash | Heavier physical attack | Shadow currently augments it with poison stacks. |
| Quick Cut | Bladedancer intrinsic | Fast physical identity piece. |
| Venom Jab | Assassin talent unlock | Early poison skill. |
| Poison Strike | Assassin talent unlock | 83% weapon scaling, 1.2 base attack time, applies poison. |
| Rending Slash | Bladedancer talent unlock/proc | Applies shred and can be triggered by Opportunity Strikes. |
| Beguiling Strike | Shadow talent unlock | Applies decay/resistance pressure. |
| Death Strike | Shadow talent unlock | Damage benefits from active poison stacks. Internal ID is currently `skill.killers_mark`. |
| Steal | Thief intrinsic | Steals 3g and supports Thief economy identity. |
| Hold | Timing/control action | Not an attack for proc purposes. |

Phase 6 decision: decide whether active skills should remain mostly tree-specific unlocks, become deeper build-defining capstones, or become a pool that multiple trees can shape differently.

## Assassin Audit

Current data:

- Tree ID: `tree.assassin`
- Intrinsic: x20% Poison Damage.
- Talents:
  - Venom Edge: +5 Poison Damage, unlocks Venom Jab.
  - Precise Cuts: +10% Crit Chance.
  - Lethal Intent: +50% Crit Damage, requires Venom Edge or Precise Cuts.
  - Toxic Techniques: +8 Poison Damage, unlocks Poison Strike, requires Lethal Intent.
  - Perfect Toxin: x100% Poison Damage, requires Toxic Techniques, cost 3.

Current implied fantasy:

Assassin is the direct poison damage tree with some crit support. It increases poison output through base poison damage and poison multipliers, then adds poison-focused active skills.

Strengths:

- The poison identity is easy to understand.
- It has a direct early unlock in Venom Jab and a stronger later unlock in Poison Strike.
- It interacts naturally with Phase 5 elemental/poison gear stats.

Risks:

- The tree may be too linear: more poison, then more poison again.
- Crit support may feel generic unless crit has a poison-specific payoff.
- Perfect Toxin is a large multiplier that may make earlier choices feel like tax nodes.
- Assassin and Shadow both use poison heavily; Phase 6 needs a sharper distinction.

Questions for Phase 6:

- Is Assassin about poison burst, poison execution, poison crits, or poison reliability?
- Should Assassin be the best single-target/boss poison tree while Shadow owns hybrid debuff pressure?
- Should crit be a core Assassin poison mechanic or moved toward Thief/precision identity?
- Should Poison Strike remain an unlock, become a build-around, or be replaced by a more distinctive capstone?

## Bladedancer Audit

Current data:

- Tree ID: `tree.bladedancer`
- Intrinsic: unlocks Quick Cut.
- Talents:
  - Quick Hands: +10% Attack Speed.
  - Piercing Blades: +20 Shred Value, unlocks Rending Slash.
  - Practiced Rhythm: x10% Physical Damage and +10% Retrigger Chance, requires Quick Hands or Piercing Blades.
  - Opportunity Strikes: Quick Cut has a 20% chance to trigger Rending Slash, requires Practiced Rhythm, cost 2.
  - Sunder: +20 Shred Value and +5 Shred Stacks, requires Opportunity Strikes, cost 3.

Current implied fantasy:

Bladedancer is the fast physical pressure tree. It uses Quick Cut, attack speed, retrigger, shred, and triggered Rending Slash to overwhelm armored targets.

Strengths:

- The active-skill loop is concrete: Quick Cut can lead to Rending Slash.
- Shred gives a clear matchup role against armor.
- Retrigger and attack speed create a recognizable high-tempo style.

Risks:

- Phase 5 accepted a Balance Lab warning for `bladedancer_contract_watchmen`, where the build exceeded the old win-rate watch threshold.
- Retrigger can create nonlinear scaling, especially with triggered skills.
- Shred stack/value boosts can stack with gear Bonus Stacks and Shred stats.
- If Bladedancer is simply fast plus physical plus shred, it may become the default answer to too many enemy types.

Questions for Phase 6:

- Should Bladedancer be a combo tree, a proc tree, a shred tree, or a fast-rotation tree?
- How much retrigger should legal builds be able to reach?
- Should Opportunity Strikes remain Quick Cut -> Rending Slash, or should triggered skills become a broader combo system?
- What is Bladedancer weak against?

## Shadow Audit

Current data:

- Tree ID: `tree.shadow`
- Intrinsic: Stab and Heavy Slash apply +1 Poison Stack.
- Talents:
  - Lingering Venom: +5 Poison Damage and +20% Chance for Crits to Apply Poison.
  - Exposed Weakness: +20% Decay Value, unlocks Beguiling Strike.
  - Black Lotus: +10% Crit Chance, unlocks Death Strike, requires Lingering Venom or Exposed Weakness.
  - Nightblade Rhythm: when applying Decay, also apply the same number of Shred stacks, requires Black Lotus, cost 2.
  - Umbral Presence: Poison stack cap increased to 40, requires Nightblade Rhythm, cost 3.

Current implied fantasy:

Shadow is a hybrid debuff tree. It layers poison, decay, crit poison, Death Strike, and decay-to-shred conversion.

Strengths:

- The tree has interesting cross-mechanic identity.
- Decay gives it a resistance-answering role distinct from Bladedancer's armor answer.
- Death Strike creates a payoff for active poison stacks.
- Nightblade Rhythm connects resistance pressure and armor pressure in a memorable way.

Risks:

- It overlaps Assassin on poison and Bladedancer on shred.
- Decay applying shred can blur tree boundaries if not carefully tuned.
- Umbral Presence is a cap increase that may feel invisible until late or specific builds.
- Multiple debuff systems can become hard to read if tooltip and combat log language lags behind.

Questions for Phase 6:

- Is Shadow the hybrid debuff tree, the delayed payoff tree, or the setup/execution tree?
- Should Shadow own decay and poison-stack manipulation while Assassin owns poison damage?
- Should Death Strike remain Shadow's payoff, and should it scale from poison stacks, debuff variety, or enemy vulnerability?
- Should Nightblade Rhythm remain a strong cross-debuff bridge or become a more conditional effect?

## Thief Audit

Current data:

- Tree ID: `tree.thief`
- Intrinsic: unlocks Steal.
- Steal currently steals 3g.
- Talents:
  - Keen Eye: x10% Physical Damage.
  - Sticky Fingers: +30% Gold Rewards.
  - Silvered Blade: x30% Physical Damage, requires Keen Eye or Sticky Fingers.
  - Big Score: +1% Crit Chance per stolen gold, requires Silvered Blade, cost 2.
  - Gilded Blade: +1% Crit Damage per current gold, requires Big Score, cost 3.

Current implied fantasy:

Thief turns money into combat pressure and combat into money. It is the economy-combat bridge tree.

Strengths:

- The identity is distinct from the other Rogue trees.
- Steal is a clear intrinsic skill.
- It naturally interacts with Phase 5 Increased Gold and Overkill Gold.
- It creates a unique progression fantasy around wealth and precision.

Risks:

- Economy scaling can become runaway if reward gold, stolen gold, current gold, and gear Increased Gold all multiply without strong caps or sinks.
- Physical damage multipliers may make Thief feel like a generic physical tree before the gold mechanics come online.
- Player-facing explanations need to be especially clear: stolen gold, current gold, stash gold, reward gold, and shop gold can sound similar.
- If gold is too valuable for shops and combat, players may avoid spending, which fights the shop loop.

Questions for Phase 6:

- Should Thief reward hoarding, spending, stealing, or cycling gold?
- Should current gold be a combat stat, a risk/reward resource, or a temporary contract-local value?
- How should Thief avoid competing directly with shop economy readability?
- Should Steal become a more active buildcraft decision than a simple gold action?

## Cross-Tree Overlap

Current overlaps to clarify:

- Poison appears in Assassin and Shadow.
- Crit appears in Assassin, Shadow, and Thief.
- Physical damage appears in Bladedancer and Thief.
- Shred appears in Bladedancer and Shadow.
- Gold/economy appears in Thief and Phase 5 gear.
- Retrigger appears in Bladedancer and Phase 5 gear.

Overlap is not automatically bad. The problem is unresolved ownership. Phase 6 should define primary, secondary, and forbidden identities for each tree.

Suggested ownership framing to evaluate, not blindly adopt:

| Mechanic | Primary Owner | Secondary Owner | Notes |
| --- | --- | --- | --- |
| Poison damage | Assassin | Shadow | Assassin should probably be clearer at direct poison scaling. |
| Poison stack manipulation | Shadow | Assassin | Shadow can own stack cap/setup while Assassin owns damage. |
| Shred/armor answer | Bladedancer | Shadow | Shadow's shred should probably depend on decay or setup. |
| Decay/resistance answer | Shadow | Gear | Shadow should have the clearest decay identity. |
| Retrigger/combo | Bladedancer | Gear | Keep legal retrigger below dangerous caps. |
| Gold-combat conversion | Thief | Gear economy stats | Needs strong readability and caps. |
| Crit | Thief or Assassin | Shadow | Decide whether crit is precision, poison delivery, or economy payoff. |

## Content Risks Before Redesign

- Some file names and resource IDs do not match; preserve IDs or migrate carefully.
- Legacy stat modifiers and canonical `stat_id` modifiers are mixed.
- Some capstone effects are large numeric multipliers rather than new play patterns.
- The current trees are mostly five-node chains; Phase 6 should decide whether that structure remains or expands.
- Practice Room and Balance Lab currently validate the Phase 5 baseline, not a complete tree redesign.
- Existing tree UI may be usable for the current small trees but may need layout support if Phase 6 adds branches, ranks, or more nodes.

## Recommended Phase 6 Design Decisions Before Coding

1. Choose each tree's one-sentence identity.
2. Decide whether the tree count remains four for Rogue.
3. Decide whether each tree keeps five talents or moves to a larger structure.
4. Decide whether talents can have ranks.
5. Decide whether active skills are unlocked by trees, talents, or both.
6. Decide whether mixed-tree builds are encouraged, restricted, or specialized.
7. Decide what happens to existing talent and skill IDs in old saves.
8. Decide which current mechanics are capped, soft-capped, or disallowed.
9. Define the first Balance Lab scenarios for each tree before tuning numbers.

## Suggested First-Pass Deliverable

Before changing `.tres` files, create a Phase 6 design table with:

- Tree name.
- Tree fantasy.
- Primary damage/status mechanic.
- Primary enemy defense answer.
- Core active skill or loop.
- Early talent promise.
- Mid-tree turn.
- Capstone payoff.
- Intended gear synergies.
- Intended weakness.
- Required engine hooks.
- Required tests.
