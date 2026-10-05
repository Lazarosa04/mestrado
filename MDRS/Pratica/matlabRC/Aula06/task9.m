%% 9

addpath('C:\Users\Ruben\Documents\MATLAB\MATLABcodes1')
load("InputData2.mat")
nNodes= size(Nodes,1);
nLinks= size(Links,1);
nFlows= size(T,1);

sP= cell(1,nFlows);
nSP= zeros(1,nFlows);

%% a)
% Determine the number of routing paths provided by the network to each traffic flow.
% Register the minimum and maximum number of routing paths and the corresponding
% traffic flows

k= inf;
for f=1:nFlows
    [shortestPath, totalCost] = kShortestPath(L,T(f,1),T(f,2),k);
    sP{f}= shortestPath;
    nSP(f)= length(totalCost);
end

fprintf("Minimun no. of paths= %d \n", min(nSP));
min_array = find(nSP == min(nSP));
for f = min_array
    fprintf("Flow %d (%d -> %d) \n", f, T(f,1), T(f,2))
end

fprintf("Maximun no. of paths= %d \n", max(nSP));
max_array = find(nSP == max(nSP));
for f = max_array
    fprintf("Flow %d (%d -> %d) \n", f, T(f,1), T(f,2))
end

%% c) e d)

timeLimit= 5;
% k= inf;
k = 6;
sP= cell(1,nFlows);
nSP= zeros(1,nFlows);
for f=1:nFlows
    [shortestPath, totalCost] = kShortestPath(L,T(f,1),T(f,2),k);
    sP{f}= shortestPath;
    nSP(f)= length(totalCost);
end
fprintf("\n===== ALGORITHM A — RANDOM =====\n");
[A_sol, A_W, A_noSol, A_avgW, A_time] = RandomAlgorithm(nNodes,Links,T,sP,nSP,timeLimit);
fprintf("W = %.2f Gbps | No. sol = %d | Av. W = %.2f | time = %.2f sec\n", ...
        A_W, A_noSol, A_avgW, A_time);


fprintf("\n===== ALGORITHM B — GREEDY RANDOMIZED =====\n");
[B_sol, B_W, B_noSol, B_avgW, B_time] = GreedyRandomizedAlgorithm(nNodes,Links,T,sP,nSP,timeLimit);
fprintf("W = %.2f Gbps | No. sol = %d | Av. W = %.2f | time = %.2f sec\n", ...
        B_W, B_noSol, B_avgW, B_time);


fprintf("\n===== ALGORITHM C — MULTI-START HILL CLIMBING (RANDOM START) =====\n");
[C_sol, C_W, C_noSol, C_avgW, C_time] = HillClimbing_Random(nNodes,Links,T,sP,nSP,timeLimit);
fprintf("W = %.2f Gbps | No. sol = %d | Av. W = %.2f | time = %.2f sec\n", ...
        C_W, C_noSol, C_avgW, C_time);


fprintf("\n===== ALGORITHM D — MULTI-START HILL CLIMBING (GREEDY RANDOM START) =====\n");
[D_sol, D_W, D_noSol, D_avgW, D_time] = HillClimbing_Greedy(nNodes,Links,T,sP,nSP,timeLimit);
fprintf("W = %.2f Gbps | No. sol = %d | Av. W = %.2f | time = %.2f sec\n", ...
        D_W, D_noSol, D_avgW, D_time);

%% Explicação sobre os resultados com diferentes valores de K:

% Quando usamos k = inf, cada fluxo tem todos os caminhos possíveis disponíveis.
% Isso significa que cada solução gerada pelo algoritmo demora mais tempo a ser calculada,
% pois existem mais caminhos para avaliar. Por isso, o número de soluções testadas
% (No. sol) é relativamente menor e a melhor solução demora mais a aparecer.
%
% Quando limitamos k = 6 (apenas os 6 caminhos mais curtos por fluxo), cada solução
% é mais rápida de calcular, permitindo que o algoritmo teste mais soluções dentro do
% mesmo limite de tempo. Por isso, No. sol aumenta e o tempo para encontrar a melhor
% solução (bestTime) diminui. A qualidade da melhor solução (W) não muda significativamente,
% porque os melhores caminhos estão incluídos entre os 6 mais curtos.
%
% Em resumo:
% - k grande = mais caminhos, soluções mais lentas, No. sol menor, bestTime maior
% - k pequeno = menos caminhos, soluções mais rápidas, No. sol maior, bestTime menor
