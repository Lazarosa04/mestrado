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
% inv not mentioned so we assume false
inv = false;

runExperiment(y, C, f, P, quantum, inv);

%% 3.c
% Case D: y1 = 1000, y2 = 1000, y3 = 1000
y = [1000 1000 1000];

runExperiment(y, C, f, P, quantum, inv);

%% 3.d
% 4500 for flow 3
quantum = [1500 1500 4500];

runExperiment(y, C, f, P, quantum, inv);

%% 3.e
minBytes = [100 100 500];
maxBytes = [1500 150 1000];
meanBytes = (minBytes + maxBytes) / 2; % [800 125 750] bytes

% 3.c e 3.d, case D, y1 = y2 = y3 = 1000 pps
C1 = 1000*800*8e6;  % 6.4Mbps
C2 = 1000*125*8e6;  % 1Mbps
C3 = 1000*750*8e6;  % 6Mbps
CTotal = C1+C2+C3;  % 13.4 Mbps > C = 10Mbps

% 3.C
quantum = [1500 1500 1500]  % i.e os fluxos têm todos o mesmo peso
% temos 10 Mbps para distribuir por igual pelos 3 fluxos
% o fluxo 2 só suporta 1Mbps por isso recebe logo isso
% restam 10-1 = 9 Mbps para distribuir por igual pelos restantes fluxos
% 9/2 = 4.5
% logo a distribuição ideal do throughput para este caso é:
ideal = [4.5 1 4.5]

% 3.d
quantum = [1500 1500 4500]  % i.e o fluxo 3 vale 3 vezes mais que os outros fluxos
% ou seja a distribuição deve seguir este padrão [1 1 3]
% temos 10 Mbps para distribuir pelos 3 fluxos seguindo esse padrão
% para 10 Mbps a distribuição seria [2 2 6] mas
% o fluxo 2 só suporta 1Mbps por isso recebe logo isso
% o fluxo 3 só suporta 6Mbps por isso tambem recebe logo isso
% restam 10-1-6 = 3 Mbps para o fluxo 1
% logo a distribuição ideal do throughput para este caso é:
ideal = [3 1 6]

