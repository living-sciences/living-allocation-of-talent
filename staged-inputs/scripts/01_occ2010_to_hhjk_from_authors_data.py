"""Empirical OCC(2010-2012 ACS code) -> HHJK occ_code (1..66) map, read from the AUTHORS' OWN
shipped 2010-2012 extract (IPUMS OCC + OCC1990 + their occ_code). Market workers only
(emp_full_adj>0), perwt-weighted. Output: crosswalks/occ2010acs_to_hhjk_empirical.csv"""
import pandas as pd, pathlib
HERE = pathlib.Path(__file__).resolve().parents[1]
DTA = HERE.parent / "package/extracted/2012_extract_composite_main.dta"
cols = ["occ", "occ1990", "occ_code", "emp_full_adj", "perwt", "person_adj"]
d = pd.read_stata(DTA, columns=cols, convert_categoricals=False)
d = d[d.emp_full_adj > 0]
d["w"] = d.perwt * d.person_adj
g = d.groupby(["occ", "occ_code"]).w.sum().reset_index()
g["share"] = g.w / g.groupby("occ").w.transform("sum")
g = g.sort_values(["occ", "share"], ascending=[True, False])
g.to_csv(HERE / "crosswalks/occ2010acs_to_hhjk_empirical.csv", index=False)
pure = g.groupby("occ").share.max()
wocc = d.groupby("occ").w.sum()
print("codes:", len(pure), " codes with max share>=0.99:", (pure >= .99).sum(),
      " worker-weight in pure codes:", round(wocc[pure >= .99].sum() / wocc.sum(), 4))
o9 = d.groupby(["occ", "occ1990"]).w.sum().reset_index()
p9 = o9.groupby("occ").w.max() / o9.groupby("occ").w.sum()
print("OCC->OCC1990 deterministic (share>=0.99):", (p9 >= .99).sum(), "/", len(p9),
      " weight:", round(wocc[p9[p9 >= .99].index].sum() / wocc.sum(), 4))
