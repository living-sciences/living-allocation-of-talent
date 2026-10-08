# Findings — 004 corrective study (HHJK 2019 post-2010 living-update)

## What was corrected, and why

The provenance audit of studies 001/002/003 found the **model work sound** — every headline
number traces to a case log on disk, and Gates 1, 2, 2b(i), 2b(iii), 3, 5 and 6 are genuine
passes — but found that several **binding gate rules and reporting rules were overridden,
relabelled, or satisfied only on paper**, and that spec deliverables were dropped without a
continuation. This study keeps the (sound) numbers and fixes the presentation and the honesty
of the gates. The nine corrections:

1. **Gate 3b is reported FAILED, not "semantic PASS."** The pre-registered rule requires one
   route to pass all four tolerances; the (d) earnings-level tolerance (≤1%) is missed under
   **every** route — 1.80% (1-year pre-registered recipe), 0.59% (ADJINC-only, but adopted
   *after* seeing results), 1.92% (3-year file). There is no "semantic pass" category. The 2023
   results are retained via the spec's honest-partial path, and the consequence is **quantified**
   by a 2023 level-scale sensitivity: rescaling the 2023 earnings level by the Gate-3b gap
   (1/1.019, 1/1.016) moves **L4 to 8.4% / 8.1%** (from 7.0%), the opposite-sign +1.9% check gives
   6.1%, and the "≈2011 dollars" intermediate pce(2010)≈104.0 gives **5.9%**; **L5 is exactly
   invariant at 9.0** in all cases. So L4 lives in ~6–8% regardless of convention — an order of
   magnitude below the ~40% historical share. The audit's inference that the shipped "2010"
   earnings are ≈2011 dollars (so the corrected pce(2010)=106.17 over-corrects and the true L4
   lies **between 5.2 and 7.0**) is stated as a **hypothesis, not a finding**. The out-of-trigger
   3-year PUMS fetch is disclosed.

2. **Lead with the convention-robust absolute contribution; pair L4 with L4b on each convention.**
   The **absolute** friction contribution to market-GDP/person growth was **0.04 pp/yr in 2000-10
   and 0.06 pp/yr in 2010-23 under BOTH deflator conventions** (Difference rows, identical in
   Living and LivingDefl). The **share** is deflator-sensitive only because the denominator moves:
   L4 7.0% (paper) / 5.2% (corrected), **L4b 7.3% (paper) / 29.2% (corrected)**. L4b jumps to 29.2%
   not because frictions did more, but because the corrected 2010 deflator compresses 2000-2010
   actual growth. "Essentially unchanged since 2000-10" is kept only convention-qualified.

3. **LivingDefl L6 run; group_shares.csv filled.** 2010-23 group split under the corrected
   deflator: WW 3.8 / BM 0.5 / BW 0.8 (paper convention: 5.2 / 0.7 / 1.1).

4. **Gate 2b(ii) made real.** The actual `TauW_alt/TauH_alt/Z_alt` arrays produced by the
   production `how_much_poorer.m` were dumped at t0=1970 and t0=2010 and diffed against the rule
   (**PASS**). This exercises the t0>1 incumbent path L4 depends on: at t0=2010 the 1990/2000-young
   incumbent cohorts correctly keep their **own** estimates (only the 2023-young cohort is reset).

5. **Gate 4 recomputed in-run** with `scripts/04`: (a) 96.46% unambiguous, 0% unmapped; (b) recode
   Duncan 0.0103 vs 0.0114 baseline (ratio 0.90); (c) per-group ratios 0.80–0.99 — **PASS**. R4 is
   relabelled an **argmax-split proxy**: it differs from the modal map in only **5 of 538 codes**,
   so it bounds parent-override sensitivity, not full crosswalk uncertainty.

6. **tau_paths.csv and fig1 rebuilt from the Octave estimator.** The prior Python weighted mean
   mismatched the paper's Octave `Mean(weighted)` in early periods (BW 1960 7.90 → **6.685**; WW
   1960 6.85 → 6.818). The garbage `mean_tauH_wt` column (1e5–1e10, from empty cells) was dropped.
   The missing 1960-2010 L3/L6 stability rows were added (7-period run t1=6: L3 41.3, L6 33.6/1.2/3.7).

7. **robustness_summary.csv column labels fixed** — the τʰ/τʷ columns actually held Ywkr/Cons; they
   now hold the true τʰ-only and τʷ-only Ymkt shares (primary L3 34.2/6.2, L4 5.4/1.5).

8. **Dropped deliverables added:** L7 (WW τ̂ 2023 — doctors 1.01, lawyers 1.04, construction 6.33,
   secretaries 0.38), L2 (young relative-propensity SD, declining), L8 (earnings market after-tauw + LFP, data
   vs model 2023: 64,080/60,918 — model 4.9% below — and 0.792/0.790; the 2010 row 55,304/57,257
   equals the replication's Table IV 41,541/42,717 in 2023 dollars, same convention), L9 (annual relative-propensity SD 2017-19 &
   2021-24; literal-white coding RAC1P==1, not W*), and the figure CSVs.

9. **003 theory wording corrected** (see `003_theory_corrections.md`): τʷ is **not** flat for white
   women (47% of their decline; 51% R5); the Hurst-Rubinstein-Shimizu paraphrase is corrected (the
   adjusted gap stayed flat **even as** discrimination fell); [PROJECTED] tags added to the headline
   and the ~8.8%-unrealised metric; a projection error band is stated (WW backtest 0.193 ≫ projected
   0.049 decline, so ~0.08%/decade is inside the law's error); the continued/slowed cut-off is
   declared the study's own post-hoc choice (WW borderline, 0.341 vs 1/3).

## Method (plain language)

The paper is a Roy model of occupational choice (Fréchet talent θ=2, CES σ=3) in which
group×occupation frictions — a labour-market wedge τʷ and a human-capital cost τʰ, composed into
τ̂ — are backed out from relative occupational propensities and relative wage gaps for four groups
(white men as the frictionless reference, white women, Black men, Black women). The living-update
added one pooled 2022-2024 ACS "2023" period built the paper's own way (keyless Census PUMS + a
public 2018→HHJK occupation crosswalk, anchored end-to-end on 2010-2012), with race bridged across
the 2020 coding change, and L4 co-reported under the paper 2010 deflator and a corrected one. This
corrective study re-used every `.mat` file and the staged Octave stage-split tooling, re-running
only the pieces the audit named: the 2023 level-scale sensitivity, LivingDefl L6, the Gate-2b array
dump, Gate 4, the t1=6 stability rows, and the intermediate deflator — all foreground, no installs,
no fetches.

## Bottom line

The living-update's conclusion survives the corrections: falling frictions contributed only a few
percent of 2010-2023 market-GDP/person growth (far below the ~40% of 1960-2010), and ~9% of output
remains on the table in 2023. But three claims needed honesty: **Gate 3b FAILED**; the
**"essentially unchanged" framing belongs on the absolute contribution (0.04→0.06 pp/yr), not on
the deflator-sensitive share**; and the model's **post-2010 decline is only τʰ-dominated for Black
men and women — for white women τʷ carries about half**.
