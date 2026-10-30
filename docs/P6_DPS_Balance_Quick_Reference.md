# DPS Balance — Quick Reference

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

**Live baseline:** P6M5-D023 · 6 October 2026

Crude Dagger only · naked, zero-defense dummy · zero starting stash (Gilded Blade includes gold stolen during combat). Mean DPS: 200 seeds, checked against 200 independent seeds. Fixed allocations; best rotations found in the search.

## DPS rankings

| Points | Window | 1st | 2nd | 3rd | 4th |
|---:|---:|---|---|---|---|
| 1 | 30s | Assassin **25.23** | Shadow **21.38** | Bladedancer **16.22** | Thief **15.67** |
| 1 | 120s | Assassin **25.78** | Shadow **21.74** | Bladedancer **16.38** | Thief **15.61** |
| 10 | 30s | Assassin **60.16** | Thief **46.77** | Bladedancer **42.99** | Shadow **39.06** |
| 10 | 120s | Assassin **61.18** | Thief **58.47** | Shadow **57.60** | Bladedancer **47.98** |
| 21 | 30s | Shadow **315.17** | Bladedancer **240.17** | Assassin **200.61** | Thief **162.82** |
| 21 | 120s | Shadow **573.40** | Thief **384.20** | Bladedancer **240.54** | Assassin **209.87** |
| 35 | 30s | Shadow **473.56** | Assassin **329.42** | Bladedancer **309.02** | Thief **233.27** |
| 35 | 120s | Shadow **1,011.28** | Thief **501.75** | Bladedancer **324.59** | Assassin **324.44** |

21-point BD uses **BD2**; BD1 is retired. At 35 points / 120s, BD and Assassin are effectively tied (324.59 vs 324.44).

## Appendix — Allocations & rotations

Ranks use **allocated / maximum**. Unlisted talents have zero points. Repeat each macro; cooldowns follow live rules. “Heavy Strike” is **Heavy Slash**.

### 1 point

**Bladedancer**

Whetstone 1/5.

- **30s & 120s:** Quick Cut

**Thief**

Keen Eye 1/5.

- **30s & 120s:** Steal

**Assassin**

Precision 1/5.

- **30s:** 2× Venom Jab → 3× Heavy Slash
- **120s:** Venom Jab → Stab → Venom Jab → 3× Heavy Slash

**Shadow**

Coated Weapons 1/1.

- **30s:** Stab → 2× Heavy Slash
- **120s:** 3× Heavy Slash → Stab

### 10 points

**Bladedancer**

Precision Attacks 1/1 · Rending Slash 1/1 · Weakness 3/5 · Whetstone 5/5.

- **30s & 120s:** Rending Slash → Quick Cut → Heavy Slash → Parry Strike

**Thief**

Sticky Fingers 5/5 · Fast Hands 5/5.

- **30s:** Pick Pocket → 3× Mug → Pick Pocket → 2× Mug
- **120s:** Pick Pocket → 6× Mug

**Assassin**

Echoing Toxin 3/3 · Hastened Poison 2/5 · Quick Hands 5/5.

- **30s:** Venom Jab → Virulent Poison → Blinding Powder
- **120s:** Virulent Poison → Venom Jab → Virulent Poison → Blinding Powder

**Shadow**

Coated Weapons 1/1 · Deception 5/5 · Snake Oil 4/4.

- **30s:** 4× Stab → Touch of Darkness → Death Strike
- **120s:** 5× Stab → Touch of Darkness → Death Strike

### 21 points

**Bladedancer (BD2)**

Cloak & Dagger 2/2 · Fancy Footwork 5/5 · Opportunity 3/3 · Rending Slash 1/1 · Riposte 2/2 · Virulent Corruption 1/1 · Weapon Master 2/2 · Whetstone 5/5.

- **30s:** 2× Quick Cut → Dance of Death → Quick Cut → Dance of Death → Leaping Plunge
- **120s:** 2× Quick Cut → Dance of Death → Quick Cut → Leaping Plunge

**Thief**

Gilded Blade 1/1 · Keen Eye 4/5 · Sticky Fingers 5/5 · Bribery 3/3 · Fast Hands 5/5 · Silvered Edge 3/3.

- **30s:** Pick Pocket → Steal → 7× Big Score → Mug
- **120s:** Pick Pocket → 2× Steal → 6× Big Score

**Assassin**

Bypass 1/1 · Critical Poison 1/1 · Echoing Toxin 3/3 · Hastened Poison 2/5 · Quick Hands 5/5 · Resonance 4/4 · Toxic Tradeoff 5/5.

- **30s:** Virulent Poison → 2× Blinding Powder → Poison Vile → Blinding Powder
- **120s:** Virulent Poison → Hold → Blinding Powder → Poison Vile → Blinding Powder

**Shadow**

Coated Weapons 1/1 · Death Blade 2/2 · Death Pact 2/3 · Death Touch 3/3 · Deception 5/5 · Dusk Strike 1/1 · Shadow Mastery 2/5 · Snake Oil 4/4 · Umbral Presence 1/1.

- **30s:** Beguiling Strike → 2× Distilled Corruption → Beguiling Strike → Distilled Corruption → Heavy Slash → Distilled Corruption → 2× Death Strike → Touch of Darkness
- **120s:** Beguiling Strike → Distilled Corruption → Death Strike → Beguiling Strike → Distilled Corruption → Death Strike → Touch of Darkness → Beguiling Presence

### 35 points

**Bladedancer**

Cloak & Dagger 2/2 · Double Dip 2/2 · Fancy Footwork 5/5 · Opportunity 3/3 · Precision Attacks 1/1 · Rending Slash 1/1 · Riposte 2/2 · Sharpened Edge 5/5 · Side Step 1/1 · Virulent Corruption 1/1 · Weakness 5/5 · Weapon Master 2/2 · Whetstone 5/5.

- **30s:** Dance of Death → 2× Quick Cut → Parry Strike → Quick Cut → Stab → Leaping Plunge
- **120s:** Quick Cut → Dance of Death → Quick Cut → Parry Strike → Quick Cut → Stab → Leaping Plunge

**Thief**

Gilded Blade 1/1 · Keen Eye 5/5 · Sticky Fingers 5/5 · Bribery 3/3 · Charisma 3/3 · Fast Hands 5/5 · Fill Your Pockets 5/5 · Finders Keepers 2/2 · Loaded Dice 3/3 · Silvered Edge 3/3.

- **30s:** Pick Pocket → Steal → 2× Big Score → Mug → Big Score
- **120s:** Pick Pocket → Steal → Big Score → Steal → 2× Big Score

**Assassin**

Accelerant 5/5 · Bypass 1/1 · Critical Poison 1/1 · Echoing Toxin 3/3 · Hastened Poison 5/5 · Poison Strike 1/1 · Precision 5/5 · Quick Hands 5/5 · Resonance 4/4 · Toxic Tradeoff 5/5.

- **30s:** Virulent Poison → Poison Vile → 2× Poison Strike
- **120s:** Poison Vile → Virulent Poison → Blinding Powder → 2× Poison Strike

**Shadow**

Blind Spot 5/5 · Coated Weapons 1/1 · Death Blade 2/2 · Death from the Shadows 5/5 · Death Pact 3/3 · Death Touch 3/3 · Deception 5/5 · Dusk Strike 1/1 · Shadow Mastery 5/5 · Snake Oil 4/4 · Umbral Presence 1/1.

- **30s:** Beguiling Strike → 2× Distilled Corruption → Beguiling Strike → 2× Distilled Corruption → 3× Death Strike → Touch of Darkness
- **120s:** Beguiling Strike → Distilled Corruption → Death Strike → Touch of Darkness → 2× Death Strike → Beguiling Strike → Beguiling Presence

---

[Detailed results](../project/reports/balance/subclass_protocol_d023/results.md) · [Protocol](P6_Subclass_Balance_Protocol.md)
