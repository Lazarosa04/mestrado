%% 2.a
% Estimate the performance of Sim2FlowsPrio over 50 runs and calculate
% 90% confidence intervals for each metric and flow.

function results = runExperiment(y, C, f, P, priorityFlow)
    nRuns = 50;
    confidenceLevel = 0.90;
    
    PL = zeros(nRuns, 2);
    APD = zeros(nRuns, 2);
    MPD = zeros(nRuns, 2);
    TT = zeros(nRuns, 2);
    
    for run = 1:nRuns
        [PL(run, :), APD(run, :), MPD(run, :), TT(run, :)] = ...
            Sim2FlowsPrio(y, C, f, P, priorityFlow);
    end
    
    metricNames = {'PL (%)', 'APD (ms)', 'MPD (ms)', 'TT (Mbps)'};
    metricSamples = {PL, APD, MPD, TT};
    metricFields = {'PL', 'APD', 'MPD', 'TT'};
    alpha = 1 - confidenceLevel;
    zCritical = norminv(1 - alpha/2);
    
    fprintf(['\nResults for y = [%g %g], C = %g Mbps, ' ...
        'f = [%g %g] Bytes, P = %g, priority flow = %d:\n'], ...
        y(1), y(2), C, f(1), f(2), P, priorityFlow);
    
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



y = [1500 1000];
C = 10;
P = 10000;
f = [1000000 1000000];
prio = 2; % Flow 2 has higher priority in this experiment.

results2a = runExperiment(y, C, f, P, prio);

%% 2.b - Repeat 2.a with Flow 1 having higher priority
prio = 1;
results2b = runExperiment(y, C, f, P, prio);

%% 2.c - Repeat 2.a with 10,000-Byte queues
f = [10000 10000];
prio = 2;
results2c = runExperiment(y, C, f, P, prio);

%% 2.d - Repeat 2.b with 10,000-Byte queues
prio = 1;
results2d = runExperiment(y, C, f, P, prio);
