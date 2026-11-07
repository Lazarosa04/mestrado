%% 3.a
% Estimate the performance of Sim2FlowsDrr over 50 runs and calculate
% 90% confidence intervals for each metric and flow.

function results = runExperiment(y, C, f, P, quantum, inv)
    nRuns = 50;
    confidenceLevel = 0.90;
    
    PL = zeros(nRuns, 2);
    APD = zeros(nRuns, 2);
    MPD = zeros(nRuns, 2);
    TT = zeros(nRuns, 2);
    
    for run = 1:nRuns
        [PL(run, :), APD(run, :), MPD(run, :), TT(run, :)] = ...
            Sim2FlowsDrr(y, C, f, P, quantum, inv);
    end
    
    metricNames = {'PL (%)', 'APD (ms)', 'MPD (ms)', 'TT (Mbps)'};
    metricSamples = {PL, APD, MPD, TT};
    metricFields = {'PL', 'APD', 'MPD', 'TT'};
    alpha = 1 - confidenceLevel;
    zCritical = norminv(1 - alpha/2);
    
    fprintf(['\nResults for y = [%g %g], C = %g Mbps, ' ...
        'f = [%g %g] Bytes, P = %g, quantum = [%g %g] Bytes, inv = %d:\n'], ...
        y(1), y(2), C, f(1), f(2), P, ...
        quantum(1), quantum(2), inv);
    
    for metric = 1:numel(metricNames)
        samples = metricSamples{metric};
        estimate = mean(samples, 1);
        margin = zCritical * sqrt(var(samples, 0, 1) / nRuns);
        confidenceInterval = [estimate - margin; estimate + margin];
    
        results.(metricFields{metric}).estimate = estimate;
        results.(metricFields{metric}).confidenceInterval = confidenceInterval;
    
        fprintf('\n%s (estimate +- error, %.0f%% CI):\n', ...
            metricNames{metric}, confidenceLevel * 100);
        for flow = 1:2
            fprintf('  Flow %d: %.6g +- %.6g\n', flow, ...
                estimate(flow), margin(flow));
        end
    end
end


y = [1000 5500];
C = 10;
P = 10000;
f = [1000000 1000000];
quantum = [1600 1600];
inv = false;
results3a = runExperiment(y, C, f, P, quantum, inv);

%% 3.b - Repeat 3.a with the order of the flows inverted
inv = true;
results3b = runExperiment(y, C, f, P, quantum, inv);

%% 3.c - Repeat 3.a with a larger quantum for Flow 2
quantum = [1600 4800];
inv = false;
results3c = runExperiment(y, C, f, P, quantum, inv);

%% 3.d - Repeat 3.c with the order of the flows inverted
inv = true;
results3d = runExperiment(y, C, f, P, quantum, inv);