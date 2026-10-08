# Follow-up Study 002/003 (theory-update) — what the post-2010 trajectory says about the model

*HHJK (2019) "The Allocation of Talent and U.S. Economic Growth." Study B (§B of the
instruction), launched in slot `003-theory-update` with `--timeout 14400`. Reuses the
living-update (001, finished by its continuation `002-living-update-cont`); **no new data
fetched**; new Octave runs only for the counterfactual projections, stage-split per §0.4.*

## Question

HHJK estimate that falling group×occupation frictions (τ) account for 41.5 % of 1960–2010
market-GDP-per-person growth and that 9.9 % of output remained on the table in 2010. The
living-update (001) extended the series to a pooled 2022–2024 "2023" period and found the
friction contribution had fallen to ~7 % per decade. **This study asks what that post-2010
trajectory says about the model itself:** (1) is the slowdown a *stall/reversal*, or the
*convergence the model always implied*? (2) which margin — pre-market τʰ or labour-market
τʷ — does the model attribute the post-2010 change to? (3) what does the fitted trajectory
imply for *remaining* output gains going forward? (4) write down the updated model.

## Approach

**Reused unchanged (read from disk, not re-run):** 001's 7-period friction estimates in the
saved `.mat` files — `meanlogtau`/`varlogtau` (earnings-weighted mean and variance of ln τ̂
by group×period) and the τʰ/τʷ arrays (`TauH_T`, `TauW`) — from
`001-living-update/workspace/cases/{Living,R5_unscaled,R8_bands,R1_WNH,R2_Wlit,R3_2024,R4_SPLIT}/TalentData_Benchmark.mat`,
and the 2023 baseline equilibrium `SolveEqmBasic_Benchmark.mat` (GDP per person 71 641,
market GDP/person 61 793). The living-update's headline numbers (L3 38.5 %, L4 7.0 %,
L5 9.0 %) are its inputs here.

**What this study did:**
1. **Items 1,2,4 in Python** (`analyze_theory.py`) from the saved estimates — no model
   re-run needed. Convergence-law fits by nonlinear least squares (1960 anchored),
   backtest, out-of-sample test, per-decade rates, pre-registered stall classification, and
   the exact τʰ/τʷ decomposition of ln τ̂ (= η·E_w[ln(1+τʰ)] − E_w[ln(1−τʷ)]).
2. **Item 3 (projection) in Octave** (`project_tau.m`, 4 fresh `SolveForEqm` solves per
   spec, each ≤ 66 s, stage-split through `run_stage.sh` with the 540 s backstop, never
   backgrounded). Holds A, φ, z̃, q, TExperience and periods 1–6 at their 2023/estimated
   values; pushes the period-7 (2023) composite friction for WW/BM/BW along the fitted law
   to 2033/2043/τ∞, realised as a parallel shift of −ln(1−τʷ) in period 7 (which moves the
   earnings-weighted mean ln τ̂ by exactly the law-implied Δ — validated each run, and a
   zero-shift run reproduces 001's baseline to the digit). Only period 7 changes.

## Results

### Item 1 — the friction-convergence law and the stall test

Law fit on 1960–2010 (true midpoint years), per group (`convergence_law.csv`):

| group | λ (yr⁻¹) | half-life | τ∞ (level) | obs 2023 (ln τ̂) | law pred 2023 | OOS err | backtest e | band b |
|---|---|---|---|---|---|---|---|---|
| WW | 0.040 ± 0.013 | 17.2 yr | 1.28 ± .20 | 0.397 | 0.352 | 0.046 | 0.193 | 0.193 |
| BM | 0.098 ± 0.007 |  7.1 yr | 1.42 ± .01 | 0.332 | 0.351 | 0.019 | 0.010 | 0.046 |
| BW | 0.050 ± 0.010 | 13.9 yr | 1.60 ± .11 | 0.566 | 0.524 | 0.042 | 0.125 | 0.125 |

The 7-period-input fit (001's 7-period estimates, per HHJK-B2) and the original 6-period-input
fit agree closely (e.g. WW λ 0.0402 vs 0.0408, τ∞ 1.284 vs 1.322; `convergence_law.csv`,
`lambda_6p`/`tau_inf_6p`) — the small gap is the averaged-earnings-weight effect 001 traced,
not a change in estimated frictions.

**Per-decade annualized decline in mean ln τ̂ and classification** (`decade_rates_and_stall.csv`):

| group | 1960–80 | 1980–2000 | 2000–10 | 2010–23 | avg 1960–2010 | 2010–23 as frac of avg | 2023 above law | class |
|---|---|---|---|---|---|---|---|---|
| WW | 0.0366 | 0.0155 | 0.0009 | 0.0070 | 0.0206 | 0.34 | +0.046 < b=0.193 | **continued** |
| BM | 0.0236 | 0.0023 | 0.0013 | 0.0013 | 0.0105 | 0.13 | −0.019 < b=0.046 | **slowed** |
| BW | 0.0422 | 0.0125 | 0.0010 | 0.0042 | 0.0217 | 0.19 | +0.042 < b=0.125 | **slowed** |

**No group stalled or reversed.** WW's 2010–23 decline is 34 % of its historical average
(≥ 1/3 → continued). BM and BW decelerated below 1/3 of their historical pace, but their
2023 points sit **within** the band of their own 1960–2010 law's extrapolation (above-law
gap < b) → **slowed, not stalled**. The pre-registered reading: the post-2010 deceleration
is the exponential approach to the floor that the convergence law always implied — the
engine is running out of fuel, not seizing.

**Honest caveat on power.** The band b = max(R1–R4 spread, backtest error). WW and BW have
**large backtest errors** (0.193, 0.125) — the 1960–2000 fit predicts 2010 poorly for them —
so their bands are wide and "not stalled" is a **low-power** verdict there. **BM's backtest
is tight** (0.010), so BM's "slowed" is confident. No backtest error exceeds the group's full
1960–2010 decline (WW 1.05, BM 0.53, BW 1.10), so no group is "not classifiable."

### Item 2 — τʰ vs τʷ split of the 2010→2023 change

Exact decomposition of the change in mean ln τ̂ (`tauWtauH_split_2010_2023.csv`):

| group | Δ mean ln τ̂ | τʰ part | τʷ part | τʰ share | τʷ share |
|---|---|---|---|---|---|
| WW | −0.084 | −0.045 | −0.040 | 53 % | 47 % |
| BM | −0.016 | −0.020 | **+0.004** | 126 % | −26 % |
| BW | −0.051 | −0.044 | −0.006 | 88 % | 12 % |

The post-2010 friction decline is **τʰ-dominated** (pre-market / human-capital access),
with the **labour-market wedge τʷ essentially flat** (for BM it rose slightly). This survives
R5 (unscaled interval: WW 49 / BM 99 / BW 79 % τʰ) and R8 (cohort-following bands:
WW 53 / BM 122 / BW 64 % τʰ).

**Relation to Hurst–Rubinstein–Shimizu (2024).** HRS document that adjusted Black–white wage
gaps have been roughly **flat since ~1980** even as measured labour-market discrimination is
low/declining. In HHJK's accounting, τʷ is the labour-market-wedge analogue of
"discrimination"; the model here says τʷ is **flat post-2010** and the residual friction
movement is **pre-market (τʰ)** — the same division of labour HRS emphasise. The attribution
(post-2010 change is pre-market, not labour-market) **survives R5 and R8**.

### Item 3 — remaining-gains projection [PROJECTED, conditional on the fitted law, A, φ, z̃, q held at 2023]

Re-solving 001's 2023 equilibrium with τ on the fitted law (`projection_results.csv`):

| horizon | primary ΔYmkt | R5 | R8 | annualized (primary) |
|---|---|---|---|---|
| 2023→2033 | **+0.075 %** | +0.073 % | +0.081 % | 0.0075 %/yr |
| 2023→2043 | **+0.126 %** | +0.122 % | +0.135 % | 0.0063 %/yr |
| 2023→τ∞ (full convergence) | **+0.227 %** | +0.220 % | +0.244 % | — |

Compared with the **paper's 1960–2010 falling-τ contribution of ≈ 0.69 %/yr** (41.5 % of the
1.66 %/yr market-GDP-per-person growth over 1960–2011), the projected forward contribution
(~0.008 %/yr) is **~90× smaller**. Even pushing τ all the way to the fitted floor adds only
~0.23 % of output; the floors τ∞ ≈ 1.28–1.60 (well above the frictionless 1.0) mean
**~8.8 % of output stays permanently unrealised** — close to L5's 9.0 % "remove-all-frictions"
gain, of which the law says almost none will be captured by the convergence trend.
*These numbers are a conditional illustration of the fitted law, not a GDP growth forecast.*

### Item 4 — the written-down updated model

**Updated parameters** (primary; s.e. in `convergence_law.csv`):

| group | λ_g (yr⁻¹) | τ∞_g (level) | robustness range of τ∞ (R1–R4 incl.) | 2023 composition of ln τ̂ |
|---|---|---|---|---|
| WW | 0.040 | 1.28 | ~1.26–1.30 | 72 % τʷ / 28 % τʰ |
| BM | 0.098 | 1.42 | ~1.40–1.43 | 24 % τʷ / 76 % τʰ |
| BW | 0.050 | 1.60 | ~1.55–1.64 | 58 % τʷ / 42 % τʰ |

(WM is the frictionless reference, τ ≡ 1.) A convergence law also fits Var ln τ̂ with floors
1.81 (WW), 1.10 (BM), 1.27 (BW) — dispersion is converging too, though the BW variance law is
weakly identified (`convergence_law.csv`, `var_ln_tau` rows).

**One-paragraph claim the paper should make now:** *"Through 2023, the measured group×occupation
frictions continue to fall, but at a decelerating rate that is well described by partial
adjustment toward a non-zero floor (half-lives of 7–17 years, floors τ∞ ≈ 1.3–1.6 — frictions
do not vanish). The deceleration since 2010 is not a stall or reversal; it is the convergence
the data always implied. What movement remains is overwhelmingly on the pre-market
human-capital margin (τʰ): the labour-market wedge τʷ has been roughly flat since 2010 for
Black men and women, echoing Hurst–Rubinstein–Shimizu (2024). Consequently the growth
contribution of falling frictions, which averaged ≈ 0.7 %/yr of market GDP per person over
1960–2010, is now on the order of 0.01 %/yr, and even full convergence to the estimated floor
would add only ~0.2 % to output. The large talent-misallocation gains of the late 20th century
were a one-time reallocation that is now nearly complete."*

## Comparison to the originals

| quantity | original / 001 value | this study | source of original |
|---|---|---|---|
| Falling-τ share of 1960–2010 growth | 41.5 % | (context) | replication `HowMuchPoorer_Benchmark.log` |
| Falling-τ share of 2010–2023 growth (L4) | 7.0 % (001) | consistent (deceleration) | `002-living-update-cont/results/growth_shares.csv` |
| Remaining gain if all τ removed, 2023 (L5) | 9.0 % (001) | floor leaves ~8.8 % permanent | `remaining_gain.csv` |
| Post-2010 margin | — (new) | τʰ-dominated (53–126 %) | this study |
| Stall verdict | qualitative "less optimistic" (C12) | continued (WW) / slowed (BM,BW); no stall | this study |
| Forward friction dividend | — (new) | +0.08 %/decade, ~90× below historical | this study [PROJECTED] |

## Deviations & limitations

- **Projection margin (declared).** The composite-friction decline is realised through the
  labour-market wedge τʷ (period-7-only, so the projection is a clean comparative static and
  the zero-shift run reproduces the baseline exactly). Realising it through τʰ instead would
  change the exact output level modestly; the projection numbers are small and robust across
  R5/R8, and are labelled conditional throughout. The projection holds the cross-occupation
  **dispersion** at 2023 (a parallel shift of the mean); the fitted variance law is reported
  in item 4 but not imposed on the projection.
- **Low forecasting power for WW/BW** (backtest e = 0.19, 0.13): the "not stalled" verdict for
  those groups is weak by construction of the pre-registered band; BM is the one confident call.
- **Pre-registration honoured.** λ, τ∞, the stall thresholds, the band definition, the
  consistent-input rule (B2), the backtest (B1), the [PROJECTED] labels (B3) and the
  stage-split execution (B4) are all applied verbatim from the spec.
- **Identification (risk 5).** τ is backed out from relative wages and shares; if preference
  sorting (δ>0) or task-return shifts moved after 2010, part of the measured τʰ/τʷ split is
  not literally "friction." The 2022–2024 window is a tight post-pandemic labour market
  (risk 4). These caveats are inherited from 001.
- **Scope.** Study A (001/§A) was out of this launch's scope and was not re-run; its completed
  artifacts are the inputs here. R7 (θ sweep) was optional and not run.

## Key files (`results/`)
`convergence_law.csv`, `decade_rates_and_stall.csv`, `tauWtauH_split_2010_2023.csv`,
`projection_results.csv`, `projection_deltas*.json`, `theory_analysis.json`,
`friction_series.json`, `findings.md`, `written model` (this report §Item 4),
`fig1_convergence_law.png`, `fig2_split_and_projection.png`, and the projection case logs
under `workspace/cases/Proj_*/`.
