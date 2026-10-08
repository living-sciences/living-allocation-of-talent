# LAUNCH SCOPE: Execute ONLY Study B (the 002 theory-update study). Study A sections are context; its completed artifacts are inputs, do not re-run them.

# Follow-up studies: did the allocation of talent keep improving after 2010? (HHJK 2019)

REVISED for the 2b judge re-check (2026-10-05), against `verdicts/phase2b-judge.md` items HHJK-A1 to A7 and B1 to B4. The first draft was written the same day; every source below was verified live that day. See `recency-research.md` for URLs, sizes, hashes and audits, and the changelog at the end for what changed and why. There are two studies: **001-living-update** (§A) and **002-theory-update** (§B). They share §0 and §C.

## 0. Shared setup (both studies)

### 0.1 Workspace staging (do this first)
- A verified, pre-staged data workspace exists at `/workspace/eval/followup_staging/shared-data/`, the container path of the corpus `extension-assets/`.
- FIRST action: symlink or hardlink its contents into your own `workspace/`.
- Then verify that every entry in `DATA_MANIFEST.md` is present and readable. Spot-load one parquet per year (2010, 2011, 2012, 2017-2019, 2021-2024) and one crosswalk CSV.
- Do not read other studies under `followup/`. This study stands alone, except that 002 reads 001's `results/`.

### 0.2 The paper in one paragraph (so the study is self-contained)
- **Model.** A Roy model of occupational choice with Fréchet talent (shape θ = 2) and CES aggregation (σ = 3). Human-capital elasticity η = 0.103.
- **Groups.** Four: white men (WM, frictionless reference), white women (WW), Black men (BM) and Black women (BW). Ages 25-54, in 66 market occupations plus home.
- **Frictions.** Group×occupation frictions: a labor-market wedge τʷ and a human-capital cost τʰ. These form the composite τ = (1+τʰ)^η/(1−τʷ). Preferences are z̃.
- **Identification.**
  - Relative occupational propensities, net of wage gaps, identify τ.
  - Wage gaps of the young identify z̃.
  - Life-cycle wage-gap changes split τ into τʷ/τʰ, with 50/50 in 1960 and τʰ ≥ −0.8.
- **Data.** Six decennial cross-sections, 1960-2010. "2010" is the pooled ACS 2010-2012.
- **Headline.** Holding τ's at 1960 values, the model loses **41.5%** of 1960-2010 growth in market GDP per person (Table V). Removing all frictions in 2010 would still add **9.9%** to output.

### 0.3 Environment constraints
- The container has Python, R and Octave 6.4. There is NO Stata or MATLAB.
- **Model code:** the authors' Matlab under Octave, using the port the replication built and validated:
  - Copy `run/replication/codebase/` (or `package/extracted/` + `package/octave_compat/octave_port.patch` + `shims/`).
  - Rename `ChadMatlab/lookup.m` aside.
  - Add a no-op `keyboard.m` shim for batch runs (Theta4-type cases hit a shipped `keyboard()` debug trap; without the shim Octave spins forever on EOF).
  - Run numeric cases with the shipped no-op `print.m`.
  - Run every case through the stage-split runner of §0.4, never as one Octave process.
- **Figures:** re-plot in Python (matplotlib) from saved `.mat` files (`scipy.io.loadmat`, `-mat7-binary`). Do NOT rebuild the gnuplot/font/epstool stack.
- **Data prep:** Python/pandas port of the Stata do-files. The relevant logic is quoted in §A.3. `extension-assets/scripts/06_dryrun_doFile_port_anchor.py` already reproduces 24 sample 2010 cells exactly; start from it.

### 0.4 Execution pattern: stage-split foreground calls (REQUIRED; replaces the draft's "foreground rule")

**Why.** Your Bash tool caps one call at 600 s. Veritas sets no `BASH_MAX_TIMEOUT_MS` in the container, and the per-call default is only 120 s unless you pass `timeout`. A call that overruns is moved to the background by the harness, and a backgrounded job dies with the session. The replication ran its 16-minute Benchmark case as one Octave process and survived only by backgrounding it, which this study must not do. So no Octave process in this study may run longer than 9 minutes. Each case is split into short processes that hand off through `.mat` files.

**Why the split is valid.** The pipeline is already file-checkpointed:
- `EstimateTauZ_main`, `CleanandShowTauAZ`, `SolveEqmBasic` and `HowMuchPoorer` each start with `clear` and reload their inputs from `CohortData_<case>.mat`, `EstimateTauZData_<case>.mat`, `TalentData_<case>.mat` and `SolveEqmBasic_<case>.mat`.
- `HowMuchPoorer.m` is a list of independent `how_much_poorer()` calls. Each call reloads `SolveEqmBasic_<case>.mat`, and `SolveForEqm` re-initialises its history globals (`TauW_C`, `phi_C`, `mgtilde_C`, `w_C`) on entry (SolveForEqm.m l.22-30). So the calls can be grouped into separate processes in any order.
- **One hidden in-process dependency exists, and the staged driver fixes it.** In the one-process pipeline, `SolveEqmBasic.m` leaves `q ShortNames GeoArith_adjust mgEstimated` declared global (its l.17-18). `HowMuchPoorer.m` never declares them. A fresh process that skips this fails inside `SolveForEqm` with `mgEstimated(_,1): out of bound 0`. The spec author hit this and fixed it on 2026-10-05; `HowMuchPoorer_chunk.m` declares them before its `load`. Any new driver you write (the generalized t0/t1 chunks, 002's projections) must declare the union of the `global` lines of `SolveEqmBasic.m` and `HowMuchPoorer.m` before loading `TalentData`.

**Staged, tested tools** (`extension-assets/octave_stage/`):
- `run_stage.sh CASE "<octave statements>"`: the runner. It runs one stage in a fresh `octave-cli` with the standard prelude (shims and `ChadMatlab` on the path, `-mat7-binary`, `global CaseName`), wraps it in `timeout -s INT 540`, writes `stage_console_*.log`, and appends `case, stage, rc, seconds` to `stage_timings.csv`. Exit code 124 means the 540 s backstop killed the stage.
- `HowMuchPoorer_chunk.m`: runs chunk k of the original `HowMuchPoorer.m` in a fresh process. Chunk 1 is TauWTauH/TauH/TauW; chunk 2 is Both+Z/MeansOnly/DispersionOnly; chunks 3-5 are the WW/BM/BW group rows (Benchmark only).
- `split_case.sh CASE STAGE`: one named stage (S1, S2, S3, H1-H5) of an original-code case. Call it once per foreground tool call. Copy all three files into each case directory.

**Stage plan and measured wall times.** These are the original 6-period Benchmark, run stage-split by the spec author on 2026-10-05 (host Octave 6.4.0, load average 26-83 on 32 cores, so slower than the container).

| Stage | Octave statements | Writes | Wall (6-period) |
|---|---|---|---|
| S1 | `SetParameters; HighQualityFigures=0; ReadCohortData; EstimateTauZ_main;` | `CohortData_`, `EstimateTauZData_` | 42 s |
| S2 | `CleanandShowTauAZ;` | `CleanandShowTauAZ_`, `TalentData_` | 9 s |
| S3 | `SolveEqmBasic;` (one baseline solve + the zero-friction table) | `SolveEqmBasic_` | 239 s (about 60 s in the replication's container run) |
| S4.1-S4.5 | `global HMPChunk; HMPChunk=k; HowMuchPoorer_chunk;` (3 solves each) | `HowMuchPoorer_c<k>_<case>.log/.mat` | 136 / 132 / 139 / 143 / 144 s (each about 45 s per solve). The unsplit 15-call stage took about 12 min in the replication |

The replication's own logs agree. Without figures, one `SolveForEqm` call took about 45-50 s: 6-call HowMuchPoorer runs took 4.3-4.8 min, and the Benchmark's 15-call HowMuchPoorer took about 12 of its 16 minutes. The 15-call stage is the only one that breaks the 10-minute cap, and chunking it into 3-call processes removes the problem.

**Rules.**
1. **One stage per Bash call,** with the tool parameter `timeout: 600000` and the command run through `run_stage.sh`, so the stage's own `timeout 540` fires first. Do not rely on the default 120 s timeout.
2. **Budget per stage: 540 s hard (the runner kills it), 420 s soft.** After the first 7-period Benchmark, read `stage_timings.csv`. If any stage took more than 420 s, split it further before running anything else:
   - HowMuchPoorer-type stages: go to 2 calls per process, then 1. One 7-period `SolveForEqm` is expected to take about 1-1.5 min, or about 4 min under heavy load.
   - S1: run `ReadCohortData` and `EstimateTauZ_main` as separate processes. This is valid because `EstimateTauZ_main` starts with `clear` and loads `CohortData_<case>.mat`.
   - S3: if a single `SolveEqmBasic` exceeds 420 s, split its baseline solve (through the `save` at l.41) from the zero-friction table that follows, and checkpoint between them. Record the split.
   - A stage killed at 540 s (rc 124) is never re-run unchanged. Split it.
3. **Skip-if-done.** Before running a stage, skip it if its output `.mat` exists, its log ends normally, and both are newer than its inputs. This makes every case resumable after a session restart.
4. **Parallelism: at most 3 Octave processes at a time** (the box is shared). The only allowed form is one foreground Bash call, with `timeout: 600000`, that starts up to 3 `run_stage.sh` invocations for *different cases*, each in its own case directory, followed by `wait`. Contention slows each stage, so the 420 s soft budget applies to the stages as timed inside that parallel call.
5. **Never** use `run_in_background`, a bare `&`/`nohup` without `wait` in the same call, or "start, then end the turn and wait for a notification". These die with the session (`templates/followup/session_instructions.md`).
6. **One directory per case** (a copy of the codebase), because diary and `.mat` names collide.
7. Log every stage to `results/stage_timings.csv` and ship it.

### 0.5 Launch parameters and continuation
- The orchestrator launches **001 with `--timeout 43200` (12 h)** and **002 with `--timeout 14400` (4 h)**. The budgets are in §C.
- **Continuation.** If 001's session ends before the deliverables are complete, the orchestrator launches **`003-living-update-cont`**. Its instruction: "Re-attach `followup/001-living-update/workspace/cases/*/`; `run_stage.sh` skip-if-done resumes every case; do not delete any `.mat`; finish the gates and deliverables of §A as written."
- `results/followup_summary.json` records, after each completed case, which cases and gates are done, so the continuation knows where to start.

## A. Study 001-living-update: extend the paper's series to a 2020s period and re-estimate

### A.1 Question
Has the improvement in talent allocation continued, stalled or reversed since 2010, and what does that do to the growth-accounting conclusion? The baseline is 41.5% of 1960-2010 market-GDP-per-person growth, with 9.9% of gains left in 2010.

### A.2 Design: one new period, built the paper's own way
- **New period "2023"** = ACS 1-year PUMS **2022 + 2023 + 2024 pooled**, with person weight PWGTP/3. This mirrors the paper's 2010 point, the IPUMS ACS 2010-2012 3-year file:
  - prime-age W\*+B n is about 2.87 M, against 2.89 M in 2010;
  - it is the newest usable state of the world. The 2025 ACS is unreleased because of the Commerce DAO delay, and its PUMS returns 404 as of 2026-10-05.
  - Label: `year = 2023`, the pool midpoint.
- **Interval spacing (pre-declared).**
  - The labels say 2010 → 2023, but the true pool midpoints are **2011** (2010-2012) and **2023** (2022-2024). The final step is therefore **12 years**.
  - The paper's own precedent: its 2000 → "2010" step runs from the 2000 census to a pool centred on 2011, about 11 years, and the code treats it as 10.
  - The `Decades` label for the new period stays 2023, for display. Every annualization that this study introduces uses the true midpoint spacing: 10 years for each census-to-census step, 11 for 2000 → 2010-12, and 12 for 2010-12 → 2022-24. The paper-label convention goes in a second column. Growth *shares* are unaffected, because they are ratios of two growth rates over the same window.
- **Sensitivity:** 2024 alone (PWGTP unscaled) as the new period. Report the headline estimands only.
- **Cohorts: renumber so the new young cohort is 1.**
  - The paper's cohorts 1-8 become 2-9, giving `Ncohorts = 9`, `Decades = [1960 1970 1980 1990 2000 2010 2023]`.
  - In 2023: young (25-34) = cohort 1, middle (35-44) = cohort 2 (the 2010-young), old (45-54) = cohort 3 (the 2000-young).
  - This keeps the code's rule (young in period t is cohort NY+1−t; middle +1; old +2).
  - Do NOT append the new cohort as 9; the offset arithmetic would break in about 40 places.
  - **Cohorts do not line up exactly.** Because the step is 12 years and the age bands move by 10, the 2023 "middle" band (35-44, centred on birth year 1983.5) is not the same birth cohort as the 2010-young band (25-34 in 2010-12, centred on 1981.5). The two overlap in about 8 of 10 birth years by midpoints, or about 7 of 10 by labels. The paper's own 2000 → 2010 step has a 1-year shift (about 9 of 10). R8 (§A.7) tests this.
- **What extends:**
  - 2010-young cohort: young only → young + middle.
  - 2000-young cohort: young + middle → full Y/M/O.
  - New cohort 1: young only.
  - The 1960 50/50 τʷ/τʰ split and the τʰ ≥ −0.8 bound stay unchanged and anchored at 1960.

### A.3 Data construction for the 2023 period
Implement this in Python. It replicates `create_2010_IPUMS_extract.do` + `create_ipums_1960_2010_analysis_file.do` on PUMS variables, with the mapping verified in recency §2. Gate 3b (§A.6) validates this exact code path end to end on 2010-2012 PUMS before it is used for 2022-2024. Write the PUMS route as one function, parameterised by year list, base-year dollars, earnings-floor rule, occupation map and race rule, so that 3b and the new period run the same code.

**Sample**
- AGEP 25-54.
- Groups: W\* × SEX or B × SEX (definitions below).
- Drop military (ESR ∈ {4,5} or OCCP ≥ 9800).
- Drop unemployed (ESR = 3).
- Drop employed with missing OCCP.

**Work status and occupation**
- `emp_full` = ESR∈{1,2} & WKHP≥30.
- `emp_part` = ESR∈{1,2} & 15≤WKHP<30. The do-file uses 15, against 10 in the paper text; keep 15.
- Everyone else is home.
- `person_adj` = 0.5 for part-time, else 1.
- `occ_code` = HHJK category (1-66) via `crosswalks/occ2018_to_hhjk.csv` (rows with `modal==1`) for workers; 0 = home. Part-timers count 0.5 in their occupation and 0.5 in home, through the `occ_code2` mechanism.

**Earnings and wages**
- Earnings = (WAGP + SEMP) × ADJINC/1e6, then × PCE_2023/PCE_year, giving 2023 dollars. PCE values: 2022 116.038, 2023 120.505, 2024 123.662.
- `emp_full_lastyear` = WKWN ≥ 48 & earnings ≥ **$1,471** (= 1000 × CPI-U 2023 304.703/207.16, the paper's 1960-2000 rule).
- `wks_last_year` = 49 if WKWN∈[48,49], 51 if WKWN∈[50,52].
- wage = earnings/(WKHP × wks_last_year).
- `incwage_full` is defined only for emp_full_lastyear & full-time.

**Education:** `highgrade` from SCHL: 1→0; 2-7→4; 8-11→8; 12→9; 13→10; 14→11; 15-18→12; 19→13; 20→14; 21→16; 22-24→19.

**Collapse and output**
- Per (group, age-band cohort, occ_code), weighted by PWGTP/3, compute `num`, `occ_income`, `occ_grade`, `occ_wage`, ln-arith/geo income and wage, and var ln income/wage. Use exactly the do-file's formulas, including the "all"-group 0 rows and the cohort-0 all-ages rows.
- Append the result as `year=2023` rows to a copy of `chad_output_file_2019_01_24.csv`, with the cohort renumbering applied to the old rows. Write `results/chad_output_file_living.csv`.

**Race/ethnicity coding (pre-declared; see recency §4)**
- **Primary W\*** = RAC1P==1 OR (HISP>1 AND RACWHT==1 AND RACBLK≠1).
  - This "bridged white" keeps the paper's concept (white regardless of Hispanic origin) across the 2020 ACS race-coding change.
- **Primary B** = RAC1P==2 (paper literal).
- **Bounds, which must be run:**
  - W_NH = non-Hispanic white alone.
  - W_lit = RAC1P==1 (the paper's literal code). This shows the artifact.
- Report the group population shares q and the Hispanic share of W under each definition.

**Deflator:** extend `pce` in `ReadCohortData.m` with **135.33** for 2023. That is 101.653 × 120.505/90.514: the 2023 PCE spliced onto the paper's 2009=100 vector at 2010, from FRED DPCERD3A086NBEA fetched 2026-10-05. The 2023 entry is the same under both 2010-deflator conventions of §A.5. The corrected convention changes only the 2010 entry, because only the 2010 data are in another year's dollars.

### A.4 Code changes (Octave)
A code audit inventoried about 120-150 line edits in about 12 files. They are summarized here; follow the inventory in the replication tree's code with `grep -n "7-t\|1:6\|(:,:,6)\|7:8\|3:8\|Ncohorts=8"`.

- **Mechanical.**
  - `7-t` → `NY+1-t`.
  - `1:6`, `1:5`, `6`, `7:8`, `3:8` → expressions in `Nyears`/`Ncohorts`.
  - `TauH_C(:,:,6:-1:1)` → `NY:-1:1`.
  - Generate `CohortConcordance`/`YearConcordance` from `Decades` (LookatCohortData.m:19-37).
  - Extend the colour/symbol vectors to 9 cohorts.
  - Update labels and axes from `Decades`.
  - Inventory every place where a `Decades` difference enters a model quantity, not only a display. Each one either uses the true spacing per the interval rule or is logged as kept at the paper's 10-year convention. Write the list to `results/decades_usage.csv`.
- **Experience profiles** (GetTExperience.m:86-115, 224-229, 247-256).
  - Generalize the "t<5 has Y/M/O; t==5 has Y/M only; t==6 copies" edge logic to NY.
  - **Interval rule (pre-declared).** Experience growth measured across the 2010 → 2023 step is annualized over the true midpoint spacing of 12 years and rescaled to the code's 10-year step, `^(10/12)`, before it enters `TigYMO`.
    - Justification: the age bands are 10 years wide, so the code's experience step is a 10-year one, and the observed cohort wage growth spans 12 calendar years.
    - The paper did not rescale its own ≈11-year 2000 → 2010 step. That step is left as the paper coded it, so the 1960-2010 estimates stay comparable.
    - R5 reports the unscaled variant (12 treated as 10, the paper's precedent).
- **Counterfactual base/end years** (`how_much_poorer.m`, which hard-codes base = period 1 and end = period 6).
  - Add arguments `t0`, `t1`.
  - For "τ held at t0": set τʷ for periods > t0 to the t0 value.
  - Set τʰ and z̃ to the t0-young cohort's values **for every cohort that is young after t0**.
  - **Incumbent rule, made exact.** Cohorts already in the market at t0 (young, middle or old at t0) **keep their own estimated τʰ and z̃**, because SolveForEqm is path-dependent and their pre-t0 history is data. This differs on paper from the original code. At t0 = 1960 the original sets *every* cohort, including the 1950- and 1940-young incumbents (cohorts 7-8, which become 8-9 after renumbering), to the 1960-young cohort's τʰ and z̃ (how_much_poorer.m l.63-69), and the incumbents' own estimates do differ (`TalentData_Benchmark.mat`: max |Δz̃| ≈ 2.3; τʰ differs in unpopulated cells).
    - **Verified harmless at t0 = 1960.** The spec author re-ran the original with incumbents kept at their own values on 2026-10-05. The TauWTauH and Both+Z rows reproduce the replication log to every printed digit (Ymkt 41.5 and 40.8; all 16 columns identical), because 1960 incumbents have left the market by 2010.
    - So the single rule above nests the paper. Gate 2 re-checks this on all rows.
    - At t0 = 2010 the rule does bind: the 1990- and 2000-young cohorts are still in the market in 2023. That is why gate 2b tests the t0 > 1 path separately.
  - Use `YBaseline(t0,:)` and `Decades(t1)-Decades(t0)`.
  - Apply the same to the MeansOnly/DispersionOnly loops and to the remaining-gain (no-friction) table.
  - Ship a generalized chunk driver (the `HowMuchPoorer_chunk.m` pattern, with t0, t1, WhatUnchanged and group as inputs, ≤ 3 calls per process).
- **Refactor-equivalence gate.** Before adding any data, the generalized code run on the ORIGINAL 6-period CSV must reproduce the replication's logs exactly. See gates 2 and 2b.

### A.5 Claims re-estimated (C-ids map to the replication)
Paper values come from the replication's own logs in `run/replication/codebase/`. Read them from disk, not from memory.

| ID | Estimand | Paper / replication value (file) |
|---|---|---|
| L1 | Earnings-weighted mean τ̂ by group, every period 1960-2023 (Fig. 2 extended) | 1960 → 2010 WW 6.93 → 2.29, BM 2.83 → 1.49 (`CleanandShowTauAZ_Benchmark.log`, Mean(weighted) rows) |
| L2 | Var ln τ by group, every period (Fig. 3 extended); SD of ln relative propensity for the young (Fig. 1 extended) | Var ln τ falls by about 0.4 for all groups 1960-2010 |
| L3 | **Share of 1960→2023 market-GDP-per-person growth due to τʰ & τʷ** (τ at 1960), with the τʰ-only and τʷ-only rows and the 5 Table V outcomes (Y, Ymkt, Ywkr, LFP, Earn) | 1960→2010: 41.5 / 36.0 / 7.7 (`HowMuchPoorer_Benchmark.log` l.76, 93, 110) |
| L4 | **Share of 2010→2023 growth due to changing τ** (τ held at 2010, base t0 = 2010), same rows. **Co-reported under two deflator conventions** (see below) | new; prior from the paper's C12: small |
| L4b | **Baseline for L4:** share of 2000→2010 growth due to changing τ (t0 = 2000, t1 = 2010), from the same 7-period run, **under the same deflator convention** as the L4 it sits beside | new (same estimator, previous decade) |
| L5 | Remaining gain if all frictions are removed, per period, 2023 added | 13.4 / 25.8 / 34.2 / 24.1 / 14.1 / **9.9** (`SolveEqmBasic_Benchmark.log` l.646-653) |
| L6 | Group split of L3 and L4 (Table VII): WW, BM, BW | WW 33.8, BM 1.2, BW 3.7 (`HowMuchPoorer_Benchmark.log` l.181, 232, 283) |
| L7 | Illustrative WW τ, 2023: lawyers, doctors, construction, secretaries (Fig. 4) | about 10 → below 2 (doctors, lawyers), 1960 → 2010 |
| L8 | Model fit, Table IV extended: earnings per worker and LFP, data against model, 2023 | 2010: 41,541/42,717; 0.759/0.748 |
| L9 | Descriptive (no model): white-men share of doctors+lawyers 1960, 2010, 2023, using the C21 convention from `DocLawShare.m`; annual SD of ln relative propensity for 2017-2019 and 2021-2024 from the staged PUMS | 94.5% / 57.7% (replication) |

**L4 deflator co-headline (pre-declared).**
- The paper's "2010" earnings are 2012 dollars deflated with the 2010 PCE, which overstates real 2010 levels by 4.4% (recency §1). L4's base year is exactly that year.
- Run two full cases through all stages, each with its own S1-S3:
  - `Living`: the paper convention, `pce(2010)` = 101.653.
  - `LivingDefl`: corrected, `pce(2010)` = 106.17 = 101.653 × 94.534/90.514.
- Report L4, L4b and the L6 rows for L4 under both conventions, side by side.
- If the two L4 Ymkt TauWTauH shares differ by **more than 5 percentage points**:
  - the result card states "L4 is deflator-sensitive";
  - `findings.md` names the **corrected-deflator L4 as the economically correct number** and the paper-convention L4 as the comparability number.
- L3 stays on the paper convention as its headline, for comparability with 41.5%. Its corrected-deflator value is a robustness row (R6).

**Over-time figure (required).** One panel per group showing mean τ̂ 1960-2023 (L1) as the paper's Fig. 2 extended. Mark the 2023 point with a different marker and a dashed segment for the 12-year step. Add a second figure: a bar chart of the per-decade (annualized, true midpoint spacing) contribution of falling τ to market-GDP-per-person growth, 1960-70 … 2000-10, 2010-23, plus L5 as a line.

**Stability of the 1960-2010 estimates (pre-declared; replaces the draft's "a finding, not an error").**
- Report the 1960-2010 numbers from the 7-period run next to the original 6-period numbers, in `results/stability_1960_2010.csv`.
- Any change larger than **0.5 pp in a share** (L3-type, L5, L6) or **1% in a mean τ̂** (L1) must be traced to a named mechanism. That means naming the cohort and the experience-profile observation that changed, and demonstrating it: re-run `GetTExperience` (and the stages downstream of it) with the new period's observations masked, and show that the change disappears.
- **An untraced change is treated as a bug.** Stop, fix, and re-run gate 2 before reporting any 2023 number.

### A.6 Validation gates (in order; stop and report if one fails)
1. **Anchor, stage-split.** Run the Benchmark case with the unmodified ported code on the shipped CSV, through `octave_stage/split_case.sh` (S1, S2, S3, S4.1-S4.5). This gate certifies the split as well as the port.
   - Table V must match the replication log exactly: Ymkt 41.5 / 36.0 / 7.7 and all 20 cells, plus the 9.9% remaining gain and the Table VII group rows.
   - The stages are `split_case.sh Benchmark S1`, `S2`, `S3`, `H1` … `H5`, one per foreground call.
   - Compare every `// Share //` row of the concatenated chunk logs with `run/replication/codebase/HowMuchPoorer_Benchmark.log`, and `SolveEqmBasic_Benchmark.log` with the replication's. Write the diff to `results/gate1_split_diff.txt`; it must be empty for share and table rows.
   - Every stage must be under 540 s, as recorded in `stage_timings.csv`.
2. **Refactor equivalence.** The NY-generalized code on the same 6-period CSV must reproduce gate 1's `HowMuchPoorer` and `SolveEqmBasic` share rows to the printed decimal. Also, `how_much_poorer(t0=1,t1=6)` must equal the original.
2b. **Unit checks of the new counterfactual path** (original 6-period data, generalized code, before any new data):
   - (i) **t0 = t1** (t0 = t1 = 6): the counterfactual τʷ, τʰ and z̃ arrays are identical to the baseline arrays for every cohort present at t1, and the counterfactual t1 outcomes equal `YBaseline(t1,:)` to relative 1e-8. The τ contribution is therefore exactly 0. (The share formula divides by `Decades(t1)-Decades(t0)` = 0, so check levels, not the printed share.)
   - (ii) **Assignment table** for t0 = 2 (1970), t1 = 6: write `results/tau_assignment_t0_1970_t1_2010.csv`, cohort × period, showing which source supplies τʷ (which period), τʰ and z̃ (which cohort) in each cell. Check it against the rule in §A.4. Cohorts young in 1980-2010 get the 1970-young cohort's τʰ/z̃. Cohorts young in 1970 or earlier keep their own. τʷ in periods 3-6 equals period 2.
   - (iii) **Nesting:** for t0 = 1, t1 = 5, the generalized code's shares equal those of a scratch copy of the original `how_much_poorer.m` with its end period edited from 6 to 5 (a one-line change). Record both in `results/gate2b.json`.
3. **Data-port anchor.** The pandas port run on the shipped `2012_extract_composite_main.dta` must reproduce **every** `year==2012` row of `chad_output_file_2019_01_24.csv` (num, occ_income, occ_grade, occ_wage, ln/var columns) to relative error 1e-5. Missing cells must match missing cells. Script 06 already gives 0 mismatches on 24 sample cells.
3b. **End-to-end PUMS-route anchor (pre-registered).** This is the gate for the Census-PUMS variable layer: ESR, WKHP, WKW/WKWN, WAGP+SEMP with ADJINC, SCHL, PWGTP and RAC1P.
   - **Input.** Build the 2010 period from the staged Census **ACS 1-year PUMS 2010, 2011 and 2012**, pooled with PWGTP/3 (`pums/prime_age_{2010,2011,2012}.parquet`). Use the same PUMS-route function as the new period, with these 2010-specific settings, which follow the authors' 2010 do-file:
     - dollars: ADJINC to survey-year dollars, then × PCE_2012/PCE_year into 2012 dollars;
     - earnings floor: the do-file's nominal `>= 1000`;
     - weeks: from WKW intervals (1 = 50-52 → 51; 2 = 48-49 → 49), since 2010-2012 PUMS has no WKWN;
     - occupation: 2010-basis OCCP through the authors' own exact map `crosswalks/occ2010acs_to_hhjk_empirical.csv` (L3; no 2018 crosswalk involved);
     - race: W_lit/B, which equal the IPUMS RACE codes the paper used.
   - **Comparison.** Compare with the shipped `year==2012` rows.
   - **Tolerances** (pre-registered; the judge's proposal, adopted unchanged):
     - (a) group × cohort population shares within **1% relative**;
     - (b) occupation shares by group: Duncan(PUMS route, shipped) ≤ **0.0114** (the 2022-vs-2023 same-coding baseline);
     - (c) mean ln wage by group × cohort within **0.02**;
     - (d) Table-IV-style data-side earnings per worker and LFP (full = 1, part = 0.5) within **1%**.
   - **Also report, not gated:**
     - unmapped OCCP weight. The spec author measured 0.0000 in all three years on 2026-10-05; anything above 0.5% means the route is broken;
     - the same comparison under W\* (expected nearly identical before the 2020 coding change);
     - the 2012 1-year file alone against the shipped rows, so that pooling effects can be told apart from semantic ones.
   - **WKWN bridge** (the one variable that 3b cannot reach, because 2010-2012 has no WKWN). Among employed prime-age W\*+B, compare the weighted share with 48-52 weeks under WKW in 2018 against WKWN in 2019. |Δ| must be ≤ 1.5 × |Δ| of the same-coding pair 2017 vs 2018 (WKW both years) or ≤ 1 pp, whichever is larger. Also compare the 48-49 and 50-52 split.
   - **If 3b fails, stop and diagnose. Do not proceed to 2023.** Diagnose by variable (drop one recode at a time).
     - If the failure is population shares only and could be sampling or weighting (the IPUMS 3-year file is not the union of three 1-year files with PWGTP/3; that equivalence is UNVERIFIED), the one permitted extra fetch is the Census **2010-2012 3-year PUMS**: `https://www2.census.gov/programs-surveys/acs/data/pums/2012/3-Year/csv_pus.zip`, **1,610,918,446 bytes**, Last-Modified 2014-02-04, keyless (HEAD-verified 2026-10-05). Fetch it with `curl -f`, in a foreground call with `timeout: 600000`, wrapped in `timeout 540`; resume with `curl -C -` if needed. Then re-run 3b on that file.
     - Report both results. 3b passes only if the 1-year pool or the 3-year file passes all of (a)-(d), and the report states which one passed.
4. **Crosswalk quality** (thresholds pre-declared; staged audit values in brackets). Recompute with `scripts/04_resolve_and_audit_crosswalk.py`.
   - (a) ≥ 95% of 2022-2024 W\*+B employed weight in unambiguous 2018 codes [96.4%, per the recency audit for 2024, with the 2022-2024 pool reported the same; you recompute it], and ≤ 0.5% unmapped [0.0%].
   - (b) Aggregate recode Duncan (ACS 2017 through the authors' 2010 map against ACS 2018 through the crosswalk) ≤ 1.5 × the same-coding baseline Duncan (2022 vs 2023) [0.0103 vs 0.0114].
   - (c) The same ratio ≤ 1.5 for each of WM/WW/BM/BW [all ≤ 1.0].
   - (d) Every one of the 66 categories is non-empty for WM in 2023.
   - If (a)-(c) fail, stop. Report the failing categories, and run the SPLIT allocation (`split_share`) as the primary instead.
5. **Race coding.** Report q and the Hispanic share of W under W\*, W_NH and W_lit. If L3/L4 differ by more than 5 percentage points between W\* and W_NH, flag the headline as race-coding-sensitive in the result card.
6. **Sanity.** The 2023 data-side Table IV numbers (earnings per worker, LFP) must be plausible against published ACS aggregates. The LFP-equivalent of the prime-age W\*+B population (full-time = 1, part-time = 0.5) should be about 0.78 to 0.82; the spec-writer's dry run on the staged data gave **0.792**, against the paper's 2010 data value of 0.759. A wild fit failure in SolveEqmBasic is a stop condition.
7. **Stability trace.** The rule of §A.5 ("Stability of the 1960-2010 estimates") is applied, and every flagged change is traced, before any 2023 number is reported.

### A.7 Robustness (labelled as such; headline estimands L3, L4, L5 only)
- R1: W_NH.
- R2: W_lit.
- R3: 2024-only new period.
- R4: SPLIT crosswalk allocation.
- R5: unscaled 12-year experience interval (12 treated as 10, the paper's precedent).
- R6: corrected 2010 deflator **for L3** (`pce(2010)` = 106.17). For L4 the corrected deflator is a co-headline, not a robustness row (§A.5). The case is `LivingDefl`, already run.
- **R8: age bands shifted to follow birth cohorts across the 12-year step.**
  - In the 2023 period use middle = 37-46 and old = 47-54. The old band is truncated, because the staged extracts stop at 54 and the model's age range is 25-54; disclose this.
  - Young stays 25-34.
  - Report L3, L4 and L5 only. Also report the τʷ/τʰ split of the 2010-2023 change, which 002 needs.
- R7, if time permits: θ = 1.5 and θ = 4 for L4 only.
- **Priority** if the time budget forces a choice: R8 before R7. R1-R6 and R8 are required; R7 is optional.

### A.8 Deliverables (handoff contract)
- `report.md`: Question, Approach, Results with a comparison table (original value, source file, new value), Deviations & limitations.
- `followup_summary.json`, updated incrementally after every case and gate (it is the continuation's resume point).
- `result_card.json` (`sai.followup.result_card/v1`).
  - Headline: L4 (the share of 2010 → 2023 growth from falling τ) **under both deflator conventions, each paired with L4b (2000 → 2010) on the same convention**, plus L5 for 2023 against 9.9%.
  - Include the deflator-sensitivity flag of §A.5 and the race-coding flag of gate 5 when they apply.
- `results/`:
  - `chad_output_file_living.csv`;
  - `tau_paths.csv` (period × group: mean τ̂ weighted, Var ln τ, mean z̃);
  - `growth_shares.csv` (window × counterfactual × outcome × deflator convention);
  - `remaining_gain.csv`;
  - `group_shares.csv`;
  - `audit_crosswalk.json`, `audit_race.csv`;
  - `gate1_split_diff.txt`, `gate2b.json`, `tau_assignment_t0_1970_t1_2010.csv`, `anchor_3b.json` (all four tolerances, values and pass/fail, plus the WKWN bridge);
  - `stability_1960_2010.csv`, `decades_usage.csv`, `stage_timings.csv`;
  - the two figures as PNG + CSV, plus all case and stage logs.
- `results/findings.md` opens with a plain-language METHOD paragraph: the paper's own model and estimator; one new pooled 2022-2024 period built the paper's way; the keyless Census PUMS + public crosswalk route, anchored end to end on 2010-2012; the race bridging; and the two deflator conventions for L4.

## B. Study 002-theory-update: what the post-2010 trajectory says about the model

**Reuse 001 only.** Read `followup/001-living-update/results/` and its saved `.mat` files. **Fetch nothing.** New Octave runs are allowed only for the counterfactual projections below. They follow §0.4 exactly: stage-split, one stage per foreground call with `timeout: 600000` through `run_stage.sh` (540 s backstop), at most 3 Octave processes at a time, inside one waiting call, never backgrounded. Each projection solve is its own stage, and any new driver re-declares the globals listed in §0.4. Launch with `--timeout 14400`.

**Pre-registration.** The rules in items 1-3 are fixed by this spec, before 001's numbers exist. Apply them verbatim. Do not adjust thresholds after seeing 001's results.

1. **Friction-convergence law, fit by era.**
   - For each group g, model the earnings-weighted mean of ln τ̂ (and Var ln τ) as partial-adjustment convergence toward a floor τ∞: ln τ_t = ln τ∞ + (ln τ_1960 − ln τ∞)·e^{−λ_g (t−1960)}. Time t uses the true midpoint dates (1960, …, 2000, 2011, 2023).
   - **Inputs (consistent estimator).** Fit the law on the 1960-2010 estimates **from 001's 7-period run**, the same estimator that produces the 2023 point. Report the fit on the original 6-period estimates alongside it (λ_g, τ∞_g, residuals), as a second column.
   - Estimate (λ_g, τ∞_g) on 1960-2010 only.
   - **Backtest (required before any stall call).**
     - Fit the same law on 1960-2000 only (7-period-run estimates) and predict 2010 (t = 2011).
     - The backtest error is e_g = |observed − predicted| for mean ln τ̂ (and separately for Var ln τ).
     - Report it per group, together with the 6-period-input version.
   - **Out-of-sample test:** compare the predicted 2023 value with the 2023 estimate from 001. Report the forecast error against the band b_g = **max(R1-R4 spread_g, e_g)**.
   - Also estimate the per-decade decline rates for 1960-80, 1980-2000, 2000-10 and 2010-23 (annualized over true midpoint spacing: 11 years for 2000-10, 12 for 2010-23).
   - **Pre-declared stall test:** "convergence stalled" for group g if the 2010-23 annualized decline in mean ln τ is less than one third of the 1960-2010 average AND the 2023 value lies above the 1960-2010 law's prediction by more than **b_g = max(R1-R4 spread, backtest error e_g)**. Classify each group as continued / slowed / stalled / reversed by these rules. If e_g exceeds the full 1960-2010 decline of group g, the law has no forecasting power for that group: classify it "not classifiable (law fails backtest)".
2. **Split the trajectory.** Separate τʰ (pre-market) from τʷ (labor-market) for the 2010-23 change, per group.
   - Report this split under the primary specification **and** under R5 (unscaled interval) and R8 (cohort-following bands), because both act directly on the life-cycle split.
   - Relate this to Hurst-Rubinstein-Shimizu (2024): flat adjusted Black-white wage gaps since 1980 alongside falling discrimination.
   - Say which margin the model attributes the post-2010 change to, and whether that attribution survives R5 and R8.
3. **Remaining-gains projection.**
   - Using 001's 2023 equilibrium (A, φ, z̃, q at 2023), solve the model with τ's on the fitted law at 2033 and 2043, and with τ → τ∞.
   - Report the implied additional output gains, and the annualized growth contribution per decade going forward, against the paper's 1960-2010 average contribution.
   - **Label every projected number [PROJECTED, conditional on the fitted law, A, φ, z̃ and q held at 2023].** This covers the 2033 and 2043 values, the τ → τ∞ gains and the decade-ahead contribution.
   - This turns the paper's qualitative "less optimistic after 2010" (C12) into a conditional number. It is **not** a forecast of growth. The card and findings must not call it one, or put it next to a GDP forecast.
4. **Written-down model.** A short section stating the updated parameters: λ_g, τ∞_g, and the 2023 τʷ/τʰ split, with s.e. or the robustness range. It also gives the one-paragraph updated claim the paper "should say now".

Deliverables follow the same contract as 001. The result card headline is the stall classification per group (with b_g and e_g shown), plus the decade-ahead growth contribution tagged [PROJECTED, …] as above.

## C. Out of scope, alternatives, budget

### Out of scope
- New groups (Hispanic, Asian). The paper models white and Black men and women only.
- The θ(1−η) MLE (C18; no shipped code).
- Re-estimating δ. Use δ = 0 (Benchmark); δ variants are optional and not requested.
- 2025-2026 labor-market events: the 2025 ACS is unreleased.
- AFQT (C19).
- Cross-state Charles-Guryan (C18 supplement).
- Any fetch beyond the staged assets. FRED values are already in this spec. **One exception:** the conditional 2010-2012 3-year PUMS fetch of gate 3b, with its URL and size given there.

### Documented alternative: IPUMS-gated exact-comparability path
A human with a free IPUMS USA account (https://uma.ipums.org/usa/user/new) can request us2022a, us2023a, us2024a (or us2024c). The variables are those listed in the briefing §5, plus **HISPAN** and **RACED**. This would give:
- (i) IPUMS's own OCC1990 for the 2018-code years, which replaces the chain crosswalk and lets the study diff the two;
- (ii) a non-Hispanic-white series consistent back to 1960, by also re-pulling the 1960-2010 samples with HISPAN;
- (iii) the IPUMS 3-year weighting and dollar conventions.

Turnaround is minutes to hours after registration. If unlocked, rerun 001 as `004-living-update-ipums`, with Gate 4 replaced by an OCC1990 agreement check. Do not overwrite 001. (Slot 003 is reserved for the continuation, §0.5.)

### Compute budget
- Data prep: under 1 h, CPU, under 8 GB RAM. The parquet extracts are 22-24 MB per year. Gate 3b adds about 15 min.
- **Octave, counted in `SolveForEqm` calls** (about 1-1.5 min each at 7 periods; 3 per HowMuchPoorer-type stage):
  - Gate 1 (6-period, split): 1 + 15 calls, about 20 min.
  - Gate 2 + 2b: about 20 calls, about 25 min.
  - `Living`: L3 (6) + L4 (6) + L4b (3) + L6 for L3 and L4 (18) = 33 calls plus S1-S3, about 45 min.
  - `LivingDefl`: L4 (6) + L4b (3) + L6 for L4 (9) + L3 (3) = 21 calls, about 30 min.
  - R1-R5 and R8: 6 cases × (S1-S3 + 9 calls), about 15 min each, 90 min.
  - R7 (optional): 2 × about 10 min.
  - Total about 4-4.5 h serial, or about 2 h at 3-way parallelism. With data prep, retries and agent time, 001 fits in the 12 h `--timeout`.
- 002 needs about 3-5 projection solves × (primary + R5 + R8), each its own stage, plus fits: well under the 4 h `--timeout`.
- No GPU.

### Known risks (state them in the report)
- (1) **Code generalization.** The final interval is 12 years, and the experience-profile edge logic plus the path-dependent counterfactual with base 2010 are the hardest parts. Gates 2 and 2b catch regressions, and the stability trace catches silent shifts.
- (2) **Race-coding break.** W\* bounds it but does not remove it.
- (3) **Crosswalk.** 3.6% of employment sits in rule-resolved codes.
- (4) **Composition and period effects.** 2022-2024 are post-pandemic years with a tight labor market.
- (5) **Identification.** HHJK's τ backs out from relative wages and shares. If preference sorting (δ > 0) or rising returns to Abstract tasks moved after 2010, part of any measured τ change is not "friction".
- (6) **Cohort overlap.** The 2023 middle band is not the 2010-young birth cohort. With midpoints the overlap is about 8 of 10 birth years, or about 7 of 10 by labels; the paper's own previous step had about 9 of 10. R8 bounds this.
- (7) **Deflator.** L4's base year carries the paper's 4.4% deflator overstatement. It is co-reported, not hidden.
- (8) **Execution.** Every Octave process is held under 9 minutes by construction (§0.4). A stage that grows past the soft budget is split, never backgrounded.

## Revision changelog (2026-10-05)

Each change below maps to the judge's item number in `verdicts/phase2b-judge.md`.

| Item | Change |
|---|---|
| **HHJK-A1** (foreground rule not executable) | §0.4 is rewritten as the **stage-split** pattern, the judge's option (a). The spec author verified it on 2026-10-05 by running the original Benchmark split into S1 (ReadCohortData+EstimateTauZ_main, 42 s), S2 (CleanandShowTauAZ, 9 s), S3 (SolveEqmBasic, 239 s under load average about 80) and S4.1-S4.5 (HowMuchPoorer in 3-call chunks, 132-144 s each; the unsplit stage took about 12 min). The split run reproduces the replication's `HowMuchPoorer_Benchmark.log` exactly: all 15 counterfactual blocks, 120 of 120 level/growth/share rows, diffed byte for byte, including Ymkt 41.5 / 36.0 / 7.7 and the Table VII group rows. `SolveEqmBasic_Benchmark.log` differs only in the file path and an ASCII plot. The longest stage was 239 s against the 540 s backstop. A second run in a fresh directory, using exactly the staged `octave_stage/` files (`split_case.sh` S1 … H5 through `run_stage.sh` with its `timeout 540`), was also identical, with stages of 29/10/246/137/131/136/140/141 s (`octave_stage/gate1_verification_stage_timings.csv`). One hidden dependency was found and fixed (the `mgEstimated`/`GeoArith_adjust` globals). Tested tools are staged in `extension-assets/octave_stage/`. Added: per-call `timeout: 600000`, a 540 s in-runner backstop, a 420 s soft budget with split-further rules, skip-if-done resume, at most 3 parallel processes in one waiting call, and no backgrounding. Gate 1 now runs through the split, so it certifies the split. |
| A1 / cross-cutting 1 | New §0.5: explicit `--timeout 43200` (001) and `--timeout 14400` (002); continuation `003-living-update-cont`; the IPUMS alternative moves to slot 004. |
| **HHJK-A2** (no PUMS-route anchor) | New **Gate 3b**. ACS 1-year PUMS 2010, 2011 and 2012 are staged (612/608/597 MB zips, keyless, with sha256 and prime-age parquets in the manifest). The 2010 period is built through the same PUMS-route function as 2023, with the authors' exact 2010 occupation map, and compared with the shipped `year==2012` rows under the judge's four tolerances, adopted unchanged. Stop on failure. Added a WKWN bridge check (the one variable 3b cannot reach) and a conditional, pre-verified fetch of the 2010-2012 3-year PUMS (1.61 GB) for diagnosis. |
| **HHJK-A3** (deflator on L4) | L4 is co-reported under the paper and corrected 2010 deflators (`Living` and `LivingDefl` cases). Above 5 pp the card says "deflator-sensitive" and findings names the corrected value as economically correct. L3 stays on the paper convention; R6 now covers L3 only. Cross-cutting 2: L4 is paired with a new L4b (2000 → 2010, same run, same deflator convention). |
| **HHJK-A4** (interval and cohort spacing) | §A.2 states the true 12-year spacing (midpoints 2011 → 2023) and the paper's ≈11-treated-as-10 precedent. The experience exponent is pre-declared as `^(10/12)`, with its justification (§A.4); R5 is the unscaled variant. Annualizations use the true spacing. Cohort non-overlap is added to §A.2 and to Known risks (6). New **R8** (middle 37-46, old 47-54 truncated) for L3/L4/L5, with priority over R7. |
| **HHJK-A5** (new counterfactual path untested) | New **Gate 2b**: (i) t0 = t1 gives an exactly zero contribution, checked on levels because the share divides by 0; (ii) the cohort × period τ assignment table for t0 = 1970 goes into `results/`; (iii) nesting against the original edited to end period 5. Also the incumbent rule is made explicit: the original overwrites the 1960 incumbents with the 1960-young τʰ/z̃. The spec author showed that keeping their own values reproduces the original's TauWTauH and Both+Z rows exactly, so one rule ("incumbents keep their own history") nests the paper and binds only for t0 > 1960. |
| **HHJK-A6** (shifts in 1960-2010 estimates) | "A finding, not an error" is removed. The 0.5 pp / 1% thresholds apply, with tracing by masked `GetTExperience` re-runs; untraced changes are bugs. This is gate 7 and `stability_1960_2010.csv`. |
| HHJK-A7 (minor) | The gate-4(a) bracket is reconciled to the research note's 96.4%; the agent recomputes it. Known-risk (3) is corrected to 3.6%. |
| **HHJK-B1** (backtest) | 002 fits the law on 1960-2000 and predicts 2010. The stall band is max(R1-R4 spread, backtest error). Pre-declared in this spec. Groups whose backtest error exceeds their whole decline are "not classifiable". |
| **HHJK-B2** (consistent inputs) | The law is fit on the 7-period run's 1960-2010 estimates, with the 6-period fit reported alongside. |
| **HHJK-B3** (labels) | [PROJECTED, conditional on the fitted law, A, φ, z̃ and q held at 2023] on the 2033/2043/τ∞ outputs and the decade-ahead contribution; it may not be presented as a growth forecast. The τʷ/τʰ split is also reported under R5 and R8. |
| **HHJK-B4** (002 wording) | 002 now uses §0.4 verbatim: stage-split, ≤ 3 processes, never backgrounded, `--timeout 14400`. |