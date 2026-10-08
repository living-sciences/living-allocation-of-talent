# Study 002/003 (theory-update) — findings

## Method (plain language)

This study does **not** touch any new data. It reuses the frictions (τ̂, and its τʷ/τʰ
split) that the living-update (001) estimated with HHJK (2019)'s own Roy model — the
authors' Matlab under Octave, extended to a 7th period (pooled 2022–2024 ACS, "2023").
On top of 001's **7-period estimates** it does four things, all pre-registered in the
spec before 001's numbers existed:

1. **Fits a friction-convergence law per group.** Each group's earnings-weighted mean
   ln τ̂ is modelled as partial-adjustment convergence toward a floor τ∞:
   ln τ_t = ln τ∞ + (ln τ_1960 − ln τ∞)·e^(−λ(t−1960)), time in true pool-midpoint years
   (1960…2000, 2011, 2023). (λ, τ∞) are estimated on **1960–2010 only**, then the law is
   **backtested** (fit 1960–2000, predict 2010) and tested **out-of-sample** against the
   2023 estimate. A pre-declared stall test classifies each group.
2. **Splits the 2010→2023 friction change** into its pre-market (τʰ) and labour-market
   (τʷ) components, under the primary spec and under R5/R8, and relates it to
   Hurst–Rubinstein–Shimizu (2024).
3. **Projects remaining output gains** by re-solving 001's 2023 general equilibrium
   (A, φ, z̃, q held at 2023) with τ pushed along the fitted law to 2033, 2043 and the
   floor τ∞ — four new Octave `SolveForEqm` solves per spec, stage-split per §0.4. Every
   projected number is tagged **[PROJECTED, conditional on the fitted law with A, φ, z̃, q
   held at 2023]** and is **not** a growth forecast.
4. **Writes down the updated model** (λ_g, τ∞_g, the 2023 τʷ/τʰ composition) and the
   one-paragraph claim the paper "should say now."

## Headline results

- **Stall classification (mean ln τ̂):** WW = **continued** (2010–23 decline is 34 % of the
  1960–2010 average rate, ≥ 1/3), BM = **slowed**, BW = **slowed**. **No group stalled or
  reversed.** Every group's 2023 point lies *within* the band b of its own 1960–2010 law's
  extrapolation, so the post-2010 deceleration is **what exponential convergence predicts**,
  not a break from it.
  - Caveat (honest): the band b = max(R1–R4 spread, backtest error). WW and BW have **large
    backtest errors** (e = 0.193, 0.125 in ln-τ units), so their bands are wide and the
    "not stalled" verdict for them is **low-power** — the law simply has weak short-horizon
    forecasting skill for WW/BW. **BM's backtest is tight** (e = 0.010), so BM's "slowed" is
    a confident call. No group's backtest error exceeds its full 1960–2010 decline, so none
    is "not classifiable."
- **τʷ/τʰ split of the 2010→2023 decline:** **τʰ-dominated** — WW 53 % τʰ, BM 126 % τʰ
  (τʷ ticked *up*), BW 88 % τʰ. Robust across R5 (WW 49/BM 99/BW 79 % τʰ) and R8
  (WW 53/BM 122/BW 64 % τʰ). The model attributes almost all of the post-2010 friction
  decline for Black groups to the **pre-market human-capital margin**, with the
  **labour-market wedge τʷ flat** — consistent with **Hurst–Rubinstein–Shimizu (2024)**,
  who find adjusted Black–white wage gaps roughly flat since ~1980 alongside low/flat
  measured labour-market discrimination.
- **Remaining-gains projection [PROJECTED]:** continuing the fitted law raises 2023 market
  GDP/person by **+0.08 % by 2033, +0.13 % by 2043, +0.23 % at full convergence (τ→τ∞)**
  (robust: R5 0.07/0.12/0.22 %, R8 0.08/0.14/0.24 %). Annualized ≈ **0.008 %/yr** — versus
  the paper's 1960–2010 falling-τ contribution of **≈ 0.69 %/yr** (41.5 % of 1.66 %/yr
  market-GDP growth): the friction "dividend" going forward is **~90× smaller** than it was
  historically. Even full convergence to the fitted floor leaves **~8.8 %** of output on the
  table permanently (the floors τ∞ ≈ 1.28–1.60 are well above the frictionless 1.0).

This turns HHJK's qualitative "less optimistic after 2010" (C12) into a conditional number.
