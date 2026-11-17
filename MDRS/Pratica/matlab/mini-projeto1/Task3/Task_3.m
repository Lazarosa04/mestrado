%% 3.a.
% 90% confidence intervals
% 50 runs
% Queue sizes
f = [1000000 1000000 1000000];
% Capacity
C = 10;
% Stopping criterion
P = 100000;

%% 3.b.
% Case C: y1 = 800pps, y2 = 800pps, y3 = 600pps
y = [800 800 600];
% quantum value of 1500 for each flow
quantum = [1500 1500 1500];
% inv not mentioned so we assume False
inv = False;

runExperiment(y, C, f, P, quantum, inv);

%% 3.c
% Case D: y1 = 1000, y2 = 1000, y3 = 1000
y = [1000 1000 1000];

runExperiment(y, C, f, P, quantum, inv);

%% 3.d
% 4500 for flow 3
quantum = [1500 1500 4500];

runExperiment(y, C, f, P, quantum, inv);
