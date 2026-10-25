# M7-T4 — Icon production and integration

Status: **Complete — user-approved full set installed and verified, 2026-10-09 (D018).**

All 93 identities now use the approved Flat charcoal square treatment, including the five refinements. T5 tooltip review is next; revisit individual icons there only as needed.

## Initial production and review evidence (before D018)

G11 authoring reconciliation is implemented: Icon Lab now contains all 93 live identities and 501 assets, including the dedicated Greed icon. Nine source-linked buffs retain their source assignments. Current display names and live-content labels replace obsolete readiness metadata; historical talent draft prose is hidden and selected stale shared-effect summaries corrected. This is not the full T5 wording review.

The exact frozen 92-identity fingerprint migrates by adding Greed. Existing assignments, explicit clears and imported images survive; unknown identities, missing modern assignments and unknown fingerprints remain rejected. The frozen approved exports and real browser drafts are untouched. Catalog generation is fresh and deterministic.

G09 candidates are prepared for Shadow Mastery, Dusk Strike, Potency, Toxic Tradeoff and Sharpened Edge. The first three improve edge contrast; the latter two improve blade silhouette. All are separate transparent 32×32 PNGs. Original subjects, orientation and palette identities guide the candidates; final taste/recognition acceptance belongs to the user.

- [Actual-size comparison](../tools/icon-lab/proposals/m7-t4/comparison.png): current above proposed, 22/24/32/52px, grayscale and count examples, 64px detail.
- [Portable Icon Lab workspace](../tools/icon-lab/proposals/m7-t4/workspace.json): all 93 assignments, exactly five proposed changes; verified import/export.
- [Candidate manifest](../tools/icon-lab/proposals/m7-t4/manifest.json), [exact generation prompts](../tools/icon-lab/proposals/m7-t4/prompts.json); generated masters retained alongside normalized candidates.

The live game still uses the approved assets. Candidate integration is staged only in an isolated checkout. T3 explicitly says: “Exact asset edits or replacements require concrete review.” See [accepted T3 handoff](P6M7_T3_Closeout_And_Accepted_Conventions.md). No blanket approval is inferred from historical R3.

## Validation and evidence

Executed 2026-10-09 against the inherited dirty workspace. Game reports include HEAD, source fingerprints, exact commands and save isolation records. Tooling source hashes and runtime coverage are in [T4 verification](../project/reports/p6_m7_t4/verification.json).

| Check | Result / evidence |
| --- | --- |
| `node tools/icon-lab/build-data.js --check` | Fresh: 93 identities / 501 assets. |
| `node tools/icon-lab/run_checks.js` | 16 model checks pass, including exact legacy migration, preserved clears, linked buffs and rejected malformed workspaces. |
| `node tools/icon-lab/ui_checks.js` | 28 browser groups pass in isolated Edge context: three sizes, actual exports/imports, recovery, legacy Greed migration, candidate decode and no uncaught errors. [Browser summary](../project/reports/p6_m7_t4/browser/browser-summary.json). |
| `python tools/p6/run_m6_closeout.py --report-name p6_m7_t4_focused --tests icon_assignment_test p6_m7_presentation_inventory` | Both pass. All 93 runtime textures resolve and source-linked reuse is retained; live content inventory covers 44 talents / 140 ranks / 23 skills. [Summary](../project/reports/p6_m7_t4_focused/summary.json). |
| `python tools/p6/run_m6_closeout.py --report-name p6_m7_t4_visual --visual --tests p6_m7_icon_accents_test` | Pass. Test Mode palettes/trees at 1280/1600/1920; Adventure and Practice counter/accent samples at 1920. [Summary](../project/reports/p6_m7_t4_visual/summary.json). This is not the full T8 mode-by-size matrix. |
| `python tools/p6/validate_m7_t4_preview.py` | Pass: five candidate files staged in the disposable checkout and cross-mode rendering rerun. [Summary](../project/reports/p6_m7_t4_candidate_visual/summary.json), [1280 tree](../project/reports/p6_m7_t4_candidate_visual/screenshots/tree-1280-0.png), [Adventure tree](../project/reports/p6_m7_t4_candidate_visual/screenshots/adventure-tree-counters.png). Live art/mappings unchanged. |
| `python tools/p6/prepare_m7_t4_candidates.py` | Five transparent 32px candidates, preserved masters and portable workspace; actual-size comparison visually inspected. Grayscale/count overlays are review approximations. |

Browser reproduction uses the bundled Node package directory via `NODE_PATH` and `ICON_LAB_REPORT_DIR=../../project/reports/p6_m7_t4/browser` to preserve older evidence. Initial browser run identified old 92-entry/9-buff assertions; both now track 93/10. First launch lacked Playwright on the default module path; the existing bundled dependency resolved it without installation.

Rendered baseline samples retain accepted geometry and category treatments. Shadow Mastery remains intentionally subdued when locked; this does not establish contrast acceptance for every state. Existing certificate/resource-teardown diagnostics remain M9 matters. No real save paths, sibling Enigma files, combat mechanics or balance values were changed.

## Initial review and completion boundary (superseded by D018 approval)

Review the five candidates individually or as a set. After accepted selections are known, install only those changes with provenance, regenerate authoring data, rerun affected mapping/render checks and close T4. Rejected candidates retain their approved originals or receive a targeted revision. T4 is not complete while concrete art acceptance and final live adoption remain outstanding.

T5 owns full descriptions, T6 effect overflow, T7 dense popups/audio, and T8 integrated accessibility. T9 human playtesting and T10 final presentation acceptance are not implied by automated checks.

## Square-background preview request — 2026-10-09

The user liked the five refinements and requested a unified hard-square treatment across icons from different packs. Prepared three preview-only shared backings: Soft slate (recommended), Flat charcoal and Inset stone. Ten actual icons cover the five refinements plus mixed square/transparent pack samples; controls show 22/32/52px, locked grayscale and count approximations, with the accepted category bottom accents. Existing baked-in artwork colors are preserved in this first backing comparison; individual background cleanup and final consistency review remain downstream of the selected direction.

[Review snapshot](../project/reports/p6_m7_t4/square-soft-slate.png), [alternate flat](../project/reports/p6_m7_t4/square-flat-charcoal.png), [alternate inset](../project/reports/p6_m7_t4/square-inset-stone.png). Interactive approval preview is delivered inline in the chat. Browser checks verified embedded images, size/state changes, carousel navigation and 320/736px layout fit. No game files or live assignments changed. Once the user selects a treatment, prepare the full 93-identity consistency gallery before final adoption. T4 remains Pending input for this concrete direction.

## Flat charcoal selected — 2026-10-09

The user selected **Flat charcoal** from the three square-background previews. The full 93-identity gallery now uses that exact shared treatment (#28282b backing, #5e5d61 one-pixel border, one-pixel inset, hard corners), including the five refined candidates. It preserves nine source-linked buff relationships and dedicated Greed art. Selection shows current versus proposed art; size/state controls cover 22/32/52px and approximate locked/count views.

[Full gallery snapshot](../project/reports/p6_m7_t4/flat-charcoal-gallery.png) and [browser verification](../project/reports/p6_m7_t4/flat-charcoal-gallery-checks.json). All 93 images loaded; three sizes, selection, states and 320/736px layouts passed. Existing baked-in pack backgrounds remain visible for consistency review; this gallery applies the selected common backing, not background removal. The user's preference settles the backing direction; full-set feedback and final game integration remain next. Runtime files are unchanged.

## D018 adoption

User accepted the full set, with individual changes reserved for the T5 tooltip audit. Installed all 93 mappings using 84 opaque 32px textures under `assets/ui/assigned_flat/`; nine buffs still share their source texture. The installer reads the frozen original export and new [approved treatment](../tools/icon-lab/approved/m7-t4/treatment.json), keeping original assets intact and avoiding repeated framing on rerun. Five refined sources have explicit reviewed provenance.

The common tile is #28282b charcoal with a #5e5d61 one-pixel hard border, one-pixel inset and nearest-neighbor 28px artwork. Existing painted pack backgrounds are retained as reviewed. No gameplay values, category-accent code, button geometry or save policies change. All 585 authoring assets remain available, including previous installed paths; the previous 93-entry fingerprint is explicitly compatible, alongside exact frozen 92-entry migration.

## Final validation and closeout

- `python tools/p6/run_m6_closeout.py --report-name p6_m7_t4_live_final --tests icon_assignment_test p6_m7_presentation_inventory p6_talent_ui_test p6_skill_ui_test training_room_combat_view_test`: **five suites pass**, including loaded texture borders/insets, 93 mappings, source reuse, talent/skill controls, Practice and unchanged deterministic combat. [Summary](../project/reports/p6_m7_t4_live_final/summary.json).
- `python tools/p6/run_m6_closeout.py --report-name p6_m7_t4_live_final_visual --visual --tests p6_m7_icon_accents_test`: **pass**; Test Mode art/accent samples at 1280/1600/1920 plus Adventure and Practice samples. [Summary](../project/reports/p6_m7_t4_live_final_visual/summary.json), [1280 tree](../project/reports/p6_m7_t4_live_final_visual/p6_m7_icon_accents_test/icon_accents/tree-1280-2.png). Rendered samples visually inspected. Full mode-by-size accessibility remains T8.
- `node tools/icon-lab/build-data.js --check`: **fresh, 93 entries / 585 assets**. `node tools/icon-lab/run_checks.js`: **17 pass**. Existing `ui_checks.js` with the bundled Playwright dependency: **28 browser groups pass**. [Browser summary](../project/reports/p6_m7_t4_adoption/browser/browser-summary.json).
- All 93 mapping hashes match; 84 textures are opaque 32px tiles; originals remain byte-identical; repeated installer execution preserves exact output bytes and avoids double framing. [Asset checks](../project/reports/p6_m7_t4_adoption/asset_checks.json), [final fingerprints](../project/reports/p6_m7_t4_adoption/final_verification.json).
- Both final isolated-run records report unchanged protected files and redirected per-suite user data. No real player saves or sibling Enigma files were used.

Initial import/verification attempts failed because editor scanning registered historical class definitions from `project/reports/p6_m6_t6_closeout/candidate/` instead of runtime scripts. `project/reports/.gdignore` now excludes archived evidence from editor registration/import; explicit isolated test-script loading still works, as the final runs demonstrate. The runtime class registry was refreshed with redirected user data. Failed evidence remains under `p6_m7_t4_live_focused`, `p6_m7_t4_live_visual`, `p6_m7_t4_live_verified` and `p6_m7_t4_live_rendered`; none is counted as a passing run. Temporary import-runner instrumentation was removed. Certificate/teardown diagnostics remain the previously recorded M9 qualification issue.

T4 is complete. User acceptance covers the five refinements and shared Flat charcoal treatment; original baked-in colors were visible and retained in that review. T5 owns the tooltip audit and any individual icon refinements found alongside it. T6/T7/T8 and later human playtesting remain outstanding.
