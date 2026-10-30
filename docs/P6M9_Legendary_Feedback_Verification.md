# Legendary combat feedback

2026-10-27 — P6M9-D034. User approved all eight presentation proposals, with Serpent's Scales using a wiggle and glow instead of added words. Applies to Adventure/shared Test and Practice.

| Item | Implemented cue | Recorded trigger |
| --- | --- | --- |
| Umbral Stiletto | Purple slash across the target | Successful Death Strike impact with captured Umbral equipment flag |
| Decrepit Blade | Green expanding burst and short radial rays | Fueled Poison Strike all-stack burst; still visible if Scales preserves its cost |
| Nightkiss Kitana | Red curved swoosh | Successful Exsanguinate impact with captured Nightkiss equipment flag |
| Lolzorz's Locket | Countdown number briefly enlarges and flashes | Actual recorded cooldown deadline reduction; repeated HUD refreshes do not repeat the pulse |
| Serpent's Coil | Ghost uses the poison attack animation frames | Recorded Poison retrigger; ordinary Poison ticks do not create attack ghosts |
| Serpent's Scales | Two small sideways wiggles and a brief green outline/halo | Tick's recorded `stacks_preserved` flag; no added words, size or damage changes |
| Arctic Mittens | Blue frost rim and moving motes around the combat clock | Captured countdown rate below one while playback is active |
| Hands of the Lightning Lord | Standard ghost for attack retriggers; poison ghost for Poison retriggers enabled by Coil | Existing attack-chain events and recorded Poison repeat events |

Critical Poison retains its existing larger text, punctuation and punch while preservation animates its horizontal position and glow independently. Preservation also remains visible within attack chains. Existing popup limits remain in force. Stage accents reuse at most three nodes; both ghost variants share one reusable sprite. Clock frost adds one child to each clock badge.

Equipment signature flags are captured in `presentation_initial`; replay never queries a subsequently edited build. Tick records additionally expose whether the activation is an all-stack Consume burst, including a preserved burst with zero stacks consumed. These are observational fields; RNG calls, damage, stack costs, cooldown scheduling and countdown arithmetic are unchanged. Locket pulses consume presentation credit serials, reset on each playback start, and briefly retain `0.0s` when a reduction makes a skill ready.

Skip/instant playback suppress transient cues; reduced motion cancels stage effects, popup feedback and countdown pulses. Arctic motion hides under reduced motion and ends with playback. New fights reset signature flags and pending visual state. Original artwork, item identities and save formats are unchanged.

Verification uses isolated project/profile copies:

- [Integrated Legendary check](../project/reports/m9_legendary_integrated_09/summary.json): passes in both dashboards at 1× and 4× with resolver-produced events, 36 actual1600×900 screenshots, normal/critical preservation, actual Locket reductions, and skip/reduced-motion/unequipped controls. Samples the actual horizontal tween and verifies glow restoration. Diagnostic fixtures combine effect flags to obtain witnesses; they are not claims about legal equipment combinations or balance. [Event/render index](../project/reports/m9_legendary_integrated_09/m9_legendary_feedback_test/m9_legendary_feedback/evidence.json).
- [Retained mechanics](../project/reports/m9_legendary_mechanics_retained/summary.json): `m9_t8_mechanics_test` and `m9_t9_combined_mechanics_test` pass.
- [Existing popup conventions](../project/reports/m9_legendary_existing_feedback/summary.json): Blinding Powder and critical Poison presentation suites pass with rendered dashboards.
- Bounded stage runtime checks cover failed casts, empty/natural tick rejection, full poison animation frames, reuse across 50 repeat calls, reset and cancellation. Parent inspected final dashboard samples for target alignment, readable text, clock frost, red/purple accents and poison ghosts.

Known certificate-store and engine teardown diagnostics are retained in the logs; this is scoped presentation verification, not broad engine qualification or a progression review. T10 remains Not started.
