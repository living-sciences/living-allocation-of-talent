"""PUMS-route data construction (spec A.3), parameterised so Gate 3b (2010-2012) and the
2023 build run the SAME code path.

build_period(year_list, pce, base_year, floor_value, floor_basis, occ_map, race_rule,
             weight_scale, year_label, cohort_map, deflate=True, split_map=None)

Returns (long_output_df, diagnostics).  Person-level construction follows
create_2010_IPUMS_extract.do on the Census PUMS variables (recency-verified mapping):
  AGEP, SEX, RAC1P/RACWHT/RACBLK/HISP, ESR, WKHP, WKW|WKWN, WAGP+SEMP, ADJINC, SCHL, PWGTP, OCCP.
"""
import pathlib
import numpy as np
import pandas as pd
import doport

PUMS = pathlib.Path(__file__).resolve().parents[1] / "pums"

# SCHL -> highgrade (spec A.3 education table)
SCHL_HG = {1: 0}
for s in range(2, 8):
    SCHL_HG[s] = 4
for s in range(8, 12):
    SCHL_HG[s] = 8
SCHL_HG[12] = 9
SCHL_HG[13] = 10
SCHL_HG[14] = 11
for s in range(15, 19):
    SCHL_HG[s] = 12
SCHL_HG[19] = 13
SCHL_HG[20] = 14
SCHL_HG[21] = 16
for s in range(22, 25):
    SCHL_HG[s] = 19


def race_masks(d, rule):
    rac = d["RAC1P"].to_numpy()
    B = rac == 2
    if rule == "W_lit":
        W = rac == 1
    elif rule == "W_NH":
        W = (rac == 1) & (d["HISP"].to_numpy() == 1)
    elif rule == "Wstar":
        W = (rac == 1) | ((d["HISP"].to_numpy() > 1) &
                          (d["RACWHT"].to_numpy() == 1) & (d["RACBLK"].to_numpy() != 1))
    else:
        raise ValueError(rule)
    return W, B


def build_period(year_list, pce, base_year, floor_value, floor_basis, occ_map, race_rule,
                 weight_scale, year_label, cohort_map, deflate=True, split_map=None,
                 apply_adjinc=True, apply_pce=None):
    """apply_adjinc: multiply earnings by ADJINC/1e6 (within-year constant-dollar factor).
    apply_pce: multiply by PCE_base/PCE_year (cross-year inflation to base_year).
      If None, defaults to the legacy `deflate` flag (adjinc AND pce)."""
    if apply_pce is None:
        apply_pce = deflate
        apply_adjinc = deflate
    frames = []
    for y in year_list:
        frames.append(pd.read_parquet(PUMS / f"prime_age_{y}.parquet"))
    d = pd.concat(frames, ignore_index=True)

    diag = {}
    # --- sample: prime age, W*|B
    d = d[(d.AGEP >= 25) & (d.AGEP <= 54)].copy()
    W, B = race_masks(d, race_rule)
    sex = d["SEX"].to_numpy()
    ind_wm = ((W) & (sex == 1)).astype(float)
    ind_ww = ((W) & (sex == 2)).astype(float)
    ind_bm = ((B) & (sex == 1)).astype(float)
    ind_bw = ((B) & (sex == 2)).astype(float)
    inrace = (W | B)
    d = d[inrace].copy()
    ind_wm = ind_wm[inrace]; ind_ww = ind_ww[inrace]
    ind_bm = ind_bm[inrace]; ind_bw = ind_bw[inrace]

    esr = d["ESR"].to_numpy()
    occp = pd.to_numeric(d["OCCP"], errors="coerce").to_numpy()
    wkhp = pd.to_numeric(d["WKHP"], errors="coerce").to_numpy()

    # --- drop military, unemployed, employed-missing-occ
    military = np.isin(esr, [4, 5]) | (np.nan_to_num(occp, nan=0) >= 9800)
    unemployed = (esr == 3)
    employed = np.isin(esr, [1, 2])
    emp_missing_occ = employed & ~np.isfinite(occp)
    drop = military | unemployed | emp_missing_occ
    keep = ~drop

    d = d[keep].copy()
    esr = esr[keep]; occp = occp[keep]; wkhp = wkhp[keep]
    ind_wm = ind_wm[keep]; ind_ww = ind_ww[keep]
    ind_bm = ind_bm[keep]; ind_bw = ind_bw[keep]

    employed = np.isin(esr, [1, 2])
    emp_full = employed & (wkhp >= 30)
    emp_part = employed & (wkhp >= 15) & (wkhp < 30)
    home = ~emp_full & ~emp_part
    emp_full_adj = np.where(emp_full, 1.0, np.where(emp_part, 0.5, 0.0))
    person_adj = np.where(emp_part, 0.5, 1.0)

    # --- weeks
    if "WKWN" in d.columns:
        wkwn = pd.to_numeric(d["WKWN"], errors="coerce").to_numpy()
        full_year = np.isfinite(wkwn) & (wkwn >= 48)
        wks = np.where(np.isfinite(wkwn) & (wkwn >= 50) & (wkwn <= 52), 51.0,
                       np.where(np.isfinite(wkwn) & (wkwn >= 48) & (wkwn <= 49), 49.0, np.nan))
    else:
        wkw = pd.to_numeric(d["WKW"], errors="coerce").to_numpy()
        full_year = np.isin(wkw, [1, 2])
        wks = np.where(wkw == 1, 51.0, np.where(wkw == 2, 49.0, np.nan))

    # --- earnings/dollars
    wagp = np.nan_to_num(pd.to_numeric(d["WAGP"], errors="coerce").to_numpy())
    semp = np.nan_to_num(pd.to_numeric(d["SEMP"], errors="coerce").to_numpy())
    adjinc = pd.to_numeric(d["ADJINC"], errors="coerce").to_numpy() / 1e6
    yr = d["YEAR"].to_numpy()
    nominal = wagp + semp
    pce_year = np.array([pce[int(a)] for a in yr], dtype=float)
    earnings = nominal.astype(float)
    if apply_adjinc:
        earnings = earnings * adjinc
    if apply_pce:
        earnings = earnings * (pce[base_year] / pce_year)

    floor_var = nominal if floor_basis == "nominal" else earnings
    emp_full_lastyear = full_year & (floor_var >= floor_value)

    incwage_full = np.where(emp_full_lastyear & (emp_full_adj > 0), earnings, np.nan)
    wage = incwage_full / (wkhp * wks)

    # --- education
    schl = pd.to_numeric(d["SCHL"], errors="coerce").to_numpy()
    hg = np.array([SCHL_HG.get(int(s), np.nan) if np.isfinite(s) else np.nan for s in schl])
    hg = np.where(np.isfinite(hg), hg, 0.0)  # SCHL missing -> 0 (do-file: educ 0 -> 0)

    # --- occupation code
    occ_code = np.zeros(len(d), dtype=float)
    worker = emp_full_adj > 0
    occ_int = np.where(np.isfinite(occp), occp, -1).astype(int)
    mapped = np.array([occ_map.get(o, np.nan) for o in occ_int])
    # unmapped-worker diagnostic
    w = d["PWGTP"].to_numpy(float) / weight_scale
    unmapped_worker = worker & ~np.isfinite(mapped)
    diag["unmapped_worker_weight_share"] = float(w[unmapped_worker].sum() / w[worker].sum())
    occ_code = np.where(worker, mapped, 0.0)
    occ_code = np.where(worker & ~np.isfinite(mapped), -1.0, occ_code)  # unmapped -> excluded
    occ_code2 = np.where(person_adj == 0.5, 0.0, occ_code)

    df = pd.DataFrame({
        "age": d["AGEP"].to_numpy(),
        "w": w,
        "pa": person_adj,
        "wf": ((emp_full_lastyear) & (emp_full_adj == 1) & np.isfinite(incwage_full)).astype(float),
        "inc": incwage_full,
        "wage": wage,
        "hg": hg,
        "ind_wm": ind_wm, "ind_ww": ind_ww, "ind_bm": ind_bm, "ind_bw": ind_bw,
        "occ_code": occ_code,
        "occ_code2": occ_code2,
        "emp_full_adj": emp_full_adj,
        "emp_part": emp_part.astype(float),
        "home": home.astype(float),
    })

    out = doport.build_output(df, year_label, cohort_map)
    diag["n_persons"] = int(len(df))
    diag["total_weight"] = float(df["w"].sum())
    return out, diag, df
