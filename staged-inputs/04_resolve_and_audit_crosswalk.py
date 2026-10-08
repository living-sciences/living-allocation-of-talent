"""Resolve the 2018-code -> HHJK candidate table into a usable crosswalk and audit it.

Resolution rules (pre-declared):
  MODAL (primary, mirrors how IPUMS builds OCC1990: each code goes to its modal 1990 category):
    an ambiguous 2018 code goes to the HHJK category holding the largest perwt-weighted
    market employment among its 2010-2012 source codes in the AUTHORS' 2010-2012 extract.
  SPLIT (robustness): the same weights used as fractional allocation shares.
  Unmapped codes with no 2010-2012 source: manual title-based HHJK assignment (MANUAL_HHJK),
    listed and weight-reported.

Audit outputs (crosswalks/audit_*.csv + stdout):
  A1 coverage: share of 2024 (and 2022-2024 pooled) white+Black employed weight whose code
     maps to exactly one HHJK category without resolution (unambiguous), resolved, manual.
  A2 recode-jump test: HHJK occupation shares for white+Black employed age 25-54 in ACS 2017
     (2010-basis codes, mapped through the authors' own 2010-2012 OCC->occ_code function)
     vs ACS 2018 (2018 codes, mapped through this crosswalk). One-year real change is small,
     so the Duncan dissimilarity index between the two years is an upper bound on the
     artificial discontinuity. Per-category |log share ratio| reported.
"""
import pandas as pd, numpy as np, pathlib
HERE = pathlib.Path(__file__).resolve().parents[1]
CW = HERE / "crosswalks"
emp = pd.read_csv(CW / "occ2010acs_to_hhjk_empirical.csv")
w1012 = emp.groupby("occ").w.sum()
f1012 = emp.sort_values("share").groupby("occ").occ_code.last()
cand = pd.read_csv(CW / "occ2018_to_hhjk_candidates.csv", dtype={"src1012": str})

# Manual (title-based) for 2018 codes with no 2010-2012 source in the authors' data.
# Only codes that actually occur in 2022-2024 PUMS matter; others are PUMS-collapsed away.
MANUAL_HHJK = {
    6540: 47,  # Solar photovoltaic installers -> Construction trades
}

# Parent-title overrides for ambiguous codes where the modal-by-source-size rule picks a large
# source that contributes only a minority of the 2018 code's workers. Each 2018 code follows
# the 2010 code it is the direct successor of by title (Census 'Occ Code Changes' sheet).
PARENT_OVERRIDE = {
    2545: 11,  # Teaching Assistants <- 2540 Teacher Assistants (not 2200 Postsecondary Teachers)
    3545: 17,  # Misc Health Technologists <- 3535 (not 3420)
    5040: 27,  # Communications Equipment Operators, All Other <- 5030 (not 2900)
    6835: 48,  # Explosives Workers <- 6830 (not 6820 Earth Drillers)
    7905: 20,  # CNC tool operators/programmers <- 7900 Computer Control Programmers (not 8965)
    1022: 20,  # Software QA <- 1020 Software Developers (HHJK puts OCC1990 229 in 'Technicians, Other')
}

rows = []
for _, r in cand.iterrows():
    srcs = [int(x) for x in str(r.src1012).split()] if isinstance(r.src1012, str) and r.src1012.strip() else []
    if srcs:
        s = pd.DataFrame({"src": srcs, "hh": [f1012[x] for x in srcs], "w": [w1012[x] for x in srcs]})
        g = s.groupby("hh").w.sum()
        g = g / g.sum()
        pick = PARENT_OVERRIDE.get(r.occ2018, g.idxmax())
        for hh, sh in g.items():
            rows.append(dict(occ2018=r.occ2018, occ_code=int(hh), split_share=sh,
                             modal=int(hh == pick), ambiguous=int(len(g) > 1), manual=0,
                             override=int(r.occ2018 in PARENT_OVERRIDE)))
    elif r.occ2018 in MANUAL_HHJK:
        rows.append(dict(occ2018=r.occ2018, occ_code=MANUAL_HHJK[r.occ2018], split_share=1.0,
                         modal=1, ambiguous=0, manual=1))
xw = pd.DataFrame(rows)
xw.to_csv(CW / "occ2018_to_hhjk.csv", index=False)
modal = xw[xw.modal == 1].set_index("occ2018")

def prep(year):
    d = pd.read_parquet(HERE / f"pums/prime_age_{year}.parquet")
    d = d[d.ESR.isin([1, 2]) & d.RAC1P.isin([1, 2]) & d.OCCP.notna()].copy()
    d["o"] = d.OCCP.astype(int)
    return d[d.o < 9800]

# ---- A1 coverage
for yrs in ([2024], [2022, 2023, 2024]):
    d = pd.concat([prep(y) for y in yrs])
    w = d.groupby("o").PWGTP.sum(); T = w.sum()
    k = modal.reindex(w.index)
    print(f"A1 {yrs}: unambiguous {w[(k.ambiguous == 0) & (k.manual == 0)].sum()/T:.4f}  "
          f"ambiguous(resolved modal) {w[k.ambiguous == 1].sum()/T:.4f}  manual {w[k.manual == 1].sum()/T:.4f}  "
          f"UNMAPPED {w[k.occ_code.isna()].sum()/T:.5f}  codes unmapped: {list(w.index[k.occ_code.isna()])}")

# ---- A2 recode-jump test 2017 (2010-basis) vs 2018 (2018-basis)
ip = pd.read_csv(CW / "occ_occsoc_crosswalk_2000_onward_with_code_descriptions.csv", dtype=str, encoding="latin1")
c = list(ip.columns)
m1317 = {}
for _, r in ip.iterrows():
    try:
        a, b = int(r[c[9]]), int(r[c[11]])
        m1317.setdefault(b, a)
    except Exception:
        pass
d17 = prep(2017)
def map17(o):
    if o in f1012.index:
        return f1012[o]
    if o in m1317 and m1317[o] in f1012.index:
        return f1012[m1317[o]]
    return np.nan
d17["hh"] = d17.o.map(map17)
d18 = prep(2018)
d18["hh"] = d18.o.map(modal.occ_code)
print("A2 unmapped weight 2017:", round(d17.PWGTP[d17.hh.isna()].sum()/d17.PWGTP.sum(), 5),
      " 2018:", round(d18.PWGTP[d18.hh.isna()].sum()/d18.PWGTP.sum(), 5))
s17 = d17.groupby("hh").PWGTP.sum(); s17 /= s17.sum()
s18 = d18.groupby("hh").PWGTP.sum(); s18 /= s18.sum()
J = pd.concat([s17.rename("s2017"), s18.rename("s2018")], axis=1).fillna(0)
J["logratio"] = np.log(J.s2018 / J.s2017)
J.index = J.index.astype(int)
J.to_csv(CW / "audit_jump_2017_2018.csv")
D = 0.5 * (J.s2018 - J.s2017).abs().sum()
print(f"A2 Duncan dissimilarity 2017 vs 2018 over HHJK cats: {D:.4f}")
big = J[(J.logratio.abs() > 0.15) & ((J.s2017 + J.s2018) > 0.002)]
print("A2 categories with |log ratio|>0.15 (and share>0.1%):\n", big.round(4).to_string())
print("A2 weight in flagged categories (2018):", round(big.s2018.sum(), 4))
# baseline: same statistic for 2022 vs 2023 (both 2018-basis) = genuine year-to-year noise+change
def sh(y):
    d = prep(y); d["hh"] = d.o.map(modal.occ_code)
    s = d.groupby("hh").PWGTP.sum(); return s / s.sum()
a, b = sh(2022), sh(2023)
print(f"A2 baseline Duncan 2022 vs 2023 (same coding): {0.5*(a-b).abs().sum():.4f}")

# ---- A3 group-specific recode-jump test (paper's 4 groups, literal pre-2020 coding RAC1P)
def grp(d):
    return np.select([(d.RAC1P == 1) & (d.SEX == 1), (d.RAC1P == 1) & (d.SEX == 2),
                      (d.RAC1P == 2) & (d.SEX == 1), (d.RAC1P == 2) & (d.SEX == 2)],
                     ["WM", "WW", "BM", "BW"], "x")
d22 = prep(2022); d22["hh"] = d22.o.map(modal.occ_code)
d23 = prep(2023); d23["hh"] = d23.o.map(modal.occ_code)
res = []
for a_, b_, lab in [(d17, d18, "2017v2018 (recode)"), (d22, d23, "2022v2023 (baseline)")]:
    a_ = a_.assign(g=grp(a_)); b_ = b_.assign(g=grp(b_))
    for g in ["WM", "WW", "BM", "BW"]:
        sa = a_[a_.g == g].groupby("hh").PWGTP.sum(); sa /= sa.sum()
        sb = b_[b_.g == g].groupby("hh").PWGTP.sum(); sb /= sb.sum()
        D = 0.5 * sa.sub(sb, fill_value=0).abs().sum()
        res.append(dict(pair=lab, group=g, duncan=round(D, 4)))
R = pd.DataFrame(res).pivot(index="group", columns="pair", values="duncan")
R.to_csv(CW / "audit_jump_by_group.csv")
print("A3 group Duncan:\n", R.to_string())
