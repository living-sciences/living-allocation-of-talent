# DATA_MANIFEST: HHJK (2019) extension assets

Staged on 2026-10-05 by the Phase-2a recency agent. All sources are keyless. Raw zips are kept for provenance. The study reads the parquet extracts.

## pums/
Census ACS 1-year PUMS person files: `https://www2.census.gov/programs-surveys/acs/data/pums/<Y>/1-Year/csv_pus.zip`. Each zip holds `psam_pusa.csv` and `psam_pusb.csv`.

| file | bytes | Last-Modified | sha256 |
|---|---|---|---|
| csv_pus_2024.zip | 602,847,146 | 2025-12-04 | afdc6d90c6e2f0bab365ed32d95ba4c4d8ac651162f46ac7861295b2dc469894 |
| csv_pus_2023.zip | 597,292,173 | 2024-09-10 | 98b6ecb14b4830d1f2b54c265a5bd997828415c2dab14e17369c40e98b78d9d4 |
| csv_pus_2022.zip | 591,122,084 | 2023-09-18 | 687a97773d0fdfec6c624ea6bf48466f12059d3ee80283a2ad8604ea7a66231e |
| csv_pus_2021.zip | 571,180,899 | 2022-09-22 | (race-break test only) |
| csv_pus_2019.zip | 567,851,237 | 2020-10-15 | (race-break test only) |
| csv_pus_2018.zip | 562,224,936 | 2019-10-31 | (occupation recode test only) |
| csv_pus_2017.zip | 628,817,174 | 2018-10-02 | (occupation recode test only) |

- `prime_age_<Y>.parquet` (about 22-24 MB each) is ages 25-54, all races, built by `scripts/03_extract_pums_prime_age.py`.
- Columns: SERIALNO SPORDER ST|STATE PWGTP AGEP SEX RAC1P RAC2P RACWHT RACBLK RACASN RACNUM HISP OCCP SOCP INDP ESR COW WAGP SEMP PERNP WKHP WKWN|WKW WKL SCHL ADJINC MIL RELSHIPP|RELP NATIVITY YEAR.
- Row counts: 2017 1,177,289; 2018 1,174,733; 2019 1,166,388; 2021 1,165,953; 2022 1,208,177; 2023 1,215,438; 2024 1,217,903.
- 2025 1-year PUMS returns 404; release is delayed (Census DAO).
- The 2020-2024 5-year file (2.27 GB zipped) was NOT pulled.

### Added 2026-10-05 for gate 3b (spec revision, judge item HHJK-A2)
Same keyless source, the 2010-2012 1-year files (the years pooled in the paper's "2010" point):

| file | bytes | Last-Modified | sha256 |
|---|---|---|---|
| csv_pus_2012.zip | 612,354,711 | 2013-12-11 | bd9048262f6d56a19b3ef4bba762d91bce493f007902d8b712789e54a39d3b6b |
| csv_pus_2011.zip | 607,745,960 | 2013-03-04 | 7786e8d7e19494a3ae98f9a99f6aa9d655bc2dc0ebde289aed0a3abd625749d1 |
| csv_pus_2010.zip | 596,648,291 | 2013-03-04 | ef8bd999c5688a3000f339e695a6a6f511d856c02076f3d937c0acbb858cd5c3 |

- Each zip holds `ss1Ypusa.csv` and `ss1Ypusb.csv`.
- `prime_age_{2010,2011,2012}.parquet` were built by script 03. Row counts: 2010 1,205,292; 2011 1,189,778; 2012 1,181,063.
- These files have **WKW** (intervals 1-6) and no WKWN. They also have no STATE or RELSHIPP (they have ST and RELP).
- OCCP in all three years is 100% covered by `crosswalks/occ2010acs_to_hhjk_empirical.csv`: 0.0000 unmapped weight among employed RAC1P∈{1,2}, checked 2026-10-05.
- Not staged: the 2010-2012 **3-year** PUMS, `https://www2.census.gov/programs-surveys/acs/data/pums/2012/3-Year/csv_pus.zip` (1,610,918,446 bytes, Last-Modified 2014-02-04). The spec permits fetching it only for a gate-3b diagnosis.

## octave_stage/
Stage-split execution tools (spec §0.4), tested 2026-10-05 on the original Benchmark: `run_stage.sh` (one stage per fresh octave-cli, 540 s backstop, `stage_timings.csv`), `split_case.sh` (stages S1, S2, S3, H1-H5 of the original pipeline) and `HowMuchPoorer_chunk.m` (HowMuchPoorer in 3-call chunks; it re-declares the SolveEqmBasic globals). Copy them into each case directory.

## docs/
PUMS data dictionaries 2022, 2023 and 2024 (csv; 2024 also pdf), and code lists 2022 and 2024. Source: `https://www2.census.gov/programs-surveys/acs/tech_docs/pums/{data_dict,code_lists}/`.

## crosswalks/
- **Fetched:**
  - Census `2018-occupation-code-list-and-crosswalk.xlsx` and the related lists from `https://www2.census.gov/programs-surveys/demo/guidance/industry-occupation/`.
  - IPUMS `occ_occsoc_crosswalk_2000_onward*` and `OCCBLS_paper.pdf` from `https://usa.ipums.org/usa/resources/`.
  - Dorn `occ2010_occ1990dd`, `occ1990_occ1990dd` from `https://www.ddorn.net/data/`.
- **Built:**
  - `occ2010acs_to_hhjk_empirical.csv`: the authors' own exact map, 487 codes, deterministic.
  - `occ2018_to_hhjk_candidates.csv`.
  - `occ2018_to_hhjk.csv`: the USE column is `modal==1`; `split_share` is for the SPLIT robustness.
  - Audits: `audit_jump_2017_2018.csv`, `audit_jump_by_group.csv`, `audit_race_coding.csv`.

## scripts/
01 → 06 run in order with Python ≥3.10 + pandas + pyarrow + openpyxl + xlrd. Script 06 is the do-file-port dry-run anchor (0 mismatches on 2010 cells).

## Deflators (not files; fetched live, keyless)
FRED `https://fred.stlouisfed.org/graph/fredgraph.csv?id=DPCERD3A086NBEA` and `…?id=CPIAUCSL&fq=Annual&fam=avg`.
- PCE 2010 90.514, 2012 94.534, 2023 120.505.
- CPI-U 2023 304.703.
