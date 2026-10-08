# 004 — Corrective study: honest gates, completed deliverables, corrected presentation
### HHJK (2019), "The Allocation of Talent and U.S. Economic Growth" — post-2010 living-update (supersedes 001/002/003 cards)

## Question

The provenance audit of the HHJK living-update studies (001 living-update, 002 its continuation,
003 theory-update) found the **model work sound** — every headline number traces to a case log,
and Gates 1, 2, 2b(i), 2b(iii), 3, 5, 6 are genuine passes — but found that **binding gate rules
and reporting rules were overridden, relabelled, or met only on paper**, and that spec deliverables
were dropped without a continuation. This study implements the audit's authoritative fix list (§8):
report a failed gate as FAILED (no invented "semantic PASS"); use the spec's honest-partial path
where a failure is survivable and state the consequence; finish every dropped deliverable; and
correct the public presentation. It reuses 001/002/003 `.mat` files and the staged Octave
stage-split tooling, re-running only what the fixes require (≈1 h of compute), foreground only, no
installs, no fetches.

## Approach — what was reused, what was re-run

**Reused unchanged (read from disk):** the authors' Matlab model under Octave 6.4 (the replication's
validated port) in each case directory; the 7-period `Living`/`LivingDefl` cases' `TalentData_*` and
`SolveEqmBasic_*` `.mat` files; the staged crosswalks and PUMS parquets; and the prior studies'
logs and reports (the source of every "original" value below).

**Re-run (foreground, stage-split, ≤540 s backstop; longest stage ≈283 s):**
- 2023 level-scale sensitivity: `Living` S1-S3 + `t6_7` c1 with the 2023 earnings level rescaled
  (1/1.019, 1/1.016, +1.9%, and pce(2010)≈104.0).
- `LivingDefl` L6 group chunks (`t6_7` c3/c4/c5).
- `Living` 1960→2010 stability chunks (`t1_6` c1/c3/c4/c5) on the 7-period case.
- Gate 2b(ii) array dump from the production `how_much_poorer.m` at t0=1970 and t0=2010.
- Gate 4 crosswalk audit (`scripts/04`) in-run.

**Environment note.** gnuplot is unavailable and installs are forbidden, so Octave's figure calls
are stubbed with no-op graphics shims; all figures are re-plotted in Python per the spec. The shims
were verified numerically clean (the earnings-invariant `meanlogtau` is byte-identical between a
scaled re-run and the prior `Living` output).

## Results

### 1. Gate 3b — FAILED (relabelled from "semantic PASS"), with a quantified consequence

The pre-registered rule passes only if one route passes **all four** tolerances. The earnings-level
tolerance (d, ≤1%) fails under **every** route:

| Route | (a) pop share | (b) Duncan | (c) ln-wage | (d) earnings | pass all? |
|---|---|---|---|---|---|
| 1-yr pool, pre-registered (ADJINC×PCE) | 1.18% | 0.0018 | 0.0168 | **1.80%** | No |
| 1-yr pool, ADJINC-only (post-hoc) | 1.18% | 0.0018 | 0.0079 | 0.59% | No |
| 2012 1-yr alone | 2.82% | 0.0174 | 0.0212 | 1.34% | No |
| 3-year file (fetched) | 0.0000 | 0.0000 | 0.0190 | **1.92%** | No |

The prior study recorded `GATE3B_PASS=false`, then added a non-spec `semantic_pass=true` field and
proceeded. **Reported here as FAILED.** The 2023 results are retained via the spec's honest-partial
path, and the level-convention consequence is quantified by rescaling the 2023 earnings level
(τ̂ is exactly invariant to a uniform 2023 scale — `meanlogtau` byte-identical — so L4 moves only
through the 2010→2023 actual-growth denominator):

| 2023 earnings level | L4 Ymkt (τʷτʰ) | τʰ-only | τʷ-only | L5 (2023) |
|---|---|---|---|---|
| ×1.000 (paper, unchanged) | 7.0 | 5.4 | 1.5 | 9.0 |
| ×1/1.016 (−1.6%) | 8.1 | 6.2 | 1.8 | 9.0 |
| ×1/1.019 (−1.9%) | 8.4 | 6.4 | 1.8 | 9.0 |
| ×1.019 (+1.9%, reverse check) | 6.1 | 4.6 | 1.3 | 9.0 |
| pce(2010)≈104.0 ("≈2011 dollars") | 5.9 | 4.5 | 1.3 | 9.0 |

L4 ranges ~6.1–8.4% (≈±0.5 pp per 1% of 2023 level); **L5 is exactly invariant at 9.0**. The audit's
inference that the shipped "2010" earnings are ≈2011 dollars (so pce(2010)=106.17 over-corrects and
the true L4 lies **between 5.2 and 7.0**; the pce≈104.0 run gives 5.9) is a **hypothesis, not a
finding**. The out-of-trigger 2010-2012 3-year PUMS fetch (two tolerances were failing, not
population-shares-only) is disclosed.

### 2. Lead statement — absolute contribution is deflator-robust; the share is not

| Window | Share % (paper) | Share % (corrected) | Absolute pp/yr (**both** conventions) | Actual mkt-GDP/person growth (paper / corrected) |
|---|---|---|---|---|
| 2000-2010 (L4b) | 7.3 | **29.2** | **0.04** | 0.58%/yr / 0.15%/yr |
| 2010-2023 (L4) | 7.0 | 5.2 | **0.06** | 0.89%/yr / 1.22%/yr |

The **absolute** contribution of falling frictions (the Difference-row Ymkt) is **0.04 pp/yr
(2000-10) and 0.06 pp/yr (2010-23) under both conventions** — not slowing. The share swings only
because the denominator (actual growth) moves: the corrected 2010 deflator raises the 2010 level,
compressing 2000-2010 actual growth to 0.15%/yr and so inflating L4b to 29.2%. "Essentially
unchanged since 2000-10" is retained only as a convention-qualified statement.

### 3. Mean composite friction τ̂ — Octave estimator (corrects fig1 / tau_paths)

| group | 1960 (prior Python → Octave) | 2010 | 2023 |
|---|---|---|---|
| White women | 6.85 → **6.818** | 2.232 | 1.946 |
| Black men | 2.88 → **2.871** | 1.494 | 1.459 |
| Black women | **7.90 → 6.685** | 2.543 | 2.372 |

`tau_paths.csv` and `fig1` are rebuilt from the paper's Octave `Mean(weighted)` rows; the garbage
`mean_tauH_wt` column (1e5–1e10, empty cells) is dropped.

### 4. Stability (gate 7)

Raw per-occupation τ̂ for 1960-2010 is **identical** between the 6- and 7-period runs (max relative
difference 4.6e-16, identical finite-cell pattern), so the masked `GetTExperience` re-run is **moot**
(unchanged raw τ̂ ⇒ unchanged experience profiles). The 1.6–2.7% mean-τ̂ shifts are a pure
`earningsweights_avg` reweighting (demonstrated: identical raw τ̂ under the 6- vs 7-period weight
reproduces WW 1960 6.966→6.853, the same −1.6% as the Octave 6.930→6.818). The **headline share
estimands are stable**: the 7-period run's 1960→2010 L3 = 41.3 (vs 41.5), L6 WW/BM/BW = 33.6/1.2/3.7
(vs 33.8/1.2/3.7) — all ≤0.2 pp (`stability_1960_2010*.csv`, `stability_trace.txt`).

### 5. Gates 2b(ii) and 4

- **2b(ii) PASS (real):** the `TauW_alt/TauH_alt/Z_alt` arrays dumped from the production code at
  t0=1970 and t0=2010 match the rule. At t0=2010, τʷ is held at 2010 only in period 7, and τʰ/z̃ are
  reset only for the 2023-young cohort — the 1990/2000-young incumbents keep their own estimates,
  the exact path L4 depends on (`gate2b_assignment_arraydump.json`).
- **4 PASS (recomputed in-run):** (a) 96.46% unambiguous, 0% unmapped; (b) 0.0103 vs 0.0114; (c)
  group ratios 0.80–0.99. R4 is relabelled an **argmax-split proxy** (differs from the modal map in
  5 of 538 codes), not a true fractional SPLIT (`gate4_crosswalk.json`).

### 6. Completed deliverables

- **LivingDefl L6** (2010-23, corrected deflator): WW 3.8 / BM 0.5 / BW 0.8; `group_shares.csv` filled.
- **robustness_summary.csv** relabelled to the true τʰ-only/τʷ-only Ymkt shares.
- **L7** WW τ̂ 2023: Doctors 1.01, Lawyers 1.04, Construction 6.33, Secretaries 0.38 (doctors/lawyers
  ~8–12 in 1960 → ~1 by 2010/2023; construction stays high; secretaries <1).
- **L2** young relative-propensity SD, declining (WW 2.25→1.48, BM 1.26→0.71, BW 2.29→1.81).
- **L8** Table IV 2023 fit, 'Earnings (market, after tauw)': data 64,080 / model 60,918 (model
  4.9% below; the 2010 row 55,304/57,257 equals the replication's Table IV 41,541/42,717 in 2023
  dollars, same convention); LFP 0.792 / 0.790.
- **L9** annual relative-propensity SD 2017-19 & 2021-24 (roughly flat; cross-checks L2).
- figure CSVs for fig1 and fig2.

### 7. 003 theory corrections (`003_theory_corrections.md`, `card_corrections.csv`)

τʷ is **not** flat for white women (47% of their 2010-23 decline; 51% under R5) — only flat for
Black men and minor for Black women; the Hurst-Rubinstein-Shimizu paraphrase is corrected (adjusted
gap flat **even as** discrimination fell); [PROJECTED, conditional] tags added to the headline and
the ~8.8%-unrealised metric; a projection error band is stated (WW backtest 0.193 ≫ projected 0.049
ln-τ decline, so ~0.08%/decade is inside the law's own error); the continued/slowed cut-off is the
study's own post-hoc choice (WW borderline, 0.341 vs 1/3); the forward 0.0075%/yr is also compared
with the measured 2010-23 ~0.06%/yr, not only 1960-2010.

## Comparison to the prior studies

| Quantity | Prior (001/002/003) | This study (004) | Source of prior value |
|---|---|---|---|
| Gate 3b label | "semantic PASS" | **FAILED** | 002 result_card.json / anchor_3b.json |
| Lead on 2010-23 contribution | "essentially unchanged from 7.3% (share)" | **0.04→0.06 pp/yr, both conventions** | 002 report.md |
| L4b corrected on the card | omitted | **29.2% paired with L4 5.2%** | 002 result_card.json |
| mean τ̂ BW 1960 | 7.90 (Python) | **6.685 (Octave)** | 002 tau_paths.csv |
| robustness τʰ/τʷ cols | Ywkr/Cos mislabelled | **true τʰ/τʷ-only Ymkt** | 002 robustness_summary.csv |
| Gate 4 (b)/(c) | cited Phase-2a | **recomputed in-run** | 002 audit_crosswalk.json |
| Gate 2b(ii) | tautological | **real array dump, PASS** | 002 tau_assignment… csv |
| group_shares.csv | empty | **filled + LivingDefl L6** | 002 group_shares.csv |
| R4 | "SPLIT crosswalk" | **argmax-split proxy (5/538)** | 002 report.md |
| 003 "τʷ flat" | all groups | **not WW (47%)** | 003 report.md |

## Deviations & limitations

- **Gate 3b retained-results decision.** The gate FAILED; the model results are kept via the spec's
  honest-partial path because the failure is an earnings-level convention, bounded by the
  sensitivity (L4 6.1–8.4%, L5 invariant). This is a deliberate, disclosed departure from the literal
  stop rule, matching the audit's own recommendation. If a strict reading is preferred, the honest
  summary is "3b failed; the 2023 point is a level-convention-bounded estimate, not an anchored one."
- **R4 relabelled, not re-run** as a true fractional SPLIT (that needs a rebuilt 2023 data pipeline);
  the honest-relabel option the audit offered was taken, with scope (5/538 codes) stated.
- **pce(2010)≈104.0** is an optional illustration of the "≈2011 dollars" hypothesis (L4=5.9), not a
  finding.
- **Octave figures stubbed** (no gnuplot, installs forbidden); numerics verified invariant.
- **003 corrections** are delivered as `results/003_theory_corrections.md` + `card_corrections.csv`,
  not by editing the read-only 003 directory.
- Inherited caveats stand: race-coding break across 2020 (W* bounds it), cohort non-overlap across
  the 12-year step (R8), post-pandemic 2022-2024 composition, and the identification assumption that
  measured τ moves are frictions (not preference/task-return shifts).

## Key files

`results/`: `findings.md`, `card_corrections.csv`, `tau_paths.csv`, `group_shares.csv`,
`robustness_summary.csv`, `stability_1960_2010.csv` (+`_shares.csv`, `stability_trace.txt`),
`tau_assignment_t0_1970_t1_2010.csv`, `gate2b_assignment_arraydump.json`,
`L2_sd_ln_relprop_young.csv`, `L7_WW_tau_by_occupation.csv`, `L8_tableIV_fit_2023.csv`,
`L9_annual_sd_ln_relprop.csv`, `fig1_tauhat_by_group_1960_2023.png` (+`.csv`),
`fig2_L4_deflator_share_vs_absolute.png` (+`.csv`), `stage_timings.csv`, `003_theory_corrections.md`.
`gates/`: `gate3b_anchor.json`, `gate4_crosswalk.json`, `gate4_script04_output.txt`,
`gate4_R4_proxy.json`.
