# The Allocation of Talent and U.S. Economic Growth (Hsieh, Hurst, Jones and Klenow, Econometrica 2019)

This repository is the working directory of an AI-agent replication of the paper, together with the extension studies that carried its analysis forward to 2022-2024 Census data. It holds the runs themselves and the documentation they wrote, and it backs the living-paper page:

**https://livingscience.ai/econ/living-allocation-of-talent**

## The paper

Hsieh, C.-T., Hurst, E., Jones, C. I., and Klenow, P. J. (2019). The Allocation of Talent and U.S. Economic Growth. *Econometrica* 87(5), 1439-1474. DOI: [10.3982/ECTA11427](https://doi.org/10.3982/ECTA11427). Author copy: http://klenow.com/HHJK.pdf

## What is here

- `run/replication/` is the replication run. `codebase/` is the authors' official replication package (Matlab model code, Stata data-preparation do-files, the aggregated model-input file `chad_output_file_2019_01_24.csv`, the `ChadMatlab/` helper library, and the replication instructions), together with every output the run produced: the `.mat` result files, the per-case Octave logs, and the figures. The untouched package as distributed sits in `codebase/extracted/` for comparison. The surrounding files (`replication_log.json`, `evidence_summary.json`, the `step*_console.log` files, `env.sh`) record what the agent ran and what came out.
- The authors' code is written for Matlab, and the run executed it under GNU Octave 6.4 instead, using a small mechanical compatibility patch (`run/replication/codebase/octave_compat/octave_port.patch` plus the shims in `octave_compat/shims/` and `codebase/shims/`) that leaves the numerical method unchanged.
- `run/followup/` holds the extension studies, each with its `instruction.md`, its `workspace/` (code and per-case model runs), its `results/`, and, once finished, a `report.md`, a `result_card.json` and a `followup_summary.json`:
  - `001-living-update` extends the paper's friction series and growth accounting to a pooled 2022-2024 American Community Survey period. It ran out of time before writing its report and card, so it is **superseded by `002-living-update-cont`**, which continues it from its checkpoints and finishes the work.
  - `002-living-update-cont` is that continuation: the generalized model code, the new 2023 period, the robustness cases, and the over-time figure.
  - `003-theory-update` asks what the post-2010 trajectory says about the model itself (convergence or stall, which friction margin moved, and what gains remain), working from 001/002's saved estimates with no new data.
  - `004-gate-conformance` is a corrective study run after a provenance audit of 001-003. It reports every failed pre-registered check as failed, finishes deliverables the earlier studies dropped, and corrects their presentation. **It supersedes both 002 and 003 for every published number**, and its `results/fix_log.md` records the few corrections applied afterwards, with their traces.
- `LARGE_FILES_OMITTED.md` lists the files left out because of their size, with where to get each one.

## Inputs staged for the extension studies

Before the extension studies ran, their public inputs were downloaded into a shared staging directory that the study workspaces reached through symbolic links (`pums/`, `crosswalks/`, `docs/`, `scripts/`, `octave_stage/` and `DATA_MANIFEST.md` in 001's workspace; `pums/`, `crosswalks/` and `octave_stage/` in 004's). That staging mirror is not part of this repository and the links have been removed, so the paths are listed here instead. All sources are keyless and were staged on 2026-10-05.

- **Census ACS 1-year PUMS person files** for 2010, 2011, 2012, 2017, 2018, 2019, 2021, 2022, 2023 and 2024, from `https://www2.census.gov/programs-surveys/acs/data/pums/<YEAR>/1-Year/csv_pus.zip`. The studies read prime-age (25-54) parquet extracts built from these zips (`prime_age_<YEAR>.parquet`, about 22-24 MB each). The raw zips are about 0.6 GB each and are not redistributed here; download them from the Census Bureau at the URL above.
- **Census ACS PUMS data dictionaries and code lists** (2022, 2023, 2024) from `https://www2.census.gov/programs-surveys/acs/tech_docs/pums/`.
- **Occupation crosswalks**: the Census 2018 occupation code list and crosswalk from `https://www2.census.gov/programs-surveys/demo/guidance/industry-occupation/`; the IPUMS `occ_occsoc_crosswalk_2000_onward` files from `https://usa.ipums.org/usa/resources/`; and David Dorn's `occ2010_occ1990dd` and `occ1990_occ1990dd` from `https://www.ddorn.net/data/`. The map from ACS 2010 occupation codes to the paper's 67 occupations was built from the authors' own data, and the 2018-code map from these public crosswalks.
- **Stage-split Octave tooling** (`run_stage.sh`, `split_case.sh`, `HowMuchPoorer_chunk.m`), copied into each case directory, which is why copies appear in the case folders here.
- **Deflators** fetched live from FRED: `DPCERD3A086NBEA` (PCE price index) and `CPIAUCSL` (CPI-U, annual average).

## What is not here

The pipeline's grading and scoring files, its report-back assets, its engine internals (prompts and run state), and the agents' session transcripts and run logs are internal machinery and are not published. The repository keeps the runs and the documentation they wrote.

## Authors' terms

Files under `run/replication/codebase/`, and the copies of that code and data in the extension studies' workspaces (`codebase_living/` and the `cases/*` directories), derive from the authors' replication package (Econometric Society supplementary material, `11427_Data_and_Programs.zip`), possibly modified by the replication agent. They remain under the original authors' terms. The package's data are derived from IPUMS USA microdata, which IPUMS allows to be shared as a subset for journal replication; please cite IPUMS USA (Ruggles et al., https://usa.ipums.org) if you use them. Everything else in this repository is output generated by the replication and extension agents.

## Caveats

These are agent-run analyses. Read each study's `report.md`, and for the extension's headline numbers the `004-gate-conformance` report and result card, before quoting any number. A difference from the paper reflects what our agents could reproduce, not a finding that the authors did anything wrong.
