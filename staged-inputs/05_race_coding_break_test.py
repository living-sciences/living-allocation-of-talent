"""Race/ethnicity comparability test across the 2020 ACS race-coding change.

The paper's groups (do-files): RACE==1 (white, Hispanic origin ignored) and RACE==2 (Black),
crossed with sex. From ACS 2020 the Census Bureau's new write-in coding moved most Hispanic
'white alone' respondents into 'two or more races' / 'some other race'. This script compares
candidate white definitions on statistics that should move smoothly year to year:
  * population share of the group (age 25-54)
  * Hispanic share inside the group
  * mean log annual earnings of full-year full-time workers (paper's earnings definition)
  * Duncan index of the group's HHJK occupation distribution vs the previous year
Years: 2017, 2018, 2019 (old coding) | 2021, 2022, 2023, 2024 (new coding); 2020 skipped
(experimental 1-year). Output: crosswalks/audit_race_coding.csv
"""
import pandas as pd, numpy as np, pathlib
HERE = pathlib.Path(__file__).resolve().parents[1]
CW = HERE / "crosswalks"
xw = pd.read_csv(CW / "occ2018_to_hhjk.csv"); m18 = xw[xw.modal == 1].set_index("occ2018").occ_code
emp = pd.read_csv(CW / "occ2010acs_to_hhjk_empirical.csv"); f1012 = emp.sort_values("share").groupby("occ").occ_code.last()
ip = pd.read_csv(CW / "occ_occsoc_crosswalk_2000_onward_with_code_descriptions.csv", dtype=str, encoding="latin1")
c = list(ip.columns); m1317 = {}
for _, r in ip.iterrows():
    try: m1317.setdefault(int(r[c[11]]), int(r[c[9]]))
    except Exception: pass

DEFS = {
    "W_literal (RAC1P==1, paper code)": lambda d: d.RAC1P == 1,
    "W_bridged (WA + Hisp&RACWHT&~RACBLK)": lambda d: (d.RAC1P == 1) | ((d.HISP > 1) & (d.RACWHT == 1) & (d.RACBLK != 1)),
    "W_nonhisp (NH white alone)": lambda d: (d.RAC1P == 1) & (d.HISP == 1),
    "B_alone (RAC1P==2, paper code)": lambda d: d.RAC1P == 2,
}
rows, prev = [], {}
for y in [2017, 2018, 2019, 2021, 2022, 2023, 2024]:
    d = pd.read_parquet(HERE / f"pums/prime_age_{y}.parquet")
    o = pd.to_numeric(d.OCCP, errors="coerce")
    if y <= 2017:
        d["hh"] = o.map(lambda v: f1012.get(v, f1012.get(m1317.get(v, -1), np.nan)) if pd.notna(v) else np.nan)
    else:
        d["hh"] = o.map(m18)
    wk = d.WKWN if "WKWN" in d else d.WKW.map({1: 51, 2: 49})  # WKW 1=50-52, 2=48-49
    if "WKWN" in d:
        wk = np.where(d.WKWN >= 50, 51, np.where(d.WKWN >= 48, 49, np.nan))
    earn = (d.WAGP.fillna(0) + d.SEMP.fillna(0)) * d.ADJINC / 1e6
    ft = d.ESR.isin([1, 2]) & (d.WKHP >= 30) & pd.notna(wk) & (earn >= 1000)
    T = d.PWGTP.sum()
    for name, f in DEFS.items():
        for sex in (1, 2):
            g = f(d) & (d.SEX == sex)
            w = d.PWGTP[g]
            e = d[g & ft]
            mle = np.average(np.log(earn[g & ft]), weights=e.PWGTP)
            occ = d[g & d.ESR.isin([1, 2]) & d.hh.notna() & (d.WKHP >= 15)].groupby("hh").PWGTP.sum()
            occ = occ / occ.sum()
            key = (name, sex)
            D = 0.5 * occ.sub(prev[key], fill_value=0).abs().sum() if key in prev else np.nan
            prev[key] = occ
            rows.append(dict(year=y, definition=name, sex="M" if sex == 1 else "F",
                             pop_share=w.sum() / T, hisp_share=d.PWGTP[g & (d.HISP > 1)].sum() / w.sum(),
                             mean_ln_earn_nominal=mle, duncan_vs_prev_year=D, n=int(g.sum())))
R = pd.DataFrame(rows)
R.to_csv(CW / "audit_race_coding.csv", index=False)
pd.set_option("display.width", 250)
for name in DEFS:
    print("\n==", name)
    print(R[R.definition == name].pivot(index="year", columns="sex",
          values=["pop_share", "hisp_share", "mean_ln_earn_nominal", "duncan_vs_prev_year"]).round(4).to_string())
