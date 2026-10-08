% HowMuchPoorer_gen.m -- generalized stage-split driver for how_much_poorer(t0,t1).
% Runs ONE chunk (<=3 SolveForEqm calls) of the hold-tau-at-t0 counterfactual in a fresh
% process. Set before calling:
%   global CaseName HMPChunk HMP_t0 HMP_t1; CaseName='Living'; HMPChunk=k; HMP_t0=..; HMP_t1=..;
% Chunks: 1 = TauWTauH/TauH/TauW (all groups, GroupToChange=0)
%         2 = Both+Z/MeansOnly/DispersionOnly (all groups)
%         3/4/5 = TauWTauH/TauH/TauW for WW/BM/BW
clear; global CaseName HMPChunk HMP_t0 HMP_t1;
k=HMPChunk; t0=HMP_t0; t1=HMP_t1;
diarychad(['HowMuchPoorer_gen_t' num2str(t0) '_' num2str(t1) '_c' num2str(k)],CaseName);
global Noccs Ngroups Ncohorts Nyears GroupNames CohortConcordance TauW_Orig pData HAllData Decades ExperienceCohortFactor
global TauW_C phi_C mgtilde_C w_C WhatToChain earningsweights_avg ConstrainTauH
global q ShortNames GeoArith_adjust mgEstimated
load(['TalentData_' CaseName]);
if exist('NumHomeDraws')~=1; NumHomeDraws=[]; end;
STB=0;
args={TauH,TauW,Z,TExperience,A,phi,q,wH_T,gam,GammaBase,beta,eta,theta,dlta,mu,sigma,Tbar};
fprintf('\n=== HowMuchPoorer_gen chunk %d, t0=%d (%d), t1=%d (%d) ===\n',k,t0,Decades(t0),t1,Decades(t1));
if k==1;
    ShowParameters;
    how_much_poorer('TauWTauH',args{:},0,STB,t0,t1);
    how_much_poorer('TauH',    args{:},0,STB,t0,t1);
    how_much_poorer('TauW',    args{:},0,STB,t0,t1);
elseif k==2;
    how_much_poorer('Both+Z',        args{:},0,STB,t0,t1);
    how_much_poorer('MeansOnly',     args{:},0,STB,t0,t1);
    how_much_poorer('DispersionOnly',args{:},0,STB,t0,t1);
else;
    G=[WW BM BW]; g=G(k-2);
    how_much_poorer('TauWTauH',args{:},g,STB,t0,t1);
    how_much_poorer('TauH',    args{:},g,STB,t0,t1);
    how_much_poorer('TauW',    args{:},g,STB,t0,t1);
end;
clear args;
save(['HowMuchPoorer_gen_t' num2str(t0) '_' num2str(t1) '_c' num2str(k) '_' CaseName '.mat']);
diary off;
