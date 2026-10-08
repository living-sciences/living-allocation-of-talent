"""Chain crosswalk: ACS PUMS OCCP (2018 Census codes, used 2018+) -> HHJK occ_code (1..66).

Layers (all public, keyless):
  L1  Census "2018-occupation-code-list-and-crosswalk.xlsx", sheet 'Occ Code Changes'
      gives every 2010->2018 code change (splits, merges, renumbers). Codes not listed there
      are unchanged (2018 code == 2010 code).
  L2  IPUMS 'occ_occsoc_crosswalk_2000_onward_with_code_descriptions.csv' aligns the
      2013-2017 ACS OCC codes with the 2010-2012 ACS OCC codes (IPUMS's harmonized rows),
      needed because the authors' 2010 point is the 2010-2012 ACS whose OCC codes differ
      slightly from 2013-2017 (e.g. the 2013 computer-occupation split).
  L3  Empirical 2010-2012 OCC -> HHJK occ_code map from the AUTHORS' OWN shipped extract
      (script 01; deterministic for all 487 codes).

Output: crosswalks/occ2018_to_hhjk.csv with one row per (occ2018, occ_code, n_sources,
        ambiguous flag, source 2010 codes). A 2018 code is AMBIGUOUS if its 2010 sources
        land in more than one HHJK occ_code.
"""
import pandas as pd, pathlib, re
HERE = pathlib.Path(__file__).resolve().parents[1]
CW = HERE / "crosswalks"

emp = pd.read_csv(CW / "occ2010acs_to_hhjk_empirical.csv")
occ1012_to_hhjk = emp.sort_values("share").groupby("occ").occ_code.last().to_dict()

# ---- L2: 2013-2017 code -> 2010-2012 code(s), from IPUMS row alignment
ip = pd.read_csv(CW / "occ_occsoc_crosswalk_2000_onward_with_code_descriptions.csv",
                 dtype=str, encoding="latin1")
c = list(ip.columns)
ip = ip[[c[9], c[11], c[13]]]
ip.columns = ["o1012", "o1317", "o18"]
def num(s):
    try:
        return int(str(s).strip())
    except Exception:
        return None
for k in ip.columns:
    ip[k] = ip[k].map(num)
# forward-fill o1012 within blocks where a 2013-17 code appears without a 2010-12 code
# (IPUMS marks those '(split, see X)'); conservative: only use rows with both present.
m1317 = {}
for _, r in ip.dropna(subset=["o1317"]).iterrows():
    if r.o1012 is not None and not pd.isna(r.o1012):
        m1317.setdefault(int(r.o1317), set()).add(int(r.o1012))

def to_1012(code10):
    """2010 Census code (2013-17 usage) -> set of 2010-2012 ACS codes in the authors' data."""
    if code10 in occ1012_to_hhjk:
        return {code10}
    return {x for x in m1317.get(code10, set()) if x in occ1012_to_hhjk}

# ---- L1: 2018 -> 2010 sources
ch = pd.read_excel(CW / "2018-occupation-code-list-and-crosswalk.xlsx", "Occ Code Changes",
                   header=None, skiprows=3, dtype=str)
ch.columns = ["c10", "t10", "c18", "t18", "summ"]
ch = ch[ch.c10.notna() | ch.c18.notna()].copy()
# Each change is a block that starts at a row carrying a 'Summary of changes' text; a block
# can be a split (1 c10 -> n c18), a merge (n c10 -> 1 c18, e.g. "6300, 6310 and 6320
# combined into 6305") or many-to-many. Pair every c10 with every c18 inside the block.
ch["block"] = ch.summ.notna().cumsum()
src18 = {}
for _, blk in ch.groupby("block"):
    a_s = {num(x) for x in blk.c10 if num(x) is not None}
    b_s = {num(x) for x in blk.c18 if num(x) is not None}
    for b in b_s:
        src18.setdefault(b, set()).update(a_s)

# full 2018 code list (PUMS public-use list)
cl = pd.read_excel(CW / "2018-occupation-code-list-and-crosswalk.xlsx", "2018 Census Occ Code List",
                   header=None, dtype=str)
codes18 = set()
for v in cl[2].dropna():
    v = str(v).strip()
    if re.fullmatch(r"\d{4}", v):
        codes18.add(int(v))

# L2b fallback: IPUMS's own 2018-row notes ("collapsed, includes 8120, 8150 ...",
# "split, see 4130") name the 2010-era codes a PUMS-collapsed 2018 code came from.
ipd = pd.read_csv(CW / "occ_occsoc_crosswalk_2000_onward_with_code_descriptions.csv",
                  dtype=str, encoding="latin1")
cd = list(ipd.columns)
note18 = {}
for _, r in ipd.iterrows():
    o = num(r[cd[13]])
    if o is not None and isinstance(r[cd[14]], str):
        note18[o] = {int(x) for x in re.findall(r"\b(\d{3,4})\b", r[cd[14]])}
# L2c last resort (documented manual, title-based; each is a PUMS-collapsed 2010 code that
# the 2010-2012 IPUMS public-use list folds into a broader code). Filled only if still empty.
MANUAL = {}

rows = []
for o18 in sorted(codes18):
    if o18 >= 9800:  # military
        continue
    srcs = src18.get(o18)
    how = "changed"
    if not srcs:
        srcs = {o18}
        how = "identity"
    s1012 = set().union(*[to_1012(s) for s in srcs])
    if not s1012 and o18 in note18:
        s1012 = set().union(*[to_1012(s) for s in note18[o18]])
        how += "+ipums_note"
    if not s1012 and o18 in MANUAL:
        s1012 = {MANUAL[o18]}
        how += "+manual"
    hh = sorted({occ1012_to_hhjk[s] for s in s1012})
    rows.append(dict(occ2018=o18, src2010=" ".join(map(str, sorted(srcs))),
                     src1012=" ".join(map(str, sorted(s1012))), how=how,
                     hhjk_candidates=" ".join(map(str, hh)), n_hhjk=len(hh)))
out = pd.DataFrame(rows)
out.to_csv(CW / "occ2018_to_hhjk_candidates.csv", index=False)
print(out.n_hhjk.value_counts().sort_index())
print(out[out.n_hhjk != 1].to_string())
