% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   EstimateTauZ.m   
%
%   Main program to estimate TauW, TauH, and Z
%   See the Note on Estimation for more information on how this program works.
%     
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; 
global CaseName OccupationNames ShortNames BrawnyOccupations GroupNames Noccs Ngroups Nyears Ncohorts Decades;
diarychad('EstimateTauZ',CaseName)

clc;
load(['CohortData_' CaseName '.mat']);
ShowParameters;

ssr=ones(100,1)*100;
iter=1;
end_criteria=100;


% Initializing for storage
ExperienceCohortFactor=ones(Ngroups,Nyears,3); % YMO structure
Z=zeros(Noccs,Ngroups,Ncohorts)*NaN;  % Ordered by Cohort
                                      %TgHome=zeros(Noccs,Ngroups,Ncohorts)*NaN;  % Ordered by Cohort


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Part I
% Estimate w(i), s(i) and phi(i) from white men 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    clc;
    ShowData=1;    
    Tbar=3*ones(Noccs,Ngroups,Nyears); % Initial guess for Tbar for WM. 

dltaOld=-1;
if EstimateDelta; dlta=0; end;
A=NaN; % Initially we do not have A to use as an instrument
while abs(dlta-dltaOld)>.002; % Loop until dlta converges    
    if EstimateDelta;
        dltaOld=dlta;
        if isnan(A);
            dlta=1/2; % Starting guess. 0.1 also converges to same value
        else;
            dlta=estimatedeltaYWM(eta,beta,theta,gam,sigma,Tbar,A);
        end;
        save(['CohortData_' CaseName '.mat'],'dlta','-append');
    else;
        dltaOld=dlta;
    end;
    
    [w,phi,s,mwm,ZWM,WageBarHomeY]=solveWMfor_wZ(eta,beta,theta,gam,sigma,OccupationtoIdentifyWageHome,Tbar,ShowData);

    % GetTExperience first ==> Tig and Tbar to pass to solveWMfor_w_phi    
    % Compute the T(i,g) and That := T(i,g)/T(i,WM) and iterate to update
    That=ones(size(p)); % Initial guess
    TbarHat=ones(size(Tbar))*NaN;
    for g=1:Ngroups;
        TbarHat(:,g,:)=div(Tbar(:,g,:),Tbar(:,WM,:));
    end;
    GetTExperience
    
    % Iterate until converges
    Told=squeeze(Tbar(:,1,:));
    maxdiff=1; s_counter=1; % WM
    disp '>>> Starting maxdiff/s_counter loop in EstimateTauZ.m';
    while maxdiff>.001 && s_counter<25;
        [w,phi,s,mwm,ZWMt,WageBarHomeY]=solveWMfor_wZ(eta,beta,theta,gam,sigma,OccupationtoIdentifyWageHome,Tbar,ShowData);
        % Note: ZWMt has a time order instead of a cohort order, but we never use this series
        %       The cohort order one is backed out of estimatetauz with all the other groups.
        disp ' '; 
        fprintf('>>> Calling GetTExperience: Loop = %1.0f\n',s_counter);
        disp ' ';
        GetTExperience
        s_counter=s_counter+1;
        maxdiff=max(max(Told-squeeze(Tbar(:,1,:))));
        Told=squeeze(Tbar(:,1,:)); % WM
    end;
    disp ' ';
    fprintf('Done with iteration to get Tbar convergence. MaxDiff=%6.4f  s_counter=%2.0f\n',[maxdiff s_counter]);
    disp ' ';
       
    
    % And plot for WW if IgnoreBrawnyOccupations || NoFrictions2010
    if IgnoreBrawnyOccupations || NoFrictions2010;
        disp 'TauHat for WW -- should be 1 in the right places if IgnoreBrawnyOccupations || NoFrictions2010';
        cshow(ShortNames,squeeze(tauhat(:,WW,:)),'%8.3f','1960 1970 1980 1990 2000 2010');
    end;
    
    disp ' ';
    fprintf('Iteration to get Tbar ended after %2.0f iterations',s_counter-1);
    disp ' ';

    % Update Earnings for WageBarHomeY (young);
    Earnings_orig = Earnings;
    for t=1:Nyears;
        for g=1:Ngroups;
            earnings_markup(g,t)=nansum(mult(squeeze(Earnings(:,g,(Nyears+1-t),t)./WageBar(:,g,(Nyears+1-t),t)),earningsweights(:,t)));
            Earnings(HOME,g,(Nyears+1-t),t)=earnings_markup(g,t)*WageBarHomeY(g,t);  % Adjust for Geo/Arith
            WageBar(HOME,g,(Nyears+1-t),t)=WageBarHomeY(g,t);
        end;
    end;
    
    %  Eqn (B5) in the appendix shows that in our model, the ratio of the 
    %  geometric mean to the arithmetic mean is
    %   G = A * gam/GammaBase * pig^(dlta*mu) / ((1-dlta)+dlta*pig^mu);
    %  1/10/19 old line in solveeqm.m:    AvgQuality=AvgQuality*gam/GammaBase/GeoArith_markup;
    %  1/16/19 new line:                  AvgQuality=AvgQuality*GeoArith_adjust;
    
    GeoArith_markup=1./median(earnings_markup(WM,:));
    fprintf('Markup of geometric mean over arithmetic mean is %8.4f\n',GeoArith_markup);
    pterm=p.^(dlta*mu)./((1-dlta)+dlta*p.^mu); % NxGxCxT
    for t=1:Nyears;
        for g=1:Ngroups;   % Use middle-aged cohort in each year = 7-t+1         
            pterm_g(g,t) = nansum(earningsweights(:,t).*squeeze(pterm(:,g,(Nyears+2-t),t)));
        end;
    end;
    pterm_t=sum(earningsweights_gt.*pterm_g);
    pterm=mean(pterm_t')
    GeoArith_model=gam/GammaBase*pterm;
    GeoArith_adjust=GeoArith_model/GeoArith_markup;
    fprintf('GeoArith_model = %8.4f\n',GeoArith_model);
    fprintf('GeoArith_markup = %8.4f\n',GeoArith_markup);
    fprintf('GeoArith_adjust = %8.4f\n',GeoArith_adjust);

    
% =========================================================================
% =========================================================================
% Part II
% Estimate TauW, TauH, and Z for three other groups (white women and black men/women)
% =========================================================================
% =========================================================================

    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Prepare to Loop over AlphaSplitTauW1960 to find the 
    % fixed point split of tauhat into TauW and TauH
    % that we should start with
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    AlphaIterMax=10; % Max number of iterations
    %AlphaIterMax=2; % Max number of iterations 2==> don't iterate. Just 1 time through...
    alphacounter=1;
    AlphaChange=1;
    if ~isnan(Alpha0FixedSplit);
        AlphaSplitTauW1960=Alpha0FixedSplit;  % Then just use this split and do not iterate
        AlphaIterMax=2;
    end;
    if FiftyFiftyTauHat==1;
        ConstantAlpha=1/2; %
    end;
    if ~isnan(ConstantAlpha);
        AlphaSplitTauW1960=ConstantAlpha; % Starting value and don't iterate
        AlphaIterMax=2;
    end;
    AlphaSplit=zeros(AlphaIterMax,1);
    AlphaSplit(1)=AlphaSplitTauW1960;
    %WageforTauW=Wage_controls; % The "Wage" series from Erik, as opposed to earnings. = Earnings/ReportedHours. Use for WageGrowth TauW
    %disp 'Using WageforTauW=Wage_controls to get WageGrowth for estimating TauW...';
    WageforTauW=WageBar; % The basic Earnings series (default)
    disp 'Using WageforTauW=WageBar to get WageGrowth for estimating TauW...';
    
while alphacounter<AlphaIterMax && abs(AlphaChange)>.003;

    [TauW,TauH,Z,mg,WageGrowthRelative,EarningsHome]=estimatetauz(AlphaSplit(alphacounter),w,phi,s,p,WageBar,Earnings,tauhat,Tig,eta,beta,theta,dlta,gam,ConstantAlpha,Tbar,GroupExpAdjustment,WageforTauW,WhichWageGrowth,ConstrainTauH,PurgeWageGrowthSelection,IgnoreBrawnyOccupations,NoFrictions2010);
    % Update EarningsHome from estimatetauz -- i.e. since tauh=tauw=0 at home, using wagegrowth equation...
    % This is arithmetic average, which is what we need to compute H(i,t) later.
    Earnings(HOME,:,:,:)=EarningsHome;

    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SPLIT of tauhat into TauW and TauH (young)
    %   - To update our 1960 assumption
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    AlphaSplitYoung=-log(1-TauW)./log(tauhat);  % Noccs x Ngroups x Nyears
    AlphaSplitYoung(AlphaSplitYoung>1)=1; % Constrain values to between 0 and 1 when averaging
    AlphaSplitYoung(AlphaSplitYoung<0)=0;
    disp ' ';
    disp 'AlphaSplitYoung for WW:';
    cshow(ShortNames,squeeze(AlphaSplitYoung(:,2,:)),'%8.3f','1960 1970 1980 1990 2000 2010');
    for g=2:Ngroups;
        meansplit(g,:)=squeeze(nansum(mult(squeeze(AlphaSplitYoung(:,g,:)),earningsweights_avg)));
    end;
    nonWMweights=earningsweights_g./sum(earningsweights_g(2:Ngroups));
    nonWMweights(WM)=NaN;
    meansplit_avg=sum(mult(meansplit(2:Ngroups,:),nonWMweights(2:Ngroups)));
    disp ' ';
    disp '============================================';
    disp 'SPLIT of tauhat into TauW and TauH (young), earnings weighted'
    disp ' - For comparison with our 1960 assumption'
    disp '============================================';
    cshow(GroupNames,meansplit,'%10.3f','1960 1970 1980 1990 2000 2010')
    disp '-----------------------------------------------------------------------';
    cshow('///Mean/// ',meansplit_avg,'%10.3f',[],[],1);
    fprintf('  And the mean for all years is %10.3f\n',mean(meansplit_avg));
    fprintf('The mean for yearsafter 1960 is %10.3f\n',mean(meansplit_avg(2:end)));

    % And update
    AlphaSplitNew=mean(meansplit_avg);
    AlphaChange=AlphaSplitNew-AlphaSplitTauW1960;
    alphacounter=alphacounter+1;
    AlphaSplit(alphacounter)=AlphaSplitNew;
    AlphaSplitTauW1960=AlphaSplitNew;

end; % End of AlphaSplit (alphacounter) loop

disp ' ';
disp 'List of AlphaSplitTauW1960 values we tried:';
blah=[(1:AlphaIterMax)' AlphaSplit];
cshow(' ',blah(1:(alphacounter-1),:),'%8.0f %8.4f','Iter AlphaSplit');
disp ' ';
AlphaSplitTauW1960=AlphaSplit(alphacounter-1);
fprintf('The final value of AlphaSplitTauW1960 = %8.5f\n',AlphaSplitTauW1960);
disp ' ';




%% Part III Fix missing values in a systematic way
    
    % Earnings(HOME) -- arithmetic avg -- we need this for AvgQuality and human capital
    % at the end of this program. Use the differences across cohorts in 1980 and 1970 to fill in
    EarningsHome=squeeze(Earnings(1,:,:,:));
    Cohort=Nyears+1; t=2; % Old in 1970
    ScaleFactor = EarningsHome(:,Cohort-1,t+1)./EarningsHome(:,Cohort-2,t+1); % 1980 old vs middle
    EarningsHome(:,Cohort,t)=EarningsHome(:,Cohort-1,t).*ScaleFactor;
    t=1; % Middle in 1960
    ScaleFactor = EarningsHome(:,Cohort-1,t+1)./EarningsHome(:,Cohort-2,t+1); % 1970 middle vs young
    EarningsHome(:,Cohort,t)=EarningsHome(:,Cohort-1,t).*ScaleFactor;
    Cohort=Nyears+2; % Old in 1960
    ScaleFactor = EarningsHome(:,Cohort-1,t+1)./EarningsHome(:,Cohort-2,t+1); % 1970 old vs middle
    EarningsHome(:,Cohort,t)=EarningsHome(:,Cohort-1,t).*ScaleFactor;
    Earnings(HOME,:,:,:)=EarningsHome;


    % Fix missing values in a systematic way
    disp ' '; disp '===========================================================';
    disp 'Fixing TauW / TauH / TgHome / Z missing values';
    disp ' -- Use first non-missing value';
    disp ' -- Missing p and WageBar ==> 0';
    disp ' ';  disp '===========================================================';

    for g=2:Ngroups; disp ' ';
        disp '*********************';
        disp(GroupNames{g});
        disp '*********************'; disp ' ';
        for i=2:Noccs;
            % TauW
            missingTauW=(isnan(squeeze(TauW(i,g,:))) | isinf(squeeze(TauW(i,g,:))) | (squeeze(TauW(i,g,:))==1) );
            %if all(missingTauW); 
            %    disp 'All TauW missing. Stopping...'; keyboard;
            %end;
            if any(missingTauW);
                cshow(['TauW ' ShortNames{i}],squeeze(TauW(i,g,:))','%8.4f',[],'nonee',1);
                TauW(i,g,:)=fixmissing(squeeze(TauW(i,g,:)),missingTauW);
                cshow(['TauW ' ShortNames{i}],squeeze(TauW(i,g,:))','%8.4f',[],'nonee',1);
            end;
    
            % TauH
            missingTauH=(isnan(squeeze(TauH(i,g,1:Nyears))) | isinf(squeeze(TauH(i,g,1:Nyears))) );
            %if all(missingTauH); 
            %    disp 'All TauH missing. Stopping...'; keyboard;
            %end;
            if any(missingTauH);
                cshow(['TauH ' ShortNames{i}],squeeze(TauH(i,g,:))','%8.4f',[],'nonee',1);
                TauH(i,g,1:Nyears)=fixmissing(squeeze(TauH(i,g,1:Nyears)),missingTauH);
                cshow(['TauH ' ShortNames{i}],squeeze(TauH(i,g,1:Nyears))','%8.4f',[],'nonee',1);
            end;

            % Z
            %missingZ=(isnan(squeeze(Z(i,g,1:Nyears))) | (squeeze(Z(i,g,1:Nyears))==1) );
            missingZ=isnan(squeeze(Z(i,g,1:Nyears)));
            %if all(missingZ); 
            %    disp 'All Z missing. Stopping...'; keyboard;
            %end;
            if any(missingZ);
                cshow(['Z ' ShortNames{i}],squeeze(Z(i,g,:))','%8.4f',[],'nonee',1);
                Z(i,g,1:Nyears)=fixmissing(squeeze(Z(i,g,1:Nyears)),missingZ);
                cshow(['Z ' ShortNames{i}],squeeze(Z(i,g,1:Nyears))','%8.4f',[],'nonee',1);
            end;

        
        end; % Occupations
    end; % Groups
    % Zero out the home sector tau's -- otherwise NaNs can mess up sums later
    TauW(1,:,:)=zeros(Ngroups,Nyears);
    TauH(1,:,:)=zeros(Ngroups,Nyears);

    % Fix TauH order -- In Version 4.0 and before it was Ncohorts rather than Nyears
    % Same thing for Z
    TauH_T=TauH;
    TauH_C=zeros(Noccs,Ngroups,Ncohorts);
    TauH_C(:,:,Nyears:(-1):1)=TauH;
    TauH=TauH_C; % To restore "old" way of ordering, which later programs assume!
    
    Z_T=Z;
    Z_C=zeros(Noccs,Ngroups,Ncohorts);
    Z_C(:,:,Nyears:(-1):1)=Z;
    Z=Z_C; % To restore "old" way of ordering, which later programs assume!
    
    

%% Part IIIB
% Compute AvgQuality and Human capital levels    
    
    AvgQuality=zeros(Noccs,Ngroups,Ncohorts,Nyears);
    for g=1:Ngroups; % This separate looping is needed!!
        % Calculate Average Quality of Workers
        for c=1:Ncohorts;
            % Note well: AvgQuality *includes* the TExperience (since that will enter H(.) later).
            % This should use Earnings instead of WageBar (i.e. arithmetic average)
            AvgQuality(:,g,c,:)=squeeze(Earnings(:,g,c,:))./squeeze((1-TauW(:,g,:)))./w; %./squeeze(TExperience(:,g,c,:));
        end;    
        AvgQuality(isnan(AvgQuality))=0; % Replace NaNs with zeros (bc TauW=1 when noone in Forest)
        AvgQuality(isinf(AvgQuality))=0; % Replace Infss with zeros (bc TauW=1 when noone in Forest)
    
    end;

    % Get H(i,t) by adding up across cohorts and groups
    % Note: AvgQuality calculated above already implicitly includes Texp
    H=zeros(Noccs,Ngroups,Ncohorts,Nyears); % Efficiency units in each cell
    for i=1:Noccs;
        H(i,:,:,:)=q.*squeeze(p(i,:,:,:)).*squeeze(AvgQuality(i,:,:,:));
    end;
    Higt=squeeze(nansum(H,3)); % Add over cohorts

    Hyoung=zeros(Noccs,Ngroups,Nyears);
    for t=1:Nyears;
        cYoung=CohortConcordance(t,2);
        Hyoung(:,:,t)=squeeze(H(:,:,cYoung,t));
    end;

%% Get A(i,t) for instruments in the estimatedeltaYWM.m
    
    Hit=squeeze(sum(Higt,2)); % Add over groups
    GDP=sum(w.*Hit)';
    num=w.^sigma.*Hit;
    A=(div(num,GDP')).^(1/(sigma-1));
end; % while loop to estimate delta
    
% Variables to save
phiAll=[zeros(Noccs,2)*NaN phi]; % 1940 1950 ... 2010 Order in solvefor_w_phi_givensubsidy
phi_C=flipud(phiAll')';
HAllData=H;
mgEstimated=mg

save(['EstimateTauZData_' CaseName '.mat'],'TauW','TauH','TauH_C','TauH_T','Z','phi_C', 'TigYMO', 'GeoArith_adjust', 'mgEstimated',...
     'AvgQuality','H','HAllData','Higt','Hit','tauhat','tauhat_all','tauhat_y', ...
     'w','phi','s','mwm','earningsweights','Tig','TExperience','Tbar','GroupExpAdjustment','WageGrowthRelative','Nymo');

diary off;


