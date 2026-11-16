%% 2.a.
% 90% confidence intervals
% 50 runs
% Queue sizes
f = [1000000 1000000 1000000];
% Capacity
C = 10;
% Stopping criterion
P = 100000;

%% 2.b.
% Case C: y1 = 800pps, y2 = 800pps, y3 = 600pps
y = [800 800 600];

% Sim3FlowsPrioT uses prio = 1 to give Flow 3 the highest priority.
prio = 1;

runExperiment(y, C, f, P, prio);

%% 2.c. Average packet delay and throughput
% Theoretical M/G/1 results with priority queuing for case C.
minBytes = [100 100 500];
maxBytes = [1500 150 1000];
meanBytes = (minBytes + maxBytes) / 2;
capacityBps = C * 1e6;

numberOfSizes = maxBytes - minBytes + 1;
varianceBytes = (numberOfSizes.^2 - 1) / 12;
secondMomentBytes = meanBytes.^2 + varianceBytes;

meanService = 8 * meanBytes / capacityBps;
secondMomentService = 64 * secondMomentBytes / capacityBps^2;

rho = y .* meanService;
totalRho = sum(rho);
if totalRho >= 1
    error('The priority M/G/1 system is unstable: rho must be less than 1.');
end

% Flow 3 has the highest priority. Flows 1 and 2 share the lower
% priority level and therefore have the same average queueing delay.
rhoHigh = rho(3);
rhoLow = rho(1) + rho(2);
W0 = 0.5 * sum(y .* secondMomentService);

queueingDelayHigh = W0 / (1 - rhoHigh);
queueingDelayLow = W0 / ((1 - rhoHigh) * (1 - totalRho));

averagePacketDelayMs = 1000 * ...
    [queueingDelayLow + meanService(1), ...
     queueingDelayLow + meanService(2), ...
     queueingDelayHigh + meanService(3)];
throughputMbps = y .* meanBytes * 8 / 1e6;

fprintf('\nTheoretical priority M/G/1 results for case C:\n');
fprintf('Flow 3 has the highest priority.\n');
fprintf('Flows 1 and 2 share the lower priority level.\n');

for flow = 1:numel(y)
    fprintf(['Flow %d: average packet delay = %.6f ms, ' ...
        'throughput = %.6f Mbps\n'], ...
        flow, averagePacketDelayMs(flow), throughputMbps(flow));
end

%% 2.d.
% Case A: y1 = 400pps, y2 = 400pps, y3 = 600pps
% Case B: y1 = 600pps, y2 = 600pps, y3 = 600pps
% Case C: y1 = 800pps, y2 = 800pps, y3 = 600pps

cases = [400 400 600;   % A
         600 600 600;   % B
         800 800 600];  % C

results = cell(3,1);
for k = 1:3
    results{k} = runExperiment(cases(k,:), C, f, P, prio);
end

%% 2.d. graficos

apd = zeros(1,3);
apdCI = zeros(2,3);
mpd = zeros(1,3);
mpdCI = zeros(2,3);

for k = 1:3
    apd(k) = results{k}.APD.estimate(3);
    apdCI(:,k) = results{k}.APD.confidenceInterval(:,3);

    mpd(k) = results{k}.MPD.estimate(3);
    mpdCI(:,k) = results{k}.MPD.confidenceInterval(:,3);
end

figure;
bar(apd);
hold on;
errorbar(1:3, apd, apd-apdCI(1,:), apdCI(2,:)-apd, ...
    'Color', 'w', 'LineWidth', 0.7, 'CapSize', 10, 'LineStyle', 'none');
xticks(1:3);
xticklabels(["A" "B" "C"]);
ylabel('Average packet delay of Flow 3 (ms)');

figure;
bar(mpd);
hold on;
errorbar(1:3, mpd, mpd-mpdCI(1,:), mpdCI(2,:)-mpd, ...
    'Color', 'w', 'LineWidth', 0.7, 'CapSize', 10, 'LineStyle', 'none');
xticks(1:3);
xticklabels(["A" "B" "C"]);
ylabel('Maximum packet delay of Flow 3 (ms)');
