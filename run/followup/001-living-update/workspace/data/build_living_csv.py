"""Build the 7-period living CSV: old 1960-2010 rows (cohort +1) + new pooled 2022-2024 '2023'
period (spec A.2/A.3). Primary race = W* (bridged white). Writes chad_output_file_living*.csv."""
import sys, pathlib, numpy as np, pandas as pd
import build_pums_route as bpr, doport
HERE=pathlib.Path(__file__).resolve().parent
ROOT=HERE.parents[1]
CW=ROOT/"workspace/crosswalks"
CODE=ROOT/"workspace/codebase_living"
OUT=ROOT/"results"

PCE={2010:90.514,2011:92.6,2012:94.534,2022:116.038,2023:120.505,2024:123.662}
COH={0:"all",1:(25,34),2:(35,44),3:(45,54)}

# occ 2018 -> hhjk via modal==1
cw=pd.read_csv(CW/"occ2018_to_hhjk.csv")
modal=cw[cw["modal"]==1]
OCC2018={int(o):int(c) for o,c in zip(modal.occ2018,modal.occ_code)}
# SPLIT variant (robustness R4): split_share allocation top pick is same as modal here; keep modal for primary.

def build_new_period(race_rule, year_list=(2022,2023,2024), wscale=3):
    out,diag,pdf = bpr.build_period(list(year_list), PCE, 2023, 1471, "deflated_earnings",
                                    OCC2018, race_rule, wscale, 2023, COH,
                                    apply_adjinc=True, apply_pce=True)
    return out,diag,pdf

def assemble(new_rows, label):
    old=pd.read_csv(CODE/"chad_output_file_2019_01_24.csv")
    old=old.copy()
    # cohort +1 for c>=1 (0 stays all-ages)
    old.loc[old["cohort"]>=1,"cohort"]=old.loc[old["cohort"]>=1,"cohort"]+1
    # new rows: already year=2023, cohorts 0..3
    both=pd.concat([old,new_rows],ignore_index=True)
    p=OUT/f"chad_output_file_{label}.csv"
    both.to_csv(p,index=False)
    return p,old,both

if __name__=="__main__":
    import json
    races={"Wstar":"primary","W_NH":"R1","W_lit":"R2"}
    diags={}
    for rr in races:
        out,diag,pdf=build_new_period(rr)
        diags[rr]=diag
        if rr=="Wstar":
            p,old,both=assemble(out,"living")
            print("wrote",p,"old rows",len(old),"new rows",len(out),"total",len(both))
        else:
            out.to_csv(OUT/f"new2023_{rr}.csv",index=False)
            print("wrote new2023 for",rr,len(out),"rows; unmapped_wt",round(diag['unmapped_worker_weight_share'],5))
    # group population shares q and Hispanic share of W under each race def (gate 5)
    json.dump({k:{"unmapped_worker_weight_share":v["unmapped_worker_weight_share"],
                  "n_persons":v["n_persons"],"total_weight":v["total_weight"]} for k,v in diags.items()},
              open(OUT/"build_living_diag.json","w"),indent=2,default=str)
    print("diag unmapped (Wstar):",round(diags["Wstar"]["unmapped_worker_weight_share"],5))
