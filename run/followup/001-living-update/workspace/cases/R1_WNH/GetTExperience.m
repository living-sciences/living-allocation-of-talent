% GetTExperience.m
%
%  Called from EstimateTauZ.m to compute TExperience
%  (a block of code, rather than a function).
%
%  Note: Uses WM and requires estimates of phi(i,t) and w(i,t).
%
% TigYMO -- WM experience terms from WM wages.  Occupation-cohort-age specific 
%   Replacing what Erik had done.
%
% For HOME: Use average across all occs
%
% Estimate occupation-cohort-age specific TExperience terms from male's wage
% Note that TExperience for the young = 1 for every occupations
%
%  4/18/16 -- Lifecycle Tbar 
% 12/12/17 -- Allows hetergeneity in Tbar by occ (SameExperience=0) <-- No! need to recalculate tauhat???


if SameExperience~=1;
    disp 'GetTExperience.m has not been updated for heterogeneous experience. Stopping.';
    disp '(Though we do allow some flexibility for NoBrawny and NoFrictions2010)';
    keyboard;
end;


WageSeries=Earnings; % Use for computing return to experience, not WageBar

% Calculate tauhat -- Relative to WM Note: All tauh and tauw will be
% *relative to WM* for the bulk of the program. We'll only undo this at
% the end (legacy of the fact that we initially set tauWM=1) -- Because
% we estimate wHome and Thome to fix WM LFP at a given value in all
% occs, the solution of the model depends only on relative taus! (in the
% estimation, not in the equilibrium)
%   -- omits TbarHat term for now, fixed below with tauhat_y:
tauhat=That.^(1-eta).*relp.^(-(1-dlta)/theta) .* wagegap.^(-(1-eta));
tauhat(isinf(tauhat))=NaN; % Code to handle missing data
clear tauhat_y; 

% Only makes sense for the young cohorts
% and need to multiply by TbarHat term (GxT, common across occupations)
for t=1:Nyears;
    ct=(Nyears+1-t);
    tauhat_y(:,:,t)=squeeze(tauhat(:,:,ct,t)).*TbarHat(:,:,t).^eta;
end;
oldtauhat=tauhat;
tauhat=tauhat_y;  % Replace with the tauhat_y version: NxGxT
    

    % Fix missing values in a systematic way
    disp ' '; disp '===========================================================';
    disp 'GetTExperience.m:';
    disp 'Fixing tauhat_y missing values --> tauhat_y_cleaned (just for robustness cases)';
    disp ' -- Use first non-missing value';
    disp ' ';  disp '===========================================================';

    % tauhat_y
    tauhat_y_cleaned=tauhat_y;
    for g=2:Ngroups; disp ' ';
        disp '*********************';
        disp(GroupNames{g});
        disp '*********************'; disp ' ';
        for i=2:Noccs;
            % tauhat_y
            missingtauhat_y_cleaned=(isnan(squeeze(tauhat_y_cleaned(i,g,:))) | isinf(squeeze(tauhat_y_cleaned(i,g,:))));
            if all(missingtauhat_y_cleaned); 
                disp 'All tauhat_y_cleaned missing. Stopping...'; keyboard;
            elseif any(missingtauhat_y_cleaned);
                cshow(['tauhat_y_cleaned ' ShortNames{i}],squeeze(tauhat_y_cleaned(i,g,:))','%8.4f',[],'nonee',1);
                tauhat_y_cleaned(i,g,:)=fixmissing(squeeze(tauhat_y_cleaned(i,g,:)),missingtauhat_y_cleaned);
                cshow(['tauhat_y_cleaned ' ShortNames{i}],squeeze(tauhat_y_cleaned(i,g,:))','%8.4f',[],'nonee',1);
            end;
        end; % Occupations
    end; % Groups



Nymo=3; % Y=1,M=2,O=3 are the three indexes in the YMO structure
TigYMO=ones(Noccs,Nyears,Nymo); % For WM for Group, Year of Birth (i.e. cohort-like), and YMO age

% Weights for averaging -- aggregate earnings-weighted average of TigYMO -- Noccs x Nyears x Nymo
earningsweights=div(AggIncomeData_it,nansum(AggIncomeData_it,1));
earningsweights_avg=mean(earningsweights')';  % Noccs x 1


% Living-update generalization (Capabilities 2 & 3):
%  - The loop runs over cohorts young at periods t=1..(Nyears-1). A cohort young at t has
%    a MIDDLE observation iff t+1<=Nyears and an OLD observation iff t+2<=Nyears. The
%    youngest cohort (young at the last period, t=Nyears) is Y-only, so it is NOT iterated
%    here and its TigYMO row stays at the initialized value 1 (exactly as the original
%    t=1:5 loop left column 6 = ones). Within the loop, t==(Nyears-1) is the Y/M-only edge
%    (old unobserved): wagebar_o/pig_o/w_o/s_o/phi_o become NaN/0 just as the original
%    t==5 branch, reproducing the terminal old-column quirk (TigYMO(:,Nyears-1,3)->0 after
%    the SameExperience averaging).
%  - Capability 3 (experience-interval rescaling): if any Decades step length differs from
%    10 (e.g. the 2010->2023 12-year step) AND ExperienceUnscaled==0, the life-cycle
%    wage-growth factors are annualized and re-expressed over the model's 10-year step
%    before entering TigYMO. On the 6-period Benchmark every step is 10 years, so this
%    branch is NOT taken and the factors are byte-identical to the original.
if ~exist('ExperienceUnscaled'); ExperienceUnscaled=0; end;
% NB: do NOT use the builtin diff() here -- LookatCohortData leaves a 67x4 variable
% named 'diff' in the shared script workspace, which would shadow the function.
DecStep_ = Decades(2:end)-Decades(1:end-1);
% rescaleStep = TRUE midpoint spacing used for the experience annualization (spec A.4
% interval rule). Census->census steps keep their 10-year label. The paper's ~11-year
% 2000->2010 step is LEFT as the paper coded it (10). Only the final pooled step,
% labelled 2010->2023 (=13 by label because "2010" is really the 2010-12 pool), has
% TRUE midpoint spacing 12 (2011->2023): set it to 12 so the exponent is ^(10/12).
rescaleStep_ = DecStep_(:);
if Nyears>=7; rescaleStep_(Nyears-1) = 12; end;
ApplyExpRescale = (~ExperienceUnscaled) & any(rescaleStep_~=10);

for t=1:(Nyears-1);
    Cohort=(Nyears+1-t);
    HasMiddle=(t+1<=Nyears); % always true for t<=Nyears-1
    HasOld   =(t+2<=Nyears);
    wagebar_y=squeeze(WageSeries(:,WM,Cohort,t));
    wagebar_m=squeeze(WageSeries(:,WM,Cohort,t+1));
    if ~HasOld;
        wagebar_o=zeros(Noccs,1)*NaN;
    else;
        wagebar_o=squeeze(WageSeries(:,WM,Cohort,t+2));
    end;
    pig_y=squeeze(p(:,WM,Cohort,t));
    pig_m=squeeze(p(:,WM,Cohort,t+1));
    if ~HasOld;
        pig_o=zeros(Noccs,1)*NaN;
    else;
        pig_o=squeeze(p(:,WM,Cohort,t+2));
    end;
    w_m=w(:,t+1);
    w_y=w(:,t);
    if ~HasOld;
        w_o=zeros(Noccs,1);
    else;
        w_o=w(:,t+2);
    end;
    s_y=s(:,t);     s_m=s(:,t+1);
    phi_y=phi(:,t); phi_m=phi(:,t+1);
    if ~HasOld;
        s_o=zeros(Noccs,1);  phi_o=zeros(Noccs,1);
    else;
        s_o=s(:,t+2);     phi_o=phi(:,t+2);
    end;
    % Now use the life cycle of wage growth to recover the T(t-c)...
    if SameExperience==1;
        rawM=(wagebar_m./wagebar_y)./(w_m./w_y)./(s_y.^phi_m./s_y.^phi_y); % middle
        rawO=(wagebar_o./wagebar_y)./(w_o./w_y)./(s_y.^phi_o./s_y.^phi_y); % old
    else;
        % With heterogeneous experience, treat phi/s as constant over time
        rawM=(wagebar_m./wagebar_y)./(w_m./w_y); %./(s_y.^phi_m./s_y.^phi_y); % middle
        rawO=(wagebar_o./wagebar_y)./(w_o./w_y); %./(s_y.^phi_o./s_y.^phi_y); % old
    end;
    if ApplyExpRescale;
        % Annualize the step's growth factor and re-express it over the 10-year model step.
        %   Middle factor spans the single step t->t+1 (length Decades(t+1)-Decades(t)).
        %   Old factor spans two steps t->t+2; use the AVERAGE step length over that span.
        expM=10/rescaleStep_(t);
        if HasOld;
            expO=10/((rescaleStep_(t)+rescaleStep_(t+1))/2);
        else;
            expO=1; % old unobserved: factor feeds only deleted periods, leave raw
        end;
        TigYMO(:,t,2)=rawM.^expM;
        TigYMO(:,t,3)=rawO.^expO;
    else;
        % 6-period Benchmark path: exactly the original factors (no exponentiation).
        TigYMO(:,t,2)=rawM;
        TigYMO(:,t,3)=rawO;
    end;
 %disp 'GetTExp...'; keyboard
    % Fix if less than 1 or not weakly increasing
    TigYMO(TigYMO<1)=1;
    UseMiddle=(TigYMO(:,:,2)>TigYMO(:,:,3));
    blah=TigYMO(:,:,3); blahFix=TigYMO(:,:,2);
    blah(UseMiddle)=blahFix(UseMiddle);
    TigYMO(:,:,3)=blah;
        
    % Home = average of market
    TigYMO_avg=nansum(mult(squeeze(TigYMO(:,t,:)),earningsweights(:,t)));
    TigYMO(HOME,t,:)=TigYMO_avg;
    
    %At this point we have heterogeneity
end;

% SameExperience option: use same returns to experience in all occupations
%  -- Use the earnings-weighted average returns in each year.
% Otherwise, we already have TigYMO heterogeneous, so nothing to do there
if SameExperience==1;
    for t=1:Nyears;
        TigYMO_avg=nansum(mult(squeeze(TigYMO(:,t,:)),earningsweights(:,t)));
        TigYMO(:,t,:)=mult(ones(Noccs,3),TigYMO_avg);
    end;
end;


% ConstantExperience option: make the returns to experience constant over time
% i.e. the same in 1960, 1990, and 2010
if ConstantExperience==1;
    TigConstant=mean(TigYMO(:,1:4,:),2); % Average of times when we see all cohorts
    for t=1:Nyears;
        TigYMO(:,t,:)=TigConstant;
    end;
end;

disp ' ';
disp 'GetTExperience.m:'
disp '                     TigYMO for               --- 1960 ---      and    --- 1990 ---'
cshow(OccupationNames,[squeeze(TigYMO(:,1,:)) squeeze(TigYMO(:,4,:))],'%7.2f %7.2f %7.2f %12.2f %7.2f %7.2f');
disp ' ';
disp 'Values for occupation 8:';
squeeze(TigYMO(8,:,:))

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% T(i,g) = TExperience_y * TigYMO with GroupExpAdjustment
%    where
%       TExperience_y = 1 normally, or different for Brawny occs or NoFrictions2010
%         TigYMO      = Baseline experience adjustment from WM (cohort specific)
%    GroupExpAdjustment = Adjustment to experience for groups based on LFP (adjusts endogenously in counterfactuals)
%
%    Need to do all of this now, so we can compute tauhat *including* all terms in That
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TExperience_y:
%        True:  tauhat=That.^(1-eta).*relp.^(-(1-dlta)/theta) .* wagegap.^(-(1-eta)).*TbarHat^eta;
%
%     For NoBrawny and NoFrictions2010:
%        Let Tstar == That.^(1-eta).*TbarHat^eta -- Any change to TExperience gets inherited by both That and TbarHat
%        Want: tauhat=1 ==> Tstar= 1 / ( relp.^(-(1-dlta)/theta) .* wagegap.^(-(1-eta))  )
%                               = TstarOLD./tauhat
%                so TExperience_new = Tstar_old ./ tauhat
%        and recall TExperience(WM)=1.

TExperience_y=ones(size(tauhat_y));   % Noccs x Ngroups x Nyears
for t=1:Nyears;
    That_y(:,:,t)=That(:,:,(Nyears+1-t),t);
end;
TstarOLD=That_y.^(1-eta).*TbarHat.^eta;
if IgnoreBrawnyOccupations; % Then recover T(i,g) in those occs to yield tauhat=1
    % BrawnyOccupations (T/F) from Names67Occupations.m from Rendall
    % Assume no frictions for WW. Allow frictions for BW, but assume T(BW)=T(WW)
    TExperience_y(BrawnyOccupations,WW,:)=TstarOLD(BrawnyOccupations,WW,:)./tauhat_y_cleaned(BrawnyOccupations,WW,:);  % Only decide occupation when young
    TExperience_y(BrawnyOccupations,BW,:)=TstarOLD(BrawnyOccupations,WW,:)./tauhat_y_cleaned(BrawnyOccupations,WW,:);  % Use WW T's for BW
end;
if NoFrictions2010; % Then recover T(i,g) to yield tauhat=1 in 2010
    tauhat_y_cleaned(1,:,Nyears)=1; % So home sector is not a NaN
    for t=1:Nyears; % Take from the last period (2010), apply to all young cohorts
        TExperience_y(:,:,t)=TstarOLD(:,:,Nyears)./tauhat_y_cleaned(:,:,Nyears);  % last decade.
    end;
end;


%   For Version 5.0+, we do NOT adjust for differential experience in occs.
%   because now we assume people choose occ when young and stay there their whole lives.
OFFGroupExpAdjustment=ones(Ngroups,Nyears,Nymo); % YMO structure. "OFF" denotes "turned off"
GroupExpAdjFactor=ones(Ngroups,1);
if HalfExperience;
    GroupExpAdjFactor=[1 1/2 1/2 1/2]'; % WM=1, others get half the return to experience
end;

% Now compute T(i,g) = TExperience_y * TigYMO with GroupExpAdjFactor
TExperience=zeros(size(p))*NaN;
for g=1:Ngroups; 
    for t=1:Nyears; % Loop over years when the young are born (time)
        Cohort=(Nyears+1-t);
        TExperience(:,g,Cohort,t)  =TExperience_y(:,g,t);  % Young
        TExperience(:,g,Cohort,t+1)=TExperience_y(:,g,t).*(1+(TigYMO(:,t,2)-1).*GroupExpAdjFactor(g));  % Middle
        TExperience(:,g,Cohort,t+2)=TExperience_y(:,g,t).*(1+(TigYMO(:,t,3)-1).*GroupExpAdjFactor(g));  % Old
    end;
    TExperience(:,:,:,(Nyears+1):(Nyears+2))=[]; % previous loop creates two extra (future) decades;
    %What about in 1960 when we look at the 1950M women and 1940old women?
    %Let's just use the 1960 cohort adjustments. Cohort born in 1950 M=1960 O=1970
    % Incumbent cohort Nyears+1 (=7 when Nyears=6): middle in period 1, old in period 2.
    TExperience(:,g,(Nyears+1),1)=TExperience_y(:,g,1).*(1+(TigYMO(:,1,2)-1).*GroupExpAdjFactor(g)); % Middle
    TExperience(:,g,(Nyears+1),2)=TExperience_y(:,g,1).*(1+(TigYMO(:,1,3)-1).*GroupExpAdjFactor(g)); % Old
end;


% That := T(i,g)/T(i,WM)
Tig=TExperience; % These are the same
That=zeros(size(p)); % Need to resize TExperience_y for computing tauhat
for g=1:Ngroups;
    That(:,g,:,:)=TExperience(:,g,:,:)./TExperience(:,WM,:,:);
end;


% Finally, compute Tbar for all groups
% Have to adjust for future for 2000 and 2010 cohorts

Tbar=zeros(Noccs,Ngroups,Nyears)*NaN;
for g=1:Ngroups;
    for t=1:Nyears;
        if t<Nyears-1;
            % Full Y/M/O: the young cohort at t observed at periods t, t+1, t+2 (all <=Nyears).
            Tbar(:,g,t)=sum(squeeze(TExperience(:,g,(Nyears+1-t),(t:(t+2)))),2);
        elseif t==Nyears-1;
            % Y/M observed (periods Nyears-1, Nyears); OLD extrapolated from the next-older
            % cohort's old/middle ratio. cyoung=young cohort at t (=2); cyoung+1 (=3) is the
            % cohort that is middle at Nyears-1 and old at Nyears.
            cyoung=(Nyears+1-t);
            adjfactor=TExperience(:,g,cyoung+1,Nyears)./TExperience(:,g,cyoung+1,Nyears-1); %last/prev
            Tbar(:,g,t)=TExperience(:,g,cyoung,Nyears-1)+TExperience(:,g,cyoung,Nyears).*(1+adjfactor);
        elseif t==Nyears;
            %Tbar(:,g,t)=Tbar(:,g,Nyears-1); % Assume last-period cohort = prev cohort
            % Scale by ratio of TExperience_y last/prev to fix NoBrawny -- scale appropriately
            Tbar(:,g,t)=Tbar(:,g,Nyears-1).*TExperience_y(:,g,Nyears)./TExperience_y(:,g,Nyears-1);
        end;
    end;
end;

TbarHat=ones(size(Tbar))*NaN;
for g=1:Ngroups;
    TbarHat(:,g,:)=div(Tbar(:,g,:),Tbar(:,WM,:));
end;

disp ' ';
disp 'Tbar and TbarHat by Group and Years for Doctors'
squeeze(Tbar(8,:,:))
squeeze(TbarHat(8,:,:))

disp ' ';
disp 'Tbar and TbarHat by Group and Years for Secretaries'
squeeze(Tbar(23,:,:))
squeeze(TbarHat(23,:,:))

disp ' ';
disp 'Tbar and TbarHat by Group and Years for Farm'
squeeze(Tbar(42,:,:))
squeeze(TbarHat(42,:,:))

if any(~isreal(TExperience)); disp 'Imaginary TExperience! Stopping...'; keyboard; end;


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GROUPEXPADJUSTMENT -- Version 5: We create this variable so we can "add" it to
% WageGrowth when estimating TauW in estimatetauz.m
%
%    Suppose WW p's for doctors Y/M/O are .04, .06, .07
%    Suppose WM p's for doctors Y/M/O are .10, .10, and .10
%
%    WW when M:  2/3 have same experience as men, 1/3 have no experience.  
%                So the experience term for women would be 2/3 that of men.
%    WW when O:  4/7 have same experience as men, 2/7 have one decade of experience, and 1/7 have no experience.  
%        So it would be 4/7 * T3 + 2/7*T2
%    So for M == basically like old version 4 approach except with pY and pM instead of lfpY/M
%       for O == just do the same thing as for M, but for the earlier cohort...
% Note: when using WageGrowth(WW) in estimatetauz.m, we need to adjust it upward:
%      TrueExperience = 1 + GroupExpAdjustment*(TExperience-1);
%  ==> HypotheticalWageGrowth = ActualWageGrowth * TExperience / TrueExperience 

GroupExpAdjustment=ones(Noccs,Ngroups,Ncohorts,Nymo); % YMO structure
if NoGroupExpAdj~=1; % Adjust unless we look at special case of No adjustment
    for t=1:(Nyears-1);
        % Y->M
        Cohort=(Nyears+1-t); % Cohort that is young at date t
        pY=squeeze(p(:,:,Cohort,t));
        pM=squeeze(p(:,:,Cohort,t+1)); % When middle aged
        GroupExpAdjustment(:,:,Cohort,2)=div(pY./pM,pY(:,WM)./pM(:,WM)); % Adjust experience when M

        % M->O in year t to t+1
        CohortM=(Nyears+2-t); % Cohort that is middle at date t
        pM=squeeze(p(:,:,CohortM,t));
        pO=squeeze(p(:,:,CohortM,t+1)); % When old
        GroupExpAdjustment(:,:,CohortM,3)=div(pM./pO,pM(:,WM)./pO(:,WM)); % Adjust experience when O
    end; % Loop over young cohorts
    GroupExpAdjustment(GroupExpAdjustment>1)=1; % Do not allow adjustment larger than 1 
end;

