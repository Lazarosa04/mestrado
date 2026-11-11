function results = runExperiment(y, C, f, P)
    nRuns = 50;
    confidenceLevel = 0.90;
    
    PL = zeros(nRuns, 3);
    APD = zeros(nRuns, 3);
    MPD = zeros(nRuns, 3);
    TT = zeros(nRuns, 3);
    
    for run = 1:nRuns
        [PL(run, :), APD(run, :), MPD(run, :), TT(run, :)] = ...
            Sim3FlowsT(y, C, f, P);
    end
    
    metricNames = {'PL (%)', 'APD (ms)', 'MPD (ms)', 'TT (Mbps)'};
    metricSamples = {PL, APD, MPD, TT};
    metricFields = {'PL', 'APD', 'MPD', 'TT'};
    alpha = 1 - confidenceLevel;
    zCritical = norminv(1 - alpha/2);
    
    fprintf('\nResultados para y = [%g %g %g], C = %g Mbps, f = %g Bytes, P = %g:\n', ...
        y(1), y(2), y(3), C, f, P);
    
    for metric = 1:numel(metricNames)
        samples = metricSamples{metric};
        estimate = mean(samples, 1);
        margin = zCritical * sqrt(var(samples, 0, 1) / nRuns);
        confidenceInterval = [estimate - margin; estimate + margin];
    
        results.(metricFields{metric}).estimate = estimate;
        results.(metricFields{metric}).confidenceInterval = confidenceInterval;
    
        fprintf('\n%s (estimativa +- erro, IC de %.0f%%):\n', ...
            metricNames{metric}, confidenceLevel * 100);
        for flow = 1:3
            fprintf('  Fluxo %d: %.6g +- %.6g\n', flow, ...
                estimate(flow), margin(flow));
        end
    end
end
