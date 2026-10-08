# Corrective study: 004-gate-conformance — honest gates, completed deliverables, corrected presentation

## What this is

The provenance audit (staged at `/workspace/eval/gate-conformance-inputs/hhjk-provenance.md`
— read it fully first, especially §8, the authoritative fix list) found the model work in
001/002-cont/003 sound (gates 1, 2, 3, 5, 6 pass; every headline traces), but binding gate
rules were overridden or met only on paper, and spec deliverables were dropped without a
continuation. This study supersedes the prior cards for publication. ~1 hour of compute.

Non-negotiable framing rules:
- **A failed gate is reported as FAILED.** Inventing relabels ("semantic PASS") is
  prohibited. Where a failure is survivable, the spec's own honest-partial path is used and
  the consequence stated on the card.
- Complete every item; if your session ends first, the continuation finishes the remainder
  (list it in followup_summary.json `remaining`).

## The nine fixes (audit §8; implement all)

1. **Gate 3b**: relabel as FAILED (both routes miss at least one of the four pre-registered
   tolerances; quote the table: 1-yr (a) 1.18%/(d) 1.80%; ADJINC-only (d) 0.59% but adopted
   post hoc; 3-yr (d) 1.92%). Run the prescribed 2023 level-scale sensitivity: rescale the
   2023 earnings level by the Gate-3b level gap and report how L4/L5 move. State the
   audit's inference (shipped "2010" earnings approximately in 2011 dollars) as a
   hypothesis, not a finding. Also disclose the out-of-trigger 3-year PUMS fetch.
2. **Deflator pairing**: every L4 sits beside its L4b on the same convention (7.0 vs 7.3
   paper-convention; 5.2 vs 29.2 corrected). Lead the card with the statement that holds
   under BOTH conventions: the absolute friction contribution (0.04 pp/yr 2000-10 vs
   0.06 pp/yr 2010-23). "Essentially unchanged since 2000-10" may appear only
   convention-qualified.
3. **Run LivingDefl L6** and fill `group_shares.csv` (it is header-only).
4. **Gate 2b(ii)**: make it a real check — dump the actual τ/z̃ assignment arrays the
   generalized code produces for t0=1970 and diff them against the rule, covering the
   t0>1 incumbent path L4 depends on.
5. **Gate 4 (b)/(c)**: recompute with the staged script 04 on the final crosswalk (don't
   cite Phase-2a values); either run a true SPLIT R4 or relabel it as the 5-of-538-codes
   proxy it is.
6. **Rebuild `tau_paths.csv` and the over-time figure from the Octave estimator** (the
   Python estimator mismatches the paper's: BW 1960 7.90 vs 6.685); complete the missing
   1960-2010 stability rows for L3/L6 under gate 7's trace rule.
7. **Fix `robustness_summary.csv`** column labels (τʰ/τʷ columns actually hold Ywkr/Cons).
8. **Add the dropped deliverables**: L7, the L2 young-propensity SD, the L8
   earnings-per-worker fit, the L9 annual SDs, and the figure CSVs.
9. **003 wording corrections** (as a findings addendum + corrected card fields): τʷ-flat
   holds for BM/BW but NOT WW (τʷ = 47% of WW's decline; 51% under R5); correct the
   Hurst-Rubinstein-Shimizu paraphrase (the adjusted gap stayed flat even as measured
   discrimination fell); [PROJECTED] tags on the headline conditional wording and the
   "~8.8% permanently unrealised" metric; add a projection error band from the backtest
   errors (WW's 0.193 vs the projected 0.049 decline must be visible); declare the
   continued/slowed cut-off as the study's own choice.

## Deliverables

`report.md`; `results/findings.md` opening with what was corrected and why;
`result_card.json` whose summary leads with the both-conventions statement and carries
honest gate labels; `results/card_corrections.csv` (old claim → corrected → reason);
the rebuilt CSVs and figure; gate artifacts for items 1, 4, 5.

## Rules

Foreground only (no background subagents — the audit flagged that violation); no package
installs beyond the staged environment (no micromamba); no fetches; reuse 001/002/003
artifacts and the staged Octave stage-split tooling; `--timeout 10800`.