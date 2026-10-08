"""Pandas port of create_ipums_1960_2010_analysis_file.do (the collapse/formula layer).

Shared by Gate 3 (shipped .dta), Gate 3b (PUMS-route 2010) and the 2023 build.
Given a person-level frame with the constructed HHJK variables, it reproduces the
`chad_output_file` long format: for each (group 0..4, cohort, occ_code 0..66) a row with
num, occ_income, occ_grade, occ_wage, ln arith/geo income & wage, var ln income/wage.

Stata semantics replicated exactly:
 * part-time workers count 0.5 in their market occ (step1, by occ_code) AND 0.5 in home
   (step2, by occ_code2==0).  occ 0 = home.
 * [fw=perwt] frequency weights.  (sum) sums perwt*value, ignoring missing (ln(<=0)=missing).
 * (sd) is the frequency-weighted sample sd: mean=Sw x/Sw, var=(Sw x^2 - Sw*mean^2)/(Sw-1),
   missing when fewer than 2 non-missing obs.
 * occ_grade for group0 uses highgrade*person_adj in the numerator; for groups 1-4 the
   numerator is highgrade*group (NO person_adj) -- an asymmetry in the do-file, kept.
"""
import numpy as np
import pandas as pd

GROUPS = [0, 1, 2, 3, 4]  # 0=all,1=WM,2=WW,3=BM,4=BW


def _wsd_var(sub_w, sub_x):
    """Frequency-weighted sample variance (Stata (sd))^2 over non-missing x."""
    m = np.isfinite(sub_x)
    w = sub_w[m].astype(float)
    x = sub_x[m].astype(float)
    if len(x) < 1:
        return np.nan
    Sw = w.sum()
    # Stata (sd) with [fw=perwt]: a single record of weight w expands to w identical
    # points, so sd=0 (not missing) as long as the fw count N=Sw exceeds 1.
    if Sw <= 1:
        return np.nan
    mean = (w * x).sum() / Sw
    var = ((w * x * x).sum() - Sw * mean * mean) / (Sw - 1.0)
    return var


def _agg_for_frame(frame, keycol):
    """Return per-key weighted sums and variances for all 5 groups.

    frame must have: w, pa, wf(0/1), inc, wage, hg, ind_wm, ind_ww, ind_bm, ind_bw, <keycol>.
    """
    f = frame
    w = f["w"].to_numpy(float)
    pa = f["pa"].to_numpy(float)
    wf = f["wf"].to_numpy(float)
    inc = f["inc"].to_numpy(float)       # nan where not full-year worker
    wage = f["wage"].to_numpy(float)
    hg = f["hg"].to_numpy(float)
    ln_inc = np.where((wf > 0) & (inc > 0), np.log(np.where(inc > 0, inc, np.nan)), np.nan)
    ln_wage = np.where((wf > 0) & (wage > 0), np.log(np.where(wage > 0, wage, np.nan)), np.nan)
    inc0 = np.where(np.isfinite(inc), inc, 0.0)
    wage0 = np.where(np.isfinite(wage), wage, 0.0)

    base = pd.DataFrame({"key": f[keycol].to_numpy()})
    inds = {0: np.ones(len(f)), 1: f["ind_wm"].to_numpy(float),
            2: f["ind_ww"].to_numpy(float), 3: f["ind_bm"].to_numpy(float),
            4: f["ind_bw"].to_numpy(float)}

    out = {}
    for g, ind in inds.items():
        d = pd.DataFrame({"key": base["key"].to_numpy()})
        d["num"] = w * ind * pa
        d["wf"] = w * ind * wf
        d["inc"] = w * ind * inc0 * wf
        d["lninc"] = w * ind * np.where(np.isfinite(ln_inc), ln_inc, 0.0) * (np.isfinite(ln_inc))
        if g == 0:
            d["hg"] = w * hg * pa
            d["num_hg_den"] = w * pa          # count_num_adj
        else:
            d["hg"] = w * hg * ind            # NO person_adj (do-file)
            d["num_hg_den"] = w * ind * pa    # group_adj
        d["wage"] = w * ind * wage0 * wf
        d["lnwage"] = w * ind * np.where(np.isfinite(ln_wage), ln_wage, 0.0) * (np.isfinite(ln_wage))
        s = d.groupby("key").sum()
        out[g] = s
    return out, (base, w, inds, ln_inc, ln_wage)


def collapse_cohort(df, keys_market="occ_code", keys_home="occ_code2"):
    """Collapse one cohort subset into the long per-(group,occ) table."""
    mk = df[df[keys_market] > 0].copy()
    mk["key"] = mk[keys_market]
    hm = df[df[keys_home] == 0].copy()
    hm["key"] = 0
    frame = pd.concat([mk, hm], ignore_index=True)

    agg, extra = _agg_for_frame(frame, "key")
    base, w, inds, ln_inc, ln_wage = extra

    occ_keys = sorted(frame["key"].unique().tolist())
    rows = []
    # Precompute group masks on frame for variance
    fw = frame["wf"].to_numpy(float)
    finc = frame["inc"].to_numpy(float)
    fwage = frame["wage"].to_numpy(float)
    fkey = frame["key"].to_numpy()
    fln_inc = np.where((fw > 0) & (finc > 0), np.log(np.where(finc > 0, finc, np.nan)), np.nan)
    fln_wage = np.where((fw > 0) & (fwage > 0), np.log(np.where(fwage > 0, fwage, np.nan)), np.nan)
    fweight = frame["w"].to_numpy(float)
    finds = {0: np.ones(len(frame)), 1: frame["ind_wm"].to_numpy(float),
             2: frame["ind_ww"].to_numpy(float), 3: frame["ind_bm"].to_numpy(float),
             4: frame["ind_bw"].to_numpy(float)}

    # index frame rows by key for fast variance slicing
    key_to_idx = {k: np.where(fkey == k)[0] for k in occ_keys}

    for g in GROUPS:
        s = agg[g]
        for o in occ_keys:
            if o in s.index:
                r = s.loc[o]
            else:
                r = None
            num = float(r["num"]) if r is not None else 0.0
            wf_sum = float(r["wf"]) if r is not None else 0.0
            inc_sum = float(r["inc"]) if r is not None else 0.0
            lninc_sum = float(r["lninc"]) if r is not None else 0.0
            hg_sum = float(r["hg"]) if r is not None else 0.0
            hg_den = float(r["num_hg_den"]) if r is not None else 0.0
            wage_sum = float(r["wage"]) if r is not None else 0.0
            lnwage_sum = float(r["lnwage"]) if r is not None else 0.0

            occ_income = inc_sum / wf_sum if wf_sum > 0 else np.nan
            occ_grade = hg_sum / hg_den if hg_den > 0 else np.nan
            occ_ln_income_geo = lninc_sum / wf_sum if wf_sum > 0 else np.nan
            occ_ln_income_arith = np.log(occ_income) if (occ_income is not None and occ_income > 0) else np.nan
            if g == 0:
                occ_wage = np.nan
                occ_ln_wage_geo = np.nan
                occ_ln_wage_arith = np.nan
            else:
                occ_wage = wage_sum / wf_sum if wf_sum > 0 else np.nan
                occ_ln_wage_geo = lnwage_sum / wf_sum if wf_sum > 0 else np.nan
                occ_ln_wage_arith = np.log(occ_wage) if (occ_wage > 0) else np.nan

            # variances
            idx = key_to_idx[o]
            ind = finds[g][idx]
            sel = ind > 0
            sub_w = fweight[idx][sel]
            vi = _wsd_var(sub_w, fln_inc[idx][sel])
            if g == 0:
                vw = np.nan
            else:
                vw = _wsd_var(sub_w, fln_wage[idx][sel])

            rows.append(dict(group=g, occ_code=int(o), num=num,
                             occ_income=occ_income, occ_grade=occ_grade, occ_wage=occ_wage,
                             occ_ln_income_arith=occ_ln_income_arith,
                             occ_ln_income_geo=occ_ln_income_geo,
                             occ_ln_wage_arith=occ_ln_wage_arith,
                             occ_ln_wage_geo=occ_ln_wage_geo,
                             occ_var_ln_income=vi, occ_var_ln_wage=vw))
    return pd.DataFrame(rows)


def build_output(df, year, cohort_label_map):
    """df: person frame with constructed cols. cohort_label_map: {label:(lo,hi) age band or 'all'}.

    Produces the full long table with 'cohort' and 'year' columns.
    """
    pieces = []
    for label, band in cohort_label_map.items():
        if band == "all":
            sub = df
        else:
            lo, hi = band
            sub = df[(df["age"] >= lo) & (df["age"] <= hi)]
        tab = collapse_cohort(sub)
        tab["cohort"] = label
        tab["year"] = year
        pieces.append(tab)
    out = pd.concat(pieces, ignore_index=True)
    cols = ["year", "group", "cohort", "occ_code", "num", "occ_income", "occ_grade",
            "occ_wage", "occ_ln_income_arith", "occ_ln_income_geo", "occ_ln_wage_arith",
            "occ_ln_wage_geo", "occ_var_ln_income", "occ_var_ln_wage"]
    return out[cols].sort_values(["cohort", "group", "occ_code"]).reset_index(drop=True)
