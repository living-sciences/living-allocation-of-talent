"""Dry-run anchor for the pandas port of create_ipums_1960_2010_analysis_file.do.
Rebuilds the 2010 (year=2012), young cohort (cohort=1), 4 groups x occ {0,1,7,15,22,47} cells
of `num` (perwt*person_adj; home uses occ_code2==0) and `occ_income` (perwt-weighted mean of
incwage_full over working_full) from the authors' shipped 2012_extract_composite_main.dta and
compares to chad_output_file.csv. Verified 2026-10-05: all 24 num and 20 occ_income cells match
to the printed precision."""
import pandas as pd, numpy as np, pathlib
PK = pathlib.Path(__file__).resolve().parents[2] / "package/extracted"
c = pd.read_csv(PK / "chad_output_file.csv")
cols = ["age", "perwt", "occ_code", "occ_code2", "person_adj", "white_man", "white_woman",
        "black_man", "black_woman", "incwage_full", "emp_full_lastyear", "emp_full_adj"]
d = pd.read_stata(PK / "2012_extract_composite_main.dta", columns=cols, convert_categoricals=False)
y = d[(d.age >= 25) & (d.age <= 34)]
bad = 0
for gi, g in enumerate(["white_man", "white_woman", "black_man", "black_woman"], 1):
    m = y[g] == 1
    ref = c[(c.year == 2012) & (c.cohort == 1) & (c.group == gi)].set_index("occ_code")
    for o in [0, 1, 7, 15, 22, 47]:
        s = y[m & ((y.occ_code2 == 0) if o == 0 else (y.occ_code == o))]
        num = (s.perwt * s.person_adj).sum()
        ok = abs(num - ref.num[o]) <= 0.5
        if o:
            wf = s[(s.emp_full_lastyear == 1) & (s.emp_full_adj == 1) & s.incwage_full.notna()]
            inc = np.average(wf.incwage_full, weights=wf.perwt)
            ok &= abs(inc / ref.occ_income[o] - 1) < 1e-5
        bad += not ok
        print(g, o, round(float(num), 1), ref.num[o], "OK" if ok else "MISMATCH")
print("mismatches:", bad)
