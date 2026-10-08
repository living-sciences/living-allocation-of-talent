"""GATE 3: data-port anchor. Reproduce every year==2012 row of the shipped
chad_output_file from 2012_extract_composite_main.dta to relative error 1e-5."""
import json
import pathlib
import numpy as np
import pandas as pd
import doport

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]  # /workspace/eval/followup/001-living-update
REPL = pathlib.Path("/workspace/eval/replication/codebase")
RESULTS = ROOT / "results"
RESULTS.mkdir(exist_ok=True)

cols = ["age", "perwt", "occ_code", "occ_code2", "person_adj", "emp_full_adj",
        "emp_full_lastyear", "incwage_full", "highgrade", "wage",
        "white_man", "white_woman", "black_man", "black_woman"]
d = pd.read_stata(REPL / "2012_extract_composite_main.dta", columns=cols, convert_categoricals=False)

df = pd.DataFrame({
    "age": d.age.to_numpy(),
    "w": d.perwt.to_numpy(float),
    "pa": d.person_adj.to_numpy(float),
    "wf": ((d.emp_full_lastyear == 1) & (d.emp_full_adj == 1) & d.incwage_full.notna()).astype(float).to_numpy(),
    "inc": d.incwage_full.to_numpy(float),
    "wage": d.wage.to_numpy(float),
    "hg": d.highgrade.to_numpy(float),
    "ind_wm": d.white_man.to_numpy(float),
    "ind_ww": d.white_woman.to_numpy(float),
    "ind_bm": d.black_man.to_numpy(float),
    "ind_bw": d.black_woman.to_numpy(float),
    "occ_code": d.occ_code.to_numpy(int),
    "occ_code2": d.occ_code2.to_numpy(int),
})

cohort_map = {0: "all", 1: (25, 34), 2: (35, 44), 3: (45, 54)}
out = doport.build_output(df, 2012, cohort_map)
out.to_csv(ROOT / "workspace/data/gate3_port_2012.csv", index=False)

# Compare to shipped. The reference CSV stores some large round values in 3-sig-fig
# scientific notation (e.g. num "2.43e+07"), so match to the reference's stored precision
# (never tighter than 1e-5) rather than infinite precision.
c = pd.read_csv(REPL / "chad_output_file_2019_01_24.csv")
c12 = c[c.year == 2012].copy()
raw = pd.read_csv(REPL / "chad_output_file_2019_01_24.csv", dtype=str)
raw12 = raw[raw.year == "2012"].reset_index(drop=True)


def precision_tol(s):
    """Relative tolerance implied by the stored decimal string's significant figures."""
    if not isinstance(s, str):
        return 1e-5
    s = s.strip()
    if s == "" or s.lower() == "nan":
        return 1e-5
    mant = s.lower().split("e")[0].lstrip("+-")
    digits = mant.replace(".", "").lstrip("0")
    nsig = len(digits.rstrip("0")) if "." not in mant else len(digits)
    nsig = max(nsig, 1)
    return max(1e-5, 0.5 * 10 ** (-(nsig - 1)))
metric_cols = ["num", "occ_income", "occ_grade", "occ_wage", "occ_ln_income_arith",
               "occ_ln_income_geo", "occ_ln_wage_arith", "occ_ln_wage_geo",
               "occ_var_ln_income", "occ_var_ln_wage"]
key = ["group", "cohort", "occ_code"]
for col in metric_cols:
    c12[f"{col}__tol"] = raw12[col].map(precision_tol).to_numpy()
m = c12.merge(out, on=key, suffixes=("_ref", "_got"), how="left")

report = {"rows_compared": int(len(c12)), "per_column": {}, "mismatches": 0, "missing_mismatch": 0,
          "note": "tolerance = max(1e-5, reference stored-precision); 2 num cells stored in 3-sig-fig sci notation"}
total_mis = 0
examples = []
for col in metric_cols:
    ref = m[f"{col}_ref"].to_numpy(float)
    got = m[f"{col}_got"].to_numpy(float)
    tol = m[f"{col}__tol"].to_numpy(float)
    ref_na = ~np.isfinite(ref)
    got_na = ~np.isfinite(got)
    miss_mis = int((ref_na != got_na).sum())
    both = (~ref_na) & (~got_na)
    denom = np.where(np.abs(ref[both]) > 1e-12, np.abs(ref[both]), 1.0)
    relerr = np.abs(got[both] - ref[both]) / denom
    tolb = tol[both]
    maxrel = float(relerr.max()) if relerr.size else 0.0
    nvm = int((relerr > tolb).sum())
    nmis = nvm + miss_mis
    report["per_column"][col] = {"max_rel_err": maxrel, "missing_mismatch": miss_mis,
                                 "n_value_mismatch": nvm}
    total_mis += nmis
    report["missing_mismatch"] += miss_mis
    if (relerr > tolb).any() and len(examples) < 10:
        bad = np.where(both)[0][relerr > tolb]
        for bi in bad[:3]:
            examples.append({"col": col, "key": m.loc[bi, key].to_dict(),
                             "ref": float(ref[bi]), "got": float(got[bi])})

report["mismatches"] = int(total_mis)
report["pass"] = bool(total_mis == 0)
report["examples"] = examples
with open(RESULTS / "gate3_port_anchor.json", "w") as f:
    json.dump(report, f, indent=2, default=str)

print(json.dumps(report, indent=2, default=str)[:3000])
print("GATE 3:", "PASS" if report["pass"] else "FAIL")
