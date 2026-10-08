# 003 (theory-update) corrections — findings addendum + corrected card fields

This corrective study (004) supersedes the `003-theory-update` card and the wording of its
findings/report where they are wrong or under-qualified. The underlying numbers trace to disk
and stand; what changes is the wording, the tags, and one substantive claim (τʷ for white
women). All values below are read from `003-theory-update/results/` on disk.

## 1. "τʷ flat" is false for white women — it is ~half of their decline

`tauWtauH_split_2010_2023.csv` (exact decomposition of Δ mean ln τ̂, 2010→2023):

| group | ΔlnτH share (τʰ) | ΔlnτW share (τʷ) | reading |
|---|---|---|---|
| White women | 53.0% | **47.0%** (51.0% under R5; 46.6% R8) | **≈ 50/50, NOT τʰ-dominated** |
| Black men | 126.0% | −26.0% (τʷ **rose**) | τʰ-dominated; τʷ flat/slightly up |
| Black women | 87.7% | 12.3% (36.0% R8) | τʰ-dominated; τʷ minor |

**Corrected claim:** the post-2010 friction decline is τʰ-dominated **for Black men and Black
women**, but for **white women the labour-market wedge τʷ accounts for about half (47%, and 51%
under R5)** of the decline. The 003 headline/card statement "the labour-market wedge τʷ flat"
(all groups) overstates: it is flat only for BM and minor for BW, and is **not** flat for WW.

## 2. Hurst–Rubinstein–Shimizu (2024) paraphrase corrected

- **003 (wrong):** "flat adjusted Black–white wage gaps since ~1980 *alongside* low/flat measured
  labour-market discrimination."
- **Corrected:** HRS document that the **adjusted Black–white male wage gap stayed roughly flat
  since ~1980 EVEN AS taste-based/measured discrimination FELL**, because returns to Abstract
  tasks rose. The "consistent with HRS" framing must be rewritten around *flat-gap-despite-falling-
  discrimination*, not *flat-gap-alongside-flat-discrimination*. (And since τʷ is ~half of WW's
  decline, HHJK's τʷ is not uniformly "flat" the way the 003 text implies.)

## 3. [PROJECTED] tags (spec B3) added

- **Headline projection:** must read **"[PROJECTED, conditional on the fitted law, A, φ, z̃ and q
  held at 2023; NOT a growth forecast] the forward friction 'dividend' is ~0.08%/decade"** — the
  003 card headline used a lowercase "projected" without the conditional tag.
- **"~8.8% permanently unrealised" metric:** add the same **[PROJECTED, conditional …]** tag — in
  003 it carried no tag at all. (It is 9.0 (L5) − 0.227 (τ→τ∞), a derived projected quantity.)

## 4. Projection error band (the projection has essentially no forecasting power for WW/BW)

From `convergence_law.csv` / `decade_rates_and_stall.csv`:

| group | backtest error e (1960-2000→2010) | band b | projected 2023→2033 ΔlnτH decline | full 1960-2010 decline |
|---|---|---|---|---|
| WW | **0.193** | 0.193 | **≈ 0.049** | 1.052 |
| BM | 0.010 | 0.046 | small | 0.528 |
| BW | 0.125 | 0.125 | small | 1.102 |

**Required statement next to the projection:** white women's backtest error (0.193) is ~4× the
projected 2023→2033 ln-τ decline (≈0.049), so the ~0.08%/decade forward dividend **sits well
inside the convergence law's own demonstrated forecast error** for WW (and BW). Only Black men's
law backtests tightly (e=0.010). The projection is a conditional illustration, not a forecast,
and for WW/BW it is low-power.

## 5. continued/slowed cut-off is the study's own post-hoc choice; WW is borderline

The spec pre-registers only "stalled" and "not classifiable". The **continued vs slowed line (the
2010-23 annualized decline ≥ 1/3 of the 1960-2010 average ⇒ "continued")** is 003's **own post-hoc
choice**, and must be declared as such. **White women sit on the knife edge: frac_recent_of_avg =
0.341 vs the 1/3 = 0.333 line** (`decade_rates_and_stall.csv`). WW's "continued" is therefore a
hair's-breadth call; "continued/slowed" should be presented as a soft, author-chosen boundary.

## 6. Forward dividend compared with the nearest baseline, not only 1960-2010

003 compared the projected ~0.0075%/yr only with the 1960-2010 average (~0.69%/yr, "~90× smaller").
It should **also** be compared with the **measured 2010-2023 contribution of ≈0.06%/yr** (this
study, Difference-row Ymkt). The forward dividend is ~8× smaller than even the decade just measured
— a sharper and more honest framing than the 90× vs the 1960-2010 peak.

## Corrected 003 card fields (apply to 003-theory-update/result_card.json)

- **headline:** "… what little decline remains is pre-market (τʰ) **for Black men and women, while
  for white women τʷ is ~half the decline** …; **[PROJECTED, conditional on the fitted law, A, φ,
  z̃, q held at 2023; not a growth forecast]** the forward friction dividend is ~0.08%/decade, ~90×
  below 1960-2010 **and ~8× below the measured 2010-23 ~0.06%/yr**."
- **metric "Post-2010 friction decline attributed to pre-market tauH" note:** "τʷ flat for BM
  (rose), minor for BW (12%), **but ≈ half of WW's decline (47%; 51% R5)**; HRS: adjusted gap flat
  EVEN AS discrimination fell."
- **metric "Output permanently unrealised …":** prepend **[PROJECTED, conditional …]**.
- **stall-classification notes:** add "continued/slowed line is this study's own post-hoc choice;
  WW borderline (0.341 vs 0.333). WW/BW projections are low-power (backtest e 0.193/0.125 ≫ projected
  0.049 decline)."
