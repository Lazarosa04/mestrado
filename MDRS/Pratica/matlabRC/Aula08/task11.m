%% 11

addpath('C:\Users\Ruben\Documents\MATLAB\MATLABcodes1')
load("InputData2.mat")
nNodes= size(Nodes,1);
nLinks= size(Links,1);
nFlows= size(T,1);

sP= cell(1,nFlows);
nSP= zeros(1,nFlows);

%% a)
% Determine the total link energy consumption (E) and the worst link load (W) of the
% network and when all traffic flows are routed through the shortest path provided by the
% network. What do you conclude?

% matriz L     -> comprimentos
% matriz Loads -> peso de cada link, soma dos 2 pesos > 0 -> operacional 
% se operacional -> 20 + 10% * comprimento

% gerar matrizes necessárias
k= 6;
for f=1:nFlows
    [shortestPath, totalCost] = kShortestPath(L,T(f,1),T(f,2),k);
    sP{f}= shortestPath;
    nSP(f)= length(totalCost);
end

sol= ones(1,nFlows);
Loads= calcLinkLoads(nNodes,Links,T,sP,sol);

E = energy_consumption(L, Loads); 
maxLoad= max(max(Loads(:,3:4)));
fprintf("E= %5.3f     W=%5.3f \n", E, maxLoad);

%% c)

timeLimit = 30;
% 0 < alfa < 1
a = 1;
[bSol,bObjective,noCycles,avObjective,bTime,bE] = HillClimbing_Greedy_multiStart(nNodes,Links,T,sP,nSP,timeLimit,L,a);

fprintf("E = %.2f | W = %.2f Gbps | No. sol = %d | Av. W = %.2f | time = %.2f sec\n", ...
        bE,bObjective,noCycles,avObjective,bTime);

fprintf("List of links in sleeping mode: ");
for i = 1:size(Loads,1)
    linkLoad = Loads(i,3) + Loads(i,4);
    if linkLoad <= 0
        node1 = Loads(i,1);
        node2 = Loads(i,2);
        fprintf('{%d, %d} ', node1, node2);
    end
    if i == (size(Loads,1) - 1)
        fprintf("\n");
    end
end