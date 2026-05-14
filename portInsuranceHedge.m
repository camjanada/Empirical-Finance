 %% 1. Parameters
clear; clc;
format bank
Kp = 90; s_A = 0.18; s_I = 0.15; rho = 0.90; r = 0.04;
Exp_returns = [0.07, 0.06]; % [max Sharpe portfolio E[r], Index E[r]]
C = [1 rho; rho 1]; 
S = diag([s_A, s_I]); 
V = S*C*S; 
returns = Exp_returns; 
Week = [0:1:52]'; 
Time = (repmat(52,length(Week),1)-Week)/52; 
Time(end) = (Week(end)+0.5-52)/52; 
% End Parameters 

%% 2. Simulate Stock A and Index (Stock A = your maxSharpe portfolio
for n = 1:1000
M = [100 100; zeros(52,2)]; % Stock A, Index 
for t = 2:length(Time)
    M(t,:) = M(t-1,:).*exp(returns/52 + randn(1,2)*chol(V)/sqrt(52)); 
end

d1p = (log(M(:,2)/Kp)+repmat(r,length(Time),1)+ 0.5*repmat(s_I^2,length(Time),1).*Time)./(s_I*sqrt(Time)); 
d2p = d1p - s_I*sqrt(Time); 

%% 3. Price option and put delta

put = repmat(Kp,length(Time),1).*exp(-r*Time).*normcdf(-d2p)-M(:,2).*normcdf(-d1p); 
delta = -normcdf(-d1p); 

%% 4. Delta Hedge Accounting 

X = [delta(1),-100*delta(1),-r*100*delta(1)/52;zeros(52,3)]; 
for t = 2:length(Time) 
    X(t,1) = delta(t)-delta(t-1); 
    X(t,2) = X(t-1,2)- X(t,1)*M(t,2)+X(t-1,3);  % Cash bal
    X(t,3) = X(t,2)*r/52; % interest
end
DeltaHedgeAcct = table(Week,Time,M(:,2),M(:,1),d1p,d2p,put,delta,X(:,2),X(:,3),...
    'VariableNames',{'Week','Time','Index','StockA','d1pI = ','d2p','Put','Delta','Cash','Interest'}); 
%% 5. Portfolio Value with Hedge 
 putValueHedged(n) = DeltaHedgeAcct.Put(1) + DeltaHedgeAcct.Index(end)-Kp;
 putUnhedged(n) = DeltaHedgeAcct.Put(1) - (Kp>DeltaHedgeAcct.Index(end))*(Kp-DeltaHedgeAcct.Index(end));

end

%% 6. Export Results to Excel
outDir = 'C:\Users\camja\Downloads\';

% Single-path hedge accounting table (last simulation run)
writetable(DeltaHedgeAcct, [outDir 'DeltaHedgeAcct.csv']);

% Summary statistics across all 1000 paths
SummaryStats = table(...
    {'Hedged'; 'Unhedged'}, ...
    [mean(putValueHedged); mean(putUnhedged)], ...
    [std(putValueHedged);  std(putUnhedged)], ...
    [min(putValueHedged);  min(putUnhedged)], ...
    [max(putValueHedged);  max(putUnhedged)], ...
    [mean(putValueHedged<0); mean(putUnhedged<0)], ...
    'VariableNames', {'Strategy','Mean','StdDev','Min','Max','ProbLoss'});
disp(SummaryStats);
writetable(SummaryStats, [outDir 'SimulationSummary.csv']);

% All 1000 payoffs for both strategies
AllPayoffs = table((1:1000)', putValueHedged', putUnhedged', ...
    'VariableNames', {'Simulation','HedgedPL','UnhedgedPL'});
writetable(AllPayoffs, [outDir 'AllSimulationPayoffs.csv']);

