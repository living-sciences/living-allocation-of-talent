% HowMuchPoorer_chunk.m -- stage-split driver for HowMuchPoorer.m (living-update A1).
% Runs ONE chunk of HowMuchPoorer's how_much_poorer() calls in a fresh Octave process.
% Each how_much_poorer call is independent: it reloads SolveEqmBasic_<Case>.mat and
% SolveForEqm re-initialises its history globals (TauW_C, phi_C, mgtilde_C, w_C) on entry.
% Set before calling:  global CaseName HMPChunk; CaseName='Benchmark'; HMPChunk=k;  (k=1..5)
%   1: TauWTauH, TauH, TauW            (all groups)
%   2: Both+Z, MeansOnly, DispersionOnly (all groups)
%   3/4/5: TauWTauH, TauH, TauW for WW / BM / BW   (Benchmark only, as in HowMuchPoorer.m)
clear; global CaseName HMPChunk;
diarychad(['HowMuchPoorer_c' num2str(HMPChunk)],CaseName);
global Noccs Ngroups Ncohorts Nyears GroupNames CohortConcordance TauW_Orig pData HAllData Decades ExperienceCohortFactor
global TauW_C phi_C mgtilde_C w_C WhatToChain earningsweights_avg ConstrainTauH
% In the one-process pipeline these were left declared global by SolveEqmBasic.m (its l.17-18);
% a fresh process must re-declare them BEFORE the load, or SolveForEqm sees mgEstimated=[].
global q ShortNames GeoArith_adjust mgEstimated
load(['TalentData_' CaseName]);
if exist('NumHomeDraws')~=1; NumHomeDraws=[]; end;
ShowTimeBreakdown=isequal(CaseName,'Benchmark');
args={TauH,TauW,Z,TExperience,A,phi,q,wH_T,gam,GammaBase,beta,eta,theta,dlta,mu,sigma,Tbar};
k=HMPChunk;
if k==1;
    ShowParameters;
    [growthshareTWTH,Y_TWTH,YBaseline,pModel_TWTH]=how_much_poorer('TauWTauH',args{:},0,ShowTimeBreakdown);
    if ~ChainSingleCase;
        how_much_poorer('TauH',args{:},0,ShowTimeBreakdown);
        how_much_poorer('TauW',args{:},0,ShowTimeBreakdown);
    end;
elseif k==2;
    if ~ChainSingleCase;
        how_much_poorer('Both+Z',args{:},0,ShowTimeBreakdown);
        how_much_poorer('MeansOnly',args{:},0,ShowTimeBreakdown);
        how_much_poorer('DispersionOnly',args{:},0,ShowTimeBreakdown);
    end;
else;
    if isequal(CaseName,'Benchmark');
        G=[WW BM BW]; g=G(k-2);
        for w={'TauWTauH','TauH','TauW'};
            how_much_poorer(w{1},args{:},g,0);
        end;
    end;
end;
clear args;
save(['HowMuchPoorer_' CaseName '_c' num2str(k) '.mat']);
diary off;
