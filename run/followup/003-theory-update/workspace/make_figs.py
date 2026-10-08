import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt, numpy as np, json, os
OUT="/workspace/eval/followup/003-theory-update/results"
OK=["#0072B2","#E69F00","#009E73","#D55E00","#CC79A7","#56B4E9","#F0E442","#000000"]
plt.rcParams.update({"figure.dpi":150,"savefig.dpi":150,"savefig.bbox":"tight",
  "font.size":12,"axes.titlesize":13,"axes.labelsize":12,
  "axes.spines.top":False,"axes.spines.right":False,"axes.grid":True,"grid.alpha":0.25})
A=json.load(open(f"{OUT}/theory_analysis.json"))
import scipy.io as sio
ml=sio.loadmat("/workspace/eval/followup/001-living-update/workspace/cases/Living/TalentData_Benchmark.mat")["meanlogtau"]
DATES=np.array([1960,1970,1980,1990,2000,2011,2023.0])
groups=["WW","BM","BW"]; gi={"WW":1,"BM":2,"BW":3}
col={"WW":OK[0],"BM":OK[2],"BW":OK[4]}
def claw(t,linf,lam,y0): return linf+(y0-linf)*np.exp(-lam*(t-1960.0))

# ---------- FIG 1: convergence law + OOS 2023 + projection ----------
fig,ax=plt.subplots(figsize=(8.2,5.0))
tt=np.linspace(1960,2043,400)
for g in groups:
    m=A["MEAN"][g]; y=ml[:,gi[g]]; c=col[g]; y0=m["y0"]
    # observed 1960-2010 (fit sample)
    ax.plot(DATES[:6],y[:6],'o',color=c,ms=6,zorder=5)
    # fitted law (fit on 1960-2010) extrapolated
    ax.plot(tt,claw(tt,m["linf"],m["lam"],y0),'-',color=c,lw=2,
            label=f"{g}: law λ={m['lam']:.3f}, τ∞={np.exp(m['linf']):.2f}")
    # 2023 out-of-sample observed point (diamond) + band
    b=A["CLS"][g]["band_b"]
    ax.errorbar([2023],[m["obs2023"]],yerr=[b],fmt='D',color=c,ms=9,capsize=5,
                mec='black',mew=0.8,zorder=6)
    # floor line
    ax.axhline(m["linf"],color=c,ls=':',lw=1,alpha=0.5)
ax.axvspan(2023,2043,color='gray',alpha=0.06)
ax.text(2033,ax.get_ylim()[1]*0.96,"projection\nregion",ha='center',va='top',fontsize=9,color='gray')
ax.set_xlabel("year (true pool midpoint)")
ax.set_ylabel("earnings-weighted mean  ln τ̂  (composite friction)")
ax.set_title("Friction convergence law: fit 1960–2010, 2023 out-of-sample (◆ = observed, bar = band b)")
ax.legend(loc='upper right',fontsize=9,framealpha=0.9)
ax.annotate("solid = fitted law extrapolated; dotted = fitted floor τ∞;\n"
            "2023 diamonds sit within the law's own band → no stall",
            xy=(0.015,0.02),xycoords='axes fraction',fontsize=8.5,color='#333')
fig.savefig(f"{OUT}/fig1_convergence_law.png",facecolor="white"); plt.close(fig)

# ---------- FIG 2: tauW/tauH split (left) + projected gains (right) ----------
fig,(axL,axR)=plt.subplots(1,2,figsize=(8.8,4.3))
# left: share of 2010-23 mean-ln-tau DECLINE attributed to tauH vs tauW (primary)
S=A["SPLIT"]["primary"]
x=np.arange(3); wbar=0.6
dH=[-S[g]["dH"] for g in groups]  # magnitude of decline (positive)
dW=[-S[g]["dW"] for g in groups]
axL.bar(x,dH,wbar,label="τʰ (pre-market / human-capital)",color=OK[1])
axL.bar(x,dW,wbar,bottom=dH,label="τʷ (labour-market wedge)",color=OK[0])
axL.axhline(0,color='k',lw=0.8)
axL.set_xticks(x); axL.set_xticklabels(groups)
axL.set_ylabel("decline in mean ln τ̂, 2010→2023")
axL.set_title("Post-2010 friction decline is τʰ-dominated")
axL.legend(fontsize=9,loc='upper right')
for i,g in enumerate(groups):
    sh=S[g]["shareH"]*100
    axL.annotate(f"τʰ {sh:.0f}%",(i,max(dH[i],0)+0.004),ha='center',fontsize=8.5)

# right: projected additional Ymkt gain vs historical per-decade contribution
P=json.load(open(f"{OUT}/projection_results.json"))
prim={r["horizon"]:r["gain_Ymkt_pct"] for r in P if r["spec"]=="primary"}
labels=["1960–2010\n(historical\nper decade)","2023→2033","2023→2043","2023→τ∞"]
# historical per-decade LEVEL contribution of falling tau ≈ 0.69%/yr * 10 = 6.9%/decade
vals=[6.9, prim["2033"], prim["2043"], prim["tau->tau_inf"]]
colors=[OK[7],OK[1],OK[1],OK[3]]
bars=axR.bar(range(4),vals,color=colors,width=0.62)
axR.set_ylabel("falling-τ contribution to mkt GDP/person (%)")
axR.set_title("Friction 'dividend': historical vs projected [PROJECTED]")
axR.set_xticks(range(4)); axR.set_xticklabels(labels,fontsize=9)
for b,v in zip(bars,vals):
    axR.annotate(f"{v:.2f}%",(b.get_x()+b.get_width()/2,v),ha='center',
                 va='bottom',fontsize=9)
axR.annotate("projected numbers conditional on the fitted law\nwith A, φ, z̃, q held at 2023 — not a growth forecast",
             xy=(0.02,0.80),xycoords='axes fraction',fontsize=8,color='#555')
fig.tight_layout()
fig.savefig(f"{OUT}/fig2_split_and_projection.png",facecolor="white"); plt.close(fig)
print("wrote fig1_convergence_law.png, fig2_split_and_projection.png")
