global CaseName; CaseName='Benchmark';
global Noccs Ngroups Ncohorts Nyears GroupNames CohortConcordance TauW_Orig pData HAllData Decades ExperienceCohortFactor
global TauW_C phi_C mgtilde_C w_C WhatToChain earningsweights_avg ConstrainTauH
global q ShortNames GeoArith_adjust mgEstimated
load('TalentData_Benchmark');
if exist('NumHomeDraws')~=1; NumHomeDraws=[]; end;
args={TauH,TauW,Z,TExperience,A,phi,q,wH_T,gam,GammaBase,beta,eta,theta,dlta,mu,sigma,Tbar};

% (i) t0=t1=6 : counterfactual == baseline, zero contribution (check levels)
[gs66,Y66,YB,p66]=how_much_poorer('TauWTauH',args{:},0,0,6,6);
lev_relerr = max(abs(Y66(6,1:8)./YB(6,1:8)-1));
fprintf('GATE2Bi t0=t1=6 max_rel_level_err(cols1-8)=%.3e\n', lev_relerr);

% (iii) nesting: gen(t0=1,t1=5) vs original-edited-to-5
[g15,~,~,~]=how_much_poorer('TauWTauH',args{:},0,0,1,5);
[o5,~,~,~] =how_much_poorer_orig5('TauWTauH',args{:},0,0);
fprintf('GATE2Biii gen(1,5)  share: %s\n', sprintf('%.4f ',g15));
fprintf('GATE2Biii orig5     share: %s\n', sprintf('%.4f ',o5));
fprintf('GATE2Biii max_abs_share_diff=%.3e\n', max(abs(g15-o5)));
save('gate2b_vals.mat','gs66','lev_relerr','g15','o5');
