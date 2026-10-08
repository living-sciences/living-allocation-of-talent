addpath([pwd '/shims']);
global CaseName; CaseName='Benchmark';
global Noccs Ngroups Ncohorts Nyears GroupNames CohortConcordance TauW_Orig pData HAllData Decades ExperienceCohortFactor
global TauW_C phi_C mgtilde_C w_C WhatToChain earningsweights_avg ConstrainTauH
global q ShortNames GeoArith_adjust mgEstimated
load(['TalentData_' CaseName]);
if exist('NumHomeDraws')~=1; NumHomeDraws=[]; end;
args={TauH,TauW,Z,TExperience,A,phi,q,wH_T,gam,GammaBase,beta,eta,theta,dlta,mu,sigma,Tbar};
fprintf('Nyears=%d Decades=',Nyears); disp(Decades');
how_much_poorer_dump('Both+Z',args{:},0,0,2,6);   % t0=1970 (assignment table spec)
how_much_poorer_dump('Both+Z',args{:},0,0,6,7);   % t0=2010 (L4 incumbent path)
disp('DUMP_DONE');
