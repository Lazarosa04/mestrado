%% 1.a.
% 90% confidence intervals
% 50 runs
% Queue size
f = 1000000;
% Capacity
C = 10; 
% Stopping criterion
P = 100000;

%% 1.b.
% Case C: y1 = 800pps, y2 = 800pps, y3 = 600pps
y = [800 800 600];

runExperiment(y, C, f, P);

%% 1.c. Average packet delay
minBytes = [ 100 100 500];
maxBytes = [1500 150 1000];
meanBytes = (minBytes + maxBytes)/2;
capacityBps = C * 1e6;

numberOfSizes = maxBytes - minBytes + 1;
varianceBytes = (numberOfSizes.^2 - 1)/12;
secondMomentBytes = meanBytes.^2 + varianceBytes;

meanService = 8 * meanBytes / capacityBps;
secondMomentService = 64 * secondMomentBytes / capacityBps^2;

totalArrivalRate = sum(y);
rho = sum(y .* meanService);
if rho >= 1
    error('The M/G/1 system is unstable: rho must be less than 1.');
end

aggregateMeanService = sum(y .* meanService) / totalArrivalRate;
aggregateSecondMomentService = ...
    sum(y .* secondMomentService) / totalArrivalRate;
queueingDelay = totalArrivalRate * aggregateSecondMomentService / ...
    (2 * (1 - totalArrivalRate * aggregateMeanService));

averagePacketDelayMs = 1000 * (queueingDelay + meanService);

for flow = 1:numel(y)
    fprintf('Flow %d: average packet delay = %.6f ms\n', ...
        flow, averagePacketDelayMs(flow));
end

%% 1.c. Throughput
throughputMbps = y .* meanBytes * 8 / 1e6;

fprintf('\nTheoretical throughput for case C:\n');
for flow = 1:numel(y)
    fprintf('Flow %d: throughput = %.6f Mbps\n', flow, throughputMbps(flow));
end
