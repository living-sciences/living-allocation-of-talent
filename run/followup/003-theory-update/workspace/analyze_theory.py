#!/usr/bin/env python3
"""Study 002/003 theory-update. Items 1,2,4: friction-convergence law, era fits,
backtest, out-of-sample stall classification, tauW/tauH split of the 2010-23 change,
and the written-down model. Pure reuse of 001's saved .mat estimates. No fetch."""
import scipy.io as sio, numpy as np, os, json, csv
from scipy.optimize import curve_fit

ROOT="/workspace/eval/followup/001-living-update/workspace/cases"
OUT="/workspace/eval/followup/003-theory-update/results"
os.makedirs(OUT,exist_ok=True)
GROUPS=["WM","WW","BM","BW"]
# true midpoint dates (A.2 / item1): 2010-label -> 2011, 2023-label -> 2023
DATES=np.array([1960,1970,1980,1990,2000,2011,2023.0])

def load_series(case):
    d=sio.loadmat(os.path.join(ROOT,case,"TalentData_Benchmark.mat"))
    return d["meanlogtau"], d["varlogtau"], d["Decades"].ravel(), d

ml7,vl7,dec7,dL=load_series("Living")        # 7-period (primary inputs, B2)
mlB,vlB,decB,dB=load_series("Benchmark")     # 6-period (original estimates, B2 2nd col)
# robustness variants for R1-R4 spread and item-2 R5/R8 split
VARIANTS={k:load_series(v) for k,v in
          {"R1":"R1_WNH","R2":"R2_Wlit","R3":"R3_2024","R4":"R4_SPLIT",
           "R5":"R5_unscaled","R8":"R8_bands"}.items()}

def claw(t,linf,lam,y0):           # convergence law, y0 fixed (anchor at 1960)
    return linf+(y0-linf)*np.exp(-lam*(t-1960.0))

def fit_law(dates,y):
    """Fit (linf,lambda) with 1960 anchored to y[0]. Returns params, se, resid."""
    y0=y[0]
    f=lambda t,linf,lam: claw(t,linf,lam,y0)
    # init: floor = min observed, lambda from half-decay
    p0=[min(y.min(),y[-1]),0.03]
    try:
        p,cov=curve_fit(f,dates,y,p0=p0,maxfev=200000,
                        bounds=([-5,1e-5],[max(y0,5),1.0]))
        se=np.sqrt(np.diag(cov))
    except Exception as e:
        p=np.array(p0); se=np.array([np.nan,np.nan])
    resid=y-f(dates,*p)
    return p,se,resid,y0

def analyze_quantity(series7,seriesB,label):
    """series: (7-period array 7x4). Fit law per group on 1960-2010, backtest, OOS."""
    res={}
    for g in range(1,4):               # skip WM reference
        y7=series7[:,g]                 # 7 points
        # --- primary fit on 1960-2010 (indices 0..5) ---
        p,se,resid,y0=fit_law(DATES[:6],y7[:6])
        linf,lam=p
        pred2023=claw(2023,linf,lam,y0)
        obs2023=y7[6]
        oos_err=abs(obs2023-pred2023)
        # --- 6-period-input fit (B2 second column) ---
        yB=seriesB[:,g]
        pB,seB,_,y0B=fit_law(DATES[:6],yB[:6])
        # --- backtest: fit 1960-2000 (idx 0..4), predict 2010 (2011) ---
        pb,_,_,y0b=fit_law(DATES[:5],y7[:5])
        pred2010=claw(2011,pb[0],pb[1],y0b)
        e=abs(y7[5]-pred2010)
        # 6-period backtest too
        pbB,_,_,y0bB=fit_law(DATES[:5],yB[:5])
        eB=abs(yB[5]-claw(2011,pbB[0],pbB[1],y0bB))
        res[GROUPS[g]]=dict(linf=linf,lam=lam,se_linf=se[0],se_lam=se[1],
            resid=resid.tolist(),y0=y0,pred2023=pred2023,obs2023=obs2023,
            oos_err=oos_err,backtest_e=e,backtest_eB=eB,pred2010=pred2010,obs2010=y7[5],
            linfB=pB[0],lamB=pB[1],
            full_decline_1960_2010=y7[0]-y7[5])
    return res

MEAN=analyze_quantity(ml7,mlB,"meanlogtau")
VAR =analyze_quantity(vl7,vlB,"varlogtau")

# ---- R1-R4 spread of the 2023 meanlogtau (band component) ----
spread={}
for g in range(1,4):
    vals=[ml7[6,g]]+[VARIANTS[k][0][6,g] for k in ["R1","R2","R3","R4"]]
    spread[GROUPS[g]]=max(vals)-min(vals)

# ---- per-decade annualized decline in mean ln tau (true midpoint spacing) ----
def decade_rates(y):
    return {
      "1960-80":(y[0]-y[2])/20.0,
      "1980-2000":(y[2]-y[4])/20.0,
      "2000-10":(y[4]-y[5])/11.0,
      "2010-23":(y[5]-y[6])/12.0,
      "avg_1960-2010":(y[0]-y[5])/51.0,
    }

# ---- stall classification ----
def classify(g):
    y=ml7[:,g]
    r=decade_rates(y)
    m=MEAN[GROUPS[g]]
    b=max(spread[GROUPS[g]],m["backtest_e"])
    full=m["full_decline_1960_2010"]
    d_recent=r["2010-23"]; d_avg=r["avg_1960-2010"]
    above = m["obs2023"]-m["pred2023"]   # >0 means above the law path (worse/slower)
    # taxonomy
    if m["backtest_e"]>full and full>0:
        cls="not classifiable (law fails backtest)"
    elif d_recent<0:
        cls="reversed"
    elif d_recent>= d_avg/3.0:
        cls="continued"
    else:
        cls="stalled" if above> b else "slowed"
    return dict(group=GROUPS[g],rates=r,band_b=b,spread_R1R4=spread[GROUPS[g]],
                backtest_e=m["backtest_e"],full_decline=full,
                above_law_2023=above,d_recent=d_recent,d_avg=d_avg,
                frac_of_avg=d_recent/d_avg if d_avg else np.nan,classification=cls)

CLS={GROUPS[g]:classify(g) for g in range(1,4)}

# ================= item 2: tauW/tauH split of the 2010->23 change =================
def split_change(case):
    _,_,_,d=load_series(case)
    eta=float(np.ravel(d["eta"])[0]); ew=d["earningsweights_avg"].ravel().astype(float)
    TauH_T=d["TauH_T"]; TauW=d["TauW"]; w=ew[1:67]
    def ewm(x):
        m=~np.isnan(x)&~np.isinf(x); ww=w[m]/w[m].sum(); return float(np.sum(x[m]*ww))
    out={}
    for g in range(1,4):
        pH=np.array([ewm(eta*np.log(1+TauH_T[1:67,g,t]))  for t in range(7)])
        pW=np.array([ewm(-np.log(1-TauW[1:67,g,t]))       for t in range(7)])
        dH=pH[6]-pH[5]; dW=pW[6]-pW[5]; tot=dH+dW
        out[GROUPS[g]]=dict(dH=dH,dW=dW,total=tot,
            shareH=dH/tot if tot else np.nan, shareW=dW/tot if tot else np.nan,
            H_path=pH.tolist(),W_path=pW.tolist())
    return out

SPLIT={"primary":split_change("Living"),"R5":split_change("R5_unscaled"),
       "R8":split_change("R8_bands")}

# ===================== write outputs =====================
# convergence_law.csv
with open(os.path.join(OUT,"convergence_law.csv"),"w",newline="") as f:
    wr=csv.writer(f)
    wr.writerow(["group","quantity","lambda_7p","tau_inf_logmean_7p","tau_inf_level_7p",
                 "se_lambda","se_tauinf","lambda_6p","tau_inf_6p",
                 "obs_2023","pred_2023_from_1960_2010","oos_forecast_err",
                 "backtest_e_7p","backtest_e_6p","band_b","full_decline_1960_2010"])
    for g in range(1,4):
        for qn,Q in [("mean_ln_tau",MEAN),("var_ln_tau",VAR)]:
            m=Q[GROUPS[g]]
            band=max(spread[GROUPS[g]],m["backtest_e"]) if qn=="mean_ln_tau" else ""
            wr.writerow([GROUPS[g],qn,f"{m['lam']:.5f}",f"{m['linf']:.5f}",
                f"{np.exp(m['linf']):.4f}",f"{m['se_lam']:.5f}",f"{m['se_linf']:.5f}",
                f"{m['lamB']:.5f}",f"{m['linfB']:.5f}",f"{m['obs2023']:.5f}",
                f"{m['pred2023']:.5f}",f"{m['oos_err']:.5f}",f"{m['backtest_e']:.5f}",
                f"{m['backtest_eB']:.5f}",f"{band if band=='' else round(band,5)}",
                f"{m['full_decline_1960_2010']:.5f}"])

# decade rates + classification
with open(os.path.join(OUT,"decade_rates_and_stall.csv"),"w",newline="") as f:
    wr=csv.writer(f)
    wr.writerow(["group","r_1960_80","r_1980_2000","r_2000_10","r_2010_23",
                 "avg_1960_2010","frac_recent_of_avg","band_b","spread_R1R4",
                 "backtest_e","above_law_2023","classification"])
    for g in range(1,4):
        c=CLS[GROUPS[g]]; r=c["rates"]
        wr.writerow([GROUPS[g],f"{r['1960-80']:.5f}",f"{r['1980-2000']:.5f}",
            f"{r['2000-10']:.5f}",f"{r['2010-23']:.5f}",f"{r['avg_1960-2010']:.5f}",
            f"{c['frac_of_avg']:.3f}",f"{c['band_b']:.5f}",f"{c['spread_R1R4']:.5f}",
            f"{c['backtest_e']:.5f}",f"{c['above_law_2023']:+.5f}",c["classification"]])

# tauW/tauH split
with open(os.path.join(OUT,"tauWtauH_split_2010_2023.csv"),"w",newline="") as f:
    wr=csv.writer(f)
    wr.writerow(["spec","group","d_mean_ln_tau","d_tauH_part","d_tauW_part",
                 "shareH","shareW"])
    for spec,S in SPLIT.items():
        for g in GROUPS[1:]:
            s=S[g]
            wr.writerow([spec,g,f"{s['total']:.5f}",f"{s['dH']:.5f}",f"{s['dW']:.5f}",
                         f"{s['shareH']:.3f}",f"{s['shareW']:.3f}"])

json.dump(dict(MEAN=MEAN,VAR=VAR,spread=spread,CLS=CLS,SPLIT=SPLIT,
               dates=DATES.tolist()),
          open(os.path.join(OUT,"theory_analysis.json"),"w"),indent=1,default=float)

# ---- console summary ----
print("="*78,"\nITEM 1: convergence law (mean ln tau), fit on 1960-2010, true midpoints")
print(f"{'grp':4} {'lambda':>8} {'halflife':>8} {'tau_inf':>8} {'obs2023':>8} {'pred2023':>8} {'OOSerr':>7} {'e_bktst':>7} {'band_b':>7}")
for g in GROUPS[1:]:
    m=MEAN[g]; hl=np.log(2)/m['lam']
    print(f"{g:4} {m['lam']:8.4f} {hl:8.1f} {np.exp(m['linf']):8.3f} {m['obs2023']:8.4f} {m['pred2023']:8.4f} {m['oos_err']:7.4f} {m['backtest_e']:7.4f} {CLS[g]['band_b']:7.4f}")
print("\nITEM 1: per-decade annualized decline in mean ln tau + classification")
for g in GROUPS[1:]:
    c=CLS[g];r=c["rates"]
    print(f"  {g}: 2010-23={r['2010-23']:+.5f}/yr  avg1960-2010={r['avg_1960-2010']:+.5f}/yr "
          f"(frac {c['frac_of_avg']:.2f})  above_law={c['above_law_2023']:+.4f} vs b={c['band_b']:.4f}  => {c['classification']}")
print("\nITEM 2: tauW/tauH split of 2010-23 mean-ln-tau change (primary)")
for g in GROUPS[1:]:
    s=SPLIT["primary"][g]
    print(f"  {g}: total={s['total']:+.4f}  tauH={s['dH']:+.4f}({s['shareH']*100:4.0f}%)  tauW={s['dW']:+.4f}({s['shareW']*100:4.0f}%)")
print("  R5:",{g:round(SPLIT['R5'][g]['shareH'],2) for g in GROUPS[1:]},"shareH")
print("  R8:",{g:round(SPLIT['R8'][g]['shareH'],2) for g in GROUPS[1:]},"shareH")
print("\nwrote convergence_law.csv, decade_rates_and_stall.csv, tauWtauH_split_2010_2023.csv, theory_analysis.json")
PY_DONE=1
print("done")
