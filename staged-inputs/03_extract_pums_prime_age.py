"""Stream the keyless Census ACS 1-year PUMS person files (zipped, never fully unzipped) and
keep only the columns the HHJK pipeline needs, for ages 25-54 (all races; race filtering is a
pre-declared step of the study, not done here). Writes pums/prime_age_<year>.parquet.

Usage: python 03_extract_pums_prime_age.py 2024 [2023 2022 2018 2017]
"""
import sys, zipfile, pathlib, pandas as pd
HERE = pathlib.Path(__file__).resolve().parents[1]
WANT = ["SERIALNO", "SPORDER", "ST", "STATE", "PWGTP", "AGEP", "SEX", "RAC1P", "RAC2P", "RACWHT",
        "RACBLK", "RACASN", "RACNUM", "HISP", "OCCP", "SOCP", "INDP", "ESR", "COW", "WAGP",
        "SEMP", "PERNP", "WKHP", "WKWN", "WKW", "WKL", "SCHL", "ADJINC", "MIL", "RELSHIPP",
        "RELP", "NATIVITY"]
STR = {"SERIALNO", "SOCP", "OCCP", "INDP"}

def run(year):
    z = zipfile.ZipFile(HERE / f"pums/csv_pus_{year}.zip")
    parts = sorted(n for n in z.namelist() if n.endswith(".csv"))
    out = []
    for p in parts:
        with z.open(p) as f:
            hdr = f.readline().decode().strip().split(",")
        cols = [c for c in WANT if c in hdr]
        with z.open(p) as f:
            for ch in pd.read_csv(f, usecols=cols, chunksize=500_000,
                                  dtype={c: str for c in STR if c in cols}, low_memory=False):
                ch = ch[(ch.AGEP >= 25) & (ch.AGEP <= 54)]
                out.append(ch)
    d = pd.concat(out, ignore_index=True)
    d["YEAR"] = year
    d.to_parquet(HERE / f"pums/prime_age_{year}.parquet", index=False)
    print(year, parts, d.shape, "missing:", [c for c in WANT if c not in d.columns])

for y in sys.argv[1:]:
    run(int(y))
