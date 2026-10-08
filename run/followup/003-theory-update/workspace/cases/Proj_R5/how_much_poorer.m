function [growthshares,Y_alt,YBaseline,pModel_alt]=how_much_poorer(WhatUnchanged,TauH,TauW,Z,TExperience,A,phi,q,wH_T,gam,GammaBase,beta,eta,theta,dlta,mu,sigma,Tbar,GroupToChange,ShowTimeBreakdown,t0,t1);
%
% Living-update generalization of how_much_poorer with a BASE period t0 and END period t1.
%  "Relative to Decades(t1), how much poorer would we be if <WhatUnchanged> had been held
%   at its Decades(t0) values?"
%  Defaults t0=1, t1=Nyears reproduce the paper's hold-at-1960, evaluate-at-last-period.
%
%  WhatUnchanged={'TauWTauH','TauW','TauH','Both+Z','MeansOnly','DispersionOnly'}.
%  GroupToChange={WW,BM,BW index} restricts the change to that group.
%
%  INCUMBENT RULE (spec A.4): tauW for PERIODS > t0 is set to the period-t0 value; tauH and z
%  for every cohort YOUNG AFTER t0 (cohorts 1..Nyears-t0) are set to the t0-young cohort's
%  values; cohorts already in the market at t0 (cohorts >= Nyears+1-t0) KEEP THEIR OWN
%  estimates (their pre-t0 history is data). At t0=1 this nests the paper exactly because the
%  pre-1960 incumbent cohorts have left the 25-54 market by any sampled end period.

global Nyears Noccs Ncohorts Ngroups Decades GroupNames ExperienceCohortFactor HAllData CaseName WhatToChain earningsweights_avg ConstrainTauH

if ~exist('GroupToChange'); GroupToChange=0; end;
if isempty(GroupToChange); GroupToChange=0; end;
if ~exist('ShowTimeBreakdown'); ShowTimeBreakdown=0; end;
if ~exist('t0')||isempty(t0); t0=1; end;
if ~exist('t1')||isempty(t1); t1=Nyears; end;
GetMeans=0;
if isequal(WhatUnchanged,'TauW');         ChangeTauH=0; ChangeTauW=1; ChangeZ=0; end;
if isequal(WhatUnchanged,'TauH');         ChangeTauH=1; ChangeTauW=0; ChangeZ=0; end;
if isequal(WhatUnchanged,'TauWTauH');     ChangeTauH=1; ChangeTauW=1; ChangeZ=0; end;
if isequal(WhatUnchanged,'Both+Z');       ChangeTauH=1; ChangeTauW=1; ChangeZ=1; end;
if isequal(WhatUnchanged,'NoChange');     ChangeTauH=0; ChangeTauW=0; ChangeZ=0; end;
if isequal(WhatUnchanged,'MeansOnly');      ChangeTauH=0; ChangeTauW=0; ChangeZ=0; GetMeans=1; end;
if isequal(WhatUnchanged,'DispersionOnly'); ChangeTauH=0; ChangeTauW=0; ChangeZ=0; GetMeans=1; end;
Mkt=2:Noccs;

t0young=Nyears+1-t0;   % cohort young in period t0 (= paper's Cohort1960 when t0=1)

disp ' '; disp ' ';
disp '========================================================================';
if GroupToChange==0;
    disp ([' How much poorer in ' num2str(Decades(t1)) ' with ' num2str(Decades(t0)) ' values of ' WhatUnchanged]);
else;
    disp ([' How much poorer in ' num2str(Decades(t1)) ' with ' num2str(Decades(t0)) ' values of ' WhatUnchanged ', for ' GroupNames{GroupToChange}]);
end;
disp '========================================================================';

% BASELINE
load(['SolveEqmBasic_' CaseName]);
pBaseline=pModel;
WageGapBaseline=WageGapBaseline';
WageGapBaseline(:,1)=[];
YBaseline=[GDPBaseline GDPMktBaseline GDPwkrBaseline LFPBaseline EarningsBaseline ConsumpYoungBaseline EarningsYoungBaseline GDPYoungBaseline WageGapBaseline EarningsBaseline_g' UtilityBaseline];
chaintle={'GDP per person','GDP (mkt) per person','GDP (mkt) per worker','Labor Force Participation (LFP)','Earnings (market)','ConsumpYoung (market)','EarningsYoung (market)','GDPYoung (market)','WageGapWW','WageGapBM','WageGapBW','EarningsWM','EarningsWW','EarningsBM','EarningsBW','Utility: CE-Welfare of Young'};

% Means (for MeansOnly / DispersionOnly). Reference period/cohort is t0.
if GetMeans;
    lnTauWmeans=zeros(size(TauW));
    lnTauHmeans=zeros(size(TauH));
    for g=1:Ngroups;
        lnTWmean_g=nansum(mult(squeeze(log((1-TauW(Mkt,g,:)))),earningsweights_avg(Mkt)));
        lnTHmean_g=nansum(mult(squeeze(log(1+TauH(Mkt,g,:))),earningsweights_avg(Mkt)));
        lnTauWmeans(Mkt,g,:)=kron(lnTWmean_g,ones(Noccs-1,1));
        lnTauHmeans(Mkt,g,:)=kron(lnTHmean_g,ones(Noccs-1,1));
    end;
    % Fix the pre-sample incumbent cohorts (Nyears+1..Ncohorts) to the oldest sampled-young
    % cohort's mean, generalizing the original's lnTauHmeans(:,:,7:8)=...(:,:,6).
    for c=(Nyears+1):Ncohorts;
        lnTauHmeans(:,:,c)=lnTauHmeans(:,:,Nyears);
    end;
end;

% Reference (t0) sources, broadcast
Z_src   = Z(:,:,t0young);     % Noccs x Ngroups
TauH_src= TauH(:,:,t0young);
TauW_src= TauW(:,:,t0);       % Noccs x Ngroups (period-t0 wedge)

% Start the counterfactual at the ACTUAL values, then overwrite per the incumbent rule
TauW_alt=TauW; TauH_alt=TauH; Z_alt=Z;

% tauW: periods strictly after t0 held at the period-t0 value
if ChangeTauW;
    for p=(t0+1):Nyears;
        if GroupToChange==0;
            TauW_alt(:,:,p)=TauW_src;
        else;
            TauW_alt(:,GroupToChange,p)=TauW_src(:,GroupToChange);
        end;
    end;
end;
% tauH/z: cohorts young strictly after t0 (cohorts 1..Nyears-t0) held at t0-young values
if ChangeTauH;
    for c=1:(Nyears-t0);
        if GroupToChange==0; TauH_alt(:,:,c)=TauH_src;
        else; TauH_alt(:,GroupToChange,c)=TauH_src(:,GroupToChange); end;
    end;
end;
if ChangeZ;
    for c=1:(Nyears-t0);
        if GroupToChange==0; Z_alt(:,:,c)=Z_src;
        else; Z_alt(:,GroupToChange,c)=Z_src(:,GroupToChange); end;
    end;
end;

% DispersionOnly: hold t0 dispersion, let means evolve (periods/cohorts after t0 only)
if isequal(WhatUnchanged,'DispersionOnly');
    gg = (GroupToChange==0) * 0;  % placeholder
    for t=(t0+1):Nyears;
        ct=Nyears+1-t;
        if GroupToChange==0;
            TW=log(1-TauW(:,:,t0))-lnTauWmeans(:,:,t0) + lnTauWmeans(:,:,t);
            TH=log(1+TauH(:,:,t0young))-lnTauHmeans(:,:,t0young) + lnTauHmeans(:,:,ct);
            TauW_alt(:,:,t)=1-exp(TW);
            TauH_alt(:,:,ct)=exp(TH)-1;
        else;
            TW=log(1-TauW(:,GroupToChange,t0))-lnTauWmeans(:,GroupToChange,t0) + lnTauWmeans(:,GroupToChange,t);
            TH=log(1+TauH(:,GroupToChange,t0young))-lnTauHmeans(:,GroupToChange,t0young) + lnTauHmeans(:,GroupToChange,ct);
            TauW_alt(:,GroupToChange,t)=1-exp(TW);
            TauH_alt(:,GroupToChange,ct)=exp(TH)-1;
        end;
    end;
    TauH_alt(TauH_alt<ConstrainTauH)=ConstrainTauH;
    TauW_alt(TauW_alt>0.99)=0.99;
end;

% MeansOnly: hold t0 means, let dispersion evolve (periods/cohorts after t0 only)
if isequal(WhatUnchanged,'MeansOnly');
    for t=(t0+1):Nyears;
        ct=Nyears+1-t;
        if GroupToChange==0;
            TW=log(1-TauW(:,:,t))-lnTauWmeans(:,:,t) + lnTauWmeans(:,:,t0);
            TH=log(1+TauH(:,:,ct))-lnTauHmeans(:,:,ct) + lnTauHmeans(:,:,t0young);
            TauW_alt(:,:,t)=1-exp(TW);
            TauH_alt(:,:,ct)=exp(TH)-1;
        else;
            TW=log(1-TauW(:,GroupToChange,t))-lnTauWmeans(:,GroupToChange,t) + lnTauWmeans(:,GroupToChange,t0);
            TH=log(1+TauH(:,GroupToChange,ct))-lnTauHmeans(:,GroupToChange,ct) + lnTauHmeans(:,GroupToChange,t0young);
            TauW_alt(:,GroupToChange,t)=1-exp(TW);
            TauH_alt(:,GroupToChange,ct)=exp(TH)-1;
        end;
    end;
    TauH_alt(TauH_alt<ConstrainTauH)=ConstrainTauH;
    TauW_alt(TauW_alt>0.99)=0.99;
end;

t=t1;
[y_output,y_mkt,y_earnings,y_wkr,lfp,consumpmkt,earningsyoung,gdpyoung,wagegap,earnings_g,utility,wModel,HModel,HModelAll,pModel]...
    =SolveForEqm(TauH_alt,TauW_alt,Z_alt,TExperience,A,phi,q,wH_T,gam,GammaBase,beta,eta,theta,dlta,mu,sigma,Tbar);
Yinit=[y_output(t) y_mkt(t) y_wkr(t) lfp(t) y_earnings(t) consumpmkt(t) earningsyoung(t) gdpyoung(t) wagegap(2:4,t)' earnings_g(:,t)' utility(t)];

gIactual=log(YBaseline(t1,:)./YBaseline(t0,:))/(Decades(t1)-Decades(t0));
gImodel =log(Yinit./YBaseline(t0,:))/(Decades(t1)-Decades(t0));
gIshare = (1-gImodel./gIactual)*100;
rowtle=[sprintf('%4d(base)',Decades(t0)); sprintf('%4d(alt) ',Decades(t1)); sprintf('%4d(tru) ',Decades(t1))];
fmt='%8.0f %8.0f %8.0f %8.3f %8.0f %8.0f %8.0f %8.0f %8.3f %8.3f %8.3f %8.0f %8.0f %8.0f %8.0f %8.0f';

cshow(rowtle,[YBaseline(t0,:); Yinit; YBaseline(t1,:)],fmt,'Y Ymkt Ywkr LFP Earn Cons EarnY gdpY GapWW GapBM GapBW EarnWM EarnWW EarnBM EarnBW Util');
cshow('Growth(alt)',gImodel,'%8.4f',[],'nonee',1);
cshow('Growth(tru)',gIactual,'%8.4f',[],'nonee',1);
cshow('Difference ',gIactual-gImodel,'%8.4f',[],'nonee',1);
cshow('// Share //',gIshare,'%8.1f',[],'nonee',1);
disp ' '; disp ' ';

growthshares=gIshare;
pModel_alt=pModel;
Y_alt = [y_output y_mkt y_wkr lfp y_earnings consumpmkt earningsyoung gdpyoung wagegap(2:4,:)' earnings_g'];

end
