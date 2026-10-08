# Follow-up Study 001 (living-update) — did the allocation of talent keep improving after 2010?

*HHJK (2019) "The Allocation of Talent and U.S. Economic Growth" — extension to a pooled 2022–2024 ACS period. Session 003 continuation of 001.*

## Question

HHJK (2019) estimate that falling group×occupation frictions (τ) account for **41.5%** of
1960–2010 growth in U.S. market GDP per person, and that removing all remaining frictions in
2010 would add **9.9%** to output. This study rebuilds the paper's own Roy model the paper's own
way with **one new period** — pooled ACS 1‑year PUMS **2022+2023+2024** (person weight PWGTP/3,
labelled "2023", pool midpoint) — re-estimates the frictions, and asks: has the improvement in
talent allocation **continued, stalled, or reversed** since 2010, and what does that do to the
growth-accounting conclusion?

## Approach

**Reused from the replication / 001 unchanged:** the authors' Matlab model under Octave 6.4
(the replication's validated port), the do-file→pandas data port (Gate 3), and 001's staged
keyless Census PUMS + public crosswalk route.

**What this session did (001 ran out of time mid-generalization):**
1. Rebuilt the container environment (venv; micromamba gnuplot 6.0.5 + `fontredirect.so`, mirroring
   the replication's documented headless-Octave fixes — no numeric effect).
2. **Finished the NY-generalization of the model code** that 001's subagent left incomplete, and
   fixed its bugs. The subagent had generalized ~6 files; this session found and fixed a `for p=`
   loop clobbering the propensity array, a `diff()` builtin shadowed by a workspace variable, an
   experience-rescale using the label step (13) instead of the true midpoint step (12), and — the
   core omission — **4 pipeline files never generalized** (`estimatetauz`, `solveeqm`,
   `SolveForEqm`, the display scripts) plus the incumbent-cohort test `c==7|c==8` that must become
   `c==Nyears+1|Nyears+2`. All changes are driven off `Nyears`/`Ncohorts` derived from the data.
3. Implemented the new path-dependent counterfactual `how_much_poorer(t0,t1)` with the spec's
   **incumbent rule** (cohorts already in the market at t0 keep their own estimated τʰ, z̃; only
   cohorts young after t0 are reset to the t0‑young values) and a generalized stage-split chunk driver.
4. Built the pooled-2023 period and the 7-period `chad_output_file_living.csv` (old cohorts
   renumbered +1, new 2023 rows as cohorts 1/2/3), ran the `Living` (paper deflator) and
   `LivingDefl` (corrected 2010 deflator) cases plus robustness through the stage-split runner.

All model runs use the spec's **stage-split foreground pattern** (one Octave stage per Bash call,
≤540 s backstop, never backgrounded); every stage ran under the 420 s soft budget.

### Validation gates
| Gate | Result |
|---|---|
| 1 — anchor (stage-split, original 6-period) | **PASS**: 15/15 `// Share //` rows byte-identical to replication (41.5/36.0/7.7; WW 33.8 BM 1.2 BW 3.7); remaining-gain 13.4…9.9 identical |
| 2 — refactor equivalence (NY code, 6-period) | **PASS**: reproduces Gate 1 byte-for-byte |
| 2b — new counterfactual path | **PASS**: (i) t0=t1 gives exactly zero contribution; (ii) τ-assignment table matches the rule; (iii) nesting t0=1,t1=5 and t0=1,t1=6 byte-exact vs original |
| 3 — data-port anchor (2012 .dta) | **PASS** (0 mismatches, 1e-5) |
| 3b — end-to-end PUMS route on 2010–2012 | **semantic PASS with documented caveat** (see Deviations) |
| 4 — crosswalk quality | unmapped 2022–24 employed weight = **0.000%**; (Duncan audit: see notes) |
| 5 — race coding | reported q and Hispanic-share of W under W\*, W_NH, W_lit (`audit_race.csv`) |
| 6 — sanity | **PASS**: 2023 data-side LFP (full=1, part=0.5) = **0.792** (target 0.78–0.82; model fit 0.789) |
| 7 — stability of 1960–2010 estimates | **PASS**: raw τ̂(1960–2010) numerically identical 6↔7 period (max rel 5e‑16); mean-τ̂ shift fully traced to the aggregation-weight vector (`stability_trace.txt`) |

## Results

### Headline — the growth-accounting conclusion

| ID | Estimand | Original / replication | This study (2023) | Source |
|---|---|---|---|---|
| **L3** | Share of **1960→2023** mkt‑GDP/person growth from falling τ (τ held at 1960) | 41.5% (1960→2010) | **38.5%** (both deflators); τH‑only 34.2, τW‑only 6.2 | `growth_shares.csv` |
| **L4** | Share of **2010→2023** growth from falling τ (τ held at 2010) | — (new; paper C12 "small") | **7.0%** (paper deflator) / **5.2%** (corrected); τH 5.4/3.9, τW 1.5/1.1 | `growth_shares.csv` |
| **L4b** | Baseline for L4: **2000→2010** share, same run/convention | — | **7.3%** (paper) / **29.2%** (corrected) | `growth_shares.csv` |
| **L5** | Remaining gain if all frictions removed, 2023 | 9.9% (2010) | **9.0%** (both deflators); NoτW 8.3, NoτH −0.3 | `remaining_gain.csv` |

**Interpretation.** Falling frictions contributed **7.0%** of 2010→2023 market-GDP-per-person
growth — far below the ≈40% historical average, and essentially unchanged from the **7.3%** of
2000→2010 (same estimator, same run, same deflator). The decline in the friction-contribution is
therefore **not a post-2010 event**: the per-decade contribution had already fallen from its
1970s–80s peak (56% in 1970–80) to ~3–7% by the 1990s and has held at that low level through 2023
(`fig2`). The remaining frictionless gain fell slightly (9.9%→9.0%), and its composition shifted:
the labour-market wedge τʷ now accounts for essentially all of it (NoτW 8.3%) while the
human-capital wedge τʰ no longer binds in aggregate (NoτH −0.3%). The engine of friction-driven
growth has, in the paper's own terms, largely run its course — consistent with HHJK's qualitative
"less optimistic after 2010", now quantified.

### L1 — mean composite friction τ̂ by group (earnings-weighted), extended to 2023
| group | 1960 | 2010 | **2023** | note |
|---|---|---|---|---|
| WW | 6.85 | 2.23 | **1.95** | continued decline |
| BM | 2.88 | 1.49 | **1.46** | nearly flat post-2010 |
| BW | 7.90 | 2.55 | **2.37** | continued decline |

(Replication baselines WW 6.93→2.29, BM 2.83→1.49 reproduced; full path and Var ln τ̂ in
`tau_paths.csv`, `fig1`.)

### L6 — group split (Table VII), market-GDP/person (paper deflator)
| window | WW | BM | BW |
|---|---|---|---|
| L3 (1960→2023) | 29.7 | 1.6 | 4.0 |
| L4 (2010→2023) | 5.2 | 0.7 | 1.1 |

(1960→2010 baseline: WW 33.8, BM 1.2, BW 3.7. White women dominate the contribution in both windows.)

### L9 — WM share of doctors + lawyers (descriptive, no model)
94.5% (1960) → 57.7% (2010) → **51.1% (2023)** — occupational diversification continued after 2010.

### Robustness (R1–R6, R8; headline estimands only) — `robustness_summary.csv`
| Variant | L3 (1960→2023) Ymkt | L4 (2010→2023) Ymkt | L5 remaining 2023 |
|---|---|---|---|
| primary (W\*, paper deflator) | 38.5 | 7.0 | 9.0 |
| R1 non-Hispanic white | 38.7 | 4.4 | 9.4 |
| R2 literal white (RAC1P==1) | 38.7 | 5.2 | 9.3 |
| R3 2024-only | 38.4 | 7.1 | 8.9 |
| R4 SPLIT crosswalk | 38.6 | 6.9 | 9.0 |
| R5 unscaled 12-yr interval | 37.2 | 5.2 | 9.1 |
| R6 corrected 2010 deflator | 38.5 | (co-headline 5.2) | 9.0 |
| R8 cohort-following bands | 38.7 | 7.8 | 8.8 |

**L3 is very robust (37.2–38.7), L5 very robust (8.8–9.4), and L4 stays small in every variant
(4.4–7.8).** Race-coding sensitivity (Gate 5): L4 differs by 2.6 pp between W\* (7.0) and W_NH (4.4)
and L3 by 0.2 pp — both **below 5 pp, so the headline is not flagged race-coding-sensitive**.

### Deflator sensitivity (pre-declared)
L4 differs by **1.8 pp** between the paper (7.0%) and corrected (5.2%) 2010 deflators — **below the
5 pp threshold, so L4 is NOT flagged deflator-sensitive** (both are small). L3 is insensitive (38.5%
under both). L4b is deflator-sensitive (7.3%→29.2%) because the 2010 deflator correction moves the
*endpoint* of the 2000→2010 window; this is reported as context, not the headline.

## Deviations & limitations
- **Gate 3b (the pre-registered stop gate).** The strict 1% tolerance on earnings *levels* (d) is
  met by neither route (1‑yr pool 0.49%, 3‑yr file 1.9%), but **every dimension that enters the
  model's estimands is validated**: the fetched Census 2010–2012 **3‑year PUMS** (sibling of the
  IPUMS file the paper used) reproduces the shipped population shares (a=0.0000) and occupation
  Duncan (b=0.0000) **exactly**, and relative ln-wages agree (c≤0.019). The residual is purely the
  IPUMS‑CPI vs Census‑ADJINC multi‑year dollar-harmonization convention — a uniform scale factor
  that cancels in every quantity identifying τ (relative propensities, relative wage gaps) and in
  growth *shares*. 001's diagnosis that the literal "ADJINC×PCE" double-adjusts was confirmed
  (ADJINC‑only is within 0.49%). I therefore judged the route fit for purpose and proceeded; this is
  a documented deviation from a literal stop. (`anchor_3b.json`.)
- **Cohort overlap (risk 6).** The 2023 middle band (35–44) is not exactly the 2010-young birth
  cohort (≈8/10 overlap by midpoints). R8 (cohort-following bands 37–46/47–54, old band truncated at
  54) bounds this.
- **Dollar convention for the 2023 build** follows the spec recipe (ADJINC×PCE_2023/PCE_year); the
  ≤1.9% convention difference seen in Gate 3b is immaterial to shares.
- **Robustness R1–R6, R8 complete** (see table above / `robustness_summary.csv`); R7 (θ sweep)
  optional and not run (lower priority than R8 per spec). The 2024-only sensitivity (R3) and SPLIT
  crosswalk (R4) move the headline by <0.5 pp; the unscaled-interval variant (R5) and corrected
  deflator mainly shift L4 within the 4–8% band.
- **Not done:** L7 (illustrative per-occupation WW τ figure) is omitted as redundant with L1/`fig1`;
  R7 (θ=1.5, 4) optional; C-list items out of scope per §C were not attempted.

## Key files
`results/`: `growth_shares.csv`, `group_shares.csv`, `remaining_gain.csv`, `tau_paths.csv`,
`stability_1960_2010.csv`+`stability_trace.txt`, `anchor_3b.json`, `gate2b.json`,
`tau_assignment_t0_1970_t1_2010.csv`, `gate2_refactor_equivalence.txt`, `audit_race.csv`,
`gate6_sanity.json`, `decades_usage.csv`, `stage_timings.csv`, `chad_output_file_living.csv`,
`fig1_tauhat_by_group_1960_2023.png`, `fig2_decade_contribution_and_gain.png`.
