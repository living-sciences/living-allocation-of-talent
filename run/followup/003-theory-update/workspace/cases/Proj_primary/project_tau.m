% project_tau.m -- Study 002/003 item 3: remaining-gains projection.
% Takes 001's 2023 equilibrium (A, phi, Z, q, TExperience held at 2023) and pushes the
% period-7 (2023) composite friction for WW/BM/BW toward the fitted-law floor, realised as a
% parallel shift of -ln(1-TauW) in period 7 (shifts the earnings-wtd mean ln tauhat by delta_g).
% Only period 7 changes; periods 1-6 are untouched. One SolveForEqm call per invocation.
% Set before call: global CaseName PROJLABEL dWW dBM dBW
clear; global CaseName PROJLABEL dWW dBM dBW
% --- union of globals used by SolveEqmBasic / SolveForEqm / solveeqm / e_solveeqm ---
global Noccs Ngroups Ncohorts Nyears CohortConcordance TauW_Orig pData HAllData q ShortNames
global TauW_C phi_C mgtilde_C w_C GeoArith_adjust mgEstimated StopHere pModel
global Decades GroupNames earningsweights_avg ConstrainTauH WhatToChain ExperienceCohortFactor
load(['TalentData_' CaseName]);          % populates the globals above + eta,TauH_T,TauW,etc.
Mkt=2:Noccs;
S=load(['SolveEqmBasic_' CaseName '.mat']);   % 001's 2023 baseline equilibrium

delta=zeros(1,Ngroups); delta(WW)=dWW; delta(BM)=dBM; delta(BW)=dBW;
TauW_proj=TauW;
for g=1:Ngroups;
  if delta(g)~=0;
     TauW_proj(:,g,Nyears)=1-(1-TauW(:,g,Nyears)).*exp(-delta(g));
  end;
end;

% validate realised composite-mean shift == target delta (young-cohort composite)
ew=earningsweights_avg(Mkt); ew=ew/nansum(ew);
fprintf('\n--- %s: realised vs target mean-ln-tauhat shift (period 7) ---\n',PROJLABEL);
for g=[WW BM BW];
  oldc=eta*log(1+TauH_T(Mkt,g,Nyears))-log(1-TauW(Mkt,g,Nyears));
  newc=eta*log(1+TauH_T(Mkt,g,Nyears))-log(1-TauW_proj(Mkt,g,Nyears));
  fprintf('  g=%d target=%+.5f realised=%+.5f\n',g,delta(g),nansum((newc-oldc).*ew));
end;

[YModel,YMkt,Earn,Ywkr,LFP,CY,EY,GDPY,WG,Eg,U]=SolveForEqm(TauH,TauW_proj,Z,TExperience,A,phi,q,wH_T,gam,GammaBase,beta,eta,theta,dlta,mu,sigma,Tbar);
t=Nyears;
Ybase=S.GDPBaseline(t); Ymktbase=S.GDPMktBaseline(t); GDPYbase=S.GDPYoungBaseline(t); LFPbase=S.LFPBaseline(t);
gY=100*(YModel(t)/Ybase-1); gYmkt=100*(YMkt(t)/Ymktbase-1); gYoung=100*(GDPY(t)/GDPYbase-1);
fprintf('\n=== PROJECTION %s (2023 equilibrium, A/phi/Z/q fixed) ===\n',PROJLABEL);
fprintf('Y       base=%10.1f proj=%10.1f  gain=%+7.3f%%\n',Ybase,YModel(t),gY);
fprintf('Ymkt    base=%10.1f proj=%10.1f  gain=%+7.3f%%\n',Ymktbase,YMkt(t),gYmkt);
fprintf('GDPYoung base=%9.1f proj=%10.1f  gain=%+7.3f%%\n',GDPYbase,GDPY(t),gYoung);
fprintf('LFP     base=%10.4f proj=%10.4f\n',LFPbase,LFP(t));
R=struct('label',PROJLABEL,'Ybase',Ybase,'Yproj',YModel(t),'Ymktbase',Ymktbase,...
   'Ymktproj',YMkt(t),'GDPYbase',GDPYbase,'GDPYproj',GDPY(t),'LFPbase',LFPbase,...
   'LFPproj',LFP(t),'gain_Y',gY,'gain_Ymkt',gYmkt,'gain_GDPYoung',gYoung,...
   'dWW',dWW,'dBM',dBM,'dBW',dBW);
save(['Proj_' PROJLABEL '_' CaseName '.mat'],'R','YModel','YMkt','GDPY','LFP','delta');
fprintf('saved Proj_%s_%s.mat\n',PROJLABEL,CaseName);
