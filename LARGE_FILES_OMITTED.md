# Files omitted from this repository

GitHub limits single files to 100 MB, so the large data files below were left out. Everything else from the runs is here.

## The authors' processed IPUMS extracts (Stata .dta)

These six files ship inside the authors' official replication package. They were present, byte-identical, in five places in the run: `run/replication/codebase/`, `run/replication/codebase/extracted/`, `run/followup/001-living-update/workspace/codebase_living/`, `run/followup/001-living-update/workspace/cases/Benchmark/` and `run/followup/001-living-update/workspace/cases/Benchmark/extracted/`. The two smaller files are under the limit, but a partial set is of no use on its own, so all six were omitted together. The replication itself ran from the aggregated model-input file `chad_output_file_2019_01_24.csv`, which is included.

| file | bytes | sha256 |
|---|---|---|
| 1960_extract_composite_main.dta | 77,498,834 | a786c1eef77c6d8c7df39334c18d10c622e09ebdf31f318ca37dbdc770349d72 |
| 1970_extract_composite_main.dta | 86,331,230 | b73a49bb8d0c998a4bdd1fabe43c012358b640b4bb2c886a68285ed92ab33a8a |
| 1980_extract_composite_main.dta | 485,045,500 | 04b23058a9aa99e890be3a52c8c58caa965fa8c8cef15d1a647e37e0bd746cab |
| 1990_extract_composite_main.dta | 566,850,955 | 3880db1134052c8e348ac38c5c09f311a970da66c9c3ae2111da98e3ac1f1859 |
| 2000_extract_composite_main.dta | 584,971,397 | 3e156c9814c7c9fea6ab762de9ab3bc8b000fde5e0c52ff188f9432da03aedf7 |
| 2012_extract_composite_main.dta | 404,600,544 | 4e79fba7dd52b64c6435d97f8ae0b7ed798103be16d7b214a3afbb770223e7b5 |

**Where to get them:** the Econometric Society supplementary material for the article, `11427_Data_and_Programs.zip` (436,468,700 bytes, sha256 `1b0d53e80d2a2c8d3ad5e5290766828875cebddef6b145ac3a1313a33389021f`), linked from https://www.econometricsociety.org/publications/econometrica/2019/09/01/allocation-talent-and-us-economic-growth. A byte-identical copy is on Chad Jones's site as https://web.stanford.edu/~chadj/TalentReplication701.zip. Unzip it and place the `.dta` files next to the code in each directory listed above.

## The 2010-2012 three-year ACS PUMS file

| file | bytes | sha256 |
|---|---|---|
| run/followup/001-living-update/workspace/pums3yr/csv_pus_3yr_2012.zip | 1,610,918,446 | beda2ef97014b7fd83ecb36789ae4fa746d0f8c3efc852dd33a5330d47e5209b |

**Where to get it:** U.S. Census Bureau, https://www2.census.gov/programs-surveys/acs/data/pums/2012/3-Year/csv_pus.zip (Last-Modified 2014-02-04). Study 001 fetched it to diagnose its earnings anchor check (disclosed as an out-of-trigger fetch in `004-gate-conformance`), and built `prime_age_3yr_2012.parquet` from it.

## Staged inputs (not in the run directory)

The 1-year ACS PUMS zips and the parquet extracts the studies read lived in a shared staging directory outside the run, reached by symbolic links. They are not mirrored here; the README's "Inputs staged for the extension studies" section lists each source with its URL.
