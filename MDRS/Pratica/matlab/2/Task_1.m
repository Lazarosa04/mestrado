% considera o simulador de eventos discreto implementado na função matlab
% fornecida Sim2Flows, para estimar a performance de uma ligação opnto a
% ponto que suporte 2 fluxos de pacotes.

% o simulador considera uma ligação de capacidade C (em Mbps) e um tamanho
% de queue f (em bytes) com scheduling FIFO.

% o fluxo de pacotes 1 é caracterizado por: 
% 1) os pacotes chegam seguindo um processo de Poisson com pps médio y1
% 2) o tamanho do pacote é
% aleatorio entre 64 e 1518 bytes com as seguintes probabilidades, 19% para
% 64 bytes, 23% para 110 bytes, 17% para 1518 bytes e probabilidades iguais
% para todos os restantes valroes

% o fluxo de pacote 2 é caracterizado por:
% 1) os pacotes chegam seguindo um processo de Poisson com pps médio y2
% 2) tamanho aleatorio de pacote entre 110 e 130 bytes todos com
% probabilidades iguais

% parametros de entrada do Sim2Flows:
% y - vector com o ritmo de transmissão de cada fluxo em pps
% C - capacidade da ligação em Mbps
% f - tamanho da queue em Bytes
% p - número total de pacotes transmitidos numa simulação

% parametros de performance estimados pelo Sim2Flows
% PL - vector com a percentagem de pacotes perdidos em cada fluxo
% APD - vector com o delay medio de pacote de cada fluxo (milisegundos)
% MPD - vector com o maximo delay de pacote de cada fluxo (milisegundos)
% TT - vector do throughtput transmitido de cada fluxo (Mbps)

% criterio de paragem do
% Sim2Flows, instante de tempo em que a ligação termina a transmissão do
% ultimo pacote de p

%% 1.a
% desenvolve um script matlab para correr Sim2Flows 50 vezes com criterio
% de paragem p = 10000 para cada simulação e comparar os valores estimaods
% e os intervalos a 90% de confiança de todos os parametros para quando 
% y1 = 1500pps, y2 = 1000pps, C = 10 Mbos e f = 1000000 bytes (~1Mbytes)

function results = runExperiment(y, C, f, P)
    nRuns = 50;
    confidenceLevel = 0.90;
    
    PL = zeros(nRuns, 2);
    APD = zeros(nRuns, 2);
    MPD = zeros(nRuns, 2);
    TT = zeros(nRuns, 2);
    
    for run = 1:nRuns
        [PL(run, :), APD(run, :), MPD(run, :), TT(run, :)] = ...
            Sim2Flows(y, C, f, P);
    end
    
    metricNames = {'PL (%)', 'APD (ms)', 'MPD (ms)', 'TT (Mbps)'};
    metricSamples = {PL, APD, MPD, TT};
    metricFields = {'PL', 'APD', 'MPD', 'TT'};
    alpha = 1 - confidenceLevel;
    zCritical = norminv(1 - alpha/2);
    
    fprintf('\nResultados para y = [%g %g], C = %g Mbps, f = %g Bytes, P = %g:\n', ...
        y(1), y(2), C, f, P);
    
    for metric = 1:numel(metricNames)
        samples = metricSamples{metric};
        estimate = mean(samples, 1);
        margin = zCritical * sqrt(var(samples, 0, 1) / nRuns);
        confidenceInterval = [estimate - margin; estimate + margin];
    
        results.(metricFields{metric}).estimate = estimate;
        results.(metricFields{metric}).confidenceInterval = confidenceInterval;
    
        fprintf('\n%s (estimativa +- erro, IC de %.0f%%):\n', ...
            metricNames{metric}, confidenceLevel * 100);
        for flow = 1:2
            fprintf('  Fluxo %d: %.6g +- %.6g\n', flow, ...
                estimate(flow), margin(flow));
        end
    end
end


y = [1500 1000];
C = 10;
P = 10000;
f = 1000000;
results1a = runExperiment(y, C, f, P);

%% 1.b - queue de 10 kBytes
f = 10000;
results1b = runExperiment(y, C, f, P);

%% 1.c - queue de 2 kBytes
f = 2000;
results1c = runExperiment(y,C,f,P);

%% 1.d - compara o atraso medio dos dois fluxos para os tamanhos de queue
% usados nas alíneas anteriores, com intervalos de confiança de 90%.

queueSizes = [1000000; 10000; 2000];
queueLabels = {'1 MB', '10 kB', '2 kB'};
experiments = {results1a, results1b, results1c};
meanDelays = zeros(numel(experiments), 2);
ciLower = zeros(numel(experiments), 2);
ciUpper = zeros(numel(experiments), 2);

for experiment = 1:numel(experiments)
    meanDelays(experiment, :) = experiments{experiment}.APD.estimate;
    confidenceInterval = experiments{experiment}.APD.confidenceInterval;
    ciLower(experiment, :) = confidenceInterval(1, :);
    ciUpper(experiment, :) = confidenceInterval(2, :);
end

for flow = 1:2
    figure;
    bar(meanDelays(:, flow));
    hold on;
    errorbar(1:numel(queueSizes), meanDelays(:, flow), ...
        meanDelays(:, flow) - ciLower(:, flow), ...
        ciUpper(:, flow) - meanDelays(:, flow), ...
        'k', 'LineStyle', 'none', 'LineWidth', 1);
    hold off;

    xticks(1:numel(queueSizes));
    xticklabels(queueLabels);
    xlabel('Tamanho da queue (Bytes)');
    ylabel('Atraso médio de pacote (ms)');
    ylim([0 3]);
    title(sprintf('Atraso médio - Fluxo %d', flow));
    grid on;
end